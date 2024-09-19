String? tableOrderDetailCancel = 'tb_order_detail_cancel ';

class OrderDetailCancelFields{
  static List<String> values = [
    order_detail_cancel_sqlite_id,
    order_detail_cancel_id,
    order_detail_cancel_key,
    order_detail_sqlite_id,
    order_detail_key,
    quantity,
    cancel_by,
    cancel_by_user_id,
    cancel_reason,
    settlement_sqlite_id,
    settlement_key,
    status,
    sync_status,
    created_at,
    updated_at,
    soft_delete
  ];

  static String order_detail_cancel_sqlite_id = 'order_detail_cancel_sqlite_id';
  static String order_detail_cancel_id = 'order_detail_cancel_id';
  static String order_detail_cancel_key = 'order_detail_cancel_key';
  static String order_detail_sqlite_id = 'order_detail_sqlite_id';
  static String order_detail_key = 'order_detail_key';
  static String quantity = 'quantity';
  static String cancel_by = 'cancel_by';
  static String cancel_by_user_id = 'cancel_by_user_id';
  static String cancel_reason = 'cancel_reason';
  static String settlement_sqlite_id = 'settlement_sqlite_id';
  static String settlement_key = 'settlement_key';
  static String status = 'status';
  static String sync_status = 'sync_status';
  static String created_at = 'created_at';
  static String updated_at = 'updated_at';
  static String soft_delete = 'soft_delete';
}

class OrderDetailCancel{
  int? order_detail_cancel_sqlite_id;
  int? order_detail_cancel_id;
  String? order_detail_cancel_key;
  String? order_detail_sqlite_id;
  String? order_detail_key;
  String? quantity;
  String? cancel_by;
  String? cancel_by_user_id;
  String? cancel_reason;
  String? settlement_sqlite_id;
  String? settlement_key;
  int? status;
  int? sync_status;
  String? created_at;
  String? updated_at;
  String? soft_delete;
  num? total_item;
  num? total_amount;
  String? product_name;
  String? product_variant_name;
  num? price;

  OrderDetailCancel(
      {this.order_detail_sqlite_id,
        this.order_detail_cancel_id,
        this.order_detail_cancel_key,
        this.order_detail_cancel_sqlite_id,
        this.order_detail_key,
        this.quantity,
        this.cancel_by,
        this.cancel_by_user_id,
        this.cancel_reason,
        this.settlement_sqlite_id,
        this.settlement_key,
        this.status,
        this.sync_status,
        this.created_at,
        this.updated_at,
        this.soft_delete,
        this.total_item,
        this.total_amount,
        this.product_name,
        this.product_variant_name,
        this.price
      });

  OrderDetailCancel copy({
    int? order_detail_cancel_sqlite_id,
    int? order_detail_cancel_id,
    String? order_detail_cancel_key,
    String? order_detail_sqlite_id,
    String? order_detail_key,
    String? quantity,
    String? cancel_by,
    String? cancel_by_user_id,
    String? cancel_reason,
    String? settlement_sqlite_id,
    String? settlement_key,
    int? status,
    int? sync_status,
    String? created_at,
    String? updated_at,
    String? soft_delete
  }) =>
      OrderDetailCancel(
        order_detail_cancel_sqlite_id: order_detail_cancel_sqlite_id ?? this.order_detail_cancel_sqlite_id,
        order_detail_cancel_id: order_detail_cancel_id ?? this.order_detail_cancel_id,
        order_detail_cancel_key: order_detail_cancel_key ?? this.order_detail_cancel_key,
        order_detail_sqlite_id: order_detail_sqlite_id ?? this.order_detail_sqlite_id,
        order_detail_key: order_detail_cancel_key ?? this.order_detail_key,
        quantity: quantity ?? this.quantity,
        cancel_by: cancel_by ?? this.cancel_by,
        cancel_by_user_id: cancel_by_user_id ?? this.cancel_by_user_id,
        cancel_reason: cancel_reason ?? this.cancel_reason,
        settlement_sqlite_id: settlement_sqlite_id ?? this.settlement_sqlite_id,
        settlement_key: settlement_key ?? this.settlement_key,
        status: status ?? this.status,
        sync_status: sync_status ?? this.sync_status,
        created_at: created_at ?? this.created_at,
        updated_at: updated_at ?? this.updated_at,
        soft_delete: soft_delete ?? this.soft_delete,
      );

  static OrderDetailCancel fromJson(Map<String, Object?> json) => OrderDetailCancel(
    order_detail_cancel_sqlite_id: json[OrderDetailCancelFields.order_detail_cancel_sqlite_id] as int?,
    order_detail_cancel_id: json[OrderDetailCancelFields.order_detail_cancel_id] as int?,
    order_detail_cancel_key: json[OrderDetailCancelFields.order_detail_cancel_key] as String?,
    order_detail_sqlite_id: json[OrderDetailCancelFields.order_detail_sqlite_id] as String?,
    order_detail_key: json[OrderDetailCancelFields.order_detail_key] as String?,
    quantity: json[OrderDetailCancelFields.quantity] as String?,
    cancel_by: json[OrderDetailCancelFields.cancel_by] as String?,
    cancel_by_user_id: json[OrderDetailCancelFields.cancel_by_user_id] as String?,
    cancel_reason: json[OrderDetailCancelFields.cancel_reason] as String?,
    settlement_sqlite_id: json[OrderDetailCancelFields.settlement_sqlite_id] as String?,
    settlement_key: json[OrderDetailCancelFields.settlement_key] as String?,
    status: json[OrderDetailCancelFields.status] as int?,
    sync_status: json[OrderDetailCancelFields.sync_status] as int?,
    created_at: json[OrderDetailCancelFields.created_at] as String?,
    updated_at: json[OrderDetailCancelFields.updated_at] as String?,
    soft_delete: json[OrderDetailCancelFields.soft_delete] as String?,
    total_item: json['total_item'] as num?,
    product_name: json['product_name'] as String?,
    product_variant_name: json['product_variant_name'] as String?,
    price: json['price'] as num?
  );

  Map<String, Object?> toJson() => {
    OrderDetailCancelFields.order_detail_cancel_sqlite_id: order_detail_cancel_sqlite_id,
    OrderDetailCancelFields.order_detail_cancel_id: order_detail_cancel_id,
    OrderDetailCancelFields.order_detail_cancel_key: order_detail_cancel_key,
    OrderDetailCancelFields.order_detail_sqlite_id: order_detail_sqlite_id,
    OrderDetailCancelFields.order_detail_key: order_detail_key,
    OrderDetailCancelFields.quantity: quantity,
    OrderDetailCancelFields.cancel_by: cancel_by,
    OrderDetailCancelFields.cancel_by_user_id: cancel_by_user_id,
    OrderDetailCancelFields.cancel_reason: cancel_reason,
    OrderDetailCancelFields.settlement_sqlite_id: settlement_sqlite_id,
    OrderDetailCancelFields.settlement_key: settlement_key,
    OrderDetailCancelFields.status: status,
    OrderDetailCancelFields.sync_status: sync_status,
    OrderDetailCancelFields.created_at: created_at,
    OrderDetailCancelFields.updated_at: updated_at,
    OrderDetailCancelFields.soft_delete: soft_delete
  };

}