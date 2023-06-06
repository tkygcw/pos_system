import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';
import 'package:pos_system/database/pos_database.dart';
import 'package:pos_system/notifier/connectivity_change_notifier.dart';
import 'package:pos_system/object/cash_record.dart';
import 'package:pos_system/object/receipt_layout.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:crypto/crypto.dart';

import '../../database/domain.dart';
import '../../main.dart';
import '../../notifier/theme_color.dart';
import '../../object/app_setting.dart';
import '../../object/print_receipt.dart';
import '../../object/printer.dart';
import '../../translation/AppLocalizations.dart';
import '../logout_dialog.dart';

class CashDialog extends StatefulWidget {
  final bool isCashIn;
  final bool isCashOut;
  final bool isNewDay;
  final Function() callBack;

  const CashDialog({Key? key, required this.isCashIn, required this.callBack, required this.isCashOut, required this.isNewDay}) : super(key: key);

  @override
  State<CashDialog> createState() => _CashDialogState();
}

class _CashDialogState extends State<CashDialog> {
  final remarkController = TextEditingController();
  final amountController = TextEditingController();
  List<Printer> printerList = [];
  List<AppSetting> appSettingList = [];
  String amount = '';
  bool _isLoad = false;
  bool _submitted = false;
  bool isButtonDisabled = false, isLogOut = false;

  @override
  void initState() {
    super.initState();
    readAllPrinters();
    readLastSettlement();
    getAllAppSetting();
  }

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
    remarkController.dispose();
    amountController.dispose();
  }

  readAllPrinters() async {
    printerList = await PrintReceipt().readAllPrinters();
  }

  String? get errorRemark {
    final text = remarkController.value.text;
    if (text.isEmpty && widget.isNewDay == false) {
      return 'remark_required';
    }
    return null;
  }

  String? get errorAmount {
    final text = amountController.value.text;
    if (text.isEmpty) {
      return 'amount_required';
    }
    return null;
  }

  void _submit(BuildContext context, ConnectivityChangeNotifier connectivity) {
    setState(() => _submitted = true);
    if (errorRemark == null && errorAmount == null) {
      // Disable the button after it has been pressed
      setState(() {
        isButtonDisabled = true;
      });
      if (widget.isCashIn) {
        print('cash in');
        createCashRecord(1, connectivity);
      } else if (widget.isCashOut) {
        print('cash-out');
        createCashRecord(2, connectivity);
      } else {
        createCashRecord(3, connectivity);
      }
    }
  }

  closeDialog(BuildContext context) {
    return Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeColor>(builder: (context, ThemeColor color, child) {
      return Consumer<ConnectivityChangeNotifier>(builder: (context, ConnectivityChangeNotifier connectivity, child) {
        return Center(
          child: SingleChildScrollView(
            physics: NeverScrollableScrollPhysics(),
            child: LayoutBuilder(builder: (context, constraints) {
              if (constraints.maxWidth > 800) {
                return AlertDialog(
                  title: widget.isNewDay
                      ? Text('Opening Balance')
                      : widget.isCashIn
                          ? Text('Cash-in')
                          : Text('Cash-out'),
                  content: Container(
                    height: widget.isNewDay ? MediaQuery.of(context).size.height / 6 : MediaQuery.of(context).size.height / 4,
                    width: widget.isNewDay ? MediaQuery.of(context).size.height / 2 : MediaQuery.of(context).size.width / 4,
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            child: Visibility(
                              visible: widget.isNewDay ? false : true,
                              child: ValueListenableBuilder(
                                  // Note: pass _controller to the animation argument
                                  valueListenable: remarkController,
                                  builder: (context, TextEditingValue value, __) {
                                    return SizedBox(
                                      height: 100,
                                      child: Padding(
                                        padding: const EdgeInsets.all(8.0),
                                        child: TextField(
                                          controller: remarkController,
                                          decoration: InputDecoration(
                                            errorText: _submitted
                                                ? errorRemark == null
                                                    ? errorRemark
                                                    : AppLocalizations.of(context)?.translate(errorRemark!)
                                                : null,
                                            border: OutlineInputBorder(
                                              borderSide: BorderSide(color: color.backgroundColor),
                                            ),
                                            focusedBorder: OutlineInputBorder(
                                              borderSide: BorderSide(color: color.backgroundColor),
                                            ),
                                            labelText: 'Remark',
                                          ),
                                        ),
                                      ),
                                    );
                                  }),
                            ),
                          ),
                          Container(
                            child: ValueListenableBuilder(
                                // Note: pass _controller to the animation argument
                                valueListenable: amountController,
                                builder: (context, TextEditingValue value, __) {
                                  return SizedBox(
                                    height: 85,
                                    child: Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: TextField(
                                        inputFormatters: [
                                          FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                                        ],
                                        keyboardType: TextInputType.number,
                                        controller: amountController,
                                        decoration: InputDecoration(
                                          errorText: _submitted
                                              ? errorAmount == null
                                                  ? errorAmount
                                                  : AppLocalizations.of(context)?.translate(errorAmount!)
                                              : null,
                                          border: OutlineInputBorder(
                                            borderSide: BorderSide(color: color.backgroundColor),
                                          ),
                                          focusedBorder: OutlineInputBorder(
                                            borderSide: BorderSide(color: color.backgroundColor),
                                          ),
                                          labelText: 'Amount',
                                        ),
                                      ),
                                    ),
                                  );
                                }),
                          ),
                          widget.isNewDay && _isLoad && this.amount != ''
                              ? Container(
                                  margin: EdgeInsets.only(left: 10),
                                  alignment: Alignment.topLeft,
                                  height: MediaQuery.of(context).size.height / 18,
                                  child: Row(
                                    children: [
                                      Container(child: Text('Last settlement opening balance: ${amount}')),
                                      Spacer(),
                                      Container(
                                          child: ElevatedButton(
                                        child: Text('${AppLocalizations.of(context)?.translate('add')}'),
                                        onPressed: () {
                                          amountController.text = amount;
                                        },
                                        style: ElevatedButton.styleFrom(backgroundColor: color.backgroundColor),
                                      ))
                                    ],
                                  ))
                              : Container()
                        ],
                      ),
                    ),
                  ),
                  actions: [
                    Visibility(
                      visible: widget.isNewDay ? false : true,
                      child: SizedBox(
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
                    ),
                    widget.isNewDay ?
                    Center(
                      child: SizedBox(
                        width: MediaQuery.of(context).size.width / 7,
                        height: MediaQuery.of(context).size.height / 12,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: color.buttonColor),
                          child: Text('${AppLocalizations.of(context)?.translate('add')}'),
                          onPressed: isButtonDisabled
                              ? null
                              : () {
                            try {
                              double.parse(amountController.text);
                              _submit(context, connectivity);
                            } catch (e) {
                              Fluttertoast.showToast(backgroundColor: Color(0xFFFF0000), msg: "Invalid Input!");
                            }
                          },
                        ),
                      ),
                    ) :
                    SizedBox(
                      width: MediaQuery.of(context).size.width / 5,
                      height: MediaQuery.of(context).size.height / 12,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: color.buttonColor),
                        child: Text('${AppLocalizations.of(context)?.translate('add')}'),
                        onPressed: isButtonDisabled
                            ? null
                            : () {
                                try {
                                  double.parse(amountController.text);
                                  _submit(context, connectivity);
                                } catch (e) {
                                  Fluttertoast.showToast(backgroundColor: Color(0xFFFF0000), msg: "Invalid Input!");
                                }
                              },
                      ),
                    )
                  ],
                );
              } else {
                ///mobile layout
                return SingleChildScrollView(
                  child: AlertDialog(
                    title: widget.isNewDay
                        ? Text('Opening Balance')
                        : widget.isCashIn
                            ? Text('Cash-in')
                            : Text('Cash-out'),
                    content: Container(
                      height: widget.isNewDay ? MediaQuery.of(context).size.height / 3 : 150,
                      width: widget.isNewDay ? MediaQuery.of(context).size.height / 1 : MediaQuery.of(context).size.width / 2,
                      child: SingleChildScrollView(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              child: Visibility(
                                visible: widget.isNewDay ? false : true,
                                child: ValueListenableBuilder(
                                    // Note: pass _controller to the animation argument
                                    valueListenable: remarkController,
                                    builder: (context, TextEditingValue value, __) {
                                      return Padding(
                                        padding: const EdgeInsets.all(8.0),
                                        child: TextField(
                                          autofocus: true,
                                          controller: remarkController,
                                          decoration: InputDecoration(
                                            errorText: _submitted
                                                ? errorRemark == null
                                                    ? errorRemark
                                                    : AppLocalizations.of(context)?.translate(errorRemark!)
                                                : null,
                                            border: OutlineInputBorder(
                                              borderSide: BorderSide(color: color.backgroundColor),
                                            ),
                                            focusedBorder: OutlineInputBorder(
                                              borderSide: BorderSide(color: color.backgroundColor),
                                            ),
                                            labelText: 'Remark',
                                          ),
                                        ),
                                      );
                                    }),
                              ),
                            ),
                            Container(
                              child: ValueListenableBuilder(
                                  // Note: pass _controller to the animation argument
                                  valueListenable: amountController,
                                  builder: (context, TextEditingValue value, __) {
                                    return Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: TextField(
                                        inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
                                        keyboardType: TextInputType.number,
                                        controller: amountController,
                                        decoration: InputDecoration(
                                          errorText: _submitted
                                              ? errorAmount == null
                                                  ? errorAmount
                                                  : AppLocalizations.of(context)?.translate(errorAmount!)
                                              : null,
                                          border: OutlineInputBorder(
                                            borderSide: BorderSide(color: color.backgroundColor),
                                          ),
                                          focusedBorder: OutlineInputBorder(
                                            borderSide: BorderSide(color: color.backgroundColor),
                                          ),
                                          labelText: 'Amount',
                                        ),
                                      ),
                                    );
                                  }),
                            ),
                            Visibility(
                              visible: widget.isNewDay && _isLoad && this.amount != '' ? true : false,
                              child: Container(
                                  margin: EdgeInsets.only(left: 10),
                                  alignment: Alignment.topLeft,
                                  height: MediaQuery.of(context).size.height / 9,
                                  child: Row(
                                    children: [
                                      Container(child: Text('Last settlement opening balance: ${amount}')),
                                      Spacer(),
                                      Container(
                                          child: ElevatedButton(
                                        child: Text('${AppLocalizations.of(context)?.translate('add')}'),
                                        onPressed: () {
                                          amountController.text = amount;
                                        },
                                        style: ElevatedButton.styleFrom(primary: color.backgroundColor),
                                      ))
                                    ],
                                  )),
                            )
                          ],
                        ),
                      ),
                    ),
                    actions: [
                      widget.isNewDay
                          ? Container()
                          : TextButton(
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
                      TextButton(
                        child: Text('${AppLocalizations.of(context)?.translate('add')}'),
                        onPressed: isButtonDisabled
                            ? null
                            : () {
                                _submit(context, connectivity);
                              },
                      )
                    ],
                  ),
                );
              }
            }),
          ),
        );
      });
    });
  }

/*
  ----------------DB Query part------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
*/

  generateCashRecordKey(CashRecord cashRecord) async {
    final prefs = await SharedPreferences.getInstance();
    final int? device_id = prefs.getInt('device_id');
    var bytes = cashRecord.created_at!.replaceAll(new RegExp(r'[^0-9]'), '') + cashRecord.cash_record_sqlite_id.toString() + device_id.toString();
    return md5.convert(utf8.encode(bytes)).toString();
  }

  insertCashRecordKey(CashRecord cashRecord, String dateTime) async {
    CashRecord? _record;
    int _status = 0;
    String? _key;
    _key = await generateCashRecordKey(cashRecord);
    if (_key != null) {
      CashRecord cashRecordObject = CashRecord(cash_record_key: _key, updated_at: dateTime, cash_record_sqlite_id: cashRecord.cash_record_sqlite_id);
      int data = await PosDatabase.instance.updateCashRecordUniqueKey(cashRecordObject);
      if (data == 1) {
        _record = await PosDatabase.instance.readSpecificCashRecord(cashRecordObject.cash_record_sqlite_id!);
      }
    }

    return _record;
  }

  createCashRecord(int type, ConnectivityChangeNotifier connectivity) async {
    try {
      DateFormat dateFormat = DateFormat("yyyy-MM-dd HH:mm:ss");
      String dateTime = dateFormat.format(DateTime.now());
      List<String> _value = [];
      bool _isInserted = false;
      final prefs = await SharedPreferences.getInstance();
      final int? branch_id = prefs.getInt('branch_id');
      final String? pos_user = prefs.getString('pos_pin_user');
      print('pos user: ${pos_user.toString()}');
      final String? login_user = prefs.getString('user');
      Map userObject = json.decode(pos_user!);
      Map logInUser = json.decode(login_user!);

      CashRecord cashRecordObject = CashRecord(
          cash_record_id: 0,
          cash_record_key: '',
          company_id: logInUser['company_id'].toString(),
          branch_id: branch_id.toString(),
          remark: widget.isNewDay ? 'Opening Balance' : remarkController.text,
          amount: amountController.text,
          payment_name: '',
          payment_type_id: '',
          type: widget.isNewDay ? 0 : type,
          user_id: userObject['user_id'].toString(),
          settlement_key: '',
          settlement_date: '',
          sync_status: 0,
          created_at: dateTime,
          updated_at: '',
          soft_delete: '');

      CashRecord data = await PosDatabase.instance.insertSqliteCashRecord(cashRecordObject);
      CashRecord updatedData = await insertCashRecordKey(data, dateTime);
      _value.add(jsonEncode(updatedData));
      //sync to cloud
      print('cash record value: ${_value.toString()}');
      await syncCashRecordToCloud(_value.toString());
      if (this.isLogOut == true) {
        openLogOutDialog();
      } else {
        closeDialog(context);
        widget.callBack();
        if (widget.isNewDay) {
          if (appSettingList.isNotEmpty && appSettingList[0].open_cash_drawer == 1) {
            await PrintReceipt().cashDrawer(context, printerList: this.printerList);
          }
        } else {
          await PrintReceipt().cashDrawer(context, printerList: this.printerList);
        }
      }
    } catch (e) {
      setState(() {
        this.isButtonDisabled = false;
      });
      print('cash record error: ${e}');
      Fluttertoast.showToast(backgroundColor: Color(0xFFFF0000), msg: "Create cash record error: ${e}");
    }
  }

  Future<Future<Object?>> openLogOutDialog() async {
    return showGeneralDialog(
        barrierColor: Colors.black.withOpacity(0.5),
        transitionBuilder: (context, a1, a2, widget) {
          final curvedValue = Curves.easeInOutBack.transform(a1.value) - 1.0;
          return Transform(
            transform: Matrix4.translationValues(0.0, curvedValue * 200, 0.0),
            child: Opacity(
              opacity: a1.value,
              child: LogoutConfirmDialog(),
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

  syncCashRecordToCloud(String value) async {
    final prefs = await SharedPreferences.getInstance();
    final int? device_id = prefs.getInt('device_id');
    final String? login_value = prefs.getString('login_value');
    bool _hasInternetAccess = await Domain().isHostReachable();
    if (_hasInternetAccess) {
      print('value: ${login_value.toString()}');
      if(mainSyncToCloud.count == 0){
        Map data = await Domain().syncLocalUpdateToCloud(device_id: device_id.toString(), value: login_value.toString(), cash_record_value: value);
        if (data['status'] == '1') {
          List responseJson = data['data'];
          await PosDatabase.instance.updateCashRecordSyncStatusFromCloud(responseJson[0]['cash_record_key']);
        } else if (data['status'] == '7') {
          this.isLogOut = true;
        }
      }
    }
  }

  getAllAppSetting() async {
    List<AppSetting> data = await PosDatabase.instance.readAllAppSetting();
    if (data.length > 0) {
      appSettingList = List.from(data);
    }
  }

  readLastSettlement() async {
    final prefs = await SharedPreferences.getInstance();
    final int? branch_id = prefs.getInt('branch_id');

    List<CashRecord> data = await PosDatabase.instance.readSpecificLatestSettlementCashRecord(branch_id.toString());
    if (data.length > 0) {
      amount = data[0].amount!;
    }

    setState(() {
      _isLoad = true;
    });
  }
}
