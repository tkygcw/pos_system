String? tableTableUseDetail= 'tb_table_use_detail ';

class TableUseDetailFields {
  static List<String> values = [
    table_use_detail_sqlite_id,
    table_use_detail_id,
    table_use_id,
    table_id,
    original_table_id,
    created_at,
    updated_at,
    soft_delete
  ];

  static String table_use_detail_sqlite_id = 'table_use_detail_sqlite_id';
  static String table_use_detail_id = 'table_use_detail_id';
  static String table_use_id = 'table_use_id';
  static String table_id = 'table_id';
  static String original_table_id = 'original_table_id';
  static String created_at = 'created_at';
  static String updated_at = 'updated_at';
  static String soft_delete = 'soft_delete';
}

class TableUseDetail{
  int? table_use_detail_sqlite_id;
  int? table_use_detail_id;
  String? table_use_id;
  String? table_id;
  String? original_table_id;
  String? created_at;
  String? updated_at;
  String? soft_delete;

  TableUseDetail(
      {this.table_use_detail_sqlite_id,
        this.table_use_detail_id,
        this.table_use_id,
        this.table_id,
        this.original_table_id,
        this.created_at,
        this.updated_at,
        this.soft_delete});

  TableUseDetail copy({
    int? table_use_detail_sqlite_id,
    int? table_use_detail_id,
    String? table_use_id,
    String? table_id,
    String? original_table_id,
    String? created_at,
    String? updated_at,
    String? soft_delete,
  }) =>
      TableUseDetail(
          table_use_detail_sqlite_id: table_use_detail_sqlite_id ?? this.table_use_detail_sqlite_id,
          table_use_detail_id: table_use_detail_id ?? this.table_use_detail_id,
          table_use_id: table_use_id ?? this.table_use_id,
          table_id: table_id ?? this.table_id,
          original_table_id: original_table_id ?? this.original_table_id,
          created_at: created_at ?? this.created_at,
          updated_at: updated_at ?? this.updated_at,
          soft_delete: soft_delete ?? this.soft_delete);

  static TableUseDetail fromJson(Map<String, Object?> json) => TableUseDetail  (
    table_use_detail_sqlite_id: json[TableUseDetailFields.table_use_detail_sqlite_id] as int?,
    table_use_detail_id: json[TableUseDetailFields.table_use_detail_id] as int?,
    table_use_id: json[TableUseDetailFields.table_use_id] as String?,
    table_id: json[TableUseDetailFields.table_id] as String?,
    original_table_id: json[TableUseDetailFields.original_table_id] as String?,
    created_at: json[TableUseDetailFields.created_at] as String?,
    updated_at: json[TableUseDetailFields.updated_at] as String?,
    soft_delete: json[TableUseDetailFields .soft_delete] as String?,
  );

  Map<String, Object?> toJson() => {
    TableUseDetailFields.table_use_detail_sqlite_id: table_use_detail_sqlite_id,
    TableUseDetailFields.table_use_detail_id: table_use_detail_id,
    TableUseDetailFields.table_use_id: table_use_id,
    TableUseDetailFields.table_id: table_id,
    TableUseDetailFields.original_table_id: original_table_id,
    TableUseDetailFields.created_at: created_at,
    TableUseDetailFields.updated_at: updated_at,
    TableUseDetailFields.soft_delete: soft_delete,
  };
}

