import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pos_system/database/pos_database.dart';
import 'package:pos_system/object/branch_link_tax.dart';
import 'package:pos_system/object/order.dart';
import 'package:pos_system/object/order_detail.dart';
import 'package:pos_system/object/order_promotion_detail.dart';
import 'package:pos_system/object/order_tax_detail.dart';
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
  late TextEditingController _controller;
  DateRangePickerController _dateRangePickerController = DateRangePickerController();
  DateFormat dateFormat = DateFormat("dd/MM/yyyy");
  String currentStDate = new DateFormat("yyyy-MM-dd 00:00:00").format(DateTime.now());
  String currentEdDate = new DateFormat("yyyy-MM-dd 00:00:00").format(DateTime.now());
  List<Order> paidOrderList = [], dateOrderList = [];
  List<OrderDetail> cancelledOrderDetail = [], dateOrderDetail = [];
  List<OrderPromotionDetail> paidPromotionDetail = [], datePromotionDetail = [];
  List<OrderTaxDetail> paidOrderTaxDetail = [], dateTaxDetail = [];
  List<PaymentLinkCompany> paymentList = [];
  List<BranchLinkTax> branchTaxList = [];
  ReportObject? reportObject;
  String jsonPayment = '';
  double totalSales = 0.0;
  double totalPromotionAmount = 0.0;
  String dateTimeNow = '';
  String _range = '';
  bool isLoaded = false;

  void _onSelectionChanged(DateRangePickerSelectionChangedArgs args) {
    DateFormat _dateFormat = DateFormat("yyyy-MM-dd 00:00:00");
    if (args.value is PickerDateRange) {
      _range = '${DateFormat('dd/MM/yyyy').format(args.value.startDate)} -'
      // ignore: lines_longer_than_80_chars
          ' ${DateFormat('dd/MM/yyyy').format(args.value.endDate ?? args.value.startDate)}';

      currentStDate = _dateFormat.format(args.value.startDate);
      currentEdDate = _dateFormat.format(args.value.endDate ?? args.value.startDate);
      _dateRangePickerController.selectedRange = PickerDateRange(args.value.startDate, args.value.endDate ?? args.value.startDate);
    }
  }

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
                              child: Text('Overview',
                                  style: TextStyle(fontSize: 25, color: Colors.black)),
                            ),
                            Spacer(),
                            Container(
                                margin: EdgeInsets.only(right: 10),
                                child: IconButton(
                                  onPressed: () {
                                    showDialog(context: context, builder: (BuildContext context) {
                                      return AlertDialog(
                                        title: Text('Select a date range'),
                                        content: Container(
                                          height: 350,
                                          width: 350,
                                          child: Container(
                                            child: Card(
                                              child: SfDateRangePicker(
                                                controller: _dateRangePickerController,
                                                selectionMode: DateRangePickerSelectionMode.range,
                                                onSelectionChanged: _onSelectionChanged,
                                                showActionButtons: true,
                                                onSubmit: (object) {
                                                  this.dateOrderList.clear();
                                                  this.dateOrderDetail.clear();
                                                  this.dateTaxDetail.clear();
                                                  this.datePromotionDetail.clear();
                                                  _controller = new TextEditingController(text: '${_range}');
                                                  preload();
                                                  Navigator.of(context).pop();
                                                },
                                                onCancel: (){
                                                  Navigator.of(context).pop();
                                                },

                                              ),
                                            ),
                                          ),
                                        ),
                                      );
                                    });
                                  },
                                  icon: Icon(Icons.calendar_month),
                                )),
                            Container(
                              width: 300,
                              child: TextField(
                                controller: _controller,
                                enabled: false,
                              ),
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
                                  subtitle: Text('${reportObject!.dateRefundOrderList!.length}',
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
                                  subtitle: Text('${reportObject!.totalSales!.toStringAsFixed(2)}',
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
                                  title: Text('Total Cancellation'),
                                  subtitle: Text('${dateOrderDetail.length}',
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
          return Scaffold(
            resizeToAvoidBottomInset: false,
            body: Container(
              padding: const EdgeInsets.all(8),
              child: Text('this is overview'),
            ),
          );
        }
      });
    });
  }

  preload() async {
    await getAllPaidOrder();
    await readPaymentLinkCompany();
    await getAllPaidOrderTaxDetail();
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
    List<BranchLinkTax> _data = await PosDatabase.instance.readBranchLinkTax();
    if(_data.isNotEmpty){
      branchTaxList = _data;
      for(int i = 0; i < branchTaxList.length; i++){
        for(int j = 0; j < dateTaxDetail.length; j++){
          if(branchTaxList[i].tax_id == dateTaxDetail[j].tax_id){
            branchTaxList[i].total_amount += double.parse(dateTaxDetail[j].tax_amount!);
          }
        }
      }
    }
  }

  getAllPaidOrderTaxDetail() async {
    DateTime _startDate = DateTime.parse(currentStDate);
    DateTime _endDate = DateTime.parse(currentEdDate);
    List<OrderTaxDetail> _taxData = await PosDatabase.instance.readAllPaidOrderTax();
    if(_taxData.isNotEmpty){
      paidOrderTaxDetail = _taxData;
      for(int i = 0; i < paidOrderTaxDetail.length; i++){
        DateTime convertDate = new DateFormat("yyyy-MM-dd HH:mm:ss").parse(paidOrderTaxDetail[i].created_at!);
        if(currentStDate != currentEdDate){
          if(convertDate.isAfter(_startDate)){
            if(convertDate.isBefore(addDays(date: _endDate))){
              dateTaxDetail.add(paidOrderTaxDetail[i]);
            }
          }
        } else {
          if(convertDate.isAfter(_startDate) && convertDate.isBefore(addDays(date: _endDate))){
            dateTaxDetail.add(paidOrderTaxDetail[i]);
          }
        }
      }
    }
  }

  getAllPaidOrder() async {
    ReportObject object = await ReportObject().getAllPaidOrder(currentStDate: currentStDate, currentEdDate: currentEdDate);
    reportObject = object;
    dateOrderList = reportObject!.dateOrderList!;
    totalSales = reportObject!.totalSales!;
    // DateTime _startDate = DateTime.parse(currentStDate);
    // DateTime _endDate = DateTime.parse(currentEdDate);
    // this.totalSales = 0.0;
    // List<Order> orderData = await PosDatabase.instance.readAllOrder();
    // paidOrderList = orderData;
    // if (paidOrderList.isNotEmpty) {
    //   for (int i = 0; i < paidOrderList.length; i++) {
    //     DateTime convertDate = new DateFormat("yyyy-MM-dd HH:mm:ss").parse(paidOrderList[i].created_at!);
    //     if(currentStDate != currentEdDate){
    //       if(convertDate.isAfter(_startDate)){
    //         if(convertDate.isBefore(addDays(date: _endDate))){
    //           dateOrderList.add(paidOrderList[i]);
    //         }
    //       }
    //     } else {
    //       if(convertDate.isAfter(_startDate) && convertDate.isBefore(addDays(date: _endDate))){
    //         dateOrderList.add(paidOrderList[i]);
    //       }
    //     }
    //
    //   }
    //   for (int j = 0; j < dateOrderList.length; j++) {
    //     if(dateOrderList[j].payment_status != 2){
    //       sumAllOrderTotal(dateOrderList[j].final_amount!);
    //     }
    //   }
    // }
  }

  getAllPaidOrderPromotionDetail() async {
    DateTime _startDate = DateTime.parse(currentStDate);
    DateTime _endDate = DateTime.parse(currentEdDate);
    this.totalPromotionAmount = 0.0;
    List<OrderPromotionDetail> detailData = await PosDatabase.instance.readAllPaidOrderPromotionDetail();
    this.paidPromotionDetail = detailData;
    print('paid promo length: ${paidPromotionDetail.length}');
    if (paidPromotionDetail.isNotEmpty) {
      for (int i = 0; i < paidPromotionDetail.length; i++) {
        DateTime convertDate = new DateFormat("yyyy-MM-dd HH:mm:ss").parse(paidPromotionDetail[i].created_at!);
        if(currentStDate != currentEdDate){
          if(convertDate.isAfter(_startDate)){
            if(convertDate.isBefore(addDays(date: _endDate))){
              datePromotionDetail.add(paidPromotionDetail[i]);
            }
          }
        } else {
          if(convertDate.isAfter(_startDate) && convertDate.isBefore(addDays(date: _endDate))){
            datePromotionDetail.add(paidPromotionDetail[i]);
          }
        }
      }
      print('data length: ${datePromotionDetail.length}');
      for (int j = 0; j < datePromotionDetail.length; j++) {
        sumAllPromotionAmount(datePromotionDetail[j].promotion_amount!);
      }
      print(this.totalPromotionAmount);
    }
  }

  getRefund() async {
    ReportObject object = await ReportObject().getAllRefundOrder(currentStDate: currentStDate, currentEdDate: currentEdDate);
    reportObject = object;
  }

  getAllCancelOrderDetail() async {
    DateTime _startDate = DateTime.parse(currentStDate);
    DateTime _endDate = DateTime.parse(currentEdDate);
    List<OrderDetail> detailData = await PosDatabase.instance.readAllCancelItem();
    this.cancelledOrderDetail = detailData;
    if (cancelledOrderDetail.isNotEmpty) {
      for (int i = 0; i < cancelledOrderDetail.length; i++) {
        DateTime convertDate = new DateFormat("yyyy-MM-dd HH:mm:ss").parse(cancelledOrderDetail[i].created_at!);
        if(currentStDate != currentEdDate){
          if(convertDate.isAfter(_startDate)){
            if(convertDate.isBefore(addDays(date: _endDate))){
              dateOrderDetail.add(cancelledOrderDetail[i]);
            }
          }
        } else {
          if(convertDate.isAfter(_startDate) && convertDate.isBefore(addDays(date: _endDate))){
            dateOrderDetail.add(cancelledOrderDetail[i]);
          }
        }
      }
    }
    setState(() {
      isLoaded = true;
    });
  }

  addDays({date}){
    var _date = date.add(Duration(days: 1));
    return _date;
  }

  sumAllPromotionAmount(String promotionAmount) {
    return this.totalPromotionAmount += double.parse(promotionAmount);
  }

  sumAllOrderTotal(String finalAmount) {
    return this.totalSales += double.parse(finalAmount);
  }
}
