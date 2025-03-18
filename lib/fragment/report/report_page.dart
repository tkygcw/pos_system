import 'dart:convert';
import 'package:collapsible_sidebar/collapsible_sidebar.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';
import 'package:page_transition/page_transition.dart';
import 'package:pos_system/database/pos_database.dart';
import 'package:pos_system/fragment/report/attedance_report.dart';
import 'package:pos_system/fragment/report/cancel_modifier_report.dart';
import 'package:pos_system/fragment/report/cancel_record_report.dart';
import 'package:pos_system/fragment/report/cancellation_report.dart';
import 'package:pos_system/fragment/report/cash_record_report.dart';
import 'package:pos_system/fragment/report/category_report.dart';
import 'package:pos_system/fragment/report/daily_sales_report.dart';
import 'package:pos_system/fragment/report/sales_summary_report.dart';
import 'package:pos_system/fragment/report/dining_report.dart';
import 'package:pos_system/fragment/report/modifier_report.dart';
import 'package:pos_system/fragment/report/payment_report.dart';
import 'package:pos_system/fragment/report/print_report_page.dart';
import 'package:pos_system/fragment/report/product_edited_report.dart';
import 'package:pos_system/fragment/report/product_report.dart';
import 'package:pos_system/fragment/report/refund_report.dart';
import 'package:pos_system/fragment/report/report_overview.dart';
import 'package:pos_system/fragment/report/report_receipt/layout/cancel_record_layout.dart';
import 'package:pos_system/fragment/report/report_receipt/layout/cancellation_layout.dart';
import 'package:pos_system/fragment/report/report_receipt/layout/cancelled_mod_layout.dart';
import 'package:pos_system/fragment/report/report_receipt/layout/category_layout.dart';
import 'package:pos_system/fragment/report/report_receipt/layout/dining_layout.dart';
import 'package:pos_system/fragment/report/report_receipt/layout/modifier_layout.dart';
import 'package:pos_system/fragment/report/report_receipt/layout/overview_layout.dart';
import 'package:pos_system/fragment/report/report_receipt/layout/payment_layout.dart';
import 'package:pos_system/fragment/report/report_receipt/layout/product_layout.dart';
import 'package:pos_system/fragment/report/report_receipt/layout/staff_layout.dart';
import 'package:pos_system/fragment/report/report_receipt/print_report_receipt.dart';
import 'package:pos_system/fragment/report/staff_sales_report.dart';
import 'package:pos_system/notifier/report_notifier.dart';
import 'package:pos_system/object/user.dart';
import 'package:pos_system/translation/AppLocalizations.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
  PrintReportReceipt receipt = PrintReportReceipt();
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
  bool _isChecked = false;
  late SharedPreferences prefs;
  final adminPosPinController = TextEditingController();
  bool isButtonDisabled = false,  _obscureText = true;
  bool _submitted = false;
  bool isLogOut = false;
  late bool reportPermission = true;
  late bool dialogPrompt = false;

  @override
  void initState() {
    super.initState();
    context.read<ReportModel>().resetDateTime();
    dateTimeNow = dateFormat.format(DateTime.now());
    _controller = TextEditingController(text: '${dateTimeNow} - ${dateTimeNow}');
    _dateRangePickerController.selectedRange = PickerDateRange(DateTime.now(), DateTime.now());
    currentPage = 0;
    getPrefData();
    preload();
    checkAccess();
    receipt.readCashierPrinter();
  }

  readAdminData(String pin) async {
    try {
      User? userData = await PosDatabase.instance.readSpecificUserWithPin(pin);
      if (userData != null) {
        if(userData.report_permission == 1) {
          setState(() {
            reportPermission = true;
          });
        } else {
          reportPermission = false;
          Fluttertoast.showToast(backgroundColor: Color(0xFFFF0000), msg: "${AppLocalizations.of(context)?.translate('no_permission')}");
        }
      } else {
        adminPosPinController.clear();
        Fluttertoast.showToast(backgroundColor: Color(0xFFFF0000), msg: "${AppLocalizations.of(context)?.translate('user_not_found')}");
      }
    } catch (e) {
      print('delete error ${e}');
    }
  }

  String? get errorPassword {
    final text = adminPosPinController.value.text;
    //readAdminData(text);
    if (text.isEmpty) {
      return 'password_required';
    }
    return null;
  }

  void _submit(BuildContext context) async {
    setState(() => _submitted = true);
    if (errorPassword == null) {
      await readAdminData(adminPosPinController.text);
    } else {
      setState(() {
        isButtonDisabled = false;
      });
    }
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
    var deviceHeight = MediaQuery.of(context).size.height;
    var deviceWidth = MediaQuery.of(context).size.width;
    return Consumer<ThemeColor>(builder: (context, ThemeColor color, child) {
      return Consumer<ReportModel>(builder: (context, ReportModel reportModel, child){
        if(deviceWidth > 900 && deviceHeight > 500){
          if(reportPermission) {
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
                      visible: currentPage != 2 && currentPage != 15 && currentPage != 16 ? true : false,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          Checkbox(
                            value: _isChecked,
                            onChanged: (bool? value) {
                              setState(() {
                                _isChecked = !_isChecked;
                                prefs.setBool('reportBasedOnOB', _isChecked);
                                reportModel.refresh();
                              });
                            },
                          ),
                          GestureDetector(
                            onTap: () {
                              Fluttertoast.showToast(msg: AppLocalizations.of(context)!.translate('report_calculate_based_on_opening_balance'));
                            },
                            child: Row(
                              children: <Widget>[
                                Text(AppLocalizations.of(context)!.translate('advanced')),
                                SizedBox(width: 4),
                                Icon(Icons.info, color: color.backgroundColor, size: 22,),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: 25),
                    Visibility(
                      visible: currentPage != 2 && currentPage != 16 ? true : false,
                      child: Container(
                        child: IconButton(
                          icon: Icon(Icons.print),
                          color: color.backgroundColor,
                          onPressed: (){
                            Navigator.push(
                              context,
                              PageTransition(
                                type: PageTransitionType.bottomToTop,
                                child: PrintReportPage(currentPage: currentPage,),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    Visibility(
                      visible: currentPage != 1 && currentPage != 2 && currentPage != 6 && currentPage != 12 && currentPage != 13
                          && currentPage != 15 && currentPage != 16  ? true : false,
                      child: Container(
                        child: IconButton(
                          icon: Icon(Icons.receipt),
                          color: color.backgroundColor,
                          onPressed: receiptOnPressed,
                        ),
                      ),
                    ),
                    Container(
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
                                    reportModel.setDateTime(currentStDate, currentEdDate);
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
                                              reportModel.setDateTime(currentStDate, currentEdDate);
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
                    Container(
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
                          label: AppLocalizations.of(context)!.translate('sales_summary'),
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
                          icon: Icons.fastfood,
                          label: AppLocalizations.of(context)!.translate('edit_report'),
                        ),
                        SideNavigationBarItem(
                          icon: Icons.no_food,
                          label: AppLocalizations.of(context)!.translate('cancel_report'),
                        ),
                        SideNavigationBarItem(
                          icon: Icons.no_food,
                          label: AppLocalizations.of(context)!.translate('cancel_record_report'),
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
                          label: AppLocalizations.of(context)!.translate('cashflow_report'),
                        ),
                        SideNavigationBarItem(
                          icon: Icons.person,
                          label: AppLocalizations.of(context)!.translate('staff_sales_report'),
                        ),
                        SideNavigationBarItem(
                          icon: Icons.person,
                          label: AppLocalizations.of(context)!.translate('attendance_report'),
                        ),
                        SideNavigationBarItem(
                          icon: Icons.compare_arrows,
                          label: AppLocalizations.of(context)!.translate('transfer_report'),
                        ),
                      ],
                      onTap: (index) {
                        setState(() {
                          currentPage = index;
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
            return StatefulBuilder(builder: (context, StateSetter setState) {
              return Center(
                child: SingleChildScrollView(
                  physics: NeverScrollableScrollPhysics(),
                  child: AlertDialog(
                    title: Text(AppLocalizations.of(context)!.translate('enter_admin_pin')),
                    content: SizedBox(
                      height: 75.0,
                      width: 350.0,
                      child: ValueListenableBuilder(
                          valueListenable: adminPosPinController,
                          builder: (context, TextEditingValue value, __) {
                            return Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: TextField(
                                autofocus: true,
                                onSubmitted: (input) {
                                  setState(() {
                                    isButtonDisabled = true;
                                  });
                                  _submit(context);
                                  if(mounted){
                                    setState(() {
                                      isButtonDisabled = false;
                                    });
                                  }
                                },
                                obscureText: _obscureText,
                                controller: adminPosPinController,
                                keyboardType: TextInputType.numberWithOptions(decimal: true),
                                decoration: InputDecoration(
                                  suffixIcon: IconButton(
                                    icon: Icon(_obscureText ? Icons.visibility_off : Icons.visibility),
                                    onPressed: () {
                                      setState(() {
                                        _obscureText = !_obscureText;
                                      });
                                    },
                                  ),
                                  errorText: _submitted
                                      ? errorPassword == null
                                      ? errorPassword
                                      : AppLocalizations.of(context)?.translate(errorPassword!)
                                      : null,
                                  border: OutlineInputBorder(
                                    borderSide: BorderSide(color: color.backgroundColor),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderSide: BorderSide(color: color.backgroundColor),
                                  ),
                                  labelText: "PIN",
                                ),
                              ),
                            );
                          }),
                    ),
                    actions: <Widget>[
                      SizedBox(
                        width: MediaQuery.of(context).size.width / 6,
                        height: MediaQuery.of(context).size.height / 12,
                        child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: color.backgroundColor,
                            ),
                            child: Text(
                              AppLocalizations.of(context)!.translate('clear'),
                              style: TextStyle(color: Colors.white),
                            ),
                            onPressed: (){
                              adminPosPinController.clear();
                            }
                        ),
                      ),
                      SizedBox(
                        width: MediaQuery.of(context).size.width / 6,
                        height:  MediaQuery.of(context).size.height / 12,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: color.buttonColor,
                          ),
                          child: Text(
                            AppLocalizations.of(context)!.translate('yes'),
                            style: TextStyle(color: Colors.white),
                          ),
                          onPressed: isButtonDisabled
                              ? null
                              : () async {
                            setState(() {
                              isButtonDisabled = true;
                            });
                            _submit(context);
                            if(mounted){
                              setState(() {
                                isButtonDisabled = false;
                              });
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              );
            });
          }
        } else {
          ///mobile layout
          if(reportPermission) {
            return Scaffold(
              resizeToAvoidBottomInset: false,
              appBar: MediaQuery.of(context).orientation == Orientation.landscape ? AppBar(
                automaticallyImplyLeading: false,
                title: Row(
                  children: [
                    Text(AppLocalizations.of(context)!.translate('report'), style: TextStyle(fontSize: 20, color: color.backgroundColor)),
                    Spacer(),
                    Visibility(
                      visible: currentPage != 14 && currentPage != 15 ? true : false,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          Checkbox(
                            value: _isChecked,
                            onChanged: (bool? value) {
                              setState(() {
                                _isChecked = !_isChecked;
                                prefs.setBool('reportBasedOnOB', _isChecked);
                                reportModel.refresh();
                              });
                            },
                          ),
                          GestureDetector(
                            onTap: () {
                              Fluttertoast.showToast(msg: AppLocalizations.of(context)!.translate('report_calculate_based_on_opening_balance'));
                            },
                            child: Row(
                              children: <Widget>[
                                Text(AppLocalizations.of(context)!.translate('advanced')),
                                SizedBox(width: 4),
                                Icon(Icons.info, color: color.backgroundColor, size: 22,),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: 10),
                    Visibility(
                      visible: currentPage != 2 && currentPage != 16 ? true : false,
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
                      visible: currentPage != 1 && currentPage != 2 && currentPage != 6 && currentPage != 12 && currentPage != 13
                          && currentPage != 15 && currentPage != 16  ? true : false,
                      child: Container(
                        child: IconButton(
                          icon: Icon(Icons.receipt),
                          color: color.backgroundColor,
                          onPressed: receiptOnPressed,
                        ),
                      ),
                    ),
                    Container(
                      width: 230,
                      height: 55,
                      child: TextField(
                        controller: _controller,
                        decoration: InputDecoration(
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.all(Radius.circular(4)),
                              borderSide: BorderSide(width: 1,color: color.backgroundColor),
                            ),
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.all(Radius.circular(5.0)))
                        ),
                        style: TextStyle(color: Colors.black),
                        readOnly: true,
                        onTap: (){
                          showDialog(context: context, builder: (BuildContext context) {
                            return WillPopScope(
                              onWillPop: () async {
                                dateTimeNow = dateFormat.format(DateTime.now());
                                _controller = TextEditingController(text: '${dateTimeNow} - ${dateTimeNow}');
                                _dateRangePickerController.selectedRange = PickerDateRange(DateTime.now(), DateTime.now());
                                setState(() {
                                  reportModel.setDateTime(currentStDate, currentEdDate);
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
                                      TextEditingController(text: '${_range}') :
                                      TextEditingController(text: '${dateTimeNow} - ${dateTimeNow}');
                                      setState(() {
                                        reportModel.setDateTime(currentStDate, currentEdDate);
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
                      ),
                    ),
                  ],
                ),
                backgroundColor: Color(0xffFAFAFA),
                elevation: 0,
              ) :
              AppBar(
                automaticallyImplyLeading: false,
                leading: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: GestureDetector(
                    onTap: () {
                      isCollapsedNotifier.value = !isCollapsedNotifier.value;
                    },
                    child: Image.asset('drawable/logo.png'),
                  ),
                ),
                title: Row(
                  children: [
                    Text(AppLocalizations.of(context)!.translate('report'), style: TextStyle(fontSize: 20, color: color.backgroundColor)),
                    Spacer(),
                    Visibility(
                      visible: false,
                      // visible: currentPage != 13 ? true : false,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          Checkbox(
                            value: _isChecked,
                            onChanged: (bool? value) {
                              setState(() {
                                _isChecked = !_isChecked;
                                prefs.setBool('reportBasedOnOB', _isChecked);
                                reportModel.refresh();
                              });
                            },
                          ),
                          GestureDetector(
                            onTap: () {
                              Fluttertoast.showToast(msg: AppLocalizations.of(context)!.translate('report_calculate_based_on_opening_balance'));
                            },
                            child: Row(
                              children: <Widget>[
                                Text(AppLocalizations.of(context)!.translate('advanced')),
                                SizedBox(width: 4),
                                Icon(Icons.info, color: color.backgroundColor, size: 22,),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: 10),
                    Visibility(
                      // visible: currentPage != 13 ? true : false,
                      visible: false,
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
                      // visible: currentPage != 1 && currentPage != 5 && currentPage != 10 && currentPage != 11 && currentPage != 13  ? true : false,
                      visible: false,
                      child: Container(
                        child: IconButton(
                          icon: Icon(Icons.receipt),
                          color: color.backgroundColor,
                          onPressed: receiptOnPressed,
                        ),
                      ),
                    ),
                  ],
                ),
                backgroundColor: Color(0xffFAFAFA),
                elevation: 0,
                actions: [
                  Visibility(
                    visible: MediaQuery.of(context).size.width > 500 ? false : true,
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
                                    reportModel.setDateTime(currentStDate, currentEdDate);
                                  });
                                  return true;
                                },
                                child: AlertDialog(
                                  title: Text(AppLocalizations.of(context)!.translate('select_a_date_range')),
                                  titlePadding: EdgeInsets.fromLTRB(24, 12, 24, 0),
                                  contentPadding: EdgeInsets.all(16),
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
                                              reportModel.setDateTime(currentStDate, currentEdDate);
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
                        )
                    ),
                  ),
                  Visibility(
                    visible: MediaQuery.of(context).size.width > 500 ? true : false,
                    child: Container(
                      width: 230,
                      height: 55,
                      child: TextField(
                        controller: _controller,
                        decoration: InputDecoration(
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.all(Radius.circular(4)),
                              borderSide: BorderSide(width: 1,color: color.backgroundColor),
                            ),
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.all(Radius.circular(5.0)))
                        ),
                        style: TextStyle(color: Colors.black),
                        readOnly: true,
                        onTap: (){
                          showDialog(context: context, builder: (BuildContext context) {
                            return WillPopScope(
                              onWillPop: () async {
                                dateTimeNow = dateFormat.format(DateTime.now());
                                _controller = TextEditingController(text: '${dateTimeNow} - ${dateTimeNow}');
                                _dateRangePickerController.selectedRange = PickerDateRange(DateTime.now(), DateTime.now());
                                setState(() {
                                  reportModel.setDateTime(currentStDate, currentEdDate);
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
                                      TextEditingController(text: '${_range}') :
                                      TextEditingController(text: '${dateTimeNow} - ${dateTimeNow}');
                                      setState(() {
                                        reportModel.setDateTime(currentStDate, currentEdDate);
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
                      ),
                    ),
                  ),
                  Visibility(
                    visible: currentPage != 14,
                    child: PopupMenuButton<String>(
                      onSelected: handleClick,
                      itemBuilder: (BuildContext context) {
                        final List<String> choices = [];
                        if (currentPage != 13) {
                          choices.add('advanced');
                        }
                        choices.add('pdf');
                        if (currentPage != 1 && currentPage != 5 && currentPage != 10 && currentPage != 11 && currentPage != 13) {
                          choices.add('print');
                        }
                        return choices.map((String choice) {
                          return PopupMenuItem<String>(
                            value: choice,
                            child: Text('${AppLocalizations.of(context)!.translate(choice)}${choice == 'advanced' ? _isChecked ? ' ON' : ' OFF' : ''}'),
                          );
                        }).toList();
                      },
                      icon: Icon(Icons.more_vert, color: color.backgroundColor,),
                    ),
                  ),
                ],
              ),
              body: Padding(
                padding: EdgeInsets.fromLTRB(8, 10, 8, 8),
                child: Column(
                  children: [
                    Container(
                      padding: EdgeInsets.only(left: 8),
                      alignment: Alignment.centerLeft,
                      child: DropdownButton<int>(
                        value: selectedIndex,
                        menuMaxHeight: 500,
                        items: [
                          DropdownMenuItem(
                            value: 0,
                            child: Text(AppLocalizations.of(context)!.translate('overview')),
                          ),
                          DropdownMenuItem(
                            value: 1,
                            child: Text(AppLocalizations.of(context)!.translate('sales_summary')),
                          ),
                          DropdownMenuItem(
                            value: 2,
                            child: Text(AppLocalizations.of(context)!.translate('product_report')),
                          ),
                          DropdownMenuItem(
                            value: 3,
                            child: Text(AppLocalizations.of(context)!.translate('category_report')),
                          ),
                          DropdownMenuItem(
                            value: 4,
                            child: Text(AppLocalizations.of(context)!.translate('modifier_report')),
                          ),
                          DropdownMenuItem(
                            value: 5,
                            child: Text(AppLocalizations.of(context)!.translate('edit_report')),
                          ),
                          DropdownMenuItem(
                            value: 6,
                            child: Text(AppLocalizations.of(context)!.translate('cancel_report')),
                          ),
                          DropdownMenuItem(
                            value: 7,
                            child: Text(AppLocalizations.of(context)!.translate('cancel_record_report')),
                          ),
                          DropdownMenuItem(
                            value: 8,
                            child: Text(AppLocalizations.of(context)!.translate('cancel_modifier_report')),
                          ),
                          DropdownMenuItem(
                            value: 9,
                            child: Text(AppLocalizations.of(context)!.translate('dining_report')),
                          ),
                          DropdownMenuItem(
                            value: 10,
                            child: Text(AppLocalizations.of(context)!.translate('payment_report')),
                          ),
                          DropdownMenuItem(
                            value: 11,
                            child: Text(AppLocalizations.of(context)!.translate('refund_report')),
                          ),
                          DropdownMenuItem(
                            value: 12,
                            child: Text(AppLocalizations.of(context)!.translate('cashflow_report')),
                          ),
                          DropdownMenuItem(
                            value: 13,
                            child: Text(AppLocalizations.of(context)!.translate('staff_sales_report')),
                          ),
                          DropdownMenuItem(
                            value: 14,
                            child: Text(AppLocalizations.of(context)!.translate('attendance_report')),
                          ),
                          DropdownMenuItem(
                            value: 15,
                            child: Text(AppLocalizations.of(context)!.translate('transfer_report')),
                          ),
                        ],
                        onChanged: (int? newIndex) {
                          setState(() {
                            selectedIndex = newIndex!;
                            currentPage = newIndex;
                          });
                        },
                      ),
                    ),
                    Expanded(
                      child: views.elementAt(selectedIndex),
                    ),
                  ],
                ),
              ),
            );
          } else {
            return StatefulBuilder(builder: (context, StateSetter setState) {
              return Center(
                child: SingleChildScrollView(
                  child: AlertDialog(
                    title: Text(AppLocalizations.of(context)!.translate('enter_admin_pin')),
                    content: SizedBox(
                      height: 75.0,
                      width: 350.0,
                      child: ValueListenableBuilder(
                          valueListenable: adminPosPinController,
                          builder: (context, TextEditingValue value, __) {
                            return Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: TextField(
                                autofocus: true,
                                onSubmitted: (input) {
                                  setState(() {
                                    isButtonDisabled = true;
                                  });
                                  _submit(context);
                                  if(mounted){
                                    setState(() {
                                      isButtonDisabled = false;
                                    });
                                  }
                                },
                                obscureText: _obscureText,
                                controller: adminPosPinController,
                                keyboardType: TextInputType.numberWithOptions(decimal: true),
                                decoration: InputDecoration(
                                  suffixIcon: IconButton(
                                    icon: Icon(_obscureText ? Icons.visibility_off : Icons.visibility),
                                    onPressed: () {
                                      setState(() {
                                        _obscureText = !_obscureText;
                                      });
                                    },
                                  ),
                                  errorText: _submitted
                                      ? errorPassword == null
                                      ? errorPassword
                                      : AppLocalizations.of(context)?.translate(errorPassword!)
                                      : null,
                                  border: OutlineInputBorder(
                                    borderSide: BorderSide(color: color.backgroundColor),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderSide: BorderSide(color: color.backgroundColor),
                                  ),
                                  labelText: "PIN",
                                ),
                              ),
                            );
                          }),
                    ),
                    actions: <Widget>[
                      SizedBox(
                        width:  MediaQuery.of(context).size.width / 4,
                        height: MediaQuery.of(context).size.height / 10,
                        child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: color.backgroundColor,
                            ),
                            child: Text(
                              AppLocalizations.of(context)!.translate('clear'),
                              style: TextStyle(color: Colors.white),
                            ),
                            onPressed: (){
                              adminPosPinController.clear();
                            }
                        ),
                      ),
                      SizedBox(
                        width: MediaQuery.of(context).size.width / 4,
                        height: MediaQuery.of(context).size.height / 10,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: color.buttonColor,
                          ),
                          child: Text(
                            AppLocalizations.of(context)!.translate('yes'),
                            style: TextStyle(color: Colors.white),
                          ),
                          onPressed: isButtonDisabled
                              ? null
                              : () async {
                            setState(() {
                              isButtonDisabled = true;
                            });
                            _submit(context);
                            if(mounted){
                              setState(() {
                                isButtonDisabled = false;
                              });
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              );
            });
          }
        }
      });
    });
  }

  Future<void> handleClick(String value) async {
    switch (value) {
      case 'advanced':
        setState(() {
          _isChecked = !_isChecked;
          prefs.setBool('reportBasedOnOB', _isChecked);
        });
        break;
      case 'pdf':
        Navigator.push(
          context,
          PageTransition(
            type: PageTransitionType.bottomToTop,
            child: PrintReportPage(currentPage: this.currentPage,),
          ),
        );
        break;
      case 'print':
        receiptOnPressed();
        break;
    }
  }

  receiptOnPressed() async {
    switch(currentPage){
      case 0: {
        await receipt.printReceipt(layout: OverviewReceiptLayout());
      }break;
      case 3: {
        await receipt.printReceipt(layout: ProductReceiptLayout());
      }break;
      case 4: {
        await receipt.printReceipt(layout: CategoryReceiptLayout());
      }break;
      case 5: {
        await receipt.printReceipt(layout: ModifierReceiptLayout());
      }break;
      case 7: {
        await receipt.printReceipt(layout: CancellationReceiptLayout());
      }break;
      case 8: {
        await receipt.printReceipt(layout: CancelRecordLayout());
      }break;
      case 9: {
        await receipt.printReceipt(layout: CancelledModReceiptLayout());
      }break;
      case 10: {
        await receipt.printReceipt(layout: DiningReceiptLayout());
      }break;
      case 11: {
        await receipt.printReceipt(layout: PaymentReceiptLayout());
      }break;
      case 14: {
        await receipt.printReceipt(layout: StaffReceiptLayout());
      }break;
    }
  }

  getPrefData() async {
    try {
      prefs = await SharedPreferences.getInstance();
      if(prefs.getBool('reportBasedOnOB') != null) {
        _isChecked = prefs.getBool('reportBasedOnOB')!;
      } else {
        _isChecked = false;
        prefs.setBool('reportBasedOnOB', _isChecked);
      }
    } catch (e) {
      _isChecked = false;
    }
  }

  preload(){
    views.addAll([
      Container(
        child: ReportOverview(),//0
      ),
      Container(
        child: SalesSummaryReport(),//1
      ),
      Container(
        child: DailySalesReport(),//2
      ),
      Container(
        child: ProductReport(),//3
      ),
      Container(
        child: CategoryReport(),//4
      ),
      Container(
        child: ModifierReport(),//5
      ),
      Container(
        child: ProductEditedReport(),//6
      ),
      Container(
        child: CancellationReport(),//7
      ),
      Container(
        child: CancelRecordReport(),//8
      ),
      Container(
        child: CancelModifierReport(),//9
      ),
      Container(
        child: DiningReport(),//10
      ),
      Container(
        child: PaymentReport(),//11
      ),
      Container(
        child: RefundReport(),//12
      ),
      Container(
        child: CashRecordReport(),//13
      ),
      Container(
        child: StaffSalesReport(),//14
      ),
      Container(
        child: AttendanceReport(),//15
      ),
      Container(
        child: TransferRecord(),//16
      ),
    ]);
  }

  checkAccess() async {
    final prefs = await SharedPreferences.getInstance();
    final String? pos_user = prefs.getString('pos_pin_user');
    Map<String, dynamic> userMap = json.decode(pos_user!);
    User userData = User.fromJson(userMap);

    if(userData.report_permission == 1) {
      reportPermission = true;
    } else {
      reportPermission = false;
    }
    setState(() {

    });
  }
}
