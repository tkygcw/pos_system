import 'dart:convert';

import 'package:confirm_dialog/confirm_dialog.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';
import 'package:pos_system/database/pos_database.dart';
import 'package:pos_system/fragment/settlement/cash_box_dialog.dart';
import 'package:pos_system/fragment/settlement/cash_dialog.dart';
import 'package:pos_system/fragment/settlement/history_dialog.dart';
import 'package:pos_system/fragment/settlement/pos_pin_dialog.dart';
import 'package:pos_system/fragment/settlement/settlement_dialog.dart';
import 'package:pos_system/object/order_cache.dart';
import 'package:pos_system/object/payment_link_company.dart';
import 'package:pos_system/page/pos_pin.dart';
import 'package:pos_system/page/progress_bar.dart';
import 'package:pos_system/utils/Utils.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../database/domain.dart';
import '../../notifier/connectivity_change_notifier.dart';
import '../../notifier/theme_color.dart';
import '../../object/cash_record.dart';
import '../../translation/AppLocalizations.dart';

class SettlementPage extends StatefulWidget {
  const SettlementPage({Key? key}) : super(key: key);

  @override
  State<SettlementPage> createState() => _SettlementPageState();
}

class _SettlementPageState extends State<SettlementPage> {
  List<OrderCache> unpaidOrderCacheList = [];
  List<CashRecord> cashRecordList = [];
  List<String> paymentNameList = [];
  String selectedPayment = 'All/Cash Drawer';
  bool isLoad = false;

  @override
  void initState() {
    super.initState();
    checkUnpaidOrderCache();
    readPaymentLinkCompany();
    readCashRecord();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeColor>(builder: (context, ThemeColor color, child) {
      return LayoutBuilder(builder: (context, constraints) {
        if (constraints.maxWidth > 800) {
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
                                      "Counter",
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
                                                      style: TextStyle(fontSize: 18),
                                                    ),
                                                  ),
                                                ))
                                            .toList(),
                                        // Customize the selected item
                                        selectedItemBuilder: (BuildContext context) => paymentNameList
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
                                      child: Text('Cash-In'),
                                      onPressed: () {
                                        openCashDialog(true, false);
                                      },
                                      style: ElevatedButton.styleFrom(backgroundColor: color.backgroundColor)),
                                  Container(
                                    height: 30,
                                    child: VerticalDivider(color: Colors.grey, thickness: 1),
                                  ),
                                  ElevatedButton(
                                    child: Text('Cash-Out'),
                                    onPressed: () {
                                      openCashOutDialog();
                                    },
                                    style: ElevatedButton.styleFrom(backgroundColor: color.buttonColor),
                                  ),
                                  Container(
                                    height: 30,
                                    child: VerticalDivider(color: Colors.grey, thickness: 1),
                                  ),
                                  ElevatedButton(
                                    child: Text('Settlement'),
                                    onPressed: () {
                                      if (cashRecordList.length > 1 && unpaidOrderCacheList.isEmpty) {
                                        openSettlementDialog(cashRecordList);
                                      } else if (cashRecordList.isEmpty) {
                                        Fluttertoast.showToast(backgroundColor: Color(0xFFFF0000), msg: "No record");
                                      } else if (unpaidOrderCacheList.isNotEmpty) {
                                        Fluttertoast.showToast(backgroundColor: Color(0xFFFF0000), msg: "Still have order not yet paid");
                                      } else if (cashRecordList.length == 1) {
                                        Fluttertoast.showToast(backgroundColor: Color(0xFFFF0000), msg: "Cannot do settlement with opening balance");
                                      }
                                    },
                                    style: ElevatedButton.styleFrom(backgroundColor: color.backgroundColor),
                                  ),
                                  Container(
                                    height: 30,
                                    child: VerticalDivider(color: Colors.grey, thickness: 1),
                                  ),
                                  ElevatedButton(
                                    child: Text('Cash Record History'),
                                    onPressed: () {
                                      openSettlementHistoryDialog();
                                    },
                                    style: ElevatedButton.styleFrom(backgroundColor: color.buttonColor),
                                  ),
                                  Container(
                                    height: 30,
                                    child: VerticalDivider(color: Colors.grey, thickness: 1),
                                  ),
                                  ElevatedButton(
                                    child: Text('Transfer Ownership'),
                                    onPressed: () async {
                                      if (await confirm(
                                        context,
                                        title: Text('${AppLocalizations.of(context)?.translate('confirm_pos_pin')}'),
                                        content: Text('${AppLocalizations.of(context)?.translate('to_pos_pin')}'),
                                        textOK: Text('${AppLocalizations.of(context)?.translate('yes')}'),
                                        textCancel: Text('${AppLocalizations.of(context)?.translate('no')}'),
                                      )) {
                                        return openPosPinDialog();
                                      }
                                    },
                                    style: ElevatedButton.styleFrom(backgroundColor: color.backgroundColor),
                                  ),
                                  Container(
                                    height: 30,
                                    child: VerticalDivider(color: Colors.grey, thickness: 1),
                                  ),
                                  ElevatedButton(
                                    child: Text('Open cash drawer'),
                                    onPressed: () {
                                      openCashBoxDialog();
                                    },
                                    style: ElevatedButton.styleFrom(backgroundColor: color.buttonColor),
                                  ),
                                  Container(
                                    height: 30,
                                    child: VerticalDivider(color: Colors.grey, thickness: 1),
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
                                    height: MediaQuery.of(context).size.height / 1.7,
                                    child: Consumer<ConnectivityChangeNotifier>(builder: (context, ConnectivityChangeNotifier connectivity, child) {
                                      return ListView.builder(
                                          shrinkWrap: true,
                                          itemCount: cashRecordList.length,
                                          itemBuilder: (context, index) {
                                            return ListTile(
                                              contentPadding: EdgeInsets.all(10),
                                              leading: cashRecordList[index].payment_type_id == '1' || cashRecordList[index].payment_type_id == ''
                                                  ? CircleAvatar(
                                                      backgroundColor: Colors.grey.shade200,
                                                      child: Icon(
                                                        Icons.payments,
                                                        color: Colors.grey,
                                                      ))
                                                  : cashRecordList[index].payment_type_id == '2'
                                                      ? CircleAvatar(
                                                          backgroundColor: Colors.grey.shade200,
                                                          child: Icon(
                                                            Icons.qr_code_rounded,
                                                            color: Colors.grey,
                                                          ))
                                                      : CircleAvatar(
                                                          backgroundColor: Colors.grey.shade200,
                                                          child: Icon(
                                                            Icons.wifi,
                                                            color: Colors.grey,
                                                          )),
                                              title: Text(
                                                '${cashRecordList[index].remark}',
                                                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey),
                                              ),
                                              subtitle: cashRecordList[index].type == 1 || cashRecordList[index].type == 0
                                                  ? RichText(
                                                      text: TextSpan(
                                                        style: TextStyle(color: Colors.black, fontSize: 16),
                                                        children: <TextSpan>[
                                                          TextSpan(
                                                              text: '${Utils.formatDate(cashRecordList[index].created_at)}',
                                                              style: TextStyle(color: Colors.black87, fontSize: 14)),
                                                          TextSpan(text: '\n'),
                                                          TextSpan(
                                                            text: 'Cash In by: ${cashRecordList[index].userName}',
                                                            style: TextStyle(color: Colors.grey, fontSize: 12),
                                                          ),
                                                        ],
                                                      ),
                                                    )
                                                  : cashRecordList[index].type == 3
                                                      ? RichText(
                                                          text: TextSpan(
                                                            style: TextStyle(color: Colors.black, fontSize: 16),
                                                            children: <TextSpan>[
                                                              TextSpan(
                                                                  text: '${Utils.formatDate(cashRecordList[index].created_at)}',
                                                                  style: TextStyle(color: Colors.black87, fontSize: 14)),
                                                              TextSpan(text: '\n'),
                                                              TextSpan(
                                                                text: 'Close by: ${cashRecordList[index].userName}',
                                                                style: TextStyle(color: Colors.grey, fontSize: 12),
                                                              ),
                                                            ],
                                                          ),
                                                        )
                                                      : RichText(
                                                          text: TextSpan(
                                                            style: TextStyle(color: Colors.black, fontSize: 16),
                                                            children: <TextSpan>[
                                                              TextSpan(
                                                                  text: '${Utils.formatDate(cashRecordList[index].created_at)}',
                                                                  style: TextStyle(color: Colors.black87, fontSize: 14)),
                                                              TextSpan(text: '\n'),
                                                              TextSpan(
                                                                text: 'Cash-Out: ${cashRecordList[index].userName}',
                                                                style: TextStyle(color: Colors.grey, fontSize: 12),
                                                              ),
                                                            ],
                                                          ),
                                                        ),
                                              trailing: cashRecordList[index].type == 2 || cashRecordList[index].type == 4
                                                  ? Text('-${Utils.convertTo2Dec(cashRecordList[index].amount!)}',
                                                      style: TextStyle(fontSize: 16, color: Colors.red))
                                                  : Text('+${Utils.convertTo2Dec(cashRecordList[index].amount!)}',
                                                      style: TextStyle(fontSize: 16, color: Colors.green)),
                                              onLongPress: () async {
                                                if (cashRecordList[index].type != 0 && cashRecordList[index].type != 3) {
                                                  if (await confirm(
                                                    context,
                                                    title: Text('${AppLocalizations.of(context)?.translate('remove_cash_record')}'),
                                                    content: Text('${AppLocalizations.of(context)?.translate('would you like to remove?')}'),
                                                    textOK: Text('${AppLocalizations.of(context)?.translate('yes')}'),
                                                    textCancel: Text('${AppLocalizations.of(context)?.translate('no')}'),
                                                  )) {
                                                    return removeCashRecord(cashRecordList[index], connectivity);
                                                  }
                                                }
                                              },
                                            );
                                          });
                                    }))
                                : Container(
                                    alignment: Alignment.center,
                                    height: MediaQuery.of(context).size.height / 1.7,
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
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 30),
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
        } else {
          ///mobile view
          return Scaffold(
            resizeToAvoidBottomInset: false,
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
                                      "Counter",
                                      style: TextStyle(fontSize: 25),
                                    ),
                                    Spacer(),
                                    Container(
                                      margin: EdgeInsets.only(right: 10),
                                      width: MediaQuery.of(context).size.width / 4,
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
                                                      style: TextStyle(fontSize: 18),
                                                    ),
                                                  ),
                                                ))
                                            .toList(),
                                        // Customize the selected item
                                        selectedItemBuilder: (BuildContext context) => paymentNameList
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
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Container(
                                child: Row(
                                  children: [
                                    ElevatedButton(
                                        child: Text('Cash-in'),
                                        onPressed: () {
                                          openCashDialog(true, false);
                                        },
                                        style: ElevatedButton.styleFrom(backgroundColor: color.backgroundColor)),
                                    Container(
                                      height: 30,
                                      child: VerticalDivider(color: Colors.grey, thickness: 1),
                                    ),
                                    ElevatedButton(
                                      child: Text('Cash-out'),
                                      onPressed: () {
                                        if (cashRecordList.length > 0) {
                                          openCashOutDialog();
                                          // openCashDialog(false, true);
                                        } else {
                                          Fluttertoast.showToast(backgroundColor: Color(0xFFFF0000), msg: "No record");
                                        }
                                      },
                                      style: ElevatedButton.styleFrom(backgroundColor: color.buttonColor),
                                    ),
                                    Container(
                                      height: 30,
                                      child: VerticalDivider(color: Colors.grey, thickness: 1),
                                    ),
                                    ElevatedButton(
                                      child: Text('Settlement'),
                                      onPressed: () {
                                        if (cashRecordList.length > 1 && unpaidOrderCacheList.isEmpty) {
                                          openSettlementDialog(cashRecordList);
                                        } else if (cashRecordList.isEmpty) {
                                          Fluttertoast.showToast(backgroundColor: Color(0xFFFF0000), msg: "No record");
                                        } else if (unpaidOrderCacheList.isNotEmpty) {
                                          Fluttertoast.showToast(backgroundColor: Color(0xFFFF0000), msg: "Still have order not yet paid");
                                        } else if (cashRecordList.length == 1) {
                                          Fluttertoast.showToast(
                                              backgroundColor: Color(0xFFFF0000), msg: "Cannot do settlement with opening balance");
                                        }
                                      },
                                      style: ElevatedButton.styleFrom(backgroundColor: color.backgroundColor),
                                    ),
                                    Container(
                                      height: 30,
                                      child: VerticalDivider(color: Colors.grey, thickness: 1),
                                    ),
                                    ElevatedButton(
                                      child: Text('Settlement History'),
                                      onPressed: () {
                                        openSettlementHistoryDialog();
                                      },
                                      style: ElevatedButton.styleFrom(backgroundColor: color.buttonColor),
                                    ),
                                    Container(
                                      height: 30,
                                      child: VerticalDivider(color: Colors.grey, thickness: 1),
                                    ),
                                    ElevatedButton(
                                      child: Text('Transfer Ownership'),
                                      onPressed: () async {
                                        openPosPinDialog();
                                      },
                                      style: ElevatedButton.styleFrom(backgroundColor: color.backgroundColor),
                                    ),
                                    Container(
                                      height: 30,
                                      child: VerticalDivider(color: Colors.grey, thickness: 1),
                                    ),
                                    ElevatedButton(
                                      child: Text('Open Cash Drawer'),
                                      onPressed: () {
                                        openCashBoxDialog();
                                      },
                                      style: ElevatedButton.styleFrom(backgroundColor: color.buttonColor),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            Divider(
                              height: 10,
                              color: Colors.grey,
                            ),
                            cashRecordList.length > 0
                                ? Container(
                                    margin: EdgeInsets.fromLTRB(25, 0, 25, 0),
                                    height: MediaQuery.of(context).size.height / 1.7,
                                    child: Scrollbar(child:
                                        Consumer<ConnectivityChangeNotifier>(builder: (context, ConnectivityChangeNotifier connectivity, child) {
                                      return ListView.builder(
                                          shrinkWrap: true,
                                          primary: false,
                                          itemCount: cashRecordList.length,
                                          itemBuilder: (context, index) {
                                            return ListTile(
                                              isThreeLine: true,
                                              leading: cashRecordList[index].payment_type_id == '1' || cashRecordList[index].payment_type_id == ''
                                                  ? CircleAvatar(
                                                      backgroundColor: Colors.grey.shade200, child: Icon(Icons.payments, color: Colors.grey))
                                                  : cashRecordList[index].payment_type_id == '2'
                                                      ? CircleAvatar(
                                                          backgroundColor: Colors.grey.shade200,
                                                          child: Icon(Icons.qr_code_rounded, color: Colors.grey))
                                                      : CircleAvatar(
                                                          backgroundColor: Colors.grey.shade200, child: Icon(Icons.wifi, color: Colors.grey)),
                                              title: Text(
                                                '${cashRecordList[index].remark}',
                                                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey),
                                              ),
                                              subtitle: cashRecordList[index].type == 1 || cashRecordList[index].type == 0
                                                  ? RichText(
                                                      text: TextSpan(
                                                        style: TextStyle(color: Colors.black, fontSize: 16),
                                                        children: <TextSpan>[
                                                          TextSpan(
                                                              text: '${Utils.formatDate(cashRecordList[index].created_at)}',
                                                              style: TextStyle(color: Colors.black87, fontSize: 14)),
                                                          TextSpan(text: '\n'),
                                                          TextSpan(
                                                            text: 'Cash in by: ${cashRecordList[index].userName}',
                                                            style: TextStyle(color: Colors.grey, fontSize: 12),
                                                          ),
                                                        ],
                                                      ),
                                                    )
                                                  : cashRecordList[index].type == 2
                                                      ? RichText(
                                                          text: TextSpan(
                                                            style: TextStyle(color: Colors.black, fontSize: 16),
                                                            children: <TextSpan>[
                                                              TextSpan(
                                                                  text: '${Utils.formatDate(cashRecordList[index].created_at)}',
                                                                  style: TextStyle(color: Colors.black87, fontSize: 14)),
                                                              TextSpan(text: '\n'),
                                                              TextSpan(
                                                                text: 'Cash-out by: ${cashRecordList[index].userName}',
                                                                style: TextStyle(color: Colors.grey, fontSize: 12),
                                                              ),
                                                            ],
                                                          ),
                                                        )
                                                      : cashRecordList[index].type == 3
                                                          ? RichText(
                                                              text: TextSpan(
                                                                style: TextStyle(color: Colors.black, fontSize: 16),
                                                                children: <TextSpan>[
                                                                  TextSpan(
                                                                      text: '${Utils.formatDate(cashRecordList[index].created_at)}',
                                                                      style: TextStyle(color: Colors.black87, fontSize: 14)),
                                                                  TextSpan(text: '\n'),
                                                                  TextSpan(
                                                                    text: 'Close by: ${cashRecordList[index].userName}',
                                                                    style: TextStyle(color: Colors.grey, fontSize: 12),
                                                                  ),
                                                                ],
                                                              ),
                                                            )
                                                          : RichText(
                                                              text: TextSpan(
                                                                style: TextStyle(color: Colors.black, fontSize: 16),
                                                                children: <TextSpan>[
                                                                  TextSpan(
                                                                      text: '${Utils.formatDate(cashRecordList[index].created_at)}',
                                                                      style: TextStyle(color: Colors.black87, fontSize: 14)),
                                                                  TextSpan(text: '\n'),
                                                                  TextSpan(
                                                                    text: 'Refund by: ${cashRecordList[index].userName}',
                                                                    style: TextStyle(color: Colors.grey, fontSize: 12),
                                                                  ),
                                                                ],
                                                              ),
                                                            ),
                                              trailing: cashRecordList[index].type == 2 || cashRecordList[index].type == 4
                                                  ? Text('-${Utils.convertTo2Dec(cashRecordList[index].amount!)}',
                                                      style: TextStyle(fontSize: 16, color: Colors.red))
                                                  : Text('+${Utils.convertTo2Dec(cashRecordList[index].amount!)}',
                                                      style: TextStyle(fontSize: 16, color: Colors.green)),
                                              onLongPress: () async {
                                                if (cashRecordList[index].type != 0 && cashRecordList[index].type != 3) {
                                                  if (await confirm(
                                                    context,
                                                    title: Text('${AppLocalizations.of(context)?.translate('remove_cash_record')}'),
                                                    content: Text('${AppLocalizations.of(context)?.translate('would you like to remove?')}'),
                                                    textOK: Text('${AppLocalizations.of(context)?.translate('yes')}'),
                                                    textCancel: Text('${AppLocalizations.of(context)?.translate('no')}'),
                                                  )) {
                                                    return removeCashRecord(cashRecordList[index], connectivity);
                                                  }
                                                }
                                              },
                                            );
                                          });
                                    })),
                                  )
                                : Container(
                                    alignment: Alignment.center,
                                    height: MediaQuery.of(context).size.height / 1.7,
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.menu),
                                        Text('NO RECORD'),
                                      ],
                                    ),
                                  ),
                          ],
                        ),
                      ),
                    ),
                  )
                : CustomProgressBar(),
            bottomNavigationBar: Container(
              height: MediaQuery.of(context).size.height / 4,
              child: Column(
                children: [
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
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 30),
                      )),
                  Divider(
                    height: 10,
                    color: Colors.grey,
                  ),
                ],
              ),
            ),
          );
        }
      });
    });
  }

/*
  -------------------Dialog part---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
*/
  openPosPinDialog() async {
    return showGeneralDialog(
        barrierColor: Colors.black.withOpacity(0.5),
        transitionBuilder: (context, a1, a2, widget) {
          final curvedValue = Curves.easeInOutBack.transform(a1.value) - 1.0;
          return Transform(
            transform: Matrix4.translationValues(0.0, curvedValue * 200, 0.0),
            child: Opacity(
              opacity: a1.value,
              child: PosPinDialog(
                callBack: () => toPosPinPage(),
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

  Future<Future<Object?>> openCashOutDialog() async {
    return showGeneralDialog(
        barrierColor: Colors.black.withOpacity(0.5),
        transitionBuilder: (context, a1, a2, widget) {
          final curvedValue = Curves.easeInOutBack.transform(a1.value) - 1.0;
          return Transform(
            transform: Matrix4.translationValues(0.0, curvedValue * 200, 0.0),
            child: Opacity(
                opacity: a1.value,
                child: PosPinDialog(
                  callBack: () => openCashDialog(false, true),
                )),
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
    List<PaymentLinkCompany> data = await PosDatabase.instance.readAllPaymentLinkCompany(userObject['company_id']);
    for (int i = 0; i < data.length; i++) {
      if (!paymentNameList.contains(data)) {
        paymentNameList.add(data[i].name!);
      }
    }
  }

  checkUnpaidOrderCache() async {
    List<OrderCache> data = await PosDatabase.instance.readAllUnpaidOrderCache();
    unpaidOrderCacheList = data;
    print('unpaid Order Cache List: ${unpaidOrderCacheList.length}');
  }

  readCashRecord() async {
    isLoad = false;
    cashRecordList = [];
    List<CashRecord> data = await PosDatabase.instance.readBranchCashRecord();
    if (selectedPayment == 'All/Cash Drawer') {
      cashRecordList = data;
    } else if (selectedPayment == 'Cash') {
      for (int i = 0; i < data.length; i++) {
        if (data[i].payment_type_id == '1') {
          cashRecordList.add(data[i]);
        }
      }
    } else if (selectedPayment == 'Card') {
      for (int i = 0; i < data.length; i++) {
        if (data[i].payment_type_id == '2') {
          cashRecordList.add(data[i]);
        }
      }
    } else if (selectedPayment == 'Grab') {
      for (int i = 0; i < data.length; i++) {
        if (data[i].payment_type_id == '5') {
          cashRecordList.add(data[i]);
        }
      }
    } else if (selectedPayment == 'ipay tng scanner') {
      for (int i = 0; i < data.length; i++) {
        if (data[i].payment_type_id == '6') {
          cashRecordList.add(data[i]);
        }
      }
    }

    setState(() {
      isLoad = true;
    });
  }

  removeCashRecord(CashRecord cashRecord, ConnectivityChangeNotifier connectivity) async {
    try {
      DateFormat dateFormat = DateFormat("yyyy-MM-dd HH:mm:ss");
      String dateTime = dateFormat.format(DateTime.now());
      List<String> _value = [];
      print('delete cash record id: ${cashRecord.cash_record_sqlite_id}');
      print('delete cash record sync status: ${cashRecord.sync_status}');
      CashRecord cashRecordObject = CashRecord(
          sync_status: cashRecord.sync_status == 0 ? 0 : 2, soft_delete: dateTime, cash_record_sqlite_id: cashRecord.cash_record_sqlite_id);
      int data = await PosDatabase.instance.deleteCashRecord(cashRecordObject);
      //sync to cloud
      if (data == 1) {
        CashRecord _record = await PosDatabase.instance.readSpecificCashRecord(cashRecord.cash_record_sqlite_id!);
        _value.add(jsonEncode(_record));
      }
      await readCashRecord();
      //sync to cloud
      syncUpdatedCashRecordToCloud(_value.toString());
    } catch (e) {
      print('delete cash record error: ${e}');
      Fluttertoast.showToast(backgroundColor: Color(0xFFFF0000), msg: "Delete cash record error: ${e}");
    }
  }

  syncUpdatedCashRecordToCloud(String value) async {
    bool _hasInternetAccess = await Domain().isHostReachable();
    if (_hasInternetAccess) {
      Map response = await Domain().SyncCashRecordToCloud(value);
      if (response['status'] == '1') {
        List responseJson = response['data'];
        int cashRecordData = await PosDatabase.instance.updateCashRecordSyncStatusFromCloud(responseJson[0]['cash_record_key']);
      }
    }
  }

/*
  ----------------Other function part------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
*/

  toPosPinPage() {
    String cashDrawer = calcCashDrawer();
    print('to pos pin call him');
    // Navigator.push(context,
    //   PageTransition(type: PageTransitionType.fade, child: PosPinPage(cashBalance: cashDrawer),
    //   ),
    // );
    Navigator.of(context).pushAndRemoveUntil(
      // the new route
      MaterialPageRoute(
        builder: (BuildContext context) => PosPinPage(cashBalance: cashDrawer),
      ),

      // this function should return true when we're done removing routes
      // but because we want to remove all other screens, we make it
      // always return false
      (Route route) => false,
    );
  }

  getTotalAmount() {
    String total = '';
    switch (selectedPayment) {
      case 'All/Cash Drawer':
        {
          total = 'Cash drawer(inc: cash bill): ' + calcCashDrawer().toString();
        }
        break;
      case 'Cash':
        {
          total = 'Cash: ' + calcTotalAmount('1');
        }
        break;
      case 'Card':
        {
          total = 'Card: ' + calcTotalAmount('2');
        }
        break;
      case 'Grab':
        {
          total = 'GrabPay: ' + calcTotalAmount('5');
        }
        break;
      case 'ipay tng scanner':
        {
          total = 'ipay tng scanner: ' + calcTotalAmount('6');
        }
        break;
      default:
        {
          total = 'N/A';
        }
        break;
    }
    return total;
  }

  calcTotalAmount(String type_id) {
    try {
      double total = 0.0;
      double _totalRefund = 0.0;
      double subtotal = 0.0;
      for (int i = 0; i < cashRecordList.length; i++) {
        if (cashRecordList[i].payment_type_id == type_id && cashRecordList[i].type == 3) {
          total += double.parse(cashRecordList[i].amount!);
        } else if (cashRecordList[i].payment_type_id == type_id && cashRecordList[i].type == 4) {
          _totalRefund += double.parse(cashRecordList[i].amount!);
        }
      }
      subtotal = total - _totalRefund;
      return subtotal.toStringAsFixed(2);
    } catch (e) {
      Fluttertoast.showToast(backgroundColor: Color(0xFFFF0000), msg: "calculate cash error: ${e}");
      return 0.0;
    }
  }

  calcCashDrawer() {
    try {
      double totalCashIn = 0.0;
      double totalCashOut = 0.0;
      double totalCashDrawer = 0.0;
      double totalCashRefund = 0.0;
      for (int i = 0; i < cashRecordList.length; i++) {
        if (cashRecordList[i].type == 0) {
          totalCashIn += double.parse(cashRecordList[i].amount!);
        } else if (cashRecordList[i].type == 1) {
          totalCashIn += double.parse(cashRecordList[i].amount!);
        } else if (cashRecordList[i].type == 3 && cashRecordList[i].payment_type_id == '1') {
          totalCashIn += double.parse(cashRecordList[i].amount!);
        } else if (cashRecordList[i].type == 2 && cashRecordList[i].payment_type_id == '') {
          totalCashOut += double.parse(cashRecordList[i].amount!);
        } else if (cashRecordList[i].type == 4 && cashRecordList[i].payment_type_id == '1') {
          totalCashRefund += double.parse(cashRecordList[i].amount!);
        }
      }
      totalCashDrawer = totalCashIn - (totalCashOut + totalCashRefund);
      return totalCashDrawer.toStringAsFixed(2);
    } catch (e) {
      Fluttertoast.showToast(backgroundColor: Color(0xFFFF0000), msg: "calculate cash drawer error: ${e}");
      return 0.0;
    }
  }
}
