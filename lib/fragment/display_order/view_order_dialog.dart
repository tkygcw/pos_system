import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../notifier/theme_color.dart';

class ViewOrderDialogPage extends StatefulWidget {
  const ViewOrderDialogPage({Key? key}) : super(key: key);

  @override
  _ViewOrderDialogPageState createState() => _ViewOrderDialogPageState();
}

class _ViewOrderDialogPageState extends State<ViewOrderDialogPage> {
  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeColor>(builder: (context, ThemeColor color, child) {
      return AlertDialog(
        title: Row(
          children: [
            Text(
              "Order detail",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            Spacer(),
            // isAdd
            //     ? Container()
            //     : IconButton(
            //   icon: const Icon(Icons.delete_outlined),
            //   color: Colors.red,
            //   onPressed: () async {
            //     if (await confirm(
            //       context,
            //       title: const Text('Confirm'),
            //       content: const Text('Would you like to remove?'),
            //       textOK: const Text('Yes'),
            //       textCancel: const Text('No'),
            //     )) {
            //       return deleteCategory();
            //     }
            //     // deleteCategory();
            //   },
            // ),
          ],
        ),
        content: Container(
          height: 450.0, // Change as per your requirement
          width: 350.0,
        ),
        actions: <Widget>[
          TextButton(
            child: Text('Close'),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
          TextButton(
            child: const Text('Submit'),
            onPressed: () {
              // _submit();
              // print(selectColor);
            },
          ),
        ],
      );
    });
  }
}
