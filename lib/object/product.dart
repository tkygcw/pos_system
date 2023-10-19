String? tableProduct = 'tb_product ';

class ProductFields {
  static List<String> values = [
    product_sqlite_id,
    product_id,
    category_sqlite_id,
    category_id,
    company_id,
    name,
    price,
    description,
    SKU,
    image,
    has_variant,
    stock_type,
    stock_quantity,
    available,
    graphic_type,
    color,
    daily_limit,
    daily_limit_amount,
    unit,
    per_quantity_unit,
    sync_status,
    created_at,
    updated_at,
    soft_delete
  ];

  static String product_sqlite_id = 'product_sqlite_id';
  static String product_id = 'product_id';
  static String category_sqlite_id = 'category_sqlite_id';
  static String category_id = 'category_id';
  static String company_id = 'company_id';
  static String name = 'name';
  static String price = 'price';
  static String description = 'description';
  static String SKU = 'SKU';
  static String image = 'image';
  static String has_variant = 'has_variant';
  static String stock_type = 'stock_type';
  static String stock_quantity = 'stock_quantity';
  static String available = 'available';
  static String graphic_type = 'graphic_type';
  static String color = 'color';
  static String daily_limit = 'daily_limit';
  static String daily_limit_amount = 'daily_limit_amount';
  static String unit = 'unit';
  static String per_quantity_unit = 'per_quantity_unit';
  static String sync_status = 'sync_status';
  static String created_at = 'created_at';
  static String updated_at = 'updated_at';
  static String soft_delete = 'soft_delete';
}

class Product{
  int? product_sqlite_id;
  int? product_id;
  String? category_sqlite_id;
  String? category_id;
  String? company_id;
  String? name;
  String? price;
  String? description;
  String? SKU;
  String? image;
  int? has_variant;
  int? stock_type;
  String? stock_quantity;
  int? available;
  String? graphic_type;
  String? color;
  String? daily_limit;
  String? daily_limit_amount;
  String? unit;
  String? per_quantity_unit;
  int? sync_status;
  String? created_at;
  String? updated_at;
  String? soft_delete;
  String? category_name;

  Product(
      {this.product_sqlite_id,
        this.product_id,
        this.category_sqlite_id,
        this.category_id,
        this.company_id,
        this.name,
        this.price,
        this.description,
        this.SKU,
        this.image,
        this.has_variant,
        this.stock_type,
        this.stock_quantity,
        this.available,
        this.graphic_type,
        this.color,
        this.daily_limit,
        this.daily_limit_amount,
        this.unit,
        this.per_quantity_unit,
        this.sync_status,
        this.created_at,
        this.updated_at,
        this.soft_delete,
        this.category_name,
      });

  Product copy({
    int? product_sqlite_id,
    int? product_id,
    String? category_sqlite_id,
    String? category_id,
    String? company_id,
    String? name,
    String? price,
    String? description,
    String? SKU,
    String? image,
    int? has_variant,
    int? stock_type,
    String? stock_quantity,
    int? available,
    String? graphic_type,
    String? color,
    String? daily_limit,
    String? daily_limit_amount,
    String? unit,
    String? per_quantity_unit,
    int? sync_status,
    String? created_at,
    String? updated_at,
    String? soft_delete,
  }) =>
      Product(
          product_sqlite_id: product_sqlite_id ?? this.product_sqlite_id,
          product_id: product_id ?? this.product_id,
          category_sqlite_id: category_sqlite_id ?? this.category_sqlite_id,
          category_id: category_id ?? this.category_id,
          company_id: company_id ?? this.company_id,
          name: name ?? this.name,
          price: price ?? this.price,
          description: description ?? this.description,
          SKU: SKU ?? this.SKU,
          image: image ?? this.image,
          has_variant: has_variant ?? this.has_variant,
          stock_type: stock_type ?? this.stock_type,
          stock_quantity: stock_quantity ?? this.stock_quantity,
          available: available ?? this.available,
          graphic_type: graphic_type ?? this.graphic_type,
          color: color ?? this.color,
          daily_limit: daily_limit ?? this.daily_limit,
          daily_limit_amount: daily_limit_amount ?? this.daily_limit_amount,
          unit: unit ?? this.unit,
          per_quantity_unit: per_quantity_unit ?? this.per_quantity_unit,
          sync_status: sync_status ?? this.sync_status,
          created_at: created_at ?? this.created_at,
          updated_at: updated_at ?? this.updated_at,
          soft_delete: soft_delete ?? this.soft_delete);

  static Product fromJson(Map<String, Object?> json) => Product(
    product_sqlite_id: json[ProductFields.product_sqlite_id] as int?,
    product_id: json[ProductFields.product_id] as int?,
    category_sqlite_id: json[ProductFields.category_sqlite_id] as String?,
    category_id: json[ProductFields.category_id] as String?,
    company_id: json[ProductFields.company_id] as String?,
    name: json[ProductFields.name] as String?,
    price: json[ProductFields.price] as String?,
    description: json[ProductFields.description] as String?,
    SKU: json[ProductFields.SKU] as String?,
    image: json[ProductFields.image] as String?,
    has_variant: json[ProductFields.has_variant] as int?,
    stock_type: json[ProductFields.stock_type] as int?,
    stock_quantity: json[ProductFields.stock_quantity] as String?,
    available: json[ProductFields.available] as int?,
    graphic_type: json[ProductFields.graphic_type] as String?,
    color: json[ProductFields.color] as String?,
    daily_limit: json[ProductFields.daily_limit] as String?,
    daily_limit_amount: json[ProductFields.daily_limit_amount] as String?,
    unit: json[ProductFields.unit] as String?,
    per_quantity_unit: json[ProductFields.per_quantity_unit] as String?,
    sync_status: json[ProductFields.sync_status] as int?,
    created_at: json[ProductFields.created_at] as String?,
    updated_at: json[ProductFields.updated_at] as String?,
    soft_delete: json[ProductFields.soft_delete] as String?,
    category_name: json['category_name'] as String?
  );

  Map<String, Object?> toJson() => {
    ProductFields.product_sqlite_id: product_sqlite_id,
    ProductFields.product_id: product_id,
    ProductFields.category_sqlite_id: category_sqlite_id,
    ProductFields.category_id: category_id,
    ProductFields.company_id: company_id,
    ProductFields.name: name,
    ProductFields.price: price,
    ProductFields.description: description,
    ProductFields.SKU: SKU,
    ProductFields.image: image,
    ProductFields.has_variant: has_variant,
    ProductFields.stock_type: stock_type,
    ProductFields.stock_quantity: stock_quantity,
    ProductFields.available: available,
    ProductFields.graphic_type: graphic_type,
    ProductFields.color: color,
    ProductFields.daily_limit: daily_limit,
    ProductFields.daily_limit_amount: daily_limit_amount,
    ProductFields.unit: unit,
    ProductFields.per_quantity_unit: per_quantity_unit,
    ProductFields.sync_status: sync_status,
    ProductFields.created_at: created_at,
    ProductFields.updated_at: updated_at,
    ProductFields.soft_delete: soft_delete,
    'category_name': category_name,
  };
}
