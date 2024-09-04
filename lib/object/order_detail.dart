import 'package:pos_system/object/branch_link_product.dart';
import 'package:pos_system/object/categories.dart';
import 'package:pos_system/object/modifier_item.dart';
import 'package:pos_system/object/order_modifier_detail.dart';
import 'package:pos_system/object/product_variant.dart';
import 'package:pos_system/object/variant_item.dart';

String? tableOrderDetail = 'tb_order_detail ';

class OrderDetailFields {
  static List<String> values = [
    order_detail_sqlite_id,
    order_detail_id,
    order_detail_key,
    order_cache_sqlite_id,
    order_cache_key,
    branch_link_product_sqlite_id,
    category_sqlite_id,
    category_name,
    productName,
    has_variant,
    product_variant_name,
    price,
    original_price,
    quantity,
    remark,
    account,
    edited_by,
    edited_by_user_id,
    cancel_by,
    cancel_by_user_id,
    status,
    sync_status,
    unit,
    per_quantity_unit,
    product_sku,
    created_at,
    updated_at,
    soft_delete
  ];

  static String order_detail_sqlite_id = 'order_detail_sqlite_id';
  static String order_detail_id = 'order_detail_id';
  static String order_detail_key = 'order_detail_key';
  static String order_cache_sqlite_id = 'order_cache_sqlite_id';
  static String order_cache_key = 'order_cache_key';
  static String branch_link_product_sqlite_id = 'branch_link_product_sqlite_id';
  static String category_sqlite_id = 'category_sqlite_id';
  static String category_name = 'category_name';
  static String productName = 'product_name';
  static String has_variant = 'has_variant';
  static String product_variant_name = 'product_variant_name';
  static String price = 'price';
  static String original_price = 'original_price';
  static String quantity = 'quantity';
  static String remark = 'remark';
  static String account = 'account';
  static String edited_by = 'edited_by';
  static String edited_by_user_id = 'edited_by_user_id';
  static String cancel_by = 'cancel_by';
  static String cancel_by_user_id = 'cancel_by_user_id';
  static String status = 'status';
  static String sync_status = 'sync_status';
  static String unit = 'unit';
  static String per_quantity_unit = 'per_quantity_unit';
  static String product_sku = 'product_sku';
  static String created_at = 'created_at';
  static String updated_at = 'updated_at';
  static String soft_delete = 'soft_delete';
}

class OrderDetail{
  int? order_detail_sqlite_id;
  int? order_detail_id;
  String? order_detail_key;
  String? order_cache_sqlite_id;
  String? order_cache_key;
  String? branch_link_product_sqlite_id;
  String? category_sqlite_id;
  String? category_name;
  String? productName;
  String? has_variant = '';
  String? product_variant_name = '';
  String? price = '';
  String? original_price = '';
  String? quantity;
  String? remark;
  String? account;
  String? edited_by;
  String? edited_by_user_id;
  String? cancel_by;
  String? cancel_by_user_id;
  int? status;
  int? sync_status;
  String? unit;
  String? per_quantity_unit;
  String? product_sku;
  String? created_at;
  String? updated_at;
  String? soft_delete;
  String? total_amount;
  String base_price = '0.0';
  String? product_category_id;
  String? mod_item_id;
  ProductVariant? productVariant;
  List<VariantItem> variantItem = [];
  List<ModifierItem> modifierItem = [];
  List<OrderModifierDetail> orderModifierDetail = [];
  List<String> mod_group_id = [];
  bool hasModifier = false;
  int? category_id;
  int? branch_link_product_id;
  num? category_item_sum;
  num? item_sum;
  double? category_net_sales;
  double? category_gross_sales;
  double? double_price;
  double? gross_price;
  int? total_record;
  String? available_stock;
  bool? isRemove;
  String? item_cancel;
  List<OrderDetail> categoryOrderDetailList = [];
  bool isSelected = true;
  List<String> tableNumber = [];
  String? orderQueue = '';
  String? order_number = '';
  String? branch_id = '';
  String? order_created_at = '';
  num? item_qty;
  String? failPrintBatch;
  int? allow_ticket;
  int? ticket_count;
  String? ticket_exp;

  OrderDetail(
      {this.order_detail_sqlite_id,
        this.order_detail_id,
        this.order_detail_key,
        this.order_cache_sqlite_id,
        this.order_cache_key,
        this.branch_link_product_sqlite_id,
        this.category_sqlite_id,
        this.category_name,
        this.productName,
        this.has_variant,
        this.product_variant_name,
        this.price,
        this.original_price,
        this.quantity,
        this.remark,
        this.account,
        this.edited_by,
        this.edited_by_user_id,
        this.cancel_by,
        this.cancel_by_user_id,
        this.status,
        this.sync_status,
        this.unit,
        this.per_quantity_unit,
        this.product_sku,
        this.created_at,
        this.updated_at,
        this.soft_delete,
        this.total_amount,
        this.category_id,
        this.branch_link_product_id,
        this.category_item_sum,
        this.item_sum,
        this.category_net_sales,
        this.category_gross_sales,
        this.double_price,
        this.gross_price,
        this.total_record,
        this.available_stock,
        this.isRemove,
        this.item_cancel,
        this.order_number,
        this.branch_id,
        this.order_created_at,
        this.item_qty,
        this.product_category_id,
        this.failPrintBatch,
        this.allow_ticket,
        this.ticket_count,
        this.ticket_exp,
        List<String>? tableNumber,
        bool? isSelected
      }) {
    this.tableNumber = tableNumber ?? [];
    this.isSelected = isSelected ?? true;
  }

  OrderDetail copy({
    int? order_detail_sqlite_id,
    int? order_detail_id,
    String? order_detail_key,
    String? order_cache_sqlite_id,
    String? order_cache_key,
    String? branch_link_product_sqlite_id,
    String? category_sqlite_id,
    String? category_name,
    String? productName,
    String? has_variant,
    String? product_variant_name,
    String? price,
    String? original_price,
    String? quantity,
    String? remark,
    String? account,
    String? edited_by,
    String? edited_by_user_id,
    String? cancel_by,
    String? cancel_by_user_id,
    int? status,
    int? sync_status,
    String? unit,
    String? per_quantity_unit,
    String? product_sku,
    String? created_at,
    String? updated_at,
    String? soft_delete
  }) =>
      OrderDetail(
          order_detail_sqlite_id: order_detail_sqlite_id ?? this.order_detail_sqlite_id,
          order_detail_id: order_detail_id ?? this.order_detail_id,
          order_detail_key: order_detail_key ?? this.order_detail_key,
          order_cache_sqlite_id: order_cache_sqlite_id ?? this.order_cache_sqlite_id,
          order_cache_key: order_cache_key ?? this.order_cache_key,
          branch_link_product_sqlite_id: branch_link_product_sqlite_id ?? this.branch_link_product_sqlite_id,
          category_sqlite_id: category_sqlite_id ?? this.category_sqlite_id,
          category_name: category_name ?? this.category_name,
          productName: productName ?? this.productName,
          has_variant: has_variant ?? this.has_variant,
          product_variant_name: product_variant_name ?? this.product_variant_name,
          price: price ?? this.price,
          original_price: original_price ?? this.original_price,
          quantity: quantity ?? this.quantity,
          remark: remark ?? this.remark,
          account: account ?? this.account,
          edited_by: edited_by ?? this.edited_by,
          edited_by_user_id: edited_by_user_id ?? this.edited_by_user_id,
          cancel_by: cancel_by ?? this.cancel_by,
          cancel_by_user_id: cancel_by_user_id ?? this.cancel_by_user_id,
          status: status ?? this.status,
          sync_status: sync_status ?? this.sync_status,
          unit: unit ?? this.unit,
          per_quantity_unit: per_quantity_unit ?? this.per_quantity_unit,
          product_sku: product_sku ?? this.product_sku,
          created_at: created_at ?? this.created_at,
          updated_at: updated_at ?? this.updated_at,
          soft_delete: soft_delete ?? this.soft_delete);

  static OrderDetail fromJson(Map<String, Object?> json) {
    List<String> tableNumber = [];
    var tableNumberJson = json['tableNumber'] as List?;
    if(tableNumberJson != null){
      tableNumber= List<String>.from(tableNumberJson);
    }
    return OrderDetail(
      order_detail_sqlite_id: json[OrderDetailFields.order_detail_sqlite_id] as int?,
      order_detail_id: json[OrderDetailFields.order_detail_id] as int?,
      order_detail_key: json[OrderDetailFields.order_detail_key] as String?,
      order_cache_sqlite_id: json[OrderDetailFields.order_cache_sqlite_id] as String?,
      order_cache_key: json[OrderDetailFields.order_cache_key] as String?,
      branch_link_product_sqlite_id: json[OrderDetailFields.branch_link_product_sqlite_id] as String?,
      category_sqlite_id: json[OrderDetailFields.category_sqlite_id] as String?,
      category_name: json[OrderDetailFields.category_name] as String?,
      productName: json[OrderDetailFields.productName] as String?,
      has_variant: json[OrderDetailFields.has_variant] as String?,
      product_variant_name: json[OrderDetailFields.product_variant_name] as String?,
      price: json[OrderDetailFields.price] as String?,
      original_price: json[OrderDetailFields.original_price] as String?,
      quantity: json[OrderDetailFields.quantity] as String?,
      remark: json[OrderDetailFields.remark] as String?,
      account: json[OrderDetailFields.account] as String?,
      edited_by: json[OrderDetailFields.edited_by] as String?,
      edited_by_user_id: json[OrderDetailFields.edited_by_user_id] as String?,
      cancel_by: json[OrderDetailFields.cancel_by] as String?,
      cancel_by_user_id: json[OrderDetailFields.cancel_by_user_id] as String?,
      status: json[OrderDetailFields.status] as int?,
      sync_status: json[OrderDetailFields.sync_status] as int?,
      unit: json[OrderDetailFields.unit] as String?,
      per_quantity_unit: json[OrderDetailFields.per_quantity_unit] as String?,
      product_sku: json[OrderDetailFields.product_sku] as String?,
      created_at: json[OrderDetailFields.created_at] as String?,
      updated_at: json[OrderDetailFields.updated_at] as String?,
      soft_delete: json[OrderDetailFields.soft_delete] as String?,
      total_amount: json['total_amount'] as String?,
      category_id: json['category_id'] as int?,
      branch_link_product_id: json['branch_link_product_id'] as int?,
      category_item_sum: json['category_item_sum'] as num?,
      item_sum: json['item_sum'] as num?,
      category_net_sales: json['category_net_sales'] as double?,
      category_gross_sales: json['category_gross_sales'] as double?,
      double_price: json['net_sales'] as double?,
      gross_price: json['gross_price'] as double?,
      total_record: json['total_record'] as int?,
      item_cancel: json['item_cancel'] as String?,
      order_number: json['order_number'] as String?,
      branch_id: json['branch_id'] as String?,
      order_created_at: json['order_created_at'] as String?,
      item_qty: json['item_qty'] as num?,
      product_category_id: json['product_category_id'] as String?,
      tableNumber: tableNumber,
      failPrintBatch: json['failPrintBatch'] as String?,
      isSelected: json['isSelected'] as bool?,
      allow_ticket: json['allow_ticket'] as int?,
      ticket_count: json['ticket_count'] as int?,
      ticket_exp: json['ticket_exp'] as String?
    );
  }

  Map<String, Object?> toJson() => {
    OrderDetailFields.order_detail_sqlite_id: order_detail_sqlite_id,
    OrderDetailFields.order_detail_id: order_detail_id,
    OrderDetailFields.order_detail_key: order_detail_key,
    OrderDetailFields.order_cache_sqlite_id: order_cache_sqlite_id,
    OrderDetailFields.order_cache_key: order_cache_key,
    OrderDetailFields.branch_link_product_sqlite_id: branch_link_product_sqlite_id,
    OrderDetailFields.category_sqlite_id: category_sqlite_id,
    OrderDetailFields.category_name: category_name,
    OrderDetailFields.productName: productName,
    OrderDetailFields.has_variant: has_variant,
    OrderDetailFields.product_variant_name: product_variant_name,
    OrderDetailFields.price: price,
    OrderDetailFields.original_price: original_price,
    OrderDetailFields.quantity: quantity,
    OrderDetailFields.remark: remark,
    OrderDetailFields.account: account,
    OrderDetailFields.edited_by: edited_by,
    OrderDetailFields.edited_by_user_id: edited_by_user_id,
    OrderDetailFields.cancel_by: cancel_by,
    OrderDetailFields.cancel_by_user_id: cancel_by_user_id,
    OrderDetailFields.status: status,
    OrderDetailFields.sync_status: sync_status,
    OrderDetailFields.unit: unit,
    OrderDetailFields.per_quantity_unit: per_quantity_unit,
    OrderDetailFields.product_sku: product_sku,
    OrderDetailFields.created_at: created_at,
    OrderDetailFields.updated_at: updated_at,
    OrderDetailFields.soft_delete: soft_delete,
    'product_category_id': product_category_id,
    'order_modifier_detail': orderModifierDetail,
    'tableNumber': tableNumber,
    'failPrintBatch': failPrintBatch,
    'isSelected': isSelected,
    'allow_ticket': allow_ticket,
    'ticket_count': ticket_count,
    'ticket_exp': ticket_exp
  };

  Map<String, Object?> toInsertJson() => {
    OrderDetailFields.order_detail_sqlite_id: order_detail_sqlite_id,
    OrderDetailFields.order_detail_id: order_detail_id,
    OrderDetailFields.order_detail_key: order_detail_key,
    OrderDetailFields.order_cache_sqlite_id: order_cache_sqlite_id,
    OrderDetailFields.order_cache_key: order_cache_key,
    OrderDetailFields.branch_link_product_sqlite_id: branch_link_product_sqlite_id,
    OrderDetailFields.category_sqlite_id: category_sqlite_id,
    OrderDetailFields.category_name: category_name,
    OrderDetailFields.productName: productName,
    OrderDetailFields.has_variant: has_variant,
    OrderDetailFields.product_variant_name: product_variant_name,
    OrderDetailFields.price: price,
    OrderDetailFields.original_price: original_price,
    OrderDetailFields.quantity: quantity,
    OrderDetailFields.remark: remark,
    OrderDetailFields.account: account,
    OrderDetailFields.edited_by: edited_by,
    OrderDetailFields.edited_by_user_id: edited_by_user_id,
    OrderDetailFields.cancel_by: cancel_by,
    OrderDetailFields.cancel_by_user_id: cancel_by_user_id,
    OrderDetailFields.status: status,
    OrderDetailFields.sync_status: sync_status,
    OrderDetailFields.unit: unit,
    OrderDetailFields.per_quantity_unit: per_quantity_unit,
    OrderDetailFields.product_sku: product_sku,
    OrderDetailFields.created_at: created_at,
    OrderDetailFields.updated_at: updated_at,
    OrderDetailFields.soft_delete: soft_delete
  };

  Map syncJson() => {
    OrderDetailFields.order_detail_key: order_detail_key,
    OrderDetailFields.order_cache_key: order_cache_key,
    OrderDetailFields.category_name: category_name,
    OrderDetailFields.productName: productName,
    OrderDetailFields.has_variant: has_variant,
    OrderDetailFields.product_variant_name: product_variant_name,
    OrderDetailFields.price: price,
    OrderDetailFields.original_price: original_price,
    OrderDetailFields.quantity: quantity,
    OrderDetailFields.remark: remark,
    OrderDetailFields.account: account,
    OrderDetailFields.edited_by: edited_by,
    OrderDetailFields.edited_by_user_id: edited_by_user_id,
    OrderDetailFields.cancel_by: cancel_by,
    OrderDetailFields.cancel_by_user_id: cancel_by_user_id,
    OrderDetailFields.status: status,
    OrderDetailFields.sync_status: sync_status,
    OrderDetailFields.unit: unit,
    OrderDetailFields.per_quantity_unit: per_quantity_unit,
    OrderDetailFields.product_sku: product_sku,
    OrderDetailFields.created_at: created_at,
    OrderDetailFields.updated_at: updated_at,
    OrderDetailFields.soft_delete: soft_delete,
    CategoriesFields.category_id: category_id,
    BranchLinkProductFields.branch_link_product_id: branch_link_product_id
  };
}
