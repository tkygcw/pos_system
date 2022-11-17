import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';
import 'package:pos_system/fragment/table/table.dart';
import 'package:pos_system/notifier/cart_notifier.dart';
import 'package:pos_system/notifier/table_notifier.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../database/pos_database.dart';
import '../../notifier/theme_color.dart';
import '../../object/cash_record.dart';
import '../../object/order.dart';
import '../../object/order_cache.dart';
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
  const PaymentSuccessDialog({Key? key, required this.orderId, required this.callback, required this.orderCacheIdList, required this.selectedTableList}) : super(key: key);

  @override
  State<PaymentSuccessDialog> createState() => _PaymentSuccessDialogState();
}

class _PaymentSuccessDialogState extends State<PaymentSuccessDialog> {
  DateFormat dateFormat = DateFormat("yyyy-MM-dd HH:mm:ss");


  closeDialog(BuildContext context) {
    return Navigator.of(context).pop(true);
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    callUpdateOrder();
    createCashRecord();
    _printReceipt();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeColor>(builder: (context, ThemeColor color, child) {
      return Consumer<CartModel>(builder: (context, CartModel cartModel, child) {
          return Consumer<TableModel>(
            builder: (context, TableModel tableModel, child) {
              return WillPopScope(
                onWillPop: () async => false,
                child: AlertDialog(
                  title: Text('Payment success'),
                  actions: [
                    TextButton(
                      child:
                          Text('${AppLocalizations.of(context)?.translate('close')}'),
                      onPressed: () async {
                        closeDialog(context);
                        tableModel.changeContent(true);
                        cartModel.initialLoad();
                        widget.callback();
                      },
                    ),
                  ],
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
    await deleteCurrentTableUseDetail();
    await deleteCurrentTableUseId();
    await updateOrderCache();
    await deleteOrderCache();
    await updatePosTableStatus(0);
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
            sync_status: 0,
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

  createCashRecord() async {
    try{
      DateFormat dateFormat = DateFormat("yyyy-MM-dd HH:mm:ss");
      String dateTime = dateFormat.format(DateTime.now());
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
            company_id: logInUser['company_id'].toString(),
            branch_id: branch_id.toString(),
            remark: 'invoice001',
            amount: orderData[0].final_amount,
            payment_name: '',
            payment_type_id: orderData[0].payment_link_company_id,
            type: 3,
            user_id: userObject['user_id'].toString(),
            settlement_date: '',
            sync_status: 0,
            created_at: dateTime,
            updated_at: '',
            soft_delete: ''
        );

        CashRecord data = await PosDatabase.instance.insertSqliteCashRecord(cashRecordObject);
      }

    }catch(e){
      Fluttertoast.showToast(
          backgroundColor: Color(0xFFFF0000),
          msg: "Create cash record error: ${e}");
    }
  }

  _printReceipt() async {
    try {
      print('print receipt');
      // for (int i = 0; i < printerList.length; i++) {
      //   List<PrinterLinkCategory> data = await PosDatabase.instance
      //       .readPrinterLinkCategory(printerList[i].printer_sqlite_id!);
      //   print('printer link category length: ${data.length}');
      //   for(int j = 0; j < data.length; j++){
      //     if (data[j].category_sqlite_id == '3') {
      //       if(printerList[i].type == 0){
      //         var printerDetail = jsonDecode(printerList[i].value!);
      //         var data = Uint8List.fromList(await ReceiptLayout().printReceipt80mm(true, null));
      //         bool? isConnected = await flutterUsbPrinter.connect(
      //             int.parse(printerDetail['vendorId']),
      //             int.parse(printerDetail['productId']));
      //         if (isConnected == true) {
      //           await flutterUsbPrinter.write(data);
      //         } else {
      //           print('not connected');
      //         }
      //       } else {
      //         print("print lan");
      //       }
      //     }
      //   }
      // }
    } catch (e) {
      print('Printer Connection Error: ${e}');
      //response = 'Failed to get platform version.';
    }
  }
}
