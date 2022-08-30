String? tableBranchLinkProduct = 'tb_branch_link_product';

class BranchLinkProductFields {
  static List<String> values = [
    branch_link_product_sqlite_id,
    branch_link_product_id,
    branch_id,
    product_id,
    has_variant,
    product_variant_id,
    b_SKU,
    price,
    stock_type,
    daily_limit,
    daily_limit_amount,
    stock_quantity,
    created_at,
    updated_at,
    soft_delete,

  ];

  static String branch_link_product_sqlite_id = 'branch_link_product_sqlite_id';
  static String branch_link_product_id = 'branch_link_product_id';
  static String branch_id = 'branch_id';
  static String product_id = 'product_id';
  static String has_variant = 'has_variant';
  static String product_variant_id = 'product_variant_id';
  static String b_SKU = 'b_SKU';
  static String price = 'price';
  static String stock_type = 'stock_type';
  static String daily_limit = 'daily_limit';
  static String daily_limit_amount = 'daily_limit_amount';
  static String stock_quantity = 'stock_quantity';
  static String created_at = 'created_at';
  static String updated_at = 'updated_at';
  static String soft_delete = 'soft_delete';
}

class BranchLinkProduct {
  int? branch_link_product_sqlite_id;
  int? branch_link_product_id;
  String? branch_id;
  String? product_id;
  String? has_variant;
  String? product_variant_id;
  String? b_SKU;
  String? price;
  String? stock_type;
  String? daily_limit;
  String? daily_limit_amount;
  String? stock_quantity;
  String? created_at;
  String? updated_at;
  String? soft_delete;
  String? variant_name;

  BranchLinkProduct(
      {this.branch_link_product_sqlite_id,
        this.branch_link_product_id,
        this.branch_id,
        this.product_id,
        this.has_variant,
        this.product_variant_id,
        this.b_SKU,
        this.price,
        this.stock_type,
        this.daily_limit,
        this.daily_limit_amount,
        this.stock_quantity,
        this.created_at,
        this.updated_at,
        this.soft_delete,
      this.variant_name});

  BranchLinkProduct copy({
    int? branch_link_product_sqlite_id,
    int? branch_link_product_id,
    String? branch_id,
    String? product_id,
    String? has_variant,
    String? product_variant_id,
    String? b_SKU,
    String? price,
    String? stock_type,
    String? daily_limit,
    String? daily_limit_amount,
    String? stock_quantity,
    String? created_at,
    String? updated_at,
    String? soft_delete,
    String? variant_name,
  }) =>
      BranchLinkProduct(
          branch_link_product_sqlite_id: branch_link_product_sqlite_id ?? this.branch_link_product_sqlite_id,
          branch_link_product_id: branch_link_product_id ?? this.branch_link_product_id,
          branch_id: branch_id ?? this.branch_id,
          product_id: product_id ?? this.product_id,
          has_variant: has_variant ?? this.has_variant,
          product_variant_id: product_variant_id ?? this.product_variant_id,
          b_SKU: b_SKU ?? this.b_SKU,
          price: price ?? this.price,
          stock_type: stock_type ?? this.stock_type,
          daily_limit: daily_limit ?? this.daily_limit,
          daily_limit_amount: daily_limit_amount ?? this.daily_limit_amount,
          stock_quantity: stock_quantity ?? this.stock_quantity,
          created_at: created_at ?? this.created_at,
          updated_at: updated_at ?? this.updated_at,
          soft_delete: soft_delete ?? this.soft_delete,
          variant_name: variant_name ?? this.variant_name
      );

  static BranchLinkProduct fromJson(Map<String, Object?> json) => BranchLinkProduct(
    branch_link_product_sqlite_id: json[BranchLinkProductFields.branch_link_product_sqlite_id] as int?,
    branch_link_product_id: json[BranchLinkProductFields.branch_link_product_id] as int?,
    branch_id: json[BranchLinkProductFields.branch_id] as String?,
    product_id: json[BranchLinkProductFields.product_id] as String?,
    has_variant: json[BranchLinkProductFields.has_variant] as String?,
    product_variant_id: json[BranchLinkProductFields.product_variant_id] as String?,
    b_SKU: json[BranchLinkProductFields.b_SKU] as String?,
    price: json[BranchLinkProductFields.price] as String?,
    stock_type: json[BranchLinkProductFields.stock_type] as String?,
    daily_limit: json[BranchLinkProductFields.daily_limit] as String?,
    daily_limit_amount: json[BranchLinkProductFields.daily_limit_amount] as String?,
    stock_quantity: json[BranchLinkProductFields.stock_quantity] as String?,
    created_at: json[BranchLinkProductFields.created_at] as String?,
    updated_at: json[BranchLinkProductFields.updated_at] as String?,
    soft_delete: json[BranchLinkProductFields.soft_delete] as String?,
    variant_name: json['variant_name'] as String?,
  );

  Map<String, Object?> toJson() => {
    BranchLinkProductFields.branch_link_product_sqlite_id: branch_link_product_sqlite_id,
    BranchLinkProductFields.branch_link_product_id: branch_link_product_id,
    BranchLinkProductFields.branch_id: branch_id,
    BranchLinkProductFields.product_id: product_id,
    BranchLinkProductFields.has_variant: has_variant,
    BranchLinkProductFields.product_variant_id: product_variant_id,
    BranchLinkProductFields.b_SKU: b_SKU,
    BranchLinkProductFields.price: price,
    BranchLinkProductFields.stock_type: stock_type,
    BranchLinkProductFields.daily_limit: daily_limit,
    BranchLinkProductFields.daily_limit_amount: daily_limit_amount,
    BranchLinkProductFields.stock_quantity: stock_quantity,
    BranchLinkProductFields.created_at: created_at,
    BranchLinkProductFields.updated_at: updated_at,
    BranchLinkProductFields.soft_delete: soft_delete,

  };
}
