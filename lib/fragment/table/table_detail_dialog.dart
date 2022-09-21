import 'dart:async';

import 'package:flutter/material.dart';
import 'package:pos_system/object/branch_link_product.dart';
import 'package:pos_system/object/order_detail.dart';
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
  List<OrderDetail> orderDetailList = [];
  List<BranchLinkProduct> branchProductList = [];
  double totalOrderAmount = 0.0;
  bool isLoad = false;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    readSpecificTableDetail();
  }

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeColor>(builder: (context, ThemeColor color, child) {
      return AlertDialog(
        title: Text("table ${widget.object.number} detail"),
        content: isLoad
            ? Container(
                width: 350.0,
                height: 450.0,
                child: Column(
                  children: [
                    Expanded(
                        child: Container(
                          height: 350,
                          child: ListView.builder(
                              shrinkWrap: true,
                              itemCount: orderDetailList.length,
                              itemBuilder: (context, index) {
                                return SizedBox(
                                  height: 85.0,
                                  child: Column(
                                    children: [
                                      Expanded(
                                            child: ListView.builder(
                                              shrinkWrap: true,
                                              itemCount: branchProductList.length,
                                              itemBuilder: (context, index) {
                                                return Text('${branchProductList[index].product_name}');
                                              },
                                            ),
                                      ),
                                      Expanded(
                                        child: ListTile(
                                          hoverColor: Colors.transparent,
                                          onTap: () {},
                                          isThreeLine: true,
                                          title: RichText(
                                            text: TextSpan(
                                              children: <TextSpan>[
                                                TextSpan(
                                                    text: "RM" +
                                                        orderDetailList[index].total_amount!,
                                                    style: TextStyle(
                                                      fontSize: 13,
                                                      color: color.backgroundColor,
                                                    )),
                                              ],
                                            ),
                                          ),
                                          subtitle: Text('Remark here'),
                                          trailing: Container(
                                            child: FittedBox(
                                              child: Row(
                                                children: [
                                                  Text('qty'),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ]
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
                            trailing: Text("${getAllTotalAmount()}"),
                          ),
                          TextButton(
                              onPressed: () {
                                print('${branchProductList[0].product_name}');
                              },
                              child: Text("Print food detail"))
                        ],
                      ),
                    )
                  ]
                )
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
    for(int i = 0; i < data.length; i++){
      List<OrderDetail> detailData = await PosDatabase.instance
          .readTableOrderDetail(data[i].order_cache_id.toString());

      for(int j = 0; j < detailData.length; j++){
        await getAllProductDetail(detailData[j].branch_link_product_id!);
      }

      setState(() {
        orderDetailList += detailData;
        isLoad = true;
      });
      print('order list length: ${orderDetailList.length}');
      print('init branch product length: ${branchProductList.length}');

    }
  }

  getAllTotalAmount(){
    totalOrderAmount = 0.0;
    for(int i = 0; i < orderDetailList.length; i++){
      totalOrderAmount +=  double.parse(orderDetailList[i].total_amount!);
    }
    return totalOrderAmount.toStringAsFixed(2);
  }

  getAllProductDetail(String branch_link_product_id) async {
    List<String> branchProductItem = [];
    List<BranchLinkProduct> data = await PosDatabase.instance.readSpecificBranchLinkProduct(branch_link_product_id);
    branchProductList = data;
    print('call inside get all product detail: ${branchProductList.length}');
  }

}
