import 'package:flutter/cupertino.dart';

import '../object/order_detail.dart';

class FailPrintModel extends ChangeNotifier {
  static final FailPrintModel instance = FailPrintModel.init();
  List<OrderDetail> failedPrintOrderDetail = [];
  FailPrintModel.init();

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

  void removeOrderDetailWithList(List<OrderDetail> orderDetail){
    for(int i = 0; i < orderDetail.length; i++){
      failedPrintOrderDetail.removeWhere((e) => e.order_detail_sqlite_id == orderDetail[i].order_detail_sqlite_id);
    }
    notifyListeners();
  }

  void removeAllFailedOrderDetail(){
    failedPrintOrderDetail.clear();
    notifyListeners();
  }

}