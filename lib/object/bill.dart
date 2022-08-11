String? tableBill = 'tb_bill';

class BillFields {
  static List<String> values = [
    bill_sqlite_id,
    bill_id,
    order_id,
    amount,
    is_refund,
    created_at,
    updated_at,
    soft_delete
  ];

  static String bill_sqlite_id = 'bill_sqlite_id';
  static String bill_id = 'bill_id';
  static String company_id = 'company_id';
  static String branch_id = 'branch_id';
  static String order_id = 'order_id';
  static String amount = 'amount';
  static String is_refund = 'is_refund';
  static String created_at = 'created_at';
  static String updated_at = 'updated_at';
  static String soft_delete = 'soft_delete';
}

class Bill {
  int? bill_sqlite_id;
  int? bill_id;
  String? company_id;
  String? branch_id;
  String? order_id;
  String? amount;
  int? is_refund;
  String? created_at;
  String? updated_at;
  String? soft_delete;

  Bill(
      {this.bill_sqlite_id,
      this.bill_id,
      this.company_id,
      this.branch_id,
      this.order_id,
      this.amount,
      this.is_refund,
      this.created_at,
      this.updated_at,
      this.soft_delete});

  Bill copy({
    int? bill_sqlite_id,
    int? bill_id,
    String? company_id,
    String? branch_id,
    String? order_id,
    String? amount,
    int? is_refund,
    String? created_at,
    String? updated_at,
    String? soft_delete,
  }) =>
      Bill(
          bill_sqlite_id: bill_sqlite_id ?? this.bill_sqlite_id,
          bill_id: bill_id ?? this.bill_id,
          company_id: company_id ?? this.company_id,
          branch_id: branch_id ?? this.branch_id,
          order_id: order_id ?? this.order_id,
          amount: amount ?? this.amount,
          is_refund: is_refund ?? this.is_refund,
          created_at: created_at ?? this.created_at,
          updated_at: updated_at ?? this.updated_at,
          soft_delete: soft_delete ?? this.soft_delete);

  static Bill fromJson(Map<String, Object?> json) => Bill(
        bill_sqlite_id: json[BillFields.bill_sqlite_id] as int?,
        bill_id: json[BillFields.bill_id] as int?,
        company_id: json[BillFields.company_id] as String?,
        branch_id: json[BillFields.branch_id] as String?,
        order_id: json[BillFields.order_id] as String?,
        amount: json[BillFields.amount] as String?,
        is_refund: json[BillFields.is_refund] as int?,
        created_at: json[BillFields.created_at] as String?,
        updated_at: json[BillFields.updated_at] as String?,
        soft_delete: json[BillFields.soft_delete] as String?,
      );

  Map<String, Object?> toJson() => {
        BillFields.bill_sqlite_id: bill_sqlite_id,
        BillFields.bill_id: bill_id,
        BillFields.company_id: company_id,
        BillFields.branch_id: branch_id,
        BillFields.order_id: order_id,
        BillFields.amount: amount,
        BillFields.is_refund: is_refund,
        BillFields.created_at: created_at,
        BillFields.updated_at: updated_at,
        BillFields.soft_delete: soft_delete,
      };
}
