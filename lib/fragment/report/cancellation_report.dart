import 'dart:async';

import 'package:flutter/material.dart';
import 'package:pos_system/translation/AppLocalizations.dart';
import 'package:pos_system/utils/Utils.dart';
import 'package:provider/provider.dart';
import '../../notifier/report_notifier.dart';
import '../../notifier/theme_color.dart';
import '../../object/categories.dart';
import '../../object/order_detail.dart';
import '../../object/report_class.dart';
import '../../page/progress_bar.dart';

class CancellationReport extends StatefulWidget {
  const CancellationReport({Key? key}) : super(key: key);

  @override
  State<CancellationReport> createState() => _CancellationReportState();
}

class _CancellationReportState extends State<CancellationReport> {
  StreamController controller = StreamController();
  late Stream contentStream;
  List<DataRow> _dataRow = [];
  List<Categories> categoryData = [];
  List<OrderDetail> orderDetailCategoryData = [];
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
                        resizeToAvoidBottomInset: false,
                        body: Container(
                          padding: const EdgeInsets.all(8),
                          child: SingleChildScrollView(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      child: Text(AppLocalizations.of(context)!.translate('cancellation_report'),
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
                                    child:  SingleChildScrollView(
                                      scrollDirection: Axis.horizontal,
                                      child: DataTable(
                                          border: TableBorder.symmetric(outside: BorderSide(color: Colors.black12)),
                                          headingTextStyle: TextStyle(color: Colors.white),
                                          headingRowColor: MaterialStateColor.resolveWith((states) {return Colors.black;},),
                                          columns: <DataColumn>[
                                            DataColumn(
                                              label: Expanded(
                                                child: Text(
                                                  AppLocalizations.of(context)!.translate('product'),
                                                  style: TextStyle(fontWeight: FontWeight.bold),
                                                ),
                                              ),
                                            ),
                                            DataColumn(
                                              label: Expanded(
                                                child: Text(
                                                  AppLocalizations.of(context)!.translate('variant'),
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
                                                  AppLocalizations.of(context)!.translate('gross_sales'),
                                                  style: TextStyle(fontWeight: FontWeight.bold),
                                                ),
                                              ),
                                            ),
                                            DataColumn(
                                              label: Expanded(
                                                child: Text(
                                                  AppLocalizations.of(context)!.translate('cancel_by'),
                                                  style: TextStyle(fontWeight: FontWeight.bold),
                                                ),
                                              ),
                                            ),
                                          ],
                                          rows: _dataRow
                                      ),
                                    )
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
                        )
                    );
                  } else {
                    return Scaffold(
                      resizeToAvoidBottomInset: false,
                      body: Container(
                        padding: const EdgeInsets.all(8),
                        child: SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    child: Text(AppLocalizations.of(context)!.translate('cancellation_report'),
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
                                              AppLocalizations.of(context)!.translate('product'),
                                              style: TextStyle(fontWeight: FontWeight.bold),
                                            ),
                                          ),
                                        ),
                                        DataColumn(
                                          label: Expanded(
                                            child: Text(
                                              AppLocalizations.of(context)!.translate('variant'),
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
                                              AppLocalizations.of(context)!.translate('gross_sales'),
                                              style: TextStyle(fontWeight: FontWeight.bold),
                                            ),
                                          ),
                                        ),
                                        DataColumn(
                                          label: Expanded(
                                            child: Text(
                                              AppLocalizations.of(context)!.translate('cancel_by'),
                                              style: TextStyle(fontWeight: FontWeight.bold),
                                            ),
                                          ),
                                        ),
                                      ],
                                      rows: _dataRow
                                  ),
                                )
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
                      )
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
    return Scaffold();
  }

  preload(ReportModel reportModel) async {
    this.currentStDate = reportModel.startDateTime;
    this.currentEdDate = reportModel.endDateTime;
    await getAllCancelItemData();
    reportModel.addOtherValue(valueList: orderDetailCategoryData);
    controller.sink.add("refresh");
  }

  getAllCancelItemData() async {
    _dataRow.clear();
    ReportObject object = await ReportObject().getAllCancelItemCategory(currentStDate: currentStDate, currentEdDate: currentEdDate);
    orderDetailCategoryData = object.dateOrderDetail!;
    if(orderDetailCategoryData.isNotEmpty){
      for(int i = 0; i < orderDetailCategoryData.length; i++){
        ReportObject object2 = await ReportObject().getAllCancelOrderDetailWithCategory(orderDetailCategoryData[i].category_name!, currentStDate: currentStDate, currentEdDate: currentEdDate);
        orderDetailCategoryData[i].categoryOrderDetailList = object2.dateOrderDetail!;
        _dataRow.addAll([
          DataRow(
            color: MaterialStateColor.resolveWith((states) {return Colors.grey;},),
            cells: <DataCell>[
              orderDetailCategoryData[i].category_name != '' ?
              DataCell(
                Text(AppLocalizations.of(context)!.translate('category')+' - ${orderDetailCategoryData[i].category_name}', style: TextStyle(fontWeight: FontWeight.bold)),
              ): DataCell(
                Text(AppLocalizations.of(context)!.translate('category_other'), style: TextStyle(fontWeight: FontWeight.bold)),
              ),
              DataCell(Text('')),
              DataCell(Text(orderDetailCategoryData[i].category_item_sum is double ? '${orderDetailCategoryData[i].category_item_sum!.toStringAsFixed(2)}' : '${orderDetailCategoryData[i].category_item_sum}')),
              DataCell(Text('${Utils.to2Decimal(orderDetailCategoryData[i].category_gross_sales!)}')),
              DataCell(Text('')),
            ],
          ),
          for(int j = 0; j < orderDetailCategoryData[i].categoryOrderDetailList.length; j++)
            DataRow(
              cells: <DataCell>[
                DataCell(Text('${orderDetailCategoryData[i].categoryOrderDetailList[j].productName}')),
                DataCell(
                    orderDetailCategoryData[i].categoryOrderDetailList[j].product_variant_name != '' ?
                    Text('${orderDetailCategoryData[i].categoryOrderDetailList[j].product_variant_name}'): Text('-')),
                DataCell(Text(orderDetailCategoryData[i].categoryOrderDetailList[j].item_sum is double ?
                '${orderDetailCategoryData[i].categoryOrderDetailList[j].item_qty}/${orderDetailCategoryData[i].categoryOrderDetailList[j].item_sum!.toStringAsFixed(2)}(${orderDetailCategoryData[i].categoryOrderDetailList[j].unit})' :
                '${orderDetailCategoryData[i].categoryOrderDetailList[j].item_sum}')),
                // DataCell(Text('${categoryData[i].categoryOrderDetailList[j].gross_price!.toStringAsFixed(2)}')),
                DataCell(Text('${Utils.to2Decimal(orderDetailCategoryData[i].categoryOrderDetailList[j].gross_price!)}')),
                DataCell(Text('${orderDetailCategoryData[i].categoryOrderDetailList[j].cancel_by}')),
              ]),
        ]);
      }
    }
  }
}
