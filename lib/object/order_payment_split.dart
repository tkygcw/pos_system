String? tableOrderPaymentSplit = 'tb_order_payment_split';

class OrderPaymentSplitFields {
  static List<String> values = [
    order_payment_split_sqlite_id,
    order_payment_split_id,
    order_payment_split_key,
    branch_id,
    payment_link_company_id,
    amount,
    payment_received,
    payment_change,
    order_key,
    sync_status,
    created_at,
    updated_at,
    soft_delete
  ];

  static String order_payment_split_sqlite_id = 'order_payment_split_sqlite_id';
  static String order_payment_split_id = 'order_payment_split_id';
  static String order_payment_split_key = 'order_payment_split_key';
  static String branch_id = 'branch_id';
  static String payment_link_company_id = 'payment_link_company_id';
  static String amount = 'amount';
  static String payment_received = 'payment_received';
  static String payment_change = 'payment_change';
  static String order_key = 'order_key';
  static String sync_status = 'sync_status';
  static String created_at = 'created_at';
  static String updated_at = 'updated_at';
  static String soft_delete = 'soft_delete';

}

class OrderPaymentSplit {
  int? order_payment_split_sqlite_id;
  int? order_payment_split_id;
  String? order_payment_split_key;
  String? branch_id;
  String? payment_link_company_id;
  String? amount;
  String? payment_received;
  String? payment_change;
  String? order_key;
  int? sync_status;
  String? created_at;
  String? updated_at;
  String? soft_delete;
  String? payment_name;
  String? payment_type_id;

  OrderPaymentSplit(
      {this.order_payment_split_sqlite_id,
        this.order_payment_split_id,
        this.order_payment_split_key,
        this.branch_id,
        this.payment_link_company_id,
        this.amount,
        this.payment_received,
        this.payment_change,
        this.order_key,
        this.sync_status,
        this.created_at,
        this.updated_at,
        this.soft_delete,
        this.payment_name,
        this.payment_type_id,
      });

  OrderPaymentSplit copy({
    int? order_payment_split_sqlite_id,
    int? order_payment_split_id,
    String? order_payment_split_key,
    String? branch_id,
    String? payment_link_company_id,
    String? amount,
    String? payment_received,
    String? payment_change,
    String? order_key,
    int? sync_status,
    String? created_at,
    String? updated_at,
    String? soft_delete
  }) =>
      OrderPaymentSplit(
          order_payment_split_sqlite_id: order_payment_split_sqlite_id ?? this.order_payment_split_sqlite_id,
          order_payment_split_id: order_payment_split_id ?? this.order_payment_split_id,
          order_payment_split_key: order_payment_split_key ?? this.order_payment_split_key,
          branch_id: branch_id ?? this.branch_id,
          payment_link_company_id: payment_link_company_id ?? this.payment_link_company_id,
          amount: amount ?? this.amount,
          payment_received: payment_received ?? this.payment_received,
          payment_change: payment_change ?? this.payment_change,
          order_key: order_key ?? this.order_key,
          sync_status: sync_status ?? this.sync_status,
          created_at: created_at ?? this.created_at,
          updated_at: updated_at ?? this.updated_at,
          soft_delete: soft_delete ?? this.soft_delete);

  static OrderPaymentSplit fromJson(Map<String, Object?> json) => OrderPaymentSplit(
    order_payment_split_sqlite_id: json[OrderPaymentSplitFields.order_payment_split_sqlite_id] as int?,
    order_payment_split_id: json[OrderPaymentSplitFields.order_payment_split_id] as int?,
    order_payment_split_key: json[OrderPaymentSplitFields.order_payment_split_key] as String?,
    branch_id: json[OrderPaymentSplitFields.branch_id] as String?,
    payment_link_company_id: json[OrderPaymentSplitFields.payment_link_company_id] as String?,
    amount: json[OrderPaymentSplitFields.amount] as String?,
    payment_received: json[OrderPaymentSplitFields.payment_received] as String?,
    payment_change: json[OrderPaymentSplitFields.payment_change] as String?,
    order_key: json[OrderPaymentSplitFields.order_key] as String?,
    sync_status: json[OrderPaymentSplitFields.sync_status] as int?,
    created_at: json[OrderPaymentSplitFields.created_at] as String?,
    updated_at: json[OrderPaymentSplitFields.updated_at] as String?,
    soft_delete: json[OrderPaymentSplitFields.soft_delete] as String?,
    payment_name: json['payment_name'] as String?,
    payment_type_id: json['payment_type_id'] as String?,
  );

  Map<String, Object?> toJson() => {
    OrderPaymentSplitFields.order_payment_split_sqlite_id: order_payment_split_sqlite_id,
    OrderPaymentSplitFields.order_payment_split_id: order_payment_split_id,
    OrderPaymentSplitFields.order_payment_split_key: order_payment_split_key,
    OrderPaymentSplitFields.branch_id: branch_id,
    OrderPaymentSplitFields.payment_link_company_id: payment_link_company_id,
    OrderPaymentSplitFields.amount: amount,
    OrderPaymentSplitFields.payment_received: payment_received,
    OrderPaymentSplitFields.payment_change: payment_change,
    OrderPaymentSplitFields.order_key: order_key,
    OrderPaymentSplitFields.sync_status: sync_status,
    OrderPaymentSplitFields.created_at: created_at,
    OrderPaymentSplitFields.updated_at: updated_at,
    OrderPaymentSplitFields.soft_delete: soft_delete,
  };
}


