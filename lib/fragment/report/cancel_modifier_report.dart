import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:syncfusion_flutter_datepicker/datepicker.dart';

import '../../notifier/report_notifier.dart';
import '../../notifier/theme_color.dart';
import '../../object/branch_link_modifier.dart';
import '../../object/modifier_group.dart';
import '../../object/report_class.dart';
import '../../page/progress_bar.dart';

class CancelModifierReport extends StatefulWidget {
  const CancelModifierReport({Key? key}) : super(key: key);

  @override
  State<CancelModifierReport> createState() => _CancelModifierReportState();
}

class _CancelModifierReportState extends State<CancelModifierReport> {
  List<DataRow> _dataRow = [];
  String currentStDate = '';
  String currentEdDate = '';
  bool isLoaded = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeColor>(builder: (context, ThemeColor color, child) {
      return Consumer<ReportModel>(builder: (context, ReportModel reportModel, child) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if(reportModel.load == 0){
            preload(reportModel);
            reportModel.setLoaded();
          }
        });
          return LayoutBuilder(builder: (context, constraints) {
            if (constraints.maxWidth > 800) {
              return Scaffold(
                body: this.isLoaded ?
                Container(
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            child: Text('Cancelled Modifier Report',
                                style: TextStyle(fontSize: 25, color: Colors.black)),
                          ),
                        ],
                      ),
                      SizedBox(height: 5),
                      Divider(
                        height: 10,
                        color: Colors.grey,
                      ),
                      SizedBox(height: 5),
                      _dataRow.isNotEmpty ?
                      Container(
                        margin: EdgeInsets.all(10),
                        child:  isLoaded ?
                        DataTable(
                            border: TableBorder.symmetric(outside: BorderSide(color: Colors.black12)),
                            headingTextStyle: TextStyle(color: Colors.white),
                            headingRowColor: MaterialStateColor.resolveWith((states) {return Colors.black;},),
                            columns: <DataColumn>[
                              DataColumn(
                                label: Expanded(
                                  child: Text(
                                    'Modifier',
                                    style: TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ),
                              DataColumn(
                                label: Expanded(
                                  child: Text(
                                    'Quantity',
                                    style: TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ),
                              DataColumn(
                                label: Expanded(
                                  child: Text(
                                    'Net Sales',
                                    style: TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ),
                            ],
                            rows: _dataRow
                        ) : Center(
                          child: CustomProgressBar(),
                        ),
                      ):
                      Center(
                        heightFactor: 12,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Icon(Icons.menu),
                            Text('NO RECORD FOUND'),
                          ],
                        ),
                      )
                    ],
                  ),
                ) : CustomProgressBar(),
              );
            } else {
              return Scaffold(
                body: this.isLoaded ?
                Container(
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            child: Text('Cancelled Modifier Report',
                                style: TextStyle(fontSize: 25, color: Colors.black)),
                          ),
                        ],
                      ),
                      SizedBox(height: 5),
                      Divider(
                        height: 10,
                        color: Colors.grey,
                      ),
                      SizedBox(height: 5),
                      _dataRow.isNotEmpty ?
                      Container(
                        margin: EdgeInsets.all(10),
                        child:  isLoaded ?
                        DataTable(
                            border: TableBorder.symmetric(outside: BorderSide(color: Colors.black12)),
                            headingTextStyle: TextStyle(color: Colors.white),
                            headingRowColor: MaterialStateColor.resolveWith((states) {return Colors.black;},),
                            columns: <DataColumn>[
                              DataColumn(
                                label: Expanded(
                                  child: Text(
                                    'Modifier',
                                    style: TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ),
                              DataColumn(
                                label: Expanded(
                                  child: Text(
                                    'Quantity',
                                    style: TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ),
                              DataColumn(
                                label: Expanded(
                                  child: Text(
                                    'Net Sales',
                                    style: TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ),
                            ],
                            rows: _dataRow
                        ) : Center(
                          child: CustomProgressBar(),
                        ),
                      ):
                      Center(
                        heightFactor: 4,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Icon(Icons.menu),
                            Text('NO RECORD FOUND'),
                          ],
                        ),
                      )
                    ],
                  ),
                ) : CustomProgressBar(),
              );
            }
          });
        }
      );
    });
  }

  preload(ReportModel reportModel) async {
    this.currentStDate = reportModel.startDateTime;
    this.currentEdDate = reportModel.endDateTime;
    await getAllCancelledModifier();
    if(mounted){
      setState(() {
        isLoaded = true;
      });
    }
  }

  getAllCancelledModifier() async {
    _dataRow.clear();
    List<ModifierGroup> modGroupData = [];
    //List<OrderModifierDetail> modifierData = [];
    ReportObject object = await ReportObject().getAllCancelledModifierGroup(currentStDate: currentStDate, currentEdDate: currentEdDate);
    modGroupData = object.dateModifierGroup!;
    print('modifier group data: ${modGroupData.length}');
    if(modGroupData.isNotEmpty){
      for(int i = 0; i < modGroupData.length; i++){
        ReportObject object = await ReportObject().getAllCancelledOrderModifierDetail(modGroupData[i].mod_group_id.toString(), currentStDate: currentStDate, currentEdDate: currentEdDate);
        modGroupData[i].modDetailList = object.dateModifier!;
        _dataRow.addAll([
          DataRow(
            color: MaterialStateColor.resolveWith((states) {return Colors.grey;},),
            cells: <DataCell>[
              DataCell(
                Text('Group - ${modGroupData[i].name}', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
              DataCell(Text('${modGroupData[i].item_sum}')),
              DataCell(Text('${modGroupData[i].net_sales!.toStringAsFixed(2)}')),
            ],
          ),
          for(int j = 0; j < modGroupData[i].modDetailList.length; j++)
            DataRow(
              cells: <DataCell>[
                DataCell(Text('${modGroupData[i].modDetailList[j].mod_name}')),
                DataCell(Text('${modGroupData[i].modDetailList[j].item_sum}')),
                DataCell(Text('${modGroupData[i].modDetailList[j].net_sales!.toStringAsFixed(2)}')),
              ],
            ),
        ]);
      }
    }
  }
}
