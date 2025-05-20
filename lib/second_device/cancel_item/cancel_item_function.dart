import 'package:f_logs/model/flog/flog.dart';
import 'package:pos_system/object/order_cache.dart';
import 'package:pos_system/object/order_detail.dart';
import 'package:pos_system/second_device/cancel_item/cancel_query.dart';
import 'package:pos_system/utils/Utils.dart';

import '../../database/pos_database.dart';
import '../../notifier/table_notifier.dart';
import 'cancel_item_data.dart';

class CancelItemFunction {
  var _posDatabase = PosDatabase.instance;
  var _cancelItemData = CancelItemData.instance;

  Future<List<OrderDetail>> _readOrderCacheOrderDetail(List<OrderCache> orderCacheList, CancelQuery cancelQuery) async {
    List<OrderDetail> orderDetail = [];
    for(var orderCache in orderCacheList) {
      List<OrderDetail> data = await cancelQuery.readAllOrderDetailByOrderCacheSqliteId(orderCache.order_cache_sqlite_id!.toString());
      orderDetail.addAll(data);
    }
    return orderDetail;
  }

  cancelOrderDetail() async {
    var db = await _posDatabase.database;
    int updateStatus = await db.transaction((txn) async {
      try {
        final cancelQuery = CancelQuery(txn, Utils.dbCurrentDateTimeFormat());
        var cancelUser = await cancelQuery.readSpecificUserById(_cancelItemData.userId);
        var cancelOrderDetail = await cancelQuery.readSpecificOrderDetailJoinOrderCache(_cancelItemData.orderDetailSqliteId);
        List<OrderCache> cancelTableOrderCache = await cancelQuery.readOrderCacheByTableUseKey(cancelOrderDetail!.table_use_key!);
        var cancelOrderCacheOrderDetail = await _readOrderCacheOrderDetail(cancelTableOrderCache, cancelQuery);

        if (_cancelItemData.cancelQty == cancelOrderDetail.quantity || (cancelOrderDetail.unit != 'each' && cancelOrderDetail.unit != 'each_c')) {
          await cancelQuery.callDeleteOrderDetail();
          if(cancelTableOrderCache.length == 1 && cancelOrderCacheOrderDetail.length == 1){
            await cancelQuery.resetOrderCacheTableUse(cancelOrderDetail.table_use_sqlite_id!);
          }
        } else {
          await cancelQuery.callUpdateOrderDetail(cancelOrderDetail: cancelOrderDetail, cancelUser: cancelUser!);
        }
        return 1;
      }catch(e, stackTrace){
        FLog.error(
          className: "adjust_qty_dialog",
          text: "transaction error",
          exception: "Error: $e, StackTrace: $stackTrace",
        );
        rethrow;
      }
    });
    print("update status: ${updateStatus}");
    try{
      if(updateStatus == 1){
        //sync data to firestore
        //syncToFirestore();
        //print cancel receipt
        //callPrinter(dateTime, cart);
        // Fluttertoast.showToast(backgroundColor: Color(0xFF24EF10), msg: AppLocalizations.of(globalContext)!.translate('delete_successful'));
        //refresh table menu UI
        TableModel.instance.changeContent(true);
      }
    }catch(e, stackTrace){
      FLog.error(
        className: "adjust_qty_dialog",
        text: "callUpdateCart error",
        exception: "Error: $e, StackTrace: $stackTrace",
      );
    }
  }
}