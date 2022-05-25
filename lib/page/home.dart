import 'package:collapsible_sidebar/collapsible_sidebar.dart';
import 'package:flutter/material.dart';
import 'package:pos_system/fragment/product.dart';
import 'package:pos_system/fragment/setting.dart';
import 'package:pos_system/notifier/connectivity_change_notifier.dart';
import 'package:pos_system/notifier/theme_color.dart';
import 'package:provider/provider.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late List<CollapsibleItem> _items;
  late String currentPage;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _items = _generateItems;
    currentPage = 'dashboard';
  }

  @override
  Widget build(BuildContext context) {
    var size = MediaQuery.of(context).size;
    return Consumer<ThemeColor>(builder: (context, ThemeColor color, child) {
      color.changeColor();
      return Scaffold(
          body: SafeArea(
        child: CollapsibleSidebar(
          isCollapsed: true,
          items: _items,
          avatarImg: NetworkImage('https://channelsoft.com.my/wp-content/uploads/2020/02/logo1.jpg'),
          title: 'John Smith',
          onTitleTap: () {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Yay! Flutter Collapsible Sidebar!')));
          },
          backgroundColor: color.backgroundColor,
          selectedTextColor: color.iconColor,
          textStyle: TextStyle(fontSize: 15, fontStyle: FontStyle.italic),
          titleStyle: TextStyle(fontSize: 20, fontStyle: FontStyle.italic, fontWeight: FontWeight.bold),
          toggleTitleStyle: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          selectedIconColor: color.iconColor,
          selectedIconBox: color.buttonColor,
          body: Consumer<ConnectivityChangeNotifier>(builder: (context, ConnectivityChangeNotifier connection, child) {
            return _body(size, context);
          }),
        ),
      ));
    });
  }

  List<CollapsibleItem> get _generateItems {
    return [
      CollapsibleItem(
        text: 'Dashboard',
        icon: Icons.assessment,
        onPressed: () => setState(() => currentPage = 'dashboard'),
        isSelected: true,
      ),
      CollapsibleItem(
        text: 'Product',
        icon: Icons.icecream,
        onPressed: () => setState(() => currentPage = 'product'),
      ),
      CollapsibleItem(
        text: 'Printer',
        icon: Icons.print,
        onPressed: () => setState(() => currentPage = 'printer'),
      ),
      CollapsibleItem(
        text: 'Setting',
        icon: Icons.notifications,
        onPressed: () => setState(() => currentPage = 'setting'),
      ),
    ];
  }

  Widget _body(Size size, BuildContext context) {
    switch (currentPage) {
      case 'printer':
        return ProductPage();
      default:
        return SettingPage();
    }
  }
}
