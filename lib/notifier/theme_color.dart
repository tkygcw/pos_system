import 'package:flutter/material.dart';

class ThemeColor extends ChangeNotifier {
  ThemeColor() {
    initialLoad();
  }

  Color _backgroundColor = Color(0xff0c1f32);
  Color _buttonColor = Color(0xff3a5fb4);
  Color _iconColor = Color(0xffffffff);

  Color get backgroundColor => _backgroundColor;

  Color get buttonColor => _buttonColor;

  Color get iconColor => _iconColor;

  void initialLoad() async {
    notifyListeners();
  }

  void changeColor() async {
    notifyListeners();
  }
}
