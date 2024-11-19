import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:assets_audio_player/assets_audio_player.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pos_system/database/pos_firestore.dart';
import 'package:pos_system/fragment/custom_toastification.dart';
import 'package:pos_system/second_device/server.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:crypto/crypto.dart';

import '../../database/pos_database.dart';
import '../../main.dart';
import '../../notifier/app_setting_notifier.dart';
import '../../notifier/cart_notifier.dart';
import '../../notifier/fail_print_notifier.dart';
import '../../notifier/table_notifier.dart';
import '../../object/app_setting.dart';
import '../../object/branch_link_product.dart';
import '../../object/cart_product.dart';
import '../../object/modifier_item.dart';
import '../../object/order.dart';
import '../../object/order_cache.dart';
import '../../object/order_detail.dart';
import '../../object/order_modifier_detail.dart';
import '../../fragment/printing_layout/print_receipt.dart';
import '../../object/printer.dart';
import '../../object/table.dart';
import '../../object/table_use.dart';
import '../../object/table_use_detail.dart';
import '../../object/variant_group.dart';
import '../../translation/AppLocalizations.dart';
import '../../utils/Utils.dart';


abstract class PlaceOrder {
  final DateFormat dateFormat = DateFormat("yyyy-MM-dd HH:mm:ss");
  BuildContext context = MyApp.navigatorKey.currentContext!;
  PrintReceipt printReceipt = PrintReceipt();
  List<Printer> printerList = [];
  List<BranchLinkProduct> branchLinkProductList = [];
  String localTableUseId = '';
  String tableUseKey = '', tableUseDetailKey = '', orderCacheSqliteId = '', orderCacheKey = '', orderDetailKey = '';
  OrderCache? _orderCache;

  OrderCache? get orderCache => _orderCache;

  PosFirestore get posFirestore => PosFirestore.instance;

  PosDatabase get posDatabase => PosDatabase.instance;

  Future<void> createOrderCache(CartModel cart, String orderBy, String orderByUserId);

  Future<Map<String, dynamic>> placeOrder(CartModel cart, String address, String orderBy, String orderByUserId);

  initData() async {
    printerList = await printReceipt.readAllPrinters();
  }

  int randomBatch() {
    return Random().nextInt(1000000) + 1;
  }

  Color randomColor() {
    return Color(Random().nextInt(0xffffffff)).withAlpha(0xff);
  }

  String colorToHex(Color color) {
    String hex = '#' + color.value.toRadixString(16).substring(2);
    return hex;
  }

  int hexToInteger(String hexCode) {
    int temp = int.parse(hexCode, radix: 16);
    return temp;
  }

  Future<String> colorChecking() async {
    String hexCode = '';
    bool colorFound = false;
    bool found = false;
    int tempColor = 0;
    int matchColor = 0;
    int diff = 0;
    final prefs = await SharedPreferences.getInstance();
    final int? branch_id = prefs.getInt('branch_id');
    List<TableUse> data = await posDatabase.readAllTableUseId(branch_id!);

    while (colorFound == false) {
      /* change color */
      hexCode = colorToHex(randomColor());
      if (data.isNotEmpty) {
        for (int i = 0; i < data.length; i++) {
          if (hexCode == data[i].card_color) {
            found = false;
            break;
          } else {
            tempColor = hexToInteger(hexCode.replaceAll('#', ''));
            matchColor = hexToInteger(data[i].card_color!.replaceAll('#', ''));
            diff = tempColor - matchColor;
            if (diff.abs() < 160000) {
              print('color too close or not yet loop finish');
              print('diff: ${diff.abs()}');
              found = false;
              break;
            } else {
              print('color is ok');
              print('diff: ${diff}');
              if (i < data.length) {
                continue;
              }
            }
          }
        }
        found = true;
      } else {
        found = true;
        break;
      }
      if (found == true) colorFound = true;
    }
    return hexCode;
  }

  Future<String> batchChecking() async {
    int tempBatch = 0;
    bool batchFound = false;
    bool founded = false;
    final prefs = await SharedPreferences.getInstance();
    final int? branch_id = prefs.getInt('branch_id');

    List<OrderCache> data = await posDatabase.readBranchOrderCache(branch_id!);
    while (batchFound == false) {
      tempBatch = randomBatch();
      if (data.isNotEmpty) {
        for (int i = 0; i < data.length; i++) {
          if (tempBatch.toString() == data[i].batch_id!.toString()) {
            print('batch same!');
            founded = false;
            break;
          } else {
            if (i < data.length) {
              print('not yet loop finish');
              continue;
            }
          }
        }
        founded = true;
      } else {
        founded = true;
        break;
      }

      if (founded == true) batchFound = true;
    }
    return tempBatch.toString();
  }

  ///check table status
  ///
  ///if true, contain table in used
  ///
  ///else all table not in used
  Future<bool> checkTableStatus(CartModel cart) async {
    bool tableInUse = false;
    for(int i = 0; i < cart.selectedTable.length; i++){
      List<PosTable> table = await posDatabase.checkPosTableStatus(cart.selectedTable[i].table_sqlite_id!);
      if(table.first.status == 1){
        List<OrderCache> orderCache = await posDatabase.readTableOrderCache(table.first.table_use_key!);
        if(orderCache.isNotEmpty){
          _orderCache = orderCache.first;
        }
        tableInUse = true;
        break;
      }
    }
    return tableInUse;
  }

  Future<Map<String, dynamic>?> checkOrderStock(CartModel cartModel) async {
    List<cartProductItem> outOfStockItem = [];
    Map<String, dynamic>? result;
    //bool hasStock = false;
    List<cartProductItem> unitCartItem = cartModel.cartNotifierItem.where((e) => (e.unit == 'each' || e.unit == 'each_c') && e.status == 0).toList();
    if(unitCartItem.isNotEmpty){
      for(int i = 0 ; i < unitCartItem.length; i++){
        print("loop: $i");
        List<BranchLinkProduct> checkData = await posDatabase.readSpecificBranchLinkProduct(unitCartItem[i].branch_link_product_sqlite_id!);
        switch (checkData[0].stock_type) {
          case '1':
            {
             if(int.parse(checkData[0].daily_limit!) < unitCartItem[i].quantity!){
               outOfStockItem.add(unitCartItem[i]);
               branchLinkProductList.add(checkData[0]);
             }
            }
            break;
          case '2':
            {
              if(int.parse(checkData[0].stock_quantity!) < unitCartItem[i].quantity!){
                outOfStockItem.add(unitCartItem[i]);
                branchLinkProductList.add(checkData[0]);
              }
            }
            break;
        }
      }
    }
    if(outOfStockItem.isNotEmpty){
      Map<String, dynamic>? objectData = {
        'cartItem': outOfStockItem,
        'tb_branch_link_product': branchLinkProductList,
      };
      result = {'status': '2', 'data': objectData};
    }
    return result;
  }

  printCheckList(String order_by) async {
    if(AppSettingModel.instance.autoPrintChecklist == true){
      int printStatus = await printReceipt.printCheckList(printerList, int.parse(this.orderCacheSqliteId), order_by: order_by);
    }
  }

  List<OrderDetail> updateBatch(List<OrderDetail> orderDetail, String address, String batchId){
    List<OrderDetail> updatedList = [];
    for(int i = 0; i < orderDetail.length; i++){
      orderDetail[i].failPrintBatch = '$batchId-$address';
    }
    updatedList.addAll(orderDetail);
    return updatedList;
  }

  printKitchenList(String address) async {
    try {
      final String batchId = DateTime.now().toString().replaceAll(RegExp(r'[^0-9]'), '');
      List<OrderDetail>? returnData = await printReceipt.printKitchenList(printerList, int.parse(this.orderCacheSqliteId));
      if(returnData != null){
        List<OrderDetail> updatedBatch = updateBatch(returnData, address, batchId);
        if (updatedBatch.isNotEmpty) {
          sendFailPrintOrderDetail(address: address, failList: updatedBatch);
          FailPrintModel.instance.addAllFailedOrderDetail(orderDetailList: updatedBatch);
          ShowFailedPrintKitchenToast.showToast();
        }
      } else {
        //Fluttertoast.showToast(backgroundColor: Colors.red, msg: "${AppLocalizations.of(context)?.translate('no_printer_added')}");
      }
    } catch (e) {
      print("print kitchen list error: $e");
    }
  }

  sendFailPrintOrderDetail({String? address, List<OrderDetail>? failList}){
    Socket? client = Server.instance.clientList.firstWhereOrNull((e) => e.remoteAddress.address == address);
    if(client != null){
      Map<String, dynamic>? result = {'status': '1', 'action': '0', 'failedPrintOrderDetail': failList};
      client.write("${jsonEncode(result)}\n");
    }
  }

  playSound() {
    try {
      final assetsAudioPlayer = AssetsAudioPlayer();
      assetsAudioPlayer.open(
        Audio("audio/review.mp3"),
      );
    } catch (e) {
      print("Play Sound Error: ${e}");
    }
  }

  Future<void> createTableUseID() async {
    DateFormat dateFormat = DateFormat("yyyy-MM-dd HH:mm:ss");
    String dateTime = dateFormat.format(DateTime.now());
    final prefs = await SharedPreferences.getInstance();
    final int? branch_id = prefs.getInt('branch_id');
    String hexCode = '';
    try {
      hexCode = await colorChecking();
      TableUse data = TableUse(
          table_use_id: 0,
          branch_id: branch_id,
          table_use_key: '',
          order_cache_key: '',
          card_color: hexCode.toString(),
          status: 0,
          sync_status: 0,
          created_at: dateTime,
          updated_at: '',
          soft_delete: '');
      //create table use data
      TableUse tableUseData = await posDatabase.insertSqliteTableUse(data);
      localTableUseId = tableUseData.table_use_sqlite_id.toString();
      await insertTableUseKey(tableUseData, dateTime);
    } catch (e) {
      print(e);
    }
  }

  Future<String> generateTableUseKey(TableUse tableUse) async {
    final prefs = await SharedPreferences.getInstance();
    final int? device_id = prefs.getInt('device_id');
    var bytes = tableUse.created_at!.replaceAll(new RegExp(r'[^0-9]'), '') + tableUse.table_use_sqlite_id.toString() + device_id.toString();
    var md5Hash = md5.convert(utf8.encode(bytes));
    return Utils.shortHashString(hashCode: md5Hash);
  }

  Future<void> insertTableUseKey(TableUse tableUse, String dateTime) async {
    tableUseKey = await generateTableUseKey(tableUse);
    if (tableUseKey != '') {
      TableUse tableUseObject = TableUse(table_use_key: tableUseKey, sync_status: 0, updated_at: dateTime, table_use_sqlite_id: tableUse.table_use_sqlite_id);
      await posDatabase.updateTableUseUniqueKey(tableUseObject);
    }
  }

  Future<void> createTableUseDetail(CartModel cart) async {
    DateFormat dateFormat = DateFormat("yyyy-MM-dd HH:mm:ss");
    String dateTime = dateFormat.format(DateTime.now());
    try {
      if(cart.selectedTable.isNotEmpty){
        for (int i = 0; i < cart.selectedTable.length; i++) {
          //create table use detail
          TableUseDetail tableUseDetailData = await posDatabase.insertSqliteTableUseDetail(TableUseDetail(
              table_use_detail_id: 0,
              table_use_detail_key: '',
              table_use_sqlite_id: localTableUseId,
              table_use_key: tableUseKey,
              table_sqlite_id: cart.selectedTable[i].table_sqlite_id.toString(),
              table_id: cart.selectedTable[i].table_id.toString(),
              status: 0,
              sync_status: 0,
              created_at: dateTime,
              updated_at: '',
              soft_delete: ''));
          await insertTableUseDetailKey(tableUseDetailData, dateTime);
        }
      }
    } catch (e) {
      print(e);
    }
  }

  Future<String> generateTableUseDetailKey(TableUseDetail tableUseDetail) async {
    final prefs = await SharedPreferences.getInstance();
    final int? device_id = prefs.getInt('device_id');
    var bytes = tableUseDetail.created_at!.replaceAll(new RegExp(r'[^0-9]'), '') + tableUseDetail.table_use_detail_sqlite_id.toString() + device_id.toString();
    var md5Hash = md5.convert(utf8.encode(bytes));
    return Utils.shortHashString(hashCode: md5Hash);
  }

  Future<void> insertTableUseDetailKey(TableUseDetail tableUseDetail, String dateTime) async {
    tableUseDetailKey = await generateTableUseDetailKey(tableUseDetail);
    if (tableUseDetailKey != '') {
      TableUseDetail tableUseDetailObject =
      TableUseDetail(table_use_detail_key: tableUseDetailKey, sync_status: 0, updated_at: dateTime, table_use_detail_sqlite_id: tableUseDetail.table_use_detail_sqlite_id);
      await posDatabase.updateTableUseDetailUniqueKey(tableUseDetailObject);
    }
  }

  Future<String> generateOrderCacheKey(OrderCache orderCache) async {
    final prefs = await SharedPreferences.getInstance();
    final int? device_id = prefs.getInt('device_id');
    var bytes = orderCache.created_at!.replaceAll(new RegExp(r'[^0-9]'), '') + orderCache.order_cache_sqlite_id.toString() + device_id.toString();
    var md5Hash = md5.convert(utf8.encode(bytes));
    return Utils.shortHashString(hashCode: md5Hash);
  }

  Future<void> insertOrderCacheKey(OrderCache orderCache, String dateTime) async {
    orderCacheKey = await generateOrderCacheKey(orderCache);
    if (orderCacheKey != '') {
      OrderCache orderCacheObject = OrderCache(order_cache_key: orderCacheKey, sync_status: 0, updated_at: dateTime, order_cache_sqlite_id: orderCache.order_cache_sqlite_id);
      await posDatabase.updateOrderCacheUniqueKey(orderCacheObject);
    }
  }

  Future<void> insertOrderCacheKeyIntoTableUse(CartModel cart, OrderCache orderCache, String dateTime) async {
    if (cart.selectedOption == "Dine in" && AppSettingModel.instance.table_order == 1) {
      List<TableUse> checkTableUse = await posDatabase.readSpecificTableUseId(int.parse(orderCache.table_use_sqlite_id!));
      TableUse tableUseObject = TableUse(
          order_cache_key: orderCacheKey,
          sync_status: checkTableUse[0].sync_status == 0 ? 0 : 2,
          updated_at: dateTime,
          table_use_sqlite_id: int.parse(orderCache.table_use_sqlite_id!));
      await posDatabase.updateTableUseOrderCacheUniqueKey(tableUseObject);
    }
  }

  String getVariant2(cartProductItem object) {
    List<String?> variant = [];
    String result = '';
    var length = object.variant!.length;
    for (int i = 0; i < length; i++) {
      VariantGroup group = object.variant![i];
      for (int j = 0; j < group.child!.length; j++) {
        if (group.child![j].isSelected!) {
          variant.add(group.child![j].name!);
          result = variant.toString().replaceAll('[', '').replaceAll(']', '').replaceAll(",", " |");
        }
      }
    }
    return result;
  }

  Future<void> createOrderDetail(CartModel cart) async {
    DateFormat dateFormat = DateFormat("yyyy-MM-dd HH:mm:ss");
    String dateTime = dateFormat.format(DateTime.now());

    ///loop cart item & create order detail
    List<cartProductItem> newOrderDetailList = cart.cartNotifierItem.where((item) => item.status == 0).toList();
    for (int j = 0; j < newOrderDetailList.length; j++) {
      OrderDetail object = OrderDetail(
          order_detail_id: 0,
          order_detail_key: '',
          order_cache_sqlite_id: orderCacheSqliteId,
          order_cache_key: orderCacheKey,
          branch_link_product_sqlite_id: newOrderDetailList[j].branch_link_product_sqlite_id,
          category_sqlite_id: newOrderDetailList[j].category_sqlite_id,
          category_name: newOrderDetailList[j].category_name,
          productName: newOrderDetailList[j].product_name,
          has_variant: newOrderDetailList[j].productVariantName == '' ? '0' : '1',
          product_variant_name: newOrderDetailList[j].productVariantName,
          price: newOrderDetailList[j].price,
          original_price: newOrderDetailList[j].base_price,
          quantity: newOrderDetailList[j].quantity.toString(),
          remark: newOrderDetailList[j].remark,
          account: '',
          edited_by: '',
          edited_by_user_id: '',
          cancel_by: '',
          cancel_by_user_id: '',
          status: 0,
          sync_status: 0,
          unit: newOrderDetailList[j].unit,
          per_quantity_unit: newOrderDetailList[j].per_quantity_unit,
          product_sku: newOrderDetailList[j].product_sku,
          created_at: dateTime,
          updated_at: '',
          soft_delete: '');
      OrderDetail orderDetailData = await posDatabase.insertSqliteOrderDetail(object);
      await updateProductStock(
          orderDetailData.branch_link_product_sqlite_id.toString(),
          newOrderDetailList[j].branch_link_product_id!,
          int.tryParse(orderDetailData.quantity!) != null ? int.parse(orderDetailData.quantity!) : double.parse(orderDetailData.quantity!),
          dateTime);

      ///insert order detail key
      await insertOrderDetailKey(orderDetailData, dateTime);

      ///insert order modifier detail
      if (newOrderDetailList[j].checkedModifierItem!.isNotEmpty) {
        List<ModifierItem> modItem = newOrderDetailList[j].checkedModifierItem!;
        await createOrderModDetail(modItem: modItem, orderDetailSqliteId: orderDetailData.order_detail_sqlite_id.toString(), dateTime: dateTime);
      }
    }
  }

  Future<void> insertOrderDetailKey(OrderDetail orderDetail, String dateTime) async {
    try {
      orderDetailKey = await generateOrderDetailKey(orderDetail);
      if (orderDetailKey != '') {
        OrderDetail orderDetailObject =
        OrderDetail(order_detail_key: orderDetailKey, sync_status: 0, updated_at: dateTime, order_detail_sqlite_id: orderDetail.order_detail_sqlite_id);
        await posDatabase.updateOrderDetailUniqueKey(orderDetailObject);
      }
    } catch (e) {
      print('insert order detail key error: ${e}');
    }
  }

  Future<String> generateOrderDetailKey(OrderDetail orderDetail) async {
    final prefs = await SharedPreferences.getInstance();
    final int? device_id = prefs.getInt('device_id');
    var bytes = orderDetail.created_at!.replaceAll(new RegExp(r'[^0-9]'), '') + orderDetail.order_detail_sqlite_id.toString() + device_id.toString();
    var md5Hash = md5.convert(utf8.encode(bytes));
    return Utils.shortHashString(hashCode: md5Hash);
  }

  Future<void> updateProductStock(String branch_link_product_sqlite_id, int branchLinkProductId, num quantity, String dateTime) async {
    num _totalStockQty = 0, updateStock = 0;
    BranchLinkProduct? object;
    try {
      List<BranchLinkProduct> checkData = await posDatabase.readSpecificBranchLinkProduct(branch_link_product_sqlite_id);
      if (checkData.isNotEmpty) {
        switch (checkData[0].stock_type) {
          case '1':
            {
              _totalStockQty = int.parse(checkData[0].daily_limit!) - quantity;
              object = BranchLinkProduct(
                  updated_at: dateTime,
                  sync_status: 2,
                  daily_limit: _totalStockQty.toString(),
                  branch_link_product_id: branchLinkProductId,
                  branch_link_product_sqlite_id: int.parse(branch_link_product_sqlite_id));
              updateStock = await posDatabase.updateBranchLinkProductDailyLimit(object);
              posFirestore.updateBranchLinkProductDailyLimit(object);
            }
            break;
          case '2':
            {
              _totalStockQty = int.parse(checkData[0].stock_quantity!) - quantity;
              object = BranchLinkProduct(
                  updated_at: dateTime,
                  sync_status: 2,
                  stock_quantity: _totalStockQty.toString(),
                  branch_link_product_id: branchLinkProductId,
                  branch_link_product_sqlite_id: int.parse(branch_link_product_sqlite_id));
              updateStock = await posDatabase.updateBranchLinkProductStock(object);
              posFirestore.updateBranchLinkProductStock(object);
            }
            break;
          default:
            {
              updateStock = 0;
            }
            break;
        }
        //return updated value
        if (updateStock == 1) {
          List<BranchLinkProduct> updatedData = await posDatabase.readSpecificBranchLinkProduct(branch_link_product_sqlite_id);
          branchLinkProductList.add(updatedData[0]);
        }
      }
    } catch (e) {
      print("cart update product stock error: $e");
    }
  }

  Future<void> createOrderModDetail({required List<ModifierItem> modItem, required String orderDetailSqliteId, required String dateTime}) async {
    for (int k = 0; k < modItem.length; k++) {
      OrderModifierDetail orderModifierDetailData = await posDatabase.insertSqliteOrderModifierDetail(OrderModifierDetail(
          order_modifier_detail_id: 0,
          order_modifier_detail_key: '',
          order_detail_sqlite_id: orderDetailSqliteId,
          order_detail_id: '0',
          order_detail_key: orderDetailKey,
          mod_item_id: modItem[k].mod_item_id.toString(),
          mod_name: modItem[k].name,
          mod_price: modItem[k].price,
          mod_group_id: modItem[k].mod_group_id.toString(),
          sync_status: 0,
          created_at: dateTime,
          updated_at: '',
          soft_delete: ''));
      //insert unique key
      await insertOrderModifierDetailKey(orderModifierDetailData, dateTime);
    }
  }

  Future<void> insertOrderModifierDetailKey(OrderModifierDetail orderModifierDetail, String dateTime) async {
    String orderModifierDetailKey = await generateOrderModifierDetailKey(orderModifierDetail);
    if (orderModifierDetailKey != '') {
      OrderModifierDetail orderModifierDetailData = OrderModifierDetail(
          order_modifier_detail_key: orderModifierDetailKey,
          updated_at: dateTime,
          sync_status: orderModifierDetail.sync_status == 0 ? 0 : 2,
          order_modifier_detail_sqlite_id: orderModifierDetail.order_modifier_detail_sqlite_id);
      await posDatabase.updateOrderModifierDetailUniqueKey(orderModifierDetailData);
    }
  }

  Future<String> generateOrderModifierDetailKey(OrderModifierDetail orderModifierDetail) async {
    final prefs = await SharedPreferences.getInstance();
    final int? device_id = prefs.getInt('device_id');
    var bytes = orderModifierDetail.created_at!.replaceAll(new RegExp(r'[^0-9]'), '') + orderModifierDetail.order_modifier_detail_sqlite_id.toString() + device_id.toString();
    var md5Hash = md5.convert(utf8.encode(bytes));
    return Utils.shortHashString(hashCode: md5Hash);
  }

  Future<void> updatePosTable(CartModel cart) async {
    try {
      DateFormat dateFormat = DateFormat("yyyy-MM-dd HH:mm:ss");
      String dateTime = dateFormat.format(DateTime.now());
      if(cart.selectedTable.isNotEmpty){
        for (int i = 0; i < cart.selectedTable.length; i++) {
          List<PosTable> result = await posDatabase.checkPosTableStatus(cart.selectedTable[i].table_sqlite_id!);
          List<TableUseDetail> tableUseDetail = await posDatabase.readSpecificTableUseDetail(cart.selectedTable[i].table_sqlite_id!);
          if (result[0].status == 0) {
            PosTable posTableData = PosTable(
                table_sqlite_id: cart.selectedTable[i].table_sqlite_id,
                table_use_detail_key: tableUseDetail[0].table_use_detail_key,
                table_use_key: tableUseKey,
                status: 1,
                updated_at: dateTime);
            await posDatabase.updateCartPosTableStatus(posTableData);
          }
        }
      }
    } catch (e) {
      print("update table error: $e");
    }
  }

  Future<int?> generateOrderQueue(CartModel cart) async {
    print("generateOrderQueue called");
    final prefs = await SharedPreferences.getInstance();
    final int? branch_id = prefs.getInt('branch_id');
    AppSetting? localSetting = await posDatabase.readLocalAppSetting(branch_id.toString());
    if(localSetting!.enable_numbering == 1 &&
        ((localSetting.table_order != 0 && cart.selectedOption != 'Dine in') ||
            localSetting.table_order == 0)) {
      int orderQueue = localSetting.starting_number!;
      try {
        List<Order> orderList = await posDatabase.readLatestOrder();;
        List<OrderCache> orderCacheList = await posDatabase.readAllOrderCache();;
        List<Order> latestNotDineInOrder = await posDatabase.readLatestNotDineInOrder();
        List<OrderCache> notDineInOrderCache = await posDatabase.readAllNotDineInOrderCache();
        // not yet make settlement
        if(orderList.isNotEmpty) {
          if(localSetting.table_order != 0) {
            if(latestNotDineInOrder.isNotEmpty) {
              if(latestNotDineInOrder.first.settlement_key! == '') {
                if(int.tryParse(notDineInOrderCache.first.order_queue!) == null || int.parse(notDineInOrderCache.first.order_queue!) >= 9999) {
                  orderQueue = localSetting.starting_number!;
                }
                else {
                  orderQueue = int.parse(notDineInOrderCache.first.order_queue!) + 1;
                }
              }
            } else {
              if(notDineInOrderCache.isNotEmpty && notDineInOrderCache.first.order_key == '') {
                orderQueue = int.parse(notDineInOrderCache.first.order_queue!) + 1;
              } else {
                orderQueue = localSetting.starting_number!;
              }
            }
          } else {
            if(orderList.first.settlement_key! == '') {
              if(int.tryParse(orderCacheList.first.order_queue!) == null || int.parse(orderCacheList.first.order_queue!) >= 9999) {
                orderQueue = localSetting.starting_number!;
              }
              else {
                orderQueue = int.parse(orderCacheList[0].order_queue!) + 1;
              }
            } else {
              // after settlement
              if(orderCacheList.first.order_key == '' && orderCacheList.first.cancel_by == '') {
                orderQueue = int.parse(orderCacheList[0].order_queue!) + 1;
              } else {
                orderQueue = localSetting.starting_number!;
              }
            }
          }
        } else {
          if(localSetting.table_order != 0) {
            if(notDineInOrderCache.isNotEmpty && notDineInOrderCache.first.order_key == '') {
              orderQueue = int.parse(notDineInOrderCache.first.order_queue!) + 1;
            } else {
              orderQueue = localSetting.starting_number!;
            }
          } else {
            if(orderCacheList.isNotEmpty && orderCacheList.first.order_key == '') {
              orderQueue = int.parse(orderCacheList.first.order_queue!) + 1;
            } else {
              orderQueue = localSetting.starting_number!;
            }
          }
        }
        return orderQueue;
      } catch(e) {
        print("generateOrderQueue error: $e");
        return orderQueue = localSetting.starting_number!;
      }
    }
    return null;
  }
}

