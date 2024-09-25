import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';
import 'package:pos_system/database/pos_database.dart';
import 'package:pos_system/object/branch.dart';
import 'package:pos_system/object/branch_link_dining_option.dart';
import 'package:pos_system/object/branch_link_modifier.dart';
import 'package:pos_system/object/branch_link_promotion.dart';
import 'package:pos_system/object/branch_link_tax.dart';
import 'package:pos_system/object/dining_option.dart';
import 'package:pos_system/object/modifier_group.dart';
import 'package:pos_system/object/modifier_item.dart';
import 'package:pos_system/object/modifier_link_product.dart';
import 'package:pos_system/object/product.dart';
import 'package:pos_system/object/product_variant.dart';
import 'package:pos_system/object/product_variant_detail.dart';
import 'package:pos_system/object/qr_order.dart';
import 'package:awesome_snackbar_content/awesome_snackbar_content.dart';
import 'package:pos_system/object/table.dart';

import '../fragment/custom_snackbar.dart';
import '../main.dart';
import '../object/branch_link_product.dart';
import '../object/categories.dart';
import '../object/order_cache.dart';
import '../object/order_detail.dart';
import '../object/order_modifier_detail.dart';
import '../translation/AppLocalizations.dart';
import 'domain.dart';

class PosFirestore{
  static final PosFirestore instance = PosFirestore.init();
  static final BuildContext context = MyApp.navigatorKey.currentContext!;
  static FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final DateFormat dateFormat = DateFormat("yyyy-MM-dd HH:mm:ss");

  PosFirestore.init();

  FirebaseFirestore get firestore => _firestore;

  insertBranch(Branch branch) async {
    await firestore.collection(tableBranch!).doc(branch.branch_id.toString()).set(branch.toJson());
  }

  insertBranchLinkDining(BranchLinkDining data) async {
    await firestore.collection(tableBranchLinkDining!).doc(data.branch_link_dining_id.toString()).set(data.toJson());
  }

  insertBranchLinkModifier(BranchLinkModifier data) async {
    await firestore.collection(tableBranchLinkModifier!).doc(data.branch_link_modifier_id.toString()).set(data.toJson());
  }

  insertBranchLinkProduct(BranchLinkProduct data) async {
    await firestore.collection(tableBranchLinkProduct!).doc(data.branch_link_product_id.toString()).set(data.toJson());
  }

  insertBranchLinkPromotion(BranchLinkPromotion data) async {
    await firestore.collection(tableBranchLinkPromotion!).doc(data.branch_link_promotion_id.toString()).set(data.toJson());
  }

  insertBranchLinkTax(BranchLinkTax data) async {
    await firestore.collection(tableBranchLinkTax!).doc(data.branch_link_tax_id.toString()).set(data.toJson());
  }

  insertDiningOption(DiningOption data) async {
    await firestore.collection(tableDiningOption!).doc(data.dining_id.toString()).set(data.toJson());
  }

  insertModifierGroup(ModifierGroup data) async {
    await firestore.collection(tableModifierGroup!).doc(data.mod_group_id.toString()).set(data.toJson2());
  }

  insertModifierItem(ModifierItem data) async {
    await firestore.collection(tableModifierItem!).doc(data.mod_item_id.toString()).set(data.toJson2());
  }

  insertModifierLinkProduct(ModifierLinkProduct data) async {
    await firestore.collection(tableModifierLinkProduct!).doc(data.modifier_link_product_id.toString()).set(data.toJson());
  }

  insertProduct(Product data) async {
    await firestore.collection(tableProduct!).doc(data.product_id.toString()).set(data.toJson());
  }

  insertProductVariant(ProductVariant data) async {
    await firestore.collection(tableProductVariant!).doc(data.product_variant_id.toString()).set(data.toJson());
  }

  insertProductVariantDetail(ProductVariantDetail data) async {
    await firestore.collection(tableProductVariantDetail!).doc(data.product_variant_detail_id.toString()).set(data.toJson());
  }

  insertPosTable(PosTable data) async {
    await firestore.collection(tablePosTable!).doc(data.table_id.toString()).set(data.toJson());
  }

  Future<Branch?> readCurrentBranch(String branch_id) async {
    var snapshot = await firestore.collection(tableBranch!).doc(branch_id).get();
    if(snapshot.data() != null){
      return Branch.fromJson(snapshot.data()!);
    } else {
      return null;
    }
  }

  readDataFromCloud() async {
    await firestore.collection(tableProduct!).get().then((event) {
      for (var doc in event.docs) {
        print("${doc.id} => ${doc.data()}");
      }
    });
  }

  addProductFromLocalId() async {
    List<Product> products = await PosDatabase.instance.readAllProduct();
    firestore.collection(tableProduct!).add(products.first.toJson()).then((DocumentReference doc) {
      print('DocumentSnapshot added with ID: ${doc.id}');
    });
  }

  addProductFromLocalIdWithSpecificId() async {
    List<Product> products = await PosDatabase.instance.readAllProduct();
    final docRef = firestore.collection(tableProduct!).doc(products.first.product_sqlite_id.toString());
    await docRef.set(products.first.toJson());
  }

  transferDatabaseData() async {
    try{
      Map res = await Domain().transferDatabaseData('tb_table_dynamic');
      print("res length: ${res['data'].length}");
      List data = res['data'];
      int chunkSize = 20;
      int total = data.length;
      int totalChunkBreak = 0;
      for (int i = 0; i < total; i += chunkSize) {
        // Take a chunk of 'chunkSize' elements, starting from index 'i'
        List<dynamic> chunk = data.sublist(i, i + chunkSize > total ? total : i + chunkSize);
        for(int j = 0; j < chunk.length; j++){
          try{
            await firestore.collection("tb_table_dynamic").doc(chunk[j]['table_dynamic_id'].toString()).set(chunk[j]);
          }catch(e){
            break;
          }

        }
        // Process the chunk
        totalChunkBreak += chunk.length;
      }
      print("total chunk processed: ${totalChunkBreak}");
    }catch(e){
      print("transferDatabaseData error: ${e}");
    }
  }

  updateSpecificProduct(String id){
    final status = firestore.collection(tableProduct!).doc(id);
    status.update({"name": 'newNameTest2'}).then(
            (value) => print("DocumentSnapshot successfully updated!"),
        onError: (e) => print("Error updating document $e"));
  }

  deleteSpecificProduct(String id){
    firestore.collection(tableProduct!).doc(id).delete().then(
          (doc) => print("Document deleted"),
      onError: (e) => print("Error updating document $e"),
    );
  }

  realtimeQROrder(BuildContext context, String branch_id){
    final docRef = firestore.collection('tb_qr_order_cache')
        .where("branch_id", isEqualTo: branch_id)
        .where("soft_delete", isEqualTo: '')
        .where("accepted", isEqualTo: 1)
        .where("sync_status", isEqualTo: 0);
    docRef.snapshots(includeMetadataChanges: true).listen((event) async {
      for (var changes in event.docChanges) {
        final source = (event.metadata.isFromCache) ? "local cache" : "server";
        switch (changes.type) {
          case DocumentChangeType.added:
            print("New product from $source: ${changes.doc.id}");
            insertQROrderCache(changes.doc);
            break;
          case DocumentChangeType.modified:
            print("Modified product from $source: ${changes.doc.data()}");
            break;
          case DocumentChangeType.removed:
            print("Removed product from $source: ${changes.doc.data()}");
            break;
        }
      }
    },
      onError: (error) => print("Listen failed: $error"),
    );
  }

  Future<void> insertQROrderCache(DocumentSnapshot docSnapshot) async {
    try{
      updateDocumentSyncStatus(docSnapshot.reference);
      OrderCache? localData = await insertLocalOrderCache(docSnapshot.data() as Map<String, dynamic>);
      if(localData != null){
        readOrderDetail(docSnapshot.reference, localData);
      }
    }catch(e){
      print("insertQROrderCache error: $e");
    }
  }

  Future<void> readAllNotAcceptedOrderCache(String branch_id) async {
    try{
      Query orderCache = firestore.collection("tb_qr_order_cache")
          .where("branch_id", isEqualTo: branch_id)
          .where("soft_delete", isEqualTo: '')
          .where("accepted", isEqualTo: 1)
          .where("sync_status", isEqualTo: 0);
      var querySnapshot = await orderCache.get();
      print("doc length: ${querySnapshot.docs.length}");
      for (var docSnapshot in querySnapshot.docs) {
        print('${docSnapshot.id} => ${docSnapshot.data()}');
        insertQROrderCache(docSnapshot);
      }
    }catch(e){
      print("readFullOrderCache error: $e");
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
      return null;
    }
  }

  readOrderDetail(DocumentReference parentDoc, OrderCache localOrderCache) async {
    var querySnapshot = await parentDoc.collection("tb_order_detail").get();
    for (var docSnapshot in querySnapshot.docs) {
      print('${docSnapshot.id} => ${docSnapshot.data()}');
      updateDocumentSyncStatus(docSnapshot.reference);
      OrderDetail? orderDetail = await insertLocalOrderDetail(docSnapshot.data(), localOrderCache);
      if(orderDetail != null){
        readOrderModDetail(docSnapshot.reference, orderDetail);
      }
    }
  }

  Future<OrderDetail?> insertLocalOrderDetail(Map<String, dynamic> data, OrderCache localOrderCache) async {
    try{
      String categoryLocalId;
      BranchLinkProduct? branchLinkProductData = await PosDatabase.instance.readSpecificBranchLinkProductByCloudId(data['branch_link_product_id']);
      if(data['category_id'] != '0'){
        Categories catData = await PosDatabase.instance.readSpecificCategoryByCloudId(data['category_id']);
        categoryLocalId = catData.category_sqlite_id.toString();
      } else {
        categoryLocalId = '0';
      }
      OrderDetail orderDetail = OrderDetail(
        order_detail_id: 0,
        order_detail_key: data['order_detail_key'],
        order_cache_sqlite_id: localOrderCache.order_cache_sqlite_id.toString(),
        order_cache_key: data['order_cache_key'].toString(),
        branch_link_product_sqlite_id: branchLinkProductData != null ? branchLinkProductData.branch_link_product_sqlite_id.toString() : '',
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
      return await PosDatabase.instance.insertSqliteOrderDetail(orderDetail);
    }catch(e){
      await deleteOrderCache(localOrderCache.order_cache_key!);
      return null;
    }
  }

  readOrderModDetail(DocumentReference parentDoc, OrderDetail orderDetail) async {
    final querySnapshot = await parentDoc.collection("tb_order_modifier_detail").get();
    for (var docSnapshot in querySnapshot.docs){
      print('${docSnapshot.id} => ${docSnapshot.data()}');
      updateDocumentSyncStatus(docSnapshot.reference);
      OrderModifierDetail? modDetail= await insertLocalOrderModifierDetail(docSnapshot.data(), orderDetail);
      if(modDetail != null) {
        QrOrder.instance.getAllNotAcceptedQrOrder();
        CustomSnackBar.instance.showSnackBar(
            title: "${AppLocalizations.of(context)?.translate('qr_order')}",
            description: "${AppLocalizations.of(context)?.translate('new_qr_order_received')}",
            contentType: ContentType.success,
            playSound: true,
            playtime: 2
        );
      }
    }
  }

  Future<OrderModifierDetail?> insertLocalOrderModifierDetail(Map<String, dynamic> data, OrderDetail orderDetail) async {
    try{
      OrderModifierDetail modifierDetail = OrderModifierDetail(
          order_modifier_detail_id: 0,
          order_modifier_detail_key: data['order_modifier_detail_key'].toString(),
          order_detail_sqlite_id: orderDetail.order_detail_sqlite_id.toString(),
          order_detail_id: '0',
          order_detail_key: data['order_detail_key'],
          mod_item_id: data['mod_item_id'].toString(),
          mod_name: data['name'].toString(),
          mod_price: data['price'].toString(),
          mod_group_id: data['mod_group_id'].toString(),
          sync_status: 1,
          created_at: data['created_at'],
          updated_at: '',
          soft_delete: ''
      );
      return await PosDatabase.instance.insertSqliteOrderModifierDetail(modifierDetail);
    }catch(e){
      await deleteOrderCache(orderDetail.order_cache_key!);
      return null;
    }
  }

  deleteOrderCache(String orderCacheKey) async {
    String dateTime = dateFormat.format(DateTime.now());
    OrderCache orderCache = OrderCache(
        soft_delete: dateTime,
        order_cache_key: orderCacheKey
    );
    await PosDatabase.instance.softDeleteOrderCache(orderCache);
  }

  updateDocumentSyncStatus(DocumentReference docRef) async {
    await firestore.runTransaction((transaction) async {
      var docSnapshot = await transaction.get(docRef);
      if (docSnapshot.exists) {
        transaction.update(docRef, {"sync_status": 1});
      }
    }, timeout: Duration(seconds: 2), maxAttempts: 2);
  }

  acceptOrderCache(OrderCache updatedOrderCache) async {
    int status = 0;
    try{
      Map<String, dynamic> jsonMap = {
        'updated_at': updatedOrderCache.updated_at,
        'order_by': 'Qr order',
        'accepted': 0,
        'total_amount': updatedOrderCache.total_amount ?? '',
        'batch_id': updatedOrderCache.batch_id,
        'table_use_key': updatedOrderCache.table_use_key ?? ''
      };
      await firestore.runTransaction((transaction) async {
        final querySnapshot = await firestore.collection('tb_qr_order_cache')
            .where('order_cache_key', isEqualTo: updatedOrderCache.order_cache_key).get();
        print("querySnapshot length: ${querySnapshot.docs.length}");
        for (QueryDocumentSnapshot doc in querySnapshot.docs) {
          DocumentReference docRef = doc.reference;
          var docSnapshot = await transaction.get(docRef);
          if (docSnapshot.exists) {
            print("inside called!!");
            transaction.update(docRef, jsonMap);
            status = 1;
          }
        }
      }, timeout: Duration(seconds: 2), maxAttempts: 2);
    }catch(e){
      status = 0;
    }
    return status;
  }

  rejectOrderCache(String key, OrderCache updatedOrderCache) async {
    Map<String, dynamic> jsonMap = {
      'soft_delete': updatedOrderCache.soft_delete ?? '',
      'updated_at': updatedOrderCache.updated_at,
      'accepted': updatedOrderCache.accepted ?? 1,
    };
    int status = 0;
    final querySnapshot = await firestore.collection('tb_qr_order_cache').where('order_cache_key', isEqualTo: key.toString()).get();
    try{
      await firestore.runTransaction((transaction) async {
        print("querySnapshot length: ${querySnapshot.docs.length}");
        for (QueryDocumentSnapshot doc in querySnapshot.docs) {
          DocumentReference docRef = doc.reference;
          var docSnapshot = await transaction.get(docRef);
          if (docSnapshot.exists) {
            print("inside called!!");
            transaction.update(docRef, jsonMap);
            status = 1;
          }
        }
      }, timeout: Duration(seconds: 2), maxAttempts: 2);
    }catch(e){
      print("updateOrderCacheAcceptStatus error: $e");
      status = 0;
    }
    return status;
  }

  realtimeUpdate(){
    final docRef = firestore.collection(tableProduct!).where("company", isEqualTo: '3');
    docRef.snapshots(includeMetadataChanges: true).listen((event) {
      for (var changes in event.docChanges) {
        final source = (event.metadata.isFromCache) ? "local cache" : "server";
        switch (changes.type) {
          case DocumentChangeType.added:
            print("New product from $source: ${changes.doc.data()}");
            break;
          case DocumentChangeType.modified:
            print("Modified product from $source: ${changes.doc.data()}");
            break;
          case DocumentChangeType.removed:
            print("Removed product from $source: ${changes.doc.data()}");
            break;
        }
      }
    },
      onError: (error) => print("Listen failed: $error"),
    );
  }

  offline(){
    firestore.settings = const Settings(persistenceEnabled: true, cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,);
    firestore.disableNetwork().then((_) {
      // Do offline things
      print("offline on");
      realtimeUpdate();
    });
  }

  online(){
    firestore.enableNetwork().then((_) {
      // Back online
      print("im online");
    });

  }
}