import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:page_transition/page_transition.dart';
import 'package:pos_system/fragment/report/cancel_modifier_report.dart';
import 'package:pos_system/fragment/report/cancellation_report.dart';
import 'package:pos_system/fragment/report/cash_record_report.dart';
import 'package:pos_system/fragment/report/category_report.dart';
import 'package:pos_system/fragment/report/daily_sales_report.dart';
import 'package:pos_system/fragment/report/dining_report.dart';
import 'package:pos_system/fragment/report/modifier_report.dart';
import 'package:pos_system/fragment/report/payment_report.dart';
import 'package:pos_system/fragment/report/print_report_page.dart';
import 'package:pos_system/fragment/report/product_report.dart';
import 'package:pos_system/fragment/report/refund_report.dart';
import 'package:pos_system/fragment/report/report_overview.dart';
import 'package:pos_system/notifier/report_notifier.dart';
import 'package:pos_system/translation/AppLocalizations.dart';
import 'package:provider/provider.dart';
import 'package:side_navigation/side_navigation.dart';
import 'package:syncfusion_flutter_datepicker/datepicker.dart';

import '../../notifier/theme_color.dart';
import 'transfer_report.dart';

class ReportPage extends StatefulWidget {
  final ReportModel report;
  const ReportPage({Key? key, required this.report}) : super(key: key);

  @override
  State<ReportPage> createState() => _ReportPageState();
}

class _ReportPageState extends State<ReportPage> {
  late TextEditingController _controller;
  DateRangePickerController _dateRangePickerController = DateRangePickerController();
  DateFormat dateFormat = DateFormat("dd/MM/yyyy");
  String currentStDate = new DateFormat("yyyy-MM-dd 00:00:00").format(DateTime.now());
  String currentEdDate = new DateFormat("yyyy-MM-dd 00:00:00").format(DateTime.now());
  String dateTimeNow = '';
  String _range = '';
  bool isLoaded = false;
  List<Widget> views = [];
  int selectedIndex = 0;
  int currentPage = 0;


  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.report.initDateTime();
      widget.report.resetLoad();
    });
    dateTimeNow = dateFormat.format(DateTime.now());
    _controller = new TextEditingController(text: '${dateTimeNow} - ${dateTimeNow}');
    _dateRangePickerController.selectedRange = PickerDateRange(DateTime.now(), DateTime.now());
    currentPage = 0;
    preload();
  }

  void _onSelectionChanged(DateRangePickerSelectionChangedArgs args) {
    DateFormat _dateFormat = DateFormat("yyyy-MM-dd 00:00:00");
    if (args.value is PickerDateRange) {
      _range = '${DateFormat('dd/MM/yyyy').format(args.value.startDate)} -'
      // ignore: lines_longer_than_80_chars
          ' ${DateFormat('dd/MM/yyyy').format(args.value.endDate ?? args.value.startDate)}';

      this.currentStDate = _dateFormat.format(args.value.startDate);
      this.currentEdDate = _dateFormat.format(args.value.endDate ?? args.value.startDate);
      _dateRangePickerController.selectedRange = PickerDateRange(args.value.startDate, args.value.endDate ?? args.value.startDate);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeColor>(builder: (context, ThemeColor color, child) {
      return Consumer<ReportModel>(builder: (context, ReportModel reportModel, child){
          return LayoutBuilder(builder: (context, constraints) {
            if(constraints.maxWidth > 800){
              return Scaffold(
                resizeToAvoidBottomInset: false,
                appBar: AppBar(
                  primary: false,
                  automaticallyImplyLeading: false,
                  title: Row(
                    children: [
                      Text(AppLocalizations.of(context)!.translate('report'), style: TextStyle(fontSize: 25, color: Colors.black)),
                      Spacer(),
                      Visibility(
                        visible: this.currentPage != 11 ? true : false,
                        child: Container(
                          child: IconButton(
                              icon: Icon(Icons.print),
                              color: color.backgroundColor,
                              onPressed: (){
                                Navigator.push(
                                  context,
                                  PageTransition(
                                    type: PageTransitionType.bottomToTop,
                                    child: PrintReportPage(currentPage: this.currentPage,),
                                  ),
                                );
                              },
                          ),
                        ),
                      ),
                      SizedBox(width: 25),
                      Visibility(
                        visible: this.currentPage != 1 ? true : false,
                        child: Container(
                            margin: EdgeInsets.only(right: 10),
                            child: IconButton(
                              onPressed: () {
                                showDialog(barrierDismissible: false, context: context, builder: (BuildContext context) {
                                  return WillPopScope(
                                    onWillPop: ()  async  {
                                      dateTimeNow = dateFormat.format(DateTime.now());
                                      _controller = new TextEditingController(text: '${dateTimeNow} - ${dateTimeNow}');
                                      _dateRangePickerController.selectedRange = PickerDateRange(DateTime.now(), DateTime.now());
                                      setState(() {
                                        reportModel.setDateTime(this.currentStDate, this.currentEdDate);
                                        reportModel.resetLoad();
                                      });
                                      return true;
                                    },
                                    child: AlertDialog(
                                      title: Text(AppLocalizations.of(context)!.translate('select_a_date_range')),
                                      content: Container(
                                        height: 400,
                                        width: 450,
                                        child: Container(
                                          child: Card(
                                            elevation: 10,
                                            child: SfDateRangePicker(
                                              view: DateRangePickerView.month,
                                              controller: _dateRangePickerController,
                                              selectionMode: DateRangePickerSelectionMode.range,
                                              allowViewNavigation: true,
                                              showActionButtons: true,
                                              showTodayButton: true,
                                              onSelectionChanged: _onSelectionChanged,
                                              maxDate: DateTime.now(),
                                              confirmText: AppLocalizations.of(context)!.translate('ok'),
                                              cancelText: AppLocalizations.of(context)!.translate('cancel'),
                                              onSubmit: (object) {
                                                _controller = _range != '' ?
                                                new TextEditingController(text: '${_range}')
                                                    :
                                                new TextEditingController(text: '${dateTimeNow} - ${dateTimeNow}');
                                                setState(() {
                                                  reportModel.setDateTime(this.currentStDate, this.currentEdDate);
                                                  reportModel.resetLoad();
                                                });
                                                Navigator.of(context).pop();
                                              },
                                              onCancel: (){
                                                Navigator.of(context).pop();
                                              },

                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                });
                              },
                              icon: Icon(Icons.calendar_month),
                              color: color.backgroundColor,
                            )),
                      ),
                      Visibility(
                        visible: this.currentPage != 1 ? true : false,
                        child: Container(
                          width: 300,
                          height: 55,
                          child: TextField(
                            controller: _controller,
                            decoration: InputDecoration(
                              border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(5.0)))
                            ),
                            style: TextStyle(color: Colors.black),
                            enabled: false,
                          ),
                        ),
                      ),
                    ],
                  ),
                  backgroundColor: Color(0xffFAFAFA),
                  elevation: 0,
                ),
                body: Padding(
                  padding: EdgeInsets.fromLTRB(8, 10, 8, 8),
                  child: Row(
                    children: [
                      SideNavigationBar(
                        expandable: false,
                        theme: SideNavigationBarTheme(
                          backgroundColor: Colors.white,
                          togglerTheme: SideNavigationBarTogglerTheme.standard(),
                          itemTheme: SideNavigationBarItemTheme(
                            selectedItemColor: color.backgroundColor,
                          ),
                          dividerTheme: SideNavigationBarDividerTheme.standard(),
                        ),
                        selectedIndex: selectedIndex,
                        items: [
                          SideNavigationBarItem(
                            icon: Icons.view_comfy_alt,
                            label: AppLocalizations.of(context)!.translate('overview'),
                          ),
                          SideNavigationBarItem(
                            icon: Icons.list_alt,
                            label: AppLocalizations.of(context)!.translate('daily_sales'),
                          ),
                          SideNavigationBarItem(
                            icon: Icons.fastfood,
                            label: AppLocalizations.of(context)!.translate('product_report'),
                          ),
                          SideNavigationBarItem(
                            icon: Icons.fastfood,
                            label: AppLocalizations.of(context)!.translate('category_report'),
                          ),
                          SideNavigationBarItem(
                            icon: Icons.fastfood,
                            label: AppLocalizations.of(context)!.translate('modifier_report'),
                          ),
                          SideNavigationBarItem(
                            icon: Icons.no_food,
                            label: AppLocalizations.of(context)!.translate('cancel_report'),
                          ),
                          SideNavigationBarItem(
                            icon: Icons.no_food,
                            label: AppLocalizations.of(context)!.translate('cancel_modifier_report'),
                          ),
                          SideNavigationBarItem(
                            icon: Icons.local_dining,
                            label: AppLocalizations.of(context)!.translate('dining_report'),
                          ),
                          SideNavigationBarItem(
                            icon: Icons.payment,
                            label: AppLocalizations.of(context)!.translate('payment_report'),
                          ),
                          SideNavigationBarItem(
                            icon: Icons.refresh,
                            label: AppLocalizations.of(context)!.translate('refund_report'),
                          ),
                          SideNavigationBarItem(
                            icon: Icons.monetization_on,
                            label: AppLocalizations.of(context)!.translate('cash_record_report'),
                          ),
                          SideNavigationBarItem(
                            icon: Icons.compare_arrows,
                            label: AppLocalizations.of(context)!.translate('transfer_report'),
                          ),
                        ],
                        onTap: (index) {
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            reportModel.resetLoad();
                          });
                          setState(() {
                            this.currentPage = index;
                            selectedIndex = index;
                          });
                        },
                      ),
                      Expanded(
                        child: views.elementAt(selectedIndex),
                      )
                    ],
                  ),
                ),
              );
            } else {
              ///mobile layout
              return Scaffold(
                resizeToAvoidBottomInset: false,
                appBar: AppBar(
                  automaticallyImplyLeading: false,
                  title: Row(
                    children: [
                      Text(AppLocalizations.of(context)!.translate('report'), style: TextStyle(fontSize: 25, color: Colors.black)),
                      Spacer(),
                      Visibility(
                        visible: this.currentPage != 11 ? true : false,
                        child: IconButton(
                          icon: Icon(Icons.print),
                          color: color.backgroundColor,
                          onPressed: (){
                            Navigator.push(
                              context,
                              PageTransition(
                                type: PageTransitionType.bottomToTop,
                                child: PrintReportPage(currentPage: this.currentPage,),
                              ),
                            );
                          },
                        ),
                      ),
                      Visibility(
                        visible: this.currentPage != 1 ? true : false,
                        child: Container(
                            margin: EdgeInsets.only(right: 10),
                            child: IconButton(
                              onPressed: () {
                                showDialog(context: context, builder: (BuildContext context) {
                                  return WillPopScope(
                                    onWillPop: ()  async  {
                                      dateTimeNow = dateFormat.format(DateTime.now());
                                      _controller = new TextEditingController(text: '${dateTimeNow} - ${dateTimeNow}');
                                      _dateRangePickerController.selectedRange = PickerDateRange(DateTime.now(), DateTime.now());
                                      setState(() {
                                        reportModel.setDateTime(this.currentStDate, this.currentEdDate);
                                        reportModel.resetLoad();
                                      });
                                      return true;
                                    },
                                    child: AlertDialog(
                                      contentPadding: EdgeInsets.zero,
                                      content: Container(
                                        height: MediaQuery.of(context).size.height,
                                        width: MediaQuery.of(context).size.width,
                                        child: SfDateRangePicker(
                                          controller: _dateRangePickerController,
                                          selectionMode: DateRangePickerSelectionMode.range,
                                          allowViewNavigation: true,
                                          showActionButtons: true,
                                          showTodayButton: true,
                                          onSelectionChanged: _onSelectionChanged,
                                          maxDate: DateTime.now(),
                                          onSubmit: (object) {
                                            _controller = _range != '' ?
                                            new TextEditingController(text: '${_range}')
                                                :
                                            new TextEditingController(text: '${dateTimeNow} - ${dateTimeNow}');
                                            setState(() {
                                              reportModel.setDateTime(this.currentStDate, this.currentEdDate);
                                              reportModel.resetLoad();
                                            });
                                            Navigator.of(context).pop();
                                          },
                                          onCancel: (){
                                            Navigator.of(context).pop();
                                          },

                                        ),
                                      ),
                                    ),
                                  );
                                });
                              },
                              icon: Icon(Icons.calendar_month),
                              color: color.backgroundColor,
                            )),
                      ),
                      Visibility(
                        visible: this.currentPage != 1 ? true : false,
                        child: Container(
                          width: 230,
                          height: 55,
                          child: TextField(
                            controller: _controller,
                            decoration: InputDecoration(
                                border: OutlineInputBorder(
                                    borderRadius: BorderRadius.all(Radius.circular(5.0)))
                            ),
                            style: TextStyle(color: Colors.black),
                            enabled: false,
                          ),
                        ),
                      ),
                    ],
                  ),
                  backgroundColor: Color(0xffFAFAFA),
                  elevation: 0,
                ),
                body: Padding(
                  padding: EdgeInsets.fromLTRB(8, 10, 8, 8),
                  child: Row(
                    children: [
                      SideNavigationBar(
                        initiallyExpanded: false,
                        expandable: false,
                        theme: SideNavigationBarTheme(
                          backgroundColor: Colors.white,
                          togglerTheme: SideNavigationBarTogglerTheme.standard(),
                          itemTheme: SideNavigationBarItemTheme(
                            selectedItemColor: color.backgroundColor,
                          ),
                          dividerTheme: SideNavigationBarDividerTheme.standard(),
                        ),
                        selectedIndex: selectedIndex,
                        items: [
                          SideNavigationBarItem(
                            icon: Icons.view_comfy_alt,
                            label: AppLocalizations.of(context)!.translate('overview'),
                          ),
                          SideNavigationBarItem(
                            icon: Icons.list_alt,
                            label: AppLocalizations.of(context)!.translate('daily_sales'),
                          ),
                          SideNavigationBarItem(
                            icon: Icons.fastfood,
                            label: AppLocalizations.of(context)!.translate('product_report'),
                          ),
                          SideNavigationBarItem(
                            icon: Icons.fastfood,
                            label: AppLocalizations.of(context)!.translate('category_report'),
                          ),
                          SideNavigationBarItem(
                            icon: Icons.fastfood,
                            label: AppLocalizations.of(context)!.translate('modifier_report'),
                          ),
                          SideNavigationBarItem(
                            icon: Icons.no_food,
                            label: AppLocalizations.of(context)!.translate('cancel_report'),
                          ),
                          SideNavigationBarItem(
                            icon: Icons.no_food,
                            label: 'Cancel Modifier Report',
                          ),
                          SideNavigationBarItem(
                            icon: Icons.local_dining,
                            label: AppLocalizations.of(context)!.translate('dining_report'),
                          ),
                          SideNavigationBarItem(
                            icon: Icons.payment,
                            label: AppLocalizations.of(context)!.translate('payment_report'),
                          ),
                          SideNavigationBarItem(
                            icon: Icons.refresh,
                            label: AppLocalizations.of(context)!.translate('refund_report'),
                          ),
                          SideNavigationBarItem(
                            icon: Icons.monetization_on,
                            label: AppLocalizations.of(context)!.translate('cash_record_report'),
                          ),
                          SideNavigationBarItem(
                            icon: Icons.compare_arrows,
                            label: AppLocalizations.of(context)!.translate('transfer_report'),
                          ),
                        ],
                        onTap: (index) {
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            reportModel.resetLoad();
                          });
                          setState(() {
                            this.currentPage = index;
                            selectedIndex = index;
                          });
                        },
                      ),
                      Expanded(
                        child: views.elementAt(selectedIndex),
                      )
                    ],
                  ),
                ),
              );
            }
          });
        }
      );
    });
  }
  preload(){
    views.addAll([
      Container(
        child: ReportOverview(),
      ),
      Container(
        child: DailySalesReport(),
      ),
      Container(
        child: ProductReport(),
      ),
      Container(
        child: CategoryReport(),
      ),
      Container(
        child: ModifierReport(),
      ),
      Container(
        child: CancellationReport(),
      ),
      Container(
        child: CancelModifierReport(),
      ),
      Container(
        child: DiningReport(),
      ),
      Container(
        child: PaymentReport(),
      ),
      Container(
        child: RefundReport(),
      ),
      Container(
        child: CashRecordReport(),
      ),
      Container(
        child: TransferRecord(),
      ),
    ]);
  }
}
