import 'package:pos_system/object/settlement_link_payment.dart';

String? tableSettlement = 'tb_settlement';

class SettlementFields {
  static List<String> values = [
    settlement_sqlite_id,
    settlement_id,
    settlement_key,
    company_id,
    branch_id,
    total_bill,
    total_sales,
    total_refund_bill,
    total_refund_amount,
    total_discount,
    total_cancellation,
    total_charge,
    total_tax,
    settlement_by_user_id,
    settlement_by,
    status,
    sync_status,
    opened_at,
    created_at,
    updated_at,
    soft_delete
  ];

  static String settlement_sqlite_id = 'settlement_sqlite_id';
  static String settlement_id = 'settlement_id';
  static String settlement_key = 'settlement_key';
  static String company_id = 'company_id';
  static String branch_id = 'branch_id';
  static String total_bill = 'total_bill';
  static String total_sales = 'total_sales';
  static String total_refund_bill = 'total_refund_bill';
  static String total_refund_amount = 'total_refund_amount';
  static String total_discount = 'total_discount';
  static String total_cancellation = 'total_cancellation';
  static String total_charge = 'total_charge';
  static String total_tax = 'total_tax';
  static String settlement_by_user_id = 'settlement_by_user_id';
  static String settlement_by = 'settlement_by';
  static String status = 'status';
  static String sync_status = 'sync_status';
  static String opened_at = 'opened_at';
  static String created_at = 'created_at';
  static String updated_at = 'updated_at';
  static String soft_delete = 'soft_delete';
}

class Settlement{
  int? settlement_sqlite_id;
  int? settlement_id;
  String? settlement_key;
  String? company_id;
  String? branch_id;
  String? total_bill;
  String? total_sales;
  String? total_refund_bill;
  String? total_refund_amount;
  String? total_discount;
  String? total_cancellation;
  String? total_charge;
  String? total_tax;
  String? settlement_by_user_id;
  String? settlement_by;
  int? status;
  int? sync_status;
  String? opened_at;
  String? created_at;
  String? updated_at;
  String? soft_delete;
  int? all_bill;
  double? all_sales;
  int? all_refund_bill;
  double? all_refund_amount;
  double? all_discount;
  double? all_charge_amount;
  double? all_tax_amount;
  int? all_cancellation;
  List<SettlementLinkPayment>? settlementPayment;

  Settlement(
      {this.settlement_sqlite_id,
        this.settlement_id,
        this.settlement_key,
        this.company_id,
        this.branch_id,
        this.total_bill,
        this.total_sales,
        this.total_refund_bill,
        this.total_refund_amount,
        this.total_discount,
        this.total_cancellation,
        this.total_charge,
        this.total_tax,
        this.settlement_by_user_id,
        this.settlement_by,
        this.status,
        this.sync_status,
        this.opened_at,
        this.created_at,
        this.updated_at,
        this.soft_delete,
        this.all_bill,
        this.all_sales,
        this.all_refund_bill,
        this.all_refund_amount,
        this.all_discount,
        this.all_charge_amount,
        this.all_tax_amount,
        this.all_cancellation,
        this.settlementPayment
      });

  Settlement copy({
    int? settlement_sqlite_id,
    int? settlement_id,
    String? settlement_key,
    String? company_id,
    String? branch_id,
    String? total_bill,
    String? total_sales,
    String? total_refund_bill,
    String? total_refund_amount,
    String? total_discount,
    String? total_cancellation,
    String? total_charge,
    String? total_tax,
    String? settlement_by_user_id,
    String? settlement_by,
    int? status,
    int? sync_status,
    String? opened_at,
    String? created_at,
    String? updated_at,
    String? soft_delete,
  }) =>
      Settlement(
          settlement_sqlite_id: settlement_sqlite_id ?? this.settlement_sqlite_id,
          settlement_id: settlement_id ?? this.settlement_id,
          settlement_key: settlement_key ?? this.settlement_key,
          company_id: company_id ?? this.company_id,
          branch_id: branch_id ?? this.branch_id,
          total_bill: total_bill ?? this.total_bill,
          total_sales: total_sales ?? this.total_sales,
          total_refund_bill: total_refund_bill ?? this.total_refund_bill,
          total_refund_amount: total_refund_amount ?? this.total_refund_amount,
          total_discount: total_discount ?? this.total_discount,
          total_cancellation: total_cancellation ?? this.total_cancellation,
          total_charge: total_charge ?? this.total_charge,
          total_tax: total_tax ?? this.total_tax,
          settlement_by_user_id: settlement_by_user_id ?? this.settlement_by_user_id,
          settlement_by: settlement_by ?? this.settlement_by,
          status: status ?? this.status,
          sync_status: sync_status ?? this.sync_status,
          opened_at: opened_at ?? this.opened_at,
          created_at: created_at ?? this.created_at,
          updated_at: updated_at ?? this.updated_at,
          soft_delete: soft_delete ?? this.soft_delete);

  static Settlement fromJson(Map<String, Object?> json) => Settlement (
    settlement_sqlite_id: json[SettlementFields.settlement_sqlite_id] as int?,
    settlement_id: json[SettlementFields.settlement_id] as int?,
    settlement_key: json[SettlementFields.settlement_key] as String?,
    company_id: json[SettlementFields.company_id] as String?,
    branch_id: json[SettlementFields.branch_id] as String?,
    total_bill: json[SettlementFields.total_bill] as String?,
    total_sales: json[SettlementFields.total_sales] as String?,
    total_refund_bill: json[SettlementFields.total_refund_bill] as String?,
    total_refund_amount: json[SettlementFields.total_refund_amount] as String?,
    total_discount: json[SettlementFields.total_discount] as String?,
    total_cancellation: json[SettlementFields.total_cancellation] as String?,
    total_charge: json[SettlementFields.total_charge] as String?,
    total_tax: json[SettlementFields.total_tax] as String?,
    settlement_by_user_id: json[SettlementFields.settlement_by_user_id] as String?,
    settlement_by: json[SettlementFields.settlement_by] as String?,
    status: json[SettlementFields.status] as int?,
    sync_status: json[SettlementFields.sync_status] as int?,
    opened_at: json[SettlementFields.opened_at] as String?,
    created_at: json[SettlementFields.created_at] as String?,
    updated_at: json[SettlementFields.updated_at] as String?,
    soft_delete: json[SettlementFields.soft_delete] as String?,
    all_bill: json['all_bill'] as int?,
    all_sales: json['all_sales'] as double?,
    all_refund_bill: json['all_refund_bill'] as int?,
    all_refund_amount: json['all_refund_amount'] as double?,
    all_discount: json['all_discount'] as double?,
    all_charge_amount: json['all_charge_amount'] as double?,
    all_tax_amount: json['all_tax_amount'] as double?,
    all_cancellation: json['all_cancellation'] as int?

  );

  Map<String, Object?> toJson() => {
    SettlementFields.settlement_sqlite_id: settlement_sqlite_id,
    SettlementFields.settlement_id: settlement_id,
    SettlementFields.settlement_key: settlement_key,
    SettlementFields.company_id: company_id,
    SettlementFields.branch_id: branch_id,
    SettlementFields.total_bill: total_bill,
    SettlementFields.total_sales: total_sales,
    SettlementFields.total_refund_bill: total_refund_bill,
    SettlementFields.total_refund_amount: total_refund_amount,
    SettlementFields.total_discount: total_discount,
    SettlementFields.total_cancellation: total_cancellation,
    SettlementFields.total_charge: total_charge,
    SettlementFields.total_tax: total_tax,
    SettlementFields.settlement_by_user_id: settlement_by_user_id,
    SettlementFields.settlement_by: settlement_by,
    SettlementFields.status: status,
    SettlementFields.sync_status: sync_status,
    SettlementFields.opened_at: opened_at,
    SettlementFields.created_at: created_at,
    SettlementFields.updated_at: updated_at,
    SettlementFields.soft_delete: soft_delete,
  };
}
