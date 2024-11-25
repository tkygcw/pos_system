import 'dart:convert';

import 'package:pos_system/second_device/order/place_order.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../database/pos_database.dart';
import '../../main.dart';
import '../../notifier/cart_notifier.dart';
import '../../object/cart_product.dart';
import '../../object/order_cache.dart';

class PlaceNotDineInOrder extends PlaceOrder {

  @override
  Future<void> createOrderCache(CartModel cart, String orderBy, String orderByUserId) async {
    String dateTime = dateFormat.format(DateTime.now());
    final prefs = await SharedPreferences.getInstance();
    final int? branch_id = prefs.getInt('branch_id');
    final String? loginUser = prefs.getString('user');
    Map loginUserObject = json.decode(loginUser!);
    String batch = '';
    try {
      int? orderQueue = await generateOrderQueue(cart);
      batch = await batchChecking();
      // if (isAddOrder == true) {
      //   batch = cart.cartNotifierItem[0].first_cache_batch!;
      // } else {
      //   batch = await batchChecking();
      // }
      //check selected table is in use or not
      // if (cart.selectedOption == 'Dine in') {
      //   for (int i = 0; i < cart.selectedTable.length; i++) {
      //     List<TableUseDetail> useDetail = await PosDatabase.instance.readSpecificTableUseDetail(cart.selectedTable[i].table_sqlite_id!);
      //     if (useDetail.isNotEmpty) {
      //       _tableUseId = useDetail[0].table_use_sqlite_id!;
      //     } else {
      //       _tableUseId = this.localTableUseId;
      //     }
      //   }
      //   List<TableUse> tableUseData = await PosDatabase.instance.readSpecificTableUseId(int.parse(_tableUseId));
      //   _tableUse = tableUseData;
      // }
      if (batch != '') {
        //create order cache
        OrderCache data = await PosDatabase.instance.insertSqLiteOrderCache(OrderCache(
            order_cache_id: 0,
            order_cache_key: '',
            order_queue: orderQueue != null ? orderQueue.toString().padLeft(4, '0') : '',
            company_id: loginUserObject['company_id'].toString(),
            branch_id: branch_id.toString(),
            order_detail_id: '',
            table_use_sqlite_id: '',
            table_use_key: '',
            batch_id: batch.toString().padLeft(6, '0'),
            dining_id: cart.selectedOptionId,//this.diningOptionID.toString(),
            order_sqlite_id: '',
            order_key: '',
            order_by: orderBy,
            order_by_user_id: orderByUserId,
            cancel_by: '',
            cancel_by_user_id: '',
            customer_id: '0',
            total_amount: cart.subtotal,  //newOrderSubtotal.toStringAsFixed(2),
            qr_order: 0,
            qr_order_table_sqlite_id: '',
            qr_order_table_id: '',
            accepted: 0,
            payment_status: 0,
            sync_status: 0,
            created_at: dateTime,
            updated_at: '',
            soft_delete: ''));
        orderCacheSqliteId = data.order_cache_sqlite_id.toString();
        //orderNumber = data.order_queue.toString();
        await insertOrderCacheKey(data, dateTime);
        //sync to cloud
        //syncOrderCacheToCloud(updatedCache);
        //cart.addOrder(data);
      }
    } catch (e) {
      print('createOrderCache error: ${e}');
    }
  }

  @override
  Future<Map<String, dynamic>> placeOrder(CartModel cart, String address, String orderBy, String orderByUserId) async {
    print("callCreateNewNotDineOrder");
    Map<String, dynamic> objectData;
    Map<String, dynamic>? stockResponse = await checkOrderStock(cart);
    await initData();
    if(stockResponse == null){
      await createOrderCache(cart, orderBy, orderByUserId);
      await createOrderDetail(cart);
      await printCheckList(orderBy);
      List<cartProductItem> ticketProduct = cart.cartNotifierItem.where((e) => e.allow_ticket == 1).toList();
      if(ticketProduct.isNotEmpty){
        await printReceipt.printProductTicket(printerList, int.parse(orderCacheSqliteId), ticketProduct);
      }
      // if (_appSettingModel.autoPrintChecklist == true) {
      //   int printStatus = await printReceipt.printCheckList(printerList, int.parse(this.orderCacheId));
      //   if (printStatus == 1) {
      //     Fluttertoast.showToast(backgroundColor: Colors.red, msg: "${AppLocalizations.of(context)?.translate('printer_not_connected')}");
      //   } else if (printStatus == 2) {
      //     Fluttertoast.showToast(backgroundColor: Colors.orangeAccent, msg: "${AppLocalizations.of(context)?.translate('printer_connection_timeout')}");
      //   } else if (printStatus == 5) {
      //     Fluttertoast.showToast(backgroundColor: Colors.red, msg: AppLocalizations.of(context)!.translate('printing_error'));
      //   }
      // }
      // if (this.isLogOut == true) {
      //   openLogOutDialog();
      //   return;
      // }

      asyncQ.addJob((_) => printKitchenList(address));
      objectData = {
        'tb_branch_link_product': branchLinkProductList,
      };
      return {'status': '1', 'data': objectData};
    } else {
      return stockResponse;
    }

  }

}