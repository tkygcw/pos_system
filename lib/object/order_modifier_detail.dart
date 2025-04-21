String? tableOrderModifierDetail = 'tb_order_modifier_detail';

class OrderModifierDetailFields {
  static List<String> values = [
    order_modifier_detail_sqlite_id,
    order_modifier_detail_id,
    order_modifier_detail_key,
    order_detail_sqlite_id,
    order_detail_id,
    order_detail_key,
    mod_item_id,
    mod_name,
    mod_price,
    mod_group_id,
    sync_status,
    created_at,
    updated_at,
    soft_delete
  ];

  static String order_modifier_detail_sqlite_id = 'order_modifier_detail_sqlite_id';
  static String order_modifier_detail_id = 'order_modifier_detail_id';
  static String order_modifier_detail_key = 'order_modifier_detail_key';
  static String order_detail_sqlite_id = 'order_detail_sqlite_id';
  static String order_detail_id = 'order_detail_id';
  static String order_detail_key = 'order_detail_key';
  static String mod_item_id = 'mod_item_id';
  static String mod_name = 'mod_name';
  static String mod_price = 'mod_price';
  static String mod_group_id = 'mod_group_id';
  static String created_at = 'created_at';
  static String sync_status = 'sync_status';
  static String updated_at = 'updated_at';
  static String soft_delete = 'soft_delete';
}

class OrderModifierDetail{
  int? order_modifier_detail_sqlite_id;
  int? order_modifier_detail_id;
  String? order_modifier_detail_key;
  String? order_detail_sqlite_id;
  String? order_detail_id;
  String? order_detail_key;
  String? mod_item_id;
  String? mod_name;
  String? mod_price;
  String? mod_group_id;
  int? sync_status;
  String? created_at;
  String? updated_at;
  String? soft_delete;
  int? item_sum;
  double? net_sales;
  String? mod_group_name;

  OrderModifierDetail(
      {this.order_modifier_detail_sqlite_id,
        this.order_modifier_detail_id,
        this.order_modifier_detail_key,
        this.order_detail_sqlite_id,
        this.order_detail_id,
        this.order_detail_key,
        this.mod_item_id,
        this.mod_name,
        this.mod_price,
        this.mod_group_id,
        this.sync_status,
        this.created_at,
        this.updated_at,
        this.soft_delete,
        this.item_sum,
        this.net_sales,
        this.mod_group_name
      });

  OrderModifierDetail copy({
     int? order_modifier_detail_sqlite_id,
     int? order_modifier_detail_id,
     String? order_modifier_detail_key,
     String? order_detail_sqlite_id,
     String? order_detail_id,
     String? order_detail_key,
     String? mod_item_id,
     String? mod_name,
     String? mod_price,
     String? mod_group_id,
     int? sync_status,
     String? created_at,
     String? updated_at,
     String? soft_delete,
  }) =>
      OrderModifierDetail(
        order_modifier_detail_sqlite_id: order_modifier_detail_sqlite_id ?? this.order_modifier_detail_sqlite_id,
        order_modifier_detail_id: order_modifier_detail_id ?? this.order_modifier_detail_id,
        order_modifier_detail_key: order_modifier_detail_key ?? this.order_modifier_detail_key,
        order_detail_sqlite_id: order_detail_sqlite_id ?? this.order_detail_sqlite_id,
        order_detail_id: order_detail_id ?? this.order_detail_id,
        order_detail_key: order_detail_key ?? this.order_detail_key,
        mod_item_id: mod_item_id ?? this.mod_item_id,
        mod_group_id: mod_group_id ?? this.mod_group_id,
        mod_name: mod_name ?? this.mod_name,
        mod_price: mod_price ?? this.mod_price,
        sync_status: sync_status ?? this.sync_status,
        created_at: created_at ?? this.created_at,
        updated_at: updated_at ?? this.updated_at,
        soft_delete: soft_delete ?? this.soft_delete);

  static OrderModifierDetail fromJson(Map<String, Object?> json) => OrderModifierDetail(
    order_modifier_detail_sqlite_id: json[OrderModifierDetailFields.order_modifier_detail_sqlite_id] as int?,
    order_modifier_detail_id: json[OrderModifierDetailFields.order_modifier_detail_id] as int?,
    order_modifier_detail_key: json[OrderModifierDetailFields.order_modifier_detail_key] as String?,
    order_detail_sqlite_id: json[OrderModifierDetailFields.order_detail_sqlite_id] as String?,
    order_detail_id: json[OrderModifierDetailFields.order_detail_id] as String?,
    order_detail_key: json[OrderModifierDetailFields.order_detail_key] as String?,
    mod_item_id: json[OrderModifierDetailFields.mod_item_id] as String?,
    mod_name: json[OrderModifierDetailFields.mod_name] as String?,
    mod_price: json[OrderModifierDetailFields.mod_price] as String?,
    mod_group_id: json[OrderModifierDetailFields.mod_group_id] as String?,
    sync_status: json[OrderModifierDetailFields.sync_status] as int?,
    created_at: json[OrderModifierDetailFields.created_at] as String?,
    updated_at: json[OrderModifierDetailFields.updated_at] as String?,
    soft_delete: json[OrderModifierDetailFields.soft_delete] as String?,
    item_sum: json['item_sum'] as int?,
    net_sales: json['net_sales'] as double?,
    mod_group_name: json['mod_group_name'] as String?
  );

  Map<String, Object?> toJson() => {
    OrderModifierDetailFields.order_modifier_detail_sqlite_id: order_modifier_detail_sqlite_id,
    OrderModifierDetailFields.order_modifier_detail_id: order_modifier_detail_id,
    OrderModifierDetailFields.order_modifier_detail_key: order_modifier_detail_key,
    OrderModifierDetailFields.order_detail_sqlite_id: order_detail_sqlite_id,
    OrderModifierDetailFields.order_detail_id: order_detail_id,
    OrderModifierDetailFields.order_detail_key: order_detail_key,
    OrderModifierDetailFields.mod_item_id: mod_item_id,
    OrderModifierDetailFields.mod_name: mod_name,
    OrderModifierDetailFields.mod_price: mod_price,
    OrderModifierDetailFields.mod_group_id: mod_group_id,
    OrderModifierDetailFields.sync_status: sync_status,
    OrderModifierDetailFields.created_at: created_at,
    OrderModifierDetailFields.updated_at: updated_at,
    OrderModifierDetailFields.soft_delete: soft_delete,
  };

  OrderModifierDetail clone() {
    return OrderModifierDetail(
      order_modifier_detail_sqlite_id: this.order_modifier_detail_sqlite_id,
      order_modifier_detail_id: this.order_modifier_detail_id,
      order_modifier_detail_key: this.order_modifier_detail_key,
      order_detail_sqlite_id: this.order_detail_sqlite_id,
      order_detail_id: this.order_detail_id,
      order_detail_key: this.order_detail_key,
      mod_item_id: this.mod_item_id,
      mod_name: this.mod_name,
      mod_price: this.mod_price,
      mod_group_id: this.mod_group_id,
      sync_status: this.sync_status,
      created_at: this.created_at,
      updated_at: this.updated_at,
      soft_delete: this.soft_delete,
    );
  }
}