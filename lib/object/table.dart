String? tablePosTable = 'tb_table ';

class PosTableFields {
  static List<String> values = [
    table_sqlite_id,
    table_url,
    table_id,
    branch_id,
    number,
    seats,
    table_use_detail_key,
    table_use_key,
    status,
    sync_status,
    dx,
    dy,
    created_at,
    updated_at,
    soft_delete,
  ];

  static String table_sqlite_id = 'table_sqlite_id';
  static String table_url = 'table_url';
  static String table_id = 'table_id';
  static String branch_id = 'branch_id';
  static String number = 'number';
  static String seats = 'seats';
  static String table_use_detail_key = 'table_use_detail_key';
  static String table_use_key = 'table_use_key';
  static String status = 'status';
  static String sync_status = 'sync_status';
  static String dx = 'table_dx';
  static String dy = 'table_dy';
  static String created_at = 'created_at';
  static String updated_at = 'updated_at';
  static String soft_delete = 'soft_delete';
}

class PosTable{
  int? table_sqlite_id;
  String? table_url;
  int? table_id;
  String? branch_id;
  String? number;
  String? seats;
  String? table_use_detail_key;
  String? table_use_key;
  int? status;
  int? sync_status;
  String? dx;
  String? dy;
  String? created_at;
  String? updated_at;
  String? soft_delete;
  String? total_amount;
  String? group;
  String? card_color;
  bool isSelected = false;
  String? qrOrderUrl;


  PosTable(
      {this.table_sqlite_id,
        this.table_url,
        this.table_id,
        this.branch_id,
        this.number,
        this.seats,
        this.table_use_detail_key,
        this.table_use_key,
        this.status,
        this.sync_status,
        this.dx,
        this.dy,
        this.created_at,
        this.updated_at,
        this.soft_delete,
        this.group,
        this.card_color,
        this.qrOrderUrl,
        this.total_amount
      });

  PosTable copy({
    int? table_sqlite_id,
    String? table_url,
    int? table_id,
    String? branch_id,
    String? number,
    String? seats,
    String? table_use_detail_key,
    String? table_use_key,
    int? status,
    int? sync_status,
    String? dx,
    String? dy,
    String? created_at,
    String? updated_at,
    String? soft_delete,

  }) =>
      PosTable(
          table_sqlite_id: table_sqlite_id ?? this.table_sqlite_id,
          table_url: table_url ?? this.table_url,
          table_id: table_id ?? this.table_id,
          branch_id: branch_id ?? this.branch_id,
          number: number ?? this.number,
          seats: seats ?? this.seats,
          status: status ?? this.status,
          dx: dx ?? this.dx,
          dy: dy ?? this.dy,
          table_use_detail_key: table_use_detail_key ?? this.table_use_detail_key,
          table_use_key: table_use_key ?? this.table_use_key,
          sync_status: sync_status ?? this.sync_status,
          created_at: created_at ?? this.created_at,
          updated_at: updated_at ?? this.updated_at,
          soft_delete: soft_delete ?? this.soft_delete,

      );

  static PosTable fromJson(Map<String, Object?> json) => PosTable(
    table_sqlite_id: json[PosTableFields.table_sqlite_id] as int?,
    table_url: json[PosTableFields.table_url] as String?,
    table_id: json[PosTableFields.table_id] as int?,
    branch_id: json[PosTableFields.branch_id] as String?,
    number: json[PosTableFields.number] as String?,
    seats: json[PosTableFields.seats] as String?,
    table_use_detail_key: json[PosTableFields.table_use_detail_key] as String?,
    table_use_key: json[PosTableFields.table_use_key] as String?,
    status: json[PosTableFields.status] as int?,
    sync_status: json[PosTableFields.sync_status] as int?,
    dx: json[PosTableFields.dx] as String?,
    dy: json[PosTableFields.dy] as String?,
    created_at: json[PosTableFields.created_at] as String?,
    updated_at: json[PosTableFields.updated_at] as String?,
    soft_delete: json[PosTableFields .soft_delete] as String?,
    group: json['group'] as String?,
    card_color: json['card_color'] as String?,
    total_amount: json['total_amount'] as String?

  );

  Map<String, Object?> toJson() => {
    PosTableFields.table_sqlite_id: table_sqlite_id,
    PosTableFields.table_url: table_url,
    PosTableFields.table_id: table_id,
    PosTableFields.branch_id: branch_id,
    PosTableFields.number: number,
    PosTableFields.seats: seats,
    PosTableFields.table_use_detail_key: table_use_detail_key,
    PosTableFields.table_use_key: table_use_key,
    PosTableFields.status: status,
    PosTableFields.sync_status: sync_status,
    PosTableFields.dx: dx,
    PosTableFields.dy: dy,
    PosTableFields.created_at: created_at,
    PosTableFields.updated_at: updated_at,
    PosTableFields.soft_delete: soft_delete,
    'group': group,
    'card_color': card_color,
    'total_amount': total_amount
  };


}

