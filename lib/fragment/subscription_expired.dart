import 'package:flutter/material.dart';
import 'package:pos_system/translation/AppLocalizations.dart';
import 'package:url_launcher/url_launcher.dart';

class SubscriptionExpired extends StatefulWidget {
  const SubscriptionExpired({Key? key}) : super(key: key);

  @override
  State<SubscriptionExpired> createState() => _SubscriptionExpiredState();
}

class _SubscriptionExpiredState extends State<SubscriptionExpired> {
  List versionData = [];

  void initState() {
    super.initState();
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
