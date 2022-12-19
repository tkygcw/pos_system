import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';
import 'package:pos_system/fragment/payment/ipay_api.dart';
import 'package:pos_system/fragment/payment/number_button.dart';
import 'package:pos_system/fragment/payment/payment_success_dialog.dart';
import 'package:pos_system/notifier/theme_color.dart';
import 'package:pos_system/object/branch_link_promotion.dart';
import 'package:pos_system/object/branch_link_tax.dart';
import 'package:pos_system/object/order.dart';
import 'package:pos_system/object/order_promotion_detail.dart';
import 'package:pos_system/object/order_tax_detail.dart';
import 'package:pos_system/object/payment_link_company.dart';
import 'package:pos_system/object/receipt_layout.dart';
import 'package:provider/provider.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import 'dart:developer';
import 'package:crypto/crypto.dart';

import '../../database/domain.dart';
import '../../database/pos_database.dart';
import '../../notifier/cart_notifier.dart';
import '../../object/branch_link_dining_option.dart';
import '../../object/cart_product.dart';
import '../../object/dining_option.dart';
import '../../object/modifier_group.dart';
import '../../object/promotion.dart';
import '../../object/table.dart';
import '../../object/tax.dart';
import '../../object/tax_link_dining.dart';
import '../../object/variant_group.dart';


class MakePayment extends StatefulWidget {
  final int type;
  final int payment_link_company_id;
  final String dining_id;
  const MakePayment({Key? key, required this.type, required this.payment_link_company_id, required this.dining_id}) : super(key: key);

  @override
  State<MakePayment> createState() => _MakePaymentState();
}

class _MakePaymentState extends State<MakePayment> {
  final inputController = TextEditingController();
  final ScrollController _controller = ScrollController();
  late StreamController streamController;
  // var type ="0";
  var userInput = '0.00';
  var answer = '';
  Barcode? result;
  QRViewController? controller;
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  List<String> branchLinkDiningIdList = [];
  List<Promotion> autoApplyPromotionList = [];
  List<Promotion> appliedPromotionList = [];
  List<String> orderCacheIdList = [];
  List<PosTable> selectedTableList = [];
  List<Order> orderList = [];
  List<Tax> taxList = [];
  bool scanning=false;
  bool isopen=false;
  bool hasSelectedPromo = false;
  bool hasPromo = false;
  int taxRate = 0;
  int diningOptionID = 0;
  int count = 0;
  double total = 0.0;
  double promo = 0.0;
  double selectedPromo = 0.0;
  double selectedPromoAmount = 0.0;
  double taxAmount = 0.0;
  double priceIncAllTaxes = 0.0;
  double priceIncTaxes = 0.0;
  double discountPrice = 0.0;
  double promoAmount = 0.0;
  double totalAmount = 0.0;
  double tableOrderPrice = 0.0;
  double rounding = 0.0;
  String diningName = '';
  String selectedPromoRate = '';
  String promoName = '';
  String promoRate = '';
  String localTableUseId = '';
  String orderCacheId = '';
  String ipay_code = '';
  String? allPromo = '';
  String finalAmount = '';
  String change = '0.00';
  String? orderId, orderKey;
  int myCount = 0;
  late Map branchObject;

  // Array of button
  final List<String> buttons = [
    '7', //0
    '8', //1
    '9', //2
    'C', //3
    '4', //4
    '5', //5
    '6', //6
    'DEL', //7
    '1', //8
    '2', //9
    '3', //10
    '', //11
    '00', //12
    '0', //13
    '.', //14
    '', //15
    '20.00', //16
    '50.00', //17
    '100.00', //18
    'GO', //19

  ];

  void _scrollDown() {
    _controller.jumpTo(_controller.position.maxScrollExtent);
  }

  @override
  void initState() {
    super.initState();
    streamController = StreamController();
    readAllBranchLinkDiningOption();
    readBranchPref();
    readSpecificPaymentMethod();
    readAllOrder();

  }

  @override
  void dispose() {
    inputController.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  void reassemble() {
    super.reassemble();
    if (Platform.isAndroid) {
      controller?.pauseCamera();
    } else if (Platform.isIOS) {
      controller?.resumeCamera();
    }
  }

  closeDialog(BuildContext context) {
    return Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    if (controller != null && mounted && result == null) {
      controller!.pauseCamera();
      controller!.resumeCamera();
    }

    return Consumer<ThemeColor>(builder: (context, ThemeColor color, child) {
      return LayoutBuilder(builder: (context,  constraints) {
          if(constraints.maxWidth > 800){
            return AlertDialog(
              title: Text('Amount'),
              content: Container(
                  width: MediaQuery.of(context).size.width / 1,
                  height: MediaQuery.of(context).size.height / 1,
                  child: StreamBuilder(
                      stream: streamController.stream, builder: (context, snapshot) {
                    return Consumer<CartModel>(builder: (context, CartModel cart, child) {
                      getSubTotal(cart);
                      getCartItemList(cart);
                      return Row(
                        children: [
                          Expanded(
                              child: Column(
                                children: [
                                  Container(
                                    margin: EdgeInsets.only(bottom: 20),
                                    alignment: Alignment.centerLeft,
                                    child: Text('Table No: ${getSelectedTable(cart)}', style: TextStyle(fontWeight: FontWeight.bold,fontSize: 20)),
                                  ),
                                  Card(
                                    elevation: 5,
                                    child: Column(
                                      children: [
                                        Container(
                                          height: MediaQuery.of(context).size.width < 1300 ? MediaQuery.of(context).size.width / 4.5 : MediaQuery.of(context).size.width / 5,
                                          child: ListView.builder(
                                              itemCount: cart.cartNotifierItem.length,
                                              itemBuilder: (context, index) {
                                                return ListTile(
                                                  hoverColor: Colors.transparent,
                                                  onTap: null,
                                                  isThreeLine: true,
                                                  title: RichText(
                                                    text: TextSpan(
                                                      children: <TextSpan>[
                                                        TextSpan(
                                                          text: cart.cartNotifierItem[index].name +'\n',
                                                          style: TextStyle(
                                                              fontSize: MediaQuery.of(context).size.height > 500 ? 20 : 15 ,
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
                                                          Text('x${cart.cartNotifierItem[index].quantity.toString()}',
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
                                        SizedBox(height: 10),
                                        Divider(
                                          color: Colors.grey,
                                          height: 1,
                                          thickness: 1,
                                          indent: 20,
                                          endIndent: 20,
                                        ),
                                        SizedBox(height: 10),
                                        Container(
                                          constraints: new BoxConstraints(
                                              maxHeight: MediaQuery.of(context).size.height < 500 && cart.selectedOption == 'Dine in' ? 31 :
                                              MediaQuery.of(context).size.height < 700 && cart.selectedOption == 'Dine in' ? 190 : 200
                                          ),
                                          // height: MediaQuery.of(context).size.height < 700 && cart.selectedOption == 'Dine in' ? 190
                                          //         : MediaQuery.of(context).size.height < 700 && cart.selectedOption == 'Take Away' ? 180
                                          //         : 200,
                                          child: ListView(
                                            controller: _controller,
                                            padding: EdgeInsets.only(left: 5, right: 5),
                                            physics: ClampingScrollPhysics(),
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
                                              ListView.builder(
                                                  shrinkWrap: true,
                                                  padding: EdgeInsets.zero,
                                                  physics: NeverScrollableScrollPhysics(),
                                                  itemCount: taxList.length,
                                                  itemBuilder: (context, index){
                                                    return ListTile(
                                                      title: Text('${taxList[index].name}(${taxList[index].tax_rate}%)'),
                                                      trailing: Text('${taxList[index].tax_amount?.toStringAsFixed(2)}'), //Text(''),
                                                      visualDensity: VisualDensity(vertical: -4),
                                                      dense: true,
                                                    );
                                                  }
                                              ),
                                              ListTile(
                                                title: Text("Total",
                                                    style: TextStyle(fontSize: 14)),
                                                trailing: Text('${totalAmount.toStringAsFixed(2)}',
                                                    style: TextStyle(fontSize: 14)),
                                                visualDensity: VisualDensity(vertical: -4),
                                                dense: true,
                                              ),
                                              ListTile(
                                                title: Text("Rounding",
                                                    style: TextStyle(fontSize: 14)),
                                                trailing: Text('${rounding.toStringAsFixed(2)}',
                                                    style: TextStyle(fontSize: 14)),
                                                visualDensity: VisualDensity(vertical: -4),
                                                dense: true,
                                              ),
                                              ListTile(
                                                visualDensity: VisualDensity(vertical: -4),
                                                title: Text("Final amount",
                                                    style: TextStyle(
                                                        fontSize: 18,
                                                        fontWeight: FontWeight.bold)),
                                                trailing: Text("${finalAmount}", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                                dense: true,
                                              ),
                                            ],
                                            shrinkWrap: true,
                                          ),
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
                          Container(
                            padding: EdgeInsets.fromLTRB(10, 0, 10, 0),
                            height: MediaQuery.of(context).size.height,
                            child: VerticalDivider(
                                color: Colors.grey, thickness: 1),
                          ),
                          Expanded(
                            child: widget.type == 0 ?
                            Container(
                              margin: EdgeInsets.fromLTRB(30, 0, 25, 0),
                              height: MediaQuery.of(context).size.height / 1,
                              child: Column(
                                children: [
                                  Container(
                                    margin: EdgeInsets.only(bottom: 10),
                                    alignment: Alignment.centerLeft,
                                    child: Text('Change: ${change}', style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold)),
                                  ),
                                  Container(
                                    width: double.infinity,
                                    alignment: AlignmentDirectional.bottomEnd,
                                    child: ValueListenableBuilder(
                                        valueListenable: inputController,
                                        builder: (context, TextEditingValue value, __) {
                                          return Container(
                                            child: TextField(
                                              onChanged: (value){
                                                calcChange(value);
                                              },
                                              keyboardType: TextInputType.number,
                                              textAlign: TextAlign.right,
                                              enabled: false,
                                              maxLines: 1,
                                              controller: inputController,
                                              decoration: InputDecoration(
                                                border: OutlineInputBorder(
                                                    borderSide: BorderSide(color: color.backgroundColor)),
                                                focusedBorder: OutlineInputBorder(
                                                  borderSide: BorderSide(color: color.backgroundColor),
                                                ),
                                              ),
                                              style:  TextStyle(fontSize: 40),
                                            ),
                                          );
                                        }),
                                  ),
                                  Expanded(
                                    flex: 7,
                                    child: GridView.builder(
                                        physics: NeverScrollableScrollPhysics(),
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
                                                if(inputController.text.length > 0){
                                                  double value = double.parse(inputController.text) - double.parse(finalAmount);
                                                  if(value > 0.0){
                                                    setState(() {
                                                      change = value.toStringAsFixed(2);
                                                    });
                                                  }
                                                  setState(() {
                                                    inputController.text = inputController.text.substring(0, inputController.text.length - 1);
                                                  });

                                                }else {
                                                  setState(() {
                                                    change = '0.00';
                                                  });
                                                }
                                              },
                                              buttonText: buttons[index],
                                              color: color.backgroundColor,
                                              textColor: Colors.white,
                                            );
                                          }
                                          // DEL button
                                          else if (index == 7) {
                                            return NumberButton(
                                              buttontapped: () {
                                                setState(() {
                                                  change = '0.00';
                                                  inputController.text = '';
                                                });
                                              },
                                              buttonText: buttons[index],
                                              color: color.buttonColor,
                                              textColor: Colors.white,
                                            );
                                          }
                                          // RM 20.00 btn
                                          else if (index == 16) {
                                            return NumberButton(
                                              buttontapped: () {
                                                setState(() {
                                                  inputController.text = buttons[index];
                                                });
                                                double value = double.parse(inputController.text) - double.parse(finalAmount);
                                                if(value > 0.0){
                                                  setState(() {
                                                    change = value.toStringAsFixed(2);
                                                  });
                                                }
                                              },
                                              buttonText: buttons[index],
                                              color: color.backgroundColor,
                                              textColor: Colors.white,
                                            );
                                          }
                                          //RM 50 btn
                                          else if (index == 17) {
                                            return NumberButton(
                                              buttontapped: () {
                                                setState(() {
                                                  inputController.text = buttons[index];
                                                });
                                                double value = double.parse(inputController.text) - double.parse(finalAmount);
                                                if(value > 0.0){
                                                  setState(() {
                                                    change = value.toStringAsFixed(2);
                                                  });
                                                }
                                              },
                                              buttonText: buttons[index],
                                              color: color.buttonColor,
                                              textColor: Colors.white,
                                            );
                                          }
                                          //RM 100 btn
                                          else if (index == 18) {
                                            return NumberButton(
                                              buttontapped: () {
                                                setState(() {
                                                  inputController.text = buttons[index];
                                                });
                                                double value = double.parse(inputController.text) - double.parse(finalAmount);
                                                if(value > 0.0){
                                                  setState(() {
                                                    change = value.toStringAsFixed(2);
                                                  });
                                                }
                                              },
                                              buttonText: buttons[index],
                                              color: color.backgroundColor,
                                              textColor: Colors.white,
                                            );
                                          }
                                          //GO button
                                          else if (index == 19) {
                                            return NumberButton(
                                              buttontapped: () async  {
                                                bool _isCreated = false;
                                                if(double.parse(inputController.text) >= double.parse(finalAmount)){
                                                  await callCreateOrder(inputController.text, orderChange: change);
                                                  _isCreated = true;
                                                  if(_isCreated == true){
                                                    openPaymentSuccessDialog(widget.dining_id);
                                                    ReceiptLayout().openCashDrawer();
                                                  }
                                                } else {
                                                  Fluttertoast.showToast(
                                                      backgroundColor: Color(0xFFFF0000),
                                                      msg: "Insufficient balance");
                                                  setState(() {
                                                    inputController.text = '0.00';
                                                  });
                                                }
                                              },
                                              buttonText: buttons[index],
                                              color: color.buttonColor,
                                              textColor: Colors.white,
                                            );
                                          }
                                          //  other buttons
                                          else {
                                            return NumberButton(
                                              buttontapped: () {
                                                if(inputController.text.length < 6){
                                                  if(inputController.text.contains('.')){
                                                    var decimal = inputController.text.split(".")[1].length;
                                                    if(decimal < 2){
                                                      setState(() {
                                                        inputController.text += buttons[index];
                                                      });
                                                    }
                                                  } else {
                                                    setState(() {
                                                      inputController.text += buttons[index];
                                                    });
                                                  }
                                                }
                                                double value = double.parse(inputController.text) - double.parse(finalAmount);
                                                if(value > 0.0){
                                                  setState(() {
                                                    change = value.toStringAsFixed(2);
                                                  });
                                                }
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
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    child: ClipRRect(
                                      borderRadius:
                                      BorderRadius.circular(16.0),
                                      child:
                                      ///***If you have exported images you must have to copy those images in assets/images directory.
                                      Image(
                                        image: NetworkImage(
                                            "https://v.icbc.com.cn/userfiles/Resources/ICBC/haiwai/Malaysia/photo/2021/mobil202108034.jpg"),
                                      ),
                                    ),
                                  ),
                                  Container(
                                    margin: EdgeInsets.all(20),
                                    child: Text('RM${finalAmount}',style: TextStyle(fontSize: 40,fontWeight: FontWeight.bold),),
                                  ),
                                  Container(
                                    child: ElevatedButton(
                                      style: ButtonStyle(
                                          backgroundColor: MaterialStateProperty.all(Colors.green),
                                        padding: MaterialStateProperty.all(EdgeInsets.all(20))
                                      ),
                                      onPressed: () async {
                                        await callCreateOrder(finalAmount);
                                        openPaymentSuccessDialog(widget.dining_id);
                                      }, child: Text("Received payment",style:TextStyle(fontSize: 25)),

                                    ),
                                  ),
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
                                          margin: EdgeInsets.all(25),
                                          child: _buildQrView(context),
                                        ),

                                      )
                                  ),
                                  Expanded(
                                      flex:1,
                                      child: Container(
                                        alignment: Alignment.center,
                                        child: Text('RM${finalAmount}',style: TextStyle(fontSize: 40,fontWeight: FontWeight.bold)),
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
                                              setState(() {
                                                scanning = true;
                                              });
                                              //await controller?.resumeCamera();
                                              await controller?.scannedDataStream;
                                              await callCreateOrder(finalAmount);

                                            }, child: Text(scanning==false?"Start Scan":"Scanning...",style:TextStyle(fontSize: 25)),

                                          ),
                                        ),
                                      )
                                  ),
                                ],
                              ) ,
                            ):Container(),
                          )
                        ],
                      );
                    });
                  })
              ),
            );
          } else {
            //mobile view
            return Center(
              child: SingleChildScrollView(
                child: AlertDialog(
                  title: Text('Amount'),
                  content: Container(
                      width: MediaQuery.of(context).size.width / 1,
                      height: MediaQuery.of(context).size.height/ 1.8,
                      child: StreamBuilder(stream: streamController.stream, builder: (context, snapshot) {
                        return Consumer<CartModel>(builder: (context, CartModel cart, child) {
                          getSubTotal(cart);
                          getCartItemList(cart);
                          return Row(
                            children: [
                              Expanded(
                                  child: Column(
                                    children: [
                                      Container(
                                        padding: EdgeInsets.only(bottom: 5),
                                        alignment: Alignment.centerLeft,
                                        child: Text('Table No: ${getSelectedTable(cart)}'),
                                      ),
                                      Card(
                                        elevation: 5,
                                        child: Column(
                                          children: [
                                            Container(
                                              height: MediaQuery.of(context).size.height / 4,
                                              child: ListView.builder(
                                                  itemCount: cart.cartNotifierItem.length,
                                                  padding: EdgeInsets.only(top: 10),
                                                  itemBuilder: (context, index) {
                                                    return ListTile(
                                                      onTap: null,
                                                      isThreeLine: true,
                                                      title: RichText(
                                                        text: TextSpan(
                                                          children: <TextSpan>[
                                                            TextSpan(
                                                              text: cart.cartNotifierItem[index].name +'\n',
                                                              style: TextStyle(
                                                                  fontSize: 15 ,
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
                                                              Text('x${cart.cartNotifierItem[index].quantity.toString()}',
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
                                            SizedBox(height: 5),
                                            Divider(
                                              color: Colors.grey,
                                              height: 1,
                                              thickness: 1,
                                              indent: 20,
                                              endIndent: 20,
                                            ),
                                            SizedBox(height: 5),
                                            Container(
                                              constraints: new BoxConstraints(
                                                  maxHeight: MediaQuery.of(context).size.height < 500 && cart.selectedOption == 'Dine in' ? 31 :
                                                  MediaQuery.of(context).size.height < 700 && cart.selectedOption == 'Dine in' ? 190 : 200
                                              ),
                                              // height: MediaQuery.of(context).size.height < 700 && cart.selectedOption == 'Dine in' ? 190
                                              //         : MediaQuery.of(context).size.height < 700 && cart.selectedOption == 'Take Away' ? 180
                                              //         : 200,
                                              child: ListView(
                                                controller: _controller,
                                                padding: EdgeInsets.only(left: 5, right: 5),
                                                physics: ClampingScrollPhysics(),
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
                                                  ListView.builder(
                                                      shrinkWrap: true,
                                                      padding: EdgeInsets.zero,
                                                      physics: NeverScrollableScrollPhysics(),
                                                      itemCount: taxList.length,
                                                      itemBuilder: (context, index){
                                                        return ListTile(
                                                          title: Text('${taxList[index].name}(${taxList[index].tax_rate}%)'),
                                                          trailing: Text('${taxList[index].tax_amount?.toStringAsFixed(2)}'), //Text(''),
                                                          visualDensity: VisualDensity(vertical: -4),
                                                          dense: true,
                                                        );
                                                      }
                                                  ),
                                                  ListTile(
                                                    title: Text("Total",
                                                        style: TextStyle(fontSize: 14)),
                                                    trailing: Text('${totalAmount.toStringAsFixed(2)}',
                                                        style: TextStyle(fontSize: 14)),
                                                    visualDensity: VisualDensity(vertical: -4),
                                                    dense: true,
                                                  ),
                                                  ListTile(
                                                    title: Text("Rounding",
                                                        style: TextStyle(fontSize: 14)),
                                                    trailing: Text('${rounding.toStringAsFixed(2)}',
                                                        style: TextStyle(fontSize: 14)),
                                                    visualDensity: VisualDensity(vertical: -4),
                                                    dense: true,
                                                  ),
                                                  ListTile(
                                                    visualDensity: VisualDensity(vertical: -4),
                                                    title: Text("Final amount",
                                                        style: TextStyle(
                                                            fontSize: 18,
                                                            fontWeight: FontWeight.bold)),
                                                    trailing: Text("${finalAmount}", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                                    dense: true,
                                                  ),
                                                ],
                                                shrinkWrap: true,
                                              ),
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
                              Container(
                                padding: EdgeInsets.fromLTRB(5, 0, 5, 0),
                                height: MediaQuery.of(context).size.height/2,
                                child: VerticalDivider(
                                    color: Colors.grey, thickness: 1),
                              ),
                              Expanded(
                                child: widget.type == 0 ?
                                Container(
                                  height: MediaQuery.of(context).size.height / 1 ,
                                  child: Column(
                                    children: [
                                      Container(
                                        margin: EdgeInsets.only(bottom: 10),
                                        alignment: Alignment.centerLeft,
                                        child: Text('Change: ${change}'),
                                      ),
                                      Expanded(
                                        flex: 2,
                                        child: Column(
                                          children: [
                                            Container(
                                              margin: EdgeInsets.only(bottom: 10),
                                              child: ValueListenableBuilder(
                                                  valueListenable: inputController,
                                                  builder: (context, TextEditingValue value, __) {
                                                    return Container(
                                                      child: TextField(
                                                        onChanged: (value){
                                                          calcChange(value);
                                                        },
                                                        keyboardType: TextInputType.number,
                                                        textAlign: TextAlign.right,
                                                        enabled: MediaQuery.of(context).size.height > 500 ? false : true,
                                                        maxLines: 1,
                                                        controller: inputController,
                                                        decoration: InputDecoration(
                                                          border: OutlineInputBorder(
                                                              borderSide: BorderSide(color: color.backgroundColor)),
                                                          focusedBorder: OutlineInputBorder(
                                                            borderSide: BorderSide(color: color.backgroundColor),
                                                          ),
                                                        ),
                                                        style:  TextStyle(fontSize: 40),
                                                      ),
                                                    );
                                                  }),
                                            ),
                                            Expanded(
                                              child: Row(
                                                mainAxisAlignment: MainAxisAlignment.center,
                                                children: [
                                                  Container(
                                                    child: ElevatedButton(
                                                        onPressed: () async {
                                                          if(double.parse(inputController.text) >= double.parse(finalAmount)){
                                                            await callCreateOrder(inputController.text, orderChange: change);
                                                            openPaymentSuccessDialog(widget.dining_id);
                                                            ReceiptLayout().openCashDrawer();
                                                          } else {
                                                            Fluttertoast.showToast(
                                                                backgroundColor: Color(0xFFFF0000),
                                                                msg: "Insufficient balance");
                                                            setState(() {
                                                              inputController.text = '0.00';
                                                            });
                                                          }
                                                        },
                                                        child: Text('Pay')),
                                                  ),
                                                  SizedBox(width: 10,),
                                                  Container(
                                                    child: ElevatedButton(
                                                        onPressed: () async {
                                                          inputController.clear();
                                                          change = '0.00';
                                                        },
                                                        child: Text('Clear')),
                                                  ),
                                                ],
                                              ),
                                            )
                                          ],
                                        ),
                                      ),
                                    ],
                                  ), // GridView.builder
                                ): widget.type == 1  ?
                                Container(
                                  child: Column(
                                    children: [
                                      Container(
                                        height: MediaQuery.of(context).size.height / 3,
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

                                      ),
                                      Container(
                                        alignment: Alignment.center,
                                        child: Text('RM${finalAmount}',style: TextStyle(fontSize: 20,fontWeight: FontWeight.bold),),
                                      ),
                                      Container(
                                        alignment: Alignment.center,
                                        child: ElevatedButton(
                                          style: ButtonStyle(backgroundColor: MaterialStateProperty.all(Colors.green)),
                                          onPressed: () async {
                                            await callCreateOrder(finalAmount);
                                            openPaymentSuccessDialog(widget.dining_id);
                                          }, child: Text("Received payment",style:TextStyle(fontSize: 20)),
                                        ),
                                      ),
                                    ],
                                  ) ,
                                ): widget.type == 2 ?
                                Container(
                                  child: Column(
                                    children: [
                                      Container(
                                        height: scanning ? MediaQuery.of(context).size.height / 2 : MediaQuery.of(context).size.height / 3,
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
                                          child: _buildQrViewMobile(context),
                                        ),
                                      ),
                                      Visibility(
                                        visible: scanning ? false: true,
                                        child: Container(
                                          alignment: Alignment.center,
                                          child: Text('RM${finalAmount}',style: TextStyle(fontSize: 20,fontWeight: FontWeight.bold))
                                        ),
                                      ),
                                      Visibility(
                                        visible: scanning ? false : true,
                                        child: Container(
                                          alignment: Alignment.center,
                                          child: ElevatedButton(
                                            style: ButtonStyle(backgroundColor: MaterialStateProperty.all(color.backgroundColor) ),
                                            onPressed: () async {
                                              setState(() {
                                                scanning = true;
                                              });
                                              //await controller?.resumeCamera();
                                              await controller?.scannedDataStream;
                                              await callCreateOrder(finalAmount);

                                            }, child: Text("Start Scan",style:TextStyle(fontSize: 20)),

                                          ),
                                        ),
                                      )
                                    ],
                                  ) ,
                                ):Container(),
                              )
                            ],
                          );
                        });
                      })
                  ),
                ),
              ),
            );
          }
        }
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
  Widget _buildQrViewMobile(BuildContext context) {
    // For this example we check how width or tall the device is and change the scanArea and overlay accordingly.
    var scanArea = 200.00;
    // To ensure the Scanner view is properly sizes after rotation
    // we need to listen for Flutter SizeChanged notification and update controller
    return QRView(
      key: qrKey,
      onQRViewCreated: _onQRViewCreated,
      overlay: QrScannerOverlayShape(
          borderColor: Colors.redAccent,
          borderRadius: 5,
          borderLength: 20,
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

  void _onQRViewCreated(QRViewController p1){
    setState(() {
      this.controller = p1;
    });

    p1.scannedDataStream.listen((scanData) async {
      setState(() {
        result = scanData;
        print('result:${result?.code}');
      });
      p1.pauseCamera();

      var api = await paymentApi();
      if(api != 0){
        // await updateOrder();
        openPaymentSuccessDialog(widget.dining_id);
      } else {
        Navigator.of(context).pop();
        Fluttertoast.showToast(
            backgroundColor: Color(0xFFFF0000), msg: "${api}");
      }
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
  Future<Future<Object?>> openPaymentSuccessDialog(String dining_id) async {
    return showGeneralDialog(
        barrierColor: Colors.black.withOpacity(0.5),
        transitionBuilder: (context, a1, a2, widget) {
          final curvedValue = Curves.easeInOutBack.transform(a1.value) - 1.0;
          return Transform(
            transform: Matrix4.translationValues(0.0, curvedValue * 200, 0.0),
            child: Opacity(
              opacity: a1.value,
              child: PaymentSuccessDialog(
                dining_id: dining_id,
                orderCacheIdList: orderCacheIdList,
                selectedTableList: selectedTableList,
                callback: () => Navigator.of(context).pop(),
                orderId: orderId!,
                orderKey: orderKey!,
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
/*
  -----------------------Cart-item--------------------------------------------------------------------------------------------------------------------------------------------------
*/
/*
  get selected table
*/
  getSelectedTable(CartModel cart) {
    List<String> result = [];
    if(cart.selectedOption == 'Dine in'){
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
    } else {
      return 'N/A';
    }

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
      promotion.promoAmount = selectedPromo;
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
            selectedPromo += double.parse(cart.selectedPromotion!.amount!) * cart.cartNotifierItem[i].quantity;
          }
        }
      }
      promoAmount += selectedPromo;
      cart.selectedPromotion!.promoAmount = selectedPromo;
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
            }
          } else {
            //Auto apply non specific category promotion
            if (cart.cartNotifierItem.isNotEmpty) {
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

  addAllPromotion(CartModel cartModel){
    if(autoApplyPromotionList.length > 0) {
      for (int i = 0; i < autoApplyPromotionList.length; i++){
        if(!appliedPromotionList.contains(autoApplyPromotionList[i])){
          appliedPromotionList.add(autoApplyPromotionList[i]);
        }
      }
    }
    if(cartModel.selectedPromotion != null){
      if(!appliedPromotionList.contains(cartModel.selectedPromotion!)){
        appliedPromotionList.add(cartModel.selectedPromotion!);
      }
    }
  }

  getCartItemList(CartModel cart){
    orderCacheIdList = [];
    selectedTableList = [];
    for(int i = 0; i < cart.cartNotifierItem.length; i++){
      if(!orderCacheIdList.contains(cart.cartNotifierItem[i].orderCacheId!)){
        orderCacheIdList.add(cart.cartNotifierItem[i].orderCacheId!);
      }
    }
    for(int j = 0; j < cart.selectedTable.length; j++){
      if(!selectedTableList.contains(cart.selectedTable[j].table_sqlite_id)){
        selectedTableList.add(cart.selectedTable[j]);
      }
    }

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
    calPromotion(cart);
    getTaxAmount();
    getRounding();
    getAllTotal();
    addAllPromotion(cart);
    if(myCount == 0){
      WidgetsBinding.instance.addPostFrameCallback((_) {
        setState(() {
          _scrollDown();
        });
      });
      myCount++;
    }
    streamController.add('refresh');
  }

  getTaxAmount() {
    try{
      discountPrice = total - promoAmount;
      if(taxList.length > 0){
        for(int i = 0; i < taxList.length; i++){
          priceIncTaxes = discountPrice * (double.parse(taxList[i].tax_rate!)/100);
          taxList[i].tax_amount = priceIncTaxes;
        }
      }
    }catch(e){
      print('get tax amount error: $e');
    }

    streamController.add('refresh');
  }

  getAllTaxAmount(){
    double total = 0.0;
    if(taxList.length > 0){
      for(int i = 0; i < taxList.length; i++){
        total = total + taxList[i].tax_amount!;
      }
    }
    priceIncAllTaxes = total;

    return priceIncAllTaxes;
  }

  getRounding(){
    double _round = 0.0;
    _round = double.parse(totalAmount.toStringAsFixed(1)) - double.parse(totalAmount.toStringAsFixed(2));
    if(_round.toStringAsFixed(2) != '0.05' && _round.toStringAsFixed(2) != '-0.05'){
      rounding = _round;
    } else {
      rounding = 0.0;
    }

    streamController.add('refresh');
  }

  getAllTotal() {
    getAllTaxAmount();
    try {
      discountPrice = total - promoAmount;
      totalAmount = discountPrice + priceIncAllTaxes;

      if(rounding == 0.0){
        finalAmount = totalAmount.toStringAsFixed(2);
      } else {
        finalAmount = totalAmount.toStringAsFixed(1) + '0';
      }
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
    final prefs = await SharedPreferences.getInstance();
    final int? branch_id = prefs.getInt('branch_id');
    try {
      diningOptionID = 0;
      this.diningName = cart.selectedOption;
      //get dining option data
      List<DiningOption> data = await PosDatabase.instance.checkSelectedOption(cart.selectedOption);
      diningOptionID = data[0].dining_id!;
      //get dining tax
      List<Tax> taxData = await PosDatabase.instance.readTax(branch_id.toString(), diningOptionID.toString());
      if (taxData.length > 0) {
        taxList = List.from(taxData);
      } else {
        taxList = [];
      }
    } catch (error) {
      print('get dining tax error: $error');
    }

    streamController.add('refresh');
  }

  callCreateOrder(String? paymentReceived, {orderChange}) async {
    await createOrder(double.parse(paymentReceived!), orderChange);
    await insertOrderKey();
    await crateOrderTaxDetail();
    await createOrderPromotionDetail();
  }

  readBranchPref() async {
    final prefs = await SharedPreferences.getInstance();
    final String? branch = prefs.getString('branch');
    branchObject = json.decode(branch!);
  }

  generateOrderKey(Order order) async  {
    final prefs = await SharedPreferences.getInstance();
    final int? device_id = prefs.getInt('device_id');
    var bytes  = order.created_at!.replaceAll(new RegExp(r'[^0-9]'),'') + order.order_sqlite_id.toString() + device_id.toString();
    print('bytes: ${bytes}');
    return md5.convert(utf8.encode(bytes)).toString();
  }

  generateOrderNumber(){
    int orderNum = 0;
    if(orderList.isNotEmpty){
      orderNum = int.parse(orderList[0].order_number!) + 1;
    } else {
      orderNum = 1;
    }
    return orderNum;
  }

  createOrder(double? paymentReceived, String? orderChange) async {
    DateFormat dateFormat = DateFormat("yyyy-MM-dd HH:mm:ss");
    String dateTime = dateFormat.format(DateTime.now());
    final prefs = await SharedPreferences.getInstance();
    final String? login_user = prefs.getString('user');
    final int? branch_id = prefs.getInt('branch_id');
    final String? pos_user = prefs.getString('pos_pin_user');
    Map logInUser = json.decode(login_user!);
    Map userObject = json.decode(pos_user!);
    int orderNum = generateOrderNumber();

    try{
      if(orderNum != 0){
        Order orderObject = Order(
            order_id: 0,
            order_number: orderNum.toString().padLeft(5 ,'0'),
            company_id: logInUser['company_id'].toString(),
            branch_id:  branch_id.toString(),
            customer_id: '',
            dining_id: widget.dining_id,
            dining_name: this.diningName,
            branch_link_promotion_id: '',
            payment_link_company_id: widget.payment_link_company_id.toString(),
            branch_link_tax_id: '',
            subtotal: total.toStringAsFixed(2),
            amount: totalAmount.toStringAsFixed(2),
            rounding: rounding.toStringAsFixed(2),
            final_amount: finalAmount,
            close_by: userObject['name'].toString(),
            payment_received: paymentReceived == null ? '' : paymentReceived.toStringAsFixed(2),
            payment_change: orderChange == null ? '0.00' : orderChange,
            payment_status: 0,
            order_key: '',
            sync_status: 0,
            created_at: dateTime,
            updated_at: '',
            soft_delete: ''
        );
        Order data = await PosDatabase.instance.insertSqliteOrder(orderObject);
        this.orderId = data.order_sqlite_id.toString();
      }
      
    }catch(e){
      print('create order error: ${e}');
      Fluttertoast.showToast(
          backgroundColor: Color(0xFFFF0000),
          msg: "Create order cache error: ${e}");
    }
  }

  insertOrderKey() async {
    DateFormat dateFormat = DateFormat("yyyy-MM-dd HH:mm:ss");
    String dateTime = dateFormat.format(DateTime.now());
    List<String> _value = [];
    await readAllOrder();
    orderKey = await generateOrderKey(orderList[0]);
    if(orderKey != null){
      Order orderObject = Order(
        order_key: orderKey,
        sync_status: 0,
        updated_at: dateTime,
        order_sqlite_id: orderList[0].order_sqlite_id
      );
      int updatedData = await PosDatabase.instance.updateOrderUniqueKey(orderObject);
      if(updatedData == 1){
        Order orderData = await PosDatabase.instance.readSpecificOrder(orderObject.order_sqlite_id!);
        _value.add(jsonEncode(orderData));
      }
    }
    //sync to cloud
    Map data = await Domain().SyncOrderToCloud(_value.toString());
    if (data['status'] == '1') {
      List responseJson = data['data'];
      for (var i = 0; i < responseJson.length; i++) {
        int orderData = await PosDatabase.instance.updateOrderSyncStatusFromCloud(responseJson[i]['order_key']);
      }
    }
  }

  generateOrderPromotionDetailKey(OrderPromotionDetail orderPromotionDetail) async  {
    final prefs = await SharedPreferences.getInstance();
    final int? device_id = prefs.getInt('device_id');
    var bytes  = orderPromotionDetail.created_at!.replaceAll(new RegExp(r'[^0-9]'),'') + orderPromotionDetail.order_promotion_detail_sqlite_id.toString() + device_id.toString();
    return md5.convert(utf8.encode(bytes)).toString();
  }

  insertOrderPromotionDetailKey(OrderPromotionDetail orderPromotionDetail, String dateTime) async {
    String? _key;
    OrderPromotionDetail? _data;
    _key = await generateOrderPromotionDetailKey(orderPromotionDetail);
    if(_key != null){
      OrderPromotionDetail orderPromoDetailObject = OrderPromotionDetail(
          order_promotion_detail_key: _key,
          sync_status: 0,
          updated_at: dateTime,
          order_promotion_detail_sqlite_id: orderPromotionDetail.order_promotion_detail_sqlite_id
      );
      int updatedData = await PosDatabase.instance.updateOrderPromotionDetailUniqueKey(orderPromoDetailObject);
      if(updatedData == 1){
        OrderPromotionDetail orderPromotionDetailData = await PosDatabase.instance.readSpecificOrderPromotionDetailByLocalId(orderPromoDetailObject.order_promotion_detail_sqlite_id!);
        _data = orderPromotionDetailData;
      }
    }
    return _data;
  }

  createOrderPromotionDetail() async {
    DateFormat dateFormat = DateFormat("yyyy-MM-dd HH:mm:ss");
    String dateTime = dateFormat.format(DateTime.now());
    final prefs = await SharedPreferences.getInstance();
    final int? branch_id = prefs.getInt('branch_id');
    List<String> _value = [];

    for (int i = 0; i < appliedPromotionList.length; i++) {
      List<BranchLinkPromotion> branchPromotionData = await PosDatabase.instance.readSpecificBranchLinkPromotion(branch_id.toString(), appliedPromotionList[i].promotion_id.toString());
      OrderPromotionDetail data = await PosDatabase.instance
          .insertSqliteOrderPromotionDetail(OrderPromotionDetail(
          order_promotion_detail_id: 0,
          order_promotion_detail_key: '',
          order_sqlite_id: orderId,
          order_id: '0',
          order_key: orderKey,
          promotion_name: appliedPromotionList[i].name,
          promotion_id: appliedPromotionList[i].promotion_id.toString(),
          rate: appliedPromotionList[i].promoRate,
          promotion_amount: appliedPromotionList[i].promoAmount!.toStringAsFixed(2),
          promotion_type: appliedPromotionList[i].type,
          branch_link_promotion_id: branchPromotionData[0].branch_link_promotion_id.toString(),
          auto_apply: appliedPromotionList[i].auto_apply!,
          sync_status: 0,
          created_at: dateTime,
          updated_at: '',
          soft_delete: ''
      ));
      OrderPromotionDetail returnData = await insertOrderPromotionDetailKey(data, dateTime);
      _value.add(jsonEncode(returnData));
    }
    //sync to cloud
    Map data = await Domain().SyncOrderPromotionDetailToCloud(_value.toString());
    if (data['status'] == '1') {
      List responseJson = data['data'];
      for (var i = 0; i < responseJson.length; i++) {
        int orderPromoData = await PosDatabase.instance.updateOrderPromotionDetailSyncStatusFromCloud(responseJson[i]['order_promotion_detail_key']);
      }
    }
  }

  generateOrderTaxDetailKey(OrderTaxDetail orderTaxDetail) async  {
    final prefs = await SharedPreferences.getInstance();
    final int? device_id = prefs.getInt('device_id');
    var bytes  = orderTaxDetail.created_at!.replaceAll(new RegExp(r'[^0-9]'),'') + orderTaxDetail.order_tax_detail_key.toString() + device_id.toString();
    return md5.convert(utf8.encode(bytes)).toString();
  }

  insertOrderTaxDetailKey(OrderTaxDetail orderTaxDetail, String dateTime) async {
    String? _key;
    OrderTaxDetail? _data;
    _key = await generateOrderTaxDetailKey(orderTaxDetail);
    if(_key != null){
      OrderTaxDetail orderTaxDetailObject = OrderTaxDetail(
          order_tax_detail_key: _key,
          sync_status: 0,
          updated_at: dateTime,
          order_tax_detail_sqlite_id: orderTaxDetail.order_tax_detail_sqlite_id
      );
      int updatedData = await PosDatabase.instance.updateOrderTaxDetailUniqueKey(orderTaxDetailObject);
      if(updatedData == 1 ){
        OrderTaxDetail orderTaxDetailData = await PosDatabase.instance.readSpecificOrderTaxDetailByLocalId(orderTaxDetailObject.order_tax_detail_sqlite_id!);
        _data = orderTaxDetailData;
      }
    }
    return _data;
  }

  crateOrderTaxDetail() async {
    print('order tax detail called');
    DateFormat dateFormat = DateFormat("yyyy-MM-dd HH:mm:ss");
    String dateTime = dateFormat.format(DateTime.now());
    final prefs = await SharedPreferences.getInstance();
    final int? branch_id = prefs.getInt('branch_id');
    List<String> _value = [];

    for(int i = 0; i < taxList.length; i++){
      List<BranchLinkTax> branchTaxData = await PosDatabase.instance.readSpecificBranchLinkTax(branch_id.toString(), taxList[i].tax_id.toString());
      if(branchTaxData.length > 0){
        OrderTaxDetail data = await PosDatabase.instance.insertSqliteOrderTaxDetail(OrderTaxDetail(
            order_tax_detail_id: 0,
            order_tax_detail_key: '',
            order_sqlite_id: orderId,
            order_id: '0',
            order_key: orderKey,
            tax_name: taxList[i].name,
            rate: taxList[i].tax_rate,
            tax_id: taxList[i].tax_id.toString(),
            branch_link_tax_id: branchTaxData[0].branch_link_tax_id.toString(),
            tax_amount: taxList[i].tax_amount!.toStringAsFixed(2),
            sync_status: 0,
            created_at: dateTime,
            updated_at: '',
            soft_delete: ''
        ));
        OrderTaxDetail returnData = await insertOrderTaxDetailKey(data, dateTime);
        _value.add(jsonEncode(returnData));
      }
    }
    //sync to cloud
    Map data = await Domain().SyncOrderTaxDetailToCloud(_value.toString());
    if (data['status'] == '1') {
      List responseJson = data['data'];
      for (var i = 0; i < responseJson.length; i++) {
        int syncData = await PosDatabase.instance.updateOrderTaxDetailSyncStatusFromCloud(responseJson[i]['order_tax_detail_key']);
      }
    }
  }

  readSpecificPaymentMethod() async {
    List<PaymentLinkCompany> data = await PosDatabase.instance.readPaymentMethodByType(widget.type.toString());
    if(data.length > 0){
      ipay_code = data[0].ipay_code!;
    }
  }

  readAllOrder() async {
    List<Order> data = await PosDatabase.instance.readLatestOrder();
    orderList = List.from(data);

  }

/*
  -------------------API Call---------------------------------------------------------------------------------------------------------------------------------------------------------
*/

  paymentApi() async {
    var response = await Api().sendPayment(
        branchObject['ipay_merchant_code'],
        branchObject['ipay_merchant_key'],
        336,
        orderId!,
        '1.00',
        'MYR',
        'ipay',
        branchObject['name'],
        'jacksonleow6@gmail.com',
        '0127583579',
        'taylor',
        result!.code!,
        '',
        '',
        '',
        '',
        signature256(
          branchObject['ipay_merchant_key'],
          branchObject['ipay_merchant_code'],
          orderId!,
          '100',
          'MYR',
          '',
          result!.code!,
          ''
        )
    );
    if(response != null){
      print('res: ${response}');
      return response;
    } else {
      return 0;
    }
  }

  signature256(var merchant_key, var merchant_code, var refNo, var amount, var currency, var xFields, var barcodeNo, var TerminalId ){
    var signature = utf8.encode(merchant_key + merchant_code + refNo + amount + currency + xFields + barcodeNo + TerminalId);
    String value = sha256.convert(signature).toString();
    return value;
  }

  calcChange(String amount){
    if(amount != ''){
      double value = double.parse(amount) - double.parse(finalAmount);
      setState(() {
        change = value.toStringAsFixed(2);
      });
    } else {
      change = '0.00';
    }

  }
}


