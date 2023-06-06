import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:pos_system/fragment/printer/test_print.dart';
import 'package:pos_system/fragment/qr_order/test_qrcode.dart';
import 'package:pos_system/fragment/report/print_report_page.dart';
// import 'package:pos_system/fragment/printer/test_scanner.dart';
import 'package:pos_system/fragment/setting/features_setting.dart';
import 'package:pos_system/fragment/setting/logout_dialog.dart';
import 'package:pos_system/fragment/setting/printer_setting.dart';
import 'package:pos_system/fragment/setting/receipt_setting.dart';
import 'package:pos_system/fragment/setting/table_setting.dart';
import 'package:pos_system/fragment/test_sync/test_category_sync.dart';
import 'package:pos_system/object/user.dart';
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
import '../multi_device/multi_device.dart';
import '../test_dual_screen/test_display.dart';

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

  List<Widget> views = [
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
    Container(
      child: FeaturesSetting(),
    ),
    Container(
      child: MultiDevicePage(),
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
        if(constraints.maxWidth > 800){
          return Padding(
            padding: EdgeInsets.fromLTRB(8, 10, 8, 8),
            child: this.isLoaded ?
            Scaffold(
              resizeToAvoidBottomInset: false,
              appBar: AppBar(
                automaticallyImplyLeading: false,
                title: Text('Setting',
                    style: TextStyle(fontSize: 25, color: Colors.black)),
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
                              child: Text('Close Counter'),
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
                    items: const [
                      SideNavigationBarItem(
                        icon: Icons.print,
                        label: 'Printer',
                      ),
                      SideNavigationBarItem(
                        icon: Icons.receipt,
                        label: 'Receipt Layout',
                      ),
                      SideNavigationBarItem(
                        icon: Icons.settings,
                        label: 'Table Setting',
                      ),
                      SideNavigationBarItem(
                        icon: Icons.settings,
                        label: 'App-Device setting',
                      ),
                      // SideNavigationBarItem(
                      //   icon: Icons.settings,
                      //   label: 'Multi device testing',
                      // ),
                      // SideNavigationBarItem(
                      //   icon: Icons.list,
                      //   label: 'Test sync (temp)',
                      // ),
                      // SideNavigationBarItem(
                      //   icon: Icons.list,
                      //   label: 'Test second screen (temp)',
                      // ),
                      // SideNavigationBarItem(
                      //   icon: Icons.list,
                      //   label: 'Test report print (temp)',
                      // ),
                      // SideNavigationBarItem(
                      //   icon: Icons.list,
                      //   label: 'Test qr code (temp)',
                      // ),
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
          return Padding(
            padding: EdgeInsets.fromLTRB(8, 10, 8, 8),
            child: this.isLoaded ?
            Scaffold(
              resizeToAvoidBottomInset: false,
              appBar: AppBar(
                automaticallyImplyLeading: false,
                title: Text('Setting',
                    style: TextStyle(fontSize: 25, color: Colors.black)),
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
                                child: Text('Close Counter'),
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
                      items: const [
                        SideNavigationBarItem(
                          icon: Icons.print,
                          label: 'Printer',
                        ),
                        SideNavigationBarItem(
                          icon: Icons.receipt,
                          label: 'Receipt Layout',
                        ),
                        SideNavigationBarItem(
                          icon: Icons.table_restaurant,
                          label: 'Table Setting',
                        ),
                        SideNavigationBarItem(
                          icon: Icons.settings,
                          label: 'App-Device setting',
                        ),
                        // SideNavigationBarItem(
                        //   icon: Icons.list,
                        //   label: 'Test sync (temp)',
                        // ),
                        // SideNavigationBarItem(
                        //   icon: Icons.list,
                        //   label: 'Test second screen (temp)',
                        // ),
                        // SideNavigationBarItem(
                        //   icon: Icons.list,
                        //   label: 'Test report print (temp)',
                        // ),
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
              ),
            ) : CustomProgressBar(),
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
    setState(() {
      this.isLoaded = true;
    });
  }

}
