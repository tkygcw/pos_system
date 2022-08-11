String? tableCategories = 'tb_categories';

class CategoriesFields {
  static List<String> values = [
    category_sqlite_id,
    category_id,
    company_id,
    name,
    sequence,
    color,
    created_at,
    updated_at,
    soft_delete
  ];

  static String category_sqlite_id = 'category_sqlite_id';
  static String category_id = 'category_id';
  static String company_id = 'company_id';
  static String name = 'name';
  static String sequence = 'sequence';
  static String color = 'color';
  static String created_at = 'created_at';
  static String updated_at = 'updated_at';
  static String soft_delete = 'soft_delete';
}

class Categories {
  int? category_sqlite_id;
  int? category_id;
  String? company_id;
  String? name;
  String? sequence;
  String? color;
  String? created_at;
  String? updated_at;
  String? soft_delete;
  int? item_sum;

  Categories(
      {this.category_sqlite_id,
      this.category_id,
      this.company_id,
      this.name,
      this.sequence,
      this.color,
      this.created_at,
      this.updated_at,
      this.soft_delete,
      this.item_sum});

  // factory Categories.fromsJson(Map<String, dynamic> json) {
  //   return Categories(
  //     category_sqlite_id: json['category_sqlite_id'],
  //     category_id: json['category_id'],
  //     company_id: json['company_id'] as String?,
  //     name: json['name'] as String?,
  //     sequence: json['sequence'] as String?,
  //     color: json['color'] as String?,
  //     created_at: json['created_at'] as String?,
  //     updated_at: json['updated_at'] as String?,
  //     soft_delete: json['soft_delete'] as String?,
  //   );
  // }

  Categories copy({
    int? category_sqlite_id,
    int? category_id,
    String? company_id,
    String? name,
    String? sequence,
    String? color,
    String? created_at,
    String? updated_at,
    String? soft_delete,
    int? item_sum,
  }) =>
      Categories(
          category_sqlite_id: category_sqlite_id ?? this.category_sqlite_id,
          category_id: category_id ?? this.category_id,
          company_id: company_id ?? this.company_id,
          name: name ?? this.name,
          sequence: sequence ?? this.sequence,
          color: color ?? this.color,
          created_at: created_at ?? this.created_at,
          updated_at: updated_at ?? this.updated_at,
          soft_delete: soft_delete ?? this.soft_delete,
          item_sum: item_sum ?? this.item_sum);

  static Categories fromJson(Map<String, Object?> json) => Categories(
        category_sqlite_id: json[CategoriesFields.category_sqlite_id] as int?,
        category_id: json[CategoriesFields.category_id] as int?,
        company_id: json[CategoriesFields.company_id] as String?,
        name: json[CategoriesFields.name] as String?,
        sequence: json[CategoriesFields.sequence] as String?,
        color: json[CategoriesFields.color] as String?,
        created_at: json[CategoriesFields.created_at] as String?,
        updated_at: json[CategoriesFields.updated_at] as String?,
        soft_delete: json[CategoriesFields.soft_delete] as String?,
        item_sum: json['item_sum'] as int?,
      );

  // Categories(
  // name: 'No Category',
  // category_id: 0,
  // company_id: '',
  // sequence: '',
  // color: '',
  // created_at: '',
  // updated_at: '',
  // soft_delete: '')

  Map<String, Object?> toJson() => {
        CategoriesFields.category_sqlite_id: category_sqlite_id,
        CategoriesFields.category_id: category_id,
        CategoriesFields.company_id: company_id,
        CategoriesFields.name: name,
        CategoriesFields.sequence: sequence,
        CategoriesFields.color: color,
        CategoriesFields.created_at: created_at,
        CategoriesFields.updated_at: updated_at,
        CategoriesFields.soft_delete: soft_delete,
      };
}
