import '../../object/order_detail_cancel.dart';

class CancelRecordReportUtils {

  static String getCancelQtyFormat(OrderDetailCancel orderDetailCancel){
    if(orderDetailCancel.unit == 'each' || orderDetailCancel.unit == 'each_c'){
      return orderDetailCancel.quantity!;
    } else {
      if(orderDetailCancel.quantity_before_cancel != ''){
        return '${orderDetailCancel.quantity!}(${orderDetailCancel.quantity_before_cancel!})';
      } else {
        return '1(${double.parse(orderDetailCancel.quantity!).toStringAsFixed(2)})';
      }
    }
  }

  static String getProductVariant(OrderDetailCancel orderDetailCancel){
    if(orderDetailCancel.product_variant_name != null && orderDetailCancel.product_variant_name != ''){
      return '${orderDetailCancel.product_variant_name}';
    } else {
      return '';
    }
  }
}