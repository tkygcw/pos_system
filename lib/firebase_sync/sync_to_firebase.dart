import 'package:pos_system/database/pos_database.dart';
import 'package:pos_system/database/pos_firestore.dart';
import 'package:pos_system/database/pos_firestore_utils.dart';
import 'package:pos_system/object/branch.dart';
import 'package:pos_system/object/branch_link_dining_option.dart';
import 'package:pos_system/object/branch_link_modifier.dart';
import 'package:pos_system/object/branch_link_product.dart';
import 'package:pos_system/object/branch_link_tax.dart';
import 'package:pos_system/object/categories.dart';
import 'package:pos_system/object/dining_option.dart';
import 'package:pos_system/object/modifier_group.dart';
import 'package:pos_system/object/modifier_item.dart';
import 'package:pos_system/object/modifier_link_product.dart';
import 'package:pos_system/object/product.dart';
import 'package:pos_system/object/product_variant.dart';
import 'package:pos_system/object/table.dart';
import 'package:pos_system/object/variant_group.dart';
import 'package:pos_system/object/variant_item.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../object/branch_link_promotion.dart';
import '../object/product_variant_detail.dart';

class SyncToFirebase {
  static final SyncToFirebase instance = SyncToFirebase._init();
  static PosFirestore posFirestore = PosFirestore.instance;
  static PosDatabase _posDatabase = PosDatabase.instance;
  static bool isBranchExisted = false;

  SyncToFirebase._init();

  FirestoreStatus get _firestore_status => posFirestore.firestore_status;

  syncToFirebase() async {
    print("sync to firebase called!!!");
    if(isBranchExisted == false && _firestore_status == FirestoreStatus.online){
      final localDbVersion = await _posDatabase.dbVersion;
      final prefs = await SharedPreferences.getInstance();
      final int? branch_id = prefs.getInt('branch_id');
      Branch? data = await posFirestore.readCurrentBranch(branch_id.toString());
      if(data == null) {
        print("perform sync");
        sync();
      } else {
        if(data.firestore_db_version == null){
          syncBranch();
        } else {
          PosFirestoreUtils.onUpgrade(data.firestore_db_version!, localDbVersion);
        }
      }
    }
  }

  checkBranchInFirestore(Branch branch) async {
    if(branch.allow_firestore == 0) {
      posFirestore.setFirestoreStatus = FirestoreStatus.offline;
    } else {
      final localDbVersion = await _posDatabase.dbVersion;
      posFirestore.setFirestoreStatus = FirestoreStatus.online;
      Branch? data = await posFirestore.readCurrentBranch(branch.branch_id.toString());
      if(data == null){
        syncBranch();
      } else {
        if(data.firestore_db_version == null){
          syncBranch();
        } else if(data.firestore_db_version! < localDbVersion) {
          syncBranch();
        }
      }
    }
    isBranchExisted = true;
  }

  sync() async {
    Branch? data = await _posDatabase.readLocalBranch();
    if(data != null && data.qr_order_status == '0' && data.allow_firestore == 1){
      syncVariantItem();
      syncVariantGroup();
      syncPosTable();
      syncProductVariantDetail();
      syncProductVariant();
      syncProduct();
      updateProduct();
      syncModifierLinkProduct();
      syncModifierItem();
      syncModifierGroup();
      syncDiningOption();
      syncCategories();
      syncBranchLinkTax();
      syncBranchLinkPromotion();
      syncBranchLinkProduct();
      syncBranchLinkModifier();
      syncBranchLinkDiningOption();
      syncBranch();
    }
  }

  syncBranch() async {
    Branch? data = await _posDatabase.readLocalBranch();
    if(data != null && data.allow_firestore == 1){
      posFirestore.insertBranch(data);
    }
  }

  syncBranchLinkDiningOption() async {
    List<BranchLinkDining> branchLinkDining = await _posDatabase.readLocalBranchLinkDining();
    for(final dining in branchLinkDining){
      posFirestore.insertBranchLinkDining(dining);
    }
  }

  syncBranchLinkModifier() async{
    List<BranchLinkModifier> branchLinkModifier = await _posDatabase.readLocalBranchLinkModifier();
    for(final branchModifier in branchLinkModifier){
      posFirestore.insertBranchLinkModifier(branchModifier);
    }
  }

  syncBranchLinkProduct() async{
    List<BranchLinkProduct> branchLinkProduct = await _posDatabase.readLocalBranchLinkProduct();
    for(final branchProduct in branchLinkProduct){
      posFirestore.insertBranchLinkProduct(branchProduct);
    }
  }

  syncBranchLinkPromotion() async{
    List<BranchLinkPromotion> branchLinkPromotion = await _posDatabase.readLocalBranchLinkPromotion();
    for(final branchPromotion in branchLinkPromotion){
      posFirestore.insertBranchLinkPromotion(branchPromotion);
    }
  }

  syncBranchLinkTax() async{
    List<BranchLinkTax> branchLinkTax = await _posDatabase.readLocalBranchLinkTax();
    for(final branchTax in branchLinkTax){
      posFirestore.insertBranchLinkTax(branchTax);
    }
  }

  syncDiningOption() async{
    List<DiningOption> diningOption = await _posDatabase.readLocalDiningOption();
    for(final option in diningOption){
      posFirestore.insertDiningOption(option);
    }
  }

  syncCategories() async{
    List<Categories> categories = await _posDatabase.readLocalCategories();
    for(final category in categories){
      posFirestore.insertCategory(category);
    }
  }

  syncModifierGroup() async {
    List<ModifierGroup> modifierGroup = await _posDatabase.readLocalModifierGroup();
    for(final group in modifierGroup){
      posFirestore.insertModifierGroup(group);
    }
  }

  syncModifierItem() async {
    List<ModifierItem> modifierItem = await _posDatabase.readLocalModifierItem();
    for(final item in modifierItem){
      posFirestore.insertModifierItem(item);
    }
  }

  syncModifierLinkProduct() async {
    List<ModifierLinkProduct> modLinkProduct = await _posDatabase.readLocalModifierLinkProduct();
    for(final productMod in modLinkProduct){
      posFirestore.insertModifierLinkProduct(productMod);
    }
  }

  syncProduct() async {
    List<Product> product = await _posDatabase.readLocalProduct();
    for(final products in product){
      posFirestore.insertProduct(products);
    }
  }

  updateProduct() async {
    List<Product> product = await _posDatabase.readAllNotSyncUpdatedProduct(1000);
    for(final products in product){
      posFirestore.updateProduct(products);
    }
  }

  syncProductVariant() async {
      List<ProductVariant> productVariant = await _posDatabase.readLocalProductVariant();
      for(final productVariants in productVariant){
        posFirestore.insertProductVariant(productVariants);
      }
  }

  syncProductVariantDetail() async {
    List<ProductVariantDetail> productVariantDetail = await _posDatabase.readLocalProductVariantDetail();
    for(final detail in productVariantDetail){
      posFirestore.insertProductVariantDetail(detail);
    }
  }

  syncPosTable() async {
    List<PosTable> posTable = await _posDatabase.readLocalPosTable();
    for(final table in posTable){
      posFirestore.insertPosTable(table);
    }
  }

  syncVariantGroup() async {
    List<VariantGroup> variantGroup = await _posDatabase.readLocalVariantGroup();
    for(final group in variantGroup){
      posFirestore.insertVariantGroup(group);
    }
  }

  syncVariantItem() async {
    List<VariantItem> variantItem = await _posDatabase.readLocalVariantItem();
    for(final item in variantItem){
      posFirestore.insertVariantItem(item);
    }
  }

}