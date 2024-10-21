import 'package:confirm_dialog/confirm_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';
import 'package:pos_system/database/pos_database.dart';
import 'package:pos_system/fragment/setting/sync_dialog.dart';
import 'package:pos_system/fragment/setting/system_log_dialog.dart';
import 'package:pos_system/notifier/theme_color.dart';
import 'package:pos_system/object/table.dart';
import 'package:pos_system/page/pos_pin.dart';
import 'package:pos_system/page/progress_bar.dart';
import 'package:pos_system/page/select_table_dialog.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../main.dart';
import '../../object/table_use.dart';
import '../../object/table_use_detail.dart';
import '../../translation/AppLocalizations.dart';

class DataProcessingSetting extends StatefulWidget {
  const DataProcessingSetting({Key? key}) : super(key: key);

  @override
  State<DataProcessingSetting> createState() => _DataProcessingSettingState();
}

class _DataProcessingSettingState extends State<DataProcessingSetting> {
  final adminPosPinController = TextEditingController();
  bool inProgress = false;
  bool isButtonDisabled = false;
  bool _submitted = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeColor>(builder: (context, ThemeColor color, child) {
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
          title: Text(AppLocalizations.of(context)!.translate('data_processing'),
              style: TextStyle(fontSize: 20, color: color.backgroundColor)),
          centerTitle: false,
        )
            : null,
        body: SingleChildScrollView(
          child: Column(
            children: [
              ListTile(
                title: Text(AppLocalizations.of(context)!.translate('system_log')),
                trailing: Icon(Icons.history),
                onTap: () async {
                  openSystemLog();
                },
              ),
              ListTile(
                title: Text(AppLocalizations.of(context)!.translate('sync')),
                trailing: Icon(Icons.sync),
                onTap: () async {
                  openSyncDialog();
                },
              ),
              ListTile(
                title: Text(AppLocalizations.of(context)!.translate('sync_reset')),
                trailing: Icon(Icons.refresh),
                onTap: () async {
                  syncRecord.count = 0;
                  qrOrder.count = 0;
                  Fluttertoast.showToast(msg: AppLocalizations.of(context)!.translate('sync_reset_success'));
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
                  title: Text(AppLocalizations.of(context)!.translate('reset_table_data')),
                  subtitle: Text(AppLocalizations.of(context)!.translate('reset_table_desc')),
                  onTap: (){
                    openSelectTableDialog();
                  },
                  trailing: Icon(Icons.navigate_next)
              ),
              ListTile(
                  title: Text(AppLocalizations.of(context)!.translate('clear_pos_data')),
                  subtitle: Text(AppLocalizations.of(context)!.translate('clear_pos_data_desc')),
                  onTap: () async {
                    await showSecondDialog(context, color);
                  },
                  trailing: Icon(Icons.navigate_next)
              ),
            ],
          ),
        ),
      );
    });
  }

  Future<void> openSelectTableDialog () {
    return showDialog(
      context: context,
      barrierDismissible: false, // user must tap button!
      builder: (BuildContext context) {
        return SelectTableDialog(currentPage: '1',);
      },
    ).then((result){
      if(result != null){
        if(result == 'resetAllTable'){
          resetAllInUsedTableStatus();
        } else {
          resetTableStatus(result);
        }
      }
    });
  }

  Future showSecondDialog(BuildContext context, ThemeColor color) {
    return showDialog(
        barrierDismissible: false,
        context: context,
        builder: (BuildContext context) {
          return StatefulBuilder(builder: (context, StateSetter setState) {
            return Center(
              child: SingleChildScrollView(
                child: AlertDialog(
                  title: Text(AppLocalizations.of(context)!.translate('enter_debug_pin')),
                  content: !inProgress ? SizedBox(
                    height: 75.0,
                    width: 350.0,
                    child: ValueListenableBuilder(
                        valueListenable: adminPosPinController,
                        builder: (context, TextEditingValue value, __) {
                          return Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: TextField(
                              autofocus: true,
                              onSubmitted: (input) {
                                setState(() {
                                  isButtonDisabled = true;
                                });
                                _submit(context);
                                if(mounted){
                                  setState(() {
                                    isButtonDisabled = false;
                                    inProgress = false;
                                  });
                                }
                              },
                              obscureText: true,
                              controller: adminPosPinController,
                              keyboardType: TextInputType.numberWithOptions(decimal: true),
                              decoration: InputDecoration(
                                errorText: _submitted
                                    ? errorPassword == null
                                    ? errorPassword
                                    : AppLocalizations.of(context)?.translate(errorPassword!)
                                    : null,
                                border: OutlineInputBorder(
                                  borderSide: BorderSide(color: color.backgroundColor),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderSide: BorderSide(color: color.backgroundColor),
                                ),
                                labelText: "PIN",
                              ),
                            ),
                          );
                        }),
                  )
                      : Container(
                      height: 100,
                      child: CustomProgressBar()
                  ),
                  actions: <Widget>[
                    Row(
                      children: [
                        Expanded(
                          flex: 1,
                          child: SizedBox(
                            height: MediaQuery.of(context).size.width > 900 && MediaQuery.of(context).size.height > 500
                                ? MediaQuery.of(context).size.height / 12
                                : MediaQuery.of(context).orientation == Orientation.landscape ? MediaQuery.of(context).size.height / 10
                                : MediaQuery.of(context).size.height / 20,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: color.backgroundColor,
                              ),
                              child: Text(
                                AppLocalizations.of(context)!.translate('close'),
                                style: TextStyle(color: Colors.white),
                              ),
                              onPressed: isButtonDisabled
                                  ? null
                                  : () {
                                setState(() {
                                  isButtonDisabled = true;
                                });
                                Navigator.of(context).pop();
                                if(mounted){
                                  setState(() {
                                    isButtonDisabled = false;
                                  });
                                }
                              },
                            ),
                          ),
                        ),
                        SizedBox(width: 10),
                        Expanded(
                          flex: 1,
                          child: SizedBox(
                            height: MediaQuery.of(context).size.width > 900 && MediaQuery.of(context).size.height > 500
                                ? MediaQuery.of(context).size.height / 12
                                : MediaQuery.of(context).orientation == Orientation.landscape ? MediaQuery.of(context).size.height / 10
                                : MediaQuery.of(context).size.height / 20,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: color.buttonColor,
                              ),
                              child: Text(
                                AppLocalizations.of(context)!.translate('yes'),
                                style: TextStyle(color: Colors.white),
                              ),
                              onPressed: isButtonDisabled
                                  ? null
                                  : () async {
                                setState(() {
                                  isButtonDisabled = true;
                                });
                                _submit(context);
                                if(mounted){
                                  setState(() {
                                    isButtonDisabled = false;
                                    inProgress = false;
                                  });
                                }
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          });
        });
  }

  String? get errorPassword {
    final text = adminPosPinController.value.text;
    if (text.isEmpty) {
      return 'password_required';
    }
    return null;
  }

  void _submit(BuildContext context) async {
    setState(() => _submitted = true);
    if (errorPassword == null) {
      await readAdminData(adminPosPinController.text);
    } else {
      setState(() {
        isButtonDisabled = false;
        inProgress = false;
      });
    }
  }

  readAdminData(String pin) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? branch_id = prefs.getInt('branch_id').toString();

      if(branch_id != null){
        if(pin == branch_id.padLeft(6, '0')) {
          Navigator.of(context).pop();
          await openClearDataDialog();
        } else {
          Fluttertoast.showToast(backgroundColor: Color(0xFFFF0000), msg: "${AppLocalizations.of(context)?.translate('wrong_pin_please_insert_valid_pin')}");
        }
      } else {
        Fluttertoast.showToast(backgroundColor: Color(0xFFFF0000), msg: "${AppLocalizations.of(context)?.translate('something_went_wrong_please_try_again_later')}");
      }

    } catch (e) {
      print('delete error ${e}');
    }
  }

  Future openClearDataDialog() {
    return showDialog(
        barrierDismissible: false,
        context: context,
        builder: (BuildContext context) {
          return StatefulBuilder(builder: (context, StateSetter setState){
            return Center(
                child: AlertDialog(
                  content: SizedBox(
                    width: 360,
                    child: ListView(
                        padding: EdgeInsets.zero,
                        shrinkWrap: true,
                        children: [
                          Card(
                              elevation: 5,
                              child: ListTile(
                                leading: CircleAvatar(
                                    backgroundColor: Colors.grey.shade200,
                                    child: Icon(
                                      Icons.refresh,
                                      color: Colors.grey,
                                    )),
                                title: Text(AppLocalizations.of(context)!.translate('clear_all_pos_data')),
                                onTap: () async {
                                  if (await confirm(
                                    context,
                                    title: Text('${AppLocalizations.of(context)?.translate('clear_all_pos_data')}'),
                                    content: Text('${AppLocalizations.of(context)?.translate('to_pos_pin')}'),
                                    textOK: Text('${AppLocalizations.of(context)?.translate('yes')}'),
                                    textCancel: Text('${AppLocalizations.of(context)?.translate('no')}'),
                                  )) {
                                    Navigator.of(context).pushAndRemoveUntil(
                                      MaterialPageRoute(
                                        builder: (BuildContext context) => PosPinPage(),
                                      ),
                                          (Route route) => false,
                                    );
                                    clearAllPosData();
                                  }
                                },
                                trailing: Icon(Icons.navigate_next),
                              )
                          ),
                          // Card(
                          //     elevation: 5,
                          //     child: ListTile(
                          //       leading: CircleAvatar(
                          //           backgroundColor: Colors.grey.shade200,
                          //           child: Icon(
                          //             Icons.edit,
                          //             color: Colors.grey,
                          //           )),
                          //       title: Text(AppLocalizations.of(context)!.translate('clear_specific_data')),
                          //       onTap: () async {
                          //         if (await confirm(
                          //           context,
                          //           title: Text('${AppLocalizations.of(context)?.translate('clear_specific_data')}'),
                          //           content: Text('${AppLocalizations.of(context)?.translate('to_pos_pin')}'),
                          //           textOK: Text('${AppLocalizations.of(context)?.translate('yes')}'),
                          //           textCancel: Text('${AppLocalizations.of(context)?.translate('no')}'),
                          //         )) {
                          //           Navigator.of(context).pushAndRemoveUntil(
                          //             MaterialPageRoute(
                          //               builder: (BuildContext context) => PosPinPage(),
                          //             ),
                          //                 (Route route) => false,
                          //           );
                          //           clearAllPosData();
                          //         }
                          //       },
                          //       trailing: Icon(Icons.navigate_next),
                          //     )
                          // ),
                        ]
                    ),
                  ),
                  actions: <Widget>[
                    TextButton(
                      child: Text('${AppLocalizations.of(context)?.translate('close')}'),
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                    )
                  ],
                )
            );
          });
        }
    );
  }

  clearAllPosData() {
    PosDatabase.instance.clearAllOrderCache();
    PosDatabase.instance.clearAllOrderDetail();
    PosDatabase.instance.clearAllOrder();
    PosDatabase.instance.clearAllOrderDetailCancel();
    PosDatabase.instance.clearAllOrderModifierDetail();
    PosDatabase.instance.clearAllOrderTax();
    PosDatabase.instance.clearAllOrderPromotion();
    PosDatabase.instance.clearAllOrderPaymentSplit();
    PosDatabase.instance.clearAllTableUse();
    PosDatabase.instance.clearAllTableUseDetail();
    resetAllInUsedTableStatus();
    PosDatabase.instance.clearAllCashRecord();
    PosDatabase.instance.clearAllRefund();
    PosDatabase.instance.clearAllSettlement();
    PosDatabase.instance.clearAllSettlementLinkPayment();
    PosDatabase.instance.clearAllTransferOwner();
    PosDatabase.instance.clearAllCustomer();
  }

  resetAllInUsedTableStatus() async {
    DateFormat dateFormat = DateFormat("yyyy-MM-dd HH:mm:ss");
    String dateTime = dateFormat.format(DateTime.now());
    List<PosTable> data = await PosDatabase.instance.readAllTable();
    for(int i = 0; i < data.length; i++){
      PosTable posTable = data[i];
      await resetTableUseDetail(dateTime, posTable);
      await resetTableUse(dateTime, posTable);
      PosTable object = PosTable(
          status: 0,
          table_use_detail_key: '',
          table_use_key: '',
          updated_at: dateTime,
          table_sqlite_id: posTable.table_sqlite_id
      );
      await PosDatabase.instance.resetPosTable(object);
    }
  }

  resetTableStatus(PosTable posTable) async {
    DateFormat dateFormat = DateFormat("yyyy-MM-dd HH:mm:ss");
    String dateTime = dateFormat.format(DateTime.now());
    await resetTableUseDetail(dateTime, posTable);
    await resetTableUse(dateTime, posTable);
    PosTable data = PosTable(
        status: 0,
        table_use_detail_key: '',
        table_use_key: '',
        updated_at: dateTime,
        table_sqlite_id: posTable.table_sqlite_id
    );
    await PosDatabase.instance.resetPosTable(data);
  }

  resetTableUseDetail(String dateTime, PosTable posTable) async {
    TableUseDetail? tableUseDetailData = await PosDatabase.instance.readTableUseDetailByKey(posTable.table_use_detail_key!);
    if(tableUseDetailData != null){
      TableUseDetail detailObject = TableUseDetail(
          status: 1,
          soft_delete: dateTime,
          sync_status: tableUseDetailData.sync_status == 0 ? 0 : 2,
          table_use_detail_key: posTable.table_use_detail_key
      );
      await PosDatabase.instance.deleteTableUseDetailByKey(detailObject);
    }
  }

  resetTableUse(String dateTime, PosTable posTable) async {
    List<TableUseDetail> checkData = await PosDatabase.instance.readTableUseDetailByTableUseKey(posTable.table_use_key!);
    //check is current table is merged table or not
    if(checkData.isEmpty){
      TableUse? tableUseData = await PosDatabase.instance.readSpecificTableUseByKey2(posTable.table_use_key!);
      if(tableUseData != null){
        TableUse object = TableUse(
            status: 1,
            soft_delete: dateTime,
            sync_status: tableUseData.sync_status == 0 ? 0 : 2,
            table_use_key: posTable.table_use_key
        );
        await PosDatabase.instance.deleteTableUseByKey(object);
      }
    }
  }

  Future<Future<Object?>> openSystemLog() async {
    return showGeneralDialog(
        barrierColor: Colors.black.withOpacity(0.5),
        transitionBuilder: (context, a1, a2, widget) {
          final curvedValue = Curves.easeInOutBack.transform(a1.value) - 1.0;
          return Transform(
            transform: Matrix4.translationValues(0.0, curvedValue * 200, 0.0),
            child: Opacity(
              opacity: a1.value,
              child: SystemLogDialog(),
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

  Future<Future<Object?>> openSyncDialog() async {
    return showGeneralDialog(
        barrierColor: Colors.black.withOpacity(0.5),
        transitionBuilder: (context, a1, a2, widget) {
          final curvedValue = Curves.easeInOutBack.transform(a1.value) - 1.0;
          return Transform(
            transform: Matrix4.translationValues(0.0, curvedValue * 200, 0.0),
            child: Opacity(
              opacity: a1.value,
              child: SyncDialog(),
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
}
