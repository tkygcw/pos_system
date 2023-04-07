import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_usb_printer/flutter_usb_printer.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';
import 'package:pos_system/fragment/cart/adjust_quantity.dart';
import 'package:pos_system/notifier/connectivity_change_notifier.dart';
import 'package:pos_system/object/cart_product.dart';
import 'package:pos_system/object/order_cache.dart';
import 'package:pos_system/object/order_modifier_detail.dart';
import 'package:pos_system/object/print_receipt.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:crypto/crypto.dart';

import '../../database/domain.dart';
import '../../database/pos_database.dart';
import '../../notifier/cart_notifier.dart';
import '../../notifier/table_notifier.dart';
import '../../notifier/theme_color.dart';
import '../../object/branch_link_product.dart';
import '../../object/order_detail.dart';
import '../../object/order_detail_cancel.dart';
import '../../object/printer.dart';
import '../../object/table.dart';
import '../../object/table_use.dart';
import '../../object/table_use_detail.dart';
import '../../object/user.dart';
import '../../translation/AppLocalizations.dart';
import '../logout_dialog.dart';

class CartRemoveDialog extends StatefulWidget {
  final cartProductItem? cartItem;
  final String currentPage;

  const CartRemoveDialog({Key? key, this.cartItem, required this.currentPage})
      : super(key: key);

  @override
  State<CartRemoveDialog> createState() => _CartRemoveDialogState();
}

class _CartRemoveDialogState extends State<CartRemoveDialog> {
  FlutterUsbPrinter flutterUsbPrinter = FlutterUsbPrinter();
  final adminPosPinController = TextEditingController();
  bool _submitted = false;
  List<User> adminData = [];
  List<Printer> printerList = [];
  List<OrderCache> cartCacheList = [], cartTableCacheList = [];
  List<OrderDetail> cartOrderDetailList = [];
  List<OrderModifierDetail> cartOrderModDetailList = [];
  List<TableUseDetail> cartTableUseDetail = [];
  OrderDetail? orderDetail;
  String? table_use_value, table_use_detail_value, branch_link_product_value, order_cache_value, order_detail_value, order_detail_cancel_value, table_value;
  bool _isLoaded = false, isLogOut = false;
  int simpleIntInput = 1;


  late TableModel tableModel;

  @override
  void initState() {
    super.initState();
    readAllPrinters();
    if(widget.currentPage != 'menu'){
      readCartItemInfo();
    }

  }

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
    adminPosPinController.dispose();
  }


  String? get errorPassword {
    final text = adminPosPinController.value.text;
    //readAdminData(text);
    if (text.isEmpty) {
      return 'password_required';
    }
    return null;
  }

  void _submit(BuildContext context, CartModel cart, ConnectivityChangeNotifier connectivity) async {
    setState(() => _submitted = true);
    if (errorPassword == null && _isLoaded == true) {
      await readAdminData(adminPosPinController.text, cart, connectivity);
      if(this.isLogOut == false){
        Navigator.of(context).pop();
        Navigator.of(context).pop();
      }
      return;
    }
  }

  closeDialog(BuildContext context) {
    return Navigator.of(context).pop(true);
  }

  Future showSecondDialog(BuildContext context, ThemeColor color, CartModel cart, ConnectivityChangeNotifier connectivity) {
    return showDialog(
      barrierDismissible: false,
      context: context,
      builder: (BuildContext context) => Center(
        child: SingleChildScrollView(
          physics: NeverScrollableScrollPhysics(),
          child: AlertDialog(
            title: Text('Enter Current User PIN'),
            content: SizedBox(
              height: 100.0,
              width: 350.0,
              child: ValueListenableBuilder(
                  valueListenable: adminPosPinController,
                  builder: (context, TextEditingValue value, __) {
                    return Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: TextField(
                        obscureText: true,
                        controller: adminPosPinController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          errorText: _submitted
                              ? errorPassword == null
                              ? errorPassword
                              : AppLocalizations.of(context)
                              ?.translate(errorPassword!)
                              : null,
                          border: OutlineInputBorder(
                            borderSide:
                            BorderSide(color: color.backgroundColor),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide:
                            BorderSide(color: color.backgroundColor),
                          ),
                          labelText: "PIN",
                        ),
                      ),
                    );
                  }),
            ),
            actions: <Widget>[
              TextButton(
                child: Text('${AppLocalizations.of(context)?.translate('close')}'),
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).pop();
                },
              ),
              TextButton(
                child: Text('${AppLocalizations.of(context)?.translate('yes')}'),
                onPressed: ()  {
                  _submit(context, cart, connectivity);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<Future<Object?>> openDialog({cartItem, currentPage}) async {
    return showGeneralDialog(
        barrierColor: Colors.black.withOpacity(0.5),
        transitionBuilder: (context, a1, a2, widget) {
          final curvedValue = Curves.easeInOutBack.transform(a1.value) - 1.0;
          return Transform(
            transform: Matrix4.translationValues(0.0, curvedValue * 200, 0.0),
            child: Opacity(
              opacity: a1.value,
              child: AdjustQuantityDialog(cartItem: cartItem, currentPage: currentPage,),
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

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeColor>(builder: (context, ThemeColor color, child) {
      return Consumer<ConnectivityChangeNotifier>(builder: (context, ConnectivityChangeNotifier connectivity, child) {
        return Consumer<CartModel>(builder: (context, CartModel cart, child) {
          return Consumer<TableModel>(builder: (context, TableModel tableModel, child) {
            this.tableModel = tableModel;
            return AlertDialog(
              title: Text('Confirm remove item ?'),
              content: Container(
                child: Row(
                  children: [
                    Text('${widget.cartItem!.name} ${AppLocalizations.of(context)?.translate('confirm_delete')}')
                  ],
                ),
              ),
              actions: <Widget>[
                TextButton(
                    child:
                    Text('${AppLocalizations.of(context)?.translate('no')}'),
                    onPressed: () {
                      Navigator.of(context).pop();
                    }),
                TextButton(
                    child:
                    Text('${AppLocalizations.of(context)?.translate('yes')}'),
                    onPressed: () async {
                      if (widget.currentPage == 'menu') {
                        cart.removeItem(widget.cartItem!);
                        if (cart.cartNotifierItem.isEmpty) {
                          cart.removeAllTable();
                        }
                        Navigator.of(context).pop();
                      } else {
                        if(widget.cartItem!.quantity == 1){
                          await showSecondDialog(context, color, cart, connectivity);
                        } else {
                          openDialog(cartItem: widget.cartItem, currentPage: widget.currentPage);
                          //await showAdjustQuantityDialog(context, color, cart, connectivity);
                        }                        //openCancelOrderDialog(widget.cartItem!);
                        //Navigator.of(context).pop();
                      }
                    })
              ],
            );
          });
        });
      });
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

  readCartItemInfo() async {
    final prefs = await SharedPreferences.getInstance();
    final int? branch_id = prefs.getInt('branch_id');
    //get cart item order cache
    List<OrderCache> cacheData = await PosDatabase.instance.readSpecificOrderCache(widget.cartItem!.orderCacheId!);
    cartCacheList = List.from(cacheData);

    if(widget.currentPage != 'other order'){
      //get table use order cache
      List<OrderCache> tableCacheData = await PosDatabase.instance.readTableOrderCache(branch_id.toString(), cacheData[0].table_use_sqlite_id!);
      cartTableCacheList = List.from(tableCacheData);

      //get table use detail
      List<TableUseDetail> tableDetailData = await PosDatabase.instance.readAllTableUseDetail(cacheData[0].table_use_sqlite_id!);
      cartTableUseDetail = List.from(tableDetailData);
    }

    //get cart item order cache order detail
    List<OrderDetail> orderDetailData = await PosDatabase.instance.readTableOrderDetail(widget.cartItem!.orderCacheId!);
    cartOrderDetailList = List.from(orderDetailData);

    OrderDetail cartItemOrderDetail = await PosDatabase.instance.readSpecificOrderDetailByLocalId(int.parse(widget.cartItem!.order_detail_sqlite_id!));
    orderDetail = cartItemOrderDetail;

    //get modifier detail length
    List<OrderModifierDetail> orderModData = await PosDatabase.instance.readOrderModifierDetail(widget.cartItem!.order_detail_sqlite_id!);
    cartOrderModDetailList = List.from(orderModData);

    _isLoaded = true;
  }

  readAdminData(String pin, CartModel cart, ConnectivityChangeNotifier connectivity) async {
    List<String> _posTableValue = [];
    List<String> _orderModDetailValue = [];
    bool _hasModifier = false;
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? pos_user = prefs.getString('pos_pin_user');
      Map userObject = json.decode(pos_user!);
      DateFormat dateFormat = DateFormat("yyyy-MM-dd HH:mm:ss");
      String dateTime = dateFormat.format(DateTime.now());

      //List<User> userData = await PosDatabase.instance.readSpecificUserWithRole(pin);
      User? userData = await PosDatabase.instance.readSpecificUserWithPin(pin);
      if (userData != null) {
        if (userData.user_id == userObject['user_id']) {

          if(cartTableCacheList.length <= 1 && cartOrderDetailList.length > 1){
            await callDeleteOrderDetail(userData, dateTime, cart);

          } else if(cartTableCacheList.length > 1 && cartOrderDetailList.length <= 1 ){
            await callDeletePartialOrder(userData, dateTime, cart, connectivity);

          } else if (cartTableCacheList.length > 1 && cartOrderDetailList.length > 1) {
            await callDeleteOrderDetail(userData, dateTime, cart);

          } else if(widget.currentPage == 'other order' && cartOrderDetailList.length > 1){
            await callDeleteOrderDetail(userData, dateTime, cart);

          } else {
            print('delete all called');
            await callDeleteAllOrder(userData, cartCacheList[0].table_use_sqlite_id!, dateTime, cart, connectivity);
            for (int i = 0; i < cartTableUseDetail.length; i++) {
              //update all table to unused
              PosTable posTableData = await updatePosTableStatus(int.parse(cartTableUseDetail[i].table_sqlite_id!), 0, dateTime);
              _posTableValue.add(jsonEncode(posTableData));
            }
          }
          table_value = _posTableValue.toString();
          //sync to cloud
          await syncAllToCloud();
          if(this.isLogOut == true){
            openLogOutDialog();
            return;
          }
          await PrintReceipt().printDeleteList(printerList, widget.cartItem!.orderCacheId!, dateTime);
          await PrintReceipt().printKitchenDeleteList(printerList, widget.cartItem!.orderCacheId!, widget.cartItem!.category_sqlite_id!, dateTime, cart);
          tableModel.changeContent(true);
          cart.removeAllTable();
          cart.removeAllCartItem();
          cart.removePromotion();
          // if(connectivity.isConnect){
          //
          //   //syncUpdatedPosTableToCloud(_posTableValue.toString());
          // }
          Fluttertoast.showToast(backgroundColor: Color(0xFF24EF10), msg: "delete successful");

        } else {
          Fluttertoast.showToast(
              backgroundColor: Color(0xFFFF0000), msg: "${AppLocalizations.of(context)?.translate('pin_not_match')}");
        }
      } else {
        Fluttertoast.showToast(
            backgroundColor: Color(0xFFFF0000), msg: "${AppLocalizations.of(context)?.translate('user_not_found')}");
      }

    } catch (e) {
      print('delete error ${e}');
    }
  }

  updateOrderDetailQuantity(String dateTime, CartModel cart) async {
    List<String> _value = [];
    OrderDetail orderDetailObject = OrderDetail(
        updated_at: dateTime,
        sync_status: orderDetail!.sync_status == 0 ? 0 : 2,
        status: 0,
        quantity: '0',
        order_detail_sqlite_id: int.parse(widget.cartItem!.order_detail_sqlite_id!),
        branch_link_product_sqlite_id: widget.cartItem!.branchProduct_id);

    int data = await PosDatabase.instance.updateOrderDetailQuantity(orderDetailObject);
    if(data == 1){
      OrderDetail detailData = await PosDatabase.instance.readSpecificOrderDetailByLocalId(orderDetailObject.order_detail_sqlite_id!);
      await updateProductStock(orderDetailObject.branch_link_product_sqlite_id!, 1, dateTime);
      _value.add(jsonEncode(detailData.syncJson()));
    }
    // order_detail_value = _value.toString();
    //syncUpdatedOrderDetailToCloud(_value.toString());
  }

  generateOrderDetailCancelKey(OrderDetailCancel orderDetailCancel) async {
    final prefs = await SharedPreferences.getInstance();
    final int? device_id = prefs.getInt('device_id');
    var bytes = orderDetailCancel.created_at!.replaceAll(new RegExp(r'[^0-9]'), '') +
        orderDetailCancel.order_detail_cancel_sqlite_id.toString() +
        device_id.toString();
    return md5.convert(utf8.encode(bytes)).toString();
  }

  insertOrderDetailCancelKey(OrderDetailCancel orderDetailCancel, String dateTime) async {
    OrderDetailCancel? data;
    String? key = await generateOrderDetailCancelKey(orderDetailCancel);
    if (key != null) {
      OrderDetailCancel object = OrderDetailCancel(
          order_detail_cancel_key: key,
          sync_status: 0,
          updated_at: dateTime,
          order_detail_cancel_sqlite_id: orderDetailCancel.order_detail_cancel_sqlite_id
      );
      int uniqueKey = await PosDatabase.instance.updateOrderDetailCancelUniqueKey(object);
      if (uniqueKey == 1) {
        OrderDetailCancel orderDetailCancelData = await PosDatabase.instance.readSpecificOrderDetailCancelByLocalId(object.order_detail_cancel_sqlite_id!);
        data = orderDetailCancelData;
      }
    }
    return data;
  }

  createOrderDetailCancel(User user, String dateTime) async {
    List<String> _value = [];
    OrderDetail data = await PosDatabase.instance.readSpecificOrderDetailByLocalId(int.parse(widget.cartItem!.order_detail_sqlite_id!));
    OrderDetailCancel object =  OrderDetailCancel(
      order_detail_cancel_id: 0,
      order_detail_cancel_key: '',
      order_detail_sqlite_id: widget.cartItem?.order_detail_sqlite_id,
      order_detail_key: data.order_detail_key,
      quantity: data.quantity,
      cancel_by: user.name,
      cancel_by_user_id: user.user_id.toString(),
      settlement_sqlite_id: '',
      settlement_key: '',
      status: 0,
      sync_status: 0,
      created_at: dateTime,
      updated_at: '',
      soft_delete: '',
    );
    OrderDetailCancel orderDetailCancel = await PosDatabase.instance.insertSqliteOrderDetailCancel(object);
    OrderDetailCancel updateData = await insertOrderDetailCancelKey(orderDetailCancel, dateTime);
    _value.add(jsonEncode(updateData));
    order_detail_cancel_value = _value.toString();
    //syncOrderDetailCancelToCloud(_value.toString());
  }

  syncOrderDetailCancelToCloud(String value) async {
    bool _hasInternetAccess = await Domain().isHostReachable();
    if (_hasInternetAccess) {
      Map response = await Domain().SyncOrderDetailCancelToCloud(value);
      if (response['status'] == '1') {
        List responseJson = response['data'];
        int data = await PosDatabase.instance.updateOrderDetailCancelSyncStatusFromCloud(responseJson[0]['order_detail_cancel_key']);
      }
    }
  }

  syncUpdatedPosTableToCloud(String posTableValue) async {
    bool _hasInternetAccess = await Domain().isHostReachable();
    if(_hasInternetAccess){
      Map response = await Domain().SyncUpdatedPosTableToCloud(posTableValue);
      if (response['status'] == '1') {
        List responseJson = response['data'];
        for (var i = 0; i < responseJson.length; i++) {
          int syncData = await PosDatabase.instance.updatePosTableSyncStatusFromCloud(responseJson[i]['table_id']);
        }
      }
    }
  }

  syncOrderModifierDetailToCloud(String orderModDetailValue) async {
    bool _hasInternetAccess = await Domain().isHostReachable();
    if(_hasInternetAccess){
      Map modResponse = await Domain().SyncOrderModifierDetailToCloud(orderModDetailValue);
      if(modResponse['status'] == '1'){
        List responseJson = modResponse['data'];
        for(int i = 0 ; i <responseJson.length; i++){
          int syncData = await PosDatabase.instance.updateOrderModifierDetailSyncStatusFromCloud(responseJson[i]['order_modifier_detail_key']);
        }
      }
    }
  }

  readAllPrinters() async {
    printerList = await PrintReceipt().readAllPrinters();
  }

  callDeleteOrderDetail(User user, String dateTime, CartModel cart) async {
    await createOrderDetailCancel(user, dateTime);
    await updateOrderDetailQuantity(dateTime, cart);
    List<String> _value = [];
    OrderDetail orderDetailObject = OrderDetail(
        updated_at: dateTime,
        sync_status: orderDetail!.sync_status == 0 ? 0 : 2,
        status: 1,
        cancel_by: user.name,
        cancel_by_user_id: user.user_id.toString(),
        order_detail_sqlite_id: int.parse(widget.cartItem!.order_detail_sqlite_id!),
        branch_link_product_sqlite_id: widget.cartItem!.branchProduct_id);

    int deleteOrderDetailData = await PosDatabase.instance.updateOrderDetailStatus(orderDetailObject);
    if(deleteOrderDetailData == 1){
      //sync to cloud
      OrderDetail detailData = await PosDatabase.instance.readSpecificOrderDetailByLocalId(orderDetailObject.order_detail_sqlite_id!);
      _value.add(jsonEncode(detailData.syncJson()));
      await updateOrderCacheSubtotal(detailData.order_cache_sqlite_id!, detailData.price, detailData.quantity, dateTime);
      //print('value: ${_value.toString()}');
    }
    order_detail_value = _value.toString();
    //syncUpdatedOrderDetailToCloud(_value.toString());
  }

  updateOrderCacheSubtotal(String orderCacheLocalId, price, quantity, String dateTime) async {
    double subtotal = 0.0;
    OrderCache data = await PosDatabase.instance.readSpecificOrderCacheByLocalId(int.parse(orderCacheLocalId));
    subtotal = double.parse(data.total_amount!) - double.parse(price);
    OrderCache orderCache = OrderCache(
      order_cache_sqlite_id: data.order_cache_sqlite_id,
      total_amount: subtotal.toStringAsFixed(2),
      sync_status: data.sync_status == 0 ? 0 : 2,
      updated_at: dateTime
    );
    int status = await PosDatabase.instance.updateOrderCacheSubtotal(orderCache);
  }

  updateProductStock(String branch_link_product_sqlite_id, int quantity, String dateTime) async{
    List<String> _value = [];
    int _totalStockQty = 0, updateStock = 0;
    BranchLinkProduct? object;
    List<BranchLinkProduct> checkData = await PosDatabase.instance.readSpecificBranchLinkProduct(branch_link_product_sqlite_id);
    if(checkData[0].stock_type == '2'){
      _totalStockQty = int.parse(checkData[0].stock_quantity!) + quantity;
      object = BranchLinkProduct(
          updated_at: dateTime,
          sync_status: 2,
          stock_quantity: _totalStockQty.toString(),
          branch_link_product_sqlite_id: int.parse(branch_link_product_sqlite_id)
      );
      updateStock = await PosDatabase.instance.updateBranchLinkProductStock(object);
    } else {
      _totalStockQty = int.parse(checkData[0].daily_limit_amount!) + quantity;
      object = BranchLinkProduct(
          updated_at: dateTime,
          sync_status: 2,
          daily_limit_amount: _totalStockQty.toString(),
          branch_link_product_sqlite_id: int.parse(branch_link_product_sqlite_id)
      );
      updateStock = await PosDatabase.instance.updateBranchLinkProductDailyLimitAmount(object);
    }
    if(updateStock == 1){
      List<BranchLinkProduct> updatedData = await PosDatabase.instance.readSpecificBranchLinkProduct(branch_link_product_sqlite_id);
      _value.add(jsonEncode(updatedData[0].toJson()));
    }
    branch_link_product_value = _value.toString();
    //sync to cloud
    //syncBranchLinkProductStock(value.toString());
  }

  syncBranchLinkProductStock(String value) async {
    bool _hasInternetAccess = await Domain().isHostReachable();
    if(_hasInternetAccess) {
      Map orderDetailResponse = await Domain().SyncBranchLinkProductToCloud(value);
      if (orderDetailResponse['status'] == '1') {
        List responseJson = orderDetailResponse['data'];
        for (int i = 0; i < responseJson.length; i++) {
          int syncUpdated = await PosDatabase.instance.updateBranchLinkProductSyncStatusFromCloud(responseJson[i]['branch_link_product_id']);
        }
      }
    }
  }

  syncUpdatedOrderDetailToCloud(String value) async {
    bool _hasInternetAccess = await Domain().isHostReachable();
    if(_hasInternetAccess){
      Map response = await Domain().SyncOrderDetailToCloud(value.toString());
      if (response['status'] == '1') {
        List responseJson = response['data'];
        int orderDetailData = await PosDatabase.instance.updateOrderDetailSyncStatusFromCloud(responseJson[0]['order_detail_key']);
      }
    }
  }

  callDeleteAllOrder(User user, String currentTableUseId, String dateTime, CartModel cartModel, ConnectivityChangeNotifier connectivity) async {
    if(widget.currentPage != 'other_order'){
      await deleteCurrentTableUseDetail(currentTableUseId, dateTime, connectivity);
      await deleteCurrentTableUseId(int.parse(currentTableUseId), dateTime, connectivity);
    }
    await callDeleteOrderDetail(user, dateTime, cartModel);
    await deleteCurrentOrderCache(user, dateTime, connectivity);
  }

  callDeletePartialOrder(User user, String dateTime, CartModel cartModel, ConnectivityChangeNotifier connectivity) async {
    await callDeleteOrderDetail(user, dateTime, cartModel);
    await deleteCurrentOrderCache(user, dateTime, connectivity);
  }

  updatePosTableStatus(int tableId, int status, String dateTime) async {
    PosTable? _data;
    PosTable posTableData = PosTable(
        table_use_detail_key: '',
        status: status,
        updated_at: dateTime,
        table_sqlite_id: tableId);
    int updatedStatus = await PosDatabase.instance.updatePosTableStatus(posTableData);
    int removeKey = await PosDatabase.instance.removePosTableTableUseDetailKey(posTableData);
    if(updatedStatus == 1 && removeKey == 1){
      List<PosTable> posTable  = await PosDatabase.instance.readSpecificTable(posTableData.table_sqlite_id.toString());
      if(posTable[0].sync_status == 2){
        _data = posTable[0];
      }
    }
    return _data;
  }

  deleteCurrentOrderCache(User user, String dateTime, ConnectivityChangeNotifier connectivity) async {
    List<String> _orderCacheValue = [];
    try {
      OrderCache orderCacheObject = OrderCache(
          sync_status: cartCacheList[0].sync_status == 0 ? 0 : 2,
          cancel_by: user.name,
          cancel_by_user_id: user.user_id.toString(),
          order_cache_sqlite_id: int.parse(widget.cartItem!.orderCacheId!)
      );
      int deletedOrderCache = await PosDatabase.instance.cancelOrderCache(orderCacheObject);
      //sync to cloud
      if(deletedOrderCache == 1 && connectivity.isConnect){
        OrderCache orderCacheData = await PosDatabase.instance.readSpecificOrderCacheByLocalId(orderCacheObject.order_cache_sqlite_id!);
        if(orderCacheData.sync_status != 1){
          _orderCacheValue.add(jsonEncode(orderCacheData));
        }
        order_cache_value = _orderCacheValue.toString();
        //syncOrderCacheToCloud(_orderCacheValue.toString());
      }
    } catch (e) {
      print('delete order cache error: ${e}');
    }
  }

  // syncOrderCacheToCloud(String value) async {
  //   bool _hasInternetAccess = await Domain().isHostReachable();
  //   if (_hasInternetAccess) {
  //     Map response = await Domain().SyncOrderCacheToCloud(value);
  //     if(response['status'] == '1'){
  //       List responseJson = response['data'];
  //       int syncData = await PosDatabase.instance.updateOrderCacheSyncStatusFromCloud(responseJson[0]['order_cache_key']);
  //     }
  //   }
  // }

  deleteCurrentTableUseDetail(String currentTableUseId, String dateTime, ConnectivityChangeNotifier connectivity) async {
    print('current table use id: ${currentTableUseId}');
    List<String> _value = [];
    try {
      List<TableUseDetail> checkData  = await PosDatabase.instance.readAllTableUseDetail(currentTableUseId);
      for(int i = 0; i < checkData.length; i++){
        TableUseDetail tableUseDetailObject = TableUseDetail(
          sync_status: checkData[i].sync_status == 0 ? 0 : 2,
          status: 1,
          table_use_sqlite_id: currentTableUseId,
          table_use_detail_sqlite_id: checkData[i].table_use_detail_sqlite_id
        );
        int deleteStatus = await PosDatabase.instance.deleteTableUseDetail(tableUseDetailObject);
        if(deleteStatus == 1){
          TableUseDetail detailData = await PosDatabase.instance.readSpecificTableUseDetailByLocalId(tableUseDetailObject.table_use_detail_sqlite_id!);
          _value.add(jsonEncode(detailData));
        }
      }
      table_use_detail_value = _value.toString();
      //sync to cloud
      //syncTableUseDetail(_value.toString());
    } catch (e) {
      print(e);
      Fluttertoast.showToast(
          backgroundColor: Color(0xFFFF0000),
          msg: "Delete current table use detail error: $e");
    }
  }

  syncTableUseDetail(String value) async {
    bool _hasInternetAccess = await Domain().isHostReachable();
    if(_hasInternetAccess){
      Map data = await Domain().SyncTableUseDetailToCloud(value);
      if(data['status'] == '1'){
        List responseJson = data['data'];
        for (var i = 0; i < responseJson.length; i++) {
          int tablaUseDetailData = await PosDatabase.instance.updateTableUseDetailSyncStatusFromCloud(responseJson[i]['table_use_detail_key']);
        }
      }
    }
  }

  deleteCurrentTableUseId(int currentTableUseId, String dateTime, ConnectivityChangeNotifier connectivity) async {
    List<String> _value = [];
    try {
      TableUse checkData = await PosDatabase.instance.readSpecificTableUseIdByLocalId(currentTableUseId);
      TableUse tableUseObject = TableUse(
        sync_status: checkData.sync_status == 0 ? 0 : 2,
        status: 1,
        table_use_sqlite_id: currentTableUseId,
      );
      int deletedTableUse = await PosDatabase.instance.deleteTableUseID(tableUseObject);
      if(deletedTableUse == 1){
        //sync to cloud
        TableUse tableUseData = await PosDatabase.instance.readSpecificTableUseIdByLocalId(tableUseObject.table_use_sqlite_id!);
        _value.add(jsonEncode(tableUseData));
        table_use_value = _value.toString();
        //syncTableUseIdToCloud(_value.toString());
      }
    } catch (e) {
      Fluttertoast.showToast(
          backgroundColor: Color(0xFFFF0000),
          msg: "Delete current table use id error: ${e}");
    }
  }

  syncTableUseIdToCloud(String value) async {
    bool _hasInternetAccess = await Domain().isHostReachable();
    if(_hasInternetAccess){
      Map data = await Domain().SyncTableUseToCloud(value);
      if (data['status'] == '1') {
        List responseJson = data['data'];
        int tablaUseData = await PosDatabase.instance.updateTableUseSyncStatusFromCloud(responseJson[0]['table_use_key']);
      }
    }
  }

  syncAllToCloud() async {
    final prefs = await SharedPreferences.getInstance();
    final int? device_id = prefs.getInt('device_id');
    final String? login_value = prefs.getString('login_value');
    bool _hasInternetAccess = await Domain().isHostReachable();
    if (_hasInternetAccess) {
      Map data = await Domain().syncLocalUpdateToCloud(
        device_id: device_id.toString(),
        value: login_value,
        table_use_value: this.table_use_value,
        table_use_detail_value: this.table_use_detail_value,
        order_cache_value: this.order_cache_value,
        order_detail_value: this.order_detail_value,
        order_detail_cancel_value: this.order_detail_cancel_value,
        branch_link_product_value: this.branch_link_product_value,
        table_value: this.table_value
      );
      //if success update local sync status
      if (data['status'] == '1') {
        List responseJson = data['data'];
        for(int i = 0; i < responseJson.length; i++){
          switch(responseJson[i]['table_name']){
            case 'tb_table_use_detail': {
              await PosDatabase.instance.updateTableUseDetailSyncStatusFromCloud(responseJson[i]['table_use_detail_key']);
            }
            break;
            case 'tb_table_use': {
              await PosDatabase.instance.updateTableUseSyncStatusFromCloud(responseJson[i]['table_use_key']);
            }
            break;
            case 'tb_order_detail_cancel': {
              await PosDatabase.instance.updateOrderDetailCancelSyncStatusFromCloud(responseJson[i]['order_detail_cancel_key']);
            }
            break;
            case 'tb_branch_link_product': {
              await PosDatabase.instance.updateBranchLinkProductSyncStatusFromCloud(responseJson[i]['branch_link_product_id']);
            }
            break;
            case 'tb_order_detail': {
              await PosDatabase.instance.updateOrderDetailSyncStatusFromCloud(responseJson[i]['order_detail_key']);
            }
            break;
            case 'tb_order_cache': {
              await PosDatabase.instance.updateOrderCacheSyncStatusFromCloud(responseJson[i]['order_cache_key']);
            }
            break;
            case 'tb_table': {
              await PosDatabase.instance.updatePosTableSyncStatusFromCloud(responseJson[i]['table_id']);
            }
            break;
            default: {
              return;
            }
          }
        }
      } else if(data['status'] == '7'){
        this.isLogOut = true;
      }
    }
  }
}
