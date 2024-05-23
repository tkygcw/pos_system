import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';
import 'package:page_transition/page_transition.dart';
import 'package:pos_system/database/pos_database.dart';
import 'package:pos_system/fragment/report/cancel_modifier_report.dart';
import 'package:pos_system/fragment/report/cancellation_report.dart';
import 'package:pos_system/fragment/report/cash_record_report.dart';
import 'package:pos_system/fragment/report/category_report.dart';
import 'package:pos_system/fragment/report/daily_sales_report.dart';
import 'package:pos_system/fragment/report/dining_report.dart';
import 'package:pos_system/fragment/report/modifier_report.dart';
import 'package:pos_system/fragment/report/payment_report.dart';
import 'package:pos_system/fragment/report/print_report_page.dart';
import 'package:pos_system/fragment/report/product_edited_report.dart';
import 'package:pos_system/fragment/report/product_report.dart';
import 'package:pos_system/fragment/report/refund_report.dart';
import 'package:pos_system/fragment/report/report_overview.dart';
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
  final adminPosPinController = TextEditingController();
  bool isButtonDisabled = false;
  bool _submitted = false;
  bool isLogOut = false;
  late bool reportPermission = true;
  late bool dialogPrompt = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.report.initDateTime();
      //widget.report.resetLoad();
    });
    dateTimeNow = dateFormat.format(DateTime.now());
    _controller = new TextEditingController(text: '${dateTimeNow} - ${dateTimeNow}');
    _dateRangePickerController.selectedRange = PickerDateRange(DateTime.now(), DateTime.now());
    currentPage = 0;
    preload();
  }

  readAdminData(String pin) async {
    List<String> _posTableValue = [];
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? pos_user = prefs.getString('pos_pin_user');
      Map userObject = json.decode(pos_user!);
      DateFormat dateFormat = DateFormat("yyyy-MM-dd HH:mm:ss");
      String dateTime = dateFormat.format(DateTime.now());

      //List<User> userData = await PosDatabase.instance.readSpecificUserWithRole(pin);
      User? userData = await PosDatabase.instance.readSpecificUserWithPin(pin);
      print("adjustPrice userData: ${userData}");
      if (userData != null) {
        if(userData.report_permission == 1) {
          setState(() {
            // Navigator.of(context).pop(true);
            reportPermission = true;
            widget.report.resetLoad();
          });
        } else {
          reportPermission = false;
          Fluttertoast.showToast(backgroundColor: Color(0xFFFF0000), msg: "${AppLocalizations.of(context)?.translate('no_permission')}");
        }

      } else {
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
      return;
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
    return Consumer<ThemeColor>(builder: (context, ThemeColor color, child) {
      return Consumer<ReportModel>(builder: (context, ReportModel reportModel, child){
          return LayoutBuilder(builder: (context, constraints) {
            if(constraints.maxWidth > 800){
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
                              icon: Icons.fastfood,
                              label: AppLocalizations.of(context)!.translate('edit_report'),
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
                                    obscureText: true,
                                    controller: adminPosPinController,
                                    keyboardType: TextInputType.number,
                                    decoration: InputDecoration(
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
                            width: MediaQuery.of(context).size.width > 900 && MediaQuery.of(context).size.height > 500 ? MediaQuery.of(context).size.width / 6 : MediaQuery.of(context).size.width / 4,
                            height: MediaQuery.of(context).size.width > 900 && MediaQuery.of(context).size.height > 500 ? MediaQuery.of(context).size.height / 12 : MediaQuery.of(context).size.height / 10,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: color.backgroundColor,
                              ),
                              child: Text(
                                AppLocalizations.of(context)!.translate('clear'),
                                style: TextStyle(color: Colors.white),
                              ),
                              onPressed: isButtonDisabled
                                  ? null
                                  : () {
                                setState(() {
                                  isButtonDisabled = true;
                                });
                                adminPosPinController.clear();
                                if(mounted){
                                  setState(() {
                                    isButtonDisabled = false;
                                  });
                                }
                              },
                            ),
                          ),
                          SizedBox(
                            width: MediaQuery.of(context).size.width > 900 && MediaQuery.of(context).size.height > 500 ? MediaQuery.of(context).size.width / 6 : MediaQuery.of(context).size.width / 4,
                            height: MediaQuery.of(context).size.width > 900 && MediaQuery.of(context).size.height > 500 ? MediaQuery.of(context).size.height / 12 : MediaQuery.of(context).size.height / 10,
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
                              icon: Icons.fastfood,
                              label: AppLocalizations.of(context)!.translate('edit_report'),
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
                                    obscureText: true,
                                    controller: adminPosPinController,
                                    keyboardType: TextInputType.number,
                                    decoration: InputDecoration(
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
                            width: MediaQuery.of(context).size.width > 900 && MediaQuery.of(context).size.height > 500 ? MediaQuery.of(context).size.width / 6 : MediaQuery.of(context).size.width / 4,
                            height: MediaQuery.of(context).size.width > 900 && MediaQuery.of(context).size.height > 500 ? MediaQuery.of(context).size.height / 12 : MediaQuery.of(context).size.height / 10,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: color.backgroundColor,
                              ),
                              child: Text(
                                AppLocalizations.of(context)!.translate('close'),
                                style: TextStyle(color: Colors.white),
                              ),
                              onPressed: isButtonDisabled
                                  ? null
                                  : () {
                                setState(() {
                                  isButtonDisabled = true;
                                });
                                Navigator.of(context).pop();
                                if(mounted){
                                  setState(() {
                                    isButtonDisabled = false;
                                  });
                                }
                              },
                            ),
                          ),
                          SizedBox(
                            width: MediaQuery.of(context).size.width > 900 && MediaQuery.of(context).size.height > 500 ? MediaQuery.of(context).size.width / 6 : MediaQuery.of(context).size.width / 4,
                            height: MediaQuery.of(context).size.width > 900 && MediaQuery.of(context).size.height > 500 ? MediaQuery.of(context).size.height / 12 : MediaQuery.of(context).size.height / 10,
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
        }
      );
    });
  }
  preload(){
    checkAccess();
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
        child: ProductEditedReport(),
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
  }
}
