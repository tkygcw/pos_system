import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:pos_system/database/pos_database.dart';
import 'package:pos_system/object/categories.dart';
import 'package:pos_system/object/order_detail.dart';
import 'package:pos_system/object/table_use.dart';
import 'package:pos_system/object/table_use_detail.dart';
import 'package:pos_system/object/tax.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../database/domain.dart';

import '../../object/order.dart';
import '../../object/order_cache.dart';


class TestCategorySync extends StatefulWidget {
  const TestCategorySync({Key? key}) : super(key: key);

  @override
  State<TestCategorySync> createState() => _TestCategorySyncState();
}

class _TestCategorySyncState extends State<TestCategorySync> {
  List<Order> notSyncOrderList = [];
  List<OrderCache> notSyncOrderCacheList = [];
  List<OrderDetail> notSyncOrderDetailList = [];
  List<TableUse> notSyncTableUseList = [];
  List<TableUseDetail> notSyncTableUseDetailList = [];
  Timer? timer;


  @override
  void initState() {
    super.initState();
    //timer = Timer.periodic(Duration(seconds: 15), (Timer t) => SyncToCloud());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        alignment: Alignment.center,
        child: ElevatedButton(
            onPressed: () async  => await updatedTableUseDetailSyncToCloud(),//tableUseSyncToCloud(),
            child: Text('current screen height/width: ${MediaQuery.of(context).size.height}, ${MediaQuery.of(context).size.width}')),
      ),
    );
  }

/*
  test sync query  (tb_order)
*/
  updatedTableUseDetailSyncToCloud() async {
    List<String> value = [];
    await getNotSyncUpdatedTableUseDetail();
    print('${notSyncTableUseDetailList.length} table use detail call to sync api');
    for(int i = 0; i < notSyncTableUseDetailList.length; i++){
      value.add(jsonEncode(notSyncTableUseDetailList[i].syncJson()));
    }
    print('Value: ${value.toString()}');
    Map data = await Domain().SyncUpdatedTableUseDetailToCloud(value.toString());
    List responseJson = data['data'];
    for (var i = 0; i < responseJson.length; i++) {
      int tablaUseDetailData = await PosDatabase.instance.updateTableUseDetailSyncStatusFromCloud(responseJson[i]['table_use_detail_key']);
    }
  }

  tableUseDetailSyncToCloud() async {
    List<String> value = [];
    await getNotSyncTableUseDetail();
    print('${notSyncTableUseDetailList.length} table use call to sync api');
    for(int i = 0; i <  notSyncTableUseDetailList.length; i++){
      value.add(jsonEncode(notSyncTableUseDetailList[i].syncJson()));
    }
    print('Value: ${value.toString()}');
    Map data = await Domain().SyncTableUseDetailToCloud(value.toString());
    List responseJson = data['data'];
    for (var i = 0; i < responseJson.length; i++) {
      int tablaUseDetailData = await PosDatabase.instance.updateTableUseDetailSyncStatusFromCloud(responseJson[i]['table_use_detail_key']);
    }
  }

  updatedTableUseSyncToCloud() async {
    List<String> value = [];
    await getNotSyncUpdatedTableUse();
    print('${notSyncTableUseList.length} table use call to sync api');
    for(int i = 0; i <  notSyncTableUseList.length; i++){
      value.add(jsonEncode(notSyncTableUseList[i]));
    }
    print('Value: ${value.toString()}');
    Map data = await Domain().SyncUpdatedTableUseToCloud(value.toString());
    if (data['status'] == '1') {
      List responseJson = data['data'];
      for (var i = 0; i < responseJson.length; i++) {
        int tablaUseData = await PosDatabase.instance.updateTableUseSyncStatusFromCloud(responseJson[i]['table_use_key']);
      }
    }
  }

  tableUseSyncToCloud() async {
    List<String> value = [];
    await getNotSyncTableUse();
    print('${notSyncTableUseList.length} table use call to sync api');
    for(int i = 0; i <  notSyncTableUseList.length; i++){
      value.add(jsonEncode(notSyncTableUseList[i]));
    }
    print('Value: ${value.toString()}');
    Map data = await Domain().SyncTableUseToCloud(value.toString());
    if (data['status'] == '1') {
      List responseJson = data['data'];
      for (var i = 0; i < responseJson.length; i++) {
        int tablaUseData = await PosDatabase.instance.updateTableUseSyncStatusFromCloud(responseJson[i]['table_use_key']);
      }
    }
  }

  updatedOrderDetailSyncToCloud() async {
    List<String> jsonValue = [];
    await getNotSyncUpdatedOrderDetail();
    for(int i = 0; i < notSyncOrderDetailList.length; i++){
      jsonValue.add(jsonEncode(notSyncOrderDetailList[i].syncJson()));
    }
    print('Value: ${jsonValue.toString()}');

    Map data = await Domain().SyncUpdatedOrderDetailToCloud(jsonValue.toString());
    if (data['status'] == '1') {
      List responseJson = data['data'];
      for (var i = 0; i < responseJson.length; i++) {
        int orderDetailData = await PosDatabase.instance.updateOrderDetailSyncStatusFromCloud(responseJson[i]['order_detail_key']);
      }
    }
  }


  orderDetailSyncToCloud() async {
    List<String> jsonValue = [];
    await getNotSyncOrderDetail();
    print('${notSyncOrderDetailList.length} order detail call to sync api');
    for(int i = 0; i <  notSyncOrderDetailList.length; i++){
      print('test: ${notSyncOrderDetailList[i].branch_link_product_id}');
      jsonValue.add(jsonEncode(notSyncOrderDetailList[i].syncJson()));
    }
    print('Value: ${jsonValue.toString()}');

    Map data = await Domain().SyncOrderDetailToCloud(jsonValue.toString());
    if (data['status'] == '1') {
      List responseJson = data['data'];
      for (var i = 0; i < responseJson.length; i++) {
        int orderDetailData = await PosDatabase.instance.updateOrderDetailSyncStatusFromCloud(responseJson[i]['order_detail_key']);
      }
    }
  }

  updatedOrderCacheSyncToCloud() async {
    List<String> value = [];
    await getNotSyncUpdatedOrderCache();
    for(int i = 0; i <  notSyncOrderCacheList.length; i++){
      value.add(jsonEncode(notSyncOrderCacheList[i]));
    }
    print('Value: ${value.toString()}');
    Map data = await Domain().SyncUpdatedOrderCacheToCloud(value.toString());
    List responseJson = data['data'];
    for(int i = 0 ; i <responseJson.length; i++){
      int orderCacheData = await PosDatabase.instance.updateOrderCacheSyncStatusFromCloud(responseJson[i]['order_cache_key']);
    }
  }

  orderCacheSyncToCloud() async {
    List<String> value = [];
    await getNotSyncOrderCache();
    for(int i = 0; i <  notSyncOrderCacheList.length; i++){
      value.add(jsonEncode(notSyncOrderCacheList[i]));
    }

    Map data = await Domain().SyncOrderCacheToCloud(value.toString());
    if(data['status'] == '1'){
      List responseJson = data['data'];
      for(int i = 0 ; i <responseJson.length; i++){
        int orderCacheData = await PosDatabase.instance.updateOrderCacheSyncStatusFromCloud(responseJson[i]['order_cache_key']);
      }
    }
  }

  updatedOrderSyncToCloud() async {
    List<String> value = [];
    await getNotSyncUpdatedOrder();
    for(int i = 0; i < notSyncOrderList.length; i++){
      value.add(jsonEncode(notSyncOrderList[i]));
    }
    print('Value: ${value.toString()}');
    // Map data = await Domain().SyncOrderToCloud(value.toString());
    // print('response: ${data}');
    // if (data['status'] == '1') {
    //   List responseJson = data['data'];
    //   for (var i = 0; i < responseJson.length; i++) {
    //     //print('response order key: ${responseJson[i]['order_key']}');
    //     int orderData = await PosDatabase.instance.updateOrderSyncStatusFromCloud(responseJson[i]['order_key']);
    //   }
    // }
  }

  orderSyncToCloud() async {
    List<String> value = [];
    await getNotSyncOrder();
    print('${notSyncOrderList.length} orders call to sync api');
    for(int i = 0; i <  notSyncOrderList.length; i++){
      value.add(jsonEncode(notSyncOrderList[i]));
    }
    print('Value: ${value}');
    Map data = await Domain().SyncOrderToCloud(value.toString());
    print('response: ${data}');
    if (data['status'] == '1') {
      List responseJson = data['data'];
      for (var i = 0; i < responseJson.length; i++) {
        //print('response order key: ${responseJson[i]['order_key']}');
        int orderData = await PosDatabase.instance.updateOrderSyncStatusFromCloud(responseJson[i]['order_key']);
      }
    }
  }

  getNotSyncUpdatedTableUseDetail()async{
    List<TableUseDetail> data = await PosDatabase.instance.readAllNotSyncUpdatedTableUseDetail();
    notSyncTableUseDetailList = data;
  }

  getNotSyncTableUseDetail()async{
    List<TableUseDetail> data = await PosDatabase.instance.readAllNotSyncTableUseDetail();
    notSyncTableUseDetailList = data;
  }

/*
  ----------------------Table use part---------------------------------------------------------------------------------------------------------------------------------------
*/
  getNotSyncUpdatedTableUse() async {
    List<TableUse> data = await PosDatabase.instance.readAllNotSyncUpdatedTableUse();
    notSyncTableUseList = data;
  }

  getNotSyncTableUse() async {
    List<TableUse> data = await PosDatabase.instance.readAllNotSyncTableUse();
    notSyncTableUseList = data;
  }
/*
  ----------------------Order detail part---------------------------------------------------------------------------------------------------------------------------------------
*/

  getNotSyncUpdatedOrderDetail() async {
    List<OrderDetail> data = await PosDatabase.instance.readAllNotSyncUpdatedOrderDetail();
    notSyncOrderDetailList = data;
  }

  getNotSyncOrderDetail() async {
    List<OrderDetail> data = await PosDatabase.instance.readAllNotSyncOrderDetail();
    notSyncOrderDetailList = data;
  }
/*
  ----------------------Order cache part---------------------------------------------------------------------------------------------------------------------------------------
*/
  getNotSyncUpdatedOrderCache() async {
    List<OrderCache> data = await PosDatabase.instance.readAllNotSyncUpdatedOrderCache();
    notSyncOrderCacheList = data;
  }

  getNotSyncOrderCache() async {
    List<OrderCache> data = await PosDatabase.instance.readAllNotSyncOrderCache();
    notSyncOrderCacheList = data;
  }

/*
  ----------------------Order part---------------------------------------------------------------------------------------------------------------------------------------
*/
  getNotSyncUpdatedOrder() async {
    List<Order> data = await PosDatabase.instance.readAllNotSyncUpdatedOrder();
    notSyncOrderList = data;
  }

  getNotSyncOrder() async {
    List<Order> data = await PosDatabase.instance.readAllNotSyncOrder();
    notSyncOrderList = data;
  }

/*
  test order number generator
*/
  generateOrderNumber(){
    int orderNum = 0;
    String dbNum = '0012';
    orderNum = int.parse(dbNum) + 1;
    print('order number: ${orderNum}');
    return orderNum;
  }
  
/*
  test branch pref  
*/
  readBranchPref() async {
    final prefs = await SharedPreferences.getInstance();
    final String? branch = prefs.getString('branch');
    Map branchObject = json.decode(branch!);
    print('branch name: ${branchObject['name']}');
    print('ipay merchant key: ${branchObject['ipay_merchant_key']}');
  }

/*
  test linked tax
*/
  readLinkedTax() async {
    List<Tax> taxList = [];
    List<String> taxName = [];
    String taxRate = '';
    final prefs = await SharedPreferences.getInstance();
    final int? branch_id = prefs.getInt('branch_id');

    List<Tax> data = await PosDatabase.instance.readTax(branch_id.toString(), '3');
    if(data.length > 0){
      taxList = List.from(data);
      for(int i = 0; i < taxList.length; i++){
        taxName.add(taxList[i].name!);
      }
    }
    return taxName;
  }

/*
  save dining option to database
*/
  checkAllSyncRecord() async {
    final prefs = await SharedPreferences.getInstance();
    final String? user = prefs.getString('user');
    Map userObject = json.decode(user!);
    Map data = await Domain().getAllSyncRecord('5');
    if (data['status'] == '1') {
      List responseJson = data['data'];

      for (var i = 0; i < responseJson.length; i++) {
        if(responseJson[i]['type'] == '1'){
          await callCategoryQuery(responseJson[i]['data'], responseJson[i]['method']);
        }
        // DiningOption data = await PosDatabase.instance
        //     .insertDiningOption(DiningOption.fromJson(responseJson[i]));
      }
    }
  }

  callCategoryQuery(data, method) async {
    print('query call: ${data[0]}');
    final category = Categories.fromJson(data[0]);

    if(method == '0'){
      Categories categoryData = await PosDatabase.instance.insertCategories(Categories.fromJson(data[0]));
    } else {
      int categoryData = await PosDatabase.instance.updateCategoryFromCloud(Categories.fromJson(data[0]));
    }
  }
}
