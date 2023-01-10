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
import '../../object/printer.dart';
import '../../object/receipt_layout.dart';
import '../../translation/AppLocalizations.dart';

class TableChangeDialog extends StatefulWidget {
  final List<Printer> printerList;
  final PosTable object;
  final Function() callBack;
  const TableChangeDialog(
      {Key? key, required this.object, required this.callBack, required this.printerList})
      : super(key: key);

  @override
  State<TableChangeDialog> createState() => _TableChangeDialogState();
}

class _TableChangeDialogState extends State<TableChangeDialog> {
  FlutterUsbPrinter flutterUsbPrinter = FlutterUsbPrinter();
  final tableNoController = TextEditingController();
  List<OrderCache> orderCacheList = [];
  bool _submitted = false;

  @override
  void initState() {
    // TODO: implement initState
    //readAllTableCache();
    super.initState();
  }

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
    tableNoController.dispose();
  }

  String? get errorTableNo {
    final text = tableNoController.value.text;
    if (text.isEmpty) {
      return 'table_no_required';
    }
    return null;
  }

  callChangeToTableInUse(String currentTableUseId, String NewTableUseId, String dateTime) async {
    await updateOrderCache(currentTableUseId, NewTableUseId, dateTime);
    await deleteCurrentTableUseDetail(currentTableUseId, dateTime);
    await deleteCurrentTableUseId(int.parse(currentTableUseId), dateTime);
  }

  updateOrderCache(String currentTableUseId, String NewTableUseId, String dateTime) async {
    List<String> _value = [];
    try{
      final prefs = await SharedPreferences.getInstance();
      final int? branch_id = prefs.getInt('branch_id');

      List<OrderCache> checkData = await PosDatabase.instance.readTableOrderCache(branch_id.toString(), currentTableUseId);
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
      //sync to cloud
      syncOrderCacheToCloud(_value.toString());
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

  syncOrderCacheToCloud(String value) async {
    bool _hasInternetAccess = await Domain().isHostReachable();
    if(_hasInternetAccess){
      Map response = await Domain().SyncOrderCacheToCloud(value);
      if(response['status'] == '1'){
        List responseJson = response['data'];
        for(int i = 0 ; i <responseJson.length; i++){
          int syncData = await PosDatabase.instance.updateOrderCacheSyncStatusFromCloud(responseJson[i]['order_cache_key']);
        }
      }
    }
  }

  deleteCurrentTableUseDetail(String currentTableUseId, String dateTime) async {
    List<String> _value = [];
    try{
      List<TableUseDetail> checkData  = await PosDatabase.instance.readAllTableUseDetail(currentTableUseId);
      for(int i = 0; i < checkData.length; i++){
        TableUseDetail tableUseDetailObject =  TableUseDetail(
          soft_delete: dateTime,
          sync_status: checkData[i].sync_status == 0 ?  0 : 2,
          table_use_sqlite_id: currentTableUseId,
          table_use_detail_sqlite_id: checkData[i].table_use_detail_sqlite_id
        );
        int updatedData = await PosDatabase.instance.deleteTableUseDetail(tableUseDetailObject);
        if(updatedData == 1){
          TableUseDetail detailData =  await PosDatabase.instance.readSpecificTableUseDetailByLocalId(tableUseDetailObject.table_use_detail_sqlite_id!);
          _value.add(jsonEncode(detailData.syncJson()));
        }
      }
      //sync to cloud
      syncDeletedTableUseDetailToCloud(_value.toString());
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

  syncDeletedTableUseDetailToCloud(String value) async {
    bool _hasInternetAccess = await Domain().isHostReachable();
    if(_hasInternetAccess){
      Map data = await Domain().SyncTableUseDetailToCloud(value);
      if (data['status'] == '1') {
        List responseJson = data['data'];
        for (var i = 0; i < responseJson.length; i++) {
          int syncData = await PosDatabase.instance.updateTableUseDetailSyncStatusFromCloud(responseJson[i]['table_use_detail_key']);
        }
      }
    }
  }

  deleteCurrentTableUseId(int currentTableUseId, String dateTime) async {
    List<String> _value = [];
    try{
      TableUse checkData = await PosDatabase.instance.readSpecificTableUseIdByLocalId(currentTableUseId);
      TableUse tableUseObject = TableUse(
        soft_delete: dateTime,
        sync_status: checkData.sync_status == 0 ? 0 : 2,
        table_use_sqlite_id: currentTableUseId,
      );
      int updatedData = await PosDatabase.instance.deleteTableUseID(tableUseObject);
      if(updatedData == 1){
        TableUse tableUseData = await PosDatabase.instance.readSpecificTableUseIdByLocalId(tableUseObject.table_use_sqlite_id!);
        _value.add(jsonEncode(tableUseData));
      }
      //sync to cloud
      syncTableUseIdToCloud(_value.toString());
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

  syncTableUseIdToCloud(String value) async {
    bool _hasInternetAccess = await Domain().isHostReachable();
    if(_hasInternetAccess){
      Map data = await Domain().SyncTableUseToCloud(value);
      if (data['status'] == '1') {
        List responseJson = data['data'];
        int syncData = await PosDatabase.instance.updateTableUseSyncStatusFromCloud(responseJson[0]['table_use_key']);
      }
    }
  }

  /**
   * concurrent here
   */
  changeToUnusedTable(int currentDetailTableId, String table_id, String dateTime) async {
    List<String> _value = [];
    List<TableUseDetail> checkData = await PosDatabase.instance.readSpecificTableUseDetail(currentDetailTableId);
    TableUseDetail tableUseDetailObject = TableUseDetail(
        table_sqlite_id: table_id,
        sync_status: checkData[0].sync_status == 0 ? 0 : 2,
        updated_at: dateTime
    );
    int updatedData = await PosDatabase.instance.updateTableUseDetail(widget.object.table_sqlite_id!, tableUseDetailObject);
    if(updatedData == 1){
      List<TableUseDetail> tableUseDetailData = await PosDatabase.instance.readSpecificTableUseDetail(int.parse(tableUseDetailObject.table_sqlite_id!));
      if(tableUseDetailData[0].soft_delete == ''){
        _value.add(jsonEncode(tableUseDetailData[0].syncJson()));
      }
    }
    //sync to cloud
    syncTableUseDetailToCloud(_value.toString());
    // Map data = await Domain().SyncTableUseDetailToCloud(_value.toString());
    // if (data['status'] == '1') {
    //   List responseJson = data['data'];
    //   for (var i = 0; i < responseJson.length; i++) {
    //     int syncData = await PosDatabase.instance.updateTableUseDetailSyncStatusFromCloud(responseJson[i]['table_use_detail_key']);
    //   }
    // }
  }

  syncTableUseDetailToCloud(String value) async {
    bool _hasInternetAccess = await Domain().isHostReachable();
    if(_hasInternetAccess){
      Map data = await Domain().SyncTableUseDetailToCloud(value);
      if (data['status'] == '1') {
        List responseJson = data['data'];
        for (var i = 0; i < responseJson.length; i++) {
          int syncData = await PosDatabase.instance.updateTableUseDetailSyncStatusFromCloud(responseJson[i]['table_use_detail_key']);
        }
      }
    }
  }

  updateTable() async {
    DateFormat dateFormat = DateFormat("yyyy-MM-dd HH:mm:ss");
    String dateTime = dateFormat.format(DateTime.now());
    final prefs = await SharedPreferences.getInstance();
    final int? branch_id = prefs.getInt('branch_id');

    List<TableUseDetail> NowUseDetailData = await PosDatabase.instance.readSpecificTableUseDetail(widget.object.table_sqlite_id!);
    List<PosTable> tableData = await PosDatabase.instance.readSpecificTableByTableNo(branch_id!, tableNoController.text);
    List<TableUseDetail> NewUseDetailData = await PosDatabase.instance.readSpecificTableUseDetail(tableData[0].table_sqlite_id!);
    //check new table is in use or not
    if(NewUseDetailData.length > 0){
      await callChangeToTableInUse(NowUseDetailData[0].table_use_sqlite_id!, NewUseDetailData[0].table_use_sqlite_id!, dateTime);
      await updatePosTable(NewUseDetailData[0].table_use_detail_key!, dateTime);

    } else {
      await changeToUnusedTable(widget.object.table_sqlite_id!, tableData[0].table_sqlite_id.toString(), dateTime);
      await updatePosTable(NowUseDetailData[0].table_use_detail_key!, dateTime);

    }
  }

  /**
   * concurrent here
   */
  updatePosTableStatusAndDetailKey(int tableId, int status, String dateTime, String key) async {
    PosTable? _data;
    PosTable posTableObject = PosTable(
      table_use_detail_key: key,
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
  }


  updatePosTable(String key, String dateTime) async {
    print('table updated');
    final prefs = await SharedPreferences.getInstance();
    final int? branch_id = prefs.getInt('branch_id');
    List<String> _value = [];

    List<PosTable> tableData = await PosDatabase.instance.readSpecificTableByTableNo(branch_id!, tableNoController.text);
    //update new table status
    List<PosTable> newTable = await PosDatabase.instance.checkPosTableStatus(branch_id, tableData[0].table_sqlite_id!);
    if (newTable[0].status == 0) {
      PosTable updateNewTableData = await updatePosTableStatusAndDetailKey(tableData[0].table_sqlite_id!, 1, dateTime, key);
      _value.add(jsonEncode(updateNewTableData));
    }
    //update previous table status
    List<PosTable> lastTable = await PosDatabase.instance.checkPosTableStatus(branch_id, widget.object.table_sqlite_id!);
    if (lastTable[0].status == 1) {
      PosTable updatedLastTableData = await updatePosTableStatusAndDetailKey(widget.object.table_sqlite_id!, 0, dateTime, '');
      _value.add(jsonEncode(updatedLastTableData));
    }
    //sync to cloud
    syncUpdatedTableToCloud(_value.toString());
    await _printChangeTableList(lastTable: lastTable[0].number, newTable: newTable[0].number);
    widget.callBack();
    Navigator.of(context).pop();
  }

  syncUpdatedTableToCloud(String value) async {
    bool _hasInternetAccess = await Domain().isHostReachable();
    if(_hasInternetAccess){
      Map response = await Domain().SyncUpdatedPosTableToCloud(value);
      if (response['status'] == '1') {
        List responseJson = response['data'];
        for (var i = 0; i < responseJson.length; i++) {
          int syncData = await PosDatabase.instance.updatePosTableSyncStatusFromCloud(responseJson[i]['table_id']);
        }
      }
    }
  }

  _printChangeTableList({lastTable, newTable}) async {
    try {
      for (int i = 0; i < widget.printerList.length; i++) {
        var printerDetail = jsonDecode(widget.printerList[i].value!);
        if (widget.printerList[i].type == 0) {
          //print USB 80mm
          if (widget.printerList[i].paper_size == 0) {
            var data = Uint8List.fromList(await ReceiptLayout().printChangeTableList80mm(true, fromTable: lastTable, toTable: newTable));
            bool? isConnected = await flutterUsbPrinter.connect(int.parse(printerDetail['vendorId']), int.parse(printerDetail['productId']));
            if (isConnected == true) {
              await flutterUsbPrinter.write(data);
            } else {
              Fluttertoast.showToast(
                  backgroundColor: Colors.red,
                  msg: "${AppLocalizations.of(context)?.translate('usb_printer_not_connect')}");
            }
          } else {
            var data = Uint8List.fromList(await ReceiptLayout().printChangeTableList58mm(true, fromTable: lastTable, toTable: newTable));
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
          if (widget.printerList[i].paper_size == 0) {
            //print LAN 80mm paper
            final profile = await CapabilityProfile.load();
            final printer = NetworkPrinter(PaperSize.mm80, profile);
            final PosPrintResult res = await printer.connect(printerDetail, port: 9100);
            if (res == PosPrintResult.success) {
              await ReceiptLayout().printChangeTableList80mm(false, value: printer, fromTable: lastTable, toTable: newTable);
              printer.disconnect();
            } else {
              Fluttertoast.showToast(
                  backgroundColor: Colors.red,
                  msg: "${AppLocalizations.of(context)?.translate('lan_printer_not_connect')}");
            }
          } else {
            //print LAN 58mm paper
            final profile = await CapabilityProfile.load();
            final printer = NetworkPrinter(PaperSize.mm58, profile);
            final PosPrintResult res = await printer.connect(printerDetail, port: 9100);
            if (res == PosPrintResult.success) {
              await ReceiptLayout().printChangeTableList58mm(false, value: printer, fromTable: lastTable, toTable: newTable);
              printer.disconnect();
            } else {
              Fluttertoast.showToast(
                  backgroundColor: Colors.red,
                  msg: "${AppLocalizations.of(context)?.translate('lan_printer_not_connect')}");
            }
          }
        }
      }
    } catch (e) {
      print('Printer Connection Error: ${e}');
      Fluttertoast.showToast(
          backgroundColor: Colors.red,
          msg: "${AppLocalizations.of(context)?.translate('printing_error')}");
    }
  }

  void _submit(BuildContext context) {
    setState(() => _submitted = true);
    if (errorTableNo == null) {
      updateTable();

    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeColor>(builder: (context, ThemeColor color, child) {
      return AlertDialog(
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
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
          TextButton(
            child: Text("Submit"),
            onPressed: () {
              _submit(context);
            },
          ),
        ],
      );
    });
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
