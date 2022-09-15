import 'package:collapsible_sidebar/collapsible_sidebar.dart';
import 'package:flutter/material.dart';
import 'package:pos_system/fragment/bill/bill.dart';
import 'package:pos_system/fragment/cart/cart.dart';
import 'package:pos_system/fragment/order/order.dart';
import 'package:pos_system/fragment/product/product.dart';
import 'package:pos_system/fragment/setting/setting.dart';
import 'package:pos_system/fragment/table/table.dart';
import 'package:pos_system/notifier/connectivity_change_notifier.dart';
import 'package:pos_system/notifier/theme_color.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../database/pos_database.dart';
import '../object/branch.dart';
import '../object/user.dart';

class HomePage extends StatefulWidget {
  final User? user;

  const HomePage({Key? key, this.user}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late List<CollapsibleItem> _items;
  late String currentPage;
  late String role;
  String? branchName;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _items = _generateItems;
    currentPage = 'order';
    getRoleName();
    getBranchName();
  }

  @override
  Widget build(BuildContext context) {
    var size = MediaQuery.of(context).size;
    return Consumer<ThemeColor>(builder: (context, ThemeColor color, child) {
      return Scaffold(
          resizeToAvoidBottomInset: false,
          body: SafeArea(
            child: CollapsibleSidebar(
                sidebarBoxShadow: [
                  BoxShadow(
                    color: Colors.transparent,
                  ),
                ],
                // maxWidth: 80,
                isCollapsed: true,
                items: _items,
                avatarImg: NetworkImage(
                    'https://channelsoft.com.my/wp-content/uploads/2020/02/logo1.jpg'),
                title: widget.user!.name! +
                    "\n" +
                    (branchName ?? '') +
                    " - " +
                    role,
                backgroundColor: color.backgroundColor,
                selectedTextColor: color.iconColor,
                textStyle: TextStyle(fontSize: 15, fontStyle: FontStyle.italic),
                titleStyle: TextStyle(
                    fontSize: 17,
                    fontStyle: FontStyle.italic,
                    fontWeight: FontWeight.bold),
                toggleTitleStyle:
                    TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                selectedIconColor: color.iconColor,
                selectedIconBox: color.buttonColor,
                body: Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: Consumer<ConnectivityChangeNotifier>(builder:
                          (context, ConnectivityChangeNotifier connection,
                              child) {
                        return _body(size, context);
                      }),
                    ),
                    Visibility(
                      visible: currentPage != 'product' && currentPage != 'setting'? true: false,
                      child: Expanded(
                          flex: 1, child: CartPage()
                      ),
                    )
                  ],
                )),
          ));
    });
  }

  List<CollapsibleItem> get _generateItems {
    return [
      CollapsibleItem(
        text: 'Order',
        icon: Icons.add_shopping_cart,
        onPressed: () => setState(() => currentPage = 'order'),
        isSelected: true,
      ),
      CollapsibleItem(
        text: 'Product',
        icon: Icons.fastfood,
        onPressed: () => setState(() => currentPage = 'product'),
      ),
      CollapsibleItem(
        text: 'Table',
        icon: Icons.table_restaurant,
        onPressed: () => setState(() => currentPage = 'table'),
      ),
      CollapsibleItem(
        text: 'Bill',
        icon: Icons.receipt,
        onPressed: () => setState(() => currentPage = 'bill'),
      ),
      CollapsibleItem(
        text: 'Setting',
        icon: Icons.settings,
        onPressed: () => setState(() => currentPage = 'setting'),
      ),
    ];
  }

  Widget _body(Size size, BuildContext context) {
    switch (currentPage) {
      case 'order':
        return OrderPage();
      case 'product':
        return ProductPage();
      case 'table':
        return TablePage();
      case 'bill':
        return BillPage();
      default:
        return SettingMenu();
    }
  }

  getRoleName() {
    if (widget.user?.role.toString() == "0") {
      role = 'Owner';
    } else if (widget.user!.role! == 1) {
      role = 'Cashier';
    } else if (widget.user!.role! == 2) {
      role = 'Manager';
    } else if (widget.user!.role! == 3) {
      role = 'Waiter';
    }
  }

  getBranchName() async {
    final prefs = await SharedPreferences.getInstance();
    final int? branch_id = prefs.getInt('branch_id');
    Branch? data =
        await PosDatabase.instance.readBranchName(branch_id.toString());
    setState(() {
      branchName = data!.name!;
    });
  }
}
