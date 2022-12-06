String? tablePosTable = 'tb_table ';

class PosTableFields {
  static List<String> values = [
    table_sqlite_id,
    table_id,
    branch_id,
    number,
    seats,
    table_use_detail_key,
    status,
    sync_status,
    created_at,
    updated_at,
    soft_delete
  ];

  static String table_sqlite_id = 'table_sqlite_id';
  static String table_id = 'table_id';
  static String branch_id = 'branch_id';
  static String number = 'number';
  static String seats = 'seats';
  static String table_use_detail_key = 'table_use_detail_key';
  static String status = 'status';
  static String sync_status = 'sync_status';
  static String created_at = 'created_at';
  static String updated_at = 'updated_at';
  static String soft_delete = 'soft_delete';
}

class PosTable{
  int? table_sqlite_id;
  int? table_id;
  String? branch_id;
  String? number;
  String? seats;
  String? table_use_detail_key;
  int? status;
  int? sync_status;
  String? created_at;
  String? updated_at;
  String? soft_delete;
  double total_Amount = 0.0;
  String? group;
  String? cardColor;
  bool isSelected = false;

  PosTable(
      {this.table_sqlite_id,
        this.table_id,
        this.branch_id,
        this.number,
        this.seats,
        this.table_use_detail_key,
        this.status,
        this.sync_status,
        this.created_at,
        this.updated_at,
        this.soft_delete});

  PosTable copy({
    int? table_sqlite_id,
    int? table_id,
    String? branch_id,
    String? number,
    String? seats,
    String? table_use_detail_key,
    int? status,
    int? sync_status,
    String? created_at,
    String? updated_at,
    String? soft_delete,
  }) =>
      PosTable(
          table_sqlite_id: table_sqlite_id ?? this.table_sqlite_id,
          table_id: table_id ?? this.table_id,
          branch_id: branch_id ?? this.branch_id,
          number: number ?? this.number,
          seats: seats ?? this.seats,
          status: status ?? this.status,
          table_use_detail_key: table_use_detail_key ?? this.table_use_detail_key,
          sync_status: sync_status ?? this.sync_status,
          created_at: created_at ?? this.created_at,
          updated_at: updated_at ?? this.updated_at,
          soft_delete: soft_delete ?? this.soft_delete);

  static PosTable fromJson(Map<String, Object?> json) => PosTable  (
    table_sqlite_id: json[PosTableFields.table_sqlite_id] as int?,
    table_id: json[PosTableFields.table_id] as int?,
    branch_id: json[PosTableFields.branch_id] as String?,
    number: json[PosTableFields.number] as String?,
    seats: json[PosTableFields.seats] as String?,
    table_use_detail_key: json[PosTableFields.table_use_detail_key] as String?,
    status: json[PosTableFields.status] as int?,
    sync_status: json[PosTableFields.sync_status] as int?,
    created_at: json[PosTableFields.created_at] as String?,
    updated_at: json[PosTableFields.updated_at] as String?,
    soft_delete: json[PosTableFields .soft_delete] as String?,
  );

  Map<String, Object?> toJson() => {
    PosTableFields.table_sqlite_id: table_sqlite_id,
    PosTableFields.table_id: table_id,
    PosTableFields.branch_id: branch_id,
    PosTableFields.number: number,
    PosTableFields.seats: seats,
    PosTableFields.table_use_detail_key: table_use_detail_key,
    PosTableFields.status: status,
    PosTableFields.sync_status: sync_status,
    PosTableFields.created_at: created_at,
    PosTableFields.updated_at: updated_at,
    PosTableFields.soft_delete: soft_delete,
  };


}

