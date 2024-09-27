import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:f_logs/model/flog/flog.dart';
import 'package:flutter/cupertino.dart';
import 'package:pos_system/database/pos_firestore.dart';
import 'package:pos_system/utils/Utils.dart';
import 'package:awesome_snackbar_content/awesome_snackbar_content.dart';

import '../database/pos_database.dart';
import '../fragment/custom_snackbar.dart';
import '../main.dart';
import '../object/branch_link_product.dart';
import '../object/categories.dart';
import '../object/order_cache.dart';
import '../object/order_detail.dart';
import '../object/order_modifier_detail.dart';
import '../object/qr_order.dart';
import '../translation/AppLocalizations.dart';

class FirestoreQROrderSync {
  static final FirestoreQROrderSync instance = FirestoreQROrderSync._init();
  static final firestore = PosFirestore.instance.firestore;
  static final BuildContext context = MyApp.navigatorKey.currentContext!;
  final _tableQrOrderCache = 'tb_qr_order_cache';

  FirestoreQROrderSync._init();

  realtimeQROrder(String branch_id) {
    final docRef = firestore.collection(_tableQrOrderCache)
        .where(OrderCacheFields.branch_id, isEqualTo: branch_id)
        .where(OrderCacheFields.soft_delete, isEqualTo: '')
        .where(OrderCacheFields.accepted, isEqualTo: 1)
        .where(OrderCacheFields.sync_status, isEqualTo: 0);
    docRef.snapshots(includeMetadataChanges: true).listen((event) async {
      for (var changes in event.docChanges) {
        final source = (event.metadata.isFromCache) ? "local cache" : "server";
        switch (changes.type) {
          case DocumentChangeType.added:
            print("New product from $source: ${changes.doc.id}");
            readOrderCache(changes.doc);
            break;
          case DocumentChangeType.modified:
            print("Modified product from $source: ${changes.doc.data()}");
            break;
          case DocumentChangeType.removed:
            print("Removed order from $source: ${changes.doc.id}");
            print("Removed order from $source: ${changes.doc.data()}");
            break;
        }
      }
    },
      onError: (error) => print("Listen failed: $error"),
    );
  }

  Future<void> readAllNotAcceptedOrderCache(String branch_id) async {
    try{
      Query orderCache = firestore.collection(_tableQrOrderCache)
          .where(OrderCacheFields.branch_id, isEqualTo: branch_id)
          .where(OrderCacheFields.soft_delete, isEqualTo: '')
          .where(OrderCacheFields.accepted, isEqualTo: 1)
          .where(OrderCacheFields.sync_status, isEqualTo: 0);
      var querySnapshot = await orderCache.get();
      for (var docSnapshot in querySnapshot.docs) {
        print('${docSnapshot.id} => ${docSnapshot.data()}');
        readOrderCache(docSnapshot);
      }
    }catch(e){
      FLog.error(
        className: "pos_firestore",
        text: "readAllNotAcceptedOrderCache error",
        exception: e,
      );
    }
  }

  Future<void> readOrderCache(DocumentSnapshot docSnapshot) async {
    try{
      updateDocSyncStatus(docSnapshot.reference);
      OrderCache? localData = await insertLocalOrderCache(docSnapshot.data() as Map<String, dynamic>);
      if(localData != null){
        readOrderDetail(docSnapshot.reference, localData);
      }
    }catch(e){
      FLog.error(
        className: "firebase_sync/qr_order_sync",
        text: "readOrderCache error",
        exception: "Error: $e, order_cache_key: ${docSnapshot.id}",
      );
    }
  }

  Future<void> readOrderDetail(DocumentReference parentDoc, OrderCache localOrderCache) async {
    try{
      var querySnapshot = await parentDoc.collection(tableOrderDetail!).get();
      print("order detail doc length: ${querySnapshot.docs.length}");
      for (var docSnapshot in querySnapshot.docs) {
        updateDocSyncStatus(docSnapshot.reference);
        OrderDetail? orderDetail = await insertLocalOrderDetail(docSnapshot.data(), localOrderCache);
        if(orderDetail != null){
          readOrderModDetail(docSnapshot.reference, orderDetail);
          return;
        } else {
          break;
        }
      }
    }catch(e){
      FLog.error(
        className: "firebase_sync/qr_order_sync",
        text: "readOrderDetail error",
        exception: "Error: $e, order_cache_key: ${localOrderCache.order_cache_key}",
      );
    }
    await softDeleteLocalOrderCache(localOrderCache.order_cache_key!);
  }

  Future<void> readOrderModDetail(DocumentReference parentDoc, OrderDetail orderDetail) async {
    try{
      final querySnapshot = await parentDoc.collection(tableOrderModifierDetail!).get();
      if(querySnapshot.docs.isNotEmpty){
        for (var docSnapshot in querySnapshot.docs){
          print('${docSnapshot.id} => ${docSnapshot.data()}');
          updateDocSyncStatus(docSnapshot.reference);
          OrderModifierDetail? modDetail= await insertLocalOrderModifierDetail(docSnapshot.data(), orderDetail);
          print("mod detail: ${modDetail}");
          if(modDetail == null) {
            throw Exception("insertLocalOrderModifierDetail error");
          }
        }
        QrOrder.instance.getAllNotAcceptedQrOrder();
        CustomSnackBar.instance.showSnackBar(
            title: "${AppLocalizations.of(context)?.translate('qr_order')}",
            description: "${AppLocalizations.of(context)?.translate('new_qr_order_received')}",
            contentType: ContentType.success,
            playSound: true,
            playtime: 2
        );
      }
    }catch(e){
      FLog.error(
        className: "firebase_sync/qr_order_sync",
        text: "readOrderModDetail error",
        exception: "Error: $e, order_cache_key: ${orderDetail.order_cache_key}",
      );
      await softDeleteLocalOrderCache(orderDetail.order_cache_key!);
    }
  }

  Future<OrderCache?> insertLocalOrderCache(Map<String, dynamic> data) async {
    try{
      OrderCache orderCache = OrderCache(
          order_cache_id: 0,
          order_cache_key: data['order_cache_key'].toString(),
          order_queue: '',
          company_id: data['company_id'].toString(),
          branch_id: data['branch_id'].toString(),
          order_detail_id: '',
          table_use_sqlite_id: '',
          table_use_key: '',
          batch_id: data['batch_id'].toString(),
          dining_id: data['dining_id'].toString(),
          order_sqlite_id: '',
          order_key: '',
          order_by: '',
          order_by_user_id: '',
          cancel_by: '',
          cancel_by_user_id: '',
          customer_id: data['customer_id'].toString(),
          total_amount: data['total_amount'].toString(),
          qr_order: 1,
          qr_order_table_sqlite_id: '',
          qr_order_table_id: data['table_id'] ?? '',
          accepted: 1,
          sync_status: 1,
          created_at: data['created_at'],
          updated_at: '',
          soft_delete: ''
      );
      return await PosDatabase.instance.insertSqLiteOrderCache(orderCache);
    }catch(e){
      FLog.error(
        className: "firebase_sync/qr_order_sync",
        text: "insertLocalOrderCache error",
        exception: "Error: $e, order_cache_key: ${data['order_cache_key']}",
      );
      return null;
    }
  }

  Future<OrderDetail?> insertLocalOrderDetail(Map<String, dynamic> data, OrderCache localOrderCache) async {
    OrderDetail? orderDetail;
    try{
      String? categoryLocalId;
      BranchLinkProduct? branchLinkProductData = await PosDatabase.instance.readSpecificBranchLinkProductByCloudId(data['branch_link_product_id']);
      if(data['category_id'] != '0'){
        Categories? catData = await PosDatabase.instance.readSpecificCategoryByCloudId(data['category_id']);
        categoryLocalId = catData?.category_sqlite_id.toString();
      } else {
        categoryLocalId = '0';
      }
      if(branchLinkProductData != null && categoryLocalId != null){
        OrderDetail insertData = OrderDetail(
          order_detail_id: 0,
          order_detail_key: data['order_detail_key'],
          order_cache_sqlite_id: localOrderCache.order_cache_sqlite_id.toString(),
          order_cache_key: data['order_cache_key'].toString(),
          branch_link_product_sqlite_id: branchLinkProductData.branch_link_product_sqlite_id.toString(),
          category_sqlite_id: categoryLocalId,
          category_name: data['category_name'],
          productName: data['product_name'],
          has_variant: data['has_variant'],
          product_variant_name: data['product_variant_name'],
          price: data['price'],
          original_price: data['original_price'],
          quantity: data['quantity'],
          remark: data['remark'],
          account: '',
          edited_by: '',
          edited_by_user_id: '',
          cancel_by: '',
          cancel_by_user_id: '',
          status: 0,
          unit: 'each',
          per_quantity_unit: '',
          product_sku: data['product_sku'] ?? '',
          sync_status: 1,
          created_at: data['created_at'],
          updated_at: '',
          soft_delete: '',
        );
        orderDetail = await PosDatabase.instance.insertSqliteOrderDetail(insertData);
      }
    }catch(e){
      orderDetail = null;
      FLog.error(
        className: "pos_firestore",
        text: "insertLocalOrderDetail error",
        exception: "Error: $e, order_cache_key: ${localOrderCache.order_cache_key}, order_detail_key: ${data['order_detail_key']}",
      );
    }
    return orderDetail;
  }

  Future<OrderModifierDetail?> insertLocalOrderModifierDetail(Map<String, dynamic> data, OrderDetail orderDetail) async {
    OrderModifierDetail? orderModifierDetail;
    try{
      OrderModifierDetail modifierDetail = OrderModifierDetail(
          order_modifier_detail_id: 0,
          order_modifier_detail_key: data['order_modifier_detail_key']!,
          order_detail_sqlite_id: orderDetail.order_detail_sqlite_id.toString(),
          order_detail_id: '0',
          order_detail_key: data['order_detail_key'],
          mod_item_id: data['mod_item_id']!,
          mod_name: data['name']!,
          mod_price: data['price']!,
          mod_group_id: data['mod_group_id']!,
          sync_status: 1,
          created_at: data['created_at'],
          updated_at: '',
          soft_delete: ''
      );
      orderModifierDetail =  await PosDatabase.instance.insertSqliteOrderModifierDetail(modifierDetail);
    }catch(e){
      FLog.error(
        className: "pos_firestore",
        text: "insertLocalOrderModifierDetail error",
        exception: "Error: $e, order_cache_key: ${orderDetail.order_cache_key}",
      );
      orderModifierDetail = null;
    }
    return orderModifierDetail;
  }

  Future<int> softDeleteLocalOrderCache(String orderCacheKey) async {
    OrderCache orderCache = OrderCache(
        soft_delete: Utils.dbCurrentDateTimeFormat(),
        order_cache_key: orderCacheKey
    );
    return await PosDatabase.instance.softDeleteOrderCache(orderCache);
  }

  updateDocSyncStatus(DocumentReference docRef){
    final batch = firestore.batch();
    batch.update(docRef, {"sync_status": 1});
    batch.commit();
  }

  Future<int> acceptOrderCache(OrderCache updatedOrderCache) async {
    int status = 0;
    try{
      final batch = firestore.batch();
      Map<String, dynamic> jsonMap = {
        OrderCacheFields.updated_at: updatedOrderCache.updated_at,
        OrderCacheFields.order_by: 'Qr order',
        OrderCacheFields.accepted: 0,
        OrderCacheFields.total_amount: updatedOrderCache.total_amount ?? '',
        OrderCacheFields.batch_id: updatedOrderCache.batch_id,
        OrderCacheFields.table_use_key: updatedOrderCache.table_use_key ?? ''
      };
      final docRef = await firestore.collection(_tableQrOrderCache).doc(updatedOrderCache.order_cache_key);
      batch.update(docRef, jsonMap);
      batch.commit();
      status = 1;
    }catch(e){
      FLog.error(
        className: "firebase_sync/qr_order_sync",
        text: "acceptOrderCache error",
        exception: "Error: $e, order_cache_key: ${updatedOrderCache.order_cache_key}",
      );
      status = 0;
    }
    return status;
  }

  Future<int> rejectOrderCache(OrderCache updatedOrderCache) async {
    int status = 0;
    try{
      final batch = firestore.batch();
      Map<String, dynamic> jsonMap = {
        OrderCacheFields.soft_delete: updatedOrderCache.soft_delete ?? '',
        OrderCacheFields.updated_at: updatedOrderCache.updated_at,
        OrderCacheFields.accepted: updatedOrderCache.accepted ?? 1,
      };
      final docRef = await firestore.collection(_tableQrOrderCache).doc(updatedOrderCache.order_cache_key);
      batch.update(docRef, jsonMap);
      batch.commit();
      status = 1;
    }catch(e){
      FLog.error(
        className: "firebase_sync/qr_order_sync",
        text: "rejectOrderCache error",
        exception: "Error: $e, order_cache_key: ${updatedOrderCache.order_cache_key}",
      );
      status = 0;
    }
    return status;
  }

  Future<int> updateOrderDetail(OrderDetail orderDetail) async {
    int status = 0;
    try{
      final batch = firestore.batch();
      Map<String, dynamic> jsonMap = {
        'updated_at': orderDetail.updated_at,
        'price': orderDetail.price,
        'quantity': orderDetail.quantity,
      };
      final docRef = await firestore.collection(_tableQrOrderCache).doc(orderDetail.order_cache_key)
          .collection(tableOrderDetail!).doc(orderDetail.order_detail_key);
      batch.update(docRef, jsonMap);
      batch.commit();
      status = 1;
    }catch(e){
      FLog.error(
        className: "firebase_sync/qr_order_sync",
        text: "updateOrderDetail error",
        exception: "Error: $e, order_cache_key: ${orderDetail.order_cache_key}",
      );
      status = 0;
    }
    return status;
  }
}