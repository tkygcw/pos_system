import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pos_system/database/pos_database.dart';
import 'package:pos_system/object/bill.dart';
import 'package:pos_system/object/branch_link_dining_option.dart';
import 'package:pos_system/object/branch_link_modifier.dart';
import 'package:pos_system/object/branch_link_product.dart';
import 'package:pos_system/object/branch_link_promotion.dart';
import 'package:pos_system/object/branch_link_tax.dart';
import 'package:pos_system/object/cash_record.dart';
import 'package:pos_system/object/categories.dart';
import 'package:pos_system/object/modifier_group.dart';
import 'package:pos_system/object/modifier_item.dart';
import 'package:pos_system/object/modifier_link_product.dart';
import 'package:pos_system/object/order.dart';
import 'package:pos_system/object/order_cache.dart';
import 'package:pos_system/object/order_detail.dart';
import 'package:pos_system/object/order_detail_cancel.dart';
import 'package:pos_system/object/order_modifier_detail.dart';
import 'package:pos_system/object/order_promotion_detail.dart';
import 'package:pos_system/object/order_tax_detail.dart';
import 'package:pos_system/object/payment_link_company.dart';
import 'package:pos_system/object/printer.dart';
import 'package:pos_system/object/printer_link_category.dart';
import 'package:pos_system/object/product.dart';
import 'package:pos_system/object/product_variant.dart';
import 'package:pos_system/object/product_variant_detail.dart';
import 'package:pos_system/object/promotion.dart';
import 'package:pos_system/object/refund.dart';
import 'package:pos_system/object/sale.dart';
import 'package:pos_system/object/settlement.dart';
import 'package:pos_system/object/settlement_link_payment.dart';
import 'package:pos_system/object/table.dart';
import 'package:pos_system/object/tax_link_dining.dart';
import 'package:pos_system/object/user.dart';
import 'package:pos_system/object/variant_group.dart';
import 'package:pos_system/object/variant_item.dart';
import 'package:pos_system/page/pos_pin.dart';
import 'package:pos_system/page/progress_bar.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../database/domain.dart';
import '../notifier/theme_color.dart';
import '../object/branch_link_user.dart';
import '../object/customer.dart';
import '../object/dining_option.dart';
import '../object/receipt.dart';
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
    getAllUser();
    getAllSettlement();
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
    getModifierGroup();
    getModifierItem();
    getBranchLinkModifier();
    getSale();
    getCashRecord();
    getAllPrinter();
    clearCloudSyncRecord();
    createReceiptLayout();

    // Go to Page2 after 5s.
    Timer(Duration(seconds: 5), () {
      Navigator.push(context, MaterialPageRoute(builder: (_) => PosPinPage()));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeColor>(builder: (context, ThemeColor color, child) {
      return Scaffold(
        backgroundColor: color.backgroundColor,
        body: CustomProgressBar(),
      );
    });
  }

  createReceiptLayout() async {
    try {
      DateFormat dateFormat = DateFormat("yyyy-MM-dd HH:mm:ss");
      String dateTime = dateFormat.format(DateTime.now());
      final prefs = await SharedPreferences.getInstance();
      final int? branch_id = prefs.getInt('branch_id');

      Receipt data = await PosDatabase.instance.insertSqliteReceipt(Receipt(
          receipt_id: 0,
          branch_id: branch_id.toString(),
          company_id: '',
          header_text: '',
          footer_text: '',
          header_image: '',
          footer_image: '',
          header_text_status: 0,
          footer_text_status: 0,
          header_image_status: 0,
          footer_image_status: 0,
          promotion_detail_status: 0,
          status: 1,
          sync_status: 0,
          created_at: dateTime,
          updated_at: '',
          soft_delete: ''));
    } catch (e) {
      Fluttertoast.showToast(backgroundColor: Color(0xFFFF0000), msg: "Fail to add receipt layout, Please try again $e");
      print('$e');
    }
  }

  clearCloudSyncRecord() async {
    final prefs = await SharedPreferences.getInstance();
    final int? branch_id = prefs.getInt('branch_id');
    Map data = await Domain().clearAllSyncRecord(branch_id.toString());
  }

/*
  save printer to local database
*/
  getAllPrinter() async {
    final prefs = await SharedPreferences.getInstance();
    final int? branch_id = prefs.getInt('branch_id');
    Map data = await Domain().getPrinter(branch_id.toString());
    if (data['status'] == '1') {
      List responseJson = data['printer'];
      for (var i = 0; i < responseJson.length; i++) {
        Printer printerItem = Printer.fromJson(responseJson[i]);
        Printer data = await PosDatabase.instance.insertPrinter(Printer(
            printer_id: printerItem.printer_id,
            printer_key: printerItem.printer_key,
            branch_id: printerItem.branch_id,
            company_id: printerItem.company_id,
            printer_link_category_id: '',
            value: printerItem.value,
            type: printerItem.type,
            printer_label: printerItem.printer_label,
            paper_size: printerItem.paper_size,
            printer_status: printerItem.printer_status,
            is_counter: printerItem.is_counter,
            sync_status: 1,
            created_at: printerItem.created_at,
            updated_at: printerItem.updated_at,
            soft_delete: printerItem.soft_delete));
      }
    }
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
        User user = await PosDatabase.instance.insertUser(User.fromJson(responseJson[i]));
        // if (user != '') {
        //   Navigator.of(context).pushReplacement(MaterialPageRoute(
        //     builder: (context) => PosPinPage(),
        //   ));
        // }
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
        BranchLinkUser data = await PosDatabase.instance.insertBranchLinkUser(BranchLinkUser.fromJson(responseJson[i]));
      }
    }
  }

/*
  save settlement to database
*/
  getAllSettlement() async {
    final prefs = await SharedPreferences.getInstance();
    final int? branch_id = prefs.getInt('branch_id');
    final String? user = prefs.getString('user');
    Map userObject = json.decode(user!);
    Map data = await Domain().getSettlement(userObject['company_id'], branch_id.toString());
    if (data['status'] == '1') {
      List responseJson = data['settlement'];
      for (var i = 0; i < responseJson.length; i++) {
        Settlement item = Settlement.fromJson(responseJson[i]);
        Settlement data = await PosDatabase.instance.insertSettlement(Settlement(
          settlement_id: item.settlement_id,
          settlement_key: item.settlement_key,
          company_id: item.company_id,
          branch_id: item.branch_id,
          total_bill: item.total_bill,
          total_sales: item.total_sales,
          total_refund_bill: item.total_refund_bill,
          total_refund_amount: item.total_refund_amount,
          total_discount: item.total_discount,
          total_cancellation: item.total_cancellation,
          total_tax: item.total_tax,
          settlement_by_user_id: item.settlement_by_user_id,
          settlement_by: item.settlement_by,
          status: item.status,
          sync_status: 1,
          created_at: item.created_at,
          updated_at: item.updated_at,
          soft_delete: item.soft_delete,
        ));
      }
      getAllOrder();
      getAllTable();
      getSettlementLinkPayment();
    } else {
      getAllOrder();
      getAllTable();
      getSettlementLinkPayment();
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
        PosTable table = await PosDatabase.instance.insertPosTable(PosTable.fromJson(responseJson[i]));
      }
      getAllCategory();
    } else {
      getAllCategory();
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
      Categories data = await PosDatabase.instance.insertCategories(Categories.fromJson(responseJson[i]));
    }
    getAllProduct();
    getAllPrinterLinkCategory();
  }
}

/*
  save printer category to database
*/
getAllPrinterLinkCategory() async {
  final prefs = await SharedPreferences.getInstance();
  final int? branch_id = prefs.getInt('branch_id');
  Map data = await Domain().getPrinterCategory(branch_id.toString());
  if (data['status'] == '1') {
    List responseJson = data['printer'];
    for (var i = 0; i < responseJson.length; i++) {
      PrinterLinkCategory item = PrinterLinkCategory.fromJson(responseJson[i]);
      Printer printer = await PosDatabase.instance.readPrinterSqliteID(item.printer_key!);
      Categories? categories = await PosDatabase.instance.readCategorySqliteID(item.category_id!);
      PrinterLinkCategory data = await PosDatabase.instance.insertPrinterCategory(PrinterLinkCategory(
        printer_link_category_key: item.printer_link_category_key,
        printer_link_category_id: item.printer_link_category_id,
        printer_sqlite_id: printer.printer_sqlite_id.toString(),
        printer_key: item.printer_key,
        category_sqlite_id: categories != null ? categories.category_sqlite_id.toString() : '0',
        category_id: item.category_id,
        sync_status: 1,
        created_at: item.created_at,
        updated_at: item.updated_at,
        soft_delete: item.soft_delete,
      ));
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
          category_sqlite_id: categoryData != null ? categoryData.category_sqlite_id.toString() : '0',
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
          soft_delete: productItem.soft_delete));
    }
    getModifierLinkProduct();
    getVariantGroup();
    getProductVariant();
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
      DiningOption data = await PosDatabase.instance.insertDiningOption(DiningOption.fromJson(responseJson[i]));
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
      BranchLinkDining data = await PosDatabase.instance.insertBranchLinkDining(BranchLinkDining.fromJson(responseJson[i]));
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
      Tax data = await PosDatabase.instance.insertTax(Tax.fromJson(responseJson[i]));
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
      BranchLinkTax data = await PosDatabase.instance.insertBranchLinkTax(BranchLinkTax.fromJson(responseJson[i]));
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
      TaxLinkDining data = await PosDatabase.instance.insertTaxLinkDining(TaxLinkDining.fromJson(responseJson[i]));
    }
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
      Promotion data = await PosDatabase.instance.insertPromotion(Promotion.fromJson(responseJson[i]));
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
      BranchLinkPromotion data = await PosDatabase.instance.insertBranchLinkPromotion(BranchLinkPromotion.fromJson(responseJson[i]));
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
      Customer data = await PosDatabase.instance.insertCustomer(Customer.fromJson(responseJson[i]));
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
  Map data = await Domain().getAllBill(userObject['company_id'], branch_id.toString());
  if (data['status'] == '1') {
    List responseJson = data['bill'];
    for (var i = 0; i < responseJson.length; i++) {
      Bill data = await PosDatabase.instance.insertBill(Bill.fromJson(responseJson[i]));
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
      PaymentLinkCompany data = await PosDatabase.instance.insertPaymentLinkCompany(PaymentLinkCompany.fromJson(responseJson[i]));
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
  Map data = await Domain().getAllRefund(userObject['company_id'], branch_id.toString());
  if (data['status'] == '1') {
    List responseJson = data['refund'];
    for (var i = 0; i < responseJson.length; i++) {
      Order orderData = await PosDatabase.instance.readOrderSqliteID(responseJson[i]['order_key']);
      Refund data = await PosDatabase.instance.insertRefund(Refund(
        refund_id: responseJson[i]['refund_id'],
        refund_key: responseJson[i]['refund_key'],
        company_id: responseJson[i]['company_id'],
        branch_id: responseJson[i]['branch_id'],
        order_cache_sqlite_id: '',
        order_cache_key: '',
        order_sqlite_id: orderData.order_sqlite_id.toString(),
        order_key: responseJson[i]['order_key'],
        refund_by: responseJson[i]['refund_by'],
        refund_by_user_id: responseJson[i]['refund_by_user_id'],
        bill_id: responseJson[i]['bill_id'],
        sync_status: 1,
        created_at: responseJson[i]['created_at'],
        updated_at: responseJson[i]['updated_at'],
        soft_delete: responseJson[i]['soft_delete'],
      ));
      updateOrderRefundSqliteId(data.refund_sqlite_id.toString(), orderData.order_sqlite_id!);
    }
  }
}

/*
  save refund local id into order
*/
updateOrderRefundSqliteId(String refundLocalId, int orderLocalId) async {
  Order order = Order(refund_sqlite_id: refundLocalId, order_sqlite_id: orderLocalId);
  int data = await PosDatabase.instance.updateOrderRefundSqliteId(order);
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
      ModifierGroup data = await PosDatabase.instance.insertModifierGroup(ModifierGroup.fromJson(responseJson[i]));
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
      ModifierItem data = await PosDatabase.instance.insertModifierItem(ModifierItem.fromJson(responseJson[i]));
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
      BranchLinkModifier data = await PosDatabase.instance.insertBranchLinkModifier(BranchLinkModifier.fromJson(responseJson[i]));
    }
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
      ProductVariant? productVariantData = await PosDatabase.instance.readProductVariantSqliteID(branchLinkProductData.product_variant_id!);
      BranchLinkProduct data = await PosDatabase.instance.insertBranchLinkProduct(BranchLinkProduct(
          branch_link_product_id: branchLinkProductData.branch_link_product_id,
          branch_id: branchLinkProductData.branch_id,
          product_sqlite_id: productData!.product_sqlite_id.toString(),
          product_id: branchLinkProductData.product_id,
          has_variant: branchLinkProductData.has_variant,
          product_variant_sqlite_id: productVariantData != null ? productVariantData.product_variant_sqlite_id.toString() : '0',
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
          soft_delete: branchLinkProductData.soft_delete));
    }
    getAllTableUse();
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
      TableUse item = TableUse.fromJson(responseJson[i]);
      TableUse user = await PosDatabase.instance.insertTableUse(TableUse(
        table_use_id: item.table_use_id,
        table_use_key: item.table_use_key,
        branch_id: item.branch_id,
        order_cache_key: item.order_cache_key,
        card_color: item.card_color,
        status: item.status,
        sync_status: 1,
        created_at: item.created_at,
        updated_at: item.updated_at,
        soft_delete: item.soft_delete,
      ));
    }
    getAllOrderCache();
    getAllTableUseDetail();
  }
}

/*
  sava table use detail to database
*/
getAllTableUseDetail() async {
  final prefs = await SharedPreferences.getInstance();
  final int? branch_id = prefs.getInt('branch_id');
  Map data = await Domain().getAllTableUseDetail(branch_id.toString());
  if (data['status'] == '1') {
    List responseJson = data['table_use'];
    for (var i = 0; i < responseJson.length; i++) {
      TableUseDetail item = TableUseDetail.fromJson(responseJson[i]);
      TableUse? tableUseData = await PosDatabase.instance.readTableUseSqliteID(item.table_use_key!);
      print('table id: ${item.table_id}');
      PosTable tableData = await PosDatabase.instance.readTableByCloudId(item.table_id.toString());
      //TableUseDetail user = await PosDatabase.instance.insertSqliteTableUseDetail(TableUseDetail.fromJson(responseJson[i]));
      TableUseDetail user = await PosDatabase.instance.insertTableUseDetail(TableUseDetail(
          table_use_detail_id: item.table_use_detail_id,
          table_use_detail_key: item.table_use_detail_key,
          table_use_sqlite_id: tableUseData != null ? tableUseData.table_use_sqlite_id.toString() : '0',
          table_use_key: item.table_use_key,
          table_sqlite_id: tableData.table_sqlite_id.toString(),
          table_id: item.table_id,
          status: item.status,
          sync_status: 1,
          created_at: item.created_at,
          updated_at: item.updated_at,
          soft_delete: item.soft_delete));
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
  Map data = await Domain().getModifierLinkProduct(userObject['company_id'], branch_id.toString());
  if (data['status'] == '1') {
    List responseJson = data['product'];
    for (var i = 0; i < responseJson.length; i++) {
      ModifierLinkProduct modData = ModifierLinkProduct.fromJson(responseJson[i]);
      Product? productData = await PosDatabase.instance.readProductSqliteID(modData.product_id!);
      ModifierLinkProduct data = await PosDatabase.instance.insertModifierLinkProduct(ModifierLinkProduct(
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
      VariantGroup data = await PosDatabase.instance.insertVariantGroup(VariantGroup(
          child: [],
          variant_group_id: variantData.variant_group_id,
          product_id: variantData.product_id,
          product_sqlite_id: productData!.product_sqlite_id.toString(),
          name: variantData.name,
          sync_status: 2,
          created_at: variantData.created_at,
          updated_at: variantData.updated_at,
          soft_delete: variantData.soft_delete));
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
      VariantItem data = await PosDatabase.instance.insertVariantItem(VariantItem(
          variant_item_id: variantItemData.variant_item_id,
          variant_group_id: variantItemData.variant_group_id,
          variant_group_sqlite_id: variantGroupData != null ? variantGroupData.variant_group_sqlite_id.toString() : '0',
          name: variantItemData.name,
          sync_status: 2,
          created_at: variantItemData.created_at,
          updated_at: variantItemData.updated_at,
          soft_delete: variantItemData.soft_delete));
    }
    getBranchLinkProduct();
  } else {
    getBranchLinkProduct();
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
      ProductVariant data = await PosDatabase.instance.insertProductVariant(ProductVariant(
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
          soft_delete: productVariantItem.soft_delete));
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
      ProductVariantDetail data = await PosDatabase.instance.insertProductVariantDetail(ProductVariantDetail(
          product_variant_detail_id: productVariantDetailItem.product_variant_detail_id,
          product_variant_id: productVariantDetailItem.product_variant_id,
          product_variant_sqlite_id: productVariantData!.product_variant_sqlite_id.toString(),
          variant_item_id: productVariantDetailItem.variant_item_id,
          variant_item_sqlite_id: variantItemData!.variant_item_sqlite_id.toString(),
          sync_status: 2,
          created_at: productVariantDetailItem.created_at,
          updated_at: productVariantDetailItem.updated_at,
          soft_delete: productVariantDetailItem.soft_delete));
    }
  }
}

/*
  save settlement link payment to database
*/
getSettlementLinkPayment() async {
  final prefs = await SharedPreferences.getInstance();
  final int? branch_id = prefs.getInt('branch_id');
  final String? user = prefs.getString('user');
  Map userObject = json.decode(user!);
  Map data = await Domain().getSettlementLinkPayment(userObject['company_id'], branch_id.toString());
  if (data['status'] == '1') {
    List responseJson = data['settlement'];
    for (var i = 0; i < responseJson.length; i++) {
      SettlementLinkPayment item = SettlementLinkPayment.fromJson(responseJson[i]);
      Settlement settlementData = await PosDatabase.instance.readSettlementSqliteID(item.settlement_key!);
      SettlementLinkPayment data = await PosDatabase.instance.insertSettlementLinkPayment(SettlementLinkPayment(
        settlement_link_payment_id: item.settlement_link_payment_id,
        settlement_link_payment_key: item.settlement_link_payment_key,
        company_id: item.company_id,
        branch_id: item.branch_id,
        settlement_sqlite_id: settlementData.settlement_sqlite_id.toString(),
        settlement_key: item.settlement_key,
        total_bill: item.total_bill,
        total_sales: item.total_sales,
        payment_link_company_id: item.payment_link_company_id,
        status: item.status,
        sync_status: 1,
        created_at: item.created_at,
        updated_at: item.updated_at,
        soft_delete: item.soft_delete,
      ));
    }
  }
}

/*
  save order to database
*/
getAllOrder() async {
  Settlement? settlement;
  final prefs = await SharedPreferences.getInstance();
  final int? branch_id = prefs.getInt('branch_id');
  final String? user = prefs.getString('user');
  Map userObject = json.decode(user!);
  Map data = await Domain().getAllOrder(userObject['company_id'], branch_id.toString());
  if (data['status'] == '1') {
    List responseJson = data['order'];
    for (var i = 0; i < responseJson.length; i++) {
      if (responseJson[i]['settlement_key'] != '') {
        Settlement settlementData = await PosDatabase.instance.readSettlementSqliteID(responseJson[i]['settlement_key']);
        settlement = settlementData;
      }
      Order data = await PosDatabase.instance.insertOrder(Order(
          order_id: responseJson[i]['order_id'],
          order_number: responseJson[i]['order_number'],
          company_id: responseJson[i]['company_id'],
          customer_id: responseJson[i]['customer_id'],
          dining_id: responseJson[i]['dining_id'],
          dining_name: responseJson[i]['dining_name'],
          branch_link_promotion_id: responseJson[i]['branch_link_promotion_id'],
          payment_link_company_id: responseJson[i]['payment_link_company_id'],
          branch_id: responseJson[i]['branch_id'],
          branch_link_tax_id: responseJson[i]['branch_link_tax_id'],
          subtotal: responseJson[i]['subtotal'],
          amount: responseJson[i]['amount'],
          rounding: responseJson[i]['rounding'],
          final_amount: responseJson[i]['final_amount'],
          close_by: responseJson[i]['close_by'],
          payment_status: responseJson[i]['payment_status'],
          payment_received: responseJson[i]['payment_received'],
          payment_change: responseJson[i]['payment_change'],
          order_key: responseJson[i]['order_key'],
          refund_sqlite_id: '',
          refund_key: responseJson[i]['refund_key'],
          settlement_sqlite_id: settlement != null ? settlement.settlement_sqlite_id.toString() : '',
          settlement_key: responseJson[i]['settlement_key'],
          sync_status: 1,
          created_at: responseJson[i]['created_at'],
          updated_at: responseJson[i]['updated_at'],
          soft_delete: responseJson[i]['soft_delete']));
    }
    getAllOrderPromotionDetail();
    getAllOrderTaxDetail();
    getAllRefund();
  }
}

/*
  save order promotion detail to database
*/
getAllOrderPromotionDetail() async {
  final prefs = await SharedPreferences.getInstance();
  final int? branch_id = prefs.getInt('branch_id');
  final String? user = prefs.getString('user');
  Map userObject = json.decode(user!);
  Map data = await Domain().getAllOrderPromotionDetail(userObject['company_id'], branch_id.toString());
  if (data['status'] == '1') {
    List responseJson = data['order'];
    for (var i = 0; i < responseJson.length; i++) {
      Order orderData = await PosDatabase.instance.readOrderSqliteID(responseJson[i]['order_key']);
      OrderPromotionDetail data = await PosDatabase.instance.insertOrderPromotionDetail(OrderPromotionDetail(
        order_promotion_detail_id: responseJson[i]['order_promotion_detail_id'],
        order_promotion_detail_key: responseJson[i]['order_promotion_detail_key'],
        order_sqlite_id: orderData.order_sqlite_id.toString(),
        order_id: orderData.order_id.toString(),
        order_key: responseJson[i]['order_key'],
        promotion_name: responseJson[i]['promotion_name'],
        rate: responseJson[i]['rate'],
        promotion_id: responseJson[i]['promotion_id'],
        branch_link_promotion_id: responseJson[i]['branch_link_promotion_id'],
        promotion_amount: responseJson[i]['promotion_amount'],
        promotion_type: responseJson[i]['promotion_type'],
        auto_apply: responseJson[i]['auto_apply'],
        sync_status: 1,
        created_at: responseJson[i]['created_at'],
        updated_at: responseJson[i]['updated_at'],
        soft_delete: responseJson[i]['soft_delete'],
      ));
    }
  }
}

/*
  save order tax detail to database
*/
getAllOrderTaxDetail() async {
  final prefs = await SharedPreferences.getInstance();
  final int? branch_id = prefs.getInt('branch_id');
  final String? user = prefs.getString('user');
  Map userObject = json.decode(user!);
  Map data = await Domain().getAllOrderTaxDetail(userObject['company_id'], branch_id.toString());
  if (data['status'] == '1') {
    List responseJson = data['order'];
    for (var i = 0; i < responseJson.length; i++) {
      Order orderData = await PosDatabase.instance.readOrderSqliteID(responseJson[i]['order_key']);
      OrderTaxDetail data = await PosDatabase.instance.insertOrderTaxDetail(OrderTaxDetail(
        order_tax_detail_id: responseJson[i]['order_tax_detail_id'],
        order_tax_detail_key: responseJson[i]['order_tax_detail_key'],
        order_sqlite_id: orderData.order_sqlite_id.toString(),
        order_id: orderData.order_id.toString(),
        order_key: responseJson[i]['order_key'],
        tax_name: responseJson[i]['tax_name'],
        rate: responseJson[i]['rate'],
        tax_id: responseJson[i]['tax_id'],
        branch_link_tax_id: responseJson[i]['branch_link_tax_id'],
        tax_amount: responseJson[i]['tax_amount'],
        sync_status: 1,
        created_at: responseJson[i]['created_at'],
        updated_at: responseJson[i]['updated_at'],
        soft_delete: responseJson[i]['soft_delete'],
      ));
    }
  }
}

/*
  save order cache to database
*/
getAllOrderCache() async {
  String tableUseLocalId = '', orderLocalId = '';
  final prefs = await SharedPreferences.getInstance();
  final int? branch_id = prefs.getInt('branch_id');
  final String? user = prefs.getString('user');
  Map userObject = json.decode(user!);
  Map data = await Domain().getAllOrderCache(userObject['company_id'], branch_id.toString());
  if (data['status'] == '1') {
    List responseJson = data['order'];
    for (var i = 0; i < responseJson.length; i++) {
      OrderCache cloudData = OrderCache.fromJson(responseJson[i]);
      if (cloudData.table_use_key != '' && cloudData.table_use_key != null) {
        TableUse? tableUseData = await PosDatabase.instance.readTableUseSqliteID(cloudData.table_use_key!);
        tableUseLocalId = tableUseData!.table_use_sqlite_id.toString();
      } else {
        tableUseLocalId = '';
      }

      if (cloudData.order_key != '' && cloudData.order_key != null) {
        Order orderData = await PosDatabase.instance.readOrderSqliteID(cloudData.order_key!);
        orderLocalId = orderData.order_sqlite_id.toString();
      } else {
        orderLocalId = '';
      }
      OrderCache data = await PosDatabase.instance.insertOrderCache(OrderCache(
        order_cache_id: cloudData.order_cache_id,
        order_cache_key: cloudData.order_cache_key,
        company_id: cloudData.company_id,
        branch_id: cloudData.branch_id,
        order_detail_id: '',
        table_use_sqlite_id: tableUseLocalId,
        table_use_key: cloudData.table_use_key != '' && cloudData.table_use_key != null ? cloudData.table_use_key : '',
        batch_id: cloudData.batch_id,
        dining_id: cloudData.dining_id,
        order_sqlite_id: orderLocalId,
        order_key: cloudData.order_key != '' && cloudData.order_key != null ? cloudData.order_key : '',
        order_by: cloudData.order_by != '' ? cloudData.order_by : '',
        order_by_user_id: cloudData.order_by_user_id,
        cancel_by: cloudData.cancel_by != '' ? cloudData.cancel_by : '',
        cancel_by_user_id: cloudData.cancel_by_user_id != '' ? cloudData.cancel_by_user_id : '',
        customer_id: cloudData.customer_id,
        total_amount: cloudData.total_amount != '' ? cloudData.total_amount : '',
        qr_order: cloudData.qr_order,
        qr_order_table_sqlite_id: '',
        qr_order_table_id: responseJson[i]['table_id'],
        accepted: cloudData.accepted,
        sync_status: 1,
        created_at: cloudData.created_at,
        updated_at: cloudData.updated_at,
        soft_delete: cloudData.soft_delete,
      ));
    }
    getAllOrderDetail();
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
  Map data = await Domain().getAllOrderDetail(userObject['company_id'], branch_id.toString());
  if (data['status'] == '1') {
    List responseJson = data['order'];
    for (var i = 0; i < responseJson.length; i++) {
      //OrderDetail item = OrderDetail.fromJson(responseJson[i]);
      OrderCache cacheData = await PosDatabase.instance.readOrderCacheSqliteID(responseJson[i]['order_cache_key']);
      Categories? categoriesData = await PosDatabase.instance.readCategorySqliteID(responseJson[i]['category_id'].toString());
      BranchLinkProduct branchLinkProductData =
          await PosDatabase.instance.readBranchLinkProductSqliteID(responseJson[i]['branch_link_product_id'].toString());
      OrderDetail data = await PosDatabase.instance.insertOrderDetail(OrderDetail(
          order_detail_id: responseJson[i]['order_detail_id'],
          order_detail_key: responseJson[i]['order_detail_key'].toString(),
          order_cache_sqlite_id: cacheData.order_cache_sqlite_id.toString(),
          order_cache_key: responseJson[i]['order_cache_key'],
          branch_link_product_sqlite_id: branchLinkProductData.branch_link_product_sqlite_id.toString(),
          category_sqlite_id: categoriesData != null ? categoriesData.category_sqlite_id.toString() : '0',
          productName: responseJson[i]['product_name'],
          has_variant: responseJson[i]['has_variant'],
          product_variant_name: responseJson[i]['product_variant_name'],
          price: responseJson[i]['price'],
          original_price: responseJson[i]['original_price'],
          quantity: responseJson[i]['quantity'],
          remark: responseJson[i]['remark'],
          account: responseJson[i]['account'],
          cancel_by: responseJson[i]['cancel_by'],
          cancel_by_user_id: responseJson[i]['cancel_by_user_id'],
          status: responseJson[i]['status'],
          sync_status: 1,
          created_at: responseJson[i]['created_at'],
          updated_at: responseJson[i]['updated_at'],
          soft_delete: responseJson[i]['soft_delete']));
    }
    getAllOrderModifierDetail();
    getAllOrderDetailCancel();
  }
}

/*
  save order detail cancel to database
*/
getAllOrderDetailCancel() async {
  Settlement? settlement;
  final prefs = await SharedPreferences.getInstance();
  final int? branch_id = prefs.getInt('branch_id');
  final String? user = prefs.getString('user');
  Map userObject = json.decode(user!);
  Map data = await Domain().getAllOrderDetailCancel(userObject['company_id'], branch_id.toString());
  if (data['status'] == '1') {
    List responseJson = data['order'];
    for (var i = 0; i < responseJson.length; i++) {
      if (responseJson[i]['settlement_key'] != '') {
        Settlement settlementData = await PosDatabase.instance.readSettlementSqliteID(responseJson[i]['settlement_key']);
        settlement = settlementData;
      }
      OrderDetail detailData = await PosDatabase.instance.readOrderDetailSqliteID(responseJson[i]['order_detail_key']);
      OrderDetailCancel data = await PosDatabase.instance.insertOrderDetailCancel(OrderDetailCancel(
        order_detail_cancel_id: responseJson[i]['order_detail_cancel_id'],
        order_detail_cancel_key: responseJson[i]['order_detail_cancel_key'],
        order_detail_sqlite_id: detailData.order_detail_sqlite_id.toString(),
        order_detail_key: responseJson[i]['order_detail_key'],
        quantity: responseJson[i]['quantity'],
        cancel_by: responseJson[i]['cancel_by'],
        cancel_by_user_id: responseJson[i]['cancel_by_user_id'],
        settlement_sqlite_id: settlement != null ? settlement.settlement_sqlite_id.toString() : '',
        settlement_key: responseJson[i]['settlement_key'],
        status: responseJson[i]['status'],
        sync_status: 1,
        created_at: responseJson[i]['created_at'],
        updated_at: responseJson[i]['updated_at'],
        soft_delete: responseJson[i]['soft_delete'],
      ));
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
  Map data = await Domain().getAllOrderModifierDetail(userObject['company_id'], branch_id.toString());
  if (data['status'] == '1') {
    List responseJson = data['order'];
    for (var i = 0; i < responseJson.length; i++) {
      OrderDetail detailData = await PosDatabase.instance.readOrderDetailSqliteID(responseJson[i]['order_detail_key']);
      OrderModifierDetail data = await PosDatabase.instance.insertOrderModifierDetail(OrderModifierDetail(
          order_modifier_detail_id: responseJson[i]['order_modifier_detail_id'],
          order_modifier_detail_key: responseJson[i]['order_modifier_detail_key'],
          order_detail_key: responseJson[i]['order_detail_key'],
          order_detail_sqlite_id: detailData.order_detail_sqlite_id.toString(),
          order_detail_id: '0',
          mod_item_id: responseJson[i]['mod_item_id'],
          mod_name: responseJson[i]['name'],
          mod_price: responseJson[i]['price'],
          mod_group_id: responseJson[i]['mod_group_id'],
          sync_status: 1,
          created_at: responseJson[i]['created_at'],
          updated_at: responseJson[i]['updated_at'],
          soft_delete: responseJson[i]['soft_delete']));
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
  Map data = await Domain().getSale(userObject['company_id'], branch_id.toString());
  if (data['status'] == '1') {
    List responseJson = data['sale'];
    for (var i = 0; i < responseJson.length; i++) {
      Sale data = await PosDatabase.instance.insertSale(Sale.fromJson(responseJson[i]));
    }
  }
}

/*
  save cash record to database
*/
getCashRecord() async {
  final prefs = await SharedPreferences.getInstance();
  final int? branch_id = prefs.getInt('branch_id');
  final String? user = prefs.getString('user');
  Map userObject = json.decode(user!);
  Map data = await Domain().getCashRecord(userObject['company_id'], branch_id.toString());
  if (data['status'] == '1') {
    List responseJson = data['data'];
    for (var i = 0; i < responseJson.length; i++) {
      CashRecord data = await PosDatabase.instance.insertCashRecord(CashRecord(
        cash_record_id: responseJson[i]['cash_record_id'],
        cash_record_key: responseJson[i]['cash_record_key'],
        company_id: responseJson[i]['company_id'],
        branch_id: responseJson[i]['branch_id'],
        remark: responseJson[i]['remark'],
        payment_name: responseJson[i]['payment_name'],
        payment_type_id: responseJson[i]['payment_type_id'],
        type: responseJson[i]['type'],
        amount: responseJson[i]['amount'],
        user_id: responseJson[i]['user_id'],
        settlement_key: responseJson[i]['settlement_key'],
        settlement_date: responseJson[i]['settlement_date'],
        sync_status: 1,
        created_at: responseJson[i]['created_at'],
        updated_at: responseJson[i]['updated_at'],
        soft_delete: responseJson[i]['soft_delete'],
      ));
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
  final directory = await _localPath;
  final path = '$directory/assets/$folderName';
  final pathImg = Directory(path);
  await prefs.setString('local_path', path);

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
        url = 'https://pos.lkmng.com/api/gallery/' + userObject['company_id'] + '/' + name;
        final response = await http.get(Uri.parse(url));
        var localPath = path + '/' + name;
        final imageFile = File(localPath);
        await imageFile.writeAsBytes(response.bodyBytes);
      }
    }
  }
}
