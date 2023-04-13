import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:page_transition/page_transition.dart';
import 'package:pos_system/database/pos_database.dart';
import 'package:pos_system/page/progress_bar.dart';
import 'package:provider/provider.dart';

import '../../notifier/theme_color.dart';
import '../../object/table.dart';
import '../../translation/AppLocalizations.dart';
import '../report/print_report_page.dart';

class TableSetting extends StatefulWidget {
  const TableSetting({Key? key}) : super(key: key);

  @override
  State<TableSetting> createState() => _TableSettingState();
}

class _TableSettingState extends State<TableSetting> {
  List<PosTable> tableList = [];
  List<PosTable> checkedTable = [];
  int _maxChecked = 4;
  int _numChecked = 0;
  bool _isLoad = false;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    getAllTable();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeColor>(builder: (context, ThemeColor color, child) {
      return LayoutBuilder(builder: (context,  constraints) {
        if(constraints.maxWidth > 800) {
          return Scaffold(
            resizeToAvoidBottomInset: false,
            floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
            floatingActionButton: FloatingActionButton(
              backgroundColor: color.backgroundColor,
              onPressed: () {
                if(checkedTable.isNotEmpty){
                  Navigator.push(
                    context,
                    PageTransition(
                      type: PageTransitionType.bottomToTop,
                      child: PrintReportPage(
                          currentPage: -1,
                          tableList: this.checkedTable,
                          callBack: () => getAllTable(),
                      ),
                    ),
                  );
                } else {
                  Fluttertoast.showToast(
                      backgroundColor: Color(0xFFFF0000),
                      msg: "${AppLocalizations.of(context)?.translate('no_table')}");
                }
              },
              tooltip: "Print QR",
              child: const Icon(Icons.print),
            ),
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
                          title: Text('Table NO: ${tableList[index].number}'),
                          onChanged: (value){
                            setState(() {
                              if (value!) {
                                if (_numChecked < _maxChecked) {
                                  tableList[index].isSelected = true;
                                  _numChecked++;
                                  checkedTable.add(tableList[index]);
                                } else {
                                  // Prevent the user from checking more checkboxes
                                  tableList[index].isSelected = false;
                                }
                              } else {
                                tableList[index].isSelected = false;
                                _numChecked--;
                                checkedTable.remove(tableList[index]);
                              }
                              print('check list: ${checkedTable.length}');
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
                          Text('NO TABLE FOUND', style: TextStyle(fontSize: 24)),
                        ],
                      ),
                    ),
                  ]
              ),
            )
                : CustomProgressBar(),
          );
        } else {
          ///mobile view
          return Scaffold(
            resizeToAvoidBottomInset: false,
            floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
            floatingActionButton: FloatingActionButton(
              elevation: 5,
              backgroundColor: color.backgroundColor,
              onPressed: () {
                if(checkedTable.isNotEmpty){
                  Navigator.push(
                    context,
                    PageTransition(
                      type: PageTransitionType.bottomToTop,
                      child: PrintReportPage(
                        currentPage: -1,
                        tableList: this.checkedTable,
                        callBack: () => getAllTable(),
                      ),
                    ),
                  );
                } else {
                  Fluttertoast.showToast(
                      backgroundColor: Color(0xFFFF0000),
                      msg: "${AppLocalizations.of(context)?.translate('no_table')}");
                }
              },
              tooltip: "Print QR",
              child: const Icon(Icons.print),
            ),
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
                          title: Text('Table NO: ${tableList[index].number}'),
                          onChanged: (value){
                            setState(() {
                              if (value!) {
                                if (_numChecked < _maxChecked) {
                                  tableList[index].isSelected = true;
                                  _numChecked++;
                                  checkedTable.add(tableList[index]);
                                } else {
                                  // Prevent the user from checking more checkboxes
                                  tableList[index].isSelected = false;
                                }
                              } else {
                                tableList[index].isSelected = false;
                                _numChecked--;
                                checkedTable.remove(tableList[index]);
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
                          Text('NO TABLE FOUND', style: TextStyle(fontSize: 24)),
                        ],
                      ),
                    ),
                  ]
              ),
            )
                : CustomProgressBar(),
          );
        }
      });
    });
  }

  getAllTable() async {
    this._numChecked = 0;
    this.checkedTable.clear();
    List<PosTable> data = await PosDatabase.instance.readAllTable();
    tableList = data;
    print('my table: ${tableList[0].table_url}');
    setState(() {
      _isLoad = true;
    });

  }
}
