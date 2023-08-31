import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SharePreferences {
  read(String key) async {
    try {
      var prefs;
      prefs = await SharedPreferences.getInstance();
      var data = await prefs.getString(key);
      if (data != null)
        return json.decode(data);
      else
        return null;
    } catch (e) {
      debugPrint('Read Data Error: key = ${key} ${e}');
      return null;
    }
  }

  save(String key, value) async {
    try {
      var prefs;

      prefs = await SharedPreferences.getInstance();
      await prefs.setString(key, json.encode(value));
    } catch (e) {
      debugPrint('Saving Data Error: $e');
    }
  }

  remove(String key) async {
    try {
      var prefs;
      prefs = await SharedPreferences.getInstance();
      await prefs.remove(key);
    } catch (e) {
      debugPrint('Remove Data Error: $e');
    }
  }

  clear() async {
    try {
      var prefs;
      prefs = await SharedPreferences.getInstance();
      await prefs.clear();
    } catch (e) {
      debugPrint('Clear Data Error: $e');
    }
  }
}
