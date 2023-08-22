import 'package:flutter/material.dart';
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
            onPressed: (){
              final Uri _url = Uri.parse('${versionData[0]['app_url']}');
              launchUrl(_url, mode: LaunchMode.externalApplication);
            },
            child: Text(AppLocalizations.of(context)!.translate('update')))
      ],
    );
  }
}
