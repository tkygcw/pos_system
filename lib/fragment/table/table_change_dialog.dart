import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:esc_pos_printer/esc_pos_printer.dart';
import 'package:esc_pos_utils/esc_pos_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_usb_printer/flutter_usb_printer.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';
import 'package:pos_system/notifier/theme_color.dart';
import 'package:pos_system/object/order_cache.dart';
import 'package:pos_system/object/table.dart';
import 'package:pos_system/object/table_use.dart';
import 'package:pos_system/object/table_use_detail.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../database/domain.dart';
import '../../database/pos_database.dart';
import '../../main.dart';
import '../../object/print_receipt.dart';
import '../../object/printer.dart';
import '../../object/receipt_layout.dart';
import '../../translation/AppLocalizations.dart';
import '../logout_dialog.dart';

class TableChangeDialog extends StatefulWidget {
  final PosTable object;
  final Function() callBack;
  const TableChangeDialog(
      {Key? key, required this.object, required this.callBack })
      : super(key: key);

  @override
  State<TableChangeDialog> createState() => _TableChangeDialogState();
}

class _TableChangeDialogState extends State<TableChangeDialog> {
  FlutterUsbPrinter flutterUsbPrinter = FlutterUsbPrinter();
  final tableNoController = TextEditingController();
  PrintReceipt printReceipt = PrintReceipt();
  List<OrderCache> orderCacheList = [];
  List<Printer> printerList = [];
  String? table_use_value, table_use_detail_value, order_cache_value, table_value;
  bool _submitted = false, isLogOut = false, isButtonDisabled = false, willPop = true;


  @override
  void initState() {
    // TODO: implement initState
    //readAllTableCache();
    readAllPrinters();
    super.initState();
  }

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
    tableNoController.dispose();
  }

  readAllPrinters() async {
    printerList = await printReceipt.readAllPrinters();
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

  String? get errorTableNo {
    final text = tableNoController.value.text;
    if (text.isEmpty) {
      return 'table_no_required';
    } else if(text == widget.object.number){
      return 'table_no_same';
    }
    return null;
  }

  callChangeToTableInUse(String currentTableUseKey, String currentTableUseId, String NewTableUseId, String dateTime) async {
    await updateOrderCache(currentTableUseKey, NewTableUseId, dateTime);
    await deleteCurrentTableUseDetail(currentTableUseId, dateTime);
    await deleteCurrentTableUseId(int.parse(currentTableUseId), dateTime);
  }

  updateOrderCache(String currentTableUseKey, String NewTableUseId, String dateTime) async {
    List<String> _value = [];
    try{
      List<OrderCache> checkData = await PosDatabase.instance.readTableOrderCache(currentTableUseKey);
      TableUse newTableUseData = await PosDatabase.instance.readSpecificTableUseIdByLocalId(int.parse(NewTableUseId));
      for(int i = 0; i < checkData.length; i++){
        OrderCache orderCacheObject = OrderCache(
            order_cache_sqlite_id: checkData[i].order_cache_sqlite_id,
            table_use_sqlite_id: NewTableUseId,
            table_use_key: newTableUseData.table_use_key,
            sync_status: checkData[i].sync_status == 0 ? 0 : 2,
            updated_at: dateTime
        );
        int updatedData = await PosDatabase.instance.updateOrderCacheTableUseId(orderCacheObject);
        if(updatedData == 1){
          OrderCache orderCacheData = await PosDatabase.instance.readSpecificOrderCacheByLocalId(orderCacheObject.order_cache_sqlite_id!);
          _value.add(jsonEncode(orderCacheData));
        }
      }
      this.order_cache_value = _value.toString();
      //sync to cloud
      //syncOrderCacheToCloud(_value.toString());
      // Map response = await Domain().SyncOrderCacheToCloud(_value.toString());
      // if(response['status'] == '1'){
      //   List responseJson = response['data'];
      //   for(int i = 0 ; i <responseJson.length; i++){
      //     int syncData = await PosDatabase.instance.updateOrderCacheSyncStatusFromCloud(responseJson[i]['order_cache_key']);
      //   }
      // }
    } catch(e){
      print('Update order cache table use id error: ${e}');
      Fluttertoast.showToast(
          backgroundColor: Color(0xFFFF0000),
          msg: "Update order cache table use id error: ${e}");
    }
  }

  // syncOrderCacheToCloud(String value) async {
  //   bool _hasInternetAccess = await Domain().isHostReachable();
  //   if(_hasInternetAccess){
  //     Map response = await Domain().SyncOrderCacheToCloud(value);
  //     if(response['status'] == '1'){
  //       List responseJson = response['data'];
  //       for(int i = 0 ; i <responseJson.length; i++){
  //         int syncData = await PosDatabase.instance.updateOrderCacheSyncStatusFromCloud(responseJson[i]['order_cache_key']);
  //       }
  //     }
  //   }
  // }

  deleteCurrentTableUseDetail(String currentTableUseId, String dateTime) async {
    List<String> _value = [];
    try{
      List<TableUseDetail> checkData  = await PosDatabase.instance.readAllTableUseDetail(currentTableUseId);
      for(int i = 0; i < checkData.length; i++){
        TableUseDetail tableUseDetailObject =  TableUseDetail(
          soft_delete: dateTime,
          sync_status: checkData[i].sync_status == 0 ?  0 : 2,
          status: 1,
          table_use_sqlite_id: currentTableUseId,
          table_use_detail_key: checkData[i].table_use_detail_key,
          table_use_detail_sqlite_id: checkData[i].table_use_detail_sqlite_id
        );
        int updatedData = await PosDatabase.instance.deleteTableUseDetailByKey(tableUseDetailObject);
        //int updatedData = await PosDatabase.instance.deleteTableUseDetail(tableUseDetailObject);
        if(updatedData == 1){
          TableUseDetail detailData =  await PosDatabase.instance.readSpecificTableUseDetailByLocalId(tableUseDetailObject.table_use_detail_sqlite_id!);
          _value.add(jsonEncode(detailData));
        }
      }
      this.table_use_detail_value = _value.toString();
      //sync to cloud
      //syncDeletedTableUseDetailToCloud(_value.toString());
      // Map data = await Domain().SyncTableUseDetailToCloud(_value.toString());
      // if (data['status'] == '1') {
      //   List responseJson = data['data'];
      //   for (var i = 0; i < responseJson.length; i++) {
      //     int syncData = await PosDatabase.instance.updateTableUseDetailSyncStatusFromCloud(responseJson[i]['table_use_detail_key']);
      //   }
      // }
    } catch(e){
      Fluttertoast.showToast(
          backgroundColor: Color(0xFFFF0000),
          msg: "Delete current table use detail error: $e");
    }
  }

  // syncDeletedTableUseDetailToCloud(String value) async {
  //   bool _hasInternetAccess = await Domain().isHostReachable();
  //   if(_hasInternetAccess){
  //     Map data = await Domain().SyncTableUseDetailToCloud(value);
  //     if (data['status'] == '1') {
  //       List responseJson = data['data'];
  //       for (var i = 0; i < responseJson.length; i++) {
  //         int syncData = await PosDatabase.instance.updateTableUseDetailSyncStatusFromCloud(responseJson[i]['table_use_detail_key']);
  //       }
  //     }
  //   }
  // }

  deleteCurrentTableUseId(int currentTableUseId, String dateTime) async {
    List<String> _value = [];
    try{
      TableUse checkData = await PosDatabase.instance.readSpecificTableUseIdByLocalId(currentTableUseId);
      TableUse tableUseObject = TableUse(
        soft_delete: dateTime,
        sync_status: checkData.sync_status == 0 ? 0 : 2,
        status: 1,
        table_use_key: checkData.table_use_key,
        table_use_sqlite_id: currentTableUseId,
      );
      int updatedData = await PosDatabase.instance.deleteTableUseByKey(tableUseObject);
      //int updatedData = await PosDatabase.instance.deleteTableUseID(tableUseObject);
      if(updatedData == 1){
        TableUse tableUseData = await PosDatabase.instance.readSpecificTableUseIdByLocalId(tableUseObject.table_use_sqlite_id!);
        _value.add(jsonEncode(tableUseData));
      }
      this.table_use_value = _value.toString();
      //sync to cloud
      //syncTableUseIdToCloud(_value.toString());
      // Map data = await Domain().SyncTableUseToCloud(_value.toString());
      // if (data['status'] == '1') {
      //   List responseJson = data['data'];
      //   int syncData = await PosDatabase.instance.updateTableUseSyncStatusFromCloud(responseJson[0]['table_use_key']);
      // }
    }catch(e){
      Fluttertoast.showToast(
          backgroundColor: Color(0xFFFF0000),
          msg: "Delete current table use id error: ${e}");
    }
  }

  // syncTableUseIdToCloud(String value) async {
  //   bool _hasInternetAccess = await Domain().isHostReachable();
  //   if(_hasInternetAccess){
  //     Map data = await Domain().SyncTableUseToCloud(value);
  //     if (data['status'] == '1') {
  //       List responseJson = data['data'];
  //       int syncData = await PosDatabase.instance.updateTableUseSyncStatusFromCloud(responseJson[0]['table_use_key']);
  //     }
  //   }
  // }

  /**
   * concurrent here
   */
  changeToUnusedTable(int currentDetailTableId, String table_local_id, String table_id, String dateTime) async {
    print('table local id : ${table_local_id}');
    List<String> _value = [];
    List<TableUseDetail> checkData = await PosDatabase.instance.readSpecificTableUseDetail(currentDetailTableId);
    TableUseDetail tableUseDetailObject = TableUseDetail(
        table_use_detail_key: checkData[0].table_use_detail_key,
        table_sqlite_id: table_local_id,
        table_id: table_id,
        sync_status: checkData[0].sync_status == 0 ? 0 : 2,
        updated_at: dateTime
    );
    int updatedData = await PosDatabase.instance.updateTableUseDetail(tableUseDetailObject);
    if(updatedData == 1){
      List<TableUseDetail> tableUseDetailData = await PosDatabase.instance.readSpecificTableUseDetail(int.parse(tableUseDetailObject.table_sqlite_id!));
      if(tableUseDetailData[0].soft_delete == ''){
        _value.add(jsonEncode(tableUseDetailData[0]));
      }
    }
    this.table_use_detail_value = _value.toString();
    //sync to cloud
    //syncTableUseDetailToCloud(_value.toString());
    // Map data = await Domain().SyncTableUseDetailToCloud(_value.toString());
    // if (data['status'] == '1') {
    //   List responseJson = data['data'];
    //   for (var i = 0; i < responseJson.length; i++) {
    //     int syncData = await PosDatabase.instance.updateTableUseDetailSyncStatusFromCloud(responseJson[i]['table_use_detail_key']);
    //   }
    // }
  }

  // syncTableUseDetailToCloud(String value) async {
  //   bool _hasInternetAccess = await Domain().isHostReachable();
  //   if(_hasInternetAccess){
  //     Map data = await Domain().SyncTableUseDetailToCloud(value);
  //     if (data['status'] == '1') {
  //       List responseJson = data['data'];
  //       for (var i = 0; i < responseJson.length; i++) {
  //         int syncData = await PosDatabase.instance.updateTableUseDetailSyncStatusFromCloud(responseJson[i]['table_use_detail_key']);
  //       }
  //     }
  //   }
  // }

  updateTable() async {
    DateFormat dateFormat = DateFormat("yyyy-MM-dd HH:mm:ss");
    String dateTime = dateFormat.format(DateTime.now());
    try{
      List<TableUseDetail> NowUseDetailData = await PosDatabase.instance.readSpecificTableUseDetail(widget.object.table_sqlite_id!);
      List<PosTable> tableData = await PosDatabase.instance.readSpecificTableByTableNo(tableNoController.text);
      List<TableUseDetail> NewUseDetailData = await PosDatabase.instance.readSpecificTableUseDetail(tableData[0].table_sqlite_id!);
      //check new table is in use or not
      if(NewUseDetailData.isNotEmpty){
        await callChangeToTableInUse(NowUseDetailData[0].table_use_key!, NowUseDetailData[0].table_use_sqlite_id!, NewUseDetailData[0].table_use_sqlite_id!, dateTime);
        await updatePosTable(NewUseDetailData[0].table_use_detail_key!, dateTime, NowUseDetailData[0].table_use_key!);

      } else {
        await changeToUnusedTable(widget.object.table_sqlite_id!, tableData[0].table_sqlite_id.toString(), tableData[0].table_id.toString(), dateTime);
        await updatePosTable(NowUseDetailData[0].table_use_detail_key!, dateTime, NowUseDetailData[0].table_use_key!);
      }
      // await syncAllToCloud();
      // if(this.isLogOut == true){
      //   openLogOutDialog();
      //   return;
      // }
      widget.callBack();
      Navigator.of(context).pop();
    } catch(e){
      print('update table error: $e');
      Fluttertoast.showToast(
          backgroundColor: Colors.red,
          msg: "${AppLocalizations.of(context)?.translate("table_not_found")}");
      Navigator.of(context).pop();
    }
  }

  /**
   * concurrent here
   */
  updatePosTableStatusAndDetailKey(int tableId, int status, String dateTime, String key, String tableUseKey) async {
    try{
      PosTable? _data;
      PosTable posTableObject = PosTable(
        table_use_detail_key: key,
        table_use_key: tableUseKey,
        status: status,
        updated_at: dateTime,
        table_sqlite_id: tableId,
      );
      int updateStatus = await PosDatabase.instance.updatePosTableStatus(posTableObject);
      int updateKey = await PosDatabase.instance.removePosTableTableUseDetailKey(posTableObject);
      if(updateStatus == 1 && updateKey == 1){
        List<PosTable> posTable  = await PosDatabase.instance.readSpecificTable(posTableObject.table_sqlite_id.toString());
        _data = posTable[0];
      }
      return _data;
    }catch(e){
      print('update pos table status and detail Key error: $e');
    }

  }


  updatePosTable(String key, String dateTime, String currantTableUseKey) async {
    try{
      List<String> _value = [];
      List<PosTable> tableData = await PosDatabase.instance.readSpecificTableByTableNo(tableNoController.text);
      //update new table status
      List<PosTable> newTable = await PosDatabase.instance.checkPosTableStatus(tableData[0].table_sqlite_id!);
      if (newTable[0].status == 0) {
        PosTable updateNewTableData = await updatePosTableStatusAndDetailKey(tableData[0].table_sqlite_id!, 1, dateTime, key, currantTableUseKey);
        _value.add(jsonEncode(updateNewTableData));
      }
      //update previous table status
      List<PosTable> lastTable = await PosDatabase.instance.checkPosTableStatus(widget.object.table_sqlite_id!);
      if (lastTable[0].status == 1) {
        PosTable updatedLastTableData = await updatePosTableStatusAndDetailKey(widget.object.table_sqlite_id!, 0, dateTime, '', '');
        _value.add(jsonEncode(updatedLastTableData));
      }
      this.table_value = _value.toString();
      //sync to cloud
      //syncUpdatedTableToCloud(_value.toString());
      await callPrinter(lastTable: lastTable[0].number, newTable: newTable[0].number);
    }catch(e){
     print('update pos table function error: $e');
    }
  }

  // syncUpdatedTableToCloud(String value) async {
  //   bool _hasInternetAccess = await Domain().isHostReachable();
  //   if(_hasInternetAccess){
  //     Map response = await Domain().SyncUpdatedPosTableToCloud(value);
  //     if (response['status'] == '1') {
  //       List responseJson = response['data'];
  //       for (var i = 0; i < responseJson.length; i++) {
  //         int syncData = await PosDatabase.instance.updatePosTableSyncStatusFromCloud(responseJson[i]['table_id']);
  //       }
  //     }
  //   }
  // }

  callPrinter({lastTable, newTable}) async {
    int printStatus = await printReceipt.printChangeTableList(printerList, lastTable: lastTable, newTable: newTable);
    if(printStatus == 1){
      Fluttertoast.showToast(
          backgroundColor: Colors.red,
          msg: "${AppLocalizations.of(context)?.translate('printer_not_connected')}");
    } else if (printStatus == 2){
      Fluttertoast.showToast(
          backgroundColor: Colors.orangeAccent,
          msg: "${AppLocalizations.of(context)?.translate('printer_connection_timeout')}");
    }
  }

  void _submit(BuildContext context) async {
    setState(() => _submitted = true);
    if (errorTableNo == null) {
      await updateTable();
    } else {
      setState(() {
        isButtonDisabled = false;
        willPop = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeColor>(builder: (context, ThemeColor color, child) {
      return WillPopScope(
        onWillPop: () async => willPop,
        child: AlertDialog(
          title: Text("Change table to?"),
          content: Container(
            width: 350.0,
            height: 100.0,
            child: ValueListenableBuilder(
                // Note: pass _controller to the animation argument
                valueListenable: tableNoController,
                builder: (context, TextEditingValue value, __) {
                  return Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: TextField(
                      controller: tableNoController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        errorText: _submitted
                            ? errorTableNo == null
                                ? errorTableNo
                                : AppLocalizations.of(context)
                                    ?.translate(errorTableNo!)
                            : null,
                        border: OutlineInputBorder(
                          borderSide: BorderSide(color: color.backgroundColor),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: color.backgroundColor),
                        ),
                        labelText: 'Table No.',
                      ),
                    ),
                  );
                }),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('${AppLocalizations.of(context)?.translate('close')}'),
              onPressed: isButtonDisabled ? null : () {
                setState(() {
                  isButtonDisabled = true;
                });
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text("Submit"),
              onPressed: isButtonDisabled ? null : () {
                setState(() {
                  isButtonDisabled = true;
                  willPop = false;
                });
                _submit(context);
              },
            ),
          ],
        ),
      );
    });
  }

  syncAllToCloud() async {
    try{
      if(mainSyncToCloud.count == 0){
        mainSyncToCloud.count == 1;
        final prefs = await SharedPreferences.getInstance();
        final int? device_id = prefs.getInt('device_id');
        final String? login_value = prefs.getString('login_value');
        Map data = await Domain().syncLocalUpdateToCloud(
            device_id: device_id.toString(),
            value: login_value,
            table_use_value: this.table_use_value,
            table_use_detail_value: this.table_use_detail_value,
            order_cache_value: this.order_cache_value,
            table_value: this.table_value
        );
        if (data['status'] == '1') {
          List responseJson = data['data'];
          for (int i = 0; i < responseJson.length; i++) {
            switch(responseJson[i]['table_name']){
              case 'tb_table_use': {
                await PosDatabase.instance.updateTableUseSyncStatusFromCloud(responseJson[i]['table_use_key']);
              }
              break;
              case 'tb_table_use_detail': {
                await PosDatabase.instance.updateTableUseDetailSyncStatusFromCloud(responseJson[i]['table_use_detail_key']);
              }
              break;
              case 'tb_order_cache': {
                await PosDatabase.instance.updateOrderCacheSyncStatusFromCloud(responseJson[i]['order_cache_key']);
              }
              break;
              case 'tb_table': {
                await PosDatabase.instance.updatePosTableSyncStatusFromCloud(responseJson[i]['table_id']);
              }
              break;
              default: {
                return;
              }
            }
          }
          mainSyncToCloud.resetCount();
        } else if(data['status'] == '7'){
          mainSyncToCloud.resetCount();
          this.isLogOut = true;
        }else if (data['status'] == '8') {
          print('change table sync timeout');
          mainSyncToCloud.resetCount();
          throw TimeoutException("Timeout");
        } else {
          mainSyncToCloud.resetCount();
        }
      }
    }catch(e){
      mainSyncToCloud.resetCount();
    }

    // bool _hasInternetAccess = await Domain().isHostReachable();
    // if (_hasInternetAccess) {
    //
    // }
  }

  // readAllTableCache() async {
  //   print('read all table cache called');
  //   final prefs = await SharedPreferences.getInstance();
  //   final int? branch_id = prefs.getInt('branch_id');
  //
  //   List<OrderCache> orderCacheData = await PosDatabase.instance
  //       .readTableOrderCache(branch_id.toString(), widget.object.table_sqlite_id.toString());
  //   //loop all table order cache
  //   for (int i = 0; i < orderCacheData.length; i++) {
  //     if (!orderCacheList.contains(orderCacheData)) {
  //       orderCacheList = List.from(orderCacheData);
  //     }
  //   }
  //   print('order cache length: ${orderCacheList.length}');
  // }




}
