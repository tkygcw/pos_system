import 'package:flutter/material.dart';
import 'package:pos_system/fragment/food/food_setting.dart';
import 'package:pos_system/translation/AppLocalizations.dart';
import 'package:provider/provider.dart';
import 'package:side_navigation/side_navigation.dart';
import '../../notifier/theme_color.dart';

class ProductPage extends StatefulWidget {
  const ProductPage({Key? key}) : super(key: key);

  @override
  _ProductPageState createState() => _ProductPageState();
}

class _ProductPageState extends State<ProductPage> {
  List<Widget> views = [
    Container(
      child: FoodSetting(),
    ),
    // Container(
    //   child: CategorySetting(),
    // ),
  ];
  int selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeColor>(builder: (context, ThemeColor color, child) {
      return Padding(
        padding: MediaQuery.of(context).size.width > 900 && MediaQuery.of(context).size.height > 500 ? EdgeInsets.fromLTRB(8, 10, 8, 8) : EdgeInsets.fromLTRB(0, 0, 8, 8),
        child: Scaffold(
          resizeToAvoidBottomInset: false,
          appBar: AppBar(
            automaticallyImplyLeading: false,
            title: Text(AppLocalizations.of(context)!.translate('food'),
                style: TextStyle(fontSize: 25, color: Colors.black)),
            backgroundColor: Color(0xffFAFAFA),
            elevation: 0,
          ),
          body: Row(
            children: [
              /// Pretty similar to the BottomNavigationBar!
              SideNavigationBar(
                initiallyExpanded: MediaQuery.of(context).size.height > 500 ? true :false,
                expandable: MediaQuery.of(context).size.height > 500 ? false : true,
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
                    icon: Icons.food_bank,
                    label: AppLocalizations.of(context)!.translate('food_and_beverage'),
                  ),
                  // SideNavigationBarItem(
                  //   icon: Icons.list,
                  //   label: 'Categories',
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
        ),
      );

      // );
    });
  }
}
