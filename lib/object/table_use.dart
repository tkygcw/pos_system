String? tableTableUse = 'tb_table_use ';

class TableUseFields {
  static List<String> values = [
    table_use_sqlite_id,
    table_use_id,
    table_use_key,
    branch_id,
    order_cache_key,
    cardColor,
    sync_status,
    created_at,
    updated_at,
    soft_delete
  ];

  static String table_use_sqlite_id = 'table_use_sqlite_id';
  static String table_use_id = 'table_use_id';
  static String table_use_key = 'table_use_key';
  static String branch_id = 'branch_id';
  static String order_cache_key = 'order_cache_key';
  static String cardColor = 'cardColor';
  static String sync_status = 'sync_status';
  static String created_at = 'created_at';
  static String updated_at = 'updated_at';
  static String soft_delete = 'soft_delete';
}

class TableUse{
  int? table_use_sqlite_id;
  int? table_use_id;
  String? table_use_key;
  int? branch_id;
  String? order_cache_key;
  String? cardColor;
  int? sync_status;
  String? created_at;
  String? updated_at;
  String? soft_delete;

  TableUse(
      {this.table_use_sqlite_id,
        this.table_use_id,
        this.table_use_key,
        this.order_cache_key,
        this.branch_id,
        this.cardColor,
        this.sync_status,
        this.created_at,
        this.updated_at,
        this.soft_delete});

  TableUse copy({
    int? table_use_sqlite_id,
    int? table_use_id,
    String? table_use_key,
    int? branch_id,
    String? order_cache_key,
    String? cardColor,
    int? sync_status,
    String? created_at,
    String? updated_at,
    String? soft_delete,
  }) =>
      TableUse(
          table_use_sqlite_id: table_use_sqlite_id ?? this.table_use_sqlite_id,
          table_use_id: table_use_id ?? this.table_use_id,
          table_use_key: table_use_key ?? this.table_use_key,
          branch_id: branch_id ?? this.branch_id,
          order_cache_key: order_cache_key ?? this.order_cache_key,
          cardColor: cardColor ?? this.cardColor,
          sync_status: sync_status ?? this.sync_status,
          created_at: created_at ?? this.created_at,
          updated_at: updated_at ?? this.updated_at,
          soft_delete: soft_delete ?? this.soft_delete);

  static TableUse fromJson(Map<String, Object?> json) => TableUse  (
    table_use_sqlite_id: json[TableUseFields.table_use_sqlite_id] as int?,
    table_use_id: json[TableUseFields.table_use_id] as int?,
    table_use_key: json[TableUseFields.table_use_key] as String?,
    branch_id: json[TableUseFields.branch_id] as int?,
    order_cache_key: json[TableUseFields.order_cache_key] as String?,
    cardColor: json[TableUseFields.cardColor] as String?,
    sync_status: json[TableUseFields.sync_status] as int?,
    created_at: json[TableUseFields.created_at] as String?,
    updated_at: json[TableUseFields.updated_at] as String?,
    soft_delete: json[TableUseFields .soft_delete] as String?,
  );

  Map<String, Object?> toJson() => {
    TableUseFields.table_use_sqlite_id: table_use_sqlite_id,
    TableUseFields.table_use_id: table_use_id,
    TableUseFields.table_use_key: table_use_key,
    TableUseFields.branch_id: branch_id,
    TableUseFields.order_cache_key: order_cache_key,
    TableUseFields.cardColor: cardColor,
    TableUseFields.sync_status: sync_status,
    TableUseFields.created_at: created_at,
    TableUseFields.updated_at: updated_at,
    TableUseFields.soft_delete: soft_delete,
  };
}

