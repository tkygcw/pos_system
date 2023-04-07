import 'package:app_settings/app_settings.dart';
import 'package:flutter/material.dart';
import 'package:pos_system/database/pos_database.dart';
import 'package:pos_system/fragment/logout_dialog.dart';
import 'package:pos_system/object/app_setting.dart';
import 'package:pos_system/page/progress_bar.dart';
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
  late ThemeColor color;
  late Color _mainColor;
  late Color _buttonColor;
  late Color _iconColor;
  List<AppSetting> appSettingList = [];
  bool cashDrawer = false;
  bool _isLoaded = false;

  @override
  void initState() {
    super.initState();
    getAllAppSetting();
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
              child: Text('CANCEL'),
              onPressed: Navigator.of(context).pop,
            ),
            TextButton(
              child: Text('SUBMIT'),
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
      "Background Color picker",
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
      "Button Color picker",
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
      "Icon Color picker",
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
        body: _isLoaded ?
        SingleChildScrollView(
          child: Container(
            child: Column(
              children: [
                ListTile(
                  title: Text("Change Background Color"),
                  subtitle: Text("Main Color for the appearance of app"),
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
                  title: Text("Change Button Color"),
                  subtitle: Text("Button Color for the appearance of app"),
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
                  title: Text("Change Icon Color"),
                  subtitle: Text("Icon Color for the appearance of app"),
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
                ListTile(
                  title: Text('Auto open cash drawer'),
                  subtitle: Text('Auto open cash drawer after insert opening balance'),
                  trailing: Switch(
                      value: this.cashDrawer,
                      activeColor: color.backgroundColor,
                      onChanged: (value) async {
                        await getAllAppSetting();
                        setState(() {
                          this.cashDrawer = value;
                        });
                        if(appSettingList.length == 0){
                          await createAppSetting();
                        } else {
                          await updateAppSetting();
                        }
                      },
                  ),
                ),
                Divider(
                  color: Colors.grey,
                  height: 1,
                  thickness: 1,
                  indent: 20,
                  endIndent: 20,
                ),
                ListTile(
                  title: Text('Wi-Fi setting'),
                  subtitle: Text('open wi-fi setting'),
                  trailing: Icon(Icons.wifi),
                  onTap: () {
                    AppSettings.openWIFISettings();
                  },
                ),
                ListTile(
                  title: Text('App Notification setting'),
                  subtitle: Text('open app notification setting'),
                  trailing: Icon(Icons.notifications_on),
                  onTap: () {
                    AppSettings.openNotificationSettings();
                  },
                ),
                ListTile(
                  title: Text('Device Sound setting'),
                  subtitle: Text('open device sound setting'),
                  trailing: Icon(Icons.volume_up),
                  onTap: () {
                    AppSettings.openSoundSettings();
                  },
                ),
                Divider(
                  color: Colors.grey,
                  height: 1,
                  thickness: 1,
                  indent: 20,
                  endIndent: 20,
                ),
                ListTile(
                  title: Text('Log Out', style: TextStyle(color: Colors.red)),
                  subtitle: Text('Reset Pos', style: TextStyle(color: Colors.red)),
                  trailing: Icon(Icons.logout, color: Colors.red),
                  onTap: () {
                    openLogoutDialog();
                  },
                ),
              ],
            ),
          ),
        ) : CustomProgressBar(),
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

  updateAppSetting() async {
    AppSetting appSetting = AppSetting(
      open_cash_drawer: this.cashDrawer == true ? 1 : 0,
      app_setting_sqlite_id: appSettingList[0].app_setting_sqlite_id

    );

    int data = await PosDatabase.instance.updateAppSettings(appSetting);
  }

  createAppSetting() async {
    AppSetting appSetting = AppSetting(
      open_cash_drawer: this.cashDrawer ? 1 : 0
    );
    AppSetting data = await PosDatabase.instance.insertSetting(appSetting);
  }

  getAllAppSetting() async {
    List<AppSetting> data = await PosDatabase.instance.readAllAppSetting();
    if(data.length > 0){
      appSettingList = List.from(data);
      if(appSettingList[0].open_cash_drawer == 1){
        this.cashDrawer = true;
      } else {
        this.cashDrawer = false;
      }
    }
    setState(() {
      _isLoaded = true;
    });
  }
}
