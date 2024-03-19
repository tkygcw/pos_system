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

class ProductEditedReport extends StatefulWidget {
  const ProductEditedReport({Key? key}) : super(key: key);

  @override
  State<ProductEditedReport> createState() => _ProductEditedReportState();
}

class _ProductEditedReportState extends State<ProductEditedReport> {
  List<DataRow> _dataRow = [];
  List<Categories> categoryData = [];
  List<OrderDetail> categoryOrderDetailList = [];
  List<OrderDetail> orderDetailList = [];
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
                              child: Text(AppLocalizations.of(context)!.translate('product_edited_report'),
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
                                        AppLocalizations.of(context)!.translate('receipt_no'),
                                        style: TextStyle(fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ),
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
                                      child: Text(AppLocalizations.of(context)!.translate('original_price'),
                                        style: TextStyle(fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ),
                                  DataColumn(
                                    label: Expanded(
                                      child: Text(AppLocalizations.of(context)!.translate('price'),
                                        style: TextStyle(fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ),
                                  DataColumn(
                                    label: Expanded(
                                      child: Text(
                                        AppLocalizations.of(context)!.translate('edit_by'),
                                        style: TextStyle(fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ),
                                  DataColumn(
                                    label: Expanded(
                                      child: Text(
                                        AppLocalizations.of(context)!.translate('edit_at'),
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
              //mobile view
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
                              child: Text(AppLocalizations.of(context)!.translate('product_edited_report'),
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
                                        AppLocalizations.of(context)!.translate('receipt_no'),
                                        style: TextStyle(fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ),
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
                                      child: Text(AppLocalizations.of(context)!.translate('original_price'),
                                        style: TextStyle(fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ),
                                  DataColumn(
                                    label: Expanded(
                                      child: Text(AppLocalizations.of(context)!.translate('price'),
                                        style: TextStyle(fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ),
                                  DataColumn(
                                    label: Expanded(
                                      child: Text(
                                        AppLocalizations.of(context)!.translate('edit_by'),
                                        style: TextStyle(fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ),
                                  DataColumn(
                                    label: Expanded(
                                      child: Text(
                                        AppLocalizations.of(context)!.translate('edit_at'),
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
    return Scaffold();
  }

  preload(ReportModel reportModel) async {
    this.currentStDate = reportModel.startDateTime;
    this.currentEdDate = reportModel.endDateTime;
    await getAllCancelItemData();
    reportModel.addOtherValue(valueList: categoryOrderDetailList);
    if(mounted){
      setState(() {
        isLoaded = true;
      });
    }
  }

  getAllCancelItemData() async {
    _dataRow.clear();
    ReportObject object = await ReportObject().getAllEditedOrderDetail(currentStDate: currentStDate, currentEdDate: currentEdDate);
    print("dateOrderDetail: ${object.dateOrderDetail!.length}");
    categoryOrderDetailList = object.dateOrderDetail!;
    //print('date category data: ${categoryData.length}');
    if(categoryOrderDetailList.isNotEmpty){
      for(int i = 0; i < categoryOrderDetailList.length; i++){
        categoryOrderDetailList[i].categoryOrderDetailList = object.dateOrderDetail!;
        _dataRow.addAll([
          DataRow(
            cells: <DataCell>[
              // DataCell(Text('Receipt No')),
              DataCell(Text('#${categoryOrderDetailList[i].order_number}-${categoryOrderDetailList[i].branch_id?.padLeft(3,'0')}-${categoryOrderDetailList[i].created_at.toString().replaceAll(' ', '').replaceAll('-', '').replaceAll(':', '')}')),
              DataCell(Text('${categoryOrderDetailList[i].productName}')),
              DataCell(Text('${categoryOrderDetailList[i].original_price}')),
              DataCell(Text('${categoryOrderDetailList[i].price}')),
              DataCell(Text('${categoryOrderDetailList[i].edited_by}')),
              DataCell(Text('${Utils.formatDate(categoryOrderDetailList[i].updated_at)}')),
            ]),
        ]);
      }
    }
  }
}
