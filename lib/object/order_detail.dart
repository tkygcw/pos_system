import 'package:pos_system/object/categories.dart';
import 'package:pos_system/object/modifier_item.dart';
import 'package:pos_system/object/order_modifier_detail.dart';
import 'package:pos_system/object/product_variant.dart';
import 'package:pos_system/object/variant_item.dart';

import 'modifier_group.dart';

String? tableOrderDetail = 'tb_order_detail ';

class OrderDetailFields {
  static List<String> values = [
    order_detail_sqlite_id,
    order_detail_id,
    order_cache_sqlite_id,
    branch_link_product_sqlite_id,
    category_sqlite_id,
    productName,
    has_variant,
    product_variant_name,
    price,
    quantity,
    remark,
    account,
    cancel_by,
    cancel_by_user_id,
    sync_status,
    created_at,
    updated_at,
    soft_delete
  ];

  static String order_detail_sqlite_id = 'order_detail_sqlite_id';
  static String order_detail_id = 'order_detail_id';
  static String order_cache_sqlite_id = 'order_cache_sqlite_id';
  static String branch_link_product_sqlite_id = 'branch_link_product_sqlite_id';
  static String category_sqlite_id = 'category_sqlite_id';
  static String productName = 'product_name';
  static String has_variant = 'has_variant';
  static String product_variant_name = 'product_variant_name';
  static String price = 'price';
  static String quantity = 'quantity';
  static String remark = 'remark';
  static String account = 'account';
  static String cancel_by = 'cancel_by';
  static String cancel_by_user_id = 'cancel_by_user_id';
  static String sync_status = 'sync_status';
  static String created_at = 'created_at';
  static String updated_at = 'updated_at';
  static String soft_delete = 'soft_delete';
}

class OrderDetail{
  int? order_detail_sqlite_id;
  int? order_detail_id;
  String? order_cache_sqlite_id;
  String? branch_link_product_sqlite_id;
  String? category_sqlite_id;
  String? productName = '';
  String? has_variant = '';
  String? product_variant_name = '';
  String? price = '';
  String? quantity;
  String? remark;
  String? account;
  String? cancel_by;
  String? cancel_by_user_id;
  int? sync_status;
  String? created_at;
  String? updated_at;
  String? soft_delete;
  String? total_amount;
  String base_price = '0.0';
  String? category_id;
  String product_name = '';
  String? mod_item_id;
  ProductVariant? productVariant ;
  List<VariantItem> variantItem = [];
  List<ModifierItem> modifierItem = [];
  List<String> mod_group_id = [];
  bool hasModifier = false;

  OrderDetail(
      {this.order_detail_sqlite_id,
        this.order_detail_id,
        this.order_cache_sqlite_id,
        this.branch_link_product_sqlite_id,
        this.category_sqlite_id,
        this.productName,
        this.has_variant,
        this.product_variant_name,
        this.price,
        this.quantity,
        this.remark,
        this.account,
        this.cancel_by,
        this.cancel_by_user_id,
        this.sync_status,
        this.created_at,
        this.updated_at,
        this.soft_delete,
        this.total_amount});

  OrderDetail copy({
    int? order_detail_sqlite_id,
    int? order_detail_id,
    String? order_cache_sqlite_id,
    String? branch_link_product_sqlite_id,
    String? category_sqlite_id,
    String? productName,
    String? has_variant,
    String? product_variant_name,
    String? price,
    String? quantity,
    String? remark,
    String? account,
    String? cancel_by,
    String? cancel_by_user_id,
    int? sync_status,
    String? created_at,
    String? updated_at,
    String? soft_delete,
  }) =>
      OrderDetail(
          order_detail_sqlite_id: order_detail_sqlite_id ?? this.order_detail_sqlite_id,
          order_detail_id: order_detail_id ?? this.order_detail_id,
          order_cache_sqlite_id: order_cache_sqlite_id ?? this.order_cache_sqlite_id,
          branch_link_product_sqlite_id: branch_link_product_sqlite_id ?? this.branch_link_product_sqlite_id,
          category_sqlite_id: category_sqlite_id ?? this.category_sqlite_id,
          productName: productName ?? this.productName,
          has_variant: has_variant ?? this.has_variant,
          product_variant_name: product_variant_name ?? this.product_variant_name,
          price: price ?? this.price,
          quantity: quantity ?? this.quantity,
          remark: remark ?? this.remark,
          account: account ?? this.account,
          cancel_by: cancel_by ?? this.cancel_by,
          cancel_by_user_id: cancel_by_user_id ?? this.cancel_by_user_id,
          sync_status: sync_status ?? this.sync_status,
          created_at: created_at ?? this.created_at,
          updated_at: updated_at ?? this.updated_at,
          soft_delete: soft_delete ?? this.soft_delete,
          total_amount: total_amount ?? this.total_amount);

  static OrderDetail fromJson(Map<String, Object?> json) => OrderDetail(
    order_detail_sqlite_id: json[OrderDetailFields.order_detail_sqlite_id] as int?,
    order_detail_id: json[OrderDetailFields.order_detail_id] as int?,
    order_cache_sqlite_id: json[OrderDetailFields.order_cache_sqlite_id] as String?,
    branch_link_product_sqlite_id: json[OrderDetailFields.branch_link_product_sqlite_id] as String?,
    category_sqlite_id: json[OrderDetailFields.category_sqlite_id] as String?,
    productName: json[OrderDetailFields.productName] as String?,
    has_variant: json[OrderDetailFields.has_variant] as String?,
    product_variant_name: json[OrderDetailFields.product_variant_name] as String?,
    price: json[OrderDetailFields.price] as String?,
    quantity: json[OrderDetailFields.quantity] as String?,
    remark: json[OrderDetailFields.remark] as String?,
    account: json[OrderDetailFields.account] as String?,
    cancel_by: json[OrderDetailFields.cancel_by] as String?,
    cancel_by_user_id: json[OrderDetailFields.cancel_by_user_id] as String?,
    sync_status: json[OrderDetailFields.sync_status] as int?,
    created_at: json[OrderDetailFields.created_at] as String?,
    updated_at: json[OrderDetailFields.updated_at] as String?,
    soft_delete: json[OrderDetailFields.soft_delete] as String?,
    total_amount: json['total_amount'] as String?
  );

  Map<String, Object?> toJson() => {
    OrderDetailFields.order_detail_sqlite_id: order_detail_sqlite_id,
    OrderDetailFields.order_detail_id: order_detail_id,
    OrderDetailFields.order_cache_sqlite_id: order_cache_sqlite_id,
    OrderDetailFields.branch_link_product_sqlite_id: branch_link_product_sqlite_id,
    OrderDetailFields.category_sqlite_id: category_sqlite_id,
    OrderDetailFields.productName: productName,
    OrderDetailFields.has_variant: has_variant,
    OrderDetailFields.product_variant_name: product_variant_name,
    OrderDetailFields.price: price,
    OrderDetailFields.quantity: quantity,
    OrderDetailFields.remark: remark,
    OrderDetailFields.account: account,
    OrderDetailFields.cancel_by: cancel_by,
    OrderDetailFields.cancel_by_user_id: cancel_by_user_id,
    OrderDetailFields.sync_status: sync_status,
    OrderDetailFields.created_at: created_at,
    OrderDetailFields.updated_at: updated_at,
    OrderDetailFields.soft_delete: soft_delete,
  };
}
