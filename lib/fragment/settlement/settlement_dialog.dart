import 'dart:async';
import 'dart:convert';

import 'package:confirm_dialog/confirm_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_usb_printer/flutter_usb_printer.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';
import 'package:pos_system/main.dart';
import 'package:pos_system/object/order_detail_cancel.dart';
import 'package:pos_system/object/order_promotion_detail.dart';
import 'package:pos_system/object/print_receipt.dart';
import 'package:pos_system/object/settlement.dart';
import 'package:pos_system/object/settlement_link_payment.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:crypto/crypto.dart';

import '../../database/domain.dart';
import '../../database/pos_database.dart';
import '../../notifier/theme_color.dart';
import '../../object/cash_record.dart';
import '../../object/order.dart';
import '../../object/order_tax_detail.dart';
import '../../object/payment_link_company.dart';
import '../../object/printer.dart';
import '../../object/report_class.dart';
import '../../object/user.dart';
import '../../translation/AppLocalizations.dart';
import '../../utils/Utils.dart';
import '../logout_dialog.dart';
import '../setting/sync_dialog.dart';

class SettlementDialog extends StatefulWidget {
  final List<Printer> printerList;
  final List<CashRecord> cashRecordList;
  final Function() callBack;

  const SettlementDialog(
      {Key? key,
      required this.cashRecordList,
      required this.callBack,
      required this.printerList})
      : super(key: key);

  @override
  State<SettlementDialog> createState() => _SettlementDialogState();
}

class _SettlementDialogState extends State<SettlementDialog> {
  final adminPosPinController = TextEditingController();
  FlutterUsbPrinter flutterUsbPrinter = FlutterUsbPrinter();
  DateFormat dateFormat = DateFormat("yyyy-MM-dd HH:mm:ss");
  String currentEdDate =
      new DateFormat("yyyy-MM-dd 00:00:00").format(DateTime.now());
  double totalSales = 0.0,
      totalRefundAmount = 0.0,
      totalPromotionAmount = 0.0,
      totalTax = 0.0;
  int totalBill = 0, totalRefundBill = 0, totalCancelItem = 0;
  List<Order> dateOrderList = [], dateRefundList = [], orderList = [];
  List<OrderPromotionDetail> datePromotionDetail = [];
  List<OrderDetailCancel> dateOrderDetailCancel = [];
  List<OrderTaxDetail> dateTaxList = [];
  List<PaymentLinkCompany> paymentList = [];
  List<Printer> printerList = [];
  String localSettlementId = '', settlementKey = '';
  String? settlement_value,
      settlement_link_payment_value,
      order_value,
      order_cancel_value,
      cash_record_value;
  Settlement? settlement;
  bool _submitted = false;
  bool _isLoaded = false;
  bool isButtonDisabled = false, isLogOut = false, willPop = true;

  late final currentSettlementDateTime;

  @override
  void initState() {
    super.initState();
    preload();
  }

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
    adminPosPinController.dispose();
  }

  String? get errorPassword {
    final text = adminPosPinController.value.text;
    if (text.isEmpty) {
      return 'password_required';
    }
    return null;
  }

  void _submit(BuildContext context, ThemeColor color) async {
    setState(() => _submitted = true);
    if (errorPassword == null) {
      // Disable the button after it has been pressed
      await readAdminData(adminPosPinController.text);
      willPop = true;
      if (await confirm(
        context,
        title: Text('${AppLocalizations.of(context)?.translate('confirm_sync')}'),
        content: Text('${AppLocalizations.of(context)?.translate('confirm_sync_desc')}'),
        textOK: Text('${AppLocalizations.of(context)?.translate('yes')}'),
        textCancel: Text('${AppLocalizations.of(context)?.translate('no')}'),
      )) {
        bool? status = await openSyncDialog();
        if(status != null && status == true){
          widget.callBack();
          Navigator.of(context).pop();
        } else {
          widget.callBack();
          Navigator.of(context).pop();
        }
      } else {
        widget.callBack();
        Navigator.of(context).pop();
      }
    }
  }

  openSyncDialog() async {
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

  // Future showAfterSettlementDialog(BuildContext context, ThemeColor color) {
  //   return showDialog(
  //       barrierDismissible: false,
  //       context: context,
  //       builder: (BuildContext context) {
  //         return StatefulBuilder(builder: (context, StateSetter setState){
  //           return Center(
  //             child: SingleChildScrollView(
  //               physics: NeverScrollableScrollPhysics(),
  //               child: AlertDialog(
  //                 title: Text('Settlement success'),
  //                 content: Column(
  //                   mainAxisAlignment: MainAxisAlignment.center,
  //                   children: [
  //                     SizedBox(
  //                       width: 190,
  //                       height: 60,
  //                       child: ElevatedButton(
  //                           onPressed: () async {
  //                             await callPrinter();
  //                             widget.callBack();
  //                             // Navigator.of(context).pop();
  //                             // Navigator.of(context).pop();
  //                           },
  //                           child: Row(
  //                             children: [
  //                               Text("Reprint settlement"),
  //                              Spacer(),
  //                               Icon(Icons.print)
  //                             ],
  //                           )),
  //                     ),
  //                     SizedBox(height: 20),
  //                     SizedBox(
  //                       height: 60,
  //                       width: 100,
  //                       child: ElevatedButton(
  //                           onPressed: isButtonDisabled ? null : (){
  //                             setState(() {
  //                               isButtonDisabled = true;
  //                             });
  //                             widget.callBack();
  //                             Navigator.of(context).pop();
  //                             Navigator.of(context).pop();
  //                           },
  //                           child: Row(
  //                             children: [
  //                               Text("Close"),
  //                               Spacer(),
  //                               Icon(Icons.close)
  //                             ],
  //                           )),
  //                     )
  //                   ],
  //                 ),
  //               ),
  //             ),
  //           );
  //         });
  //       }
  //   );
  // }

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

  closeDialog(BuildContext context) {
    return Navigator.of(context).pop(true);
  }

  Future showSecondDialog(BuildContext context, ThemeColor color) {
    return showDialog(
        barrierDismissible: false,
        context: context,
        builder: (BuildContext context) {
          return StatefulBuilder(builder: (context, StateSetter setState) {
            return WillPopScope(
              onWillPop: () async {
                widget.callBack();
                return willPop;
              },
              child: Center(
                child: SingleChildScrollView(
                  child: AlertDialog(
                    title: Text(AppLocalizations.of(context)!
                        .translate('enter_admin_pin')),
                    content: SizedBox(
                      height: 100.0,
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
                                    willPop = false;
                                    isButtonDisabled = true;
                                  });
                                  _submit(context, color);
                                },
                                obscureText: true,
                                controller: adminPosPinController,
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                  errorText: _submitted
                                      ? errorPassword == null
                                          ? errorPassword
                                          : AppLocalizations.of(context)
                                              ?.translate(errorPassword!)
                                      : null,
                                  border: OutlineInputBorder(
                                    borderSide: BorderSide(
                                        color: color.backgroundColor),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderSide: BorderSide(
                                        color: color.backgroundColor),
                                  ),
                                  labelText: "PIN",
                                ),
                              ),
                            );
                          }),
                    ),
                    actions: <Widget>[
                      TextButton(
                        child: Text(
                            '${AppLocalizations.of(context)?.translate('close')}'),
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
                        child: Text(
                            '${AppLocalizations.of(context)?.translate('yes')}'),
                        onPressed: isButtonDisabled
                            ? null
                            : () async {
                                setState(() {
                                  willPop = false;
                                  isButtonDisabled = true;
                                });
                                _submit(context, color);
                              },
                      ),
                    ],
                  ),
                ),
              ),
            );
          });
        });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeColor>(builder: (context, ThemeColor color, child) {
      return AlertDialog(
        title: Text(
            AppLocalizations.of(context)!.translate('confirm_do_settlement')),
        content: Container(
          child: Text(
              '${AppLocalizations.of(context)?.translate('settlement_desc')}'),
        ),
        actions: [
          TextButton(
            child:
            Text('${AppLocalizations.of(context)?.translate('close')}'),
            onPressed: () {
              closeDialog(context);
            },
          ),
          TextButton(
            child: Text('${AppLocalizations.of(context)?.translate('yes')}'),
            onPressed: () async {
              final prefs = await SharedPreferences.getInstance();
              final String? pos_user = prefs.getString('pos_pin_user');
              Map<String, dynamic> userMap = json.decode(pos_user!);
              User userData = User.fromJson(userMap);

              if(userData.settlement_permission != 1) {
                await showSecondDialog(context, color);
                closeDialog(context);
              } else {
                currentSettlementDateTime = dateFormat.format(DateTime.now());
                await callSettlement();
                if (await confirm(
                  context,
                  title: Text('${AppLocalizations.of(context)?.translate('confirm_sync')}'),
                  content: Text('${AppLocalizations.of(context)?.translate('confirm_sync_desc')}'),
                  textOK: Text('${AppLocalizations.of(context)?.translate('yes')}'),
                  textCancel: Text('${AppLocalizations.of(context)?.translate('no')}'),
                )) {
                  bool? status = await openSyncDialog();
                  if(status != null && status == true){
                    widget.callBack();
                    Navigator.of(context).pop();
                  } else {
                    widget.callBack();
                    Navigator.of(context).pop();
                  }
                } else {
                  widget.callBack();
                  Navigator.of(context).pop();
                }
                // Navigator.of(context).pop();
              }
            },
          )
        ],
      );
    });
  }

/*
  ----------------DB Query part------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
*/

  readAdminData(String pin) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? pos_user = prefs.getString('pos_pin_user');
      Map userObject = json.decode(pos_user!);
      currentSettlementDateTime = dateFormat.format(DateTime.now());
      User? userData = await PosDatabase.instance.readSpecificUserWithPin(pin);
      if (userData != null) {
        if (userData.settlement_permission == 1) {
          await callSettlement();
        } else {
          Fluttertoast.showToast(backgroundColor: Color(0xFFFF0000), msg: "${AppLocalizations.of(context)?.translate('no_permission')}");
        }
      } else {
        Fluttertoast.showToast(backgroundColor: Color(0xFFFF0000), msg: "${AppLocalizations.of(context)?.translate('user_not_found')}");
      }
    } catch (e) {
      print('user checking error ${e}');
      return;
    }
  }

  callSettlement() async {
    //create settlement
    await createSettlement();
    await createSettlementLinkPayment();
    //update all today cash record settlement date
    await updateTodaySettlementOrder();
    await updateTodaySettlementOrderDetailCancel();
    await updateAllCashRecordSettlement();
    await callPrinter();
  }

  callPrinter() async {
    int printStatus = await PrintReceipt().printSettlementList(
        printerList, currentSettlementDateTime, this.settlement!);
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
    }
  }

  generateSettlementKey(Settlement settlement) async {
    final prefs = await SharedPreferences.getInstance();
    final int? device_id = prefs.getInt('device_id');
    var bytes = settlement.created_at!.replaceAll(new RegExp(r'[^0-9]'), '') +
        settlement.settlement_sqlite_id.toString() +
        device_id.toString();
    print('bytes: ${bytes}');
    var md5Hash = md5.convert(utf8.encode(bytes));
    return Utils.shortHashString(hashCode: md5Hash);
  }

  insertSettlementKey(Settlement settlement, String dateTime) async {
    String? _key;
    Settlement? _data;
    _key = await generateSettlementKey(settlement);
    if (_key != null) {
      Settlement object = Settlement(
          settlement_key: _key,
          sync_status: 0,
          updated_at: dateTime,
          settlement_sqlite_id: settlement.settlement_sqlite_id);

      int updatedData =
          await PosDatabase.instance.updateSettlementUniqueKey(object);
      if (updatedData == 1) {
        Settlement data = await PosDatabase.instance
            .readSpecificSettlementByLocalId(settlement.settlement_sqlite_id!);
        _data = data;
      }
    }
    return _data;
  }

  createSettlement() async {
    List<String> _value = [];
    DateFormat dateFormat = DateFormat("yyyy-MM-dd HH:mm:ss");
    String dateTime = dateFormat.format(DateTime.now());
    final prefs = await SharedPreferences.getInstance();
    final String? login_user = prefs.getString('user');
    final int? branch_id = prefs.getInt('branch_id');
    final String? pos_user = prefs.getString('pos_pin_user');
    Map logInUser = json.decode(login_user!);
    Map userObject = json.decode(pos_user!);

    Settlement object = Settlement(
        settlement_id: 0,
        settlement_key: '',
        company_id: logInUser['company_id'].toString(),
        branch_id: branch_id.toString(),
        total_bill: this.totalBill.toString(),
        //dateOrderList.length.toString(),
        total_sales: this.totalSales.toStringAsFixed(2),
        total_refund_bill: this.totalRefundBill.toString(),
        //dateRefundList.length.toString(),
        total_refund_amount: this.totalRefundAmount.toStringAsFixed(2),
        //totalRefundAmount.toStringAsFixed(2),
        total_discount: this.totalPromotionAmount.toStringAsFixed(2),
        //totalPromotionAmount.toStringAsFixed(2),
        total_cancellation: this.totalCancelItem.toString(),
        //dateOrderDetailCancel[0].total_item != null ? dateOrderDetailCancel[0].total_item.toString() : '0',
        total_tax: this.totalTax.toStringAsFixed(2),
        //totalTax.toStringAsFixed(2),
        settlement_by_user_id: userObject['user_id'].toString(),
        settlement_by: userObject['name'].toString(),
        status: 0,
        sync_status: 0,
        created_at: dateTime,
        updated_at: '',
        soft_delete: '');
    Settlement data = await PosDatabase.instance.insertSqliteSettlement(object);
    Settlement updatedData = await insertSettlementKey(data, dateTime);
    this.settlement = updatedData;
    localSettlementId = updatedData.settlement_sqlite_id.toString();
    settlementKey = updatedData.settlement_key!;
    _value.add(jsonEncode(updatedData));
    settlement_value = _value.toString();
    //syncSettlementToCloud(value.toString());
  }

  // syncSettlementToCloud(String value) async {
  //   bool _hasInternetAccess = await Domain().isHostReachable();
  //   if (_hasInternetAccess) {
  //     Map settlementResponse = await Domain().SyncSettlementToCloud(value);
  //     if (settlementResponse['status'] == '1') {
  //       List responseJson = settlementResponse['data'];
  //       for (int i = 0; i < responseJson.length; i++) {
  //         int syncUpdated = await PosDatabase.instance.updateSettlementSyncStatusFromCloud(responseJson[i]['settlement_key']);
  //       }
  //     }
  //   }
  // }

  // updateSettlement(int settlement_sqlite_id) async {
  //   List<String> value = [];
  //   DateFormat dateFormat = DateFormat("yyyy-MM-dd HH:mm:ss");
  //   String dateTime = dateFormat.format(DateTime.now());
  //   final prefs = await SharedPreferences.getInstance();
  //   final String? pos_user = prefs.getString('pos_pin_user');
  //   Map userObject = json.decode(pos_user!);
  //
  //   Settlement checkData = await PosDatabase.instance.readSpecificSettlementByLocalId(settlement_sqlite_id);
  //   Settlement object = Settlement(
  //       settlement_sqlite_id: settlement_sqlite_id,
  //       total_bill: dateOrderList.length.toString(),
  //       total_sales: this.totalSales.toStringAsFixed(2),
  //       total_refund_bill: dateRefundList.length.toString(),
  //       total_refund_amount: totalRefundAmount.toStringAsFixed(2),
  //       total_discount: totalPromotionAmount.toStringAsFixed(2),
  //       total_cancellation: dateOrderDetailCancel[0].total_item != null ? dateOrderDetailCancel[0].total_item.toString() : '0',
  //       total_tax: totalTax.toStringAsFixed(2),
  //       settlement_by_user_id: userObject['user_id'].toString(),
  //       settlement_by: userObject['name'].toString(),
  //       status: 0,
  //       sync_status: checkData.sync_status == 0 ? 0 : 2,
  //       updated_at: dateTime,
  //   );
  //   int data = await PosDatabase.instance.updateSettlement(object);
  //   if(data == 1){
  //     Settlement updatedData = await PosDatabase.instance.readSpecificSettlementByLocalId(settlement_sqlite_id);
  //     updateSettlementLinkPayment(settlement_key: updatedData.settlement_key);
  //     value.add(jsonEncode(updatedData));
  //   }
  //   //sync to cloud
  //   syncSettlementToCloud(value.toString());
  // }

  // updateSettlementLinkPayment({settlement_key}) async {
  //   List<String> _value = [];
  //   DateFormat dateFormat = DateFormat("yyyy-MM-dd HH:mm:ss");
  //   String dateTime = dateFormat.format(DateTime.now());
  //   for(int j = 0 ; j < paymentList.length; j++) {
  //     SettlementLinkPayment checkData = await PosDatabase.instance.readAllSettlementLinkPaymentWithKeyAndPayment(settlement_key, paymentList[j].payment_link_company_id!);
  //     SettlementLinkPayment object = SettlementLinkPayment(
  //         total_bill: paymentList[j].total_bill.toString(),
  //         total_sales: paymentList[j].totalAmount.toStringAsFixed(2),
  //         status: 0,
  //         sync_status: checkData.sync_status == 0 ? 0 : 2,
  //         updated_at: dateTime,
  //         settlement_link_payment_sqlite_id: checkData.settlement_link_payment_sqlite_id
  //     );
  //     int status = await PosDatabase.instance.updateSettlementLinkPayment(object);
  //     if(status == 1){
  //       SettlementLinkPayment updatedData = await PosDatabase.instance.readSpecificSettlementLinkPaymentByPaymentLinkCompany(paymentList[j].payment_link_company_id!);
  //       _value.add(jsonEncode(updatedData));
  //     }
  //     //sync to cloud
  //     syncSettlementLinkPaymentToCloud(_value.toString());
  //   }
  // }

  updateTodaySettlementOrder() async {
    List<Order> _orderList = [];
    List<String> _value = [];
    List<Order> data = await PosDatabase.instance.readAllNotSettlementOrder();
    _orderList = data;
    if (_orderList.isNotEmpty) {
      for (int i = 0; i < _orderList.length; i++) {
        Order object = Order(
            updated_at: currentSettlementDateTime,
            sync_status: _orderList[i].sync_status == 0 ? 0 : 2,
            settlement_key: this.settlement!.settlement_key,
            settlement_sqlite_id:
                this.settlement!.settlement_sqlite_id.toString(),
            order_sqlite_id: _orderList[i].order_sqlite_id);
        int status = await PosDatabase.instance.updateOrderSettlement(object);
        Order order = await PosDatabase.instance
            .readSpecificOrder(_orderList[i].order_sqlite_id!);
        _value.add(jsonEncode(order));
      }
      this.order_value = _value.toString();
    }
  }

  updateTodaySettlementOrderDetailCancel() async {
    List<OrderDetailCancel> _orderDetailCancelList = [];
    List<String> _value = [];
    List<OrderDetailCancel> data =
        await PosDatabase.instance.readAllNotSettlementOrderDetailCancel();
    _orderDetailCancelList = data;
    print('cancel length: ${_orderDetailCancelList.length}');
    if (_orderDetailCancelList.isNotEmpty) {
      for (int i = 0; i < _orderDetailCancelList.length; i++) {
        OrderDetailCancel object = OrderDetailCancel(
          updated_at: currentSettlementDateTime,
          sync_status: _orderDetailCancelList[i].sync_status == 0 ? 0 : 2,
          settlement_key: this.settlement!.settlement_key,
          settlement_sqlite_id:
              this.settlement!.settlement_sqlite_id.toString(),
          order_detail_cancel_sqlite_id:
              _orderDetailCancelList[i].order_detail_cancel_sqlite_id,
        );
        int status = await PosDatabase.instance
            .updateOrderDetailCancelSettlement(object);
        OrderDetailCancel orderDetailCancelData = await PosDatabase.instance
            .readSpecificOrderDetailCancelByLocalId(
                object.order_detail_cancel_sqlite_id!);
        _value.add(jsonEncode(orderDetailCancelData));
      }
      this.order_cancel_value = _value.toString();
    }
  }

  updateAllCashRecordSettlement() async {
    List<String> _value = [];
    for (int i = 0; i < widget.cashRecordList.length; i++) {
      CashRecord cashRecord = CashRecord(
          settlement_date: currentSettlementDateTime,
          settlement_key: this.settlement!.settlement_key,
          sync_status: widget.cashRecordList[i].sync_status == 0 ? 0 : 2,
          updated_at: currentSettlementDateTime,
          cash_record_sqlite_id:
              widget.cashRecordList[i].cash_record_sqlite_id);
      int data = await PosDatabase.instance.updateCashRecord(cashRecord);
      if (data == 1) {
        //collect all not sync local create/update data
        CashRecord _record = await PosDatabase.instance
            .readSpecificCashRecord(cashRecord.cash_record_sqlite_id!);
        if (_record.sync_status != 1) {
          _value.add(jsonEncode(_record));
        }
      }
    }
    cash_record_value = _value.toString();
    //sync to cloud
    //await syncSettlementCashRecordToCloud(_value.toString());
  }

  // syncSettlementCashRecordToCloud(String value) async {
  //   bool _hasInternetAccess = await Domain().isHostReachable();
  //   if(_hasInternetAccess){
  //     Map response = await Domain().SyncCashRecordToCloud(value);
  //     if (response['status'] == '1') {
  //       List responseJson = response['data'];
  //       for (var i = 0; i < responseJson.length; i++) {
  //         int cashRecordData = await PosDatabase.instance.updateCashRecordSyncStatusFromCloud(responseJson[i]['cash_record_key']);
  //       }
  //     }
  //   }
  // }

  generateSettlementLinkPaymentKey(
      SettlementLinkPayment settlementLinkPayment) async {
    final prefs = await SharedPreferences.getInstance();
    final int? device_id = prefs.getInt('device_id');
    var bytes = settlementLinkPayment.created_at!
            .replaceAll(new RegExp(r'[^0-9]'), '') +
        settlementLinkPayment.settlement_link_payment_sqlite_id.toString() +
        device_id.toString();
    var md5Hash = md5.convert(utf8.encode(bytes));
    return Utils.shortHashString(hashCode: md5Hash);
  }

  insertSettlementLinkPaymentKey(
      SettlementLinkPayment settlementLinkPayment, String dateTime) async {
    String? _key;
    SettlementLinkPayment? _data;
    _key = await generateSettlementLinkPaymentKey(settlementLinkPayment);
    if (_key != null) {
      SettlementLinkPayment object = SettlementLinkPayment(
          settlement_link_payment_key: _key,
          sync_status: 0,
          updated_at: dateTime,
          settlement_link_payment_sqlite_id:
              settlementLinkPayment.settlement_link_payment_sqlite_id);

      int updatedData = await PosDatabase.instance
          .updateSettlementLinkPaymentUniqueKey(object);
      if (updatedData == 1) {
        SettlementLinkPayment data = await PosDatabase.instance
            .readSpecificSettlementLinkPaymentByLocalId(
                settlementLinkPayment.settlement_link_payment_sqlite_id!);
        _data = data;
      }
    }
    return _data;
  }

  createSettlementLinkPayment() async {
    List<String> _value = [];
    DateFormat dateFormat = DateFormat("yyyy-MM-dd HH:mm:ss");
    String dateTime = dateFormat.format(DateTime.now());
    final prefs = await SharedPreferences.getInstance();
    final String? login_user = prefs.getString('user');
    final int? branch_id = prefs.getInt('branch_id');
    final String? pos_user = prefs.getString('pos_pin_user');
    Map logInUser = json.decode(login_user!);
    Map userObject = json.decode(pos_user!);
    print('settlement id: ${this.localSettlementId}');
    for (int j = 0; j < paymentList.length; j++) {
      SettlementLinkPayment object = SettlementLinkPayment(
          settlement_link_payment_id: 0,
          settlement_link_payment_key: '',
          company_id: logInUser['company_id'].toString(),
          branch_id: branch_id.toString(),
          settlement_sqlite_id: localSettlementId,
          settlement_key: settlementKey,
          total_bill: paymentList[j].total_bill.toString(),
          total_sales: paymentList[j].totalAmount.toStringAsFixed(2),
          payment_link_company_id:
              paymentList[j].payment_link_company_id.toString(),
          status: 0,
          sync_status: 0,
          created_at: dateTime,
          updated_at: '',
          soft_delete: '');

      SettlementLinkPayment data =
          await PosDatabase.instance.insertSqliteSettlementLinkPayment(object);
      SettlementLinkPayment updatedData =
          await insertSettlementLinkPaymentKey(data, dateTime);
      _value.add(jsonEncode(updatedData));
    }
    settlement_link_payment_value = _value.toString();
    //syncSettlementLinkPaymentToCloud(_value.toString());
  }

  // syncSettlementLinkPaymentToCloud(String value) async {
  //   bool _hasInternetAccess = await Domain().isHostReachable();
  //   if (_hasInternetAccess) {
  //     Map settlementResponse = await Domain().SyncSettlementLinkPaymentToCloud(value);
  //     if (settlementResponse['status'] == '1') {
  //       List responseJson = settlementResponse['data'];
  //       for (int i = 0; i < responseJson.length; i++) {
  //         int syncUpdated = await PosDatabase.instance.updateSettlementLinkPaymentSyncStatusFromCloud(responseJson[i]['settlement_link_payment_key']);
  //       }
  //     }
  //   }
  // }

  preload() async {
    printerList = widget.printerList;
    await getAllTodaySalesOverview();
    await readPaymentLinkCompany();
    // DateTime _startDate = DateTime.parse(widget.cashRecordList[0].created_at!);
    // String currentStDate = new DateFormat("yyyy-MM-dd 00:00:00").format(_startDate);
    // await getAllPaidOrder(currentStDate);
    // await getRefund(currentStDate);
    // await getAllPaidOrderPromotionDetail(currentStDate);
    // await getAllCancelOrderDetail(currentStDate);
    // await getBranchTaxes(currentStDate);
    // await readAllPrinters();
    setState(() {
      _isLoaded = true;
    });
  }

  getAllTodaySalesOverview() async {
    List<Order> orderData =
        await PosDatabase.instance.readAllNotSettlementPaidOrder();
    List<Order> refundData =
        await PosDatabase.instance.readAllNotSettlementRefundedOrder();
    List<OrderTaxDetail> orderTax =
        await PosDatabase.instance.readAllNotSettlementOrderTaxDetail();
    List<OrderPromotionDetail> orderPromotion =
        await PosDatabase.instance.readAllNotSettlementOrderPromotionDetail();
    // List<OrderDetailCancel> orderCancelData =
    //     await PosDatabase.instance.readAllNotSettlementOrderDetailCancel();
    OrderDetailCancel? cancelItemQty = await PosDatabase.instance.sumAllNotSettlementCancelItemQuantity();
    if (orderData.isNotEmpty) {
      this.orderList = orderData;
      this.totalBill = orderData.length;
      this.totalSales = orderData[0].gross_sales!;
    }
    if (refundData.isNotEmpty) {
      this.totalRefundBill = refundData.length;
      this.totalRefundAmount = refundData[0].gross_sales!;
    }
    if (orderTax.isNotEmpty) {
      this.totalTax = orderTax[0].total_tax_amount!;
    }
    if (orderPromotion.isNotEmpty) {
      this.totalPromotionAmount = orderPromotion[0].total_promotion_amount!;
    }
    if (cancelItemQty!.total_item != null) {
      this.totalCancelItem = int.parse(cancelItemQty.total_item.toString());
    }
    print('order promo: ${this.totalPromotionAmount}');
  }

  readPaymentLinkCompany() async {
    final prefs = await SharedPreferences.getInstance();
    final String? user = prefs.getString('user');
    Map userObject = json.decode(user!);
    List<PaymentLinkCompany> data = await PosDatabase.instance.readAllPaymentLinkCompanyWithDeleted(userObject['company_id']);
    if (data.isNotEmpty) {
      paymentList = data;
      for (int j = 0; j < paymentList.length; j++) {
        for (int i = 0; i < orderList.length; i++) {
          if (orderList[i].payment_status != 2) {
            if (paymentList[j].payment_link_company_id == int.parse(orderList[i].payment_link_company_id!)) {
              paymentList[j].total_bill++;
              paymentList[j].totalAmount += double.parse(orderList[i].final_amount!);
            }
          }
        }
      }
    }
  }

  getAllPaidOrder(String currentStDate) async {
    ReportObject object = await ReportObject().getAllPaidOrder(
        currentStDate: currentStDate, currentEdDate: currentEdDate);
    dateOrderList = object.dateOrderList!;
    totalSales = object.totalSales!;
  }

  getRefund(String currentStDate) async {
    ReportObject object = await ReportObject().getAllRefundOrder(
        currentStDate: currentStDate, currentEdDate: currentEdDate);
    dateRefundList = object.dateRefundOrderList!;
    totalRefundAmount = object.totalRefundAmount!;
  }

  getAllPaidOrderPromotionDetail(String currentStDate) async {
    ReportObject object = await ReportObject().getAllPaidOrderPromotionDetail(
        currentStDate: currentStDate, currentEdDate: currentEdDate);
    datePromotionDetail = object.datePromotionDetail!;
    totalPromotionAmount = object.totalPromotionAmount!;
  }

  getAllCancelOrderDetail(String currentStDate) async {
    ReportObject object = await ReportObject().getTotalCancelledItem(
        currentStDate: currentStDate, currentEdDate: currentEdDate);
    dateOrderDetailCancel = object.dateOrderDetailCancelList!;
    print('order detail cancel: ${dateOrderDetailCancel[0].total_item}');
    //ateOrderDetail = object.dateOrderDetail!;
  }

  getBranchTaxes(String currentStDate) async {
    ReportObject object = await ReportObject().getAllPaidOrderTaxDetail(
        currentStDate: currentStDate, currentEdDate: currentEdDate);
    dateTaxList = object.dateTaxDetail!;
    //totalTax = dateTaxList[0].total_tax_amount!;
    for (int i = 0; i < dateTaxList.length; i++) {
      totalTax = totalTax + dateTaxList[i].total_tax_amount!;
    }
  }

  readAllPrinters() async {
    printerList = await PrintReceipt().readAllPrinters();
  }

  syncAllToCloud() async {
    try {
      if (mainSyncToCloud.count == 0) {
        mainSyncToCloud.count == 1;
        final prefs = await SharedPreferences.getInstance();
        final int? device_id = prefs.getInt('device_id');
        final String? login_value = prefs.getString('login_value');
        Map data = await Domain().syncLocalUpdateToCloud(
            device_id: device_id.toString(),
            value: login_value,
            settlement_value: this.settlement_value,
            settlement_link_payment_value: this.settlement_link_payment_value,
            order_value: this.order_value,
            order_detail_cancel_value: this.order_cancel_value,
            cash_record_value: this.cash_record_value);
        if (data['status'] == '1') {
          List responseJson = data['data'];
          for (int i = 0; i < responseJson.length; i++) {
            switch (responseJson[i]['table_name']) {
              case 'tb_settlement':
                {
                  await PosDatabase.instance
                      .updateSettlementSyncStatusFromCloud(
                          responseJson[i]['settlement_key']);
                }
                break;
              case 'tb_settlement_link_payment':
                {
                  await PosDatabase.instance
                      .updateSettlementLinkPaymentSyncStatusFromCloud(
                          responseJson[i]['settlement_link_payment_key']);
                }
                break;
              case 'tb_order':
                {
                  await PosDatabase.instance.updateOrderSyncStatusFromCloud(
                      responseJson[i]['order_key']);
                }
                break;
              case 'tb_order_detail_cancel':
                {
                  await PosDatabase.instance
                      .updateOrderDetailCancelSyncStatusFromCloud(
                          responseJson[i]['order_detail_cancel_key']);
                }
                break;
              case 'tb_cash_record':
                {
                  await PosDatabase.instance
                      .updateCashRecordSyncStatusFromCloud(
                          responseJson[i]['cash_record_key']);
                }
                break;
              default:
                return;
            }
          }
          mainSyncToCloud.resetCount();
        } else if (data['status'] == '7') {
          mainSyncToCloud.resetCount();
          this.isLogOut = true;
        } else if (data['status'] == '8') {
          print('settlement sync timeout');
          mainSyncToCloud.resetCount();
          throw TimeoutException("Timeout");
        } else {
          mainSyncToCloud.resetCount();
        }
      }
    } catch (e) {
      mainSyncToCloud.resetCount();
    }
  }
}
