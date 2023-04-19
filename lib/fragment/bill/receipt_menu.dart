import 'package:flutter/material.dart';
import 'package:pos_system/database/pos_database.dart';
import 'package:pos_system/fragment/bill/refund_dialog.dart';
import 'package:pos_system/object/cart_payment.dart';
import 'package:pos_system/object/order_cache.dart';
import 'package:pos_system/object/order_detail.dart';
import 'package:pos_system/object/order_promotion_detail.dart';
import 'package:pos_system/object/order_tax_detail.dart';
import 'package:pos_system/object/promotion.dart';
import 'package:pos_system/page/progress_bar.dart';
import 'package:pos_system/utils/Utils.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../notifier/cart_notifier.dart';
import '../../notifier/theme_color.dart';
import '../../object/branch_link_product.dart';
import '../../object/cart_product.dart';
import '../../object/modifier_group.dart';
import '../../object/modifier_item.dart';
import '../../object/modifier_link_product.dart';
import '../../object/order.dart';
import '../../object/order_modifier_detail.dart';
import '../../object/product.dart';
import '../../object/product_variant.dart';
import '../../object/product_variant_detail.dart';
import '../../object/table.dart';
import '../../object/table_use_detail.dart';
import '../../object/variant_group.dart';
import '../../object/variant_item.dart';

class ReceiptMenu extends StatefulWidget {
  final CartModel cartModel;

  const ReceiptMenu({Key? key, required this.cartModel}) : super(key: key);

  @override
  State<ReceiptMenu> createState() => _ReceiptMenuState();
}

class _ReceiptMenuState extends State<ReceiptMenu> {
  List<Order> paidOrderList = [];
  List<OrderCache> orderCacheList = [];
  List<OrderDetail> orderDetailList = [];
  List<VariantGroup> variantGroup = [];
  List<ModifierGroup> modifierGroup = [];
  List<OrderTaxDetail> orderTaxList = [];
  List<OrderPromotionDetail> orderPromotionList = [];
  List<Order> allPaidOrder = [];
  String orderNumber = '';
  String selectedOption = 'Paid';
  List<String> optionList = ['Paid', 'Refunded'];
  bool _isLoaded = false;
  bool _readComplete = false;

  @override
  void initState() {
    super.initState();
    getOrder();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.cartModel.initialLoad();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeColor>(builder: (context, ThemeColor color, child) {
      return Consumer<CartModel>(builder: (context, CartModel cart, child) {
        if (cart.isInit) {
          getOrder(model: cart);
        }
        return LayoutBuilder(builder: (context, constraints) {
          if (constraints.maxWidth > 800) {
            return Scaffold(
                appBar: AppBar(
                  primary: false,
                  elevation: 0,
                  automaticallyImplyLeading: false,
                  title: Text(
                    "Receipt",
                    style: TextStyle(fontSize: 25),
                  ),
                  actions: [
                    Container(
                      padding: EdgeInsets.all(8),
                      width: MediaQuery.of(context).size.width / 5,
                      child: TextField(
                        maxLines: 1,
                        onChanged: (value) {
                          searchPaidOrders(value);
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
                    Container(
                      width: MediaQuery.of(context).size.width / 5,
                      child: DropdownButton<String>(
                        onChanged: (String? value) {
                          setState(() {
                            selectedOption = value!;
                            getOrder();
                            cart.initialLoad();
                            //readCashRecord();
                          });
                          //getCashRecord();
                        },
                        menuMaxHeight: 300,
                        value: selectedOption,
                        // Hide the default underline
                        underline: Container(),
                        icon: Icon(
                          Icons.arrow_drop_down,
                          color: color.backgroundColor,
                        ),
                        isExpanded: true,
                        // The list of options
                        items: optionList
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
                        selectedItemBuilder: (BuildContext context) => optionList.map((e) => Center(child: Text(e))).toList(),
                      ),
                    ),
                  ],
                ),
                resizeToAvoidBottomInset: false,
                body: _isLoaded
                    ? Container(
                        child: paidOrderList.isNotEmpty
                            ? ListView.builder(
                                shrinkWrap: true,
                                itemCount: paidOrderList.length,
                                itemBuilder: (BuildContext context, int index) {
                                  return Card(
                                    elevation: 5,
                                    shape: paidOrderList[index].isSelected
                                        ? new RoundedRectangleBorder(
                                            side: new BorderSide(color: color.backgroundColor, width: 3.0),
                                            borderRadius: BorderRadius.circular(4.0))
                                        : new RoundedRectangleBorder(
                                            side: new BorderSide(color: Colors.white, width: 3.0), borderRadius: BorderRadius.circular(4.0)),
                                    margin: EdgeInsets.symmetric(horizontal: 10.0, vertical: 6.0),
                                    child: ListTile(
                                      contentPadding: EdgeInsets.all(10),
                                      title: Text(
                                        'RM${paidOrderList[index].final_amount}',
                                        style: TextStyle(color: Colors.blueGrey, fontWeight: FontWeight.bold),
                                      ),
                                      leading: CircleAvatar(
                                          backgroundColor: Colors.grey.shade200,
                                          child: Icon(
                                            Icons.receipt,
                                            color: Colors.grey,
                                          )),
                                      subtitle: paidOrderList[index].payment_status == 1
                                          ? RichText(
                                              text: TextSpan(
                                                style: TextStyle(color: Colors.black, fontSize: 16),
                                                children: <TextSpan>[
                                                  TextSpan(
                                                    text: 'Date: ${Utils.formatDate(paidOrderList[index].created_at)}',
                                                    style: TextStyle(color: Colors.black87, fontSize: 14),
                                                  ),
                                                  TextSpan(text: '\n'),
                                                  TextSpan(
                                                      text: 'Close By: ${paidOrderList[index].close_by}',
                                                      style: TextStyle(color: Colors.grey, fontSize: 12)),
                                                ],
                                              ),
                                            )
                                          : Text('Refund By: ${paidOrderList[index].refund_by}\nRefund At: ${paidOrderList[index].refund_at}'),
                                      trailing: Text('Receipt No: ${paidOrderList[index].generateOrderNumber()}'),
                                      onTap: () async {
                                        if (paidOrderList[index].isSelected == false) {
                                          //reset other selected order
                                          for (int i = 0; i < paidOrderList.length; i++) {
                                            paidOrderList[i].isSelected = false;
                                            cart.initialLoad();
                                          }
                                          paidOrderList[index].isSelected = true;
                                          await getOrderDetail(paidOrderList[index]);
                                          //check is order refunded or not
                                          if (paidOrderList[index].payment_status == 1) {
                                            await addToCart(cart, orderCacheList, false);
                                          } else {
                                            await addToCart(cart, orderCacheList, true);
                                          }
                                          await callReadOrderTaxPromoDetail(paidOrderList[index]);
                                          if (_readComplete == true) {
                                            await paymentAddToCart(paidOrderList[index], cart);
                                          }
                                        } else if (paidOrderList[index].isSelected == true) {
                                          paidOrderList[index].isSelected = false;
                                          cart.initialLoad();
                                        }
                                      },
                                      onLongPress: paidOrderList[index].payment_status == 1
                                          ? () {
                                              openRefundDialog(paidOrderList[index], orderCacheList);
                                              print('refund bill');
                                            }
                                          : null,
                                    ),
                                  );
                                })
                            : Container(
                                alignment: Alignment.center,
                                height: MediaQuery.of(context).size.height / 1.7,
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.receipt_long, size: 36.0),
                                    Text('NO RECORD', style: TextStyle(fontSize: 24)),
                                  ],
                                ),
                              ),
                      )
                    : CustomProgressBar());
          } else {
            ///mobile view
            return Scaffold(
                body: _isLoaded
                    ? Container(
                        child: Column(
                          children: [
                            Padding(
                              padding: EdgeInsets.fromLTRB(11, 15, 11, 4),
                              child: Row(
                                children: [
                                  Text(
                                    "Receipt",
                                    style: TextStyle(fontSize: 25),
                                  ),
                                  SizedBox(width: 80),
                                  Expanded(
                                    child: TextField(
                                      onChanged: (value) {
                                        searchPaidOrders(value);
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
                                  Expanded(
                                    child: DropdownButton<String>(
                                      onChanged: (String? value) {
                                        setState(() {
                                          selectedOption = value!;
                                          getOrder();
                                          cart.initialLoad();
                                          //readCashRecord();
                                        });
                                        //getCashRecord();
                                      },
                                      menuMaxHeight: 300,
                                      value: selectedOption,
                                      // Hide the default underline
                                      underline: Container(),
                                      icon: Icon(
                                        Icons.arrow_drop_down,
                                        color: color.backgroundColor,
                                      ),
                                      isExpanded: true,
                                      // The list of options
                                      items: optionList
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
                                      selectedItemBuilder: (BuildContext context) => optionList.map((e) => Center(child: Text(e))).toList(),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Expanded(
                              child: paidOrderList.length > 0
                                  ? ListView.builder(
                                      itemCount: paidOrderList.length,
                                      itemBuilder: (BuildContext context, int index) {
                                        return Card(
                                          elevation: 5,
                                          shape: paidOrderList[index].isSelected
                                              ? new RoundedRectangleBorder(
                                                  side: new BorderSide(color: color.backgroundColor, width: 3.0),
                                                  borderRadius: BorderRadius.circular(4.0))
                                              : new RoundedRectangleBorder(
                                                  side: new BorderSide(color: Colors.white, width: 3.0), borderRadius: BorderRadius.circular(4.0)),
                                          margin: EdgeInsets.symmetric(horizontal: 10.0, vertical: 6.0),
                                          child: ListTile(
                                            isThreeLine: true,
                                            title: Text('RM${paidOrderList[index].final_amount}', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey),),
                                            leading: CircleAvatar(
                                                backgroundColor: Colors.grey.shade200,
                                                child: Icon(
                                                  Icons.receipt,
                                                  color: Colors.grey,
                                                )),
                                            subtitle: paidOrderList[index].payment_status == 1
                                                ? Text('Close By: ${paidOrderList[index].close_by}\nClose At: ${Utils.formatDate(paidOrderList[index].created_at)}')
                                                : Text('Refund By: ${paidOrderList[index].refund_by}\nRefund At: ${paidOrderList[index].refund_at}'),
                                            trailing: Text('Order: #${paidOrderList[index].order_number}'),
                                            onTap: () async {
                                              if (paidOrderList[index].isSelected == false) {
                                                //reset other selected order
                                                for (int i = 0; i < paidOrderList.length; i++) {
                                                  paidOrderList[i].isSelected = false;
                                                  cart.initialLoad();
                                                }
                                                paidOrderList[index].isSelected = true;
                                                await getOrderDetail(paidOrderList[index]);
                                                //check is order refunded or not
                                                if (paidOrderList[index].payment_status == 1) {
                                                  await addToCart(cart, orderCacheList, false);
                                                } else {
                                                  await addToCart(cart, orderCacheList, true);
                                                }
                                                await callReadOrderTaxPromoDetail(paidOrderList[index]);
                                                if (_readComplete == true) {
                                                  await paymentAddToCart(paidOrderList[index], cart);
                                                }
                                              } else if (paidOrderList[index].isSelected == true) {
                                                paidOrderList[index].isSelected = false;
                                                cart.initialLoad();
                                              }
                                            },
                                            onLongPress: paidOrderList[index].payment_status == 1
                                                ? () {
                                                    openRefundDialog(paidOrderList[index], orderCacheList);
                                                    print('refund bill');
                                                  }
                                                : null,
                                          ),
                                        );
                                      })
                                  : Container(
                                      alignment: Alignment.center,
                                      height: MediaQuery.of(context).size.height / 1.7,
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(Icons.receipt_long, size: 36.0),
                                          Text('NO RECORD', style: TextStyle(fontSize: 24)),
                                        ],
                                      ),
                                    ),
                            )
                          ],
                        ),
                      )
                    : CustomProgressBar());
          }
        });
      });
    });
  }

  Future<Future<Object?>> openRefundDialog(Order order, List<OrderCache> orderCacheList) async {
    return showGeneralDialog(
        barrierColor: Colors.black.withOpacity(0.5),
        transitionBuilder: (context, a1, a2, widget) {
          final curvedValue = Curves.easeInOutBack.transform(a1.value) - 1.0;
          return Transform(
            transform: Matrix4.translationValues(0.0, curvedValue * 200, 0.0),
            child: Opacity(
              opacity: a1.value,
              child: RefundDialog(callBack: () => getOrder(), order: order, orderCacheList: orderCacheList),
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

  paymentAddToCart(Order order, CartModel cart) {
    var value = cartPaymentDetail(
        order.order_sqlite_id.toString(),
        double.parse(order.subtotal!),
        double.parse(order.amount!),
        double.parse(order.rounding!),
        order.final_amount!,
        double.parse(order.payment_received!),
        double.parse(order.payment_change!),
        orderTaxList,
        orderPromotionList);

    cart.addPaymentDetail(value);
  }

  addToCart(CartModel cart, List<OrderCache> orderCacheList, bool isRefund) async {
    print('is refund: ${isRefund}');
    var value;
    List<TableUseDetail> tableUseDetailList = [];
    List<OrderCache> _uniqueOrderCacheList = [];
    for (int i = 0; i < orderDetailList.length; i++) {
      value = cartProductItem(
          orderDetailList[i].branch_link_product_sqlite_id!,
          orderDetailList[i].productName!,
          orderDetailList[i].product_category_id!,
          orderDetailList[i].price!,
          int.parse(orderDetailList[i].quantity!),
          getModifierGroupItem(orderDetailList[i]),
          getVariantGroupItem(orderDetailList[i]),
          orderDetailList[i].remark!,
          0,
          null,
          Colors.black,
          isRefund: isRefund);
      cart.addItem(value);
    }
    print('order cache list: ${orderCacheList.length}');
    List<String> _uniqueList = [];
    var _value;
    for (int j = 0; j < orderCacheList.length; j++) {
      //print('order cache list ${j+1}: ${orderCacheList[j].table_use_sqlite_id}');
      // if(_uniqueOrderCacheList.isEmpty){
      //   _uniqueOrderCacheList.add(orderCacheList[j]);
      // } else {
      //   for(int m = 0; m < _uniqueOrderCacheList.length; m++){
      //     print('table use id ${m+1}: ${_uniqueOrderCacheList[m].table_use_sqlite_id}');
      //     print('cache table use id ${m+1}: ${orderCacheList[j].table_use_sqlite_id}');
      //     if(_uniqueOrderCacheList[m].table_use_sqlite_id == orderCacheList[j].table_use_sqlite_id){
      //       break;
      //       //_uniqueOrderCacheList.removeAt(j);
      //       //_uniqueOrderCacheList.add(orderCacheList[j]);
      //     } else {
      //       //_uniqueOrderCacheList.add(orderCacheList[j]);
      //     }
      //   }
      // }
      _uniqueList.add(orderCacheList[j].table_use_sqlite_id!);
      _value = _uniqueList.toSet().toList();
      //Get specific table use detail
      // List<TableUseDetail> tableUseDetailData = await PosDatabase.instance.readDeleteOnlyTableUseDetail(orderCacheList[j].table_use_sqlite_id!);
      // if(!tableUseDetailList.contains(tableUseDetailData)){
      //   tableUseDetailList.addAll(tableUseDetailData);
      // }
      //tableUseDetailList = List.from(tableUseDetailData);
      //add selected dining option
      if (orderCacheList[j].dining_id == '2') {
        cart.selectedOption = 'Take Away';
      } else if (orderCacheList[j].dining_id == '3') {
        cart.selectedOption = 'Delivery';
      } else {
        cart.selectedOption = 'Dine in';
      }
      print('cycle ${j + 1} finish');
    }
    //get all table use detail
    for (int m = 0; m < _value.length; m++) {
      List<TableUseDetail> tableUseDetailData = await PosDatabase.instance.readDeleteOnlyTableUseDetail(_value[m]!);
      if (!tableUseDetailList.contains(tableUseDetailData)) {
        tableUseDetailList.addAll(tableUseDetailData);
      }
    }
    //get table object add to cart
    for (int k = 0; k < tableUseDetailList.length; k++) {
      List<PosTable> tableData = await PosDatabase.instance.readSpecificTable(tableUseDetailList[k].table_sqlite_id!);
      if (cart.selectedTable.length > 0) {
        if (!cart.selectedTable.contains(tableData)) {
          cart.addTable(tableData[0]);
        }
      } else {
        cart.addTable(tableData[0]);
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
        modifierGroup.add(ModifierGroup(modifierChild: [], mod_group_id: int.parse(orderDetail.mod_group_id[j])));
        position = modifierGroup.length - 1;
      }

      for (int k = 0; k < temp.length; k++) {
        if (modifierGroup[position].mod_group_id.toString() == temp[k].mod_group_id) {
          modItemChild.add(
              ModifierItem(mod_group_id: orderDetail.mod_group_id[position], mod_item_id: temp[k].mod_item_id, name: temp[k].name, isChecked: true));
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
      variantGroup.add(VariantGroup(child: orderDetail.variantItem, variant_group_id: int.parse(orderDetail.variantItem[i].variant_group_id!)));
    }
    //print('variant group length: ${variantGroup.length}');
    return variantGroup;
  }

  getOrderDetail(Order order) async {
    orderCacheList.clear();
    List<OrderDetail> _cacheOrderDetail = [];
    await getOrderCache(order.order_sqlite_id.toString());

    for (int i = 0; i < orderCacheList.length; i++) {
      List<OrderDetail> detailData =
          await PosDatabase.instance.readSpecificOrderDetailByOrderCacheId(orderCacheList[i].order_cache_sqlite_id.toString());
      if (!_cacheOrderDetail.contains(detailData)) {
        _cacheOrderDetail.addAll(detailData);
      }
    }

    if (_cacheOrderDetail.length > 0) {
      orderDetailList = List.from(_cacheOrderDetail);
    }
    for (int k = 0; k < orderDetailList.length; k++) {
      List<BranchLinkProduct> result = await PosDatabase.instance.readSpecificBranchLinkProduct(orderDetailList[k].branch_link_product_sqlite_id!);
      //Get product category
      List<Product> productResult = await PosDatabase.instance.readSpecificProductCategory(result[0].product_id!);
      orderDetailList[k].product_category_id = productResult[0].category_id;
      if (orderDetailList[k].has_variant == '1') {
        List<BranchLinkProduct> variant = await PosDatabase.instance.readBranchLinkProductVariant(orderDetailList[k].branch_link_product_sqlite_id!);
        orderDetailList[k].productVariant =
            ProductVariant(product_variant_id: int.parse(variant[0].product_variant_id!), variant_name: variant[0].variant_name);

        //Get product variant detail
        List<ProductVariantDetail> productVariantDetail = await PosDatabase.instance.readProductVariantDetail(variant[0].product_variant_id!);
        orderDetailList[k].variantItem.clear();
        for (int v = 0; v < productVariantDetail.length; v++) {
          //Get product variant item
          List<VariantItem> variantItemDetail =
              await PosDatabase.instance.readProductVariantItemByVariantID(productVariantDetail[v].variant_item_id!);
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
      if (productMod.length > 0) {
        orderDetailList[k].hasModifier = true;
      }

      if (orderDetailList[k].hasModifier == true) {
        //Get order modifier detail
        List<OrderModifierDetail> modDetail =
            await PosDatabase.instance.readOrderModifierDetail(orderDetailList[k].order_detail_sqlite_id.toString());
        if (modDetail.length > 0) {
          orderDetailList[k].modifierItem.clear();
          for (int m = 0; m < modDetail.length; m++) {
            // print('mod detail length: ${modDetail.length}');
            if (!orderDetailList[k].modifierItem.contains(modDetail[m].mod_group_id!)) {
              orderDetailList[k].modifierItem.add(ModifierItem(
                  mod_group_id: modDetail[m].mod_group_id!, mod_item_id: int.parse(modDetail[m].mod_item_id!), name: modDetail[m].modifier_name!));
              orderDetailList[k].mod_group_id.add(modDetail[m].mod_group_id!);
              orderDetailList[k].mod_item_id = modDetail[m].mod_item_id;
            }
          }
        }
      }
    }
  }

  getOrderCache(String localOrderId) async {
    List<OrderCache> cacheData = await PosDatabase.instance.readSpecificOrderCacheByOrderID(localOrderId);
    if (cacheData.length > 0) {
      orderCacheList = List.from(cacheData);
    }
  }

  getOrder({model}) async {
    if (model != null) {
      model.setInit(false);
    }
    _isLoaded = false;
    paidOrderList = [];
    if (selectedOption == 'Paid') {
      List<Order> data = await PosDatabase.instance.readAllPaidOrder();
      if (data.length > 0) {
        paidOrderList = List.from(data);
      }
    } else {
      List<Order> data = await PosDatabase.instance.readAllRefundOrder();
      if (data.isNotEmpty) {
        paidOrderList = List.from(data);
      }
    }

    setState(() {
      _isLoaded = true;
    });
  }

  callReadOrderTaxPromoDetail(Order order) async {
    await readPaidOrderTaxDetail(order);
    await readPaidOrderPromotionDetail(order);
    setState(() {
      _readComplete = true;
    });
  }

  readPaidOrderTaxDetail(Order order) async {
    List<OrderTaxDetail> data = await PosDatabase.instance.readSpecificOrderTaxDetail(order.order_sqlite_id.toString());
    orderTaxList = List.from(data);
  }

  readPaidOrderPromotionDetail(Order order) async {
    List<OrderPromotionDetail> detailData = await PosDatabase.instance.readSpecificOrderPromotionDetail(order.order_sqlite_id.toString());
    orderPromotionList = List.from(detailData);
  }

  searchPaidOrders(String text) async {
    if (selectedOption == 'Paid') {
      List<Order> data = await PosDatabase.instance.searchPaidReceipt(text);
      setState(() {
        paidOrderList = data;
      });
    } else {
      List<Order> data = await PosDatabase.instance.searchRefundReceipt(text);
      setState(() {
        paidOrderList = data;
      });
    }
  }
}
