import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_usb_printer/flutter_usb_printer.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../database/pos_database.dart';
import '../../notifier/theme_color.dart';
import '../../object/cash_record.dart';
import '../../object/printer.dart';
import '../../object/printer_link_category.dart';
import '../../object/receipt_layout.dart';
import '../../object/user.dart';
import '../../translation/AppLocalizations.dart';

class SettlementDialog extends StatefulWidget {
  final List<CashRecord> cashRecordList;
  final Function() callBack;
  const SettlementDialog({Key? key, required this.cashRecordList, required this.callBack}) : super(key: key);

  @override
  State<SettlementDialog> createState() => _SettlementDialogState();
}

class _SettlementDialogState extends State<SettlementDialog> {
  final adminPosPinController = TextEditingController();
  FlutterUsbPrinter flutterUsbPrinter = FlutterUsbPrinter();
  DateFormat dateFormat = DateFormat("yyyy-MM-dd HH:mm:ss");
  List<Printer> printerList = [];
  bool _submitted = false;

  @override
  void initState() {
    super.initState();
    readAllPrinters();
  }

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
    adminPosPinController.dispose();

  }

  String? get errorPassword {
    final text = adminPosPinController.value.text;
    readAdminData(text);
    if (text.isEmpty) {
      return 'password_required';
    }
    return null;
  }

  void _submit(BuildContext context) async {
    setState(() => _submitted = true);
    if (errorPassword == '') {
      await readAdminData(adminPosPinController.text);
      return;
    }
  }

  closeDialog(BuildContext context) {
    return Navigator.of(context).pop(true);
  }
  Future showSecondDialog(BuildContext context, ThemeColor color) {
    return showDialog(
      barrierDismissible: false,
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: Text('Enter admin PIN'),
        content: SizedBox(
          height: 100.0,
          width: 350.0,
          child: Column(
            children: [
              ValueListenableBuilder(
                  valueListenable: adminPosPinController,
                  builder: (context, TextEditingValue value, __) {
                    return Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: TextField(
                        controller: adminPosPinController,
                        decoration: InputDecoration(
                          errorText: _submitted
                              ? errorPassword == null
                              ? errorPassword
                              : AppLocalizations.of(context)
                              ?.translate(errorPassword!)
                              : null,
                          border: OutlineInputBorder(
                            borderSide:
                            BorderSide(color: color.backgroundColor),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide:
                            BorderSide(color: color.backgroundColor),
                          ),
                          labelText: "PIN",
                        ),
                      ),
                    );
                  }),
            ],
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
            child: Text('${AppLocalizations.of(context)?.translate('yes')}'),
            onPressed: () async {
              _submit(context);
            },
          ),
        ],
      ),
    );
  }
  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeColor>(builder: (context, ThemeColor color, child) {
      return AlertDialog(
        title: Text('Confirm do settlement'),
        content: Container(
          child: Text('${AppLocalizations.of(context)?.translate('settlement_desc')}'),
        ),
        actions: [
          TextButton(
            child: Text('${AppLocalizations.of(context)?.translate('close')}'),
            onPressed: (){
              closeDialog(context);
            },
          ),
          TextButton(
            child: Text('${AppLocalizations.of(context)?.translate('yes')}'),
            onPressed: () async {
              await showSecondDialog(context, color);
              closeDialog(context);
            },
          )
        ],
      );
    });
  }

  readAdminData(String pin) async {
    try {
      String dateTime = dateFormat.format(DateTime.now());

      List<User> userData =
      await PosDatabase.instance.readSpecificUserWithRole(pin);
      if (userData.length > 0) {
        closeDialog(context);
        //update all today cash record settlement date
        await updateAllCashRecordSettlement(dateTime);
        //print settlement list
        await _printSettlementList(dateTime);
      } else {
        Fluttertoast.showToast(
            backgroundColor: Color(0xFFFF0000), msg: "Password incorrect");
      }
      widget.callBack();
    } catch (e) {
      print('delete error ${e}');
    }

  }

  _printSettlementList(String dateTime) async {
    print('printer called');
    try {
      for (int i = 0; i < printerList.length; i++) {
        List<PrinterLinkCategory> data = await PosDatabase.instance
            .readPrinterLinkCategory(printerList[i].printer_sqlite_id!);
        for (int j = 0; j < data.length; j++) {
          if (data[j].category_sqlite_id == '3') {
            if (printerList[i].type == 0) {
              var printerDetail = jsonDecode(printerList[i].value!);
              var data = Uint8List.fromList(await ReceiptLayout().printSettlementList80mm(true, null, dateTime));
              bool? isConnected = await flutterUsbPrinter.connect(
                  int.parse(printerDetail['vendorId']),
                  int.parse(printerDetail['productId']));
              if (isConnected == true) {
                await flutterUsbPrinter.write(data);
              } else {
                print('not connected');
              }
            } else {
              print("print lan");
            }
          }
        }
      }
    } catch (e) {
      print('Printer Connection Error');
      //response = 'Failed to get platform version.';
    }
  }


  updateAllCashRecordSettlement(String dateTime) async {
    for(int i = 0; i < widget.cashRecordList.length; i++){
      CashRecord cashRecord = CashRecord(
          settlement_date: dateTime,
          sync_status: 0,
          updated_at: dateTime,
          cash_record_sqlite_id:  widget.cashRecordList[i].cash_record_sqlite_id);

      int data = await PosDatabase.instance.updateCashRecord(cashRecord);
    }
  }

  readAllPrinters() async {
    final prefs = await SharedPreferences.getInstance();
    final int? branch_id = prefs.getInt('branch_id');

    List<Printer> data = await PosDatabase.instance.readAllBranchPrinter(branch_id!);
    printerList = List.from(data);
  }
}