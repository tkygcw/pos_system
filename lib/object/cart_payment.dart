import 'package:pos_system/object/promotion.dart';
import 'package:pos_system/object/tax.dart';

import 'order_promotion_detail.dart';
import 'order_tax_detail.dart';

class cartPaymentDetail {
  String localOrderId = '';
  double subtotal = 0.0;
  double amount = 0.00;
  double rounding = 0.0;
  String finalAmount = '';
  double paymentReceived = 0.0;
  double paymentChange = 0.0;
  List<OrderTaxDetail> orderTaxList = [];
  List<OrderPromotionDetail> orderPromotionDetail = [];
  List<Promotion>? promotionList = [];
  Promotion? manualPromo;
  List<Tax>? taxList = [];
  String? dining_name;

  cartPaymentDetail(
      String localOrderId,
      double subtotal,
      double amount,
      double rounding,
      String finalAmount,
      double paymentReceived,
      double paymentChange,
      List<OrderTaxDetail> orderTaxList,
      List<OrderPromotionDetail> orderPromotionDetail,
      {this.promotionList,
        this.manualPromo,
        this.taxList,
        this.dining_name})
  {
    this.localOrderId = localOrderId;
    this.subtotal = subtotal;
    this.amount = amount;
    this.rounding = rounding;
    this.finalAmount = finalAmount;
    this.paymentReceived = paymentReceived;
    this.paymentChange = paymentChange;
    this.orderTaxList = orderTaxList;
    this.orderPromotionDetail = orderPromotionDetail;
  }
}