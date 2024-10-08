
import 'package:f_logs/model/flog/flog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_usb_printer/flutter_usb_printer.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:pos_system/main.dart';
import 'package:pos_system/object/order_cache.dart';
import 'package:pos_system/fragment/printing_layout/print_receipt.dart';
import 'package:pos_system/object/table.dart';
import '../../notifier/cart_notifier.dart';
import '../../object/cart_product.dart';
import '../../object/printer.dart';
import '../../translation/AppLocalizations.dart';

class ReprintDialog extends StatefulWidget {
  final List<Printer> printerList;
  final CartModel cart;
  final String orderKey;
  final BuildContext parentContext;
  final String currentPage;
  const ReprintDialog({
    Key? key,
    required this.printerList,
    required this.cart,
    required this.orderKey,
    required this.parentContext,
    required this.currentPage}) : super(key: key);

  @override
  State<ReprintDialog> createState() => _ReprintDialogState();
}

class _ReprintDialogState extends State<ReprintDialog> {
  late final CartModel cartModel;
  FlutterUsbPrinter flutterUsbPrinter = FlutterUsbPrinter();
  PrintReceipt printReceipt = PrintReceipt();
  List<cartProductItem> ticketProduct = [];
  bool isButtonDisable = false;

  @override
  void initState() {
    // TODO: implement initState
    getTicketProduct();
    getCartModel();
    super.initState();
  }

  getCartModel(){
    List<PosTable> selectedTable = widget.cart.selectedTable.toList();
    List<cartProductItem> cartItem = widget.cart.cartNotifierItem.toList();
    String selectedOption = widget.cart.selectedOption;
    cartModel = CartModel(
      cartNotifierItem: cartItem,
      selectedOption: selectedOption,
      selectedTable: selectedTable,
      cartNotifierPayment: widget.cart.cartNotifierPayment.toList()
    );
  }

  getTicketProduct(){
    CartModel cart = widget.cart;
    ticketProduct = cart.cartNotifierItem.where((e) => e.allow_ticket == 1).toList();
  }

  void reprintCheckList() async {
    BuildContext _context = widget.parentContext;
    bool? isPaymentPage;
    if(widget.currentPage == 'bill'){
      isPaymentPage = true;
    }
    int printStatus = await printReceipt.reprintCheckList(widget.printerList, cartModel, isPayment: isPaymentPage);
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

  void reprintKitchenList() async  {
    try{
      List<OrderCache> orderCacheList = widget.cart.currentOrderCache;
      print("order cache list length: ${orderCacheList.length}");
      for(final cache in orderCacheList){
        asyncQ.addJob((_) async => await printReceipt.printKitchenList(widget.printerList, cache.order_cache_sqlite_id!, isReprint: true));
      }
    }catch(e){
      FLog.error(
        className: "reprint dialog",
        text: "reprint kitchen list error",
        exception: "$e",
      );
    }
  }

  printReviewReceipt() async {
    print("order key in reprint: ${widget.orderKey}");
    int printStatus = await printReceipt.printReviewReceipt(widget.printerList, cartModel, widget.orderKey);
    checkPrinterStatus(printStatus);
  }

  checkPrinterStatus(int printStatus) {
    if (printStatus == 1) {
      Fluttertoast.showToast(backgroundColor: Colors.red, msg: "${AppLocalizations.of(context)?.translate('printer_not_connected')}");
    } else if (printStatus == 2) {
      Fluttertoast.showToast(backgroundColor: Colors.orangeAccent, msg: "${AppLocalizations.of(context)?.translate('printer_connection_timeout')}");
    } else if (printStatus == 3) {
      Fluttertoast.showToast(backgroundColor: Colors.red, msg: AppLocalizations.of(context)!.translate('no_printer_added'));
    } else if (printStatus == 4) {
      Fluttertoast.showToast(backgroundColor: Colors.orangeAccent, msg: "${AppLocalizations.of(context)?.translate('no_cashier_printer')}");
    }
  }

  printPaymentReceipt() async {
    String localOrderId = widget.cart.cartNotifierPayment[0].localOrderId;
    print("cart payment length: ${widget.cart.cartNotifierPayment.length}");
    print("local order id in reprint: ${localOrderId}");
    int printStatus = await printReceipt.printCartReceiptList(widget.printerList, widget.cart, localOrderId);
    checkPrinterStatus(printStatus);
  }


  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(AppLocalizations.of(context)!.translate('reprint')),
      content: SingleChildScrollView(
        child: Column(
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
            Card(
              elevation: 5,
              child: ListTile(
                title: Text(AppLocalizations.of(context)!.translate('reprint_kitchen_list')),
                onTap: reprintKitchenList,
                trailing: Icon(Icons.kitchen),
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
            ),
          Visibility(
            visible: widget.currentPage == 'table' || widget.currentPage == 'other_order' ? true : false,
              child: Card(
                elevation: 5,
                child: ListTile(
                  title: Text(AppLocalizations.of(context)!.translate('print_review_receipt')),
                  onTap: printReviewReceipt,
                  trailing: Icon(Icons.receipt),
                ),
              ),
            ),
            Visibility(
              visible: widget.currentPage == 'bill' ? true : false,
              child: Card(
                elevation: 5,
                child: ListTile(
                  title: Text(AppLocalizations.of(context)!.translate('print_receipt')),
                  onTap: printPaymentReceipt,
                  trailing: Icon(Icons.receipt_long),
                ),
              ),
            ),
          ],
        ),
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

