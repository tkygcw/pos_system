String? tableKitchenList = 'tb_kitchen_list';

class KitchenListFields {
  static List<String> values = [
    kitchen_list_sqlite_id,
    kitchen_list_id,
    kitchen_list_key,
    branch_id,
    product_name_font_size,
    other_font_size,
    paper_size,
    kitchen_list_show_price,
    print_combine_kitchen_list,
    kitchen_list_item_separator,
    show_product_sku,
    sync_status,
    created_at,
    updated_at,
    soft_delete
  ];

  static String kitchen_list_sqlite_id = 'kitchen_list_sqlite_id';
  static String kitchen_list_id = 'kitchen_list_id';
  static String kitchen_list_key = 'kitchen_list_key';
  static String branch_id = 'branch_id';
  static String product_name_font_size = 'product_name_font_size';
  static String other_font_size = 'other_font_size';
  static String paper_size = 'paper_size';
  static String kitchen_list_show_price = 'kitchen_list_show_price';
  static String print_combine_kitchen_list = 'print_combine_kitchen_list';
  static String kitchen_list_item_separator = 'kitchen_list_item_separator';
  static String show_product_sku = 'show_product_sku';
  static String sync_status = 'sync_status';
  static String created_at = 'created_at';
  static String updated_at = 'updated_at';
  static String soft_delete = 'soft_delete';

}

class KitchenList {
  int? kitchen_list_sqlite_id;
  int? kitchen_list_id;
  String? kitchen_list_key;
  String? branch_id;
  int? product_name_font_size;
  int? other_font_size;
  String? paper_size;
  int? kitchen_list_show_price;
  int? print_combine_kitchen_list;
  int? kitchen_list_item_separator;
  int? show_product_sku;
  int? sync_status;
  String? created_at;
  String? updated_at;
  String? soft_delete;

  KitchenList(
      {this.kitchen_list_sqlite_id,
        this.kitchen_list_id,
        this.kitchen_list_key,
        this.branch_id,
        this.product_name_font_size,
        this.other_font_size,
        this.paper_size,
        this.kitchen_list_show_price,
        this.print_combine_kitchen_list,
        this.kitchen_list_item_separator,
        this.show_product_sku,
        this.sync_status,
        this.created_at,
        this.updated_at,
        this.soft_delete});

  KitchenList copy({
    int? kitchen_list_sqlite_id,
    int? kitchen_list_id,
    String? kitchen_list_key,
    String? branch_id,
    int? product_name_font_size,
    int? other_font_size,
    String? paper_size,
    int? kitchen_list_show_price,
    int? print_combine_kitchen_list,
    int? kitchen_list_item_separator,
    int? show_product_sku,
    int? sync_status,
    String? created_at,
    String? updated_at,
    String? soft_delete
  }) =>
      KitchenList(
          kitchen_list_sqlite_id: kitchen_list_sqlite_id ?? this.kitchen_list_sqlite_id,
          kitchen_list_id: kitchen_list_id ?? this.kitchen_list_id,
          kitchen_list_key: kitchen_list_key ?? this.kitchen_list_key,
          branch_id: branch_id ?? this.branch_id,
          product_name_font_size: product_name_font_size ?? this.product_name_font_size,
          other_font_size: other_font_size ?? this.other_font_size,
          paper_size: paper_size ?? this.paper_size,
          kitchen_list_show_price: kitchen_list_show_price ?? this.kitchen_list_show_price,
          print_combine_kitchen_list: print_combine_kitchen_list ?? this.print_combine_kitchen_list,
          kitchen_list_item_separator: kitchen_list_item_separator ?? this.kitchen_list_item_separator,
          show_product_sku: show_product_sku ?? this.show_product_sku,
          sync_status: sync_status ?? this.sync_status,
          created_at: created_at ?? this.created_at,
          updated_at: updated_at ?? this.updated_at,
          soft_delete: soft_delete ?? this.soft_delete);

  static KitchenList fromJson(Map<String, Object?> json) => KitchenList(
    kitchen_list_sqlite_id: json[KitchenListFields.kitchen_list_sqlite_id] as int?,
    kitchen_list_id: json[KitchenListFields.kitchen_list_id] as int?,
    kitchen_list_key: json[KitchenListFields.kitchen_list_key] as String?,
    branch_id: json[KitchenListFields.branch_id] as String?,
    product_name_font_size: json[KitchenListFields.product_name_font_size] as int?,
    other_font_size: json[KitchenListFields.other_font_size] as int?,
    paper_size: json[KitchenListFields.paper_size] as String?,
    kitchen_list_show_price: json[KitchenListFields.kitchen_list_show_price] as int?,
    print_combine_kitchen_list: json[KitchenListFields.print_combine_kitchen_list] as int?,
    kitchen_list_item_separator: json[KitchenListFields.kitchen_list_item_separator] as int?,
    show_product_sku: json[KitchenListFields.show_product_sku] as int?,
    sync_status: json[KitchenListFields.sync_status] as int?,
    created_at: json[KitchenListFields.created_at] as String?,
    updated_at: json[KitchenListFields.updated_at] as String?,
    soft_delete: json[KitchenListFields.soft_delete] as String?,
  );

  Map<String, Object?> toJson() => {
    KitchenListFields.kitchen_list_sqlite_id: kitchen_list_sqlite_id,
    KitchenListFields.kitchen_list_id: kitchen_list_id,
    KitchenListFields.kitchen_list_key: kitchen_list_key,
    KitchenListFields.branch_id: branch_id,
    KitchenListFields.product_name_font_size: product_name_font_size,
    KitchenListFields.other_font_size: other_font_size,
    KitchenListFields.paper_size: paper_size,
    KitchenListFields.kitchen_list_show_price: kitchen_list_show_price,
    KitchenListFields.print_combine_kitchen_list: print_combine_kitchen_list,
    KitchenListFields.kitchen_list_item_separator: kitchen_list_item_separator,
    KitchenListFields.show_product_sku: show_product_sku,
    KitchenListFields.sync_status: sync_status,
    KitchenListFields.created_at: created_at,
    KitchenListFields.updated_at: updated_at,
    KitchenListFields.soft_delete: soft_delete,
  };
}
