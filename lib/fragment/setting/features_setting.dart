import 'dart:async';

import 'package:app_settings/app_settings.dart';
import 'package:confirm_dialog/confirm_dialog.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';
import 'package:pos_system/controller/controllerObject.dart';
import 'package:pos_system/fragment/logout_dialog.dart';
import 'package:pos_system/notifier/app_setting_notifier.dart';
import 'package:pos_system/object/app_setting.dart';
import 'package:pos_system/page/pos_pin.dart';
import 'package:pos_system/page/progress_bar.dart';
import 'package:pos_system/translation/AppLocalizations.dart';
import 'package:pos_system/translation/language_setting.dart';
import 'package:provider/provider.dart';
import 'package:flutter_material_color_picker/flutter_material_color_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../notifier/theme_color.dart';

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
  late SharedPreferences prefs;
  bool isLoaded = false;
  final List<String> orientationOption = [
    'auto',
    'landscape',
    'portrait'
  ];
  int? orientation = 0;

  @override
  void initState() {
    super.initState();
    getPrefData();
    streamController = controller.appDeviceController;
    actionStream = actionController.stream.asBroadcastStream();
    listenAction();
  }

  listenAction(){
    actionController.sink.add("init");
    actionStream.listen((event) async {
      switch(event){
        case 'init':{
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
      Container(
        width: MediaQuery.of(context).size.width * 0.5,
        height: MediaQuery.of(context).size.height * 0.5,
        child: MaterialColorPicker(
          circleSize: MediaQuery.of(context).orientation == Orientation.landscape ? 75 : 55,
          colors: fullMaterialColors,
          selectedColor: color.backgroundColor,
          allowShades: false,
          onMainColorChange: (color) =>
              setState(() => this.color.backgroundColor = color as Color),
        ),
      ),
    );
  }

  void _openButtonColorPicker() async {
    _openDialog(
      AppLocalizations.of(context)!.translate('button_color_picker'),
      Container(
        width: MediaQuery.of(context).size.width * 0.5,
        height: MediaQuery.of(context).size.height * 0.5,
        child: MaterialColorPicker(
          circleSize: MediaQuery.of(context).orientation == Orientation.landscape ? 75 : 55,
          colors: fullMaterialColors,
          selectedColor: color.buttonColor,
          allowShades: false,
          onMainColorChange: (color) => setState(() => this.color.buttonColor = color as Color),
        ),
      ),
    );
  }

  void _openIconColorPicker() async {
    _openDialog(
      AppLocalizations.of(context)!.translate('icon_color_picker'),
      Container(
        width: MediaQuery.of(context).size.width * 0.5,
        height: MediaQuery.of(context).size.height * 0.5,
        child: MaterialColorPicker(
          circleSize: MediaQuery.of(context).orientation == Orientation.landscape ? 75 : 55,
          colors: fullMaterialColors,
          selectedColor: color.iconColor,
          allowShades: false,
          onMainColorChange: (color) => setState(() => this.color.iconColor = color as Color),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeColor>(builder: (context, ThemeColor color, child) {
      this.color = color;
      return Consumer<AppSettingModel>(builder: (context, AppSettingModel appSettingModel, child) {
        return Scaffold(
            appBar:  MediaQuery.of(context).size.width < 800 && MediaQuery.of(context).orientation == Orientation.portrait ? AppBar(
              elevation: 1,
              leading: IconButton(
                icon: Icon(Icons.arrow_back_ios, color: color.buttonColor),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
              backgroundColor: Colors.white,
              title: Text(AppLocalizations.of(context)!.translate('app_device_setting'),
                  style: TextStyle(fontSize: 20, color: color.backgroundColor)),
              centerTitle: false,
            )
                : null,
            body: StreamBuilder(
              stream: controller.appDeviceStream,
              builder: (context, snapshot){
                if(snapshot.hasData){
                  return isLoaded ? SingleChildScrollView(
                    child: Container(
                      child: Column(
                        children: [
                          ListTile(
                            title: Text(AppLocalizations.of(context)!.translate('screen_orientation')),
                            subtitle: Text(AppLocalizations.of(context)!.translate('screen_orientation_desc')),
                            trailing: SizedBox(
                              width: MediaQuery.of(context).orientation == Orientation.landscape ? 200 : 150,
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton2(
                                  isExpanded: true,
                                  buttonStyleData: ButtonStyleData(
                                    height: 55,
                                    padding: const EdgeInsets.only(left: 14, right: 14),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(5),
                                      border: Border.all(
                                        color: Colors.black26,
                                      ),
                                    ),
                                  ),
                                  dropdownStyleData: DropdownStyleData(
                                    maxHeight: 200,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(10),
                                      color: Colors.grey.shade100,
                                    ),
                                    scrollbarTheme: ScrollbarThemeData(
                                        thickness: WidgetStateProperty.all(5),
                                        mainAxisMargin: 20,
                                        crossAxisMargin: 5
                                    ),
                                  ),
                                  items: orientationOption.asMap().entries.map((orientationValue) => DropdownMenuItem<int>(
                                    value: orientationValue.key,
                                    child: Text(
                                      AppLocalizations.of(context)!.translate(orientationValue.value),
                                      overflow: TextOverflow.visible,
                                      style: const TextStyle(
                                        fontSize: 14,
                                      ),
                                    ),
                                  )).toList(),
                                  value: orientation,
                                  onChanged: (int? newValue) async{
                                    if (orientation != newValue) {
                                      if (await confirm(
                                        context,
                                        title: Text('${AppLocalizations.of(context)?.translate('screen_orientation')}'),
                                        content: Text('${AppLocalizations.of(context)?.translate('to_pos_pin')}'),
                                        textOK: Text('${AppLocalizations.of(context)?.translate('yes')}'),
                                        textCancel: Text('${AppLocalizations.of(context)?.translate('no')}'),
                                      )) {
                                        orientation = newValue;
                                        prefs.setInt('orientation', orientation!);
                                        Navigator.of(context).pushAndRemoveUntil(
                                          MaterialPageRoute(
                                            builder: (BuildContext context) => PosPinPage(),
                                          ),
                                              (Route route) => false,
                                        );
                                        setState(() {

                                        });
                                      }
                                      // actionController.sink.add("switch");
                                    }
                                  },
                                ),
                              ),
                            ),
                          ),
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
                            onTap: _openMainColorPicker,
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
                            onTap: _openButtonColorPicker,
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
                            onTap: _openIconColorPicker,
                          ),
                          Divider(
                            color: Colors.grey,
                            height: 1,
                            thickness: 1,
                            indent: 20,
                            endIndent: 20,
                          ),
                          ListTile(
                            title: Text(AppLocalizations.of(context)!.translate('wifi_setting')),
                            subtitle: Text(AppLocalizations.of(context)!.translate('open_wifi_setting')),
                            trailing: Icon(Icons.wifi),
                            onTap: () {
                              AppSettings.openAppSettings(type: AppSettingsType.wifi);
                            },
                          ),
                          ListTile(
                            title: Text(AppLocalizations.of(context)!.translate('app_notification_setting')),
                            subtitle: Text(AppLocalizations.of(context)!.translate('open_app_notification_setting')),
                            trailing: Icon(Icons.notifications_on),
                            onTap: () {
                              AppSettings.openAppSettings(type: AppSettingsType.notification);
                            },
                          ),
                          ListTile(
                            title: Text(AppLocalizations.of(context)!.translate('device_sound_setting')),
                            subtitle: Text(AppLocalizations.of(context)!.translate('open_device_sound_setting')),
                            trailing: Icon(Icons.volume_up),
                            onTap: () {
                              AppSettings.openAppSettings(type: AppSettingsType.sound);
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
                  ) : CustomProgressBar();
                } else {
                  return CustomProgressBar();
                }
              },
            )
        );
      });
      //print(color.backgroundColor);
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

  getPrefData() async {
    try {
      prefs = await SharedPreferences.getInstance();
      if(prefs.getInt('orientation') != null) {
        orientation = prefs.getInt('orientation');
      } else {
        orientation = 0;
        prefs.setInt('orientation', orientation!);
      }
      setState(() {
        isLoaded = true;
      });
    } catch (e) {
      orientation = 0;
      setState(() {
        isLoaded = true;
      });
    }
  }
}
