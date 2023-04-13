import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../translation/AppLocalizations.dart';

class Utils {
  static getText(context, message) {
    return AppLocalizations.of(context)!.translate(message);
  }

  /*
  * remove double's decimal if behind is .00 / .0
  * */
  static numDetector(String value) {
    try {
      List split = value.split('.');
      //if is decimal value
      if (split.length > 1) {
        //if value after dot (.xx) is smaller than 0
        if (int.parse(split[1]) <= 0) {
          return split[0];
        } else
          return double.parse(value).toStringAsFixed(2);
      } else
        return value;
    } catch (e) {
      return value;
    }
  }

  static int convertToInt(value) {
    try {
      return value is int ? value : int.parse(value);
    } catch ($e) {
      return 0;
    }
  }

  static String convertTo2Dec(value) {
    try {
      return double.parse(value).toStringAsFixed(2);
    } catch ($e) {
      return '0.00';
    }
  }

  static MaterialColor white = const MaterialColor(
    0xFFFFFFFF,
    const <int, Color>{
      50: const Color(0xFFFFFFFF),
      100: const Color(0xFFFFFFFF),
      200: const Color(0xFFFFFFFF),
      300: const Color(0xFFFFFFFF),
      400: const Color(0xFFFFFFFF),
      500: const Color(0xFFFFFFFF),
      600: const Color(0xFFFFFFFF),
      700: const Color(0xFFFFFFFF),
      800: const Color(0xFFFFFFFF),
      900: const Color(0xFFFFFFFF),
    },
  );

  static formatDate(date) {
    try {
      final dateFormat = DateFormat("dd/MM/yy hh:mm a");
      DateTime todayDate = DateTime.parse(date);
      return dateFormat.format(todayDate).toString();
    } catch (e) {
      return '';
    }
  }

  static formatProductVariant(String variant){
    try{
      String result = '';
      result = variant.toString().replaceAll("|", ",").trim();
      return result;
    } catch(e){
      return '';
    }
  }
}
