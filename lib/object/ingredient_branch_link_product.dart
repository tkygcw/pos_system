String? tableIngredientBranchLinkProduct = 'tb_ingredient_branch_link_product';

class IngredientBranchLinkProductFields {
  static List<String> values = [
    ingredient_branch_link_product_sqlite_id,
    ingredient_branch_link_product_id,
    ingredient_company_link_branch_id,
    branch_link_product_id,
    ingredient_usage,
    sync_status,
    created_at,
    updated_at,
    soft_delete,
  ];

  static String ingredient_branch_link_product_sqlite_id = 'ingredient_branch_link_product_sqlite_id';
  static String ingredient_branch_link_product_id = 'ingredient_branch_link_product_id';
  static String ingredient_company_link_branch_id = 'ingredient_company_link_branch_id';
  static String branch_link_product_id = 'branch_link_product_id';
  static String ingredient_usage = 'ingredient_usage';
  static String sync_status = 'sync_status';
  static String created_at = 'created_at';
  static String updated_at = 'updated_at';
  static String soft_delete = 'soft_delete';
}

class IngredientBranchLinkProduct {
  int? ingredient_branch_link_product_sqlite_id;
  int? ingredient_branch_link_product_id;
  String? ingredient_company_link_branch_id;
  String? branch_link_product_id;
  String? ingredient_usage;
  int? sync_status;
  String? created_at;
  String? updated_at;
  String? soft_delete;

  IngredientBranchLinkProduct(
      {this.ingredient_branch_link_product_sqlite_id,
        this.ingredient_branch_link_product_id,
        this.ingredient_company_link_branch_id,
        this.branch_link_product_id,
        this.ingredient_usage,
        this.sync_status,
        this.created_at,
        this.updated_at,
        this.soft_delete,
      });

  IngredientBranchLinkProduct copy({
    int? ingredient_branch_link_product_sqlite_id,
    int? ingredient_branch_link_product_id,
    String? ingredient_company_link_branch_id,
    String? branch_link_product_id,
    String? ingredient_usage,
    int? sync_status,
    String? created_at,
    String? updated_at,
    String? soft_delete,
  }) =>
      IngredientBranchLinkProduct(
        ingredient_branch_link_product_sqlite_id: ingredient_branch_link_product_sqlite_id ?? this.ingredient_branch_link_product_sqlite_id,
        ingredient_branch_link_product_id: ingredient_branch_link_product_id ?? this.ingredient_branch_link_product_id,
        ingredient_company_link_branch_id: ingredient_company_link_branch_id ?? this.ingredient_company_link_branch_id,
        branch_link_product_id: branch_link_product_id ?? this.branch_link_product_id,
        ingredient_usage: ingredient_usage ?? this.ingredient_usage,
        sync_status: sync_status ?? this.sync_status,
        created_at: created_at ?? this.created_at,
        updated_at: updated_at ?? this.updated_at,
        soft_delete: soft_delete ?? this.soft_delete,
      );

  static IngredientBranchLinkProduct fromJson(Map<String, Object?> json) => IngredientBranchLinkProduct(
    ingredient_branch_link_product_sqlite_id: json[IngredientBranchLinkProductFields.ingredient_branch_link_product_sqlite_id] as int?,
    ingredient_branch_link_product_id: json[IngredientBranchLinkProductFields.ingredient_branch_link_product_id] as int?,
    ingredient_company_link_branch_id: json[IngredientBranchLinkProductFields.ingredient_company_link_branch_id] as String?,
    branch_link_product_id: json[IngredientBranchLinkProductFields.branch_link_product_id] as String?,
    ingredient_usage: json[IngredientBranchLinkProductFields.ingredient_usage] as String?,
    sync_status: json[IngredientBranchLinkProductFields.sync_status] as int?,
    created_at: json[IngredientBranchLinkProductFields.created_at] as String?,
    updated_at: json[IngredientBranchLinkProductFields.updated_at] as String?,
    soft_delete: json[IngredientBranchLinkProductFields.soft_delete] as String?,
  );

  Map<String, Object?> toJson() => {
    IngredientBranchLinkProductFields.ingredient_branch_link_product_sqlite_id: ingredient_branch_link_product_sqlite_id,
    IngredientBranchLinkProductFields.ingredient_branch_link_product_id: ingredient_branch_link_product_id,
    IngredientBranchLinkProductFields.ingredient_company_link_branch_id: ingredient_company_link_branch_id,
    IngredientBranchLinkProductFields.branch_link_product_id: branch_link_product_id,
    IngredientBranchLinkProductFields.ingredient_usage: ingredient_usage,
    IngredientBranchLinkProductFields.sync_status: sync_status,
    IngredientBranchLinkProductFields.created_at: created_at,
    IngredientBranchLinkProductFields.updated_at: updated_at,
    IngredientBranchLinkProductFields.soft_delete: soft_delete,
  };
}
