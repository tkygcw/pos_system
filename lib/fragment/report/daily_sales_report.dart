import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pos_system/object/settlement.dart';
import 'package:pos_system/object/settlement_link_payment.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:syncfusion_flutter_datepicker/datepicker.dart';

import '../../database/pos_database.dart';
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


  @override
  void initState() {
    super.initState();
    dateTimeNow = dateFormat.format(DateTime.now());
    _controller = new TextEditingController(text: '${dateTimeNow} - ${dateTimeNow}');
    _dateRangePickerController.selectedRange = PickerDateRange(DateTime.now(), DateTime.now());
    preload();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeColor>(builder: (context, ThemeColor color, child) {
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
                        child: Text('Daily Sales Report',
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
                                  'Date',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                            DataColumn(
                              label: Expanded(
                                child: Text(
                                  'Total Bills',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                            DataColumn(
                              label: Expanded(
                                child: Text(
                                  'Total Sales',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                            DataColumn(
                              label: Expanded(
                                child: Text(
                                  'Total Refund bill',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                            DataColumn(
                              label: Expanded(
                                child: Text(
                                  'Total Refund',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                            DataColumn(
                              label: Expanded(
                                child: Text(
                                  'Total Discount',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                            DataColumn(
                              label: Expanded(
                                child: Text(
                                  'Total Tax',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                            DataColumn(
                              label: Expanded(
                                child: Text(
                                  'Total Cancellation',
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
                        Text('NO RECORD FOUND'),
                      ],
                    ),
                  )
                ],
              ),
            ),
          );
        } else {
          return Scaffold(
            body: Container(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        child: Text('Daily Sales Report',
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
                                  'Date',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                            DataColumn(
                              label: Expanded(
                                child: Text(
                                  'Total Bills',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                            DataColumn(
                              label: Expanded(
                                child: Text(
                                  'Total Sales',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                            DataColumn(
                              label: Expanded(
                                child: Text(
                                  'Total Refund bill',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                            DataColumn(
                              label: Expanded(
                                child: Text(
                                  'Total Refund',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                            DataColumn(
                              label: Expanded(
                                child: Text(
                                  'Total Discount',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                            DataColumn(
                              label: Expanded(
                                child: Text(
                                  'Total Tax',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                            DataColumn(
                              label: Expanded(
                                child: Text(
                                  'Total Cancellation',
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
                        Text('NO RECORD FOUND'),
                      ],
                    ),
                  )
                ],
              ),
            ),
          );
        }
      });
    });
  }
  preload() async {
    await getTotalSales();
    await getAllPaymentLinkCompany();
    setState(() {
      isLoaded = true;
    });
  }

  getAllPaymentLinkCompany() async {
    final prefs = await SharedPreferences.getInstance();
    final String? user = prefs.getString('user');
    Map userObject = json.decode(user!);
    List<PaymentLinkCompany> data = await PosDatabase.instance.readAllPaymentLinkCompany(userObject['company_id']);
    if(data.isNotEmpty){
      paymentLinkCompanyList = data;
    }
  }

  getTotalSales() async {
    _dataRow.clear();
    List<Settlement> settlementList = [];
    List<SettlementLinkPayment> settlementLinkPaymentList = [];
    ReportObject object = await ReportObject().getAllSettlement();
    settlementList = object.dateSettlementList!;
    //print('dining data: ${modifierData.length}');
    if(settlementList.isNotEmpty){
      for(int i = 0; i < settlementList.length; i++){
        ReportObject object = await ReportObject().getAllSettlementPaymentDetail(settlementList[i].settlement_sqlite_id!);
        settlementLinkPaymentList = object.dateSettlementPaymentList!;
        print('settlement payment length: ${settlementLinkPaymentList.length}');
        _dataRow.addAll([
          DataRow(
            cells: <DataCell>[
              DataCell(
                Text('${settlementList[i].created_at}'),
              ),
              DataCell(Text('${settlementList[i].total_bill}')),
              DataCell(Text('${settlementList[i].total_sales}')),
              DataCell(Text('${settlementList[i].total_refund_bill}')),
              DataCell(Text('${settlementList[i].total_refund_amount}')),
              DataCell(Text('${settlementList[i].total_discount}')),
              DataCell(Text('${settlementList[i].total_tax}')),
              DataCell(Text('${settlementList[i].total_cancellation}')),
              for(int j = 0; j < settlementLinkPaymentList.length; j++)
                DataCell(Text('${settlementLinkPaymentList[j].total_sales}')),

            ],
          ),
        ]);
      }
    }
  }
}
