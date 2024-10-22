import 'dart:convert';
import 'dart:typed_data';
import 'package:assets_audio_player/assets_audio_player.dart';
import 'package:esc_pos_printer/esc_pos_printer.dart';
import 'package:esc_pos_utils/esc_pos_utils.dart';
import 'package:f_logs/model/flog/flog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_usb_printer/flutter_usb_printer.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:pos_system/main.dart';
import 'package:pos_system/object/checklist.dart';
import 'package:pos_system/object/kitchen_list.dart';
import 'package:pos_system/object/printer.dart';
import 'package:pos_system/object/printer_link_category.dart';
import 'package:pos_system/object/receipt.dart';
import 'package:pos_system/fragment/printing_layout/receipt_layout.dart';
import 'package:pos_system/object/settlement.dart';
import 'package:pos_system/object/table.dart';
import 'package:pos_system/object/table_use_detail.dart';
import 'package:print_bluetooth_thermal/print_bluetooth_thermal.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../database/pos_database.dart';
import 'bill/layout.dart';
import 'bill/preview_layout.dart';
import 'checklist/layout.dart';
import 'kitchenlist/kitchen_combine_layout.dart';
import 'kitchenlist/kitchen_default_layout.dart';
import 'product_ticket/layout.dart';
import 'reprint/checklist/layout.dart';
import '../../notifier/cart_notifier.dart';
import '../../translation/AppLocalizations.dart';
import '../../object/cart_product.dart';
import '../../object/order_cache.dart';
import '../../object/order_detail.dart';
import '../../object/order_modifier_detail.dart';

class PrintReceipt{
  /**
   * printStatus = 0, ok
   * printStatus = 1, printer not connected
   * printStatus = 2, timeout
   * printStatus = 3, no printer
   * printStatus = 4, no active printer added
   * printStatus = 5, printing error
   */
  FlutterUsbPrinter flutterUsbPrinter = FlutterUsbPrinter();
  Duration duration = Duration(seconds: 1);
  double combineListTotal = 0;

  getDeviceList() async {
    List<Map<String, dynamic>> results = [];
    results = await FlutterUsbPrinter.getUSBDeviceList();
    if(results.isNotEmpty){
      return jsonEncode(results[0]);
    } else {
      return null;
    }
  }

  readAllPrinters() async {
    List<Printer> printerList = [];
    List<Printer> data = await PosDatabase.instance.readAllBranchPrinter();
    printerList = data;
    return printerList;
  }

  selfTest(List<Printer> printerList) async {
    try {
      // for usb printer
      for (int i = 0; i < printerList.length; i++) {
        var printerDetail = jsonDecode(printerList[i].value!);
        if(printerList[i].paper_size == 0){
          var data = Uint8List.fromList(await ReceiptLayout().testTicket80mm(true));
          bool? isConnected = await flutterUsbPrinter.connect(
              int.parse(printerDetail['vendorId']),
              int.parse(printerDetail['productId']));
          if (isConnected == true) {
            await flutterUsbPrinter.write(data);
          } else {
            print('not connected');
          }
        } else if(printerList[i].paper_size == 1){
          print('print 58mm');
          var data = Uint8List.fromList(
              await ReceiptLayout().testTicket58mm(true));
          bool? isConnected = await flutterUsbPrinter.connect(
              int.parse(printerDetail['vendorId']),
              int.parse(printerDetail['productId']));
          if (isConnected == true) {
            await flutterUsbPrinter.write(data);
          } else {
            print('not connected');
          }
        } else {
          print('print 35mm');
          var data = Uint8List.fromList(
              await ReceiptLayout().testTicket35mm(true));
          bool? isConnected = await flutterUsbPrinter.connect(
              int.parse(printerDetail['vendorId']),
              int.parse(printerDetail['productId']));
          if (isConnected == true) {
            await flutterUsbPrinter.write(data);
          } else {
            print('not connected');
          }
        }
      }

    } catch (e) {
      print('error $e');
      print('Printer Connection Error');
      //response = 'Failed to get platform version.';
    }
  }

  cashDrawer({required printerList}) async {
    try{
      int printStatus = 0;
      List<Printer> cashierPrinterList = printerList.where((item) => item.printer_status == 1 && item.is_counter == 1).toList();
      if(cashierPrinterList.isNotEmpty){
        for (int i = 0; i < cashierPrinterList.length; i++) {
          if (cashierPrinterList[i].type == 0) {
            ReceiptLayout().openCashDrawer(isUSB: true);
            printStatus = 0;
          } else if(cashierPrinterList[i].type == 1) {
            var printerDetail = jsonDecode(cashierPrinterList[i].value!);
            final profile = await CapabilityProfile.load();
            final printer = NetworkPrinter(PaperSize.mm80, profile);
            final PosPrintResult res = await printer.connect(printerDetail, port: 9100, timeout: duration);
            if (res == PosPrintResult.success) {
              await ReceiptLayout().openCashDrawer(isUSB: false, value: printer);
              printer.disconnect();
              printStatus = 0;
            } else if(res == PosPrintResult.timeout){
              printStatus = 2;
            } else {
              printStatus = 1;
            }
          } else {
            var printerDetail = jsonDecode(cashierPrinterList[i].value!);
            bool res = await bluetoothPrinterConnect(printerDetail);
            if (res) {
              await PrintBluetoothThermal.writeBytes(await ReceiptLayout().openCashDrawer(isUSB: true));
              printStatus = 0;
            } else {
              printStatus = 1;
            }
          }
        }
      } else {
        printStatus = 4;
      }
      return printStatus;
    }catch(e){
      print('Open Cash Drawer Error: ${e}');
      FLog.error(
        className: "print_receipt",
        text: "open cash drawer error",
        exception: "$e",
      );
      return 1;
    }
  }

  printTestPrintChecklist(List<Printer> cashierPrinter, Checklist checklistLayout, String paperSize) async {
    try{
      for (int i = 0; i < cashierPrinter.length; i++) {
        var printerDetail = jsonDecode(cashierPrinter[i].value!);
        if (cashierPrinter[i].printer_status == 1) {
          if (cashierPrinter[i].type == 0) {
            if (paperSize == '80') {
              //print 80mm
              var data = Uint8List.fromList(await ReceiptLayout().printTestCheckList80mm(true, checklistLayout: checklistLayout));
              bool? isConnected = await flutterUsbPrinter.connect(
                  int.parse(printerDetail['vendorId']), int.parse(printerDetail['productId']));
              if (isConnected == true) {
                await flutterUsbPrinter.write(data);
              } else {
              }
            } else {
              //print 58mm
              var data = Uint8List.fromList(
                  await ReceiptLayout().printTestCheckList58mm(true, checklistLayout: checklistLayout));
              bool? isConnected = await flutterUsbPrinter.connect(
                  int.parse(printerDetail['vendorId']), int.parse(printerDetail['productId']));
              if (isConnected == true) {
                await flutterUsbPrinter.write(data);
              } else {
              }
            }
          } else if(cashierPrinter[i].type == 1){
            if (paperSize == '80') {
              //print LAN 80mm
              final profile = await CapabilityProfile.load();
              final printer = NetworkPrinter(PaperSize.mm80, profile);
              final PosPrintResult res = await printer.connect(printerDetail, port: 9100);

              if (res == PosPrintResult.success) {
                await ReceiptLayout().printTestCheckList80mm(false, value: printer, checklistLayout: checklistLayout);
                printer.disconnect();
              } else {
              }
            } else {
              //print LAN 58mm
              final profile = await CapabilityProfile.load();
              final printer = NetworkPrinter(PaperSize.mm58, profile);
              final PosPrintResult res = await printer.connect(printerDetail, port: 9100);

              if (res == PosPrintResult.success) {
                await ReceiptLayout().printTestCheckList58mm(false, value: printer, checklistLayout: checklistLayout);
                printer.disconnect();
              } else {
              }
            }
          } else {
            bool res = await bluetoothPrinterConnect(printerDetail);
            if (paperSize == '80') {
              //print bluetooth 80mm
              if (res) {
                await PrintBluetoothThermal.writeBytes(await ReceiptLayout().printTestCheckList80mm(true, checklistLayout: checklistLayout));
              } else {
              }
            } else {
              //print bluetooth 58mm
              if (res) {
                await PrintBluetoothThermal.writeBytes(await ReceiptLayout().printTestCheckList58mm(true, checklistLayout: checklistLayout));
              } else {
              }
            }
          }
        }

      }
    } catch(e){
      print("test print fail: ${e}");
    }
  }

  printTestPrintKitchenList(List<Printer> kitchenPrinter, KitchenList KitchenListLayout, String paperSize) async {
    try{
      for (int i = 0; i < kitchenPrinter.length; i++) {
        var printerDetail = jsonDecode(kitchenPrinter[i].value!);
        if (kitchenPrinter[i].type == 0) {
          if (paperSize == '80') {
            //print 80mm
            var data = Uint8List.fromList(await ReceiptLayout().printTestKitchenList80mm(true, KitchenListLayout: KitchenListLayout));
            bool? isConnected = await flutterUsbPrinter.connect(
                int.parse(printerDetail['vendorId']), int.parse(printerDetail['productId']));
            if (isConnected == true) {
              await flutterUsbPrinter.write(data);
            } else {
            }
          } else {
            //print 58mm
            var data = Uint8List.fromList(
                await ReceiptLayout().printTestKitchenList58mm(true, KitchenListLayout: KitchenListLayout));
            bool? isConnected = await flutterUsbPrinter.connect(
                int.parse(printerDetail['vendorId']), int.parse(printerDetail['productId']));
            if (isConnected == true) {
              await flutterUsbPrinter.write(data);
            } else {
            }
          }
        } else if(kitchenPrinter[i].type == 1){
          if (paperSize == '80') {
            //print LAN 80mm
            final profile = await CapabilityProfile.load();
            final printer = NetworkPrinter(PaperSize.mm80, profile);
            final PosPrintResult res = await printer.connect(printerDetail, port: 9100);

            if (res == PosPrintResult.success) {
              await ReceiptLayout().printTestKitchenList80mm(false, value: printer, KitchenListLayout: KitchenListLayout);
              printer.disconnect();
            } else {
            }
          } else {
            //print LAN 58mm
            final profile = await CapabilityProfile.load();
            final printer = NetworkPrinter(PaperSize.mm58, profile);
            final PosPrintResult res = await printer.connect(printerDetail, port: 9100);

            if (res == PosPrintResult.success) {
              await ReceiptLayout().printTestKitchenList58mm(false, value: printer, KitchenListLayout: KitchenListLayout);
              printer.disconnect();
            } else {
            }
          }
        } else {
          bool res = await bluetoothPrinterConnect(printerDetail);
          if (paperSize == '80') {
            //print bluetooth 80mm
            if (res) {
              await PrintBluetoothThermal.writeBytes(await ReceiptLayout().printTestKitchenList80mm(true, KitchenListLayout: KitchenListLayout));
            } else {
            }
          } else {
            //print bluetooth 58mm
            if (res) {
              await PrintBluetoothThermal.writeBytes(await ReceiptLayout().printTestKitchenList58mm(true, KitchenListLayout: KitchenListLayout));
            } else {
            }
          }
        }
      }
    } catch(e){
      print("test print fail: ${e}");
    }
  }

  printTestPrintReceipt(List<Printer> printerList, Receipt receipt, String paperSize, context) async {
    List<Printer> cashierPrinter = printerList.where((item) => item.is_counter == 1 && item.printer_status == 1).toList();
    if(cashierPrinter.isNotEmpty){
      for (int i = 0; i < cashierPrinter.length; i++) {
        var printerDetail = jsonDecode(cashierPrinter[i].value!);
        if (cashierPrinter[i].type == 0) {
          if (paperSize == '80') {
            //print 80mm
            var data = Uint8List.fromList(await ReceiptLayout().printTestReceipt80mm(true, receipt));
            bool? isConnected = await flutterUsbPrinter.connect(
                int.parse(printerDetail['vendorId']), int.parse(printerDetail['productId']));
            if (isConnected == true) {
              await flutterUsbPrinter.write(data);
            } else {
              Fluttertoast.showToast(
                  backgroundColor: Colors.red,
                  msg: "${AppLocalizations.of(context)?.translate('usb_printer_not_connect')}");
            }
          } else {
            //print 58mm
            var data = Uint8List.fromList(
                await ReceiptLayout().printTestReceipt58mm(true, receipt));
            bool? isConnected = await flutterUsbPrinter.connect(
                int.parse(printerDetail['vendorId']), int.parse(printerDetail['productId']));
            if (isConnected == true) {
              await flutterUsbPrinter.write(data);
            } else {
              Fluttertoast.showToast(
                  backgroundColor: Colors.red,
                  msg: "${AppLocalizations.of(context)?.translate('usb_printer_not_connect')}");
            }
          }
        } else if(cashierPrinter[i].type == 1) {
          if (paperSize == '80') {
            //print LAN 80mm
            final profile = await CapabilityProfile.load();
            final printer = NetworkPrinter(PaperSize.mm80, profile);
            final PosPrintResult res = await printer.connect(printerDetail, port: 9100);

            if (res == PosPrintResult.success) {
              await ReceiptLayout().printTestReceipt80mm(false, receipt, value: printer);
              printer.disconnect();
            } else {
              Fluttertoast.showToast(
                  backgroundColor: Colors.red,
                  msg: "${AppLocalizations.of(context)?.translate('lan_printer_not_connect')}");
            }
          } else {
            //print LAN 58mm
            final profile = await CapabilityProfile.load();
            final printer = NetworkPrinter(PaperSize.mm58, profile);
            final PosPrintResult res = await printer.connect(printerDetail, port: 9100);

            if (res == PosPrintResult.success) {
              await ReceiptLayout().printTestReceipt58mm(false, receipt, value: printer);
              printer.disconnect();
            } else {
              Fluttertoast.showToast(
                  backgroundColor: Colors.red,
                  msg: "${AppLocalizations.of(context)?.translate('lan_printer_not_connect')}");
            }
          }
        } else {
          bool res = await bluetoothPrinterConnect(printerDetail);
          if (paperSize == '80') {
            //print bluetooth 80mm
            if (res) {
              await PrintBluetoothThermal.writeBytes(await ReceiptLayout().printTestReceipt80mm(true, receipt));
            } else {
              Fluttertoast.showToast(
                  backgroundColor: Colors.red,
                  msg: "${AppLocalizations.of(context)?.translate('bluetooth_printer_not_connect')}");
            }
          } else {
            //print bluetooth 58mm
            if (res) {
              await PrintBluetoothThermal.writeBytes(await ReceiptLayout().printTestReceipt58mm(true, receipt));
            } else {
              Fluttertoast.showToast(
                  backgroundColor: Colors.red,
                  msg: "${AppLocalizations.of(context)?.translate('bluetooth_printer_not_connect')}");
            }
          }
        }
      }
    } else {
      Fluttertoast.showToast(
          backgroundColor: Colors.red,
          msg: AppLocalizations.of(context)!.translate('no_cashier_printer_added'));
    }
  }

  printPaymentReceiptList(List<Printer> printerList, String orderId, List<PosTable> selectedTableList) async {
    try {
      int printStatus = 0;
      List<Printer> cashierPrinterList = printerList.where((item) => item.printer_status == 1 && item.is_counter == 1).toList();
      if(cashierPrinterList.isEmpty){
        printStatus = 4;
      } else {
        for (int i = 0; i < cashierPrinterList.length; i++) {
          var printerDetail = jsonDecode(cashierPrinterList[i].value!);
          if (cashierPrinterList[i].type == 0) {
            if (cashierPrinterList[i].paper_size == 0) {
              //print 80mm
              var data = Uint8List.fromList(await BillLayout().printReceipt80mm(true, orderId, selectedTableList));
              bool? isConnected = await flutterUsbPrinter.connect(
                  int.parse(printerDetail['vendorId']), int.parse(printerDetail['productId']));
              if (isConnected == true) {
                await flutterUsbPrinter.write(data);
                printStatus = 0;
              } else {
                printStatus = 1;
                // Fluttertoast.showToast(
                //     backgroundColor: Colors.red,
                //     msg: "${AppLocalizations.of(context)?.translate('usb_printer_not_connect')}");
              }
            } else {
              //print 58mm
              var data = Uint8List.fromList(
                  await BillLayout().printReceipt58mm(true, orderId, selectedTableList));
              bool? isConnected = await flutterUsbPrinter.connect(
                  int.parse(printerDetail['vendorId']), int.parse(printerDetail['productId']));
              if (isConnected == true) {
                await flutterUsbPrinter.write(data);
                printStatus = 0;
              } else {
                printStatus = 1;
                // Fluttertoast.showToast(
                //     backgroundColor: Colors.red,
                //     msg: "${AppLocalizations.of(context)?.translate('usb_printer_not_connect')}");
              }
            }
          } else if(cashierPrinterList[i].type == 1) {
            if (cashierPrinterList[i].paper_size == 0) {
              //print LAN 80mm
              final profile = await CapabilityProfile.load();
              final printer = NetworkPrinter(PaperSize.mm80, profile);
              final PosPrintResult res = await printer.connect(printerDetail, port: 9100, timeout: duration);

              if (res == PosPrintResult.success) {
                await BillLayout().printReceipt80mm(false, orderId, selectedTableList, value: printer);
                printer.disconnect();
                printStatus = 0;
              } else if (res == PosPrintResult.timeout){
                printStatus = 2;
              } else {
                printStatus = 1;
              }
            } else {
              //print LAN 58mm
              final profile = await CapabilityProfile.load();
              final printer = NetworkPrinter(PaperSize.mm58, profile);
              final PosPrintResult res = await printer.connect(printerDetail, port: 9100, timeout: duration);

              if (res == PosPrintResult.success) {
                await BillLayout().printReceipt58mm(false, orderId, selectedTableList,value: printer);
                printer.disconnect();
                printStatus = 0;
              } else if (res == PosPrintResult.timeout){
                printStatus = 2;
              } else {
                printStatus = 1;
              }
            }
          } else {
            bool res = await bluetoothPrinterConnect(printerDetail);
            if (cashierPrinterList[i].paper_size == 0) {
              //print bluetooth 80mm
              if (res) {
                await PrintBluetoothThermal.writeBytes(await BillLayout().printReceipt80mm(true, orderId, selectedTableList));
                printStatus = 0;
              } else {
                printStatus = 1;
              }
            } else {
              //print bluetooth 58mm
              if (res) {
                await PrintBluetoothThermal.writeBytes(await BillLayout().printReceipt58mm(true, orderId, selectedTableList));
                printStatus = 0;
              } else {
                printStatus = 1;
              }
            }
          }
        }
      }
      return printStatus;
    } catch (e) {
      print('Printer Connection Error cart: ${e}');
      FLog.error(
        className: "print_receipt",
        text: "print payment receipt list error",
        exception: "$e",
      );
      return 1;
      // Fluttertoast.showToast(
      //     backgroundColor: Colors.red,
      //     msg: "${AppLocalizations.of(context)?.translate('printing_error')}");
    }
  }

  printReviewReceipt(List<Printer> printerList, CartModel cartModel, String orderKey) async {
    try{
      int printStatus = 0;
      List<Printer> cashierPrinterList = printerList.where((item) => item.printer_status == 1 && item.is_counter == 1).toList();
      if(cashierPrinterList.isEmpty){
        printStatus = 4;
      } else {
        for (int i = 0; i < cashierPrinterList.length; i++) {
          var printerDetail = jsonDecode(cashierPrinterList[i].value!);
          if (cashierPrinterList[i].type == 0) {
            if (cashierPrinterList[i].paper_size == 0) {
              //print 80mm
              var data = Uint8List.fromList(
                  await PreviewLayout().printPreviewReceipt80mm(true, cartModel, orderKey));
              bool? isConnected = await flutterUsbPrinter.connect(
                  int.parse(printerDetail['vendorId']), int.parse(printerDetail['productId']));
              if (isConnected == true) {
                await flutterUsbPrinter.write(data);
                printStatus = 0;
              } else {
                printStatus = 1;
                // Fluttertoast.showToast(
                //     backgroundColor: Colors.red,
                //     msg: "${AppLocalizations.of(context)?.translate('usb_printer_not_connect')}");
              }
            } else {
              //print 58mm
              var data = Uint8List.fromList(
                  await PreviewLayout().printPreviewReceipt58mm(true, cartModel, orderKey));
              bool? isConnected = await flutterUsbPrinter.connect(
                  int.parse(printerDetail['vendorId']), int.parse(printerDetail['productId']));
              if (isConnected == true) {
                await flutterUsbPrinter.write(data);
                printStatus = 0;
              } else {
                printStatus = 1;
                // Fluttertoast.showToast(
                //     backgroundColor: Colors.red,
                //     msg: "${AppLocalizations.of(context)?.translate('usb_printer_not_connect')}");
              }
            }
          } else if(cashierPrinterList[i].type == 1) {
            if (cashierPrinterList[i].paper_size == 0) {
              //print LAN 80mm
              final profile = await CapabilityProfile.load();
              final printer = NetworkPrinter(PaperSize.mm80, profile);
              final PosPrintResult res = await printer.connect(printerDetail, port: 9100, timeout: duration);

              if (res == PosPrintResult.success) {
                await PreviewLayout().printPreviewReceipt80mm(false, cartModel, orderKey, value: printer);
                printer.disconnect();
                printStatus = 0;
              } else if (res == PosPrintResult.timeout){
                print('printer time out');
                printStatus = 2;
              }else {
                printStatus = 1;
              }
            } else {
              //print LAN 58mm
              final profile = await CapabilityProfile.load();
              final printer = NetworkPrinter(PaperSize.mm58, profile);
              final PosPrintResult res = await printer.connect(printerDetail, port: 9100, timeout: duration);

              if (res == PosPrintResult.success) {
                await PreviewLayout().printPreviewReceipt58mm(false, cartModel, orderKey, value: printer);
                printer.disconnect();
                printStatus = 0;
              } else if (res == PosPrintResult.timeout){
                print('printer time out');
                printStatus = 2;
              }
              else {
                printStatus = 1;
              }
            }
          } else {
            bool res = await bluetoothPrinterConnect(printerDetail);
            if (cashierPrinterList[i].paper_size == 0) {
              //print bluetooth 80mm
              if (res) {
                await PrintBluetoothThermal.writeBytes(await PreviewLayout().printPreviewReceipt80mm(true, cartModel, orderKey));
                printStatus = 0;
              } else {
                printStatus = 1;
              }
            } else {
              //print bluetooth 58mm
              if (res) {
                await PrintBluetoothThermal.writeBytes(await PreviewLayout().printPreviewReceipt58mm(true, cartModel, orderKey));
                printStatus = 0;
              } else {
                printStatus = 1;
              }
            }
          }
        }
      }
      return printStatus;
    }catch(e){
      print('Printer Connection Error cart: ${e}');
      FLog.error(
        className: "print_receipt",
        text: "print review receipt error",
        exception: "$e",
      );
      return 1;
    }

  }

  printCartReceiptList(List<Printer> printerList, CartModel cart, String localOrderId) async {
    try {
      int printStatus = 0;
      ///filter active cashier printer
      List<Printer> cashierPrinterList = printerList.where((item) => item.printer_status == 1 && item.is_counter == 1).toList();
      if(cashierPrinterList.isEmpty){
        printStatus = 4;
      } else {
        for (int i = 0; i < cashierPrinterList.length; i++) {
          if(cashierPrinterList[i].printer_status == 1 && cashierPrinterList[i].is_counter == 1){
            var printerDetail = jsonDecode(cashierPrinterList[i].value!);
            if (cashierPrinterList[i].type == 0) {
              if (cashierPrinterList[i].paper_size == 0) {
                var data = Uint8List.fromList(
                    await BillLayout().printReceipt80mm(true, localOrderId, cart.selectedTable, isRefund: cart.cartNotifierItem[0].isRefund));
                bool? isConnected = await flutterUsbPrinter.connect(
                    int.parse(printerDetail['vendorId']), int.parse(printerDetail['productId']));
                if (isConnected == true) {
                  await flutterUsbPrinter.write(data);
                  printStatus = 0;
                } else {
                  printStatus = 1;
                }
              } else {
                var data = Uint8List.fromList(
                    await BillLayout().printReceipt58mm(true, localOrderId, cart.selectedTable, isRefund: cart.cartNotifierItem[0].isRefund));
                bool? isConnected = await flutterUsbPrinter.connect(
                    int.parse(printerDetail['vendorId']), int.parse(printerDetail['productId']));
                if (isConnected == true) {
                  await flutterUsbPrinter.write(data);
                  printStatus = 0;
                } else {
                  printStatus = 1;
                }
              }
            } else if(cashierPrinterList[i].type == 1) {
              //print LAN 80mm
              if (cashierPrinterList[i].paper_size == 0) {
                final profile = await CapabilityProfile.load();
                final printer = NetworkPrinter(PaperSize.mm80, profile);
                final PosPrintResult res = await printer.connect(printerDetail, port: 9100, timeout: duration);
                if (res == PosPrintResult.success) {
                  await BillLayout().printReceipt80mm(false, localOrderId, cart.selectedTable, value: printer, isRefund: cart.cartNotifierItem[0].isRefund);
                  printer.disconnect();
                  printStatus = 0;
                }  else if (res == PosPrintResult.timeout){
                  print('printer time out');
                  printStatus = 2;
                }
                else {
                  printStatus = 1;
                }
              } else {
                //print LAN 58mm
                final profile = await CapabilityProfile.load();
                final printer = NetworkPrinter(PaperSize.mm58, profile);
                final PosPrintResult res = await printer.connect(printerDetail, port: 9100, timeout: duration);
                if (res == PosPrintResult.success) {
                  await BillLayout().printReceipt58mm(false, localOrderId, cart.selectedTable,value: printer, isRefund: cart.cartNotifierItem[0].isRefund);
                  printer.disconnect();
                  printStatus = 0;
                } else if (res == PosPrintResult.timeout){
                  print('printer time out');
                  printStatus = 2;
                  // Fluttertoast.showToast(
                  //     backgroundColor: Colors.orangeAccent,
                  //     msg: "${AppLocalizations.of(context)?.translate('lan_printer_timeout')}");
                }else {
                  printStatus = 1;
                  // Fluttertoast.showToast(
                  //     backgroundColor: Colors.red,
                  //     msg: "${AppLocalizations.of(context)?.translate('lan_printer_not_connect')}");
                }
              }
            } else {
              bool res = await bluetoothPrinterConnect(printerDetail);
              if (cashierPrinterList[i].paper_size == 0) {
                //print bluetooth 80mm
                if (res) {
                  await PrintBluetoothThermal.writeBytes(await BillLayout().printReceipt80mm(true, localOrderId, cart.selectedTable, isRefund: cart.cartNotifierItem[0].isRefund));
                  printStatus = 0;
                } else {
                  printStatus = 1;
                }
              } else {
                //print bluetooth 58mm
                if (res) {
                  await PrintBluetoothThermal.writeBytes(await BillLayout().printReceipt58mm(true, localOrderId, cart.selectedTable, isRefund: cart.cartNotifierItem[0].isRefund));
                  printStatus = 0;
                } else {
                  printStatus = 1;
                }
              }
            }
          }
        }
      }
      return printStatus;
    } catch (e) {
      print('Printer Connection Error cart: ${e}');
      FLog.error(
        className: "print_receipt",
        text: "print cart receipt list error",
        exception: "$e",
      );
      return 1;
      // Fluttertoast.showToast(
      //     backgroundColor: Colors.red,
      //     msg: "${AppLocalizations.of(context)?.translate('printing_error')}");
    }
  }

  printCheckList(List<Printer> printerList, int orderCacheLocalId, {String? order_by}) async {

    print('check list call');
    try {
      int printStatus = 0;
      for (int i = 0; i < printerList.length; i++) {
        int printer_id = 0;
        if(printerList[i].printer_status == 1 && (printerList[i].is_counter == 1 || printerList[i].is_kitchen_checklist == 1)){
          if(printerList[i].is_kitchen_checklist == 1) {
            printer_id = printerList[i].printer_sqlite_id!;
          }
          var printerDetail = jsonDecode(printerList[i].value!);
          if (printerList[i].type == 0) {
            //print USB 80mm
            if (printerList[i].paper_size == 0) {
              var data = Uint8List.fromList(await ChecklistLayout().printCheckList80mm(true, orderCacheLocalId, order_by: order_by, printer_id: printer_id));
              bool? isConnected = await flutterUsbPrinter.connect(int.parse(printerDetail['vendorId']), int.parse(printerDetail['productId']));
              if (isConnected == true) {
                await flutterUsbPrinter.write(data);
                printStatus = 0;
              } else {
                printStatus = 1;
                // Fluttertoast.showToast(
                //     backgroundColor: Colors.red,
                //     msg: "${AppLocalizations.of(context)?.translate('usb_printer_not_connect')}");
              }
            } else {
              //print 58mm
              var data = Uint8List.fromList(await ChecklistLayout().printCheckList58mm(true, orderCacheLocalId, order_by: order_by, printer_id: printer_id));
              bool? isConnected = await flutterUsbPrinter.connect(
                  int.parse(printerDetail['vendorId']), int.parse(printerDetail['productId']));
              if (isConnected == true) {
                await flutterUsbPrinter.write(data);
                printStatus = 0;
              } else {
                printStatus = 1;
                // Fluttertoast.showToast(
                //     backgroundColor: Colors.red,
                //     msg: "${AppLocalizations.of(context)?.translate('usb_printer_not_connect')}");
              }
            }
          } else if(printerList[i].type == 1){
            if (printerList[i].paper_size == 0) {
              //print LAN 80mm paper
              final profile = await CapabilityProfile.load();
              final printer = NetworkPrinter(PaperSize.mm80, profile);
              final PosPrintResult res = await printer.connect(printerDetail, port: 9100, timeout: duration);
              if (res == PosPrintResult.success) {
                await ChecklistLayout().printCheckList80mm(false, orderCacheLocalId, value: printer, order_by: order_by, printer_id: printer_id);
                await Future.delayed(Duration(milliseconds: 100));
                printer.disconnect();
                printStatus = 0;
              } else if (res == PosPrintResult.timeout){
                print('printer time out');
                printStatus = 2;
              } else {
                printStatus = 1;
              }
            } else {
              //print LAN 58mm paper
              final profile = await CapabilityProfile.load();
              final printer = NetworkPrinter(PaperSize.mm58, profile);
              final PosPrintResult res = await printer.connect(printerDetail, port: 9100, timeout: duration);
              if (res == PosPrintResult.success) {
                await ChecklistLayout().printCheckList58mm(false, orderCacheLocalId, value: printer, order_by: order_by, printer_id: printer_id);
                await Future.delayed(Duration(milliseconds: 100));
                printer.disconnect();
                printStatus = 0;
              } else if (res == PosPrintResult.timeout){
                print('printer time out');
                printStatus = 2;
              } else {
                printStatus =  1;
              }
            }
          } else {
            bool res = await bluetoothPrinterConnect(printerDetail);
            //bluetooth print 80mm
            if (printerList[i].paper_size == 0) {
              if (res) {
                await PrintBluetoothThermal.writeBytes(await ChecklistLayout().printCheckList80mm(true, orderCacheLocalId, order_by: order_by, printer_id: printer_id));
                printStatus = 0;
              } else {
                printStatus = 1;
              }
            } else {
              //bluetooth print 58mm
              if (res) {
                await PrintBluetoothThermal.writeBytes(await ChecklistLayout().printCheckList58mm(true, orderCacheLocalId, order_by: order_by, printer_id: printer_id));
                printStatus = 0;
              } else {
                printStatus = 1;
              }
            }
          }
        }
      }
      print('finish print');
      return printStatus;
    } catch (e) {
      print('Printer Connection Error: ${e}');
      FLog.error(
        className: "print_receipt",
        text: "print checklist error",
        exception: "$e",
      );
      Fluttertoast.showToast(
          backgroundColor: Colors.red,
          msg: "check list error: $e");
      return 5;
    }
  }

  reprintCheckList(List<Printer> printerList, CartModel cartModel, {bool? isPayment}) async {
    int printStatus = 0;
    try {
      if(printerList.isNotEmpty){
        for (int i = 0; i < printerList.length; i++) {
          if(printerList[i].printer_status == 1 && (printerList[i].is_counter == 1 || printerList[i].is_kitchen_checklist == 1)){
            var printerDetail = jsonDecode(printerList[i].value!);
            if (printerList[i].type == 0) {
              //print USB 80mm
              if (printerList[i].paper_size == 0) {
                var data = Uint8List.fromList(await ReprintCheckListLayout().reprintCheckList80mm(true, cartModel, isPayment: isPayment));
                bool? isConnected = await flutterUsbPrinter.connect(int.parse(printerDetail['vendorId']), int.parse(printerDetail['productId']));
                if (isConnected == true) {
                  await flutterUsbPrinter.write(data);
                  printStatus = 0;
                } else {
                  printStatus = 1;
                }
              } else {
                //print 58mm
                var data = Uint8List.fromList(await ReprintCheckListLayout().reprintCheckList58mm(true, cartModel, isPayment: isPayment));
                bool? isConnected = await flutterUsbPrinter.connect(
                    int.parse(printerDetail['vendorId']), int.parse(printerDetail['productId']));
                if (isConnected == true) {
                  await flutterUsbPrinter.write(data);
                  printStatus = 0;
                } else {
                  printStatus = 1;
                }
              }
            }
            else if(printerList[i].type == 1){
              if (printerList[i].paper_size == 0) {
                //print LAN 80mm paper
                final profile = await CapabilityProfile.load();
                final printer = NetworkPrinter(PaperSize.mm80, profile);
                final PosPrintResult res = await printer.connect(printerDetail, port: 9100, timeout: duration);
                if (res == PosPrintResult.success) {
                  await ReprintCheckListLayout().reprintCheckList80mm(false, cartModel, value: printer, isPayment: isPayment);
                  await Future.delayed(Duration(milliseconds: 100));
                  printer.disconnect();
                  printStatus = 0;
                } else if (res == PosPrintResult.timeout){
                  print('printer time out');
                  printStatus = 2;
                } else {
                  printStatus = 1;
                }
              } else {
                //print LAN 58mm paper
                final profile = await CapabilityProfile.load();
                final printer = NetworkPrinter(PaperSize.mm58, profile);
                final PosPrintResult res = await printer.connect(printerDetail, port: 9100, timeout: duration);
                if (res == PosPrintResult.success) {
                  await ReprintCheckListLayout().reprintCheckList58mm(false, cartModel, value: printer, isPayment: isPayment);
                  await Future.delayed(Duration(milliseconds: 100));
                  printer.disconnect();
                  printStatus = 0;
                } else if (res == PosPrintResult.timeout){
                  print('printer time out');
                  printStatus = 2;
                } else {
                  printStatus = 1;
                }
              }
            }
            else {
              bool res = await bluetoothPrinterConnect(printerDetail);
              //bluetooth print 80mm
              if (printerList[i].paper_size == 0) {
                if (res) {
                  await PrintBluetoothThermal.writeBytes(await ReprintCheckListLayout().reprintCheckList80mm(true, cartModel, isPayment: isPayment));
                  printStatus = 0;
                } else {
                  printStatus = 1;
                }
              } else {
                //bluetooth print 58mm
                if (res) {
                  await PrintBluetoothThermal.writeBytes(await ReprintCheckListLayout().reprintCheckList58mm(true, cartModel, isPayment: isPayment));
                  printStatus = 0;
                } else {
                  printStatus = 1;
                }
              }
            }
          }
        }
      } else {
        printStatus = 3;
      }
    } catch (e) {
      print('Printer Connection Error: ${e}');
      FLog.error(
        className: "print_receipt",
        text: "reprint checklist error",
        exception: "$e",
      );
      printStatus = 5;
    }
    return printStatus;
  }

  printProductTicket(List<Printer> printerList, int orderCacheLocalId, List<cartProductItem> productTicketItem) async {
    try{
      List<Printer> activeCashierPrinter = printerList.where((e) => e.is_counter == 1 && e.is_label == 0 && e.printer_status == 1).toList();
      if(activeCashierPrinter.isNotEmpty){
        for (int i = 0; i < activeCashierPrinter.length; i++) {
          var printerDetail = jsonDecode(activeCashierPrinter[i].value!);
          for (int j = 0; j < productTicketItem.length; j++) {
            for(int k = 0; k < productTicketItem[j].ticket_count!; k++){
              int currentCount = k + 1;
              //check printer type
              if (activeCashierPrinter[i].type == 1) {
                //check paper size
                if (activeCashierPrinter[i].paper_size == 0) {
                  //print LAN
                  final profile = await CapabilityProfile.load();
                  final printer = NetworkPrinter(PaperSize.mm80, profile);
                  final PosPrintResult res = await printer.connect(printerDetail, port: 9100, timeout: duration);
                  if (res == PosPrintResult.success) {
                    await ProductTicketLayout().printProductTicket80mm(false, orderCacheLocalId, currentCount, value: printer, cartItem: productTicketItem[j]);
                    await Future.delayed(Duration(milliseconds: 100));
                    printer.disconnect();
                  } else {
                    // failedPrintOrderDetail.add(orderDetail[k]);
                  }
                } else if (activeCashierPrinter[i].paper_size == 1) {
                  //print LAN 58mm
                  final profile = await CapabilityProfile.load();
                  final printer = NetworkPrinter(PaperSize.mm58, profile);
                  final PosPrintResult res = await printer.connect(printerDetail, port: 9100, timeout: duration);
                  if (res == PosPrintResult.success) {
                    //need to change to 58
                    await ProductTicketLayout().printProductTicket58mm(false, orderCacheLocalId, currentCount, value: printer, cartItem: productTicketItem[j]);
                    await Future.delayed(Duration(milliseconds: 100));
                    printer.disconnect();
                  } else {
                    // failedPrintOrderDetail.add(orderDetail[k]);
                  }
                }
              } else {
                //print USB
                if (activeCashierPrinter[i].paper_size == 0) {
                  var data_usb;
                  data_usb = Uint8List.fromList(await ProductTicketLayout().printProductTicket80mm(true, orderCacheLocalId, currentCount, cartItem: productTicketItem[j]));
                  bool? isConnected = await flutterUsbPrinter.connect(int.parse(printerDetail['vendorId']), int.parse(printerDetail['productId']));
                  if (isConnected == true) {
                    await flutterUsbPrinter.write(data_usb);
                  } else {
                    // failedPrintOrderDetail.add(orderDetail[k]);
                  }
                } else if (activeCashierPrinter[i].paper_size == 1) {
                  //print USB 58mm
                  var data_usb;
                  data_usb = Uint8List.fromList(await ProductTicketLayout().printProductTicket58mm(true, orderCacheLocalId, currentCount, cartItem: productTicketItem[j]));
                  bool? isConnected = await flutterUsbPrinter.connect(
                      int.parse(printerDetail['vendorId']), int.parse(printerDetail['productId']));
                  if (isConnected == true) {
                    await flutterUsbPrinter.write(data_usb);
                  } else {
                    // failedPrintOrderDetail.add(orderDetail[k]);
                  }
                }
              }
            }
          }
        }
      }
      // return failedPrintOrderDetail;
    } catch (e){
      print('Product ticket printing error: ${e}');
      FLog.error(
        className: "print_receipt",
        text: "print product ticket error",
        exception: "$e",
      );
      return 5;
    }
  }

  getTableNumber(int orderCacheId, OrderDetail orderDetail) async {
    List<String> tableNoList = [];
    OrderCache cacheData = await PosDatabase.instance.readSpecificOrderCacheByLocalId(orderCacheId);
    List<TableUseDetail> detailData2 = await PosDatabase.instance.readAllTableUseDetail(cacheData.table_use_sqlite_id!);
    for(int i = 0; i < detailData2.length; i++){
      List<PosTable> tableData = await PosDatabase.instance.readSpecificTable(detailData2[i].table_sqlite_id!);
      if(!orderDetail.tableNumber.contains(tableData[0].number)){
        tableNoList.add(tableData[0].number!);
      }
    }
    orderDetail.tableNumber.addAll(tableNoList);
  }

  getOrderQueue(int orderCacheId, OrderDetail orderDetail) async {
    OrderCache cacheData = await PosDatabase.instance.readSpecificOrderCacheByLocalId(orderCacheId);
    orderDetail.orderQueue = cacheData.order_queue!;

  }

  List<OrderDetail> groupOrderDetailsByCategory(List<OrderDetail> orderDetail, List<PrinterLinkCategory> data) {
    combineListTotal = 0;
    List<OrderDetail> groupedOrderDetails = [];
    for(int i=0; i < orderDetail.length; i++){
      for (int j = 0; j < data.length; j++) {
        if(orderDetail[i].category_sqlite_id == data[j].category_sqlite_id){
          groupedOrderDetails.add(orderDetail[i]);
          combineListTotal += double.parse(orderDetail[i].price!) * double.parse(orderDetail[i].quantity!);
        }
      }
    }
    return groupedOrderDetails;
  }

  printKitchenList(List<Printer> printerList, int orderCacheLocalId, {bool? isReprint}) async {
    print("printKitchenList called");
    List<OrderDetail>? failedPrintOrderDetail;
    try{
      KitchenList? kitchenListLayout58mm = await PosDatabase.instance.readSpecificKitchenList('58');
      KitchenList? kitchenListLayout80mm = await PosDatabase.instance.readSpecificKitchenList('80');
      List<OrderDetail> orderDetail = await PosDatabase.instance.readSpecificOrderDetailByOrderCacheId(orderCacheLocalId.toString());
      int currentItem = 0;
      if(printerList.isNotEmpty){
        failedPrintOrderDetail = [];
        for (int i = 0; i < printerList.length; i++) {
          if(printerList[i].printer_status == 1){
            bool printCombinedKitchenList = false;
            List<PrinterLinkCategory> data = await PosDatabase.instance.readPrinterLinkCategory(printerList[i].printer_sqlite_id!);
            for (int j = 0; j < data.length; j++) {
              for (int k = 0; k < orderDetail.length; k++) {
                //get table number
                await getTableNumber(orderCacheLocalId, orderDetail[k]);
                //get order queue number
                await getOrderQueue(orderCacheLocalId, orderDetail[k]);
                //check printer category
                if (orderDetail[k].category_sqlite_id == data[j].category_sqlite_id && orderDetail[k].status == 0) {
                  var printerDetail = jsonDecode(printerList[i].value!);
                  for(int i = 0; i < orderDetail.length; i++) {
                    List<OrderModifierDetail> modDetail = await PosDatabase.instance.readOrderModifierDetail(orderDetail[i].order_detail_sqlite_id.toString());
                    if(modDetail.isNotEmpty){
                      orderDetail[i].orderModifierDetail = modDetail;
                    } else {
                      orderDetail[i].orderModifierDetail = [];
                    }
                  }
                  //check printer type
                  if (printerList[i].type == 1) {
                    //check paper size
                    if (printerList[i].paper_size == 0) {
                      //print LAN
                      final profile = await CapabilityProfile.load();
                      final printer = NetworkPrinter(PaperSize.mm80, profile);
                      final PosPrintResult res = await printer.connect(printerDetail, port: 9100, timeout: duration);
                      if (res == PosPrintResult.success) {
                        if(kitchenListLayout80mm == null || kitchenListLayout80mm.print_combine_kitchen_list == 0 || orderDetail.length == 1)
                          await DefaultKitchenListLayout().printKitchenList80mm(false, orderCacheLocalId, value: printer, orderDetail: orderDetail[k], isReprint: isReprint);
                        else if(kitchenListLayout80mm.print_combine_kitchen_list == 1 && printCombinedKitchenList == false) {
                          List<OrderDetail> groupedOrderDetails = groupOrderDetailsByCategory(orderDetail, data);
                          await CombineKitchenListLayout().printCombinedKitchenList80mm(false, orderCacheLocalId, value: printer, orderDetailList: groupedOrderDetails, isReprint: isReprint, combineListTotal: combineListTotal);
                          printCombinedKitchenList = true;
                        }
                        await Future.delayed(Duration(milliseconds: 100));
                        printer.disconnect();
                      } else {
                        failedPrintOrderDetail.add(orderDetail[k]);
                      }
                    } else if (printerList[i].paper_size == 1) {
                      //print LAN 58mm
                      final profile = await CapabilityProfile.load();
                      final printer = NetworkPrinter(PaperSize.mm58, profile);
                      final PosPrintResult res = await printer.connect(printerDetail, port: 9100, timeout: duration);
                      if (res == PosPrintResult.success) {
                        if(kitchenListLayout58mm == null || kitchenListLayout58mm.print_combine_kitchen_list == 0 || orderDetail.length == 1)
                          await DefaultKitchenListLayout().printKitchenList58mm(false, orderCacheLocalId, value: printer, orderDetail: orderDetail[k], isReprint: isReprint);
                        else if(kitchenListLayout58mm.print_combine_kitchen_list == 1 && printCombinedKitchenList == false) {
                          List<OrderDetail> groupedOrderDetails = groupOrderDetailsByCategory(orderDetail, data);
                          await CombineKitchenListLayout().printCombinedKitchenList58mm(false, orderCacheLocalId, value: printer, orderDetailList: groupedOrderDetails, isReprint: isReprint, combineListTotal: combineListTotal);
                          printCombinedKitchenList = true;
                        }
                        await Future.delayed(Duration(milliseconds: 100));
                        printer.disconnect();
                      } else {
                        failedPrintOrderDetail.add(orderDetail[k]);
                      }
                    } else {
                      // print LAN 35mm label
                      final profile = await CapabilityProfile.load();
                      final printer = NetworkPrinter(PaperSize.mm35, profile);
                      final PosPrintResult res = await printer.connect(printerDetail, port: 9100, timeout: duration);
                      int totalItem = 0;
                      // get total item in order
                      for (int x = 0; x < orderDetail.length; x++)
                        for (int y = 0; y < int.parse(orderDetail[x].quantity!); y++)
                          totalItem += 1;

                      for (int j = 0; j < int.parse(orderDetail[k].quantity!); j++) {
                        currentItem++;
                        if (res == PosPrintResult.success) {
                          await ReceiptLayout().printLabel35mm(false, orderCacheLocalId, totalItem, currentItem, value: printer, orderDetail: orderDetail[k]);
                          await Future.delayed(Duration(milliseconds: 100));
                          printer.disconnect();
                        } else {
                          failedPrintOrderDetail.add(orderDetail[k]);
                        }
                      }
                    }
                  } else if(printerList[i].type == 0){
                    //print USB
                    if (printerList[i].paper_size == 0) {
                      var data_usb;
                      if(kitchenListLayout80mm == null || kitchenListLayout80mm.print_combine_kitchen_list == 0 || orderDetail.length == 1)
                        data_usb = Uint8List.fromList(await DefaultKitchenListLayout().printKitchenList80mm(true, orderCacheLocalId, orderDetail: orderDetail[k], isReprint: isReprint));
                      else if(kitchenListLayout80mm.print_combine_kitchen_list == 1 && printCombinedKitchenList == false) {
                        List<OrderDetail> groupedOrderDetails = groupOrderDetailsByCategory(orderDetail, data);
                        data_usb = Uint8List.fromList(await CombineKitchenListLayout().printCombinedKitchenList80mm(true, orderCacheLocalId, orderDetailList: groupedOrderDetails, isReprint: isReprint, combineListTotal: combineListTotal));
                        printCombinedKitchenList = true;
                      }
                      if(data_usb != null) {
                        bool? isConnected = await flutterUsbPrinter.connect(int.parse(printerDetail['vendorId']), int.parse(printerDetail['productId']));
                        if (isConnected == true) {
                          await flutterUsbPrinter.write(data_usb);
                        } else {
                          failedPrintOrderDetail.add(orderDetail[k]);
                        }
                      }
                    } else if (printerList[i].paper_size == 1) {
                      //print USB 58mm
                      var data_usb;
                      if(kitchenListLayout58mm == null || kitchenListLayout58mm.print_combine_kitchen_list == 0 || orderDetail.length == 1)
                        data_usb = Uint8List.fromList(await DefaultKitchenListLayout().printKitchenList58mm(true, orderCacheLocalId, orderDetail: orderDetail[k], isReprint: isReprint));
                      else if(kitchenListLayout58mm.print_combine_kitchen_list == 1 && printCombinedKitchenList == false) {
                        List<OrderDetail> groupedOrderDetails = groupOrderDetailsByCategory(orderDetail, data);
                        data_usb = Uint8List.fromList(await CombineKitchenListLayout().printCombinedKitchenList58mm(true, orderCacheLocalId, orderDetailList: groupedOrderDetails, isReprint: isReprint, combineListTotal: combineListTotal));
                        printCombinedKitchenList = true;
                      }
                      if(data_usb != null) {
                        bool? isConnected = await flutterUsbPrinter.connect(
                            int.parse(printerDetail['vendorId']), int.parse(printerDetail['productId']));
                        if (isConnected == true) {
                          await flutterUsbPrinter.write(data_usb);
                        } else {
                          failedPrintOrderDetail.add(orderDetail[k]);
                        }
                      }
                    } else {
                      //print USB 35mm
                      int totalItem = 0;
                      // get total item in order
                      for (int x = 0; x < orderDetail.length; x++)
                        for (int y = 0; y < int.parse(orderDetail[x].quantity!); y++)
                          totalItem += 1;

                      for (int j = 0; j < int.parse(orderDetail[k].quantity!); j++) {
                        currentItem++;
                        var data = Uint8List.fromList(
                            await ReceiptLayout().printLabel35mm(true, orderCacheLocalId, totalItem, currentItem, orderDetail: orderDetail[k]));
                        bool? isConnected = await flutterUsbPrinter.connect(
                            int.parse(printerDetail['vendorId']), int.parse(printerDetail['productId']));
                        if (isConnected == true) {
                          asyncQ.addJob((_) async => await flutterUsbPrinter.write(data));
                        } else {
                          failedPrintOrderDetail.add(orderDetail[k]);
                        }
                      }
                    }
                  } else {
                    //print bluetooth
                    bool res = await bluetoothPrinterConnect(printerDetail);
                    if (printerList[i].paper_size == 0) {
                      if (res) {
                        if(kitchenListLayout80mm == null || kitchenListLayout80mm.print_combine_kitchen_list == 0 || orderDetail.length == 1)
                          await PrintBluetoothThermal.writeBytes(await DefaultKitchenListLayout().printKitchenList80mm(true, orderCacheLocalId, orderDetail: orderDetail[k], isReprint: isReprint));
                        else if(kitchenListLayout80mm.print_combine_kitchen_list == 1 && printCombinedKitchenList == false) {
                          List<OrderDetail> groupedOrderDetails = groupOrderDetailsByCategory(orderDetail, data);
                          await PrintBluetoothThermal.writeBytes(await CombineKitchenListLayout().printCombinedKitchenList80mm(true, orderCacheLocalId, orderDetailList: groupedOrderDetails, isReprint: isReprint, combineListTotal: combineListTotal));
                          printCombinedKitchenList = true;
                        }
                      } else {
                        failedPrintOrderDetail.add(orderDetail[k]);
                      }
                    } else if (printerList[i].paper_size == 1) {
                      if (res) {
                        if(kitchenListLayout58mm == null || kitchenListLayout58mm.print_combine_kitchen_list == 0 || orderDetail.length == 1)
                          await PrintBluetoothThermal.writeBytes(await DefaultKitchenListLayout().printKitchenList58mm(true, orderCacheLocalId, orderDetail: orderDetail[k], isReprint: isReprint));
                        else if(kitchenListLayout58mm.print_combine_kitchen_list == 1 && printCombinedKitchenList == false) {
                          List<OrderDetail> groupedOrderDetails = groupOrderDetailsByCategory(orderDetail, data);
                          await PrintBluetoothThermal.writeBytes(await CombineKitchenListLayout().printCombinedKitchenList58mm(true, orderCacheLocalId, orderDetailList: groupedOrderDetails, isReprint: isReprint, combineListTotal: combineListTotal));
                          printCombinedKitchenList = true;
                        }
                      } else {
                        failedPrintOrderDetail.add(orderDetail[k]);
                      }
                    } else {
                      //print bluetooth 35mm
                      int totalItem = 0;
                      // get total item in order
                      for (int x = 0; x < orderDetail.length; x++)
                        for (int y = 0; y < int.parse(orderDetail[x].quantity!); y++)
                          totalItem += 1;

                      for (int j = 0; j < int.parse(orderDetail[k].quantity!); j++) {
                        currentItem++;
                        if (res) {
                          await PrintBluetoothThermal.writeBytes(await ReceiptLayout().printLabel35mm(true, orderCacheLocalId, totalItem, currentItem, orderDetail: orderDetail[k]));
                        } else {
                          failedPrintOrderDetail.add(orderDetail[k]);
                        }
                      }
                    }
                  }
                }
              }
            }
          }
        }
      }
      return failedPrintOrderDetail;
    } catch (e){
      print('Kitchen printing Error: ${e}');
      FLog.error(
        className: "print_receipt",
        text: "print kitchen list error",
        exception: "$e",
      );
      return failedPrintOrderDetail;
    }
  }

  reprintFailKitchenList(List<Printer> printerList, {required List<OrderDetail> reprintList}) async {
    List<OrderDetail>? failedPrintOrderDetail;
    int currentItem = 0;
    try{
      KitchenList? kitchenListLayout58mm = await PosDatabase.instance.readSpecificKitchenList('58');
      KitchenList? kitchenListLayout80mm = await PosDatabase.instance.readSpecificKitchenList('80');
      if(printerList.isNotEmpty){
        failedPrintOrderDetail = [];
        for (int i = 0; i < printerList.length; i++) {
          if(printerList[i].printer_status == 1){
            List<PrinterLinkCategory> data = await PosDatabase.instance.readPrinterLinkCategory(printerList[i].printer_sqlite_id!);
            for (int j = 0; j < data.length; j++) {
              for (int k = 0; k < reprintList.length; k++) {
                //check printer category
                if (reprintList[k].category_sqlite_id == data[j].category_sqlite_id && reprintList[k].status == 0) {
                  var printerDetail = jsonDecode(printerList[i].value!);
                  List<OrderModifierDetail> modDetail = await PosDatabase.instance.readOrderModifierDetail(reprintList[k].order_detail_sqlite_id.toString());
                  if(modDetail.isNotEmpty){
                    reprintList[k].orderModifierDetail = modDetail;
                  } else {
                    reprintList[k].orderModifierDetail = [];
                  }
                  //check printer type
                  if (printerList[i].type == 1) {
                    //check paper size
                    if (printerList[i].paper_size == 0) {
                      //print LAN
                      final profile = await CapabilityProfile.load();
                      final printer = NetworkPrinter(PaperSize.mm80, profile);
                      final PosPrintResult res = await printer.connect(printerDetail, port: 9100, timeout: duration);
                      if (res == PosPrintResult.success) {
                        if(kitchenListLayout80mm == null || kitchenListLayout80mm.print_combine_kitchen_list == 0 || reprintList.length == 1){
                          await DefaultKitchenListLayout().printKitchenList80mm(false, int.parse(reprintList[k].order_cache_sqlite_id!), value: printer, orderDetail: reprintList[k], isReprint: true);
                        } else if(kitchenListLayout80mm.print_combine_kitchen_list == 1) {
                          List<String> distinctTableNumbers = [];
                          List<String> distinctOrderNumbers = [];
                          List<String> distinctDateTime = [];

                          for (OrderDetail orderDetail in reprintList) {
                            if (orderDetail.orderQueue != '') {
                              distinctOrderNumbers = reprintList.map((orderDetail) => orderDetail.orderQueue!).toSet().toList();
                            } else if (orderDetail.tableNumber.isNotEmpty) {
                              // distinctTableNumbers.add(orderDetail.tableNumber.map((num) => num.toString()).join(', '));
                              distinctTableNumbers = reprintList.map((orderDetail) => orderDetail.tableNumber.map((num) => num.toString()).join(', ')).toSet().toList();
                            } else {
                              distinctDateTime = reprintList.map((orderDetail) => orderDetail.created_at!).toSet().toList();
                            }
                          }
                          if(distinctOrderNumbers.length >= 1) {
                            for (String orderNumberFiltered in distinctOrderNumbers) {
                              List<OrderDetail> filteredOrders = [];
                              filteredOrders.addAll(reprintList.where((orderDetail) => orderDetail.orderQueue! == orderNumberFiltered).toList());
                              List<OrderDetail> groupedOrderDetails = groupOrderDetailsByCategory(filteredOrders, data);
                              if(filteredOrders.length > 1) {
                                await CombineKitchenListLayout().printCombinedKitchenList80mm(
                                  false,
                                  int.parse(filteredOrders.first.order_cache_sqlite_id!),
                                  value: printer,
                                  orderDetailList: groupedOrderDetails,
                                  combineListTotal: combineListTotal
                                );
                                reprintList.removeWhere((orderDetail) => groupedOrderDetails.any((groupedDetail) => groupedDetail.order_detail_sqlite_id == orderDetail.order_detail_sqlite_id));
                              } else {
                                await DefaultKitchenListLayout().printKitchenList80mm(false, int.parse(filteredOrders.first.order_cache_sqlite_id!), value: printer, orderDetail: groupedOrderDetails[0], isReprint: true);
                                reprintList.removeWhere((orderDetail) => orderDetail.orderQueue! == orderNumberFiltered);
                              }
                            }
                          }

                          if(distinctTableNumbers.length >= 1) {
                            for (String tableNumberFiltered in distinctTableNumbers) {
                              List<OrderDetail> filteredOrders = [];
                              filteredOrders.addAll(reprintList.where((orderDetail) => orderDetail.tableNumber.toString().replaceAll('[', '').replaceAll(']', '') == tableNumberFiltered).toList());
                              List<OrderDetail> groupedOrderDetails = groupOrderDetailsByCategory(filteredOrders, data);
                              if(filteredOrders.length > 1) {
                                await CombineKitchenListLayout().printCombinedKitchenList80mm(
                                  false,
                                  int.parse(groupedOrderDetails.first.order_cache_sqlite_id!),
                                  value: printer,
                                  orderDetailList: groupedOrderDetails,
                                  combineListTotal: combineListTotal
                                );
                                reprintList.removeWhere((orderDetail) => groupedOrderDetails.any((groupedDetail) => groupedDetail.order_detail_sqlite_id == orderDetail.order_detail_sqlite_id));
                              } else {
                                await DefaultKitchenListLayout().printKitchenList80mm(false, int.parse(filteredOrders.first.order_cache_sqlite_id!), value: printer, orderDetail: groupedOrderDetails[0], isReprint: true);
                                reprintList.removeWhere((orderDetail) => orderDetail.tableNumber.toString().replaceAll('[', '').replaceAll(']', '') == tableNumberFiltered);
                              }
                            }
                          }

                          if(distinctDateTime.length >= 1) {
                            for (String dateTimeFiltered in distinctDateTime) {
                              List<OrderDetail> filteredOrders = [];
                              filteredOrders.addAll(reprintList.where((orderDetail) => orderDetail.created_at! == dateTimeFiltered).toList());
                              List<OrderDetail> groupedOrderDetails = groupOrderDetailsByCategory(filteredOrders, data);
                              if(filteredOrders.length > 1) {
                                await CombineKitchenListLayout().printCombinedKitchenList80mm(
                                  false,
                                  int.parse(filteredOrders.first.order_cache_sqlite_id!),
                                  value: printer,
                                  orderDetailList: groupedOrderDetails,
                                  combineListTotal: combineListTotal
                                );
                                reprintList.removeWhere((orderDetail) => groupedOrderDetails.any((groupedDetail) => groupedDetail.order_detail_sqlite_id == orderDetail.order_detail_sqlite_id));
                              } else {
                                await DefaultKitchenListLayout().printKitchenList80mm(false, int.parse(filteredOrders.first.order_cache_sqlite_id!), value: printer, orderDetail: groupedOrderDetails[0], isReprint: true);
                                reprintList.removeWhere((orderDetail) => orderDetail.created_at! == dateTimeFiltered);
                              }
                            }
                          }
                        }
                        await Future.delayed(Duration(milliseconds: 100));
                        printer.disconnect();
                      } else {
                        failedPrintOrderDetail.add(reprintList[k]);
                      }
                    } else if (printerList[i].paper_size == 1) {
                      //print LAN 58mm
                      final profile = await CapabilityProfile.load();
                      final printer = NetworkPrinter(PaperSize.mm58, profile);
                      final PosPrintResult res = await printer.connect(printerDetail, port: 9100, timeout: duration);

                      if (res == PosPrintResult.success) {
                        if(kitchenListLayout58mm == null || kitchenListLayout58mm.print_combine_kitchen_list == 0 || reprintList.length == 1){
                          await DefaultKitchenListLayout().printKitchenList58mm(false, int.parse(reprintList[k].order_cache_sqlite_id!), value: printer, orderDetail: reprintList[k], isReprint: true);
                        } else if(kitchenListLayout58mm.print_combine_kitchen_list == 1) {
                          List<String> distinctTableNumbers = [];
                          List<String> distinctOrderNumbers = [];
                          List<String> distinctDateTime = [];

                          for (OrderDetail orderDetail in reprintList) {
                            if (orderDetail.orderQueue != '') {
                              // distinctOrderNumbers.add(orderDetail.orderQueue!);
                              distinctOrderNumbers = reprintList.map((orderDetail) => orderDetail.orderQueue!).toSet().toList();
                            } else if (orderDetail.tableNumber.isNotEmpty) {
                              // distinctTableNumbers.add(orderDetail.tableNumber.map((num) => num.toString()).join(', '));
                              distinctTableNumbers = reprintList.map((orderDetail) => orderDetail.tableNumber.map((num) => num.toString()).join(', ')).toSet().toList();
                            } else {
                              distinctDateTime = reprintList.map((orderDetail) => orderDetail.created_at!).toSet().toList();
                            }
                          }

                          if(distinctOrderNumbers.length >= 1) {
                            for (String orderNumberFiltered in distinctOrderNumbers) {
                              List<OrderDetail> filteredOrders = [];
                              filteredOrders.addAll(reprintList.where((orderDetail) => orderDetail.orderQueue! == orderNumberFiltered).toList());
                              List<OrderDetail> groupedOrderDetails = groupOrderDetailsByCategory(filteredOrders, data);
                              if(filteredOrders.length > 1) {
                                await CombineKitchenListLayout().printCombinedKitchenList58mm(
                                  false,
                                  int.parse(groupedOrderDetails.first.order_cache_sqlite_id!),
                                  value: printer,
                                  orderDetailList: groupedOrderDetails,
                                  combineListTotal: combineListTotal
                                );
                                reprintList.removeWhere((orderDetail) => groupedOrderDetails.any((groupedDetail) => groupedDetail.order_detail_sqlite_id == orderDetail.order_detail_sqlite_id));
                              } else {
                                await DefaultKitchenListLayout().printKitchenList58mm(false, int.parse(filteredOrders.first.order_cache_sqlite_id!), value: printer, orderDetail: filteredOrders[0], isReprint: true);
                                reprintList.removeWhere((orderDetail) => orderDetail.orderQueue! == orderNumberFiltered);
                              }
                            }
                          }

                          if(distinctTableNumbers.length >= 1) {
                            for (String tableNumberFiltered in distinctTableNumbers) {
                              List<OrderDetail> filteredOrders = [];
                              filteredOrders.addAll(reprintList.where((orderDetail) => orderDetail.tableNumber.toString().replaceAll('[', '').replaceAll(']', '') == tableNumberFiltered).toList());
                              List<OrderDetail> groupedOrderDetails = groupOrderDetailsByCategory(filteredOrders, data);
                              if(filteredOrders.length > 1) {
                                await CombineKitchenListLayout().printCombinedKitchenList58mm(
                                  false,
                                  int.parse(groupedOrderDetails.first.order_cache_sqlite_id!),
                                  value: printer,
                                  orderDetailList: groupedOrderDetails,
                                  combineListTotal: combineListTotal
                                );
                                reprintList.removeWhere((orderDetail) => groupedOrderDetails.any((groupedDetail) => groupedDetail.order_detail_sqlite_id == orderDetail.order_detail_sqlite_id));
                              } else {
                                await DefaultKitchenListLayout().printKitchenList58mm(false, int.parse(filteredOrders.first.order_cache_sqlite_id!), value: printer, orderDetail: filteredOrders[0], isReprint: true);
                                reprintList.removeWhere((orderDetail) => orderDetail.tableNumber.toString().replaceAll('[', '').replaceAll(']', '') == tableNumberFiltered);
                              }
                            }
                          }

                          if(distinctDateTime.length >= 1) {
                            for (String dateTimeFiltered in distinctDateTime) {
                              List<OrderDetail> filteredOrders = [];
                              filteredOrders.addAll(reprintList.where((orderDetail) => orderDetail.created_at! == dateTimeFiltered).toList());
                              List<OrderDetail> groupedOrderDetails = groupOrderDetailsByCategory(filteredOrders, data);
                              if(filteredOrders.length > 1) {
                                await CombineKitchenListLayout().printCombinedKitchenList58mm(
                                  false,
                                  int.parse(groupedOrderDetails.first.order_cache_sqlite_id!),
                                  value: printer,
                                  orderDetailList: groupedOrderDetails,
                                  combineListTotal: combineListTotal
                                );
                                reprintList.removeWhere((orderDetail) => groupedOrderDetails.any((groupedDetail) => groupedDetail.order_detail_sqlite_id == orderDetail.order_detail_sqlite_id));
                              } else {
                                await DefaultKitchenListLayout().printKitchenList58mm(false, int.parse(filteredOrders.first.order_cache_sqlite_id!), value: printer, orderDetail: filteredOrders[0], isReprint: true);
                                reprintList.removeWhere((orderDetail) => orderDetail.created_at! == dateTimeFiltered);
                              }
                            }
                          }
                        }
                        await Future.delayed(Duration(milliseconds: 100));
                        printer.disconnect();
                      } else {
                        failedPrintOrderDetail.add(reprintList[k]);
                      }
                    } else {
                      //print LAN 35mm
                      print("reprint label 35mm");
                      final profile = await CapabilityProfile.load();
                      final printer = NetworkPrinter(PaperSize.mm35, profile);
                      final PosPrintResult res = await printer.connect(printerDetail, port: 9100, timeout: duration);
                      int totalItem = 0;
                      for (int x = 0; x < reprintList.length; x++)
                        for (int y = 0; y < int.parse(reprintList[x].quantity!); y++)
                          totalItem += 1;

                      for (int j = 0; j < int.parse(reprintList[k].quantity!); j++) {
                        currentItem++;
                        if (res == PosPrintResult.success) {
                          await ReceiptLayout().printLabel35mm(false, int.parse(reprintList[k].order_cache_sqlite_id!), totalItem, currentItem, value: printer, orderDetail: reprintList[k]);
                          await Future.delayed(Duration(milliseconds: 100));
                          printer.disconnect();
                        } else {
                          failedPrintOrderDetail.add(reprintList[k]);
                        }
                      }
                    }
                  } else if(printerList[i].type == 0){
                    //print USB
                    if (printerList[i].paper_size == 0) {
                      var data = Uint8List.fromList(
                          await DefaultKitchenListLayout().printKitchenList80mm(true, int.parse(reprintList[k].order_cache_sqlite_id!), orderDetail: reprintList[k], isReprint: true));
                      bool? isConnected = await flutterUsbPrinter.connect(int.parse(printerDetail['vendorId']), int.parse(printerDetail['productId']));
                      if (isConnected == true) {
                        await flutterUsbPrinter.write(data);
                      } else {
                        failedPrintOrderDetail.add(reprintList[k]);
                      }
                    } else if (printerList[i].paper_size == 1) {
                      //print 58mm
                      var data = Uint8List.fromList(
                          await DefaultKitchenListLayout().printKitchenList58mm(true, int.parse(reprintList[k].order_cache_sqlite_id!), orderDetail: reprintList[k], isReprint: true));
                      bool? isConnected = await flutterUsbPrinter.connect(
                          int.parse(printerDetail['vendorId']), int.parse(printerDetail['productId']));
                      if (isConnected == true) {
                        await flutterUsbPrinter.write(data);
                      } else {
                        failedPrintOrderDetail.add(reprintList[k]);
                      }
                    } else {
                      //print 35mm
                      print("reprint label 35mm");
                      int totalItem = 0;
                      for (int x = 0; x < reprintList.length; x++)
                        for (int y = 0; y < int.parse(reprintList[x].quantity!); y++)
                          totalItem += 1;

                      for (int j = 0; j < int.parse(reprintList[k].quantity!); j++) {
                        currentItem++;
                        var data = Uint8List.fromList(
                            await ReceiptLayout().printLabel35mm(true, int.parse(reprintList[k].order_cache_sqlite_id!), totalItem, currentItem, orderDetail: reprintList[k]));
                        bool? isConnected = await flutterUsbPrinter.connect(
                            int.parse(printerDetail['vendorId']), int.parse(printerDetail['productId']));
                        if (isConnected == true) {
                          await flutterUsbPrinter.write(data);
                        } else {
                          failedPrintOrderDetail.add(reprintList[k]);
                        }
                      }
                    }
                  } else {
                    //print bluetooth
                    bool res = await bluetoothPrinterConnect(printerDetail);
                    if (printerList[i].paper_size == 0) {
                      if (res) {
                        if(kitchenListLayout80mm == null || kitchenListLayout80mm.print_combine_kitchen_list == 0 || reprintList.length == 1){
                          var data = await DefaultKitchenListLayout().printKitchenList80mm(true, int.parse(reprintList[k].order_cache_sqlite_id!), orderDetail: reprintList[k], isReprint: true);
                          await PrintBluetoothThermal.writeBytes(data);
                        } else if(kitchenListLayout80mm.print_combine_kitchen_list == 1) {
                          List<String> distinctTableNumbers = [];
                          List<String> distinctOrderNumbers = [];
                          List<String> distinctDateTime = [];

                          for (OrderDetail orderDetail in reprintList) {
                            if (orderDetail.orderQueue != '') {
                              distinctOrderNumbers = reprintList.map((orderDetail) => orderDetail.orderQueue!).toSet().toList();
                            } else if (orderDetail.tableNumber.isNotEmpty) {
                              // distinctTableNumbers.add(orderDetail.tableNumber.map((num) => num.toString()).join(', '));
                              distinctTableNumbers = reprintList.map((orderDetail) => orderDetail.tableNumber.map((num) => num.toString()).join(', ')).toSet().toList();
                            } else {
                              distinctDateTime = reprintList.map((orderDetail) => orderDetail.created_at!).toSet().toList();
                            }
                          }
                          if(distinctOrderNumbers.length >= 1) {
                            for (String orderNumberFiltered in distinctOrderNumbers) {
                              List<OrderDetail> filteredOrders = [];
                              filteredOrders.addAll(reprintList.where((orderDetail) => orderDetail.orderQueue! == orderNumberFiltered).toList());
                              List<OrderDetail> groupedOrderDetails = groupOrderDetailsByCategory(filteredOrders, data);
                              if(filteredOrders.length > 1) {
                                var data = await CombineKitchenListLayout().printCombinedKitchenList80mm(true, int.parse(filteredOrders.first.order_cache_sqlite_id!), orderDetailList: groupedOrderDetails, isReprint: true, combineListTotal: combineListTotal);
                                await PrintBluetoothThermal.writeBytes(data);
                                reprintList.removeWhere((orderDetail) => groupedOrderDetails.any((groupedDetail) => groupedDetail.order_detail_sqlite_id == orderDetail.order_detail_sqlite_id));
                              } else {
                                var data = await DefaultKitchenListLayout().printKitchenList80mm(true, int.parse(filteredOrders.first.order_cache_sqlite_id!), orderDetail: groupedOrderDetails[0], isReprint: true);
                                await PrintBluetoothThermal.writeBytes(data);
                                reprintList.removeWhere((orderDetail) => orderDetail.orderQueue! == orderNumberFiltered);
                              }
                            }
                          }

                          if(distinctTableNumbers.length >= 1) {
                            for (String tableNumberFiltered in distinctTableNumbers) {
                              List<OrderDetail> filteredOrders = [];
                              filteredOrders.addAll(reprintList.where((orderDetail) => orderDetail.tableNumber.toString().replaceAll('[', '').replaceAll(']', '') == tableNumberFiltered).toList());
                              List<OrderDetail> groupedOrderDetails = groupOrderDetailsByCategory(filteredOrders, data);
                              if(filteredOrders.length > 1) {
                                var data = await CombineKitchenListLayout().printCombinedKitchenList80mm(true, int.parse(groupedOrderDetails.first.order_cache_sqlite_id!), orderDetailList: groupedOrderDetails, isReprint: true, combineListTotal: combineListTotal);
                                await PrintBluetoothThermal.writeBytes(data);
                                reprintList.removeWhere((orderDetail) => groupedOrderDetails.any((groupedDetail) => groupedDetail.order_detail_sqlite_id == orderDetail.order_detail_sqlite_id));
                              } else {
                                var data = await DefaultKitchenListLayout().printKitchenList80mm(true, int.parse(filteredOrders.first.order_cache_sqlite_id!), orderDetail: groupedOrderDetails[0], isReprint: true);
                                await PrintBluetoothThermal.writeBytes(data);
                                reprintList.removeWhere((orderDetail) => orderDetail.tableNumber.toString().replaceAll('[', '').replaceAll(']', '') == tableNumberFiltered);
                              }
                            }
                          }

                          if(distinctDateTime.length >= 1) {
                            for (String dateTimeFiltered in distinctDateTime) {
                              List<OrderDetail> filteredOrders = [];
                              filteredOrders.addAll(reprintList.where((orderDetail) => orderDetail.created_at! == dateTimeFiltered).toList());
                              List<OrderDetail> groupedOrderDetails = groupOrderDetailsByCategory(filteredOrders, data);
                              if(filteredOrders.length > 1) {
                                var data = await CombineKitchenListLayout().printCombinedKitchenList80mm(true, int.parse(filteredOrders.first.order_cache_sqlite_id!), orderDetailList: groupedOrderDetails, isReprint: true, combineListTotal: combineListTotal);
                                await PrintBluetoothThermal.writeBytes(data);
                                reprintList.removeWhere((orderDetail) => groupedOrderDetails.any((groupedDetail) => groupedDetail.order_detail_sqlite_id == orderDetail.order_detail_sqlite_id));
                              } else {
                                var data = await DefaultKitchenListLayout().printKitchenList80mm(true, int.parse(filteredOrders.first.order_cache_sqlite_id!), orderDetail: groupedOrderDetails[0], isReprint: true);
                                await PrintBluetoothThermal.writeBytes(data);
                                reprintList.removeWhere((orderDetail) => orderDetail.created_at! == dateTimeFiltered);
                              }
                            }
                          }
                        }
                        await Future.delayed(Duration(milliseconds: 100));
                      } else {
                        failedPrintOrderDetail.add(reprintList[k]);
                      }
                    }
                  }
                }
              }
            }
          }
        }
      }
      return failedPrintOrderDetail;
    } catch (e){
      print('Reprint kitchen printing Error: ${e}');
      FLog.error(
        className: "print_receipt",
        text: "reprint kitchen list error",
        exception: "$e",
      );
      return failedPrintOrderDetail;
      // Fluttertoast.showToast(
      //     backgroundColor: Colors.red,
      //     msg: "${AppLocalizations.of(context)?.translate('printing_error')}");
    }
  }

  playSound() {
    final assetsAudioPlayer = AssetsAudioPlayer();
    assetsAudioPlayer.open(
      Audio("audio/review.mp3"),
    );
  }

  printQrKitchenList(List<Printer> printerList, int orderCacheLocalId, {orderDetailList}) async {
    print("printQrKitchenList called");
    List<OrderDetail> failedPrintOrderDetail = [];
    try{
      KitchenList? kitchenListLayout58mm = await PosDatabase.instance.readSpecificKitchenList('58');
      KitchenList? kitchenListLayout80mm = await PosDatabase.instance.readSpecificKitchenList('80');
      List<OrderDetail> orderDetail = await PosDatabase.instance.readSpecificOrderDetailByOrderCacheId(orderCacheLocalId.toString());
      int currentItem = 0;

      for (int i = 0; i < printerList.length; i++) {
        if(printerList[i].printer_status == 1){
          var printerDetail = jsonDecode(printerList[i].value!);
          bool printCombinedKitchenList = false;
          List<PrinterLinkCategory> data = await PosDatabase.instance.readPrinterLinkCategory(printerList[i].printer_sqlite_id!);
          for (int j = 0; j < data.length; j++) {
            for (int k = 0; k < orderDetailList.length; k++) {
              //check printer category
              if (orderDetailList[k].category_sqlite_id == data[j].category_sqlite_id && orderDetailList[k].status == 0) {

                //check printer type
                if (printerList[i].type == 1) {
                  //check paper size
                  if (printerList[i].paper_size == 0) {
                    //print LAN
                    final profile = await CapabilityProfile.load();
                    final printer = NetworkPrinter(PaperSize.mm80, profile);
                    final PosPrintResult res = await printer.connect(printerDetail, port: 9100, timeout: duration);

                    if (res == PosPrintResult.success) {
                      // await ReceiptLayout().printQrKitchenList80mm(false, orderDetailList[k], orderCacheLocalId, value: printer);
                      if(kitchenListLayout80mm == null || kitchenListLayout80mm.print_combine_kitchen_list == 0 || orderDetailList.length == 1)
                        await DefaultKitchenListLayout().printKitchenList80mm(false, orderCacheLocalId, value: printer, orderDetail: orderDetailList[k]);
                      else if(kitchenListLayout80mm.print_combine_kitchen_list == 1 && printCombinedKitchenList == false) {
                        List<OrderDetail> groupedOrderDetails = groupOrderDetailsByCategory(orderDetailList, data);
                        await CombineKitchenListLayout().printCombinedKitchenList80mm(false, orderCacheLocalId, value: printer, orderDetailList: groupedOrderDetails, combineListTotal: combineListTotal);
                        printCombinedKitchenList = true;
                      }
                      await Future.delayed(Duration(milliseconds: 100));
                      printer.disconnect();

                    } else {
                      failedPrintOrderDetail.add(orderDetailList[k]);
                    }
                  } else if (printerList[i].paper_size == 1){
                    //print LAN 58mm
                    final profile = await CapabilityProfile.load();
                    final printer = NetworkPrinter(PaperSize.mm58, profile);
                    final PosPrintResult res = await printer.connect(printerDetail, port: 9100, timeout: duration);

                    if (res == PosPrintResult.success) {
                      // await ReceiptLayout().printQrKitchenList58mm(false, orderDetailList[k], orderCacheLocalId, value: printer);
                      if(kitchenListLayout58mm == null || kitchenListLayout58mm.print_combine_kitchen_list == 0 || orderDetailList.length == 1)
                        await DefaultKitchenListLayout().printKitchenList58mm(false, orderCacheLocalId, value: printer, orderDetail: orderDetailList[k]);
                      else if(kitchenListLayout58mm.print_combine_kitchen_list == 1 && printCombinedKitchenList == false) {
                        List<OrderDetail> groupedOrderDetails = groupOrderDetailsByCategory(orderDetail, data);
                        await CombineKitchenListLayout().printCombinedKitchenList58mm(false, orderCacheLocalId, value: printer, orderDetailList: groupedOrderDetails, combineListTotal: combineListTotal);
                        printCombinedKitchenList = true;
                      }
                      await Future.delayed(Duration(milliseconds: 100));
                      printer.disconnect();
                    } else {
                      failedPrintOrderDetail.add(orderDetailList[k]);
                    }
                  } else {
                    //print LAN 35mm
                    final profile = await CapabilityProfile.load();
                    final printer = NetworkPrinter(PaperSize.mm35, profile);
                    final PosPrintResult res = await printer.connect(printerDetail, port: 9100, timeout: duration);
                    int totalItem = 0;
                    // get total item in order
                    for (int x = 0; x < orderDetail.length; x++)
                      for (int y = 0; y < int.parse(orderDetail[x].quantity!); y++)
                        totalItem += 1;

                    for (int j = 0; j < int.parse(orderDetail[k].quantity!); j++) {
                      currentItem++;
                      if (res == PosPrintResult.success) {
                        await ReceiptLayout().printLabel35mm(false, orderCacheLocalId, totalItem, currentItem, value: printer, orderDetail: orderDetail[k]);
                        await Future.delayed(Duration(milliseconds: 100));
                        printer.disconnect();
                      } else {
                        failedPrintOrderDetail.add(orderDetail[k]);
                      }
                    }
                  }
                } else if(printerList[i].type == 0){
                  //print USB
                  if (printerList[i].paper_size == 0) {
                    // var data = Uint8List.fromList(
                    //     await ReceiptLayout().printQrKitchenList80mm(true, orderDetailList[k], orderCacheLocalId));
                    var data_usb;
                    if(kitchenListLayout80mm == null || kitchenListLayout80mm.print_combine_kitchen_list == 0 || orderDetailList.length == 1)
                      data_usb = Uint8List.fromList(await DefaultKitchenListLayout().printKitchenList80mm(true, orderCacheLocalId, orderDetail: orderDetailList[k]));
                    else if(kitchenListLayout80mm.print_combine_kitchen_list == 1 && printCombinedKitchenList == false) {
                      List<OrderDetail> groupedOrderDetails = groupOrderDetailsByCategory(orderDetailList, data);
                      data_usb = Uint8List.fromList(await CombineKitchenListLayout().printCombinedKitchenList80mm(true, orderCacheLocalId, orderDetailList: groupedOrderDetails, combineListTotal: combineListTotal));
                      printCombinedKitchenList = true;
                    }
                    if(data_usb != null) {
                      bool? isConnected = await flutterUsbPrinter.connect(
                          int.parse(printerDetail['vendorId']), int.parse(printerDetail['productId']));
                      if (isConnected == true) {
                        await flutterUsbPrinter.write(data_usb);
                      } else {
                        failedPrintOrderDetail.add(orderDetailList[k]);
                      }
                    }
                  } else if (printerList[i].paper_size == 1){
                    //print 58mm
                    // var data = Uint8List.fromList(
                    //     await ReceiptLayout().printQrKitchenList58mm(true, orderDetailList[k], orderCacheLocalId));
                    var data_usb;
                    if(kitchenListLayout58mm == null || kitchenListLayout58mm.print_combine_kitchen_list == 0 || orderDetailList.length == 1)
                      data_usb = Uint8List.fromList(await DefaultKitchenListLayout().printKitchenList58mm(true, orderCacheLocalId, orderDetail: orderDetailList[k]));
                    else if(kitchenListLayout58mm.print_combine_kitchen_list == 1 && printCombinedKitchenList == false) {
                      List<OrderDetail> groupedOrderDetails = groupOrderDetailsByCategory(orderDetail, data);
                      data_usb = Uint8List.fromList(await CombineKitchenListLayout().printCombinedKitchenList58mm(true, orderCacheLocalId, orderDetailList: groupedOrderDetails, combineListTotal: combineListTotal));
                      printCombinedKitchenList = true;
                    }
                    if(data_usb != null) {
                      bool? isConnected = await flutterUsbPrinter.connect(
                          int.parse(printerDetail['vendorId']), int.parse(printerDetail['productId']));
                      if (isConnected == true) {
                        await flutterUsbPrinter.write(data_usb);
                      } else {
                        failedPrintOrderDetail.add(orderDetailList[k]);
                      }
                    }
                  } else {
                    //print USB 35mm
                    int totalItem = 0;
                    // get total item in order
                    for (int x = 0; x < orderDetail.length; x++)
                      for (int y = 0; y < int.parse(orderDetail[x].quantity!); y++)
                        totalItem += 1;

                    for (int j = 0; j < int.parse(orderDetail[k].quantity!); j++) {
                      currentItem++;
                      var data = Uint8List.fromList(
                          await ReceiptLayout().printLabel35mm(true, orderCacheLocalId, totalItem, currentItem, orderDetail: orderDetail[k]));
                      bool? isConnected = await flutterUsbPrinter.connect(
                          int.parse(printerDetail['vendorId']), int.parse(printerDetail['productId']));
                      if (isConnected == true) {
                        await flutterUsbPrinter.write(data);
                      } else {
                        failedPrintOrderDetail.add(orderDetail[k]);
                      }
                    }
                  }
                } else {
                  //print bluetooth
                  bool res = await bluetoothPrinterConnect(printerDetail);
                  if (printerList[i].paper_size == 0) {
                    if (res) {
                      if(kitchenListLayout80mm == null || kitchenListLayout80mm.print_combine_kitchen_list == 0 || orderDetailList.length == 1){
                        var bluetooth_data = await DefaultKitchenListLayout().printKitchenList80mm(true, orderCacheLocalId, orderDetail: orderDetailList[k]);
                        await PrintBluetoothThermal.writeBytes(bluetooth_data);
                      } else if(kitchenListLayout80mm.print_combine_kitchen_list == 1 && printCombinedKitchenList == false) {
                        List<OrderDetail> groupedOrderDetails = groupOrderDetailsByCategory(orderDetailList, data);
                        var bluetooth_data = await CombineKitchenListLayout().printCombinedKitchenList80mm(true, orderCacheLocalId, orderDetailList: groupedOrderDetails, combineListTotal: combineListTotal);
                        await PrintBluetoothThermal.writeBytes(bluetooth_data);
                        printCombinedKitchenList = true;
                      }
                      await Future.delayed(Duration(milliseconds: 100));
                    } else {
                      failedPrintOrderDetail.add(orderDetailList[k]);
                    }
                  } else if (printerList[i].paper_size == 1){
                    //print 58mm
                    if (res) {
                      if(kitchenListLayout58mm == null || kitchenListLayout58mm.print_combine_kitchen_list == 0 || orderDetailList.length == 1){
                        var bluetooth_data = await DefaultKitchenListLayout().printKitchenList58mm(true, orderCacheLocalId, orderDetail: orderDetailList[k]);
                        await PrintBluetoothThermal.writeBytes(bluetooth_data);
                      } else if(kitchenListLayout58mm.print_combine_kitchen_list == 1 && printCombinedKitchenList == false) {
                        List<OrderDetail> groupedOrderDetails = groupOrderDetailsByCategory(orderDetailList, data);
                        var bluetooth_data = await CombineKitchenListLayout().printCombinedKitchenList58mm(true, orderCacheLocalId, orderDetailList: groupedOrderDetails, combineListTotal: combineListTotal);
                        await PrintBluetoothThermal.writeBytes(bluetooth_data);
                        printCombinedKitchenList = true;
                      }
                      await Future.delayed(Duration(milliseconds: 100));
                    } else {
                      failedPrintOrderDetail.add(orderDetailList[k]);
                    }
                  } else {
                    //print bluetooth 35mm
                    int totalItem = 0;
                    // get total item in order
                    for (int x = 0; x < orderDetail.length; x++)
                      for (int y = 0; y < int.parse(orderDetail[x].quantity!); y++)
                        totalItem += 1;

                    for (int j = 0; j < int.parse(orderDetail[k].quantity!); j++) {
                      currentItem++;
                      var data = Uint8List.fromList(
                          await ReceiptLayout().printLabel35mm(true, orderCacheLocalId, totalItem, currentItem, orderDetail: orderDetail[k]));
                      bool? isConnected = await flutterUsbPrinter.connect(
                          int.parse(printerDetail['vendorId']), int.parse(printerDetail['productId']));
                      if (isConnected == true) {
                        await flutterUsbPrinter.write(data);
                      } else {
                        failedPrintOrderDetail.add(orderDetail[k]);
                      }
                    }
                  }
                }
              }
            }
          }
        }
      }
      return failedPrintOrderDetail;
    } catch (e){
      print('QR Kitchen Printing Error: ${e}');
      FLog.error(
        className: "print_receipt",
        text: "print qr kitchen list error",
        exception: "$e",
      );
      return failedPrintOrderDetail;
    }
  }

  printCancelReceipt(List<Printer> printerList, String orderCacheId, String dateTime) async {
    try {
      int printStatus = 0;
      for (int i = 0; i < printerList.length; i++) {
        if(printerList[i].printer_status == 1 && printerList[i].is_counter == 1){
          var printerDetail = jsonDecode(printerList[i].value!);
          if (printerList[i].type == 0) {
            if(printerList[i].paper_size == 0){
              var data = Uint8List.fromList(await ReceiptLayout().printDeleteItemList80mm(true, orderCacheId, dateTime));
              bool? isConnected = await flutterUsbPrinter.connect(
                  int.parse(printerDetail['vendorId']),
                  int.parse(printerDetail['productId']));
              if (isConnected == true) {
                await flutterUsbPrinter.write(data);
                printStatus = 0;
              } else {
                print('not connected');
                printStatus = 1;
              }
            } else {
              var data = Uint8List.fromList(await ReceiptLayout().printDeleteItemList58mm(true, orderCacheId, dateTime));
              bool? isConnected = await flutterUsbPrinter.connect(
                  int.parse(printerDetail['vendorId']),
                  int.parse(printerDetail['productId']));
              if (isConnected == true) {
                await flutterUsbPrinter.write(data);
                printStatus = 0;
              } else {
                print('not connected');
                printStatus = 1;
              }
            }
          } else if(printerList[i].type == 1) {
            //check paper size (print LAN)
            if(printerList[i].paper_size == 0){
              //print LAN
              final profile = await CapabilityProfile.load();
              final printer = NetworkPrinter(PaperSize.mm80, profile);
              final PosPrintResult res = await printer.connect(printerDetail, port: 9100, timeout: duration);

              if (res == PosPrintResult.success) {
                await ReceiptLayout().printDeleteItemList80mm(false, orderCacheId, dateTime, value: printer);
                await Future.delayed(Duration(milliseconds: 100));
                printer.disconnect();
                printStatus = 0;
              } else if (res == PosPrintResult.timeout){
                print('printer time out');
                printStatus = 2;
                // Fluttertoast.showToast(
                //     backgroundColor: Colors.orangeAccent,
                //     msg: "${AppLocalizations.of(context)?.translate('lan_printer_timeout')}");
              } else {
                print('not connected');
                printStatus = 1;
              }
            } else {
              //print LAN
              final profile = await CapabilityProfile.load();
              final printer = NetworkPrinter(PaperSize.mm58, profile);
              final PosPrintResult res = await printer.connect(printerDetail, port: 9100, timeout: duration);

              if (res == PosPrintResult.success) {
                await ReceiptLayout().printDeleteItemList58mm(false, orderCacheId, dateTime, value: printer);
                await Future.delayed(Duration(milliseconds: 100));
                printer.disconnect();
                printStatus = 0;
              } else if (res == PosPrintResult.timeout){
                print('printer time out');
                printStatus = 2;
                // Fluttertoast.showToast(
                //     backgroundColor: Colors.orangeAccent,
                //     msg: "${AppLocalizations.of(context)?.translate('lan_printer_timeout')}");
              } else {
                print('not connected');
                printStatus = 1;
              }
            }
          } else {
            //print bluetooth
            bool res = await bluetoothPrinterConnect(printerDetail);
            if (printerList[i].paper_size == 0) {
              if (res) {
                await PrintBluetoothThermal.writeBytes(await ReceiptLayout().printDeleteItemList80mm(true, orderCacheId, dateTime, value: printerDetail));
                await Future.delayed(Duration(milliseconds: 100));
                printStatus = 0;
              } else {
                print('not connected');
                printStatus = 1;
              }
            } else {
              if (res) {
                await PrintBluetoothThermal.writeBytes(await ReceiptLayout().printDeleteItemList58mm(true, orderCacheId, dateTime, value: printerDetail));
                await Future.delayed(Duration(milliseconds: 100));
                printStatus = 0;
              } else {
                print('not connected');
                printStatus = 1;
              }
            }
          }
        }
      }
      return printStatus;
    } catch (e) {
      print('Printer Connection Error');
      return 0;
      //response = 'Failed to get platform version.';
    }
  }

  printKitchenDeleteList(List<Printer> printerList, String orderCacheId, String category_id, String dateTime, CartModel cart) async {
    try {
      int printStatus = 0;
      for (int i = 0; i < printerList.length; i++) {
        if(printerList[i].printer_status == 1){
          List<PrinterLinkCategory> data = await PosDatabase.instance.readPrinterLinkCategory(printerList[i].printer_sqlite_id!);
          for (int j = 0; j < data.length; j++) {
            if (category_id == data[j].category_sqlite_id) {
              var printerDetail = jsonDecode(printerList[i].value!);
              if (printerList[i].type == 0) {
                if(printerList[i].paper_size == 0){
                  var data = Uint8List.fromList(await ReceiptLayout().printDeleteItemList80mm(true, orderCacheId, dateTime));
                  bool? isConnected = await flutterUsbPrinter.connect(
                      int.parse(printerDetail['vendorId']),
                      int.parse(printerDetail['productId']));
                  if (isConnected == true) {
                    await flutterUsbPrinter.write(data);
                    printStatus = 0;
                  } else {
                    print('not connected');
                    printStatus = 1;
                  }
                }else {
                  var data = Uint8List.fromList(await ReceiptLayout().printDeleteItemList58mm(true, orderCacheId, dateTime));
                  bool? isConnected = await flutterUsbPrinter.connect(
                      int.parse(printerDetail['vendorId']),
                      int.parse(printerDetail['productId']));
                  if (isConnected == true) {
                    await flutterUsbPrinter.write(data);
                    printStatus = 0;
                  } else {
                    print('not connected');
                    printStatus = 1;
                  }
                }
              } else if(printerList[i].type == 1) {
                //check paper size
                if(printerList[i].paper_size == 0){
                  //print LAN 80mm
                  final profile = await CapabilityProfile.load();
                  final printer = NetworkPrinter(PaperSize.mm80, profile);
                  final PosPrintResult res = await printer.connect(printerDetail, port: 9100, timeout: duration);

                  if (res == PosPrintResult.success) {
                    await ReceiptLayout().printDeleteItemList80mm(false, orderCacheId, dateTime, value: printer);
                    await Future.delayed(Duration(milliseconds: 100));
                    printer.disconnect();
                    printStatus = 0;
                  } else if (res == PosPrintResult.timeout){
                    print('printer time out');
                    printStatus = 2;
                    break;
                    // Fluttertoast.showToast(
                    //     backgroundColor: Colors.orangeAccent,
                    //     msg: "${AppLocalizations.of(context)?.translate('lan_printer_timeout')}");
                  } else {
                    print('not connected');
                    printStatus = 1;
                    break;
                  }
                } else {
                  //print LAN 58mm
                  final profile = await CapabilityProfile.load();
                  final printer = NetworkPrinter(PaperSize.mm58, profile);
                  final PosPrintResult res = await printer.connect(printerDetail, port: 9100, timeout: duration);

                  if (res == PosPrintResult.success) {
                    await ReceiptLayout().printDeleteItemList58mm(false, orderCacheId, dateTime, value: printer);
                    await Future.delayed(Duration(milliseconds: 100));
                    printer.disconnect();
                    printStatus = 0;
                  } else if (res == PosPrintResult.timeout){
                    print('printer time out');
                    printStatus = 2;
                    break;
                    // Fluttertoast.showToast(
                    //     backgroundColor: Colors.orangeAccent,
                    //     msg: "${AppLocalizations.of(context)?.translate('lan_printer_timeout')}");
                  } else {
                    print('not connected');
                    printStatus = 1;
                    break;
                  }
                }
              } else {
                //print bluetooth
                bool res = await bluetoothPrinterConnect(printerDetail);
                if (printerList[i].paper_size == 0) {
                  if (res) {
                    await PrintBluetoothThermal.writeBytes(await ReceiptLayout().printDeleteItemList80mm(true, orderCacheId, dateTime, value: printerDetail));
                    await Future.delayed(Duration(milliseconds: 100));
                    printStatus = 0;
                  } else {
                    printStatus = 1;
                  }
                } else {
                  if (res) {
                    await PrintBluetoothThermal.writeBytes(await ReceiptLayout().printDeleteItemList58mm(true, orderCacheId, dateTime, value: printerDetail));
                    await Future.delayed(Duration(milliseconds: 100));
                    printStatus = 0;
                  } else {
                    printStatus = 1;
                  }
                }
              }
            }
          }
        }
      }
      return printStatus;
    } catch (e) {
      print('Printer Connection Error');
      return 0;
      //response = 'Failed to get platform version.';
    }
  }

  printSettlementList(List<Printer> printerList, String dateTime, Settlement settlement) async {
    try {
      int printStatus = 0;
      if(printerList.isNotEmpty){
        for (int i = 0; i < printerList.length; i++) {
          if(printerList[i].printer_status == 1 && printerList[i].is_counter == 1){
            var printerDetail = jsonDecode(printerList[i].value!);
            if (printerList[i].type == 0) {
              if(printerList[i].paper_size == 0){
                //print USB 80mm
                var data = Uint8List.fromList(await ReceiptLayout().printSettlementList80mm(true, dateTime, settlement));
                bool? isConnected = await flutterUsbPrinter.connect(
                    int.parse(printerDetail['vendorId']),
                    int.parse(printerDetail['productId']));
                if (isConnected == true) {
                  await flutterUsbPrinter.write(data);
                  printStatus = 0;
                } else {
                  printStatus = 1;
                  // Fluttertoast.showToast(
                  //     backgroundColor: Colors.red,
                  //     msg: "${AppLocalizations.of(context)?.translate('usb_printer_not_connect')}");
                }
              } else {
                //print USB 58mm
                var data = Uint8List.fromList(await ReceiptLayout().printSettlementList58mm(true, dateTime, settlement));
                bool? isConnected = await flutterUsbPrinter.connect(
                    int.parse(printerDetail['vendorId']),
                    int.parse(printerDetail['productId']));
                if (isConnected == true) {
                  await flutterUsbPrinter.write(data);
                  printStatus = 0;
                } else {
                  printStatus = 1;
                  // Fluttertoast.showToast(
                  //     backgroundColor: Colors.red,
                  //     msg: "${AppLocalizations.of(context)?.translate('usb_printer_not_connect')}");
                }
              }
            } else if(printerList[i].type == 1) {
              if(printerList[i].paper_size == 0){
                //print LAN 80mm
                final profile = await CapabilityProfile.load();
                final printer = NetworkPrinter(PaperSize.mm80, profile);
                final PosPrintResult res = await printer.connect(printerDetail, port: 9100, timeout: duration);
                if (res == PosPrintResult.success) {
                  await ReceiptLayout().printSettlementList80mm(false, dateTime, settlement, value: printer);
                  await Future.delayed(Duration(milliseconds: 100));
                  printer.disconnect();
                  printStatus = 0;
                } else if (res == PosPrintResult.timeout){
                  print('printer time out');
                  printStatus = 2;
                  // Fluttertoast.showToast(
                  //     backgroundColor: Colors.orangeAccent,
                  //     msg: "${AppLocalizations.of(context)?.translate('lan_printer_timeout')}");
                } else {
                  printStatus = 1;
                  // Fluttertoast.showToast(
                  //     backgroundColor: Colors.red,
                  //     msg: "${AppLocalizations.of(context)?.translate('lan_printer_not_connect')}");
                }
              } else {
                //print LAN 58mm
                final profile = await CapabilityProfile.load();
                final printer = NetworkPrinter(PaperSize.mm58, profile);
                final PosPrintResult res = await printer.connect(printerDetail, port: 9100, timeout: duration);
                if (res == PosPrintResult.success) {
                  await ReceiptLayout().printSettlementList58mm(false, dateTime, settlement, value: printer);
                  await Future.delayed(Duration(milliseconds: 100));
                  printer.disconnect();
                  printStatus = 0;
                } else if (res == PosPrintResult.timeout){
                  print('printer time out');
                  printStatus = 2;
                  // Fluttertoast.showToast(
                  //     backgroundColor: Colors.orangeAccent,
                  //     msg: "${AppLocalizations.of(context)?.translate('lan_printer_timeout')}");
                } else {
                  printStatus = 1;
                  // Fluttertoast.showToast(
                  //     backgroundColor: Colors.red,
                  //     msg: "${AppLocalizations.of(context)?.translate('lan_printer_not_connect')}");
                }
              }
            } else {
              //print bluetooth
              bool res = await bluetoothPrinterConnect(printerDetail);
              if (printerList[i].paper_size == 0) {
                if (res) {
                  await PrintBluetoothThermal.writeBytes(await ReceiptLayout().printSettlementList80mm(true, dateTime, settlement, value: printerDetail));
                  await Future.delayed(Duration(milliseconds: 100));
                  printStatus = 0;
                } else {
                  printStatus = 1;
                }
              } else {
                if (res) {
                  await PrintBluetoothThermal.writeBytes(await ReceiptLayout().printSettlementList58mm(true, dateTime, settlement, value: printerDetail));
                  await Future.delayed(Duration(milliseconds: 100));
                  printStatus = 0;
                } else {
                  printStatus = 1;
                }
              }
            }
          }
        }
      } else {
        printStatus = 3;
      }
      return printStatus;
    } catch (e) {
      FLog.error(
        className: "print_receipt",
        text: "print settlement list error",
        exception: "$e",
      );
      print('Printer Connection Error: ${e}');
      return 0;
      //response = 'Failed to get platform version.';
    }
  }

  printCashBalanceList(List<Printer> printerList, context, {required cashBalance}) async {
    print("printCashBalanceList called");
    try {
      for (int i = 0; i < printerList.length; i++) {
        if(printerList[i].printer_status == 1 && printerList[i].is_counter == 1){
          var printerDetail = jsonDecode(printerList[i].value!);
          if (printerList[i].type == 0) {
            if (printerList[i].paper_size == 0) {
              //print usb 80mm
              var data = Uint8List.fromList(await ReceiptLayout().printCashBalanceList80mm(true, cashBalance));
              bool? isConnected = await flutterUsbPrinter.connect(int.parse(printerDetail['vendorId']), int.parse(printerDetail['productId']));
              if (isConnected == true) {
                await flutterUsbPrinter.write(data);
              } else {
                Fluttertoast.showToast(backgroundColor: Colors.red, msg: "${AppLocalizations.of(context)?.translate('usb_printer_not_connect')}");
              }
            } else {
              //print usb 58mm
              var data = Uint8List.fromList(await ReceiptLayout().printCashBalanceList58mm(true, cashBalance));
              bool? isConnected = await flutterUsbPrinter.connect(int.parse(printerDetail['vendorId']), int.parse(printerDetail['productId']));
              if (isConnected == true) {
                await flutterUsbPrinter.write(data);
              } else {
                Fluttertoast.showToast(backgroundColor: Colors.red, msg: "${AppLocalizations.of(context)?.translate('usb_printer_not_connect')}");
              }
            }
          } else if(printerList[i].type == 1) {
            //print LAN
            if (printerList[i].paper_size == 0) {
              //print 80mm
              final profile = await CapabilityProfile.load();
              final printer = NetworkPrinter(PaperSize.mm80, profile);
              final PosPrintResult res = await printer.connect(printerDetail, port: 9100, timeout: duration);
              if (res == PosPrintResult.success) {
                await ReceiptLayout().printCashBalanceList80mm(false, cashBalance, value: printer);
                await Future.delayed(Duration(milliseconds: 100));
                printer.disconnect();
              } else if (res == PosPrintResult.timeout){
                print('printer time out');
                Fluttertoast.showToast(
                    backgroundColor: Colors.orangeAccent,
                    msg: "${AppLocalizations.of(context)?.translate('lan_printer_timeout')}");
              } else {
                Fluttertoast.showToast(backgroundColor: Colors.red, msg: "${AppLocalizations.of(context)?.translate('lan_printer_not_connect')}");
              }
            } else {
              //print 58mm
              final profile = await CapabilityProfile.load();
              final printer = NetworkPrinter(PaperSize.mm58, profile);
              final PosPrintResult res = await printer.connect(printerDetail, port: 9100, timeout: duration);
              if (res == PosPrintResult.success) {
                await ReceiptLayout().printCashBalanceList58mm(false, cashBalance, value: printer);
                await Future.delayed(Duration(milliseconds: 100));
                printer.disconnect();
              } else if (res == PosPrintResult.timeout){
                print('printer time out');
                Fluttertoast.showToast(
                    backgroundColor: Colors.orangeAccent,
                    msg: "${AppLocalizations.of(context)?.translate('lan_printer_timeout')}");
              } else {
                Fluttertoast.showToast(backgroundColor: Colors.red, msg: "${AppLocalizations.of(context)?.translate('lan_printer_not_connect')}");
              }
            }
          } else {
            //print bluetooth
            bool res = await bluetoothPrinterConnect(printerDetail);
            if (printerList[i].paper_size == 0) {
              if (res) {
                await PrintBluetoothThermal.writeBytes(await ReceiptLayout().printCashBalanceList80mm(true, cashBalance));
                await Future.delayed(Duration(milliseconds: 100));
              } else {
                Fluttertoast.showToast(backgroundColor: Colors.red, msg: "${AppLocalizations.of(context)?.translate('bluetooth_printer_not_connect')}");
              }
            } else {
              if (res) {
                await PrintBluetoothThermal.writeBytes(await ReceiptLayout().printCashBalanceList58mm(true, cashBalance));
                await Future.delayed(Duration(milliseconds: 100));
              } else {
                Fluttertoast.showToast(backgroundColor: Colors.red, msg: "${AppLocalizations.of(context)?.translate('bluetooth_printer_not_connect')}");
              }
            }
          }
        }
      }
    } catch (e) {
      print(e);
      print('Printer Connection Error');
      //response = 'Failed to get platform version.';
    }
  }

  printChangeTableList(List<Printer> printerList, {lastTable, newTable}) async {
    try {
      int printStatus = 0;
      for (int i = 0; i < printerList.length; i++) {
        if(printerList[i].printer_status == 1){
          var printerDetail = jsonDecode(printerList[i].value!);
          if (printerList[i].type == 0) {
            //print USB 80mm
            if (printerList[i].paper_size == 0) {
              var data = Uint8List.fromList(await ReceiptLayout().printChangeTableList80mm(true, fromTable: lastTable, toTable: newTable));
              bool? isConnected = await flutterUsbPrinter.connect(int.parse(printerDetail['vendorId']), int.parse(printerDetail['productId']));
              if (isConnected == true) {
                await flutterUsbPrinter.write(data);
                printStatus = 0;
              } else {
                printStatus = 1;
                // Fluttertoast.showToast(
                //     backgroundColor: Colors.red,
                //     msg: "${AppLocalizations.of(context)?.translate('usb_printer_not_connect')}");
              }
            } else {
              var data = Uint8List.fromList(await ReceiptLayout().printChangeTableList58mm(true, fromTable: lastTable, toTable: newTable));
              bool? isConnected = await flutterUsbPrinter.connect(
                  int.parse(printerDetail['vendorId']), int.parse(printerDetail['productId']));
              if (isConnected == true) {
                await flutterUsbPrinter.write(data);
                printStatus = 0;
              } else {
                printStatus = 1;
                // Fluttertoast.showToast(
                //     backgroundColor: Colors.red,
                //     msg: "${AppLocalizations.of(context)?.translate('usb_printer_not_connect')}");
              }
            }
          } else if(printerList[i].type == 1) {
            if (printerList[i].paper_size == 0) {
              //print LAN 80mm paper
              final profile = await CapabilityProfile.load();
              final printer = NetworkPrinter(PaperSize.mm80, profile);
              final PosPrintResult res = await printer.connect(printerDetail, port: 9100);
              if (res == PosPrintResult.success) {
                await ReceiptLayout().printChangeTableList80mm(false, value: printer, fromTable: lastTable, toTable: newTable);
                printStatus = 0;
                await Future.delayed(Duration(milliseconds: 100));
                printer.disconnect();
              } else if (res == PosPrintResult.timeout) {
                printStatus = 2;
                // Fluttertoast.showToast(
                //     backgroundColor: Colors.red,
                //     msg: "${AppLocalizations.of(context)?.translate('lan_printer_not_connect')}");
              } else {
                printStatus = 1;
              }
            } else {
              //print LAN 58mm paper
              final profile = await CapabilityProfile.load();
              final printer = NetworkPrinter(PaperSize.mm58, profile);
              final PosPrintResult res = await printer.connect(printerDetail, port: 9100);
              if (res == PosPrintResult.success) {
                await ReceiptLayout().printChangeTableList58mm(false, value: printer, fromTable: lastTable, toTable: newTable);
                printStatus = 0;
                await Future.delayed(Duration(milliseconds: 100));
                printer.disconnect();
              } else if(res == PosPrintResult.timeout) {
                printStatus = 2;
                // Fluttertoast.showToast(
                //     backgroundColor: Colors.red,
                //     msg: "${AppLocalizations.of(context)?.translate('lan_printer_not_connect')}");
              } else {
                printStatus = 1;
              }
            }
          } else {
            //print bluetooth
            bool res = await bluetoothPrinterConnect(printerDetail);
            if (printerList[i].paper_size == 0) {
              if (res) {
                await PrintBluetoothThermal.writeBytes(await ReceiptLayout().printChangeTableList80mm(true, fromTable: lastTable, toTable: newTable));
                printStatus = 0;
                await Future.delayed(Duration(milliseconds: 100));
              } else {
                printStatus = 1;
              }
            } else {
              if (res) {
                await PrintBluetoothThermal.writeBytes(await ReceiptLayout().printChangeTableList58mm(true, fromTable: lastTable, toTable: newTable));
                printStatus = 0;
                await Future.delayed(Duration(milliseconds: 100));
              } else {
                printStatus = 1;
              }
            }
          }
        }
      }
      return printStatus;
    } catch (e) {
      print('Printer Connection Error: ${e}');
      return 5;
      // Fluttertoast.showToast(
      //     backgroundColor: Colors.red,
      //     msg: "${AppLocalizations.of(context)?.translate('printing_error')}");
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