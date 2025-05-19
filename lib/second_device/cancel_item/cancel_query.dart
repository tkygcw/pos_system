import 'package:pos_system/object/order_cache.dart';
import 'package:pos_system/object/order_detail.dart';
import 'package:pos_system/object/user.dart';
import 'package:sqflite/sqflite.dart';

import '../../object/order_detail_cancel.dart';

class CancelQuery {
  late Transaction _transaction;

  CancelQuery(this._transaction);


  Future<void> callUpdateOrderDetail() async {
    await _createOrderDetailCancel();
    await _updateOrderDetailQuantity();
  }

  _createOrderDetailCancel() async {
    try{
      List<String> _value = [];
      // OrderDetail data = await cancelQuery.readSpecificOrderDetailByLocalId(int.parse(widget.cartItem.order_detail_sqlite_id!));
      // OrderDetail data = await posDatabase.readSpecificOrderDetailByLocalId(int.parse(widget.cartItem.order_detail_sqlite_id!));
      OrderDetailCancel object = OrderDetailCancel(
        order_detail_cancel_id: 0,
        order_detail_cancel_key: '',
        order_detail_sqlite_id: _cartItem.order_detail_sqlite_id,
        order_detail_key: _orderDetail.order_detail_key,
        quantity: _cancelQuantity.toString(),
        quantity_before_cancel: _cartItem.quantity! is double ?
        _cartItem.quantity!.toStringAsFixed(2): _cartItem.quantity!.toString(),
        cancel_by: _user.name,
        cancel_by_user_id: _user.user_id.toString(),
        cancel_reason: _reason,
        settlement_sqlite_id: '',
        settlement_key: '',
        status: 0,
        sync_status: 0,
        created_at: _dateTime,
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

  Future<List<OrderDetail>> readAllOrderDetailByOrderCacheSqliteId(String sqliteId) async {
    try{
      var result = await _transaction.rawQuery("SELECT * FROM $tableOrderCache WHERE order_cache_sqlite_id = ? AND soft_delete = ? AND cancel_by = ? ",
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
      var result = await _transaction.rawQuery("SELECT a.*, b.table_use_key FROM $tableOrderDetail AS a "
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

  Future<User?> readSpecificUserById(String userId) async {
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