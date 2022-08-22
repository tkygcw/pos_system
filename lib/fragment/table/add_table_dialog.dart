import 'package:confirm_dialog/confirm_dialog.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pos_system/database/pos_database.dart';
import 'package:pos_system/notifier/theme_color.dart';
import 'package:pos_system/object/table.dart';
import 'package:pos_system/translation/AppLocalizations.dart';
import 'package:provider/provider.dart';

class AddTableDialog extends StatefulWidget {
  final Function() callBack;
  final PosTable object;

  const AddTableDialog({required this.callBack, required this.object, Key? key})
      : super(key: key);

  @override
  _AddTableDialogState createState() => _AddTableDialogState();
}

class _AddTableDialogState extends State<AddTableDialog> {
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

  String get errorTableNo {
    final text = tableNoController.value.text;
    if (text.isEmpty) {
      return 'table_no_required';
    }
    return '';
  }

  String get errorSeat {
    final text = seatController.value.text;
    if (text.isEmpty) {
      return 'seat_required';
    }
    return '';
  }

  void _submit(BuildContext context) {
    setState(() => _submitted = true);
    if (errorTableNo == '' && errorSeat == '') {
      if (isUpdate) {
        updatePosTable();
      } else {
        createPosMenu();
      }
      widget.callBack();
      closeDialog(context);
      return;
    }
  }

  void createPosMenu() async {
    print('create called!');
    DateFormat dateFormat = DateFormat("yyyy-MM-dd HH:mm:ss");
    String dateTime = dateFormat.format(DateTime.now());

    PosTable status = await PosDatabase.instance.insertPosTable(PosTable(
        table_id: 0,
        branch_id: '5',
        number: tableNoController.text,
        seats: seatController.text,
        status: 0,
        created_at: dateTime,
        updated_at: '',
        soft_delete: ''));
  }

  void updatePosTable() async {
    print('updated');
    DateFormat dateFormat = DateFormat("yyyy-MM-dd HH:mm:ss");
    String dateTime = dateFormat.format(DateTime.now());

    PosTable posTableData = PosTable(
        table_sqlite_id: widget.object.table_sqlite_id,
        number: tableNoController.text,
        seats: seatController.text,
        updated_at: dateTime);

    int data = await PosDatabase.instance.updatePosTable(posTableData);
  }

  void deletePosTable() async {
    print('deleted');
    DateFormat dateFormat = DateFormat("yyyy-MM-dd HH:mm:ss");
    String dateTime = dateFormat.format(DateTime.now());

    PosTable posTableData = PosTable(
        soft_delete: dateTime, table_sqlite_id: widget.object.table_sqlite_id);

    int data = await PosDatabase.instance.deletePosTable(posTableData);
    widget.callBack();
    Navigator.of(context).pop();
  }

  closeDialog(BuildContext context) {
    return Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeColor>(builder: (context, ThemeColor color, child) {
      return AlertDialog(
        title: Row(
          children: [
            Text(
        '${AppLocalizations.of(context)?.translate('confirm')}',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              "Create Table",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            Spacer(),
            IconButton(
              icon: const Icon(Icons.delete_outlined),
              color: Colors.red,
              onPressed: () async {
                if (await confirm(
                  context,
                  title: Text(
                      '${AppLocalizations.of(context)?.translate('confirm')}'),
                  content: Text(
                      '${AppLocalizations.of(context)?.translate('would you like to remove?')}'),
                  textOK:
                      Text('${AppLocalizations.of(context)?.translate('yes')}'),
                  textCancel:
                      Text('${AppLocalizations.of(context)?.translate('no')}'),
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
                                ? AppLocalizations.of(context)
                                    ?.translate(errorTableNo)
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
                                ? AppLocalizations.of(context)
                                    ?.translate(errorSeat)
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
            child: Text('${AppLocalizations.of(context)?.translate('add')}'),
            onPressed: () async {
              _submit(context);
            },
          ),
        ],
      );
    });
  }
}
