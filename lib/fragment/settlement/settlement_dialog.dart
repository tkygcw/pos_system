import 'dart:convert';
import 'dart:typed_data';

import 'package:esc_pos_printer/esc_pos_printer.dart';
import 'package:esc_pos_utils/esc_pos_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_usb_printer/flutter_usb_printer.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';
import 'package:intl/intl.dart';
import 'package:pos_system/notifier/connectivity_change_notifier.dart';
import 'package:pos_system/object/order_detail.dart';
import 'package:pos_system/object/order_detail_cancel.dart';
import 'package:pos_system/object/order_promotion_detail.dart';
import 'package:pos_system/object/print_receipt.dart';
import 'package:pos_system/object/refund.dart';
import 'package:pos_system/object/settlement.dart';
import 'package:pos_system/object/settlement_link_payment.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:crypto/crypto.dart';

import '../../database/domain.dart';
import '../../database/pos_database.dart';
import '../../notifier/theme_color.dart';
import '../../object/branch_link_tax.dart';
import '../../object/cash_record.dart';
import '../../object/order.dart';
import '../../object/order_tax_detail.dart';
import '../../object/payment_link_company.dart';
import '../../object/printer.dart';
import '../../object/printer_link_category.dart';
import '../../object/receipt_layout.dart';
import '../../object/report_class.dart';
import '../../object/user.dart';
import '../../page/loading_dialog.dart';
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
  String currentEdDate = new DateFormat("yyyy-MM-dd 00:00:00").format(DateTime.now());
  double totalSales = 0.0, totalRefundAmount = 0.0, totalPromotionAmount = 0.0, totalTax = 0.0;
  List<Order> dateOrderList = [], dateRefundList = [];
  List<OrderPromotionDetail> datePromotionDetail = [];
  List<OrderDetailCancel> dateOrderDetailCancel = [];
  List<OrderTaxDetail> dateTaxList = [];
  List<PaymentLinkCompany> paymentList = [];
  List<Printer> printerList = [];
  String localSettlementId = '', settlementKey = '';
  bool _submitted = false;
  bool _isLoaded = false;

  @override
  void initState() {
    super.initState();
    print('sub string: ${widget.cashRecordList[0].created_at!.substring(0, 10)}');
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

  void _submit(BuildContext context, ConnectivityChangeNotifier connectivity) async {
    setState(() => _submitted = true);
    if (errorPassword == null) {
      await readAdminData(adminPosPinController.text, connectivity);
      Navigator.of(context).pop();
      widget.callBack();
      return;
    }
  }

  closeDialog(BuildContext context) {
    return Navigator.of(context).pop(true);
  }
  Future showSecondDialog(BuildContext context, ThemeColor color, ConnectivityChangeNotifier connectivity) {
    return showDialog(
      barrierDismissible: false,
      context: context,
      builder: (BuildContext context) => Center(
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.manual,
          child: AlertDialog(
            title: Text('Enter Admin PIN'),
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
                },
              ),
              TextButton(
                child: Text('${AppLocalizations.of(context)?.translate('yes')}'),
                onPressed: () async {
                  if(_isLoaded){
                    _submit(context, connectivity);
                  }
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
      return Consumer<ConnectivityChangeNotifier>(builder: (context, ConnectivityChangeNotifier connectivity, child) {
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
                await showSecondDialog(context, color, connectivity);
                closeDialog(context);
              },
            )
          ],
        );
      });
    });
  }

/*
  ----------------DB Query part------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
*/

  readAdminData(String pin, ConnectivityChangeNotifier connectivity) async {
    try {
      String dateTime = dateFormat.format(DateTime.now());
      List<User> userData = await PosDatabase.instance.readSpecificUserWithRole(pin);
      if (userData.length > 0) {
        List<Settlement> settlementData = await PosDatabase.instance.readAllSettlement();
        if(settlementData.isNotEmpty){
          if(widget.cashRecordList[0].created_at!.substring(0, 10) != settlementData[0].created_at!.substring(0, 10)){
            //create settlement
            await createSettlement();
            createSettlementLinkPayment();
            //update all today cash record settlement date
            await updateAllCashRecordSettlement(dateTime, connectivity);
            //print settlement list
            await PrintReceipt().printSettlementList(printerList, dateTime, context);
          } else {
            //update settlement
            updateSettlement(settlementData[0].settlement_sqlite_id!);
            updateSettlementLinkPayment();
            //update all today cash record settlement date
            await updateAllCashRecordSettlement(dateTime, connectivity);
            //print settlement list
            await PrintReceipt().printSettlementList(printerList, dateTime, context);
          }
        } else {
          //create settlement
          await createSettlement();
          await createSettlementLinkPayment();
          //update all today cash record settlement date
          await updateAllCashRecordSettlement(dateTime, connectivity);
          //print settlement list
          await PrintReceipt().printSettlementList(printerList, dateTime, context);
        }
      } else {
        Fluttertoast.showToast(
            backgroundColor: Color(0xFFFF0000), msg: "Password incorrect");
      }
    } catch (e) {
      print('user checking error ${e}');
    }
  }

  generateSettlementKey(Settlement settlement) async  {
    final prefs = await SharedPreferences.getInstance();
    final int? device_id = prefs.getInt('device_id');
    var bytes  = settlement.created_at!.replaceAll(new RegExp(r'[^0-9]'),'') + settlement.settlement_sqlite_id.toString() + device_id.toString();
    print('bytes: ${bytes}');
    return md5.convert(utf8.encode(bytes)).toString();
  }

  insertSettlementKey(Settlement settlement, String dateTime) async {
    String? _key;
    Settlement? _data;
    _key = await generateSettlementKey(settlement);
    if(_key != null){
      Settlement object = Settlement(
        settlement_key: _key,
        sync_status: 0,
        updated_at: dateTime,
        settlement_sqlite_id: settlement.settlement_sqlite_id
      );

      int updatedData = await PosDatabase.instance.updateSettlementUniqueKey(object);
      if(updatedData == 1){
        Settlement data = await PosDatabase.instance.readSpecificSettlementByLocalId(settlement.settlement_sqlite_id!);
        _data = data;
      }
    }
    return _data;
  }

  createSettlement() async {
    List<String> value = [];
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
      total_bill: dateOrderList.length.toString(),
      total_sales: this.totalSales.toStringAsFixed(2),
      total_refund_bill: dateRefundList.length.toString(),
      total_refund_amount: totalRefundAmount.toStringAsFixed(2),
      total_discount: totalPromotionAmount.toStringAsFixed(2),
      total_cancellation: dateOrderDetailCancel[0].total_item.toString(),
      total_tax: totalTax.toStringAsFixed(2),
      settlement_by_user_id: userObject['user_id'].toString(),
      settlement_by: userObject['name'].toString(),
      status: 0,
      sync_status: 0,
      created_at: dateTime,
      updated_at: '',
      soft_delete: ''
    );
    Settlement data = await PosDatabase.instance.insertSqliteSettlement(object);
    Settlement updatedData = await insertSettlementKey(data, dateTime);
    localSettlementId = updatedData.settlement_sqlite_id.toString();
    settlementKey = updatedData.settlement_key!;
    value.add(jsonEncode(updatedData));
    print('value: ${value.toString()}');
    syncSettlementToCloud(value.toString());
  }

  syncSettlementToCloud(String value) async {
    bool _hasInternetAccess = await Domain().isHostReachable();
    if (_hasInternetAccess) {
      Map settlementResponse = await Domain().SyncSettlementToCloud(value);
      if (settlementResponse['status'] == '1') {
        List responseJson = settlementResponse['data'];
        for (int i = 0; i < responseJson.length; i++) {
          int syncUpdated = await PosDatabase.instance.updateSettlementSyncStatusFromCloud(responseJson[i]['settlement_key']);
        }
      }
    }
  }

  updateSettlement(int settlement_sqlite_id) async {
    List<String> value = [];
    DateFormat dateFormat = DateFormat("yyyy-MM-dd HH:mm:ss");
    String dateTime = dateFormat.format(DateTime.now());
    final prefs = await SharedPreferences.getInstance();
    final String? pos_user = prefs.getString('pos_pin_user');
    Map userObject = json.decode(pos_user!);

    Settlement checkData = await PosDatabase.instance.readSpecificSettlementByLocalId(settlement_sqlite_id);
    Settlement object = Settlement(
        settlement_sqlite_id: settlement_sqlite_id,
        total_bill: dateOrderList.length.toString(),
        total_sales: this.totalSales.toStringAsFixed(2),
        total_refund_bill: dateRefundList.length.toString(),
        total_refund_amount: totalRefundAmount.toStringAsFixed(2),
        total_discount: totalPromotionAmount.toStringAsFixed(2),
        total_cancellation: dateOrderDetailCancel[0].total_item.toString(),
        total_tax: totalTax.toStringAsFixed(2),
        settlement_by_user_id: userObject['user_id'].toString(),
        settlement_by: userObject['name'].toString(),
        status: 0,
        sync_status: checkData.sync_status == 0 ? 0 : 2,
        updated_at: dateTime,
    );

    int data = await PosDatabase.instance.updateSettlement(object);
    if(data == 1){
      Settlement updatedData = await PosDatabase.instance.readSpecificSettlementByLocalId(settlement_sqlite_id);
      value.add(jsonEncode(updatedData));
    }
    //sync to cloud
    syncSettlementToCloud(value.toString());
  }

  updateAllCashRecordSettlement(String dateTime, ConnectivityChangeNotifier connectivity) async {
    List<String> _value = [];
    for(int i = 0; i < widget.cashRecordList.length; i++){
      CashRecord cashRecord = CashRecord(
          settlement_date: dateTime,
          sync_status: widget.cashRecordList[i].sync_status == 0 ? 0 : 2,
          updated_at: dateTime,
          cash_record_sqlite_id:  widget.cashRecordList[i].cash_record_sqlite_id);
      int data = await PosDatabase.instance.updateCashRecord(cashRecord);
      if(data == 1 && connectivity.isConnect) {
        //collect all not sync local create/update data
        CashRecord _record = await PosDatabase.instance.readSpecificCashRecord(cashRecord.cash_record_sqlite_id!);
        if(_record.sync_status != 1){
          _value.add(jsonEncode(_record));
        }
      }
    }
    //sync to cloud
    await syncSettlementCashRecordToCloud(_value.toString());
  }

  syncSettlementCashRecordToCloud(String value) async {
    bool _hasInternetAccess = await Domain().isHostReachable();
    if(_hasInternetAccess){
      Map response = await Domain().SyncCashRecordToCloud(value);
      if (response['status'] == '1') {
        List responseJson = response['data'];
        for (var i = 0; i < responseJson.length; i++) {
          int cashRecordData = await PosDatabase.instance.updateCashRecordSyncStatusFromCloud(responseJson[i]['cash_record_key']);
        }
      }
    }
  }

  generateSettlementLinkKey(SettlementLinkPayment settlementLinkPayment) async  {
    final prefs = await SharedPreferences.getInstance();
    final int? device_id = prefs.getInt('device_id');
    var bytes  = settlementLinkPayment.created_at!.replaceAll(new RegExp(r'[^0-9]'),'') +
        settlementLinkPayment.settlement_link_payment_sqlite_id.toString() + device_id.toString();
    print('bytes: ${bytes}');
    return md5.convert(utf8.encode(bytes)).toString();
  }

  insertSettlementLinkPaymentKey(SettlementLinkPayment settlementLinkPayment, String dateTime) async {
    String? _key;
    SettlementLinkPayment? _data;
    _key = await generateSettlementLinkKey(settlementLinkPayment);
    if(_key != null){
      SettlementLinkPayment object = SettlementLinkPayment(
        settlement_link_payment_key: _key,
        sync_status: 0,
        updated_at: dateTime,
        settlement_link_payment_sqlite_id: settlementLinkPayment.settlement_link_payment_sqlite_id
      );

      int updatedData = await PosDatabase.instance.updateSettlementLinkPaymentUniqueKey(object);
      if(updatedData == 1){
        SettlementLinkPayment data = await PosDatabase.instance.readSpecificSettlementLinkPaymentByLocalId(settlementLinkPayment.settlement_link_payment_sqlite_id!);
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
    for(int j = 0 ; j < paymentList.length; j++) {
      SettlementLinkPayment object = SettlementLinkPayment(
          settlement_link_payment_id: 0,
          settlement_link_payment_key: '',
          company_id: logInUser['company_id'].toString(),
          branch_id: branch_id.toString(),
          settlement_sqlite_id: localSettlementId,
          settlement_key: settlementKey,
          total_bill: paymentList[j].total_bill.toString(),
          total_sales: paymentList[j].totalAmount.toStringAsFixed(2),
          payment_link_company_id: paymentList[j].payment_link_company_id.toString(),
          status: 0,
          sync_status: 0,
          created_at: dateTime,
          updated_at: '',
          soft_delete: ''
      );

      SettlementLinkPayment data = await PosDatabase.instance.insertSqliteSettlementLinkPayment(object);
      SettlementLinkPayment updatedData = await insertSettlementLinkPaymentKey(data, dateTime);
      _value.add(jsonEncode(updatedData));
    }
    syncSettlementLinkPaymentToCloud(_value.toString());
  }

  syncSettlementLinkPaymentToCloud(String value) async {
    bool _hasInternetAccess = await Domain().isHostReachable();
    if (_hasInternetAccess) {
      Map settlementResponse = await Domain().SyncSettlementLinkPaymentToCloud(value);
      if (settlementResponse['status'] == '1') {
        List responseJson = settlementResponse['data'];
        for (int i = 0; i < responseJson.length; i++) {
          int syncUpdated = await PosDatabase.instance.updateSettlementLinkPaymentSyncStatusFromCloud(responseJson[i]['settlement_link_payment_key']);
        }
      }
    }
  }

  updateSettlementLinkPayment() async {
    List<String> _value = [];
    DateFormat dateFormat = DateFormat("yyyy-MM-dd HH:mm:ss");
    String dateTime = dateFormat.format(DateTime.now());

    for(int j = 0 ; j < paymentList.length; j++) {
      SettlementLinkPayment checkData = await PosDatabase.instance.readSpecificSettlementLinkPaymentByLocalId(paymentList[j].payment_link_company_id!);
      SettlementLinkPayment object = SettlementLinkPayment(
          total_bill: paymentList[j].total_bill.toString(),
          total_sales: paymentList[j].totalAmount.toStringAsFixed(2),
          status: 0,
          sync_status: checkData.sync_status == 0 ? 0 : 2,
          updated_at: dateTime,
          settlement_link_payment_sqlite_id: checkData.settlement_link_payment_sqlite_id
      );
      int status = await PosDatabase.instance.updateSettlementLinkPayment(object);
      if(status == 1){
        SettlementLinkPayment updatedData = await PosDatabase.instance.readSpecificSettlementLinkPaymentByPaymentLinkCompany(paymentList[j].payment_link_company_id!);
        _value.add(jsonEncode(updatedData));
      }
      print('updated value: ${_value.toString()}');
      // print('value: ${_value.toString()}');
      syncSettlementLinkPaymentToCloud(_value.toString());
    }
  }

  preload() async {
    DateTime _startDate = DateTime.parse(widget.cashRecordList[0].created_at!);
    String currentStDate = new DateFormat("yyyy-MM-dd 00:00:00").format(_startDate);
    await getAllPaidOrder(currentStDate);
    await getRefund(currentStDate);
    await getAllPaidOrderPromotionDetail(currentStDate);
    await getAllCancelOrderDetail(currentStDate);
    await readPaymentLinkCompany();
    await getBranchTaxes(currentStDate);
    await readAllPrinters();
    setState(() {
      _isLoaded = true;
    });
  }

  readPaymentLinkCompany() async {
    final prefs = await SharedPreferences.getInstance();
    final String? user = prefs.getString('user');
    Map userObject = json.decode(user!);
    List<PaymentLinkCompany> data = await PosDatabase.instance.readAllPaymentLinkCompany(userObject['company_id']);
    if (data.isNotEmpty) {
      paymentList = data;
      for(int j = 0 ; j < paymentList.length; j++){
        for(int i = 0; i < dateOrderList.length; i++){
          if(dateOrderList[i].payment_status != 2){
            if(paymentList[j].payment_link_company_id == int.parse(dateOrderList[i].payment_link_company_id!)){
              paymentList[j].total_bill ++;
              paymentList[j].totalAmount += double.parse(dateOrderList[i].final_amount!);
            }
          }
        }
      }
    }
  }

  getAllPaidOrder(String currentStDate) async {
    ReportObject object = await ReportObject().getAllPaidOrder(currentStDate: currentStDate, currentEdDate: currentEdDate);
    dateOrderList = object.dateOrderList!;
    totalSales = object.totalSales!;
  }

  getRefund(String currentStDate) async {
    ReportObject object = await ReportObject().getAllRefundOrder(currentStDate: currentStDate, currentEdDate: currentEdDate);
    dateRefundList = object.dateRefundOrderList!;
    totalRefundAmount = object.totalRefundAmount!;
  }

  getAllPaidOrderPromotionDetail(String currentStDate) async {
    ReportObject object = await ReportObject().getAllPaidOrderPromotionDetail(currentStDate: currentStDate, currentEdDate: currentEdDate);
    datePromotionDetail = object.datePromotionDetail!;
    totalPromotionAmount = object.totalPromotionAmount!;
  }

  getAllCancelOrderDetail(String currentStDate) async {
    ReportObject object = await ReportObject().getTotalCancelledItem(currentStDate: currentStDate, currentEdDate: currentEdDate);
    dateOrderDetailCancel = object.dateOrderDetailCancelList!;
    //ateOrderDetail = object.dateOrderDetail!;
  }

  getBranchTaxes(String currentStDate) async {
    ReportObject object = await ReportObject().getAllPaidOrderTaxDetail(currentStDate: currentStDate, currentEdDate: currentEdDate);
    dateTaxList = object.dateTaxDetail!;
    //totalTax = dateTaxList[0].total_tax_amount!;
    for(int i = 0; i < dateTaxList.length; i++){
      totalTax = totalTax + dateTaxList[i].total_tax_amount!;
    }
  }

  readAllPrinters() async {
    printerList = await PrintReceipt().readAllPrinters();
  }

}
