import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:page_transition/page_transition.dart';
import 'package:pos_system/database/pos_database.dart';
import 'package:pos_system/fragment/report/print_report_page.dart';
import 'package:pos_system/fragment/test_dual_screen/test_display.dart';
import 'package:pos_system/object/branch_link_dining_option.dart';
import 'package:pos_system/object/branch_link_product.dart';
import 'package:pos_system/object/branch_link_tax.dart';
import 'package:pos_system/object/branch_link_user.dart';
import 'package:pos_system/object/cash_record.dart';
import 'package:pos_system/object/categories.dart';
import 'package:pos_system/object/customer.dart';
import 'package:pos_system/object/dining_option.dart';
import 'package:pos_system/object/order_detail.dart';
import 'package:pos_system/object/order_modifier_detail.dart';
import 'package:pos_system/object/order_promotion_detail.dart';
import 'package:pos_system/object/order_tax_detail.dart';
import 'package:pos_system/object/payment_link_company.dart';
import 'package:pos_system/object/pdf_format.dart';
import 'package:pos_system/object/table.dart';
import 'package:pos_system/object/table_use.dart';
import 'package:pos_system/object/table_use_detail.dart';
import 'package:pos_system/object/tax.dart';
import 'package:pos_system/object/tax_link_dining.dart';
import 'package:pos_system/page/progress_bar.dart';
import 'package:presentation_displays/display.dart';
import 'package:presentation_displays/displays_manager.dart';
import 'package:printing/printing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../database/domain.dart';

import '../../object/branch_link_modifier.dart';
import '../../object/modifier_group.dart';
import '../../object/modifier_item.dart';
import '../../object/modifier_link_product.dart';
import '../../object/order.dart';
import '../../object/order_cache.dart';
import '../../object/product.dart';
import '../../object/product_variant.dart';
import '../../object/product_variant_detail.dart';
import '../../object/user.dart';
import '../../object/variant_group.dart';
import '../../object/variant_item.dart';


class TestCategorySync extends StatefulWidget {
  const TestCategorySync({Key? key}) : super(key: key);

  @override
  State<TestCategorySync> createState() => _TestCategorySyncState();
}

class _TestCategorySyncState extends State<TestCategorySync> {
  List<PosTable> notSyncPosTableList = [];
  List<Order> notSyncOrderList = [];
  List<OrderTaxDetail> notSyncOrderTaxDetailList = [];
  List<OrderPromotionDetail> notSyncOrderPromotionDetailList = [];
  List<OrderCache> notSyncOrderCacheList = [];
  List<OrderDetail> notSyncOrderDetailList = [];
  List<OrderModifierDetail> notSyncOrderModifierDetailList = [];
  List<TableUse> notSyncTableUseList = [];
  List<TableUseDetail> notSyncTableUseDetailList = [];
  List<CashRecord> notSyncCashRecordList = [];
  Timer? timer;
  DisplayManager displayManager = DisplayManager();
  List<Display?> displays = [];
  bool isLoaded = false;


  @override
  void initState() {
    super.initState();
    getDisplay();

    // timer = Timer.periodic(Duration(seconds: 15), (Timer t) {
    //   updatedPosTableSyncToCloud();
    //   updatedOrderPromotionDetailSyncToCloud();
    // });
  }

  getDisplay() async {
    final values = await displayManager.getDisplays();
    displays.clear();
    setState(() {
      displays.addAll(values!);
      isLoaded = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: isLoaded ?
      Container(
        alignment: Alignment.center,
        child: Column(
          children: [
            ElevatedButton(
                onPressed: () async  => await checkAllSyncRecord(),  //await displayManager.showSecondaryDisplay(displayId: 1, routerName: "presentation"),
                child: Text('current screen height/width: ${MediaQuery.of(context).size.height}, ${MediaQuery.of(context).size.width}')),
            ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    PageTransition(
                      type: PageTransitionType.bottomToTop,
                      child: PrintReportPage(),
                    ),
                  );
                },
                child: Text('pdf generate'))
          ],
        ),
      ) : CustomProgressBar(),
    );
  }

/*
  test pdf
*/
  // getPdf() {
  //   String title = 'Overview report';
  //   PdfFormat().redirectToPdfPreviewPage();
  // }

/*
  test get qr order
*/
  getQrOrder() async {
    String categoryLocalId;
    DateFormat dateFormat = DateFormat("yyyy-MM-dd HH:mm:ss");
    String dateTime = dateFormat.format(DateTime.now());
    final prefs = await SharedPreferences.getInstance();
    final String? login_user = prefs.getString('user');
    final int? branch_id = prefs.getInt('branch_id');
    Map logInUser = json.decode(login_user!);

    Map response = await Domain().SyncQrOrderFromCloud(branch_id.toString(), logInUser['company_id'].toString());
    if (response['status'] == '1') {
      //print('response data: ${response['data'][1]['order_cache_key']}');
      for(int i = 0; i < response['data'].length; i++){
        PosTable tableData = await PosDatabase.instance.readTableByCloudId(response['data'][i]['table_id']);
        //print('order detail: ${response['data'][i]['order_detail']}');
        OrderCache orderCache = OrderCache(
          order_cache_id: 0,
          order_cache_key: response['data'][i]['order_cache_key'].toString(),
          company_id: response['data'][i]['company_id'].toString(),
          branch_id: response['data'][i]['branch_id'].toString(),
          order_detail_id: '',
          table_use_sqlite_id: '',
          table_use_key: '',
          batch_id: response['data'][i]['batch_id'].toString(),
          dining_id: response['data'][i]['dining_id'].toString(),
          order_sqlite_id: '',
          order_key: '',
          order_by: '',
          order_by_user_id: '',
          cancel_by: '',
          cancel_by_user_id: '',
          customer_id: response['data'][i]['customer_id'].toString(),
          total_amount: response['data'][i]['total_amount'].toString(),
          qr_order: 1,
          qr_order_table_sqlite_id: tableData.table_sqlite_id.toString(),
          accepted: 1,
          sync_status: 1,
          created_at: dateTime,
          updated_at: '',
          soft_delete: ''
        );

        OrderCache data = await PosDatabase.instance.insertSqLiteOrderCache(orderCache);

        for(int j = 0; j < response['data'][i]['order_detail'].length; j++){
          BranchLinkProduct branchLinkProductData =
          await PosDatabase.instance.readSpecificBranchLinkProductByCloudId(response['data'][i]['order_detail'][j]['branch_link_product_id'].toString());
          print('category id: ${response['data'][i]['order_detail'][j]['category_id'].toString()}');
          if(response['data'][i]['order_detail'][j]['category_id'].toString() != '0'){
            Categories catData = await PosDatabase.instance.readSpecificCategoryByCloudId(response['data'][i]['order_detail'][j]['category_id'].toString());
            categoryLocalId = catData.category_sqlite_id.toString();
          } else {
            categoryLocalId = '0';
          }

          OrderDetail orderDetail = OrderDetail(
            order_detail_id: 0,
            order_detail_key: response['data'][i]['order_detail'][j]['order_detail_key'],
            order_cache_sqlite_id: data.order_cache_sqlite_id.toString(),
            order_cache_key: response['data'][i]['order_cache_key'].toString(),
            branch_link_product_sqlite_id: branchLinkProductData.branch_link_product_sqlite_id.toString(),
            category_sqlite_id: categoryLocalId,
            productName: response['data'][i]['order_detail'][j]['product_name'],
            has_variant: response['data'][i]['order_detail'][j]['has_variant'],
            product_variant_name: response['data'][i]['order_detail'][j]['product_variant_name'],
            price: response['data'][i]['order_detail'][j]['price'],
            original_price: branchLinkProductData.price,
            quantity: response['data'][i]['order_detail'][j]['quantity'],
            remark: response['data'][i]['order_detail'][j]['remark'],
            account: '',
            cancel_by: '',
            cancel_by_user_id: '',
            status: 0,
            sync_status: 1,
            created_at: dateTime,
            updated_at: '',
            soft_delete: '',
          );
          OrderDetail orderDetailData = await PosDatabase.instance.insertSqliteOrderDetail(orderDetail);

          if(response['data'][i]['order_detail'][j]['modifier'].length > 0){
            for(int k = 0; k < response['data'][i]['order_detail'][j]['modifier'].length; k++){
              OrderModifierDetail modifierDetail = OrderModifierDetail(
                  order_modifier_detail_id: 0,
                  order_modifier_detail_key: response['data'][i]['order_detail'][j]['modifier'][k]['order_modifier_detail_key'].toString(),
                  order_detail_sqlite_id: orderDetailData.order_detail_sqlite_id.toString(),
                  order_detail_id: '0',
                  order_detail_key: response['data'][i]['order_detail'][j]['order_detail_key'],
                  mod_item_id: response['data'][i]['order_detail'][j]['modifier'][k]['mod_item_id'].toString(),
                  mod_name: response['data'][i]['order_detail'][j]['modifier'][k]['name'].toString(),
                  mod_price: response['data'][i]['order_detail'][j]['modifier'][k]['price'].toString(),
                  mod_group_id: response['data'][i]['order_detail'][j]['modifier'][k]['mod_group_id'].toString(),
                  sync_status: 1,
                  created_at: dateTime,
                  updated_at: '',
                  soft_delete: ''
              );
              OrderModifierDetail orderModifierDetailData = await PosDatabase.instance.insertSqliteOrderModifierDetail(modifierDetail);
            }
          }
        }
      }
      //var jsonData = jsonDecode(response['data']);
      //print('order cache key: ${jsonData['order_cache_key']}');
    }
  }

/*
  test sync query  (tb_order)
*/
  test() async {
    OrderDetail data = await PosDatabase.instance.readSpecificOrderDetailByLocalId(7);
    print('data return: ${data.syncJson()}');
  }

/*
  ----------------------Cash record part----------------------------------------------------------------------------------------------------------------------------
*/
  updatedCashRecordSyncToCloud() async {
    List<String> value = [];
    await getNotSyncUpdatedCashRecord();
    print('${notSyncCashRecordList.length} cash call to sync api');
    for(int i = 0; i <  notSyncCashRecordList.length; i++){
      value.add(jsonEncode(notSyncCashRecordList[i]));
    }
    print('Value: ${value}');
    Map data = await Domain().SyncUpdatedCashRecordToCloud(value.toString());
    if (data['status'] == '1') {
      List responseJson = data['data'];
      for (var i = 0; i < responseJson.length; i++) {
        int orderPromoData = await PosDatabase.instance.updateCashRecordSyncStatusFromCloud(responseJson[i]['cash_record_key']);
      }
    }
  }

  cashRecordSyncToCloud() async {
    List<String> value = [];
    await getNotSyncCashRecord();
    print('${notSyncCashRecordList.length} cash call to sync api');
    for(int i = 0; i <  notSyncCashRecordList.length; i++){
      value.add(jsonEncode(notSyncCashRecordList[i]));
    }

    Map data = await Domain().SyncCashRecordToCloud(value.toString());
    if (data['status'] == '1') {
      List responseJson = data['data'];
      for (var i = 0; i < responseJson.length; i++) {
        int orderPromoData = await PosDatabase.instance.updateCashRecordSyncStatusFromCloud(responseJson[i]['cash_record_key']);
      }
    }
  }

  getNotSyncUpdatedCashRecord() async {
    List<CashRecord> data = await PosDatabase.instance.readAllNotSyncUpdatedCashRecord();
    notSyncCashRecordList = data;
  }

  getNotSyncCashRecord() async {
    List<CashRecord> data = await PosDatabase.instance.readAllNotSyncCashRecord();
    notSyncCashRecordList = data;
  }

/*
  ----------------------Pos table part----------------------------------------------------------------------------------------------------------------------------
*/
  updatedPosTableSyncToCloud() async {
    List<String> value = [];
    await getNotSyncUpdatedTable();
    print('${notSyncPosTableList.length} pos table call to sync api');
    for (int i = 0; i < notSyncPosTableList.length; i++) {
      value.add(jsonEncode(notSyncPosTableList[i]));
    }
    print('Value: ${value}');
    Map data = await Domain().SyncUpdatedPosTableToCloud(value.toString());
    if (data['status'] == '1') {
      List responseJson = data['data'];
      for (var i = 0; i < responseJson.length; i++) {
        int tableData = await PosDatabase.instance.updatePosTableSyncStatusFromCloud(responseJson[i]['table_id']);
      }
    }
  }

  getNotSyncUpdatedTable() async {
    List<PosTable> data = await PosDatabase.instance.readAllNotSyncUpdatedPosTable();
    notSyncPosTableList = data;
  }
/*
  ----------------------Order Tax detail part----------------------------------------------------------------------------------------------------------------------------
*/

  updatedOrderPromotionDetailSyncToCloud() async {
    List<String> value = [];
    await getNotSyncUpdatedOrderPromotionDetail();
    print('${notSyncOrderTaxDetailList.length} order promo detail call to sync api');
    for(int i = 0; i <  notSyncOrderTaxDetailList.length; i++){
      value.add(jsonEncode(notSyncOrderTaxDetailList[i]));
    }
    print('Value: ${value}');
    Map data = await Domain().SyncUpdatedOrderPromotionDetailToCloud(value.toString());
    if (data['status'] == '1') {
      List responseJson = data['data'];
      for (var i = 0; i < responseJson.length; i++) {
        int orderPromoData = await PosDatabase.instance.updateOrderPromotionDetailSyncStatusFromCloud(responseJson[i]['order_promotion_detail_key']);
      }
    }
  }

  orderPromotionDetailSyncToCloud() async {
    List<String> value = [];
    await getNotSyncOrderPromotionDetail();
    print('${notSyncOrderPromotionDetailList.length} order tax detail call to sync api');
    for(int i = 0; i <  notSyncOrderPromotionDetailList.length; i++){
      value.add(jsonEncode(notSyncOrderPromotionDetailList[i]));
    }
    print('Value: ${value}');
    Map data = await Domain().SyncOrderPromotionDetailToCloud(value.toString());
    if (data['status'] == '1') {
      List responseJson = data['data'];
      for (var i = 0; i < responseJson.length; i++) {
        int orderPromoData = await PosDatabase.instance.updateOrderPromotionDetailSyncStatusFromCloud(responseJson[i]['order_promotion_detail_key']);
      }
    }
  }

  getNotSyncUpdatedOrderPromotionDetail() async {
    List<OrderPromotionDetail> data = await PosDatabase.instance.readAllNotSyncUpdatedOrderPromotionDetail();
    notSyncOrderPromotionDetailList = data;
  }

  getNotSyncOrderPromotionDetail() async {
    List<OrderPromotionDetail> data = await PosDatabase.instance.readAllNotSyncOrderPromotionDetail();
    notSyncOrderPromotionDetailList = data;
  }

/*
  ----------------------Order Tax detail part----------------------------------------------------------------------------------------------------------------------------
*/
  updatedOrderTaxDetailSyncToCloud() async {
    List<String> value = [];
    await getNotSyncUpdatedOrderTaxDetail();
    print('${notSyncOrderTaxDetailList.length} order tax detail call to sync api');
    for(int i = 0; i <  notSyncOrderTaxDetailList.length; i++){
      value.add(jsonEncode(notSyncOrderTaxDetailList[i]));
    }
    print('Value: ${value}');
    Map data = await Domain().SyncUpdatedOrderTaxDetailToCloud(value.toString());
    if (data['status'] == '1') {
      List responseJson = data['data'];
      for (var i = 0; i < responseJson.length; i++) {
        int orderData = await PosDatabase.instance.updateOrderTaxDetailSyncStatusFromCloud(responseJson[i]['order_tax_detail_key']);
      }
    }
  }

  orderTaxDetailSyncToCloud() async {
    List<String> value = [];
    await getNotSyncOrderTaxDetail();
    print('${notSyncOrderTaxDetailList.length} order tax detail call to sync api');
    for(int i = 0; i <  notSyncOrderTaxDetailList.length; i++){
      value.add(jsonEncode(notSyncOrderTaxDetailList[i]));
    }
    print('Value: ${value}');
    Map data = await Domain().SyncOrderTaxDetailToCloud(value.toString());
    if (data['status'] == '1') {
      List responseJson = data['data'];
      for (var i = 0; i < responseJson.length; i++) {
        int orderData = await PosDatabase.instance.updateOrderTaxDetailSyncStatusFromCloud(responseJson[i]['order_tax_detail_key']);
      }
    }
  }

  getNotSyncUpdatedOrderTaxDetail() async {
    List<OrderTaxDetail> data = await PosDatabase.instance.readAllNotSyncUpdatedOrderTaxDetail();
    notSyncOrderTaxDetailList = data;
  }

  getNotSyncOrderTaxDetail() async {
    List<OrderTaxDetail> data = await PosDatabase.instance.readAllNotSyncOrderTaxDetail();
    notSyncOrderTaxDetailList = data;
  }

/*
  ----------------------Table use detail part-------------------------------------------------------------------------------------------------------------------------------------
*/
  updatedTableUseDetailSyncToCloud() async {
    List<String> value = [];
    await getNotSyncUpdatedTableUseDetail();
    print('${notSyncTableUseDetailList.length} table use detail call to sync api');
    for(int i = 0; i < notSyncTableUseDetailList.length; i++){
      value.add(jsonEncode(notSyncTableUseDetailList[i]));
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
      value.add(jsonEncode(notSyncTableUseDetailList[i]));
    }
    print('Value: ${value.toString()}');
    Map data = await Domain().SyncTableUseDetailToCloud(value.toString());
    if (data['status'] == '1') {
      List responseJson = data['data'];
      for (var i = 0; i < responseJson.length; i++) {
        int tablaUseDetailData = await PosDatabase.instance.updateTableUseDetailSyncStatusFromCloud(responseJson[i]['table_use_detail_key']);
      }
    }

  }


  getNotSyncUpdatedTableUseDetail() async {
    List<TableUseDetail> data = await PosDatabase.instance.readAllNotSyncUpdatedTableUseDetail();
    notSyncTableUseDetailList = data;
  }

  getNotSyncTableUseDetail() async {
    List<TableUseDetail> data = await PosDatabase.instance.readAllNotSyncTableUseDetail();
    notSyncTableUseDetailList = data;
  }

/*
  ----------------------Table use part---------------------------------------------------------------------------------------------------------------------------------------
*/
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


  getNotSyncUpdatedTableUse() async {
    List<TableUse> data = await PosDatabase.instance.readAllNotSyncUpdatedTableUse();
    notSyncTableUseList = data;
  }

  getNotSyncTableUse() async {
    List<TableUse> data = await PosDatabase.instance.readAllNotSyncTableUse();
    notSyncTableUseList = data;
  }

/*
  ----------------------Order modifier detail part-----------------------------------------------------------------------------------------------------------------------------
*/
  updatedOrderModifierDetailSyncToCloud() async {
    List<String> value = [];
    await getNotSyncUpdatedOrderModifierDetail();
    print('${notSyncOrderModifierDetailList.length} mod detail call to sync api');
    for(int i = 0; i < notSyncOrderModifierDetailList.length; i++){
      value.add(jsonEncode(notSyncOrderModifierDetailList[i]));
    }
    print('value: ${value}');
    Map data = await Domain().SyncUpdatedOrderModifierDetailToCloud(value.toString());
    if(data['status'] == '1'){
      List responseJson = data['data'];
      for(int i = 0 ; i <responseJson.length; i++){
        int orderCacheData = await PosDatabase.instance.updateOrderModifierDetailSyncStatusFromCloud(responseJson[i]['order_modifier_detail_key']);
      }
    }
  }

  orderModifierDetailSyncToCloud() async {
    List<String> value = [];
    await getNotSyncOrderModifierDetail();
    print('${notSyncOrderModifierDetailList.length} mod detail call to sync api');
    for(int i = 0; i < notSyncOrderModifierDetailList.length; i++){
      value.add(jsonEncode(notSyncOrderModifierDetailList[i]));
    }
    print('value: ${value}');
    Map data = await Domain().SyncOrderModifierDetailToCloud(value.toString());
    if(data['status'] == '1'){
      List responseJson = data['data'];
      for(int i = 0 ; i <responseJson.length; i++){
        int orderCacheData = await PosDatabase.instance.updateOrderModifierDetailSyncStatusFromCloud(responseJson[i]['order_modifier_detail_key']);
      }
    }
  }

  getNotSyncUpdatedOrderModifierDetail() async {
    List<OrderModifierDetail> data = await PosDatabase.instance.readAllNotSyncUpdatedOrderModifierDetail();
    notSyncOrderModifierDetailList = data;
  }

  getNotSyncOrderModifierDetail() async {
    List<OrderModifierDetail> data = await PosDatabase.instance.readAllNotSyncOrderModDetail();
    notSyncOrderModifierDetailList = data;
  }

/*
  ----------------------Order detail part---------------------------------------------------------------------------------------------------------------------------------------
*/

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
  updatedOrderSyncToCloud() async {
    List<String> value = [];
    await getNotSyncUpdatedOrder();
    for(int i = 0; i < notSyncOrderList.length; i++){
      value.add(jsonEncode(notSyncOrderList[i]));
    }
    print('Value: ${value.toString()}');
    Map data = await Domain().SyncUpdatedOrderToCloud(value.toString());
    if (data['status'] == '1') {
      List responseJson = data['data'];
      for (var i = 0; i < responseJson.length; i++) {
        //print('response order key: ${responseJson[i]['order_key']}');
        int orderData = await PosDatabase.instance.updateOrderSyncStatusFromCloud(responseJson[i]['order_key']);
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
    Map data = await Domain().SyncOrderToCloud(value.toString());
    if (data['status'] == '1') {
      List responseJson = data['data'];
      for (var i = 0; i < responseJson.length; i++) {
        int orderData = await PosDatabase.instance.updateOrderSyncStatusFromCloud(responseJson[i]['order_key']);
      }
    }
  }

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
    List<int> syncRecordIdList = [];
    if (data['status'] == '1') {
      List responseJson = data['data'];

      for (var i = 0; i < responseJson.length; i++) {
        switch(responseJson[i]['type']){
          case '0':
            bool status = await callProductQuery(data: responseJson[i]['data'], method: responseJson[i]['method']);
            if(status == true){
              syncRecordIdList.add(responseJson[i]['id']);
            }
            break;
          case '1':
            bool status = await callCategoryQuery(data: responseJson[i]['data'], method: responseJson[i]['method']);
            if(status == true){
              syncRecordIdList.add(responseJson[i]['id']);
            }
            break;
          case '2':
            bool status = await callModifierLinkProductQuery(data: responseJson[i]['data'], method: responseJson[i]['method']);
            if(status == true){
              syncRecordIdList.add(responseJson[i]['id']);
            }
            break;
          case '3':
            bool status = await callVariantGroupQuery(data: responseJson[i]['data'], method: responseJson[i]['method']);
            if(status == true){
              syncRecordIdList.add(responseJson[i]['id']);
            }
            break;
          case '4':
            bool status = await callVariantItemQuery(data: responseJson[i]['data'], method: responseJson[i]['method']);
            if(status == true){
              syncRecordIdList.add(responseJson[i]['id']);
            }
            break;
          case '5':
            bool status = await callProductVariantQuery(data: responseJson[i]['data'], method: responseJson[i]['method']);
            if(status == true){
              syncRecordIdList.add(responseJson[i]['id']);
            }
            break;
          case '6':
            bool status = await callProductVariantDetailQuery(data: responseJson[i]['data'], method: responseJson[i]['method']);
            if(status == true){
              syncRecordIdList.add(responseJson[i]['id']);
            }
            break;
          case '7':
            bool status = await callBranchLinkProductQuery(data: responseJson[i]['data'], method: responseJson[i]['method']);
            if(status == true){
              syncRecordIdList.add(responseJson[i]['id']);
            }
            break;
          case '8':
            bool status = await callModifierGroupQuery(data: responseJson[i]['data'], method: responseJson[i]['method']);
            if(status == true){
              syncRecordIdList.add(responseJson[i]['id']);
            }
            break;
          case '9':
            bool status = await callModifierItemQuery(data: responseJson[i]['data'], method: responseJson[i]['method']);
            if(status == true){
              syncRecordIdList.add(responseJson[i]['id']);
            }
            break;
          case '10':
            bool status = await callBranchLinkModifierQuery(data: responseJson[i]['data'], method: responseJson[i]['method']);
            if(status == true){
              syncRecordIdList.add(responseJson[i]['id']);
            }
            break;
          case '11':
            bool status = await callUserQuery(data: responseJson[i]['data'], method: responseJson[i]['method']);
            if(status == true){
              syncRecordIdList.add(responseJson[i]['id']);
            }
            break;
          case '12':
            bool status = await callBranchLinkUserQuery(data: responseJson[i]['data'], method: responseJson[i]['method']);
            if(status == true){
              syncRecordIdList.add(responseJson[i]['id']);
            }
            break;
          case '13':
            bool status = await callCustomerQuery(data: responseJson[i]['data'], method: responseJson[i]['method']);
            if(status == true){
              syncRecordIdList.add(responseJson[i]['id']);
            }
            break;
          case '14':
            print('14 called');
            bool status = await callPaymentLinkCompanyQuery(data: responseJson[i]['data'], method: responseJson[i]['method']);
            if(status == true){
              syncRecordIdList.add(responseJson[i]['id']);
            }
            break;
          case'15':
            bool status = await callTaxQuery(data: responseJson[i]['data'], method: responseJson[i]['method']);
            if(status == true){
              syncRecordIdList.add(responseJson[i]['id']);
            }
            break;
          case '16':
            bool status = await callBranchLinkTax(data: responseJson[i]['data'], method: responseJson[i]['method']);
            if(status == true){
              syncRecordIdList.add(responseJson[i]['id']);
            }
            break;
          case '17':
            bool status = await callTaxLinkDining(data: responseJson[i]['data'], method: responseJson[i]['method']);
            if(status == true){
              syncRecordIdList.add(responseJson[i]['id']);
            }
            break;
          case '18':
            bool status = await callDiningOptionQuery(data: responseJson[i]['data'], method: responseJson[i]['method']);
            if(status == true){
              syncRecordIdList.add(responseJson[i]['id']);
            }
            break;
          case '19':
            bool status = await callBranchLinkDiningQuery(data: responseJson[i]['data'], method: responseJson[i]['method']);
            if(status == true){
              syncRecordIdList.add(responseJson[i]['id']);
            }
            break;
        }
      }
      //update sync record
      Map updateResponse = await Domain().updateAllCloudSyncRecord('5', syncRecordIdList.toString());
    }
  }

  callBranchLinkDiningQuery({data, method}) async {
    bool isComplete = false;
    BranchLinkDining  diningData = BranchLinkDining.fromJson(data[0]);
    try{
      if(method == '0'){
        BranchLinkDining data = await PosDatabase.instance.insertBranchLinkDining(diningData);
        if(data.created_at != ''){
          isComplete = true;
        }
      } else{
        int data = await PosDatabase.instance.updateBranchLikDining(diningData);
        if(data == 1){
          isComplete = true;
        }
      }
      return isComplete;

    } catch(e){
      return isComplete = false;
    }
  }

  callDiningOptionQuery({data, method}) async {
    bool isComplete = false;
    DiningOption diningOption = DiningOption.fromJson(data[0]);
    if(method == '0'){
      DiningOption data = await PosDatabase.instance.insertDiningOption(diningOption);
      if(data.created_at != ''){
        isComplete = true;
      }
    } else {
      int data = await PosDatabase.instance.updateDiningOption(diningOption);
      if(data == 1){
        isComplete = true;
      }
    }
    return isComplete;
  }

  callTaxLinkDining({data, method}) async {
    bool isComplete = false;
    TaxLinkDining taxData = TaxLinkDining.fromJson(data[0]);
    try{
      if(method == '0'){
        TaxLinkDining data = await PosDatabase.instance.insertTaxLinkDining(taxData);
        if(data.created_at != ''){
          isComplete = true;
        }
      } else {
        int data = await PosDatabase.instance.updateTaxLinkDining(taxData);
        if(data == 1){
          isComplete = true;
        }
      }
      return isComplete;
    } catch(e){
      return isComplete = false;
    }
  }

  callBranchLinkTax({data, method}) async {
    bool isComplete = false;
    BranchLinkTax taxData = BranchLinkTax.fromJson(data[0]);
    try{
      if(method == '0'){
        BranchLinkTax data = await PosDatabase.instance.insertBranchLinkTax(taxData);
        if(data.created_at != ''){
          isComplete = true;
        }
      } else {
        int data = await PosDatabase.instance.updateBranchLinkTax(taxData);
        print('update status: ${data}');
        if(data == 1){
          isComplete = true;
        }
      }
      return isComplete;
    } catch(e){
      return isComplete = false;
    }
  }

  callTaxQuery({data, method}) async {
    bool isComplete = false;
    Tax taxData = Tax.fromJson(data[0]);
    try{
      if(method == '0'){
        Tax data = await PosDatabase.instance.insertTax(taxData);
        if(data.created_at != ''){
          isComplete = true;
        }
      }else {
        int data = await PosDatabase.instance.updateTax(taxData);
        if(data == 1){
          isComplete = true;
        }
      }
      return isComplete;
    } catch(e){
      print('tax query error: ${e}');
      return isComplete = false;
    }
  }

  callPaymentLinkCompanyQuery({data, method}) async {
    bool isComplete = false;
    PaymentLinkCompany paymentData = PaymentLinkCompany.fromJson(data[0]);
    try{
      if(method == '0'){
        PaymentLinkCompany data = await PosDatabase.instance.insertPaymentLinkCompany(paymentData);
        if(data.created_at != ''){
          isComplete = true;
        }
      } else {
        int data = await PosDatabase.instance.updatePaymentLinkCompany(paymentData);
        if(data == 1){
          isComplete = true;
        }
      }
      return isComplete;
    } catch(e){
      return isComplete = false;
    }
  }

  callCustomerQuery({data, method}) async {
    bool isComplete = false;
    Customer customerData = Customer.fromJson(data[0]);
    if(method == '0'){
      Customer data = await PosDatabase.instance.insertCustomer(customerData);
      if(data.created_at != ''){
        isComplete = true;
      }
    } else {
      int data = await PosDatabase.instance.updateCustomer(customerData);
      if(data == 1){
        isComplete = true;
      }
    }
    return isComplete;
  }

  callBranchLinkUserQuery({data, method}) async {
    bool isComplete = false;
    BranchLinkUser branchLinkUserData = BranchLinkUser.fromJson(data[0]);
    if(method == '0'){
      //create
      BranchLinkUser data = await PosDatabase.instance.insertBranchLinkUser(branchLinkUserData);
      if(data.created_at != ''){
        isComplete = true;
      }
    } else {
      //update
      int data = await PosDatabase.instance.updateBranchLinkUser(branchLinkUserData);
      if(data == 1){
        isComplete = true;
      }
    }
    return isComplete;
  }

  callUserQuery({data, method}) async {
    bool isComplete = false;
    User userData = User.fromJson(data[0]);
    if(method == '0'){
      //create
      User user = await PosDatabase.instance.insertUser(userData);
      if(user.created_at != ''){
        isComplete = true;
      }
    } else {
      //update
      int data = await PosDatabase.instance.updateUser(userData);
      if(data == 1){
        isComplete = true;
      }
    }
    return isComplete;
  }

  callBranchLinkModifierQuery({data, method}) async {
    bool isComplete = false;
    BranchLinkModifier branchLinkModifierData = BranchLinkModifier.fromJson(data[0]);
    if(method == '0'){
      //create
      BranchLinkModifier insertData = await PosDatabase.instance.insertBranchLinkModifier(branchLinkModifierData);
      if(insertData.created_at != ''){
        isComplete = true;
      }
    } else {
      //update
      int updateData = await PosDatabase.instance.updateBranchLinkModifier(branchLinkModifierData);
      if(updateData == 1){
        isComplete = true;
      }
    }
    return isComplete;
  }

  callModifierItemQuery({data, method}) async {
    bool isComplete = false;
    ModifierItem modifierItemData = ModifierItem.fromJson(data[0]);
    if(method == '0'){
      //create
      ModifierItem insertData = await PosDatabase.instance.insertModifierItem(modifierItemData);
      if(insertData.created_at != ''){
        isComplete = true;
      }
    } else {
      //update
      int updateData = await PosDatabase.instance.updateModifierItem(modifierItemData);
      if(updateData == 1){
        isComplete = true;
      }
    }
    return isComplete;
  }

  callModifierGroupQuery({data, method}) async {
    bool isComplete = false;
    ModifierGroup modifierGroupData = ModifierGroup.fromJson(data[0]);
    if(method == '0'){
      //create
      ModifierGroup insertData = await PosDatabase.instance.insertModifierGroup(modifierGroupData);
      if(insertData.created_at != ''){
        isComplete = true;
      }
    } else {
      //update
      print('update mod group called');
      int updateData = await PosDatabase.instance.updateModifierGroup(modifierGroupData);
      if(updateData == 1){
        isComplete = true;
      }
    }
    return isComplete;
  }

  callBranchLinkProductQuery({data, method}) async {
    bool isComplete = false;
    BranchLinkProduct branchLinkProductData = BranchLinkProduct.fromJson(data[0]);
    Product? productData = await PosDatabase.instance.readProductSqliteID(branchLinkProductData.product_id!);
    ProductVariant? productVariantData = await PosDatabase.instance.readProductVariantSqliteID(branchLinkProductData.product_variant_id!);
    BranchLinkProduct object = BranchLinkProduct(
        branch_link_product_id: branchLinkProductData.branch_link_product_id,
        branch_id: branchLinkProductData.branch_id,
        product_sqlite_id: productData!.product_sqlite_id.toString(),
        product_id: branchLinkProductData.product_id,
        has_variant: branchLinkProductData.has_variant,
        product_variant_sqlite_id: productVariantData != null ? productVariantData.product_variant_sqlite_id.toString(): '0',
        product_variant_id: branchLinkProductData.product_variant_id,
        b_SKU: branchLinkProductData.b_SKU,
        price: branchLinkProductData.price,
        stock_type: branchLinkProductData.stock_type,
        daily_limit: branchLinkProductData.daily_limit,
        daily_limit_amount: branchLinkProductData.daily_limit_amount,
        stock_quantity: branchLinkProductData.stock_quantity,
        sync_status: 1,
        created_at: branchLinkProductData.created_at,
        updated_at: branchLinkProductData.updated_at,
        soft_delete: branchLinkProductData.soft_delete
    );
    if(method == '0'){
      //create
      BranchLinkProduct data = await PosDatabase.instance.insertBranchLinkProduct(object);
      if(data.branch_link_product_sqlite_id != null){
        isComplete = true;
      }
    } else {
      //update
      int updateData = await PosDatabase.instance.updateBranchLinkProduct(object);
      if(updateData == 1){
        isComplete = true;
      }
    }
    return isComplete;
  }

  callProductVariantDetailQuery({data, method}) async {
    bool isComplete = false;
    ProductVariantDetail productVariantDetailItem = ProductVariantDetail.fromJson(data[0]);
    ProductVariant? productVariantData = await PosDatabase.instance.readProductVariantSqliteID(productVariantDetailItem.product_variant_id!);
    VariantItem? variantItemData = await PosDatabase.instance.readVariantItemSqliteID(productVariantDetailItem.variant_item_id!);
    ProductVariantDetail object = ProductVariantDetail(
        product_variant_detail_id: productVariantDetailItem.product_variant_detail_id,
        product_variant_id: productVariantDetailItem.product_variant_id,
        product_variant_sqlite_id: productVariantData!.product_variant_sqlite_id.toString(),
        variant_item_id: productVariantDetailItem.variant_item_id,
        variant_item_sqlite_id: variantItemData!.variant_item_sqlite_id.toString(),
        sync_status: 2,
        created_at: productVariantDetailItem.created_at,
        updated_at: productVariantDetailItem.updated_at,
        soft_delete: productVariantDetailItem.soft_delete
    );
    if(method == '0'){
      //create
      ProductVariantDetail data = await PosDatabase.instance.insertProductVariantDetail(object);
      if(data.product_variant_detail_sqlite_id != null){
        isComplete = true;
      }
    } else {
      //update
      int data = await PosDatabase.instance.updateProductVariantDetail(object);
      if(data == 1){
        isComplete = true;
      }
    }
    return isComplete;
  }

  callProductVariantQuery({data, method}) async {
    bool isComplete = false;
    ProductVariant productVariantItem = ProductVariant.fromJson(data[0]);
    Product? productData = await PosDatabase.instance.readProductSqliteID(productVariantItem.product_id!);
    ProductVariant object = ProductVariant(
        product_variant_id: productVariantItem.product_variant_id,
        product_sqlite_id: productData!.product_sqlite_id.toString(),
        product_id: productVariantItem.product_id,
        variant_name: productVariantItem.variant_name,
        SKU: productVariantItem.SKU,
        price: productVariantItem.price,
        stock_type: productVariantItem.stock_type,
        daily_limit: productVariantItem.daily_limit,
        daily_limit_amount: productVariantItem.daily_limit_amount,
        stock_quantity: productVariantItem.stock_quantity,
        sync_status: 2,
        created_at: productVariantItem.created_at,
        updated_at: productVariantItem.updated_at,
        soft_delete: productVariantItem.soft_delete
    );
    if(method == '0'){
      //create
      ProductVariant data = await PosDatabase.instance.insertProductVariant(object);
      if(data.product_variant_sqlite_id != null){
        isComplete = true;
      }
    } else {
      //update
      int data = await PosDatabase.instance.updateProductVariant(object);
      if(data == 1){
        isComplete = true;
      }
    }
    return isComplete;
  }

  callVariantItemQuery({data, method}) async {
    bool isComplete = false;
    VariantItem variantItemData = VariantItem.fromJson(data[0]);
    VariantGroup? variantGroupData = await PosDatabase.instance.readVariantGroupSqliteID(variantItemData.variant_group_id!);
    VariantItem object = VariantItem(
        variant_item_id: variantItemData.variant_item_id,
        variant_group_id: variantItemData.variant_group_id,
        variant_group_sqlite_id: variantGroupData != null ? variantGroupData.variant_group_sqlite_id.toString(): '0',
        name: variantItemData.name,
        sync_status: 2,
        created_at: variantItemData.created_at,
        updated_at: variantItemData.updated_at,
        soft_delete: variantItemData.soft_delete
    );
    if(method == '0'){
      //create
      VariantItem data = await PosDatabase.instance.insertVariantItem(object);
      if(data.variant_item_sqlite_id != null){
        isComplete = true;
      }
    } else {
      //update
      int data = await PosDatabase.instance.updateVariantItem(object);
      if(data == 1){
        isComplete = true;
      }
    }
    return isComplete;
  }

  callVariantGroupQuery({data, method}) async {
    bool isComplete = false;
    VariantGroup variantData = VariantGroup.fromJson(data[0]);
    Product? productData = await PosDatabase.instance.readProductSqliteID(variantData.product_id!);
    VariantGroup object = VariantGroup(
        child: [],
        variant_group_id: variantData.variant_group_id,
        product_id: variantData.product_id,
        product_sqlite_id: productData!.product_sqlite_id.toString(),
        name: variantData.name,
        sync_status: 2,
        created_at: variantData.created_at,
        updated_at: variantData.updated_at,
        soft_delete: variantData.soft_delete
    );
    if(method == '0'){
      //create
      VariantGroup data = await PosDatabase.instance.insertVariantGroup(object);
      if(data.variant_group_sqlite_id != null){
        isComplete = true;
      }
    } else {
      //update
      int data = await PosDatabase.instance.updateVariantGroup(object);
      if(data == 1){
        isComplete = true;
      }
    }
    return isComplete;
  }

  callModifierLinkProductQuery({data, method}) async {
    bool isComplete = false;
    ModifierLinkProduct modData = ModifierLinkProduct.fromJson(data[0]);
    Product? productData = await PosDatabase.instance.readProductSqliteID(modData.product_id!);
    ModifierLinkProduct object = ModifierLinkProduct(
      modifier_link_product_id: modData.modifier_link_product_id,
      mod_group_id: modData.mod_group_id,
      product_id: modData.product_id,
      product_sqlite_id: productData!.product_sqlite_id.toString(),
      sync_status: 2,
      created_at: modData.created_at,
      updated_at: modData.updated_at,
      soft_delete: modData.soft_delete,
    );
    if(method == '0'){
      //create
      ModifierLinkProduct data = await PosDatabase.instance.insertModifierLinkProduct(object);
      if(data.modifier_link_product_sqlite_id != null){
        isComplete = true;
      }
    } else {
      //update
      int data = await PosDatabase.instance.updateModifierLinkProduct(object);
      if(data == 1){
        isComplete = true;
      }
    }
    return isComplete;
  }

  callCategoryQuery({data, method}) async {
    print('query call: ${data[0]}');
    final category = Categories.fromJson(data[0]);
    bool isComplete = false;

    if(method == '0'){
      Categories categoryData = await PosDatabase.instance.insertCategories(Categories.fromJson(data[0]));
      if(categoryData.category_sqlite_id != null){
        isComplete = true;
      }
    } else {
      int categoryData = await PosDatabase.instance.updateCategoryFromCloud(Categories.fromJson(data[0]));
      if(categoryData == 1){
        isComplete = true;
      }
    }
    return isComplete;
  }

  callProductQuery({data, method}) async {
    bool isComplete = false;
    Product productItem = Product.fromJson(data[0]);
    Categories? categoryData = await PosDatabase.instance.readCategorySqliteID(productItem.category_id!);
    Product productObject = Product(
        product_id: productItem.product_id,
        category_id: productItem.category_id,
        category_sqlite_id: categoryData != null ? categoryData.category_sqlite_id.toString(): '0' ,
        company_id: productItem.company_id,
        name: productItem.name,
        price: productItem.price,
        description: productItem.description,
        SKU: productItem.SKU,
        image: productItem.image,
        has_variant: productItem.has_variant,
        stock_type: productItem.stock_type,
        stock_quantity: productItem.stock_quantity,
        available: productItem.available,
        graphic_type: productItem.graphic_type,
        color: productItem.color,
        daily_limit: productItem.daily_limit,
        daily_limit_amount: productItem.daily_limit_amount,
        sync_status: 2,
        created_at: productItem.created_at,
        updated_at: productItem.updated_at,
        soft_delete: productItem.soft_delete
    );
    if(method == '0'){
      //create
      Product productData = await PosDatabase.instance.insertProduct(productObject);
      if(productData.product_sqlite_id != null){
        isComplete = true;
      }
    } else {
      //update
      int data = await PosDatabase.instance.updateProduct(productObject);
      if(data == 1){
        isComplete = true;
      }
    }
    return isComplete;
  }
}
