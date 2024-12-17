String tableSalesModifierPerDay = 'tb_sales_modifier_per_day';

class SalesModifierPerDayFields {
  static List<String> values = [
    sales_modifier_per_day_sqlite_id,
    sales_modifier_per_day_id,
    branch_id,
    mod_item_id,
    mod_group_id,
    modifier_name,
    modifier_group_name,
    amount_sold,
    total_amount,
    total_ori_amount,
    date,
    sync_status,
    created_at,
    updated_at,
    soft_delete
  ];

  static String sales_modifier_per_day_sqlite_id = 'sales_modifier_per_day_sqlite_id';
  static String sales_modifier_per_day_id = 'sales_modifier_per_day_id';
  static String branch_id = 'branch_id';
  static String mod_item_id = 'mod_item_id';
  static String mod_group_id = 'mod_group_id';
  static String modifier_name = 'modifier_name';
  static String modifier_group_name = 'modifier_group_name';
  static String amount_sold = 'amount_sold';
  static String total_amount = 'total_amount';
  static String total_ori_amount = 'total_ori_amount';
  static String date = 'date';
  static String sync_status = 'sync_status';
  static String created_at = 'created_at';
  static String updated_at = 'updated_at';
  static String soft_delete = 'soft_delete';
}

class SalesModifierPerDay{
  int? sales_modifier_per_day_sqlite_id;
  int? sales_modifier_per_day_id;
  String? branch_id;
  String? mod_item_id;
  String? mod_group_id;
  String? modifier_name;
  String? modifier_group_name;
  String? amount_sold;
  String? total_amount;
  String? total_ori_amount;
  String? date;
  int? sync_status;
  String? created_at;
  String? updated_at;
  String? soft_delete;

  SalesModifierPerDay({
    this.sales_modifier_per_day_sqlite_id,
    this.sales_modifier_per_day_id,
    this.branch_id,
    this.mod_item_id,
    this.mod_group_id,
    this.modifier_name,
    this.modifier_group_name,
    this.amount_sold,
    this.total_amount,
    this.total_ori_amount,
    this.date,
    this.sync_status,
    this.created_at,
    this.updated_at,
    this.soft_delete
  });

  SalesModifierPerDay copy({
    int? sales_modifier_per_day_sqlite_id,
    int? sales_modifier_per_day_id,
    String? branch_id,
    String? mod_item_id,
    String? mod_group_id,
    String? modifier_name,
    String? modifier_group_name,
    String? amount_sold,
    String? total_amount,
    String? total_ori_amount,
    String? date,
    int? sync_status,
    String? created_at,
    String? updated_at,
    String? soft_delete
  }) =>
      SalesModifierPerDay(
        sales_modifier_per_day_sqlite_id: sales_modifier_per_day_sqlite_id ?? this.sales_modifier_per_day_sqlite_id,
        sales_modifier_per_day_id: sales_modifier_per_day_id ?? this.sales_modifier_per_day_id,
        branch_id: branch_id ?? this.branch_id,
        mod_item_id: mod_item_id ?? this.mod_item_id,
        mod_group_id: mod_group_id ?? this.mod_group_id,
        modifier_name: modifier_name ?? this.modifier_name,
        modifier_group_name: modifier_group_name ?? this.modifier_group_name,
        amount_sold: amount_sold ?? this.amount_sold,
        total_amount: total_amount ?? this.total_amount,
        total_ori_amount: total_ori_amount ?? this.total_ori_amount,
        date: date ?? this.date,
        sync_status: sync_status ?? this.sync_status,
        created_at: created_at ?? this.created_at,
        updated_at: updated_at ?? this.updated_at,
        soft_delete: soft_delete ?? this.soft_delete,
      );

  static SalesModifierPerDay fromJson(Map<String, Object?> json) => SalesModifierPerDay (
    sales_modifier_per_day_sqlite_id: json[SalesModifierPerDayFields.sales_modifier_per_day_sqlite_id] as int?,
    sales_modifier_per_day_id: json[SalesModifierPerDayFields.sales_modifier_per_day_id] as int?,
    branch_id: json[SalesModifierPerDayFields.branch_id] as String?,
    mod_item_id: json[SalesModifierPerDayFields.mod_item_id] as String?,
    mod_group_id: json[SalesModifierPerDayFields.mod_group_id] as String?,
    modifier_name: json[SalesModifierPerDayFields.modifier_name] as String?,
    modifier_group_name: json[SalesModifierPerDayFields.modifier_group_name] as String?,
    amount_sold: json[SalesModifierPerDayFields.amount_sold] as String?,
    total_amount: json[SalesModifierPerDayFields.total_amount] as String?,
    total_ori_amount: json[SalesModifierPerDayFields.total_ori_amount] as String?,
    date: json[SalesModifierPerDayFields.date] as String?,
    sync_status: json[SalesModifierPerDayFields.sync_status] as int?,
    created_at: json[SalesModifierPerDayFields.created_at] as String?,
    updated_at: json[SalesModifierPerDayFields.updated_at] as String?,
    soft_delete: json[SalesModifierPerDayFields.soft_delete] as String?,
  );

  Map<String, Object?> toJson() => {
    SalesModifierPerDayFields.sales_modifier_per_day_sqlite_id: sales_modifier_per_day_sqlite_id,
    SalesModifierPerDayFields.sales_modifier_per_day_id: sales_modifier_per_day_id,
    SalesModifierPerDayFields.branch_id: branch_id,
    SalesModifierPerDayFields.mod_item_id: mod_item_id,
    SalesModifierPerDayFields.mod_group_id: mod_group_id,
    SalesModifierPerDayFields.modifier_name: modifier_name,
    SalesModifierPerDayFields.modifier_group_name: modifier_group_name,
    SalesModifierPerDayFields.amount_sold: amount_sold,
    SalesModifierPerDayFields.total_amount: total_amount,
    SalesModifierPerDayFields.total_ori_amount: total_ori_amount,
    SalesModifierPerDayFields.date: date,
    SalesModifierPerDayFields.sync_status: sync_status,
    SalesModifierPerDayFields.created_at: created_at,
    SalesModifierPerDayFields.updated_at: updated_at,
    SalesModifierPerDayFields.soft_delete: soft_delete,
  };
}
