import 'dart:async';

import 'package:flutter/material.dart';
import 'package:pos_system/database/domain.dart';
import 'package:pos_system/fragment/table/merge_bill_dialog.dart';
import 'package:pos_system/fragment/table/remove_detail_dialog.dart';
import 'package:pos_system/notifier/cart_notifier.dart';
import 'package:pos_system/object/branch_link_product.dart';
import 'package:pos_system/object/order.dart';
import 'package:pos_system/object/order_detail.dart';
import 'package:pos_system/object/order_modifier_detail.dart';
import 'package:pos_system/object/product.dart';
import 'package:pos_system/object/product_variant.dart';
import 'package:pos_system/object/product_variant_detail.dart';
import 'package:pos_system/object/variant_item.dart';
import 'package:pos_system/page/progress_bar.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../database/pos_database.dart';
import '../../notifier/theme_color.dart';
import '../../object/cart_product.dart';
import '../../object/modifier_group.dart';
import '../../object/modifier_item.dart';
import '../../object/modifier_link_product.dart';
import '../../object/order_cache.dart';
import '../../object/table.dart';
import '../../object/variant_group.dart';

class TableDetailDialog extends StatefulWidget {
  final PosTable object;
  final Function() callBack;

  const TableDetailDialog(
      {Key? key, required this.object, required this.callBack})
      : super(key: key);

  @override
  State<TableDetailDialog> createState() => _TableDetailDialogState();
}

class _TableDetailDialogState extends State<TableDetailDialog> {
  late StreamController controller;
  List<OrderCache> orderCacheList = [];
  List<OrderDetail> orderDetailList = [];
  List<BranchLinkProduct> branchProductList = [];
  List<VariantGroup> variantGroup = [];
  List<ModifierGroup> modifierGroup = [];
  String productName = '';
  double totalOrderAmount = 0.0;
  bool isLoad = false;
  double priceSST = 0.0;
  double priceServeTax = 0.0;

  @override
  void initState() {
    // TODO: implement initState
    readSpecificTableDetail();
    super.initState();
  }

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeColor>(builder: (context, ThemeColor color, child) {
      return Consumer<CartModel>(builder: (context, CartModel cart, child) {
        return AlertDialog(
          title: Text("table ${widget.object.number} detail"),
          content: isLoad == true
              ? Container(
                      width: 350.0,
                      height: 450.0,
                      child: Column(children: [
                        Expanded(
                          flex: 6,
                          child: Container(
                            child: ListView.builder(
                                shrinkWrap: true,
                                itemCount: orderDetailList.length,
                                itemBuilder: (context, index) {
                                  return Dismissible(
                                    background: Container(
                                      color: Colors.red,
                                      padding: EdgeInsets.only(left: 25.0),
                                      child: Row(
                                        children: [
                                          Icon(Icons.delete,
                                              color: Colors.white),
                                        ],
                                      ),
                                    ),
                                    key: ValueKey(
                                        orderDetailList[index].product_name),
                                    direction: DismissDirection.startToEnd,
                                    confirmDismiss: (direction) async {
                                      if (direction ==
                                          DismissDirection.startToEnd) {
                                        openRemoveOrderDetailDialog(
                                            orderDetailList[index]);
                                      }
                                      return null;
                                    },
                                    child: Card(
                                      child: Container(
                                        margin: EdgeInsets.all(10),
                                          height: 85.0,
                                          child: Column(children: [
                                            Expanded(
                                              child: ListTile(
                                                hoverColor: Colors.transparent,
                                                onTap: () {},
                                                isThreeLine: true,
                                                title: RichText(
                                                  text: TextSpan(
                                                    children: <TextSpan>[
                                                      TextSpan(
                                                          text:
                                                              "${orderDetailList[index].product_name}" +
                                                                  "\n",
                                                          style: TextStyle(
                                                            fontSize: 18,
                                                            color: color
                                                                .backgroundColor,
                                                          )),
                                                      TextSpan(
                                                          text: "RM${orderDetailList[index].price}",
                                                          style: TextStyle(
                                                            fontSize: 13,
                                                            color: color
                                                                .backgroundColor,
                                                          )),
                                                    ],
                                                  ),
                                                ),
                                                subtitle: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    orderDetailList[index].modifierItem.isNotEmpty
                                                        ? Text("+ ${reformatModifierDetail(orderDetailList[index].modifierItem)}")
                                                        : Container(),
                                                    orderDetailList[index].productVariant != null
                                                        ? Text(
                                                            "+ ${reformatVariantDetail(orderDetailList[index].productVariant!)}")
                                                        : Container(),
                                                    Text(
                                                        "${orderDetailList[index].remark}")
                                                  ],
                                                ),
                                                // Text(
                                                //     "Add on: ${reformatModifierDetail(orderDetailList[index].modifier_name) + "\n"} "
                                                //     "${orderDetailList[index].variant_name +"\n"} "
                                                //     "${orderDetailList[index].remark}"
                                                // ),
                                                trailing: Container(
                                                  child: FittedBox(
                                                    child: Row(
                                                      children: [
                                                        Text('x${orderDetailList[index].quantity}',
                                                            style: TextStyle(
                                                          fontSize: 18,
                                                          color: color
                                                              .backgroundColor,
                                                        )),
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ]),
                                      ),
                                    ),
                                  );
                                }),
                          ),
                        ),
                        Expanded(
                          flex: 1,
                          child: Card(
                            elevation: 5,
                            child: ListTile(
                              title: Text("Total",
                                  style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold)),
                              trailing: Text("RM${getAllTotalAmount()}"),
                            ),
                          ),
                        )
                      ]))
              : CustomProgressBar(),
          actions: <Widget>[
            TextButton(
              child: Text('Close'),
              onPressed: () {
                widget.callBack();
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Make payment'),
              onPressed: () async {
                if(cart.cartNotifierItem.isEmpty){
                  addToPaymentCart(cart);
                  Navigator.of(context).pop();
                } else {
                  await openMergeBillDialog(widget.object);
                }

              },
            ),
          ],
        );
      });
    });
  }

  readSpecificTableDetail() async {
    print('readSpecificTableDetail called');
    isLoad = false;
    orderDetailList.clear();
    orderCacheList.clear();
    final prefs = await SharedPreferences.getInstance();
    final int? branch_id = prefs.getInt('branch_id');

    //Get all order table cache
    List<OrderCache> data = await PosDatabase.instance
        .readTableOrderCache(branch_id.toString(), widget.object.table_id.toString());
    //loop all table order cache
    for (int i = 0; i < data.length; i++) {
      if(!orderCacheList.contains(data)){
        orderCacheList = List.from(data);

      }
      //Get all order detail based on order cache id
      List<OrderDetail> detailData = await PosDatabase.instance
          .readTableOrderDetail(data[i].order_cache_sqlite_id.toString());
      //add all order detail from db
      if (!orderDetailList.contains(detailData)) {
        orderDetailList..addAll(detailData);
      }
    }
      //loop all order detail
      for (int k = 0; k < orderDetailList.length; k++) {
        //Get data from branch link product
        List<BranchLinkProduct> result = await PosDatabase.instance
            .readSpecificBranchLinkProduct(
                orderDetailList[k].branch_link_product_sqlite_id!);
        orderDetailList[k].product_name = result[0].product_name!;


        //Get product category
        List<Product> productResult = await PosDatabase.instance
            .readSpecificProductCategory(result[0].product_id!);
        orderDetailList[k].category_id = productResult[0].category_id;

        if (result[0].has_variant == '1') {
          //Get product variant
          List<BranchLinkProduct> variant = await PosDatabase.instance
              .readBranchLinkProductVariant(
                  orderDetailList[k].branch_link_product_sqlite_id!);
          orderDetailList[k].productVariant = ProductVariant(
              product_variant_id: int.parse(variant[0].product_variant_id!),
              variant_name: variant[0].variant_name);

          //Get product variant detail
          List<ProductVariantDetail> productVariantDetail = await PosDatabase.instance.readProductVariantDetail(variant[0].product_variant_id!);
          orderDetailList[k].variantItem.clear();
          for (int v = 0; v < productVariantDetail.length; v++) {
            //Get product variant item
            List<VariantItem> variantItemDetail = await PosDatabase.instance.readProductVariantItemByVariantID(productVariantDetail[v].variant_item_id!);
            orderDetailList[k].variantItem.add(VariantItem(
                variant_item_id:
                    int.parse(productVariantDetail[v].variant_item_id!),
                variant_group_id: variantItemDetail[0].variant_group_id,
                name: variant[0].variant_name,
                isSelected: true));
            productVariantDetail.clear();

          }
        }

        //check product modifier
        List<ModifierLinkProduct> productMod = await PosDatabase.instance.readProductModifier(result[0].product_id!);
        if(productMod.length > 0){
          orderDetailList[k].hasModifier = true;
        }

        if(orderDetailList[k].hasModifier == true){
          //Get order modifier detail
          List<OrderModifierDetail> modDetail = await PosDatabase.instance.readOrderModifierDetail(orderDetailList[k].order_detail_id.toString());
          if (modDetail.length > 0) {
            orderDetailList[k].modifierItem.clear();
            for (int m = 0; m < modDetail.length; m++) {
              // print('mod detail length: ${modDetail.length}');
              if (!orderDetailList[k].modifierItem.contains(modDetail[m].mod_group_id!)) {
                orderDetailList[k].modifierItem.add(ModifierItem(
                    mod_group_id: modDetail[m].mod_group_id!,
                    mod_item_id: int.parse(modDetail[m].mod_item_id!),
                    name: modDetail[m].modifier_name!));
                orderDetailList[k].mod_group_id.add(modDetail[m].mod_group_id!);
                orderDetailList[k].mod_item_id = modDetail[m].mod_item_id;
              }
            }
        }
        }
      }
    setState(() {
      isLoad = true;
    });
  }

  getAllTotalAmount() {
    totalOrderAmount = 0.0;
    priceSST = 0.0;
    priceServeTax = 0.0;
    for (int i = 0; i < orderCacheList.length; i++) {
      totalOrderAmount += double.parse(orderCacheList[i].total_amount!);
    }

    return totalOrderAmount.toStringAsFixed(2);
  }


  reformatModifierDetail(List<ModifierItem> modList) {
    String result = '';
    for (int i = 0; i < modList.length; i++) {
      result += modList[i].name.toString().trim();
    }
    return result;
  }

  reformatVariantDetail(ProductVariant productVariant) {
    String result = '';
    result = productVariant.variant_name!.replaceAll('|', '\n+').trim();
    return result;
  }

  Future<Future<Object?>> openRemoveOrderDetailDialog(
      OrderDetail orderDetail) async {
    return showGeneralDialog(
        barrierColor: Colors.black.withOpacity(0.5),
        transitionBuilder: (context, a1, a2, widget) {
          final curvedValue = Curves.easeInOutBack.transform(a1.value) - 1.0;
          return Transform(
            transform: Matrix4.translationValues(0.0, curvedValue * 200, 0.0),
            child: Opacity(
              opacity: a1.value,
              child: DetailRemoveDialog(
                object: orderDetail,
                callBack: () => readSpecificTableDetail(),
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

  Future<Future<Object?>> openMergeBillDialog(PosTable posTable) async {
    return showGeneralDialog(
        barrierColor: Colors.black.withOpacity(0.5),
        transitionBuilder: (context, a1, a2, widget) {
          final curvedValue = Curves.easeInOutBack.transform(a1.value) - 1.0;
          return Transform(
            transform: Matrix4.translationValues(0.0, curvedValue * 200, 0.0),
            child: Opacity(
              opacity: a1.value,
              child: MergeBillDialog(
                tableObject: posTable,
                callBack: addToPaymentCart,
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
          print('modifierGroup[i].modifierChild: ${temp[k].mod_item_id}');
          temp.removeAt(k);
        }
      }
      modifierGroup[position].modifierChild = modItemChild;
    }
    return modifierGroup;
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


  addToPaymentCart(CartModel cart) {
    var value;
    cart.removeAllTable();
    for (int i = 0; i < orderDetailList.length; i++) {
      value = cartProductItem(
        orderDetailList[i].branch_link_product_sqlite_id!,
        orderDetailList[i].product_name,
        orderDetailList[i].category_id!,
        orderDetailList[i].price!,
        int.parse(orderDetailList[i].quantity!),
        getModifierGroupItem(orderDetailList[i]),
        getVariantGroupItem(orderDetailList[i]),
        orderDetailList[i].remark!,
        1,
        null
      );
      cart.addItem(value);
    }
    if(cart.selectedTable.isEmpty){
      cart.addTable(widget.object);
    }

  }
}
