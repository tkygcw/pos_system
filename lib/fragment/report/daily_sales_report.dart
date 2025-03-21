import 'dart:async';

import 'package:f_logs/model/flog/flog.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pos_system/object/sales_per_day/sales_per_day.dart';
import 'package:pos_system/page/progress_bar.dart';
import 'package:provider/provider.dart';

import '../../notifier/report_notifier.dart';
import '../../object/report_class.dart';
import '../../translation/AppLocalizations.dart';

class DailySalesReport extends StatefulWidget {
  const DailySalesReport({Key? key}) : super(key: key);

  @override
  State<DailySalesReport> createState() => _DailySalesReportState();
}

class _DailySalesReportState extends State<DailySalesReport> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0.0,
        automaticallyImplyLeading: false,
        backgroundColor: Colors.transparent,
        title: Text(AppLocalizations.of(context)!.translate('daily_sales'), style: TextStyle(fontSize: 25)),
        centerTitle: false,
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(1.0), // Thickness of the underline
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Container(
              color:  Colors.grey, // Color of the underline
              height: 0.5, // Thickness of the underline
            ),
          ),
        ),
      ),
      body: _buildReport(),
    );
  }
}

class _buildReport extends StatefulWidget {
  const _buildReport({Key? key}) : super(key: key);

  @override
  State<_buildReport> createState() => _buildReportState();
}

class _buildReportState extends State<_buildReport> {
  StreamController _controller = StreamController();
  List<DataRow> _dataRow = [];
  late Stream stream;
  late ReportModel _reportModel;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    stream = _controller.stream;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ReportModel>(builder: (context, reportModel, child) {
      _reportModel = reportModel;
      preload();
      return StreamBuilder(stream: stream, builder: (context, snapshot){
        if(snapshot.hasData){
          if(_dataRow.isNotEmpty){
            return Padding(
              padding: EdgeInsets.only(top: 15, left: 8, right: 8),
              child: SingleChildScrollView(
                scrollDirection: Axis.vertical,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    border: TableBorder.symmetric(outside: BorderSide(color: Colors.black12)),
                    headingTextStyle: TextStyle(color: Colors.white),
                    headingRowColor: WidgetStateColor.resolveWith((states) {return Colors.black;},),
                    columns: [
                      DataColumn(
                        label: Expanded(
                          child: Text(
                            AppLocalizations.of(context)!.translate('date'),
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
                      DataColumn(
                        label: Expanded(
                          child: Text(
                            AppLocalizations.of(context)!.translate('total_rounding'),
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                      DataColumn(
                        label: Expanded(
                          child: Text(
                            AppLocalizations.of(context)!.translate('total_tax'),
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                      DataColumn(
                        label: Expanded(
                          child: Text(
                            AppLocalizations.of(context)!.translate('total_charge'),
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                      DataColumn(
                        label: Expanded(
                          child: Text(
                            AppLocalizations.of(context)!.translate('total_discount'),
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
                            AppLocalizations.of(context)!.translate('net_sales'),
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],
                    rows: _dataRow,
                  ),
                ),
              ),
            );
          } else {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Icon(Icons.menu),
                  Text(AppLocalizations.of(context)!.translate('no_record_found')),
                ],
              ),
            );
          }
        } else if (snapshot.hasError) {
          return Center(
            child: Text("Something went wrong..."),
          );
        } else {
          return CustomProgressBar();
        }
      });
    });
  }

  preload() async {
    try{
      _dataRow = [];
      List<SalesPerDay> salesPerDay = await ReportObject().getAllSalesPerDay(currentStDate:  _reportModel.startDateTime, currentEdDate: _reportModel.endDateTime);
      for(var sales in salesPerDay) {
        _dataRow.addAll([
          DataRow(cells: [
            DataCell(Text('${sales.date ?? '-'}')),
            DataCell(Text('${sales.total_amount}')),
            DataCell(Text('${sales.rounding}')),
            DataCell(Text('${sales.tax}')),
            DataCell(Text('${sales.charge}')),
            DataCell(Text('${sales.promotion}')),
            DataCell(Text('${(double.parse(sales.total_amount!) + double.parse(sales.promotion!)).toStringAsFixed(2)}')),
            DataCell(Text('${sales.total_amount}')),
          ])
        ]);
      }
      _controller.sink.add('refresh');
    }catch(e, s){
      FLog.error(
        className: "daily sales report",
        text: "preload failed",
        exception: "Error: $e, StackTrace: $s",
      );
      _controller.sink.addError(e);
      rethrow;
    }
  }
}

