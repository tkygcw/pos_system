String? tableDynamicQR = 'tb_dynamic_qr';

class DynamicQRFields {
  static List<String> values = [
    dynamic_qr_sqlite_id,
    dynamic_qr_id,
    dynamic_qr_key,
    branch_id,
    qr_code_size,
    paper_size,
    sync_status,
    created_at,
    updated_at,
    soft_delete
  ];

  static String dynamic_qr_sqlite_id = 'dynamic_qr_sqlite_id';
  static String dynamic_qr_id = 'dynamic_qr_id';
  static String dynamic_qr_key = 'dynamic_qr_key';
  static String branch_id = 'branch_id';
  static String qr_code_size = 'qr_code_size';
  static String paper_size = 'paper_size';
  static String sync_status = 'sync_status';
  static String created_at = 'created_at';
  static String updated_at = 'updated_at';
  static String soft_delete = 'soft_delete';

}

class DynamicQR {
  int? dynamic_qr_sqlite_id;
  int? dynamic_qr_id;
  String? dynamic_qr_key;
  String? branch_id;
  int? qr_code_size;
  String? paper_size;
  int? sync_status;
  String? created_at;
  String? updated_at;
  String? soft_delete;

  DynamicQR(
      {this.dynamic_qr_sqlite_id,
        this.dynamic_qr_id,
        this.dynamic_qr_key,
        this.branch_id,
        this.qr_code_size,
        this.paper_size,
        this.sync_status,
        this.created_at,
        this.updated_at,
        this.soft_delete});

  DynamicQR copy({
    int? dynamic_qr_sqlite_id,
    int? dynamic_qr_id,
    String? dynamic_qr_key,
    String? branch_id,
    int? qr_code_size,
    String? paper_size,
    int? sync_status,
    String? created_at,
    String? updated_at,
    String? soft_delete
  }) =>
      DynamicQR(
          dynamic_qr_sqlite_id: dynamic_qr_sqlite_id ?? this.dynamic_qr_sqlite_id,
          dynamic_qr_id: dynamic_qr_id ?? this.dynamic_qr_id,
          dynamic_qr_key: dynamic_qr_key ?? this.dynamic_qr_key,
          branch_id: branch_id ?? this.branch_id,
          qr_code_size: qr_code_size ?? this.qr_code_size,
          paper_size: paper_size ?? this.paper_size,
          sync_status: sync_status ?? this.sync_status,
          created_at: created_at ?? this.created_at,
          updated_at: updated_at ?? this.updated_at,
          soft_delete: soft_delete ?? this.soft_delete);

  static DynamicQR fromJson(Map<String, Object?> json) => DynamicQR(
    dynamic_qr_sqlite_id: json[DynamicQRFields.dynamic_qr_sqlite_id] as int?,
    dynamic_qr_id: json[DynamicQRFields.dynamic_qr_id] as int?,
    dynamic_qr_key: json[DynamicQRFields.dynamic_qr_key] as String?,
    branch_id: json[DynamicQRFields.branch_id] as String?,
    qr_code_size: json[DynamicQRFields.qr_code_size] as int?,
    paper_size: json[DynamicQRFields.paper_size] as String?,
    sync_status: json[DynamicQRFields.sync_status] as int?,
    created_at: json[DynamicQRFields.created_at] as String?,
    updated_at: json[DynamicQRFields.updated_at] as String?,
    soft_delete: json[DynamicQRFields.soft_delete] as String?,
  );

  Map<String, Object?> toJson() => {
    DynamicQRFields.dynamic_qr_sqlite_id: dynamic_qr_sqlite_id,
    DynamicQRFields.dynamic_qr_id: dynamic_qr_id,
    DynamicQRFields.dynamic_qr_key: dynamic_qr_key,
    DynamicQRFields.branch_id: branch_id,
    DynamicQRFields.qr_code_size: qr_code_size,
    DynamicQRFields.paper_size: paper_size,
    DynamicQRFields.sync_status: sync_status,
    DynamicQRFields.created_at: created_at,
    DynamicQRFields.updated_at: updated_at,
    DynamicQRFields.soft_delete: soft_delete,
  };
}
