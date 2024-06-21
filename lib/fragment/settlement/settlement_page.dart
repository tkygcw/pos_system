import 'dart:async';
import 'dart:convert';

import 'package:confirm_dialog/confirm_dialog.dart';
import 'package:f_logs/model/flog/flog.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';
import 'package:pos_system/database/pos_database.dart';
import 'package:pos_system/fragment/settlement/cash_box_dialog.dart';
import 'package:pos_system/fragment/settlement/cash_dialog.dart';
import 'package:pos_system/fragment/settlement/history_dialog.dart';
import 'package:pos_system/fragment/settlement/pos_pin_dialog.dart';
import 'package:pos_system/fragment/settlement/reprint_settlement_dialog.dart';
import 'package:pos_system/fragment/settlement/settlement_dialog.dart';
import 'package:pos_system/object/order_cache.dart';
import 'package:pos_system/object/payment_link_company.dart';
import 'package:pos_system/object/printer.dart';
import 'package:pos_system/object/settlement.dart';
import 'package:pos_system/object/user.dart';
import 'package:pos_system/page/pos_pin.dart';
import 'package:pos_system/page/progress_bar.dart';
import 'package:pos_system/utils/Utils.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../database/domain.dart';
import '../../main.dart';
import '../../notifier/connectivity_change_notifier.dart';
import '../../notifier/theme_color.dart';
import '../../object/cash_record.dart';
import '../../object/print_receipt.dart';
import '../../translation/AppLocalizations.dart';
import '../logout_dialog.dart';

class SettlementPage extends StatefulWidget {
  const SettlementPage({Key? key}) : super(key: key);

  @override
  State<SettlementPage> createState() => _SettlementPageState();
}

class _SettlementPageState extends State<SettlementPage> {
  PrintReceipt printReceipt = PrintReceipt();
  List<Printer> printerList = [];
  List<OrderCache> unpaidOrderCacheList = [];
  List<CashRecord> initCashRecordList = [];
  List<CashRecord> cashRecordList = [];
  List<String> paymentNameList = [];
  String selectedPayment = 'All/Cash Drawer';
  PaymentLinkCompany? paymentMethod;
  List<PaymentLinkCompany> companyPaymentList = [];
  bool isLoad = false, isLogOut = false;

  @override
  void initState() {
    super.initState();
    //checkUnpaidOrderCache();
    readAllPrinters();
    readCashRecord();
  }

  readAllPrinters() async {
    printerList = await printReceipt.readAllPrinters();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeColor>(builder: (context, ThemeColor color, child) {
      return LayoutBuilder(builder: (context, constraints) {
        if (constraints.maxWidth > 900 && constraints.maxHeight > 500) {
          return isLoad ?
          Scaffold(
            appBar: AppBar(
              automaticallyImplyLeading: false,
              elevation: 0,
              title: Text(
                AppLocalizations.of(context)!.translate('counter'),
                style: TextStyle(fontSize: 25),
              ),
              actions: [
                Container(
                  margin: EdgeInsets.only(right: 10),
                  width: MediaQuery.of(context).size.height / 3,
                  child: DropdownButton<PaymentLinkCompany>(
                    onChanged: (value) {
                      setState(() {
                        paymentMethod = value!;
                        readSpecificPaymentCashRecord(paymentMethod!.payment_type_id!);
                      });
                    },
                    menuMaxHeight: 300,
                    value: paymentMethod,
                    // Hide the default underline
                    underline: Container(),
                    icon: Icon(
                      Icons.arrow_drop_down,
                      color: color.backgroundColor,
                    ),
                    isExpanded: true,
                    // The list of options
                    items: companyPaymentList.map((e) => DropdownMenuItem<PaymentLinkCompany>(
                      value: e,
                      child: Container(
                        alignment: Alignment.centerLeft,
                        child: Text(e.name!,style: TextStyle(fontSize: 18)),
                      ),
                    ))
                        .toList(),
                    // Customize the selected item
                    selectedItemBuilder: (BuildContext context) => companyPaymentList.map((e) => Center(
                      child: Text(e.name!),
                    )).toList(),
                  ),
                ),
              ],
            ),
            body: Padding(
              padding: EdgeInsets.fromLTRB(10, 0, 10, 0),
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    Divider(
                      height: 10,
                      color: Colors.grey,
                    ),
                    Container(
                      alignment: Alignment.topLeft,
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            ElevatedButton(
                                child: Text(AppLocalizations.of(context)!.translate('cash_in')),
                                onPressed: () async {
                                  final prefs = await SharedPreferences.getInstance();
                                  final String? pos_user = prefs.getString('pos_pin_user');
                                  Map<String, dynamic> userMap = json.decode(pos_user!);
                                  User userData = User.fromJson(userMap);

                                  if (userData.cash_drawer_permission != 1) {
                                    openCashInDialog();
                                  } else {
                                    await openCashDialog(true, false);
                                  }
                                },
                                style: ElevatedButton.styleFrom(backgroundColor: color.backgroundColor)),
                            Container(
                              height: 30,
                              child: VerticalDivider(color: Colors.grey, thickness: 1),
                            ),
                            ElevatedButton(
                              child: Text(AppLocalizations.of(context)!.translate('cash_out')),
                              onPressed: () async {
                                final prefs = await SharedPreferences.getInstance();
                                final String? pos_user = prefs.getString('pos_pin_user');
                                Map<String, dynamic> userMap = json.decode(pos_user!);
                                User userData = User.fromJson(userMap);

                                if (userData.cash_drawer_permission != 1) {
                                  openCashOutDialog();
                                } else {
                                  await openCashDialog(false, true);
                                }
                              },
                              style: ElevatedButton.styleFrom(backgroundColor: color.buttonColor),
                            ),
                            Container(
                              height: 30,
                              child: VerticalDivider(color: Colors.grey, thickness: 1),
                            ),
                            ElevatedButton(
                              child: Text(AppLocalizations.of(context)!.translate('settlement')),
                              onPressed: () {
                                if (cashRecordList.isNotEmpty) {
                                  openSettlementDialog(cashRecordList);
                                } else {
                                  Fluttertoast.showToast(backgroundColor: Color(0xFFFF0000), msg: AppLocalizations.of(context)!.translate('no_record'));
                                }
                              },
                              style: ElevatedButton.styleFrom(backgroundColor: color.backgroundColor),
                            ),
                            Container(
                              height: 30,
                              child: VerticalDivider(color: Colors.grey, thickness: 1),
                            ),
                            ElevatedButton(
                              child: Text(AppLocalizations.of(context)!.translate('reprint_settlement')),
                              onPressed: () {
                                openReprintSettlementDialog();
                              },
                              style: ElevatedButton.styleFrom(backgroundColor: color.buttonColor),
                            ),
                            Container(
                              height: 30,
                              child: VerticalDivider(color: Colors.grey, thickness: 1),
                            ),
                            // ElevatedButton(
                            //   child: Text(AppLocalizations.of(context)!.translate('cash_record_history')),
                            //   onPressed: () {
                            //     openSettlementHistoryDialog();
                            //   },
                            //   style: ElevatedButton.styleFrom(backgroundColor: color.backgroundColor),
                            // ),
                            // Container(
                            //   height: 30,
                            //   child: VerticalDivider(color: Colors.grey, thickness: 1),
                            // ),
                            ElevatedButton(
                              child: Text(AppLocalizations.of(context)!.translate('transfer_ownership')),
                              onPressed: () async {
                                if (await confirm(
                                  context,
                                  title: Text('${AppLocalizations.of(context)?.translate('confirm_pos_pin')}'),
                                  content: Text('${AppLocalizations.of(context)?.translate('to_pos_pin')}'),
                                  textOK: Text('${AppLocalizations.of(context)?.translate('yes')}'),
                                  textCancel: Text('${AppLocalizations.of(context)?.translate('no')}'),
                                )) {
                                  // return openPosPinDialog();
                                  return toPosPinPage();
                                }
                              },
                              style: ElevatedButton.styleFrom(backgroundColor: color.backgroundColor),
                            ),
                            Container(
                              height: 30,
                              child: VerticalDivider(color: Colors.grey, thickness: 1),
                            ),
                            ElevatedButton(
                              child: Text(AppLocalizations.of(context)!.translate('open_cash_drawer')),
                              onPressed: () async {
                                // openCashBoxDialog();
                                final prefs = await SharedPreferences.getInstance();
                                final String? pos_user = prefs.getString('pos_pin_user');
                                Map<String, dynamic> userMap = json.decode(pos_user!);
                                User userData = User.fromJson(userMap);

                                if (userData.cash_drawer_permission != 1) {
                                  openCashBoxDialog();
                                } else {
                                  await callOpenCashDrawer();
                                }
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
                    ),
                    Divider(
                      height: 10,
                      color: Colors.grey,
                    ),
                    cashRecordList.isNotEmpty ?
                    Container(
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
                                          text: AppLocalizations.of(context)!.translate('cash_in_by')+': ${cashRecordList[index].userName}',
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
                                          text: AppLocalizations.of(context)!.translate('close_by')+': ${cashRecordList[index].userName}',
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
                                          text: AppLocalizations.of(context)!.translate('cash_out')+': ${cashRecordList[index].userName}',
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
                                    if (cashRecordList[index].type != 0 && cashRecordList[index].type != 3 && cashRecordList[index].type != 4) {
                                      if (await confirm(
                                        context,
                                        title: Text('${AppLocalizations.of(context)?.translate('remove_cash_record')}'),
                                        content: Text('${AppLocalizations.of(context)?.translate('would_you_like_to_remove')}'),
                                        textOK: Text('${AppLocalizations.of(context)?.translate('yes')}'),
                                        textCancel: Text('${AppLocalizations.of(context)?.translate('no')}'),
                                      )) {
                                        return await removeCashRecord(cashRecordList[index], connectivity);
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
                          Text(AppLocalizations.of(context)!.translate('no_record')),
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
          ) : CustomProgressBar();
        } else {
          ///mobile layout
          return Scaffold(
            resizeToAvoidBottomInset: false,
            body: isLoad
                ? Container(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(15, 5, 20, 0),
                      child: SingleChildScrollView(
                        child: Column(
                          children: [
                            Container(
                                margin: EdgeInsets.fromLTRB(0, 0, 0, 10),
                                alignment: Alignment.topLeft,
                                child: Row(
                                  children: [
                                    Text(
                                      AppLocalizations.of(context)!.translate('counter'),
                                      style: TextStyle(fontSize: 25),
                                    ),
                                    Spacer(),
                                    Container(
                                      margin: EdgeInsets.only(right: 10),
                                      width: MediaQuery.of(context).size.width / 4,
                                      child: DropdownButton<PaymentLinkCompany>(
                                        onChanged: (value) {
                                          setState(() {
                                            paymentMethod = value!;
                                            readSpecificPaymentCashRecord(paymentMethod!.payment_type_id!);
                                          });
                                        },
                                        menuMaxHeight: 200,
                                        value: paymentMethod,
                                        // Hide the default underline
                                        underline: Container(),
                                        icon: Icon(
                                          Icons.arrow_drop_down,
                                          color: color.backgroundColor,
                                        ),
                                        isExpanded: true,
                                        // The list of options
                                        items: companyPaymentList
                                            .map((e) => DropdownMenuItem(
                                                  value: e,
                                                  child: Container(
                                                    alignment: Alignment.centerLeft,
                                                    child: Text(e.name!,style: TextStyle(fontSize: 18))
                                                  ),
                                                ))
                                            .toList(),
                                        // Customize the selected item
                                        selectedItemBuilder: (BuildContext context) => companyPaymentList.map((e) => Center(child: Text(e.name!))).toList(),
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
                                        child: Text(AppLocalizations.of(context)!.translate('cash_in')),
                                        onPressed: () async {
                                          final prefs = await SharedPreferences.getInstance();
                                          final String? pos_user = prefs.getString('pos_pin_user');
                                          Map<String, dynamic> userMap = json.decode(pos_user!);
                                          User userData = User.fromJson(userMap);

                                          if (userData.cash_drawer_permission != 1) {
                                            openCashInDialog();
                                          } else {
                                            await openCashDialog(true, false);
                                          }
                                        },
                                        style: ElevatedButton.styleFrom(backgroundColor: color.backgroundColor)),
                                    Container(
                                      height: 30,
                                      child: VerticalDivider(color: Colors.grey, thickness: 1),
                                    ),
                                    ElevatedButton(
                                      child: Text(AppLocalizations.of(context)!.translate('cash_out')),
                                      onPressed: () async {
                                        if (cashRecordList.isNotEmpty) {
                                          // openCashOutDialog();
                                          // openCashDialog(false, true);
                                          final prefs = await SharedPreferences.getInstance();
                                          final String? pos_user = prefs.getString('pos_pin_user');
                                          Map<String, dynamic> userMap = json.decode(pos_user!);
                                          User userData = User.fromJson(userMap);

                                          if (userData.cash_drawer_permission != 1) {
                                            openCashOutDialog();
                                          } else {
                                            await openCashDialog(false, true);
                                          }
                                        } else {
                                          Fluttertoast.showToast(backgroundColor: Color(0xFFFF0000), msg: AppLocalizations.of(context)!.translate('no_record'));
                                        }
                                      },
                                      style: ElevatedButton.styleFrom(backgroundColor: color.buttonColor),
                                    ),
                                    Container(
                                      height: 30,
                                      child: VerticalDivider(color: Colors.grey, thickness: 1),
                                    ),
                                    ElevatedButton(
                                      child: Text(AppLocalizations.of(context)!.translate('settlement')),
                                      onPressed: () {
                                        if (cashRecordList.isNotEmpty) {
                                          openSettlementDialog(cashRecordList);
                                        } else {
                                          Fluttertoast.showToast(backgroundColor: Color(0xFFFF0000), msg: AppLocalizations.of(context)!.translate('no_record'));
                                        }
                                      },
                                      style: ElevatedButton.styleFrom(backgroundColor: color.backgroundColor),
                                    ),
                                    Container(
                                      height: 30,
                                      child: VerticalDivider(color: Colors.grey, thickness: 1),
                                    ),
                                    ElevatedButton(
                                      child: Text(AppLocalizations.of(context)!.translate('reprint_settlement')),
                                      onPressed: () {
                                        openReprintSettlementDialog();
                                      },
                                      style: ElevatedButton.styleFrom(backgroundColor: color.buttonColor),
                                    ),
                                    Container(
                                      height: 30,
                                      child: VerticalDivider(color: Colors.grey, thickness: 1),
                                    ),
                                    ElevatedButton(
                                      child: Text(AppLocalizations.of(context)!.translate('transfer_ownership')),
                                      onPressed: () async {
                                        if(cashRecordList.isNotEmpty){
                                          if (await confirm(
                                            context,
                                            title: Text('${AppLocalizations.of(context)?.translate('confirm_pos_pin')}'),
                                            content: Text('${AppLocalizations.of(context)?.translate('to_pos_pin')}'),
                                            textOK: Text('${AppLocalizations.of(context)?.translate('yes')}'),
                                            textCancel: Text('${AppLocalizations.of(context)?.translate('no')}'),
                                          )) {
                                            // return openPosPinDialog();
                                            return toPosPinPage();
                                          }
                                        } else {
                                          Fluttertoast.showToast(backgroundColor: Color(0xFFFF0000), msg: "${AppLocalizations.of(context)?.translate('close_counter_warn')}");
                                        }
                                      },
                                      style: ElevatedButton.styleFrom(backgroundColor: color.backgroundColor),
                                    ),
                                    Container(
                                      height: 30,
                                      child: VerticalDivider(color: Colors.grey, thickness: 1),
                                    ),
                                    ElevatedButton(
                                      child: Text(AppLocalizations.of(context)!.translate('open_cash_drawer')),
                                      onPressed: () async {
                                        // openCashBoxDialog();
                                        final prefs = await SharedPreferences.getInstance();
                                        final String? pos_user = prefs.getString('pos_pin_user');
                                        Map<String, dynamic> userMap = json.decode(pos_user!);
                                        User userData = User.fromJson(userMap);

                                        if (userData.cash_drawer_permission != 1) {
                                          openCashBoxDialog();
                                        } else {
                                          await callOpenCashDrawer();
                                        }
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
                            cashRecordList.isNotEmpty
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
                                                            text: AppLocalizations.of(context)!.translate('cash_in_by')+': ${cashRecordList[index].userName}',
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
                                                                text: AppLocalizations.of(context)!.translate('cash_out_by')+': ${cashRecordList[index].userName}',
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
                                                                    text: AppLocalizations.of(context)!.translate('close_by')+': ${cashRecordList[index].userName}',
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
                                                                    text: AppLocalizations.of(context)!.translate('refund_by')+': ${cashRecordList[index].userName}',
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
                                                if (cashRecordList[index].type != 0 && cashRecordList[index].type != 3 && cashRecordList[index].type != 4) {
                                                  if (await confirm(
                                                    context,
                                                    title: Text('${AppLocalizations.of(context)?.translate('remove_cash_record')}'),
                                                    content: Text('${AppLocalizations.of(context)?.translate('would_you_like_to_remove')}'),
                                                    textOK: Text('${AppLocalizations.of(context)?.translate('yes')}'),
                                                    textCancel: Text('${AppLocalizations.of(context)?.translate('no')}'),
                                                  )) {
                                                    return await removeCashRecord(cashRecordList[index], connectivity);
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
                                        Text(AppLocalizations.of(context)!.translate('no_record')),
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
              height: MediaQuery.of(context).size.height / 6,
              child: Column(
                children: [
                  Divider(
                    height: 10,
                    color: Colors.grey,
                  ),
                  Container(
                      margin: EdgeInsets.all(5),
                      padding: EdgeInsets.only(right: 10),
                      alignment: Alignment.bottomRight,
                      child: Text(
                        '${getTotalAmount()}',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24),
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
                transfer_ownership: true,
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

  Future<Future<Object?>> openCashInDialog() async {
    return showGeneralDialog(
        barrierColor: Colors.black.withOpacity(0.5),
        transitionBuilder: (context, a1, a2, widget) {
          final curvedValue = Curves.easeInOutBack.transform(a1.value) - 1.0;
          return Transform(
            transform: Matrix4.translationValues(0.0, curvedValue * 200, 0.0),
            child: Opacity(
                opacity: a1.value,
                child: PosPinDialog(
                  transfer_ownership: false,
                  callBack: () => openCashDialog(true, false),
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
                  transfer_ownership: false,
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
                printerList: printerList,
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

  Future<Future<Object?>> openReprintSettlementDialog() async {
    return showDialog(
      barrierDismissible: false,
      context: context,
      builder: (_) => ReprintSettlementDialog(),
    );;
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
    companyPaymentList.add(PaymentLinkCompany(
      name: 'All/Cash Drawer',
      payment_type_id: '0'
    ));
    paymentMethod = companyPaymentList.first;
    final prefs = await SharedPreferences.getInstance();
    final String? user = prefs.getString('user');
    Map userObject = json.decode(user!);
    List<PaymentLinkCompany> data = await PosDatabase.instance.readAllPaymentLinkCompany(userObject['company_id']);
    companyPaymentList.addAll(data);
  }

  checkUnpaidOrderCache() async {
    List<OrderCache> data = await PosDatabase.instance.readAllUnpaidOrderCache();
    unpaidOrderCacheList = data;
    print('unpaid Order Cache List: ${unpaidOrderCacheList.length}');
  }

  readSpecificPaymentCashRecord(String paymentTypeId){
    print("payment type id: ${paymentTypeId}");
    if(paymentTypeId != '0'){
      return cashRecordList = initCashRecordList.where((e) => e.payment_type_id == paymentTypeId).toList();
    } else {
      return cashRecordList = initCashRecordList;
    }
  }

  readCashRecord() async {
    isLoad = false;
    await readPaymentLinkCompany();
    List<CashRecord> data = await PosDatabase.instance.readBranchCashRecord();
    initCashRecordList = data;
    cashRecordList = initCashRecordList;
    if(!mounted) return;
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
      await syncCashRecordToCloud(_value.toString());
      if(isLogOut){
        openLogOutDialog();
        return;
      }
      //syncUpdatedCashRecordToCloud(_value.toString());
    } catch (e) {
      print('delete cash record error: ${e}');
      Fluttertoast.showToast(backgroundColor: Color(0xFFFF0000), msg: AppLocalizations.of(context)!.translate('delete_cash_record_error')+" ${e}");
    }
  }

  // syncUpdatedCashRecordToCloud(String value) async {
  //   bool _hasInternetAccess = await Domain().isHostReachable();
  //   if (_hasInternetAccess) {
  //     Map response = await Domain().SyncCashRecordToCloud(value);
  //     if (response['status'] == '1') {
  //       List responseJson = response['data'];
  //       int cashRecordData = await PosDatabase.instance.updateCashRecordSyncStatusFromCloud(responseJson[0]['cash_record_key']);
  //     }
  //   }
  // }

  syncCashRecordToCloud(String value) async {
    try{
      if(mainSyncToCloud.count == 0){
        mainSyncToCloud.count = 1;
        final prefs = await SharedPreferences.getInstance();
        final int? device_id = prefs.getInt('device_id');
        final String? login_value = prefs.getString('login_value');
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
        } else {
          mainSyncToCloud.resetCount();
        }
      }
    }catch(e){
      mainSyncToCloud.resetCount();
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

/*
  ----------------Other function part------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
*/
  reprintLatestSettlement() async {
    Settlement? settlement = await PosDatabase.instance.readLatestSettlement();
    if(settlement != null){
      await callPrinter(currentSettlementDateTime: settlement.created_at!, settlement: settlement);
    } else {
      Fluttertoast.showToast(
          backgroundColor: Colors.red,
          msg: AppLocalizations.of(context)!.translate('no_settlement_record_found'));
    }
  }

  callPrinter({required String currentSettlementDateTime, required Settlement settlement}) async {
    int printStatus = await printReceipt.printSettlementList(printerList, currentSettlementDateTime, settlement);
    if(printStatus == 1){
      Fluttertoast.showToast(
          backgroundColor: Colors.red,
          msg: "${AppLocalizations.of(context)?.translate('printer_not_connected')}");
    } else if (printStatus == 2){
      Fluttertoast.showToast(
          backgroundColor: Colors.orangeAccent,
          msg: "${AppLocalizations.of(context)?.translate('printer_connection_timeout')}");
    }else if(printStatus == 3){
      Fluttertoast.showToast(
          backgroundColor: Colors.red,
          msg: AppLocalizations.of(context)!.translate('no_cashier_printer_added'));
    }
  }

  setScreenLayout() {
    final double screenWidth = MediaQueryData.fromView(WidgetsBinding.instance.window).size.width;
    if (screenWidth < 500) {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown
      ]);
    }
  }

  toPosPinPage() {
    String cashDrawer = calcCashDrawer();
    print('to pos pin call him');
    // Navigator.push(context,
    //   PageTransition(type: PageTransitionType.fade, child: PosPinPage(cashBalance: cashDrawer),
    //   ),
    // );
    setScreenLayout();
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

  getPaymentOption(paymentOption){
    if(paymentOption == 'All/Cash Drawer') return 'all_cash_drawer';
    else if(paymentOption == 'Cash') return 'cash';
    else if(paymentOption == 'Card') return 'card';
    else return paymentOption;
  }

  String getTotalAmount() {
    String total = "${AppLocalizations.of(context)!.translate('amount')}: ";
    if(paymentMethod!.payment_type_id == '0'){
      total += calcTotalAmount();
      total += ' / ${AppLocalizations.of(context)!.translate('cash_drawer_amount')}: ${calcCashDrawer()}';
    } else {
      total += calcTotalAmount();
    }
    return total;
  }

  String calcTotalAmount() {
    try {
      double total = 0.0;
      double totalRefund = 0.0;
      double subtotal = 0.0;
      if(paymentMethod!.payment_type_id == '0'){
        final list = cashRecordList.where((e) =>  e.type == 0 || e.type == 1 || e.type == 3).toList().map((e) => double.parse(e.amount!)).toList();
        if(list.isNotEmpty){
          total = list.reduce((a, b) => a + b);
        }
        final refundList = cashRecordList.where((e) => e.type == 2 || e.type == 4).map((e) => double.parse(e.amount!)).toList();
        if(refundList.isNotEmpty){
          totalRefund = refundList.reduce((a, b) => a + b);
        }
      } else {
        for (int i = 0; i < cashRecordList.length; i++) {
          if (cashRecordList[i].payment_type_id == paymentMethod!.payment_type_id && cashRecordList[i].type == 3) {
            total += double.parse(cashRecordList[i].amount!);
          } else if (cashRecordList[i].payment_type_id == paymentMethod!.payment_type_id && cashRecordList[i].type == 4) {
            totalRefund += double.parse(cashRecordList[i].amount!);
          }
        }
      }
      subtotal = total - totalRefund;
      return subtotal.toStringAsFixed(2);
    } catch (e) {
      FLog.error(
        className: "settlement page",
        text: "Calc total amount error",
        exception: "$e",
      );
      Fluttertoast.showToast(backgroundColor: Color(0xFFFF0000), msg: AppLocalizations.of(context)!.translate('calculate_cash_error')+" ${e}");
      return '0.00';
    }
  }

  String calcCashDrawer() {
    try {
      double totalCashIn = 0.0;
      double totalCashDrawer = 0.0;
      double totalCashRefundAndOut = 0.0;
      final list = cashRecordList.where((e) => (e.payment_type_id == '1' || e.payment_type_id == '') && (e.type == 0 || e.type == 1 || e.type == 3)).toList().map((e) => double.parse(e.amount!)).toList();
      if(list.isNotEmpty){
        totalCashIn = list.reduce((a, b) => a + b);
      }
      final refundList = cashRecordList.where((e) => (e.payment_type_id == '1' || e.payment_type_id == '') && (e.type == 2 || e.type == 4)).map((e) => double.parse(e.amount!)).toList();
      if(refundList.isNotEmpty){
        totalCashRefundAndOut = refundList.reduce((a, b) => a + b);
      }
      totalCashDrawer = totalCashIn - totalCashRefundAndOut;
      return totalCashDrawer.toStringAsFixed(2);
    } catch (e) {
      FLog.error(
        className: "settlement page",
        text: "Calc cash drawer error",
        exception: "$e",
      );
      Fluttertoast.showToast(backgroundColor: Color(0xFFFF0000), msg: AppLocalizations.of(context)!.translate('calculate_cash_drawer_error')+" ${e}");
      return '0.00';
    }
  }

  callOpenCashDrawer() async {
    int printStatus = await PrintReceipt().cashDrawer(printerList: this.printerList);
    if (printStatus == 1) {
      Fluttertoast.showToast(
          backgroundColor: Colors.red,
          msg:
          "${AppLocalizations.of(context)?.translate('printer_not_connected')}");
    } else if (printStatus == 2) {
      Fluttertoast.showToast(
          backgroundColor: Colors.orangeAccent,
          msg:
          "${AppLocalizations.of(context)?.translate('printer_connection_timeout')}");
    } else if (printStatus == 3) {
      Fluttertoast.showToast(
          backgroundColor: Colors.red,
          msg: AppLocalizations.of(context)!
              .translate('no_cashier_printer_added'));
    } else if (printStatus == 4) {
      Fluttertoast.showToast(
          backgroundColor: Colors.orangeAccent,
          msg:
          "${AppLocalizations.of(context)?.translate('no_cashier_printer')}");
    }
  }
}
