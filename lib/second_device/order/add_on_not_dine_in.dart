import 'dart:convert';

import 'package:pos_system/database/pos_database.dart';
import 'package:pos_system/notifier/cart_notifier.dart';
import 'package:pos_system/object/order_cache.dart';
import 'package:pos_system/second_device/order/place_order.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../main.dart';
import '../../notifier/table_notifier.dart';
import '../../object/cart_product.dart';

class PlaceNotDineInAddOrder extends PlaceOrder {
  final PosDatabase _posDatabase = PosDatabase.instance;
  OrderCache addOnOrderCache;

  PlaceNotDineInAddOrder({required this.addOnOrderCache});

  @override
  Future<Map<String, dynamic>> placeOrder(CartModel cart, String address, String orderBy, String orderByUserId) async {
    try{
      await initData();
      await createOrderCache(cart, orderBy, orderByUserId);
      await createOrderDetail(cart);
      TableModel.instance.changeContent(true);
      await printCheckList(orderBy);
      List<cartProductItem> ticketProduct = cart.cartNotifierItem.where((e) => e.allow_ticket == 1 && e.status == 0).toList();
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
      asyncQ.addJob((_) => printKitchenList(address));
      Map<String, dynamic>? objectData = {'tb_branch_link_product': branchLinkProductList};
      return {'status': '1', 'data': objectData};
    }catch(e, s){
      print("placeOrder error: $e, stacktrace: $s");
      rethrow;
    }
  }

  @override
  Future<void> createOrderCache(CartModel cart, String orderBy, String orderByUserId) async {
    try{
      String dateTime = dateFormat.format(DateTime.now());
      final prefs = await SharedPreferences.getInstance();
      final int? branch_id = prefs.getInt('branch_id');
      final String? loginUser = prefs.getString('user');
      Map loginUserObject = json.decode(loginUser!);
      int? orderQueue = await generateOrderQueue(cart);

      OrderCache insertData = OrderCache(
          order_cache_id: 0,
          order_cache_key: '',
          order_queue: addOnOrderCache.order_queue!,
          company_id: loginUserObject['company_id'].toString(),
          branch_id: branch_id.toString(),
          order_detail_id: '',
          table_use_sqlite_id: '',
          table_use_key: '',
          other_order_key: addOnOrderCache.other_order_key,
          batch_id: addOnOrderCache.batch_id,
          dining_id: cart.selectedOptionId,
          order_sqlite_id: '',
          order_key: '',
          order_by: orderBy,
          order_by_user_id: orderByUserId,
          cancel_by: '',
          cancel_by_user_id: '',
          customer_id: '0',
          total_amount: cart.subtotal,
          qr_order: 0,
          qr_order_table_sqlite_id: '',
          qr_order_table_id: '',
          accepted: 0,
          payment_status: 0,
          sync_status: 0,
          created_at: dateTime,
          updated_at: '',
          soft_delete: '');
      OrderCache data = await _posDatabase.insertSqLiteOrderCache(insertData);
      orderCacheSqliteId = data.order_cache_sqlite_id.toString();
      await insertOrderCacheKey(data, dateTime);
    }catch(e, s){
      print("createOrderCache error: $e, stacktrace: $s");
      rethrow;
    }
  }
  
}