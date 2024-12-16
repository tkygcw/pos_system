import 'package:f_logs/model/flog/flog.dart';
import 'package:intl/intl.dart';
import 'package:pos_system/database/pos_database.dart';
import 'package:pos_system/object/order_tax_detail.dart';
import 'package:pos_system/object/sales_per_day.dart';
import 'package:pos_system/utils/Utils.dart';

import '../../object/order.dart';
import '../../object/order_promotion_detail.dart';

class SettlementQuery {
  final _posDatabase = PosDatabase.instance;
  late final _currentDateTime;
  late final _transaction;

  SettlementQuery(){
   _currentDateTime = Utils.dbCurrentDateTimeFormat();
  }

  generateSalesPerDay() async {
    var db = await _posDatabase.database;
    await db.transaction((txn) async {
      _transaction = txn;
      List<Order> data = await _readSales();
      if(data.isNotEmpty){
        print("data length: ${data.length}");
        for(var sales in data){
          print("date: ${sales.created_at!.substring(0, 10)}");
          print("total tax: ${sales.total_tax_amount!.toStringAsFixed(2)}");
          print("total charge: ${sales.total_charge_amount}");
          print("total sales: ${sales.total_sales}");
          print("total promotion amount: ${sales.total_promo_amount}");
          await _insertSqliteSalesPerDay(sales);
        }
      }
    });
  }

  Future<SalesPerDay> _insertSqliteSalesPerDay(Order sales) async {
    try{
      var data = SalesPerDay(
        sales_per_day_id: 0,
        branch_id: '3',
        total_amount: sales.total_sales!.toStringAsFixed(2),
        tax: sales.total_tax_amount!.toStringAsFixed(2),
        charge: sales.total_charge_amount!.toStringAsFixed(2),
        promotion: sales.total_promo_amount!.toStringAsFixed(2),
        date: sales.created_at!.substring(0, 10),
        payment_method_sales: '',
        payment_method: '',
        sync_status: 0,
        created_at: _currentDateTime,
        updated_at: '',
        soft_delete: '',
      );
      final id = await _transaction.insert(tableSalesPerDay, data.toJson());
      return data.copy(sales_per_day_sqlite_id: id);
    }catch(e, stackTrace){
      FLog.error(
        className: "settlement query",
        text: "_insertSqliteSalesPerDay error",
        exception: "Error: $e, StackTrace: $stackTrace",
      );
      rethrow;
    }
  }

/*
  get not yet settlement order
*/
  Future<List<Order>> _readSales() async {
    final result = await _transaction.rawQuery(
        'WITH PromoSums AS (SELECT order_sqlite_id, SUM(promotion_amount) AS TotalPromoAmount FROM $tableOrderPromotionDetail GROUP BY order_sqlite_id ), '
            'TaxSums AS (SELECT order_sqlite_id, SUM(CASE WHEN type = ? THEN tax_amount ELSE 0 END) AS TaxType0Amount, '
            'SUM(CASE WHEN type = ? THEN tax_amount ELSE 0 END) AS TaxType1Amount FROM $tableOrderTaxDetail GROUP BY order_sqlite_id )'
        'SELECT o.created_at as created_at, SUM(o.final_amount) AS total_sales, '
            'COALESCE(SUM(P.TotalPromoAmount), 0.0) AS total_promo_amount, '
            'COALESCE(SUM(T.TaxType0Amount), 0.0) AS total_charge_amount, '
            'COALESCE(SUM(T.TaxType1Amount), 0.0) AS total_tax_amount '
            'FROM $tableOrder o '
            'LEFT JOIN PromoSums P ON o.order_sqlite_id = P.order_sqlite_id '
            'LEFT JOIN TaxSums T ON o.order_sqlite_id = T.order_sqlite_id '
            'GROUP BY SUBSTR(o.created_at, 1, 10) ',
        ['0', '1']) as List<Map<String, Object?>>;
    return result.map((json) => Order.fromJson(json)).toList();
  }
}