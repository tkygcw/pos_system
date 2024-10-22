import 'package:flutter/cupertino.dart';
import 'package:pos_system/database/pos_database.dart';
import 'package:pos_system/object/app_setting.dart';

class AppSettingModel extends ChangeNotifier {
  static final AppSettingModel instance = AppSettingModel();
  bool? directPaymentStatus;
  bool? autoPrintChecklist;
  bool? autoPrintReceipt;
  bool? show_sku;
  bool? qr_order_auto_accept;
  bool? settlement_after_all_order_paid;
  bool? enable_numbering;
  int? starting_number;
  int? table_order;
  bool? show_product_desc;
  bool? autoPrintCancelReceipt;
  int? product_sort_by;
  int? dynamic_qr_default_exp_after_hour;
  int? variant_item_sort_by;
  bool? required_cancel_reason;

  AppSettingModel({
    this.directPaymentStatus,
    this.autoPrintChecklist,
    this.autoPrintReceipt,
    this.show_sku,
    this.qr_order_auto_accept,
    this.settlement_after_all_order_paid,
    this.enable_numbering,
    this.starting_number,
    this.table_order,
    this.show_product_desc,
    this.autoPrintCancelReceipt,
    this.product_sort_by,
    this.dynamic_qr_default_exp_after_hour,
    this.variant_item_sort_by,
    this.required_cancel_reason
  });

  void initialLoad() async {
    AppSetting? data = await PosDatabase.instance.readAppSetting();
    if (data != null) {
      directPaymentStatus = data.direct_payment == 0 ? false : true;
      autoPrintChecklist = data.print_checklist == 0 ? false : true;
      autoPrintReceipt = data.print_receipt == 0 ? false : true;
      show_sku = data.show_sku == 0 ? false : true;
      qr_order_auto_accept = data.qr_order_auto_accept == 0 ? false : true;
      settlement_after_all_order_paid = data.settlement_after_all_order_paid == 0 ? false : true;
      enable_numbering = data.enable_numbering == null || data.enable_numbering == 0 ? false : true;
      starting_number = data.starting_number != null || data.starting_number != 0 ? data.starting_number : 0;
      table_order = data.table_order;
      show_product_desc = data.show_product_desc == 0 ? false : true;
      autoPrintCancelReceipt = data.print_cancel_receipt == 0 ? false : true;
      product_sort_by = data.product_sort_by;
      dynamic_qr_default_exp_after_hour = data.dynamic_qr_default_exp_after_hour;
      variant_item_sort_by = data.variant_item_sort_by;
      required_cancel_reason = data.required_cancel_reason == 1 ? true : false;
    }
  }

  void setDirectPaymentStatus(bool status) {
    directPaymentStatus = status;
    notifyListeners();
  }

  void setPrintChecklistStatus(bool status) {
    autoPrintChecklist = status;
    notifyListeners();
  }

  void setPrintReceiptStatus(bool status) {
    autoPrintReceipt = status;
    notifyListeners();
  }

  void setShowSKUStatus(bool status) {
    show_sku = status;
    notifyListeners();
  }

  void setQrOrderAutoAcceptStatus(bool status) {
    qr_order_auto_accept = status;
    notifyListeners();
  }

  void setSettlementAfterAllOrderPaidStatus(bool status) {
    settlement_after_all_order_paid = status;
    notifyListeners();
  }

  void setOrderNumberingStatus(bool status) {
    enable_numbering = status;
    notifyListeners();
  }

  void setTableOrderStatus(int status) {
    table_order = status;
    notifyListeners();
  }

  void setShowProductDescStatus(bool status) {
    show_product_desc = status;
    notifyListeners();
  }

  void setAutoPrintCancelReceiptStatus(bool status) {
    autoPrintCancelReceipt = status;
    notifyListeners();
  }

  void setProductSortByStatus(int status) {
    product_sort_by = status;
    notifyListeners();
  }

  void setVariantItemSortByStatus(int status) {
    variant_item_sort_by = status;
    notifyListeners();
  }

  void setRequiredCancelReasonStatus(bool status) {
    required_cancel_reason = status;
    notifyListeners();
  }

  void setDynamicQrDefaultExpAfterHour(int hour) {
    dynamic_qr_default_exp_after_hour = hour;
    notifyListeners();
  }
}
