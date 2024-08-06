import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:pos_system/fragment/choose_qr_type_dialog.dart';
import 'package:pos_system/fragment/setting/table_setting/table_setting_mobile.dart';
import 'package:pos_system/fragment/setting/table_setting/table_setting_tablet.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../notifier/theme_color.dart';
import '../../../object/table.dart';
import '../../../translation/AppLocalizations.dart';

class TableSetting extends StatefulWidget {
  const TableSetting({Key? key}) : super(key: key);

  @override
  State<TableSetting> createState() => _TableSettingState();
}

class _TableSettingState extends State<TableSetting> {

  bool hasAccess = true;

  @override
  void initState() {
    super.initState();
    checkStatus();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    if(hasAccess){
      return Consumer<ThemeColor>(builder: (context, ThemeColor color, child) {
        if(screenWidth > 800 && screenHeight > 500){
          return TableSettingTablet(themeColor: color, openChooseQrDialog: openChooseQRDialog);
        } else {
          return TableSettingMobile(themeColor: color, openChooseQrDialog: openChooseQRDialog);
        }
      });
    } else {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.lock),
          Text(AppLocalizations.of(context)!.translate('upgrade_to_use_qr_order'))
        ],
      );
    }
  }

  Future<Future<Object?>> openChooseQRDialog(List<PosTable> selectedTable, Function() callback) async {
    return showGeneralDialog(
        barrierColor: Colors.black.withOpacity(0.5),
        transitionBuilder: (context, a1, a2, widget) {
          final curvedValue = Curves.easeInOutBack.transform(a1.value) - 1.0;
          return Transform(
            transform: Matrix4.translationValues(0.0, curvedValue * 200, 0.0),
            child: ChooseQrTypeDialog(posTableList: selectedTable, callback: callback,),
          );
        },
        transitionDuration: Duration(milliseconds: 200),
        barrierDismissible: false,
        context: context,
        pageBuilder: (context, animation1, animation2) {
          // ignore: null_check_always_fails
          return null!;
        });
  }

  Future<void> checkStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final String? branch = prefs.getString('branch');
    Map branchObject = json.decode(branch!);
    if(branchObject['qr_order_status'] == '1'){
      setState(() {
        hasAccess = false;
      });
    }
  }
}
