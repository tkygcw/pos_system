String? tableModifierLinkProduct = 'tb_modifier_link_product';

class ModifierLinkProductFields {
  static List<String> values = [
    modifier_link_product_sqlite_id,
    modifier_link_product_id,
    mod_group_id,
    product_id,
    product_sqlite_id,
    sync_status,
    created_at,
    updated_at,
    soft_delete
  ];

  static String modifier_link_product_sqlite_id = 'modifier_link_product_sqlite_id';
  static String modifier_link_product_id = 'modifier_link_product_id';
  static String mod_group_id = 'mod_group_id';
  static String product_id = 'product_id';
  static String product_sqlite_id = 'product_sqlite_id';
  static String sync_status = 'sync_status';
  static String created_at = 'created_at';
  static String updated_at = 'updated_at';
  static String soft_delete = 'soft_delete';
}

class ModifierLinkProduct{
  int? modifier_link_product_sqlite_id;
  int? modifier_link_product_id;
  String? mod_group_id;
  String? product_id;
  String? product_sqlite_id;
  int? sync_status;
  String? created_at;
  String? updated_at;
  String? soft_delete;

  ModifierLinkProduct(
      { this.modifier_link_product_sqlite_id,
        this.modifier_link_product_id,
        this.mod_group_id,
        this.product_id,
        this.product_sqlite_id,
        this.sync_status,
        this.created_at,
        this.updated_at,
        this.soft_delete});

  ModifierLinkProduct copy({
    int? modifier_link_product_sqlite_id,
    int? modifier_link_product_id,
    String? mod_group_id,
    String? product_id,
    String? product_sqlite_id,
    int? sync_status,
    String? created_at,
    String? updated_at,
    String? soft_delete,
  }) =>
      ModifierLinkProduct(
          modifier_link_product_sqlite_id: modifier_link_product_sqlite_id ?? this.modifier_link_product_sqlite_id,
          modifier_link_product_id: modifier_link_product_id ?? this.modifier_link_product_id,
          mod_group_id: mod_group_id ?? this.mod_group_id,
          product_id: product_id ?? this.product_id,
          product_sqlite_id: product_sqlite_id ?? this.product_sqlite_id,
          sync_status: sync_status ?? this.sync_status,
          created_at: created_at ?? this.created_at,
          updated_at: updated_at ?? this.updated_at,
          soft_delete: soft_delete ?? this.soft_delete);

  static ModifierLinkProduct fromJson(Map<String, Object?> json) => ModifierLinkProduct(
    modifier_link_product_sqlite_id: json[ModifierLinkProductFields.modifier_link_product_sqlite_id] as int?,
    modifier_link_product_id: json[ModifierLinkProductFields.modifier_link_product_id] as int?,
    mod_group_id: json[ModifierLinkProductFields.mod_group_id] as String?,
    product_id: json[ModifierLinkProductFields.product_id] as String?,
    product_sqlite_id: json[ModifierLinkProductFields.product_sqlite_id] as String?,
    sync_status: json[ModifierLinkProductFields.sync_status] as int?,
    created_at: json[ModifierLinkProductFields.created_at] as String?,
    updated_at: json[ModifierLinkProductFields.updated_at] as String?,
    soft_delete: json[ModifierLinkProductFields.soft_delete] as String?,
  );

  Map<String, Object?> toJson() => {
    ModifierLinkProductFields.modifier_link_product_sqlite_id: modifier_link_product_sqlite_id,
    ModifierLinkProductFields.modifier_link_product_id: modifier_link_product_id,
    ModifierLinkProductFields.mod_group_id: mod_group_id,
    ModifierLinkProductFields.product_id: product_id,
    ModifierLinkProductFields.product_sqlite_id: product_sqlite_id,
    ModifierLinkProductFields.sync_status: sync_status,
    ModifierLinkProductFields.created_at: created_at,
    ModifierLinkProductFields.updated_at: updated_at,
    ModifierLinkProductFields.soft_delete: soft_delete,
  };
}
