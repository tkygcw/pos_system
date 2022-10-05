String? tablePrinter = 'tb_printer';

class PrinterFields {
  static List<String> values = [
    printer_sqlite_id,
    printer_id,
    branch_id,
    company_id,
    value,
    type,
    printerLabel,
    printer_link_category_id,
    created_at,
    updated_at,
    soft_delete
  ];

  static String printer_sqlite_id = 'printer_sqlite_id';
  static String printer_id = 'printer_id';
  static String branch_id = 'branch_id';
  static String company_id = 'company_id';
  static String value = 'value';
  static String type = 'type';
  static String printerLabel = 'printerLabel';
  static String printer_link_category_id = 'printer_link_category_id';
  static String created_at = 'created_at';
  static String updated_at = 'updated_at';
  static String soft_delete = 'soft_delete';
}

class Printer {
  int? printer_sqlite_id;
  int? printer_id;
  String? branch_id;
  String? company_id;
  String? value;
  String? type;
  String? printerLabel;
  String? printer_link_category_id;
  String? created_at;
  String? updated_at;
  String? soft_delete;

  Printer(
      {this.printer_sqlite_id,
      this.printer_id,
      this.branch_id,
      this.company_id,
      this.value,
      this.type,
      this.printerLabel,
      this.printer_link_category_id,
      this.created_at,
      this.updated_at,
      this.soft_delete});

  Printer copy({
    int? printer_sqlite_id,
    int? printer_id,
    String? branch_id,
    String? company_id,
    String? value,
    String? type,
    String? printerLabel,
    String? printer_link_category_id,
    String? created_at,
    String? updated_at,
    String? soft_delete
  }) =>
      Printer(
        printer_sqlite_id: printer_sqlite_id ?? this.printer_sqlite_id,
        printer_id: printer_id ?? this.printer_id,
        branch_id: branch_id ?? this.branch_id,
        company_id: company_id ?? this.company_id,
        value: value ?? this.value,
        type: type ?? this.type,
        printerLabel: printerLabel ?? this.printerLabel,
        printer_link_category_id: printer_link_category_id ?? this.printer_link_category_id,
        created_at: created_at ?? this.created_at,
        updated_at: updated_at ?? this.updated_at,
        soft_delete: soft_delete ?? this.soft_delete);

  static Printer fromJson(Map<String, Object?> json) => Printer(
    printer_sqlite_id: json[PrinterFields.printer_sqlite_id] as int?,
    printer_id: json[PrinterFields.printer_id] as int?,
    branch_id: json[PrinterFields.branch_id] as String?,
    company_id: json[PrinterFields.company_id] as String?,
    value: json[PrinterFields.value] as String?,
    type: json[PrinterFields.type] as String?,
    printerLabel: json[PrinterFields.printerLabel] as String?,
    printer_link_category_id: json[PrinterFields.printer_link_category_id] as String?,
    created_at: json[PrinterFields.created_at] as String?,
    updated_at: json[PrinterFields.updated_at] as String?,
    soft_delete: json[PrinterFields.soft_delete] as String?,
  );

  Map<String, Object?> toJson() => {
    PrinterFields.printer_sqlite_id: printer_sqlite_id,
    PrinterFields.printer_id: printer_id,
    PrinterFields.branch_id: branch_id,
    PrinterFields.company_id: company_id,
    PrinterFields.value: value,
    PrinterFields.type: type,
    PrinterFields.printerLabel: printerLabel,
    PrinterFields.printer_link_category_id: printer_link_category_id,
    PrinterFields.created_at: created_at,
    PrinterFields.updated_at: updated_at,
    PrinterFields.soft_delete: soft_delete,
  };
}
