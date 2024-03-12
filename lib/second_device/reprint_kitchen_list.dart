import 'dart:convert';
import 'dart:io';

import 'package:another_flushbar/flushbar.dart';
import 'package:assets_audio_player/assets_audio_player.dart';
import 'package:flutter/material.dart';
import 'package:pos_system/notifier/fail_print_notifier.dart';
import 'package:pos_system/object/printer.dart';
import 'package:pos_system/second_device/server.dart';
import 'package:provider/provider.dart';

import '../main.dart';
import '../object/order_detail.dart';
import '../object/print_receipt.dart';
import '../translation/AppLocalizations.dart';

class ReprintKitchenList {
  FailPrintModel _failPrintModel = FailPrintModel.instance;
  List<OrderDetail> selectedList = [];
  BuildContext _context = MyApp.navigatorKey.currentContext!;
  PrintReceipt printReceipt = PrintReceipt();
  String flushbarStatus = '';

 void printFailKitchenList(List<OrderDetail> reprintList) async {
    if(_failPrintModel.failedPrintOrderDetail.isNotEmpty){
      //remove all unselected sub-pos order detail
      _failPrintModel.removeOrderDetailWithList(reprintList.where((e) => e.isSelected == false).toList());
      //group all selected sub-pos order detail
      selectedList.addAll(reprintList.where((e) => e.isSelected == true).toList());
      //reprint process
      List<Printer> printerList = await printReceipt.readAllPrinters();
      List<OrderDetail> returnData = await printReceipt.reprintKitchenList(printerList, reprintList: selectedList);
      if (returnData.isNotEmpty) {
        splitOrderDetail(returnData);
        showFlushBar();
        playSound();
        Future.delayed(Duration(seconds: 3), () {
          print("status change: ${flushbarStatus}");
          if(flushbarStatus != "FlushbarStatus.IS_HIDING" && flushbarStatus != "FlushbarStatus.DISMISSED")
            playSound();
        });

      } else {
        //remove all success printed failed order detail
        _failPrintModel.removeOrderDetailWithList(reprintList);
      }
    }
  }

  splitOrderDetail(List<OrderDetail> returnData){
    print("return data: ${returnData.length}");
    Map<String, List<OrderDetail>> groupedOrder = groupOrder(returnData);
    List<String> keyList = groupedOrder.keys.toList();
    for(int i = 0; i < keyList.length; i++){
      print("ip address: ${keyList[i]}");
      print("group order list: ${groupedOrder[keyList[i]]}");
      sendFailPrintOrderDetail(address: keyList[i], failList: groupedOrder[keyList[i]]);
    }
  }

  sendFailPrintOrderDetail({String? address, List<OrderDetail>? failList}){
    Socket client = Server.instance.clientList.firstWhere((e) => e.remoteAddress.address == address);
    Map<String, dynamic>? result = {'status': '1', 'action': '0', 'failedPrintOrderDetail': failList};
    client.write("${jsonEncode(result)}\n");
  }

  Map<String, List<OrderDetail>> groupOrder(List<OrderDetail> returnData) {
    Map<String, List<OrderDetail>> groupedOrderDetails = {};
    for (OrderDetail orderItem in returnData) {
      String cardID = '';
      // if(getOrderNumber(orderItem) != '') {
      //   cardID = getOrderNumber(orderItem);
      // } else
      // if(getTableNumber(orderItem) != '') {
      //   cardID = getTableNumber(orderItem);
      // }
      // else {
      //   cardID = orderItem.order_cache_key.toString().replaceAll("[", "").replaceAll("]", "");
      // }
      cardID = getIpAddress(orderItem);
      if (groupedOrderDetails.containsKey(cardID)) {
        groupedOrderDetails[cardID]!.add(orderItem);
      } else {
        groupedOrderDetails[cardID] = [orderItem];
      }
    }
    return groupedOrderDetails;
  }

  String getIpAddress(OrderDetail orderDetail){
    return orderDetail.failPrintBatch!.split("-").last;
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