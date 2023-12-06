import 'dart:async';

import 'package:confirm_dialog/confirm_dialog.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';
import 'package:pos_system/object/table.dart';
import 'package:pos_system/page/pos_pin.dart';
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
  Receipt? receiptObject;
  bool cashDrawer = false, secondDisplay = false, tableOrder = true, directPayment = false, showSKU = false;

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
        case 'direct_payment':{
          await updateDirectPaymentAppSetting();
          controller.refresh(streamController);
        }
        break;
        case 'show_sku':{
          await updateShowSKUAppSetting();
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

      if(appSetting.table_order == 1){
        this.tableOrder = true;
      } else {
        this.tableOrder = false;
      }

      if(appSetting.direct_payment == 1){
        this.directPayment = true;
      } else {
        this.directPayment = false;
      }

      if(appSetting.show_sku == 1){
        this.showSKU = true;
      } else {
        this.showSKU = false;
      }
    }
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
                            title: Text(AppLocalizations.of(context)!.translate('table_order')),
                            subtitle: Text(AppLocalizations.of(context)!.translate('table_order_desc')),
                            trailing: Switch(
                              value: this.tableOrder,
                              activeColor: color.backgroundColor,
                              onChanged: (value) async {
                                // switch on
                                if(value){
                                  this.tableOrder = value;
                                  if (await confirm(
                                    context,
                                    title: Text('${AppLocalizations.of(context)?.translate('disable_table_order')}'),
                                    content: Text('${AppLocalizations.of(context)?.translate('disable_table_order_desc')}'),
                                    textOK: Text('${AppLocalizations.of(context)?.translate('yes')}'),
                                    textCancel: Text('${AppLocalizations.of(context)?.translate('no')}'),
                                  )) {
                                    Navigator.of(context).pushAndRemoveUntil(
                                      MaterialPageRoute(
                                        builder: (BuildContext context) => PosPinPage(),
                                      ),
                                          (Route route) => false,
                                    );
                                    appSettingModel.setTableOrderStatus(tableOrder);
                                  } else
                                    this.tableOrder = !value;
                                } else{
                                  // switch off
                                  if(await anyTableUse()){
                                    Fluttertoast.showToast(msg: AppLocalizations.of(context)!.translate('please_settle_the_bill_for_all_tables'));
                                  } else if(appSettingModel.enable_numbering == false){
                                    Fluttertoast.showToast(msg: AppLocalizations.of(context)!.translate('please_enable_order_number'));
                                  } else if(appSettingModel.directPaymentStatus == false){
                                    Fluttertoast.showToast(msg: AppLocalizations.of(context)!.translate('please_enable_direct_payment'));
                                  } else {
                                    this.tableOrder = value;
                                    if (await confirm(
                                      context,
                                      title: Text('${AppLocalizations.of(context)?.translate('disable_table_order')}'),
                                      content: Text('${AppLocalizations.of(context)?.translate('disable_table_order_desc')}'),
                                      textOK: Text('${AppLocalizations.of(context)?.translate('yes')}'),
                                      textCancel: Text('${AppLocalizations.of(context)?.translate('no')}'),
                                    )) {
                                      Navigator.of(context).pushAndRemoveUntil(
                                        MaterialPageRoute(
                                          builder: (BuildContext context) => PosPinPage(),
                                        ),
                                            (Route route) => false,
                                      );
                                      appSettingModel.setTableOrderStatus(tableOrder);
                                    } else
                                      this.tableOrder = !value;
                                  }

                                  // else {
                                  //   if(appSettingModel.enable_numbering == false){
                                  //     Fluttertoast.showToast(msg: AppLocalizations.of(context)!.translate('please_enable_order_number'));
                                  //   }
                                  //   if(appSettingModel.directPaymentStatus == false){
                                  //     Fluttertoast.showToast(msg: AppLocalizations.of(context)!.translate('please_enable_direct_payment'));
                                  //   } else {
                                  //     this.tableOrder = value;
                                  //     if (await confirm(
                                  //       context,
                                  //       title: Text('${AppLocalizations.of(context)?.translate('disable_table_order')}'),
                                  //       content: Text('${AppLocalizations.of(context)?.translate('disable_table_order_desc')}'),
                                  //       textOK: Text('${AppLocalizations.of(context)?.translate('yes')}'),
                                  //       textCancel: Text('${AppLocalizations.of(context)?.translate('no')}'),
                                  //     )) {
                                  //       Navigator.of(context).pushAndRemoveUntil(
                                  //         MaterialPageRoute(
                                  //           builder: (BuildContext context) => PosPinPage(),
                                  //         ),
                                  //             (Route route) => false,
                                  //       );
                                  //       appSettingModel.setTableOrderStatus(tableOrder);
                                  //     } else
                                  //       this.tableOrder = !value;
                                  //   }
                                  // }
                                }


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
                          Divider(
                            color: Colors.grey,
                            height: 1,
                            thickness: 1,
                            indent: 20,
                            endIndent: 20,
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
                          ListTile(
                            title: Text(AppLocalizations.of(context)!.translate('reset_second_display')),
                            subtitle: Text(AppLocalizations.of(context)!.translate('reset_second_display_desc')),
                            trailing: ElevatedButton(
                                onPressed: () async {
                                  await displayManager.transferDataToPresentation("init");
                                },
                                child: Icon(Icons.reset_tv))
                          ),

                          Divider(
                            color: Colors.grey,
                            height: 1,
                            thickness: 1,
                            indent: 20,
                            endIndent: 20,
                          ),
                          ListTile(
                            title: Text(AppLocalizations.of(context)!.translate('place_order_payment')),
                            subtitle: Text(AppLocalizations.of(context)!.translate('direct_make_payment_when_oder_placed')),
                            trailing: Switch(
                              value: directPayment,
                              activeColor: color.backgroundColor,
                              onChanged: (value) {
                                // switch off
                                if(!value) {
                                  if(appSettingModel.table_order == false){
                                    Fluttertoast.showToast(msg: AppLocalizations.of(context)!.translate('please_enable_table_order'));
                                  } else {
                                    directPayment = value;
                                    appSettingModel.setDirectPaymentStatus(directPayment);
                                  }
                                } else {
                                  directPayment = value;
                                  appSettingModel.setDirectPaymentStatus(directPayment);
                                }
                                actionController.sink.add("direct_payment");
                              },
                            ),
                          ),
                          ListTile(
                            title: Text(AppLocalizations.of(context)!.translate('show_sku')),
                            subtitle: Text(AppLocalizations.of(context)!.translate('show_sku_desc')),
                            trailing: Switch(
                              value: showSKU,
                              activeColor: color.backgroundColor,
                              onChanged: (value) {
                                showSKU = value;
                                appSettingModel.setShowSKUStatus(showSKU);
                                actionController.sink.add("show_sku");
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
    DateFormat dateFormat = DateFormat("yyyy-MM-dd HH:mm:ss");
    String dateTime = dateFormat.format(DateTime.now());
    AppSetting object = AppSetting(
        open_cash_drawer: this.cashDrawer == true ? 1 : 0,
        show_second_display: this.secondDisplay == true ? 1 : 0,
        app_setting_sqlite_id: appSetting.app_setting_sqlite_id,
        table_order: this.tableOrder == true ? 1 : 0,
        updated_at: dateTime
    );
    int data = await PosDatabase.instance.updateAppSettings(object);
    if(object.show_second_display == 0){
      notificationModel.disableSecondDisplay();
    } else {
      notificationModel.enableSecondDisplay();
    }
  }

  updateDirectPaymentAppSetting() async {
    DateFormat dateFormat = DateFormat("yyyy-MM-dd HH:mm:ss");
    String dateTime = dateFormat.format(DateTime.now());
    AppSetting object = AppSetting(
        direct_payment: this.directPayment == true ? 1 : 0,
        app_setting_sqlite_id: appSetting.app_setting_sqlite_id,
        updated_at: dateTime
    );
    int data = await PosDatabase.instance.updateDirectPaymentSettings(object);
  }

  updateShowSKUAppSetting() async {
    DateFormat dateFormat = DateFormat("yyyy-MM-dd HH:mm:ss");
    String dateTime = dateFormat.format(DateTime.now());
    AppSetting object = AppSetting(
        show_sku: this.showSKU == true ? 1 : 0,
        app_setting_sqlite_id: appSetting.app_setting_sqlite_id,
        updated_at: dateTime
    );
    int data = await PosDatabase.instance.updateShowSKUSettings(object);
  }

  Future<bool> anyTableUse() async {
    List<PosTable> tableList = await PosDatabase.instance.readAllTable();
    for (int i = 0; i < tableList.length; i++) {
      if(tableList[i].status == 1)
        return true;
    }
    return false;
  }
}
