import 'package:flutter/material.dart';
import 'package:pos_system/notifier/cart_notifier.dart';
import 'package:provider/provider.dart';
import 'table_menu.dart';

class TablePage extends StatefulWidget {
  const TablePage({Key? key}) : super(key: key);

  @override
  _TablePageState createState() => _TablePageState();
}

class _TablePageState extends State<TablePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Consumer<CartModel>(builder: (context, CartModel cart, child) {
      return Row(
        children: [Expanded(flex: 12, child: TableMenu(callBack: () {}))],
      );
    }));
  }
}
