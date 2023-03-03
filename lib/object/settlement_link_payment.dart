String? tableSettlementLinkPayment = 'tb_settlement_link_payment';

class SettlementLinkPaymentFields {
  static List<String> values = [
    settlement_link_payment_sqlite_id,
    settlement_link_payment_id,
    settlement_link_payment_key,
    company_id,
    branch_id,
    settlement_sqlite_id,
    settlement_key,
    total_bill,
    total_sales,
    payment_link_company_id,
    status,
    sync_status,
    created_at,
    updated_at,
    soft_delete
  ];

  static String settlement_link_payment_sqlite_id = 'settlement_link_payment_sqlite_id';
  static String settlement_link_payment_id = 'settlement_link_payment_id';
  static String settlement_link_payment_key = 'settlement_link_payment_key';
  static String company_id = 'company_id';
  static String branch_id = 'branch_id';
  static String settlement_sqlite_id = 'settlement_sqlite_id';
  static String settlement_key = 'settlement_key';
  static String total_bill = 'total_bill';
  static String total_sales = 'total_sales';
  static String payment_link_company_id = 'payment_link_company_id';
  static String status = 'status';
  static String sync_status = 'sync_status';
  static String created_at = 'created_at';
  static String updated_at = 'updated_at';
  static String soft_delete = 'soft_delete';
}

class SettlementLinkPayment{
  int? settlement_link_payment_sqlite_id;
  int? settlement_link_payment_id;
  String? settlement_link_payment_key;
  String? company_id;
  String? branch_id;
  String? settlement_sqlite_id;
  String? settlement_key;
  String? total_bill;
  String? total_sales;
  String? payment_link_company_id;
  int? status;
  int? sync_status;
  String? created_at;
  String? updated_at;
  String? soft_delete;

  SettlementLinkPayment(
      {this.settlement_link_payment_sqlite_id,
        this.settlement_link_payment_id,
        this.settlement_link_payment_key,
        this.company_id,
        this.branch_id,
        this.settlement_sqlite_id,
        this.settlement_key,
        this.total_bill,
        this.total_sales,
        this.payment_link_company_id,
        this.status,
        this.sync_status,
        this.created_at,
        this.updated_at,
        this.soft_delete});

  SettlementLinkPayment copy({
    int? settlement_link_payment_sqlite_id,
    int? settlement_link_payment_id,
    String? settlement_link_payment_key,
    String? company_id,
    String? branch_id,
    String? settlement_sqlite_id,
    String? settlement_key,
    String? total_bill,
    String? total_sales,
    String? payment_link_company_id,
    int? status,
    int? sync_status,
    String? created_at,
    String? updated_at,
    String? soft_delete,
  }) =>
      SettlementLinkPayment(
          settlement_link_payment_sqlite_id: settlement_link_payment_sqlite_id ?? this.settlement_link_payment_sqlite_id,
          settlement_link_payment_id: settlement_link_payment_id ?? this.settlement_link_payment_id,
          settlement_link_payment_key: settlement_link_payment_key ?? this.settlement_link_payment_key,
          company_id: company_id ?? this.company_id,
          branch_id: branch_id ?? this.branch_id,
          settlement_sqlite_id: settlement_sqlite_id ?? this.settlement_sqlite_id,
          settlement_key: settlement_key ?? this.settlement_key,
          total_bill: total_bill ?? this.total_bill,
          total_sales: total_sales ?? this.total_sales,
          payment_link_company_id: payment_link_company_id ?? this.payment_link_company_id,
          status: status ?? this.status,
          sync_status: sync_status ?? this.sync_status,
          created_at: created_at ?? this.created_at,
          updated_at: updated_at ?? this.updated_at,
          soft_delete: soft_delete ?? this.soft_delete);

  static SettlementLinkPayment fromJson(Map<String, Object?> json) => SettlementLinkPayment (
    settlement_link_payment_sqlite_id: json[SettlementLinkPaymentFields.settlement_link_payment_sqlite_id] as int?,
    settlement_link_payment_id: json[SettlementLinkPaymentFields.settlement_link_payment_id] as int?,
    settlement_link_payment_key: json[SettlementLinkPaymentFields.settlement_link_payment_key] as String?,
    company_id: json[SettlementLinkPaymentFields.company_id] as String?,
    branch_id: json[SettlementLinkPaymentFields.branch_id] as String?,
    settlement_sqlite_id: json[SettlementLinkPaymentFields.settlement_sqlite_id] as String?,
    settlement_key: json[SettlementLinkPaymentFields.settlement_key] as String?,
    total_bill: json[SettlementLinkPaymentFields.total_bill] as String?,
    total_sales: json[SettlementLinkPaymentFields.total_sales] as String?,
    payment_link_company_id: json[SettlementLinkPaymentFields.payment_link_company_id] as String?,
    status: json[SettlementLinkPaymentFields.status] as int?,
    sync_status: json[SettlementLinkPaymentFields.sync_status] as int?,
    created_at: json[SettlementLinkPaymentFields.created_at] as String?,
    updated_at: json[SettlementLinkPaymentFields.updated_at] as String?,
    soft_delete: json[SettlementLinkPaymentFields.soft_delete] as String?,
  );

  Map<String, Object?> toJson() => {
    SettlementLinkPaymentFields.settlement_link_payment_sqlite_id: settlement_link_payment_sqlite_id,
    SettlementLinkPaymentFields.settlement_link_payment_id: settlement_link_payment_id,
    SettlementLinkPaymentFields.settlement_link_payment_key: settlement_link_payment_key,
    SettlementLinkPaymentFields.company_id: company_id,
    SettlementLinkPaymentFields.branch_id: branch_id,
    SettlementLinkPaymentFields.settlement_sqlite_id: settlement_sqlite_id,
    SettlementLinkPaymentFields.settlement_key: settlement_key,
    SettlementLinkPaymentFields.total_bill: total_bill,
    SettlementLinkPaymentFields.total_sales: total_sales,
    SettlementLinkPaymentFields.payment_link_company_id: payment_link_company_id,
    SettlementLinkPaymentFields.status: status,
    SettlementLinkPaymentFields.sync_status: sync_status,
    SettlementLinkPaymentFields.created_at: created_at,
    SettlementLinkPaymentFields.updated_at: updated_at,
    SettlementLinkPaymentFields.soft_delete: soft_delete,
  };
}
