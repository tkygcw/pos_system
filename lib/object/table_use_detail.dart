import 'package:pos_system/object/table.dart';

String? tableTableUseDetail= 'tb_table_use_detail ';

class TableUseDetailFields {
  static List<String> values = [
    table_use_detail_sqlite_id,
    table_use_detail_id,
    table_use_detail_key,
    table_use_sqlite_id,
    table_use_key,
    table_sqlite_id,
    original_table_sqlite_id,
    sync_status,
    created_at,
    updated_at,
    soft_delete
  ];

  static String table_use_detail_sqlite_id = 'table_use_detail_sqlite_id';
  static String table_use_detail_id = 'table_use_detail_id';
  static String table_use_detail_key = 'table_use_detail_key';
  static String table_use_sqlite_id = 'table_use_sqlite_id';
  static String table_use_key = 'table_use_key';
  static String table_sqlite_id = 'table_sqlite_id';
  static String original_table_sqlite_id = 'original_table_sqlite_id';
  static String sync_status = 'sync_status';
  static String created_at = 'created_at';
  static String updated_at = 'updated_at';
  static String soft_delete = 'soft_delete';
}

class TableUseDetail{
  int? table_use_detail_sqlite_id;
  int? table_use_detail_id;
  String? table_use_detail_key;
  String? table_use_sqlite_id;
  String? table_use_key;
  String? table_sqlite_id;
  String? original_table_sqlite_id;
  int? sync_status;
  String? created_at;
  String? updated_at;
  String? soft_delete;
  int? table_id;

  TableUseDetail(
      {this.table_use_detail_sqlite_id,
        this.table_use_detail_id,
        this.table_use_detail_key,
        this.table_use_sqlite_id,
        this.table_use_key,
        this.table_sqlite_id,
        this.original_table_sqlite_id,
        this.sync_status,
        this.created_at,
        this.updated_at,
        this.soft_delete,
        this.table_id});

  TableUseDetail copy({
    int? table_use_detail_sqlite_id,
    int? table_use_detail_id,
    String? table_use_detail_key,
    String? table_use_sqlite_id,
    String? table_use_key,
    String? table_sqlite_id,
    String? original_table_sqlite_id,
    int? sync_status,
    String? created_at,
    String? updated_at,
    String? soft_delete,
  }) =>
      TableUseDetail(
          table_use_detail_sqlite_id: table_use_detail_sqlite_id ?? this.table_use_detail_sqlite_id,
          table_use_detail_id: table_use_detail_id ?? this.table_use_detail_id,
          table_use_detail_key: table_use_detail_key ?? this.table_use_detail_key,
          table_use_sqlite_id: table_use_sqlite_id ?? this.table_use_sqlite_id,
          table_use_key: table_use_key ?? this.table_use_key,
          table_sqlite_id: table_sqlite_id ?? this.table_sqlite_id,
          original_table_sqlite_id: original_table_sqlite_id ?? this.original_table_sqlite_id,
          sync_status: sync_status ?? this.sync_status,
          created_at: created_at ?? this.created_at,
          updated_at: updated_at ?? this.updated_at,
          soft_delete: soft_delete ?? this.soft_delete);

  static TableUseDetail fromJson(Map<String, Object?> json) => TableUseDetail  (
    table_use_detail_sqlite_id: json[TableUseDetailFields.table_use_detail_sqlite_id] as int?,
    table_use_detail_id: json[TableUseDetailFields.table_use_detail_id] as int?,
    table_use_detail_key: json[TableUseDetailFields.table_use_detail_key] as String?,
    table_use_sqlite_id: json[TableUseDetailFields.table_use_sqlite_id] as String?,
    table_use_key: json[TableUseDetailFields.table_use_key] as String?,
    table_sqlite_id: json[TableUseDetailFields.table_sqlite_id] as String?,
    original_table_sqlite_id: json[TableUseDetailFields.original_table_sqlite_id] as String?,
    sync_status: json[TableUseDetailFields.sync_status] as int?,
    created_at: json[TableUseDetailFields.created_at] as String?,
    updated_at: json[TableUseDetailFields.updated_at] as String?,
    soft_delete: json[TableUseDetailFields .soft_delete] as String?,
    table_id: json['table_id'] as int?
  );

  Map<String, Object?> toJson() => {
    TableUseDetailFields.table_use_detail_sqlite_id: table_use_detail_sqlite_id,
    TableUseDetailFields.table_use_detail_id: table_use_detail_id,
    TableUseDetailFields.table_use_detail_key: table_use_detail_key,
    TableUseDetailFields.table_use_sqlite_id: table_use_sqlite_id,
    TableUseDetailFields.table_use_key: table_use_key,
    TableUseDetailFields.table_sqlite_id: table_sqlite_id,
    TableUseDetailFields.original_table_sqlite_id: original_table_sqlite_id,
    TableUseDetailFields.sync_status: sync_status,
    TableUseDetailFields.created_at: created_at,
    TableUseDetailFields.updated_at: updated_at,
    TableUseDetailFields.soft_delete: soft_delete,
  };

  Map syncJson() => {
    TableUseDetailFields.table_use_detail_key: table_use_detail_key,
    TableUseDetailFields.table_use_key: table_use_key,
    TableUseDetailFields.sync_status: sync_status,
    TableUseDetailFields.created_at: created_at,
    TableUseDetailFields.updated_at: updated_at,
    TableUseDetailFields.soft_delete: soft_delete,
    PosTableFields.table_id: table_id
  };
}

