import 'package:flutter/material.dart';
import 'package:pos_system/fragment/features_setting.dart';
import 'package:pos_system/fragment/printer_setting.dart';
import 'package:pos_system/page/login.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:side_navigation/side_navigation.dart';
import '../notifier/theme_color.dart';

class SettingMenu extends StatefulWidget {
  const SettingMenu({Key? key}) : super(key: key);

  @override
  _SettingMenuState createState() => _SettingMenuState();
}

class _SettingMenuState extends State<SettingMenu> {
  List<Widget> views = [
    Container(
      child: PrinterSetting(),
    ),
    Container(
      child: FeaturesSetting(),
    ),
  ];
  int selectedIndex = 0;


  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeColor>(builder: (context, ThemeColor color, child) {
      return Padding(
        padding: EdgeInsets.fromLTRB(8, 10, 8, 8),
        child: Scaffold(
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
                    Text("yongwei0512@hotmail.com"),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        primary: color.backgroundColor,
                      ),
                      onPressed: () {
                        logout();
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
                    icon: Icons.list,
                    label: 'Features',
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
        ),
      );
    });
  }
  logout() async{
    final prefs = await SharedPreferences.getInstance();
    prefs.clear();
    Navigator.of(context).pushReplacement(MaterialPageRoute(
        builder: (context) => LoginPage()));

  }
}
