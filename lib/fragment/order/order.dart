import 'package:flutter/material.dart';
import 'package:pos_system/fragment/cart/cart.dart';
import 'package:pos_system/fragment/food/food_menu.dart';
import 'package:pos_system/utils/Utils.dart';
import 'package:provider/provider.dart';
import '../../notifier/theme_color.dart';

class OrderPage extends StatefulWidget {
  const OrderPage({Key? key}) : super(key: key);

  @override
  State<OrderPage> createState() => _OrderPageState();
}

class _OrderPageState extends State<OrderPage> {
  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeColor>(builder: (context, ThemeColor color, child) {
      // final drawerHeader = UserAccountsDrawerHeader(
      //   decoration: BoxDecoration(
      //     color: color.backgroundColor,
      //   ),
      //   accountName: Text('Taylor chong'),
      //   accountEmail: Text('Cashier'),
      //   currentAccountPicture: CircleAvatar(
      //       backgroundImage: NetworkImage(
      //           'https://channelsoft.com.my/wp-content/uploads/2020/02/logo1.jpg')),
      // );
      // final drawerItems = ListView(
      //   children: [
      //     drawerHeader,
      //     ListTile(
      //       title: Text(
      //         'Dashboard',
      //       ),
      //       leading: const Icon(Icons.assessment),
      //       onTap: () {
      //         setState(() => SettingPage());
      //         Navigator.pop(context);
      //       },
      //     ),
      //     ListTile(
      //       title: Text(
      //         'Product',
      //       ),
      //       leading: const Icon(Icons.icecream),
      //       onTap: () {
      //         Navigator.pop(context);
      //       },
      //     ),
      //     ListTile(
      //       title: Text(
      //         'Printer',
      //       ),
      //       leading: const Icon(Icons.print),
      //       onTap: () {
      //         Navigator.pop(context);
      //       },
      //     ),
      //     ListTile(
      //       title: Text(
      //         'Setting',
      //       ),
      //       leading: const Icon(Icons.notifications),
      //       onTap: () {
      //         Navigator.pop(context);
      //       },
      //     ),
      //   ],
      // );
      return Scaffold(
          body: Row(
        children: [
          Expanded(flex: 12, child: FoodMenu()),
          Expanded(flex: 4, child: CartPage()),
        ],
      ));
    });
  }
}
