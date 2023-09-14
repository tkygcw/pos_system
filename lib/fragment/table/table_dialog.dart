import 'dart:convert';

import 'package:confirm_dialog/confirm_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';
import 'package:pos_system/database/domain.dart';
import 'package:pos_system/database/pos_database.dart';
import 'package:pos_system/notifier/theme_color.dart';
import 'package:pos_system/object/table.dart';
import 'package:pos_system/translation/AppLocalizations.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:crypto/crypto.dart';

class TableDialog extends StatefulWidget {
  final List<PosTable> allTableList;
  final Function() callBack;
  final PosTable object;

  const TableDialog({required this.callBack, required this.object, Key? key, required this.allTableList}) : super(key: key);

  @override
  _TableDialogState createState() => _TableDialogState();
}

class _TableDialogState extends State<TableDialog> {
  final tableNoController = TextEditingController();
  final seatController = TextEditingController();
  bool _submitted = false;
  bool isUpdate = false;
  bool isButtonDisabled = false;

  @override
  void initState() {
    // TODO: implement initState
    if (widget.object.created_at != null) {
      isUpdate = true;
      tableNoController.text = widget.object.number!;
      seatController.text = widget.object.seats!;
    } else {
      isUpdate = false;
    }
    super.initState();
  }

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
    tableNoController.dispose();
    seatController.dispose();
  }

  String? get errorTableNo {
    final text = tableNoController.value.text;
    if (text.isEmpty) {
      return 'table_no_required';
    }
    return null;
  }

  String? get errorSeat {
    final text = seatController.value.text;
    if (text.isEmpty) {
      return 'seat_required';
    }
    return null;
  }

  void _submit(BuildContext context) {
    setState(() => _submitted = true);
    if (errorTableNo == null && errorSeat == null) {
      // Disable the button after it has been pressed
      setState(() {
        isButtonDisabled = true;
      });
      if (isUpdate) {
        updatePosTable();
      } else {
        checkRepeatedTableNumber();
      }
    }
  }

  checkRepeatedTableNumber() {
    List<PosTable> tableList = widget.allTableList;
    bool tbNumberRepeated = tableList.any((item) => item.number == tableNoController.text);
    if (tbNumberRepeated) {
      Fluttertoast.showToast(msg: AppLocalizations.of(context)!.translate('table_number_repeated'), backgroundColor: Colors.red);
      isButtonDisabled = false;
      return;
    } else {
      createPosTable();
    }
  }

  generateUrl(String dateTime) async {
    final prefs = await SharedPreferences.getInstance();
    final int? branch_id = prefs.getInt('branch_id');
    var bytes = dateTime.replaceAll(new RegExp(r'[^0-9]'), '') + branch_id.toString() + tableNoController.text;
    return md5.convert(utf8.encode(bytes)).toString();
  }

  void createPosTable() async {
    try {
      DateFormat dateFormat = DateFormat("yyyy-MM-dd HH:mm:ss");
      String dateTime = dateFormat.format(DateTime.now());
      final prefs = await SharedPreferences.getInstance();
      final int? branch_id = prefs.getInt('branch_id');
      var url = await generateUrl(dateTime);

      bool _hasInternetAccess = await Domain().isHostReachable();
      if (_hasInternetAccess) {
        Map response = await Domain().insertTable(seatController.text, tableNoController.text, branch_id.toString(), url);
        if (response['status'] == '1') {
          //create local
          PosTable data = await PosDatabase.instance.insertSyncPosTable(PosTable(
              table_id: response['table'],
              table_url: url,
              branch_id: branch_id.toString(),
              number: tableNoController.text,
              seats: seatController.text,
              table_use_detail_key: '',
              table_use_key: '',
              status: 0,
              sync_status: 1,
              dx: '',
              dy: '',
              created_at: dateTime,
              updated_at: '',
              soft_delete: ''));

          if (data.created_at != '') {
            widget.callBack();
            Fluttertoast.showToast(msg: AppLocalizations.of(context)!.translate('successfully_create'));
            Navigator.of(context).pop();
          } else {
            Fluttertoast.showToast(msg: AppLocalizations.of(context)!.translate('fail_create'));
          }
        }
      } else {
        Fluttertoast.showToast(msg: AppLocalizations.of(context)!.translate('no_internet_access'));
      }

/*
      -------------------------sync to cloud-----------------------------------
*/
      // Map response = await Domain().insertTable(seatController.text, tableNoController.text, branch_id.toString());
      // if (response['status'] == '1') {
      //   int syncData = await PosDatabase.instance.updateSyncPosTable(PosTable(
      //     table_id: response['table'],
      //     sync_status: 2,
      //     updated_at: dateTime,
      //     table_sqlite_id: data.table_sqlite_id,
      //   ));
      // }
/*
      ------------------------------sync end-----------------------------------
*/
    } catch (error) {
      print('error: ${error}');
      Fluttertoast.showToast(msg: AppLocalizations.of(context)!.translate('something_went_wrong_please_try_again_later'));
    }
  }

  Future<int> updatePosTable() async {
    int data = 0;
    try {
      DateFormat dateFormat = DateFormat("yyyy-MM-dd HH:mm:ss");
      String dateTime = dateFormat.format(DateTime.now());

      bool _hasInternetAccess = await Domain().isHostReachable();
      if (_hasInternetAccess) {
        Map response = await Domain().editTable(seatController.text, tableNoController.text, widget.object.table_id.toString());
        if (response['status'] == '1') {
          //update local
          data = await PosDatabase.instance.updatePosTable(PosTable(
              table_sqlite_id: widget.object.table_sqlite_id,
              number: tableNoController.text,
              seats: seatController.text,
              sync_status: 1,
              updated_at: dateTime));

          if (data == 1) {
            widget.callBack();
            Fluttertoast.showToast(msg: AppLocalizations.of(context)!.translate('successfully_update'));
            Navigator.of(context).pop();
          } else {
            Fluttertoast.showToast(msg: AppLocalizations.of(context)!.translate('fail_update'));
          }
        }
      } else {
        Fluttertoast.showToast(msg: AppLocalizations.of(context)!.translate('no_internet_access'));
      }
    } catch (error) {
      Fluttertoast.showToast(msg: AppLocalizations.of(context)!.translate('something_went_wrong_please_try_again_later'));
    }
    return data;
  }



  Future<int> deletePosTable() async {
    int data = 0;
    try {
      DateFormat dateFormat = DateFormat("yyyy-MM-dd HH:mm:ss");
      String dateTime = dateFormat.format(DateTime.now());
      // data = await PosDatabase.instance.deletePosTable(PosTable(soft_delete: dateTime, sync_status: 1, table_sqlite_id: widget.object.table_sqlite_id));
/*
      -------------------------------sync to cloud----------------------------
*/
      bool _hasInternetAccess = await Domain().isHostReachable();
      if(_hasInternetAccess){
        Map response = await Domain().deleteBranchTable(widget.object.table_id.toString());
        if (response['status'] == '1') {
          int data = await PosDatabase.instance.deletePosTable(PosTable(
            soft_delete: dateTime,
            sync_status: 1,
            table_sqlite_id: widget.object.table_sqlite_id
          ));
          /*
      ---------------------------------end sync-------------------------------
*/
          if (data == 1) {
            Fluttertoast.showToast(msg: AppLocalizations.of(context)!.translate('successfully_delete'));
            widget.callBack();
            closeDialog(context);
          } else {
            Fluttertoast.showToast(msg: AppLocalizations.of(context)!.translate('fail_delete'));
          }
        }
      }

    } catch (error) {
      print('error: ' + error.toString());
      Fluttertoast.showToast(msg: AppLocalizations.of(context)!.translate('something_went_wrong_please_try_again_later'));
    }
    return data;
  }

  closeDialog(BuildContext context) {
    return Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeColor>(builder: (context, ThemeColor color, child) {
      return Center(
        child: SingleChildScrollView(
          child: AlertDialog(
            title: Row(
              children: [
                Text(
                  widget.object.table_id == null ? '${AppLocalizations.of(context)?.translate('create_table')}' : '${AppLocalizations.of(context)?.translate('edit_table')}',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Spacer(),
                widget.object.table_id == null
                    ? Container()
                    : IconButton(
                        icon: const Icon(Icons.delete_outlined),
                        padding: EdgeInsets.zero,
                        constraints: BoxConstraints(),
                        color: Colors.red,
                        onPressed: () async {
                          bool confirmation = await confirm(
                            context,
                            title: Text(
                              '${AppLocalizations.of(context)?.translate('delete_table')}',
                            ),
                            content: Text(
                              '${AppLocalizations.of(context)?.translate('would_you_like_to_remove')}',
                            ),
                            textOK: Text(
                              '${AppLocalizations.of(context)?.translate('yes')}',
                            ),
                            textCancel: Text(
                              '${AppLocalizations.of(context)?.translate('no')}',
                            ),
                          );

                          if (confirmation) {
                            await deletePosTable();
                          }
                        },
                      ),
              ],
            ),
            content: Container(
              height: MediaQuery.of(context).size.height > 500 ? 200.0 : 150, // Change as per your requirement
              width: 350.0,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ValueListenableBuilder(
                        // Note: pass _controller to the animation argument
                        valueListenable: tableNoController,
                        builder: (context, TextEditingValue value, __) {
                          return Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: TextField(
                              controller: tableNoController,
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(
                                  RegExp(r'[0-9]'),
                                ),
                                FilteringTextInputFormatter.deny(
                                  RegExp(r'^0+'), //users can't type 0 at 1st position
                                ),
                              ],
                              maxLength: 3,
                              decoration: InputDecoration(
                                errorText: _submitted
                                    ? errorTableNo == null
                                        ? errorTableNo
                                        : AppLocalizations.of(context)?.translate(errorTableNo!)
                                    : null,
                                border: OutlineInputBorder(
                                  borderSide: BorderSide(color: color.backgroundColor),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderSide: BorderSide(color: color.backgroundColor),
                                ),
                                labelText: AppLocalizations.of(context)!.translate('table_no') + '.',
                              ),
                            ),
                          );
                        }),
                    ValueListenableBuilder(
                        // Note: pass _controller to the animation argument
                        valueListenable: seatController,
                        builder: (context, TextEditingValue value, __) {
                          return Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: TextField(
                              controller: seatController,
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(
                                  RegExp(r'[0-9]'),
                                ),
                                FilteringTextInputFormatter.deny(
                                  RegExp(r'^0+'), //users can't type 0 at 1st position
                                ),
                              ],
                              maxLength: 2,
                              decoration: InputDecoration(
                                errorText: _submitted
                                    ? errorSeat == null
                                        ? errorSeat
                                        : AppLocalizations.of(context)?.translate(errorSeat!)
                                    : null,
                                border: OutlineInputBorder(
                                  borderSide: BorderSide(color: color.backgroundColor),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderSide: BorderSide(color: color.backgroundColor),
                                ),
                                labelText: AppLocalizations.of(context)!.translate('seat'),
                              ),
                            ),
                          );
                        }),
                  ],
                ),
              ),
            ),
            actions: <Widget>[
              SizedBox(
                width: MediaQuery.of(context).size.width / 5,
                height: MediaQuery.of(context).size.height / 12,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: color.backgroundColor),
                  child: Text('${AppLocalizations.of(context)?.translate('close')}'),
                  onPressed: isButtonDisabled
                      ? null
                      : () {
                          // Disable the button after it has been pressed
                          setState(() {
                            isButtonDisabled = true;
                          });
                          Navigator.of(context).pop();
                        },
                ),
              ),
              SizedBox(
                width: MediaQuery.of(context).size.width / 5,
                height: MediaQuery.of(context).size.height / 12,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: color.buttonColor),
                  child: widget.object.table_id == null ? Text('${AppLocalizations.of(context)?.translate('add')}') : Text(AppLocalizations.of(context)!.translate('submit')),
                  onPressed: isButtonDisabled
                      ? null
                      : () async {
                          _submit(context);
                        },
                ),
              ),
            ],
          ),
        ),
      );
    });
  }
}
