import 'dart:convert';

import 'package:confirm_dialog/confirm_dialog.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';
import 'package:page_transition/page_transition.dart';
import 'package:pos_system/database/pos_database.dart';
import 'package:pos_system/fragment/settlement/cash_box_dialog.dart';
import 'package:pos_system/fragment/settlement/cash_dialog.dart';
import 'package:pos_system/fragment/settlement/history_dialog.dart';
import 'package:pos_system/fragment/settlement/settlement_dialog.dart';
import 'package:pos_system/object/payment_link_company.dart';
import 'package:pos_system/page/pos_pin.dart';
import 'package:pos_system/page/progress_bar.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../notifier/theme_color.dart';
import '../../object/cash_record.dart';
import '../../translation/AppLocalizations.dart';

class SettlementPage extends StatefulWidget {
  const SettlementPage({Key? key}) : super(key: key);

  @override
  State<SettlementPage> createState() => _SettlementPageState();
}

class _SettlementPageState extends State<SettlementPage> {
  List<CashRecord> cashRecordList = [];
  List<String> paymentNameList = [];
  String selectedPayment = 'All/Cash Drawer';
  bool isLoad = false;

  @override
  void initState() {
    super.initState();
    readPaymentLinkCompany();
    readCashRecord();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeColor>(builder: (context, ThemeColor color, child) {
      return Scaffold(
        body: isLoad
            ? Container(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        Container(
                            margin: EdgeInsets.fromLTRB(0, 0, 0, 10),
                            alignment: Alignment.topLeft,
                            child: Row(
                              children: [
                                Text(
                                  "Settlement",
                                  style: TextStyle(fontSize: 25),
                                ),
                                Spacer(),
                                Container(
                                  margin: EdgeInsets.only(right: 10),
                                  width: MediaQuery.of(context).size.height / 3,
                                  child: DropdownButton<String>(
                                    onChanged: (String? value) {
                                      setState(() {
                                        selectedPayment = value!;
                                        readCashRecord();
                                      });
                                      //getCashRecord();
                                    },
                                    menuMaxHeight: 300,
                                    value: selectedPayment,
                                    // Hide the default underline
                                    underline: Container(),
                                    icon: Icon(
                                      Icons.arrow_drop_down,
                                      color: color.backgroundColor,
                                    ),
                                    isExpanded: true,
                                    // The list of options
                                    items: paymentNameList
                                        .map((e) => DropdownMenuItem(
                                              value: e,
                                              child: Container(
                                                alignment: Alignment.centerLeft,
                                                child: Text(
                                                  e,
                                                  style:
                                                      TextStyle(fontSize: 18),
                                                ),
                                              ),
                                            ))
                                        .toList(),
                                    // Customize the selected item
                                    selectedItemBuilder:
                                        (BuildContext context) =>
                                            paymentNameList
                                                .map((e) => Center(
                                                      child: Text(e),
                                                    ))
                                                .toList(),
                                  ),
                                ),
                              ],
                            )),
                        Divider(
                          height: 10,
                          color: Colors.grey,
                        ),
                        Container(
                          child: Row(
                            children: [
                              ElevatedButton(
                                  child: Text('Cash-in'),
                                  onPressed: () {
                                    openCashDialog(true, false);
                                  },
                                  style: ElevatedButton.styleFrom(
                                      primary: color.backgroundColor)),
                              Container(
                                height: 30,
                                child: VerticalDivider(
                                    color: Colors.grey, thickness: 1),
                              ),
                              ElevatedButton(
                                child: Text('Cash-out'),
                                onPressed: () {
                                  if(cashRecordList.length > 0){
                                    openCashDialog(false, true);
                                  } else {
                                    Fluttertoast.showToast(
                                        backgroundColor: Color(0xFFFF0000),
                                        msg: "No record");
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                    primary: color.buttonColor),
                              ),
                              Container(
                                height: 30,
                                child: VerticalDivider(
                                    color: Colors.grey, thickness: 1),
                              ),
                              ElevatedButton(
                                child: Text('Settlement'),
                                onPressed: () {
                                  if(cashRecordList.length > 0){
                                    openSettlementDialog(cashRecordList);
                                  } else {
                                    Fluttertoast.showToast(
                                        backgroundColor: Color(0xFFFF0000),
                                        msg: "No record");
                                  }

                                },
                                style: ElevatedButton.styleFrom(
                                    primary: color.backgroundColor),
                              ),
                              Container(
                                height: 30,
                                child: VerticalDivider(
                                    color: Colors.grey, thickness: 1),
                              ),
                              ElevatedButton(
                                child: Text('Settlement history'),
                                onPressed: () {
                                  openSettlementHistoryDialog();
                                },
                                style: ElevatedButton.styleFrom(
                                    primary: color.buttonColor),
                              ),
                              Container(
                                height: 30,
                                child: VerticalDivider(
                                    color: Colors.grey, thickness: 1),
                              ),
                              ElevatedButton(
                                child: Text('Transfer ownership'),
                                onPressed: () async {

                                  if (await confirm(
                                    context,
                                    title: Text(
                                        '${AppLocalizations.of(context)?.translate('confirm_pos_pin')}'),
                                    content: Text(
                                        '${AppLocalizations.of(context)?.translate('to_pos_pin')}'),
                                    textOK: Text(
                                        '${AppLocalizations.of(context)?.translate('yes')}'),
                                    textCancel: Text(
                                        '${AppLocalizations.of(context)?.translate('no')}'),
                                  )) {
                                    return toPosPinPage();
                                  }

                                },
                                style: ElevatedButton.styleFrom(
                                    primary: color.backgroundColor),
                              ),
                              Container(
                                height: 30,
                                child: VerticalDivider(
                                    color: Colors.grey, thickness: 1),
                              ),
                              ElevatedButton(
                                child: Text('Open cash drawer'),
                                onPressed: () {
                                  openCashBoxDialog();
                                },
                                style: ElevatedButton.styleFrom(
                                    primary: color.buttonColor),
                              ),
                            ],
                          ),
                        ),
                        Divider(
                          height: 10,
                          color: Colors.grey,
                        ),
                        cashRecordList.length > 0
                            ? Container(
                                height:
                                MediaQuery.of(context).size.height / 1.7,
                                child: ListView.builder(
                                    shrinkWrap: true,
                                    itemCount: cashRecordList.length,
                                    itemBuilder: (context, index) {
                                      return ListTile(
                                        leading: cashRecordList[index].payment_type_id == '1' || cashRecordList[index].payment_type_id == ''
                                            ? Icon(Icons.payments_sharp)
                                            : cashRecordList[index].payment_type_id == '2'
                                            ? Icon(Icons.credit_card_rounded)
                                            : Icon(Icons.wifi),
                                        title: Text(
                                            '${cashRecordList[index].remark}'),
                                        subtitle: cashRecordList[index].type == 1 || cashRecordList[index].type == 0
                                            ? Text(
                                                'Cash in by: ${cashRecordList[index].userName}')
                                            : cashRecordList[index].type == 2
                                                ? Text(
                                                    'Cash-out by: ${cashRecordList[index].userName}')
                                                : Text(
                                                    'Close by: ${cashRecordList[index].userName}'),
                                        trailing: cashRecordList[index].type == 2
                                            ? Text(
                                                '-${cashRecordList[index].amount}',
                                                style: TextStyle(
                                                    color: Colors.red))
                                            : Text(
                                                '+${cashRecordList[index].amount}',
                                                style: TextStyle(
                                                    color: Colors.green)),
                                        onLongPress: () async {
                                          if(cashRecordList[index].type != 0 && cashRecordList[index].type != 3){
                                            if (await confirm(
                                              context,
                                              title: Text(
                                                  '${AppLocalizations.of(context)?.translate('remove_cash_record')}'),
                                              content: Text(
                                                  '${AppLocalizations.of(context)?.translate('would you like to remove?')}'),
                                              textOK: Text(
                                                  '${AppLocalizations.of(context)?.translate('yes')}'),
                                              textCancel: Text(
                                                  '${AppLocalizations.of(context)?.translate('no')}'),
                                            )) {
                                              return removeCashRecord(
                                                  cashRecordList[index]);
                                            }
                                          }
                                        },
                                      );
                                    }),
                              )
                            : Container(
                                alignment: Alignment.center,
                                height:
                                    MediaQuery.of(context).size.height / 1.7,
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.menu),
                                    Text('NO RECORD'),
                                  ],
                                ),
                              ),
                        Divider(
                          height: 10,
                          color: Colors.grey,
                        ),
                        Container(
                            margin: EdgeInsets.all(15),
                            padding: EdgeInsets.only(right: 10),
                            alignment: Alignment.bottomRight,
                            child: Text(
                              '${getTotalAmount()}',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 30),
                            )),
                        Divider(
                          height: 10,
                          color: Colors.grey,
                        ),
                      ],
                    ),
                  ),
                ),
              )
            : CustomProgressBar(),
      );
    });
  }

/*
  -------------------Dialog part---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
*/

  Future<Future<Object?>> openCashDialog(bool cashIn, bool cashOut) async {
    return showGeneralDialog(
        barrierColor: Colors.black.withOpacity(0.5),
        transitionBuilder: (context, a1, a2, widget) {
          final curvedValue = Curves.easeInOutBack.transform(a1.value) - 1.0;
          return Transform(
            transform: Matrix4.translationValues(0.0, curvedValue * 200, 0.0),
            child: Opacity(
              opacity: a1.value,
              child: CashDialog(
                isCashIn: cashIn,
                isCashOut: cashOut,
                callBack: () => readCashRecord(),
                isNewDay: false,
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

  Future<Future<Object?>> openSettlementDialog(List<CashRecord> cashRecord) async {
    return showGeneralDialog(
        barrierColor: Colors.black.withOpacity(0.5),
        transitionBuilder: (context, a1, a2, widget) {
          final curvedValue = Curves.easeInOutBack.transform(a1.value) - 1.0;
          return Transform(
            transform: Matrix4.translationValues(0.0, curvedValue * 200, 0.0),
            child: Opacity(
              opacity: a1.value,
              child: SettlementDialog(
                cashRecordList: cashRecord,
                callBack: () => readCashRecord(),
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

  Future<Future<Object?>> openSettlementHistoryDialog() async {
    return showGeneralDialog(
        barrierColor: Colors.black.withOpacity(0.5),
        transitionBuilder: (context, a1, a2, widget) {
          final curvedValue = Curves.easeInOutBack.transform(a1.value) - 1.0;
          return Transform(
            transform: Matrix4.translationValues(0.0, curvedValue * 200, 0.0),
            child: Opacity(
              opacity: a1.value,
              child: HistoryDialog(),
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

  Future<Future<Object?>> openCashBoxDialog() async {
    return showGeneralDialog(
        barrierColor: Colors.black.withOpacity(0.5),
        transitionBuilder: (context, a1, a2, widget) {
          final curvedValue = Curves.easeInOutBack.transform(a1.value) - 1.0;
          return Transform(
            transform: Matrix4.translationValues(0.0, curvedValue * 200, 0.0),
            child: Opacity(
              opacity: a1.value,
              child: CashBoxDialog(),
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

/*
  ----------------DB Query part------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
*/

  readPaymentLinkCompany() async {
    paymentNameList.add('All/Cash Drawer');
    final prefs = await SharedPreferences.getInstance();
    final String? user = prefs.getString('user');
    Map userObject = json.decode(user!);
    List<PaymentLinkCompany> data = await PosDatabase.instance
        .readAllPaymentLinkCompany(userObject['company_id']);
    for (int i = 0; i < data.length; i++) {
      if (!paymentNameList.contains(data)) {
        paymentNameList.add(data[i].name!);
      }
    }
  }

  readCashRecord() async {
    isLoad = false;
    cashRecordList = [];
    final prefs = await SharedPreferences.getInstance();
    final int? branch_id = prefs.getInt('branch_id');
    List<CashRecord> data = await PosDatabase.instance.readBranchCashRecord(branch_id.toString());
    if (selectedPayment == 'All/Cash Drawer') {
      if (!cashRecordList.contains(data)) {
        cashRecordList = List.from(data);
      }
    } else if (selectedPayment == 'Cash') {
      for (int i = 0; i < data.length; i++) {
        if (data[i].payment_type_id == '0') {
          cashRecordList.add(data[i]);
        }
      }
    } else if (selectedPayment == 'Card') {
      for (int i = 0; i < data.length; i++) {
        if (data[i].payment_type_id == '1') {
          cashRecordList.add(data[i]);
        }
      }
    } else if (selectedPayment == 'Grab') {
      for (int i = 0; i < data.length; i++) {
        if (data[i].payment_type_id == '0') {
          cashRecordList.add(data[i]);
        }
      }
    } else if (selectedPayment == 'ipay tng scanner') {
      for (int i = 0; i < data.length; i++) {
        if (data[i].payment_type_id == '2') {
          cashRecordList.add(data[i]);
        }
      }
    }

    setState(() {
      isLoad = true;
    });
  }

  removeCashRecord(CashRecord cashRecord) async {
    try {
      DateFormat dateFormat = DateFormat("yyyy-MM-dd HH:mm:ss");
      String dateTime = dateFormat.format(DateTime.now());
      CashRecord cashRecordObject = CashRecord(
          sync_status: 0,
          soft_delete: dateTime,
          cash_record_sqlite_id: cashRecord.cash_record_sqlite_id);
      int data = await PosDatabase.instance.deleteCashRecord(cashRecordObject);
      await readCashRecord();
    } catch (e) {
      Fluttertoast.showToast(
          backgroundColor: Color(0xFFFF0000),
          msg: "Delete cash record error: ${e}");
    }
  }

/*
  ----------------Other function part------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
*/

  toPosPinPage(){
    String cashDrawer = calcCashDrawer();
    print('to pos pin call him');
    Navigator.push(context,
      PageTransition(type: PageTransitionType.fade, child: PosPinPage(cashBalance: cashDrawer),
      ),
    );
  }

  getTotalAmount() {
    String total = '';
    switch(selectedPayment) {
      case 'All/Cash Drawer': {
        print('get total amount call calc cash drawer');
        total = 'Cash drawer: ' + calcCashDrawer();
      }
      break;
      case 'Cash': {
        total = 'Cash: ' + calcTotalAmount('0');
      }
      break;
      case 'Card': {
        total = 'Card: ' + calcTotalAmount('1');
      }
      break;
      case 'Grab': {
        total = 'GrabPay: ' + calcTotalAmount('0');
      }
      break;
      case 'ipay tng scanner': {
        total = 'ipay tng scanner: ' + calcTotalAmount('2');
      }
      break;
      default: {
        total = 'N/A';
      }
      break;
    }
    return total;
  }

  calcTotalAmount(String type_id){
    try{
      double total = 0.0;
      for (int i = 0; i < cashRecordList.length; i++) {
        if(cashRecordList[i].payment_type_id == type_id){
          total += double.parse(cashRecordList[i].amount!);
        }
      }
      return total.toStringAsFixed(2);
    }catch(e){
      Fluttertoast.showToast(
          backgroundColor: Color(0xFFFF0000),
          msg: "calculate cash error: ${e}");
      return 0.0;
    }
  }

  calcCashDrawer() {
    try {
      double totalCashIn = 0.0;
      double totalCashOut = 0.0;
      double totalCashDrawer = 0.0;
      for (int i = 0; i < cashRecordList.length; i++) {
        if (cashRecordList[i].type == 0 || cashRecordList[i].type == 1 || cashRecordList[i].payment_type_id == '1') {
          totalCashIn += double.parse(cashRecordList[i].amount!);
        } else if (cashRecordList[i].type == 2 && cashRecordList[i].payment_type_id == '') {
          totalCashOut += double.parse(cashRecordList[i].amount!);
        }
      }

      totalCashDrawer = totalCashIn - totalCashOut;

      return totalCashDrawer.toStringAsFixed(2);
    } catch (e) {
      Fluttertoast.showToast(
          backgroundColor: Color(0xFFFF0000),
          msg: "calculate cash drawer error: ${e}");
      return 0.0;
    }
  }


}
