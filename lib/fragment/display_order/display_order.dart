
import 'package:flutter/material.dart';

class DisplayOrderPage extends StatefulWidget {

  const DisplayOrderPage({Key? key}) : super(key: key);

  @override
  _DisplayOrderPageState createState() => _DisplayOrderPageState();
}

class _DisplayOrderPageState extends State<DisplayOrderPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Column(
            children: [
              Row(
                children: [
                  Text(
                    "Order",
                    style: TextStyle(fontSize: 25),
                  ),
                  Spacer(),
                  SizedBox(width: 200, child: TextField())
                ],
              )
            ],
          ),
        ),
      ) ,
    );
  }
}
