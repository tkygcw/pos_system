import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pos_system/fragment/display_order/other_order.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../database/pos_database.dart';
import '../fragment/bill/bill.dart';
import '../fragment/display_order/display_order.dart';
import '../fragment/order/order.dart';
import '../fragment/product/product.dart';
import '../fragment/qr_order/qr_order_page.dart';
import '../fragment/setting/setting.dart';
import '../fragment/settlement/cash_dialog.dart';
import '../fragment/settlement/settlement_page.dart';
import '../fragment/table/table.dart';
import '../notifier/connectivity_change_notifier.dart';
import '../notifier/theme_color.dart';
import '../object/branch.dart';
import '../object/user.dart';

class MobileHomePage extends StatefulWidget {
  final User? user;
  final bool isNewDay;
  const MobileHomePage({Key? key, this.user, required this.isNewDay}) : super(key: key);

  @override
  State<MobileHomePage> createState() => _MobileHomePageState();
}

class _MobileHomePageState extends State<MobileHomePage> {
  late String currentPage;
  late String role;
  String? branchName;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
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
  }

  @override
  Widget build(BuildContext context) {
    var size = MediaQuery.of(context).size;
    return Consumer<ThemeColor>(builder: (context, ThemeColor color, child) {
        return Scaffold(
          appBar: AppBar(
            title: Text('Lucky 8'),
            centerTitle: true,
          ),
          body: SafeArea(
              child: Consumer<ConnectivityChangeNotifier>(builder: (context, ConnectivityChangeNotifier connection, child) {
                return _body(size, context);
              })
          ),
          drawer: Drawer(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                UserAccountsDrawerHeader(
                  decoration: BoxDecoration(
                    color: color.backgroundColor,
                  ),
                  currentAccountPicture: CircleAvatar(
                    backgroundImage: FileImage(File('data/user/0/com.example.pos_system/files/assets/img/logo1.jpg')),
                  ),
                  accountName: Text(branchName!),
                  accountEmail: Text('${widget.user!.name!}-${role}'),
                ),
                ListTile(
                  title: const Text('Menu'),
                  leading: Icon(Icons.add_shopping_cart),
                  onTap: () {
                    setState(() => currentPage = 'menu');
                    Navigator.pop(context);
                  },
                ),
                ListTile(
                  title: const Text('Product'),
                  leading: Icon(Icons.fastfood),
                  onTap: () {
                    setState(() => currentPage = 'product');
                    Navigator.pop(context);
                  },
                ),
                ListTile(
                  title: const Text('Table'),
                  leading: Icon(Icons.table_restaurant),
                  onTap: () {
                    setState(() => currentPage = 'table');
                    Navigator.pop(context);
                  },
                ),
                ListTile(
                  title: const Text('Qr order'),
                  leading: Icon(Icons.qr_code),
                  onTap: () {
                    setState(() => currentPage = 'qr_order');
                    Navigator.pop(context);
                  },
                ),
                ListTile(
                  title: const Text('Bill'),
                  leading: Icon(Icons.receipt_long),
                  onTap: () {
                    setState(() => currentPage = 'bill');
                    Navigator.pop(context);
                  },
                ),
                ListTile(
                  title: const Text('Other order'),
                  leading: Icon(Icons.receipt),
                  onTap: () {
                    setState(() => currentPage = 'other_order');
                    Navigator.pop(context);
                  },
                ),
                ListTile(
                  title: const Text('Settlement'),
                  leading: Icon(Icons.monetization_on),
                  onTap: () {
                    setState(() => currentPage = 'settlement');
                    Navigator.pop(context);
                  },
                ),
                ListTile(
                  title: const Text('Setting'),
                  leading: Icon(Icons.settings),
                  onTap: () {
                    setState(() => currentPage = 'setting');
                    Navigator.pop(context);
                  },
                ),
              ],
            ),
          ),
        );
      }
    );
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
