String? tableTableUse = 'tb_table_use ';

class TableUseFields {
  static List<String> values = [
    table_use_sqlite_id,
    table_use_id,
    branch_id,
    cardColor,
    created_at,
    updated_at,
    soft_delete
  ];

  static String table_use_sqlite_id = 'table_use_sqlite_id';
  static String table_use_id = 'table_use_id';
  static String branch_id = 'branch_id';
  static String cardColor = 'cardColor';
  static String created_at = 'created_at';
  static String updated_at = 'updated_at';
  static String soft_delete = 'soft_delete';
}

class TableUse{
  int? table_use_sqlite_id;
  int? table_use_id;
  int? branch_id;
  String? cardColor;
  String? created_at;
  String? updated_at;
  String? soft_delete;

  TableUse(
      {this.table_use_sqlite_id,
        this.table_use_id,
        this.branch_id,
        this.cardColor,
        this.created_at,
        this.updated_at,
        this.soft_delete});

  TableUse copy({
    int? table_use_sqlite_id,
    int? table_use_id,
    int? branch_id,
    String? cardColor,
    String? created_at,
    String? updated_at,
    String? soft_delete,
  }) =>
      TableUse(
          table_use_sqlite_id: table_use_sqlite_id ?? this.table_use_sqlite_id,
          table_use_id: table_use_id ?? this.table_use_id,
          branch_id: branch_id ?? this.branch_id,
          cardColor: cardColor ?? this.cardColor,
          created_at: created_at ?? this.created_at,
          updated_at: updated_at ?? this.updated_at,
          soft_delete: soft_delete ?? this.soft_delete);

  static TableUse fromJson(Map<String, Object?> json) => TableUse  (
    table_use_sqlite_id: json[TableUseFields.table_use_sqlite_id] as int?,
    table_use_id: json[TableUseFields.table_use_id] as int?,
    branch_id: json[TableUseFields.branch_id] as int?,
    cardColor: json[TableUseFields.cardColor] as String?,
    created_at: json[TableUseFields.created_at] as String?,
    updated_at: json[TableUseFields.updated_at] as String?,
    soft_delete: json[TableUseFields .soft_delete] as String?,
  );

  Map<String, Object?> toJson() => {
    TableUseFields.table_use_sqlite_id: table_use_sqlite_id,
    TableUseFields.table_use_id: table_use_id,
    TableUseFields.branch_id: branch_id,
    TableUseFields.cardColor: cardColor,
    TableUseFields.created_at: created_at,
    TableUseFields.updated_at: updated_at,
    TableUseFields.soft_delete: soft_delete,
  };
}

