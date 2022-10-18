String? tablePrinterLinkCategory = 'tb_printer_link_category';

class PrinterLinkCategoryFields {
  static List<String> values = [
    printer_link_category_sqlite_id,
    printer_link_category_id,
    printer_id,
    category_id,
    created_at,
    updated_at,
    soft_delete
  ];

  static String printer_link_category_sqlite_id = 'printer_link_category_sqlite_id';
  static String printer_link_category_id = 'printer_link_category_id';
  static String printer_id = 'printer_id';
  static String category_id = 'category_id';
  static String created_at = 'created_at';
  static String updated_at = 'updated_at';
  static String soft_delete = 'soft_delete';
}

class PrinterLinkCategory {
  int? printer_link_category_sqlite_id;
  int? printer_link_category_id;
  String? printer_id;
  String? category_id;
  String? created_at;
  String? updated_at;
  String? soft_delete;

  PrinterLinkCategory(
      {this.printer_link_category_sqlite_id,
        this.printer_link_category_id,
        this.printer_id,
        this.category_id,
        this.created_at,
        this.updated_at,
        this.soft_delete});

  PrinterLinkCategory copy({
    int? printer_link_category_sqlite_id,
    int? printer_link_category_id,
    String? printer_id,
    String? category_id,
    String? created_at,
    String? updated_at,
    String? soft_delete
  }) =>
      PrinterLinkCategory(
          printer_link_category_sqlite_id: printer_link_category_sqlite_id ?? this.printer_link_category_sqlite_id,
          printer_link_category_id: printer_link_category_id ?? this.printer_link_category_id,
          printer_id: printer_id ?? this.printer_id,
          category_id: category_id ?? this.category_id,
          created_at: created_at ?? this.created_at,
          updated_at: updated_at ?? this.updated_at,
          soft_delete: soft_delete ?? this.soft_delete);

  static PrinterLinkCategory fromJson(Map<String, Object?> json) => PrinterLinkCategory(
    printer_link_category_sqlite_id: json[PrinterLinkCategoryFields.printer_link_category_sqlite_id] as int?,
    printer_link_category_id: json[PrinterLinkCategoryFields.printer_link_category_id] as int?,
    printer_id: json[PrinterLinkCategoryFields.printer_id] as String?,
    category_id: json[PrinterLinkCategoryFields.category_id] as String?,
    created_at: json[PrinterLinkCategoryFields.created_at] as String?,
    updated_at: json[PrinterLinkCategoryFields.updated_at] as String?,
    soft_delete: json[PrinterLinkCategoryFields.soft_delete] as String?,
  );

  Map<String, Object?> toJson() => {
    PrinterLinkCategoryFields.printer_link_category_sqlite_id: printer_link_category_sqlite_id,
    PrinterLinkCategoryFields.printer_link_category_id: printer_link_category_id,
    PrinterLinkCategoryFields.printer_id: printer_id,
    PrinterLinkCategoryFields.category_id: category_id,
    PrinterLinkCategoryFields.created_at: created_at,
    PrinterLinkCategoryFields.updated_at: updated_at,
    PrinterLinkCategoryFields.soft_delete: soft_delete,
  };
}
