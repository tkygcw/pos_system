import 'dart:async';

import 'package:collection/collection.dart';
import 'package:confirm_dialog/confirm_dialog.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pos_system/page/progress_bar.dart';
import 'package:provider/provider.dart';

import '../database/pos_database.dart';
import '../notifier/theme_color.dart';
import '../object/order_cache.dart';
import '../object/table.dart';
import '../object/table_use.dart';
import '../object/table_use_detail.dart';
import '../translation/AppLocalizations.dart';

class SelectTableDialog extends StatefulWidget {
  final String currentPage;
  const SelectTableDialog({Key? key, required this.currentPage}) : super(key: key);

  @override
  State<SelectTableDialog> createState() => _SelectTableDialogState();
}

class _SelectTableDialogState extends State<SelectTableDialog> {
  StreamController controller = StreamController();
  late Stream contentStream;
  List<PosTable> tableList = [];
  bool showResetAllButton = false, showTotalAmount = false, showTableGroup = false;

  @override
  void initState() {
    // TODO: implement initState
    initData();
    super.initState();
  }

  initData() async {
    contentStream = controller.stream;
    await getBranchTable();
    await getCurrentPage();
    controller.sink.add("refresh");
  }

  getCurrentPage(){
    switch(widget.currentPage){
      case '1': {
        showResetAllButton = true;
      }break;
      default: {
        showTotalAmount= false;
        showTableGroup = false;
        showResetAllButton = false;
      }
    }
  }

  getBranchTable() async {
    tableList = await PosDatabase.instance.readAllTable();
    if(widget.currentPage != '1'){
      await readAllTableAmount();
    }
    sortTable();
  }

  readAllTableAmount() async {
    double tableAmount = 0.0;
    for (int i = 0; i < tableList.length; i++) {
      if(tableList[i].status == 1){
        List<TableUseDetail> tableUseDetailData = await PosDatabase.instance.readSpecificTableUseDetail(tableList[i].table_sqlite_id!);

        if (tableUseDetailData.isNotEmpty) {
          List<OrderCache> data = await PosDatabase.instance.readTableOrderCache(tableUseDetailData[0].table_use_key!);

          tableList[i].group = data[0].table_use_sqlite_id;
          tableList[i].card_color = data[0].card_color;

          for (int j = 0; j < data.length; j++) {
            tableAmount += double.parse(data[j].total_amount!);
          }
          tableList[i].total_amount = tableAmount.toStringAsFixed(2);

        }
      }
    }
  }

  sortTable(){
    tableList.sort((a, b) {
      final aNumber = a.number!;
      final bNumber = b.number!;

      bool isANumeric = int.tryParse(aNumber) != null;
      bool isBNumeric = int.tryParse(bNumber) != null;

      if (isANumeric && isBNumeric) {
        return int.parse(aNumber).compareTo(int.parse(bNumber));
      } else if (isANumeric) {
        return -1; // Numeric before alphanumeric
      } else if (isBNumeric) {
        return 1; // Alphanumeric before numeric
      } else {
        // Custom alphanumeric sorting logic
        return compareNatural(aNumber, bNumber);
      }
    });
  }

  toColor(String hex) {
    var hexColor = hex.replaceAll("#", "");
    if (hexColor.length == 6) {
      hexColor = "FF" + hexColor;
    }
    if (hexColor.length == 8) {
      return Color(int.parse("0x$hexColor"));
    }
  }

  fontColor({required PosTable posTable}){
    try{
      if(posTable.status == 1 && showTableGroup){
        Color fontColor = Colors.black;
        Color backgroundColor = toColor(posTable.card_color!);
        if(backgroundColor.computeLuminance() > 0.5){
          fontColor = Colors.black;
        } else {
          fontColor = Colors.white;
        }
        return fontColor;
      }
    }catch(e){
      print("error pos table: ${posTable.number}");
      print("error: $e");
      print("open a error dialog ask user want to reset which table");
      return Colors.black;
      //resetTableStatus(posTable);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeColor>(builder: (context, ThemeColor color, child) {
      return StreamBuilder(
        stream: contentStream,
        builder: (context, snapshot){
          if(snapshot.hasData){
            return AlertDialog(
              title: Row(
                children: [
                  Text(AppLocalizations.of(context)!.translate('select_table')),
                  Visibility(
                    visible: showResetAllButton ? true : false,
                    child: Container(
                      padding: EdgeInsets.only(left: 15.0),
                      child: ElevatedButton.icon(
                          onPressed: () async {
                            if (await confirm(
                              context,
                              title: Text(AppLocalizations.of(context)!.translate('confirm_reset_all_table')),
                              content: Text(AppLocalizations.of(context)!.translate('confirm_reset_all_table_desc')),
                              textOK: Text('${AppLocalizations.of(context)?.translate('yes')}'),
                              textCancel: Text('${AppLocalizations.of(context)?.translate('no')}'),
                            )) {
                              Navigator.of(context).pop("resetAllTable");
                            }
                          },
                          icon: Icon(Icons.restart_alt),
                          label: Text(AppLocalizations.of(context)!.translate('reset_all_table'))),
                    ),
                  ),
                  Spacer(),
                  IconButton(
                      constraints: BoxConstraints(),
                      color: Colors.redAccent,
                      visualDensity: VisualDensity.comfortable,
                      onPressed: (){
                        Navigator.of(context).pop();
                      },
                      icon: Icon(Icons.close))
                ],
              ),
              content: Container(
                width: MediaQuery.of(context).size.width / 2,
                child: GridView.count(
                  shrinkWrap: true,
                  crossAxisCount: 4,
                  children: List.generate(
                      tableList.length, (index) {
                    return Card(
                      color: getColor(tableList[index]),
                      elevation: 5,
                      child: InkWell(
                        splashColor: Colors.blue.withAlpha(30),
                        onTap: () async {
                          switch(widget.currentPage){
                            case '1': {
                              await resetTableFunction(tableList[index]);
                            }break;
                            default: {
                              Navigator.of(context).pop(tableList[index]);
                            }
                          }
                        },
                        child: Container(
                          margin: EdgeInsets.all(10),
                          child: Container(
                            height: 100,
                            child: Stack(
                              children: [
                                Visibility(
                                  visible: showTableGroup ? true : false,
                                  child: Container(
                                      alignment: Alignment.topCenter,
                                      child: Container(
                                        padding: EdgeInsets.only(right: 5.0, left: 5.0),
                                        decoration: BoxDecoration(
                                            color: tableList[index].group != null ?
                                            toColor(tableList[index].card_color!) :
                                            Colors.white,
                                            borderRadius: BorderRadius.circular(5.0)
                                        ),
                                        child: Text(
                                          AppLocalizations.of(context)!.translate('group')+": ${tableList[index].group}",
                                          style:
                                          TextStyle(fontSize: 14, color: fontColor(posTable: tableList[index])),
                                        ),
                                      )),
                                ),
                                tableList[index].seats == '2' ?
                                Container(
                                  decoration: BoxDecoration(
                                    image: DecorationImage(
                                      image: AssetImage("drawable/two-seat.jpg"),
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ) :
                                tableList[index].seats == '4' ?
                                Container(
                                  decoration: BoxDecoration(
                                    image: DecorationImage(
                                      image: AssetImage("drawable/four-seat.jpg"),
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ) :
                                tableList[index].seats == '6' ?
                                Container(
                                  decoration: BoxDecoration(
                                    image: DecorationImage(
                                      image: AssetImage("drawable/six-seat.jpg"),
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ) : SizedBox.shrink(),
                                Container(
                                    alignment: Alignment.center,
                                    child: Text(tableList[index].number!)),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ),
            );

          } else {
            return CustomProgressBar();
          }
        },
      );
    });
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

  getColor(PosTable posTable){
    if(widget.currentPage == '1' && posTable.status == 1){
      return Colors.redAccent;
    } else {
      return null;
    }
  }

  resetTableFunction(PosTable posTable) async {
    if (await confirm(
      context,
      title: Text('${AppLocalizations.of(context)!.translate('confirm_reset_table_no')}: ${posTable.number}'),
      content: getContent(posTable),
      textOK: Text('${AppLocalizations.of(context)?.translate('yes')}'),
      textCancel: Text('${AppLocalizations.of(context)?.translate('no')}'),
    )) {
      await resetTableStatus(posTable);
      await getBranchTable();
      controller.sink.add("refresh");
      // Navigator.of(context).pop(posTable);
    }
  }

  getContent(PosTable posTable){
    if(posTable.status == 1){
      return Text(AppLocalizations.of(context)!.translate('confirm_reset_table_no_desc'));
    } else {
      return Text(AppLocalizations.of(context)!.translate('confirm_reset_table_no_desc_2'));
    }
  }

}
