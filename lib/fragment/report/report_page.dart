import 'package:flutter/material.dart';
import 'package:pos_system/fragment/report/report_overview.dart';
import 'package:provider/provider.dart';
import 'package:side_navigation/side_navigation.dart';

import '../../notifier/theme_color.dart';
import 'transfer_report.dart';

class ReportPage extends StatefulWidget {
  const ReportPage({Key? key}) : super(key: key);

  @override
  State<ReportPage> createState() => _ReportPageState();
}

class _ReportPageState extends State<ReportPage> {
  List<Widget> views = [
    Container(
      child: ReportOverview(),
    ),
    Container(
      child: TransferRecord(),
    ),
  ];
  int selectedIndex = 0;
  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeColor>(builder: (context, ThemeColor color, child) {
      return LayoutBuilder(builder: (context, constraints) {
        if(constraints.maxWidth > 800){
          return Scaffold(
            appBar: AppBar(
              automaticallyImplyLeading: false,
              title: Text('Report',
                  style: TextStyle(fontSize: 25, color: Colors.black)),
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
                        icon: Icons.list,
                        label: 'Transfer report',
                      ),
                    ],
                    onTap: (index) {
                      setState(() {
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
          return Scaffold(
            appBar: AppBar(
              automaticallyImplyLeading: false,
              title: Text('Report',
                  style: TextStyle(fontSize: 25, color: Colors.black)),
              backgroundColor: Color(0xffFAFAFA),
              elevation: 0,
            ),
            body: Padding(
              padding: EdgeInsets.fromLTRB(8, 0, 8, 8),
              child: Row(
                children: [
                  SideNavigationBar(
                    initiallyExpanded: false,
                    expandable: true,
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
                        icon: Icons.list,
                        label: 'Daily Sales',
                      ),
                    ],
                    onTap: (index) {
                      setState(() {
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
    });
  }
}
