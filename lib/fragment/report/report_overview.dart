import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pos_system/database/pos_database.dart';
import 'package:pos_system/notifier/report_notifier.dart';
import 'package:pos_system/object/branch_link_tax.dart';
import 'package:pos_system/object/order.dart';
import 'package:pos_system/object/order_detail.dart';
import 'package:pos_system/object/order_detail_cancel.dart';
import 'package:pos_system/object/order_promotion_detail.dart';
import 'package:pos_system/object/order_tax_detail.dart';
import 'package:pos_system/object/refund.dart';
import 'package:pos_system/object/report_class.dart';
import 'package:pos_system/page/progress_bar.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:syncfusion_flutter_datepicker/datepicker.dart';

import '../../notifier/theme_color.dart';
import '../../object/payment_link_company.dart';
import '../../translation/AppLocalizations.dart';

class ReportOverview extends StatefulWidget {
  const ReportOverview({Key? key}) : super(key: key);

  @override
  State<ReportOverview> createState() => _ReportOverviewState();
}

class _ReportOverviewState extends State<ReportOverview> {
  DateFormat dateFormat = DateFormat("dd/MM/yyyy");
  String currentStDate = '';
  String currentEdDate = '';
  List<Order> paidOrderList = [], dateOrderList = [], dateRefundList = [];
  List<OrderDetail> cancelledOrderDetail = [], dateOrderDetail = [];
  List<OrderPromotionDetail> paidPromotionDetail = [], datePromotionDetail = [];
  List<OrderTaxDetail> paidOrderTaxDetail = [], dateTaxDetail = [];
  List<PaymentLinkCompany> paymentList = [];
  List<BranchLinkTax> branchTaxList = [];
  List<OrderDetailCancel> dateOrderDetailCancel = [];
  ReportObject? reportObject;
  String jsonPayment = '';
  double totalSales = 0.0, totalRefundAmount = 0.0;
  double totalPromotionAmount = 0.0;
  bool isLoaded = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeColor>(builder: (context, ThemeColor color, child) {
      return Consumer<ReportModel>(builder: (context, ReportModel reportModel, child) {
        preload(reportModel);
          return LayoutBuilder(builder: (context, constraints) {
            if (constraints.maxWidth > 800) {
              return isLoaded == true ?
              Scaffold(
                      resizeToAvoidBottomInset: false,
                      body: Container(
                        padding: const EdgeInsets.all(8),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Container(
                                  child: Text('Overview',
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
                                child: GridView.count(
                              physics: NeverScrollableScrollPhysics(),
                              shrinkWrap: true,
                              crossAxisSpacing: 5,
                              mainAxisSpacing: 5,
                              crossAxisCount: 4,
                              childAspectRatio: (1 / .4),
                              children: [
                                Container(
                                  child: Card(
                                    color: color.iconColor,
                                    elevation: 5,
                                    child: ListTile(
                                      title: Text('Total bills'),
                                      subtitle: Text('${dateOrderList.length}',
                                          style: TextStyle(color: Colors.black, fontSize: 24)),
                                      trailing: Icon(Icons.receipt_long),
                                    ),
                                  ),
                                ),
                                Container(
                                  child: Card(
                                    color: color.iconColor,
                                    elevation: 5,
                                    child: ListTile(
                                      title: Text('Total Sales (MYR)'),
                                      subtitle: Text('${totalSales.toStringAsFixed(2)}',
                                          style: TextStyle(color: Colors.black, fontSize: 24)),
                                      trailing: Icon(Icons.monetization_on),
                                    ),
                                  ),
                                ),
                                Container(
                                  child: Card(
                                    color: color.iconColor,
                                    elevation: 5,
                                    child: ListTile(
                                      title: Text('Total Refund bill'),
                                      subtitle: Text('${dateRefundList.length}',
                                          style: TextStyle(color: Colors.black, fontSize: 24)),
                                      trailing: Icon(Icons.refresh),
                                    ),
                                  ),
                                ),
                                Container(
                                  child: Card(
                                    color: color.iconColor,
                                    elevation: 5,
                                    child: ListTile(
                                      title: Text('Total Refund'),
                                      subtitle: Text('${totalRefundAmount.toStringAsFixed(2)}',
                                          style: TextStyle(color: Colors.black, fontSize: 24)),
                                      trailing: Icon(Icons.cancel),
                                    ),
                                  ),
                                ),
                                Container(
                                  child: Card(
                                    color: color.iconColor,
                                    elevation: 5,
                                    child: ListTile(
                                      title: Text('Total discount'),
                                      subtitle: Text('${totalPromotionAmount.toStringAsFixed(2)}',
                                          style: TextStyle(color: Colors.black, fontSize: 24)),
                                      trailing: Icon(Icons.discount),
                                    ),
                                  ),
                                ),
                                Container(
                                  child: Card(
                                    color: color.iconColor,
                                    elevation: 5,
                                    child: ListTile(
                                      title: Text('Total Cancelled item'),
                                      subtitle: dateOrderDetailCancel[0].total_item != null ?
                                      Text('${dateOrderDetailCancel[0].total_item}',
                                          style: TextStyle(color: Colors.black, fontSize: 24))
                                          :
                                      Text('0', style: TextStyle(color: Colors.black, fontSize: 24)),
                                      trailing: Icon(Icons.no_food),
                                    ),
                                  ),
                                ),
                              ],
                            )),
                            Spacer(),
                            Container(
                              //flex: 2,
                              child: GridView.count(
                                shrinkWrap: true,
                                physics: NeverScrollableScrollPhysics(),
                                crossAxisCount: 2,
                                crossAxisSpacing: 10,
                                childAspectRatio: MediaQuery.of(context).size.height < 750 ? (1 / .6) : (1 / .7),
                                children: [
                                  Container(
                                    child: Card(
                                      color: color.iconColor,
                                      elevation: 5,
                                      child: Padding(
                                        padding: EdgeInsets.all(20),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Container(
                                              margin: EdgeInsets.only(bottom: 20),
                                              child: Text('Payment Overview',
                                                  style: TextStyle(fontSize: 20)),
                                            ),
                                            Container(
                                              child: Table(
                                                children: [
                                                  for (var payment in paymentList)
                                                    TableRow(children: [
                                                      Container(
                                                        padding: EdgeInsets.only(bottom: 10),
                                                        child: Text('${payment.name}'),
                                                      ),
                                                      Container(
                                                        padding: EdgeInsets.only(bottom: 10),
                                                        child: Text('${payment.total_bill}'),
                                                      ),
                                                      Container(
                                                        padding: EdgeInsets.only(bottom: 10),
                                                        child: Text(
                                                            '${payment.totalAmount.toStringAsFixed(2)}'),
                                                      ),
                                                    ]),
                                                ],
                                              ),
                                            )
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                  Container(
                                    child: Card(
                                      color: color.iconColor,
                                      elevation: 5,
                                      child: Padding(
                                        padding: EdgeInsets.all(20),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Container(
                                              margin: EdgeInsets.only(bottom: 20),
                                              child: Text('Charges Overview',
                                                  style: TextStyle(fontSize: 20)),
                                            ),
                                            branchTaxList.isNotEmpty ?
                                            Container(
                                              child: Table(
                                                children: [
                                                  for (var branchTax in branchTaxList)
                                                  TableRow(children: [
                                                    Container(
                                                      padding: EdgeInsets.only(bottom: 10),
                                                      child: Text('${branchTax.tax_name}'),
                                                    ),
                                                    Container(
                                                      padding: EdgeInsets.only(bottom: 10),
                                                      child: Text('${branchTax.total_amount.toStringAsFixed(2)}'),
                                                    ),
                                                  ]),
                                                ],
                                              ),
                                            ) :
                                            Center(
                                              heightFactor: 5,
                                              child: Column(
                                                children: [
                                                  Icon(Icons.no_meals_ouline),
                                                  Text('No Charges Record')
                                                ],
                                              ),
                                            )
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            )
                          ],
                        ),
                      ),
                    )
                  : CustomProgressBar();
            } else {
              ///mobile view
              return isLoaded == true ?
              Scaffold(
                resizeToAvoidBottomInset: false,
                body: Container(
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        child: Text('Overview',
                            style: TextStyle(fontSize: 25, color: Colors.black)),
                      ),
                      SizedBox(height: 5),
                      Divider(
                        height: 10,
                        color: Colors.grey,
                      ),
                      SizedBox(height: 5),
                      Container(
                          child: GridView.count(
                            shrinkWrap: true,
                            crossAxisSpacing: 5,
                            mainAxisSpacing: 5,
                            crossAxisCount: 4,
                            childAspectRatio: (1 / 0.8),
                            children: [
                              Container(
                                child: Card(
                                  color: color.iconColor,
                                  elevation: 5,
                                  child: ListTile(
                                    title: Text('Total bills'),
                                    subtitle: Text('${dateOrderList.length}',
                                        style: TextStyle(color: Colors.black, fontSize: 24)),
                                  ),
                                ),
                              ),
                              Container(
                                child: Card(
                                  color: color.iconColor,
                                  elevation: 5,
                                  child: ListTile(
                                    title: Text('Total Sales (MYR)'),
                                    subtitle: Text('${totalSales.toStringAsFixed(2)}',
                                        style: TextStyle(color: Colors.black, fontSize: 24)),
                                  ),
                                ),
                              ),
                              Container(
                                child: Card(
                                  color: color.iconColor,
                                  elevation: 5,
                                  child: ListTile(
                                    title: Text('Total Refund bill'),
                                    subtitle: Text('${dateRefundList.length}',
                                        style: TextStyle(color: Colors.black, fontSize: 24)),
                                  ),
                                ),
                              ),
                              Container(
                                child: Card(
                                  color: color.iconColor,
                                  elevation: 5,
                                  child: ListTile(
                                    title: Text('Total Refund'),
                                    subtitle: Text('${totalRefundAmount.toStringAsFixed(2)}',
                                        style: TextStyle(color: Colors.black, fontSize: 24)),
                                  ),
                                ),
                              ),
                              Container(
                                child: Card(
                                  color: color.iconColor,
                                  elevation: 5,
                                  child: ListTile(
                                    title: Text('Total discount'),
                                    subtitle: Text('${totalPromotionAmount.toStringAsFixed(2)}',
                                        style: TextStyle(color: Colors.black, fontSize: 24)),
                                  ),
                                ),
                              ),
                              Container(
                                child: Card(
                                  color: color.iconColor,
                                  elevation: 5,
                                  child: ListTile(
                                    title: Text('Total Cancelled Item'),
                                    subtitle: Text('${dateOrderDetail.length}',
                                        style: TextStyle(color: Colors.black, fontSize: 24)),
                                  ),
                                ),
                              ),
                            ],
                          )),
                      Spacer(),
                      Container(
                        //flex: 2,
                        child: GridView.count(
                          shrinkWrap: true,
                          physics: NeverScrollableScrollPhysics(),
                          crossAxisCount: 2,
                          crossAxisSpacing: 10,
                          childAspectRatio: MediaQuery.of(context).size.height < 750 ? (1 / .6) : (1 / .7),
                          children: [
                            Container(
                              child: Card(
                                color: color.iconColor,
                                elevation: 5,
                                child: Padding(
                                  padding: EdgeInsets.all(20),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        margin: EdgeInsets.only(bottom: 20),
                                        child: Text('Payment Overview',
                                            style: TextStyle(fontSize: 20)),
                                      ),
                                      Container(
                                        child: Table(
                                          children: [
                                            for (var payment in paymentList)
                                              TableRow(children: [
                                                Container(
                                                  padding: EdgeInsets.only(bottom: 10),
                                                  child: Text('${payment.name}'),
                                                ),
                                                Container(
                                                  padding: EdgeInsets.only(bottom: 10),
                                                  child: Text('${payment.total_bill}'),
                                                ),
                                                Container(
                                                  padding: EdgeInsets.only(bottom: 10),
                                                  child: Text(
                                                      '${payment.totalAmount.toStringAsFixed(2)}'),
                                                ),
                                              ]),
                                          ],
                                        ),
                                      )
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            Container(
                              child: Card(
                                color: color.iconColor,
                                elevation: 5,
                                child: Padding(
                                  padding: EdgeInsets.all(20),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        margin: EdgeInsets.only(bottom: 20),
                                        child: Text('Charges Overview',
                                            style: TextStyle(fontSize: 20)),
                                      ),
                                      branchTaxList.isNotEmpty ?
                                      Container(
                                        child: Table(
                                          children: [
                                            for (var branchTax in branchTaxList)
                                              TableRow(children: [
                                                Container(
                                                  padding: EdgeInsets.only(bottom: 10),
                                                  child: Text('${branchTax.tax_name}'),
                                                ),
                                                Container(
                                                  padding: EdgeInsets.only(bottom: 10),
                                                  child: Text('${branchTax.total_amount.toStringAsFixed(2)}'),
                                                ),
                                              ]),
                                          ],
                                        ),
                                      ) :
                                      Center(
                                        heightFactor: 5,
                                        child: Column(
                                          children: [
                                            Icon(Icons.no_meals_ouline),
                                            Text('No Charges Record')
                                          ],
                                        ),
                                      )
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                    ],
                  ),
                ),
              ) : CustomProgressBar();
            }
          });
        }
      );
    });
  }

  preload(ReportModel reportModel) async {
    this.currentStDate = reportModel.startDateTime;
    this.currentEdDate = reportModel.endDateTime;
    await getAllPaidOrder();
    await readPaymentLinkCompany();
    await readBranchTaxes();
    await getAllPaidOrderPromotionDetail();
    await getRefund();
    getAllCancelOrderDetail();
  }

  readPaymentLinkCompany() async {
    final prefs = await SharedPreferences.getInstance();
    final String? user = prefs.getString('user');
    Map userObject = json.decode(user!);
    List<PaymentLinkCompany> data = await PosDatabase.instance.readAllPaymentLinkCompany(userObject['company_id']);
    if (data.isNotEmpty) {
      paymentList = data;
      for(int j = 0 ; j < paymentList.length; j++){
        for(int i = 0; i < dateOrderList.length; i++){
          if(dateOrderList[i].payment_status != 2){
            if(paymentList[j].payment_link_company_id == int.parse(dateOrderList[i].payment_link_company_id!)){
              paymentList[j].total_bill ++;
              paymentList[j].totalAmount += double.parse(dateOrderList[i].final_amount!);
            }
          }
        }
      }
    }
  }

  readBranchTaxes() async {
    ReportObject object = await ReportObject().getAllPaidOrderTaxDetail(currentStDate: currentStDate, currentEdDate: currentEdDate);
    branchTaxList = object.branchTaxList!;
  }

  getAllPaidOrder() async {
    ReportObject object = await ReportObject().getAllPaidOrder(currentStDate: currentStDate, currentEdDate: currentEdDate);
    reportObject = object;
    dateOrderList = reportObject!.dateOrderList!;
    totalSales = reportObject!.totalSales!;
  }

  getAllPaidOrderPromotionDetail() async {
    ReportObject object = await ReportObject().getAllPaidOrderPromotionDetail(currentStDate: currentStDate, currentEdDate: currentEdDate);
    reportObject = object;
    datePromotionDetail = object.datePromotionDetail!;
    totalPromotionAmount = object.totalPromotionAmount!;
  }

  getRefund() async {
    ReportObject object = await ReportObject().getAllRefundOrder(currentStDate: currentStDate, currentEdDate: currentEdDate);
    reportObject = object;
    dateRefundList = object.dateRefundOrderList!;
    totalRefundAmount = object.totalRefundAmount!;
  }

  getAllCancelOrderDetail() async {
    ReportObject object = await ReportObject().getTotalCancelledItem(currentStDate: currentStDate, currentEdDate: currentEdDate);
    reportObject  = object;
    dateOrderDetailCancel = object.dateOrderDetailCancelList!;
    if(mounted){
      setState(() {
        isLoaded = true;
      });
    }
  }
}
