
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_usb_printer/flutter_usb_printer.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:pos_system/object/print_receipt.dart';
import '../../notifier/cart_notifier.dart';
import '../../object/cart_product.dart';
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
  List<cartProductItem> ticketProduct = [];
  bool isButtonDisable = false;

  @override
  void initState() {
    // TODO: implement initState
    getTicketProduct();
    super.initState();
  }

  getTicketProduct(){
    CartModel cart = widget.cart;
    ticketProduct = cart.cartNotifierItem.where((e) => e.allow_ticket == 1).toList();
  }

  void reprintCheckList() async  {
    BuildContext _context = widget.parentContext;
    int printStatus = await printReceipt.reprintCheckList(widget.printerList, widget.cart);
    switch(printStatus){
      case 1: {
        Fluttertoast.showToast(
            backgroundColor: Colors.red,
            msg: "${AppLocalizations.of(_context)?.translate('printer_not_connected')}");
      }break;
      case 2 : {
        Fluttertoast.showToast(
            backgroundColor: Colors.orangeAccent,
            msg: "${AppLocalizations.of(_context)?.translate('printer_connection_timeout')}");
      }break;
      case 3: {
        Fluttertoast.showToast(
            backgroundColor: Colors.orangeAccent,
            msg: "${AppLocalizations.of(_context)?.translate('no_printer_added')}");
      }break;
      case 5: {
        Fluttertoast.showToast(backgroundColor: Colors.red, msg: AppLocalizations.of(_context)!.translate('printing_error'));
      }break;
    }
  }

  void reprintProductTicket() async  {
    BuildContext _context = widget.parentContext;
    if(ticketProduct.isNotEmpty){
      printReceipt.printProductTicket(widget.printerList, int.parse(ticketProduct[0].order_cache_sqlite_id!), ticketProduct);
    }
    // switch(printStatus){
    //   case 1: {
    //     Fluttertoast.showToast(
    //         backgroundColor: Colors.red,
    //         msg: "${AppLocalizations.of(_context)?.translate('printer_not_connected')}");
    //   }break;
    //   case 2 : {
    //     Fluttertoast.showToast(
    //         backgroundColor: Colors.orangeAccent,
    //         msg: "${AppLocalizations.of(_context)?.translate('printer_connection_timeout')}");
    //   }break;
    //   case 3: {
    //     Fluttertoast.showToast(
    //         backgroundColor: Colors.orangeAccent,
    //         msg: "${AppLocalizations.of(_context)?.translate('no_printer_added')}");
    //   }break;
    //   case 5: {
    //     Fluttertoast.showToast(backgroundColor: Colors.red, msg: AppLocalizations.of(_context)!.translate('printing_error'));
    //   }break;
    // }
  }
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(AppLocalizations.of(context)!.translate('reprint')),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Card(
            elevation: 5,
            child: ListTile(
                title: Text(AppLocalizations.of(context)!.translate('reprint_checklist')),
                onTap: reprintCheckList,
                trailing: Icon(Icons.print)
            ),
          ),
          Visibility(
            visible: ticketProduct.isNotEmpty ? true : false,
            child: Card(
              elevation: 5,
              child: ListTile(
                title: Text(AppLocalizations.of(context)!.translate('reprint_product_ticket')),
                onTap: reprintProductTicket,
                trailing: Icon(Icons.print),
              ),
            ),
          )
        ],
      ),
      actions: [
        ElevatedButton(
          onPressed: isButtonDisable ? null : () {
            setState(() {
              isButtonDisable = true;
            });
            Navigator.of(context).pop();
            },
          child: Text('${AppLocalizations.of(context)?.translate('close')}'),
        )

      ],
    );
  }
}

