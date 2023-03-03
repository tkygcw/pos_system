import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:syncfusion_flutter_datepicker/datepicker.dart';

import '../../notifier/report_notifier.dart';
import '../../notifier/theme_color.dart';
import '../../object/categories.dart';
import '../../object/report_class.dart';
import '../../page/progress_bar.dart';

class CancellationReport extends StatefulWidget {
  const CancellationReport({Key? key}) : super(key: key);

  @override
  State<CancellationReport> createState() => _CancellationReportState();
}

class _CancellationReportState extends State<CancellationReport> {
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
                resizeToAvoidBottomInset: false,
                body: this.isLoaded ?
                Container(
                  padding: const EdgeInsets.all(8),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              child: Text('Cancellation Report',
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
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: DataTable(
                                border: TableBorder.symmetric(outside: BorderSide(color: Colors.black12)),
                                headingTextStyle: TextStyle(color: Colors.white),
                                headingRowColor: MaterialStateColor.resolveWith((states) {return Colors.black;},),
                                columns: <DataColumn>[
                                  DataColumn(
                                    label: Expanded(
                                      child: Text(
                                        'Product',
                                        style: TextStyle(fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ),
                                  DataColumn(
                                    label: Expanded(
                                      child: Text(
                                        'Variant',
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
                                  DataColumn(
                                    label: Expanded(
                                      child: Text(
                                        'Cancel By',
                                        style: TextStyle(fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ),
                                ],
                                rows: _dataRow
                            ),
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
                  ),
                ) : CustomProgressBar(),
              );
            } else {
              return Scaffold(
                resizeToAvoidBottomInset: false,
                body: this.isLoaded ?
                Container(
                  padding: const EdgeInsets.all(8),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              child: Text('Cancellation Report',
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
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: DataTable(
                                border: TableBorder.symmetric(outside: BorderSide(color: Colors.black12)),
                                headingTextStyle: TextStyle(color: Colors.white),
                                headingRowColor: MaterialStateColor.resolveWith((states) {return Colors.black;},),
                                columns: <DataColumn>[
                                  DataColumn(
                                    label: Expanded(
                                      child: Text(
                                        'Product',
                                        style: TextStyle(fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ),
                                  DataColumn(
                                    label: Expanded(
                                      child: Text(
                                        'Variant',
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
                                  DataColumn(
                                    label: Expanded(
                                      child: Text(
                                        'Cancel By',
                                        style: TextStyle(fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ),
                                ],
                                rows: _dataRow
                            ),
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
                  ),
                ) : CustomProgressBar(),
              );
            }
          });
        }
      );
    });
    return Scaffold();
  }

  preload(ReportModel reportModel) async {
    this.currentStDate = reportModel.startDateTime;
    this.currentEdDate = reportModel.endDateTime;
    await getAllCancelItemData();
    if(mounted){
      setState(() {
        isLoaded = true;
      });
    }
  }

  getAllCancelItemData() async {
    _dataRow.clear();
    List<Categories> categoryData = [];
    ReportObject object = await ReportObject().getAllCancelItemCategory(currentStDate: currentStDate, currentEdDate: currentEdDate);
    categoryData = object.dateCategory!;
    print('date category data: ${categoryData.length}');
    if(categoryData.isNotEmpty){
      for(int i = 0; i < categoryData.length; i++){
        ReportObject object = await ReportObject().getAllCancelOrderDetailWithCategory(categoryData[i].category_sqlite_id!, currentStDate: currentStDate, currentEdDate: currentEdDate);
        categoryData[i].categoryOrderDetailList = object.dateOrderDetail!;
        print('date detail data: ${categoryData[i].categoryOrderDetailList.length}');
        _dataRow.addAll([
          DataRow(
            color: MaterialStateColor.resolveWith((states) {return Colors.grey;},),
            cells: <DataCell>[
              DataCell(
                Text('Category - ${categoryData[i].name}'),
              ),
              DataCell(Text('')),
              DataCell(Text('${categoryData[i].item_sum}')),
              DataCell(Text('${categoryData[i].net_sales!.toStringAsFixed(2)}')),
              DataCell(Text('${categoryData[i].gross_sales!.toStringAsFixed(2)}')),
              DataCell(Text('')),
            ],
          ),
          for(int j = 0; j < categoryData[i].categoryOrderDetailList.length; j++)
            DataRow(
              cells: <DataCell>[
                DataCell(Text('${categoryData[i].categoryOrderDetailList[j].productName}')),
                DataCell(
                    categoryData[i].categoryOrderDetailList[j].product_variant_name != '' ?
                    Text('${categoryData[i].categoryOrderDetailList[j].product_variant_name}'): Text('-')),
                DataCell(Text('${categoryData[i].categoryOrderDetailList[j].item_sum}')),
                DataCell(Text('${categoryData[i].categoryOrderDetailList[j].double_price!.toStringAsFixed(2)}')),
                DataCell(Text('${categoryData[i].categoryOrderDetailList[j].gross_price!.toStringAsFixed(2)}')),
                DataCell(Text('${categoryData[i].categoryOrderDetailList[j].cancel_by}')),
              ],
            ),
        ]);
      }
    }
  }
}
