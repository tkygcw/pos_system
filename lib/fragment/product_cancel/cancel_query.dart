import 'dart:convert';

import 'package:f_logs/model/flog/flog.dart';
import 'package:intl/intl.dart';
import 'package:pos_system/database/pos_database.dart';
import 'package:pos_system/database/pos_firestore.dart';
import 'package:pos_system/object/branch_link_modifier.dart';
import 'package:pos_system/object/cart_product.dart';
import 'package:pos_system/object/ingredient_branch_link_modifier.dart';
import 'package:pos_system/object/ingredient_branch_link_product.dart';
import 'package:pos_system/object/ingredient_company_link_branch.dart';
import 'package:pos_system/object/ingredient_movement.dart';
import 'package:pos_system/object/order_modifier_detail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:crypto/crypto.dart';

import '../../object/branch_link_product.dart';
import '../../object/categories.dart';
import '../../object/dining_option.dart';
import '../../object/order_cache.dart';
import '../../object/order_detail.dart';
import '../../object/order_detail_cancel.dart';
import '../../object/product.dart';
import '../../object/table.dart';
import '../../object/table_use.dart';
import '../../object/table_use_detail.dart';
import '../../object/user.dart';
import '../../utils/Utils.dart';

class CancelQuery{
  final DateFormat _dateFormat = DateFormat("yyyy-MM-dd HH:mm:ss");
  String _dateTime = '';
  String _reason = '';
  bool _restock = false;
  late final OrderDetail _orderDetail;
  late final List<OrderModifierDetail> _cartOrderModDetailList;
  late final cartProductItem _cartItem;
  late final num _cancelQuantity;
  late final User _user;
  late final _transaction;

  CancelQuery({
    required User user,
    required var transaction,
    required cartProductItem widgetCartItem,
    required num simpleIntInput,
    required OrderDetail orderDetail,
    required List<OrderModifierDetail> cartOrderModDetailList,
    bool? restock,
    String? reason,

  }) {
    this._user = user;
    this._transaction = transaction;
    this._dateTime = _dateFormat.format(DateTime.now());
    this._cartItem = widgetCartItem;
    this._cancelQuantity = simpleIntInput;
    this._orderDetail = orderDetail;
    this._cartOrderModDetailList = cartOrderModDetailList;
    this._restock = restock ?? this._restock;
    this._reason = reason ?? this._reason;
 }

  Future<void> callDeleteAllOrder({
    required List<TableUseDetail> cartTableUseDetail,
    required String currentTableUseId,
    required String currentPage,
    required OrderCache orderCache}) async {
    try{
      print('delete all order called');
      if (currentPage != 'other_order') {
        await _deleteCurrentTableUseDetail(currentTableUseId);
        await _deleteCurrentTableUseId(int.parse(currentTableUseId));
        await _updatePosTableStatus(cartTableUseDetail: cartTableUseDetail);
      }
      await callDeleteOrderDetail(deleteOrderCache: true, cartOrderCache: orderCache);
    }catch(e, stackTrace){
      FLog.error(
        className: "adjust_qty_dialog",
        text: "callDeleteAllOrder error",
        exception: "Error: $e, StackTrace: $stackTrace",
      );
      rethrow;
    }
  }

  _updatePosTableStatus({required List<TableUseDetail> cartTableUseDetail}) async {
    try{
      // PosTable? _data;
      for (int i = 0; i < cartTableUseDetail.length; i++) {
        //update all table to unused
        PosTable posTableData = PosTable(
          table_use_detail_key: '',
          table_use_key: '',
          status: 0,
          updated_at: _dateTime,
          table_sqlite_id: int.parse(cartTableUseDetail[i].table_sqlite_id!),
        );
        int updatedStatus = await _updateSqlitePosTableStatus(posTableData);
        // int updatedStatus = await posDatabase.updatePosTableStatus(posTableData);
        // int removeKey = await posDatabase.removePosTableTableUseDetailKey(posTableData);
        // if (updatedStatus == 1) {
        //   List<PosTable> posTable = await posDatabase.readSpecificTable(posTableData.table_sqlite_id.toString());
        //   if (posTable[0].sync_status == 2) {
        //     _data = posTable[0];
        //   }
        // }
        // _posTableValue.add(jsonEncode(posTableData));
      }
      // table_value = _posTableValue.toString();
      // return _data;
    }catch(e, stackTrace){
      FLog.error(
        className: "adjust_qty_dialog",
        text: "updatePosTableStatus error",
        exception: "Error: $e, StackTrace: $stackTrace",
      );
      rethrow;
    }
  }

  _deleteCurrentTableUseDetail(String currentTableUseId) async {
    List<String> _value = [];
    try {
      List<TableUseDetail> checkData = await _readAllTableUseDetail(currentTableUseId);
      // List<TableUseDetail> checkData = await posDatabase.readAllTableUseDetail(currentTableUseId);
      for (int i = 0; i < checkData.length; i++) {
        TableUseDetail tableUseDetailObject = checkData[i].copy(
          updated_at: _dateTime,
          sync_status: checkData[i].sync_status == 0 ? 0 : 2,
          status: 1,
        );
        int deleteStatus = await _deleteTableUseDetail(tableUseDetailObject);
        // int deleteStatus = await posDatabase.deleteTableUseDetail(tableUseDetailObject);
        // if (deleteStatus == 1) {
        //   _value.add(jsonEncode(tableUseDetailObject));
        //   table_use_detail_value = _value.toString();
        // }
      }
      //sync to cloud
      //syncTableUseDetail(_value.toString());
    } catch(e, stackTrace){
      FLog.error(
        className: "adjust_qty_dialog",
        text: "deleteCurrentTableUseDetail error",
        exception: "Error: $e, StackTrace: $stackTrace",
      );
      rethrow;
    }
  }

  _deleteCurrentTableUseId(int currentTableUseId) async {
    List<String> _value = [];
    try {
      TableUse? checkData = await _readSpecificTableUseIdByLocalId(currentTableUseId);
      // TableUse checkData = await posDatabase.readSpecificTableUseIdByLocalId(currentTableUseId);
      TableUse tableUseObject = checkData!.copy(
        updated_at: _dateTime,
        sync_status: checkData.sync_status == 0 ? 0 : 2,
        status: 1,
      );
      int deletedTableUse = await _deleteTableUseID(tableUseObject);
      // int deletedTableUse = await posDatabase.deleteTableUseID(tableUseObject);
      // if (deletedTableUse == 1) {
      //   //sync to cloud
      //   TableUse tableUseData = await posDatabase.readSpecificTableUseIdByLocalId(tableUseObject.table_use_sqlite_id!);
      //   _value.add(jsonEncode(tableUseObject));
      //   table_use_value = _value.toString();
      //   syncTableUseIdToCloud(_value.toString());
      // }
    } catch(e, stackTrace){
      FLog.error(
        className: "adjust_qty_dialog",
        text: "deleteCurrentTableUseId error",
        exception: "Error: $e, StackTrace: $stackTrace",
      );
      rethrow;
    }
  }

  Future<void> callDeleteOrderDetail({bool? deleteOrderCache, OrderCache? cartOrderCache}) async {
    try{
      await callUpdateOrderDetail();
      List<String> _value = [];
      OrderDetail orderDetailObject = OrderDetail(
        updated_at: _dateTime,
        sync_status: _orderDetail.sync_status == 0 ? 0 : 2,
        status: 1,
        cancel_by: _user.name,
        cancel_by_user_id: _user.user_id.toString(),
        order_detail_sqlite_id: int.parse(_cartItem.order_detail_sqlite_id!),
      );
      int deleteOrderDetailData = await _updateOrderDetailStatus(orderDetailObject);
      if(deleteOrderCache == true && deleteOrderDetailData == 1){
        await _deleteCurrentOrderCache(cartOrderCache!);
      }
      // int deleteOrderDetailData = await posDatabase.updateOrderDetailStatus(orderDetailObject);
      // if (deleteOrderDetailData == 1) {
      //   //await updateProductStock(orderDetailObject.branch_link_product_sqlite_id!, int.parse(orderDetailObject.quantity!), dateTime);
      //   //sync to cloud
      //   OrderDetail detailData = await cancelQuery.readSpecificOrderDetailByLocalId(orderDetailObject.order_detail_sqlite_id!);
      //   OrderDetail detailData = await posDatabase.readSpecificOrderDetailByLocalId(orderDetailObject.order_detail_sqlite_id!);
      //   _value.add(jsonEncode(detailData.syncJson()));
      //   order_detail_value = _value.toString();
      //   print('value: ${_value.toString()}');
      // }
      //syncUpdatedOrderDetailToCloud(_value.toString());
    }catch(e, stackTrace){
      FLog.error(
        className: "adjust_qty_dialog",
        text: "callDeleteOrderDetail error",
        exception: "Error: $e, StackTrace: $stackTrace",
      );
      rethrow;
    }
  }

  _deleteCurrentOrderCache(OrderCache cartOrderCache) async {
    print('delete order cache called');
    List<String> _orderCacheValue = [];
    try {
      OrderCache orderCacheObject = OrderCache(
        sync_status: cartOrderCache.sync_status == 0 ? 0 : 2,
        cancel_by: _user.name,
        cancel_by_user_id: _user.user_id.toString(),
        order_cache_sqlite_id: int.parse(_cartItem.order_cache_sqlite_id!),
      );
      int deletedOrderCache = await _cancelOrderCache(orderCacheObject);
      // int deletedOrderCache = await posDatabase.cancelOrderCache(orderCacheObject);
      //sync to cloud
      // if (deletedOrderCache == 1) {
      //   // await getOrderCacheValue(orderCacheObject);
      //   // OrderCache orderCacheData = await posDatabase.readSpecificOrderCacheByLocalId(orderCacheObject.order_cache_sqlite_id!);
      //   // if(orderCacheData.sync_status != 1){
      //   //   _orderCacheValue.add(jsonEncode(orderCacheData));
      //   // }
      //   // order_cache_value = _orderCacheValue.toString();
      //   //syncOrderCacheToCloud(_orderCacheValue.toString());
      // }
    }catch(e, stackTrace){
      FLog.error(
        className: "adjust_qty_dialog",
        text: "deleteCurrentOrderCache error",
        exception: "Error: $e, StackTrace: $stackTrace",
      );
      rethrow;
    }
  }

  Future<void> callUpdateOrderDetail() async {
    await _createOrderDetailCancel();
    await _updateOrderDetailQuantity();
  }

  _updateOrderDetailQuantity() async {
    List<String> _value = [];
    try{
      OrderDetail orderDetail = OrderDetail(
        updated_at: _dateTime,
        sync_status: _orderDetail.sync_status == 0 ? 0 : 2,
        status: 0,
        quantity: _getTotalQty(),
        order_detail_sqlite_id: int.parse(_cartItem.order_detail_sqlite_id!),
        branch_link_product_sqlite_id: _cartItem.branch_link_product_sqlite_id,
      );
      // updateOrderDetailQuantity
      num data = await _updateSqliteOrderDetailQuantity(orderDetail);
      // num data = await posDatabase.updateOrderDetailQuantity(orderDetail);
      if (data == 1) {
        // readSpecificOrderDetailByLocalId
        OrderDetail updatedOrderDetail = await _readSpecificOrderDetailByLocalId(orderDetail.order_detail_sqlite_id!);
        // OrderDetail detailData = await posDatabase.readSpecificOrderDetailByLocalId(orderDetail.order_detail_sqlite_id!);
        OrderCache? orderCache = await _updateOrderCacheSubtotal(updatedOrderDetail.order_cache_sqlite_id!, updatedOrderDetail.price!);
        if(_restock){
          await _updateProductStock(updatedOrderDetail.branch_link_product_sqlite_id!);
          await _updateIngredientStock(updatedOrderDetail);
        }
        // _firestoreQROrderSync.updateOrderDetailAndCacheSubtotal(updatedOrderDetail, orderCache!);
        // _value.add(jsonEncode(updatedOrderDetail.syncJson()));
      }
      // order_detail_value = _value.toString();
    }catch(e, stackTrace){
      FLog.error(
        className: "adjust_qty_dialog",
        text: "updateOrderDetailQuantity error",
        exception: "Error: $e, StackTrace: $stackTrace",
      );
      rethrow;
    }
  }

  _updateProductStock(String branch_link_product_sqlite_id) async {
    List<String> _value = [];
    num _totalStockQty = 0, updateStock = 0;
    BranchLinkProduct? object;
    try{
      // readSpecificBranchLinkProduct
      List<BranchLinkProduct> checkData = await _readSpecificBranchLinkProduct(branch_link_product_sqlite_id);
      // List<BranchLinkProduct> checkData = await posDatabase.readSpecificBranchLinkProduct(branch_link_product_sqlite_id);
      if(checkData.isNotEmpty){
        switch(checkData.first.stock_type){
          case '1': {
            _totalStockQty = int.parse(checkData[0].daily_limit!) + _cancelQuantity;
            object = checkData.first.copy(
                updated_at: _dateTime,
                sync_status: 2,
                daily_limit: _totalStockQty.toString(),
                branch_link_product_sqlite_id: int.parse(branch_link_product_sqlite_id));
            updateStock = await _updateBranchLinkProductDailyLimit(object);
            // updateStock = await posDatabase.updateBranchLinkProductDailyLimit(object);
          }break;
          case'2': {
            _totalStockQty = int.parse(checkData[0].stock_quantity!) + _cancelQuantity;
            object = checkData.first.copy(
                updated_at: _dateTime,
                sync_status: 2,
                stock_quantity: _totalStockQty.toString(),
                branch_link_product_sqlite_id: int.parse(branch_link_product_sqlite_id));
            updateStock = await _updateBranchLinkProductStock(object);
            // updateStock = await posDatabase.updateBranchLinkProductStock(object);
          }break;
          // optimization required
          case '4': {
            final prefs = await SharedPreferences.getInstance();
            final int? branch_id = prefs.getInt('branch_id');
            List<IngredientBranchLinkProduct> detailData = await _readAllProductIngredient(checkData.first.branch_link_product_id.toString());
            List<int> ingredientList = [];
            for(int i =0; i < detailData.length; i++){
              IngredientBranchLinkProduct data1 = detailData[i];
              List<IngredientCompanyLinkBranch> ingredientCompanyLinkBranch = await _readSpecificIngredientCompanyLinkBranch(data1.ingredient_company_link_branch_id.toString());
              ingredientList.add(ingredientCompanyLinkBranch[0].ingredient_company_link_branch_id!);
            }
            for (var value in ingredientList) {
              List<IngredientCompanyLinkBranch> ingredientCompanyLinkBranch = await _readSpecificIngredientCompanyLinkBranch(value.toString());
              List<IngredientBranchLinkProduct> ingredientDetail = await _readSpecificProductIngredient(value.toString());
              int ingredientUsed = int.parse(ingredientCompanyLinkBranch[0].stock_quantity!) + (int.parse(_cancelQuantity.toString())*int.parse(ingredientDetail[0].ingredient_usage!));

              IngredientCompanyLinkBranch object = IngredientCompanyLinkBranch(
                updated_at: _dateTime,
                sync_status: 2,
                stock_quantity: ingredientUsed.toString(),
                ingredient_company_link_branch_id: value,
              );
              updateStock = await _updateIngredientCompanyLinkBranchStock(object);

              try{
                IngredientMovement ingredientMovement = IngredientMovement(
                    ingredient_movement_id: 0,
                    ingredient_movement_key: '',
                    branch_id: branch_id.toString(),
                    ingredient_company_link_branch_id: value.toString(),
                    order_cache_key: _orderDetail.order_cache_key,
                    order_detail_key: _orderDetail.order_detail_key,
                    order_modifier_detail_key: '',
                    type: 3,
                    movement: '+${(_cancelQuantity*int.parse(ingredientDetail[0].ingredient_usage!)).toString()}',
                    source: 0,
                    remark: '',
                    calculate_status: 1,
                    sync_status: 0,
                    created_at: _dateTime,
                    updated_at: '',
                    soft_delete: ''
                );
                IngredientMovement data = await _insertSqliteIngredientMovement(ingredientMovement);
                await _insertIngredientMovementKey(data, _dateTime);
              }catch(e){
                print("insertIngredientMovement error: $e");
                FLog.error(
                  className: "cart",
                  text: "ingredient movement insert failed",
                  exception: e,
                );
              }
            }
          }break;
          default: {
            updateStock = 0;
          }
        }
        // if (updateStock == 1) {
        //   List<BranchLinkProduct> updatedData = await posDatabase.readSpecificBranchLinkProduct(branch_link_product_sqlite_id);
        //   _value.add(jsonEncode(updatedData[0]));
        //   branch_link_product_value = _value.toString();
        // }
      }
    }catch(e, stackTrace){
      FLog.error(
        className: "cancel query",
        text: "updateProductStock error",
        exception: "Error: $e, StackTrace: $stackTrace",
      );
      rethrow;
    }

    //print('branch link product value in function: ${branch_link_product_value}');
    //sync to cloud
    //syncBranchLinkProductStock(value.toString());
  }

  _updateIngredientStock(OrderDetail updatedOrderDetail) async {
    print("_updateIngredientStock called");
    DateFormat dateFormat = DateFormat("yyyy-MM-dd HH:mm:ss");
    PosFirestore posFirestore = PosFirestore.instance;
    print("_updateIngredientStock 1");
    print("updatedOrderDetail.orderModifierDetail.length: ${_cartOrderModDetailList.length}");
    for(int j = 0; j < _cartOrderModDetailList.length; j++){
      print("_updateIngredientStock 2");
      List<BranchLinkModifier> modData = await _readBranchLinkModifier(_cartOrderModDetailList[j].mod_item_id.toString());
      if(modData.first.stock_type == 1){
        print("_updateIngredientStock 3");
        List<IngredientBranchLinkModifier> modIngredientData = await _readSpecificModifierIngredient(modData.first.branch_link_modifier_id.toString());
        List<IngredientCompanyLinkBranch> ingredientCompanyLinkBranch = await _readSpecificIngredientCompanyLinkBranch(modIngredientData[0].ingredient_company_link_branch_id!);
        print("_updateIngredientStock 4");
        int ingredientUsed = int.parse(ingredientCompanyLinkBranch[0].stock_quantity!) + (int.parse(_cancelQuantity.toString())*int.parse(modIngredientData[0].ingredient_usage!));
        print("_updateIngredientStock 5");
        IngredientCompanyLinkBranch object = IngredientCompanyLinkBranch(
          updated_at: _dateTime,
          sync_status: 2,
          stock_quantity: ingredientUsed.toString(),
          ingredient_company_link_branch_id: int.parse(modIngredientData[0].ingredient_company_link_branch_id!),
        );
        await _updateIngredientCompanyLinkBranchStock(object);
        print("_updateIngredientStock 6");
        posFirestore.updateIngredientCompanyLinkBranchStock(object);
        IngredientMovement ingredientMovement = IngredientMovement(
            ingredient_movement_id: 0,
            ingredient_movement_key: '',
            branch_id: ingredientCompanyLinkBranch[0].branch_id,
            ingredient_company_link_branch_id: ingredientCompanyLinkBranch[0].ingredient_company_link_branch_id.toString(),
            order_cache_key: updatedOrderDetail.order_cache_key,
            order_detail_key: updatedOrderDetail.order_detail_key,
            order_modifier_detail_key: _cartOrderModDetailList[j].order_modifier_detail_key,
            type: 3,
            movement: '+${(_cancelQuantity*int.parse(modIngredientData[0].ingredient_usage!)).toString()}',
            source: 0,
            remark: '',
            calculate_status: 1,
            sync_status: 0,
            created_at: dateFormat.format(DateTime.now()),
            updated_at: '',
            soft_delete: ''
        );
        IngredientMovement data = await _insertSqliteIngredientMovement(ingredientMovement);
        await _insertIngredientMovementKey(data, _dateTime);
      }
    }
  }

  Future<String> generateIngredientMovementKey(IngredientMovement ingredientMovement) async {
    final prefs = await SharedPreferences.getInstance();
    final int? device_id = prefs.getInt('device_id');
    var bytes = ingredientMovement.created_at!.replaceAll(new RegExp(r'[^0-9]'), '') + ingredientMovement.ingredient_movement_sqlite_id.toString() + device_id.toString();
    var md5Hash = md5.convert(utf8.encode(bytes));
    return Utils.shortHashString(hashCode: md5Hash);
  }

  Future<void> _insertIngredientMovementKey(IngredientMovement ingredientMovement, String dateTime) async {
    try {
      String key = await generateIngredientMovementKey(ingredientMovement);

      IngredientMovement data = IngredientMovement(
        updated_at: dateTime,
        sync_status: 0,
        ingredient_movement_key: key,
        ingredient_movement_sqlite_id: ingredientMovement.ingredient_movement_sqlite_id,
      );

      await _transaction.rawUpdate(
        'UPDATE $tableIngredientMovement '
            'SET updated_at = ?, sync_status = ?, ingredient_movement_key = ? '
            'WHERE ingredient_movement_sqlite_id = ?',
        [data.updated_at, data.sync_status, data.ingredient_movement_key, data.ingredient_movement_sqlite_id],
      );
    } catch (e, stackTrace) {
      print("_insertIngredientMovementKey Error: $e, StackTrace: $stackTrace");
      FLog.error(
        className: "_insertIngredientMovementKey",
        text: "Error inserting ingredient movement key",
        exception: "Error: $e, StackTrace: $stackTrace",
      );
      rethrow;
    }
  }

  Future<IngredientMovement> _insertSqliteIngredientMovement(IngredientMovement data) async {
    try {
      final id = await _transaction.rawInsert(
        'INSERT INTO $tableIngredientMovement (${data.toJson().keys.join(', ')}) VALUES (${List.filled(data.toJson().length, '?').join(', ')})',
        data.toJson().values.toList(),
      );

      return data.copy(ingredient_movement_sqlite_id: id);
    } catch (e, stackTrace) {
      print("_insertSqliteIngredientMovement Error: $e, StackTrace: $stackTrace");
      FLog.error(
        className: "_insertSqliteIngredientMovement",
        text: "Error inserting ingredient movement",
        exception: "Error: $e, StackTrace: $stackTrace",
      );
      rethrow;
    }
  }

  Future<int> _updateIngredientCompanyLinkBranchStock(IngredientCompanyLinkBranch data) async {
    try{
      return await _transaction.rawUpdate('UPDATE $tableIngredientCompanyLinkBranch SET updated_at = ?, sync_status = ?, stock_quantity = ? WHERE ingredient_company_link_branch_id = ?', [
        data.updated_at,
        data.sync_status,
        data.stock_quantity,
        data.ingredient_company_link_branch_id,
      ]);
    }catch(e, stackTrace){
      FLog.error(
        className: "cancel query",
        text: "_updateIngredientCompanyLinkBranchStock error",
        exception: "Error: $e, StackTrace: $stackTrace",
      );
      rethrow;
    }
  }

  Future<List<IngredientBranchLinkProduct>> _readSpecificProductIngredient(String ingredient_company_link_branch_id) async {
    try{
      final result = await _transaction.rawQuery('SELECT * '
          'FROM $tableIngredientBranchLinkProduct WHERE soft_delete = ? AND ingredient_company_link_branch_id = ?',
          ['', ingredient_company_link_branch_id]) as List<Map<String, Object?>>;

      return result.map((json) => IngredientBranchLinkProduct.fromJson(json)).toList();
    }catch(e, stackTrace){
      print("_readSpecificProductIngredient Error: $e, StackTrace: $stackTrace");
      FLog.error(
        className: "cancel query",
        text: "_readSpecificProductIngredient error",
        exception: "Error: $e, StackTrace: $stackTrace",
      );
      rethrow;
    }
  }

  Future<List<BranchLinkModifier>> _readBranchLinkModifier(String mod_item_id) async {
    try{
      final result = await _transaction.rawQuery('SELECT * FROM $tableBranchLinkModifier WHERE soft_delete = ? AND mod_item_id = ?',
          ['', mod_item_id]) as List<Map<String, Object?>>;

      return result.map((json) => BranchLinkModifier.fromJson(json)).toList();
    }catch(e, stackTrace){
      print("_readBranchLinkModifier Error: $e, StackTrace: $stackTrace");
      FLog.error(
        className: "cancel query",
        text: "_readBranchLinkModifier error",
        exception: "Error: $e, StackTrace: $stackTrace",
      );
      rethrow;
    }
  }

  Future<List<IngredientBranchLinkModifier>> _readSpecificModifierIngredient(String branch_link_modifier_id) async {
    try{
      final result = await _transaction.rawQuery('SELECT * FROM $tableIngredientBranchLinkModifier WHERE branch_link_modifier_id = ? AND soft_delete = ?',
          [branch_link_modifier_id, '']) as List<Map<String, Object?>>;

      return result.map((json) => IngredientBranchLinkModifier.fromJson(json)).toList();
    }catch(e, stackTrace){
      print("_readSpecificModifierIngredient Error: $e, StackTrace: $stackTrace");
      FLog.error(
        className: "cancel query",
        text: "_readSpecificModifierIngredient error",
        exception: "Error: $e, StackTrace: $stackTrace",
      );
      rethrow;
    }
  }

  Future<List<IngredientCompanyLinkBranch>> _readSpecificIngredientCompanyLinkBranch(String ingredient_company_link_branch_id) async {
    try{
      final result = await _transaction.rawQuery('SELECT * '
          'FROM $tableIngredientCompanyLinkBranch WHERE soft_delete = ? AND ingredient_company_link_branch_id = ?',
          ['', ingredient_company_link_branch_id]) as List<Map<String, Object?>>;

      return result.map((json) => IngredientCompanyLinkBranch.fromJson(json)).toList();
    }catch(e, stackTrace){
      print("_readSpecificIngredientCompanyLinkBranch Error: $e, StackTrace: $stackTrace");
      FLog.error(
        className: "cancel query",
        text: "_readSpecificIngredientCompanyLinkBranch error",
        exception: "Error: $e, StackTrace: $stackTrace",
      );
      rethrow;
    }
  }

  Future<List<IngredientBranchLinkProduct>> _readAllProductIngredient(String branch_link_product_id) async {
    try{
      final result = await _transaction.rawQuery('SELECT * '
          'FROM $tableIngredientBranchLinkProduct WHERE soft_delete = ? AND branch_link_product_id = ?',
          ['', branch_link_product_id]) as List<Map<String, Object?>>;

      return result.map((json) => IngredientBranchLinkProduct.fromJson(json)).toList();
    }catch(e, stackTrace){
      print("_readAllProductIngredient Error: $e, StackTrace: $stackTrace");
      FLog.error(
        className: "cancel query",
        text: "_readAllProductIngredient error",
        exception: "Error: $e, StackTrace: $stackTrace",
      );
      rethrow;
    }
  }

  Future<OrderCache?> _updateOrderCacheSubtotal(String orderCacheLocalId, String price) async {
    try{
      // readSpecificOrderCacheByLocalId
      OrderCache data = await _readSpecificOrderCacheByLocalId(int.parse(orderCacheLocalId));
      // OrderCache data = await posDatabase.readSpecificOrderCacheByLocalId(int.parse(orderCacheLocalId));
      OrderCache orderCache = data.copy(
          order_cache_sqlite_id: data.order_cache_sqlite_id,
          total_amount: _getSubtotal(double.parse(data.total_amount!), price, _cancelQuantity),
          sync_status: data.sync_status == 0 ? 0 : 2,
          updated_at: _dateTime);
      // updateOrderCacheSubtotal
      int status = await _updateSqliteOrderCacheSubtotal(orderCache);
      if (status == 1) {
        return data;
      } else {
        return null;
      }
      // int status = await posDatabase.updateOrderCacheSubtotal(orderCache);
      // if (status == 1) {
      //   getOrderCacheValue(orderCache);
      // }
    }catch(e, stackTrace){
      FLog.error(
        className: "adj_quantity",
        text: "updateOrderCacheSubtotal error",
        exception: "Error: $e, StackTrace: $stackTrace",
      );
      rethrow;
    }
  }

  String _getSubtotal(double totalAmount, String price, num quantity){
    double subtotal = 0.0;
    if(_cartItem.unit != 'each' && _cartItem.unit != 'each_c'){
      subtotal = totalAmount - double.parse(price);
    } else {
      subtotal = totalAmount - double.parse(price) * quantity;
    }
    print("subtotal: ${subtotal.toStringAsFixed(2)}");
    return subtotal.toStringAsFixed(2);
  }


  String _getTotalQty(){
    num totalQty = 0;
    if(_cartItem.unit != 'each' && _cartItem.unit != 'each_c'){
      if(_cancelQuantity != 0){
        totalQty = 0;
      }
    } else {
      totalQty = _cartItem.quantity! - _cancelQuantity;
    }
    print("total qty: ${totalQty}");
    return totalQty.toString();
  }

  _createOrderDetailCancel() async {
    try{
      List<String> _value = [];
      // OrderDetail data = await cancelQuery.readSpecificOrderDetailByLocalId(int.parse(widget.cartItem.order_detail_sqlite_id!));
      // OrderDetail data = await posDatabase.readSpecificOrderDetailByLocalId(int.parse(widget.cartItem.order_detail_sqlite_id!));
      OrderDetailCancel object = OrderDetailCancel(
        order_detail_cancel_id: 0,
        order_detail_cancel_key: '',
        order_detail_sqlite_id: _cartItem.order_detail_sqlite_id,
        order_detail_key: _orderDetail.order_detail_key,
        quantity: _cancelQuantity.toString(),
        quantity_before_cancel: _cartItem.quantity! is double ?
        _cartItem.quantity!.toStringAsFixed(2): _cartItem.quantity!.toString(),
        cancel_by: _user.name,
        cancel_by_user_id: _user.user_id.toString(),
        cancel_reason: _reason,
        settlement_sqlite_id: '',
        settlement_key: '',
        status: 0,
        sync_status: 0,
        created_at: _dateTime,
        updated_at: '',
        soft_delete: '',
      );
      OrderDetailCancel orderDetailCancel = await _insertSqliteOrderDetailCancel(object);
      // OrderDetailCancel orderDetailCancel = await posDatabase.insertSqliteOrderDetailCancel(object);
      OrderDetailCancel updateData = await _insertOrderDetailCancelKey(orderDetailCancel);
      // _value.add(jsonEncode(updateData));
      // order_detail_cancel_value = _value.toString();
      //syncOrderDetailCancelToCloud(_value.toString());
    }catch(e, stackTrace){
      FLog.error(
        className: "adjust_qty_dialog",
        text: "insertOrderDetailCancelKey error",
        exception: "Error: $e, StackTrace: $stackTrace",
      );
      rethrow;
    }
  }

  _generateOrderDetailCancelKey(OrderDetailCancel orderDetailCancel) async {
    final prefs = await SharedPreferences.getInstance();
    final int? device_id = prefs.getInt('device_id');
    var bytes = orderDetailCancel.created_at!.replaceAll(new RegExp(r'[^0-9]'), '') +
            orderDetailCancel.order_detail_cancel_sqlite_id.toString() +
            device_id.toString();
    var md5Hash = md5.convert(utf8.encode(bytes));
    return Utils.shortHashString(hashCode: md5Hash);
  }

  _insertOrderDetailCancelKey(OrderDetailCancel orderDetailCancel) async {
    try{
      OrderDetailCancel? data;
      String? key = await _generateOrderDetailCancelKey(orderDetailCancel);
      if (key != null) {
        OrderDetailCancel object = OrderDetailCancel(
            order_detail_cancel_key: key,
            sync_status: 0,
            updated_at: _dateTime,
            order_detail_cancel_sqlite_id:
            orderDetailCancel.order_detail_cancel_sqlite_id);
        int uniqueKey = await _updateOrderDetailCancelUniqueKey(object);
        // await posDatabase.updateOrderDetailCancelUniqueKey(object);
        if (uniqueKey == 1) {
          // OrderDetailCancel orderDetailCancelData = await posDatabase.readSpecificOrderDetailCancelByLocalId(object.order_detail_cancel_sqlite_id!);
          data = orderDetailCancel.copy(
              order_detail_cancel_key: object.order_detail_cancel_key,
              sync_status: object.sync_status,
              updated_at: object.updated_at
          );
        }
      }
      return data;
    }catch(e, stackTrace){
      FLog.error(
        className: "adjust_qty_dialog",
        text: "insertOrderDetailCancelKey error",
        exception: "Error: $e, StackTrace: $stackTrace",
      );
      rethrow;
    }
  }

  Future<OrderDetail> readSpecificOrderDetailByLocalIdNoJoin(String order_detail_sqlite_id) async {
    try{
      final result = await _transaction.rawQuery(
          'SELECT * FROM $tableOrderDetail WHERE order_detail_sqlite_id = ? ',
          [order_detail_sqlite_id]);

      return OrderDetail.fromJson(result.first);
    }catch(e, stackTrace){
      FLog.error(
        className: "cancel query",
        text: "readSpecificOrderDetailByLocalIdNoJoin error",
        exception: "Error: $e, StackTrace: $stackTrace",
      );
      rethrow;
    }
  }

  Future<OrderDetailCancel> _insertSqliteOrderDetailCancel(OrderDetailCancel data) async {
    try{
      final id = await _transaction.insert(tableOrderDetailCancel!, data.toJson());
      return data.copy(order_detail_cancel_sqlite_id: id);
    }catch(e, stackTrace){
      FLog.error(
        className: "cancel query",
        text: "insertSqliteOrderDetailCancel error",
        exception: "Error: $e, StackTrace: $stackTrace",
      );
      rethrow;
    }
  }

  Future<int> _updateOrderDetailCancelUniqueKey(OrderDetailCancel data) async {
    try{
      return await _transaction.rawUpdate('UPDATE $tableOrderDetailCancel SET order_detail_cancel_key = ?, sync_status = ?, updated_at = ? WHERE order_detail_cancel_sqlite_id = ?', [
        data.order_detail_cancel_key,
        data.sync_status,
        data.updated_at,
        data.order_detail_cancel_sqlite_id,
      ]);
    }catch(e, stackTrace){
      FLog.error(
        className: "cancel query",
        text: "insertSqliteOrderDetailCancel error",
        exception: "Error: $e, StackTrace: $stackTrace",
      );
      rethrow;
    }
  }

  Future<int> _updateSqliteOrderDetailQuantity(OrderDetail data) async {
    try{
      return _transaction.rawUpdate('UPDATE $tableOrderDetail SET updated_at = ?, sync_status = ?, quantity = ? WHERE order_detail_sqlite_id = ?',
          [data.updated_at, data.sync_status, data.quantity, data.order_detail_sqlite_id]);
    }catch(e, stackTrace){
      FLog.error(
        className: "cancel query",
        text: "updateOrderDetailQuantity error",
        exception: "Error: $e, StackTrace: $stackTrace",
      );
      rethrow;
    }
  }

  Future<OrderDetail> _readSpecificOrderDetailByLocalId(int order_detail_sqlite_id) async {
    try{
      final result = await _transaction.rawQuery(
          'SELECT a.soft_delete, a.updated_at, a.created_at, a.product_sku, a.per_quantity_unit, a.unit, a.sync_status, a.status, a.cancel_by_user_id, a.cancel_by, a.edited_by_user_id, a.edited_by, '
              'a.account, a.remark, a.quantity, a.original_price, a.price, a.product_variant_name, a.has_variant, a.product_name, a.category_name, a.order_cache_key, a.order_cache_sqlite_id, '
              'a.order_detail_key, a.branch_link_product_sqlite_id, IFNULL( (SELECT category_id FROM $tableCategories WHERE category_sqlite_id = a.category_sqlite_id), 0) AS category_id,'
              'c.branch_link_product_id FROM $tableOrderDetail AS a '
              'LEFT JOIN $tableBranchLinkProduct AS c ON a.branch_link_product_sqlite_id = c.branch_link_product_sqlite_id '
              'WHERE a.order_detail_sqlite_id = ? ',
          [order_detail_sqlite_id]);

      return OrderDetail.fromJson(result.first);
    }catch(e, stackTrace){
      FLog.error(
        className: "cancel query",
        text: "readSpecificOrderDetailByLocalId error",
        exception: "Error: $e, StackTrace: $stackTrace",
      );
      rethrow;
    }
  }

  Future<OrderCache> _readSpecificOrderCacheByLocalId(int order_cache_sqlite_id) async {
    try{
      final result = await _transaction.rawQuery(
          'SELECT a.soft_delete, a.updated_at, a.created_at, a.sync_status, a.accepted, a.qr_order_table_id, a.qr_order_table_sqlite_id, a.qr_order, a.total_amount, '
              'a.customer_id, a.cancel_by_user_id, a.cancel_by, '
              'a.order_by_user_id, a.order_by, a.order_key, a.order_sqlite_id, a.dining_id, a.batch_id, a.table_use_key, a.table_use_sqlite_id, a.order_detail_id, a.branch_id, '
              'a.company_id, a.order_queue, a.order_cache_key, a.order_cache_id, a.order_cache_sqlite_id, '
              'b.name AS name FROM $tableOrderCache AS a JOIN $tableDiningOption AS b ON a.dining_id = b.dining_id WHERE a.order_cache_sqlite_id = ? AND b.soft_delete = ?',
          [order_cache_sqlite_id, '']);
      return OrderCache.fromJson(result.first);
    }catch(e, stackTrace){
      FLog.error(
        className: "cancel query",
        text: "readSpecificOrderCacheByLocalId error",
        exception: "Error: $e, StackTrace: $stackTrace",
      );
      rethrow;
    }
  }

  Future<int> _updateSqliteOrderCacheSubtotal(OrderCache data) async {
    try{
      return await _transaction.rawUpdate('UPDATE $tableOrderCache SET sync_status = ?, total_amount = ?, updated_at = ? WHERE order_cache_sqlite_id = ?',
          [data.sync_status, data.total_amount, data.updated_at, data.order_cache_sqlite_id]);
    }catch(e, stackTrace){
      FLog.error(
        className: "cancel query",
        text: "updateOrderCacheSubtotal error",
        exception: "Error: $e, StackTrace: $stackTrace",
      );
      rethrow;
    }
  }

  Future<List<BranchLinkProduct>> _readSpecificBranchLinkProduct(String branch_link_product_sqlite_id) async {
    try{
      final result = await _transaction.rawQuery(
          'SELECT a.*, b.name, b.allow_ticket, b.ticket_count, b.ticket_exp '
              'FROM $tableBranchLinkProduct AS a JOIN $tableProduct AS b ON a.product_id = b.product_id '
              'WHERE b.soft_delete = ? AND a.branch_link_product_sqlite_id = ?',
          ['', branch_link_product_sqlite_id]) as List<Map<String, Object?>>;

      return result.map((json) => BranchLinkProduct.fromJson(json)).toList();
    }catch(e, stackTrace){
      FLog.error(
        className: "cancel query",
        text: "readSpecificBranchLinkProduct error",
        exception: "Error: $e, StackTrace: $stackTrace",
      );
      rethrow;
    }
  }

  Future<int> _updateBranchLinkProductDailyLimit(BranchLinkProduct data) async {
    try{
      return await _transaction.rawUpdate('UPDATE $tableBranchLinkProduct SET updated_at = ?, sync_status = ?, daily_limit = ? WHERE branch_link_product_sqlite_id = ?',
          [data.updated_at, data.sync_status, data.daily_limit, data.branch_link_product_sqlite_id]);
    }catch(e, stackTrace){
      FLog.error(
        className: "cancel query",
        text: "updateBranchLinkProductDailyLimit error",
        exception: "Error: $e, StackTrace: $stackTrace",
      );
      rethrow;
    }
  }

  Future<int> _updateBranchLinkProductStock(BranchLinkProduct data) async {
    try{
      return await _transaction.rawUpdate('UPDATE $tableBranchLinkProduct SET updated_at = ?, sync_status = ?, stock_quantity = ? WHERE branch_link_product_sqlite_id = ?',
          [data.updated_at, data.sync_status, data.stock_quantity, data.branch_link_product_sqlite_id]);
    }catch(e, stackTrace){
      FLog.error(
        className: "cancel query",
        text: "updateBranchLinkProductStock error",
        exception: "Error: $e, StackTrace: $stackTrace",
      );
      rethrow;
    }
  }

  Future<int> _updateOrderDetailStatus(OrderDetail data) async {
    try{
      return await _transaction.rawUpdate('UPDATE $tableOrderDetail SET updated_at = ?, sync_status = ?, status = ?, cancel_by = ?, cancel_by_user_id = ? WHERE order_detail_sqlite_id = ?',
          [data.updated_at, data.sync_status, data.status, data.cancel_by, data.cancel_by_user_id, data.order_detail_sqlite_id]);
    }catch(e, stackTrace){
      FLog.error(
        className: "cancel query",
        text: "updateOrderDetailStatus error",
        exception: "Error: $e, StackTrace: $stackTrace",
      );
      rethrow;
    }
  }

  Future<int> _cancelOrderCache(OrderCache data) async {
    try{
      return await _transaction.rawUpdate('UPDATE $tableOrderCache SET sync_status = ?, cancel_by = ?, cancel_by_user_id = ? WHERE order_cache_sqlite_id = ?',
          [data.sync_status, data.cancel_by, data.cancel_by_user_id, data.order_cache_sqlite_id]);
    }catch(e, stackTrace){
      FLog.error(
        className: "cancel query",
        text: "cancelOrderCache error",
        exception: "Error: $e, StackTrace: $stackTrace",
      );
      rethrow;
    }
  }

  Future<List<TableUseDetail>> _readAllTableUseDetail(String table_use_sqlite_id) async {
    try{
      final result = await _transaction.rawQuery('SELECT * '
          'FROM $tableTableUseDetail WHERE soft_delete = ? AND status = ? AND table_use_sqlite_id = ?',
          ['', 0, table_use_sqlite_id]) as List<Map<String, Object?>>;

      return result.map((json) => TableUseDetail.fromJson(json)).toList();
    }catch(e, stackTrace){
      FLog.error(
        className: "cancel query",
        text: "readAllTableUseDetail error",
        exception: "Error: $e, StackTrace: $stackTrace",
      );
      rethrow;
    }
  }

  Future<int> _deleteTableUseDetail(TableUseDetail data) async {
    try{
      return await _transaction.rawUpdate('UPDATE $tableTableUseDetail SET updated_at = ?, sync_status = ?, status = ? WHERE table_use_sqlite_id = ? AND table_use_detail_sqlite_id = ?',
          [data.updated_at, data.sync_status, data.status, data.table_use_sqlite_id, data.table_use_detail_sqlite_id]);
    }catch(e, stackTrace){
      FLog.error(
        className: "cancel query",
        text: "deleteTableUseDetail error",
        exception: "Error: $e, StackTrace: $stackTrace",
      );
      rethrow;
    }
  }

  Future<TableUse?> _readSpecificTableUseIdByLocalId(int table_use_sqlite_id) async {
    try{
      final result = await _transaction.rawQuery('SELECT * FROM $tableTableUse '
          'WHERE table_use_sqlite_id = ? ', [table_use_sqlite_id]) as List<Map<String, Object?>>;
      if(result.isNotEmpty){
        return TableUse.fromJson(result.first);
      } else {
        return null;
      }
    }catch(e, stackTrace){
      FLog.error(
        className: "cancel query",
        text: "deleteTableUseDetail error",
        exception: "Error: $e, StackTrace: $stackTrace",
      );
      rethrow;
    }
  }

  Future<int> _deleteTableUseID(TableUse data) async {
    try{
      return await _transaction.rawUpdate('UPDATE $tableTableUse SET updated_at = ?, status = ?, sync_status = ? WHERE table_use_sqlite_id = ?',
          [data.updated_at, data.status, data.sync_status, data.table_use_sqlite_id]);
    }catch(e, stackTrace){
      FLog.error(
        className: "cancel query",
        text: "deleteTableUseDetail error",
        exception: "Error: $e, StackTrace: $stackTrace",
      );
      rethrow;
    }
  }

  Future<int> _updateSqlitePosTableStatus(PosTable data) async {
    try{
      return await _transaction.rawUpdate('UPDATE $tablePosTable SET '
          'sync_status = ?, table_use_detail_key = ?, table_use_key = ?, status = ?, updated_at = ? WHERE table_sqlite_id = ?',
          [2, data.table_use_detail_key, data.table_use_key, data.status, data.updated_at, data.table_sqlite_id]);
    }catch(e, stackTrace){
      FLog.error(
        className: "cancel query",
        text: "updatePosTableStatus error",
        exception: "Error: $e, StackTrace: $stackTrace",
      );
      rethrow;
    }
  }

}