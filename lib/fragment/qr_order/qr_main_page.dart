import 'dart:async';
import 'dart:convert';

import 'package:confirm_dialog/confirm_dialog.dart';
import 'package:f_logs/model/flog/flog.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pos_system/database/pos_database.dart';
import 'package:pos_system/fragment/qr_order/adjust_stock_dialog.dart';
import 'package:pos_system/main.dart';
import 'package:pos_system/object/branch_link_product.dart';
import 'package:pos_system/object/order_cache.dart';
import 'package:pos_system/object/order_detail.dart';
import 'package:pos_system/object/order_modifier_detail.dart';
import 'package:pos_system/object/qr_order.dart';
import 'package:pos_system/object/qr_order_auto_accept.dart';
import 'package:pos_system/object/table.dart';
import 'package:pos_system/translation/AppLocalizations.dart';
import 'package:pos_system/utils/Utils.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../notifier/theme_color.dart';

class QrMainPage extends StatefulWidget {
  const QrMainPage({Key? key}) : super(key: key);

  @override
  State<QrMainPage> createState() => _QrMainPageState();
}

class _QrMainPageState extends State<QrMainPage> {
  List<OrderCache> qrOrderCacheList = [];
  List<OrderDetail> orderDetailList = [], noStockOrderDetailList = [];
  bool _isLoaded = false, hasNoStockProduct = false, hasAccess = true;

  @override
  void initState() {
    super.initState();
    checkStatus();
  }

  @override
  void deactivate() {
    super.deactivate();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeColor>(builder: (context, ThemeColor color, child) {
      return hasAccess ?
        Scaffold(
          appBar: QrAppBar(context, color),
          body: Consumer<QrOrder>(builder: (context, order, child) {
            getAllNotAcceptedQrOrder(order);
            return Container(
              padding: const EdgeInsets.all(10),
              child: qrOrderCacheList.isNotEmpty ?
              OrderListView()
                  :
              NoOrderView(context),
            );
          })
      ) :
      Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.lock),
          Text(AppLocalizations.of(context)!.translate('upgrade_to_use_qr_order'))
        ],
      );
    });
  }

  AppBar QrAppBar(BuildContext context, ThemeColor color) {
    return AppBar(
      primary: false,
      elevation: 0,
      automaticallyImplyLeading: false,
      title: Row(
        children: [
          Text(AppLocalizations.of(context)!.translate('qr_order'), style: TextStyle(fontSize: 25)),
          Spacer(),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: color.backgroundColor,
            ),
            icon: Icon(Icons.sync),
            label: Text(
              AppLocalizations.of(context)!.translate('sync_qr_order'),
              style: TextStyle(color: Colors.white),
            ),
            onPressed: () async {
              if(qrOrder.count == 0){
                qrOrder.count = 1;
                await qrOrder.getQrOrder(MyApp.navigatorKey.currentContext!);
                qrOrder.count = 0;
              }
            },
          ),
          SizedBox(width: 10),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: color.backgroundColor,
            ),
            icon: Icon(Icons.receipt_long),
            label: Text(
              AppLocalizations.of(context)!.translate('accept_all'),
              style: TextStyle(color: Colors.white),
            ),
            onPressed: () async {
              if (await confirm(
                context,
                title: Text("${AppLocalizations.of(context)!.translate('confirm_accept_all')}"),
                content: Text('${AppLocalizations.of(context)!.translate('confirm_accept_all_desc')}'),
                textOK: Text('${AppLocalizations.of(context)!.translate('yes')}'),
                textCancel: Text('${AppLocalizations.of(context)!.translate('no')}'),
              )) {
                if(mounted){
                  asyncQ.addJob((_) async => await QrOrderAutoAccept().load());
                }
              }
            },
          ),
        ],
      ),
    );
  }

  Widget NoOrderView(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.qr_code_2, size: 40.0),
          Text(AppLocalizations.of(context)!.translate('no_order'), style: TextStyle(fontSize: 24)),
        ],
      ),
    );
  }

  Widget OrderListView() {
    return ListView.builder(
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
                  TextSpan(text: '\n'),
                  TextSpan(text: 'Batch ID: #${qrOrderCacheList[index].batch_id}',
                      style: TextStyle(color: Colors.black54, fontSize: 14)),
                ],
              ),
            ),
            leading: CircleAvatar(
                backgroundColor: Colors.grey.shade200,
                child: Icon(
                  Icons.qr_code,
                  color: Colors.grey,
                )),
            trailing: Container(
              width: 130,
              padding: EdgeInsets.all(8.0),
              child: Text(
                '${getDuration(qrOrderCacheList[index].created_at)}',
                style: TextStyle(fontSize: 18, color: Colors.white),
                textAlign: TextAlign.center,
              ),// as needed
              decoration: BoxDecoration(
                color: getBackgroundColor(qrOrderCacheList[index].created_at),
                borderRadius: BorderRadius.circular(8.0),
              ),
            ),
            onTap: () async {
              await checkOrderDetail(qrOrderCacheList[index].order_cache_sqlite_id!, index);
              //pop stock adjust dialog
              openAdjustStockDialog(orderDetailList, qrOrderCacheList[index].order_cache_sqlite_id!,
                  qrOrderCacheList[index].qr_order_table_sqlite_id!, qrOrderCacheList[index].batch_id!);
            },
          ),
        );
      },
    );
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
                callBack: () => QrOrder.instance.getAllNotAcceptedQrOrder(),
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

  getAllNotAcceptedQrOrder(QrOrder order) async {
    qrOrderCacheList = order.qrOrderCacheList;
    if (qrOrderCacheList.isNotEmpty) {
      for (int i = 0; i < qrOrderCacheList.length; i++) {
        if (qrOrderCacheList[i].qr_order_table_id != '') {
          if(qrOrderCacheList[i].qr_order_table_sqlite_id == ''){
            PosTable tableData = await PosDatabase.instance.readTableByCloudId(qrOrderCacheList[i].qr_order_table_id!);
            int status = await updateQrOrderTableLocalId(qrOrderCacheList[i].order_cache_sqlite_id!, tableData.table_sqlite_id.toString());
            if(status == 1){
              qrOrderCacheList[i].qr_order_table_sqlite_id = tableData.table_sqlite_id.toString();
            }
          }
        } else {
          qrOrderCacheList[i].table_number = '';
        }
        //callUpdateCloud(qrOrderCacheList[i].order_cache_key!);
      }
    }
  }

  Future<void> checkStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final String? branch = prefs.getString('branch');
    Map branchObject = json.decode(branch!);
    if(branchObject['qr_order_status'] == '1'){
      setState(() {
        hasAccess = false;
      });
    }
  }

  checkOrderDetail(int orderCacheLocalId, int index) async {
    try{
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
    }catch(e){
      FLog.error(
        className: "qr main page",
        text: "check order detail error",
        exception: e,
      );
      print("check order detail error: ${e}");
    }
  }

  Future<int> updateQrOrderTableLocalId(int orderCacheId, String tableLocalId) async {
    OrderCache orderCache = OrderCache(order_cache_sqlite_id: orderCacheId, qr_order_table_sqlite_id: tableLocalId);
    int status = await PosDatabase.instance.updateOrderCacheTableLocalId(orderCache);
    return status;
  }

  String getDuration(String? created_at) {
    DateFormat dateFormat = DateFormat("yyyy-MM-dd HH:mm:ss");
    DateTime currentDateTime = dateFormat.parse(dateFormat.format(DateTime.now()));
    DateTime qrOrderCreatedAt = dateFormat.parse(created_at!);

    Duration difference = currentDateTime.difference(qrOrderCreatedAt);

    if (difference.inMinutes < 1) {
      return '1 minute';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes} minutes';
    } else if (difference.inDays < 1) {
      return '${difference.inHours} hours';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days';
    } else {
      return '${difference.inDays ~/ 7} weeks';
    }
  }

  Color getBackgroundColor(String? created_at) {
    DateFormat dateFormat = DateFormat("yyyy-MM-dd HH:mm:ss");
    DateTime currentDateTime = dateFormat.parse(dateFormat.format(DateTime.now()));
    DateTime qrOrderCreatedAt = dateFormat.parse(created_at!);

    Duration difference = currentDateTime.difference(qrOrderCreatedAt);

    if (difference.inMinutes > 10) {
      return Colors.red;
    } else {
      return Colors.green;
    }
  }

  // callUpdateCloud(String key) async {
  //   bool _hasInternetAccess = await Domain().isHostReachable();
  //   if (_hasInternetAccess) {
  //     Map response = await Domain().updateCloudOrderCacheSyncStatus(key);
  //   }
  // }
}
