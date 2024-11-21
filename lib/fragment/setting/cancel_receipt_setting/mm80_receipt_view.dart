import 'dart:async';

import 'package:flutter/material.dart';

import '../../../enumClass/receipt_dialog_enum.dart';
import '../../../translation/AppLocalizations.dart';

class mm80ReceiptView extends StatefulWidget {
  const mm80ReceiptView({Key? key}) : super(key: key);

  @override
  State<mm80ReceiptView> createState() => _mm80ReceiptViewState();
}

class _mm80ReceiptViewState extends State<mm80ReceiptView> {
  StreamController actionController = StreamController();
  ReceiptDialogEnum productFontSize = ReceiptDialogEnum.big;
  ReceiptDialogEnum variantAddonFontSize = ReceiptDialogEnum.big;
  double fontSize = 20.0, otherFontSize = 20.0;
  late Stream actionStream;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    actionStream = actionController.stream.asBroadcastStream();
  }
  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: actionStream,
      builder: (context, snapshot) {
        return Row(
          children: [
            Expanded(flex: 1, child: Container(color: Colors.blue,)),
            Expanded(
              flex: 1,
                child: Column(
                  children: [
                    Container(
                      alignment: Alignment.topLeft,
                      child: Text(AppLocalizations.of(context)!.translate('product_name_font_size'), style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey)),
                    ),
                    RadioListTile<ReceiptDialogEnum?>(
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
                  ],
                ),
            )
          ],
        );
      }
    );
  }
}
