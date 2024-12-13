import 'package:flutter/material.dart';
import 'package:pos_system/object/cart_product.dart';
import 'package:provider/provider.dart';

import '../../notifier/cart_notifier.dart';
import '../../notifier/theme_color.dart';
import '../../translation/AppLocalizations.dart';

class CartRemoveDialog extends StatefulWidget {
  final cartProductItem? cartItem;
  final String currentPage;

  const CartRemoveDialog({Key? key, this.cartItem, required this.currentPage})
      : super(key: key);

  @override
  State<CartRemoveDialog> createState() => _CartRemoveDialogState();
}

class _CartRemoveDialogState extends State<CartRemoveDialog> {
  bool _isButtonDisabled = false;


  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeColor>(builder: (context, ThemeColor color, child) {
      return Consumer<CartModel>(builder: (context, CartModel cart, child) {
        return AlertDialog(
          title: Text(AppLocalizations.of(context)!.translate('confirm_remove_item')),
          content: Container(
            width: 400,
            // height: 50,
            child: Text('${widget.cartItem!.product_name} ${AppLocalizations.of(context)?.translate('confirm_delete')}'),
          ),
          actions: <Widget>[
            Row(
              children: [
                Expanded(
                  flex: 1,
                  child: SizedBox(
                    width: MediaQuery.of(context).size.width > 900 && MediaQuery.of(context).size.height > 500 ? MediaQuery.of(context).size.width / 6 : MediaQuery.of(context).size.width / 4,
                    height: MediaQuery.of(context).size.width > 900 && MediaQuery.of(context).size.height > 500
                        ? MediaQuery.of(context).size.height / 12
                        : MediaQuery.of(context).orientation == Orientation.landscape ? MediaQuery.of(context).size.height / 10
                        : MediaQuery.of(context).size.height / 20,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: color.backgroundColor,
                      ),
                      child: Text(
                        AppLocalizations.of(context)!.translate('close'),
                        style: TextStyle(color: Colors.white),
                      ),
                      onPressed: _isButtonDisabled
                          ? null
                          : () {
                        setState(() {
                          _isButtonDisabled = true;
                        });
                        Navigator.of(context).pop();
                      },
                    ),
                  ),
                ),
                SizedBox(width: 10),
                Expanded(
                  flex: 1,
                  child: SizedBox(
                    width: MediaQuery.of(context).size.width > 900 && MediaQuery.of(context).size.height > 500 ? MediaQuery.of(context).size.width / 6 : MediaQuery.of(context).size.width / 4,
                    height: MediaQuery.of(context).size.width > 900 && MediaQuery.of(context).size.height > 500
                        ? MediaQuery.of(context).size.height / 12
                        : MediaQuery.of(context).orientation == Orientation.landscape ? MediaQuery.of(context).size.height / 10
                        : MediaQuery.of(context).size.height / 20,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: color.buttonColor,
                      ),
                      child: Text(
                        AppLocalizations.of(context)!.translate('yes'),
                        style: TextStyle(color: Colors.white),
                      ),
                      onPressed: _isButtonDisabled ? null : () async {
                        Navigator.of(context).pop();
                        setState(() {
                          _isButtonDisabled = true;
                        });
                        if (widget.currentPage == 'menu') {
                          cart.removeItem(widget.cartItem!);
                          if (cart.cartNotifierItem.isEmpty) {
                            cart.removeAllTable();
                          }
                        }
                        setState(() {
                          _isButtonDisabled = false;
                        });
                      },
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
      });
    });
  }
}
