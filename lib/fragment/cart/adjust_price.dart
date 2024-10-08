import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';
import 'package:pos_system/main.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../database/domain.dart';
import '../../database/pos_database.dart';
import '../../notifier/cart_notifier.dart';
import '../../notifier/table_notifier.dart';
import '../../notifier/theme_color.dart';
import '../../object/cart_product.dart';
import '../../object/order_cache.dart';
import '../../object/order_detail.dart';
import '../../object/order_modifier_detail.dart';
import '../../object/table_use_detail.dart';
import '../../object/user.dart';
import '../../translation/AppLocalizations.dart';

class AdjustPriceDialog extends StatefulWidget {
  final CartModel cart;
  final cartProductItem cartItem;
  final int index;
  final String currentPage;
  final Function(cartProductItem) callBack;

  const AdjustPriceDialog({Key? key, required this.cartItem, required this.currentPage, required this.callBack, required this.cart, required this.index}) : super(key: key);

  @override
  State<AdjustPriceDialog> createState() => _AdjustPriceDialogState();
}

class _AdjustPriceDialogState extends State<AdjustPriceDialog> {
  num simpleIntInput = 0;
  num modifierTotalPrice = 0;
  final adminPosPinController = TextEditingController();
  List<User> adminData = [];
  List<OrderCache> cartCacheList = [], cartTableCacheList = [];
  List<OrderDetail> cartOrderDetailList = [];
  List<OrderModifierDetail> cartOrderModDetailList = [];
  List<TableUseDetail> cartTableUseDetail = [];
  String? order_cache_value, order_detail_value;
  OrderDetail? orderDetail;
  bool isLogOut = false;
  bool _isLoaded = false;
  bool _submitted = false;
  bool isButtonDisabled = false;
  bool isYesButtonDisabled = false;
  bool willPop = true;

  late TableModel tableModel;
  TextEditingController priceController = TextEditingController();

  @override
  void initState() {
    super.initState();
    readCartItemInfo();
    simpleIntInput = widget.cartItem.unit != 'each' && widget.cartItem.unit != 'each_c' ? 0 : 1;
    priceController = TextEditingController(text: '${widget.cartItem.price}');
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
    } else {
      setState(() {
        isButtonDisabled = false;
      });
    }
  }

  Future showSecondDialog(BuildContext context, ThemeColor color, CartModel cart) {
    return showDialog(
        barrierDismissible: false,
        context: context,
        builder: (BuildContext context) {
          return StatefulBuilder(builder: (context, StateSetter setState) {
            return WillPopScope(
              onWillPop: () async => willPop,
              child: Center(
                child: SingleChildScrollView(
                  child: AlertDialog(
                    title: Text(AppLocalizations.of(context)!.translate('enter_admin_pin')),
                    content: SizedBox(
                      height: 75.0,
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
                                  if(mounted){
                                    setState(() {
                                      isButtonDisabled = false;
                                    });
                                  }
                                },
                                obscureText: true,
                                controller: adminPosPinController,
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                  errorText: _submitted
                                      ? errorPassword == null
                                      ? errorPassword
                                      : AppLocalizations.of(context)?.translate(errorPassword!)
                                      : null,
                                  border: OutlineInputBorder(
                                    borderSide: BorderSide(color: color.backgroundColor),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderSide: BorderSide(color: color.backgroundColor),
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
                            if(mounted){
                              setState(() {
                                isButtonDisabled = false;
                              });
                            }
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
                            if(mounted){
                              setState(() {
                                isButtonDisabled = false;
                              });
                            }
                          },
                        ),
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
        return Consumer<TableModel>(builder: (context, TableModel tableModel, child) {
          this.tableModel = tableModel;
          return Center(
            child: SingleChildScrollView(
              child: AlertDialog(
                title: Text(AppLocalizations.of(context)!.translate('adjust_price')),
                content: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Container(
                        height: 75,
                        width: 350,
                        child: TextField(
                          autofocus: false,
                          controller: priceController,
                          keyboardType: TextInputType.number,
                          inputFormatters: <TextInputFormatter>[FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}'))],
                          textAlign: TextAlign.center,
                          decoration: InputDecoration(
                            errorText: priceController.text.isEmpty ? '${AppLocalizations.of(context)?.translate('adjust_price_error')} 0' : null,
                            focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: color.backgroundColor),
                            ),
                            hintText: widget.cartItem.price,
                          ),
                          onChanged: (value) => setState(() {
                            try{
                              // if(double.parse(priceController.text) < modifierTotalPrice) {
                              //   isYesButtonDisabled = true;
                              // } else {
                              //   isYesButtonDisabled = false;
                              // }
                              double.parse(value.replaceAll(',', ''));
                            }catch (e){
                              priceController.text = "";
                            }
                          } ),
                          onSubmitted: (value) {
                            isButtonDisabled
                                ? null
                                : () async {
                              if(priceController.text.isNotEmpty) {
                                if (double.parse(priceController.text).toStringAsFixed(2) != double.parse(widget.cartItem.price!).toStringAsFixed(2)) {
                                  DateFormat dateFormat = DateFormat("yyyy-MM-dd HH:mm:ss");
                                  String dateTime = dateFormat.format(DateTime.now());
                                  final prefs = await SharedPreferences.getInstance();
                                  final String? pos_user = prefs.getString('pos_pin_user');
                                  Map<String, dynamic> userMap = json.decode(pos_user!);
                                  User userData = User.fromJson(userMap);

                                  if(userData.edit_price_without_pin != 1) {
                                    await showSecondDialog(context, color, cart);
                                  } else {
                                    await callUpdateCart(userData, dateTime, cart);
                                    Navigator.of(context).pop();
                                  }
                                } else {
                                  //no changes
                                  print("Price Adjust: no changes");
                                  Navigator.of(context).pop();
                                }
                              } else {
                                priceController.text = "";
                              }
                            }();
                          },
                        ),
                      ),
                    ),
                  ],
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
                            onPressed: isButtonDisabled
                                ? null
                                : () {
                              setState(() {
                                isButtonDisabled = true;
                              });
                              Navigator.of(context).pop();
                              // if(mounted) {
                              //   setState(() {
                              //     isButtonDisabled = false;
                              //   });
                              // }
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
                            onPressed: isButtonDisabled || isYesButtonDisabled
                                ? null
                                : () async {
                              if(priceController.text.isNotEmpty) {
                                if (double.parse(priceController.text).toStringAsFixed(2) != double.parse(widget.cartItem.price!).toStringAsFixed(2)) {
                                  DateFormat dateFormat = DateFormat("yyyy-MM-dd HH:mm:ss");
                                  String dateTime = dateFormat.format(DateTime.now());
                                  final prefs = await SharedPreferences.getInstance();
                                  final String? pos_user = prefs.getString('pos_pin_user');
                                  Map<String, dynamic> userMap = json.decode(pos_user!);
                                  User userData = User.fromJson(userMap);

                                  if(userData.edit_price_without_pin != 1) {
                                    await showSecondDialog(context, color, cart);
                                  } else {
                                    await callUpdateCart(userData, dateTime, cart);
                                    Navigator.of(context).pop();
                                  }
                                } else {
                                  //no changes
                                  print("Price Adjust: no changes");
                                  setState(() {
                                    isButtonDisabled = true;
                                  });
                                  Navigator.of(context).pop();
                                }
                              } else {
                                priceController.text = "";
                              }
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        });
      });
    });
  }

  readCartItemInfo() async {
    //get cart item order cache
    if (widget.currentPage != 'menu') {
      List<OrderCache> cacheData = await PosDatabase.instance.readSpecificOrderCache(widget.cartItem.order_cache_sqlite_id!);
      cartCacheList = List.from(cacheData);

      if (widget.currentPage != 'other order') {
        //get table use order cache
        List<OrderCache> tableCacheData = await PosDatabase.instance.readTableOrderCache(cacheData[0].table_use_key!);
        cartTableCacheList = List.from(tableCacheData);

        //get table use detail
        List<TableUseDetail> tableDetailData = await PosDatabase.instance.readAllTableUseDetail(cacheData[0].table_use_sqlite_id!);
        cartTableUseDetail = List.from(tableDetailData);
      }

      //get cart item order cache order detail
      List<OrderDetail> orderDetailData = await PosDatabase.instance.readTableOrderDetail(widget.cartItem.order_cache_key!);
      cartOrderDetailList = List.from(orderDetailData);

      OrderDetail cartItemOrderDetail = await PosDatabase.instance.readSpecificOrderDetailByLocalId(int.parse(widget.cartItem.order_detail_sqlite_id!));
      orderDetail = cartItemOrderDetail;

      //get modifier detail length
      List<OrderModifierDetail> orderModData = await PosDatabase.instance.readOrderModifierDetail(widget.cartItem.order_detail_sqlite_id!);
      cartOrderModDetailList = List.from(orderModData);
      getModifierTotalPrice();

      _isLoaded = true;
    }

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
      print("adjustPrice userData: ${userData}");
      if (userData != null) {
        if(userData.edit_price_without_pin == 1) {
          await callUpdateCart(userData, dateTime, cart);
          if (this.isLogOut == false) {
            Navigator.of(context).pop();
            Navigator.of(context).pop();
          }
        } else {
          Fluttertoast.showToast(backgroundColor: Color(0xFFFF0000), msg: "${AppLocalizations.of(context)?.translate('no_permission')}");
        }

      } else {
        Fluttertoast.showToast(backgroundColor: Color(0xFFFF0000), msg: "${AppLocalizations.of(context)?.translate('user_not_found')}");
      }
    } catch (e) {
      print('delete error ${e}');
    }
  }

  callUpdateCart(User userData, String dateTime, CartModel cart) async {
    if (widget.currentPage == 'menu') {
      // before adding to order cache
      widget.cartItem.price = double.parse(priceController.text).toStringAsFixed(2);
      widget.callBack(widget.cartItem);
      Fluttertoast.showToast(backgroundColor: Color(0xFF24EF10), msg: AppLocalizations.of(context)!.translate('price_updated'));
    } else {
      // for other order, table order
      await updateOrderDetailUnitPrice(userData, dateTime, cart);
      print('order detail unit price updated');

      Fluttertoast.showToast(backgroundColor: Color(0xFF24EF10), msg: AppLocalizations.of(context)!.translate('price_updated'));
      tableModel.changeContent(true);
      // cart.removeAllTable();
      // cart.removeAllCartItem();
      // cart.removePromotion();
      widget.cartItem.price = double.parse(priceController.text).toStringAsFixed(2);
      widget.callBack(widget.cartItem);
      //sync to cloud
      syncAllToCloud();
    }
  }

  updateOrderDetailUnitPrice(User user, String dateTime, CartModel cart) async {
    List<String> _value = [];
    num newPrice = 0;
    try {
      newPrice = double.parse(priceController.text);
      OrderDetail orderDetailObject = OrderDetail(
        updated_at: dateTime,
        sync_status: orderDetail!.sync_status == 0 ? 0 : 2,
        status: 0,
        edited_by: user.name,
        edited_by_user_id: user.user_id.toString(),
        price: newPrice.toStringAsFixed(2),
        order_detail_sqlite_id: int.parse(widget.cartItem.order_detail_sqlite_id!),
        branch_link_product_sqlite_id: widget.cartItem.branch_link_product_sqlite_id,
      );
      num data = await PosDatabase.instance.updateOrderDetailUnitPrice(orderDetailObject);
      if (data == 1) {
        OrderDetail detailData = await PosDatabase.instance.readSpecificOrderDetailByLocalId(orderDetailObject.order_detail_sqlite_id!);
        await updateOrderCacheSubtotal(detailData.order_cache_sqlite_id!, orderDetail!.quantity, orderDetail!.price, detailData.price, dateTime);
        _value.add(jsonEncode(detailData.syncJson()));
      }
      order_detail_value = _value.toString();
    } catch (e) {
      print("update price in order detail error: $e");
    }
  }

  updateOrderCacheSubtotal(String orderCacheLocalId, quantity, oldPrice, newPrice, String dateTime) async {
    num subtotal = 0.0;
    OrderCache data = await PosDatabase.instance.readSpecificOrderCacheByLocalId(int.parse(orderCacheLocalId));
    subtotal = (double.parse(data.total_amount!) - double.parse(oldPrice)*double.parse(quantity)) + (double.parse(quantity) * double.parse(newPrice));
    OrderCache orderCache =
    OrderCache(order_cache_sqlite_id: data.order_cache_sqlite_id, total_amount: subtotal.toStringAsFixed(2), sync_status: data.sync_status == 0 ? 0 : 2, updated_at: dateTime);
    int status = await PosDatabase.instance.updateOrderCacheSubtotal(orderCache);
    if (status == 1) {
      getOrderCacheValue(orderCache);
    }
  }

  getOrderCacheValue(OrderCache orderCacheObject) async {
    List<String> _orderCacheValue = [];
    OrderCache orderCacheData = await PosDatabase.instance.readSpecificOrderCacheByLocalId(orderCacheObject.order_cache_sqlite_id!);
    if (orderCacheData.sync_status != 1) {
      _orderCacheValue.add(jsonEncode(orderCacheData));
    }
    order_cache_value = _orderCacheValue.toString();
  }

  syncAllToCloud() async {
    try {
      if (mainSyncToCloud.count == 0) {
        mainSyncToCloud.count = 1;
        final prefs = await SharedPreferences.getInstance();
        final int? device_id = prefs.getInt('device_id');
        final String? login_value = prefs.getString('login_value');

        Map data = await Domain()
            .syncLocalUpdateToCloud(device_id: device_id.toString(), value: login_value, order_cache_value: this.order_cache_value, order_detail_value: this.order_detail_value);
        //if success update local sync status
        if (data['status'] == '1') {
          List responseJson = data['data'];
          if (responseJson.isNotEmpty) {
            for (int i = 0; i < responseJson.length; i++) {
              switch (responseJson[i]['table_name']) {
                case 'tb_order_detail':
                  {
                    await PosDatabase.instance.updateOrderDetailSyncStatusFromCloud(responseJson[i]['order_detail_key']);
                  }
                  break;
                case 'tb_order_cache':
                  {
                    await PosDatabase.instance.updateOrderCacheSyncStatusFromCloud(responseJson[i]['order_cache_key']);
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
      }
    } catch (e) {
      print('adjust price sync to cloud error: $e');
      mainSyncToCloud.resetCount();
      //return 1;
    }
  }

  getModifierTotalPrice() async {
    for (int i = 0; i < cartOrderModDetailList.length; i++) {
      modifierTotalPrice += double.parse(cartOrderModDetailList[i].mod_price!);
    }
  }
}
