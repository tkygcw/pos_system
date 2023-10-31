
import 'package:flutter/material.dart';
import 'package:flutter_usb_printer/flutter_usb_printer.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:pos_system/object/print_receipt.dart';
import '../../notifier/cart_notifier.dart';
import '../../object/printer.dart';
import '../../translation/AppLocalizations.dart';

class ReprintDialog extends StatefulWidget {
  final List<Printer> printerList;
  final CartModel cart;
  final BuildContext parentContext;
  const ReprintDialog({Key? key, required this.printerList, required this.cart, required this.parentContext}) : super(key: key);

  @override
  State<ReprintDialog> createState() => _ReprintDialogState();
}

class _ReprintDialogState extends State<ReprintDialog> {
  FlutterUsbPrinter flutterUsbPrinter = FlutterUsbPrinter();
  PrintReceipt printReceipt = PrintReceipt();
  bool isButtonDisable = false;

  void _submit(BuildContext context) async  {
    int printStatus = await printReceipt.reprintCheckList(widget.printerList, widget.cart, context);
    switch(printStatus){
      case 1: {
        Fluttertoast.showToast(
            backgroundColor: Colors.red,
            msg: "${AppLocalizations.of(context)?.translate('printer_not_connected')}");
      }break;
      case 2 : {
        Fluttertoast.showToast(
            backgroundColor: Colors.orangeAccent,
            msg: "${AppLocalizations.of(context)?.translate('printer_connection_timeout')}");
      }break;
      case 3: {
        Fluttertoast.showToast(
            backgroundColor: Colors.orangeAccent,
            msg: "${AppLocalizations.of(context)?.translate('no_printer_added')}");
      }break;
      case 5: {
        Fluttertoast.showToast(backgroundColor: Colors.red, msg: AppLocalizations.of(context)!.translate('printing_error'));
      }break;
    }
  }
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(AppLocalizations.of(context)!.translate('confirm_reprint_check_list')),
      content: Text(AppLocalizations.of(context)!.translate('would_you_like_to_reprint_check_list')),
      actions: [
        TextButton(
            onPressed: isButtonDisable ? null : () {
              setState(() {
                isButtonDisable = true;
              });
              Navigator.of(context).pop();
            },
            child: Text('${AppLocalizations.of(context)?.translate('close')}')
        ),
        TextButton(
            onPressed: isButtonDisable ? null : (){
              setState(() {
                isButtonDisable = true;
              });
              Navigator.of(context).pop();
              _submit(widget.parentContext);
            },
            child: Text('${AppLocalizations.of(context)?.translate('yes')}'))
      ],
    );
  }
}

