String? tableCashRecord = 'tb_cash_record ';

class CashRecordFields {
  static List<String> values = [
    cash_record_sqlite_id,
    cash_record_id,
    cash_record_key,
    company_id,
    branch_id,
    remark,
    payment_name,
    payment_type_id,
    type,
    amount,
    user_id,
    settlement_key,
    settlement_date,
    sync_status,
    created_at,
    updated_at,
    soft_delete
  ];

  static String cash_record_sqlite_id = 'cash_record_sqlite_id';
  static String cash_record_id = 'cash_record_id';
  static String cash_record_key = 'cash_record_key';
  static String company_id = 'company_id';
  static String branch_id = 'branch_id';
  static String remark = 'remark';
  static String payment_name = 'payment_name';
  static String payment_type_id = 'payment_type_id';
  static String type = 'type';
  static String amount = 'amount';
  static String user_id = 'user_id';
  static String settlement_key = 'settlement_key';
  static String settlement_date = 'settlement_date';
  static String sync_status = 'sync_status';
  static String created_at = 'created_at';
  static String updated_at = 'updated_at';
  static String soft_delete = 'soft_delete';
}

class CashRecord {
  int? cash_record_sqlite_id;
  int? cash_record_id;
  String? cash_record_key;
  String? company_id;
  String? branch_id;
  String? remark;
  String? payment_name;
  String? payment_type_id;
  int? type;
  String? amount;
  String? user_id;
  String? settlement_key;
  String? settlement_date;
  int? sync_status;
  String? created_at;
  String? updated_at;
  String? soft_delete;
  String? userName;
  String? payment_method;

  CashRecord(
      {this.cash_record_sqlite_id,
      this.cash_record_id,
      this.cash_record_key,
      this.company_id,
      this.branch_id,
      this.remark,
      this.payment_name,
      this.payment_type_id,
      this.type,
      this.amount,
      this.user_id,
      this.settlement_key,
      this.settlement_date,
      this.sync_status,
      this.created_at,
      this.updated_at,
      this.soft_delete,
      this.userName,
      this.payment_method,
      });

  CashRecord copy({
    int? cash_record_sqlite_id,
    int? cash_record_id,
    String? cash_record_key,
    String? company_id,
    String? branch_id,
    String? remark,
    String? payment_name,
    String? payment_type_id,
    int? type,
    String? amount,
    String? user_id,
    String? settlement_key,
    String? settlement_date,
    int? sync_status,
    String? created_at,
    String? updated_at,
    String? soft_delete,
  }) =>
      CashRecord(
          cash_record_sqlite_id: cash_record_sqlite_id ?? this.cash_record_sqlite_id,
          cash_record_id: cash_record_id ?? this.cash_record_id,
          cash_record_key: cash_record_key ?? this.cash_record_key,
          company_id: company_id ?? this.company_id,
          branch_id: branch_id ?? this.branch_id,
          remark: remark ?? this.remark,
          payment_name: payment_name ?? this.payment_name,
          payment_type_id: payment_type_id ?? this.payment_type_id,
          type: type ?? this.type,
          amount: amount ?? this.amount,
          user_id: user_id ?? this.user_id,
          settlement_key: settlement_key ?? this.settlement_key,
          settlement_date: settlement_date ?? this.settlement_date,
          sync_status: sync_status ?? this.sync_status,
          created_at: created_at ?? this.created_at,
          updated_at: updated_at ?? this.updated_at,
          soft_delete: soft_delete ?? this.soft_delete);

  static CashRecord fromJson(Map<String, Object?> json) => CashRecord(
      cash_record_sqlite_id: json[CashRecordFields.cash_record_sqlite_id] as int?,
      cash_record_id: json[CashRecordFields.cash_record_id] as int?,
      cash_record_key: json[CashRecordFields.cash_record_key] as String?,
      company_id: json[CashRecordFields.company_id] as String?,
      branch_id: json[CashRecordFields.branch_id] as String?,
      remark: json[CashRecordFields.remark] as String?,
      payment_name: json[CashRecordFields.payment_name] as String?,
      payment_type_id: json[CashRecordFields.payment_type_id] as String?,
      type: json[CashRecordFields.type] as int?,
      amount: json[CashRecordFields.amount] as String?,
      user_id: json[CashRecordFields.user_id] as String?,
      settlement_key: json[CashRecordFields.settlement_key] as String?,
      settlement_date: json[CashRecordFields.settlement_date] as String?,
      sync_status: json[CashRecordFields.sync_status] as int?,
      created_at: json[CashRecordFields.created_at] as String?,
      updated_at: json[CashRecordFields.updated_at] as String?,
      soft_delete: json[CashRecordFields.soft_delete] as String?,
      userName: json['name'] as String?,
      payment_method: json['payment_method'] as String?,
  );

  Map<String, Object?> toJson() => {
    CashRecordFields.cash_record_sqlite_id: cash_record_sqlite_id,
    CashRecordFields.cash_record_id: cash_record_id,
    CashRecordFields.cash_record_key: cash_record_key,
    CashRecordFields.company_id: company_id,
    CashRecordFields.branch_id: branch_id,
    CashRecordFields.remark: remark,
    CashRecordFields.payment_name: payment_name,
    CashRecordFields.payment_type_id: payment_type_id,
    CashRecordFields.type: type,
    CashRecordFields.amount: amount,
    CashRecordFields.user_id: user_id,
    CashRecordFields.settlement_key: settlement_key,
    CashRecordFields.settlement_date: settlement_date,
    CashRecordFields.sync_status: sync_status,
    CashRecordFields.created_at: created_at,
    CashRecordFields.updated_at: updated_at,
    CashRecordFields.soft_delete: soft_delete,
  };
}
