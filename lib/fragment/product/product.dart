import 'package:collapsible_sidebar/collapsible_sidebar.dart';
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
      return Scaffold(
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
          title: Text(AppLocalizations.of(context)!.translate('product'),
              style: TextStyle(fontSize: 25, color: Colors.black)),
          backgroundColor: Color(0xffFAFAFA),
          elevation: 0,
        ),
        body: Row(
          children: [
            /// Make it take the rest of the available width
            Expanded(
              child: views.elementAt(selectedIndex),
            )
          ],
        ),
      );

      // );
    });
  }
}
