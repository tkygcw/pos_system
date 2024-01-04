import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';
import 'package:pos_system/database/pos_database.dart';
import 'package:pos_system/fragment/setting/kitchenlist_dialog.dart';
import 'package:pos_system/fragment/setting/receipt_dialog.dart';
import 'package:pos_system/page/progress_bar.dart';
import 'package:provider/provider.dart';

import '../../notifier/theme_color.dart';
import '../../object/receipt.dart';
import '../../translation/AppLocalizations.dart';
import '../../controller/controllerObject.dart';
import '../../object/app_setting.dart';
import '../../notifier/app_setting_notifier.dart';
import 'checklist_dialog.dart';

class ReceiptSetting extends StatefulWidget {
  const ReceiptSetting({Key? key}) : super(key: key);

  @override
  State<ReceiptSetting> createState() => _ReceiptSettingState();
}

class _ReceiptSettingState extends State<ReceiptSetting> {
  ControllerClass controller = ControllerClass();
  StreamController actionController = StreamController();
  TextEditingController orderNumberController = TextEditingController();
  AppSetting appSetting = AppSetting();
  late StreamController streamController;
  late Stream actionStream;
  // List<AppSetting> appSettingList = [];
  Receipt? receiptObject;
  bool printCheckList = false,
      enableNumbering = false,
      printReceipt = false;
  int startingNumber = 0, compareStartingNumber = 0;

  @override
  void initState() {
    super.initState();
    streamController = controller.hardwareSettingController;
    actionStream = actionController.stream.asBroadcastStream();
    listenAction();
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
      if(appSetting.print_checklist == 1){
        printCheckList = true;
      } else {
        printCheckList = false;
      }

      if(appSetting.print_receipt == 1){
        printReceipt = true;
      } else {
        printReceipt = false;
      }

      if(appSetting.enable_numbering == 1){
        enableNumbering = true;
      } else {
        enableNumbering = false;
      }

      if(appSetting.starting_number != 0){
        startingNumber = appSetting.starting_number!;
        orderNumberController.text = startingNumber.toString();
      } else {
        startingNumber = 0;
      }
      compareStartingNumber = startingNumber;
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

  Future<Future<Object?>> openStartingNumberDialog() async {
    return showGeneralDialog(
        barrierColor: Colors.black.withOpacity(0.5),
        transitionBuilder: (context, a1, a2, widget) {
          final curvedValue = Curves.easeInOutBack.transform(a1.value) - 1.0;
          return Center(
            child: SingleChildScrollView(
              physics: NeverScrollableScrollPhysics(),
              child: AlertDialog(
                title: Text(
                    AppLocalizations.of(context)!.translate('update_order_starting_number')),
                content: Column(
                  children: [
                    SizedBox(height: 20),
                    Container(
                      // Customize your Container's properties here
                      child: Center(
                        child: Text(
                            AppLocalizations.of(context)!.translate('current_order_starting_number') + " : ${appSetting.starting_number.toString().padLeft(4, '0')}"),
                      ),
                    ),
                    SizedBox(height: 40),
                    Container(
                      width: 400,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 273,
                            child: TextField(
                              autofocus: true,
                              controller: orderNumberController,
                              keyboardType: TextInputType.number,
                              inputFormatters: <TextInputFormatter>[FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(4)],
                              textAlign: TextAlign.center,
                              decoration: InputDecoration(
                                hintText: 'Example: 0050',
                                focusedBorder: OutlineInputBorder(
                                  borderSide: BorderSide(color: Colors.black.withOpacity(0.5)),
                                ),
                              ),
                              onChanged: (value) => setState(() {
                                try {
                                  startingNumber = int.parse(orderNumberController.text);
                                } catch (e) {
                                  startingNumber = 0;
                                }
                              }),
                              onSubmitted: (value) async {
                                await updateAppSetting();
                                Navigator.of(context).pop();
                              }
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                actions: <Widget>[
                  TextButton(
                    child: Text(
                        '${AppLocalizations.of(context)?.translate('close')}'),
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                  ),
                  TextButton(
                    child: Text(
                        '${AppLocalizations.of(context)?.translate('yes')}'),
                    onPressed: () async {
                      await updateAppSetting();
                      Navigator.of(context).pop();
                    },
                  ),
                ],
              ),
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

  Future<Future<Object?>> openKitchenlistDialog() async {
    return showGeneralDialog(
        barrierColor: Colors.black.withOpacity(0.5),
        transitionBuilder: (context, a1, a2, widget) {
          final curvedValue = Curves.easeInOutBack.transform(a1.value) - 1.0;
          return Transform(
            transform: Matrix4.translationValues(0.0, curvedValue * 200, 0.0),
            child: Opacity(
              opacity: a1.value,
              child: KitchenlistDialog(),
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
                            title: Text(AppLocalizations.of(context)!.translate('kitchen_list_setting')),
                            subtitle: Text(AppLocalizations.of(context)!.translate('customize_your_kitchen_list_look')),
                            trailing: Icon(Icons.navigate_next),
                            onTap: (){
                              openKitchenlistDialog();
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
                            title: Text(AppLocalizations.of(context)!.translate('auto_print_receipt')),
                            subtitle: Text(AppLocalizations.of(context)!.translate('auto_print_receipt_desc')),
                            trailing: Switch(
                              value: printReceipt,
                              activeColor: color.backgroundColor,
                              onChanged: (value) async {
                                printReceipt = value;
                                appSettingModel.setPrintReceiptStatus(printReceipt);
                                actionController.sink.add("switch");
                              },
                            ),
                          ),
                          ListTile(
                            title: Text(AppLocalizations.of(context)!.translate('order_numbering')),
                            subtitle: Text(AppLocalizations.of(context)!.translate('enable_order_numbering')),
                            trailing: Switch(
                              value: enableNumbering,
                              activeColor: color.backgroundColor,
                              onChanged: (value) async {
                                if(!value) {
                                  if(appSettingModel.table_order == false) {
                                    Fluttertoast.showToast(msg: AppLocalizations.of(context)!.translate('please_enable_table_order_in_general_setting'));
                                  } else {
                                    enableNumbering = value;
                                    appSettingModel.setOrderNumberingStatus(enableNumbering);
                                    actionController.sink.add("switch");
                                  }
                                } else {
                                  enableNumbering = value;
                                  appSettingModel.setOrderNumberingStatus(enableNumbering);
                                  actionController.sink.add("switch");
                                }
                              },
                            ),
                          ),
                          ListTile(
                            title: Text(AppLocalizations.of(context)!.translate('order_starting_number'),
                              style: TextStyle(
                                color: !enableNumbering ? Colors.grey : null,
                              )),
                            subtitle: Text(AppLocalizations.of(context)!.translate('default_order_starting_number'),
                                style: TextStyle(
                                  color: !enableNumbering ? Colors.grey : null,
                                )),
                            trailing: Text(startingNumber.toString()+'    ', style: TextStyle(color: !enableNumbering ? Colors.grey : null, fontWeight: FontWeight.w500)),
                            onTap: (){
                              if (enableNumbering) {
                                openStartingNumberDialog();
                              } else{
                                Fluttertoast.showToast(msg: AppLocalizations.of(context)!.translate('order_starting_number_required'));
                              }
                            },
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
    DateFormat dateFormat = DateFormat("yyyy-MM-dd HH:mm:ss");
    String dateTime = dateFormat.format(DateTime.now());
    AppSetting object = AppSetting(
        print_checklist: printCheckList == true ? 1 : 0,
        print_receipt: printReceipt == true ? 1 : 0,
        enable_numbering: enableNumbering == true ? 1 : 0,
        starting_number: startingNumber != 0 ? startingNumber : 0,
        app_setting_sqlite_id: appSetting.app_setting_sqlite_id,
        updated_at: dateTime
    );
    int data = await PosDatabase.instance.updateReceiptSettings(object);
    getAllAppSetting();
    if(compareStartingNumber != startingNumber){
      if(data == 1){
        Fluttertoast.showToast(
            backgroundColor: Color(0xFF24EF10),
            msg: AppLocalizations.of(context)!.translate('update_success'));
      } else{
        Fluttertoast.showToast(
            backgroundColor: Color(0xFFFF0000),
            msg: AppLocalizations.of(context)!.translate('fail_update'));
      }
    }
  }
}
