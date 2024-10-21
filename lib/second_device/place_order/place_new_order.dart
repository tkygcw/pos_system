import 'dart:convert';

import 'package:intl/intl.dart';
import 'package:pos_system/second_device/place_order/place_order.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../database/pos_database.dart';
import '../../main.dart';
import '../../notifier/app_setting_notifier.dart';
import '../../notifier/cart_notifier.dart';
import '../../notifier/table_notifier.dart';
import '../../object/cart_product.dart';
import '../../object/order_cache.dart';
import '../../object/table.dart';
import '../../object/table_use.dart';
import '../../object/table_use_detail.dart';

class PlaceNewDineInOrder extends PlaceOrder {
  static DateFormat dateFormat = DateFormat("yyyy-MM-dd HH:mm:ss");
  String _dateTime = dateFormat.format(DateTime.now());

  Future<Map<String, dynamic>> callCreateNewOrder(CartModel cart, String address, String orderBy, String orderByUserId) async {
    Map<String, dynamic> objectData;
    try{
      await initData();
      if(await checkTableStatus(cart) == false){
        await createTableUseID();
        await createTableUseDetail(cart);
        await createOrderCache(cart, orderBy, orderByUserId);
        await createOrderDetail(cart);
        if(cart.selectedOption == 'Dine in' && AppSettingModel.instance.table_order == 1) {
          await updatePosTable(cart);
        }

        //print check list
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
        asyncQ.addJob((_) => printKitchenList(address));
        objectData = {
          'tb_branch_link_product': branchLinkProductList,
        };
        if(AppSettingModel.instance.table_order == 1) {
          TableModel.instance.changeContent(true);
        }

        return {'status': '1', 'data': objectData};
      } else {
        List<PosTable> cartTable = cart.selectedTable;
        OrderCache posTableCache = (await PosDatabase.instance.readTableOrderCache(inUsedTable!.table_use_key!)).first;
        await createAddOrderCache(cart, orderBy, orderByUserId, posTableCache);
        await createOrderDetail(cart);
        await checkAllTableInCart(cartTable, posTableCache);
        branchLinkProductList = await PosDatabase.instance.readAllBranchLinkProduct();
        await printCheckList(orderBy);
        List<cartProductItem> ticketProduct = cart.cartNotifierItem.where((e) => e.allow_ticket == 1).toList();
        if(ticketProduct.isNotEmpty){
          await printReceipt.printProductTicket(printerList, int.parse(orderCacheSqliteId), ticketProduct);
        }
        asyncQ.addJob((_) => printKitchenList(address));
        objectData = {
          'tb_branch_link_product': branchLinkProductList,
        };
        if(AppSettingModel.instance.table_order == 1) {
          TableModel.instance.changeContent(true);
        }

        return {'status': '1', 'data': objectData};
      }
    }catch(e){
      return {'status': '4', 'exception': "New-order error: ${e.toString()}"};;
    }
  }

  @override
  Future<void> createOrderCache(CartModel cart, String orderBy, String orderByUserId) async {
    // TODO: implement createOrderCache
    final prefs = await SharedPreferences.getInstance();
    final int? branch_id = prefs.getInt('branch_id');
    final String? loginUser = prefs.getString('user');

    List<TableUse> _tableUse = [];
    Map loginUserObject = json.decode(loginUser!);
    String _tableUseId = '';
    String batch = '';
    try {
      batch = await batchChecking();
      // if (isAddOrder == true) {
      //   batch = cart.cartNotifierItem[0].first_cache_batch!;
      // } else {
      //   batch = await batchChecking();
      // }
      //check selected table is in use or not
      if (cart.selectedOption == 'Dine in' && AppSettingModel.instance.table_order != 0) {
        for (int i = 0; i < cart.selectedTable.length; i++) {
          List<TableUseDetail> useDetail = await PosDatabase.instance.readSpecificTableUseDetail(cart.selectedTable[i].table_sqlite_id!);
          if(AppSettingModel.instance.table_order == 1) {
            if (useDetail.isNotEmpty) {
              _tableUseId = useDetail[0].table_use_sqlite_id!;
            } else {
              _tableUseId = this.localTableUseId;
            }
          } else {
            _tableUseId = this.localTableUseId;
          }
        }
        List<TableUse> tableUseData = await PosDatabase.instance.readSpecificTableUseId(int.parse(_tableUseId));
        _tableUse = tableUseData;
      }

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
            order_queue: '',
            company_id: loginUserObject['company_id'].toString(),
            branch_id: branch_id.toString(),
            order_detail_id: '',
            table_use_sqlite_id: _tableUseId,
            table_use_key: _tableUse[0].table_use_key,
            batch_id: batch.toString().padLeft(6, '0'),
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
            created_at: _dateTime,
            updated_at: '',
            soft_delete: ''));
        orderCacheSqliteId = data.order_cache_sqlite_id.toString();
        //orderNumber = data.order_queue.toString();
        await insertOrderCacheKey(data, _dateTime);
        await insertOrderCacheKeyIntoTableUse(cart, data, _dateTime);
        // if(cart.selectedOption == 'Dine in'){
        //   await insertOrderCacheKeyIntoTableUse(cart, data, dateTime);
        // }
        // sync to cloud
        //syncOrderCacheToCloud(updatedCache);
        //cart.addOrder(data);
      }
    } catch (e) {
      print('createOrderCache error: ${e}');
    }
  }

  Future<void> createAddOrderCache(CartModel cart, String orderBy, String orderByUserId, OrderCache posTableCache) async {
    try {
      //create order cache
      OrderCache data = await PosDatabase.instance.insertSqLiteOrderCache(OrderCache(
          order_cache_id: 0,
          order_cache_key: '',
          order_queue: '',
          company_id: posTableCache.company_id,
          branch_id: posTableCache.branch_id,
          order_detail_id: '',
          table_use_sqlite_id: posTableCache.table_use_sqlite_id,
          table_use_key: posTableCache.table_use_key,
          batch_id: posTableCache.batch_id,
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
          created_at: _dateTime,
          updated_at: '',
          soft_delete: ''));
      orderCacheSqliteId = data.order_cache_sqlite_id.toString();
      await insertOrderCacheKey(data, _dateTime);
      // await insertOrderCacheKeyIntoTableUse(cart, data, _dateTime);
    } catch (e) {
      print('createAddOrderCache error: ${e}');
    }
  }

  Future<void> createSpecificTableUseDetail(PosTable posTable, OrderCache posTableCache) async {
    try {
      //create table use detail
      TableUseDetail tableUseDetailData = await PosDatabase.instance.insertSqliteTableUseDetail(TableUseDetail(
          table_use_detail_id: 0,
          table_use_detail_key: '',
          table_use_sqlite_id: posTableCache.table_use_sqlite_id,
          table_use_key: posTableCache.table_use_key,
          table_sqlite_id: posTable.table_sqlite_id.toString(),
          table_id: posTable.table_id.toString(),
          status: 0,
          sync_status: 0,
          created_at: _dateTime,
          updated_at: '',
          soft_delete: ''));
      await insertTableUseDetailKey(tableUseDetailData, _dateTime);
    } catch (e) {
      print("createSpecificTableUseDetail error: ${e}");
    }
  }

  Future<void> checkAllTableInCart(List<PosTable> cartTable, OrderCache posTableCache) async {
    for(final posTable in cartTable){
      List<PosTable> table = await PosDatabase.instance.checkPosTableStatus(posTable.table_sqlite_id!);
      if(table.first.status == 0){
        await createSpecificTableUseDetail(table.first, posTableCache);
        await updateSpecificTable(table.first);
      }
    }
  }

  Future<void> updateSpecificTable(PosTable posTable) async {
    PosTable posTableData = PosTable(
        table_sqlite_id: posTable.table_sqlite_id,
        table_use_detail_key: tableUseDetailKey,
        table_use_key: tableUseKey,
        status: 1,
        updated_at: _dateTime);
    await PosDatabase.instance.updateCartPosTableStatus(posTableData);
  }

}