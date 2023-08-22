import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pos_system/object/payment_link_company.dart';
import 'package:pos_system/translation/AppLocalizations.dart';
import 'package:pos_system/utils/Utils.dart';
import 'package:provider/provider.dart';
import 'package:syncfusion_flutter_datepicker/datepicker.dart';

import '../../notifier/report_notifier.dart';
import '../../notifier/theme_color.dart';
import '../../object/order.dart';
import '../../object/report_class.dart';
import '../../page/progress_bar.dart';

class PaymentReport extends StatefulWidget {
  const PaymentReport({Key? key}) : super(key: key);

  @override
  State<PaymentReport> createState() => _PaymentReportState();
}

class _PaymentReportState extends State<PaymentReport> {
  List<DataRow> _dataRow = [];
  List<Order> paymentList = [];
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
                body: this.isLoaded ?
                Container(
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            child: Text(AppLocalizations.of(context)!.translate('payment_report'),
                                style: TextStyle(fontSize: 25, color: Colors.black)),
                          ),
                          Spacer(),
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
                        child: isLoaded ?
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
                                      AppLocalizations.of(context)!.translate('payment_type'),
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
                                    child: Text(AppLocalizations.of(context)!.translate('net_sales'),
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
                ) : CustomProgressBar(),
              );
            } else {
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
                              child: Text(AppLocalizations.of(context)!.translate('payment_report'),
                                  style: TextStyle(fontSize: 25, color: Colors.black)),
                            ),
                            Spacer(),
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
                          child: isLoaded ?
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
                                        AppLocalizations.of(context)!.translate('payment_type'),
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
                                      child: Text(AppLocalizations.of(context)!.translate('net_sales'),
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
    await getAllPaidPayment();
    reportModel.addOtherValue(valueList: paymentList);
    if(mounted){
      setState(() {
        isLoaded = true;
      });
    }
  }

  getAllPaidPayment() async {
    _dataRow.clear();
    ReportObject object = await ReportObject().getAllPaymentData(currentStDate: currentStDate, currentEdDate: currentEdDate);
    paymentList = object.datePayment!;
    //print('modifier data: ${modifierData.length}');
    if(paymentList.isNotEmpty){
      for(int i = 0; i < paymentList.length; i++){
        _dataRow.addAll([
          DataRow(
            cells: <DataCell>[
              DataCell(
                Text('${paymentList[i].payment_name}'),
              ),
              DataCell(Text('${paymentList[i].item_sum}')),
              DataCell(Text('${paymentList[i].net_sales!.toStringAsFixed(2)}')),
              // DataCell(Text('${paymentList[i].gross_sales!.toStringAsFixed(2)}')),
              DataCell(Text('${Utils.to2Decimal(paymentList[i].gross_sales!)}')),
            ],
          ),
        ]);
      }
    }
  }
}
