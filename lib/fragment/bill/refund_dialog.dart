import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';
import 'package:pos_system/object/refund.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:crypto/crypto.dart';

import '../../database/domain.dart';
import '../../database/pos_database.dart';
import '../../notifier/theme_color.dart';
import '../../object/cash_record.dart';
import '../../object/order.dart';
import '../../object/order_cache.dart';
import '../../object/user.dart';
import '../../translation/AppLocalizations.dart';

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
  String refundKey = '';
  bool _submitted = false;

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
      await readAdminData(adminPosPinController.text);
      Navigator.of(context).pop();
      Navigator.of(context).pop();
      return;
    }
  }

  Future showSecondDialog(BuildContext context, ThemeColor color) {
    return showDialog(
      barrierDismissible: false,
      context: context,
      builder: (BuildContext context) => Center(
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.manual,
          child: AlertDialog(
            title: Text('Enter User PIN'),
            content: SizedBox(
              height: 100.0,
              width: 350.0,
              child: ValueListenableBuilder(
                  valueListenable: adminPosPinController,
                  builder: (context, TextEditingValue value, __) {
                    return Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: TextField(
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
                onPressed: () {
                  Navigator.of(context).pop();
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
        ),
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeColor>(builder: (context, ThemeColor color, child) {
      return AlertDialog(
        title: Text('Confirm refund this Order?'),
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
            onPressed: () async {
              await showSecondDialog(context, color);
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
        print('user found ${userData.name}');
        //create refund record
        await createRefund(userData);
        updateOrderPaymentStatus();
        createRefundedCashRecord(userData);
        //print refund list
        //await _printSettlementList(dateTime);
        widget.callBack();
      } else {
        Fluttertoast.showToast(
            backgroundColor: Color(0xFFFF0000), msg: "PIN incorrect, User not found");
      }
    } catch (e) {
      print('delete error ${e}');
    }
  }

  generateRefundKey(Refund refund) async  {
    final prefs = await SharedPreferences.getInstance();
    final int? device_id = prefs.getInt('device_id');
    var bytes  = refund.created_at!.replaceAll(new RegExp(r'[^0-9]'),'') + refund.refund_sqlite_id.toString() + device_id.toString();
    return md5.convert(utf8.encode(bytes)).toString();
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
    Refund updatedData = await insertRefundKey(data, dateTime);
    refundKey = updatedData.refund_key!;
    _value.add(jsonEncode(updatedData));

  }

  syncTableUseDetailToCloud(String value) async {
    //check is host reachable
    bool _hasInternetAccess = await Domain().isHostReachable();
    if (_hasInternetAccess) {
      // Map response = await Domain().SyncTableUseDetailToCloud(value);
      // if (response['status'] == '1') {
      //   List responseJson = response['data'];
      //   for (int i = 0; i < responseJson.length; i++) {
      //     int updateStatus = await PosDatabase.instance.updateTableUseDetailSyncStatusFromCloud(responseJson[i]['table_use_detail_key']);
      //   }
      // }
    }
  }

  updateOrderPaymentStatus() async {
    List<String> _value = [];
    String dateTime = dateFormat.format(DateTime.now());
    Order checkData = await PosDatabase.instance.readSpecificOrder(widget.order.order_sqlite_id!);
    Order _orderObject = Order(
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
    print('updated order value: ${_value.toString()}');
  }

  generateCashRecordKey(CashRecord cashRecord) async {
    final prefs = await SharedPreferences.getInstance();
    final int? device_id = prefs.getInt('device_id');
    var bytes = cashRecord.created_at!.replaceAll(new RegExp(r'[^0-9]'), '') +
        cashRecord.cash_record_sqlite_id.toString() +
        device_id.toString();
    return md5.convert(utf8.encode(bytes)).toString();
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
        settlement_date: '',
        sync_status: 0,
        created_at: dateTime,
        updated_at: '',
        soft_delete: '');
    CashRecord data = await PosDatabase.instance.insertSqliteCashRecord(cashRecordObject);
    CashRecord updatedData = await insertCashRecordKey(data, dateTime);
    _value.add(jsonEncode(updatedData));
    print('cash record: ${_value.toString()}');
  }

}
