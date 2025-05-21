import 'package:f_logs/model/flog/flog.dart';
import 'package:pos_system/object/order_cache.dart';
import 'package:pos_system/object/order_detail.dart';
import 'package:pos_system/second_device/cancel_item/cancel_query.dart';
import 'package:pos_system/utils/Utils.dart';

import '../../database/pos_database.dart';
import '../../database/pos_firestore.dart';
import '../../firebase_sync/qr_order_sync.dart';
import '../../fragment/printing_layout/print_receipt.dart';
import '../../notifier/app_setting_notifier.dart';
import '../../notifier/table_notifier.dart';
import '../../object/branch_link_product.dart';
import 'cancel_item_data.dart';

class CancelItemFunction {
  var _posDatabase = PosDatabase.instance;
  var _cancelItemData = CancelItemData.instance;
  var _firestoreQROrderSync = FirestoreQROrderSync.instance;
  var _posFirestore = PosFirestore.instance;
  late final OrderDetail _orderDetail;

  Future<List<OrderDetail>> _readOrderCacheOrderDetail(CancelQuery cancelQuery) async {
    List<OrderDetail> orderDetail = [];
    orderDetail = await cancelQuery.readAllOrderDetailByOrderCacheSqliteId(_orderDetail.order_cache_sqlite_id.toString());
    return orderDetail;
  }

  cancelOrderDetail() async {
    var db = await _posDatabase.database;
    int cancelStatus = await db.transaction((txn) async {
      try {
        final cancelQuery = CancelQuery(txn, Utils.dbCurrentDateTimeFormat());
        var cancelUser = await cancelQuery.readSpecificUserById(_cancelItemData.userId);
        _orderDetail = (await cancelQuery.readSpecificOrderDetailJoinOrderCache(_cancelItemData.orderDetailSqliteId))!;
        List<OrderCache> cancelTableOrderCache = await cancelQuery.readOrderCacheByTableUseKey(_orderDetail.table_use_key!);
        if (_cancelItemData.cancelQty == num.parse(_orderDetail.quantity!) || (_orderDetail.unit != 'each' && _orderDetail.unit != 'each_c')) {
          await cancelQuery.callDeleteOrderDetail(cancelOrderDetail: _orderDetail, cancelUser: cancelUser!);
          if(cancelTableOrderCache.length == 1){
            var cancelTableOrderDetail = await _readOrderCacheOrderDetail(cancelQuery);
            if(cancelTableOrderDetail.isEmpty){
              await cancelQuery.resetOrderCacheTableUse(_orderDetail.table_use_sqlite_id!);
            }
          } else {
            List<OrderDetail> orderDetail = await _readOrderCacheOrderDetail(cancelQuery);
            if(orderDetail.isEmpty){
              await cancelQuery.cancelCurrentOrderCache();
            }
          }
        } else {
          await cancelQuery.callUpdateOrderDetail(cancelOrderDetail: _orderDetail, cancelUser: cancelUser!);
        }
        return 1;
      }catch(e, stackTrace){
        FLog.error(
          className: "cancel item function",
          text: "transaction error",
          exception: "Error: $e, StackTrace: $stackTrace",
        );
        rethrow;
      }
    });
    if(cancelStatus == 1){
      try{
        //sync data to firestore
        syncToFirestore(_orderDetail);
        callPrinter(Utils.formatDate(DateTime.now().toString()), _orderDetail.order_cache_sqlite_id!, _orderDetail.category_sqlite_id!);
        //refresh table ui
        TableModel.instance.changeContent(true);
      }catch(e, s){
        FLog.error(
          className: "cancel item function",
          text: "outside transaction error",
          exception: "Error: $e, StackTrace: $s",
        );
      }
    }
  }

  callPrinter(String dateTime, String orderCacheSqliteId, String categorySqliteId) async {
    try{
      PrintReceipt _printReceipt = PrintReceipt();
      await _printReceipt.readAllPrinters();
      print("auto print cancel: ${AppSettingModel.instance.autoPrintCancelReceipt!}");
      if(AppSettingModel.instance.autoPrintCancelReceipt!){
        await _printReceipt.printCancelReceipt(orderCacheSqliteId, dateTime);
        //print kitchen cancel receipt
        await _printReceipt.printKitchenDeleteList(
          orderCacheSqliteId,
          categorySqliteId,
          dateTime,
        );
      }
    }catch(e, stackTrace){
      FLog.error(
        className: "adjust_qty_dialog",
        text: "callPrinter error",
        exception: "Error: $e, StackTrace: $stackTrace",
      );
      rethrow;
    }
  }

  syncToFirestore(OrderDetail orderDetail) async {
    try{
      OrderDetail orderDetailData = await _posDatabase.readSpecificOrderDetailByLocalId(orderDetail.order_detail_sqlite_id!);
      OrderCache? orderCacheData = await _posDatabase.readSpecificOrderCacheByKey(orderDetail.order_cache_key!);
      BranchLinkProduct? branchLinkProductData = await _posDatabase.readSpecificBranchLinkProduct2(orderDetail.branch_link_product_sqlite_id!.toString());
      if(_cancelItemData.restock && branchLinkProductData!.stock_type != 3){
        _posFirestore.insertBranchLinkProduct(branchLinkProductData);
      }
      if(orderCacheData!.qr_order == 1){
        _firestoreQROrderSync.updateOrderDetailAndOrderCache(orderDetailData, orderCacheData);
      }
    }catch(e, stackTrace){
      FLog.error(
        className: "adjust_qty_dialog",
        text: "syncToFirestore error",
        exception: "Error: $e, StackTrace: $stackTrace",
      );
      rethrow;
    }
  }
}