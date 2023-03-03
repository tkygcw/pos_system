import 'dart:async';

import 'package:flutter/material.dart';
import 'package:pos_system/database/pos_database.dart';
import 'package:pos_system/fragment/qr_order/adjust_stock_dialog.dart';
import 'package:pos_system/object/branch_link_product.dart';
import 'package:pos_system/object/order_cache.dart';
import 'package:pos_system/object/order_detail.dart';
import 'package:pos_system/object/order_modifier_detail.dart';

import '../../page/progress_bar.dart';
import '../../translation/AppLocalizations.dart';
import '../settlement/pos_pin_dialog.dart';

class QrMainPage extends StatefulWidget {
  const QrMainPage({Key? key}) : super(key: key);

  @override
  State<QrMainPage> createState() => _QrMainPageState();
}

class _QrMainPageState extends State<QrMainPage> {
  late StreamController controller;
  List<OrderCache> qrOrderCacheList = [];
  List<OrderDetail> orderDetailList = [], noStockOrderDetailList = [];
  bool _isLoaded = false, hasNoStockProduct = false;

  @override
  void initState() {
    super.initState();
    controller = StreamController();
    preload();
  }

  @override
  void deactivate() {
    controller.sink.close();
    super.deactivate();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body:
      StreamBuilder(
          stream: controller.stream, builder: (context, snapshot) {
          preload();
          return Container(
            padding:  EdgeInsets.all(20),
            child: Container(
              margin: EdgeInsets.fromLTRB(0, 0, 0, 10),
              alignment: Alignment.topLeft,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    margin: EdgeInsets.only(bottom: 20),
                    child: Text('Qr Order', style: TextStyle(fontSize: 25)),
                  ),
                  ListView.builder(
                      shrinkWrap: true,
                      itemCount: qrOrderCacheList.length,
                      itemBuilder: (BuildContext context, int index){
                        return Card(
                          elevation: 5,
                          child: ListTile(
                            title: Text('id: ${qrOrderCacheList[index].customer_id}'),
                            subtitle: Text('Amount: ${qrOrderCacheList[index].total_amount}'),
                            leading: CircleAvatar(backgroundColor: Colors.grey.shade200,child: Icon(Icons.qr_code, color: Colors.grey,)),
                            trailing: Text('#${qrOrderCacheList[index].batch_id}'),
                            onTap: () async  {
                              await checkOrderDetail(qrOrderCacheList[index].order_cache_sqlite_id!);
                              //pop stock adjust dialog
                              openAdjustStockDialog(orderDetailList, qrOrderCacheList[index].order_cache_sqlite_id!, qrOrderCacheList[index].qr_order_table_sqlite_id!);
                              // if(hasNoStockProduct){
                              //
                              // } else {
                              //   //check is table in use or not
                              //   ///if table is not in use then =>
                              //   // generate table use record & key
                              //   // generate table use detail
                              //   //update into order cache
                              //   //update pos table status
                              //   /// else =>
                              //   //get the order cache based on table use detail sqlite id with table id
                              //   // get table use key & table use sqlite insert into table order cache
                              //   // create table use detail
                              // }
                              //check stock
                              //get all item compare stock
                              //if no stock add to one list
                              //pop dialog box show all no stock product
                              //if cancel just pop dialog
                              //
                            },
                          ),
                        );
                      }
                  )
                ],
              ),
            ),
          );
        }
      )
    );
  }

  openAdjustStockDialog(List<OrderDetail> orderDetail, int localId, String tableLocalId) async {
    return showGeneralDialog(
        barrierColor: Colors.black.withOpacity(0.5),
        transitionBuilder: (context, a1, a2, widget) {
          final curvedValue = Curves.easeInOutBack.transform(a1.value) - 1.0;
          return Transform(
            transform: Matrix4.translationValues(0.0, curvedValue * 200, 0.0),
            child: Opacity(
              opacity: a1.value,
              child: AdjustStockDialog(
                orderDetailList: orderDetail,
                tableLocalId: tableLocalId,
                orderCacheLocalId: localId, callBack: () => preload(),
                orderCacheList: qrOrderCacheList,
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

  preload() async {
    print('keep called');
    await getAllNotAcceptedQrOrder();
    if (!controller.isClosed) {
      controller.sink.add('refresh');
    }
    // setState(() {
    //   _isLoaded = true;
    // });
  }

  checkOrderDetail(int orderCacheLocalId) async {
    // orderDetailList = [];
    // noStockOrderDetailList = [];
    // hasNoStockProduct == false;
    List<OrderDetail> detailData = await PosDatabase.instance.readAllOrderDetailByOrderCache(orderCacheLocalId);
    orderDetailList = detailData;
    for(int i = 0; i < orderDetailList.length; i++){
      List<BranchLinkProduct> data = await PosDatabase.instance.readSpecificBranchLinkProduct(orderDetailList[i].branch_link_product_sqlite_id!);
      List<OrderModifierDetail> modDetailData = await PosDatabase.instance.readOrderModifierDetail(orderDetailList[i].order_detail_sqlite_id.toString());

      print('mod data: ${modDetailData}');
      orderDetailList[i].orderModifierDetail = modDetailData;
      print('data: ${ orderDetailList[i].orderModifierDetail = modDetailData}');
      orderDetailList[i].available_stock = data[0].stock_quantity!;
      orderDetailList[i].isRemove = false;
      //noStockOrderDetailList.add(orderDetailList[i]);
     // if(int.parse(orderDetailList[i].quantity!) > int.parse(data[0].stock_quantity!)){
     //
     //   hasNoStockProduct = true;
     // }
    }
  }



  getAllNotAcceptedQrOrder() async {
    List<OrderCache> data = await PosDatabase.instance.readNotAcceptedQROrderCache();
    qrOrderCacheList = data;
    //controller.sink.add('1');
    print('order cache list: ${qrOrderCacheList.length}');
  }
}
