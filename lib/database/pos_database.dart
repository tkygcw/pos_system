import 'package:pos_system/object/bill.dart';
import 'package:pos_system/object/branch.dart';
import 'package:pos_system/object/branch_link_user.dart';
import 'package:pos_system/object/categories.dart';
import 'package:pos_system/object/customer.dart';
import 'package:pos_system/object/dining_option.dart';
import 'package:pos_system/object/modifier_group.dart';
import 'package:pos_system/object/modifier_item.dart';
import 'package:pos_system/object/modifier_link_product.dart';
import 'package:pos_system/object/order.dart';
import 'package:pos_system/object/order_cache.dart';
import 'package:pos_system/object/order_detail.dart';
import 'package:pos_system/object/payment_link_company.dart';
import 'package:pos_system/object/product.dart';
import 'package:pos_system/object/product_variant.dart';
import 'package:pos_system/object/product_variant_detail.dart';
import 'package:pos_system/object/promotion.dart';
import 'package:pos_system/object/refund.dart';
import 'package:pos_system/object/sale.dart';
import 'package:pos_system/object/table.dart';
import 'package:pos_system/object/tax.dart';
import 'package:pos_system/object/tax_link_dining.dart';
import 'package:pos_system/object/user.dart';
import 'package:pos_system/object/user_log.dart';
import 'package:pos_system/object/variant_group.dart';
import 'package:pos_system/object/variant_item.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../object/branch_link_dining_option.dart';
import '../object/branch_link_modifier.dart';
import '../object/branch_link_product.dart';
import '../object/branch_link_promotion.dart';
import '../object/branch_link_tax.dart';
import '../object/color.dart';

class PosDatabase {
  static final PosDatabase instance = PosDatabase.init();
  static Database? _database;

  PosDatabase.init();

  Future<Database> get database async {
    if (_database != null) return _database!;

    _database = await _initDB('pos.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);
    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future _createDB(Database db, int version) async {
    final idType = 'INTEGER PRIMARY KEY AUTOINCREMENT';
    final textType = 'TEXT NOT NULL';
    final integerType = 'INTEGER NOT NULL';

/*
    create user table
*/
    await db.execute(
        '''CREATE TABLE $tableUser ( ${UserFields.user_id} $idType, ${UserFields.name} $textType, ${UserFields.email} $textType, 
           ${UserFields.phone} $textType, ${UserFields.role} $integerType, ${UserFields.pos_pin} $textType,
           ${UserFields.status} $integerType, ${UserFields.created_at} $textType, ${UserFields.updated_at} $textType, ${UserFields.soft_delete} $textType)''');
/*
    create category table
*/
    await db.execute(
        '''CREATE TABLE $tableCategories ( ${CategoriesFields.category_sqlite_id} $idType, ${CategoriesFields.category_id} $integerType, ${CategoriesFields.company_id} $textType, ${CategoriesFields.name} $textType, 
           ${CategoriesFields.sequence} $textType, ${CategoriesFields.color} $textType, ${CategoriesFields.created_at} $textType, ${CategoriesFields.updated_at} $textType, 
           ${CategoriesFields.soft_delete} $textType)''');
/*
    create bill table
*/
    await db.execute(
        '''CREATE TABLE $tableBill ( ${BillFields.bill_sqlite_id} $idType, ${BillFields.bill_id} $integerType, ${BillFields.company_id} $textType,
           ${BillFields.branch_id} $textType, ${BillFields.order_id} $textType, ${BillFields.amount} $textType, 
           ${BillFields.is_refund} $integerType, ${BillFields.created_at} $textType, ${BillFields.updated_at} $textType, 
           ${BillFields.soft_delete} $textType)''');
/*
    create customer table
*/
    await db.execute(
        '''CREATE TABLE $tableCustomer ( ${CustomerFields.customer_sqlite_id} $idType, ${CustomerFields.customer_id} $integerType, ${CustomerFields.company_id} $textType, ${CustomerFields.name} $textType, 
           ${CustomerFields.phone} $textType, ${CustomerFields.email} $textType, ${CustomerFields.address} $textType, ${CustomerFields.note} $textType,
           ${CustomerFields.created_at} $textType, ${CustomerFields.updated_at} $textType, ${CustomerFields.soft_delete} $textType)''');
/*
    create dining option table
*/
    await db.execute(
        '''CREATE TABLE $tableDiningOption ( ${DiningOptionFields.dining_id} $idType, ${DiningOptionFields.name} $textType, ${DiningOptionFields.company_id} $textType, 
           ${DiningOptionFields.created_at} $textType, ${DiningOptionFields.updated_at} $textType, ${DiningOptionFields.soft_delete} $textType)''');
/*
    create modifier group table
*/
    await db.execute(
        '''CREATE TABLE $tableModifierGroup ( ${ModifierGroupFields.mod_group_id} $idType, ${ModifierGroupFields.company_id} $textType, ${ModifierGroupFields.name} $textType, 
           ${ModifierGroupFields.created_at} $textType, ${ModifierGroupFields.updated_at} $textType, ${ModifierGroupFields.soft_delete} $textType)''');
/*
    create modifier item table
*/
    await db.execute(
        '''CREATE TABLE $tableModifierItem ( ${ModifierItemFields.mod_item_id} $idType, ${ModifierItemFields.mod_group_id} $textType, ${ModifierItemFields.name} $textType, 
           ${ModifierItemFields.price} $textType, ${ModifierItemFields.sequence} $integerType, ${ModifierItemFields.quantity} $textType, 
           ${ModifierItemFields.created_at} $textType,${ModifierItemFields.updated_at} $textType, ${ModifierItemFields.soft_delete} $textType)''');
/*
    create modifier link product table
*/
    await db.execute(
        '''CREATE TABLE $tableModifierLinkProduct ( ${ModifierLinkProductFields.modifier_link_product_sqlite_id} $idType, ${ModifierLinkProductFields.modifier_link_product_id} $integerType, ${ModifierLinkProductFields.mod_group_id} $textType,
           ${ModifierLinkProductFields.product_id} $textType, ${ModifierLinkProductFields.created_at} $textType, ${ModifierLinkProductFields.updated_at} $textType,
           ${ModifierLinkProductFields.soft_delete} $textType)''');
/*
    create order table
*/
    await db.execute(
        '''CREATE TABLE $tableOrder ( ${OrderFields.order_sqlite_id} $idType, ${OrderFields.order_id} $integerType, ${OrderFields.company_id} $textType,
           ${OrderFields.customer_id} $textType, ${OrderFields.branch_link_promotion_id} $textType,${OrderFields.payment_link_company_id} $textType,
           ${OrderFields.branch_id} $textType, ${OrderFields.branch_link_tax_id} $textType, ${OrderFields.final_amount} $textType,
           ${OrderFields.close_by} $textType, ${OrderFields.created_at} $textType, ${OrderFields.updated_at} $textType, ${OrderFields.soft_delete} $textType)''');
/*
    create order cache table
*/
    await db.execute(
        '''CREATE TABLE $tableOrderCache ( ${OrderCacheFields.order_cache_sqlite_id} $idType, ${OrderCacheFields.order_cache_id} $integerType, ${OrderCacheFields.company_id} $textType, 
           ${OrderCacheFields.branch_id} $textType, ${OrderCacheFields.order_detail_id} $textType, ${OrderCacheFields.table_id} $textType, 
           ${OrderCacheFields.dining_id} $textType, ${OrderCacheFields.order_id} $textType, ${OrderCacheFields.order_by} $textType, ${OrderCacheFields.total_amount} $textType,
           ${OrderCacheFields.created_at} $textType, ${OrderCacheFields.updated_at} $textType, ${OrderCacheFields.soft_delete} $textType)''');
/*
    create order detail table
*/
    await db.execute(
        '''CREATE TABLE $tableOrderDetail ( ${OrderDetailFields.order_detail_sqlite_id} $idType, ${OrderDetailFields.order_detail_id} $integerType, 
           ${OrderDetailFields.order_cache_id} $textType, ${OrderDetailFields.branch_link_product_id} $textType, 
           ${OrderDetailFields.quantity} $textType, ${OrderDetailFields.remark} $textType, ${OrderDetailFields.account} $textType,
           ${OrderDetailFields.created_at} $textType, ${OrderDetailFields.updated_at} $textType, ${OrderDetailFields.soft_delete} $textType)''');
/*
    create payment link company
*/
    await db.execute(
        '''CREATE TABLE $tablePaymentLinkCompany ( ${PaymentLinkCompanyFields.payment_link_company_id} $idType, ${PaymentLinkCompanyFields.payment_type_id} $textType,
           ${PaymentLinkCompanyFields.company_id} $textType,${PaymentLinkCompanyFields.name} $textType, ${PaymentLinkCompanyFields.created_at} $textType, 
           ${PaymentLinkCompanyFields.updated_at} $textType, ${PaymentLinkCompanyFields.soft_delete} $textType)''');
/*
    create product table
*/
    await db.execute(
        '''CREATE TABLE $tableProduct ( ${ProductFields.product_sqlite_id} $idType, ${ProductFields.product_id} $integerType, ${ProductFields.category_id} $textType, ${ProductFields.company_id} $textType,
           ${ProductFields.name} $textType,${ProductFields.price} $textType, ${ProductFields.description} $textType, ${ProductFields.SKU} $textType, ${ProductFields.image} $textType,
           ${ProductFields.has_variant} $integerType,${ProductFields.stock_type} $integerType, ${ProductFields.stock_quantity} $textType, ${ProductFields.available} $integerType,
           ${ProductFields.graphic_type} $textType, ${ProductFields.color} $textType, ${ProductFields.daily_limit} $textType, ${ProductFields.daily_limit_amount} $textType,
           ${ProductFields.created_at} $textType, ${ProductFields.updated_at} $textType, ${ProductFields.soft_delete} $textType)''');
/*
    create product variant table
*/
    await db.execute(
        '''CREATE TABLE $tableProductVariant ( ${ProductVariantFields.product_variant_sqlite_id} $idType, ${ProductVariantFields.product_variant_id} $integerType, ${ProductVariantFields.product_id} $textType, ${ProductVariantFields.variant_name} $textType,
           ${ProductVariantFields.SKU} $textType,${ProductVariantFields.price} $textType,${ProductVariantFields.stock_type} $textType, ${ProductVariantFields.daily_limit} $textType, ${ProductVariantFields.daily_limit_amount} $textType,
           ${ProductVariantFields.stock_quantity} $textType,${ProductVariantFields.created_at} $textType, ${ProductVariantFields.updated_at} $textType, ${ProductVariantFields.soft_delete} $textType)''');
/*
    create product variant detail table
*/
    await db.execute(
        '''CREATE TABLE $tableProductVariantDetail ( ${ProductVariantDetailFields.product_variant_detail_sqlite_id} $idType, ${ProductVariantDetailFields.product_variant_detail_id} $integerType,
           ${ProductVariantDetailFields.product_variant_id} $textType,${ProductVariantDetailFields.variant_item_id} $textType, ${ProductVariantDetailFields.created_at} $textType, 
           ${ProductVariantDetailFields.updated_at} $textType, ${ProductVariantDetailFields.soft_delete} $textType)''');
/*
    create promotion table
*/
    await db.execute(
        '''CREATE TABLE $tablePromotion ( ${PromotionFields.promotion_id} $idType, ${PromotionFields.company_id} $textType,${PromotionFields.name} $textType,${PromotionFields.amount} $textType, 
           ${PromotionFields.specific_category} $textType, ${PromotionFields.category_id} $textType, ${PromotionFields.type} $integerType,
           ${PromotionFields.auto_apply} $textType,${PromotionFields.all_day} $textType, ${PromotionFields.all_time} $textType, ${PromotionFields.sdate} $textType,
           ${PromotionFields.edate} $textType, ${PromotionFields.stime} $textType, ${PromotionFields.etime} $textType,
           ${PromotionFields.created_at} $textType, ${PromotionFields.updated_at} $textType, ${PromotionFields.soft_delete} $textType)''');
/*
    create refund table
*/
    await db.execute(
        '''CREATE TABLE $tableRefund ( ${RefundFields.refund_sqlite_id} $idType, ${RefundFields.refund_id} $integerType, ${RefundFields.company_id} $textType,
           ${RefundFields.branch_id} $textType, ${RefundFields.order_cache_id} $textType,${RefundFields.order_detail_id} $textType,
           ${RefundFields.order_id} $textType, ${RefundFields.refund_by} $textType, ${RefundFields.bill_id} $textType, 
           ${RefundFields.created_at} $textType,${RefundFields.updated_at} $textType, ${RefundFields.soft_delete} $textType)''');
/*
    create sale table
*/
    await db.execute(
        '''CREATE TABLE $tableSale ( ${SaleFields.sale_sqlite_id} $idType, ${SaleFields.sale_id} $integerType,
           ${SaleFields.company_id} $textType,${SaleFields.branch_id} $textType, ${SaleFields.daily_sales} $textType,
           ${SaleFields.user_sales} $textType, ${SaleFields.item_sales} $textType, ${SaleFields.cashier_sales} $textType,
           ${SaleFields.hours_sales} $textType, ${SaleFields.payment_sales} $textType,  
           ${SaleFields.created_at} $textType,${SaleFields.updated_at} $textType, ${SaleFields.soft_delete} $textType)''');
/*
    create restaurant table
*/
    await db.execute(
        '''CREATE TABLE $tablePosTable ( ${PosTableFields.table_sqlite_id} $idType, ${PosTableFields.table_id} $integerType, ${PosTableFields.branch_id} $textType,${PosTableFields.number} $textType,
           ${PosTableFields.seats} $textType, ${PosTableFields.status} $integerType,
           ${PosTableFields.created_at} $textType,${PosTableFields.updated_at} $textType, ${PosTableFields.soft_delete} $textType)''');
/*
    create tax table
*/
    await db.execute(
        '''CREATE TABLE $tableTax ( ${TaxFields.tax_id} $idType, ${TaxFields.company_id} $textType,${TaxFields.name} $textType,
           ${TaxFields.tax_rate} $textType,${TaxFields.created_at} $textType,${TaxFields.updated_at} $textType, 
           ${TaxFields.soft_delete} $textType)''');
/*
    create tax link dining table
*/
    await db.execute(
        '''CREATE TABLE $tableTaxLinkDining ( ${TaxLinkDiningFields.tax_link_dining_id} $idType, ${TaxLinkDiningFields.tax_id} $textType,${TaxLinkDiningFields.dining_id} $textType,
           ${TaxLinkDiningFields.created_at} $textType,${TaxLinkDiningFields.updated_at} $textType,${TaxLinkDiningFields.soft_delete} $textType)''');
/*
    create user log table
*/
    await db.execute(
        '''CREATE TABLE $tableUserLog ( ${UserLogFields.user_log_id} $idType, ${UserLogFields.user_id} $textType,${UserLogFields.check_in_time} $textType,
           ${UserLogFields.check_out_time} $textType,${UserLogFields.date} $textType)''');
/*
    create variant group table
*/
    await db.execute(
        '''CREATE TABLE $tableVariantGroup ( ${VariantGroupFields.variant_group_sqlite_id} $idType, ${VariantGroupFields.variant_group_id} $integerType,${VariantGroupFields.product_id} $textType,${VariantGroupFields.name} $textType,
           ${VariantGroupFields.created_at} $textType,${VariantGroupFields.updated_at} $textType,${VariantGroupFields.soft_delete} $textType)''');
/*
    create variant item table
*/
    await db.execute(
        '''CREATE TABLE $tableVariantItem ( ${VariantItemFields.variant_item_sqlite_id} $idType, ${VariantItemFields.variant_item_id} $integerType , ${VariantItemFields.variant_group_id} $textType,${VariantItemFields.name} $textType,
           ${VariantItemFields.created_at} $textType,${VariantItemFields.updated_at} $textType,${VariantItemFields.soft_delete} $textType)''');
/*
    create branch link dining table
*/
    await db.execute(
        '''CREATE TABLE $tableBranchLinkDining ( ${BranchLinkDiningFields.branch_link_dining_id} $idType, ${BranchLinkDiningFields.branch_id} $textType,
           ${BranchLinkDiningFields.dining_id} $textType, ${BranchLinkDiningFields.is_default} $integerType, ${BranchLinkDiningFields.sequence} $textType,
           ${BranchLinkDiningFields.created_at} $textType, ${BranchLinkDiningFields.updated_at} $textType, ${BranchLinkDiningFields.soft_delete} $textType)''');
/*
    create branch link modifier
*/
    await db.execute(
        '''CREATE TABLE $tableBranchLinkModifier ( ${BranchLinkModifierFields.branch_link_modifier_id} $idType, ${BranchLinkModifierFields.branch_id} $textType,
           ${BranchLinkModifierFields.mod_group_id} $textType, ${BranchLinkModifierFields.mod_item_id} $textType, ${BranchLinkModifierFields.name} $textType, 
           ${BranchLinkModifierFields.price} $textType, ${BranchLinkModifierFields.sequence} $integerType, ${BranchLinkModifierFields.status} $textType,
           ${BranchLinkModifierFields.created_at} $textType, ${BranchLinkModifierFields.updated_at} $textType,${BranchLinkModifierFields.soft_delete} $textType)''');
/*
    create branch link product table
*/
    await db.execute(
        '''CREATE TABLE $tableBranchLinkProduct ( ${BranchLinkProductFields.branch_link_product_sqlite_id} $idType, ${BranchLinkProductFields.branch_link_product_id} $integerType,
           ${BranchLinkProductFields.branch_id} $textType,
           ${BranchLinkProductFields.product_id} $textType, ${BranchLinkProductFields.has_variant} $textType, ${BranchLinkProductFields.product_variant_id} $textType,
           ${BranchLinkProductFields.b_SKU} $textType, ${BranchLinkProductFields.price} $textType, ${BranchLinkProductFields.stock_type} $textType,
           ${BranchLinkProductFields.daily_limit} $textType, ${BranchLinkProductFields.daily_limit_amount} $textType, ${BranchLinkProductFields.stock_quantity} $textType,
           ${BranchLinkProductFields.created_at} $textType, ${BranchLinkProductFields.updated_at} $textType, ${BranchLinkProductFields.soft_delete} $textType)''');
/*
    create branch link promotion
*/
    await db.execute(
        '''CREATE TABLE $tableBranchLinkPromotion ( ${BranchLinkPromotionFields.branch_link_promotion_id} $idType, ${BranchLinkPromotionFields.branch_id} $textType,
           ${BranchLinkPromotionFields.promotion_id} $textType, ${BranchLinkPromotionFields.created_at} $textType, ${BranchLinkPromotionFields.updated_at} $textType,
           ${BranchLinkPromotionFields.soft_delete} $textType)''');
/*
    create branch link tax table
*/
    await db.execute(
        '''CREATE TABLE $tableBranchLinkTax ( ${BranchLinkTaxFields.branch_link_tax_id} $idType, ${BranchLinkTaxFields.branch_id} $textType,
           ${BranchLinkTaxFields.tax_id} $textType, ${BranchLinkTaxFields.created_at} $textType, ${BranchLinkTaxFields.updated_at} $textType,
           ${BranchLinkTaxFields.soft_delete} $textType)''');
/*
    create branch link user table
*/
    await db.execute(
        '''CREATE TABLE $tableBranchLinkUser ( ${BranchLinkUserFields.branch_link_user_id} $idType, ${BranchLinkUserFields.branch_id} $textType,
           ${BranchLinkUserFields.user_id} $textType, ${BranchLinkUserFields.created_at} $textType, ${BranchLinkUserFields.updated_at} $textType,
           ${BranchLinkUserFields.soft_delete} $textType)''');
/*
    create branch table
*/
    await db.execute('''CREATE TABLE $tableBranch (
           ${BranchFields.branchID} $idType,
           ${BranchFields.name} $textType)''');

/*
    create app color table
*/
    await db.execute(
        '''CREATE TABLE  $tableAppColors ( 
          ${AppColorsFields.app_color_sqlite_id} $idType, 
          ${AppColorsFields.app_color_id} $integerType,
          ${AppColorsFields.background_color} $textType,
          ${AppColorsFields.button_color} $textType,
          ${AppColorsFields.icon_color} $textType,
          ${AppColorsFields.created_at} $textType,
          ${AppColorsFields.updated_at} $textType,
          ${AppColorsFields.soft_delete} $textType)''');
  }

/*
  ------------------------------------------------------------------------------------------------------------------------------------------------------------------------
*/

/*
  add user to sqlite
*/
  Future<User> insertUser(User user) async {
    final db = await instance.database;
    final id = await db.insert(tableUser!, user.toJson());
    return user.copy(user_id: id);
  }

/*
  add table to sqlite
*/
  Future<PosTable> insertPosTable(PosTable table) async {
    final db = await instance.database;
    final id = await db.insert(tablePosTable!, table.toJson());
    return table.copy(table_sqlite_id: id);
  }

/*
  add branch link user to sqlite
*/
  Future<BranchLinkUser> insertBranchLinkUser(BranchLinkUser data) async {
    final db = await instance.database;
    final id = await db.insert(tableBranchLinkUser!, data.toJson());
    return data.copy(branch_link_user_id: id);
  }

/*
  add dining option to sqlite
*/
  Future<DiningOption> insertDiningOption(DiningOption data) async {
    final db = await instance.database;
    final id = await db.insert(tableDiningOption!, data.toJson());
    return data.copy(dining_id: id);
  }

/*
  add branch link dining option to sqlite
*/
  Future<BranchLinkDining> insertBranchLinkDining(BranchLinkDining data) async {
    final db = await instance.database;
    final id = await db.insert(tableBranchLinkDining!, data.toJson());
    return data.copy(branch_link_dining_id: id);
  }

/*
  add tax to sqlite
*/
  Future<Tax> insertTax(Tax data) async {
    final db = await instance.database;
    final id = await db.insert(tableTax!, data.toJson());
    return data.copy(tax_id: id);
  }

/*
  add branch link tax to sqlite
*/
  Future<BranchLinkTax> insertBranchLinkTax(BranchLinkTax data) async {
    final db = await instance.database;
    final id = await db.insert(tableBranchLinkTax!, data.toJson());
    return data.copy(branch_link_tax_id: id);
  }

/*
  add tax link dining to sqlite
*/
  Future<TaxLinkDining> insertTaxLinkDining(TaxLinkDining data) async {
    final db = await instance.database;
    final id = await db.insert(tableTaxLinkDining!, data.toJson());
    return data.copy(tax_link_dining_id: id);
  }

/*
  add product categories to sqlite
*/
  Future<Categories> insertCategories(Categories data) async {
    final db = await instance.database;
    final id = await db.insert(tableCategories!, data.toJson());
    return data.copy(category_sqlite_id: id);
  }

/*
  add promotion to sqlite
*/
  Future<Promotion> insertPromotion(Promotion data) async {
    final db = await instance.database;
    final id = await db.insert(tablePromotion!, data.toJson());
    return data.copy(promotion_id: id);
  }

/*
  add branch link promotion to sqlite
*/
  Future<BranchLinkPromotion> insertBranchLinkPromotion(
      BranchLinkPromotion data) async {
    final db = await instance.database;
    final id = await db.insert(tableBranchLinkPromotion!, data.toJson());
    return data.copy(branch_link_promotion_id: id);
  }

/*
  add customer to sqlite
*/
  Future<Customer> insertCustomer(Customer data) async {
    final db = await instance.database;
    final id = await db.insert(tableCustomer!, data.toJson());
    return data.copy(customer_id: id);
  }

/*
  add bill to sqlite
*/
  Future<Bill> insertBill(Bill data) async {
    final db = await instance.database;
    final id = await db.insert(tableBill!, data.toJson());
    return data.copy(bill_id: id);
  }

/*
  add payment option to sqlite
*/
  Future<PaymentLinkCompany> insertPaymentLinkCompany(
      PaymentLinkCompany data) async {
    final db = await instance.database;
    final id = await db.insert(tablePaymentLinkCompany!, data.toJson());
    return data.copy(payment_link_company_id: id);
  }

/*
  add refund list to sqlite
*/
  Future<Refund> insertRefund(Refund data) async {
    final db = await instance.database;
    final id = await db.insert(tableRefund!, data.toJson());
    return data.copy(refund_id: id);
  }

/*
  add modifier group to sqlite
*/
  Future<ModifierGroup> insertModifierGroup(ModifierGroup data) async {
    final db = await instance.database;
    final id = await db.insert(tableModifierGroup!, data.toJson());
    return data.copy(mod_group_id: id);
  }

/*
  add modifier item to sqlite
*/
  Future<ModifierItem> insertModifierItem(ModifierItem data) async {
    final db = await instance.database;
    final id = await db.insert(tableModifierItem!, data.toJson());
    return data.copy(mod_item_id: id);
  }

/*
  add branch link modifier to sqlite
*/
  Future<BranchLinkModifier> insertBranchLinkModifier(
      BranchLinkModifier data) async {
    final db = await instance.database;
    final id = await db.insert(tableBranchLinkModifier!, data.toJson());
    return data.copy(branch_link_modifier_id: id);
  }

/*
  add product to sqlite
*/
  Future<Product> insertProduct(Product data) async {
    final db = await instance.database;
    final id = await db.insert(tableProduct!, data.toJson());
    return data.copy(product_sqlite_id: id);
  }

/*
  add branch link product to sqlite
*/
  Future<BranchLinkProduct> insertBranchLinkProduct(
      BranchLinkProduct data) async {
    final db = await instance.database;
    final id = await db.insert(tableBranchLinkProduct!, data.toJson());
    return data.copy(branch_link_product_id: id);
  }

/*
  add modifier link product to sqlite
*/
  Future<ModifierLinkProduct> insertModifierLinkProduct(
      ModifierLinkProduct data) async {
    final db = await instance.database;
    final id = await db.insert(tableModifierLinkProduct!, data.toJson());
    return data.copy(modifier_link_product_id: id);
  }

/*
  add variant group to sqlite
*/
  Future<VariantGroup> insertVariantGroup(VariantGroup data) async {
    final db = await instance.database;
    final id = await db.insert(tableVariantGroup!, data.toJson());
    return data.copy(variant_group_sqlite_id: id);
  }

/*
  add variant item to sqlite
*/
  Future<VariantItem> insertVariantItem(VariantItem data) async {
    final db = await instance.database;
    final id = await db.insert(tableVariantItem!, data.toJson());
    return data.copy(variant_item_id: id);
  }

/*
  add product variant to sqlite
*/
  Future<ProductVariant> insertProductVariant(ProductVariant data) async {
    final db = await instance.database;
    final id = await db.insert(tableProductVariant!, data.toJson());
    return data.copy(product_variant_id: id);
  }

/*
  add product variant detail to sqlite
*/
  Future<ProductVariantDetail> insertProductVariantDetail(
      ProductVariantDetail data) async {
    final db = await instance.database;
    final id = await db.insert(tableProductVariantDetail!, data.toJson());
    return data.copy(product_variant_detail_id: id);
  }

/*
  add all order to sqlite
*/
  Future<Order> insertOrder(Order data) async {
    final db = await instance.database;
    final id = await db.insert(tableOrder!, data.toJson());
    return data.copy(order_id: id);
  }

/*
  add all order cache to sqlite
*/
  Future<OrderCache> insertOrderCache(OrderCache data) async {
    final db = await instance.database;
    final id = await db.insert(tableOrderCache!, data.toJson());
    return data.copy(order_cache_id: id);
  }

/*
  add all order detail to sqlite
*/
  Future<OrderDetail> insertOrderDetail(OrderDetail data) async {
    final db = await instance.database;
    final id = await db.insert(tableOrderDetail!, data.toJson());
    return data.copy(order_detail_id: id);
  }

/*
  add sale to sqlite
*/
  Future<Sale> insertSale(Sale data) async {
    final db = await instance.database;
    final id = await db.insert(tableSale!, data.toJson());
    return data.copy(sale_id: id);
  }

/*
  add branch to sqlite
*/
  Future<Branch> insertBranch(Branch data) async {
    final db = await instance.database;
    final id = await db.insert(tableBranch!, data.toJson());
    return data.copy(branchID: id);
  }

/*
  add branch to sqlite
*/
  Future<AppColors> insertColor(AppColors data) async {
    final db = await instance.database;
    final id = await db.insert(tableAppColors!, data.toJson());
    return data.copy(app_color_id: id);
  }

/*
  ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
*/

/*
  verify pos pin
*/
  Future<User?> verifyPosPin(String pos_pin, String branch_id) async {
    final db = await instance.database;
    // final maps = await db.query(tableUser!,columns: UserFields.values, where: '${UserFields.pos_pin} = ?', whereArgs: [pos_pin]);
    final maps = await db.rawQuery(
        'SELECT a.* FROM $tableUser AS a JOIN $tableBranchLinkUser AS b ON a.user_id = b.user_id WHERE a.soft_delete = ? AND b.soft_delete = ? AND b.branch_id = ? AND a.pos_pin = ?',
        ['', '', branch_id, pos_pin]);
    if (maps.isNotEmpty) {
      return User.fromJson(maps.first);
    }
  }

/*
  read branch name
*/
  Future<Branch?> readBranchName(String branch_id) async {
    final db = await instance.database;
    final maps = await db.query(tableBranch!,
        columns: BranchFields.values,
        where: '${BranchFields.branchID} = ?',
        whereArgs: [branch_id]);
    if (maps.isNotEmpty) {
      return Branch.fromJson(maps.first);
    }
  }

  /*
  read specific variant item
*/
  Future<VariantItem?> readVariantItem(String name) async {
    final db = await instance.database;
    final maps = await db.rawQuery(
        'SELECT * FROM $tableVariantItem WHERE soft_delete = ? AND name = ?',
        ['', name]);
    if (maps.isNotEmpty) {
      return VariantItem.fromJson(maps.first);
    }
  }

  /*
  read variant group
*/
  Future<List<VariantGroup>> readVariantGroup(String product_id) async {
    final db = await instance.database;
    final result = await db.rawQuery(
        'SELECT * FROM $tableVariantGroup WHERE soft_delete = ? AND product_id = ?',
        ['', product_id]);

    return result.map((json) => VariantGroup.fromJson(json)).toList();

  }

  /*
  read variant item
*/
  Future<List<VariantItem>> readVariantItemForGroup(String variant_group_id) async {
    final db = await instance.database;
    final result = await db.rawQuery(
        'SELECT * FROM $tableVariantItem WHERE soft_delete = ? AND variant_group_id = ?',
        ['', variant_group_id]);

    return result.map((json) => VariantItem.fromJson(json)).toList();

  }

/*
  read app colors
*/
  Future<List<AppColors>> readAppColors() async {
    final db = await instance.database;
    final result = await db.rawQuery(
      'SELECT * FROM $tableAppColors WHERE soft_delete = ? ' ,
      ['']
    );
    return result.map((json) => AppColors.fromJson(json)).toList();
  }

/*
  read categories (categories part)
*/
  Future<List<Categories>> readCategories() async {
    final db = await instance.database;
    final result = await db.rawQuery(
        'SELECT DISTINCT a.*,(SELECT COUNT(DISTINCT b.product_id) from $tableProduct AS b JOIN $tableBranchLinkProduct AS c ON b.product_id = c.product_id where b.category_id= a.category_id AND b.soft_delete = ? AND c.soft_delete = ?)item_sum FROM $tableCategories AS a WHERE a.soft_delete = ?',
        ['', '', '']);
    return result.map((json) => Categories.fromJson(json)).toList();
  }

/*
  search categories (categories part)
*/
  Future<List<Categories>> searchCategories(String name) async {
    final db = await instance.database;
    final result = await db.rawQuery(
        'SELECT DISTINCT a.*,(SELECT COUNT(DISTINCT b.product_id) from $tableProduct AS b JOIN $tableBranchLinkProduct AS c ON b.product_id = c.product_id where b.category_id= a.category_id AND b.soft_delete = ? AND c.soft_delete = ?)item_sum FROM $tableCategories AS a WHERE a.soft_delete = ? AND a.name LIKE ? ',
        ['', '', '', '%' + name + '%']);
    return result.map((json) => Categories.fromJson(json)).toList();
  }

/*
  read all categories (product part)
*/
  Future<List<Categories>> readAllCategories() async {
    final db = await instance.database;
    final result = await db.rawQuery(
        'SELECT DISTINCT a.* , (SELECT COUNT(b.product_id) from $tableProduct AS b where b.category_id= a.category_id AND b.soft_delete = ?) item_sum FROM $tableCategories AS a JOIN $tableProduct AS b ON a.category_id = b.category_id JOIN $tableBranchLinkProduct AS c ON b.product_id = c.product_id WHERE a.soft_delete = ? AND b.soft_delete = ? AND c.soft_delete = ? AND b.available = ? ',
        ['', '', '', '', 1]);
    return result.map((json) => Categories.fromJson(json)).toList();
  }

/*
  search categories (product part)
*/
  Future<List<Categories>> readSpecificCategory(String name) async {
    final db = await instance.database;
    final result = await db.rawQuery(
        'SELECT DISTINCT a.* , (SELECT COUNT(b.product_id) from $tableProduct AS b where b.category_id= a.category_id AND b.soft_delete = ?) item_sum FROM $tableCategories AS a JOIN $tableProduct AS b ON a.category_id = b.category_id JOIN $tableBranchLinkProduct AS c ON b.product_id = c.product_id WHERE a.soft_delete = ? AND b.soft_delete = ? AND c.soft_delete = ? AND b.available = ? AND a.name LIKE ? ',
        ['', '', '', '', 1, '%' + name + '%']);
    return result.map((json) => Categories.fromJson(json)).toList();
  }

/*
  read all product
*/
  Future<List<Product>> readAllProduct() async {
    final db = await instance.database;
    final result = await db.rawQuery(
        'SELECT DISTINCT a.* FROM $tableProduct AS a JOIN $tableBranchLinkProduct AS b ON a.product_id = b.product_id WHERE a.soft_delete = ? AND b.soft_delete = ? AND a.available = ?',
        ['', '', 1]);
    return result.map((json) => Product.fromJson(json)).toList();
  }

/*
  read specific category product
*/
  Future<List<Product>> readSpecificProduct(String name) async {
    final db = await instance.database;
    final result = await db.rawQuery(
        'SELECT DISTINCT a.* FROM $tableProduct AS a JOIN $tableBranchLinkProduct AS b ON a.product_id = b.product_id JOIN $tableCategories AS c ON a.category_id = c.category_id WHERE a.soft_delete = ? AND b.soft_delete = ? AND c.soft_delete = ? AND c.name = ? AND a.available = ?',
        ['', '', '', name, 1]);
    return result.map((json) => Product.fromJson(json)).toList();
  }

/*
  set default sku
*/
  Future<List<Product>> readDefaultSKU(String companyID) async {
    final db = await instance.database;
    final result = await db.rawQuery(
        'SELECT MAX(SKU) as SKU FROM $tableProduct WHERE soft_delete = ? AND company_id = ?',
        ['', companyID]);
    return result.map((json) => Product.fromJson(json)).toList();
  }

/*
  check sku for add product
*/
  Future<List<Product>> checkProductSKU(String sku) async {
    final db = await instance.database;
    final result = await db.rawQuery(
        'SELECT * FROM $tableProduct WHERE soft_delete = ? AND SKU = ?',
        ['', sku]);
    return result.map((json) => Product.fromJson(json)).toList();
  }

/*
  check sku for edit product
*/
  Future<List<Product>> checkProductSKUForEdit(String sku) async {
    final db = await instance.database;
    final result = await db.rawQuery(
        'SELECT * FROM $tableProduct WHERE soft_delete = ? AND SKU != ?',
        ['', sku]);
    return result.map((json) => Product.fromJson(json)).toList();
  }

/*
  search product
*/
  Future<List<Product>> searchProduct(String text) async {
    final db = await instance.database;
    final result = await db.rawQuery(
        'SELECT DISTINCT a.* FROM $tableProduct AS a JOIN $tableBranchLinkProduct AS b ON a.product_id = b.product_id WHERE a.soft_delete = ? AND b.soft_delete = ? AND a.name LIKE ? OR a.SKU LIKE ?',
        ['', '', '%' + text + '%', '%' + text + '%']);
    return result.map((json) => Product.fromJson(json)).toList();
  }

/*
  read product variant group name
*/
  Future<List<VariantGroup>> readProductVariantGroup(int productID) async {
    final db = await instance.database;
    final result = await db.rawQuery(
        'SELECT DISTINCT a.variant_group_id, a.product_id, a.name, a.created_at, a.updated_at, a.soft_delete FROM $tableVariantGroup AS a JOIN $tableBranchLinkProduct AS b ON a.product_id = b.product_id JOIN $tableProductVariant AS c ON b.product_variant_id = c.product_variant_id JOIN $tableProductVariantDetail AS d ON c.product_variant_id = d.product_variant_id JOIN $tableVariantItem AS e ON d.variant_item_id = e.variant_item_id AND e.variant_group_id = a.variant_group_id WHERE a.soft_delete = ? AND b.soft_delete = ? AND c.soft_delete = ? AND d.soft_delete = ? AND e.soft_delete = ? AND a.product_id = ?',
        ['', '', '', '', '', productID]);
    return result.map((json) => VariantGroup.fromJson(json)).toList();
  }

/*
  read product variant group item
*/
  Future<List<VariantItem>> readProductVariantItem(int variantGroupID) async {
    final db = await instance.database;
    final result = await db.rawQuery(
        'SELECT DISTINCT a.variant_item_id, a.variant_group_id, a.name, a.created_at, a.updated_at, a.soft_delete FROM $tableVariantItem AS a JOIN $tableVariantGroup AS b ON a.variant_group_id = b.variant_group_id JOIN $tableProductVariantDetail AS c ON a.variant_item_id = c.variant_item_id WHERE a.soft_delete = ? AND b.soft_delete = ? AND c.soft_delete = ? AND a.variant_group_id = ?',
        ['', '', '', variantGroupID]);
    return result.map((json) => VariantItem.fromJson(json)).toList();
  }

/*
  read product modifier group name
*/
  Future<List<ModifierGroup>> readProductModifierGroupName(
      int productID) async {
    final db = await instance.database;
    final result = await db.rawQuery(
        'SELECT a.* FROM $tableModifierGroup AS a JOIN $tableModifierLinkProduct AS b ON a.mod_group_id = b.mod_group_id WHERE a.soft_delete = ? AND b.soft_delete = ? AND b.product_id = ?',
        ['', '', productID]);
    return result.map((json) => ModifierGroup.fromJson(json)).toList();
  }

  /*
  read all product modifier group name
  */
  Future<List<ModifierGroup>> readAllModifier() async {
    final db = await instance.database;
    final result = await db.rawQuery(
        'SELECT * FROM $tableModifierGroup WHERE soft_delete = ?', ['']);
    return result.map((json) => ModifierGroup.fromJson(json)).toList();
  }

  /*
  read all product modifier group name
  */
  Future<List<ModifierLinkProduct>> readProductModifier(
      String productID) async {
    final db = await instance.database;
    final result = await db.rawQuery(
        'SELECT * FROM $tableModifierLinkProduct WHERE soft_delete = ? AND product_id = ?',
        ['', productID]);
    return result.map((json) => ModifierLinkProduct.fromJson(json)).toList();
  }

/*
  read product modifier group item
*/
  Future<List<ModifierItem>> readProductModifierItem(int modGroupID) async {
    final db = await instance.database;
    final result = await db.rawQuery(
        'SELECT * FROM $tableModifierItem WHERE soft_delete = ? AND mod_group_id = ?',
        ['', modGroupID]);
    return result.map((json) => ModifierItem.fromJson(json)).toList();
  }

/*
  read all table
*/
  Future<List<PosTable>> readAllTable(int branchID) async {
    final db = await instance.database;
    final result = await db.rawQuery(
        'SELECT * FROM $tablePosTable WHERE soft_delete = ? AND branch_id = ?',
        ['', branchID]);
    return result.map((json) => PosTable.fromJson(json)).toList();
  }

/*
  read specific user
*/
  Future<List<User>> readSpecificUserWithRole(String pin) async {
    final db = await instance.database;
    final result = await db.rawQuery(
        'SELECT * FROM $tableUser WHERE soft_delete = ? AND role = ? AND pos_pin = ?',
        ['', 0, pin]);
    return result.map((json) => User.fromJson(json)).toList();
  }


/*
  update category
*/
  Future<int> updateCategory(Categories data) async {
    final db = await instance.database;
    return await db.rawUpdate(
        'UPDATE $tableCategories SET name = ?, color = ?, updated_at = ? WHERE category_sqlite_id = ?',
        [data.name, data.color, data.updated_at, data.category_sqlite_id]);
  }

/*
  update App color
*/
  Future<int> updateAppColor(AppColors data) async {
    final db = await instance.database;
    return await db.rawUpdate(
        'UPDATE $tableAppColors SET background_color = ?, button_color = ?, icon_color = ?, updated_at = ? WHERE app_color_sqlite_id = ?',
        [data.background_color, data.button_color, data.icon_color, data.updated_at, data.app_color_sqlite_id]);
  }

/*
  update Pos Table
*/
  Future<int> updatePosTable(PosTable data) async {
    final db = await instance.database;
    return await db.rawUpdate(
        'UPDATE $tablePosTable SET number = ?, seats = ?, updated_at = ? WHERE table_sqlite_id = ?',
        [data.number, data.seats, data.updated_at, data.table_sqlite_id]);
  }

/*
  delete category
*/
  Future<int> deleteCategory(Categories data) async {
    final db = await instance.database;
    return await db.rawUpdate(
        'UPDATE $tableCategories SET soft_delete = ? WHERE category_sqlite_id = ?',
        [data.soft_delete, data.category_sqlite_id]);
  }

/*
  Soft-delete Pos Table
*/
  Future<int> deletePosTable(PosTable data) async {
    final db = await instance.database;
    return await db.rawUpdate(
      'UPDATE $tablePosTable SET soft_delete = ? WHERE table_sqlite_id = ?',
      [data.soft_delete, data.table_sqlite_id]);
  }

/*
  Delete All Branch
*/
  Future clearAllBranch() async {
    final db = await instance.database;
    return await db.rawDelete('DELETE FROM $tableBranch');
  }

/*
  Delete All Branch Link Modifier
*/
  Future clearAllBranchLinkModifier() async {
    final db = await instance.database;
    return await db.rawDelete('DELETE FROM $tableBranchLinkModifier');
  }

/*
  Delete All Branch Link Modifier
*/
  Future clearAllBranchLinkProduct() async {
    final db = await instance.database;
    return await db.rawDelete('DELETE FROM $tableBranchLinkProduct');
  }

/*
  Delete All Branch Link Promotion
*/
  Future clearAllBranchLinkPromotion() async {
    final db = await instance.database;
    return await db.rawDelete('DELETE FROM $tableBranchLinkPromotion');
  }

/*
  Delete All Branch Link Tax
*/
  Future clearAllBranchLinkTax() async {
    final db = await instance.database;
    return await db.rawDelete('DELETE FROM $tableBranchLinkTax');
  }

/*
  Delete All Branch Link Dining Option
*/
  Future clearAllBranchLinkDining() async {
    final db = await instance.database;
    return await db.rawDelete('DELETE FROM $tableBranchLinkDining');
  }

/*
  Delete All Branch Link User
*/
  Future clearAllBranchLinkUser() async {
    final db = await instance.database;
    return await db.rawDelete('DELETE FROM $tableBranchLinkUser');
  }

/*
  Delete all category
*/
  Future clearAllCategory() async {
    final db = await instance.database;
    return await db.rawDelete('DELETE FROM $tableCategories');
  }

/*
  Delete All Dining Option
*/
  Future clearAllDiningOption() async {
    final db = await instance.database;
    return await db.rawDelete('DELETE FROM $tableDiningOption');
  }

/*
  Delete All ModifierItem
*/
  Future clearAllModifierItem() async {
    final db = await instance.database;
    return await db.rawDelete('DELETE FROM $tableModifierItem');
  }

/*
  Delete All ModifierGroup
*/
  Future clearAllModifierGroup() async {
    final db = await instance.database;
    return await db.rawDelete('DELETE FROM $tableModifierGroup');
  }

/*
  Delete All Modifier link Product
*/
  Future clearAllModifierLinkProduct() async {
    final db = await instance.database;
    return await db.rawDelete('DELETE FROM $tableModifierLinkProduct');
  }

/*
  Delete Pos Table
*/
  Future clearAllPosTable() async {
    final db = await instance.database;
    return await db.rawDelete('DELETE FROM $tablePosTable');
  }

/*
  Delete All Product
*/
  Future clearAllProduct() async {
    final db = await instance.database;
    return await db.rawDelete('DELETE FROM $tableProduct');
  }

/*
  Delete All ProductVariant
*/
  Future clearAllProductVariant() async {
    final db = await instance.database;
    return await db.rawDelete('DELETE FROM $tableProductVariant');
  }

/*
  Delete All ProductVariantDetail
*/
  Future clearAllProductVariantDetail() async {
    final db = await instance.database;
    return await db.rawDelete('DELETE FROM $tableProductVariantDetail');
  }

/*
  Delete all promotion
*/
  Future clearAllPromotion() async {
    final db = await instance.database;
    return await db.rawDelete('DELETE FROM $tablePromotion');
  }

/*
  Delete all payment link company
*/
  Future clearAllPaymentLinkCompany() async {
    final db = await instance.database;
    return await db.rawDelete('DELETE FROM $tablePaymentLinkCompany');
  }

/*
  Delete all tax
*/
  Future clearAllTax() async {
    final db = await instance.database;
    return await db.rawDelete('DELETE FROM $tableTax');
  }

/*
  Delete all tax link dining
*/
  Future clearAllTaxLinkDining() async {
    final db = await instance.database;
    return await db.rawDelete('DELETE FROM $tableTaxLinkDining');
  }

/*
  Delete all User
*/
  Future clearAllUser() async {
    final db = await instance.database;
    return await db.rawDelete('DELETE FROM $tableUser');
  }

/*
  Delete All VariantItem
*/
  Future clearAllVariantItem() async {
    final db = await instance.database;
    return await db.rawDelete('DELETE FROM $tableVariantItem');
  }

/*
  Delete All VariantGroup
*/
  Future clearAllVariantGroup() async {
    final db = await instance.database;
    return await db.rawDelete('DELETE FROM $tableVariantGroup');
  }

  // Future<List<Categories>> readAllNotes() async {
  //   final db = await instance.database;
  //   final orderBy = '${UserFields.user_id} ASC';
  //   // final result = await db.rawQuery('SELECT * FROM $tableUser ORDER BY $orderBy');
  //   final result = await db.query(tableUser!, orderBy: orderBy);
  //   return result.map((json) => User.fromJson(json)).toList();
  // }
  //
  // Future<int> update(User user) async{
  //   final db = await instance.database;
  //   return db.update(tableUser!, user.toJson(), where: '${UserFields.user_id} = ?' , whereArgs: [user.user_id] );
  // }
  //
  // Future<int> delete(int id ) async {
  //   final db = await instance.database;
  //   return await db.delete(tableUser!, where: '${UserFields.user_id} = ?' , whereArgs: [id]);
  //
  // }

  Future close() async {
    final db = await instance.database;
    db.close();
  }
}
