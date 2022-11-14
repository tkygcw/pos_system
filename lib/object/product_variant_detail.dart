String? tableProductVariantDetail = 'tb_product_variant_detail';

class ProductVariantDetailFields {
  static List<String> values = [
    product_variant_detail_sqlite_id,
    product_variant_detail_id,
    product_variant_sqlite_id,
    product_variant_id,
    variant_item_sqlite_id,
    variant_item_id,
    created_at,
    updated_at,
    soft_delete
  ];

  static String product_variant_detail_sqlite_id = 'product_variant_detail_sqlite_id';
  static String product_variant_detail_id = 'product_variant_detail_id';
  static String product_variant_sqlite_id = 'product_variant_sqlite_id';
  static String product_variant_id = 'product_variant_id';
  static String variant_item_sqlite_id = 'variant_item_sqlite_id';
  static String variant_item_id = 'variant_item_id';
  static String created_at = 'created_at';
  static String updated_at = 'updated_at';
  static String soft_delete = 'soft_delete';
}

class ProductVariantDetail {
  int? product_variant_detail_sqlite_id;
  int? product_variant_detail_id;
  String? product_variant_sqlite_id;
  String? product_variant_id;
  String? variant_item_sqlite_id;
  String? variant_item_id;
  String? created_at;
  String? updated_at;
  String? soft_delete;

  ProductVariantDetail(
      {this.product_variant_detail_sqlite_id,
      this.product_variant_detail_id,
      this.product_variant_sqlite_id,
      this.product_variant_id,
      this.variant_item_sqlite_id,
      this.variant_item_id,
      this.created_at,
      this.updated_at,
      this.soft_delete});

  ProductVariantDetail copy({
    int? product_variant_detail_sqlite_id,
    int? product_variant_detail_id,
    String? product_variant_sqlite_id,
    String? product_variant_id,
    String? variant_item_sqlite_id,
    String? variant_item_id,
    String? created_at,
    String? updated_at,
    String? soft_delete,
  }) =>
      ProductVariantDetail(
          product_variant_detail_sqlite_id: product_variant_detail_sqlite_id ?? this.product_variant_detail_sqlite_id,
          product_variant_detail_id: product_variant_detail_id ?? this.product_variant_detail_id,
          product_variant_sqlite_id: product_variant_sqlite_id ?? this.product_variant_sqlite_id,
          product_variant_id: product_variant_id ?? this.product_variant_id,
          variant_item_sqlite_id: variant_item_sqlite_id ?? this.variant_item_sqlite_id,
          variant_item_id: variant_item_id ?? this.variant_item_id,
          created_at: created_at ?? this.created_at,
          updated_at: updated_at ?? this.updated_at,
          soft_delete: soft_delete ?? this.soft_delete);

  static ProductVariantDetail fromJson(Map<String, Object?> json) =>
      ProductVariantDetail(
        product_variant_detail_sqlite_id:
            json[ProductVariantDetailFields.product_variant_detail_sqlite_id]
                as int?,
        product_variant_detail_id:
            json[ProductVariantDetailFields.product_variant_detail_id] as int?,
        product_variant_id:
        json[ProductVariantDetailFields.product_variant_sqlite_id] as String?,
        product_variant_sqlite_id:
            json[ProductVariantDetailFields.product_variant_id] as String?,
        variant_item_id:
            json[ProductVariantDetailFields.variant_item_sqlite_id] as String?,
        variant_item_sqlite_id:
        json[ProductVariantDetailFields.variant_item_id] as String?,
        created_at: json[ProductVariantDetailFields.created_at] as String?,
        updated_at: json[ProductVariantDetailFields.updated_at] as String?,
        soft_delete: json[ProductVariantDetailFields.soft_delete] as String?,
      );

  Map<String, Object?> toJson() => {
        ProductVariantDetailFields.product_variant_detail_sqlite_id:
            product_variant_detail_sqlite_id,
        ProductVariantDetailFields.product_variant_detail_id:
            product_variant_detail_id,
        ProductVariantDetailFields.product_variant_id: product_variant_id,
        ProductVariantDetailFields.variant_item_id: variant_item_id,
        ProductVariantDetailFields.created_at: created_at,
        ProductVariantDetailFields.updated_at: updated_at,
        ProductVariantDetailFields.soft_delete: soft_delete,
      };
}
