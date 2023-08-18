import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:pos_system/object/branch_link_product.dart';
import 'package:pos_system/object/order_detail_cancel.dart';
import 'package:pos_system/object/printer.dart';
import 'package:pos_system/object/printer_link_category.dart';
import 'package:pos_system/object/receipt.dart';
import 'package:pos_system/object/refund.dart';
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
import 'order.dart';
import 'order_cache.dart';
import 'order_detail.dart';
import 'order_modifier_detail.dart';
import 'order_promotion_detail.dart';
import 'order_tax_detail.dart';

class SyncToCloud {
  int count = 0;
  List<PosTable> notSyncPosTableList = [];
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
  List<TransferOwner> notSyncTransferOwnerList = [];
  List<Settlement> notSyncSettlementList = [];
  List<SettlementLinkPayment>  notSyncSettlementLinkPaymentList = [];
  List<Refund> notSyncRefundList = [];
  List<BranchLinkProduct> notSyncBranchLinkProductList = [];
  List<Printer> notSyncPrinterList = [];
  List<PrinterLinkCategory> notSyncPrinterCategoryList = [];
  String? table_use_value, table_use_detail_value, order_cache_value, order_detail_value, order_detail_cancel_value,
      order_modifier_detail_value, order_value, order_promotion_value, order_tax_value, receipt_value, refund_value, table_value, settlement_value,
      settlement_link_payment_value, cash_record_value, branch_link_product_value, printer_value, printer_link_category_value, transfer_owner_value;

  resetCount(){
    count = 0;
  }

  syncAllToCloud() async {
    print('sync to cloud called');
    await getAllValue();
    final prefs = await SharedPreferences.getInstance();
    final int? device_id = prefs.getInt('device_id');
    final String? login_value = prefs.getString('login_value');
    Map data = await Domain().syncLocalUpdateToCloud(
        device_id: device_id.toString(),
        value: login_value,
        isSync: true,
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
        branch_link_product_value: this.branch_link_product_value,
        table_value: this.table_value,
        printer_value: this.printer_value,
        printer_link_category_value: this.printer_link_category_value,
        transfer_owner_value: this.transfer_owner_value
    );
    if (data['status'] == '1') {
      List responseJson = data['data'];
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
            await PosDatabase.instance.updateOrderSyncStatusFromCloud(responseJson[i]['order_key']);
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
          default: {
            return;
          }
        }
      }
      return 0;
    } else if (data['status'] == '7'){
      return 1;
    } else if (data['status'] == '8'){
      return 2;
    }
    // bool _hasInternetAccess = await Domain().isHostReachable();
    // if (_hasInternetAccess) {
    //
    // }
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
    branch_link_product_value = [].toString();
    printer_value = [].toString();
    printer_link_category_value = [].toString();
    transfer_owner_value = [].toString();
  }

  getAllValue() async {
    resetValue();
    await getNotSyncReceipt();
    await getNotSyncBranchLinkProduct();
    await getNotSyncCashRecord();
    await getNotSyncOrder();
    await getNotSyncOrderCache();
    await getNotSyncOrderDetail();
    await getNotSyncOrderDetailCancel();
    await getNotSyncOrderModifierDetail();
    await getNotSyncOrderPromotionDetail();
    await getNotSyncOrderTaxDetail();
    await getNotSyncPrinter();
    await getNotSyncPrinterLinkCategory();
    await getNotSyncRefund();
    await getNotSyncSettlement();
    await getNotSyncSettlementLinkPayment();
    await getNotSyncTableUse();
    await getNotSyncTableUseDetail();
    await getNotSyncTable();
    await getNotSyncTransfer();
  }

  getNotSyncReceipt() async {
    try{
      List<String> _value = [];
      List<Receipt> data = await PosDatabase.instance.readAllNotSyncReceipt();
      if(data.isNotEmpty){
        for(int i = 0; i < data.length; i++){
          _value.add(jsonEncode(data[i]));
        }
        this.receipt_value = _value.toString();
      }
      //print('receipt value: ${receipt_value}');
    } catch(error){
      print('15 receipt error: ${error}');
      return;
    }
  }


/*
  ----------------------Printer part----------------------------------------------------------------------------------------------------------------------------
*/

  getNotSyncPrinterLinkCategory() async {
    try{
      List<String> _value = [];
      List<PrinterLinkCategory> data = await PosDatabase.instance.readAllNotSyncPrinterLinkCategory();
      notSyncPrinterCategoryList = data;
      if(notSyncPrinterCategoryList.isNotEmpty){
        for(int i = 0; i < notSyncPrinterCategoryList.length; i++){
          _value.add(jsonEncode(notSyncPrinterCategoryList[i]));
        }
        this.printer_link_category_value = _value.toString();
        print('value: ${printer_link_category_value}');
      }
    }catch (error){
      print('15 printer category error: ${error}');
      return;
    }
  }

  getNotSyncPrinter() async {
    try{
      List<String> _value = [];
      List<Printer> data = await PosDatabase.instance.readAllNotSyncLANPrinter();
      notSyncPrinterList = data;
      if(notSyncPrinterList.isNotEmpty){
        for(int i = 0; i < notSyncPrinterList.length; i++){
          _value.add(jsonEncode(notSyncPrinterList[i]));
        }
        this.printer_value = _value.toString();
      }
    } catch(error){
      print('15 printer sync error: ${error}');
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
      List<BranchLinkProduct> data = await PosDatabase.instance.readAllNotSyncBranchLinkProduct();
      notSyncBranchLinkProductList = data;
      if(notSyncBranchLinkProductList.isNotEmpty){
        for(int i = 0; i < notSyncBranchLinkProductList.length; i++){
          _value.add(jsonEncode(notSyncBranchLinkProductList[i]));
        }
        this.branch_link_product_value = _value.toString();
      }
    } catch (error){
      print('15 branch link product sync error: ${error}');
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
      List<SettlementLinkPayment> data = await PosDatabase.instance.readAllNotSyncSettlementLinkPayment();
      notSyncSettlementLinkPaymentList = data;
      if(notSyncSettlementLinkPaymentList.isNotEmpty){
        for(int i = 0; i < notSyncSettlementLinkPaymentList.length; i++){
          _value.add(jsonEncode(notSyncSettlementLinkPaymentList[i]));
        }
        this.settlement_link_payment_value = _value.toString();
      }
    }catch(error){
      print('15 settlement payment sync error: ${error}');
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
      List<Settlement> data = await PosDatabase.instance.readAllNotSyncSettlement();
      notSyncSettlementList = data;
      if(notSyncSettlementList.isNotEmpty){
        for(int i = 0; i < notSyncSettlementList.length; i++){
          _value.add(jsonEncode(notSyncSettlementList[i]));
        }
        this.settlement_value = _value.toString();
      }
    }catch(error){
      print('15 settlement sync error: ${error}');
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
      List<TransferOwner> data = await PosDatabase.instance.readAllNotSyncTransferOwner();
      notSyncTransferOwnerList = data;
      if(notSyncTransferOwnerList.isNotEmpty){
        for(int i = 0; i < notSyncTransferOwnerList.length; i++){
          _value.add(jsonEncode(notSyncTransferOwnerList[i]));
        }
        this.transfer_owner_value = _value.toString();
      }
    }catch(error){
      print('15 transfer owner sync error: ${error}');
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
      List<Refund> data = await PosDatabase.instance.readAllNotSyncRefund();
      notSyncRefundList = data;
      if(notSyncRefundList.isNotEmpty){
        for(int i = 0; i <  notSyncRefundList.length; i++){
          _value.add(jsonEncode(notSyncRefundList[i]));
        }
        this.refund_value = _value.toString();
      }
    } catch (error){
      print('15 refund sync error: ${error}');
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
      List<CashRecord> data = await PosDatabase.instance.readAllNotSyncCashRecord();
      notSyncCashRecordList = data;
      if(notSyncCashRecordList.isNotEmpty) {
        for(int i = 0; i < notSyncCashRecordList.length; i++){
          _value.add(jsonEncode(notSyncCashRecordList[i]));
        }
        this.cash_record_value = _value.toString();
      }
    }catch(error){
      print('15 cash record sync error: ${error}');
      return;
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
      List<PosTable> data = await PosDatabase.instance.readAllNotSyncUpdatedPosTable();
      notSyncPosTableList = data;
      if(notSyncPosTableList.isNotEmpty){
        for (int i = 0; i < notSyncPosTableList.length; i++) {
          _value.add(jsonEncode(notSyncPosTableList[i]));
        }
        this.table_value = _value.toString();
      }
    }catch(error){
      print('15 table sync error: ${error}');
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
      List<OrderPromotionDetail> data = await PosDatabase.instance.readAllNotSyncOrderPromotionDetail();
      notSyncOrderPromotionDetailList = data;
      if(notSyncOrderPromotionDetailList.isNotEmpty){
        for(int i = 0; i <  notSyncOrderPromotionDetailList.length; i++){
          _value.add(jsonEncode(notSyncOrderPromotionDetailList[i]));
        }
        this.order_promotion_value = _value.toString();
      }
    }catch(error){
      print('15 order promotion sync error: ${error}');
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
      List<OrderTaxDetail> data = await PosDatabase.instance.readAllNotSyncOrderTaxDetail();
      notSyncOrderTaxDetailList = data;
      if(notSyncOrderTaxDetailList.isNotEmpty){
        for(int i = 0; i <  notSyncOrderTaxDetailList.length; i++){
          _value.add(jsonEncode(notSyncOrderTaxDetailList[i]));
        }
        this.order_tax_value = _value.toString();
      }
    } catch(error){
      print('15 order tax sync error: ${error}');
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
      List<TableUseDetail> data = await PosDatabase.instance.readAllNotSyncTableUseDetail();
      notSyncTableUseDetailList = data;
      if(notSyncTableUseDetailList.isNotEmpty){
        for(int i = 0; i <  notSyncTableUseDetailList.length; i++){
          _value.add(jsonEncode(notSyncTableUseDetailList[i]));
        }
        this.table_use_detail_value = _value.toString();
      }
    }catch(error){
      print('15 table use detail error: ${error}');
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
      List<TableUse> data = await PosDatabase.instance.readAllNotSyncTableUse();
      notSyncTableUseList = data;
      if(notSyncTableUseList.isNotEmpty){
        for(int i = 0; i < notSyncTableUseList.length; i++){
          _value.add(jsonEncode(notSyncTableUseList[i]));
        }
        this.table_use_value = _value.toString();
      }
    }catch(error){
      print('15 table use sync error: ${error}');
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
      List<OrderModifierDetail> data = await PosDatabase.instance.readAllNotSyncOrderModDetail();
      notSyncOrderModifierDetailList = data;
      if(notSyncOrderModifierDetailList.isNotEmpty){
        for(int i = 0; i < notSyncOrderModifierDetailList.length; i++){
          _value.add(jsonEncode(notSyncOrderModifierDetailList[i]));
        }
        this.order_modifier_detail_value = _value.toString();
      }
    } catch(error){
      print('15 order modifier detail sync error: ${error}');
      return;
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
      List<OrderDetailCancel> data = await PosDatabase.instance.readAllNotSyncOrderDetailCancel();
      notSyncOrderDetailCancelList = data;
      if(notSyncOrderDetailCancelList.isNotEmpty){
        for(int i = 0; i < notSyncOrderDetailCancelList.length; i++){
          _value.add(jsonEncode(notSyncOrderDetailCancelList[i]));
        }
        this.order_detail_cancel_value = _value.toString();
      }
    } catch(error){
      print('15 order detail cancel error: ${error}');
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
      List<OrderDetail> data = await PosDatabase.instance.readAllNotSyncOrderDetail();
      notSyncOrderDetailList = data;
      if(notSyncOrderDetailList.isNotEmpty){
        for(int i = 0; i <  notSyncOrderDetailList.length; i++){
          _value.add(jsonEncode(notSyncOrderDetailList[i].syncJson()));
        }
        this.order_detail_value = _value.toString();
      }
    } catch(error){
      print('15 order detail sync error: ${error}');
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
      List<OrderCache> data = await PosDatabase.instance.readAllNotSyncOrderCache();
      notSyncOrderCacheList = data;
      if(notSyncOrderCacheList.isNotEmpty){
        for(int i = 0; i <  notSyncOrderCacheList.length; i++){
          _value.add(jsonEncode(notSyncOrderCacheList[i]));
        }
        this.order_cache_value = _value.toString();
      }
    } catch(error){
      print('15 order cache sync error: ${error}');
      return;
    }
  }

/*
  ----------------------Order part---------------------------------------------------------------------------------------------------------------------------------------
*/
  updatedOrderSyncToCloud() async {
    List<String> value = [];
    await getNotSyncUpdatedOrder();
    if(notSyncOrderList.isNotEmpty){
      for(int i = 0; i < notSyncOrderList.length; i++){
        value.add(jsonEncode(notSyncOrderList[i]));
      }
      //sync to cloud
      Map data = await Domain().SyncUpdatedOrderToCloud(value.toString());
      if (data['status'] == '1') {
        List responseJson = data['data'];
        for (var i = 0; i < responseJson.length; i++) {
          //print('response order key: ${responseJson[i]['order_key']}');
          int orderData = await PosDatabase.instance.updateOrderSyncStatusFromCloud(responseJson[i]['order_key']);
        }
      }
    }
  }

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
      List<Order> data = await PosDatabase.instance.readAllNotSyncOrder();
      notSyncOrderList = data;
      if(notSyncOrderList.isNotEmpty){
        for(int i = 0; i < notSyncOrderList.length; i++){
          _value.add(jsonEncode(notSyncOrderList[i]));
        }
        this.order_value = _value.toString();
      }
    }catch(error){
      print('15 sync order error: ${error}');
      return;
    }

  }
}