import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';
import 'package:pos_system/object/order_detail.dart';
import 'package:provider/provider.dart';

import '../../database/pos_database.dart';
import '../../notifier/cart_notifier.dart';
import '../../notifier/theme_color.dart';
import '../../object/cart_product.dart';
import '../../object/user.dart';
import '../../translation/AppLocalizations.dart';

class CancelDialog extends StatefulWidget {
  final cartProductItem cartItem;
  const CancelDialog({Key? key, required this.cartItem}) : super(key: key);

  @override
  State<CancelDialog> createState() => _CancelDialogState();
}

class _CancelDialogState extends State<CancelDialog> {
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

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeColor>(builder: (context, ThemeColor color, child) {
      return Consumer<CartModel>(builder: (context, CartModel cart, child) {
        return AlertDialog(
          title: Text(AppLocalizations.of(context)!.translate('enter_admin_pin')),
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
              Text('${AppLocalizations.of(context)?.translate('yes')}'),
              onPressed: () async {
                _submit(context);
              },
            ),
          ],
        );
      });
    });
  }
  readAdminData(String pin) async {
    DateFormat dateFormat = DateFormat("yyyy-MM-dd HH:mm:ss");
    String dateTime = dateFormat.format(DateTime.now());
    List<User> userData = await PosDatabase.instance.readSpecificUserWithRole(pin);
    if(userData.length > 0){
      //List<OrderDetail> data = await PosDatabase.instance.readTableOrderDetail(widget.cartItem.orderCacheId!);
      int orderDetailData = await PosDatabase.instance.deleteSpecificOrderDetail(OrderDetail(
          soft_delete: dateTime,
          cancel_by: userData[0].name,
          order_cache_sqlite_id: widget.cartItem.order_cache_sqlite_id!,
          branch_link_product_sqlite_id: widget.cartItem.branch_link_product_sqlite_id
      ));

      Fluttertoast.showToast(
          backgroundColor: Color(0xFF24EF10),
          msg: AppLocalizations.of(context)!.translate('delete_successful'));
      // Navigator.of(context).pop();
    }else{
      Fluttertoast.showToast(
          backgroundColor: Color(0xFFFF0000),
          msg: AppLocalizations.of(context)!.translate('password_incorrect'));
    }
  }

}
