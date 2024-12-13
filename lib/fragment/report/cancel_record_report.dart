import 'dart:async';

import 'package:flutter/material.dart';
import 'package:pos_system/fragment/report/cancel_record_report_utils.dart';
import 'package:pos_system/notifier/report_notifier.dart';
import 'package:pos_system/object/order_detail_cancel.dart';
import 'package:provider/provider.dart';

import '../../notifier/theme_color.dart';
import '../../object/report_class.dart';
import '../../page/progress_bar.dart';
import '../../translation/AppLocalizations.dart';
import '../../utils/Utils.dart';

class CancelRecordReport extends StatefulWidget {
  const CancelRecordReport({Key? key}) : super(key: key);

  @override
  State<CancelRecordReport> createState() => _CancelRecordReportState();
}

class _CancelRecordReportState extends State<CancelRecordReport> {
  List<DataRow> _dataRow = [];
  late ReportModel model;

  @override
  void initState() {
    model = context.read<ReportModel>();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeColor>(builder: (context, ThemeColor color, child) {
      return Consumer<ReportModel>(builder: (context, ReportModel reportModel, child) {
        return FutureBuilder(
            future: getAllOrderDetailCancel(),
            builder: (context, snapshot) {
              if(snapshot.hasData){
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
                                  child: Text(AppLocalizations.of(context)!.translate('cancel_record_report'),
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
                                              AppLocalizations.of(context)!.translate('date_time'),
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
                                            child: Text(
                                              AppLocalizations.of(context)!.translate('variant'),
                                              style: TextStyle(fontWeight: FontWeight.bold),
                                            ),
                                          ),
                                        ),
                                        DataColumn(
                                          label: Expanded(
                                            child: Text(AppLocalizations.of(context)!.translate('cancel_by'),
                                              style: TextStyle(fontWeight: FontWeight.bold),
                                            ),
                                          ),
                                        ),
                                        DataColumn(
                                          label: Expanded(
                                            child: Text('Reason',
                                              style: TextStyle(fontWeight: FontWeight.bold),
                                            ),
                                          ),
                                        ),
                                        DataColumn(
                                          label: Expanded(
                                            child: Text(
                                              AppLocalizations.of(context)!.translate('quantity'),
                                              style: TextStyle(fontWeight: FontWeight.bold),
                                            ),
                                          ),
                                        ),
                                        DataColumn(
                                          label: Expanded(
                                            child: Text(
                                              'Total amount',
                                              style: TextStyle(fontWeight: FontWeight.bold),
                                            ),
                                          ),
                                        ),
                                      ],
                                      rows: _dataRow
                                  ),
                                )
                            )
                          ],
                        ),
                      ),
                    )
                );
              } else {
                return CustomProgressBar();
              }
            }
        );
      });
    });
  }

  getAllOrderDetailCancel() async {
    _dataRow.clear();
    String currentStDate = model.startDateTime;
    String currentEdDate = model.endDateTime;
    List<OrderDetailCancel> data = await ReportObject().getAllOrderDetailCancel(currentStDate: currentStDate, currentEdDate: currentEdDate);
    model.addOtherValue(valueList: data);
    _dataRow.add(DataRow(
      color: WidgetStateColor.resolveWith((states) {return Colors.grey;},),
      cells: <DataCell>[
        DataCell(Text('')),
        DataCell(Text('')),
        DataCell(Text('')),
        DataCell(Text('')),
        DataCell(Text('')),
        DataCell(Text(data.isEmpty ? '0' : data.first.total_item.toString())),
        DataCell(Text(data.isEmpty ? '0.00' : data.first.total_amount!.toStringAsFixed(2))),
      ],
    ));
    if(data.isNotEmpty){
      for(int i = 0; i < data.length; i++){
        _dataRow.addAll([
          DataRow(
            cells: <DataCell>[
              DataCell(Text(Utils.formatDate(data[i].created_at!))),
              DataCell(Text(data[i].product_name!)),
              DataCell(Text(data[i].product_variant_name!)),
              DataCell(Text(data[i].cancel_by!)),
              DataCell(Text(data[i].cancel_reason!)),
              DataCell(Text(CancelRecordReportUtils.getCancelQtyFormat(data[i]))),
              DataCell(Text(data[i].price!.toStringAsFixed(2))),
            ],
          ),
        ]);
      }
    }
    return _dataRow;
  }
}
