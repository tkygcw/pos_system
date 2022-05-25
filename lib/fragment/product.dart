import 'package:flutter/material.dart';
import 'package:pos_system/utils/Utils.dart';

class ProductPage extends StatefulWidget {
  const ProductPage({Key? key}) : super(key: key);

  @override
  State<ProductPage> createState() => _ProductPageState();
}

class _ProductPageState extends State<ProductPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Text(Utils.getText(context, 'product')),
    );
  }
}
