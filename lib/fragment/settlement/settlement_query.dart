import 'dart:convert';

import 'package:f_logs/model/flog/flog.dart';
import 'package:intl/intl.dart';
import 'package:pos_system/database/pos_database.dart';
import 'package:pos_system/object/categories.dart';
import 'package:pos_system/object/modifier_group.dart';
import 'package:pos_system/object/modifier_item.dart';
import 'package:pos_system/object/order_tax_detail.dart';
import 'package:pos_system/object/product.dart';
import 'package:pos_system/object/sales_per_day/category_sales_per_day.dart';
import 'package:pos_system/object/sales_per_day/modifier_sales_per_day.dart';
import 'package:pos_system/object/sales_per_day/sales_per_day.dart';
import 'package:pos_system/utils/Utils.dart';

import '../../object/order.dart';
import '../../object/order_cache.dart';
import '../../object/order_detail.dart';
import '../../object/order_modifier_detail.dart';
import '../../object/order_promotion_detail.dart';
import '../../object/sales_per_day/dining_sales_per_day.dart';
import '../../object/sales_per_day/product_sales_per_day.dart';

class SettlementQuery {
  final _posDatabase = PosDatabase.instance;
  late final String _currentDateTime, _branch_id;
  late final _transaction;
  String _currentSalesDate = '';

  SettlementQuery({required String branch_id}){
    _branch_id = branch_id;
  }

  generateSalesPerDay() async {
    _currentDateTime = Utils.dbCurrentDateTimeFormat();
    var db = await _posDatabase.database;
    await db.transaction((txn) async {
      _transaction = txn;
      List<Order> data = await _readSales();
      if(data.isNotEmpty){
        for(var sales in data){
          _currentSalesDate = sales.created_at!;
          await _insertSqliteSalesPerDay(sales);
          await _generateCategorySales();
          await _generateProductSales();
          await _generateModSales();
          await _generateDiningSales();
        }
      }
    });
  }

  _generateDiningSales() async {
    try{
      DateTime _endDate = DateTime.parse(_currentSalesDate).add(Duration(days: 1));
      List<Order> orderList = await _readAllPaidDining(_currentSalesDate.substring(0, 10), _endDate.toString().substring(0, 10));
      var data = SalesDiningPerDay(
        sales_dining_per_day_id: 0,
        branch_id: _branch_id,
        dine_in: '',
        take_away: '',
        delivery: '',
        date: _currentSalesDate.substring(0, 10),
        type: 1,
        sync_status: 0,
        created_at: _currentDateTime,
        updated_at: '',
        soft_delete: '',
      );
      for(int i = 0; i < orderList.length; i++){
        var order = orderList[i];
        if(order.dining_name == 'Dine in'){
          data = data.copy(dine_in: order.gross_sales!.toStringAsFixed(2));
        } else if (order.dining_name == 'Take Away'){
          data = data.copy(take_away: order.gross_sales!.toStringAsFixed(2));
        } else {
          data = data.copy(delivery: order.gross_sales!.toStringAsFixed(2));
        }
      }
      await _insertSqliteDiningSalesPerDay(data);
    } catch(e, s){
      FLog.error(
        className: "settlement query",
        text: "_insertSqliteDiningSalesPerDay error",
        exception: 'Error: $e, Stacktrace: $s',
      );
      rethrow;
    }
  }

  Future<SalesDiningPerDay> _insertSqliteDiningSalesPerDay(SalesDiningPerDay data) async {
    try{
      final id = await _transaction.insert(tableSalesDiningPerDay, data.toJson());
      return data.copy(sales_dining_per_day_sqlite_id: id);
    }catch(e, s){
      FLog.error(
        className: "settlement query",
        text: "_insertSqliteDiningSalesPerDay error",
        exception: 'Error: $e, Stacktrace: $s',
      );
      rethrow;
    }
  }

/*
  read all paid Dining
*/
  Future<List<Order>> _readAllPaidDining(String date1, String date2) async {
    try{
      final result = await _transaction.rawQuery(
          'SELECT a.*, COUNT(order_sqlite_id) AS item_sum, SUM(final_amount + 0.0) AS gross_sales, SUM(subtotal + 0.0) AS net_sales '
              'FROM $tableOrder AS a WHERE a.soft_delete = ? AND a.payment_status = ? '
              'AND SUBSTR(a.created_at, 1, 10) >= ? AND SUBSTR(a.created_at, 1, 10) < ? GROUP BY a.dining_name',
          ['', 1, date1, date2]) as List<Map<String, Object?>>;
      return result.map((json) => Order.fromJson(json)).toList();
    }catch(e, s){
      FLog.error(
        className: "settlement query",
        text: "_readAllPaidDining error",
        exception: 'Error: $e, Stacktrace: $s',
      );
      rethrow;
    }
  }

  _generateModSales() async {
    try{
      DateTime _endDate = DateTime.parse(_currentSalesDate).add(Duration(days: 1));
      List<OrderModifierDetail> modDetail = await _readAllPaidModifier(_currentSalesDate.substring(0, 10), _endDate.toString().substring(0, 10));
      for(var detail in modDetail){
        await _insertSqliteModifierSalesPerDay(detail);
      }
    }catch(e, s){
      FLog.error(
        className: "settlement query",
        text: "_generateModSales error",
        exception: 'Error: $e, Stacktrace: $s',
      );
      rethrow;
    }
  }

  Future<SalesModifierPerDay> _insertSqliteModifierSalesPerDay(OrderModifierDetail modDetail) async {
    try{
      var data = SalesModifierPerDay(
        sales_modifier_per_day_id: 0,
        branch_id: _branch_id,
        mod_item_id: modDetail.mod_item_id!,
        mod_group_id: modDetail.mod_group_id!,
        modifier_name: modDetail.mod_name!,
        modifier_group_name: modDetail.mod_group_name,
        amount_sold: modDetail.item_sum!.toString(),
        total_amount: modDetail.net_sales!.toStringAsFixed(2),
        total_ori_amount: modDetail.net_sales!.toStringAsFixed(2),
        date: _currentSalesDate.substring(0, 10),
        type: 1,
        sync_status: 0,
        created_at: _currentDateTime,
        updated_at: '',
        soft_delete: '',
      );
      final id = await _transaction.insert(tableSalesModifierPerDay, data.toJson());
      return data.copy(sales_modifier_per_day_sqlite_id: id);
    }catch(e, s){
      FLog.error(
        className: "settlement query",
        text: "_insertSqliteModifierSalesPerDay error",
        exception: 'Error: $e, Stacktrace: $s',
      );
      rethrow;
    }
  }

/*
  read all paid modifier
*/
  Future<List<OrderModifierDetail>> _readAllPaidModifier(String date1, String date2) async {
    try{
      final result = await _transaction.rawQuery(
          'WITH Modifier AS (SELECT a.mod_item_id, b.name AS mod_group_name '
              'FROM $tableModifierItem AS a JOIN $tableModifierGroup AS b '
              'ON a.mod_group_id = b.mod_group_id GROUP BY a.mod_item_id) '
              'SELECT a.*, '
              'SUM(CASE WHEN b.unit != ? AND b.unit != ? THEN 1 ELSE b.quantity END) AS item_sum, '
              'SUM(CASE WHEN b.unit != ? AND b.unit != ? THEN a.mod_price * 1 + 0.0 ELSE a.mod_price * b.quantity + 0.0 END) AS net_sales, '
              'COALESCE(M.mod_group_name, ?) AS mod_group_name '
              'FROM $tableOrderModifierDetail AS a JOIN $tableOrderDetail AS b ON a.order_detail_sqlite_id = b.order_detail_sqlite_id '
              'JOIN $tableOrderCache AS c ON b.order_cache_sqlite_id = c.order_cache_sqlite_id '
              'JOIN $tableOrder AS d ON c.order_sqlite_id = d.order_sqlite_id '
              'LEFT JOIN Modifier M ON a.mod_item_id = M.mod_item_id '
              'WHERE a.soft_delete = ? AND b.soft_delete = ? AND c.soft_delete = ? AND c.accepted = ? AND c.cancel_by = ? AND d.soft_delete = ? '
              'AND b.status = ? AND d.payment_status = ? '
              'AND SUBSTR(a.created_at, 1, 10) >= ? AND SUBSTR(a.created_at, 1, 10) < ? GROUP BY a.mod_name',
          ['each', 'each_c', 'each', 'each_c', '', '', '', '', 0, '', '', 0, 1, date1, date2]) as List<Map<String, Object?>>;
      return result.map((json) => OrderModifierDetail.fromJson(json)).toList();
    }catch(e, s){
      FLog.error(
        className: "settlement query",
        text: "_readAllPaidModifier error",
        exception: 'Error: $e, Stacktrace: $s',
      );
      rethrow;
    }
  }

  _generateProductSales() async {
    try{
      DateTime _endDate = DateTime.parse(_currentSalesDate).add(Duration(days: 1));
      List<OrderDetail> orderDetail = await _readAllProductWithOrderDetail(_currentSalesDate.substring(0, 10), _endDate.toString().substring(0, 10));
      for(var detail in orderDetail){
        await _insertSqliteProductSalesPerDay(detail);
      }
    }catch(e, s){
      FLog.error(
        className: "settlement query",
        text: "_generateProductSales error",
        exception: 'Error: $e, Stacktrace: $s',
      );
      rethrow;
    }
  }

  Future<SalesProductPerDay> _insertSqliteProductSalesPerDay(OrderDetail orderDetail) async {
    try{
      var data = SalesProductPerDay(
        sales_product_per_day_id: 0,
        branch_id: _branch_id,
        product_id: orderDetail.product_id!.toString(),
        product_name: orderDetail.productName ?? '',
        amount_sold: orderDetail.unit != 'each' && orderDetail.unit != 'each_c' ? orderDetail.item_qty!.toString() : orderDetail.item_sum!.toString(),
        total_amount: orderDetail.gross_price!.toStringAsFixed(2),
        total_ori_amount: orderDetail.net_sales!.toStringAsFixed(2),
        date: _currentSalesDate.substring(0, 10),
        type: 1,
        sync_status: 0,
        created_at: _currentDateTime,
        updated_at: '',
        soft_delete: '',
      );
      final id = await _transaction.insert(tableSalesProductPerDay, data.toJson());
      return data.copy(sales_product_per_day_sqlite_id: id);
    }catch(e, s){
      FLog.error(
        className: "settlement query",
        text: "_insertSqliteProductSalesPerDay error",
        exception: 'Error: $e, Stacktrace: $s',
      );
      rethrow;
    }
  }


/*
  read all product with order detail
*/
  Future<List<OrderDetail>> _readAllProductWithOrderDetail(String date1, String date2) async {
    try{
      final result = await _transaction.rawQuery(
          'WITH Product AS (SELECT SKU, product_id FROM $tableProduct GROUP BY product_sqlite_id ) '
              'SELECT a.created_at, a.product_name, a.product_variant_name, a.unit, SUM(a.original_price * a.quantity + 0.0) AS net_sales, '
              'SUM(a.price * a.quantity + 0.0) AS gross_price, '
              'SUM(CASE WHEN a.unit != ? AND a.unit != ? THEN a.per_quantity_unit * a.quantity ELSE a.quantity END) AS item_sum, '
              'SUM(CASE WHEN a.unit != ? THEN 1 ELSE 0 END) AS item_qty, '
              'COALESCE(P.product_id, 0) AS product_id '
              'FROM $tableOrderDetail AS a JOIN $tableOrderCache AS b ON a.order_cache_sqlite_id = b.order_cache_sqlite_id '
              'JOIN $tableOrder AS c ON b.order_sqlite_id = c.order_sqlite_id '
              'LEFT JOIN Product P ON a.product_sku = P.SKU '
              'WHERE a.soft_delete = ? AND a.status = ? AND b.soft_delete = ? AND b.accepted = ? AND c.soft_delete = ? AND c.payment_status = ?'
              'AND SUBSTR(a.created_at, 1, 10) >= ? AND SUBSTR(a.created_at, 1, 10) < ? '
              'GROUP BY a.product_name '
              'ORDER BY a.product_name',
          ['each', 'each_c', 'each', '', 0, '', 0, '', 1, date1, date2]) as List<Map<String, Object?>>;
      return result.map((json) => OrderDetail.fromJson(json)).toList();
    }catch(e, s){
      FLog.error(
        className: "settlement query",
        text: "_readAllProductWithOrderDetail error",
        exception: 'Error: $e, Stacktrace: $s',
      );
      rethrow;
    }
  }

  _generateCategorySales() async {
    try{
      DateTime _endDate = DateTime.parse(_currentSalesDate).add(Duration(days: 1));
      List<OrderDetail> orderDetail = await _readAllCategoryWithOrderDetail(_currentSalesDate.substring(0, 10), _endDate.toString().substring(0, 10));
      for(var detail in orderDetail){
        await _insertSqliteCategorySalesPerDay(detail);
      }
    }catch(e, s){
      FLog.error(
        className: "settlement query",
        text: "_generateCategorySales error",
        exception: 'Error: $e, Stacktrace: $s',
      );
      rethrow;
    }
  }

  Future<SalesCategoryPerDay> _insertSqliteCategorySalesPerDay(OrderDetail orderDetail) async {
    try{
      var data = SalesCategoryPerDay(
        sales_category_per_day_id: 0,
        branch_id: _branch_id,
        category_id: orderDetail.category_id!.toString(),
        category_name: orderDetail.category_name ?? '',
        amount_sold: orderDetail.category_item_sum! is double ? orderDetail.category_item_sum!.toStringAsFixed(2) : orderDetail.category_item_sum!.toString(),
        total_amount: orderDetail.category_gross_sales!.toStringAsFixed(2),
        total_ori_amount: orderDetail.category_gross_sales!.toStringAsFixed(2),
        date: _currentSalesDate.substring(0, 10),
        type: 1,
        sync_status: 0,
        created_at: _currentDateTime,
        updated_at: '',
        soft_delete: '',
      );
      final id = await _transaction.insert(tableSalesCategoryPerDay, data.toJson());
      return data.copy(category_sales_per_day_sqlite_id: id);
    }catch(e, s){
      FLog.error(
        className: "settlement query",
        text: "_insertSqliteCategorySalesPerDay error",
        exception: 'Error: $e, Stacktrace: $s',
      );
      rethrow;
    }
  }

/*
  read all category with product
*/
  Future<List<OrderDetail>> _readAllCategoryWithOrderDetail(String date1, String date2) async {
    try{
      final result = await _transaction.rawQuery(
          'WITH Category AS (SELECT category_sqlite_id, category_id FROM $tableCategories GROUP BY category_sqlite_id ) '
              'SELECT b.*, SUM(b.original_price * b.quantity + 0.0) AS category_gross_sales, SUM(b.price * b.quantity + 0.0) AS category_net_sales, '
              'SUM(CASE WHEN b.unit != ? AND b.unit != ? THEN 1 ELSE b.quantity END) AS category_item_sum, '
              'COALESCE(C.category_id, 0) AS category_id '
              'FROM $tableOrderDetail AS b JOIN $tableOrderCache AS c ON b.order_cache_sqlite_id = c.order_cache_sqlite_id '
              'JOIN $tableOrder AS d ON c.order_sqlite_id = d.order_sqlite_id '
              'LEFT JOIN Category C ON b.category_sqlite_id = C.category_sqlite_id '
              'WHERE b.soft_delete = ? AND c.soft_delete = ? AND c.accepted = ? AND c.cancel_by = ? AND d.soft_delete = ? AND b.status = ? AND d.payment_status = ? '
              'AND SUBSTR(b.created_at, 1, 10) >= ? AND SUBSTR(b.created_at, 1, 10) < ? GROUP BY b.category_name '
              'ORDER BY b.category_name DESC',
          ['each', 'each_c', '', '', 0, '', '', 0, 1, date1, date2]) as List<Map<String, Object?>>;
      return result.map((json) => OrderDetail.fromJson(json)).toList();
    }catch(e, s){
      FLog.error(
        className: "settlement query",
        text: "_readAllCategoryWithOrderDetail error",
        exception: 'Error: $e, Stacktrace: $s',
      );
      rethrow;
    }
  }


  Future<SalesPerDay> _insertSqliteSalesPerDay(Order sales) async {
    try{
      var data = SalesPerDay(
        sales_per_day_id: 0,
        branch_id: _branch_id,
        total_amount: sales.total_sales!.toStringAsFixed(2),
        tax: sales.total_tax_amount!.toStringAsFixed(2),
        charge: sales.total_charge_amount!.toStringAsFixed(2),
        promotion: sales.total_promo_amount!.toStringAsFixed(2),
        rounding: sales.total_rounding!.toStringAsFixed(2),
        date: _currentSalesDate.substring(0, 10),
        payment_method_sales: '',
        payment_method: '',
        type: 1,
        sync_status: 0,
        created_at: _currentDateTime,
        updated_at: '',
        soft_delete: '',
      );
      final id = await _transaction.insert(tableSalesPerDay, data.toJson());
      return data.copy(sales_per_day_sqlite_id: id);
    }catch(e, s){
      FLog.error(
        className: "settlement query",
        text: "_insertSqliteSalesPerDay error",
        exception: 'Error: $e, Stacktrace: $s',
      );
      rethrow;
    }
  }

/*
  get not yet settlement order
*/
  Future<List<Order>> _readSales() async {
    try{
      String currentDate = _currentDateTime.substring(0, 10);
      String endDate = DateFormat("yyyy-MM-dd").format(DateTime.parse(_currentDateTime).add(Duration(days: 1)));
      final result = await _transaction.rawQuery(
          'WITH PromoSums AS (SELECT order_sqlite_id, SUM(promotion_amount) AS TotalPromoAmount FROM $tableOrderPromotionDetail GROUP BY order_sqlite_id ), '
              'TaxSums AS (SELECT order_sqlite_id, SUM(CASE WHEN type = ? THEN tax_amount ELSE 0.0 END) AS TaxType0Amount, '
              'SUM(CASE WHEN type = ? THEN tax_amount ELSE 0.0 END) AS TaxType1Amount FROM $tableOrderTaxDetail GROUP BY order_sqlite_id )'
              'SELECT o.created_at as created_at, SUM(o.final_amount) AS total_sales, '
              'SUM(o.rounding) AS total_rounding, '
              'COALESCE(SUM(P.TotalPromoAmount), 0.0) AS total_promo_amount, '
              'COALESCE(SUM(T.TaxType0Amount), 0.0) AS total_charge_amount, '
              'COALESCE(SUM(T.TaxType1Amount), 0.0) AS total_tax_amount '
              'FROM $tableOrder o '
              'LEFT JOIN PromoSums P ON o.order_sqlite_id = P.order_sqlite_id '
              'LEFT JOIN TaxSums T ON o.order_sqlite_id = T.order_sqlite_id '
              'WHERE SUBSTR(o.created_at, 1, 10) >= ? AND SUBSTR(o.created_at, 1, 10) < ? '
              'GROUP BY SUBSTR(o.created_at, 1, 10) ',
          ['0', '1', currentDate, endDate]) as List<Map<String, Object?>>;
      return result.map((json) => Order.fromJson(json)).toList();
    }catch(e, s){
      FLog.error(
        className: "settlement query",
        text: "_readSales error",
        exception: 'Error: $e, Stacktrace: $s',
      );
      rethrow;
    }
  }
}