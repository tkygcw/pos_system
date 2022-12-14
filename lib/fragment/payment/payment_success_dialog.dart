import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_usb_printer/flutter_usb_printer.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';
import 'package:pos_system/notifier/cart_notifier.dart';
import 'package:pos_system/notifier/table_notifier.dart';
import 'package:pos_system/object/printer.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:crypto/crypto.dart';

import '../../database/domain.dart';
import '../../database/pos_database.dart';
import '../../notifier/theme_color.dart';
import '../../object/cash_record.dart';
import '../../object/order.dart';
import '../../object/order_cache.dart';
import '../../object/printer_link_category.dart';
import '../../object/receipt_layout.dart';
import '../../object/table.dart';
import '../../object/table_use.dart';
import '../../object/table_use_detail.dart';
import '../../translation/AppLocalizations.dart';

class PaymentSuccessDialog extends StatefulWidget {
  final List<String> orderCacheIdList;
  final List<PosTable> selectedTableList;
  final Function() callback;
  final String orderId;
  final String orderKey;
  final String dining_id;
  const PaymentSuccessDialog({Key? key, required this.orderId, required this.callback, required this.orderCacheIdList, required this.selectedTableList, required this.dining_id, required this.orderKey}) : super(key: key);

  @override
  State<PaymentSuccessDialog> createState() => _PaymentSuccessDialogState();
}

class _PaymentSuccessDialogState extends State<PaymentSuccessDialog> {
  DateFormat dateFormat = DateFormat("yyyy-MM-dd HH:mm:ss");
  List<Printer> printerList = [];
  FlutterUsbPrinter flutterUsbPrinter = FlutterUsbPrinter();


  closeDialog(BuildContext context) {
    return Navigator.of(context).pop(true);
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    callUpdateOrder();
    createCashRecord();
    readAllPrinters();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeColor>(builder: (context, ThemeColor color, child) {
      return Consumer<CartModel>(builder: (context, CartModel cartModel, child) {
          return Consumer<TableModel>(builder: (context, TableModel tableModel, child) {
              return WillPopScope(
                onWillPop: () async => false,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    if(constraints.maxWidth > 800) {
                      return AlertDialog(
                        title: Text('Payment success'),
                        content: Container(
                          width: MediaQuery.of(context).size.width / 3,
                          height: MediaQuery.of(context).size.height / 3,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: MediaQuery.of(context).size.height / 6,
                                child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                        primary: color.backgroundColor,
                                        padding: EdgeInsets.fromLTRB(0, 30, 0, 30)
                                    ),
                                    onPressed: () async {
                                      await _printReceiptList();
                                    },
                                    child: Text('Print receipt', style: TextStyle(fontSize: 18),)
                                ),
                              ),
                              SizedBox(height: 25),
                              Container(
                                width: MediaQuery.of(context).size.height / 6,
                                child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      primary: color.buttonColor,
                                    ),
                                    onPressed: (){
                                      closeDialog(context);
                                      tableModel.changeContent(true);
                                      cartModel.initialLoad();
                                      widget.callback();
                                    },
                                    child: Text('${AppLocalizations.of(context)?.translate('close')}')
                                ),
                              )
                            ],
                          ),
                        ),
                      );
                    } else {
                      //Mobile layout
                      return AlertDialog(
                        title: Text('Payment success'),
                        content: Container(
                          width: MediaQuery.of(context).size.width / 2,
                          height: 150,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                        primary: color.backgroundColor,
                                    ),
                                    onPressed: () async {
                                      await _printReceiptList();
                                    },
                                    child: Text('Print receipt', style: TextStyle(fontSize: 15),)
                                ),
                              ),
                              //SizedBox(height: 25),
                              Container(
                                child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      primary: color.buttonColor,
                                    ),
                                    onPressed: (){
                                      closeDialog(context);
                                      tableModel.changeContent(true);
                                      cartModel.initialLoad();
                                      widget.callback();
                                    },
                                    child: Text('${AppLocalizations.of(context)?.translate('close')}')
                                ),
                              )
                            ],
                          ),
                        ),
                      );
                    }
                  }
                ),
              );
            }
          );
        }
      );
    });
  }

  callUpdateOrder() async {
    await updateOrder();
    if(widget.dining_id == '1'){
      await deleteCurrentTableUseDetail();
      await deleteCurrentTableUseId();
      await updatePosTableStatus(0);
      await updatePosTableTableUseDetailKey();
    }
    await updateOrderCache();
    await deleteOrderCache();

  }

  updateOrder() async {
    String dateTime = dateFormat.format(DateTime.now());
    Order orderObject = Order(
        updated_at: dateTime,
        order_sqlite_id: int.parse(widget.orderId)
    );

    int data = await PosDatabase.instance.updateOrderPaymentStatus(orderObject);
  }

  deleteCurrentTableUseDetail() async {
    String dateTime = dateFormat.format(DateTime.now());

    try{
      if(widget.orderCacheIdList.length > 0) {
        for (int j = 0; j < widget.orderCacheIdList.length; j++) {
          List<OrderCache> data  = await PosDatabase.instance.readSpecificOrderCache(widget.orderCacheIdList[j]);
          int tableUseDetailData = await PosDatabase.instance.deleteTableUseDetail(
              TableUseDetail(
                soft_delete: dateTime,
                table_use_sqlite_id: data[0].table_use_sqlite_id!,
              ));
        }
      }

    } catch(e){
      Fluttertoast.showToast(
          backgroundColor: Color(0xFFFF0000),
          msg: "Delete current table use detail error: $e");
    }
  }

  deleteCurrentTableUseId() async {
    String dateTime = dateFormat.format(DateTime.now());
    try{
      if(widget.orderCacheIdList.length > 0) {
        for (int j = 0; j < widget.orderCacheIdList.length; j++) {
          List<OrderCache> data  = await PosDatabase.instance.readSpecificOrderCache(widget.orderCacheIdList[j]);
          int tableUseData = await PosDatabase.instance.deleteTableUseID(
              TableUse(
                  soft_delete: dateTime,
                  table_use_sqlite_id: int.parse(data[0].table_use_sqlite_id!)
              ));
        }
      }
    }catch(e){
      Fluttertoast.showToast(
          backgroundColor: Color(0xFFFF0000),
          msg: "Delete current table use id error: ${e}");
    }
  }

  updateOrderCache() async {
    String dateTime = dateFormat.format(DateTime.now());

    if(widget.orderCacheIdList.length > 0){
      for(int j = 0; j < widget.orderCacheIdList.length; j++){
        OrderCache cacheObject = OrderCache(
            order_sqlite_id: widget.orderId,
            order_key: widget.orderKey,
            sync_status: 2,
            updated_at: dateTime,
            order_cache_sqlite_id: int.parse(widget.orderCacheIdList[j])
        );

        int data = await PosDatabase.instance.updateOrderCacheOrderId(cacheObject);
      }
    }
  }

  deleteOrderCache() async {
    String dateTime = dateFormat.format(DateTime.now());

    if(widget.orderCacheIdList.length > 0){
      for(int j = 0; j < widget.orderCacheIdList.length; j++){
        OrderCache orderCacheObject = OrderCache(
            soft_delete: dateTime,
            order_cache_sqlite_id: int.parse(widget.orderCacheIdList[j])
        );
        int data = await PosDatabase.instance.deletePaidOrderCache(orderCacheObject);
      }
    }
  }

  updatePosTableStatus(int status) async {
    String dateTime = dateFormat.format(DateTime.now());
    if(widget.selectedTableList.length > 0){
      for(int i = 0; i < widget.selectedTableList.length; i++){
        PosTable posTableData = PosTable(
          status: status,
          updated_at: dateTime,
          table_sqlite_id: widget.selectedTableList[i].table_sqlite_id
        );
        int data = await PosDatabase.instance.updatePosTableStatus(posTableData);
      }
    }
  }

  updatePosTableTableUseDetailKey() async {
    String dateTime = dateFormat.format(DateTime.now());
    if(widget.selectedTableList.length > 0) {
      for (int i = 0; i < widget.selectedTableList.length; i++) {
        PosTable posTableData = PosTable(
            table_use_detail_key: '',
            updated_at: dateTime,
            table_sqlite_id: widget.selectedTableList[i].table_sqlite_id
        );
        int data = await PosDatabase.instance.removePosTableTableUseDetailKey(
            posTableData);
      }
    }
  }

  generateCashRecordKey(CashRecord cashRecord) async  {
    final prefs = await SharedPreferences.getInstance();
    final int? device_id = prefs.getInt('device_id');
    var bytes  = cashRecord.created_at!.replaceAll(new RegExp(r'[^0-9]'),'') + cashRecord.cash_record_sqlite_id.toString() + device_id.toString();
    return md5.convert(utf8.encode(bytes)).toString();
  }

  insertCashRecordKey(CashRecord cashRecord, String dateTime) async {
    CashRecord? _record;
    int _status = 0;
    String? _key;
    _key = await generateCashRecordKey(cashRecord);
    if(_key != null){
      CashRecord cashRecordObject = CashRecord(
          cash_record_key: _key,
          updated_at: dateTime,
          cash_record_sqlite_id: cashRecord.cash_record_sqlite_id
      );
      int data = await PosDatabase.instance.updateCashRecordUniqueKey(cashRecordObject);
      if(data == 1){
        _record = await PosDatabase.instance.readSpecificCashRecord(cashRecord.cash_record_sqlite_id!);
      }
    }
    return _record;
  }

  createCashRecord() async {
    try{
      DateFormat dateFormat = DateFormat("yyyy-MM-dd HH:mm:ss");
      String dateTime = dateFormat.format(DateTime.now());
      List<String> _value = [];
      final prefs = await SharedPreferences.getInstance();
      final int? branch_id = prefs.getInt('branch_id');
      final String? pos_user = prefs.getString('pos_pin_user');
      final String? login_user = prefs.getString('user');
      Map userObject = json.decode(pos_user!);
      Map logInUser = json.decode(login_user!);

      List<Order> orderData = await PosDatabase.instance.readSpecificPaidOrder(widget.orderId);

      if(orderData.length == 1){
        CashRecord cashRecordObject  = CashRecord(
            cash_record_id: 0,
            cash_record_key: '',
            company_id: logInUser['company_id'].toString(),
            branch_id: branch_id.toString(),
            remark: orderData[0].generateOrderNumber(),
            amount: orderData[0].final_amount,
            payment_name: '',
            payment_type_id: orderData[0].payment_type,
            type: 3,
            user_id: userObject['user_id'].toString(),
            settlement_date: '',
            sync_status: 0,
            created_at: dateTime,
            updated_at: '',
            soft_delete: ''
        );
        CashRecord data = await PosDatabase.instance.insertSqliteCashRecord(cashRecordObject);
        CashRecord updatedData = await insertCashRecordKey(data, dateTime);

        //sync to cloud
        if(updatedData.cash_record_key != '' && updatedData.sync_status == 0){
          _value.add(jsonEncode(updatedData));
          Map response = await Domain().SyncCashRecordToCloud(_value.toString());
          if (response['status'] == '1') {
            List responseJson = response['data'];
            for (var i = 0; i < responseJson.length; i++) {
              int cashRecordData = await PosDatabase.instance.updateCashRecordSyncStatusFromCloud(responseJson[0]['cash_record_key']);
            }
          }
        }
      }

    }catch(e){
      print(e);
      Fluttertoast.showToast(
          backgroundColor: Color(0xFFFF0000),
          msg: "Create cash record error: ${e}");
    }
  }

  _printReceiptList() async {
    print('called');
    try {
      for (int i = 0; i < printerList.length; i++) {
        List<PrinterLinkCategory> data = await PosDatabase.instance
            .readPrinterLinkCategory(printerList[i].printer_sqlite_id!);
        for(int j = 0; j < data.length; j++){
          if (data[j].category_sqlite_id == '3') {
            if(printerList[i].type == 0){
              var printerDetail = jsonDecode(printerList[i].value!);
              var data = Uint8List.fromList(await ReceiptLayout()
                  .printReceipt80mm(true, widget.orderId));
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
      print('Printer Connection Error cart: ${e}');
      //response = 'Failed to get platform version.';
    }
  }

  readAllPrinters() async {
    final prefs = await SharedPreferences.getInstance();
    final int? branch_id = prefs.getInt('branch_id');

    List<Printer> data =
    await PosDatabase.instance.readAllBranchPrinter(branch_id!);
    printerList = List.from(data);
  }
}
