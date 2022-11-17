import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:pos_system/database/pos_database.dart';
import 'package:pos_system/object/bill.dart';
import 'package:pos_system/object/branch_link_dining_option.dart';
import 'package:pos_system/object/branch_link_modifier.dart';
import 'package:pos_system/object/branch_link_product.dart';
import 'package:pos_system/object/branch_link_promotion.dart';
import 'package:pos_system/object/branch_link_tax.dart';
import 'package:pos_system/object/categories.dart';
import 'package:pos_system/object/modifier_group.dart';
import 'package:pos_system/object/modifier_item.dart';
import 'package:pos_system/object/modifier_link_product.dart';
import 'package:pos_system/object/order.dart';
import 'package:pos_system/object/order_cache.dart';
import 'package:pos_system/object/order_detail.dart';
import 'package:pos_system/object/order_modifier_detail.dart';
import 'package:pos_system/object/payment_link_company.dart';
import 'package:pos_system/object/product.dart';
import 'package:pos_system/object/product_variant.dart';
import 'package:pos_system/object/product_variant_detail.dart';
import 'package:pos_system/object/promotion.dart';
import 'package:pos_system/object/refund.dart';
import 'package:pos_system/object/sale.dart';
import 'package:pos_system/object/table.dart';
import 'package:pos_system/object/tax_link_dining.dart';
import 'package:pos_system/object/user.dart';
import 'package:pos_system/object/variant_group.dart';
import 'package:pos_system/object/variant_item.dart';
import 'package:pos_system/page/pos_pin.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../database/domain.dart';
import '../notifier/theme_color.dart';
import '../object/branch_link_user.dart';
import '../object/customer.dart';
import '../object/dining_option.dart';
import '../object/table_use.dart';
import '../object/table_use_detail.dart';
import '../object/tax.dart';

class LoadingPage extends StatefulWidget {
  const LoadingPage({Key? key}) : super(key: key);

  @override
  State<LoadingPage> createState() => _LoadingPageState();
}

class _LoadingPageState extends State<LoadingPage> {
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _createProductImgFolder();
    getAllCategory();
    getAllUser();
    getAllTable();
    getBranchLinkUser();
    getAllDiningOption();
    getBranchLinkDiningOption();
    getAllTax();
    getBranchLinkTax();
    getTaxLinkDining();
    getAllPromotion();
    getBranchLinkPromotion();
    getAllCustomer();
    getAllBill();
    getPaymentLinkCompany();
    getAllRefund();
    getModifierGroup();
    getModifierItem();
    getBranchLinkModifier();
    getAllOrder();
    getAllOrderCache();
    getAllOrderDetail();
    getAllOrderModifierDetail();
    getSale();
    getAllTableUse();
    getAllTableUseDetail();



    // Go to Page2 after 5s.
    Timer(Duration(seconds: 4), () {
      Navigator.push(context, MaterialPageRoute(builder: (_) => PosPinPage()));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeColor>(builder: (context, ThemeColor color, child) {
      return Scaffold(
        backgroundColor: color.backgroundColor,
        body: Center(
            child: Image.file(File(
                'data/user/0/com.example.pos_system/files/assets/img/output-onlinegiftools.gif'))),
      );
    });
  }

/*
  sava company user to database
*/
  getAllUser() async {
    final prefs = await SharedPreferences.getInstance();
    final String? user = prefs.getString('user');
    Map userObject = json.decode(user!);
    Map data = await Domain().getAllUser(userObject['company_id']);
    if (data['status'] == '1') {
      List responseJson = data['user'];
      for (var i = 0; i < responseJson.length; i++) {
        User user = await PosDatabase.instance
            .insertUser(User.fromJson(responseJson[i]));
        // if (user != '') {
        //   Navigator.of(context).pushReplacement(MaterialPageRoute(
        //     builder: (context) => PosPinPage(),
        //   ));
        // }
      }
    }
  }

  /*
  sava table use to database
*/
  getAllTableUse() async {
    final prefs = await SharedPreferences.getInstance();
    final int? branch_id = prefs.getInt('branch_id');
    Map data = await Domain().getAllTableUse(branch_id.toString());
    if (data['status'] == '1') {
      List responseJson = data['table_use'];
      for (var i = 0; i < responseJson.length; i++) {
        TableUse user = await PosDatabase.instance
            .insertSqliteTableUse(TableUse.fromJson(responseJson[i]));
      }
    }
  }

  /*
  sava table use detailto database
*/
  getAllTableUseDetail() async {
    final prefs = await SharedPreferences.getInstance();
    final int? branch_id = prefs.getInt('branch_id');
    Map data = await Domain().getAllTableUseDetail(branch_id.toString());
    if (data['status'] == '1') {
      List responseJson = data['table_use'];
      for (var i = 0; i < responseJson.length; i++) {
        TableUseDetail user = await PosDatabase.instance
            .insertSqliteTableUseDetail(
                TableUseDetail.fromJson(responseJson[i]));
      }
    }
  }

/*
  save branch link user table to database
*/
  getBranchLinkUser() async {
    final prefs = await SharedPreferences.getInstance();
    final int? branch_id = prefs.getInt('branch_id');
    Map data = await Domain().getBranchLinkUser(branch_id.toString());
    if (data['status'] == '1') {
      List responseJson = data['user'];
      for (var i = 0; i < responseJson.length; i++) {
        BranchLinkUser data = await PosDatabase.instance
            .insertBranchLinkUser(BranchLinkUser.fromJson(responseJson[i]));
      }
    }
  }

/*
  save branch table to database
*/
  getAllTable() async {
    final prefs = await SharedPreferences.getInstance();
    final int? branch_id = prefs.getInt('branch_id');
    Map data = await Domain().getAllTable(branch_id.toString());
    if (data['status'] == '1') {
      List responseJson = data['table'];
      for (var i = 0; i < responseJson.length; i++) {
        PosTable table = await PosDatabase.instance
            .insertPosTable(PosTable.fromJson(responseJson[i]));
      }
    }
  }
}

/*
  save dining option to database
*/
getAllDiningOption() async {
  final prefs = await SharedPreferences.getInstance();
  final String? user = prefs.getString('user');
  Map userObject = json.decode(user!);
  Map data = await Domain().getAllDiningOption(userObject['company_id']);
  if (data['status'] == '1') {
    List responseJson = data['dining_option'];
    for (var i = 0; i < responseJson.length; i++) {
      DiningOption data = await PosDatabase.instance
          .insertDiningOption(DiningOption.fromJson(responseJson[i]));
    }
  }
}

/*
  save branch link dining option to database
*/
getBranchLinkDiningOption() async {
  final prefs = await SharedPreferences.getInstance();
  final int? branch_id = prefs.getInt('branch_id');
  Map data = await Domain().getBranchLinkDiningOption(branch_id.toString());
  if (data['status'] == '1') {
    List responseJson = data['dining_option'];
    for (var i = 0; i < responseJson.length; i++) {
      BranchLinkDining data = await PosDatabase.instance
          .insertBranchLinkDining(BranchLinkDining.fromJson(responseJson[i]));
    }
  }
}

/*
  save tax to database
*/
getAllTax() async {
  final prefs = await SharedPreferences.getInstance();
  final String? user = prefs.getString('user');
  Map userObject = json.decode(user!);
  Map data = await Domain().getAllTax(userObject['company_id']);
  if (data['status'] == '1') {
    List responseJson = data['tax'];
    for (var i = 0; i < responseJson.length; i++) {
      Tax data =
          await PosDatabase.instance.insertTax(Tax.fromJson(responseJson[i]));
    }
  }
}

/*
  save branch link tax to database
*/
getBranchLinkTax() async {
  final prefs = await SharedPreferences.getInstance();
  final int? branch_id = prefs.getInt('branch_id');
  Map data = await Domain().getBranchLinkTax(branch_id.toString());
  if (data['status'] == '1') {
    List responseJson = data['tax'];
    for (var i = 0; i < responseJson.length; i++) {
      BranchLinkTax data = await PosDatabase.instance
          .insertBranchLinkTax(BranchLinkTax.fromJson(responseJson[i]));
    }
  }
}

/*
  save tax link dining to database
*/
getTaxLinkDining() async {
  final prefs = await SharedPreferences.getInstance();
  final int? branch_id = prefs.getInt('branch_id');
  Map data = await Domain().getTaxLinkDining(branch_id.toString());
  if (data['status'] == '1') {
    List responseJson = data['tax'];
    for (var i = 0; i < responseJson.length; i++) {
      TaxLinkDining data = await PosDatabase.instance
          .insertTaxLinkDining(TaxLinkDining.fromJson(responseJson[i]));
    }
  }
}

/*
  save categories to database
*/
getAllCategory() async {
  final prefs = await SharedPreferences.getInstance();
  final String? user = prefs.getString('user');
  Map userObject = json.decode(user!);
  Map data = await Domain().getAllCategory(userObject['company_id']);
  if (data['status'] == '1') {
    List responseJson = data['categories'];
    for (var i = 0; i < responseJson.length; i++) {
      Categories data = await PosDatabase.instance
          .insertCategories(Categories.fromJson(responseJson[i]));
    }
    getAllProduct();
  }
}

/*
  save promotion to database
*/
getAllPromotion() async {
  final prefs = await SharedPreferences.getInstance();
  final String? user = prefs.getString('user');
  Map userObject = json.decode(user!);
  Map data = await Domain().getAllPromotion(userObject['company_id']);
  if (data['status'] == '1') {
    List responseJson = data['promotion'];
    for (var i = 0; i < responseJson.length; i++) {
      Promotion data = await PosDatabase.instance
          .insertPromotion(Promotion.fromJson(responseJson[i]));
    }
  }
}

/*
  save branch link promotion to database
*/
getBranchLinkPromotion() async {
  final prefs = await SharedPreferences.getInstance();
  final int? branch_id = prefs.getInt('branch_id');
  Map data = await Domain().getBranchLinkPromotion(branch_id.toString());
  if (data['status'] == '1') {
    List responseJson = data['promotion'];
    for (var i = 0; i < responseJson.length; i++) {
      BranchLinkPromotion data = await PosDatabase.instance
          .insertBranchLinkPromotion(
              BranchLinkPromotion.fromJson(responseJson[i]));
    }
  }
}

/*
  save customer to database
*/
getAllCustomer() async {
  final prefs = await SharedPreferences.getInstance();
  final String? user = prefs.getString('user');
  Map userObject = json.decode(user!);
  Map data = await Domain().getAllCustomer(userObject['company_id']);
  if (data['status'] == '1') {
    List responseJson = data['customer'];
    for (var i = 0; i < responseJson.length; i++) {
      Customer data = await PosDatabase.instance
          .insertCustomer(Customer.fromJson(responseJson[i]));
    }
  }
}

/*
  save bill to database
*/
getAllBill() async {
  final prefs = await SharedPreferences.getInstance();
  final String? user = prefs.getString('user');
  final int? branch_id = prefs.getInt('branch_id');
  Map userObject = json.decode(user!);
  Map data =
      await Domain().getAllBill(userObject['company_id'], branch_id.toString());
  if (data['status'] == '1') {
    List responseJson = data['bill'];
    for (var i = 0; i < responseJson.length; i++) {
      Bill data =
          await PosDatabase.instance.insertBill(Bill.fromJson(responseJson[i]));
    }
  }
}

/*
  save payment option to database
*/
getPaymentLinkCompany() async {
  final prefs = await SharedPreferences.getInstance();
  final String? user = prefs.getString('user');
  Map userObject = json.decode(user!);
  Map data = await Domain().getPaymentLinkCompany(userObject['company_id']);
  if (data['status'] == '1') {
    List responseJson = data['payment'];
    for (var i = 0; i < responseJson.length; i++) {
      PaymentLinkCompany data = await PosDatabase.instance
          .insertPaymentLinkCompany(
              PaymentLinkCompany.fromJson(responseJson[i]));
    }
  }
}

/*
  save refund to database
*/
getAllRefund() async {
  final prefs = await SharedPreferences.getInstance();
  final String? user = prefs.getString('user');
  final int? branch_id = prefs.getInt('branch_id');
  Map userObject = json.decode(user!);
  Map data = await Domain()
      .getAllRefund(userObject['company_id'], branch_id.toString());
  if (data['status'] == '1') {
    List responseJson = data['refund'];
    for (var i = 0; i < responseJson.length; i++) {
      Refund data = await PosDatabase.instance
          .insertRefund(Refund.fromJson(responseJson[i]));
    }
  }
}

/*
  save modifier group to database
*/
getModifierGroup() async {
  final prefs = await SharedPreferences.getInstance();
  final String? user = prefs.getString('user');
  Map userObject = json.decode(user!);
  Map data = await Domain().getModifierGroup(userObject['company_id']);
  if (data['status'] == '1') {
    List responseJson = data['modifier'];
    for (var i = 0; i < responseJson.length; i++) {
      ModifierGroup data = await PosDatabase.instance
          .insertModifierGroup(ModifierGroup.fromJson(responseJson[i]));
    }
  }
}

/*
  save modifier item to database
*/
getModifierItem() async {
  final prefs = await SharedPreferences.getInstance();
  final String? user = prefs.getString('user');
  Map userObject = json.decode(user!);
  Map data = await Domain().getModifierItem(userObject['company_id']);
  if (data['status'] == '1') {
    List responseJson = data['modifier'];
    for (var i = 0; i < responseJson.length; i++) {
      ModifierItem data = await PosDatabase.instance
          .insertModifierItem(ModifierItem.fromJson(responseJson[i]));
    }
  }
}

/*
  save branch link modifier to database
*/
getBranchLinkModifier() async {
  final prefs = await SharedPreferences.getInstance();
  final int? branch_id = prefs.getInt('branch_id');
  Map data = await Domain().getBranchLinkModifier(branch_id.toString());
  if (data['status'] == '1') {
    List responseJson = data['modifier'];
    for (var i = 0; i < responseJson.length; i++) {
      BranchLinkModifier data = await PosDatabase.instance
          .insertBranchLinkModifier(
              BranchLinkModifier.fromJson(responseJson[i]));
    }
  }
}

/*
  save product to database
*/
getAllProduct() async {
  final prefs = await SharedPreferences.getInstance();
  final String? user = prefs.getString('user');
  Map userObject = json.decode(user!);
  Map data = await Domain().getAllProduct(userObject['company_id']);
  if (data['status'] == '1') {
    List responseJson = data['product'];
    for (var i = 0; i < responseJson.length; i++) {
      Product productItem = Product.fromJson(responseJson[i]);
      Categories? categoryData = await PosDatabase.instance.readCategorySqliteID(productItem.category_id!);
      Product data = await PosDatabase.instance.insertProduct(Product(
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
      ));
    }
    getModifierLinkProduct();
    getVariantGroup();
    getProductVariant();
    getBranchLinkProduct();


  }
}

/*
  save branch link product to database
*/
getBranchLinkProduct() async {
  final prefs = await SharedPreferences.getInstance();
  final int? branch_id = prefs.getInt('branch_id');
  Map data = await Domain().getBranchLinkProduct(branch_id.toString());
  if (data['status'] == '1') {
    List responseJson = data['product'];
    for (var i = 0; i < responseJson.length; i++) {
      BranchLinkProduct branchLinkProductData = BranchLinkProduct.fromJson(responseJson[i]);
      Product? productData = await PosDatabase.instance.readProductSqliteID(branchLinkProductData.product_id!);
      // ProductVariant? productVariantData = await PosDatabase.instance.readProductVariantSqliteID(branchLinkProductData.product_variant_id!);
      // print(productVariantData!.product_variant_sqlite_id);
      BranchLinkProduct data = await PosDatabase.instance
          .insertBranchLinkProduct(BranchLinkProduct(
        branch_link_product_id: branchLinkProductData.branch_link_product_id,
        branch_id: branchLinkProductData.branch_id,
        product_sqlite_id: branchLinkProductData.product_id,
        product_id: productData!.product_sqlite_id.toString(),
        has_variant: branchLinkProductData.has_variant,
        product_variant_sqlite_id: '0',
        product_variant_id: branchLinkProductData.product_variant_id,
        b_SKU: branchLinkProductData.b_SKU,
        price: branchLinkProductData.price,
        stock_type: branchLinkProductData.stock_type,
        daily_limit: branchLinkProductData.daily_limit,
        daily_limit_amount: branchLinkProductData.daily_limit_amount,
        stock_quantity: branchLinkProductData.stock_quantity,
        sync_status: 2,
        created_at: branchLinkProductData.created_at,
        updated_at: branchLinkProductData.updated_at,
        soft_delete: branchLinkProductData.soft_delete
      )
      );
    }
  }
}

/*
  save modifier link product to database
*/
getModifierLinkProduct() async {
  final prefs = await SharedPreferences.getInstance();
  final int? branch_id = prefs.getInt('branch_id');
  final String? user = prefs.getString('user');
  Map userObject = json.decode(user!);
  Map data = await Domain()
      .getModifierLinkProduct(userObject['company_id'], branch_id.toString());
  if (data['status'] == '1') {
    List responseJson = data['product'];
    for (var i = 0; i < responseJson.length; i++) {
      ModifierLinkProduct modData = ModifierLinkProduct.fromJson(responseJson[i]);
      Product? productData = await PosDatabase.instance.readProductSqliteID(modData.product_id!);
      ModifierLinkProduct data = await PosDatabase.instance
          .insertModifierLinkProduct(ModifierLinkProduct(
        modifier_link_product_id: modData.modifier_link_product_id,
        mod_group_id: modData.mod_group_id,
        product_id: modData.product_id,
        product_sqlite_id: productData!.product_sqlite_id.toString(),
        sync_status: 2,
        created_at: modData.created_at,
        updated_at: modData.updated_at,
        soft_delete: modData.soft_delete,
      ));
    }
  }
}

/*
  save variant group to database
*/
getVariantGroup() async {
  final prefs = await SharedPreferences.getInstance();
  final String? user = prefs.getString('user');
  Map userObject = json.decode(user!);
  Map data = await Domain().getVariantGroup(userObject['company_id']);
  if (data['status'] == '1') {
    List responseJson = data['variant'];
    for (var i = 0; i < responseJson.length; i++) {
      VariantGroup variantData = VariantGroup.fromJson(responseJson[i]);
      Product? productData = await PosDatabase.instance.readProductSqliteID(variantData.product_id!);
      VariantGroup data = await PosDatabase.instance
          .insertVariantGroup(
        VariantGroup(
          child: [],
          variant_group_id: variantData.variant_group_id,
          product_id: variantData.product_id,
          product_sqlite_id: productData!.product_sqlite_id.toString(),
          name: variantData.name,
          sync_status: 2,
          created_at: variantData.created_at,
          updated_at: variantData.updated_at,
          soft_delete: variantData.soft_delete
        )
      );
    }
    getVariantItem();

  }

}

/*
  save variant item to database
*/
getVariantItem() async {
  final prefs = await SharedPreferences.getInstance();
  final String? user = prefs.getString('user');
  Map userObject = json.decode(user!);
  Map data = await Domain().getVariantItem(userObject['company_id']);
  if (data['status'] == '1') {
    List responseJson = data['variant'];
    for (var i = 0; i < responseJson.length; i++) {
      VariantItem variantItemData = VariantItem.fromJson(responseJson[i]);
      VariantGroup? variantGroupData = await PosDatabase.instance.readVariantGroupSqliteID(variantItemData.variant_group_id!);
      VariantItem data = await PosDatabase.instance
          .insertVariantItem( VariantItem(
        variant_item_id: variantItemData.variant_item_id,
        variant_group_id: variantItemData.variant_group_id,
        variant_group_sqlite_id: variantGroupData != null ? variantGroupData.variant_group_sqlite_id.toString(): '0',
        name: variantItemData.name,
        sync_status: 2,
        created_at: variantItemData.created_at,
        updated_at: variantItemData.updated_at,
        soft_delete: variantItemData.soft_delete
      ));
    }
  }
}

/*
  save product variant to database
*/
getProductVariant() async {
  final prefs = await SharedPreferences.getInstance();
  final String? user = prefs.getString('user');
  Map userObject = json.decode(user!);
  Map data = await Domain().getProductVariant(userObject['company_id']);
  if (data['status'] == '1') {
    List responseJson = data['variant'];
    for (var i = 0; i < responseJson.length; i++) {
      ProductVariant productVariantItem = ProductVariant.fromJson(responseJson[i]);
      Product? productData = await PosDatabase.instance.readProductSqliteID(productVariantItem.product_id!);
      ProductVariant data = await PosDatabase.instance
          .insertProductVariant(ProductVariant(
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
      ));
    }
    getProductVariantDetail();

  }
}

/*
  save product variant detail to database
*/
getProductVariantDetail() async {
  final prefs = await SharedPreferences.getInstance();
  final String? user = prefs.getString('user');
  Map userObject = json.decode(user!);
  Map data = await Domain().getProductVariantDetail(userObject['company_id']);
  if (data['status'] == '1') {
    List responseJson = data['variant'];
    for (var i = 0; i < responseJson.length; i++) {
      ProductVariantDetail productVariantDetailItem = ProductVariantDetail.fromJson(responseJson[i]);
      ProductVariant? productVariantData = await PosDatabase.instance.readProductVariantSqliteID(productVariantDetailItem.product_variant_id!);
      VariantItem? variantItemData = await PosDatabase.instance.readVariantItemSqliteID(productVariantDetailItem.variant_item_id!);
      ProductVariantDetail data = await PosDatabase.instance
          .insertProductVariantDetail(ProductVariantDetail(
          product_variant_detail_id: productVariantDetailItem.product_variant_detail_id,
          product_variant_id: productVariantDetailItem.product_variant_id,
          product_variant_sqlite_id: productVariantData!.product_variant_sqlite_id.toString(),
          variant_item_id: productVariantDetailItem.variant_item_id,
          variant_item_sqlite_id: variantItemData!.variant_item_sqlite_id.toString(),
          sync_status: 2,
          created_at: productVariantDetailItem.created_at,
          updated_at: productVariantDetailItem.updated_at,
          soft_delete: productVariantDetailItem.soft_delete
      ));
    }
  }
}

/*
  save order to database
*/
getAllOrder() async {
  final prefs = await SharedPreferences.getInstance();
  final int? branch_id = prefs.getInt('branch_id');
  final String? user = prefs.getString('user');
  Map userObject = json.decode(user!);
  Map data = await Domain()
      .getAllOrder(userObject['company_id'], branch_id.toString());
  if (data['status'] == '1') {
    List responseJson = data['order'];
    for (var i = 0; i < responseJson.length; i++) {
      Order data = await PosDatabase.instance
          .insertOrder(Order.fromJson(responseJson[i]));
    }
  }
}

/*
  save order cache to database
*/
getAllOrderCache() async {
  final prefs = await SharedPreferences.getInstance();
  final int? branch_id = prefs.getInt('branch_id');
  final String? user = prefs.getString('user');
  Map userObject = json.decode(user!);
  Map data = await Domain()
      .getAllOrderCache(userObject['company_id'], branch_id.toString());
  if (data['status'] == '1') {
    List responseJson = data['order'];
    for (var i = 0; i < responseJson.length; i++) {
      OrderCache data = await PosDatabase.instance
          .insertOrderCache(OrderCache.fromJson(responseJson[i]));
    }
  }
}

/*
  save order detail to database
*/
getAllOrderDetail() async {
  final prefs = await SharedPreferences.getInstance();
  final int? branch_id = prefs.getInt('branch_id');
  final String? user = prefs.getString('user');
  Map userObject = json.decode(user!);
  Map data = await Domain()
      .getAllOrderDetail(userObject['company_id'], branch_id.toString());
  if (data['status'] == '1') {
    List responseJson = data['order'];
    for (var i = 0; i < responseJson.length; i++) {
      OrderDetail data = await PosDatabase.instance
          .insertOrderDetail(OrderDetail.fromJson(responseJson[i]));
    }
  }
}

/*
  save order modifier detail to database
*/
getAllOrderModifierDetail() async {
  final prefs = await SharedPreferences.getInstance();
  final int? branch_id = prefs.getInt('branch_id');
  final String? user = prefs.getString('user');
  Map userObject = json.decode(user!);
  Map data = await Domain().getAllOrderModifierDetail(
      userObject['company_id'], branch_id.toString());
  if (data['status'] == '1') {
    List responseJson = data['order'];
    for (var i = 0; i < responseJson.length; i++) {
      OrderModifierDetail data = await PosDatabase.instance
          .insertOrderModifierDetail(
              OrderModifierDetail.fromJson(responseJson[i]));
    }
  }
}

/*
  save sale to database
*/
getSale() async {
  final prefs = await SharedPreferences.getInstance();
  final int? branch_id = prefs.getInt('branch_id');
  final String? user = prefs.getString('user');
  Map userObject = json.decode(user!);
  Map data =
      await Domain().getSale(userObject['company_id'], branch_id.toString());
  if (data['status'] == '1') {
    List responseJson = data['sale'];
    for (var i = 0; i < responseJson.length; i++) {
      Sale data =
          await PosDatabase.instance.insertSale(Sale.fromJson(responseJson[i]));
    }
  }
}

/*
  create folder to save product image
*/
Future<String> get _localPath async {
  final directory = await getApplicationSupportDirectory();
  return directory.path;
}

_createProductImgFolder() async {
  final prefs = await SharedPreferences.getInstance();
  final String? user = prefs.getString('user');
  Map userObject = json.decode(user!);
  final folderName = userObject['company_id'];
  final path = await _localPath;
  final pathImg = Directory("$path/assets/$folderName");
  pathImg.create();
  downloadProductImage(pathImg.path);
}

/*
  download product image
*/
downloadProductImage(String path) async {
  final prefs = await SharedPreferences.getInstance();
  final String? user = prefs.getString('user');
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
        url = 'https://pos.lkmng.com/api/gallery/' +
            userObject['company_id'] +
            '/' +
            name;
        final response = await http.get(Uri.parse(url));
        var localPath = path + '/' + name;
        final imageFile = File(localPath);
        await imageFile.writeAsBytes(response.bodyBytes);
      }
    }
  }
}
