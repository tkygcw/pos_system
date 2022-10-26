import 'package:flutter/material.dart';
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
import '../../translation/AppLocalizations.dart';

class TableChangeDialog extends StatefulWidget {
  final PosTable object;
  final Function() callBack;
  const TableChangeDialog(
      {Key? key, required this.object, required this.callBack})
      : super(key: key);

  @override
  State<TableChangeDialog> createState() => _TableChangeDialogState();
}

class _TableChangeDialogState extends State<TableChangeDialog> {
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
/*
 taylor part
*/
  // void updateOrderCache() async {
  //   DateFormat dateFormat = DateFormat("yyyy-MM-dd HH:mm:ss");
  //   String dateTime = dateFormat.format(DateTime.now());
  //   final prefs = await SharedPreferences.getInstance();
  //   final int? branch_id = prefs.getInt('branch_id');
  //   List<PosTable> tableData = await PosDatabase.instance
  //       .readSpecificTableByTableNo(branch_id!, tableNoController.text);
  //   for (int i = 0; i < orderCacheList.length; i++) {
  //     Map responseUpdateOrderCache = await Domain().editOrderCache(
  //         orderCacheList[i].order_cache_id.toString(),
  //         tableData[0].table_id.toString());
  //     if (responseUpdateOrderCache['status'] == '1') {
  //       int data = await PosDatabase.instance.updateOrderCacheTableID(
  //           OrderCache(
  //               order_cache_id: orderCacheList[i].order_cache_id,
  //               table_id: tableData[0].table_id.toString(),
  //               updated_at: dateTime));
  //     }
  //   }
  // }
/*
  taylor part
*/
  // updatePosTable() async {
  //   print('table updated');
  //   DateFormat dateFormat = DateFormat("yyyy-MM-dd HH:mm:ss");
  //   String dateTime = dateFormat.format(DateTime.now());
  //   final prefs = await SharedPreferences.getInstance();
  //   final int? branch_id = prefs.getInt('branch_id');
  //
  //   List<PosTable> tableData = await PosDatabase.instance
  //       .readSpecificTableByTableNo(branch_id!, tableNoController.text);
  //   List<PosTable> newTable = await PosDatabase.instance
  //       .checkPosTableStatus(branch_id, tableData[0].table_id!);
  //   if (newTable[0].status == 0) {
  //     Map responseChangeTableStatus =
  //         await Domain().editTableStatus('1', tableData[0].table_id.toString());
  //     if (responseChangeTableStatus['status'] == '1') {
  //       PosTable posTableData = PosTable(
  //           table_id: tableData[0].table_id!, status: 1, updated_at: dateTime);
  //       int data =
  //           await PosDatabase.instance.updatePosTableStatus(posTableData);
  //     }
  //   }
  //
  //   List<PosTable> lastTable = await PosDatabase.instance
  //       .checkPosTableStatus(branch_id, widget.object.table_id!);
  //   if (lastTable[0].status == 1) {
  //     Map responseChangeTableStatus = await Domain()
  //         .editTableStatus('0', widget.object.table_id.toString());
  //     if (responseChangeTableStatus['status'] == '1') {
  //       PosTable posTableData = PosTable(
  //           table_id: widget.object.table_id, status: 0, updated_at: dateTime);
  //       int data2 =
  //           await PosDatabase.instance.updatePosTableStatus(posTableData);
  //     }
  //   }
  //   widget.callBack();
  //   Navigator.of(context).pop();
  // }
/*
leow part
*/
  callChangeToTableInUse(String currentTableUseId, String NewTableUseId, String dateTime) async {
    await updateOrderCache(currentTableUseId, NewTableUseId, dateTime);
    await deleteCurrentTableUseDetail(currentTableUseId, dateTime);
    await deleteCurrentTableUseId(int.parse(currentTableUseId), dateTime);
  }
  /**
   * concurrent here
   */
  changeToUnusedTable(String table_id, String dateTime) async {
    int tableUseDetailData = await PosDatabase.instance.updateTableUseDetail(
        widget.object.table_sqlite_id!,
        TableUseDetail(
            table_sqlite_id: table_id,
            updated_at: dateTime
        ));
  }

  updateTableUse() async {
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

    } else {
      await changeToUnusedTable(tableData[0].table_sqlite_id.toString(), dateTime);

    }
  }

  /**
   * concurrent here
   */
  updatePosTableStatus(int tableId, int status, String dateTime) async {
    PosTable posTableData = PosTable(status: status, updated_at: dateTime, table_sqlite_id: tableId, );
    int data2 = await PosDatabase.instance.updatePosTableStatus(posTableData);
  }

  updatePosTable() async {
    print('table updated');
    DateFormat dateFormat = DateFormat("yyyy-MM-dd HH:mm:ss");
    String dateTime = dateFormat.format(DateTime.now());
    final prefs = await SharedPreferences.getInstance();
    final int? branch_id = prefs.getInt('branch_id');

    List<PosTable> tableData = await PosDatabase.instance
        .readSpecificTableByTableNo(branch_id!, tableNoController.text);
    //update new table status
    List<PosTable> newTable = await PosDatabase.instance
        .checkPosTableStatus(branch_id, tableData[0].table_sqlite_id!);
    if (newTable[0].status == 0) {
      updatePosTableStatus(tableData[0].table_sqlite_id!, 1, dateTime);
    }
    //update previous table status
    List<PosTable> lastTable = await PosDatabase.instance
        .checkPosTableStatus(branch_id, widget.object.table_sqlite_id!);
    if (lastTable[0].status == 1) {
      updatePosTableStatus(widget.object.table_sqlite_id!, 0, dateTime);
    }
    widget.callBack();
    Navigator.of(context).pop();
  }

  void _submit(BuildContext context) {
    setState(() => _submitted = true);
    if (errorTableNo == null) {
      updateTableUse();
      updatePosTable();
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

  updateOrderCache(String currentTableUseId, String NewTableUseId, String dateTime) async {
    try{
      int orderCacheData = await PosDatabase.instance.updateOrderCacheTableUseId(
          currentTableUseId,
          OrderCache(
              table_use_sqlite_id: NewTableUseId,
              updated_at: dateTime
          ));
    } catch(e){
      Fluttertoast.showToast(
          backgroundColor: Color(0xFFFF0000),
          msg: "Update order cache table use id error: ${e}");
    }
  }

  deleteCurrentTableUseDetail(String currentTableUseId, String dateTime) async {
    DateFormat dateFormat = DateFormat("yyyy-MM-dd HH:mm:ss");
    String dateTime = dateFormat.format(DateTime.now());

    try{
      int tableUseDetailData = await PosDatabase.instance.deleteTableUseDetail(
          TableUseDetail(
              soft_delete: dateTime,
              table_use_sqlite_id: currentTableUseId,
          ));
    } catch(e){
      Fluttertoast.showToast(
          backgroundColor: Color(0xFFFF0000),
          msg: "Delete current table use detail error: $e");
    }
  }

  deleteCurrentTableUseId(int currentTableUseId, String dateTime) async {
    DateFormat dateFormat = DateFormat("yyyy-MM-dd HH:mm:ss");
    String dateTime = dateFormat.format(DateTime.now());

    try{
      int tableUseData = await PosDatabase.instance.deleteTableUseID(
          TableUse(
            soft_delete: dateTime,
            table_use_sqlite_id: currentTableUseId,
          ));
    }catch(e){
      Fluttertoast.showToast(
          backgroundColor: Color(0xFFFF0000),
          msg: "Delete current table use id error: ${e}");
    }
  }


}
