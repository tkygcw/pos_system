String? tablePrinter = 'tb_printer';

class PrinterFields {
  static List<String> values = [
    printer_sqlite_id,
    printer_key,
    printer_id,
    branch_id,
    company_id,
    value,
    type,
    printer_label,
    printer_link_category_id,
    paper_size,
    printer_status,
    is_counter,
    is_label,
    sync_status,
    created_at,
    updated_at,
    soft_delete
  ];

  static String printer_sqlite_id = 'printer_sqlite_id';
  static String printer_key = 'printer_key';
  static String printer_id = 'printer_id';
  static String branch_id = 'branch_id';
  static String company_id = 'company_id';
  static String value = 'value';
  static String type = 'type';
  static String printer_label = 'printer_label';
  static String printer_link_category_id = 'printer_link_category_id';
  static String paper_size = 'paper_size';
  static String printer_status = 'printer_status';
  static String is_counter = 'is_counter';
  static String is_label = 'is_label';
  static String sync_status = 'sync_status';
  static String created_at = 'created_at';
  static String updated_at = 'updated_at';
  static String soft_delete = 'soft_delete';
}

class Printer {
  int? printer_sqlite_id;
  String? printer_key;
  int? printer_id;
  String? branch_id;
  String? company_id;
  String? value;
  int? type;
  String? printer_label;
  String? printer_link_category_id;
  int? paper_size;
  int? printer_status;
  int? is_counter;
  int? is_label;
  int? sync_status;
  String? created_at;
  String? updated_at;
  String? soft_delete;

  Printer(
      {this.printer_sqlite_id,
      this.printer_key,
      this.printer_id,
      this.branch_id,
      this.company_id,
      this.value,
      this.type,
      this.printer_label,
      this.printer_link_category_id,
      this.paper_size,
      this.printer_status,
      this.is_counter,
      this.is_label,
      this.sync_status,
      this.created_at,
      this.updated_at,
      this.soft_delete});

  Printer copy({
    int? printer_sqlite_id,
    String? printer_key,
    int? printer_id,
    String? branch_id,
    String? company_id,
    String? value,
    int? type,
    String? printer_label,
    String? printer_link_category_id,
    int? paper_size,
    int? printer_status,
    int? is_counter,
    int? is_label,
    int? sync_status,
    String? created_at,
    String? updated_at,
    String? soft_delete
  }) =>
      Printer(
        printer_sqlite_id: printer_sqlite_id ?? this.printer_sqlite_id,
        printer_key: printer_key ?? this.printer_key,
        printer_id: printer_id ?? this.printer_id,
        branch_id: branch_id ?? this.branch_id,
        company_id: company_id ?? this.company_id,
        value: value ?? this.value,
        type: type ?? this.type,
        printer_label: printer_label ?? this.printer_label,
        printer_link_category_id: printer_link_category_id ?? this.printer_link_category_id,
        paper_size: paper_size ?? this.paper_size,
        printer_status: printer_status ?? this.printer_status,
        is_counter: is_counter ?? this.is_counter,
        is_label: is_label ?? this.is_label,
        sync_status: sync_status ?? this.sync_status,
        created_at: created_at ?? this.created_at,
        updated_at: updated_at ?? this.updated_at,
        soft_delete: soft_delete ?? this.soft_delete);

  static Printer fromJson(Map<String, Object?> json) => Printer(
    printer_sqlite_id: json[PrinterFields.printer_sqlite_id] as int?,
    printer_key: json[PrinterFields.printer_key] as String?,
    printer_id: json[PrinterFields.printer_id] as int?,
    branch_id: json[PrinterFields.branch_id] as String?,
    company_id: json[PrinterFields.company_id] as String?,
    value: json[PrinterFields.value] as String?,
    type: json[PrinterFields.type] as int?,
    printer_label: json[PrinterFields.printer_label] as String?,
    printer_link_category_id: json[PrinterFields.printer_link_category_id] as String?,
    paper_size: json[PrinterFields.paper_size] as int?,
    printer_status: json[PrinterFields.printer_status] as int?,
    is_counter: json[PrinterFields.is_counter] as int?,
    is_label: json[PrinterFields.is_label] as int?,
    sync_status: json[PrinterFields.sync_status] as int?,
    created_at: json[PrinterFields.created_at] as String?,
    updated_at: json[PrinterFields.updated_at] as String?,
    soft_delete: json[PrinterFields.soft_delete] as String?,
  );

  Map<String, Object?> toJson() => {
    PrinterFields.printer_sqlite_id: printer_sqlite_id,
    PrinterFields.printer_key: printer_key,
    PrinterFields.printer_id: printer_id,
    PrinterFields.branch_id: branch_id,
    PrinterFields.company_id: company_id,
    PrinterFields.value: value,
    PrinterFields.type: type,
    PrinterFields.printer_label: printer_label,
    PrinterFields.printer_link_category_id: printer_link_category_id,
    PrinterFields.paper_size: paper_size,
    PrinterFields.printer_status: printer_status,
    PrinterFields.is_counter: is_counter,
    PrinterFields.is_label: is_label,
    PrinterFields.sync_status: sync_status,
    PrinterFields.created_at: created_at,
    PrinterFields.updated_at: updated_at,
    PrinterFields.soft_delete: soft_delete,
  };
}
