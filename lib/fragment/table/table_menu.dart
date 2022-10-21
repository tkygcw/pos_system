import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:pos_system/fragment/table/table_change_dialog.dart';
import 'package:pos_system/fragment/table/table_detail_dialog.dart';
import 'package:pos_system/fragment/table/table_dialog.dart';
import 'package:pos_system/notifier/cart_notifier.dart';
import 'package:pos_system/object/order_cache.dart';
import 'package:pos_system/object/table.dart';
import 'package:pos_system/object/table_use_detail.dart';
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
import '../../object/order_detail.dart';
import '../../object/order_modifier_detail.dart';
import '../../object/product.dart';
import '../../object/product_variant.dart';
import '../../object/product_variant_detail.dart';
import '../../object/variant_group.dart';
import '../../object/variant_item.dart';

class TableMenu extends StatefulWidget {
  const TableMenu({Key? key}) : super(key: key);

  @override
  _TableMenuState createState() => _TableMenuState();
}

class _TableMenuState extends State<TableMenu> {
  List<PosTable> tableList = [];
  List<OrderCache> orderCacheList = [];
  List<OrderDetail> orderDetailList = [];
  List<VariantGroup> variantGroup = [];
  List<ModifierGroup> modifierGroup = [];
  List<PosTable> sameGroupTbList = [];
  double priceSST = 0.0;
  double priceServeTax = 0.0;
  bool isLoaded = false;
  Color cardColor = Colors.primaries[Random().nextInt(Colors.primaries.length)];

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    readAllTable();
  }

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
  }

  hexToColor(String hexCode) {
    return new Color(int.parse(hexCode.substring(1, 7), radix: 16) + 0xFF000000);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeColor>(builder: (context, ThemeColor color, child) {
      return Consumer<CartModel>(
        builder: (context, CartModel cart, child) {
          return Scaffold(
            body: Container(
                    child: Column(
                      children: [
                        Padding(
                          padding: EdgeInsets.fromLTRB(11, 15, 11, 4),
                          child: Row(
                            children: [
                              Text(
                                "Table",
                                style: TextStyle(fontSize: 25),
                              ),
                              Padding(
                                padding: const EdgeInsets.fromLTRB(18, 0, 0, 0),
                                child: ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(
                                        primary: color.backgroundColor),
                                    onPressed: () {
                                      openAddTableDialog(PosTable());
                                    },
                                    icon: Icon(Icons.add),
                                    label: Text("Table")),
                              ),
                              SizedBox(width: 500),
                              Expanded(
                                child: TextField(
                                  decoration: InputDecoration(
                                    isDense: true,
                                    border: InputBorder.none,
                                    labelText: 'Search',
                                    focusedBorder: OutlineInputBorder(
                                      borderSide: const BorderSide(
                                          color: Colors.grey, width: 2.0),
                                      borderRadius: BorderRadius.circular(25.0),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 20),
                        isLoaded ?
                        Expanded(
                          child: GridView.count(
                            shrinkWrap: true,
                            crossAxisCount: 5,
                            children: List.generate(
                                //this is the total number of cards
                                tableList.length, (index) {
                              // tableList[index].seats == 2;
                              return Card(
                                color: tableList[index].status != 0
                                    ? hexToColor(tableList[index].cardColor!)
                                    : Colors.white,
                                shape: tableList[index].isSelected
                                    ? new RoundedRectangleBorder(
                                    side: new BorderSide(color: Colors.blue, width: 3.0),
                                    borderRadius: BorderRadius.circular(4.0))
                                    : new RoundedRectangleBorder(
                                    side: new BorderSide(color: Colors.white, width: 3.0),
                                    borderRadius: BorderRadius.circular(4.0)),
                                elevation: 5,
                                child: InkWell(
                                  splashColor:
                                  Colors.blue.withAlpha(30),
                                  onLongPress: () {
                                    if (tableList[index].status != 1) {
                                      openAddTableDialog(
                                          tableList[index]);
                                    } else {
                                      openChangeTableDialog(
                                          tableList[index]);
                                    }
                                  },
                                  onTap: () async {
                                    if (tableList[index].status == 1) {
                                      // table in use (colored)
                                      for (int i = 0; i < tableList.length; i++) {
                                        if (tableList[index].group == tableList[i].group) {
                                          if (tableList[i].isSelected == false) {
                                            tableList[i].isSelected = true;

                                          } else if (tableList[i].isSelected == true){

                                            if (tableList[index].group == tableList[i].group) {
                                              setState(() {
                                                removeFromCart(cart, tableList[index]);
                                                tableList[i].isSelected = false;
                                                cart.removeSpecificTable(tableList[i]);
                                              });

                                            } else {
                                              setState(() {
                                                removeFromCart(cart, tableList[index]);
                                                tableList[i].isSelected = false;
                                                cart.removeSpecificTable(tableList[index]);
                                              });
                                            }

                                          }
                                        }

                                      }
                                    } else {
                                      for (int j = 0; j < tableList.length; j++) {
                                        //reset all using table to un-select (table status == 1)
                                        if (tableList[j].status == 1) {
                                          tableList[j].isSelected = false;
                                          cart.removeAllCartItem();
                                          cart.removeSpecificTable(tableList[j]);
                                        }
                                      }
                                      Fluttertoast.showToast(
                                          backgroundColor: Color(0xFF07F107),
                                          msg: "Table not in use");
                                    }
                                    if (tableList[index].status == 1 && tableList[index].isSelected == true) {
                                      await readSpecificTableDetail(tableList[index]);
                                      addToCart(cart, tableList[index]);

                                    }
                                  },
                                  child: Container(
                                    margin: EdgeInsets.all(2),
                                    child: Column(
                                      children: [
                                        tableList[index].group != null ?
                                        Expanded(
                                            child:  Text(
                                              "Group: ${tableList[index].group}",
                                              style: TextStyle(fontSize: 18),
                                            )
                                        ): Expanded(child: Text('')),
                                        Container(
                                          margin: EdgeInsets.fromLTRB(0, 5, 0, 5),
                                          height:
                                              MediaQuery.of(context).size.height / 6,
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
                                                fit: BoxFit.cover,
                                              ),
                                              Container(
                                                  alignment: Alignment.center,
                                                  child: Text(
                                                      "#" + tableList[index].number!)),
                                            ],
                                          ),
                                        ),
                                        tableList[index].status == 1 ?
                                        Expanded(
                                            child: Text(
                                              "RM ${tableList[index].total_Amount.toStringAsFixed(2)}",
                                              style: TextStyle(fontSize: 18)),
                                        ) :
                                            Expanded
                                              (child: Text(''))
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            }),
                          ),
                        ) : CustomProgressBar()
                      ],
                    ),
                  )
          );
        }
      );
    });
  }

  Future<Future<Object?>> openAddTableDialog(PosTable posTable) async {
    return showGeneralDialog(
        barrierColor: Colors.black.withOpacity(0.5),
        transitionBuilder: (context, a1, a2, widget) {
          final curvedValue = Curves.easeInOutBack.transform(a1.value) - 1.0;
          return Transform(
            transform: Matrix4.translationValues(0.0, curvedValue * 200, 0.0),
            child: Opacity(
                opacity: a1.value,
                child: TableDialog(
                    object: posTable, callBack: () => readAllTable())),
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

  Future<Future<Object?>> openChangeTableDialog(PosTable posTable) async {
    return showGeneralDialog(
        barrierColor: Colors.black.withOpacity(0.5),
        transitionBuilder: (context, a1, a2, widget) {
          final curvedValue = Curves.easeInOutBack.transform(a1.value) - 1.0;
          return Transform(
            transform: Matrix4.translationValues(0.0, curvedValue * 200, 0.0),
            child: Opacity(
                opacity: a1.value,
                child: TableChangeDialog(
                  object: posTable,
                  callBack: () => readAllTable(),
                )),
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

  Future<Future<Object?>> openTableDetailDialog(PosTable posTable) async {
    return showGeneralDialog(
        barrierColor: Colors.black.withOpacity(0.5),
        transitionBuilder: (context, a1, a2, widget) {
          final curvedValue = Curves.easeInOutBack.transform(a1.value) - 1.0;
          return Transform(
            transform: Matrix4.translationValues(0.0, curvedValue * 200, 0.0),
            child: Opacity(
              opacity: a1.value,
              child: TableDetailDialog(
                object: posTable,
                callBack: () => readAllTable(),
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

  readAllTable() async {
    isLoaded = false;
    final prefs = await SharedPreferences.getInstance();
    final int? branch_id = prefs.getInt('branch_id');
    List<PosTable> data = await PosDatabase.instance.readAllTable(branch_id!.toInt());

    tableList = List.from(data);
    await readAllTableAmount();
    setState(() {
      isLoaded = true;
    });
  }

  readAllTableAmount() async {
    priceSST = 0.0;
    priceServeTax = 0.0;
    print('readAllTableAmount called');
    final prefs = await SharedPreferences.getInstance();
    final int? branch_id = prefs.getInt('branch_id');

    for (int i = 0; i < tableList.length; i++) {
      List<TableUseDetail> tableUseDetailData = await PosDatabase.instance.readSpecificTableUseDetail(tableList[i].table_sqlite_id!);
      if (tableUseDetailData.length > 0) {
        List<OrderCache> data = await PosDatabase.instance.readTableOrderCache(branch_id.toString(), tableUseDetailData[0].table_use_sqlite_id!);
        tableList[i].group = data[0].table_use_sqlite_id;
        tableList[i].cardColor = data[0].cardColor;
        for(int j = 0; j < data.length; j++){
          tableList[i].total_Amount += double.parse(data[j].total_amount!);
        }
      }
    }
  }

  readSpecificTableDetail(PosTable posTable) async {
    orderDetailList.clear();
    orderCacheList.clear();
    final prefs = await SharedPreferences.getInstance();
    final int? branch_id = prefs.getInt('branch_id');

    //Get specific table use detail
    List<TableUseDetail> tableUseDetailData = await PosDatabase.instance
        .readSpecificTableUseDetail(posTable.table_sqlite_id!);

    //Get all order table cache
    List<OrderCache> data = await PosDatabase.instance.readTableOrderCache(
        branch_id.toString(), tableUseDetailData[0].table_use_sqlite_id!);
    //loop all table order cache
    for (int i = 0; i < data.length; i++) {
      if (!orderCacheList.contains(data)) {
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
          0,
          orderDetailList[i].order_cache_sqlite_id);
      cart.addItem(value);
    }
    for (int j = 0; j < orderCacheList.length; j++) {
      //Get specific table use detail
      List<TableUseDetail> tableUseDetailData = await PosDatabase.instance
          .readAllTableUseDetail(orderCacheList[j].table_use_sqlite_id!);
      tableUseDetailList = List.from(tableUseDetailData);
    }

    for (int k = 0; k < tableUseDetailList.length; k++) {
      List<PosTable> tableData = await PosDatabase.instance
          .readSpecificTable(branch_id!, tableUseDetailList[k].table_sqlite_id!);
      cart.addTable(tableData[0]);
    }
  }

  removeFromCart(CartModel cart, PosTable posTable) async {
    print('remove from cart called');
    var value;
    await readSpecificTableDetail(posTable);
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
          0,
          orderDetailList[i].order_cache_sqlite_id);
      cart.removeSpecificItem(value);
    }
  }


}
