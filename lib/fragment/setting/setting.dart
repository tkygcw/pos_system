import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:pos_system/fragment/printer/test_print.dart';
// import 'package:pos_system/fragment/printer/test_scanner.dart';
import 'package:pos_system/fragment/setting/features_setting.dart';
import 'package:pos_system/fragment/setting/logout_dialog.dart';
import 'package:pos_system/fragment/setting/printer_setting.dart';
import 'package:pos_system/fragment/setting/receipt_setting.dart';
import 'package:pos_system/fragment/test_sync/test_category_sync.dart';
import 'package:pos_system/object/user.dart';
import 'package:pos_system/page/login.dart';
import 'package:pos_system/page/progress_bar.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:side_navigation/side_navigation.dart';
import '../../database/pos_database.dart';
import '../../notifier/theme_color.dart';
import '../../object/cash_record.dart';
import '../../translation/AppLocalizations.dart';

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
      child: FeaturesSetting(),
    ),
    Container(
      child: TestCategorySync(),
    )
  ];
  int selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    getLoginUserInfo();
    checkCashRecord();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeColor>(builder: (context, ThemeColor color, child) {
      return Padding(
        padding: EdgeInsets.fromLTRB(8, 10, 8, 8),
        child: this.isLoaded ? Scaffold(
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
                        primary: color.backgroundColor,
                      ),
                      onPressed: () {
                        if(this.cashRecordList.length == 0){
                          openLogoutDialog();
                        } else {
                          if(this.count == 0){
                            Fluttertoast.showToast(
                                backgroundColor: Colors.red,
                                msg: "${AppLocalizations.of(context)?.translate('log_out_settlement')}");
                            this.count++;
                          }
                        }

                      },
                      child: Text('Logout'),
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
                    icon: Icons.color_lens,
                    label: 'Appearance',
                  ),
                  SideNavigationBarItem(
                    icon: Icons.list,
                    label: 'Test sync (temp)',
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
    final prefs = await SharedPreferences.getInstance();
    final int? branch_id = prefs.getInt('branch_id');
    List<CashRecord> data = await PosDatabase.instance.readBranchCashRecord(branch_id.toString());
    cashRecordList = List.from(data);
    setState(() {
      this.isLoaded = true;
    });
  }

}
