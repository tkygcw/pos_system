import 'dart:async';

import 'package:flutter/material.dart';
import 'package:pos_system/database/domain.dart';
import 'package:pos_system/fragment/table/remove_detail_dialog.dart';
import 'package:pos_system/notifier/cart_notifier.dart';
import 'package:pos_system/object/branch_link_product.dart';
import 'package:pos_system/object/order_detail.dart';
import 'package:pos_system/object/order_modifier_detail.dart';
import 'package:pos_system/object/product.dart';
import 'package:pos_system/page/progress_bar.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../database/pos_database.dart';
import '../../notifier/theme_color.dart';
import '../../object/cart_product.dart';
import '../../object/modifier_group.dart';
import '../../object/modifier_item.dart';
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
  List<OrderDetail> orderDetailList = [];
  List<BranchLinkProduct> branchProductList = [];
  List<VariantGroup> variantGroup = [];
  List<ModifierGroup> modifierGroup = [];
  String productName = '';
  double totalOrderAmount = 0.0;
  bool isLoad = false;

  @override
  void initState() {
    // TODO: implement initState
    controller = StreamController();
    readSpecificTableDetail();
    super.initState();
  }

  @override
  void dispose() {
    // TODO: implement dispose
    controller.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeColor>(builder: (context, ThemeColor color, child) {
      return Consumer<CartModel>(builder: (context, CartModel cart, child) {
        return AlertDialog(
          title: Text("table ${widget.object.number} detail"),
          content: isLoad
              ? StreamBuilder(builder: (context, snapshot) {
                  return Container(
                      width: 350.0,
                      height: 450.0,
                      child: Column(children: [
                        Expanded(
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
                                    child: SizedBox(
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
                                                      text: "RM" +
                                                          "${orderDetailList[index].total_amount}" +
                                                          " (RM${orderDetailList[index].base_price})",
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
                                                orderDetailList[index]
                                                        .modifier_name
                                                        .isNotEmpty
                                                    ? Text(
                                                        "Add on: ${reformatModifierDetail(orderDetailList[index].modifier_name)}")
                                                    : Container(),
                                                orderDetailList[index]
                                                            .variant_name !=
                                                        'no_variant'
                                                    ? Text(
                                                        "Variant: ${reformatVariantDetail(orderDetailList[index].variant_name)}")
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
                                                    IconButton(
                                                        hoverColor:
                                                            Colors.transparent,
                                                        icon:
                                                            Icon(Icons.remove),
                                                        onPressed: () {
                                                          orderDetailList[index]
                                                                      .quantity !=
                                                                  '1'
                                                              ? setState(() {
                                                                  orderDetailList[
                                                                          index]
                                                                      .quantity = (int.parse(
                                                                              orderDetailList[index].quantity!) -
                                                                          1)
                                                                      .toString();
                                                                })
                                                              : null;
                                                        }),
                                                    Text(
                                                        '${orderDetailList[index].quantity}'),
                                                    IconButton(
                                                        hoverColor:
                                                            Colors.transparent,
                                                        icon: Icon(Icons.add),
                                                        onPressed: () {
                                                          setState(() {
                                                            orderDetailList[
                                                                        index]
                                                                    .quantity =
                                                                (int.parse(orderDetailList[index]
                                                                            .quantity!) +
                                                                        1)
                                                                    .toString();
                                                          });
                                                          controller
                                                              .add('refresh');
                                                        })
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ]),
                                    ),
                                  );
                                }),
                          ),
                        ),
                        Expanded(
                          child: ListView(
                            children: [
                              ListTile(
                                title: Text("Total",
                                    style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold)),
                                trailing: Text("RM${getAllTotalAmount()}"),
                              ),
                              TextButton(
                                  onPressed: () => cart.removeAllCartItem(),
                                  child: Text('Clear cart item'))
                            ],
                          ),
                        )
                      ]));
                })
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
              onPressed: () {
                addToPaymentCart(cart);
                Navigator.of(context).pop();
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
    final prefs = await SharedPreferences.getInstance();
    final int? branch_id = prefs.getInt('branch_id');

    List<OrderCache> data = await PosDatabase.instance
        .readTableOrderCache(branch_id.toString(), widget.object.table_id!);
    for (int i = 0; i < data.length; i++) {
      List<OrderDetail> detailData = await PosDatabase.instance
          .readTableOrderDetail(data[i].order_cache_id.toString());

      for (int j = 0; j < detailData.length; j++) {
        orderDetailList += detailData;
      }

      for (int k = 0; k < orderDetailList.length; k++) {
        List<BranchLinkProduct> result = await PosDatabase.instance
            .readSpecificBranchLinkProduct(
                orderDetailList[k].branch_link_product_id!);
        orderDetailList[k].product_name = result[0].product_name!;
        orderDetailList[k].base_price = result[0].price!;

        List<Product> productResult = await PosDatabase.instance
            .readSpecificProductCategory(result[0].product_id!);
        orderDetailList[k].category_id = productResult[0].category_id;

        if (result[0].has_variant == '1') {
          List<BranchLinkProduct> variant = await PosDatabase.instance
              .readBranchLinkProductVariant(
                  orderDetailList[k].branch_link_product_id!);
          orderDetailList[k].variant_name = variant[0].variant_name!;
        } else {
          orderDetailList[k].variant_name = 'no_variant';
        }

        List<OrderModifierDetail> modDetail = await PosDatabase.instance
            .readOrderModifierDetail(
                orderDetailList[k].order_detail_id.toString());
        print('length: ${modDetail.length}');
        if (modDetail.length > 0) {
          orderDetailList[k].mod_group_id.clear();
          for (int m = 0; m < modDetail.length; m++) {
            if (!orderDetailList[k]
                .modifier_name
                .contains(modDetail[m].modifier_name!)) {
              orderDetailList[k].modifier_name.add(modDetail[m].modifier_name!);
              orderDetailList[k].mod_group_id.add(modDetail[m].mod_group_id!);
              orderDetailList[k].mod_item_id = modDetail[m].mod_item_id;
              print(
                  'readSpecificTableDetail mod group id: ${orderDetailList[k].mod_group_id}');
            }
          }
        }
      }
    }
    isLoad = true;
    if (!controller.isClosed) {
      controller.add('refresh');
    }
  }

  getAllTotalAmount() {
    totalOrderAmount = 0.0;
    for (int i = 0; i < orderDetailList.length; i++) {
      totalOrderAmount += double.parse(orderDetailList[i].total_amount!);
    }
    return totalOrderAmount.toStringAsFixed(2);
  }

  reformatModifierDetail(List<String> modList) {
    String result = '';
    result = modList.toString().replaceAll('[', '').replaceAll(']', '');
    return result;
  }

  reformatVariantDetail(String variantName) {
    String result = '';
    result = variantName.replaceAll('|', ',');
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

  getModifierGroupItem(OrderDetail orderDetail) {
    print('getModifierGroupItem called');
    modifierGroup = [];
    List<ModifierItem> modItemChild = [];

    for (int j = 0; j < orderDetail.mod_group_id.length; j++) {
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

      for (int k = 0; k < orderDetail.modifier_name.length; k++) {
        print(
            'orderDetailList[i].modifier_name.length: ${orderDetail.modifier_name.length}');

        modItemChild.add(ModifierItem(
            mod_group_id: orderDetail.mod_group_id[position],
            mod_item_id: int.parse(orderDetail.mod_item_id!),
            name: orderDetail.modifier_name[k],
            isChecked: true));
      }

      modifierGroup[position].modifierChild = modItemChild;
      print('modifierGroup[i].modifierChild: ${orderDetail.mod_group_id}');
    }

    return modifierGroup;
  }

  void addToPaymentCart(CartModel cart) async {
    var value;
    cart.removeAllCartItem();

    //get selected modifier

    for (int i = 0; i < orderDetailList.length; i++) {
      value = cartProductItem(
        orderDetailList[i].branch_link_product_id!,
        orderDetailList[i].product_name,
        orderDetailList[i].category_id!,
        orderDetailList[i].base_price,
        int.parse(orderDetailList[i].quantity!),
        getModifierGroupItem(orderDetailList[i]),
        variantGroup,
        orderDetailList[i].remark!,
      );
      cart.addItem(value);
    }
  }
}
