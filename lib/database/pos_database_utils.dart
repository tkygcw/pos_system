import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:pos_system/object/sales_per_day/category_sales_per_day.dart';
import 'package:pos_system/object/sales_per_day/dining_sales_per_day.dart';
import 'package:pos_system/object/sales_per_day/product_sales_per_day.dart';
import 'package:pos_system/object/sales_per_day/sales_per_day.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';

import '../object/app_setting.dart';
import '../object/attendance.dart';
import '../object/bill.dart';
import '../object/branch.dart';
import '../object/branch_link_dining_option.dart';
import '../object/branch_link_modifier.dart';
import '../object/branch_link_product.dart';
import '../object/branch_link_promotion.dart';
import '../object/branch_link_tax.dart';
import '../object/branch_link_user.dart';
import '../object/cancel_receipt.dart';
import '../object/cash_record.dart';
import '../object/categories.dart';
import '../object/checklist.dart';
import '../object/color.dart';
import '../object/current_version.dart';
import '../object/customer.dart';
import '../object/dining_option.dart';
import '../object/dynamic_qr.dart';
import '../object/kitchen_list.dart';
import '../object/modifier_group.dart';
import '../object/modifier_item.dart';
import '../object/modifier_link_product.dart';
import '../object/order.dart';
import '../object/order_cache.dart';
import '../object/order_detail.dart';
import '../object/order_detail_cancel.dart';
import '../object/order_detail_link_promotion.dart';
import '../object/order_detail_link_tax.dart';
import '../object/order_modifier_detail.dart';
import '../object/order_payment_split.dart';
import '../object/order_promotion_detail.dart';
import '../object/order_tax_detail.dart';
import '../object/payment_link_company.dart';
import '../object/printer.dart';
import '../object/printer_link_category.dart';
import '../object/product.dart';
import '../object/product_variant.dart';
import '../object/product_variant_detail.dart';
import '../object/promotion.dart';
import '../object/receipt.dart';
import '../object/refund.dart';
import '../object/sale.dart';
import '../object/sales_per_day/modifier_sales_per_day.dart';
import '../object/second_screen.dart';
import '../object/settlement.dart';
import '../object/settlement_link_payment.dart';
import '../object/subscription.dart';
import '../object/table.dart';
import '../object/table_use.dart';
import '../object/table_use_detail.dart';
import '../object/tax.dart';
import '../object/tax_link_dining.dart';
import '../object/transfer_owner.dart';
import '../object/user.dart';
import '../object/user_log.dart';
import '../object/variant_group.dart';
import '../object/variant_item.dart';

class PosDatabaseUtils {
  static final idType = 'INTEGER PRIMARY KEY AUTOINCREMENT';
  static final textType = 'TEXT NOT NULL';
  static final integerType = 'INTEGER NOT NULL';
  static final jsonType = 'JSON DEFAULT "[]"';

  static void onUpgrade (Database db, int oldVersion, int newVersion) async {
    //get pref
    final prefs = await SharedPreferences.getInstance();

    if (oldVersion < newVersion) {
      print("new version: $newVersion");
      for (int version = oldVersion; version <= newVersion; version++) {
        print("current version: ${version}");
        // you can execute drop table and create table
        switch (version) {
          case 10: {
            await db.execute("ALTER TABLE $tableAppSetting ADD ${AppSettingFields.print_receipt} INTEGER NOT NULL DEFAULT 1");
          }break;
          case 11: {
            await db.execute("ALTER TABLE $tablePaymentLinkCompany ADD ${PaymentLinkCompanyFields.allow_image} $integerType DEFAULT 0");
            await db.execute("ALTER TABLE $tablePaymentLinkCompany ADD ${PaymentLinkCompanyFields.image_name} $textType DEFAULT '' ");
          }break;
          case 12: {
            await db.execute("ALTER TABLE $tableOrderDetail ADD ${OrderDetailFields.edited_by} TEXT NOT NULL DEFAULT '' ");
            await db.execute("ALTER TABLE $tableOrderDetail ADD ${OrderDetailFields.edited_by_user_id} TEXT NOT NULL DEFAULT '' ");
            await db.execute("ALTER TABLE $tableChecklist ADD ${ChecklistFields.check_list_show_price} INTEGER NOT NULL DEFAULT 0");
            await db.execute("ALTER TABLE $tableChecklist ADD ${ChecklistFields.check_list_show_separator} INTEGER NOT NULL DEFAULT 0");
            await db.execute("ALTER TABLE $tableUser ADD ${UserFields.edit_price_without_pin} INTEGER NOT NULL DEFAULT 0");
          }break;
          case 13: {
            await db.execute("ALTER TABLE $tableAppSetting ADD ${AppSettingFields.qr_order_auto_accept} INTEGER NOT NULL DEFAULT 0");
            await db.execute('''CREATE TABLE $tableSubscription(
            ${SubscriptionFields.subscription_sqlite_id} $idType,
            ${SubscriptionFields.id} $integerType,
            ${SubscriptionFields.company_id} $textType,
            ${SubscriptionFields.subscription_plan_id} $textType,
            ${SubscriptionFields.subscribe_package} $textType,
            ${SubscriptionFields.subscribe_fee} $textType,
            ${SubscriptionFields.duration} $textType,
            ${SubscriptionFields.branch_amount} $integerType,
            ${SubscriptionFields.start_date} $textType,
            ${SubscriptionFields.end_date} $textType,
            ${SubscriptionFields.created_at} $textType,
            ${SubscriptionFields.soft_delete} $textType)''');
          }break;
          case 14: {
            print("case 14 called");
            await db.execute("ALTER TABLE $tableUser ADD ${UserFields.refund_permission} INTEGER NOT NULL DEFAULT 1");
            await db.execute("ALTER TABLE $tableUser ADD ${UserFields.settlement_permission} INTEGER NOT NULL DEFAULT 1");
            await db.execute("ALTER TABLE $tableUser ADD ${UserFields.report_permission} INTEGER NOT NULL DEFAULT 1");
            await db.execute("ALTER TABLE $tableUser ADD ${UserFields.cash_drawer_permission} INTEGER NOT NULL DEFAULT 1");
          }break;
          case 15: {
            await db.execute("UPDATE $tableUser SET ${UserFields.edit_price_without_pin} = 1 WHERE role = 0 AND soft_delete = ''");
            await db.execute("UPDATE $tableBranch SET ${BranchFields.sub_pos_status} = 1");
            await db.execute("UPDATE $tableBranch SET ${BranchFields.attendance_status} = 1");
          }break;
          case 16: {
            await db.execute('''CREATE TABLE $tableAttendance(
            ${AttendanceFields.attendance_sqlite_id} $idType,
            ${AttendanceFields.attendance_key} $textType,
            ${AttendanceFields.branch_id} $textType,
            ${AttendanceFields.user_id} $textType,
            ${AttendanceFields.role} $integerType,
            ${AttendanceFields.clock_in_at} $textType,
            ${AttendanceFields.clock_out_at} $textType,
            ${AttendanceFields.duration} $integerType,
            ${AttendanceFields.sync_status} $integerType,
            ${AttendanceFields.created_at} $textType,
            ${AttendanceFields.updated_at} $textType,
            ${AttendanceFields.soft_delete} $textType)''');
          }break;
          case 17: {
            await db.execute("ALTER TABLE $tableProduct ADD ${ProductFields.allow_ticket} $integerType DEFAULT 0");
            await db.execute("ALTER TABLE $tableProduct ADD ${ProductFields.ticket_count} $integerType NOT NULL DEFAULT 0");
            await db.execute("ALTER TABLE $tableProduct ADD ${ProductFields.ticket_exp} $textType NOT NULL DEFAULT '' ");
          }break;
          case 18: {
            await db.execute("ALTER TABLE $tableAppSetting ADD ${AppSettingFields.print_cancel_receipt} $integerType DEFAULT 1");
            await db.execute("ALTER TABLE $tableAppSetting ADD ${AppSettingFields.product_sort_by} $integerType DEFAULT 0");
            await db.execute("ALTER TABLE $tableAppSetting ADD ${AppSettingFields.show_product_desc} $integerType DEFAULT 0");
          }break;
          case 19: {
            await db.execute("ALTER TABLE $tableSettlement ADD ${SettlementFields.opened_at} $textType NOT NULL DEFAULT '' ");
          }break;
          case 20: {
            await db.execute('''CREATE TABLE $tableDynamicQR(
            ${DynamicQRFields.dynamic_qr_sqlite_id} $idType,
            ${DynamicQRFields.dynamic_qr_id} $integerType,
            ${DynamicQRFields.dynamic_qr_key} $textType,
            ${DynamicQRFields.branch_id} $textType,
            ${DynamicQRFields.qr_code_size} $integerType,
            ${DynamicQRFields.paper_size} $textType,
            ${DynamicQRFields.footer_text} $textType,
            ${DynamicQRFields.sync_status} $integerType,
            ${DynamicQRFields.created_at} $textType,
            ${DynamicQRFields.updated_at} $textType,
            ${DynamicQRFields.soft_delete} $textType)''');
            await db.execute("ALTER TABLE $tableAppSetting ADD ${AppSettingFields.dynamic_qr_default_exp_after_hour} $integerType DEFAULT 1");
          }break;
          case 21: {
            await db.execute("ALTER TABLE $tableOrderDetail ADD ${OrderDetailFields.product_sku} $textType DEFAULT '' ");
            await db.execute("ALTER TABLE $tableReceipt ADD ${ReceiptFields.show_product_sku} $integerType DEFAULT 0");
            await db.execute("ALTER TABLE $tableReceipt ADD ${ReceiptFields.show_branch_tel} $integerType DEFAULT 1");
            await db.execute("ALTER TABLE $tableChecklist ADD ${ChecklistFields.show_product_sku} $integerType DEFAULT 0");
            await db.execute("ALTER TABLE $tableKitchenList ADD ${KitchenListFields.show_product_sku} $integerType DEFAULT 0 ");
            await db.execute("ALTER TABLE $tableTax ADD ${TaxFields.type} $integerType DEFAULT 0");
            await db.execute("ALTER TABLE $tableOrderTaxDetail ADD ${OrderTaxDetailFields.type} $integerType DEFAULT 0");
            await db.execute("ALTER TABLE $tableSettlement ADD ${SettlementFields.total_charge} $textType NOT NULL DEFAULT '' ");
          }break;
          case 22: {
            if(defaultTargetPlatform == TargetPlatform.iOS){
              await db.execute("ALTER TABLE $tableTax ADD ${TaxFields.type} $integerType DEFAULT 0");
              await db.execute("ALTER TABLE $tableOrderTaxDetail ADD ${OrderTaxDetailFields.type} $integerType DEFAULT 0");
              await db.execute("ALTER TABLE $tableSettlement ADD ${SettlementFields.total_charge} $textType NOT NULL DEFAULT '' ");
            }
            await db.execute("ALTER TABLE $tableAppSetting ADD ${AppSettingFields.variant_item_sort_by} $integerType DEFAULT 0");
          }break;
          case 23: {
            await db.execute('''CREATE TABLE $tableOrderPaymentSplit(
            ${OrderPaymentSplitFields.order_payment_split_sqlite_id} $idType,
            ${OrderPaymentSplitFields.order_payment_split_id} $integerType,
            ${OrderPaymentSplitFields.order_payment_split_key} $textType,
            ${OrderPaymentSplitFields.branch_id} $textType,
            ${OrderPaymentSplitFields.payment_link_company_id} $textType,
            ${OrderPaymentSplitFields.amount} $textType,
            ${OrderPaymentSplitFields.payment_received} $textType,
            ${OrderPaymentSplitFields.payment_change} $textType,
            ${OrderPaymentSplitFields.order_key} $textType,
            ${OrderPaymentSplitFields.ipay_trans_id} $textType,
            ${OrderPaymentSplitFields.sync_status} $integerType,
            ${OrderPaymentSplitFields.created_at} $textType,
            ${OrderPaymentSplitFields.updated_at} $textType,
            ${OrderPaymentSplitFields.soft_delete} $textType)''');
            await db.execute("ALTER TABLE $tableOrder ADD ${OrderFields.payment_split} INTEGER NOT NULL DEFAULT 0");
            await db.execute("ALTER TABLE $tableOrder ADD ${OrderFields.ipay_trans_id} $textType DEFAULT '' ");
            await db.execute('''CREATE TABLE $tableCurrentVersion(
            ${CurrentVersionFields.current_version_sqlite_id} $idType,
            ${CurrentVersionFields.current_version_id} $integerType,
            ${CurrentVersionFields.branch_id} $textType,
            ${CurrentVersionFields.current_version} $textType,
            ${CurrentVersionFields.platform} $integerType,
            ${CurrentVersionFields.is_gms} $integerType,
            ${CurrentVersionFields.source} $textType,
            ${CurrentVersionFields.sync_status} $integerType,
            ${CurrentVersionFields.created_at} $textType,
            ${CurrentVersionFields.updated_at} $textType,
            ${CurrentVersionFields.soft_delete} $textType)''');
          }break;
          case 24: {
            await db.execute("ALTER TABLE $tableOrderCache ADD ${OrderCacheFields.payment_status} $integerType DEFAULT 1");
          }break;
          case 25: {
            print("case 25 call");
            await dbVersion26Upgrade(db, prefs);
            await dbVersion27Upgrade(db);
          }break;
          case 26: {
            print("case 26 call");
            await dbVersion26Upgrade(db, prefs);
            await dbVersion27Upgrade(db);
          }break;
          case 27: {
            print("case 27 call");
            await db.execute("ALTER TABLE $tableBranch ADD ${BranchFields.allow_firestore} $integerType DEFAULT 0 ");
          }break;
          case 28: {
            ///Temporarily close
            // await dbVersion29Upgrade(db, prefs);
          }break;
          case 29: {
            await dbVersion30Upgrade(db, prefs);
            await db.execute("ALTER TABLE $tableBranch ADD ${BranchFields.logo} $textType DEFAULT ''");
            await db.execute("ALTER TABLE $tableReceipt ADD ${ReceiptFields.header_image_size} $integerType DEFAULT 0 ");
            await db.execute("ALTER TABLE $tableReceipt ADD ${ReceiptFields.second_header_text} $textType DEFAULT '' ");
            await db.execute("ALTER TABLE $tableReceipt ADD ${ReceiptFields.second_header_text_status} $integerType DEFAULT 0 ");
            await db.execute("ALTER TABLE $tableReceipt ADD ${ReceiptFields.second_header_font_size} $integerType DEFAULT 0 ");
            await db.execute("ALTER TABLE $tableReceipt ADD ${ReceiptFields.hide_dining_method_table_no} $integerType DEFAULT 0 ");
            await db.execute("ALTER TABLE $tableKitchenList ADD ${KitchenListFields.use_printer_label_as_title} INTEGER NOT NULL DEFAULT 0");
          }break;
          case 30: {
            await dbVersion31Upgrade(db);
          }break;
          case 31: {
            await db.execute("ALTER TABLE $tableBranch ADD ${BranchFields.allow_livedata} $integerType DEFAULT 0 ");
          }break;
          case 32: {
          await db.execute("ALTER TABLE $tableAppSetting ADD ${AppSettingFields.qr_order_alert} $integerType DEFAULT 1");
          await db.execute("ALTER TABLE $tableOrderCache ADD ${OrderCacheFields.other_order_key} $textType DEFAULT ''");
          await db.execute("ALTER TABLE $tableAppSetting ADD ${AppSettingFields.rounding_absorb} $integerType DEFAULT 0");
          }break;
          case 33: {
            await dbVersion33Upgrade(db, prefs);
          }break;
          case 34: {
            await db.execute("ALTER TABLE $tableBranch ADD ${BranchFields.allow_einvoice} $integerType DEFAULT 0 ");
            await db.execute("ALTER TABLE $tableBranch ADD ${BranchFields.einvoice_status} $integerType DEFAULT 0 ");
          }break;
          case 35: {
            await db.execute("ALTER TABLE $tablePromotion ADD ${PromotionFields.multiple_category} $jsonType");
            await db.execute("ALTER TABLE $tablePromotion ADD ${PromotionFields.multiple_product} $jsonType");
          }break;
        }
      }
    }
  }

  static Future createDB(Database db, int version) async {
/*
    create user table
*/
    await db.execute('''CREATE TABLE $tableUser ( ${UserFields.user_id} $idType, ${UserFields.name} $textType, ${UserFields.email} $textType, 
           ${UserFields.phone} $textType, ${UserFields.role} $integerType, ${UserFields.pos_pin} $textType, ${UserFields.edit_price_without_pin} $integerType, 
           ${UserFields.refund_permission} $integerType, ${UserFields.cash_drawer_permission} $integerType, ${UserFields.settlement_permission} $integerType, 
           ${UserFields.report_permission} $integerType, ${UserFields.status} $integerType, ${UserFields.created_at} $textType, 
           ${UserFields.updated_at} $textType, ${UserFields.soft_delete} $textType)''');
/*
    create subscription table
*/
    await db.execute('''CREATE TABLE $tableSubscription ( ${SubscriptionFields.subscription_sqlite_id} $idType, ${SubscriptionFields.id} $integerType, ${SubscriptionFields.company_id} $textType, 
           ${SubscriptionFields.subscription_plan_id} $textType, ${SubscriptionFields.subscribe_package} $textType, ${SubscriptionFields.subscribe_fee} $textType, ${SubscriptionFields.duration} $textType, 
           ${SubscriptionFields.branch_amount} $integerType, ${SubscriptionFields.start_date} $textType, ${SubscriptionFields.end_date} $textType, ${SubscriptionFields.created_at} $textType, 
           ${SubscriptionFields.soft_delete} $textType)''');

/*
    create attendance table
*/
    await db.execute('''CREATE TABLE $tableAttendance ( ${AttendanceFields.attendance_sqlite_id} $idType, ${AttendanceFields.attendance_key} $textType, ${AttendanceFields.branch_id} $textType, 
           ${AttendanceFields.user_id} $textType, ${AttendanceFields.role} $integerType, ${AttendanceFields.clock_in_at} $textType, ${AttendanceFields.clock_out_at} $textType, ${AttendanceFields.duration} $integerType, 
           ${AttendanceFields.sync_status} $integerType, ${AttendanceFields.created_at} $textType, ${AttendanceFields.updated_at} $textType, ${AttendanceFields.soft_delete} $textType)''');
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
    await db.execute('''CREATE TABLE $tableBill ( ${BillFields.bill_sqlite_id} $idType, ${BillFields.bill_id} $integerType, ${BillFields.company_id} $textType,
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
        '''CREATE TABLE $tableDiningOption (
        ${DiningOptionFields.dining_id} $idType, 
        ${DiningOptionFields.name} $textType, 
        ${DiningOptionFields.company_id} $textType,
        ${DiningOptionFields.created_at} $textType, 
        ${DiningOptionFields.updated_at} $textType, 
        ${DiningOptionFields.soft_delete} $textType)''');
/*
    create modifier group table
*/
    await db.execute(
        '''CREATE TABLE $tableModifierGroup ( 
        ${ModifierGroupFields.mod_group_id} $idType, 
        ${ModifierGroupFields.company_id} $textType, 
        ${ModifierGroupFields.name} $textType, 
        ${ModifierGroupFields.dining_id} $textType, 
        ${ModifierGroupFields.compulsory} $textType, 
        ${ModifierGroupFields.sequence_number} $textType,
        ${ModifierGroupFields.min_select} $integerType,
        ${ModifierGroupFields.max_select} $integerType,
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
    await db.execute('''CREATE TABLE $tableOrder ( 
           ${OrderFields.order_sqlite_id} $idType, 
           ${OrderFields.order_id} $integerType, 
           ${OrderFields.order_number} $textType,
           ${OrderFields.order_queue} $textType,
           ${OrderFields.company_id} $textType,
           ${OrderFields.customer_id} $textType, 
           ${OrderFields.dining_id} $textType,
           ${OrderFields.dining_name} $textType,
           ${OrderFields.branch_link_promotion_id} $textType,
           ${OrderFields.payment_link_company_id} $textType,
           ${OrderFields.branch_id} $textType, 
           ${OrderFields.branch_link_tax_id} $textType, 
           ${OrderFields.subtotal} $textType,
           ${OrderFields.amount} $textType, 
           ${OrderFields.rounding} $textType, 
           ${OrderFields.final_amount} $textType,
           ${OrderFields.close_by} $textType, 
           ${OrderFields.payment_status} $integerType, 
           ${OrderFields.payment_split} $integerType, 
           ${OrderFields.payment_received} $textType,
           ${OrderFields.payment_change} $textType,
           ${OrderFields.order_key} $textType,
           ${OrderFields.refund_sqlite_id} $textType,
           ${OrderFields.refund_key} $textType,
           ${OrderFields.settlement_sqlite_id} $textType,
           ${OrderFields.settlement_key} $textType,
           ${OrderFields.ipay_trans_id} $textType,
           ${OrderFields.sync_status} $integerType,
           ${OrderFields.created_at} $textType, 
           ${OrderFields.updated_at} $textType, 
           ${OrderFields.soft_delete} $textType)''');
/*
    create order cache table
*/
    await db.execute('''CREATE TABLE $tableOrderCache ( 
          ${OrderCacheFields.order_cache_sqlite_id} $idType, 
          ${OrderCacheFields.order_cache_id} $integerType,
          ${OrderCacheFields.order_cache_key} $textType, 
          ${OrderCacheFields.order_queue} $textType, 
          ${OrderCacheFields.company_id} $textType, 
          ${OrderCacheFields.branch_id} $textType, 
          ${OrderCacheFields.order_detail_id} $textType, 
          ${OrderCacheFields.table_use_sqlite_id} $textType, 
          ${OrderCacheFields.table_use_key} $textType,
          ${OrderCacheFields.other_order_key} $textType,
          ${OrderCacheFields.batch_id} $textType, 
          ${OrderCacheFields.dining_id} $textType, 
          ${OrderCacheFields.order_sqlite_id} $textType, 
          ${OrderCacheFields.order_key} $textType,
          ${OrderCacheFields.order_by} $textType,
          ${OrderCacheFields.order_by_user_id} $textType, 
          ${OrderCacheFields.cancel_by} $textType,
          ${OrderCacheFields.cancel_by_user_id} $textType,
          ${OrderCacheFields.customer_id} $textType, 
          ${OrderCacheFields.total_amount} $textType,
          ${OrderCacheFields.qr_order} $integerType,
          ${OrderCacheFields.qr_order_table_sqlite_id} $textType,
          ${OrderCacheFields.qr_order_table_id} $textType,
          ${OrderCacheFields.accepted} $integerType,
          ${OrderCacheFields.payment_status} $integerType,
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
        ${OrderDetailFields.order_detail_key} $textType,
        ${OrderDetailFields.order_cache_sqlite_id} $textType, 
        ${OrderDetailFields.order_cache_key} $textType,
        ${OrderDetailFields.branch_link_product_sqlite_id} $textType, 
        ${OrderDetailFields.category_sqlite_id} $textType,
        ${OrderDetailFields.category_name} $textType,
        ${OrderDetailFields.productName} $textType,
        ${OrderDetailFields.has_variant} $textType, 
        ${OrderDetailFields.product_variant_name} $textType, 
        ${OrderDetailFields.price} $textType, 
        ${OrderDetailFields.original_price} $textType, 
        ${OrderDetailFields.quantity} $textType, 
        ${OrderDetailFields.remark} $textType, 
        ${OrderDetailFields.account} $textType,
        ${OrderDetailFields.edited_by} $textType,
        ${OrderDetailFields.edited_by_user_id} $textType,
        ${OrderDetailFields.cancel_by} $textType,
        ${OrderDetailFields.cancel_by_user_id} $textType,
        ${OrderDetailFields.status} $integerType,
        ${OrderDetailFields.sync_status} $integerType,
        ${OrderDetailFields.unit} $textType, 
        ${OrderDetailFields.per_quantity_unit} $textType,
        ${OrderDetailFields.product_sku} $textType,
        ${OrderDetailFields.created_at} $textType, 
        ${OrderDetailFields.updated_at} $textType,
        ${OrderDetailFields.soft_delete} $textType)''');

/*
    create order detail link tax table
*/
    await db.execute('''CREATE TABLE $tableOrderDetailLinkTax ( 
        ${OrderDetailLinkTaxFields.order_detail_link_tax_sqlite_id} $idType, 
        ${OrderDetailLinkTaxFields.order_detail_link_tax_id} $integerType, 
        ${OrderDetailLinkTaxFields.order_detail_link_tax_key} $textType,
        ${OrderDetailLinkTaxFields.order_detail_sqlite_id} $textType, 
        ${OrderDetailLinkTaxFields.order_detail_id} $textType,
        ${OrderDetailLinkTaxFields.order_detail_key} $textType, 
        ${OrderDetailLinkTaxFields.tax_id} $textType,
        ${OrderDetailLinkTaxFields.tax_name} $textType,
        ${OrderDetailLinkTaxFields.rate} $textType, 
        ${OrderDetailLinkTaxFields.branch_link_tax_id} $textType, 
        ${OrderDetailLinkTaxFields.tax_amount} $textType, 
        ${OrderDetailLinkTaxFields.sync_status} $integerType,
        ${OrderDetailLinkTaxFields.created_at} $textType, 
        ${OrderDetailLinkTaxFields.updated_at} $textType,
        ${OrderDetailLinkTaxFields.soft_delete} $textType)''');

/*
    create order detail link promotion table
*/
    await db.execute('''CREATE TABLE $tableOrderDetailLinkPromotion ( 
        ${OrderDetailLinkPromotionFields.order_detail_link_promotion_sqlite_id} $idType, 
        ${OrderDetailLinkPromotionFields.order_detail_link_promotion_id} $integerType, 
        ${OrderDetailLinkPromotionFields.order_detail_link_promotion_key} $textType, 
        ${OrderDetailLinkPromotionFields.order_detail_sqlite_id} $textType, 
        ${OrderDetailLinkPromotionFields.order_detail_id} $textType, 
        ${OrderDetailLinkPromotionFields.order_detail_key} $textType, 
        ${OrderDetailLinkPromotionFields.promotion_id} $textType, 
        ${OrderDetailLinkPromotionFields.promotion_name} $textType, 
        ${OrderDetailLinkPromotionFields.rate} $textType, 
        ${OrderDetailLinkPromotionFields.branch_link_promotion_id} $textType, 
        ${OrderDetailLinkPromotionFields.promotion_amount} $textType, 
        ${OrderDetailLinkPromotionFields.sync_status} $integerType, 
        ${OrderDetailLinkPromotionFields.created_at} $textType, 
        ${OrderDetailLinkPromotionFields.updated_at} $textType, 
        ${OrderDetailLinkPromotionFields.soft_delete} $textType)''');

/*
    create payment link company
*/
    await db.execute('''CREATE TABLE $tablePaymentLinkCompany ( ${PaymentLinkCompanyFields.payment_link_company_id} $idType, ${PaymentLinkCompanyFields.payment_type_id} $textType,
           ${PaymentLinkCompanyFields.company_id} $textType, 
           ${PaymentLinkCompanyFields.name} $textType, 
           ${PaymentLinkCompanyFields.allow_image} $integerType, 
           ${PaymentLinkCompanyFields.image_name} $textType, 
           ${PaymentLinkCompanyFields.type} $integerType, 
           ${PaymentLinkCompanyFields.ipay_code} $textType, 
           ${PaymentLinkCompanyFields.created_at} $textType, ${PaymentLinkCompanyFields.updated_at} $textType, ${PaymentLinkCompanyFields.soft_delete} $textType)''');
/*
    create product table
*/
    await db.execute(
        '''CREATE TABLE $tableProduct ( ${ProductFields.product_sqlite_id} $idType, ${ProductFields.product_id} $integerType, ${ProductFields.category_id} $textType, ${ProductFields.category_sqlite_id} $textType, ${ProductFields.company_id} $textType,
           ${ProductFields.name} $textType,${ProductFields.price} $textType, ${ProductFields.description} $textType, ${ProductFields.SKU} $textType, ${ProductFields.image} $textType,
           ${ProductFields.has_variant} $integerType,${ProductFields.stock_type} $integerType, ${ProductFields.stock_quantity} $textType, ${ProductFields.available} $integerType,
           ${ProductFields.graphic_type} $textType, ${ProductFields.color} $textType, ${ProductFields.daily_limit} $textType, ${ProductFields.daily_limit_amount} $textType, 
           ${ProductFields.sync_status} $integerType, ${ProductFields.unit} $textType, ${ProductFields.per_quantity_unit} $textType, ${ProductFields.sequence_number} $textType, 
           ${ProductFields.allow_ticket} $integerType, ${ProductFields.ticket_count} $integerType, ${ProductFields.ticket_exp} $textType, ${ProductFields.show_in_qr} $integerType, 
           ${ProductFields.created_at} $textType, ${ProductFields.updated_at} $textType, ${ProductFields.soft_delete} $textType)''');
/*
    create product variant table
*/
    await db.execute(
        '''CREATE TABLE $tableProductVariant ( ${ProductVariantFields.product_variant_sqlite_id} $idType, ${ProductVariantFields.product_variant_id} $integerType, ${ProductVariantFields.product_sqlite_id} $textType, ${ProductVariantFields.product_id} $textType, ${ProductVariantFields.variant_name} $textType,
           ${ProductVariantFields.SKU} $textType,${ProductVariantFields.price} $textType,${ProductVariantFields.stock_type} $textType, ${ProductVariantFields.daily_limit} $textType, ${ProductVariantFields.daily_limit_amount} $textType,
           ${ProductVariantFields.stock_quantity} $textType, ${ProductVariantFields.sync_status} $integerType,${ProductVariantFields.created_at} $textType, ${ProductVariantFields.updated_at} $textType, ${ProductVariantFields.soft_delete} $textType)''');
/*
    create product variant detail table
*/
    await db.execute(
        '''CREATE TABLE $tableProductVariantDetail ( ${ProductVariantDetailFields.product_variant_detail_sqlite_id} $idType, ${ProductVariantDetailFields.product_variant_detail_id} $integerType,
           ${ProductVariantDetailFields.product_variant_id} $textType,${ProductVariantDetailFields.product_variant_sqlite_id} $textType, ${ProductVariantDetailFields.variant_item_sqlite_id} $textType,${ProductVariantDetailFields.variant_item_id} $textType, ${ProductVariantDetailFields.sync_status} $integerType, ${ProductVariantDetailFields.created_at} $textType, 
           ${ProductVariantDetailFields.updated_at} $textType, ${ProductVariantDetailFields.soft_delete} $textType)''');
/*
    create promotion table
*/
    await db.execute(
        '''CREATE TABLE $tablePromotion ( ${PromotionFields.promotion_id} $idType, ${PromotionFields.company_id} $textType,${PromotionFields.name} $textType,${PromotionFields.amount} $textType, 
           ${PromotionFields.specific_category} $textType, ${PromotionFields.category_id} $textType, ${PromotionFields.multiple_category} $jsonType, 
           ${PromotionFields.multiple_product} $jsonType, ${PromotionFields.type} $integerType,
           ${PromotionFields.auto_apply} $textType,${PromotionFields.all_day} $textType, ${PromotionFields.all_time} $textType, ${PromotionFields.sdate} $textType,
           ${PromotionFields.edate} $textType, ${PromotionFields.stime} $textType, ${PromotionFields.etime} $textType,
           ${PromotionFields.created_at} $textType, ${PromotionFields.updated_at} $textType, ${PromotionFields.soft_delete} $textType)''');
/*
    create refund table
*/
    await db.execute('''CREATE TABLE $tableRefund ( 
          ${RefundFields.refund_sqlite_id} $idType, 
          ${RefundFields.refund_id} $integerType, 
          ${RefundFields.refund_key} $textType,
          ${RefundFields.company_id} $textType,
          ${RefundFields.branch_id} $textType, 
          ${RefundFields.order_cache_sqlite_id} $textType,
          ${RefundFields.order_cache_key} $textType,
          ${RefundFields.order_sqlite_id} $textType, 
          ${RefundFields.order_key} $textType,
          ${RefundFields.refund_by} $textType, 
          ${RefundFields.refund_by_user_id} $textType,
          ${RefundFields.bill_id} $textType, 
          ${RefundFields.sync_status} $integerType,
          ${RefundFields.created_at} $textType,
          ${RefundFields.updated_at} $textType, 
          ${RefundFields.soft_delete} $textType)''');
/*
    create sale table
*/
    await db.execute('''CREATE TABLE $tableSale ( ${SaleFields.sale_sqlite_id} $idType, ${SaleFields.sale_id} $integerType,
           ${SaleFields.company_id} $textType,${SaleFields.branch_id} $textType, ${SaleFields.daily_sales} $textType,
           ${SaleFields.user_sales} $textType, ${SaleFields.item_sales} $textType, ${SaleFields.cashier_sales} $textType,
           ${SaleFields.hours_sales} $textType, ${SaleFields.payment_sales} $textType,  
           ${SaleFields.created_at} $textType,${SaleFields.updated_at} $textType, ${SaleFields.soft_delete} $textType)''');
/*
    create restaurant table
*/
    await db.execute('''CREATE TABLE $tablePosTable ( 
           ${PosTableFields.table_sqlite_id} $idType, 
           ${PosTableFields.table_url} $textType, 
           ${PosTableFields.table_id} $integerType, 
           ${PosTableFields.branch_id} $textType,
           ${PosTableFields.number} $textType,
           ${PosTableFields.seats} $textType, 
           ${PosTableFields.table_use_detail_key} $textType, 
           ${PosTableFields.table_use_key} $textType, 
           ${PosTableFields.status} $integerType, 
           ${PosTableFields.sync_status} $integerType, 
           ${PosTableFields.dx} $textType, 
           ${PosTableFields.dy} $textType,
           ${PosTableFields.created_at} $textType,
           ${PosTableFields.updated_at} $textType, 
           ${PosTableFields.soft_delete} $textType)''');
/*
    create tax table
*/
    await db.execute('''CREATE TABLE $tableTax ( ${TaxFields.tax_id} $idType, ${TaxFields.company_id} $textType,${TaxFields.name} $textType,
           ${TaxFields.type} $integerType, ${TaxFields.tax_rate} $textType,${TaxFields.created_at} $textType,${TaxFields.updated_at} $textType, 
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
    await db.execute('''CREATE TABLE $tableUserLog ( ${UserLogFields.user_log_id} $idType, ${UserLogFields.user_id} $textType,${UserLogFields.check_in_time} $textType,
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
    await db.execute('''CREATE TABLE $tableBranchLinkDining ( ${BranchLinkDiningFields.branch_link_dining_id} $idType, ${BranchLinkDiningFields.branch_id} $textType,
           ${BranchLinkDiningFields.dining_id} $textType, ${BranchLinkDiningFields.is_default} $integerType, ${BranchLinkDiningFields.sequence} $textType,
           ${BranchLinkDiningFields.created_at} $textType, ${BranchLinkDiningFields.updated_at} $textType, ${BranchLinkDiningFields.soft_delete} $textType)''');
/*
    create branch link modifier
*/
    await db.execute('''CREATE TABLE $tableBranchLinkModifier ( ${BranchLinkModifierFields.branch_link_modifier_id} $idType, ${BranchLinkModifierFields.branch_id} $textType,
           ${BranchLinkModifierFields.mod_group_id} $textType, ${BranchLinkModifierFields.mod_item_id} $textType, ${BranchLinkModifierFields.name} $textType, 
           ${BranchLinkModifierFields.price} $textType, ${BranchLinkModifierFields.sequence} $integerType, ${BranchLinkModifierFields.status} $textType,
           ${BranchLinkModifierFields.created_at} $textType, ${BranchLinkModifierFields.updated_at} $textType,${BranchLinkModifierFields.soft_delete} $textType)''');
/*
    create branch link product table
*/
    await db.execute(
        '''CREATE TABLE $tableBranchLinkProduct ( ${BranchLinkProductFields.branch_link_product_sqlite_id} $idType, ${BranchLinkProductFields.branch_link_product_id} $integerType,
           ${BranchLinkProductFields.branch_id} $textType, ${BranchLinkProductFields.product_sqlite_id} $textType,
           ${BranchLinkProductFields.product_id} $textType, ${BranchLinkProductFields.has_variant} $textType, ${BranchLinkProductFields.product_variant_sqlite_id} $textType, ${BranchLinkProductFields.product_variant_id} $textType,
           ${BranchLinkProductFields.b_SKU} $textType, ${BranchLinkProductFields.price} $textType, ${BranchLinkProductFields.stock_type} $textType,
           ${BranchLinkProductFields.daily_limit} $textType, ${BranchLinkProductFields.daily_limit_amount} $textType, ${BranchLinkProductFields.stock_quantity} $textType,
           ${BranchLinkProductFields.sync_status} $integerType, ${BranchLinkProductFields.created_at} $textType, ${BranchLinkProductFields.updated_at} $textType, ${BranchLinkProductFields.soft_delete} $textType)''');
/*
    create branch link promotion
*/
    await db.execute('''CREATE TABLE $tableBranchLinkPromotion ( ${BranchLinkPromotionFields.branch_link_promotion_id} $idType, ${BranchLinkPromotionFields.branch_id} $textType,
           ${BranchLinkPromotionFields.promotion_id} $textType, ${BranchLinkPromotionFields.created_at} $textType, ${BranchLinkPromotionFields.updated_at} $textType,
           ${BranchLinkPromotionFields.soft_delete} $textType)''');
/*
    create branch link tax table
*/
    await db.execute('''CREATE TABLE $tableBranchLinkTax ( ${BranchLinkTaxFields.branch_link_tax_id} $idType, ${BranchLinkTaxFields.branch_id} $textType,
           ${BranchLinkTaxFields.tax_id} $textType, ${BranchLinkTaxFields.created_at} $textType, ${BranchLinkTaxFields.updated_at} $textType,
           ${BranchLinkTaxFields.soft_delete} $textType)''');
/*
    create branch link user table
*/
    await db.execute('''CREATE TABLE $tableBranchLinkUser ( ${BranchLinkUserFields.branch_link_user_id} $idType, ${BranchLinkUserFields.branch_id} $textType,
           ${BranchLinkUserFields.user_id} $textType, ${BranchLinkUserFields.created_at} $textType, ${BranchLinkUserFields.updated_at} $textType,
           ${BranchLinkUserFields.soft_delete} $textType)''');
/*
    create branch table
*/
    await db.execute('''CREATE TABLE $tableBranch (
           ${BranchFields.branch_id} $idType,
           ${BranchFields.branch_url} $textType,
           ${BranchFields.name} $textType,
           ${BranchFields.logo} $textType,
           ${BranchFields.address} $textType,
           ${BranchFields.phone} $textType,
           ${BranchFields.email} $textType,
           ${BranchFields.ipay_merchant_code} $textType,
           ${BranchFields.ipay_merchant_key} $textType,
           ${BranchFields.notification_token} $textType,
           ${BranchFields.qr_order_status} $textType,
           ${BranchFields.sub_pos_status} $integerType,
           ${BranchFields.attendance_status} $integerType,
           ${BranchFields.company_id} $textType,
           ${BranchFields.working_day} $textType,
           ${BranchFields.working_time} $textType,
           ${BranchFields.close_qr_order} $integerType,
           ${BranchFields.register_no} $textType,
           ${BranchFields.allow_firestore} $integerType,
           ${BranchFields.allow_livedata} $integerType,
           ${BranchFields.qr_show_sku} $integerType,
           ${BranchFields.qr_product_sequence} $integerType,
           ${BranchFields.show_qr_history} $textType,
           ${BranchFields.generate_sales} $integerType,
           ${BranchFields.allow_einvoice} $integerType,
           ${BranchFields.einvoice_status} $integerType
           )''');

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
          ${OrderModifierDetailFields.order_modifier_detail_key} $textType,
          ${OrderModifierDetailFields.order_detail_sqlite_id} $textType,
          ${OrderModifierDetailFields.order_detail_id} $textType,
          ${OrderModifierDetailFields.order_detail_key} $textType,
          ${OrderModifierDetailFields.mod_item_id} $textType,
          ${OrderModifierDetailFields.mod_name} $textType,
          ${OrderModifierDetailFields.mod_price} $textType,
          ${OrderModifierDetailFields.mod_group_id} $textType,
          ${OrderModifierDetailFields.sync_status} $integerType,
          ${OrderModifierDetailFields.created_at} $textType,
          ${OrderModifierDetailFields.updated_at} $textType,
          ${OrderModifierDetailFields.soft_delete} $textType)''');

/*
    create table use table
*/
    await db.execute('''CREATE TABLE $tableTableUse(
          ${TableUseFields.table_use_sqlite_id} $idType,
          ${TableUseFields.table_use_id} $integerType,
          ${TableUseFields.table_use_key} $textType,
          ${TableUseFields.branch_id} $integerType,
          ${TableUseFields.order_cache_key} $textType,
          ${TableUseFields.card_color} $textType,
          ${TableUseFields.status} $integerType,
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
          ${TableUseDetailFields.table_use_detail_key} $textType,
          ${TableUseDetailFields.table_use_sqlite_id} $textType,
          ${TableUseDetailFields.table_use_key} $textType,
          ${TableUseDetailFields.table_sqlite_id} $textType,
          ${TableUseDetailFields.table_id} $textType,
          ${TableUseDetailFields.status} $integerType,
          ${TableUseDetailFields.sync_status} $integerType,
          ${TableUseDetailFields.created_at} $textType,
          ${TableUseDetailFields.updated_at} $textType,
          ${TableUseDetailFields.soft_delete} $textType)''');

/*
    create printer table
*/
    await db.execute('''CREATE TABLE $tablePrinter(
          ${PrinterFields.printer_sqlite_id} $idType,
          ${PrinterFields.printer_key} $textType,
          ${PrinterFields.printer_id} $integerType,
          ${PrinterFields.branch_id} $textType,
          ${PrinterFields.company_id} $textType,
          ${PrinterFields.value} $textType,
          ${PrinterFields.type} $integerType,
          ${PrinterFields.printer_label} $textType,
          ${PrinterFields.printer_link_category_id} $textType,
          ${PrinterFields.paper_size} $integerType,
          ${PrinterFields.printer_status} $integerType,
          ${PrinterFields.is_counter} $integerType,
          ${PrinterFields.is_kitchen_checklist} $integerType,
          ${PrinterFields.is_label} $integerType,
          ${PrinterFields.sync_status} $integerType,
          ${PrinterFields.created_at} $textType,
          ${PrinterFields.updated_at} $textType,
          ${PrinterFields.soft_delete} $textType)''');

/*
    create printer link category table
*/
    await db.execute('''CREATE TABLE $tablePrinterLinkCategory(
          ${PrinterLinkCategoryFields.printer_link_category_sqlite_id} $idType,
          ${PrinterLinkCategoryFields.printer_link_category_key} $textType,
          ${PrinterLinkCategoryFields.printer_link_category_id} $integerType,
          ${PrinterLinkCategoryFields.printer_sqlite_id} $textType,
          ${PrinterLinkCategoryFields.printer_key} $textType,
          ${PrinterLinkCategoryFields.category_sqlite_id} $textType,
          ${PrinterLinkCategoryFields.category_id} $textType,
          ${PrinterLinkCategoryFields.sync_status} $integerType,
          ${PrinterLinkCategoryFields.created_at} $textType,
          ${PrinterLinkCategoryFields.updated_at} $textType,
          ${PrinterLinkCategoryFields.soft_delete} $textType)''');

/*
    create receipt table
*/
    await db.execute('''CREATE TABLE $tableReceipt(
          ${ReceiptFields.receipt_sqlite_id} $idType,
          ${ReceiptFields.receipt_id} $integerType,
          ${ReceiptFields.receipt_key} $textType,
          ${ReceiptFields.branch_id} $textType,
          ${ReceiptFields.header_image} $textType,
          ${ReceiptFields.header_image_size} $integerType,
          ${ReceiptFields.header_image_status} $integerType,
          ${ReceiptFields.header_text} $textType,
          ${ReceiptFields.header_text_status} $integerType,
          ${ReceiptFields.header_font_size} $integerType,
          ${ReceiptFields.second_header_text} $textType,
          ${ReceiptFields.second_header_text_status} $integerType,
          ${ReceiptFields.second_header_font_size} $integerType,
          ${ReceiptFields.show_address} $integerType,
          ${ReceiptFields.show_email} $integerType,
          ${ReceiptFields.receipt_email} $textType,
          ${ReceiptFields.show_break_down_price} $integerType,
          ${ReceiptFields.hide_dining_method_table_no} $integerType,
          ${ReceiptFields.footer_image} $textType,
          ${ReceiptFields.footer_image_status} $integerType,
          ${ReceiptFields.footer_text} $textType,
          ${ReceiptFields.footer_text_status} $integerType,
          ${ReceiptFields.promotion_detail_status} $integerType,
          ${ReceiptFields.paper_size} $textType,
          ${ReceiptFields.status} $integerType,
          ${ReceiptFields.show_product_sku} $integerType,
          ${ReceiptFields.show_branch_tel} $integerType,
          ${ReceiptFields.show_register_no} $integerType,
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
          ${CashRecordFields.cash_record_key} $textType,
          ${CashRecordFields.company_id} $textType,
          ${CashRecordFields.branch_id} $textType,
          ${CashRecordFields.remark} $textType,
          ${CashRecordFields.payment_name} $textType,
          ${CashRecordFields.payment_type_id} $textType,
          ${CashRecordFields.type} $integerType,
          ${CashRecordFields.amount} $textType,
          ${CashRecordFields.user_id} $textType,
          ${CashRecordFields.settlement_key} $textType,
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
          ${OrderTaxDetailFields.order_tax_detail_key} $textType,
          ${OrderTaxDetailFields.order_sqlite_id} $textType,
          ${OrderTaxDetailFields.order_id} $textType,
          ${OrderTaxDetailFields.order_key} $textType,
          ${OrderTaxDetailFields.tax_name} $textType,
          ${OrderTaxDetailFields.type} $integerType,
          ${OrderTaxDetailFields.rate} $textType,
          ${OrderTaxDetailFields.tax_id} $textType,
          ${OrderTaxDetailFields.branch_link_tax_id} $textType,
          ${OrderTaxDetailFields.tax_amount} $textType,
          ${OrderTaxDetailFields.sync_status} $integerType,
          ${OrderTaxDetailFields.created_at} $textType,
          ${OrderTaxDetailFields.updated_at} $textType,
          ${OrderTaxDetailFields.soft_delete} $textType)''');

/*
    create order promotion detail table
*/
    await db.execute('''CREATE TABLE $tableOrderPromotionDetail(
          ${OrderPromotionDetailFields.order_promotion_detail_sqlite_id} $idType,
          ${OrderPromotionDetailFields.order_promotion_detail_id} $integerType,
          ${OrderPromotionDetailFields.order_promotion_detail_key} $textType,
          ${OrderPromotionDetailFields.order_sqlite_id} $textType,
          ${OrderPromotionDetailFields.order_id} $textType,
          ${OrderPromotionDetailFields.order_key} $textType,
          ${OrderPromotionDetailFields.promotion_name} $textType,
          ${OrderPromotionDetailFields.rate} $textType,
          ${OrderPromotionDetailFields.promotion_id} $textType,
          ${OrderPromotionDetailFields.branch_link_promotion_id} $textType,
          ${OrderPromotionDetailFields.promotion_amount} $textType,
          ${OrderPromotionDetailFields.promotion_type} $integerType,
          ${OrderPromotionDetailFields.auto_apply} $textType,
          ${OrderPromotionDetailFields.sync_status} $integerType,
          ${OrderPromotionDetailFields.created_at} $textType,
          ${OrderPromotionDetailFields.updated_at} $textType,
          ${OrderPromotionDetailFields.soft_delete} $textType)''');

/*
    create app setting table
*/
    await db.execute('''CREATE TABLE $tableAppSetting(
          ${AppSettingFields.app_setting_sqlite_id} $idType,
          ${AppSettingFields.branch_id} $textType,
          ${AppSettingFields.open_cash_drawer} $integerType,
          ${AppSettingFields.show_second_display} $integerType,
          ${AppSettingFields.direct_payment} $integerType,
          ${AppSettingFields.print_checklist} $integerType,
          ${AppSettingFields.print_receipt} $integerType,
          ${AppSettingFields.show_sku} $integerType,
          ${AppSettingFields.qr_order_auto_accept} $integerType,
          ${AppSettingFields.enable_numbering} $integerType,
          ${AppSettingFields.starting_number} $integerType,
          ${AppSettingFields.table_order} $integerType,
          ${AppSettingFields.settlement_after_all_order_paid} $integerType,
          ${AppSettingFields.show_product_desc} $integerType,
          ${AppSettingFields.print_cancel_receipt} $integerType,
          ${AppSettingFields.product_sort_by} $integerType,
          ${AppSettingFields.dynamic_qr_default_exp_after_hour} $integerType,
          ${AppSettingFields.variant_item_sort_by} $integerType,
          ${AppSettingFields.dynamic_qr_invalid_after_payment} $integerType,
          ${AppSettingFields.required_cancel_reason} $integerType,
          ${AppSettingFields.qr_order_alert} $integerType,
          ${AppSettingFields.rounding_absorb} $integerType,
          ${AppSettingFields.sync_status} $integerType,
          ${AppSettingFields.created_at} $textType,
          ${AppSettingFields.updated_at} $textType)''');
/*
    create transfer owner table
*/
    await db.execute('''CREATE TABLE $tableTransferOwner(
          ${TransferOwnerFields.transfer_owner_sqlite_id} $idType,
          ${TransferOwnerFields.transfer_owner_key} $textType,
          ${TransferOwnerFields.branch_id} $textType,
          ${TransferOwnerFields.device_id} $textType,
          ${TransferOwnerFields.transfer_from_user_id} $textType,
          ${TransferOwnerFields.transfer_to_user_id} $textType,
          ${TransferOwnerFields.cash_balance} $textType,
          ${TransferOwnerFields.sync_status} $integerType,
          ${TransferOwnerFields.created_at} $textType,
          ${TransferOwnerFields.updated_at} $textType,
          ${TransferOwnerFields.soft_delete} $textType)''');
/*
    create settlement table
*/
    await db.execute('''CREATE TABLE $tableSettlement(
          ${SettlementFields.settlement_sqlite_id} $idType,
          ${SettlementFields.settlement_id} $integerType,
          ${SettlementFields.settlement_key} $textType,
          ${SettlementFields.company_id} $textType,
          ${SettlementFields.branch_id} $textType,
          ${SettlementFields.total_bill} $textType,
          ${SettlementFields.total_sales} $textType,
          ${SettlementFields.total_refund_bill} $textType,
          ${SettlementFields.total_refund_amount} $textType,
          ${SettlementFields.total_discount} $textType,
          ${SettlementFields.total_cancellation} $textType,
          ${SettlementFields.total_charge} $textType, 
          ${SettlementFields.total_tax} $textType, 
          ${SettlementFields.total_rounding} $textType, 
          ${SettlementFields.settlement_by_user_id} $textType,
          ${SettlementFields.settlement_by} $textType,
          ${SettlementFields.status} $integerType,
          ${SettlementFields.sync_status} $integerType,
          ${SettlementFields.opened_at} $textType,
          ${SettlementFields.created_at} $textType,
          ${SettlementFields.updated_at} $textType,
          ${SettlementFields.soft_delete} $textType)''');

/*
    create settlement link payment table
*/
    await db.execute('''CREATE TABLE $tableSettlementLinkPayment(
          ${SettlementLinkPaymentFields.settlement_link_payment_sqlite_id} $idType,
          ${SettlementLinkPaymentFields.settlement_link_payment_id} $integerType,
          ${SettlementLinkPaymentFields.settlement_link_payment_key} $textType,
          ${SettlementLinkPaymentFields.company_id} $textType,
          ${SettlementLinkPaymentFields.branch_id} $textType,
          ${SettlementLinkPaymentFields.settlement_sqlite_id} $textType,
          ${SettlementLinkPaymentFields.settlement_key} $textType,
          ${SettlementLinkPaymentFields.total_bill} $textType,
          ${SettlementLinkPaymentFields.total_sales} $textType,
          ${SettlementLinkPaymentFields.payment_link_company_id} $textType,
          ${SettlementLinkPaymentFields.status} $integerType,
          ${SettlementLinkPaymentFields.sync_status} $integerType,
          ${SettlementLinkPaymentFields.created_at} $textType,
          ${SettlementLinkPaymentFields.updated_at} $textType,
          ${SettlementLinkPaymentFields.soft_delete} $textType)''');

/*
    create order detail cancel table
*/
    await db.execute('''CREATE TABLE $tableOrderDetailCancel(
          ${OrderDetailCancelFields.order_detail_cancel_sqlite_id} $idType,
          ${OrderDetailCancelFields.order_detail_cancel_id} $integerType,
          ${OrderDetailCancelFields.order_detail_cancel_key} $textType,
          ${OrderDetailCancelFields.order_detail_sqlite_id} $textType,
          ${OrderDetailCancelFields.order_detail_key} $textType,
          ${OrderDetailCancelFields.quantity} $textType,
          ${OrderDetailCancelFields.quantity_before_cancel} $textType,
          ${OrderDetailCancelFields.cancel_by} $textType,
          ${OrderDetailCancelFields.cancel_by_user_id} $textType,
          ${OrderDetailCancelFields.cancel_reason} $textType,
          ${OrderDetailCancelFields.settlement_sqlite_id} $textType,
          ${OrderDetailCancelFields.settlement_key} $textType,
          ${OrderDetailCancelFields.status} $integerType,
          ${OrderDetailCancelFields.sync_status} $integerType,
          ${OrderDetailCancelFields.created_at} $textType,
          ${OrderDetailCancelFields.updated_at} $textType,
          ${OrderDetailCancelFields.soft_delete} $textType)''');

/*
    create checklist table
*/
    await db.execute('''CREATE TABLE $tableChecklist(
          ${ChecklistFields.checklist_sqlite_id} $idType,
          ${ChecklistFields.checklist_id} $integerType,
          ${ChecklistFields.checklist_key} $textType,
          ${ChecklistFields.branch_id} $textType,
          ${ChecklistFields.product_name_font_size} $integerType,
          ${ChecklistFields.other_font_size} $integerType,
          ${ChecklistFields.check_list_show_price} $integerType,
          ${ChecklistFields.check_list_show_separator} $integerType,
          ${ChecklistFields.paper_size} $textType,
          ${ChecklistFields.show_product_sku} $integerType,
          ${ChecklistFields.sync_status} $integerType,
          ${ChecklistFields.created_at} $textType,
          ${ChecklistFields.updated_at} $textType,
          ${ChecklistFields.soft_delete} $textType)''');

/*
    create second_screen table
*/
    await db.execute('''CREATE TABLE $tableSecondScreen(
          ${SecondScreenFields.second_screen_id} $idType,
          ${SecondScreenFields.company_id} $textType,
          ${SecondScreenFields.branch_id} $textType,
          ${SecondScreenFields.name} $textType,
          ${SecondScreenFields.sequence_number} $textType,
          ${SecondScreenFields.created_at} $textType,
          ${SecondScreenFields.soft_delete} $textType)''');

    /*
    create kitchen list table
*/
    await db.execute('''CREATE TABLE $tableKitchenList(
          ${KitchenListFields.kitchen_list_sqlite_id} $idType,
          ${KitchenListFields.kitchen_list_id} $integerType,
          ${KitchenListFields.kitchen_list_key} $textType,
          ${KitchenListFields.branch_id} $textType,
          ${KitchenListFields.product_name_font_size} $integerType,
          ${KitchenListFields.other_font_size} $integerType,
          ${KitchenListFields.paper_size} $textType,
          ${KitchenListFields.use_printer_label_as_title} $integerType,
          ${KitchenListFields.kitchen_list_show_price} $integerType,
          ${KitchenListFields.print_combine_kitchen_list} $integerType,
          ${KitchenListFields.kitchen_list_item_separator} $integerType,
          ${KitchenListFields.kitchen_list_show_total_amount} $integerType,
          ${KitchenListFields.show_product_sku} $integerType,
          ${KitchenListFields.sync_status} $integerType,
          ${KitchenListFields.created_at} $textType,
          ${KitchenListFields.updated_at} $textType,
          ${KitchenListFields.soft_delete} $textType)''');

    /*
    create dynamic qr table
*/
    await db.execute('''CREATE TABLE $tableDynamicQR(
          ${DynamicQRFields.dynamic_qr_sqlite_id} $idType,
          ${DynamicQRFields.dynamic_qr_id} $integerType,
          ${DynamicQRFields.dynamic_qr_key} $textType,
          ${DynamicQRFields.branch_id} $textType,
          ${DynamicQRFields.qr_code_size} $integerType,
          ${DynamicQRFields.paper_size} $textType,
          ${DynamicQRFields.footer_text} $textType,
          ${DynamicQRFields.sync_status} $integerType,
          ${DynamicQRFields.created_at} $textType,
          ${DynamicQRFields.updated_at} $textType,
          ${DynamicQRFields.soft_delete} $textType)''');



/*
    create order payment split table
*/
    await db.execute('''CREATE TABLE $tableOrderPaymentSplit(
          ${OrderPaymentSplitFields.order_payment_split_sqlite_id} $idType,
          ${OrderPaymentSplitFields.order_payment_split_id} $integerType,
          ${OrderPaymentSplitFields.order_payment_split_key} $textType,
          ${OrderPaymentSplitFields.branch_id} $textType,
          ${OrderPaymentSplitFields.payment_link_company_id} $textType,
          ${OrderPaymentSplitFields.amount} $textType,
          ${OrderPaymentSplitFields.payment_received} $textType,
          ${OrderPaymentSplitFields.payment_change} $textType,
          ${OrderPaymentSplitFields.order_key} $textType,
          ${OrderPaymentSplitFields.ipay_trans_id} $textType,
          ${OrderPaymentSplitFields.sync_status} $integerType,
          ${OrderPaymentSplitFields.created_at} $textType,
          ${OrderPaymentSplitFields.updated_at} $textType,
          ${OrderPaymentSplitFields.soft_delete} $textType)''');

/*
    create current version table
*/
    await db.execute('''CREATE TABLE $tableCurrentVersion(
          ${CurrentVersionFields.current_version_sqlite_id} $idType,
          ${CurrentVersionFields.current_version_id} $integerType,
          ${CurrentVersionFields.branch_id} $textType,
          ${CurrentVersionFields.current_version} $textType,
          ${CurrentVersionFields.platform} $integerType,
          ${CurrentVersionFields.is_gms} $integerType,
          ${CurrentVersionFields.source} $textType,
          ${CurrentVersionFields.sync_status} $integerType,
          ${CurrentVersionFields.created_at} $textType,
          ${CurrentVersionFields.updated_at} $textType,
          ${CurrentVersionFields.soft_delete} $textType)''');

/*
    create cancel receipt table
*/
    await db.execute('''CREATE TABLE $tableCancelReceipt(
          ${CancelReceiptFields.cancel_receipt_sqlite_id} $idType,
          ${CancelReceiptFields.cancel_receipt_id} $integerType,
          ${CancelReceiptFields.cancel_receipt_key} $textType,
          ${CancelReceiptFields.branch_id} $textType,
          ${CancelReceiptFields.product_name_font_size} $integerType,
          ${CancelReceiptFields.other_font_size} $integerType,
          ${CancelReceiptFields.paper_size} $textType,
          ${CancelReceiptFields.show_product_sku} $integerType,
          ${CancelReceiptFields.show_product_price} $integerType,
          ${CancelReceiptFields.sync_status} $integerType,
          ${CancelReceiptFields.created_at} $textType,
          ${CancelReceiptFields.updated_at} $textType,
          ${CancelReceiptFields.soft_delete} $textType)''');

/*
    create sales per day table
*/
    await db.execute('''CREATE TABLE $tableSalesPerDay(
          ${SalesPerDayFields.sales_per_day_sqlite_id} $idType,
          ${SalesPerDayFields.sales_per_day_id} $integerType,
          ${SalesPerDayFields.branch_id} $textType,
          ${SalesPerDayFields.total_amount} $textType,
          ${SalesPerDayFields.tax} $textType,
          ${SalesPerDayFields.charge} $textType,
          ${SalesPerDayFields.promotion} $textType,
          ${SalesPerDayFields.rounding} $textType,
          ${SalesPerDayFields.date} $textType,
          ${SalesPerDayFields.payment_method} $textType,
          ${SalesPerDayFields.payment_method_sales} $textType,
          ${SalesPerDayFields.type} $integerType,
          ${SalesPerDayFields.sync_status} $integerType,
          ${SalesPerDayFields.created_at} $textType,
          ${SalesPerDayFields.updated_at} $textType,
          ${SalesPerDayFields.soft_delete} $textType)''');

/*
    create category sales per day table
*/
    await db.execute('''CREATE TABLE $tableSalesCategoryPerDay(
          ${SalesCategoryPerDayFields.sales_category_per_day_sqlite_id} $idType,
          ${SalesCategoryPerDayFields.sales_category_per_day_id} $integerType,
          ${SalesCategoryPerDayFields.branch_id} $textType,
          ${SalesCategoryPerDayFields.category_id} $textType,
          ${SalesCategoryPerDayFields.category_name} $textType,
          ${SalesCategoryPerDayFields.amount_sold} $textType,
          ${SalesCategoryPerDayFields.total_amount} $textType,
          ${SalesCategoryPerDayFields.total_ori_amount} $textType,
          ${SalesCategoryPerDayFields.date} $textType,
          ${SalesCategoryPerDayFields.type} $integerType,
          ${SalesCategoryPerDayFields.sync_status} $integerType,
          ${SalesCategoryPerDayFields.created_at} $textType,
          ${SalesCategoryPerDayFields.updated_at} $textType,
          ${SalesCategoryPerDayFields.soft_delete} $textType)''');

/*
    create product sales per day table
*/
    await db.execute('''CREATE TABLE $tableSalesProductPerDay(
          ${SalesProductPerDayFields.sales_product_per_day_sqlite_id} $idType,
          ${SalesProductPerDayFields.sales_product_per_day_id} $integerType,
          ${SalesProductPerDayFields.branch_id} $textType,
          ${SalesProductPerDayFields.product_id} $textType,
          ${SalesProductPerDayFields.product_name} $textType,
          ${SalesProductPerDayFields.amount_sold} $textType,
          ${SalesProductPerDayFields.total_amount} $textType,
          ${SalesProductPerDayFields.total_ori_amount} $textType,
          ${SalesProductPerDayFields.date} $textType,
          ${SalesProductPerDayFields.type} $integerType,
          ${SalesProductPerDayFields.sync_status} $integerType,
          ${SalesProductPerDayFields.created_at} $textType,
          ${SalesProductPerDayFields.updated_at} $textType,
          ${SalesProductPerDayFields.soft_delete} $textType)''');

/*
    create modifier sales per day table
*/
    await db.execute('''CREATE TABLE $tableSalesModifierPerDay(
          ${SalesModifierPerDayFields.sales_modifier_per_day_sqlite_id} $idType,
          ${SalesModifierPerDayFields.sales_modifier_per_day_id} $integerType,
          ${SalesModifierPerDayFields.branch_id} $textType,
          ${SalesModifierPerDayFields.mod_item_id} $textType,
          ${SalesModifierPerDayFields.mod_group_id} $textType,
          ${SalesModifierPerDayFields.modifier_name} $textType,
          ${SalesModifierPerDayFields.modifier_group_name} $textType,
          ${SalesModifierPerDayFields.amount_sold} $textType,
          ${SalesModifierPerDayFields.total_amount} $textType,
          ${SalesModifierPerDayFields.total_ori_amount} $textType,
          ${SalesModifierPerDayFields.date} $textType,
          ${SalesModifierPerDayFields.type} $integerType,
          ${SalesModifierPerDayFields.sync_status} $integerType,
          ${SalesModifierPerDayFields.created_at} $textType,
          ${SalesModifierPerDayFields.updated_at} $textType,
          ${SalesModifierPerDayFields.soft_delete} $textType)''');

/*
    create dining sales per day table
*/
    await db.execute('''CREATE TABLE $tableSalesDiningPerDay(
          ${SalesDiningPerDayFields.sales_dining_per_day_sqlite_id} $idType,
          ${SalesDiningPerDayFields.sales_dining_per_day_id} $integerType,
          ${SalesDiningPerDayFields.branch_id} $textType,
          ${SalesDiningPerDayFields.dine_in} $textType,
          ${SalesDiningPerDayFields.take_away} $textType,
          ${SalesDiningPerDayFields.delivery} $textType,
          ${SalesDiningPerDayFields.date} $textType,
          ${SalesDiningPerDayFields.type} $integerType,
          ${SalesDiningPerDayFields.sync_status} $integerType,
          ${SalesDiningPerDayFields.created_at} $textType,
          ${SalesDiningPerDayFields.updated_at} $textType,
          ${SalesDiningPerDayFields.soft_delete} $textType)''');

  }

  static dbVersion33Upgrade(Database db, SharedPreferences prefs) async {
    await db.execute("ALTER TABLE $tableSettlement ADD ${SettlementFields.total_rounding} $textType DEFAULT ''");
    await db.execute("ALTER TABLE $tableBranch ADD ${BranchFields.generate_sales} $integerType DEFAULT 0");
    final branchResult = await db.rawQuery('SELECT * FROM $tableBranch LIMIT 1');
    Branch branchData = Branch.fromJson(branchResult.first);
    await prefs.setString("branch", json.encode(branchData));
    //create sales per day table
    await db.execute('''CREATE TABLE $tableSalesPerDay(
          ${SalesPerDayFields.sales_per_day_sqlite_id} $idType,
          ${SalesPerDayFields.sales_per_day_id} $integerType,
          ${SalesPerDayFields.branch_id} $textType,
          ${SalesPerDayFields.total_amount} $textType,
          ${SalesPerDayFields.tax} $textType,
          ${SalesPerDayFields.charge} $textType,
          ${SalesPerDayFields.promotion} $textType,
          ${SalesPerDayFields.rounding} $textType,
          ${SalesPerDayFields.date} $textType,
          ${SalesPerDayFields.payment_method} $textType,
          ${SalesPerDayFields.payment_method_sales} $textType,
          ${SalesPerDayFields.type} $integerType,
          ${SalesPerDayFields.sync_status} $integerType,
          ${SalesPerDayFields.created_at} $textType,
          ${SalesPerDayFields.updated_at} $textType,
          ${SalesPerDayFields.soft_delete} $textType)''');
    //create category sales per day table
    await db.execute('''CREATE TABLE $tableSalesCategoryPerDay(
          ${SalesCategoryPerDayFields.sales_category_per_day_sqlite_id} $idType,
          ${SalesCategoryPerDayFields.sales_category_per_day_id} $integerType,
          ${SalesCategoryPerDayFields.branch_id} $textType,
          ${SalesCategoryPerDayFields.category_id} $textType,
          ${SalesCategoryPerDayFields.category_name} $textType,
          ${SalesCategoryPerDayFields.amount_sold} $textType,
          ${SalesCategoryPerDayFields.total_amount} $textType,
          ${SalesCategoryPerDayFields.total_ori_amount} $textType,
          ${SalesCategoryPerDayFields.date} $textType,
          ${SalesCategoryPerDayFields.type} $integerType,
          ${SalesCategoryPerDayFields.sync_status} $integerType,
          ${SalesCategoryPerDayFields.created_at} $textType,
          ${SalesCategoryPerDayFields.updated_at} $textType,
          ${SalesCategoryPerDayFields.soft_delete} $textType)''');
    //create product sales per day
    await db.execute('''CREATE TABLE $tableSalesProductPerDay(
          ${SalesProductPerDayFields.sales_product_per_day_sqlite_id} $idType,
          ${SalesProductPerDayFields.sales_product_per_day_id} $integerType,
          ${SalesProductPerDayFields.branch_id} $textType,
          ${SalesProductPerDayFields.product_id} $textType,
          ${SalesProductPerDayFields.product_name} $textType,
          ${SalesProductPerDayFields.amount_sold} $textType,
          ${SalesProductPerDayFields.total_amount} $textType,
          ${SalesProductPerDayFields.total_ori_amount} $textType,
          ${SalesProductPerDayFields.date} $textType,
          ${SalesProductPerDayFields.type} $integerType,
          ${SalesProductPerDayFields.sync_status} $integerType,
          ${SalesProductPerDayFields.created_at} $textType,
          ${SalesProductPerDayFields.updated_at} $textType,
          ${SalesProductPerDayFields.soft_delete} $textType)''');
    //create modifier sales per day
    await db.execute('''CREATE TABLE $tableSalesModifierPerDay(
          ${SalesModifierPerDayFields.sales_modifier_per_day_sqlite_id} $idType,
          ${SalesModifierPerDayFields.sales_modifier_per_day_id} $integerType,
          ${SalesModifierPerDayFields.branch_id} $textType,
          ${SalesModifierPerDayFields.mod_item_id} $textType,
          ${SalesModifierPerDayFields.mod_group_id} $textType,
          ${SalesModifierPerDayFields.modifier_name} $textType,
          ${SalesModifierPerDayFields.modifier_group_name} $textType,
          ${SalesModifierPerDayFields.amount_sold} $textType,
          ${SalesModifierPerDayFields.total_amount} $textType,
          ${SalesModifierPerDayFields.total_ori_amount} $textType,
          ${SalesModifierPerDayFields.date} $textType,
          ${SalesModifierPerDayFields.type} $integerType,
          ${SalesModifierPerDayFields.sync_status} $integerType,
          ${SalesModifierPerDayFields.created_at} $textType,
          ${SalesModifierPerDayFields.updated_at} $textType,
          ${SalesModifierPerDayFields.soft_delete} $textType)''');
    //create dining sales per day table
    await db.execute('''CREATE TABLE $tableSalesDiningPerDay(
          ${SalesDiningPerDayFields.sales_dining_per_day_sqlite_id} $idType,
          ${SalesDiningPerDayFields.sales_dining_per_day_id} $integerType,
          ${SalesDiningPerDayFields.branch_id} $textType,
          ${SalesDiningPerDayFields.dine_in} $textType,
          ${SalesDiningPerDayFields.take_away} $textType,
          ${SalesDiningPerDayFields.delivery} $textType,
          ${SalesDiningPerDayFields.date} $textType,
          ${SalesDiningPerDayFields.type} $integerType,
          ${SalesDiningPerDayFields.sync_status} $integerType,
          ${SalesDiningPerDayFields.created_at} $textType,
          ${SalesDiningPerDayFields.updated_at} $textType,
          ${SalesDiningPerDayFields.soft_delete} $textType)''');
  }

  static dbVersion31Upgrade(Database db) async {
    //modifier quantity
    await db.execute("ALTER TABLE $tableModifierGroup ADD ${ModifierGroupFields.min_select} $integerType DEFAULT 0");
    await db.execute("ALTER TABLE $tableModifierGroup ADD ${ModifierGroupFields.max_select} $integerType DEFAULT 0");
    //tb app setting required cancel reason
    await db.execute("ALTER TABLE $tableAppSetting ADD ${AppSettingFields.required_cancel_reason} $integerType DEFAULT 0");
    //tb order cancel new field: quantity before cancel
    await db.execute("ALTER TABLE $tableOrderDetailCancel ADD ${OrderDetailCancelFields.quantity_before_cancel} $textType DEFAULT '' ");
    await db.execute("ALTER TABLE $tableOrderDetailCancel ADD ${OrderDetailCancelFields.cancel_reason} $textType DEFAULT '' ");
    // new table cancel_receipt
    await db.execute('''CREATE TABLE $tableCancelReceipt(
            ${CancelReceiptFields.cancel_receipt_sqlite_id} $idType,
            ${CancelReceiptFields.cancel_receipt_id} $integerType,
            ${CancelReceiptFields.cancel_receipt_key} $textType,
            ${CancelReceiptFields.branch_id} $textType,
            ${CancelReceiptFields.product_name_font_size} $integerType,
            ${CancelReceiptFields.other_font_size} $integerType,
            ${CancelReceiptFields.paper_size} $textType,
            ${CancelReceiptFields.show_product_sku} $integerType,
            ${CancelReceiptFields.show_product_price} $integerType,
            ${CancelReceiptFields.sync_status} $integerType,
            ${CancelReceiptFields.created_at} $textType,
            ${CancelReceiptFields.updated_at} $textType,
            ${CancelReceiptFields.soft_delete} $textType)''');
  }

  static dbVersion30Upgrade(Database db, SharedPreferences prefs) async {
    await db.execute("ALTER TABLE $tableBranch ADD ${BranchFields.qr_show_sku} $integerType DEFAULT 1");
    await db.execute("ALTER TABLE $tableBranch ADD ${BranchFields.qr_product_sequence} $integerType DEFAULT 0");
    await db.execute("ALTER TABLE $tableBranch ADD ${BranchFields.show_qr_history} $textType DEFAULT '0' ");
    final branchResult = await db.rawQuery('SELECT * FROM $tableBranch LIMIT 1');
    Branch branchData = Branch.fromJson(branchResult.first);
    await prefs.setString("branch", json.encode(branchData));
  }

  static dbVersion29Upgrade(Database db, SharedPreferences prefs) async {
    final int? branch_id = prefs.getInt('branch_id');
    if(branch_id == 182 || branch_id == 176 || branch_id == 201){
      await db.rawUpdate('UPDATE $tableOrderCache SET sync_status = ? WHERE qr_order = ? ', [0, 1]);
      final result = await db.rawQuery('SELECT * FROM $tableOrderCache WHERE qr_order = ? AND soft_delete = ?', [1, '']);
      List<OrderCache> orderCacheData = result.map((json) => OrderCache.fromJson(json)).toList();
      for(var orderCache in orderCacheData){
        await db.rawUpdate('UPDATE $tableOrderDetail SET sync_status = ? WHERE order_cache_sqlite_id = ? ', [0, orderCache.order_cache_sqlite_id]);
        final result = await db.rawQuery('SELECT * FROM $tableOrderDetail WHERE sync_status = ? AND soft_delete = ?', [0, '']);
        List<OrderDetail> orderDetailData = result.map((json) => OrderDetail.fromJson(json)).toList();
        for(var orderDetail in orderDetailData){
          await db.rawUpdate('UPDATE $tableOrderModifierDetail SET sync_status = ? WHERE order_detail_sqlite_id = ? ', [0, orderDetail.order_detail_sqlite_id]);
        }
      }
    }
  }

  static dbVersion27Upgrade(Database db) async {
    bool columnExists = await checkColumnExists(db, tableKitchenList!, KitchenListFields.kitchen_list_show_total_amount);
    print("db 27 column exist: ${columnExists}");
    if(!columnExists) {
      print("perform upgrade");
      await db.execute("ALTER TABLE $tableKitchenList ADD ${KitchenListFields.kitchen_list_show_total_amount} $integerType DEFAULT 0 ");
      await db.execute("ALTER TABLE $tablePrinter ADD ${PrinterFields.is_kitchen_checklist} $integerType DEFAULT 0 ");
      await db.execute("ALTER TABLE $tableReceipt ADD ${ReceiptFields.show_break_down_price} $integerType DEFAULT 0 ");
      await db.execute("ALTER TABLE $tableAppSetting ADD ${AppSettingFields.settlement_after_all_order_paid} $integerType DEFAULT 0");
    }
  }

  static dbVersion26Upgrade(Database db, SharedPreferences prefs) async {
    bool columnExists = await checkColumnExists(db, tableBranch!, BranchFields.company_id);
    print("db 26 column exist: ${columnExists}");
    if(!columnExists){
      print("perform upgrade");
      //rename tb_branch.branchID -> branch_id (old way)
      //create a new table
      await db.execute('''CREATE TABLE tb_branch_copy (
           ${BranchFields.branch_id} $idType,
           ${BranchFields.branch_url} $textType,
           ${BranchFields.name} $textType,
           ${BranchFields.address} $textType,
           ${BranchFields.phone} $textType,
           ${BranchFields.email} $textType,
           ${BranchFields.ipay_merchant_code} $textType,
           ${BranchFields.ipay_merchant_key} $textType,
           ${BranchFields.notification_token} $textType,
           ${BranchFields.qr_order_status} $textType,
           ${BranchFields.sub_pos_status} $integerType,
           ${BranchFields.attendance_status} $integerType)''');
      //insert data from old table tb_branch
      await db.execute('''INSERT INTO tb_branch_copy (
            branch_id, branch_url, name, address, phone, email, ipay_merchant_code, ipay_merchant_key,
            notification_token,qr_order_status,sub_pos_status, attendance_status) 
            SELECT branchID, branch_url, name, address, phone, email, ipay_merchant_code, ipay_merchant_key,
            notification_token, qr_order_status, sub_pos_status, attendance_status FROM $tableBranch ''');
      //remove old table tb_branch
      await db.execute("DROP TABLE $tableBranch");
      //rename new created table name
      await db.execute("ALTER TABLE tb_branch_copy RENAME TO $tableBranch");
      //other upgrade
      final result = await db.rawQuery('SELECT company_id FROM $tableProduct WHERE soft_delete = ? LIMIT 1', ['']);
      Product productData = Product.fromJson(result.first);
      await db.execute("ALTER TABLE $tableBranch ADD ${BranchFields.company_id} $textType DEFAULT ${productData.company_id}");
      await db.execute("ALTER TABLE $tableBranch ADD ${BranchFields.working_day} $textType DEFAULT '\[0, 0, 0, 0, 0, 0, 0\]' ");
      await db.execute("ALTER TABLE $tableBranch ADD ${BranchFields.working_time} $textType DEFAULT '\[\"00:00\", \"23:59\"\]' ");
      await db.execute("ALTER TABLE $tableBranch ADD ${BranchFields.register_no} $textType DEFAULT '' ");
      await db.execute("ALTER TABLE $tableBranch ADD ${BranchFields.close_qr_order} $integerType DEFAULT 0 ");
      await db.execute("ALTER TABLE $tableProduct ADD ${ProductFields.show_in_qr} $integerType DEFAULT 1");
      await db.execute("ALTER TABLE $tableDiningOption ADD ${DiningOptionFields.company_id} $textType DEFAULT '${productData.company_id}' ");
      await db.execute("ALTER TABLE $tableAppSetting ADD ${AppSettingFields.dynamic_qr_invalid_after_payment} $integerType DEFAULT 1");
      await db.execute("ALTER TABLE $tableReceipt ADD ${ReceiptFields.show_register_no} $integerType DEFAULT 0");
      final branchResult = await db.rawQuery('SELECT * FROM $tableBranch LIMIT 1');
      Branch branchData = Branch.fromJson(branchResult.first);
      await prefs.setString("branch", json.encode(branchData));
    }
  }

  static Future<bool> checkColumnExists(Database db, String tableName, String columnName) async {
    // Query to check if the column already exists
    var result = await db.rawQuery("PRAGMA table_info($tableName)");
    bool columnExists = result.any((column) => column['name'] == columnName);
    return columnExists;
  }
}