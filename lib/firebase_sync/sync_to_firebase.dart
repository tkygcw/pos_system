import 'package:pos_system/database/pos_database.dart';
import 'package:pos_system/database/pos_firestore.dart';
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
  static final SyncToFirebase instance = SyncToFirebase.init();
  static PosFirestore posFirestore = PosFirestore.instance;
  static bool isBranchExisted = false;
  SyncToFirebase.init();

  syncToFirebase() async {
    print("sync to firebase called!!!");
    if(isBranchExisted == false){
      final prefs = await SharedPreferences.getInstance();
      final int? branch_id = prefs.getInt('branch_id');
      Branch? data = await PosFirestore.instance.readCurrentBranch(branch_id.toString());
      print("branch data in syncToFirebase: ${data}");
      if(data == null){
        print("perform sync");
        sync();
      }
    }
  }

  checkBranchInFirestore(Branch branch) async {
    if(branch.allow_firestore == 0) {
      posFirestore.setFirestoreStatus = FirestoreStatus.offline;
    } else {
      posFirestore.setFirestoreStatus = FirestoreStatus.online;
      Branch? data = await PosFirestore.instance.readCurrentBranch(branch.branch_id.toString());
      print("branch data in checkBranchInFirestore: ${data}");
      if(data == null){
        syncBranch();
      }
    }
    isBranchExisted = true;
  }

  sync() async {
    Branch? data = await PosDatabase.instance.readLocalBranch();
    if(data != null && data.qr_order_status == '0' && data.allow_firestore == 1){
      syncVariantItem();
      syncVariantGroup();
      syncPosTable();
      syncProductVariantDetail();
      syncProductVariant();
      syncProduct();
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
    Branch? data = await PosDatabase.instance.readLocalBranch();
    if(data != null && data.allow_firestore == 1){
      PosFirestore.instance.insertBranch(data);
    }
  }

  syncBranchLinkDiningOption() async {
    List<BranchLinkDining> branchLinkDining = await PosDatabase.instance.readLocalBranchLinkDining();
    for(final dining in branchLinkDining){
      PosFirestore.instance.insertBranchLinkDining(dining);
    }
  }

  syncBranchLinkModifier() async{
    List<BranchLinkModifier> branchLinkModifier = await PosDatabase.instance.readLocalBranchLinkModifier();
    for(final branchModifier in branchLinkModifier){
      PosFirestore.instance.insertBranchLinkModifier(branchModifier);
    }
  }

  syncBranchLinkProduct() async{
    List<BranchLinkProduct> branchLinkProduct = await PosDatabase.instance.readLocalBranchLinkProduct();
    for(final branchProduct in branchLinkProduct){
      PosFirestore.instance.insertBranchLinkProduct(branchProduct);
    }
  }

  syncBranchLinkPromotion() async{
    List<BranchLinkPromotion> branchLinkPromotion = await PosDatabase.instance.readLocalBranchLinkPromotion();
    for(final branchPromotion in branchLinkPromotion){
      PosFirestore.instance.insertBranchLinkPromotion(branchPromotion);
    }
  }

  syncBranchLinkTax() async{
    List<BranchLinkTax> branchLinkTax = await PosDatabase.instance.readLocalBranchLinkTax();
    for(final branchTax in branchLinkTax){
      PosFirestore.instance.insertBranchLinkTax(branchTax);
    }
  }

  syncDiningOption() async{
    List<DiningOption> diningOption = await PosDatabase.instance.readLocalDiningOption();
    for(final option in diningOption){
      PosFirestore.instance.insertDiningOption(option);
    }
  }

  syncCategories() async{
    List<Categories> categories = await PosDatabase.instance.readLocalCategories();
    for(final category in categories){
      PosFirestore.instance.insertCategory(category);
    }
  }

  syncModifierGroup() async {
    List<ModifierGroup> modifierGroup = await PosDatabase.instance.readLocalModifierGroup();
    for(final group in modifierGroup){
      PosFirestore.instance.insertModifierGroup(group);
    }
  }

  syncModifierItem() async {
    List<ModifierItem> modifierItem = await PosDatabase.instance.readLocalModifierItem();
    for(final item in modifierItem){
      PosFirestore.instance.insertModifierItem(item);
    }
  }

  syncModifierLinkProduct() async {
    List<ModifierLinkProduct> modLinkProduct = await PosDatabase.instance.readLocalModifierLinkProduct();
    for(final productMod in modLinkProduct){
      PosFirestore.instance.insertModifierLinkProduct(productMod);
    }
  }

  syncProduct() async {
    List<Product> product = await PosDatabase.instance.readLocalProduct();
    for(final products in product){
      PosFirestore.instance.insertProduct(products);
    }
  }

  syncProductVariant() async {
      List<ProductVariant> productVariant = await PosDatabase.instance.readLocalProductVariant();
      for(final productVariants in productVariant){
        PosFirestore.instance.insertProductVariant(productVariants);
      }
  }

  syncProductVariantDetail() async {
    List<ProductVariantDetail> productVariantDetail = await PosDatabase.instance.readLocalProductVariantDetail();
    for(final detail in productVariantDetail){
      PosFirestore.instance.insertProductVariantDetail(detail);
    }
  }

  syncPosTable() async {
    List<PosTable> posTable = await PosDatabase.instance.readLocalPosTable();
    for(final table in posTable){
      PosFirestore.instance.insertPosTable(table);
    }
  }

  syncVariantGroup() async {
    List<VariantGroup> variantGroup = await PosDatabase.instance.readLocalVariantGroup();
    for(final group in variantGroup){
      PosFirestore.instance.insertVariantGroup(group);
    }
  }

  syncVariantItem() async {
    List<VariantItem> variantItem = await PosDatabase.instance.readLocalVariantItem();
    for(final item in variantItem){
      PosFirestore.instance.insertVariantItem(item);
    }
  }

}