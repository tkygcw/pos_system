import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_usb_printer/flutter_usb_printer.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';
import 'package:pos_system/fragment/cart/cancel_order_dialog.dart';
import 'package:pos_system/object/cart_product.dart';
import 'package:pos_system/object/order_cache.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../database/pos_database.dart';
import '../../notifier/cart_notifier.dart';
import '../../notifier/theme_color.dart';
import '../../object/order_detail.dart';
import '../../object/printer.dart';
import '../../object/printer_link_category.dart';
import '../../object/receipt_layout.dart';
import '../../object/table.dart';
import '../../object/table_use.dart';
import '../../object/table_use_detail.dart';
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
  FlutterUsbPrinter flutterUsbPrinter = FlutterUsbPrinter();
  final adminPosPinController = TextEditingController();
  bool _submitted = false;
  List <User> adminData = [];
  List<Printer> printerList = [];

  @override
  void initState() {
    super.initState();
    readAllPrinters();
  }

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


  Future showSecondDialog(BuildContext context, ThemeColor color, CartModel cart) {
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
            Text('${AppLocalizations.of(context)?.translate('yes')}'),
            onPressed: () async {
              _submit(context);
              cart.removeAllTable();
              cart.removeAllCartItem();
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
                    await showSecondDialog(context, color, cart);
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
      // print('cart cache id: ${widget.cartItem!.orderCacheId!}');
      // print('product id: ${ widget.cartItem!.branchProduct_id}');
      DateFormat dateFormat = DateFormat("yyyy-MM-dd HH:mm:ss");
      String dateTime = dateFormat.format(DateTime.now());

      List<User> userData = await PosDatabase.instance.readSpecificUserWithRole(pin);
      if(userData.length > 0){
        closeDialog(context);
        List<OrderDetail> data = await PosDatabase.instance.readTableOrderDetail(widget.cartItem!.orderCacheId!);
        if(data.length > 1){
          callDeleteOrderDetail(userData[0], dateTime);

        } else {
          List<OrderCache> cacheData  = await PosDatabase.instance.readSpecificOrderCache(widget.cartItem!.orderCacheId!);
          List<TableUseDetail> detailData = await PosDatabase.instance.readAllTableUseDetail(cacheData[0].table_use_sqlite_id!);
          for(int i = 0; i < detailData.length; i++){
            //update all table to unused
            await updatePosTableStatus(int.parse(detailData[i].table_sqlite_id!), 0, dateTime);
          }
          //delete all order inc order cache
          await callDeleteAllOrder(userData[0], cacheData[0].table_use_sqlite_id!, dateTime);

        }
        await _printDeleteList(widget.cartItem!.orderCacheId!, dateTime);
        Fluttertoast.showToast(
            backgroundColor: Color(0xFF24EF10),
            msg: "delete successful");
      }else{
        Fluttertoast.showToast(
            backgroundColor: Color(0xFFFF0000),
            msg: "Password incorrect");
      }
    } catch(e){
      print('delete error ${e}');
    }

  }
  _printDeleteList(String orderCacheId, String dateTime) async {
    print('printer called');
    try {
      for (int i = 0; i < printerList.length; i++) {
        List<PrinterLinkCategory> data = await PosDatabase.instance
            .readPrinterLinkCategory(printerList[i].printer_sqlite_id!);
        for(int j = 0; j < data.length; j++){
          if (data[j].category_sqlite_id == '3') {
            if(printerList[i].type == 0){
              var printerDetail = jsonDecode(printerList[i].value!);
              var data = Uint8List.fromList(await ReceiptLayout()
                  .printDeleteItemList80mm(true, null, orderCacheId, dateTime));
              bool? isConnected = await flutterUsbPrinter.connect(
                  int.parse(printerDetail['vendorId']),
                  int.parse(printerDetail['productId']));
              if (isConnected == true) {
                await flutterUsbPrinter.write(data);
              } else {
                print('not connected');
              }
            } else {
              print("print lan");
            }
          }
        }
      }
    } catch (e) {
      print('Printer Connection Error');
      //response = 'Failed to get platform version.';
    }
  }

  readAllPrinters() async {
    final prefs = await SharedPreferences.getInstance();
    final int? branch_id = prefs.getInt('branch_id');

    List<Printer> data =
    await PosDatabase.instance.readAllBranchPrinter(branch_id!);
    printerList = List.from(data);
  }

  callDeleteOrderDetail(User user, String dateTime) async {
    int orderDetailData = await PosDatabase.instance.deleteSpecificOrderDetail(OrderDetail(
        soft_delete: dateTime,
        cancel_by: user.name,
        cancel_by_user_id: user.user_id.toString(),
        order_cache_sqlite_id: widget.cartItem!.orderCacheId!,
        branch_link_product_sqlite_id: widget.cartItem!.branchProduct_id
    ));
  }

  callDeleteAllOrder(User user, String currentTableUseId, String dateTime) async {
    await deleteCurrentTableUseDetail(currentTableUseId, dateTime);
    await deleteCurrentTableUseId(int.parse(currentTableUseId), dateTime);
    await callDeleteOrderDetail(user, dateTime);
    await deleteCurrentOrderCache(user, dateTime);
  }

  updatePosTableStatus(int tableId, int status, String dateTime) async {
    PosTable posTableData = PosTable(status: status, updated_at: dateTime, table_sqlite_id: tableId);
    int data2 = await PosDatabase.instance.updatePosTableStatus(posTableData);
  }

  deleteCurrentOrderCache(User user, String dateTime) async {
    print('delete order cache called');
    try{
      int orderCacheData = await PosDatabase.instance.deleteOrderCache(OrderCache(
          soft_delete: dateTime,
          cancel_by: user.name,
          cancel_by_user_id: user.user_id.toString(),
          order_cache_sqlite_id: int.parse(widget.cartItem!.orderCacheId!)
      ));
    }catch(e){
      print('delete order cache error: ${e}');
    }
  }

  deleteCurrentTableUseDetail(String currentTableUseId, String dateTime) async {
    try{
      int tableUseDetailData = await PosDatabase.instance.deleteTableUseDetail(
          TableUseDetail(
            soft_delete: dateTime,
            table_use_sqlite_id: currentTableUseId,
          ));
    } catch(e){
      Fluttertoast.showToast(
          backgroundColor: Color(0xFFFF0000),
          msg: "Delete current table use detail error: $e");
    }
  }

  deleteCurrentTableUseId(int currentTableUseId, String dateTime) async {
    try{
      int tableUseData = await PosDatabase.instance.deleteTableUseID(
          TableUse(
            soft_delete: dateTime,
            table_use_sqlite_id: currentTableUseId,
          ));
    }catch(e){
      Fluttertoast.showToast(
          backgroundColor: Color(0xFFFF0000),
          msg: "Delete current table use id error: ${e}");
    }
  }
}
