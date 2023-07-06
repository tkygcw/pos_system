import 'package:flutter/material.dart';

import '../database/domain.dart';

class NetworkDialog extends StatefulWidget {
  final Function() callback;
  const NetworkDialog({Key? key, required this.callback}) : super(key: key);

  @override
  State<NetworkDialog> createState() => _NetworkDialogState();
}

class _NetworkDialogState extends State<NetworkDialog> {
  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        bool _hasInternetAccess = await Domain().isHostReachable();
        if(_hasInternetAccess){
          return true;
        } else {
          return false;
        }
      },
      child: AlertDialog(
        title: Text('Connection failed'),
        content: Container(
          child: Text('Network Connection failed. Please check your devices wireless or mobile network setting and reconnect'),
        ),
        actions: [
          Center(
            child: ElevatedButton(
                onPressed: () async {
                  bool _hasInternetAccess = await Domain().isHostReachable();
                  if(_hasInternetAccess){
                    widget.callback();
                    return Navigator.of(context).pop();
                  } else {
                    return;
                  }
                }, 
                child: Text('Retry')
            ),
          )
        ],
      ),
    );
  }
}
