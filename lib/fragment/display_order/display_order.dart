import 'dart:convert';
import 'package:f_logs/model/flog/flog.dart';
import 'package:collapsible_sidebar/collapsible_sidebar.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:pos_system/database/pos_database.dart';
import 'package:pos_system/notifier/cart_notifier.dart';
import 'package:pos_system/notifier/notification_notifier.dart';
import 'package:pos_system/notifier/table_notifier.dart';
import 'package:pos_system/object/app_setting.dart';
import 'package:pos_system/object/dining_option.dart';
import 'package:pos_system/object/order.dart';
import 'package:pos_system/object/order_cache.dart';
import 'package:pos_system/object/table.dart';
import 'package:pos_system/object/table_use_detail.dart';
import 'package:pos_system/object/order_payment_split.dart';
import 'package:pos_system/page/loading_dialog.dart';
import 'package:pos_system/page/progress_bar.dart';
import 'package:pos_system/translation/AppLocalizations.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../notifier/theme_color.dart';
import '../../object/branch_link_product.dart';
import '../../object/cart_product.dart';
import '../../object/categories.dart';
import '../../object/modifier_group.dart';
import '../../object/modifier_item.dart';
import '../../object/order_detail.dart';
import '../../object/order_modifier_detail.dart';
import '../../object/product_variant.dart';
import '../../object/variant_group.dart';
import '../../utils/Utils.dart';
import '../custom_toastification.dart';

class DisplayOrderPage extends StatefulWidget {
  final CartModel cartModel;
  const DisplayOrderPage({Key? key, required this.cartModel}) : super(key: key);

  @override
  _DisplayOrderPageState createState() => _DisplayOrderPageState();
}

class _DisplayOrderPageState extends State<DisplayOrderPage> {
  List<String> list = [];
  String? selectDiningOption = 'All';
  List<OrderCache> orderCacheList = [];
  List<OrderDetail> orderDetailList = [];
  List<OrderModifierDetail> orderModifierDetail = [];
  List<ProductVariant> orderProductVariant = [];
  List<VariantGroup> variantGroup = [];
  List<ModifierGroup> modifierGroup = [];
  bool _isLoad = false;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    getDiningList();
    getOrderList();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.cartModel.notDineInInitLoad();
    });
  }


  getDiningList() async{
    list.add('All');
    List<DiningOption> data = await PosDatabase.instance.readAllDiningOption();
    for(int i=0; i< data.length; i++){
      // if(data[i].name != 'Dine in'){
      //   list.add(data[i].name!);
      // }
      list.add(data[i].name!);
    }

  }

  getOrderList({model}) async {
    _isLoad = false;
    List<OrderCache> data = [];
    if (model != null) {
      model.changeContent2(false);
    }
    final prefs = await SharedPreferences.getInstance();
    final String? user = prefs.getString('user');
    Map userObject = json.decode(user!);
    final int? branch_id = prefs.getInt('branch_id');
    AppSetting? localSetting = await PosDatabase.instance.readLocalAppSetting(branch_id.toString());

    if(localSetting!.table_order == 2) {
      if (selectDiningOption == 'All') {
        data = await PosDatabase.instance.readOrderCacheNoDineInAdvanced(branch_id.toString(), userObject['company_id']);
      } else {
        data = await PosDatabase.instance.readOrderCacheSpecialAdvanced(selectDiningOption!);
      }
    } else {
      if (selectDiningOption == 'All') {
        data = await PosDatabase.instance.readOrderCacheNoDineIn(branch_id.toString(), userObject['company_id']);
      } else {
        data = await PosDatabase.instance.readOrderCacheSpecial(selectDiningOption!);
      }
    }
    orderCacheList = data;
    for(int i = 0; i < orderCacheList.length; i++) {
      if(orderCacheList[i].order_key != null && orderCacheList[i].order_key != '') {
        double amountPaid = 0;
        double total_amount = double.parse(orderCacheList[i].total_amount!);
        List<OrderPaymentSplit> orderSplit = await PosDatabase.instance.readSpecificOrderSplitByOrderKey(orderCacheList[i].order_key!);

        for(int k = 0; k < orderSplit.length; k++){
          amountPaid += double.parse(orderSplit[k].amount!);
        }

        List<Order> orderData = await PosDatabase.instance.readSpecificOrderByOrderKey(orderCacheList[i].order_key!);
        total_amount = double.parse(orderData[0].final_amount!);

        total_amount -= amountPaid;
        orderCacheList[i].total_amount = total_amount.toString();
      } else {
        if(orderCacheList[i].other_order_key !=''){
          List<OrderCache> data = await PosDatabase.instance.readOrderCacheByOtherOrderKey(orderCacheList[i].other_order_key!);
          double total_amount = 0;
          for(int j = 0; j < data.length; j++){
            total_amount += double.parse(data[j].total_amount!);
          }
          orderCacheList[i].total_amount = total_amount.toString();
        }
      }
    }
    orderCacheList = removeDuplicateOrderCache(orderCacheList);
    if(!mounted) return;
    setState(() {
      _isLoad = true;
    });

  }

  List<OrderCache> removeDuplicateOrderCache(List<OrderCache> orderCacheList) {
    final seenKeys = <String>{}; // Set to store unique other_order_key values

    return orderCacheList.where((orderCache) {
      final key = orderCache.other_order_key;
      if (key == null || key == '') return true; // Keep entries with empty keys

      return seenKeys.add(key); // Adds to set & returns true if it's a new key
    }).toList();
  }

  // Future<Future<Object?>> openViewOrderDialog(OrderCache data) async {
  //   return showGeneralDialog(
  //       barrierColor: Colors.black.withOpacity(0.5),
  //       transitionBuilder: (context, a1, a2, widget) {
  //         final curvedValue = Curves.easeInOutBack.transform(a1.value) - 1.0;
  //         return Transform(
  //           transform: Matrix4.translationValues(0.0, curvedValue * 200, 0.0),
  //           child: Opacity(
  //             opacity: a1.value,
  //             child: ViewOrderDialogPage(orderCache: data),
  //           ),
  //         );
  //       },
  //       transitionDuration: Duration(milliseconds: 200),
  //       barrierDismissible: false,
  //       context: context,
  //       pageBuilder: (context, animation1, animation2) {
  //         return null!;
  //       });
  // }


  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeColor>(builder: (context, ThemeColor color, child) {
      return Consumer<NotificationModel>(builder: (context, notificationModel, child) {
        return Consumer<CartModel>(builder: (context, CartModel cart, child) {
          if(notificationModel.contentLoaded == true){
            notificationModel.resetContentLoaded();
            notificationModel.resetContentLoad();
            getOrderList();
          }
          return Consumer<TableModel>(builder: (context, TableModel tableModel, child) {
            if (tableModel.isChange && cart.cartNotifierItem.isEmpty) {
              getOrderList(model: tableModel);
            }
            return Scaffold(
              appBar: MediaQuery.of(context).orientation == Orientation.landscape && MediaQuery.of(context).size.width > 900 && MediaQuery.of(context).size.height > 500 ? AppBar(
                automaticallyImplyLeading: false,
                elevation: 0,
                title: Text(AppLocalizations.of(context)!.translate('other_order'), style: TextStyle(fontSize: 25)),
                centerTitle: false,
                actions: [
                  Container(
                    width: MediaQuery.of(context).size.height / 3,
                    padding: EdgeInsets.fromLTRB(0, 0, 0, 0),
                    child: DropdownButton<String>(
                      onChanged: (String? value) {
                        setState(() {
                          selectDiningOption = value!;
                        });
                        cart.removeAllCartItem();
                        cart.removeAllTable();
                        getOrderList();
                      },
                      menuMaxHeight: 300,
                      value: selectDiningOption,
                      // Hide the default underline
                      underline: Container(),
                      icon: Icon(
                        Icons.arrow_drop_down,
                        color: color.backgroundColor,
                      ),
                      isExpanded: true,
                      // The list of options
                      items: list
                          .map((e) => DropdownMenuItem(
                        value: e,
                        child: Container(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            AppLocalizations.of(context)!.translate(getDiningOption(e)),
                            style: TextStyle(fontSize: 18),
                          ),
                        ),
                      ))
                          .toList(),
                      // Customize the selected item
                      selectedItemBuilder: (BuildContext context) => list
                          .map((e) => Center(
                        child: Text(AppLocalizations.of(context)!.translate(getDiningOption(e))),
                      ))
                          .toList(),
                    ),
                  ),
                ],
              ) :
              AppBar(
                automaticallyImplyLeading: false,
                elevation: 0,
                leading: MediaQuery.of(context).orientation == Orientation.landscape ? null : Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: GestureDetector(
                    onTap: () {
                      isCollapsedNotifier.value = !isCollapsedNotifier.value;
                    },
                    child: Image.asset('drawable/logo.png'),
                  ),
                ),
                title: Text(AppLocalizations.of(context)!.translate('other_order'),
                  style: TextStyle(fontSize: 20, color: color.backgroundColor),
                ),
                centerTitle: false,
                actions: [
                  Container(
                    width: MediaQuery.of(context).size.height / 7,
                    padding: EdgeInsets.fromLTRB(0, 0, 0, 0),
                    child: DropdownButton<String>(
                      onChanged: (String? value) {
                        setState(() {
                          selectDiningOption = value!;
                        });
                        cart.removeAllCartItem();
                        cart.removeAllTable();
                        getOrderList();
                      },
                      menuMaxHeight: 250,
                      value: selectDiningOption,
                      // Hide the default underline
                      underline: Container(),
                      icon: Icon(
                        Icons.arrow_drop_down,
                        color: color.backgroundColor,
                      ),
                      isExpanded: true,
                      // The list of options
                      items: list
                          .map((e) => DropdownMenuItem(
                        value: e,
                        child: Container(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            AppLocalizations.of(context)!.translate(getDiningOption(e)),
                            style: TextStyle(fontSize: 18),
                          ),
                        ),
                      ))
                          .toList(),
                      // Customize the selected item
                      selectedItemBuilder: (BuildContext context) => list
                          .map((e) => Center(
                        child: Text(AppLocalizations.of(context)!.translate(getDiningOption(e))),
                      ))
                          .toList(),
                    ),
                  )
                ],
              ),
              resizeToAvoidBottomInset: false,
              body: _isLoad ? Container(
                padding: EdgeInsets.all(10),
                child: orderCacheList.isNotEmpty ?
                ListView.builder(
                    shrinkWrap: true,
                    itemCount: orderCacheList.length,
                    itemBuilder: (BuildContext context, int index) {
                      return Card(
                        elevation: 5,
                        color: orderCacheList[index].payment_status == 2 ? Color(0xFFFFB3B3) : Colors.white,
                        shape: orderCacheList[index].is_selected
                            ? new RoundedRectangleBorder(
                            side: new BorderSide(
                                color: orderCacheList[index].payment_status == 2 ? Colors.red : color.backgroundColor, width: 3.0),
                            borderRadius: BorderRadius.circular(4.0))
                            : new RoundedRectangleBorder(
                            side: new BorderSide(color: orderCacheList[index].payment_status == 2 ? Color(0xFFFFB3B3) : Colors.white, width: 3.0),
                            borderRadius: BorderRadius.circular(4.0)),
                        child: InkWell(
                          onTap: () async {
                            openLoadingDialogBox();
                            Future.delayed(Duration(milliseconds: 500), () async {
                              try {
                                if(orderCacheList[index].is_selected == false){
                                  bool selectedStatus = await cart.isOtherOrderCacheSelected(orderCacheList[index]);
                                  if(selectedStatus == false){
                                    if(cart.cartNotifierItem.isEmpty){
                                      // orderCacheList[index].is_selected = true;
                                      // cart.selectedOptionId = orderCacheList[index].dining_id!;
                                      // await getOrderDetail(orderCacheList[index]);
                                      // await addToCart(cart, orderCacheList[index]);
                                      if (orderCacheList[index].order_key != '') {
                                        for(int i = 0; i < orderCacheList.length; i ++) {
                                          if(orderCacheList[i].order_key == orderCacheList[index].order_key && orderCacheList[index].order_key != '') {
                                            orderCacheList[i].is_selected = true;
                                            cart.selectedOptionId = orderCacheList[i].dining_id!;
                                            cart.selectedOptionOrderKey = orderCacheList[i].order_key!;
                                            if(orderCacheList[i].other_order_key != ''){
                                              List<OrderCache> data = await PosDatabase.instance.readOrderCacheByOtherOrderKey(orderCacheList[i].other_order_key!);
                                              for(int i = 0; i < data.length; i++) {
                                                await getOrderDetail(data[i]);
                                                await addToCart(cart, data[i]);
                                              }
                                            } else {
                                              await getOrderDetail(orderCacheList[i]);
                                              await addToCart(cart, orderCacheList[i]);
                                            }
                                          }
                                        }

                                      } else {
                                        orderCacheList[index].is_selected = true;
                                        cart.selectedOptionId = orderCacheList[index].dining_id!;
                                        cart.selectedOptionOrderKey = orderCacheList[index].order_key!;
                                        if(orderCacheList[index].other_order_key != ''){
                                          List<OrderCache> data = await PosDatabase.instance.readOrderCacheByOtherOrderKey(orderCacheList[index].other_order_key!);
                                          for(int i = 0; i < data.length; i++) {
                                            await getOrderDetail(data[i]);
                                            await addToCart(cart, data[i]);
                                          }
                                        } else {
                                          await getOrderDetail(orderCacheList[index]);
                                          await addToCart(cart, orderCacheList[index]);
                                        }

                                      }
                                    } else {
                                      if(orderCacheList[index].dining_id == cart.selectedOptionId){
                                        if(cart.selectedOptionOrderKey == orderCacheList[index].order_key) {
                                          if (orderCacheList[index].order_key != '') {
                                            for(int i = 0; i < orderCacheList.length; i++) {
                                              if(orderCacheList[i].order_key == orderCacheList[index].order_key && orderCacheList[index].order_key != '') {
                                                orderCacheList[i].is_selected = true;
                                                cart.selectedOptionId = orderCacheList[i].dining_id!;
                                                cart.selectedOptionOrderKey = orderCacheList[i].order_key!;
                                                await getOrderDetail(orderCacheList[i]);
                                                await addToCart(cart, orderCacheList[i]);
                                              } else {
                                                orderCacheList[index].is_selected = true;
                                                cart.selectedOptionId = orderCacheList[index].dining_id!;
                                                cart.selectedOptionOrderKey = orderCacheList[index].order_key!;
                                                await getOrderDetail(orderCacheList[index]);
                                                await addToCart(cart, orderCacheList[index]);
                                              }
                                            }
                                          } else {
                                            orderCacheList[index].is_selected = true;
                                            cart.selectedOptionId = orderCacheList[index].dining_id!;
                                            cart.selectedOptionOrderKey = orderCacheList[index].order_key!;

                                            if(orderCacheList[index].other_order_key != ''){
                                              List<OrderCache> data = await PosDatabase.instance.readOrderCacheByOtherOrderKey(orderCacheList[index].other_order_key!);
                                              for(int i = 0; i < data.length; i++) {
                                                await getOrderDetail(data[i]);
                                                await addToCart(cart, data[i]);
                                              }
                                            } else {
                                              await getOrderDetail(orderCacheList[index]);
                                              await addToCart(cart, orderCacheList[index]);
                                            }
                                          }
                                        } else {
                                          Fluttertoast.showToast(
                                              backgroundColor: Colors.red,
                                              msg: "${AppLocalizations.of(context)?.translate('payment_status_not_match')}");
                                        }


                                        // orderCacheList[index].is_selected = true;
                                        // await getOrderDetail(orderCacheList[index]);
                                        // await addToCart(cart, orderCacheList[index]);
                                      } else {
                                        Fluttertoast.showToast(
                                            backgroundColor: Colors.red,
                                            msg: "${AppLocalizations.of(context)?.translate('dining_option_not_match')}");
                                      }
                                    }
                                    //reset other selected order
                                    // for(int i = 0; i < orderCacheList.length; i++){
                                    //   orderCacheList[i].is_selected = false;
                                    //   cart.notDineInInitLoad();
                                    // }
                                  } else {
                                    CustomFailedToast.showToast(title: 'Order is in payment');
                                  }
                                } else if(orderCacheList[index].is_selected == true) {
                                  if(orderCacheList[index].other_order_key != ''){
                                    List<OrderCache> data = await PosDatabase.instance.readOrderCacheByOtherOrderKey(orderCacheList[index].other_order_key!);
                                    for(int i = 0; i < data.length; i++) {
                                      data[i].is_selected = false;
                                      cart.removePromotion();
                                      cart.removeCartItemBasedOnOrderCache(data[i].order_cache_sqlite_id.toString());
                                    }
                                  }
                                  if(orderCacheList[index].order_key != '') {
                                    for(int i = 0; i < orderCacheList.length; i++) {
                                      orderCacheList[i].is_selected = false;
                                      cart.removeSpecificOrderCache(orderCacheList[i]);
                                      cart.removePromotion();
                                      cart.removeCartItemBasedOnOrderCache(orderCacheList[i].order_cache_sqlite_id.toString());
                                    }
                                  } else {
                                    orderCacheList[index].is_selected = false;
                                    cart.removeSpecificOrderCache(orderCacheList[index]);
                                    cart.removePromotion();
                                    cart.removeCartItemBasedOnOrderCache(orderCacheList[index].order_cache_sqlite_id.toString());
                                  }
                                  List<TableUseDetail> tableUseDetailList = await PosDatabase.instance.readTableUseDetailByTableUseKey(orderCacheList[index].table_use_key!);
                                  for(int i = 0; i < tableUseDetailList.length; i++) {
                                    List<PosTable> tableData = await PosDatabase.instance.readSpecificTable(tableUseDetailList[i].table_sqlite_id!);
                                    cart.removeSpecificTable(tableData[0]);
                                  }
                                }
                              } catch(e) {
                                Navigator.of(context).pop();
                                for(int i = 0; i < orderCacheList.length; i++) {
                                  orderCacheList[i].is_selected = false;
                                  cart.removePromotion();
                                  cart.removeCartItemBasedOnOrderCache(orderCacheList[i].order_cache_sqlite_id.toString());
                                }
                                FLog.error(
                                  className: "display_order",
                                  text: "other order on tap error",
                                  exception: e,
                                );
                              } finally {
                                setState(() {
                                  Navigator.of(context).pop();
                                });
                              }
                            });
                            //openViewOrderDialog(orderCacheList[index]);
                          },
                          child: Padding(
                            padding: MediaQuery.of(context).orientation == Orientation.landscape || MediaQuery.of(context).size.width > 500 ? const EdgeInsets.all(16.0) : EdgeInsets.fromLTRB(0, 16, 0, 16),
                            child: ListTile(
                                leading:
                                orderCacheList[index].dining_name == 'Take Away'
                                    ? Icon(
                                  Icons.fastfood_sharp,
                                  color: color.backgroundColor,
                                  size: 30.0,
                                )
                                    : orderCacheList[index].dining_name == 'Delivery'
                                    ? Icon(
                                  Icons.delivery_dining,
                                  color: color.backgroundColor,
                                  size: 30.0,
                                )
                                    : Icon(
                                  Icons.local_dining_sharp,
                                  color: color.backgroundColor,
                                  size: 30.0,
                                ),
                                trailing: Text(
                                  orderCacheList[index].custom_table_number! != ''
                                  ? '${AppLocalizations.of(context)!.translate('table')} ${orderCacheList[index].custom_table_number!}'
                                  : '#${orderCacheList[index].batch_id.toString()}',
                                  style: TextStyle(fontSize: MediaQuery.of(context).orientation == Orientation.landscape || MediaQuery.of(context).size.width > 500 ? 20 : 15),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(AppLocalizations.of(context)!.translate('order_by')+': ' + orderCacheList[index].order_by!,
                                      style: TextStyle(fontSize: MediaQuery.of(context).orientation == Orientation.landscape || MediaQuery.of(context).size.width > 500 ? 14 : 13),
                                    ),
                                    Text(AppLocalizations.of(context)!.translate('order_at')+': ' + Utils.formatDate(orderCacheList[index].created_at!),
                                      style: TextStyle(fontSize: MediaQuery.of(context).orientation == Orientation.landscape || MediaQuery.of(context).size.width > 500 ? 14 : 13),
                                    ),
                                  ],
                                ),
                                title: Text(
                                  "${Utils.convertTo2Dec(orderCacheList[index].total_amount!,)}",
                                  style: TextStyle(fontSize: MediaQuery.of(context).orientation == Orientation.landscape || MediaQuery.of(context).size.width > 500 ? 20 : 18),
                                )),
                          ),
                        ),
                      );
                    })
                    :
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.list,
                        color: Colors.grey,
                        size: 36.0,
                      ),
                      Text(AppLocalizations.of(context)!.translate('no_order'), style: TextStyle(fontSize: 24),),
                    ],
                  ),
                ),
              ) : CustomProgressBar(),
            );
          }
          );
        }
        );
      });
    });
  }

  Future<Future<Object?>> openLoadingDialogBox() async {
    return showGeneralDialog(
        barrierColor: Colors.black.withOpacity(0.5),
        transitionBuilder: (context, a1, a2, widget) {
          final curvedValue = Curves.easeInOutBack.transform(a1.value) - 1.0;
          return Transform(
            transform: Matrix4.translationValues(0.0, curvedValue * 200, 0.0),
            child: Opacity(
                opacity: a1.value,
                child: WillPopScope(child: LoadingDialog(isTableMenu: true), onWillPop: () async => false)),
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

  getDiningOption(diningOption){
    if(diningOption == 'All') return 'all';
    else if(diningOption == 'Take Away') return 'take_away';
    else if(diningOption == 'Dine in') return 'dine_in';
    else return 'delivery';
  }

  addToCart(CartModel cart, OrderCache orderCache) async {
    List<cartProductItem> cartItemList = [];
    cart.addCartOrderCache(orderCache);
    var value;
    for (int i = 0; i < orderDetailList.length; i++) {
      // if(orderCache.custom_table_number != '') {
      //   cart.selectedTableIndex = orderCache.custom_table_number!;
      // }
      value = cartProductItem(
          branch_link_product_sqlite_id: orderDetailList[i].branch_link_product_sqlite_id!,
          product_name: orderDetailList[i].productName!,
          category_id: orderDetailList[i].product_category_id!,
          price: orderDetailList[i].price!,
          quantity: int.tryParse(orderDetailList[i].quantity!) != null ? int.parse(orderDetailList[i].quantity!) : double.parse(orderDetailList[i].quantity!),
          checkedModifierItem: [],
          orderModifierDetail: orderDetailList[i].orderModifierDetail,
          productVariantName: orderDetailList[i].product_variant_name,
          remark: orderDetailList[i].remark!,
          unit: orderDetailList[i].unit,
          per_quantity_unit: orderDetailList[i].per_quantity_unit,
          order_queue: orderCache.order_queue,
          custom_table_number: orderCache.custom_table_number,
          status: 0,
          order_cache_sqlite_id: orderCache.order_cache_sqlite_id.toString(),
          order_cache_key: orderCache.order_cache_key,
          category_sqlite_id: orderDetailList[i].category_sqlite_id,
          order_detail_sqlite_id: orderDetailList[i].order_detail_sqlite_id.toString(),
          refColor: Colors.black,
          first_cache_batch: orderCache.batch_id,
          first_cache_order_by: orderCache.order_by,
          first_cache_created_date_time: orderCache.created_at,
          first_cache_other_order_key: orderCache.other_order_key,
          allow_ticket: orderDetailList[i].allow_ticket,
          ticket_count: orderDetailList[i].ticket_count,
          ticket_exp: orderDetailList[i].ticket_exp,
          product_sku: orderDetailList[i].product_sku,
          order_key: orderCache.order_key,
      );
      cartItemList.add(value);
      if(orderCache.dining_name == 'Take Away'){
        cart.selectedOption = 'Take Away';
      } else if(orderCache.dining_name == 'Dine in'){
        cart.selectedOption = 'Dine in';
      } else {
        cart.selectedOption = 'Delivery';
      }
    }
    cart.addAllItem(cartItemList: cartItemList);

    List<TableUseDetail> tableUseDetailList = await PosDatabase.instance.readTableUseDetailByTableUseKey(orderCache.table_use_key!);
    print("tableUseDetailList.length: ${tableUseDetailList.length}");
    for(int i = 0; i < tableUseDetailList.length; i++) {
      List<PosTable> tableData = await PosDatabase.instance.readSpecificTable(tableUseDetailList[i].table_sqlite_id!);
      if (cart.selectedTable.isNotEmpty) {
        if (!cart.selectedTable.contains(tableData)) {
          cart.addTable(tableData[0]);
        }
      } else {
        cart.addTable(tableData[0]);
      }
    }
  }

  getVariantGroupItem(OrderDetail orderDetail) {
    variantGroup = [];
    //loop all order detail variant
    for (int i = 0; i < orderDetail.variantItem.length; i++) {
      variantGroup.add(VariantGroup(
          child: orderDetail.variantItem,
          variant_group_id:
          int.parse(orderDetail.variantItem[i].variant_group_id!)));
    }
    //print('variant group length: ${variantGroup.length}');
    return variantGroup;
  }

  getModifierGroupItem(OrderDetail orderDetail) {
    modifierGroup = [];
    List<ModifierItem> temp = List.from(orderDetail.modifierItem);

    for (int j = 0; j < orderDetail.mod_group_id.length; j++) {
      List<ModifierItem> modItemChild = [];
      //check modifier group is existed or not
      bool isModifierExisted = false;
      int position = 0;
      for (int g = 0; g < modifierGroup.length; g++) {
        if (modifierGroup[g].mod_group_id == orderDetail.mod_group_id[j]) {
          isModifierExisted = true;
          position = g;
          break;
        }
      }
      //if new category
      if (!isModifierExisted) {
        modifierGroup.add(ModifierGroup(
            modifierChild: [],
            mod_group_id: int.parse(orderDetail.mod_group_id[j])));
        position = modifierGroup.length - 1;
      }

      for (int k = 0; k < temp.length; k++) {
        if (modifierGroup[position].mod_group_id.toString() ==
            temp[k].mod_group_id) {
          modItemChild.add(ModifierItem(
              mod_group_id: orderDetail.mod_group_id[position],
              mod_item_id: temp[k].mod_item_id,
              name: temp[k].name,
              isChecked: true));
          temp.removeAt(k);
        }
      }
      modifierGroup[position].modifierChild = modItemChild;
    }
    return modifierGroup;
  }

  getOrderDetail(OrderCache orderCache) async {
    List<OrderDetail> detailData = await PosDatabase.instance.readSpecificOrderDetailByOrderCacheId(orderCache.order_cache_sqlite_id.toString());
    if(detailData.length > 0){
      orderDetailList = List.from(detailData);
    }
    for (int k = 0; k < orderDetailList.length; k++) {
      //Get data from branch link product
      List<BranchLinkProduct> data = await PosDatabase.instance.readSpecificBranchLinkProduct(orderDetailList[k].branch_link_product_sqlite_id!);
      if(data.isNotEmpty) {
        orderDetailList[k].allow_ticket = data[0].allow_ticket;
        orderDetailList[k].ticket_count = data[0].ticket_count;
        orderDetailList[k].ticket_exp = data[0].ticket_exp;
      }

      //Get product category
      if(orderDetailList[k].category_sqlite_id! == '0'){
        orderDetailList[k].product_category_id = '0';
      } else {
        Categories category = await PosDatabase.instance.readSpecificCategoryByLocalId(orderDetailList[k].category_sqlite_id!);
        orderDetailList[k].product_category_id = category.category_id.toString();
      }
      //check order modifier
      await getOrderModifierDetail(orderDetailList[k]);
    }
  }

  getOrderModifierDetail(OrderDetail orderDetail) async {
    try{
      List<OrderModifierDetail> modDetail = await PosDatabase.instance.readOrderModifierDetail(orderDetail.order_detail_sqlite_id.toString());
      if (modDetail.isNotEmpty) {
        orderDetail.orderModifierDetail = modDetail;
      } else {
        orderDetail.orderModifierDetail = [];
      }
    }catch(e){
      print("getOrderModifierDetail error: $e");
      orderDetail.orderModifierDetail = [];
    }
  }
}
