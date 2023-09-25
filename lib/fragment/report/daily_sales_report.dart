import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pos_system/object/settlement.dart';
import 'package:pos_system/object/settlement_link_payment.dart';
import 'package:pos_system/translation/AppLocalizations.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:syncfusion_flutter_datepicker/datepicker.dart';

import '../../database/pos_database.dart';
import '../../notifier/report_notifier.dart';
import '../../notifier/theme_color.dart';
import '../../object/payment_link_company.dart';
import '../../object/report_class.dart';
import '../../page/progress_bar.dart';

class DailySalesReport extends StatefulWidget {
  const DailySalesReport({Key? key}) : super(key: key);

  @override
  State<DailySalesReport> createState() => _DailySalesReportState();
}

class _DailySalesReportState extends State<DailySalesReport> {
  late TextEditingController _controller;
  List<DataRow> _dataRow = [];
  List<PaymentLinkCompany> paymentLinkCompanyList = [];
  DateRangePickerController _dateRangePickerController = DateRangePickerController();
  DateFormat dateFormat = DateFormat("dd/MM/yyyy");
  String currentStDate = new DateFormat("yyyy-MM-dd 00:00:00").format(DateTime.now());
  String currentEdDate = new DateFormat("yyyy-MM-dd 00:00:00").format(DateTime.now());
  String dateTimeNow = '';
  String _range = '';
  bool isLoaded = false;
  List<String> settlementStringList = [], paymentStringList = [], settlementPaymentStringList = [];
  List<Settlement> settlementList = [];


  @override
  void initState() {
    super.initState();
    dateTimeNow = dateFormat.format(DateTime.now());
    _controller = new TextEditingController(text: '${dateTimeNow} - ${dateTimeNow}');
    _dateRangePickerController.selectedRange = PickerDateRange(DateTime.now(), DateTime.now());
    //preload();
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
                child: SingleChildScrollView(
                  scrollDirection: Axis.vertical,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            child: Text(AppLocalizations.of(context)!.translate('daily_sales_report'),
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
                                      AppLocalizations.of(context)!.translate('date'),
                                      style: TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ),
                                DataColumn(
                                  label: Expanded(
                                    child: Text(
                                      AppLocalizations.of(context)!.translate('total_bills'),
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
                                      AppLocalizations.of(context)!.translate('total_refund_bill'),
                                      style: TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ),
                                DataColumn(
                                  label: Expanded(
                                    child: Text(
                                      AppLocalizations.of(context)!.translate('total_refund'),
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
                                      AppLocalizations.of(context)!.translate('total_tax'),
                                      style: TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ),
                                DataColumn(
                                  label: Expanded(
                                    child: Text(
                                      AppLocalizations.of(context)!.translate('total_cancellation'),
                                      style: TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ),
                                for(int i = 0; i < paymentLinkCompanyList.length; i++)
                                  DataColumn(
                                    label: Expanded(
                                      child: Text(
                                        '${paymentLinkCompanyList[i].name}',
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
              ),
            );
          } else {
            return Scaffold(
              body: Container(
                padding: const EdgeInsets.all(8),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            child: Text(AppLocalizations.of(context)!.translate('daily_sales_report'),
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
                                        AppLocalizations.of(context)!.translate('date'),
                                        style: TextStyle(fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ),
                                  DataColumn(
                                    label: Expanded(
                                      child: Text(
                                        AppLocalizations.of(context)!.translate('total_bills'),
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
                                        AppLocalizations.of(context)!.translate('total_refund_bill'),
                                        style: TextStyle(fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ),
                                  DataColumn(
                                    label: Expanded(
                                      child: Text(
                                        AppLocalizations.of(context)!.translate('total_refund'),
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
                                        AppLocalizations.of(context)!.translate('total_tax'),
                                        style: TextStyle(fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ),
                                  DataColumn(
                                    label: Expanded(
                                      child: Text(
                                        AppLocalizations.of(context)!.translate('total_cancellation'),
                                        style: TextStyle(fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ),
                                  for(int i = 0; i < paymentLinkCompanyList.length; i++)
                                    DataColumn(
                                      label: Expanded(
                                        child: Text(
                                          '${paymentLinkCompanyList[i].name}',
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
              ),
            );
          }
        });
      });

    });
  }
  preload(ReportModel reportModel) async {
    await getAllPaymentLinkCompany();
    await getTotalSales();
    reportModel.addOtherValue(headerValue: paymentLinkCompanyList, valueList: settlementList);
    if(mounted){
      setState(() {
        isLoaded = true;
      });
    }
  }

  getAllPaymentLinkCompany() async {
    final prefs = await SharedPreferences.getInstance();
    final String? user = prefs.getString('user');
    Map userObject = json.decode(user!);
    List<PaymentLinkCompany> data = await PosDatabase.instance.readAllPaymentLinkCompanyWithDeleted(userObject['company_id']);
    print("payment link company length: ${data.length}");
    if(data.isNotEmpty){
      paymentLinkCompanyList = data;
      for(int i = 0 ; i < paymentLinkCompanyList.length; i++){
        paymentStringList.add(jsonEncode(paymentLinkCompanyList[i]));
      }
    }
  }

  getTotalSales() async {
    _dataRow.clear();
    List<SettlementLinkPayment> settlementLinkPaymentList = [];
    ReportObject object = await ReportObject().getAllSettlement();
    settlementList = object.dateSettlementList!;
    //print('dining data: ${modifierData.length}');
    if(settlementList.isNotEmpty){
      for(int i = 0; i < settlementList.length; i++){
        settlementStringList.add(jsonEncode(settlementList[i]));
        //print('settlement key: ${settlementList[i].settlement_key}');
        ReportObject object = await ReportObject().getAllSettlementPaymentDetail(settlementList[i].created_at!, paymentLinkCompanyList);
        settlementLinkPaymentList = object.dateSettlementPaymentList!;
        //add settlement payment into settlement object
        settlementList[i].settlementPayment = settlementLinkPaymentList;
        //print('settlement payment length: ${settlementLinkPaymentList.length}');
        DateTime dataDate = DateTime.parse(settlementList[i].created_at!);
        String stringDate = new DateFormat("dd-MM-yyyy").format(dataDate);
        settlementList[i].created_at = stringDate;
        _dataRow.addAll([
          DataRow(
            cells: <DataCell>[
              DataCell(
                Text('${settlementList[i].created_at}'),
              ),
              DataCell(Text('${settlementList[i].all_bill}')),
              DataCell(Text('${settlementList[i].all_sales?.toStringAsFixed(2)}')),
              DataCell(Text('${settlementList[i].all_refund_bill}')),
              DataCell(Text('${settlementList[i].all_refund_amount?.toStringAsFixed(2)}')),
              DataCell(Text('${settlementList[i].all_discount?.toStringAsFixed(2)}')),
              DataCell(Text('${settlementList[i].all_tax_amount?.toStringAsFixed(2)}')),
              DataCell(Text('${settlementList[i].all_cancellation}')),
              for(int j = 0; j < paymentLinkCompanyList.length; j++)
                DataCell(Text('${settlementLinkPaymentList[j].all_payment_sales?.toStringAsFixed(2)}')),

            ],
          ),
        ]);
      }
    }
  }
}
