import 'dart:async';

import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:pos_system/fragment/setting/receipt_dialog.dart';
import 'package:provider/provider.dart';

import '../../controller/controllerObject.dart';
import '../../database/pos_database.dart';
import '../../main.dart';
import '../../notifier/app_setting_notifier.dart';
import '../../notifier/theme_color.dart';
import '../../object/app_setting.dart';
import '../../object/receipt.dart';
import '../../page/progress_bar.dart';
import '../../translation/AppLocalizations.dart';
import 'checklist_dialog.dart';

class HardwareSetting extends StatefulWidget {
  const HardwareSetting({Key? key}) : super(key: key);

  @override
  State<HardwareSetting> createState() => _HardwareSettingState();
}

class _HardwareSettingState extends State<HardwareSetting> {
  ControllerClass controller = ControllerClass();
  StreamController actionController = StreamController();
  AppSetting appSetting = AppSetting();
  late StreamController streamController;
  late Stream actionStream;
  // List<AppSetting> appSettingList = [];
  Receipt? receiptObject;
  bool cashDrawer = false, secondDisplay = false, printCheckList = false;
  bool _isLoaded = false;

  @override
  void initState() {
    super.initState();
    streamController = controller.hardwareSettingController;
    actionStream = actionController.stream.asBroadcastStream();
    listenAction();
    // getAllAppSetting();
    // read80mmReceiptLayout();
  }

  listenAction(){
    actionController.sink.add("init");
    actionStream.listen((event) async {
      switch(event){
        case 'init':{
          await getAllAppSetting();
          await read80mmReceiptLayout();
          controller.refresh(streamController);
        }
        break;
        case 'switch':{
          await updateAppSetting();
          controller.refresh(streamController);
        }
        break;
      }
    });
  }

  read80mmReceiptLayout() async {
    Receipt? data = await PosDatabase.instance.readSpecificReceipt("80");
    if(data != null){
      receiptObject = data;
    }
  }

  getAllAppSetting() async {
    AppSetting? data = await PosDatabase.instance.readAppSetting();
    if(data != null){
      appSetting = data;
      if(appSetting.open_cash_drawer == 1){
        this.cashDrawer = true;
      } else {
        this.cashDrawer = false;
      }

      if(appSetting.show_second_display == 1){
        this.secondDisplay = true;
      } else {
        this.secondDisplay = false;
      }

      if(appSetting.print_checklist == 1){
        printCheckList = true;
      } else {
        printCheckList = false;
      }
    }
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

  Future<Future<Object?>> openChecklistDialog() async {
    return showGeneralDialog(
        barrierColor: Colors.black.withOpacity(0.5),
        transitionBuilder: (context, a1, a2, widget) {
          final curvedValue = Curves.easeInOutBack.transform(a1.value) - 1.0;
          return Transform(
            transform: Matrix4.translationValues(0.0, curvedValue * 200, 0.0),
            child: Opacity(
                opacity: a1.value,
                child: ChecklistDialog(),
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
      return Consumer<AppSettingModel>(builder: (context, AppSettingModel appSettingModel, child) {
        return Scaffold(
            body: StreamBuilder(
                stream: controller.hardwareSettingStream,
                builder: (context, snapshot){
                  if(snapshot.hasData){
                    return SingleChildScrollView(
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
                            title: Text(AppLocalizations.of(context)!.translate('check_list_setting')),
                            subtitle: Text(AppLocalizations.of(context)!.translate('customize_your_check_list_look')),
                            trailing: Icon(Icons.navigate_next),
                            onTap: (){
                              openChecklistDialog();
                            },
                          ),
                          ListTile(
                            title: Text(AppLocalizations.of(context)!.translate('auto_print_checklist')),
                            subtitle: Text(AppLocalizations.of(context)!.translate('auto_print_checklist_desc')),
                            trailing: Switch(
                              value: printCheckList,
                              activeColor: color.backgroundColor,
                              onChanged: (value) async {
                                printCheckList = value;
                                appSettingModel.setPrintChecklistStatus(printCheckList);
                                actionController.sink.add("switch");
                              },
                            ),
                          ),
                          ListTile(
                            title: Text(AppLocalizations.of(context)!.translate('auto_open_cash_drawer')),
                            subtitle: Text(AppLocalizations.of(context)!.translate('auto_open_cash_drawer_after_insert_opening_balance')),
                            trailing: Switch(
                              value: this.cashDrawer,
                              activeColor: color.backgroundColor,
                              onChanged: (value) async {
                                this.cashDrawer = value;
                                actionController.sink.add("switch");
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
                                this.secondDisplay = value;
                                actionController.sink.add("switch");
                              },
                            ),
                          ),
                        ],
                      ),
                    );
                  } else {
                    return CustomProgressBar();
                  }
                }
            )

        );
      });
    });
  }

  updateAppSetting() async {
    print('update called');
    AppSetting object = AppSetting(
        open_cash_drawer: this.cashDrawer == true ? 1 : 0,
        show_second_display: this.secondDisplay == true ? 1 : 0,
        print_checklist: printCheckList == true ? 1 : 0,
        app_setting_sqlite_id: appSetting.app_setting_sqlite_id
    );
    int data = await PosDatabase.instance.updateAppSettings(object);
    if(object.show_second_display == 0){
      notificationModel.disableSecondDisplay();
    } else {
      notificationModel.enableSecondDisplay();
    }
  }
}
