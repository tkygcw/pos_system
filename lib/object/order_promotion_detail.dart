String? tableOrderPromotionDetail = 'tb_order_promotion_detail';

class OrderPromotionDetailFields {
  static List<String> values = [
    order_promotion_detail_sqlite_id,
    order_promotion_detail_id,
    order_sqlite_id,
    order_id,
    promotion_name,
    promotion_type,
    rate,
    promotion_id,
    branch_link_promotion_id,
    promotion_amount,
    sync_status,
    created_at,
    updated_at,
    soft_delete
  ];

  static String order_promotion_detail_sqlite_id = 'order_promotion_detail_sqlite_id';
  static String order_promotion_detail_id = 'order_promotion_detail_id';
  static String order_sqlite_id = 'order_sqlite_id';
  static String order_id = 'order_id';
  static String promotion_name = 'promotion_name';
  static String promotion_type = 'promotion_type';
  static String rate = 'rate';
  static String promotion_id = 'promotion_id';
  static String branch_link_promotion_id = 'branch_link_promotion_id';
  static String promotion_amount = 'promotion_amount';
  static String sync_status = 'sync_status';
  static String created_at = 'created_at';
  static String updated_at = 'updated_at';
  static String soft_delete = 'soft_delete';
}

class OrderPromotionDetail {
  int? order_promotion_detail_sqlite_id;
  int? order_promotion_detail_id;
  String? order_sqlite_id;
  String? order_id;
  String? promotion_name;
  String? rate;
  String? promotion_id;
  String? branch_link_promotion_id;
  String? promotion_amount;
  int? promotion_type;
  int? sync_status;
  String? created_at;
  String? updated_at;
  String? soft_delete;

  OrderPromotionDetail(
      {this.order_promotion_detail_sqlite_id,
        this.order_promotion_detail_id,
        this.order_sqlite_id,
        this.order_id,
        this.promotion_name,
        this.rate,
        this.promotion_id,
        this.branch_link_promotion_id,
        this.promotion_amount,
        this.promotion_type,
        this.sync_status,
        this.created_at,
        this.updated_at,
        this.soft_delete});

  OrderPromotionDetail copy({
    int? order_promotion_detail_sqlite_id,
    int? order_promotion_detail_id,
    String? order_sqlite_id,
    String? order_id,
    String? promotion_name,
    String? rate,
    String? promotion_id,
    String? branch_link_promotion_id,
    String? promotion_amount,
    int? promotion_type,
    int? sync_status,
    String? created_at,
    String? updated_at,
    String? soft_delete,
  }) =>
      OrderPromotionDetail(
          order_promotion_detail_sqlite_id: order_promotion_detail_sqlite_id ?? this.order_promotion_detail_sqlite_id,
          order_promotion_detail_id: order_promotion_detail_id ?? this.order_promotion_detail_id,
          order_sqlite_id: order_sqlite_id ?? this.order_sqlite_id,
          order_id: order_id ?? this.order_id,
          promotion_name: promotion_name ?? this.promotion_name,
          rate: rate ?? this.rate,
          promotion_id: promotion_id ?? this.promotion_id,
          branch_link_promotion_id: branch_link_promotion_id ?? this.branch_link_promotion_id,
          promotion_amount: promotion_amount ?? this.promotion_amount,
          promotion_type: promotion_type ?? this.promotion_type,
          sync_status: sync_status ?? this.sync_status,
          created_at: created_at ?? this.created_at,
          updated_at: updated_at ?? this.updated_at,
          soft_delete: soft_delete ?? this.soft_delete);

  static OrderPromotionDetail fromJson(Map<String, Object?> json) => OrderPromotionDetail(
    order_promotion_detail_sqlite_id: json[OrderPromotionDetailFields.order_promotion_detail_sqlite_id] as int?,
    order_promotion_detail_id: json[OrderPromotionDetailFields.order_promotion_detail_id] as int?,
    order_sqlite_id: json[OrderPromotionDetailFields.order_sqlite_id] as String?,
    order_id: json[OrderPromotionDetailFields.order_id] as String?,
    promotion_name: json[OrderPromotionDetailFields.promotion_name] as String?,
    rate: json[OrderPromotionDetailFields.rate] as String?,
    promotion_id: json[OrderPromotionDetailFields.promotion_id] as String?,
    branch_link_promotion_id: json[OrderPromotionDetailFields.branch_link_promotion_id] as String?,
    promotion_amount: json[OrderPromotionDetailFields.promotion_amount] as String?,
    promotion_type: json[OrderPromotionDetailFields.promotion_type] as int?,
    sync_status: json[OrderPromotionDetailFields.sync_status] as int?,
    created_at: json[OrderPromotionDetailFields.created_at] as String?,
    updated_at: json[OrderPromotionDetailFields.updated_at] as String?,
    soft_delete: json[OrderPromotionDetailFields.soft_delete] as String?,
  );

  Map<String, Object?> toJson() => {
    OrderPromotionDetailFields.order_promotion_detail_sqlite_id: order_promotion_detail_sqlite_id,
    OrderPromotionDetailFields.order_promotion_detail_id: order_promotion_detail_id,
    OrderPromotionDetailFields.order_sqlite_id: order_sqlite_id,
    OrderPromotionDetailFields.order_id: order_id,
    OrderPromotionDetailFields.promotion_name: promotion_name,
    OrderPromotionDetailFields.rate: rate,
    OrderPromotionDetailFields.promotion_id: promotion_id,
    OrderPromotionDetailFields.branch_link_promotion_id: branch_link_promotion_id,
    OrderPromotionDetailFields.promotion_amount: promotion_amount,
    OrderPromotionDetailFields.promotion_type: promotion_type,
    OrderPromotionDetailFields.sync_status: sync_status,
    OrderPromotionDetailFields.created_at: created_at,
    OrderPromotionDetailFields.updated_at: updated_at,
    OrderPromotionDetailFields.soft_delete: soft_delete,
  };


}