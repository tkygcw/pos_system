import 'dart:convert';

import 'package:circular_menu/circular_menu.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:page_transition/page_transition.dart';
import 'package:pos_system/notifier/theme_color.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../database/pos_database.dart';
import '../../../object/table.dart';
import '../../../page/progress_bar.dart';
import '../../../translation/AppLocalizations.dart';
import '../../report/print_report_page.dart';

class TableSettingMobile extends StatefulWidget {
  final ThemeColor themeColor;
  final Function(List<PosTable> selectedTable, Function() callback) openChooseQrDialog;
  const TableSettingMobile({Key? key, required this.themeColor, required this.openChooseQrDialog}) : super(key: key);

  @override
  State<TableSettingMobile> createState() => _TableSettingMobileState();
}

class _TableSettingMobileState extends State<TableSettingMobile> {
  late Map branchObject;
  bool selectAll = false, _isLoad = false;
  List<PosTable> checkedTable = [];
  List<PosTable> tableList = [];

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    getInitData();
  }

  @override
  Widget build(BuildContext context) {
    ThemeColor color = widget.themeColor;
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        elevation: 0,
        actions: [
          Container(
              padding: EdgeInsets.all(10),
              child: Checkbox(
                activeColor: color.backgroundColor,
                value: selectAll,
                onChanged: (value){
                  setState(() {
                    selectAll = value!;
                  });
                  if(selectAll){
                    for(var table in tableList){
                      print("table is selected: ${table.isSelected}");
                      if(table.isSelected == false){
                        table.isSelected = true;
                        checkedTable.add(table);
                      }
                    }
                  } else {
                    unselectAllTable();
                  }
                },
              )
          )
        ],
      ),
      resizeToAvoidBottomInset: false,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: CircularMenu(
          curve: Curves.decelerate,
          toggleButtonBoxShadow: [],
          toggleButtonColor: color.backgroundColor,
          items: [
            CircularMenuItem(
                color: color.buttonColor,
                boxShadow: [],
                icon: Icons.qr_code_2,
                onTap: () {
                  if(checkedTable.isNotEmpty){
                    widget.openChooseQrDialog(checkedTable, unselectAllTable());
                  } else {
                    Fluttertoast.showToast(
                        backgroundColor: Color(0xFFFF0000),
                        msg: "${AppLocalizations.of(context)?.translate('no_table')}");
                  }
                }),
            CircularMenuItem(
              color: color.buttonColor,
              boxShadow: [],
              icon: Icons.picture_as_pdf,
              onTap: (){
                if(checkedTable.isNotEmpty){
                  Navigator.push(
                    context,
                    PageTransition(
                      type: PageTransitionType.bottomToTop,
                      child: PrintReportPage(
                        currentPage: -1,
                        tableList: checkedTable,
                        callBack: () => setState(() {
                          unselectAllTable();
                        }),
                      ),
                    ),
                  );
                } else {
                  Fluttertoast.showToast(
                      backgroundColor: Color(0xFFFF0000),
                      msg: "${AppLocalizations.of(context)?.translate('no_table')}");
                }
              },
            ),
          ]),
      body: _isLoad ?
      Padding(
          padding: const EdgeInsets.all(8.0),
          child: tableList.isNotEmpty ?
          ListView.builder(
              shrinkWrap: true,
              itemCount: tableList.length,
              itemBuilder: (BuildContext context,int index){
                return Card(
                  elevation: 5,
                  child: CheckboxListTile(
                      value: tableList[index].isSelected,
                      activeColor: color.backgroundColor,
                      title: Text(AppLocalizations.of(context)!.translate('table_no') +': ${tableList[index].number}'),
                      onChanged: (value){
                        setState(() {
                          if(value!){
                            tableList[index].isSelected = true;
                            checkedTable.add(tableList[index]);
                          } else {
                            tableList[index].isSelected = false;
                            checkedTable.remove(tableList[index]);
                          }
                          if(checkedTable.isEmpty){
                            selectAll = false;
                          } else if(checkedTable.length != tableList.length) {
                            selectAll = false;
                          } else {
                            selectAll = true;
                          }
                        });
                      }),
                );
              }
          ) : Stack(
              children: [
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.table_restaurant, size: 36.0),
                      Text(AppLocalizations.of(context)!.translate('no_table_found'), style: TextStyle(fontSize: 24)),
                    ],
                  ),
                ),
              ]
          )
      )
          : CustomProgressBar(),
    );
  }

  unselectAllTable(){
    for(var table in tableList){
      if(table.isSelected == true){
        table.isSelected = false;
      }
    }
    checkedTable.clear();
    selectAll = false;
  }

  getInitData() async {
    await getPref();
    this.checkedTable.clear();
    List<PosTable> data = await PosDatabase.instance.readAllTable();
    tableList = data;
    sortTable();
    setState(() {
      _isLoad = true;
    });
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
        return aNumber.compareTo(bNumber);
      }
    });
  }

  getPref() async {
    final prefs = await SharedPreferences.getInstance();
    final String? branch = prefs.getString('branch');
    branchObject = json.decode(branch!);
  }

}
