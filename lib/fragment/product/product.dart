import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:pos_system/fragment/category/category_setting.dart';
import 'package:pos_system/fragment/food/food_setting.dart';
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
    Container(
      child: CategorySetting(),
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
            title: Text('Food',
                style: TextStyle(fontSize: 25, color: Colors.black)),
            backgroundColor: Color(0xffFAFAFA),
            elevation: 0,
          ),
          body: Row(
            children: [
              /// Pretty similar to the BottomNavigationBar!
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
                    icon: Icons.food_bank,
                    label: 'Food and Beverage',
                  ),
                  SideNavigationBarItem(
                    icon: Icons.list,
                    label: 'Categories',
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

      // );
    });
  }
}
