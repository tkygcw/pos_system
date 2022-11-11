import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:pos_system/database/pos_database.dart';
import 'package:pos_system/object/categories.dart';
import 'package:pos_system/object/tax.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../database/domain.dart';

class TestCategorySync extends StatefulWidget {
  const TestCategorySync({Key? key}) : super(key: key);

  @override
  State<TestCategorySync> createState() => _TestCategorySyncState();
}

class _TestCategorySyncState extends State<TestCategorySync> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        alignment: Alignment.center,
        child: ElevatedButton(
            onPressed: ()async  => readBranchPref(),
            child: Text('test branch object pref')),
      ),
    );
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
