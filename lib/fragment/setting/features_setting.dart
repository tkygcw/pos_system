import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_material_color_picker/flutter_material_color_picker.dart';
import '../../notifier/theme_color.dart';

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
      "Main Color picker",
      MaterialColorPicker(
        selectedColor: color.backgroundColor,
        allowShades: false,
        onMainColorChange: (color) =>
            setState(() => this.color.backgroundColor = color as Color),
      ),
    );
  }

  void _openButtonColorPicker() async {
    _openDialog(
      "Main Color picker",
      MaterialColorPicker(
        selectedColor: color.buttonColor,
        allowShades: false,
        onMainColorChange: (color) => setState(() => this.color.buttonColor = color as Color),
      ),
    );
  }

  void _openIconColorPicker() async {
    _openDialog(
      "Main Color picker",
      MaterialColorPicker(
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
        body: Column(
          children: [
            Expanded(
              child: Column(
                children: [
                  ListTile(
                    title: Text("Change Background Color"),
                    subtitle: Text("Main Color for the appearance of app"),
                    trailing: CircleAvatar(
                      backgroundColor: color.backgroundColor,
                      child: InkWell(
                        onTap: () {
                          _openMainColorPicker();
                        },
                      ),
                    ),
                  ),
                  ListTile(
                    title: Text("Change Button Color"),
                    subtitle: Text("Button Color for the appearance of app"),
                    trailing: CircleAvatar(
                      backgroundColor: color.buttonColor,
                      child: InkWell(
                        onTap: () {
                          _openButtonColorPicker();
                        },
                      ),
                    ),
                  ),
                  ListTile(
                    title: Text("Change Icon Color"),
                    subtitle: Text("Icon Color for the appearance of app"),
                    trailing: CircleAvatar(
                      backgroundColor: color.iconColor,
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
