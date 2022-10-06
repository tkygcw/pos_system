import 'dart:async';

import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:pos_system/notifier/cart_notifier.dart';
import 'package:pos_system/page/progress_bar.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../database/pos_database.dart';
import '../../notifier/theme_color.dart';
import '../../object/branch_link_product.dart';
import '../../object/cart_product.dart';
import '../../object/modifier_group.dart';
import '../../object/modifier_item.dart';
import '../../object/modifier_link_product.dart';
import '../../object/order_cache.dart';
import '../../object/order_detail.dart';
import '../../object/order_modifier_detail.dart';
import '../../object/product.dart';
import '../../object/product_variant.dart';
import '../../object/product_variant_detail.dart';
import '../../object/table.dart';
import '../../object/table_use_detail.dart';
import '../../object/variant_group.dart';
import '../../object/variant_item.dart';
import '../../translation/AppLocalizations.dart';
import 'package:reorderable_grid_view/reorderable_grid_view.dart';

class CartDialog extends StatefulWidget {
  const CartDialog({Key? key}) : super(key: key);

  @override
  State<CartDialog> createState() => _CartDialogState();
}

class _CartDialogState extends State<CartDialog> {
  List<PosTable> tableList = [];
  List<OrderCache> orderCacheList = [];
  List<OrderDetail> orderDetailList = [];
  List<VariantGroup> variantGroup = [];
  List<ModifierGroup> modifierGroup = [];
  late StreamController controller;
  double priceSST = 0.0;
  double priceServeTax = 0.0;
  bool isLoad = false;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    controller = StreamController();
    readAllTable();
  }

  Future showSecondDialog(BuildContext context, ThemeColor color, int dragIndex,
      int targetIndex, CartModel cart) {
    return showDialog(
      barrierDismissible: false,
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: Text('Confirm merge table'),
        content: SizedBox(
            height: 100.0,
            width: 350.0,
            child: Text(
                'merge table ${tableList[dragIndex].number} with table ${tableList[targetIndex].number} ?')),
        actions: <Widget>[
          TextButton(
            child: Text('${AppLocalizations.of(context)?.translate('close')}'),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
          TextButton(
            child: Text('${AppLocalizations.of(context)?.translate('yes')}'),
            onPressed: () async  {
              if (tableList[dragIndex].table_id != tableList[targetIndex].table_id) {
                final prefs = await SharedPreferences.getInstance();
                final int? branch_id = prefs.getInt('branch_id');
                cart.removeAllTable();
                List<TableUseDetail> DragTableUseDetailData = await PosDatabase.instance.readSpecificTableUseDetail(tableList[dragIndex].table_id!);
                List<TableUseDetail> TargetTableUseDetailData = await PosDatabase.instance.readSpecificTableUseDetail(tableList[targetIndex].table_id!);
                List<TableUseDetail> allDragTableUseData = await PosDatabase.instance.readAllTableUseDetail(DragTableUseDetailData[0].table_use_id!);
                List<TableUseDetail> allTargetTableUseData = await PosDatabase.instance.readAllTableUseDetail(TargetTableUseDetailData[0].table_use_id!);
                for(int i = 0 ; i < allDragTableUseData.length; i++){
                List<PosTable> tableData = await PosDatabase.instance.readSpecificTable(branch_id!, allDragTableUseData[i].table_id!);
                  cart.addTable(tableData[0]);
                }
                for(int j = 0 ; j < allTargetTableUseData.length; j++){
                  List<PosTable> TargetTableData = await PosDatabase.instance.readSpecificTable(branch_id!, allTargetTableUseData[j].table_id!);
                  cart.addTable(TargetTableData[0]);
                }

              } else {
                Fluttertoast.showToast(
                    backgroundColor: Color(0xFFFF0000),
                    msg:
                        "${AppLocalizations.of(context)?.translate('merge_error')}");
              }

              Navigator.of(context).pop();
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeColor>(builder: (context, ThemeColor color, child) {
      return StreamBuilder(
          stream: controller.stream,
          builder: (context, snapshot) {
            return AlertDialog(
              title: Text("Select Table"),
              content: isLoad ?
              Container(
                height: 650,
                width: MediaQuery.of(context).size.width /2,
                child: Consumer<CartModel>(
                    builder: (context, CartModel cart, child) {
                  return Column(
                    children: [
                      Expanded(
                        child: ReorderableGridView.count(
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                          crossAxisCount: 4,
                          children: tableList
                              .asMap()
                              .map((index, posTable) =>
                                  MapEntry(index, tableItem(cart, index)))
                              .values
                              .toList(),
                          onReorder: (int oldIndex, int newIndex) {
                            showSecondDialog(
                                context, color, oldIndex, newIndex, cart);
                          },
                        ),
                      ),
                    ],
                  );
                }),
              ) : CustomProgressBar(),
              actions: <Widget>[
                TextButton(
                  child: Text(
                      '${AppLocalizations.of(context)?.translate('close')}'),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
              ],
            );
          });
    });
  }

  Widget tableItem(CartModel cart, index) {
    return Container(
      key: Key(index.toString()),
      child: Card(
        color: tableList[index].status != 0 ? Colors.red : Colors.white,
        child: Container(
          margin: EdgeInsets.all(10),
          child: Column(
            children: [
              tableList[index].group != null
                  ? Text(
                      "Group: ${tableList[index].group}",
                      style: TextStyle(fontSize: 18),
                    )
                  : Text(''),
              Container(
                margin: EdgeInsets.fromLTRB(0, 2, 0, 2),
                height: MediaQuery.of(context).size.height / 8,
                child: Stack(
                  alignment: Alignment.bottomLeft,
                  children: [
                    Ink.image(
                      image: tableList[index].seats == '2'
                          ? NetworkImage(
                              "https://www.hometown.in/media/cms/icon/Two-Seater-Dining-Sets.png")
                          : tableList[index].seats == '4'
                              ? NetworkImage(
                                  "https://www.hometown.in/media/cms/icon/Four-Seater-Dining-Sets.png")
                              : tableList[index].seats == '6'
                                  ? NetworkImage(
                                      "https://www.hometown.in/media/cms/icon/Six-Seater-Dining-Sets.png")
                                  : NetworkImage(
                                      "https://png.pngtree.com/png-vector/20190820/ourmid/pngtree-no-image-vector-illustration-isolated-png-image_1694547.jpg"),
                      child: InkWell(
                        splashColor: Colors.blue.withAlpha(30),
                        onTap: () async {
                          if (tableList[index].status == 1) {
                            cart.removeAllCartItem();
                            await readSpecificTableDetail(tableList[index]);
                            addToCart(cart, tableList[index]);
                            Navigator.of(context).pop();
                          } else {
                            cart.removeAllCartItem();
                            cart.removeAllTable();
                            cart.addTable(tableList[index]);
                            Navigator.of(context).pop();
                          }
                        },
                      ),
                      fit: BoxFit.cover,
                    ),
                    Container(
                        alignment: Alignment.center,
                        child: Text("#" + tableList[index].number!)),
                  ],
                ),
              ),
              tableList[index].status == 1
                  ? Container(
                      alignment: Alignment.topCenter,
                      child: Text(
                        "RM ${tableList[index].total_Amount.toStringAsFixed(2)}",
                        style: TextStyle(fontSize: 18),
                      ),
                    )
                  : Container()
            ],
          ),
        ),
      ),
    );
  }

  readAllTable() async {
    isLoad = false;
    final prefs = await SharedPreferences.getInstance();
    final int? branch_id = prefs.getInt('branch_id');

    List<PosTable> data = await PosDatabase.instance.readAllTable(branch_id!.toInt());

    tableList = List.from(data);
    readAllTableAmount();
    setState(() {
      
      isLoad = true;
    });
  }

  readAllTableAmount() async {
    print('readAllTableAmount called');
    final prefs = await SharedPreferences.getInstance();
    final int? branch_id = prefs.getInt('branch_id');

    for (int i = 0; i < tableList.length; i++) {
      List<TableUseDetail> tableUseDetailData = await PosDatabase.instance
          .readSpecificTableUseDetail(tableList[i].table_id!);
      if (tableUseDetailData.length > 0) {
        List<OrderCache> data = await PosDatabase.instance.readTableOrderCache(
            branch_id.toString(), tableUseDetailData[0].table_use_id!);
        tableList[i].total_Amount += double.parse(data[0].total_amount!);
        tableList[i].group = data[0].table_use_id;
      }
    }
    controller.add('refresh');
  }

  readSpecificTableDetail(PosTable posTable) async {
    print('readSpecificTableDetail called');
    orderDetailList.clear();
    orderCacheList.clear();
    final prefs = await SharedPreferences.getInstance();
    final int? branch_id = prefs.getInt('branch_id');

    //Get specific table use detail
    List<TableUseDetail> tableUseDetailData = await PosDatabase.instance
        .readSpecificTableUseDetail(posTable.table_id!);

    //Get all order table cache
    List<OrderCache> data = await PosDatabase.instance.readTableOrderCache(
        branch_id.toString(), tableUseDetailData[0].table_use_id!);
    //loop all table order cache
    for (int i = 0; i < data.length; i++) {
      if (!orderCacheList.contains(data)) {
        orderCacheList = List.from(data);
      }
      //Get all order detail based on order cache id
      List<OrderDetail> detailData = await PosDatabase.instance
          .readTableOrderDetail(data[i].order_cache_id.toString());
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
              orderDetailList[k].branch_link_product_id!);
      orderDetailList[k].product_name = result[0].product_name!;

      //Get product category
      List<Product> productResult = await PosDatabase.instance
          .readSpecificProductCategory(result[0].product_id!);
      orderDetailList[k].category_id = productResult[0].category_id;

      if (result[0].has_variant == '1') {
        //Get product variant
        List<BranchLinkProduct> variant = await PosDatabase.instance
            .readBranchLinkProductVariant(
                orderDetailList[k].branch_link_product_id!);
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

      //check product modifier
      List<ModifierLinkProduct> productMod =
          await PosDatabase.instance.readProductModifier(result[0].product_id!);
      if (productMod.length > 0) {
        orderDetailList[k].hasModifier = true;
      }

      if (orderDetailList[k].hasModifier == true) {
        //Get order modifier detail
        List<OrderModifierDetail> modDetail = await PosDatabase.instance
            .readOrderModifierDetail(
                orderDetailList[k].order_detail_id.toString());
        if (modDetail.length > 0) {
          orderDetailList[k].modifierItem.clear();
          for (int m = 0; m < modDetail.length; m++) {
            // print('mod detail length: ${modDetail.length}');
            if (!orderDetailList[k]
                .modifierItem
                .contains(modDetail[m].mod_group_id!)) {
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

  addToCart(CartModel cart, PosTable posTable) async {
    final prefs = await SharedPreferences.getInstance();
    final int? branch_id = prefs.getInt('branch_id');
    var value;
    List<TableUseDetail> tableUseDetailList = [];
    cart.removeAllTable();
    for (int i = 0; i < orderDetailList.length; i++) {
      value = cartProductItem(
        orderDetailList[i].branch_link_product_id!,
        orderDetailList[i].product_name,
        orderDetailList[i].category_id!,
        orderDetailList[i].price!,
        int.parse(orderDetailList[i].quantity!),
        getModifierGroupItem(orderDetailList[i]),
        getVariantGroupItem(orderDetailList[i]),
        orderDetailList[i].remark!,
      );
      cart.addItem(value);
    }
    for (int j = 0; j < orderCacheList.length; j++) {
      //Get specific table use detail
      List<TableUseDetail> tableUseDetailData = await PosDatabase.instance
          .readAllTableUseDetail(orderCacheList[j].table_use_id!);
      tableUseDetailList = List.from(tableUseDetailData);
    }

    for (int k = 0; k < tableUseDetailList.length; k++) {
      List<PosTable> tableData = await PosDatabase.instance
          .readSpecificTable(branch_id!, tableUseDetailList[k].table_id!);
      cart.addTable(tableData[0]);
    }
  }
}
