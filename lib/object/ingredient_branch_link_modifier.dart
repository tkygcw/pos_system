String? tableIngredientBranchLinkModifier = 'tb_ingredient_branch_link_modifier';

class IngredientBranchLinkModifierFields {
  static List<String> values = [
    ingredient_branch_link_modifier_sqlite_id,
    ingredient_branch_link_modifier_id,
    ingredient_company_link_branch_id,
    branch_link_modifier_id,
    ingredient_usage,
    sync_status,
    created_at,
    updated_at,
    soft_delete,
  ];

  static String ingredient_branch_link_modifier_sqlite_id = 'ingredient_branch_link_modifier_sqlite_id';
  static String ingredient_branch_link_modifier_id = 'ingredient_branch_link_modifier_id';
  static String ingredient_company_link_branch_id = 'ingredient_company_link_branch_id';
  static String branch_link_modifier_id = 'branch_link_modifier_id';
  static String ingredient_usage = 'ingredient_usage';
  static String sync_status = 'sync_status';
  static String created_at = 'created_at';
  static String updated_at = 'updated_at';
  static String soft_delete = 'soft_delete';
}

class IngredientBranchLinkModifier {
  int? ingredient_branch_link_modifier_sqlite_id;
  int? ingredient_branch_link_modifier_id;
  String? ingredient_company_link_branch_id;
  String? branch_link_modifier_id;
  String? ingredient_usage;
  int? sync_status;
  String? created_at;
  String? updated_at;
  String? soft_delete;

  IngredientBranchLinkModifier(
      {this.ingredient_branch_link_modifier_sqlite_id,
        this.ingredient_branch_link_modifier_id,
        this.ingredient_company_link_branch_id,
        this.branch_link_modifier_id,
        this.ingredient_usage,
        this.sync_status,
        this.created_at,
        this.updated_at,
        this.soft_delete,
      });

  IngredientBranchLinkModifier copy({
    int? ingredient_branch_link_modifier_sqlite_id,
    int? ingredient_branch_link_modifier_id,
    String? ingredient_company_link_branch_id,
    String? branch_link_modifier_id,
    String? ingredient_usage,
    int? sync_status,
    String? created_at,
    String? updated_at,
    String? soft_delete,
  }) =>
      IngredientBranchLinkModifier(
        ingredient_branch_link_modifier_sqlite_id: ingredient_branch_link_modifier_sqlite_id ?? this.ingredient_branch_link_modifier_sqlite_id,
        ingredient_branch_link_modifier_id: ingredient_branch_link_modifier_id ?? this.ingredient_branch_link_modifier_id,
        ingredient_company_link_branch_id: ingredient_company_link_branch_id ?? this.ingredient_company_link_branch_id,
        branch_link_modifier_id: branch_link_modifier_id ?? this.branch_link_modifier_id,
        ingredient_usage: ingredient_usage ?? this.ingredient_usage,
        sync_status: sync_status ?? this.sync_status,
        created_at: created_at ?? this.created_at,
        updated_at: updated_at ?? this.updated_at,
        soft_delete: soft_delete ?? this.soft_delete,
      );

  static IngredientBranchLinkModifier fromJson(Map<String, Object?> json) => IngredientBranchLinkModifier(
    ingredient_branch_link_modifier_sqlite_id: json[IngredientBranchLinkModifierFields.ingredient_branch_link_modifier_sqlite_id] as int?,
    ingredient_branch_link_modifier_id: json[IngredientBranchLinkModifierFields.ingredient_branch_link_modifier_id] as int?,
    ingredient_company_link_branch_id: json[IngredientBranchLinkModifierFields.ingredient_company_link_branch_id] as String?,
    branch_link_modifier_id: json[IngredientBranchLinkModifierFields.branch_link_modifier_id] as String?,
    ingredient_usage: json[IngredientBranchLinkModifierFields.ingredient_usage] as String?,
    sync_status: json[IngredientBranchLinkModifierFields.sync_status] as int?,
    created_at: json[IngredientBranchLinkModifierFields.created_at] as String?,
    updated_at: json[IngredientBranchLinkModifierFields.updated_at] as String?,
    soft_delete: json[IngredientBranchLinkModifierFields.soft_delete] as String?,
  );

  Map<String, Object?> toJson() => {
    IngredientBranchLinkModifierFields.ingredient_branch_link_modifier_sqlite_id: ingredient_branch_link_modifier_sqlite_id,
    IngredientBranchLinkModifierFields.ingredient_branch_link_modifier_id: ingredient_branch_link_modifier_id,
    IngredientBranchLinkModifierFields.ingredient_company_link_branch_id: ingredient_company_link_branch_id,
    IngredientBranchLinkModifierFields.branch_link_modifier_id: branch_link_modifier_id,
    IngredientBranchLinkModifierFields.ingredient_usage: ingredient_usage,
    IngredientBranchLinkModifierFields.sync_status: sync_status,
    IngredientBranchLinkModifierFields.created_at: created_at,
    IngredientBranchLinkModifierFields.updated_at: updated_at,
    IngredientBranchLinkModifierFields.soft_delete: soft_delete,
  };
}
