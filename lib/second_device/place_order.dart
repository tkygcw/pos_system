import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:assets_audio_player/assets_audio_player.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pos_system/object/app_setting.dart';
import 'package:pos_system/second_device/server.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:crypto/crypto.dart';
import 'package:awesome_snackbar_content/awesome_snackbar_content.dart';

import '../database/pos_database.dart';
import '../fragment/custom_snackbar.dart';
import '../main.dart';
import '../notifier/app_setting_notifier.dart';
import '../notifier/cart_notifier.dart';
import '../notifier/fail_print_notifier.dart';
import '../notifier/table_notifier.dart';
import '../object/branch_link_product.dart';
import '../object/cart_product.dart';
import '../object/modifier_item.dart';
import '../object/order_cache.dart';
import '../object/order_detail.dart';
import '../object/order_modifier_detail.dart';
import '../object/print_receipt.dart';
import '../object/printer.dart';
import '../object/table.dart';
import '../object/table_use.dart';
import '../object/table_use_detail.dart';
import '../object/variant_group.dart';
import '../translation/AppLocalizations.dart';


abstract class PlaceOrder {
  BuildContext context = MyApp.navigatorKey.currentContext!;
  PrintReceipt printReceipt = PrintReceipt();
  List<Printer> printerList = [];
  List<BranchLinkProduct> branchLinkProductList = [];
  String localTableUseId = '';
  String tableUseKey = '', tableUseDetailKey = '', orderCacheSqliteId = '', orderCacheKey = '', orderDetailKey = '';


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
    List<TableUse> data = await PosDatabase.instance.readAllTableUseId(branch_id!);

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

    List<OrderCache> data = await PosDatabase.instance.readBranchOrderCache(branch_id!);
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

  // Future<void> callCreateNewNotDineOrder(CartModel cart) async {
  //   print("callCreateNewNotDineOrder");
  //   await createOrderCache(cart, isAddOrder: false);
  //   await createOrderDetail(cart);
  //   printCheckList();
  //   // if (_appSettingModel.autoPrintChecklist == true) {
  //   //   int printStatus = await printReceipt.printCheckList(printerList, int.parse(this.orderCacheId));
  //   //   if (printStatus == 1) {
  //   //     Fluttertoast.showToast(backgroundColor: Colors.red, msg: "${AppLocalizations.of(context)?.translate('printer_not_connected')}");
  //   //   } else if (printStatus == 2) {
  //   //     Fluttertoast.showToast(backgroundColor: Colors.orangeAccent, msg: "${AppLocalizations.of(context)?.translate('printer_connection_timeout')}");
  //   //   } else if (printStatus == 5) {
  //   //     Fluttertoast.showToast(backgroundColor: Colors.red, msg: AppLocalizations.of(context)!.translate('printing_error'));
  //   //   }
  //   // }
  //   // if (this.isLogOut == true) {
  //   //   openLogOutDialog();
  //   //   return;
  //   // }
  //
  //   printKitchenList();
  // }

  // Future<void> callCreateNewOrder(CartModel cart) async {
  //   if(await checkTableStatus(cart) == false){
  //     await createTableUseID();
  //     await createTableUseDetail(cart);
  //     await createOrderCache(cart, isAddOrder: false);
  //     await createOrderDetail(cart);
  //     await updatePosTable(cart);
  //     //print check list
  //     printCheckList();
  //     // if (_appSettingModel.autoPrintChecklist == true) {
  //     //   int printStatus = await printReceipt.printCheckList(printerList, int.parse(this.orderCacheId));
  //     //   if (printStatus == 1) {
  //     //     Fluttertoast.showToast(backgroundColor: Colors.red, msg: "${AppLocalizations.of(context)?.translate('printer_not_connected')}");
  //     //   } else if (printStatus == 2) {
  //     //     Fluttertoast.showToast(backgroundColor: Colors.orangeAccent, msg: "${AppLocalizations.of(context)?.translate('printer_connection_timeout')}");
  //     //   } else if (printStatus == 5) {
  //     //     Fluttertoast.showToast(backgroundColor: Colors.red, msg: AppLocalizations.of(context)!.translate('printing_error'));
  //     //   }
  //     // }
  //     printKitchenList();
  //   } else {
  //     throw Exception("Contain table in-used");
  //   }
  // }
  ///check table status
  ///
  ///if true, contain table in used
  ///
  ///else all table not in used
  Future<bool> checkTableStatus(CartModel cart) async {
    bool tableInUse = false;
    for(int i = 0; i < cart.selectedTable.length; i++){
      List<PosTable> table = await PosDatabase.instance.checkPosTableStatus(cart.selectedTable[i].table_sqlite_id!);
      if(table[0].status == 1){
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
        List<BranchLinkProduct> checkData = await PosDatabase.instance.readSpecificBranchLinkProduct(unitCartItem[i].branch_link_product_sqlite_id!);
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
      String flushbarStatus = '';
      List<OrderDetail>? returnData = await printReceipt.printKitchenList(printerList, int.parse(this.orderCacheSqliteId));
      if(returnData != null){
        List<OrderDetail> updatedBatch = updateBatch(returnData, address, batchId);
        if (updatedBatch.isNotEmpty) {
          sendFailPrintOrderDetail(address: address, failList: updatedBatch);
          FailPrintModel.instance.addAllFailedOrderDetail(orderDetailList: updatedBatch);
          CustomSnackBar.instance.showSnackBar(
              title: "${AppLocalizations.of(context)?.translate('error')}${AppLocalizations.of(context)?.translate('kitchen_printer_timeout')}",
              description: "${AppLocalizations.of(context)?.translate('please_try_again_later')}",
              contentType: ContentType.failure,
              playSound: true,
              playtime: 2);
          // playSound();
          // Flushbar(
          //   icon: Icon(Icons.error, size: 32, color: Colors.white),
          //   shouldIconPulse: false,
          //   title: "${AppLocalizations.of(context)?.translate('error')}${AppLocalizations.of(context)?.translate('kitchen_printer_timeout')}",
          //   message: "${AppLocalizations.of(context)?.translate('please_try_again_later')}",
          //   duration: Duration(seconds: 5),
          //   backgroundColor: Colors.red,
          //   messageColor: Colors.white,
          //   flushbarPosition: FlushbarPosition.TOP,
          //   maxWidth: 350,
          //   margin: EdgeInsets.all(8),
          //   borderRadius: BorderRadius.circular(8),
          //   padding: EdgeInsets.fromLTRB(40, 20, 40, 20),
          //   onTap: (flushbar) {
          //     flushbar.dismiss(true);
          //   },
          //   onStatusChanged: (status) {
          //     flushbarStatus = status.toString();
          //   },
          // )
          //   ..show(context);
          // Future.delayed(Duration(seconds: 3), () {
          //   print("status change: ${flushbarStatus}");
          //   if (flushbarStatus != "FlushbarStatus.IS_HIDING" && flushbarStatus != "FlushbarStatus.DISMISSED") playSound();
          // });
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
      TableUse tableUseData = await PosDatabase.instance.insertSqliteTableUse(data);
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
    return md5.convert(utf8.encode(bytes)).toString();
  }

  Future<void> insertTableUseKey(TableUse tableUse, String dateTime) async {
    tableUseKey = await generateTableUseKey(tableUse);
    if (tableUseKey != '') {
      TableUse tableUseObject = TableUse(table_use_key: tableUseKey, sync_status: 0, updated_at: dateTime, table_use_sqlite_id: tableUse.table_use_sqlite_id);
      await PosDatabase.instance.updateTableUseUniqueKey(tableUseObject);
    }
  }

  Future<void> createTableUseDetail(CartModel cart) async {
    DateFormat dateFormat = DateFormat("yyyy-MM-dd HH:mm:ss");
    String dateTime = dateFormat.format(DateTime.now());
    try {
      if(cart.selectedTable.isNotEmpty){
        for (int i = 0; i < cart.selectedTable.length; i++) {
          //create table use detail
          TableUseDetail tableUseDetailData = await PosDatabase.instance.insertSqliteTableUseDetail(TableUseDetail(
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
    return md5.convert(utf8.encode(bytes)).toString();
  }

  Future<void> insertTableUseDetailKey(TableUseDetail tableUseDetail, String dateTime) async {
    tableUseDetailKey = await generateTableUseDetailKey(tableUseDetail);
    if (tableUseDetailKey != '') {
      TableUseDetail tableUseDetailObject =
      TableUseDetail(table_use_detail_key: tableUseDetailKey, sync_status: 0, updated_at: dateTime, table_use_detail_sqlite_id: tableUseDetail.table_use_detail_sqlite_id);
      await PosDatabase.instance.updateTableUseDetailUniqueKey(tableUseDetailObject);
    }
  }

  Future<void> createOrderCache(CartModel cart) {
    // TODO: implement createOrderCache
    throw UnimplementedError();
  }

  Future<String> generateOrderCacheKey(OrderCache orderCache) async {
    final prefs = await SharedPreferences.getInstance();
    final int? device_id = prefs.getInt('device_id');
    var bytes = orderCache.created_at!.replaceAll(new RegExp(r'[^0-9]'), '') + orderCache.order_cache_sqlite_id.toString() + device_id.toString();
    return md5.convert(utf8.encode(bytes)).toString();
  }

  Future<void> insertOrderCacheKey(OrderCache orderCache, String dateTime) async {
    orderCacheKey = await generateOrderCacheKey(orderCache);
    if (orderCacheKey != '') {
      OrderCache orderCacheObject = OrderCache(order_cache_key: orderCacheKey, sync_status: 0, updated_at: dateTime, order_cache_sqlite_id: orderCache.order_cache_sqlite_id);
      await PosDatabase.instance.updateOrderCacheUniqueKey(orderCacheObject);
    }
  }

  Future<void> insertOrderCacheKeyIntoTableUse(CartModel cart, OrderCache orderCache, String dateTime) async {
    if (cart.selectedOption == "Dine in") {
      List<TableUse> checkTableUse = await PosDatabase.instance.readSpecificTableUseId(int.parse(orderCache.table_use_sqlite_id!));
      TableUse tableUseObject = TableUse(
          order_cache_key: orderCacheKey,
          sync_status: checkTableUse[0].sync_status == 0 ? 0 : 2,
          updated_at: dateTime,
          table_use_sqlite_id: int.parse(orderCache.table_use_sqlite_id!));
      await PosDatabase.instance.updateTableUseOrderCacheUniqueKey(tableUseObject);
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
          has_variant: newOrderDetailList[j].variant!.length == 0 ? '0' : '1',
          product_variant_name: getVariant2(newOrderDetailList[j]),
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
          created_at: dateTime,
          updated_at: '',
          soft_delete: '');
      OrderDetail orderDetailData = await PosDatabase.instance.insertSqliteOrderDetail(object);
      await updateProductStock(
          orderDetailData.branch_link_product_sqlite_id.toString(),
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
        await PosDatabase.instance.updateOrderDetailUniqueKey(orderDetailObject);
      }
    } catch (e) {
      print('insert order detail key error: ${e}');
    }
  }

  Future<String> generateOrderDetailKey(OrderDetail orderDetail) async {
    final prefs = await SharedPreferences.getInstance();
    final int? device_id = prefs.getInt('device_id');
    var bytes = orderDetail.created_at!.replaceAll(new RegExp(r'[^0-9]'), '') + orderDetail.order_detail_sqlite_id.toString() + device_id.toString();
    return md5.convert(utf8.encode(bytes)).toString();
  }

  Future<void> updateProductStock(String branch_link_product_sqlite_id, num quantity, String dateTime) async {
    num _totalStockQty = 0, updateStock = 0;
    BranchLinkProduct? object;
    try {
      List<BranchLinkProduct> checkData = await PosDatabase.instance.readSpecificBranchLinkProduct(branch_link_product_sqlite_id);
      if (checkData.isNotEmpty) {
        switch (checkData[0].stock_type) {
          case '1':
            {
              _totalStockQty = int.parse(checkData[0].daily_limit!) - quantity;
              object = BranchLinkProduct(
                  updated_at: dateTime, sync_status: 2, daily_limit: _totalStockQty.toString(), branch_link_product_sqlite_id: int.parse(branch_link_product_sqlite_id));
              updateStock = await PosDatabase.instance.updateBranchLinkProductDailyLimit(object);
            }
            break;
          case '2':
            {
              _totalStockQty = int.parse(checkData[0].stock_quantity!) - quantity;
              object = BranchLinkProduct(
                  updated_at: dateTime, sync_status: 2, stock_quantity: _totalStockQty.toString(), branch_link_product_sqlite_id: int.parse(branch_link_product_sqlite_id));
              updateStock = await PosDatabase.instance.updateBranchLinkProductStock(object);
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
          List<BranchLinkProduct> updatedData = await PosDatabase.instance.readSpecificBranchLinkProduct(branch_link_product_sqlite_id);
          branchLinkProductList.add(updatedData[0]);
        }
      }
    } catch (e) {
      print("cart update product stock error: $e");
    }
  }

  Future<void> createOrderModDetail({required List<ModifierItem> modItem, required String orderDetailSqliteId, required String dateTime}) async {
    for (int k = 0; k < modItem.length; k++) {
      OrderModifierDetail orderModifierDetailData = await PosDatabase.instance.insertSqliteOrderModifierDetail(OrderModifierDetail(
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
      await PosDatabase.instance.updateOrderModifierDetailUniqueKey(orderModifierDetailData);
    }
  }

  Future<String> generateOrderModifierDetailKey(OrderModifierDetail orderModifierDetail) async {
    final prefs = await SharedPreferences.getInstance();
    final int? device_id = prefs.getInt('device_id');
    var bytes = orderModifierDetail.created_at!.replaceAll(new RegExp(r'[^0-9]'), '') + orderModifierDetail.order_modifier_detail_sqlite_id.toString() + device_id.toString();
    return md5.convert(utf8.encode(bytes)).toString();
  }

  Future<void> updatePosTable(CartModel cart) async {
    try {
      DateFormat dateFormat = DateFormat("yyyy-MM-dd HH:mm:ss");
      String dateTime = dateFormat.format(DateTime.now());
      if(cart.selectedTable.isNotEmpty){
        for (int i = 0; i < cart.selectedTable.length; i++) {
          List<PosTable> result = await PosDatabase.instance.checkPosTableStatus(cart.selectedTable[i].table_sqlite_id!);
          List<TableUseDetail> tableUseDetail = await PosDatabase.instance.readSpecificTableUseDetail(cart.selectedTable[i].table_sqlite_id!);
          if (result[0].status == 0) {
            PosTable posTableData = PosTable(
                table_sqlite_id: cart.selectedTable[i].table_sqlite_id,
                table_use_detail_key: tableUseDetail[0].table_use_detail_key,
                table_use_key: tableUseKey,
                status: 1,
                updated_at: dateTime);
            await PosDatabase.instance.updateCartPosTableStatus(posTableData);
          }
        }
      }
    } catch (e) {
      print("update table error: $e");
    }
  }
}

class PlaceNewDineInOrder extends PlaceOrder {

  Future<Map<String, dynamic>> callCreateNewOrder(CartModel cart, String address, String orderBy) async {
    Map<String, dynamic> objectData;
    await initData();
    if(await checkTableStatus(cart) == false){
      await createTableUseID();
      await createTableUseDetail(cart);
      await createOrderCache(cart);
      await createOrderDetail(cart);
      await updatePosTable(cart);
      //print check list
      await printCheckList(orderBy);
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
      TableModel.instance.changeContent(true);
      return {'status': '1', 'data': objectData};
    } else {
      // throw Exception("Contain table in-used");
      branchLinkProductList = await PosDatabase.instance.readAllBranchLinkProduct();
      objectData = {
        'tb_branch_link_product': branchLinkProductList,
      };
      return {'status': '3', 'error': AppLocalizations.of(context)?.translate('table_is_used'), 'data': objectData};
    }
  }

  @override
  Future<void> createOrderCache(CartModel cart) async {
    // TODO: implement createOrderCache
    DateFormat dateFormat = DateFormat("yyyy-MM-dd HH:mm:ss");
    String dateTime = dateFormat.format(DateTime.now());
    final prefs = await SharedPreferences.getInstance();
    final int? branch_id = prefs.getInt('branch_id');
    final String? user = prefs.getString('pos_pin_user');
    final String? loginUser = prefs.getString('user');

    List<TableUse> _tableUse = [];
    Map userObject = json.decode(user!);
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
      for (int i = 0; i < cart.selectedTable.length; i++) {
        List<TableUseDetail> useDetail = await PosDatabase.instance.readSpecificTableUseDetail(cart.selectedTable[i].table_sqlite_id!);
        if (useDetail.isNotEmpty) {
          _tableUseId = useDetail[0].table_use_sqlite_id!;
        } else {
          _tableUseId = this.localTableUseId;
        }
      }
      List<TableUse> tableUseData = await PosDatabase.instance.readSpecificTableUseId(int.parse(_tableUseId));
      _tableUse = tableUseData;
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
            dining_id: cart.selectedOptionId,//this.diningOptionID.toString(),
            order_sqlite_id: '',
            order_key: '',
            order_by: userObject['name'].toString(),
            order_by_user_id: userObject['user_id'].toString(),
            cancel_by: '',
            cancel_by_user_id: '',
            customer_id: '0',
            total_amount: cart.subtotal,  //newOrderSubtotal.toStringAsFixed(2),
            qr_order: 0,
            qr_order_table_sqlite_id: '',
            qr_order_table_id: '',
            accepted: 0,
            sync_status: 0,
            created_at: dateTime,
            updated_at: '',
            soft_delete: ''));
        orderCacheSqliteId = data.order_cache_sqlite_id.toString();
        //orderNumber = data.order_queue.toString();
        await insertOrderCacheKey(data, dateTime);
        await insertOrderCacheKeyIntoTableUse(cart, data, dateTime);
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

}

class PlaceNotDineInOrder extends PlaceOrder {

  Future<Map<String, dynamic>> callCreateNewNotDineOrder(CartModel cart, String address, String orderBy) async {
    print("callCreateNewNotDineOrder");
    Map<String, dynamic> objectData;

    await initData();
    await createOrderCache(cart);
    await createOrderDetail(cart);
    await printCheckList(orderBy);
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
  }

  @override
  Future<void> createOrderCache(CartModel cart) async {
    // TODO: implement createOrderCache
    DateFormat dateFormat = DateFormat("yyyy-MM-dd HH:mm:ss");
    String dateTime = dateFormat.format(DateTime.now());
    final prefs = await SharedPreferences.getInstance();
    final int? branch_id = prefs.getInt('branch_id');
    final String? user = prefs.getString('pos_pin_user');
    final String? loginUser = prefs.getString('user');

    List<TableUse> _tableUse = [];
    Map userObject = json.decode(user!);
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
            table_use_sqlite_id: '',
            table_use_key: '',
            batch_id: batch.toString().padLeft(6, '0'),
            dining_id: cart.selectedOptionId,//this.diningOptionID.toString(),
            order_sqlite_id: '',
            order_key: '',
            order_by: userObject['name'].toString(),
            order_by_user_id: userObject['user_id'].toString(),
            cancel_by: '',
            cancel_by_user_id: '',
            customer_id: '0',
            total_amount: cart.subtotal,  //newOrderSubtotal.toStringAsFixed(2),
            qr_order: 0,
            qr_order_table_sqlite_id: '',
            qr_order_table_id: '',
            accepted: 0,
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

}

class PlaceAddOrder extends PlaceOrder {

  Future<Map<String, dynamic>> callAddOrderCache(CartModel cart, String address, String orderBy) async {
    Map<String, dynamic> objectData;
    await initData();
    if(await checkTableStatus(cart) == true){
      if(checkIsTableSelectedInPaymentCart(cart) == false) {
        await createOrderCache(cart);
        await createOrderDetail(cart);
        await printCheckList(orderBy);
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
        TableModel.instance.changeContent(true);
        return {'status': '1', 'data': objectData};
      } else {
        branchLinkProductList = await PosDatabase.instance.readAllBranchLinkProduct();
        objectData = {
          'tb_branch_link_product': branchLinkProductList,
        };
        return {'status': '3', 'error': AppLocalizations.of(context)?.translate('table_is_in_payment'), 'data': objectData};
        // result = {'status': '3', 'error': "Table is selected in payment cart"};
        // branchLinkProductList = await PosDatabase.instance.readAllBranchLinkProduct();
        // throw Exception("Table are selected in payment cart");
      }
    } else {
      branchLinkProductList = await PosDatabase.instance.readAllBranchLinkProduct();
      objectData = {
        'tb_branch_link_product': branchLinkProductList,
      };
      return {'status': '3', 'error': AppLocalizations.of(context)?.translate('table_not_in_use'), 'data': objectData};
      // branchLinkProductList = await PosDatabase.instance.readAllBranchLinkProduct();
      // throw Exception("Table not in-used");
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
  Future<void> createOrderCache(CartModel cart) async {
    // TODO: implement createOrderCache
    DateFormat dateFormat = DateFormat("yyyy-MM-dd HH:mm:ss");
    String dateTime = dateFormat.format(DateTime.now());
    final prefs = await SharedPreferences.getInstance();
    final int? branch_id = prefs.getInt('branch_id');
    final String? user = prefs.getString('pos_pin_user');
    final String? loginUser = prefs.getString('user');

    Map userObject = json.decode(user!);
    Map loginUserObject = json.decode(loginUser!);
    // String _tableUseId = '';
    String batch = '';
    try {
      batch = cart.cartNotifierItem[0].first_cache_batch!;
      List<PosTable> inUsedTable = await checkCartTableStatus(cart.selectedTable);
      TableUse tableUseData = await PosDatabase.instance.readSpecificTableUseByKey(inUsedTable[0].table_use_key!);
      // List<TableUse> tableUseData = await PosDatabase.instance.readSpecificTableUseId(int.parse(_tableUseId));
      TableUse _tableUse = tableUseData;
      if (batch != '') {
        //create order cache
        OrderCache data = await PosDatabase.instance.insertSqLiteOrderCache(OrderCache(
            order_cache_id: 0,
            order_cache_key: '',
            order_queue: '',
            company_id: loginUserObject['company_id'].toString(),
            branch_id: branch_id.toString(),
            order_detail_id: '',
            table_use_sqlite_id: _tableUse.table_use_sqlite_id.toString(),
            table_use_key: _tableUse.table_use_key,
            batch_id: batch.toString().padLeft(6, '0'),
            dining_id: cart.selectedOptionId,//this.diningOptionID.toString(),
            order_sqlite_id: '',
            order_key: '',
            order_by: userObject['name'].toString(),
            order_by_user_id: userObject['user_id'].toString(),
            cancel_by: '',
            cancel_by_user_id: '',
            customer_id: '0',
            total_amount: cart.subtotal,  //newOrderSubtotal.toStringAsFixed(2),
            qr_order: 0,
            qr_order_table_sqlite_id: '',
            qr_order_table_id: '',
            accepted: 0,
            sync_status: 0,
            created_at: dateTime,
            updated_at: '',
            soft_delete: ''));
        orderCacheSqliteId = data.order_cache_sqlite_id.toString();
        //orderNumber = data.order_queue.toString();
        await insertOrderCacheKey(data, dateTime);
        await insertOrderCacheKeyIntoTableUse(cart, data, dateTime);
      }
    } catch (e) {
      print('createOrderCache error: ${e}');
    }
  }

}
