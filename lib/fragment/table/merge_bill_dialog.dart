import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:pos_system/notifier/cart_notifier.dart';
import 'package:pos_system/notifier/theme_color.dart';
import 'package:pos_system/object/table.dart';
import 'package:provider/provider.dart';

import '../../translation/AppLocalizations.dart';

class MergeBillDialog extends StatefulWidget {
  final PosTable tableObject;
  final Function(CartModel cart) callBack;

  const MergeBillDialog({Key? key, required this.callBack, required this.tableObject}) : super(key: key);

  @override
  State<MergeBillDialog> createState() => _MergeBillDialogState();
}

class _MergeBillDialogState extends State<MergeBillDialog> {
  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeColor>(builder: (context, ThemeColor color, child) {
      return Consumer<CartModel>(
        builder: (context, CartModel cart, child) {
          return AlertDialog(
            title: Text(AppLocalizations.of(context)!.translate('confirm_merge_bill')),
            content: Container(
              child: Row(
                children: [
                  Text(AppLocalizations.of(context)!.translate('confirm_merge_bill'))
                ],
              ),
            ),
            actions: <Widget>[
              TextButton(
                  child: Text('${AppLocalizations.of(context)?.translate('no')}'),
                  onPressed: () {
                    cart.removeAllTable();
                    cart.removeAllCartItem();
                    widget.callBack(cart);
                    Navigator.of(context).pop();
                  }
              ),
              TextButton(
                  child: Text('${AppLocalizations.of(context)?.translate('yes')}'),
                  onPressed: () {
                    if(widget.tableObject.number != cart.selectedTable[0].number){
                      widget.callBack(cart);
                      Navigator.of(context).pop();
                    } else {
                      Fluttertoast.showToast(
                          backgroundColor: Color(0xFFFF0000),
                          msg: AppLocalizations.of(context)!.translate('merge_error'));
                    }
                  })
            ],
          );
        }
      );
    });
  }

}
