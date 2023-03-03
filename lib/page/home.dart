import 'dart:async';
import 'dart:io';

import 'package:collapsible_sidebar/collapsible_sidebar.dart';
import 'package:flutter/material.dart';
import 'package:pos_system/fragment/bill/bill.dart';
import 'package:pos_system/fragment/cart/cart.dart';
import 'package:pos_system/fragment/display_order/display_order.dart';
import 'package:pos_system/fragment/order/order.dart';
import 'package:pos_system/fragment/product/product.dart';
import 'package:pos_system/fragment/report/report_page.dart';
import 'package:pos_system/fragment/setting/setting.dart';
import 'package:pos_system/fragment/settlement/settlement_page.dart';
import 'package:pos_system/fragment/table/table.dart';
import 'package:pos_system/notifier/connectivity_change_notifier.dart';
import 'package:pos_system/notifier/theme_color.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../database/pos_database.dart';
import '../fragment/display_order/other_order.dart';
import '../fragment/qr_order/qr_order_page.dart';
import '../fragment/settlement/cash_dialog.dart';
import '../object/branch.dart';
import '../object/user.dart';

class HomePage extends StatefulWidget {
  final User? user;
  final bool isNewDay;
  const HomePage({Key? key, this.user, required this.isNewDay}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late List<CollapsibleItem> _items;
  late String currentPage;
  late String role;
  String? branchName;
  Timer? timer;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _items = _generateItems;
    currentPage = 'menu';
    getRoleName();
    getBranchName();
    if(widget.isNewDay){
      WidgetsBinding.instance.addPostFrameCallback((_) {
        showDialog(
            barrierDismissible: false, context: context, builder: (BuildContext context) {
          return WillPopScope(
              child: CashDialog(isCashIn: true, callBack: (){}, isCashOut: false, isNewDay: true),
              onWillPop: () async => false);
            //CashDialog(isCashIn: true, callBack: (){}, isCashOut: false, isNewDay: true,);
        });
      });
    }
    // timer = Timer.periodic(Duration(seconds: 15), (Timer t) {
    //   print('sync to cloud at home');
    // });
  }

  @override
  Widget build(BuildContext context) {
    var size = MediaQuery.of(context).size;
    return Consumer<ThemeColor>(builder: (context, ThemeColor color, child) {
      return WillPopScope(
        onWillPop: () async => false,
        child: Scaffold(
            resizeToAvoidBottomInset: false,
            body: SafeArea(
              //side nav bar
              child: CollapsibleSidebar(
                  sidebarBoxShadow: [
                    BoxShadow(
                      color: Colors.transparent,
                    ),
                  ],
                  // maxWidth: 80,
                  isCollapsed: true,
                  items: _items,
                  avatarImg: FileImage(File('data/user/0/com.example.pos_system/files/assets/img/logo1.jpg')),
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
                        child: Consumer<ConnectivityChangeNotifier>(builder: (context, ConnectivityChangeNotifier connection, child) {
                          return _body(size, context);
                        }),
                      ),
                      //cart page
                      Visibility(
                        visible: currentPage != 'product' &&
                            currentPage != 'setting' &&
                            currentPage != 'settlement' &&
                            currentPage != 'qr_order' &&
                            currentPage != 'report'
                            ? true
                            : false,
                        child: Expanded(
                            flex: MediaQuery.of(context).size.height > 500 ? 1 : 2,
                            child: CartPage(
                              currentPage: currentPage,
                            )),
                      )
                    ],
                  )),
            )),
      );
    });
  }

  List<CollapsibleItem> get _generateItems {
    return [
      CollapsibleItem(
        text: 'Menu',
        icon: Icons.add_shopping_cart,
        onPressed: () => setState(() => currentPage = 'menu'),
        isSelected: true,
      ),
      CollapsibleItem(
        text: 'Table',
        icon: Icons.table_restaurant,
        onPressed: () => setState(() => currentPage = 'table'),
      ),
      CollapsibleItem(
        text: 'Qr Order',
        icon: Icons.qr_code ,
        onPressed: () => setState(() => currentPage = 'qr_order'),
      ),
      CollapsibleItem(
        text: 'Other Order',
        icon: Icons.delivery_dining,
        onPressed: () => setState(() => currentPage = 'other_order'),
      ),
      CollapsibleItem(
        text: 'Bill',
        icon: Icons.receipt_long,
        onPressed: () => setState(() => currentPage = 'bill'),
      ),
      CollapsibleItem(
        text: 'Settlement',
        icon: Icons.point_of_sale,
        onPressed: () => setState(() => currentPage = 'settlement'),
      ),
      CollapsibleItem(
        text: 'Report',
        icon: Icons.monetization_on,
        onPressed: () => setState(() => currentPage = 'report'),
      ),
      CollapsibleItem(
        text: 'Product',
        icon: Icons.fastfood,
        onPressed: () => setState(() => currentPage = 'product'),
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
      case 'menu':
        return OrderPage();
      case 'product':
        return ProductPage();
      case 'table':
        return TablePage();
      case 'qr_order':
        return QrOrderPage();
      case 'bill':
        return BillPage();
      case 'other_order':
        return OtherOrderPage();
      case 'report':
        return ReportPage();
      case 'settlement':
        return SettlementPage();
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
    print('branch name : $branchName');
  }

}
