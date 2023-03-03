
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pos_system/object/branch_link_dining_option.dart';
import 'package:pos_system/object/order.dart';
import 'package:provider/provider.dart';
import 'package:syncfusion_flutter_datepicker/datepicker.dart';

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
                body: Container(
                  padding: const EdgeInsets.all(8),
                  child: this.isLoaded ?
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            child: Text('Dining Report',
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
                                    'Dining Option',
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
                              DataColumn(
                                label: Expanded(
                                  child: Text(
                                    'Gross Sales',
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
                            Text('NO RECORD FOUND'),
                          ],
                        ),
                      )
                    ],
                  ) : CustomProgressBar(),
                ),
              );
            } else {
              return Scaffold(
                body: SingleChildScrollView(
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    child: this.isLoaded ?
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              child: Text('Dining Report',
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
                                        'Dining Option',
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
                                  DataColumn(
                                    label: Expanded(
                                      child: Text(
                                        'Gross Sales',
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
                              Text('NO RECORD FOUND'),
                            ],
                          ),
                        )
                      ],
                    ) : CustomProgressBar(),
                  ),
                ),
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
    await getAllPaidDining();
    if(mounted){
      setState(() {
        isLoaded = true;
      });
    }
  }

  getAllPaidDining() async {
    _dataRow.clear();
    List<Order> diningList = [];
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
              DataCell(Text('${diningList[i].net_sales!.toStringAsFixed(2)}')),
              DataCell(Text('${diningList[i].gross_sales!.toStringAsFixed(2)}')),
            ],
          ),
        ]);
      }
    }
  }
}
