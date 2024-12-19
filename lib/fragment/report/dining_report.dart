import 'dart:async';

import 'package:flutter/material.dart';
import 'package:pos_system/object/order.dart';
import 'package:pos_system/translation/AppLocalizations.dart';
import 'package:pos_system/utils/Utils.dart';
import 'package:provider/provider.dart';

import '../../notifier/report_notifier.dart';
import '../../notifier/theme_color.dart';
import '../../object/report_class.dart';
import '../../page/progress_bar.dart';

class DiningReport extends StatefulWidget {
  const DiningReport({Key? key}) : super(key: key);

  @override
  State<DiningReport> createState() => _DiningReportState();
}

class _DiningReportState extends State<DiningReport> {
  StreamController controller = StreamController();
  late Stream contentStream;
  List<DataRow> _dataRow = [];
  List<Order> diningList = [];
  String currentStDate = '';
  String currentEdDate = '';

  @override
  void initState() {
    super.initState();
    contentStream = controller.stream.asBroadcastStream();
  }


  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeColor>(builder: (context, ThemeColor color, child) {
      return Consumer<ReportModel>(builder: (context, ReportModel reportModel, child) {
        preload(reportModel);
          return StreamBuilder(
            stream: contentStream,
            builder: (context, snapshot) {
              if(snapshot.hasData){
                return LayoutBuilder(builder: (context, constraints) {
                  if (constraints.maxWidth > 800) {
                    return Scaffold(
                      body: Container(
                          padding: const EdgeInsets.all(8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    child: Text(AppLocalizations.of(context)!.translate('dining_report'),
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
                                child: DataTable(
                                    border: TableBorder.symmetric(outside: BorderSide(color: Colors.black12)),
                                    headingTextStyle: TextStyle(color: Colors.white),
                                    headingRowColor: MaterialStateColor.resolveWith((states) {return Colors.black;},),
                                    columns: <DataColumn>[
                                      DataColumn(
                                        label: Expanded(
                                          child: Text(
                                            AppLocalizations.of(context)!.translate('dining_option'),
                                            style: TextStyle(fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                      ),
                                      DataColumn(
                                        label: Expanded(
                                          child: Text(AppLocalizations.of(context)!.translate('quantity'),
                                            style: TextStyle(fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                      ),
                                      DataColumn(
                                        label: Expanded(
                                          child: Text(
                                            AppLocalizations.of(context)!.translate('total_sales'),
                                            style: TextStyle(fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                      ),
                                    ],
                                    rows: _dataRow
                                ),
                              ):
                              Center(
                                heightFactor: 12,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Icon(Icons.menu),
                                    Text(AppLocalizations.of(context)!.translate('no_record_found')),
                                  ],
                                ),
                              )
                            ],
                          )
                      ),
                    );
                  } else {
                    return Scaffold(
                      body: SingleChildScrollView(
                        child: Container(
                            padding: const EdgeInsets.all(8),
                            child:  Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      child: Text(AppLocalizations.of(context)!.translate('dining_report'),
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
                                  child: SingleChildScrollView(
                                    scrollDirection: Axis.horizontal,
                                    child: DataTable(
                                        border: TableBorder.symmetric(outside: BorderSide(color: Colors.black12)),
                                        headingTextStyle: TextStyle(color: Colors.white),
                                        headingRowColor: MaterialStateColor.resolveWith((states) {return Colors.black;},),
                                        columns: <DataColumn>[
                                          DataColumn(
                                            label: Expanded(
                                              child: Text(
                                                AppLocalizations.of(context)!.translate('dining_option'),
                                                style: TextStyle(fontWeight: FontWeight.bold),
                                              ),
                                            ),
                                          ),
                                          DataColumn(
                                            label: Expanded(
                                              child: Text(AppLocalizations.of(context)!.translate('quantity'),
                                                style: TextStyle(fontWeight: FontWeight.bold),
                                              ),
                                            ),
                                          ),
                                          DataColumn(
                                            label: Expanded(
                                              child: Text(
                                                AppLocalizations.of(context)!.translate('total_sales'),
                                                style: TextStyle(fontWeight: FontWeight.bold),
                                              ),
                                            ),
                                          ),
                                        ],
                                        rows: _dataRow
                                    ),
                                  ),
                                ):
                                Center(
                                  heightFactor: 4,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: [
                                      Icon(Icons.menu),
                                      Text(AppLocalizations.of(context)!.translate('no_record_found')),
                                    ],
                                  ),
                                )
                              ],
                            )
                        ),
                      ),
                    );
                  }
                });
              } else {
                return CustomProgressBar();
              }
            }
          );
        }
      );
    });
  }

  preload(ReportModel reportModel) async {
    this.currentStDate = reportModel.startDateTime;
    this.currentEdDate = reportModel.endDateTime;
    await getAllPaidDining();
    reportModel.addOtherValue(valueList: diningList);
    controller.sink.add("refresh");
  }

  getAllPaidDining() async {
    _dataRow.clear();
    ReportObject object = await ReportObject().getAllPaidDiningData(currentStDate: currentStDate, currentEdDate: currentEdDate);
    diningList = object.dateDining!;
    //print('dining data: ${modifierData.length}');
    if(diningList.isNotEmpty){
      for(int i = 0; i < diningList.length; i++){
        _dataRow.addAll([
          DataRow(
            cells: <DataCell>[
              DataCell(
                Text('${diningList[i].dining_name}'),
              ),
              DataCell(Text('${diningList[i].item_sum}')),
              // DataCell(Text('${diningList[i].gross_sales!.toStringAsFixed(2)}')),
              DataCell(Text(diningList[i].gross_sales!.toStringAsFixed(2))),
            ],
          ),
        ]);
      }
    }
  }
}
