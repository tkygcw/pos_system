import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:pos_system/database/pos_database.dart';
import 'package:pos_system/object/categories.dart';
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
            onPressed: () async   => await orderCacheSyncToCloud(),
            child: Text('current screen height/width: ${MediaQuery.of(context).size.height}, ${MediaQuery.of(context).size.width}')),
      ),
    );
  }

/*
  test sync query  (tb_order)
*/
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


  orderSyncToCloud() async {
    List<String> value = [];
    await getNotSyncOrder();
    print('${notSyncOrderList.length} orders call to sync api');
    for(int i = 0; i <  notSyncOrderList.length; i++){
      value.add(jsonEncode(notSyncOrderList[i]));
    }
    print('Value: ${value}');
    Map data = await Domain().getAllSyncToCloudRecord(value.toString());
    print('response: ${data}');
    if (data['status'] == '1') {
      List responseJson = data['data'];
      for (var i = 0; i < responseJson.length; i++) {
        //print('response order key: ${responseJson[i]['order_key']}');
        int orderData = await PosDatabase.instance.updateOrderSyncStatusFromCloud(responseJson[i]['order_key']);
      }
    }
  }

  getNotSyncOrderCache() async {
    List<OrderCache> data = await PosDatabase.instance.readAllNotSyncOrderCache();
    notSyncOrderCacheList = data;
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
