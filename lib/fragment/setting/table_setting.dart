import 'package:flutter/material.dart';
import 'package:page_transition/page_transition.dart';
import 'package:pos_system/database/pos_database.dart';
import 'package:pos_system/page/progress_bar.dart';
import 'package:provider/provider.dart';

import '../../notifier/theme_color.dart';
import '../../object/table.dart';
import '../report/print_report_page.dart';

class TableSetting extends StatefulWidget {
  const TableSetting({Key? key}) : super(key: key);

  @override
  State<TableSetting> createState() => _TableSettingState();
}

class _TableSettingState extends State<TableSetting> {
  List<PosTable> tableList = [];
  List<PosTable> checkedTable = [];
  int _maxChecked = 1;
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
            floatingActionButton: FloatingActionButton(
              backgroundColor: color.backgroundColor,
              onPressed: () {
                print('check table list: ${this.checkedTable.length}');
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
          return Scaffold();
        }
      });
    });
  }

  getAllTable() async {
    this._numChecked = 0;
    this.checkedTable.clear();
    List<PosTable> data = await PosDatabase.instance.readAllTable();
    tableList = data;
    setState(() {
      _isLoad = true;
    });

  }
}
