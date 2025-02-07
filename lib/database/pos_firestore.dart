import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:f_logs/model/flog/flog.dart';
import 'package:flutter/cupertino.dart';
import 'package:pos_system/database/pos_database.dart';
import 'package:pos_system/object/branch.dart';
import 'package:pos_system/object/branch_link_dining_option.dart';
import 'package:pos_system/object/branch_link_modifier.dart';
import 'package:pos_system/object/branch_link_promotion.dart';
import 'package:pos_system/object/branch_link_tax.dart';
import 'package:pos_system/object/categories.dart';
import 'package:pos_system/object/dining_option.dart';
import 'package:pos_system/object/ingredient_branch_link_product.dart';
import 'package:pos_system/object/ingredient_company.dart';
import 'package:pos_system/object/ingredient_company_link_branch.dart';
import 'package:pos_system/object/modifier_group.dart';
import 'package:pos_system/object/modifier_item.dart';
import 'package:pos_system/object/modifier_link_product.dart';
import 'package:pos_system/object/product.dart';
import 'package:pos_system/object/product_variant.dart';
import 'package:pos_system/object/product_variant_detail.dart';
import 'package:pos_system/object/table.dart';
import 'package:pos_system/object/variant_group.dart';
import '../main.dart';
import '../object/branch_link_product.dart';
import '../object/variant_item.dart';
import 'domain.dart';

enum FirestoreStatus{
  online,
  offline
}

class PosFirestore {
  static final PosFirestore instance = PosFirestore._init();
  static final BuildContext context = MyApp.navigatorKey.currentContext!;
  static FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static FirestoreStatus _firestore_status = FirestoreStatus.offline;
  static PosDatabase _posDatabase = PosDatabase.instance;
  static final tb_table_dynamic = 'tb_table_dynamic';

  PosFirestore._init();

  FirebaseFirestore get firestore => _firestore;

  FirestoreStatus get firestore_status => _firestore_status;

  set setFirestoreStatus(FirestoreStatus status) {
    _firestore_status = status;
  }

  insertBranch(Branch branch) async {
    if(firestore_status == FirestoreStatus.offline){
      return;
    }
    branch.firestore_db_version = await _posDatabase.dbVersion;
    await firestore.collection(tableBranch!).doc(branch.branch_id.toString()).set(branch.toFirestoreJson(), SetOptions(merge: true));
  }

  insertBranchLinkDining(BranchLinkDining data) async {
    if(firestore_status == FirestoreStatus.offline){
      return;
    }
    await firestore.collection(tableBranchLinkDining!).doc(data.branch_link_dining_id.toString()).set(data.toJson(), SetOptions(merge: true));
  }

  insertBranchLinkModifier(BranchLinkModifier data) async {
    if(firestore_status == FirestoreStatus.offline){
      return;
    }
    await firestore.collection(tableBranchLinkModifier!).doc(data.branch_link_modifier_id.toString()).set(data.toJson(), SetOptions(merge: true));
  }

  insertBranchLinkProduct(BranchLinkProduct data) async {
    if(firestore_status == FirestoreStatus.offline){
      return;
    }
    await firestore.collection(tableBranchLinkProduct!).doc(data.branch_link_product_id.toString()).set(data.toJson(), SetOptions(merge: true));
  }

  insertBranchLinkPromotion(BranchLinkPromotion data) async {
    if(firestore_status == FirestoreStatus.offline){
      return;
    }
    await firestore.collection(tableBranchLinkPromotion!).doc(data.branch_link_promotion_id.toString()).set(data.toJson(), SetOptions(merge: true));
  }

  insertBranchLinkTax(BranchLinkTax data) async {
    if(firestore_status == FirestoreStatus.offline){
      return;
    }
    await firestore.collection(tableBranchLinkTax!).doc(data.branch_link_tax_id.toString()).set(data.toJson(), SetOptions(merge: true));
  }

  insertCategory(Categories data) async {
    if(firestore_status == FirestoreStatus.offline){
      return;
    }
    await firestore.collection(tableCategories!).doc(data.category_id.toString()).set(data.toJson(), SetOptions(merge: true));
  }

  insertDiningOption(DiningOption data) async {
    if(firestore_status == FirestoreStatus.offline){
      return;
    }
    await firestore.collection(tableDiningOption!).doc(data.dining_id.toString()).set(data.toJson(), SetOptions(merge: true));
  }

  insertModifierGroup(ModifierGroup data) async {
    if(firestore_status == FirestoreStatus.offline){
      return;
    }
    await firestore.collection(tableModifierGroup!).doc(data.mod_group_id.toString()).set(data.toJson2(), SetOptions(merge: true));
  }

  insertModifierItem(ModifierItem data) async {
    if(firestore_status == FirestoreStatus.offline){
      return;
    }
    await firestore.collection(tableModifierItem!).doc(data.mod_item_id.toString()).set(data.toJson2(), SetOptions(merge: true));
  }

  insertModifierLinkProduct(ModifierLinkProduct data) async {
    if(firestore_status == FirestoreStatus.offline){
      return;
    }
    await firestore.collection(tableModifierLinkProduct!).doc(data.modifier_link_product_id.toString()).set(data.toJson(), SetOptions(merge: true));
  }

  insertIngredientCompany(IngredientCompany data) async {
    if(firestore_status == FirestoreStatus.offline){
      return;
    }
    await firestore.collection(tableIngredientCompany!).doc(data.ingredient_company_id.toString()).set(data.toJson(), SetOptions(merge: true));
  }

  insertIngredientCompanyLinkBranch(IngredientCompanyLinkBranch data) async {
    if(firestore_status == FirestoreStatus.offline){
      return;
    }
    await firestore.collection(tableIngredientCompanyLinkBranch!).doc(data.ingredient_company_link_branch_id.toString()).set(data.toJson(), SetOptions(merge: true));
  }

  insertIngredientBranchLinkProduct(IngredientBranchLinkProduct data) async {
    if(firestore_status == FirestoreStatus.offline){
      return;
    }
    await firestore.collection(tableIngredientBranchLinkProduct!).doc(data.ingredient_branch_link_product_id.toString()).set(data.toJson(), SetOptions(merge: true));
  }

  insertProduct(Product data) async {
    if(firestore_status == FirestoreStatus.offline){
      return;
    }
    await firestore.collection(tableProduct!).doc(data.product_id.toString()).set(data.toJson(), SetOptions(merge: true));
  }

  updateProduct(Product data) async {
    if(firestore_status == FirestoreStatus.offline){
      return;
    }
    await firestore.collection(tableProduct!).doc(data.product_id.toString()).update(data.toJson());
  }

  insertProductVariant(ProductVariant data) async {
    if(firestore_status == FirestoreStatus.offline){
      return;
    }
    await firestore.collection(tableProductVariant!).doc(data.product_variant_id.toString()).set(data.toJson(), SetOptions(merge: true));
  }

  insertProductVariantDetail(ProductVariantDetail data) async {
    if(firestore_status == FirestoreStatus.offline){
      return;
    }
    await firestore.collection(tableProductVariantDetail!).doc(data.product_variant_detail_id.toString()).set(data.toJson(), SetOptions(merge: true));
  }

  insertPosTable(PosTable data) async {
    if(firestore_status == FirestoreStatus.offline){
      return;
    }
    await firestore.collection(tablePosTable!).doc(data.table_id.toString()).set(data.toJson(), SetOptions(merge: true));
  }

  insertVariantGroup(VariantGroup data) async {
    if(firestore_status == FirestoreStatus.offline){
      return;
    }
    await firestore.collection(tableVariantGroup!).doc(data.variant_group_id.toString()).set(data.toInsertJson(), SetOptions(merge: true));
  }

  insertVariantItem(VariantItem data) async {
    if(firestore_status == FirestoreStatus.offline){
      return;
    }
    await firestore.collection(tableVariantItem!).doc(data.variant_item_id.toString()).set(data.toJson(), SetOptions(merge: true));
  }

  insertTableDynamic(PosTable data) async {
    if(firestore_status == FirestoreStatus.offline){
      return;
    }
    await firestore.collection(tb_table_dynamic).doc(data.table_id!.toString()).set(data.toTableDynamicJson(), SetOptions(merge: true));
  }

  Future<int> softDeleteOneTimeQr(PosTable data) async {
    int status = 0;
    try{
      if(firestore_status == FirestoreStatus.offline){
        return 0;
      }
      final batch = firestore.batch();
      Map<String, dynamic> jsonMap = {
        PosTableFields.soft_delete: data.soft_delete,
      };
      final docSnapshot = await firestore.collection(tb_table_dynamic).doc(data.table_id!.toString()).get();
      if(docSnapshot.exists) {
        final data = docSnapshot.data() as Map<String, dynamic>;
        if(data['invalid_after_payment'] == 1){
          batch.update(docSnapshot.reference, jsonMap);
          batch.commit();
          status = 1;
        }
      }
    }catch(e){
      FLog.error(
        className: "pos_firestore",
        text: "softDeleteTableDynamic error",
        exception: e,
      );
      status = 0;
    }
    return status;
  }

  Future<int> updateBranchCloseQROrderStatus(Branch data) async {
    int status = 0;
    try{
     if(firestore_status == FirestoreStatus.offline){
        return 0;
      }
      final batch = firestore.batch();
      Map<String, dynamic> jsonMap = {
        BranchFields.close_qr_order: data.close_qr_order,
      };
      final docRef = await firestore.collection(tableBranch!).doc(data.branch_id!.toString());
      batch.update(docRef, jsonMap);
      batch.commit();
      status = 1;
    }catch(e){
      FLog.error(
        className: "pos_firestore",
        text: "updateBranchCloseQROrderStatus error",
        exception: e,
      );
      status = 0;
    }
    return status;
  }

  Future<int> updateBranchLinkProductDailyLimit(BranchLinkProduct branchProduct) async {
    int status = 0;
    try{
     if(firestore_status == FirestoreStatus.offline){
        return 0;
      }
      final batch = firestore.batch();
      Map<String, dynamic> jsonMap = {
        BranchLinkProductFields.updated_at: branchProduct.updated_at,
        BranchLinkProductFields.daily_limit: branchProduct.daily_limit,
      };
      final docRef = await firestore.collection(tableBranchLinkProduct!).doc(branchProduct.branch_link_product_id!.toString());
      batch.update(docRef, jsonMap);
      batch.commit();
      status = 1;
    }catch(e){
      FLog.error(
        className: "pos_firestore",
        text: "updateBranchLinkProductDailyLimit error",
        exception: e,
      );
      status = 0;
    }
    return status;
  }

  Future<int> updateBranchLinkProductStock(BranchLinkProduct branchProduct) async {
    int status = 0;
    try{
     if(firestore_status == FirestoreStatus.offline){
        return 0;
      }
      final batch = firestore.batch();
      Map<String, dynamic> jsonMap = {
        BranchLinkProductFields.updated_at: branchProduct.updated_at,
        BranchLinkProductFields.stock_quantity: branchProduct.stock_quantity,
      };
      final docRef = await firestore.collection(tableBranchLinkProduct!).doc(branchProduct.branch_link_product_id!.toString());
      batch.update(docRef, jsonMap);
      batch.commit();
      status = 1;
    }catch(e){
      FLog.error(
        className: "pos_firestore",
        text: "updateBranchLinkProductStock error",
        exception: e,
      );
      status = 0;
    }
    return status;
  }

  Future<int> updateIngredientCompanyLinkBranchStock(IngredientCompanyLinkBranch branchIngredient) async {
    int status = 0;
    try{
     if(firestore_status == FirestoreStatus.offline){
        return 0;
      }
      final batch = firestore.batch();
      Map<String, dynamic> jsonMap = {
        BranchLinkProductFields.updated_at: branchIngredient.updated_at,
        BranchLinkProductFields.stock_quantity: branchIngredient.stock_quantity,
      };
      final docRef = await firestore.collection(tableIngredientCompanyLinkBranch!).doc(branchIngredient.ingredient_company_link_branch_id!.toString());
      batch.update(docRef, jsonMap);
      batch.commit();
      status = 1;
    }catch(e){
      FLog.error(
        className: "pos_firestore",
        text: "updateIngredientCompanyLinkBranchStock error",
        exception: e,
      );
      status = 0;
    }
    return status;
  }

  Future<Branch?> readCurrentBranch(String branch_id) async {
    if(firestore_status == 0){
      return null;
    }
    var snapshot = await firestore.collection(tableBranch!).doc(branch_id).get();
    if(snapshot.data() != null){
      return Branch.fromJson(snapshot.data()!);
    } else {
      return null;
    }
  }

/*
  for debug use only
*/
  transferDatabaseData() async {
    try{
      Map res = await Domain().transferDatabaseData('tb_branch_link_product');
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
            await firestore.collection("tb_branch_link_product").doc(chunk[j]['branch_link_product_id'].toString()).set(chunk[j]);
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

  offline(){
    print("im offline");
    firestore.disableNetwork();
  }

  online(){
    firestore.enableNetwork().then((_) {
      // Back online
      print("im online");
    });

  }
}