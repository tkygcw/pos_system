import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:assets_audio_player/assets_audio_player.dart';
import 'package:confirm_dialog/confirm_dialog.dart';
import 'package:f_logs/model/flog/flog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_usb_printer/flutter_usb_printer.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';
import 'package:pos_system/database/pos_firestore.dart';
import 'package:pos_system/fragment/cart/adjust_price.dart';
import 'package:pos_system/fragment/cart/cart_dialog.dart';
import 'package:pos_system/fragment/cart/promotion_dialog.dart';
import 'package:pos_system/fragment/cart/remove_cart_dialog.dart';
import 'package:pos_system/fragment/cart/reprint_dialog.dart';
import 'package:pos_system/fragment/cart/reprint_kitchen_list_dialog.dart';
import 'package:pos_system/fragment/custom_toastification.dart';
import 'package:pos_system/fragment/product_cancel/adjust_quantity.dart';
import 'package:pos_system/notifier/cart_notifier.dart';
import 'package:pos_system/notifier/fail_print_notifier.dart';
import 'package:pos_system/notifier/theme_color.dart';
import 'package:pos_system/object/branch_link_dining_option.dart';
import 'package:pos_system/object/branch_link_product.dart';
import 'package:pos_system/object/branch_link_promotion.dart';
import 'package:pos_system/object/cart_product.dart';
import 'package:pos_system/object/dining_option.dart';
import 'package:pos_system/object/modifier_group.dart';
import 'package:pos_system/object/modifier_item.dart';
import 'package:pos_system/object/order.dart';
import 'package:pos_system/object/order_cache.dart';
import 'package:pos_system/object/order_detail.dart';
import 'package:pos_system/object/order_payment_split.dart';
import 'package:pos_system/object/order_promotion_detail.dart';
import 'package:pos_system/object/order_tax_detail.dart';
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
import '../../main.dart';
import '../../notifier/app_setting_notifier.dart';
import '../../notifier/notification_notifier.dart';
import '../../object/app_setting.dart';
import '../../object/cart_payment.dart';
import '../../object/cash_record.dart';
import '../../object/order_modifier_detail.dart';
import '../../object/second_display_data.dart';
import '../printing_layout/print_receipt.dart';
import '../../object/printer.dart';
import '../../object/table.dart';
import '../../object/tax.dart';
import '../../translation/AppLocalizations.dart';
import '../../utils/Utils.dart';
import '../logout_dialog.dart';
import '../settlement/cash_dialog.dart';
import '../payment/payment_select_dialog.dart';

class CartPage extends StatefulWidget {
  final String currentPage;
  final BuildContext? parentContext;

  const CartPage({required this.currentPage, Key? key, this.parentContext}) : super(key: key);

  @override
  State<CartPage> createState() => CartPageState();
}

class CartPageState extends State<CartPage> {
  final PosFirestore posFirestore = PosFirestore.instance;
  final ScrollController _scrollController = ScrollController();
  late StreamController controller;
  late AppSettingModel _appSettingModel;
  late FailPrintModel _failPrintModel;
  FlutterUsbPrinter flutterUsbPrinter = FlutterUsbPrinter();
  PrintReceipt printReceipt = PrintReceipt();
  List<Printer> printerList = [];
  List<Promotion> promotionList = [], autoApplyPromotionList = [];
  List<OrderPaymentSplit> paymentSplitList = [];
  List<BranchLinkDining> diningList = [];
  List<String> branchLinkDiningIdList = [];
  List<cartProductItem> sameCategoryItemList = [];
  List<TableUse> tableUseList = [];
  List<Tax> taxRateList = [];
  List<OrderTaxDetail> orderTaxList = [];
  List<OrderPromotionDetail> orderPromotionList = [];
  List<Order> orderList = [];
  List<OrderCache> orderCacheList = [];
  int diningOptionID = 0, simpleIntInput = 0;
  double total = 0.0,
      newOrderSubtotal = 0.0,
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
      paymentChange = 0.0,
      paymentSplitAmount = 0.0;
  String selectedPromoRate = '', promoName = '', promoRate = '', localTableUseId = '', orderCacheId = '', orderNumber = '', allPromo = '', finalAmount = '', localOrderId = '';
  String? table_use_value,
      table_use_detail_value,
      order_cache_value,
      order_detail_value,
      order_modifier_detail_value,
      table_value,
      branch_link_product_value,
      unit,
      per_quantity_unit;
  String? orderCacheKey;
  String? orderDetailKey;
  String? tableUseKey;
  String? orderModifierDetailKey;
  String? tableUseDetailKey;
  bool hasPromo = false,
      hasSelectedPromo = false,
      _isSettlement = false,
      hasNewItem = false,
      timeOutDetected = false,
      isLogOut = false,
      isLoading = false,
      isButtonDisabled = false;
  Color font = Colors.black45;
  int myCount = 0;

  Timer? _timer;

  bool lastDiningOption = false;

  String orderKey = '';

  void _scrollDown() {
    _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
  }

  @override
  void initState() {
    controller = StreamController();
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
  void dispose() {
    _timer?.cancel();
    reInitSecondDisplay(cartEmpty: true);
    super.dispose();
  }

  Future showSecondDialog(BuildContext context, ThemeColor color, CartModel cart, BranchLinkDining branchLinkDining) {
    return showDialog(
      barrierDismissible: false,
      context: context,
      builder: (BuildContext context) => Center(
        child: SingleChildScrollView(
          physics: NeverScrollableScrollPhysics(),
          child: AlertDialog(
            title: Text(AppLocalizations.of(context)!.translate('confirm_change_dining_option')),
            content: SizedBox(child: Text(AppLocalizations.of(context)!.translate('all_your_cart_item_will_remove_confirm_change_dining_option'))),
            actions: <Widget>[
              TextButton(
                child: Text('${AppLocalizations.of(context)?.translate('close')}'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
              TextButton(
                child: Text('${AppLocalizations.of(context)?.translate('yes')}'),
                onPressed: () {
                  cart.removeAllCartItem();
                  cart.removeAllTable();
                  cart.selectedOption = branchLinkDining.name!;
                  cart.selectedOptionId = branchLinkDining.dining_id!;
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeColor>(builder: (context, ThemeColor color, child) {
      return Consumer<AppSettingModel>(builder: (context, AppSettingModel appSettingModel, child) {
        _appSettingModel = appSettingModel;
        return Consumer<FailPrintModel>(builder: (context, FailPrintModel failPrintModel, child) {
          _failPrintModel = failPrintModel;
          return Consumer<CartModel>(builder: (context, CartModel cart, child) {
            return Consumer<NotificationModel>(builder: (context, NotificationModel notificationModel, child) {
              if(cart.cartNotifierItem.isEmpty){
                isButtonDisabled = true;
              } else {
                if(widget.currentPage != 'table' && widget.currentPage != 'other_order')
                  isButtonDisabled = false;
              }
              if(lastDiningOption == false) readAllBranchLinkDiningOption(cart: cart);

              if (notificationModel.cartContentLoaded == true) {
                notificationModel.resetCartContentLoaded();
                WidgetsBinding.instance.addPostFrameCallback((_){
                  cart.removeAllCartItem();
                  cart.removeAllTable();
                  cart.removeAllGroupList();
                  cart.removeAllPromotion();
                  cart.removePaymentDetail();
                });
                Future.delayed(const Duration(seconds: 1), () {
                  readAllBranchLinkDiningOption(cart: cart);
                  getPromotionData();
                  getSubTotal(cart);
                  getReceiptPaymentDetail(cart);
                });
              }
              widget.currentPage == 'menu' || widget.currentPage == 'table' || widget.currentPage == 'qr_order' || widget.currentPage == 'other_order'
                  ? getSubTotal(cart)
                  : getReceiptPaymentDetail(cart);
              return Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Scaffold(
                    resizeToAvoidBottomInset: false,
                    appBar: AppBar(
                      automaticallyImplyLeading: false,
                      title: Row(
                        children: [
                          Visibility(
                            visible: widget.currentPage == 'table' ? true: true,
                            child: Text('${getSelectedTable(cart, appSettingModel)}'),
                          ),
                          // MediaQuery.of(context).size.height > 500
                          //     ? Text(AppLocalizations.of(context)!.translate('bill'), style: TextStyle(fontSize: 20, color: Colors.black))
                          //     : SizedBox.shrink(),
                          // Visibility(
                          //   visible: widget.currentPage == 'table' ? true: false,
                          //   child: Expanded(
                          //     child: Padding(
                          //       padding: const EdgeInsets.all(8.0),
                          //       child: Text(AppLocalizations.of(context)!.translate('table')+': ${getSelectedTable(cart)}'),
                          //     ),
                          //   ),
                          // ),
                        ],
                      ),
                      backgroundColor: Colors.white,
                      actions: [
                        Visibility(
                          visible: widget.currentPage == 'menu' ? true : false,
                          child: Expanded(
                            child: IconButton(
                              tooltip: 'kitchen print',
                              icon: Badge(
                                isLabelVisible: failPrintModel.failedPrintOrderDetail.isEmpty ? false : true,
                                label: Text(failPrintModel.failedPrintOrderDetail.length.toString()),
                                child: const Icon(
                                  Icons.print,
                                ),
                              ),
                              color: color.backgroundColor,
                              onPressed: () {
                                //tableDialog(context);
                                openReprintKitchenDialog();
                              },
                            ),
                          ),
                        ),
                        Visibility(
                          visible: cart.selectedOption == 'Dine in' && widget.currentPage == 'menu' && appSettingModel.table_order != 0
                              ? true
                              : false,
                          child: Expanded(
                            child: IconButton(
                              tooltip: 'table',
                              icon: Badge(
                                isLabelVisible: cart.selectedTable.isEmpty ? false : true,
                                label: Text("${cart.selectedTable.length}"),
                                child: const Icon(
                                  Icons.table_restaurant,
                                ),
                              ),
                              color: color.backgroundColor,
                              onPressed: () {
                                //tableDialog(context);
                                openChooseTableDialog(cart);
                              },
                            ),
                          ),
                        ),
                        Visibility(
                          visible: (widget.currentPage == 'menu' && cart.selectedOption == 'Dine in' && appSettingModel.table_order != 0) ||
                              (widget.currentPage == 'menu' && cart.selectedOption != 'Dine in' && appSettingModel.directPaymentStatus == false) ||
                              widget.currentPage == 'qr_order' || widget.currentPage == 'bill' || ((widget.currentPage == 'table' || widget.currentPage == 'other_order') && orderKey != '')
                              ? false
                              : true,
                          child: IconButton(
                            tooltip: 'promotion',
                            icon: Icon(Icons.discount),
                            color: color.backgroundColor,
                            onPressed: () {
                              print("app setting: ${appSettingModel.directPaymentStatus}");
                              openPromotionDialog();
                            },
                          ),
                        ),
                        Visibility(
                          visible: widget.currentPage == 'menu' ? true : false,
                          child: Expanded(
                            child: IconButton(
                              tooltip: 'clear cart',
                              icon: const Icon(
                                Icons.delete,
                              ),
                              color: color.backgroundColor,
                              onPressed: () {
                                cart.removePartialCartItem();
                                //cart.removeAllTable();
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                    body: StreamBuilder(
                        stream: controller.stream,
                        builder: (context, snapshot) {
                          if(snapshot.hasData && notificationModel.contentLoad == false){
                            return Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                border: Border.all(color: Colors.grey.shade100, width: 3.0),
                              ),
                              child: Column(
                                children: [
                                  Container(
                                    margin: MediaQuery.of(context).size.height > 500 && MediaQuery.of(context).size.width > 900
                                        ? EdgeInsets.only(bottom: 10)
                                        : EdgeInsets.zero,
                                    child: GridView(
                                        physics: NeverScrollableScrollPhysics(),
                                        shrinkWrap: true,
                                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                            crossAxisCount: diningList.length == 3 ?  3 : 2,
                                            childAspectRatio: 2.0,
                                            mainAxisExtent: 50
                                        ),
                                        children: List.generate(diningList.length, (index) {
                                          return InkWell(
                                            onTap: () {
                                              widget.currentPage == 'menu'
                                                  ? cart.cartNotifierItem.isEmpty
                                                  ? setState(() {
                                                cart.removeAllTable();
                                                cart.selectedOption = diningList[index].name!;
                                                cart.selectedOptionId =
                                                diningList[index].dining_id!;
                                              })
                                                  : cart.cartNotifierItem.isNotEmpty &&
                                                  cart.cartNotifierItem[0].status != 1 &&
                                                  cart.selectedOption != diningList[index].name!
                                                  ? setState(() {
                                                showSecondDialog(
                                                    context, color, cart, diningList[index]);
                                              })
                                                  : null
                                                  : null;
                                            },
                                            child: Container(
                                                color: cart.selectedOption == diningList[index].name!
                                                    ? color.buttonColor
                                                    : color.backgroundColor,
                                                alignment: Alignment.center,
                                                child: Text(
                                                  diningList[index].name!,
                                                  textAlign: TextAlign.center,
                                                  style: TextStyle(
                                                      fontWeight: FontWeight.w600,
                                                      color: cart.selectedOption == diningList[index].name!
                                                          ? color.iconColor
                                                          : Colors.white,
                                                      fontSize: 16),
                                                )),
                                          );
                                        })),
                                  ),
                                  Expanded(
                                    child: ListView.builder(
                                        controller: _scrollController,
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
                                            key: ValueKey(cart.cartNotifierItem[index].product_name),
                                            direction: widget.currentPage == 'menu' && cart.cartNotifierItem[index].status == 0 ||
                                                widget.currentPage == 'table' && orderKey == ''||
                                                widget.currentPage == 'other_order' && orderKey == ''
                                                ? DismissDirection.startToEnd
                                                : DismissDirection.none,
                                            confirmDismiss: (direction) async {
                                              if (direction == DismissDirection.startToEnd) {
                                                await openRemoveCartItemDialog(cart.cartNotifierItem[index], widget.currentPage);
                                              }
                                              return null;
                                            },
                                            child: ListTile(
                                              hoverColor: Colors.transparent,
                                              isThreeLine: true,
                                              title: RichText(
                                                text: TextSpan(
                                                  children: <TextSpan>[
                                                    TextSpan(
                                                      text: cart.cartNotifierItem[index].product_name! + '\n',
                                                      style: TextStyle(
                                                          fontSize: 14,
                                                          color: cart.cartNotifierItem[index].status == 1 ? font : cart.cartNotifierItem[index].refColor,
                                                          fontWeight: FontWeight.bold),
                                                    ),
                                                    TextSpan(
                                                      // text: "RM" + cart.cartNotifierItem[index].price! + " (" +  ,
                                                        text:
                                                        "RM ${cart.cartNotifierItem[index].price!} (${cart.cartNotifierItem[index].unit! != 'each' && cart.cartNotifierItem[index].unit! != 'each_c' ? cart.cartNotifierItem[index].per_quantity_unit! + cart.cartNotifierItem[index].unit! : 'each'})",
                                                        style: TextStyle(
                                                          fontSize: 13,
                                                          color: cart.cartNotifierItem[index].status == 1 ? font : cart.cartNotifierItem[index].refColor,
                                                        )),
                                                  ],
                                                ),
                                              ),
                                              subtitle: Text(
                                                  getVariant(cart.cartNotifierItem[index]) + getModifier(cart.cartNotifierItem[index]) + getRemark(cart.cartNotifierItem[index]),
                                                  style: TextStyle(fontSize: 10)),
                                              onTap: () async {
                                                // if(widget.currentPage == 'menu' && cart.cartNotifierItem[index].status == 0 ||
                                                //     widget.currentPage == 'table' || widget.currentPage == 'other_order')
                                                if(orderKey == '') {
                                                  if(widget.currentPage == 'table' || widget.currentPage == 'other_order')
                                                    await openAdjustPriceDialog(cart, cart.cartNotifierItem[index], widget.currentPage, index);
                                                }
                                              },
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
                                                              if (cart.cartNotifierItem[index].status == 0) {
                                                                if (cart.cartNotifierItem[index].quantity! > 1) {
                                                                  if (cart.cartNotifierItem[index].unit != 'each' && cart.cartNotifierItem[index].unit != 'each_c') {
                                                                    setState(() {
                                                                      cart.cartNotifierItem[index].quantity = (cart.cartNotifierItem[index].quantity! - 1).ceilToDouble();
                                                                    });
                                                                  } else {
                                                                    setState(() {
                                                                      cart.cartNotifierItem[index].quantity = (cart.cartNotifierItem[index].quantity! - 1);
                                                                    });
                                                                  }
                                                                } else {
                                                                  cart.removeItem(cart.cartNotifierItem[index]);
                                                                }
                                                              } else {
                                                                Fluttertoast.showToast(
                                                                  backgroundColor: Colors.red,
                                                                  msg: AppLocalizations.of(context)!.translate('order_already_placed'),
                                                                );
                                                              }
                                                            }),
                                                      ),
                                                      Text(
                                                        cart.cartNotifierItem[index].quantity.toString(),
                                                        style: TextStyle(color: cart.cartNotifierItem[index].refColor),
                                                      ),
                                                      widget.currentPage == 'menu'
                                                          ? IconButton(
                                                          hoverColor: Colors.transparent,
                                                          icon: Icon(Icons.add),
                                                          onPressed: () async {
                                                            if (cart.cartNotifierItem[index].status == 0) {
                                                              if (await checkProductStock(cart, cart.cartNotifierItem[index]) == true) {
                                                                setState(() {
                                                                  cart.cartNotifierItem[index].quantity = cart.cartNotifierItem[index].quantity! + 1;
                                                                });
                                                              } else {
                                                                Fluttertoast.showToast(
                                                                    backgroundColor: Colors.red, msg: AppLocalizations.of(context)!.translate('product_out_of_stock'));
                                                              }
                                                            } else {
                                                              Fluttertoast.showToast(
                                                                  backgroundColor: Colors.red, msg: AppLocalizations.of(context)!.translate('order_already_placed'));
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
                                  SizedBox(height: MediaQuery.of(context).size.height > 500 && MediaQuery.of(context).size.width > 900 ? 20 : 5),
                                  Divider(
                                    color: Colors.grey,
                                    height: 1,
                                    thickness: 1,
                                    indent: 20,
                                    endIndent: 20,
                                  ),
                                  SizedBox(height: MediaQuery.of(context).size.height > 500 && MediaQuery.of(context).size.width > 900 ? 10 : 5),
                                  Container(
                                    height: MediaQuery.of(context).size.height > 500
                                        ? widget.currentPage == 'menu' || widget.currentPage == 'table' || widget.currentPage == 'other_order' || widget.currentPage == 'bill'
                                        ? MediaQuery.of(context).orientation == Orientation.landscape
                                        ? 130
                                        : 100
                                        : null
                                        : 25,
                                    child: ListView(
                                      physics: ClampingScrollPhysics(),
                                      children: [
                                        ListTile(
                                          title: Text('Subtotal', style: TextStyle(fontSize: 14)),
                                          trailing: Text('${total.toStringAsFixed(2)}', style: TextStyle(fontSize: 14)),
                                          visualDensity: VisualDensity(vertical: -4),
                                          dense: true,
                                        ),
                                        Visibility(
                                            visible: hasPromo == true ? true : false,
                                            child: ListView.builder(
                                                shrinkWrap: true,
                                                physics: NeverScrollableScrollPhysics(),
                                                itemCount: autoApplyPromotionList.length,
                                                itemBuilder: (context, index) {
                                                  return ListTile(
                                                      title: Text('${autoApplyPromotionList[index].name} (${autoApplyPromotionList[index].promoRate})', style: TextStyle(fontSize: 14)),
                                                      visualDensity: VisualDensity(vertical: -4),
                                                      dense: true,
                                                      trailing: Text('-${autoApplyPromotionList[index].promoAmount!.toStringAsFixed(2)}', style: TextStyle(fontSize: 14)));
                                                })),
                                        Visibility(
                                          visible: cart.selectedPromotion != null ? true : false,
                                          child: ListTile(
                                            title: SingleChildScrollView(
                                              scrollDirection: Axis.horizontal,
                                              child: Row(
                                                children: [
                                                  Text('${allPromo} (${selectedPromoRate})', style: TextStyle(fontSize: 14)),
                                                  Visibility(
                                                    visible: orderKey == '' ? true : false,
                                                    child: IconButton(
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
                                                  ),
                                                ],
                                              ),
                                            ),
                                            trailing: Text('-${selectedPromo.toStringAsFixed(2)}', style: TextStyle(fontSize: 14)),
                                            visualDensity: VisualDensity(vertical: -4),
                                            dense: true,
                                          ),
                                        ),
                                        Visibility(
                                          visible: widget.currentPage == 'bill' ? true : false,
                                          child: ListView.builder(
                                              shrinkWrap: true,
                                              physics: NeverScrollableScrollPhysics(),
                                              itemCount: orderPromotionList.length,
                                              itemBuilder: (context, index) {
                                                return ListTile(
                                                    title: Text('${orderPromotionList[index].promotion_name} (${orderPromotionList[index].rate})', style: TextStyle(fontSize: 14)),
                                                    visualDensity: VisualDensity(vertical: -4),
                                                    dense: true,
                                                    trailing: Text('-${orderPromotionList[index].promotion_amount}', style: TextStyle(fontSize: 14)));
                                              }),
                                        ),
                                        Visibility(
                                          visible:
                                          widget.currentPage == 'menu' || widget.currentPage == 'table' || widget.currentPage == 'qr_order' || widget.currentPage == 'other_order'
                                              ? true
                                              : false,
                                          child: ListView.builder(
                                              shrinkWrap: true,
                                              physics: NeverScrollableScrollPhysics(),
                                              itemCount: taxRateList.length,
                                              itemBuilder: (context, index) {
                                                return ListTile(
                                                  title: Text('${taxRateList[index].name}(${taxRateList[index].tax_rate}%)', style: TextStyle(fontSize: 14)),
                                                  trailing: Text('${taxRateList[index].tax_amount?.toStringAsFixed(2)}', style: TextStyle(fontSize: 14)),
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
                                                  title: Text('${orderTaxList[index].tax_name}(${orderTaxList[index].rate}%)', style: TextStyle(fontSize: 14)),
                                                  trailing: Text('${orderTaxList[index].tax_amount}', style: TextStyle(fontSize: 14)),
                                                  //Text(''),
                                                  visualDensity: VisualDensity(vertical: -4),
                                                  dense: true,
                                                );
                                              }),
                                        ),
                                        ListTile(
                                          title: Text('Amount', style: TextStyle(fontSize: 14)),
                                          trailing: Text('${totalAmount.toStringAsFixed(2)}', style: TextStyle(fontSize: 14)),
                                          visualDensity: VisualDensity(vertical: -4),
                                          dense: true,
                                        ),
                                        ListTile(
                                          title: Text('Rounding', style: TextStyle(fontSize: 14)),
                                          trailing: Text('${rounding.toStringAsFixed(2)}', style: TextStyle(fontSize: 14)),
                                          visualDensity: VisualDensity(vertical: -4),
                                          dense: true,
                                        ),
                                        Visibility(
                                            visible: orderKey != '' ? true : false,
                                            child: ListView.builder(
                                                shrinkWrap: true,
                                                physics: NeverScrollableScrollPhysics(),
                                                itemCount: paymentSplitList.length,
                                                itemBuilder: (context, index) {
                                                  return ListTile(
                                                      title: Text('${paymentSplitList[index].payment_name}', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                                                      visualDensity: VisualDensity(vertical: -4),
                                                      dense: true,
                                                      trailing: Text('${paymentSplitList[index].payment_received!}', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)));
                                                }
                                            )
                                        ),
                                        ListTile(
                                          visualDensity: VisualDensity(vertical: -4),
                                          title: Text('Final Amount', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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
                                                    title: Text('Payment received', style: TextStyle(fontSize: 14)),
                                                    trailing: Text("${paymentReceived.toStringAsFixed(2)}", style: TextStyle(fontSize: 14)),
                                                    dense: true,
                                                  ),
                                                ),
                                                Container(
                                                  child: ListTile(
                                                    visualDensity: VisualDensity(vertical: -4),
                                                    title: Text('Change', style: TextStyle(fontSize: 14)),
                                                    trailing: Text("${paymentChange.toStringAsFixed(2)}", style: TextStyle(fontSize: 14)),
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
                                    child: Row(
                                      children: [
                                        Visibility(
                                          visible: widget.currentPage != 'bill' ? true : false,
                                          child: Expanded(
                                              child: ElevatedButton(
                                                  style: ElevatedButton.styleFrom(
                                                    backgroundColor: color.backgroundColor,
                                                    minimumSize: const Size.fromHeight(50), // NEW
                                                  ),
                                                  onPressed: isButtonDisabled
                                                      ? null
                                                      : () async {
                                                    // setState(() {
                                                    //   isButtonDisabled = true;
                                                    // });
                                                    await checkCashRecord();
                                                    if (widget.currentPage == 'menu' || widget.currentPage == 'qr_order') {
                                                      if (_isSettlement == true) {
                                                        showDialog(
                                                            barrierDismissible: false,
                                                            context: context,
                                                            builder: (BuildContext context) {
                                                              return PopScope(
                                                                  canPop: false,
                                                                  child: CashDialog(isCashIn: true, callBack: () {}, isCashOut: false, isNewDay: true));
                                                            });
                                                        _isSettlement = false;
                                                      } else {
                                                        disableButton();
                                                        if (cart.selectedOption == 'Dine in' && appSettingModel.table_order != 0) {
                                                          if (cart.selectedTable.isNotEmpty && cart.cartNotifierItem.isNotEmpty) {
                                                            openLoadingDialogBox();
                                                            //_startTimer();
                                                            print('has new item ${hasNewItem}');
                                                            if (cart.cartNotifierItem[0].status == 1 && hasNewItem == true) {
                                                              asyncQ.addJob((_) async => await callAddOrderCache(cart));
                                                            } else if (cart.cartNotifierItem[0].status == 0) {
                                                              asyncQ.addJob((_) async {
                                                                await callCreateNewOrder(cart, appSettingModel);
                                                                print("local: cart add new order done");
                                                              });
                                                            } else {
                                                              Fluttertoast.showToast(
                                                                  backgroundColor: Colors.red, msg: AppLocalizations.of(context)!.translate('cannot_replace_same_order'));
                                                              Navigator.of(context).pop();
                                                            }
                                                            // cart.removeAllCartItem();
                                                            // cart.removeAllTable();
                                                          } else {
                                                            Fluttertoast.showToast(
                                                                backgroundColor: Colors.red,
                                                                msg: AppLocalizations.of(context)!.translate('make_sure_cart_is_not_empty_and_table_is_selected'));
                                                          }
                                                        } else {
                                                          // not dine in call
                                                          print("Not dine in called");
                                                          cart.removeAllTable();
                                                          if (cart.cartNotifierItem.isNotEmpty) {
                                                            openLoadingDialogBox();
                                                            asyncQ.addJob((_) async => await callCreateNewNotDineOrder(cart, appSettingModel));
                                                          } else {
                                                            Fluttertoast.showToast(backgroundColor: Colors.red, msg: "${AppLocalizations.of(context)?.translate('empty_cart')}");
                                                          }
                                                        }
                                                      }
                                                    } else if (widget.currentPage == 'table') {
                                                      if (cart.selectedTable.isNotEmpty && cart.cartNotifierItem.isNotEmpty) {
                                                        if (_isSettlement == true) {
                                                          showDialog(
                                                              barrierDismissible: false,
                                                              context: context,
                                                              builder: (BuildContext context) {
                                                                return PopScope(
                                                                    canPop: false,
                                                                    child: CashDialog(isCashIn: true, callBack: () {}, isCashOut: false, isNewDay: true));
                                                              });
                                                          _isSettlement = false;
                                                        } else {
                                                          if (cart.selectedTable.length > 1) {
                                                            if (await confirm(
                                                              context,
                                                              title: Text('${AppLocalizations.of(context)?.translate('confirm_merge_bill')}'),
                                                              content: Text('${AppLocalizations.of(context)?.translate('to_merge_bill')}'),
                                                              textOK: Text('${AppLocalizations.of(context)?.translate('yes')}'),
                                                              textCancel: Text('${AppLocalizations.of(context)?.translate('no')}'),
                                                            )) {
                                                              paymentAddToCart(cart);
                                                              return openPaymentSelect(cart);
                                                            }
                                                          } else {
                                                            paymentAddToCart(cart);
                                                            openPaymentSelect(cart);
                                                          }
                                                        }
                                                      } else {
                                                        Fluttertoast.showToast(backgroundColor: Colors.red, msg: "${AppLocalizations.of(context)?.translate('empty_cart')}");
                                                      }
                                                    } else if (widget.currentPage == 'other_order') {
                                                      if (cart.cartNotifierItem.isNotEmpty) {
                                                        if (_isSettlement == true) {
                                                          showDialog(
                                                              barrierDismissible: false,
                                                              context: context,
                                                              builder: (BuildContext context) {
                                                                return PopScope(
                                                                    canPop: false,
                                                                    child: CashDialog(isCashIn: true, callBack: () {}, isCashOut: false, isNewDay: true));
                                                              });
                                                          _isSettlement = false;
                                                        } else {
                                                          paymentAddToCart(cart);
                                                          openPaymentSelect(cart);
                                                        }
                                                      } else {
                                                        Fluttertoast.showToast(backgroundColor: Colors.red, msg: "${AppLocalizations.of(context)?.translate('empty_cart')}");
                                                      }
                                                    } else {
                                                      if (cart.cartNotifierItem.isNotEmpty) {
                                                        if (_isSettlement == true) {
                                                          showDialog(
                                                              barrierDismissible: false,
                                                              context: context,
                                                              builder: (BuildContext context) {
                                                                return PopScope(
                                                                    canPop: false,
                                                                    child: CashDialog(isCashIn: true, callBack: () {}, isCashOut: false, isNewDay: true));
                                                              });
                                                          _isSettlement = false;
                                                        } else {
                                                          int printStatus = await printReceipt.printCartReceiptList(printerList, cart, this.localOrderId);
                                                          checkPrinterStatus(printStatus);
                                                          cart.initialLoad();
                                                          cart.changInit(true);
                                                        }
                                                      } else {
                                                        Fluttertoast.showToast(backgroundColor: Colors.red, msg: "${AppLocalizations.of(context)?.translate('empty_cart')}");
                                                      }
                                                    }
                                                    enableButton();
                                                  },
                                                  child: MediaQuery.of(context).size.height > 500 && MediaQuery.of(context).size.width > 900
                                                      ? widget.currentPage == 'menu' || widget.currentPage == 'qr_order'
                                                      ? Text(AppLocalizations.of(context)!.translate('place_order') + '\n (RM ${this.finalAmount})')
                                                      : widget.currentPage == 'table' || widget.currentPage == 'other_order'
                                                      ? Text(AppLocalizations.of(context)!.translate('pay') + ' (RM ${this.finalAmount})')
                                                      : Text(AppLocalizations.of(context)!.translate('print_receipt'))
                                                  // mobile
                                                      : widget.currentPage == 'menu' || widget.currentPage == 'qr_order'
                                                      ? MediaQuery.of(context).orientation == Orientation.landscape
                                                      ? Text(AppLocalizations.of(context)!.translate('place_order'))
                                                      : Text(AppLocalizations.of(context)!.translate('place_order') + '\n (RM ${this.finalAmount})')
                                                      : widget.currentPage == 'table' || widget.currentPage == 'other_order'
                                                      ? MediaQuery.of(context).orientation == Orientation.landscape
                                                      ? Text(AppLocalizations.of(context)!.translate('pay'))
                                                      : Text(AppLocalizations.of(context)!.translate('pay') + ' (RM ${this.finalAmount})')
                                                      : Text(AppLocalizations.of(context)!.translate('print_receipt')))),
                                        ),
                                        Visibility(
                                            child: SizedBox(
                                              width: 10,
                                            ),
                                            visible: widget.currentPage == "table" || widget.currentPage == "other_order"
                                                ? true
                                                : widget.currentPage == "menu"
                                                ? cart.cartNotifierItem.any((item) => item.status == 1)
                                                ? true
                                                : false
                                                : false),
                                        Visibility(
                                          visible: widget.currentPage == "menu" && cart.cartNotifierItem.isNotEmpty && cart.cartNotifierItem[0].status == 1 ? true : false,
                                          child: Expanded(
                                            child: ElevatedButton(
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: color.backgroundColor,
                                                minimumSize: const Size.fromHeight(50),
                                              ),
                                              onPressed: () {
                                                bool hasNotPlacedOrder = cart.cartNotifierItem.any((item) => item.status == 0);
                                                if (hasNotPlacedOrder) {
                                                  Fluttertoast.showToast(
                                                      backgroundColor: Colors.red, msg: AppLocalizations.of(context)!.translate('make_sure_all_product_is_placed_order'));
                                                } else {
                                                  openReprintDialog(printerList, cart);
                                                }
                                              },
                                              child: Text(AppLocalizations.of(context)!.translate('reprint')),
                                            ),
                                          ),
                                        ),
                                        Visibility(
                                          visible: widget.currentPage == "table" || widget.currentPage == "other_order" || widget.currentPage == "bill" ? true : false,
                                          child: Expanded(
                                              child: ElevatedButton(
                                                  style: ElevatedButton.styleFrom(
                                                    backgroundColor: color.backgroundColor,
                                                    minimumSize: const Size.fromHeight(50),
                                                  ),
                                                  onPressed: cart.cartNotifierItem.isEmpty || isLoading
                                                      ? null
                                                      : () async {
                                                    setState(() {
                                                      isLoading = true;
                                                    });
                                                    if(widget.currentPage != 'bill'){
                                                      paymentAddToCart(cart);
                                                    }
                                                    openReprintDialog(printerList, cart);

                                                    setState(() {
                                                      isLoading = false;
                                                    });
                                                  },
                                                  child: isLoading
                                                      ? CircularProgressIndicator(
                                                    color: Colors.white,
                                                    strokeWidth: 3,
                                                  )
                                                      : Text(AppLocalizations.of(context)!.translate('reprint')))),
                                        )
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          } else {
                            return CustomProgressBar();
                          }
                        }),
                  ));
            });
          });
        });
      });
    });
  }

  num checkCartProductQuantity(CartModel cart, BranchLinkProduct branchLinkProduct) {
    ///get all same item in cart
    List<cartProductItem> sameProductList =
    cart.cartNotifierItem.where((item) => item.branch_link_product_sqlite_id == branchLinkProduct.branch_link_product_sqlite_id.toString() && item.status == 0).toList();
    if (sameProductList.isNotEmpty) {
      /// sum all quantity
      num totalQuantity = sameProductList.fold(0, (sum, product) => sum + product.quantity!);
      return totalQuantity;
    } else {
      return 0;
    }
  }

  checkProductStock(CartModel cart, cartProductItem cartItem) async {
    bool hasStock = true;
    List<BranchLinkProduct> data = await PosDatabase.instance.readSpecificBranchLinkProduct(cartItem.branch_link_product_sqlite_id!);
    if (data.isNotEmpty) {
      BranchLinkProduct product = data[0];
      switch (product.stock_type) {
        case '1':
          {
            if (int.parse(product.daily_limit!) > 0 && simpleIntInput <= int.parse(product.daily_limit!)) {
              num stockLeft = int.parse(product.daily_limit!) - checkCartProductQuantity(cart, product);
              print('stock left: ${stockLeft}');
              if (stockLeft > 0) {
                hasStock = true;
              } else {
                hasStock = false;
              }
            } else {
              hasStock = false;
            }
          }
          break;
        case '2':
          {
            num stockQuantity = int.tryParse(product.stock_quantity!) != null ? int.parse(product.stock_quantity!) : double.parse(product.stock_quantity!);
            if (stockQuantity > 0 && simpleIntInput <= stockQuantity) {
              num stockLeft = stockQuantity - checkCartProductQuantity(cart, product);
              if (stockLeft > 0) {
                hasStock = true;
              } else {
                hasStock = false;
              }
            } else {
              hasStock = false;
            }
          }
          break;
        default:
          {
            hasStock = true;
          }
      }
    }
    // BranchLinkProduct product = data[0];
    // if (product.has_variant == 0) {
    //   if (product.stock_type == '2') {
    //     if (int.parse(product.stock_quantity!) > 0 && simpleIntInput <= int.parse(product.stock_quantity!)) {
    //       int stockLeft =
    //           int.parse(product.stock_quantity!) - checkCartProductQuantity(cart, product);
    //       if (stockLeft > 0) {
    //         hasStock = true;
    //       } else {
    //         hasStock = false;
    //       }
    //     } else {
    //       hasStock = false;
    //     }
    //   } else {
    //     if (int.parse(product.daily_limit!) > 0 && simpleIntInput <= int.parse(product.daily_limit!)) {
    //       int stockLeft = int.parse(product.daily_limit!) - checkCartProductQuantity(cart, product);
    //       print('stock left: ${stockLeft}');
    //       if (stockLeft > 0) {
    //         hasStock = true;
    //       } else {
    //         hasStock = false;
    //       }
    //     } else {
    //       hasStock = false;
    //     }
    //   }
    // } else {
    //   //check has variant product stock
    //   if (product.stock_type == '2') {
    //     if (int.parse(product.stock_quantity!) > 0 &&
    //         simpleIntInput <= int.parse(product.stock_quantity!)) {
    //       int stockLeft =
    //           int.parse(product.stock_quantity!) - checkCartProductQuantity(cart, product);
    //       print('stock left: ${stockLeft}');
    //       if (stockLeft > 0) {
    //         hasStock = true;
    //       } else {
    //         hasStock = false;
    //       }
    //     } else {
    //       hasStock = false;
    //     }
    //   } else {
    //     if (int.parse(product.daily_limit_amount!) > 0 &&
    //         simpleIntInput <= int.parse(product.daily_limit_amount!)) {
    //       int stockLeft =
    //           int.parse(product.daily_limit_amount!) - checkCartProductQuantity(cart, product);
    //       print('stock left: ${stockLeft}');
    //       if (stockLeft > 0) {
    //         hasStock = true;
    //       } else {
    //         hasStock = false;
    //       }
    //     } else {
    //       hasStock = false;
    //     }
    //   }
    // }
    // print('has stock ${hasStock}');
    return hasStock;
  }

  // void _startTimer() {
  //   _isProcessComplete = false;
  //   _timer = Timer(Duration(seconds: 5), () {
  //     if (_isProcessComplete == false) {
  //       Navigator.of(context).pop();
  //       _isProcessComplete = true;
  //       enableButton();// Closing the dialog
  //     }
  //   });
  // }

  disableButton() {
    setState(() {
      isButtonDisabled = true;
    });
  }

  enableButton() {
    setState(() {
      isButtonDisabled = false;
    });
  }

  checkPrinterStatus(int printStatus) {
    if (printStatus == 1) {
      Fluttertoast.showToast(backgroundColor: Colors.red, msg: "${AppLocalizations.of(context)?.translate('printer_not_connected')}");
    } else if (printStatus == 2) {
      Fluttertoast.showToast(backgroundColor: Colors.orangeAccent, msg: "${AppLocalizations.of(context)?.translate('printer_connection_timeout')}");
    } else if (printStatus == 3) {
      Fluttertoast.showToast(backgroundColor: Colors.red, msg: AppLocalizations.of(context)!.translate('no_printer_added'));
    } else if (printStatus == 4) {
      Fluttertoast.showToast(backgroundColor: Colors.orangeAccent, msg: "${AppLocalizations.of(context)?.translate('no_cashier_printer')}");
    }
  }

  updateCartItem(CartModel cart) {
    for (int i = 0; i < cart.cartNotifierItem.length; i++) {
      cart.cartNotifierItem[i].order_cache_sqlite_id = orderCacheId;
      cart.cartNotifierItem[i].order_cache_key = orderCacheKey;
      cart.cartNotifierItem[i].order_queue = orderNumber;
    }
  }

  paymentAddToCart(CartModel cart) {
    var value = cartPaymentDetail('', total, totalAmount, rounding, finalAmount, 0.0, 0.0, [], [],
        promotionList: autoApplyPromotionList, manualPromo: cart.selectedPromotion, taxList: taxRateList, dining_name: cart.selectedOption);
    if (cart.cartNotifierPayment.isNotEmpty) {
      cart.cartNotifierPayment.clear();
      cart.addPaymentDetail(value);
    } else {
      cart.addPaymentDetail(value);
    }
  }

  checkCartItem(CartModel cart) {
    for (int i = 0; i < cart.cartNotifierItem.length; i++) {
      if (cart.cartNotifierItem[i].status == 0) {
        hasNewItem = true;
      } else {
        hasNewItem = false;
      }
    }
  }

  readAllPrinters() async {
    printerList = await printReceipt.readAllPrinters();
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
    if (object.modifier != null) {
      var length = object.modifier!.length;
      for (int i = 0; i < length; i++) {
        ModifierGroup group = object.modifier![i];
        var length = group.modifierChild!.length;
        for (int j = 0; j < length; j++) {
          if (group.modifierChild![j].isChecked!) {
            modifier.add(group.modifierChild![j].name! + '\n');
            result = modifier.toString().replaceAll('[', '').replaceAll(']', '').replaceAll(',', '+').replaceFirst('', '+ ');
          }
        }
      }
    } else {
      if (object.orderModifierDetail != null && object.orderModifierDetail!.isNotEmpty) {
        for (int i = 0; i < object.orderModifierDetail!.length; i++) {
          modifier.add(object.orderModifierDetail![i].mod_name! + '\n');
          result = modifier.toString().replaceAll('[', '').replaceAll(']', '').replaceAll(',', '+').replaceFirst('', '+ ');
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
    if (object.variant != null) {
      var length = object.variant!.length;
      for (int i = 0; i < length; i++) {
        VariantGroup group = object.variant![i];
        for (int j = 0; j < group.child!.length; j++) {
          if (group.child![j].isSelected!) {
            variant.add(group.child![j].name! + '\n');
            result = variant.toString().replaceAll('[', '').replaceAll(']', '').replaceAll(',', '+').replaceAll('|', '\n+').replaceFirst('', '+ ');
          }
        }
      }
    } else {
      if (object.productVariantName != null && object.productVariantName != '') {
        result = object.productVariantName!.replaceAll('|', '\n+').replaceFirst('', '+ ') + "\n";
      }
    }
    return result;
  }

  getVariant2(cartProductItem object) {
    List<String?> variant = [];
    String result = '';
    var length = object.variant!.length;
    for (int i = 0; i < length; i++) {
      VariantGroup group = object.variant![i];
      for (int j = 0; j < group.child!.length; j++) {
        if (group.child![j].isSelected!) {
          variant.add(group.child![j].name!);
          result = variant.toString().replaceAll('[', '').replaceAll(']', '').replaceAll(",", " |");
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
      result = '**' + object.remark.toString();
    }
    return result;
  }

/*
  Get Selected table
*/
  getSelectedTable(CartModel cart, AppSettingModel appSettingModel) {
    List<String> result = [];
    String? orderQueue = '';
    for (int i = 0; i < cart.cartNotifierItem.length; i++) {
      if (cart.cartNotifierItem[i].order_queue != '') orderQueue = cart.cartNotifierItem[i].order_queue;
    }

    if (cart.selectedTable.isEmpty && cart.selectedOption == 'Dine in') {
      result.add('-');
    } else if (cart.selectedOption != 'Dine in') {
      result.add('-');
    } else {
      if (cart.selectedTable.length > 1) {
        for (int i = 0; i < cart.selectedTable.length; i++) {
          result.add('${cart.selectedTable[i].number}');
        }
      } else {
        result.add('${cart.selectedTable[0].number}');
      }
    }

    if (result[0] == '-') {
      if (orderQueue != '') {
        result.clear();
        result.add(AppLocalizations.of(context)!.translate('order') + ': ${orderQueue}');
        return result[0];
      }
    }
    result[0] = AppLocalizations.of(context)!.translate('table') + ': ${result.toString().replaceAll('[', '').replaceAll(']', '')}';
    return result[0];
  }

/*
  -----------------Calculation-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
*/
  calPromotion(CartModel cart) async {
    // check if it is a split payment
    promoAmount = 0.0;
    if(orderKey != '' && cart.cartNotifierItem.isNotEmpty) {
      List<OrderPromotionDetail> promotionData = await PosDatabase.instance.readSpecificOrderPromotionDetailByOrderKey(orderKey);
      // check if promotion apply
      if(promotionData.isNotEmpty && cart.selectedPromotion == null) {
        for(int i = 0 ; i < promotionData.length; i++ ) {
          for(int j = 0 ; j < promotionList.length; j++) {
            if(promotionList[j].promotion_id == int.parse(promotionData[i].promotion_id!)) {
              if(promotionList[j].auto_apply == '0') {
                cart.addPromotion(promotionList[j]);
              }
            }
          }
        }
      }
    }

    getAutoApplyPromotion(cart);
    getManualApplyPromotion(cart);
    // if (!controller.isClosed) {
    //   controller.sink.add('refresh');
    // }
  }

  getManualApplyPromotion(CartModel cart) {
    List<cartProductItem> _sameCategoryList = [];
    allPromo = '';
    selectedPromoRate = '';
    double rate = 0.0;
    try {
      if (cart.selectedPromotion != null) {
        allPromo = cart.selectedPromotion!.name!;
        if (cart.selectedPromotion!.type == 0) {
          selectedPromoRate = cart.selectedPromotion!.amount.toString() + '%';
          rate = double.parse(cart.selectedPromotion!.amount!) / 100;
          cart.selectedPromotion!.promoRate = selectedPromoRate;
        } else {
          selectedPromoRate = double.parse(cart.selectedPromotion!.amount!).toStringAsFixed(2);
          rate = double.parse(cart.selectedPromotion!.amount!);
          cart.selectedPromotion!.promoRate = selectedPromoRate;
        }

        if (cart.selectedPromotion!.specific_category == '1') {
          for (int i = 0; i < cart.cartNotifierItem.length; i++) {
            if (cart.cartNotifierItem[i].category_id == cart.selectedPromotion!.category_id) {
              _sameCategoryList.add(cart.cartNotifierItem[i]);
            }
          }
          specificCategoryAmount(cart.selectedPromotion!, _sameCategoryList, cart);
        } else {
          nonSpecificCategoryAmount(cart, rate);
        }
      }
    } catch (error) {
      print('Get manual promotion error: $error');
    }
    if (!controller.isClosed) {
      controller.sink.add('refresh');
    }
  }

  specificCategoryAmount(Promotion promotion, List<cartProductItem> cartItem, CartModel cart) {
    try {
      selectedPromo = 0.0;
      hasSelectedPromo = false;

      for (int j = 0; j < cartItem.length; j++) {
        if (promotion.type == 0) {
          hasSelectedPromo = true;
          selectedPromo += (double.parse(cartItem[j].price!) * cartItem[j].quantity!) * (double.parse(promotion.amount!) / 100);
          cart.selectedPromotion!.promoAmount = selectedPromo;
        } else {
          hasSelectedPromo = true;
          selectedPromo += (double.parse(promotion.amount!) * cartItem[j].quantity!);
          cart.selectedPromotion!.promoAmount = selectedPromo;
        }
      }
      promoAmount += selectedPromo;
    } catch (e) {
      print('Specific category offer amount error: $e');
      selectedPromo = 0.0;
    }
    controller.add('refresh');
  }

  nonSpecificCategoryAmount(CartModel cart, double rate) {
    try {
      selectedPromo = 0.0;
      hasSelectedPromo = false;

      if (cart.selectedPromotion!.type == 0) {
        hasSelectedPromo = true;
        selectedPromo = double.parse((total * rate).toStringAsFixed(2));
      } else {
        if (cart.cartNotifierItem.isNotEmpty) {
          for (int i = 0; i < cart.cartNotifierItem.length; i++) {
            hasSelectedPromo = true;
            selectedPromo = double.parse(cart.selectedPromotion!.amount!);
            cart.selectedPromotion!.promoAmount = selectedPromo;
          }
        }
      }
      promoAmount += selectedPromo;
      print('promotion amount: ${promoAmount}');
      cart.selectedPromotion!.promoAmount = selectedPromo;
    } catch (error) {
      print('check promotion type error: $error');
      selectedPromo = 0.0;
    }
    controller.add('refresh');
  }

  promotionDateTimeChecking({
    cache_created_at,
    sDate,
    eDate,
    sTime,
    eTime,
  }) {
    // String stime = "20:00";
    // String etime = '22:19';
    DateTime currentDateTime = DateTime.now();
    bool inTime = false;

    try {
      if (cache_created_at == null) {
        if (sDate != null && eDate != null && sTime != null && eTime != null) {
          //parse date
          DateTime parsedStartDate = DateTime.parse(sDate);
          DateTime parsedEndDate = DateTime.parse(eDate);
          //parse time
          DateTime startTime = new DateFormat("HH:mm").parse(sTime);
          DateTime endTime = new DateFormat("HH:mm").parse(eTime);
          TimeOfDay parsedStartTime = TimeOfDay.fromDateTime(startTime);
          TimeOfDay parsedEndTime = TimeOfDay.fromDateTime(endTime);

          //compare date
          int startDateComparison = currentDateTime.compareTo(parsedStartDate);
          int endDateComparison = currentDateTime.compareTo(parsedEndDate);

          //compare start time
          int startTimeComparison = currentDateTime.hour.compareTo(parsedStartTime.hour);
          if (startTimeComparison == 0) {
            startTimeComparison = currentDateTime.minute.compareTo(parsedStartTime.minute);
          }
          //compare end time
          int endTimeComparison = currentDateTime.hour.compareTo(parsedEndTime.hour);
          if (endTimeComparison == 0) {
            endTimeComparison = currentDateTime.minute.compareTo(parsedEndTime.minute);
          }

          //combine two comparison
          if (startDateComparison >= 0 && endDateComparison <= 0) {
            if (startTimeComparison >= 0 && endTimeComparison <= 0) {
              inTime = true;
            } else {
              inTime = false;
            }
          } else {
            inTime = false;
          }
        } else if (sDate != null && eDate != null) {
          DateTime parsedStartDate = DateTime.parse(sDate);
          DateTime parsedEndDate = DateTime.parse(eDate);

          int startDateComparison = currentDateTime.compareTo(parsedStartDate);
          int endDateComparison = currentDateTime.compareTo(parsedEndDate);

          if (startDateComparison >= 0 && endDateComparison <= 0) {
            inTime = true;
          } else {
            inTime = false;
          }
        } else if (sTime != null && eTime != null) {
          DateTime startTime = new DateFormat("HH:mm").parse(sTime);
          DateTime endTime = new DateFormat("HH:mm").parse(eTime);

          TimeOfDay parsedStartTime = TimeOfDay.fromDateTime(startTime);
          TimeOfDay parsedEndTime = TimeOfDay.fromDateTime(endTime);
          //compare start time
          int startTimeComparison = currentDateTime.hour.compareTo(parsedStartTime.hour);
          if (startTimeComparison == 0) {
            startTimeComparison = currentDateTime.minute.compareTo(parsedStartTime.minute);
          }
          //compare end time
          int endTimeComparison = currentDateTime.hour.compareTo(parsedEndTime.hour);
          if (endTimeComparison == 0) {
            endTimeComparison = currentDateTime.minute.compareTo(parsedEndTime.minute);
          }
          //combine two comparison
          if (startTimeComparison >= 0 && endTimeComparison <= 0) {
            inTime = true;
          } else {
            inTime = false;
          }
        }
      } else {
        //compare with order cache created date time
        if (sDate != null && eDate != null && sTime != null && eTime != null) {
          //parse date
          DateTime parsedCacheDate = DateTime.parse(cache_created_at);
          DateTime parsedStartDate = DateTime.parse(sDate);
          DateTime parsedEndDate = DateTime.parse(eDate);
          //format time
          String formatDate = new DateFormat("HH:mm").format(parsedCacheDate);
          //parse time
          DateTime cacheTime = new DateFormat("HH:mm").parse(formatDate);
          DateTime startTime = new DateFormat("HH:mm").parse(sTime);
          DateTime endTime = new DateFormat("HH:mm").parse(eTime);
          TimeOfDay parsedCacheTime = TimeOfDay.fromDateTime(cacheTime);
          TimeOfDay parsedStartTime = TimeOfDay.fromDateTime(startTime);
          TimeOfDay parsedEndTime = TimeOfDay.fromDateTime(endTime);
          //compare date
          int startDateComparison = parsedCacheDate.compareTo(parsedStartDate);
          int endDateComparison = parsedCacheDate.compareTo(parsedEndDate);

          //compare start time
          int startTimeComparison = parsedCacheTime.hour.compareTo(parsedStartTime.hour);
          if (startTimeComparison == 0) {
            startTimeComparison = parsedCacheTime.minute.compareTo(parsedStartTime.minute);
          }
          //compare end time
          int endTimeComparison = parsedCacheTime.hour.compareTo(parsedEndTime.hour);
          if (endTimeComparison == 0) {
            endTimeComparison = parsedCacheTime.minute.compareTo(parsedEndTime.minute);
          }
          //combine two comparison
          if (startDateComparison >= 0 && endDateComparison <= 0) {
            if (startTimeComparison >= 0 && endTimeComparison <= 0) {
              inTime = true;
            } else {
              inTime = false;
            }
          } else {
            inTime = false;
          }
        } else if (sDate != null && eDate != null) {
          DateTime parsedCacheDate = DateTime.parse(cache_created_at);
          DateTime parsedStartDate = DateTime.parse(sDate);
          DateTime parsedEndDate = DateTime.parse(eDate);

          int startDateComparison = parsedCacheDate.compareTo(parsedStartDate);
          int endDateComparison = parsedCacheDate.compareTo(parsedEndDate);

          if (startDateComparison >= 0 && endDateComparison <= 0) {
            inTime = true;
          } else {
            inTime = false;
          }
        } else if (sTime != null && eTime != null) {
          DateTime cacheDate = DateTime.parse(cache_created_at);

          String formatDate = new DateFormat("HH:mm").format(cacheDate);

          DateTime cacheTime = new DateFormat("HH:mm").parse(formatDate);
          DateTime startTime = new DateFormat("HH:mm").parse(sTime);
          DateTime endTime = new DateFormat("HH:mm").parse(eTime);

          TimeOfDay parsedCacheTime = TimeOfDay.fromDateTime(cacheTime);
          TimeOfDay parsedStartTime = TimeOfDay.fromDateTime(startTime);
          TimeOfDay parsedEndTime = TimeOfDay.fromDateTime(endTime);
          //compare start time
          int startTimeComparison = parsedCacheTime.hour.compareTo(parsedStartTime.hour);
          if (startTimeComparison == 0) {
            startTimeComparison = parsedCacheTime.minute.compareTo(parsedStartTime.minute);
          }
          //compare end time
          int endTimeComparison = parsedCacheTime.hour.compareTo(parsedEndTime.hour);
          if (endTimeComparison == 0) {
            endTimeComparison = parsedCacheTime.minute.compareTo(parsedEndTime.minute);
          }
          //combine two comparison
          if (startTimeComparison >= 0 && endTimeComparison <= 0) {
            inTime = true;
          } else {
            inTime = false;
          }
        }
      }
      return inTime;
    } catch (e) {
      print('error caught:$e');
      return;
    }
  }

  getAutoApplyPromotion(CartModel cart) {
    print("getAutoApplyPromotion called");
    try {
      // cart.removeAutoPromotion();
      cart.autoPromotion = [];

      autoApplyPromotionList = [];
      promoName = '';
      hasPromo = false;
      if (cart.cartNotifierItem.isNotEmpty) {
        //loop promotion list get promotion
        for (int j = 0; j < promotionList.length; j++) {
          promotionList[j].promoAmount = 0.0;
          //check is the promotion auto apply
          if (promotionList[j].auto_apply == '1') {
            //check is promotion all day & all time
            if (promotionList[j].all_day == '1' && promotionList[j].all_time == '1') {
              if (promotionList[j].specific_category == '1') {
                //Auto apply specific category promotion
                for (int m = 0; m < cart.cartNotifierItem.length; m++) {
                  if (cart.cartNotifierItem[m].category_id == promotionList[j].category_id) {
                    hasPromo = true;
                    promoName = promotionList[j].name!;
                    if (!autoApplyPromotionList.contains(promotionList[j])) {
                      autoApplyPromotionList.add(promotionList[j]);
                      if (widget.currentPage != 'menu') {
                        // cart.addAutoApplyPromo(promotionList[j]);
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
                    // cart.addAutoApplyPromo(promotionList[j]);
                  }
                  promoName = promotionList[j].name!;
                  autoApplyNonSpecificCategoryAmount(promotionList[j], cart);
                }
              }
            } else {
              if (promotionList[j].all_day == '0' && promotionList[j].all_time == '0') {
                if (cart.cartNotifierItem[0].status == 0) {
                  if (promotionDateTimeChecking(sDate: promotionList[j].sdate, eDate: promotionList[j].edate, sTime: promotionList[j].stime, eTime: promotionList[j].etime) ==
                      true) {
                    if (promotionList[j].specific_category == '1') {
                      //Auto apply specific category promotion
                      for (int m = 0; m < cart.cartNotifierItem.length; m++) {
                        if (cart.cartNotifierItem[m].category_id == promotionList[j].category_id) {
                          hasPromo = true;
                          promoName = promotionList[j].name!;
                          if (!autoApplyPromotionList.contains(promotionList[j])) {
                            autoApplyPromotionList.add(promotionList[j]);
                            if (widget.currentPage != 'menu') {
                              // cart.addAutoApplyPromo(promotionList[j]);
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
                          // cart.addAutoApplyPromo(promotionList[j]);
                        }
                        promoName = promotionList[j].name!;
                        autoApplyNonSpecificCategoryAmount(promotionList[j], cart);
                      }
                    }
                  }
                } else {
                  if (promotionDateTimeChecking(
                      sDate: promotionList[j].sdate,
                      eDate: promotionList[j].edate,
                      sTime: promotionList[j].stime,
                      eTime: promotionList[j].etime,
                      cache_created_at: cart.cartNotifierItem[0].first_cache_created_date_time) ==
                      true) {
                    if (promotionList[j].specific_category == '1') {
                      //Auto apply specific category promotion
                      for (int m = 0; m < cart.cartNotifierItem.length; m++) {
                        if (cart.cartNotifierItem[m].category_id == promotionList[j].category_id) {
                          hasPromo = true;
                          promoName = promotionList[j].name!;
                          if (!autoApplyPromotionList.contains(promotionList[j])) {
                            autoApplyPromotionList.add(promotionList[j]);
                            if (widget.currentPage != 'menu') {
                              // cart.addAutoApplyPromo(promotionList[j]);
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
                          // cart.addAutoApplyPromo(promotionList[j]);
                        }
                        promoName = promotionList[j].name!;
                        autoApplyNonSpecificCategoryAmount(promotionList[j], cart);
                      }
                    }
                  }
                }
              } else if (promotionList[j].all_day == '0' && promotionList[j].all_time == '1') {
                //check cart item status and promotion time
                if (cart.cartNotifierItem[0].status == 0) {
                  if (promotionDateTimeChecking(sDate: promotionList[j].sdate, eDate: promotionList[j].edate) == true) {
                    if (promotionList[j].specific_category == '1') {
                      //Auto apply specific category promotion
                      for (int m = 0; m < cart.cartNotifierItem.length; m++) {
                        if (cart.cartNotifierItem[m].category_id == promotionList[j].category_id) {
                          hasPromo = true;
                          promoName = promotionList[j].name!;
                          if (!autoApplyPromotionList.contains(promotionList[j])) {
                            autoApplyPromotionList.add(promotionList[j]);
                            if (widget.currentPage != 'menu') {
                              // cart.addAutoApplyPromo(promotionList[j]);
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
                          // cart.addAutoApplyPromo(promotionList[j]);
                        }
                        promoName = promotionList[j].name!;
                        autoApplyNonSpecificCategoryAmount(promotionList[j], cart);
                      }
                    }
                  }
                } else {
                  if (promotionDateTimeChecking(
                      sDate: promotionList[j].sdate, eDate: promotionList[j].edate, cache_created_at: cart.cartNotifierItem[0].first_cache_created_date_time) ==
                      true) {
                    if (promotionList[j].specific_category == '1') {
                      //Auto apply specific category promotion
                      for (int m = 0; m < cart.cartNotifierItem.length; m++) {
                        if (cart.cartNotifierItem[m].category_id == promotionList[j].category_id) {
                          hasPromo = true;
                          promoName = promotionList[j].name!;
                          if (!autoApplyPromotionList.contains(promotionList[j])) {
                            autoApplyPromotionList.add(promotionList[j]);
                            if (widget.currentPage != 'menu') {
                              // cart.addAutoApplyPromo(promotionList[j]);
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
                          // cart.addAutoApplyPromo(promotionList[j]);
                        }
                        promoName = promotionList[j].name!;
                        autoApplyNonSpecificCategoryAmount(promotionList[j], cart);
                      }
                    }
                  }
                }
              } else if (promotionList[j].all_time == '0' && promotionList[j].all_day == '1') {
                //check cart item status and promotion time
                if (cart.cartNotifierItem[0].status == 0) {
                  if (promotionDateTimeChecking(sTime: promotionList[j].stime, eTime: promotionList[j].etime) == true) {
                    if (promotionList[j].specific_category == '1') {
                      //Auto apply specific category promotion
                      for (int m = 0; m < cart.cartNotifierItem.length; m++) {
                        if (cart.cartNotifierItem[m].category_id == promotionList[j].category_id) {
                          hasPromo = true;
                          promoName = promotionList[j].name!;
                          if (!autoApplyPromotionList.contains(promotionList[j])) {
                            autoApplyPromotionList.add(promotionList[j]);
                            if (widget.currentPage != 'menu') {
                              // cart.addAutoApplyPromo(promotionList[j]);
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
                          // cart.addAutoApplyPromo(promotionList[j]);
                        }
                        promoName = promotionList[j].name!;
                        autoApplyNonSpecificCategoryAmount(promotionList[j], cart);
                      }
                    }
                  }
                } else {
                  if (promotionDateTimeChecking(
                      sTime: promotionList[j].stime, eTime: promotionList[j].etime, cache_created_at: cart.cartNotifierItem[0].first_cache_created_date_time) ==
                      true) {
                    if (promotionList[j].specific_category == '1') {
                      //Auto apply specific category promotion
                      for (int m = 0; m < cart.cartNotifierItem.length; m++) {
                        if (cart.cartNotifierItem[m].category_id == promotionList[j].category_id) {
                          hasPromo = true;
                          promoName = promotionList[j].name!;
                          if (!autoApplyPromotionList.contains(promotionList[j])) {
                            autoApplyPromotionList.add(promotionList[j]);
                            if (widget.currentPage != 'menu') {
                              // cart.addAutoApplyPromo(promotionList[j]);
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
                          // cart.addAutoApplyPromo(promotionList[j]);
                        }
                        promoName = promotionList[j].name!;
                        autoApplyNonSpecificCategoryAmount(promotionList[j], cart);
                      }
                    }
                  }
                }
              }
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
          promo += (double.parse(promotion.amount!) * cart.cartNotifierItem[i].quantity!);
          promotion.promoAmount = promo;
          promoRate = 'RM' + promotion.amount!;
          promotion.promoRate = promoRate;
        } else {
          promo += (double.parse(cart.cartNotifierItem[i].price!) * cart.cartNotifierItem[i].quantity!) * (double.parse(promotion.amount!) / 100);
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
        promo += (double.parse(promotion.amount!) * cartItem.quantity!);
        promotion.promoAmount = promotion.promoAmount! + promo;
        promoRate = 'RM' + promotion.amount!;
        promotion.promoRate = promoRate;
      } else {
        promo += (double.parse(cartItem.price!) * cartItem.quantity!) * (double.parse(promotion.amount!) / 100);
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
    try {
      //get dining option data
      List<DiningOption> data = await PosDatabase.instance.checkSelectedOption(cart.selectedOption);
      if (data.isNotEmpty) {
        diningOptionID = data[0].dining_id!;

        //get dining tax
        List<Tax> taxData = await PosDatabase.instance.readTax(diningOptionID.toString());
        //print("tax data length: ${taxData.length}");
        if (taxData.isNotEmpty) {
          taxRateList = List.from(taxData);
        } else {
          taxRateList = [];
        }
      }
    } catch (error) {
      print('get dining tax in cart error: $error');
    }
    // if (!controller.isClosed) {
    //   controller.sink.add('refresh');
    // }
  }

/*
  receipt menu initial call
*/
  getReceiptPaymentDetail(CartModel cart) async {
    this.total = 0.0;
    this.totalAmount = 0.0;
    this.rounding = 0.0;
    this.finalAmount = '0.00';
    this.paymentReceived = 0.0;
    this.paymentChange = 0.0;
    this.orderTaxList = [];
    this.orderPromotionList = [];
    autoApplyPromotionList = [];
    this.localOrderId = '';

    for (int i = 0; i < cart.cartNotifierPayment.length; i++) {
      List<Order> orderData = [];
      orderData = await PosDatabase.instance.readSpecificPaidOrder(cart.cartNotifierPayment[i].localOrderId);
      // refund order
      if(orderData.length == 0) {
        orderData = await PosDatabase.instance.readSpecificRefundedOrder(cart.cartNotifierPayment[i].localOrderId);
      }
      if(orderData.length != 0) {
        this.orderKey = orderData[0].order_key!;
      }
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
    await getAllPaymentSplit(cart);
    if (!controller.isClosed) {
      controller.sink.add('refresh');
    }
  }

/*
  Cart Ordering initial called
*/
  getSubTotal(CartModel cart) async {
    print("getSubTotal");
    // await Future.delayed(Duration(milliseconds: 6000));
    try {
      // widget.currentPage == 'table' || widget.currentPage == 'qr_order'
      //     ? cart.selectedOption = 'Dine in'
      //     : null;
      total = 0.0;
      newOrderSubtotal = 0.0;
      paymentSplitAmount = 0.0;
      promo = 0.0;
      promoAmount = 0.0;
      orderKey = '';
      for (int i = 0; i < cart.cartNotifierItem.length; i++) {
        total += (double.parse((cart.cartNotifierItem[i].price!)) * cart.cartNotifierItem[i].quantity!);
        if (cart.cartNotifierItem[i].status == 0) {
          newOrderSubtotal += (double.parse((cart.cartNotifierItem[i].price!)) * cart.cartNotifierItem[i].quantity!);
        }
        if(cart.cartNotifierItem[i].order_key != null && cart.cartNotifierItem[i].order_key != '') {
          orderKey = cart.cartNotifierItem[i].order_key!;
        } else {
          orderKey = '';
        }
      }
    } catch (e) {
      print('Sub Total Error: $e');
      total = 0.0;
    }
    await getDiningTax(cart);
    await calPromotion(cart);
    getTaxAmount();
    getRounding();
    await getAllPaymentSplit(cart);
    getAllTotal();
    checkCartItem(cart);
    print("cart scroll down: ${cart.scrollDown }");
    if (cart.scrollDown == 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        setState(() {
          _scrollDown();
        });
      });
      cart.setScrollDown = 1;
    }
    if((widget.currentPage == 'table' || widget.currentPage == 'other_order') && cart.cartNotifierItem.isNotEmpty)
      isButtonDisabled = false;
    if(cart.cartNotifierItem.isNotEmpty){
      reInitSecondDisplay(cartEmpty: false, cart: cart);
    } else {
      reInitSecondDisplay(cartEmpty: true);
    }
    if (!controller.isClosed) {
      controller.sink.add('refresh');
      print("refresh called");
    }
  }

  reInitSecondDisplay({required bool cartEmpty, CartModel? cart}) async {
    if (notificationModel.hasSecondScreen == true && notificationModel.secondScreenEnable == true) {
      if(cartEmpty){
        await displayManager.transferDataToPresentation("init");
      } else {
        if(cart != null){
          SecondDisplayData data = SecondDisplayData(
              tableNo: cart.selectedTable.isEmpty ? null : cart.selectedTable.map((e) => e.number).toList().toString().replaceAll('[', '').replaceAll(']', ''),
              itemList: cart.cartNotifierItem,
              subtotal: cart.cartSubTotal.toStringAsFixed(2),
              totalDiscount: promoAmount.toStringAsFixed(2),
              totalTax: priceIncAllTaxes.toStringAsFixed(2),
              rounding: rounding.toStringAsFixed(2),
              finalAmount: finalAmount,
              selectedOption: cart.selectedOption
          );
          await displayManager.transferDataToPresentation(jsonEncode(data));
        }
      }
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
    // if (!controller.isClosed) {
    //   controller.sink.add('refresh');
    // }
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
    getAllTaxAmount();
    double _round = 0.0;
    totalAmount = 0.0;
    discountPrice = total - promoAmount;
    totalAmount = discountPrice + priceIncAllTaxes;
    _round = Utils.roundToNearestFiveSen(double.parse(totalAmount.toStringAsFixed(2))) - double.parse(totalAmount.toStringAsFixed(2));
    rounding = _round;

    // if (!controller.isClosed) {
    //   controller.sink.add('refresh');
    // }
  }

  getAllTotal() {
    try {
      finalAmount = Utils.roundToNearestFiveSen(double.parse((totalAmount-paymentSplitAmount).toStringAsFixed(2))).toStringAsFixed(2);
    } catch (error) {
      print('Total calc error: $error');
    }

    // if (!controller.isClosed) {
    //   controller.sink.add('refresh');
    // }
  }

  getAllPaymentSplit(CartModel cart) async {
    try {
      paymentSplitList = [];
      paymentSplitAmount = 0.0;
      print("Cart item: ${cart.cartNotifierItem.length}");
      if(cart.cartNotifierItem.length != 0) {
        if(orderKey != '') {
          List<OrderPaymentSplit> orderSplit = await PosDatabase.instance.readSpecificOrderSplitByOrderKey(orderKey);
          for(int k = 0; k < orderSplit.length; k++){
            paymentSplitAmount += double.parse(orderSplit[k].amount!);
            paymentSplitList.add(orderSplit[k]);
          }
        }
      }
    } catch(e) {
      print("Total payment split: $e");
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
                orderKey: orderKey,
                parentContext: this.widget.parentContext!,
                currentPage: this.widget.currentPage,
              ),
            ),
          );
        },
        transitionDuration: Duration(milliseconds: 200),
        barrierDismissible: true,
        barrierLabel: 'Dismiss',
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
                callBack: (cart) {},
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
              child: PromotionDialog(
                cartFinalAmount: finalAmount,
                subtotal: newOrderSubtotal.toString(),
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

  Future<Future<Object?>> openRemoveCartItemDialog(cartProductItem item, String currentPage) async {
    return showGeneralDialog(
        barrierColor: Colors.black.withOpacity(0.5),
        transitionBuilder: (context, a1, a2, widget) {
          final curvedValue = Curves.easeInOutBack.transform(a1.value) - 1.0;
          return Transform(
            transform: Matrix4.translationValues(0.0, curvedValue * 200, 0.0),
            child: Opacity(
              opacity: a1.value,
              child: currentPage == 'menu' ?
              CartRemoveDialog(
                cartItem: item,
                currentPage: currentPage,
              ) :
              AdjustQuantityDialog(cartItem: item, currentPage: currentPage)
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

  Future<Future<Object?>> openAdjustPriceDialog(CartModel cart, cartProductItem item, String currentPage, int index) async {
    return showGeneralDialog(
        barrierColor: Colors.black.withOpacity(0.5),
        transitionBuilder: (context, a1, a2, widget) {
          final curvedValue = Curves.easeInOutBack.transform(a1.value) - 1.0;
          return Transform(
            transform: Matrix4.translationValues(0.0, curvedValue * 200, 0.0),
            child: Opacity(
              opacity: a1.value,
              child: AdjustPriceDialog(
                cart: cart,
                cartItem: item,
                index: index,
                currentPage: currentPage,
                callBack: (cartProductItem object) {
                  cart.refresh();
                },
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
            child: Opacity(opacity: a1.value, child: WillPopScope(child: LoadingDialog(isTableMenu: false), onWillPop: () async => false)),
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

  openPaymentSelect(CartModel cart) async {
    return showGeneralDialog(
        barrierColor: Colors.black.withOpacity(0.5),
        transitionBuilder: (context, a1, a2, widget) {
          final curvedValue = Curves.easeInOutBack.transform(a1.value) - 1.0;
          return Transform(
            transform: Matrix4.translationValues(0.0, curvedValue * 200, 0.0),
            child: Opacity(
              opacity: a1.value,
              child: PaymentSelect(
                  dining_id: diningOptionID.toString(),
                  dining_name: cart.selectedOption,
                  order_key: orderKey,
                  callBack: (orderKeyValue) async {

                    if(orderKeyValue != '') {
                      cart.cartNotifierItem.forEach((element) {
                        element.order_key = orderKeyValue;
                      });
                      await getSubTotal(cart);
                      await paymentAddToCart(cart);
                      print("final amount: $finalAmount");
                    } else {
                      cart.removeAllCartItem();
                      cart.removeAllTable();
                      cart.removeAllGroupList();
                    }

                  }),
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

  Future<Future<Object?>> openLogOutDialog() async {
    return showGeneralDialog(
        barrierColor: Colors.black.withOpacity(0.5),
        transitionBuilder: (context, a1, a2, widget) {
          final curvedValue = Curves.easeInOutBack.transform(a1.value) - 1.0;
          return Transform(
            transform: Matrix4.translationValues(0.0, curvedValue * 200, 0.0),
            child: Opacity(
              opacity: a1.value,
              child: LogoutConfirmDialog(),
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

  openReprintKitchenDialog() async {
    return showGeneralDialog(
        barrierColor: Colors.black.withOpacity(0.5),
        transitionBuilder: (context, a1, a2, widget) {
          final curvedValue = Curves.easeInOutBack.transform(a1.value) - 1.0;
          return Transform(
            transform: Matrix4.translationValues(0.0, curvedValue * 200, 0.0),
            child: Opacity(
              opacity: a1.value,
              child: ReprintKitchenListDialog(printerList: printerList, callback: openReprintKitchenDialog),
            ),
          );
        },
        transitionDuration: Duration(milliseconds: 200),
        barrierDismissible: false,
        context: widget.parentContext!,
        pageBuilder: (context, animation1, animation2) {
          // ignore: null_check_always_fails
          return null!;
        });
  }

  checkCashRecord() async {
    List<CashRecord> data = await PosDatabase.instance.readBranchCashRecord();
    if (data.length <= 0) {
      _isSettlement = true;
    } else {
      _isSettlement = false;
    }
  }

  readAllBranchLinkDiningOption({serverCall, cart}) async {
    final prefs = await SharedPreferences.getInstance();
    final int? branch_id = prefs.getInt('branch_id');
    List<BranchLinkDining> data = await PosDatabase.instance.readBranchLinkDiningOption(branch_id!.toString());

    diningList.clear();
    branchLinkDiningIdList.clear();

    for (int i = 0; i < data.length; i++) {
      diningList.add(data[i]);
      branchLinkDiningIdList.add(data[i].dining_id!);
    }
    if (serverCall == null) {
      if(cart.selectedOptionId == '') {
        if (data.any((item) => item.name == 'Dine in')) {
          cart.selectedOption = 'Dine in';
        } else {
          cart.selectedOption = "Take Away";
        }
        if (!controller.isClosed) {
          controller.sink.add('refresh');
        }
      }
    }
    //cart.selectedOption = diningList.first.name;
    lastDiningOption = true;
  }

  getPromotionData({serverCall}) async {
    promotionList.clear();
    try {
      List<BranchLinkPromotion> data = await PosDatabase.instance.readBranchLinkPromotion();
      for (int i = 0; i < data.length; i++) {
        List<Promotion> temp = await PosDatabase.instance.checkPromotion(data[i].promotion_id!);
        if (temp.isNotEmpty) promotionList.add(temp[0]);
      }
    } catch (error) {
      print('promotion list error $error');
    }
  }

  resetValue() {
    this.table_use_value = [].toString();
    this.table_use_detail_value = [].toString();
    this.order_cache_value = [].toString();
    this.order_detail_value = [].toString();
    this.order_modifier_detail_value = [].toString();
    this.branch_link_product_value = [].toString();
    this.table_value = [].toString();
  }

  Future<bool> checkTableStatus(CartModel cart) async {
    bool tableInUse = false;
    for(int i = 0; i < cart.selectedTable.length; i++){
      List<PosTable> table = await PosDatabase.instance.checkPosTableStatus(cart.selectedTable[i].table_sqlite_id!);
      if(table[0].status == 1){
        tableInUse = true;
        break;
      }
    }
    return tableInUse;
  }

/*
  dine in call
*/
  callCreateNewOrder(CartModel cart, AppSettingModel appSettingModel) async {
    try{
      resetValue();
      final prefs = await SharedPreferences.getInstance();
      final int? branch_id = prefs.getInt('branch_id');
      AppSetting? localSetting = await PosDatabase.instance.readLocalAppSetting(branch_id.toString());

      if(await checkTableStatus(cart) == false){
        await createTableUseID();
        await createTableUseDetail(cart);
        await createOrderCache(cart, isAddOrder: false);
        await createOrderDetail(cart);

        if(cart.selectedOption == 'Dine in' && localSetting!.table_order == 1) {
          await updatePosTable(cart);
        }
        if (_appSettingModel.autoPrintChecklist == true) {
          int printStatus = await printReceipt.printCheckList(printerList, int.parse(this.orderCacheId));
          if (printStatus == 1) {
            Fluttertoast.showToast(backgroundColor: Colors.red, msg: "${AppLocalizations.of(context)?.translate('printer_not_connected')}");
          } else if (printStatus == 2) {
            Fluttertoast.showToast(backgroundColor: Colors.orangeAccent, msg: "${AppLocalizations.of(context)?.translate('printer_connection_timeout')}");
          } else if (printStatus == 5) {
            Fluttertoast.showToast(backgroundColor: Colors.red, msg: AppLocalizations.of(context)!.translate('printing_error'));
          }
        }
        List<cartProductItem> ticketProduct = cart.cartNotifierItem.where((e) => e.allow_ticket == 1).toList();
        if(ticketProduct.isNotEmpty){
          asyncQ.addJob((_) => printReceipt.printProductTicket(printerList, int.parse(this.orderCacheId), ticketProduct));
          // printReceipt.printProductTicket(printerList, int.parse(this.orderCacheId), ticketProduct);
        }

        if(appSettingModel.table_order == 2) {
          Navigator.of(context).pop();
          await checkDirectPayment(appSettingModel, cart);
        } else {
          cart.removeAllCartItem();
          cart.removeAllTable();
          Navigator.of(context).pop();
        }
        //syncAllToCloud();
        // print('finish sync');
        // if (this.isLogOut == true) {
        //   openLogOutDialog();
        //   return;
        // }
        asyncQ.addJob((_) => printKitchenList());
        isCartExpanded = !isCartExpanded;
      } else {
        // cart.removeAllCartItem();
        // cart.removeAllTable();
        Navigator.of(context).pop();
        ShowPlaceOrderFailedToast.showToast(AppLocalizations.of(context)!.translate('table_is_used'));
      }
    }catch(e){
      FLog.error(
        className: "cart",
        text: "dine in call create new order error",
        exception: e,
      );
    }

  }

/*
  add-on call (dine in)
*/
  callAddOrderCache(CartModel cart) async {
    try{
      resetValue();
      List<cartProductItem> outOfStockItem = await checkOrderStock(cart);
      if(await checkTableStatus(cart) == true){
        if(outOfStockItem.isEmpty){
          cart.selectedTable.removeWhere((e) => e.status == 0);
          await createOrderCache(cart, isAddOrder: true);
          await createOrderDetail(cart);
          if (_appSettingModel.autoPrintChecklist == true) {
            int printStatus = await printReceipt.printCheckList(printerList, int.parse(this.orderCacheId));
            if (printStatus == 1) {
              Fluttertoast.showToast(backgroundColor: Colors.red, msg: "${AppLocalizations.of(context)?.translate('printer_not_connected')}");
            } else if (printStatus == 2) {
              Fluttertoast.showToast(backgroundColor: Colors.orangeAccent, msg: "${AppLocalizations.of(context)?.translate('printer_connection_timeout')}");
            } else if (printStatus == 5) {
              Fluttertoast.showToast(backgroundColor: Colors.red, msg: AppLocalizations.of(context)!.translate('printing_error'));
            }
          }
          List<cartProductItem> ticketProduct = cart.cartNotifierItem.where((e) => e.allow_ticket == 1 && e.status == 0).toList();
          if(ticketProduct.isNotEmpty){
            asyncQ.addJob((_) => printReceipt.printProductTicket(printerList, int.parse(this.orderCacheId), ticketProduct));
          }
          cart.removeAllCartItem();
          cart.removeAllTable();
          Navigator.of(context).pop();

          //syncAllToCloud();
          // if (this.isLogOut == true) {
          //   openLogOutDialog();
          //   return;
          // }
          asyncQ.addJob((_) => printKitchenList());
          isCartExpanded = !isCartExpanded;
        } else {
          Navigator.of(context).pop();
          showOutOfStockDialog(outOfStockItem);
        }
      } else {
        // cart.removeAllCartItem();
        // cart.removeAllTable();
        Navigator.of(context).pop();
        ShowPlaceOrderFailedToast.showToast(AppLocalizations.of(context)!.translate('table_not_in_use'));
      }
    }catch(e){
      FLog.error(
        className: "cart",
        text: "callAddOrderCache error",
        exception: e,
      );
    }
  }


/*
  Not dine in call
*/
  callCreateNewNotDineOrder(CartModel cart, AppSettingModel appSettingModel) async {
    try {
      resetValue();
      await createOrderCache(cart, isAddOrder: false);
      await createOrderDetail(cart);
      if(_appSettingModel.autoPrintChecklist == true){
        int printStatus = await printReceipt.printCheckList(printerList, int.parse(this.orderCacheId));
        if (printStatus == 1) {
          Fluttertoast.showToast(
              backgroundColor: Colors.red,
              msg: "${AppLocalizations.of(context)?.translate('printer_not_connected')}");
        } else if (printStatus == 2) {
          Fluttertoast.showToast(
              backgroundColor: Colors.orangeAccent,
              msg: "${AppLocalizations.of(context)?.translate('printer_connection_timeout')}");
        } else if (printStatus == 5) {
          Fluttertoast.showToast(backgroundColor: Colors.red, msg: AppLocalizations.of(context)!.translate('printing_error'));
        }
      }
      List<cartProductItem> ticketProduct = cart.cartNotifierItem.where((e) => e.allow_ticket == 1).toList();
      if(ticketProduct.isNotEmpty){
        asyncQ.addJob((_) => printReceipt.printProductTicket(printerList, int.parse(this.orderCacheId), ticketProduct));
      }
      Navigator.of(context).pop();
      checkDirectPayment(appSettingModel, cart);

      // syncAllToCloud();
      // if (this.isLogOut == true) {
      //   openLogOutDialog();
      //   return;
      // }
      asyncQ.addJob((_) => printKitchenList());
      isCartExpanded = !isCartExpanded;
      // printKitchenList();
    } catch(e) {
      FLog.error(
        className: "cart",
        text: "callCreateNewNotDineOrder error",
        exception: e,
      );
    }
  }

  Future<List<cartProductItem>> checkOrderStock(CartModel cartModel) async {
    List<cartProductItem> outOfStockItem = [];
    // Map<String, dynamic>? result;
    //bool hasStock = false;
    List<cartProductItem> unitCartItem = cartModel.cartNotifierItem.where((e) => e.unit == 'each' && e.status == 0).toList();
    if(unitCartItem.isNotEmpty){
      for(int i = 0 ; i < unitCartItem.length; i++){
        print("loop: $i");
        List<BranchLinkProduct> checkData = await PosDatabase.instance.readSpecificBranchLinkProduct(unitCartItem[i].branch_link_product_sqlite_id!);
        switch (checkData[0].stock_type) {
          case '1':
            {
              if(int.parse(checkData[0].daily_limit!) < unitCartItem[i].quantity!){
                outOfStockItem.add(unitCartItem[i]);
                // branchLinkProductList.add(checkData[0]);
              }
            }
            break;
          case '2':
            {
              if(int.parse(checkData[0].stock_quantity!) < unitCartItem[i].quantity!){
                outOfStockItem.add(unitCartItem[i]);
                // branchLinkProductList.add(checkData[0]);
              }
            }
            break;
        }
      }
    }
    return outOfStockItem;
  }

  Future<void> showOutOfStockDialog(List<cartProductItem> item) async {
    var screenHeight = MediaQuery.of(context).size.height;
    return showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context){
          return AlertDialog(
            title: Text(AppLocalizations.of(context)!.translate("product_out_of_stock")),
            content: Container(
              constraints: BoxConstraints(maxHeight: 400),
              width: 350,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${AppLocalizations.of(context)!.translate("total_item")}: ${item.length}'),
                    SizedBox(height: 10),
                    ListView.builder(
                      shrinkWrap: true,
                      physics: NeverScrollableScrollPhysics(),
                      itemCount: item.length,
                      itemBuilder: (context, index) {
                        return Card(
                          elevation: 5,
                          child: ListTile(
                            dense: screenHeight < 750.0 ? true : false,
                            isThreeLine: true,
                            title: Text(item[index].product_name!, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blueGrey)),
                            subtitle: Text(getVariant(item[index]) + getModifier(item[index])),
                            trailing: Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text("x${item[index].quantity}"),
                                FutureBuilder(
                                    future: getStockLeft(item[index]),
                                    builder: (context, snapshot){
                                      if(snapshot.hasData){
                                        return Text("${AppLocalizations.of(context)!.translate("available_stock")}: ${(snapshot.data)}", style: TextStyle(color: Colors.red),);
                                      } else {
                                        return Text("");
                                      }
                                    })
                                // Text("${AppLocalizations.of(context)!.translate("available_stock")}: ${getStockLeft(item[index]) ?? ''}", style: TextStyle(color: Colors.red),)
                              ],
                            ),
                          ),
                        );
                      },
                    )
                    // separatorBuilder: (BuildContext context, int index) => const Divider()),
                  ],
                ),
              ),
            ),
            actions: [
              ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  onPressed: (){
                    Navigator.of(context).pop();
                  },
                  child: Text(AppLocalizations.of(context)!.translate("close")))
            ],
          );
        });
  }

  Future<String> getStockLeft(cartProductItem cartItem) async {
    String stockLeft = '';
    BranchLinkProduct? product = await PosDatabase.instance.readSpecificBranchLinkProduct2(cartItem.branch_link_product_sqlite_id.toString());
    if(product != null){
      switch (product.stock_type) {
        case '1':
          return stockLeft = product.daily_limit!;
        case '2':
          return stockLeft = product.stock_quantity!;
      }
    }
    return stockLeft;
  }

  checkDirectPayment(AppSettingModel appSettingModel, cart) {
    if (appSettingModel.directPaymentStatus == true) {
      paymentAddToCart(cart);
      updateCartItem(cart);
      openPaymentSelect(cart);
    } else {
      cart.removeAllCartItem();
      cart.selectedTable.clear();
    }
  }

  printKitchenList() async {
    try {
      List<OrderDetail>? returnData = await printReceipt.printKitchenList(printerList, int.parse(this.orderCacheId));
      if(returnData != null){
        if (returnData.isNotEmpty) {
          _failPrintModel.addAllFailedOrderDetail(orderDetailList: returnData);
          if(mounted){
            ShowFailedPrintKitchenToast.showToast();
          }
        }
      } else {
        Fluttertoast.showToast(backgroundColor: Colors.red, msg: "${AppLocalizations.of(context)?.translate('no_printer_added')}");
      }
    } catch (e) {
      FLog.error(
        className: "cart",
        text: "print kitchen list error",
        exception: "$e",
      );
    }
  }

  playSound() {
    try {
      final assetsAudioPlayer = AssetsAudioPlayer();
      assetsAudioPlayer.open(
        Audio("audio/review.mp3"),
      );
    } catch (e) {
      print("Play Sound Error: ${e}");
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
      if (data.isNotEmpty) {
        for (int i = 0; i < data.length; i++) {
          if (tempBatch.toString() == data[i].batch_id!.toString()) {
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
    return tempBatch.toString();
  }

/*
  ---------------Place Order part--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
*/
  createTableUseID() async {
    List<String> _value = [];
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
            status: 0,
            sync_status: 0,
            created_at: dateTime,
            updated_at: '',
            soft_delete: '');
        //create table use data
        TableUse tableUseData = await PosDatabase.instance.insertSqliteTableUse(data);
        localTableUseId = tableUseData.table_use_sqlite_id.toString();
        TableUse _updatedTableUseData = await insertTableUseKey(tableUseData, dateTime);
        _value.add(jsonEncode(_updatedTableUseData));
        //sync tot cloud
        //await syncTableUseIdToCloud(_updatedTableUseData);
      }
    } catch (e) {
      print(e);
      Fluttertoast.showToast(
          backgroundColor: Color(0xFFFF0000), msg: AppLocalizations.of(context)!.translate('create_table_id_error')+" ${e}");
      FLog.error(
        className: "cart",
        text: "create table use id error",
        exception: e,
      );
    }
  }

  // syncTableUseIdToCloud(TableUse updatedTableUseData) async {
  //   List<String> _value = [];
  //   //check is host reachable
  //   bool _hasInternetAccess = await Domain().isHostReachable();
  //   if (_hasInternetAccess) {
  //     _value.add(jsonEncode(updatedTableUseData));
  //     Map response = await Domain().SyncTableUseToCloud(_value.toString());
  //     if (response['status'] == '1') {
  //       List responseJson = response['data'];
  //       int syncData = await PosDatabase.instance.updateTableUseSyncStatusFromCloud(responseJson[0]['table_use_key']);
  //     }
  //   }
  // }

  generateTableUseKey(TableUse tableUse) async {
    final prefs = await SharedPreferences.getInstance();
    final int? device_id = prefs.getInt('device_id');
    var bytes = tableUse.created_at!.replaceAll(new RegExp(r'[^0-9]'), '') + tableUse.table_use_sqlite_id.toString() + device_id.toString();
    var md5Hash = md5.convert(utf8.encode(bytes));
    return Utils.shortHashString(hashCode: md5Hash);
  }

  insertTableUseKey(TableUse tableUse, String dateTime) async {
    TableUse? _tbUseList;
    tableUseKey = await generateTableUseKey(tableUse);
    if (tableUseKey != null) {
      TableUse tableUseObject = TableUse(table_use_key: tableUseKey, sync_status: 0, updated_at: dateTime, table_use_sqlite_id: tableUse.table_use_sqlite_id);
      int tableUseData = await PosDatabase.instance.updateTableUseUniqueKey(tableUseObject);
      if (tableUseData == 1) {
        TableUse data = await PosDatabase.instance.readSpecificTableUseIdByLocalId(tableUseObject.table_use_sqlite_id!);
        _tbUseList = data;
      }
    }
    return _tbUseList;
  }

  generateTableUseDetailKey(TableUseDetail tableUseDetail) async {
    final prefs = await SharedPreferences.getInstance();
    final int? device_id = prefs.getInt('device_id');
    var bytes = tableUseDetail.created_at!.replaceAll(new RegExp(r'[^0-9]'), '') + tableUseDetail.table_use_detail_sqlite_id.toString() + device_id.toString();
    var md5Hash = md5.convert(utf8.encode(bytes));
    return Utils.shortHashString(hashCode: md5Hash);
  }

  insertTableUseDetailKey(TableUseDetail tableUseDetail, String dateTime) async {
    TableUseDetail? _tableUseDetailData;
    tableUseDetailKey = await generateTableUseDetailKey(tableUseDetail);
    if (tableUseDetailKey != null) {
      TableUseDetail tableUseDetailObject =
      TableUseDetail(table_use_detail_key: tableUseDetailKey, sync_status: 0, updated_at: dateTime, table_use_detail_sqlite_id: tableUseDetail.table_use_detail_sqlite_id);
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
        try {
          //create table use detail
          TableUseDetail tableUseDetailData = await PosDatabase.instance.insertSqliteTableUseDetail(
              TableUseDetail(
                  table_use_detail_id: 0,
                  table_use_detail_key: '',
                  table_use_sqlite_id: localTableUseId,
                  table_use_key: tableUseKey,
                  table_sqlite_id: cart.selectedTable[i].table_sqlite_id.toString(),
                  table_id: cart.selectedTable[i].table_id.toString(),
                  status: 0,
                  sync_status: 0,
                  created_at: dateTime,
                  updated_at: '',
                  soft_delete: ''));
          TableUseDetail updatedDetail = await insertTableUseDetailKey(tableUseDetailData, dateTime);
          _value.add(jsonEncode(updatedDetail));
        } catch(e) {
          FLog.error(
            className: "cart",
            text: "table use detail insert failed (table_id: ${cart.selectedTable[i].table_id.toString()})",
            exception: "$e\n${cart.selectedTable[i].toJson()}",
          );
        }
      }
      table_use_detail_value = _value.toString();
      //sync to cloud
      //syncTableUseDetailToCloud(_value.toString());
    } catch (e) {
      print(e);
      Fluttertoast.showToast(
          backgroundColor: Color(0xFFFF0000), msg: AppLocalizations.of(context)!.translate('create_table_detail_error')+" ${e}");
      FLog.error(
        className: "cart",
        text: "createTableUseDetail error",
        exception: e,
      );
    }
  }

  // syncTableUseDetailToCloud(String value) async {
  //   //check is host reachable
  //   bool _hasInternetAccess = await Domain().isHostReachable();
  //   if (_hasInternetAccess) {
  //     Map response = await Domain().SyncTableUseDetailToCloud(value);
  //     if (response['status'] == '1') {
  //       List responseJson = response['data'];
  //       for (int i = 0; i < responseJson.length; i++) {
  //         int updateStatus = await PosDatabase.instance.updateTableUseDetailSyncStatusFromCloud(responseJson[i]['table_use_detail_key']);
  //       }
  //     }
  //   }
  // }

  createOrderCache(CartModel cart, {required bool isAddOrder}) async {
    try {
      print("createOrderCache called");
      DateFormat dateFormat = DateFormat("yyyy-MM-dd HH:mm:ss");
      String dateTime = dateFormat.format(DateTime.now());

      final prefs = await SharedPreferences.getInstance();
      final int? branch_id = prefs.getInt('branch_id');
      final String? user = prefs.getString('pos_pin_user');
      final String? loginUser = prefs.getString('user');

      AppSetting? localSetting = await PosDatabase.instance.readLocalAppSetting(branch_id.toString());
      int orderQueue = localSetting!.enable_numbering == 1 && ((localSetting.table_order != 0 && cart.selectedOption != 'Dine in') ||  localSetting.table_order == 0) ? await generateOrderQueue() : -1;

      TableUse? _tableUse;
      List<PosTable> inUsedTable = [];
      List<String> _value = [];
      Map userObject = json.decode(user!);
      Map loginUserObject = json.decode(loginUser!);
      String _tableUseId = '';
      String batch = '';
      try {
        if (isAddOrder == true) {
          batch = cart.cartNotifierItem[0].first_cache_batch!;
        } else {
          batch = await batchChecking();
        }
        //check selected table is in use or not
        if (cart.selectedOption == 'Dine in' && localSetting.table_order != 0) {
          if(isAddOrder == true){
            inUsedTable = await checkCartTableStatus(cart.selectedTable);
          } else {
            inUsedTable.addAll(cart.selectedTable);
          }
          List<TableUseDetail> useDetail = await PosDatabase.instance.readSpecificTableUseDetail(inUsedTable[0].table_sqlite_id!);
          if(localSetting.table_order == 1) {
            if (useDetail.isNotEmpty) {
              _tableUseId = useDetail[0].table_use_sqlite_id!;
            } else {
              _tableUseId = this.localTableUseId;
            }
          } else {
            _tableUseId = this.localTableUseId;
          }

          List<TableUse> tableUseData = await PosDatabase.instance.readSpecificTableUseId(int.parse(_tableUseId));
          _tableUse = tableUseData[0];
        }
        if (batch != '') {
          try {
            //create order cache
            OrderCache data = await PosDatabase.instance.insertSqLiteOrderCache(OrderCache(
                order_cache_id: 0,
                order_cache_key: '',
                order_queue: orderQueue != -1 ? orderQueue.toString().padLeft(4, '0') : '',
                company_id: loginUserObject['company_id'].toString(),
                branch_id: branch_id.toString(),
                order_detail_id: '',
                table_use_sqlite_id: cart.selectedOption == 'Dine in' && localSetting.table_order != 0 ? _tableUse!.table_use_sqlite_id.toString() : '',
                table_use_key: cart.selectedOption == 'Dine in' && localSetting.table_order != 0 ? _tableUse!.table_use_key : '',
                batch_id: batch.toString().padLeft(6, '0'),
                dining_id: this.diningOptionID.toString(),
                order_sqlite_id: '',
                order_key: '',
                order_by: userObject['name'].toString(),
                order_by_user_id: userObject['user_id'].toString(),
                cancel_by: '',
                cancel_by_user_id: '',
                customer_id: '0',
                total_amount: newOrderSubtotal.toStringAsFixed(2),
                qr_order: 0,
                qr_order_table_sqlite_id: '',
                qr_order_table_id: '',
                accepted: 0,
                payment_status: 0,
                sync_status: 0,
                created_at: dateTime,
                updated_at: '',
                soft_delete: ''));
            orderCacheId = data.order_cache_sqlite_id.toString();
            orderNumber = data.order_queue.toString();

            try {
              OrderCache updatedCache = await insertOrderCacheKey(data, dateTime);
              if (updatedCache.sync_status == 0 && isAddOrder == false) {
                //sync updated table use (with order cache key)
                await insertOrderCacheKeyIntoTableUse(cart, updatedCache, dateTime);
              }
              _value.add(jsonEncode(updatedCache));
              order_cache_value = _value.toString();
              //sync to cloud
              //syncOrderCacheToCloud(updatedCache);
              cart.addOrder(data);
            } catch(e) {
              FLog.error(
                className: "cart",
                text: "order cache key insert failed ()",
                exception: "$e\n${data.toJson()}",
              );
            }
          } catch(e) {
            FLog.error(
              className: "cart",
              text: "order cache create insert error",
              exception: e,
            );
          }
        }
      } catch (e) {
        print('createOrderCache error: ${e}');
      }
    } catch(e) {
      FLog.error(
        className: "cart",
        text: "createOrderCache error",
        exception: e,
      );
    }
  }

  Future<List<PosTable>> checkCartTableStatus(List<PosTable> cartSelectedTable) async {
    List<PosTable> inUsedTable = [];
    for(int i = 0; i < cartSelectedTable.length; i++){
      List<PosTable> table = await PosDatabase.instance.checkPosTableStatus(cartSelectedTable[i].table_sqlite_id!);
      if(table[0].status == 1){
        inUsedTable.add(table[0]);
      }
    }
    return inUsedTable;
  }

  // syncOrderCacheToCloud(OrderCache updatedCache) async {
  //   List<String> _orderCacheValue = [];
  //   bool _hasInternetAccess = await Domain().isHostReachable();
  //   if (_hasInternetAccess) {
  //     _orderCacheValue.add(jsonEncode(updatedCache));
  //     Map response = await Domain().SyncOrderCacheToCloud(_orderCacheValue.toString());
  //     if (response['status'] == '1') {
  //       List responseJson = response['data'];
  //       int orderCacheData = await PosDatabase.instance.updateOrderCacheSyncStatusFromCloud(responseJson[0]['order_cache_key']);
  //     }
  //   }
  // }

  generateOrderCacheKey(OrderCache orderCache) async {
    final prefs = await SharedPreferences.getInstance();
    final int? device_id = prefs.getInt('device_id');
    var bytes = orderCache.created_at!.replaceAll(new RegExp(r'[^0-9]'), '') + orderCache.order_cache_sqlite_id.toString() + device_id.toString();
    var md5Hash = md5.convert(utf8.encode(bytes));
    return Utils.shortHashString(hashCode: md5Hash);
  }

  Future<int> generateOrderQueue() async {
    print("generateOrderQueue called");
    final prefs = await SharedPreferences.getInstance();
    final int? branch_id = prefs.getInt('branch_id');
    AppSetting? localSetting = await PosDatabase.instance.readLocalAppSetting(branch_id.toString());
    int orderQueue = localSetting!.starting_number!;
    try {
      await readAllOrder();
      await readAllOrderCache();
      List<Order> orderData = await PosDatabase.instance.readLatestNotDineInOrder();
      List<OrderCache> orderCacheData = await PosDatabase.instance.readAllNotDineInOrderCache();
      // not yet make settlement
      if(orderList.isNotEmpty) {
        if(localSetting.table_order != 0) {
          if(orderData.isNotEmpty) {
            if(orderData[0].settlement_key! == '') {
              if(int.tryParse(orderCacheData[0].order_queue!) == null || int.parse(orderCacheData[0].order_queue!) >= 9999) {
                orderQueue = localSetting.starting_number!;
              }
              else {
                orderQueue = int.parse(orderCacheData[0].order_queue!) + 1;
              }
            }
          } else {
            if(orderCacheData.isNotEmpty && orderCacheData[0].order_key == '') {
              orderQueue = int.parse(orderCacheData[0].order_queue!) + 1;
            } else {
              orderQueue = localSetting.starting_number!;
            }
          }
        } else {
          if(orderList[0].settlement_key! == '') {
            if(int.tryParse(orderCacheList[0].order_queue!) == null || int.parse(orderCacheList[0].order_queue!) >= 9999) {
              orderQueue = localSetting.starting_number!;
            }
            else {
              orderQueue = int.parse(orderCacheList[0].order_queue!) + 1;
            }
          } else {
            // after settlement
            if(orderCacheList[0].order_key == '' && orderCacheList[0].cancel_by == '') {
              orderQueue = int.parse(orderCacheList[0].order_queue!) + 1;
            } else {
              orderQueue = localSetting.starting_number!;
            }
          }
        }
      } else {
        if(localSetting.table_order != 0) {
          if(orderCacheData.isNotEmpty && orderCacheData[0].order_key == '') {
            orderQueue = int.parse(orderCacheData[0].order_queue!) + 1;
          } else {
            orderQueue = localSetting.starting_number!;
          }
        } else {
          if(orderCacheList.isNotEmpty && orderCacheList[0].order_key == '') {
            orderQueue = int.parse(orderCacheList[0].order_queue!) + 1;
          } else {
            orderQueue = localSetting.starting_number!;
          }
        }
      }
      return orderQueue;
    } catch(e) {
      print("generateOrderQueue error");
      return orderQueue = localSetting.starting_number!;
    }
  }

  insertOrderCacheKey(OrderCache orderCache, String dateTime) async {
    OrderCache? data;
    orderCacheKey = await generateOrderCacheKey(orderCache);
    if (orderCacheKey != null) {
      OrderCache orderCacheObject = OrderCache(order_cache_key: orderCacheKey, sync_status: 0, updated_at: dateTime, order_cache_sqlite_id: orderCache.order_cache_sqlite_id);
      int cacheUniqueKey = await PosDatabase.instance.updateOrderCacheUniqueKey(orderCacheObject);
      if (cacheUniqueKey == 1) {
        OrderCache orderCacheData = await PosDatabase.instance.readSpecificOrderCacheByLocalId(orderCacheObject.order_cache_sqlite_id!);
        if (orderCacheData.sync_status == 0) {
          data = orderCacheData;
        }
      }
    }
    return data;
  }

  insertOrderCacheKeyIntoTableUse(CartModel cart, OrderCache orderCache, String dateTime) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final int? branch_id = prefs.getInt('branch_id');
      AppSetting? localSetting = await PosDatabase.instance.readLocalAppSetting(branch_id.toString());
      List<String> _tableUseValue = [];
      if (cart.selectedOption == "Dine in" && localSetting!.table_order == 1) {
        List<TableUse> checkTableUse = await PosDatabase.instance.readSpecificTableUseId(int.parse(orderCache.table_use_sqlite_id!));
        TableUse tableUseObject = TableUse(
            order_cache_key: orderCacheKey,
            sync_status: checkTableUse[0].sync_status == 0 ? 0 : 2,
            updated_at: dateTime,
            table_use_sqlite_id: int.parse(orderCache.table_use_sqlite_id!));
        int tableUseCacheKey =
        await PosDatabase.instance.updateTableUseOrderCacheUniqueKey(tableUseObject);
        if (tableUseCacheKey == 1) {
          List<TableUse> updatedTableUseRead =
          await PosDatabase.instance.readSpecificTableUseId(tableUseObject.table_use_sqlite_id!);
          _tableUseValue.add(jsonEncode(updatedTableUseRead[0]));
          table_use_value = _tableUseValue.toString();
          //sync to cloud
          //syncUpdatedTableUseIdToCloud(_tableUseValue.toString());
        }
      }
    } catch(e) {
      FLog.error(
        className: "cart",
        text: "insertOrderCacheKeyIntoTableUse error",
        exception: e,
      );
    }
  }

  // syncUpdatedTableUseIdToCloud(String tableUseValue) async {
  //   bool _hasInternetAccess = await Domain().isHostReachable();
  //   if (_hasInternetAccess) {
  //     var response = await Domain().SyncTableUseToCloud(tableUseValue);
  //     if (response != null) {
  //       if (response['status'] == '1') {
  //         List responseJson = response['data'];
  //         int updatedTableUse = await PosDatabase.instance.updateTableUseSyncStatusFromCloud(responseJson[0]['table_use_key']);
  //       }
  //     } else {
  //       this.timeOutDetected = true;
  //     }
  //   }
  // }

  createOrderDetail(CartModel cart) async {
    DateFormat dateFormat = DateFormat("yyyy-MM-dd HH:mm:ss");
    String dateTime = dateFormat.format(DateTime.now());
    List<String> _orderDetailValue = [];
    List<String> _orderModifierValue = [];
    List<String> _branchLinkProductValue = [];

    ///loop cart item & create order detail
    List<cartProductItem> newOrderDetailList = cart.cartNotifierItem.where((item) => item.status == 0).toList();
    for (int j = 0; j < newOrderDetailList.length; j++) {
      OrderDetail object = OrderDetail(
          order_detail_id: 0,
          order_detail_key: '',
          order_cache_sqlite_id: orderCacheId,
          order_cache_key: orderCacheKey,
          branch_link_product_sqlite_id: newOrderDetailList[j].branch_link_product_sqlite_id,
          category_sqlite_id: newOrderDetailList[j].category_sqlite_id,
          category_name: newOrderDetailList[j].category_name,
          productName: newOrderDetailList[j].product_name,
          has_variant: newOrderDetailList[j].variant!.length == 0 ? '0' : '1',
          product_variant_name: getVariant2(newOrderDetailList[j]),
          price: newOrderDetailList[j].price,
          original_price: newOrderDetailList[j].base_price,
          quantity: newOrderDetailList[j].quantity.toString(),
          remark: newOrderDetailList[j].remark,
          account: '',
          edited_by: '',
          edited_by_user_id: '',
          cancel_by: '',
          cancel_by_user_id: '',
          status: 0,
          sync_status: 0,
          unit: newOrderDetailList[j].unit,
          per_quantity_unit: newOrderDetailList[j].per_quantity_unit,
          product_sku: newOrderDetailList[j].product_sku,
          created_at: dateTime,
          updated_at: '',
          soft_delete: '');

      newOrderDetailList[j].productVariantName = object.product_variant_name;
      try {
        OrderDetail orderDetailData = await PosDatabase.instance.insertSqliteOrderDetail(object);
        BranchLinkProduct? branchLinkProductData = await updateProductStock(
            orderDetailData.branch_link_product_sqlite_id.toString(),
            newOrderDetailList[j].branch_link_product_id!,
            int.tryParse(orderDetailData.quantity!) != null ? int.parse(orderDetailData.quantity!): double.parse(orderDetailData.quantity!),
            dateTime);
        if(branchLinkProductData != null){
          _branchLinkProductValue.add(jsonEncode(branchLinkProductData.toJson()));
          branch_link_product_value = _branchLinkProductValue.toString();
        }
        ///insert order detail key
        OrderDetail updatedOrderDetailData = await insertOrderDetailKey(orderDetailData, dateTime);
        _orderDetailValue.add(jsonEncode(updatedOrderDetailData.syncJson()));
        order_detail_value = _orderDetailValue.toString();

        ///insert order modifier detail
        if (newOrderDetailList[j].checkedModifierItem!.isNotEmpty) {
          List<ModifierItem> modItem = newOrderDetailList[j].checkedModifierItem!;
          for (int k = 0; k < modItem.length; k++) {
            OrderModifierDetail orderModifierDetailData = await PosDatabase.instance
                .insertSqliteOrderModifierDetail(OrderModifierDetail(
                order_modifier_detail_id: 0,
                order_modifier_detail_key: '',
                order_detail_sqlite_id: orderDetailData.order_detail_sqlite_id.toString(),
                order_detail_id: '0',
                order_detail_key: await orderDetailKey,
                mod_item_id: modItem[k].mod_item_id.toString(),
                mod_name: modItem[k].name,
                mod_price: modItem[k].price,
                mod_group_id: modItem[k].mod_group_id.toString(),
                sync_status: 0,
                created_at: dateTime,
                updated_at: '',
                soft_delete: ''));
            //insert unique key
            OrderModifierDetail updatedOrderModifierDetail =
            await insertOrderModifierDetailKey(orderModifierDetailData, dateTime);
            if (updatedOrderModifierDetail.order_modifier_detail_key != '') {
              _orderModifierValue.add(jsonEncode(updatedOrderModifierDetail));
              order_modifier_detail_value = _orderModifierValue.toString();
            }
          }
        }
      } catch(e) {
        FLog.error(
          className: "cart",
          text: "order detail insert failed",
          exception: "$e\n${object.toJson()}",
        );
      }
    }
  }

  updateProductStock(String branch_link_product_sqlite_id, int branchLinkProductId, num quantity, String dateTime) async {
    print("update product stock called!!!");
    num _totalStockQty = 0, updateStock = 0;
    BranchLinkProduct? object;
    try {
      List<BranchLinkProduct> checkData = await PosDatabase.instance.readSpecificBranchLinkProduct(branch_link_product_sqlite_id);
      if (checkData.isNotEmpty) {
        switch (checkData[0].stock_type) {
          case '1':
            {
              _totalStockQty = int.parse(checkData[0].daily_limit!) - quantity;
              object = BranchLinkProduct(
                  updated_at: dateTime,
                  sync_status: 2,
                  daily_limit: _totalStockQty.toString(),
                  branch_link_product_id: branchLinkProductId,
                  branch_link_product_sqlite_id: int.parse(branch_link_product_sqlite_id));
              updateStock = await PosDatabase.instance.updateBranchLinkProductDailyLimit(object);
              posFirestore.updateBranchLinkProductDailyLimit(object);
            }
            break;
          case '2':
            {
              _totalStockQty = int.parse(checkData[0].stock_quantity!) - quantity;
              object = BranchLinkProduct(
                  updated_at: dateTime,
                  sync_status: 2,
                  stock_quantity: _totalStockQty.toString(),
                  branch_link_product_id: branchLinkProductId,
                  branch_link_product_sqlite_id: int.parse(branch_link_product_sqlite_id));
              updateStock = await PosDatabase.instance.updateBranchLinkProductStock(object);
              posFirestore.updateBranchLinkProductStock(object);
            }
            break;
          default:
            {
              updateStock = 0;
            }
            break;
        }
        //return updated value
        if (updateStock == 1) {
          List<BranchLinkProduct> updatedData = await PosDatabase.instance.readSpecificBranchLinkProduct(branch_link_product_sqlite_id);
          return updatedData[0];
        } else {
          return null;
        }
      }
    } catch (e) {
      print("cart update product stock error: $e");
      FLog.error(
        className: "cart",
        text: "product stock update failed (branch_link_product_sqlite_id: ${branch_link_product_sqlite_id})",
        exception: e,
      );
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
      int updateUniqueKey = await PosDatabase.instance.updateOrderModifierDetailUniqueKey(orderModifierDetailData);
      if (updateUniqueKey == 1) {
        OrderModifierDetail data = await PosDatabase.instance.readSpecificOrderModifierDetailByLocalId(orderModifierDetailData.order_modifier_detail_sqlite_id!);
        detailData = data;
      }
    }
    return detailData;
  }

  insertOrderDetailKey(OrderDetail orderDetail, String dateTime) async {
    OrderDetail? detailData;
    try {
      orderDetailKey = await generateOrderDetailKey(orderDetail);
      if (orderDetailKey != null) {
        OrderDetail orderDetailObject =
        OrderDetail(order_detail_key: orderDetailKey, sync_status: 0, updated_at: dateTime, order_detail_sqlite_id: orderDetail.order_detail_sqlite_id);
        int updateUniqueKey = await PosDatabase.instance.updateOrderDetailUniqueKey(orderDetailObject);
        if (updateUniqueKey == 1) {
          OrderDetail data = await PosDatabase.instance.readSpecificOrderDetailByLocalId(orderDetailObject.order_detail_sqlite_id!);
          detailData = data;
        }
      }
      return detailData;
    } catch (e) {
      print('insert order detail key error: ${e}');
      FLog.error(
        className: "cart",
        text: "order detail key insert failed",
        exception: "$e\n${orderDetail.toJson()}",
      );
      return;
    }
  }

  generateOrderDetailKey(OrderDetail orderDetail) async {
    final prefs = await SharedPreferences.getInstance();
    final int? device_id = prefs.getInt('device_id');
    var bytes = orderDetail.created_at!.replaceAll(new RegExp(r'[^0-9]'), '') + orderDetail.order_detail_sqlite_id.toString() + device_id.toString();
    var md5Hash = md5.convert(utf8.encode(bytes));
    return Utils.shortHashString(hashCode: md5Hash);
  }

  generateOrderModifierDetailKey(OrderModifierDetail orderModifierDetail) async {
    final prefs = await SharedPreferences.getInstance();
    final int? device_id = prefs.getInt('device_id');
    var bytes = orderModifierDetail.created_at!.replaceAll(new RegExp(r'[^0-9]'), '') + orderModifierDetail.order_modifier_detail_sqlite_id.toString() + device_id.toString();
    var md5Hash = md5.convert(utf8.encode(bytes));
    return Utils.shortHashString(hashCode: md5Hash);
  }

  updatePosTable(CartModel cart) async {
    try {
      List<String> _value = [];
      DateFormat dateFormat = DateFormat("yyyy-MM-dd HH:mm:ss");
      String dateTime = dateFormat.format(DateTime.now());

      for (int i = 0; i < cart.selectedTable.length; i++) {
        List<PosTable> result = await PosDatabase.instance.checkPosTableStatus(cart.selectedTable[i].table_sqlite_id!);
        List<TableUseDetail> tableUseDetail = await PosDatabase.instance.readSpecificTableUseDetail(cart.selectedTable[i].table_sqlite_id!);
        if (result[0].status == 0) {
          PosTable posTableData = PosTable(
              table_sqlite_id: cart.selectedTable[i].table_sqlite_id,
              table_use_detail_key: tableUseDetail[0].table_use_detail_key,
              table_use_key: tableUseKey,
              status: 1,
              updated_at: dateTime);
          int data = await PosDatabase.instance.updateCartPosTableStatus(posTableData);
          if (data == 1) {
            List<PosTable> posTable = await PosDatabase.instance.readSpecificTable(posTableData.table_sqlite_id.toString());
            if (posTable[0].sync_status == 2) {
              _value.add(jsonEncode(posTable[0]));
            }
          }
        }
      }
      table_value = _value.toString();
      if (this.timeOutDetected == false) {
        //syncUpdatedTableToCloud(_value.toString());
      }
    } catch (e) {
      Fluttertoast.showToast(backgroundColor: Color(0xFFFF0000), msg: AppLocalizations.of(context)!.translate('update_table_error') + " ${e}");
      print("update table error: $e");
      FLog.error(
        className: "cart",
        text: "table update error",
        exception: e,
      );
    }
  }

  syncAllToCloud() async {
    try {
      if (mainSyncToCloud.count == 0) {
        mainSyncToCloud.count = 1;
        final prefs = await SharedPreferences.getInstance();
        final int? device_id = prefs.getInt('device_id');
        final String? login_value = prefs.getString('login_value');
        //bool _hasInternetAccess = await Domain().isHostReachable();
        Map data = await Domain().syncLocalUpdateToCloud(
            device_id: device_id.toString(),
            value: login_value,
            table_use_value: this.table_use_value,
            table_use_detail_value: this.table_use_detail_value,
            order_cache_value: this.order_cache_value,
            order_detail_value: this.order_detail_value,
            branch_link_product_value: this.branch_link_product_value,
            order_modifier_value: this.order_modifier_detail_value,
            table_value: this.table_value);
        print('data status: ${data['status']}');
        if (data['status'] == '1') {
          print('success');
          List responseJson = data['data'];
          if (responseJson.isNotEmpty) {
            for (int i = 0; i < responseJson.length; i++) {
              switch (responseJson[i]['table_name']) {
                case 'tb_table_use':
                  {
                    await PosDatabase.instance.updateTableUseSyncStatusFromCloud(responseJson[i]['table_use_key']);
                  }
                  break;
                case 'tb_table_use_detail':
                  {
                    await PosDatabase.instance.updateTableUseDetailSyncStatusFromCloud(responseJson[i]['table_use_detail_key']);
                  }
                  break;
                case 'tb_order_cache':
                  {
                    await PosDatabase.instance.updateOrderCacheSyncStatusFromCloud(responseJson[i]['order_cache_key']);
                  }
                  break;
                case 'tb_order_detail':
                  {
                    await PosDatabase.instance.updateOrderDetailSyncStatusFromCloud(responseJson[i]['order_detail_key']);
                  }
                  break;
                case 'tb_order_modifier_detail':
                  {
                    await PosDatabase.instance.updateOrderModifierDetailSyncStatusFromCloud(responseJson[i]['order_modifier_detail_key']);
                  }
                  break;
                case 'tb_branch_link_product':
                  {
                    await PosDatabase.instance.updateBranchLinkProductSyncStatusFromCloud(responseJson[i]['branch_link_product_id']);
                  }
                  break;
                case 'tb_table':
                  {
                    await PosDatabase.instance.updatePosTableSyncStatusFromCloud(responseJson[i]['table_id']);
                  }
                  break;
                default:
                  {
                    return;
                  }
              }
            }
            mainSyncToCloud.resetCount();
          } else {
            mainSyncToCloud.resetCount();
          }
        } else if (data['status'] == '7') {
          this.isLogOut = true;
          mainSyncToCloud.resetCount();
        } else if (data['status'] == '8') {
          print('cart time out');
          mainSyncToCloud.resetCount();
          throw TimeoutException("Timeout");
        } else {
          mainSyncToCloud.resetCount();
        }
      }
    } catch (e) {
      print("cart sync to cloud error: $e");
      mainSyncToCloud.resetCount();
      // return;
    }
  }

/*
  ---------------multi device part--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
*/
/*
  Cart Ordering initial called
*/
  getSubTotalMultiDevice(CartModel cart) async {
    try {
      //widget.currentPage == 'table' || widget.currentPage == 'qr_order' ? cart.selectedOption = 'Dine in' : null;
      total = 0.0;
      newOrderSubtotal = 0.0;
      promo = 0.0;
      promoAmount = 0.0;
      for (int i = 0; i < cart.cartNotifierItem.length; i++) {
        total += (double.parse((cart.cartNotifierItem[i].price!)) * cart.cartNotifierItem[i].quantity!);
        if (cart.cartNotifierItem[i].status == 0) {
          newOrderSubtotal += (double.parse((cart.cartNotifierItem[i].price!)) * cart.cartNotifierItem[i].quantity!);
        }
      }
    } catch (e) {
      print('Sub Total Error: $e');
      total = 0.0;
    }
    await getDiningTaxMultiDevice(cart);
    // calPromotion(cart);
    // getTaxAmount();
    // getRounding();
    // getAllTotal();
    checkCartItem(cart);
    // if (cart.myCount == 0) {
    //   WidgetsBinding.instance.addPostFrameCallback((_) {
    //     setState(() {
    //       _scrollDown();
    //     });
    //   });
    //   cart.myCount++;
    // }
    // if (!controller.isClosed) {
    //   controller.sink.add('refresh');
    // }
  }

  getDiningTaxMultiDevice(CartModel cart) async {
    try {
      //get dining option data
      List<DiningOption> data = await PosDatabase.instance.checkSelectedOption(cart.selectedOption);
      if (data.isNotEmpty) {
        diningOptionID = data[0].dining_id!;

        //get dining tax
        List<Tax> taxData = await PosDatabase.instance.readTax(diningOptionID.toString());
        if (taxData.isNotEmpty) {
          taxRateList = List.from(taxData);
        } else {
          taxRateList = [];
        }
      }
    } catch (error) {
      print('get dining tax in cart error: $error');
    }
  }

/*
  Not dine in call
*/
  callCreateNewNotDineOrder2(CartModel cart) async {
    print('cart: ${cart.cartNotifierItem.length}');
    resetValue();
    await createOrderCache(cart, isAddOrder: false);
    await createOrderDetail(cart);
    // await syncAllToCloud();
    // if(this.isLogOut == true){
    //   openLogOutDialog();
    //   return;
    // }
    // await printReceipt.printCheckList(printerList, int.parse(this.orderCacheId), context);
    // await printReceipt.printKitchenList(printerList, context, cart, int.parse(this.orderCacheId));
  }

  readAllOrder() async {
    List<Order> data = await PosDatabase.instance.readLatestOrder();
    orderList = data;
  }

  readAllOrderCache() async {
    List<OrderCache> data = await PosDatabase.instance.readAllOrderCache();
    orderCacheList = data;
  }
}
