import 'package:flutter/material.dart';
import 'package:pos_system/notifier/theme_color.dart';
import 'package:provider/provider.dart';

class LoadingDialog extends StatefulWidget {
  const LoadingDialog({Key? key}) : super(key: key);

  @override
  State<LoadingDialog> createState() => _LoadingDialogState();
}

class _LoadingDialogState extends State<LoadingDialog> {
  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeColor>(builder: (context, ThemeColor color, child) {
      return WillPopScope(
        onWillPop: () async => true,
        child: AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(
                color: color.backgroundColor,
              ),
              Container(margin: EdgeInsets.only(left: 15),child:Text("Placing order, Please wait..." )),
            ],
          ),
        ),
      );
    });

  }
}
