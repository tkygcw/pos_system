import 'package:flutter/material.dart';
import 'package:pos_system/object/cart_product.dart';
import 'package:provider/provider.dart';

import '../../notifier/cart_notifier.dart';
import '../../notifier/theme_color.dart';
import '../../translation/AppLocalizations.dart';

class CartRemoveDialog extends StatefulWidget {
  final cartProductItem? cartItem;
  const CartRemoveDialog({Key? key, this.cartItem}) : super(key: key);

  @override
  State<CartRemoveDialog> createState() => _CartRemoveDialogState();
}

class _CartRemoveDialogState extends State<CartRemoveDialog> {
  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeColor>(builder: (context, ThemeColor color, child) {
      return Consumer<CartModel>(builder: (context, CartModel cart, child) {
        return AlertDialog(
          title: Text('Confirm remove item ?'),
          content: Container(
            child: Row(
              children: [
                Text(
                    '${widget.cartItem!.name} ${AppLocalizations.of(context)?.translate('confirm_delete')}')
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
                child: Text('${AppLocalizations.of(context)?.translate('no')}'),
                onPressed: () {
                  Navigator.of(context).pop();
                }),
            TextButton(
                child:
                    Text('${AppLocalizations.of(context)?.translate('yes')}'),
                onPressed: () {
                  cart.removeItem(widget.cartItem!);
                  Navigator.of(context).pop();
                })
          ],
        );
      });
    });
  }
}
