import 'dart:convert';

import 'package:collection/collection.dart';
import 'package:pos_system/notifier/cart_notifier.dart';
import 'package:pos_system/object/table_use.dart';
import 'package:provider/provider.dart';
import 'package:sqflite/sqflite.dart';

import '../database/pos_database.dart';
import '../main.dart';
import '../notifier/table_notifier.dart';
import '../object/branch_link_product.dart';
import '../object/categories.dart';
import '../object/order.dart';
import '../object/order_cache.dart';
import '../object/order_detail.dart';
import '../object/order_modifier_detail.dart';
import '../object/order_payment_split.dart';
import '../object/table.dart';
import '../object/table_use_detail.dart';
import '../utils/Utils.dart';

class TableFunction {
  final _context = MyApp.navigatorKey.currentContext!;
  PosDatabase _posDatabase = PosDatabase.instance;
  List<PosTable> tableList = [];
  List<PosTable> initialTableList = [];
  List<OrderCache> _orderCacheList = [];
  List<OrderDetail> _orderDetailList = [];

  List<OrderCache> get orderCacheList => _orderCacheList;

  List<OrderDetail> get orderDetailList => _orderDetailList;


  readAllTable() async {
    tableList = await _posDatabase.readAllTable();
    //for compare purpose
    initialTableList = await _posDatabase.readAllTable();

    //table number sorting
    sortTable();

    await readAllTableGroup();
  }

  sortTable(){
    tableList.sort((a, b) {
      final aNumber = a.number!;
      final bNumber = b.number!;

      bool isANumeric = int.tryParse(aNumber) != null;
      bool isBNumeric = int.tryParse(bNumber) != null;

      if (isANumeric && isBNumeric) {
        return int.parse(aNumber).compareTo(int.parse(bNumber));
      } else if (isANumeric) {
        return -1; // Numeric before alphanumeric
      } else if (isBNumeric) {
        return 1; // Alphanumeric before numeric
      } else {
        // Custom alphanumeric sorting logic
        return compareNatural(aNumber, bNumber);
      }
    });
  }

  readAllTableGroup() async {
    double tableAmount = 0.0;
    bool hasTableInUse = tableList.any((item) => item.status == 1);
    if(hasTableInUse){
      if(hasTableInUse){
        for (int i = 0; i < tableList.length; i++) {
          if(tableList[i].status == 1){
            List<TableUseDetail> tableUseDetailData = await PosDatabase.instance.readSpecificInUsedTableUseDetail(tableList[i].table_sqlite_id!);
            if (tableUseDetailData.isNotEmpty) {
              List<OrderCache> data = await PosDatabase.instance.readTableOrderCache(tableUseDetailData[0].table_use_key!);
              if(data.isNotEmpty){
                double tableAmount = 0.0;
                tableList[i].group = data[0].table_use_sqlite_id;
                tableList[i].card_color = data[0].card_color;
                for(int j = 0; j < data.length; j++){
                  tableAmount += double.parse(data[j].total_amount!);
                }
                if(data[0].order_key != ''){
                  double amountPaid = 0;
                  List<OrderPaymentSplit> orderSplit = await PosDatabase.instance.readSpecificOrderSplitByOrderKey(data[0].order_key!);

                  for(int k = 0; k < orderSplit.length; k++){
                    amountPaid += double.parse(orderSplit[k].amount!);
                  }
                  List<Order> orderData = await PosDatabase.instance.readSpecificOrderByOrderKey(data[0].order_key!);
                  tableAmount = double.parse(orderData[0].final_amount!);

                  tableAmount -= amountPaid;
                  tableList[i].order_key = data[0].order_key!;
                }
                tableList[i].total_amount = tableAmount.toStringAsFixed(2);
              }
            }
          }
        }
      }
    }
  }

  Future<void> readSpecificTableDetail(PosTable posTable) async {
    try{
      //Get specific table use detail
      List<TableUseDetail> tableUseDetailData = await _posDatabase.readSpecificTableUseDetail(posTable.table_sqlite_id!);
      if(tableUseDetailData.isNotEmpty){
        //Get all order table cache
        List<OrderCache> data = await _posDatabase.readTableOrderCache(tableUseDetailData[0].table_use_key!);
        Provider.of<CartModel>(_context, listen: false).addAllSubPosOrderCache(data);
        //loop all table order cache
        for (int i = 0; i < data.length; i++) {
          if (!_orderDetailList.contains(data)) {
            _orderCacheList = List.from(data);
          }
          //Get all order detail based on order cache id
          List<OrderDetail> detailData = await _posDatabase.readTableOrderDetail(data[i].order_cache_key!);
          //add all order detail from db
          for(var item in detailData){
            print("detailData: ${jsonEncode(detailData)}");
          }
          if (!_orderDetailList.contains(detailData)) {
            _orderDetailList..addAll(detailData);
          }
        }
        //loop all order detail
        for (int k = 0; k < _orderDetailList.length; k++) {
          //Get data from branch link product
          List<BranchLinkProduct> data = await _posDatabase.readSpecificBranchLinkProduct(_orderDetailList[k].branch_link_product_sqlite_id!);
          _orderDetailList[k].allow_ticket = data[0].allow_ticket;
          _orderDetailList[k].ticket_count = data[0].ticket_count;
          _orderDetailList[k].ticket_exp = data[0].ticket_exp;
          // if(data.isNotEmpty){
          //   _orderDetailList[k].allow_ticket = data[0].allow_ticket;
          //   _orderDetailList[k].ticket_count = data[0].ticket_count;
          //   _orderDetailList[k].ticket_exp = data[0].ticket_exp;
          // }
          //Get product category
          if(_orderDetailList[k].category_sqlite_id! == '0'){
            _orderDetailList[k].product_category_id = '0';
          } else {
            Categories category = await _posDatabase.readSpecificCategoryByLocalId(_orderDetailList[k].category_sqlite_id!);
            _orderDetailList[k].product_category_id = category.category_id.toString();
          }

          //check product modifier
          await _getOrderModifierDetail(_orderDetailList[k]);
        }
      }
    }catch(e){
      rethrow;
    }
  }

  Future<void> _getOrderModifierDetail(OrderDetail orderDetail) async {
    try{
      List<OrderModifierDetail> modDetail = await _posDatabase.readOrderModifierDetail(orderDetail.order_detail_sqlite_id.toString());
      if (modDetail.isNotEmpty) {
        orderDetail.orderModifierDetail = modDetail;
      } else {
        orderDetail.orderModifierDetail = [];
      }
    }catch(e){
      rethrow;
    }
  }

  void clearSubPosOrderCache({String? table_use_key}){
    if(table_use_key != null){
      Provider.of<CartModel>(_context, listen: false).removeSpecificSubPosOrderCache(table_use_key);
    } else {
      Provider.of<CartModel>(_context, listen: false).clearSubPosOrderCache();
    }
  }

  void removeSpecificBatchSubPosOrderCache(String batch){
    Provider.of<CartModel>(_context, listen: false).removeSpecificBatchSubPosOrderCache(batch);
  }

  Future<bool> IsTableSelected(PosTable posTable) async {
    CartModel cartModel =  Provider.of<CartModel>(_context, listen: false);
    bool status1 = await cartModel.isTableSelectedBySubPos(tableUseKey: posTable.table_use_key!);
    bool status2 = await cartModel.isTableSelectedByMainPos(tableUseKey: posTable.table_use_key!);
    bool isTableSelected = false;
    if(posTable.table_use_key != null){
      isTableSelected = status1 || status2;
    }
    return isTableSelected;
  }

  changeTable({required String startTableNum, required String destinationTableNum}) async {
    final _posDatabase = PosDatabase.instance;
    var db = await _posDatabase.database;
    await db.transaction((txn) async {
      String dateTime = Utils.dbCurrentDateTimeFormat();
      var query = ChangeTableQuery(txn);
      var startTable = await query.readPosTable(startTableNum);
      var destinationTable = await query.readPosTable(destinationTableNum);
      if(destinationTable == null){
        throw Exception("Table not existed");
      } else {
        if(destinationTable.status == 0){
          //change to table not in used
          await _changeToUnusedTable(destinationTable, startTable!, query, dateTime);
        } else {
          //change to table in used
          await _changeToTableInUsed(destinationTable, startTable!, query, dateTime);
        }
        await _updateTableStatus(startTable, destinationTable, query, dateTime);
      }
      TableModel.instance.changeContent(true);
    });
  }

  _changeToTableInUsed(PosTable destinationTable, PosTable startTable, ChangeTableQuery query, String dateTime) async {
    await _updateOrderCacheTableUseSqliteIdAndKey(destinationTable, startTable, query, dateTime);
    await _softDeleteTableUseKey(query, startTable, dateTime);
    await _softDeleteMergedTableUseDetail(query, startTable, dateTime, deleteAll: true);
  }

  _changeToUnusedTable(PosTable destinationTable, PosTable startTable, ChangeTableQuery query, String dateTime) async {
    await _softDeleteMergedTableUseDetail(query, startTable, dateTime);
    await _updateTableUseDetail(destinationTable, startTable, query, dateTime);
  }

  _softDeleteTableUseKey(ChangeTableQuery query, PosTable startTable, String dateTime) async {
    var tableUse = await query.readSpecificTableUseByKey(startTable.table_use_key!);
    var data = tableUse!.copy(
      status: 1,
      sync_status: tableUse.sync_status == 0 ? 0 : 2,
      soft_delete: dateTime
    );
    await query.deleteTableUse(data);
  }

  _updateOrderCacheTableUseSqliteIdAndKey(PosTable destinationTable, PosTable startTable, ChangeTableQuery query, String dateTime) async {
    print("start table use key: ${startTable.table_use_key}");
    var orderCacheList = await query.readAllOrderCacheByTableUseKey(startTable.table_use_key!);
    print("order cache list length: ${orderCacheList.length}");
    for(var orderCache in orderCacheList) {
      TableUse? destinationTableUse = await query.readSpecificTableUseByKey(destinationTable.table_use_key!);
      var data = orderCache.copy(
        table_use_sqlite_id: destinationTableUse!.table_use_sqlite_id!.toString(),
        table_use_key: destinationTable.table_use_key,
        sync_status: orderCache.sync_status == 0 ? 0 : 2,
        updated_at: dateTime
      );
      await query.updateOrderCacheTableUseSqliteAndKey(data);
    }
  }

  _updateTableUseDetail(PosTable destinationTable, PosTable startTable, ChangeTableQuery query, String dateTime) async {
    TableUseDetail? data = await query.readSpecificTableUseDetail(startTable.table_use_detail_key!);
    TableUseDetail tableUseDetailObject = data!.copy(
      table_sqlite_id: destinationTable.table_sqlite_id!.toString(),
      table_id: destinationTable.table_id!.toString(),
      sync_status: data.sync_status == 0 ? 0 : 2,
      updated_at: dateTime,
    );
    await query.updateTableUseDetail(tableUseDetailObject);
  }

  Future<void> _softDeleteMergedTableUseDetail(ChangeTableQuery query, PosTable startTable, String dateTime, {bool? deleteAll = false}) async {
    List<TableUseDetail> tableUseDetailList = await query.readAllTableUseDetailByTableUseKey(startTable);
    if(tableUseDetailList.isNotEmpty){
      if(deleteAll == false){
        tableUseDetailList.removeWhere((e) => e.table_sqlite_id.toString() == startTable.table_sqlite_id.toString());
      }
      for(var tableUseDetail in tableUseDetailList) {
        var updateData = tableUseDetail.copy(
            soft_delete: dateTime,
            sync_status: tableUseDetail.sync_status == 0 ?  0 : 2,
            status: 1,
        );
        await query.deleteTableUseDetailByKey(updateData);
      }
    }
  }

  _updateTableStatus(PosTable startTable, PosTable destinationTable, ChangeTableQuery query, String dateTime) async {
    List<PosTable> startPosTableList = await query.readAllPosTableByTableUseKey(startTable.table_use_key!);
    for(var posTable in startPosTableList){
      var data = posTable.copy(
        updated_at: dateTime,
        table_use_key: '',
        table_use_detail_key: '',
        status: 0,
        sync_status: posTable.sync_status == 0 ? 0 : 2
      );
      await query.updatePosTableStatus(data);
    }
    //update destination pos table status
    var data = destinationTable.copy(
        updated_at: dateTime,
        table_use_key: destinationTable.status == 0 ? startTable.table_use_key : destinationTable.table_use_key,
        table_use_detail_key: destinationTable.status == 0 ? startTable.table_use_detail_key : destinationTable.table_use_detail_key,
        status: 1,
        sync_status: destinationTable.sync_status == 0 ? 0 : 2
    );
    await query.updatePosTableStatus(data);
  }
}

class ChangeTableQuery {
  Transaction _transaction;

  ChangeTableQuery(this._transaction);

  Future<int> deleteTableUse(TableUse data) async {
    return await _transaction.rawUpdate('UPDATE $tableTableUse SET soft_delete = ?, sync_status = ?, status = ? WHERE table_use_sqlite_id = ?',
        [data.soft_delete, data.sync_status, data.status, data.table_use_sqlite_id]);
  }

  Future<int> deleteTableUseDetailByKey(TableUseDetail data) async {
    return await _transaction.rawUpdate('UPDATE $tableTableUseDetail SET soft_delete = ?, sync_status = ?, status = ? WHERE table_use_detail_key = ?',
        [data.soft_delete, data.sync_status, data.status, data.table_use_detail_key]);
  }

  Future<int> updateOrderCacheTableUseSqliteAndKey(OrderCache data) async {
    try{
      return await _transaction.rawUpdate('UPDATE $tableOrderCache '
          'SET table_use_sqlite_id = ?, table_use_key = ?, sync_status = ?, updated_at = ? WHERE order_cache_sqlite_id = ?',
          [data.table_use_sqlite_id, data.table_use_key, data.sync_status, data.updated_at, data.order_cache_sqlite_id]);
    }catch(e, s){
      rethrow;
    }
  }

  Future<int> updatePosTableStatus(PosTable data) async {
    try{
      return await _transaction.rawUpdate('UPDATE $tablePosTable '
          'SET status = ?, table_use_key = ?, table_use_detail_key = ?, sync_status = ?, updated_at = ? WHERE table_sqlite_id = ?',
          [data.status, data.table_use_key, data.table_use_detail_key, data.sync_status, data.updated_at, data.table_sqlite_id]);
    }catch(e, s){
      rethrow;
    }
  }

  Future<int> updateTableUseDetail(TableUseDetail data) async {
    try{
      return await _transaction.rawUpdate('UPDATE $tableTableUseDetail '
          'SET table_sqlite_id = ?, table_id = ?, sync_status = ?, updated_at = ? WHERE table_use_detail_key = ?',
          [data.table_sqlite_id, data.table_id, data.sync_status, data.updated_at, data.table_use_detail_key]);
    }catch(e, s){
      rethrow;
    }
  }

  Future<List<OrderCache>> readAllOrderCacheByTableUseKey(String tableUseKey) async {
    try{
      var result = await _transaction.rawQuery("SELECT * FROM $tableOrderCache WHERE table_use_key = ? AND soft_delete = ?",
          [tableUseKey, '']);
      return result.isNotEmpty ? result.map((json) => OrderCache.fromJson(json)).toList() : [];
    }catch(e, s){
      // FLog.error(
      //   className: "settlement query",
      //   text: "_readSales error",
      //   exception: 'Error: $e, Stacktrace: $s',
      // );
      rethrow;
    }
  }

  Future<List<PosTable>> readAllPosTableByTableUseKey(String tableUseKey) async {
    try{
      var result = await _transaction.rawQuery("SELECT * FROM $tablePosTable WHERE table_use_key = ? AND soft_delete = ?",
          [tableUseKey, '']);
      return result.isNotEmpty ? result.map((json) => PosTable.fromJson(json)).toList() : [];
    }catch(e, s){
      // FLog.error(
      //   className: "settlement query",
      //   text: "_readSales error",
      //   exception: 'Error: $e, Stacktrace: $s',
      // );
      rethrow;
    }
  }


  Future<List<TableUseDetail>> readAllTableUseDetailByTableUseKey(PosTable posTable) async {
    try{
      var result = await _transaction.rawQuery("SELECT * FROM $tableTableUseDetail WHERE table_use_key = ? AND soft_delete = ? ",
          [posTable.table_use_key, '']);
      return result.isNotEmpty ? result.map((json) => TableUseDetail.fromJson(json)).toList() : [];
    }catch(e, s){
      // FLog.error(
      //   className: "settlement query",
      //   text: "_readSales error",
      //   exception: 'Error: $e, Stacktrace: $s',
      // );
      rethrow;
    }
  }

  Future<TableUse?> readSpecificTableUseByKey(String key) async {
    try{
      var result = await _transaction.rawQuery("SELECT * FROM $tableTableUse WHERE table_use_key = ? AND soft_delete = ? ",
          [key, '']);
      return result.isNotEmpty ? TableUse.fromJson(result.first) : null;
    }catch(e, s){
      // FLog.error(
      //   className: "settlement query",
      //   text: "_readSales error",
      //   exception: 'Error: $e, Stacktrace: $s',
      // );
      rethrow;
    }
  }

  Future<TableUseDetail?> readSpecificTableUseDetail(String key) async {
    try{
      var result = await _transaction.rawQuery("SELECT * FROM $tableTableUseDetail "
          "WHERE table_use_detail_key = ? AND soft_delete = ? ",
          [key, '']);
      return result.isNotEmpty ? TableUseDetail.fromJson(result.first) : null;
    }catch(e, s){
      // FLog.error(
      //   className: "settlement query",
      //   text: "_readSales error",
      //   exception: 'Error: $e, Stacktrace: $s',
      // );
      rethrow;
    }
  }

  Future<PosTable?> readPosTable(String tableNumber) async {
    try{
      var result = await _transaction.rawQuery("SELECT * FROM $tablePosTable WHERE number = ? AND soft_delete = ?", [tableNumber, '']);
      return result.isNotEmpty ?  PosTable.fromJson(result.first) : null;
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