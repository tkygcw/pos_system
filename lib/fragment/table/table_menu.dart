import 'dart:async';

import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:pos_system/fragment/table/table_change_dialog.dart';
import 'package:pos_system/fragment/table/table_detail_dialog.dart';
import 'package:pos_system/fragment/table/table_dialog.dart';
import 'package:pos_system/main.dart';
import 'package:pos_system/notifier/cart_notifier.dart';
import 'package:pos_system/object/order_cache.dart';
import 'package:pos_system/object/table.dart';
import 'package:pos_system/object/table_use_detail.dart';
import 'package:pos_system/page/progress_bar.dart';
import 'package:provider/provider.dart';

import '../../database/domain.dart';
import '../../database/pos_database.dart';
import '../../notifier/table_notifier.dart';
import '../../notifier/theme_color.dart';
import '../../object/branch_link_product.dart';
import '../../object/cart_product.dart';
import '../../object/modifier_group.dart';
import '../../object/modifier_item.dart';
import '../../object/modifier_link_product.dart';
import '../../object/order_detail.dart';
import '../../object/order_modifier_detail.dart';
import '../../object/print_receipt.dart';
import '../../object/printer.dart';
import '../../object/product.dart';
import '../../object/product_variant.dart';
import '../../object/product_variant_detail.dart';
import '../../object/variant_group.dart';
import '../../object/variant_item.dart';

class TableMenu extends StatefulWidget {
  final CartModel cartModel;
  final Function() callBack;
  const TableMenu({Key? key, required this.callBack, required this.cartModel}) : super(key: key);

  @override
  _TableMenuState createState() => _TableMenuState();
}

class _TableMenuState extends State<TableMenu> {
  List<Printer> printerList = [];
  List<PosTable> tableList = [];
  List<OrderCache> orderCacheList = [];
  List<OrderDetail> orderDetailList = [];
  List<VariantGroup> variantGroup = [];
  List<ModifierGroup> modifierGroup = [];
  List<PosTable> sameGroupTbList = [];
  double priceSST = 0.0;
  double priceServeTax = 0.0;
  bool isLoaded = false;
  bool productDetailLoaded = false;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    readAllTable();
    readAllPrinters();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.cartModel.initialLoad();
    });
  }

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
  }

  fontColor({required PosTable posTable}){
    if(posTable.status == 1){
      Color fontColor = Colors.black;
      Color backgroundColor = toColor(posTable.card_color!);
      if(backgroundColor.computeLuminance() > 0.5){
        fontColor = Colors.black;
      } else {
        fontColor = Colors.white;
      }
      return fontColor;
    }
  }

  toColor(String hex) {
    var hexColor = hex.replaceAll("#", "");
    if (hexColor.length == 6) {
      hexColor = "FF" + hexColor;
    }
    if (hexColor.length == 8) {
      return Color(int.parse("0x$hexColor"));
    }
  }

  searchTable(String text) async {
    isLoaded = false;
    List<PosTable> data = await PosDatabase.instance.searchTable(text);
    tableList = data;
    await readAllTableGroup();
    if(mounted){
      setState(() {
        isLoaded = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeColor>(builder: (context, ThemeColor color, child) {
      return Consumer<CartModel>(builder: (context, CartModel cart, child) {
        return Consumer<TableModel>(builder: (context, TableModel tableModel, child) {
          if (tableModel.isChange) {
            readAllTable(model: tableModel);
          }
          if(notificationModel.contentLoad == true) {
            isLoaded = false;
          }
          if(notificationModel.contentLoad == true && notificationModel.contentLoaded == true){
            notificationModel.resetContentLoaded();
            notificationModel.resetContentLoad();
            Future.delayed(const Duration(seconds: 1), () {
              if(mounted){
                setState(() {
                  readAllTable(notification: true);
                });
              }
            });
          }
          return Scaffold(
              body: isLoaded
                  ? Container(
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
                                  padding:
                                      const EdgeInsets.fromLTRB(18, 0, 0, 0),
                                  child: ElevatedButton.icon(
                                      style: ElevatedButton.styleFrom(
                                          backgroundColor: color.backgroundColor),
                                      onPressed: () async  {
                                        bool hasInternetAccess = await Domain().isHostReachable();
                                        if(hasInternetAccess){
                                          openAddTableDialog(PosTable());
                                        } else {
                                          Fluttertoast.showToast(msg: "Internet access required");
                                        }
                                      },
                                      icon: Icon(Icons.add),
                                      label: Text("Table")),
                                ),
                                SizedBox(
                                    width: MediaQuery.of(context).size.height > 500
                                        ? 500
                                        : 50),
                                Expanded(
                                  child: TextField(
                                    onChanged: (value) {
                                      searchTable(value);
                                    },
                                    decoration: InputDecoration(
                                      isDense: true,
                                      border: InputBorder.none,
                                      labelText: 'Search',
                                      focusedBorder: OutlineInputBorder(
                                        borderSide: const BorderSide(color: Colors.grey, width: 2.0),
                                        borderRadius: BorderRadius.circular(25.0),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: 20),
                          Expanded(
                            child: GridView.count(
                              shrinkWrap: true,
                              crossAxisCount: MediaQuery.of(context).size.height > 500 ? 5 : 3,
                              children: List.generate(
                                  //this is the total number of cards
                                  tableList.length, (index) {
                                // tableList[index].seats == 2;
                                return Card(
                                  color: tableList[index].status != 0 && MediaQuery.of(context).size.height < 500
                                      ? toColor(tableList[index].card_color!)
                                      : Colors.white,
                                  shape: tableList[index].isSelected
                                      ? new RoundedRectangleBorder(
                                          side: new BorderSide(
                                              color: color.backgroundColor, width: 3.0),
                                          borderRadius:
                                              BorderRadius.circular(4.0))
                                      : new RoundedRectangleBorder(
                                          side: new BorderSide(
                                              color: Colors.white, width: 3.0),
                                          borderRadius:
                                              BorderRadius.circular(4.0)),
                                  elevation: 5,
                                  child: InkWell(
                                    splashColor: Colors.blue.withAlpha(30),
                                    onDoubleTap: () {
                                      if (tableList[index].status != 1) {
                                        openAddTableDialog(tableList[index]);
                                      } else {
                                        openChangeTableDialog(tableList[index], cart);
                                      }
                                    },
                                    onTap: () async {
                                      await readSpecificTableDetail(tableList[index]);
                                      if (this.productDetailLoaded) {
                                        if (tableList[index].status == 1) {
                                          // table in use (colored)
                                          for (int i = 0; i < tableList.length; i++) {
                                            if (tableList[index].group == tableList[i].group) {
                                              if (tableList[i].isSelected == false) {
                                                tableList[i].isSelected = true;
                                              } else if (tableList[i].isSelected == true) {
                                                if (tableList[index].group == tableList[i].group) {
                                                  setState(() {
                                                    //removeFromCart(cart, tableList[index]);
                                                    tableList[i].isSelected = false;
                                                    //print('table list: ${tableList[i].number}');
                                                    //cart.removeSpecificTable(tableList[i]);
                                                  });
                                                } else {
                                                  setState(() {
                                                    //removeFromCart(cart, tableList[index]);
                                                    tableList[i].isSelected = false;
                                                    //cart.removeSpecificTable(tableList[index]);
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
                                              cart.removePromotion();
                                              cart.removeSpecificTable(tableList[j]);
                                            }
                                          }
                                          Fluttertoast.showToast(backgroundColor: Color(0xFF07F107), msg: "Table not in use");
                                        }
                                        if (tableList[index].status == 1 && tableList[index].isSelected == true) {
                                          //await readSpecificTableDetail(tableList[index]);
                                          addToCart(cart, tableList[index]);
                                        } else {
                                          removeFromCart(cart, tableList[index]);
                                        }
                                      }
                                    },
                                    child: Container(
                                      margin: MediaQuery.of(context).size.height > 500 ? EdgeInsets.all(2) : EdgeInsets.all(0),
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          // tableList[index].group != null && MediaQuery.of(context).size.height > 500
                                          //     ? Expanded(
                                          //         child: Text(
                                          //         "Group: ${tableList[index].group}",
                                          //         style:
                                          //             TextStyle(fontSize: 18),
                                          //       ))
                                          //     : MediaQuery.of(context).size.height > 500
                                          //         ? Expanded(child: Text(''))
                                          //         : Container(height: 10),
                                          Container(
                                            margin: MediaQuery.of(context).size.height > 500
                                                ? EdgeInsets.fromLTRB(0, 5, 0, 5)
                                                : null,
                                            height: MediaQuery.of(context).size.height < 500
                                                ? 100
                                                : MediaQuery.of(context).size.height < 700
                                                ? MediaQuery.of(context).size.height / 6.5
                                                    : MediaQuery.of(context).size.height / 5.5,
                                            child: Stack(
                                              children: [
                                                Visibility(
                                                  visible: tableList[index].group != null && MediaQuery.of(context).size.height > 500  ? true : false,
                                                  child: Container(
                                                      alignment: Alignment.topCenter,
                                                      child: Container(
                                                        padding: EdgeInsets.only(right: 5.0, left: 5.0),
                                                        decoration: BoxDecoration(
                                                            color: tableList[index].group != null && MediaQuery.of(context).size.height > 500
                                                                ?
                                                            toColor(tableList[index].card_color!)
                                                                :
                                                            Colors.white,
                                                            borderRadius: BorderRadius.circular(5.0)
                                                        ),
                                                        child: Text(
                                                          "Group: ${tableList[index].group}",
                                                          style:
                                                          TextStyle(fontSize: 18, color: fontColor(posTable: tableList[index])),
                                                        ),
                                                      )),
                                                ),
                                                tableList[index].seats == '2'
                                                    ?
                                                Container(
                                                  alignment: Alignment.center,

                                                  child: Image.asset("drawable/two-seat.jpg")
                                                )
                                                    :
                                                tableList[index].seats == '4'
                                                    ?
                                                Container(
                                                    alignment: Alignment.center,
                                                    child: Image.asset("drawable/four-seat.jpg")
                                                )
                                                    :
                                                tableList[index].seats == '6'
                                                    ?
                                                Container(
                                                    alignment: Alignment.center,
                                                    child: Image.asset("drawable/six-seat.jpg")
                                                )
                                                    :
                                                Container(),
                                                // Ink.image(
                                                //   image: tableList[index].seats == '2'
                                                //       ? FileImage(File('data/user/0/com.example.pos_system/files/assets/img/two-seat.jpg'))
                                                //   // NetworkImage(
                                                //   //         "https://www.hometown.in/media/cms/icon/Two-Seater-Dining-Sets.png")
                                                //       : tableList[index].seats == '4'
                                                //           ? FileImage(File('data/user/0/com.example.pos_system/files/assets/img/four-seat.jpg'))
                                                //   // NetworkImage(
                                                //   //             "https://www.hometown.in/media/cms/icon/Four-Seater-Dining-Sets.png")
                                                //           : tableList[index].seats == '6'
                                                //               ? FileImage(File('data/user/0/com.example.pos_system/files/assets/img/six-seat.jpg'))
                                                //   // NetworkImage(
                                                //   //                 "https://www.hometown.in/media/cms/icon/Six-Seater-Dining-Sets.png")
                                                //               : FileImage(File('data/user/0/com.example.pos_system/files/assets/img/duitNow.jpg')),
                                                //   // NetworkImage(
                                                //   //                 "https://png.pngtree.com/png-vector/20190820/ourmid/pngtree-no-image-vector-illustration-isolated-png-image_1694547.jpg"),
                                                //   fit: BoxFit.cover,
                                                // ),
                                                Container(
                                                    alignment: Alignment.center,
                                                    child: Text("#" + tableList[index].number!)),
                                                Visibility(
                                                  visible: MediaQuery.of(context).size.height > 500 ? true : false,
                                                  child: Container(
                                                      alignment: Alignment.bottomCenter,
                                                      child: Text(
                                                          "RM ${tableList[index].total_Amount.toStringAsFixed(2)}",
                                                          style: TextStyle(fontSize: 18))),
                                                ),

                                              ],
                                            ),
                                          ),
                                          MediaQuery.of(context).size.height > 500 ? Container(height: 10) : Container(),
                                          // tableList[index].status == 1 ?
                                          // Expanded(
                                          //     child: Text(
                                          //       "RM ${tableList[index].total_Amount.toStringAsFixed(2)}",
                                          //       style: TextStyle(fontSize: 18)),
                                          // ) :
                                          //     Expanded
                                          //       (child: Text(''))
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              }),
                            ),
                          )
                        ],
                      ),
                    )
                  : CustomProgressBar());
        });
      });
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
                    allTableList: tableList,
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

  Future<Future<Object?>> openChangeTableDialog(PosTable posTable, CartModel cartModel) async {
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
                  callBack: () {
                    readAllTable();
                    cartModel.initialLoad();
                  },
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

  readAllPrinters() async {
    printerList = await PrintReceipt().readAllPrinters();
  }

  readAllTable({model, notification}) async {
    if(notification == null){
      isLoaded = false;
    }
    if (model != null) {
      model.changeContent2(false);
    }

    List<PosTable> data = await PosDatabase.instance.readAllTable();

    tableList = List.from(data);
    await readAllTableGroup();
    if(mounted){
      setState(() {
        isLoaded = true;
      });
    }
  }

  readAllTableGroup() async {
    priceSST = 0.0;
    priceServeTax = 0.0;

    bool hasTableInUse = tableList.any((item) => item.status == 1);
    if(hasTableInUse){
      for (int i = 0; i < tableList.length; i++) {
        if(tableList[i].status == 1){
          List<TableUseDetail> tableUseDetailData = await PosDatabase.instance.readSpecificInUsedTableUseDetail(tableList[i].table_sqlite_id!);
          if (tableUseDetailData.isNotEmpty) {
            List<OrderCache> data = await PosDatabase.instance.readTableOrderCache(tableUseDetailData[0].table_use_key!);
            if(data.isNotEmpty){
              tableList[i].group = data[0].table_use_sqlite_id;
              tableList[i].card_color = data[0].card_color;
              //tableList[i].total_Amount = double.parse(data[0].total_amount!);

              for(int j = 0; j < data.length; j++){
                tableList[i].total_Amount += double.parse(data[j].total_amount!);
              }
            }
          }
        }
      }
    }
  }

  readSpecificTableDetail(PosTable posTable) async {
    orderDetailList.clear();
    orderCacheList.clear();

    //Get specific table use detail
    List<TableUseDetail> tableUseDetailData = await PosDatabase.instance.readSpecificInUsedTableUseDetail(posTable.table_sqlite_id!);
    if (tableUseDetailData.isNotEmpty) {
      //Get all order table cache
      List<OrderCache> data = await PosDatabase.instance.readTableOrderCache(tableUseDetailData[0].table_use_key!);

      //loop all table order cache
      for (int i = 0; i < data.length; i++) {
        if (!orderCacheList.contains(data)) {
          orderCacheList = List.from(data);
        }
        //Get all order detail based on order cache id
        //print('order cache key: ${data[i].order_cache_key!}');
        List<OrderDetail> detailData = await PosDatabase.instance.readTableOrderDetail(data[i].order_cache_key!);
        //print('order detail length 2 : ${detailData.length}');
        //add all order detail from db
        if (!orderDetailList.contains(detailData)) {
          orderDetailList..addAll(detailData);
        }
      }
    }

    //loop all order detail
    for (int k = 0; k < orderDetailList.length; k++) {
      //Get data from branch link product
      List<BranchLinkProduct> result = await PosDatabase.instance.readSpecificBranchLinkProduct(orderDetailList[k].branch_link_product_sqlite_id!);

      //Get product category
      List<Product> productResult = await PosDatabase.instance.readSpecificProductCategory(result[0].product_id!);
      orderDetailList[k].product_category_id = productResult[0].category_id;

      if (result[0].has_variant == '1') {
        //Get product variant
        List<BranchLinkProduct> variant = await PosDatabase.instance.readBranchLinkProductVariant(orderDetailList[k].branch_link_product_sqlite_id!);
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
              variant_item_id: int.parse(productVariantDetail[v].variant_item_id!),
              variant_group_id: variantItemDetail[0].variant_group_id,
              name: variant[0].variant_name,
              isSelected: true));
          productVariantDetail.clear();
        }
      }

      //check product modifier
      List<ModifierLinkProduct> productMod = await PosDatabase.instance.readProductModifier(result[0].product_sqlite_id!);
      if (productMod.isNotEmpty) {
        orderDetailList[k].hasModifier = true;
        await getOrderModifierDetail(orderDetailList[k]);
      }

      // if (orderDetailList[k].hasModifier == true) {
      //   //Get order modifier detail
      //   gerOrderModifierDetail(orderDetailList[k]);
      //   // List<OrderModifierDetail> modDetail = await PosDatabase.instance.readOrderModifierDetail(orderDetailList[k].order_detail_sqlite_id.toString());
      //   // if (modDetail.length > 0) {
      //   //   orderDetailList[k].modifierItem.clear();
      //   //   for (int m = 0; m < modDetail.length; m++) {
      //   //     // print('mod detail length: ${modDetail.length}');
      //   //     if (!orderDetailList[k].modifierItem.contains(modDetail[m].mod_group_id!)) {
      //   //       orderDetailList[k].modifierItem.add(ModifierItem(
      //   //           mod_group_id: modDetail[m].mod_group_id!,
      //   //           mod_item_id: int.parse(modDetail[m].mod_item_id!),
      //   //           name: modDetail[m].modifier_name!));
      //   //       orderDetailList[k].mod_group_id.add(modDetail[m].mod_group_id!);
      //   //       orderDetailList[k].mod_item_id = modDetail[m].mod_item_id;
      //   //     }
      //   //   }
      //   // }
      // }
    }
    if(mounted){
      setState(() {
        productDetailLoaded = true;
      });
    }
  }

  getOrderModifierDetail(OrderDetail orderDetail) async {
    List<OrderModifierDetail> modDetail = await PosDatabase.instance.readOrderModifierDetail(orderDetail.order_detail_sqlite_id.toString());
    if (modDetail.isNotEmpty) {
      orderDetail.modifierItem.clear();
      for (int m = 0; m < modDetail.length; m++) {
        // print('mod detail length: ${modDetail.length}');
        if (!orderDetail.modifierItem.contains(modDetail[m].mod_group_id!)) {
          orderDetail.modifierItem.add(ModifierItem(
              mod_group_id: modDetail[m].mod_group_id!,
              mod_item_id: int.parse(modDetail[m].mod_item_id!),
              name: modDetail[m].modifier_name!));
          orderDetail.mod_group_id.add(modDetail[m].mod_group_id!);
          orderDetail.mod_item_id = modDetail[m].mod_item_id;
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
    var value;
    List<TableUseDetail> tableUseDetailList = [];
    List<cartProductItem> itemList = [];
    var detailLength = orderDetailList.length;
    //print('tb order detail length: ${detailLength}');
    for (int i = 0; i < detailLength; i++) {
      value = cartProductItem(
          branch_link_product_sqlite_id: orderDetailList[i].branch_link_product_sqlite_id!,
          product_name: orderDetailList[i].productName!,
          category_id: orderDetailList[i].product_category_id!,
          price: orderDetailList[i].price!,
          quantity: int.parse(orderDetailList[i].quantity!),
          checkedModifierItem: [],
          modifier: getModifierGroupItem(orderDetailList[i]),
          variant: getVariantGroupItem(orderDetailList[i]),
          remark: orderDetailList[i].remark!,
          status: 0,
          order_cache_sqlite_id: orderDetailList[i].order_cache_sqlite_id,
          order_cache_key: orderDetailList[i].order_cache_key,
          category_sqlite_id: orderDetailList[i].category_sqlite_id,
          order_detail_sqlite_id: orderDetailList[i].order_detail_sqlite_id.toString(),
          base_price: orderDetailList[i].original_price,
          refColor: Colors.black,
      );
      cart.addItem(value);
    }
    var cacheLength = orderCacheList.length;
    for (int j = 0; j < cacheLength; j++) {
      //Get specific table use detail
      List<TableUseDetail> tableUseDetailData = await PosDatabase.instance
          .readAllTableUseDetail(orderCacheList[j].table_use_sqlite_id!);
      tableUseDetailList = List.from(tableUseDetailData);
    }
    var length = tableUseDetailList.length;
    for (int k = 0; k < length; k++) {
      List<PosTable> tableData = await PosDatabase.instance.readSpecificTable(tableUseDetailList[k].table_sqlite_id!);
      cart.addTable(tableData[0]);
    }
    //cart.addAllItem(cartItemList: itemList);
  }

  removeFromCart(CartModel cart, PosTable posTable) async {
    var value;
    List<TableUseDetail> tableUseDetailList = [];
    //await readSpecificTableDetail(posTable);
    if (this.productDetailLoaded) {
      var detailLength = orderDetailList.length;
      for (int i = 0; i < detailLength; i++) {
        value = cartProductItem(
            branch_link_product_sqlite_id: orderDetailList[i].branch_link_product_sqlite_id!,
            product_name: orderDetailList[i].productName!,
            category_id: orderDetailList[i].product_category_id!,
            price: orderDetailList[i].price!,
            quantity: int.parse(orderDetailList[i].quantity!),
            modifier: getModifierGroupItem(orderDetailList[i]),
            variant: getVariantGroupItem(orderDetailList[i]),
            remark: orderDetailList[i].remark!,
            status: 0,
            order_cache_sqlite_id: orderDetailList[i].order_cache_sqlite_id,
            category_sqlite_id: orderDetailList[i].category_sqlite_id,
            order_detail_sqlite_id: orderDetailList[i].order_detail_sqlite_id.toString(),
            refColor: toColor(posTable.card_color!),
        );
        cart.removeSpecificItem(value);
        cart.removePromotion();
      }
      var cacheLength = orderCacheList.length;
      for (int j = 0; j < cacheLength; j++) {
        //Get specific table use detail
        List<TableUseDetail> tableUseDetailData = await PosDatabase.instance.readAllTableUseDetail(orderCacheList[j].table_use_sqlite_id!);
        tableUseDetailList = tableUseDetailData;
      }
      var length = tableUseDetailList.length;
      for (int k = 0; k < length; k++) {
        List<PosTable> tableData = await PosDatabase.instance.readSpecificTable(tableUseDetailList[k].table_sqlite_id!);
        cart.removeSpecificTable(tableData[0]);
        //cart.addTable(tableData[0]);
      }
    }
  }
}
