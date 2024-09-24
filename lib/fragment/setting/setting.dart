import 'dart:convert';

import 'package:collapsible_sidebar/collapsible_sidebar.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:pos_system/fragment/setting/device_setting.dart';
import 'package:pos_system/fragment/Attendance/attendance_dialog.dart';
import 'package:pos_system/fragment/setting/features_setting.dart';
import 'package:pos_system/fragment/setting/hardware_setting.dart';
import 'package:pos_system/fragment/setting/logout_dialog.dart';
import 'package:pos_system/fragment/setting/order_setting.dart';
import 'package:pos_system/fragment/setting/printer_setting.dart';
import 'package:pos_system/fragment/setting/receipt_setting.dart';
import 'package:pos_system/fragment/setting/table_setting/table_setting.dart';
import 'package:pos_system/page/login.dart';
import 'package:pos_system/page/progress_bar.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:side_navigation/side_navigation.dart';
import '../../database/domain.dart';
import '../../database/pos_database.dart';
import '../../main.dart';
import '../../notifier/theme_color.dart';
import '../../object/cash_record.dart';
import '../../page/pos_pin.dart';
import '../../translation/AppLocalizations.dart';
import 'data_process_setting.dart';

class SettingMenu extends StatefulWidget {
  const SettingMenu({Key? key}) : super(key: key);

  @override
  _SettingMenuState createState() => _SettingMenuState();
}

class _SettingMenuState extends State<SettingMenu> {
  List<CashRecord> cashRecordList = [];
  String userEmail = '';
  int count = 0;
  bool isLoaded = false;
  String serverIp = '';

  List<Widget> views = [
    // General Setting
    Container(
      child: HardwareSetting(),
    ),
    Container(
      child: OrderSetting(),
    ),
    Container(
      child: PrinterSetting(),
      // TestPrint()
    ),
    Container(
      child: ReceiptSetting(),
    ),
    Container(
      child: TableSetting(),
    ),
    // app-device setting
    Container(
      child: FeaturesSetting(),
    ),
    Container(
      child: DataProcessingSetting(),
    ),
    Container(
      child: DeviceSetting(),
    ),
    // Container(
    //   child: TestCategorySync(),
    // ),
    // Container(
    //   child: DisplayManagerScreen(),
    // ),
    // Container(
    //   child: TestPrint(),
    // ),
    // Container(
    //   child: TestQrcode(),
    // )
  ];
  int selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    getLoginUserInfo();
    checkCashRecord();
  }

  toPosPinPage(){
    //String cashDrawer = calcCashDrawer();
    print('to pos pin call him');
    // Navigator.push(context,
    //   PageTransition(type: PageTransitionType.fade, child: PosPinPage(cashBalance: cashDrawer),
    //   ),
    // );
    Navigator.of(context).pushAndRemoveUntil(
      // the new route
      MaterialPageRoute(
        builder: (BuildContext context) => PosPinPage(),
      ),

      // this function should return true when we're done removing routes
      // but because we want to remove all other screens, we make it
      // always return false
          (Route route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeColor>(builder: (context, ThemeColor color, child) {
      return LayoutBuilder(builder: (context,  constraints) {
        if(MediaQuery.of(context).size.width > 800){
          return Padding(
            padding: EdgeInsets.fromLTRB(0,0,0,0),
            child: this.isLoaded ?
            Scaffold(
              resizeToAvoidBottomInset: false,
              appBar: AppBar(
                automaticallyImplyLeading: false,
                leading: MediaQuery.of(context).orientation == Orientation.landscape ? null : Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: GestureDetector(
                    onTap: () {
                      isCollapsedNotifier.value = !isCollapsedNotifier.value;
                    },
                    child: Image.asset('drawable/logo.png'),
                  ),
                ),
                title: Text(AppLocalizations.of(context)!.translate('setting'),
                    style: MediaQuery.of(context).size.width > 900 && MediaQuery.of(context).size.height > 500
                        ? TextStyle(fontSize: 25, color: Colors.black)
                        : TextStyle(fontSize: 20, color: color.backgroundColor)),
                centerTitle: false,
                backgroundColor: Color(0xffFAFAFA),
                elevation: 0,
              ),
              body: Row(
                children: [
                  /// Pretty similar to the BottomNavigationBar!
                  SideNavigationBar(
                    expandable: false,
                    footer: SideNavigationBarFooter(
                        label: Column(
                          children: [
                            Text("${userEmail}"),
                            ElevatedButton(onPressed: () async {
                              openAttendanceDialog();
                            },
                              child: Text('${AppLocalizations.of(context)?.translate('clock_in_out')}')
                            ),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: color.backgroundColor,
                              ),
                              onPressed: () async {
                                bool _hasInternetAccess = await Domain().isHostReachable();
                                if(this.cashRecordList.isEmpty){
                                  if(_hasInternetAccess){
                                    //notificationModel.setTimer(true);
                                    toPosPinPage();
                                  } else {
                                    Fluttertoast.showToast(
                                        backgroundColor: Colors.red,
                                        msg: "${AppLocalizations.of(context)?.translate('check_internet_connection')}");
                                  }
                                } else {
                                  Fluttertoast.showToast(
                                      backgroundColor: Colors.red,
                                      msg: "${AppLocalizations.of(context)?.translate('log_out_settlement')}");
                                }

                              },
                              child: Text(AppLocalizations.of(context)!.translate('close_counter')),
                            ),
                          ],
                        )),
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
                        icon: Icons.devices,
                        label: AppLocalizations.of(context)!.translate('general_setting'),
                      ),
                      SideNavigationBarItem(
                        icon: Icons.shopping_cart,
                        label: AppLocalizations.of(context)!.translate('order_setting'),
                      ),
                      SideNavigationBarItem(
                        icon: Icons.print,
                        label: AppLocalizations.of(context)!.translate('printer_setting'),
                      ),
                      SideNavigationBarItem(
                        icon: Icons.receipt,
                        label: AppLocalizations.of(context)!.translate('receipt_setting'),
                      ),
                      SideNavigationBarItem(
                        icon: Icons.table_restaurant,
                        label: AppLocalizations.of(context)!.translate('table_setting'),
                      ),
                      SideNavigationBarItem(
                        icon: Icons.settings,
                        label: AppLocalizations.of(context)!.translate('app_device_setting'),
                      ),
                      SideNavigationBarItem(
                        icon: Icons.sync,
                        label: AppLocalizations.of(context)!.translate('data_processing'),
                      ),
                      SideNavigationBarItem(
                        icon: Icons.devices_other,
                        label: AppLocalizations.of(context)!.translate("device_setting"),
                      ),
                    ],
                    onTap: (index) {
                      setState(() {
                        selectedIndex = index;
                      });
                    },
                  ),

                  /// Make it take the rest of the available width
                  Expanded(
                    child: views.elementAt(selectedIndex),
                  )
                ],
              ),
            ) : CustomProgressBar(),
          );
        } else {
          ///mobile layout
          return MediaQuery.of(context).orientation == Orientation.landscape ? Padding(
            padding: EdgeInsets.fromLTRB(0, 0, 8, 15),
            child: this.isLoaded ?
            Scaffold(
              resizeToAvoidBottomInset: false,
              appBar: AppBar(
                automaticallyImplyLeading: false,
                title: Text(AppLocalizations.of(context)!.translate('setting'),
                    style: TextStyle(fontSize: 20, color: color.backgroundColor)),
                centerTitle: false,
                backgroundColor: Color(0xffFAFAFA),
                elevation: 0,
              ),
              body: Row(
                children: [
                  /// Pretty similar to the BottomNavigationBar!
                  Expanded(
                    flex: 1,
                    child: SideNavigationBar(
                      expandable: false,
                      footer: SideNavigationBarFooter(
                          label: Column(
                            children: [
                              Text("${userEmail}"),
                              ElevatedButton(onPressed: () async {
                                openAttendanceDialog();
                              },
                                  child: Text('${AppLocalizations.of(context)?.translate('clock_in_out')}')
                              ),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: color.backgroundColor,
                                ),
                                onPressed: () async {
                                  bool _hasInternetAccess = await Domain().isHostReachable();
                                  if(this.cashRecordList.isEmpty){
                                    if(_hasInternetAccess){
                                      notificationModel.setTimer(true);
                                      toPosPinPage();
                                    } else {
                                      Fluttertoast.showToast(
                                          backgroundColor: Colors.red,
                                          msg: "${AppLocalizations.of(context)?.translate('check_internet_connection')}");
                                    }
                                  } else {
                                    Fluttertoast.showToast(
                                        backgroundColor: Colors.red,
                                        msg: "${AppLocalizations.of(context)?.translate('log_out_settlement')}");
                                  }

                                },
                                child: Text(AppLocalizations.of(context)!.translate('close_counter')),
                              ),
                            ],
                          )),
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
                          icon: Icons.devices,
                          label: AppLocalizations.of(context)!.translate('general_setting'),
                        ),
                        SideNavigationBarItem(
                          icon: Icons.shopping_cart,
                          label: AppLocalizations.of(context)!.translate('order_setting'),
                        ),
                        SideNavigationBarItem(
                          icon: Icons.print,
                          label: AppLocalizations.of(context)!.translate('printer_setting'),
                        ),
                        SideNavigationBarItem(
                          icon: Icons.receipt,
                          label: AppLocalizations.of(context)!.translate('receipt_setting'),
                        ),
                        SideNavigationBarItem(
                          icon: Icons.table_restaurant,
                          label: AppLocalizations.of(context)!.translate('table_setting'),
                        ),
                        SideNavigationBarItem(
                          icon: Icons.settings,
                          label: AppLocalizations.of(context)!.translate('app_device_setting'),
                        ),
                        SideNavigationBarItem(
                          icon: Icons.sync,
                          label: AppLocalizations.of(context)!.translate('data_processing'),
                        ),
                        SideNavigationBarItem(
                          icon: Icons.devices_other,
                          label: AppLocalizations.of(context)!.translate("device_setting"),
                        ),
                      ],
                      onTap: (index) {
                        setState(() {
                          selectedIndex = index;
                        });
                      },
                    ),
                  ),

                  /// Make it take the rest of the available width
                  Expanded(
                    flex: 2,
                      child: views.elementAt(selectedIndex),
                  )
                ],
              )
            )
            : CustomProgressBar(),
          ) : Padding(
            padding: EdgeInsets.all(0),
              child: this.isLoaded ?
              Scaffold(
                resizeToAvoidBottomInset: false,
                appBar: AppBar(
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
                  title: Text(AppLocalizations.of(context)!.translate('setting'),
                      style: TextStyle(fontSize: 20, color: color.backgroundColor)),
                  centerTitle: false,
                  backgroundColor: Color(0xffFAFAFA),
                  elevation: 1,
                ),
                body: ListView(
                  padding: EdgeInsets.zero,
                  children: <Widget>[
                    ListTile(
                      leading: Icon(Icons.devices),
                      title: Text(AppLocalizations.of(context)!.translate('general_setting')),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => views.elementAt(0),
                          ),
                        );
                      },
                    ),
                    ListTile(
                      leading: Icon(Icons.shopping_cart),
                      title: Text(AppLocalizations.of(context)!.translate('order_setting')),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => views.elementAt(1),
                          ),
                        );
                      },
                    ),
                    ListTile(
                      leading: Icon(Icons.print),
                      title: Text(AppLocalizations.of(context)!.translate('printer_setting')),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => views.elementAt(2),
                          ),
                        );
                      },
                    ),
                    ListTile(
                      leading: Icon(Icons.receipt),
                      title: Text(AppLocalizations.of(context)!.translate('receipt_setting')),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => views.elementAt(3),
                          ),
                        );
                      },
                    ),
                    ListTile(
                      leading: Icon(Icons.table_restaurant),
                      title: Text(AppLocalizations.of(context)!.translate('table_setting')),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => views.elementAt(4),
                          ),
                        );
                      },
                    ),
                    ListTile(
                      leading: Icon(Icons.settings),
                      title: Text(AppLocalizations.of(context)!.translate('app_device_setting')),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => views.elementAt(5),
                          ),
                        );
                      },
                    ),
                    ListTile(
                      leading: Icon(Icons.sync),
                      title: Text(AppLocalizations.of(context)!.translate('data_processing')),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => views.elementAt(6),
                          ),
                        );
                      },
                    ),
                    ListTile(
                      leading: Icon(Icons.devices_other),
                      title: Text(AppLocalizations.of(context)!.translate("device_setting")),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => views.elementAt(7),
                          ),
                        );
                      },
                    ),
                  ],
                ),
                bottomNavigationBar: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(userEmail),
                    ElevatedButton(
                      onPressed: () async {
                        openAttendanceDialog();
                      },
                      child: Text('${AppLocalizations.of(context)?.translate('clock_in_out')}'),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: color.backgroundColor,
                      ),
                      onPressed: () async {
                        bool _hasInternetAccess = await Domain().isHostReachable();
                        if (cashRecordList.isEmpty) {
                          if (_hasInternetAccess) {
                            notificationModel.setTimer(true);
                            toPosPinPage();
                          } else {
                            Fluttertoast.showToast(
                              backgroundColor: Colors.red,
                              msg: "${AppLocalizations.of(context)?.translate('check_internet_connection')}",
                            );
                          }
                        } else {
                          Fluttertoast.showToast(
                            backgroundColor: Colors.red,
                            msg: "${AppLocalizations.of(context)?.translate('log_out_settlement')}",
                          );
                        }
                      },
                      child: Text(AppLocalizations.of(context)!.translate('close_counter')),
                    ),
                  ],
                ),
              )
              : CustomProgressBar(),
          );
        }
      });
    });
  }
  
  logout() async{
    final prefs = await SharedPreferences.getInstance();
    prefs.clear();
    Navigator.of(context).pushReplacement(MaterialPageRoute(
        builder: (context) => LoginPage()));

  }

  Future<Future<Object?>> openLogoutDialog() async {
    return showGeneralDialog(
        barrierColor: Colors.black.withOpacity(0.5),
        transitionBuilder: (context, a1, a2, widget) {
          final curvedValue = Curves.easeInOutBack.transform(a1.value) - 1.0;
          return Transform(
            transform: Matrix4.translationValues(0.0, curvedValue * 200, 0.0),
            child: Opacity(
                opacity: a1.value,
                child: logout_dialog()),
          );
        },
        transitionDuration: Duration(milliseconds: 200),
        barrierDismissible: false,
        context: context,
        pageBuilder: (context, animation1, animation2) {
          // ignore: null_check_always_fails
          return null!;
        });
  }

  Future<Future<Object?>> openAttendanceDialog() async {
    return showGeneralDialog(
        barrierColor: Colors.black.withOpacity(0.5),
        transitionBuilder: (context, a1, a2, widget) {
          final curvedValue = Curves.easeInOutBack.transform(a1.value) - 1.0;
          return Transform(
            transform: Matrix4.translationValues(0.0, curvedValue * 200, 0.0),
            child: Opacity(
              opacity: a1.value,
              child: AttendanceDialog(),
            ),
          );
        },
        transitionDuration: Duration(milliseconds: 200),
        barrierDismissible: false,
        context: context,
        pageBuilder: (context, animation1, animation2) {
          // ignore: null_check_always_fails
          return null!;
        });
  }

  getLoginUserInfo() async {
    final prefs = await SharedPreferences.getInstance();
    final String? login_user = prefs.getString('user');
    Map logInUser = json.decode(login_user!);
    this.userEmail = logInUser['email'];
    this.isLoaded = false;

  }

  checkCashRecord() async {
    List<CashRecord> data = await PosDatabase.instance.readBranchCashRecord();
    cashRecordList = List.from(data);
    if(mounted){
      setState(() {
        this.isLoaded = true;
      });
    }
  }

}
