import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:page_transition/page_transition.dart';
import 'package:pos_system/fragment/report/cancel_modifier_report.dart';
import 'package:pos_system/fragment/report/cancellation_report.dart';
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
                  automaticallyImplyLeading: false,
                  title: Row(
                    children: [
                      Text('Report', style: TextStyle(fontSize: 25, color: Colors.black)),
                      Spacer(),
                      Visibility(
                        visible: this.currentPage != 10 ? true : false,
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
                                      title: Text('Select a date range'),
                                      content: Container(
                                        height: 350,
                                        width: 350,
                                        child: Container(
                                          child: Card(
                                            elevation: 10,
                                            child: SfDateRangePicker(
                                              controller: _dateRangePickerController,
                                              selectionMode: DateRangePickerSelectionMode.range,
                                              allowViewNavigation: false,
                                              onSelectionChanged: _onSelectionChanged,
                                              maxDate: DateTime.now(),
                                              showActionButtons: true,
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
                          child: TextField(
                            controller: _controller,
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
                        items: const [
                          SideNavigationBarItem(
                            icon: Icons.view_comfy_alt,
                            label: 'Overview',
                          ),
                          SideNavigationBarItem(
                            icon: Icons.list_alt,
                            label: 'Daily Sales',
                          ),
                          SideNavigationBarItem(
                            icon: Icons.fastfood,
                            label: 'Product Report',
                          ),
                          SideNavigationBarItem(
                            icon: Icons.fastfood,
                            label: 'Category Report',
                          ),
                          SideNavigationBarItem(
                            icon: Icons.fastfood,
                            label: 'Modifier Report',
                          ),
                          SideNavigationBarItem(
                            icon: Icons.no_food,
                            label: 'Cancel Report',
                          ),
                          SideNavigationBarItem(
                            icon: Icons.no_food,
                            label: 'Cancel Modifier Report',
                          ),
                          SideNavigationBarItem(
                            icon: Icons.local_dining,
                            label: 'Dining Report',
                          ),
                          SideNavigationBarItem(
                            icon: Icons.payment,
                            label: 'Payment Report',
                          ),
                          SideNavigationBarItem(
                            icon: Icons.refresh,
                            label: 'Refund Report',
                          ),
                          SideNavigationBarItem(
                            icon: Icons.compare_arrows,
                            label: 'Transfer Report',
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
                      Text('Report', style: TextStyle(fontSize: 25, color: Colors.black)),
                      Spacer(),
                      Visibility(
                        visible: this.currentPage != 10 ? true : false,
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
                                        child: Container(
                                          child: Card(
                                            child: SfDateRangePicker(
                                              controller: _dateRangePickerController,
                                              selectionMode: DateRangePickerSelectionMode.range,
                                              allowViewNavigation: false,
                                              onSelectionChanged: _onSelectionChanged,
                                              maxDate: DateTime.now(),
                                              showActionButtons: true,
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
                          width: 200,
                          child: TextField(
                            controller: _controller,
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
                        items: const [
                          SideNavigationBarItem(
                            icon: Icons.view_comfy_alt,
                            label: 'Overview',
                          ),
                          SideNavigationBarItem(
                            icon: Icons.list_alt,
                            label: 'Daily Sales',
                          ),
                          SideNavigationBarItem(
                            icon: Icons.fastfood,
                            label: 'Product Report',
                          ),
                          SideNavigationBarItem(
                            icon: Icons.fastfood,
                            label: 'Category Report',
                          ),
                          SideNavigationBarItem(
                            icon: Icons.fastfood,
                            label: 'Modifier Report',
                          ),
                          SideNavigationBarItem(
                            icon: Icons.no_food,
                            label: 'Cancel Report',
                          ),
                          SideNavigationBarItem(
                            icon: Icons.no_food,
                            label: 'Cancel Modifier Report',
                          ),
                          SideNavigationBarItem(
                            icon: Icons.local_dining,
                            label: 'Dining Report',
                          ),
                          SideNavigationBarItem(
                            icon: Icons.payment,
                            label: 'Payment Report',
                          ),
                          SideNavigationBarItem(
                            icon: Icons.refresh,
                            label: 'Refund Report',
                          ),
                          SideNavigationBarItem(
                            icon: Icons.compare_arrows,
                            label: 'Transfer Report',
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
        child: TransferRecord(),
      ),
    ]);
  }
}
