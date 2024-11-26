import 'package:flutter/services.dart';

class IminLib {
  static const MethodChannel channel = MethodChannel('com.example.pos_system/lcdDisplay');

  checkLcdScreen() async {
    try{
      await channel.invokeMethod("sdkInit");
      return 1;
    }catch(e){
      print('no lcd screen: $e');
      return 0;
    }
  }

  initLcd() async {
    try{
      final byteData = await rootBundle.load("drawable/logo.png");
      final bytes = byteData.buffer.asUint8List();
      var status = await channel.invokeMethod("sendImg", bytes);
      print('status: ${status}');
    } catch(e){
      return;
    }
  }

  sendImage() async {
    final byteData = await rootBundle.load("drawable/tableQr.png");
    final bytes = byteData.buffer.asUint8List();
    await channel.invokeMethod("sendImg", bytes);
  }

  clearScreen() async {
    await channel.invokeMethod("clear");
  }

  openCashDrawer() async {
    await channel.invokeMethod("cashBox");
  }
}