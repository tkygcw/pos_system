import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../database/pos_database.dart';
import '../object/color.dart';

class ThemeColor extends ChangeNotifier {
  List<AppColors> colorList = [];
  ThemeColor() {
    initialLoad();
  }

//default color first login
  Color backgroundColor = Color(0xff0d5060);

  // Color _buttonColor = Color(0xfff06292);
  Color buttonColor = Color(0xff39817d);

  // Color _iconColor = Color(0xffffd54f);
  Color iconColor = Color(0xffa1ffcf);



  void initialLoad() async {
    await readAllColor();
    if(colorList.length <= 0){
      createAppColors();
    }else {
      backgroundColor = hexToColor(colorList[0].background_color!);
      buttonColor = hexToColor(colorList[0].button_color!);
      iconColor = hexToColor(colorList[0].icon_color!);
      notifyListeners();
    }

  }

  void changeColor(appColor, appColor2, appColor3) async {
    backgroundColor = appColor;
    buttonColor = appColor2;
    iconColor = appColor3;
    updateAppColor(appColor, appColor2, appColor3);
    notifyListeners();
  }

  updateAppColor(appColor, appColor2, appColor3 ) async {
    List<AppColors> data = await PosDatabase.instance.readAppColors();
    if(data.length >= 0) {
      DateFormat dateFormat = DateFormat("yyyy-MM-dd HH:mm:ss");
      String dateTime = dateFormat.format(DateTime.now());

      AppColors colorData = AppColors(
          app_color_sqlite_id: 1,
          background_color: '#'+appColor.value.toRadixString(16).substring(2),
          button_color: '#'+appColor2.value.toRadixString(16).substring(2),
          icon_color: '#'+appColor3.value.toRadixString(16).substring(2),
          updated_at: dateTime);
      int data = await PosDatabase.instance.updateAppColor(colorData);
    }
  }

  readAllColor() async {
    List<AppColors> data = await PosDatabase.instance.readAppColors();
    return colorList = data;
  }

  createAppColors() async {
    List<AppColors> data =
    await PosDatabase.instance.readAppColors();
    if (data.length <= 0) {
      DateFormat dateFormat = DateFormat("yyyy-MM-dd HH:mm:ss");
      String dateTime = dateFormat.format(DateTime.now());

      AppColors appColors = await PosDatabase.instance.insertColor(AppColors(
          app_color_id: 0,
          background_color: '#' +
              ThemeColor().backgroundColor.value.toRadixString(16).substring(2),
          button_color: '#' +
              ThemeColor().buttonColor.value.toRadixString(16).substring(2),
          icon_color: '#' +
              ThemeColor().iconColor.value.toRadixString(16).substring(2),
          created_at: dateTime,
          updated_at: '',
          soft_delete: ''
      ));
    }
  }

  Color hexToColor(String hexCode) {
    return new Color(int.parse(hexCode.substring(1, 7), radix: 16) + 0xFF000000);
  }




}
