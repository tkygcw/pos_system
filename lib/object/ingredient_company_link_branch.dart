String? tableIngredientCompanyLinkBranch = 'tb_ingredient_company_link_branch';

class IngredientCompanyLinkBranchFields {
  static List<String> values = [
    ingredient_company_link_branch_sqlite_id,
    ingredient_company_link_branch_id,
    ingredient_company_id,
    branch_id,
    stock_quantity,
    sync_status,
    created_at,
    updated_at,
    soft_delete,
  ];

  static String ingredient_company_link_branch_sqlite_id = 'ingredient_company_link_branch_sqlite_id';
  static String ingredient_company_link_branch_id = 'ingredient_company_link_branch_id';
  static String ingredient_company_id = 'ingredient_company_id';
  static String branch_id = 'branch_id';
  static String stock_quantity = 'stock_quantity';
  static String sync_status = 'sync_status';
  static String created_at = 'created_at';
  static String updated_at = 'updated_at';
  static String soft_delete = 'soft_delete';
}

class IngredientCompanyLinkBranch {
  int? ingredient_company_link_branch_sqlite_id;
  int? ingredient_company_link_branch_id;
  String? ingredient_company_id;
  String? branch_id;
  String? stock_quantity;
  int? sync_status;
  String? created_at;
  String? updated_at;
  String? soft_delete;

  IngredientCompanyLinkBranch(
      {this.ingredient_company_link_branch_sqlite_id,
        this.ingredient_company_link_branch_id,
        this.ingredient_company_id,
        this.branch_id,
        this.stock_quantity,
        this.sync_status,
        this.created_at,
        this.updated_at,
        this.soft_delete,
      });

  IngredientCompanyLinkBranch copy({
    int? ingredient_company_link_branch_sqlite_id,
    int? ingredient_company_link_branch_id,
    String? ingredient_company_id,
    String? branch_id,
    String? stock_quantity,
    int? sync_status,
    String? created_at,
    String? updated_at,
    String? soft_delete,
  }) =>
      IngredientCompanyLinkBranch(
        ingredient_company_link_branch_sqlite_id: ingredient_company_link_branch_sqlite_id ?? this.ingredient_company_link_branch_sqlite_id,
        ingredient_company_link_branch_id: ingredient_company_link_branch_id ?? this.ingredient_company_link_branch_id,
        ingredient_company_id: ingredient_company_id ?? this.ingredient_company_id,
        branch_id: branch_id ?? this.branch_id,
        stock_quantity: stock_quantity ?? this.stock_quantity,
        sync_status: sync_status ?? this.sync_status,
        created_at: created_at ?? this.created_at,
        updated_at: updated_at ?? this.updated_at,
        soft_delete: soft_delete ?? this.soft_delete,
      );

  static IngredientCompanyLinkBranch fromJson(Map<String, Object?> json) => IngredientCompanyLinkBranch(
    ingredient_company_link_branch_sqlite_id: json[IngredientCompanyLinkBranchFields.ingredient_company_link_branch_sqlite_id] as int?,
    ingredient_company_link_branch_id: json[IngredientCompanyLinkBranchFields.ingredient_company_link_branch_id] as int?,
    ingredient_company_id: json[IngredientCompanyLinkBranchFields.ingredient_company_id] as String?,
    branch_id: json[IngredientCompanyLinkBranchFields.branch_id] as String?,
    stock_quantity: json[IngredientCompanyLinkBranchFields.stock_quantity] as String?,
    sync_status: json[IngredientCompanyLinkBranchFields.sync_status] as int?,
    created_at: json[IngredientCompanyLinkBranchFields.created_at] as String?,
    updated_at: json[IngredientCompanyLinkBranchFields.updated_at] as String?,
    soft_delete: json[IngredientCompanyLinkBranchFields.soft_delete] as String?,
  );

  Map<String, Object?> toJson() => {
    IngredientCompanyLinkBranchFields.ingredient_company_link_branch_sqlite_id: ingredient_company_link_branch_sqlite_id,
    IngredientCompanyLinkBranchFields.ingredient_company_link_branch_id: ingredient_company_link_branch_id,
    IngredientCompanyLinkBranchFields.ingredient_company_id: ingredient_company_id,
    IngredientCompanyLinkBranchFields.branch_id: branch_id,
    IngredientCompanyLinkBranchFields.stock_quantity: stock_quantity,
    IngredientCompanyLinkBranchFields.sync_status: sync_status,
    IngredientCompanyLinkBranchFields.created_at: created_at,
    IngredientCompanyLinkBranchFields.updated_at: updated_at,
    IngredientCompanyLinkBranchFields.soft_delete: soft_delete,
  };
}
