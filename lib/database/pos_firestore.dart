import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
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
import 'package:pos_system/object/table.dart';
import '../main.dart';
import '../object/branch_link_product.dart';
import 'domain.dart';

class PosFirestore {
  static final PosFirestore instance = PosFirestore._init();
  static final BuildContext context = MyApp.navigatorKey.currentContext!;
  static FirebaseFirestore _firestore = FirebaseFirestore.instance;

  PosFirestore._init();

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

  Future<int> updateBranchLinkProductDailyLimit(BranchLinkProduct branchProduct) async {
    int status = 0;
    try{
      final batch = firestore.batch();
      Map<String, dynamic> jsonMap = {
        BranchLinkProductFields.updated_at: branchProduct.updated_at,
        BranchLinkProductFields.daily_limit: branchProduct.daily_limit,
      };
      final docRef = await firestore.collection(tableBranchLinkProduct!).doc(branchProduct.branch_link_product_id.toString());
      batch.update(docRef, jsonMap);
      batch.commit();
      status = 1;
    }catch(e){
      print("firestore update branch link product error: ${e}");
      status = 0;
    }
    return status;
  }

  Future<int> updateBranchLinkProductStock(BranchLinkProduct branchProduct) async {
    int status = 0;
    try{
      final batch = firestore.batch();
      Map<String, dynamic> jsonMap = {
        BranchLinkProductFields.updated_at: branchProduct.updated_at,
        BranchLinkProductFields.stock_quantity: branchProduct.stock_quantity,
      };
      final docRef = await firestore.collection(tableBranchLinkProduct!).doc(branchProduct.branch_link_product_id.toString());
      batch.update(docRef, jsonMap);
      batch.commit();
      status = 1;
    }catch(e){
      print("firestore update branch link product stock error: ${e}");
      status = 0;
    }
    return status;
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

  updateSpecificProduct(String id) async {
    print("updating...");
    final batch = firestore.batch();
    final docRef = firestore.collection("tb_qr_order_cache").doc(id);
    batch.update(docRef, {"name": 'test'});
    batch.commit();
    // await firestore.runTransaction((transaction) async {
    //   var docSnapshot = await transaction.get(docRef);
    //   if (docSnapshot.exists) {
    //     transaction.update(docRef, {"name": 'newNameTest4'});
    //   }
    // }, timeout: Duration(seconds: 2), maxAttempts: 2);
    // final status = firestore.collection("tb_qr_order_cache").doc(id);
    // await status.update({"name": 'newNameTest2'});
  }

  deleteSpecificProduct(String id){
    firestore.collection(tableProduct!).doc(id).delete().then(
          (doc) => print("Document deleted"),
      onError: (e) => print("Error updating document $e"),
    );
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
    print("im offline");
    firestore.settings = const Settings(persistenceEnabled: true, cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,);
    firestore.disableNetwork();
  }

  online(){
    firestore.enableNetwork().then((_) {
      // Back online
      print("im online");
    });

  }
}