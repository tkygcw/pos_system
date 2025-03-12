import 'dart:convert';
import 'dart:typed_data';

import 'package:esc_pos_printer/esc_pos_printer.dart';
import 'package:esc_pos_utils/esc_pos_utils.dart';
import 'package:flutter_usb_printer/flutter_usb_printer.dart';
import 'package:print_bluetooth_thermal/print_bluetooth_thermal.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../database/pos_database.dart';
import '../../../object/printer.dart';
import '../../printing_layout/usb_print.dart';

class PrintReportReceipt {
  USBPrintFunction _usbPrintFunction = USBPrintFunction.instance;
  FlutterUsbPrinter flutterUsbPrinter = FlutterUsbPrinter();
  Duration duration = Duration(seconds: 1);
  List<Printer> cashierPrinterList = [];

  readCashierPrinter() async {
    List<Printer> data = await PosDatabase.instance.readAllBranchPrinter();
    cashierPrinterList = data.where((e) => e.is_counter == 1 && e.printer_status == 1).toList();
  }

  printReceipt({layout}) async {
    if(cashierPrinterList.isNotEmpty){
      for(final printers in cashierPrinterList){
        var printerDetail = jsonDecode(printers.value!);
        if (printers.type == 0) {
          if(printers.paper_size == 0){
            var data = await layout.print80mmFormat(true);
            bool? isConnected = await _usbPrintFunction.connect(printerDetail: printerDetail);
            if (isConnected == true) {
              await _usbPrintFunction.printReceipt(data);
            }
          } else {
            var data = await layout.print58mmFormat(true);
            bool? isConnected = await _usbPrintFunction.connect(printerDetail: printerDetail);
            if (isConnected == true) {
              await _usbPrintFunction.printReceipt(data);
            }
          }
        } else if(printers.type == 1){
          if(printers.paper_size == 0){
            final profile = await CapabilityProfile.load();
            final printer = NetworkPrinter(PaperSize.mm80, profile);
            final PosPrintResult res = await printer.connect(printerDetail, port: 9100, timeout: duration);
            if (res == PosPrintResult.success) {
              await layout.print80mmFormat(false, value: printer);
              printer.disconnect();
            }
          } else {
            final profile = await CapabilityProfile.load();
            final printer = NetworkPrinter(PaperSize.mm58, profile);
            final PosPrintResult res = await printer.connect(printerDetail, port: 9100, timeout: duration);
            if (res == PosPrintResult.success) {
              await layout.print58mmFormat(false, value: printer);
              printer.disconnect();
            }
          }
        } else {
          bool res = await bluetoothPrinterConnect(printerDetail);
          if(printers.paper_size == 0){
            if (res) {
              await PrintBluetoothThermal.writeBytes(await layout.print80mmFormat(true));
            }
          } else {
            if (res) {
              await PrintBluetoothThermal.writeBytes(await layout.print58mmFormat(true));
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