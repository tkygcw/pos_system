
import 'package:flutter/material.dart';
import 'package:flutter_usb_printer/flutter_usb_printer.dart';
import 'package:pos_system/object/print_receipt.dart';
import '../../notifier/cart_notifier.dart';
import '../../object/printer.dart';
import '../../translation/AppLocalizations.dart';

class ReprintDialog extends StatefulWidget {
  final List<Printer> printerList;
  final CartModel cart;
  const ReprintDialog({Key? key, required this.printerList, required this.cart}) : super(key: key);

  @override
  State<ReprintDialog> createState() => _ReprintDialogState();
}

class _ReprintDialogState extends State<ReprintDialog> {
  FlutterUsbPrinter flutterUsbPrinter = FlutterUsbPrinter();
  PrintReceipt printReceipt = PrintReceipt();
  bool _isChecked = false;

  void _submit(BuildContext context) async  {
    await printReceipt.reprintCheckList(widget.printerList, widget.cart, context);
    // if (_isChecked == false) {
    // } else {
    //   // await _printCheckList();
    //   // await _printKitchenList(widget.cart);
    // }
    Navigator.of(context).pop();
  }
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(AppLocalizations.of(context)!.translate('confirm_reprint_check_list')),
      content: Container(
        height: 150,
        // width: MediaQuery.of(context).size.width / 3,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(AppLocalizations.of(context)!.translate('would_you_like_to_reprint_check_list')),
            // Row(
            //   children: [
            //     Text('reprint kitchen check list'),
            //     Checkbox(
            //         value: _isChecked,
            //         onChanged: (value) {
            //           setState(() {
            //             _isChecked = value!;
            //           });
            //         }
            //     )
            //   ],
            // )
          ],
        ),
      ),
      actions: [
        TextButton(
            onPressed: (){
              Navigator.of(context).pop();
            },
            child: Text('${AppLocalizations.of(context)?.translate('close')}')
        ),
        TextButton(
            onPressed: () async{
              _submit(context);
            },
            child: Text('${AppLocalizations.of(context)?.translate('yes')}'))
      ],
    );
  }

  // _printCheckList() async {
  //   try {
  //     for (int i = 0; i < widget.printerList.length; i++) {
  //       List<PrinterLinkCategory> data = await PosDatabase.instance.readPrinterLinkCategory(widget.printerList[i].printer_sqlite_id!);
  //       for(int j = 0; j < data.length; j++){
  //         if (data[j].category_sqlite_id == '0') {
  //           var printerDetail = jsonDecode(widget.printerList[i].value!);
  //           if(widget.printerList[i].type == 0){
  //             if(widget.printerList[i].paper_size == 0){
  //               var data = Uint8List.fromList(await ReceiptLayout().printCheckList80mm(true));
  //               bool? isConnected = await flutterUsbPrinter.connect(
  //                   int.parse(printerDetail['vendorId']),
  //                   int.parse(printerDetail['productId']));
  //               if (isConnected == true) {
  //                 await flutterUsbPrinter.write(data);
  //               } else {
  //                 print('not connected');
  //               }
  //             } else {
  //               var data = Uint8List.fromList(await ReceiptLayout().printCheckList58mm(true));
  //               bool? isConnected = await flutterUsbPrinter.connect(
  //                   int.parse(printerDetail['vendorId']),
  //                   int.parse(printerDetail['productId']));
  //               if (isConnected == true) {
  //                 await flutterUsbPrinter.write(data);
  //               } else {
  //                 print('not connected');
  //               }
  //             }
  //
  //           } else {
  //             //print LAN
  //             if(widget.printerList[i].paper_size == 0){
  //               //print 80mm paper
  //               final profile = await CapabilityProfile.load();
  //               final printer = NetworkPrinter(PaperSize.mm80, profile);
  //               final PosPrintResult res = await printer.connect(printerDetail, port: 9100);
  //               if (res == PosPrintResult.success) {
  //                 await ReceiptLayout().printCheckList80mm(false, value: printer);
  //                 printer.disconnect();
  //               } else {
  //                 print('not connected');
  //               }
  //             } else {
  //               // print 58mm paper
  //               final profile = await CapabilityProfile.load();
  //               final printer = NetworkPrinter(PaperSize.mm58, profile);
  //               final PosPrintResult res = await printer.connect(printerDetail, port: 9100);
  //               if (res == PosPrintResult.success) {
  //                 await ReceiptLayout().printCheckList58mm(false, value: printer);
  //                 printer.disconnect();
  //               } else {
  //                 print('not connected');
  //               }
  //             }
  //           }
  //         }
  //       }
  //
  //     }
  //   } catch (e) {
  //     print('Printer Connection Error: ${e}');
  //     //response = 'Failed to get platform version.';
  //   }
  // }

  // _printKitchenList(CartModel cart) async {
  //   print('kitchen lan call');
  //   print('printer list ${widget.printerList.length}');
  //   for (int i = 0; i < widget.printerList.length; i++) {
  //     List<PrinterLinkCategory> data = await PosDatabase.instance.readPrinterLinkCategory(widget.printerList[i].printer_sqlite_id!);
  //     for(int j = 0; j < data.length; j++){
  //       for(int k = 0; k < cart.cartNotifierItem.length; k++){
  //         //check printer category
  //         if (cart.cartNotifierItem[k].category_sqlite_id == data[j].category_sqlite_id) {
  //           var printerDetail = jsonDecode(widget.printerList[i].value!);
  //           //check printer type
  //           if(widget.printerList[i].type == 1){
  //             //check paper size
  //             if(widget.printerList[i].paper_size == 0){
  //               //print LAN
  //               final profile = await CapabilityProfile.load();
  //               final printer = NetworkPrinter(PaperSize.mm80, profile);
  //               final PosPrintResult res = await printer.connect(printerDetail, port: 9100);
  //
  //               if (res == PosPrintResult.success) {
  //                 await ReceiptLayout().printKitchenList80mm(false, cart.cartNotifierItem[k], value: printer);
  //                 printer.disconnect();
  //               } else {
  //                 print('not connected');
  //               }
  //             } else {
  //               final profile = await CapabilityProfile.load();
  //               final printer = NetworkPrinter(PaperSize.mm58, profile);
  //               final PosPrintResult res = await printer.connect(printerDetail, port: 9100);
  //               if (res == PosPrintResult.success) {
  //                 await ReceiptLayout().printKitchenList58mm(false, cart.cartNotifierItem[k], value: printer);
  //                 printer.disconnect();
  //               } else {
  //                 print('not connected');
  //               }
  //             }
  //           } else {
  //             //print USB
  //             if(widget.printerList[i].paper_size == 0) {
  //               var data = Uint8List.fromList(await ReceiptLayout().printKitchenList80mm(true, cart.cartNotifierItem[k]));
  //               bool? isConnected = await flutterUsbPrinter.connect(
  //                   int.parse(printerDetail['vendorId']),
  //                   int.parse(printerDetail['productId']));
  //               if (isConnected == true) {
  //                 await flutterUsbPrinter.write(data);
  //               } else {
  //                 print('not connected');
  //               }
  //             } else {
  //               //print 58mm
  //               var data = Uint8List.fromList(await ReceiptLayout().printKitchenList58mm(true, cart.cartNotifierItem[k]));
  //               bool? isConnected = await flutterUsbPrinter.connect(
  //                   int.parse(printerDetail['vendorId']),
  //                   int.parse(printerDetail['productId']));
  //               if (isConnected == true) {
  //                 await flutterUsbPrinter.write(data);
  //               } else {
  //                 print('not connected');
  //               }
  //             }
  //           }
  //         }
  //       }
  //     }
  //   }
  // }
}

