import 'package:confirm_dialog/confirm_dialog.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';
import 'package:pos_system/database/domain.dart';
import 'package:pos_system/database/pos_database.dart';
import 'package:pos_system/notifier/theme_color.dart';
import 'package:pos_system/object/table.dart';
import 'package:pos_system/translation/AppLocalizations.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TableDialog extends StatefulWidget {
  final Function() callBack;
  final PosTable object;

  const TableDialog({required this.callBack, required this.object, Key? key})
      : super(key: key);

  @override
  _TableDialogState createState() => _TableDialogState();
}

class _TableDialogState extends State<TableDialog> {
  final tableNoController = TextEditingController();
  final seatController = TextEditingController();
  bool _submitted = false;
  bool isUpdate = false;

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
      if (isUpdate) {
        updatePosTable();
      } else {
        createPosTable();
      }
    }
  }

  void createPosTable() async {
    try {
      DateFormat dateFormat = DateFormat("yyyy-MM-dd HH:mm:ss");
      String dateTime = dateFormat.format(DateTime.now());
      final prefs = await SharedPreferences.getInstance();
      final int? branch_id = prefs.getInt('branch_id');
      PosTable data = await PosDatabase.instance.insertSyncPosTable(PosTable(
          table_id: 0,
          branch_id: branch_id.toString(),
          number: tableNoController.text,
          seats: seatController.text,
          status: 0,
          sync_status: 0,
          created_at: dateTime,
          updated_at: '',
          soft_delete: ''));
/*
      -------------------------sync to cloud-----------------------------------
*/
      Map response = await Domain().insertTable(
          seatController.text, tableNoController.text, branch_id.toString());
      if (response['status'] == '1') {
        int syncData = await PosDatabase.instance.updateSyncPosTable(PosTable(
          table_id: response['table'],
          sync_status: 2,
          updated_at: dateTime,
          table_sqlite_id: data.table_sqlite_id,
        ));
      }
/*
      ------------------------------sync end-----------------------------------
*/
      if (data.table_sqlite_id != '') {
        Fluttertoast.showToast(msg: 'Successfully create');
        widget.callBack();
        closeDialog(context);
      } else {
        Fluttertoast.showToast(msg: 'Fail create');
      }
    } catch (error) {
      Fluttertoast.showToast(msg: 'Something went wrong, please try again');
    }
  }

  void updatePosTable() async {
    try {
      DateFormat dateFormat = DateFormat("yyyy-MM-dd HH:mm:ss");
      String dateTime = dateFormat.format(DateTime.now());
      int data = await PosDatabase.instance.updatePosTable(PosTable(
          table_sqlite_id: widget.object.table_sqlite_id,
          number: tableNoController.text,
          seats: seatController.text,
          sync_status: 1,
          updated_at: dateTime));
/*
      --------------------------------sync to cloud----------------------------
*/
      Map response = await Domain().editTable(seatController.text,
          tableNoController.text, widget.object.table_id.toString());
      if (response['status'] == '1') {
        int syncData = await PosDatabase.instance.updateSyncPosTable(PosTable(
          table_id: widget.object.table_id,
          sync_status: 2,
          updated_at: dateTime,
          table_sqlite_id: widget.object.table_sqlite_id,
        ));
      }
/*
      ---------------------------------end sync--------------------------------
*/
      if (data == 1) {
        Fluttertoast.showToast(msg: 'Successfully edit');
        widget.callBack();
        closeDialog(context);
      } else {
        Fluttertoast.showToast(msg: 'Fail edit');
      }
    } catch (error) {
      Fluttertoast.showToast(msg: 'Something went wrong, please try again');
    }
  }

  void deletePosTable() async {
    try {
      DateFormat dateFormat = DateFormat("yyyy-MM-dd HH:mm:ss");
      String dateTime = dateFormat.format(DateTime.now());
      int data = await PosDatabase.instance.deletePosTable(PosTable(
          soft_delete: dateTime,
          sync_status: 1,
          table_sqlite_id: widget.object.table_sqlite_id));
/*
      -------------------------------sync to cloud----------------------------
*/
      Map response =
          await Domain().deleteBranchTable(widget.object.table_id.toString());
      if (response['status'] == '1') {
        int syncData = await PosDatabase.instance.updateSyncPosTable(PosTable(
          table_id: widget.object.table_id,
          sync_status: 2,
          updated_at: dateTime,
          table_sqlite_id: widget.object.table_sqlite_id,
        ));
      }
/*
      ---------------------------------end sync-------------------------------
*/
      if (data == 1) {
        Fluttertoast.showToast(msg: 'Successfully delete');
        widget.callBack();
        closeDialog(context);
      } else {
        Fluttertoast.showToast(msg: 'Fail delete');
      }
    } catch (error) {
      Fluttertoast.showToast(msg: 'Something went wrong, please try again');
    }
  }

  closeDialog(BuildContext context) {
    return Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeColor>(builder: (context, ThemeColor color, child) {
      return SingleChildScrollView(
        child: AlertDialog(
          title: Row(
            children: [
              Text(
                widget.object.table_id == null
                    ? '${AppLocalizations.of(context)?.translate('create_table')}'
                    : '${AppLocalizations.of(context)?.translate('edit_table')}',
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
                      color: Colors.red,
                      onPressed: () async {
                        if (await confirm(
                          context,
                          title: Text(
                              '${AppLocalizations.of(context)?.translate('confirm')}'),
                          content: Text(
                              '${AppLocalizations.of(context)?.translate('would you like to remove?')}'),
                          textOK: Text(
                              '${AppLocalizations.of(context)?.translate('yes')}'),
                          textCancel: Text(
                              '${AppLocalizations.of(context)?.translate('no')}'),
                        )) {
                          return deletePosTable();
                        }
                      },
                    ),
            ],
          ),
          content: Container(
            height: 200.0, // Change as per your requirement
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
                            decoration: InputDecoration(
                              errorText: _submitted
                                  ? errorTableNo == null
                                      ? errorTableNo
                                      : AppLocalizations.of(context)
                                          ?.translate(errorTableNo!)
                                  : null,
                              border: OutlineInputBorder(
                                borderSide:
                                    BorderSide(color: color.backgroundColor),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderSide:
                                    BorderSide(color: color.backgroundColor),
                              ),
                              labelText: 'Table No.',
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
                            decoration: InputDecoration(
                              errorText: _submitted
                                  ? errorSeat == null
                                      ? errorSeat
                                      : AppLocalizations.of(context)
                                          ?.translate(errorSeat!)
                                  : null,
                              border: OutlineInputBorder(
                                borderSide:
                                    BorderSide(color: color.backgroundColor),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderSide:
                                    BorderSide(color: color.backgroundColor),
                              ),
                              labelText: 'Seat',
                            ),
                          ),
                        );
                      }),
                ],
              ),
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('${AppLocalizations.of(context)?.translate('close')}'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: widget.object.table_id == null
                  ? Text('${AppLocalizations.of(context)?.translate('add')}')
                  : Text("Submit"),
              onPressed: () async {
                _submit(context);
              },
            ),
          ],
        ),
      );
    });
  }
}
