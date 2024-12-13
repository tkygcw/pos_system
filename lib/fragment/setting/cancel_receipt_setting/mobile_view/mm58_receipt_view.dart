import 'dart:async';

import 'package:flutter/material.dart';
import 'package:pos_system/database/pos_database.dart';
import 'package:pos_system/notifier/theme_color.dart';
import 'package:pos_system/object/cancel_receipt.dart';
import 'package:pos_system/page/progress_bar.dart';
import 'package:provider/provider.dart';

import '../../../../enumClass/receipt_dialog_enum.dart';
import '../../../../translation/AppLocalizations.dart';

class mm58MobileReceiptView extends StatefulWidget {
  final Function(CancelReceipt layout) callback;
  const mm58MobileReceiptView({Key? key, required this.callback}) : super(key: key);

  @override
  State<mm58MobileReceiptView> createState() => _mm58MobileReceiptView();
}

class _mm58MobileReceiptView extends State<mm58MobileReceiptView> {
  StreamController actionController = StreamController();
  PosDatabase posDatabase = PosDatabase.instance;
  ReceiptDialogEnum productFontSize = ReceiptDialogEnum.big;
  ReceiptDialogEnum variantAddonFontSize = ReceiptDialogEnum.big;
  double fontSize = 20.0, otherFontSize = 20.0;
  bool showSKU = false, cancelShowPrice = false;
  late Stream actionStream;
  late CancelReceipt cancelReceipt;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    listenAction();
    actionStream = actionController.stream.asBroadcastStream();
  }

  getCancelReceipt() async {
    CancelReceipt? cancelReceipt = await posDatabase.readSpecificCancelReceiptByPaperSize('58');
    if(cancelReceipt != null){
      productFontSize = ReceiptDialogEnum.values.elementAt(cancelReceipt.product_name_font_size!);
      variantAddonFontSize = ReceiptDialogEnum.values.elementAt(cancelReceipt.other_font_size!);
      showSKU = cancelReceipt.show_product_sku == 1 ? true : false;
      cancelShowPrice = cancelReceipt.show_product_price == 1 ? true : false;
    }
    widget.callback(CancelReceipt(
        paper_size: '58',
        product_name_font_size: productFontSize.index,
        other_font_size: variantAddonFontSize.index,
        show_product_sku: showSKU ? 1 : 0,
        show_product_price: cancelShowPrice ? 1 : 0
    ));
    Future.delayed(Duration(milliseconds: 500), () {
      actionController.sink.add("refresh");
    });
  }

  listenAction() async{
    await getCancelReceipt();
    actionStream.listen((event) async  {
      switch(event){
        case 'switch':{
          widget.callback(CancelReceipt(
              paper_size: '58',
              product_name_font_size: productFontSize.index,
              other_font_size: variantAddonFontSize.index,
              show_product_sku: showSKU ? 1 : 0,
              show_product_price: cancelShowPrice ? 1 : 0
          ));
        }
        break;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    var color = context.watch<ThemeColor>();
    return StreamBuilder(
        stream: actionStream,
        builder: (context, snapshot) {
          if(snapshot.hasData){
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  alignment: Alignment.topLeft,
                  child: Text(AppLocalizations.of(context)!.translate('product_name_font_size'), style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey)),
                ),
                RadioListTile<ReceiptDialogEnum?>(
                  activeColor: color.backgroundColor,
                  value: ReceiptDialogEnum.big,
                  groupValue: productFontSize,
                  onChanged: (value) async  {
                    productFontSize = value!;
                    fontSize = 20.0;
                    actionController.sink.add("switch");
                  },
                  title: Text(AppLocalizations.of(context)!.translate('big')),
                  controlAffinity: ListTileControlAffinity.trailing,
                ),
                RadioListTile<ReceiptDialogEnum?>(
                  activeColor: color.backgroundColor,
                  value: ReceiptDialogEnum.medium,
                  groupValue: productFontSize,
                  onChanged: (value) async  {
                    productFontSize = value!;
                    fontSize = 18.0;
                    actionController.sink.add("switch");
                  },
                  title: Text(AppLocalizations.of(context)!.translate('medium')),
                  controlAffinity: ListTileControlAffinity.trailing,
                ),
                RadioListTile<ReceiptDialogEnum?>(
                  activeColor: color.backgroundColor,
                  value: ReceiptDialogEnum.small,
                  groupValue: productFontSize,
                  onChanged: (value) async  {
                    productFontSize = value!;
                    fontSize = 14.0;
                    actionController.sink.add("switch");
                  },
                  title: Text(AppLocalizations.of(context)!.translate('small')),
                  controlAffinity: ListTileControlAffinity.trailing,
                ),
                Container(
                  alignment: Alignment.topLeft,
                  child: Text(AppLocalizations.of(context)!.translate('other_font_size'), style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey)),
                ),
                RadioListTile<ReceiptDialogEnum?>(
                  activeColor: color.backgroundColor,
                  value: ReceiptDialogEnum.big,
                  groupValue: variantAddonFontSize,
                  onChanged: (value) async  {
                    variantAddonFontSize = value!;
                    otherFontSize = 20.0;
                    actionController.sink.add("switch");
                  },
                  title: Text(AppLocalizations.of(context)!.translate('big')),
                  controlAffinity: ListTileControlAffinity.trailing,
                ),
                RadioListTile<ReceiptDialogEnum?>(
                  activeColor: color.backgroundColor,
                  value: ReceiptDialogEnum.medium,
                  groupValue: variantAddonFontSize,
                  onChanged: (value) async  {
                    variantAddonFontSize = value!;
                    otherFontSize = 18.0;
                    actionController.sink.add("switch");
                  },
                  title: Text(AppLocalizations.of(context)!.translate('medium')),
                  controlAffinity: ListTileControlAffinity.trailing,
                ),
                RadioListTile<ReceiptDialogEnum?>(
                  activeColor: color.backgroundColor,
                  value: ReceiptDialogEnum.small,
                  groupValue: variantAddonFontSize,
                  onChanged: (value) async  {
                    variantAddonFontSize = value!;
                    otherFontSize = 14.0;
                    actionController.sink.add("switch");
                  },
                  title: Text(AppLocalizations.of(context)!.translate('small')),
                  controlAffinity: ListTileControlAffinity.trailing,
                ),
                Container(
                  alignment: Alignment.topLeft,
                  child: Text(AppLocalizations.of(context)!.translate('cancel_receipt_setting'), style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey)),
                ),
                ListTile(
                  title: Text(AppLocalizations.of(context)!.translate('cancel_show_price')),
                  subtitle: Text(AppLocalizations.of(context)!.translate('cancel_show_price_desc')),
                  trailing: Switch(
                    value: cancelShowPrice,
                    activeColor: color.backgroundColor,
                    onChanged: (value) async {
                      cancelShowPrice = value;
                      actionController.sink.add("switch");
                    },
                  ),
                ),
                ListTile(
                  title: Text(AppLocalizations.of(context)!.translate('show_product_sku')),
                  subtitle: Text(AppLocalizations.of(context)!.translate('show_product_sku_desc')),
                  trailing: Switch(
                    value: showSKU,
                    activeColor: color.backgroundColor,
                    onChanged: (value) {
                      showSKU = value;
                      actionController.sink.add("switch");
                    },
                  ),
                ),
              ],
            );
          } else {
            return CustomProgressBar();
          }
        }
    );
  }
}
