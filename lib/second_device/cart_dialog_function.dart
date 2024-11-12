import 'dart:convert';

import 'package:collection/collection.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:crypto/crypto.dart';

import '../database/pos_database.dart';
import '../object/branch_link_product.dart';
import '../object/categories.dart';
import '../object/order_cache.dart';
import '../object/order_detail.dart';
import '../object/order_modifier_detail.dart';
import '../object/table.dart';
import '../object/table_use_detail.dart';

class SubPosCartDialogFunction {
  List<PosTable> tableList = [];
  List<OrderCache> orderCacheList = [];
  List<OrderDetail> orderDetailList = [];
  String? tableUseDetailKey, tableUseKey;


  readAllTable() async {
    tableList = await PosDatabase.instance.readAllTable();
    sortTable();
    await readAllTableAmount();
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

  readAllTableAmount() async {
    double tableAmount = 0.0;
    for (int i = 0; i < tableList.length; i++) {
      if(tableList[i].status == 1){
        List<TableUseDetail> tableUseDetailData = await PosDatabase.instance.readSpecificTableUseDetail(tableList[i].table_sqlite_id!);

        if (tableUseDetailData.isNotEmpty) {
          List<OrderCache> data = await PosDatabase.instance.readTableOrderCache(tableUseDetailData[0].table_use_key!);
          tableList[i].group = data[0].table_use_sqlite_id;
          tableList[i].card_color = data[0].card_color;
          for (int j = 0; j < data.length; j++) {
            tableAmount += double.parse(data[j].total_amount!);
          }
          tableList[i].total_amount = tableAmount.toStringAsFixed(2);
        }
      }
    }
  }

  readSpecificTableDetail(PosTable posTable) async {
    //Get specific table use detail
    List<TableUseDetail> tableUseDetailData = await PosDatabase.instance.readSpecificTableUseDetail(posTable.table_sqlite_id!);

    //Get all order table cache
    List<OrderCache> data = await PosDatabase.instance.readTableOrderCache(tableUseDetailData[0].table_use_key!);
    //loop all table order cache
    for (int i = 0; i < data.length; i++) {
      if (!orderCacheList.contains(data)) {
        orderCacheList = List.from(data);
      }
      //Get all order detail based on order cache id
      List<OrderDetail> detailData = await PosDatabase.instance.readTableOrderDetail(data[i].order_cache_key!);
      //add all order detail from db
      if (!orderDetailList.contains(detailData)) {
        orderDetailList..addAll(detailData);
      }
    }
    //loop all order detail
    for (int k = 0; k < orderDetailList.length; k++) {
      //Get data from branch link product
      List<BranchLinkProduct> data = await PosDatabase.instance.readSpecificBranchLinkProduct(orderDetailList[k].branch_link_product_sqlite_id!);
      orderDetailList[k].allow_ticket = data[0].allow_ticket;
      orderDetailList[k].ticket_count = data[0].ticket_count;
      orderDetailList[k].ticket_exp = data[0].ticket_exp;
      //Get product category
      if(orderDetailList[k].category_sqlite_id! == '0'){
        orderDetailList[k].product_category_id = '0';
      } else {
        Categories category = await PosDatabase.instance.readSpecificCategoryByLocalId(orderDetailList[k].category_sqlite_id!);
        orderDetailList[k].product_category_id = category.category_id.toString();
      }

      //check product modifier
      await getOrderModifierDetail(orderDetailList[k]);
    }
  }

  Future<void> getOrderModifierDetail(OrderDetail orderDetail) async {
    List<OrderModifierDetail> modDetail = await PosDatabase.instance.readOrderModifierDetail(orderDetail.order_detail_sqlite_id.toString());
    if (modDetail.isNotEmpty) {
      orderDetail.orderModifierDetail = modDetail;
    } else {
      orderDetail.orderModifierDetail = [];
    }
  }

  callRemoveTableQuery(int table_sqlite_id) async {
    DateFormat dateFormat = DateFormat("yyyy-MM-dd HH:mm:ss");
    String dateTime = dateFormat.format(DateTime.now());
    if(await checkTableStatus(table_sqlite_id) == true){
      await deleteCurrentTableUseDetail(table_sqlite_id, dateTime);
      await updatePosTableStatus(table_sqlite_id, 0, '', '', dateTime);
      //await readAllTable(isReset: true);
    } else {
      return;
    }
  }

  Future<bool> checkTableStatus(int table_sqlite_id) async {
    bool tableInUse = false;
    List<PosTable> table = await PosDatabase.instance.checkPosTableStatus(table_sqlite_id);
    if(table[0].status == 1) {
      tableInUse = true;
    }
    // for(int i = 0; i < cart.selectedTable.length; i++){
    //   List<PosTable> table = await PosDatabase.instance.checkPosTableStatus(cart.selectedTable[i].table_sqlite_id!);
    //   if(table[0].status == 1){
    //     tableInUse = true;
    //     break;
    //   }
    // }
    return tableInUse;
  }

  deleteCurrentTableUseDetail(int currentTableId, String dateTime) async {
    print('current delete table local id: ${currentTableId}');
    try {
      List<TableUseDetail> checkData = await PosDatabase.instance.readSpecificTableUseDetail(currentTableId);
      print('check data length: ${checkData.length}');
      TableUseDetail tableUseDetailObject = TableUseDetail(
          soft_delete: dateTime,
          sync_status: checkData[0].sync_status == 0 ? 0 : 2,
          status: 1,
          table_sqlite_id: currentTableId.toString(),
          table_use_detail_key: checkData[0].table_use_detail_key,
          table_use_detail_sqlite_id: checkData[0].table_use_detail_sqlite_id);
      int updatedData = await PosDatabase.instance.deleteTableUseDetailByKey(tableUseDetailObject);
    } catch (e) {
      print("delete table use detail error: $e");
    }
  }

  updatePosTableStatus(int dragTableId, int status, String tableUseDetailKey, String tableUseKey, String dateTime) async {
    //get target table use key here
    PosTable posTableData = PosTable(
        table_use_detail_key: tableUseDetailKey,
        table_use_key: tableUseKey,
        table_sqlite_id: dragTableId,
        status: status,
        updated_at: dateTime);
    int updatedTable = await PosDatabase.instance.updatePosTableStatus(posTableData);
    int updatedKey = await PosDatabase.instance.removePosTableTableUseDetailKey(posTableData);
  }

  Future<int> callMergeTableQuery({required int dragTableId, required int targetTableId}) async {
    DateFormat dateFormat = DateFormat("yyyy-MM-dd HH:mm:ss");
    String dateTime = dateFormat.format(DateTime.now());
    if(await checkTableStatus(dragTableId) == false && await checkTableStatus(targetTableId) == true){
      await createTableUseDetail(dragTableId, targetTableId);
      await updatePosTableStatus(dragTableId, 1, this.tableUseDetailKey!, tableUseKey!, dateTime);
      return 1;
    } else {
      return 2;
    }
  }

  createTableUseDetail(int newTableId, int oldTableId) async {
    DateFormat dateFormat = DateFormat("yyyy-MM-dd HH:mm:ss");
    String dateTime = dateFormat.format(DateTime.now());
    try {
      //read table use detail data based on target table id
      List<TableUseDetail> tableUseDetailData = await PosDatabase.instance.readSpecificTableUseDetail(oldTableId);
      List<PosTable> tableData = await PosDatabase.instance.readSpecificTable(newTableId.toString());

      //create table use detail
      TableUseDetail insertData = await PosDatabase.instance.insertSqliteTableUseDetail(TableUseDetail(
          table_use_detail_id: 0,
          table_use_detail_key: '',
          table_use_sqlite_id: tableUseDetailData[0].table_use_sqlite_id,
          table_use_key: tableUseDetailData[0].table_use_key,
          table_sqlite_id: newTableId.toString(),
          table_id: tableData[0].table_id.toString(),
          created_at: dateTime,
          status: 0,
          sync_status: 0,
          updated_at: '',
          soft_delete: ''));
      this.tableUseKey = insertData.table_use_key;
      await insertTableUseDetailKey(insertData, dateTime);
    } catch (e) {
      print('create table use detail error: $e');
    }
  }

  Future<void> insertTableUseDetailKey(TableUseDetail tableUseDetail, String dateTime) async {
    tableUseDetailKey = await generateTableUseDetailKey(tableUseDetail);
    if (tableUseDetailKey != null) {
      TableUseDetail tableUseDetailObject = TableUseDetail(
          table_use_detail_key: tableUseDetailKey,
          sync_status: 0,
          updated_at: dateTime,
          table_use_detail_sqlite_id: tableUseDetail.table_use_detail_sqlite_id);
      int data = await PosDatabase.instance.updateTableUseDetailUniqueKey(tableUseDetailObject);
    }
  }

  generateTableUseDetailKey(TableUseDetail tableUseDetail) async {
    final prefs = await SharedPreferences.getInstance();
    final int? device_id = prefs.getInt('device_id');
    var bytes = tableUseDetail.created_at!.replaceAll(new RegExp(r'[^0-9]'), '') +
        tableUseDetail.table_use_detail_sqlite_id.toString() +
        device_id.toString();
    return md5.convert(utf8.encode(bytes)).toString();
  }

}