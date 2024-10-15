import 'dart:async';

import 'package:flutter/material.dart';
import 'package:pos_system/object/cash_record.dart';
import 'package:pos_system/page/progress_bar.dart';
import 'package:provider/provider.dart';

import '../../notifier/report_notifier.dart';
import '../../notifier/theme_color.dart';
import '../../object/report_class.dart';
import '../../translation/AppLocalizations.dart';
import '../../utils/Utils.dart';

class CashRecordReport extends StatefulWidget {
  const CashRecordReport({Key? key}) : super(key: key);

  @override
  State<CashRecordReport> createState() => _CashRecordReportState();
}

class _CashRecordReportState extends State<CashRecordReport> {
  StreamController controller = StreamController();
  late Stream contentStream;
  late ReportModel reportModel;
  List<DataRow> _dataRow = [];
  String currentStDate = '';
  String currentEdDate = '';


  @override
  void initState() {
    super.initState();
    contentStream = controller.stream;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeColor>(builder: (context, ThemeColor color, child) {
      return Consumer<ReportModel>(builder: (context, ReportModel reportModel, child){
        this.reportModel = reportModel;
        preload();
        return Padding(
          padding: const EdgeInsets.only(bottom: 8.0, right: 8.0, left: 8.0),
          child: Scaffold(
            appBar: AppBar(
              elevation: 0.0,
              backgroundColor: Colors.transparent,
              title: Text(AppLocalizations.of(context)!.translate('cash_record_report'), style: TextStyle(fontSize: 25)),
              titleSpacing: 0.0,
              centerTitle: false,
              automaticallyImplyLeading: false,
              bottom: PreferredSize(
                preferredSize: Size.zero,
                child: Divider(
                height: 10,
                color: Colors.grey),
              ),
            ),
            body: StreamBuilder(
                stream: contentStream,
                builder: (context, snapshot) {
                  if(snapshot.hasData){
                    if(_dataRow.isNotEmpty){
                      return Container(
                        padding: EdgeInsets.all(10),
                        child: SingleChildScrollView(
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
                                        AppLocalizations.of(context)!.translate('date_time'),
                                        style: TextStyle(fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ),
                                  DataColumn(
                                    label: Expanded(
                                      child: Text(AppLocalizations.of(context)!.translate('user'),
                                        style: TextStyle(fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ),
                                  DataColumn(
                                    label: Expanded(
                                      child: Text(
                                        AppLocalizations.of(context)!.translate('remark'),
                                        style: TextStyle(fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ),
                                  DataColumn(
                                    label: Expanded(
                                      child: Text(
                                        AppLocalizations.of(context)!.translate('amount'),
                                        style: TextStyle(fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ),
                                  DataColumn(
                                    label: Expanded(
                                      child: Text(
                                        AppLocalizations.of(context)!.translate('payment_method'),
                                        style: TextStyle(fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ),
                                ],
                                rows: _dataRow
                            ),
                          ),
                        ),
                      );
                    } else {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.menu),
                            Text(AppLocalizations.of(context)!.translate('no_record_found')),
                          ],
                        ),
                      );
                    }
                  } else {
                    return CustomProgressBar();
                  }
                }
            ),
          ),
        );
      });
    });
  }

  preload() async {
    this.currentStDate = reportModel.startDateTime;
    this.currentEdDate = reportModel.endDateTime;
    List<CashRecord> cashRecordData = await getAllCashRecord();
    controller.sink.add("refresh");
    reportModel.addOtherValue(valueList: cashRecordData);
  }

  Future<List<CashRecord>>getAllCashRecord() async {
    _dataRow.clear();
    List<CashRecord> cashRecord = await ReportObject().getAllCashRecord(currentStDate: currentStDate, currentEdDate: currentEdDate);
    if(_dataRow.isEmpty){
      _dataRow.add(
        DataRow(
            color: MaterialStatePropertyAll(Colors.grey),
            cells: <DataCell>[
              DataCell(Container()),
              DataCell(Container()),
              DataCell(Container()),
              DataCell(Text(calcTotalCashRecord(cashRecordList: cashRecord))),
              DataCell(Container()),
            ]
        ),
      );
      if(cashRecord.isNotEmpty){
        for(int i = 0; i < cashRecord.length; i++){
          _dataRow.addAll([
            DataRow(
              cells: <DataCell>[
                DataCell(
                  Text(Utils.formatDate(cashRecord[i].created_at!)),
                ),
                DataCell(Text(cashRecord[i].userName!)),
                DataCell(Text(cashRecord[i].remark!)),
                DataCell(Text(formatAmount(cashRecord: cashRecord[i]))),
                DataCell(Text(cashRecord[i].payment_method!)),
              ],
            ),
          ]);
        }
      }
    }
    return cashRecord;
  }

  String formatAmount({required CashRecord cashRecord}){
    String newAmount = Utils.to2Decimal(double.parse(cashRecord.amount!));
    if(cashRecord.type == 2 || cashRecord.type == 4){
      newAmount = "-${Utils.to2Decimal(double.parse(cashRecord.amount!))}";
    }
    return newAmount;
  }

  String calcTotalCashRecord({required List<CashRecord> cashRecordList}) {
    double totalCashIn = 0.0;
    double totalCashOut = 0.0;
    double totalCashDrawer = 0.0;
    double totalCashRefund = 0.0;
    try {
      if(cashRecordList.isNotEmpty){
        for (int i = 0; i < cashRecordList.length; i++) {
          if (cashRecordList[i].type == 0) {
            totalCashIn += double.parse(cashRecordList[i].amount!);
          } else if (cashRecordList[i].type == 1) {
            totalCashIn += double.parse(cashRecordList[i].amount!);
          } else if (cashRecordList[i].type == 3) {
            totalCashIn += double.parse(cashRecordList[i].amount!);
          } else if (cashRecordList[i].type == 2) {
            totalCashOut += double.parse(cashRecordList[i].amount!);
          } else if (cashRecordList[i].type == 4) {
            totalCashRefund += double.parse(cashRecordList[i].amount!);
          }
        }
        totalCashDrawer = totalCashIn - (totalCashOut + totalCashRefund);
      }
      return Utils.to2Decimal(totalCashDrawer);
    } catch (e) {
      print("calc total cash drawer error: $e");
      return "0.00";
    }
  }

}
