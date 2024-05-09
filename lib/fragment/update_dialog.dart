import 'dart:io';

import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:gms_check/gms_check.dart';
import 'package:pos_system/translation/AppLocalizations.dart';
import 'package:url_launcher/url_launcher.dart';

class UpdateDialog extends StatefulWidget {
  final List versionData;
  const UpdateDialog({Key? key, required this.versionData}) : super(key: key);

  @override
  State<UpdateDialog> createState() => _UpdateDialogState();
}

class _UpdateDialogState extends State<UpdateDialog> {
  List versionData = [];

  void initState() {
    super.initState();
    this.versionData = widget.versionData;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(AppLocalizations.of(context)!.translate('new_version_available')),
      content: WillPopScope(
          onWillPop: () async {
            if(versionData[0]['force_update'] == 1){
              return false;
            } else {
              return true;
            }
          },
          child: Text('${versionData[0]['description']}')),
      actions: [
        Visibility(
          visible: versionData[0]['force_update'] == 0 ? true : false,
          child: ElevatedButton(
              onPressed: (){
                Navigator.of(context).pop();
              },
              child: Text(AppLocalizations.of(context)!.translate('close'))),
        ),
        ElevatedButton(
            onPressed: () async {
              final Uri _url;
              if(Platform.isIOS) {
                _url = Uri.parse('${versionData[0]['app_url']}');
                launchUrl(_url, mode: LaunchMode.externalApplication);
              } else if(Platform.isAndroid) {
                await GmsCheck().checkGmsAvailability();
                if(GmsCheck().isGmsAvailable){
                  _url = Uri.parse('${versionData[0]['app_url']}');
                } else {
                  Fluttertoast.showToast(backgroundColor: Colors.red, msg: "GMS not availale");
                  _url = Uri.parse('https://drive.google.com/drive/folders/1ULEb4QKmNrhRQkT_uja0J1fHK0css1Ur');
                }
                launchUrl(_url, mode: LaunchMode.externalApplication);
              }
            },
            child: Text(AppLocalizations.of(context)!.translate('update')))
      ],
    );
  }
}
