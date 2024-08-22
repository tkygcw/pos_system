import 'dart:async';
import 'dart:convert';

import 'package:f_logs/model/flog/flog.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';
import 'package:pos_system/object/refund.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:crypto/crypto.dart';

import '../../database/domain.dart';
import '../../database/pos_database.dart';
import '../../main.dart';
import '../../notifier/theme_color.dart';
import '../../object/cash_record.dart';
import '../../object/order.dart';
import '../../object/order_cache.dart';
import '../../object/user.dart';
import '../../translation/AppLocalizations.dart';
import '../../utils/Utils.dart';
import '../logout_dialog.dart';

class RefundDialog extends StatefulWidget {
  final Order order;
  final List<OrderCache> orderCacheList;
  final Function() callBack;
  const RefundDialog({Key? key, required this.callBack, required this.order, required this.orderCacheList}) : super(key: key);

  @override
  State<RefundDialog> createState() => _RefundDialogState();
}

class _RefundDialogState extends State<RefundDialog> {
  DateFormat dateFormat = DateFormat("yyyy-MM-dd HH:mm:ss");
  final adminPosPinController = TextEditingController();
  String refundLocalId = '';
  String refundKey = '';
  String? refund_value, order_value, cash_record_value;
  bool _submitted = false;
  bool isButtonDisabled = false, isLogOut = false;


  String? get errorPassword {
    final text = adminPosPinController.value.text;
    if (text.isEmpty) {
      return 'password_required';
    }
    return null;
  }

  void _submit(BuildContext context) async {
    setState(() => _submitted = true);
    if (errorPassword == null) {
      // Disable the button after it has been pressed
      setState(() {
        isButtonDisabled = true;
      });
      await readAdminData(adminPosPinController.text);
      print("button disable");
      setState(() {
        isButtonDisabled = false;
      });
    } else {
      setState(() {
        isButtonDisabled = false;
      });
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

  Future showSecondDialog(BuildContext context, ThemeColor color) {
    return showDialog(
      barrierDismissible: false,
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(builder: (context, StateSetter setState){
          return Center(
            child: SingleChildScrollView(
              child: AlertDialog(
                title: Text(AppLocalizations.of(context)!.translate('enter_admin_pin')),
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
                            onSubmitted: (input){
                              _submit(context);
                            },
                            obscureText: true,
                            inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9]'))],
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
                ),
                actions: <Widget>[
                  TextButton(
                    child: Text('${AppLocalizations.of(context)?.translate('close')}'),
                    onPressed: isButtonDisabled ? null : () {
                      // Disable the button after it has been pressed
                      setState(() {
                        isButtonDisabled = true;
                      });
                      Navigator.of(context).pop();
                      Navigator.of(context).pop();
                    },
                  ),
                  TextButton(
                    child: Text('${AppLocalizations.of(context)?.translate('yes')}'),
                    onPressed: isButtonDisabled ? null : () async {
                      _submit(context);
                    },
                  ),
                ],
              ),
            ),
          );
        });
      }
    );
  }


  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeColor>(builder: (context, ThemeColor color, child) {
      return AlertDialog(
        title: Text(AppLocalizations.of(context)!.translate('refund_desc')),
        content: Container(
          child: Text('${AppLocalizations.of(context)?.translate('refund_desc')}'),
        ),
        actions: [
          TextButton(
            child: Text('${AppLocalizations.of(context)?.translate('close')}'),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
          TextButton(
            child: Text('${AppLocalizations.of(context)?.translate('yes')}'),
            onPressed: () async  {
              // await showSecondDialog(context, color);
              final prefs = await SharedPreferences.getInstance();
              final String? pos_user = prefs.getString('pos_pin_user');
              Map<String, dynamic> userMap = json.decode(pos_user!);
              User userData = User.fromJson(userMap);
              if(userData.refund_permission != 1) {
                await showSecondDialog(context, color);
              } else {
                await callRefund(userData);
                Navigator.of(context).pop();
                Navigator.of(context).pop();
              }
            },
          ),
        ],
      );
    });
  }

  readAdminData(String pin) async {
    try {
      User? userData = await PosDatabase.instance.readSpecificUserWithPin(pin);
      if (userData != null) {
        if(userData.refund_permission == 1){
          //create refund record
          await callRefund(userData);
          Navigator.of(context).pop(true);
          Navigator.of(context).pop(true);
          Navigator.of(context).pop(true);
        } else {
          Fluttertoast.showToast(
              backgroundColor: Color(0xFFFF0000), msg: AppLocalizations.of(context)!.translate('no_permission'));
        }
      } else {
        Fluttertoast.showToast(
            backgroundColor: Color(0xFFFF0000), msg: AppLocalizations.of(context)!.translate('user_not_found'));
      }
    } catch (e) {
      print('delete error ${e}');
    }
  }

  callRefund(userData) async {
    await createRefund(userData);
    await updateOrderPaymentStatus();
    await createRefundedCashRecord(userData);
    await syncAllToCloud();
    if(this.isLogOut == true){
      openLogOutDialog();
      return;
    }
    widget.callBack();
  }

  generateRefundKey(Refund refund) async  {
    final prefs = await SharedPreferences.getInstance();
    final int? device_id = prefs.getInt('device_id');
    var bytes  = refund.created_at!.replaceAll(new RegExp(r'[^0-9]'),'') + refund.refund_sqlite_id.toString() + device_id.toString();
    var md5Hash = md5.convert(utf8.encode(bytes));
    return Utils.shortHashString(hashCode: md5Hash);
  }

  insertRefundKey(Refund refund, String dateTime) async {
    Refund? _record;
    String? _key;
    _key = await generateRefundKey(refund);
    if(_key != null){
      Refund _refundObject = Refund(
          refund_key: _key,
          updated_at: dateTime,
          refund_sqlite_id: refund.refund_sqlite_id
      );
      int data = await PosDatabase.instance.updateRefundUniqueKey(_refundObject);
      if(data == 1){
        _record = await PosDatabase.instance.readAllRefundByLocalId(_refundObject.refund_sqlite_id!);
      }
    }
    return _record;
  }

  createRefund(User user) async {
    try{
      String dateTime = dateFormat.format(DateTime.now());
      final prefs = await SharedPreferences.getInstance();
      final int? branch_id = prefs.getInt('branch_id');
      final String? login_user = prefs.getString('user');
      List<String> _value = [];
      Map logInUser = json.decode(login_user!);

      Refund refundObject = Refund(
          refund_id: 0,
          refund_key: '',
          company_id: logInUser['company_id'].toString(),
          branch_id: branch_id.toString(),
          order_cache_sqlite_id: '',
          order_cache_key: '',
          order_sqlite_id: widget.order.order_sqlite_id.toString(),
          order_key: widget.order.order_key,
          refund_by: user.name,
          refund_by_user_id: user.user_id.toString(),
          bill_id: widget.order.generateOrderNumber(),
          sync_status: 0,
          created_at: dateTime,
          updated_at: '',
          soft_delete: ''
      );
      Refund data = await PosDatabase.instance.insertSqliteRefund(refundObject);
      refundLocalId = data.refund_sqlite_id.toString();
      Refund updatedData = await insertRefundKey(data, dateTime);
      refundKey = updatedData.refund_key!;
      _value.add(jsonEncode(updatedData));
      refund_value = _value.toString();
      //sync to cloud
      //syncRefundToCloud(_value.toString());
    } catch(e) {
      FLog.error(
        className: "refund_dialog",
        text: "createRefund error",
        exception: "$e",
      );
    }
  }

  // syncRefundToCloud(String value) async {
  //   //check is host reachable
  //   bool _hasInternetAccess = await Domain().isHostReachable();
  //   if (_hasInternetAccess) {
  //     Map response = await Domain().SyncRefundToCloud(value);
  //     if (response['status'] == '1') {
  //       List responseJson = response['data'];
  //       int updateStatus = await PosDatabase.instance.updateRefundSyncStatusFromCloud(responseJson[0]['refund_key']);
  //     }
  //   }
  // }

  updateOrderPaymentStatus() async {
    try{
      List<String> _value = [];
      String dateTime = dateFormat.format(DateTime.now());
      Order checkData = await PosDatabase.instance.readSpecificOrder(widget.order.order_sqlite_id!);
      Order _orderObject = Order(
          refund_sqlite_id: this.refundLocalId,
          refund_key: this.refundKey,
          sync_status: checkData.sync_status == 0 ? 0 : 2,
          updated_at: dateTime,
          order_sqlite_id: checkData.order_sqlite_id
      );
      int status = await PosDatabase.instance.updateOrderPaymentRefundStatus(_orderObject);
      if(status == 1){
        Order orderData = await PosDatabase.instance.readSpecificOrder(_orderObject.order_sqlite_id!);
        _value.add(jsonEncode(orderData));
      }
      order_value = _value.toString();
      //sync to cloud
      //syncUpdatedOrderToCloud(_value.toString());
    } catch(e){
      FLog.error(
        className: "refund_dialog",
        text: "updateOrderPaymentStatus error",
        exception: "$e",
      );
    }
  }

  // syncUpdatedOrderToCloud(String value) async {
  //   bool _hasInternetAccess = await Domain().isHostReachable();
  //   if (_hasInternetAccess) {
  //     Map data = await Domain().SyncOrderToCloud(value);
  //     if (data['status'] == '1') {
  //       List responseJson = data['data'];
  //       int orderData = await PosDatabase.instance.updateOrderSyncStatusFromCloud(responseJson[0]['order_key']);
  //     }
  //   }
  // }

  generateCashRecordKey(CashRecord cashRecord) async {
    final prefs = await SharedPreferences.getInstance();
    final int? device_id = prefs.getInt('device_id');
    var bytes = cashRecord.created_at!.replaceAll(new RegExp(r'[^0-9]'), '') +
        cashRecord.cash_record_sqlite_id.toString() +
        device_id.toString();
    var md5Hash = md5.convert(utf8.encode(bytes));
    return Utils.shortHashString(hashCode: md5Hash);
  }

  insertCashRecordKey(CashRecord cashRecord, String dateTime) async {
    CashRecord? _record;
    int _status = 0;
    String? _key;
    _key = await generateCashRecordKey(cashRecord);
    if (_key != null) {
      CashRecord cashRecordObject = CashRecord(
          cash_record_key: _key,
          updated_at: dateTime,
          cash_record_sqlite_id: cashRecord.cash_record_sqlite_id);
      int data = await PosDatabase.instance.updateCashRecordUniqueKey(cashRecordObject);
      if (data == 1) {
        _record =
        await PosDatabase.instance.readSpecificCashRecord(cashRecord.cash_record_sqlite_id!);
      }
    }
    return _record;
  }

  createRefundedCashRecord(User user) async {
    try {
      String dateTime = dateFormat.format(DateTime.now());
      final prefs = await SharedPreferences.getInstance();
      final int? branch_id = prefs.getInt('branch_id');
      final String? login_user = prefs.getString('user');
      List<String> _value = [];
      Map logInUser = json.decode(login_user!);

      CashRecord cashRecordObject = CashRecord(
          cash_record_id: 0,
          cash_record_key: '',
          company_id: logInUser['company_id'].toString(),
          branch_id: branch_id.toString(),
          remark: widget.order.generateOrderNumber(),
          amount: widget.order.final_amount,
          payment_name: '',
          payment_type_id: widget.order.payment_type,
          type: 4,
          user_id: user.user_id.toString(),
          settlement_key: '',
          settlement_date: '',
          sync_status: 0,
          created_at: dateTime,
          updated_at: '',
          soft_delete: '');
      CashRecord data = await PosDatabase.instance.insertSqliteCashRecord(cashRecordObject);
      CashRecord updatedData = await insertCashRecordKey(data, dateTime);
      _value.add(jsonEncode(updatedData));
      cash_record_value = _value.toString();
      //sync to cloud
      //syncCashRecordToCloud(_value.toString());
    } catch(e) {
      FLog.error(
        className: "refund_dialog",
        text: "createRefundedCashRecord error",
        exception: "$e",
      );
    }
  }

  // syncCashRecordToCloud(String value) async {
  //   bool _hasInternetAccess = await Domain().isHostReachable();
  //   if (_hasInternetAccess) {
  //     Map response = await Domain().SyncCashRecordToCloud(value);
  //     if (response['status'] == '1') {
  //       List responseJson = response['data'];
  //       for (var i = 0; i < responseJson.length; i++) {
  //         int cashRecordData = await PosDatabase.instance.updateCashRecordSyncStatusFromCloud(responseJson[0]['cash_record_key']);
  //       }
  //     }
  //   }
  // }

  syncAllToCloud() async {
    try{
      if(mainSyncToCloud.count == 0){
        mainSyncToCloud.count = 1;
        final prefs = await SharedPreferences.getInstance();
        final int? device_id = prefs.getInt('device_id');
        final String? login_value = prefs.getString('login_value');
        Map data = await Domain().syncLocalUpdateToCloud(
            device_id: device_id.toString(),
            value: login_value,
            refund_value: this.refund_value,
            order_value: this.order_value,
            cash_record_value: this.cash_record_value
        );
        if (data['status'] == '1') {
          List responseJson = data['data'];
          for (int i = 0; i < responseJson.length; i++) {
            switch(responseJson[i]['table_name']){
              case 'tb_refund': {
                await PosDatabase.instance.updateRefundSyncStatusFromCloud(responseJson[i]['refund_key']);
              }
              break;
              case 'tb_order': {
                await PosDatabase.instance.updateOrderSyncStatusFromCloud(responseJson[i]['order_key']);
              }
              break;
              case 'tb_cash_record': {
                await PosDatabase.instance.updateCashRecordSyncStatusFromCloud(responseJson[i]['cash_record_key']);
              }
              break;
              default:
                return;
            }
          }
          mainSyncToCloud.resetCount();
        } else if(data['status'] == '7'){
          mainSyncToCloud.resetCount();
          this.isLogOut = true;
        } else if (data['status'] == '8') {
          mainSyncToCloud.resetCount();
          print('refund timeout');
          throw TimeoutException("Time out");
        }else {
          mainSyncToCloud.resetCount();
        }
      }
    } catch(e){
      mainSyncToCloud.resetCount();
      FLog.error(
        className: "refund_dialog",
        text: "syncAllToCloud error",
        exception: "$e",
      );
    }
    // bool _hasInternetAccess = await Domain().isHostReachable();
    // if (_hasInternetAccess) {
    //
    // }
  }
}
