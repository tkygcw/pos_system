import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:pos_system/database/pos_database.dart';
import 'package:pos_system/notifier/cart_notifier.dart';
import 'package:pos_system/notifier/notification_notifier.dart';
import 'package:pos_system/notifier/table_notifier.dart';
import 'package:pos_system/object/dining_option.dart';
import 'package:pos_system/object/order_cache.dart';
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
    List<OrderCache> data = [];
    if (model != null) {
      model.changeContent2(false);
    }
    final prefs = await SharedPreferences.getInstance();
    final String? user = prefs.getString('user');
    Map userObject = json.decode(user!);
    final int? branch_id = prefs.getInt('branch_id');
    if (selectDiningOption == 'All') {
      data = await PosDatabase.instance.readOrderCacheNoDineIn(branch_id.toString(), userObject['company_id']);
    } else {
      data = await PosDatabase.instance.readOrderCacheSpecial(selectDiningOption!);
    }
    if(!mounted) return;
    setState(() {
      orderCacheList = data;
    });
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
            if (tableModel.isChange) {
              getOrderList(model: tableModel);
            }
            return Scaffold(
              appBar: AppBar(
                automaticallyImplyLeading: false,
                elevation: 0,
                title: Text(AppLocalizations.of(context)!.translate('other_order'), style: TextStyle(fontSize: 25)),
                actions: [
                  Container(
                    width: MediaQuery.of(context).size.height / 3,
                    padding: EdgeInsets.fromLTRB(0, 0, 0, 0),
                    child: DropdownButton<String>(
                      onChanged: (String? value) {
                        setState(() {
                          selectDiningOption = value!;
                        });
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
              ),
              resizeToAvoidBottomInset: false,
              body: Container(
                padding: EdgeInsets.all(10),
                child: orderCacheList.isNotEmpty ?
                ListView.builder(
                    shrinkWrap: true,
                    itemCount: orderCacheList.length,
                    itemBuilder: (BuildContext context, int index) {
                      return Card(
                        elevation: 5,
                        shape: orderCacheList[index].is_selected
                            ? new RoundedRectangleBorder(
                            side: new BorderSide(
                                color: color.backgroundColor, width: 3.0),
                            borderRadius: BorderRadius.circular(4.0))
                            : new RoundedRectangleBorder(
                            side: new BorderSide(
                                color: Colors.white, width: 3.0),
                            borderRadius: BorderRadius.circular(4.0)),
                        child: InkWell(
                          onTap: () async {
                            if(orderCacheList[index].is_selected == false){
                              if(cart.cartNotifierItem.isEmpty){
                                orderCacheList[index].is_selected = true;
                                cart.selectedOptionId = orderCacheList[index].dining_id!;
                                await getOrderDetail(orderCacheList[index]);
                                await addToCart(cart, orderCacheList[index]);
                              } else {
                                if(orderCacheList[index].dining_id == cart.selectedOptionId){
                                  orderCacheList[index].is_selected = true;
                                  await getOrderDetail(orderCacheList[index]);
                                  await addToCart(cart, orderCacheList[index]);
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

                            } else if(orderCacheList[index].is_selected == true) {
                              orderCacheList[index].is_selected = false;
                              cart.removeCartItemBasedOnOrderCache(orderCacheList[index].order_cache_sqlite_id.toString());
                            }
                            //openViewOrderDialog(orderCacheList[index]);
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
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
                                  '#'+orderCacheList[index].batch_id.toString(),
                                  style: TextStyle(fontSize: 20),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(AppLocalizations.of(context)!.translate('order_by')+': ' + orderCacheList[index].order_by!,
                                      style: TextStyle(fontSize: 14),
                                    ),
                                    Text(AppLocalizations.of(context)!.translate('order_at')+': ' + Utils.formatDate(orderCacheList[index].created_at!),
                                      style: TextStyle(fontSize: 14),
                                    ),
                                  ],
                                ),
                                title: Text(
                                  "${Utils.convertTo2Dec(orderCacheList[index].total_amount!,)}",
                                  style: TextStyle(fontSize: 20),
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
              ),
            );
          }
          );
        }
        );
      });
    });
  }

  getDiningOption(diningOption){
    if(diningOption == 'All') return 'all';
    else if(diningOption == 'Take Away') return 'take_away';
    else if(diningOption == 'Dine in') return 'dine_in';
    else return 'delivery';
  }

  addToCart(CartModel cart, OrderCache orderCache) async {
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
          status: 0,
          order_cache_sqlite_id: orderCache.order_cache_sqlite_id.toString(),
          order_cache_key: orderCache.order_cache_key,
          category_sqlite_id: orderDetailList[i].category_sqlite_id,
          order_detail_sqlite_id: orderDetailList[i].order_detail_sqlite_id.toString(),
          refColor: Colors.black,
          first_cache_batch: orderCache.batch_id,
          first_cache_order_by: orderCache.order_by,
          first_cache_created_date_time: orderCache.created_at,
          allow_ticket: orderDetailList[i].allow_ticket,
          ticket_count: orderDetailList[i].ticket_count,
          ticket_exp: orderDetailList[i].ticket_exp,
      );
      cart.addItem(value);
      if(orderCache.dining_name == 'Take Away'){
        cart.selectedOption = 'Take Away';
      } else if(orderCache.dining_name == 'Dine in'){
        cart.selectedOption = 'Dine in';
      } else {
        cart.selectedOption = 'Delivery';
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
      orderDetailList[k].allow_ticket = data[0].allow_ticket;
      orderDetailList[k].ticket_count = data[0].ticket_count;
      orderDetailList[k].ticket_exp = data[0].ticket_exp;
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
