import 'dart:async';
import 'dart:convert';

import 'package:confirm_dialog/confirm_dialog.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';
import 'package:pos_system/object/order.dart';
import 'package:pos_system/fragment/setting/adjust_hour_dialog.dart';
import 'package:pos_system/object/table.dart';
import 'package:pos_system/page/pos_pin.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  final List<String> sortBy = [
    'default',
    'product_name',
    'product_sku',
    'product_price',
    'product_name_seq_desc',
    'product_sku_seq_desc',
    'product_price_seq_desc'
  ];
  final List<String> tableModeOption = [
    'table_mode_no_table',
    'table_mode_full_table',
    'table_mode_no_table_special'
  ];
  int? selectedValue = 0;
  int? tableMode = 0;
  bool cashDrawer = false, secondDisplay = false, directPayment = false, showSKU = false,
      qrOrderAutoAccept = false, showProductDesc = false, hasQrAccess = true;
  // String? tableMode;


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
          await checkStatus();
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
        case 'show_pro_desc':{
          await updateShowProDescAppSetting();
          controller.refresh(streamController);
        }
        break;
        case 'qr_order_auto_accept':{
          await updateQrOrderAutoAcceptAppSetting();
          controller.refresh(streamController);
        }
        break;
        case 'prod_sort_by':{
          await updateProductSortBySetting();
          controller.refresh(streamController);
        }
        break;
      }
    });
  }

  Future<void> checkStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final String? branch = prefs.getString('branch');
    Map branchObject = json.decode(branch!);
    if(branchObject['qr_order_status'] == '1'){
      hasQrAccess = false;
    }
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

      if(appSetting.table_order != null) {
        tableMode = appSetting.table_order!;
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

      if(appSetting.qr_order_auto_accept == 1){
        this.qrOrderAutoAccept = true;
      } else {
        this.qrOrderAutoAccept = false;
      }

      if(appSetting.show_product_desc == 1){
        this.showProductDesc = true;
      } else {
        this.showProductDesc = false;
      }
      if(appSetting.product_sort_by != null){
        selectedValue = appSetting.product_sort_by!;
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
                            title: Text(AppLocalizations.of(context)!.translate('table_mode')),
                            subtitle: Text(AppLocalizations.of(context)!.translate('table_mode_desc')),
                            trailing: SizedBox(
                              width: 200,
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton2(
                                  isExpanded: true,
                                  buttonStyleData: ButtonStyleData(
                                    height: 55,
                                    padding: const EdgeInsets.only(left: 14, right: 14),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(5),
                                      border: Border.all(
                                        color: Colors.black26,
                                      ),
                                    ),
                                  ),
                                  dropdownStyleData: DropdownStyleData(
                                    maxHeight: 200,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(10),
                                      color: Colors.grey.shade100,
                                    ),
                                    scrollbarTheme: ScrollbarThemeData(
                                        thickness: WidgetStateProperty.all(5),
                                        mainAxisMargin: 20,
                                        crossAxisMargin: 5
                                    ),
                                  ),
                                  items: tableModeOption.asMap().entries.map((tableOption) => DropdownMenuItem<int>(
                                    value: tableOption.key,
                                    child: Text(
                                      AppLocalizations.of(context)!.translate(tableOption.value),
                                      overflow: TextOverflow.visible,
                                      style: const TextStyle(
                                        fontSize: 14,
                                      ),
                                    ),
                                  )).toList(),
                                  value: tableMode,
                                  onChanged: (int? newValue) async{
                                    if (appSettingModel.table_order != newValue) {
                                      if (appSettingModel.table_order == 1) {
                                        // switch off
                                        if (await anyTableUse()) {
                                          Fluttertoast.showToast(
                                              msg: AppLocalizations.of(context)!.translate('please_settle_the_bill_for_all_tables'));
                                        } else if (appSettingModel.enable_numbering == false) {
                                          Fluttertoast.showToast(
                                              msg: AppLocalizations.of(context)!.translate('please_enable_order_number'));
                                        } else if (appSettingModel.directPaymentStatus == false) {
                                          Fluttertoast.showToast(
                                              msg: AppLocalizations.of(context)!.translate('please_enable_direct_payment'));
                                        } else {
                                          if (await confirm(
                                            context,
                                            title: Text('${AppLocalizations.of(context)?.translate('table_mode')}'),
                                            content: Text('${AppLocalizations.of(context)?.translate('disable_table_order_desc')}'),
                                            textOK: Text('${AppLocalizations.of(context)?.translate('yes')}'),
                                            textCancel: Text('${AppLocalizations.of(context)?.translate('no')}'),
                                          )) {
                                            tableMode = newValue;
                                            Navigator.of(context).pushAndRemoveUntil(
                                              MaterialPageRoute(
                                                builder: (BuildContext context) => PosPinPage(),
                                              ),
                                                  (Route route) => false,
                                            );
                                            appSettingModel.setTableOrderStatus(tableMode!);
                                          }
                                        }
                                        newValue = appSettingModel.table_order;
                                      } else {
                                        if (await confirm(
                                          context,
                                          title: Text('${AppLocalizations.of(context)?.translate('table_mode')}'),
                                          content: Text('${AppLocalizations.of(context)?.translate('disable_table_order_desc')}'),
                                          textOK: Text('${AppLocalizations.of(context)?.translate('yes')}'),
                                          textCancel: Text('${AppLocalizations.of(context)?.translate('no')}'),
                                        )) {
                                          tableMode = newValue;
                                          Navigator.of(context).pushAndRemoveUntil(
                                            MaterialPageRoute(
                                              builder: (BuildContext context) => PosPinPage(),
                                            ),
                                                (Route route) => false,
                                          );
                                          appSettingModel.setTableOrderStatus(tableMode!);
                                        }
                                      }
                                      actionController.sink.add("switch");
                                    }
                                  },
                                ),
                              ),
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
                                  if(appSettingModel.table_order != 1){
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
                          ListTile(
                            title: Text(AppLocalizations.of(context)!.translate('show_product_desc')),
                            subtitle: Text(AppLocalizations.of(context)!.translate('show_product_desc_desc')),
                            trailing: Switch(
                              value: showProductDesc,
                              activeColor: color.backgroundColor,
                              onChanged: (value) {
                                showProductDesc = value;
                                appSettingModel.setShowProductDescStatus(showProductDesc);
                                actionController.sink.add("show_pro_desc");
                              },
                            ),
                          ),
                          ListTile(
                            title: Text(AppLocalizations.of(context)!.translate('product_sort_by')),
                            subtitle: Text(AppLocalizations.of(context)!.translate('product_sort_by_desc')),
                            trailing: SizedBox(
                              width: 200,
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton2(
                                  isExpanded: true,
                                  buttonStyleData: ButtonStyleData(
                                    height: 55,
                                    padding: const EdgeInsets.only(left: 14, right: 14),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(5),
                                      border: Border.all(
                                        color: Colors.black26,
                                      ),
                                    ),
                                  ),
                                  dropdownStyleData: DropdownStyleData(
                                    maxHeight: 200,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(10),
                                      color: Colors.grey.shade100,
                                    ),
                                    scrollbarTheme: ScrollbarThemeData(
                                        thickness: WidgetStateProperty.all(5),
                                        mainAxisMargin: 20,
                                        crossAxisMargin: 5
                                    ),
                                  ),
                                  items: sortBy.asMap().entries.map((sort) => DropdownMenuItem<int>(
                                    value: sort.key,
                                    child: Text(
                                      AppLocalizations.of(context)!.translate(sort.value),
                                      overflow: TextOverflow.visible,
                                      style: const TextStyle(
                                        fontSize: 14,
                                      ),
                                    ),
                                  )).toList(),
                                  value: selectedValue,
                                  onChanged: (int? value) {
                                    selectedValue = value;
                                    actionController.sink.add("prod_sort_by");
                                    Provider.of<AppSettingModel>(context, listen: false).setProductSortByStatus(value!);
                                  },
                                ),
                              ),
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
                            title: Text(AppLocalizations.of(context)!.translate('auto_accept_qr_order'), style: TextStyle(color: !hasQrAccess ? Colors.grey: null)),
                            subtitle: Text(AppLocalizations.of(context)!.translate('auto_accept_qr_order_desc')),
                            trailing: Switch(
                              value: qrOrderAutoAccept,
                              activeColor: color.backgroundColor,
                              onChanged: hasQrAccess ? (value) {
                                qrOrderAutoAccept = value;
                                appSettingModel.setQrOrderAutoAcceptStatus(qrOrderAutoAccept);
                                actionController.sink.add("qr_order_auto_accept");
                              } : null
                            ),
                          ),
                          ListTile(
                            title: Text(AppLocalizations.of(context)!.translate('set_default_exp_after_hour'), style: TextStyle(color: !hasQrAccess ? Colors.grey: null)),
                            subtitle: Text(AppLocalizations.of(context)!.translate('set_default_exp_after_hour_desc')),
                            trailing: Text('${appSettingModel.dynamic_qr_default_exp_after_hour} ${AppLocalizations.of(context)!.translate('hours')}',
                                style: TextStyle(color: !hasQrAccess ? Colors.grey : null, fontWeight: FontWeight.w500)),
                            onTap: hasQrAccess ? (){
                             openAdjustHourDialog(appSettingModel);
                            } : null
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

  Future<Future<Object?>> openAdjustHourDialog(AppSettingModel appSettingModel) async {
    return showGeneralDialog(
        barrierColor: Colors.black.withOpacity(0.5),
        transitionBuilder: (context, a1, a2, widget) {
          final curvedValue = Curves.easeInOutBack.transform(a1.value) - 1.0;
          return Transform(
            transform: Matrix4.translationValues(0.0, curvedValue * 200, 0.0),
            child: Opacity(
                opacity: a1.value,
                child: AdjustHourDialog(exp_hour: appSettingModel.dynamic_qr_default_exp_after_hour!)
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

  updateAppSetting() async {
    DateFormat dateFormat = DateFormat("yyyy-MM-dd HH:mm:ss");
    String dateTime = dateFormat.format(DateTime.now());
    AppSetting object = AppSetting(
        open_cash_drawer: this.cashDrawer == true ? 1 : 0,
        show_second_display: this.secondDisplay == true ? 1 : 0,
        app_setting_sqlite_id: appSetting.app_setting_sqlite_id,
        table_order: this.tableMode,
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

  updateQrOrderAutoAcceptAppSetting() async {
    DateFormat dateFormat = DateFormat("yyyy-MM-dd HH:mm:ss");
    String dateTime = dateFormat.format(DateTime.now());
    AppSetting object = AppSetting(
        qr_order_auto_accept: this.qrOrderAutoAccept == true ? 1 : 0,
        app_setting_sqlite_id: appSetting.app_setting_sqlite_id,
        updated_at: dateTime
    );
    int data = await PosDatabase.instance.updateQrOrderAutoAcceptSetting(object);
  }

  updateShowProDescAppSetting() async {
    DateFormat dateFormat = DateFormat("yyyy-MM-dd HH:mm:ss");
    String dateTime = dateFormat.format(DateTime.now());
    AppSetting object = AppSetting(
        show_product_desc: showProductDesc == true ? 1 : 0,
        app_setting_sqlite_id: appSetting.app_setting_sqlite_id,
        updated_at: dateTime
    );
    int data = await PosDatabase.instance.updateShowProDescSettings(object);
  }

  updateProductSortBySetting() async {
    DateFormat dateFormat = DateFormat("yyyy-MM-dd HH:mm:ss");
    String dateTime = dateFormat.format(DateTime.now());
    AppSetting object = AppSetting(
        product_sort_by: selectedValue,
        app_setting_sqlite_id: appSetting.app_setting_sqlite_id,
        updated_at: dateTime
    );
    int data = await PosDatabase.instance.updateProductSortBySettings(object);
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
