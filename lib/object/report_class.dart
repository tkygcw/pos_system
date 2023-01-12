import 'package:intl/intl.dart';

import '../database/pos_database.dart';
import 'order.dart';
import 'order_detail.dart';

class ReportObject{
  double? totalSales = 0.0;
  List<Order> paidOrderList = [];
  List<Order>? dateOrderList;
  List<Order>? dateRefundOrderList;
  List<OrderDetail> cancelledOrderDetail = [];
  List<OrderDetail>? dateOrderDetail;

  ReportObject(
      {this.totalSales,
      this.dateOrderList,
      this.dateOrderDetail,
      this.dateRefundOrderList});

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

  getAllRefundOrder({currentStDate, currentEdDate}) async {
    dateRefundOrderList = [];
    DateTime _startDate = DateTime.parse(currentStDate);
    DateTime _endDate = DateTime.parse(currentEdDate);
    this.totalSales = 0.0;
    List<Order> orderData = await PosDatabase.instance.readAllRefundOrder();
    print('paid order list in class: ${paidOrderList.length}');
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
    ReportObject value = ReportObject(totalSales: totalSales, dateRefundOrderList: dateRefundOrderList);
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

  addDays({date}){
    var _date = date.add(Duration(days: 1));
    return _date;
  }

  sumAllOrderTotal(String finalAmount) {
    return this.totalSales = this.totalSales! + double.parse(finalAmount);
  }
}