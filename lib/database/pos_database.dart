import 'dart:convert';

import 'package:pos_system/object/app_setting.dart';
import 'package:pos_system/object/attendance.dart';
import 'package:pos_system/object/bill.dart';
import 'package:pos_system/object/branch.dart';
import 'package:pos_system/object/branch_link_user.dart';
import 'package:pos_system/object/cash_record.dart';
import 'package:pos_system/object/categories.dart';
import 'package:pos_system/object/customer.dart';
import 'package:pos_system/object/dining_option.dart';
import 'package:pos_system/object/kitchen_list.dart';
import 'package:pos_system/object/modifier_group.dart';
import 'package:pos_system/object/modifier_item.dart';
import 'package:pos_system/object/modifier_link_product.dart';
import 'package:pos_system/object/order.dart';
import 'package:pos_system/object/order_cache.dart';
import 'package:pos_system/object/order_detail.dart';
import 'package:pos_system/object/order_detail_cancel.dart';
import 'package:pos_system/object/order_detail_link_tax.dart';
import 'package:pos_system/object/order_modifier_detail.dart';
import 'package:pos_system/object/order_payment_split.dart';
import 'package:pos_system/object/order_tax_detail.dart';
import 'package:pos_system/object/payment_link_company.dart';
import 'package:pos_system/object/printer_link_category.dart';
import 'package:pos_system/object/product.dart';
import 'package:pos_system/object/product_variant.dart';
import 'package:pos_system/object/product_variant_detail.dart';
import 'package:pos_system/object/promotion.dart';
import 'package:pos_system/object/receipt.dart';
import 'package:pos_system/object/refund.dart';
import 'package:pos_system/object/sale.dart';
import 'package:pos_system/object/settlement.dart';
import 'package:pos_system/object/subscription.dart';
import 'package:pos_system/object/table.dart';
import 'package:pos_system/object/table_use.dart';
import 'package:pos_system/object/table_use_detail.dart';
import 'package:pos_system/object/tax.dart';
import 'package:pos_system/object/tax_link_dining.dart';
import 'package:pos_system/object/transfer_owner.dart';
import 'package:pos_system/object/user.dart';
import 'package:pos_system/object/user_log.dart';
import 'package:pos_system/object/variant_group.dart';
import 'package:pos_system/object/variant_item.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../object/branch_link_dining_option.dart';
import '../object/branch_link_modifier.dart';
import '../object/branch_link_product.dart';
import '../object/branch_link_promotion.dart';
import '../object/branch_link_tax.dart';
import '../object/checklist.dart';
import '../object/color.dart';
import '../object/order_detail_link_promotion.dart';
import '../object/order_promotion_detail.dart';
import '../object/printer.dart';
import '../object/second_screen.dart';
import '../object/settlement_link_payment.dart';

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
    return await openDatabase(path, version: 17, onCreate: _createDB, onUpgrade: _onUpgrade);
  }

  void _onUpgrade(Database db, int oldVersion, int newVersion) async {
    final idType = 'INTEGER PRIMARY KEY AUTOINCREMENT';
    final textType = 'TEXT NOT NULL';
    final integerType = 'INTEGER NOT NULL';
    //get branch id pref
    final prefs = await SharedPreferences.getInstance();
    final String? branch_id = prefs.getInt('branch_id').toString();

    if (oldVersion < newVersion) {
      // you can execute drop table and create table
      switch (oldVersion) {
        case 5: {
          await db.execute("ALTER TABLE $tablePosTable ADD ${PosTableFields.dy} TEXT NOT NULL DEFAULT '' ");
          await db.execute("ALTER TABLE $tablePosTable ADD ${PosTableFields.dx} TEXT NOT NULL DEFAULT '' ");
          //new version
          await db.execute("ALTER TABLE $tableProduct ADD ${ProductFields.unit} TEXT NOT NULL DEFAULT 'each' ");
          await db.execute("ALTER TABLE $tableProduct ADD ${ProductFields.per_quantity_unit} TEXT NOT NULL DEFAULT '' ");
          await db.execute("ALTER TABLE $tableProduct ADD ${ProductFields.sequence_number} TEXT NOT NULL DEFAULT '' ");
          await db.execute("ALTER TABLE $tableOrderDetail ADD ${OrderDetailFields.unit} TEXT NOT NULL DEFAULT '' ");
          await db.execute("ALTER TABLE $tableOrderDetail ADD ${OrderDetailFields.per_quantity_unit} TEXT NOT NULL DEFAULT '' ");
        }break;
        case 6: {
          await db.execute("ALTER TABLE $tableProduct ADD ${ProductFields.unit} TEXT NOT NULL DEFAULT 'each' ");
          await db.execute("ALTER TABLE $tableProduct ADD ${ProductFields.per_quantity_unit} TEXT NOT NULL DEFAULT '' ");
          await db.execute("ALTER TABLE $tableProduct ADD ${ProductFields.sequence_number} TEXT NOT NULL DEFAULT '' ");
          await db.execute("ALTER TABLE $tableOrderDetail ADD ${OrderDetailFields.unit} TEXT NOT NULL DEFAULT '' ");
          await db.execute("ALTER TABLE $tableOrderDetail ADD ${OrderDetailFields.per_quantity_unit} TEXT NOT NULL DEFAULT '' ");
          //new field
          await db.execute("ALTER TABLE $tableModifierGroup ADD ${ModifierGroupFields.sequence_number} TEXT NOT NULL DEFAULT '' ");
        }break;
        case 7: {
          await db.execute("ALTER TABLE $tableModifierGroup ADD ${ModifierGroupFields.sequence_number} TEXT NOT NULL DEFAULT '' ");
          //new
          await db.execute('''CREATE TABLE $tableSecondScreen(
          ${SecondScreenFields.second_screen_id} $idType,
          ${SecondScreenFields.company_id} $textType,
          ${SecondScreenFields.branch_id} $textType,
          ${SecondScreenFields.name} $textType,
          ${SecondScreenFields.sequence_number} $textType,
          ${SecondScreenFields.created_at} $textType,
          ${SecondScreenFields.soft_delete} $textType)''');

          await db.execute("ALTER TABLE $tableAppSetting ADD ${AppSettingFields.branch_id} TEXT NOT NULL DEFAULT '$branch_id' ");
          await db.execute("ALTER TABLE $tableAppSetting ADD ${AppSettingFields.enable_numbering} INTEGER NOT NULL DEFAULT 0");
          await db.execute("ALTER TABLE $tableAppSetting ADD ${AppSettingFields.starting_number} INTEGER NOT NULL DEFAULT 0");
          await db.execute("ALTER TABLE $tableAppSetting ADD ${AppSettingFields.table_order} INTEGER NOT NULL DEFAULT 1");
          await db.execute("ALTER TABLE $tableAppSetting ADD ${AppSettingFields.sync_status} INTEGER NOT NULL DEFAULT 0");
          await db.execute("ALTER TABLE $tableAppSetting ADD ${AppSettingFields.created_at} TEXT NOT NULL DEFAULT '' ");
          await db.execute("ALTER TABLE $tableAppSetting ADD ${AppSettingFields.updated_at} TEXT NOT NULL DEFAULT '' ");
          await db.execute("ALTER TABLE $tableOrderCache ADD ${OrderCacheFields.order_queue} TEXT NOT NULL DEFAULT '' ");
          await db.execute("ALTER TABLE $tableOrder ADD ${OrderFields.order_queue} TEXT NOT NULL DEFAULT '' ");
          await db.execute("ALTER TABLE $tablePrinter ADD ${PrinterFields.is_label} INTEGER NOT NULL DEFAULT 0");
          await db.execute('''CREATE TABLE $tableKitchenList(
          ${KitchenListFields.kitchen_list_sqlite_id} $idType,
          ${KitchenListFields.kitchen_list_id} $integerType,
          ${KitchenListFields.kitchen_list_key} $textType,
          ${KitchenListFields.branch_id} $textType,
          ${KitchenListFields.product_name_font_size} $integerType,
          ${KitchenListFields.other_font_size} $integerType,
          ${KitchenListFields.paper_size} $textType,
          ${KitchenListFields.kitchen_list_show_price} $integerType,
          ${KitchenListFields.print_combine_kitchen_list} $integerType,
          ${KitchenListFields.kitchen_list_item_separator} $integerType,
          ${KitchenListFields.sync_status} $integerType,
          ${KitchenListFields.created_at} $textType,
          ${KitchenListFields.updated_at} $textType,
          ${KitchenListFields.soft_delete} $textType)''');
          //new
          await db.execute("ALTER TABLE $tableAppSetting ADD ${AppSettingFields.print_receipt} INTEGER NOT NULL DEFAULT 1");
          await db.execute("ALTER TABLE $tablePaymentLinkCompany ADD ${PaymentLinkCompanyFields.allow_image} $integerType DEFAULT 0");
          await db.execute("ALTER TABLE $tablePaymentLinkCompany ADD ${PaymentLinkCompanyFields.image_name} $textType DEFAULT '' ");
          //new case 12
          await db.execute("ALTER TABLE $tableOrderDetail ADD ${OrderDetailFields.edited_by} TEXT NOT NULL DEFAULT '' ");
          await db.execute("ALTER TABLE $tableOrderDetail ADD ${OrderDetailFields.edited_by_user_id} TEXT NOT NULL DEFAULT '' ");
          await db.execute("ALTER TABLE $tableChecklist ADD ${ChecklistFields.check_list_show_price} INTEGER NOT NULL DEFAULT 0");
          await db.execute("ALTER TABLE $tableChecklist ADD ${ChecklistFields.check_list_show_separator} INTEGER NOT NULL DEFAULT 0");
          await db.execute("ALTER TABLE $tableUser ADD ${UserFields.edit_price_without_pin} INTEGER NOT NULL DEFAULT 0");
          //new case 13
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
        case 8 :{
          await db.execute('''CREATE TABLE $tableSecondScreen(
          ${SecondScreenFields.second_screen_id} $idType,
          ${SecondScreenFields.company_id} $textType,
          ${SecondScreenFields.branch_id} $textType,
          ${SecondScreenFields.name} $textType,
          ${SecondScreenFields.sequence_number} $textType,
          ${SecondScreenFields.created_at} $textType,
          ${SecondScreenFields.soft_delete} $textType)''');
          //new
          await db.execute("ALTER TABLE $tableAppSetting ADD ${AppSettingFields.branch_id} TEXT NOT NULL DEFAULT '$branch_id' ");
          await db.execute("ALTER TABLE $tableAppSetting ADD ${AppSettingFields.enable_numbering} INTEGER NOT NULL DEFAULT 0");
          await db.execute("ALTER TABLE $tableAppSetting ADD ${AppSettingFields.starting_number} INTEGER NOT NULL DEFAULT 0");
          await db.execute("ALTER TABLE $tableAppSetting ADD ${AppSettingFields.table_order} INTEGER NOT NULL DEFAULT 1");
          await db.execute("ALTER TABLE $tableAppSetting ADD ${AppSettingFields.sync_status} INTEGER NOT NULL DEFAULT 0");
          await db.execute("ALTER TABLE $tableAppSetting ADD ${AppSettingFields.created_at} TEXT NOT NULL DEFAULT '' ");
          await db.execute("ALTER TABLE $tableAppSetting ADD ${AppSettingFields.updated_at} TEXT NOT NULL DEFAULT '' ");
          await db.execute("ALTER TABLE $tableOrderCache ADD ${OrderCacheFields.order_queue} TEXT NOT NULL DEFAULT '' ");
          await db.execute("ALTER TABLE $tableOrder ADD ${OrderFields.order_queue} TEXT NOT NULL DEFAULT '' ");
          await db.execute("ALTER TABLE $tablePrinter ADD ${PrinterFields.is_label} INTEGER NOT NULL DEFAULT 0");
          await db.execute('''CREATE TABLE $tableKitchenList(
          ${KitchenListFields.kitchen_list_sqlite_id} $idType,
          ${KitchenListFields.kitchen_list_id} $integerType,
          ${KitchenListFields.kitchen_list_key} $textType,
          ${KitchenListFields.branch_id} $textType,
          ${KitchenListFields.product_name_font_size} $integerType,
          ${KitchenListFields.other_font_size} $integerType,
          ${KitchenListFields.paper_size} $textType,
          ${KitchenListFields.kitchen_list_show_price} $integerType,
          ${KitchenListFields.print_combine_kitchen_list} $integerType,
          ${KitchenListFields.kitchen_list_item_separator} $integerType,
          ${KitchenListFields.sync_status} $integerType,
          ${KitchenListFields.created_at} $textType,
          ${KitchenListFields.updated_at} $textType,
          ${KitchenListFields.soft_delete} $textType)''');
          //new
          await db.execute("ALTER TABLE $tableAppSetting ADD ${AppSettingFields.print_receipt} INTEGER NOT NULL DEFAULT 1");
          await db.execute("ALTER TABLE $tablePaymentLinkCompany ADD ${PaymentLinkCompanyFields.allow_image} $integerType DEFAULT 0");
          await db.execute("ALTER TABLE $tablePaymentLinkCompany ADD ${PaymentLinkCompanyFields.image_name} $textType DEFAULT '' ");
          //new case 12
          await db.execute("ALTER TABLE $tableOrderDetail ADD ${OrderDetailFields.edited_by} TEXT NOT NULL DEFAULT '' ");
          await db.execute("ALTER TABLE $tableOrderDetail ADD ${OrderDetailFields.edited_by_user_id} TEXT NOT NULL DEFAULT '' ");
          await db.execute("ALTER TABLE $tableChecklist ADD ${ChecklistFields.check_list_show_price} INTEGER NOT NULL DEFAULT 0");
          await db.execute("ALTER TABLE $tableChecklist ADD ${ChecklistFields.check_list_show_separator} INTEGER NOT NULL DEFAULT 0");
          await db.execute("ALTER TABLE $tableUser ADD ${UserFields.edit_price_without_pin} INTEGER NOT NULL DEFAULT 0");
          //new case 13
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
        case 9: {
          await db.execute("ALTER TABLE $tableAppSetting ADD ${AppSettingFields.branch_id} TEXT NOT NULL DEFAULT '$branch_id' ");
          await db.execute("ALTER TABLE $tableAppSetting ADD ${AppSettingFields.enable_numbering} INTEGER NOT NULL DEFAULT 0");
          await db.execute("ALTER TABLE $tableAppSetting ADD ${AppSettingFields.starting_number} INTEGER NOT NULL DEFAULT 0");
          await db.execute("ALTER TABLE $tableAppSetting ADD ${AppSettingFields.table_order} INTEGER NOT NULL DEFAULT 1");
          await db.execute("ALTER TABLE $tableAppSetting ADD ${AppSettingFields.sync_status} INTEGER NOT NULL DEFAULT 0");
          await db.execute("ALTER TABLE $tableAppSetting ADD ${AppSettingFields.created_at} TEXT NOT NULL DEFAULT '' ");
          await db.execute("ALTER TABLE $tableAppSetting ADD ${AppSettingFields.updated_at} TEXT NOT NULL DEFAULT '' ");
          await db.execute("ALTER TABLE $tableOrderCache ADD ${OrderCacheFields.order_queue} TEXT NOT NULL DEFAULT '' ");
          await db.execute("ALTER TABLE $tableOrder ADD ${OrderFields.order_queue} TEXT NOT NULL DEFAULT '' ");
          await db.execute("ALTER TABLE $tablePrinter ADD ${PrinterFields.is_label} INTEGER NOT NULL DEFAULT 0");
          await db.execute('''CREATE TABLE $tableKitchenList(
          ${KitchenListFields.kitchen_list_sqlite_id} $idType,
          ${KitchenListFields.kitchen_list_id} $integerType,
          ${KitchenListFields.kitchen_list_key} $textType,
          ${KitchenListFields.branch_id} $textType,
          ${KitchenListFields.product_name_font_size} $integerType,
          ${KitchenListFields.other_font_size} $integerType,
          ${KitchenListFields.paper_size} $textType,
          ${KitchenListFields.kitchen_list_show_price} $integerType,
          ${KitchenListFields.print_combine_kitchen_list} $integerType,
          ${KitchenListFields.kitchen_list_item_separator} $integerType,
          ${KitchenListFields.sync_status} $integerType,
          ${KitchenListFields.created_at} $textType,
          ${KitchenListFields.updated_at} $textType,
          ${KitchenListFields.soft_delete} $textType)''');
          //new
          await db.execute("ALTER TABLE $tableAppSetting ADD ${AppSettingFields.print_receipt} INTEGER NOT NULL DEFAULT 1");
          await db.execute("ALTER TABLE $tablePaymentLinkCompany ADD ${PaymentLinkCompanyFields.allow_image} $integerType DEFAULT 0");
          await db.execute("ALTER TABLE $tablePaymentLinkCompany ADD ${PaymentLinkCompanyFields.image_name} $textType DEFAULT '' ");
          //new case 12
          await db.execute("ALTER TABLE $tableOrderDetail ADD ${OrderDetailFields.edited_by} TEXT NOT NULL DEFAULT '' ");
          await db.execute("ALTER TABLE $tableOrderDetail ADD ${OrderDetailFields.edited_by_user_id} TEXT NOT NULL DEFAULT '' ");
          await db.execute("ALTER TABLE $tableChecklist ADD ${ChecklistFields.check_list_show_price} INTEGER NOT NULL DEFAULT 0");
          await db.execute("ALTER TABLE $tableChecklist ADD ${ChecklistFields.check_list_show_separator} INTEGER NOT NULL DEFAULT 0");
          await db.execute("ALTER TABLE $tableUser ADD ${UserFields.edit_price_without_pin} INTEGER NOT NULL DEFAULT 0");
          //new case 13
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
        case 10: {
          await db.execute("ALTER TABLE $tableAppSetting ADD ${AppSettingFields.print_receipt} INTEGER NOT NULL DEFAULT 1");
          //new
          await db.execute("ALTER TABLE $tablePaymentLinkCompany ADD ${PaymentLinkCompanyFields.allow_image} $integerType DEFAULT 0");
          await db.execute("ALTER TABLE $tablePaymentLinkCompany ADD ${PaymentLinkCompanyFields.image_name} $textType DEFAULT '' ");
          //new case 12
          await db.execute("ALTER TABLE $tableOrderDetail ADD ${OrderDetailFields.edited_by} TEXT NOT NULL DEFAULT '' ");
          await db.execute("ALTER TABLE $tableOrderDetail ADD ${OrderDetailFields.edited_by_user_id} TEXT NOT NULL DEFAULT '' ");
          await db.execute("ALTER TABLE $tableChecklist ADD ${ChecklistFields.check_list_show_price} INTEGER NOT NULL DEFAULT 0");
          await db.execute("ALTER TABLE $tableChecklist ADD ${ChecklistFields.check_list_show_separator} INTEGER NOT NULL DEFAULT 0");
          await db.execute("ALTER TABLE $tableUser ADD ${UserFields.edit_price_without_pin} INTEGER NOT NULL DEFAULT 0");
          //new case 13
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
        case 11: {
          await db.execute("ALTER TABLE $tablePaymentLinkCompany ADD ${PaymentLinkCompanyFields.allow_image} $integerType DEFAULT 0");
          await db.execute("ALTER TABLE $tablePaymentLinkCompany ADD ${PaymentLinkCompanyFields.image_name} $textType DEFAULT '' ");
          //new case 12
          await db.execute("ALTER TABLE $tableOrderDetail ADD ${OrderDetailFields.edited_by} TEXT NOT NULL DEFAULT '' ");
          await db.execute("ALTER TABLE $tableOrderDetail ADD ${OrderDetailFields.edited_by_user_id} TEXT NOT NULL DEFAULT '' ");
          await db.execute("ALTER TABLE $tableChecklist ADD ${ChecklistFields.check_list_show_price} INTEGER NOT NULL DEFAULT 0");
          await db.execute("ALTER TABLE $tableChecklist ADD ${ChecklistFields.check_list_show_separator} INTEGER NOT NULL DEFAULT 0");
          await db.execute("ALTER TABLE $tableUser ADD ${UserFields.edit_price_without_pin} INTEGER NOT NULL DEFAULT 0");
          //new case 13
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
        case 12: {
          await db.execute("ALTER TABLE $tableOrderDetail ADD ${OrderDetailFields.edited_by} TEXT NOT NULL DEFAULT '' ");
          await db.execute("ALTER TABLE $tableOrderDetail ADD ${OrderDetailFields.edited_by_user_id} TEXT NOT NULL DEFAULT '' ");
          await db.execute("ALTER TABLE $tableChecklist ADD ${ChecklistFields.check_list_show_price} INTEGER NOT NULL DEFAULT 0");
          await db.execute("ALTER TABLE $tableChecklist ADD ${ChecklistFields.check_list_show_separator} INTEGER NOT NULL DEFAULT 0");
          await db.execute("ALTER TABLE $tableUser ADD ${UserFields.edit_price_without_pin} INTEGER NOT NULL DEFAULT 0");
          //new case 13
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
          //branch table
          await db.execute("ALTER TABLE $tableBranch ADD ${BranchFields.qr_order_status} $textType DEFAULT '0'");
          await db.execute("ALTER TABLE $tableBranch ADD ${BranchFields.sub_pos_status} INTEGER NOT NULL DEFAULT 1");
          await db.execute("ALTER TABLE $tableBranch ADD ${BranchFields.attendance_status} INTEGER NOT NULL DEFAULT 1");

          await db.execute("UPDATE $tableUser SET ${UserFields.edit_price_without_pin} = 1 WHERE role = 0 AND soft_delete = ''");

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
        case 15: {
          await db.execute("UPDATE $tableUser SET ${UserFields.edit_price_without_pin} = 1 WHERE role = 0 AND soft_delete = ''");
          await db.execute("UPDATE $tableBranch SET ${BranchFields.sub_pos_status} = 1");
          await db.execute("UPDATE $tableBranch SET ${BranchFields.attendance_status} = 1");

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
        case 16: {
          await db.execute('''CREATE TABLE $tableOrderPaymentSplit(
          ${OrderPaymentSplitFields.order_split_payment_sqlite_id} $idType,
          ${OrderPaymentSplitFields.order_split_payment_id} $integerType,
          ${OrderPaymentSplitFields.payment_link_company_id} $textType,
          ${OrderPaymentSplitFields.amount} $textType,
          ${OrderPaymentSplitFields.payment_received} $textType,
          ${OrderPaymentSplitFields.payment_change} $textType,
          ${OrderPaymentSplitFields.order_key} $textType,
          ${OrderPaymentSplitFields.sync_status} $integerType,
          ${OrderPaymentSplitFields.created_at} $textType,
          ${OrderPaymentSplitFields.updated_at} $textType,
          ${OrderPaymentSplitFields.soft_delete} $textType)''');
          await db.execute("ALTER TABLE $tableOrder ADD ${OrderFields.payment_status} INTEGER NOT NULL DEFAULT 0");
        }break;
      }
    }
  }

  Future _createDB(Database db, int version) async {
    final idType = 'INTEGER PRIMARY KEY AUTOINCREMENT';
    final textType = 'TEXT NOT NULL';
    final integerType = 'INTEGER NOT NULL';

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
    await db.execute('''CREATE TABLE $tableDiningOption ( ${DiningOptionFields.dining_id} $idType, ${DiningOptionFields.name} $textType, 
           ${DiningOptionFields.created_at} $textType, ${DiningOptionFields.updated_at} $textType, ${DiningOptionFields.soft_delete} $textType)''');
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
           ${PromotionFields.specific_category} $textType, ${PromotionFields.category_id} $textType, ${PromotionFields.type} $integerType,
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
           ${BranchFields.branchID} $idType,
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
          ${ReceiptFields.header_image_status} $integerType,
          ${ReceiptFields.header_text} $textType,
          ${ReceiptFields.header_text_status} $integerType,
          ${ReceiptFields.header_font_size} $integerType,
          ${ReceiptFields.show_address} $integerType,
          ${ReceiptFields.show_email} $integerType,
          ${ReceiptFields.receipt_email} $textType,
          ${ReceiptFields.footer_image} $textType,
          ${ReceiptFields.footer_image_status} $integerType,
          ${ReceiptFields.footer_text} $textType,
          ${ReceiptFields.footer_text_status} $integerType,
          ${ReceiptFields.promotion_detail_status} $integerType,
          ${ReceiptFields.paper_size} $textType,
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
          ${SettlementFields.total_tax} $textType, 
          ${SettlementFields.settlement_by_user_id} $textType,
          ${SettlementFields.settlement_by} $textType,
          ${SettlementFields.status} $integerType,
          ${SettlementFields.sync_status} $integerType,
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
          ${OrderDetailCancelFields.cancel_by} $textType,
          ${OrderDetailCancelFields.cancel_by_user_id} $textType,
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
          ${KitchenListFields.kitchen_list_show_price} $integerType,
          ${KitchenListFields.print_combine_kitchen_list} $integerType,
          ${KitchenListFields.kitchen_list_item_separator} $integerType,
          ${KitchenListFields.sync_status} $integerType,
          ${KitchenListFields.created_at} $textType,
          ${KitchenListFields.updated_at} $textType,
          ${KitchenListFields.soft_delete} $textType)''');

/*
    create order payment split table
*/
    await db.execute('''CREATE TABLE $tableOrderPaymentSplit(
          ${OrderPaymentSplitFields.order_split_payment_sqlite_id} $idType,
          ${OrderPaymentSplitFields.order_split_payment_id} $integerType,
          ${OrderPaymentSplitFields.payment_link_company_id} $textType,
          ${OrderPaymentSplitFields.amount} $textType,
          ${OrderPaymentSplitFields.payment_received} $textType,
          ${OrderPaymentSplitFields.payment_change} $textType,
          ${OrderPaymentSplitFields.order_key} $textType,
          ${OrderPaymentSplitFields.sync_status} $integerType,
          ${OrderPaymentSplitFields.created_at} $textType,
          ${OrderPaymentSplitFields.updated_at} $textType,
          ${OrderPaymentSplitFields.soft_delete} $textType)''');
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
  add attendance to sqlite
*/
  Future<Attendance> insertAttendance(Attendance data) async {
    final db = await instance.database;
    final id = await db.insert(tableAttendance!, data.toJson());
    return data.copy(attendance_sqlite_id: id);
  }

  /*
  add table to sqlite (from cloud)
*/
  Future<PosTable> insertPosTable(PosTable data) async {
    final db = await instance.database;
    final id = db.rawInsert(
        'INSERT INTO $tablePosTable(table_id, table_url, branch_id, number, seats, status, table_use_detail_key, table_use_key, sync_status, table_dx, table_dy, created_at, updated_at, soft_delete) VALUES(?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
        [
          data.table_id,
          data.table_url,
          data.branch_id,
          data.number,
          data.seats,
          data.status,
          data.table_use_detail_key,
          data.table_use_key,
          1,
          data.dx,
          data.dy,
          data.created_at,
          data.updated_at,
          data.soft_delete
        ]);
    return data.copy(table_sqlite_id: await id);
  }

/*
  add pos table to sqlite(table page)
*/
  Future<PosTable> insertSyncPosTable(PosTable data) async {
    final db = await instance.database;
    final id = db.rawInsert(
        'INSERT INTO $tablePosTable(table_id, table_url, branch_id, number, seats, table_use_detail_key, table_use_key, status, sync_status, table_dx , table_dy, created_at, updated_at, soft_delete) VALUES(?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
        [
          data.table_id,
          data.table_url,
          data.branch_id,
          data.number,
          data.seats,
          data.table_use_detail_key,
          data.table_use_key,
          data.status,
          data.sync_status,
          data.dx,
          data.dy,
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
    final id = await db.insert(tableBranchLinkDining!, data.toJson2());
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
    final id = await db.insert(tableTaxLinkDining!, data.toInsertJson());
    return data.copy(tax_link_dining_id: id);
  }

/*
  add product categories to sqlite (from cloud)
*/
  Future<Categories> insertCategories(Categories data) async {
    final db = await instance.database;
    final id = db.rawInsert(
        'INSERT INTO $tableCategories(category_id, company_id, name, color, sync_status, sequence, created_at, updated_at, soft_delete) VALUES(?, ?, ?, ?, ?, ?, ?, ?, ?)',
        [data.category_id, data.company_id, data.name, data.color, 2, data.sequence, data.created_at, data.updated_at, data.soft_delete]);
    return data.copy(category_sqlite_id: await id);
  }

/*
  add product categories to sqlite
*/
  Future<Categories> insertSyncCategories(Categories data) async {
    final db = await instance.database;
    final id = db.rawInsert(
        'INSERT INTO $tableCategories(category_id, company_id, name, color, sync_status, sequence, created_at, updated_at, soft_delete) VALUES(?, ?, ?, ?, ?, ?, ?, ?, ?)',
        [data.category_id, data.company_id, data.name, data.color, data.sync_status, data.sequence, data.created_at, data.updated_at, data.soft_delete]);
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
  Future<BranchLinkPromotion> insertBranchLinkPromotion(BranchLinkPromotion data) async {
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
  Future<PaymentLinkCompany> insertPaymentLinkCompany(PaymentLinkCompany data) async {
    final db = await instance.database;
    final id = await db.insert(tablePaymentLinkCompany!, data.toJson());
    return data.copy(payment_link_company_id: id);
  }

/*
  add refund list to sqlite
*/
  Future<Refund> insertRefund(Refund data) async {
    final db = await instance.database;
    final id = db.rawInsert(
        'INSERT INTO $tableRefund(refund_id, refund_key, company_id, branch_id, order_cache_sqlite_id, '
        'order_cache_key, order_sqlite_id, order_key, refund_by, refund_by_user_id, bill_id, sync_status, created_at, updated_at, soft_delete) '
        'VALUES(?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
        [
          data.refund_id,
          data.refund_key,
          data.company_id,
          data.branch_id,
          data.order_cache_sqlite_id,
          data.order_cache_key,
          data.order_sqlite_id,
          data.order_key,
          data.refund_by,
          data.refund_by_user_id,
          data.bill_id,
          data.sync_status,
          data.created_at,
          data.updated_at,
          data.soft_delete
        ]);
    return data.copy(refund_sqlite_id: await id);
  }

/*
  add modifier group to sqlite
*/
  Future<ModifierGroup> insertModifierGroup(ModifierGroup data) async {
    final db = await instance.database;
    final id = await db.insert(tableModifierGroup!, data.toJson2());
    return data.copy(mod_group_id: id);
  }

/*
  add modifier item to sqlite
*/
  Future<ModifierItem> insertModifierItem(ModifierItem data) async {
    final db = await instance.database;
    final id = await db.insert(tableModifierItem!, data.toJson2());
    return data.copy(mod_item_id: id);
  }

/*
  add branch link modifier to sqlite
*/
  Future<BranchLinkModifier> insertBranchLinkModifier(BranchLinkModifier data) async {
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
        'INSERT INTO $tableProduct(product_id, category_id, category_sqlite_id, company_id, name, price, description, SKU, image, has_variant, stock_type, stock_quantity, available, graphic_type, color, daily_limit, daily_limit_amount, '
            'sync_status, unit, per_quantity_unit, sequence_number, created_at, updated_at, soft_delete) VALUES(?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
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
          data.unit,
          data.per_quantity_unit,
          data.sequence_number,
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
  Future<BranchLinkProduct> insertBranchLinkProduct(BranchLinkProduct data) async {
    final db = await instance.database;
    final id = db.rawInsert(
        'INSERT INTO $tableBranchLinkProduct(branch_link_product_id, branch_id, product_sqlite_id, product_id, has_variant, product_variant_sqlite_id, product_variant_id, b_SKU, price, stock_type, daily_limit, daily_limit_amount, stock_quantity, sync_status, created_at, updated_at, soft_delete) VALUES(?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
        [
          data.branch_link_product_id,
          data.branch_id,
          data.product_sqlite_id,
          data.product_id,
          data.has_variant,
          data.product_variant_sqlite_id,
          data.product_variant_id,
          data.b_SKU,
          data.price,
          data.stock_type,
          data.daily_limit,
          data.daily_limit_amount,
          data.stock_quantity,
          data.sync_status,
          data.created_at,
          data.updated_at,
          data.soft_delete
        ]);
    return data.copy(branch_link_product_sqlite_id: await id);
  }

  /*
  add modifier link product to sqlite (from cloud)
*/
  Future<ModifierLinkProduct> insertModifierLinkProduct(ModifierLinkProduct data) async {
    final db = await instance.database;
    final id = db.rawInsert(
        'INSERT INTO $tableModifierLinkProduct(modifier_link_product_id, mod_group_id, product_id, product_sqlite_id, sync_status, created_at, updated_at, soft_delete) VALUES(?, ?, ?, ?, ?, ?, ?, ?)',
        [data.modifier_link_product_id, data.mod_group_id, data.product_id, data.product_sqlite_id, data.sync_status, data.created_at, data.updated_at, data.soft_delete]);
    return data.copy(modifier_link_product_sqlite_id: await id);
  }

/*
  add modifier link product to sqlite
*/
  Future<ModifierLinkProduct> insertSyncModifierLinkProduct(ModifierLinkProduct data) async {
    final db = await instance.database;
    final id = db.rawInsert(
        'INSERT INTO $tableModifierLinkProduct(modifier_link_product_id, mod_group_id, product_id, product_sqlite_id, sync_status, created_at, updated_at, soft_delete) VALUES(?, ?, ?, ?, ?, ?, ?, ?)',
        [data.modifier_link_product_id, data.mod_group_id, data.product_id, data.product_sqlite_id, data.sync_status, data.created_at, data.updated_at, data.soft_delete]);
    return data.copy(modifier_link_product_id: await id);
  }

  /*
  add variant group to sqlite (from cloud)
*/
  Future<VariantGroup> insertVariantGroup(VariantGroup data) async {
    final db = await instance.database;
    final id = db.rawInsert(
        'INSERT INTO $tableVariantGroup(variant_group_id, product_id, product_sqlite_id, name, sync_status, created_at, updated_at, soft_delete) VALUES(?, ?, ?, ?, ?, ?, ?, ?)',
        [data.variant_group_id, data.product_id, data.product_sqlite_id, data.name, data.sync_status, data.created_at, data.updated_at, data.soft_delete]);
    return data.copy(variant_group_sqlite_id: await id);
  }

/*
  add variant group to sqlite
*/
  Future<VariantGroup> insertSyncVariantGroup(VariantGroup data) async {
    final db = await instance.database;
    final id = db.rawInsert(
        'INSERT INTO $tableVariantGroup(variant_group_id, product_id, product_sqlite_id, name, sync_status, created_at, updated_at, soft_delete) VALUES(?, ?, ?, ?, ?, ?, ?, ?)',
        [data.variant_group_id, data.product_id, data.product_sqlite_id, data.name, data.sync_status, data.created_at, data.updated_at, data.soft_delete]);
    return data.copy(variant_group_sqlite_id: await id);
  }

  /*
  add variant item to sqlite (from cloud)
*/
  Future<VariantItem> insertVariantItem(VariantItem data) async {
    final db = await instance.database;
    final id = db.rawInsert(
        'INSERT INTO $tableVariantItem(variant_item_id, variant_group_id, variant_group_sqlite_id, name, sync_status, created_at, updated_at, soft_delete) VALUES(?, ?, ?, ?, ?, ?, ?, ?)',
        [data.variant_item_id, data.variant_group_id, data.variant_group_sqlite_id, data.name, data.sync_status, data.created_at, data.updated_at, data.soft_delete]);
    return data.copy(variant_item_sqlite_id: await id);
  }

/*
  add variant item to sqlite
*/
  Future<VariantItem> insertSyncVariantItem(VariantItem data) async {
    final db = await instance.database;
    final id = db.rawInsert('INSERT INTO $tableVariantItem(variant_item_id, variant_group_id, name, sync_status, created_at, updated_at, soft_delete) VALUES(?, ?, ?, ?, ?, ?, ?)',
        [data.variant_item_id, data.variant_group_id, data.name, data.sync_status, data.created_at, data.updated_at, data.soft_delete]);
    return data.copy(variant_item_sqlite_id: await id);
  }

  /*
  add product variant to sqlite (from cloud)
*/
  Future<ProductVariant> insertProductVariant(ProductVariant data) async {
    final db = await instance.database;
    final id = db.rawInsert(
        'INSERT INTO $tableProductVariant(product_variant_id, product_sqlite_id, product_id, variant_name, SKU, price, stock_type, daily_limit, daily_limit_amount, stock_quantity, sync_status, created_at, updated_at, soft_delete) VALUES(?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
        [
          data.product_variant_id,
          data.product_sqlite_id,
          data.product_id,
          data.variant_name,
          data.SKU,
          data.price,
          data.stock_type,
          data.daily_limit,
          data.daily_limit_amount,
          data.stock_quantity,
          data.sync_status,
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
          data.sync_status,
          data.created_at,
          data.updated_at,
          data.soft_delete
        ]);
    return data.copy(product_variant_sqlite_id: await id);
  }

/*
  add product variant detail to sqlite
*/
  Future<ProductVariantDetail> insertProductVariantDetail(ProductVariantDetail data) async {
    final db = await instance.database;
    final id = db.rawInsert(
        'INSERT INTO $tableProductVariantDetail(product_variant_detail_id, product_variant_id, product_variant_sqlite_id, variant_item_sqlite_id, variant_item_id, sync_status, created_at, updated_at, soft_delete) VALUES(?, ?, ?, ?, ?, ?, ?, ?, ?)',
        [
          data.product_variant_detail_id,
          data.product_variant_id,
          data.product_variant_sqlite_id,
          data.variant_item_sqlite_id,
          data.variant_item_id,
          data.sync_status,
          data.created_at,
          data.updated_at,
          data.soft_delete
        ]);
    return data.copy(product_variant_detail_sqlite_id: await id);
  }

/*
  add all order to sqlite
*/
  Future<Order> insertOrder(Order data) async {
    try{
      final db = await instance.database;
      final id = db.rawInsert(
          'INSERT INTO $tableOrder(order_id, order_number, order_queue, company_id, customer_id, dining_id, dining_name, '
              'branch_link_promotion_id, payment_link_company_id, branch_id, branch_link_tax_id, '
              'subtotal, amount, rounding, final_amount, close_by, payment_status, paymment_split, payment_received, payment_change, order_key, '
              'refund_sqlite_id, refund_key, settlement_sqlite_id, settlement_key, sync_status, created_at, updated_at, soft_delete) '
              'VALUES(?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
          [
            data.order_id,
            data.order_number,
            data.order_queue,
            data.company_id,
            data.customer_id,
            data.dining_id,
            data.dining_name,
            data.branch_link_promotion_id,
            data.payment_link_company_id,
            data.branch_id,
            data.branch_link_tax_id,
            data.subtotal,
            data.amount,
            data.rounding,
            data.final_amount,
            data.close_by,
            data.payment_status,
            0,
            data.payment_received,
            data.payment_change,
            data.order_key,
            data.refund_sqlite_id,
            data.refund_key,
            data.settlement_sqlite_id,
            data.settlement_key,
            data.sync_status,
            data.created_at,
            data.updated_at,
            data.soft_delete
          ]);
      return data.copy(order_sqlite_id: await id);
    }catch(e){
      print("Insert Order Error: ${e}");
    }
    return Order();
  }

/*
  add all order promotion to sqlite
*/
  Future<OrderPromotionDetail> insertOrderPromotionDetail(OrderPromotionDetail data) async {
    final db = await instance.database;
    final id = db.rawInsert(
        'INSERT INTO $tableOrderPromotionDetail(order_promotion_detail_id, order_promotion_detail_key, order_sqlite_id, order_id, '
        'order_key, promotion_name, rate, promotion_id, branch_link_promotion_id, promotion_amount, '
        'promotion_type, auto_apply, sync_status, created_at, updated_at, soft_delete) VALUES(?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
        [
          data.order_promotion_detail_id,
          data.order_promotion_detail_key,
          data.order_sqlite_id,
          data.order_id,
          data.order_key,
          data.promotion_name,
          data.rate,
          data.promotion_id,
          data.branch_link_promotion_id,
          data.promotion_amount,
          data.promotion_type,
          data.auto_apply,
          data.sync_status,
          data.created_at,
          data.updated_at,
          data.soft_delete
        ]);
    return data.copy(order_promotion_detail_sqlite_id: await id);
  }

/*
  add all order promotion to sqlite
*/
  Future<OrderTaxDetail> insertOrderTaxDetail(OrderTaxDetail data) async {
    final db = await instance.database;
    final id = db.rawInsert(
        'INSERT INTO $tableOrderTaxDetail(order_tax_detail_id, order_tax_detail_key, order_sqlite_id,  '
        'order_id, order_key, tax_name, rate, tax_id, branch_link_tax_id, tax_amount, sync_status, created_at, updated_at, soft_delete) '
        'VALUES(?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ? ,?, ?)',
        [
          data.order_tax_detail_id,
          data.order_tax_detail_key,
          data.order_sqlite_id,
          data.order_id,
          data.order_key,
          data.tax_name,
          data.rate,
          data.tax_id,
          data.branch_link_tax_id,
          data.tax_amount,
          data.sync_status,
          data.created_at,
          data.updated_at,
          data.soft_delete
        ]);
    return data.copy(order_tax_detail_sqlite_id: await id);
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
  insert table use from cloud
*/
  Future<TableUse> insertTableUse(TableUse data) async {
    final db = await instance.database;
    final id = await db.rawInsert(
        'INSERT INTO $tableTableUse(table_use_id, table_use_key, branch_id, order_cache_key, '
        'card_color, status, sync_status, created_at, updated_at, soft_delete) VALUES(?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
        [
          data.table_use_id,
          data.table_use_key,
          data.branch_id,
          data.order_cache_key,
          data.card_color,
          data.status,
          data.sync_status,
          data.created_at,
          data.updated_at,
          data.soft_delete
        ]);
    return data.copy(table_use_sqlite_id: await id);
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
  add table use detail (from cloud)
*/
  Future<TableUseDetail> insertTableUseDetail(TableUseDetail data) async {
    final db = await instance.database;
    final id = db.rawInsert(
        'INSERT INTO $tableTableUseDetail(table_use_detail_id, table_use_detail_key, table_use_sqlite_id, table_use_key, table_sqlite_id, table_id, status, sync_status, created_at, updated_at, soft_delete) VALUES(?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
        [
          data.table_use_detail_id,
          data.table_use_detail_key,
          data.table_use_sqlite_id,
          data.table_use_key,
          data.table_sqlite_id,
          data.table_id,
          data.status,
          data.sync_status,
          data.created_at,
          data.updated_at,
          data.soft_delete
        ]);
    return data.copy(table_use_detail_sqlite_id: await id);
  }

/*
  add all order cache to sqlite
*/
  Future<OrderCache> insertOrderCache(OrderCache data) async {
    final db = await instance.database;
    final id = db.rawInsert(
        'INSERT INTO $tableOrderCache(order_cache_id, order_cache_key, order_queue, company_id, branch_id, order_detail_id, '
        'table_use_sqlite_id, table_use_key, batch_id, dining_id, order_sqlite_id, order_key, order_by, order_by_user_id, '
        'cancel_by, cancel_by_user_id, customer_id, total_amount, qr_order, qr_order_table_sqlite_id, qr_order_table_id, accepted, sync_status, created_at, updated_at, soft_delete) '
        'VALUES(?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?) ',
        [
          data.order_cache_id,
          data.order_cache_key,
          data.order_queue,
          data.company_id,
          data.branch_id,
          data.order_detail_id,
          data.table_use_sqlite_id,
          data.table_use_key,
          data.batch_id,
          data.dining_id,
          data.order_sqlite_id,
          data.order_key,
          data.order_by,
          data.order_by_user_id,
          data.cancel_by,
          data.cancel_by_user_id,
          data.customer_id,
          data.total_amount,
          data.qr_order,
          data.qr_order_table_sqlite_id,
          data.qr_order_table_id,
          data.accepted,
          data.sync_status,
          data.created_at,
          data.updated_at,
          data.soft_delete
        ]);
    return data.copy(order_cache_sqlite_id: await id);
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
    final id = db.rawInsert(
        'INSERT INTO $tableOrderDetail(order_detail_id, order_detail_key, order_cache_sqlite_id, order_cache_key, '
        'branch_link_product_sqlite_id, category_sqlite_id, category_name, product_name, has_variant, product_variant_name, price, original_price, quantity, '
        'remark, account, edited_by, edited_by_user_id, cancel_by, cancel_by_user_id, status, sync_status, unit, per_quantity_unit, created_at, updated_at, soft_delete) '
        'VALUES(?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?) ',
        [
          data.order_detail_id,
          data.order_detail_key,
          data.order_cache_sqlite_id,
          data.order_cache_key,
          data.branch_link_product_sqlite_id,
          data.category_sqlite_id,
          data.category_name,
          data.productName,
          data.has_variant,
          data.product_variant_name,
          data.price,
          data.original_price,
          data.quantity,
          data.remark,
          data.account,
          data.edited_by,
          data.edited_by_user_id,
          data.cancel_by,
          data.cancel_by_user_id,
          data.status,
          data.sync_status,
          data.unit,
          data.per_quantity_unit,
          data.created_at,
          data.updated_at,
          data.soft_delete
        ]);
    return data.copy(order_detail_sqlite_id: await id);
  }

/*
  add order detail data into sqlite
*/
  Future<OrderDetail> insertSqliteOrderDetail(OrderDetail data) async {
    final db = await instance.database;
    final id = await db.insert(tableOrderDetail!, data.toInsertJson());
    return data.copy(order_detail_sqlite_id: id);
  }

/*
  add order modifier data into sqlite(cloud)
*/
  Future<OrderModifierDetail> insertOrderModifierDetail(OrderModifierDetail data) async {
    final db = await instance.database;
    final id = db.rawInsert(
        'INSERT INTO $tableOrderModifierDetail(order_modifier_detail_id, order_modifier_detail_key, order_detail_sqlite_id, '
        'order_detail_id, order_detail_key, mod_item_id, mod_name, mod_price, mod_group_id, sync_status, created_at, updated_at, soft_delete) VALUES(?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
        [
          data.order_modifier_detail_id,
          data.order_modifier_detail_key,
          data.order_detail_sqlite_id,
          data.order_detail_id,
          data.order_detail_key,
          data.mod_item_id,
          data.mod_name,
          data.mod_price,
          data.mod_group_id,
          data.sync_status,
          data.created_at,
          data.updated_at,
          data.soft_delete
        ]);
    return data.copy(order_modifier_detail_id: await id);
  }

/*
  add order modifier data into sqlite
*/
  Future<OrderModifierDetail> insertSqliteOrderModifierDetail(OrderModifierDetail data) async {
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
  add color setting
*/
  Future<AppColors> insertColor(AppColors data) async {
    final db = await instance.database;
    final id = await db.insert(tableAppColors!, data.toJson());
    return data.copy(app_color_id: id);
  }

  /*
  add app setting to cloud
*/
  Future<AppSetting> insertSetting(AppSetting data) async {
    final db = await instance.database;
    final id = db.rawInsert(
        'INSERT INTO $tableCashRecord(branch_id, open_cash_drawer, show_second_display, direct_payment, print_checklist, '
            'print_receipt, show_sku, qr_order_auto_accept, enable_numbering, starting_number, sync_status, created_at, updated_at) '
            'VALUES(?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
        [
          data.branch_id,
          data.open_cash_drawer,
          data.show_second_display,
          data.direct_payment,
          data.print_checklist,
          data.print_receipt,
          data.show_sku,
          data.qr_order_auto_accept,
          data.enable_numbering,
          data.starting_number,
          data.sync_status,
          data.created_at,
          data.updated_at
        ]);
    return data.copy(app_setting_sqlite_id: await id);
  }

/*
  add app setting to local db
*/
  Future<AppSetting> insertSqliteSetting(AppSetting data) async {
    final db = await instance.database;
    final id = await db.insert(tableAppSetting!, data.toJson());
    return data.copy(app_setting_sqlite_id: id);
  }

/*
  add attendance to local db
*/
  Future<Attendance> insertSqliteAttendance(Attendance data) async {
    final db = await instance.database;
    final id = await db.insert(tableAttendance!, data.toJson());
    return data.copy(attendance_sqlite_id: id);
  }

/*
  add subscription to local db
*/
  Future<Subscription> insertSqliteSubscription(Subscription data) async {
    final db = await instance.database;
    final id = await db.insert(tableSubscription!, data.toJson());
    return data.copy(subscription_sqlite_id: id);
  }

/*
  add printer into local db from cloud
*/
  Future<Printer> insertPrinter(Printer data) async {
    final db = await instance.database;
    final id = await db.rawInsert(
        'INSERT INTO $tablePrinter(soft_delete, updated_at, created_at, sync_status, is_counter, is_label, '
        'printer_status, paper_size, printer_label, type, value, printer_link_category_id, company_id, branch_id, printer_key, printer_id) '
        'VALUES(?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
        [
          data.soft_delete,
          data.updated_at,
          data.created_at,
          data.sync_status,
          data.is_counter,
          data.is_label,
          data.printer_status,
          data.paper_size,
          data.printer_label,
          data.type,
          data.value,
          data.printer_link_category_id,
          data.company_id,
          data.branch_id,
          data.printer_key,
          data.printer_id
        ]);
    return data.copy(printer_sqlite_id: await id);
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
  add printer category into local db from cloud
*/
  Future<PrinterLinkCategory> insertPrinterCategory(PrinterLinkCategory data) async {
    final db = await instance.database;
    final id = await db.rawInsert(
        'INSERT INTO $tablePrinterLinkCategory(soft_delete, updated_at, created_at, sync_status, category_id, '
        'category_sqlite_id, printer_key, printer_sqlite_id, printer_link_category_id, printer_link_category_key) '
        'VALUES(?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
        [
          data.soft_delete,
          data.updated_at,
          data.created_at,
          data.sync_status,
          data.category_id,
          data.category_sqlite_id,
          data.printer_key,
          data.printer_sqlite_id,
          data.printer_link_category_id,
          data.printer_link_category_key,
        ]);
    return data.copy(printer_link_category_sqlite_id: await id);
  }

/*
  add printer link category into local db
*/
  Future<PrinterLinkCategory> insertSqlitePrinterLinkCategory(PrinterLinkCategory data) async {
    final db = await instance.database;
    final id = await db.insert(tablePrinterLinkCategory!, data.toJson());
    return data.copy(printer_link_category_sqlite_id: id);
  }

/*
  insert receipt (from cloud)
*/
  Future<Receipt> insertReceipt(Receipt data) async {
    final db = await instance.database;
    final id = db.rawInsert(
        'INSERT INTO $tableReceipt(soft_delete, updated_at, created_at, sync_status, header_font_size, status, paper_size, promotion_detail_status, '
        'footer_text_status, footer_text, footer_image_status, footer_image, receipt_email, show_email, show_address, '
        'header_text_status, header_text, header_image_status, header_image, branch_id, receipt_key, receipt_id) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
        [
          data.soft_delete,
          data.updated_at,
          data.created_at,
          data.sync_status,
          data.header_font_size,
          data.status,
          data.paper_size,
          data.promotion_detail_status,
          data.footer_text_status,
          data.footer_text,
          data.footer_image_status,
          data.footer_image,
          data.receipt_email,
          data.show_email,
          data.show_address,
          data.header_text_status,
          data.header_text,
          data.header_image_status,
          data.header_image,
          data.branch_id,
          data.receipt_key,
          data.receipt_id
        ]);
    return data.copy(receipt_sqlite_id: await id);
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
  insert cash record (from cloud)
*/
  Future<CashRecord> insertCashRecord(CashRecord data) async {
    final db = await instance.database;
    final id = db.rawInsert(
        'INSERT INTO $tableCashRecord(cash_record_id, cash_record_key, company_id, branch_id, remark, '
        'payment_name, payment_type_id, type, amount, user_id, settlement_key, settlement_date, sync_status, created_at, updated_at, soft_delete) '
        'VALUES(?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
        [
          data.cash_record_id,
          data.cash_record_key,
          data.company_id,
          data.branch_id,
          data.remark,
          data.payment_name,
          data.payment_type_id,
          data.type,
          data.amount,
          data.user_id,
          data.settlement_key,
          data.settlement_date,
          data.sync_status,
          data.created_at,
          data.updated_at,
          data.soft_delete
        ]);
    return data.copy(cash_record_sqlite_id: await id);
  }

/*
  crate order into local(from local)
*/
  Future<Order> insertSqliteOrder(Order data) async {
    final db = await instance.database;
    final id = await db.insert(tableOrder!, data.toJson());
    return data.copy(order_sqlite_id: id);
  }

/*
  crate order payment split into local(from local)
*/
  Future<OrderPaymentSplit> insertSqliteOrderPaymentSplit(OrderPaymentSplit data) async {
    final db = await instance.database;
    final id = await db.insert(tableOrderPaymentSplit!, data.toJson());
    return data.copy(order_split_payment_sqlite_id: id);
  }

/*
  add order tax detail
*/
  Future<OrderTaxDetail> insertSqliteOrderTaxDetail(OrderTaxDetail data) async {
    final db = await instance.database;
    final id = await db.insert(tableOrderTaxDetail!, data.toJson());
    return data.copy(order_tax_detail_sqlite_id: id);
  }

/*
  add order promotion detail
*/
  Future<OrderPromotionDetail> insertSqliteOrderPromotionDetail(OrderPromotionDetail data) async {
    final db = await instance.database;
    final id = await db.insert(tableOrderPromotionDetail!, data.toJson());
    return data.copy(order_promotion_detail_sqlite_id: id);
  }

/*
  insert cash record (from cloud)
*/
  Future<TransferOwner> insertTransferOwner(TransferOwner data) async {
    final db = await instance.database;
    final id = db.rawInsert(
        'INSERT INTO $tableTransferOwner(transfer_owner_key, branch_id, device_id, transfer_from_user_id, transfer_to_user_id, '
        'cash_balance, sync_status, created_at, updated_at, soft_delete) '
        'VALUES(?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
        [
          data.transfer_owner_key,
          data.branch_id,
          data.device_id,
          data.transfer_from_user_id,
          data.transfer_to_user_id,
          data.cash_balance,
          data.sync_status,
          data.created_at,
          data.updated_at,
          data.soft_delete
        ]);
    return data.copy(transfer_owner_sqlite_id: await id);
  }

/*
  add transfer owner record
*/
  Future<TransferOwner> insertSqliteTransferOwner(TransferOwner data) async {
    final db = await instance.database;
    final id = await db.insert(tableTransferOwner!, data.toJson());
    return data.copy(transfer_owner_sqlite_id: id);
  }

/*
  add refund record
*/
  Future<Refund> insertSqliteRefund(Refund data) async {
    final db = await instance.database;
    final id = await db.insert(tableRefund!, data.toJson());
    return data.copy(refund_sqlite_id: id);
  }

/*
  add settlement record
*/
  Future<Settlement> insertSqliteSettlement(Settlement data) async {
    final db = await instance.database;
    final id = await db.insert(tableSettlement!, data.toJson());
    return data.copy(settlement_sqlite_id: id);
  }

/*
  insert settlement from cloud
*/
  Future<Settlement> insertSettlement(Settlement data) async {
    final db = await instance.database;
    final id = db.rawInsert(
        'INSERT INTO $tableSettlement(settlement_id, settlement_key, company_id, branch_id, total_bill, '
        'total_sales, total_refund_bill, total_refund_amount, total_discount, total_cancellation, total_tax, '
        'settlement_by_user_id, settlement_by, status, sync_status, created_at, updated_at, soft_delete) '
        'VALUES(?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ? ,?, ?, ?, ?, ?, ?)',
        [
          data.settlement_id,
          data.settlement_key,
          data.company_id,
          data.branch_id,
          data.total_bill,
          data.total_sales,
          data.total_refund_bill,
          data.total_refund_amount,
          data.total_discount,
          data.total_cancellation,
          data.total_tax,
          data.settlement_by_user_id,
          data.settlement_by,
          data.status,
          data.sync_status,
          data.created_at,
          data.updated_at,
          data.soft_delete
        ]);
    return data.copy(settlement_sqlite_id: await id);
  }

/*
  add settlement link payment record
*/
  Future<SettlementLinkPayment> insertSqliteSettlementLinkPayment(SettlementLinkPayment data) async {
    final db = await instance.database;
    final id = await db.insert(tableSettlementLinkPayment!, data.toJson());
    return data.copy(settlement_link_payment_sqlite_id: id);
  }

/*
  insert settlement from cloud
*/
  Future<SettlementLinkPayment> insertSettlementLinkPayment(SettlementLinkPayment data) async {
    final db = await instance.database;
    final id = db.rawInsert(
        'INSERT INTO $tableSettlementLinkPayment(settlement_link_payment_id, settlement_link_payment_key, '
        'company_id, branch_id, settlement_sqlite_id, settlement_key, total_bill, total_sales, payment_link_company_id, status, '
        'sync_status, created_at, updated_at, soft_delete) VALUES(?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
        [
          data.settlement_link_payment_id,
          data.settlement_link_payment_key,
          data.company_id,
          data.branch_id,
          data.settlement_sqlite_id,
          data.settlement_key,
          data.total_bill,
          data.total_sales,
          data.payment_link_company_id,
          data.status,
          data.sync_status,
          data.created_at,
          data.updated_at,
          data.soft_delete
        ]);
    return data.copy(settlement_link_payment_sqlite_id: await id);
  }

/*
  add order detail cancel in local db
*/
  Future<OrderDetailCancel> insertSqliteOrderDetailCancel(OrderDetailCancel data) async {
    final db = await instance.database;
    final id = await db.insert(tableOrderDetailCancel!, data.toJson());
    return data.copy(order_detail_cancel_sqlite_id: id);
  }

/*
  add order detail cancel data into sqlite(cloud)
*/
  Future<OrderDetailCancel> insertOrderDetailCancel(OrderDetailCancel data) async {
    final db = await instance.database;
    final id = db.rawInsert(
        'INSERT INTO $tableOrderDetailCancel(order_detail_cancel_id, order_detail_cancel_key, order_detail_sqlite_id, order_detail_key, '
        'quantity, cancel_by, cancel_by_user_id, settlement_sqlite_id, settlement_key, status, sync_status, created_at, updated_at, soft_delete) '
        'VALUES(?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
        [
          data.order_detail_cancel_id,
          data.order_detail_cancel_key,
          data.order_detail_sqlite_id,
          data.order_detail_key,
          data.quantity,
          data.cancel_by,
          data.cancel_by_user_id,
          data.settlement_sqlite_id,
          data.settlement_key,
          data.status,
          data.sync_status,
          data.created_at,
          data.updated_at,
          data.soft_delete
        ]);
    return data.copy(order_detail_cancel_sqlite_id: await id);
  }

/*
  add checklist data into sqlite(cloud)
*/
  Future<Checklist> insertChecklist(Checklist data) async {
    final db = await instance.database;
    final id = db.rawInsert(
        'INSERT INTO $tableChecklist(soft_delete, updated_at, created_at, sync_status, paper_size, check_list_show_separator, '
            'check_list_show_price, other_font_size, product_name_font_size, branch_id, checklist_key, checklist_id) '
            'VALUES(?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
        [
          '',
          data.updated_at,
          data.created_at,
          data.sync_status,
          data.paper_size,
          data.check_list_show_separator,
          data.check_list_show_price,
          data.other_font_size,
          data.product_name_font_size,
          data.branch_id,
          data.checklist_key,
          data.checklist_id
        ]);
    return data.copy(checklist_sqlite_id: await id);
  }

/*
  add checklist data into local db
*/
  Future<Checklist> insertSqliteChecklist(Checklist data) async {
    final db = await instance.database;
    final id = await db.insert(tableChecklist!, data.toJson());
    return data.copy(checklist_sqlite_id: id);
  }

/*
  add second screen to sqlite
*/
  Future<SecondScreen> insertSecondScreen(SecondScreen data) async {
    final db = await instance.database;
    final id = await db.insert(tableSecondScreen!, data.toJson());
    return data.copy(second_screen_id: id);
  }

  /*
  add kitchen list data into sqlite(cloud)
*/
  Future<KitchenList> insertKitchenList(KitchenList data) async {
    final db = await instance.database;
    final id = db.rawInsert(
        'INSERT INTO $tableKitchenList(soft_delete, updated_at, created_at, sync_status, kitchen_list_item_separator, print_combine_kitchen_list, kitchen_list_show_price, '
            'paper_size, other_font_size, product_name_font_size, branch_id, kitchen_list_key, kitchen_list_id) '
            'VALUES(?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
        [
          '',
          data.updated_at,
          data.created_at,
          data.sync_status,
          data.kitchen_list_item_separator,
          data.print_combine_kitchen_list,
          data.kitchen_list_show_price,
          data.paper_size,
          data.other_font_size,
          data.product_name_font_size,
          data.branch_id,
          data.kitchen_list_key,
          data.kitchen_list_id
        ]);
    return data.copy(kitchen_list_sqlite_id: await id);
  }

/*
  add kitchen list data into local db
*/
  Future<KitchenList> insertSqliteKitchenList(KitchenList data) async {
    final db = await instance.database;
    final id = await db.insert(tableKitchenList!, data.toJson());
    return data.copy(kitchen_list_sqlite_id: id);
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
    return null;
  }

  Future<Product?> readProductSqliteID(String product_id) async {
    final db = await instance.database;
    final maps = await db.rawQuery('SELECT * FROM $tableProduct WHERE product_id = ?', [product_id]);
    if (maps.isNotEmpty) {
      return Product.fromJson(maps.first);
    } else {
      return null;
    }
  }

/*
  read product local id inc deleted
*/
  Future<Product?> readProductLocalId(String product_id) async {
    final db = await instance.database;
    final maps = await db.rawQuery('SELECT * FROM $tableProduct WHERE product_id = ?', [product_id]);
    if (maps.isNotEmpty) {
      return Product.fromJson(maps.first);
    } else {
      return null;
    }
  }

  Future<VariantGroup?> readVariantGroupSqliteID(String variant_group_id) async {
    final db = await instance.database;
    final maps = await db.rawQuery('SELECT * FROM $tableVariantGroup WHERE variant_group_id = ?', [variant_group_id]);
    if (maps.isNotEmpty) {
      return VariantGroup.fromJson(maps.first);
    }
    return null;
  }

  Future<VariantGroup?> readVariantGroupID(String variant_group_sqlite_id) async {
    final db = await instance.database;
    final maps = await db.rawQuery('SELECT * FROM $tableVariantGroup WHERE soft_delete = ? AND variant_group_sqlite_id = ?', ['', variant_group_sqlite_id]);
    if (maps.isNotEmpty) {
      return VariantGroup.fromJson(maps.first);
    }
    return null;
  }

  Future<ProductVariant?> readProductVariantSqliteID(String product_variant_id) async {
    final db = await instance.database;
    final maps = await db.rawQuery('SELECT * FROM $tableProductVariant WHERE product_variant_id = ?', [product_variant_id]);
    if (maps.isNotEmpty) {
      return ProductVariant.fromJson(maps.first);
    } else {
      return null;
    }
  }

  Future<ProductVariant?> readProductVariantID(String product_variant_sqlite_id) async {
    final db = await instance.database;
    final maps = await db.rawQuery('SELECT * FROM $tableProductVariant WHERE soft_delete = ? AND product_variant_sqlite_id = ?', ['', product_variant_sqlite_id]);
    if (maps.isNotEmpty) {
      return ProductVariant.fromJson(maps.first);
    }
    return null;
  }

  Future<VariantItem?> readVariantItemSqliteID(String variant_item_id) async {
    final db = await instance.database;
    final maps = await db.rawQuery('SELECT * FROM $tableVariantItem WHERE variant_item_id = ?', [variant_item_id]);
    if (maps.isNotEmpty) {
      return VariantItem.fromJson(maps.first);
    }
    return null;
  }

  Future<Categories?> readCategorySqliteID(String category_id) async {
    final db = await instance.database;
    final maps = await db.rawQuery('SELECT * FROM $tableCategories WHERE category_id = ?', [category_id]);
    if (maps.isNotEmpty) {
      return Categories.fromJson(maps.first);
    } else {
      return null;
    }
  }

  Future<BranchLinkProduct?> readBranchLinkProductSqliteID(String branch_link_product_id) async {
    final db = await instance.database;
    final maps = await db.rawQuery('SELECT * FROM $tableBranchLinkProduct WHERE branch_link_product_id = ?', [branch_link_product_id]);
    if (maps.isNotEmpty) {
      return BranchLinkProduct.fromJson(maps.first);
    } else {
      return null;
    }
  }

  Future<TableUse?> readTableUseSqliteID(String tableUseKey) async {
    final db = await instance.database;
    final maps = await db.rawQuery('SELECT * FROM $tableTableUse WHERE soft_delete = ? AND table_use_key = ?', ['', tableUseKey]);
    if (maps.isNotEmpty) {
      return TableUse.fromJson(maps.first);
    }
    return null;
  }

  Future<OrderCache?> readOrderCacheSqliteID(String orderCacheKey) async {
    final db = await instance.database;
    final maps = await db.rawQuery('SELECT * FROM $tableOrderCache WHERE soft_delete = ? AND order_cache_key = ?', ['', orderCacheKey]);
    if(maps.isNotEmpty){
      return OrderCache.fromJson(maps.first);
    } else {
      return null;
    }
  }

  Future<OrderCache?> readSpecificOrderCacheByKey(String orderCacheKey) async {
    final db = await instance.database;
    final maps = await db.rawQuery('SELECT * FROM $tableOrderCache WHERE soft_delete = ? AND order_cache_key = ?', ['', orderCacheKey]);
    if (maps.isNotEmpty) {
      return OrderCache.fromJson(maps.first);
    } else {
      return null;
    }
  }

  Future<OrderDetail?> readOrderDetailSqliteID(String orderDetailKey) async {
    final db = await instance.database;
    final maps = await db.rawQuery('SELECT * FROM $tableOrderDetail WHERE soft_delete = ? AND order_detail_key = ?', ['', orderDetailKey]);
    if(maps.isNotEmpty){
      return OrderDetail.fromJson(maps.first);
    } else {
      return null;
    }
  }

  Future<Order?> readOrderSqliteID(String orderKey) async {
    final db = await instance.database;
    final maps = await db.rawQuery('SELECT * FROM $tableOrder WHERE soft_delete = ? AND order_key = ?', ['', orderKey]);
    if(maps.isNotEmpty){
      return Order.fromJson(maps.first);
    } else {
      return null;
    }
  }

  Future<Settlement> readSettlementSqliteID(String settlementKey) async {
    final db = await instance.database;
    final maps = await db.rawQuery('SELECT * FROM $tableSettlement WHERE soft_delete = ? AND settlement_key = ?', ['', settlementKey]);
    return Settlement.fromJson(maps.first);
  }

  Future<Printer> readPrinterSqliteID(String printerKey) async {
    final db = await instance.database;
    final maps = await db.rawQuery('SELECT * FROM $tablePrinter WHERE soft_delete = ? AND printer_key = ?', ['', printerKey]);
    return Printer.fromJson(maps.first);
  }

/*
  read branch name
*/
  Future<Branch?> readBranchName(String branch_id) async {
    final db = await instance.database;
    final maps = await db.query(tableBranch!, columns: BranchFields.values, where: '${BranchFields.branchID} = ?', whereArgs: [branch_id]);
    if (maps.isNotEmpty) {
      return Branch.fromJson(maps.first);
    }
    return null;
  }

  /*
  read specific variant item
*/
  Future<VariantItem?> readVariantItem(String name) async {
    final db = await instance.database;
    final maps = await db.rawQuery('SELECT * FROM $tableVariantItem WHERE soft_delete = ? AND name = ?', ['', name]);
    if (maps.isNotEmpty) {
      return VariantItem.fromJson(maps.first);
    }
    return null;
  }

/*
  read variant group
*/
  Future<List<VariantGroup>> readVariantGroup(String product_sqlite_id) async {
    final db = await instance.database;
    final result = await db.rawQuery('SELECT * FROM $tableVariantGroup WHERE soft_delete = ? AND product_sqlite_id = ?', ['', product_sqlite_id]);

    return result.map((json) => VariantGroup.fromJson(json)).toList();
  }

  /*
  read product variant
*/
  Future<List<ProductVariant>> readProductVariant(String product_sqlite_id) async {
    final db = await instance.database;
    final result = await db.rawQuery('SELECT * FROM $tableProductVariant WHERE soft_delete = ? AND product_sqlite_id = ?', ['', product_sqlite_id]);

    return result.map((json) => ProductVariant.fromJson(json)).toList();
  }

/*
  read product variant detail
*/
  Future<List<ProductVariantDetail>> readProductVariantDetail(String product_variant_id) async {
    final db = await instance.database;
    final result = await db.rawQuery('SELECT * FROM $tableProductVariantDetail WHERE product_variant_id = ?', [product_variant_id]);

    return result.map((json) => ProductVariantDetail.fromJson(json)).toList();
  }

/*
  read product variant item
*/
  Future<List<VariantItem>> readProductVariantItemByVariantID(String variant_item_id) async {
    final db = await instance.database;
    final result = await db.rawQuery('SELECT * FROM $tableVariantItem WHERE variant_item_id = ?', [variant_item_id]);
    return result.map((json) => VariantItem.fromJson(json)).toList();
  }

  /*
  read variant group
*/
  Future<ProductVariant?> readProductVariantForUpdate(String variant_name, String product_sqlite_id) async {
    final db = await instance.database;
    final maps =
        await db.rawQuery('SELECT * FROM $tableProductVariant WHERE soft_delete = ? AND variant_name = ? AND product_sqlite_id = ?', ['', variant_name, product_sqlite_id]);
    if (maps.isNotEmpty) {
      return ProductVariant.fromJson(maps.first);
    }
    return null;
  }

  /*
  read variant group for update
*/
  Future<VariantGroup?> readSpecificVariantGroup(String name, String product_sqlite_id) async {
    final db = await instance.database;
    final maps = await db.rawQuery('SELECT * FROM $tableVariantGroup WHERE soft_delete = ? AND name = ? AND product_sqlite_id = ?', ['', name, product_sqlite_id]);
    if (maps.isNotEmpty) {
      return VariantGroup.fromJson(maps.first);
    }
    return null;
  }

  /*
  read variant item for group
*/
  Future<List<VariantItem>> readVariantItemForGroup(String variant_group_sqlite_id) async {
    final db = await instance.database;
    final result = await db.rawQuery('SELECT * FROM $tableVariantItem WHERE soft_delete = ? AND variant_group_sqlite_id = ?', ['', variant_group_sqlite_id]);

    return result.map((json) => VariantItem.fromJson(json)).toList();
  }

  /*
  read branch link product
*/
  Future<List<BranchLinkProduct>> readBranchLinkProduct(String branch_id, String product_sqlite_id) async {
    final db = await instance.database;
    final result = await db.rawQuery(
        'SELECT a.*, (SELECT variant_name FROM $tableProductVariant WHERE soft_delete = ? AND product_variant_sqlite_id = a.product_variant_sqlite_id) as variant_name FROM $tableBranchLinkProduct AS a WHERE a.soft_delete = ? AND a.branch_id = ? AND a.product_sqlite_id = ?',
        ['', '', branch_id, product_sqlite_id]);

    return result.map((json) => BranchLinkProduct.fromJson(json)).toList();
  }

  /*
  read modifier link product
*/
  Future<List<ModifierLinkProduct>> readModifierLinkProduct(String mod_group_id, String product_sqlite_id) async {
    final db = await instance.database;
    final result =
        await db.rawQuery('SELECT * FROM $tableModifierLinkProduct WHERE soft_delete = ? AND mod_group_id = ? AND product_sqlite_id = ?', ['', mod_group_id, product_sqlite_id]);

    return result.map((json) => ModifierLinkProduct.fromJson(json)).toList();
  }

  /*
  read modifier link product
*/
  Future<List<ModifierLinkProduct>> readModifierLinkProductList(String product_sqlite_id) async {
    final db = await instance.database;
    final result = await db.rawQuery('SELECT * FROM $tableModifierLinkProduct WHERE soft_delete = ? AND product_sqlite_id = ?', ['', product_sqlite_id]);

    return result.map((json) => ModifierLinkProduct.fromJson(json)).toList();
  }

/*
  read all branch link product
*/
  Future<List<BranchLinkProduct>> readAllBranchLinkProduct() async {
    final db = await instance.database;
    final result = await db.rawQuery('SELECT * FROM $tableBranchLinkProduct WHERE soft_delete = ?', ['']);

    return result.map((json) => BranchLinkProduct.fromJson(json)).toList();
  }

/*
  read branch link specific product
*/
  Future<List<BranchLinkProduct>> readBranchLinkSpecificProduct(String product_id) async {
    final db = await instance.database;
    final result = await db.rawQuery('SELECT * FROM $tableBranchLinkProduct WHERE soft_delete = ? AND product_sqlite_id = ?', ['', product_id]);

    return result.map((json) => BranchLinkProduct.fromJson(json)).toList();
  }

/*
  read branch link product by product variant
*/
  Future<BranchLinkProduct?> readBranchLinkProductByProductVariant(String product_variant_sqlite_id) async {
    final db = await instance.database;
    final result = await db.rawQuery('SELECT * FROM $tableBranchLinkProduct WHERE soft_delete = ? AND product_variant_sqlite_id = ?', ['', product_variant_sqlite_id]);
    if (result.isNotEmpty) {
      return BranchLinkProduct.fromJson(result.first);
    } else {
      return null;
    }
  }

/*
  read all product variant
*/
  Future<List<ProductVariant>> readAllProductVariant() async {
    final db = await instance.database;
    final result = await db.rawQuery('SELECT * FROM $tableProductVariant WHERE soft_delete = ?', ['']);

    return result.map((json) => ProductVariant.fromJson(json)).toList();
  }

/*
  read product variant by name
*/
  Future<List<ProductVariant>> readSpecificProductVariant(String product_id, String variant_name) async {
    final db = await instance.database;
    final result = await db.rawQuery('SELECT * FROM $tableProductVariant WHERE soft_delete = ? AND product_sqlite_id = ? AND variant_name = ?', ['', product_id, variant_name]);

    return result.map((json) => ProductVariant.fromJson(json)).toList();
  }

  /*
  read product variant by branch link product id
*/
  Future<ProductVariant?> readProductVariantSpecial(String branch_link_product_sqlite_id) async {
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
  Future<List<BranchLinkProduct>> readSpecificBranchLinkProduct(String branch_link_product_sqlite_id) async {
    final db = await instance.database;
    final result = await db.rawQuery(
        'SELECT a.*, b.name FROM $tableBranchLinkProduct AS a JOIN $tableProduct AS b ON a.product_id = b.product_id WHERE b.soft_delete = ? AND a.branch_link_product_sqlite_id = ?',
        ['', branch_link_product_sqlite_id]);

    return result.map((json) => BranchLinkProduct.fromJson(json)).toList();
  }

/*
  read specific branch link product item with no left join
*/
  Future<BranchLinkProduct?> readSpecificBranchLinkProduct2(String branch_link_product_sqlite_id) async {
    final db = await instance.database;
    final result = await db.rawQuery(
        'SELECT * FROM $tableBranchLinkProduct WHERE soft_delete = ? AND branch_link_product_sqlite_id = ?',
        ['', branch_link_product_sqlite_id]);
    if(result.isNotEmpty){
      return BranchLinkProduct.fromJson(result.first);
    } else {
      return null;
    }
  }

/*
  read specific branch link product item
*/
  Future<BranchLinkProduct?> readSpecificAvailableBranchLinkProduct(String branch_link_product_sqlite_id) async {
    final db = await instance.database;
    final result = await db.rawQuery(
        'SELECT a.*, b.name FROM $tableBranchLinkProduct AS a JOIN $tableProduct AS b ON a.product_id = b.product_id '
        'WHERE a.soft_delete = ? AND b.soft_delete = ? AND a.branch_link_product_sqlite_id = ? AND b.available = ?',
        ['', '', branch_link_product_sqlite_id, 1]);

    if (result.isNotEmpty) {
      return BranchLinkProduct.fromJson(result.first);
    } else {
      return null;
    }
  }

/*
  read branch product variant
*/
  Future<List<BranchLinkProduct>> readBranchLinkProductVariant(String branch_link_product_sqlite_id) async {
    final db = await instance.database;
    final result = await db.rawQuery(
        'SELECT a.*, b.variant_name FROM $tableBranchLinkProduct AS a JOIN $tableProductVariant AS b ON a.product_variant_id = b.product_variant_id WHERE a.branch_link_product_sqlite_id = ?',
        [branch_link_product_sqlite_id]);

    return result.map((json) => BranchLinkProduct.fromJson(json)).toList();
  }

/*
  checking product variant
*/
  Future<List<BranchLinkProduct>> checkProductVariant(String product_variant_id, String product_id) async {
    final db = await instance.database;
    final result = await db
        .rawQuery('SELECT * FROM $tableBranchLinkProduct WHERE soft_delete =? AND product_variant_sqlite_id = ? AND product_sqlite_id = ?', ['', product_variant_id, product_id]);

    return result.map((json) => BranchLinkProduct.fromJson(json)).toList();
  }

/*
  checking product
*/
  Future<List<Product>> checkSpecificProduct(String product_id) async {
    final db = await instance.database;
    final result = await db
        .rawQuery('SELECT * FROM $tableProduct WHERE soft_delete =? AND product_sqlite_id = ?', ['', product_id]);

    return result.map((json) => Product.fromJson(json)).toList();
  }

/*
  read branch link dining option
*/
  Future<List<BranchLinkDining>> readBranchLinkDiningOption(String branch_id) async {
    final db = await instance.database;
    final result = await db.rawQuery(
        'SELECT a.*, b.name FROM $tableBranchLinkDining AS a JOIN $tableDiningOption AS b ON a.dining_id = b.dining_id WHERE a.soft_delete = ? AND b.soft_delete = ? AND a.branch_id = ?',
        ['', '', branch_id]);

    return result.map((json) => BranchLinkDining.fromJson(json)).toList();
  }

/*
  read all tax link dining
*/
  Future<List<TaxLinkDining>> readAllTaxLinkDining() async {
    final db = await instance.database;
    final result = await db.rawQuery(
        'SELECT a.*, b.tax_rate, b.name AS tax_name, c.name AS dining_name '
            'FROM $tableTaxLinkDining AS a JOIN $tableTax AS b ON a.tax_id = b.tax_id '
            'JOIN $tableDiningOption AS c ON a.dining_id = c.dining_id WHERE a.soft_delete = ? AND b.soft_delete = ? AND c.soft_delete = ?',
        ['', '', '']);

    return result.map((json) => TaxLinkDining.fromJson(json)).toList();
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
    final result = await db.rawQuery('SELECT dining_id FROM $tableDiningOption WHERE soft_delete = ? AND name = ?', ['', name]);

    return result.map((json) => DiningOption.fromJson(json)).toList();
  }

/*
  get tax rate/ name
*/
  Future<List<Tax>> readTax(String dining_id) async {
    final db = await instance.database;
    final result = await db.rawQuery(
        'SELECT b.* FROM $tableBranchLinkTax AS a JOIN $tableTax as B ON a.tax_id = b.tax_id JOIN $tableTaxLinkDining as c ON a.tax_id = c.tax_id WHERE c.dining_id = ? AND a.soft_delete = ? AND b.soft_delete = ? AND c.soft_delete = ?',
        [dining_id, '', '', '']);

    return result.map((json) => Tax.fromJson(json)).toList();
  }

/*
  read Branch link promotion
*/
  Future<List<BranchLinkPromotion>> readBranchLinkPromotion() async {
    final db = await instance.database;
    final result = await db.rawQuery('SELECT * FROM $tableBranchLinkPromotion WHERE soft_delete = ?', ['']);
    // 'SELECT a.*, b.name FROM $tableBranchLinkPromotion AS a JOIN $tablePromotion AS b ON a.promotion_id = b.promotion_id WHERE a.soft_delete = ? AND b.soft_delete = ? AND a.branch_id = ?',
    // ['', '', branch_id]);

    return result.map((json) => BranchLinkPromotion.fromJson(json)).toList();
  }

/*
  check promotion
*/
  Future<List<Promotion>> checkPromotion(String promotion_id) async {
    final db = await instance.database;
    final result = await db.rawQuery('SELECT * FROM $tablePromotion WHERE soft_delete = ? AND promotion_id = ?', ['', promotion_id]);

    return result.map((json) => Promotion.fromJson(json)).toList();
  }

/*
  read all branch link modifier price
*/
  Future<List<BranchLinkModifier>> readAllBranchLinkModifier() async {
    final db = await instance.database;
    final result = await db.rawQuery('SELECT * FROM $tableBranchLinkModifier WHERE soft_delete = ?', ['']);

    return result.map((json) => BranchLinkModifier.fromJson(json)).toList();
  }

/*
  read branch link modifier price
*/
  Future<List<BranchLinkModifier>> readBranchLinkModifier(String mod_item_id) async {
    final db = await instance.database;
    final result = await db.rawQuery('SELECT * FROM $tableBranchLinkModifier WHERE soft_delete = ? AND mod_item_id = ?', ['', mod_item_id]);

    return result.map((json) => BranchLinkModifier.fromJson(json)).toList();
  }

/*
  read app colors
*/
  Future<List<AppColors>> readAppColors() async {
    final db = await instance.database;
    final result = await db.rawQuery('SELECT * FROM $tableAppColors WHERE soft_delete = ? ', ['']);
    return result.map((json) => AppColors.fromJson(json)).toList();
  }

/*
  read all category (-)
*/
  Future<List<Categories>> readAllCategory() async {
    final db = await instance.database;
    final result = await db.rawQuery('SELECT * FROM $tableCategories WHERE soft_delete = ? ', ['']);
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
        'SELECT DISTINCT a.* , (SELECT COUNT(b.product_sqlite_id) from $tableProduct AS b where b.category_sqlite_id = a.category_sqlite_id AND b.soft_delete = ?) item_sum FROM $tableCategories AS a JOIN $tableProduct AS b ON a.category_sqlite_id = b.category_sqlite_id JOIN $tableBranchLinkProduct AS c ON b.product_sqlite_id = c.product_sqlite_id WHERE a.soft_delete = ? AND b.soft_delete = ? AND c.soft_delete = ? AND b.available = ? ORDER BY a.sequence ',
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
  read all product
*/
  Future<List<Product>> readAllProductForProductSetting() async {
    final db = await instance.database;
    final result = await db.rawQuery(
        'SELECT DISTINCT a.* FROM $tableProduct AS a JOIN $tableBranchLinkProduct AS b ON a.product_id = b.product_id WHERE a.soft_delete = ? AND b.soft_delete = ?', ['', '']);
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
    final result = await db.rawQuery('SELECT MAX(SKU) as SKU FROM $tableProduct WHERE soft_delete = ? AND company_id = ?', ['', companyID]);
    return result.map((json) => Product.fromJson(json)).toList();
  }

/*
  check sku for add product
*/
  Future<List<Product>> checkProductSKU(String sku) async {
    final db = await instance.database;
    final result = await db.rawQuery('SELECT * FROM $tableProduct WHERE soft_delete = ? AND SKU = ?', ['', sku]);
    return result.map((json) => Product.fromJson(json)).toList();
  }

/*
  check sku for edit product
*/
  Future<List<Product>> checkProductSKUForEdit(String sku, int product_sqlite_id) async {
    final db = await instance.database;
    final result = await db.rawQuery('SELECT * FROM $tableProduct WHERE soft_delete = ? AND SKU = ? AND product_sqlite_id != ?', ['', sku, product_sqlite_id]);
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
  search table
*/
  Future<List<PosTable>> searchTable(String text) async {
    final db = await instance.database;
    final result = await db
        .rawQuery('SELECT * FROM $tablePosTable WHERE soft_delete = ? AND (number LIKE ? OR seats LIKE ?) ORDER BY table_sqlite_id ', ['', '%' + text + '%', '%' + text + '%']);
    return result.map((json) => PosTable.fromJson(json)).toList();
  }

/*
  search paid receipt
*/
  Future<List<Order>> searchPaidReceipt(String text) async {
    final db = await instance.database;
    final result = await db.rawQuery(
        'SELECT * FROM $tableOrder WHERE payment_status = ? AND soft_delete = ? AND (order_number LIKE ? OR close_by LIKE ?) ORDER BY created_at DESC ',
        [1, '', '%' + text + '%', '%' + text + '%']);
    return result.map((json) => Order.fromJson(json)).toList();
  }

/*
  search refund receipt
*/
  Future<List<Order>> searchRefundReceipt(String text) async {
    final db = await instance.database;
    final result = await db.rawQuery(
        'SELECT a.*, b.refund_by AS refund_name FROM $tableOrder AS a JOIN $tableRefund AS b ON a.refund_key = b.refund_key WHERE a.payment_status = ? AND a.soft_delete = ? AND b.soft_delete = ? AND (a.order_number LIKE ? OR b.refund_by LIKE ?) ORDER BY created_at DESC ',
        [2, '', '', '%' + text + '%', '%' + text + '%']);
    return result.map((json) => Order.fromJson(json)).toList();
  }

/*
  read product variant group name
*/
  Future<List<VariantGroup>> readProductVariantGroup(int productID) async {
    final db = await instance.database;
    final result = await db.rawQuery(
        'SELECT DISTINCT a.variant_group_sqlite_id, a.variant_group_id, a.product_sqlite_id, a.name, a.created_at, a.updated_at, a.soft_delete FROM $tableVariantGroup AS a JOIN $tableBranchLinkProduct AS b ON a.product_sqlite_id = b.product_sqlite_id JOIN $tableProductVariant AS c ON b.product_variant_sqlite_id = c.product_variant_sqlite_id JOIN $tableProductVariantDetail AS d ON c.product_variant_sqlite_id = d.product_variant_sqlite_id JOIN $tableVariantItem AS e ON d.variant_item_sqlite_id = e.variant_item_sqlite_id AND e.variant_group_sqlite_id = a.variant_group_sqlite_id WHERE a.soft_delete = ? AND b.soft_delete = ? AND c.soft_delete = ? AND d.soft_delete = ? AND e.soft_delete = ? AND a.product_sqlite_id = ?',
        ['', '', '', '', '', productID]);
    return result.map((json) => VariantGroup.fromJson(json)).toList();
  }

/*
  read product variant group name
*/
  Future<List<VariantGroup>> readAllVariantGroup(String productID) async {
    final db = await instance.database;
    final result = await db.rawQuery('SELECT * FROM $tableVariantGroup WHERE soft_delete = ? AND product_sqlite_id = ?', ['', productID]);
    return result.map((json) => VariantGroup.fromJson(json)).toList();
  }

/*
  read product variant group item
*/
  Future<List<VariantItem>> readProductVariantItem(int variantGroupID) async {
    final db = await instance.database;
    final result = await db.rawQuery(
        'SELECT DISTINCT a.variant_item_sqlite_id, a.variant_item_id, a.variant_group_id, a.variant_group_sqlite_id, a.name, a.created_at, a.updated_at, a.soft_delete FROM $tableVariantItem AS a JOIN $tableVariantGroup AS b ON a.variant_group_id = b.variant_group_id JOIN $tableProductVariantDetail AS c ON a.variant_item_id = c.variant_item_id WHERE a.soft_delete = ? AND b.soft_delete = ? AND c.soft_delete = ? AND a.variant_group_sqlite_id = ?',
        ['', '', '', variantGroupID]);
    return result.map((json) => VariantItem.fromJson(json)).toList();
  }

/*
  read product modifier group name
*/
  Future<List<ModifierGroup>> readProductModifierGroupName(int productID) async {
    final db = await instance.database;
    final result = await db.rawQuery(
        'SELECT a.* FROM $tableModifierGroup AS a JOIN $tableModifierLinkProduct AS b ON a.mod_group_id = b.mod_group_id '
        'WHERE a.soft_delete = ? AND b.soft_delete = ? AND b.product_sqlite_id = ?',
        ['', '', productID]);
    return result.map((json) => ModifierGroup.fromJson(json)).toList();
  }

/*
  read all product modifier group name
*/
  Future<List<ModifierGroup>> readAllModifier() async {
    final db = await instance.database;
    final result = await db.rawQuery('SELECT * FROM $tableModifierGroup WHERE soft_delete = ?', ['']);
    return result.map((json) => ModifierGroup.fromJson(json)).toList();
  }

/*
  read all product modifier group name
*/
  Future<List<ModifierLinkProduct>> readProductModifier(String product_sqlite_id) async {
    final db = await instance.database;
    final result = await db.rawQuery('SELECT * FROM $tableModifierLinkProduct WHERE soft_delete = ? AND product_sqlite_id = ?', ['', product_sqlite_id]);
    return result.map((json) => ModifierLinkProduct.fromJson(json)).toList();
  }

/*
  read product modifier group item
*/
  Future<List<ModifierItem>> readProductModifierItem(int modGroupID) async {
    final db = await instance.database;
    final result = await db.rawQuery(
        'SELECT a.*, b.status AS mod_status FROM $tableModifierItem AS a LEFT JOIN $tableBranchLinkModifier AS b ON a.mod_item_id = b.mod_item_id '
        'WHERE a.soft_delete = ? AND b.soft_delete = ? AND a.mod_group_id = ? AND b.status = ? ORDER BY a.sequence',
        ['', '', modGroupID, '1']);
    return result.map((json) => ModifierItem.fromJson(json)).toList();
  }

/*
  read product category
*/
  Future<List<Product>> readSpecificProductCategory(String product_id) async {
    final db = await instance.database;
    final result = await db.rawQuery('SELECT * FROM $tableProduct WHERE soft_delete = ? AND product_id = ?', ['', product_id]);

    return result.map((json) => Product.fromJson(json)).toList();
  }

/*
  read all table
*/
  Future<List<PosTable>> readAllTable() async {
    final db = await instance.database;
    final result = await db.rawQuery('SELECT * FROM $tablePosTable WHERE soft_delete = ? ORDER BY table_sqlite_id ', ['']);
    return result.map((json) => PosTable.fromJson(json)).toList();
  }

/*
  read table id by table no
*/
  Future<List<PosTable>> readSpecificTableByTableNo(String number) async {
    final db = await instance.database;
    final result = await db.rawQuery('SELECT * FROM $tablePosTable WHERE soft_delete = ? AND number = ?', ['', number]);

    return result.map((json) => PosTable.fromJson(json)).toList();
  }

/*
  read table id by table id
*/
  Future<List<PosTable>> readSpecificTable(String table_sqlite_id) async {
    final db = await instance.database;
    final result = await db.rawQuery('SELECT * FROM $tablePosTable WHERE soft_delete = ? AND table_sqlite_id = ?', ['', table_sqlite_id]);

    return result.map((json) => PosTable.fromJson(json)).toList();
  }

/*
  read table id by table no included deleted
*/
  Future<List<PosTable>> readSpecificTableIncludeDeleted(String table_sqlite_id) async {
    final db = await instance.database;
    final result = await db.rawQuery('SELECT * FROM $tablePosTable WHERE table_sqlite_id = ?', [table_sqlite_id]);

    return result.map((json) => PosTable.fromJson(json)).toList();
  }

/*
  read table by cloud id
*/
  Future<PosTable> readTableByCloudId(String table_id) async {
    final db = await instance.database;
    final result = await db.rawQuery('SELECT * FROM $tablePosTable WHERE table_id = ?', [table_id]);
    return PosTable.fromJson(result.first);
  }

/*
  check table status
*/
  Future<List<PosTable>> checkPosTableStatus(int table_sqlite_id) async {
    final db = await instance.database;
    final result = await db.rawQuery('SELECT * FROM $tablePosTable WHERE soft_delete = ? AND table_sqlite_id = ?', ['', table_sqlite_id]);

    return result.map((json) => PosTable.fromJson(json)).toList();
  }

/*
  read branch all table use id
*/
  Future<List<TableUse>> readAllTableUseId(int branch_id) async {
    final db = await instance.database;
    final result = await db.rawQuery('SELECT * FROM $tableTableUse WHERE soft_delete = ? AND status = ? AND branch_id = ? ', ['', 0, branch_id]);

    return result.map((json) => TableUse.fromJson(json)).toList();
  }

/*
  read Specific table use
*/
  Future<List<TableUse>> readSpecificTableUseId(int table_use_sqlite_id) async {
    final db = await instance.database;
    final result = await db.rawQuery('SELECT * FROM $tableTableUse WHERE soft_delete = ? AND status = ? AND table_use_sqlite_id = ? ', ['', 0, table_use_sqlite_id]);

    return result.map((json) => TableUse.fromJson(json)).toList();
  }

/*
  read Specific table use by table use local id
*/
  Future<TableUse> readSpecificTableUseIdByLocalId(int table_use_sqlite_id) async {
    final db = await instance.database;
    final result = await db.rawQuery('SELECT * FROM $tableTableUse WHERE table_use_sqlite_id = ? ', [table_use_sqlite_id]);

    return TableUse.fromJson(result.first);
  }

/*
  read use table detail by table use key
*/
  Future<List<TableUseDetail>> readTableUseDetailByTableUseKey(String table_use_key) async {
    final db = await instance.database;
    final result = await db.rawQuery('SELECT * FROM $tableTableUseDetail WHERE soft_delete = ? AND table_use_key = ? ', ['', table_use_key]);

    return result.map((json) => TableUseDetail.fromJson(json)).toList();
  }

/*
  read table use detail by table use detail key
*/
  Future<TableUseDetail?> readTableUseDetailByKey(String key) async {
    final db = await instance.database;
    final result = await db.rawQuery('SELECT * FROM $tableTableUseDetail WHERE soft_delete = ? AND table_use_detail_key = ? ', ['', key]);
    if(result.isNotEmpty){
      return TableUseDetail.fromJson(result.first);
    } else {
      return null;
    }
  }

/*
  read specific use table detail based on table id
*/
  Future<List<TableUseDetail>> readSpecificTableUseDetail(int table_sqlite_id) async {
    final db = await instance.database;
    final result = await db.rawQuery(
        'SELECT a.* FROM $tableTableUseDetail AS a '
        'JOIN $tablePosTable AS b ON a.table_sqlite_id = b.table_sqlite_id '
        'WHERE a.soft_delete = ? AND b.soft_delete = ? AND a.table_sqlite_id = ? AND a.status = ? ORDER BY table_use_detail_sqlite_id DESC LIMIT 1',
        ['', '', table_sqlite_id, 0]);

    return result.map((json) => TableUseDetail.fromJson(json)).toList();
  }

/*
  read specific use table detail based on table id (only table is in used)
*/
  Future<List<TableUseDetail>> readSpecificInUsedTableUseDetail(int table_sqlite_id) async {
    final db = await instance.database;
    final result = await db.rawQuery(
        'SELECT a.*, b.table_id AS table_local_id FROM $tableTableUseDetail AS a '
        'JOIN $tablePosTable AS b ON a.table_sqlite_id = b.table_sqlite_id '
        'WHERE a.soft_delete = ? AND b.soft_delete = ? AND a.table_sqlite_id = ? AND a.status = ? AND b.status = ? ORDER BY table_use_detail_sqlite_id DESC LIMIT 1',
        ['', '', table_sqlite_id, 0, 1]);

    return result.map((json) => TableUseDetail.fromJson(json)).toList();
  }

/*
  read specific use table detail based on table use detail local id
*/
  Future<TableUseDetail> readSpecificTableUseDetailByLocalId(int table_use_detail_sqlite_id) async {
    final db = await instance.database;
    final result = await db.rawQuery('SELECT * FROM $tableTableUseDetail WHERE table_use_detail_sqlite_id = ?', [table_use_detail_sqlite_id]);

    return TableUseDetail.fromJson(result.first);
  }

/*
  read all occurrence table detail based on table use id
*/
  Future<List<TableUseDetail>> readAllTableUseDetail(String table_use_sqlite_id) async {
    final db = await instance.database;
    final result = await db.rawQuery('SELECT * FROM $tableTableUseDetail WHERE soft_delete = ? AND status = ? AND table_use_sqlite_id = ?', ['', 0, table_use_sqlite_id]);

    return result.map((json) => TableUseDetail.fromJson(json)).toList();
  }

/*
  read all table detail based on table use id(inc deleted)
*/
  Future<List<TableUseDetail>> readAllDeletedTableUseDetail(String table_use_sqlite_id) async {
    final db = await instance.database;
    final result = await db.rawQuery('SELECT * FROM $tableTableUseDetail WHERE table_use_sqlite_id = ?', [table_use_sqlite_id]);

    return result.map((json) => TableUseDetail.fromJson(json)).toList();
  }

  /*
  read latest order cache
*/
  Future<List<OrderCache>> readBranchLatestOrderCache(int branch_id) async {
    final db = await instance.database;
    final result = await db.rawQuery(
        'SELECT a.*, b.name FROM $tableOrderCache AS a JOIN $tableDiningOption AS b ON a.dining_id = b.dining_id '
        'WHERE a.soft_delete = ? AND b.soft_delete = ? AND a.branch_id = ? AND a.cancel_by = ? AND a.accepted = ? ORDER BY a.created_at DESC LIMIT 1',
        ['', '', branch_id, '', 0]);
    return result.map((json) => OrderCache.fromJson(json)).toList();
  }

/*
  read all order cache
*/
  Future<List<OrderCache>> readBranchOrderCache(int branch_id) async {
    final db = await instance.database;
    final result = await db
        .rawQuery('SELECT * FROM $tableOrderCache WHERE order_key = ? AND soft_delete = ? AND accepted = ? AND cancel_by = ? AND branch_id = ?', ['', '', 0, '', branch_id]);
    return result.map((json) => OrderCache.fromJson(json)).toList();
  }

/*
  read specific order cache
*/
  Future<List<OrderCache>> readSpecificOrderCache(String order_cache_sqlite_id) async {
    final db = await instance.database;
    final result = await db
        .rawQuery('SELECT * FROM $tableOrderCache WHERE soft_delete = ? AND accepted = ? AND cancel_by = ? AND order_cache_sqlite_id = ?', ['', 0, '', order_cache_sqlite_id]);
    return result.map((json) => OrderCache.fromJson(json)).toList();
  }

/*
  read specific order cache
*/
  Future<OrderCache> readSpecificOrderCacheByLocalId(int order_cache_sqlite_id) async {
    final db = await instance.database;
    final result = await db.rawQuery(
        'SELECT a.soft_delete, a.updated_at, a.created_at, a.sync_status, a.accepted, a.qr_order_table_id, a.qr_order_table_sqlite_id, a.qr_order, a.total_amount, '
        'a.customer_id, a.cancel_by_user_id, a.cancel_by, '
        'a.order_by_user_id, a.order_by, a.order_key, a.order_sqlite_id, a.dining_id, a.batch_id, a.table_use_key, a.table_use_sqlite_id, a.order_detail_id, a.branch_id, '
        'a.company_id, a.order_queue, a.order_cache_key, a.order_cache_id, a.order_cache_sqlite_id, '
        'b.name AS name FROM $tableOrderCache AS a JOIN $tableDiningOption AS b ON a.dining_id = b.dining_id WHERE a.order_cache_sqlite_id = ? AND b.soft_delete = ?',
        [order_cache_sqlite_id, '']);
    return OrderCache.fromJson(result.first);
  }

/*
  read specific order cache without joing dining option
*/
  Future<OrderCache> readSpecificOrderCacheByLocalId2(int order_cache_sqlite_id) async {
    final db = await instance.database;
    final result = await db.rawQuery(
        'SELECT * FROM $tableOrderCache WHERE order_cache_sqlite_id = ? AND soft_delete = ?',
        [order_cache_sqlite_id, '']);
    return OrderCache.fromJson(result.first);
  }

/*
  read specific order cache(deleted)
*/
  Future<List<OrderCache>> readSpecificDeletedOrderCache(int order_cache_sqlite_id) async {
    final db = await instance.database;
    final result = await db.rawQuery(
        'SELECT a.*, b.name FROM $tableOrderCache AS a JOIN $tableDiningOption AS b ON a.dining_id = b.dining_id '
        'WHERE a.order_cache_sqlite_id = ? AND b.soft_delete = ?',
        [order_cache_sqlite_id, '']);
    return result.map((json) => OrderCache.fromJson(json)).toList();
  }

/*
  read table order cache
*/
  Future<List<OrderCache>> readTableOrderCache(String table_use_key) async {
    try {
      final db = await instance.database;
      final result = await db.rawQuery(
          'SELECT a.*, b.card_color FROM $tableOrderCache AS a JOIN $tableTableUse AS b ON a.table_use_key = b.table_use_key '
          'WHERE a.soft_delete = ? AND b.soft_delete = ? AND a.table_use_key = ? AND a.cancel_by = ? AND a.accepted = ? AND b.status = ? '
          'ORDER BY a.order_cache_sqlite_id DESC',
          ['', '', table_use_key, '', 0, 0]);
      return result.map((json) => OrderCache.fromJson(json)).toList();
    } catch (e) {
      print(e);
      return [];
    }
  }

/*
  get all order cache except dine in
*/
  Future<List<OrderCache>> readOrderCacheNoDineIn(String branch_id, String company_id) async {
    try {
      final db = await instance.database;
      final result = await db.rawQuery(
          'SELECT a.order_cache_sqlite_id, a.order_cache_key, a.order_queue ,a.order_detail_id, a.dining_id, a.table_use_sqlite_id, a.table_use_key, a.batch_id, a.order_sqlite_id, a.order_key, '
          'a.order_by, a.total_amount, a.customer_id, a.created_at, a.updated_at, a.soft_delete, b.name AS name '
          'FROM tb_order_cache as a JOIN tb_dining_option as b ON a.dining_id = b.dining_id '
          'WHERE a.order_key = ? AND a.soft_delete= ? AND b.soft_delete = ? AND a.branch_id = ? '
          'AND a.company_id = ? AND a.accepted = ? AND cancel_by = ? AND a.table_use_key = ? ORDER BY a.created_at DESC  ',
          ['', '', '', branch_id, company_id, 0, '', '']);

      return result.map((json) => OrderCache.fromJson(json)).toList();
    } catch (e) {
      print(e);
      return [];
    }
  }

  /*
  get order cache for different dine in option
*/
  Future<List<OrderCache>> readOrderCacheSpecial(String name) async {
    try {
      final db = await instance.database;
      final result = await db.rawQuery(
          'SELECT a.order_cache_sqlite_id, a.order_queue, a.order_detail_id, a.dining_id, a.table_use_sqlite_id, a.table_use_key, a.batch_id, a.dining_id, '
          'a.order_sqlite_id, a.order_by, a.order_key, a.cancel_by, a.total_amount, a.customer_id, '
          'a.created_at, a.updated_at, a.soft_delete, b.name AS name '
          'FROM tb_order_cache as a JOIN tb_dining_option as b ON a.dining_id = b.dining_id '
          'WHERE a.order_key = ? AND a.soft_delete=? AND b.soft_delete=? AND a.cancel_by = ? AND b.name = ? AND a.table_use_key = ?',
          ['', '', '', '', name, '']);

      return result.map((json) => OrderCache.fromJson(json)).toList();
    } catch (e) {
      print(e);
      return [];
    }
  }

/*
  read order detail by order cache
*/
  Future<List<OrderDetail>> readTableOrderDetail(String order_cache_key) async {
    final db = await instance.database;
    final result = await db.rawQuery(
        'SELECT a.*, b.total_amount FROM $tableOrderDetail AS a JOIN $tableOrderCache AS b ON a.order_cache_key = b.order_cache_key '
        'WHERE a.soft_delete = ? AND b.soft_delete = ? AND a.order_cache_key = ? AND a.status = ? AND b.accepted = ? AND b.cancel_by = ? ',
        ['', '', order_cache_key, 0, 0, '']);

    return result.map((json) => OrderDetail.fromJson(json)).toList();
  }

/*
  read order detail by order cache (deleted)
*/
  Future<List<OrderDetail>> readDeletedOrderDetail(String order_cache_sqlite_id) async {
    final db = await instance.database;
    final result = await db.rawQuery(
        'SELECT a.remark, a.product_variant_name, a.has_variant, a.product_name, a.category_sqlite_id, a.per_quantity_unit, a.unit, '
        'a.branch_link_product_sqlite_id, a.order_cache_key, a.order_cache_key, a.order_detail_key, a.order_detail_sqlite_id, '
        'b.quantity AS item_cancel, b.cancel_by FROM $tableOrderDetail AS a JOIN $tableOrderDetailCancel AS b ON a.order_detail_sqlite_id = b.order_detail_sqlite_id '
        'WHERE a.order_cache_sqlite_id = ? AND a.soft_delete = ? ORDER BY b.order_detail_cancel_sqlite_id DESC LIMIT 1',
        [order_cache_sqlite_id, '']);

    return result.map((json) => OrderDetail.fromJson(json)).toList();
  }

/*
  read specific order detail by local id
*/
  Future<OrderDetail> readSpecificOrderDetailByLocalId(int order_detail_sqlite_id) async {
    final db = await instance.database;
    final result = await db.rawQuery(
        'SELECT a.soft_delete, a.updated_at, a.created_at, a.per_quantity_unit, a.unit, a.sync_status, a.status, a.cancel_by_user_id, a.cancel_by, a.edited_by_user_id, a.edited_by, '
        'a.account, a.remark, a.quantity, a.original_price, a.price, a.product_variant_name, a.has_variant, a.product_name, a.category_name, a.order_cache_key, a.order_cache_sqlite_id, '
        'a.order_detail_key, IFNULL( (SELECT category_id FROM $tableCategories WHERE category_sqlite_id = a.category_sqlite_id), 0) AS category_id,'
        'c.branch_link_product_id FROM $tableOrderDetail AS a '
        'LEFT JOIN $tableBranchLinkProduct AS c ON a.branch_link_product_sqlite_id = c.branch_link_product_sqlite_id '
        'WHERE a.order_detail_sqlite_id = ? ',
        [order_detail_sqlite_id]);

    return OrderDetail.fromJson(result.first);
  }

/*
  read specific order modifier detail by local id
*/
  Future<OrderModifierDetail> readSpecificOrderModifierDetailByLocalId(int order_modifier_detail_sqlite_id) async {
    final db = await instance.database;
    final result = await db.rawQuery('SELECT * FROM $tableOrderModifierDetail WHERE order_modifier_detail_sqlite_id = ? ', [order_modifier_detail_sqlite_id]);

    return OrderModifierDetail.fromJson(result.first);
  }

/*
  read order modifier detail by order cache (deleted)
*/
  Future<List<OrderModifierDetail>> readDeletedOrderModifierDetail(String order_detail_sqlite_id) async {
    final db = await instance.database;
    final result = await db.rawQuery('SELECT * FROM $tableOrderModifierDetail WHERE order_detail_sqlite_id = ?', [order_detail_sqlite_id]);

    return result.map((json) => OrderModifierDetail.fromJson(json)).toList();
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
  Future<List<OrderModifierDetail>> readOrderModifierDetail(String order_detail_sqlite_id) async {
    final db = await instance.database;
    final result = await db.rawQuery('SELECT a.* FROM $tableOrderModifierDetail AS a WHERE a.soft_delete = ? AND a.order_detail_sqlite_id = ?', ['', order_detail_sqlite_id]);

    return result.map((json) => OrderModifierDetail.fromJson(json)).toList();
  }

/*
  read order mod detail
*/
  Future<OrderModifierDetail?> readOrderModifierDetailOne(String order_detail_id) async {
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
  read all user
*/
  Future<List<User>> readAllUser() async {
    final db = await instance.database;
    final result = await db.rawQuery('SELECT * FROM $tableUser WHERE soft_delete = ? ', ['']);
    return result.map((json) => User.fromJson(json)).toList();
  }

/*
  read specific user
*/
  Future<List<User>> readSpecificUserWithRole(String pin) async {
    final db = await instance.database;
    final result = await db.rawQuery('SELECT * FROM $tableUser WHERE soft_delete = ? AND role = ? AND pos_pin = ?', ['', 0, pin]);
    return result.map((json) => User.fromJson(json)).toList();
  }

/*
  read specific user with pin
*/
  Future<User?> readSpecificUserWithPin(String pin) async {
    final db = await instance.database;
    final result = await db.rawQuery('SELECT * FROM $tableUser WHERE soft_delete = ? AND pos_pin = ?', ['', pin]);
    if (result.isNotEmpty) {
      return User.fromJson(result.first);
    } else {
      return null;
    }
  }

  /*
  read attendance
*/
  Future<Attendance?> readAttendance(int user_id) async {
    final db = await instance.database;
    final result = await db.rawQuery('SELECT * FROM $tableAttendance WHERE user_id = ? AND soft_delete = ? AND clock_out_at = ?', [user_id, '', '']);
    if (result.isNotEmpty) {
      return Attendance.fromJson(result.first);
    } else {
      return null;
    }
  }

  /*
  read all the dining option for company
*/
  Future<List<DiningOption>> readAllDiningOption() async {
    final db = await instance.database;
    final result = await db.rawQuery('SELECT * FROM $tableDiningOption WHERE soft_delete = ?', ['']);
    return result.map((json) => DiningOption.fromJson(json)).toList();
  }

/*
  read specific
*/
  Future<OrderDetailCancel> readSpecificOrderDetailCancelByLocalId(int local_id) async {
    final db = await instance.database;
    final result = await db.rawQuery('SELECT * FROM $tableOrderDetailCancel WHERE order_detail_cancel_sqlite_id = ?', [local_id]);
    return OrderDetailCancel.fromJson(result.first);
  }

/*
  ----------------------------Printer part--------------------------------------------------------------------------------------------------------------------------------
*/

/*
  read specific printer link category
*/
  Future<PrinterLinkCategory> readSpecificPrinterCategoryByLocalId(int local_id) async {
    final db = await instance.database;
    final result = await db.rawQuery('SELECT * FROM $tablePrinterLinkCategory WHERE printer_link_category_sqlite_id = ?', [local_id]);
    return PrinterLinkCategory.fromJson(result.first);
  }

/*
  read specific printer
*/
  Future<Printer> readSpecificPrinterByLocalId(int local_id) async {
    final db = await instance.database;
    final result = await db.rawQuery('SELECT * FROM $tablePrinter WHERE printer_sqlite_id = ?', [local_id]);
    return Printer.fromJson(result.first);
  }

/*
  read branch All printer
*/
  Future<List<Printer>> readAllBranchPrinter() async {
    final db = await instance.database;
    final result = await db.rawQuery('SELECT * FROM $tablePrinter WHERE soft_delete = ? ', ['']);
    return result.map((json) => Printer.fromJson(json)).toList();
  }

/*
  read printer link category
*/
  Future<List<PrinterLinkCategory>> readDeletedPrinterLinkCategory(int printer_sqlite_id) async {
    final db = await instance.database;
    final result = await db.rawQuery('SELECT * FROM $tablePrinterLinkCategory WHERE soft_delete != ? AND printer_sqlite_id = ?', ['', printer_sqlite_id]);
    return result.map((json) => PrinterLinkCategory.fromJson(json)).toList();
  }

/*
  read printer link category
*/
  Future<List<PrinterLinkCategory>> readPrinterLinkCategory(int printer_sqlite_id) async {
    final db = await instance.database;
    final result = await db.rawQuery('SELECT * FROM $tablePrinterLinkCategory WHERE soft_delete = ? AND printer_sqlite_id = ?', ['', printer_sqlite_id]);
    return result.map((json) => PrinterLinkCategory.fromJson(json)).toList();
  }

/*
  read specific category (category id)
*/
  Future<Categories?> readSpecificCategoryById(String category_sqlite_id) async {
    final db = await instance.database;
    final result = await db.rawQuery('SELECT * FROM $tableCategories WHERE soft_delete = ? AND category_sqlite_id = ? ', ['', category_sqlite_id]);
    if (result.isNotEmpty) {
      return Categories.fromJson(result.first);
    } else {
      return null;
    }
  }

/*
  ----------------------------Receipt layout part------------------------------------------------------------------------------------------------
*/

// /*
//   read all receipt layout
// */
//   Future<List<Receipt>> readAllReceipt() async {
//     final db = await instance.database;
//     final result = await db
//         .rawQuery('SELECT * FROM $tableReceipt WHERE soft_delete = ? ', ['']);
//     return result.map((json) => Receipt.fromJson(json)).toList();
//   }

/*
  read all receipt layout
*/
  Future<Receipt?> readAllReceipt() async {
    final db = await instance.database;
    final result = await db.rawQuery('SELECT * FROM $tableReceipt WHERE soft_delete = ? ', ['']);
    return Receipt.fromJson(result.first);
  }

/*
  read specific receipt layout
*/
  Future<Receipt?> readSpecificReceipt(String paperSize) async {
    final db = await instance.database;
    final result = await db.rawQuery('SELECT * FROM $tableReceipt WHERE soft_delete = ? AND paper_size = ? ', ['', paperSize]);
    return Receipt.fromJson(result.first);
  }

/*
  read specific receipt layout by key
*/
  Future<Receipt?> readSpecificReceiptByKey(String key) async {
    final db = await instance.database;
    final result = await db.rawQuery('SELECT * FROM $tableReceipt WHERE soft_delete = ? AND receipt_key = ? ', ['', key]);
    return Receipt.fromJson(result.first);
  }

/*
  ----------------------------Checklist layout part------------------------------------------------------------------------------------------------
*/

/*
  read specific checklist layout by key
*/
  Future<Checklist?> readSpecificChecklistByKey(String key) async {
    final db = await instance.database;
    final result = await db.rawQuery('SELECT * FROM $tableChecklist WHERE soft_delete = ? AND checklist_key = ? ', ['', key]);
    if (result.isNotEmpty) {
      return Checklist.fromJson(result.first);
    } else {
      return null;
    }
  }

/*
  read specific checklist layout
*/
  Future<Checklist?> readSpecificChecklist(String paperSize) async {
    final db = await instance.database;
    final result = await db.rawQuery('SELECT * FROM $tableChecklist WHERE soft_delete = ? AND paper_size = ? ORDER BY checklist_sqlite_id ', ['', paperSize]);
    if (result.isNotEmpty) {
      return Checklist.fromJson(result.first);
    } else {
      return null;
    }
  }

/*
  ----------------------------Kitchen List layout part------------------------------------------------------------------------------------------------
*/

/*
  read specific kitchen_list layout by key
*/
  Future<KitchenList?> readSpecificKitchenListByKey(String key) async {
    final db = await instance.database;
    final result = await db.rawQuery('SELECT * FROM $tableKitchenList WHERE soft_delete = ? AND kitchen_list_key = ? ', ['', key]);
    if (result.isNotEmpty) {
      return KitchenList.fromJson(result.first);
    } else {
      return null;
    }
  }

/*
  read specific kitchen_list layout
*/
  Future<KitchenList?> readSpecificKitchenList(String paperSize) async {
    final db = await instance.database;
    final result = await db.rawQuery('SELECT * FROM $tableKitchenList WHERE soft_delete = ? AND paper_size = ? ORDER BY kitchen_list_sqlite_id ', ['', paperSize]);
    if (result.isNotEmpty) {
      return KitchenList.fromJson(result.first);
    } else {
      return null;
    }
  }

/*
  ----------------------------Cash record part------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
*/
/*
  read all order cache
*/
  Future<List<OrderCache>> readAllUnpaidOrderCache() async {
    final db = await instance.database;
    final result = await db.rawQuery('SELECT * FROM $tableOrderCache WHERE soft_delete = ? AND accepted = ? AND cancel_by = ? AND order_key = ?', ['', 0, '', '']);
    return result.map((json) => OrderCache.fromJson(json)).toList();
  }

  /*
  read all order cache in branch
*/
  Future<List<OrderCache>> readAllOrderCache() async {
    final db = await instance.database;
    final result = await db.rawQuery('SELECT * FROM $tableOrderCache WHERE created_at != ? ORDER BY order_cache_sqlite_id DESC LIMIT 1', ['']);
    return result.map((json) => OrderCache.fromJson(json)).toList();
  }

/*
  read branch cash record(haven't settlement)
*/
  Future<List<CashRecord>> readBranchCashRecord() async {
    final db = await instance.database;
    final result = await db.rawQuery(
        'SELECT a.*, b.name FROM $tableCashRecord AS a JOIN $tableUser AS b ON a.user_id = b.user_id '
        'WHERE a.soft_delete = ? AND a.settlement_key = ? AND b.soft_delete = ? ORDER BY a.created_at DESC',
        ['', '', '']);
    return result.map((json) => CashRecord.fromJson(json)).toList();
  }

/*
  read all branch settlement cash record
  AND SUBSTR(a.created_at, 1, 10) = SUBSTR(?, 1, 10)
*/
  Future<List<CashRecord>> readAllBranchSettlementCashRecord(String branch_id, String date1, String date2) async {
    final db = await instance.database;
    final result = await db.rawQuery(
        'SELECT a.*, b.name FROM $tableCashRecord AS a JOIN $tableUser AS b ON a.user_id = b.user_id '
        'WHERE a.soft_delete = ? AND a.settlement_date != ? AND a.branch_id = ? AND SUBSTR(a.created_at, 1, 10) >= ? AND SUBSTR(a.created_at, 1, 10) < ? AND b.soft_delete = ? ORDER BY a.cash_record_sqlite_id DESC',
        ['', '', branch_id, date1, date2, '']);
    return result.map((json) => CashRecord.fromJson(json)).toList();
  }

/*
  read specific settlement cash record
*/
  Future<List<CashRecord>> readSpecificSettlementCashRecord(String branch_id, String dateTime, String settlement_key) async {
    final db = await instance.database;
    final result = await db.rawQuery(
        'SELECT a.*, b.name FROM $tableCashRecord AS a JOIN $tableUser AS b ON a.user_id = b.user_id WHERE a.soft_delete = ? AND a.settlement_key = ? AND a.branch_id = ? AND b.soft_delete = ?',
        ['', settlement_key, branch_id, '']);
    return result.map((json) => CashRecord.fromJson(json)).toList();
  }

/*
  read all payment link company
*/
  Future<List<PaymentLinkCompany>> readAllPaymentLinkCompany(String company_id) async {
    final db = await instance.database;
    final result = await db.rawQuery('SELECT * FROM $tablePaymentLinkCompany WHERE soft_delete = ? AND company_id = ? ORDER BY name', ['', company_id]);
    return result.map((json) => PaymentLinkCompany.fromJson(json)).toList();
  }

/*
  read all payment link company include soft deleted
*/
  Future<List<PaymentLinkCompany>> readAllPaymentLinkCompanyWithDeleted(String company_id) async {
    final db = await instance.database;
    final result = await db.rawQuery('SELECT * FROM $tablePaymentLinkCompany WHERE company_id = ? ORDER BY name', [company_id]);
    return result.map((json) => PaymentLinkCompany.fromJson(json)).toList();
  }

/*
  read last owner cash record
*/
  Future<CashRecord?> readLastCashRecord() async {
    final db = await instance.database;
    final maps = await db.rawQuery('SELECT * FROM $tableCashRecord WHERE soft_delete = ? ORDER BY cash_record_sqlite_id DESC LIMIT 1', ['']);
    if (maps.isNotEmpty) {
      return CashRecord.fromJson(maps.first);
    }
    return null;
  }

/*
  read latest specific cash record
*/
  Future<List<CashRecord>> readSpecificLatestSettlementCashRecord(String branch_id) async {
    final db = await instance.database;
    final result =
        await db.rawQuery('SELECT * FROM $tableCashRecord WHERE soft_delete = ? AND branch_id = ? AND type = ? ORDER BY settlement_date DESC LIMIT 1', ['', branch_id, 0]);
    return result.map((json) => CashRecord.fromJson(json)).toList();
  }

/*
  read specific cash record(with deleted)
*/
  Future<CashRecord> readSpecificCashRecord(int cash_record_sqlite_id) async {
    final db = await instance.database;
    final result = await db.rawQuery('SELECT * FROM $tableCashRecord WHERE cash_record_sqlite_id = ?', [cash_record_sqlite_id]);
    return CashRecord.fromJson(result.first);
  }

/*
  read specific cash record(with deleted)
*/
  Future<CashRecord?> readSpecificCashRecordByRemark(String remark) async {
    final db = await instance.database;
    final result = await db.rawQuery('SELECT * FROM $tableCashRecord WHERE remark = ? AND soft_delete = ? ', [remark, '']);
    if (result.isNotEmpty) {
      return CashRecord.fromJson(result.first);
    } else {
      return null;
    }
  }

/*
  -----------------------Order part-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
*/

/*
  read all order created order(for generate order number use)
*/
  Future<List<Order>> readLatestOrder() async {
    final db = await instance.database;
    final result = await db.rawQuery('SELECT * FROM $tableOrder WHERE created_at != ? ORDER BY order_sqlite_id DESC LIMIT 1', ['']);
    return result.map((json) => Order.fromJson(json)).toList();
  }

/*
  read specific Order
*/
  Future<Order> readSpecificOrder(int order_sqlite_id) async {
    final db = await instance.database;
    final result = await db.rawQuery('SELECT * FROM $tableOrder WHERE order_sqlite_id = ?', [order_sqlite_id]);
    return Order.fromJson(result.first);
  }

/*
  read all payment method
*/
  Future<List<PaymentLinkCompany>> readPaymentMethods() async {
    final db = await instance.database;
    final result = await db.rawQuery('SELECT * FROM $tablePaymentLinkCompany WHERE soft_delete = ? ', ['']);
    return result.map((json) => PaymentLinkCompany.fromJson(json)).toList();
  }

/*
  read specific payment link company
*/
  Future<PaymentLinkCompany?> readSpecificPaymentLinkCompany(int payment_link_company_id) async {
    final db = await instance.database;
    final result = await db.rawQuery('SELECT * FROM $tablePaymentLinkCompany WHERE payment_link_company_id = ? AND soft_delete = ? ', [payment_link_company_id, '']);
    if (result.isNotEmpty) {
      return PaymentLinkCompany.fromJson(result.first);
    } else {
      return null;
    }
  }

/*
  read payment method by type
*/
  Future<List<PaymentLinkCompany>> readPaymentMethodByType(String type) async {
    final db = await instance.database;
    final result = await db.rawQuery('SELECT * FROM $tablePaymentLinkCompany WHERE soft_delete = ? AND type = ? ', ['', type]);
    return result.map((json) => PaymentLinkCompany.fromJson(json)).toList();
  }

/*
  read specific branch link tax
*/
  Future<List<BranchLinkTax>> readSpecificBranchLinkTax(String branch_id, String tax_id) async {
    final db = await instance.database;
    final result = await db.rawQuery('SELECT * FROM $tableBranchLinkTax WHERE soft_delete = ? AND branch_id = ? AND tax_id = ?', ['', branch_id, tax_id]);
    return result.map((json) => BranchLinkTax.fromJson(json)).toList();
  }

/*
  read specific branch link promotion
*/
  Future<List<BranchLinkPromotion>> readSpecificBranchLinkPromotion(String branch_id, String promotion_id) async {
    final db = await instance.database;
    final result = await db.rawQuery('SELECT * FROM $tableBranchLinkPromotion WHERE soft_delete = ? AND branch_id = ? AND promotion_id = ?', ['', branch_id, promotion_id]);
    return result.map((json) => BranchLinkPromotion.fromJson(json)).toList();
  }

/*
  --------------------Paid order part--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
*/

/*
  read specific order
*/
  Future<List<Order>> readSpecificOrderByOrderKey(String orderKey) async {
    final db = await instance.database;
    final result = await db.rawQuery('SELECT * FROM $tableOrder WHERE soft_delete = ? AND order_key = ?', ['', orderKey]);
    return result.map((json) => Order.fromJson(json)).toList();
  }

/*
  read specific order
*/
  Future<List<OrderPaymentSplit>> readSpecificOrderSplitByOrderKey(String orderKey) async {
    final db = await instance.database;
    final result = await db.rawQuery('SELECT a.*, b.name AS payment_name, b.payment_type_id AS payment_type_id FROM $tableOrderPaymentSplit as a '
        'JOIN $tablePaymentLinkCompany AS b ON a.payment_link_company_id = b.payment_link_company_id WHERE a.soft_delete = ? AND '
        'a.order_key = ?', ['', orderKey]);
    return result.map((json) => OrderPaymentSplit.fromJson(json)).toList();
  }

/*
  read specific paid order
*/
  Future<List<Order>> readSpecificPaidOrder(String order_sqlite_id) async {
    final db = await instance.database;
    final result = await db.rawQuery(
        'SELECT a.*, b.name, b.payment_type_id FROM $tableOrder AS a '
        'LEFT JOIN $tablePaymentLinkCompany AS b ON a.payment_link_company_id = b.payment_link_company_id '
        'WHERE a.payment_status = ? AND a.soft_delete = ? AND a.order_sqlite_id = ?',
        [1, '', order_sqlite_id]);
    return result.map((json) => Order.fromJson(json)).toList();
  }

/*
  read specific refunded order
*/
  Future<List<Order>> readSpecificRefundedOrder(String order_sqlite_id) async {
    final db = await instance.database;
    final result = await db.rawQuery(
        'SELECT a.*, b.name, b.payment_type_id FROM $tableOrder AS a '
            'LEFT JOIN $tablePaymentLinkCompany AS b ON a.payment_link_company_id = b.payment_link_company_id '
            'WHERE a.payment_status = ? AND a.soft_delete = ? AND a.order_sqlite_id = ?',
        [2, '', order_sqlite_id]);
    return result.map((json) => Order.fromJson(json)).toList();
  }

/*
  read specific paid order
*/
  Future<List<Order>> readSpecificPaidSplitPaymentOrder(String order_sqlite_id) async {
    final db = await instance.database;
    final result = await db.rawQuery(
        'SELECT a.*, c.name, c.payment_type_id, b.amount AS amountSplit FROM $tableOrder AS a '
            'JOIN $tableOrderPaymentSplit AS b ON a.order_key = b.order_key '
            'JOIN $tablePaymentLinkCompany AS c ON b.payment_link_company_id = c.payment_link_company_id '
            'WHERE a.payment_status = ? AND a.soft_delete = ? AND a.order_sqlite_id = ? ORDER BY b.created_at DESC',
        [1, '', order_sqlite_id]);
    return result.map((json) => Order.fromJson(json)).toList();
  }

/*
  read all paid order
*/
  Future<List<Order>> readAllPaidOrder() async {
    final db = await instance.database;
    final result = await db.rawQuery(
        'SELECT a.*, b.payment_type_id FROM $tableOrder AS a '
        'LEFT JOIN $tablePaymentLinkCompany AS b ON a.payment_link_company_id = b.payment_link_company_id '
        'WHERE a.payment_status = ? AND a.payment_split != ? AND a.settlement_key = ? AND a.soft_delete = ? ORDER BY a.created_at DESC',
        [1, 2, '', '']);
    return result.map((json) => Order.fromJson(json)).toList();
  }

/*
  read order cache by orderID
*/
  Future<List<OrderCache>> readSpecificOrderCacheByOrderID(String order_sqlite_id) async {
    final db = await instance.database;
    final result = await db.rawQuery('SELECT * FROM $tableOrderCache WHERE order_sqlite_id = ?', [order_sqlite_id]);
    return result.map((json) => OrderCache.fromJson(json)).toList();
  }

/*
  read order detail by paid order cache
*/
  Future<List<OrderDetail>> readSpecificOrderDetailByOrderCacheId(String order_cache_sqlite_id) async {
    final db = await instance.database;
    final result = await db.rawQuery('SELECT * FROM $tableOrderDetail WHERE soft_delete = ? AND status = ? AND order_cache_sqlite_id = ?', ['', 0, order_cache_sqlite_id]);

    return result.map((json) => OrderDetail.fromJson(json)).toList();
  }

/*
  read all deleted table use detail
*/
  Future<List<TableUseDetail>> readDeleteOnlyTableUseDetail(String table_use_sqlite_id) async {
    final db = await instance.database;
    final result = await db.rawQuery('SELECT * FROM $tableTableUseDetail WHERE soft_delete = ? AND status = ? AND table_use_sqlite_id = ?', ['', 1, table_use_sqlite_id]);

    return result.map((json) => TableUseDetail.fromJson(json)).toList();
  }

/*
  read specific order tax detail
*/
  Future<List<OrderTaxDetail>> readSpecificOrderTaxDetail(String order_sqlite_id) async {
    final db = await instance.database;
    final result = await db.rawQuery('SELECT * FROM $tableOrderTaxDetail WHERE soft_delete = ? AND order_sqlite_id = ?', ['', order_sqlite_id]);

    return result.map((json) => OrderTaxDetail.fromJson(json)).toList();
  }

/*
  read specific order tax detail by local id
*/
  Future<OrderTaxDetail> readSpecificOrderTaxDetailByLocalId(int order_tax_detail_sqlite_id) async {
    final db = await instance.database;
    final result = await db.rawQuery('SELECT * FROM $tableOrderTaxDetail WHERE soft_delete = ? AND order_tax_detail_sqlite_id = ?', ['', order_tax_detail_sqlite_id]);

    return OrderTaxDetail.fromJson(result.first);
  }

/*
  read specific order promotion detail
*/
  Future<List<OrderPromotionDetail>> readSpecificOrderPromotionDetail(String order_sqlite_id) async {
    final db = await instance.database;
    final result = await db.rawQuery('SELECT * FROM $tableOrderPromotionDetail WHERE soft_delete = ? AND order_sqlite_id = ?', ['', order_sqlite_id]);

    return result.map((json) => OrderPromotionDetail.fromJson(json)).toList();
  }

/*
  read specific order promotion detail by order key
*/
  Future<List<OrderPromotionDetail>> readSpecificOrderPromotionDetailByOrderKey(String order_key) async {
    final db = await instance.database;
    final result = await db.rawQuery('SELECT * FROM $tableOrderPromotionDetail WHERE soft_delete = ? AND order_key = ?', ['', order_key]);

    return result.map((json) => OrderPromotionDetail.fromJson(json)).toList();
  }

/*
  read specific order promotion detail by local id
*/
  Future<OrderPromotionDetail> readSpecificOrderPromotionDetailByLocalId(int order_promotion_detail_sqlite_id) async {
    final db = await instance.database;
    final result =
        await db.rawQuery('SELECT * FROM $tableOrderPromotionDetail WHERE soft_delete = ? AND order_promotion_detail_sqlite_id = ?', ['', order_promotion_detail_sqlite_id]);

    return OrderPromotionDetail.fromJson(result.first);
  }

/*
  read latest subscription
*/
  Future<Subscription?> readAllSubscription() async {
    final db = await instance.database;
    // final result = await db.rawQuery('SELECT * FROM $tableSubscription');
    final result = await db.rawQuery('SELECT * FROM $tableSubscription WHERE soft_delete = ? ORDER BY end_date DESC ', ['']);
    if (result.isNotEmpty) {
      return Subscription.fromJson(result.first);
    } else {
      return null;
    }
  }

/*
  --------------------App setting part--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
*/

/*
  read latest app setting
*/
  Future<List<AppSetting>> readAllAppSetting() async {
    final db = await instance.database;
    final result = await db.rawQuery('SELECT * FROM $tableAppSetting');
    return result.map((json) => AppSetting.fromJson(json)).toList();
  }

/*
  read latest app setting
*/
  Future<AppSetting?> readAppSetting() async {
    final db = await instance.database;
    final result = await db.rawQuery('SELECT * FROM $tableAppSetting');
    if (result.isNotEmpty) {
      return AppSetting.fromJson(result.first);
    } else {
      return null;
    }
  }

  /*
  get app setting sync status
*/
  Future<AppSetting?> readLocalAppSetting(String branch_id) async {
    final db = await instance.database;
    final result = await db.rawQuery('SELECT * FROM $tableAppSetting WHERE branch_id = ?', [branch_id]);
    if (result.isNotEmpty) {
      return AppSetting.fromJson(result.first);
    } else {
      return null;
    }
  }

  /*
  check setting avaibility
*/
  Future<bool?> isLocalAppSettingExisted() async {
    final db = await instance.database;
    final result = await db.rawQuery('SELECT * FROM $tableAppSetting');
    if (result.isNotEmpty) {
      return true;
    } else {
      return false;
    }
  }

/*
  read specific app setting
*/
  Future<AppSetting?> readSpecificAppSetting(int id) async {
    final db = await instance.database;
    final result = await db.rawQuery('SELECT * FROM $tableAppSetting WHERE app_setting_sqlite_id = ?', [id]);
    if (result.isNotEmpty) {
      return AppSetting.fromJson(result.first);
    } else {
      return null;
    }
  }



/*
  --------------------Report part--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
*/

/*
  read all order group by user wiht OB
*/
  Future<List<Order>> readStaffSalesWithOB(String date1, String date2) async {
    final db = await instance.database;
    final result = await db.rawQuery(
        'SELECT *, SUM (final_amount) AS gross_sales, COUNT(order_sqlite_id) AS item_sum FROM $tableOrder '
            'WHERE soft_delete = ? AND settlement_key IN (SELECT settlement_key FROM $tableCashRecord WHERE remark = ? AND '
            'soft_delete = ? AND SUBSTR(created_at, 1, 10) >= ? AND SUBSTR(created_at, 1, 10) < ?) GROUP BY close_by',
        ['', 'Opening Balance', '', date1, date2]);
    return result.map((json) => Order.fromJson(json)).toList();
  }

/*
  read all order group by user
*/
  Future<List<Order>> readStaffSales(String date1, String date2) async {
    final db = await instance.database;
    final result = await db.rawQuery(
        'SELECT *, SUM (final_amount) AS gross_sales, COUNT(order_sqlite_id) AS item_sum FROM $tableOrder '
            'WHERE soft_delete = ? AND SUBSTR(created_at, 1, 10) >= ? AND SUBSTR(created_at, 1, 10) < ? GROUP BY close_by',
        ['', date1, date2]);
    return result.map((json) => Order.fromJson(json)).toList();
  }

/*
  read all cash record
*/
  Future<List<CashRecord>> readAllTodayCashRecord(String date1, String date2) async {
    final db = await instance.database;
    final result = await db.rawQuery(
        'SELECT a.created_at, a.type, a.user_id, a.amount, a.remark, b.name AS name FROM $tableCashRecord AS a JOIN $tableUser AS b on a.user_id = b.user_id '
            'WHERE a.soft_delete = ? AND b.soft_delete = ? AND SUBSTR(a.created_at, 1, 10) >= ? AND SUBSTR(a.created_at, 1, 10) < ?',
        ['', '', date1, date2]);
    return result.map((json) => CashRecord.fromJson(json)).toList();
  }

/*
  read all cash record with opening balance
*/
  Future<List<CashRecord>> readAllTodayCashRecordWithOB(String date1, String date2) async {
    final db = await instance.database;
    final result = await db.rawQuery(
        'SELECT a.created_at, a.type, a.user_id, a.amount, a.remark, b.name AS name FROM $tableCashRecord AS a JOIN $tableUser AS b on a.user_id = b.user_id '
            'WHERE a.soft_delete = ? AND b.soft_delete = ? AND a.settlement_key IN (SELECT settlement_key FROM $tableCashRecord WHERE remark = ? AND '
            'soft_delete = ? AND soft_delete = ? AND SUBSTR(created_at, 1, 10) >= ? AND SUBSTR(created_at, 1, 10) < ?)',
        ['', '', 'Opening Balance', '', '', date1, date2]);
    return result.map((json) => CashRecord.fromJson(json)).toList();
  }

/*
  read all settlement link payment
*/
  Future<List<SettlementLinkPayment>> readSpecificSettlementLinkPaymentBySettlementKey(String settlement_key, String payment_link_company_id) async {
    //print('settlement time: ${settlement_key}');
    final db = await instance.database;
    final result = await db.rawQuery(
        'SELECT a.soft_delete, a.updated_at, a.created_at, a.sync_status, a.status, a.payment_link_company_id, a.total_sales, a.total_bill, a.settlement_key, a.settlement_sqlite_id, a.branch_id, '
        'a.company_id, a.settlement_link_payment_key, a.settlement_link_payment_id, a.settlement_link_payment_sqlite_id,  '
        'SUM(a.total_sales) AS all_payment_sales FROM $tableSettlementLinkPayment AS a JOIN $tablePaymentLinkCompany AS b ON a.payment_link_company_id = b.payment_link_company_id  '
        'WHERE a.soft_delete = ? AND a.status = ? AND a.settlement_key = ? AND a.payment_link_company_id = ? ',
        ['', 0, settlement_key, payment_link_company_id]);
    return result.map((json) => SettlementLinkPayment.fromJson(json)).toList();
  }

/*
  read all settlement link payment
*/
  Future<List<SettlementLinkPayment>> readSpecificSettlementLinkPayment(String settlement_date, String payment_link_company_id) async {
    //print('settlement time: ${settlement_key}');
    final db = await instance.database;
    final result = await db.rawQuery(
        'SELECT a.soft_delete, a.updated_at, a.created_at, a.sync_status, a.status, a.payment_link_company_id, a.total_sales, a.total_bill, a.settlement_key, a.settlement_sqlite_id, a.branch_id, '
        'a.company_id, a.settlement_link_payment_key, a.settlement_link_payment_id, a.settlement_link_payment_sqlite_id,  '
        'SUM(a.total_sales) AS all_payment_sales FROM $tableSettlementLinkPayment AS a JOIN $tablePaymentLinkCompany AS b ON a.payment_link_company_id = b.payment_link_company_id  '
        'WHERE a.soft_delete = ? AND a.status = ? AND SUBSTR(a.created_at, 1, 10) = SUBSTR(?, 1, 10) AND a.payment_link_company_id = ? GROUP BY a.payment_link_company_id ORDER BY b.name ',
        ['', 0, settlement_date, payment_link_company_id]);
    return result.map((json) => SettlementLinkPayment.fromJson(json)).toList();
  }

/*
  read all settlement
*/
  Future<List<Settlement>> readAllSettlement(String date1, String date2) async {
    final db = await instance.database;
    final result = await db.rawQuery(
        'SELECT *, SUM(total_bill) AS all_bill, SUM(total_sales) AS all_sales, SUM(total_refund_bill) AS all_refund_bill, '
        'SUM(total_refund_amount) AS all_refund_amount, SUM(total_discount) AS all_discount, '
        'SUM(total_tax) AS all_tax_amount, SUM(total_cancellation) AS all_cancellation '
        'FROM $tableSettlement WHERE soft_delete = ? AND status = ? AND SUBSTR(created_at, 1, 10) >= ? AND SUBSTR(created_at, 1, 10) < ? GROUP BY SUBSTR(created_at, 1, 10) ORDER BY SUBSTR(created_at, 1, 10) DESC ',
        ['', 0, date1, date2]);
    return result.map((json) => Settlement.fromJson(json)).toList();
  }

/*
  read all settlement with opening balance
*/
  Future<List<Settlement>> readAllSettlementWithOB(String date1, String date2) async {
    final db = await instance.database;
    final result = await db.rawQuery(
        'SELECT a.*, SUM(total_bill) AS all_bill, SUM(total_sales) AS all_sales, SUM(total_refund_bill) AS all_refund_bill, '
            'SUM(total_refund_amount) AS all_refund_amount, SUM(total_discount) AS all_discount, '
            'SUM(total_tax) AS all_tax_amount, SUM(total_cancellation) AS all_cancellation '
            'FROM $tableSettlement AS a JOIN $tableCashRecord AS b ON b.settlement_key = a.settlement_key AND b.remark = ?'
            'WHERE a.soft_delete = ? AND a.status = ? AND SUBSTR(b.created_at, 1, 10) >= ? AND SUBSTR(b.created_at, 1, 10) < ? GROUP BY SUBSTR(b.created_at, 1, 10) ORDER BY SUBSTR(b.created_at, 1, 10) DESC ',
        ['Opening Balance', '', 0, date1, date2]);
    return result.map((json) => Settlement.fromJson(json)).toList();
  }

/*
  sum all tax by tax id
*/
  Future<List<OrderTaxDetail>> sumAllOrderTaxDetail(int order_sqlite_id, String tax_id, String date1, String date2) async {
    final db = await instance.database;
    final result = await db.rawQuery(
        'SELECT SUM(tax_amount) AS total_tax_amount FROM $tableOrderTaxDetail '
        'WHERE soft_delete = ? AND tax_id = ? AND order_sqlite_id = ? AND SUBSTR(created_at, 1, 10) >= ? AND SUBSTR(created_at, 1, 10) < ? '
        'GROUP BY tax_id ORDER BY tax_id ',
        ['', tax_id, order_sqlite_id, date1, date2]);
    return result.map((json) => OrderTaxDetail.fromJson(json)).toList();
  }

/*
  read all order tax detail by order id
*/
  Future<List<OrderTaxDetail>> readAllRefundedOrderTaxDetail(int order_sqlite_id, String date1, String date2) async {
    final db = await instance.database;
    final result = await db.rawQuery(
        'SELECT * FROM $tableOrderTaxDetail '
        'WHERE soft_delete = ? AND order_sqlite_id = ? AND SUBSTR(created_at, 1, 10) >= ? AND SUBSTR(created_at, 1, 10) < ? '
        'GROUP BY tax_id ORDER BY tax_id ',
        ['', order_sqlite_id, date1, date2]);
    return result.map((json) => OrderTaxDetail.fromJson(json)).toList();
  }

/*
  read all refunded order
*/
  Future<List<Order>> readAllRefundedOrder(String date1, String date2) async {
    final db = await instance.database;
    final result = await db.rawQuery(
        'SELECT a.*, b.bill_id AS bill_no, b.refund_by AS refund_name, b.created_at AS refund_at, '
        '(SELECT COALESCE(SUM(tax_amount), 0.0) FROM $tableOrderTaxDetail WHERE order_sqlite_id = a.order_sqlite_id) AS total_tax_amount, '
        '(SELECT SUM(promotion_amount) FROM $tableOrderPromotionDetail WHERE order_sqlite_id = a.order_sqlite_id) AS promo_amount '
        'FROM $tableOrder AS a JOIN $tableRefund AS b ON a.refund_sqlite_id = b.refund_sqlite_id '
        'WHERE a.soft_delete = ? AND b.soft_delete = ? AND a.payment_status = ? '
        'AND SUBSTR(a.created_at, 1, 10) >= ? AND SUBSTR(a.created_at, 1, 10) < ? ',
        ['', '', 2, date1, date2]);
    return result.map((json) => Order.fromJson(json)).toList();
  }

/*
  read all refunded order with opening balance
*/
  Future<List<Order>> readAllRefundedOrderWithOB(String date1, String date2) async {
    final db = await instance.database;
    final result = await db.rawQuery(
        'SELECT a.*, b.bill_id AS bill_no, b.refund_by AS refund_name, b.created_at AS refund_at, '
            '(SELECT COALESCE(SUM(tax_amount), 0.0) FROM $tableOrderTaxDetail WHERE order_sqlite_id = a.order_sqlite_id) AS total_tax_amount, '
            '(SELECT SUM(promotion_amount) FROM $tableOrderPromotionDetail WHERE order_sqlite_id = a.order_sqlite_id) AS promo_amount '
            'FROM $tableOrder AS a JOIN $tableRefund AS b ON a.refund_sqlite_id = b.refund_sqlite_id '
            'JOIN $tableCashRecord AS c on a.settlement_key = c.settlement_key AND c.remark = ?'
            'WHERE a.soft_delete = ? AND b.soft_delete = ? AND a.payment_status = ? '
            'AND SUBSTR(c.created_at, 1, 10) >= ? AND SUBSTR(c.created_at, 1, 10) < ? ',
        ['Opening Balance', '', '', 2, date1, date2]);
    return result.map((json) => Order.fromJson(json)).toList();
  }

/*
  read all cancelled modifier
*/
  Future<List<OrderModifierDetail>> readAllCancelledModifier(String mod_group_id, String date1, String date2) async {
    final db = await instance.database;
    final result = await db.rawQuery(
        'SELECT a.*, SUM(c.quantity) AS item_sum, SUM(c.quantity * a.mod_price + 0.0) AS net_sales '
        'FROM $tableOrderModifierDetail AS a JOIN $tableOrderDetail AS b ON a.order_detail_sqlite_id = b.order_detail_sqlite_id '
        'JOIN $tableOrderDetailCancel AS c ON b.order_detail_sqlite_id = c.order_detail_sqlite_id  '
        'WHERE a.soft_delete = ? AND b.soft_delete = ? AND c.soft_delete = ? AND a.mod_group_id = ? '
        'AND SUBSTR(c.created_at, 1, 10) >= ? AND SUBSTR(c.created_at, 1, 10) < ? GROUP BY a.mod_name ',
        ['', '', '', mod_group_id, date1, date2]);
    return result.map((json) => OrderModifierDetail.fromJson(json)).toList();
  }

/*
  read all cancelled modifier with opening balance
*/
  Future<List<OrderModifierDetail>> readAllCancelledModifierWithOB(String mod_group_id, String date1, String date2) async {
    final db = await instance.database;
    final result = await db.rawQuery(
        'SELECT a.*, SUM(c.quantity) AS item_sum, SUM(c.quantity * a.mod_price + 0.0) AS net_sales '
            'FROM $tableOrderModifierDetail AS a JOIN $tableOrderDetail AS b ON a.order_detail_sqlite_id = b.order_detail_sqlite_id '
            'JOIN $tableOrderDetailCancel AS c ON b.order_detail_sqlite_id = c.order_detail_sqlite_id JOIN $tableCashRecord AS d on c.settlement_key = d.settlement_key AND d.remark = ?'
            'WHERE a.soft_delete = ? AND b.soft_delete = ? AND c.soft_delete = ? AND a.mod_group_id = ? '
            'AND SUBSTR(d.created_at, 1, 10) >= ? AND SUBSTR(d.created_at, 1, 10) < ? GROUP BY a.mod_name ',
        ['Opening Balance', '', '', '', mod_group_id, date1, date2]);
    return result.map((json) => OrderModifierDetail.fromJson(json)).toList();
  }

/*
  read all cancelled modifier group
*/
  Future<List<ModifierGroup>> readAllCancelledModifierGroup(String date1, String date2) async {
    final db = await instance.database;
    final result = await db.rawQuery(
        'SELECT d.created_at, b.*, SUM(d.quantity * a.mod_price + 0.0) AS net_sales, SUM(d.quantity) AS item_sum '
        'FROM $tableOrderModifierDetail AS a JOIN $tableModifierGroup AS b ON a.mod_group_id = b.mod_group_id '
        'JOIN $tableOrderDetail AS c ON a.order_detail_sqlite_id = c.order_detail_sqlite_id '
        'JOIN $tableOrderDetailCancel AS d ON c.order_detail_sqlite_id = d.order_detail_sqlite_id '
        'WHERE a.soft_delete = ? AND c.soft_delete = ? AND d.soft_delete = ? '
        'AND SUBSTR(d.created_at, 1, 10) >= ? AND SUBSTR(d.created_at, 1, 10) < ? GROUP BY b.mod_group_id ',
        ['', '', '', date1, date2]);
    return result.map((json) => ModifierGroup.fromJson(json)).toList();
  }

/*
  read all cancelled modifier group with opening balance
*/
  Future<List<ModifierGroup>> readAllCancelledModifierGroupWithOB(String date1, String date2) async {
    final db = await instance.database;
    final result = await db.rawQuery(
        'SELECT d.created_at, b.*, SUM(d.quantity * a.mod_price + 0.0) AS net_sales, SUM(d.quantity) AS item_sum '
            'FROM $tableOrderModifierDetail AS a JOIN $tableModifierGroup AS b ON a.mod_group_id = b.mod_group_id '
            'JOIN $tableOrderDetail AS c ON a.order_detail_sqlite_id = c.order_detail_sqlite_id '
            'JOIN $tableOrderDetailCancel AS d ON c.order_detail_sqlite_id = d.order_detail_sqlite_id JOIN $tableCashRecord AS e on d.settlement_key = e.settlement_key AND e.remark = ?'
            'WHERE a.soft_delete = ? AND c.soft_delete = ? AND d.soft_delete = ? '
            'AND SUBSTR(e.created_at, 1, 10) >= ? AND SUBSTR(e.created_at, 1, 10) < ? GROUP BY b.mod_group_id ',
        ['Opening Balance', '', '', '', date1, date2]);
    return result.map((json) => ModifierGroup.fromJson(json)).toList();
  }

/*
  read all cancelled order detail with category
*/
  Future<List<OrderDetail>> readAllCancelledOrderDetailWithCategory(int category_sqlite_id, String date1, String date2) async {
    final db = await instance.database;
    final result = await db.rawQuery(
        'SELECT a.created_at, a.product_name, a.product_variant_name, b.cancel_by, SUM(b.quantity * a.price + 0.0) AS gross_price, '
        'SUM(b.quantity * a.original_price + 0.0) AS net_sales, '
        'SUM(b.quantity) AS item_sum '
        'FROM $tableOrderDetail AS a JOIN $tableOrderDetailCancel AS b ON a.order_detail_sqlite_id = b.order_detail_sqlite_id '
        'WHERE a.soft_delete = ? AND b.soft_delete = ? AND a.category_sqlite_id = ? '
        'AND SUBSTR(b.created_at, 1, 10) >= ? AND SUBSTR(b.created_at, 1, 10) < ? '
        'GROUP BY a.product_name, a.product_variant_name ORDER BY a.product_name',
        ['', '', category_sqlite_id, date1, date2]);
    return result.map((json) => OrderDetail.fromJson(json)).toList();
  }

/*
  read all cancelled order detail with category
*/
  Future<List<OrderDetail>> readAllCancelledOrderDetailWithCategory2(String category_name, String date1, String date2) async {
    final db = await instance.database;
    final result = await db.rawQuery(
      //CASE WHEN b.unit != ? OR b.unit != ? THEN 1 ELSE b.quantity END
        'SELECT a.created_at, a.product_name, a.product_variant_name, a.unit, b.cancel_by, SUM(b.quantity * a.price + 0.0) AS gross_price, '
            'SUM(b.quantity * a.original_price + 0.0) AS net_sales, '
            'SUM(CASE WHEN a.unit != ? AND a.unit != ? THEN a.per_quantity_unit * b.quantity ELSE b.quantity END) AS item_sum, '
            'SUM(CASE WHEN a.unit != ? THEN 1 ELSE 0 END) AS item_qty '
            'FROM $tableOrderDetail AS a JOIN $tableOrderDetailCancel AS b ON a.order_detail_sqlite_id = b.order_detail_sqlite_id '
            'WHERE a.soft_delete = ? AND b.soft_delete = ? AND a.category_name = ? '
            'AND SUBSTR(b.created_at, 1, 10) >= ? AND SUBSTR(b.created_at, 1, 10) < ? '
            'GROUP BY a.product_name, a.product_variant_name ORDER BY a.product_name',
        ['each', 'each_c', 'each', '', '', category_name, date1, date2]);
    return result.map((json) => OrderDetail.fromJson(json)).toList();
  }

/*
  read all cancelled order detail with category with opening balance
*/
  Future<List<OrderDetail>> readAllCancelledOrderDetailWithCategory2WithOB(String category_name, String date1, String date2) async {
    final db = await instance.database;
    final result = await db.rawQuery(
      //CASE WHEN b.unit != ? OR b.unit != ? THEN 1 ELSE b.quantity END
        'SELECT a.created_at, a.product_name, a.product_variant_name, a.unit, b.cancel_by, SUM(b.quantity * a.price + 0.0) AS gross_price, '
            'SUM(b.quantity * a.original_price + 0.0) AS net_sales, '
            'SUM(CASE WHEN a.unit != ? AND a.unit != ? THEN a.per_quantity_unit * b.quantity ELSE b.quantity END) AS item_sum, '
            'SUM(CASE WHEN a.unit != ? THEN 1 ELSE 0 END) AS item_qty '
            'FROM $tableOrderDetail AS a JOIN $tableOrderDetailCancel AS b ON a.order_detail_sqlite_id = b.order_detail_sqlite_id '
            'JOIN $tableCashRecord AS c on b.settlement_key = c.settlement_key AND c.remark = ? '
            'WHERE a.soft_delete = ? AND b.soft_delete = ? AND a.category_name = ? '
            'AND SUBSTR(c.created_at, 1, 10) >= ? AND SUBSTR(c.created_at, 1, 10) < ? '
            'GROUP BY a.product_name, a.product_variant_name ORDER BY a.product_name',
        ['each', 'each_c', 'each', 'Opening Balance', '', '', category_name, date1, date2]);
    return result.map((json) => OrderDetail.fromJson(json)).toList();
  }

/*
  read all cancelled category with order detail
*/
  Future<List<Categories>> readAllCancelledCategoryWithOrderDetail(String date1, String date2) async {
    final db = await instance.database;
    final result = await db.rawQuery(
        'SELECT a.*, SUM(b.quantity * a.original_price + 0.0) AS category_sales, SUM(b.quantity * a.price + 0.0) AS category_gross_sales,'
        'IFNULL( (SELECT category_sqlite_id FROM $tableCategories WHERE category_sqlite_id = a.category_sqlite_id), 0) AS category_sqlite_id, '
        'IFNULL( (SELECT name FROM $tableCategories WHERE category_sqlite_id = a.category_sqlite_id), "Other") AS name, '
        'SUM(b.quantity) AS item_sum '
        'FROM $tableOrderDetail AS a JOIN $tableOrderDetailCancel AS b ON a.order_detail_sqlite_id = b.order_detail_sqlite_id '
        'WHERE a.soft_delete = ? AND b.soft_delete = ? '
        'AND SUBSTR(b.created_at, 1, 10) >= ? AND SUBSTR(b.created_at, 1, 10) < ? GROUP BY a.category_sqlite_id '
        'ORDER BY a.category_sqlite_id DESC',
        ['', '', date1, date2]);
    return result.map((json) => Categories.fromJson(json)).toList();
  }

/*
  read all cancelled category with order detail
*/
  Future<List<OrderDetail>> readAllCancelledCategoryWithOrderDetail2(String date1, String date2) async {
    final db = await instance.database;
    final result = await db.rawQuery(
        'SELECT a.*, SUM(b.quantity * a.original_price + 0.0) AS category_net_sales, SUM(b.quantity * a.price + 0.0) AS category_gross_sales,'
        'SUM(CASE WHEN a.unit != ? OR a.unit != ? THEN 1 ELSE b.quantity END) AS category_item_sum '
        'FROM $tableOrderDetail AS a JOIN $tableOrderDetailCancel AS b ON a.order_detail_sqlite_id = b.order_detail_sqlite_id '
        'WHERE a.soft_delete = ? AND b.soft_delete = ? '
        'AND SUBSTR(b.created_at, 1, 10) >= ? AND SUBSTR(b.created_at, 1, 10) < ? GROUP BY a.category_name '
        'ORDER BY a.category_name DESC',
        ['each', '', '', '', date1, date2]);
    return result.map((json) => OrderDetail.fromJson(json)).toList();
  }

/*
  read all cancelled category with order detail with opening balance
*/
  Future<List<OrderDetail>> readAllCancelledCategoryWithOrderDetail2WithOB(String date1, String date2) async {
    final db = await instance.database;
    final result = await db.rawQuery(
        'SELECT a.*, SUM(b.quantity * a.original_price + 0.0) AS category_net_sales, SUM(b.quantity * a.price + 0.0) AS category_gross_sales,'
            'SUM(CASE WHEN a.unit != ? OR a.unit != ? THEN 1 ELSE b.quantity END) AS category_item_sum '
            'FROM $tableOrderDetail AS a JOIN $tableOrderDetailCancel AS b ON a.order_detail_sqlite_id = b.order_detail_sqlite_id '
            'JOIN $tableCashRecord AS c on b.settlement_key = c.settlement_key AND c.remark = ? '
            'WHERE a.soft_delete = ? AND b.soft_delete = ? '
            'AND SUBSTR(c.created_at, 1, 10) >= ? AND SUBSTR(c.created_at, 1, 10) < ? GROUP BY a.category_name '
            'ORDER BY a.category_name DESC',
        ['each', '', 'Opening Balance', '', '', date1, date2]);
    return result.map((json) => OrderDetail.fromJson(json)).toList();
  }

/*
  read all edited order
*/
  Future<List<OrderDetail>> readAllEditedOrderDetail(String date1, String date2) async {
    final db = await instance.database;
    final result = await db.rawQuery(
        'SELECT a.*, c.order_number, c.branch_id, c.created_at as order_created_at FROM $tableOrderDetail AS a JOIN $tableOrderCache '
        'AS b ON a.order_cache_key = b.order_cache_key JOIN $tableOrder AS c ON b.order_key = c.order_key '
        'WHERE a.soft_delete = ? AND a.edited_by_user_id != ? AND a.status = ? AND SUBSTR(a.updated_at, 1, 10) >= ? AND SUBSTR(a.updated_at, 1, 10) < ? AND b.order_key != ? ',
        ['', '', 0, date1, date2, '']);
    return result.map((json) => OrderDetail.fromJson(json)).toList();
  }

/*
  read all edited order with opening balance
*/
  Future<List<OrderDetail>> readAllEditedOrderDetailWithOB(String date1, String date2) async {
    final db = await instance.database;
    final result = await db.rawQuery(
        'SELECT a.*, c.order_number, c.branch_id, c.created_at as order_created_at FROM $tableOrderDetail AS a JOIN $tableOrderCache '
            'AS b ON a.order_cache_key = b.order_cache_key JOIN $tableOrder AS c ON b.order_key = c.order_key JOIN $tableCashRecord AS d on c.settlement_key = d.settlement_key AND d.remark = ?'
            'WHERE a.soft_delete = ? AND a.edited_by_user_id != ? AND a.status = ? AND SUBSTR(d.created_at, 1, 10) >= ? AND SUBSTR(d.created_at, 1, 10) < ? AND b.order_key != ? ',
        ['Opening Balance', '', '', 0, date1, date2, '']);
    return result.map((json) => OrderDetail.fromJson(json)).toList();
  }

/*
  read all paid payment
*/
  Future<List<Order>> readAllPaidPaymentType(String date1, String date2) async {
    final db = await instance.database;
    final result = await db.rawQuery(
        'SELECT a.*, b.name AS name, COUNT(order_sqlite_id) AS item_sum, SUM(final_amount + 0.0) AS gross_sales, SUM(subtotal + 0.0) AS net_sales '
        'FROM $tableOrder AS a JOIN $tablePaymentLinkCompany AS b ON a.payment_link_company_id = b.payment_link_company_id '
        'WHERE a.soft_delete = ? AND a.payment_status = ? '
        'AND SUBSTR(a.created_at, 1, 10) >= ? AND SUBSTR(a.created_at, 1, 10) < ? GROUP BY a.payment_link_company_id ',
        ['', 1, date1, date2]);
    return result.map((json) => Order.fromJson(json)).toList();
  }

/*
  read all paid payment with opening balance
*/
  Future<List<Order>> readAllPaidPaymentTypeWithOB(String date1, String date2) async {
    final db = await instance.database;
    final result = await db.rawQuery(
        'SELECT a.*, b.name AS name, COUNT(order_sqlite_id) AS item_sum, SUM(final_amount + 0.0) AS gross_sales, SUM(subtotal + 0.0) AS net_sales '
            'FROM $tableOrder AS a JOIN $tablePaymentLinkCompany AS b ON a.payment_link_company_id = b.payment_link_company_id '
            'JOIN $tableCashRecord AS c on a.settlement_key = c.settlement_key AND c.remark = ? '
            'WHERE a.soft_delete = ? AND a.payment_status = ? '
            'AND SUBSTR(c.created_at, 1, 10) >= ? AND SUBSTR(c.created_at, 1, 10) < ? GROUP BY a.payment_link_company_id ',
        ['Opening Balance', '', 1, date1, date2]);
    return result.map((json) => Order.fromJson(json)).toList();
  }

/*
  read all paid Dining
*/
  Future<List<Order>> readAllPaidDining(String date1, String date2) async {
    final db = await instance.database;
    final result = await db.rawQuery(
        'SELECT a.*, COUNT(order_sqlite_id) AS item_sum, SUM(final_amount + 0.0) AS gross_sales, SUM(subtotal + 0.0) AS net_sales '
        'FROM $tableOrder AS a WHERE a.soft_delete = ? AND a.payment_status = ? '
        'AND SUBSTR(a.created_at, 1, 10) >= ? AND SUBSTR(a.created_at, 1, 10) < ? GROUP BY a.dining_id',
        ['', 1, date1, date2]);
    return result.map((json) => Order.fromJson(json)).toList();
  }

/*
  read all paid Dining with opening balance
*/
  Future<List<Order>> readAllPaidDiningWithOB(String date1, String date2) async {
    final db = await instance.database;
    final result = await db.rawQuery(
        'SELECT a.*, COUNT(order_sqlite_id) AS item_sum, SUM(final_amount + 0.0) AS gross_sales, SUM(subtotal + 0.0) AS net_sales '
            'FROM $tableOrder AS a  JOIN $tableCashRecord AS b on a.settlement_key = b.settlement_key AND b.remark = ? WHERE a.soft_delete = ? AND a.payment_status = ? '
            'AND SUBSTR(b.created_at, 1, 10) >= ? AND SUBSTR(b.created_at, 1, 10) < ? GROUP BY a.dining_id',
        ['Opening Balance', '', 1, date1, date2]);
    return result.map((json) => Order.fromJson(json)).toList();
  }

/*
  read all attendance
*/
  Future<List<Attendance>> readAllAttendance(String userId, String date1, String date2) async {
    final db = await instance.database;
    final result = await db.rawQuery('SELECT * FROM $tableAttendance WHERE user_id = ? AND soft_delete = ? AND SUBSTR(clock_in_at, 1, 10) >= ? AND '
        'SUBSTR(clock_in_at, 1, 10) < ? ORDER BY clock_in_at ASC', [userId, '', date1, date2]);
    return result.map((json) => Attendance.fromJson(json)).toList();
  }

/*
  read all attendance user group
*/
  Future<List<Attendance>> readAllAttendanceGroup(String date1, String date2) async {
    final db = await instance.database;
    final result = await db.rawQuery('SELECT a.*, b.name, SUM(a.duration) AS totalDuration FROM $tableAttendance AS a JOIN $tableUser AS b ON a.user_id = b.user_id WHERE a.soft_delete = ? AND SUBSTR(a.clock_in_at, 1, 10) >= ? AND '
        'SUBSTR(a.clock_in_at, 1, 10) < ? GROUP BY a.user_id', ['', date1, date2]);
    return result.map((json) => Attendance.fromJson(json)).toList();
  }

/*
  read all paid modifier
*/
  Future<List<OrderModifierDetail>> readAllPaidModifier(String mod_group_id, String date1, String date2) async {
    final db = await instance.database;
    final result = await db.rawQuery(
        'SELECT a.*, COUNT(a.order_modifier_detail_sqlite_id) AS item_sum, SUM(a.mod_price + 0.0) AS net_sales '
        'FROM $tableOrderModifierDetail AS a JOIN $tableOrderDetail AS b ON a.order_detail_sqlite_id = b.order_detail_sqlite_id '
        'JOIN $tableOrderCache AS c ON b.order_cache_sqlite_id = c.order_cache_sqlite_id '
        'JOIN $tableOrder AS d ON c.order_sqlite_id = d.order_sqlite_id '
        'WHERE a.soft_delete = ? AND b.soft_delete = ? AND c.soft_delete = ? AND c.accepted = ? AND c.cancel_by = ? AND d.soft_delete = ? '
        'AND a.mod_group_id = ? AND b.status = ? AND d.payment_status = ? '
        'AND SUBSTR(a.created_at, 1, 10) >= ? AND SUBSTR(a.created_at, 1, 10) < ? GROUP BY a.mod_name  ',
        ['', '', '', 0, '', '', mod_group_id, 0, 1, date1, date2]);
    return result.map((json) => OrderModifierDetail.fromJson(json)).toList();
  }

/*
  read all paid modifier with opening balance
*/
  Future<List<OrderModifierDetail>> readAllPaidModifierWithOB(String mod_group_id, String date1, String date2) async {
    final db = await instance.database;
    final result = await db.rawQuery(
        'SELECT a.*, COUNT(a.order_modifier_detail_sqlite_id) AS item_sum, SUM(a.mod_price + 0.0) AS net_sales '
            'FROM $tableOrderModifierDetail AS a JOIN $tableOrderDetail AS b ON a.order_detail_sqlite_id = b.order_detail_sqlite_id '
            'JOIN $tableOrderCache AS c ON b.order_cache_sqlite_id = c.order_cache_sqlite_id '
            'JOIN $tableOrder AS d ON c.order_sqlite_id = d.order_sqlite_id JOIN $tableCashRecord AS e on d.settlement_key = e.settlement_key AND e.remark = ?'
            'WHERE a.soft_delete = ? AND b.soft_delete = ? AND c.soft_delete = ? AND c.accepted = ? AND c.cancel_by = ? AND d.soft_delete = ? '
            'AND a.mod_group_id = ? AND b.status = ? AND d.payment_status = ? '
            'AND SUBSTR(e.created_at, 1, 10) >= ? AND SUBSTR(e.created_at, 1, 10) < ? GROUP BY a.mod_name  ',
        ['Opening Balance', '', '', '', 0, '', '', mod_group_id, 0, 1, date1, date2]);
    return result.map((json) => OrderModifierDetail.fromJson(json)).toList();
  }

/*
  read all paid modifier group
*/
  Future<List<ModifierGroup>> readAllPaidModifierGroup(String date1, String date2) async {
    final db = await instance.database;
    final result = await db.rawQuery(
        'SELECT a.created_at, b.*, SUM(a.mod_price + 0.0) AS net_sales, COUNT(a.order_modifier_detail_sqlite_id) AS item_sum '
        'FROM $tableOrderModifierDetail AS a JOIN $tableModifierGroup AS b ON a.mod_group_id = b.mod_group_id '
        'JOIN $tableOrderDetail AS c ON a.order_detail_sqlite_id = c.order_detail_sqlite_id '
        'JOIN $tableOrderCache AS d ON c.order_cache_sqlite_id = d.order_cache_sqlite_id '
        'JOIN $tableOrder AS e ON d.order_sqlite_id = e.order_sqlite_id '
        'WHERE a.soft_delete = ? AND c.soft_delete = ? AND d.soft_delete = ? AND e.soft_delete = ? '
        'AND c.status = ? AND d.accepted = ? AND d.cancel_by = ? AND e.payment_status = ? '
        'AND SUBSTR(a.created_at, 1, 10) >= ? AND SUBSTR(a.created_at, 1, 10) < ? GROUP BY b.mod_group_id  ',
        ['', '', '', '', 0, 0, '', 1, date1, date2]);
    return result.map((json) => ModifierGroup.fromJson(json)).toList();
  }

/*
  read all paid modifier group with opening balance
*/
  Future<List<ModifierGroup>> readAllPaidModifierGroupWithOB(String date1, String date2) async {
    final db = await instance.database;
    final result = await db.rawQuery(
        'SELECT a.created_at, b.*, SUM(a.mod_price + 0.0) AS net_sales, COUNT(a.order_modifier_detail_sqlite_id) AS item_sum '
            'FROM $tableOrderModifierDetail AS a JOIN $tableModifierGroup AS b ON a.mod_group_id = b.mod_group_id '
            'JOIN $tableOrderDetail AS c ON a.order_detail_sqlite_id = c.order_detail_sqlite_id '
            'JOIN $tableOrderCache AS d ON c.order_cache_sqlite_id = d.order_cache_sqlite_id '
            'JOIN $tableOrder AS e ON d.order_sqlite_id = e.order_sqlite_id JOIN $tableCashRecord AS f on e.settlement_key = f.settlement_key AND f.remark = ?'
            'WHERE a.soft_delete = ? AND c.soft_delete = ? AND d.soft_delete = ? AND e.soft_delete = ? '
            'AND c.status = ? AND d.accepted = ? AND d.cancel_by = ? AND e.payment_status = ? '
            'AND SUBSTR(f.created_at, 1, 10) >= ? AND SUBSTR(f.created_at, 1, 10) < ? GROUP BY b.mod_group_id  ',
        ['Opening Balance', '', '', '', '', 0, 0, '', 1, date1, date2]);
    return result.map((json) => ModifierGroup.fromJson(json)).toList();
  }

/*
  read all category with product
*/
  Future<List<OrderDetail>> readAllCategoryWithOrderDetail2(String date1, String date2) async {
    final db = await instance.database;
    final result = await db.rawQuery(
        'SELECT b.*, SUM(b.original_price * b.quantity + 0.0) AS category_net_sales, SUM(b.price * b.quantity + 0.0) AS category_gross_sales, '
            'SUM(CASE WHEN b.unit != ? OR b.unit != ? THEN 1 ELSE b.quantity END) AS category_item_sum '
            'FROM $tableOrderDetail AS b JOIN $tableOrderCache AS c ON b.order_cache_sqlite_id = c.order_cache_sqlite_id '
            'JOIN $tableOrder AS d ON c.order_sqlite_id = d.order_sqlite_id '
            'WHERE b.soft_delete = ? AND c.soft_delete = ? AND c.accepted = ? AND c.cancel_by = ? AND d.soft_delete = ? AND b.status = ? AND d.payment_status = ? '
            'AND SUBSTR(b.created_at, 1, 10) >= ? AND SUBSTR(b.created_at, 1, 10) < ? GROUP BY b.category_name '
            'ORDER BY b.category_name DESC',
        ['each', 'each_c', '', '', 0, '', '', 0, 1, date1, date2]);
    return result.map((json) => OrderDetail.fromJson(json)).toList();
  }

/*
  read all category with product with opening balance
*/
  Future<List<OrderDetail>> readAllCategoryWithOrderDetail2WithOB(String date1, String date2) async {
    final db = await instance.database;
    final result = await db.rawQuery(
        'SELECT b.*, SUM(b.original_price * b.quantity + 0.0) AS category_net_sales, SUM(b.price * b.quantity + 0.0) AS category_gross_sales, '
            'SUM(CASE WHEN b.unit != ? OR b.unit != ? THEN 1 ELSE b.quantity END) AS category_item_sum '
            'FROM $tableOrderDetail AS b JOIN $tableOrderCache AS c ON b.order_cache_sqlite_id = c.order_cache_sqlite_id '
            'JOIN $tableOrder AS d ON c.order_sqlite_id = d.order_sqlite_id JOIN $tableCashRecord AS e on d.settlement_key = e.settlement_key AND e.remark = ?'
            'WHERE b.soft_delete = ? AND c.soft_delete = ? AND c.accepted = ? AND c.cancel_by = ? AND d.soft_delete = ? AND b.status = ? AND d.payment_status = ? '
            'AND SUBSTR(e.created_at, 1, 10) >= ? AND SUBSTR(e.created_at, 1, 10) < ? GROUP BY b.category_name '
            'ORDER BY b.category_name DESC',
        ['each', 'each_c', 'Opening Balance', '', '', 0, '', '', 0, 1, date1, date2]);
    return result.map((json) => OrderDetail.fromJson(json)).toList();
  }

/*
  read all order detail with category
*/
  Future<List<OrderDetail>> readAllPaidOrderDetailWithCategory2(String category_name, String date1, String date2) async {
    final db = await instance.database;
    final result = await db.rawQuery(
        'SELECT a.created_at, a.product_name, a.product_variant_name, a.unit, SUM(a.original_price * a.quantity + 0.0) AS net_sales, SUM(a.price * a.quantity + 0.0) AS gross_price, '
            'SUM(CASE WHEN a.unit != ? AND a.unit != ? THEN a.per_quantity_unit * a.quantity ELSE a.quantity END) AS item_sum, '
            'SUM(CASE WHEN a.unit != ? THEN 1 ELSE 0 END) AS item_qty '
            'FROM $tableOrderDetail AS a JOIN $tableOrderCache AS b ON a.order_cache_sqlite_id = b.order_cache_sqlite_id '
            'JOIN $tableOrder AS c ON b.order_sqlite_id = c.order_sqlite_id '
            'WHERE a.soft_delete = ? AND a.status = ? AND b.soft_delete = ? AND b.accepted = ? AND c.soft_delete = ? AND c.payment_status = ? AND a.category_name = ? '
            'AND SUBSTR(a.created_at, 1, 10) >= ? AND SUBSTR(a.created_at, 1, 10) < ? '
            'GROUP BY a.product_name, a.product_variant_name ORDER BY a.product_name',
        ['each', 'each_c', 'each', '', 0, '', 0, '', 1, category_name, date1, date2]);
    return result.map((json) => OrderDetail.fromJson(json)).toList();
  }

/*
  read all order detail with category with opening balance
*/
  Future<List<OrderDetail>> readAllPaidOrderDetailWithCategory2WithOB(String category_name, String date1, String date2) async {
    final db = await instance.database;
    final result = await db.rawQuery(
        'SELECT a.created_at, a.product_name, a.product_variant_name, a.unit, SUM(a.original_price * a.quantity + 0.0) AS net_sales, SUM(a.price * a.quantity + 0.0) AS gross_price, '
            'SUM(CASE WHEN a.unit != ? AND a.unit != ? THEN a.per_quantity_unit * a.quantity ELSE a.quantity END) AS item_sum, '
            'SUM(CASE WHEN a.unit != ? THEN 1 ELSE 0 END) AS item_qty '
            'FROM $tableOrderDetail AS a JOIN $tableOrderCache AS b ON a.order_cache_sqlite_id = b.order_cache_sqlite_id '
            'JOIN $tableOrder AS c ON b.order_sqlite_id = c.order_sqlite_id JOIN $tableCashRecord AS d on c.settlement_key = d.settlement_key AND d.remark = ?'
            'WHERE a.soft_delete = ? AND a.status = ? AND b.soft_delete = ? AND b.accepted = ? AND c.soft_delete = ? AND c.payment_status = ? AND a.category_name = ? '
            'AND SUBSTR(d.created_at, 1, 10) >= ? AND SUBSTR(d.created_at, 1, 10) < ? '
            'GROUP BY a.product_name, a.product_variant_name ORDER BY a.product_name',
        ['each', 'each_c', 'each', 'Opening Balance', '', 0, '', 0, '', 1, category_name, date1, date2]);
    return result.map((json) => OrderDetail.fromJson(json)).toList();
  }

/*
  read All Branch Link Dining Option
*/
  Future<List<BranchLinkDining>> readAllBranchLinkDiningOption() async {
    final db = await instance.database;
    final result = await db.rawQuery(
        'SELECT a.*, b.name FROM $tableBranchLinkDining AS a JOIN $tableDiningOption AS b ON a.dining_id = b.dining_id WHERE a.soft_delete = ? AND b.soft_delete = ?', ['', '']);
    return result.map((json) => BranchLinkDining.fromJson(json)).toList();
  }

/*
  read all refund order
*/
  Future<List<Order>> readAllRefundOrder(String date1, String date2) async {
    final db = await instance.database;
    final result = await db.rawQuery(
        'SELECT a.*, b.payment_type_id, c.refund_by AS refund_name, c.created_at AS refund_at FROM $tableOrder AS a '
        'LEFT JOIN $tablePaymentLinkCompany AS b ON a.payment_link_company_id = b.payment_link_company_id '
        'JOIN $tableRefund AS c ON a.refund_key = c.refund_key '
        'WHERE a.payment_status = ? AND a.refund_key != ? AND a.soft_delete = ? AND c.soft_delete = ? '
        'AND SUBSTR(a.created_at, 1, 10) >= ? AND SUBSTR(a.created_at, 1, 10) < ? '
        'ORDER BY a.created_at DESC',
        [2, '', '', '', date1, date2]);
    return result.map((json) => Order.fromJson(json)).toList();
  }

/*
  read all refund order with opening balance
*/
  Future<List<Order>> readAllRefundOrderWithOB(String date1, String date2) async {
    final db = await instance.database;
    final result = await db.rawQuery(
        'SELECT a.*, b.payment_type_id, c.refund_by AS refund_name, c.created_at AS refund_at FROM $tableOrder AS a '
            'LEFT JOIN $tablePaymentLinkCompany AS b ON a.payment_link_company_id = b.payment_link_company_id '
            'JOIN $tableRefund AS c ON a.refund_key = c.refund_key JOIN $tableCashRecord AS d on a.settlement_key = d.settlement_key AND d.remark = ?'
            'WHERE a.payment_status = ? AND a.refund_key != ? AND a.soft_delete = ? AND c.soft_delete = ? '
            'AND SUBSTR(d.created_at, 1, 10) >= ? AND SUBSTR(d.created_at, 1, 10) < ? '
            'ORDER BY a.created_at DESC',
        ['Opening Balance', 2, '', '', '', date1, date2]);
    return result.map((json) => Order.fromJson(json)).toList();
  }

/*
  read all refund order
*/
  Future<List<Order>> readAllNotSettlementRefundOrder() async {
    final db = await instance.database;
    final result = await db.rawQuery(
        'SELECT a.*, b.payment_type_id, c.refund_by AS refund_name, c.created_at AS refund_at FROM $tableOrder AS a '
        'LEFT JOIN $tablePaymentLinkCompany AS b ON a.payment_link_company_id = b.payment_link_company_id AND b.soft_delete = ? '
        'JOIN $tableRefund AS c ON a.refund_key = c.refund_key '
        'WHERE a.payment_status = ? AND a.refund_key != ? AND a.settlement_key = ? AND a.soft_delete = ? AND c.soft_delete = ? ORDER BY a.created_at DESC',
        ['', 2, '', '', '', '']);
    return result.map((json) => Order.fromJson(json)).toList();
  }

/*
  read all transfer record
*/
  Future<List<TransferOwner>> readAllTransferOwner(String date1, String date2) async {
    final db = await instance.database;
    final result = await db.rawQuery(
        'SELECT a.*, b.name AS name1, c.name AS name2 FROM $tableTransferOwner AS a JOIN $tableUser AS b ON a.transfer_from_user_id = b.user_id '
        'JOIN $tableUser AS c ON a.transfer_to_user_id = c.user_id '
            'WHERE a.soft_delete = ? AND b.soft_delete = ? AND c.soft_delete = ? '
        'AND SUBSTR(a.created_at, 1, 10) >= ? AND SUBSTR(a.created_at, 1, 10) < ? ORDER BY a.created_at DESC',
        ['', '', '', date1, date2]);
    return result.map((json) => TransferOwner.fromJson(json)).toList();
  }

/*
  read specific transfer owner
*/
  Future<TransferOwner> readSpecificTransferOwnerByLocalId(String transfer_owner_key) async {
    final db = await instance.database;
    final result = await db.rawQuery('SELECT * FROM $tableTransferOwner WHERE soft_delete = ? AND transfer_owner_key = ?', ['', transfer_owner_key]);
    return TransferOwner.fromJson(result.first);
  }

/*
  read all order tax detail
*/
  Future<List<OrderTaxDetail>> readAllPaidOrderTax() async {
    final db = await instance.database;
    final result = await db.rawQuery(
        'SELECT a.*, '
        '(SELECT SUM(tax_amount + 0.0) FROM $tableOrderTaxDetail WHERE order_tax_detail_sqlite_id = a.order_tax_detail_sqlite_id) '
        'AS total_tax_amount FROM $tableOrderTaxDetail AS a '
        'JOIN $tableOrder AS b ON a.order_sqlite_id = b.order_sqlite_id '
        'WHERE a.soft_delete = ? AND b.soft_delete = ? AND b.payment_status = ?',
        ['', '', 1]);

    return result.map((json) => OrderTaxDetail.fromJson(json)).toList();
  }

/*
  read all order tax detail with opening balance
*/
  Future<List<OrderTaxDetail>> readAllPaidOrderTaxWithOB() async {
    final db = await instance.database;
    final result = await db.rawQuery(
        'SELECT a.*, c.created_at AS counterOpenDate, '
            '(SELECT SUM(tax_amount + 0.0) FROM $tableOrderTaxDetail WHERE order_tax_detail_sqlite_id = a.order_tax_detail_sqlite_id) '
            'AS total_tax_amount FROM $tableOrderTaxDetail AS a '
            'JOIN $tableOrder AS b ON a.order_sqlite_id = b.order_sqlite_id '
            'JOIN $tableCashRecord AS c on b.settlement_key = c.settlement_key AND c.remark = ?'
            'WHERE a.soft_delete = ? AND b.soft_delete = ? AND b.payment_status = ?',
        ['Opening Balance' ,'', '', 1]);

    return result.map((json) => OrderTaxDetail.fromJson(json)).toList();
  }

/*
  read all branch link tax
*/
  Future<List<BranchLinkTax>> readBranchLinkTax() async {
    final db = await instance.database;
    final result = await db.rawQuery(
        'SELECT a.*, b.name FROM $tableBranchLinkTax AS a JOIN $tableTax AS b ON a.tax_id = b.tax_id '
        'WHERE a.soft_delete = ? AND b.soft_delete = ? ORDER BY b.tax_id ',
        ['', '']);
    return result.map((json) => BranchLinkTax.fromJson(json)).toList();
  }

/*
  read all cancel item
*/
  Future<List<OrderDetailCancel>> readAllCancelItem2(String date1, String date2) async {
    final db = await instance.database;
    final result = await db.rawQuery(
        'SELECT a.*, SUM(CASE WHEN b.unit != ? AND b.unit != ? THEN 1 ELSE a.quantity END) AS total_item '
            'FROM $tableOrderDetailCancel AS a JOIN $tableOrderDetail AS b ON a.order_detail_key = b.order_detail_key '
            'WHERE a.soft_delete = ? AND SUBSTR(a.created_at, 1, 10) >= ? AND SUBSTR(a.created_at, 1, 10) < ? ',
        ['each', '', '', date1, date2]);
    return result.map((json) => OrderDetailCancel.fromJson(json)).toList();
  }

/*
  read all cancel item with opening balance
*/
  Future<List<OrderDetailCancel>> readAllCancelItem2WithOB(String date1, String date2) async {
    final db = await instance.database;
    final result = await db.rawQuery(
        'SELECT a.*, SUM(CASE WHEN b.unit != ? AND b.unit != ? THEN 1 ELSE a.quantity END) AS total_item '
            'FROM $tableOrderDetailCancel AS a JOIN $tableOrderDetail AS b ON a.order_detail_key = b.order_detail_key '
            'JOIN $tableOrderCache AS c ON b.order_cache_sqlite_id = c.order_cache_sqlite_id '
            'JOIN $tableOrder AS d ON c.order_sqlite_id = d.order_sqlite_id JOIN $tableCashRecord AS e on d.settlement_key = e.settlement_key AND e.remark = ?'
            'WHERE a.soft_delete = ? AND SUBSTR(e.created_at, 1, 10) >= ? AND SUBSTR(e.created_at, 1, 10) < ? ',
        ['each', '', 'Opening Balance', '', date1, date2]);
    return result.map((json) => OrderDetailCancel.fromJson(json)).toList();
  }

/*
  read all cancel item
*/
  Future<List<OrderDetail>> readAllCancelItem() async {
    final db = await instance.database;
    final result = await db.rawQuery('SELECT * FROM $tableOrderDetail WHERE cancel_by != ?', ['']);
    return result.map((json) => OrderDetail.fromJson(json)).toList();
  }

/*
  read all paid promotion detail
*/
  Future<List<OrderPromotionDetail>> readAllPaidOrderPromotionDetail() async {
    final db = await instance.database;
    final result = await db.rawQuery(
        'SELECT a.* FROM $tableOrderPromotionDetail AS a JOIN '
        '$tableOrder AS b ON a.order_sqlite_id = b.order_sqlite_id WHERE a.soft_delete = ? AND b.soft_delete = ? AND b.payment_status = ? AND b.payment_split != ?',
        ['', '', 1, 2]);
    return result.map((json) => OrderPromotionDetail.fromJson(json)).toList();
  }

/*
  read all paid promotion detail with opening balance
*/
  Future<List<OrderPromotionDetail>> readAllPaidOrderPromotionDetailWithOB() async {
    final db = await instance.database;
    final result = await db.rawQuery(
        'SELECT a.*, c.created_at AS counterOpenDate FROM $tableOrderPromotionDetail AS a JOIN '
            '$tableOrder AS b ON a.order_sqlite_id = b.order_sqlite_id JOIN $tableCashRecord AS c on b.settlement_key = c.settlement_key AND c.remark = ?'
            'WHERE a.soft_delete = ? AND b.soft_delete = ? AND b.payment_status = ? AND b.payment_split != ?',
        ['Opening Balance', '', '', 1, 2]);
    return result.map((json) => OrderPromotionDetail.fromJson(json)).toList();
  }

/*
  read all order
*/
  Future<List<Order>> readAllOrder() async {
    final db = await instance.database;
    final result = await db.rawQuery(
        'SELECT a.*, b.payment_type_id '
        'FROM $tableOrder AS a LEFT JOIN $tablePaymentLinkCompany AS b '
        'ON a.payment_link_company_id = b.payment_link_company_id '
        'WHERE a.soft_delete = ? AND a.payment_status != ? ORDER BY a.created_at DESC',
        ['', 0]);
    return result.map((json) => Order.fromJson(json)).toList();
  }

/*
  read all order with opening balance
*/
  Future<List<Order>> readAllOrderWithOB() async {
    final db = await instance.database;
    final result = await db.rawQuery(
        'SELECT a.*, b.payment_type_id, c.created_at AS counterOpenDate '
            'FROM $tableOrder AS a LEFT JOIN $tablePaymentLinkCompany AS b '
            'ON a.payment_link_company_id = b.payment_link_company_id '
            'JOIN $tableCashRecord AS c on a.settlement_key = c.settlement_key AND c.remark = ?'
            'WHERE a.soft_delete = ? AND a.payment_status != ? ORDER BY c.created_at DESC',
        ['Opening Balance', '', 0]);
    return result.map((json) => Order.fromJson(json)).toList();
  }

/*
  --------------------Refund part--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
*/

/*
  refund join
*/
  Future<List<Order>> readSpecificRefundOrder(String order_sqlite_id) async {
    final db = await instance.database;
    final result = await db.rawQuery(
        'SELECT a.*, b.name, b.payment_type_id, c.refund_by AS refund_name, c.created_at AS refund_at FROM $tableOrder AS a '
            'LEFT JOIN $tablePaymentLinkCompany AS b ON a.payment_link_company_id = b.payment_link_company_id AND b.soft_delete = ? '
            'JOIN $tableRefund AS c ON a.refund_key = c.refund_key '
            'WHERE a.payment_status = ? AND a.soft_delete = ? AND c.soft_delete = ? AND a.order_sqlite_id = ?',
        ['', 2, '', '', order_sqlite_id]);
    return result.map((json) => Order.fromJson(json)).toList();
  }

/*
  read all refund by local id
*/
  Future<Refund> readAllRefundByLocalId(int refund_sqlite_id) async {
    final db = await instance.database;
    final result = await db.rawQuery('SELECT * FROM $tableRefund WHERE refund_sqlite_id = ?', [refund_sqlite_id]);
    return Refund.fromJson(result.first);
  }

/*
  --------------------Settlement part----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
*/

/*
  read latest 7 rows settlement
*/
  Future<List<Settlement>> readLatest7Settlement() async {
    final db = await instance.database;
    final result = await db.rawQuery('SELECT * FROM $tableSettlement WHERE soft_delete = ? ORDER BY settlement_sqlite_id DESC LIMIT 7', ['']);
    return result.map((json) => Settlement.fromJson(json)).toList();
  }

/*
  read latest settlement
*/
  Future<Settlement?> readLatestSettlement() async {
    final db = await instance.database;
    final result = await db.rawQuery('SELECT * FROM $tableSettlement WHERE soft_delete = ? ORDER BY settlement_sqlite_id DESC LIMIT 1', ['']);
    if (result.isNotEmpty) {
      return Settlement.fromJson(result.first);
    } else {
      return null;
    }
  }

/*
  get all settlement order tax detail based on settlement id
*/
  Future<List<Order>> readAllSettlementOrderBySettlementKey(String settlement_key) async {
    final db = await instance.database;
    final result = await db.rawQuery(
        'SELECT *, SUM(final_amount + 0.0) AS gross_sales FROM $tableOrder '
        'WHERE soft_delete = ? AND refund_key = ? AND settlement_key = ? GROUP BY dining_id ',
        ['', '', settlement_key]);
    return result.map((json) => Order.fromJson(json)).toList();
  }

/*
  get all settlement order tax detail based on settlement id
*/
  Future<List<OrderTaxDetail>> readAllSettlementOrderTaxDetailBySettlementKey(String settlement_key) async {
    final db = await instance.database;
    final result = await db.rawQuery(
        'SELECT c.*, (SELECT SUM(a.tax_amount + 0.0) FROM $tableOrderTaxDetail AS a JOIN $tableOrder AS b ON a.order_key = b.order_key WHERE b.settlement_key = ? AND a.tax_id = c.tax_id AND b.refund_key = ?) AS total_tax_amount '
        'FROM $tableOrderTaxDetail AS c JOIN $tableOrder AS d ON c.order_key = d.order_key '
        'WHERE c.soft_delete = ? AND d.soft_delete = ? AND d.settlement_key = ? AND d.refund_key = ? GROUP BY c.tax_name ',
        [settlement_key, '', '', '', settlement_key, '']);
    return result.map((json) => OrderTaxDetail.fromJson(json)).toList();
  }

/*
  update subscription
*/
  Future<int> updateSubscription(Subscription data) async {
    final db = await instance.database;
    return await db.rawUpdate(
        'UPDATE $tableSubscription SET subscription_plan_id = ?, subscribe_package = ?, subscribe_fee = ?, duration = ?, '
            'branch_amount = ?, start_date = ? , end_date = ? , soft_delete = ? WHERE id = ?',
        [data.subscription_plan_id, data.subscribe_package, data.subscribe_fee, data.duration, data.branch_amount,
          data.start_date, data.end_date, data.soft_delete, data.id]);
  }

/*
  update settlement order detail cancel
*/
  Future<int> updateOrderDetailCancelSettlement(OrderDetailCancel data) async {
    final db = await instance.database;
    return await db.rawUpdate(
        'UPDATE $tableOrderDetailCancel SET updated_at = ?, sync_status = ?, settlement_key = ?, settlement_sqlite_id = ? '
        'WHERE order_detail_cancel_sqlite_id = ? ',
        [data.updated_at, data.sync_status, data.settlement_key, data.settlement_sqlite_id, data.order_detail_cancel_sqlite_id]);
  }

/*
  get not yet settlement order detail cancel
*/
  Future<List<OrderDetailCancel>> readAllNotSettlementOrderDetailCancel() async {
    final db = await instance.database;
    final result = await db.rawQuery('SELECT * FROM $tableOrderDetailCancel WHERE soft_delete = ? AND settlement_key = ? ', ['', '']);
    return result.map((json) => OrderDetailCancel.fromJson(json)).toList();
  }

/*
  select sum cancel item quantity
*/
  Future<OrderDetailCancel?> sumAllNotSettlementCancelItemQuantity() async {
    final db = await instance.database;
    final result = await db.rawQuery(
        'SELECT SUM(CASE WHEN b.unit != ? OR b.unit != ? THEN 1 ELSE a.quantity END) AS total_item '
            'FROM $tableOrderDetailCancel AS a JOIN $tableOrderDetail AS b ON a.order_detail_key = b.order_detail_key '
            'WHERE a.soft_delete = ? AND a.settlement_key = ? ',
        ['each', '', '', '']);
    if(result.isNotEmpty){
      return OrderDetailCancel.fromJson(result.first);
    } else {
      return null;
    }
  }

/*
  update settlement order
*/
  Future<int> updateOrderSettlement(Order data) async {
    final db = await instance.database;
    return await db.rawUpdate('UPDATE $tableOrder SET updated_at = ?, sync_status = ?, settlement_key = ?, settlement_sqlite_id = ? WHERE order_sqlite_id = ? ',
        [data.updated_at, data.sync_status, data.settlement_key, data.settlement_sqlite_id, data.order_sqlite_id]);
  }

/*
  get settlement order promotion detail
*/
  Future<List<OrderPromotionDetail>> readAllNotSettlementOrderPromotionDetail() async {
    final db = await instance.database;
    final result = await db.rawQuery(
        'SELECT c.*, (SELECT SUM(promotion_amount + 0.0) FROM $tableOrderPromotionDetail AS a JOIN $tableOrder AS b ON a.order_key = b.order_key WHERE b.settlement_key = ? AND b.refund_key = ? ) '
        'AS total_promotion_amount FROM $tableOrderPromotionDetail AS c JOIN $tableOrder AS d ON c.order_key = d.order_key '
        'WHERE c.soft_delete = ? AND d.soft_delete = ? AND d.settlement_key = ? AND d.refund_key = ? ',
        ['', '', '', '', '', '']);
    return result.map((json) => OrderPromotionDetail.fromJson(json)).toList();
  }

/*
  get settlement order tax detail
*/
  Future<List<OrderTaxDetail>> readAllNotSettlementOrderTaxDetail() async {
    final db = await instance.database;
    final result = await db.rawQuery(
        'SELECT c.*, (SELECT SUM(a.tax_amount + 0.0) FROM $tableOrderTaxDetail AS a JOIN $tableOrder AS b ON a.order_key = b.order_key WHERE b.settlement_key = ? AND b.refund_key = ?) AS total_tax_amount '
        'FROM $tableOrderTaxDetail AS c JOIN $tableOrder AS d ON c.order_key = d.order_key '
        'WHERE c.soft_delete = ? AND d.soft_delete = ? AND d.settlement_key = ? AND d.refund_key = ? ',
        ['', '', '', '', '', '']);
    return result.map((json) => OrderTaxDetail.fromJson(json)).toList();
  }

/*
  get not yet settlement order
*/
  Future<List<Order>> readAllNotSettlementOrder() async {
    final db = await instance.database;
    final result = await db.rawQuery('SELECT * FROM $tableOrder WHERE soft_delete = ? AND settlement_key = ? ', ['', '']);
    return result.map((json) => Order.fromJson(json)).toList();
  }

/*
  get not yet settlement order
*/
  Future<List<Order>> readAllNotSettlementPaidOrder() async {
    final db = await instance.database;
    final result = await db.rawQuery(
        'SELECT *, (SELECT SUM(final_amount + 0.0) FROM $tableOrder WHERE settlement_key = ? AND refund_key = ?) AS gross_sales '
        'FROM $tableOrder WHERE soft_delete = ? AND settlement_key = ? ',
        ['', '', '', '']);
    return result.map((json) => Order.fromJson(json)).toList();
  }

/*
  get not yet settlement refund
*/
  Future<List<Order>> readAllNotSettlementRefundedOrder() async {
    final db = await instance.database;
    final result = await db.rawQuery(
        'SELECT *, (SELECT SUM(final_amount + 0.0) FROM $tableOrder WHERE refund_key != ? AND settlement_key = ?) AS gross_sales FROM $tableOrder '
        'WHERE soft_delete = ? AND refund_key != ? AND settlement_key = ? ',
        ['', '', '', '', '']);
    return result.map((json) => Order.fromJson(json)).toList();
  }

/*
  read specific settlement link payment by payment link company id
*/
  Future<SettlementLinkPayment> readSpecificSettlementLinkPaymentByPaymentLinkCompany(int payment_link_company_id) async {
    final db = await instance.database;
    final result = await db.rawQuery('SELECT * FROM $tableSettlementLinkPayment WHERE soft_delete = ? AND payment_link_company_id = ?', ['', payment_link_company_id]);

    return SettlementLinkPayment.fromJson(result.first);
  }

/*
  read all settlement link payment by settlement key
*/
  Future<SettlementLinkPayment> readAllSettlementLinkPaymentWithKeyAndPayment(String settlement_key, int payment_link_company_id) async {
    final db = await instance.database;
    final result = await db.rawQuery(
        'SELECT * FROM $tableSettlementLinkPayment WHERE soft_delete = ? AND settlement_key = ? AND payment_link_company_id = ? ', ['', settlement_key, payment_link_company_id]);

    return SettlementLinkPayment.fromJson(result.first);
  }

/*
  read specific settlement link payment by local id
*/
  Future<SettlementLinkPayment> readSpecificSettlementLinkPaymentByLocalId(int settlement_link_payment_sqlite_id) async {
    final db = await instance.database;
    final result = await db.rawQuery(
        'SELECT * FROM $tableSettlementLinkPayment WHERE soft_delete = ? AND settlement_link_payment_sqlite_id = ? '
        'ORDER BY settlement_link_payment_sqlite_id DESC LIMIT 1 ',
        ['', settlement_link_payment_sqlite_id]);

    return SettlementLinkPayment.fromJson(result.first);
  }

/*
  read specific settlement by local id
*/
  Future<Settlement> readSpecificSettlementByLocalId(int settlement_sqlite_id) async {
    final db = await instance.database;
    final result = await db.rawQuery('SELECT * FROM $tableSettlement WHERE soft_delete = ? AND settlement_sqlite_id = ?', ['', settlement_sqlite_id]);

    return Settlement.fromJson(result.first);
  }

/*
  update settlement
*/
  Future<int> updateSettlement(Settlement data) async {
    final db = await instance.database;
    return await db.rawUpdate(
        'UPDATE $tableSettlement SET updated_at = ?, sync_status = ?, total_tax = ?, total_cancellation = ?, total_discount = ?, '
        'total_refund_amount = ?, total_refund_bill = ?, total_sales = ?, total_bill = ? '
        'WHERE settlement_sqlite_id = ? ',
        [
          data.updated_at,
          data.sync_status,
          data.total_tax,
          data.total_cancellation,
          data.total_discount,
          data.total_refund_amount,
          data.total_refund_bill,
          data.total_sales,
          data.total_bill,
          data.settlement_sqlite_id,
        ]);
  }

/*
  update settlement link payment
*/
  Future<int> updateSettlementLinkPayment(SettlementLinkPayment data) async {
    final db = await instance.database;
    return await db.rawUpdate(
        'UPDATE $tableSettlementLinkPayment SET updated_at = ?, sync_status = ?, total_sales = ?, total_bill = ? '
        'WHERE settlement_link_payment_sqlite_id = ? ',
        [
          data.updated_at,
          data.sync_status,
          data.total_sales,
          data.total_bill,
          data.settlement_link_payment_sqlite_id,
        ]);
  }

/*
  --------------------Qr order part----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
*/

/*
  read table use id by table use key
*/
  Future<TableUse> readSpecificTableUseByKey(String key) async {
    final db = await instance.database;
    final result = await db.rawQuery('SELECT * FROM $tableTableUse WHERE soft_delete = ? AND status = ? AND table_use_key = ?', ['', 0, key]);

    return TableUse.fromJson(result.first);
  }

/*
  read table use id by table use key
*/
  Future<TableUse?> readSpecificTableUseByKey2(String key) async {
    final db = await instance.database;
    final result = await db.rawQuery('SELECT * FROM $tableTableUse WHERE soft_delete = ? AND table_use_key = ? ', ['', key]);
    if(result.isNotEmpty){
      return TableUse.fromJson(result.first);
    } else {
      return null;
    }
  }

/*
  update order cache qr order table local id
*/
  Future<int> updateOrderCacheTableLocalId(OrderCache data) async {
    final db = await instance.database;
    return await db
        .rawUpdate('UPDATE $tableOrderCache SET qr_order_table_sqlite_id = ? WHERE order_cache_sqlite_id = ?', [data.qr_order_table_sqlite_id, data.order_cache_sqlite_id]);
  }

/*
  reject/accept order cache
*/
  Future<int> updateOrderCacheAccept(OrderCache data) async {
    final db = await instance.database;
    return await db.rawUpdate(
        'UPDATE $tableOrderCache SET soft_delete = ?, updated_at = ?, sync_status = ?, order_by = ?, order_by_user_id = ?, accepted = ? WHERE order_cache_sqlite_id = ?',
        [data.soft_delete, data.updated_at, data.sync_status, data.order_by, data.order_by_user_id, data.accepted, data.order_cache_sqlite_id]);
  }

/*
  read all order detail by order cache
*/
  Future<List<OrderDetail>> readAllOrderDetailByOrderCache(int order_cache_sqlite_id) async {
    final db = await instance.database;
    final result = await db.rawQuery(
        'SELECT a.* FROM $tableOrderDetail AS a '
        'WHERE a.soft_delete = ? AND a.status = ? AND a.order_cache_sqlite_id = ?',
        ['', 0, order_cache_sqlite_id]);
    return result.map((json) => OrderDetail.fromJson(json)).toList();
  }

/*
  read not accepted order cache
*/
  Future<List<OrderCache>> readNotAcceptedQROrderCache() async {
    final db = await instance.database;
    final result = await db.rawQuery(
        'SELECT * FROM (SELECT a.*, b.number AS table_number, c.name '
        'FROM $tableOrderCache AS a LEFT JOIN $tablePosTable AS b ON a.qr_order_table_id = b.table_id '
        'LEFT JOIN $tableDiningOption AS c ON a.dining_id = c.dining_id '
        'WHERE a.soft_delete = ? AND b.soft_delete = ? AND c.soft_delete = ? AND a.qr_order = ? AND a.accepted = ? '
        'UNION '
        'SELECT d.*, null AS table_number, e.name FROM $tableOrderCache AS d LEFT JOIN $tableDiningOption AS e ON d.dining_id = e.dining_id '
        'WHERE d.soft_delete = ? AND e.soft_delete = ? AND d.qr_order_table_id = ? AND d.qr_order = ? AND d.accepted = ?) ORDER BY created_at DESC ',
        ['', '', '', 1, 1, '', '', '', 1, 1]);
    return result.map((json) => OrderCache.fromJson(json)).toList();
  }

/*
  ----------------------------Second screen part------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
*/

/*
  read all second screen (not soft_deleted)
*/
  Future<List<SecondScreen>> readAllNotDeletedSecondScreen() async {
    final db = await instance.database;
    final result = await db.rawQuery(
        'SELECT * FROM $tableSecondScreen WHERE soft_delete = ?',
        ['']);
    return result.map((json) => SecondScreen.fromJson(json)).toList();
  }


/*
  ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
*/

/*
  read category by cloud id
*/
  Future<Categories> readSpecificCategoryByCloudId(String id) async {
    final db = await instance.database;
    final result = await db.rawQuery('SELECT * FROM $tableCategories WHERE category_id = ?', [id]);

    return Categories.fromJson(result.first);
  }

/*
  read category by local id
*/
  Future<Categories> readSpecificCategoryByLocalId(String id) async {
    final db = await instance.database;
    final result = await db.rawQuery('SELECT * FROM $tableCategories WHERE category_sqlite_id = ?', [id]);

    return Categories.fromJson(result.first);
  }

/*
  read branch link product by cloud id
*/
  Future<BranchLinkProduct?> readSpecificBranchLinkProductByCloudId(String id) async {
    final db = await instance.database;
    final result = await db.rawQuery('SELECT * FROM $tableBranchLinkProduct WHERE soft_delete = ? AND branch_link_product_id = ?', ['', id]);
    if (result.isNotEmpty) {
      return BranchLinkProduct.fromJson(result.first);
    } else {
      return null;
    }
  }

/*
  read branch by cloud id
*/
  Future<Branch?> readSpecificBranch(int id) async {
    final db = await instance.database;
    final result = await db.rawQuery('SELECT branchID as branch_id, * FROM $tableBranch WHERE branchID = ?', [id]);
    if (result.isNotEmpty) {
      return Branch.fromJson(result.first);
    } else {
      return null;
    }
  }

/*
  ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
*/

/*
  update table local id
*/

/*
  update sync variant item for insert
*/
  Future<int> updateSyncVariantItem(VariantItem data) async {
    final db = await instance.database;
    return await db.rawUpdate('UPDATE $tableVariantItem SET variant_item_id = ?, sync_status = ?, updated_at = ? WHERE variant_item_sqlite_id = ?',
        [data.variant_item_id, data.sync_status, data.updated_at, data.variant_item_sqlite_id]);
  }

  /*
  update sync variant item for update
*/
  Future<int> updateSyncVariantItemForUpdate(VariantItem data) async {
    final db = await instance.database;
    return await db.rawUpdate(
        'UPDATE $tableVariantItem SET sync_status = ?, updated_at = ? WHERE variant_group_sqlite_id = ?', [data.sync_status, data.updated_at, data.variant_group_sqlite_id]);
  }

/*
  update sync product variant for insert
*/
  Future<int> updateSyncProductVariant(ProductVariant data) async {
    final db = await instance.database;
    return await db.rawUpdate(
        'UPDATE $tableProductVariant SET product_variant_id = ?, sync_status = ?, updated_at = ? WHERE product_variant_sqlite_id = ? AND product_sqlite_id = ? ',
        [data.product_variant_id, data.sync_status, data.updated_at, data.product_variant_sqlite_id, data.product_sqlite_id]);
  }

/*
  update sync product variant for delete
*/
  Future<int> updateSyncProductVariantForDelete(ProductVariant data) async {
    final db = await instance.database;
    return await db
        .rawUpdate('UPDATE $tableProductVariant SET sync_status = ?, updated_at = ? WHERE product_sqlite_id = ? ', [data.sync_status, data.updated_at, data.product_sqlite_id]);
  }

/*
  update sync product variant for update
*/
  Future<int> updateSyncProductVariantForUpdate(ProductVariant data) async {
    final db = await instance.database;
    return await db.rawUpdate('UPDATE $tableProductVariant SET sync_status = ?, updated_at = ? WHERE product_variant_sqlite_id = ? AND product_sqlite_id = ? ',
        [data.sync_status, data.updated_at, data.product_variant_sqlite_id, data.product_sqlite_id]);
  }

/*
  update sync product variant detail for insert
*/
  Future<int> updateSyncProductVariantDetail(ProductVariantDetail data) async {
    final db = await instance.database;
    return await db.rawUpdate(
        'UPDATE $tableProductVariantDetail SET product_variant_detail_id = ?, sync_status = ?, updated_at = ? WHERE product_variant_sqlite_id = ? AND variant_item_sqlite_id = ?', [
      data.product_variant_detail_id,
      data.sync_status,
      data.updated_at,
      data.product_variant_sqlite_id,
      data.variant_item_sqlite_id,
    ]);
  }

/*
  update sync product variant detail for update
*/
  Future<int> updateSyncProductVariantDetailForUpdate(ProductVariantDetail data) async {
    final db = await instance.database;
    return await db.rawUpdate('UPDATE $tableProductVariantDetail SET sync_status = ?, updated_at = ? WHERE product_variant_sqlite_id = ? ', [
      data.sync_status,
      data.updated_at,
      data.product_variant_sqlite_id,
    ]);
  }

/*
  update sync branch link product for delete all
*/
  Future<int> updateSyncBranchLinkProductForDeleteAll(BranchLinkProduct data) async {
    final db = await instance.database;
    return await db.rawUpdate('UPDATE $tableBranchLinkProduct SET sync_status = ?, updated_at = ? WHERE product_sqlite_id = ?', [
      data.sync_status,
      data.updated_at,
      data.product_sqlite_id,
    ]);
  }

/*
  update sync branch link product for insert
*/
  Future<int> updateSyncBranchLinkProduct(BranchLinkProduct data) async {
    final db = await instance.database;
    return await db.rawUpdate(
        'UPDATE $tableBranchLinkProduct SET branch_link_product_id = ?,  sync_status = ?, updated_at = ? WHERE product_sqlite_id = ? AND product_variant_sqlite_id = ? ', [
      data.branch_link_product_id,
      data.sync_status,
      data.updated_at,
      data.product_sqlite_id,
      data.product_variant_sqlite_id,
    ]);
  }

  /*
  update sync branch link product for update
*/
  Future<int> updateSyncBranchLinkProductForUpdate(BranchLinkProduct data) async {
    final db = await instance.database;
    return await db.rawUpdate('UPDATE $tableBranchLinkProduct SET sync_status = ?, updated_at = ? WHERE product_sqlite_id = ? AND product_variant_sqlite_id = ? ', [
      data.sync_status,
      data.updated_at,
      data.product_sqlite_id,
      data.product_variant_sqlite_id,
    ]);
  }

  /*
  update sync variant group for delete
*/
  Future<int> updateSyncVariantGroupForDelete(VariantGroup data) async {
    final db = await instance.database;
    return await db
        .rawUpdate('UPDATE $tableVariantGroup SET sync_status = ?, updated_at = ? WHERE product_sqlite_id = ?', [data.sync_status, data.updated_at, data.product_sqlite_id]);
  }

  /*
  update sync variant group for insert
*/
  Future<int> updateSyncVariantGroup(VariantGroup data) async {
    final db = await instance.database;
    return await db.rawUpdate('UPDATE $tableVariantGroup SET variant_group_id = ?, sync_status = ?, updated_at = ? WHERE variant_group_sqlite_id = ?',
        [data.variant_group_id, data.sync_status, data.updated_at, data.variant_group_sqlite_id]);
  }

  /*
  update sync modifier link product for insert
*/
  Future<int> updateSyncModifierLinkProduct(ModifierLinkProduct data) async {
    final db = await instance.database;
    return await db.rawUpdate('UPDATE $tableModifierLinkProduct SET modifier_link_product_id = ?, sync_status = ?, updated_at = ? WHERE modifier_link_product_sqlite_id = ?',
        [data.modifier_link_product_id, data.sync_status, data.updated_at, data.modifier_link_product_sqlite_id]);
  }

  /*
  update sync modifier link product for update
*/
  Future<int> updateSyncModifierLinkProductForUpdate(ModifierLinkProduct data) async {
    final db = await instance.database;
    return await db.rawUpdate('UPDATE $tableModifierLinkProduct SET sync_status = ?, updated_at = ? WHERE product_sqlite_id = ? AND mod_group_id = ?',
        [data.sync_status, data.updated_at, data.product_sqlite_id, data.mod_group_id]);
  }

  /*
  update sync category
*/
  Future<int> updateSyncCategory(Categories data) async {
    final db = await instance.database;
    return await db.rawUpdate('UPDATE $tableCategories SET category_id = ?, sync_status = ?, updated_at = ? WHERE category_sqlite_id = ?',
        [data.category_id, data.sync_status, data.updated_at, data.category_sqlite_id]);
  }

/*
  update category
*/
  Future<int> updateCategory(Categories data) async {
    final db = await instance.database;
    return await db.rawUpdate('UPDATE $tableCategories SET name = ?, color = ?, sync_status = ?, updated_at = ? WHERE category_sqlite_id = ?',
        [data.name, data.color, data.sync_status, data.updated_at, data.category_sqlite_id]);
  }

/*
  update sync product
*/
  Future<int> updateSyncProduct(Product data) async {
    final db = await instance.database;
    return await db.rawUpdate('UPDATE $tableProduct SET product_id = ?, sync_status = ?, updated_at = ? WHERE product_sqlite_id = ?',
        [data.product_id, data.sync_status, data.updated_at, data.product_sqlite_id]);
  }

  /*
  update product
*/
  Future<int> updateProduct(Product data) async {
    final db = await instance.database;
    return await db.rawUpdate(
        'UPDATE $tableProduct SET category_sqlite_id = ?, category_id = ?, name = ?, price = ?, description = ?, SKU = ?, '
        'image = ?, has_variant = ?, stock_type = ?, stock_quantity = ?, available = ?, graphic_type = ?, color = ?, '
        'daily_limit_amount = ?, daily_limit = ?, sync_status = ?, unit = ?, per_quantity_unit = ?, sequence_number = ?, updated_at = ?, soft_delete = ? WHERE product_id = ?',
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
          data.unit,
          data.per_quantity_unit,
          data.sequence_number,
          data.updated_at,
          data.soft_delete,
          data.product_id,
        ]);
  }

/*
  update product available
*/
  Future<int> updateProductAvailability(Product data) async {
    final db = await instance.database;
    return await db.rawUpdate('UPDATE $tableProduct SET available = ?, sync_status = ?, updated_at = ? WHERE product_sqlite_id = ?',
        [data.available, data.sync_status, data.updated_at, data.product_sqlite_id]);
  }

/*
  update modifier link product
*/
  Future<int> updateModifierLinkProduct(ModifierLinkProduct data) async {
    final db = await instance.database;
    return await db.rawUpdate(
        'UPDATE $tableModifierLinkProduct SET mod_group_id = ?, product_id = ?, product_sqlite_id = ?, sync_status = ?, updated_at = ?, soft_delete = ? WHERE modifier_link_product_id = ? ',
        [data.mod_group_id, data.product_id, data.product_sqlite_id, data.sync_status, data.updated_at, data.soft_delete, data.modifier_link_product_id]);
  }

/*
  update variant group
*/
  Future<int> updateVariantGroup(VariantGroup data) async {
    final db = await instance.database;
    return await db.rawUpdate(
        'UPDATE $tableVariantGroup SET product_id = ?, product_sqlite_id = ?, name = ?, sync_status = ?, updated_at = ?, soft_delete = ? WHERE variant_group_id = ? ',
        [data.product_id, data.product_sqlite_id, data.name, data.sync_status, data.updated_at, data.soft_delete, data.variant_group_id]);
  }

/*
  update variant item
*/
  Future<int> updateVariantItem(VariantItem data) async {
    final db = await instance.database;
    return await db.rawUpdate(
        'UPDATE $tableVariantItem SET variant_group_id = ?, variant_group_sqlite_id = ?, name = ?, sync_status = ?, updated_at = ? WHERE variant_item_id = ? ',
        [data.variant_group_id, data.variant_group_sqlite_id, data.name, data.sync_status, data.updated_at, data.variant_item_id]);
  }

/*
  update product variant
*/
  Future<int> updateProductVariant(ProductVariant data) async {
    final db = await instance.database;
    return await db.rawUpdate(
        'UPDATE $tableProductVariant SET product_sqlite_id = ?, product_id = ?, variant_name = ?, SKU = ?, price = ?, '
        'stock_type = ?, daily_limit = ?, daily_limit_amount = ?, stock_quantity = ?, sync_status = ?, updated_at = ?, soft_delete = ? WHERE product_variant_id = ? ',
        [
          data.product_sqlite_id,
          data.product_id,
          data.variant_name,
          data.SKU,
          data.price,
          data.stock_type,
          data.daily_limit,
          data.daily_limit_amount,
          data.stock_quantity,
          data.sync_status,
          data.updated_at,
          data.soft_delete,
          data.product_variant_id
        ]);
  }

/*
  update product variant detail
*/
  Future<int> updateProductVariantDetail(ProductVariantDetail data) async {
    final db = await instance.database;
    return await db.rawUpdate(
        'UPDATE $tableProductVariantDetail SET product_variant_id = ?, product_variant_sqlite_id = ?, variant_item_sqlite_id = ?, variant_item_id = ?, '
        'sync_status = ?, updated_at = ?, soft_delete = ? WHERE product_variant_detail_id = ?',
        [
          data.product_variant_id,
          data.product_variant_sqlite_id,
          data.variant_item_sqlite_id,
          data.variant_item_id,
          data.sync_status,
          data.updated_at,
          data.soft_delete,
          data.product_variant_detail_id
        ]);
  }

/*
  update branch link product
*/
  Future<int> updateBranchLinkProduct(BranchLinkProduct data) async {
    final db = await instance.database;
    return await db.rawUpdate(
        'UPDATE $tableBranchLinkProduct '
        'SET product_sqlite_id = ?, product_id = ?, has_variant = ?, product_variant_sqlite_id = ?, product_variant_id = ?, '
        'b_SKU = ?, price = ?, stock_type = ?, daily_limit = ?, daily_limit_amount = ?, stock_quantity = ?, sync_status = ?, updated_at = ?, soft_delete = ? '
        'WHERE branch_link_product_id = ? ',
        [
          data.product_sqlite_id,
          data.product_id,
          data.has_variant,
          data.product_variant_sqlite_id,
          data.product_variant_id,
          data.b_SKU,
          data.price,
          data.stock_type,
          data.daily_limit,
          data.daily_limit_amount,
          data.stock_quantity,
          data.sync_status,
          data.updated_at,
          data.soft_delete,
          data.branch_link_product_id
        ]);
  }

/*
  update modifier group
*/
  Future<int> updateModifierGroup(ModifierGroup data) async {
    final db = await instance.database;
    return await db.rawUpdate('UPDATE $tableModifierGroup SET company_id = ?, name = ?, dining_id = ?, compulsory = ?, sequence_number = ?, updated_at = ?, soft_delete = ? WHERE mod_group_id = ? ',
        [data.company_id, data.name, data.dining_id, data.compulsory, data.sequence_number, data.updated_at, data.soft_delete, data.mod_group_id]);
  }

  /*
  update modifier group
*/
  Future<int> updateModifierItem(ModifierItem data) async {
    final db = await instance.database;
    return await db.rawUpdate(
        'UPDATE $tableModifierItem SET mod_group_id = ?, name = ?, price = ?, sequence = ?, quantity = ?, updated_at = ?, soft_delete = ? WHERE mod_item_id = ? ',
        [data.mod_group_id, data.name, data.price, data.sequence, data.quantity, data.updated_at, data.soft_delete, data.mod_item_id]);
  }

/*
  update branch link modifier
*/
  Future<int> updateBranchLinkModifier(BranchLinkModifier data) async {
    final db = await instance.database;
    return await db.rawUpdate(
        'UPDATE $tableBranchLinkModifier SET mod_group_id = ?, mod_item_id = ?, name = ?, price = ?, sequence = ?, status = ?, updated_at = ?, soft_delete = ? WHERE branch_link_modifier_id = ? ',
        [data.mod_group_id, data.mod_item_id, data.name, data.price, data.sequence, data.status, data.updated_at, data.soft_delete, data.branch_link_modifier_id]);
  }

/*
  update user
*/
  Future<int> updateUser(User data) async {
    final db = await instance.database;
    return await db.rawUpdate('UPDATE $tableUser SET name = ?, email = ?, phone = ?, role = ?, pos_pin = ?, edit_price_without_pin = ?, refund_permission = ?, '
        'cash_drawer_permission = ?, settlement_permission = ?, report_permission = ?, status = ?, updated_at = ?, soft_delete = ? WHERE user_id = ? ',
        [data.name, data.email, data.phone, data.role, data.pos_pin, data.edit_price_without_pin, data.refund_permission, data.cash_drawer_permission,
          data.settlement_permission, data.report_permission, data.status, data.updated_at, data.soft_delete, data.user_id]);
  }

/*
  update branch link user
*/
  Future<int> updateBranchLinkUser(BranchLinkUser data) async {
    final db = await instance.database;
    return await db.rawUpdate('UPDATE $tableBranchLinkUser SET branch_id = ? , user_id = ?, updated_at = ?, soft_delete = ? WHERE branch_link_user_id = ? ',
        [data.branch_id, data.user_id, data.updated_at, data.soft_delete, data.branch_link_user_id]);
  }

/*
  update customer
*/
  Future<int> updateCustomer(Customer data) async {
    final db = await instance.database;
    return await db.rawUpdate(
        'UPDATE $tableCustomer SET company_id = ?, name = ?, phone = ?, email = ?, address = ?, note = ?, updated_at = ?, soft_delete = ? WHERE customer_id = ?',
        [data.company_id, data.name, data.phone, data.email, data.address, data.note, data.updated_at, data.soft_delete, data.customer_id]);
  }

/*
  update Payment link company
*/
  Future<int> updatePaymentLinkCompany(PaymentLinkCompany data) async {
    final db = await instance.database;
    return await db.rawUpdate(
        'UPDATE $tablePaymentLinkCompany SET payment_type_id = ?, company_id = ?, name = ?, allow_image = ?, image_name = ?, updated_at = ?, soft_delete = ? WHERE payment_link_company_id = ?',
        [data.payment_type_id, data.company_id, data.name, data.allow_image, data.image_name, data.updated_at, data.soft_delete, data.payment_link_company_id]);
  }

/*
  update tax
*/
  Future<int> updateTax(Tax data) async {
    final db = await instance.database;
    return await db.rawUpdate('UPDATE $tableTax SET company_id = ?, name = ?, tax_rate = ?, updated_at = ?, soft_delete = ? WHERE tax_id = ?',
        [data.company_id, data.name, data.tax_rate, data.updated_at, data.soft_delete, data.tax_id]);
  }

/*
  update branch link tax
*/
  Future<int> updateBranchLinkTax(BranchLinkTax data) async {
    final db = await instance.database;
    return await db.rawUpdate('UPDATE $tableBranchLinkTax SET branch_id = ?, tax_id = ?, updated_at = ?, soft_delete = ? WHERE branch_link_tax_id = ?',
        [data.branch_id, data.tax_id, data.updated_at, data.soft_delete, data.branch_link_tax_id]);
  }

/*
  update tax link dining
*/
  Future<int> updateTaxLinkDining(TaxLinkDining data) async {
    final db = await instance.database;
    return await db.rawUpdate('UPDATE $tableTaxLinkDining SET tax_id = ?, dining_id = ?, updated_at = ?, soft_delete = ? WHERE tax_link_dining_id = ?',
        [data.tax_id, data.dining_id, data.updated_at, data.soft_delete, data.tax_link_dining_id]);
  }

/*
  update dining option
*/
  Future<int> updateDiningOption(DiningOption data) async {
    final db = await instance.database;
    return await db
        .rawUpdate('UPDATE $tableDiningOption SET name = ?, updated_at = ?, soft_delete = ? WHERE dining_id = ?', [data.name, data.updated_at, data.soft_delete, data.dining_id]);
  }

/*
  update branch link dining
*/
  Future<int> updateBranchLikDining(BranchLinkDining data) async {
    final db = await instance.database;
    return await db.rawUpdate(
        'UPDATE $tableBranchLinkDining SET branch_id = ?, dining_id = ?, is_default = ?, sequence = ?, updated_at = ?, soft_delete = ? WHERE branch_link_dining_id = ?',
        [data.branch_id, data.dining_id, data.is_default, data.sequence, data.updated_at, data.soft_delete, data.branch_link_dining_id]);
  }

/*
  update promotion
*/
  Future<int> updatePromotion(Promotion data) async {
    final db = await instance.database;
    return await db.rawUpdate(
        'UPDATE $tablePromotion SET name = ?, amount = ?, specific_category = ?, category_id = ?, type = ?, '
        'auto_apply = ?, all_day = ?, all_time = ?, sdate = ?, edate = ?, stime = ?, etime = ?, updated_at = ?, soft_delete = ? WHERE promotion_id = ? ',
        [
          data.name,
          data.amount,
          data.specific_category,
          data.category_id,
          data.type,
          data.auto_apply,
          data.all_day,
          data.all_time,
          data.sdate,
          data.edate,
          data.stime,
          data.etime,
          data.updated_at,
          data.soft_delete,
          data.promotion_id
        ]);
  }

/*
  update promotion
*/
  Future<int> updateBranchLinkPromotion(BranchLinkPromotion data) async {
    final db = await instance.database;
    return await db.rawUpdate('UPDATE $tableBranchLinkPromotion SET promotion_id = ?, updated_at = ?, soft_delete = ? WHERE branch_link_promotion_id = ? ',
        [data.promotion_id, data.updated_at, data.soft_delete, data.branch_link_promotion_id]);
  }

/*
  updateBranch
*/
  Future<int> updateBranch(Branch data) async {
    final db = await instance.database;
    return await db.rawUpdate('UPDATE $tableBranch SET name = ?, address = ?, phone = ?, email = ?, qr_order_status = ?, sub_pos_status = ?, attendance_status = ? WHERE branchID = ? ',
        [data.name, data.address, data.phone, data.email, data.qr_order_status, data.sub_pos_status, data.attendance_status, data.branchID]);
  }

/*
  update printer link category soft delete
*/
  Future<int> updatePrinterLinkCategorySoftDelete(PrinterLinkCategory data) async {
    final db = await instance.database;
    return await db.rawUpdate('UPDATE $tablePrinterLinkCategory SET soft_delete = ? WHERE printer_link_category_key = ? ',
        [data.soft_delete, data.printer_link_category_key]);

  }

/*
  update table Use
*/
  Future<int> updateTableUse(TableUse data) async {
    final db = await instance.database;
    return await db.rawUpdate('UPDATE $tableTableUse SET branch_id = ?, order_cache_key = ?, card_color = ?, '
        'status = ?, updated_at = ?, soft_delete = ? WHERE table_use_key = ? ',
        [
          data.branch_id,
          data.order_cache_key,
          data.card_color,
          data.status,
          data.updated_at,
          data.soft_delete,
          data.table_use_key]);

  }

/*
  update table Use detail
*/
  Future<int> updateTableUseDetailFromCloud(TableUseDetail data) async {
    final db = await instance.database;
    return await db.rawUpdate('UPDATE $tableTableUseDetail SET status = ?, updated_at = ?, soft_delete = ? WHERE table_use_detail_key = ? ',
        [
          data.status,
          data.updated_at,
          data.soft_delete,
          data.table_use_detail_key]);

  }

/*
  update App color
*/
  Future<int> updateAppColor(AppColors data) async {
    final db = await instance.database;
    return await db.rawUpdate('UPDATE $tableAppColors SET background_color = ?, button_color = ?, icon_color = ?, updated_at = ? WHERE app_color_sqlite_id = ?',
        [data.background_color, data.button_color, data.icon_color, data.updated_at, data.app_color_sqlite_id]);
  }

/*
  update App Setting
*/
  Future<int> updateAppSettings(AppSetting data) async {
    final db = await instance.database;
    return await db.rawUpdate('UPDATE $tableAppSetting SET open_cash_drawer = ?, show_second_display = ?, table_order = ?, sync_status = ?, updated_at = ?',
        [data.open_cash_drawer, data.show_second_display, data.table_order, 2, data.updated_at]);
  }

/*
  update first sync App Setting
*/
  Future<int> updateFirstSyncAppSettings(AppSetting data) async {
    final db = await instance.database;
    return await db.rawUpdate('UPDATE $tableAppSetting SET branch_id = ?, created_at = ?, sync_status = ? WHERE app_setting_sqlite_id = ?',
        [data.branch_id, data.created_at, 0, data.app_setting_sqlite_id]);
  }

  /*
  update Receipt Setting
*/
  Future<int> updateReceiptSettings(AppSetting data) async {
    final db = await instance.database;
    return await db.rawUpdate('UPDATE $tableAppSetting SET print_checklist = ?, print_receipt = ?, enable_numbering = ?, starting_number = ?, sync_status = ?, updated_at = ?',
        [data.print_checklist, data.print_receipt, data.enable_numbering, data.starting_number, 2, data.updated_at]);
  }

/*
  update direct payment Setting
*/
  Future<int> updateDirectPaymentSettings(AppSetting data) async {
    final db = await instance.database;
    return await db.rawUpdate('UPDATE $tableAppSetting SET direct_payment = ?, sync_status = ?, updated_at = ?', [data.direct_payment, 2, data.updated_at]);
  }

/*
  update show sku Setting
*/
  Future<int> updateShowSKUSettings(AppSetting data) async {
    final db = await instance.database;
    return await db.rawUpdate('UPDATE $tableAppSetting SET show_sku = ?, sync_status = ?, updated_at = ?', [data.show_sku, 2, data.updated_at]);
  }

/*
  update auto accept qr order Setting
*/
  Future<int> updateQrOrderAutoAcceptSetting(AppSetting data) async {
    final db = await instance.database;
    return await db.rawUpdate('UPDATE $tableAppSetting SET qr_order_auto_accept = ?, sync_status = ?, updated_at = ?', [data.qr_order_auto_accept, 2, data.updated_at]);
  }

/*
  update Pos Table sync from cloud
*/
  Future<int> updatePosTableSyncRecord(PosTable data) async {
    final db = await instance.database;
    return await db.rawUpdate('UPDATE $tablePosTable SET table_url = ?, number = ?, seats = ?, updated_at = ?, soft_delete = ? WHERE table_id = ?',
        [data.table_url, data.number, data.seats, data.updated_at, data.soft_delete, data.table_id]);
  }

  /*
  update sync pos table
*/
  Future<int> updateSyncPosTable(PosTable data) async {
    final db = await instance.database;
    return await db.rawUpdate('UPDATE $tablePosTable SET table_id = ?, sync_status = ?, updated_at = ? WHERE table_sqlite_id = ?',
        [data.table_id, data.sync_status, data.updated_at, data.table_sqlite_id]);
  }

/*
  update Pos Table
*/
  Future<int> updatePosTable(PosTable data) async {
    final db = await instance.database;
    return await db.rawUpdate('UPDATE $tablePosTable SET number = ?, seats = ?, sync_status = ?, updated_at = ? WHERE table_sqlite_id = ?',
        [data.number, data.seats, data.sync_status, data.updated_at, data.table_sqlite_id]);
  }

/*
  update Pos Table status
*/
  Future<int> updatePosTableStatus(PosTable data) async {
    final db = await instance.database;
    return await db
        .rawUpdate('UPDATE $tablePosTable SET sync_status = ?, status = ?, updated_at = ? WHER\E table_sqlite_id = ?', [2, data.status, data.updated_at, data.table_sqlite_id]);
  }

/*
  update Pos Table status
*/
  Future<int> updateCartPosTableStatus(PosTable data) async {
    final db = await instance.database;
    return await db.rawUpdate('UPDATE $tablePosTable SET sync_status = ?, table_use_detail_key = ?, table_use_key = ?, status = ?, updated_at = ? WHERE table_sqlite_id = ?',
        [2, data.table_use_detail_key, data.table_use_key, data.status, data.updated_at, data.table_sqlite_id]);
  }

/*
  update Pos Table table use detail
*/
  Future<int> removePosTableTableUseDetailKey(PosTable data) async {
    final db = await instance.database;
    return await db.rawUpdate('UPDATE $tablePosTable SET sync_status = ?, table_use_detail_key = ?, table_use_key = ?, updated_at = ? WHERE table_sqlite_id = ?',
        [2, data.table_use_detail_key, data.table_use_key, data.updated_at, data.table_sqlite_id]);
  }

/*
  update table use detail
*/
  Future<int> updateTableUseDetail(TableUseDetail data) async {
    final db = await instance.database;
    return await db.rawUpdate('UPDATE $tableTableUseDetail SET table_sqlite_id = ?, table_id = ?, sync_status = ?, updated_at = ? WHERE table_use_detail_key = ?',
        [data.table_sqlite_id, data.table_id, data.sync_status, data.updated_at, data.table_use_detail_key]);
  }

/*
  update order cache
*/
  Future<int> updateOrderCacheTableUseId(OrderCache data) async {
    final db = await instance.database;
    return await db.rawUpdate('UPDATE $tableOrderCache SET table_use_sqlite_id = ?, table_use_key = ?,  sync_status = ?, updated_at = ? WHERE order_cache_sqlite_id = ?',
        [data.table_use_sqlite_id, data.table_use_key, data.sync_status, data.updated_at, data.order_cache_sqlite_id]);
  }

/*
  update printer
*/
  Future<int> updatePrinter(Printer data) async {
    final db = await instance.database;
    return await db.rawUpdate(
        'UPDATE $tablePrinter SET printer_label = ?, paper_size = ?, type = ?, value = ?, printer_status = ?, is_counter = ?, is_label = ?, sync_status = ?, updated_at = ? WHERE printer_sqlite_id = ?',
        [data.printer_label, data.paper_size, data.type, data.value, data.printer_status, data.is_counter, data.is_label, data.sync_status, data.updated_at, data.printer_sqlite_id]);
  }

/*
  update receipt status
*/
  Future<int> updateReceiptStatus(Receipt data) async {
    final db = await instance.database;
    return await db.rawUpdate('UPDATE $tableReceipt SET status = ?, sync_status = ?, updated_at = ? WHERE receipt_sqlite_id = ?',
        [data.status, data.sync_status, data.updated_at, data.receipt_sqlite_id]);
  }

/*
  update cash record settlement
*/
  Future<int> updateCashRecord(CashRecord data) async {
    final db = await instance.database;
    return await db.rawUpdate('UPDATE $tableCashRecord SET settlement_date = ?, settlement_key = ?, sync_status = ?, updated_at = ? WHERE cash_record_sqlite_id = ?',
        [data.settlement_date, data.settlement_key, data.sync_status, data.updated_at, data.cash_record_sqlite_id]);
  }

/*
  update order payment split
*/
  Future<int> updateOrderPaymentSplit(Order data) async {
    final db = await instance.database;
    return await db.rawUpdate('UPDATE $tableOrder SET payment_received = ?, payment_change = ?, payment_split = ?, sync_status = ?,  updated_at = ?, soft_delete = ? WHERE order_sqlite_id = ?',
        [data.payment_received, data.payment_change, data.payment_split, data.sync_status, data.updated_at, data.soft_delete, data.order_sqlite_id]);
  }

/*
  update order payment status
*/
  Future<int> updateOrderPaymentStatus(Order data) async {
    final db = await instance.database;
    return await db.rawUpdate('UPDATE $tableOrder SET payment_status = ?, sync_status = ?,  updated_at = ?, soft_delete = ? WHERE order_sqlite_id = ?',
        [1, data.sync_status, data.updated_at, data.soft_delete, data.order_sqlite_id]);
  }

/*
  update order payment status (refund)
*/
  Future<int> updateOrderPaymentRefundStatus(Order data) async {
    final db = await instance.database;
    return await db.rawUpdate('UPDATE $tableOrder SET payment_status = ?, refund_sqlite_id = ?, refund_key = ?, sync_status = ?,  updated_at = ? WHERE order_sqlite_id = ?',
        [2, data.refund_sqlite_id, data.refund_key, data.sync_status, data.updated_at, data.order_sqlite_id]);
  }

/*
  update order cache order id
*/
  Future<int> updateOrderCacheOrderId(OrderCache data) async {
    final db = await instance.database;
    return await db.rawUpdate('UPDATE $tableOrderCache SET order_sqlite_id = ?, order_key = ?, sync_status = ?, updated_at = ? WHERE order_cache_sqlite_id = ?',
        [data.order_sqlite_id, data.order_key, data.sync_status, data.updated_at, data.order_cache_sqlite_id]);
  }

/*
  update order cache subtotal
*/
  Future<int> updateOrderCacheSubtotal(OrderCache data) async {
    final db = await instance.database;
    return await db.rawUpdate('UPDATE $tableOrderCache SET sync_status = ?, total_amount = ?, updated_at = ? WHERE order_cache_sqlite_id = ?',
        [data.sync_status, data.total_amount, data.updated_at, data.order_cache_sqlite_id]);
  }

/*
  update branch notification token
*/
  Future<int> updateBranchNotificationToken(Branch data) async {
    final db = await instance.database;
    return await db.rawUpdate('UPDATE $tableBranch SET notification_token = ? WHERE branchID = ?', [data.notification_token, data.branchID]);
  }

/*
  update branch link product daily limit amount
*/
  Future<int> updateBranchLinkProductDailyLimit(BranchLinkProduct data) async {
    final db = await instance.database;
    return await db.rawUpdate('UPDATE $tableBranchLinkProduct SET updated_at = ?, sync_status = ?, daily_limit = ? WHERE branch_link_product_sqlite_id = ?',
        [data.updated_at, data.sync_status, data.daily_limit, data.branch_link_product_sqlite_id]);
  }

/*
  update branch link product stock
*/
  Future<int> updateBranchLinkProductStock(BranchLinkProduct data) async {
    final db = await instance.database;
    return await db.rawUpdate('UPDATE $tableBranchLinkProduct SET updated_at = ?, sync_status = ?, stock_quantity = ? WHERE branch_link_product_sqlite_id = ?',
        [data.updated_at, data.sync_status, data.stock_quantity, data.branch_link_product_sqlite_id]);
  }

/*
  update order detail status
*/
  Future<int> updateOrderDetailStatus(OrderDetail data) async {
    final db = await instance.database;
    return await db.rawUpdate('UPDATE $tableOrderDetail SET updated_at = ?, sync_status = ?, status = ?, cancel_by = ?, cancel_by_user_id = ? WHERE order_detail_sqlite_id = ?',
        [data.updated_at, data.sync_status, data.status, data.cancel_by, data.cancel_by_user_id, data.order_detail_sqlite_id]);
  }

/*
  update qr order cache
*/
  Future<int> updateQrOrderCache(OrderCache data) async {
    final db = await instance.database;
    return await db.rawUpdate(
        'UPDATE $tableOrderCache SET table_use_sqlite_id = ?, table_use_key = ?, batch_id = ?, total_amount = ?, '
        'order_by = ?, order_by_user_id = ?, accepted = ?, sync_status = ?, updated_at = ? WHERE order_cache_sqlite_id = ?',
        [
          data.table_use_sqlite_id,
          data.table_use_key,
          data.batch_id,
          data.total_amount,
          data.order_by,
          data.order_by_user_id,
          data.accepted,
          data.sync_status,
          data.updated_at,
          data.order_cache_sqlite_id
        ]);
  }

/*
  update order detail quantity
*/
  Future<int> updateOrderDetailQuantity(OrderDetail data) async {
    final db = await instance.database;
    return await db.rawUpdate('UPDATE $tableOrderDetail SET updated_at = ?, sync_status = ?, quantity = ? WHERE order_detail_sqlite_id = ?',
        [data.updated_at, data.sync_status, data.quantity, data.order_detail_sqlite_id]);
  }

/*
  update order detail unit price
*/
  Future<int> updateOrderDetailUnitPrice(OrderDetail data) async {
    final db = await instance.database;
    return await db.rawUpdate('UPDATE $tableOrderDetail SET updated_at = ?, sync_status = ?, edited_by = ?, edited_by_user_id = ?, price = ? WHERE order_detail_sqlite_id = ?',
        [data.updated_at, data.sync_status, data.edited_by, data.edited_by_user_id, data.price, data.order_detail_sqlite_id]);
  }

/*
  updated order refund local id (sync from cloud)
*/
  Future<int> updateOrderRefundSqliteId(Order data) async {
    final db = await instance.database;
    return await db.rawUpdate('UPDATE $tableOrder SET refund_sqlite_id = ? WHERE order_sqlite_id = ?', [data.refund_sqlite_id, data.order_sqlite_id]);
  }

/*
  update receipt layout
*/
  Future<int> updateReceiptLayout(Receipt data) async {
    final db = await instance.database;
    return await db.rawUpdate(
        'UPDATE $tableReceipt SET header_image = ?, header_image_status = ?, header_text = ?, header_text_status = ?, '
        'header_font_size = ?, show_address = ?, show_email = ?, receipt_email = ?, '
        'footer_image = ?, footer_image_status = ?, footer_text = ?, footer_text_status = ?, promotion_detail_status = ?, sync_status = ?, updated_at = ? WHERE receipt_sqlite_id = ?',
        [
          data.header_image,
          data.header_image_status,
          data.header_text,
          data.header_text_status,
          data.header_font_size,
          data.show_address,
          data.show_email,
          data.receipt_email,
          data.footer_image,
          data.footer_image_status,
          data.footer_text,
          data.footer_text_status,
          data.promotion_detail_status,
          data.sync_status,
          data.updated_at,
          data.receipt_sqlite_id
        ]);
  }

/*
  update order payment method
*/
  Future<int> updatePaymentMethod(Order data) async {
    final db = await instance.database;
    return await db.rawUpdate("UPDATE $tableOrder SET updated_at = ?, sync_status = ?, payment_link_company_id = ? WHERE order_key = ?", [
      data.updated_at,
      data.sync_status,
      data.payment_link_company_id,
      data.order_key,
    ]);
  }

/*
  update cash record payment type
*/
  Future<int> updatePaymentTypeId(CashRecord data) async {
    final db = await instance.database;
    return await db.rawUpdate("UPDATE $tableCashRecord SET updated_at = ?, sync_status = ?, payment_type_id = ? WHERE cash_record_key = ?", [
      data.updated_at,
      data.sync_status,
      data.payment_type_id,
      data.cash_record_key,
    ]);
  }

/*
  update checklist layout
*/
  Future<int> updateChecklist(Checklist data) async {
    final db = await instance.database;
    return await db.rawUpdate("UPDATE $tableChecklist SET updated_at = ?, sync_status = ?, product_name_font_size = ?, other_font_size = ? , check_list_show_price = ? , check_list_show_separator = ? WHERE checklist_sqlite_id = ?",
        [data.updated_at, data.sync_status, data.product_name_font_size, data.other_font_size, data.check_list_show_price, data.check_list_show_separator, data.checklist_sqlite_id]);
  }

/*
  update kitchen_list layout
*/
  Future<int> updateKitchenList(KitchenList data) async {
    final db = await instance.database;
    return await db.rawUpdate("UPDATE $tableKitchenList SET updated_at = ?, sync_status = ?, kitchen_list_item_separator = ?, print_combine_kitchen_list = ?, "
        "kitchen_list_show_price = ?, product_name_font_size = ?, other_font_size = ? WHERE kitchen_list_sqlite_id = ?",
        [data.updated_at, data.sync_status, data.kitchen_list_item_separator, data.print_combine_kitchen_list, data.kitchen_list_show_price, data.product_name_font_size, data.other_font_size, data.kitchen_list_sqlite_id]);
  }

  /*
    update table position dx, dy by Chuah
  */
  Future<int> updateTablePosition(PosTable data) async {
    final db = await instance.database;
    return await db.rawUpdate("UPDATE $tablePosTable SET updated_at = ?, table_dy = ?, table_dx = ? WHERE table_sqlite_id = ?", [
      data.updated_at,
      data.dy,
      data.dx,
      data.table_sqlite_id,
    ]);
  }

/*
  update second screen
*/
  Future<int> updateSecondScreen(SecondScreen data) async {
    final db = await instance.database;
    return await db.rawUpdate("UPDATE $tableSecondScreen SET name = ?, sequence_number = ?, soft_delete = ? WHERE id = ? ",
        [
          data.name,
          data.sequence_number,
          data.soft_delete,
          data.second_screen_id
        ]
    );
  }

/*
  reset table
*/
  Future<int> resetPosTable(PosTable data) async {
    final db = await instance.database;
    return await db.rawUpdate('UPDATE $tablePosTable SET sync_status = ?, status = ?, table_use_detail_key = ?, table_use_key = ?, updated_at = ? '
        'WHERE table_sqlite_id = ?',
        [2, data.status, data.table_use_detail_key, data.table_use_key, data.updated_at, data.table_sqlite_id]);
  }


/*
  ------------------unique key part----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
*/

/*
  update checklist unique key
*/
  Future<int> updateChecklistUniqueKey(Checklist data) async {
    final db = await instance.database;
    return await db.rawUpdate('UPDATE $tableChecklist SET checklist_key = ?, sync_status = ?, updated_at = ? WHERE checklist_sqlite_id = ?', [
      data.checklist_key,
      data.sync_status,
      data.updated_at,
      data.checklist_sqlite_id,
    ]);
  }

/*
  update attendance unique key
*/
  Future<int> updateAttendanceUniqueKey(Attendance data) async {
    final db = await instance.database;
    return await db.rawUpdate('UPDATE $tableAttendance SET attendance_key = ?, sync_status = ?, updated_at = ? WHERE attendance_sqlite_id = ?', [
      data.attendance_key,
      data.sync_status,
      data.updated_at,
      data.attendance_sqlite_id,
    ]);
  }

/*
  update attendance layout
*/
  Future<int> updateAttendance(Attendance data) async {
    final db = await instance.database;
    return await db.rawUpdate("UPDATE $tableAttendance SET updated_at = ?, sync_status = ?, clock_out_at = ?, duration = ? WHERE user_id = ? AND clock_out_at = ?",
        [data.updated_at, data.sync_status, data.clock_out_at, data.duration, data.user_id, '']);
  }

/*
  update kitchen list unique key
*/
  Future<int> updateKitchenListUniqueKey(KitchenList data) async {
    final db = await instance.database;
    return await db.rawUpdate('UPDATE $tableKitchenList SET kitchen_list_key = ?, sync_status = ?, updated_at = ? WHERE kitchen_list_sqlite_id = ?', [
      data.kitchen_list_key,
      data.sync_status,
      data.updated_at,
      data.kitchen_list_sqlite_id,
    ]);
  }

/*
  update receipt unique key
*/
  Future<int> updateReceiptUniqueKey(Receipt data) async {
    final db = await instance.database;
    return await db.rawUpdate('UPDATE $tableReceipt SET receipt_key = ?, sync_status = ?, updated_at = ? WHERE receipt_sqlite_id = ?', [
      data.receipt_key,
      data.sync_status,
      data.updated_at,
      data.receipt_sqlite_id,
    ]);
  }

/*
  update printer link category unique key
*/
  Future<int> updatePrinterLinkCategoryUniqueKey(PrinterLinkCategory data) async {
    final db = await instance.database;
    return await db.rawUpdate('UPDATE $tablePrinterLinkCategory SET printer_link_category_key = ?, sync_status = ?, updated_at = ? WHERE printer_link_category_sqlite_id = ?', [
      data.printer_link_category_key,
      data.sync_status,
      data.updated_at,
      data.printer_link_category_sqlite_id,
    ]);
  }

/*
  update printer unique key
*/
  Future<int> updatePrinterUniqueKey(Printer data) async {
    final db = await instance.database;
    return await db.rawUpdate('UPDATE $tablePrinter SET printer_key = ?, sync_status = ?, updated_at = ? WHERE printer_sqlite_id = ?', [
      data.printer_key,
      data.sync_status,
      data.updated_at,
      data.printer_sqlite_id,
    ]);
  }

/*
  update order detail cancel unique key
*/
  Future<int> updateOrderDetailCancelUniqueKey(OrderDetailCancel data) async {
    final db = await instance.database;
    return await db.rawUpdate('UPDATE $tableOrderDetailCancel SET order_detail_cancel_key = ?, sync_status = ?, updated_at = ? WHERE order_detail_cancel_sqlite_id = ?', [
      data.order_detail_cancel_key,
      data.sync_status,
      data.updated_at,
      data.order_detail_cancel_sqlite_id,
    ]);
  }

/*
  update settlement link payment unique key
*/
  Future<int> updateSettlementLinkPaymentUniqueKey(SettlementLinkPayment data) async {
    final db = await instance.database;
    return await db
        .rawUpdate('UPDATE $tableSettlementLinkPayment SET settlement_link_payment_key = ?, sync_status = ?, updated_at = ? WHERE settlement_link_payment_sqlite_id = ?', [
      data.settlement_link_payment_key,
      data.sync_status,
      data.updated_at,
      data.settlement_link_payment_sqlite_id,
    ]);
  }

/*
  update settlement unique key
*/
  Future<int> updateSettlementUniqueKey(Settlement data) async {
    final db = await instance.database;
    return await db.rawUpdate('UPDATE $tableSettlement SET settlement_key = ?, sync_status = ?, updated_at = ? WHERE settlement_sqlite_id = ?', [
      data.settlement_key,
      data.sync_status,
      data.updated_at,
      data.settlement_sqlite_id,
    ]);
  }

/*
  update refund unique key
*/
  Future<int> updateRefundUniqueKey(Refund data) async {
    final db = await instance.database;
    return await db.rawUpdate('UPDATE $tableRefund SET refund_key = ?, updated_at = ? WHERE refund_sqlite_id = ?', [
      data.refund_key,
      data.updated_at,
      data.refund_sqlite_id,
    ]);
  }

/*
  update cash record unique key
*/
  Future<int> updateCashRecordUniqueKey(CashRecord data) async {
    final db = await instance.database;
    return await db.rawUpdate('UPDATE $tableCashRecord SET cash_record_key = ?, updated_at = ? WHERE cash_record_sqlite_id = ?', [
      data.cash_record_key,
      data.updated_at,
      data.cash_record_sqlite_id,
    ]);
  }

/*
  update order promotion detail unique key
*/
  Future<int> updateOrderPromotionDetailUniqueKey(OrderPromotionDetail data) async {
    final db = await instance.database;
    return await db.rawUpdate('UPDATE $tableOrderPromotionDetail SET order_promotion_detail_key = ?, sync_status = ?, updated_at = ? WHERE order_promotion_detail_sqlite_id = ?', [
      data.order_promotion_detail_key,
      data.sync_status,
      data.updated_at,
      data.order_promotion_detail_sqlite_id,
    ]);
  }

/*
  update order tax detail unique key
*/
  Future<int> updateOrderTaxDetailUniqueKey(OrderTaxDetail data) async {
    final db = await instance.database;
    return await db.rawUpdate('UPDATE $tableOrderTaxDetail SET order_tax_detail_key = ?, sync_status = ?, updated_at = ? WHERE order_tax_detail_sqlite_id = ?', [
      data.order_tax_detail_key,
      data.sync_status,
      data.updated_at,
      data.order_tax_detail_sqlite_id,
    ]);
  }

/*
  update order unique key
*/
  Future<int> updateOrderUniqueKey(Order data) async {
    final db = await instance.database;
    return await db.rawUpdate('UPDATE $tableOrder SET order_key = ?, sync_status = ?, updated_at = ? WHERE order_sqlite_id = ?', [
      data.order_key,
      data.sync_status,
      data.updated_at,
      data.order_sqlite_id,
    ]);
  }

/*
  update order cache unique key
*/
  Future<int> updateOrderCacheUniqueKey(OrderCache data) async {
    final db = await instance.database;
    return await db.rawUpdate('UPDATE $tableOrderCache SET order_cache_key = ?, sync_status = ?, updated_at = ? WHERE order_cache_sqlite_id = ?', [
      data.order_cache_key,
      data.sync_status,
      data.updated_at,
      data.order_cache_sqlite_id,
    ]);
  }

/*
  update order detail unique key
*/
  Future<int> updateOrderDetailUniqueKey(OrderDetail data) async {
    final db = await instance.database;
    return await db.rawUpdate('UPDATE $tableOrderDetail SET order_detail_key = ?, sync_status = ?, updated_at = ? WHERE order_detail_sqlite_id = ?', [
      data.order_detail_key,
      data.sync_status,
      data.updated_at,
      data.order_detail_sqlite_id,
    ]);
  }

/*
  update order modifier detail unique key
*/
  Future<int> updateOrderModifierDetailUniqueKey(OrderModifierDetail data) async {
    final db = await instance.database;
    return await db.rawUpdate('UPDATE $tableOrderModifierDetail SET order_modifier_detail_key = ?, sync_status = ?, updated_at = ? WHERE order_modifier_detail_sqlite_id = ?', [
      data.order_modifier_detail_key,
      data.sync_status,
      data.updated_at,
      data.order_modifier_detail_sqlite_id,
    ]);
  }

/*
  update table use unique key
*/
  Future<int> updateTableUseOrderCacheUniqueKey(TableUse data) async {
    final db = await instance.database;
    return await db.rawUpdate('UPDATE $tableTableUse SET order_cache_key = ?, sync_status = ?, updated_at = ? WHERE table_use_sqlite_id = ?', [
      data.order_cache_key,
      data.sync_status,
      data.updated_at,
      data.table_use_sqlite_id,
    ]);
  }

/*
  update table use unique key
*/
  Future<int> updateTableUseUniqueKey(TableUse data) async {
    final db = await instance.database;
    return await db.rawUpdate('UPDATE $tableTableUse SET table_use_key = ?, sync_status = ?, updated_at = ? WHERE table_use_sqlite_id = ?', [
      data.table_use_key,
      data.sync_status,
      data.updated_at,
      data.table_use_sqlite_id,
    ]);
  }

/*
  update table use detail unique key
*/
  Future<int> updateTableUseDetailUniqueKey(TableUseDetail data) async {
    final db = await instance.database;
    return await db.rawUpdate('UPDATE $tableTableUseDetail SET table_use_detail_key = ?, sync_status = ?, updated_at = ? WHERE table_use_detail_sqlite_id = ?', [
      data.table_use_detail_key,
      data.sync_status,
      data.updated_at,
      data.table_use_detail_sqlite_id,
    ]);
  }

/*
  update transfer owner unique key
*/
  Future<int> updateTransferOwnerUniqueKey(TransferOwner data) async {
    final db = await instance.database;
    return await db.rawUpdate('UPDATE $tableTransferOwner SET transfer_owner_key = ?, sync_status = ?, updated_at = ? WHERE transfer_owner_sqlite_id = ?', [
      data.transfer_owner_key,
      data.sync_status,
      data.updated_at,
      data.transfer_owner_sqlite_id,
    ]);
  }

/*
  ------------------Soft delete part----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
*/

  /*
  soft delete branch link product
*/
  Future<int> updateBranchLinkProductEdit(BranchLinkProduct data) async {
    final db = await instance.database;
    return await db.rawUpdate(
        'UPDATE $tableBranchLinkProduct SET sync_status = ?,  updated_at = ?,daily_limit = ?, daily_limit_amount = ?, stock_type = ?, stock_quantity = ?, price = ? WHERE branch_id = ? AND product_sqlite_id = ?',
        [data.sync_status, data.updated_at, data.daily_limit, data.daily_limit_amount, data.stock_type, data.stock_quantity, data.price, data.branch_id, data.product_sqlite_id]);
  }

/*
  soft delete branch link product
*/
  Future<int> updateBranchLinkProductForVariant(BranchLinkProduct data) async {
    final db = await instance.database;
    return await db.rawUpdate(
        'UPDATE $tableBranchLinkProduct SET sync_status = ?, updated_at = ?,daily_limit = ?, daily_limit_amount = ?, stock_type = ?, stock_quantity = ?, price = ? WHERE branch_id = ? AND product_sqlite_id = ? AND product_variant_sqlite_id = ?',
        [
          data.sync_status,
          data.updated_at,
          data.daily_limit,
          data.daily_limit_amount,
          data.stock_type,
          data.stock_quantity,
          data.price,
          data.branch_id,
          data.product_sqlite_id,
          data.product_variant_sqlite_id
        ]);
  }

/*
  soft delete category
*/
  Future<int> deleteCategory(Categories data) async {
    final db = await instance.database;
    return await db
        .rawUpdate('UPDATE $tableCategories SET soft_delete = ?, sync_status = ? WHERE  category_sqlite_id = ?', [data.soft_delete, data.sync_status, data.category_sqlite_id]);
  }

  /*
  soft delete product
*/
  Future<int> deleteProduct(Product data) async {
    final db = await instance.database;
    return await db.rawUpdate('UPDATE $tableProduct SET soft_delete = ?, sync_status = ? WHERE soft_delete = ? AND product_sqlite_id = ?', [
      data.soft_delete,
      data.sync_status,
      '',
      data.product_sqlite_id,
    ]);
  }

  /*
  soft delete modifier link product
*/
  Future<int> deleteModifierLinkProduct(ModifierLinkProduct data) async {
    final db = await instance.database;
    return await db.rawUpdate('UPDATE $tableModifierLinkProduct SET soft_delete = ?, sync_status = ? WHERE soft_delete = ? AND product_sqlite_id = ? AND mod_group_id = ?',
        [data.soft_delete, data.sync_status, '', data.product_sqlite_id, data.mod_group_id]);
  }

  /*
  soft delete variant group
*/
  Future<int> deleteVariantGroup(VariantGroup data) async {
    final db = await instance.database;
    return await db.rawUpdate('UPDATE $tableVariantGroup SET soft_delete = ? WHERE product_sqlite_id = ? AND variant_group_sqlite_id = ?',
        [data.soft_delete, data.product_sqlite_id, data.variant_group_sqlite_id]);
  }

  /*
  soft delete variant group
*/
  Future<int> deleteAllVariantGroup(VariantGroup data) async {
    final db = await instance.database;
    return await db
        .rawUpdate('UPDATE $tableVariantGroup SET sync_status = ?, soft_delete = ? WHERE product_sqlite_id = ?', [data.sync_status, data.soft_delete, data.product_sqlite_id]);
  }

  /*
  soft delete variant item
*/
  Future<int> deleteAllVariantitem(VariantItem data) async {
    final db = await instance.database;
    return await db.rawUpdate(
        'UPDATE $tableVariantItem SET sync_status = ?, soft_delete = ? WHERE variant_group_sqlite_id = ?', [data.sync_status, data.soft_delete, data.variant_group_sqlite_id]);
  }

  /*
  soft delete product variant
*/
  Future<int> deleteAllProductVariant(ProductVariant data) async {
    final db = await instance.database;
    return await db
        .rawUpdate('UPDATE $tableProductVariant SET sync_status = ?, soft_delete = ? WHERE product_sqlite_id = ?', [data.sync_status, data.soft_delete, data.product_sqlite_id]);
  }

  /*
  soft delete product variant detail
*/
  Future<int> deleteAllProductVariantDetail(ProductVariantDetail data) async {
    final db = await instance.database;
    return await db.rawUpdate('UPDATE $tableProductVariantDetail SET sync_status = ?,  soft_delete = ? WHERE product_variant_sqlite_id = ?',
        [data.sync_status, data.soft_delete, data.product_variant_sqlite_id]);
  }

  /*
  soft delete product variant
*/
  Future<int> deleteProductVariant(ProductVariant data) async {
    final db = await instance.database;
    return await db.rawUpdate('UPDATE $tableProductVariant SET soft_delete = ?, sync_status = ? WHERE product_sqlite_id = ? AND product_variant_sqlite_id = ?',
        [data.soft_delete, data.sync_status, data.product_sqlite_id, data.product_variant_sqlite_id]);
  }

  /*
  soft delete product variant detail
*/
  Future<int> deleteProductVariantDetail(ProductVariantDetail data) async {
    final db = await instance.database;
    return await db.rawUpdate('UPDATE $tableProductVariantDetail SET soft_delete = ?, sync_status = ? WHERE product_variant_sqlite_id = ?',
        [data.soft_delete, data.sync_status, data.product_variant_sqlite_id]);
  }

  /*
  soft delete branch link product
*/
  Future<int> deleteBranchLinkProduct(BranchLinkProduct data) async {
    final db = await instance.database;
    return await db.rawUpdate('UPDATE $tableBranchLinkProduct SET soft_delete = ? , sync_status = ? WHERE product_sqlite_id = ? AND product_variant_sqlite_id = ?',
        [data.soft_delete, data.sync_status, data.product_sqlite_id, data.product_variant_sqlite_id]);
  }

  /*
  soft delete branch link product
*/
  Future<int> deleteAllProductBranch(BranchLinkProduct data) async {
    final db = await instance.database;
    return await db.rawUpdate('UPDATE $tableBranchLinkProduct SET sync_status = ?, soft_delete = ? WHERE soft_delete = ? AND product_sqlite_id = ?',
        [data.sync_status, data.soft_delete, '', data.product_sqlite_id]);
  }

  /*
  soft delete variant group
*/
  Future<int> deleteVariantItem(VariantItem data) async {
    final db = await instance.database;
    return await db.rawUpdate(
        'UPDATE $tableVariantItem SET soft_delete = ? , sync_status = ? WHERE variant_group_sqlite_id = ?', [data.soft_delete, data.sync_status, data.variant_group_sqlite_id]);
  }

/*
  Soft-delete Pos Table
*/
  Future<int> deletePosTable(PosTable data) async {
    final db = await instance.database;
    return await db.rawUpdate('UPDATE $tablePosTable SET sync_status = ?, soft_delete = ? WHERE table_sqlite_id = ?', [data.sync_status, data.soft_delete, data.table_sqlite_id]);
  }

/*
  Soft-delete Order cache
*/
  Future<int> cancelOrderCache(OrderCache data) async {
    final db = await instance.database;
    return await db.rawUpdate('UPDATE $tableOrderCache SET sync_status = ?, cancel_by = ?, cancel_by_user_id = ? WHERE order_cache_sqlite_id = ?',
        [data.sync_status, data.cancel_by, data.cancel_by_user_id, data.order_cache_sqlite_id]);
  }

/*
  Soft-delete Order cache(when payment success)
*/
  Future<int> deletePaidOrderCache(OrderCache data) async {
    final db = await instance.database;
    return await db.rawUpdate('UPDATE $tableOrderCache SET soft_delete = ? WHERE order_cache_sqlite_id = ?', [data.soft_delete, data.order_cache_sqlite_id]);
  }

/*
  Soft-delete Order detail
*/
  Future<int> deleteOrderDetail(OrderDetail data) async {
    final db = await instance.database;
    return await db.rawUpdate('UPDATE $tableOrderDetail SET soft_delete = ? WHERE order_detail_sqlite_id = ?', [data.soft_delete, data.order_detail_sqlite_id]);
  }

  /*
  Soft-delete specific Order detail
*/
  Future<int> deleteSpecificOrderDetail(OrderDetail data) async {
    final db = await instance.database;
    return await db.rawUpdate(
        'UPDATE $tableOrderDetail SET soft_delete = ?, sync_status = ?, status = ?, cancel_by = ?, cancel_by_user_id = ? WHERE order_detail_sqlite_id = ? AND branch_link_product_sqlite_id = ?',
        [data.soft_delete, data.sync_status, data.status, data.cancel_by, data.cancel_by_user_id, data.order_detail_sqlite_id, data.branch_link_product_sqlite_id]);
  }

/*
  Soft-delete Order modifier detail
*/
  Future<int> deleteOrderModifierDetail(OrderModifierDetail data) async {
    final db = await instance.database;
    return await db.rawUpdate('UPDATE $tableOrderModifierDetail SET soft_delete = ?, sync_status = ? WHERE order_detail_sqlite_id = ? AND order_modifier_detail_sqlite_id = ?',
        [data.soft_delete, data.sync_status, data.order_detail_sqlite_id, data.order_modifier_detail_sqlite_id]);
  }

/*
  Soft-delete change table table use detail
*/
  Future<int> deleteTableUseDetail(TableUseDetail data) async {
    final db = await instance.database;
    return await db.rawUpdate('UPDATE $tableTableUseDetail SET updated_at = ?, sync_status = ?, status = ? WHERE table_use_sqlite_id = ? AND table_use_detail_sqlite_id = ?',
        [data.updated_at, data.sync_status, data.status, data.table_use_sqlite_id, data.table_use_detail_sqlite_id]);
  }

  /*
  Soft-delete change table table use detail by table id
*/
  Future<int> deleteTableUseDetailByKey(TableUseDetail data) async {
    final db = await instance.database;
    return await db.rawUpdate('UPDATE $tableTableUseDetail SET soft_delete = ?, sync_status = ?, status = ? WHERE table_use_detail_key = ?',
        [data.soft_delete, data.sync_status, data.status, data.table_use_detail_key]);
  }

/*
  Soft-delete table use id
*/
  Future<int> deleteTableUseID(TableUse data) async {
    final db = await instance.database;
    return await db.rawUpdate('UPDATE $tableTableUse SET updated_at = ?, status = ?, sync_status = ? WHERE table_use_sqlite_id = ?',
        [data.updated_at, data.status, data.sync_status, data.table_use_sqlite_id]);
  }

/*
  Soft-delete table use id
*/
  Future<int> deleteTableUseByKey(TableUse data) async {
    final db = await instance.database;
    return await db.rawUpdate(
        'UPDATE $tableTableUse SET soft_delete = ?, status = ?, sync_status = ? WHERE table_use_key = ?', [data.soft_delete, data.status, data.sync_status, data.table_use_key]);
  }

/*
  Soft-delete printer
*/
  Future<int> deletePrinter(Printer data) async {
    final db = await instance.database;
    return await db
        .rawUpdate('UPDATE $tablePrinter SET soft_delete = ?, sync_status = ? WHERE printer_sqlite_id = ?', [data.soft_delete, data.sync_status, data.printer_sqlite_id]);
  }

/*
  Soft-delete printer link category
*/
  Future<int> deletePrinterCategory(PrinterLinkCategory data) async {
    final db = await instance.database;
    return await db.rawUpdate(
        'UPDATE $tablePrinterLinkCategory SET soft_delete = ?, sync_status = ? WHERE printer_sqlite_id = ?', [data.soft_delete, data.sync_status, data.printer_sqlite_id]);
  }

/*
  Soft-delete receipt layout
*/
  Future<int> deleteReceiptLayout(Receipt data) async {
    final db = await instance.database;
    return await db
        .rawUpdate('UPDATE $tableReceipt SET sync_status = ?, soft_delete = ? WHERE receipt_sqlite_id = ?', [data.sync_status, data.soft_delete, data.receipt_sqlite_id]);
  }

/*
  Soft-delete cash record
*/
  Future<int> deleteCashRecord(CashRecord data) async {
    final db = await instance.database;
    return await db.rawUpdate(
        'UPDATE $tableCashRecord SET sync_status = ?, soft_delete = ? WHERE cash_record_sqlite_id = ?', [data.sync_status, data.soft_delete, data.cash_record_sqlite_id]);
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
  Delete local table use
*/
  Future clearAllTableUse() async {
    final db = await instance.database;
    return await db.rawDelete('DELETE FROM $tableTableUse');
  }

/*
  Delete local table use detail
*/
  Future clearAllTableUseDetail() async {
    final db = await instance.database;
    return await db.rawDelete('DELETE FROM $tableTableUseDetail');
  }

/*
  Delete All Transfer Owner
*/
  Future clearAllTransferOwner() async {
    final db = await instance.database;
    return await db.rawDelete('DELETE FROM $tableTransferOwner');
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
  Delete All Order detail cancel
*/
  Future clearAllOrderDetailCancel() async {
    final db = await instance.database;
    return await db.rawDelete('DELETE FROM $tableOrderDetailCancel');
  }

/*
  Delete All Order modifier detail
*/
  Future clearAllOrderModifierDetail() async {
    final db = await instance.database;
    return await db.rawDelete('DELETE FROM $tableOrderModifierDetail');
  }

/*
  Delete All local Order
*/
  Future clearAllOrder() async {
    final db = await instance.database;
    return await db.rawDelete('DELETE FROM $tableOrder');
  }

/*
  Delete All local Order tax detail
*/
  Future clearAllOrderTax() async {
    final db = await instance.database;
    return await db.rawDelete('DELETE FROM $tableOrderTaxDetail');
  }

/*
  Delete All local Order promotion detail
*/
  Future clearAllOrderPromotion() async {
    final db = await instance.database;
    return await db.rawDelete('DELETE FROM $tableOrderPromotionDetail');
  }

/*
  Delete All local settlement
*/
  Future clearAllSettlement() async {
    final db = await instance.database;
    return await db.rawDelete('DELETE FROM $tableSettlement');
  }

/*
  Delete All local settlement link payment
*/
  Future clearAllSettlementLinkPayment() async {
    final db = await instance.database;
    return await db.rawDelete('DELETE FROM $tableSettlementLinkPayment');
  }

/*
  Delete All local customer
*/
  Future clearAllCustomer() async {
    final db = await instance.database;
    return await db.rawDelete('DELETE FROM $tableCustomer');
  }

/*
  Delete All local receipt layout
*/
  Future clearAllReceiptLayout() async {
    final db = await instance.database;
    return await db.rawDelete('DELETE FROM $tableReceipt');
  }

/*
  Delete All local cash record
*/
  Future clearAllCashRecord() async {
    final db = await instance.database;
    return await db.rawDelete('DELETE FROM $tableCashRecord');
  }

/*
  Delete All local app setting
*/
  Future clearAllAppSetting() async {
    final db = await instance.database;
    return await db.rawDelete('DELETE FROM $tableAppSetting');
  }

/*
  Delete All local printer
*/
  Future clearAllPrinter() async {
    final db = await instance.database;
    return await db.rawDelete('DELETE FROM $tablePrinter');
  }

/*
  Delete All local printer category
*/
  Future clearAllPrinterCategory() async {
    final db = await instance.database;
    return await db.rawDelete('DELETE FROM $tablePrinterLinkCategory');
  }

/*
  Delete All local refund
*/
  Future clearAllRefund() async {
    final db = await instance.database;
    return await db.rawDelete('DELETE FROM $tableRefund');
  }

/*
  Delete All local checklist
*/
  Future clearAllChecklist() async {
    final db = await instance.database;
    return await db.rawDelete('DELETE FROM $tableChecklist');
  }

/*
  Delete All local kitchen list
*/
  Future clearAllKitchenList() async {
    final db = await instance.database;
    return await db.rawDelete('DELETE FROM $tableKitchenList');
  }

/*
  Delete All second screen
*/
  Future clearAllSecondScreen() async {
    final db = await instance.database;
    return await db.rawDelete('DELETE FROM $tableSecondScreen');
  }

/*
  Delete All subscription
*/
  Future clearAllSubscription() async {
    final db = await instance.database;
    return await db.rawDelete('DELETE FROM $tableSubscription');
  }

/*
  Delete All attendance
*/
  Future clearAllAttendance() async {
    final db = await instance.database;
    return await db.rawDelete('DELETE FROM $tableAttendance');
  }

/*
  ----------------------Sync from cloud--------------------------------------------------------------------------------------------------------------------------------------------------
*/

/*
  update printer category  (from cloud)
*/
  Future<int> updatePrinterLinkCategorySyncStatusFromCloud(String printer_link_category_key) async {
    final db = await instance.database;
    return await db.rawUpdate('UPDATE $tablePrinterLinkCategory SET sync_status = ? WHERE printer_link_category_key = ?', [1, printer_link_category_key]);
  }

/*
  update printer  (from cloud)
*/
  Future<int> updatePrinterSyncStatusFromCloud(String printer_key) async {
    final db = await instance.database;
    return await db.rawUpdate('UPDATE $tablePrinter SET sync_status = ? WHERE printer_key = ?', [1, printer_key]);
  }

/*
  update category(from cloud)
*/
  Future<int> updateCategoryFromCloud(Categories data) async {
    final db = await instance.database;
    return await db.rawUpdate('UPDATE $tableCategories SET name = ?, sequence = ?, color = ?, updated_at = ?, soft_delete = ? WHERE category_id = ?',
        [data.name, data.sequence, data.color, data.updated_at, data.soft_delete, data.category_id]);
  }

/*
  update order(from cloud)
*/
  Future<int> updateOrderSyncStatusFromCloud(String order_key) async {
    final db = await instance.database;
    return await db.rawUpdate('UPDATE $tableOrder SET sync_status = ? WHERE order_key = ?', [1, order_key]);
  }

/*
  update order tax (from cloud)
*/
  Future<int> updateOrderTaxDetailSyncStatusFromCloud(String order_tax_detail_key) async {
    final db = await instance.database;
    return await db.rawUpdate('UPDATE $tableOrderTaxDetail SET sync_status = ? WHERE order_tax_detail_key = ?', [1, order_tax_detail_key]);
  }

/*
  update order promotion detail (from cloud)
*/
  Future<int> updateOrderPromotionDetailSyncStatusFromCloud(String order_promotion_detail_key) async {
    final db = await instance.database;
    return await db.rawUpdate('UPDATE $tableOrderPromotionDetail SET sync_status = ? WHERE order_promotion_detail_key = ?', [1, order_promotion_detail_key]);
  }

/*
  update order cache (from cloud)
*/
  Future<int> updateOrderCacheSyncStatusFromCloud(String order_cache_key) async {
    final db = await instance.database;
    return await db.rawUpdate('UPDATE $tableOrderCache SET sync_status = ? WHERE order_cache_key = ?', [1, order_cache_key]);
  }

/*
  update order detail (from cloud)
*/
  Future<int> updateOrderDetailSyncStatusFromCloud(String order_detail_key) async {
    final db = await instance.database;
    return await db.rawUpdate('UPDATE $tableOrderDetail SET sync_status = ? WHERE order_detail_key = ?', [1, order_detail_key]);
  }

/*
  update order modifier detail (from cloud)
*/
  Future<int> updateOrderModifierDetailSyncStatusFromCloud(String order_modifier_detail_key) async {
    final db = await instance.database;
    return await db.rawUpdate('UPDATE $tableOrderModifierDetail SET sync_status = ? WHERE order_modifier_detail_key = ?', [1, order_modifier_detail_key]);
  }

/*
  update table use(from cloud)
*/
  Future<int> updateTableUseSyncStatusFromCloud(String table_use_key) async {
    final db = await instance.database;
    return await db.rawUpdate('UPDATE $tableTableUse SET sync_status = ? WHERE table_use_key = ?', [1, table_use_key]);
  }

/*
  update table use detail(from cloud)
*/
  Future<int> updateTableUseDetailSyncStatusFromCloud(String table_use_detail_key) async {
    final db = await instance.database;
    return await db.rawUpdate('UPDATE $tableTableUseDetail SET sync_status = ? WHERE table_use_detail_key = ?', [1, table_use_detail_key]);
  }

/*
  update pos table(from cloud)
*/
  Future<int> updatePosTableSyncStatusFromCloud(int table_id) async {
    final db = await instance.database;
    return await db.rawUpdate('UPDATE $tablePosTable SET sync_status = ? WHERE table_id = ?', [1, table_id]);
  }

/*
  update cash record (from cloud)
*/
  Future<int> updateCashRecordSyncStatusFromCloud(String cash_record_key) async {
    final db = await instance.database;
    return await db.rawUpdate('UPDATE $tableCashRecord SET sync_status = ? WHERE cash_record_key = ?', [1, cash_record_key]);
  }

/*
  update app setting (from cloud)
*/
  Future<int> updateAppSettingSyncStatusFromCloud(String branch_id) async {
    final db = await instance.database;
    return await db.rawUpdate('UPDATE $tableAppSetting SET sync_status = ? WHERE branch_id = ?', [1, branch_id]);
  }

/*
  update transfer owner (from cloud)
*/
  Future<int> updateTransferOwnerSyncStatusFromCloud(String transfer_owner_key) async {
    final db = await instance.database;
    return await db.rawUpdate('UPDATE $tableTransferOwner SET sync_status = ? WHERE transfer_owner_key = ?', [1, transfer_owner_key]);
  }

/*
  update receipt (from cloud)
*/
  Future<int> updateReceiptSyncStatusFromCloud(String receipt_key) async {
    final db = await instance.database;
    return await db.rawUpdate('UPDATE $tableReceipt SET sync_status = ? WHERE receipt_key = ?', [1, receipt_key]);
  }

/*
  update refund (from cloud)
*/
  Future<int> updateRefundSyncStatusFromCloud(String refund_key) async {
    final db = await instance.database;
    return await db.rawUpdate('UPDATE $tableRefund SET sync_status = ? WHERE refund_key = ?', [1, refund_key]);
  }

/*
  update branch link product (from cloud)
*/
  Future<int> updateBranchLinkProductSyncStatusFromCloud(int branch_link_product_id) async {
    final db = await instance.database;
    return await db.rawUpdate('UPDATE $tableBranchLinkProduct SET sync_status = ? WHERE branch_link_product_id = ?', [1, branch_link_product_id]);
  }

/*
  update settlement (from cloud)
*/
  Future<int> updateSettlementSyncStatusFromCloud(String settlement_key) async {
    final db = await instance.database;
    return await db.rawUpdate('UPDATE $tableSettlement SET sync_status = ? WHERE settlement_key = ?', [1, settlement_key]);
  }

/*
  update settlement link payment (from cloud)
*/
  Future<int> updateSettlementLinkPaymentSyncStatusFromCloud(String settlement_link_payment_key) async {
    final db = await instance.database;
    return await db.rawUpdate('UPDATE $tableSettlementLinkPayment SET sync_status = ? WHERE settlement_link_payment_key = ?', [1, settlement_link_payment_key]);
  }

/*
  update order detail cancel (from cloud)
*/
  Future<int> updateOrderDetailCancelSyncStatusFromCloud(String order_detail_cancel_key) async {
    final db = await instance.database;
    return await db.rawUpdate('UPDATE $tableOrderDetailCancel SET sync_status = ? WHERE order_detail_cancel_key = ?', [1, order_detail_cancel_key]);
  }

/*
  update checklist sync status (from cloud)
*/
  Future<int> updateChecklistSyncStatusFromCloud(String checklist_key) async {
    final db = await instance.database;
    return await db.rawUpdate('UPDATE $tableChecklist SET sync_status = ? WHERE checklist_key = ?', [1, checklist_key]);
  }

/*
  update kitchen list sync status (from cloud)
*/
  Future<int> updateKitchenListSyncStatusFromCloud(String kitchen_list_key) async {
    final db = await instance.database;
    return await db.rawUpdate('UPDATE $tableKitchenList SET sync_status = ? WHERE kitchen_list_key = ?', [1, kitchen_list_key]);
  }

/*
  update attendance sync status (from cloud)
*/
  Future<int> updateAttendanceSyncStatusFromCloud(String attendance_key) async {
    final db = await instance.database;
    return await db.rawUpdate('UPDATE $tableAttendance SET sync_status = ? WHERE attendance_key = ?', [1, attendance_key]);
  }
/*
  ----------------------Sync to cloud(update)--------------------------------------------------------------------------------------------------------------------------------------------------
*/

/*
  read all not yet sync to cloud updated cash record
*/
  Future<List<CashRecord>> readAllNotSyncUpdatedCashRecord() async {
    final db = await instance.database;
    final result = await db.rawQuery('SELECT * FROM $tableCashRecord WHERE sync_status = ? ', [2]);

    return result.map((json) => CashRecord.fromJson(json)).toList();
  }

/*
  read all not yet sync to cloud updated pos table
*/
  Future<List<PosTable>> readAllNotSyncUpdatedPosTable() async {
    final db = await instance.database;
    final result = await db.rawQuery('SELECT * FROM $tablePosTable WHERE soft_delete = ? AND sync_status != ? LIMIT 10 ', ['', 1]);

    return result.map((json) => PosTable.fromJson(json)).toList();
  }

/*
  read all not yet sync to cloud updated table_use_detail
*/
  Future<List<TableUseDetail>> readAllNotSyncUpdatedTableUseDetail() async {
    final db = await instance.database;
    final result = await db.rawQuery(
        'SELECT a.soft_delete, a.updated_at, a.created_at, a.sync_status, a.status, a.table_use_key, a.table_use_detail_key, CAST(b.table_id AS TEXT) AS table_id '
        'FROM $tableTableUseDetail AS a JOIN $tablePosTable AS b ON a.table_sqlite_id = b.table_sqlite_id WHERE b.soft_delete = ? AND a.sync_status = ? ',
        ['', 2]);

    return result.map((json) => TableUseDetail.fromJson(json)).toList();
  }

/*
  read all not yet sync to cloud updated table use
*/
  Future<List<TableUse>> readAllNotSyncUpdatedTableUse() async {
    final db = await instance.database;
    final result = await db.rawQuery('SELECT * FROM $tableTableUse WHERE sync_status = ? ', [2]);

    return result.map((json) => TableUse.fromJson(json)).toList();
  }

/*
  read all not yet sync to cloud updated order modifier detail
*/
  Future<List<OrderModifierDetail>> readAllNotSyncUpdatedOrderModifierDetail() async {
    final db = await instance.database;
    final result = await db.rawQuery('SELECT * FROM $tableOrderModifierDetail WHERE sync_status = ? ', [2]);

    return result.map((json) => OrderModifierDetail.fromJson(json)).toList();
  }

/*
  read all not yet sync to cloud updated order detail
*/
  Future<List<OrderDetail>> readAllNotSyncUpdatedOrderDetail() async {
    final db = await instance.database;
    final result = await db.rawQuery(
        'SELECT a.soft_delete, a.updated_at, a.created_at, a.sync_status, a.status, a.cancel_by_user_id, a.cancel_by, a.edited_by_user_id, a.edited_by, a.account, a.remark, a.quantity, '
        'a.original_price, a.price, a.product_variant_name, a.has_variant, a.product_name, a.order_cache_key, a.order_detail_key, b.category_id, c.branch_link_product_id '
        'FROM $tableOrderDetail AS a JOIN $tableCategories as b ON a.category_sqlite_id = b.category_sqlite_id '
        'JOIN $tableBranchLinkProduct AS c ON a.branch_link_product_sqlite_id = c.branch_link_product_sqlite_id '
        'WHERE b.soft_delete = ? AND c.soft_delete = ? AND a.sync_status = ? ',
        ['', '', 2]);

    return result.map((json) => OrderDetail.fromJson(json)).toList();
  }

/*
  read all not yet sync to cloud updated order cache
*/
  Future<List<OrderCache>> readAllNotSyncUpdatedOrderCache() async {
    final db = await instance.database;
    final result = await db.rawQuery('SELECT * FROM $tableOrderCache WHERE sync_status = ? ', [2]);

    return result.map((json) => OrderCache.fromJson(json)).toList();
  }

/*
  read all not yet sync to cloud updated order promotion detail
*/
  Future<List<OrderPromotionDetail>> readAllNotSyncUpdatedOrderPromotionDetail() async {
    final db = await instance.database;
    final result = await db.rawQuery('SELECT * FROM $tableOrderPromotionDetail WHERE sync_status = ? ', [2]);

    return result.map((json) => OrderPromotionDetail.fromJson(json)).toList();
  }

/*
  read all not yet sync to cloud updated order tax detail
*/
  Future<List<OrderTaxDetail>> readAllNotSyncUpdatedOrderTaxDetail() async {
    final db = await instance.database;
    final result = await db.rawQuery('SELECT * FROM $tableOrderTaxDetail WHERE sync_status = ? ', [2]);

    return result.map((json) => OrderTaxDetail.fromJson(json)).toList();
  }

/*
  read all not yet sync to cloud updated order
*/
  Future<List<Order>> readAllNotSyncUpdatedOrder() async {
    final db = await instance.database;
    final result = await db.rawQuery('SELECT * FROM $tableOrder WHERE sync_status = ? ', [2]);

    return result.map((json) => Order.fromJson(json)).toList();
  }

/*
  ----------------------Sync to cloud(create)--------------------------------------------------------------------------------------------------------------------------------------------------
*/

/*
  read all not yet sync checklist
*/
  Future<List<Checklist>> readAllNotSyncChecklist() async {
    final db = await instance.database;
    final result = await db.rawQuery('SELECT * FROM $tableChecklist WHERE sync_status != ? LIMIT 10 ', [1]);

    return result.map((json) => Checklist.fromJson(json)).toList();
  }

/*
  read all not yet sync kitchen list
*/
  Future<List<KitchenList>> readAllNotSyncKitchenList() async {
    final db = await instance.database;
    final result = await db.rawQuery('SELECT * FROM $tableKitchenList WHERE sync_status != ? LIMIT 10 ', [1]);

    return result.map((json) => KitchenList.fromJson(json)).toList();
  }

/*
  read all not yet sync attendance
*/
  Future<List<Attendance>> readAllNotSyncAttendance() async {
    final db = await instance.database;
    final result = await db.rawQuery('SELECT * FROM $tableAttendance WHERE sync_status != ? LIMIT 10 ', [1]);

    return result.map((json) => Attendance.fromJson(json)).toList();
  }

/*
  read all not yet sync receipt
*/
  Future<List<Receipt>> readAllNotSyncReceipt() async {
    final db = await instance.database;
    final result = await db.rawQuery('SELECT * FROM $tableReceipt WHERE sync_status != ? LIMIT 10 ', [1]);

    return result.map((json) => Receipt.fromJson(json)).toList();
  }

/*
  read all not yet sync printer link category
*/
  Future<List<PrinterLinkCategory>> readAllNotSyncPrinterLinkCategory() async {
    final db = await instance.database;
    final result = await db.rawQuery(
        'SELECT a.* FROM $tablePrinterLinkCategory AS a JOIN $tablePrinter AS b ON a.printer_key = b.printer_key '
        'WHERE b.type = ? AND a.sync_status != ? LIMIT 10 ',
        [1, 1]);

    return result.map((json) => PrinterLinkCategory.fromJson(json)).toList();
  }

/*
  read all not yet sync printer
*/
  Future<List<Printer>> readAllNotSyncLANPrinter() async {
    final db = await instance.database;
    final result = await db.rawQuery('SELECT * FROM $tablePrinter WHERE type = ? AND sync_status != ? ', [1, 1]);

    return result.map((json) => Printer.fromJson(json)).toList();
  }

/*
  read all not yet sync branch link product
*/
  Future<List<BranchLinkProduct>> readAllNotSyncBranchLinkProduct() async {
    final db = await instance.database;
    final result = await db.rawQuery('SELECT * FROM $tableBranchLinkProduct WHERE soft_delete = ? AND sync_status != ? LIMIT 10 ', ['', 1]);

    return result.map((json) => BranchLinkProduct.fromJson(json)).toList();
  }

/*
  read all not yet sync refund
*/
  Future<List<Refund>> readAllNotSyncRefund() async {
    final db = await instance.database;
    final result = await db.rawQuery('SELECT * FROM $tableRefund WHERE soft_delete = ? AND sync_status != ? LIMIT 10 ', ['', 1]);

    return result.map((json) => Refund.fromJson(json)).toList();
  }

/*
  read all not yet sync settlement link payment
*/
  Future<List<SettlementLinkPayment>> readAllNotSyncSettlementLinkPayment() async {
    final db = await instance.database;
    final result = await db.rawQuery('SELECT * FROM $tableSettlementLinkPayment WHERE soft_delete = ? AND sync_status != ? LIMIT 10 ', ['', 1]);

    return result.map((json) => SettlementLinkPayment.fromJson(json)).toList();
  }

/*
  read all not yet sync settlement
*/
  Future<List<Settlement>> readAllNotSyncSettlement() async {
    final db = await instance.database;
    final result = await db.rawQuery('SELECT * FROM $tableSettlement WHERE soft_delete = ? AND sync_status != ? LIMIT 10 ', ['', 1]);

    return result.map((json) => Settlement.fromJson(json)).toList();
  }

/*
  read all not yet sync to cloud transfer owner
*/
  Future<List<TransferOwner>> readAllNotSyncTransferOwner() async {
    final db = await instance.database;
    final result = await db.rawQuery('SELECT * FROM $tableTransferOwner WHERE soft_delete = ? AND sync_status != ? LIMIT 10 ', ['', 1]);

    return result.map((json) => TransferOwner.fromJson(json)).toList();
  }

/*
  read all not yet sync to cloud cash record
*/
  Future<List<CashRecord>> readAllNotSyncCashRecord() async {
    final db = await instance.database;
    final result = await db.rawQuery('SELECT * FROM $tableCashRecord WHERE soft_delete = ? AND sync_status != ? LIMIT 10', ['', 1]);

    return result.map((json) => CashRecord.fromJson(json)).toList();
  }

/*
  read all not yet sync to cloud app setting
*/
  Future<List<AppSetting>> readAllNotSyncAppSetting() async {
    final db = await instance.database;
    final result = await db.rawQuery('SELECT * FROM $tableAppSetting WHERE sync_status != ?', [1]);
    return result.map((json) => AppSetting.fromJson(json)).toList();
  }

/*
  read all not yet sync to cloud table_use_detail
*/
  Future<List<TableUseDetail>> readAllNotSyncTableUseDetail() async {
    final db = await instance.database;
    final result = await db.rawQuery(
        'SELECT a.soft_delete, a.updated_at, a.created_at, a.sync_status, a.status, a.table_use_key, a.table_use_detail_key, CAST(b.table_id AS TEXT) AS table_id '
        'FROM $tableTableUseDetail AS a JOIN $tablePosTable AS b ON a.table_sqlite_id = b.table_sqlite_id '
        'WHERE b.soft_delete = ? AND a.table_use_detail_key != ? AND a.sync_status != ? LIMIT 10 ',
        ['', '', 1]);

    return result.map((json) => TableUseDetail.fromJson(json)).toList();
  }

/*
  read all not yet sync to cloud table use
*/
  Future<List<TableUse>> readAllNotSyncTableUse() async {
    final db = await instance.database;
    final result = await db.rawQuery('SELECT * FROM $tableTableUse WHERE table_use_key != ? AND sync_status != ? LIMIT 10 ', ['', 1]);

    return result.map((json) => TableUse.fromJson(json)).toList();
  }

/*
  read all not yet sync to cloud order modifier detail
*/
  Future<List<OrderModifierDetail>> readAllNotSyncOrderModDetail() async {
    final db = await instance.database;
    final result =
        await db.rawQuery('SELECT * FROM $tableOrderModifierDetail WHERE order_modifier_detail_key != ? AND soft_delete = ? AND sync_status != ? LIMIT 10 ', ['', '', 1]);

    return result.map((json) => OrderModifierDetail.fromJson(json)).toList();
  }

/*
  read all not yet sync order detail cancel
*/
  Future<List<OrderDetailCancel>> readAllNotSyncOrderDetailCancel() async {
    final db = await instance.database;
    final result = await db.rawQuery('SELECT * FROM $tableOrderDetailCancel WHERE soft_delete = ? AND order_detail_cancel_key != ? AND sync_status != ? LIMIT 10 ', ['', '', 1]);
    return result.map((json) => OrderDetailCancel.fromJson(json)).toList();
  }

/*
  read all not yet sync to cloud order detail
*/
  Future<List<OrderDetail>> readAllNotSyncOrderDetail() async {
    final db = await instance.database;
    final result = await db.rawQuery(
        'SELECT a.soft_delete, a.updated_at, a.created_at, a.sync_status, a.per_quantity_unit, a.unit, a.status, a.cancel_by_user_id, a.cancel_by, a.edited_by_user_id, a.edited_by, a.account, a.remark, a.quantity,'
        'a.original_price, a.price, a.product_variant_name, a.has_variant, a.product_name, a.category_name, a.order_cache_key, a.order_detail_key, b.category_id, c.branch_link_product_id '
        'FROM $tableOrderDetail AS a JOIN $tableCategories as b ON a.category_sqlite_id = b.category_sqlite_id '
        'JOIN $tableBranchLinkProduct AS c ON a.branch_link_product_sqlite_id = c.branch_link_product_sqlite_id '
        'WHERE a.soft_delete = ? AND b.soft_delete = ? AND c.soft_delete = ? AND a.order_detail_key != ? AND a.sync_status != ? '
        'UNION ALL '
        'SELECT a.soft_delete, a.updated_at, a.created_at, a.sync_status, a.per_quantity_unit, a.unit, a.status, a.cancel_by_user_id, a.cancel_by, a.edited_by_user_id, a.edited_by, a.account, a.remark, a.quantity, '
        'a.original_price, a.price, a.product_variant_name, a.has_variant, a.product_name, a.category_name, a.order_cache_key, a.order_detail_key, 0 AS category_id, b.branch_link_product_id '
        'FROM $tableOrderDetail AS a '
        'JOIN $tableBranchLinkProduct AS b ON a.branch_link_product_sqlite_id = b.branch_link_product_sqlite_id '
        'WHERE a.category_sqlite_id = ? AND a.soft_delete = ? AND b.soft_delete = ? AND a.order_detail_key != ? AND a.sync_status != ? LIMIT 10 ',
        ['', '', '', '', 1, 0, '', '', '', 1]);

    return result.map((json) => OrderDetail.fromJson(json)).toList();
  }

/*
  read all not yet sync to cloud order cache
*/
  Future<List<OrderCache>> readAllNotSyncOrderCache() async {
    final db = await instance.database;
    final result = await db.rawQuery('SELECT * FROM $tableOrderCache WHERE order_cache_key != ? AND sync_status != ? LIMIT 10 ', ['', 1]);
    return result.map((json) => OrderCache.fromJson(json)).toList();
  }

/*
  read all not yet sync to cloud order promotion details
*/
  Future<List<OrderPromotionDetail>> readAllNotSyncOrderPromotionDetail() async {
    final db = await instance.database;
    final result = await db.rawQuery('SELECT * FROM $tableOrderPromotionDetail WHERE soft_delete = ? AND sync_status != ? LIMIT 10 ', ['', 1]);

    return result.map((json) => OrderPromotionDetail.fromJson(json)).toList();
  }

/*
  read all not yet sync to cloud order tax details
*/
  Future<List<OrderTaxDetail>> readAllNotSyncOrderTaxDetail() async {
    final db = await instance.database;
    final result = await db.rawQuery('SELECT * FROM $tableOrderTaxDetail WHERE soft_delete = ? AND sync_status != ? LIMIT 10 ', ['', 1]);

    return result.map((json) => OrderTaxDetail.fromJson(json)).toList();
  }

/*
  read all not yet sync to cloud orders
*/
  Future<List<Order>> readAllNotSyncOrder() async {
    final db = await instance.database;
    final result = await db.rawQuery('SELECT * FROM $tableOrder WHERE soft_delete = ? AND order_key != ? AND sync_status != ? LIMIT 10 ', ['', '', 1]);

    return result.map((json) => Order.fromJson(json)).toList();
  }

/*
  ----------------------Sync record insert checking query----------------------------------------------------------------------------------------------------------------------------------
*/

/*
  read specific category (sync record)
*/
  Future<Categories?> checkSpecificCategoryId(int category_id) async {
    final db = await instance.database;
    final result = await db.rawQuery('SELECT * FROM $tableCategories WHERE soft_delete = ? AND category_id = ? LIMIT 1 ', ['', category_id]);
    if (result.isNotEmpty) {
      return Categories.fromJson(result.first);
    } else {
      return null;
    }
  }

/*
  read specific product (sync record)
*/
  Future<Product?> checkSpecificProductId(int product_id) async {
    final db = await instance.database;
    final result = await db.rawQuery('SELECT * FROM $tableProduct WHERE soft_delete = ? AND product_id = ? LIMIT 1 ', ['', product_id]);
    if (result.isNotEmpty) {
      return Product.fromJson(result.first);
    } else {
      return null;
    }
  }

/*
  read specific mod link product (sync record)
*/
  Future<ModifierLinkProduct?> checkSpecificModifierLinkProductId(int modifier_link_product_id) async {
    final db = await instance.database;
    final result = await db.rawQuery('SELECT * FROM $tableModifierLinkProduct WHERE soft_delete = ? AND modifier_link_product_id = ? LIMIT 1 ', ['', modifier_link_product_id]);
    if (result.isNotEmpty) {
      return ModifierLinkProduct.fromJson(result.first);
    } else {
      return null;
    }
  }

/*
  read specific variant group (sync record)
*/
  Future<VariantGroup?> checkSpecificVariantGroupId(int variant_group_id) async {
    final db = await instance.database;
    final result = await db.rawQuery('SELECT * FROM $tableVariantGroup WHERE soft_delete = ? AND variant_group_id = ? LIMIT 1 ', ['', variant_group_id]);
    if (result.isNotEmpty) {
      return VariantGroup.fromJson(result.first);
    } else {
      return null;
    }
  }

/*
  read specific variant item (sync record)
*/
  Future<VariantItem?> checkSpecificVariantItemId(int variant_item_id) async {
    final db = await instance.database;
    final result = await db.rawQuery('SELECT * FROM $tableVariantItem WHERE soft_delete = ? AND variant_item_id = ? LIMIT 1 ', ['', variant_item_id]);
    if (result.isNotEmpty) {
      return VariantItem.fromJson(result.first);
    } else {
      return null;
    }
  }

/*
  read specific product variant (sync record)
*/
  Future<ProductVariant?> checkSpecificProductVariantId(int product_variant_id) async {
    final db = await instance.database;
    final result = await db.rawQuery('SELECT * FROM $tableProductVariant WHERE soft_delete = ? AND product_variant_id = ? LIMIT 1 ', ['', product_variant_id]);
    if (result.isNotEmpty) {
      return ProductVariant.fromJson(result.first);
    } else {
      return null;
    }
  }

/*
  read specific product variant detail (sync record)
*/
  Future<ProductVariantDetail?> checkSpecificProductVariantDetailId(int product_variant_detail_id) async {
    final db = await instance.database;
    final result = await db.rawQuery('SELECT * FROM $tableProductVariantDetail WHERE soft_delete = ? AND product_variant_detail_id = ? LIMIT 1 ', ['', product_variant_detail_id]);
    if (result.isNotEmpty) {
      return ProductVariantDetail.fromJson(result.first);
    } else {
      return null;
    }
  }

/*
  read specific branch link product (sync record)
*/
  Future<BranchLinkProduct?> checkSpecificBranchLinkProductId(int branch_link_product_id) async {
    final db = await instance.database;
    final result = await db.rawQuery('SELECT * FROM $tableBranchLinkProduct WHERE soft_delete = ? AND branch_link_product_id = ? LIMIT 1 ', ['', branch_link_product_id]);
    if (result.isNotEmpty) {
      return BranchLinkProduct.fromJson(result.first);
    } else {
      return null;
    }
  }

/*
  read specific modifier group (sync record)
*/
  Future<ModifierGroup?> checkSpecificModifierGroupId(int mod_group_id) async {
    final db = await instance.database;
    final result = await db.rawQuery('SELECT * FROM $tableModifierGroup WHERE soft_delete = ? AND mod_group_id = ? LIMIT 1 ', ['', mod_group_id]);
    if (result.isNotEmpty) {
      return ModifierGroup.fromJson(result.first);
    } else {
      return null;
    }
  }

/*
  read specific modifier item (sync record)
*/
  Future<ModifierItem?> checkSpecificModifierItemId(int mod_item_id) async {
    final db = await instance.database;
    final result = await db.rawQuery('SELECT * FROM $tableModifierItem WHERE soft_delete = ? AND mod_item_id = ? LIMIT 1 ', ['', mod_item_id]);
    if (result.isNotEmpty) {
      return ModifierItem.fromJson(result.first);
    } else {
      return null;
    }
  }

/*
  read specific branch link modifier (sync record)
*/
  Future<BranchLinkModifier?> checkSpecificBranchLinkModifierId(int branch_link_modifier_id) async {
    final db = await instance.database;
    final result = await db.rawQuery('SELECT * FROM $tableBranchLinkModifier WHERE soft_delete = ? AND branch_link_modifier_id = ? LIMIT 1 ', ['', branch_link_modifier_id]);
    if (result.isNotEmpty) {
      return BranchLinkModifier.fromJson(result.first);
    } else {
      return null;
    }
  }

/*
  read specific user (sync record)
*/
  Future<User?> checkSpecificUserId(int user_id) async {
    final db = await instance.database;
    final result = await db.rawQuery('SELECT * FROM $tableUser WHERE soft_delete = ? AND user_id = ? LIMIT 1 ', ['', user_id]);
    if (result.isNotEmpty) {
      return User.fromJson(result.first);
    } else {
      return null;
    }
  }

/*
  read specific branch link user (sync record)
*/
  Future<BranchLinkUser?> checkSpecificBranchLinkUserId(int branch_link_user_id) async {
    final db = await instance.database;
    final result = await db.rawQuery('SELECT * FROM $tableBranchLinkUser WHERE soft_delete = ? AND branch_link_user_id = ? LIMIT 1 ', ['', branch_link_user_id]);
    if (result.isNotEmpty) {
      return BranchLinkUser.fromJson(result.first);
    } else {
      return null;
    }
  }

/*
  read specific payment link company (sync record)
*/
  Future<PaymentLinkCompany?> checkSpecificPaymentLinkCompanyId(int payment_link_company_id) async {
    final db = await instance.database;
    final result = await db.rawQuery('SELECT * FROM $tablePaymentLinkCompany WHERE payment_link_company_id = ? LIMIT 1 ', [payment_link_company_id]);
    if (result.isNotEmpty) {
      return PaymentLinkCompany.fromJson(result.first);
    } else {
      return null;
    }
  }

/*
  read specific tax (sync record)
*/
  Future<Tax?> checkSpecificTaxId(int tax_id) async {
    final db = await instance.database;
    final result = await db.rawQuery('SELECT * FROM $tableTax WHERE soft_delete = ? AND tax_id = ? LIMIT 1 ', ['', tax_id]);
    if (result.isNotEmpty) {
      return Tax.fromJson(result.first);
    } else {
      return null;
    }
  }

/*
  read specific branch link tax (sync record)
*/
  Future<BranchLinkTax?> checkSpecificBranchLinkTaxId(int branch_link_tax_id) async {
    final db = await instance.database;
    final result = await db.rawQuery('SELECT * FROM $tableBranchLinkTax WHERE soft_delete = ? AND branch_link_tax_id = ? LIMIT 1 ', ['', branch_link_tax_id]);
    if (result.isNotEmpty) {
      return BranchLinkTax.fromJson(result.first);
    } else {
      return null;
    }
  }

/*
  read specific branch link tax (sync record)
*/
  Future<TaxLinkDining?> checkSpecificTaxLinkDiningId(int tax_link_dining_id) async {
    final db = await instance.database;
    final result = await db.rawQuery('SELECT * FROM $tableTaxLinkDining WHERE soft_delete = ? AND tax_link_dining_id = ? LIMIT 1 ', ['', tax_link_dining_id]);
    if (result.isNotEmpty) {
      return TaxLinkDining.fromJson(result.first);
    } else {
      return null;
    }
  }

/*
  read specific table (sync record)
*/
  Future<PosTable?> checkSpecificTableId(int table_id) async {
    final db = await instance.database;
    final result = await db.rawQuery('SELECT * FROM $tablePosTable WHERE soft_delete = ? AND table_id = ? LIMIT 1 ', ['', table_id]);
    if (result.isNotEmpty) {
      return PosTable.fromJson(result.first);
    } else {
      return null;
    }
  }

/*
  read specific promotion (sync record)
*/
  Future<Promotion?> checkSpecificPromotionId(int promotion_id) async {
    final db = await instance.database;
    final result = await db.rawQuery('SELECT * FROM $tablePromotion WHERE soft_delete = ? AND promotion_id = ? LIMIT 1 ', ['', promotion_id]);
    if (result.isNotEmpty) {
      return Promotion.fromJson(result.first);
    } else {
      return null;
    }
  }

/*
  read specific branch link promotion (sync record)
*/
  Future<BranchLinkPromotion?> checkSpecificBranchLinkPromotionId(int branch_link_promotion_id) async {
    final db = await instance.database;
    final result = await db.rawQuery(
      'SELECT * FROM $tableBranchLinkPromotion WHERE soft_delete = ? AND branch_link_promotion_id = ? LIMIT 1',
      ['', branch_link_promotion_id],
    );
    if (result.isNotEmpty) {
      return BranchLinkPromotion.fromJson(result.first);
    } else {
      return null;
    }
  }

/*
  read dining option by cloud id
*/
  Future<DiningOption?> checkSpecificDiningOptionByCloudId(String id) async {
    final db = await instance.database;
    final result = await db.rawQuery('SELECT * FROM $tableDiningOption WHERE dining_id = ?', [id]);
    if(result.isNotEmpty){
      return DiningOption.fromJson(result.first);
    } else {
      return null;
    }
  }

/*
  check table use
*/
  Future<TableUse?> checkSpecificTableUse(String key) async {
    final db = await instance.database;
    final result = await db.rawQuery('SELECT * FROM $tableTableUse WHERE table_use_key = ?', [key]);
    if(result.isNotEmpty){
      return TableUse.fromJson(result.first);
    } else {
      return null;
    }
  }

/*
  check table use detail
*/
  Future<TableUseDetail?> checkSpecificTableUseDetail(String key) async {
    final db = await instance.database;
    final result = await db.rawQuery('SELECT * FROM $tableTableUseDetail WHERE table_use_detail_key = ?', [key]);
    if(result.isNotEmpty){
      return TableUseDetail.fromJson(result.first);
    } else {
      return null;
    }
  }

/*
  check second screen (sync record)
*/
  Future<SecondScreen?> checkSpecificSecondScreen(String id) async {
    final db = await instance.database;
    final result = await db.rawQuery('SELECT * FROM $tableSecondScreen WHERE id = ? AND soft_delete = ?', [id, '']);
    if(result.isNotEmpty){
      return SecondScreen.fromJson(result.first);
    } else {
      return null;
    }
  }

/*
  ----------------------Server query--------------------------------------------------------------------------------------------------------------------------------------------------
*/

/*
  read all product(client side)
*/
  Future<List<Product>> readAllClientProduct() async {
    final db = await instance.database;
    final result = await db.rawQuery(
        'SELECT DISTINCT a.*, '
        'IFNULL ((SELECT name FROM $tableCategories WHERE category_sqlite_id = a.category_sqlite_id), "NaN") AS category_name '
        'FROM $tableProduct AS a JOIN $tableBranchLinkProduct AS b ON a.product_id = b.product_id '
        'WHERE a.soft_delete = ? AND b.soft_delete = ? AND a.available = ? ',
        ['', '', 1]);
    return result.map((json) => Product.fromJson(json)).toList();
  }

/*
  read Specific table(toJson)
*/
  Future<String> readSpecificTableToJson(String table_id) async {
    final db = await instance.database;
    final result = await db.rawQuery('SELECT * FROM $tablePosTable WHERE soft_delete = ? AND table_id = ?', ['', table_id]);
    return jsonEncode(result);
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
