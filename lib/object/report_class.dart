import 'package:intl/intl.dart';

import '../database/pos_database.dart';
import 'branch_link_tax.dart';
import 'order.dart';
import 'order_detail.dart';
import 'order_promotion_detail.dart';
import 'order_tax_detail.dart';

class ReportObject{
  double? totalSales = 0.0, totalRefundAmount = 0.0;
  double? totalPromotionAmount = 0.0;
  List<Order> paidOrderList = [];
  List<Order>? dateOrderList;
  List<Order>? dateRefundOrderList;
  List<OrderDetail> cancelledOrderDetail = [];
  List<OrderDetail>? dateOrderDetail;
  List<OrderPromotionDetail> paidPromotionDetail = [];
  List<OrderPromotionDetail>? datePromotionDetail = [];
  List<OrderTaxDetail> paidOrderTaxDetail = [], dateTaxDetail = [];
  List<BranchLinkTax>? branchTaxList = [];

  ReportObject(
      {this.totalSales,
      this.totalRefundAmount,
      this.totalPromotionAmount,
      this.dateOrderList,
      this.dateOrderDetail,
      this.dateRefundOrderList,
      this.datePromotionDetail,
      this.branchTaxList});

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
        if(dateOrderList![j].payment_status != 2){
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
    this.totalSales = 0.0;

    List<Order> orderData = await PosDatabase.instance.readAllRefundOrder();
    paidOrderList = orderData;
    if (paidOrderList.isNotEmpty) {
      for (int i = 0; i < paidOrderList.length; i++) {
        DateTime convertDate = new DateFormat("yyyy-MM-dd HH:mm:ss").parse(paidOrderList[i].created_at!);
        if(currentStDate != currentEdDate){
          if(convertDate.isAfter(_startDate)){
            if(convertDate.isBefore(addDays(date: _endDate))){
              dateRefundOrderList!.add(paidOrderList[i]);
            }
          }
        } else {
          if(convertDate.isAfter(_startDate) && convertDate.isBefore(addDays(date: _endDate))){
            dateRefundOrderList!.add(paidOrderList[i]);
          }
        }

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
              dateTaxDetail.add(paidOrderTaxDetail[i]);
            }
          }
        } else {
          if(convertDate.isAfter(_startDate) && convertDate.isBefore(addDays(date: _endDate))){
            dateTaxDetail.add(paidOrderTaxDetail[i]);
          }
        }
      }
      if(_data.isNotEmpty){
        branchTaxList = _data;
        for(int i = 0; i < branchTaxList!.length; i++){
          for(int j = 0; j < dateTaxDetail.length; j++){
            if(branchTaxList![i].tax_id == dateTaxDetail[j].tax_id){
              branchTaxList![i].total_amount += double.parse(dateTaxDetail[j].tax_amount!);
            }
          }
        }
      }
    }
    ReportObject value = ReportObject(branchTaxList: branchTaxList);
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