import 'dart:convert';
import 'dart:typed_data';

import 'package:esc_pos_printer/esc_pos_printer.dart';
import 'package:esc_pos_utils/esc_pos_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_usb_printer/flutter_usb_printer.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';
import 'package:pos_system/notifier/cart_notifier.dart';
import 'package:pos_system/notifier/connectivity_change_notifier.dart';
import 'package:pos_system/notifier/table_notifier.dart';
import 'package:pos_system/object/printer.dart';
import 'package:pos_system/page/progress_bar.dart';
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
  const PaymentSuccessDialog(
      {Key? key,
      required this.orderId,
      required this.callback,
      required this.orderCacheIdList,
      required this.selectedTableList,
      required this.dining_id,
      required this.orderKey})
      : super(key: key);

  @override
  State<PaymentSuccessDialog> createState() => _PaymentSuccessDialogState();
}

class _PaymentSuccessDialogState extends State<PaymentSuccessDialog> {
  DateFormat dateFormat = DateFormat("yyyy-MM-dd HH:mm:ss");
  List<Printer> printerList = [];
  FlutterUsbPrinter flutterUsbPrinter = FlutterUsbPrinter();
  bool isLoaded = false;

  closeDialog(BuildContext context) {
    return Navigator.of(context).pop(true);
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    callUpdateOrder();
    readAllPrinters();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeColor>(builder: (context, ThemeColor color, child) {
      return Consumer<CartModel>(builder: (context, CartModel cartModel, child) {
        return Consumer<TableModel>(builder: (context, TableModel tableModel, child) {
          return WillPopScope(
            onWillPop: () async => false,
            child: LayoutBuilder(builder: (context, constraints) {
              if (constraints.maxWidth > 800) {
                return AlertDialog(
                  title: Text('Payment success'),
                  content: isLoaded
                      ? Container(
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
                                        padding: EdgeInsets.fromLTRB(0, 30, 0, 30)),
                                    onPressed: () async {
                                      await _printReceiptList();
                                      await createCashRecord();
                                      closeDialog(context);
                                      tableModel.changeContent(true);
                                      cartModel.initialLoad();
                                      widget.callback();
                                    },
                                    child: Text(
                                      'Print receipt',
                                      style: TextStyle(fontSize: 18),
                                    )),
                              ),
                              SizedBox(height: 25),
                              Container(
                                width: MediaQuery.of(context).size.height / 6,
                                child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      primary: color.buttonColor,
                                    ),
                                    onPressed: () async {
                                      await createCashRecord();
                                      closeDialog(context);
                                      tableModel.changeContent(true);
                                      cartModel.initialLoad();
                                      widget.callback();
                                    },
                                    child: Text('${AppLocalizations.of(context)?.translate('close')}')),
                              )
                            ],
                          ),
                        )
                      : CustomProgressBar(),
                );
              } else {
                //Mobile layout
                return AlertDialog(
                  title: Text('Payment success'),
                  content: isLoaded
                      ? Container(
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
                                      await createCashRecord();
                                      closeDialog(context);
                                      tableModel.changeContent(true);
                                      cartModel.initialLoad();
                                      widget.callback();
                                    },
                                    child: Text(
                                      'Print receipt',
                                      style: TextStyle(fontSize: 15),
                                    )),
                              ),
                              //SizedBox(height: 25),
                              Container(
                                child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      primary: color.buttonColor,
                                    ),
                                    onPressed: () async {
                                      await createCashRecord();
                                      closeDialog(context);
                                      tableModel.changeContent(true);
                                      cartModel.initialLoad();
                                      widget.callback();
                                    },
                                    child: Text(
                                        '${AppLocalizations.of(context)?.translate('close')}')),
                              )
                            ],
                          ),
                        )
                      : CustomProgressBar(),
                );
              }
            }),
          );
        });
      });
    });
  }

  callUpdateOrder() async {
    await updateOrder();
    if (widget.dining_id == '1') {
      await deleteCurrentTableUseDetail();
      await deleteCurrentTableUseId();
      await updatePosTableStatus(0);
    }
    await updateOrderCache();
    //await deleteOrderCache();
    isLoaded = true;
  }

  updateOrder() async {
    String dateTime = dateFormat.format(DateTime.now());
    List<String> _value = [];
    Order checkData = await PosDatabase.instance.readSpecificOrder(int.parse(widget.orderId));
    Order orderObject = Order(
        sync_status: checkData.sync_status == 0 ? 0 : 2,
        updated_at: dateTime,
        order_sqlite_id: int.parse(widget.orderId));

    int updatedData = await PosDatabase.instance.updateOrderPaymentStatus(orderObject);
    if (updatedData == 1) {
      Order orderData = await PosDatabase.instance.readSpecificOrder(int.parse(widget.orderId));
      _value.add(jsonEncode(orderData));
    }
    //sync to cloud
    await syncUpdatedOrderToCloud(_value.toString());
  }

  syncUpdatedOrderToCloud(String value) async {
    bool _hasInternetAccess = await Domain().isHostReachable();
    if (_hasInternetAccess) {
      Map data = await Domain().SyncOrderToCloud(value);
      if (data['status'] == '1') {
        List responseJson = data['data'];
        for (var i = 0; i < responseJson.length; i++) {
          int orderData = await PosDatabase.instance
              .updateOrderSyncStatusFromCloud(responseJson[i]['order_key']);
        }
      }
    }
  }

  deleteCurrentTableUseDetail() async {
    List<String> _value = [];
    String dateTime = dateFormat.format(DateTime.now());
    try {
      if (widget.orderCacheIdList.isNotEmpty) {
        for (int j = 0; j < widget.orderCacheIdList.length; j++) {
          List<OrderCache> data = await PosDatabase.instance.readSpecificOrderCache(widget.orderCacheIdList[j]);
          List<TableUseDetail> tableUseCheckData = await PosDatabase.instance.readAllTableUseDetail(data[0].table_use_sqlite_id!);
          for (int i = 0; i < tableUseCheckData.length; i++) {
            TableUseDetail tableUseDetailObject = TableUseDetail(
                soft_delete: dateTime,
                sync_status: tableUseCheckData[i].sync_status == 0 ? 0 : 2,
                table_use_sqlite_id: data[0].table_use_sqlite_id!,
                table_use_detail_sqlite_id: tableUseCheckData[i].table_use_detail_sqlite_id);
            int deletedData = await PosDatabase.instance.deleteTableUseDetail(tableUseDetailObject);
            if (deletedData == 1) {
              TableUseDetail detailData = await PosDatabase.instance.readSpecificTableUseDetailByLocalId(tableUseDetailObject.table_use_detail_sqlite_id!);
              _value.add(jsonEncode(detailData.syncJson()));
            }
          }
        }
        //sync to cloud
        syncTableUseDetailToCloud(_value.toString());
      }
    } catch (e) {
      print('Delete current table use detail error: ${e}');
      Fluttertoast.showToast(
          backgroundColor: Color(0xFFFF0000), msg: "Delete current table use detail error: $e");
    }
  }

  syncTableUseDetailToCloud(String value) async {
    bool _hasInternetAccess = await Domain().isHostReachable();
    if (_hasInternetAccess) {
      Map response = await Domain().SyncTableUseDetailToCloud(value);
      if (response['status'] == '1') {
        List responseJson = response['data'];
        for (var i = 0; i < responseJson.length; i++) {
          int syncData = await PosDatabase.instance
              .updateTableUseDetailSyncStatusFromCloud(responseJson[i]['table_use_detail_key']);
        }
      }
    }
  }

  deleteCurrentTableUseId() async {
    String dateTime = dateFormat.format(DateTime.now());
    List<String> _value = [];
    try {
      if (widget.orderCacheIdList.isNotEmpty) {
        for (int j = 0; j < widget.orderCacheIdList.length; j++) {
          List<OrderCache> data = await PosDatabase.instance.readSpecificOrderCache(widget.orderCacheIdList[j]);
          TableUse tableUseCheckData = await PosDatabase.instance.readSpecificTableUseIdByLocalId(int.parse(data[0].table_use_sqlite_id!));
          TableUse tableUseObject = TableUse(
              soft_delete: dateTime,
              sync_status: tableUseCheckData.sync_status == 0 ? 0 : 2,
              table_use_sqlite_id: int.parse(data[0].table_use_sqlite_id!));
          int deletedData = await PosDatabase.instance.deleteTableUseID(tableUseObject);
          if (deletedData == 1) {
            TableUse tableUseData = await PosDatabase.instance
                .readSpecificTableUseIdByLocalId(tableUseObject.table_use_sqlite_id!);
            _value.add(jsonEncode(tableUseData));
          }
        }
        //sync to cloud
        syncUpdatedTableUseIdToCloud(_value.toString());
      }
    } catch (e) {
      print('Delete current table use id error: ${e}');
      Fluttertoast.showToast(
          backgroundColor: Color(0xFFFF0000), msg: "Delete current table use id error: ${e}");
    }
  }

  syncUpdatedTableUseIdToCloud(String value) async {
    bool _hasInternetAccess = await Domain().isHostReachable();
    if (_hasInternetAccess) {
      Map data = await Domain().SyncTableUseToCloud(value);
      if (data['status'] == '1') {
        List responseJson = data['data'];
        for (var i = 0; i < responseJson.length; i++) {
          int tablaUseData = await PosDatabase.instance
              .updateTableUseSyncStatusFromCloud(responseJson[i]['table_use_key']);
        }
      }
    }
  }

  updateOrderCache() async {
    String dateTime = dateFormat.format(DateTime.now());
    List<String> _value = [];
    if (widget.orderCacheIdList.isNotEmpty) {
      for (int j = 0; j < widget.orderCacheIdList.length; j++) {
        OrderCache checkData = await PosDatabase.instance.readSpecificOrderCacheByLocalId(int.parse(widget.orderCacheIdList[j]));
        OrderCache cacheObject = OrderCache(
            order_sqlite_id: widget.orderId,
            order_key: widget.orderKey,
            sync_status: checkData.sync_status == 0 ? 0 : 2,
            updated_at: dateTime,
            order_cache_sqlite_id: int.parse(widget.orderCacheIdList[j]));
        int updatedOrderCache = await PosDatabase.instance.updateOrderCacheOrderId(cacheObject);
        if (updatedOrderCache == 1) {
          OrderCache orderCacheData = await PosDatabase.instance.readSpecificOrderCacheByLocalId(cacheObject.order_cache_sqlite_id!);
          _value.add(jsonEncode(orderCacheData));
        }
      }
      //sync to cloud
      syncUpdatedOrderCacheToCloud(_value.toString());
    }
  }

  syncUpdatedOrderCacheToCloud(String value) async {
    bool _hasInternetAccess = await Domain().isHostReachable();
    if (_hasInternetAccess) {
      Map data = await Domain().SyncOrderCacheToCloud(value);
      if (data['status'] == '1') {
        List responseJson = data['data'];
        for (int i = 0; i < responseJson.length; i++) {
          int syncData = await PosDatabase.instance.updateOrderCacheSyncStatusFromCloud(responseJson[i]['order_cache_key']);
        }
      }
    }
  }

  deleteOrderCache() async {
    String dateTime = dateFormat.format(DateTime.now());
    if (widget.orderCacheIdList.length > 0) {
      for (int j = 0; j < widget.orderCacheIdList.length; j++) {
        OrderCache orderCacheObject = OrderCache(
            soft_delete: dateTime, order_cache_sqlite_id: int.parse(widget.orderCacheIdList[j]));
        int data = await PosDatabase.instance.deletePaidOrderCache(orderCacheObject);
      }
    }
  }

  updatePosTableStatus(int status) async {
    List<String> _value = [];
    String dateTime = dateFormat.format(DateTime.now());
    if (widget.selectedTableList.length > 0) {
      for (int i = 0; i < widget.selectedTableList.length; i++) {
        PosTable posTableData = PosTable(
            table_use_detail_key: '',
            status: status,
            updated_at: dateTime,
            table_sqlite_id: widget.selectedTableList[i].table_sqlite_id);
        int updatedStatus = await PosDatabase.instance.updatePosTableStatus(posTableData);
        int removeKey = await PosDatabase.instance.removePosTableTableUseDetailKey(posTableData);
        if (updatedStatus == 1 && removeKey == 1) {
          List<PosTable> posTable = await PosDatabase.instance.readSpecificTable(posTableData.table_sqlite_id.toString());
          if (posTable[0].sync_status == 2) {
            _value.add(jsonEncode(posTable[0]));
          }
        }
      }
      //sync to cloud
      syncUpdatedPosTableToCloud(_value.toString());
    }
  }

  syncUpdatedPosTableToCloud(String value) async {
    bool _hasInternetAccess = await Domain().isHostReachable();
    if (_hasInternetAccess) {
      Map response = await Domain().SyncUpdatedPosTableToCloud(value);
      if (response['status'] == '1') {
        List responseJson = response['data'];
        for (var i = 0; i < responseJson.length; i++) {
          int syncData = await PosDatabase.instance.updatePosTableSyncStatusFromCloud(responseJson[i]['table_id']);
        }
      }
    }
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

  createCashRecord() async {
    try {
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

      if (orderData.length == 1) {
        CashRecord cashRecordObject = CashRecord(
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
            soft_delete: '');
        CashRecord data = await PosDatabase.instance.insertSqliteCashRecord(cashRecordObject);
        CashRecord updatedData = await insertCashRecordKey(data, dateTime);

        //sync to cloud
        syncCashRecordToCloud(updatedData);
      }
    } catch (e) {
      print(e);
      Fluttertoast.showToast(
          backgroundColor: Color(0xFFFF0000), msg: "Create cash record error: ${e}");
    }
  }

  syncCashRecordToCloud(CashRecord updatedData) async {
    List<String> _value = [];
    bool _hasInternetAccess = await Domain().isHostReachable();
    if (_hasInternetAccess) {
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

  _printReceiptList() async {
    try {
      for (int i = 0; i < printerList.length; i++) {
        List<PrinterLinkCategory> data =
            await PosDatabase.instance.readPrinterLinkCategory(printerList[i].printer_sqlite_id!);
        for (int j = 0; j < data.length; j++) {
          if (data[j].category_sqlite_id == '0') {
            var printerDetail = jsonDecode(printerList[i].value!);
            if (printerList[i].type == 0) {
              if (printerList[i].paper_size == 0) {
                //print 80mm
                var data = Uint8List.fromList(
                    await ReceiptLayout().printReceipt80mm(true, widget.orderId));
                bool? isConnected = await flutterUsbPrinter.connect(
                    int.parse(printerDetail['vendorId']), int.parse(printerDetail['productId']));
                if (isConnected == true) {
                  await flutterUsbPrinter.write(data);
                } else {
                  Fluttertoast.showToast(
                      backgroundColor: Colors.red,
                      msg: "${AppLocalizations.of(context)?.translate('usb_printer_not_connect')}");
                }
              } else {
                //print 58mm
                var data = Uint8List.fromList(
                    await ReceiptLayout().printReceipt58mm(true, widget.orderId));
                bool? isConnected = await flutterUsbPrinter.connect(
                    int.parse(printerDetail['vendorId']), int.parse(printerDetail['productId']));
                if (isConnected == true) {
                  await flutterUsbPrinter.write(data);
                } else {
                  Fluttertoast.showToast(
                      backgroundColor: Colors.red,
                      msg: "${AppLocalizations.of(context)?.translate('usb_printer_not_connect')}");
                }
              }
            } else {
              if (printerList[i].paper_size == 0) {
                //print LAN 80mm
                final profile = await CapabilityProfile.load();
                final printer = NetworkPrinter(PaperSize.mm80, profile);
                final PosPrintResult res = await printer.connect(printerDetail, port: 9100);

                if (res == PosPrintResult.success) {
                  await ReceiptLayout().printReceipt80mm(false, widget.orderId, value: printer);
                  printer.disconnect();
                } else {
                  Fluttertoast.showToast(
                      backgroundColor: Colors.red,
                      msg: "${AppLocalizations.of(context)?.translate('lan_printer_not_connect')}");
                }
              } else {
                //print LAN 58mm
                final profile = await CapabilityProfile.load();
                final printer = NetworkPrinter(PaperSize.mm58, profile);
                final PosPrintResult res = await printer.connect(printerDetail, port: 9100);

                if (res == PosPrintResult.success) {
                  await ReceiptLayout().printReceipt58mm(false, widget.orderId, value: printer);
                  printer.disconnect();
                } else {
                  Fluttertoast.showToast(
                      backgroundColor: Colors.red,
                      msg: "${AppLocalizations.of(context)?.translate('lan_printer_not_connect')}");
                }
              }
            }
          }
        }
      }
    } catch (e) {
      print('Printer Connection Error cart: ${e}');
      Fluttertoast.showToast(
          backgroundColor: Colors.red,
          msg: "${AppLocalizations.of(context)?.translate('printing_error')}");
    }
  }

  readAllPrinters() async {
    final prefs = await SharedPreferences.getInstance();
    final int? branch_id = prefs.getInt('branch_id');

    List<Printer> data = await PosDatabase.instance.readAllBranchPrinter(branch_id!);
    printerList = List.from(data);
  }
}
