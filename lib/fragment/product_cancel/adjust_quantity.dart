import 'dart:async';
import 'dart:convert';

import 'package:f_logs/model/flog/flog.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';
import 'package:pos_system/database/pos_firestore.dart';
import 'package:pos_system/firebase_sync/qr_order_sync.dart';
import 'package:pos_system/fragment/product_cancel/cancel_query.dart';
import 'package:pos_system/fragment/product_cancel/quantity_input_widget.dart';
import 'package:pos_system/fragment/product_cancel/reason_input_widget.dart';
import 'package:pos_system/main.dart';
import 'package:pos_system/object/order_detail_cancel.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:crypto/crypto.dart';

import '../../custom_pin_dialog.dart';
import '../../database/domain.dart';
import '../../database/pos_database.dart';
import '../../notifier/app_setting_notifier.dart';
import '../../notifier/cart_notifier.dart';
import '../../notifier/table_notifier.dart';
import '../../notifier/theme_color.dart';
import '../../object/branch_link_product.dart';
import '../../object/cart_product.dart';
import '../../object/order_cache.dart';
import '../../object/order_detail.dart';
import '../../object/order_modifier_detail.dart';
import '../custom_toastification.dart';
import '../printing_layout/print_receipt.dart';
import '../../object/table_use_detail.dart';
import '../../object/user.dart';
import '../../translation/AppLocalizations.dart';
import '../logout_dialog.dart';

class AdjustQuantityDialog extends StatefulWidget {
  final cartProductItem cartItem;
  final String currentPage;

  const AdjustQuantityDialog(
      {Key? key, required this.cartItem, required this.currentPage})
      : super(key: key);

  @override
  State<AdjustQuantityDialog> createState() => _AdjustQuantityDialogState();
}

class _AdjustQuantityDialogState extends State<AdjustQuantityDialog> {
  PrintReceipt _printReceipt = PrintReceipt();
  PosDatabase posDatabase = PosDatabase.instance;
  PosFirestore _posFirestore = PosFirestore.instance;
  FirestoreQROrderSync _firestoreQROrderSync = FirestoreQROrderSync.instance;
  AppSettingModel appSettingModel = AppSettingModel.instance;
  BuildContext globalContext = MyApp.navigatorKey.currentContext!;
  num simpleIntInput = 0;
  late num currentQuantity;
  final adminPosPinController = TextEditingController();
  List<OrderCache> cartCacheList = [], cartTableCacheList = [];
  List<OrderDetail> cartOrderDetailList = [];
  List<OrderModifierDetail> cartOrderModDetailList = [];
  List<TableUseDetail> cartTableUseDetail = [];
  String? table_use_value,
      table_use_detail_value,
      branch_link_product_value,
      order_cache_value,
      order_detail_value,
      order_detail_cancel_value,
      table_value;
  String reason = '';
  bool isLogOut = false;
  bool isButtonDisabled = false;
  bool willPop = true;
  bool restock = false;

  late final OrderDetail orderDetail;
  late TableModel tableModel;
  late CartModel cart;
  late ThemeColor color;

  @override
  void initState() {
    super.initState();
    readAllPrinters();
    readCartItemInfo();
    currentQuantity = widget.cartItem.quantity!;
    simpleIntInput = 1;
    tableModel = context.read<TableModel>();
    cart = context.read<CartModel>();
  }

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    color = context.watch<ThemeColor>();
    return AlertDialog(
      title: Text(AppLocalizations.of(context)!.translate('adjust_quantity')),
      content: SizedBox(
        width: 350,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              //reason input
              Visibility(
                visible: appSettingModel.required_cancel_reason!,
                child: ReasonInputWidget(reasonCallBack: reasonCallBack),
              ),
              // quantity input
              QuantityInputWidget(
                cartItemList: [widget.cartItem],
                callback: qtyInputCallback,
              )
            ],
          ),
        ),
      ),
      actions: <Widget>[
        SizedBox(
          width: MediaQuery.of(context).size.width > 900 && MediaQuery.of(context).size.height > 500 ? MediaQuery.of(context).size.width / 6 : MediaQuery.of(context).size.width / 4,
          height: MediaQuery.of(context).size.width > 900 && MediaQuery.of(context).size.height > 500
              ? MediaQuery.of(context).size.height / 12
              : MediaQuery.of(context).orientation == Orientation.landscape ? MediaQuery.of(context).size.height / 10
              : MediaQuery.of(context).size.height / 20,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: color.backgroundColor,
            ),
            child: Text(
              AppLocalizations.of(context)!.translate('close'),
              style: TextStyle(color: Colors.white),
            ),
            onPressed: () {
              setState(() {
                isButtonDisabled = true;
              });
              Navigator.of(context).pop();
              setState(() {
                isButtonDisabled = false;
              });
            },
          ),
        ),
        SizedBox(
          width: MediaQuery.of(context).size.width > 900 && MediaQuery.of(context).size.height > 500 ? MediaQuery.of(context).size.width / 6 : MediaQuery.of(context).size.width / 4,
          height: MediaQuery.of(context).size.width > 900 && MediaQuery.of(context).size.height > 500
              ? MediaQuery.of(context).size.height / 12
              : MediaQuery.of(context).orientation == Orientation.landscape ? MediaQuery.of(context).size.height / 10
              : MediaQuery.of(context).size.height / 20,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: color.buttonColor,
            ),
            child: Text(
              AppLocalizations.of(context)!.translate('yes'),
              style: TextStyle(color: Colors.white),
            ),
            onPressed: isButtonDisabled ? null : cancelOnPressed,
          ),
        ),
      ],
    );
  }

  qtyInputCallback({bool? restock, num? qty}){
    simpleIntInput = qty ?? this.simpleIntInput;
    this.restock = restock ?? this.restock;
  }

  reasonCallBack(String reason){
    this.reason = reason;
  }

  cancelOnPressed() async {
    setState(() {
      isButtonDisabled = true;
    });
    if(appSettingModel.required_cancel_reason! == true && reason == ''){
      CustomFailedToast.showToast(title: AppLocalizations.of(context)!.translate('reason_required'));
      setState(() {
        isButtonDisabled = false;
      });
      return;
    }
    if(simpleIntInput != 0 && simpleIntInput != 0.00){
      DateFormat dateFormat = DateFormat("yyyy-MM-dd HH:mm:ss");
      String dateTime = dateFormat.format(DateTime.now());
      final prefs = await SharedPreferences.getInstance();
      final String? pos_user = prefs.getString('pos_pin_user');
      Map<String, dynamic> userMap = json.decode(pos_user!);
      User userData = User.fromJson(userMap);
      if(simpleIntInput > widget.cartItem.quantity!){
        Fluttertoast.showToast(
            backgroundColor: Color(0xFFFF0000),
            msg: AppLocalizations.of(context)!.translate('quantity_invalid'));
        setState(() {
          isButtonDisabled = false;
        });
      } else {
        if(userData.edit_price_without_pin != 1) {
          Navigator.of(context).pop();
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => CustomPinDialog(
              permission: Permission.editPrice,
              callback: () async => await callUpdateCart(userData, dateTime, cart),
            ),
          );
        } else {
          await callUpdateCart(userData, dateTime, cart);
        }
      }
    } else{ //no changes
      Navigator.of(context).pop();
    }
  }

  getFinalQuantity() {
    num temp = currentQuantity;
    try {
      temp -= simpleIntInput;
    } catch (e) {}
    return widget.cartItem.unit! != 'each' && widget.cartItem.unit != 'each_c' ? temp.toStringAsFixed(2) : temp;
  }

  readAllPrinters() async {
    await _printReceipt.readAllPrinters();
  }

  readCartItemInfo() async {
    //get cart item order cache
    List<OrderCache> cacheData = await posDatabase.readSpecificOrderCache(widget.cartItem.order_cache_sqlite_id!);
    cartCacheList = List.from(cacheData);

    if (widget.currentPage != 'other order') {
      //get table use order cache
      List<OrderCache> tableCacheData = await posDatabase.readTableOrderCache(cacheData[0].table_use_key!);
      cartTableCacheList = List.from(tableCacheData);

      //get table use detail
      List<TableUseDetail> tableDetailData = await posDatabase.readAllTableUseDetail(cacheData[0].table_use_sqlite_id!);
      cartTableUseDetail = List.from(tableDetailData);
    }

    //get cart item order cache order detail
    List<OrderDetail> orderDetailData = await posDatabase.readTableOrderDetail(widget.cartItem.order_cache_key!);
    cartOrderDetailList = List.from(orderDetailData);

    OrderDetail cartItemOrderDetail = await posDatabase.readSpecificOrderDetailByLocalId(int.parse(widget.cartItem.order_detail_sqlite_id!));
    orderDetail = cartItemOrderDetail;

    //get modifier detail length
    List<OrderModifierDetail> orderModData = await posDatabase.readOrderModifierDetail(widget.cartItem.order_detail_sqlite_id!);
    cartOrderModDetailList = List.from(orderModData);
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

  callUpdateCart(User userData, String dateTime, CartModel cart) async {
    var db = await posDatabase.database;
    List<String> _posTableValue = [];
    int updateStatus = await db.transaction((txn) async {
      try {
        final cancelQuery = CancelQuery(
            transaction: txn,
            user: userData,
            orderDetail: this.orderDetail,
            simpleIntInput: this.simpleIntInput,
            widgetCartItem: widget.cartItem,
            reason: this.reason,
            restock: restock
        );
        if (simpleIntInput == widget.cartItem.quantity || (widget.cartItem.unit != 'each' && widget.cartItem.unit != 'each_c')) {
          if (cartTableCacheList.length <= 1 && cartOrderDetailList.length > 1) {
            await cancelQuery.callDeleteOrderDetail();
            // await callDeleteOrderDetail(userData, dateTime, cancelQuery);

          } else if (cartTableCacheList.length > 1 && cartOrderDetailList.length <= 1) {
            await cancelQuery.callDeleteOrderDetail(deleteOrderCache: true, cartOrderCache: cartCacheList.first);
            // await callDeletePartialOrder(userData, dateTime, cancelQuery);

          } else if (cartTableCacheList.length > 1 && cartOrderDetailList.length > 1) {
            await cancelQuery.callDeleteOrderDetail();
            // await callDeleteOrderDetail(userData, dateTime, cancelQuery);

          } else if (widget.currentPage == 'other order' && cartOrderDetailList.length > 1) {
            await cancelQuery.callDeleteOrderDetail();
            // await callDeleteOrderDetail(userData, dateTime, cancelQuery);

          } else {
            await cancelQuery.callDeleteAllOrder(
                currentTableUseId: cartCacheList.first.table_use_sqlite_id!,
                currentPage: widget.currentPage,
                orderCache: cartCacheList.first,
                cartTableUseDetail: cartTableUseDetail
            );
            cart.removeAllTable(notify: false);
            // await callDeleteAllOrder(userData, cartCacheList[0].table_use_sqlite_id!, dateTime, cancelQuery);
            // if (widget.currentPage != 'other order') {
            //   await cancelQuery.updatePosTableStatus(cartTableUseDetail: cartTableUseDetail);
            //   await updatePosTableStatus(dateTime, cancelQuery);
            //   cart.removeAllTable(notify: false);
            // }
          }
          cart.removeItem(widget.cartItem);
        } else {
          await cancelQuery.callUpdateOrderDetail();
          // await callUpdateOrderDetail(userData, dateTime, cancelQuery);
          await cart.updateItemQty(widget.cartItem, cancelQuery, notify: true);
        }
        return 1;
      }catch(e, stackTrace){
        FLog.error(
          className: "adjust_qty_dialog",
          text: "transaction error",
          exception: "Error: $e, StackTrace: $stackTrace",
        );
        Navigator.of(context).pop();
        rethrow;
      }
    });
    print("update status: ${updateStatus}");
    try{
      if(updateStatus == 1){
        syncToFirestore();
        callPrinter(dateTime, cart);
        Fluttertoast.showToast(backgroundColor: Color(0xFF24EF10), msg: AppLocalizations.of(globalContext)!.translate('delete_successful'));
        tableModel.changeContent(true);
        if(mounted){
          Navigator.of(context).pop();
        }
      }
    }catch(e, stackTrace){
      FLog.error(
        className: "adjust_qty_dialog",
        text: "callUpdateCart error",
        exception: "Error: $e, StackTrace: $stackTrace",
      );
    }
    // cart.removeAllTable();
    // cart.removeAllCartItem();
    // cart.removeItem(widget.cartItem!);
    // cart.removePromotion();
    // syncAllToCloud();
  }

  syncToFirestore() async {
    try{
      OrderDetail orderDetailData = await posDatabase.readSpecificOrderDetailByLocalId(orderDetail.order_detail_sqlite_id!);
      OrderCache? orderCacheData = await posDatabase.readSpecificOrderCacheByKey(orderDetail.order_cache_key!);
      BranchLinkProduct? branchLinkProductData = await posDatabase.readSpecificBranchLinkProduct2(orderDetail.branch_link_product_sqlite_id!.toString());
      if(restock && branchLinkProductData!.stock_type != 3){
        _posFirestore.insertBranchLinkProduct(branchLinkProductData);
      }
      if(orderCacheData!.qr_order == 1){
        _firestoreQROrderSync.updateOrderDetailAndOrderCache(orderDetailData, orderCacheData);
      }
    }catch(e, stackTrace){
      FLog.error(
        className: "adjust_qty_dialog",
        text: "syncToFirestore error",
        exception: "Error: $e, StackTrace: $stackTrace",
      );
      rethrow;
    }
  }

  callPrinter(String dateTime, CartModel cart) async {
    try{
      if(appSettingModel.autoPrintCancelReceipt!){
        int printStatus = await _printReceipt.printCancelReceipt(widget.cartItem.order_cache_sqlite_id!, dateTime);
        if (printStatus == 1) {
          Fluttertoast.showToast(
              backgroundColor: Colors.red,
              msg:
              "${AppLocalizations.of(globalContext)?.translate('printer_not_connected')}");
        } else if (printStatus == 2) {
          Fluttertoast.showToast(
              backgroundColor: Colors.orangeAccent,
              msg:
              "${AppLocalizations.of(globalContext)?.translate('printer_connection_timeout')}");
        }
        int kitchenPrintStatus = await _printReceipt.printKitchenDeleteList(
            widget.cartItem.order_cache_sqlite_id!,
            widget.cartItem.category_sqlite_id!,
            dateTime,
        );
        if (kitchenPrintStatus == 1) {
          Fluttertoast.showToast(
              backgroundColor: Colors.red,
              msg:
              "${AppLocalizations.of(globalContext)?.translate('printer_not_connected')}");
        } else if (kitchenPrintStatus == 2) {
          Fluttertoast.showToast(
              backgroundColor: Colors.orangeAccent,
              msg:
              "${AppLocalizations.of(globalContext)?.translate('printer_connection_timeout')}");
        }
      }
    }catch(e, stackTrace){
      FLog.error(
        className: "adjust_qty_dialog",
        text: "callPrinter error",
        exception: "Error: $e, StackTrace: $stackTrace",
      );
      rethrow;
    }
  }

  // callUpdateOrderDetail(User user, String dateTime, CancelQuery cancelQuery) async {
  //   await createOrderDetailCancel(user, dateTime, cancelQuery);
  //   await updateOrderDetailQuantity(dateTime, cancelQuery);
  // }

  generateOrderDetailCancelKey(OrderDetailCancel orderDetailCancel) async {
    final prefs = await SharedPreferences.getInstance();
    final int? device_id = prefs.getInt('device_id');
    var bytes =
        orderDetailCancel.created_at!.replaceAll(new RegExp(r'[^0-9]'), '') +
            orderDetailCancel.order_detail_cancel_sqlite_id.toString() +
            device_id.toString();
    return md5.convert(utf8.encode(bytes)).toString();
  }

  // insertOrderDetailCancelKey(OrderDetailCancel orderDetailCancel, String dateTime, CancelQuery cancelQuery) async {
  //   try{
  //     OrderDetailCancel? data;
  //     String? key = await generateOrderDetailCancelKey(orderDetailCancel);
  //     if (key != null) {
  //       OrderDetailCancel object = OrderDetailCancel(
  //           order_detail_cancel_key: key,
  //           sync_status: 0,
  //           updated_at: dateTime,
  //           order_detail_cancel_sqlite_id:
  //           orderDetailCancel.order_detail_cancel_sqlite_id);
  //       int uniqueKey = await cancelQuery.updateOrderDetailCancelUniqueKey(object);
  //       // await posDatabase.updateOrderDetailCancelUniqueKey(object);
  //       if (uniqueKey == 1) {
  //         // OrderDetailCancel orderDetailCancelData = await posDatabase.readSpecificOrderDetailCancelByLocalId(object.order_detail_cancel_sqlite_id!);
  //         data = orderDetailCancel.copy(
  //           order_detail_cancel_key: object.order_detail_cancel_key,
  //           sync_status: object.sync_status,
  //           updated_at: object.updated_at
  //         );
  //       }
  //     }
  //     return data;
  //   }catch(e, stackTrace){
  //     FLog.error(
  //       className: "adjust_qty_dialog",
  //       text: "insertOrderDetailCancelKey error",
  //       exception: "Error: $e, StackTrace: $stackTrace",
  //     );
  //     rethrow;
  //   }
  // }

  // createOrderDetailCancel(User user, String dateTime, CancelQuery cancelQuery) async {
  //   try{
  //     List<String> _value = [];
  //     // OrderDetail data = await cancelQuery.readSpecificOrderDetailByLocalId(int.parse(widget.cartItem.order_detail_sqlite_id!));
  //     // OrderDetail data = await posDatabase.readSpecificOrderDetailByLocalId(int.parse(widget.cartItem.order_detail_sqlite_id!));
  //     OrderDetailCancel object = OrderDetailCancel(
  //       order_detail_cancel_id: 0,
  //       order_detail_cancel_key: '',
  //       order_detail_sqlite_id: widget.cartItem.order_detail_sqlite_id,
  //       order_detail_key: orderDetail.order_detail_key,
  //       quantity: simpleIntInput.toString(),
  //       quantity_before_cancel: widget.cartItem.quantity! is double ?
  //       widget.cartItem.quantity!.toStringAsFixed(2): widget.cartItem.quantity!.toString(),
  //       cancel_by: user.name,
  //       cancel_by_user_id: user.user_id.toString(),
  //       cancel_reason: reason,
  //       settlement_sqlite_id: '',
  //       settlement_key: '',
  //       status: 0,
  //       sync_status: 0,
  //       created_at: dateTime,
  //       updated_at: '',
  //       soft_delete: '',
  //     );
  //     OrderDetailCancel orderDetailCancel = await cancelQuery.insertSqliteOrderDetailCancel(object);
  //     // OrderDetailCancel orderDetailCancel = await posDatabase.insertSqliteOrderDetailCancel(object);
  //     OrderDetailCancel updateData = await insertOrderDetailCancelKey(orderDetailCancel, dateTime, cancelQuery);
  //     // _value.add(jsonEncode(updateData));
  //     // order_detail_cancel_value = _value.toString();
  //     //syncOrderDetailCancelToCloud(_value.toString());
  //   }catch(e, stackTrace){
  //     FLog.error(
  //       className: "adjust_qty_dialog",
  //       text: "insertOrderDetailCancelKey error",
  //       exception: "Error: $e, StackTrace: $stackTrace",
  //     );
  //     rethrow;
  //   }
  // }

  // syncOrderDetailCancelToCloud(String value) async {
  //   bool _hasInternetAccess = await Domain().isHostReachable();
  //   if (_hasInternetAccess) {
  //     Map response = await Domain().SyncOrderDetailCancelToCloud(value);
  //     if (response['status'] == '1') {
  //       List responseJson = response['data'];
  //       int data = await posDatabase.updateOrderDetailCancelSyncStatusFromCloud(responseJson[0]['order_detail_cancel_key']);
  //     }
  //   }
  // }

  String getTotalQty(){
    num totalQty = 0;
    if(widget.cartItem.unit != 'each' && widget.cartItem.unit != 'each_c'){
      if(simpleIntInput != 0){
        totalQty = 0;
      }
    } else {
      totalQty = widget.cartItem.quantity! - simpleIntInput;
    }
    print("total qty: ${totalQty}");
    return totalQty.toString();
  }

  // updateOrderDetailQuantity(String dateTime, CancelQuery cancelQuery) async {
  //   List<String> _value = [];
  //   try{
  //     OrderDetail orderDetail = OrderDetail(
  //       updated_at: dateTime,
  //       sync_status: this.orderDetail.sync_status == 0 ? 0 : 2,
  //       status: 0,
  //       quantity: getTotalQty(),
  //       order_detail_sqlite_id: int.parse(widget.cartItem.order_detail_sqlite_id!),
  //       branch_link_product_sqlite_id: widget.cartItem.branch_link_product_sqlite_id,
  //     );
  //     // updateOrderDetailQuantity
  //     num data = await cancelQuery.updateOrderDetailQuantity(orderDetail);
  //     // num data = await posDatabase.updateOrderDetailQuantity(orderDetail);
  //     if (data == 1) {
  //       // readSpecificOrderDetailByLocalId
  //       OrderDetail updatedOrderDetail = await cancelQuery.readSpecificOrderDetailByLocalId(orderDetail.order_detail_sqlite_id!);
  //       // OrderDetail detailData = await posDatabase.readSpecificOrderDetailByLocalId(orderDetail.order_detail_sqlite_id!);
  //       OrderCache? orderCache = await updateOrderCacheSubtotal(updatedOrderDetail.order_cache_sqlite_id!, updatedOrderDetail.price!, simpleIntInput, dateTime, cancelQuery);
  //       if(restock){
  //         await updateProductStock(updatedOrderDetail.branch_link_product_sqlite_id!, simpleIntInput, dateTime, cancelQuery);
  //       }
  //       // _firestoreQROrderSync.updateOrderDetailAndCacheSubtotal(updatedOrderDetail, orderCache!);
  //       _value.add(jsonEncode(updatedOrderDetail.syncJson()));
  //     }
  //     order_detail_value = _value.toString();
  //   }catch(e, stackTrace){
  //     FLog.error(
  //       className: "adjust_qty_dialog",
  //       text: "updateOrderDetailQuantity error",
  //       exception: "Error: $e, StackTrace: $stackTrace",
  //     );
  //     rethrow;
  //   }
  // }

  String getSubtotal(double totalAmount, String price, num quantity){
    double subtotal = 0.0;
    if(widget.cartItem.unit != 'each' && widget.cartItem.unit != 'each_c'){
      subtotal = totalAmount - double.parse(price);
    } else {
      subtotal = totalAmount - double.parse(price) * quantity;
    }
    print("subtotal: ${subtotal.toStringAsFixed(2)}");
    return subtotal.toStringAsFixed(2);
  }

  // Future<OrderCache?> updateOrderCacheSubtotal(String orderCacheLocalId, String price, num quantity, String dateTime, CancelQuery cancelQuery) async {
  //   try{
  //     // readSpecificOrderCacheByLocalId
  //     OrderCache data = await cancelQuery.readSpecificOrderCacheByLocalId(int.parse(orderCacheLocalId));
  //     // OrderCache data = await posDatabase.readSpecificOrderCacheByLocalId(int.parse(orderCacheLocalId));
  //     OrderCache orderCache = data.copy(
  //         order_cache_sqlite_id: data.order_cache_sqlite_id,
  //         total_amount: getSubtotal(double.parse(data.total_amount!), price, quantity),
  //         sync_status: data.sync_status == 0 ? 0 : 2,
  //         updated_at: dateTime);
  //     // updateOrderCacheSubtotal
  //     int status = await cancelQuery.updateOrderCacheSubtotal(orderCache);
  //     if (status == 1) {
  //       return data;
  //     } else {
  //       return null;
  //     }
  //     // int status = await posDatabase.updateOrderCacheSubtotal(orderCache);
  //     // if (status == 1) {
  //     //   getOrderCacheValue(orderCache);
  //     // }
  //   }catch(e, stackTrace){
  //     FLog.error(
  //       className: "adj_quantity",
  //       text: "updateOrderCacheSubtotal error",
  //       exception: "Error: $e, StackTrace: $stackTrace",
  //     );
  //     rethrow;
  //   }
  // }

  // syncUpdatedPosTableToCloud(String posTableValue) async {
  //   bool _hasInternetAccess = await Domain().isHostReachable();
  //   if(_hasInternetAccess){
  //     Map response = await Domain().SyncUpdatedPosTableToCloud(posTableValue);
  //     if (response['status'] == '1') {
  //       List responseJson = response['data'];
  //       for (var i = 0; i < responseJson.length; i++) {
  //         int syncData = await posDatabase.updatePosTableSyncStatusFromCloud(responseJson[i]['table_id']);
  //       }
  //     }
  //   }
  // }

  // callDeleteOrderDetail(User user, String dateTime, CancelQuery cancelQuery) async {
  //   try{
  //     await createOrderDetailCancel(user, dateTime, cancelQuery);
  //     await updateOrderDetailQuantity(dateTime, cancelQuery);
  //     List<String> _value = [];
  //     OrderDetail orderDetailObject = OrderDetail(
  //       updated_at: dateTime,
  //       sync_status: orderDetail.sync_status == 0 ? 0 : 2,
  //       status: 1,
  //       cancel_by: user.name,
  //       cancel_by_user_id: user.user_id.toString(),
  //       order_detail_sqlite_id: int.parse(widget.cartItem.order_detail_sqlite_id!),
  //     );
  //     int deleteOrderDetailData = await cancelQuery.updateOrderDetailStatus(orderDetailObject);
  //     // int deleteOrderDetailData = await posDatabase.updateOrderDetailStatus(orderDetailObject);
  //     // if (deleteOrderDetailData == 1) {
  //     //   //await updateProductStock(orderDetailObject.branch_link_product_sqlite_id!, int.parse(orderDetailObject.quantity!), dateTime);
  //     //   //sync to cloud
  //     //   OrderDetail detailData = await cancelQuery.readSpecificOrderDetailByLocalId(orderDetailObject.order_detail_sqlite_id!);
  //     //   OrderDetail detailData = await posDatabase.readSpecificOrderDetailByLocalId(orderDetailObject.order_detail_sqlite_id!);
  //     //   _value.add(jsonEncode(detailData.syncJson()));
  //     //   order_detail_value = _value.toString();
  //     //   print('value: ${_value.toString()}');
  //     // }
  //     //syncUpdatedOrderDetailToCloud(_value.toString());
  //   }catch(e, stackTrace){
  //     FLog.error(
  //       className: "adjust_qty_dialog",
  //       text: "callDeleteOrderDetail error",
  //       exception: "Error: $e, StackTrace: $stackTrace",
  //     );
  //     rethrow;
  //   }
  // }

  // updateProductStock(String branch_link_product_sqlite_id, num quantity, String dateTime, CancelQuery cancelQuery) async {
  //   List<String> _value = [];
  //   num _totalStockQty = 0, updateStock = 0;
  //   BranchLinkProduct? object;
  //   try{
  //     // readSpecificBranchLinkProduct
  //     List<BranchLinkProduct> checkData = await cancelQuery.readSpecificBranchLinkProduct(branch_link_product_sqlite_id);
  //     // List<BranchLinkProduct> checkData = await posDatabase.readSpecificBranchLinkProduct(branch_link_product_sqlite_id);
  //     if(checkData.isNotEmpty){
  //       switch(checkData.first.stock_type){
  //         case '1': {
  //           _totalStockQty = int.parse(checkData[0].daily_limit!) + quantity;
  //           object = checkData.first.copy(
  //               updated_at: dateTime,
  //               sync_status: 2,
  //               daily_limit: _totalStockQty.toString(),
  //               branch_link_product_sqlite_id: int.parse(branch_link_product_sqlite_id));
  //           updateStock = await cancelQuery.updateBranchLinkProductDailyLimit(object);
  //           // updateStock = await posDatabase.updateBranchLinkProductDailyLimit(object);
  //         }break;
  //         case'2': {
  //           _totalStockQty = int.parse(checkData[0].stock_quantity!) + quantity;
  //           object = checkData.first.copy(
  //               updated_at: dateTime,
  //               sync_status: 2,
  //               stock_quantity: _totalStockQty.toString(),
  //               branch_link_product_sqlite_id: int.parse(branch_link_product_sqlite_id));
  //           updateStock = await cancelQuery.updateBranchLinkProductStock(object);
  //           // updateStock = await posDatabase.updateBranchLinkProductStock(object);
  //         }break;
  //         default: {
  //           updateStock = 0;
  //         }
  //       }
  //       // if (updateStock == 1) {
  //       //   List<BranchLinkProduct> updatedData = await posDatabase.readSpecificBranchLinkProduct(branch_link_product_sqlite_id);
  //       //   _value.add(jsonEncode(updatedData[0]));
  //       //   branch_link_product_value = _value.toString();
  //       // }
  //     }
  //   }catch(e, stackTrace){
  //     FLog.error(
  //       className: "cancel query",
  //       text: "updateProductStock error",
  //       exception: "Error: $e, StackTrace: $stackTrace",
  //     );
  //     rethrow;
  //   }
  //
  //   //print('branch link product value in function: ${branch_link_product_value}');
  //   //sync to cloud
  //   //syncBranchLinkProductStock(value.toString());
  // }

  // syncBranchLinkProductStock(String value) async {
  //   bool _hasInternetAccess = await Domain().isHostReachable();
  //   if(_hasInternetAccess) {
  //     Map orderDetailResponse = await Domain().SyncBranchLinkProductToCloud(value);
  //     if (orderDetailResponse['status'] == '1') {
  //       List responseJson = orderDetailResponse['data'];
  //       for (int i = 0; i < responseJson.length; i++) {
  //         int syncUpdated = await posDatabase.updateBranchLinkProductSyncStatusFromCloud(responseJson[i]['branch_link_product_id']);
  //       }
  //     }
  //   }
  // }

  // syncUpdatedOrderDetailToCloud(String value) async {
  //   bool _hasInternetAccess = await Domain().isHostReachable();
  //   if(_hasInternetAccess){
  //     Map response = await Domain().SyncOrderDetailToCloud(value.toString());
  //     if (response['status'] == '1') {
  //       List responseJson = response['data'];
  //       int orderDetailData = await posDatabase.updateOrderDetailSyncStatusFromCloud(responseJson[0]['order_detail_key']);
  //     }
  //   }
  // }

  // callDeleteAllOrder(User user, String currentTableUseId, String dateTime, CancelQuery cancelQuery) async {
  //   try{
  //     print('delete all order called');
  //     if (widget.currentPage != 'other_order') {
  //       await deleteCurrentTableUseDetail(currentTableUseId, dateTime, cancelQuery);
  //       await deleteCurrentTableUseId(int.parse(currentTableUseId), dateTime, cancelQuery);
  //     }
  //     await callDeleteOrderDetail(user, dateTime, cancelQuery);
  //     await deleteCurrentOrderCache(user, dateTime, cancelQuery);
  //   }catch(e, stackTrace){
  //     FLog.error(
  //       className: "adjust_qty_dialog",
  //       text: "callDeleteAllOrder error",
  //       exception: "Error: $e, StackTrace: $stackTrace",
  //     );
  //     rethrow;
  //   }
  // }

  // callDeletePartialOrder(User user, String dateTime, CancelQuery cancelQuery) async {
  //   try{
  //     await callDeleteOrderDetail(user, dateTime, cancelQuery);
  //     await deleteCurrentOrderCache(user, dateTime, cancelQuery);
  //   }catch(e, stackTrace){
  //     FLog.error(
  //       className: "adjust_qty_dialog",
  //       text: "callDeletePartialOrder error",
  //       exception: "Error: $e, StackTrace: $stackTrace",
  //     );
  //     rethrow;
  //   }
  // }

  // updatePosTableStatus(String dateTime, CancelQuery cancelQuery) async {
  //   try{
  //     // PosTable? _data;
  //     for (int i = 0; i < cartTableUseDetail.length; i++) {
  //       //update all table to unused
  //       PosTable posTableData = PosTable(
  //         table_use_detail_key: '',
  //         table_use_key: '',
  //         status: 0,
  //         updated_at: dateTime,
  //         table_sqlite_id: int.parse(cartTableUseDetail[i].table_sqlite_id!),
  //       );
  //       int updatedStatus = await cancelQuery.updatePosTableStatus(posTableData);
  //       // int updatedStatus = await posDatabase.updatePosTableStatus(posTableData);
  //       // int removeKey = await posDatabase.removePosTableTableUseDetailKey(posTableData);
  //       // if (updatedStatus == 1) {
  //       //   List<PosTable> posTable = await posDatabase.readSpecificTable(posTableData.table_sqlite_id.toString());
  //       //   if (posTable[0].sync_status == 2) {
  //       //     _data = posTable[0];
  //       //   }
  //       // }
  //       // _posTableValue.add(jsonEncode(posTableData));
  //     }
  //     // table_value = _posTableValue.toString();
  //     // return _data;
  //   }catch(e, stackTrace){
  //     FLog.error(
  //       className: "adjust_qty_dialog",
  //       text: "updatePosTableStatus error",
  //       exception: "Error: $e, StackTrace: $stackTrace",
  //     );
  //     rethrow;
  //   }
  // }

  // deleteCurrentOrderCache(User user, String dateTime, CancelQuery cancelQuery) async {
  //   print('delete order cache called');
  //   List<String> _orderCacheValue = [];
  //   try {
  //     OrderCache orderCacheObject = OrderCache(
  //         sync_status: cartCacheList[0].sync_status == 0 ? 0 : 2,
  //         cancel_by: user.name,
  //         cancel_by_user_id: user.user_id.toString(),
  //         order_cache_sqlite_id: int.parse(widget.cartItem.order_cache_sqlite_id!),
  //     );
  //     int deletedOrderCache = await cancelQuery.cancelOrderCache(orderCacheObject);
  //     // int deletedOrderCache = await posDatabase.cancelOrderCache(orderCacheObject);
  //     //sync to cloud
  //     // if (deletedOrderCache == 1) {
  //     //   // await getOrderCacheValue(orderCacheObject);
  //     //   // OrderCache orderCacheData = await posDatabase.readSpecificOrderCacheByLocalId(orderCacheObject.order_cache_sqlite_id!);
  //     //   // if(orderCacheData.sync_status != 1){
  //     //   //   _orderCacheValue.add(jsonEncode(orderCacheData));
  //     //   // }
  //     //   // order_cache_value = _orderCacheValue.toString();
  //     //   //syncOrderCacheToCloud(_orderCacheValue.toString());
  //     // }
  //   }catch(e, stackTrace){
  //     FLog.error(
  //       className: "adjust_qty_dialog",
  //       text: "deleteCurrentOrderCache error",
  //       exception: "Error: $e, StackTrace: $stackTrace",
  //     );
  //     rethrow;
  //   }
  // }

  getOrderCacheValue(OrderCache orderCacheObject) async {
    List<String> _orderCacheValue = [];
    OrderCache orderCacheData = await posDatabase
        .readSpecificOrderCacheByLocalId(
        orderCacheObject.order_cache_sqlite_id!);
    if (orderCacheData.sync_status != 1) {
      _orderCacheValue.add(jsonEncode(orderCacheData));
    }
    order_cache_value = _orderCacheValue.toString();
  }

  // syncOrderCacheToCloud(String value) async {
  //   bool _hasInternetAccess = await Domain().isHostReachable();
  //   if (_hasInternetAccess) {
  //     Map response = await Domain().SyncOrderCacheToCloud(value);
  //     if(response['status'] == '1'){
  //       List responseJson = response['data'];
  //       int syncData = await posDatabase.updateOrderCacheSyncStatusFromCloud(responseJson[0]['order_cache_key']);
  //     }
  //   }
  // }

  // deleteCurrentTableUseDetail(String currentTableUseId, String dateTime, CancelQuery cancelQuery) async {
  //   List<String> _value = [];
  //   try {
  //     List<TableUseDetail> checkData = await cancelQuery.readAllTableUseDetail(currentTableUseId);
  //     // List<TableUseDetail> checkData = await posDatabase.readAllTableUseDetail(currentTableUseId);
  //     for (int i = 0; i < checkData.length; i++) {
  //       TableUseDetail tableUseDetailObject = checkData[i].copy(
  //           updated_at: dateTime,
  //           sync_status: checkData[i].sync_status == 0 ? 0 : 2,
  //           status: 1,
  //       );
  //       int deleteStatus = await cancelQuery.deleteTableUseDetail(tableUseDetailObject);
  //       // int deleteStatus = await posDatabase.deleteTableUseDetail(tableUseDetailObject);
  //       if (deleteStatus == 1) {
  //         _value.add(jsonEncode(tableUseDetailObject));
  //         table_use_detail_value = _value.toString();
  //       }
  //     }
  //     //sync to cloud
  //     //syncTableUseDetail(_value.toString());
  //   } catch(e, stackTrace){
  //     FLog.error(
  //       className: "adjust_qty_dialog",
  //       text: "deleteCurrentTableUseDetail error",
  //       exception: "Error: $e, StackTrace: $stackTrace",
  //     );
  //     rethrow;
  //   }
  // }

  // syncTableUseDetail(String value) async {
  //   bool _hasInternetAccess = await Domain().isHostReachable();
  //   if(_hasInternetAccess){
  //     Map data = await Domain().SyncTableUseDetailToCloud(value);
  //     if(data['status'] == '1'){
  //       List responseJson = data['data'];
  //       for (var i = 0; i < responseJson.length; i++) {
  //         int tablaUseDetailData = await posDatabase.updateTableUseDetailSyncStatusFromCloud(responseJson[i]['table_use_detail_key']);
  //       }
  //     }
  //   }
  // }

  // deleteCurrentTableUseId(int currentTableUseId, String dateTime, CancelQuery cancelQuery) async {
  //   List<String> _value = [];
  //   try {
  //     TableUse? checkData = await cancelQuery.readSpecificTableUseIdByLocalId(currentTableUseId);
  //     // TableUse checkData = await posDatabase.readSpecificTableUseIdByLocalId(currentTableUseId);
  //     TableUse tableUseObject = checkData!.copy(
  //       updated_at: dateTime,
  //       sync_status: checkData.sync_status == 0 ? 0 : 2,
  //       status: 1,
  //     );
  //     int deletedTableUse = await cancelQuery.deleteTableUseID(tableUseObject);
  //     // int deletedTableUse = await posDatabase.deleteTableUseID(tableUseObject);
  //     if (deletedTableUse == 1) {
  //       //sync to cloud
  //       // TableUse tableUseData = await posDatabase.readSpecificTableUseIdByLocalId(tableUseObject.table_use_sqlite_id!);
  //       _value.add(jsonEncode(tableUseObject));
  //       table_use_value = _value.toString();
  //       //syncTableUseIdToCloud(_value.toString());
  //     }
  //   } catch(e, stackTrace){
  //     FLog.error(
  //       className: "adjust_qty_dialog",
  //       text: "deleteCurrentTableUseId error",
  //       exception: "Error: $e, StackTrace: $stackTrace",
  //     );
  //     rethrow;
  //   }
  // }

  // syncTableUseIdToCloud(String value) async {
  //   bool _hasInternetAccess = await Domain().isHostReachable();
  //   if(_hasInternetAccess){
  //     Map data = await Domain().SyncTableUseToCloud(value);
  //     if (data['status'] == '1') {
  //       List responseJson = data['data'];
  //       int tablaUseData = await posDatabase.updateTableUseSyncStatusFromCloud(responseJson[0]['table_use_key']);
  //     }
  //   }
  // }

  syncAllToCloud() async {
    try {
      if (mainSyncToCloud.count == 0) {
        mainSyncToCloud.count = 1;
        final prefs = await SharedPreferences.getInstance();
        final int? device_id = prefs.getInt('device_id');
        final String? login_value = prefs.getString('login_value');
        print(
            'branch link product value in sync: ${this.branch_link_product_value}');
        Map data = await Domain().syncLocalUpdateToCloud(
            device_id: device_id.toString(),
            value: login_value,
            table_use_value: this.table_use_value,
            table_use_detail_value: this.table_use_detail_value,
            order_cache_value: this.order_cache_value,
            order_detail_value: this.order_detail_value,
            order_detail_cancel_value: this.order_detail_cancel_value,
            branch_link_product_value: this.branch_link_product_value,
            table_value: this.table_value);
        //if success update local sync status
        if (data['status'] == '1') {
          List responseJson = data['data'];
          if (responseJson.isNotEmpty) {
            for (int i = 0; i < responseJson.length; i++) {
              switch (responseJson[i]['table_name']) {
                case 'tb_table_use_detail':
                  {
                    await posDatabase
                        .updateTableUseDetailSyncStatusFromCloud(
                        responseJson[i]['table_use_detail_key']);
                  }
                  break;
                case 'tb_table_use':
                  {
                    await posDatabase
                        .updateTableUseSyncStatusFromCloud(
                        responseJson[i]['table_use_key']);
                  }
                  break;
                case 'tb_order_detail_cancel':
                  {
                    await posDatabase
                        .updateOrderDetailCancelSyncStatusFromCloud(
                        responseJson[i]['order_detail_cancel_key'], responseJson[i]['updated_at']);
                  }
                  break;
                case 'tb_branch_link_product':
                  {
                    await posDatabase
                        .updateBranchLinkProductSyncStatusFromCloud(
                        responseJson[i]['branch_link_product_id'], responseJson[i]['updated_at']);
                  }
                  break;
                case 'tb_order_detail':
                  {
                    await posDatabase
                        .updateOrderDetailSyncStatusFromCloud(
                        responseJson[i]['order_detail_key'], responseJson[i]['updated_at']);
                  }
                  break;
                case 'tb_order_cache':
                  {
                    await posDatabase
                        .updateOrderCacheSyncStatusFromCloud(
                        responseJson[i]['order_cache_key'], responseJson[i]['updated_at']);
                  }
                  break;
                case 'tb_table':
                  {
                    await posDatabase
                        .updatePosTableSyncStatusFromCloud(
                        responseJson[i]['table_id']);
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
          throw TimeoutException("Time out");
        } else {
          mainSyncToCloud.resetCount();
        }
        // bool _hasInternetAccess = await Domain().isHostReachable();
        // if (_hasInternetAccess) {
        //
        // } else {
        //   mainSyncToCloud.resetCount();
        // }
      }
    } catch (e) {
      print('adjust quantity sync to cloud error: $e');
      mainSyncToCloud.resetCount();
      //return 1;
    }
  }
}
