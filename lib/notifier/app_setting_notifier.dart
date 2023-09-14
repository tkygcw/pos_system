import 'package:flutter/cupertino.dart';
import 'package:pos_system/database/pos_database.dart';
import 'package:pos_system/object/app_setting.dart';

class AppSettingModel extends ChangeNotifier{
  bool? directPaymentStatus;
  bool? autoPrintChecklist;
  bool? show_sku;

  AppSettingModel({this.directPaymentStatus, this.autoPrintChecklist, this.show_sku});

  void initialLoad() async {
    AppSetting? data = await PosDatabase.instance.readAppSetting();
    if(data != null){
      directPaymentStatus = data.direct_payment == 0 ? false : true;
      autoPrintChecklist = data.print_checklist == 0 ? false : true;
      show_sku = data.show_sku == 0 ? false : true;
    }
  }

  void setDirectPaymentStatus(bool status){
    directPaymentStatus = status;
    notifyListeners();
  }

  void setPrintChecklistStatus(bool status){
    autoPrintChecklist = status;
    notifyListeners();
  }

  void setShowSKUStatus(bool status){
    show_sku = status;
    notifyListeners();
  }
}