import 'dart:async';

import 'package:app_settings/app_settings.dart';
import 'package:flutter/material.dart';
import 'package:pos_system/controller/controllerObject.dart';
import 'package:pos_system/database/pos_database.dart';
import 'package:pos_system/fragment/logout_dialog.dart';
import 'package:pos_system/main.dart';
import 'package:pos_system/object/app_setting.dart';
import 'package:pos_system/page/progress_bar.dart';
import 'package:pos_system/translation/AppLocalizations.dart';
import 'package:pos_system/translation/language_setting.dart';
import 'package:provider/provider.dart';
import 'package:flutter_material_color_picker/flutter_material_color_picker.dart';
import '../../notifier/theme_color.dart';
import 'logout_dialog.dart';

class FeaturesSetting extends StatefulWidget {
  const FeaturesSetting({Key? key}) : super(key: key);

  @override
  _FeaturesSettingState createState() => _FeaturesSettingState();
}

class _FeaturesSettingState extends State<FeaturesSetting> {
  ControllerClass controller = ControllerClass();
  StreamController actionController = StreamController();
  late StreamController streamController;
  late Stream actionStream;
  late ThemeColor color;
  late Color _mainColor;
  late Color _buttonColor;
  late Color _iconColor;
  List<AppSetting> appSettingList = [];
  bool directPayment = false;
  bool _isLoaded = false;

  @override
  void initState() {
    super.initState();
    streamController = controller.appDeviceController;
    actionStream = actionController.stream.asBroadcastStream();
    listenAction();
  }


  listenAction(){
    actionController.sink.add("init");
    actionStream.listen((event) async {
      switch(event){
        case 'init':{
          await getAllAppSetting();
          controller.refresh(streamController);
        }
        break;
        case 'direct_payment':{
          await updateAppSetting();
          controller.refresh(streamController);
        }
        break;
      }
    });
  }

  void _openDialog(String title, Widget content) {
    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          contentPadding: const EdgeInsets.all(10.0),
          title: Text(title),
          content: content,
          actions: [
            TextButton(
              child: Text(AppLocalizations.of(context)!.translate('cancel')),
              onPressed: Navigator.of(context).pop,
            ),
            TextButton(
              child: Text(AppLocalizations.of(context)!.translate('submit')),
              onPressed: () {
                print('color selected');
                Navigator.of(context).pop();
                setState(() {
                    _mainColor = this.color.backgroundColor;
                    _buttonColor = this.color.buttonColor;
                    _iconColor = this.color.iconColor;

                  color.changeColor(_mainColor, _buttonColor, _iconColor);
                });
              },
            ),
          ],
        );
      },
    );
  }

  void _openMainColorPicker() async {
    _openDialog(
      AppLocalizations.of(context)!.translate('background_color_picker'),
      MaterialColorPicker(
        colors: fullMaterialColors,
        selectedColor: color.backgroundColor,
        allowShades: false,
        onMainColorChange: (color) =>
            setState(() => this.color.backgroundColor = color as Color),
      ),
    );
  }

  void _openButtonColorPicker() async {
    _openDialog(
      AppLocalizations.of(context)!.translate('button_color_picker'),
      MaterialColorPicker(
        colors: fullMaterialColors,
        selectedColor: color.buttonColor,
        allowShades: false,
        onMainColorChange: (color) => setState(() => this.color.buttonColor = color as Color),
      ),
    );
  }

  void _openIconColorPicker() async {
    _openDialog(
      AppLocalizations.of(context)!.translate('icon_color_picker'),
      MaterialColorPicker(
        colors: fullMaterialColors,
        selectedColor: color.iconColor,
        allowShades: false,
        onMainColorChange: (color) => setState(() => this.color.iconColor = color as Color),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeColor>(builder: (context, ThemeColor color, child) {
      this.color = color;
      //print(color.backgroundColor);
      return Scaffold(
        body: StreamBuilder(
          stream: controller.appDeviceStream,
          builder: (context, snapshot){
            if(snapshot.hasData){
              return SingleChildScrollView(
                child: Container(
                  child: Column(
                    children: [
                      ListTile(
                        title: Text(AppLocalizations.of(context)!.translate('change_background_color')),
                        subtitle: Text(AppLocalizations.of(context)!.translate('main_color_for_the_appearance_of_app')),
                        trailing: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.black,
                              width: 1.5,
                            ),
                          ),
                          child: CircleAvatar(
                            backgroundColor: color.backgroundColor,
                            child: InkWell(
                              onTap: () {
                                _openMainColorPicker();
                              },
                            ),
                          ),
                        ),
                      ),
                      ListTile(
                        title: Text(AppLocalizations.of(context)!.translate('change_button_color')),
                        subtitle: Text(AppLocalizations.of(context)!.translate('button_color_for_appearance_of_app')),
                        trailing: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.black,
                              width: 1.5,
                            ),
                          ),
                          child: CircleAvatar(
                            backgroundColor: color.buttonColor,
                            child: InkWell(
                              onTap: () {
                                _openButtonColorPicker();
                              },
                            ),
                          ),
                        ),
                      ),
                      ListTile(
                        title: Text(AppLocalizations.of(context)!.translate('change_icon_color')),
                        subtitle: Text(AppLocalizations.of(context)!.translate('icon_color_for_appearance_of_app')),
                        trailing: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.black,
                              width: 1.0,
                            ),
                          ),
                          child: CircleAvatar(
                            backgroundColor: color.iconColor,
                            child: InkWell(
                              onTap: () {
                                _openIconColorPicker();
                              },
                            ),
                          ),
                        ),
                      ),
                      Divider(
                        color: Colors.grey,
                        height: 1,
                        thickness: 1,
                        indent: 20,
                        endIndent: 20,
                      ),
                      // ListTile(
                      //   title: Text(AppLocalizations.of(context)!.translate('place_order_payment')),
                      //   subtitle: Text(AppLocalizations.of(context)!.translate('direct_make_payment_when_oder_placed')),
                      //   trailing: Switch(
                      //     value: directPayment,
                      //     activeColor: color.backgroundColor,
                      //     onChanged: (value) async {
                      //       directPayment = value;
                      //       actionController.sink.add("direct_payment");
                      //       //await getAllAppSetting();
                      //       // if(appSettingList.isEmpty){
                      //       //   await createAppSetting();
                      //       // } else {
                      //       //   await updateAppSetting();
                      //       // }
                      //     },
                      //   ),
                      // ),
                      // Divider(
                      //   color: Colors.grey,
                      //   height: 1,
                      //   thickness: 1,
                      //   indent: 20,
                      //   endIndent: 20,
                      // ),
                      ListTile(
                        title: Text(AppLocalizations.of(context)!.translate('wifi_setting')),
                        subtitle: Text(AppLocalizations.of(context)!.translate('open_wifi_setting')),
                        trailing: Icon(Icons.wifi),
                        onTap: () {
                          AppSettings.openWIFISettings();
                        },
                      ),
                      ListTile(
                        title: Text(AppLocalizations.of(context)!.translate('app_notification_setting')),
                        subtitle: Text(AppLocalizations.of(context)!.translate('open_app_notification_setting')),
                        trailing: Icon(Icons.notifications_on),
                        onTap: () {
                          AppSettings.openNotificationSettings();
                        },
                      ),
                      ListTile(
                        title: Text(AppLocalizations.of(context)!.translate('device_sound_setting')),
                        subtitle: Text(AppLocalizations.of(context)!.translate('open_device_sound_setting')),
                        trailing: Icon(Icons.volume_up),
                        onTap: () {
                          AppSettings.openSoundSettings();
                        },
                      ),
                      ListTile(
                        title: Text(AppLocalizations.of(context)!.translate('device_language_setting')),
                        subtitle: Text(AppLocalizations.of(context)!.translate('open_device_language_setting')),
                        trailing: Icon(Icons.language),
                        onTap: () {
                          openLanguageDialog();
                        },
                      ),
                      Divider(
                        color: Colors.grey,
                        height: 1,
                        thickness: 1,
                        indent: 20,
                        endIndent: 20,
                      ),
                      Padding(
                        padding: EdgeInsets.all(15),
                        child: Card(
                          color: Colors.redAccent,
                          child: ListTile(
                            title: Text(AppLocalizations.of(context)!.translate('logout'), style: TextStyle(color: Colors.white)),
                            subtitle: Text(AppLocalizations.of(context)!.translate('reset_pos'), style: TextStyle(color: Colors.white)),
                            trailing: Icon(Icons.logout, color: Colors.white),
                            onTap: () {
                              openLogoutDialog();
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            } else {
              return CustomProgressBar();
            }
          },
        )

      );
    });
  }

  Future<Future<Object?>> openLogoutDialog() async {
    return showGeneralDialog(
        barrierColor: Colors.black.withOpacity(0.5),
        transitionBuilder: (context, a1, a2, widget) {
          final curvedValue = Curves.easeInOutBack.transform(a1.value) - 1.0;
          return Transform(
            transform: Matrix4.translationValues(0.0, curvedValue * 200, 0.0),
            child: Opacity(
                opacity: a1.value,
                child: LogoutConfirmDialog(currentPage: 'Setting')),
          );
        },
        transitionDuration: Duration(milliseconds: 200),
        barrierDismissible: false,
        context: context,
        pageBuilder: (context, animation1, animation2) {
          // ignore: null_check_always_fails
          return null!;
        });
  }

  Future<Future<Object?>> openLanguageDialog() async {
    return showGeneralDialog(
        barrierColor: Colors.black.withOpacity(0.5),
        transitionBuilder: (context, a1, a2, widget) {
          final curvedValue = Curves.easeInOutBack.transform(a1.value) - 1.0;
          return Transform(
            transform: Matrix4.translationValues(0.0, curvedValue * 200, 0.0),
            child: Opacity(
                opacity: a1.value,
                child: LanguageDialog()),
          );
        },
        transitionDuration: Duration(milliseconds: 200),
        barrierDismissible: false,
        context: context,
        pageBuilder: (context, animation1, animation2) {
          // ignore: null_check_always_fails
          return null!;
        });
  }

  updateAppSetting() async {
    print('update called');
    AppSetting appSetting = AppSetting(
      direct_payment: directPayment ? 1 : 0,
      app_setting_sqlite_id: appSettingList[0].app_setting_sqlite_id
    );
    int data = await PosDatabase.instance.updateDirectPaymentSettings(appSetting);
  }

  // createAppSetting() async {
  //   AppSetting appSetting = AppSetting(
  //     open_cash_drawer: this.cashDrawer ? 1 : 0,
  //     show_second_display: this.secondDisplay ? 1 : 0
  //
  //   );
  //   AppSetting data = await PosDatabase.instance.insertSetting(appSetting);
  // }

  getAllAppSetting() async {
    List<AppSetting> data = await PosDatabase.instance.readAllAppSetting();
    if(data.length > 0){
      appSettingList = data;
      if(appSettingList[0].direct_payment == 1){
        directPayment = true;
      } else {
        directPayment = false;
      }
    }
  }
}
