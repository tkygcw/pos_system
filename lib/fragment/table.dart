import 'package:flutter/material.dart';
import 'package:pos_system/fragment/cart.dart';
import 'table/table_menu.dart';

class TablePage extends StatefulWidget {
  const TablePage({Key? key}) : super(key: key);

  @override
  _TablePageState createState() => _TablePageState();
}

class _TablePageState extends State<TablePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
body: Row(
  children: [
    Expanded(flex: 12,child: TableMenu()),
    Expanded(flex: 4, child: CartPage())
  ],
),
    );
  }
}
