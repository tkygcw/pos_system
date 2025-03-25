import 'package:f_logs/model/flog/flog.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:pos_system/notifier/cart_notifier.dart';
import 'package:pos_system/object/branch_link_product.dart';
import 'package:pos_system/object/cart_product.dart';
import 'package:pos_system/object/categories.dart';
import 'package:pos_system/object/order.dart';
import 'package:pos_system/object/order_cache.dart';
import 'package:pos_system/object/order_detail.dart';
import 'package:pos_system/object/order_modifier_detail.dart';
import 'package:pos_system/object/order_payment_split.dart';
import 'package:pos_system/object/table.dart';
import 'package:pos_system/object/table_use_detail.dart';
import 'package:pos_system/page/loading_dialog.dart';
import 'package:pos_system/utils/Utils.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../database/pos_database.dart';
import '../../notifier/theme_color.dart';
import '../../translation/AppLocalizations.dart';
import '../custom_toastification.dart';

class OtherOrderAddtoCart extends StatefulWidget {
  final String cartFinalAmount;
  final String diningOptionId;
  const OtherOrderAddtoCart({Key? key, required this.cartFinalAmount, required this.diningOptionId}) : super(key: key);

  @override
  State<OtherOrderAddtoCart> createState() => _OtherOrderAddtoCartState();
}

class _OtherOrderAddtoCartState extends State<OtherOrderAddtoCart> {
  String? selectDiningOption = 'All';
  List<OrderDetail> orderDetailList = [];
  List<OrderCache> orderCacheList = [];
  double dStartTime = 0.0;
  double dEndTime = 0.0;
  double dCurrentTime = 0.0;
  bool isActive = false, _isLoaded = false;
  bool isButtonDisabled = false;
  TimeOfDay currentTime = TimeOfDay.now();
  late DateTime startDTime;
  late DateTime endDTime;
  late TimeOfDay startTime;
  late TimeOfDay endTime;
  bool willPop = true;

  @override
  void initState() {
    super.initState();
    getOrderList();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeColor>(builder: (context, ThemeColor color, child) {
      return AlertDialog(
        title: Text(AppLocalizations.of(context)!.translate('select_order')),
        content: Container(
          width: 350,
          height: 350,
          child: Consumer<CartModel>(builder: (context, CartModel cart, child) {
            return _isLoaded ? Column(
              children: [
                Expanded(
                    child: orderCacheList.isNotEmpty ? ListView.builder(
                        padding: EdgeInsets.zero,
                        shrinkWrap: true,
                        itemCount: orderCacheList.length,
                        itemBuilder: (BuildContext context, int index) {
                          return Card(
                            elevation: 5,
                            color: orderCacheList[index].payment_status == 2 ? Color(0xFFFFB3B3) : Colors.white,
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: orderCacheList[index].payment_status == 2 ? Color(0xFFFFB3B3) : Colors.white,
                                  child: orderCacheList[index].dining_name == 'Take Away' ? Icon(
                                    Icons.fastfood_sharp,
                                    color: color.backgroundColor,
                                  ) : orderCacheList[index].dining_name == 'Delivery'
                                      ? Icon(
                                    Icons.delivery_dining,
                                    color: color.backgroundColor,
                                  ) : Icon(
                                    Icons.local_dining_sharp,
                                    color: color.backgroundColor,
                                  )),
                              title: Text('${Utils.convertTo2Dec(orderCacheList[index].total_amount!)}',
                                  style: TextStyle(fontSize: checkPortraitSmallScreen() ? 16 : 18)),
                              trailing: checkPortraitSmallScreen() ? null
                                : Text(
                                  orderCacheList[index].custom_table_number! != ''
                                      ? '${AppLocalizations.of(context)!.translate('table')} ${orderCacheList[index].custom_table_number!}'
                                      : '#'+orderCacheList[index].batch_id.toString(),
                                  style: TextStyle(fontSize: 15),
                                ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(checkPortraitSmallScreen() ?
                                    orderCacheList[index].order_by!
                                    : AppLocalizations.of(context)!.translate('order_by')+': ' + orderCacheList[index].order_by!,
                                    style: TextStyle(fontSize: MediaQuery.of(context).orientation == Orientation.landscape || MediaQuery.of(context).size.width > 500 ? 14 : 13),
                                  ),
                                  Text(checkPortraitSmallScreen() ?
                                    Utils.formatDate(orderCacheList[index].created_at!)
                                    : AppLocalizations.of(context)!.translate('order_at')+': ' + Utils.formatDate(orderCacheList[index].created_at!),
                                    style: TextStyle(fontSize: MediaQuery.of(context).orientation == Orientation.landscape || MediaQuery.of(context).size.width > 500 ? 14 : 13),
                                  ),

                                  checkPortraitSmallScreen()
                                      ? Text(
                                      orderCacheList[index].custom_table_number != ''
                                          ? '${AppLocalizations.of(context)!.translate('table')} ${orderCacheList[index].custom_table_number!}'
                                          : '#${orderCacheList[index].batch_id.toString()}',
                                    style: TextStyle(fontSize: MediaQuery.of(context).orientation == Orientation.landscape || MediaQuery.of(context).size.width > 500 ? 14 : 13),
                                  ) : Container(),
                                ],
                              ),
                              onTap: () async {
                                openLoadingDialogBox();
                                try {
                                  if(orderCacheList[index].is_selected == false){
                                    await Future.delayed(Duration(milliseconds: 300));
                                    bool selectedStatus = await cart.isOtherOrderCacheSelected(orderCacheList[index]);
                                    if(!selectedStatus) {
                                      if(cart.cartNotifierItem.isEmpty){
                                        // orderCacheList[index].is_selected = true;
                                        // cart.selectedOptionId = orderCacheList[index].dining_id!;
                                        // await getOrderDetail(orderCacheList[index]);
                                        // await addToCart(cart, orderCacheList[index]);
                                        if (orderCacheList[index].order_key != '') {
                                          Fluttertoast.showToast(backgroundColor: Color(0xFFFF0000), msg: AppLocalizations.of(context)!.translate('payment_not_complete'));
                                          return;
                                        } else {
                                          orderCacheList[index].is_selected = true;
                                          cart.selectedOptionId = orderCacheList[index].dining_id!;
                                          cart.selectedOptionOrderKey = orderCacheList[index].order_key!;
                                          if(orderCacheList[index].custom_table_number != '' && orderCacheList[index].custom_table_number != null)
                                            cart.selectedTableIndex = orderCacheList[index].custom_table_number!;
                                          if(orderCacheList[index].other_order_key != ''){
                                            List<OrderCache> data = await PosDatabase.instance.readOrderCacheByOtherOrderKey(orderCacheList[index].other_order_key!);
                                            for(int i = 0; i < data.length; i++){
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
                                              await getOrderDetail(orderCacheList[index]);
                                              await addToCart(cart, orderCacheList[index]);
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
                                    if(orderCacheList[index].order_key != '') {
                                      for(int i = 0; i < orderCacheList.length; i++) {
                                        orderCacheList[i].is_selected = false;
                                        cart.removePromotion();
                                        cart.removeCartItemBasedOnOrderCache(orderCacheList[i].order_cache_sqlite_id.toString());
                                      }
                                    } else {
                                      orderCacheList[index].is_selected = false;
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
                                    Navigator.of(context).pop();
                                  });
                                }
                              },
                            ),
                          );
                        }) : Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.list,
                            color: Colors.grey,
                            size: 30.0,
                          ),
                          Text(AppLocalizations.of(context)!.translate('no_order'), style: TextStyle(fontSize: 20),),
                        ],
                      ),
                    ))
              ],
            ) : Center(
              child: CircularProgressIndicator(),
            );
          }),
        ),
        actions: <Widget>[
          TextButton(
            child: Text('${AppLocalizations.of(context)?.translate('close')}'),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
        ],
      );
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

  checkPortraitSmallScreen() {
    if(MediaQuery.of(context).orientation == Orientation.portrait && MediaQuery.of(context).size.width < 500) {
      return true;
    } else {
      return false;
    }
  }

  getOrderList({model}) async {
    List<OrderCache> data = [];
    if (model != null) {
      model.changeContent2(false);
    }
    final prefs = await SharedPreferences.getInstance();
    final String? user = prefs.getString('user');

    data = await PosDatabase.instance.readOrderCacheByDiningOptionId(widget.diningOptionId);

    if(!mounted) return;
    setState(() {
      orderCacheList = data;
    });
    if(orderCacheList.isNotEmpty) {
      for(int i = 0; i < orderCacheList.length; i++) {
        if(orderCacheList[i].order_key != '') {
          double amountPaid = 0;
          double total_amount = double.parse(orderCacheList[i].total_amount!);
          List<OrderPaymentSplit> orderSplit = await PosDatabase.instance.readSpecificOrderSplitByOrderKey(orderCacheList[i].order_key!);

          for(int k = 0; k < orderSplit.length; k++){
            amountPaid += double.parse(orderSplit[k].amount!);
          }

          List<Order> orderData = await PosDatabase.instance.readSpecificOrderByOrderKey(orderCacheList[i].order_key!);
          total_amount = double.parse(orderData[0].final_amount!);

          total_amount -= amountPaid;
          setState(() {
            orderCacheList[i].total_amount = total_amount.toString();
          });
        } else {
          if(orderCacheList[i].other_order_key !=''){
            List<OrderCache> data = await PosDatabase.instance.readOrderCacheByOtherOrderKey(orderCacheList[i].other_order_key!);
            double total_amount = 0;
            for(int j = 0; j < data.length; j++){
              total_amount += double.parse(data[j].total_amount!);
            }
            setState(() {
              orderCacheList[i].total_amount = total_amount.toString();
            });
          }
        }
      }
      _isLoaded = true;
    } else{
      print('order cache no data');
      _isLoaded = true;
    }

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

  addToCart(CartModel cart, OrderCache orderCache) async {
    List<cartProductItem> cartItemList = [];
    cart.addCartOrderCache(orderCache);
    var value;
    for (int i = 0; i < orderDetailList.length; i++) {
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
        status: 1,
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
      print("order_cache_sqlite_id: ${orderCache.order_cache_sqlite_id.toString()}");
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
}
