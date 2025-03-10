import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_usb_printer/flutter_usb_printer.dart';
import 'package:thermal_printer/thermal_printer.dart';

class USBPrintFunction {

  USBPrintFunction._();

  static USBPrintFunction _instance = USBPrintFunction._();

  static USBPrintFunction get instance => _instance;

  FlutterUsbPrinter _flutterUsbPrinter = FlutterUsbPrinter();
  var _printerManager = PrinterManager.instance;
  final PrinterType _printerType = PrinterType.usb;

  Future<bool?> connect({required printerDetail}) async {
    bool? status = true;
    if(Platform.isWindows){
      status = await _printerManager.connect(
        type: _printerType,
        model: UsbPrinterInput(
          name: printerDetail['name'],
          productId: printerDetail['productId'],
          vendorId: printerDetail['vendorId'],
        ),
      );
    } else {
      status = await _flutterUsbPrinter.connect(int.parse(printerDetail['vendorId']), int.parse(printerDetail['productId']));
    }
    return status;
  }

  Future<void> printReceipt(List<int> bytes) async {
    if(Platform.isWindows){
      await _printerManager.send(type: _printerType, bytes: bytes);
    } else {
      var data = Uint8List.fromList(bytes);
      await _flutterUsbPrinter.write(data);
    }
  }

  Future<void> disconnect() async {
    if(Platform.isWindows){
      await _printerManager.disconnect(type: _printerType);
    } else {
      await _flutterUsbPrinter.close();
    }
  }
}