String? tableVariantItem = 'tb_variant_item ';

class VariantItemFields {
  static List<String> values = [
    variant_item_id,
    variant_group_id,
    name,
    created_at,
    updated_at,
    soft_delete
  ];

  static String variant_item_id = 'variant_item_id';
  static String variant_group_id = 'variant_group_id';
  static String name = 'name';
  static String created_at = 'created_at';
  static String updated_at = 'updated_at';
  static String soft_delete = 'soft_delete';
}

class VariantItem{
  int? variant_item_id;
  String? variant_group_id;
  String? name;
  String? created_at;
  String? updated_at;
  String? soft_delete;

  VariantItem(
      {this.variant_item_id,
        this.variant_group_id,
        this.name,
        this.created_at,
        this.updated_at,
        this.soft_delete});

  VariantItem copy({
    int? variant_item_id,
    String? variant_group_id,
    String? name,
    String? created_at,
    String? updated_at,
    String? soft_delete,
  }) =>
      VariantItem(
          variant_item_id: variant_item_id ?? this.variant_item_id,
          variant_group_id: variant_group_id ?? this.variant_group_id,
          name: name ?? this.name,
          created_at: created_at ?? this.created_at,
          updated_at: updated_at ?? this.updated_at,
          soft_delete: soft_delete ?? this.soft_delete);

  static VariantItem fromJson(Map<String, Object?> json) => VariantItem  (
    variant_item_id: json[VariantItemFields.variant_item_id] as int?,
    variant_group_id: json[VariantItemFields.variant_group_id] as String?,
    name: json[VariantItemFields.name] as String?,
    created_at: json[VariantItemFields.created_at] as String?,
    updated_at: json[VariantItemFields.updated_at] as String?,
    soft_delete: json[VariantItemFields .soft_delete] as String?,
  );

  Map<String, Object?> toJson() => {
    VariantItemFields.variant_item_id: variant_item_id,
    VariantItemFields.variant_group_id: variant_group_id,
    VariantItemFields.name: name,
    VariantItemFields.created_at: created_at,
    VariantItemFields.updated_at: updated_at,
    VariantItemFields.soft_delete: soft_delete,
  };
}
