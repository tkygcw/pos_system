import 'package:another_flushbar/flushbar.dart';
import 'package:assets_audio_player/assets_audio_player.dart';
import 'package:flutter/material.dart';
import 'package:pos_system/notifier/fail_print_notifier.dart';
import 'package:pos_system/object/printer.dart';

import '../main.dart';
import '../object/order_detail.dart';
import '../object/print_receipt.dart';
import '../translation/AppLocalizations.dart';

class ReprintKitchenList {
  FailPrintModel _failPrintModel = FailPrintModel.instance;
  BuildContext _context = MyApp.navigatorKey.currentContext!;
  PrintReceipt printReceipt = PrintReceipt();
  String flushbarStatus = '';

  Future<List<OrderDetail>> printFailKitchenList(List<OrderDetail> reprintList) async {
    _failPrintModel.removeAllFailedOrderDetail();
    List<Printer> printerList = await printReceipt.readAllPrinters();
    List<OrderDetail> returnData = await printReceipt.reprintKitchenList(printerList, reprintList: reprintList);
    if (returnData.isNotEmpty) {
      _failPrintModel.addAllFailedOrderDetail(orderDetailList: returnData);
      playSound();
      Future.delayed(Duration(seconds: 3), () {
        print("status change: ${flushbarStatus}");
        if(flushbarStatus != "FlushbarStatus.IS_HIDING" && flushbarStatus != "FlushbarStatus.DISMISSED")
          playSound();
      });

    } else {
      _failPrintModel.removeAllFailedOrderDetail();
    }
    return returnData;
  }

  showFlushBar(){
    Flushbar(
      icon: Icon(Icons.error, size: 32, color: Colors.white),
      shouldIconPulse: false,
      title: "${AppLocalizations.of(_context)?.translate('error')}${AppLocalizations.of(_context)?.translate('kitchen_printer_timeout')}",
      message: "${AppLocalizations.of(_context)?.translate('please_try_again_later')}",
      duration: Duration(seconds: 5),
      backgroundColor: Colors.red,
      messageColor: Colors.white,
      flushbarPosition: FlushbarPosition.TOP,
      maxWidth: 350,
      margin: EdgeInsets.all(8),
      borderRadius: BorderRadius.circular(8),
      padding: EdgeInsets.fromLTRB(40, 20, 40, 20),
      onTap: (flushbar) {
        flushbar.dismiss(true);
      },
      onStatusChanged: (status) {
        flushbarStatus = status.toString();
        print("onStatusChanged: ${status}");
      },
    )..show(_context);
  }

  playSound() {
    try {
      final assetsAudioPlayer = AssetsAudioPlayer();
      assetsAudioPlayer.open(
        Audio("audio/review.mp3"),
      );
    } catch (e) {
      print("Play Sound Error: ${e}");
    }
  }
}