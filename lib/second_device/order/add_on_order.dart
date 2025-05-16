import 'dart:convert';

import 'package:pos_system/notifier/app_setting_notifier.dart';
import 'package:pos_system/object/app_setting.dart';
import 'package:pos_system/second_device/order/place_order.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../database/pos_database.dart';
import '../../main.dart';
import '../../notifier/cart_notifier.dart';
import '../../notifier/table_notifier.dart';
import '../../object/cart_product.dart';
import '../../object/order_cache.dart';
import '../../object/table.dart';
import '../../object/table_use.dart';

class PlaceAddOrder extends PlaceOrder {

  Future<Map<String, dynamic>> placeOrder(CartModel cart, String address, String orderBy, String orderByUserId) async {
    Map<String, dynamic> objectData;
    Map<String, dynamic>? stockResponse = await checkOrderStock(cart);
    await initData();
    if(stockResponse == null){
      if(await checkTableStatus(cart) == true){
        if(checkIsTableSelectedInPaymentCart(cart) == false) {
          await createOrderCache(cart, orderBy, orderByUserId);
          await createOrderDetail(cart);
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
          AppSetting? data = await PosDatabase.instance.readAppSetting();
          if(data != null){
            if(data.print_kitchen_list == true) {
              asyncQ.addJob((_) => printKitchenList(address));
            }
          }
          Map<String, dynamic>? objectData = {'tb_branch_link_product': branchLinkProductList};
          TableModel.instance.changeContent(true);
          return {'status': '1', 'data': objectData};
        } else {
          branchLinkProductList = await PosDatabase.instance.readAllBranchLinkProduct();
          objectData = {
            'tb_branch_link_product': branchLinkProductList,
          };
          return {'status': '3', 'error': 'table_is_in_payment', 'data': objectData};
          // result = {'status': '3', 'error': "Table is selected in payment cart"};
          // branchLinkProductList = await PosDatabase.instance.readAllBranchLinkProduct();
          // throw Exception("Table are selected in payment cart");
        }
      } else {
        branchLinkProductList = await PosDatabase.instance.readAllBranchLinkProduct();
        objectData = {
          'tb_branch_link_product': branchLinkProductList,
        };
        return {'status': '3', 'error': 'table_not_in_used', 'data': objectData};
        // branchLinkProductList = await PosDatabase.instance.readAllBranchLinkProduct();
        // throw Exception("Table not in-used");
      }
    } else {
      return stockResponse;
    }
  }

  Future<List<PosTable>> checkCartTableStatus(List<PosTable> cartSelectedTable) async {
    List<PosTable> inUsedTable = [];
    for(int i = 0; i < cartSelectedTable.length; i++){
      List<PosTable> table = await PosDatabase.instance.checkPosTableStatus(cartSelectedTable[i].table_sqlite_id!);
      if(table[0].status == 1){
        inUsedTable.add(table[0]);
      }
    }
    return inUsedTable;
  }


  checkIsTableSelectedInPaymentCart(CartModel cart){
    bool isTableSelected = false;
    List<PosTable> inCartTableList = Provider.of<CartModel>(context, listen: false).selectedTable.where((e) => e.isInPaymentCart == true).toList();
    if(inCartTableList.isNotEmpty){
      for(int i = 0; i < cart.selectedTable.length; i++){
        for(int j = 0; j < inCartTableList.length; j++){
          if(cart.selectedTable[i].table_sqlite_id == inCartTableList[j].table_sqlite_id){
            isTableSelected = true;
            break;
          }
        }
      }
    }
    return isTableSelected;
  }

  @override
  Future<void> createOrderCache(CartModel cart, String orderBy, String orderByUserId) async {
    String dateTime = dateFormat.format(DateTime.now());
    final prefs = await SharedPreferences.getInstance();
    final int? branch_id = prefs.getInt('branch_id');
    final String? loginUser = prefs.getString('user');
    Map loginUserObject = json.decode(loginUser!);
    OrderCache orderCache = super.orderCache!;
    String batch = '';
    try {
      int? orderQueue = await generateOrderQueue(cart);
      batch = orderCache.batch_id!;
      // List<PosTable> inUsedTable = await checkCartTableStatus(cart.selectedTable);
      TableUse _tableUse = await PosDatabase.instance.readSpecificTableUseByKey(orderCache.table_use_key!);
      // List<TableUse> tableUseData = await PosDatabase.instance.readSpecificTableUseId(int.parse(_tableUseId));
      // TableUse _tableUse = tableUseData;
      if (batch != '') {
        //create order cache
        OrderCache data = await PosDatabase.instance.insertSqLiteOrderCache(OrderCache(
            order_cache_id: 0,
            order_cache_key: '',
            order_queue: orderQueue != null ? orderQueue.toString().padLeft(4, '0') : '',
            company_id: loginUserObject['company_id'].toString(),
            branch_id: branch_id.toString(),
            order_detail_id: '',
            custom_table_number: '',
            table_use_sqlite_id: _tableUse.table_use_sqlite_id.toString(),
            table_use_key: _tableUse.table_use_key,
            other_order_key: orderCache.order_cache_key,
            batch_id: batch,
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
            soft_delete: ''));
        orderCacheSqliteId = data.order_cache_sqlite_id.toString();
        await insertOrderCacheKey(data, dateTime);
        await insertOrderCacheKeyIntoTableUse(cart, data, dateTime);
      }
    } catch (e) {
      print('add_on_order, createOrderCache error: ${e}');
    }
  }

}