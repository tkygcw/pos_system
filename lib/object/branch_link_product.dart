import 'package:pos_system/object/product.dart';

String? tableBranchLinkProduct = 'tb_branch_link_product';

class BranchLinkProductFields {
  static List<String> values = [
    branch_link_product_sqlite_id,
    branch_link_product_id,
    branch_id,
    product_sqlite_id,
    product_id,
    has_variant,
    product_variant_sqlite_id,
    product_variant_id,
    b_SKU,
    price,
    stock_type,
    daily_limit,
    daily_limit_amount,
    stock_quantity,
    sync_status,
    created_at,
    updated_at,
    soft_delete,

  ];

  static String branch_link_product_sqlite_id = 'branch_link_product_sqlite_id';
  static String branch_link_product_id = 'branch_link_product_id';
  static String branch_id = 'branch_id';
  static String product_id = 'product_id';
  static String product_sqlite_id = 'product_sqlite_id';
  static String has_variant = 'has_variant';
  static String product_variant_id = 'product_variant_id';
  static String product_variant_sqlite_id = 'product_variant_sqlite_id';
  static String b_SKU = 'b_SKU';
  static String price = 'price';
  static String stock_type = 'stock_type';
  static String daily_limit = 'daily_limit';
  static String daily_limit_amount = 'daily_limit_amount';
  static String stock_quantity = 'stock_quantity';
  static String sync_status = 'sync_status';
  static String created_at = 'created_at';
  static String updated_at = 'updated_at';
  static String soft_delete = 'soft_delete';
}

class BranchLinkProduct {
  int? branch_link_product_sqlite_id;
  int? branch_link_product_id;
  String? branch_id;
  String? product_sqlite_id;
  String? product_id;
  String? has_variant;
  String? product_variant_sqlite_id;
  String? product_variant_id;
  String? b_SKU;
  String? price;
  String? stock_type;
  String? daily_limit;
  String? daily_limit_amount;
  String? stock_quantity;
  int? sync_status;
  String? created_at;
  String? updated_at;
  String? soft_delete;
  String? variant_name;
  String? product_name;
  int? allow_ticket;
  int? ticket_count;
  String? ticket_exp;
  int? show_in_qr;

  BranchLinkProduct(
      {this.branch_link_product_sqlite_id,
        this.branch_link_product_id,
        this.branch_id,
        this.product_sqlite_id,
        this.product_id,
        this.has_variant,
        this.product_variant_sqlite_id,
        this.product_variant_id,
        this.b_SKU,
        this.price,
        this.stock_type,
        this.daily_limit,
        this.daily_limit_amount,
        this.stock_quantity,
        this.sync_status,
        this.created_at,
        this.updated_at,
        this.soft_delete,
        this.variant_name,
        this.product_name,
        this.allow_ticket,
        this.ticket_count,
        this.ticket_exp,
        this.show_in_qr
      });

  BranchLinkProduct copy({
    int? branch_link_product_sqlite_id,
    int? branch_link_product_id,
    String? branch_id,
    String? product_sqlite_id,
    String? product_id,
    String? has_variant,
    String? product_variant_sqlite_id,
    String? product_variant_id,
    String? b_SKU,
    String? price,
    String? stock_type,
    String? daily_limit,
    String? daily_limit_amount,
    String? stock_quantity,
    int? sync_status,
    String? created_at,
    String? updated_at,
    String? soft_delete,
    String? variant_name,
    String? product_name
  }) =>
      BranchLinkProduct(
          branch_link_product_sqlite_id: branch_link_product_sqlite_id ?? this.branch_link_product_sqlite_id,
          branch_link_product_id: branch_link_product_id ?? this.branch_link_product_id,
          branch_id: branch_id ?? this.branch_id,
          product_sqlite_id: product_sqlite_id ?? this.product_sqlite_id,
          product_id: product_id ?? this.product_id,
          has_variant: has_variant ?? this.has_variant,
          product_variant_id: product_variant_id ?? this.product_variant_id,
          product_variant_sqlite_id: product_variant_sqlite_id ?? this.product_variant_sqlite_id,
          b_SKU: b_SKU ?? this.b_SKU,
          price: price ?? this.price,
          stock_type: stock_type ?? this.stock_type,
          daily_limit: daily_limit ?? this.daily_limit,
          daily_limit_amount: daily_limit_amount ?? this.daily_limit_amount,
          stock_quantity: stock_quantity ?? this.stock_quantity,
          sync_status: sync_status ?? this.sync_status,
          created_at: created_at ?? this.created_at,
          updated_at: updated_at ?? this.updated_at,
          soft_delete: soft_delete ?? this.soft_delete,
          variant_name: variant_name ?? this.variant_name,
          product_name: product_name ?? this.product_name
      );

  static BranchLinkProduct fromJson(Map<String, Object?> json) => BranchLinkProduct(
      branch_link_product_sqlite_id: json[BranchLinkProductFields.branch_link_product_sqlite_id] as int?,
      branch_link_product_id: json[BranchLinkProductFields.branch_link_product_id] as int?,
      branch_id: json[BranchLinkProductFields.branch_id] as String?,
      product_sqlite_id: json[BranchLinkProductFields.product_sqlite_id] as String?,
      product_id: json[BranchLinkProductFields.product_id] as String?,
      has_variant: json[BranchLinkProductFields.has_variant] as String?,
      product_variant_id: json[BranchLinkProductFields.product_variant_id] as String?,
      product_variant_sqlite_id: json[BranchLinkProductFields.product_variant_sqlite_id] as String?,
      b_SKU: json[BranchLinkProductFields.b_SKU] as String?,
      price: json[BranchLinkProductFields.price] as String?,
      stock_type: json[BranchLinkProductFields.stock_type] as String?,
      daily_limit: json[BranchLinkProductFields.daily_limit] as String?,
      daily_limit_amount: json[BranchLinkProductFields.daily_limit_amount] as String?,
      stock_quantity: json[BranchLinkProductFields.stock_quantity] as String?,
      sync_status: json[BranchLinkProductFields.sync_status] as int?,
      created_at: json[BranchLinkProductFields.created_at] as String?,
      updated_at: json[BranchLinkProductFields.updated_at] as String?,
      soft_delete: json[BranchLinkProductFields.soft_delete] as String?,
      variant_name: json['variant_name'] as String?,
      product_name: json['name'] as String?,
      allow_ticket: json['allow_ticket'] as int?,
      ticket_count: json['ticket_count'] as int?,
      ticket_exp: json['ticket_exp'] as String?,
      show_in_qr: json[ProductFields.show_in_qr] as int?
  );

  Map<String, Object?> toJson() => {
    BranchLinkProductFields.branch_link_product_sqlite_id: branch_link_product_sqlite_id,
    BranchLinkProductFields.branch_link_product_id: branch_link_product_id,
    BranchLinkProductFields.branch_id: branch_id,
    BranchLinkProductFields.product_sqlite_id: product_sqlite_id,
    BranchLinkProductFields.product_id: product_id,
    BranchLinkProductFields.has_variant: has_variant,
    BranchLinkProductFields.product_variant_sqlite_id: product_variant_sqlite_id,
    BranchLinkProductFields.product_variant_id: product_variant_id,
    BranchLinkProductFields.b_SKU: b_SKU,
    BranchLinkProductFields.price: price,
    BranchLinkProductFields.stock_type: stock_type,
    BranchLinkProductFields.daily_limit: daily_limit,
    BranchLinkProductFields.daily_limit_amount: daily_limit_amount,
    BranchLinkProductFields.stock_quantity: stock_quantity,
    BranchLinkProductFields.sync_status: sync_status,
    BranchLinkProductFields.created_at: created_at,
    BranchLinkProductFields.updated_at: updated_at,
    BranchLinkProductFields.soft_delete: soft_delete,
  };
}
