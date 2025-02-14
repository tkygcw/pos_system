import 'dart:convert';

import 'package:f_logs/model/flog/flog.dart';
import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';
import 'package:pos_system/main.dart';
import 'package:pos_system/object/app_setting.dart';
import 'package:pos_system/object/attendance.dart';
import 'package:pos_system/object/branch_link_product.dart';
import 'package:pos_system/object/cancel_receipt.dart';
import 'package:pos_system/object/checklist.dart';
import 'package:pos_system/object/ingredient_movement.dart';
import 'package:pos_system/object/kitchen_list.dart';
import 'package:pos_system/object/order_detail_cancel.dart';
import 'package:pos_system/object/order_payment_split.dart';
import 'package:pos_system/object/printer.dart';
import 'package:pos_system/object/printer_link_category.dart';
import 'package:pos_system/object/product.dart';
import 'package:pos_system/object/receipt.dart';
import 'package:pos_system/object/refund.dart';
import 'package:pos_system/object/sales_per_day/category_sales_per_day.dart';
import 'package:pos_system/object/sales_per_day/dining_sales_per_day.dart';
import 'package:pos_system/object/sales_per_day/modifier_sales_per_day.dart';
import 'package:pos_system/object/sales_per_day/product_sales_per_day.dart';
import 'package:pos_system/object/sales_per_day/sales_per_day.dart';
import 'package:pos_system/object/settlement.dart';
import 'package:pos_system/object/settlement_link_payment.dart';
import 'package:pos_system/object/table.dart';
import 'package:pos_system/object/table_use.dart';
import 'package:pos_system/object/table_use_detail.dart';
import 'package:pos_system/object/transfer_owner.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../database/domain.dart';
import '../database/pos_database.dart';
import 'cash_record.dart';
import 'dynamic_qr.dart';
import 'order.dart';
import 'order_cache.dart';
import 'order_detail.dart';
import 'order_modifier_detail.dart';
import 'order_promotion_detail.dart';
import 'order_tax_detail.dart';

class SyncToCloud {
  int count = 0;
  bool emptyResponse = false;
  List<PosTable> notSyncPosTableList = [];
  List<Product> notSyncProductList = [];
  List<IngredientMovement> notSyncIngredientMovementList = [];
  List<Order> notSyncOrderList = [];
  List<OrderTaxDetail> notSyncOrderTaxDetailList = [];
  List<OrderPromotionDetail> notSyncOrderPromotionDetailList = [];
  List<OrderCache> notSyncOrderCacheList = [];
  List<OrderDetail> notSyncOrderDetailList = [];
  List<OrderDetailCancel> notSyncOrderDetailCancelList = [];
  List<OrderModifierDetail> notSyncOrderModifierDetailList = [];
  List<TableUse> notSyncTableUseList = [];
  List<TableUseDetail> notSyncTableUseDetailList = [];
  List<Table> notSyncTableList = [];
  List<CashRecord> notSyncCashRecordList = [];
  List<AppSetting> notSyncAppSettingList = [];
  List<TransferOwner> notSyncTransferOwnerList = [];
  List<Settlement> notSyncSettlementList = [];
  List<SettlementLinkPayment>  notSyncSettlementLinkPaymentList = [];
  List<Refund> notSyncRefundList = [];
  List<BranchLinkProduct> notSyncBranchLinkProductList = [];
  List<Printer> notSyncPrinterList = [];
  List<PrinterLinkCategory> notSyncPrinterCategoryList = [];
  List<DynamicQR> notSyncDynamicQr = [];
  String? table_use_value, table_use_detail_value, order_cache_value, order_detail_value, order_detail_cancel_value,
      order_modifier_detail_value, order_value, order_promotion_value, order_tax_value, receipt_value, refund_value, table_value, settlement_value,
      settlement_link_payment_value, cash_record_value, app_setting_value, branch_link_product_value, printer_value, printer_link_category_value,
      transfer_owner_value, checklist_value, kitchen_list_value, attendance_value, dynamic_qr_value, order_payment_split_value, cancel_receipt_value, product_value,
      ingredient_movement_value, sales_per_day_value, sales_category_per_day_value, sales_product_per_day_value, sales_modifier_per_day_value, sales_dining_per_day_value;
  late SharedPreferences prefs;
  bool isNewSync = false;
  int dataSelectLimit = 10;

  resetCount(){
    count = 0;
  }

  getPrefData() async {
    prefs = await SharedPreferences.getInstance();
    if(prefs.getInt('new_sync') == null){
      await prefs.setInt('new_sync', 0);
    }
    isNewSync = prefs.getInt('new_sync') == 1 ? true : false;
  }

  Future<int> syncAllToCloud({bool? isManualSync}) async {
    print('sync to cloud called');
    await getPrefData();
    dataSelectLimit = isNewSync ? 1000 : 10;
    int status = 0;
    try{
      await getAllValue();
      final prefs = await SharedPreferences.getInstance();
      final int? device_id = prefs.getInt('device_id');
      final String? login_value = prefs.getString('login_value');

      DateTime syncStart = DateTime.now();
      if(isPaused){
        print("sync to cloud paused");
        emptyResponse = true;
        return status = 0;
      }
      Map data = await Domain().syncLocalUpdateToCloud(
          device_id: device_id.toString(),
          value: login_value,
          isSync: true,
          isManualSync: isManualSync,
          table_use_value: this.table_use_value,
          table_use_detail_value: this.table_use_detail_value,
          order_cache_value: this.order_cache_value,
          order_detail_value: this.order_detail_value,
          order_detail_cancel_value: this.order_detail_cancel_value,
          order_modifier_value: this.order_modifier_detail_value,
          order_value: this.order_value,
          order_promotion_value: this.order_promotion_value,
          order_tax_value: this.order_tax_value,
          receipt_value: this.receipt_value,
          refund_value: this.refund_value,
          settlement_value: this.settlement_value,
          settlement_link_payment_value: this.settlement_link_payment_value,
          cash_record_value: this.cash_record_value,
          app_setting_value: this.app_setting_value,
          branch_link_product_value: this.branch_link_product_value,
          table_value: this.table_value,
          printer_value: this.printer_value,
          printer_link_category_value: this.printer_link_category_value,
          transfer_owner_value: this.transfer_owner_value,
          checklist_value:  this.checklist_value,
          kitchen_list_value:  this.kitchen_list_value,
          attendance_value:  this.attendance_value,
          dynamic_qr_value: this.dynamic_qr_value,
          order_payment_split_value: this.order_payment_split_value,
          cancel_receipt_value: this.cancel_receipt_value,
          product_value:  this.product_value,
          ingredient_movement_value:  this.ingredient_movement_value,
          sales_per_day_value: this.sales_per_day_value,
          sales_category_per_day_value: this.sales_category_per_day_value,
          sales_product_per_day_value: this.sales_product_per_day_value,
          sales_modifier_per_day_value: this.sales_modifier_per_day_value,
          sales_dining_per_day_value: this.sales_dining_per_day_value
      );
      print("Step 2: order modifier detail length: ${order_modifier_detail_value!.length} local finished sync to cloud at ${DateTime.now()}, take ${DateTime.now().difference(syncStart).inSeconds} seconds");
      if (data['status'] == '1') {
        List responseJson = data['data'];
        if(responseJson.isNotEmpty){
          emptyResponse = false;
          DateTime updateSyncStatusStart = DateTime.now();
          for(int i = 0; i < responseJson.length; i++){
            switch(responseJson[i]['table_name']){
              case 'tb_table_use': {
                await PosDatabase.instance.updateTableUseSyncStatusFromCloud(responseJson[i]['table_use_key']);
              }
              break;
              case 'tb_table_use_detail': {
                await PosDatabase.instance.updateTableUseDetailSyncStatusFromCloud(responseJson[i]['table_use_detail_key']);
              }
              break;
              case 'tb_order_cache': {
                await PosDatabase.instance.updateOrderCacheSyncStatusFromCloud(responseJson[i]['order_cache_key']);
              }
              break;
              case 'tb_order_detail': {
                await PosDatabase.instance.updateOrderDetailSyncStatusFromCloud(responseJson[i]['order_detail_key']);
              }
              break;
              case 'tb_order_detail_cancel': {
                await PosDatabase.instance.updateOrderDetailCancelSyncStatusFromCloud(responseJson[i]['order_detail_cancel_key']);
              }
              break;
              case 'tb_order_modifier_detail': {
                await PosDatabase.instance.updateOrderModifierDetailSyncStatusFromCloud(responseJson[i]['order_modifier_detail_key']);
              }
              break;
              case 'tb_order': {
                await PosDatabase.instance.updateOrderSyncStatusFromCloud(responseJson[i]['order_key'], settlement_key: responseJson[i]['settlement_key']);
              }
              break;
              case 'tb_order_promotion_detail': {
                await PosDatabase.instance.updateOrderPromotionDetailSyncStatusFromCloud(responseJson[i]['order_promotion_detail_key']);
              }
              break;
              case 'tb_order_tax_detail': {
                await PosDatabase.instance.updateOrderTaxDetailSyncStatusFromCloud(responseJson[i]['order_tax_detail_key']);
              }
              break;
              case 'tb_receipt': {
                await PosDatabase.instance.updateReceiptSyncStatusFromCloud(responseJson[i]['receipt_key']);
              }
              break;
              case 'tb_refund': {
                await PosDatabase.instance.updateRefundSyncStatusFromCloud(responseJson[i]['refund_key']);
              }
              break;
              case 'tb_settlement': {
                await PosDatabase.instance.updateSettlementSyncStatusFromCloud(responseJson[i]['settlement_key']);
              }
              break;
              case 'tb_settlement_link_payment': {
                await PosDatabase.instance.updateSettlementLinkPaymentSyncStatusFromCloud(responseJson[i]['settlement_link_payment_key']);
              }
              break;
              case 'tb_cash_record': {
                await PosDatabase.instance.updateCashRecordSyncStatusFromCloud(responseJson[i]['cash_record_key']);
              }
              break;
              case 'tb_app_setting': {
                await PosDatabase.instance.updateAppSettingSyncStatusFromCloud(responseJson[i]['branch_id']);
              }
              break;
              case 'tb_branch_link_product': {
                await PosDatabase.instance.updateBranchLinkProductSyncStatusFromCloud(responseJson[i]['branch_link_product_id']);
              }
              break;
              case 'tb_table': {
                await PosDatabase.instance.updatePosTableSyncStatusFromCloud(responseJson[i]['table_id']);
              }
              break;
              case 'tb_printer': {
                await PosDatabase.instance.updatePrinterSyncStatusFromCloud(responseJson[i]['printer_key']);
              }
              break;
              case 'tb_printer_link_category': {
                await PosDatabase.instance.updatePrinterLinkCategorySyncStatusFromCloud(responseJson[i]['printer_link_category_key']);
              }
              break;
              case 'tb_transfer_owner': {
                await PosDatabase.instance.updateTransferOwnerSyncStatusFromCloud(responseJson[i]['transfer_owner_key']);
              }
              break;
              case 'tb_checklist': {
                await PosDatabase.instance.updateChecklistSyncStatusFromCloud(responseJson[i]['checklist_key']);
              }
              break;
              case 'tb_kitchen_list': {
                await PosDatabase.instance.updateKitchenListSyncStatusFromCloud(responseJson[i]['kitchen_list_key']);
              }
              break;
              case 'tb_attendance': {
                await PosDatabase.instance.updateAttendanceSyncStatusFromCloud(responseJson[i]['attendance_key']);
              }
              break;
              case 'tb_order_payment_split': {
                await PosDatabase.instance.updateOrderPaymentSplitSyncStatusFromCloud(responseJson[i]['order_payment_split_key']);
              }
              break;
              case 'tb_dynamic_qr': {
                await PosDatabase.instance.updateDynamicQrSyncStatusFromCloud(responseJson[i]['dynamic_qr_key']);
              }break;
              case 'tb_cancel_receipt': {
                await PosDatabase.instance.updateCancelReceiptSyncStatusFromCloud(responseJson[i]['cancel_receipt_key']);
              }break;
              case 'tb_product': {
                await PosDatabase.instance.updateProductSyncStatusFromCloud(responseJson[i]['product_id']);
              }break;
              case 'tb_ingredient_movement': {
                await PosDatabase.instance.updateIngredientMovementSyncStatusFromCloud(responseJson[i]['ingredient_movement_key']);
              }
              break;
              case 'tb_sales_per_day': {
                await PosDatabase.instance.updateSalesPerDaySyncStatusFromCloud(responseJson[i]['date']);
              }
              break;
              case 'tb_sales_category_per_day': {
                await PosDatabase.instance.updateSalesCategoryPerDaySyncStatusFromCloud(responseJson[i]['date'], responseJson[i]['category_id']);
              }
              break;
              case 'tb_sales_product_per_day': {
                await PosDatabase.instance.updateSalesProductPerDaySyncStatusFromCloud(responseJson[i]['date'], responseJson[i]['product_id'], responseJson[i]['sales_product_per_day_sqlite_id']);
              }
              break;
              case 'tb_sales_modifier_per_day': {
                await PosDatabase.instance.updateSalesModifierPerDaySyncStatusFromCloud(responseJson[i]['date'], responseJson[i]['mod_item_id']);
              }
              break;
              case 'tb_sales_dining_per_day': {
                await PosDatabase.instance.updateSalesDiningPerDaySyncStatusFromCloud(responseJson[i]['date']);
              }
              break;
            }
          }
          print("Step 3: update sync status finished at ${DateTime.now()}, take ${DateTime.now().difference(updateSyncStatusStart).inSeconds} seconds");
        } else {
          emptyResponse = true;
        }
        status = 0;
      } else if (data['status'] == '7'){
        //multi login detected
        emptyResponse = true;
        status = 1;
      } else if (data['status'] == '8'){
        //error catch
        emptyResponse = true;
        status = 2;
      } else {
        //status 2, no data sync
        emptyResponse = true;
      }
    }catch(e){
      emptyResponse = true;
      status = 2;
      print("sync to cloud error: ${e}");
      FLog.error(
        className: "sync_to_cloud",
        text: "sync to cloud error",
        exception: e,
      );
    }
    return status;
  }

  resetValue(){
    table_use_value = [].toString();
    table_use_detail_value = [].toString();
    order_cache_value = [].toString();
    order_detail_value = [].toString();
    order_detail_cancel_value = [].toString();
    order_modifier_detail_value = [].toString();
    order_value = [].toString();
    order_promotion_value = [].toString();
    order_tax_value = [].toString();
    receipt_value = [].toString();
    refund_value = [].toString();
    table_value = [].toString();
    settlement_value = [].toString();
    settlement_link_payment_value = [].toString();
    cash_record_value = [].toString();
    app_setting_value = [].toString();
    branch_link_product_value = [].toString();
    printer_value = [].toString();
    printer_link_category_value = [].toString();
    transfer_owner_value = [].toString();
    checklist_value = [].toString();
    kitchen_list_value = [].toString();
    attendance_value = [].toString();
    dynamic_qr_value = [].toString();
    order_payment_split_value = [].toString();
    cancel_receipt_value = [].toString();
    product_value = [].toString();
    ingredient_movement_value = [].toString();
    sales_per_day_value = [].toString();
    sales_category_per_day_value = [].toString();
    sales_product_per_day_value = [].toString();
    sales_modifier_per_day_value = [].toString();
    sales_dining_per_day_value = [].toString();
  }

  getAllValue() async {
    resetValue();
    if(isPaused){
      print("sync to cloud paused");
      emptyResponse = true;
      return;
    }
    await getNotSyncChecklist();
    if(checklist_value != '[]' && isNewSync){
      return;
    }
    await getNotSyncKitchenList();
    if(kitchen_list_value != '[]' && isNewSync){
      return;
    }
    await getNotSyncReceipt();
    if(receipt_value != '[]' && isNewSync){
      return;
    }
    await getNotSyncAttendance();
    if(attendance_value != '[]' && isNewSync){
      return;
    }
    await getNotSyncBranchLinkProduct();
    if(branch_link_product_value != '[]' && isNewSync){
      return;
    }
    await getNotSyncCashRecord();
    if(cash_record_value != '[]' && isNewSync){
      return;
    }
    await getNotSyncAppSetting();
    if(app_setting_value != '[]' && isNewSync){
      return;
    }
    await getNotSyncOrder();
    if(order_value != '[]' && isNewSync){
      return;
    }
    await getNotSyncOrderCache();
    if(order_cache_value != '[]' && isNewSync){
      return;
    }
    await getNotSyncOrderDetail();
    if(order_detail_value != '[]' && isNewSync){
      return;
    }
    await getNotSyncOrderDetailCancel();
    if(order_detail_cancel_value != '[]' && isNewSync){
      return;
    }
    await getNotSyncOrderModifierDetail();
    if(order_modifier_detail_value != '[]' && isNewSync){
      return;
    }
    await getNotSyncOrderPaymentSplit();
    if(order_payment_split_value != '[]' && isNewSync){
      return;
    }
    await getNotSyncOrderPromotionDetail();
    if(order_promotion_value != '[]' && isNewSync){
      return;
    }
    await getNotSyncOrderTaxDetail();
    if(order_tax_value != '[]' && isNewSync){
      return;
    }
    await getNotSyncPrinter();
    if(printer_value != '[]' && isNewSync){
      return;
    }
    await getNotSyncPrinterLinkCategory();
    if(printer_link_category_value != '[]' && isNewSync){
      return;
    }
    await getNotSyncRefund();
    if(refund_value != '[]' && isNewSync){
      return;
    }
    await getNotSyncSettlement();
    if(settlement_value != '[]' && isNewSync){
      return;
    }
    await getNotSyncSettlementLinkPayment();
    if(settlement_link_payment_value != '[]' && isNewSync){
      return;
    }
    await getNotSyncTableUse();
    if(table_use_value != '[]' && isNewSync){
      return;
    }
    await getNotSyncTableUseDetail();
    if(table_use_detail_value != '[]' && isNewSync){
      return;
    }
    await getNotSyncTable();
    if(table_value != '[]' && isNewSync){
      return;
    }
    await getNotSyncTransfer();
    if(transfer_owner_value != '[]' && isNewSync){
      return;
    }
    await getNotSyncDynamicQr();
    if(dynamic_qr_value != '[]' && isNewSync){
      return;
    }
    await getNotSyncCancelReceipt();
    if(cancel_receipt_value != '[]' && isNewSync){
      return;
    }
    await getNotSyncProduct();
    if(product_value != '[]' && isNewSync){
      return;
    }
    await getNotSyncIngredientMovement();
    if(ingredient_movement_value != '[]' && isNewSync){
      return;
    }
    await getNotSyncSalesPerDay();
    if(sales_per_day_value != '[]' && isNewSync){
      return;
    }
    await getNotSyncSalesCategoryPerDay();
    if(sales_category_per_day_value != '[]' && isNewSync){
      return;
    }
    await getNotSyncSalesProductPerDay();
    if(sales_product_per_day_value != '[]' && isNewSync){
      return;
    }
    await getNotSyncSalesModifierPerDay();
    if(sales_modifier_per_day_value != '[]' && isNewSync){
      return;
    }
    await getNotSyncSalesDiningPerDay();

  }

  getNotSyncSalesDiningPerDay() async {
    List<String> _value = [];
    try{
      List<SalesDiningPerDay> data = await PosDatabase.instance.readAllNotSyncSalesDiningPerDay(dataSelectLimit);
      if(data.isNotEmpty){
        for(int i = 0; i < data.length; i++){
          _value.add(jsonEncode(data[i]));
        }
        sales_dining_per_day_value = _value.toString();
        print("sales_dining_per_day_value: ${sales_dining_per_day_value}");
      }
    } catch(e, stackTrace){
      FLog.error(
        className: "sync_to_cloud",
        text: "getNotSyncSalesDiningPerDay error",
        exception: 'Error: $e, StackTrace: $stackTrace',
      );
      sales_dining_per_day_value = null;
    }
  }

  getNotSyncSalesModifierPerDay() async {
    List<String> _value = [];
    try{
      List<SalesModifierPerDay> data = await PosDatabase.instance.readAllNotSyncSalesModifierPerDay(dataSelectLimit);
      if(data.isNotEmpty){
        for(int i = 0; i < data.length; i++){
          _value.add(jsonEncode(data[i]));
        }
        sales_modifier_per_day_value = _value.toString();
        print("sales_modifier_per_day_value: ${sales_modifier_per_day_value}");
      }
    } catch(e, stackTrace){
      FLog.error(
        className: "sync_to_cloud",
        text: "getNotSyncSalesModifierPerDay error",
        exception: 'Error: $e, StackTrace: $stackTrace',
      );
      sales_modifier_per_day_value = null;
    }
  }

  getNotSyncSalesProductPerDay() async {
    List<String> _value = [];
    try{
      List<SalesProductPerDay> data = await PosDatabase.instance.readAllNotSyncSalesProductPerDay(dataSelectLimit);
      if(data.isNotEmpty){
        for(int i = 0; i < data.length; i++){
          _value.add(jsonEncode(data[i]));
        }
        sales_product_per_day_value = _value.toString();
        print("sales_product_per_day_value: ${sales_product_per_day_value}");
      }
    } catch(e, stackTrace){
      FLog.error(
        className: "sync_to_cloud",
        text: "getNotSyncSalesProductPerDay error",
        exception: 'Error: $e, StackTrace: $stackTrace',
      );
      sales_product_per_day_value = null;
    }
  }

  getNotSyncSalesCategoryPerDay() async {
    List<String> _value = [];
    try{
      List<SalesCategoryPerDay> data = await PosDatabase.instance.readAllNotSyncSalesCategoryPerDay(dataSelectLimit);
      if(data.isNotEmpty){
        for(int i = 0; i < data.length; i++){
          _value.add(jsonEncode(data[i]));
        }
        sales_category_per_day_value = _value.toString();
        print("sales_category_per_day_value: ${sales_category_per_day_value}");
      }
    } catch(e, stackTrace){
      FLog.error(
        className: "sync_to_cloud",
        text: "getNotSyncSalesCategoryPerDay error",
        exception: 'Error: $e, StackTrace: $stackTrace',
      );
      sales_category_per_day_value = null;
    }
  }

  getNotSyncSalesPerDay() async {
    List<String> _value = [];
    try{
      List<SalesPerDay> data = await PosDatabase.instance.readAllNotSyncSalesPerDay(dataSelectLimit);
      if(data.isNotEmpty){
        for(int i = 0; i < data.length; i++){
          _value.add(jsonEncode(data[i]));
        }
        sales_per_day_value = _value.toString();
        print("sales_per_day_value: ${sales_per_day_value}");
      }
    } catch(e, stackTrace){
      FLog.error(
        className: "sync_to_cloud",
        text: "getNotSyncSalesPerDay error",
        exception: 'Error: $e, StackTrace: $stackTrace',
      );
      sales_per_day_value = null;
    }
  }

  getNotSyncCancelReceipt() async {
    List<String> _value = [];
    try{
      List<CancelReceipt> data = await PosDatabase.instance.readAllNotSyncCancelReceipt(dataSelectLimit);
      if(data.isNotEmpty){
        for(int i = 0; i < data.length; i++){
          _value.add(jsonEncode(data[i]));
        }
        cancel_receipt_value = _value.toString();
        print("cancel_receipt_value: ${cancel_receipt_value}");
      }
    } catch(e, stackTrace){
      FLog.error(
        className: "sync_to_cloud",
        text: "dynamic qr sync to cloud error",
        exception: 'Error: $e, StackTrace: $stackTrace',
      );
      cancel_receipt_value = null;
    }
  }

  getNotSyncDynamicQr() async {
    List<String> _value = [];
    try{
      List<DynamicQR> data = await PosDatabase.instance.readAllNotSyncDynamicQr(dataSelectLimit);
      if(data.isNotEmpty){
        for(int i = 0; i < data.length; i++){
          _value.add(jsonEncode(data[i]));
        }
        dynamic_qr_value = _value.toString();
      }
    } catch(e){
      print('sync dynamic qr to cloud error: $e');
      FLog.error(
        className: "sync_to_cloud",
        text: "dynamic qr sync to cloud error",
        exception: e,
      );
      dynamic_qr_value = null;
    }
  }

  getNotSyncChecklist() async {
    List<String> _value = [];
    try{
      List<Checklist> data = await PosDatabase.instance.readAllNotSyncChecklist(dataSelectLimit);
      if(data.isNotEmpty){
        for(int i = 0; i < data.length; i++){
          _value.add(jsonEncode(data[i]));
        }
        checklist_value = _value.toString();
      }
    } catch(e){
      print('15 checklist error: $e');
      FLog.error(
        className: "sync_to_cloud",
        text: "checklist sync to cloud error",
        exception: e,
      );
      checklist_value = null;
    }
  }

  getNotSyncKitchenList() async {
    List<String> _value = [];
    try{
      List<KitchenList> data = await PosDatabase.instance.readAllNotSyncKitchenList(dataSelectLimit);
      if(data.isNotEmpty){
        for(int i = 0; i < data.length; i++){
          _value.add(jsonEncode(data[i]));
        }
        kitchen_list_value = _value.toString();
      }
    } catch(e){
      print('15 kitchen_list error: $e');
      FLog.error(
        className: "sync_to_cloud",
        text: "kitchen list sync to cloud error",
        exception: e,
      );
      kitchen_list_value = null;
    }
  }

  getNotSyncAttendance() async {
    List<String> _value = [];
    try{
      List<Attendance> data = await PosDatabase.instance.readAllNotSyncAttendance(dataSelectLimit);
      if(data.isNotEmpty){
        for(int i = 0; i < data.length; i++){
          _value.add(jsonEncode(data[i]));
        }
        attendance_value = _value.toString();
      }
    } catch(e){
      print('15 attendance error: $e');
      FLog.error(
        className: "sync_to_cloud",
        text: "attendance sync to cloud error",
        exception: e,
      );
      attendance_value = null;
    }
  }

  getNotSyncReceipt() async {
    try{
      List<String> _value = [];
      List<Receipt> data = await PosDatabase.instance.readAllNotSyncReceipt(dataSelectLimit);
      if(data.isNotEmpty){
        for(int i = 0; i < data.length; i++){
          _value.add(jsonEncode(data[i]));
        }
        this.receipt_value = _value.toString();
      }
      //print('receipt value: ${receipt_value}');
    } catch(error){
      print('15 receipt error: ${error}');
      FLog.error(
        className: "sync_to_cloud",
        text: "receipt sync to cloud error",
        exception: error,
      );
      return;
    }
  }


/*
  ----------------------Printer part----------------------------------------------------------------------------------------------------------------------------
*/

  getNotSyncPrinterLinkCategory() async {
    try{
      List<String> _value = [];
      List<PrinterLinkCategory> data = await PosDatabase.instance.readAllNotSyncPrinterLinkCategory(dataSelectLimit);
      notSyncPrinterCategoryList = data;
      if(notSyncPrinterCategoryList.isNotEmpty){
        for(int i = 0; i < notSyncPrinterCategoryList.length; i++){
          _value.add(jsonEncode(notSyncPrinterCategoryList[i]));
        }
        this.printer_link_category_value = _value.toString();
        print('value: ${printer_link_category_value}');
      }
    }catch(error){
      print('15 printer category error: ${error}');
      FLog.error(
        className: "sync_to_cloud",
        text: "printer category sync to cloud error",
        exception: error,
      );
      return;
    }
  }

  getNotSyncPrinter() async {
    try{
      List<String> _value = [];
      List<Printer> data = await PosDatabase.instance.readAllNotSyncLANPrinter();
      notSyncPrinterList = data;
      print('printer list: ${notSyncPrinterList.length}');
      if(notSyncPrinterList.isNotEmpty){
        for(int i = 0; i < notSyncPrinterList.length; i++){
          _value.add(jsonEncode(notSyncPrinterList[i]));
        }
        this.printer_value = _value.toString();
        print('value: ${printer_value}');
      }
    } catch(error){
      print('15 printer sync error: ${error}');
      FLog.error(
        className: "sync_to_cloud",
        text: "printer sync to cloud error",
        exception: error,
      );
      return;
    }
  }

/*
  ----------------------Branch link product part----------------------------------------------------------------------------------------------------------------------------
*/
  // branchLinkProductSyncToCloud() async {
  //   List<String> value = [];
  //   await getNotSyncBranchLinkProduct();
  //   if(notSyncBranchLinkProductList.isNotEmpty){
  //     for(int i = 0; i < notSyncBranchLinkProductList.length; i++){
  //       value.add(jsonEncode(notSyncBranchLinkProductList[i]));
  //     }
  //   }
  //   //sync to cloud
  //   syncBranchLinkProductStock(value.toString());
  // }


  // syncBranchLinkProductStock(String value) async {
  //   bool _hasInternetAccess = await Domain().isHostReachable();
  //   if(_hasInternetAccess) {
  //     Map orderDetailResponse = await Domain().SyncBranchLinkProductToCloud(value);
  //     if (orderDetailResponse['status'] == '1') {
  //       List responseJson = orderDetailResponse['data'];
  //       for (int i = 0; i < responseJson.length; i++) {
  //         int syncUpdated = await PosDatabase.instance.updateBranchLinkProductSyncStatusFromCloud(responseJson[i]['branch_link_product_id']);
  //       }
  //     }
  //   }
  // }

  getNotSyncBranchLinkProduct() async {
    try{
      List<String> _value = [];
      List<BranchLinkProduct> data = await PosDatabase.instance.readAllNotSyncBranchLinkProduct(dataSelectLimit);
      notSyncBranchLinkProductList = data;
      if(notSyncBranchLinkProductList.isNotEmpty){
        for(int i = 0; i < notSyncBranchLinkProductList.length; i++){
          _value.add(jsonEncode(notSyncBranchLinkProductList[i]));
        }
        this.branch_link_product_value = _value.toString();
      }
    } catch(error){
      print('15 branch link product sync error: ${error}');
      FLog.error(
        className: "sync_to_cloud",
        text: "branch link product sync to cloud error",
        exception: error,
      );
      return;
    }
  }

/*
  ----------------------Settlement link payment part----------------------------------------------------------------------------------------------------------------------------
*/
  // settlementLinkPaymentSyncToCloud() async {
  //   List<String> value = [];
  //   await getNotSyncSettlementLinkPayment();
  //   if(notSyncSettlementLinkPaymentList.isNotEmpty){
  //     for(int i = 0; i < notSyncSettlementLinkPaymentList.length; i++){
  //       value.add(jsonEncode(notSyncSettlementLinkPaymentList[i]));
  //     }
  //   }
  //   //sync to cloud
  //   syncSettlementLinkPaymentToCloud(value.toString());
  // }
  //
  // syncSettlementLinkPaymentToCloud(String value) async {
  //   bool _hasInternetAccess = await Domain().isHostReachable();
  //   if (_hasInternetAccess) {
  //     Map settlementResponse = await Domain().SyncSettlementLinkPaymentToCloud(value);
  //     if (settlementResponse['status'] == '1') {
  //       List responseJson = settlementResponse['data'];
  //       for (int i = 0; i < responseJson.length; i++) {
  //         int syncUpdated = await PosDatabase.instance.updateSettlementLinkPaymentSyncStatusFromCloud(responseJson[i]['settlement_link_payment_key']);
  //       }
  //     }
  //   }
  // }

  getNotSyncSettlementLinkPayment() async {
    try{
      List<String> _value = [];
      List<SettlementLinkPayment> data = await PosDatabase.instance.readAllNotSyncSettlementLinkPayment(dataSelectLimit);
      notSyncSettlementLinkPaymentList = data;
      if(notSyncSettlementLinkPaymentList.isNotEmpty){
        for(int i = 0; i < notSyncSettlementLinkPaymentList.length; i++){
          _value.add(jsonEncode(notSyncSettlementLinkPaymentList[i]));
        }
        this.settlement_link_payment_value = _value.toString();
      }
    }catch(error){
      print('15 settlement payment sync error: ${error}');
      FLog.error(
        className: "sync_to_cloud",
        text: "settlement payment sync to cloud error",
        exception: error,
      );
      return;
    }
  }

/*
  ----------------------Settlement part-------------------------------------------------------------------------------------------------------------------------------------------------
*/

  // settlementSyncToCloud() async {
  //   List<String> value = [];
  //   await getNotSyncSettlement();
  //   if(notSyncSettlementList.isNotEmpty){
  //     for(int i = 0; i < notSyncSettlementList.length; i++){
  //       value.add(jsonEncode(notSyncSettlementList[i]));
  //     }
  //   }
  //   //sync to cloud
  //   syncSettlementToCloud(value.toString());
  // }
  // syncSettlementToCloud(String value) async {
  //   bool _hasInternetAccess = await Domain().isHostReachable();
  //   if (_hasInternetAccess) {
  //     Map settlementResponse = await Domain().SyncSettlementToCloud(value);
  //     if (settlementResponse['status'] == '1') {
  //       List responseJson = settlementResponse['data'];
  //       for (int i = 0; i < responseJson.length; i++) {
  //         int syncUpdated = await PosDatabase.instance.updateSettlementSyncStatusFromCloud(responseJson[i]['settlement_key']);
  //       }
  //     }
  //   }
  // }

  getNotSyncSettlement() async {
    try{
      List<String> _value = [];
      List<Settlement> data = await PosDatabase.instance.readAllNotSyncSettlement(dataSelectLimit);
      notSyncSettlementList = data;
      if(notSyncSettlementList.isNotEmpty){
        for(int i = 0; i < notSyncSettlementList.length; i++){
          _value.add(jsonEncode(notSyncSettlementList[i]));
        }
        this.settlement_value = _value.toString();
      }
    }catch(error){
      print('15 settlement sync error: ${error}');
      FLog.error(
        className: "sync_to_cloud",
        text: "settlement sync to cloud error",
        exception: error,
      );
      return;
    }
  }

/*
  ----------------------Transfer owner part----------------------------------------------------------------------------------------------------------------------------
*/

  // transferOwnerSyncToCloud() async {
  //   List<String> value = [];
  //   await getNotSyncTransfer();
  //   if(notSyncTransferOwnerList.isNotEmpty){
  //     for(int i = 0; i < notSyncTransferOwnerList.length; i++){
  //       value.add(jsonEncode(notSyncTransferOwnerList[i]));
  //     }
  //     //sync to cloud
  //     syncTransferOwnerToCloud(value.toString());
  //   }
  // }
  //
  // syncTransferOwnerToCloud(String value) async {
  //   //check is host reachable
  //   bool _hasInternetAccess = await Domain().isHostReachable();
  //   if(_hasInternetAccess){
  //     Map response = await Domain().SyncTransferOwnerToCloud(value);
  //     if (response['status'] == '1') {
  //       List responseJson = response['data'];
  //       for (int i = 0; i < responseJson.length; i++) {
  //         int updateStatus = await PosDatabase.instance.updateTransferOwnerSyncStatusFromCloud(
  //             responseJson[i]['transfer_owner_key']);
  //       }
  //     }
  //   }
  // }

  getNotSyncTransfer() async {
    try{
      List<String> _value = [];
      List<TransferOwner> data = await PosDatabase.instance.readAllNotSyncTransferOwner(dataSelectLimit);
      notSyncTransferOwnerList = data;
      if(notSyncTransferOwnerList.isNotEmpty){
        for(int i = 0; i < notSyncTransferOwnerList.length; i++){
          _value.add(jsonEncode(notSyncTransferOwnerList[i]));
        }
        this.transfer_owner_value = _value.toString();
      }
    }catch(error){
      print('15 transfer owner sync error: ${error}');
      FLog.error(
        className: "sync_to_cloud",
        text: "transfer owner sync to cloud error",
        exception: error,
      );
      return;
    }
  }


/*
  ----------------------Refund part----------------------------------------------------------------------------------------------------------------------------
*/

  // refundSyncToCloud() async {
  //   List<String> value = [];
  //   await getNotSyncRefund();
  //   if(notSyncRefundList.isNotEmpty){
  //     for(int i = 0; i <  notSyncRefundList.length; i++){
  //       value.add(jsonEncode(notSyncRefundList[i]));
  //     }
  //     //sync to cloud
  //     syncRefundToCloud(value.toString());
  //   }
  //
  // }
  //
  // syncRefundToCloud(String value) async {
  //   //check is host reachable
  //   bool _hasInternetAccess = await Domain().isHostReachable();
  //   if (_hasInternetAccess) {
  //     Map response = await Domain().SyncRefundToCloud(value);
  //     if (response['status'] == '1') {
  //       List responseJson = response['data'];
  //       int updateStatus = await PosDatabase.instance.updateRefundSyncStatusFromCloud(responseJson[0]['refund_key']);
  //     }
  //   }
  // }

  getNotSyncRefund() async {
    try{
      List<String> _value = [];
      List<Refund> data = await PosDatabase.instance.readAllNotSyncRefund(dataSelectLimit);
      notSyncRefundList = data;
      if(notSyncRefundList.isNotEmpty){
        for(int i = 0; i <  notSyncRefundList.length; i++){
          _value.add(jsonEncode(notSyncRefundList[i]));
        }
        this.refund_value = _value.toString();
      }
    } catch(error){
      print('15 refund sync error: ${error}');
      FLog.error(
        className: "sync_to_cloud",
        text: "refund sync to cloud error",
        exception: error,
      );
      return;
    }
  }

/*
  ----------------------Cash record part----------------------------------------------------------------------------------------------------------------------------
*/
  updatedCashRecordSyncToCloud() async {
    List<String> value = [];
    await getNotSyncUpdatedCashRecord();
    if(notSyncCashRecordList.isNotEmpty){
      for(int i = 0; i <  notSyncCashRecordList.length; i++){
        value.add(jsonEncode(notSyncCashRecordList[i]));
      }
      //sync to cloud
      Map data = await Domain().SyncUpdatedCashRecordToCloud(value.toString());
      if (data['status'] == '1') {
        List responseJson = data['data'];
        for (var i = 0; i < responseJson.length; i++) {
          int orderPromoData = await PosDatabase.instance.updateCashRecordSyncStatusFromCloud(responseJson[i]['cash_record_key']);
        }
      }
    }
  }

  cashRecordSyncToCloud() async {
    List<String> value = [];
    await getNotSyncCashRecord();
    if(notSyncCashRecordList.isNotEmpty) {
      for(int i = 0; i < notSyncCashRecordList.length; i++){
        value.add(jsonEncode(notSyncCashRecordList[i]));
      }
      //sync to cloud
      Map data = await Domain().SyncCashRecordToCloud(value.toString());
      if (data['status'] == '1') {
        List responseJson = data['data'];
        for (var i = 0; i < responseJson.length; i++) {
          int orderPromoData = await PosDatabase.instance.updateCashRecordSyncStatusFromCloud(responseJson[i]['cash_record_key']);
        }
      }
    }
  }

  getNotSyncUpdatedCashRecord() async {
    List<CashRecord> data = await PosDatabase.instance.readAllNotSyncUpdatedCashRecord();
    notSyncCashRecordList = data;
  }

  getNotSyncCashRecord() async {
    try{
      List<String> _value = [];
      List<CashRecord> data = await PosDatabase.instance.readAllNotSyncCashRecord(dataSelectLimit);
      notSyncCashRecordList = data;
      if(notSyncCashRecordList.isNotEmpty) {
        for(int i = 0; i < notSyncCashRecordList.length; i++){
          _value.add(jsonEncode(notSyncCashRecordList[i]));
        }
        this.cash_record_value = _value.toString();
      }
    }catch(error){
      print('15 cash record sync error: ${error}');
      FLog.error(
        className: "sync_to_cloud",
        text: "cash record sync to cloud error",
        exception: error,
      );
      return;
    }
  }

  /*
  ----------------------App setting part----------------------------------------------------------------------------------------------------------------------------
*/

  getNotSyncAppSetting() async {
    try{
      List<String> _value = [];
      List<AppSetting> data = await PosDatabase.instance.readAllNotSyncAppSetting();
      notSyncAppSettingList = data;
      if(notSyncAppSettingList.isNotEmpty) {
        for(int i = 0; i < notSyncAppSettingList.length; i++){
          if(notSyncAppSettingList[i].branch_id != '' && notSyncAppSettingList[i].created_at != ''){
            _value.add(jsonEncode(notSyncAppSettingList[i])); 
          } else {
            AppSetting? updateData = await updateFirstSyncAppSetting(appSetting: notSyncAppSettingList[i]);
            if(updateData != null){
              _value.add(jsonEncode(updateData));
            }
          }
        }
        this.app_setting_value = _value.toString();
        print("app_setting_value: ${app_setting_value}");
      }
    }catch(error){
      print('15 app setting sync error: ${error}');
      FLog.error(
        className: "sync_to_cloud",
        text: "app setting sync to cloud error",
        exception: error,
      );
      return;
    }
  }
  
  updateFirstSyncAppSetting({required AppSetting appSetting}) async {
    DateFormat dateFormat = DateFormat("yyyy-MM-dd HH:mm:ss");
    String dateTime = dateFormat.format(DateTime.now());
    final prefs = await SharedPreferences.getInstance();
    AppSetting data = AppSetting(
      created_at: dateTime,
      branch_id: prefs.getInt("branch_id").toString(),
      app_setting_sqlite_id: appSetting.app_setting_sqlite_id
    );
    int status = await PosDatabase.instance.updateFirstSyncAppSettings(data);
    //return updated data
    if(status == 1){
      AppSetting? returnData = await PosDatabase.instance.readSpecificAppSetting(data.app_setting_sqlite_id!);
      return returnData;
    } else {
      return null;
    }
  }

/*
  ----------------------Pos table part----------------------------------------------------------------------------------------------------------------------------
*/
  // updatedPosTableSyncToCloud() async {
  //   List<String> value = [];
  //   await getNotSyncUpdatedTable();
  //   if(notSyncPosTableList.isNotEmpty){
  //     for (int i = 0; i < notSyncPosTableList.length; i++) {
  //       value.add(jsonEncode(notSyncPosTableList[i]));
  //     }
  //     //sync to cloud
  //     Map data = await Domain().SyncUpdatedPosTableToCloud(value.toString());
  //     if (data['status'] == '1') {
  //       List responseJson = data['data'];
  //       for (var i = 0; i < responseJson.length; i++) {
  //         int tableData = await PosDatabase.instance.updatePosTableSyncStatusFromCloud(responseJson[i]['table_id']);
  //       }
  //     }
  //   }
  // }

  getNotSyncTable() async {
    try{
      List<String> _value = [];
      List<PosTable> data = await PosDatabase.instance.readAllNotSyncUpdatedPosTable(dataSelectLimit);
      notSyncPosTableList = data;
      if(notSyncPosTableList.isNotEmpty){
        for (int i = 0; i < notSyncPosTableList.length; i++) {
          _value.add(jsonEncode(notSyncPosTableList[i]));
        }
        this.table_value = _value.toString();
      }
    }catch(error){
      print('15 table sync error: ${error}');
      FLog.error(
        className: "sync_to_cloud",
        text: "table sync to cloud error",
        exception: error,
      );
      return;
    }
  }

  getNotSyncProduct() async {
    try{
      List<String> _value = [];
      List<Product> data = await PosDatabase.instance.readAllNotSyncUpdatedProduct(dataSelectLimit);
      notSyncProductList = data;
      if(notSyncProductList.isNotEmpty){
        for (int i = 0; i < notSyncProductList.length; i++) {
          _value.add(jsonEncode(notSyncProductList[i]));
        }
        this.product_value = _value.toString();
      }
    }catch(error){
      print('15 table sync error: ${error}');
      FLog.error(
        className: "sync_to_cloud",
        text: "table sync to cloud error",
        exception: error,
      );
      return;
    }
  }

  getNotSyncIngredientMovement() async {
    try{
      List<String> _value = [];
      List<IngredientMovement> data = await PosDatabase.instance.readAllNotSyncUpdatedIngredientMovement(dataSelectLimit);
      notSyncIngredientMovementList = data;
      if(notSyncIngredientMovementList.isNotEmpty){
        for (int i = 0; i < notSyncIngredientMovementList.length; i++) {
          _value.add(jsonEncode(notSyncIngredientMovementList[i]));
        }
        this.ingredient_movement_value = _value.toString();
      }
    }catch(error){
      print('getNotSyncIngredientMovement error: ${error}');
      FLog.error(
        className: "sync_to_cloud",
        text: "getNotSyncIngredientMovement error",
        exception: error,
      );
      return;
    }
  }
/*
  ----------------------Order Tax detail part----------------------------------------------------------------------------------------------------------------------------
*/

  updatedOrderPromotionDetailSyncToCloud() async {
    List<String> value = [];
    await getNotSyncUpdatedOrderPromotionDetail();
    if(notSyncOrderTaxDetailList.isNotEmpty){
      for(int i = 0; i <  notSyncOrderTaxDetailList.length; i++){
        value.add(jsonEncode(notSyncOrderTaxDetailList[i]));
      }
      //sync to cloud
      Map data = await Domain().SyncUpdatedOrderPromotionDetailToCloud(value.toString());
      if (data['status'] == '1') {
        List responseJson = data['data'];
        for (var i = 0; i < responseJson.length; i++) {
          int orderPromoData = await PosDatabase.instance.updateOrderPromotionDetailSyncStatusFromCloud(responseJson[i]['order_promotion_detail_key']);
        }
      }
    }
  }

  orderPromotionDetailSyncToCloud() async {
    List<String> value = [];
    await getNotSyncOrderPromotionDetail();
    if(notSyncOrderPromotionDetailList.isNotEmpty){
      for(int i = 0; i <  notSyncOrderPromotionDetailList.length; i++){
        value.add(jsonEncode(notSyncOrderPromotionDetailList[i]));
      }
      //sync to cloud
      Map data = await Domain().SyncOrderPromotionDetailToCloud(value.toString());
      if (data['status'] == '1') {
        List responseJson = data['data'];
        for (var i = 0; i < responseJson.length; i++) {
          int orderPromoData = await PosDatabase.instance.updateOrderPromotionDetailSyncStatusFromCloud(responseJson[i]['order_promotion_detail_key']);
        }
      }
    }
  }

  getNotSyncUpdatedOrderPromotionDetail() async {
    List<OrderPromotionDetail> data = await PosDatabase.instance.readAllNotSyncUpdatedOrderPromotionDetail();
    notSyncOrderPromotionDetailList = data;
  }

  getNotSyncOrderPromotionDetail() async {
    try{
      List<String> _value = [];
      List<OrderPromotionDetail> data = await PosDatabase.instance.readAllNotSyncOrderPromotionDetail(dataSelectLimit);
      notSyncOrderPromotionDetailList = data;
      if(notSyncOrderPromotionDetailList.isNotEmpty){
        for(int i = 0; i <  notSyncOrderPromotionDetailList.length; i++){
          _value.add(jsonEncode(notSyncOrderPromotionDetailList[i]));
        }
        this.order_promotion_value = _value.toString();
      }
    }catch(error){
      print('15 order promotion sync error: ${error}');
      FLog.error(
        className: "sync_to_cloud",
        text: "order promotion sync to cloud error",
        exception: error,
      );
      return;
    }
  }

/*
  ----------------------Order Tax detail part----------------------------------------------------------------------------------------------------------------------------
*/
  updatedOrderTaxDetailSyncToCloud() async {
    List<String> value = [];
    await getNotSyncUpdatedOrderTaxDetail();
    if(notSyncOrderTaxDetailList.isNotEmpty){
      for(int i = 0; i <  notSyncOrderTaxDetailList.length; i++){
        value.add(jsonEncode(notSyncOrderTaxDetailList[i]));
      }
      //sync to cloud
      Map data = await Domain().SyncUpdatedOrderTaxDetailToCloud(value.toString());
      if (data['status'] == '1') {
        List responseJson = data['data'];
        for (var i = 0; i < responseJson.length; i++) {
          int orderData = await PosDatabase.instance.updateOrderTaxDetailSyncStatusFromCloud(responseJson[i]['order_tax_detail_key']);
        }
      }
    }
  }

  orderTaxDetailSyncToCloud() async {
    List<String> value = [];
    await getNotSyncOrderTaxDetail();
    if(notSyncOrderTaxDetailList.isNotEmpty){
      for(int i = 0; i <  notSyncOrderTaxDetailList.length; i++){
        value.add(jsonEncode(notSyncOrderTaxDetailList[i]));
      }
      //sync to cloud
      Map data = await Domain().SyncOrderTaxDetailToCloud(value.toString());
      if (data['status'] == '1') {
        List responseJson = data['data'];
        for (var i = 0; i < responseJson.length; i++) {
          int orderData = await PosDatabase.instance.updateOrderTaxDetailSyncStatusFromCloud(responseJson[i]['order_tax_detail_key']);
        }
      }
    }
  }

  getNotSyncUpdatedOrderTaxDetail() async {
    List<OrderTaxDetail> data = await PosDatabase.instance.readAllNotSyncUpdatedOrderTaxDetail();
    notSyncOrderTaxDetailList = data;
  }

  getNotSyncOrderTaxDetail() async {
    try{
      List<String> _value = [];
      List<OrderTaxDetail> data = await PosDatabase.instance.readAllNotSyncOrderTaxDetail(dataSelectLimit);
      notSyncOrderTaxDetailList = data;
      if(notSyncOrderTaxDetailList.isNotEmpty){
        for(int i = 0; i <  notSyncOrderTaxDetailList.length; i++){
          _value.add(jsonEncode(notSyncOrderTaxDetailList[i]));
        }
        this.order_tax_value = _value.toString();
      }
    } catch(error){
      print('15 order tax sync error: ${error}');
      FLog.error(
        className: "sync_to_cloud",
        text: "order tax sync to cloud error",
        exception: error,
      );
      return;
    }
  }

/*
  ----------------------Table use detail part-------------------------------------------------------------------------------------------------------------------------------------
*/
  tableUseDetailSyncToCloud() async {
    List<String> value = [];
    await getNotSyncTableUseDetail();
    if(notSyncTableUseDetailList.isNotEmpty){
      for(int i = 0; i <  notSyncTableUseDetailList.length; i++){
        value.add(jsonEncode(notSyncTableUseDetailList[i]));
      }
      //sync to cloud
      Map data = await Domain().SyncTableUseDetailToCloud(value.toString());
      if (data['status'] == '1') {
        List responseJson = data['data'];
        for (var i = 0; i < responseJson.length; i++) {
          int tablaUseDetailData = await PosDatabase.instance.updateTableUseDetailSyncStatusFromCloud(responseJson[i]['table_use_detail_key']);
        }
      }
    }
  }


  getNotSyncTableUseDetail() async {
    try{
      List<String> _value = [];
      List<TableUseDetail> data = await PosDatabase.instance.readAllNotSyncTableUseDetail(dataSelectLimit);
      notSyncTableUseDetailList = data;
      if(notSyncTableUseDetailList.isNotEmpty){
        for(int i = 0; i <  notSyncTableUseDetailList.length; i++){
          _value.add(jsonEncode(notSyncTableUseDetailList[i]));
        }
        this.table_use_detail_value = _value.toString();
      }
    }catch(error){
      print('15 table use detail error: ${error}');
      FLog.error(
        className: "sync_to_cloud",
        text: "table use detail sync to cloud error",
        exception: error,
      );
      return;
    }
  }

/*
  ----------------------Table use part---------------------------------------------------------------------------------------------------------------------------------------
*/
  tableUseSyncToCloud() async {
    List<String> value = [];
    await getNotSyncTableUse();
    if(notSyncTableUseList.isNotEmpty){
      for(int i = 0; i < notSyncTableUseList.length; i++){
        value.add(jsonEncode(notSyncTableUseList[i]));
      }
      //sync to cloud
      Map data = await Domain().SyncTableUseToCloud(value.toString());
      if (data['status'] == '1') {
        List responseJson = data['data'];
        for (var i = 0; i < responseJson.length; i++) {
          int tablaUseData = await PosDatabase.instance.updateTableUseSyncStatusFromCloud(responseJson[i]['table_use_key']);
        }
      }
    }
  }


  getNotSyncTableUse() async {
    try{
      List<String> _value = [];
      List<TableUse> data = await PosDatabase.instance.readAllNotSyncTableUse(dataSelectLimit);
      notSyncTableUseList = data;
      if(notSyncTableUseList.isNotEmpty){
        for(int i = 0; i < notSyncTableUseList.length; i++){
          _value.add(jsonEncode(notSyncTableUseList[i]));
        }
        this.table_use_value = _value.toString();
      }
    }catch(error){
      print('15 table use sync error: ${error}');
      FLog.error(
        className: "sync_to_cloud",
        text: "table use sync to cloud error",
        exception: error,
      );
      return;
    }
  }

/*
  ----------------------Order modifier detail part-----------------------------------------------------------------------------------------------------------------------------
*/
  updatedOrderModifierDetailSyncToCloud() async {
    List<String> value = [];
    await getNotSyncUpdatedOrderModifierDetail();
    if(notSyncOrderModifierDetailList.isNotEmpty){
      for(int i = 0; i < notSyncOrderModifierDetailList.length; i++){
        value.add(jsonEncode(notSyncOrderModifierDetailList[i]));
      }
      //sync to cloud
      Map data = await Domain().SyncUpdatedOrderModifierDetailToCloud(value.toString());
      if(data['status'] == '1'){
        List responseJson = data['data'];
        for(int i = 0 ; i <responseJson.length; i++){
          int orderCacheData = await PosDatabase.instance.updateOrderModifierDetailSyncStatusFromCloud(responseJson[i]['order_modifier_detail_key']);
        }
      }
    }
  }

  orderModifierDetailSyncToCloud() async {
    List<String> value = [];
    await getNotSyncOrderModifierDetail();
    if(notSyncOrderModifierDetailList.isNotEmpty){
      for(int i = 0; i < notSyncOrderModifierDetailList.length; i++){
        value.add(jsonEncode(notSyncOrderModifierDetailList[i]));
      }
      //sync to cloud
      Map data = await Domain().SyncOrderModifierDetailToCloud(value.toString());
      if(data['status'] == '1'){
        List responseJson = data['data'];
        for(int i = 0 ; i <responseJson.length; i++){
          int orderCacheData = await PosDatabase.instance.updateOrderModifierDetailSyncStatusFromCloud(responseJson[i]['order_modifier_detail_key']);
        }
      }
    }
  }

  getNotSyncUpdatedOrderModifierDetail() async {
    List<OrderModifierDetail> data = await PosDatabase.instance.readAllNotSyncUpdatedOrderModifierDetail();
    notSyncOrderModifierDetailList = data;
  }

  getNotSyncOrderModifierDetail() async {
    try{
      List<String> _value = [];
      List<OrderModifierDetail> data = await PosDatabase.instance.readAllNotSyncOrderModDetail(dataSelectLimit);
      notSyncOrderModifierDetailList = data;
      if(notSyncOrderModifierDetailList.isNotEmpty){
        for(int i = 0; i < notSyncOrderModifierDetailList.length; i++){
          _value.add(jsonEncode(notSyncOrderModifierDetailList[i]));
        }
        this.order_modifier_detail_value = _value.toString();
      }
    } catch(error){
      print('15 order modifier detail sync error: ${error}');
      FLog.error(
        className: "sync_to_cloud",
        text: "order modifier detail sync to cloud error",
        exception: error,
      );
      return;
    }

  }

  getNotSyncOrderPaymentSplit() async {
    List<String> _value = [];
    try{
      List<OrderPaymentSplit> data = await PosDatabase.instance.readAllNotSyncOrderPaymentSplit(dataSelectLimit);
      if(data.isNotEmpty){
        for(int i = 0; i < data.length; i++){
          _value.add(jsonEncode(data[i]));
        }
        order_payment_split_value = _value.toString();
        print("order_payment_split_value: ${order_payment_split_value}");
      }
    } catch(e){
      FLog.error(
        className: "sync_to_cloud",
        text: "order payment split sync to cloud error",
        exception: e,
      );
      order_payment_split_value = null;
    }
  }

/*
  ----------------------Order detail cancel part---------------------------------------------------------------------------------------------------------------------------------------
*/

  // orderDetailCancelSyncToCloud() async {
  //   List<String> jsonValue = [];
  //   await getNotSyncOrderDetailCancel();
  //   if(notSyncOrderDetailCancelList.isNotEmpty){
  //     for(int i = 0; i < notSyncOrderDetailCancelList.length; i++){
  //       jsonValue.add(jsonEncode(notSyncOrderDetailCancelList[i]));
  //     }
  //     //sync to cloud
  //     syncOrderDetailCancelToCloud(jsonValue.toString());
  //   }
  // }
  //
  // syncOrderDetailCancelToCloud(String value) async {
  //   bool _hasInternetAccess = await Domain().isHostReachable();
  //   if (_hasInternetAccess) {
  //     Map response = await Domain().SyncOrderDetailCancelToCloud(value);
  //     if (response['status'] == '1') {
  //       List responseJson = response['data'];
  //       for (var i = 0; i < responseJson.length; i++) {
  //         int data = await PosDatabase.instance.updateOrderDetailCancelSyncStatusFromCloud(responseJson[i]['order_detail_cancel_key']);
  //       }
  //     }
  //   }
  // }


  getNotSyncOrderDetailCancel() async {
    try{
      List<String> _value = [];
      List<OrderDetailCancel> data = await PosDatabase.instance.readAllNotSyncOrderDetailCancel(dataSelectLimit);
      notSyncOrderDetailCancelList = data;
      if(notSyncOrderDetailCancelList.isNotEmpty){
        for(int i = 0; i < notSyncOrderDetailCancelList.length; i++){
          _value.add(jsonEncode(notSyncOrderDetailCancelList[i]));
        }
        this.order_detail_cancel_value = _value.toString();
      }
    } catch(error){
      print('15 order detail cancel error: ${error}');
      FLog.error(
        className: "sync_to_cloud",
        text: "order detail cancel sync to cloud error",
        exception: error,
      );
      return;
    }
  }


/*
  ----------------------Order detail part---------------------------------------------------------------------------------------------------------------------------------------
*/

  updatedOrderDetailSyncToCloud() async {
    List<String> jsonValue = [];
    await getNotSyncUpdatedOrderDetail();
    if(notSyncOrderDetailList.isNotEmpty){
      for(int i = 0; i < notSyncOrderDetailList.length; i++){
        jsonValue.add(jsonEncode(notSyncOrderDetailList[i].syncJson()));
      }
      //sync to cloud
      Map data = await Domain().SyncUpdatedOrderDetailToCloud(jsonValue.toString());
      if (data['status'] == '1') {
        List responseJson = data['data'];
        for (var i = 0; i < responseJson.length; i++) {
          int orderDetailData = await PosDatabase.instance.updateOrderDetailSyncStatusFromCloud(responseJson[i]['order_detail_key']);
        }
      }
    }
  }

  orderDetailSyncToCloud() async {
    List<String> jsonValue = [];
    await getNotSyncOrderDetail();
    if(notSyncOrderDetailList.isNotEmpty){
      for(int i = 0; i <  notSyncOrderDetailList.length; i++){
        print('order detail length: ${notSyncOrderDetailList[i].branch_link_product_id}');
        jsonValue.add(jsonEncode(notSyncOrderDetailList[i].syncJson()));
      }
      print('order detail value: ${jsonValue.toString()}');
      //sync to cloud
      Map data = await Domain().SyncOrderDetailToCloud(jsonValue.toString());
      if (data['status'] == '1') {
        List responseJson = data['data'];
        for (var i = 0; i < responseJson.length; i++) {
          int orderDetailData = await PosDatabase.instance.updateOrderDetailSyncStatusFromCloud(responseJson[i]['order_detail_key']);
        }
      }
    }
  }

  getNotSyncUpdatedOrderDetail() async {
    List<OrderDetail> data = await PosDatabase.instance.readAllNotSyncUpdatedOrderDetail();
    notSyncOrderDetailList = data;
  }

  getNotSyncOrderDetail() async {
    try{
      List<String> _value = [];
      List<OrderDetail> data = await PosDatabase.instance.readAllNotSyncOrderDetail(dataSelectLimit);
      notSyncOrderDetailList = data;
      if(notSyncOrderDetailList.isNotEmpty){
        for(int i = 0; i <  notSyncOrderDetailList.length; i++){
          _value.add(jsonEncode(notSyncOrderDetailList[i].syncJson()));
        }
        this.order_detail_value = _value.toString();
        print("order detail: ${this.order_detail_value}");
      }
    } catch(error){
      print('15 order detail sync error: ${error}');
      FLog.error(
        className: "sync_to_cloud",
        text: "order detail sync to cloud error",
        exception: error,
      );
      return;
    }

  }
/*
  ----------------------Order cache part---------------------------------------------------------------------------------------------------------------------------------------
*/
  orderCacheSyncToCloud() async {
    List<String> value = [];
    await getNotSyncOrderCache();
    if(notSyncOrderCacheList.isNotEmpty){
      for(int i = 0; i <  notSyncOrderCacheList.length; i++){
        value.add(jsonEncode(notSyncOrderCacheList[i]));
      }
      //sync to cloud
      Map data = await Domain().SyncOrderCacheToCloud(value.toString());
      if(data['status'] == '1'){
        List responseJson = data['data'];
        for(int i = 0 ; i <responseJson.length; i++){
          int orderCacheData = await PosDatabase.instance.updateOrderCacheSyncStatusFromCloud(responseJson[i]['order_cache_key']);
        }
      }
    }
  }

  getNotSyncOrderCache() async {
    try{
      List<String> _value = [];
      List<OrderCache> data = await PosDatabase.instance.readAllNotSyncOrderCache(dataSelectLimit);
      notSyncOrderCacheList = data;
      if(notSyncOrderCacheList.isNotEmpty){
        for(int i = 0; i <  notSyncOrderCacheList.length; i++){
          _value.add(jsonEncode(notSyncOrderCacheList[i]));
        }
        this.order_cache_value = _value.toString();
      }
    } catch(error){
      print('15 order cache sync error: ${error}');
      FLog.error(
        className: "sync_to_cloud",
        text: "order cache sync to cloud error",
        exception: error,
      );
      return;
    }
  }

/*
  ----------------------Order part---------------------------------------------------------------------------------------------------------------------------------------
*/
  // updatedOrderSyncToCloud() async {
  //   List<String> value = [];
  //   await getNotSyncUpdatedOrder();
  //   if(notSyncOrderList.isNotEmpty){
  //     for(int i = 0; i < notSyncOrderList.length; i++){
  //       value.add(jsonEncode(notSyncOrderList[i]));
  //     }
  //     //sync to cloud
  //     Map data = await Domain().SyncUpdatedOrderToCloud(value.toString());
  //     if (data['status'] == '1') {
  //       List responseJson = data['data'];
  //       for (var i = 0; i < responseJson.length; i++) {
  //         //print('response order key: ${responseJson[i]['order_key']}');
  //         int orderData = await PosDatabase.instance.updateOrderSyncStatusFromCloud(responseJson[i]['order_key']);
  //       }
  //     }
  //   }
  // }

  orderSyncToCloud() async {
    List<String> value = [];
    await getNotSyncOrder();
    if(notSyncOrderList.isNotEmpty){
      for(int i = 0; i < notSyncOrderList.length; i++){
        value.add(jsonEncode(notSyncOrderList[i]));
      }
      //sync to cloud
      Map data = await Domain().SyncOrderToCloud(value.toString());
      if (data['status'] == '1') {
        List responseJson = data['data'];
        for (var i = 0; i < responseJson.length; i++) {
          int orderData = await PosDatabase.instance.updateOrderSyncStatusFromCloud(responseJson[i]['order_key']);
        }
      }
    }
  }

  getNotSyncUpdatedOrder() async {
    List<Order> data = await PosDatabase.instance.readAllNotSyncUpdatedOrder();
    notSyncOrderList = data;
  }

  getNotSyncOrder() async {
    try{
      List<String> _value = [];
      List<Order> data = await PosDatabase.instance.readAllNotSyncOrder(dataSelectLimit);
      notSyncOrderList = data;
      if(notSyncOrderList.isNotEmpty){
        for(int i = 0; i < notSyncOrderList.length; i++){
          _value.add(jsonEncode(notSyncOrderList[i]));
        }
        this.order_value = _value.toString();
      }
    }catch(error){
      print('15 sync order error: ${error}');
      FLog.error(
        className: "sync_to_cloud",
        text: "order sync to cloud error",
        exception: error,
      );
      return;
    }

  }
}