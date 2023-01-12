String? tableRefund = 'tb_refund ';

class RefundFields {
  static List<String> values = [
    refund_sqlite_id,
    refund_id,
    refund_key,
    company_id,
    branch_id,
    order_cache_sqlite_id,
    order_cache_key,
    order_sqlite_id,
    order_key,
    refund_by,
    refund_by_user_id,
    bill_id,
    sync_status,
    created_at,
    updated_at,
    soft_delete
  ];

  static String refund_sqlite_id = 'refund_sqlite_id';
  static String refund_id = 'refund_id';
  static String refund_key = 'refund_key';
  static String company_id = 'company_id';
  static String branch_id = 'branch_id';
  static String order_cache_sqlite_id = 'order_cache_sqlite_id';
  static String order_cache_key = 'order_cache_key';
  static String order_sqlite_id = 'order_sqlite_id';
  static String order_key = 'order_key';
  static String refund_by = 'refund_by';
  static String refund_by_user_id = 'refund_by_user_id';
  static String bill_id = 'bill_id';
  static String sync_status = 'sync_status';
  static String created_at = 'created_at';
  static String updated_at = 'updated_at';
  static String soft_delete = 'soft_delete';
}

class Refund{
  int? refund_sqlite_id;
  int? refund_id;
  String? refund_key;
  String? company_id;
  String? branch_id;
  String? order_cache_sqlite_id;
  String? order_cache_key;
  String? order_sqlite_id;
  String? order_key;
  String? refund_by;
  String? refund_by_user_id;
  String? bill_id;
  int? sync_status;
  String? created_at;
  String? updated_at;
  String? soft_delete;

  Refund(
      {this.refund_sqlite_id,
        this.refund_id,
        this.refund_key,
        this.company_id,
        this.branch_id,
        this.order_cache_sqlite_id,
        this.order_cache_key,
        this.order_sqlite_id,
        this.order_key,
        this.refund_by,
        this.refund_by_user_id,
        this.bill_id,
        this.sync_status,
        this.created_at,
        this.updated_at,
        this.soft_delete});

  Refund copy({
    int? refund_sqlite_id,
    int? refund_id,
    String? refund_key,
    String? company_id,
    String? branch_id,
    String? order_cache_sqlite_id,
    String? order_cache_key,
    String? order_sqlite_id,
    String? order_key,
    String? refund_by,
    String? refund_by_user_id,
    String? bill_id,
    int? sync_status,
    String? created_at,
    String? updated_at,
    String? soft_delete,
  }) =>
      Refund(
          refund_sqlite_id: refund_sqlite_id ?? this.refund_sqlite_id,
          refund_id: refund_id ?? this.refund_id,
          refund_key: refund_key ?? this.refund_key,
          company_id: company_id ?? this.company_id,
          branch_id: branch_id ?? this.branch_id,
          order_cache_sqlite_id: order_cache_sqlite_id ?? this.order_cache_sqlite_id,
          order_cache_key: order_cache_key ?? this.order_cache_key,
          order_sqlite_id: order_sqlite_id ?? this.order_sqlite_id,
          order_key: order_key ?? this.order_key,
          refund_by: refund_by ?? this.refund_by,
          refund_by_user_id: refund_by_user_id ?? this.refund_by_user_id,
          bill_id: bill_id ?? this.bill_id,
          sync_status: sync_status ?? this.sync_status,
          created_at: created_at ?? this.created_at,
          updated_at: updated_at ?? this.updated_at,
          soft_delete: soft_delete ?? this.soft_delete);

  static Refund fromJson(Map<String, Object?> json) => Refund (
    refund_sqlite_id: json[RefundFields.refund_sqlite_id] as int?,
    refund_id: json[RefundFields.refund_id] as int?,
    refund_key: json[RefundFields.refund_key] as String?,
    company_id: json[RefundFields.company_id] as String?,
    branch_id: json[RefundFields.branch_id] as String?,
    order_cache_sqlite_id: json[RefundFields.order_cache_sqlite_id] as String?,
    order_cache_key: json[RefundFields.order_cache_key] as String?,
    order_sqlite_id: json[RefundFields.order_sqlite_id] as String?,
    order_key: json[RefundFields.order_key] as String?,
    refund_by: json[RefundFields.refund_by] as String?,
    refund_by_user_id: json[RefundFields.refund_by_user_id] as String?,
    bill_id: json[RefundFields.bill_id] as String?,
    sync_status: json[RefundFields.sync_status] as int?,
    created_at: json[RefundFields.created_at] as String?,
    updated_at: json[RefundFields.updated_at] as String?,
    soft_delete: json[RefundFields.soft_delete] as String?,
  );

  Map<String, Object?> toJson() => {
    RefundFields.refund_sqlite_id: refund_sqlite_id,
    RefundFields.refund_id: refund_id,
    RefundFields.refund_key: refund_key,
    RefundFields.company_id: company_id,
    RefundFields.branch_id: branch_id,
    RefundFields.order_cache_sqlite_id: order_cache_sqlite_id,
    RefundFields.order_cache_key: order_cache_key,
    RefundFields.order_sqlite_id: order_sqlite_id,
    RefundFields.order_key: order_key,
    RefundFields.refund_by: refund_by,
    RefundFields.refund_by_user_id: refund_by_user_id,
    RefundFields.bill_id: bill_id,
    RefundFields.sync_status: sync_status,
    RefundFields.created_at: created_at,
    RefundFields.updated_at: updated_at,
    RefundFields.soft_delete: soft_delete,
  };
}
