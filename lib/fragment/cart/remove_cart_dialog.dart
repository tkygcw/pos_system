import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';
import 'package:pos_system/fragment/cart/cancel_order_dialog.dart';
import 'package:pos_system/object/cart_product.dart';
import 'package:provider/provider.dart';

import '../../database/pos_database.dart';
import '../../notifier/cart_notifier.dart';
import '../../notifier/theme_color.dart';
import '../../object/order_detail.dart';
import '../../object/user.dart';
import '../../translation/AppLocalizations.dart';

class CartRemoveDialog extends StatefulWidget {
  final cartProductItem? cartItem;
  final String currentPage;
  const CartRemoveDialog({Key? key, this.cartItem, required this.currentPage}) : super(key: key);

  @override
  State<CartRemoveDialog> createState() => _CartRemoveDialogState();
}



class _CartRemoveDialogState extends State<CartRemoveDialog> {
  final adminPosPinController = TextEditingController();
  bool _submitted = false;
  List <User> adminData = [];

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
    adminPosPinController.dispose();
  }

  String? get errorPassword {
    final text = adminPosPinController.value.text;
    readAdminData(text);
    if (text.isEmpty) {
      return 'password_required';
    }
    return null;
  }

  void _submit(BuildContext context) async {
    setState(() => _submitted = true);
    if (errorPassword == '') {
      await readAdminData(adminPosPinController.text);
      return;

    }
  }

  closeDialog(BuildContext context) {
    return Navigator.of(context).pop(true);
  }


  Future showSecondDialog(BuildContext context, ThemeColor color) {
    return showDialog(
      barrierDismissible: false,
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: Text('Enter admin PIN'),
        content: SizedBox(
          height: 100.0,
          width: 350.0,
          child: Column(
            children: [
              ValueListenableBuilder(
                  valueListenable: adminPosPinController,
                  builder: (context, TextEditingValue value, __) {
                    return Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: TextField(
                        controller: adminPosPinController,
                        decoration: InputDecoration(
                          errorText: _submitted
                              ? errorPassword == null ? errorPassword: AppLocalizations.of(context)
                              ?.translate(errorPassword!)
                              : null,
                          border: OutlineInputBorder(
                            borderSide:
                            BorderSide(color: color.backgroundColor),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide:
                            BorderSide(color: color.backgroundColor),
                          ),
                          labelText: "PIN",
                        ),
                      ),
                    );
                  }),
            ],
          ),
        ),
        actions: <Widget>[
          TextButton(
            child: Text('${AppLocalizations.of(context)?.translate('close')}'),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
          TextButton(
            child:
            Text('${AppLocalizations.of(context)?.translate('confirm_logout')}'),
            onPressed: () async {
              _submit(context);
            },
          ),
        ],
      ),
    );
  }
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
                onPressed: () async  {
                  if(widget.currentPage == 'menu'){
                    cart.removeItem(widget.cartItem!);
                    if(cart.cartNotifierItem.isEmpty){
                      cart.removeAllTable();
                    }
                    Navigator.of(context).pop();
                  } else {
                    print('detect table page');
                    await showSecondDialog(context, color);
                    closeDialog(context);
                    //openCancelOrderDialog(widget.cartItem!);
                    //Navigator.of(context).pop();
                  }

                })
          ],
        );
      });
    });
  }

  Future<Future<Object?>> openCancelOrderDialog(cartProductItem cartItem) async {
    return showGeneralDialog(
        barrierColor: Colors.black.withOpacity(0.5),
        transitionBuilder: (context, a1, a2, widget) {
          final curvedValue = Curves.easeInOutBack.transform(a1.value) - 1.0;
          return Transform(
            transform: Matrix4.translationValues(0.0, curvedValue * 200, 0.0),
            child: Opacity(
              opacity: a1.value,
              child: CancelDialog(
                cartItem: cartItem,
              ),
            ),
          );
        },
        transitionDuration: Duration(milliseconds: 200),
        barrierDismissible: false,
        context: context,
        pageBuilder: (context, animation1, animation2) {
          // ignore: null_check_always_fails
          return null!;
        });
  }

  readAdminData(String pin) async {
    try{
      print('cart cache id: ${widget.cartItem!.orderCacheId!}');
      print('product id: ${ widget.cartItem!.branchProduct_id}');
      DateFormat dateFormat = DateFormat("yyyy-MM-dd HH:mm:ss");
      String dateTime = dateFormat.format(DateTime.now());
      List<User> userData = await PosDatabase.instance.readSpecificUserWithRole(pin);
      if(userData.length > 0){
        //List<OrderDetail> data = await PosDatabase.instance.readTableOrderDetail(widget.cartItem.orderCacheId!);
        int orderDetailData = await PosDatabase.instance.deleteSpecificOrderDetail(OrderDetail(
            soft_delete: dateTime,
            cancel_by: userData[0].name,
            order_cache_sqlite_id: widget.cartItem!.orderCacheId!,
            branch_link_product_sqlite_id: widget.cartItem!.branchProduct_id
        ));

        Fluttertoast.showToast(
            backgroundColor: Color(0xFF24EF10),
            msg: "delete successful");
        // Navigator.of(context).pop();
      }else{
        Fluttertoast.showToast(
            backgroundColor: Color(0xFFFF0000),
            msg: "Password incorrect");
      }
    } catch(e){
      print('delete error ${e}');
    }

  }
}
