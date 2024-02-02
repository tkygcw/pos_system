import 'dart:async';

import 'package:flutter/material.dart';
import 'package:pos_system/database/pos_database.dart';
import 'package:pos_system/object/branch_link_tax.dart';
import 'package:pos_system/object/order.dart';
import 'package:pos_system/object/order_tax_detail.dart';
import 'package:pos_system/translation/AppLocalizations.dart';
import 'package:pos_system/utils/Utils.dart';
import 'package:provider/provider.dart';

import '../../notifier/report_notifier.dart';
import '../../notifier/theme_color.dart';
import '../../object/report_class.dart';
import '../../page/progress_bar.dart';

class RefundReport extends StatefulWidget {
  const RefundReport({Key? key}) : super(key: key);

  @override
  State<RefundReport> createState() => _RefundReportState();
}

class _RefundReportState extends State<RefundReport> {
  StreamController controller = StreamController();
  late Stream contentStream;
  List<DataRow> _dataRow = [];
  List<BranchLinkTax> taxList = [];
  List<Order> orderList = [];
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
                                      child: Text(AppLocalizations.of(context)!.translate('refund_report'),
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
                                SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: Container(
                                      margin: EdgeInsets.all(10),
                                      child: DataTable(
                                          border: TableBorder.symmetric(outside: BorderSide(color: Colors.black12)),
                                          headingTextStyle: TextStyle(color: Colors.white),
                                          headingRowColor: MaterialStateColor.resolveWith((states) {return Colors.black;},),
                                          columns: <DataColumn>[
                                            DataColumn(
                                              label: Expanded(
                                                child: Text(
                                                  AppLocalizations.of(context)!.translate('bill_no'),
                                                  style: TextStyle(fontWeight: FontWeight.bold),
                                                ),
                                              ),
                                            ),
                                            DataColumn(
                                              label: Expanded(
                                                child: Text(
                                                  AppLocalizations.of(context)!.translate('subtotal'),
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
                                            for(int i = 0; i < taxList.length; i++)
                                              DataColumn(
                                                label: Expanded(
                                                  child: Text(
                                                    '${taxList[i].tax_name}',
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
                                                  AppLocalizations.of(context)!.translate('rounding'),
                                                  style: TextStyle(fontWeight: FontWeight.bold),
                                                ),
                                              ),
                                            ),
                                            DataColumn(
                                              label: Expanded(
                                                child: Text(
                                                  AppLocalizations.of(context)!.translate('final_amount'),
                                                  style: TextStyle(fontWeight: FontWeight.bold),
                                                ),
                                              ),
                                            ),
                                            DataColumn(
                                              label: Expanded(
                                                child: Text(
                                                  AppLocalizations.of(context)!.translate('refund_by'),
                                                  style: TextStyle(fontWeight: FontWeight.bold),
                                                ),
                                              ),
                                            ),
                                            DataColumn(
                                              label: Expanded(
                                                child: Text(
                                                  AppLocalizations.of(context)!.translate('refund_at'),
                                                  style: TextStyle(fontWeight: FontWeight.bold),
                                                ),
                                              ),
                                            ),
                                          ],
                                          rows: _dataRow
                                      )
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
                        )
                    );
                  } else {
                    return  Scaffold(
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
                                      child: Text(AppLocalizations.of(context)!.translate('refund_report'),
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
                                SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: Container(
                                    margin: EdgeInsets.all(10),
                                    child: DataTable(
                                        border: TableBorder.symmetric(outside: BorderSide(color: Colors.black12)),
                                        headingTextStyle: TextStyle(color: Colors.white),
                                        headingRowColor: MaterialStateColor.resolveWith((states) {return Colors.black;},),
                                        columns: <DataColumn>[
                                          DataColumn(
                                            label: Expanded(
                                              child: Text(
                                                AppLocalizations.of(context)!.translate('bill_no'),
                                                style: TextStyle(fontWeight: FontWeight.bold),
                                              ),
                                            ),
                                          ),
                                          DataColumn(
                                            label: Expanded(
                                              child: Text(
                                                AppLocalizations.of(context)!.translate('subtotal'),
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
                                          for(int i = 0; i < taxList.length; i++)
                                            DataColumn(
                                              label: Expanded(
                                                child: Text(
                                                  '${taxList[i].tax_name}',
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
                                                AppLocalizations.of(context)!.translate('rounding'),
                                                style: TextStyle(fontWeight: FontWeight.bold),
                                              ),
                                            ),
                                          ),
                                          DataColumn(
                                            label: Expanded(
                                              child: Text(
                                                AppLocalizations.of(context)!.translate('final_amount'),
                                                style: TextStyle(fontWeight: FontWeight.bold),
                                              ),
                                            ),
                                          ),
                                          DataColumn(
                                            label: Expanded(
                                              child: Text(
                                                AppLocalizations.of(context)!.translate('refund_by'),
                                                style: TextStyle(fontWeight: FontWeight.bold),
                                              ),
                                            ),
                                          ),
                                          DataColumn(
                                            label: Expanded(
                                              child: Text(
                                                AppLocalizations.of(context)!.translate('refund_at'),
                                                style: TextStyle(fontWeight: FontWeight.bold),
                                              ),
                                            ),
                                          ),
                                        ],
                                        rows: _dataRow
                                    )
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
  }

  preload(ReportModel reportModel) async {
    this.currentStDate = reportModel.startDateTime;
    this.currentEdDate = reportModel.endDateTime;
    await getAllBranchLinkTax();
    await getAllRefundOrder();
    reportModel.addOtherValue(headerValue: taxList, valueList: orderList);
    controller.sink.add("refresh");
  }

  getAllBranchLinkTax() async {
    List<BranchLinkTax> data = await PosDatabase.instance.readBranchLinkTax();
    taxList = data;
  }

  getAllRefundOrder() async {
    _dataRow.clear();
    ReportObject object = await ReportObject().getAllRefundedOrder(currentStDate: currentStDate, currentEdDate: currentEdDate);
    orderList = object.dateRefundOrderList!;
    if(orderList.isNotEmpty){
      for(int i = 0; i < orderList.length; i++){
        ReportObject object = await ReportObject().getAllTaxDetail(orderList[i].order_sqlite_id!, currentStDate: currentStDate, currentEdDate: currentEdDate);
        orderList[i].taxDetailList = object.dateTaxDetail!;
        // print(' tax length');
        orderList[i].taxDetailList.isNotEmpty ?
        _dataRow.addAll([
          DataRow(
            cells: <DataCell>[
              DataCell(
                Text('${orderList[i].bill_no}'),
              ),
              DataCell(Text('${orderList[i].subtotal}')),
              orderList[i].promo_amount == null ?
              DataCell(Text('-0.00'))
                  :
              DataCell(Text('-${orderList[i].promo_amount?.toStringAsFixed(2)}')),
              for(int j = 0; j < orderList[i].taxDetailList.length; j++)
                DataCell(Text('${orderList[i].taxDetailList[j].total_tax_amount!.toStringAsFixed(2)}')) ,
              DataCell(Text('${orderList[i].amount}')),
              DataCell(Text('${orderList[i].rounding}')),
              DataCell(Text('${orderList[i].final_amount}')),
              DataCell(Text('${orderList[i].refund_by}')),
              DataCell(Text('${orderList[i].refund_at}')),
            ],
          ),
        ])
            :
        _dataRow.addAll([
          DataRow(
            cells: <DataCell>[
              DataCell(
                Text('${orderList[i].bill_no}'),
              ),
              DataCell(Text('${orderList[i].subtotal}')),
              orderList[i].promo_amount == null ?
              DataCell(Text('-0.00'))
                  :
              DataCell(Text('-${orderList[i].promo_amount?.toStringAsFixed(2)}')),
              for(int i = 0; i < taxList.length; i++)
                DataCell(Text('0.00')),
              DataCell(Text('${orderList[i].amount}')),
              DataCell(Text('${orderList[i].rounding}')),
              DataCell(Text('${orderList[i].final_amount}')),
              DataCell(Text('${orderList[i].refund_by}')),
              DataCell(Text('${Utils.formatDate(orderList[i].refund_at)}')),
            ],
          ),
        ]);
      }
    }
  }
}
