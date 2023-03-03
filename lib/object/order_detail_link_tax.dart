String? tableOrderDetailLinkTax = 'tb_order_detail_link_tax';

class OrderDetailLinkTaxFields {
  static List<String> values = [
    order_detail_link_tax_sqlite_id,
    order_detail_link_tax_id,
    order_detail_link_tax_key,
    order_detail_sqlite_id,
    order_detail_id,
    order_detail_key,
    tax_id,
    tax_name,
    rate,
    branch_link_tax_id,
    tax_amount,
    sync_status,
    created_at,
    updated_at,
    soft_delete
  ];

  static String order_detail_link_tax_sqlite_id = 'order_detail_link_tax_sqlite_id';
  static String order_detail_link_tax_id = 'order_detail_link_tax_id';
  static String order_detail_link_tax_key = 'order_detail_link_tax_key';
  static String order_detail_sqlite_id = 'order_detail_sqlite_id';
  static String order_detail_id = 'order_detail_id';
  static String order_detail_key = 'order_detail_key';
  static String tax_id = 'tax_id';
  static String tax_name = 'tax_name';
  static String rate = 'rate';
  static String branch_link_tax_id = 'branch_link_tax_id';
  static String tax_amount = 'tax_amount';
  static String sync_status = 'sync_status';
  static String created_at = 'created_at';
  static String updated_at = 'updated_at';
  static String soft_delete = 'soft_delete';
}

class OrderDetailLinkTax{
  int? order_detail_link_tax_sqlite_id;
  int? order_detail_link_tax_id;
  String? order_detail_link_tax_key;
  String? order_detail_sqlite_id;
  String? order_detail_id;
  String? order_detail_key;
  String? tax_id;
  String? tax_name;
  String? rate;
  String? branch_link_tax_id;
  String? tax_amount;
  int? sync_status;
  String? created_at;
  String? updated_at;
  String? soft_delete;

  OrderDetailLinkTax(
      {
        this.order_detail_link_tax_sqlite_id,
        this.order_detail_link_tax_id,
        this.order_detail_link_tax_key,
        this.order_detail_sqlite_id,
        this.order_detail_id,
        this.order_detail_key,
        this.tax_id,
        this.tax_name,
        this.rate,
        this.branch_link_tax_id,
        this.tax_amount,
        this.sync_status,
        this.created_at,
        this.updated_at,
        this.soft_delete
      });

  OrderDetailLinkTax copy({
    int? order_detail_link_tax_sqlite_id,
    int? order_detail_link_tax_id,
    String? order_detail_link_tax_key,
    String? order_detail_sqlite_id,
    String? order_detail_id,
    String? order_detail_key,
    String? tax_id,
    String? tax_name,
    String? rate,
    String? branch_link_tax_id,
    String? tax_amount,
    int? sync_status,
    String? created_at,
    String? updated_at,
    String? soft_delete
  }) =>
      OrderDetailLinkTax(
        order_detail_link_tax_sqlite_id: order_detail_link_tax_sqlite_id ?? this.order_detail_link_tax_sqlite_id,
        order_detail_link_tax_id: order_detail_link_tax_id ?? this.order_detail_link_tax_id,
        order_detail_link_tax_key: order_detail_link_tax_key ?? this.order_detail_link_tax_key,
        order_detail_sqlite_id: order_detail_sqlite_id ?? this.order_detail_sqlite_id,
        order_detail_id: order_detail_id ?? this.order_detail_id,
        order_detail_key: order_detail_key ?? this.order_detail_key,
        tax_id: tax_id ?? this.tax_id,
        tax_name: tax_name ?? this.tax_name,
        rate: rate ?? this.rate,
        branch_link_tax_id: branch_link_tax_id ?? this.branch_link_tax_id,
        tax_amount: tax_amount ?? this.tax_amount,
        sync_status: sync_status ?? this.sync_status,
        created_at: created_at ?? this.created_at,
        updated_at: updated_at ?? this.updated_at,
        soft_delete: soft_delete ?? soft_delete);

  static OrderDetailLinkTax fromJson(Map<String, Object?> json) => OrderDetailLinkTax(
    order_detail_link_tax_sqlite_id: json[OrderDetailLinkTaxFields.order_detail_link_tax_sqlite_id] as int?,
    order_detail_link_tax_id: json[OrderDetailLinkTaxFields.order_detail_link_tax_id] as int?,
    order_detail_link_tax_key: json[OrderDetailLinkTaxFields.order_detail_link_tax_key] as String?,
    order_detail_sqlite_id: json[OrderDetailLinkTaxFields.order_detail_sqlite_id] as String?,
    order_detail_id: json[OrderDetailLinkTaxFields.order_detail_id] as String?,
    order_detail_key: json[OrderDetailLinkTaxFields.order_detail_key] as String?,
    tax_id: json[OrderDetailLinkTaxFields.tax_id] as String?,
    tax_name: json[OrderDetailLinkTaxFields.tax_name] as String?,
    rate: json[OrderDetailLinkTaxFields.rate] as String?,
    branch_link_tax_id: json[OrderDetailLinkTaxFields.branch_link_tax_id] as String?,
    tax_amount: json[OrderDetailLinkTaxFields.tax_amount] as String?,
    sync_status: json[OrderDetailLinkTaxFields.sync_status] as int?,
    created_at: json[OrderDetailLinkTaxFields.created_at] as String?,
    updated_at: json[OrderDetailLinkTaxFields.updated_at] as String?,
    soft_delete: json[OrderDetailLinkTaxFields.soft_delete] as String?,
  );

  Map<String, Object?> toJson() => {
    OrderDetailLinkTaxFields.order_detail_link_tax_sqlite_id: order_detail_link_tax_sqlite_id,
    OrderDetailLinkTaxFields.order_detail_link_tax_id: order_detail_link_tax_id,
    OrderDetailLinkTaxFields.order_detail_link_tax_key: order_detail_link_tax_key,
    OrderDetailLinkTaxFields.order_detail_sqlite_id: order_detail_sqlite_id,
    OrderDetailLinkTaxFields.order_detail_id: order_detail_id,
    OrderDetailLinkTaxFields.order_detail_key: order_detail_key,
    OrderDetailLinkTaxFields.tax_id: tax_id,
    OrderDetailLinkTaxFields.tax_name: tax_name,
    OrderDetailLinkTaxFields.rate: rate,
    OrderDetailLinkTaxFields.branch_link_tax_id: branch_link_tax_id,
    OrderDetailLinkTaxFields.tax_amount: tax_amount,
    OrderDetailLinkTaxFields.sync_status: sync_status,
    OrderDetailLinkTaxFields.created_at: created_at,
    OrderDetailLinkTaxFields.updated_at: updated_at,
    OrderDetailLinkTaxFields.soft_delete: soft_delete
  };
}