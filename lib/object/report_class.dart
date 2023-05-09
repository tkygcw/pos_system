import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pos_system/object/modifier_group.dart';
import 'package:pos_system/object/order_modifier_detail.dart';
import 'package:pos_system/object/payment_link_company.dart';
import 'package:pos_system/object/settlement.dart';
import 'package:pos_system/object/settlement_link_payment.dart';
import 'package:pos_system/object/transfer_owner.dart';

import '../database/pos_database.dart';
import 'branch_link_dining_option.dart';
import 'branch_link_modifier.dart';
import 'branch_link_tax.dart';
import 'categories.dart';
import 'order.dart';
import 'order_detail.dart';
import 'order_detail_cancel.dart';
import 'order_promotion_detail.dart';
import 'order_tax_detail.dart';

class ReportObject{
  double? totalSales = 0.0, totalRefundAmount = 0.0;
  double? totalPromotionAmount = 0.0;
  List<Order> paidOrderList = [];
  List<Order>? dateOrderList;
  List<Order>? dateRefundOrderList;
  List<OrderDetail> cancelledOrderDetail = [], paidOrderDetail = [];
  List<OrderDetail>? dateOrderDetail;
  List<OrderPromotionDetail> paidPromotionDetail = [];
  List<OrderPromotionDetail>? datePromotionDetail = [];
  List<OrderTaxDetail> paidOrderTaxDetail = [];
  List<OrderTaxDetail>? dateTaxDetail = [];
  List<BranchLinkTax>? branchTaxList = [];
  List<Categories> paidCategory = [];
  List<Categories>? dateCategory = [];
  List<ModifierGroup> paidModifierGroup = [];
  List<ModifierGroup>? dateModifierGroup = [];
  List<OrderModifierDetail> paidModifier = [];
  List<OrderModifierDetail>? dateModifier = [];
  List<Order> paidDining = [];
  List<Order>? dateDining  = [];
  List<Order> paidPayment = [];
  List<Order>? datePayment = [];
  List<Settlement> settlementList = [];
  List<Settlement>? dateSettlementList = [];
  List<SettlementLinkPayment> settlementPaymentList = [];
  List<SettlementLinkPayment>? dateSettlementPaymentList = [];
  List<OrderDetailCancel>? dateOrderDetailCancelList = [];
  List<TransferOwner>? dateTransferList = [];

  ReportObject(
      {this.totalSales,
      this.totalRefundAmount,
      this.totalPromotionAmount,
      this.dateOrderList,
      this.dateOrderDetail,
      this.dateRefundOrderList,
      this.datePromotionDetail,
      this.branchTaxList,
      this.dateTaxDetail,
      this.dateCategory,
      this.dateModifierGroup,
      this.dateModifier,
      this.dateDining,
      this.datePayment,
      this.dateSettlementList,
      this.dateSettlementPaymentList,
      this.dateOrderDetailCancelList,
      this.dateTransferList});

  getAllTransferRecord({currentStDate, currentEdDate}) async {
    dateTransferList = [];
    DateTime _startDate = DateTime.parse(currentStDate);
    DateTime _endDate = DateTime.parse(currentEdDate);
    DateTime addEndDate = addDays(date: _endDate);
    String stringStDate = new DateFormat("yyyy-MM-dd").format(_startDate);
    String stringEdDate = new DateFormat("yyyy-MM-dd").format(addEndDate);
    List<TransferOwner> data = await PosDatabase.instance.readAllTransferOwner(stringStDate, stringEdDate);
    print('data: ${data.length}');
    for(int i = 0; i < data.length; i++){
      dateTransferList!.add(data[i]);
    }
    ReportObject value = ReportObject(dateTransferList: dateTransferList);
    return value;
  }

  getAllSettlementPaymentDetail(String settlement_date) async {
    dateSettlementPaymentList = [];
    List<SettlementLinkPayment> settlementData = await PosDatabase.instance.readSpecificSettlementLinkPayment(settlement_date);
    settlementPaymentList = settlementData;
    print('length: ${settlementPaymentList.length}');
    if (settlementPaymentList.isNotEmpty) {
      for (int i = 0; i < settlementPaymentList.length; i++) {
        dateSettlementPaymentList!.add(settlementPaymentList[i]);
        print('payment method: ${settlementPaymentList[i].payment_link_company_id}');
      }
    }
    ReportObject value = ReportObject(dateSettlementPaymentList: dateSettlementPaymentList);
    return value;
  }

  getAllSettlement({currentStDate, currentEdDate}) async {
    dateSettlementList = [];
    List<Settlement> settlementData = await PosDatabase.instance.readAllSettlement();
    settlementList = settlementData;
    if (settlementList.isNotEmpty) {
      for (int i = 0; i < settlementList.length; i++) {
        // DateTime dataDate = DateTime.parse(settlementList[i].created_at!);
        // String stringDate = new DateFormat("dd-MM-yyyy").format(dataDate);
        // settlementList[i].created_at = stringDate;
        dateSettlementList!.add(settlementList[i]);
      }
    }
    ReportObject value = ReportObject(dateSettlementList: dateSettlementList);
    return value;
  }

  getAllTaxDetail(int order_sqlite_id, {currentStDate, currentEdDate}) async {
    dateTaxDetail = [];
    DateTime _startDate = DateTime.parse(currentStDate);
    DateTime _endDate = DateTime.parse(currentEdDate);
    //convert time to string
    DateTime addEndDate = addDays(date: _endDate);
    String stringStDate = new DateFormat("yyyy-MM-dd").format(_startDate);
    String stringEdDate = new DateFormat("yyyy-MM-dd").format(addEndDate);
    List<OrderTaxDetail> taxData = await PosDatabase.instance.readAllRefundedOrderTaxDetail(order_sqlite_id, stringStDate, stringEdDate);
    paidOrderTaxDetail = taxData;
    if (paidOrderTaxDetail.isNotEmpty) {
      for (int i = 0; i < paidOrderTaxDetail.length; i++) {
        List<OrderTaxDetail> taxSumData = await PosDatabase.instance.sumAllOrderTaxDetail(order_sqlite_id, paidOrderTaxDetail[i].tax_id!, stringStDate, stringEdDate);
        paidOrderTaxDetail[i].total_tax_amount = taxSumData[0].total_tax_amount;
        dateTaxDetail!.add(paidOrderTaxDetail[i]);

        // DateTime convertDate = new DateFormat("yyyy-MM-dd HH:mm:ss").parse(paidOrderList[i].created_at!);
        // if(currentStDate != currentEdDate){
        //   if(convertDate.isAfter(_startDate)){
        //     if(convertDate.isBefore(addDays(date: _endDate))){
        //       dateRefundOrderList!.add(paidOrderList[i]);
        //     }
        //   }
        // } else {
        //   if(convertDate.isAfter(_startDate) && convertDate.isBefore(addDays(date: _endDate))){
        //     dateRefundOrderList!.add(paidOrderList[i]);
        //   }
        // }
      }
    }
    ReportObject value = ReportObject(dateTaxDetail: dateTaxDetail);
    return value;
  }

  getAllRefundedOrder({currentStDate, currentEdDate}) async {
    dateRefundOrderList = [];
    DateTime _startDate = DateTime.parse(currentStDate);
    DateTime _endDate = DateTime.parse(currentEdDate);
    //convert time to string
    DateTime addEndDate = addDays(date: _endDate);
    String stringStDate = new DateFormat("yyyy-MM-dd").format(_startDate);
    String stringEdDate = new DateFormat("yyyy-MM-dd").format(addEndDate);
    List<Order> orderData = await PosDatabase.instance.readAllRefundedOrder(stringStDate, stringEdDate);
    paidOrderList = orderData;
    if (paidOrderList.isNotEmpty) {
      for (int i = 0; i < paidOrderList.length; i++) {
        dateRefundOrderList!.add(paidOrderList[i]);
        // DateTime convertDate = new DateFormat("yyyy-MM-dd HH:mm:ss").parse(paidOrderList[i].created_at!);
        // if(currentStDate != currentEdDate){
        //   if(convertDate.isAfter(_startDate)){
        //     if(convertDate.isBefore(addDays(date: _endDate))){
        //       dateRefundOrderList!.add(paidOrderList[i]);
        //     }
        //   }
        // } else {
        //   if(convertDate.isAfter(_startDate) && convertDate.isBefore(addDays(date: _endDate))){
        //     dateRefundOrderList!.add(paidOrderList[i]);
        //   }
        // }

      }
    }
    ReportObject value = ReportObject(dateRefundOrderList: dateRefundOrderList);
    return value;
  }

  getAllCancelledOrderModifierDetail(String mod_group_id, {currentStDate, currentEdDate}) async {
    dateModifier = [];
    DateTime _startDate = DateTime.parse(currentStDate);
    DateTime _endDate = DateTime.parse(currentEdDate);
    //convert time to string
    DateTime addEndDate = addDays(date: _endDate);
    String stringStDate = new DateFormat("yyyy-MM-dd").format(_startDate);
    String stringEdDate = new DateFormat("yyyy-MM-dd").format(addEndDate);
    //get data
    List<OrderModifierDetail> detailData = await PosDatabase.instance.readAllCancelledModifier(mod_group_id, stringStDate, stringEdDate);
    this.paidModifier = detailData;
    if (paidModifier.isNotEmpty) {
      for (int i = 0; i < paidModifier.length; i++) {
        dateModifier!.add(paidModifier[i]);
      }
      //   DateTime convertDate = new DateFormat("yyyy-MM-dd HH:mm:ss").parse(paidModifier[i].created_at!);
      //   if(currentStDate != currentEdDate){
      //     if(convertDate.isAfter(_startDate)){
      //       if(convertDate.isBefore(addDays(date: _endDate))){
      //         dateModifier!.add(paidModifier[i]);
      //       }
      //     }
      //   } else {
      //     if(convertDate.isAfter(_startDate) && convertDate.isBefore(addDays(date: _endDate))){
      //       dateModifier!.add(paidModifier[i]);
      //     }
      //   }
      // }
    }
    ReportObject value = ReportObject(dateModifier: dateModifier);
    return value;
  }

  getAllCancelledModifierGroup({currentStDate, currentEdDate}) async {
    dateModifierGroup = [];
    DateTime _startDate = DateTime.parse(currentStDate);
    DateTime _endDate = DateTime.parse(currentEdDate);
    //convert time to string
    DateTime addEndDate = addDays(date: _endDate);
    String stringStDate = new DateFormat("yyyy-MM-dd").format(_startDate);
    String stringEdDate = new DateFormat("yyyy-MM-dd").format(addEndDate);
    print('date1: ${stringStDate}');
    print('date2: ${stringEdDate}');
    //get data
    List<ModifierGroup> modifierGroupData = await PosDatabase.instance.readAllCancelledModifierGroup(stringStDate, stringEdDate);
    print('modifier group data 1: ${modifierGroupData.length}');
    this.paidModifierGroup = modifierGroupData;
    if (paidModifierGroup.isNotEmpty) {
      for (int i = 0; i < paidModifierGroup.length; i++) {
        //print('paid modifier: ${paidModifier[i].toJson()}');
        dateModifierGroup!.add(paidModifierGroup[i]);
        // DateTime convertDate = new DateFormat("yyyy-MM-dd HH:mm:ss").parse(paidModifier[i].created_at!);
        // if(currentStDate != currentEdDate){
        //   if(convertDate.isAfter(_startDate)){
        //     if(convertDate.isBefore(addDays(date: _endDate))){
        //       dateModifier!.add(paidModifier[i]);
        //     }
        //   }
        // } else {
        //   if(convertDate.isAfter(_startDate) && convertDate.isBefore(addDays(date: _endDate))){
        //     dateModifier!.add(paidModifier[i]);
        //   }
        // }
      }
    }
    ReportObject value = ReportObject(dateModifierGroup: dateModifierGroup);
    return value;
  }

  getAllCancelOrderDetailWithCategory(int category_sqlite_id, {currentStDate, currentEdDate}) async {
    dateOrderDetail = [];
    DateTime _startDate = DateTime.parse(currentStDate);
    DateTime _endDate = DateTime.parse(currentEdDate);
    //convert time to string
    DateTime addEndDate = addDays(date: _endDate);
    String stringStDate = new DateFormat("yyyy-MM-dd").format(_startDate);
    String stringEdDate = new DateFormat("yyyy-MM-dd").format(addEndDate);
    //get data
    List<OrderDetail> detailData = await PosDatabase.instance.readAllCancelledOrderDetailWithCategory(category_sqlite_id, stringStDate, stringEdDate);
    this.paidOrderDetail = detailData;
    if (paidOrderDetail.isNotEmpty) {
      for (int i = 0; i < paidOrderDetail.length; i++) {
        DateTime convertDate = new DateFormat("yyyy-MM-dd HH:mm:ss").parse(paidOrderDetail[i].created_at!);
        if(currentStDate != currentEdDate){
          if(convertDate.isAfter(_startDate)){
            if(convertDate.isBefore(addDays(date: _endDate))){
              dateOrderDetail!.add(paidOrderDetail[i]);
            }
          }
        } else {
          if(convertDate.isAfter(_startDate) && convertDate.isBefore(addDays(date: _endDate))){
            dateOrderDetail!.add(paidOrderDetail[i]);
          }
        }
      }
    }
    ReportObject value = ReportObject(dateOrderDetail: dateOrderDetail);
    return value;
  }

  getAllCancelItemCategory({currentStDate, currentEdDate}) async {
    dateCategory = [];
    DateTime _startDate = DateTime.parse(currentStDate);
    DateTime _endDate = DateTime.parse(currentEdDate);
    //convert time to string
    DateTime addEndDate = addDays(date: _endDate);
    String stringStDate = new DateFormat("yyyy-MM-dd").format(_startDate);
    String stringEdDate = new DateFormat("yyyy-MM-dd").format(addEndDate);
    print('string start date: ${stringStDate}');
    print('string end date: ${stringEdDate}');
    List<Categories> categoryData = await PosDatabase.instance.readAllCancelledCategoryWithOrderDetail(stringStDate, stringEdDate);
    this.paidCategory = categoryData;
    if (paidCategory.isNotEmpty) {
      for (int i = 0; i < paidCategory.length; i++) {
        dateCategory!.add(paidCategory[i]);
        // DateTime convertDate = new DateFormat("yyyy-MM-dd HH:mm:ss").parse(paidCategory[i].created_at!);
        // if(currentStDate != currentEdDate){
        //   if(convertDate.isAfter(_startDate)){
        //     if(convertDate.isBefore(addDays(date: _endDate))){
        //       dateCategory!.add(paidCategory[i]);
        //     }
        //   }
        // } else {
        //   if(convertDate.isAfter(_startDate) && convertDate.isBefore(addDays(date: _endDate))){
        //     dateCategory!.add(paidCategory[i]);
        //   }
        // }
      }
    }
    ReportObject value = ReportObject(dateCategory: dateCategory);
    return value;
  }

  getAllPaymentData({currentStDate, currentEdDate}) async {
    datePayment = [];
    DateTime _startDate = DateTime.parse(currentStDate);
    DateTime _endDate = DateTime.parse(currentEdDate);
    //convert time to string
    DateTime addEndDate = addDays(date: _endDate);
    String stringStDate = new DateFormat("yyyy-MM-dd").format(_startDate);
    String stringEdDate = new DateFormat("yyyy-MM-dd").format(addEndDate);
    //get data
    List<Order> paymentData = await PosDatabase.instance.readAllPaidPaymentType(stringStDate, stringEdDate);
    this.paidPayment = paymentData;
    if (paidPayment.isNotEmpty) {
      for (int i = 0; i < paidPayment.length; i++) {
        datePayment!.add(paidPayment[i]);
        // DateTime convertDate = new DateFormat("yyyy-MM-dd HH:mm:ss").parse(paidPayment[i].created_at!);
        // if(currentStDate != currentEdDate){
        //   if(convertDate.isAfter(_startDate)){
        //     if(convertDate.isBefore(addDays(date: _endDate))){
        //       datePayment!.add(paidPayment[i]);
        //     }
        //   }
        // } else {
        //   if(convertDate.isAfter(_startDate) && convertDate.isBefore(addDays(date: _endDate))){
        //     datePayment!.add(paidPayment[i]);
        //   }
        // }
      }
    }
    ReportObject value = ReportObject(datePayment: datePayment);
    return value;
  }

  getAllPaidDiningData({currentStDate, currentEdDate}) async {
    dateDining = [];
    DateTime _startDate = DateTime.parse(currentStDate);
    DateTime _endDate = DateTime.parse(currentEdDate);
    DateTime addEndDate = addDays(date: _endDate);
    String stringStDate = new DateFormat("yyyy-MM-dd").format(_startDate);
    String stringEdDate = new DateFormat("yyyy-MM-dd").format(addEndDate);
    //get data
    List<Order> diningData = await PosDatabase.instance.readAllPaidDining(stringStDate, stringEdDate);
    this.paidDining = diningData;
    if (paidDining.isNotEmpty) {
      for (int i = 0; i < paidDining.length; i++) {
        dateDining!.add(paidDining[i]);
        // DateTime convertDate = new DateFormat("yyyy-MM-dd HH:mm:ss").parse(paidDining[i].created_at!);
        // if(currentStDate != currentEdDate){
        //   if(convertDate.isAfter(_startDate)){
        //     if(convertDate.isBefore(addDays(date: _endDate))){
        //       dateDining!.add(paidDining[i]);
        //     }
        //   }
        // } else {
        //   if(convertDate.isAfter(_startDate) && convertDate.isBefore(addDays(date: _endDate))){
        //     dateDining!.add(paidDining[i]);
        //   }
        // }
      }
    }
    print('dining data after filter: ${dateDining!.length}');
    ReportObject value = ReportObject(dateDining: dateDining);
    return value;
  }


  getAllPaidOrderModifierDetail(String mod_group_id, {currentStDate, currentEdDate}) async {
    dateModifier = [];
    DateTime _startDate = DateTime.parse(currentStDate);
    DateTime _endDate = DateTime.parse(currentEdDate);
    //convert time to string
    DateTime addEndDate = addDays(date: _endDate);
    String stringStDate = new DateFormat("yyyy-MM-dd").format(_startDate);
    String stringEdDate = new DateFormat("yyyy-MM-dd").format(addEndDate);
    //get data
    List<OrderModifierDetail> detailData = await PosDatabase.instance.readAllPaidModifier(mod_group_id, stringStDate, stringEdDate);
    this.paidModifier = detailData;
    if (paidModifier.isNotEmpty) {
      for (int i = 0; i < paidModifier.length; i++) {
        dateModifier!.add(paidModifier[i]);
      }
      //   DateTime convertDate = new DateFormat("yyyy-MM-dd HH:mm:ss").parse(paidModifier[i].created_at!);
      //   if(currentStDate != currentEdDate){
      //     if(convertDate.isAfter(_startDate)){
      //       if(convertDate.isBefore(addDays(date: _endDate))){
      //         dateModifier!.add(paidModifier[i]);
      //       }
      //     }
      //   } else {
      //     if(convertDate.isAfter(_startDate) && convertDate.isBefore(addDays(date: _endDate))){
      //       dateModifier!.add(paidModifier[i]);
      //     }
      //   }
      // }
    }
    ReportObject value = ReportObject(dateModifier: dateModifier);
    return value;
  }

  getAllPaidModifierGroup({currentStDate, currentEdDate}) async {
    dateModifierGroup = [];
    DateTime _startDate = DateTime.parse(currentStDate);
    DateTime _endDate = DateTime.parse(currentEdDate);
    //convert time to string
    DateTime addEndDate = addDays(date: _endDate);
    String stringStDate = new DateFormat("yyyy-MM-dd").format(_startDate);
    String stringEdDate = new DateFormat("yyyy-MM-dd").format(addEndDate);
    print('date1: ${stringStDate}');
    print('date2: ${stringEdDate}');
    //get data
    List<ModifierGroup> modifierGroupData = await PosDatabase.instance.readAllPaidModifierGroup(stringStDate, stringEdDate);
    print('modifier group data 1: ${modifierGroupData.length}');
    this.paidModifierGroup = modifierGroupData;
    if (paidModifierGroup.isNotEmpty) {
      for (int i = 0; i < paidModifierGroup.length; i++) {
        //print('paid modifier: ${paidModifier[i].toJson()}');
        dateModifierGroup!.add(paidModifierGroup[i]);
        // DateTime convertDate = new DateFormat("yyyy-MM-dd HH:mm:ss").parse(paidModifier[i].created_at!);
        // if(currentStDate != currentEdDate){
        //   if(convertDate.isAfter(_startDate)){
        //     if(convertDate.isBefore(addDays(date: _endDate))){
        //       dateModifier!.add(paidModifier[i]);
        //     }
        //   }
        // } else {
        //   if(convertDate.isAfter(_startDate) && convertDate.isBefore(addDays(date: _endDate))){
        //     dateModifier!.add(paidModifier[i]);
        //   }
        // }
      }
    }
    ReportObject value = ReportObject(dateModifierGroup: dateModifierGroup);
    return value;
  }

  getAllPaidOrderDetailWithCategory(int category_sqlite_id, {currentStDate, currentEdDate}) async {
    dateOrderDetail = [];
    DateTime _startDate = DateTime.parse(currentStDate);
    DateTime _endDate = DateTime.parse(currentEdDate);
    //convert time to string
    DateTime addEndDate = addDays(date: _endDate);
    String stringStDate = new DateFormat("yyyy-MM-dd").format(_startDate);
    String stringEdDate = new DateFormat("yyyy-MM-dd").format(addEndDate);
    //get data
    List<OrderDetail> detailData = await PosDatabase.instance.readAllPaidOrderDetailWithCategory(category_sqlite_id, stringStDate, stringEdDate);
    this.paidOrderDetail = detailData;
    if (paidOrderDetail.isNotEmpty) {
      for (int i = 0; i < paidOrderDetail.length; i++) {
        dateOrderDetail!.add(paidOrderDetail[i]);
        // DateTime convertDate = new DateFormat("yyyy-MM-dd HH:mm:ss").parse(paidOrderDetail[i].created_at!);
        // if(currentStDate != currentEdDate){
        //   if(convertDate.isAfter(_startDate)){
        //     if(convertDate.isBefore(addDays(date: _endDate))){
        //       dateOrderDetail!.add(paidOrderDetail[i]);
        //     }
        //   }
        // } else {
        //   if(convertDate.isAfter(_startDate) && convertDate.isBefore(addDays(date: _endDate))){
        //     dateOrderDetail!.add(paidOrderDetail[i]);
        //   }
        // }
      }
    }
    ReportObject value = ReportObject(dateOrderDetail: dateOrderDetail);
    return value;
  }

  getAllPaidCategory({currentStDate, currentEdDate}) async {
    dateCategory = [];
    DateTime _startDate = DateTime.parse(currentStDate);
    DateTime _endDate = DateTime.parse(currentEdDate);
    //convert time to string
    DateTime addEndDate = addDays(date: _endDate);
    String stringStDate = new DateFormat("yyyy-MM-dd").format(_startDate);
    String stringEdDate = new DateFormat("yyyy-MM-dd").format(addEndDate);
    print('string start date: ${stringStDate}');
    print('string end date: ${stringEdDate}');
    List<Categories> categoryData = await PosDatabase.instance.readAllCategoryWithOrderDetail(stringStDate, stringEdDate);
    this.paidCategory = categoryData;
    if (paidCategory.isNotEmpty) {
      for (int i = 0; i < paidCategory.length; i++) {
        dateCategory!.add(paidCategory[i]);
        // DateTime convertDate = new DateFormat("yyyy-MM-dd HH:mm:ss").parse(paidCategory[i].created_at!);
        // if(currentStDate != currentEdDate){
        //   if(convertDate.isAfter(_startDate)){
        //     if(convertDate.isBefore(addDays(date: _endDate))){
        //       dateCategory!.add(paidCategory[i]);
        //     }
        //   }
        // } else {
        //   if(convertDate.isAfter(_startDate) && convertDate.isBefore(addDays(date: _endDate))){
        //     dateCategory!.add(paidCategory[i]);
        //   }
        // }
      }
    }
    ReportObject value = ReportObject(dateCategory: dateCategory);
    return value;
  }

  getTotalCancelledItem({currentStDate, currentEdDate}) async {
    List<OrderDetailCancel> _list = [];
    dateOrderDetailCancelList = [];
    DateTime _startDate = DateTime.parse(currentStDate);
    DateTime _endDate = DateTime.parse(currentEdDate);
    //convert time to string
    DateTime addEndDate = addDays(date: _endDate);
    String stringStDate = new DateFormat("yyyy-MM-dd").format(_startDate);
    String stringEdDate = new DateFormat("yyyy-MM-dd").format(addEndDate);
    List<OrderDetailCancel> detailData = await PosDatabase.instance.readAllCancelItem2(stringStDate, stringEdDate);
    _list = detailData;
    if (_list.isNotEmpty) {
      for (int i = 0; i < _list.length; i++) {
        dateOrderDetailCancelList!.add(_list[i]);
        // DateTime convertDate = new DateFormat("yyyy-MM-dd HH:mm:ss").parse(cancelledOrderDetail[i].created_at!);
        // if(currentStDate != currentEdDate){
        //   if(convertDate.isAfter(_startDate)){
        //     if(convertDate.isBefore(addDays(date: _endDate))){
        //       dateOrderDetail!.add(cancelledOrderDetail[i]);
        //     }
        //   }
        // } else {
        //   if(convertDate.isAfter(_startDate) && convertDate.isBefore(addDays(date: _endDate))){
        //     dateOrderDetail!.add(cancelledOrderDetail[i]);
        //   }
        // }
      }
    }
    ReportObject value = ReportObject(dateOrderDetailCancelList: dateOrderDetailCancelList);
    return value;
  }


  getAllPaidOrder({currentStDate, currentEdDate}) async {
    dateOrderList = [];
    DateTime _startDate = DateTime.parse(currentStDate);
    DateTime _endDate = DateTime.parse(currentEdDate);
    this.totalSales = 0.0;
    List<Order> orderData = await PosDatabase.instance.readAllOrder();
    paidOrderList = orderData;
    if (paidOrderList.isNotEmpty) {
      for (int i = 0; i < paidOrderList.length; i++) {
        DateTime convertDate = new DateFormat("yyyy-MM-dd HH:mm:ss").parse(paidOrderList[i].created_at!);
        if(currentStDate != currentEdDate){
          if(convertDate.isAfter(_startDate)){
            if(convertDate.isBefore(addDays(date: _endDate))){
              dateOrderList!.add(paidOrderList[i]);
            }
          }
        } else {
          if(convertDate.isAfter(_startDate) && convertDate.isBefore(addDays(date: _endDate))){
            dateOrderList!.add(paidOrderList[i]);
          }
        }

      }
      for (int j = 0; j < dateOrderList!.length; j++) {
        if(dateOrderList![j].payment_status == 1){
          sumAllOrderTotal(dateOrderList![j].final_amount!);
        }
      }
    }
    ReportObject value = ReportObject(totalSales: totalSales, dateOrderList: dateOrderList);
    return value;
  }

  getAllPaidOrderPromotionDetail({currentStDate, currentEdDate}) async {
    datePromotionDetail = [];
    DateTime _startDate = DateTime.parse(currentStDate);
    DateTime _endDate = DateTime.parse(currentEdDate);
    this.totalPromotionAmount = 0.0;
    List<OrderPromotionDetail> detailData = await PosDatabase.instance.readAllPaidOrderPromotionDetail();
    this.paidPromotionDetail = detailData;
    if (paidPromotionDetail.isNotEmpty) {
      for (int i = 0; i < paidPromotionDetail.length; i++) {
        DateTime convertDate = new DateFormat("yyyy-MM-dd HH:mm:ss").parse(paidPromotionDetail[i].created_at!);
        if(currentStDate != currentEdDate){
          if(convertDate.isAfter(_startDate)){
            if(convertDate.isBefore(addDays(date: _endDate))){
              datePromotionDetail!.add(paidPromotionDetail[i]);
            }
          }
        } else {
          if(convertDate.isAfter(_startDate) && convertDate.isBefore(addDays(date: _endDate))){
            datePromotionDetail!.add(paidPromotionDetail[i]);
          }
        }
      }
      for (int j = 0; j < datePromotionDetail!.length; j++) {
        sumAllPromotionAmount(datePromotionDetail![j].promotion_amount!);
      }
    }
    ReportObject value = ReportObject(totalPromotionAmount: totalPromotionAmount, datePromotionDetail: datePromotionDetail);
    return value;
  }

  getAllRefundOrder({currentStDate, currentEdDate}) async {
    dateRefundOrderList = [];
    DateTime _startDate = DateTime.parse(currentStDate);
    DateTime _endDate = DateTime.parse(currentEdDate);
    //convert time to string
    DateTime addEndDate = addDays(date: _endDate);
    String stringStDate = new DateFormat("yyyy-MM-dd").format(_startDate);
    String stringEdDate = new DateFormat("yyyy-MM-dd").format(addEndDate);
    this.totalSales = 0.0;

    List<Order> orderData = await PosDatabase.instance.readAllRefundOrder(stringStDate, stringEdDate);
    paidOrderList = orderData;
    if (paidOrderList.isNotEmpty) {
      for (int i = 0; i < paidOrderList.length; i++) {
        dateRefundOrderList!.add(paidOrderList[i]);
        // DateTime convertDate = new DateFormat("yyyy-MM-dd HH:mm:ss").parse(paidOrderList[i].created_at!);
        // if(currentStDate != currentEdDate){
        //   if(convertDate.isAfter(_startDate)){
        //     if(convertDate.isBefore(addDays(date: _endDate))){
        //       dateRefundOrderList!.add(paidOrderList[i]);
        //     }
        //   }
        // } else {
        //   if(convertDate.isAfter(_startDate) && convertDate.isBefore(addDays(date: _endDate))){
        //     dateRefundOrderList!.add(paidOrderList[i]);
        //   }
        // }

      }
      for (int j = 0; j < dateRefundOrderList!.length; j++) {
        sumAllOrderTotal(dateRefundOrderList![j].final_amount!);
      }
    }
    ReportObject value = ReportObject(totalRefundAmount: totalSales, dateRefundOrderList: dateRefundOrderList);
    return value;
  }

  getAllCancelOrderDetail({currentStDate, currentEdDate}) async {
    dateOrderDetail = [];
    DateTime _startDate = DateTime.parse(currentStDate);
    DateTime _endDate = DateTime.parse(currentEdDate);
    List<OrderDetail> detailData = await PosDatabase.instance.readAllCancelItem();
    this.cancelledOrderDetail = detailData;
    if (cancelledOrderDetail.isNotEmpty) {
      for (int i = 0; i < cancelledOrderDetail.length; i++) {
        DateTime convertDate = new DateFormat("yyyy-MM-dd HH:mm:ss").parse(cancelledOrderDetail[i].created_at!);
        if(currentStDate != currentEdDate){
          if(convertDate.isAfter(_startDate)){
            if(convertDate.isBefore(addDays(date: _endDate))){
              dateOrderDetail!.add(cancelledOrderDetail[i]);
            }
          }
        } else {
          if(convertDate.isAfter(_startDate) && convertDate.isBefore(addDays(date: _endDate))){
            dateOrderDetail!.add(cancelledOrderDetail[i]);
          }
        }
      }
    }
    ReportObject value = ReportObject(dateOrderDetail: dateOrderDetail);
    return value;
  }

  getAllPaidOrderTaxDetail({currentStDate, currentEdDate}) async {
    branchTaxList = [];
    dateTaxDetail = [];
    DateTime _startDate = DateTime.parse(currentStDate);
    DateTime _endDate = DateTime.parse(currentEdDate);
    List<OrderTaxDetail> _taxData = await PosDatabase.instance.readAllPaidOrderTax();
    List<BranchLinkTax> _data = await PosDatabase.instance.readBranchLinkTax();
    if(_taxData.isNotEmpty){
      paidOrderTaxDetail = _taxData;
      for(int i = 0; i < paidOrderTaxDetail.length; i++){
        DateTime convertDate = new DateFormat("yyyy-MM-dd HH:mm:ss").parse(paidOrderTaxDetail[i].created_at!);
        if(currentStDate != currentEdDate){
          if(convertDate.isAfter(_startDate)){
            if(convertDate.isBefore(addDays(date: _endDate))){
              dateTaxDetail!.add(paidOrderTaxDetail[i]);
            }
          }
        } else {
          if(convertDate.isAfter(_startDate) && convertDate.isBefore(addDays(date: _endDate))){
            dateTaxDetail!.add(paidOrderTaxDetail[i]);
          }
        }
      }
      if(_data.isNotEmpty){
        branchTaxList = _data;
        for(int i = 0; i < branchTaxList!.length; i++){
          for(int j = 0; j < dateTaxDetail!.length; j++){
            if(branchTaxList![i].tax_id == dateTaxDetail![j].tax_id){
              branchTaxList![i].total_amount += double.parse(dateTaxDetail![j].tax_amount!);
            }
          }
        }
      }
    }
    ReportObject value = ReportObject(branchTaxList: branchTaxList, dateTaxDetail: dateTaxDetail);
    return value;
  }

  addDays({date}){
    var _date = date.add(Duration(days: 1));
    return _date;
  }

  sumAllPromotionAmount(String promotionAmount) {
    return this.totalPromotionAmount =  this.totalPromotionAmount! + double.parse(promotionAmount);
  }

  sumAllOrderTotal(String finalAmount) {
    return this.totalSales = this.totalSales! + double.parse(finalAmount);
  }
}