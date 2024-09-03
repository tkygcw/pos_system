String? tableOrderTaxDetail = 'tb_order_tax_detail';

class OrderTaxDetailFields {
  static List<String> values = [
    order_tax_detail_sqlite_id,
    order_tax_detail_id,
    order_tax_detail_key,
    order_sqlite_id,
    order_id,
    order_key,
    tax_name,
    type,
    rate,
    tax_id,
    branch_link_tax_id,
    tax_amount,
    sync_status,
    created_at,
    updated_at,
    soft_delete
  ];

  static String order_tax_detail_sqlite_id = 'order_tax_detail_sqlite_id';
  static String order_tax_detail_id = 'order_tax_detail_id';
  static String order_tax_detail_key = 'order_tax_detail_key';
  static String order_sqlite_id = 'order_sqlite_id';
  static String order_id = 'order_id';
  static String order_key = 'order_key';
  static String tax_name = 'tax_name';
  static String type = 'type';
  static String rate = 'rate';
  static String tax_id = 'tax_id';
  static String branch_link_tax_id = 'branch_link_tax_id';
  static String tax_amount = 'tax_amount';
  static String sync_status = 'sync_status';
  static String created_at = 'created_at';
  static String updated_at = 'updated_at';
  static String soft_delete = 'soft_delete';
}

class OrderTaxDetail {
  int? order_tax_detail_sqlite_id;
  int? order_tax_detail_id;
  String? order_tax_detail_key;
  String? order_sqlite_id;
  String? order_id;
  String? order_key;
  String? tax_name;
  int? type;
  String? rate;
  String? tax_id;
  String? branch_link_tax_id;
  String? tax_amount;
  int? sync_status;
  String? created_at;
  String? updated_at;
  String? soft_delete;
  double? total_charge_amount;
  double? total_tax_amount;
  String? counterOpenDate;

  OrderTaxDetail(
      {this.order_tax_detail_sqlite_id,
        this.order_tax_detail_id,
        this.order_tax_detail_key,
        this.order_sqlite_id,
        this.order_id,
        this.order_key,
        this.tax_name,
        this.type,
        this.rate,
        this.tax_id,
        this.branch_link_tax_id,
        this.tax_amount,
        this.sync_status,
        this.created_at,
        this.updated_at,
        this.soft_delete,
        this.total_charge_amount,
        this.total_tax_amount,
        this.counterOpenDate
      });

  OrderTaxDetail copy({
    int? order_tax_detail_sqlite_id,
    int? order_tax_detail_id,
    String? order_tax_detail_key,
    String? order_sqlite_id,
    String? order_id,
    String? order_key,
    String? tax_name,
    int? type,
    String? rate,
    String? tax_id,
    String? branch_link_tax_id,
    String? tax_amount,
    int? sync_status,
    String? created_at,
    String? updated_at,
    String? soft_delete,
  }) =>
      OrderTaxDetail(
          order_tax_detail_sqlite_id: order_tax_detail_sqlite_id ?? this.order_tax_detail_sqlite_id,
          order_tax_detail_id: order_tax_detail_id ?? this.order_tax_detail_id,
          order_tax_detail_key: order_tax_detail_key ?? this.order_tax_detail_key,
          order_sqlite_id: order_sqlite_id ?? this.order_sqlite_id,
          order_id: order_id ?? this.order_id,
          order_key: order_key ?? this.order_key,
          tax_name: tax_name ?? this.tax_name,
          type: type ?? this.type,
          rate: rate ?? this.rate,
          tax_id: tax_id ?? this.tax_id,
          branch_link_tax_id: branch_link_tax_id ?? this.branch_link_tax_id,
          tax_amount: tax_amount ?? this.tax_amount,
          sync_status: sync_status ?? this.sync_status,
          created_at: created_at ?? this.created_at,
          updated_at: updated_at ?? this.updated_at,
          soft_delete: soft_delete ?? this.soft_delete);

  static OrderTaxDetail fromJson(Map<String, Object?> json) => OrderTaxDetail(
      order_tax_detail_sqlite_id: json[OrderTaxDetailFields.order_tax_detail_sqlite_id] as int?,
      order_tax_detail_id: json[OrderTaxDetailFields.order_tax_detail_id] as int?,
      order_tax_detail_key: json[OrderTaxDetailFields.order_tax_detail_key] as String?,
      order_sqlite_id: json[OrderTaxDetailFields.order_sqlite_id] as String?,
      order_id: json[OrderTaxDetailFields.order_id] as String?,
      order_key: json[OrderTaxDetailFields.order_key] as String?,
      tax_name: json[OrderTaxDetailFields.tax_name] as String?,
      type: json[OrderTaxDetailFields.type] as int?,
      rate: json[OrderTaxDetailFields.rate] as String?,
      tax_id: json[OrderTaxDetailFields.tax_id] as String?,
      branch_link_tax_id: json[OrderTaxDetailFields.branch_link_tax_id] as String?,
      tax_amount: json[OrderTaxDetailFields.tax_amount] as String?,
      sync_status: json[OrderTaxDetailFields.sync_status] as int?,
      created_at: json[OrderTaxDetailFields.created_at] as String?,
      updated_at: json[OrderTaxDetailFields.updated_at] as String?,
      soft_delete: json[OrderTaxDetailFields.soft_delete] as String?,
      total_charge_amount: json['total_charge_amount'] as double?,
      total_tax_amount: json['total_tax_amount'] as double?,
      counterOpenDate: json['counterOpenDate'] as String?,
  );

  Map<String, Object?> toJson() => {
    OrderTaxDetailFields.order_tax_detail_sqlite_id: order_tax_detail_sqlite_id,
    OrderTaxDetailFields.order_tax_detail_id: order_tax_detail_id,
    OrderTaxDetailFields.order_tax_detail_key: order_tax_detail_key,
    OrderTaxDetailFields.order_sqlite_id: order_sqlite_id,
    OrderTaxDetailFields.order_id: order_id,
    OrderTaxDetailFields.order_key: order_key,
    OrderTaxDetailFields.tax_name: tax_name,
    OrderTaxDetailFields.type: type,
    OrderTaxDetailFields.rate: rate,
    OrderTaxDetailFields.tax_id: tax_id,
    OrderTaxDetailFields.branch_link_tax_id: branch_link_tax_id,
    OrderTaxDetailFields.tax_amount: tax_amount,
    OrderTaxDetailFields.sync_status: sync_status,
    OrderTaxDetailFields.created_at: created_at,
    OrderTaxDetailFields.updated_at: updated_at,
    OrderTaxDetailFields.soft_delete: soft_delete,
  };


}