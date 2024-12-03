import '../../object/order_detail_cancel.dart';

class CancelRecordReportUtils {

  static String getCancelQtyFormat(OrderDetailCancel orderDetailCancel){
    if(orderDetailCancel.unit == 'each' || orderDetailCancel.unit == 'each_c'){
      return orderDetailCancel.quantity!;
    } else {
      if(orderDetailCancel.quantity_before_cancel != ''){
        return '${orderDetailCancel.quantity!}/'
            '${totalUnitQty(orderDetailCancel.quantity_before_cancel!, orderDetailCancel.per_quantity_unit!).toStringAsFixed(2)}'
            '(${orderDetailCancel.unit})';
      } else {
        return '1/${totalUnitQty(orderDetailCancel.quantity!, orderDetailCancel.per_quantity_unit!).toStringAsFixed(2)}(${orderDetailCancel.unit})';
      }
    }
  }

  static double totalUnitQty(String qtyBeforeCancel, String per_quantity_unit){
    double parsedQtyBeforeCancel = double.parse(qtyBeforeCancel);
    double parsedPerQtyUnit = double.parse(per_quantity_unit);
    return parsedQtyBeforeCancel * parsedPerQtyUnit;
  }

  static String getProductVariant(OrderDetailCancel orderDetailCancel){
    if(orderDetailCancel.product_variant_name != null && orderDetailCancel.product_variant_name != ''){
      return '${orderDetailCancel.product_variant_name}';
    } else {
      return '';
    }
  }
}