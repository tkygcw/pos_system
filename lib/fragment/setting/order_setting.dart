import 'dart:async';
import 'package:confirm_dialog/confirm_dialog.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';
import 'package:pos_system/database/pos_database.dart';
import 'package:pos_system/fragment/setting/adjust_hour_dialog.dart';
import 'package:pos_system/fragment/setting/kitchenlist_dialog.dart';
import 'package:pos_system/fragment/setting/receipt_dialog.dart';
import 'package:pos_system/object/table.dart';
import 'package:pos_system/page/pos_pin.dart';
import 'package:pos_system/page/progress_bar.dart';
import 'package:provider/provider.dart';

import '../../notifier/theme_color.dart';
import '../../object/receipt.dart';
import '../../translation/AppLocalizations.dart';
import '../../controller/controllerObject.dart';
import '../../object/app_setting.dart';
import '../../notifier/app_setting_notifier.dart';
import 'checklist_dialog.dart';

class OrderSetting extends StatefulWidget {
  const OrderSetting({Key? key}) : super(key: key);

  @override
  State<OrderSetting> createState() => _OrderSettingState();
}

class _OrderSettingState extends State<OrderSetting> {
  ControllerClass controller = ControllerClass();
  StreamController actionController = StreamController();
  TextEditingController orderNumberController = TextEditingController();
  AppSetting appSetting = AppSetting();
  late StreamController streamController;
  late Stream actionStream;
  // List<AppSetting> appSettingList = [];
  Receipt? receiptObject;
  bool printCheckList = false, enableNumbering = false, printReceipt = false, hasQrAccess = true, printCancelReceipt = true,
      directPayment = false, qrOrderAutoAccept = false, cashDrawer = false, secondDisplay = false;
  int startingNumber = 0, compareStartingNumber = 0;
  final List<String> tableModeOption = [
    'table_mode_no_table',
    'table_mode_full_table',
    'table_mode_no_table_special'
  ];
  int? tableMode = 0;

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
        case 'qr_order_auto_accept':{
          await updateQrOrderAutoAcceptAppSetting();
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
      } else {
        tableMode = 0;
      }

      if(appSetting.direct_payment == 1){
        this.directPayment = true;
      } else {
        this.directPayment = false;
      }

      if(appSetting.qr_order_auto_accept == 1){
        this.qrOrderAutoAccept = true;
      } else {
        this.qrOrderAutoAccept = false;
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

  Future<Future<Object?>> openStartingNumberDialog() async {
    return showGeneralDialog(
        barrierColor: Colors.black.withOpacity(0.5),
        transitionBuilder: (context, a1, a2, widget) {
          final curvedValue = Curves.easeInOutBack.transform(a1.value) - 1.0;
          return Center(
            child: SingleChildScrollView(
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
            appBar:  MediaQuery.of(context).size.width < 800 && MediaQuery.of(context).orientation == Orientation.portrait ? AppBar(
              elevation: 1,
              leading: IconButton(
                icon: Icon(Icons.arrow_back_ios, color: color.buttonColor),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
              backgroundColor: Colors.white,
              title: Text(AppLocalizations.of(context)!.translate('order_setting'),
                  style: TextStyle(fontSize: 20, color: color.backgroundColor)),
              centerTitle: false,
            )
                : null,
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
                              width: MediaQuery.of(context).orientation == Orientation.landscape ? 200 : 150,
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
                          Divider(
                            color: Colors.grey,
                            height: 1,
                            thickness: 1,
                            indent: 20,
                            endIndent: 20,
                          ),
                          ListTile(
                            title: Text(AppLocalizations.of(context)!.translate('order_numbering')),
                            subtitle: Text(AppLocalizations.of(context)!.translate('enable_order_numbering')),
                            trailing: Switch(
                              value: enableNumbering,
                              activeColor: color.backgroundColor,
                              onChanged: (value) async {
                                if(!value) {
                                  if(appSettingModel.table_order != 1) {
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
                          Divider(
                            color: Colors.grey,
                            height: 1,
                            thickness: 1,
                            indent: 20,
                            endIndent: 20,
                          ),
                          ListTile(
                            title: Text(AppLocalizations.of(context)!.translate('auto_accept_qr_order')),
                            subtitle: Text(AppLocalizations.of(context)!.translate('auto_accept_qr_order_desc')),
                            trailing: Switch(
                              value: qrOrderAutoAccept,
                              activeColor: color.backgroundColor,
                              onChanged: (value) {
                                qrOrderAutoAccept = value;
                                appSettingModel.setQrOrderAutoAcceptStatus(qrOrderAutoAccept);
                                actionController.sink.add("qr_order_auto_accept");
                              },
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
        print_checklist: printCheckList == true ? 1 : 0,
        print_receipt: printReceipt == true ? 1 : 0,
        enable_numbering: enableNumbering == true ? 1 : 0,
        starting_number: startingNumber != 0 ? startingNumber : 0,
        app_setting_sqlite_id: appSetting.app_setting_sqlite_id,

        open_cash_drawer: this.cashDrawer == true ? 1 : 0,
        show_second_display: this.secondDisplay == true ? 1 : 0,
        table_order: this.tableMode,
        updated_at: dateTime
    );
    int data = await PosDatabase.instance.updateReceiptSettings(object);
    await PosDatabase.instance.updateAppSettings(object);
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

  updateDirectPaymentAppSetting() async {
    DateFormat dateFormat = DateFormat("yyyy-MM-dd HH:mm:ss");
    String dateTime = dateFormat.format(DateTime.now());
    AppSetting object = AppSetting(
        direct_payment: this.directPayment == true ? 1 : 0,
        app_setting_sqlite_id: appSetting.app_setting_sqlite_id,
        updated_at: dateTime
    );
    await PosDatabase.instance.updateDirectPaymentSettings(object);
  }

  updateQrOrderAutoAcceptAppSetting() async {
    DateFormat dateFormat = DateFormat("yyyy-MM-dd HH:mm:ss");
    String dateTime = dateFormat.format(DateTime.now());
    AppSetting object = AppSetting(
        qr_order_auto_accept: this.qrOrderAutoAccept == true ? 1 : 0,
        app_setting_sqlite_id: appSetting.app_setting_sqlite_id,
        updated_at: dateTime
    );
    await PosDatabase.instance.updateQrOrderAutoAcceptSetting(object);
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
