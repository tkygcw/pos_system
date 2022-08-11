String? tableModifierGroup = 'tb_modifier_group';

class ModifierGroupFields {
  static List<String> values = [
    mod_group_id,
    company_id,
    name,
    created_at,
    updated_at,
    soft_delete
  ];

  static String mod_group_id = 'mod_group_id';
  static String company_id = 'company_id';
  static String name = 'name';
  static String created_at = 'created_at';
  static String updated_at = 'updated_at';
  static String soft_delete = 'soft_delete';
}

class ModifierGroup{
  int? mod_group_id;
  String? company_id;
  String? name;
  String? created_at;
  String? updated_at;
  String? soft_delete;

  ModifierGroup(
      {this.mod_group_id,
        this.company_id,
        this.name,
        this.created_at,
        this.updated_at,
        this.soft_delete});

  ModifierGroup copy({
    int? mod_group_id,
    String? company_id,
    String? name,
    String? created_at,
    String? updated_at,
    String? soft_delete,
  }) =>
      ModifierGroup(
          mod_group_id: mod_group_id ?? this.mod_group_id,
          company_id: company_id ?? this.company_id,
          name: name ?? this.name,
          created_at: created_at ?? this.created_at,
          updated_at: updated_at ?? this.updated_at,
          soft_delete: soft_delete ?? this.soft_delete);

  static ModifierGroup fromJson(Map<String, Object?> json) => ModifierGroup(
    mod_group_id: json[ModifierGroupFields.mod_group_id] as int?,
    company_id: json[ModifierGroupFields.company_id] as String?,
    name: json[ModifierGroupFields.name] as String?,
    created_at: json[ModifierGroupFields.created_at] as String?,
    updated_at: json[ModifierGroupFields.updated_at] as String?,
    soft_delete: json[ModifierGroupFields.soft_delete] as String?,
  );

  Map<String, Object?> toJson() => {
    ModifierGroupFields.mod_group_id: mod_group_id,
    ModifierGroupFields.company_id: company_id,
    ModifierGroupFields.name: name,
    ModifierGroupFields.created_at: created_at,
    ModifierGroupFields.updated_at: updated_at,
    ModifierGroupFields.soft_delete: soft_delete,
  };
}
