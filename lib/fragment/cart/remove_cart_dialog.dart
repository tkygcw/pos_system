import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_usb_printer/flutter_usb_printer.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';
import 'package:pos_system/fragment/cart/adjust_quantity.dart';
import 'package:pos_system/main.dart';
import 'package:pos_system/object/cart_product.dart';
import 'package:pos_system/object/order_cache.dart';
import 'package:pos_system/object/order_modifier_detail.dart';
import 'package:pos_system/object/print_receipt.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:crypto/crypto.dart';

import '../../database/domain.dart';
import '../../database/pos_database.dart';
import '../../notifier/cart_notifier.dart';
import '../../notifier/table_notifier.dart';
import '../../notifier/theme_color.dart';
import '../../object/branch_link_product.dart';
import '../../object/order_detail.dart';
import '../../object/order_detail_cancel.dart';
import '../../object/printer.dart';
import '../../object/table.dart';
import '../../object/table_use.dart';
import '../../object/table_use_detail.dart';
import '../../object/user.dart';
import '../../translation/AppLocalizations.dart';
import '../logout_dialog.dart';

class CartRemoveDialog extends StatefulWidget {
  final cartProductItem? cartItem;
  final String currentPage;

  const CartRemoveDialog({Key? key, this.cartItem, required this.currentPage})
      : super(key: key);

  @override
  State<CartRemoveDialog> createState() => _CartRemoveDialogState();
}

class _CartRemoveDialogState extends State<CartRemoveDialog> {
  FlutterUsbPrinter flutterUsbPrinter = FlutterUsbPrinter();
  final adminPosPinController = TextEditingController();
  bool _submitted = false;
  List<User> adminData = [];
  List<Printer> printerList = [];
  List<OrderCache> cartCacheList = [], cartTableCacheList = [];
  List<OrderDetail> cartOrderDetailList = [];
  List<OrderModifierDetail> cartOrderModDetailList = [];
  List<TableUseDetail> cartTableUseDetail = [];
  OrderDetail? orderDetail;
  String? table_use_value, table_use_detail_value, branch_link_product_value, order_cache_value, order_detail_value, order_detail_cancel_value, table_value;
  bool _isLoaded = false, isButtonDisabled = false, isLogOut = false;
  int simpleIntInput = 1;
  bool willPop = true;


  late TableModel tableModel;

  @override
  void initState() {
    super.initState();
    readAllPrinters();
    if(widget.currentPage != 'menu'){
      readCartItemInfo();
    }

  }

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
    adminPosPinController.dispose();
  }


  String? get errorPassword {
    final text = adminPosPinController.value.text;
    //readAdminData(text);
    if (text.isEmpty) {
      return 'password_required';
    }
    return null;
  }

  void _submit(BuildContext context, CartModel cart) async {
    setState(() => _submitted = true);
    if (errorPassword == null && _isLoaded == true) {
      // Disable the button after it has been pressed
      await readAdminData(adminPosPinController.text, cart);
      // if(this.isLogOut == false){
      //   Navigator.of(context).pop();
      //   Navigator.of(context).pop();
      // }
      setState(() {
        isButtonDisabled = false;
      });
      return;
    } else {
      setState(() {
        isButtonDisabled = false;
      });
    }
  }

  closeDialog(BuildContext context) {
    return Navigator.of(context).pop(true);
  }

  Future showSecondDialog(BuildContext context, ThemeColor color, CartModel cart) {
    return showDialog(
      barrierDismissible: false,
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(builder: (context, StateSetter setState){
          return WillPopScope(
            onWillPop: () async => willPop,
            child: Center(
              child: SingleChildScrollView(
                physics: NeverScrollableScrollPhysics(),
                child: AlertDialog(
                  title: Text(AppLocalizations.of(context)!.translate('enter_admin_pin')),
                  content: SizedBox(
                    height: 100.0,
                    width: 350.0,
                    child: ValueListenableBuilder(
                        valueListenable: adminPosPinController,
                        builder: (context, TextEditingValue value, __) {
                          return Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: TextField(
                              autofocus: true,
                              onSubmitted: (input) {
                                setState(() {
                                  isButtonDisabled = true;
                                  willPop = false;
                                });
                                _submit(context, cart);
                              },
                              obscureText: true,
                              controller: adminPosPinController,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                errorText: _submitted
                                    ? errorPassword == null
                                    ? errorPassword
                                    : AppLocalizations.of(context)
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
                  ),
                  actions: <Widget>[
                    SizedBox(
                      width: MediaQuery.of(context).size.width > 900 && MediaQuery.of(context).size.height > 500 ? MediaQuery.of(context).size.width / 6 : MediaQuery.of(context).size.width / 4,
                      height: MediaQuery.of(context).size.width > 900 && MediaQuery.of(context).size.height > 500 ? MediaQuery.of(context).size.height / 12 : MediaQuery.of(context).size.height / 10,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: color.backgroundColor,
                        ),
                        child: Text(
                          AppLocalizations.of(context)!.translate('close'),
                          style: TextStyle(color: Colors.white),
                        ),
                        onPressed: isButtonDisabled
                            ? null
                            : () {
                          setState(() {
                            isButtonDisabled = true;
                          });
                          Navigator.of(context).pop();
                          Navigator.of(context).pop();
                        },
                      ),
                    ),
                    SizedBox(
                      width: MediaQuery.of(context).size.width > 900 && MediaQuery.of(context).size.height > 500 ? MediaQuery.of(context).size.width / 6 : MediaQuery.of(context).size.width / 4,
                      height: MediaQuery.of(context).size.width > 900 && MediaQuery.of(context).size.height > 500 ? MediaQuery.of(context).size.height / 12 : MediaQuery.of(context).size.height / 10,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: color.buttonColor,
                        ),
                        child: Text(
                          AppLocalizations.of(context)!.translate('yes'),
                          style: TextStyle(color: Colors.white),
                        ),
                        onPressed: isButtonDisabled
                            ? null
                            : () async {
                          setState(() {
                            isButtonDisabled = true;
                            willPop = false;
                          });
                          _submit(context, cart);
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        });
      }
    );
  }

  Future<Future<Object?>> openDialog({cartItem, currentPage}) async {
    return showGeneralDialog(
        barrierColor: Colors.black.withOpacity(0.5),
        transitionBuilder: (context, a1, a2, widget) {
          final curvedValue = Curves.easeInOutBack.transform(a1.value) - 1.0;
          return Transform(
            transform: Matrix4.translationValues(0.0, curvedValue * 200, 0.0),
            child: Opacity(
              opacity: a1.value,
              child: AdjustQuantityDialog(cartItem: cartItem, currentPage: currentPage,),
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

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeColor>(builder: (context, ThemeColor color, child) {
      return Consumer<CartModel>(builder: (context, CartModel cart, child) {
        return Consumer<TableModel>(builder: (context, TableModel tableModel, child) {
          this.tableModel = tableModel;
          return AlertDialog(
            title: Text(AppLocalizations.of(context)!.translate('confirm_remove_item')),
            content: Container(
              width: 400,
              height: 50,
              child: Text('${widget.cartItem!.product_name} ${AppLocalizations.of(context)?.translate('confirm_delete')}'),
            ),
            actions: <Widget>[
              // TextButton(
              //     child:
              //     Text('${AppLocalizations.of(context)?.translate('no')}'),
              //     onPressed: () {
              //       Navigator.of(context).pop();
              //     }),
              SizedBox(
                width: MediaQuery.of(context).size.width > 900 && MediaQuery.of(context).size.height > 500 ? MediaQuery.of(context).size.width / 6 : MediaQuery.of(context).size.width / 4,
                height: MediaQuery.of(context).size.width > 900 && MediaQuery.of(context).size.height > 500 ? MediaQuery.of(context).size.height / 12 : MediaQuery.of(context).size.height / 10,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: color.backgroundColor,
                  ),
                  child: Text(
                    AppLocalizations.of(context)!.translate('close'),
                    style: TextStyle(color: Colors.white),
                  ),
                  onPressed: isButtonDisabled
                      ? null
                      : () {
                    setState(() {
                      isButtonDisabled = true;
                    });
                    Navigator.of(context).pop();
                  },
                ),
              ),
              SizedBox(
                width: MediaQuery.of(context).size.width > 900 && MediaQuery.of(context).size.height > 500 ? MediaQuery.of(context).size.width / 6 : MediaQuery.of(context).size.width / 4,
                height: MediaQuery.of(context).size.width > 900 && MediaQuery.of(context).size.height > 500 ? MediaQuery.of(context).size.height / 12 : MediaQuery.of(context).size.height / 10,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: color.buttonColor,
                  ),
                  child: Text(
                    AppLocalizations.of(context)!.translate('yes'),
                    style: TextStyle(color: Colors.white),
                  ),
                  onPressed: isButtonDisabled
                      ? null
                      : () async {
                    if (widget.currentPage == 'menu') {
                      cart.removeItem(widget.cartItem!);
                      if (cart.cartNotifierItem.isEmpty) {
                        cart.removeAllTable();
                      }
                      Navigator.of(context).pop();
                    } else {
                      if(widget.cartItem!.quantity == 1 || widget.cartItem!.quantity! is double ){
                        DateFormat dateFormat = DateFormat("yyyy-MM-dd HH:mm:ss");
                        String dateTime = dateFormat.format(DateTime.now());
                        final prefs = await SharedPreferences.getInstance();
                        final String? pos_user = prefs.getString('pos_pin_user');
                        Map<String, dynamic> userMap = json.decode(pos_user!);
                        User userData = User.fromJson(userMap);
                        if(userData.edit_price_without_pin != 1) {
                          showSecondDialog(context, color, cart);
                        } else {
                          callUpdateCart(userData, dateTime, cart);
                          Navigator.of(context).pop();
                        }
                      } else {
                        openDialog(cartItem: widget.cartItem, currentPage: widget.currentPage);
                      }
                    }
                  },
                ),
              ),
            ],
          );
        });
      });
    });
  }

  Future<Future<Object?>> openLogOutDialog() async {
    return showGeneralDialog(
        barrierColor: Colors.black.withOpacity(0.5),
        transitionBuilder: (context, a1, a2, widget) {
          final curvedValue = Curves.easeInOutBack.transform(a1.value) - 1.0;
          return Transform(
            transform: Matrix4.translationValues(0.0, curvedValue * 200, 0.0),
            child: Opacity(
              opacity: a1.value,
              child: LogoutConfirmDialog(),
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

  readCartItemInfo() async {
    //get cart item order cache
    List<OrderCache> cacheData = await PosDatabase.instance.readSpecificOrderCache(widget.cartItem!.order_cache_sqlite_id!);
    cartCacheList = List.from(cacheData);

    if(widget.currentPage != 'other order'){
      //get table use order cache
      List<OrderCache> tableCacheData = await PosDatabase.instance.readTableOrderCache(cacheData[0].table_use_key!);
      cartTableCacheList = List.from(tableCacheData);

      //get table use detail
      List<TableUseDetail> tableDetailData = await PosDatabase.instance.readAllTableUseDetail(cacheData[0].table_use_sqlite_id!);
      cartTableUseDetail = List.from(tableDetailData);
    }

    //get cart item order cache order detail
    List<OrderDetail> orderDetailData = await PosDatabase.instance.readTableOrderDetail(widget.cartItem!.order_cache_key!);
    cartOrderDetailList = List.from(orderDetailData);

    OrderDetail cartItemOrderDetail = await PosDatabase.instance.readSpecificOrderDetailByLocalId(int.parse(widget.cartItem!.order_detail_sqlite_id!));
    orderDetail = cartItemOrderDetail;

    //get modifier detail length
    List<OrderModifierDetail> orderModData = await PosDatabase.instance.readOrderModifierDetail(widget.cartItem!.order_detail_sqlite_id!);
    cartOrderModDetailList = List.from(orderModData);

    _isLoaded = true;
  }

  readAdminData(String pin, CartModel cart) async {
    print("readAdminData");
    List<String> _posTableValue = [];
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? pos_user = prefs.getString('pos_pin_user');
      Map userObject = json.decode(pos_user!);
      DateFormat dateFormat = DateFormat("yyyy-MM-dd HH:mm:ss");
      String dateTime = dateFormat.format(DateTime.now());

      //List<User> userData = await PosDatabase.instance.readSpecificUserWithRole(pin);
      User? userData = await PosDatabase.instance.readSpecificUserWithPin(pin);
      if (userData != null) {
        // if (userData.user_id == userObject['user_id']) {
        if(userData.edit_price_without_pin == 1) {
          if(cartTableCacheList.length <= 1 && cartOrderDetailList.length > 1){
            print('delete order detail called');
            await callDeleteOrderDetail(userData, dateTime, cart);

          } else if(cartTableCacheList.length > 1 && cartOrderDetailList.length <= 1 ){
            print('delete partial order called');
            await callDeletePartialOrder(userData, dateTime, cart);

          } else if (cartTableCacheList.length > 1 && cartOrderDetailList.length > 1) {
            print('delete order detail 2 called');
            await callDeleteOrderDetail(userData, dateTime, cart);

          } else if(widget.currentPage == 'other order' && cartOrderDetailList.length > 1){
            print('delete not dine in called');
            await callDeleteOrderDetail(userData, dateTime, cart);

          } else {
            print('delete all called');
            await callDeleteAllOrder(userData, cartCacheList[0].table_use_sqlite_id!, dateTime, cart);
            for (int i = 0; i < cartTableUseDetail.length; i++) {
              //update all table to unused
              PosTable posTableData = await updatePosTableStatus(int.parse(cartTableUseDetail[i].table_sqlite_id!), 0, dateTime);
              _posTableValue.add(jsonEncode(posTableData));
            }
          }
          table_value = _posTableValue.toString();
          callPrinter(dateTime, cart);
          // await PrintReceipt().printDeleteList(printerList, widget.cartItem!.order_cache_sqlite_id!, dateTime);
          // await PrintReceipt().printKitchenDeleteList(printerList, widget.cartItem!.order_cache_sqlite_id!, widget.cartItem!.category_sqlite_id!, dateTime, cart);
          // if(connectivity.isConnect){
          //
          //   //syncUpdatedPosTableToCloud(_posTableValue.toString());
          // }
          Fluttertoast.showToast(backgroundColor: Color(0xFF24EF10), msg: AppLocalizations.of(context)!.translate('delete_successful'));
          tableModel.changeContent(true);
          cart.removeAllTable();
          cart.removeAllCartItem();
          cart.removePromotion();

          //sync to cloud
          syncAllToCloud();

          if (this.isLogOut == false) {
            Navigator.of(context).pop();
            Navigator.of(context).pop();
          }
        } else {
          Fluttertoast.showToast(backgroundColor: Color(0xFFFF0000), msg: "${AppLocalizations.of(context)?.translate('no_permission')}");
        }

      } else {
        Fluttertoast.showToast(
            backgroundColor: Color(0xFFFF0000), msg: "${AppLocalizations.of(context)?.translate('user_not_found')}");
      }

    } catch (e) {
      print('delete error ${e}');
    }
  }

  callUpdateCart(User userData, String dateTime, CartModel cart) async {
    List<String> _posTableValue = [];
    if(cartTableCacheList.length <= 1 && cartOrderDetailList.length > 1){
      print('delete order detail called');
      await callDeleteOrderDetail(userData, dateTime, cart);

    } else if(cartTableCacheList.length > 1 && cartOrderDetailList.length <= 1 ){
      print('delete partial order called');
      await callDeletePartialOrder(userData, dateTime, cart);

    } else if (cartTableCacheList.length > 1 && cartOrderDetailList.length > 1) {
      print('delete order detail 2 called');
      await callDeleteOrderDetail(userData, dateTime, cart);

    } else if(widget.currentPage == 'other order' && cartOrderDetailList.length > 1){
      print('delete not dine in called');
      await callDeleteOrderDetail(userData, dateTime, cart);

    } else {
      print('delete all called');
      await callDeleteAllOrder(userData, cartCacheList[0].table_use_sqlite_id!, dateTime, cart);
      for (int i = 0; i < cartTableUseDetail.length; i++) {
        //update all table to unused
        PosTable posTableData = await updatePosTableStatus(int.parse(cartTableUseDetail[i].table_sqlite_id!), 0, dateTime);
        _posTableValue.add(jsonEncode(posTableData));
      }
    }
    table_value = _posTableValue.toString();
    callPrinter(dateTime, cart);

    Fluttertoast.showToast(backgroundColor: Color(0xFF24EF10), msg: AppLocalizations.of(context)!.translate('delete_successful'));
    tableModel.changeContent(true);
    cart.removeAllTable();
    cart.removeAllCartItem();
    cart.removePromotion();
    syncAllToCloud();
  }

  callPrinter(String dateTime, CartModel cart) async {
    int printStatus = await PrintReceipt().printDeleteList(printerList, widget.cartItem!.order_cache_sqlite_id!, dateTime);
    if(printStatus == 1){
      Fluttertoast.showToast(
          backgroundColor: Colors.red,
          msg: "${AppLocalizations.of(context)?.translate('printer_not_connected')}");
    } else if (printStatus == 2){
      Fluttertoast.showToast(
          backgroundColor: Colors.orangeAccent,
          msg: "${AppLocalizations.of(context)?.translate('printer_connection_timeout')}");
    }
    int kitchenPrintStatus = await PrintReceipt().printKitchenDeleteList(printerList, widget.cartItem!.order_cache_sqlite_id!, widget.cartItem!.category_sqlite_id!, dateTime, cart);
    if(kitchenPrintStatus == 1){
      Fluttertoast.showToast(
          backgroundColor: Colors.red,
          msg: "${AppLocalizations.of(context)?.translate('printer_not_connected')}");
    } else if (kitchenPrintStatus == 2){
      Fluttertoast.showToast(
          backgroundColor: Colors.orangeAccent,
          msg: "${AppLocalizations.of(context)?.translate('printer_connection_timeout')}");
    }
  }

  updateOrderDetailQuantity(String dateTime, CartModel cart) async {
    List<String> _value = [];
    try{
      OrderDetail orderDetailObject = OrderDetail(
          updated_at: dateTime,
          sync_status: orderDetail!.sync_status == 0 ? 0 : 2,
          status: 0,
          quantity: '0',
          order_detail_sqlite_id: int.parse(widget.cartItem!.order_detail_sqlite_id!),
          branch_link_product_sqlite_id: widget.cartItem!.branch_link_product_sqlite_id);

      int data = await PosDatabase.instance.updateOrderDetailQuantity(orderDetailObject);
      if(data == 1){
        OrderDetail detailData = await PosDatabase.instance.readSpecificOrderDetailByLocalId(orderDetailObject.order_detail_sqlite_id!);
        if(orderDetailObject.branch_link_product_sqlite_id != null && orderDetailObject.branch_link_product_sqlite_id != ''){
          await updateProductStock(orderDetailObject.branch_link_product_sqlite_id!, 1, dateTime);
        }
        _value.add(jsonEncode(detailData.syncJson()));
      }
    } catch(e){
      print("update order detail quantity error: $e");
    }

    // order_detail_value = _value.toString();
    //syncUpdatedOrderDetailToCloud(_value.toString());
  }

  generateOrderDetailCancelKey(OrderDetailCancel orderDetailCancel) async {
    final prefs = await SharedPreferences.getInstance();
    final int? device_id = prefs.getInt('device_id');
    var bytes = orderDetailCancel.created_at!.replaceAll(new RegExp(r'[^0-9]'), '') +
        orderDetailCancel.order_detail_cancel_sqlite_id.toString() +
        device_id.toString();
    return md5.convert(utf8.encode(bytes)).toString();
  }

  insertOrderDetailCancelKey(OrderDetailCancel orderDetailCancel, String dateTime) async {
    OrderDetailCancel? data;
    String? key = await generateOrderDetailCancelKey(orderDetailCancel);
    if (key != null) {
      OrderDetailCancel object = OrderDetailCancel(
          order_detail_cancel_key: key,
          sync_status: 0,
          updated_at: dateTime,
          order_detail_cancel_sqlite_id: orderDetailCancel.order_detail_cancel_sqlite_id
      );
      int uniqueKey = await PosDatabase.instance.updateOrderDetailCancelUniqueKey(object);
      if (uniqueKey == 1) {
        OrderDetailCancel orderDetailCancelData = await PosDatabase.instance.readSpecificOrderDetailCancelByLocalId(object.order_detail_cancel_sqlite_id!);
        data = orderDetailCancelData;
      }
    }
    return data;
  }

  createOrderDetailCancel(User user, String dateTime) async {
    List<String> _value = [];
    OrderDetail data = await PosDatabase.instance.readSpecificOrderDetailByLocalId(int.parse(widget.cartItem!.order_detail_sqlite_id!));
    OrderDetailCancel object =  OrderDetailCancel(
      order_detail_cancel_id: 0,
      order_detail_cancel_key: '',
      order_detail_sqlite_id: widget.cartItem?.order_detail_sqlite_id,
      order_detail_key: data.order_detail_key,
      quantity: data.quantity,
      cancel_by: user.name,
      cancel_by_user_id: user.user_id.toString(),
      settlement_sqlite_id: '',
      settlement_key: '',
      status: 0,
      sync_status: 0,
      created_at: dateTime,
      updated_at: '',
      soft_delete: '',
    );
    OrderDetailCancel orderDetailCancel = await PosDatabase.instance.insertSqliteOrderDetailCancel(object);
    OrderDetailCancel updateData = await insertOrderDetailCancelKey(orderDetailCancel, dateTime);
    _value.add(jsonEncode(updateData));
    order_detail_cancel_value = _value.toString();
    //syncOrderDetailCancelToCloud(_value.toString());
  }

  // syncOrderDetailCancelToCloud(String value) async {
  //   bool _hasInternetAccess = await Domain().isHostReachable();
  //   if (_hasInternetAccess) {
  //     Map response = await Domain().SyncOrderDetailCancelToCloud(value);
  //     if (response['status'] == '1') {
  //       List responseJson = response['data'];
  //       int data = await PosDatabase.instance.updateOrderDetailCancelSyncStatusFromCloud(responseJson[0]['order_detail_cancel_key']);
  //     }
  //   }
  // }

  // syncUpdatedPosTableToCloud(String posTableValue) async {
  //   bool _hasInternetAccess = await Domain().isHostReachable();
  //   if(_hasInternetAccess){
  //     Map response = await Domain().SyncUpdatedPosTableToCloud(posTableValue);
  //     if (response['status'] == '1') {
  //       List responseJson = response['data'];
  //       for (var i = 0; i < responseJson.length; i++) {
  //         int syncData = await PosDatabase.instance.updatePosTableSyncStatusFromCloud(responseJson[i]['table_id']);
  //       }
  //     }
  //   }
  // }

  // syncOrderModifierDetailToCloud(String orderModDetailValue) async {
  //   bool _hasInternetAccess = await Domain().isHostReachable();
  //   if(_hasInternetAccess){
  //     Map modResponse = await Domain().SyncOrderModifierDetailToCloud(orderModDetailValue);
  //     if(modResponse['status'] == '1'){
  //       List responseJson = modResponse['data'];
  //       for(int i = 0 ; i <responseJson.length; i++){
  //         int syncData = await PosDatabase.instance.updateOrderModifierDetailSyncStatusFromCloud(responseJson[i]['order_modifier_detail_key']);
  //       }
  //     }
  //   }
  // }

  readAllPrinters() async {
    printerList = await PrintReceipt().readAllPrinters();
  }

  callDeleteOrderDetail(User user, String dateTime, CartModel cart) async {
    await createOrderDetailCancel(user, dateTime);
    await updateOrderDetailQuantity(dateTime, cart);
    List<String> _value = [];
    OrderDetail orderDetailObject = OrderDetail(
        updated_at: dateTime,
        sync_status: orderDetail!.sync_status == 0 ? 0 : 2,
        status: 1,
        cancel_by: user.name,
        cancel_by_user_id: user.user_id.toString(),
        order_detail_sqlite_id: int.parse(widget.cartItem!.order_detail_sqlite_id!),
    );

    int deleteOrderDetailData = await PosDatabase.instance.updateOrderDetailStatus(orderDetailObject);
    if(deleteOrderDetailData == 1){
      //sync to cloud
      OrderDetail detailData = await PosDatabase.instance.readSpecificOrderDetailByLocalId(orderDetailObject.order_detail_sqlite_id!);
      _value.add(jsonEncode(detailData.syncJson()));
      await updateOrderCacheSubtotal(detailData.order_cache_sqlite_id!, detailData.price, detailData.quantity, dateTime);
      //print('value: ${_value.toString()}');
    }
    order_detail_value = _value.toString();
    //syncUpdatedOrderDetailToCloud(_value.toString());
  }

  updateOrderCacheSubtotal(String orderCacheLocalId, price, quantity, String dateTime) async {
    double subtotal = 0.0;
    OrderCache data = await PosDatabase.instance.readSpecificOrderCacheByLocalId(int.parse(orderCacheLocalId));
    subtotal = double.parse(data.total_amount!) - double.parse(price);
    OrderCache orderCache = OrderCache(
      order_cache_sqlite_id: data.order_cache_sqlite_id,
      total_amount: subtotal.toStringAsFixed(2),
      sync_status: data.sync_status == 0 ? 0 : 2,
      updated_at: dateTime
    );
    int status = await PosDatabase.instance.updateOrderCacheSubtotal(orderCache);
    if(status == 1){
      await getOrderCacheValue(orderCache);
    }
  }

  updateProductStock(String branch_link_product_sqlite_id, int quantity, String dateTime) async{
    try{
      List<String> _value = [];
      int _totalStockQty = 0, updateStock = 0;
      BranchLinkProduct? object;
      List<BranchLinkProduct> checkData = await PosDatabase.instance.readSpecificBranchLinkProduct(branch_link_product_sqlite_id);
      if(checkData.isNotEmpty){
        switch(checkData[0].stock_type){
          case '1': {
            _totalStockQty = int.parse(checkData[0].daily_limit!) + quantity;
            object = BranchLinkProduct(
                updated_at: dateTime,
                sync_status: 2,
                daily_limit: _totalStockQty.toString(),
                branch_link_product_sqlite_id: int.parse(branch_link_product_sqlite_id)
            );
            updateStock = await PosDatabase.instance.updateBranchLinkProductDailyLimit(object);
          }break;
          case '2': {
            _totalStockQty = int.parse(checkData[0].stock_quantity!) + quantity;
            object = BranchLinkProduct(
                updated_at: dateTime,
                sync_status: 2,
                stock_quantity: _totalStockQty.toString(),
                branch_link_product_sqlite_id: int.parse(branch_link_product_sqlite_id)
            );
            updateStock = await PosDatabase.instance.updateBranchLinkProductStock(object);
          }break;
          default: {
            updateStock = 0;
            _value = [];
          }
        }
        if(updateStock == 1){
          List<BranchLinkProduct> updatedData = await PosDatabase.instance.readSpecificBranchLinkProduct(branch_link_product_sqlite_id);
          _value.add(jsonEncode(updatedData[0].toJson()));
        }
        branch_link_product_value = _value.toString();
      }
    } catch(e){
      print("remove cart dialog update product stock error: $e");
      branch_link_product_value = null;
    }

    //sync to cloud
    //syncBranchLinkProductStock(value.toString());
  }

  // syncBranchLinkProductStock(String value) async {
  //   bool _hasInternetAccess = await Domain().isHostReachable();
  //   if(_hasInternetAccess) {
  //     Map orderDetailResponse = await Domain().SyncBranchLinkProductToCloud(value);
  //     if (orderDetailResponse['status'] == '1') {
  //       List responseJson = orderDetailResponse['data'];
  //       for (int i = 0; i < responseJson.length; i++) {
  //         int syncUpdated = await PosDatabase.instance.updateBranchLinkProductSyncStatusFromCloud(responseJson[i]['branch_link_product_id']);
  //       }
  //     }
  //   }
  // }

  // syncUpdatedOrderDetailToCloud(String value) async {
  //   bool _hasInternetAccess = await Domain().isHostReachable();
  //   if(_hasInternetAccess){
  //     Map response = await Domain().SyncOrderDetailToCloud(value.toString());
  //     if (response['status'] == '1') {
  //       List responseJson = response['data'];
  //       int orderDetailData = await PosDatabase.instance.updateOrderDetailSyncStatusFromCloud(responseJson[0]['order_detail_key']);
  //     }
  //   }
  // }

  callDeleteAllOrder(User user, String currentTableUseId, String dateTime, CartModel cartModel) async {
    if(widget.currentPage != 'other_order'){
      await deleteCurrentTableUseDetail(currentTableUseId, dateTime);
      await deleteCurrentTableUseId(int.parse(currentTableUseId), dateTime);
    }
    await callDeleteOrderDetail(user, dateTime, cartModel);
    await deleteCurrentOrderCache(user, dateTime);
  }

  callDeletePartialOrder(User user, String dateTime, CartModel cartModel) async {
    await callDeleteOrderDetail(user, dateTime, cartModel);
    await deleteCurrentOrderCache(user, dateTime);
  }

  updatePosTableStatus(int tableId, int status, String dateTime) async {
    PosTable? _data;
    PosTable posTableData = PosTable(
        table_use_detail_key: '',
        table_use_key: '',
        status: status,
        updated_at: dateTime,
        table_sqlite_id: tableId);
    int updatedStatus = await PosDatabase.instance.updatePosTableStatus(posTableData);
    int removeKey = await PosDatabase.instance.removePosTableTableUseDetailKey(posTableData);
    if(updatedStatus == 1 && removeKey == 1){
      List<PosTable> posTable  = await PosDatabase.instance.readSpecificTable(posTableData.table_sqlite_id.toString());
      if(posTable[0].sync_status == 2){
        _data = posTable[0];
      }
    }
    return _data;
  }

  deleteCurrentOrderCache(User user, String dateTime) async {
    try {
      OrderCache orderCacheObject = OrderCache(
          sync_status: cartCacheList[0].sync_status == 0 ? 0 : 2,
          cancel_by: user.name,
          cancel_by_user_id: user.user_id.toString(),
          order_cache_sqlite_id: int.parse(widget.cartItem!.order_cache_sqlite_id!)
      );
      int deletedOrderCache = await PosDatabase.instance.cancelOrderCache(orderCacheObject);
      //sync to cloud
      if(deletedOrderCache == 1){
        await getOrderCacheValue(orderCacheObject);
        // OrderCache orderCacheData = await PosDatabase.instance.readSpecificOrderCacheByLocalId(orderCacheObject.order_cache_sqlite_id!);
        // if(orderCacheData.sync_status != 1){
        //   _orderCacheValue.add(jsonEncode(orderCacheData));
        // }
        // order_cache_value = _orderCacheValue.toString();
        //syncOrderCacheToCloud(_orderCacheValue.toString());
      }
    } catch (e) {
      print('delete order cache error: ${e}');
    }
  }

  getOrderCacheValue(OrderCache orderCacheObject) async {
    List<String> _orderCacheValue = [];
    OrderCache orderCacheData = await PosDatabase.instance.readSpecificOrderCacheByLocalId(orderCacheObject.order_cache_sqlite_id!);
    print('order cache return data: ${orderCacheData.sync_status}');
    if(orderCacheData.sync_status != 1){
      _orderCacheValue.add(jsonEncode(orderCacheData));
    }
    order_cache_value = _orderCacheValue.toString();
    print('order cache subtotal value: $order_cache_value');
  }

  // syncOrderCacheToCloud(String value) async {
  //   bool _hasInternetAccess = await Domain().isHostReachable();
  //   if (_hasInternetAccess) {
  //     Map response = await Domain().SyncOrderCacheToCloud(value);
  //     if(response['status'] == '1'){
  //       List responseJson = response['data'];
  //       int syncData = await PosDatabase.instance.updateOrderCacheSyncStatusFromCloud(responseJson[0]['order_cache_key']);
  //     }
  //   }
  // }

  deleteCurrentTableUseDetail(String currentTableUseId, String dateTime) async {
    print('current table use id: ${currentTableUseId}');
    List<String> _value = [];
    try {
      List<TableUseDetail> checkData  = await PosDatabase.instance.readAllTableUseDetail(currentTableUseId);
      for(int i = 0; i < checkData.length; i++){
        TableUseDetail tableUseDetailObject = TableUseDetail(
          updated_at: dateTime,
          sync_status: checkData[i].sync_status == 0 ? 0 : 2,
          status: 1,
          table_use_sqlite_id: currentTableUseId,
          table_use_detail_sqlite_id: checkData[i].table_use_detail_sqlite_id
        );
        int deleteStatus = await PosDatabase.instance.deleteTableUseDetail(tableUseDetailObject);
        if(deleteStatus == 1){
          TableUseDetail detailData = await PosDatabase.instance.readSpecificTableUseDetailByLocalId(tableUseDetailObject.table_use_detail_sqlite_id!);
          _value.add(jsonEncode(detailData));
        }
      }
      table_use_detail_value = _value.toString();
      //sync to cloud
      //syncTableUseDetail(_value.toString());
    } catch (e) {
      print(e);
      Fluttertoast.showToast(
          backgroundColor: Color(0xFFFF0000),
          msg: AppLocalizations.of(context)!.translate('delete_current_table_use_detail_error')+" $e");
    }
  }

  // syncTableUseDetail(String value) async {
  //   bool _hasInternetAccess = await Domain().isHostReachable();
  //   if(_hasInternetAccess){
  //     Map data = await Domain().SyncTableUseDetailToCloud(value);
  //     if(data['status'] == '1'){
  //       List responseJson = data['data'];
  //       for (var i = 0; i < responseJson.length; i++) {
  //         int tablaUseDetailData = await PosDatabase.instance.updateTableUseDetailSyncStatusFromCloud(responseJson[i]['table_use_detail_key']);
  //       }
  //     }
  //   }
  // }

  deleteCurrentTableUseId(int currentTableUseId, String dateTime) async {
    List<String> _value = [];
    try {
      TableUse checkData = await PosDatabase.instance.readSpecificTableUseIdByLocalId(currentTableUseId);
      TableUse tableUseObject = TableUse(
        updated_at: dateTime,
        sync_status: checkData.sync_status == 0 ? 0 : 2,
        status: 1,
        table_use_sqlite_id: currentTableUseId,
      );
      int deletedTableUse = await PosDatabase.instance.deleteTableUseID(tableUseObject);
      if(deletedTableUse == 1){
        //sync to cloud
        TableUse tableUseData = await PosDatabase.instance.readSpecificTableUseIdByLocalId(tableUseObject.table_use_sqlite_id!);
        _value.add(jsonEncode(tableUseData));
        table_use_value = _value.toString();
        //syncTableUseIdToCloud(_value.toString());
      }
    } catch (e) {
      Fluttertoast.showToast(
          backgroundColor: Color(0xFFFF0000),
          msg: AppLocalizations.of(context)!.translate('delete_current_table_use_id_error')+" ${e}");
    }
  }

  // syncTableUseIdToCloud(String value) async {
  //   bool _hasInternetAccess = await Domain().isHostReachable();
  //   if(_hasInternetAccess){
  //     Map data = await Domain().SyncTableUseToCloud(value);
  //     if (data['status'] == '1') {
  //       List responseJson = data['data'];
  //       int tablaUseData = await PosDatabase.instance.updateTableUseSyncStatusFromCloud(responseJson[0]['table_use_key']);
  //     }
  //   }
  // }

  syncAllToCloud() async {
    try{
      if(mainSyncToCloud.count == 0){
        mainSyncToCloud.count = 1;
        final prefs = await SharedPreferences.getInstance();
        final int? device_id = prefs.getInt('device_id');
        final String? login_value = prefs.getString('login_value');
        Map data = await Domain().syncLocalUpdateToCloud(
            device_id: device_id.toString(),
            value: login_value,
            table_use_value: this.table_use_value,
            table_use_detail_value: this.table_use_detail_value,
            order_cache_value: this.order_cache_value,
            order_detail_value: this.order_detail_value,
            order_detail_cancel_value: this.order_detail_cancel_value,
            branch_link_product_value: this.branch_link_product_value,
            table_value: this.table_value
        );
        //if success update local sync status
        if (data['status'] == '1') {
          List responseJson = data['data'];
          if(responseJson.isNotEmpty){
            for(int i = 0; i < responseJson.length; i++){
              switch(responseJson[i]['table_name']){
                case 'tb_table_use_detail': {
                  await PosDatabase.instance.updateTableUseDetailSyncStatusFromCloud(responseJson[i]['table_use_detail_key']);
                }
                break;
                case 'tb_table_use': {
                  await PosDatabase.instance.updateTableUseSyncStatusFromCloud(responseJson[i]['table_use_key']);
                }
                break;
                case 'tb_order_detail_cancel': {
                  await PosDatabase.instance.updateOrderDetailCancelSyncStatusFromCloud(responseJson[i]['order_detail_cancel_key']);
                }
                break;
                case 'tb_branch_link_product': {
                  await PosDatabase.instance.updateBranchLinkProductSyncStatusFromCloud(responseJson[i]['branch_link_product_id']);
                }
                break;
                case 'tb_order_detail': {
                  await PosDatabase.instance.updateOrderDetailSyncStatusFromCloud(responseJson[i]['order_detail_key']);
                }
                break;
                case 'tb_order_cache': {
                  await PosDatabase.instance.updateOrderCacheSyncStatusFromCloud(responseJson[i]['order_cache_key']);
                }
                break;
                case 'tb_table': {
                  await PosDatabase.instance.updatePosTableSyncStatusFromCloud(responseJson[i]['table_id']);
                }
                break;
                default: {
                  return;
                }
              }
            }
            mainSyncToCloud.resetCount();
          } else {
            mainSyncToCloud.resetCount();
          }
        } else if(data['status'] == '7'){
          this.isLogOut = true;
          mainSyncToCloud.resetCount();
        } else if(data['status'] == '8') {
          mainSyncToCloud.resetCount();
          throw TimeoutException("Time out");
        } else {
          mainSyncToCloud.resetCount();
        }
        // bool _hasInternetAccess = await Domain().isHostReachable();
        // if (_hasInternetAccess) {
        //
        // } else {
        //   mainSyncToCloud.resetCount();
        // }
      }
    } catch(e){
      print("remove cart error: $e");
      mainSyncToCloud.resetCount();
      //return 1;
    }
  }
}
