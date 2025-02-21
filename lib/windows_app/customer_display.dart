import 'package:flutter/material.dart';

class WinCustomerDisplay extends StatelessWidget {
  const WinCustomerDisplay({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: Center(
            child: Container(
                height: 150,
                child: Image(image: AssetImage("drawable/logo_cus_display.png"),)
            )
        ),
      ),
    );
  }
}
