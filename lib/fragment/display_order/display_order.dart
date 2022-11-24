import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:pos_system/database/domain.dart';
import 'package:pos_system/database/pos_database.dart';
import 'package:pos_system/fragment/display_order/view_order_dialog.dart';
import 'package:pos_system/notifier/cart_notifier.dart';
import 'package:pos_system/notifier/table_notifier.dart';
import 'package:pos_system/object/dining_option.dart';
import 'package:pos_system/object/order.dart';
import 'package:pos_system/object/order_cache.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../notifier/theme_color.dart';
import '../../object/branch_link_product.dart';
import '../../object/cart_product.dart';
import '../../object/modifier_group.dart';
import '../../object/modifier_item.dart';
import '../../object/order_detail.dart';
import '../../object/order_modifier_detail.dart';
import '../../object/product.dart';
import '../../object/product_variant.dart';
import '../../object/product_variant_detail.dart';
import '../../object/variant_group.dart';
import '../../object/variant_item.dart';

class DisplayOrderPage extends StatefulWidget {
  const DisplayOrderPage({Key? key}) : super(key: key);

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
  }


  getDiningList() async{
    list.add('All');
    final prefs = await SharedPreferences.getInstance();
    final String? user = prefs.getString('user');
    Map userObject = json.decode(user!);
    List<DiningOption> data = await PosDatabase.instance.readAllDiningOption(userObject['company_id']);
    for(int i=0; i< data.length; i++){
      if(data[i].name != 'Dine in'){
        list.add(data[i].name!);
      }
    }

  }

  getOrderList({model}) async {
    if (model != null) {
      model.changeContent2(false);
    }
    final prefs = await SharedPreferences.getInstance();
    final String? user = prefs.getString('user');
    Map userObject = json.decode(user!);
    final int? branch_id = prefs.getInt('branch_id');
    if (selectDiningOption == 'All') {
      List<OrderCache> data = await PosDatabase.instance.readOrderCacheNoDineIn(
          branch_id.toString(), userObject['company_id']);
      setState(() {
        orderCacheList = data;
      });
    } else {
      List<OrderCache> data = await PosDatabase.instance.readOrderCacheSpecial(
          branch_id.toString(), userObject['company_id'],selectDiningOption!);
      setState(() {
        orderCacheList = data;
      });
    }
  }

  Future<Future<Object?>> openViewOrderDialog(OrderCache data) async {
    return showGeneralDialog(
        barrierColor: Colors.black.withOpacity(0.5),
        transitionBuilder: (context, a1, a2, widget) {
          final curvedValue = Curves.easeInOutBack.transform(a1.value) - 1.0;
          return Transform(
            transform: Matrix4.translationValues(0.0, curvedValue * 200, 0.0),
            child: Opacity(
              opacity: a1.value,
              child: ViewOrderDialogPage(orderCache: data),
            ),
          );
        },
        transitionDuration: Duration(milliseconds: 200),
        barrierDismissible: false,
        context: context,
        pageBuilder: (context, animation1, animation2) {
          return null!;
        });
  }


  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeColor>(builder: (context, ThemeColor color, child) {
      return Consumer<CartModel>(builder: (context, CartModel cart, child) {
          return Consumer<TableModel>(builder: (context, TableModel tableModel, child) {
            if (tableModel.isChange) {
              getOrderList(model: tableModel);
            }
              return Scaffold(
                body: Container(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Text(
                              "Other Order",
                              style: TextStyle(fontSize: 25),
                            ),
                            Spacer(),
                            Expanded(
                              child: Padding(
                                padding: EdgeInsets.fromLTRB(0, 0, 60, 0),
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
                                                e,
                                                style: TextStyle(fontSize: 18),
                                              ),
                                            ),
                                          ))
                                      .toList(),
                                  // Customize the selected item
                                  selectedItemBuilder: (BuildContext context) => list
                                      .map((e) => Center(
                                            child: Text(e),
                                          ))
                                      .toList(),
                                ),
                              ),
                            ),
                          ],
                        ),
                        orderCacheList.length != 0 ?Expanded(
                          child: ListView.builder(
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
                                        //reset other selected order
                                        for(int i = 0; i < orderCacheList.length; i++){
                                          orderCacheList[i].is_selected = false;
                                          cart.initialLoad();
                                        }
                                        orderCacheList[index].is_selected = true;
                                        await getOrderDetail(orderCacheList[index]);
                                        await addToCart(cart, orderCacheList[index]);


                                      } else if(orderCacheList[index].is_selected == true) {
                                        orderCacheList[index].is_selected = false;
                                        cart.initialLoad();
                                      }
                                      //openViewOrderDialog(orderCacheList[index]);
                                    },
                                    child: Padding(
                                      padding: const EdgeInsets.all(16.0),
                                      child: ListTile(
                                          leading:
                                              orderCacheList[index].dining_id == '2'
                                                  ? Icon(
                                                      Icons.fastfood_sharp,
                                                      color: color.backgroundColor,
                                                      size: 30.0,
                                                    )
                                                  : Icon(
                                                      Icons.delivery_dining,
                                                      color: color.backgroundColor,
                                                      size: 30.0,
                                                    ),
                                          trailing: Text(
                                            '#'+orderCacheList[index].batch_id.toString(),
                                            style: TextStyle(fontSize: 20),
                                          ),
                                          subtitle: Text('Order by: ' +
                                            orderCacheList[index].order_by!,
                                            style: TextStyle(fontSize: 16),
                                          ),
                                          title: Text(
                                            orderCacheList[index]
                                                .total_amount
                                                .toString(),
                                            style: TextStyle(fontSize: 20),
                                          )),
                                    ),
                                  ),
                                );
                              }),
                        ): Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.list,
                                color: Colors.grey,
                                size: 36.0,
                              ),
                              Text("No Order", style: TextStyle(fontSize: 24),),
                            ],
                          ),
                        ),
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
  }

  addToCart(CartModel cart, OrderCache orderCache) async {
    final prefs = await SharedPreferences.getInstance();
    final int? branch_id = prefs.getInt('branch_id');
    var value;
    for (int i = 0; i < orderDetailList.length; i++) {
      value = cartProductItem(
          orderDetailList[i].branch_link_product_sqlite_id!,
          orderDetailList[i].productName!,
          orderDetailList[i].category_id!,
          orderDetailList[i].price!,
          int.parse(orderDetailList[i].quantity!),
          getModifierGroupItem(orderDetailList[i]),
          getVariantGroupItem(orderDetailList[i]),
          orderDetailList[i].remark!,
          0,
          orderCache.order_cache_sqlite_id.toString(),
          Colors.black
      );
      cart.addItem(value);
      if(orderCache.dining_id == '2'){
        cart.selectedOption = 'Take Away';
      } else if(orderCache.dining_id == '3') {
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
    List<OrderDetail> detailData = await PosDatabase.instance.readSpecificOrderDetail(orderCache.order_cache_sqlite_id.toString());
    if(detailData.length > 0){
      orderDetailList = List.from(detailData);
    }
    for (int k = 0; k < orderDetailList.length; k++) {
      List<BranchLinkProduct> result = await PosDatabase.instance.readSpecificBranchLinkProduct(orderDetailList[k].branch_link_product_sqlite_id!);
      //Get product category
      List<Product> productResult = await PosDatabase.instance.readSpecificProductCategory(result[0].product_id!);
      orderDetailList[k].category_id = productResult[0].category_id;
      if(orderDetailList[k].has_variant == '1'){
        List<BranchLinkProduct> variant = await PosDatabase.instance
            .readBranchLinkProductVariant(
            orderDetailList[k].branch_link_product_sqlite_id!);
        orderDetailList[k].productVariant = ProductVariant(
            product_variant_id: int.parse(variant[0].product_variant_id!),
            variant_name: variant[0].variant_name);

        //Get product variant detail
        List<ProductVariantDetail> productVariantDetail = await PosDatabase
            .instance
            .readProductVariantDetail(variant[0].product_variant_id!);
        orderDetailList[k].variantItem.clear();
        for (int v = 0; v < productVariantDetail.length; v++) {
          //Get product variant item
          List<VariantItem> variantItemDetail = await PosDatabase.instance
              .readProductVariantItemByVariantID(
              productVariantDetail[v].variant_item_id!);
          orderDetailList[k].variantItem.add(VariantItem(
              variant_item_id:
              int.parse(productVariantDetail[v].variant_item_id!),
              variant_group_id: variantItemDetail[0].variant_group_id,
              name: variant[0].variant_name,
              isSelected: true));
          productVariantDetail.clear();
        }
      }
    }
  }
}
