import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:gms_check/gms_check.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:pos_system/main.dart';
import 'package:pos_system/translation/AppLocalizations.dart';
import 'package:store_checker/store_checker.dart';
import 'package:url_launcher/url_launcher.dart';

class UpdateDialog extends StatefulWidget {
  final List versionData;
  const UpdateDialog({Key? key, required this.versionData}) : super(key: key);

  @override
  State<UpdateDialog> createState() => _UpdateDialogState();
}

class _UpdateDialogState extends State<UpdateDialog> {
  List versionData = [];
  String source = "", appVersion = "";

  void initState() {
    super.initState();
    this.versionData = widget.versionData;
    getSource();
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
          child: Text('Current: $source($appVersionCode)\n${versionData[0]['description']}')),
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
                  // apk
                  if(source == 'Other Source' || source == 'Local Source') {
                    _url = Uri.parse('https://drive.google.com/drive/folders/1ULEb4QKmNrhRQkT_uja0J1fHK0css1Ur');
                  } else {
                    _url = Uri.parse('${versionData[0]['app_url']}');
                  }
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
  getSource() async {
    Source installationSource;
    try {
      installationSource = await StoreChecker.getSource;
    } on PlatformException {
      installationSource = Source.UNKNOWN;
    }

    switch (installationSource) {
      case Source.IS_INSTALLED_FROM_PLAY_STORE:
      // Installed from Play Store
        source = "Play Store";
        break;
      case Source.IS_INSTALLED_FROM_PLAY_PACKAGE_INSTALLER:
      // Installed from Google Package installer
        source = "Google Package installer";
        break;
      case Source.IS_INSTALLED_FROM_LOCAL_SOURCE:
      // Installed using adb commands or side loading or any cloud service
        source = "Local Source";
        break;
      case Source.IS_INSTALLED_FROM_AMAZON_APP_STORE:
      // Installed from Amazon app store
        source = "Amazon Store";
        break;
      case Source.IS_INSTALLED_FROM_HUAWEI_APP_GALLERY:
      // Installed from Huawei app store
        source = "Huawei App Gallery";
        break;
      case Source.IS_INSTALLED_FROM_SAMSUNG_GALAXY_STORE:
      // Installed from Samsung app store
        source = "Samsung Galaxy Store";
        break;
      case Source.IS_INSTALLED_FROM_SAMSUNG_SMART_SWITCH_MOBILE:
      // Installed from Samsung Smart Switch Mobile
        source = "Samsung Smart Switch Mobile";
        break;
      case Source.IS_INSTALLED_FROM_XIAOMI_GET_APPS:
      // Installed from Xiaomi app store
        source = "Xiaomi Get Apps";
        break;
      case Source.IS_INSTALLED_FROM_OPPO_APP_MARKET:
      // Installed from Oppo app store
        source = "Oppo App Market";
        break;
      case Source.IS_INSTALLED_FROM_VIVO_APP_STORE:
      // Installed from Vivo app store
        source = "Vivo App Store";
        break;
      case Source.IS_INSTALLED_FROM_RU_STORE:
      // Installed apk from RuStore
        source = "RuStore";
        break;
      case Source.IS_INSTALLED_FROM_OTHER_SOURCE:
      // Installed from other market store
        source = "Other Source";
        break;
      case Source.IS_INSTALLED_FROM_APP_STORE:
      // Installed from app store
        source = "App Store";
        break;
      case Source.IS_INSTALLED_FROM_TEST_FLIGHT:
      // Installed from Test Flight
        source = "Test Flight";
        break;
      case Source.UNKNOWN:
      // Installed from Unknown source
        source = "Unknown Source";
        break;
    }
  }
}
