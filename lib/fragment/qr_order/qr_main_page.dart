import 'dart:async';

import 'package:flutter/material.dart';
import 'package:pos_system/database/pos_database.dart';
import 'package:pos_system/fragment/qr_order/adjust_stock_dialog.dart';
import 'package:pos_system/object/branch_link_product.dart';
import 'package:pos_system/object/order_cache.dart';
import 'package:pos_system/object/order_detail.dart';
import 'package:pos_system/object/order_modifier_detail.dart';
import 'package:pos_system/object/table.dart';
import 'package:pos_system/page/progress_bar.dart';
import 'package:pos_system/translation/AppLocalizations.dart';
import 'package:pos_system/utils/Utils.dart';
import 'package:provider/provider.dart';
import '../../notifier/theme_color.dart';

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
    return Consumer<ThemeColor>(builder: (context, ThemeColor color, child) {
      return Scaffold(
          appBar: AppBar(
            primary: false,
            elevation: 0,
            automaticallyImplyLeading: false,
            title: Text(AppLocalizations.of(context)!.translate('qr_order'), style: TextStyle(fontSize: 25)),
          ),
          body: StreamBuilder(
              stream: controller.stream,
              builder: (context, snapshot) {
                preload();
                return _isLoaded
                    ?
                Container(
                  padding: EdgeInsets.all(10),
                  child: qrOrderCacheList.isNotEmpty
                      ? ListView.builder(
                      shrinkWrap: true,
                      itemCount: qrOrderCacheList.length,
                      itemBuilder: (BuildContext context, int index) {
                        return Card(
                          elevation: 5,
                          child: ListTile(
                            contentPadding: EdgeInsets.all(10),
                            //isThreeLine: true,
                            title: qrOrderCacheList[index].dining_name == 'Dine in'
                                ? Text(AppLocalizations.of(context)!.translate('table_no')+': ${qrOrderCacheList[index].table_number}', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blueGrey))
                                : qrOrderCacheList[index].dining_name == 'Take Away'
                                ? Text(AppLocalizations.of(context)!.translate('take_away'), style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blueGrey))
                                : Text(AppLocalizations.of(context)!.translate('delivery'), style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blueGrey)),
                            subtitle: RichText(
                              text: TextSpan(
                                style: TextStyle(color: Colors.black, fontSize: 16),
                                children: <TextSpan>[
                                  TextSpan(
                                      text: AppLocalizations.of(context)!.translate('date')+': ${Utils.formatDate(qrOrderCacheList[index].created_at)}',
                                      style: TextStyle(color: Colors.blueGrey, fontSize: 14)),
                                  TextSpan(text: '\n'),
                                  TextSpan(
                                    text: AppLocalizations.of(context)!.translate('amount')+': ${Utils.convertTo2Dec(qrOrderCacheList[index].total_amount)}',
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
                              await checkOrderDetail(qrOrderCacheList[index].order_cache_sqlite_id!, index);
                              //pop stock adjust dialog
                              openAdjustStockDialog(orderDetailList, qrOrderCacheList[index].order_cache_sqlite_id!,
                                  qrOrderCacheList[index].qr_order_table_sqlite_id!, qrOrderCacheList[index].batch_id!);
                            },
                          ),
                        );
                      })
                      :
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.qr_code_2, size: 40.0),
                        Text(AppLocalizations.of(context)!.translate('no_order'), style: TextStyle(fontSize: 24)),
                      ],
                    ),
                  ),
                )
                    :
                CustomProgressBar();
              }));
    });
  }

  openAdjustStockDialog(List<OrderDetail> orderDetail, int localId, String tableLocalId, String batchNumber) async {
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
                currentBatch: batchNumber,
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

  checkOrderDetail(int orderCacheLocalId, int index) async {
    List<OrderDetail> detailData = await PosDatabase.instance.readAllOrderDetailByOrderCache(orderCacheLocalId);
    orderDetailList = detailData;
    for (int i = 0; i < orderDetailList.length; i++) {
      orderDetailList[i].tableNumber.add(qrOrderCacheList[index].table_number!);
      List<BranchLinkProduct> data = await PosDatabase.instance.readSpecificBranchLinkProduct(orderDetailList[i].branch_link_product_sqlite_id!);
      List<OrderModifierDetail> modDetailData = await PosDatabase.instance.readOrderModifierDetail(orderDetailList[i].order_detail_sqlite_id.toString());

      orderDetailList[i].orderModifierDetail = modDetailData;
      if(data.isNotEmpty){
        switch(data[0].stock_type){
          case '1': {
            orderDetailList[i].available_stock = data[0].daily_limit!;
          }break;
          case '2': {
            orderDetailList[i].available_stock = data[0].stock_quantity!;
          } break;
          default: {
            orderDetailList[i].available_stock = '';
          }
        }
      } else {
        orderDetailList[i].available_stock = '';
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
    _isLoaded = true;
    if (!controller.isClosed) {
      controller.sink.add('refresh');
    }
  }

  // callUpdateCloud(String key) async {
  //   bool _hasInternetAccess = await Domain().isHostReachable();
  //   if (_hasInternetAccess) {
  //     Map response = await Domain().updateCloudOrderCacheSyncStatus(key);
  //   }
  // }
}
