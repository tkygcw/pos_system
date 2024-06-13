import 'dart:convert';
import 'dart:typed_data';

import 'package:esc_pos_printer/esc_pos_printer.dart';
import 'package:esc_pos_utils/esc_pos_utils.dart';
import 'package:flutter_usb_printer/flutter_usb_printer.dart';
import 'package:pos_system/fragment/report/report_receipt/layout/category_layout.dart';
import 'package:pos_system/fragment/report/report_receipt/layout/product_layout.dart';

import '../../../database/pos_database.dart';
import '../../../object/printer.dart';

class PrintReportReceipt {
  FlutterUsbPrinter flutterUsbPrinter = FlutterUsbPrinter();
  Duration duration = Duration(seconds: 1);
  List<Printer> cashierPrinterList = [];


  readCashierPrinter() async {
    List<Printer> data = await PosDatabase.instance.readAllBranchPrinter();
    cashierPrinterList = data.where((e) => e.is_counter == 1 && e.printer_status == 1).toList();
  }

  printProductReceipt() async {
    if(cashierPrinterList.isNotEmpty){
      for(final printers in cashierPrinterList){
        var printerDetail = jsonDecode(printers.value!);
        if (printers.type == 0) {
          if(printers.paper_size == 0){
            var data = Uint8List.fromList(await ProductReceiptLayout().print80mmFormat(true));
            bool? isConnected = await flutterUsbPrinter.connect(int.parse(printerDetail['vendorId']), int.parse(printerDetail['productId']));
            if (isConnected == true) {
              await flutterUsbPrinter.write(data);
            }
          } else {
            var data = Uint8List.fromList(await ProductReceiptLayout().print58mmFormat(true));
            bool? isConnected = await flutterUsbPrinter.connect(int.parse(printerDetail['vendorId']), int.parse(printerDetail['productId']));
            if (isConnected == true) {
              await flutterUsbPrinter.write(data);
            }
          }
        } else {
          if(printers.paper_size == 0){
            final profile = await CapabilityProfile.load();
            final printer = NetworkPrinter(PaperSize.mm80, profile);
            final PosPrintResult res = await printer.connect(printerDetail, port: 9100, timeout: duration);
            if (res == PosPrintResult.success) {
              await ProductReceiptLayout().print80mmFormat(false, value: printer);
              printer.disconnect();
            }
          } else {
            final profile = await CapabilityProfile.load();
            final printer = NetworkPrinter(PaperSize.mm58, profile);
            final PosPrintResult res = await printer.connect(printerDetail, port: 9100, timeout: duration);
            if (res == PosPrintResult.success) {
              await ProductReceiptLayout().print58mmFormat(false, value: printer);
              printer.disconnect();
            }
          }
        }
      }
    }
  }

  printCategoryReceipt() async {
    if(cashierPrinterList.isNotEmpty){
      for(final printers in cashierPrinterList){
        var printerDetail = jsonDecode(printers.value!);
        if (printers.type == 0) {
          if(printers.paper_size == 0){
            var data = Uint8List.fromList(await CategoryReceiptLayout().print80mmFormat(true));
            bool? isConnected = await flutterUsbPrinter.connect(int.parse(printerDetail['vendorId']), int.parse(printerDetail['productId']));
            if (isConnected == true) {
              await flutterUsbPrinter.write(data);
            }
          } else {
            var data = Uint8List.fromList(await CategoryReceiptLayout().print58mmFormat(true));
            bool? isConnected = await flutterUsbPrinter.connect(int.parse(printerDetail['vendorId']), int.parse(printerDetail['productId']));
            if (isConnected == true) {
              await flutterUsbPrinter.write(data);
            }
          }
        } else {
          if(printers.paper_size == 0){
            final profile = await CapabilityProfile.load();
            final printer = NetworkPrinter(PaperSize.mm80, profile);
            final PosPrintResult res = await printer.connect(printerDetail, port: 9100, timeout: duration);
            if (res == PosPrintResult.success) {
              await CategoryReceiptLayout().print80mmFormat(false, value: printer);
              printer.disconnect();
            }
          } else {
            final profile = await CapabilityProfile.load();
            final printer = NetworkPrinter(PaperSize.mm58, profile);
            final PosPrintResult res = await printer.connect(printerDetail, port: 9100, timeout: duration);
            if (res == PosPrintResult.success) {
              await CategoryReceiptLayout().print58mmFormat(false, value: printer);
              printer.disconnect();
            }
          }
        }
      }
    }
  }
}