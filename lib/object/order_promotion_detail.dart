String? tableOrderPromotionDetail = 'tb_order_promotion_detail';

class OrderPromotionDetailFields {
  static List<String> values = [
    order_promotion_detail_sqlite_id,
    order_promotion_detail_id,
    order_promotion_detail_key,
    order_sqlite_id,
    order_id,
    order_key,
    promotion_name,
    promotion_type,
    rate,
    promotion_id,
    branch_link_promotion_id,
    promotion_amount,
    auto_apply,
    sync_status,
    created_at,
    updated_at,
    soft_delete
  ];

  static String order_promotion_detail_sqlite_id = 'order_promotion_detail_sqlite_id';
  static String order_promotion_detail_id = 'order_promotion_detail_id';
  static String order_promotion_detail_key = 'order_promotion_detail_key';
  static String order_sqlite_id = 'order_sqlite_id';
  static String order_id = 'order_id';
  static String order_key = 'order_key';
  static String promotion_name = 'promotion_name';
  static String promotion_type = 'promotion_type';
  static String rate = 'rate';
  static String promotion_id = 'promotion_id';
  static String branch_link_promotion_id = 'branch_link_promotion_id';
  static String promotion_amount = 'promotion_amount';
  static String auto_apply = 'auto_apply';
  static String sync_status = 'sync_status';
  static String created_at = 'created_at';
  static String updated_at = 'updated_at';
  static String soft_delete = 'soft_delete';
}

class OrderPromotionDetail {
  int? order_promotion_detail_sqlite_id;
  int? order_promotion_detail_id;
  String? order_promotion_detail_key;
  String? order_sqlite_id;
  String? order_id;
  String? order_key;
  String? promotion_name;
  String? rate;
  String? promotion_id;
  String? branch_link_promotion_id;
  String? promotion_amount;
  int? promotion_type;
  String? auto_apply;
  int? sync_status;
  String? created_at;
  String? updated_at;
  String? soft_delete;
  double? total_promotion_amount;
  String? counterOpenDate;

  OrderPromotionDetail(
      {this.order_promotion_detail_sqlite_id,
      this.order_promotion_detail_id,
      this.order_promotion_detail_key,
      this.order_sqlite_id,
      this.order_id,
      this.order_key,
      this.promotion_name,
      this.rate,
      this.promotion_id,
      this.branch_link_promotion_id,
      this.promotion_amount,
      this.promotion_type,
      this.auto_apply,
      this.sync_status,
      this.created_at,
      this.updated_at,
      this.soft_delete,
      this.total_promotion_amount,
      this.counterOpenDate});

  OrderPromotionDetail copy({
    int? order_promotion_detail_sqlite_id,
    int? order_promotion_detail_id,
    String? order_promotion_detail_key,
    String? order_sqlite_id,
    String? order_id,
    String? order_key,
    String? promotion_name,
    String? rate,
    String? promotion_id,
    String? branch_link_promotion_id,
    String? promotion_amount,
    int? promotion_type,
    String? auto_apply,
    int? sync_status,
    String? created_at,
    String? updated_at,
    String? soft_delete,
  }) =>
      OrderPromotionDetail(
          order_promotion_detail_sqlite_id: order_promotion_detail_sqlite_id ?? this.order_promotion_detail_sqlite_id,
          order_promotion_detail_id: order_promotion_detail_id ?? this.order_promotion_detail_id,
          order_promotion_detail_key: order_promotion_detail_key ?? this.order_promotion_detail_key,
          order_sqlite_id: order_sqlite_id ?? this.order_sqlite_id,
          order_id: order_id ?? this.order_id,
          order_key: order_key ?? this.order_key,
          promotion_name: promotion_name ?? this.promotion_name,
          rate: rate ?? this.rate,
          promotion_id: promotion_id ?? this.promotion_id,
          branch_link_promotion_id: branch_link_promotion_id ?? this.branch_link_promotion_id,
          promotion_amount: promotion_amount ?? this.promotion_amount,
          promotion_type: promotion_type ?? this.promotion_type,
          auto_apply: auto_apply ?? this.auto_apply,
          sync_status: sync_status ?? this.sync_status,
          created_at: created_at ?? this.created_at,
          updated_at: updated_at ?? this.updated_at,
          soft_delete: soft_delete ?? this.soft_delete);

  static OrderPromotionDetail fromJson(Map<String, Object?> json) =>
      OrderPromotionDetail(
        order_promotion_detail_sqlite_id: json[OrderPromotionDetailFields.order_promotion_detail_sqlite_id] as int?,
        order_promotion_detail_id: json[OrderPromotionDetailFields.order_promotion_detail_id] as int?,
        order_promotion_detail_key: json[OrderPromotionDetailFields.order_promotion_detail_key] as String?,
        order_sqlite_id: json[OrderPromotionDetailFields.order_sqlite_id] as String?,
        order_id: json[OrderPromotionDetailFields.order_id] as String?,
        order_key: json[OrderPromotionDetailFields.order_key] as String?,
        promotion_name: json[OrderPromotionDetailFields.promotion_name] as String?,
        rate: json[OrderPromotionDetailFields.rate] as String?,
        promotion_id: json[OrderPromotionDetailFields.promotion_id] as String?,
        branch_link_promotion_id: json[OrderPromotionDetailFields.branch_link_promotion_id] as String?,
        promotion_amount: json[OrderPromotionDetailFields.promotion_amount] as String?,
        promotion_type: json[OrderPromotionDetailFields.promotion_type] as int?,
        auto_apply: json[OrderPromotionDetailFields.auto_apply] as String?,
        sync_status: json[OrderPromotionDetailFields.sync_status] as int?,
        created_at: json[OrderPromotionDetailFields.created_at] as String?,
        updated_at: json[OrderPromotionDetailFields.updated_at] as String?,
        soft_delete: json[OrderPromotionDetailFields.soft_delete] as String?,
        total_promotion_amount: json['total_promotion_amount'] as double?,
        counterOpenDate: json['counterOpenDate'] as String?,
      );

  Map<String, Object?> toJson() => {
        OrderPromotionDetailFields.order_promotion_detail_sqlite_id: order_promotion_detail_sqlite_id,
        OrderPromotionDetailFields.order_promotion_detail_id: order_promotion_detail_id,
        OrderPromotionDetailFields.order_promotion_detail_key: order_promotion_detail_key,
        OrderPromotionDetailFields.order_sqlite_id: order_sqlite_id,
        OrderPromotionDetailFields.order_id: order_id,
        OrderPromotionDetailFields.order_key: order_key,
        OrderPromotionDetailFields.promotion_name: promotion_name,
        OrderPromotionDetailFields.rate: rate,
        OrderPromotionDetailFields.promotion_id: promotion_id,
        OrderPromotionDetailFields.branch_link_promotion_id: branch_link_promotion_id,
        OrderPromotionDetailFields.promotion_amount: promotion_amount,
        OrderPromotionDetailFields.promotion_type: promotion_type,
        OrderPromotionDetailFields.auto_apply: auto_apply,
        OrderPromotionDetailFields.sync_status: sync_status,
        OrderPromotionDetailFields.created_at: created_at,
        OrderPromotionDetailFields.updated_at: updated_at,
        OrderPromotionDetailFields.soft_delete: soft_delete,
      };
}
