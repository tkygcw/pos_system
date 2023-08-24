import 'package:flutter/material.dart';
import 'package:pos_system/translation/AppLocalizations.dart';

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
      onWillPop: () async => false,
      child: AlertDialog(
        title: Text(AppLocalizations.of(context)!.translate('connection_failed')),
        content: Container(
          child: Text(AppLocalizations.of(context)!.translate('network_connection_failed')),
        ),
        actions: [
          Center(
            child: ElevatedButton(
                onPressed: () async {
                  widget.callback();
                  return Navigator.of(context).pop();
                  // bool _hasInternetAccess = await Domain().isHostReachable();
                  // if(_hasInternetAccess){
                  //   widget.callback();
                  //   return Navigator.of(context).pop();
                  // } else {
                  //   return;
                  // }
                }, 
                child: Text(AppLocalizations.of(context)!.translate('retry'))
            ),
          )
        ],
      ),
    );
  }
}
