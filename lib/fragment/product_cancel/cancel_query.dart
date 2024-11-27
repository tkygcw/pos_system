import 'package:f_logs/model/flog/flog.dart';

import '../../object/branch_link_product.dart';
import '../../object/categories.dart';
import '../../object/dining_option.dart';
import '../../object/order_cache.dart';
import '../../object/order_detail.dart';
import '../../object/order_detail_cancel.dart';
import '../../object/product.dart';
import '../../object/table.dart';
import '../../object/table_use.dart';
import '../../object/table_use_detail.dart';

class CancelQuery{
  late final transaction;
  CancelQuery({required this.transaction});

  Future<OrderDetailCancel> insertSqliteOrderDetailCancel(OrderDetailCancel data) async {
    try{
      final id = await transaction.insert(tableOrderDetailCancel!, data.toJson());
      return data.copy(order_detail_cancel_sqlite_id: id);
    }catch(e, stackTrace){
      FLog.error(
        className: "cancel query",
        text: "insertSqliteOrderDetailCancel error",
        exception: "Error: $e, StackTrace: $stackTrace",
      );
      rethrow;
    }
  }

  Future<int> updateOrderDetailCancelUniqueKey(OrderDetailCancel data) async {
    try{
      return await transaction.rawUpdate('UPDATE $tableOrderDetailCancel SET order_detail_cancel_key = ?, sync_status = ?, updated_at = ? WHERE order_detail_cancel_sqlite_id = ?', [
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

  Future<int> updateOrderDetailQuantity(OrderDetail data) async {
    try{
      return transaction.rawUpdate('UPDATE $tableOrderDetail SET updated_at = ?, sync_status = ?, quantity = ? WHERE order_detail_sqlite_id = ?',
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

  Future<OrderDetail> readSpecificOrderDetailByLocalId(int order_detail_sqlite_id) async {
    try{
      final result = await transaction.rawQuery(
          'SELECT a.soft_delete, a.updated_at, a.created_at, a.per_quantity_unit, a.unit, a.sync_status, a.status, a.cancel_by_user_id, a.cancel_by, a.edited_by_user_id, a.edited_by, '
              'a.account, a.remark, a.quantity, a.original_price, a.price, a.product_variant_name, a.has_variant, a.product_name, a.category_name, a.order_cache_key, a.order_cache_sqlite_id, '
              'a.order_detail_key, a.branch_link_product_sqlite_id, IFNULL( (SELECT category_id FROM $tableCategories WHERE category_sqlite_id = a.category_sqlite_id), 0) AS category_id,'
              'c.branch_link_product_id FROM $tableOrderDetail AS a '
              'LEFT JOIN $tableBranchLinkProduct AS c ON a.branch_link_product_sqlite_id = c.branch_link_product_sqlite_id '
              'WHERE a.order_detail_sqlite_id = ? ',
          [order_detail_sqlite_id]);

      return OrderDetail.fromJson(result.first);
    }catch(e, stackTrace){
      FLog.error(
        className: "cancel query",
        text: "readSpecificOrderDetailByLocalId error",
        exception: "Error: $e, StackTrace: $stackTrace",
      );
      rethrow;
    }
  }

  Future<OrderCache> readSpecificOrderCacheByLocalId(int order_cache_sqlite_id) async {
    try{
      final result = await transaction.rawQuery(
          'SELECT a.soft_delete, a.updated_at, a.created_at, a.sync_status, a.accepted, a.qr_order_table_id, a.qr_order_table_sqlite_id, a.qr_order, a.total_amount, '
              'a.customer_id, a.cancel_by_user_id, a.cancel_by, '
              'a.order_by_user_id, a.order_by, a.order_key, a.order_sqlite_id, a.dining_id, a.batch_id, a.table_use_key, a.table_use_sqlite_id, a.order_detail_id, a.branch_id, '
              'a.company_id, a.order_queue, a.order_cache_key, a.order_cache_id, a.order_cache_sqlite_id, '
              'b.name AS name FROM $tableOrderCache AS a JOIN $tableDiningOption AS b ON a.dining_id = b.dining_id WHERE a.order_cache_sqlite_id = ? AND b.soft_delete = ?',
          [order_cache_sqlite_id, '']);
      return OrderCache.fromJson(result.first);
    }catch(e, stackTrace){
      FLog.error(
        className: "cancel query",
        text: "readSpecificOrderCacheByLocalId error",
        exception: "Error: $e, StackTrace: $stackTrace",
      );
      rethrow;
    }
  }

  Future<int> updateOrderCacheSubtotal(OrderCache data) async {
    try{
      return await transaction.rawUpdate('UPDATE $tableOrderCache SET sync_status = ?, total_amount = ?, updated_at = ? WHERE order_cache_sqlite_id = ?',
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

  Future<List<BranchLinkProduct>> readSpecificBranchLinkProduct(String branch_link_product_sqlite_id) async {
    try{
      final result = await transaction.rawQuery(
          'SELECT a.*, b.name, b.allow_ticket, b.ticket_count, b.ticket_exp '
              'FROM $tableBranchLinkProduct AS a JOIN $tableProduct AS b ON a.product_id = b.product_id '
              'WHERE b.soft_delete = ? AND a.branch_link_product_sqlite_id = ?',
          ['', branch_link_product_sqlite_id]) as List<Map<String, Object?>>;

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

  Future<int> updateBranchLinkProductDailyLimit(BranchLinkProduct data) async {
    try{
      return await transaction.rawUpdate('UPDATE $tableBranchLinkProduct SET updated_at = ?, sync_status = ?, daily_limit = ? WHERE branch_link_product_sqlite_id = ?',
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

  Future<int> updateBranchLinkProductStock(BranchLinkProduct data) async {
    try{
      return await transaction.rawUpdate('UPDATE $tableBranchLinkProduct SET updated_at = ?, sync_status = ?, stock_quantity = ? WHERE branch_link_product_sqlite_id = ?',
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

  Future<OrderDetail> readSpecificOrderDetailByLocalIdNoJoin(String order_detail_sqlite_id) async {
    try{
      final result = await transaction.rawQuery(
          'SELECT * FROM $tableOrderDetail WHERE order_detail_sqlite_id = ? ',
          [order_detail_sqlite_id]);

      return OrderDetail.fromJson(result.first);
    }catch(e, stackTrace){
      FLog.error(
        className: "cancel query",
        text: "readSpecificOrderDetailByLocalIdNoJoin error",
        exception: "Error: $e, StackTrace: $stackTrace",
      );
      rethrow;
    }
  }

  Future<int> updateOrderDetailStatus(OrderDetail data) async {
    try{
      return await transaction.rawUpdate('UPDATE $tableOrderDetail SET updated_at = ?, sync_status = ?, status = ?, cancel_by = ?, cancel_by_user_id = ? WHERE order_detail_sqlite_id = ?',
          [data.updated_at, data.sync_status, data.status, data.cancel_by, data.cancel_by_user_id, data.order_detail_sqlite_id]);
    }catch(e, stackTrace){
      FLog.error(
        className: "cancel query",
        text: "updateOrderDetailStatus error",
        exception: "Error: $e, StackTrace: $stackTrace",
      );
      rethrow;
    }
  }

  Future<int> cancelOrderCache(OrderCache data) async {
    try{
      return await transaction.rawUpdate('UPDATE $tableOrderCache SET sync_status = ?, cancel_by = ?, cancel_by_user_id = ? WHERE order_cache_sqlite_id = ?',
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

  Future<List<TableUseDetail>> readAllTableUseDetail(String table_use_sqlite_id) async {
    try{
      final result = await transaction.rawQuery('SELECT * '
          'FROM $tableTableUseDetail WHERE soft_delete = ? AND status = ? AND table_use_sqlite_id = ?',
          ['', 0, table_use_sqlite_id]) as List<Map<String, Object?>>;

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

  Future<int> deleteTableUseDetail(TableUseDetail data) async {
    try{
      return await transaction.rawUpdate('UPDATE $tableTableUseDetail SET updated_at = ?, sync_status = ?, status = ? WHERE table_use_sqlite_id = ? AND table_use_detail_sqlite_id = ?',
          [data.updated_at, data.sync_status, data.status, data.table_use_sqlite_id, data.table_use_detail_sqlite_id]);
    }catch(e, stackTrace){
      FLog.error(
        className: "cancel query",
        text: "deleteTableUseDetail error",
        exception: "Error: $e, StackTrace: $stackTrace",
      );
      rethrow;
    }
  }

  Future<TableUse?> readSpecificTableUseIdByLocalId(int table_use_sqlite_id) async {
    try{
      final result = await transaction.rawQuery('SELECT * FROM $tableTableUse '
          'WHERE table_use_sqlite_id = ? ', [table_use_sqlite_id]) as List<Map<String, Object?>>;
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

  Future<int> deleteTableUseID(TableUse data) async {
    try{
      return await transaction.rawUpdate('UPDATE $tableTableUse SET updated_at = ?, status = ?, sync_status = ? WHERE table_use_sqlite_id = ?',
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

  Future<int> updatePosTableStatus(PosTable data) async {
    try{
      return await transaction.rawUpdate('UPDATE $tablePosTable SET '
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

}