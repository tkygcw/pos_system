String? tableIngredientCompany = 'tb_ingredient_company';

class IngredientCompanyFields {
  static List<String> values = [
    ingredient_company_sqlite_id,
    ingredient_company_id,
    company_id,
    name,
    description,
    image,
    unit,
    sync_status,
    created_at,
    updated_at,
    soft_delete,

  ];

  static String ingredient_company_sqlite_id = 'ingredient_company_sqlite_id';
  static String ingredient_company_id = 'ingredient_company_id';
  static String company_id = 'company_id';
  static String description = 'description';
  static String name = 'name';
  static String image = 'image';
  static String unit = 'unit';
  static String sync_status = 'sync_status';
  static String created_at = 'created_at';
  static String updated_at = 'updated_at';
  static String soft_delete = 'soft_delete';
}

class IngredientCompany {
  int? ingredient_company_sqlite_id;
  int? ingredient_company_id;
  String? company_id;
  String? name;
  String? description;
  String? image;
  String? unit;
  int? sync_status;
  String? created_at;
  String? updated_at;
  String? soft_delete;
  String? stock;

  IngredientCompany(
      {this.ingredient_company_sqlite_id,
        this.ingredient_company_id,
        this.company_id,
        this.name,
        this.description,
        this.image,
        this.unit,
        this.sync_status,
        this.created_at,
        this.updated_at,
        this.soft_delete,
        this.stock,
      });

  IngredientCompany copy({
    int? ingredient_company_sqlite_id,
    int? ingredient_company_id,
    String? company_id,
    String? name,
    String? description,
    String? image,
    String? unit,
    int? sync_status,
    String? created_at,
    String? updated_at,
    String? soft_delete,
  }) =>
      IngredientCompany(
          ingredient_company_sqlite_id: ingredient_company_sqlite_id ?? this.ingredient_company_sqlite_id,
          ingredient_company_id: ingredient_company_id ?? this.ingredient_company_id,
          company_id: company_id ?? this.company_id,
          name: name ?? this.name,
          description: description ?? this.description,
          image: image ?? this.image,
          unit: unit ?? this.unit,
          sync_status: sync_status ?? this.sync_status,
          created_at: created_at ?? this.created_at,
          updated_at: updated_at ?? this.updated_at,
          soft_delete: soft_delete ?? this.soft_delete,
      );

  static IngredientCompany fromJson(Map<String, Object?> json) => IngredientCompany(
      ingredient_company_sqlite_id: json[IngredientCompanyFields.ingredient_company_sqlite_id] as int?,
      ingredient_company_id: json[IngredientCompanyFields.ingredient_company_id] as int?,
      company_id: json[IngredientCompanyFields.company_id] as String?,
      name: json[IngredientCompanyFields.name] as String?,
      description: json[IngredientCompanyFields.description] as String?,
      image: json[IngredientCompanyFields.image] as String?,
      unit: json[IngredientCompanyFields.unit] as String?,
      sync_status: json[IngredientCompanyFields.sync_status] as int?,
      created_at: json[IngredientCompanyFields.created_at] as String?,
      updated_at: json[IngredientCompanyFields.updated_at] as String?,
      soft_delete: json[IngredientCompanyFields.soft_delete] as String?,
      stock: json['stock'] as String?,
  );

  Map<String, Object?> toJson() => {
    IngredientCompanyFields.ingredient_company_sqlite_id: ingredient_company_sqlite_id,
    IngredientCompanyFields.ingredient_company_id: ingredient_company_id,
    IngredientCompanyFields.company_id: company_id,
    IngredientCompanyFields.name: name,
    IngredientCompanyFields.description: description,
    IngredientCompanyFields.image: image,
    IngredientCompanyFields.unit: unit,
    IngredientCompanyFields.sync_status: sync_status,
    IngredientCompanyFields.created_at: created_at,
    IngredientCompanyFields.updated_at: updated_at,
    IngredientCompanyFields.soft_delete: soft_delete,
  };
}
