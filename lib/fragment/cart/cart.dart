import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:confirm_dialog/confirm_dialog.dart';
import 'package:esc_pos_printer/esc_pos_printer.dart';
import 'package:esc_pos_utils/esc_pos_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_usb_printer/flutter_usb_printer.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';
import 'package:intl/intl.dart';
import 'package:pos_system/fragment/cart/cart_dialog.dart';
import 'package:pos_system/fragment/cart/promotion_dialog.dart';
import 'package:pos_system/fragment/cart/remove_cart_dialog.dart';
import 'package:pos_system/fragment/cart/reprint_dialog.dart';
import 'package:pos_system/notifier/cart_notifier.dart';
import 'package:pos_system/notifier/connectivity_change_notifier.dart';
import 'package:pos_system/notifier/theme_color.dart';
import 'package:pos_system/object/branch_link_dining_option.dart';
import 'package:pos_system/object/branch_link_promotion.dart';
import 'package:pos_system/object/cart_product.dart';
import 'package:pos_system/object/dining_option.dart';
import 'package:pos_system/object/modifier_group.dart';
import 'package:pos_system/object/order_cache.dart';
import 'package:pos_system/object/order_detail.dart';
import 'package:pos_system/object/order_promotion_detail.dart';
import 'package:pos_system/object/order_tax_detail.dart';
import 'package:pos_system/object/printer_link_category.dart';
import 'package:pos_system/object/promotion.dart';
import 'package:pos_system/object/table_use.dart';
import 'package:pos_system/object/table_use_detail.dart';
import 'package:pos_system/object/variant_group.dart';
import 'package:pos_system/page/loading_dialog.dart';
import 'package:pos_system/page/progress_bar.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:crypto/crypto.dart';

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

import 'package:http/http.dart' as http;

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
  List<Promotion> promotionList = [], autoApplyPromotionList = [];
  List<String> diningList = [], branchLinkDiningIdList = [];
  List<cartProductItem> sameCategoryItemList = [];
  List<TableUse> tableUseList = [];
  List<Tax> taxRateList = [];
  List<OrderTaxDetail> orderTaxList = [];
  List<OrderPromotionDetail> orderPromotionList = [];
  int diningOptionID = 0, simpleIntInput = 0;
  double total = 0.0,
      promo = 0.0,
      selectedPromo = 0.0,
      selectedPromoAmount = 0.0,
      taxAmount = 0.0,
      priceIncAllTaxes = 0.0,
      priceIncTaxes = 0.0,
      discountPrice = 0.0,
      promoAmount = 0.0,
      totalAmount = 0.0,
      tableOrderPrice = 0.0,
      rounding = 0.0,
      paymentReceived = 0.0,
      paymentChange = 0.0;
  String selectedPromoRate = '',
      promoName = '',
      promoRate = '',
      localTableUseId = '',
      orderCacheId = '',
      allPromo = '',
      finalAmount = '',
      localOrderId = '';
  String? orderCacheKey;
  String? orderDetailKey;
  String? tableUseKey;
  String? orderModifierDetailKey;
  String? tableUseDetailKey;
  bool hasPromo = false, hasSelectedPromo = false, _isSettlement = false, hasNewItem = false, timeOutDetected = false;
  Color font = Colors.black45;

  @override
  void initState() {
    controller = StreamController();
    readAllBranchLinkDiningOption();
    getPromotionData();
    readAllPrinters();
    super.initState();
  }

  @override
  void deactivate() {
    controller.sink.close();
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
                  widget.currentPage == 'qr_order' ||
                  widget.currentPage == 'other_order'
              ? getSubTotal(cart)
              : getReceiptPaymentDetail(cart);
          return Scaffold(
            resizeToAvoidBottomInset: false,
            appBar: AppBar(
              automaticallyImplyLeading: false,
              title: Row(
                children: [
                  MediaQuery.of(context).size.height > 500
                      ? Text('Bill', style: TextStyle(fontSize: 20, color: Colors.black))
                      : SizedBox.shrink(),
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
                          widget.currentPage == 'other_order'
                      ? false
                      : true,
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
                          child: Column(children: [
                            DropdownButton<String>(
                              onChanged: widget.currentPage == 'menu'
                                  ? (value) {
                                      setState(() {
                                        cart.selectedOption = value!;
                                      });
                                    }
                                  : null,
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
                              items: diningList
                                  .map((e) => DropdownMenuItem(
                                        child: Container(
                                          alignment: Alignment.centerLeft,
                                          child: Text(e, style: TextStyle(fontSize: 18)),
                                        ),
                                        value: e,
                                      ))
                                  .toList(),
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
                                          Icon(Icons.delete, color: Colors.white),
                                        ],
                                      ),
                                    ),
                                    key: ValueKey(cart.cartNotifierItem[index].name),
                                    direction: widget.currentPage == 'menu' && cart.cartNotifierItem[index].status == 0 ||
                                               widget.currentPage == 'table' ||
                                               widget.currentPage == 'other_order'
                                        ? DismissDirection.startToEnd
                                        : DismissDirection.none,
                                    confirmDismiss: (direction) async {
                                      if (direction == DismissDirection.startToEnd) {
                                        await openRemoveCartItemDialog(
                                            cart.cartNotifierItem[index], widget.currentPage);
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
                                              text: cart.cartNotifierItem[index].name + '\n',
                                              style: TextStyle(
                                                  fontSize: 14,
                                                  color: cart.cartNotifierItem[index].status == 1
                                                      ? font
                                                      : cart.cartNotifierItem[index].refColor,
                                                  fontWeight: FontWeight.bold),
                                            ),
                                            TextSpan(
                                                text: "RM" + cart.cartNotifierItem[index].price,
                                                style: TextStyle(
                                                  fontSize: 13,
                                                  color: cart.cartNotifierItem[index].status == 1
                                                      ? font
                                                      : cart.cartNotifierItem[index].refColor,
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
                                                visible:
                                                    widget.currentPage == 'menu' ? true : false,
                                                child: IconButton(
                                                    hoverColor: Colors.transparent,
                                                    icon: Icon(Icons.remove),
                                                    onPressed: () {
                                                      cart.cartNotifierItem[index].quantity != 1
                                                          ? setState(() => cart
                                                              .cartNotifierItem[index].quantity--)
                                                          : null;
                                                    }),
                                              ),
                                              Text(
                                                cart.cartNotifierItem[index].quantity.toString(),
                                                style: TextStyle(
                                                    color: cart.cartNotifierItem[index].refColor),
                                              ),
                                              widget.currentPage == 'menu'
                                                  ? IconButton(
                                                      hoverColor: Colors.transparent,
                                                      icon: Icon(Icons.add),
                                                      onPressed: () {
                                                        if (cart.cartNotifierItem[index].status ==
                                                            0) {
                                                          setState(() {
                                                            cart.cartNotifierItem[index].quantity++;
                                                          });
                                                        } else {
                                                          Fluttertoast.showToast(
                                                              backgroundColor: Colors.red,
                                                              msg: "order already placed!");
                                                        }
                                                        controller.add('refresh');
                                                      })
                                                  : Container()
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                }),
                          ),
                        ),
                        SizedBox(height: MediaQuery.of(context).size.height > 500 ? 20 : 5),
                        Divider(
                          color: Colors.grey,
                          height: 1,
                          thickness: 1,
                          indent: 20,
                          endIndent: 20,
                        ),
                        SizedBox(height: MediaQuery.of(context).size.height > 500 ? 10 : 5),
                        Container(
                          height: cart.selectedOption == 'Dine in' &&
                                  MediaQuery.of(context).size.height > 500
                              ? 190
                              : MediaQuery.of(context).size.height > 500
                                  ? null
                                  : 25,
                          child: ListView(
                            physics: ClampingScrollPhysics(),
                            children: [
                              ListTile(
                                title: Text("Subtotal", style: TextStyle(fontSize: 14)),
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
                                  trailing: Text('-${selectedPromo.toStringAsFixed(2)}',
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
                                            visualDensity: VisualDensity(vertical: -4),
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
                                          visualDensity: VisualDensity(vertical: -4),
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
                                        widget.currentPage == 'other_order'
                                    ? true
                                    : false,
                                child: ListView.builder(
                                    shrinkWrap: true,
                                    physics: NeverScrollableScrollPhysics(),
                                    itemCount: taxRateList.length,
                                    itemBuilder: (context, index) {
                                      return ListTile(
                                        title: Text(
                                            '${taxRateList[index].name}(${taxRateList[index].tax_rate}%)',
                                            style: TextStyle(fontSize: 14)),
                                        trailing: Text(
                                            '${taxRateList[index].tax_amount?.toStringAsFixed(2)}',
                                            style: TextStyle(fontSize: 14)),
                                        //Text(''),
                                        visualDensity: VisualDensity(vertical: -4),
                                        dense: true,
                                      );
                                    }),
                              ),
                              Visibility(
                                visible: widget.currentPage == 'bill' ? true : false,
                                child: ListView.builder(
                                    shrinkWrap: true,
                                    physics: NeverScrollableScrollPhysics(),
                                    itemCount: orderTaxList.length,
                                    itemBuilder: (context, index) {
                                      return ListTile(
                                        title: Text(
                                            '${orderTaxList[index].tax_name}(${orderTaxList[index].rate}%)',
                                            style: TextStyle(fontSize: 14)),
                                        trailing: Text('${orderTaxList[index].tax_amount}',
                                            style: TextStyle(fontSize: 14)),
                                        //Text(''),
                                        visualDensity: VisualDensity(vertical: -4),
                                        dense: true,
                                      );
                                    }),
                              ),
                              ListTile(
                                title: Text("Amount", style: TextStyle(fontSize: 14)),
                                trailing: Text('${totalAmount.toStringAsFixed(2)}',
                                    style: TextStyle(fontSize: 14)),
                                visualDensity: VisualDensity(vertical: -4),
                                dense: true,
                              ),
                              ListTile(
                                title: Text("Rounding", style: TextStyle(fontSize: 14)),
                                trailing: Text('${rounding.toStringAsFixed(2)}',
                                    style: TextStyle(fontSize: 14)),
                                visualDensity: VisualDensity(vertical: -4),
                                dense: true,
                              ),
                              ListTile(
                                visualDensity: VisualDensity(vertical: -4),
                                title: Text("Final Amount",
                                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                trailing: Text("${finalAmount}",
                                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                dense: true,
                              ),
                              Visibility(
                                  visible: widget.currentPage == 'bill' ? true : false,
                                  child: Column(
                                    children: [
                                      Container(
                                        child: ListTile(
                                          visualDensity: VisualDensity(vertical: -4),
                                          title: Text("Payment received",
                                              style: TextStyle(fontSize: 14)),
                                          trailing: Text("${paymentReceived.toStringAsFixed(2)}",
                                              style: TextStyle(fontSize: 14)),
                                          dense: true,
                                        ),
                                      ),
                                      Container(
                                        child: ListTile(
                                          visualDensity: VisualDensity(vertical: -4),
                                          title: Text("Change", style: TextStyle(fontSize: 14)),
                                          trailing: Text("${paymentChange.toStringAsFixed(2)}",
                                              style: TextStyle(fontSize: 14)),
                                          dense: true,
                                        ),
                                      )
                                    ],
                                  ))
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
                          child: Consumer<ConnectivityChangeNotifier>(
                              builder: (context, ConnectivityChangeNotifier connectivity, child) {
                            return Row(
                              children: [
                                Expanded(
                                    child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    primary: color.backgroundColor,
                                    minimumSize: const Size.fromHeight(50), // NEW
                                  ),
                                  onPressed: () async {
                                    await checkCashRecord();
                                    if (_isSettlement == true) {
                                      showDialog(
                                          barrierDismissible: false,
                                          context: context,
                                          builder: (BuildContext context) {
                                            return WillPopScope(
                                                child: CashDialog(
                                                    isCashIn: true,
                                                    callBack: () {},
                                                    isCashOut: false,
                                                    isNewDay: true),
                                                onWillPop: () async => false);
                                          });
                                      _isSettlement = false;
                                    } else {
                                      if (widget.currentPage == 'menu' ||
                                          widget.currentPage == 'qr_order') {
                                        if (cart.selectedOption == 'Dine in') {
                                          if (cart.selectedTable.isNotEmpty && cart.cartNotifierItem.isNotEmpty) {
                                            openLoadingDialogBox();
                                            print('has new item ${hasNewItem}');
                                            if (cart.cartNotifierItem[0].status == 1 && hasNewItem == true) {
                                              await callAddOrderCache(cart, connectivity);
                                              await _printCheckList();
                                              await _printKitchenList(cart);
                                            } else if(cart.cartNotifierItem[0].status == 0) {
                                              await callCreateNewOrder(cart, connectivity);
                                              await _printCheckList();
                                              await _printKitchenList(cart);
                                            } else {
                                              Fluttertoast.showToast(
                                                  backgroundColor: Colors.red,
                                                  msg: "Cannot replace same order");
                                            }
                                            cart.removeAllCartItem();
                                            cart.removeAllTable();
                                            Navigator.of(context).pop();
                                          } else {
                                            Fluttertoast.showToast(
                                                backgroundColor: Colors.red,
                                                msg: "make sure cart is not empty and table is selected");
                                          }
                                        } else {
                                          // not dine in call
                                          cart.removeAllTable();
                                          if (cart.cartNotifierItem.isNotEmpty) {
                                            await callCreateNewNotDineOrder(cart, connectivity);
                                            await _printCheckList();
                                            await _printKitchenList(cart);
                                            cart.removeAllCartItem();
                                            cart.selectedTable.clear();
                                          } else {
                                            Fluttertoast.showToast(
                                                backgroundColor: Colors.red,
                                                msg: "${AppLocalizations.of(context)?.translate('empty_cart')}");
                                          }
                                        }
                                      } else if (widget.currentPage == 'table') {
                                        if (cart.selectedTable.isNotEmpty) {
                                          if (cart.selectedTable.length > 1) {
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
                                              msg:
                                                  "${AppLocalizations.of(context)?.translate('empty_cart')}");
                                        }
                                      } else if (widget.currentPage == 'other_order') {
                                        if (cart.cartNotifierItem.isNotEmpty) {
                                          openPaymentSelect();
                                        } else {
                                          Fluttertoast.showToast(
                                              backgroundColor: Colors.red,
                                              msg:
                                                  "${AppLocalizations.of(context)?.translate('empty_cart')}");
                                        }
                                      } else {
                                        if (cart.cartNotifierItem.isNotEmpty) {
                                          await _printReceiptList(cart);
                                        } else {
                                          Fluttertoast.showToast(
                                              backgroundColor: Colors.red,
                                              msg:
                                                  "${AppLocalizations.of(context)?.translate('empty_cart')}");
                                        }
                                      }
                                    }
                                  },
                                  child: widget.currentPage == 'menu' ||
                                          widget.currentPage == 'qr_order'
                                      ? Text('Place Order\n (RM ${this.finalAmount})')
                                      : widget.currentPage == 'table' ||
                                              widget.currentPage == 'other_order'
                                          ? Text('Make payment (RM ${this.finalAmount})')
                                          : Text('Print Receipt'),
                                )),
                                Visibility(
                                  visible: cart.cartNotifierItem.isNotEmpty &&
                                          cart.cartNotifierItem[0].status == 1
                                      ? true
                                      : false,
                                  child: Expanded(
                                    child: Row(
                                      children: [
                                        SizedBox(
                                          width: 10,
                                        ),
                                        Expanded(
                                            child: ElevatedButton(
                                          style: ElevatedButton.styleFrom(
                                            primary: color.backgroundColor,
                                            minimumSize: const Size.fromHeight(50), // NEW
                                          ),
                                          onPressed: () {
                                            //openReprintDialog(printerList, cart);
                                            print('reprint checklist');
                                          },
                                          child: Text('Print Check List'),
                                        )),
                                      ],
                                    ),
                                  ),
                                )
                              ],
                            );
                          }),
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

  checkCartItem(CartModel cart){
    for(int i = 0; i < cart.cartNotifierItem.length; i++){
      if(cart.cartNotifierItem[i].status == 0){
        hasNewItem = true;
      } else {
        hasNewItem = false;
      }
    }
  }

  _printReceiptList(CartModel cart) async {
    try {
      for (int i = 0; i < printerList.length; i++) {
        List<PrinterLinkCategory> data =
            await PosDatabase.instance.readPrinterLinkCategory(printerList[i].printer_sqlite_id!);
        for (int j = 0; j < data.length; j++) {
          if (data[j].category_sqlite_id == '0') {
            var printerDetail = jsonDecode(printerList[i].value!);
            if (printerList[i].type == 0) {
              if (printerList[i].paper_size == 0) {
                var data = Uint8List.fromList(
                    await ReceiptLayout().printReceipt80mm(true, this.localOrderId, cart.selectedTable));
                bool? isConnected = await flutterUsbPrinter.connect(
                    int.parse(printerDetail['vendorId']), int.parse(printerDetail['productId']));
                if (isConnected == true) {
                  await flutterUsbPrinter.write(data);
                } else {
                  Fluttertoast.showToast(
                      backgroundColor: Colors.red,
                      msg: "${AppLocalizations.of(context)?.translate('usb_printer_not_connect')}");
                }
              } else {
                var data = Uint8List.fromList(
                    await ReceiptLayout().printReceipt58mm(true, this.localOrderId, cart.selectedTable));
                bool? isConnected = await flutterUsbPrinter.connect(
                    int.parse(printerDetail['vendorId']), int.parse(printerDetail['productId']));
                if (isConnected == true) {
                  await flutterUsbPrinter.write(data);
                } else {
                  Fluttertoast.showToast(
                      backgroundColor: Colors.red,
                      msg: "${AppLocalizations.of(context)?.translate('usb_printer_not_connect')}");
                }
              }
            } else {
              //print LAN 80mm
              if (printerList[i].paper_size == 0) {
                final profile = await CapabilityProfile.load();
                final printer = NetworkPrinter(PaperSize.mm80, profile);
                final PosPrintResult res = await printer.connect(printerDetail, port: 9100);
                if (res == PosPrintResult.success) {
                  await ReceiptLayout().printReceipt80mm(false, this.localOrderId, cart.selectedTable, value: printer);
                  printer.disconnect();
                } else {
                  Fluttertoast.showToast(
                      backgroundColor: Colors.red,
                      msg: "${AppLocalizations.of(context)?.translate('lan_printer_not_connect')}");
                }
              } else {
                //print LAN 58mm
                final profile = await CapabilityProfile.load();
                final printer = NetworkPrinter(PaperSize.mm58, profile);
                final PosPrintResult res = await printer.connect(printerDetail, port: 9100);
                if (res == PosPrintResult.success) {
                  await ReceiptLayout().printReceipt58mm(false, this.localOrderId, cart.selectedTable,value: printer);
                  printer.disconnect();
                } else {
                  Fluttertoast.showToast(
                      backgroundColor: Colors.red,
                      msg: "${AppLocalizations.of(context)?.translate('lan_printer_not_connect')}");
                }
              }
            }
          }
        }
      }
    } catch (e) {
      print('Printer Connection Error cart: ${e}');
      Fluttertoast.showToast(
          backgroundColor: Colors.red,
          msg: "${AppLocalizations.of(context)?.translate('printing_error')}");
    }
  }

  _printCheckList() async {
    try {
      for (int i = 0; i < printerList.length; i++) {
        List<PrinterLinkCategory> data = await PosDatabase.instance.readPrinterLinkCategory(printerList[i].printer_sqlite_id!);
        for (int j = 0; j < data.length; j++) {
          if (data[j].category_sqlite_id == '0') {
            var printerDetail = jsonDecode(printerList[i].value!);
            if (printerList[i].type == 0) {
              //print USB 80mm
              if (printerList[i].paper_size == 0) {
                var data = Uint8List.fromList(await ReceiptLayout().printCheckList80mm(true));
                bool? isConnected = await flutterUsbPrinter.connect(int.parse(printerDetail['vendorId']), int.parse(printerDetail['productId']));
                if (isConnected == true) {
                  await flutterUsbPrinter.write(data);
                } else {
                  Fluttertoast.showToast(
                      backgroundColor: Colors.red,
                      msg: "${AppLocalizations.of(context)?.translate('usb_printer_not_connect')}");
                }
              } else {
                var data = Uint8List.fromList(await ReceiptLayout().printCheckList58mm(true));
                bool? isConnected = await flutterUsbPrinter.connect(
                    int.parse(printerDetail['vendorId']), int.parse(printerDetail['productId']));
                if (isConnected == true) {
                  await flutterUsbPrinter.write(data);
                } else {
                  Fluttertoast.showToast(
                      backgroundColor: Colors.red,
                      msg: "${AppLocalizations.of(context)?.translate('usb_printer_not_connect')}");
                }
              }
            } else {
              if (printerList[i].paper_size == 0) {
                //print LAN 80mm paper
                final profile = await CapabilityProfile.load();
                final printer = NetworkPrinter(PaperSize.mm80, profile);
                final PosPrintResult res = await printer.connect(printerDetail, port: 9100);
                if (res == PosPrintResult.success) {
                  await ReceiptLayout().printCheckList80mm(false, value: printer);
                  printer.disconnect();
                } else {
                  Fluttertoast.showToast(
                      backgroundColor: Colors.red,
                      msg: "${AppLocalizations.of(context)?.translate('lan_printer_not_connect')}");
                }
              } else {
                //print LAN 58mm paper
                final profile = await CapabilityProfile.load();
                final printer = NetworkPrinter(PaperSize.mm58, profile);
                final PosPrintResult res = await printer.connect(printerDetail, port: 9100);
                if (res == PosPrintResult.success) {
                  await ReceiptLayout().printCheckList58mm(false, value: printer);
                  printer.disconnect();
                } else {
                  Fluttertoast.showToast(
                      backgroundColor: Colors.red,
                      msg: "${AppLocalizations.of(context)?.translate('lan_printer_not_connect')}");
                }
              }
            }
          }
        }
      }
    } catch (e) {
      print('Printer Connection Error: ${e}');
      Fluttertoast.showToast(
          backgroundColor: Colors.red,
          msg: "${AppLocalizations.of(context)?.translate('printing_error')}");
    }
  }

  _printKitchenList(CartModel cart) async {
    for (int i = 0; i < printerList.length; i++) {
      List<PrinterLinkCategory> data =
          await PosDatabase.instance.readPrinterLinkCategory(printerList[i].printer_sqlite_id!);
      for (int j = 0; j < data.length; j++) {
        for (int k = 0; k < cart.cartNotifierItem.length; k++) {
          //check printer category
          if (cart.cartNotifierItem[k].category_sqlite_id == data[j].category_sqlite_id &&
              cart.cartNotifierItem[k].status == 0) {
            var printerDetail = jsonDecode(printerList[i].value!);
            //check printer type
            if (printerList[i].type == 1) {
              //check paper size
              if (printerList[i].paper_size == 0) {
                //print LAN
                final profile = await CapabilityProfile.load();
                final printer = NetworkPrinter(PaperSize.mm80, profile);
                final PosPrintResult res = await printer.connect(printerDetail, port: 9100);

                if (res == PosPrintResult.success) {
                  await ReceiptLayout()
                      .printKitchenList80mm(false, cart.cartNotifierItem[k], value: printer);
                  printer.disconnect();
                } else {
                  Fluttertoast.showToast(
                      backgroundColor: Colors.red,
                      msg: "${AppLocalizations.of(context)?.translate('lan_printer_not_connect')}");
                }
              } else {
                //print LAN 58mm
                final profile = await CapabilityProfile.load();
                final printer = NetworkPrinter(PaperSize.mm58, profile);
                final PosPrintResult res = await printer.connect(printerDetail, port: 9100);

                if (res == PosPrintResult.success) {
                  await ReceiptLayout()
                      .printKitchenList58mm(false, cart.cartNotifierItem[k], value: printer);
                  printer.disconnect();
                } else {
                  Fluttertoast.showToast(
                      backgroundColor: Colors.red,
                      msg: "${AppLocalizations.of(context)?.translate('lan_printer_not_connect')}");
                }
              }
            } else {
              //print USB
              if (printerList[i].paper_size == 0) {
                var data = Uint8List.fromList(
                    await ReceiptLayout().printKitchenList80mm(true, cart.cartNotifierItem[k]));
                bool? isConnected = await flutterUsbPrinter.connect(
                    int.parse(printerDetail['vendorId']), int.parse(printerDetail['productId']));
                if (isConnected == true) {
                  await flutterUsbPrinter.write(data);
                } else {
                  Fluttertoast.showToast(
                      backgroundColor: Colors.red,
                      msg: "${AppLocalizations.of(context)?.translate('usb_printer_not_connect')}");
                }
              } else {
                //print 58mm
                var data = Uint8List.fromList(
                    await ReceiptLayout().printKitchenList58mm(true, cart.cartNotifierItem[k]));
                bool? isConnected = await flutterUsbPrinter.connect(
                    int.parse(printerDetail['vendorId']), int.parse(printerDetail['productId']));
                if (isConnected == true) {
                  await flutterUsbPrinter.write(data);
                } else {
                  Fluttertoast.showToast(
                      backgroundColor: Colors.red,
                      msg: "${AppLocalizations.of(context)?.translate('usb_printer_not_connect')}");
                }
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

    List<Printer> data = await PosDatabase.instance.readAllBranchPrinter(branch_id!);
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
    if (!controller.isClosed) {
      controller.sink.add('refresh');
    }
  }

  getManualApplyPromotion(CartModel cart) {
    List<cartProductItem> _sameCategoryList = [];
    allPromo = '';
    selectedPromoRate = '';
    try {
      if (cart.selectedPromotion != null) {
        allPromo = cart.selectedPromotion!.name!;
        if (cart.selectedPromotion!.type == 0) {
          selectedPromoRate = cart.selectedPromotion!.amount.toString() + '%';
        } else {
          selectedPromoRate = cart.selectedPromotion!.amount! + '.00';
        }

        if (cart.selectedPromotion!.specific_category == '1') {
          for (int i = 0; i < cart.cartNotifierItem.length; i++) {
            if (cart.cartNotifierItem[i].category_id == cart.selectedPromotion!.category_id) {
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
    if (!controller.isClosed) {
      controller.sink.add('refresh');
    }
  }

  specificCategoryAmount(Promotion promotion, List<cartProductItem> cartItem) {
    try {
      selectedPromo = 0.0;
      hasSelectedPromo = false;

      for (int j = 0; j < cartItem.length; j++) {
        if (promotion.type == 0) {
          hasSelectedPromo = true;
          selectedPromo += (double.parse(cartItem[j].price) * cartItem[j].quantity) *
              (double.parse(promotion.amount!) / 100);
        } else {
          hasSelectedPromo = true;
          selectedPromo += (double.parse(promotion.amount!) * cartItem[j].quantity);
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
            selectedPromo +=
                double.parse(cart.selectedPromotion!.amount!) * cart.cartNotifierItem[i].quantity;
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
              if (cart.cartNotifierItem[m].category_id == promotionList[j].category_id) {
                hasPromo = true;
                promoName = promotionList[j].name!;
                if (!autoApplyPromotionList.contains(promotionList[j])) {
                  autoApplyPromotionList.add(promotionList[j]);
                  if (widget.currentPage != 'menu') {
                    cart.addAutoApplyPromo(promotionList[j]);
                  }
                }
                autoApplySpecificCategoryAmount(promotionList[j], cart.cartNotifierItem[m]);
              }
            }
          } else {
            //Auto apply non specific category promotion
            if (cart.cartNotifierItem.isNotEmpty) {
              hasPromo = true;
              autoApplyPromotionList.add(promotionList[j]);
              if (widget.currentPage != 'menu') {
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
    if (!controller.isClosed) {
      controller.sink.add('refresh');
    }
  }

  autoApplyNonSpecificCategoryAmount(Promotion promotion, CartModel cart) {
    try {
      promo = 0.0;
      for (int i = 0; i < cart.cartNotifierItem.length; i++) {
        if (promotion.type == 1) {
          promo += (double.parse(promotion.amount!) * cart.cartNotifierItem[i].quantity);
          promotion.promoAmount = promo;
          promoRate = 'RM' + promotion.amount!;
          promotion.promoRate = promoRate;
        } else {
          promo +=
              (double.parse(cart.cartNotifierItem[i].price) * cart.cartNotifierItem[i].quantity) *
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
      List<Tax> taxData =
          await PosDatabase.instance.readTax(branch_id.toString(), diningOptionID.toString());
      if (taxData.length > 0) {
        taxRateList = List.from(taxData);
      } else {
        taxRateList = [];
      }
    } catch (error) {
      print('get dining tax error: $error');
    }
    if (!controller.isClosed) {
      controller.sink.add('refresh');
    }
  }

/*
  receipt menu initial call
*/
  getReceiptPaymentDetail(CartModel cart) {
    this.total = 0.0;
    this.totalAmount = 0.0;
    this.rounding = 0.0;
    this.finalAmount = '0.00';
    this.paymentReceived = 0.0;
    this.paymentChange = 0.0;
    this.orderTaxList = [];
    this.orderPromotionList = [];
    this.localOrderId = '';

    for (int i = 0; i < cart.cartNotifierPayment.length; i++) {
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
    if (!controller.isClosed) {
      controller.sink.add('refresh');
    }
  }

/*
  Cart Ordering initial called
*/
  getSubTotal(CartModel cart) async {
    try {
      widget.currentPage == 'table' || widget.currentPage == 'qr_order'
          ? cart.selectedOption = 'Dine in'
          : null;
      total = 0.0;
      promo = 0.0;
      promoAmount = 0.0;
      for (int i = 0; i < cart.cartNotifierItem.length; i++) {
        total +=
            (double.parse((cart.cartNotifierItem[i].price)) * cart.cartNotifierItem[i].quantity);
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
    checkCartItem(cart);
    if (!controller.isClosed) {
      controller.sink.add('refresh');
    }
  }

  getTaxAmount() {
    try {
      discountPrice = total - promoAmount;
      if (taxRateList.length > 0) {
        for (int i = 0; i < taxRateList.length; i++) {
          priceIncTaxes = discountPrice * (double.parse(taxRateList[i].tax_rate!) / 100);
          taxRateList[i].tax_amount = priceIncTaxes;
        }
      }
    } catch (e) {
      print('get tax amount error: $e');
    }
    if (!controller.isClosed) {
      controller.sink.add('refresh');
    }
  }

  getAllTaxAmount() {
    double total = 0.0;
    for (int i = 0; i < taxRateList.length; i++) {
      total = total + taxRateList[i].tax_amount!;
    }
    priceIncAllTaxes = total;
    return priceIncAllTaxes;
  }

  getRounding() {
    double _round = 0.0;
    _round =
        double.parse(totalAmount.toStringAsFixed(1)) - double.parse(totalAmount.toStringAsFixed(2));
    if (_round.toStringAsFixed(2) != '0.05' && _round.toStringAsFixed(2) != '-0.05') {
      rounding = _round;
    } else {
      rounding = 0.0;
    }

    if (!controller.isClosed) {
      controller.sink.add('refresh');
    }
  }

  getAllTotal() {
    getAllTaxAmount();
    try {
      totalAmount = 0.0;
      discountPrice = total - promoAmount;
      totalAmount = discountPrice + priceIncAllTaxes;

      if (rounding == 0.0) {
        finalAmount = totalAmount.toStringAsFixed(2);
      } else {
        finalAmount = totalAmount.toStringAsFixed(1) + '0';
      }
      //totalAmount = (totalAmount * 100).truncate() / 100;
    } catch (error) {
      print('Total calc error: $error');
    }

    if (!controller.isClosed) {
      controller.sink.add('refresh');
    }
  }

/*
  ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
*/
  Future<Future<Object?>> openReprintDialog(List<Printer> printerList, CartModel cart) async {
    return showGeneralDialog(
        barrierColor: Colors.black.withOpacity(0.5),
        transitionBuilder: (context, a1, a2, widget) {
          final curvedValue = Curves.easeInOutBack.transform(a1.value) - 1.0;
          return Transform(
            transform: Matrix4.translationValues(0.0, curvedValue * 200, 0.0),
            child: Opacity(
              opacity: a1.value,
              child: ReprintDialog(
                printerList: printerList,
                cart: cart,
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

  Future<Future<Object?>> openChooseTableDialog(CartModel cartModel) async {
    return showGeneralDialog(
        barrierColor: Colors.black.withOpacity(0.5),
        transitionBuilder: (context, a1, a2, widget) {
          final curvedValue = Curves.easeInOutBack.transform(a1.value) - 1.0;
          return Transform(
            transform: Matrix4.translationValues(0.0, curvedValue * 200, 0.0),
            child: Opacity(
              opacity: a1.value,
              child: CartDialog(
                  selectedTableList: cartModel.selectedTable,
                  printerList: this.printerList,
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
              child: CartRemoveDialog(
                cartItem: item,
                currentPage: currentPage,
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

  Future<Future<Object?>> openLoadingDialogBox() async {
    return showGeneralDialog(
        barrierColor: Colors.black.withOpacity(0.5),
        transitionBuilder: (context, a1, a2, widget) {
          final curvedValue = Curves.easeInOutBack.transform(a1.value) - 1.0;
          return Transform(
            transform: Matrix4.translationValues(0.0, curvedValue * 200, 0.0),
            child: Opacity(
              opacity: a1.value,
              child: LoadingDialog(),
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
    if (data.length <= 0) {
      _isSettlement = true;
    } else {
      _isSettlement = false;
    }
  }

  readAllBranchLinkDiningOption() async {
    final prefs = await SharedPreferences.getInstance();
    final int? branch_id = prefs.getInt('branch_id');
    List<BranchLinkDining> data =
        await PosDatabase.instance.readBranchLinkDiningOption(branch_id!.toString());
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
      List<BranchLinkPromotion> data =
          await PosDatabase.instance.readBranchLinkPromotion(branch_id.toString());

      for (int i = 0; i < data.length; i++) {
        List<Promotion> temp = await PosDatabase.instance.checkPromotion(data[i].promotion_id!);
        if (temp.length > 0) promotionList.add(temp[0]);
      }
    } catch (error) {
      print('promotion list error $error');
    }
  }

/*
  Not dine in call
*/
  callCreateNewNotDineOrder(CartModel cart, ConnectivityChangeNotifier connectivity) async {
    await createOrderCache(cart, connectivity);
    await createOrderDetail(cart, connectivity);
  }

/*
  dine in call
*/
  callCreateNewOrder(CartModel cart, ConnectivityChangeNotifier connectivity) async {
    await createTableUseID(connectivity);
    await createTableUseDetail(cart);
    await createOrderCache(cart, connectivity);
    await createOrderDetail(cart, connectivity);
    await updatePosTable(cart, connectivity);
  }

/*
  add-on call (dine in)
*/
  callAddOrderCache(CartModel cart, ConnectivityChangeNotifier connectivity) async {
    await createOrderCache(cart, connectivity);
    await createOrderDetail(cart, connectivity);
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
    List<TableUse> data = await PosDatabase.instance.readAllTableUseId(branch_id!);

    while (colorFound == false) {
      /* change color */
      hexCode = colorToHex(randomColor());
      if (data.length > 0) {
        for (int i = 0; i < data.length; i++) {
          if (hexCode == data[i].card_color) {
            found = false;
            break;
          } else {
            tempColor = hexToInteger(hexCode!.replaceAll('#', ''));
            matchColor = hexToInteger(data[i].card_color!.replaceAll('#', ''));
            diff = tempColor - matchColor;
            if (diff.abs() < 160000) {
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
    }
    return hexCode;
  }

  randomBatch() {
    return Random().nextInt(1000000) + 1;
  }

  batchChecking() async {
    print('batch checking called!');
    int tempBatch = 0;
    bool batchFound = false;
    bool founded = false;
    final prefs = await SharedPreferences.getInstance();
    final int? branch_id = prefs.getInt('branch_id');

    List<OrderCache> data = await PosDatabase.instance.readBranchOrderCache(branch_id!);
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

/*
  ---------------Place Order part--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
*/
  createTableUseID(ConnectivityChangeNotifier connectivity) async {
    DateFormat dateFormat = DateFormat("yyyy-MM-dd HH:mm:ss");
    String dateTime = dateFormat.format(DateTime.now());
    final prefs = await SharedPreferences.getInstance();
    final int? branch_id = prefs.getInt('branch_id');
    String? hexCode;
    localTableUseId = '';
    try {
      hexCode = await colorChecking();
      if (hexCode != null) {
        TableUse data = TableUse(
            table_use_id: 0,
            branch_id: branch_id,
            table_use_key: '',
            order_cache_key: '',
            card_color: hexCode.toString(),
            sync_status: 0,
            created_at: dateTime,
            updated_at: '',
            soft_delete: '');
        //create table use data
        TableUse tableUseData = await PosDatabase.instance.insertSqliteTableUse(data);
        localTableUseId = tableUseData.table_use_sqlite_id.toString();
        TableUse _updatedTableUseData = await insertTableUseKey(tableUseData, dateTime);
        //sync tot cloud
        await syncTableUseIdToCloud(_updatedTableUseData);
      }
    } catch (e) {
      print(e);
      Fluttertoast.showToast(
          backgroundColor: Color(0xFFFF0000), msg: "Create table id error: ${e}");
    }
  }

  syncTableUseIdToCloud(TableUse updatedTableUseData) async {
    List<String> _value = [];
    //check is host reachable
    bool _hasInternetAccess = await Domain().isHostReachable();
    if (_hasInternetAccess) {
      _value.add(jsonEncode(updatedTableUseData));
      Map response = await Domain().SyncTableUseToCloud(_value.toString());
      if (response['status'] == '1') {
        List responseJson = response['data'];
        int syncData = await PosDatabase.instance.updateTableUseSyncStatusFromCloud(responseJson[0]['table_use_key']);
      }
    }
  }

  generateTableUseKey(TableUse tableUse) async {
    final prefs = await SharedPreferences.getInstance();
    final int? device_id = prefs.getInt('device_id');
    var bytes = tableUse.created_at!.replaceAll(new RegExp(r'[^0-9]'), '') +
        tableUse.table_use_sqlite_id.toString() +
        device_id.toString();
    return md5.convert(utf8.encode(bytes)).toString();
  }

  insertTableUseKey(TableUse tableUse, String dateTime) async {
    List<TableUse> _tbUseList = [];
    tableUseKey = await generateTableUseKey(tableUse);
    if (tableUseKey != null) {
      TableUse tableUseObject = TableUse(
          table_use_key: tableUseKey,
          sync_status: 0,
          updated_at: dateTime,
          table_use_sqlite_id: tableUse.table_use_sqlite_id);
      int tableUseData = await PosDatabase.instance.updateTableUseUniqueKey(tableUseObject);
      if (tableUseData == 1) {
        List<TableUse> data = await PosDatabase.instance.readSpecificTableUseId(tableUseObject.table_use_sqlite_id!);
        _tbUseList = data;
      }
    }
    return _tbUseList[0];
  }

  generateTableUseDetailKey(TableUseDetail tableUseDetail) async {
    final prefs = await SharedPreferences.getInstance();
    final int? device_id = prefs.getInt('device_id');
    var bytes = tableUseDetail.created_at!.replaceAll(new RegExp(r'[^0-9]'), '') +
        tableUseDetail.table_use_detail_sqlite_id.toString() +
        device_id.toString();
    return md5.convert(utf8.encode(bytes)).toString();
  }

  insertTableUseDetailKey(TableUseDetail tableUseDetail, String dateTime) async {
    TableUseDetail? _tableUseDetailData;
    tableUseDetailKey = await generateTableUseDetailKey(tableUseDetail);
    if (tableUseDetailKey != null) {
      TableUseDetail tableUseDetailObject = TableUseDetail(
          table_use_detail_key: tableUseDetailKey,
          sync_status: 0,
          updated_at: dateTime,
          table_use_detail_sqlite_id: tableUseDetail.table_use_detail_sqlite_id);
      int data = await PosDatabase.instance.updateTableUseDetailUniqueKey(tableUseDetailObject);
      if (data == 1) {
        TableUseDetail detailData = await PosDatabase.instance.readSpecificTableUseDetailByLocalId(tableUseDetailObject.table_use_detail_sqlite_id!);
        _tableUseDetailData = detailData;
      }
    }
    return _tableUseDetailData;
  }

  createTableUseDetail(CartModel cart) async {
    DateFormat dateFormat = DateFormat("yyyy-MM-dd HH:mm:ss");
    String dateTime = dateFormat.format(DateTime.now());
    List<String> _value = [];
    try {
      for (int i = 0; i < cart.selectedTable.length; i++) {
        //create table use detail
        TableUseDetail tableUseDetailData = await PosDatabase.instance.insertSqliteTableUseDetail(
            TableUseDetail(
                table_use_detail_id: 0,
                table_use_detail_key: '',
                table_use_sqlite_id: localTableUseId,
                table_use_key: tableUseKey,
                table_sqlite_id: cart.selectedTable[i].table_sqlite_id.toString(),
                original_table_sqlite_id: cart.selectedTable[i].table_sqlite_id.toString(),
                sync_status: 0,
                created_at: dateTime,
                updated_at: '',
                soft_delete: ''));
        TableUseDetail updatedDetail = await insertTableUseDetailKey(tableUseDetailData, dateTime);
        _value.add(jsonEncode(updatedDetail.syncJson()));
      }
      //sync to cloud
      syncTableUseDetailToCloud(_value.toString());
    } catch (e) {
      print(e);
      Fluttertoast.showToast(
          backgroundColor: Color(0xFFFF0000), msg: "Create table detail error: ${e}");
    }
  }

  syncTableUseDetailToCloud(String value) async {
    //check is host reachable
    bool _hasInternetAccess = await Domain().isHostReachable();
    if (_hasInternetAccess) {
      Map response = await Domain().SyncTableUseDetailToCloud(value);
      if (response['status'] == '1') {
        List responseJson = response['data'];
        for (int i = 0; i < responseJson.length; i++) {
          int updateStatus = await PosDatabase.instance.updateTableUseDetailSyncStatusFromCloud(responseJson[i]['table_use_detail_key']);
        }
      }
    }
  }

  createOrderCache(CartModel cart, ConnectivityChangeNotifier connectivity) async {
    DateFormat dateFormat = DateFormat("yyyy-MM-dd HH:mm:ss");
    String dateTime = dateFormat.format(DateTime.now());

    final prefs = await SharedPreferences.getInstance();
    final int? branch_id = prefs.getInt('branch_id');
    final String? user = prefs.getString('user');
    List<TableUse> _tableUse = [];
    Map userObject = json.decode(user!);
    String _tableUseId = '';
    int batch = 0;
    try {
      batch = await batchChecking();
      //check selected table is in use or not
      if (cart.selectedOption == 'Dine in') {
        for (int i = 0; i < cart.selectedTable.length; i++) {
          List<TableUseDetail> useDetail = await PosDatabase.instance.readSpecificTableUseDetail(cart.selectedTable[i].table_sqlite_id!);
          if (useDetail.length > 0) {
            _tableUseId = useDetail[0].table_use_sqlite_id!;
          } else {
            _tableUseId = this.localTableUseId;
          }
        }
        List<TableUse> tableUseData = await PosDatabase.instance.readSpecificTableUseId(int.parse(_tableUseId));
        _tableUse = tableUseData;
      }
      if (batch != 0) {
        //create order cache
        OrderCache data = await PosDatabase.instance.insertSqLiteOrderCache(OrderCache(
            order_cache_id: 0,
            order_cache_key: '',
            company_id: userObject['company_id'].toString(),
            branch_id: branch_id.toString(),
            order_detail_id: '',
            table_use_sqlite_id: cart.selectedOption == 'Dine in' ? _tableUseId : '',
            table_use_key: cart.selectedOption == 'Dine in' ? _tableUse[0].table_use_key : '',
            batch_id: batch.toString().padLeft(6, '0'),
            dining_id: this.diningOptionID.toString(),
            order_sqlite_id: '',
            order_key: '',
            order_by: userObject['name'].toString(),
            order_by_user_id: userObject['user_id'].toString(),
            cancel_by: '',
            cancel_by_user_id: '',
            customer_id: '0',
            total_amount: cart.selectedOption == "Dine in" ? '' : finalAmount,
            sync_status: 0,
            created_at: dateTime,
            updated_at: '',
            soft_delete: ''));
        orderCacheId = data.order_cache_sqlite_id.toString();
        OrderCache updatedCache = await insertOrderCacheKey(data, dateTime);
        if (updatedCache.sync_status == 0) {
          //sync updated table use (with order cache key)
          await insertOrderCacheKeyIntoTableUse(cart, updatedCache, dateTime, connectivity);
        }
        //sync to cloud
        syncOrderCacheToCloud(updatedCache);
      }
    } catch (e) {
      print('error: ${e}');
      Fluttertoast.showToast(
          backgroundColor: Color(0xFFFF0000), msg: "Create order cache error: ${e}");
    }
  }

  syncOrderCacheToCloud(OrderCache updatedCache) async {
    List<String> _orderCacheValue = [];
    bool _hasInternetAccess = await Domain().isHostReachable();
    if (_hasInternetAccess) {
      _orderCacheValue.add(jsonEncode(updatedCache));
      Map response = await Domain().SyncOrderCacheToCloud(_orderCacheValue.toString());
      if (response['status'] == '1') {
        List responseJson = response['data'];
        int orderCacheData = await PosDatabase.instance.updateOrderCacheSyncStatusFromCloud(responseJson[0]['order_cache_key']);
      }
    }
  }

  generateOrderCacheKey(OrderCache orderCache) async {
    final prefs = await SharedPreferences.getInstance();
    final int? device_id = prefs.getInt('device_id');
    var bytes = orderCache.created_at!.replaceAll(new RegExp(r'[^0-9]'), '') +
        orderCache.order_cache_sqlite_id.toString() +
        device_id.toString();
    return md5.convert(utf8.encode(bytes)).toString();
  }

  insertOrderCacheKey(OrderCache orderCache, String dateTime) async {
    OrderCache? data;
    orderCacheKey = await generateOrderCacheKey(orderCache);
    if (orderCacheKey != null) {
      OrderCache orderCacheObject = OrderCache(
          order_cache_key: orderCacheKey,
          sync_status: 0,
          updated_at: dateTime,
          order_cache_sqlite_id: orderCache.order_cache_sqlite_id);
      int cacheUniqueKey = await PosDatabase.instance.updateOrderCacheUniqueKey(orderCacheObject);
      if (cacheUniqueKey == 1) {
        OrderCache orderCacheData = await PosDatabase.instance
            .readSpecificOrderCacheByLocalId(orderCacheObject.order_cache_sqlite_id!);
        if (orderCacheData.sync_status == 0) {
          data = orderCacheData;
        }
      }
    }
    return data;
  }

  insertOrderCacheKeyIntoTableUse(CartModel cart, OrderCache orderCache, String dateTime, ConnectivityChangeNotifier connectivity) async {
    List<String> _tableUseValue = [];
    if (cart.selectedOption == "Dine in") {
      List<TableUse> checkTableUse = await PosDatabase.instance.readSpecificTableUseId(int.parse(orderCache.table_use_sqlite_id!));
      TableUse tableUseObject = TableUse(
          order_cache_key: orderCacheKey,
          sync_status: checkTableUse[0].sync_status == 0 ? 0 : 2,
          updated_at: dateTime,
          table_use_sqlite_id: int.parse(orderCache.table_use_sqlite_id!));
      int tableUseCacheKey = await PosDatabase.instance.updateTableUseOrderCacheUniqueKey(tableUseObject);
      if (tableUseCacheKey == 1 && connectivity.isConnect) {
        List<TableUse> updatedTableUseRead = await PosDatabase.instance.readSpecificTableUseId(tableUseObject.table_use_sqlite_id!);
        _tableUseValue.add(jsonEncode(updatedTableUseRead[0]));
        //sync to cloud
        syncUpdatedTableUseIdToCloud(_tableUseValue.toString());
      }
    }
  }

  syncUpdatedTableUseIdToCloud(String tableUseValue) async {
    bool _hasInternetAccess = await Domain().isHostReachable();
    if (_hasInternetAccess) {
      var response = await Domain().SyncTableUseToCloud(tableUseValue);
      if(response != null){
        if (response['status'] == '1') {
          List responseJson = response['data'];
          int updatedTableUse = await PosDatabase.instance.updateTableUseSyncStatusFromCloud(responseJson[0]['table_use_key']);
        }
      } else {
        this.timeOutDetected = true;
      }

    }
  }

  createOrderDetail(CartModel cart, ConnectivityChangeNotifier connectivity) async {
    DateFormat dateFormat = DateFormat("yyyy-MM-dd HH:mm:ss");
    String dateTime = dateFormat.format(DateTime.now());
    List<String> _orderDetailValue = [];
    List<String> _orderModifierValue = [];
    bool _hasModifier = false;
    //loop cart item & create order detail
    for (int j = 0; j < cart.cartNotifierItem.length; j++) {
      if (cart.cartNotifierItem[j].status == 0) {
        OrderDetail orderDetailData = await PosDatabase.instance.insertSqliteOrderDetail(
            OrderDetail(
                order_detail_id: 0,
                order_detail_key: '',
                order_cache_sqlite_id: orderCacheId,
                order_cache_key: orderCacheKey,
                branch_link_product_sqlite_id: cart.cartNotifierItem[j].branchProduct_id,
                category_sqlite_id: cart.cartNotifierItem[j].category_sqlite_id,
                productName: cart.cartNotifierItem[j].name,
                has_variant: cart.cartNotifierItem[j].variant.length == 0 ? '0' : '1',
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
        //insert order detail key
        OrderDetail updatedOrderDetailData = await insertOrderDetailKey(orderDetailData, dateTime);
        if (updatedOrderDetailData.order_detail_key != '' && connectivity.isConnect) {
          _orderDetailValue.add(jsonEncode(updatedOrderDetailData.syncJson()));
        }
        //insert order modifier detail
        if (cart.cartNotifierItem[j].modifier.isNotEmpty) {
          for (int k = 0; k < cart.cartNotifierItem[j].modifier.length; k++) {
            ModifierGroup group = cart.cartNotifierItem[j].modifier[k];
            for (int m = 0; m < group.modifierChild.length; m++) {
              if (group.modifierChild[m].isChecked!) {
                _hasModifier = true;
                OrderModifierDetail orderModifierDetailData = await PosDatabase.instance
                    .insertSqliteOrderModifierDetail(OrderModifierDetail(
                        order_modifier_detail_id: 0,
                        order_modifier_detail_key: '',
                        order_detail_sqlite_id: orderDetailData.order_detail_sqlite_id.toString(),
                        order_detail_id: '0',
                        order_detail_key: await orderDetailKey,
                        mod_item_id: group.modifierChild[m].mod_item_id.toString(),
                        mod_group_id: group.mod_group_id.toString(),
                        sync_status: 0,
                        created_at: dateTime,
                        updated_at: '',
                        soft_delete: ''));
                //insert unique key
                OrderModifierDetail updatedOrderModifierDetail =
                    await insertOrderModifierDetailKey(orderModifierDetailData, dateTime);
                if (updatedOrderModifierDetail.order_modifier_detail_key != '' &&
                    connectivity.isConnect) {
                  _orderModifierValue.add(jsonEncode(updatedOrderModifierDetail));
                }
              }
            }
          }
        }
      }
    }
    if(this.timeOutDetected == false){
      syncOrderDetailToCloud(_orderDetailValue.toString());
      if (_hasModifier) {
        syncOrderModifierToCloud(_orderModifierValue.toString());
      }
    }
  }

  syncOrderDetailToCloud(String orderDetailValue) async {
    bool _hasInternetAccess = await Domain().isHostReachable();
    if (_hasInternetAccess) {
      Map orderDetailResponse = await Domain().SyncOrderDetailToCloud(orderDetailValue);
      if (orderDetailResponse['status'] == '1') {
        List responseJson = orderDetailResponse['data'];
        for (int i = 0; i < responseJson.length; i++) {
          int syncUpdated = await PosDatabase.instance.updateOrderDetailSyncStatusFromCloud(responseJson[i]['order_detail_key']);
        }
      }
    }
  }

  syncOrderModifierToCloud(String orderModifierValue) async {
    bool _hasInternetAccess = await Domain().isHostReachable();
    if (_hasInternetAccess) {
      Map orderModifierResponse = await Domain().SyncOrderModifierDetailToCloud(orderModifierValue);
      if (orderModifierResponse['status'] == '1') {
        List responseJson = orderModifierResponse['data'];
        for (int i = 0; i < responseJson.length; i++) {
          int syncUpdated = await PosDatabase.instance.updateOrderModifierDetailSyncStatusFromCloud(responseJson[i]['order_modifier_detail_key']);
        }
      }
    }
  }

  insertOrderModifierDetailKey(OrderModifierDetail orderModifierDetail, String dateTime) async {
    OrderModifierDetail? detailData;
    orderModifierDetailKey = await generateOrderModifierDetailKey(orderModifierDetail);
    if (orderModifierDetailKey != null) {
      OrderModifierDetail orderModifierDetailData = OrderModifierDetail(
          order_modifier_detail_key: orderModifierDetailKey,
          updated_at: dateTime,
          sync_status: orderModifierDetail.sync_status == 0 ? 0 : 2,
          order_modifier_detail_sqlite_id: orderModifierDetail.order_modifier_detail_sqlite_id);
      int updateUniqueKey =
          await PosDatabase.instance.updateOrderModifierDetailUniqueKey(orderModifierDetailData);
      if (updateUniqueKey == 1) {
        OrderModifierDetail data = await PosDatabase.instance.readSpecificOrderModifierDetailByLocalId(orderModifierDetailData.order_modifier_detail_sqlite_id!);
        detailData = data;
      }
    }
    return detailData;
  }

  insertOrderDetailKey(OrderDetail orderDetail, String dateTime) async {
    OrderDetail? detailData;
    orderDetailKey = await generateOrderDetailKey(orderDetail);
    if (orderDetailKey != null) {
      OrderDetail orderDetailObject = OrderDetail(
          order_detail_key: orderDetailKey,
          sync_status: 0,
          updated_at: dateTime,
          order_detail_sqlite_id: orderDetail.order_detail_sqlite_id);
      int updateUniqueKey =
          await PosDatabase.instance.updateOrderDetailUniqueKey(orderDetailObject);
      if (updateUniqueKey == 1) {
        OrderDetail data = await PosDatabase.instance
            .readSpecificOrderDetailByLocalId(orderDetailObject.order_detail_sqlite_id!);
        detailData = data;
      }
    }
    return detailData;
  }

  generateOrderDetailKey(OrderDetail orderDetail) async {
    final prefs = await SharedPreferences.getInstance();
    final int? device_id = prefs.getInt('device_id');
    var bytes = orderDetail.created_at!.replaceAll(new RegExp(r'[^0-9]'), '') +
        orderDetail.order_detail_sqlite_id.toString() +
        device_id.toString();
    return md5.convert(utf8.encode(bytes)).toString();
  }

  generateOrderModifierDetailKey(OrderModifierDetail orderModifierDetail) async {
    final prefs = await SharedPreferences.getInstance();
    final int? device_id = prefs.getInt('device_id');
    var bytes = orderModifierDetail.created_at!.replaceAll(new RegExp(r'[^0-9]'), '') +
        orderModifierDetail.order_modifier_detail_sqlite_id.toString() +
        device_id.toString();
    return md5.convert(utf8.encode(bytes)).toString();
  }

  updatePosTable(CartModel cart, ConnectivityChangeNotifier connectivity) async {
    try {
      List<String> _value = [];
      DateFormat dateFormat = DateFormat("yyyy-MM-dd HH:mm:ss");
      String dateTime = dateFormat.format(DateTime.now());
      final prefs = await SharedPreferences.getInstance();
      final int? branch_id = prefs.getInt('branch_id');

      for (int i = 0; i < cart.selectedTable.length; i++) {
        List<PosTable> result = await PosDatabase.instance.checkPosTableStatus(branch_id!, cart.selectedTable[i].table_sqlite_id!);
        if (result[0].status == 0) {
          PosTable posTableData = PosTable(
              table_sqlite_id: cart.selectedTable[i].table_sqlite_id,
              table_use_detail_key: tableUseDetailKey,
              status: 1,
              updated_at: dateTime);
          int data = await PosDatabase.instance.updateCartPosTableStatus(posTableData);
          if (data == 1 && connectivity.isConnect) {
            List<PosTable> posTable = await PosDatabase.instance.readSpecificTable(posTableData.table_sqlite_id.toString());
            if (posTable[0].sync_status == 2) {
              _value.add(jsonEncode(posTable[0]));
            }
          }
        }
      }
      if(this.timeOutDetected == false){
        syncUpdatedTableToCloud(_value.toString());
      }
    } catch (e) {
      Fluttertoast.showToast(backgroundColor: Color(0xFFFF0000), msg: "update table error: ${e}");
      print("update table error: $e");
    }
  }

  syncUpdatedTableToCloud(String value) async {
    bool _hasInternetAccess = await Domain().isHostReachable();
    if (_hasInternetAccess) {
      Map data = await Domain().SyncUpdatedPosTableToCloud(value);
      if (data['status'] == '1') {
        List responseJson = data['data'];
        for (var i = 0; i < responseJson.length; i++) {
          int syncData = await PosDatabase.instance.updatePosTableSyncStatusFromCloud(responseJson[i]['table_id']);
        }
      }
    }
  }
}
