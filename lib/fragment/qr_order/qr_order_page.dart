import 'package:flutter/material.dart';
import 'package:pos_system/page/progress_bar.dart';

class QrOrderPage extends StatefulWidget {
  const QrOrderPage({Key? key}) : super(key: key);

  @override
  State<QrOrderPage> createState() => _QrOrderPageState();
}

class _QrOrderPageState extends State<QrOrderPage> {
  bool _isLoaded = false;

  @override
  void initState() {
    super.initState();
    _isLoaded = true;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoaded ? 
      Container(
        padding:  EdgeInsets.all(20),
        child: Container(
          margin: EdgeInsets.fromLTRB(0, 0, 0, 10),
          alignment: Alignment.topLeft,
          child: Text('Qr Order', style: TextStyle(fontSize: 25)),
        ),
      ) 
          : CustomProgressBar(),
    );
  }
}
