import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';
import 'package:pos_system/object/order_detail_cancel.dart';
import 'package:provider/provider.dart';
import 'package:quantity_input/quantity_input.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:crypto/crypto.dart';

import '../../database/domain.dart';
import '../../database/pos_database.dart';
import '../../notifier/cart_notifier.dart';
import '../../notifier/table_notifier.dart';
import '../../notifier/theme_color.dart';
import '../../object/branch_link_product.dart';
import '../../object/cart_product.dart';
import '../../object/order_cache.dart';
import '../../object/order_detail.dart';
import '../../object/order_modifier_detail.dart';
import '../../object/print_receipt.dart';
import '../../object/printer.dart';
import '../../object/table.dart';
import '../../object/table_use.dart';
import '../../object/table_use_detail.dart';
import '../../object/user.dart';
import '../../translation/AppLocalizations.dart';

class AdjustQuantityDialog extends StatefulWidget {
  final cartProductItem cartItem;
  final String currentPage;
  const AdjustQuantityDialog({Key? key, required this.cartItem, required this.currentPage}) : super(key: key);

  @override
  State<AdjustQuantityDialog> createState() => _AdjustQuantityDialogState();
}

class _AdjustQuantityDialogState extends State<AdjustQuantityDialog> {
  int simpleIntInput = 1;
  final adminPosPinController = TextEditingController();
  List<User> adminData = [];
  List<Printer> printerList = [];
  List<OrderCache> cartCacheList = [], cartTableCacheList = [];
  List<OrderDetail> cartOrderDetailList = [];
  List<OrderModifierDetail> cartOrderModDetailList = [];
  List<TableUseDetail> cartTableUseDetail = [];
  OrderDetail? orderDetail;
  bool _isLoaded = false;
  bool _submitted = false;

  late TableModel tableModel;

  @override
  void initState() {
    super.initState();
    readAllPrinters();
    readCartItemInfo();

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

  void _submit(BuildContext context, CartModel cart) async {
    setState(() => _submitted = true);
    if (errorPassword == null) {
      await readAdminData(adminPosPinController.text, cart);
      Navigator.of(context).pop();
      Navigator.of(context).pop();
      Navigator.of(context).pop();
      return;
    }
  }

  Future showSecondDialog(BuildContext context, ThemeColor color, CartModel cart) {
    return showDialog(
      barrierDismissible: false,
      context: context,
      builder: (BuildContext context) => Center(
        child: SingleChildScrollView(
          physics: NeverScrollableScrollPhysics(),
          child: AlertDialog(
            title: Text('Enter admin PIN'),
            content: SizedBox(
              height: 100.0,
              width: 350.0,
              child: ValueListenableBuilder(
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
                  _submit(context, cart);
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
      return Consumer<CartModel>(builder: (context, CartModel cart, child) {
        return Consumer<TableModel>(builder: (context, TableModel tableModel, child) {
          this.tableModel = tableModel;
          return Center(
            child: SingleChildScrollView(
              physics: NeverScrollableScrollPhysics(),
              child: AlertDialog(
                title: Text('Adjust Quantity'),
                content: SizedBox(
                    height: 100.0,
                    width: 350.0,
                    child: QuantityInput(
                        inputWidth: 273,
                        maxValue: widget.cartItem.quantity,
                        decoration: InputDecoration(
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                                color: Colors.black),
                          ),
                        ),
                        buttonColor: Colors.black,
                        value: simpleIntInput,
                        onChanged: (value) => setState(() =>
                        simpleIntInput =
                            int.parse(value.replaceAll(',', ''))))
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
                      await showSecondDialog(context, color, cart);
                    },
                  ),
                ],
              ),
            ),
          );
        });
      });

    });
  }

  readAllPrinters() async {
    printerList = await PrintReceipt().readAllPrinters();
  }

  readCartItemInfo() async {
    final prefs = await SharedPreferences.getInstance();
    final int? branch_id = prefs.getInt('branch_id');
    //get cart item order cache
    List<OrderCache> cacheData = await PosDatabase.instance.readSpecificOrderCache(widget.cartItem.orderCacheId!);
    cartCacheList = List.from(cacheData);

    //get table use order cache
    List<OrderCache> tableCacheData = await PosDatabase.instance.readTableOrderCache(branch_id.toString(), cacheData[0].table_use_sqlite_id!);
    cartTableCacheList = List.from(tableCacheData);

    //get table use detail
    List<TableUseDetail> tableDetailData = await PosDatabase.instance.readAllTableUseDetail(cacheData[0].table_use_sqlite_id!);
    cartTableUseDetail = List.from(tableDetailData);

    //get cart item order cache order detail
    List<OrderDetail> orderDetailData = await PosDatabase.instance.readTableOrderDetail(widget.cartItem.orderCacheId!);
    cartOrderDetailList = List.from(orderDetailData);

    OrderDetail cartItemOrderDetail = await PosDatabase.instance.readSpecificOrderDetailByLocalId(int.parse(widget.cartItem.order_detail_sqlite_id!));
    orderDetail = cartItemOrderDetail;

    //get modifier detail length
    List<OrderModifierDetail> orderModData = await PosDatabase.instance.readOrderModifierDetail(widget.cartItem.order_detail_sqlite_id!);
    cartOrderModDetailList = List.from(orderModData);

    _isLoaded = true;
  }

  readAdminData(String pin, CartModel cart) async {
    List<String> _posTableValue = [];
    try {
      DateFormat dateFormat = DateFormat("yyyy-MM-dd HH:mm:ss");
      String dateTime = dateFormat.format(DateTime.now());

      List<User> userData = await PosDatabase.instance.readSpecificUserWithRole(pin);
      if (userData.isNotEmpty) {
        if(simpleIntInput == widget.cartItem.quantity){
          if(cartTableCacheList.length <= 1 && cartOrderDetailList.length > 1){
            // if(cartOrderModDetailList.isNotEmpty){
            //   _hasModifier = true;
            //   for(int i = 0; i < cartOrderModDetailList.length; i++){
            //     OrderModifierDetail deletedMod  = await deleteAllOrderModDetail(dateTime, cartOrderModDetailList[i]);
            //   }
            // }
            callDeleteOrderDetail(userData[0], dateTime, cart);
          } else if(cartTableCacheList.length > 1 && cartOrderDetailList.length <= 1 ){
            // if(cartOrderModDetailList.isNotEmpty){
            //   _hasModifier = true;
            //   for(int i = 0; i < cartOrderModDetailList.length; i++){
            //     OrderModifierDetail deletedMod  = await deleteAllOrderModDetail(dateTime, cartOrderModDetailList[i]);
            //   }
            // }
            callDeletePartialOrder(userData[0], dateTime, cart);
          } else if (cartTableCacheList.length > 1 && cartOrderDetailList.length > 1) {
            // if(cartOrderModDetailList.isNotEmpty){
            //   _hasModifier = true;
            //   for(int i = 0; i < cartOrderModDetailList.length; i++){
            //     OrderModifierDetail deletedMod  = await deleteAllOrderModDetail(dateTime, cartOrderModDetailList[i]);
            //   }
            // }
            callDeleteOrderDetail(userData[0], dateTime, cart);
          } else if(widget.currentPage == 'other order' && cartOrderDetailList.length > 1){
            // if(cartOrderModDetailList.isNotEmpty){
            //   _hasModifier = true;
            //   for(int i = 0; i < cartOrderModDetailList.length; i++){
            //     OrderModifierDetail deletedMod  = await deleteAllOrderModDetail(dateTime, cartOrderModDetailList[i]);
            //   }
            // }
            callDeleteOrderDetail(userData[0], dateTime, cart);
          } else {
            // if(cartOrderModDetailList.isNotEmpty){
            //   _hasModifier = true;
            //   for(int i = 0; i < cartOrderModDetailList.length; i++){
            //     OrderModifierDetail deletedMod  = await deleteAllOrderModDetail(dateTime, cartOrderModDetailList[i]);
            //     _orderModDetailValue.add(jsonEncode(deletedMod));
            //   }
            // }
            callDeleteAllOrder(userData[0], cartCacheList[0].table_use_sqlite_id!, dateTime, cart);
            for (int i = 0; i < cartTableUseDetail.length; i++) {
              //update all table to unused
              PosTable posTableData = await updatePosTableStatus(int.parse(cartTableUseDetail[i].table_sqlite_id!), 0, dateTime);
              _posTableValue.add(jsonEncode(posTableData));
            }
          }
        } else {
          createOrderDetailCancel(userData[0], dateTime, cart);
          await updateOrderDetailQuantity(dateTime, cart);
          tableModel.changeContent(true);
          print('update order detail quantity & create order detail cancel');
        }
        //sync to cloud
        syncUpdatedPosTableToCloud(_posTableValue.toString());
        //print cancel receipt
        //await _printDeleteList(widget.cartItem!.orderCacheId!, dateTime);

        cart.removeAllTable();
        cart.removeAllCartItem();
        cart.removePromotion();
        Fluttertoast.showToast(backgroundColor: Color(0xFF24EF10), msg: "delete successful");

      } else {
        Fluttertoast.showToast(
            backgroundColor: Color(0xFFFF0000), msg: "Password incorrect");
      }
    } catch (e) {
      print('delete error ${e}');
    }
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

  createOrderDetailCancel(User user, String dateTime, CartModel cart) async {
    List<String> _value = [];
    OrderDetail data = await PosDatabase.instance.readSpecificOrderDetailByLocalId(int.parse(widget.cartItem.order_detail_sqlite_id!));
    OrderDetailCancel object =  OrderDetailCancel(
      order_detail_cancel_id: 0,
      order_detail_cancel_key: '',
      order_detail_sqlite_id: widget.cartItem.order_detail_sqlite_id,
      order_detail_key: data.order_detail_key,
      quantity: simpleIntInput.toString(),
      cancel_by: user.name,
      cancel_by_user_id: user.user_id.toString(),
      status: 0,
      sync_status: 0,
      created_at: dateTime,
      updated_at: '',
      soft_delete: '',
    );
    OrderDetailCancel orderDetailCancel = await PosDatabase.instance.insertSqliteOrderDetailCancel(object);
    OrderDetailCancel updateData = await insertOrderDetailCancelKey(orderDetailCancel, dateTime);
    _value.add(jsonEncode(updateData));
    print('value: ${_value.toString()}');
    syncOrderDetailCancelToCloud(_value.toString());
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

  updateOrderDetailQuantity(String dateTime, CartModel cart) async {
    List<String> _value = [];
    int totalQty = 0;
    totalQty = widget.cartItem.quantity - simpleIntInput;
    OrderDetail orderDetailObject = OrderDetail(
        updated_at: dateTime,
        sync_status: orderDetail!.sync_status == 0 ? 0 : 2,
        status: 0,
        quantity: totalQty.toString(),
        order_detail_sqlite_id: int.parse(widget.cartItem.order_detail_sqlite_id!),
        branch_link_product_sqlite_id: widget.cartItem.branchProduct_id);

    int data = await PosDatabase.instance.updateOrderDetailQuantity(orderDetailObject);
    if(data == 1){
      OrderDetail detailData = await PosDatabase.instance.readSpecificOrderDetailByLocalId(orderDetailObject.order_detail_sqlite_id!);
      await updateProductStock(widget.cartItem.branchProduct_id, simpleIntInput, dateTime);
      await PrintReceipt().printDeleteList(printerList, widget.cartItem.orderCacheId!, dateTime);
      await PrintReceipt().printKitchenDeleteList(printerList, widget.cartItem.orderCacheId!, widget.cartItem.category_sqlite_id!, dateTime, cart);
      _value.add(jsonEncode(detailData.syncJson()));
    }
    syncUpdatedOrderDetailToCloud(_value.toString());
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

  callDeleteOrderDetail(User user, String dateTime, CartModel cart) async {
    await createOrderDetailCancel(user, dateTime, cart);
    await updateOrderDetailQuantity(dateTime, cart);
    List<String> _value = [];
    OrderDetail orderDetailObject = OrderDetail(
        updated_at: dateTime,
        sync_status: orderDetail!.sync_status == 0 ? 0 : 2,
        status: 1,
        cancel_by: user.name,
        cancel_by_user_id: user.user_id.toString(),
        order_detail_sqlite_id: int.parse(widget.cartItem.order_detail_sqlite_id!),
        branch_link_product_sqlite_id: widget.cartItem.branchProduct_id);

    int deleteOrderDetailData = await PosDatabase.instance.updateOrderDetailStatus(orderDetailObject);
    if(deleteOrderDetailData == 1){
      //await updateProductStock(orderDetailObject.branch_link_product_sqlite_id!, int.parse(orderDetailObject.quantity!), dateTime);
      //sync to cloud
      OrderDetail detailData = await PosDatabase.instance.readSpecificOrderDetailByLocalId(orderDetailObject.order_detail_sqlite_id!);
      _value.add(jsonEncode(detailData.syncJson()));
      print('value: ${_value.toString()}');
    }
    syncUpdatedOrderDetailToCloud(_value.toString());
    tableModel.changeContent(true);
  }

  updateProductStock(String branch_link_product_sqlite_id, int quantity, String dateTime) async{
    List<String> value = [];
    int _totalStockQty = 0;
    List<BranchLinkProduct> checkData = await PosDatabase.instance.readSpecificBranchLinkProduct(branch_link_product_sqlite_id);
    _totalStockQty = int.parse(checkData[0].stock_quantity!) + quantity;
    BranchLinkProduct object = BranchLinkProduct(
        updated_at: dateTime,
        sync_status: 2,
        stock_quantity: _totalStockQty.toString(),
        branch_link_product_sqlite_id: int.parse(branch_link_product_sqlite_id)
    );
    int updateStock = await PosDatabase.instance.updateBranchLinkProductStock(object);
    if(updateStock == 1){
      List<BranchLinkProduct> updatedData = await PosDatabase.instance.readSpecificBranchLinkProduct(branch_link_product_sqlite_id);
      value.add(jsonEncode(updatedData[0].toJson()));
    }
    //sync to cloud
    syncBranchLinkProductStock(value.toString());
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

  callDeleteAllOrder(User user, String currentTableUseId, String dateTime, CartModel cartModel) async {
    if(widget.currentPage != 'other_order'){
      await deleteCurrentTableUseDetail(currentTableUseId, dateTime);
      await deleteCurrentTableUseId(int.parse(currentTableUseId), dateTime);
    }
    await callDeleteOrderDetail(user, dateTime, cartModel);
    await deleteCurrentOrderCache(user, dateTime);
  }

  callDeletePartialOrder(User user, String dateTime, CartModel cartModel) async {
    await callDeleteOrderDetail(user, dateTime, cartModel);
    await deleteCurrentOrderCache(user, dateTime);
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

  deleteCurrentOrderCache(User user, String dateTime) async {
    List<String> _orderCacheValue = [];
    try {
      OrderCache orderCacheObject = OrderCache(
          sync_status: cartCacheList[0].sync_status == 0 ? 0 : 2,
          cancel_by: user.name,
          cancel_by_user_id: user.user_id.toString(),
          order_cache_sqlite_id: int.parse(widget.cartItem.orderCacheId!)
      );
      int deletedOrderCache = await PosDatabase.instance.cancelOrderCache(orderCacheObject);
      //sync to cloud
      if(deletedOrderCache == 1){
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

  deleteCurrentTableUseDetail(String currentTableUseId, String dateTime) async {
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
      //sync to cloud
      syncTableUseDetail(_value.toString());
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

  deleteCurrentTableUseId(int currentTableUseId, String dateTime) async {
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
