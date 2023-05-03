import 'dart:convert';
import 'dart:io';

import 'package:pos_system/object/branch.dart';
import 'package:pos_system/object/branch_link_promotion.dart';
import 'package:pos_system/object/payment_link_company.dart';
import 'package:pos_system/object/product.dart';
import 'package:pos_system/object/product_variant.dart';
import 'package:pos_system/object/product_variant_detail.dart';
import 'package:pos_system/object/promotion.dart';
import 'package:pos_system/object/table.dart';
import 'package:pos_system/object/tax.dart';
import 'package:pos_system/object/tax_link_dining.dart';
import 'package:pos_system/object/user.dart';
import 'package:pos_system/object/variant_group.dart';
import 'package:pos_system/object/variant_item.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

import '../database/domain.dart';
import '../database/pos_database.dart';
import 'branch_link_dining_option.dart';
import 'branch_link_modifier.dart';
import 'branch_link_product.dart';
import 'branch_link_tax.dart';
import 'branch_link_user.dart';
import 'categories.dart';
import 'customer.dart';
import 'dining_option.dart';
import 'modifier_group.dart';
import 'modifier_item.dart';
import 'modifier_link_product.dart';

class SyncRecord {

  syncFromCloud() async {
    print("sync from cloud call");
    return await checkAllSyncRecord();
  }

  checkAllSyncRecord() async {
    final prefs = await SharedPreferences.getInstance();
    final String? user = prefs.getString('user');
    final String? branch = prefs.getString('branch');
    final int? device_id = prefs.getInt('device_id');
    final String? login_value = prefs.getString('login_value');
    if(user != null){
      Map userObject = json.decode(user);
      Map branchObject = json.decode(branch!);
      Map data = await Domain().getAllSyncRecord('${branchObject['branchID']}', device_id.toString(), login_value.toString());
      List<int> syncRecordIdList = [];
      if (data['status'] == '1') {
        print('status 1 called!');
        List responseJson = data['data'];
        for (var i = 0; i < responseJson.length; i++) {
          switch(responseJson[i]['type']){
            case '0':
              bool status = await callProductQuery(data: responseJson[i]['data'], method: responseJson[i]['method']);
              print('product status: ${status}');
              if(status == true){
                syncRecordIdList.add(responseJson[i]['id']);
              }
              break;
            case '1':
              bool status = await callCategoryQuery(data: responseJson[i]['data'], method: responseJson[i]['method']);
              if(status == true){
                syncRecordIdList.add(responseJson[i]['id']);
              }
              break;
            case '2':
              bool status = await callModifierLinkProductQuery(data: responseJson[i]['data'], method: responseJson[i]['method']);
              if(status == true){
                syncRecordIdList.add(responseJson[i]['id']);
              }
              break;
            case '3':
              bool status = await callVariantGroupQuery(data: responseJson[i]['data'], method: responseJson[i]['method']);
              if(status == true){
                syncRecordIdList.add(responseJson[i]['id']);
              }
              break;
            case '4':
              bool status = await callVariantItemQuery(data: responseJson[i]['data'], method: responseJson[i]['method']);
              if(status == true){
                syncRecordIdList.add(responseJson[i]['id']);
              }
              break;
            case '5':
              bool status = await callProductVariantQuery(data: responseJson[i]['data'], method: responseJson[i]['method']);
              if(status == true){
                syncRecordIdList.add(responseJson[i]['id']);
              }
              break;
            case '6':
              bool status = await callProductVariantDetailQuery(data: responseJson[i]['data'], method: responseJson[i]['method']);
              if(status == true){
                syncRecordIdList.add(responseJson[i]['id']);
              }
              break;
            case '7':
              bool status = await callBranchLinkProductQuery(data: responseJson[i]['data'], method: responseJson[i]['method']);
              print('status 7: ${status}');
              if(status == true){
                syncRecordIdList.add(responseJson[i]['id']);
              }
              break;
            case '8':
              bool status = await callModifierGroupQuery(data: responseJson[i]['data'], method: responseJson[i]['method']);
              if(status == true){
                syncRecordIdList.add(responseJson[i]['id']);
              }
              break;
            case '9':
              bool status = await callModifierItemQuery(data: responseJson[i]['data'], method: responseJson[i]['method']);
              if(status == true){
                syncRecordIdList.add(responseJson[i]['id']);
              }
              break;
            case '10':
              bool status = await callBranchLinkModifierQuery(data: responseJson[i]['data'], method: responseJson[i]['method']);
              if(status == true){
                syncRecordIdList.add(responseJson[i]['id']);
              }
              break;
            case '11':
              bool status = await callUserQuery(data: responseJson[i]['data'], method: responseJson[i]['method']);
              if(status == true){
                syncRecordIdList.add(responseJson[i]['id']);
              }
              break;
            case '12':
              bool status = await callBranchLinkUserQuery(data: responseJson[i]['data'], method: responseJson[i]['method']);
              if(status == true){
                syncRecordIdList.add(responseJson[i]['id']);
              }
              break;
            case '13':
              bool status = await callCustomerQuery(data: responseJson[i]['data'], method: responseJson[i]['method']);
              if(status == true){
                syncRecordIdList.add(responseJson[i]['id']);
              }
              break;
            case '14':
              print('14 called');
              bool status = await callPaymentLinkCompanyQuery(data: responseJson[i]['data'], method: responseJson[i]['method']);
              if(status == true){
                syncRecordIdList.add(responseJson[i]['id']);
              }
              break;
            case'15':
              bool status = await callTaxQuery(data: responseJson[i]['data'], method: responseJson[i]['method']);
              if(status == true){
                syncRecordIdList.add(responseJson[i]['id']);
              }
              break;
            case '16':
              bool status = await callBranchLinkTax(data: responseJson[i]['data'], method: responseJson[i]['method']);
              if(status == true){
                syncRecordIdList.add(responseJson[i]['id']);
              }
              break;
            case '17':
              bool status = await callTaxLinkDining(data: responseJson[i]['data'], method: responseJson[i]['method']);
              if(status == true){
                syncRecordIdList.add(responseJson[i]['id']);
              }
              break;
            case '18':
              bool status = await callDiningOptionQuery(data: responseJson[i]['data'], method: responseJson[i]['method']);
              if(status == true){
                syncRecordIdList.add(responseJson[i]['id']);
              }
              break;
            case '19':
              bool status = await callBranchLinkDiningQuery(data: responseJson[i]['data'], method: responseJson[i]['method']);
              if(status == true){
                syncRecordIdList.add(responseJson[i]['id']);
              }
              break;
            case '20':
              bool status = await callPosTableQuery(data: responseJson[i]['data'], method: responseJson[i]['method']);
              if(status == true){
                syncRecordIdList.add(responseJson[i]['id']);
              }
              break;
            case '21':
              bool status = await callPromotionQuery(data: responseJson[i]['data'], method: responseJson[i]['method']);
              if(status == true){
                syncRecordIdList.add(responseJson[i]['id']);
              }
              break;
            case '22':
              bool status = await callBranchLinkPromotionQuery(data: responseJson[i]['data'], method: responseJson[i]['method']);
              if(status == true){
                syncRecordIdList.add(responseJson[i]['id']);
              }
              break;
          }
        }
        print('sync record length: ${syncRecordIdList.length}');
        //update sync record
        Map updateResponse = await Domain().updateAllCloudSyncRecord('${branchObject['branchID']}', syncRecordIdList.toString());
        return false;
      } else if (data['status'] == '7'){
        return true;
      }
    }
  }

  callBranchLinkPromotionQuery({data, method}) async {
    bool isComplete = false;
    BranchLinkPromotion branchLinkPromotion = BranchLinkPromotion.fromJson(data[0]);
    try{
      if(method == '0'){
        BranchLinkPromotion data = await PosDatabase.instance.insertBranchLinkPromotion(branchLinkPromotion);
        if(data.created_at != ''){
          isComplete = true;
        }
      }else {
        int data = await PosDatabase.instance.updateBranchLinkPromotion(branchLinkPromotion);
        if(data == 1){
          isComplete = true;
        }
      }
      return isComplete;

    } catch(e){
      return isComplete = false;
    }

  }

  callPromotionQuery({data, method}) async {
    bool isComplete = false;
    Promotion promotion = Promotion.fromJson(data[0]);
    try{
      if(method == '0'){
        Promotion data = await PosDatabase.instance.insertPromotion(promotion);
        if(data.created_at != ''){
          isComplete = true;
        }
      }else {
        int data = await PosDatabase.instance.updatePromotion(promotion);
        if(data == 1){
          isComplete = true;
        }
      }
      return isComplete;

    } catch(e){
      return isComplete = false;
    }

  }

  callPosTableQuery({data, method}) async {
    bool isComplete = false;
    PosTable posTable = PosTable.fromJson(data[0]);
    try{
      if(method == '0'){
        PosTable data = await PosDatabase.instance.insertPosTable(posTable);
        if(data.created_at != ''){
          isComplete = true;
        }
      }else {
        int data = await PosDatabase.instance.updatePosTableSyncRecord(posTable);
        if(data == 1){
          isComplete = true;
        }
      }
      return isComplete;
    } catch(e){
      return isComplete = false;
    }

  }

  callBranchLinkDiningQuery({data, method}) async {
    bool isComplete = false;
    BranchLinkDining diningData = BranchLinkDining.fromJson(data[0]);
    try{
      if(method == '0'){
        BranchLinkDining data = await PosDatabase.instance.insertBranchLinkDining(diningData);
        if(data.created_at != ''){
          isComplete = true;
        }
      } else{
        int data = await PosDatabase.instance.updateBranchLikDining(diningData);
        if(data == 1){
          isComplete = true;
        }
      }
      return isComplete;

    } catch(e){
      return isComplete = false;
    }
  }

  callDiningOptionQuery({data, method}) async {
    bool isComplete = false;
    DiningOption diningOption = DiningOption.fromJson(data[0]);
    if(method == '0'){
      DiningOption data = await PosDatabase.instance.insertDiningOption(diningOption);
      if(data.created_at != ''){
        isComplete = true;
      }
    } else {
      int data = await PosDatabase.instance.updateDiningOption(diningOption);
      if(data == 1){
        isComplete = true;
      }
    }
    return isComplete;
  }

  callTaxLinkDining({data, method}) async {
    bool isComplete = false;
    TaxLinkDining taxData = TaxLinkDining.fromJson(data[0]);
    try{
      if(method == '0'){
        TaxLinkDining data = await PosDatabase.instance.insertTaxLinkDining(taxData);
        if(data.created_at != ''){
          isComplete = true;
        }
      } else {
        int data = await PosDatabase.instance.updateTaxLinkDining(taxData);
        if(data == 1){
          isComplete = true;
        }
      }
      return isComplete;
    } catch(e){
      return isComplete = false;
    }
  }

  callBranchLinkTax({data, method}) async {
    bool isComplete = false;
    BranchLinkTax taxData = BranchLinkTax.fromJson(data[0]);
    try{
      if(method == '0'){
        BranchLinkTax data = await PosDatabase.instance.insertBranchLinkTax(taxData);
        if(data.created_at != ''){
          isComplete = true;
        }
      } else {
        int data = await PosDatabase.instance.updateBranchLinkTax(taxData);
        print('update status: ${data}');
        if(data == 1){
          isComplete = true;
        }
      }
      return isComplete;
    } catch(e){
      return isComplete = false;
    }
  }

  callTaxQuery({data, method}) async {
    bool isComplete = false;
    Tax taxData = Tax.fromJson(data[0]);
    try{
      if(method == '0'){
        Tax data = await PosDatabase.instance.insertTax(taxData);
        if(data.created_at != ''){
          isComplete = true;
        }
      }else {
        int data = await PosDatabase.instance.updateTax(taxData);
        if(data == 1){
          isComplete = true;
        }
      }
      return isComplete;
    } catch(e){
      print('tax query error: ${e}');
      return isComplete = false;
    }
  }

  callPaymentLinkCompanyQuery({data, method}) async {
    bool isComplete = false;
    PaymentLinkCompany paymentData = PaymentLinkCompany.fromJson(data[0]);
    try{
      if(method == '0'){
        PaymentLinkCompany data = await PosDatabase.instance.insertPaymentLinkCompany(paymentData);
        if(data.created_at != ''){
          isComplete = true;
        }
      } else {
        int data = await PosDatabase.instance.updatePaymentLinkCompany(paymentData);
        if(data == 1){
          isComplete = true;
        }
      }
      return isComplete;
    } catch(e){
      return isComplete = false;
    }
  }

  callCustomerQuery({data, method}) async {
    bool isComplete = false;
    Customer customerData = Customer.fromJson(data[0]);
    if(method == '0'){
      Customer data = await PosDatabase.instance.insertCustomer(customerData);
      if(data.created_at != ''){
        isComplete = true;
      }
    } else {
      int data = await PosDatabase.instance.updateCustomer(customerData);
      if(data == 1){
        isComplete = true;
      }
    }
    return isComplete;
  }

  callBranchLinkUserQuery({data, method}) async {
    bool isComplete = false;
    BranchLinkUser branchLinkUserData = BranchLinkUser.fromJson(data[0]);
    if(method == '0'){
      //create
      BranchLinkUser data = await PosDatabase.instance.insertBranchLinkUser(branchLinkUserData);
      if(data.created_at != ''){
        isComplete = true;
      }
    } else {
      //update
      int data = await PosDatabase.instance.updateBranchLinkUser(branchLinkUserData);
      if(data == 1){
        isComplete = true;
      }
    }
    return isComplete;
  }

  callUserQuery({data, method}) async {
    bool isComplete = false;
    User userData = User.fromJson(data[0]);
    if(method == '0'){
      //create
      User user = await PosDatabase.instance.insertUser(userData);
      if(user.created_at != ''){
        isComplete = true;
      }
    } else {
      //update
      int data = await PosDatabase.instance.updateUser(userData);
      if(data == 1){
        isComplete = true;
      }
    }
    return isComplete;
  }

  callBranchLinkModifierQuery({data, method}) async {
    bool isComplete = false;
    BranchLinkModifier branchLinkModifierData = BranchLinkModifier.fromJson(data[0]);
    if(method == '0'){
      //create
      BranchLinkModifier insertData = await PosDatabase.instance.insertBranchLinkModifier(branchLinkModifierData);
      if(insertData.created_at != ''){
        isComplete = true;
      }
    } else {
      //update
      int updateData = await PosDatabase.instance.updateBranchLinkModifier(branchLinkModifierData);
      if(updateData == 1){
        isComplete = true;
      }
    }
    return isComplete;
  }

  callModifierItemQuery({data, method}) async {
    bool isComplete = false;
    ModifierItem modifierItemData = ModifierItem.fromJson(data[0]);
    if(method == '0'){
      //create
      ModifierItem insertData = await PosDatabase.instance.insertModifierItem(modifierItemData);
      if(insertData.created_at != ''){
        isComplete = true;
      }
    } else {
      //update
      int updateData = await PosDatabase.instance.updateModifierItem(modifierItemData);
      if(updateData == 1){
        isComplete = true;
      }
    }
    return isComplete;
  }

  callModifierGroupQuery({data, method}) async {
    bool isComplete = false;
    ModifierGroup modifierGroupData = ModifierGroup.fromJson(data[0]);
    if(method == '0'){
      //create
      ModifierGroup insertData = await PosDatabase.instance.insertModifierGroup(modifierGroupData);
      if(insertData.created_at != ''){
        isComplete = true;
      }
    } else {
      //update
      print('update mod group called');
      int updateData = await PosDatabase.instance.updateModifierGroup(modifierGroupData);
      if(updateData == 1){
        isComplete = true;
      }
    }
    return isComplete;
  }

  callBranchLinkProductQuery({data, method}) async {
    try{
      bool isComplete = false;
      BranchLinkProduct branchLinkProductData = BranchLinkProduct.fromJson(data[0]);
      Product? productData = await PosDatabase.instance.readProductLocalId(branchLinkProductData.product_id!);
      ProductVariant? productVariantData = await PosDatabase.instance.readProductVariantSqliteID(branchLinkProductData.product_variant_id!);
      BranchLinkProduct object = BranchLinkProduct(
          branch_link_product_id: branchLinkProductData.branch_link_product_id,
          branch_id: branchLinkProductData.branch_id,
          product_sqlite_id: productData!.product_sqlite_id.toString(),
          product_id: branchLinkProductData.product_id,
          has_variant: branchLinkProductData.has_variant,
          product_variant_sqlite_id: productVariantData != null ? productVariantData.product_variant_sqlite_id.toString(): '',
          product_variant_id: branchLinkProductData.product_variant_id,
          b_SKU: branchLinkProductData.b_SKU,
          price: branchLinkProductData.price,
          stock_type: branchLinkProductData.stock_type,
          daily_limit: branchLinkProductData.daily_limit,
          daily_limit_amount: branchLinkProductData.daily_limit_amount,
          stock_quantity: branchLinkProductData.stock_quantity,
          sync_status: 1,
          created_at: branchLinkProductData.created_at,
          updated_at: branchLinkProductData.updated_at,
          soft_delete: branchLinkProductData.soft_delete
      );
      if(method == '0'){
        //create
        BranchLinkProduct data = await PosDatabase.instance.insertBranchLinkProduct(object);
        print('data : ${data.branch_link_product_sqlite_id}');
        if(data.branch_link_product_sqlite_id != null){
          isComplete = true;
        }
      } else {
        //update
        int updateData = await PosDatabase.instance.updateBranchLinkProduct(object);
        if(updateData == 1){
          isComplete = true;
        }
      }
      return isComplete;
    } catch(e){
      print(e);
      return false;
    }

  }

  callProductVariantDetailQuery({data, method}) async {
    bool isComplete = false;
    ProductVariantDetail productVariantDetailItem = ProductVariantDetail.fromJson(data[0]);
    ProductVariant? productVariantData = await PosDatabase.instance.readProductVariantSqliteID(productVariantDetailItem.product_variant_id!);
    VariantItem? variantItemData = await PosDatabase.instance.readVariantItemSqliteID(productVariantDetailItem.variant_item_id!);
    ProductVariantDetail object = ProductVariantDetail(
        product_variant_detail_id: productVariantDetailItem.product_variant_detail_id,
        product_variant_id: productVariantDetailItem.product_variant_id,
        product_variant_sqlite_id: productVariantData!.product_variant_sqlite_id.toString(),
        variant_item_id: productVariantDetailItem.variant_item_id,
        variant_item_sqlite_id: variantItemData!.variant_item_sqlite_id.toString(),
        sync_status: 2,
        created_at: productVariantDetailItem.created_at,
        updated_at: productVariantDetailItem.updated_at,
        soft_delete: productVariantDetailItem.soft_delete
    );
    if(method == '0'){
      //create
      ProductVariantDetail data = await PosDatabase.instance.insertProductVariantDetail(object);
      if(data.product_variant_detail_sqlite_id != null){
        isComplete = true;
      }
    } else {
      //update
      int data = await PosDatabase.instance.updateProductVariantDetail(object);
      if(data == 1){
        isComplete = true;
      }
    }
    return isComplete;
  }

  callProductVariantQuery({data, method}) async {
    bool isComplete = false;
    ProductVariant productVariantItem = ProductVariant.fromJson(data[0]);
    Product? productData = await PosDatabase.instance.readProductSqliteID(productVariantItem.product_id!);
    ProductVariant object = ProductVariant(
        product_variant_id: productVariantItem.product_variant_id,
        product_sqlite_id: productData!.product_sqlite_id.toString(),
        product_id: productVariantItem.product_id,
        variant_name: productVariantItem.variant_name,
        SKU: productVariantItem.SKU,
        price: productVariantItem.price,
        stock_type: productVariantItem.stock_type,
        daily_limit: productVariantItem.daily_limit,
        daily_limit_amount: productVariantItem.daily_limit_amount,
        stock_quantity: productVariantItem.stock_quantity,
        sync_status: 2,
        created_at: productVariantItem.created_at,
        updated_at: productVariantItem.updated_at,
        soft_delete: productVariantItem.soft_delete
    );
    if(method == '0'){
      //create
      ProductVariant data = await PosDatabase.instance.insertProductVariant(object);
      if(data.product_variant_sqlite_id != null){
        isComplete = true;
      }
    } else {
      //update
      int data = await PosDatabase.instance.updateProductVariant(object);
      if(data == 1){
        isComplete = true;
      }
    }
    return isComplete;
  }

  callVariantItemQuery({data, method}) async {
    bool isComplete = false;
    VariantItem variantItemData = VariantItem.fromJson(data[0]);
    VariantGroup? variantGroupData = await PosDatabase.instance.readVariantGroupSqliteID(variantItemData.variant_group_id!);
    VariantItem object = VariantItem(
        variant_item_id: variantItemData.variant_item_id,
        variant_group_id: variantItemData.variant_group_id,
        variant_group_sqlite_id: variantGroupData != null ? variantGroupData.variant_group_sqlite_id.toString(): '0',
        name: variantItemData.name,
        sync_status: 2,
        created_at: variantItemData.created_at,
        updated_at: variantItemData.updated_at,
        soft_delete: variantItemData.soft_delete
    );
    if(method == '0'){
      //create
      VariantItem data = await PosDatabase.instance.insertVariantItem(object);
      if(data.variant_item_sqlite_id != null){
        isComplete = true;
      }
    } else {
      //update
      int data = await PosDatabase.instance.updateVariantItem(object);
      if(data == 1){
        isComplete = true;
      }
    }
    return isComplete;
  }

  callVariantGroupQuery({data, method}) async {
    bool isComplete = false;
    VariantGroup variantData = VariantGroup.fromJson(data[0]);
    Product? productData = await PosDatabase.instance.readProductSqliteID(variantData.product_id!);
    VariantGroup object = VariantGroup(
        child: [],
        variant_group_id: variantData.variant_group_id,
        product_id: variantData.product_id,
        product_sqlite_id: productData!.product_sqlite_id.toString(),
        name: variantData.name,
        sync_status: 2,
        created_at: variantData.created_at,
        updated_at: variantData.updated_at,
        soft_delete: variantData.soft_delete
    );
    if(method == '0'){
      //create
      VariantGroup data = await PosDatabase.instance.insertVariantGroup(object);
      if(data.variant_group_sqlite_id != null){
        isComplete = true;
      }
    } else {
      //update
      int data = await PosDatabase.instance.updateVariantGroup(object);
      if(data == 1){
        isComplete = true;
      }
    }
    return isComplete;
  }

  callModifierLinkProductQuery({data, method}) async {
    bool isComplete = false;
    ModifierLinkProduct modData = ModifierLinkProduct.fromJson(data[0]);
    Product? productData = await PosDatabase.instance.readProductSqliteID(modData.product_id!);
    ModifierLinkProduct object = ModifierLinkProduct(
      modifier_link_product_id: modData.modifier_link_product_id,
      mod_group_id: modData.mod_group_id,
      product_id: modData.product_id,
      product_sqlite_id: productData!.product_sqlite_id.toString(),
      sync_status: 2,
      created_at: modData.created_at,
      updated_at: modData.updated_at,
      soft_delete: modData.soft_delete,
    );
    if(method == '0'){
      //create
      ModifierLinkProduct data = await PosDatabase.instance.insertModifierLinkProduct(object);
      if(data.modifier_link_product_sqlite_id != null){
        isComplete = true;
      }
    } else {
      //update
      int data = await PosDatabase.instance.updateModifierLinkProduct(object);
      if(data == 1){
        isComplete = true;
      }
    }
    return isComplete;
  }

  callCategoryQuery({data, method}) async {
    print('query call: ${data[0]}');
    final category = Categories.fromJson(data[0]);
    bool isComplete = false;

    if(method == '0'){
      Categories categoryData = await PosDatabase.instance.insertCategories(Categories.fromJson(data[0]));
      if(categoryData.category_sqlite_id != null){
        isComplete = true;
      }
    } else {
      int categoryData = await PosDatabase.instance.updateCategoryFromCloud(Categories.fromJson(data[0]));
      if(categoryData == 1){
        isComplete = true;
      }
    }
    return isComplete;
  }

  callProductQuery({data, method}) async {
    bool isComplete = false;
    Product productItem = Product.fromJson(data[0]);
    Categories? categoryData = await PosDatabase.instance.readCategorySqliteID(productItem.category_id!);
    Product productObject = Product(
        product_id: productItem.product_id,
        category_id: productItem.category_id,
        category_sqlite_id: categoryData != null ? categoryData.category_sqlite_id.toString(): '0' ,
        company_id: productItem.company_id,
        name: productItem.name,
        price: productItem.price,
        description: productItem.description,
        SKU: productItem.SKU,
        image: productItem.image,
        has_variant: productItem.has_variant,
        stock_type: productItem.stock_type,
        stock_quantity: productItem.stock_quantity,
        available: productItem.available,
        graphic_type: productItem.graphic_type,
        color: productItem.color,
        daily_limit: productItem.daily_limit,
        daily_limit_amount: productItem.daily_limit_amount,
        sync_status: 2,
        created_at: productItem.created_at,
        updated_at: productItem.updated_at,
        soft_delete: productItem.soft_delete
    );
    if(productObject.image != ''){
      await downloadProductImage();
    }
    if(method == '0'){
      //create
      Product productData = await PosDatabase.instance.insertProduct(productObject);
      if(productData.product_sqlite_id != null){
        isComplete = true;
      }
    } else {
      //update
      int data = await PosDatabase.instance.updateProduct(productObject);
      if(data == 1){
        isComplete = true;
      }
    }
    return isComplete;
  }

  /*
  download product image
*/
  downloadProductImage() async {
    final prefs = await SharedPreferences.getInstance();
    final String? user = prefs.getString('user');
    final String? path = prefs.getString('local_path');
    Map userObject = json.decode(user!);
    Map data = await Domain().getAllProduct(userObject['company_id']);
    String url = '';
    String name = '';
    if (data['status'] == '1') {
      List responseJson = data['product'];
      for (var i = 0; i < responseJson.length; i++) {
        Product data = Product.fromJson(responseJson[i]);
        name = data.image!;
        if (data.image != '') {
          url = '${Domain.backend_domain}api/gallery/' + userObject['company_id'] + '/' + name;
          final response = await http.get(Uri.parse(url));
          var localPath = path! + '/' + name;
          final imageFile = File(localPath);
          await imageFile.writeAsBytes(response.bodyBytes);
        }
      }
    }
  }
}