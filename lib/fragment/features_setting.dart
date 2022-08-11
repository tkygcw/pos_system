import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_material_color_picker/flutter_material_color_picker.dart';
import '../notifier/theme_color.dart';

class FeaturesSetting extends StatefulWidget {
  const FeaturesSetting({Key? key}) : super(key: key);

  @override
  _FeaturesSettingState createState() => _FeaturesSettingState();
}

class _FeaturesSettingState extends State<FeaturesSetting> {
  Color? _tempMainColor;
  Color _mainColor = ThemeColor().backgroundColor;
  Color? _tempButtonColor;
  Color _buttonColor = ThemeColor().buttonColor;
  Color? _tempIconColor;
  Color _iconColor = ThemeColor().iconColor;

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
                Navigator.of(context).pop();
                setState(() => _mainColor = _tempMainColor!);
                // setState(() => _buttonColor = _tempButtonColor!);
                // setState(() => _iconColor = _tempIconColor!);
              },
            ),
          ],
        );
      },
    );
  }

  void _openMainColorPicker() async {
    _openDialog(
      "Main Color picker",
      MaterialColorPicker(
        selectedColor: _mainColor,
        allowShades: false,
        onMainColorChange: (color) => setState(() => _tempMainColor = color),
      ),
    );
  }

  void _openButtonColorPicker() async {
    _openDialog(
      "Main Color picker",
      MaterialColorPicker(
        selectedColor: _buttonColor,
        allowShades: false,
        onMainColorChange: (color) => setState(() => _tempButtonColor = color),
      ),
    );
  }
  void _openIconColorPicker() async {
    _openDialog(
      "Main Color picker",
      MaterialColorPicker(
        selectedColor: _iconColor,
        allowShades: false,
        onMainColorChange: (color) => setState(() => _tempIconColor = color),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeColor>(builder: (context, ThemeColor color, child) {
      return Scaffold(
        body: Column(
          children: [
            Expanded(
              child: Column(
                children: [
                  ListTile(
                    title: Text("Change Background Color"),
                    subtitle: Text("Main Color for the apearance of app"),
                    trailing: CircleAvatar(
                      backgroundColor: _mainColor,
                      child: InkWell(
                        onTap: () {
                          _openMainColorPicker();
                        },
                      ),
                    ),
                  ),
                  ListTile(
                    title: Text("Change Button Color"),
                    subtitle: Text("Button Color for the apearance of app"),
                    trailing: CircleAvatar(
                      backgroundColor: _buttonColor,
                      child: InkWell(
                        onTap: () {
                          _openButtonColorPicker();
                        },
                      ),
                    ),
                  ),
                  ListTile(
                    title: Text("Change Icon Color"),
                    subtitle: Text("Icon Color for the apearance of app"),
                    trailing: CircleAvatar(
                      backgroundColor: _iconColor,
                      child: InkWell(
                        onTap: () {
                          _openIconColorPicker();
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    });
  }
}
