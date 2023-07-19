import 'package:flutter/material.dart';
import 'package:pos_system/page/progress_bar.dart';

import '../../database/pos_database.dart';
import '../../object/payment_link_company.dart';
import 'make_payment_dialog.dart';


class PaymentSelect extends StatefulWidget {
  final String? dining_id;
  final String dining_name;
  const PaymentSelect({Key? key, required this.dining_id, required this.dining_name}) : super(key: key);

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
    return LayoutBuilder(builder: (context,  constraints) {
      if(constraints.maxWidth > 800){
        return AlertDialog(
          title: Text('Select Payment Method'),
          content: isload
              ? Container(
            // width: MediaQuery.of(context).size.width / 2,
            // height: MediaQuery.of(context).size.height / 2,
              child: Row(
                children: [
                  Container(
                    margin: EdgeInsets.all(2),
                    width: MediaQuery.of(context).size.width / 2,
                    height: MediaQuery.of(context).size.height / 3,
                    child: Column(children: [
                      GridView.count(
                          shrinkWrap: true,
                          crossAxisCount: 4,
                          children: List.generate(PaymentLists.length, (index) {
                            return GestureDetector(
                              onTap: () {
                                //Navigator.of(context, rootNavigator: true).pop();
                                openMakePayment(PaymentLists[index].type!, PaymentLists[index].payment_link_company_id!, widget.dining_id!, widget.dining_name);

                              },
                              child: Card(
                                elevation: 5,
                                color: Colors.black,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16.0),
                                ),
                                child: Container(
                                  height: MediaQuery.of(context).size.height / 3,
                                  width: MediaQuery.of(context).size.width / 3,
                                  child: Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      // ClipRRect(
                                      //   borderRadius: BorderRadius.circular(16.0),
                                      //   child:///***If you have exported images you must have to copy those images in assets/images directory.
                                      //   Image(
                                      //     image: AssetImage("drawable/payment_method.png"),
                                      //     // NetworkImage(
                                      //     //     "https://image.freepik.com/free-photo/close-up-people-training-with-ball_23-2149049821.jpg"),
                                      //     height: MediaQuery.of(context).size.height,
                                      //     width: MediaQuery.of(context).size.width,
                                      //     fit: BoxFit.cover,
                                      //   ),
                                      // ),
                                      Text(
                                        '${PaymentLists[index].name}',
                                        textAlign: TextAlign.start,
                                        overflow: TextOverflow.clip,
                                        style: TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontStyle: FontStyle.normal,
                                          fontSize: 16,
                                          color: Colors.blueGrey,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          })
                      ),
                    ]),
                  ),
                ],
              ))
              : CustomProgressBar(),
          actions: [
            ElevatedButton(
                onPressed: (){
                  Navigator.of(context).pop();
                },
                child: Text("Close"))
          ],
        ); 
      } else {
        ///mobile view
        return Center(
          child: SingleChildScrollView(
            physics: NeverScrollableScrollPhysics(),
            child: AlertDialog(
              title: Text('Select Payment Method'),
              content: isload
                  ? Container(
                    margin: EdgeInsets.all(2),
                    width: MediaQuery.of(context).size.width / 2,
                    child: GridView.count(
                        padding: EdgeInsets.zero,
                        shrinkWrap: true,
                        crossAxisCount: 4,
                        children: List.generate(PaymentLists.length, (index) {
                          return GestureDetector(
                            onTap: () {
                              //Navigator.of(context, rootNavigator: true).pop();
                              openMakePayment(PaymentLists[index].type!, PaymentLists[index].payment_link_company_id!, widget.dining_id!, widget.dining_name);

                            },
                            child: Card(
                              elevation: 5,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16.0),
                              ),
                              child: Container(
                                height: MediaQuery.of(context).size.height / 3,
                                width: MediaQuery.of(context).size.width / 3,
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    // ClipRRect(
                                    //   borderRadius: BorderRadius.circular(16.0),
                                    //   child:///***If you have exported images you must have to copy those images in assets/images directory.
                                    //   Image(
                                    //     image: AssetImage("drawable/payment_method.png"),
                                    //     // NetworkImage(
                                    //     //     "https://image.freepik.com/free-photo/close-up-people-training-with-ball_23-2149049821.jpg"),
                                    //     height: MediaQuery.of(context).size.height,
                                    //     width: MediaQuery.of(context).size.width,
                                    //     fit: BoxFit.cover,
                                    //   ),
                                    // ),
                                    Text(
                                      '${PaymentLists[index].name}',
                                      textAlign: TextAlign.start,
                                      overflow: TextOverflow.clip,
                                      style: TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontStyle: FontStyle.normal,
                                        fontSize: 16,
                                        color: Colors.blueGrey,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        })
                    ),
                  )
                  : CustomProgressBar(),
              actions: [
                ElevatedButton(
                    onPressed: (){
                      Navigator.of(context).pop();
                    },
                    child: Text("Close"))
              ],
            ),
          ),
        );
      }
    });
  }

  readPaymentMethod() async {
    //read available payment method
    List<PaymentLinkCompany> data = await PosDatabase.instance.readPaymentMethods();
    PaymentLists = List.from(data);
    setState(() {
      isload = true;
    });
  }

  Future<Future<Object?>> openMakePayment(int type_id, int payment_link_id, String dining, String diningName) async {
    return showGeneralDialog(
        barrierColor: Colors.black.withOpacity(0.5),
        transitionBuilder: (context, a1, a2, widget) {
          final curvedValue = Curves.easeInOutBack.transform(a1.value) - 1.0;
          return Transform(
            transform: Matrix4.translationValues(0.0, curvedValue * 200, 0.0),
            child: Opacity(
              opacity: a1.value,
              child: MakePayment(
                dining_id: dining,
                dining_name: diningName,
                type: type_id,
                payment_link_company_id: payment_link_id,
              ),
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
