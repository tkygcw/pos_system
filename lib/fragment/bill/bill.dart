import 'package:flutter/material.dart';
import 'package:pos_system/fragment/bill/bill_menu.dart';
import 'package:pos_system/fragment/bill/receipt_menu.dart';
import 'package:pos_system/fragment/cart/cart.dart';

class BillPage extends StatefulWidget {
  const BillPage({Key? key}) : super(key: key);

  @override
  _BillPageState createState() => _BillPageState();
}

class _BillPageState extends State<BillPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          Expanded(flex: 12,child: ReceiptMenu())
        ],
      ),
    );
  }
}
