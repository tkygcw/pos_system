import 'dart:convert';

import 'package:f_logs/model/flog/flog.dart';
import 'package:pos_system/object/order_cache.dart';
import 'package:pos_system/object/order_detail.dart';
import 'package:pos_system/object/user.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import 'package:crypto/crypto.dart';

import '../../object/branch_link_product.dart';
import '../../object/dining_option.dart';
import '../../object/order_detail_cancel.dart';
import '../../object/product.dart';
import '../../object/table.dart';
import '../../object/table_use.dart';
import '../../object/table_use_detail.dart';
import '../../utils/Utils.dart';
import 'cancel_item_data.dart';
import 'cancel_item_function.dart';

class CancelQuery extends CancelItemFunction {
  var cancelItemData = CancelItemData.instance;
  late final OrderDetail _orderDetail;
  late final User _user;
  late Transaction _transaction;
  late String _currentDatetime;

  CancelQuery(this._transaction, this._currentDatetime);

  Future<void> resetOrderCacheTableUse(String currentTableUseId) async {
    try {
      List<TableUseDetail> tableUseDetailList = await _deleteCurrentTableUseDetail(currentTableUseId);
      await _deleteCurrentTableUseId(int.parse(currentTableUseId));
      await _updatePosTableStatus(tableUseDetailList: tableUseDetailList);
    }catch(e, stackTrace){
      FLog.error(
        className: "adjust_qty_dialog",
        text: "callDeleteOrderDetail error",
        exception: "Error: $e, StackTrace: $stackTrace",
      );
      rethrow;
    }
  }

  _updatePosTableStatus({required List<TableUseDetail> tableUseDetailList}) async {
    try{
      for (int i = 0; i < tableUseDetailList.length; i++) {
        //update all table to unused
        PosTable posTableData = PosTable(
          table_use_detail_key: '',
          table_use_key: '',
          status: 0,
          updated_at: _currentDatetime,
          table_sqlite_id: int.parse(tableUseDetailList[i].table_sqlite_id!),
        );
        await _updateSqlitePosTableStatus(posTableData);
      }
    }catch(e, stackTrace){
      FLog.error(
        className: "adjust_qty_dialog",
        text: "updatePosTableStatus error",
        exception: "Error: $e, StackTrace: $stackTrace",
      );
      rethrow;
    }
  }

  _deleteCurrentTableUseId(int currentTableUseId) async {
    try {
      TableUse? checkData = await _readSpecificTableUseIdByLocalId(currentTableUseId);
      TableUse tableUseObject = checkData!.copy(
        updated_at: _currentDatetime,
        sync_status: checkData.sync_status == 0 ? 0 : 2,
        status: 1,
      );
      await _deleteTableUseID(tableUseObject);
    } catch(e, stackTrace){
      FLog.error(
        className: "adjust_qty_dialog",
        text: "deleteCurrentTableUseId error",
        exception: "Error: $e, StackTrace: $stackTrace",
      );
      rethrow;
    }
  }

  Future<List<TableUseDetail>> _deleteCurrentTableUseDetail(String currentTableUseId) async {
    try {
      List<TableUseDetail> tableUseDetailList = await _readAllTableUseDetail(currentTableUseId);
      for (var tableUseDetail in tableUseDetailList) {
        TableUseDetail tableUseDetailObject = tableUseDetail.copy(
          updated_at: _currentDatetime,
          sync_status: tableUseDetail.sync_status == 0 ? 0 : 2,
          status: 1,
        );
        await _deleteTableUseDetail(tableUseDetailObject);
      }
      return tableUseDetailList;
    } catch(e, stackTrace){
      FLog.error(
        className: "adjust_qty_dialog",
        text: "deleteCurrentTableUseDetail error",
        exception: "Error: $e, StackTrace: $stackTrace",
      );
      rethrow;
    }
  }

  Future<void> callDeleteOrderDetail({bool? deleteOrderCache, OrderCache? cartOrderCache}) async {
    try{
      await _createOrderDetailCancel();
      OrderDetail orderDetailObject = _orderDetail.copy(
        updated_at: _currentDatetime,
        sync_status: _orderDetail.sync_status == 0 ? 0 : 2,
        status: 1,
        cancel_by: _user.name,
        cancel_by_user_id: _user.user_id.toString(),
        quantity: _getTotalQty(),
      );
      int deleteOrderDetailData = await _updateOrderDetailStatusAndQty(orderDetailObject);
      if(deleteOrderCache == true && deleteOrderDetailData == 1){
        await _cancelCurrentOrderCache();
      }
    }catch(e, stackTrace){
      FLog.error(
        className: "adjust_qty_dialog",
        text: "callDeleteOrderDetail error",
        exception: "Error: $e, StackTrace: $stackTrace",
      );
      rethrow;
    }
  }

  Future<void> callUpdateOrderDetail({required OrderDetail cancelOrderDetail, required User cancelUser}) async {
    _orderDetail = cancelOrderDetail;
    _user = cancelUser;
    await _createOrderDetailCancel();
    await _updateOrderDetailQuantity();
  }

  Future<void> _cancelCurrentOrderCache() async {
    print('delete order cache called');
    try {
      OrderCache? data = await _readSpecificOrderCacheByLocalId(int.parse(_orderDetail.order_cache_sqlite_id!));
      if(data != null){
        OrderCache orderCacheObject = data.copy(
            sync_status: data.sync_status == 0 ? 0 : 2,
            cancel_by: _user.name,
            cancel_by_user_id: _user.user_id.toString()
        );
        await _cancelOrderCache(orderCacheObject);
      }
    }catch(e, stackTrace){
      FLog.error(
        className: "adjust_qty_dialog",
        text: "deleteCurrentOrderCache error",
        exception: "Error: $e, StackTrace: $stackTrace",
      );
      rethrow;
    }
  }

  String _getSubtotal(double totalAmount, String price, num quantity){
    double subtotal = 0.0;
    if(_orderDetail.unit != 'each' && _orderDetail.unit != 'each_c'){
      subtotal = totalAmount - double.parse(price);
    } else {
      subtotal = totalAmount - double.parse(price) * quantity;
    }
    print("subtotal: ${subtotal.toStringAsFixed(2)}");
    return subtotal.toStringAsFixed(2);
  }

  String _getTotalQty(){
    num totalQty = 0;
    if(_orderDetail.unit != 'each' && _orderDetail.unit != 'each_c'){
      if(cancelItemData.cancelQty != 0){
        totalQty = 0;
      }
    } else {
      totalQty = num.parse(_orderDetail.quantity!) - cancelItemData.cancelQty;
    }
    print("total qty: ${totalQty}");
    return totalQty.toString();
  }

  _updateProductStock(String branch_link_product_sqlite_id) async {
    num _totalStockQty = 0;
    BranchLinkProduct? object;
    try{
      // readSpecificBranchLinkProduct
      List<BranchLinkProduct> checkData = await _readSpecificBranchLinkProduct(branch_link_product_sqlite_id);
      if(checkData.isNotEmpty){
        switch(checkData.first.stock_type){
          case '1': {
            _totalStockQty = int.parse(checkData[0].daily_limit!) + cancelItemData.cancelQty;
            object = checkData.first.copy(
                updated_at: _currentDatetime,
                sync_status: 2,
                daily_limit: _totalStockQty.toString(),
                branch_link_product_sqlite_id: int.parse(branch_link_product_sqlite_id));
             await _updateBranchLinkProductDailyLimit(object);
          }break;
          case'2': {
            _totalStockQty = int.parse(checkData[0].stock_quantity!) + cancelItemData.cancelQty;
            object = checkData.first.copy(
                updated_at: _currentDatetime,
                sync_status: 2,
                stock_quantity: _totalStockQty.toString(),
                branch_link_product_sqlite_id: int.parse(branch_link_product_sqlite_id));
             await _updateBranchLinkProductStock(object);
          }break;
        }
      }
    }catch(e, stackTrace){
      FLog.error(
        className: "cancel query",
        text: "updateProductStock error",
        exception: "Error: $e, StackTrace: $stackTrace",
      );
      rethrow;
    }
  }

  Future<OrderCache?> _updateOrderCacheSubtotal(String orderCacheLocalId, String price) async {
    try{
      // readSpecificOrderCacheByLocalId
      OrderCache? data = await _readSpecificOrderCacheByLocalId(int.parse(orderCacheLocalId));
      if(data != null){
        OrderCache orderCache = data.copy(
            order_cache_sqlite_id: data.order_cache_sqlite_id,
            total_amount: _getSubtotal(double.parse(data.total_amount!), price, cancelItemData.cancelQty),
            sync_status: data.sync_status == 0 ? 0 : 2,
            updated_at: _currentDatetime);
        // updateOrderCacheSubtotal
        int status = await _updateSqliteOrderCacheSubtotal(orderCache);
        if (status == 1) {
          return data;
        } else {
          return null;
        }
      }
      return null;
    }catch(e, stackTrace){
      FLog.error(
        className: "adj_quantity",
        text: "updateOrderCacheSubtotal error",
        exception: "Error: $e, StackTrace: $stackTrace",
      );
      rethrow;
    }
  }

  _updateOrderDetailQuantity() async {
    List<String> _value = [];
    try{
      OrderDetail updatedOrderDetail = _orderDetail.copy(
        updated_at: _currentDatetime,
        sync_status: _orderDetail.sync_status == 0 ? 0 : 2,
        status: 0,
        quantity: _getTotalQty()
      );
      // updateOrderDetailQuantity
      num data = await _updateSqliteOrderDetailQuantity(updatedOrderDetail);
      // num data = await posDatabase.updateOrderDetailQuantity(orderDetail);
      if (data == 1) {
        // readSpecificOrderDetailByLocalId
        // OrderDetail updatedOrderDetail = await _readSpecificOrderDetailByLocalId(orderDetail.order_detail_sqlite_id!);
        // OrderDetail detailData = await posDatabase.readSpecificOrderDetailByLocalId(orderDetail.order_detail_sqlite_id!);
        await _updateOrderCacheSubtotal(updatedOrderDetail.order_cache_sqlite_id!, updatedOrderDetail.price!);
        if(cancelItemData.restock){
          await _updateProductStock(updatedOrderDetail.branch_link_product_sqlite_id!);
        }
        // _firestoreQROrderSync.updateOrderDetailAndCacheSubtotal(updatedOrderDetail, orderCache!);
        // _value.add(jsonEncode(updatedOrderDetail.syncJson()));
      }
      // order_detail_value = _value.toString();
    }catch(e, stackTrace){
      FLog.error(
        className: "adjust_qty_dialog",
        text: "updateOrderDetailQuantity error",
        exception: "Error: $e, StackTrace: $stackTrace",
      );
      rethrow;
    }
  }

  _createOrderDetailCancel() async {
    try{
      List<String> _value = [];
      // OrderDetail data = await cancelQuery.readSpecificOrderDetailByLocalId(int.parse(widget.cartItem.order_detail_sqlite_id!));
      // OrderDetail data = await posDatabase.readSpecificOrderDetailByLocalId(int.parse(widget.cartItem.order_detail_sqlite_id!));
      OrderDetailCancel object = OrderDetailCancel(
        order_detail_cancel_id: 0,
        order_detail_cancel_key: '',
        order_detail_sqlite_id: _orderDetail.order_detail_sqlite_id.toString(),
        order_detail_key: _orderDetail.order_detail_key,
        quantity: cancelItemData.cancelQty.toString(),
        quantity_before_cancel: _orderDetail.quantity,
        cancel_by: _user.name,
        cancel_by_user_id: _user.user_id.toString(),
        cancel_reason: cancelItemData.reason,
        settlement_sqlite_id: '',
        settlement_key: '',
        status: 0,
        sync_status: 0,
        created_at: _currentDatetime,
        updated_at: '',
        soft_delete: '',
      );
      OrderDetailCancel orderDetailCancel = await _insertSqliteOrderDetailCancel(object);
      // OrderDetailCancel orderDetailCancel = await posDatabase.insertSqliteOrderDetailCancel(object);
      OrderDetailCancel updateData = await _insertOrderDetailCancelKey(orderDetailCancel);
      // _value.add(jsonEncode(updateData));
      // order_detail_cancel_value = _value.toString();
      //syncOrderDetailCancelToCloud(_value.toString());
    }catch(e, stackTrace){
      FLog.error(
        className: "adjust_qty_dialog",
        text: "insertOrderDetailCancelKey error",
        exception: "Error: $e, StackTrace: $stackTrace",
      );
      rethrow;
    }
  }

  _generateOrderDetailCancelKey(OrderDetailCancel orderDetailCancel) async {
    final prefs = await SharedPreferences.getInstance();
    final int? device_id = prefs.getInt('device_id');
    var bytes = orderDetailCancel.created_at!.replaceAll(new RegExp(r'[^0-9]'), '') +
        orderDetailCancel.order_detail_cancel_sqlite_id.toString() +
        device_id.toString();
    var md5Hash = md5.convert(utf8.encode(bytes));
    return Utils.shortHashString(hashCode: md5Hash);
  }

  _insertOrderDetailCancelKey(OrderDetailCancel orderDetailCancel) async {
    try{
      OrderDetailCancel? data;
      String? key = await _generateOrderDetailCancelKey(orderDetailCancel);
      if (key != null) {
        OrderDetailCancel object = OrderDetailCancel(
            order_detail_cancel_key: key,
            sync_status: 0,
            updated_at: _currentDatetime,
            order_detail_cancel_sqlite_id: orderDetailCancel.order_detail_cancel_sqlite_id);
        int uniqueKey = await _updateOrderDetailCancelUniqueKey(object);
        // await posDatabase.updateOrderDetailCancelUniqueKey(object);
        if (uniqueKey == 1) {
          // OrderDetailCancel orderDetailCancelData = await posDatabase.readSpecificOrderDetailCancelByLocalId(object.order_detail_cancel_sqlite_id!);
          data = orderDetailCancel.copy(
              order_detail_cancel_key: object.order_detail_cancel_key,
              sync_status: object.sync_status,
              updated_at: object.updated_at
          );
        }
      }
      return data;
    }catch(e, stackTrace){
      FLog.error(
        className: "adjust_qty_dialog",
        text: "insertOrderDetailCancelKey error",
        exception: "Error: $e, StackTrace: $stackTrace",
      );
      rethrow;
    }
  }

/*------------------------------------------------------------------------Query part---------------------------------------------------------------------------------*/

  Future<int> _updateSqlitePosTableStatus(PosTable data) async {
    try{
      return await _transaction.rawUpdate('UPDATE $tablePosTable SET '
          'sync_status = ?, table_use_detail_key = ?, table_use_key = ?, status = ?, updated_at = ? WHERE table_sqlite_id = ?',
          [2, data.table_use_detail_key, data.table_use_key, data.status, data.updated_at, data.table_sqlite_id]);
    }catch(e, stackTrace){
      FLog.error(
        className: "cancel query",
        text: "updatePosTableStatus error",
        exception: "Error: $e, StackTrace: $stackTrace",
      );
      rethrow;
    }
  }

  Future<int> _deleteTableUseID(TableUse data) async {
    try{
      return await _transaction.rawUpdate('UPDATE $tableTableUse SET updated_at = ?, status = ?, sync_status = ? WHERE table_use_sqlite_id = ?',
          [data.updated_at, data.status, data.sync_status, data.table_use_sqlite_id]);
    }catch(e, stackTrace){
      FLog.error(
        className: "cancel query",
        text: "deleteTableUseDetail error",
        exception: "Error: $e, StackTrace: $stackTrace",
      );
      rethrow;
    }
  }

  Future<int> _deleteTableUseDetail(TableUseDetail data) async {
    try{
      return await _transaction.rawUpdate('UPDATE $tableTableUseDetail SET updated_at = ?, sync_status = ?, status = ? WHERE table_use_detail_sqlite_id = ?',
          [data.updated_at, data.sync_status, data.status, data.table_use_detail_sqlite_id]);
    }catch(e, stackTrace){
      FLog.error(
        className: "cancel query",
        text: "deleteTableUseDetail error",
        exception: "Error: $e, StackTrace: $stackTrace",
      );
      rethrow;
    }
  }

  Future<int> _cancelOrderCache(OrderCache data) async {
    try{
      return await _transaction.rawUpdate('UPDATE $tableOrderCache SET sync_status = ?, cancel_by = ?, cancel_by_user_id = ? WHERE order_cache_sqlite_id = ?',
          [data.sync_status, data.cancel_by, data.cancel_by_user_id, data.order_cache_sqlite_id]);
    }catch(e, stackTrace){
      FLog.error(
        className: "cancel query",
        text: "cancelOrderCache error",
        exception: "Error: $e, StackTrace: $stackTrace",
      );
      rethrow;
    }
  }

  Future<int> _updateOrderDetailStatusAndQty(OrderDetail data) async {
    try{
      return await _transaction.rawUpdate('UPDATE $tableOrderDetail SET '
          'updated_at = ?, sync_status = ?, status = ?, quantity = ?, cancel_by = ?, cancel_by_user_id = ? WHERE order_detail_sqlite_id = ?',
          [data.updated_at, data.sync_status, data.status, data.quantity, data.cancel_by, data.cancel_by_user_id, data.order_detail_sqlite_id]);
    }catch(e, stackTrace){
      FLog.error(
        className: "cancel query",
        text: "updateOrderDetailStatus error",
        exception: "Error: $e, StackTrace: $stackTrace",
      );
      rethrow;
    }
  }

  Future<int> _updateBranchLinkProductStock(BranchLinkProduct data) async {
    try{
      return await _transaction.rawUpdate('UPDATE $tableBranchLinkProduct SET updated_at = ?, sync_status = ?, stock_quantity = ? WHERE branch_link_product_sqlite_id = ?',
          [data.updated_at, data.sync_status, data.stock_quantity, data.branch_link_product_sqlite_id]);
    }catch(e, stackTrace){
      FLog.error(
        className: "cancel query",
        text: "updateBranchLinkProductStock error",
        exception: "Error: $e, StackTrace: $stackTrace",
      );
      rethrow;
    }
  }

  Future<int> _updateBranchLinkProductDailyLimit(BranchLinkProduct data) async {
    try{
      return await _transaction.rawUpdate('UPDATE $tableBranchLinkProduct SET updated_at = ?, sync_status = ?, daily_limit = ? WHERE branch_link_product_sqlite_id = ?',
          [data.updated_at, data.sync_status, data.daily_limit, data.branch_link_product_sqlite_id]);
    }catch(e, stackTrace){
      FLog.error(
        className: "cancel query",
        text: "updateBranchLinkProductDailyLimit error",
        exception: "Error: $e, StackTrace: $stackTrace",
      );
      rethrow;
    }
  }

  Future<int> _updateSqliteOrderCacheSubtotal(OrderCache data) async {
    try{
      return await _transaction.rawUpdate('UPDATE $tableOrderCache SET sync_status = ?, total_amount = ?, updated_at = ? WHERE order_cache_sqlite_id = ?',
          [data.sync_status, data.total_amount, data.updated_at, data.order_cache_sqlite_id]);
    }catch(e, stackTrace){
      FLog.error(
        className: "cancel query",
        text: "updateOrderCacheSubtotal error",
        exception: "Error: $e, StackTrace: $stackTrace",
      );
      rethrow;
    }
  }

  Future<int> _updateSqliteOrderDetailQuantity(OrderDetail data) async {
    try{
      return _transaction.rawUpdate('UPDATE $tableOrderDetail SET updated_at = ?, sync_status = ?, quantity = ? WHERE order_detail_sqlite_id = ?',
          [data.updated_at, data.sync_status, data.quantity, data.order_detail_sqlite_id]);
    }catch(e, stackTrace){
      FLog.error(
        className: "cancel query",
        text: "updateOrderDetailQuantity error",
        exception: "Error: $e, StackTrace: $stackTrace",
      );
      rethrow;
    }
  }

  Future<int> _updateOrderDetailCancelUniqueKey(OrderDetailCancel data) async {
    try{
      return await _transaction.rawUpdate('UPDATE $tableOrderDetailCancel SET order_detail_cancel_key = ?, sync_status = ?, updated_at = ? WHERE order_detail_cancel_sqlite_id = ?', [
        data.order_detail_cancel_key,
        data.sync_status,
        data.updated_at,
        data.order_detail_cancel_sqlite_id,
      ]);
    }catch(e, stackTrace){
      FLog.error(
        className: "cancel query",
        text: "insertSqliteOrderDetailCancel error",
        exception: "Error: $e, StackTrace: $stackTrace",
      );
      rethrow;
    }
  }

  Future<OrderDetailCancel> _insertSqliteOrderDetailCancel(OrderDetailCancel data) async {
    try{
      final id = await _transaction.insert(tableOrderDetailCancel!, data.toJson());
      return data.copy(order_detail_cancel_sqlite_id: id);
    }catch(e, stackTrace){
      FLog.error(
        className: "cancel query in second device",
        text: "insertSqliteOrderDetailCancel error",
        exception: "Error: $e, StackTrace: $stackTrace",
      );
      rethrow;
    }
  }

  Future<TableUse?> _readSpecificTableUseIdByLocalId(int table_use_sqlite_id) async {
    try{
      final result = await _transaction.rawQuery('SELECT * FROM $tableTableUse '
          'WHERE table_use_sqlite_id = ? ', [table_use_sqlite_id]);
      if(result.isNotEmpty){
        return TableUse.fromJson(result.first);
      } else {
        return null;
      }
    }catch(e, stackTrace){
      FLog.error(
        className: "cancel query",
        text: "deleteTableUseDetail error",
        exception: "Error: $e, StackTrace: $stackTrace",
      );
      rethrow;
    }
  }

  Future<List<TableUseDetail>> _readAllTableUseDetail(String table_use_sqlite_id) async {
    try{
      final result = await _transaction.rawQuery('SELECT * '
          'FROM $tableTableUseDetail WHERE soft_delete = ? AND status = ? AND table_use_sqlite_id = ?',
          ['', 0, table_use_sqlite_id]);

      return result.map((json) => TableUseDetail.fromJson(json)).toList();
    }catch(e, stackTrace){
      FLog.error(
        className: "cancel query",
        text: "readAllTableUseDetail error",
        exception: "Error: $e, StackTrace: $stackTrace",
      );
      rethrow;
    }
  }

  Future<List<BranchLinkProduct>> _readSpecificBranchLinkProduct(String branch_link_product_sqlite_id) async {
    try{
      final result = await _transaction.rawQuery(
          'SELECT a.*, b.name, b.allow_ticket, b.ticket_count, b.ticket_exp '
              'FROM $tableBranchLinkProduct AS a JOIN $tableProduct AS b ON a.product_id = b.product_id '
              'WHERE b.soft_delete = ? AND a.branch_link_product_sqlite_id = ?',
          ['', branch_link_product_sqlite_id]);

      return result.map((json) => BranchLinkProduct.fromJson(json)).toList();
    }catch(e, stackTrace){
      FLog.error(
        className: "cancel query",
        text: "readSpecificBranchLinkProduct error",
        exception: "Error: $e, StackTrace: $stackTrace",
      );
      rethrow;
    }
  }

  Future<OrderCache?> _readSpecificOrderCacheByLocalId(int order_cache_sqlite_id) async {
    try{
      final result = await _transaction.rawQuery('SELECT * FROM $tableOrderCache  '
          'WHERE order_cache_sqlite_id = ? AND soft_delete = ?',
          [order_cache_sqlite_id, '']);
      return result.isNotEmpty ? OrderCache.fromJson(result.first) : null;
    }catch(e, stackTrace){
      FLog.error(
        className: "cancel query",
        text: "readSpecificOrderCacheByLocalId error",
        exception: "Error: $e, StackTrace: $stackTrace",
      );
      rethrow;
    }
  }

  Future<List<OrderDetail>> readAllOrderDetailByOrderCacheSqliteId(String sqliteId) async {
    try{
      var result = await _transaction.rawQuery("SELECT * FROM $tableOrderDetail WHERE order_cache_sqlite_id = ? AND soft_delete = ? AND cancel_by = ? ",
          [sqliteId, '', '']);
      return result.isNotEmpty ? result.map((e) => OrderDetail.fromJson(e)).toList() : [];
    }catch(e, s){
      // FLog.error(
      //   className: "settlement query",
      //   text: "_readSales error",
      //   exception: 'Error: $e, Stacktrace: $s',
      // );
      rethrow;
    }
  }


  Future<List<OrderCache>> readOrderCacheByTableUseKey(String table_use_key) async {
    try{
      var result = await _transaction.rawQuery("SELECT * FROM $tableOrderCache WHERE table_use_key = ? AND soft_delete = ? AND cancel_by = ? ",
          [table_use_key, '', '']);
      return result.isNotEmpty ? result.map((e) => OrderCache.fromJson(e)).toList() : [];
    }catch(e, s){
      // FLog.error(
      //   className: "settlement query",
      //   text: "_readSales error",
      //   exception: 'Error: $e, Stacktrace: $s',
      // );
      rethrow;
    }
  }

  Future<OrderDetail?> readSpecificOrderDetailJoinOrderCache(String orderDetailSqliteId) async {
    try{
      var result = await _transaction.rawQuery("SELECT a.*, b.table_use_key, b.table_use_sqlite_id FROM $tableOrderDetail AS a "
          "JOIN $tableOrderCache AS b ON a.order_cache_sqlite_id == b.order_cache_sqlite_id "
          "WHERE a.order_detail_sqlite_id = ? AND a.soft_delete = ? AND a.status = ? ",
          [orderDetailSqliteId, '', 0]);
      return result.isNotEmpty ? OrderDetail.fromJson(result.first) : null;
    }catch(e, s){
      // FLog.error(
      //   className: "settlement query",
      //   text: "_readSales error",
      //   exception: 'Error: $e, Stacktrace: $s',
      // );
      rethrow;
    }
  }

  Future<User?> readSpecificUserById(int userId) async {
    try{
      var result = await _transaction.rawQuery("SELECT * FROM $tableUser WHERE user_id = ? AND soft_delete = ? AND status = ?",
          [userId, '', 0]);
      return result.isNotEmpty ? User.fromJson(result.first) : null;
    }catch(e, s){
      // FLog.error(
      //   className: "settlement query",
      //   text: "_readSales error",
      //   exception: 'Error: $e, Stacktrace: $s',
      // );
      rethrow;
    }
  }
}