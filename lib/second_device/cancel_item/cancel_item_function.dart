import 'package:pos_system/object/order_cache.dart';
import 'package:pos_system/object/order_detail.dart';
import 'package:pos_system/second_device/cancel_item/cancel_query.dart';

import '../../database/pos_database.dart';

class CancelItemFunction {
  var _posDatabase = PosDatabase.instance;
  late String _userId;
  late String _orderDetailSqliteId;
  late bool _restock;
  late num _cancelQty;
  String? reason;

  CancelItemFunction(this._userId, this._orderDetailSqliteId, this._restock, this._cancelQty, this.reason);

  Future<List<OrderDetail>> readOrderCacheOrderDetail(List<OrderCache> orderCacheList, CancelQuery cancelQuery) async {
    List<OrderDetail> orderDetail = [];
    for(var orderCache in orderCacheList) {
      orderDetail.addAll(await cancelQuery.readAllOrderDetailByOrderCacheSqliteId(orderCache.order_cache_sqlite_id!.toString()));
    }
    return orderDetail;
  }

  cancelOrderDetail() async {
    var db = await _posDatabase.database;
    List<String> _posTableValue = [];
    int updateStatus = await db.transaction((txn) async {
      try {
        final cancelQuery = CancelQuery(txn);
        var cancelOrderDetail = await cancelQuery.readSpecificOrderDetailJoinOrderCache(_orderDetailSqliteId);
        var cancelTableOrderCache = await cancelQuery.readOrderCacheByTableUseKey(cancelOrderDetail!.table_use_key!);
        var cancelOrderCacheOrderDetail = await readOrderCacheOrderDetail(cancelTableOrderCache, cancelQuery);

        if (_cancelQty == cancelOrderDetail.quantity || (cancelOrderDetail.unit != 'each' && cancelOrderDetail.unit != 'each_c')) {
          if (cartTableCacheList.length <= 1 && cartOrderDetailList.length > 1) {
            await cancelQuery.callDeleteOrderDetail();
            // await callDeleteOrderDetail(userData, dateTime, cancelQuery);

          } else if (cartTableCacheList.length > 1 && cartOrderDetailList.length <= 1) {
            await cancelQuery.callDeleteOrderDetail(deleteOrderCache: true, cartOrderCache: cartCacheList.first);
            // await callDeletePartialOrder(userData, dateTime, cancelQuery);

          } else if (cartTableCacheList.length > 1 && cartOrderDetailList.length > 1) {
            await cancelQuery.callDeleteOrderDetail();
            // await callDeleteOrderDetail(userData, dateTime, cancelQuery);

          } else if (widget.currentPage == 'other order' && cartOrderDetailList.length > 1) {
            await cancelQuery.callDeleteOrderDetail();
            // await callDeleteOrderDetail(userData, dateTime, cancelQuery);

          } else {
            await cancelQuery.callDeleteAllOrder(
                currentTableUseId: cartCacheList.first.table_use_sqlite_id!,
                currentPage: widget.currentPage,
                orderCache: cartCacheList.first,
                cartTableUseDetail: cartTableUseDetail
            );
            cart.removeAllTable(notify: false);
            // await callDeleteAllOrder(userData, cartCacheList[0].table_use_sqlite_id!, dateTime, cancelQuery);
            // if (widget.currentPage != 'other order') {
            //   await cancelQuery.updatePosTableStatus(cartTableUseDetail: cartTableUseDetail);
            //   await updatePosTableStatus(dateTime, cancelQuery);
            //   cart.removeAllTable(notify: false);
            // }
          }
          cart.removeItem(widget.cartItem);
        } else {
          await cancelQuery.callUpdateOrderDetail();
          // await callUpdateOrderDetail(userData, dateTime, cancelQuery);
          await cart.updateItemQty(widget.cartItem, cancelQuery, notify: true);
        }
        return 1;
      }catch(e, stackTrace){
        FLog.error(
          className: "adjust_qty_dialog",
          text: "transaction error",
          exception: "Error: $e, StackTrace: $stackTrace",
        );
        Navigator.of(context).pop();
        rethrow;
      }
    });
    print("update status: ${updateStatus}");
    try{
      if(updateStatus == 1){
        syncToFirestore();
        callPrinter(dateTime, cart);
        Fluttertoast.showToast(backgroundColor: Color(0xFF24EF10), msg: AppLocalizations.of(globalContext)!.translate('delete_successful'));
        tableModel.changeContent(true);
        if(mounted){
          Navigator.of(context).pop();
        }
      }
    }catch(e, stackTrace){
      FLog.error(
        className: "adjust_qty_dialog",
        text: "callUpdateCart error",
        exception: "Error: $e, StackTrace: $stackTrace",
      );
    }
    // cart.removeAllTable();
    // cart.removeAllCartItem();
    // cart.removeItem(widget.cartItem!);
    // cart.removePromotion();
    // syncAllToCloud();
  }
}