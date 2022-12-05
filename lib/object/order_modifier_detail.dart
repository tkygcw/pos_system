String? tableOrderModifierDetail = 'tb_order_modifier_detail';

class OrderModifierDetailFields {
  static List<String> values = [
    order_modifier_detail_sqlite_id,
    order_modifier_detail_id,
    order_detail_sqlite_id,
    order_detail_id,
    mod_item_id,
    mod_group_id,
    created_at,
    updated_at,
    soft_delete
  ];

  static String order_modifier_detail_sqlite_id = 'order_modifier_detail_sqlite_id';
  static String order_modifier_detail_id = 'order_modifier_detail_id';
  static String order_detail_sqlite_id = 'order_detail_sqlite_id';
  static String order_detail_id = 'order_detail_id';
  static String mod_item_id = 'mod_item_id';
  static String mod_group_id = 'mod_group_id';
  static String created_at = 'created_at';
  static String updated_at = 'updated_at';
  static String soft_delete = 'soft_delete';
}

class OrderModifierDetail{
  int? order_modifier_detail_sqlite_id;
  int? order_modifier_detail_id;
  String? order_detail_sqlite_id;
  String? order_detail_id;
  String? mod_item_id;
  String? mod_group_id;
  String? created_at;
  String? updated_at;
  String? soft_delete;
  String? modifier_name;

  OrderModifierDetail(
      {this.order_modifier_detail_sqlite_id,
        this.order_modifier_detail_id,
        this.order_detail_sqlite_id,
        this.order_detail_id,
        this.mod_item_id,
        this.mod_group_id,
        this.created_at,
        this.updated_at,
        this.soft_delete,
        this.modifier_name});

  OrderModifierDetail copy({
     int? order_modifier_detail_sqlite_id,
     int? order_modifier_detail_id,
     String? order_detail_sqlite_id,
     String? order_detail_id,
     String? mod_item_id,
     String? mod_group_id,
     String? created_at,
     String? updated_at,
     String? soft_delete,
  }) =>
      OrderModifierDetail(
        order_modifier_detail_sqlite_id: order_modifier_detail_sqlite_id ?? this.order_modifier_detail_sqlite_id,
        order_modifier_detail_id: order_modifier_detail_id ?? this.order_modifier_detail_id,
        order_detail_sqlite_id: order_detail_sqlite_id ?? this.order_detail_sqlite_id,
        order_detail_id: order_detail_id ?? this.order_detail_id,
        mod_item_id: mod_item_id ?? this.mod_item_id,
        mod_group_id: mod_group_id ?? this.mod_group_id,
        created_at: created_at ?? this.created_at,
        updated_at: updated_at ?? this.updated_at,
        soft_delete: soft_delete ?? this.soft_delete);

  static OrderModifierDetail fromJson(Map<String, Object?> json) => OrderModifierDetail(
    order_modifier_detail_sqlite_id: json[OrderModifierDetailFields.order_modifier_detail_sqlite_id] as int?,
    order_modifier_detail_id: json[OrderModifierDetailFields.order_modifier_detail_id] as int?,
    order_detail_sqlite_id: json[OrderModifierDetailFields.order_detail_sqlite_id] as String?,
    order_detail_id: json[OrderModifierDetailFields.order_detail_id] as String?,
    mod_item_id: json[OrderModifierDetailFields.mod_item_id] as String?,
    mod_group_id: json[OrderModifierDetailFields.mod_group_id] as String?,
    created_at: json[OrderModifierDetailFields.created_at] as String?,
    updated_at: json[OrderModifierDetailFields.updated_at] as String?,
    soft_delete: json[OrderModifierDetailFields.soft_delete] as String?,
    modifier_name: json['name'] as String?
  );

  Map<String, Object?> toJson() => {
    OrderModifierDetailFields.order_modifier_detail_sqlite_id: order_modifier_detail_sqlite_id,
    OrderModifierDetailFields.order_modifier_detail_id: order_modifier_detail_id,
    OrderModifierDetailFields.order_detail_sqlite_id: order_detail_sqlite_id,
    OrderModifierDetailFields.order_detail_id: order_detail_id,
    OrderModifierDetailFields.mod_item_id: mod_item_id,
    OrderModifierDetailFields.mod_group_id: mod_group_id,
    OrderModifierDetailFields.created_at: created_at,
    OrderModifierDetailFields.updated_at: updated_at,
    OrderModifierDetailFields.soft_delete: soft_delete,
  };

}