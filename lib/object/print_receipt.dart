import 'dart:convert';
import 'dart:typed_data';

import 'package:esc_pos_printer/esc_pos_printer.dart';
import 'package:esc_pos_utils/esc_pos_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_usb_printer/flutter_usb_printer.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:pos_system/object/printer.dart';
import 'package:pos_system/object/printer_link_category.dart';
import 'package:pos_system/object/receipt.dart';
import 'package:pos_system/object/receipt_layout.dart';
import 'package:pos_system/object/settlement.dart';
import 'package:pos_system/object/table.dart';

import '../database/pos_database.dart';
import '../notifier/cart_notifier.dart';
import '../translation/AppLocalizations.dart';

class PrintReceipt{
  FlutterUsbPrinter flutterUsbPrinter = FlutterUsbPrinter();

  readAllPrinters() async {
    List<Printer> printerList = [];
    List<Printer> data = await PosDatabase.instance.readAllBranchPrinter();
    printerList = List.from(data);
    return printerList;
  }

  cashDrawer(context, {required printerList}) async {
    try{
      if(printerList.isNotEmpty){
        for (int i = 0; i < printerList.length; i++) {
          if(printerList[i].printer_status == 1 && printerList[i].is_counter == 1){
            if (printerList[i].type == 0) {
              ReceiptLayout().openCashDrawer(isUSB: true);
            } else {
              var printerDetail = jsonDecode(printerList[i].value!);
              final profile = await CapabilityProfile.load();
              final printer = NetworkPrinter(PaperSize.mm80, profile);
              final PosPrintResult res = await printer.connect(printerDetail, port: 9100);
              if (res == PosPrintResult.success) {
                await ReceiptLayout().openCashDrawer(isUSB: false, value: printer);
                printer.disconnect();
              } else {
                Fluttertoast.showToast(
                    backgroundColor: Colors.red,
                    msg: "${AppLocalizations.of(context)?.translate('lan_printer_not_connect')}");
              }
            }
          }
        }
      }
    }catch(e){
      print('Open Cash Drawer Error: ${e}');
    }
  }

  printPaymentReceiptList(List<Printer> printerList, String orderId, List<PosTable> selectedTableList, context) async {
    try {
      for (int i = 0; i < printerList.length; i++) {
        if(printerList[i].printer_status == 1 && printerList[i].is_counter == 1){
          var printerDetail = jsonDecode(printerList[i].value!);
          if (printerList[i].type == 0) {
            if (printerList[i].paper_size == 0) {
              //print 80mm
              var data = Uint8List.fromList(
                  await ReceiptLayout().printReceipt80mm(true, orderId, selectedTableList));
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
                  await ReceiptLayout().printReceipt58mm(true, orderId, selectedTableList));
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
            if (printerList[i].paper_size == 0) {
              //print LAN 80mm
              final profile = await CapabilityProfile.load();
              final printer = NetworkPrinter(PaperSize.mm80, profile);
              final PosPrintResult res = await printer.connect(printerDetail, port: 9100);

              if (res == PosPrintResult.success) {
                await ReceiptLayout().printReceipt80mm(false, orderId, selectedTableList, value: printer);
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
                await ReceiptLayout().printReceipt58mm(false, orderId, selectedTableList,value: printer);
                printer.disconnect();
              } else {
                Fluttertoast.showToast(
                    backgroundColor: Colors.red,
                    msg: "${AppLocalizations.of(context)?.translate('lan_printer_not_connect')}");
              }
            }
          }
        }
      }
    } catch (e) {
      print('Printer Connection Error cart: ${e}');
      Fluttertoast.showToast(
          backgroundColor: Colors.red,
          msg: "${AppLocalizations.of(context)?.translate('printing_error')}");
    }
  }

  printCartReceiptList(List<Printer> printerList, CartModel cart, String localOrderId, context) async {
    try {
      for (int i = 0; i < printerList.length; i++) {
        if(printerList[i].printer_status == 1 && printerList[i].is_counter == 1){
          var printerDetail = jsonDecode(printerList[i].value!);
          if (printerList[i].type == 0) {
            if (printerList[i].paper_size == 0) {
              var data = Uint8List.fromList(
                  await ReceiptLayout().printReceipt80mm(true, localOrderId, cart.selectedTable, isRefund: cart.cartNotifierItem[0].isRefund));
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
              var data = Uint8List.fromList(
                  await ReceiptLayout().printReceipt58mm(true, localOrderId, cart.selectedTable, isRefund: cart.cartNotifierItem[0].isRefund));
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
            //print LAN 80mm
            if (printerList[i].paper_size == 0) {
              final profile = await CapabilityProfile.load();
              final printer = NetworkPrinter(PaperSize.mm80, profile);
              final PosPrintResult res = await printer.connect(printerDetail, port: 9100);
              if (res == PosPrintResult.success) {
                await ReceiptLayout().printReceipt80mm(false, localOrderId, cart.selectedTable, value: printer, isRefund: cart.cartNotifierItem[0].isRefund);
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
                await ReceiptLayout().printReceipt58mm(false, localOrderId, cart.selectedTable,value: printer, isRefund: cart.cartNotifierItem[0].isRefund);
                printer.disconnect();
              } else {
                Fluttertoast.showToast(
                    backgroundColor: Colors.red,
                    msg: "${AppLocalizations.of(context)?.translate('lan_printer_not_connect')}");
              }
            }
          }
        }
      }
    } catch (e) {
      print('Printer Connection Error cart: ${e}');
      Fluttertoast.showToast(
          backgroundColor: Colors.red,
          msg: "${AppLocalizations.of(context)?.translate('printing_error')}");
    }
  }

  printCheckList(List<Printer> printerList, int orderCacheLocalId, context) async {
    print('check list call');
    try {
      for (int i = 0; i < printerList.length; i++) {
        if(printerList[i].printer_status == 1 && printerList[i].is_counter == 1){
          var printerDetail = jsonDecode(printerList[i].value!);
          if (printerList[i].type == 0) {
            //print USB 80mm
            if (printerList[i].paper_size == 0) {
              var data = Uint8List.fromList(await ReceiptLayout().printCheckList80mm(true, orderCacheLocalId));
              bool? isConnected = await flutterUsbPrinter.connect(int.parse(printerDetail['vendorId']), int.parse(printerDetail['productId']));
              if (isConnected == true) {
                await flutterUsbPrinter.write(data);
              } else {
                Fluttertoast.showToast(
                    backgroundColor: Colors.red,
                    msg: "${AppLocalizations.of(context)?.translate('usb_printer_not_connect')}");
              }
            } else {
              //print 58mm
              var data = Uint8List.fromList(await ReceiptLayout().printCheckList58mm(true, orderCacheLocalId));
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
            if (printerList[i].paper_size == 0) {
              //print LAN 80mm paper
              final profile = await CapabilityProfile.load();
              final printer = NetworkPrinter(PaperSize.mm80, profile);
              final PosPrintResult res = await printer.connect(printerDetail, port: 9100);
              if (res == PosPrintResult.success) {
                await ReceiptLayout().printCheckList80mm(false, orderCacheLocalId, value: printer);
                printer.disconnect();
              } else {
                Fluttertoast.showToast(
                    backgroundColor: Colors.red,
                    msg: "${AppLocalizations.of(context)?.translate('lan_printer_not_connect')}");
              }
            } else {
              //print LAN 58mm paper
              final profile = await CapabilityProfile.load();
              final printer = NetworkPrinter(PaperSize.mm58, profile);
              final PosPrintResult res = await printer.connect(printerDetail, port: 9100);
              if (res == PosPrintResult.success) {
                await ReceiptLayout().printCheckList58mm(false, orderCacheLocalId, value: printer);
                printer.disconnect();
              } else {
                Fluttertoast.showToast(
                    backgroundColor: Colors.red,
                    msg: "${AppLocalizations.of(context)?.translate('lan_printer_not_connect')}");
              }
            }
          }
        }
      }
    } catch (e) {
      print('Printer Connection Error: ${e}');
      Fluttertoast.showToast(
          backgroundColor: Colors.red,
          msg: "${AppLocalizations.of(context)?.translate('printing_error')}");
    }
  }

  printKitchenList(List<Printer> printerList, context, CartModel cart, int orderCacheLocalId) async {
    try{
      for (int i = 0; i < printerList.length; i++) {
        if(printerList[i].printer_status == 1 && printerList[i].is_counter == 0){
          List<PrinterLinkCategory> data = await PosDatabase.instance.readPrinterLinkCategory(printerList[i].printer_sqlite_id!);
          for (int j = 0; j < data.length; j++) {
            for (int k = 0; k < cart.cartNotifierItem.length; k++) {
              //check printer category
              if (cart.cartNotifierItem[k].category_sqlite_id == data[j].category_sqlite_id && cart.cartNotifierItem[k].status == 0) {
                var printerDetail = jsonDecode(printerList[i].value!);
                //check printer type
                if (printerList[i].type == 1) {
                  //check paper size
                  if (printerList[i].paper_size == 0) {
                    //print LAN
                    final profile = await CapabilityProfile.load();
                    final printer = NetworkPrinter(PaperSize.mm80, profile);
                    final PosPrintResult res = await printer.connect(printerDetail, port: 9100);

                    if (res == PosPrintResult.success) {
                      await ReceiptLayout()
                          .printKitchenList80mm(false, cart.cartNotifierItem[k], orderCacheLocalId, value: printer);
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
                      await ReceiptLayout()
                          .printKitchenList58mm(false, cart.cartNotifierItem[k], orderCacheLocalId, value: printer);
                      printer.disconnect();
                    } else {
                      Fluttertoast.showToast(
                          backgroundColor: Colors.red,
                          msg: "${AppLocalizations.of(context)?.translate('lan_printer_not_connect')}");
                    }
                  }
                } else {
                  //print USB
                  if (printerList[i].paper_size == 0) {
                    var data = Uint8List.fromList(
                        await ReceiptLayout().printKitchenList80mm(true, cart.cartNotifierItem[k], orderCacheLocalId));
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
                        await ReceiptLayout().printKitchenList58mm(true, cart.cartNotifierItem[k], orderCacheLocalId));
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
                }
              }
            }
          }
        }
      }
    } catch (e){
      print('Printer Connection Error: ${e}');
      Fluttertoast.showToast(
          backgroundColor: Colors.red,
          msg: "${AppLocalizations.of(context)?.translate('printing_error')}");
    }
  }

  printQrKitchenList(List<Printer> printerList, context, int orderCacheLocalId, {orderDetailList}) async {
    try{
      for (int i = 0; i < printerList.length; i++) {
        if(printerList[i].printer_status == 1 && printerList[i].is_counter == 0){
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
                    final PosPrintResult res = await printer.connect(printerDetail, port: 9100);

                    if (res == PosPrintResult.success) {
                      await ReceiptLayout()
                          .printQrKitchenList80mm(false, orderDetailList[k], orderCacheLocalId, value: printer);
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
                      await ReceiptLayout()
                          .printQrKitchenList58mm(false, orderDetailList[k], orderCacheLocalId, value: printer);
                      printer.disconnect();
                    } else {
                      Fluttertoast.showToast(
                          backgroundColor: Colors.red,
                          msg: "${AppLocalizations.of(context)?.translate('lan_printer_not_connect')}");
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
                      Fluttertoast.showToast(
                          backgroundColor: Colors.red,
                          msg: "${AppLocalizations.of(context)?.translate('usb_printer_not_connect')}");
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
                      Fluttertoast.showToast(
                          backgroundColor: Colors.red,
                          msg: "${AppLocalizations.of(context)?.translate('usb_printer_not_connect')}");
                    }
                  }
                }
              }
            }
          }
        }
      }
    } catch (e){
      print('Printer Connection Error: ${e}');
      Fluttertoast.showToast(
          backgroundColor: Colors.red,
          msg: "${AppLocalizations.of(context)?.translate('printing_error')}");
    }
  }

  printDeleteList(List<Printer> printerList, String orderCacheId, String dateTime) async {
    try {
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
              } else {
                print('not connected');
              }
            } else {
              var data = Uint8List.fromList(await ReceiptLayout().printDeleteItemList58mm(true, orderCacheId, dateTime));
              bool? isConnected = await flutterUsbPrinter.connect(
                  int.parse(printerDetail['vendorId']),
                  int.parse(printerDetail['productId']));
              if (isConnected == true) {
                await flutterUsbPrinter.write(data);
              } else {
                print('not connected');
              }
            }
          } else {
            //check paper size (print LAN)
            if(printerList[i].paper_size == 0){
              //print LAN
              final profile = await CapabilityProfile.load();
              final printer = NetworkPrinter(PaperSize.mm80, profile);
              final PosPrintResult res = await printer.connect(printerDetail, port: 9100);

              if (res == PosPrintResult.success) {
                await ReceiptLayout().printDeleteItemList80mm(false, orderCacheId, dateTime, value: printer);
                printer.disconnect();
              } else {
                print('not connected');
              }
            } else {
              //print LAN
              final profile = await CapabilityProfile.load();
              final printer = NetworkPrinter(PaperSize.mm58, profile);
              final PosPrintResult res = await printer.connect(printerDetail, port: 9100);

              if (res == PosPrintResult.success) {
                await ReceiptLayout().printDeleteItemList58mm(false, orderCacheId, dateTime, value: printer);
                printer.disconnect();
              } else {
                print('not connected');
              }
            }
          }
        }
      }
    } catch (e) {
      print('Printer Connection Error');
      //response = 'Failed to get platform version.';
    }
  }

  printKitchenDeleteList(List<Printer> printerList, String orderCacheId, String category_id, String dateTime, CartModel cart) async {
    try {
      for (int i = 0; i < printerList.length; i++) {
        if(printerList[i].printer_status == 1 && printerList[i].is_counter == 0){
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
                  } else {
                    print('not connected');
                  }
                }else {
                  var data = Uint8List.fromList(await ReceiptLayout().printDeleteItemList58mm(true, orderCacheId, dateTime));
                  bool? isConnected = await flutterUsbPrinter.connect(
                      int.parse(printerDetail['vendorId']),
                      int.parse(printerDetail['productId']));
                  if (isConnected == true) {
                    await flutterUsbPrinter.write(data);
                  } else {
                    print('not connected');
                  }
                }
              } else {
                //check paper size
                if(printerList[i].paper_size == 0){
                  //print LAN 80mm
                  final profile = await CapabilityProfile.load();
                  final printer = NetworkPrinter(PaperSize.mm80, profile);
                  final PosPrintResult res = await printer.connect(printerDetail, port: 9100);

                  if (res == PosPrintResult.success) {
                    await ReceiptLayout().printDeleteItemList80mm(false, orderCacheId, dateTime, value: printer);
                    printer.disconnect();
                  } else {
                    print('not connected');
                  }
                } else {
                  //print LAN 58mm
                  final profile = await CapabilityProfile.load();
                  final printer = NetworkPrinter(PaperSize.mm58, profile);
                  final PosPrintResult res = await printer.connect(printerDetail, port: 9100);

                  if (res == PosPrintResult.success) {
                    await ReceiptLayout().printDeleteItemList58mm(false, orderCacheId, dateTime, value: printer);
                    printer.disconnect();
                  } else {
                    print('not connected');
                  }
                }
              }
            }
          }
        }
      }
    } catch (e) {
      print('Printer Connection Error');
      //response = 'Failed to get platform version.';
    }
  }

  printSettlementList(List<Printer> printerList, String dateTime, context, Settlement settlement) async {
    try {
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
              } else {
                Fluttertoast.showToast(
                    backgroundColor: Colors.red,
                    msg: "${AppLocalizations.of(context)?.translate('usb_printer_not_connect')}");
              }
            } else {
              //print USB 58mm
              var data = Uint8List.fromList(await ReceiptLayout().printSettlementList58mm(true, dateTime, settlement));
              bool? isConnected = await flutterUsbPrinter.connect(
                  int.parse(printerDetail['vendorId']),
                  int.parse(printerDetail['productId']));
              if (isConnected == true) {
                await flutterUsbPrinter.write(data);
              } else {
                Fluttertoast.showToast(
                    backgroundColor: Colors.red,
                    msg: "${AppLocalizations.of(context)?.translate('usb_printer_not_connect')}");
              }
            }
          } else {
            if(printerList[i].paper_size == 0){
              //print LAN 80mm
              final profile = await CapabilityProfile.load();
              final printer = NetworkPrinter(PaperSize.mm80, profile);
              final PosPrintResult res = await printer.connect(printerDetail, port: 9100);
              if (res == PosPrintResult.success) {
                await ReceiptLayout().printSettlementList80mm(false, dateTime, settlement, value: printer);
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
                await ReceiptLayout().printSettlementList58mm(false, dateTime, settlement, value: printer);
                printer.disconnect();
              } else {
                Fluttertoast.showToast(
                    backgroundColor: Colors.red,
                    msg: "${AppLocalizations.of(context)?.translate('lan_printer_not_connect')}");
              }
            }
          }
        }
      }
    } catch (e) {
      print('Printer Connection Error');

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
              final PosPrintResult res = await printer.connect(printerDetail, port: 9100);
              if (res == PosPrintResult.success) {
                await ReceiptLayout().printCashBalanceList80mm(false, cashBalance, value: printer);
                printer.disconnect();
              } else {
                Fluttertoast.showToast(backgroundColor: Colors.red, msg: "${AppLocalizations.of(context)?.translate('lan_printer_not_connect')}");
              }
            } else {
              //print 58mm
              final profile = await CapabilityProfile.load();
              final printer = NetworkPrinter(PaperSize.mm58, profile);
              final PosPrintResult res = await printer.connect(printerDetail, port: 9100);
              if (res == PosPrintResult.success) {
                await ReceiptLayout().printCashBalanceList58mm(false, cashBalance, value: printer);
                printer.disconnect();
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

}