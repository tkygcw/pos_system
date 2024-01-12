import 'package:flutter/cupertino.dart';
import 'package:pos_system/database/pos_database.dart';
import 'package:pos_system/object/app_setting.dart';

class AppSettingModel extends ChangeNotifier {
  bool? directPaymentStatus;
  bool? autoPrintChecklist;
  bool? autoPrintReceipt;
  bool? show_sku;
  bool? enable_numbering;
  int? starting_number;
  bool? table_order;

  AppSettingModel({this.directPaymentStatus, this.autoPrintChecklist, this.autoPrintReceipt, this.show_sku, this.enable_numbering, this.starting_number, this.table_order});

  void initialLoad() async {
    AppSetting? data = await PosDatabase.instance.readAppSetting();
    if (data != null) {
      directPaymentStatus = data.direct_payment == 0 ? false : true;
      autoPrintChecklist = data.print_checklist == 0 ? false : true;
      autoPrintReceipt = data.print_receipt == 0 ? false : true;
      show_sku = data.show_sku == 0 ? false : true;
      enable_numbering = data.enable_numbering == null || data.enable_numbering == 0 ? false : true;
      starting_number = data.starting_number != null || data.starting_number != 0 ? data.starting_number : 0;
      table_order = data.table_order == 0 ? false : true;
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

  void setOrderNumberingStatus(bool status) {
    enable_numbering = status;
    notifyListeners();
  }

  void setTableOrderStatus(bool status) {
    table_order = status;
    notifyListeners();
  }
}
