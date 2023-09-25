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
import 'package:pos_system/object/report_class.dart';
import 'package:pos_system/page/progress_bar.dart';
import 'package:pos_system/translation/AppLocalizations.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../notifier/theme_color.dart';
import '../../object/payment_link_company.dart';

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
  int count = 0;
  List<String> stringList = [], branchTaxStringList = [];

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeColor>(builder: (context, ThemeColor color, child) {
      return Consumer<ReportModel>(builder: (context, ReportModel reportModel, child) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (reportModel.load == 0) {
            preload(reportModel);
            reportModel.setLoaded();
          }
        });
        return LayoutBuilder(builder: (context, constraints) {
          if (constraints.maxWidth > 800) {
            return isLoaded == true
                ? Scaffold(
                    resizeToAvoidBottomInset: false,
                    body: Container(
                      padding: const EdgeInsets.all(8),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Container(
                                child: Text(AppLocalizations.of(context)!.translate('overview'),
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
                                    title: Text(AppLocalizations.of(context)!.translate('total_bills')),
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
                                    title: Text(AppLocalizations.of(context)!.translate('total_sales')+' (MYR)'),
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
                                    title: Text(AppLocalizations.of(context)!.translate('total_refund_bill')),
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
                                    title: Text(AppLocalizations.of(context)!.translate('total_refund')),
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
                                    title: Text(AppLocalizations.of(context)!.translate('total_discount')),
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
                                    title: Text(AppLocalizations.of(context)!.translate('total_cancelled_item')),
                                    subtitle: dateOrderDetailCancel[0].total_item != null
                                        ? Text('${dateOrderDetailCancel[0].total_item}',
                                            style: TextStyle(color: Colors.black, fontSize: 24))
                                        : Text('0',
                                            style: TextStyle(color: Colors.black, fontSize: 24)),
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
                              childAspectRatio:
                                  MediaQuery.of(context).size.height < 750 ? (1 / .6) : (1 / .7),
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
                                            child: Text(AppLocalizations.of(context)!.translate('payment_overview'),
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
                                            child: Text(AppLocalizations.of(context)!.translate('charges_overview'),
                                                style: TextStyle(fontSize: 20)),
                                          ),
                                          branchTaxList.isNotEmpty
                                              ? Container(
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
                                                            child: Text(
                                                                '${branchTax.total_amount.toStringAsFixed(2)}'),
                                                          ),
                                                        ]),
                                                    ],
                                                  ),
                                                )
                                              : Center(
                                                  heightFactor: 5,
                                                  child: Column(
                                                    children: [
                                                      Icon(Icons.no_meals_ouline),
                                                      Text(AppLocalizations.of(context)!.translate('no_charges_record'))
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
            return isLoaded == true
                ? Scaffold(
                    resizeToAvoidBottomInset: false,
                    body: Container(
                      padding: const EdgeInsets.all(8),
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              child: Text(AppLocalizations.of(context)!.translate('overview'),
                                  style: TextStyle(fontSize: 25, color: Colors.black)),
                            ),
                            SizedBox(height: 5),
                            Divider(
                              height: 10,
                              color: Colors.grey,
                            ),
                            SizedBox(height: 5),
                            GridView.count(
                              physics: NeverScrollableScrollPhysics(),
                              shrinkWrap: true,
                              crossAxisSpacing: 5,
                              mainAxisSpacing: 5,
                              crossAxisCount: 4,
                              childAspectRatio: (1 / 0.8),
                              children: [
                                Card(
                                  color: color.iconColor,
                                  elevation: 5,
                                  child: ListTile(
                                    title: Text(AppLocalizations.of(context)!.translate('total_bills')),
                                    subtitle: Text('${dateOrderList.length}',
                                        style: TextStyle(color: Colors.black, fontSize: 24)),
                                  ),
                                ),
                                Card(
                                  color: color.iconColor,
                                  elevation: 5,
                                  child: ListTile(
                                    title: Text(AppLocalizations.of(context)!.translate('total_sales')+' (MYR)'),
                                    subtitle: Text('${totalSales.toStringAsFixed(2)}',
                                        style: TextStyle(color: Colors.black, fontSize: 24)),
                                  ),
                                ),
                                Card(
                                  color: color.iconColor,
                                  elevation: 5,
                                  child: ListTile(
                                    title: Text(AppLocalizations.of(context)!.translate('total_refund_bill')),
                                    subtitle: Text('${dateRefundList.length}',
                                        style: TextStyle(color: Colors.black, fontSize: 24)),
                                  ),
                                ),
                                Card(
                                  color: color.iconColor,
                                  elevation: 5,
                                  child: ListTile(
                                    title: Text(AppLocalizations.of(context)!.translate('total_refund')),
                                    subtitle: Text('${totalRefundAmount.toStringAsFixed(2)}',
                                        style: TextStyle(color: Colors.black, fontSize: 24)),
                                  ),
                                ),
                                Card(
                                  color: color.iconColor,
                                  elevation: 5,
                                  child: ListTile(
                                    title: Text(AppLocalizations.of(context)!.translate('total_discount')),
                                    subtitle: Text('${totalPromotionAmount.toStringAsFixed(2)}',
                                        style: TextStyle(color: Colors.black, fontSize: 24)),
                                  ),
                                ),
                                Card(
                                  color: color.iconColor,
                                  elevation: 5,
                                  child: ListTile(
                                    title: Text(AppLocalizations.of(context)!.translate('total_cancelled_item')),
                                    subtitle: dateOrderDetailCancel[0].total_item != null
                                        ? Text('${dateOrderDetailCancel[0].total_item}',
                                        style: TextStyle(color: Colors.black, fontSize: 24))
                                        : Text('0',
                                        style: TextStyle(color: Colors.black, fontSize: 24)),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 5),
                            GridView.count(
                              shrinkWrap: true,
                              physics: NeverScrollableScrollPhysics(),
                              crossAxisCount: 2,
                              crossAxisSpacing: 10,
                              childAspectRatio: (1 / 0.9),
                              children: [
                                Card(
                                  color: color.iconColor,
                                  elevation: 5,
                                  child: Padding(
                                    padding: EdgeInsets.all(20),
                                    child: Stack(children: [
                                      Container(
                                        margin: EdgeInsets.only(bottom: 20),
                                        child: Text(AppLocalizations.of(context)!.translate('payment_overview'),
                                            style: TextStyle(fontSize: 20)),
                                      ),
                                      Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          SingleChildScrollView(
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
                                    ]),
                                  ),
                                ),
                                Card(
                                  color: color.iconColor,
                                  elevation: 5,
                                  child: Padding(
                                      padding: EdgeInsets.all(20),
                                      child: Stack(
                                        children: [
                                          Container(
                                            margin: EdgeInsets.only(bottom: 20),
                                            child: Text(AppLocalizations.of(context)!.translate('charges_overview'),
                                                style: TextStyle(fontSize: 20)),
                                          ),
                                          Column(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              branchTaxList.isNotEmpty
                                                  ? Container(
                                                      child: Table(
                                                        children: [
                                                          for (var branchTax in branchTaxList)
                                                            TableRow(children: [
                                                              Container(
                                                                padding:
                                                                    EdgeInsets.only(bottom: 10),
                                                                child:
                                                                    Text('${branchTax.tax_name}'),
                                                              ),
                                                              Container(
                                                                padding:
                                                                    EdgeInsets.only(bottom: 10),
                                                                child: Text(
                                                                    '${branchTax.total_amount.toStringAsFixed(2)}'),
                                                              ),
                                                            ]),
                                                        ],
                                                      ),
                                                    )
                                                  : Center(
                                                      child: Column(
                                                        children: [
                                                          Icon(Icons.no_meals_ouline),
                                                          Text(AppLocalizations.of(context)!.translate('no_charges_record'))
                                                        ],
                                                      ),
                                                    )
                                            ],
                                          ),
                                        ],
                                      )),
                                ),
                              ],
                            )
                          ],
                        ),
                      ),
                    ),
                  )
                : CustomProgressBar();
          }
        });
      });
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
    await getAllCancelOrderDetail();
    reportModel.addValue(
      dateOrderList.length.toString(),
      totalSales.toStringAsFixed(2),
      dateRefundList.length.toString(),
      totalRefundAmount.toStringAsFixed(2),
      totalPromotionAmount.toStringAsFixed(2),
      dateOrderDetailCancel[0].total_item.toString(),
      stringList.toString(),
      branchTaxStringList.toString(),
    );
    //check is loaded or not
    // if (count == 0) {
    //   reportModel.addValue(
    //     dateOrderList.length.toString(),
    //     totalSales.toStringAsFixed(2),
    //     dateRefundList.length.toString(),
    //     totalRefundAmount.toStringAsFixed(2),
    //     totalPromotionAmount.toStringAsFixed(2),
    //     dateOrderDetailCancel[0].total_item.toString(),
    //     stringList.toString(),
    //     branchTaxStringList.toString(),
    //   );
    // }
    // count += 1;
    if (mounted) {
      setState(() {
        isLoaded = true;
      });
    }
  }

  readPaymentLinkCompany() async {
    this.stringList.clear();
    List<String> value = [];
    final prefs = await SharedPreferences.getInstance();
    final String? user = prefs.getString('user');
    Map userObject = json.decode(user!);
    List<PaymentLinkCompany> data = await PosDatabase.instance.readAllPaymentLinkCompanyWithDeleted(userObject['company_id']);
    if (data.isNotEmpty) {
      paymentList = data;
      for (int j = 0; j < paymentList.length; j++) {
        for (int i = 0; i < dateOrderList.length; i++) {
          if (dateOrderList[i].payment_status == 1) {
            if (paymentList[j].payment_link_company_id == int.parse(dateOrderList[i].payment_link_company_id!)) {
              paymentList[j].total_bill++;
              paymentList[j].totalAmount += double.parse(dateOrderList[i].final_amount!);
            }
          }
        }
      }
      paymentList = paymentList.where((item) => item.total_bill != 0).toList();
      for(int i = 0; i < paymentList.length; i++){
        stringList.add(jsonEncode(paymentList[i].tableJson()));
      }
    }
  }

  readBranchTaxes() async {
    branchTaxList.clear();
    branchTaxStringList.clear();
    ReportObject object = await ReportObject().getAllPaidOrderTaxDetail(currentStDate: currentStDate, currentEdDate: currentEdDate);
    branchTaxList = object.branchTaxList!;
    if (branchTaxList.isNotEmpty) {
      for (int i = 0; i < branchTaxList.length; i++) {
        branchTaxStringList.add(jsonEncode(branchTaxList[i].tableJson()));
      }
    } else {
      branchTaxStringList = [];
    }
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
    reportObject = object;
    dateOrderDetailCancel = object.dateOrderDetailCancelList!;
  }
}
