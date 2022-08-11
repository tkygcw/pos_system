String? tableRefund = 'tb_refund ';

class RefundFields {
  static List<String> values = [
    refund_sqlite_id,
    refund_id,
    company_id,
    branch_id,
    order_cache_id,
    order_detail_id,
    order_id,
    refund_by,
    bill_id,
    created_at,
    updated_at,
    soft_delete
  ];

  static String refund_sqlite_id = 'refund_sqlite_id';
  static String refund_id = 'refund_id';
  static String company_id = 'company_id';
  static String branch_id = 'branch_id';
  static String order_cache_id = 'order_cache_id';
  static String order_detail_id = 'order_detail_id';
  static String order_id = 'order_id';
  static String refund_by = 'refund_by';
  static String bill_id = 'bill_id';
  static String created_at = 'created_at';
  static String updated_at = 'updated_at';
  static String soft_delete = 'soft_delete';
}

class Refund{
  int? refund_sqlite_id;
  int? refund_id;
  String? company_id;
  String? branch_id;
  String? order_cache_id;
  String? order_detail_id;
  String? order_id;
  String? refund_by;
  String? bill_id;
  String? created_at;
  String? updated_at;
  String? soft_delete;

  Refund(
      {this.refund_sqlite_id,
        this.refund_id,
        this.company_id,
        this.branch_id,
        this.order_cache_id,
        this.order_detail_id,
        this.order_id,
        this.refund_by,
        this.bill_id,
        this.created_at,
        this.updated_at,
        this.soft_delete});

  Refund copy({
    int? refund_sqlite_id,
    int? refund_id,
    String? company_id,
    String? branch_id,
    String? order_cache_id,
    String? order_detail_id,
    String? order_id,
    String? refund_by,
    String? bill_id,
    String? created_at,
    String? updated_at,
    String? soft_delete,
  }) =>
      Refund(
          refund_sqlite_id: refund_sqlite_id ?? this.refund_sqlite_id,
          refund_id: refund_id ?? this.refund_id,
          company_id: company_id ?? this.company_id,
          branch_id: branch_id ?? this.branch_id,
          order_cache_id: order_cache_id ?? this.order_cache_id,
          order_detail_id: order_detail_id ?? this.order_detail_id,
          order_id: order_id ?? this.order_id,
          refund_by: refund_by ?? this.refund_by,
          bill_id: bill_id ?? this.bill_id,
          created_at: created_at ?? this.created_at,
          updated_at: updated_at ?? this.updated_at,
          soft_delete: soft_delete ?? this.soft_delete);

  static Refund fromJson(Map<String, Object?> json) => Refund (
    refund_sqlite_id: json[RefundFields.refund_sqlite_id] as int?,
    refund_id: json[RefundFields.refund_id] as int?,
    company_id: json[RefundFields.company_id] as String?,
    branch_id: json[RefundFields.branch_id] as String?,
    order_cache_id: json[RefundFields.order_cache_id] as String?,
    order_detail_id: json[RefundFields.order_detail_id] as String?,
    order_id: json[RefundFields.order_id] as String?,
    refund_by: json[RefundFields.refund_by] as String?,
    bill_id: json[RefundFields.bill_id] as String?,
    created_at: json[RefundFields.created_at] as String?,
    updated_at: json[RefundFields.updated_at] as String?,
    soft_delete: json[RefundFields.soft_delete] as String?,
  );

  Map<String, Object?> toJson() => {
    RefundFields.refund_sqlite_id: refund_sqlite_id,
    RefundFields.refund_id: refund_id,
    RefundFields.company_id: company_id,
    RefundFields.branch_id: branch_id,
    RefundFields.order_cache_id: order_cache_id,
    RefundFields.order_detail_id: order_detail_id,
    RefundFields.order_id: order_id,
    RefundFields.refund_by: refund_by,
    RefundFields.bill_id: bill_id,
    RefundFields.created_at: created_at,
    RefundFields.updated_at: updated_at,
    RefundFields.soft_delete: soft_delete,
  };
}
