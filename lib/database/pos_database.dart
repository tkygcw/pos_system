import 'dart:convert';

import 'package:pos_system/database/domain.dart';
import 'package:pos_system/object/bill.dart';
import 'package:pos_system/object/branch.dart';
import 'package:pos_system/object/branch_link_user.dart';
import 'package:pos_system/object/cash_record.dart';
import 'package:pos_system/object/categories.dart';
import 'package:pos_system/object/customer.dart';
import 'package:pos_system/object/dining_option.dart';
import 'package:pos_system/object/modifier_group.dart';
import 'package:pos_system/object/modifier_item.dart';
import 'package:pos_system/object/modifier_link_product.dart';
import 'package:pos_system/object/order.dart';
import 'package:pos_system/object/order_cache.dart';
import 'package:pos_system/object/order_detail.dart';
import 'package:pos_system/object/order_modifier_detail.dart';
import 'package:pos_system/object/order_tax_detail.dart';
import 'package:pos_system/object/payment_link_company.dart';
import 'package:pos_system/object/payment_type.dart';
import 'package:pos_system/object/printer_link_category.dart';
import 'package:pos_system/object/product.dart';
import 'package:pos_system/object/product_variant.dart';
import 'package:pos_system/object/product_variant_detail.dart';
import 'package:pos_system/object/promotion.dart';
import 'package:pos_system/object/receipt.dart';
import 'package:pos_system/object/refund.dart';
import 'package:pos_system/object/sale.dart';
import 'package:pos_system/object/table.dart';
import 'package:pos_system/object/table_use.dart';
import 'package:pos_system/object/table_use_detail.dart';
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
import '../object/printer.dart';

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
           ${CategoriesFields.sequence} $textType, ${CategoriesFields.color} $textType, ${CategoriesFields.sync_status} $integerType, ${CategoriesFields.created_at} $textType, ${CategoriesFields.updated_at} $textType, 
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
        '''CREATE TABLE $tableModifierGroup ( ${ModifierGroupFields.mod_group_id} $idType, ${ModifierGroupFields.company_id} $textType, ${ModifierGroupFields.name} $textType, ${ModifierGroupFields.dining_id} $textType, ${ModifierGroupFields.compulsory} $textType, 
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
           ${ModifierLinkProductFields.product_id} $textType, ${ModifierLinkProductFields.product_sqlite_id} $textType, ${ModifierLinkProductFields.sync_status} $integerType,  ${ModifierLinkProductFields.created_at} $textType, ${ModifierLinkProductFields.updated_at} $textType,
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
    await db.execute('''CREATE TABLE $tableOrderCache ( 
          ${OrderCacheFields.order_cache_sqlite_id} $idType, 
          ${OrderCacheFields.order_cache_id} $integerType, 
          ${OrderCacheFields.company_id} $textType, 
          ${OrderCacheFields.branch_id} $textType, 
          ${OrderCacheFields.order_detail_id} $textType, 
          ${OrderCacheFields.table_use_sqlite_id} $textType, 
          ${OrderCacheFields.batch_id} $textType, 
          ${OrderCacheFields.dining_id} $textType, 
          ${OrderCacheFields.order_id} $textType, 
          ${OrderCacheFields.order_by} $textType,
          ${OrderCacheFields.order_by_user_id} $textType, 
          ${OrderCacheFields.cancel_by} $textType,
          ${OrderCacheFields.cancel_by_user_id} $textType,
          ${OrderCacheFields.customer_id} $textType, 
          ${OrderCacheFields.total_amount} $textType,
          ${OrderCacheFields.sync_status} $integerType,
          ${OrderCacheFields.created_at} $textType, 
          ${OrderCacheFields.updated_at} $textType, 
          ${OrderCacheFields.soft_delete} $textType)''');
/*
    create order detail table
*/
    await db.execute('''CREATE TABLE $tableOrderDetail ( 
        ${OrderDetailFields.order_detail_sqlite_id} $idType, 
        ${OrderDetailFields.order_detail_id} $integerType, 
        ${OrderDetailFields.order_cache_sqlite_id} $textType, 
        ${OrderDetailFields.branch_link_product_sqlite_id} $textType, 
        ${OrderDetailFields.category_sqlite_id} $textType,
        ${OrderDetailFields.productName} $textType,
        ${OrderDetailFields.has_variant} $textType, 
        ${OrderDetailFields.product_variant_name} $textType, 
        ${OrderDetailFields.price} $textType, 
        ${OrderDetailFields.quantity} $textType, 
        ${OrderDetailFields.remark} $textType, 
        ${OrderDetailFields.account} $textType,
        ${OrderDetailFields.cancel_by} $textType,
        ${OrderDetailFields.cancel_by_user_id} $textType,
        ${OrderDetailFields.sync_status} $integerType,
        ${OrderDetailFields.created_at} $textType, 
        ${OrderDetailFields.updated_at} $textType,
        ${OrderDetailFields.soft_delete} $textType)''');
/*
    create payment link company
*/
    await db.execute(
        '''CREATE TABLE $tablePaymentLinkCompany ( ${PaymentLinkCompanyFields.payment_link_company_id} $idType, ${PaymentLinkCompanyFields.payment_type_id} $textType,
           ${PaymentLinkCompanyFields.company_id} $textType,${PaymentLinkCompanyFields.name} $textType, ${PaymentLinkCompanyFields.type} $integerType, 
           ${PaymentLinkCompanyFields.ipay_code} $textType, 
           ${PaymentLinkCompanyFields.created_at} $textType, ${PaymentLinkCompanyFields.updated_at} $textType, ${PaymentLinkCompanyFields.soft_delete} $textType)''');
/*
    create product table
*/
    await db.execute(
        '''CREATE TABLE $tableProduct ( ${ProductFields.product_sqlite_id} $idType, ${ProductFields.product_id} $integerType, ${ProductFields.category_id} $textType, ${ProductFields.category_sqlite_id} $textType, ${ProductFields.company_id} $textType,
           ${ProductFields.name} $textType,${ProductFields.price} $textType, ${ProductFields.description} $textType, ${ProductFields.SKU} $textType, ${ProductFields.image} $textType,
           ${ProductFields.has_variant} $integerType,${ProductFields.stock_type} $integerType, ${ProductFields.stock_quantity} $textType, ${ProductFields.available} $integerType,
           ${ProductFields.graphic_type} $textType, ${ProductFields.color} $textType, ${ProductFields.daily_limit} $textType, ${ProductFields.daily_limit_amount} $textType,${ProductFields.sync_status} $integerType,
           ${ProductFields.created_at} $textType, ${ProductFields.updated_at} $textType, ${ProductFields.soft_delete} $textType)''');
/*
    create product variant table
*/
    await db.execute(
        '''CREATE TABLE $tableProductVariant ( ${ProductVariantFields.product_variant_sqlite_id} $idType, ${ProductVariantFields.product_variant_id} $integerType, ${ProductVariantFields.product_id} $textType, ${ProductVariantFields.variant_name} $textType,
           ${ProductVariantFields.SKU} $textType,${ProductVariantFields.price} $textType,${ProductVariantFields.stock_type} $textType, ${ProductVariantFields.daily_limit} $textType, ${ProductVariantFields.daily_limit_amount} $textType,
           ${ProductVariantFields.stock_quantity} $textType, ${ProductVariantFields.sync_status} $integerType,${ProductVariantFields.created_at} $textType, ${ProductVariantFields.updated_at} $textType, ${ProductVariantFields.soft_delete} $textType)''');
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
           ${PosTableFields.seats} $textType, ${PosTableFields.status} $integerType, ${PosTableFields.sync_status} $integerType,
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
        '''CREATE TABLE $tableVariantGroup ( ${VariantGroupFields.variant_group_sqlite_id} $idType, ${VariantGroupFields.variant_group_id} $integerType,${VariantGroupFields.product_id} $textType, ${VariantGroupFields.product_sqlite_id} $textType,${VariantGroupFields.name} $textType, ${VariantGroupFields.sync_status} $integerType,
           ${VariantGroupFields.created_at} $textType,${VariantGroupFields.updated_at} $textType,${VariantGroupFields.soft_delete} $textType)''');
/*
    create variant item table
*/
    await db.execute(
        '''CREATE TABLE $tableVariantItem ( ${VariantItemFields.variant_item_sqlite_id} $idType, ${VariantItemFields.variant_item_id} $integerType , ${VariantItemFields.variant_group_id} $textType, ${VariantItemFields.variant_group_sqlite_id} $textType,${VariantItemFields.name} $textType,${VariantItemFields.sync_status} $integerType,
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
           ${BranchFields.name} $textType,
           ${BranchFields.ipay_merchant_code} $textType,
           ${BranchFields.ipay_merchant_key} $textType)''');

/*
    create app color table
*/
    await db.execute('''CREATE TABLE  $tableAppColors ( 
          ${AppColorsFields.app_color_sqlite_id} $idType, 
          ${AppColorsFields.app_color_id} $integerType,
          ${AppColorsFields.background_color} $textType,
          ${AppColorsFields.button_color} $textType,
          ${AppColorsFields.icon_color} $textType,
          ${AppColorsFields.created_at} $textType,
          ${AppColorsFields.updated_at} $textType,
          ${AppColorsFields.soft_delete} $textType)''');

/*
    create order modifier detail
*/
    await db.execute('''CREATE TABLE $tableOrderModifierDetail(
          ${OrderModifierDetailFields.order_modifier_detail_sqlite_id} $idType,
          ${OrderModifierDetailFields.order_modifier_detail_id} $integerType,
          ${OrderModifierDetailFields.order_detail_id} $textType,
          ${OrderModifierDetailFields.mod_item_id} $textType,
          ${OrderModifierDetailFields.mod_group_id} $textType,
          ${OrderModifierDetailFields.created_at} $textType,
          ${OrderModifierDetailFields.updated_at} $textType,
          ${OrderModifierDetailFields.soft_delete} $textType)''');

/*
    create table use table
*/
    await db.execute('''CREATE TABLE $tableTableUse(
          ${TableUseFields.table_use_sqlite_id} $idType,
          ${TableUseFields.table_use_id} $integerType,
          ${TableUseFields.branch_id} $integerType,
          ${TableUseFields.cardColor} $textType,
          ${TableUseFields.sync_status} $integerType,
          ${TableUseFields.created_at} $textType,
          ${TableUseFields.updated_at} $textType,
          ${TableUseFields.soft_delete} $textType)''');

/*
    create table use detail table
*/
    await db.execute('''CREATE TABLE $tableTableUseDetail(
          ${TableUseDetailFields.table_use_detail_sqlite_id} $idType,
          ${TableUseDetailFields.table_use_detail_id} $integerType,
          ${TableUseDetailFields.table_use_sqlite_id} $textType,
          ${TableUseDetailFields.table_sqlite_id} $textType,
          ${TableUseDetailFields.original_table_sqlite_id} $textType,
          ${TableUseDetailFields.sync_status} $integerType,
          ${TableUseDetailFields.created_at} $textType,
          ${TableUseDetailFields.updated_at} $textType,
          ${TableUseDetailFields.soft_delete} $textType)''');

/*
    create printer table
*/
    await db.execute('''CREATE TABLE $tablePrinter(
          ${PrinterFields.printer_sqlite_id} $idType,
          ${PrinterFields.printer_id} $integerType,
          ${PrinterFields.branch_id} $textType,
          ${PrinterFields.company_id} $textType,
          ${PrinterFields.value} $textType,
          ${PrinterFields.type} $integerType,
          ${PrinterFields.printerLabel} $textType,
          ${PrinterFields.printer_link_category_id} $textType,
          ${PrinterFields.paper_size} $integerType,
          ${PrinterFields.sync_status} $integerType,
          ${PrinterFields.created_at} $textType,
          ${PrinterFields.updated_at} $textType,
          ${PrinterFields.soft_delete} $textType)''');

/*
    create printer link category table
*/
    await db.execute('''CREATE TABLE $tablePrinterLinkCategory(
          ${PrinterLinkCategoryFields.printer_link_category_sqlite_id} $idType,
          ${PrinterLinkCategoryFields.printer_link_category_id} $integerType,
          ${PrinterLinkCategoryFields.printer_sqlite_id} $textType,
          ${PrinterLinkCategoryFields.category_sqlite_id} $textType,
          ${PrinterFields.sync_status} $integerType,
          ${PrinterLinkCategoryFields.created_at} $textType,
          ${PrinterLinkCategoryFields.updated_at} $textType,
          ${PrinterLinkCategoryFields.soft_delete} $textType)''');

/*
    create receipt table
*/
    await db.execute('''CREATE TABLE $tableReceipt(
          ${ReceiptFields.receipt_sqlite_id} $idType,
          ${ReceiptFields.receipt_id} $integerType,
          ${ReceiptFields.branch_id} $textType,
          ${ReceiptFields.company_id} $textType,
          ${ReceiptFields.header_image} $textType,
          ${ReceiptFields.header_text} $textType,
          ${ReceiptFields.footer_image} $textType,
          ${ReceiptFields.footer_text} $textType,
          ${ReceiptFields.status} $integerType,
          ${ReceiptFields.sync_status} $integerType,
          ${ReceiptFields.created_at} $textType,
          ${ReceiptFields.updated_at} $textType,
          ${ReceiptFields.soft_delete} $textType)''');

/*
    create cash record table
*/
    await db.execute('''CREATE TABLE $tableCashRecord(
          ${CashRecordFields.cash_record_sqlite_id} $idType,
          ${CashRecordFields.cash_record_id} $integerType,
          ${CashRecordFields.company_id} $textType,
          ${CashRecordFields.branch_id} $textType,
          ${CashRecordFields.remark} $textType,
          ${CashRecordFields.payment_name} $textType,
          ${CashRecordFields.payment_type_id} $textType,
          ${CashRecordFields.type} $integerType,
          ${CashRecordFields.amount} $textType,
          ${CashRecordFields.user_id} $textType,
          ${CashRecordFields.settlement_date} $textType,
          ${CashRecordFields.sync_status} $integerType,
          ${CashRecordFields.created_at} $textType,
          ${CashRecordFields.updated_at} $textType,
          ${CashRecordFields.soft_delete} $textType)''');

/*
    create order tax detail table
*/
    await db.execute('''CREATE TABLE $tableOrderTaxDetail(
          ${OrderTaxDetailFields.order_tax_detail_sqlite_id} $idType,
          ${OrderTaxDetailFields.order_tax_detail_id} $integerType,
          ${OrderTaxDetailFields.order_sqlite_id} $textType,
          ${OrderTaxDetailFields.order_id} $textType,
          ${OrderTaxDetailFields.tax_name} $textType,
          ${OrderTaxDetailFields.rate} $textType,
          ${OrderTaxDetailFields.tax_id} $textType,
          ${OrderTaxDetailFields.branch_link_tax_id} $textType,
          ${OrderTaxDetailFields.tax_amount} $textType,
          ${OrderTaxDetailFields.sync_status} $integerType,
          ${OrderTaxDetailFields.created_at} $textType,
          ${OrderTaxDetailFields.updated_at} $textType,
          ${OrderTaxDetailFields.soft_delete} $textType)''');

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
  add table to sqlite (from cloud)
*/
  Future<PosTable> insertPosTable(PosTable data) async {
    final db = await instance.database;
    final id = db.rawInsert(
        'INSERT INTO $tablePosTable(table_id, branch_id, number, seats, status, sync_status, created_at, updated_at, soft_delete) VALUES(?, ?, ?, ?, ?, ?, ?, ?, ?)',
        [
          data.table_id,
          data.branch_id,
          data.number,
          data.seats,
          data.status,
          2,
          data.created_at,
          data.updated_at,
          data.soft_delete
        ]);
    return data.copy(table_sqlite_id: await id);
  }

/*
  add product categories to sqlite
*/
  Future<PosTable> insertSyncPosTable(PosTable data) async {
    final db = await instance.database;
    final id = db.rawInsert(
        'INSERT INTO $tablePosTable(table_id, branch_id, number, seats, status, sync_status, created_at, updated_at, soft_delete) VALUES(?, ?, ?, ?, ?, ?, ?, ?, ?)',
        [
          data.table_id,
          data.branch_id,
          data.number,
          data.seats,
          data.status,
          data.sync_status,
          data.created_at,
          data.updated_at,
          data.soft_delete
        ]);
    return data.copy(table_sqlite_id: await id);
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
  add product categories to sqlite (from cloud)
*/
  Future<Categories> insertCategories(Categories data) async {
    final db = await instance.database;
    final id = db.rawInsert(
        'INSERT INTO $tableCategories(category_id, company_id, name, color, sync_status, sequence, created_at, updated_at, soft_delete) VALUES(?, ?, ?, ?, ?, ?, ?, ?, ?)',
        [
          data.category_id,
          data.company_id,
          data.name,
          data.color,
          2,
          data.sequence,
          data.created_at,
          data.updated_at,
          data.soft_delete
        ]);
    return data.copy(category_sqlite_id: await id);
  }

/*
  add product categories to sqlite
*/
  Future<Categories> insertSyncCategories(Categories data) async {
    final db = await instance.database;
    final id = db.rawInsert(
        'INSERT INTO $tableCategories(category_id, company_id, name, color, sync_status, sequence, created_at, updated_at, soft_delete) VALUES(?, ?, ?, ?, ?, ?, ?, ?, ?)',
        [
          data.category_id,
          data.company_id,
          data.name,
          data.color,
          data.sync_status,
          data.sequence,
          data.created_at,
          data.updated_at,
          data.soft_delete
        ]);
    return data.copy(category_sqlite_id: await id);
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
  add product to sqlite (from cloud)
*/
  Future<Product> insertProduct(Product data) async {
    final db = await instance.database;
    final id = db.rawInsert(
        'INSERT INTO $tableProduct(product_id, category_id, category_sqlite_id, company_id, name, price, description, SKU, image, has_variant, stock_type, stock_quantity, available, graphic_type, color, daily_limit, daily_limit_amount, sync_status, created_at, updated_at, soft_delete) VALUES(?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
        [
          data.product_id,
          data.category_id,
          data.category_sqlite_id,
          data.company_id,
          data.name,
          data.price,
          data.description,
          data.SKU,
          data.image,
          data.has_variant,
          data.stock_type,
          data.stock_quantity,
          data.available,
          data.graphic_type,
          data.color,
          data.daily_limit,
          data.daily_limit_amount,
          data.sync_status,
          data.created_at,
          data.updated_at,
          data.soft_delete
        ]);
    return data.copy(product_sqlite_id: await id);
  }

/*
  add product to sqlite
*/
  Future<Product> insertSyncProduct(Product data) async {
    final db = await instance.database;
    final id = db.rawInsert(
        'INSERT INTO $tableProduct(product_id, category_id, company_id, name, price, description, SKU, image, has_variant, stock_type, stock_quantity, available, graphic_type, color, daily_limit, daily_limit_amount, sync_status, created_at, updated_at, soft_delete) VALUES(?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
        [
          data.product_id,
          data.category_id,
          data.company_id,
          data.name,
          data.price,
          data.description,
          data.SKU,
          data.image,
          data.has_variant,
          data.stock_type,
          data.stock_quantity,
          data.available,
          data.graphic_type,
          data.color,
          data.daily_limit,
          data.daily_limit_amount,
          data.sync_status,
          data.created_at,
          data.updated_at,
          data.soft_delete
        ]);
    return data.copy(product_sqlite_id: await id);
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
  add modifier link product to sqlite (from cloud)
*/
  Future<ModifierLinkProduct> insertModifierLinkProduct(ModifierLinkProduct data) async {
    final db = await instance.database;
    final id = db.rawInsert(
        'INSERT INTO $tableModifierLinkProduct(modifier_link_product_id, mod_group_id, product_id, product_sqlite_id, sync_status, created_at, updated_at, soft_delete) VALUES(?, ?, ?, ?, ?, ?, ?, ?)',
        [
          data.modifier_link_product_id,
          data.mod_group_id,
          data.product_id,
          data.product_sqlite_id,
          data.sync_status,
          data.created_at,
          data.updated_at,
          data.soft_delete
        ]);
    return data.copy(modifier_link_product_id: await id);
  }

/*
  add modifier link product to sqlite
*/
  Future<ModifierLinkProduct> insertSyncModifierLinkProduct(ModifierLinkProduct data) async {
    final db = await instance.database;
    final id = db.rawInsert(
        'INSERT INTO $tableModifierLinkProduct(modifier_link_product_id, mod_group_id, product_id, product_sqlite_id, sync_status, created_at, updated_at, soft_delete) VALUES(?, ?, ?, ?, ?, ?, ?, ?)',
        [
          data.modifier_link_product_id,
          data.mod_group_id,
          data.product_id,
          data.product_sqlite_id,
          data.sync_status,
          data.created_at,
          data.updated_at,
          data.soft_delete
        ]);
    return data.copy(modifier_link_product_id: await id);
  }

  /*
  add variant group to sqlite (from cloud)
*/
  Future<VariantGroup> insertVariantGroup(VariantGroup data) async {
    final db = await instance.database;
    final id = db.rawInsert(
        'INSERT INTO $tableVariantGroup(variant_group_id, product_id, product_sqlite_id, name, sync_status, created_at, updated_at, soft_delete) VALUES(?, ?, ?, ?, ?, ?, ?, ?)',
        [
          data.variant_group_id,
          data.product_id,
          data.product_sqlite_id,
          data.name,
          data.sync_status,
          data.created_at,
          data.updated_at,
          data.soft_delete
        ]);
    return data.copy(variant_group_sqlite_id: await id);
  }

/*
  add variant group to sqlite
*/
  Future<VariantGroup> insertSyncVariantGroup(VariantGroup data) async {
    final db = await instance.database;
    final id = db.rawInsert(
        'INSERT INTO $tableVariantGroup(variant_group_id, product_id, product_sqlite_id, name, sync_status, created_at, updated_at, soft_delete) VALUES(?, ?, ?, ?, ?, ?, ?, ?)',
        [
          data.variant_group_id,
          data.product_id,
          data.product_sqlite_id,
          data.name,
          data.sync_status,
          data.created_at,
          data.updated_at,
          data.soft_delete
        ]);
    return data.copy(variant_group_sqlite_id: await id);
  }

  /*
  add variant item to sqlite (from cloud)
*/
  Future<VariantItem> insertVariantItem(VariantItem data) async {
    final db = await instance.database;
    final id = db.rawInsert(
        'INSERT INTO $tableVariantItem(variant_item_id, variant_group_id, variant_group_sqlite_id, name, sync_status, created_at, updated_at, soft_delete) VALUES(?, ?, ?, ?, ?, ?, ?, ?)',
        [
          data.variant_item_id,
          data.variant_group_id,
          data.variant_group_sqlite_id,
          data.name,
          data.sync_status,
          data.created_at,
          data.updated_at,
          data.soft_delete
        ]);
    return data.copy(variant_item_sqlite_id: await id);
  }

/*
  add variant item to sqlite
*/
  Future<VariantItem> insertSyncVariantItem(VariantItem data) async {
    final db = await instance.database;
    final id = db.rawInsert(
        'INSERT INTO $tableVariantItem(variant_item_id, variant_group_id, name, sync_status, created_at, updated_at, soft_delete) VALUES(?, ?, ?, ?, ?, ?, ?)',
        [
          data.variant_item_id,
          data.variant_group_id,
          data.name,
          data.sync_status,
          data.created_at,
          data.updated_at,
          data.soft_delete
        ]);
    return data.copy(variant_item_sqlite_id: await id);
  }

  /*
  add product variant to sqlite (from cloud)
*/
  Future<ProductVariant> insertProductVariant(ProductVariant data) async {
    final db = await instance.database;
    final id = db.rawInsert(
        'INSERT INTO $tableProductVariant(product_variant_id, product_id, variant_name, SKU, price, stock_type, daily_limit, daily_limit_amount, stock_quantity, sync_status, created_at, updated_at, soft_delete) VALUES(?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
        [
          data.product_variant_id,
          data.product_id,
          data.variant_name,
          data.SKU,
          data.price,
          data.stock_type,
          data.daily_limit,
          data.daily_limit_amount,
          data.stock_quantity,
          2,
          data.created_at,
          data.updated_at,
          data.soft_delete
        ]);
    return data.copy(product_variant_sqlite_id: await id);
  }

/*
  add product variant to sqlite
*/
  Future<ProductVariant> insertSyncProductVariant(ProductVariant data) async {
    final db = await instance.database;
    final id = db.rawInsert(
        'INSERT INTO $tableProductVariant(product_variant_id, product_id, variant_name, SKU, price, stock_type, daily_limit, daily_limit_amount, stock_quantity, sync_status, created_at, updated_at, soft_delete) VALUES(?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
        [
          data.product_variant_id,
          data.product_id,
          data.variant_name,
          data.SKU,
          data.price,
          data.stock_type,
          data.daily_limit,
          data.daily_limit_amount,
          data.stock_quantity,
          data.sync_status  ,
          data.created_at,
          data.updated_at,
          data.soft_delete
        ]);
    return data.copy(product_variant_sqlite_id: await id);
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
  add table use into local
*/
  Future<TableUse> insertSqliteTableUse(TableUse data) async {
    final db = await instance.database;
    final id = await db.insert(tableTableUse!, data.toJson());
    return data.copy(table_use_sqlite_id: id);
  }

/*
  add table use detail into local
*/
  Future<TableUseDetail> insertSqliteTableUseDetail(TableUseDetail data) async {
    final db = await instance.database;
    final id = await db.insert(tableTableUseDetail!, data.toJson());
    return data.copy(table_use_detail_sqlite_id: id);
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
  add order cache data into sqlite
*/
  Future<OrderCache> insertSqLiteOrderCache(OrderCache data) async {
    final db = await instance.database;
    final id = await db.insert(tableOrderCache!, data.toJson());
    return data.copy(order_cache_sqlite_id: id);
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
  add order detail data into sqlite
*/
  Future<OrderDetail> insertSqliteOrderDetail(OrderDetail data) async {
    final db = await instance.database;
    final id = await db.insert(tableOrderDetail!, data.toJson());
    return data.copy(order_detail_sqlite_id: id);
  }

/*
  add order modifier data into sqlite(cloud)
*/
  Future<OrderModifierDetail> insertOrderModifierDetail(
      OrderModifierDetail data) async {
    final db = await instance.database;
    final id = await db.insert(tableOrderModifierDetail!, data.toJson());
    return data.copy(order_modifier_detail_id: id);
  }

/*
  add order modifier data into sqlite
*/
  Future<OrderModifierDetail> insertSqliteOrderModifierDetail(
      OrderModifierDetail data) async {
    final db = await instance.database;
    final id = await db.insert(tableOrderModifierDetail!, data.toJson());
    return data.copy(order_modifier_detail_sqlite_id: id);
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
  add printer into local db
*/
  Future<Printer> insertSqlitePrinter(Printer data) async {
    final db = await instance.database;
    final id = await db.insert(tablePrinter!, data.toJson());
    return data.copy(printer_sqlite_id: id);
  }

/*
  add printer link category into local db
*/
  Future<PrinterLinkCategory> insertSqlitePrinterLinkCategory(
      PrinterLinkCategory data) async {
    final db = await instance.database;
    final id = await db.insert(tablePrinterLinkCategory!, data.toJson());
    return data.copy(printer_link_category_sqlite_id: id);
  }

/*
  add receipt data into local db
*/
  Future<Receipt> insertSqliteReceipt(Receipt data) async {
    final db = await instance.database;
    final id = await db.insert(tableReceipt!, data.toJson());
    return data.copy(receipt_sqlite_id: id);
  }

/*
  add cash record data into local db
*/
  Future<CashRecord> insertSqliteCashRecord(CashRecord data) async {
    final db = await instance.database;
    final id = await db.insert(tableCashRecord!, data.toJson());
    return data.copy(cash_record_sqlite_id: id);
  }

/*
  crate order into local(from local)
*/
 Future<Order>insertSqliteOrder(Order data) async{
   final db = await instance.database;
   final id = await db.insert(tableOrder!, data.toJson());
   return data.copy(order_sqlite_id: id);
 }

/*
  add order tax detail
*/
  Future<OrderTaxDetail>insertSqliteOrderTaxDetail(OrderTaxDetail data) async {
    final db = await instance.database;
    final id = await db.insert(tableOrderTaxDetail!, data.toJson());
    return data.copy(order_tax_detail_sqlite_id: id);
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

  Future<Product?> readProductSqliteID (String product_id) async {
    final db = await instance.database;
    final maps = await db.rawQuery(
        'SELECT * FROM $tableProduct WHERE soft_delete = ? AND product_id = ?',
        ['', product_id]);
    if (maps.isNotEmpty) {
      return Product.fromJson(maps.first);
    }
  }

  Future<VariantGroup?> readVariantGroupSqliteID (String variant_group_id) async {
    final db = await instance.database;
    final maps = await db.rawQuery(
        'SELECT * FROM $tableVariantGroup WHERE soft_delete = ? AND variant_group_id = ?',
        ['', variant_group_id]);
    if (maps.isNotEmpty) {
      return VariantGroup.fromJson(maps.first);
    }
  }

  Future<Categories?> readCategorySqliteID (String category_id) async {
    final db = await instance.database;
    final maps = await db.rawQuery(
        'SELECT * FROM $tableCategories WHERE soft_delete = ? AND category_id = ?',
        ['', category_id]);
    if (maps.isNotEmpty) {
      return Categories.fromJson(maps.first);
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
  Future<List<VariantGroup>> readVariantGroup(String product_sqlite_id) async {
    final db = await instance.database;
    final result = await db.rawQuery(
        'SELECT * FROM $tableVariantGroup WHERE soft_delete = ? AND product_sqlite_id = ?',
        ['', product_sqlite_id]);

    return result.map((json) => VariantGroup.fromJson(json)).toList();
  }

  /*
  read product variant
*/
  Future<List<ProductVariant>> readProductVariant(String product_id) async {
    final db = await instance.database;
    final result = await db.rawQuery(
        'SELECT * FROM $tableProductVariant WHERE soft_delete = ? AND product_id = ?',
        ['', product_id]);

    return result.map((json) => ProductVariant.fromJson(json)).toList();
  }

/*
  read product variant detail
*/
  Future<List<ProductVariantDetail>> readProductVariantDetail(
      String product_variant_id) async {
    final db = await instance.database;
    final result = await db.rawQuery(
        'SELECT * FROM $tableProductVariantDetail WHERE soft_delete = ? AND product_variant_id = ?',
        ['', product_variant_id]);

    return result.map((json) => ProductVariantDetail.fromJson(json)).toList();
  }

/*
  read product variant item
*/
  Future<List<VariantItem>> readProductVariantItemByVariantID(
      String variant_item_id) async {
    final db = await instance.database;
    final result = await db.rawQuery(
        'SELECT * FROM $tableVariantItem WHERE soft_delete = ? AND variant_item_id = ?',
        ['', variant_item_id]);
    return result.map((json) => VariantItem.fromJson(json)).toList();
  }

  /*
  read variant group
*/
  Future<ProductVariant?> readProductVariantForUpdate(
      String variant_name, String product_id) async {
    final db = await instance.database;
    final maps = await db.rawQuery(
        'SELECT * FROM $tableProductVariant WHERE soft_delete = ? AND variant_name = ? AND product_id = ?',
        ['', variant_name, product_id]);
    if (maps.isNotEmpty) {
      return ProductVariant.fromJson(maps.first);
    }
  }

  /*
  read variant group for update
*/
  Future<VariantGroup?> readSpecificVariantGroup(
      String name, String product_sqlite_id) async {
    final db = await instance.database;
    final maps = await db.rawQuery(
        'SELECT * FROM $tableVariantGroup WHERE soft_delete = ? AND name = ? AND product_sqlite_id = ?',
        ['', name, product_sqlite_id]);
    if (maps.isNotEmpty) {
      return VariantGroup.fromJson(maps.first);
    }
  }

  /*
  read variant item for group
*/
  Future<List<VariantItem>> readVariantItemForGroup(
      String variant_group_id) async {
    final db = await instance.database;
    final result = await db.rawQuery(
        'SELECT * FROM $tableVariantItem WHERE soft_delete = ? AND variant_group_id = ?',
        ['', variant_group_id]);

    return result.map((json) => VariantItem.fromJson(json)).toList();
  }

  /*
  read branch link product
*/
  Future<List<BranchLinkProduct>> readBranchLinkProduct(
      String branch_id, String product_id) async {
    final db = await instance.database;
    final result = await db.rawQuery(
        'SELECT a.*, (SELECT variant_name FROM $tableProductVariant WHERE soft_delete = ? AND product_variant_id = a.product_variant_id) as variant_name FROM $tableBranchLinkProduct AS a WHERE a.soft_delete = ? AND a.branch_id = ? AND a.product_id = ?',
        ['', '', branch_id, product_id]);

    return result.map((json) => BranchLinkProduct.fromJson(json)).toList();
  }

  /*
  read modifier link product
*/
  Future<List<ModifierLinkProduct>> readModifierLinkProduct(
      String mod_group_id, String product_sqlite_id) async {
    final db = await instance.database;
    final result = await db.rawQuery(
        'SELECT * FROM $tableModifierLinkProduct WHERE soft_delete = ? AND mod_group_id = ? AND product_sqlite_id = ?',
        ['', mod_group_id, product_sqlite_id]);

    return result.map((json) => ModifierLinkProduct.fromJson(json)).toList();
  }

/*
  read branch link specific product
*/
  Future<List<BranchLinkProduct>> readBranchLinkSpecificProduct(
      String branch_id, String product_id) async {
    final db = await instance.database;
    final result = await db.rawQuery(
        'SELECT * FROM $tableBranchLinkProduct WHERE soft_delete = ? AND branch_id = ? AND product_id = ?',
        ['', branch_id, product_id]);

    return result.map((json) => BranchLinkProduct.fromJson(json)).toList();
  }

/*
  read product variant by name
*/
  Future<List<ProductVariant>> readSpecificProductVariant(
      String product_id, String variant_name) async {
    final db = await instance.database;
    final result = await db.rawQuery(
        'SELECT * FROM $tableProductVariant WHERE soft_delete = ? AND product_id = ? AND variant_name = ?',
        ['', product_id, variant_name]);

    return result.map((json) => ProductVariant.fromJson(json)).toList();
  }

  /*
  read product variant by branch link product id
*/
  Future<ProductVariant?> readProductVariantSpecial(
      String branch_link_product_sqlite_id) async {
    final db = await instance.database;
    final maps = await db.rawQuery(
        'SELECT a.* FROM $tableProductVariant as a JOIN $tableBranchLinkProduct as b ON a.product_variant_id = b.product_variant_id WHERE a.soft_delete = ? AND b.soft_delete = ? AND b.branch_link_product_sqlite_id = ?',
        ['', '', branch_link_product_sqlite_id]);
    if (maps.isNotEmpty) {
      return ProductVariant.fromJson(maps.first);
    } else {
      return ProductVariant();
    }
  }

/*
  read specific branch link product item
*/
  Future<List<BranchLinkProduct>> readSpecificBranchLinkProduct(
      String branch_link_product_sqlite_id) async {
    final db = await instance.database;
    final result = await db.rawQuery(
        'SELECT a.*, b.name FROM $tableBranchLinkProduct AS a JOIN $tableProduct AS b ON a.product_id = b.product_id WHERE a.soft_delete = ? AND b.soft_delete = ? AND a.branch_link_product_sqlite_id = ?',
        ['', '', branch_link_product_sqlite_id]);

    return result.map((json) => BranchLinkProduct.fromJson(json)).toList();
  }

/*
  read branch product variant
*/
  Future<List<BranchLinkProduct>> readBranchLinkProductVariant(
      String branch_link_product_sqlite_id) async {
    final db = await instance.database;
    final result = await db.rawQuery(
        'SELECT a.*, b.variant_name FROM $tableBranchLinkProduct AS a JOIN $tableProductVariant AS b ON a.product_variant_id = b.product_variant_id WHERE a.soft_delete = ? AND b.soft_delete = ? AND a.branch_link_product_sqlite_id = ?',
        ['', '', branch_link_product_sqlite_id]);

    return result.map((json) => BranchLinkProduct.fromJson(json)).toList();
  }

/*
  checking product variant
*/
  Future<List<BranchLinkProduct>> checkProductVariant(
      String product_variant_id, String product_id) async {
    final db = await instance.database;
    final result = await db.rawQuery(
        'SELECT * FROM $tableBranchLinkProduct WHERE soft_delete =? AND product_variant_id = ? AND product_id = ?',
        ['', product_variant_id, product_id]);

    return result.map((json) => BranchLinkProduct.fromJson(json)).toList();
  }

/*
  read branch link dining option
*/
  Future<List<BranchLinkDining>> readBranchLinkDiningOption(
      String branch_id) async {
    final db = await instance.database;
    final result = await db.rawQuery(
        'SELECT a.*, b.name FROM $tableBranchLinkDining AS a JOIN $tableDiningOption AS b ON a.dining_id = b.dining_id WHERE a.soft_delete = ? AND b.soft_delete = ? AND a.branch_id = ?',
        ['', '', branch_id]);

    return result.map((json) => BranchLinkDining.fromJson(json)).toList();
  }

/*
  read tax link dining
*/
  Future<List<TaxLinkDining>> readTaxLinkDining(int dining_id) async {
    final db = await instance.database;
    final result = await db.rawQuery(
        'SELECT a.*, b.tax_rate FROM $tableTaxLinkDining AS a JOIN $tableTax AS b ON a.tax_id = b.tax_id WHERE a.soft_delete = ? AND b.soft_delete = ? AND a.dining_id = ?',
        ['', '', dining_id]);

    return result.map((json) => TaxLinkDining.fromJson(json)).toList();
  }

/*
  check dining option
*/
  Future<List<DiningOption>> checkSelectedOption(String name) async {
    final db = await instance.database;
    final result = await db.rawQuery(
        'SELECT dining_id FROM $tableDiningOption WHERE soft_delete = ? AND name = ?',
        ['', name]);

    return result.map((json) => DiningOption.fromJson(json)).toList();
  }

/*
  get tax rate/ name
*/
  Future<List<Tax>> readTax(String branch_id, String dining_id) async {
    final db = await instance.database;
    final result = await db.rawQuery(
        'SELECT b.* FROM $tableBranchLinkTax AS a JOIN $tableTax as B ON a.tax_id = b.tax_id JOIN $tableTaxLinkDining as c ON a.tax_id = c.tax_id WHERE a.branch_id = ? AND c.dining_id = ? AND a.soft_delete = ? AND b.soft_delete = ? AND c.soft_delete = ?',
        [branch_id, dining_id, '', '', '']);

    return result.map((json) => Tax.fromJson(json)).toList();
  }

/*
  read Branch link promotion
*/
  Future<List<BranchLinkPromotion>> readBranchLinkPromotion(
      String branch_id) async {
    final db = await instance.database;
    final result = await db.rawQuery(
        'SELECT * FROM $tableBranchLinkPromotion WHERE soft_delete = ? AND branch_id = ?',
        ['', branch_id]);
    // 'SELECT a.*, b.name FROM $tableBranchLinkPromotion AS a JOIN $tablePromotion AS b ON a.promotion_id = b.promotion_id WHERE a.soft_delete = ? AND b.soft_delete = ? AND a.branch_id = ?',
    // ['', '', branch_id]);

    return result.map((json) => BranchLinkPromotion.fromJson(json)).toList();
  }

/*
  check promotion
*/
  Future<List<Promotion>> checkPromotion(String promotion_id) async {
    final db = await instance.database;
    final result = await db.rawQuery(
        'SELECT * FROM $tablePromotion WHERE soft_delete = ? AND promotion_id = ?',
        ['', promotion_id]);

    return result.map((json) => Promotion.fromJson(json)).toList();
  }

/*
  read branch link modifier price
*/
  Future<List<BranchLinkModifier>> readBranchLinkModifier(
      String branch_id, String mod_item_id) async {
    final db = await instance.database;
    final result = await db.rawQuery(
        'SELECT * FROM $tableBranchLinkModifier WHERE soft_delete = ? AND branch_id = ? AND mod_item_id = ?',
        ['', branch_id, mod_item_id]);

    return result.map((json) => BranchLinkModifier.fromJson(json)).toList();
  }

/*
  read app colors
*/
  Future<List<AppColors>> readAppColors() async {
    final db = await instance.database;
    final result = await db
        .rawQuery('SELECT * FROM $tableAppColors WHERE soft_delete = ? ', ['']);
    return result.map((json) => AppColors.fromJson(json)).toList();
  }

/*
  read all category (-)
*/
  Future<List<Categories>> readAllCategory() async {
    final db = await instance.database;
    final result = await db.rawQuery(
        'SELECT * FROM $tableCategories WHERE soft_delete = ? ', ['']);
    return result.map((json) => Categories.fromJson(json)).toList();
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
  Future<List<Product>> checkProductSKUForEdit(
      String sku, int product_id) async {
    final db = await instance.database;
    final result = await db.rawQuery(
        'SELECT * FROM $tableProduct WHERE soft_delete = ? AND SKU = ? AND product_id != ?',
        ['', sku, product_id]);
    return result.map((json) => Product.fromJson(json)).toList();
  }

/*
  search product
*/
  Future<List<Product>> searchProduct(String text) async {
    final db = await instance.database;
    final result = await db.rawQuery(
        'SELECT DISTINCT a.* FROM $tableProduct AS a JOIN $tableBranchLinkProduct AS b ON a.product_id = b.product_id WHERE a.soft_delete = ? AND b.soft_delete = ? AND (a.name LIKE ? OR a.SKU LIKE ?)',
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
  read product category
*/
  Future<List<Product>> readSpecificProductCategory(String product_id) async {
    final db = await instance.database;
    final result = await db.rawQuery(
        'SELECT * FROM $tableProduct WHERE soft_delete = ? AND product_id = ?',
        ['', product_id]);

    return result.map((json) => Product.fromJson(json)).toList();
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
  read table id by table no
*/
  Future<List<PosTable>> readSpecificTableByTableNo(
      int branchID, String number) async {
    final db = await instance.database;
    final result = await db.rawQuery(
        'SELECT * FROM $tablePosTable WHERE soft_delete = ? AND branch_id = ? AND number = ?',
        ['', branchID, number]);

    return result.map((json) => PosTable.fromJson(json)).toList();
  }

/*
  read table id by table no
*/
  Future<List<PosTable>> readSpecificTable(
      int branchID, String table_sqlite_id) async {
    final db = await instance.database;
    final result = await db.rawQuery(
        'SELECT * FROM $tablePosTable WHERE soft_delete = ? AND branch_id = ? AND table_sqlite_id = ?',
        ['', branchID, table_sqlite_id]);

    return result.map((json) => PosTable.fromJson(json)).toList();
  }

/*
  check table status
*/
  Future<List<PosTable>> checkPosTableStatus(
      int branch_id, int table_sqlite_id) async {
    final db = await instance.database;
    final result = await db.rawQuery(
        'SELECT * FROM $tablePosTable WHERE soft_delete = ? AND branch_id = ? AND table_sqlite_id = ?',
        ['', branch_id, table_sqlite_id]);

    return result.map((json) => PosTable.fromJson(json)).toList();
  }

/*
  read branch all table use id
*/
  Future<List<TableUse>> readAllTableUseId(int branch_id) async {
    final db = await instance.database;
    final result = await db.rawQuery(
        'SELECT * FROM $tableTableUse WHERE soft_delete = ? AND branch_id = ? ',
        ['', branch_id]);

    return result.map((json) => TableUse.fromJson(json)).toList();
  }

/*
  read specific use table detail based on table id
*/
  Future<List<TableUseDetail>> readSpecificTableUseDetail(
      int table_sqlite_id) async {
    final db = await instance.database;
    final result = await db.rawQuery(
        'SELECT * FROM $tableTableUseDetail WHERE soft_delete = ? AND table_sqlite_id = ?',
        ['', table_sqlite_id]);

    return result.map((json) => TableUseDetail.fromJson(json)).toList();
  }

/*
  read all occurrence table detail based on table use id
*/
  Future<List<TableUseDetail>> readAllTableUseDetail(
      String table_use_sqlite_id) async {
    final db = await instance.database;
    final result = await db.rawQuery(
        'SELECT * FROM $tableTableUseDetail WHERE soft_delete = ? AND  table_use_sqlite_id = ?',
        ['', table_use_sqlite_id]);

    return result.map((json) => TableUseDetail.fromJson(json)).toList();
  }

/*
  read all table detail based on table use id(inc deleted)
*/
  Future<List<TableUseDetail>> readAllDeletedTableUseDetail(
      String table_use_sqlite_id) async {
    final db = await instance.database;
    final result = await db.rawQuery(
        'SELECT * FROM $tableTableUseDetail WHERE table_use_sqlite_id = ?',
        [table_use_sqlite_id]);

    return result.map((json) => TableUseDetail.fromJson(json)).toList();
  }

  /*
  read latest order cache
*/
  Future<List<OrderCache>> readBranchLatestOrderCache(int branch_id) async {
    final db = await instance.database;
    final result = await db.rawQuery(
        'SELECT * FROM $tableOrderCache WHERE soft_delete = ? AND branch_id = ? ORDER BY created_at DESC LIMIT 1',
        ['', branch_id]);
    return result.map((json) => OrderCache.fromJson(json)).toList();
  }

/*
  read all order cache
*/
  Future<List<OrderCache>> readBranchOrderCache(int branch_id) async {
    final db = await instance.database;
    final result = await db.rawQuery(
        'SELECT * FROM $tableOrderCache WHERE soft_delete = ? AND branch_id = ?',
        ['', branch_id]);
    return result.map((json) => OrderCache.fromJson(json)).toList();
  }

/*
  read specific order cache
*/
  Future<List<OrderCache>> readSpecificOrderCache(String order_cache_sqlite_id) async {
    final db = await instance.database;
    final result = await db.rawQuery(
        'SELECT * FROM $tableOrderCache WHERE soft_delete = ? AND order_cache_sqlite_id = ?',
        ['', order_cache_sqlite_id]);
    return result.map((json) => OrderCache.fromJson(json)).toList();
  }

/*
  read specific order cache(deleted)
*/
  Future<List<OrderCache>> readSpecificDeletedOrderCache(int order_cache_sqlite_id) async {
    final db = await instance.database;
    final result = await db.rawQuery(
        'SELECT * FROM $tableOrderCache WHERE order_cache_sqlite_id = ?',
        [order_cache_sqlite_id]);
    return result.map((json) => OrderCache.fromJson(json)).toList();
  }

/*
  read table order cache
*/
  Future<List<OrderCache>> readTableOrderCache(
      String branch_id, String table_use_id) async {
    try {
      final db = await instance.database;
      final result = await db.rawQuery(
          'SELECT a.*, b.cardColor FROM $tableOrderCache AS a JOIN $tableTableUse AS b ON a.table_use_sqlite_id = b.table_use_sqlite_id WHERE a.soft_delete = ? AND b.soft_delete = ? AND a.branch_id = ? AND a.table_use_sqlite_id = ?',
          ['', '', branch_id, table_use_id]);
      return result.map((json) => OrderCache.fromJson(json)).toList();
    } catch (e) {
      print(e);
      return [];
    }
  }

  /*
  get all order cache except dine in
*/
  Future<List<OrderCache>> readOrderCacheNoDineIn(
      String branch_id, String company_id) async {
    try {
      final db = await instance.database;
      final result = await db.rawQuery(
          'SELECT a.order_cache_id ,a.order_detail_id, a.dining_id, a.table_id, a.order_id, a.order_by, a.total_amount, a.customer_id, a.created_at, a.updated_at, a.soft_delete FROM tb_order_cache as a JOIN tb_dining_option as b ON a.dining_id = b.dining_id WHERE a.soft_delete=? AND b.soft_delete=? AND a.branch_id = ? AND a.company_id = ? AND b.company_id = ? AND b.name != ?',
          ['', '', branch_id, company_id, company_id, 'Dine in']);

      return result.map((json) => OrderCache.fromJson(json)).toList();
    } catch (e) {
      print(e);
      return [];
    }
  }

  /*
  get order cache for different dine in option
*/
  Future<List<OrderCache>> readOrderCacheSpecial(
      String branch_id, String company_id, String name) async {
    try {
      final db = await instance.database;
      final result = await db.rawQuery(
          'SELECT a.order_cache_id ,a.order_detail_id, a.dining_id, a.table_id, a.order_id, a.order_by, a.total_amount, a.customer_id, a.created_at, a.updated_at, a.soft_delete FROM tb_order_cache as a JOIN tb_dining_option as b ON a.dining_id = b.dining_id WHERE a.soft_delete=? AND b.soft_delete=? AND a.branch_id = ? AND a.company_id = ? AND b.company_id = ? AND b.name = ?',
          ['', '', branch_id, company_id, company_id, name]);

      return result.map((json) => OrderCache.fromJson(json)).toList();
    } catch (e) {
      print(e);
      return [];
    }
  }

/*
  read order detail by order cache
*/
  Future<List<OrderDetail>> readTableOrderDetail(
      String order_cache_sqlite_id) async {
    final db = await instance.database;
    final result = await db.rawQuery(
        'SELECT a.*, b.total_amount FROM $tableOrderDetail AS a JOIN $tableOrderCache AS b ON a.order_cache_sqlite_id = b.order_cache_sqlite_id WHERE a.soft_delete = ? AND b.soft_delete = ? AND a.order_cache_sqlite_id = ?',
        ['', '', order_cache_sqlite_id]);

    return result.map((json) => OrderDetail.fromJson(json)).toList();
  }

/*
  read order detail by order cache (deleted)
*/
  Future<List<OrderDetail>> readDeletedOrderDetail(String order_cache_sqlite_id, String dateTime) async {
    final db = await instance.database;
    final result = await db.rawQuery(
        'SELECT * FROM $tableOrderDetail WHERE order_cache_sqlite_id = ? AND soft_delete = ?',
        [order_cache_sqlite_id, dateTime]);

    return result.map((json) => OrderDetail.fromJson(json)).toList();
  }


//   /*
//   read order detail
// */
//   Future<List<OrderDetail>> readTableOrderDetailOne(String order_cache_id) async {
//     final db = await instance.database;
//     final result = await db.rawQuery(
//         'SELECT * FROM $tableOrderDetail WHERE soft_delete = ? AND order_cache_id = ?',
//         ['', order_cache_id]);
//
//     return result.map((json) => OrderDetail.fromJson(json)).toList();
//   }

/*
  read order mod detail
*/
  Future<List<OrderModifierDetail>> readOrderModifierDetail(
      String order_detail_id) async {
    final db = await instance.database;
    final result = await db.rawQuery(
        'SELECT a.*, b.name FROM $tableOrderModifierDetail AS a JOIN $tableModifierItem AS b ON a.mod_item_id = b.mod_item_id WHERE a.soft_delete = ? AND b.soft_delete = ? AND a.order_detail_id = ?',
        ['', '', order_detail_id]);

    return result.map((json) => OrderModifierDetail.fromJson(json)).toList();
  }

/*
  read order mod detail
*/
  Future<OrderModifierDetail?> readOrderModifierDetailOne(
      String order_detail_id) async {
    final db = await instance.database;
    final maps = await db.rawQuery(
        'SELECT a.*, b.name FROM $tableOrderModifierDetail AS a JOIN $tableModifierItem AS b ON a.mod_item_id = b.mod_item_id WHERE a.soft_delete = ? AND b.soft_delete = ? AND a.order_detail_id = ?',
        ['', '', order_detail_id]);
    if (maps.isNotEmpty) {
      return OrderModifierDetail.fromJson(maps.first);
    } else {
      return OrderModifierDetail();
    }
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
  read all the dining option for company
*/
  Future<List<DiningOption>> readAllDiningOption(String company_id) async {
    final db = await instance.database;
    final result = await db.rawQuery(
        'SELECT * FROM $tableDiningOption WHERE soft_delete = ? AND company_id = ?',
        ['', company_id]);
    return result.map((json) => DiningOption.fromJson(json)).toList();
  }

/*
  read branch All printer
*/
  Future<List<Printer>> readAllBranchPrinter(int branch_id) async {
    final db = await instance.database;
    final result = await db.rawQuery(
        'SELECT * FROM $tablePrinter WHERE soft_delete = ? AND branch_id = ?',
        ['', branch_id]);
    return result.map((json) => Printer.fromJson(json)).toList();
  }

/*
  read printer link category
*/
  Future<List<PrinterLinkCategory>> readPrinterLinkCategory(
      int printer_sqlite_id) async {
    final db = await instance.database;
    final result = await db.rawQuery(
        'SELECT * FROM $tablePrinterLinkCategory WHERE soft_delete = ? AND printer_sqlite_id = ?',
        ['', printer_sqlite_id]);
    return result.map((json) => PrinterLinkCategory.fromJson(json)).toList();
  }

/*
  read specific category (category id)
*/
  Future<List<Categories>> readSpecificCategoryById(String category_sqlite_id) async {
    final db = await instance.database;
    final result = await db.rawQuery(
        'SELECT * FROM $tableCategories WHERE soft_delete = ? AND category_sqlite_id = ?',
        ['', category_sqlite_id]);
    return result.map((json) => Categories.fromJson(json)).toList();
  }

/*
  read all receipt layout
*/
  Future<List<Receipt>> readAllReceipt() async {
    final db = await instance.database;
    final result = await db
        .rawQuery('SELECT * FROM $tableReceipt WHERE soft_delete = ? ', ['']);
    return result.map((json) => Receipt.fromJson(json)).toList();
  }

/*
  read branch cash record
*/
  Future<List<CashRecord>> readBranchCashRecord(String branch_id) async {
    final db = await instance.database;
    final result = await db.rawQuery(
        'SELECT a.*, b.name FROM $tableCashRecord AS a JOIN $tableUser AS b ON a.user_id = b.user_id WHERE a.soft_delete = ? AND a.settlement_date = ? AND a.branch_id = ? AND b.soft_delete = ?',
        ['', '', branch_id, '']);
    return result.map((json) => CashRecord.fromJson(json)).toList();
  }

/*
  read all branch settlement cash record
*/
  Future<List<CashRecord>> readAllBranchSettlementCashRecord(String branch_id) async {
    final db = await instance.database;
    final result = await db.rawQuery(
        'SELECT a.*, b.name FROM $tableCashRecord AS a JOIN $tableUser AS b ON a.user_id = b.user_id WHERE a.soft_delete = ? AND a.settlement_date != ? AND a.branch_id = ? AND b.soft_delete = ? GROUP BY a.settlement_date ORDER BY a.settlement_date DESC',
        ['', '', branch_id, '']);
    return result.map((json) => CashRecord.fromJson(json)).toList();
  }

/*
  read specific settlement cash record
*/
  Future<List<CashRecord>> readSpecificSettlementCashRecord(String branch_id, String dateTime) async {
    final db = await instance.database;
    final result = await db.rawQuery(
        'SELECT a.*, b.name FROM $tableCashRecord AS a JOIN $tableUser AS b ON a.user_id = b.user_id WHERE a.soft_delete = ? AND a.settlement_date = ? AND a.branch_id = ? AND b.soft_delete = ?',
        ['', dateTime, branch_id, '']);
    return result.map((json) => CashRecord.fromJson(json)).toList();
  }

/*
  read all payment link company
*/
  Future<List<PaymentLinkCompany>> readAllPaymentLinkCompany(String company_id) async {
    final db = await instance.database;
    final result = await db.rawQuery(
        'SELECT * FROM $tablePaymentLinkCompany WHERE soft_delete = ? AND company_id = ?',
        ['', company_id]);
    return result.map((json) => PaymentLinkCompany.fromJson(json)).toList();
  }

/*
  read last owner cash record
  'SELECT * FROM $tableOrderCache WHERE soft_delete = ? AND branch_id = ? ORDER BY created_at DESC LIMIT 1',
*/
  Future<CashRecord?> readLastCashRecord(String branch_id) async {
    final db = await instance.database;
    final maps = await db.rawQuery(
        'SELECT * FROM $tableCashRecord WHERE soft_delete = ? AND branch_id = ? ORDER BY cash_record_sqlite_id DESC LIMIT 1',
        ['', branch_id]);
    if (maps.isNotEmpty) {
      return CashRecord.fromJson(maps.first);
    }

  }
/*
  read latest specific cash record
*/
  Future<List<CashRecord>> readSpecificLatestSettlementCashRecord(String branch_id) async {
    final db = await instance.database;
    final result = await db.rawQuery(
      'SELECT * FROM $tableCashRecord WHERE soft_delete = ? AND branch_id = ? AND type = ? ORDER BY settlement_date DESC LIMIT 1',
        ['', branch_id, 0]);
    return result.map((json) => CashRecord.fromJson(json)).toList();
  }

/*
  read all payment method
*/
  Future<List<PaymentLinkCompany>> readPaymentMethods() async {
    final db = await instance.database;
    final result = await db.rawQuery(
        'SELECT * FROM $tablePaymentLinkCompany WHERE soft_delete = ? ',
        ['']);
    return result.map((json) => PaymentLinkCompany.fromJson(json)).toList();
  }


/*
  ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
*/
  /*
  update sync variant group
*/
  Future<int> updateSyncVariantItem(VariantItem data) async {
    final db = await instance.database;
    return await db.rawUpdate(
        'UPDATE $tableVariantItem SET variant_item_id = ?, sync_status = ?, updated_at = ? WHERE variant_item_sqlite_id = ?',
        [
          data.variant_item_id,
          data.sync_status,
          data.updated_at,
          data.variant_item_sqlite_id
        ]);
  }


  /*
  update sync variant group
*/
  Future<int> updateSyncVariantGroup(VariantGroup data) async {
    final db = await instance.database;
    return await db.rawUpdate(
        'UPDATE $tableVariantGroup SET variant_group_id = ?, sync_status = ?, updated_at = ? WHERE variant_group_sqlite_id = ?',
        [
          data.variant_group_id,
          data.sync_status,
          data.updated_at,
          data.variant_group_sqlite_id
        ]);
  }

  /*
  update sync modifier link product
*/
  Future<int> updateSyncModifierLinkProduct(ModifierLinkProduct data) async {
    final db = await instance.database;
    return await db.rawUpdate(
        'UPDATE $tableModifierLinkProduct SET modifier_link_product_id = ?, sync_status = ?, updated_at = ? WHERE modifier_link_product_sqlite_id = ?',
        [
          data.modifier_link_product_id,
          data.sync_status,
          data.updated_at,
          data.modifier_link_product_sqlite_id
        ]);
  }

  /*
  update sync modifier link product (update)
*/
  Future<int> updateSyncModifierLinkProductForUpdate(ModifierLinkProduct data) async {
    final db = await instance.database;
    return await db.rawUpdate(
        'UPDATE $tableModifierLinkProduct SET sync_status = ?, updated_at = ? WHERE product_sqlite_id = ?',
        [
          data.sync_status,
          data.updated_at,
          data.product_sqlite_id
        ]);
  }

  /*
  update sync category
*/
  Future<int> updateSyncCategory(Categories data) async {
    final db = await instance.database;
    return await db.rawUpdate(
        'UPDATE $tableCategories SET category_id = ?, sync_status = ?, updated_at = ? WHERE category_sqlite_id = ?',
        [
          data.category_id,
          data.sync_status,
          data.updated_at,
          data.category_sqlite_id
        ]);
  }

/*
  update category
*/
  Future<int> updateCategory(Categories data) async {
    final db = await instance.database;
    return await db.rawUpdate(
        'UPDATE $tableCategories SET name = ?, color = ?, sync_status = ?, updated_at = ? WHERE category_sqlite_id = ?',
        [
          data.name,
          data.color,
          data.sync_status,
          data.updated_at,
          data.category_sqlite_id
        ]);
  }

/*
  update sync product
*/
  Future<int> updateSyncProduct(Product data) async {
    final db = await instance.database;
    return await db.rawUpdate(
        'UPDATE $tableProduct SET product_id = ?, sync_status = ?, updated_at = ? WHERE product_sqlite_id = ?',
        [
          data.product_id,
          data.sync_status,
          data.updated_at,
          data.product_sqlite_id
        ]);
  }
  /*
  update product
*/
  Future<int> updateProduct(Product data) async {
    final db = await instance.database;
    return await db.rawUpdate(
        'UPDATE $tableProduct SET category_sqlite_id = ?, category_id = ?, name = ?, price = ?, description = ?, SKU = ?, image = ?, has_variant = ?, stock_type = ?, stock_quantity = ?, available = ?, graphic_type = ?, color = ?, daily_limit_amount = ?, daily_limit = ?, sync_status = ?,  updated_at = ? WHERE product_sqlite_id = ?',
        [
          data.category_sqlite_id,
          data.category_id,
          data.name,
          data.price,
          data.description,
          data.SKU,
          data.image,
          data.has_variant,
          data.stock_type,
          data.stock_quantity,
          data.available,
          data.graphic_type,
          data.color,
          data.daily_limit_amount,
          data.daily_limit,
          data.sync_status,
          data.updated_at,
          data.product_sqlite_id,
        ]);
  }

/*
  update App color
*/
  Future<int> updateAppColor(AppColors data) async {
    final db = await instance.database;
    return await db.rawUpdate(
        'UPDATE $tableAppColors SET background_color = ?, button_color = ?, icon_color = ?, updated_at = ? WHERE app_color_sqlite_id = ?',
        [
          data.background_color,
          data.button_color,
          data.icon_color,
          data.updated_at,
          data.app_color_sqlite_id
        ]);
  }

  /*
  update sync pos table
*/
  Future<int> updateSyncPosTable(PosTable data) async {
    final db = await instance.database;
    return await db.rawUpdate(
        'UPDATE $tablePosTable SET table_id = ?, sync_status = ?, updated_at = ? WHERE table_sqlite_id = ?',
        [
          data.table_id,
          data.sync_status,
          data.updated_at,
          data.table_sqlite_id
        ]);
  }

/*
  update Pos Table
*/
  Future<int> updatePosTable(PosTable data) async {
    final db = await instance.database;
    return await db.rawUpdate(
        'UPDATE $tablePosTable SET number = ?, seats = ?, sync_status = ?, updated_at = ? WHERE table_sqlite_id = ?',
        [
          data.number,
          data.seats,
          data.sync_status,
          data.updated_at,
          data.table_sqlite_id
        ]);
  }

/*
  update Pos Table status
*/
  Future<int> updatePosTableStatus(PosTable data) async {
    final db = await instance.database;
    return await db.rawUpdate(
        'UPDATE $tablePosTable SET status = ?, updated_at = ? WHERE table_sqlite_id = ?',
        [data.status, data.updated_at, data.table_sqlite_id]);
  }

/*
  update table use detail
*/
  Future<int> updateTableUseDetail(
      int table_sqlite_id, TableUseDetail data) async {
    final db = await instance.database;
    return await db.rawUpdate(
        'UPDATE $tableTableUseDetail SET table_sqlite_id = ?, updated_at = ? WHERE table_sqlite_id = ?',
        [data.table_sqlite_id, data.updated_at, table_sqlite_id]);
  }

/*
  update order cache
*/
  Future<int> updateOrderCacheTableUseId(
      String table_use_sqlite_id, OrderCache data) async {
    final db = await instance.database;
    return await db.rawUpdate(
        'UPDATE $tableOrderCache SET table_use_sqlite_id = ?, updated_at = ? WHERE table_use_sqlite_id = ?',
        [data.table_use_sqlite_id, data.updated_at, table_use_sqlite_id]);
  }

/*
  update printer
*/
  Future<int> updatePrinter(Printer data) async {
    final db = await instance.database;
    return await db.rawUpdate(
        'UPDATE $tablePrinter SET printerLabel = ?, paper_size = ?, type = ?, value = ?, updated_at = ? WHERE printer_sqlite_id = ?',
        [
          data.printerLabel,
          data.paper_size,
          data.type,
          data.value,
          data.updated_at,
          data.printer_sqlite_id
        ]);
  }

/*
  update receipt status
*/
  Future<int> updateReceiptStatus(Receipt data) async {
    final db = await instance.database;
    return await db.rawUpdate(
        'UPDATE $tableReceipt SET status = ?, sync_status = ?, updated_at = ? WHERE receipt_sqlite_id = ?',
        [
          data.status,
          data.sync_status,
          data.updated_at,
          data.receipt_sqlite_id
        ]);
  }

/*
  update cash record settlement
*/
  Future<int> updateCashRecord(CashRecord data) async {
    final db = await instance.database;
    return await db.rawUpdate(
        'UPDATE $tableCashRecord SET settlement_date = ?, sync_status = ?, updated_at = ? WHERE cash_record_sqlite_id = ?',
        [
          data.settlement_date,
          data.sync_status,
          data.updated_at,
          data.cash_record_sqlite_id
        ]);
  }

/*
  update order cache order id
*/
 Future<int> updateOrderCacheOrderId(OrderCache data) async {
   final db = await instance.database;
   return await db.rawUpdate(
     'UPDATE $tableOrderCache SET order_id = ?, sync_status = ?, updated_at = ? WHERE order_cache_sqlite_id = ?',
     [data.order_id, data.sync_status, data.updated_at, data.order_cache_sqlite_id]
   );
 }



/*
  ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
*/

  /*
  soft delete branch link product
*/
  Future<int> updateBranchLinkProduct(BranchLinkProduct data) async {
    final db = await instance.database;
    return await db.rawUpdate(
        'UPDATE $tableBranchLinkProduct SET updated_at = ?,daily_limit = ?, daily_limit_amount = ?, stock_type = ?, stock_quantity = ?, price = ? WHERE branch_id = ? AND product_id = ?',
        [
          data.updated_at,
          data.daily_limit,
          data.daily_limit_amount,
          data.stock_type,
          data.stock_quantity,
          data.price,
          data.branch_id,
          data.product_id
        ]);
  }

/*
  soft delete branch link product
*/
  Future<int> updateBranchLinkProductForVariant(BranchLinkProduct data) async {
    final db = await instance.database;
    return await db.rawUpdate(
        'UPDATE $tableBranchLinkProduct SET updated_at = ?,daily_limit = ?, daily_limit_amount = ?, stock_type = ?, stock_quantity = ?, price = ? WHERE branch_id = ? AND product_id = ? AND product_variant_id = ?',
        [
          data.updated_at,
          data.daily_limit,
          data.daily_limit_amount,
          data.stock_type,
          data.stock_quantity,
          data.price,
          data.branch_id,
          data.product_id,
          data.product_variant_id
        ]);
  }

/*
  soft delete category
*/
  Future<int> deleteCategory(Categories data) async {
    final db = await instance.database;
    return await db.rawUpdate(
        'UPDATE $tableCategories SET soft_delete = ?, sync_status = ? WHERE  category_sqlite_id = ?',
        [data.soft_delete, data.sync_status, data.category_sqlite_id]);
  }

  /*
  soft delete product
*/
  Future<int> deleteProduct(Product data) async {
    final db = await instance.database;
    return await db.rawUpdate(
        'UPDATE $tableProduct SET soft_delete = ?, sync_status = ? WHERE soft_delete = ? AND product_id = ?',
        [
          data.soft_delete,
          data.sync_status,
          '',
          data.product_id,
        ]);
  }

  /*
  soft delete modifier link product
*/
  Future<int> deleteModifierLinkProduct(ModifierLinkProduct data) async {
    final db = await instance.database;
    return await db.rawUpdate(
        'UPDATE $tableModifierLinkProduct SET soft_delete = ?, sync_status = ? WHERE soft_delete = ? AND product_sqlite_id = ?',
        [data.soft_delete, data.sync_status, '', data.product_sqlite_id]);
  }

  /*
  soft delete variant group
*/
  Future<int> deleteVariantGroup(VariantGroup data) async {
    final db = await instance.database;
    return await db.rawUpdate(
        'UPDATE $tableVariantGroup SET soft_delete = ? WHERE product_sqlite_id = ? AND variant_group_sqlite_id = ?',
        [data.soft_delete, data.product_sqlite_id, data.variant_group_sqlite_id]);
  }

  /*
  soft delete variant group
*/
  Future<int> deleteAllVariantGroup(VariantGroup data) async {
    final db = await instance.database;
    return await db.rawUpdate(
        'UPDATE $tableVariantGroup SET soft_delete = ? WHERE product_id = ?',
        [data.soft_delete, data.product_id]);
  }

  /*
  soft delete variant item
*/
  Future<int> deleteAllVariantitem(VariantItem data) async {
    final db = await instance.database;
    return await db.rawUpdate(
        'UPDATE $tableVariantItem SET soft_delete = ? WHERE variant_group_id = ?',
        [data.soft_delete, data.variant_group_id]);
  }

  /*
  soft delete product variant
*/
  Future<int> deleteAllProductVariant(ProductVariant data) async {
    final db = await instance.database;
    return await db.rawUpdate(
        'UPDATE $tableProductVariant SET soft_delete = ? WHERE product_id = ?',
        [data.soft_delete, data.product_id]);
  }

  /*
  soft delete product variant detail
*/
  Future<int> deleteAllProductVariantDetail(ProductVariantDetail data) async {
    final db = await instance.database;
    return await db.rawUpdate(
        'UPDATE $tableProductVariantDetail SET soft_delete = ? WHERE product_variant_id = ?',
        [data.soft_delete, data.product_variant_id]);
  }

  /*
  soft delete product variant
*/
  Future<int> deleteProductVariant(ProductVariant data) async {
    final db = await instance.database;
    return await db.rawUpdate(
        'UPDATE $tableProductVariant SET soft_delete = ? WHERE product_id = ? AND product_variant_id = ?',
        [data.soft_delete, data.product_id, data.product_variant_id]);
  }

  /*
  soft delete product variant detail
*/
  Future<int> deleteProductVariantDetail(ProductVariantDetail data) async {
    final db = await instance.database;
    return await db.rawUpdate(
        'UPDATE $tableProductVariantDetail SET soft_delete = ? WHERE product_variant_id = ?',
        [data.soft_delete, data.product_variant_id]);
  }

  /*
  soft delete branch link product
*/
  Future<int> deleteBranchLinkProduct(BranchLinkProduct data) async {
    final db = await instance.database;
    return await db.rawUpdate(
        'UPDATE $tableBranchLinkProduct SET soft_delete = ? WHERE branch_id = ? AND product_id = ? AND product_variant_id = ?',
        [
          data.soft_delete,
          data.branch_id,
          data.product_id,
          data.product_variant_id
        ]);
  }

  /*
  soft delete branch link product
*/
  Future<int> deleteAllProductBranch(BranchLinkProduct data) async {
    final db = await instance.database;
    return await db.rawUpdate(
        'UPDATE $tableBranchLinkProduct SET soft_delete = ? WHERE soft_delete = ? AND product_id = ?',
        [data.soft_delete, '', data.product_id]);
  }

  /*
  soft delete variant group
*/
  Future<int> deleteVariantItem(VariantItem data) async {
    final db = await instance.database;
    return await db.rawUpdate(
        'UPDATE $tableVariantItem SET soft_delete = ? WHERE variant_group_sqlite_id = ?',
        [data.soft_delete, data.variant_group_sqlite_id]);
  }

/*
  Soft-delete Pos Table
*/
  Future<int> deletePosTable(PosTable data) async {
    final db = await instance.database;
    return await db.rawUpdate(
        'UPDATE $tablePosTable SET sync_status = ?, soft_delete = ? WHERE table_sqlite_id = ?',
        [data.sync_status, data.soft_delete, data.table_sqlite_id]);
  }

/*
  Soft-delete Order cache
*/
  Future<int> deleteOrderCache(OrderCache data) async {
    final db = await instance.database;
    return await db.rawUpdate(
        'UPDATE $tableOrderCache SET soft_delete = ?, cancel_by = ?, cancel_by_user_id = ? WHERE order_cache_sqlite_id = ?',
        [data.soft_delete, data.cancel_by, data.cancel_by_user_id, data.order_cache_sqlite_id]);
  }

/*
  Soft-delete Order detail
*/
  Future<int> deleteOrderDetail(OrderDetail data) async {
    final db = await instance.database;
    return await db.rawUpdate(
        'UPDATE $tableOrderDetail SET soft_delete = ? WHERE order_detail_sqlite_id = ?',
        [data.soft_delete, data.order_detail_sqlite_id]);
  }

  /*
  Soft-delete specific Order detail
*/
  Future<int> deleteSpecificOrderDetail(OrderDetail data) async {
    print('called');
    final db = await instance.database;
    return await db.rawUpdate(
        'UPDATE $tableOrderDetail SET soft_delete = ?, cancel_by = ?, cancel_by_user_id = ? WHERE order_cache_sqlite_id = ? AND branch_link_product_sqlite_id = ?',
        [data.soft_delete, data.cancel_by, data.cancel_by_user_id, data.order_cache_sqlite_id, data.branch_link_product_sqlite_id]);
  }

/*
  Soft-delete Order modifier detail
*/
  Future<int> deleteOrderModifierDetail(OrderModifierDetail data) async {
    final db = await instance.database;
    return await db.rawUpdate(
        'UPDATE $tableOrderModifierDetail SET soft_delete = ? WHERE order_detail_id = ?',
        [data.soft_delete, data.order_detail_id]);
  }

/*
  Soft-delete change table table use detail
*/
  Future<int> deleteTableUseDetail(TableUseDetail data) async {
    final db = await instance.database;
    return await db.rawUpdate(
        'UPDATE $tableTableUseDetail SET soft_delete = ? WHERE table_use_sqlite_id = ?',
        [data.soft_delete, data.table_use_sqlite_id]);
  }

  /*
  Soft-delete change table table use detail by table id
*/
  Future<int> deleteTableUseDetailByTableId(TableUseDetail data) async {
    final db = await instance.database;
    return await db.rawUpdate(
        'UPDATE $tableTableUseDetail SET soft_delete = ? WHERE table_sqlite_id = ?',
        [data.soft_delete, data.table_sqlite_id]);
  }

/*
  Soft-delete table use id
*/
  Future<int> deleteTableUseID(TableUse data) async {
    final db = await instance.database;
    return await db.rawUpdate(
        'UPDATE $tableTableUse SET soft_delete = ? WHERE table_use_sqlite_id = ?',
        [data.soft_delete, data.table_use_sqlite_id]);
  }

/*
  Soft-delete printer
*/
  Future<int> deletePrinter(Printer data) async {
    final db = await instance.database;
    return await db.rawUpdate(
        'UPDATE $tablePrinter SET soft_delete = ? WHERE printer_sqlite_id = ?',
        [data.soft_delete, data.printer_sqlite_id]);
  }

/*
  Soft-delete printer link category
*/
  Future<int> deletePrinterCategory(PrinterLinkCategory data) async {
    final db = await instance.database;
    return await db.rawUpdate(
        'UPDATE $tablePrinterLinkCategory SET soft_delete = ? WHERE printer_sqlite_id = ?',
        [data.soft_delete, data.printer_sqlite_id]);
  }

/*
  Soft-delete receipt layout
*/
  Future<int> deleteReceiptLayout(Receipt data) async {
    final db = await instance.database;
    return await db.rawUpdate(
        'UPDATE $tableReceipt SET sync_status = ?, soft_delete = ? WHERE receipt_sqlite_id = ?',
        [data.sync_status, data.soft_delete, data.receipt_sqlite_id]);
  }

/*
  Soft-delete cash record
*/
  Future<int> deleteCashRecord(CashRecord data) async {
    final db = await instance.database;
    return await db.rawUpdate(
        'UPDATE $tableCashRecord SET sync_status = ?, soft_delete = ? WHERE cash_record_sqlite_id = ?',
        [data.sync_status, data.soft_delete, data.cash_record_sqlite_id]);
  }

/*
  ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
*/

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

/*
  Delete All Order cache
*/
  Future clearAllOrderCache() async {
    final db = await instance.database;
    return await db.rawDelete('DELETE FROM $tableOrderCache');
  }

/*
  Delete All Order detail
*/
  Future clearAllOrderDetail() async {
    final db = await instance.database;
    return await db.rawDelete('DELETE FROM $tableOrderDetail');
  }

/*
  Delete All Order modifier detail
*/
  Future clearAllOrderModifierDetail() async {
    final db = await instance.database;
    return await db.rawDelete('DELETE FROM $tableOrderModifierDetail');
  }

/*
  ----------------------Sync from cloud--------------------------------------------------------------------------------------------------------------------------------------------------
*/

/*
  update category(from cloud)
*/
  Future<int> updateCategoryFromCloud(Categories data) async {
    final db = await instance.database;
    return await db.rawUpdate(
        'UPDATE $tableCategories SET name = ?, color = ?, updated_at = ?, soft_delete = ? WHERE category_id = ?',
        [
          data.name,
          data.color,
          data.updated_at,
          data.soft_delete,
          data.category_id
        ]);
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
