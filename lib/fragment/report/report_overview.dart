import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pos_system/database/pos_database.dart';
import 'package:pos_system/notifier/report_notifier.dart';
import 'package:pos_system/object/branch_link_tax.dart';
import 'package:pos_system/object/order.dart';
import 'package:pos_system/object/order_detail.dart';
import 'package:pos_system/object/order_detail_cancel.dart';
import 'package:pos_system/object/order_payment_split.dart';
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
  StreamController controller = StreamController();
  late Stream contentStream;
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
  int count = 0;
  List<String> stringList = [], branchTaxStringList = [];

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
                if (constraints.maxWidth > 900 && constraints.maxHeight > 500) {
                  return Scaffold(
                    resizeToAvoidBottomInset: false,
                    body: Container(
                      padding: const EdgeInsets.all(8),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Text(AppLocalizations.of(context)!.translate('overview'),
                                  style: TextStyle(fontSize: 25, color: Colors.black)),
                            ],
                          ),
                          SizedBox(height: 5),
                          Divider(
                            height: 10,
                            color: Colors.grey,
                          ),
                          SizedBox(height: 5),
                          Container(child: GridView.count(
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

                              Visibility(
                                visible: dateOrderDetailCancel[0].total_item is double ? false : true,
                                child: Container(
                                  child: Card(
                                    color: color.iconColor,
                                    elevation: 5,
                                    child: ListTile(
                                      title: Text(AppLocalizations.of(context)!.translate('total_cancelled_item')),
                                      subtitle: dateOrderDetailCancel[0].total_item != null
                                          ? Text('${dateOrderDetailCancel[0].total_item!}',
                                          style: TextStyle(color: Colors.black, fontSize: 24))
                                          : Text('0',
                                          style: TextStyle(color: Colors.black, fontSize: 24)),
                                      trailing: Icon(Icons.no_food),
                                    ),
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
                                            child: paymentList.isNotEmpty ? Table(
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
                                            )
                                                :Center(
                                              child: Column(
                                                children: [
                                                  Icon(Icons.credit_card_off_outlined),
                                                  Text(AppLocalizations.of(context)!.translate('no_payment_record'))
                                                ],
                                              ),
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
                                          Container(
                                            child: branchTaxList.isNotEmpty ? Table(
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
                                            )
                                                : Center(
                                              child: Column(
                                                children: [
                                                  Icon(Icons.no_meals_ouline),
                                                  Text(AppLocalizations.of(context)!.translate('no_charges_record'))
                                                ],
                                              ),
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
                  );
                } else {
                  ///mobile layout
                  return MediaQuery.of(context).orientation == Orientation.landscape ? Scaffold(
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
                  ) :
                  Scaffold(
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
                            Column(
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: SizedBox(
                                        height: 120,
                                        child: Card(
                                          color: color.iconColor,
                                          elevation: 5,
                                          child: ListTile(
                                            title: Text(AppLocalizations.of(context)!.translate('total_bills'),
                                                style: TextStyle(fontWeight: FontWeight.w500)),
                                            subtitle: Text('${dateOrderList.length}',
                                                style: TextStyle(color: Colors.black, fontSize: 20)),
                                          ),
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      child: SizedBox(
                                        height: 120,
                                        child: Card(
                                          color: color.iconColor,
                                          elevation: 5,
                                          child: ListTile(
                                            title: Text(AppLocalizations.of(context)!.translate('total_sales') + ' (MYR)',
                                                style: TextStyle(fontWeight: FontWeight.w500)),
                                            subtitle: Text('${totalSales.toStringAsFixed(2)}',
                                                style: TextStyle(color: Colors.black, fontSize: 20)),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                Row(
                                  children: [
                                    Expanded(
                                      child: SizedBox(
                                        height: 120,
                                        child: Card(
                                          color: color.iconColor,
                                          elevation: 5,
                                          child: ListTile(
                                            title: Text(AppLocalizations.of(context)!.translate('total_refund_bill'),
                                                style: TextStyle(fontWeight: FontWeight.w500)),
                                            subtitle: Text('${dateRefundList.length}',
                                                style: TextStyle(color: Colors.black, fontSize: 20)),
                                          ),
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      child: SizedBox(
                                        height: 120,
                                        child: Card(
                                          color: color.iconColor,
                                          elevation: 5,
                                          child: ListTile(
                                            title: Text(AppLocalizations.of(context)!.translate('total_refund'),
                                                style: TextStyle(fontWeight: FontWeight.w500)),
                                            subtitle: Text('${totalRefundAmount.toStringAsFixed(2)}',
                                                style: TextStyle(color: Colors.black, fontSize: 20)),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                Row(
                                  children: [
                                    Expanded(
                                      child: SizedBox(
                                        height: 120,
                                        child: Card(
                                          color: color.iconColor,
                                          elevation: 5,
                                          child: ListTile(
                                            title: Text(AppLocalizations.of(context)!.translate('total_discount'),
                                                style: TextStyle(fontWeight: FontWeight.w500)),
                                            subtitle: Text('${totalPromotionAmount.toStringAsFixed(2)}',
                                                style: TextStyle(color: Colors.black, fontSize: 20)),
                                          ),
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      child: SizedBox(
                                        height: 120,
                                        child: Card(
                                          color: color.iconColor,
                                          elevation: 5,
                                          child: ListTile(
                                            title: Text(AppLocalizations.of(context)!.translate('total_cancelled_item'),
                                                style: TextStyle(fontWeight: FontWeight.w500)),
                                            subtitle: dateOrderDetailCancel[0].total_item != null
                                                ? Text('${dateOrderDetailCancel[0].total_item!}',
                                                style: TextStyle(color: Colors.black, fontSize: 20))
                                                : Text('0',
                                                style: TextStyle(color: Colors.black, fontSize: 20)),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                Row(
                                  children: [
                                    Expanded(
                                      child: SizedBox(
                                        height: 120,
                                        child: Card(
                                          color: color.iconColor,
                                          elevation: 5,
                                          child: Column(
                                            children: [
                                              ListTile(
                                                title: Text(
                                                  AppLocalizations.of(context)!.translate('payment_overview'),
                                                    style: TextStyle(fontWeight: FontWeight.w500)
                                                ),
                                                subtitle: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Container(
                                                      padding: EdgeInsets.only(top: 10),
                                                      child: paymentList.isNotEmpty
                                                          ? Table(
                                                        children: [
                                                          for (var payment in paymentList)
                                                            TableRow(children: [
                                                              Container(
                                                                padding: EdgeInsets.only(bottom: 10),
                                                                child: Text('${payment.name}',
                                                                    style: TextStyle(color: Colors.black)),
                                                              ),
                                                              Container(
                                                                padding: EdgeInsets.only(bottom: 10),
                                                                child: Text('${payment.total_bill}',
                                                                    style: TextStyle(color: Colors.black)),
                                                              ),
                                                              Container(
                                                                padding: EdgeInsets.only(bottom: 10),
                                                                child: Text('${payment.totalAmount.toStringAsFixed(2)}',
                                                                    style: TextStyle(color: Colors.black)),
                                                              ),
                                                            ]),
                                                        ],
                                                      )
                                                          : Center(
                                                        child: Column(
                                                          children: [
                                                            Icon(Icons.credit_card_off_outlined),
                                                            Text(AppLocalizations.of(context)!.translate('no_payment_record')),
                                                          ],
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                Row(
                                  children: [
                                    Expanded(
                                      child: SizedBox(
                                        height: 120,
                                        child: Card(
                                          color: color.iconColor,
                                          elevation: 5,
                                          child: Column(
                                            children: [
                                              ListTile(
                                                title: Text(
                                                  AppLocalizations.of(context)!.translate('charges_overview'),
                                                  style: TextStyle(fontWeight: FontWeight.w500),
                                                ),
                                                subtitle: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Container(
                                                      padding: EdgeInsets.only(top: 10),
                                                      child: branchTaxList.isNotEmpty
                                                          ? Table(
                                                        children: [
                                                          for (var branchTax in branchTaxList)
                                                            TableRow(children: [
                                                              Container(
                                                                padding: EdgeInsets.only(bottom: 10),
                                                                child: Text('${branchTax.tax_name}',
                                                                    style: TextStyle(color: Colors.black)),
                                                              ),
                                                              Container(
                                                                padding: EdgeInsets.only(bottom: 10),
                                                                child: Text('${branchTax.total_amount.toStringAsFixed(2)}',
                                                                    style: TextStyle(color: Colors.black)),
                                                              ),
                                                            ]),
                                                        ],
                                                      )
                                                          : Center(
                                                        child: Column(
                                                          children: [
                                                            Icon(Icons.credit_card_off_outlined),
                                                            Text(AppLocalizations.of(context)!.translate('no_payment_record')),
                                                          ],
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            )
                          ],
                        ),
                      ),
                    ),
                  );
                }
              });
            } else {
              return CustomProgressBar();
            }
          }
        );
      });
    });
  }

  preload(ReportModel reportModel) async {
    currentStDate = reportModel.startDateTime;
    currentEdDate = reportModel.endDateTime;
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
    controller.sink.add("refresh");
  }

  readPaymentLinkCompany() async {
    this.stringList.clear();
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
            } else if (int.parse(dateOrderList[i].payment_link_company_id!) == 0) {
              List<OrderPaymentSplit> orderPaymentSplit = await PosDatabase.instance.readSpecificOrderSplitByOrderKey(dateOrderList[i].order_key!);
              for(int k = 0; k < orderPaymentSplit.length; k++) {
                if (paymentList[j].payment_link_company_id == int.parse(orderPaymentSplit[k].payment_link_company_id!)) {
                  paymentList[j].total_bill++;
                  paymentList[j].totalAmount += double.parse(orderPaymentSplit[k].amount!);
                }
              }
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
