import 'dart:async';
import 'dart:convert';

import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';
import 'package:pos_system/database/pos_database.dart';
import 'package:pos_system/notifier/connectivity_change_notifier.dart';
import 'package:pos_system/object/cash_record.dart';
import 'package:pos_system/object/payment_link_company.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:crypto/crypto.dart';

import '../../database/domain.dart';
import '../../main.dart';
import '../../notifier/theme_color.dart';
import '../../object/app_setting.dart';
import '../printing_layout/print_receipt.dart';
import '../../object/printer.dart';
import '../../translation/AppLocalizations.dart';
import '../../utils/Utils.dart';
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
  final List<String> paymentLists = [];
  int? selectedPayment = 0;
  String selectedPaymentTypeId = '';

  @override
  void initState() {
    super.initState();
    readAllPrinters();
    readLastSettlement();
    getAllAppSetting();
    readPaymentMethod();
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

  _submit(BuildContext context) async {
    setState(() => _submitted = true);
    if (errorRemark == null && errorAmount == null) {
      // Disable the button after it has been pressed
      setState(() {
        isButtonDisabled = true;
      });
      if (widget.isCashIn) {
        print('cash in');
        await createCashRecord(1);
      } else if (widget.isCashOut) {
        print('cash-out');
        await createCashRecord(2);
      } else {
        await createCashRecord(3);
      }
      closeDialog(context);
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
          child: LayoutBuilder(builder: (context, constraints) {
            if (constraints.maxWidth > 800) {
              return AlertDialog(
                title: widget.isNewDay
                    ? Text(AppLocalizations.of(context)!.translate('opening_balance'))
                    : widget.isCashIn
                        ? Text(AppLocalizations.of(context)!.translate('cash_in'))
                        : Text(AppLocalizations.of(context)!.translate('cash_out')),
                content: Container(
                  height: widget.isNewDay ? MediaQuery.of(context).size.height / 6 : MediaQuery.of(context).size.height / 3,
                  width: widget.isNewDay ? MediaQuery.of(context).size.height / 2 : MediaQuery.of(context).size.width / 4,
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          child: Visibility(
                            visible: widget.isNewDay ? false : true,
                            child: DropdownButtonHideUnderline(
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: DropdownButton2(
                                  isExpanded: true,
                                  buttonStyleData: ButtonStyleData(
                                    height: 60,
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
                                  items: paymentLists.asMap().entries.map((sort) => DropdownMenuItem<int>(
                                    value: sort.key,
                                    child: Text(sort.value.split(':').last,
                                      overflow: TextOverflow.visible,
                                      style: const TextStyle(
                                        fontSize: 14,
                                      ),
                                    ),
                                  )).toList(),
                                  value: selectedPayment,
                                  onChanged: (int? value) {
                                    setState(() {
                                      selectedPayment = value;
                                      selectedPaymentTypeId = paymentLists[selectedPayment!].split(':').first;
                                    });
                                  },
                                ),
                              ),
                            ),
                          ),
                        ),
                        Container(
                          child: Visibility(
                            visible: widget.isNewDay ? false : true,
                            child: ValueListenableBuilder(
                                // Note: pass _controller to the animation argument
                                valueListenable: remarkController,
                                builder: (context, TextEditingValue value, __) {
                                  return SizedBox(
                                    height: 85,
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
                                          labelText: AppLocalizations.of(context)!.translate('remark'),
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
                                      onSubmitted: (input) async {
                                        try {
                                          double.parse(input);
                                          await _submit(context);
                                        } catch (e) {
                                          Fluttertoast.showToast(
                                            backgroundColor: Color(0xFFFF0000),
                                            msg: AppLocalizations.of(context)!.translate('invalid_input'),
                                          );
                                        }
                                      },
                                      inputFormatters: [
                                        FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                                      ],
                                      keyboardType: TextInputType.numberWithOptions(decimal: true),
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
                                        labelText: AppLocalizations.of(context)!.translate('amount'),
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
                                    Container(child: Text(AppLocalizations.of(context)!.translate('last_settlement_opening_balance')+': ${amount}')),
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
                            : () async {
                          try {
                            setState(() {
                              isButtonDisabled = true;
                            });
                            double.parse(amountController.text);
                            await _submit(context);
                          } catch (e) {
                            Fluttertoast.showToast(backgroundColor: Color(0xFFFF0000), msg: AppLocalizations.of(context)!.translate('invalid_input'));
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
                          : () async {
                              try {
                                double.parse(amountController.text);
                                await _submit(context);
                              } catch (e) {
                                Fluttertoast.showToast(backgroundColor: Color(0xFFFF0000), msg: AppLocalizations.of(context)!.translate('invalid_input'));
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
                      ? Text(AppLocalizations.of(context)!.translate('opening_balance'))
                      : widget.isCashIn
                          ? Text(AppLocalizations.of(context)!.translate('cash_in'))
                          : Text(AppLocalizations.of(context)!.translate('cash_out')),
                  content: Container(
                    width: constraints.maxWidth > 300 ? 300 : MediaQuery.of(context).size.width,
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            child: Visibility(
                              visible: widget.isNewDay ? false : true,
                              child: DropdownButtonHideUnderline(
                                child: Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: DropdownButton2(
                                    isExpanded: true,
                                    buttonStyleData: ButtonStyleData(
                                      height: 60,
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
                                    items: paymentLists.asMap().entries.map((sort) => DropdownMenuItem<int>(
                                      value: sort.key,
                                      child: Text(sort.value.split(':').last,
                                        overflow: TextOverflow.visible,
                                        style: const TextStyle(
                                          fontSize: 14,
                                        ),
                                      ),
                                    )).toList(),
                                    value: selectedPayment,
                                    onChanged: (int? value) {
                                      setState(() {
                                        selectedPayment = value;
                                        selectedPaymentTypeId = paymentLists[selectedPayment!].split(':').first;
                                      });
                                    },
                                  ),
                                ),
                              ),
                            ),
                          ),
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
                                          labelText: AppLocalizations.of(context)!.translate('remark'),
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
                                      keyboardType: TextInputType.numberWithOptions(decimal: true),
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
                                        labelText: AppLocalizations.of(context)!.translate('amount'),
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
                                    Text(AppLocalizations.of(context)!.translate('last_settlement_opening_balance')+': '),
                                    ChoiceChip(
                                      label: Text(' $amount '),
                                      selected: true,
                                      elevation: 5,
                                      onSelected: (chipSelected) {
                                        amountController.text = amount;
                                      },
                                    ),
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
                          : () async {
                              setState(() {
                                isButtonDisabled = true;
                              });
                              await _submit(context);
                            },
                    )
                  ],
                ),
              );
            }
          }),
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
    var md5Hash = md5.convert(utf8.encode(bytes));
    return Utils.shortHashString(hashCode: md5Hash);
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

  createCashRecord(int type) async {
    try {
      DateFormat dateFormat = DateFormat("yyyy-MM-dd HH:mm:ss");
      String dateTime = dateFormat.format(DateTime.now());
      List<String> _value = [];
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
          payment_type_id: widget.isNewDay ? await getCashPaymentId() : selectedPaymentTypeId ?? '',
          type: widget.isNewDay ? 0 : type,
          user_id: userObject['user_id'].toString(),
          settlement_key: '',
          settlement_date: '',
          sync_status: 0,
          created_at: dateTime,
          updated_at: '',
          soft_delete: '');

      CashRecord data = await PosDatabase.instance.insertSqliteCashRecordCashInOutOB(cashRecordObject);
      CashRecord updatedData = await insertCashRecordKey(data, dateTime);
      _value.add(jsonEncode(updatedData));
      //sync to cloud
      print('cash record value: ${_value.toString()}');
      // await syncCashRecordToCloud(_value.toString());
      if (this.isLogOut == true) {
        openLogOutDialog();
      } else {
        if (widget.isNewDay) {
          if (appSettingList.isNotEmpty && appSettingList[0].open_cash_drawer == 1) {
            await callOpenCashDrawer();
          }
        } else {
          await callOpenCashDrawer();
        }
        widget.callBack();
      }
    } catch (e) {
      if(mounted){
        setState(() {
          this.isButtonDisabled = false;
        });
      }
      print('cash record error: ${e}');
      Fluttertoast.showToast(backgroundColor: Color(0xFFFF0000), msg: AppLocalizations.of(context)!.translate('create_cash_record_error'));
    }
  }

  callOpenCashDrawer() async {
    int printStatus = await PrintReceipt().cashDrawer(printerList: this.printerList);
    if(printStatus == 1){
      Fluttertoast.showToast(
          backgroundColor: Colors.red,
          msg: "${AppLocalizations.of(context)?.translate('printer_not_connected')}");
    } else if (printStatus == 2){
      Fluttertoast.showToast(
          backgroundColor: Colors.orangeAccent,
          msg: "${AppLocalizations.of(context)?.translate('printer_connection_timeout')}");
    }else if(printStatus == 3){
      Fluttertoast.showToast(backgroundColor: Colors.red, msg: AppLocalizations.of(context)!.translate('no_cashier_printer_added'));
    } else if(printStatus == 4){
      Fluttertoast.showToast(
          backgroundColor: Colors.orangeAccent,
          msg: "${AppLocalizations.of(context)?.translate('no_cashier_printer')}");
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
    try{
      final prefs = await SharedPreferences.getInstance();
      final int? device_id = prefs.getInt('device_id');
      final String? login_value = prefs.getString('login_value');
      if(mainSyncToCloud.count == 0){
        mainSyncToCloud.count = 1;
        Map data = await Domain().syncLocalUpdateToCloud(device_id: device_id.toString(), value: login_value.toString(), cash_record_value: value);
        if (data['status'] == '1') {
          List responseJson = data['data'];
          await PosDatabase.instance.updateCashRecordSyncStatusFromCloud(responseJson[0]['cash_record_key']);
          mainSyncToCloud.resetCount();
        } else if (data['status'] == '7') {
          mainSyncToCloud.resetCount();
          this.isLogOut = true;
        }else if (data['status'] == '8'){
          print('cash dialog timeout');
          mainSyncToCloud.resetCount();
          throw TimeoutException("Time out");
        }
      }
    }catch(e){
      mainSyncToCloud.resetCount();
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

  readPaymentMethod() async {
    List<PaymentLinkCompany> data = await PosDatabase.instance.readPaymentMethods();
    paymentLists.addAll(data.map((payment) => '${payment.payment_type_id}:${payment.name!}').toList());
    if(paymentLists.isNotEmpty){
      selectedPaymentTypeId = paymentLists[0].split(':').first;
    }
  }

  Future<String> getCashPaymentId() async {
    String paymentTypeId = '';
    List<PaymentLinkCompany> data = await PosDatabase.instance.readPaymentMethods();
    for(int i = 0; i < data.length; i++){
      if(data[i].name == 'Cash'){
        paymentTypeId = data[i].payment_type_id!;
      }
    }
    return paymentTypeId;
  }
}
