String? tableVariantGroup = 'tb_variant_group ';

class VariantGroupFields {
  static List<String> values = [
    variant_group_id,
    product_id,
    name,
    created_at,
    updated_at,
    soft_delete
  ];

  static String variant_group_id = 'variant_group_id';
  static String product_id = 'product_id';
  static String name = 'name';
  static String created_at = 'created_at';
  static String updated_at = 'updated_at';
  static String soft_delete = 'soft_delete';
}

class VariantGroup{
  int? variant_group_id;
  String? product_id;
  String? name;
  String? created_at;
  String? updated_at;
  String? soft_delete;

  VariantGroup(
      {this.variant_group_id,
        this.product_id,
        this.name,
        this.created_at,
        this.updated_at,
        this.soft_delete});

  VariantGroup copy({
    int? variant_group_id,
    String? product_id,
    String? name,
    String? created_at,
    String? updated_at,
    String? soft_delete,
  }) =>
      VariantGroup(
          variant_group_id: variant_group_id ?? this.variant_group_id,
          product_id: product_id ?? this.product_id,
          name: name ?? this.name,
          created_at: created_at ?? this.created_at,
          updated_at: updated_at ?? this.updated_at,
          soft_delete: soft_delete ?? this.soft_delete);

  static VariantGroup fromJson(Map<String, Object?> json) => VariantGroup  (
    variant_group_id: json[VariantGroupFields.variant_group_id] as int?,
    product_id: json[VariantGroupFields.product_id] as String?,
    name: json[VariantGroupFields.name] as String?,
    created_at: json[VariantGroupFields.created_at] as String?,
    updated_at: json[VariantGroupFields.updated_at] as String?,
    soft_delete: json[VariantGroupFields .soft_delete] as String?,
  );

  Map<String, Object?> toJson() => {
    VariantGroupFields.variant_group_id: variant_group_id,
    VariantGroupFields.product_id: product_id,
    VariantGroupFields.name: name,
    VariantGroupFields.created_at: created_at,
    VariantGroupFields.updated_at: updated_at,
    VariantGroupFields.soft_delete: soft_delete,
  };
}
