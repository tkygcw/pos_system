String? tableOrderDetailLinkPromotion = 'tb_order_detail_link_promotion';

class OrderDetailLinkPromotionFields {
  static List<String> values = [
    order_detail_link_promotion_sqlite_id,
    order_detail_link_promotion_id,
    order_detail_link_promotion_key,
    order_detail_sqlite_id,
    order_detail_id,
    order_detail_key,
    promotion_id,
    promotion_name,
    rate,
    branch_link_promotion_id,
    promotion_amount,
    sync_status,
    created_at,
    updated_at,
    soft_delete
  ];

  static String order_detail_link_promotion_sqlite_id = 'order_detail_link_promotion_sqlite_id';
  static String order_detail_link_promotion_id = 'order_detail_link_promotion_id';
  static String order_detail_link_promotion_key = 'order_detail_link_promotion_key';
  static String order_detail_sqlite_id = 'order_detail_sqlite_id';
  static String order_detail_id = 'order_detail_id';
  static String order_detail_key = 'order_detail_key';
  static String promotion_id = 'promotion_id';
  static String promotion_name = 'promotion_name';
  static String rate = 'rate';
  static String branch_link_promotion_id = 'branch_link_promotion_id';
  static String promotion_amount = 'promotion_amount';
  static String sync_status = 'sync_status';
  static String created_at = 'created_at';
  static String updated_at = 'updated_at';
  static String soft_delete = 'soft_delete';
}

class OrderDetailLinkPromotion{
  int? order_detail_link_promotion_sqlite_id;
  int? order_detail_link_promotion_id;
  String? order_detail_link_promotion_key;
  String? order_detail_sqlite_id;
  String? order_detail_id;
  String? order_detail_key;
  String? promotion_id;
  String? promotion_name;
  String? rate;
  String? branch_link_promotion_id;
  String? promotion_amount;
  int? sync_status;
  String? created_at;
  String? updated_at;
  String? soft_delete;

  OrderDetailLinkPromotion(
      {
        this.order_detail_link_promotion_sqlite_id,
        this.order_detail_link_promotion_id,
        this.order_detail_link_promotion_key,
        this.order_detail_sqlite_id,
        this.order_detail_id,
        this.order_detail_key,
        this.promotion_id,
        this.promotion_name,
        this.rate,
        this.branch_link_promotion_id,
        this.promotion_amount,
        this.sync_status,
        this.created_at,
        this.updated_at,
        this.soft_delete
      });

  OrderDetailLinkPromotion copy({
    int? order_detail_link_promotion_sqlite_id,
    int? order_detail_link_promotion_id,
    String? order_detail_link_promotion_key,
    String? order_detail_sqlite_id,
    String? order_detail_id,
    String? order_detail_key,
    String? promotion_id,
    String? promotion_name,
    String? rate,
    String? branch_link_promotion_id,
    String? promotion_amount,
    int? sync_status,
    String? created_at,
    String? updated_at,
    String? soft_delete
  }) =>
      OrderDetailLinkPromotion(
          order_detail_link_promotion_sqlite_id: order_detail_link_promotion_sqlite_id ?? this.order_detail_link_promotion_sqlite_id,
          order_detail_link_promotion_id: order_detail_link_promotion_id ?? this.order_detail_link_promotion_id,
          order_detail_link_promotion_key: order_detail_link_promotion_key ?? this.order_detail_link_promotion_key,
          order_detail_sqlite_id: order_detail_sqlite_id ?? this.order_detail_sqlite_id,
          order_detail_id: order_detail_id ?? this.order_detail_id,
          order_detail_key: order_detail_key ?? this.order_detail_key,
          promotion_id: promotion_id ?? this.promotion_id,
          promotion_name: promotion_name ?? this.promotion_name,
          rate: rate ?? this.rate,
          branch_link_promotion_id: branch_link_promotion_id ?? this.branch_link_promotion_id,
          promotion_amount: promotion_amount ?? this.promotion_amount,
          sync_status: sync_status ?? this.sync_status,
          created_at: created_at ?? this.created_at,
          updated_at: updated_at ?? this.updated_at,
          soft_delete: soft_delete ?? soft_delete);

  static OrderDetailLinkPromotion fromJson(Map<String, Object?> json) => OrderDetailLinkPromotion(
    order_detail_link_promotion_sqlite_id: json[OrderDetailLinkPromotionFields.order_detail_link_promotion_sqlite_id] as int?,
    order_detail_link_promotion_id: json[OrderDetailLinkPromotionFields.order_detail_link_promotion_id] as int?,
    order_detail_link_promotion_key: json[OrderDetailLinkPromotionFields.order_detail_link_promotion_key] as String?,
    order_detail_sqlite_id: json[OrderDetailLinkPromotionFields.order_detail_sqlite_id] as String?,
    order_detail_id: json[OrderDetailLinkPromotionFields.order_detail_id] as String?,
    order_detail_key: json[OrderDetailLinkPromotionFields.order_detail_key] as String?,
    promotion_id: json[OrderDetailLinkPromotionFields.promotion_id] as String?,
    promotion_name: json[OrderDetailLinkPromotionFields.promotion_name] as String?,
    rate: json[OrderDetailLinkPromotionFields.rate] as String?,
    branch_link_promotion_id: json[OrderDetailLinkPromotionFields.branch_link_promotion_id] as String?,
    promotion_amount: json[OrderDetailLinkPromotionFields.promotion_amount] as String?,
    sync_status: json[OrderDetailLinkPromotionFields.sync_status] as int?,
    created_at: json[OrderDetailLinkPromotionFields.created_at] as String?,
    updated_at: json[OrderDetailLinkPromotionFields.updated_at] as String?,
    soft_delete: json[OrderDetailLinkPromotionFields.soft_delete] as String?,
  );

  Map<String, Object?> toJson() => {
    OrderDetailLinkPromotionFields.order_detail_link_promotion_sqlite_id: order_detail_link_promotion_sqlite_id,
    OrderDetailLinkPromotionFields.order_detail_link_promotion_id: order_detail_link_promotion_id,
    OrderDetailLinkPromotionFields.order_detail_link_promotion_key: order_detail_link_promotion_key,
    OrderDetailLinkPromotionFields.order_detail_sqlite_id: order_detail_sqlite_id,
    OrderDetailLinkPromotionFields.order_detail_id: order_detail_id,
    OrderDetailLinkPromotionFields.order_detail_key: order_detail_key,
    OrderDetailLinkPromotionFields.promotion_id: promotion_id,
    OrderDetailLinkPromotionFields.promotion_name: promotion_name,
    OrderDetailLinkPromotionFields.rate: rate,
    OrderDetailLinkPromotionFields.branch_link_promotion_id: branch_link_promotion_id,
    OrderDetailLinkPromotionFields.promotion_amount: promotion_amount,
    OrderDetailLinkPromotionFields.sync_status: sync_status,
    OrderDetailLinkPromotionFields.created_at: created_at,
    OrderDetailLinkPromotionFields.updated_at: updated_at,
    OrderDetailLinkPromotionFields.soft_delete: soft_delete
  };
}