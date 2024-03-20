import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';
import 'package:pos_system/database/pos_database.dart';
import 'package:pos_system/fragment/setting/sync_dialog.dart';
import 'package:pos_system/fragment/setting/system_log_dialog.dart';
import 'package:pos_system/object/table.dart';
import 'package:pos_system/page/select_table_dialog.dart';

import '../../main.dart';
import '../../object/table_use.dart';
import '../../object/table_use_detail.dart';
import '../../translation/AppLocalizations.dart';

class DataProcessingSetting extends StatefulWidget {
  const DataProcessingSetting({Key? key}) : super(key: key);

  @override
  State<DataProcessingSetting> createState() => _DataProcessingSettingState();
}

class _DataProcessingSettingState extends State<DataProcessingSetting> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            ListTile(
              title: Text(AppLocalizations.of(context)!.translate('system_log')),
              trailing: Icon(Icons.history),
              onTap: () async {
                openSystemLog();
              },
            ),
            ListTile(
              title: Text(AppLocalizations.of(context)!.translate('sync')),
              trailing: Icon(Icons.sync),
              onTap: () async {
                openSyncDialog();
              },
            ),
            ListTile(
              title: Text(AppLocalizations.of(context)!.translate('sync_reset')),
              trailing: Icon(Icons.refresh),
              onTap: () async {
                syncRecord.count = 0;
                qrOrder.count = 0;
                Fluttertoast.showToast(msg: AppLocalizations.of(context)!.translate('sync_reset_success'));
              },
            ),
            Divider(
              color: Colors.grey,
              height: 1,
              thickness: 1,
              indent: 20,
              endIndent: 20,
            ),
            ListTile(
                title: Text(AppLocalizations.of(context)!.translate('reset_table_data')),
                subtitle: Text(AppLocalizations.of(context)!.translate('reset_table_desc')),
                onTap: (){
                  openSelectTableDialog();
                },
                trailing: Icon(Icons.navigate_next)
            ),
          ],
        ),
      ),
    );
  }

  Future<void> openSelectTableDialog () {
    return showDialog(
      context: context,
      barrierDismissible: false, // user must tap button!
      builder: (BuildContext context) {
        return SelectTableDialog(currentPage: '1',);
      },
    ).then((result){
      if(result != null){
        if(result == 'resetAllTable'){
          resetAllInUsedTableStatus();
        } else {
          resetTableStatus(result);
        }
      }
    });
  }

  resetAllInUsedTableStatus() async {
    DateFormat dateFormat = DateFormat("yyyy-MM-dd HH:mm:ss");
    String dateTime = dateFormat.format(DateTime.now());
    List<PosTable> data = await PosDatabase.instance.readAllTable();
    for(int i = 0; i < data.length; i++){
      PosTable posTable = data[i];
      await resetTableUseDetail(dateTime, posTable);
      await resetTableUse(dateTime, posTable);
      PosTable object = PosTable(
          status: 0,
          table_use_detail_key: '',
          table_use_key: '',
          updated_at: dateTime,
          table_sqlite_id: posTable.table_sqlite_id
      );
      await PosDatabase.instance.resetPosTable(object);
    }
  }

  resetTableStatus(PosTable posTable) async {
    DateFormat dateFormat = DateFormat("yyyy-MM-dd HH:mm:ss");
    String dateTime = dateFormat.format(DateTime.now());
    await resetTableUseDetail(dateTime, posTable);
    await resetTableUse(dateTime, posTable);
    PosTable data = PosTable(
        status: 0,
        table_use_detail_key: '',
        table_use_key: '',
        updated_at: dateTime,
        table_sqlite_id: posTable.table_sqlite_id
    );
    await PosDatabase.instance.resetPosTable(data);
  }

  resetTableUseDetail(String dateTime, PosTable posTable) async {
    TableUseDetail? tableUseDetailData = await PosDatabase.instance.readTableUseDetailByKey(posTable.table_use_detail_key!);
    if(tableUseDetailData != null){
      TableUseDetail detailObject = TableUseDetail(
          status: 1,
          soft_delete: dateTime,
          sync_status: tableUseDetailData.sync_status == 0 ? 0 : 2,
          table_use_detail_key: posTable.table_use_detail_key
      );
      await PosDatabase.instance.deleteTableUseDetailByKey(detailObject);
    }
  }

  resetTableUse(String dateTime, PosTable posTable) async {
    List<TableUseDetail> checkData = await PosDatabase.instance.readTableUseDetailByTableUseKey(posTable.table_use_key!);
    //check is current table is merged table or not
    if(checkData.isEmpty){
      TableUse? tableUseData = await PosDatabase.instance.readSpecificTableUseByKey2(posTable.table_use_key!);
      if(tableUseData != null){
        TableUse object = TableUse(
            status: 1,
            soft_delete: dateTime,
            sync_status: tableUseData.sync_status == 0 ? 0 : 2,
            table_use_key: posTable.table_use_key
        );
        await PosDatabase.instance.deleteTableUseByKey(object);
      }
    }
  }

  Future<Future<Object?>> openSystemLog() async {
    return showGeneralDialog(
        barrierColor: Colors.black.withOpacity(0.5),
        transitionBuilder: (context, a1, a2, widget) {
          final curvedValue = Curves.easeInOutBack.transform(a1.value) - 1.0;
          return Transform(
            transform: Matrix4.translationValues(0.0, curvedValue * 200, 0.0),
            child: Opacity(
              opacity: a1.value,
              child: SystemLogDialog(),
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

  Future<Future<Object?>> openSyncDialog() async {
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
}
