import 'package:flutter/cupertino.dart';

import '../object/order_detail.dart';

class FailPrintModel extends ChangeNotifier {
  List<OrderDetail> failedPrintOrderDetail = [];

  List<OrderDetail> get failPrint => failedPrintOrderDetail;

  void addFailedOrderDetail(OrderDetail orderDetail) {
    failedPrintOrderDetail.add(orderDetail);
    notifyListeners();
  }

  void addAllFailedOrderDetail({required List<OrderDetail> orderDetailList}) {
    failedPrintOrderDetail.addAll(orderDetailList);
    notifyListeners();
  }

  void removeFailedOrderDetail(OrderDetail orderDetail){
    failedPrintOrderDetail.remove(orderDetail);
    notifyListeners();
  }

  void removeAllFailedOrderDetail(){
    failedPrintOrderDetail.clear();
    notifyListeners();
  }

}