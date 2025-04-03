import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pos_system/object/cancel_receipt.dart';

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
      print($e);
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

  static formatReportDate(date) {
    try {
      final dateFormat = DateFormat("dd/MM/yyyy hh:mm:ss a");
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

  static toColor(String hex) {
    var hexColor = hex.replaceAll("#", "");
    if (hexColor.length == 6) {
      hexColor = "FF$hexColor";
    }
    if (hexColor.length == 8) {
      return Color(int.parse("0x$hexColor"));
    }
  }

  static to2Decimal(double value){
    double _round = double.parse(value.toStringAsFixed(1)) - double.parse(value.toStringAsFixed(2));
    if (_round.toStringAsFixed(2) != '0.05' && _round.toStringAsFixed(2) != '-0.05') {
       _round;
    } else {
      _round = 0.0;
    }

    if (_round == 0.0) {
      return value.toStringAsFixed(2);
    } else {
      return value.toStringAsFixed(1) + '0';
    }
  }

  static roundToNearestFiveSen(double amount) {
    const fiveSen = 0.05;

    double remainder = amount % fiveSen;

    if (remainder < fiveSen / 2) {
      // Round down
      return (amount - remainder);
    } else {
      // Round up
      return (amount + (fiveSen - remainder));
    }
  }

  static formatPaymentAmount(double amount) {
    // Create a NumberFormat instance with two decimals and thousand separators
    NumberFormat format = NumberFormat('#,##0.00', 'en_US');

    return format.format(amount);
  }

  static shortHashString({hashCode}){
    var hash2 = DateTime.now().hashCode.toUnsigned(20).toRadixString(16).padLeft(7, '0');
    return shortHash(hashCode).toString()+hash2.toString();
  }

  static String dbCurrentDateTimeFormat(){
    final DateFormat dateFormat = DateFormat("yyyy-MM-dd HH:mm:ss");
    return dateFormat.format(DateTime.now());
  }

  static CancelReceipt defaultCancelReceiptLayout(){
    return CancelReceipt(
        product_name_font_size: 0,
        other_font_size: 0,
        show_product_sku: 0,
        show_product_price: 0
    );
  }

  static Future<String?> getAndroidVersion() async {
    if (Platform.isAndroid) {
      final DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
      final AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
      return androidInfo.version.release;
    }
    return null;
  }

}
