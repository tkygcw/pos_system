import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';
import 'package:pos_system/main.dart';
import 'package:pos_system/object/order_detail_cancel.dart';
import 'package:provider/provider.dart';
import 'package:quantity_input/quantity_input.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:crypto/crypto.dart';

import '../../database/domain.dart';
import '../../database/pos_database.dart';
import '../../notifier/cart_notifier.dart';
import '../../notifier/table_notifier.dart';
import '../../notifier/theme_color.dart';
import '../../object/branch_link_product.dart';
import '../../object/cart_product.dart';
import '../../object/order_cache.dart';
import '../../object/order_detail.dart';
import '../../object/order_modifier_detail.dart';
import '../../object/print_receipt.dart';
import '../../object/printer.dart';
import '../../object/table.dart';
import '../../object/table_use.dart';
import '../../object/table_use_detail.dart';
import '../../object/user.dart';
import '../../translation/AppLocalizations.dart';
import '../logout_dialog.dart';

class AdjustQuantityDialog extends StatefulWidget {
  final cartProductItem cartItem;
  final String currentPage;

  const AdjustQuantityDialog(
      {Key? key, required this.cartItem, required this.currentPage})
      : super(key: key);

  @override
  State<AdjustQuantityDialog> createState() => _AdjustQuantityDialogState();
}

class _AdjustQuantityDialogState extends State<AdjustQuantityDialog> {
  int simpleIntInput = 1;
  late int currentQuantity;
  final adminPosPinController = TextEditingController();
  List<User> adminData = [];
  List<Printer> printerList = [];
  List<OrderCache> cartCacheList = [], cartTableCacheList = [];
  List<OrderDetail> cartOrderDetailList = [];
  List<OrderModifierDetail> cartOrderModDetailList = [];
  List<TableUseDetail> cartTableUseDetail = [];
  String? table_use_value,
      table_use_detail_value,
      branch_link_product_value,
      order_cache_value,
      order_detail_value,
      order_detail_cancel_value,
      table_value;
  OrderDetail? orderDetail;
  bool isLogOut = false;
  bool _isLoaded = false;
  bool _submitted = false;
  bool isButtonDisabled = false;
  bool willPop = true;

  late TableModel tableModel;

  @override
  void initState() {
    super.initState();
    readAllPrinters();
    readCartItemInfo();
    currentQuantity = widget.cartItem.quantity!;
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
    if (errorPassword == null) {
      await readAdminData(adminPosPinController.text, cart);
      if (this.isLogOut == false) {
        Navigator.of(context).pop();
        Navigator.of(context).pop();
        Navigator.of(context).pop();
      }
      return;
    } else {
      setState(() {
        isButtonDisabled = false;
      });
    }
  }

  Future showSecondDialog(
      BuildContext context, ThemeColor color, CartModel cart) {
    return showDialog(
        barrierDismissible: false,
        context: context,
        builder: (BuildContext context) {
          return StatefulBuilder(builder: (context, StateSetter setState) {
            return WillPopScope(
              onWillPop: () async => willPop,
              child: Center(
                child: SingleChildScrollView(
                  physics: NeverScrollableScrollPhysics(),
                  child: AlertDialog(
                    title: Text(AppLocalizations.of(context)!
                        .translate('enter_current_user_pin')),
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
                                    borderSide: BorderSide(
                                        color: color.backgroundColor),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderSide: BorderSide(
                                        color: color.backgroundColor),
                                  ),
                                  labelText: "PIN",
                                ),
                              ),
                            );
                          }),
                    ),
                    actions: <Widget>[
                      TextButton(
                        child: Text(
                            '${AppLocalizations.of(context)?.translate('close')}'),
                        onPressed: isButtonDisabled
                            ? null
                            : () {
                                setState(() {
                                  isButtonDisabled = true;
                                });
                                Navigator.of(context).pop();
                                setState(() {
                                  isButtonDisabled = false;
                                });
                              },
                      ),
                      TextButton(
                        child: Text(
                            '${AppLocalizations.of(context)?.translate('yes')}'),
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
                    ],
                  ),
                ),
              ),
            );
          });
        });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeColor>(builder: (context, ThemeColor color, child) {
      return Consumer<CartModel>(builder: (context, CartModel cart, child) {
        return Consumer<TableModel>(
            builder: (context, TableModel tableModel, child) {
          this.tableModel = tableModel;
          return Center(
            child: SingleChildScrollView(
              physics: NeverScrollableScrollPhysics(),
              child: AlertDialog(
                title: Text(
                    AppLocalizations.of(context)!.translate('adjust_quantity')),
                content: Column(
                  children: [
                    SizedBox(
                      height: 100.0,
                      width: 350.0,
                      child: QuantityInput(
                        inputWidth: 273,
                        maxValue: widget.cartItem.quantity,
                        minValue: 0,
                        readOnly: true,
                        acceptsNegatives: false,
                        decoration: InputDecoration(
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                              color: Colors.black,
                            ),
                          ),
                        ),
                        buttonColor: Colors.black,
                        value: simpleIntInput,
                        onChanged: (value) => setState(() {
                          simpleIntInput = int.parse(value.replaceAll(',', ''));
                        }),
                      ),
                    ),
                    Container(
                      // Customize your Container's properties here
                      child: Center(
                        child: Text(
                            AppLocalizations.of(context)!.translate('change_quantity_to')+' ${getFinalQuantity()}'),
                      ),
                    ),
                  ],
                ),
                actions: <Widget>[
                  TextButton(
                    child: Text(
                        '${AppLocalizations.of(context)?.translate('close')}'),
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                  ),
                  TextButton(
                    child: Text(
                        '${AppLocalizations.of(context)?.translate('yes')}'),
                    onPressed: isButtonDisabled
                        ? null
                        : () async {
                            await showSecondDialog(context, color, cart);
                          },
                  ),
                ],
              ),
            ),
          );
        });
      });
    });
  }

  getFinalQuantity() {
    int temp = currentQuantity;
    try {
      temp -= simpleIntInput;
    } catch (e) {}
    return temp;
  }

  readAllPrinters() async {
    printerList = await PrintReceipt().readAllPrinters();
  }

  readCartItemInfo() async {
    //get cart item order cache
    List<OrderCache> cacheData = await PosDatabase.instance
        .readSpecificOrderCache(widget.cartItem.order_cache_sqlite_id!);
    cartCacheList = List.from(cacheData);

    if (widget.currentPage != 'other order') {
      //get table use order cache
      List<OrderCache> tableCacheData = await PosDatabase.instance
          .readTableOrderCache(cacheData[0].table_use_key!);
      cartTableCacheList = List.from(tableCacheData);

      //get table use detail
      List<TableUseDetail> tableDetailData = await PosDatabase.instance
          .readAllTableUseDetail(cacheData[0].table_use_sqlite_id!);
      cartTableUseDetail = List.from(tableDetailData);
    }

    //get cart item order cache order detail
    List<OrderDetail> orderDetailData = await PosDatabase.instance
        .readTableOrderDetail(widget.cartItem.order_cache_key!);
    cartOrderDetailList = List.from(orderDetailData);

    OrderDetail cartItemOrderDetail = await PosDatabase.instance
        .readSpecificOrderDetailByLocalId(
            int.parse(widget.cartItem.order_detail_sqlite_id!));
    orderDetail = cartItemOrderDetail;

    //get modifier detail length
    List<OrderModifierDetail> orderModData = await PosDatabase.instance
        .readOrderModifierDetail(widget.cartItem.order_detail_sqlite_id!);
    cartOrderModDetailList = List.from(orderModData);

    _isLoaded = true;
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

  readAdminData(String pin, CartModel cart) async {
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
        if (userData.user_id == userObject['user_id']) {
          if (simpleIntInput == widget.cartItem.quantity) {
            if (cartTableCacheList.length <= 1 &&
                cartOrderDetailList.length > 1) {
              // if(cartOrderModDetailList.isNotEmpty){
              //   _hasModifier = true;
              //   for(int i = 0; i < cartOrderModDetailList.length; i++){
              //     OrderModifierDetail deletedMod  = await deleteAllOrderModDetail(dateTime, cartOrderModDetailList[i]);
              //   }
              // }
              await callDeleteOrderDetail(userData, dateTime, cart);
            } else if (cartTableCacheList.length > 1 &&
                cartOrderDetailList.length <= 1) {
              // if(cartOrderModDetailList.isNotEmpty){
              //   _hasModifier = true;
              //   for(int i = 0; i < cartOrderModDetailList.length; i++){
              //     OrderModifierDetail deletedMod  = await deleteAllOrderModDetail(dateTime, cartOrderModDetailList[i]);
              //   }
              // }
              await callDeletePartialOrder(userData, dateTime, cart);
            } else if (cartTableCacheList.length > 1 &&
                cartOrderDetailList.length > 1) {
              // if(cartOrderModDetailList.isNotEmpty){
              //   _hasModifier = true;
              //   for(int i = 0; i < cartOrderModDetailList.length; i++){
              //     OrderModifierDetail deletedMod  = await deleteAllOrderModDetail(dateTime, cartOrderModDetailList[i]);
              //   }
              // }
              await callDeleteOrderDetail(userData, dateTime, cart);
            } else if (widget.currentPage == 'other order' &&
                cartOrderDetailList.length > 1) {
              // if(cartOrderModDetailList.isNotEmpty){
              //   _hasModifier = true;
              //   for(int i = 0; i < cartOrderModDetailList.length; i++){
              //     OrderModifierDetail deletedMod  = await deleteAllOrderModDetail(dateTime, cartOrderModDetailList[i]);
              //   }
              // }
              await callDeleteOrderDetail(userData, dateTime, cart);
            } else {
              // if(cartOrderModDetailList.isNotEmpty){
              //   _hasModifier = true;
              //   for(int i = 0; i < cartOrderModDetailList.length; i++){
              //     OrderModifierDetail deletedMod  = await deleteAllOrderModDetail(dateTime, cartOrderModDetailList[i]);
              //     _orderModDetailValue.add(jsonEncode(deletedMod));
              //   }
              // }
              await callDeleteAllOrder(userData,
                  cartCacheList[0].table_use_sqlite_id!, dateTime, cart);
              if (widget.currentPage != 'other order') {
                for (int i = 0; i < cartTableUseDetail.length; i++) {
                  //update all table to unused
                  PosTable posTableData = await updatePosTableStatus(
                      int.parse(cartTableUseDetail[i].table_sqlite_id!),
                      0,
                      dateTime);
                  _posTableValue.add(jsonEncode(posTableData));
                }
                table_value = _posTableValue.toString();
              }
              // tableModel.changeContent(true);
            }
          } else {
            await createOrderDetailCancel(userData, dateTime, cart);
            await updateOrderDetailQuantity(dateTime, cart);
            print('update order detail quantity & create order detail cancel');
          }
          await callPrinter(dateTime, cart);
          // await PrintReceipt().printDeleteList(printerList, widget.cartItem.order_cache_sqlite_id!, dateTime);
          // await PrintReceipt().printKitchenDeleteList(printerList, widget.cartItem.order_cache_sqlite_id!, widget.cartItem.category_sqlite_id!, dateTime, cart);
          //syncUpdatedPosTableToCloud(_posTableValue.toString());
          //print cancel receipt
          //await _printDeleteList(widget.cartItem!.orderCacheId!, dateTime);
          Fluttertoast.showToast(
              backgroundColor: Color(0xFF24EF10),
              msg:
                  AppLocalizations.of(context)!.translate('delete_successful'));
          tableModel.changeContent(true);
          cart.removeAllTable();
          cart.removeAllCartItem();
          cart.removePromotion();
          //sync to cloud
          await syncAllToCloud();
          print('is log out: ${this.isLogOut}');
          if (this.isLogOut == true) {
            openLogOutDialog();
            return;
          }
        } else {
          Fluttertoast.showToast(
              backgroundColor: Color(0xFFFF0000),
              msg:
                  "${AppLocalizations.of(context)?.translate('pin_not_match')}");
        }
      } else {
        Fluttertoast.showToast(
            backgroundColor: Color(0xFFFF0000),
            msg:
                "${AppLocalizations.of(context)?.translate('user_not_found')}");
      }
    } catch (e) {
      print('delete error ${e}');
    }
  }

  callPrinter(String dateTime, CartModel cart) async {
    int printStatus = await PrintReceipt().printDeleteList(
        printerList, widget.cartItem.order_cache_sqlite_id!, dateTime);
    if (printStatus == 1) {
      Fluttertoast.showToast(
          backgroundColor: Colors.red,
          msg:
              "${AppLocalizations.of(context)?.translate('printer_not_connected')}");
    } else if (printStatus == 2) {
      Fluttertoast.showToast(
          backgroundColor: Colors.orangeAccent,
          msg:
              "${AppLocalizations.of(context)?.translate('printer_connection_timeout')}");
    }
    int kitchenPrintStatus = await PrintReceipt().printKitchenDeleteList(
        printerList,
        widget.cartItem.order_cache_sqlite_id!,
        widget.cartItem.category_sqlite_id!,
        dateTime,
        cart);
    if (kitchenPrintStatus == 1) {
      Fluttertoast.showToast(
          backgroundColor: Colors.red,
          msg:
              "${AppLocalizations.of(context)?.translate('printer_not_connected')}");
    } else if (kitchenPrintStatus == 2) {
      Fluttertoast.showToast(
          backgroundColor: Colors.orangeAccent,
          msg:
              "${AppLocalizations.of(context)?.translate('printer_connection_timeout')}");
    }
  }

  generateOrderDetailCancelKey(OrderDetailCancel orderDetailCancel) async {
    final prefs = await SharedPreferences.getInstance();
    final int? device_id = prefs.getInt('device_id');
    var bytes =
        orderDetailCancel.created_at!.replaceAll(new RegExp(r'[^0-9]'), '') +
            orderDetailCancel.order_detail_cancel_sqlite_id.toString() +
            device_id.toString();
    return md5.convert(utf8.encode(bytes)).toString();
  }

  insertOrderDetailCancelKey(
      OrderDetailCancel orderDetailCancel, String dateTime) async {
    OrderDetailCancel? data;
    String? key = await generateOrderDetailCancelKey(orderDetailCancel);
    if (key != null) {
      OrderDetailCancel object = OrderDetailCancel(
          order_detail_cancel_key: key,
          sync_status: 0,
          updated_at: dateTime,
          order_detail_cancel_sqlite_id:
              orderDetailCancel.order_detail_cancel_sqlite_id);
      int uniqueKey =
          await PosDatabase.instance.updateOrderDetailCancelUniqueKey(object);
      if (uniqueKey == 1) {
        OrderDetailCancel orderDetailCancelData = await PosDatabase.instance
            .readSpecificOrderDetailCancelByLocalId(
                object.order_detail_cancel_sqlite_id!);
        data = orderDetailCancelData;
      }
    }
    return data;
  }

  createOrderDetailCancel(User user, String dateTime, CartModel cart) async {
    List<String> _value = [];
    OrderDetail data = await PosDatabase.instance
        .readSpecificOrderDetailByLocalId(
            int.parse(widget.cartItem.order_detail_sqlite_id!));
    OrderDetailCancel object = OrderDetailCancel(
      order_detail_cancel_id: 0,
      order_detail_cancel_key: '',
      order_detail_sqlite_id: widget.cartItem.order_detail_sqlite_id,
      order_detail_key: data.order_detail_key,
      quantity: simpleIntInput.toString(),
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
    OrderDetailCancel orderDetailCancel =
        await PosDatabase.instance.insertSqliteOrderDetailCancel(object);
    OrderDetailCancel updateData =
        await insertOrderDetailCancelKey(orderDetailCancel, dateTime);
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

  updateOrderDetailQuantity(String dateTime, CartModel cart) async {
    List<String> _value = [];
    int totalQty = 0;
    try{
      totalQty = widget.cartItem.quantity! - simpleIntInput;
      OrderDetail orderDetailObject = OrderDetail(
        updated_at: dateTime,
        sync_status: orderDetail!.sync_status == 0 ? 0 : 2,
        status: 0,
        quantity: totalQty.toString(),
        order_detail_sqlite_id: int.parse(widget.cartItem.order_detail_sqlite_id!),
        branch_link_product_sqlite_id: widget.cartItem.branch_link_product_sqlite_id,
      );
      int data = await PosDatabase.instance.updateOrderDetailQuantity(orderDetailObject);
      if (data == 1) {
        OrderDetail detailData = await PosDatabase.instance.readSpecificOrderDetailByLocalId(orderDetailObject.order_detail_sqlite_id!);
        await updateOrderCacheSubtotal(detailData.order_cache_sqlite_id!, detailData.price, simpleIntInput, dateTime);
        if(orderDetailObject.branch_link_product_sqlite_id != null && orderDetailObject.branch_link_product_sqlite_id != ''){
          await updateProductStock(orderDetailObject.branch_link_product_sqlite_id!, simpleIntInput, dateTime);
        }
        _value.add(jsonEncode(detailData.syncJson()));
      }
      order_detail_value = _value.toString();
    }catch(e){
      print("adjust quantity update order detail quantity error: $e");
    }
  }

  updateOrderCacheSubtotal(String orderCacheLocalId, price, quantity, String dateTime) async {
    double subtotal = 0.0;
    OrderCache data = await PosDatabase.instance.readSpecificOrderCacheByLocalId(int.parse(orderCacheLocalId));
    subtotal = double.parse(data.total_amount!) - double.parse(price) * quantity;
    OrderCache orderCache = OrderCache(
        order_cache_sqlite_id: data.order_cache_sqlite_id,
        total_amount: subtotal.toStringAsFixed(2),
        sync_status: data.sync_status == 0 ? 0 : 2,
        updated_at: dateTime);
    int status = await PosDatabase.instance.updateOrderCacheSubtotal(orderCache);
    if (status == 1) {
      getOrderCacheValue(orderCache);
    }
  }

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

  callDeleteOrderDetail(User user, String dateTime, CartModel cart) async {
    await createOrderDetailCancel(user, dateTime, cart);
    await updateOrderDetailQuantity(dateTime, cart);
    List<String> _value = [];
    OrderDetail orderDetailObject = OrderDetail(
        updated_at: dateTime,
        sync_status: orderDetail!.sync_status == 0 ? 0 : 2,
        status: 1,
        cancel_by: user.name,
        cancel_by_user_id: user.user_id.toString(),
        order_detail_sqlite_id: int.parse(widget.cartItem.order_detail_sqlite_id!),
    );

    int deleteOrderDetailData =
        await PosDatabase.instance.updateOrderDetailStatus(orderDetailObject);
    if (deleteOrderDetailData == 1) {
      //await updateProductStock(orderDetailObject.branch_link_product_sqlite_id!, int.parse(orderDetailObject.quantity!), dateTime);
      //sync to cloud
      OrderDetail detailData = await PosDatabase.instance.readSpecificOrderDetailByLocalId(orderDetailObject.order_detail_sqlite_id!);
      _value.add(jsonEncode(detailData.syncJson()));
      order_detail_value = _value.toString();
      //print('value: ${_value.toString()}');
    }
    //syncUpdatedOrderDetailToCloud(_value.toString());
  }

  updateProductStock(String branch_link_product_sqlite_id, int quantity, String dateTime) async {
    List<String> _value = [];
    int _totalStockQty = 0, updateStock = 0;
    BranchLinkProduct? object;
    try{
      List<BranchLinkProduct> checkData = await PosDatabase.instance.readSpecificBranchLinkProduct(branch_link_product_sqlite_id);
      if(checkData.isNotEmpty){
        switch(checkData[0].stock_type){
          case '1': {
            _totalStockQty = int.parse(checkData[0].daily_limit!) + quantity;
            object = BranchLinkProduct(
                updated_at: dateTime,
                sync_status: 2,
                daily_limit: _totalStockQty.toString(),
                branch_link_product_sqlite_id: int.parse(branch_link_product_sqlite_id));
            updateStock = await PosDatabase.instance.updateBranchLinkProductDailyLimit(object);
          }break;
          case'2': {
            _totalStockQty = int.parse(checkData[0].stock_quantity!) + quantity;
            object = BranchLinkProduct(
                updated_at: dateTime,
                sync_status: 2,
                stock_quantity: _totalStockQty.toString(),
                branch_link_product_sqlite_id: int.parse(branch_link_product_sqlite_id));
            updateStock = await PosDatabase.instance.updateBranchLinkProductStock(object);
          }break;
          default: {
            updateStock = 0;
          }
        }
        if (updateStock == 1) {
          List<BranchLinkProduct> updatedData = await PosDatabase.instance.readSpecificBranchLinkProduct(branch_link_product_sqlite_id);
          _value.add(jsonEncode(updatedData[0]));
          branch_link_product_value = _value.toString();
        }
      }
    }catch(e){
      print("adjust stock dialog update stock error: $e");
    }

    //print('branch link product value in function: ${branch_link_product_value}');
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

  callDeleteAllOrder(User user, String currentTableUseId, String dateTime,
      CartModel cartModel) async {
    print('delete all order called');
    if (widget.currentPage != 'other_order') {
      await deleteCurrentTableUseDetail(currentTableUseId, dateTime);
      await deleteCurrentTableUseId(int.parse(currentTableUseId), dateTime);
    }
    await callDeleteOrderDetail(user, dateTime, cartModel);
    await deleteCurrentOrderCache(user, dateTime);
  }

  callDeletePartialOrder(
      User user, String dateTime, CartModel cartModel) async {
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
    int updatedStatus =
        await PosDatabase.instance.updatePosTableStatus(posTableData);
    int removeKey = await PosDatabase.instance
        .removePosTableTableUseDetailKey(posTableData);
    if (updatedStatus == 1 && removeKey == 1) {
      List<PosTable> posTable = await PosDatabase.instance
          .readSpecificTable(posTableData.table_sqlite_id.toString());
      if (posTable[0].sync_status == 2) {
        _data = posTable[0];
      }
    }
    return _data;
  }

  deleteCurrentOrderCache(User user, String dateTime) async {
    print('delete order cache called');
    List<String> _orderCacheValue = [];
    try {
      OrderCache orderCacheObject = OrderCache(
          sync_status: cartCacheList[0].sync_status == 0 ? 0 : 2,
          cancel_by: user.name,
          cancel_by_user_id: user.user_id.toString(),
          order_cache_sqlite_id:
              int.parse(widget.cartItem.order_cache_sqlite_id!));
      int deletedOrderCache =
          await PosDatabase.instance.cancelOrderCache(orderCacheObject);
      //sync to cloud
      if (deletedOrderCache == 1) {
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
    OrderCache orderCacheData = await PosDatabase.instance
        .readSpecificOrderCacheByLocalId(
            orderCacheObject.order_cache_sqlite_id!);
    if (orderCacheData.sync_status != 1) {
      _orderCacheValue.add(jsonEncode(orderCacheData));
    }
    order_cache_value = _orderCacheValue.toString();
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
      List<TableUseDetail> checkData =
          await PosDatabase.instance.readAllTableUseDetail(currentTableUseId);
      for (int i = 0; i < checkData.length; i++) {
        TableUseDetail tableUseDetailObject = TableUseDetail(
            updated_at: dateTime,
            sync_status: checkData[i].sync_status == 0 ? 0 : 2,
            status: 1,
            table_use_sqlite_id: currentTableUseId,
            table_use_detail_sqlite_id:
                checkData[i].table_use_detail_sqlite_id);
        int deleteStatus = await PosDatabase.instance
            .deleteTableUseDetail(tableUseDetailObject);
        if (deleteStatus == 1) {
          TableUseDetail detailData = await PosDatabase.instance
              .readSpecificTableUseDetailByLocalId(
                  tableUseDetailObject.table_use_detail_sqlite_id!);
          _value.add(jsonEncode(detailData));
          table_use_detail_value = _value.toString();
        }
      }
      //sync to cloud
      //syncTableUseDetail(_value.toString());
    } catch (e) {
      print(e);
      Fluttertoast.showToast(
          backgroundColor: Color(0xFFFF0000),
          msg: AppLocalizations.of(context)!
                  .translate('delete_current_table_use_detail_error') +
              " $e");
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
      TableUse checkData = await PosDatabase.instance
          .readSpecificTableUseIdByLocalId(currentTableUseId);
      TableUse tableUseObject = TableUse(
        updated_at: dateTime,
        sync_status: checkData.sync_status == 0 ? 0 : 2,
        status: 1,
        table_use_sqlite_id: currentTableUseId,
      );
      int deletedTableUse =
          await PosDatabase.instance.deleteTableUseID(tableUseObject);
      if (deletedTableUse == 1) {
        //sync to cloud
        TableUse tableUseData = await PosDatabase.instance
            .readSpecificTableUseIdByLocalId(
                tableUseObject.table_use_sqlite_id!);
        _value.add(jsonEncode(tableUseData));
        table_use_value = _value.toString();
        //syncTableUseIdToCloud(_value.toString());
      }
    } catch (e) {
      Fluttertoast.showToast(
          backgroundColor: Color(0xFFFF0000),
          msg: AppLocalizations.of(context)!
                  .translate('delete_current_table_use_id_error') +
              " ${e}");
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
    try {
      if (mainSyncToCloud.count == 0) {
        mainSyncToCloud.count = 1;
        final prefs = await SharedPreferences.getInstance();
        final int? device_id = prefs.getInt('device_id');
        final String? login_value = prefs.getString('login_value');
        print(
            'branch link product value in sync: ${this.branch_link_product_value}');
        Map data = await Domain().syncLocalUpdateToCloud(
            device_id: device_id.toString(),
            value: login_value,
            table_use_value: this.table_use_value,
            table_use_detail_value: this.table_use_detail_value,
            order_cache_value: this.order_cache_value,
            order_detail_value: this.order_detail_value,
            order_detail_cancel_value: this.order_detail_cancel_value,
            branch_link_product_value: this.branch_link_product_value,
            table_value: this.table_value);
        //if success update local sync status
        if (data['status'] == '1') {
          List responseJson = data['data'];
          if (responseJson.isNotEmpty) {
            for (int i = 0; i < responseJson.length; i++) {
              switch (responseJson[i]['table_name']) {
                case 'tb_table_use_detail':
                  {
                    await PosDatabase.instance
                        .updateTableUseDetailSyncStatusFromCloud(
                            responseJson[i]['table_use_detail_key']);
                  }
                  break;
                case 'tb_table_use':
                  {
                    await PosDatabase.instance
                        .updateTableUseSyncStatusFromCloud(
                            responseJson[i]['table_use_key']);
                  }
                  break;
                case 'tb_order_detail_cancel':
                  {
                    await PosDatabase.instance
                        .updateOrderDetailCancelSyncStatusFromCloud(
                            responseJson[i]['order_detail_cancel_key']);
                  }
                  break;
                case 'tb_branch_link_product':
                  {
                    await PosDatabase.instance
                        .updateBranchLinkProductSyncStatusFromCloud(
                            responseJson[i]['branch_link_product_id']);
                  }
                  break;
                case 'tb_order_detail':
                  {
                    await PosDatabase.instance
                        .updateOrderDetailSyncStatusFromCloud(
                            responseJson[i]['order_detail_key']);
                  }
                  break;
                case 'tb_order_cache':
                  {
                    await PosDatabase.instance
                        .updateOrderCacheSyncStatusFromCloud(
                            responseJson[i]['order_cache_key']);
                  }
                  break;
                case 'tb_table':
                  {
                    await PosDatabase.instance
                        .updatePosTableSyncStatusFromCloud(
                            responseJson[i]['table_id']);
                  }
                  break;
                default:
                  {
                    return;
                  }
              }
            }
            mainSyncToCloud.resetCount();
          } else {
            mainSyncToCloud.resetCount();
          }
        } else if (data['status'] == '7') {
          this.isLogOut = true;
          mainSyncToCloud.resetCount();
        } else if (data['status'] == '8') {
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
    } catch (e) {
      print('adjust quantity sync to cloud error: $e');
      mainSyncToCloud.resetCount();
      //return 1;
    }
  }
}
