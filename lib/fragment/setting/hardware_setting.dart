import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:pos_system/fragment/setting/receipt_dialog.dart';
import 'package:provider/provider.dart';

import '../../database/pos_database.dart';
import '../../main.dart';
import '../../notifier/theme_color.dart';
import '../../object/app_setting.dart';
import '../../object/receipt.dart';
import '../../page/progress_bar.dart';
import '../../translation/AppLocalizations.dart';

class HardwareSetting extends StatefulWidget {
  const HardwareSetting({Key? key}) : super(key: key);

  @override
  State<HardwareSetting> createState() => _HardwareSettingState();
}

class _HardwareSettingState extends State<HardwareSetting> {
  List<AppSetting> appSettingList = [];
  Receipt? receiptObject;
  bool cashDrawer = false, secondDisplay = false;
  bool _isLoaded = false;

  @override
  void initState() {
    super.initState();
    getAllAppSetting();
    read80mmReceiptLayout();
  }

  read80mmReceiptLayout() async {
    Receipt? data = await PosDatabase.instance.readSpecificReceipt("80");
    if(data != null){
      receiptObject = data;
    }
  }

  getAllAppSetting() async {
    List<AppSetting> data = await PosDatabase.instance.readAllAppSetting();
    if(data.length > 0){
      appSettingList = List.from(data);
      if(appSettingList[0].open_cash_drawer == 1){
        this.cashDrawer = true;
      } else {
        this.cashDrawer = false;
      }

      if(appSettingList[0].show_second_display == 1){
        this.secondDisplay = true;
      } else {
        this.secondDisplay = false;
      }
    }
    setState(() {
      _isLoaded = true;
    });
  }

  Future<Future<Object?>> openReceiptDialog() async {
    return showGeneralDialog(
        barrierColor: Colors.black.withOpacity(0.5),
        transitionBuilder: (context, a1, a2, widget) {
          final curvedValue = Curves.easeInOutBack.transform(a1.value) - 1.0;
          return Transform(
            transform: Matrix4.translationValues(0.0, curvedValue * 200, 0.0),
            child: Opacity(
                opacity: a1.value,
                child: ReceiptDialog(
                  callBack: () => read80mmReceiptLayout(),
                  receiptObject: receiptObject,
                )
            ),
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

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeColor>(builder: (context, ThemeColor color, child) {
      return Scaffold(
        body: _isLoaded ?
        SingleChildScrollView(
          child: Column(
            children: [
              ListTile(
                title: Text(AppLocalizations.of(context)!.translate('receipt_setting')),
                subtitle: Text(AppLocalizations.of(context)!.translate('customize_your_receipt_look')),
                trailing: Icon(Icons.navigate_next),
                onTap: (){
                  openReceiptDialog();
                },
              ),
              ListTile(
                title: Text(AppLocalizations.of(context)!.translate('auto_open_cash_drawer')),
                subtitle: Text(AppLocalizations.of(context)!.translate('auto_open_cash_drawer_after_insert_opening_balance')),
                trailing: Switch(
                  value: this.cashDrawer,
                  activeColor: color.backgroundColor,
                  onChanged: (value) async {
                    await getAllAppSetting();
                    setState(() {
                      this.cashDrawer = value;
                    });
                    if(appSettingList.isEmpty){
                      await createAppSetting();
                    } else {
                      await updateAppSetting();
                    }
                  },
                ),
              ),
              ListTile(
                title: Text(AppLocalizations.of(context)!.translate('enable_Second_display')),
                subtitle: Text(AppLocalizations.of(context)!.translate('show_device_second_display')),
                trailing: Switch(
                  value: this.secondDisplay,
                  activeColor: color.backgroundColor,
                  onChanged: (value) async {
                    if(notificationModel.hasSecondScreen == false){
                      Fluttertoast.showToast(msg: "${AppLocalizations.of(context)?.translate('no_second_display')}");
                      return;
                    }
                    await getAllAppSetting();
                    setState(() {
                      this.secondDisplay = value;
                    });
                    if(appSettingList.length == 0){
                      await createAppSetting();
                    } else {
                      await updateAppSetting();
                    }
                  },
                ),
              ),
            ],
          ),
        ) : CustomProgressBar(),
      );
    });
  }

  updateAppSetting() async {
    print('update called');
    AppSetting appSetting = AppSetting(
        open_cash_drawer: this.cashDrawer == true ? 1 : 0,
        show_second_display: this.secondDisplay == true ? 1 : 0,
        app_setting_sqlite_id: appSettingList[0].app_setting_sqlite_id
    );
    int data = await PosDatabase.instance.updateAppSettings(appSetting);
    if(appSetting.show_second_display == 0){
      notificationModel.disableSecondDisplay();
    } else {
      notificationModel.enableSecondDisplay();
    }
  }

  createAppSetting() async {
    AppSetting appSetting = AppSetting(
        open_cash_drawer: this.cashDrawer ? 1 : 0,
        show_second_display: this.secondDisplay ? 1 : 0

    );
    AppSetting data = await PosDatabase.instance.insertSetting(appSetting);
  }
}
