import 'dart:convert';
import 'dart:typed_data';

import 'package:esc_pos_printer/esc_pos_printer.dart';
import 'package:esc_pos_utils/esc_pos_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_usb_printer/flutter_usb_printer.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';
import 'package:pos_system/fragment/cart/cancel_order_dialog.dart';
import 'package:pos_system/notifier/connectivity_change_notifier.dart';
import 'package:pos_system/object/cart_product.dart';
import 'package:pos_system/object/order_cache.dart';
import 'package:pos_system/object/order_modifier_detail.dart';
import 'package:pos_system/object/print_receipt.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../database/domain.dart';
import '../../database/pos_database.dart';
import '../../notifier/cart_notifier.dart';
import '../../notifier/table_notifier.dart';
import '../../notifier/theme_color.dart';
import '../../object/order_detail.dart';
import '../../object/printer.dart';
import '../../object/printer_link_category.dart';
import '../../object/receipt_layout.dart';
import '../../object/table.dart';
import '../../object/table_use.dart';
import '../../object/table_use_detail.dart';
import '../../object/user.dart';
import '../../translation/AppLocalizations.dart';

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
  bool _isLoaded = false;


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
      Navigator.of(context).pop();
      Navigator.of(context).pop();
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
      builder: (BuildContext context) => AlertDialog(
        title: Text('Enter admin PIN'),
        content: SizedBox(
          height: 100.0,
          width: 350.0,
          child: Column(
            children: [
              ValueListenableBuilder(
                  valueListenable: adminPosPinController,
                  builder: (context, TextEditingValue value, __) {
                    return Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: TextField(
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
            ],
          ),
        ),
        actions: <Widget>[
          TextButton(
            child: Text('${AppLocalizations.of(context)?.translate('close')}'),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
          TextButton(
            child: Text('${AppLocalizations.of(context)?.translate('yes')}'),
            onPressed: () async {
              _submit(context, cart, connectivity);
            },
          ),
        ],
      ),
    );
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
                        await showSecondDialog(context, color, cart, connectivity);
                        //openCancelOrderDialog(widget.cartItem!);
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

  Future<Future<Object?>> openCancelOrderDialog(
      cartProductItem cartItem) async {
    return showGeneralDialog(
        barrierColor: Colors.black.withOpacity(0.5),
        transitionBuilder: (context, a1, a2, widget) {
          final curvedValue = Curves.easeInOutBack.transform(a1.value) - 1.0;
          return Transform(
            transform: Matrix4.translationValues(0.0, curvedValue * 200, 0.0),
            child: Opacity(
              opacity: a1.value,
              child: CancelDialog(
                cartItem: cartItem,
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

  readCartItemInfo() async {
    final prefs = await SharedPreferences.getInstance();
    final int? branch_id = prefs.getInt('branch_id');
    //get cart item order cache
    List<OrderCache> cacheData = await PosDatabase.instance.readSpecificOrderCache(widget.cartItem!.orderCacheId!);
    cartCacheList = List.from(cacheData);

    //get table use order cache
    List<OrderCache> tableCacheData = await PosDatabase.instance.readTableOrderCache(branch_id.toString(), cacheData[0].table_use_sqlite_id!);
    cartTableCacheList = List.from(tableCacheData);

    //get table use detail
    List<TableUseDetail> tableDetailData = await PosDatabase.instance.readAllTableUseDetail(cacheData[0].table_use_sqlite_id!);
    cartTableUseDetail = List.from(tableDetailData);

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
      DateFormat dateFormat = DateFormat("yyyy-MM-dd HH:mm:ss");
      String dateTime = dateFormat.format(DateTime.now());

      List<User> userData = await PosDatabase.instance.readSpecificUserWithRole(pin);
      if (userData.isNotEmpty) {

        if(cartTableCacheList.length <= 1 && cartOrderDetailList.length > 1){
          if(cartOrderModDetailList.isNotEmpty){
            _hasModifier = true;
            for(int i = 0; i < cartOrderModDetailList.length; i++){
              OrderModifierDetail deletedMod  = await deleteAllOrderModDetail(dateTime, cartOrderModDetailList[i]);
            }
          }
          callDeleteOrderDetail(userData[0], dateTime, cart);
        } else if(cartTableCacheList.length > 1 && cartOrderDetailList.length <= 1 ){
          if(cartOrderModDetailList.isNotEmpty){
            _hasModifier = true;
            for(int i = 0; i < cartOrderModDetailList.length; i++){
              OrderModifierDetail deletedMod  = await deleteAllOrderModDetail(dateTime, cartOrderModDetailList[i]);
            }
          }
          callDeletePartialOrder(userData[0], dateTime, cart, connectivity);
        } else if (cartTableCacheList.length > 1 && cartOrderDetailList.length > 1) {
          if(cartOrderModDetailList.isNotEmpty){
            _hasModifier = true;
            for(int i = 0; i < cartOrderModDetailList.length; i++){
              OrderModifierDetail deletedMod  = await deleteAllOrderModDetail(dateTime, cartOrderModDetailList[i]);
            }
          }
          callDeleteOrderDetail(userData[0], dateTime, cart);
        } else if(widget.currentPage == 'other order' && cartOrderDetailList.length > 1){
          if(cartOrderModDetailList.isNotEmpty){
            _hasModifier = true;
            for(int i = 0; i < cartOrderModDetailList.length; i++){
              OrderModifierDetail deletedMod  = await deleteAllOrderModDetail(dateTime, cartOrderModDetailList[i]);
            }
          }
          callDeleteOrderDetail(userData[0], dateTime, cart);
        } else {
          if(cartOrderModDetailList.isNotEmpty){
            _hasModifier = true;
            for(int i = 0; i < cartOrderModDetailList.length; i++){
              OrderModifierDetail deletedMod  = await deleteAllOrderModDetail(dateTime, cartOrderModDetailList[i]);
              _orderModDetailValue.add(jsonEncode(deletedMod));
            }
          }
          callDeleteAllOrder(userData[0], cartCacheList[0].table_use_sqlite_id!, dateTime, cart, connectivity);
          for (int i = 0; i < cartTableUseDetail.length; i++) {
            //update all table to unused
            PosTable posTableData = await updatePosTableStatus(int.parse(cartTableUseDetail[i].table_sqlite_id!), 0, dateTime);
            _posTableValue.add(jsonEncode(posTableData));
          }
        }
        if(connectivity.isConnect){
          //sync to cloud
          if(_hasModifier == true){
            syncOrderModifierDetailToCloud(_orderModDetailValue.toString());
          }
          //sync to cloud
          syncUpdatedPosTableToCloud(_posTableValue.toString());
        }
        //print cancel receipt
        //await _printDeleteList(widget.cartItem!.orderCacheId!, dateTime);

        cart.removeAllTable();
        cart.removeAllCartItem();
        Fluttertoast.showToast(backgroundColor: Color(0xFF24EF10), msg: "delete successful");

      } else {
        Fluttertoast.showToast(
            backgroundColor: Color(0xFFFF0000), msg: "Password incorrect");
      }
    } catch (e) {
      print('delete error ${e}');
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
    final prefs = await SharedPreferences.getInstance();
    final int? branch_id = prefs.getInt('branch_id');

    List<Printer> data =
        await PosDatabase.instance.readAllBranchPrinter(branch_id!);
    printerList = List.from(data);
  }

  deleteAllOrderModDetail(String dateTime, OrderModifierDetail orderModifierDetail) async {
    OrderModifierDetail? _data;
    OrderModifierDetail orderModifierDetailObject = OrderModifierDetail(
      soft_delete: dateTime,
      sync_status: orderModifierDetail.sync_status == 0 ? 0 : 2,
      order_detail_sqlite_id: widget.cartItem!.order_detail_sqlite_id,
      order_modifier_detail_sqlite_id: orderModifierDetail.order_modifier_detail_sqlite_id
    );
    int deleteMod = await PosDatabase.instance.deleteOrderModifierDetail(orderModifierDetailObject);
    if(deleteMod == 1){
      OrderModifierDetail detailData = await PosDatabase.instance.readSpecificOrderModifierDetailByLocalId(orderModifierDetailObject.order_modifier_detail_sqlite_id!);
      _data = detailData;
    }
    return _data;
  }

  callDeleteOrderDetail(User user, String dateTime, CartModel cart) async {
    List<String> _value = [];
    OrderDetail orderDetailObject = OrderDetail(
        soft_delete: dateTime,
        sync_status: orderDetail!.sync_status == 0 ? 0 : 2,
        cancel_by: user.name,
        cancel_by_user_id: user.user_id.toString(),
        order_detail_sqlite_id: int.parse(widget.cartItem!.order_detail_sqlite_id!),
        branch_link_product_sqlite_id: widget.cartItem!.branchProduct_id);

    int deleteOrderDetailData = await PosDatabase.instance.deleteSpecificOrderDetail(orderDetailObject);
    if(deleteOrderDetailData == 1){
      await PrintReceipt().printDeleteList(printerList, widget.cartItem!.orderCacheId!, dateTime, context);
      await PrintReceipt().printKitchenDeleteList(printerList, widget.cartItem!.orderCacheId!, widget.cartItem!.category_sqlite_id!, dateTime, cart);
      //sync to cloud
      OrderDetail detailData = await PosDatabase.instance.readSpecificOrderDetailByLocalId(orderDetailObject.order_detail_sqlite_id!);
      _value.add(jsonEncode(detailData.syncJson()));
      syncUpdatedOrderDetailToCloud(_value.toString());
      tableModel.changeContent(true);
    }
  }

  syncUpdatedOrderDetailToCloud(String value) async {
    bool _hasInternetAccess = await Domain().isHostReachable();
    if(_hasInternetAccess){
      Map response = await Domain().SyncUpdatedOrderDetailToCloud(value.toString());
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
          soft_delete: dateTime,
          sync_status: cartCacheList[0].sync_status == 0 ? 0 : 2,
          cancel_by: user.name,
          cancel_by_user_id: user.user_id.toString(),
          order_cache_sqlite_id: int.parse(widget.cartItem!.orderCacheId!)
      );
      int deletedOrderCache = await PosDatabase.instance.deleteOrderCache(orderCacheObject);
      //sync to cloud
      if(deletedOrderCache == 1 && connectivity.isConnect){
        OrderCache orderCacheData = await PosDatabase.instance.readSpecificOrderCacheByLocalId(orderCacheObject.order_cache_sqlite_id!);
        if(orderCacheData.sync_status != 1){
          _orderCacheValue.add(jsonEncode(orderCacheData));
        }
        Map response = await Domain().SyncOrderCacheToCloud(_orderCacheValue.toString());
        if(response['status'] == '1'){
          List responseJson = response['data'];
          int syncData = await PosDatabase.instance.updateOrderCacheSyncStatusFromCloud(responseJson[0]['order_cache_key']);
        }
      }
    } catch (e) {
      print('delete order cache error: ${e}');
    }
  }

  deleteCurrentTableUseDetail(String currentTableUseId, String dateTime, ConnectivityChangeNotifier connectivity) async {
    List<String> _value = [];
    try {
      List<TableUseDetail> checkData  = await PosDatabase.instance.readAllTableUseDetail(currentTableUseId);
      for(int i = 0; i < checkData.length; i++){
        TableUseDetail tableUseDetailObject = TableUseDetail(
          soft_delete: dateTime,
          sync_status: checkData[i].sync_status == 0 ? 0 : 2,
          table_use_sqlite_id: currentTableUseId,
          table_use_detail_sqlite_id: checkData[i].table_use_detail_sqlite_id
        );
        int deleteStatus = await PosDatabase.instance.deleteTableUseDetail(tableUseDetailObject);
        if(deleteStatus == 1 && connectivity.isConnect){
          TableUseDetail detailData = await PosDatabase.instance.readSpecificTableUseDetailByLocalId(tableUseDetailObject.table_use_detail_sqlite_id!);
          _value.add(jsonEncode(detailData.syncJson()));
        }
      }
      //sync to cloud
      syncTableUseDetail(_value.toString());
    } catch (e) {
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
        soft_delete: dateTime,
        sync_status: checkData.sync_status == 0 ? 0 : 2,
        table_use_sqlite_id: currentTableUseId,
      );
      int deletedTableUse = await PosDatabase.instance.deleteTableUseID(tableUseObject);
      if(deletedTableUse == 1){
        //sync to cloud
        TableUse tableUseData = await PosDatabase.instance.readSpecificTableUseIdByLocalId(tableUseObject.table_use_sqlite_id!);
        _value.add(jsonEncode(tableUseData));
        syncTableUseIdToCloud(_value.toString());
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
}
