import 'package:confirm_dialog/confirm_dialog.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:pos_system/object/order_detail.dart';
import 'package:pos_system/object/order_modifier_detail.dart';
import 'package:provider/provider.dart';

import '../../database/domain.dart';
import '../../database/pos_database.dart';
import '../../notifier/theme_color.dart';
import '../../object/order_cache.dart';
import '../../object/product_variant.dart';

class ViewOrderDialogPage extends StatefulWidget {
  final OrderCache? orderCache;

  const ViewOrderDialogPage({Key? key, this.orderCache}) : super(key: key);

  @override
  _ViewOrderDialogPageState createState() => _ViewOrderDialogPageState();
}

class _ViewOrderDialogPageState extends State<ViewOrderDialogPage> {
  List<OrderDetail> orderDetail = [];
  List<OrderModifierDetail> orderModifierDetail = [];
  List<ProductVariant> orderProductVariant = [];

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    getOrderDetail();
  }

  getOrderDetail() async {
    List<OrderDetail> data = await PosDatabase.instance
        .readTableOrderDetail(widget.orderCache!.order_cache_id.toString());
    for (int i = 0; i < data.length; i++) {
      ProductVariant? productVariantData = await PosDatabase.instance
          .readProductVariantSpecial(data[i].branch_link_product_id.toString());
      if (productVariantData!.product_variant_id.toString().isNotEmpty) {
        orderProductVariant.add(productVariantData);
      }
      OrderModifierDetail? detail = await PosDatabase.instance
          .readOrderModifierDetailOne(data[i].order_detail_id.toString());
      if (detail!.order_modifier_detail_id.toString().isNotEmpty) {
        orderModifierDetail.add(detail);
      }
    }
    setState(() {
      orderDetail = data;
    });
    print(orderProductVariant);
  }

  deleteWholeOrder() async {
    Map responseDeleteOrderCache = await Domain().deleteOrderCache(widget.orderCache!.order_cache_id.toString());
    if(responseDeleteOrderCache['status']=='1'){
      Map responseDeleteDetail = await Domain().deleteOrderDetail(widget.orderCache!.order_cache_id.toString());
      if(responseDeleteDetail['status'] == '1'){
        List<OrderDetail> data = await PosDatabase.instance.readTableOrderDetail(widget.orderCache!.order_cache_id.toString());
        for(int i = 0; i < data.length; i++){
          Map responseDeleteOrderModifierDetail = await Domain().deleteOrderModifierDetail(data[i].order_detail_id);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeColor>(builder: (context, ThemeColor color, child) {
      return AlertDialog(
        title: Row(
          children: [
            Text(
              "Order detail",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            Spacer(),
            IconButton(
              icon: const Icon(Icons.delete_outlined),
              color: Colors.red,
              onPressed: () async {
                if (await confirm(
                  context,
                  title: const Text('Confirm'),
                  content: const Text('Would you like to remove?'),
                  textOK: const Text('Yes'),
                  textCancel: const Text('No'),
                )) {
                  return deleteWholeOrder();
                }
                // deleteCategory();
              },
            ),
          ],
        ),
        content: Container(
          height: 450.0, // Change as per your requirement
          width: 450.0,
          child: Column(
            children: [
              Expanded(
                child: ListView.builder(
                  itemCount: orderDetail.length,
                  itemBuilder: (context, index) {
                    return Card(
                      child: InkWell(
                        onTap: () {
                          // openViewOrderDialog(orderCacheList[index]);
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: ListTile(
                              trailing: Text(
                                'X' + orderDetail[index].quantity.toString(),
                                style: TextStyle(fontSize: 20),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  orderProductVariant[0].product_variant_id !=
                                          null
                                      ? ListView.builder(
                                          shrinkWrap: true,
                                          itemCount: orderProductVariant.length,
                                          itemBuilder: (context, index) {
                                            return Text(
                                              '+ ' +
                                                  orderProductVariant[index]
                                                      .variant_name!,
                                              style: TextStyle(fontSize: 16),
                                            );
                                          })
                                      : Container(),
                                  orderModifierDetail[0]
                                              .order_modifier_detail_id !=
                                          null
                                      ? ListView.builder(
                                          shrinkWrap: true,
                                          itemCount: orderModifierDetail.length,
                                          itemBuilder: (context, index) {
                                            return Text(
                                              '+ ' +
                                                  orderModifierDetail[index]
                                                      .modifier_name!,
                                              style: TextStyle(fontSize: 16),
                                            );
                                          })
                                      : Container()
                                ],
                              ),
                              title: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    orderDetail[index].productName.toString(),
                                    style: TextStyle(
                                        fontSize: 22,
                                        fontWeight: FontWeight.bold),
                                  ),
                                  Text(
                                    'RM' + orderDetail[index].price!,
                                    style: TextStyle(fontSize: 18),
                                  ),
                                ],
                              )),
                        ),
                      ),
                    );
                  },
                ),
              ),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: ListTile(title: Text('Total', style: TextStyle(fontSize: 24,fontWeight: FontWeight.bold)) ,trailing: Text(widget.orderCache!.total_amount!,style: TextStyle(fontSize: 22,fontWeight: FontWeight.bold))),
                ),
              )
            ],
          ),
        ),
        actions: <Widget>[
          TextButton(
            child: Text('Close'),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
          TextButton(
            child: const Text('Make Payment'),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
        ],
      );
    });
  }
}
