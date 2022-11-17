import 'package:flutter/material.dart';
import 'package:pos_system/database/pos_database.dart';
import 'package:pos_system/object/order_cache.dart';
import 'package:pos_system/object/order_detail.dart';
import 'package:pos_system/page/progress_bar.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../notifier/cart_notifier.dart';
import '../../notifier/theme_color.dart';
import '../../object/branch_link_product.dart';
import '../../object/cart_product.dart';
import '../../object/modifier_group.dart';
import '../../object/modifier_item.dart';
import '../../object/order.dart';
import '../../object/product.dart';
import '../../object/table.dart';
import '../../object/table_use_detail.dart';
import '../../object/variant_group.dart';

class ReceiptMenu extends StatefulWidget {
  const ReceiptMenu({Key? key}) : super(key: key);

  @override
  State<ReceiptMenu> createState() => _ReceiptMenuState();
}

class _ReceiptMenuState extends State<ReceiptMenu> {
  List<Order> paidOrderList = [];
  List<OrderDetail> orderDetailList = [];
  List<VariantGroup> variantGroup = [];
  List<ModifierGroup> modifierGroup = [];
  OrderCache? orderCache;
  bool _isLoaded = false;
  @override
  void initState() {
    super.initState();
    readPaidOrder();
  }
  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeColor>(builder: (context, ThemeColor color, child) {
      return  Consumer<CartModel>(builder: (context, CartModel cart, child) {
        return Scaffold(
          body: _isLoaded ?
          Container(
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
                Expanded(
                    child: ListView.builder(
                    itemCount: paidOrderList.length,
                    itemBuilder: (BuildContext context,int index){
                      return Card(
                        elevation: 5,
                        shape: paidOrderList[index].isSelected
                            ? new RoundedRectangleBorder(
                            side: new BorderSide(
                                color: color.backgroundColor, width: 3.0),
                            borderRadius: BorderRadius.circular(4.0))
                            : new RoundedRectangleBorder(
                            side: new BorderSide(
                                color: Colors.white, width: 3.0),
                            borderRadius: BorderRadius.circular(4.0)),
                        margin: EdgeInsets.symmetric(horizontal: 10.0, vertical: 6.0),
                        child: ListTile(
                          title: Text('RM${paidOrderList[index].final_amount}'),
                          leading: CircleAvatar(backgroundColor: Colors.grey.shade200,child: Icon(Icons.receipt, color: Colors.grey,)),
                          subtitle: Text('close by: ${paidOrderList[index].close_by}'),
                          trailing: Text('Invoice ${paidOrderList[index].order_sqlite_id}'),
                          onTap: () async {
                            if(paidOrderList[index].isSelected == false){
                              //reset other selected order
                              for(int i = 0; i < paidOrderList.length; i++){
                                paidOrderList[i].isSelected = false;
                                cart.initialLoad();
                              }
                              paidOrderList[index].isSelected = true;
                              await getOrderCache(paidOrderList[index].order_sqlite_id.toString());
                              await getOrderDetail(orderCache!);
                              await addToCart(cart);
                            } else if(paidOrderList[index].isSelected == true) {
                              paidOrderList[index].isSelected = false;
                              cart.initialLoad();
                            }

                            // if(paidOrderList[index].isSelected = true){
                            //
                            // } else{
                            //   paidOrderList[index].isSelected = false;
                            // }
                          },
                        ),
                      );
                    })
                )
              ],
            ),
          ) : CustomProgressBar()
        );
      });
    });
  }

  addToCart(CartModel cart) async {
    print('add to cart called!');
    final prefs = await SharedPreferences.getInstance();
    final int? branch_id = prefs.getInt('branch_id');
    var value;
    List<TableUseDetail> tableUseDetailList = [];
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
          null,
          Colors.black
      );
      cart.addItem(value);
    }
    //Get specific table use detail
    List<TableUseDetail> tableUseDetailData = await PosDatabase.instance
        .readDeleteOnlyTableUseDetail(orderCache!.table_use_sqlite_id!);
    tableUseDetailList = List.from(tableUseDetailData);

    for (int k = 0; k < tableUseDetailList.length; k++) {
      List<PosTable> tableData = await PosDatabase.instance.readSpecificTable(
          branch_id!, tableUseDetailList[k].table_sqlite_id!);
      cart.addTable(tableData[0]);
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
    }

  }

  getOrderCache(String localOrderId) async {
    List<OrderCache> cacheData = await PosDatabase.instance.readSpecificOrderCacheByOrderID(localOrderId);
    if(cacheData.length > 0){
      orderCache = cacheData[0];
    }
  }

  readPaidOrder() async {
    List<Order> data = await PosDatabase.instance.readAllPaidOrder();
    if(data.length > 0){
      paidOrderList = List.from(data);
    }
    setState(() {
      _isLoaded = true;
    });
  }

}
