import 'dart:async';

import 'package:flutter/material.dart';
import 'package:pos_system/database/pos_database.dart';
import 'package:pos_system/fragment/qr_order/adjust_stock_dialog.dart';
import 'package:pos_system/object/branch_link_product.dart';
import 'package:pos_system/object/order_cache.dart';
import 'package:pos_system/object/order_detail.dart';
import 'package:pos_system/object/order_modifier_detail.dart';
import 'package:pos_system/object/table.dart';
import 'package:pos_system/utils/Utils.dart';

import '../../database/domain.dart';

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
        body: StreamBuilder(
            stream: controller.stream,
            builder: (context, snapshot) {
              preload();
              return Container(
                padding: EdgeInsets.all(20),
                child: Container(
                  margin: EdgeInsets.fromLTRB(0, 0, 0, 10),
                  alignment: Alignment.topLeft,
                  child: Stack(
                    children: [
                      Container(
                        margin: EdgeInsets.only(bottom: 20),
                        child: Text('Qr Order', style: TextStyle(fontSize: 25)),
                      ),
                      qrOrderCacheList.isNotEmpty
                          ? ListView.builder(
                              padding: EdgeInsets.only(top: 50),
                              shrinkWrap: true,
                              itemCount: qrOrderCacheList.length,
                              itemBuilder: (BuildContext context, int index) {
                                return Card(
                                  elevation: 5,
                                  child: ListTile(
                                    contentPadding: EdgeInsets.all(10),
                                    //isThreeLine: true,
                                    title: qrOrderCacheList[index].dining_id == '1'
                                        ? Text('Table No: ${qrOrderCacheList[index].table_number}', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blueGrey))
                                        : qrOrderCacheList[index].dining_id == '2'
                                            ? Text('Take Away')
                                            : Text('Delivery'),
                                    subtitle: RichText(
                                      text: TextSpan(
                                        style: TextStyle(color: Colors.black, fontSize: 16),
                                        children: <TextSpan>[
                                          TextSpan(
                                              text: 'Date: ${Utils.formatDate(qrOrderCacheList[index].created_at)}',
                                              style: TextStyle(color: Colors.blueGrey, fontSize: 14)),
                                          TextSpan(text: '\n'),
                                          TextSpan(
                                            text: 'Amount: ${Utils.convertTo2Dec(qrOrderCacheList[index].total_amount)}',
                                            style: TextStyle(color: Colors.black87, fontSize: 14),
                                          ),
                                        ],
                                      ),
                                    ),
                                    leading: CircleAvatar(
                                        backgroundColor: Colors.grey.shade200,
                                        child: Icon(
                                          Icons.qr_code,
                                          color: Colors.grey,
                                        )),
                                    trailing: Text('#${qrOrderCacheList[index].batch_id}', style: TextStyle(fontSize: 18)),
                                    onTap: () async {
                                      await checkOrderDetail(qrOrderCacheList[index].order_cache_sqlite_id!);
                                      //pop stock adjust dialog
                                      openAdjustStockDialog(orderDetailList, qrOrderCacheList[index].order_cache_sqlite_id!,
                                          qrOrderCacheList[index].qr_order_table_sqlite_id!);
                                    },
                                  ),
                                );
                              })
                          : Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.qr_code_2, size: 40.0),
                                  Text('NO ORDER', style: TextStyle(fontSize: 24)),
                                ],
                              ),
                            ),
                    ],
                  ),
                ),
              );
            }));
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
                orderCacheLocalId: localId,
                callBack: () => preload(),
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
    await getAllNotAcceptedQrOrder();
  }

  checkOrderDetail(int orderCacheLocalId) async {
    List<OrderDetail> detailData = await PosDatabase.instance.readAllOrderDetailByOrderCache(orderCacheLocalId);
    orderDetailList = detailData;
    for (int i = 0; i < orderDetailList.length; i++) {
      List<BranchLinkProduct> data = await PosDatabase.instance.readSpecificBranchLinkProduct(orderDetailList[i].branch_link_product_sqlite_id!);
      List<OrderModifierDetail> modDetailData =
          await PosDatabase.instance.readOrderModifierDetail(orderDetailList[i].order_detail_sqlite_id.toString());

      orderDetailList[i].orderModifierDetail = modDetailData;
      if (data[0].stock_type == '2') {
        orderDetailList[i].available_stock = data[0].stock_quantity!;
      } else {
        orderDetailList[i].available_stock = data[0].daily_limit_amount!;
      }
      orderDetailList[i].isRemove = false;
    }
  }

  updateQrOrderTableLocalId(int orderCacheId, String tableLocalId) async {
    OrderCache orderCache = OrderCache(order_cache_sqlite_id: orderCacheId, qr_order_table_sqlite_id: tableLocalId);
    int data = await PosDatabase.instance.updateOrderCacheTableLocalId(orderCache);
  }

  getAllNotAcceptedQrOrder() async {
    List<OrderCache> data = await PosDatabase.instance.readNotAcceptedQROrderCache();
    qrOrderCacheList = data;
    if (qrOrderCacheList.isNotEmpty) {
      for (int i = 0; i < qrOrderCacheList.length; i++) {
        if (qrOrderCacheList[i].qr_order_table_id != '') {
          PosTable tableData = await PosDatabase.instance.readTableByCloudId(qrOrderCacheList[i].qr_order_table_id!);
          await updateQrOrderTableLocalId(qrOrderCacheList[i].order_cache_sqlite_id!, tableData.table_sqlite_id.toString());
        } else {
          qrOrderCacheList[i].table_number = '';
        }
        //callUpdateCloud(qrOrderCacheList[i].order_cache_key!);
      }
    }
    if (!controller.isClosed) {
      controller.sink.add('refresh');
    }
  }

  callUpdateCloud(String key) async {
    bool _hasInternetAccess = await Domain().isHostReachable();
    if (_hasInternetAccess) {
      Map response = await Domain().updateCloudOrderCacheSyncStatus(key);
    }
  }
}
