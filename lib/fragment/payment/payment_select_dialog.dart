import 'package:flutter/material.dart';
import 'package:pos_system/page/progress_bar.dart';
import 'package:provider/provider.dart';

import '../../database/pos_database.dart';
import '../../notifier/cart_notifier.dart';
import '../../notifier/theme_color.dart';
import '../../object/payment_link_company.dart';
import 'make_payment_dialog.dart';

class PaymentSelect extends StatefulWidget {
  const PaymentSelect({Key? key}) : super(key: key);

  @override
  State<PaymentSelect> createState() => _PaymentSelectState();
}

class _PaymentSelectState extends State<PaymentSelect> {
  List<PaymentLinkCompany> PaymentLists = [];
  bool isload = false;

  @override
  void initState() {
    super.initState();
    readPaymentMethod();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Select Payment Method'),
      content: isload
          ? Container(
              width: MediaQuery.of(context).size.width / 1.4,
              height: MediaQuery.of(context).size.height / 1.5,
              child: Row(
                children: [
                  Container(
                    margin: EdgeInsets.all(2),
                    width: MediaQuery.of(context).size.width / 2,
                    height: MediaQuery.of(context).size.height / 2,
                    child: Column(children: [
                      GridView.count(
                          shrinkWrap: true,
                          crossAxisCount: 4,
                          children: List.generate(PaymentLists.length, (index) {
                            return GestureDetector(
                              onTap: () {
                                openMakePayment(PaymentLists[index].type!);
                              },
                              child: Card(
                                elevation: 5,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16.0),
                                ),
                                child: Container(
                                  height:
                                      MediaQuery.of(context).size.height / 3,
                                  width: MediaQuery.of(context).size.width / 3,
                                  child: Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      ClipRRect(
                                        borderRadius:
                                            BorderRadius.circular(16.0),
                                        child:

                                            ///***If you have exported images you must have to copy those images in assets/images directory.
                                            Image(
                                          image: NetworkImage(
                                              "https://image.freepik.com/free-photo/close-up-people-training-with-ball_23-2149049821.jpg"),
                                          height: MediaQuery.of(context)
                                              .size
                                              .height,
                                          width:
                                              MediaQuery.of(context).size.width,
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                      Container(
                                        margin: EdgeInsets.all(0),
                                        padding: EdgeInsets.all(0),
                                        width:
                                            MediaQuery.of(context).size.width,
                                        height:
                                            MediaQuery.of(context).size.height,
                                        decoration: BoxDecoration(
                                          color: Color(0x6e000000),
                                          shape: BoxShape.rectangle,
                                          borderRadius:
                                              BorderRadius.circular(16.0),
                                          border: Border.all(
                                              color: Color(0x4d9e9e9e),
                                              width: 1),
                                        ),
                                      ),
                                      Text(
                                        '${PaymentLists[index].name}',
                                        textAlign: TextAlign.start,
                                        overflow: TextOverflow.clip,
                                        style: TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontStyle: FontStyle.normal,
                                          fontSize: 16,
                                          color: Color(0xffffffff),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          })


                          ),
                      Spacer(),
                      // Container(
                      //   alignment: Alignment.bottomRight,
                      //   padding: EdgeInsets.fromLTRB(0, 0, 15, 0),
                      //   child: Text(
                      //     "Total: RM20.00",
                      //     textAlign: TextAlign.start,
                      //     overflow: TextOverflow.clip,
                      //     style: TextStyle(
                      //       fontWeight: FontWeight.w700,
                      //       fontStyle: FontStyle.normal,
                      //       fontSize: 14,
                      //       color: Color(0xff000000),
                      //     ),
                      //   ),
                      // ),
                    ]),
                  ),
                  VerticalDivider(
                    color: Colors.black,
                    thickness: 2,
                  ),
                  Expanded(
                    child: Container(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [

                             ClipRRect(
                              borderRadius: BorderRadius.circular(16.0),
                              child:

                                  ///***If you have exported images you must have to copy those images in assets/images directory.
                                  Image(
                                image: NetworkImage(
                                    "https://stock.wikimini.org/w/images/5/55/Qrcode_wikipedia_fr.jpg"),
                                height: 150,
                                width: 150,
                                fit: BoxFit.cover,
                              ),
                            ),
                        SizedBox(
                          height: 20,
                        ),
                          Text(
                            "Total: RM20.00",
                            textAlign: TextAlign.start,
                            overflow: TextOverflow.clip,
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontStyle: FontStyle.normal,
                              fontSize: 14,
                              color: Color(0xff000000),
                            ),
                          )
                        ],
                      ),
                    ),
                  )
                ],
              ))
          : CustomProgressBar(),
    );
  }

  readPaymentMethod() async {
    //read available payment method
    List<PaymentLinkCompany> data =
        await PosDatabase.instance.readPaymentMethods();
    PaymentLists = List.from(data);
    setState(() {
      isload = true;
    });
  }

  Future<Future<Object?>> openMakePayment(int type_id) async {
    return showGeneralDialog(
        barrierColor: Colors.black.withOpacity(0.5),
        transitionBuilder: (context, a1, a2, widget) {
          final curvedValue = Curves.easeInOutBack.transform(a1.value) - 1.0;
          return Transform(
            transform: Matrix4.translationValues(0.0, curvedValue * 200, 0.0),
            child: Opacity(
              opacity: a1.value,
              child: MakePayment(type: type_id),
            ),
          );
        },
        transitionDuration: Duration(milliseconds: 200),
        barrierDismissible: false,
        context: context,
        pageBuilder: (context, animation1, animation2) {
          // ignore: null_check_always_fails
          return null!;
        });
  }
}
