import 'dart:convert';
import 'dart:typed_data';
import 'package:assets_audio_player/assets_audio_player.dart';
import 'package:esc_pos_printer/esc_pos_printer.dart';
import 'package:esc_pos_utils/esc_pos_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_usb_printer/flutter_usb_printer.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:pos_system/object/app_setting.dart';
import 'package:pos_system/object/checklist.dart';
import 'package:pos_system/object/kitchen_list.dart';
import 'package:pos_system/object/printer.dart';
import 'package:pos_system/object/printer_link_category.dart';
import 'package:pos_system/object/receipt.dart';
import 'package:pos_system/object/receipt_layout.dart';
import 'package:pos_system/object/settlement.dart';
import 'package:pos_system/object/table.dart';
import 'package:pos_system/object/table_use_detail.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../database/pos_database.dart';
import '../notifier/cart_notifier.dart';
import '../translation/AppLocalizations.dart';
import 'order_cache.dart';
import 'order_detail.dart';
import 'order_modifier_detail.dart';

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

  getDeviceList() async {
    var devices;
    List<Map<String, dynamic>> results = [];
    results = await FlutterUsbPrinter.getUSBDeviceList();
    if(results.isNotEmpty){
       return devices = jsonEncode(results[0]);
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
      for (int i = 0; i < printerList.length; i++) {
        var printerDetail = jsonDecode(printerList[i].value!);
        if(printerList[i].paper_size == 0){
          var data = Uint8List.fromList(await ReceiptLayout().testTicket80mm(true));
          bool? isConnected = await flutterUsbPrinter.connect(
              int.parse(printerDetail['vendorId']),
              int.parse(printerDetail['productId']));
          if (isConnected == true) {
            bool? status = await flutterUsbPrinter.write(data);
          } else {
            print('not connected');
          }
        } else if(printerList[i].paper_size == 1){
          print('print 58mm');
          var data = Uint8List.fromList(
              await ReceiptLayout().testTicket58mm(true, null));
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

  cashDrawer(context, {required printerList}) async {
    try{
      int printStatus = 0;
      List<Printer> cashierPrinterList = printerList.where((item) => item.printer_status == 1 && item.is_counter == 1).toList();
      if(cashierPrinterList.isNotEmpty){
        for (int i = 0; i < cashierPrinterList.length; i++) {
          if (cashierPrinterList[i].type == 0) {
            ReceiptLayout().openCashDrawer(isUSB: true);
            printStatus = 0;
          } else {
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
          }
        }
      } else {
        printStatus = 4;
      }
      return printStatus;
    }catch(e){
      print('Open Cash Drawer Error: ${e}');
      return 1;
    }
  }

  printTestPrintChecklist(List<Printer> cashierPrinter, Checklist checklistLayout, String paperSize) async {
    try{
      for (int i = 0; i < cashierPrinter.length; i++) {
        var printerDetail = jsonDecode(cashierPrinter[i].value!);
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
        } else {
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
        }
      }
    } catch(e){
      print("test print fail: ${e}");
    }
  }

  printTestPrintKitchenList(List<Printer> cashierPrinter, KitchenList KitchenListLayout, String paperSize) async {
    try{
      for (int i = 0; i < cashierPrinter.length; i++) {
        var printerDetail = jsonDecode(cashierPrinter[i].value!);
        if (cashierPrinter[i].type == 0) {
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
        } else {
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
        } else {
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
              var data = Uint8List.fromList(await ReceiptLayout().printReceipt80mm(true, orderId, selectedTableList));
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
                  await ReceiptLayout().printReceipt58mm(true, orderId, selectedTableList));
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
          } else {
            if (cashierPrinterList[i].paper_size == 0) {
              //print LAN 80mm
              final profile = await CapabilityProfile.load();
              final printer = NetworkPrinter(PaperSize.mm80, profile);
              final PosPrintResult res = await printer.connect(printerDetail, port: 9100, timeout: duration);

              if (res == PosPrintResult.success) {
                await ReceiptLayout().printReceipt80mm(false, orderId, selectedTableList, value: printer);
                printer.disconnect();
                printStatus = 0;
              } else if (res == PosPrintResult.timeout){
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
                await ReceiptLayout().printReceipt58mm(false, orderId, selectedTableList,value: printer);
                printer.disconnect();
                printStatus = 0;
              } else if (res == PosPrintResult.timeout){
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
          }
        }
      }
      return printStatus;
    } catch (e) {
      print('Printer Connection Error cart: ${e}');
      return 1;
      // Fluttertoast.showToast(
      //     backgroundColor: Colors.red,
      //     msg: "${AppLocalizations.of(context)?.translate('printing_error')}");
    }
  }

  printReviewReceipt(List<Printer> printerList, List<PosTable> selectedTableList, CartModel cartModel, context) async {
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
                  await ReceiptLayout().printPreviewReceipt80mm(true, selectedTableList, cartModel));
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
                  await ReceiptLayout().printPreviewReceipt58mm(true, selectedTableList, cartModel));
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
          } else {
            if (cashierPrinterList[i].paper_size == 0) {
              //print LAN 80mm
              final profile = await CapabilityProfile.load();
              final printer = NetworkPrinter(PaperSize.mm80, profile);
              final PosPrintResult res = await printer.connect(printerDetail, port: 9100, timeout: duration);

              if (res == PosPrintResult.success) {
                await ReceiptLayout().printPreviewReceipt80mm(false, selectedTableList, cartModel, value: printer);
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
                await ReceiptLayout().printPreviewReceipt58mm(false, selectedTableList, cartModel, value: printer);
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
          }
        }
      }
      return printStatus;
    }catch(e){
      print('Printer Connection Error cart: ${e}');
      return 1;
    }

  }

  printCartReceiptList(List<Printer> printerList, CartModel cart, String localOrderId, context) async {
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
                    await ReceiptLayout().printReceipt80mm(true, localOrderId, cart.selectedTable, isRefund: cart.cartNotifierItem[0].isRefund));
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
                var data = Uint8List.fromList(
                    await ReceiptLayout().printReceipt58mm(true, localOrderId, cart.selectedTable, isRefund: cart.cartNotifierItem[0].isRefund));
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
            } else {
              //print LAN 80mm
              if (cashierPrinterList[i].paper_size == 0) {
                final profile = await CapabilityProfile.load();
                final printer = NetworkPrinter(PaperSize.mm80, profile);
                final PosPrintResult res = await printer.connect(printerDetail, port: 9100, timeout: duration);
                if (res == PosPrintResult.success) {
                  await ReceiptLayout().printReceipt80mm(false, localOrderId, cart.selectedTable, value: printer, isRefund: cart.cartNotifierItem[0].isRefund);
                  printer.disconnect();
                  printStatus = 0;
                }  else if (res == PosPrintResult.timeout){
                  print('printer time out');
                  printStatus = 2;
                  // Fluttertoast.showToast(
                  //     backgroundColor: Colors.orangeAccent,
                  //     msg: "${AppLocalizations.of(context)?.translate('lan_printer_timeout')}");
                }
                else {
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
                  await ReceiptLayout().printReceipt58mm(false, localOrderId, cart.selectedTable,value: printer, isRefund: cart.cartNotifierItem[0].isRefund);
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
            }
          }
        }
      }
      return printStatus;
    } catch (e) {
      print('Printer Connection Error cart: ${e}');
      return 1;
      // Fluttertoast.showToast(
      //     backgroundColor: Colors.red,
      //     msg: "${AppLocalizations.of(context)?.translate('printing_error')}");
    }
  }

  printCheckList(List<Printer> printerList, int orderCacheLocalId) async {
    print('check list call');
    try {
      int printStatus = 0;
      for (int i = 0; i < printerList.length; i++) {
        print('loop time: ${i+1}');
        if(printerList[i].printer_status == 1 && printerList[i].is_counter == 1){
          var printerDetail = jsonDecode(printerList[i].value!);
          if (printerList[i].type == 0) {
            //print USB 80mm
            if (printerList[i].paper_size == 0) {
              var data = Uint8List.fromList(await ReceiptLayout().printCheckList80mm(true, orderCacheLocalId));
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
              var data = Uint8List.fromList(await ReceiptLayout().printCheckList58mm(true, orderCacheLocalId));
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
          } else {
            if (printerList[i].paper_size == 0) {
              //print LAN 80mm paper
              final profile = await CapabilityProfile.load();
              final printer = NetworkPrinter(PaperSize.mm80, profile);
              final PosPrintResult res = await printer.connect(printerDetail, port: 9100, timeout: duration);
              if (res == PosPrintResult.success) {
                await ReceiptLayout().printCheckList80mm(false, orderCacheLocalId, value: printer);
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
                await ReceiptLayout().printCheckList58mm(false, orderCacheLocalId, value: printer);
                printer.disconnect();
                printStatus = 0;
              } else if (res == PosPrintResult.timeout){
                print('printer time out');
                printStatus = 2;
              } else {
                printStatus =  1;
              }
            }
          }
        }
      }
      print('finish print');
      return printStatus;
    } catch (e) {
      print('Printer Connection Error: ${e}');
      Fluttertoast.showToast(
          backgroundColor: Colors.red,
          msg: "check list error: $e");
      return 5;
    }
  }

  reprintCheckList(List<Printer> printerList, CartModel cartModel, context) async {
    print('reprint celled!!!');
    int printStatus = 0;
    try {
      if(printerList.isNotEmpty){
        for (int i = 0; i < printerList.length; i++) {
          if(printerList[i].printer_status == 1 && printerList[i].is_counter == 1){
            var printerDetail = jsonDecode(printerList[i].value!);
            if (printerList[i].type == 0) {
              //print USB 80mm
              if (printerList[i].paper_size == 0) {
                var data = Uint8List.fromList(await ReceiptLayout().reprintCheckList80mm(true, cartModel));
                bool? isConnected = await flutterUsbPrinter.connect(int.parse(printerDetail['vendorId']), int.parse(printerDetail['productId']));
                if (isConnected == true) {
                  await flutterUsbPrinter.write(data);
                  printStatus = 0;
                } else {
                  printStatus = 1;
                }
              } else {
                //print 58mm
                var data = Uint8List.fromList(await ReceiptLayout().reprintCheckList58mm(true, cartModel));
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
            else {
              if (printerList[i].paper_size == 0) {
                //print LAN 80mm paper
                final profile = await CapabilityProfile.load();
                final printer = NetworkPrinter(PaperSize.mm80, profile);
                final PosPrintResult res = await printer.connect(printerDetail, port: 9100, timeout: duration);
                if (res == PosPrintResult.success) {
                  await ReceiptLayout().reprintCheckList80mm(false, cartModel, value: printer);
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
                  await ReceiptLayout().reprintCheckList58mm(false, cartModel, value: printer);
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
          }
        }
      } else {
        printStatus = 3;
      }
    } catch (e) {
      print('Printer Connection Error: ${e}');
      printStatus = 5;
    }
    return printStatus;
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

  printKitchenList(List<Printer> printerList, int orderCacheLocalId, context) async {
    print("printKitchenList called");
    bool printCombinedKitchenList = false;
    try{
      final prefs = await SharedPreferences.getInstance();
      final int? branch_id = prefs.getInt('branch_id');
      KitchenList? kitchenListLayout58mm = await PosDatabase.instance.readSpecificKitchenList('58');
      KitchenList? kitchenListLayout80mm = await PosDatabase.instance.readSpecificKitchenList('80');
      List<OrderDetail>? failedPrintOrderDetail;
      List<OrderDetail> orderDetail = await PosDatabase.instance.readSpecificOrderDetailByOrderCacheId(orderCacheLocalId.toString());

      int currentItem = 0;
      if(printerList.isNotEmpty){
        failedPrintOrderDetail = [];
        for (int i = 0; i < printerList.length; i++) {
          if(printerList[i].printer_status == 1){
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
                  List<OrderModifierDetail> modDetail = await PosDatabase.instance.readOrderModifierDetail(orderDetail[k].order_detail_sqlite_id.toString());
                  if(modDetail.isNotEmpty){
                    orderDetail[k].orderModifierDetail = modDetail;
                  } else {
                    orderDetail[k].orderModifierDetail = [];
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
                        if(kitchenListLayout80mm == null || kitchenListLayout80mm!.print_combine_kitchen_list == 0 || orderDetail.length == 1)
                          await ReceiptLayout().printKitchenList80mm(false, orderCacheLocalId, value: printer, orderDetail: orderDetail[k]);
                        else if(kitchenListLayout80mm!.print_combine_kitchen_list == 1 && printCombinedKitchenList == false) {
                          await ReceiptLayout().printCombinedKitchenList80mm(false, orderCacheLocalId, value: printer, orderDetailList: orderDetail);
                          printCombinedKitchenList = true;
                        }
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
                        if(kitchenListLayout58mm == null || kitchenListLayout58mm!.print_combine_kitchen_list == 0 || orderDetail.length == 1)
                          await ReceiptLayout().printKitchenList58mm(false, orderCacheLocalId, value: printer, orderDetail: orderDetail[k]);
                        else if(kitchenListLayout58mm!.print_combine_kitchen_list == 1 && printCombinedKitchenList == false) {
                          await ReceiptLayout().printCombinedKitchenList58mm(false, orderCacheLocalId, value: printer, orderDetailList: orderDetail);
                          printCombinedKitchenList = true;
                        }
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
                      print("totalItem: ${totalItem}");

                      for (int j = 0; j < int.parse(orderDetail[k].quantity!); j++) {
                        currentItem++;
                        if (res == PosPrintResult.success) {
                          print("currentItem: ${currentItem}");
                          await ReceiptLayout().printLabel35mm(false, orderCacheLocalId, totalItem, currentItem, value: printer, orderDetail: orderDetail[k]);
                        } else {
                          failedPrintOrderDetail.add(orderDetail[k]);
                        }
                      }
                      printer.disconnect();
                    }
                  } else {
                    //print USB
                    if (printerList[i].paper_size == 0) {
                      var data;
                      if(kitchenListLayout80mm == null || kitchenListLayout80mm!.print_combine_kitchen_list == 0 || orderDetail.length == 1)
                        data = Uint8List.fromList(await ReceiptLayout().printKitchenList80mm(true, orderCacheLocalId, orderDetail: orderDetail[k]));
                      else if(kitchenListLayout80mm!.print_combine_kitchen_list == 1 && printCombinedKitchenList == false) {
                        data = Uint8List.fromList(await ReceiptLayout().printCombinedKitchenList80mm(true, orderCacheLocalId, orderDetailList: orderDetail));
                        printCombinedKitchenList = true;
                      }
                      bool? isConnected = await flutterUsbPrinter.connect(int.parse(printerDetail['vendorId']), int.parse(printerDetail['productId']));
                      if (isConnected == true) {
                        await flutterUsbPrinter.write(data);
                      } else {
                        failedPrintOrderDetail.add(orderDetail[k]);
                      }
                    } else if (printerList[i].paper_size == 1) {
                      //print USB 58mm
                      var data;
                      if(kitchenListLayout58mm == null || kitchenListLayout58mm!.print_combine_kitchen_list == 0 || orderDetail.length == 1)
                        data = Uint8List.fromList(await ReceiptLayout().printKitchenList58mm(true, orderCacheLocalId, orderDetail: orderDetail[k]));
                      else if(kitchenListLayout58mm!.print_combine_kitchen_list == 1 && printCombinedKitchenList == false) {
                        data = Uint8List.fromList(await ReceiptLayout().printCombinedKitchenList58mm(true, orderCacheLocalId, orderDetailList: orderDetail));
                        printCombinedKitchenList = true;
                      }

                      bool? isConnected = await flutterUsbPrinter.connect(
                          int.parse(printerDetail['vendorId']), int.parse(printerDetail['productId']));
                      if (isConnected == true) {
                        await flutterUsbPrinter.write(data);
                      } else {
                        failedPrintOrderDetail.add(orderDetail[k]);
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
      return 5;
    }
  }

  reprintKitchenList(List<Printer> printerList, context, {required List<OrderDetail> reprintList}) async {
    List<OrderDetail>? failedPrintOrderDetail;
    List<OrderDetail> reprintListGroup = [];
    bool printCombinedKitchenList = false;
    int currentItem = 0;
    try{
      final prefs = await SharedPreferences.getInstance();
      final int? branch_id = prefs.getInt('branch_id');
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
                        if(kitchenListLayout80mm == null || kitchenListLayout80mm!.print_combine_kitchen_list == 0 || reprintList.length == 1){
                          await ReceiptLayout().printKitchenList80mm(false, int.parse(reprintList[k].order_cache_sqlite_id!), value: printer, orderDetail: reprintList[k]);
                        } else if(kitchenListLayout80mm!.print_combine_kitchen_list == 1 && printCombinedKitchenList == false) {
                          List<String> distinctTableNumbers = [];
                          List<String> distinctOrderNumbers = [];
                          List<String> distinctDateTime = [];

                          for (OrderDetail orderDetail in reprintList) {
                            print("orderDetail.orderQueue: ${orderDetail.orderQueue}, orderDetail.tableNumber: ${orderDetail.tableNumber}");
                            if (orderDetail.orderQueue != '') {
                              print("orderQueue not null");
                              // distinctOrderNumbers.add(orderDetail.orderQueue!);
                              distinctOrderNumbers = reprintList.map((orderDetail) => orderDetail.orderQueue!).toSet().toList();
                            } else if (orderDetail.tableNumber != null && orderDetail.tableNumber.isNotEmpty) {
                              // distinctTableNumbers.add(orderDetail.tableNumber.map((num) => num.toString()).join(', '));
                              distinctTableNumbers = reprintList.map((orderDetail) => orderDetail.tableNumber.map((num) => num.toString()).join(', ')).toSet().toList();
                            } else {
                              distinctDateTime = reprintList.map((orderDetail) => orderDetail.created_at!).toSet().toList();
                            }
                          }

                          print("distinctOrderNumbers length: ${distinctOrderNumbers.length}");
                          print("distinctTableNumbers length: ${distinctTableNumbers.length}");
                          print("distinctDateTime length: ${distinctDateTime.length}");
                          if(distinctOrderNumbers.length >= 1) {
                            for (String orderNumberFiltered in distinctOrderNumbers) {
                              print("orderNumberFiltered: ${orderNumberFiltered}");
                              List<OrderDetail> filteredOrders = [];
                              filteredOrders.addAll(reprintList.where((orderDetail) => orderDetail.orderQueue! == orderNumberFiltered).toList());
                              if(filteredOrders.length > 1) {
                                await ReceiptLayout().printCombinedKitchenList80mm(
                                  false,
                                  int.parse(filteredOrders.first.order_cache_sqlite_id!),
                                  value: printer,
                                  orderDetailList: filteredOrders,
                                );
                              } else {
                                await ReceiptLayout().printKitchenList80mm(false, int.parse(filteredOrders.first.order_cache_sqlite_id!), value: printer, orderDetail: filteredOrders[0]);
                              }
                              reprintList.removeWhere((orderDetail) => orderDetail.orderQueue! == orderNumberFiltered);
                            }
                          }

                          if(distinctTableNumbers.length >= 1) {
                            for (String tableNumberFiltered in distinctTableNumbers) {
                              print("tableNumberFiltered: ${tableNumberFiltered}");
                              List<OrderDetail> filteredOrders = [];
                              filteredOrders.addAll(reprintList.where((orderDetail) => orderDetail.tableNumber.toString().replaceAll('[', '')?.replaceAll(']', '') == tableNumberFiltered).toList());
                              if(filteredOrders.length > 1) {
                                await ReceiptLayout().printCombinedKitchenList80mm(
                                  false,
                                  int.parse(filteredOrders.first.order_cache_sqlite_id!),
                                  value: printer,
                                  orderDetailList: filteredOrders,
                                );
                              } else {
                                await ReceiptLayout().printKitchenList80mm(false, int.parse(filteredOrders.first.order_cache_sqlite_id!), value: printer, orderDetail: filteredOrders[0]);
                              }
                              reprintList.removeWhere((orderDetail) => orderDetail.tableNumber.toString().replaceAll('[', '')?.replaceAll(']', '') == tableNumberFiltered);
                            }
                          }

                          if(distinctDateTime.length >= 1) {
                            for (String dateTimeFiltered in distinctDateTime) {
                              print("orderNumberFiltered: ${dateTimeFiltered}");
                              List<OrderDetail> filteredOrders = [];
                              filteredOrders.addAll(reprintList.where((orderDetail) => orderDetail.created_at! == dateTimeFiltered).toList());
                              if(filteredOrders.length > 1) {
                                await ReceiptLayout().printCombinedKitchenList80mm(
                                  false,
                                  int.parse(filteredOrders.first.order_cache_sqlite_id!),
                                  value: printer,
                                  orderDetailList: filteredOrders,
                                );
                              } else {
                                await ReceiptLayout().printKitchenList80mm(false, int.parse(filteredOrders.first.order_cache_sqlite_id!), value: printer, orderDetail: filteredOrders[0]);
                              }
                              reprintList.removeWhere((orderDetail) => orderDetail.created_at! == dateTimeFiltered);
                            }
                          }

                          printCombinedKitchenList = true;
                          print("printCombinedKitchenList: ${printCombinedKitchenList}");
                        }
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
                        if(kitchenListLayout58mm == null || kitchenListLayout58mm!.print_combine_kitchen_list == 0 || reprintList.length == 1){
                          await ReceiptLayout().printKitchenList58mm(false, int.parse(reprintList[k].order_cache_sqlite_id!), value: printer, orderDetail: reprintList[k]);
                        } else if(kitchenListLayout58mm!.print_combine_kitchen_list == 1 && printCombinedKitchenList == false) {
                          List<String> distinctTableNumbers = [];
                          List<String> distinctOrderNumbers = [];
                          List<String> distinctDateTime = [];

                          for (OrderDetail orderDetail in reprintList) {
                            print("orderDetail.orderQueue: ${orderDetail.orderQueue}, orderDetail.tableNumber: ${orderDetail.tableNumber}");
                            if (orderDetail.orderQueue != '') {
                              print("orderQueue not null");
                              // distinctOrderNumbers.add(orderDetail.orderQueue!);
                              distinctOrderNumbers = reprintList.map((orderDetail) => orderDetail.orderQueue!).toSet().toList();
                            } else if (orderDetail.tableNumber != null && orderDetail.tableNumber.isNotEmpty) {
                              // distinctTableNumbers.add(orderDetail.tableNumber.map((num) => num.toString()).join(', '));
                              distinctTableNumbers = reprintList.map((orderDetail) => orderDetail.tableNumber.map((num) => num.toString()).join(', ')).toSet().toList();
                            } else {
                              distinctDateTime = reprintList.map((orderDetail) => orderDetail.created_at!).toSet().toList();
                            }
                          }

                          print("distinctOrderNumbers length: ${distinctOrderNumbers.length}");
                          print("distinctTableNumbers length: ${distinctTableNumbers.length}");
                          print("distinctDateTime length: ${distinctDateTime.length}");
                          if(distinctOrderNumbers.length >= 1) {
                            for (String orderNumberFiltered in distinctOrderNumbers) {
                              print("orderNumberFiltered: ${orderNumberFiltered}");
                              List<OrderDetail> filteredOrders = [];
                              filteredOrders.addAll(reprintList.where((orderDetail) => orderDetail.orderQueue! == orderNumberFiltered).toList());
                              if(filteredOrders.length > 1) {
                                await ReceiptLayout().printCombinedKitchenList58mm(
                                  false,
                                  int.parse(filteredOrders.first.order_cache_sqlite_id!),
                                  value: printer,
                                  orderDetailList: filteredOrders,
                                );
                              } else {
                                await ReceiptLayout().printKitchenList58mm(false, int.parse(filteredOrders.first.order_cache_sqlite_id!), value: printer, orderDetail: filteredOrders[0]);
                              }
                              reprintList.removeWhere((orderDetail) => orderDetail.orderQueue! == orderNumberFiltered);
                            }
                          }

                          if(distinctTableNumbers.length >= 1) {
                            for (String tableNumberFiltered in distinctTableNumbers) {
                              print("tableNumberFiltered: ${tableNumberFiltered}");
                              List<OrderDetail> filteredOrders = [];
                              filteredOrders.addAll(reprintList.where((orderDetail) => orderDetail.tableNumber.toString().replaceAll('[', '')?.replaceAll(']', '') == tableNumberFiltered).toList());
                              if(filteredOrders.length > 1) {
                                await ReceiptLayout().printCombinedKitchenList58mm(
                                  false,
                                  int.parse(filteredOrders.first.order_cache_sqlite_id!),
                                  value: printer,
                                  orderDetailList: filteredOrders,
                                );
                              } else {
                                await ReceiptLayout().printKitchenList58mm(false, int.parse(filteredOrders.first.order_cache_sqlite_id!), value: printer, orderDetail: filteredOrders[0]);
                              }
                              reprintList.removeWhere((orderDetail) => orderDetail.tableNumber.toString().replaceAll('[', '')?.replaceAll(']', '') == tableNumberFiltered);
                            }
                          }

                          if(distinctDateTime.length >= 1) {
                            for (String dateTimeFiltered in distinctDateTime) {
                              print("orderNumberFiltered: ${dateTimeFiltered}");
                              List<OrderDetail> filteredOrders = [];
                              filteredOrders.addAll(reprintList.where((orderDetail) => orderDetail.created_at! == dateTimeFiltered).toList());
                              if(filteredOrders.length > 1) {
                                await ReceiptLayout().printCombinedKitchenList58mm(
                                  false,
                                  int.parse(filteredOrders.first.order_cache_sqlite_id!),
                                  value: printer,
                                  orderDetailList: filteredOrders,
                                );
                              } else {
                                await ReceiptLayout().printKitchenList58mm(false, int.parse(filteredOrders.first.order_cache_sqlite_id!), value: printer, orderDetail: filteredOrders[0]);
                              }
                              reprintList.removeWhere((orderDetail) => orderDetail.created_at! == dateTimeFiltered);
                            }
                          }

                          printCombinedKitchenList = true;
                          print("printCombinedKitchenList: ${printCombinedKitchenList}");
                        }
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
                        } else {
                          failedPrintOrderDetail.add(reprintList[k]);
                        }
                      }
                    }
                  } else {
                    //print USB
                    if (printerList[i].paper_size == 0) {
                      var data = Uint8List.fromList(
                          await ReceiptLayout().printKitchenList80mm(true, int.parse(reprintList[k].order_cache_sqlite_id!), orderDetail: reprintList[k]));
                      bool? isConnected = await flutterUsbPrinter.connect(int.parse(printerDetail['vendorId']), int.parse(printerDetail['productId']));
                      if (isConnected == true) {
                        await flutterUsbPrinter.write(data);
                      } else {
                        failedPrintOrderDetail.add(reprintList[k]);
                      }
                    } else if (printerList[i].paper_size == 1) {
                      //print 58mm
                      var data = Uint8List.fromList(
                          await ReceiptLayout().printKitchenList58mm(true, int.parse(reprintList[k].order_cache_sqlite_id!), orderDetail: reprintList[k]));
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
    List<OrderDetail> failedPrintOrderDetail = [];
    try{
      for (int i = 0; i < printerList.length; i++) {
        if(printerList[i].printer_status == 1){
          List<PrinterLinkCategory> data = await PosDatabase.instance.readPrinterLinkCategory(printerList[i].printer_sqlite_id!);
          for (int j = 0; j < data.length; j++) {
            for (int k = 0; k < orderDetailList.length; k++) {
              //check printer category
              if (orderDetailList[k].category_sqlite_id == data[j].category_sqlite_id && orderDetailList[k].status == 0) {
                var printerDetail = jsonDecode(printerList[i].value!);
                //check printer type
                if (printerList[i].type == 1) {
                  //check paper size
                  if (printerList[i].paper_size == 0) {
                    //print LAN
                    final profile = await CapabilityProfile.load();
                    final printer = NetworkPrinter(PaperSize.mm80, profile);
                    final PosPrintResult res = await printer.connect(printerDetail, port: 9100, timeout: duration);

                    if (res == PosPrintResult.success) {
                      await ReceiptLayout().printQrKitchenList80mm(false, orderDetailList[k], orderCacheLocalId, value: printer);
                      printer.disconnect();
                    } else {
                      failedPrintOrderDetail.add(orderDetailList[k]);
                    }
                  } else {
                    //print LAN 58mm
                    final profile = await CapabilityProfile.load();
                    final printer = NetworkPrinter(PaperSize.mm58, profile);
                    final PosPrintResult res = await printer.connect(printerDetail, port: 9100, timeout: duration);

                    if (res == PosPrintResult.success) {
                      await ReceiptLayout().printQrKitchenList58mm(false, orderDetailList[k], orderCacheLocalId, value: printer);
                      printer.disconnect();
                    } else {
                      failedPrintOrderDetail.add(orderDetailList[k]);
                    }
                  }
                } else {
                  //print USB
                  if (printerList[i].paper_size == 0) {
                    var data = Uint8List.fromList(
                        await ReceiptLayout().printQrKitchenList80mm(true, orderDetailList[k], orderCacheLocalId));
                    bool? isConnected = await flutterUsbPrinter.connect(
                        int.parse(printerDetail['vendorId']), int.parse(printerDetail['productId']));
                    if (isConnected == true) {
                      await flutterUsbPrinter.write(data);
                    } else {
                      failedPrintOrderDetail.add(orderDetailList[k]);
                    }
                  } else {
                    //print 58mm
                    var data = Uint8List.fromList(
                        await ReceiptLayout().printQrKitchenList58mm(true, orderDetailList[k], orderCacheLocalId));
                    bool? isConnected = await flutterUsbPrinter.connect(
                        int.parse(printerDetail['vendorId']), int.parse(printerDetail['productId']));
                    if (isConnected == true) {
                      await flutterUsbPrinter.write(data);
                    } else {
                      failedPrintOrderDetail.add(orderDetailList[k]);
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
      print('Printer Connection Error: ${e}');
      return failedPrintOrderDetail = [];
    }
  }

  printDeleteList(List<Printer> printerList, String orderCacheId, String dateTime) async {
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
          } else {
            //check paper size (print LAN)
            if(printerList[i].paper_size == 0){
              //print LAN
              final profile = await CapabilityProfile.load();
              final printer = NetworkPrinter(PaperSize.mm80, profile);
              final PosPrintResult res = await printer.connect(printerDetail, port: 9100, timeout: duration);

              if (res == PosPrintResult.success) {
                await ReceiptLayout().printDeleteItemList80mm(false, orderCacheId, dateTime, value: printer);
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
              } else {
                //check paper size
                if(printerList[i].paper_size == 0){
                  //print LAN 80mm
                  final profile = await CapabilityProfile.load();
                  final printer = NetworkPrinter(PaperSize.mm80, profile);
                  final PosPrintResult res = await printer.connect(printerDetail, port: 9100, timeout: duration);

                  if (res == PosPrintResult.success) {
                    await ReceiptLayout().printDeleteItemList80mm(false, orderCacheId, dateTime, value: printer);
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
            } else {
              if(printerList[i].paper_size == 0){
                //print LAN 80mm
                final profile = await CapabilityProfile.load();
                final printer = NetworkPrinter(PaperSize.mm80, profile);
                final PosPrintResult res = await printer.connect(printerDetail, port: 9100, timeout: duration);
                if (res == PosPrintResult.success) {
                  await ReceiptLayout().printSettlementList80mm(false, dateTime, settlement, value: printer);
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
            }
          }
        }
      } else {
        printStatus = 3;
      }
      return printStatus;
    } catch (e) {
      print('Printer Connection Error: ${e}');
      return 0;
      //response = 'Failed to get platform version.';
    }
  }

  printCashBalanceList(List<Printer> printerList, context, {required cashBalance}) async {
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
          } else {
            //print LAN
            if (printerList[i].paper_size == 0) {
              //print 80mm
              final profile = await CapabilityProfile.load();
              final printer = NetworkPrinter(PaperSize.mm80, profile);
              final PosPrintResult res = await printer.connect(printerDetail, port: 9100, timeout: duration);
              if (res == PosPrintResult.success) {
                await ReceiptLayout().printCashBalanceList80mm(false, cashBalance, value: printer);
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
          } else {
            if (printerList[i].paper_size == 0) {
              //print LAN 80mm paper
              final profile = await CapabilityProfile.load();
              final printer = NetworkPrinter(PaperSize.mm80, profile);
              final PosPrintResult res = await printer.connect(printerDetail, port: 9100);
              if (res == PosPrintResult.success) {
                await ReceiptLayout().printChangeTableList80mm(false, value: printer, fromTable: lastTable, toTable: newTable);
                printStatus = 0;
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

}