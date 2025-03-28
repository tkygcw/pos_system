import 'package:flutter/material.dart';
import 'package:pos_system/fragment/bill/receipt_menu.dart';
import 'package:provider/provider.dart';

import '../../notifier/cart_notifier.dart';

class BillPage extends StatefulWidget {
  const BillPage({Key? key}) : super(key: key);

  @override
  _BillPageState createState() => _BillPageState();
}

class _BillPageState extends State<BillPage> {
  @override
  Widget build(BuildContext context) {
    return Consumer<CartModel>(builder: (context, CartModel cart, child) {
      return Scaffold(
        body: ReceiptMenu(cartModel: cart,),
      );
    });

  }
}
