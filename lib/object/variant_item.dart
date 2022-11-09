String? tableVariantItem = 'tb_variant_item ';

class VariantItemFields {
  static List<String> values = [
    variant_item_sqlite_id,
    variant_item_id,
    variant_group_id,
    variant_group_sqlite_id,
    name,
    sync_status,
    created_at,
    updated_at,
    soft_delete
  ];

  static String variant_item_sqlite_id = 'variant_item_sqlite_id';
  static String variant_item_id = 'variant_item_id';
  static String variant_group_id = 'variant_group_id';
  static String variant_group_sqlite_id = 'variant_group_sqlite_id';
  static String name = 'name';
  static String isSelected = 'selected';
  static String sync_status = 'sync_status';
  static String created_at = 'created_at';
  static String updated_at = 'updated_at';
  static String soft_delete = 'soft_delete';
}

class VariantItem {
  int? variant_item_sqlite_id;
  int? variant_item_id;
  String? variant_group_id;
  String? variant_group_sqlite_id;
  String? name;
  int? sync_status;
  String? created_at;
  String? updated_at;
  String? soft_delete;
  bool? isSelected;

  VariantItem(
      {this.variant_item_sqlite_id,
      this.variant_item_id,
      this.variant_group_id,
        this.variant_group_sqlite_id,
      this.name,
      this.isSelected,
      this.sync_status,
      this.created_at,
      this.updated_at,
      this.soft_delete});

  VariantItem copy({
    int? variant_item_sqlite_id,
    int? variant_item_id,
    String? variant_group_id,
    String? variant_group_sqlite_id,
    String? name,
    int? sync_status,
    String? created_at,
    String? updated_at,
    String? soft_delete,
  }) =>
      VariantItem(
          variant_item_sqlite_id:
              variant_item_sqlite_id ?? this.variant_item_sqlite_id,
          variant_item_id: variant_item_id ?? this.variant_item_id,
          variant_group_id: variant_group_id ?? this.variant_group_id,
          variant_group_sqlite_id: variant_group_sqlite_id ?? this.variant_group_sqlite_id,
          name: name ?? this.name,
          sync_status: sync_status ?? this.sync_status,
          created_at: created_at ?? this.created_at,
          updated_at: updated_at ?? this.updated_at,
          soft_delete: soft_delete ?? this.soft_delete);

  static VariantItem fromJson(Map<String, Object?> json) => VariantItem(
        variant_item_sqlite_id:
            json[VariantItemFields.variant_item_sqlite_id] as int?,
        variant_item_id: json[VariantItemFields.variant_item_id] as int?,
        variant_group_id: json[VariantItemFields.variant_group_id] as String?,
    variant_group_sqlite_id: json[VariantItemFields.variant_group_sqlite_id] as String?,
        name: json[VariantItemFields.name] as String?,
        sync_status: json[VariantItemFields.sync_status] as int?,
        created_at: json[VariantItemFields.created_at] as String?,
        updated_at: json[VariantItemFields.updated_at] as String?,
        soft_delete: json[VariantItemFields.soft_delete] as String?,
      );

  Map<String, Object?> toJson() => {
        VariantItemFields.variant_item_sqlite_id: variant_item_sqlite_id,
        VariantItemFields.variant_item_id: variant_item_id,
        VariantItemFields.variant_group_id: variant_group_id,
    VariantItemFields.variant_group_sqlite_id: variant_group_sqlite_id,
        VariantItemFields.name: name,
        VariantItemFields.sync_status: sync_status,
        VariantItemFields.created_at: created_at,
        VariantItemFields.updated_at: updated_at,
        VariantItemFields.soft_delete: soft_delete,
      };

  Map<String, Object?> addToCartJSon() => {
        VariantItemFields.name: name,
        VariantItemFields.isSelected: isSelected,
      };
}
