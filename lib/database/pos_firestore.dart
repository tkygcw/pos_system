import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pos_system/database/pos_database.dart';
import 'package:pos_system/object/product.dart';
import 'package:pos_system/object/qr_order.dart';

import '../object/branch_link_product.dart';
import '../object/categories.dart';
import '../object/order_cache.dart';
import '../object/order_detail.dart';
import '../object/order_modifier_detail.dart';

class PosFirestore{
  static final PosFirestore instance = PosFirestore.init();
  static FirebaseFirestore _firestore = FirebaseFirestore.instance;

  PosFirestore.init();

  FirebaseFirestore get firestore => _firestore;

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

  readFullOrderCache() async {
    Query orderCache = firestore.collection("tb_qr_order_cache").where("branch_id", isEqualTo: '3');
    orderCache.get().then((querySnapshot) async {
        print("Successfully completed");
        for (var docSnapshot in querySnapshot.docs) {
          print('${docSnapshot.id} => ${docSnapshot.data()}');
          OrderCache localData = await insertLocalOrderCache(docSnapshot.data() as Map<String, dynamic>);
          readOrderDetail(docSnapshot.reference, localData);
        }
      },
      onError: (e) => print("Error completing: $e"),
    );
  }

  Future<OrderCache>insertLocalOrderCache(Map<String, dynamic> data) async {
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
        qr_order_table_id: data['table_id'],
        accepted: 1,
        sync_status: 1,
        created_at: data['created_at'],
        updated_at: '',
        soft_delete: ''
    );
    return await PosDatabase.instance.insertSqLiteOrderCache(orderCache);
  }

  readOrderDetail(DocumentReference parentDoc, OrderCache localOrderCache){
    parentDoc.collection("tb_order_detail").get().then((querySnapshot) async {
      print("Successfully completed");
      for (var docSnapshot in querySnapshot.docs) {
        print('${docSnapshot.id} => ${docSnapshot.data()}');
        OrderDetail orderDetail = await insertLocalOrderDetail(docSnapshot.data(), localOrderCache);
        readOrderModDetail(docSnapshot.reference, orderDetail);
      }
    },
      onError: (e) => print("Error completing: $e"),
    );
  }

  Future<OrderDetail>insertLocalOrderDetail(Map<String, dynamic> data, OrderCache localOrderCache) async {
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
  }

  readOrderModDetail(DocumentReference parentDoc, OrderDetail orderDetail) {
    parentDoc.collection("tb_order_modifier_detail").get().then((querySnapshot) async {
      print("Successfully completed");
      for (var docSnapshot in querySnapshot.docs){
        print('${docSnapshot.id} => ${docSnapshot.data()}');
        await insertLocalOrderModifierDetail(docSnapshot.data(), orderDetail);
      }
      List<OrderCache> data = await PosDatabase.instance.readNotAcceptedQROrderCache();
      QrOrder.instance.qrOrderCacheList.addAll(data);
    },
      onError: (e) => print("Error completing: $e"),
    );
  }

  Future<OrderModifierDetail>insertLocalOrderModifierDetail(Map<String, dynamic> data, OrderDetail orderDetail) async {
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