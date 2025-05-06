String? tableChecklist = 'tb_checklist';

class ChecklistFields {
  static List<String> values = [
    checklist_sqlite_id,
    checklist_id,
    checklist_key,
    branch_id,
    product_name_font_size,
    other_font_size,
    paper_size,
    show_product_sku,
    show_total_amount,
    sync_status,
    created_at,
    updated_at,
    soft_delete
  ];

  static String checklist_sqlite_id = 'checklist_sqlite_id';
  static String checklist_id = 'checklist_id';
  static String checklist_key = 'checklist_key';
  static String branch_id = 'branch_id';
  static String product_name_font_size = 'product_name_font_size';
  static String other_font_size = 'other_font_size';
  static String check_list_show_price = 'check_list_show_price';
  static String check_list_show_separator = 'check_list_show_separator';
  static String show_product_sku = 'show_product_sku';
  static String show_total_amount = 'show_total_amount';
  static String paper_size = 'paper_size';
  static String sync_status = 'sync_status';
  static String created_at = 'created_at';
  static String updated_at = 'updated_at';
  static String soft_delete = 'soft_delete';

}

class Checklist {
  int? checklist_sqlite_id;
  int? checklist_id;
  String? checklist_key;
  String? branch_id;
  int? product_name_font_size;
  int? other_font_size;
  int? check_list_show_price;
  int? check_list_show_separator;
  String? paper_size;
  int? show_product_sku;
  int? show_total_amount;
  int? sync_status;
  String? created_at;
  String? updated_at;
  String? soft_delete;

  Checklist(
      {this.checklist_sqlite_id,
        this.checklist_id,
        this.checklist_key,
        this.branch_id,
        this.product_name_font_size,
        this.other_font_size,
        this.check_list_show_price,
        this.check_list_show_separator,
        this.paper_size,
        this.show_product_sku,
        this.show_total_amount,
        this.sync_status,
        this.created_at,
        this.updated_at,
        this.soft_delete});

  Checklist copy({
    int? checklist_sqlite_id,
    int? checklist_id,
    String? checklist_key,
    String? branch_id,
    int? product_name_font_size,
    int? other_font_size,
    int? check_list_show_price,
    int? check_list_show_separator,
    String? paper_size,
    int? show_product_sku,
    int? show_total_amount,
    int? sync_status,
    String? created_at,
    String? updated_at,
    String? soft_delete
  }) =>
      Checklist(
          checklist_sqlite_id: checklist_sqlite_id ?? this.checklist_sqlite_id,
          checklist_id: checklist_id ?? this.checklist_id,
          checklist_key: checklist_key ?? this.checklist_key,
          branch_id: branch_id ?? this.branch_id,
          product_name_font_size: product_name_font_size ?? this.product_name_font_size,
          other_font_size: other_font_size ?? this.other_font_size,
          check_list_show_price: check_list_show_price ?? this.check_list_show_price,
          check_list_show_separator: check_list_show_separator ?? this.check_list_show_separator,
          paper_size: paper_size ?? this.paper_size,
          show_product_sku: show_product_sku ?? this.show_product_sku,
          show_total_amount: show_total_amount ?? this.show_total_amount,
          sync_status: sync_status ?? this.sync_status,
          created_at: created_at ?? this.created_at,
          updated_at: updated_at ?? this.updated_at,
          soft_delete: soft_delete ?? this.soft_delete);

  static Checklist fromJson(Map<String, Object?> json) => Checklist(
    checklist_sqlite_id: json[ChecklistFields.checklist_sqlite_id] as int?,
    checklist_id: json[ChecklistFields.checklist_id] as int?,
    checklist_key: json[ChecklistFields.checklist_key] as String?,
    branch_id: json[ChecklistFields.branch_id] as String?,
    product_name_font_size: json[ChecklistFields.product_name_font_size] as int?,
    other_font_size: json[ChecklistFields.other_font_size] as int?,
    check_list_show_price: json[ChecklistFields.check_list_show_price] as int?,
    check_list_show_separator: json[ChecklistFields.check_list_show_separator] as int?,
    paper_size: json[ChecklistFields.paper_size] as String?,
    show_product_sku: json[ChecklistFields.show_product_sku] as int?,
    show_total_amount: json[ChecklistFields.show_total_amount] as int?,
    sync_status: json[ChecklistFields.sync_status] as int?,
    created_at: json[ChecklistFields.created_at] as String?,
    updated_at: json[ChecklistFields.updated_at] as String?,
    soft_delete: json[ChecklistFields.soft_delete] as String?,
  );

  Map<String, Object?> toJson() => {
    ChecklistFields.checklist_sqlite_id: checklist_sqlite_id,
    ChecklistFields.checklist_id: checklist_id,
    ChecklistFields.checklist_key: checklist_key,
    ChecklistFields.branch_id: branch_id,
    ChecklistFields.product_name_font_size: product_name_font_size,
    ChecklistFields.other_font_size: other_font_size,
    ChecklistFields.check_list_show_price: check_list_show_price,
    ChecklistFields.check_list_show_separator: check_list_show_separator,
    ChecklistFields.paper_size: paper_size,
    ChecklistFields.show_product_sku: show_product_sku,
    ChecklistFields.show_total_amount: show_total_amount,
    ChecklistFields.sync_status: sync_status,
    ChecklistFields.created_at: created_at,
    ChecklistFields.updated_at: updated_at,
    ChecklistFields.soft_delete: soft_delete,
  };
}
