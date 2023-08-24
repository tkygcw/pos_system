import 'package:flutter/material.dart';
import 'package:pos_system/object/order_detail.dart';
import 'package:pos_system/translation/AppLocalizations.dart';
import 'package:pos_system/utils/Utils.dart';
import 'package:provider/provider.dart';
import '../../notifier/report_notifier.dart';
import '../../notifier/theme_color.dart';
import '../../object/report_class.dart';
import '../../page/progress_bar.dart';

class CategoryReport extends StatefulWidget {
  const CategoryReport({Key? key}) : super(key: key);

  @override
  State<CategoryReport> createState() => _CategoryReportState();
}

class _CategoryReportState extends State<CategoryReport> {
  List<DataRow> _dataRow = [];
  //List<Categories> categoryData = [];
  List<OrderDetail> orderDetailCategoryData = [];
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
      return Consumer<ReportModel>(builder: (context, ReportModel reportModel, child){
        WidgetsBinding.instance.addPostFrameCallback((_) {
          print('category preload: ${reportModel.load}');
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
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              child: Text(AppLocalizations.of(context)!.translate('category_report'),
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
                                      AppLocalizations.of(context)!.translate('category'),
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
                                      AppLocalizations.of(context)!.translate('net_sales'),
                                      style: TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ),
                                DataColumn(
                                  label: Expanded(
                                    child: Text(
                                      AppLocalizations.of(context)!.translate('gross_sales'),
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
                              Text(AppLocalizations.of(context)!.translate('no_record_found')),
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
                body: this.isLoaded ?
                Container(
                  padding: const EdgeInsets.all(8),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.vertical,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              child: Text(AppLocalizations.of(context)!.translate('category_report'),
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
                                        AppLocalizations.of(context)!.translate('category'),
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
                                        AppLocalizations.of(context)!.translate('net_sales'),
                                        style: TextStyle(fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ),
                                  DataColumn(
                                    label: Expanded(
                                      child: Text(
                                        AppLocalizations.of(context)!.translate('gross_sales'),
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
                              Text(AppLocalizations.of(context)!.translate('no_record_found')),
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
  }

  preload(ReportModel reportModel) async {
    this.currentStDate = reportModel.startDateTime;
    this.currentEdDate = reportModel.endDateTime;
    await getAllCategory();
    reportModel.addOtherValue(valueList: orderDetailCategoryData);
    // reportModel.addOtherValue(valueList: categoryData);
    if(mounted){
      setState(() {
        isLoaded = true;
      });
    }
  }

  getAllCategory() async {
    _dataRow.clear();
    ReportObject object = await ReportObject().getAllPaidCategory(currentStDate: currentStDate, currentEdDate: currentEdDate);
    orderDetailCategoryData = object.dateOrderDetail!;
    if(orderDetailCategoryData.isNotEmpty){
      for(int i = 0; i < orderDetailCategoryData.length; i++){
        _dataRow.addAll([
          DataRow(
            cells: <DataCell>[
              DataCell(
                Text(AppLocalizations.of(context)!.translate('category')+' - ${orderDetailCategoryData[i].category_name}'),
              ),
              DataCell(Text('${orderDetailCategoryData[i].category_item_sum}')),
              DataCell(Text('${orderDetailCategoryData[i].category_net_sales!.toStringAsFixed(2)}')),
              DataCell(Text('${Utils.to2Decimal(orderDetailCategoryData[i].category_gross_sales!)}')),
            ],
          ),
        ]);
      }
    }
  }

  // getAllCategory() async {
  //   _dataRow.clear();
  //   ReportObject object = await ReportObject().getAllPaidCategory(currentStDate: currentStDate, currentEdDate: currentEdDate);
  //   categoryData = object.dateCategory!;
  //   if(categoryData.isNotEmpty){
  //     for(int i = 0; i < categoryData.length; i++){
  //       _dataRow.addAll([
  //         DataRow(
  //           cells: <DataCell>[
  //             DataCell(
  //               Text('Category - ${categoryData[i].name}'),
  //             ),
  //             DataCell(Text('${categoryData[i].item_sum}')),
  //             DataCell(Text('${categoryData[i].net_sales!.toStringAsFixed(2)}')),
  //             //DataCell(Text('${categoryData[i].gross_sales!.toStringAsFixed(2)}')),
  //             DataCell(Text('${Utils.to2Decimal(categoryData[i].gross_sales!)}')),
  //           ],
  //         ),
  //       ]);
  //     }
  //   }
  // }
}
