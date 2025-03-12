import 'dart:convert';
import 'dart:typed_data';

import 'package:f_logs/model/flog/flog.dart';
import 'package:flutter_usb_printer/flutter_usb_printer.dart';
import 'package:esc_pos_printer/esc_pos_printer.dart';
import 'package:esc_pos_utils/esc_pos_utils.dart';
import 'package:pos_system/fragment/dynamic_qr/dynamic_qr_layout.dart';
import 'package:pos_system/fragment/printing_layout/usb_print.dart';
import 'package:pos_system/object/dynamic_qr.dart';
import 'package:print_bluetooth_thermal/print_bluetooth_thermal.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../database/pos_database.dart';
import '../../../object/printer.dart';
import '../../../object/table.dart';

class PrintDynamicQr {
  USBPrintFunction _usbPrintFunction = USBPrintFunction.instance;
  FlutterUsbPrinter flutterUsbPrinter = FlutterUsbPrinter();
  DynamicQrLayout layout = DynamicQrLayout();
  Duration duration = Duration(seconds: 1);
  List<Printer> cashierPrinter = [];

  Future<void> readCashierPrinter() async {
    List<Printer> data = await PosDatabase.instance.readAllBranchPrinter();
    cashierPrinter = data.where((e) => e.is_counter == 1 && e.printer_status == 1).toList();
  }

  printDynamicQR({required PosTable table}) async {
    try{
      if(cashierPrinter.isNotEmpty){
        for(final printers in cashierPrinter){
          var printerDetail = jsonDecode(printers.value!);
          if (printers.type == 0) {
            //print USB
            if(printers.paper_size == 0){
              var data = await layout.print80mmFormat(true, posTable: table);
              bool? isConnected = await _usbPrintFunction.connect(printerDetail: printerDetail);
              if (isConnected == true) {
                await _usbPrintFunction.printReceipt(data);
              }
            } else {
              var data = await layout.print58mmFormat(true, posTable: table);
              bool? isConnected = await _usbPrintFunction.connect(printerDetail: printerDetail);
              if (isConnected == true) {
                await _usbPrintFunction.printReceipt(data);
              }
            }
          } else if(printers.type == 1) {
            if(printers.paper_size == 0){
              final profile = await CapabilityProfile.load();
              final printer = NetworkPrinter(PaperSize.mm80, profile);
              final PosPrintResult res = await printer.connect(printerDetail, port: 9100, timeout: duration);
              if (res == PosPrintResult.success) {
                await layout.print80mmFormat(false, value: printer, posTable: table);
                printer.disconnect();
              }
            } else {
              final profile = await CapabilityProfile.load();
              final printer = NetworkPrinter(PaperSize.mm58, profile);
              final PosPrintResult res = await printer.connect(printerDetail, port: 9100, timeout: duration);
              if (res == PosPrintResult.success) {
                await layout.print58mmFormat(false, value: printer, posTable: table);
                printer.disconnect();
              }
            }
          } else {
            bool res = await bluetoothPrinterConnect(printerDetail);
            if(printers.paper_size == 0){
              if (res) {
                var data = Uint8List.fromList(await layout.print80mmFormat(true, posTable: table));
                await PrintBluetoothThermal.writeBytes(data.toList());
              }
            } else {
              if (res) {
                var data = Uint8List.fromList(await layout.print58mmFormat(true, posTable: table));
                await PrintBluetoothThermal.writeBytes(data.toList());
              }
            }
          }
        }
      }
    }catch(e){
      FLog.error(
        className: "print_dynamic_qr",
        text: "printDynamicQR error",
        exception: "$e",
      );
    }
  }

  testPrintDynamicQR({required DynamicQR qrLayout, required String paperSize}) async {
    if(cashierPrinter.isNotEmpty){
      for(final printers in cashierPrinter){
        var printerDetail = jsonDecode(printers.value!);
        if (printers.type == 0) {
          if(paperSize == '80'){
            var bytes = await layout.testPrint80mmFormat(true, dynamicQR: qrLayout);
            await _usbPrintFunction.connect(printerDetail: printerDetail);
            await _usbPrintFunction.printReceipt(bytes);
            // var data = Uint8List.fromList(await layout.testPrint80mmFormat(true, dynamicQR: qrLayout));
            // bool? isConnected = await flutterUsbPrinter.connect(int.parse(printerDetail['vendorId']), int.parse(printerDetail['productId']));
            // if (isConnected == true) {
            //   await flutterUsbPrinter.write(data);
            // }
          } else {
            var bytes = await layout.testPrint58mmFormat(true, dynamicQR: qrLayout);
            await _usbPrintFunction.connect(printerDetail: printerDetail);
            await _usbPrintFunction.printReceipt(bytes);
            // var data = Uint8List.fromList(await layout.testPrint58mmFormat(true, dynamicQR: qrLayout));
            // bool? isConnected = await flutterUsbPrinter.connect(int.parse(printerDetail['vendorId']), int.parse(printerDetail['productId']));
            // if (isConnected == true) {
            //   await flutterUsbPrinter.write(data);
            // }
          }
        } else {
          if(paperSize == '80'){
            final profile = await CapabilityProfile.load();
            final printer = NetworkPrinter(PaperSize.mm80, profile);
            final PosPrintResult res = await printer.connect(printerDetail, port: 9100, timeout: duration);
            if (res == PosPrintResult.success) {
              await layout.testPrint80mmFormat(false, value: printer, dynamicQR: qrLayout);
              printer.disconnect();
            }
          } else {
            final profile = await CapabilityProfile.load();
            final printer = NetworkPrinter(PaperSize.mm58, profile);
            final PosPrintResult res = await printer.connect(printerDetail, port: 9100, timeout: duration);
            if (res == PosPrintResult.success) {
              await layout.testPrint58mmFormat(false, value: printer, dynamicQR: qrLayout);
              printer.disconnect();
            }
          }
        }
      }
    }
  }

  static Future<bool> bluetoothPrinterConnect(String mac) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? lastBtConnection = prefs.getString('lastBtConnection');
    bool result = false;
    bool connectionStatus = await PrintBluetoothThermal.connectionStatus;
    if (connectionStatus) {
      if (lastBtConnection != mac) {
        await PrintBluetoothThermal.disconnect;
        result = await PrintBluetoothThermal.connect(macPrinterAddress: mac);
        if(result) {
          await prefs.setString('lastBtConnection', mac);
        }
      } else {
        result = true;
      }
    } else {
      result = await PrintBluetoothThermal.connect(macPrinterAddress: mac);
      if(result) {
        await prefs.setString('lastBtConnection', mac);
      }
    }
    return result;
  }
}