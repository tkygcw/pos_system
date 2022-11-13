String? tableProductVariant = 'tb_product_variant ';

class ProductVariantFields {
  static List<String> values = [
    product_variant_sqlite_id,
    product_variant_id,
    product_sqlite_id,
    product_id,
    variant_name,
    SKU,
    price,
    stock_type,
    daily_limit,
    daily_limit_amount,
    stock_quantity,
    sync_status,
    created_at,
    updated_at,
    soft_delete
  ];
  static String product_variant_sqlite_id = 'product_variant_sqlite_id';
  static String product_variant_id = 'product_variant_id';
  static String product_sqlite_id = 'product_sqlite_id';
  static String product_id = 'product_id';
  static String variant_name = 'variant_name';
  static String SKU = 'SKU';
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

class ProductVariant {
  int? product_variant_sqlite_id;
  int? product_variant_id;
  String?  product_sqlite_id;
  String? product_id;
  String? variant_name;
  String? SKU;
  String? price;
  String? stock_type;
  String? daily_limit;
  String? daily_limit_amount;
  String? stock_quantity;
  int? sync_status;
  String? created_at;
  String? updated_at;
  String? soft_delete;

  ProductVariant(
      {this.product_variant_sqlite_id,
      this.product_variant_id,
      this.product_sqlite_id,
      this.product_id,
      this.variant_name,
      this.SKU,
      this.price,
      this.stock_type,
      this.daily_limit,
      this.daily_limit_amount,
      this.stock_quantity,
      this.sync_status,
      this.created_at,
      this.updated_at,
      this.soft_delete});

  ProductVariant copy({
    int? product_variant_sqlite_id,
    int? product_variant_id,
    String? product_sqlite_id,
    String? product_id,
    String? variant_name,
    String? SKU,
    String? price,
    String? stock_type,
    String? daily_limit,
    String? daily_limit_amount,
    String? stock_quantity,
    int? sync_status,
    String? created_at,
    String? updated_at,
    String? soft_delete,
  }) =>
      ProductVariant(
          product_variant_sqlite_id:
              product_variant_sqlite_id ?? this.product_variant_sqlite_id,
          product_variant_id: product_variant_id ?? this.product_variant_id,
          product_sqlite_id: product_sqlite_id ?? this.product_sqlite_id,
          product_id: product_id ?? this.product_id,
          variant_name: variant_name ?? this.variant_name,
          SKU: SKU ?? this.SKU,
          price: price ?? this.price,
          stock_type: stock_type ?? this.stock_type,
          daily_limit: daily_limit ?? this.daily_limit,
          daily_limit_amount: daily_limit_amount ?? this.daily_limit_amount,
          stock_quantity: stock_quantity ?? this.stock_quantity,
          sync_status: sync_status ?? this.sync_status,
          created_at: created_at ?? this.created_at,
          updated_at: updated_at ?? this.updated_at,
          soft_delete: soft_delete ?? this.soft_delete);

  static ProductVariant fromJson(Map<String, Object?> json) => ProductVariant(
        product_variant_sqlite_id:
            json[ProductVariantFields.product_variant_sqlite_id] as int?,
        product_variant_id:
            json[ProductVariantFields.product_variant_id] as int?,
    product_sqlite_id: json[ProductVariantFields.product_sqlite_id] as String?,
        product_id: json[ProductVariantFields.product_id] as String?,
        variant_name: json[ProductVariantFields.variant_name] as String?,
        SKU: json[ProductVariantFields.SKU] as String?,
        price: json[ProductVariantFields.price] as String?,
        stock_type: json[ProductVariantFields.stock_type] as String?,
        daily_limit: json[ProductVariantFields.daily_limit] as String?,
        daily_limit_amount:
            json[ProductVariantFields.daily_limit_amount] as String?,
        stock_quantity: json[ProductVariantFields.stock_quantity] as String?,
        sync_status: json[ProductVariantFields.sync_status] as int?,
        created_at: json[ProductVariantFields.created_at] as String?,
        updated_at: json[ProductVariantFields.updated_at] as String?,
        soft_delete: json[ProductVariantFields.soft_delete] as String?,
      );

  Map<String, Object?> toJson() => {
        ProductVariantFields.product_variant_sqlite_id:
            product_variant_sqlite_id,
        ProductVariantFields.product_variant_id: product_variant_id,
    ProductVariantFields.product_sqlite_id: product_sqlite_id,
        ProductVariantFields.product_id: product_id,
        ProductVariantFields.variant_name: variant_name,
        ProductVariantFields.SKU: SKU,
        ProductVariantFields.price: price,
        ProductVariantFields.stock_type: stock_type,
        ProductVariantFields.daily_limit: daily_limit,
        ProductVariantFields.daily_limit_amount: daily_limit_amount,
        ProductVariantFields.stock_quantity: stock_quantity,
        ProductVariantFields.sync_status: sync_status,
        ProductVariantFields.created_at: created_at,
        ProductVariantFields.updated_at: updated_at,
        ProductVariantFields.soft_delete: soft_delete,
      };
}
