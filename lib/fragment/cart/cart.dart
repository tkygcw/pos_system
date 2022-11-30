import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:confirm_dialog/confirm_dialog.dart';
import 'package:esc_pos_printer/esc_pos_printer.dart';
import 'package:esc_pos_utils/esc_pos_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_usb_printer/flutter_usb_printer.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';
import 'package:pos_system/fragment/cart/cart_dialog.dart';
import 'package:pos_system/fragment/cart/promotion_dialog.dart';
import 'package:pos_system/fragment/cart/remove_cart_dialog.dart';
import 'package:pos_system/notifier/cart_notifier.dart';
import 'package:pos_system/notifier/theme_color.dart';
import 'package:pos_system/object/branch_link_dining_option.dart';
import 'package:pos_system/object/branch_link_promotion.dart';
import 'package:pos_system/object/cart_product.dart';
import 'package:pos_system/object/dining_option.dart';
import 'package:pos_system/object/modifier_group.dart';
import 'package:pos_system/object/order.dart';
import 'package:pos_system/object/order_cache.dart';
import 'package:pos_system/object/order_detail.dart';
import 'package:pos_system/object/order_promotion_detail.dart';
import 'package:pos_system/object/order_tax_detail.dart';
import 'package:pos_system/object/printer_link_category.dart';
import 'package:pos_system/object/promotion.dart';
import 'package:pos_system/object/table_use.dart';
import 'package:pos_system/object/table_use_detail.dart';
import 'package:pos_system/object/tax_link_dining.dart';
import 'package:pos_system/object/variant_group.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../database/domain.dart';
import '../../database/pos_database.dart';
import '../../object/cash_record.dart';
import '../../object/order_modifier_detail.dart';
import '../../object/printer.dart';
import '../../object/receipt_layout.dart';
import '../../object/table.dart';
import '../../object/tax.dart';
import '../../translation/AppLocalizations.dart';
import '../settlement/cash_dialog.dart';
import '../payment/payment_select_dialog.dart';

class CartPage extends StatefulWidget {
  final String currentPage;
  const CartPage({required this.currentPage, Key? key}) : super(key: key);

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  late StreamController controller;
  FlutterUsbPrinter flutterUsbPrinter = FlutterUsbPrinter();
  List<Printer> printerList = [];
  List<Promotion> promotionList = [];
  List<String> diningList = [];
  List<String> branchLinkDiningIdList = [];
  List<cartProductItem> sameCategoryItemList = [];
  List<Promotion> autoApplyPromotionList = [];
  List<TableUse> tableUseList = [];
  List<Tax> taxRateList = [];
  List<OrderTaxDetail> orderTaxList = [];
  List<OrderPromotionDetail> orderPromotionList = [];
  int diningOptionID = 0;
  int simpleIntInput = 0;
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
  double paymentReceived = 0.0;
  double paymentChange = 0.0;
  String selectedPromoRate = '';
  String promoName = '';
  String promoRate = '';
  String localTableUseId = '';
  String orderCacheId = '';
  String? allPromo = '';
  String finalAmount = '';
  String localOrderId = '';
  bool hasPromo = false;
  bool hasSelectedPromo = false;
  bool _isSettlement = false;
  Color font = Colors.black45;

  @override
  void initState() {
    super.initState();
    controller = StreamController();
    readAllBranchLinkDiningOption();
    getPromotionData();
    readAllPrinters();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  void deactivate() {
    // TODO: implement deactivate
    controller.close();
    super.deactivate();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeColor>(builder: (context, ThemeColor color, child) {
      return Padding(
        padding: const EdgeInsets.all(8.0),
        child: Consumer<CartModel>(builder: (context, CartModel cart, child) {
          widget.currentPage == 'menu' ||
          widget.currentPage == 'table' ||
          widget.currentPage == 'qr_order'||
          widget.currentPage == 'other_order' ?
          getSubTotal(cart) : getReceiptPaymentDetail(cart);
          return Scaffold(
            resizeToAvoidBottomInset: false,
            appBar: AppBar(
              automaticallyImplyLeading: false,
              title: Row(
                children: [
                  MediaQuery.of(context).size.height > 500 ? Text('Bill', style: TextStyle(fontSize: 20, color: Colors.black)): SizedBox.shrink(),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text('Table: ${getSelectedTable(cart)}'),
                    ),
                  ),
                ],
              ),
              backgroundColor: Colors.white,
              actions: [
                Visibility(
                  visible: cart.selectedOption == 'Dine in' && widget.currentPage == 'menu'
                      ? true
                      : false,
                  child: IconButton(
                    tooltip: 'table',
                    icon: const Icon(
                      Icons.table_restaurant,
                    ),
                    color: color.backgroundColor,
                    onPressed: () {
                      //tableDialog(context);
                      openChooseTableDialog(cart);
                    },
                  ),
                ),
                Visibility(
                  visible: widget.currentPage == 'menu' ||
                           widget.currentPage == 'qr_order' ||
                           widget.currentPage == 'bill' ||
                           widget.currentPage == 'other_order'?
                           false : true,
                  child: IconButton(
                    tooltip: 'promotion',
                    icon: Icon(Icons.discount),
                    color: color.backgroundColor,
                    onPressed: () {
                      openPromotionDialog();
                    },
                  ),
                ),
                Visibility(
                  visible: widget.currentPage == 'menu' ? true : false,
                  child: IconButton(
                    tooltip: 'clear cart',
                    icon: const Icon(
                      Icons.delete,
                    ),
                    color: color.backgroundColor,
                    onPressed: () {
                      cart.removeAllCartItem();
                      cart.removeAllTable();
                    },
                  ),
                ),
                // PopupMenuButton<Text>(
                //     icon: Icon(Icons.more_vert, color: color.backgroundColor),
                //     itemBuilder: (context) {
                //       return [
                //         PopupMenuItem(
                //           child: Text(
                //             'test',
                //           ),
                //         ),
                //       ];
                //     })
              ],
            ),
            body: StreamBuilder(
                stream: controller.stream,
                builder: (context, snapshot) {
                  return Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: Colors.grey.shade100, width: 3.0),
                    ),
                    child: Column(
                      children: [
                        Padding(
                          padding: EdgeInsets.fromLTRB(10, 8, 14, 0),
                          child: Column(
                              children: [
                                DropdownButton<String>(
                                  onChanged: widget.currentPage == 'menu' ? (value) {
                                    setState(() {
                                      cart.selectedOption = value!;
                                    });
                                  } : null,
                                  value: cart.selectedOption,
                                  // Hide the default underline
                                  underline: Container(),
                                  icon: Visibility(
                                    visible: widget.currentPage == 'menu' ? true : false,
                                    child: Icon(
                                      Icons.arrow_drop_down,
                                      color: color.backgroundColor,
                                    ),
                                  ),
                                  isExpanded: true,
                                  // The list of options
                                  items: diningList.map((e) => DropdownMenuItem(
                                    child: Container(
                                      alignment: Alignment.centerLeft,
                                      child: Text(e, style: TextStyle(fontSize: 18)),
                                    ),
                                    value: e,
                                  )).toList(),
                                  // Customize the selected item
                                  selectedItemBuilder: (BuildContext context) =>
                                      diningList.map((e) => Center(child: Text(e))).toList(),
                                ),
                              ]),
                        ),
                        Expanded(
                          child: Container(
                            height: 350,
                            child: ListView.builder(
                                shrinkWrap: true,
                                itemCount: cart.cartNotifierItem.length,
                                itemBuilder: (context, index) {
                                  return Dismissible(
                                    background: Container(
                                      color: Colors.red,
                                      padding: EdgeInsets.only(left: 25.0),
                                      child: Row(
                                        children: [
                                          Icon(Icons.delete,
                                              color: Colors.white),
                                        ],
                                      ),
                                    ),
                                    key: ValueKey(cart.cartNotifierItem[index].name),
                                    direction: widget.currentPage == 'menu' &&
                                               cart.cartNotifierItem[index].status == 0 ||
                                               widget.currentPage == 'table' ?
                                               DismissDirection.startToEnd : DismissDirection.none,
                                    confirmDismiss: (direction) async {
                                      if (direction == DismissDirection.startToEnd) {
                                        await openRemoveCartItemDialog(cart.cartNotifierItem[index], widget.currentPage);
                                      }
                                      return null;
                                    },
                                    child: ListTile(
                                      hoverColor: Colors.transparent,
                                      onTap: () {},
                                      isThreeLine: true,
                                      title: RichText(
                                        text: TextSpan(
                                          children: <TextSpan>[
                                            TextSpan(
                                                text: cart.cartNotifierItem[index].name +'\n',
                                                style: TextStyle(
                                                    fontSize: 14,
                                                    color: cart.cartNotifierItem[index].status == 1
                                                        ? font
                                                        : cart.cartNotifierItem[index].refColor,
                                                    fontWeight:
                                                        FontWeight.bold),
                                            ),
                                            TextSpan(
                                                text: "RM" +
                                                    cart.cartNotifierItem[index]
                                                        .price,
                                                style: TextStyle(
                                                  fontSize: 13,
                                                  color: cart.cartNotifierItem[index].status == 1 ? font : cart.cartNotifierItem[index].refColor,
                                                )),
                                          ],
                                        ),
                                      ),
                                      subtitle: Text(
                                          getVariant(cart.cartNotifierItem[index]) +
                                              getModifier(cart.cartNotifierItem[index]) +
                                              getRemark(cart.cartNotifierItem[index]),
                                          style: TextStyle(fontSize: 10)),
                                      trailing: Container(
                                        child: FittedBox(
                                          child: Row(
                                            children: [
                                              Visibility(
                                                visible: widget.currentPage == 'menu' ? true : false,
                                                child: IconButton(
                                                    hoverColor: Colors.transparent,
                                                    icon: Icon(Icons.remove),
                                                    onPressed: () {
                                                      cart.cartNotifierItem[index].quantity != 1 ?
                                                      setState(() => cart.cartNotifierItem[index].quantity--)
                                                          : null;
                                                    }),
                                              ),
                                              Text(cart.cartNotifierItem[index].quantity.toString(),
                                                style: TextStyle(color: cart.cartNotifierItem[index].refColor),
                                              ),
                                              widget.currentPage == 'menu' ?
                                              IconButton(
                                                  hoverColor: Colors.transparent,
                                                  icon: Icon(Icons.add),
                                                  onPressed: () {
                                                    if (cart.cartNotifierItem[index].status == 0) {
                                                      setState(() {
                                                        cart.cartNotifierItem[index].quantity++;
                                                      });
                                                    } else {
                                                      Fluttertoast.showToast(
                                                          backgroundColor:
                                                              Colors.red,
                                                          msg: "order already placed!");
                                                    }
                                                    controller.add('refresh');
                                                  })
                                                  :
                                                  Container()
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                }),
                          ),
                        ),
                        SizedBox(height: MediaQuery.of(context).size.height > 500  ? 20 : 5),
                        Divider(
                          color: Colors.grey,
                          height: 1,
                          thickness: 1,
                          indent: 20,
                          endIndent: 20,
                        ),
                        SizedBox(height: MediaQuery.of(context).size.height > 500 ? 10 : 5),
                        Container(
                          height: cart.selectedOption == 'Dine in' && MediaQuery.of(context).size.height > 500  ? 190 : 25,
                          child: ListView(
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
                                visible: cart.selectedPromotion != null ? true : false,
                                child: ListTile(
                                  title: SingleChildScrollView(
                                    scrollDirection: Axis.horizontal,
                                    child: Row(
                                      children: [
                                        Text('${allPromo} (${selectedPromoRate})',
                                            style: TextStyle(fontSize: 14)),
                                        IconButton(
                                          padding: EdgeInsets.only(left: 10),
                                          constraints: BoxConstraints(),
                                          icon: Icon(Icons.close),
                                          iconSize: 20.0,
                                          color: Colors.red,
                                          onPressed: () {
                                            cart.removePromotion();
                                            selectedPromo = 0.0;
                                            hasSelectedPromo = false;
                                          },
                                        ),
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
                                      shrinkWrap: true,
                                      physics: NeverScrollableScrollPhysics(),
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
                              Visibility(
                                visible: widget.currentPage == 'bill' ? true : false,
                                child: ListView.builder(
                                    shrinkWrap: true,
                                    physics: NeverScrollableScrollPhysics(),
                                    itemCount: orderPromotionList.length,
                                    itemBuilder: (context, index) {
                                      return ListTile(
                                          title: Text(
                                              '${orderPromotionList[index].promotion_name} (${orderPromotionList[index].rate})',
                                              style: TextStyle(fontSize: 14)),
                                          visualDensity:
                                          VisualDensity(vertical: -4),
                                          dense: true,
                                          trailing: Text(
                                              '-${orderPromotionList[index].promotion_amount}',
                                              style: TextStyle(fontSize: 14)));
                                    }),
                              ),
                              Visibility(
                                visible: widget.currentPage == 'menu' ||
                                         widget.currentPage == 'table' ||
                                         widget.currentPage == 'qr_order' ||
                                         widget.currentPage == 'other_order' ?
                                         true : false,
                                child: ListView.builder(
                                    shrinkWrap: true,
                                    physics: NeverScrollableScrollPhysics(),
                                    itemCount: taxRateList.length,
                                    itemBuilder: (context, index){
                                      return ListTile(
                                        title: Text('${taxRateList[index].name}(${taxRateList[index].tax_rate}%)', style: TextStyle(fontSize: 14)),
                                        trailing: Text('${taxRateList[index].tax_amount?.toStringAsFixed(2)}', style: TextStyle(fontSize: 14)), //Text(''),
                                        visualDensity: VisualDensity(vertical: -4),
                                        dense: true,
                                      );
                                    }
                                ),
                              ),
                              Visibility(
                                visible: widget.currentPage == 'bill' ? true : false,
                                child: ListView.builder(
                                    shrinkWrap: true,
                                    physics: NeverScrollableScrollPhysics(),
                                    itemCount: orderTaxList.length,
                                    itemBuilder: (context, index){
                                      return ListTile(
                                        title: Text('${orderTaxList[index].tax_name}(${orderTaxList[index].rate}%)', style: TextStyle(fontSize: 14)),
                                        trailing: Text('${orderTaxList[index].tax_amount}', style: TextStyle(fontSize: 14)), //Text(''),
                                        visualDensity: VisualDensity(vertical: -4),
                                        dense: true,
                                      );
                                    }
                                ),
                              ),
                              ListTile(
                                title: Text("Amount",
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
                                title: Text("Final Amount",
                                    style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold)),
                                trailing: Text("${finalAmount}", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                dense: true,
                              ),
                              Visibility(
                                visible: widget.currentPage == 'bill' ? true : false,
                                  child: Column(
                                    children: [
                                      Container(
                                        child: ListTile(
                                          visualDensity: VisualDensity(vertical: -4),
                                          title: Text("Payment received", style: TextStyle(fontSize: 14)),
                                          trailing: Text("${paymentReceived.toStringAsFixed(2)}", style: TextStyle(fontSize: 14)),
                                          dense: true,
                                        ),
                                      ),
                                      Container(
                                        child: ListTile(
                                          visualDensity: VisualDensity(vertical: -4),
                                          title: Text("Change",
                                              style: TextStyle(fontSize: 14)),
                                          trailing: Text("${paymentChange.toStringAsFixed(2)}", style: TextStyle(fontSize: 14)),
                                          dense: true,
                                        ),
                                      )
                                    ],
                                  )
                              )
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
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              primary: color.backgroundColor,
                              minimumSize: const Size.fromHeight(50), // NEW
                            ),
                            onPressed: () async {
                              await checkCashRecord();
                              if(_isSettlement == true){
                                showDialog(
                                    barrierDismissible: false, context: context, builder: (BuildContext context) {
                                  return WillPopScope(
                                      child: CashDialog(isCashIn: true, callBack: (){}, isCashOut: false, isNewDay: true),
                                      onWillPop: () async => false);
                                });
                                _isSettlement = false;
                              } else {
                                if (widget.currentPage == 'menu' || widget.currentPage == 'qr_order') {
                                  if (cart.selectedOption == 'Dine in') {
                                    if (cart.selectedTable.isNotEmpty &&
                                        cart.cartNotifierItem.isNotEmpty) {
                                      if (cart.cartNotifierItem[0].status == 1) {
                                        print('add new item');
                                        await callAddOrderCache(cart);
                                        cart.removeAllCartItem();
                                        cart.removeAllTable();
                                      } else {
                                        print('add order cache');
                                        // if (printerList.length >= 0) {
                                          await callCreateNewOrder(cart);
                                          //await _printKitchenList(cart);
                                          cart.removeAllCartItem();
                                          cart.removeAllTable();
                                        // } else {
                                        //   Fluttertoast.showToast(
                                        //       backgroundColor: Colors.red,
                                        //       msg: "Printer not found");
                                        // }
                                      }
                                    } else {
                                      Fluttertoast.showToast(
                                          backgroundColor: Colors.red,
                                          msg: "make sure cart is not empty and table is selected");
                                    }
                                  } else {
                                    // not dine in call
                                    cart.removeAllTable();
                                    if (cart.cartNotifierItem.isNotEmpty) {
                                      await callCreateNewNotDineOrder(cart);
                                      //await createOrderCache(cart);
                                      // await updatePosTable(cart);
                                      cart.removeAllCartItem();
                                      cart.selectedTable.clear();
                                    } else {
                                      Fluttertoast.showToast(
                                          backgroundColor: Colors.red,
                                          msg: "${AppLocalizations.of(context)?.translate('empty_cart')}");
                                    }
                                  }
                                } else if(widget.currentPage == 'table') {
                                  if(cart.selectedTable.isNotEmpty){
                                    if(cart.selectedTable.length > 1){
                                      if (await confirm(
                                        context,
                                        title: Text(
                                            '${AppLocalizations.of(context)?.translate('confirm_merge_bill')}'),
                                        content: Text(
                                            '${AppLocalizations.of(context)?.translate('to_merge_bill')}'),
                                        textOK: Text(
                                            '${AppLocalizations.of(context)?.translate('yes')}'),
                                        textCancel: Text(
                                            '${AppLocalizations.of(context)?.translate('no')}'),
                                      )) {
                                        return openPaymentSelect();
                                      }
                                    } else {
                                      openPaymentSelect();
                                    }
                                  } else {
                                    Fluttertoast.showToast(
                                        backgroundColor: Colors.red,
                                        msg: "${AppLocalizations.of(context)?.translate('empty_cart')}");
                                  }
                                } else if(widget.currentPage == 'other_order'){
                                  if(cart.cartNotifierItem.isNotEmpty){
                                    openPaymentSelect();
                                  } else {
                                    Fluttertoast.showToast(
                                        backgroundColor: Colors.red,
                                        msg: "${AppLocalizations.of(context)?.translate('empty_cart')}");
                                  }
                                } else {
                                  if(cart.cartNotifierItem.isNotEmpty){
                                    _printReceiptList();
                                  } else {
                                    Fluttertoast.showToast(
                                        backgroundColor: Colors.red,
                                        msg: "${AppLocalizations.of(context)?.translate('empty_cart')}");
                                  }
                                }
                              }
                            },
                            child: widget.currentPage == 'menu' || widget.currentPage == 'qr_order'
                                ? Text('Place Order')
                                : widget.currentPage == 'table' || widget.currentPage == 'other_order' ? Text('Make payment')
                                : Text('Print Receipt'),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
          );
        }),
      );
    });
  }

  _printReceiptList() async {
    try {
      for (int i = 0; i < printerList.length; i++) {
        List<PrinterLinkCategory> data = await PosDatabase.instance
            .readPrinterLinkCategory(printerList[i].printer_sqlite_id!);
        for(int j = 0; j < data.length; j++){
          if (data[j].category_sqlite_id == '3') {
            if(printerList[i].type == 0){
              var printerDetail = jsonDecode(printerList[i].value!);
              var data = Uint8List.fromList(await ReceiptLayout().printReceipt80mm(true, this.localOrderId));
              bool? isConnected = await flutterUsbPrinter.connect(
                  int.parse(printerDetail['vendorId']),
                  int.parse(printerDetail['productId']));
              if (isConnected == true) {
                await flutterUsbPrinter.write(data);
              } else {
                print('not connected');
              }
            } else {
              print("print lan");
            }
          }
        }

      }
    } catch (e) {
      print('Printer Connection Error cart: ${e}');
      //response = 'Failed to get platform version.';
    }
  }

  _printCheckList() async {
    print('check List called!');
    try {
      for (int i = 0; i < printerList.length; i++) {
        List<PrinterLinkCategory> data = await PosDatabase.instance
            .readPrinterLinkCategory(printerList[i].printer_sqlite_id!);
        print('printer link category length: ${data.length}');
        for(int j = 0; j < data.length; j++){
          if (data[j].category_sqlite_id == '3') {
            if(printerList[i].type == 0){
              var printerDetail = jsonDecode(printerList[i].value!);
              var data = Uint8List.fromList(await ReceiptLayout()
                  .printCheckList80mm(true, null));
              bool? isConnected = await flutterUsbPrinter.connect(
                  int.parse(printerDetail['vendorId']),
                  int.parse(printerDetail['productId']));
              if (isConnected == true) {
                await flutterUsbPrinter.write(data);
              } else {
                print('not connected');
              }
            } else {
              print("print lan");
            }
          }
        }

      }
    } catch (e) {
      print('Printer Connection Error: ${e}');
      //response = 'Failed to get platform version.';
    }
  }

  _printKitchenList(CartModel cart) async {
    for (int i = 0; i < printerList.length; i++) {
      List<PrinterLinkCategory> data = await PosDatabase.instance.readPrinterLinkCategory(printerList[i].printer_sqlite_id!);
      for(int j = 0; j < data.length; j++){
        for(int k = 0; k < cart.cartNotifierItem.length; k++){
          //check printer category
          if (cart.cartNotifierItem[k].category_id == data[j].category_sqlite_id) {
            //check printer type
            if(printerList[i].type == 1){
              var printerDetail = jsonDecode(printerList[i].value!);
              //check paper size
              if(printerList[i].paper_size == 0){
                //print LAN
                final profile = await CapabilityProfile.load();
                final printer = NetworkPrinter(PaperSize.mm80, profile);
                final PosPrintResult res = await printer.connect(printerDetail, port: 9100);

                if (res == PosPrintResult.success) {
                  await ReceiptLayout().printKitchenList80mm(false, cart.cartNotifierItem[k], value: printer);
                  printer.disconnect();
                } else {
                  print('not connected');
                }
              } else {
                print('print 58mm');
              }
            } else {
              if(printerList[i].paper_size == 0) {
                var printerDetail = jsonDecode(printerList[i].value!);
                var data = Uint8List.fromList(await ReceiptLayout()
                    .printKitchenList80mm(true, cart.cartNotifierItem[k]));
                bool? isConnected = await flutterUsbPrinter.connect(
                    int.parse(printerDetail['vendorId']),
                    int.parse(printerDetail['productId']));
                if (isConnected == true) {
                  await flutterUsbPrinter.write(data);
                } else {
                  print('not connected');
                }
              } else {
                print('print 58mm');
              }
            }
          }
        }
      }
    }
  }

  readAllPrinters() async {
    final prefs = await SharedPreferences.getInstance();
    final int? branch_id = prefs.getInt('branch_id');

    List<Printer> data =
        await PosDatabase.instance.readAllBranchPrinter(branch_id!);
    printerList = List.from(data);
  }

/*
  -----------------------Cart-item-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
*/

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

  getVariant2(cartProductItem object) {
    List<String?> variant = [];
    String result = '';
    for (int i = 0; i < object.variant.length; i++) {
      VariantGroup group = object.variant[i];
      for (int j = 0; j < group.child.length; j++) {
        if (group.child[j].isSelected!) {
          variant.add(group.child[j].name!);
          result = variant.toString().replaceAll('[', '').replaceAll(']', '');
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
  Get Selected table
*/
  getSelectedTable(CartModel cart) {
    List<String> result = [];
    if (cart.selectedTable.isEmpty && cart.selectedOption == 'Dine in') {
      result.add('-');
    } else if (cart.selectedOption != 'Dine in') {
      result.add('N/A');
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
  -----------------Calculation-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
*/
  calPromotion(CartModel cart) {
    promoAmount = 0.0;
    getAutoApplyPromotion(cart);
    getManualApplyPromotion(cart);
    controller.add('refresh');
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
    controller.add('refresh');
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
    controller.add('refresh');
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
    controller.add('refresh');
  }

  getAutoApplyPromotion(CartModel cart) {
    try {
      cart.removeAutoPromotion();
      autoApplyPromotionList = [];
      promoName = '';
      hasPromo = false;
      //loop promotion list get promotion
      for (int j = 0; j < promotionList.length; j++) {
        promotionList[j].promoAmount = 0.0;
        if (promotionList[j].auto_apply == '1') {
          if (promotionList[j].specific_category == '1') {
            //Auto apply specific category promotion
            for (int m = 0; m < cart.cartNotifierItem.length; m++) {
              if (cart.cartNotifierItem[m].category_id ==
                  promotionList[j].category_id) {
                hasPromo = true;
                promoName = promotionList[j].name!;
                if (!autoApplyPromotionList.contains(promotionList[j])) {
                  autoApplyPromotionList.add(promotionList[j]);
                  if(widget.currentPage !='menu'){
                    cart.addAutoApplyPromo(promotionList[j]);
                  }
                }
                autoApplySpecificCategoryAmount(
                    promotionList[j], cart.cartNotifierItem[m]);
              }
            }
          } else {
            //Auto apply non specific category promotion
            if (cart.cartNotifierItem.isNotEmpty) {
              hasPromo = true;
              autoApplyPromotionList.add(promotionList[j]);
              if(widget.currentPage !='menu'){
                cart.addAutoApplyPromo(promotionList[j]);
              }
              promoName = promotionList[j].name!;
              autoApplyNonSpecificCategoryAmount(promotionList[j], cart);
            }
          }
        }
      }
    } catch (error) {
      print('Promotion error $error');
      promo = 0.0;
    }
    controller.add('refresh');
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
      }
      promoAmount += promo;
    } catch (e) {
      print("calc auto apply non specific error: $e");
      promoRate = '';
      promo = 0.0;
    }

    controller.add('refresh');
  }

  autoApplySpecificCategoryAmount(Promotion promotion, cartProductItem cartItem) {
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
      promoAmount += promo;
    } catch (e) {
      print("calc auto apply specific category error: $e");
      promoRate = '';
      promo = 0.0;
    }
    controller.add('refresh');
  }

  getDiningTax(CartModel cart) async {
    final prefs = await SharedPreferences.getInstance();
    final int? branch_id = prefs.getInt('branch_id');
    taxRateList = [];
    try {
      //get dining option data
      List<DiningOption> data = await PosDatabase.instance.checkSelectedOption(cart.selectedOption);
      diningOptionID = data[0].dining_id!;
      //get dining tax
      List<Tax> taxData = await PosDatabase.instance.readTax(branch_id.toString(), diningOptionID.toString());
      if (taxData.length > 0) {
        taxRateList = List.from(taxData);
      } else {
        taxRateList = [];
      }
    } catch (error) {
      print('get dining tax error: $error');
    }

    controller.add('refresh');
  }

/*
  receipt menu initial call
*/
  getReceiptPaymentDetail(CartModel cart){
    this.total = 0.0;
    this.totalAmount = 0.0;
    this.rounding = 0.0;
    this.finalAmount = '0.00';
    this.paymentReceived = 0.0;
    this.paymentChange = 0.0;
    this.orderTaxList = [];
    this.orderPromotionList = [];
    this.localOrderId = '';

    for(int i = 0; i < cart.cartNotifierPayment.length; i++){
      this.total = cart.cartNotifierPayment[i].subtotal;
      this.totalAmount = cart.cartNotifierPayment[i].amount;
      this.rounding = cart.cartNotifierPayment[i].rounding;
      this.finalAmount = cart.cartNotifierPayment[i].finalAmount;
      this.paymentReceived = cart.cartNotifierPayment[i].paymentReceived;
      this.paymentChange = cart.cartNotifierPayment[i].paymentChange;
      this.orderTaxList = cart.cartNotifierPayment[i].orderTaxList;
      this.orderPromotionList = cart.cartNotifierPayment[i].orderPromotionDetail;
      this.localOrderId = cart.cartNotifierPayment[i].localOrderId;

    }
    controller.add('refresh');
  }

/*
  Cart Ordering initial called
*/
  getSubTotal(CartModel cart) async {
    try {
      widget.currentPage == 'table' || widget.currentPage == 'qr_order' ? cart.selectedOption = 'Dine in' : null;
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
    controller.add('refresh');
  }

  getTaxAmount() {
    try{
      discountPrice = total - promoAmount;
      if(taxRateList.length > 0){
        for(int i = 0; i < taxRateList.length; i++){
          priceIncTaxes = discountPrice * (double.parse(taxRateList[i].tax_rate!)/100);
          taxRateList[i].tax_amount = priceIncTaxes;
        }
      }
    }catch(e){
      print('get tax amount error: $e');
    }

    controller.add('refresh');
  }

  getAllTaxAmount(){
    double total = 0.0;
    for(int i = 0; i < taxRateList.length; i++){
      total = total + taxRateList[i].tax_amount!;
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

    controller.add('refresh');
  }

  getAllTotal() {
    getAllTaxAmount();
    try {
      totalAmount = 0.0;
      discountPrice = total - promoAmount;
      totalAmount = discountPrice + priceIncAllTaxes;

      if(rounding == 0.0){
        finalAmount = totalAmount.toStringAsFixed(2);
      } else {
        finalAmount = totalAmount.toStringAsFixed(1) + '0';
      }
      //totalAmount = (totalAmount * 100).truncate() / 100;
    } catch (error) {
      print('Total calc error: $error');
    }

    controller.add('refresh');
  }

/*
  ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
*/

  Future<Future<Object?>> openChooseTableDialog(CartModel cartModel) async {
    return showGeneralDialog(
        barrierColor: Colors.black.withOpacity(0.5),
        transitionBuilder: (context, a1, a2, widget) {
          final curvedValue = Curves.easeInOutBack.transform(a1.value) - 1.0;
          return Transform(
            transform: Matrix4.translationValues(0.0, curvedValue * 200, 0.0),
            child: Opacity(
              opacity: a1.value,
              child: CartDialog(selectedTableList: cartModel.selectedTable),
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

  Future<Future<Object?>> openPromotionDialog() async {
    return showGeneralDialog(
        barrierColor: Colors.black.withOpacity(0.5),
        transitionBuilder: (context, a1, a2, widget) {
          final curvedValue = Curves.easeInOutBack.transform(a1.value) - 1.0;
          return Transform(
            transform: Matrix4.translationValues(0.0, curvedValue * 200, 0.0),
            child: Opacity(
              opacity: a1.value,
              child: PromotionDialog(),
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

  Future<Future<Object?>> openRemoveCartItemDialog(cartProductItem item, String currentPage) async {
    return showGeneralDialog(
        barrierColor: Colors.black.withOpacity(0.5),
        transitionBuilder: (context, a1, a2, widget) {
          final curvedValue = Curves.easeInOutBack.transform(a1.value) - 1.0;
          return Transform(
            transform: Matrix4.translationValues(0.0, curvedValue * 200, 0.0),
            child: Opacity(
              opacity: a1.value,
              child: CartRemoveDialog(cartItem: item, currentPage: currentPage,),
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

  openPaymentSelect() async {
    return showGeneralDialog(
        barrierColor: Colors.black.withOpacity(0.5),
        transitionBuilder: (context, a1, a2, widget) {
          final curvedValue = Curves.easeInOutBack.transform(a1.value) - 1.0;
          return Transform(
            transform: Matrix4.translationValues(0.0, curvedValue * 200, 0.0),
            child: Opacity(
              opacity: a1.value,
              child: PaymentSelect(dining_id: diningOptionID.toString()),
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


  checkCashRecord() async {
    final prefs = await SharedPreferences.getInstance();
    final int? branch_id = prefs.getInt('branch_id');
    List<CashRecord> data = await PosDatabase.instance.readBranchCashRecord(branch_id.toString());
    if(data.length <= 0){
      _isSettlement = true;
    } else {
      _isSettlement = false;
    }
  }

  readAllBranchLinkDiningOption() async {
    final prefs = await SharedPreferences.getInstance();
    final int? branch_id = prefs.getInt('branch_id');
    List<BranchLinkDining> data = await PosDatabase.instance
        .readBranchLinkDiningOption(branch_id!.toString());
    for (int i = 0; i < data.length; i++) {
      diningList.add(data[i].name!);
      branchLinkDiningIdList.add(data[i].dining_id!);
    }

    controller.add('refresh');
  }

  void getPromotionData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final int? branch_id = prefs.getInt('branch_id');
      List<BranchLinkPromotion> data = await PosDatabase.instance
          .readBranchLinkPromotion(branch_id.toString());

      for (int i = 0; i < data.length; i++) {
        List<Promotion> temp = await PosDatabase.instance.checkPromotion(data[i].promotion_id!);
        if (temp.length > 0) promotionList.add(temp[0]);
      }
    } catch (error) {
      print('promotion list error $error');
    }
  }

/*
  taylor part
*/
  // updatePosTable(CartModel cart) async {
  //   print('updated');
  //   DateFormat dateFormat = DateFormat("yyyy-MM-dd HH:mm:ss");
  //   String dateTime = dateFormat.format(DateTime.now());
  //   final prefs = await SharedPreferences.getInstance();
  //   final int? branch_id = prefs.getInt('branch_id');
  //
  //   for (int i = 0; i < cart.selectedTable.length; i++) {
  //     List<PosTable> result = await PosDatabase.instance
  //         .checkPosTableStatus(branch_id!, cart.selectedTable[i].table_id!);
  //     if (result[0].status == 0) {
  //       Map responseEditTableStatus = await Domain()
  //           .editTableStatus('1', cart.selectedTable[i].table_id.toString());
  //       if (responseEditTableStatus['status'] == '1') {
  //         PosTable posTableData = PosTable(
  //             table_id: cart.selectedTable[i].table_id,
  //             status: 1,
  //             updated_at: dateTime);
  //         int data =
  //             await PosDatabase.instance.updatePosTableStatus(posTableData);
  //       }
  //     }
  //   }
  // }

/*
  Taylor part
*/
  // createOrderCache(CartModel cart) async {
  //   print('create order cache called');
  //   DateFormat dateFormat = DateFormat("yyyy-MM-dd HH:mm:ss");
  //   String dateTime = dateFormat.format(DateTime.now());
  //   final prefs = await SharedPreferences.getInstance();
  //   final int? branch_id = prefs.getInt('branch_id');
  //   final String? user = prefs.getString('user');
  //   Map userObject = json.decode(user!);
  //   if (cart.selectedTable.length == 0) {
  //     Map responseInsertOrderCache = await Domain().insertOrderCache(
  //         userObject['company_id'].toString(),
  //         branch_id.toString(),
  //         '',
  //         diningOptionID.toString(),
  //         userObject['name'].toString(),
  //         totalAmount.toStringAsFixed(2));
  //     if (responseInsertOrderCache['status'] == '1') {
  //       OrderCache data = await PosDatabase.instance.insertSqLiteOrderCache(
  //           OrderCache(
  //               order_cache_id: responseInsertOrderCache['order'],
  //               company_id: userObject['company_id'],
  //               branch_id: branch_id.toString(),
  //               order_detail_id: '',
  //               table_id: '',
  //               dining_id: diningOptionID.toString(),
  //               order_id: '',
  //               order_by: userObject['name'].toString(),
  //               total_amount: totalAmount.toStringAsFixed(2),
  //               customer_id: '',
  //               created_at: dateTime,
  //               updated_at: '',
  //               soft_delete: ''));
  //
  //       for (int j = 0; j < cart.cartNotifierItem.length; j++) {
  //         Map responseInsertOrderDetail = await Domain().insertOrderDetail(
  //             responseInsertOrderCache['order'].toString(),
  //             cart.cartNotifierItem[j].branchProduct_id.toString(),
  //             cart.cartNotifierItem[j].name.toString(),
  //             cart.cartNotifierItem[j].variant.length == 0 ? '0' : '1',
  //             cart.cartNotifierItem[j].name.toString(),
  //             cart.cartNotifierItem[j].price.toString(),
  //             cart.cartNotifierItem[j].quantity.toString(),
  //             cart.cartNotifierItem[j].remark.toString(),
  //             '');
  //         if (responseInsertOrderDetail['status'] == '1') {
  //           OrderDetail detailData = await PosDatabase.instance
  //               .insertOrderDetail(OrderDetail(
  //                   order_detail_id: responseInsertOrderDetail['order'],
  //                   order_cache_id:
  //                       responseInsertOrderCache['order'].toString(),
  //                   branch_link_product_id:
  //                       cart.cartNotifierItem[j].branchProduct_id,
  //                   productName: cart.cartNotifierItem[j].name,
  //                   has_variant: cart.cartNotifierItem[j].variant.length == 0
  //                       ? '0'
  //                       : '1',
  //                   product_variant_name: cart.cartNotifierItem[j].name,
  //                   price: cart.cartNotifierItem[j].price,
  //                   quantity: cart.cartNotifierItem[j].quantity.toString(),
  //                   remark: cart.cartNotifierItem[j].remark,
  //                   account: '',
  //                   created_at: dateTime,
  //                   updated_at: '',
  //                   soft_delete: ''));
  //
  //           for (int k = 0; k < cart.cartNotifierItem[j].modifier.length; k++) {
  //             ModifierGroup group = cart.cartNotifierItem[j].modifier[k];
  //             for (int m = 0; m < group.modifierChild.length; m++) {
  //               if (group.modifierChild[m].isChecked!) {
  //                 Map responseInsertOrderModifierDetail = await Domain()
  //                     .insertOrderModifierDetail(
  //                         responseInsertOrderDetail['order'].toString(),
  //                         group.modifierChild[m].mod_item_id.toString(),
  //                         group.mod_group_id.toString());
  //                 if (responseInsertOrderModifierDetail['status'] == '1') {
  //                   OrderModifierDetail modifierData = await PosDatabase
  //                       .instance
  //                       .insertSqliteOrderModifierDetail(OrderModifierDetail(
  //                           order_modifier_detail_id:
  //                               responseInsertOrderModifierDetail['order'],
  //                           order_detail_id:
  //                               responseInsertOrderDetail['order'].toString(),
  //                           mod_item_id:
  //                               group.modifierChild[m].mod_item_id.toString(),
  //                           mod_group_id: group.mod_group_id.toString(),
  //                           created_at: dateTime,
  //                           updated_at: '',
  //                           soft_delete: ''));
  //                 }
  //               }
  //             }
  //           }
  //         }
  //       }
  //     }
  //   } else {
  //     for (int i = 0; i < cart.selectedTable.length; i++) {
  //       print(cart.selectedTable[i].table_id.toString());
  //       Map responseInsertOrderCache = await Domain().insertOrderCache(
  //           userObject['company_id'].toString(),
  //           branch_id.toString(),
  //           cart.selectedTable[i].table_id.toString(),
  //           diningOptionID.toString(),
  //           userObject['name'].toString(),
  //           totalAmount.toStringAsFixed(2));
  //       if (responseInsertOrderCache['status'] == '1') {
  //         OrderCache data = await PosDatabase.instance.insertSqLiteOrderCache(
  //             OrderCache(
  //                 order_cache_id: responseInsertOrderCache['order'],
  //                 company_id: userObject['company_id'],
  //                 branch_id: branch_id.toString(),
  //                 order_detail_id: '',
  //                 table_id: cart.selectedTable[i].table_id.toString(),
  //                 dining_id: diningOptionID.toString(),
  //                 order_id: '',
  //                 order_by: userObject['name'].toString(),
  //                 total_amount: totalAmount.toStringAsFixed(2),
  //                 customer_id: '',
  //                 created_at: dateTime,
  //                 updated_at: '',
  //                 soft_delete: ''));
  //
  //         for (int j = 0; j < cart.cartNotifierItem.length; j++) {
  //           Map responseInsertOrderDetail = await Domain().insertOrderDetail(
  //               responseInsertOrderCache['order'].toString(),
  //               cart.cartNotifierItem[j].branchProduct_id.toString(),
  //               cart.cartNotifierItem[j].name.toString(),
  //               cart.cartNotifierItem[j].variant.length == 0 ? '0' : '1',
  //               cart.cartNotifierItem[j].name.toString(),
  //               cart.cartNotifierItem[j].price.toString(),
  //               cart.cartNotifierItem[j].quantity.toString(),
  //               cart.cartNotifierItem[j].remark.toString(),
  //               '');
  //           if (responseInsertOrderDetail['status'] == '1') {
  //             OrderDetail detailData = await PosDatabase.instance
  //                 .insertOrderDetail(OrderDetail(
  //                     order_detail_id: responseInsertOrderDetail['order'],
  //                     order_cache_id:
  //                         responseInsertOrderCache['order'].toString(),
  //                     branch_link_product_id:
  //                         cart.cartNotifierItem[j].branchProduct_id,
  //                     productName: cart.cartNotifierItem[j].name,
  //                     has_variant: cart.cartNotifierItem[j].variant.length == 0
  //                         ? '0'
  //                         : '1',
  //                     product_variant_name: cart.cartNotifierItem[j].name,
  //                     price: cart.cartNotifierItem[j].price,
  //                     quantity: cart.cartNotifierItem[j].quantity.toString(),
  //                     remark: cart.cartNotifierItem[j].remark,
  //                     account: '',
  //                     created_at: dateTime,
  //                     updated_at: '',
  //                     soft_delete: ''));
  //
  //             for (int k = 0;
  //                 k < cart.cartNotifierItem[j].modifier.length;
  //                 k++) {
  //               ModifierGroup group = cart.cartNotifierItem[j].modifier[k];
  //               for (int m = 0; m < group.modifierChild.length; m++) {
  //                 if (group.modifierChild[m].isChecked!) {
  //                   Map responseInsertOrderModifierDetail = await Domain()
  //                       .insertOrderModifierDetail(
  //                           responseInsertOrderDetail['order'].toString(),
  //                           group.modifierChild[m].mod_item_id.toString(),
  //                           group.mod_group_id.toString());
  //                   if (responseInsertOrderModifierDetail['status'] == '1') {
  //                     OrderModifierDetail modifierData = await PosDatabase
  //                         .instance
  //                         .insertSqliteOrderModifierDetail(OrderModifierDetail(
  //                             order_modifier_detail_id:
  //                                 responseInsertOrderModifierDetail['order'],
  //                             order_detail_id:
  //                                 responseInsertOrderDetail['order'].toString(),
  //                             mod_item_id:
  //                                 group.modifierChild[m].mod_item_id.toString(),
  //                             mod_group_id: group.mod_group_id.toString(),
  //                             created_at: dateTime,
  //                             updated_at: '',
  //                             soft_delete: ''));
  //                   }
  //                 }
  //               }
  //             }
  //           }
  //         }
  //       }
  //     }
  //   }
  // }

/*
 leow part
*/

/*
  Not dine in call
*/
  callCreateNewNotDineOrder(CartModel cart) async {
    await createOrderCache(cart);
    await createOrderDetail(cart);
    //await _printCheckList();
  }
/*
  dine in call
*/
  callCreateNewOrder(CartModel cart) async {
    await createTableUseID();
    await createTableUseDetail(cart);
    await createOrderCache(cart);
    await createOrderDetail(cart);
    await updatePosTable(cart);
    //await _printCheckList();
  }

  callAddOrderCache(CartModel cart) async {
    print('add product cache');
    await createOrderCache(cart);
    await createOrderDetail(cart);
  }

  /**
   * concurrent here  (done)
   */
  // updatePosTable(CartModel cart) async {
  //   print('update table');
  //   DateFormat dateFormat = DateFormat("yyyy-MM-dd HH:mm:ss");
  //   String dateTime = dateFormat.format(DateTime.now());
  //   final prefs = await SharedPreferences.getInstance();
  //   final int? branch_id = prefs.getInt('branch_id');
  //
  //   for (int i = 0; i < cart.selectedTable.length; i++) {
  //     List<PosTable> result = await PosDatabase.instance
  //         .checkPosTableStatus(branch_id!, cart.selectedTable[i].table_id!);
  //     if (result[0].status == 0) {
  //       Map responseEditTableStatus = await Domain()
  //           .editTableStatus('1', cart.selectedTable[i].table_id.toString());
  //       if (responseEditTableStatus['status'] == '1') {
  //         PosTable posTableData = PosTable(
  //             table_id: cart.selectedTable[i].table_id,
  //             status: 1,
  //             updated_at: dateTime);
  //         int data =
  //             await PosDatabase.instance.updatePosTableStatus(posTableData);
  //       }
  //     }
  //   }
  // }
  updatePosTable(CartModel cart) async {
    try {
      DateFormat dateFormat = DateFormat("yyyy-MM-dd HH:mm:ss");
      String dateTime = dateFormat.format(DateTime.now());
      final prefs = await SharedPreferences.getInstance();
      final int? branch_id = prefs.getInt('branch_id');

      for (int i = 0; i < cart.selectedTable.length; i++) {
        List<PosTable> result = await PosDatabase.instance.checkPosTableStatus(
            branch_id!, cart.selectedTable[i].table_sqlite_id!);
        if (result[0].status == 0) {
          PosTable posTableData = PosTable(
              table_sqlite_id: cart.selectedTable[i].table_sqlite_id,
              status: 1,
              updated_at: dateTime);
          int data =
              await PosDatabase.instance.updatePosTableStatus(posTableData);
        }
      }
    } catch (e) {
      Fluttertoast.showToast(
          backgroundColor: Color(0xFFFF0000), msg: "update table error: ${e}");
      print("$e");
    }
  }

  randomColor() {
    return Color(Random().nextInt(0xffffffff)).withAlpha(0xff);
  }

  colorToHex(Color color) {
    String hex = '#' + color.value.toRadixString(16).substring(2);
    return hex;
  }

  hexToInteger(String hexCode) {
    int temp = int.parse(hexCode, radix: 16);
    return temp;
  }

  colorChecking() async {
    String? hexCode;
    bool colorFound = false;
    bool found = false;
    int tempColor = 0;
    int matchColor = 0;
    int diff = 0;
    int count = 0;
    final prefs = await SharedPreferences.getInstance();
    final int? branch_id = prefs.getInt('branch_id');
    List<TableUse> data =
        await PosDatabase.instance.readAllTableUseId(branch_id!);

    while (colorFound == false) {
      /* change color */
      hexCode = colorToHex(randomColor());
      if (data.length > 0) {
        for (int i = 0; i < data.length; i++) {
          if (hexCode == data[i].cardColor) {
            found = false;
            break;
          } else {
            tempColor = hexToInteger(hexCode!.replaceAll('#', ''));
            matchColor = hexToInteger(data[i].cardColor!.replaceAll('#', ''));
            diff = tempColor - matchColor;
            if (diff.abs() < 150000) {
              print('color too close or not yet loop finish');
              print('diff: ${diff.abs()}');
              found = false;
              break;
            } else {
              print('color is ok');
              print('diff: ${diff}');
              if (i < data.length) {
                continue;
              }
            }
          }
        }
        found = true;
      } else {
        found = true;
        break;
      }

      if (found == true) colorFound = true;
      // count++;
    }
    return hexCode;
  }

  randomBatch() {
    return Random().nextInt(100000) + 1;
  }

  batchChecking() async {
    print('batch checking called!');
    int tempBatch = 0;
    bool batchFound = false;
    bool founded = false;
    final prefs = await SharedPreferences.getInstance();
    final int? branch_id = prefs.getInt('branch_id');

    List<OrderCache> data =
        await PosDatabase.instance.readBranchOrderCache(branch_id!);
    while (batchFound == false) {
      tempBatch = randomBatch();
      if (data.length > 0) {
        for (int i = 0; i < data.length; i++) {
          if (tempBatch == int.parse(data[i].batch_id!)) {
            print('batch same!');
            founded = false;
            break;
          } else {
            if (i < data.length) {
              print('not yet loop finish');
              continue;
            }
          }
        }
        founded = true;
      } else {
        founded = true;
        break;
      }

      if (founded == true) batchFound = true;
    }
    return tempBatch;
  }

  createTableUseID() async {
    print('create table use id called');
    DateFormat dateFormat = DateFormat("yyyy-MM-dd HH:mm:ss");
    String dateTime = dateFormat.format(DateTime.now());
    final prefs = await SharedPreferences.getInstance();
    final int? branch_id = prefs.getInt('branch_id');
    String? hexCode;
    localTableUseId = '';
    try {
      hexCode = await colorChecking();
      if (hexCode != null) {
        //create table use data
        TableUse tableUseData = await PosDatabase.instance.insertSqliteTableUse(
            TableUse(
                table_use_id: 0,
                branch_id: branch_id,
                cardColor: hexCode.toString(),
                sync_status: 0,
                created_at: dateTime,
                updated_at: '',
                soft_delete: ''));
        localTableUseId = tableUseData.table_use_sqlite_id.toString();
      }
    } catch (e) {
      Fluttertoast.showToast(
          backgroundColor: Color(0xFFFF0000),
          msg: "Create table id error: ${e}");
    }
    return localTableUseId;
  }

  createTableUseDetail(CartModel cart) async {
    DateFormat dateFormat = DateFormat("yyyy-MM-dd HH:mm:ss");
    String dateTime = dateFormat.format(DateTime.now());
    try {
      for (int i = 0; i < cart.selectedTable.length; i++) {
        //create table use detail
        TableUseDetail tableUseDetailData = await PosDatabase.instance
            .insertSqliteTableUseDetail(TableUseDetail(
                table_use_detail_id: 0,
                table_use_sqlite_id: localTableUseId,
                table_sqlite_id:
                    cart.selectedTable[i].table_sqlite_id.toString(),
                original_table_sqlite_id:
                    cart.selectedTable[i].table_sqlite_id.toString(),
                sync_status: 0,
                created_at: dateTime,
                updated_at: '',
                soft_delete: ''));
      }
    } catch (e) {
      Fluttertoast.showToast(
          backgroundColor: Color(0xFFFF0000),
          msg: "Create table detail error: ${e}");
    }
  }

  createOrderCache(CartModel cart) async {
    DateFormat dateFormat = DateFormat("yyyy-MM-dd HH:mm:ss");
    String dateTime = dateFormat.format(DateTime.now());
    final prefs = await SharedPreferences.getInstance();
    final int? branch_id = prefs.getInt('branch_id');
    final String? user = prefs.getString('user');
    Map userObject = json.decode(user!);
    String _tableUseId = '';
    int batch = 0;
    try {
      batch = await batchChecking();
      //check selected table is in use or not
      for (int i = 0; i < cart.selectedTable.length; i++) {
        List<TableUseDetail> useDetail = await PosDatabase.instance
            .readSpecificTableUseDetail(cart.selectedTable[i].table_sqlite_id!);
        if (useDetail.length > 0) {
          _tableUseId = useDetail[0].table_use_sqlite_id!;
        } else {
          _tableUseId = this.localTableUseId;
        }
      }
      if (batch != 0) {
        //create order cache
        OrderCache data = await PosDatabase.instance.insertSqLiteOrderCache(
            OrderCache(
                order_cache_id: 0,
                company_id: userObject['company_id'].toString(),
                branch_id: branch_id.toString(),
                order_detail_id: '',
                table_use_sqlite_id: cart.selectedOption == 'Dine in' ? _tableUseId : '',
                batch_id: batch.toString().padLeft(5, '0'),
                dining_id: this.diningOptionID.toString(),
                order_sqlite_id: '',
                order_by: userObject['name'].toString(),
                order_by_user_id: userObject['user_id'].toString(),
                cancel_by: '',
                cancel_by_user_id: '',
                customer_id: '0',
                total_amount: cart.selectedOption == "Dine in" ? '' :  totalAmount.toStringAsFixed(2),//totalAmount.toStringAsFixed(1),
                sync_status: 0,
                created_at: dateTime,
                updated_at: '',
                soft_delete: ''));
        orderCacheId = data.order_cache_sqlite_id.toString();
      }
    } catch (e) {
      Fluttertoast.showToast(
          backgroundColor: Color(0xFFFF0000),
          msg: "Create order cache error: ${e}");
    }
  }

  /**
   * concurrent here (done)
   */
  createOrderDetail(CartModel cart) async {
    DateFormat dateFormat = DateFormat("yyyy-MM-dd HH:mm:ss");
    String dateTime = dateFormat.format(DateTime.now());
    //loop cart item & create order detail
    for (int j = 0; j < cart.cartNotifierItem.length; j++) {
      if (cart.cartNotifierItem[j].status == 0) {
        OrderDetail detailData = await PosDatabase.instance
            .insertSqliteOrderDetail(OrderDetail(
                order_detail_id: 0,
                order_cache_sqlite_id: orderCacheId,
                branch_link_product_sqlite_id:
                    cart.cartNotifierItem[j].branchProduct_id,
                category_sqlite_id: '',
                productName: cart.cartNotifierItem[j].name,
                has_variant:
                    cart.cartNotifierItem[j].variant.length == 0 ? '0' : '1',
                product_variant_name: getVariant2(cart.cartNotifierItem[j]),
                price: cart.cartNotifierItem[j].price,
                quantity: cart.cartNotifierItem[j].quantity.toString(),
                remark: cart.cartNotifierItem[j].remark,
                account: '',
                cancel_by: '',
                cancel_by_user_id: '',
                sync_status: 0,
                created_at: dateTime,
                updated_at: '',
                soft_delete: ''));

        for (int k = 0; k < cart.cartNotifierItem[j].modifier.length; k++) {
          ModifierGroup group = cart.cartNotifierItem[j].modifier[k];
          for (int m = 0; m < group.modifierChild.length; m++) {
            if (group.modifierChild[m].isChecked!) {
              // OrderModifierDetail modifierData = await PosDatabase.instance
              //     .insertSqliteOrderModifierDetail(OrderModifierDetail(
              //     order_modifier_detail_id: 0,
              //     order_detail_id:
              //     await detailData.order_detail_id.toString(),
              //     mod_item_id:
              //     group.modifierChild[m].mod_item_id.toString(),
              //     mod_group_id: group.mod_group_id.toString(),
              //     created_at: dateTime,
              //     updated_at: '',
              //     soft_delete: ''));
            }
          }
        }
      }
    }
  }
}
