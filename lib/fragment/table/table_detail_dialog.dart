import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pos_system/object/branch_link_product.dart';
import 'package:pos_system/object/order.dart';
import 'package:pos_system/object/order_detail.dart';
import 'package:pos_system/object/order_modifier_detail.dart';
import 'package:pos_system/page/progress_bar.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../database/pos_database.dart';
import '../../notifier/theme_color.dart';
import '../../object/order_cache.dart';
import '../../object/table.dart';

class TableDetailDialog extends StatefulWidget {
  final PosTable object;

  const TableDetailDialog({Key? key, required this.object}) : super(key: key);

  @override
  State<TableDetailDialog> createState() => _TableDetailDialogState();
}

class _TableDetailDialogState extends State<TableDetailDialog> {
  late StreamController controller;
  List<OrderDetail> orderDetailList = [];
  List<BranchLinkProduct> branchProductList = [];
  String productName = '';
  double totalOrderAmount = 0.0;
  bool isLoad = false;


  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    controller = StreamController();
    readSpecificTableDetail();
  }

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
    controller.close();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeColor>(builder: (context, ThemeColor color, child) {
      return AlertDialog(
        title: Text("table ${widget.object.number} detail"),
        content: isLoad
            ? StreamBuilder(
              builder: (context, snapshot) {
                return Container(
                    width: 350.0,
                    height: 450.0,
                    child: Column(
                      children: [
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
                                        if (direction == DismissDirection.startToEnd) {

                                        }
                                        return null;
                                      },
                                      child: SizedBox(
                                        height: 85.0,
                                        child: Column(
                                          children: [
                                            Expanded(
                                              child: ListTile(
                                                hoverColor: Colors.transparent,
                                                onTap: () {},
                                                isThreeLine: true,
                                                title: RichText(
                                                  text: TextSpan(
                                                    children: <TextSpan>[
                                                      TextSpan(
                                                          text: "${orderDetailList[index].product_name}" + "\n",
                                                          style: TextStyle(
                                                            fontSize: 18,
                                                            color: color.backgroundColor,
                                                          )),
                                                      TextSpan(
                                                          text: "RM"+ "${orderDetailList[index].total_amount}",
                                                          style: TextStyle(
                                                            fontSize: 13,
                                                            color: color.backgroundColor,
                                                          )),
                                                    ],
                                                  ),
                                                ),
                                                subtitle: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    orderDetailList[index].modifier_name.isNotEmpty
                                                        ? Text("Add on: ${reformatModifierDetail(orderDetailList[index].modifier_name)}")
                                                    :Container(),
                                                    orderDetailList[index].variant_name != 'no_variant'
                                                        ? Text("Variant: ${reformatVariantDetail(orderDetailList[index].variant_name)}")
                                                    : Container(),
                                                    Text("${orderDetailList[index].remark}")
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
                                                            icon: Icon(Icons.remove),
                                                            onPressed: () {
                                                              orderDetailList[index].quantity != '1' ? setState((){
                                                                orderDetailList[index].quantity = (int.parse(orderDetailList[index].quantity!) - 1).toString();
                                                              })
                                                                  : null;
                                                            }),
                                                        Text('${orderDetailList[index].quantity}'),
                                                        IconButton(
                                                            hoverColor:
                                                            Colors.transparent,
                                                            icon: Icon(Icons.add),
                                                            onPressed: () {
                                                              setState(() {
                                                                orderDetailList[index].quantity = (int.parse(orderDetailList[index].quantity!) + 1).toString();
                                                              });
                                                              controller.add('refresh');
                                                            })
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ]
                                        ),
                                      ),
                                    );
                                  }),
                            ),
                        ),
                        Expanded(
                          child: ListView(
                              children: [
                                ListTile(
                                  title: Text("Total", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                  trailing: Text("RM${getAllTotalAmount()}"),
                                ),
                                TextButton(
                                  child: Text('Create order modifier detail'),
                                  onPressed: () {
                                  },
                                )
                              ],
                            ),

                        )
                      ]
                    )
                  );
              }
            )
            : CustomProgressBar(),
        actions: <Widget>[
          TextButton(
            child: Text('Close'),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
          TextButton(
            child: Text('Make payment'),
            onPressed: () {
              print('Product add to cart');
              Navigator.of(context).pop();
            },
          ),
        ],
      );
    });
  }

  readSpecificTableDetail() async {
    final prefs = await SharedPreferences.getInstance();
    final int? branch_id = prefs.getInt('branch_id');

    List<OrderCache> data = await PosDatabase.instance
        .readTableOrderCache(branch_id.toString(), widget.object.table_id!);
    for(int i = 0; i < data.length; i++) {
      List<OrderDetail> detailData = await PosDatabase.instance
          .readTableOrderDetail(data[i].order_cache_id.toString());

      for (int j = 0; j < detailData.length; j++) {
        orderDetailList += detailData;
      }

      for(int k =0; k < orderDetailList.length; k++){
        List<BranchLinkProduct> result = await PosDatabase.instance
            .readSpecificBranchLinkProduct(orderDetailList[k].branch_link_product_id!);
        orderDetailList[k].product_name = result[0].product_name!;

        if(result[0].has_variant == '1') {
          List<BranchLinkProduct> variant = await PosDatabase.instance.readBranchLinkProductVariant(orderDetailList[k].branch_link_product_id!);
          orderDetailList[k].variant_name = variant[0].variant_name!;
        } else{
          orderDetailList[k].variant_name = 'no_variant';
        }

        List<OrderModifierDetail> modDetail = await PosDatabase.instance.readOrderModifierDetail(orderDetailList[k].order_detail_id.toString());
        for(int m = 0; m < modDetail.length; m++){
          if(!orderDetailList[k].modifier_name.contains(modDetail[m].modifier_name!)){
            orderDetailList[k].modifier_name.add(modDetail[m].modifier_name!);
          }
        }
      }
    }
    isLoad = true;
    controller.add('refresh');

  }

  getAllTotalAmount(){
    totalOrderAmount = 0.0;
    for(int i = 0; i < orderDetailList.length; i++){
      totalOrderAmount +=  double.parse(orderDetailList[i].total_amount!);
    }
    return totalOrderAmount.toStringAsFixed(2);
  }

  reformatModifierDetail(List<String> modList){
    String result = '';
    result = modList.toString().replaceAll('[', '').replaceAll(']', '');
    return result;
  }
  
  reformatVariantDetail(String variantName) {
    String result = '';
    result = variantName.replaceAll('|', ',');
    return result;
  }

  // Future<Future<Object?>> openRemoveOrderDetailDialog() async {
  //   return showGeneralDialog(
  //       barrierColor: Colors.black.withOpacity(0.5),
  //       transitionBuilder: (context, a1, a2, widget) {
  //         final curvedValue = Curves.easeInOutBack.transform(a1.value) - 1.0;
  //         return Transform(
  //           transform: Matrix4.translationValues(0.0, curvedValue * 200, 0.0),
  //           child: Opacity(
  //             opacity: a1.value,
  //             child: CartRemoveDialog(cartItem: item),
  //           ),
  //         );
  //       },
  //       transitionDuration: Duration(milliseconds: 200),
  //       barrierDismissible: false,
  //       context: context,
  //       pageBuilder: (context, animation1, animation2) {
  //         // ignore: null_check_always_fails
  //         return null!;
  //       });
  // }

}
