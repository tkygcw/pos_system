import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';
// import 'package:pos_system/fragment/payment/ipay_api.dart';
import 'package:pos_system/fragment/payment/number_button.dart';
import 'package:pos_system/notifier/theme_color.dart';
import 'package:pos_system/object/order.dart';
import 'package:pos_system/object/order_cache.dart';
import 'package:provider/provider.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import 'dart:developer';

import '../../database/pos_database.dart';
import '../../notifier/cart_notifier.dart';
import '../../object/branch_link_dining_option.dart';
import '../../object/cart_product.dart';
import '../../object/dining_option.dart';
import '../../object/modifier_group.dart';
import '../../object/promotion.dart';
import '../../object/tax_link_dining.dart';
import '../../object/variant_group.dart';


class MakePayment extends StatefulWidget {
  final int type;
  const MakePayment({Key? key, required this.type}) : super(key: key);

  @override
  State<MakePayment> createState() => _MakePamentState();
}

class _MakePamentState extends State<MakePayment> {
  late StreamController streamController;
  // var type ="0";
  var userInput = '';
  var answer = '';
  Barcode? result;
  QRViewController? controller;
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  List<String> branchLinkDiningIdList = [];
  List<Promotion> autoApplyPromotionList = [];
  bool scanning=false;
  bool isopen=false;
  bool hasSelectedPromo = false;
  bool hasPromo = false;
  int taxRate = 0;
  int diningOptionID = 0;
  double total = 0.0;
  double promo = 0.0;
  double selectedPromo = 0.0;
  double selectedPromoAmount = 0.0;
  double priceIncSST = 0.0;
  double priceIncServiceTax = 0.0;
  double discountPrice = 0.0;
  double promoAmount = 0.0;
  double totalAmount = 0.0;
  double tableOrderPrice = 0.0;
  String selectedPromoRate = '';
  String promoName = '';
  String promoRate = '';
  String localTableUseId = '';
  String orderCacheId = '';
  String? allPromo = '';
  String? orderId;

  // Array of button
  final List<String> buttons = [
    '7',
    '8',
    '9',
    'C',
    '4',
    '5',
    '6',
    'DEL',
    '1',
    '2',
    '3',
    '',
    '00',
    '0',
    '.',
    '',
    '20.00',
    '50.00',
    '100.00',
    'GO',

  ];

  @override
  void initState() {
    super.initState();
    streamController = StreamController();
    readAllBranchLinkDiningOption();
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }

  @override
  void reassemble() {
    super.reassemble();
    if (Platform.isAndroid) {
      controller?.pauseCamera();
    }
    //controller!.resumeCamera();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeColor>(builder: (context, ThemeColor color, child) {
      return  AlertDialog(
        title: Text('Amount'),
        content: Container(
          width: MediaQuery.of(context).size.width / 1,
          height: MediaQuery.of(context).size.height / 1,
          child: StreamBuilder(
              stream: streamController.stream, builder: (context, snapshot) {
                return Consumer<CartModel>(builder: (context, CartModel cart, child) {
                  getSubTotal(cart);
                  return Row(
                    children: [
                      Expanded(
                          flex: 5,
                          child: Column(
                            children: [
                              Container(
                                margin: EdgeInsets.all(20),
                                alignment: Alignment.centerLeft,
                                child: Text('Table No: ${getSelectedTable(cart)}'),
                              ),
                              Card(
                                elevation: 5,
                                child: Column(
                                  children: [
                                    Container(
                                      height: 250,
                                      child: ListView.builder(
                                          itemCount: cart.cartNotifierItem.length,
                                          itemBuilder: (context, index) {
                                            return ListTile(
                                              hoverColor: Colors.transparent,
                                              onTap: () {},
                                              isThreeLine: true,
                                              title: RichText(
                                                text: TextSpan(
                                                  children: <TextSpan>[
                                                    TextSpan(
                                                      text: cart.cartNotifierItem[index].name +'\n',
                                                      style: TextStyle(
                                                          fontSize: 20,
                                                          color: color.backgroundColor,
                                                          fontWeight: FontWeight.bold),
                                                    ),
                                                    TextSpan(
                                                        text: "RM" + cart.cartNotifierItem[index].price,
                                                        style: TextStyle(fontSize: 15, color: color.backgroundColor,
                                                        )),
                                                  ],
                                                ),
                                              ),
                                              subtitle: Text(getVariant(cart.cartNotifierItem[index]) +
                                                  getModifier(cart.cartNotifierItem[index]) +
                                                  getRemark(cart.cartNotifierItem[index]),
                                                  style: TextStyle(fontSize: 12)),
                                              trailing: Container(
                                                child: FittedBox(
                                                  child: Row(
                                                    children: [
                                                      Text(
                                                        cart.cartNotifierItem[index].quantity.toString(),
                                                        style: TextStyle(color: color.backgroundColor),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            );
                                          }
                                      ),
                                    ),
                                    SizedBox(height: 20),
                                    Divider(
                                      color: Colors.grey,
                                      height: 1,
                                      thickness: 1,
                                      indent: 20,
                                      endIndent: 20,
                                    ),
                                    SizedBox(height: 10),
                                    ListView(
                                      padding: EdgeInsets.only(left: 5, right: 5),
                                      physics: NeverScrollableScrollPhysics(),
                                      children: [
                                        ListTile(
                                          title: Text("Subtotal",
                                              style: TextStyle(fontSize: 14)),
                                          trailing: Text('${total.toStringAsFixed(2)}',
                                              style: TextStyle(fontSize: 14)),
                                          visualDensity: VisualDensity(vertical: -4),
                                          dense: true,
                                        ),
                                        Visibility(
                                          visible:
                                          hasSelectedPromo ? true : false,
                                          child: ListTile(
                                            title: SingleChildScrollView(
                                              scrollDirection: Axis.horizontal,
                                              child: Row(
                                                children: [
                                                  Text('${allPromo} (${selectedPromoRate})',
                                                      style: TextStyle(fontSize: 14)),
                                                ],
                                              ),
                                            ),
                                            trailing: Text(
                                                '-${selectedPromo.toStringAsFixed(2)}',
                                                style: TextStyle(fontSize: 14)),
                                            visualDensity: VisualDensity(vertical: -4),
                                            dense: true,
                                          ),
                                        ),
                                        Visibility(
                                            visible: hasPromo == true ? true : false,
                                            child: ListView.builder(
                                              physics: NeverScrollableScrollPhysics(),
                                              padding: EdgeInsets.zero,
                                                shrinkWrap: true,
                                                itemCount: autoApplyPromotionList.length,
                                                itemBuilder: (context, index) {
                                                  return ListTile(
                                                      title: Text(
                                                          '${autoApplyPromotionList[index].name} (${autoApplyPromotionList[index].promoRate})',
                                                          style: TextStyle(fontSize: 14)),
                                                      visualDensity:
                                                      VisualDensity(vertical: -4),
                                                      dense: true,
                                                      trailing: Text(
                                                          '-${autoApplyPromotionList[index].promoAmount!.toStringAsFixed(2)}',
                                                          style: TextStyle(fontSize: 14)));
                                                })),
                                        ListTile(
                                          title: Text('Sst (6%)',
                                              style: TextStyle(fontSize: 14)),
                                          trailing: Text(
                                              '${priceIncSST.toStringAsFixed(2)}',
                                              style: TextStyle(fontSize: 14)),
                                          visualDensity: VisualDensity(vertical: -4),
                                          dense: true,
                                        ),
                                        ListTile(
                                          title: Text('Service Tax ($taxRate%)',
                                              style: TextStyle(fontSize: 14)),
                                          trailing: Text(
                                              '${priceIncServiceTax.toStringAsFixed(2)}',
                                              style: TextStyle(fontSize: 14)),
                                          visualDensity: VisualDensity(vertical: -4),
                                          dense: true,
                                        ),
                                        ListTile(
                                          visualDensity: VisualDensity(vertical: -4),
                                          title: Text("Total",
                                              style: TextStyle(
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.bold)),
                                          trailing: Text(
                                              "${totalAmount.toStringAsFixed(2)}",
                                              style: TextStyle(
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.bold)),
                                          dense: true,
                                        ),
                                      ],
                                      shrinkWrap: true,
                                    ),
                                    SizedBox(height: 10),
                                    Divider(
                                      color: Colors.grey,
                                      height: 1,
                                      thickness: 1,
                                      indent: 20,
                                      endIndent: 20,
                                    ),
                                    SizedBox(height: 10),
                                  ],
                                ),
                              ),
                            ],
                          )
                      ),
                      widget.type == 0 ?
                      Expanded(
                        flex: 5,
                        child: Container(
                          child: Column(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: <Widget>[
                                Container(
                                  padding: EdgeInsets.all(20),
                                  alignment: Alignment.centerRight,
                                  child: Text(
                                    userInput,
                                    style: TextStyle(fontSize: 18, color: Colors.white),
                                  ),
                                ),
                                Container(
                                  padding: EdgeInsets.all(15),
                                  alignment: Alignment.centerRight,
                                  child: Text(
                                    answer,
                                    style: TextStyle(
                                        fontSize: 30,
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold),
                                  ),
                                )
                              ]),
                        ),
                      ) : Spacer(),
                      Expanded(
                        flex: 5,
                        child: widget.type == 0 ?
                        Container(
                          height:MediaQuery.of(context).size.height / 1.5 ,
                          child: Column(
                            children: [
                              Expanded(
                                flex: 2,
                                child: Container(
                                  width: double.infinity,
                                  color: Colors.grey[200],
                                  child: Container(
                                    alignment: AlignmentDirectional.bottomEnd,
                                    child: Text(userInput,
                                      style: TextStyle(
                                        color: Colors.black87,
                                        fontSize: 70,
                                        fontWeight: FontWeight.w400,
                                      ),),
                                  ),
                                ),
                              ),
                              Expanded(
                                flex: 8,
                                child: GridView.builder(
                                    itemCount: buttons.length,
                                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: 4,
                                      childAspectRatio: MediaQuery.of(context).size.width /
                                          (MediaQuery.of(context).size.height / 0.9),),
                                    itemBuilder: (BuildContext context, int index) {
                                      // Clear Button
                                      if (index == 3) {
                                        return NumberButton(
                                          buttontapped: () {
                                            setState(() {
                                              userInput = userInput.substring(0, userInput.length - 1);
                                            });
                                          },
                                          buttonText: buttons[index],
                                          color: Colors.blue[50],
                                          textColor: Colors.black,
                                        );
                                      }

                                      // +/- button
                                      else if (index == 7) {
                                        return NumberButton(
                                          buttontapped: () {
                                            setState(() {
                                              userInput = '';

                                            });
                                          },
                                          buttonText: buttons[index],
                                          color: Colors.blue[50],
                                          textColor: Colors.black,
                                        );
                                      }

                                      // Delete Button

                                      // Equal_to Button
                                      else if (index == 16) {
                                        return NumberButton(
                                          buttontapped: () {
                                            setState(() {
                                              userInput = buttons[index];

                                            });
                                          },
                                          buttonText: buttons[index],
                                          color: Colors.orange[300],
                                          textColor: Colors.white,
                                        );
                                      }
                                      else if (index == 17) {
                                        return NumberButton(
                                          buttontapped: () {
                                            setState(() {
                                              userInput = buttons[index];

                                            });
                                          },
                                          buttonText: buttons[index],
                                          color: Colors.orange[300],
                                          textColor: Colors.white,
                                        );
                                      }
                                      else if (index == 18) {
                                        return NumberButton(
                                          buttontapped: () {
                                            setState(() {
                                              userInput = buttons[index];
                                            });
                                          },
                                          buttonText: buttons[index],
                                          color: Colors.orange[300],
                                          textColor: Colors.white,
                                        );
                                      }
                                      else if (index == 19) {
                                        return NumberButton(
                                          buttontapped: () {
                                            setState(() {
                                              // equalPressed();
                                            });
                                          },
                                          buttonText: buttons[index],
                                          color: Colors.orange[700],
                                          textColor: Colors.white,
                                        );
                                      }
                                      //  other buttons
                                      else {
                                        return NumberButton(
                                          buttontapped: () {
                                            setState(() {
                                              userInput += buttons[index];
                                            });
                                          },
                                          buttonText: buttons[index],
                                          color: Colors.white,
                                          textColor:  Colors.black,
                                        );
                                      }
                                    }),
                              ),
                            ],
                          ), // GridView.builder
                        ): widget.type == 1  ?
                        Container(
                          child: Column(
                            children: [
                              Expanded(
                                  flex: 6,
                                  child: Container(
                                    child: ClipRRect(
                                      borderRadius:
                                      BorderRadius.circular(16.0),
                                      child:

                                      ///***If you have exported images you must have to copy those images in assets/images directory.
                                      Image(
                                        image: NetworkImage(
                                            "https://v.icbc.com.cn/userfiles/Resources/ICBC/haiwai/Malaysia/photo/2021/mobil202108034.jpg"),
                                        height: MediaQuery.of(context).size.height/2,
                                        width: MediaQuery.of(context).size.width/2,
                                      ),
                                    ),

                                  )
                              ),
                              Expanded(
                                  flex:1,
                                  child: Container(
                                    alignment: Alignment.center,
                                    child: Text('RM50.00',style: TextStyle(fontSize: 40,fontWeight: FontWeight.bold),),
                                  )
                              ),
                              Expanded(
                                  flex:2,
                                  child: Container(
                                    alignment: Alignment.center,
                                    child: SizedBox(
                                      width: double.maxFinite,
                                      height: 60,
                                      child: ElevatedButton(

                                        style: ButtonStyle(backgroundColor: MaterialStateProperty.all(Colors.green)),
                                        onPressed: () {

                                        }, child: Text("Confirm",style:TextStyle(fontSize: 25)),

                                      ),
                                    ),
                                  )
                              ),
                              Expanded(flex: 1,child: Container())
                            ],
                          ) ,
                        ): widget.type == 2 ?
                        Container(
                          child: Column(
                            children: [
                              Expanded(
                                  flex: 6,
                                  child: Container(
                                    child: scanning == false ?
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(16.0),
                                      child: Image(
                                        image: NetworkImage(
                                            "https://upload.wikimedia.org/wikipedia/commons/a/ac/Touch_%27n_Go_%282%29.png"),
                                        height: MediaQuery.of(context).size.height/2,
                                        width: MediaQuery.of(context).size.width/2,
                                      ),
                                    ):Container(
                                      child: _buildQrView(context) ,
                                    ),

                                  )
                              ),
                              Expanded(
                                  flex:1,
                                  child: Container(
                                    alignment: Alignment.center,
                                    child: Text('RM${totalAmount}',style: TextStyle(fontSize: 40,fontWeight: FontWeight.bold),),
                                  )
                              ),
                              Expanded(
                                  flex:2,
                                  child: Container(
                                    alignment: Alignment.center,
                                    child: SizedBox(
                                      height: 60,
                                      child: ElevatedButton(
                                        style: ButtonStyle(backgroundColor: MaterialStateProperty.all(color.backgroundColor) ),
                                        onPressed: () async {
                                          await controller?.resumeCamera();
                                          await controller?.scannedDataStream;
                                          setState(() {
                                            scanning = true;
                                          });
                                          callCrateNewOrder(cart);
                                          // await controller?.resumeCamera();
                                          // scanning= true;

                                        }, child: Text(scanning==false?"Start Scan":"Scanning...",style:TextStyle(fontSize: 25)),

                                      ),
                                    ),
                                  )
                              ),
                            ],
                          ) ,
                        ):Container(),
                      ),
                    ],
                  );
                });
              })
        ),
      );
    });



  }

  Widget _buildQrView(BuildContext context) {

    // For this example we check how width or tall the device is and change the scanArea and overlay accordingly.
    var scanArea = (MediaQuery.of(context).size.width < 400 ||
        MediaQuery.of(context).size.height < 400)
        ? 150.0
        : 300.0;
    // To ensure the Scanner view is properly sizes after rotation
    // we need to listen for Flutter SizeChanged notification and update controller
    return QRView(
      key: qrKey,
      onQRViewCreated: _onQRViewCreated,
      overlay: QrScannerOverlayShape(
          borderColor: Colors.red,
          borderRadius: 10,
          borderLength: 30,
          borderWidth: 10,
          cutOutSize: scanArea),
      onPermissionSet: (ctrl, p) => _onPermissionSet(context, ctrl, p),
    );
  }
  void _onPermissionSet(BuildContext context, QRViewController ctrl, bool p) {
    log('${DateTime.now().toIso8601String()}_onPermissionSet $p');
    if (!p) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('no Permission')),
      );
    }
  }

  void _onQRViewCreated(QRViewController p1) {
    setState(() {
      this.controller = p1;
    });

    p1.scannedDataStream.listen((scanData) {
      p1.pauseCamera();
      setState(() {
        result = scanData;
        print('result:${result?.code}');
      });

    });
  }

// function to calculate the input operation
//    equalPressed() {
//     String finaluserinput = userInput;
//     finaluserinput = userInput.replaceAll('x', '*');
//
//     Parser p = Parser();
//     Expression exp = p.parse(finaluserinput);
//     ContextModel cm = ContextModel();
//     double eval = exp.evaluate(EvaluationType.REAL, cm);
//     answer = eval.toString();
//   }
/*
  -----------------------Cart-item-----------------------------------------------------------------------------------------------------------------------------------------------------
*/
/*
  get selected table
*/
  getSelectedTable(CartModel cart) {
    List<String> result = [];
    if (cart.selectedTable.isEmpty && cart.selectedOption == 'Dine in') {
      result.add('No table');
    } else if (cart.selectedOption != 'Dine in') {
      result.add('');
    } else {
      if (cart.selectedTable.length > 1) {
        for (int i = 0; i < cart.selectedTable.length; i++) {
          result.add('${cart.selectedTable[i].number}');
        }
      } else {
        result.add('${cart.selectedTable[0].number}');
      }
    }

    return result.toString().replaceAll('[', '').replaceAll(']', '');
  }  

/*
  Get Cart product modifier
*/
  getModifier(cartProductItem object) {
    List<String?> modifier = [];
    String result = '';
    for (int i = 0; i < object.modifier.length; i++) {
      ModifierGroup group = object.modifier[i];
      for (int j = 0; j < group.modifierChild.length; j++) {
        if (group.modifierChild[j].isChecked!) {
          modifier.add(group.modifierChild[j].name! + '\n');
          result = modifier
              .toString()
              .replaceAll('[', '')
              .replaceAll(']', '')
              .replaceAll(',', '+')
              .replaceFirst('', '+ ');
        }
      }
    }
    return result;
  }

/*
  Get Cart product variant
*/
  getVariant(cartProductItem object) {
    List<String?> variant = [];
    String result = '';
    for (int i = 0; i < object.variant.length; i++) {
      VariantGroup group = object.variant[i];
      for (int j = 0; j < group.child.length; j++) {
        if (group.child[j].isSelected!) {
          variant.add(group.child[j].name! + '\n');
          result = variant
              .toString()
              .replaceAll('[', '')
              .replaceAll(']', '')
              .replaceAll(',', '+')
              .replaceAll('|', '\n+')
              .replaceFirst('', '+ ');
        }
      }
    }
    return result;
  }

/*
  Get Remark
*/
  getRemark(cartProductItem object) {
    String result = '';
    if (object.remark != '') {
      result = '*' + object.remark.toString();
    }
    return result;
  }

/*
  -------------------calculation-----------------------------------------------------------------------------------------------------------------------------------------------------
*/

  calPromotion(CartModel cart) {
    promoAmount = 0.0;
    getAutoApplyPromotion(cart);
    getManualApplyPromotion(cart);
    streamController.add('refresh');
  }

  getManualApplyPromotion(CartModel cart) {
    List<cartProductItem> _sameCategoryList = [];
    allPromo = '';
    selectedPromoRate = '';
    try {
      if (cart.selectedPromotion != null) {
        allPromo = cart.selectedPromotion!.name;
        if (cart.selectedPromotion!.type == 0) {
          selectedPromoRate = cart.selectedPromotion!.amount.toString() + '%';
        } else {
          selectedPromoRate = cart.selectedPromotion!.amount! + '.00';
        }

        if (cart.selectedPromotion!.specific_category == '1') {
          for (int i = 0; i < cart.cartNotifierItem.length; i++) {
            if (cart.cartNotifierItem[i].category_id ==
                cart.selectedPromotion!.category_id) {
              _sameCategoryList.add(cart.cartNotifierItem[i]);
            }
          }
          specificCategoryAmount(cart.selectedPromotion!, _sameCategoryList);
        } else {
          nonSpecificCategoryAmount(cart);
        }
      }
    } catch (error) {
      print('Get manual promotion error: $error');
    }
    streamController.add('refresh');
  }

  specificCategoryAmount(Promotion promotion, List<cartProductItem> cartItem) {
    try {
      selectedPromo = 0.0;
      hasSelectedPromo = false;

      for (int j = 0; j < cartItem.length; j++) {
        if (promotion.type == 0) {
          hasSelectedPromo = true;
          selectedPromo +=
              (double.parse(cartItem[j].price) * cartItem[j].quantity) *
                  (double.parse(promotion.amount!) / 100);
        } else {
          hasSelectedPromo = true;
          selectedPromo +=
          (double.parse(promotion.amount!) * cartItem[j].quantity);
        }
      }
      promoAmount += selectedPromo;
    } catch (e) {
      print('Specific category offer amount error: $e');
      selectedPromo = 0.0;
    }
    streamController.add('refresh');
  }

  nonSpecificCategoryAmount(CartModel cart) {
    try {
      selectedPromo = 0.0;
      hasSelectedPromo = false;

      if (cart.selectedPromotion!.type == 0) {
        hasSelectedPromo = true;
        selectedPromo = total * 0.10;
      } else {
        if (cart.cartNotifierItem.isNotEmpty) {
          for (int i = 0; i < cart.cartNotifierItem.length; i++) {
            hasSelectedPromo = true;
            selectedPromo += double.parse(cart.selectedPromotion!.amount!) *
                cart.cartNotifierItem[i].quantity;
          }
        }
      }
      promoAmount += selectedPromo;
    } catch (error) {
      print('check promotion type error: $error');
      selectedPromo = 0.0;
    }
    streamController.add('refresh');
  }
/*
  -------------------Auto apply Discount-------------------------------------------------------------------------------------------------------------------------------------------
*/
  getAutoApplyPromotion(CartModel cart) {
    try {
      autoApplyPromotionList = [];
      promoName = '';
      hasPromo = false;
      //loop promotion list get promotion
      for (int j = 0; j < cart.autoPromotion.length; j++) {
        cart.autoPromotion[j].promoAmount = 0.0;
        if (cart.autoPromotion[j].auto_apply == '1') {
          if (cart.autoPromotion[j].specific_category == '1') {
            //Auto apply specific category promotion
            for (int m = 0; m < cart.cartNotifierItem.length; m++) {
              if (cart.cartNotifierItem[m].category_id ==
                  cart.autoPromotion[j].category_id) {
                hasPromo = true;
                promoName = cart.autoPromotion[j].name!;
                if (!autoApplyPromotionList.contains(cart.autoPromotion[j])) {
                  autoApplyPromotionList.add(cart.autoPromotion[j]);
                }
                autoApplySpecificCategoryAmount(
                    cart.autoPromotion[j], cart.cartNotifierItem[m]);
              }
              // //check cart item status
              // if (cart.cartNotifierItem[m].status == 0) {
              //
              // }
            }
          } else {
            //Auto apply non specific category promotion
            if (cart.cartNotifierItem.isNotEmpty) {
              // for (int i = 0; i < cart.cartNotifierItem.length; i++) {
              //   if (cart.cartNotifierItem[i].status == 0) {
              //
              //   }
              // }
              hasPromo = true;
              autoApplyPromotionList.add(cart.autoPromotion[j]);
              promoName = cart.autoPromotion[j].name!;
              autoApplyNonSpecificCategoryAmount(cart.autoPromotion[j], cart);
            }
          }
        }
      }
    } catch (error) {
      print('Promotion error $error');
      promo = 0.0;
    }
    streamController.add('refresh');
  }

  autoApplyNonSpecificCategoryAmount(Promotion promotion, CartModel cart) {
    try {
      promo = 0.0;
      for (int i = 0; i < cart.cartNotifierItem.length; i++) {
        if (promotion.type == 1) {
          promo += (double.parse(promotion.amount!) *
              cart.cartNotifierItem[i].quantity);
          promotion.promoAmount = promo;
          promoRate = 'RM' + promotion.amount!;
          promotion.promoRate = promoRate;
        } else {
          promo += (double.parse(cart.cartNotifierItem[i].price) *
              cart.cartNotifierItem[i].quantity) *
              (double.parse(promotion.amount!) / 100);
          promotion.promoAmount = promo;
          promoRate = promotion.amount! + '%';
          promotion.promoRate = promoRate;
        }
        // if (cart.cartNotifierItem[i].status == 0) {
        //
        // }
      }
      promoAmount += promo;
    } catch (e) {
      print("calc auto apply non specific error: $e");
      promoRate = '';
      promo = 0.0;
    }

    streamController.add('refresh');
  }

  autoApplySpecificCategoryAmount(
      Promotion promotion, cartProductItem cartItem) {
    try {
      promo = 0.0;
      if (promotion.type == 1) {
        promo += (double.parse(promotion.amount!) * cartItem.quantity);
        promotion.promoAmount = promotion.promoAmount! + promo;
        promoRate = 'RM' + promotion.amount!;
        promotion.promoRate = promoRate;
      } else {
        promo += (double.parse(cartItem.price) * cartItem.quantity) *
            (double.parse(promotion.amount!) / 100);
        promotion.promoAmount = promotion.promoAmount! + promo;
        promoRate = promotion.amount! + '%';
        promotion.promoRate = promoRate;
      }
      // if (cartItem.status == 0) {
      // }
      //calculate promo total amount
      promoAmount += promo;
    } catch (e) {
      print("calc auto apply specific category error: $e");
      promoRate = '';
      promo = 0.0;
    }
    streamController.add('refresh');
  }

  getSubTotal(CartModel cart) async {
    try {
      total = 0.0;
      promo = 0.0;
      promoAmount = 0.0;
      for (int i = 0; i < cart.cartNotifierItem.length; i++) {
        total += (double.parse((cart.cartNotifierItem[i].price)) * cart.cartNotifierItem[i].quantity);
      }
    } catch (e) {
      print('Sub Total Error: $e');
      total = 0.0;
    }
    await getDiningTax(cart);
    // getCartPromotion(cart);
    // getAutoApplyPromotion(cart);
    calPromotion(cart);
    getSalesServiceTax();
    getServiceTax();
    getAllTotal();
    streamController.add('refresh');
  }

  getSalesServiceTax() {
    try {
      priceIncServiceTax = 0.00;
      discountPrice = 0.00;

      discountPrice = total - promoAmount;
      priceIncSST = discountPrice * 0.06;
      priceIncSST = (priceIncSST * 100).truncate() / 100;
    } catch (error) {
      print('SST calculation error $error');
      priceIncSST = 0.0;
    }
    streamController.add('refresh');
  }

  getServiceTax() {
    try {
      priceIncServiceTax = 0.0;
      discountPrice = 0.0;

      discountPrice = total - promoAmount;
      priceIncServiceTax = discountPrice * (taxRate / 100);
      priceIncServiceTax = (priceIncServiceTax * 100).truncate() / 100;
    } catch (error) {
      print('Service Tax error $error');
      priceIncServiceTax = 0.0;
    }

    streamController.add('refresh');
  }

  getAllTotal() {
    try {
      totalAmount = 0.0;

      totalAmount = discountPrice + priceIncSST + priceIncServiceTax;
      totalAmount = (totalAmount * 100).truncate() / 100;
    } catch (error) {
      print('Total calc error: $error');
    }

    streamController.add('refresh');
  }


/*
  -------------------DB Query---------------------------------------------------------------------------------------------------------------------------------------------------------
*/
  readAllBranchLinkDiningOption() async {
    final prefs = await SharedPreferences.getInstance();
    final int? branch_id = prefs.getInt('branch_id');
    List<BranchLinkDining> data = await PosDatabase.instance
        .readBranchLinkDiningOption(branch_id!.toString());
    for (int i = 0; i < data.length; i++) {
      branchLinkDiningIdList.add(data[i].dining_id!);
    }

    streamController.add('refresh');
  }

  getDiningTax(CartModel cart) async {
    try {
      diningOptionID = 0;
      //get dining option data
      List<DiningOption> data = await PosDatabase.instance.checkSelectedOption(cart.selectedOption);
      diningOptionID = data[0].dining_id!;
      //get dining tax
      List<TaxLinkDining> TaxLinkDiningData = await PosDatabase.instance.readTaxLinkDining(data[0].dining_id!);
      if (TaxLinkDiningData.length > 0) {
        for (int i = 0; i < TaxLinkDiningData.length; i++) {
          taxRate = int.parse(TaxLinkDiningData[i].tax_rate!);
        }
      } else {
        taxRate = 0;
      }
    } catch (error) {
      print('get dining tax error: $error');
      taxRate = 0;
    }

    streamController.add('refresh');

    return diningOptionID;
  }

  callCrateNewOrder(CartModel cartModel) async {
    await createOrder();
    await updateOrderCache(cartModel);
  }

  createOrder() async {
    print('create order called');
    DateFormat dateFormat = DateFormat("yyyy-MM-dd HH:mm:ss");
    String dateTime = dateFormat.format(DateTime.now());
    final prefs = await SharedPreferences.getInstance();
    final String? login_user = prefs.getString('user');
    final int? branch_id = prefs.getInt('branch_id');
    final String? pos_user = prefs.getString('pos_pin_user');
    Map logInUser = json.decode(login_user!);
    Map userObject = json.decode(pos_user!);

    try{
      Order orderObject = Order(
          order_id: 0,
          company_id: logInUser['company_id'].toString(),
          branch_id:  branch_id.toString(),
          customer_id: '',
          branch_link_promotion_id: '',
          payment_link_company_id: widget.type.toString(),
          branch_link_tax_id: '',
          final_amount: totalAmount.toStringAsFixed(2),
          close_by: userObject['name'].toString(),
          created_at: dateTime,
          updated_at: '',
          soft_delete: ''
      );

      Order data = await PosDatabase.instance.insertSqliteOrder(orderObject);
      this.orderId = data.order_sqlite_id.toString();
    }catch(e){
      print(e);
      Fluttertoast.showToast(
          backgroundColor: Color(0xFFFF0000),
          msg: "Create order cache error: ${e}");
    }
  }

  updateOrderCache(CartModel cart) async {
    DateFormat dateFormat = DateFormat("yyyy-MM-dd HH:mm:ss");
    String dateTime = dateFormat.format(DateTime.now());
    List<String> orderCacheIdList = [];

    for(int i = 0; i < cart.cartNotifierItem.length; i++){
      if(!orderCacheIdList.contains(cart.cartNotifierItem[i].orderCacheId!)){
        orderCacheIdList.add(cart.cartNotifierItem[i].orderCacheId!);
      }
    }
    for(int j = 0; j < orderCacheIdList.length; j++){
      OrderCache cacheObject = OrderCache(
          order_id: orderId,
          sync_status: 0,
          updated_at: dateTime,
          order_cache_sqlite_id: int.parse(orderCacheIdList[j])
      );

      int data = await PosDatabase.instance.updateOrderCacheOrderId(cacheObject);
    }

  }

}
