String tableSalesDiningPerDay = 'tb_sales_dining_per_day';

class SalesDiningPerDayFields {
  static List<String> values = [
    sales_dining_per_day_sqlite_id,
    sales_dining_per_day_id,
    branch_id,
    dine_in,
    take_away,
    delivery,
    date,
    sync_status,
    created_at,
    updated_at,
    soft_delete
  ];

  static String sales_dining_per_day_sqlite_id = 'sales_dining_per_day_sqlite_id';
  static String sales_dining_per_day_id = 'sales_dining_per_day_id';
  static String branch_id = 'branch_id';
  static String dine_in = 'dine_in';
  static String take_away = 'take_away';
  static String delivery = 'delivery';
  static String date = 'date';
  static String sync_status = 'sync_status';
  static String created_at = 'created_at';
  static String updated_at = 'updated_at';
  static String soft_delete = 'soft_delete';
}

class SalesDiningPerDay{
  int? sales_dining_per_day_sqlite_id;
  int? sales_dining_per_day_id;
  String? branch_id;
  String? dine_in;
  String? take_away;
  String? delivery;
  String? date;
  int? sync_status;
  String? created_at;
  String? updated_at;
  String? soft_delete;

  SalesDiningPerDay({
    this.sales_dining_per_day_sqlite_id,
    this.sales_dining_per_day_id,
    this.branch_id,
    this.dine_in,
    this.take_away,
    this.delivery,
    this.date,
    this.sync_status,
    this.created_at,
    this.updated_at,
    this.soft_delete
  });

  SalesDiningPerDay copy({
    int? sales_dining_per_day_sqlite_id,
    int? sales_dining_per_day_id,
    String? branch_id,
    String? dine_in,
    String? take_away,
    String? delivery,
    String? date,
    int? sync_status,
    String? created_at,
    String? updated_at,
    String? soft_delete
  }) =>
      SalesDiningPerDay(
        sales_dining_per_day_sqlite_id: sales_dining_per_day_sqlite_id ?? this.sales_dining_per_day_sqlite_id,
        sales_dining_per_day_id: sales_dining_per_day_id ?? this.sales_dining_per_day_id,
        branch_id: branch_id ?? this.branch_id,
        dine_in: dine_in ?? this.dine_in,
        take_away: take_away ?? this.take_away,
        delivery: delivery ?? this.delivery,
        date: date ?? this.date,
        sync_status: sync_status ?? this.sync_status,
        created_at: created_at ?? this.created_at,
        updated_at: updated_at ?? this.updated_at,
        soft_delete: soft_delete ?? this.soft_delete,
      );

  static SalesDiningPerDay fromJson(Map<String, Object?> json) => SalesDiningPerDay (
    sales_dining_per_day_sqlite_id: json[SalesDiningPerDayFields.sales_dining_per_day_sqlite_id] as int?,
    sales_dining_per_day_id: json[SalesDiningPerDayFields.sales_dining_per_day_id] as int?,
    branch_id: json[SalesDiningPerDayFields.branch_id] as String?,
    dine_in: json[SalesDiningPerDayFields.dine_in] as String?,
    take_away: json[SalesDiningPerDayFields.take_away] as String?,
    delivery: json[SalesDiningPerDayFields.delivery] as String?,
    date: json[SalesDiningPerDayFields.date] as String?,
    sync_status: json[SalesDiningPerDayFields.sync_status] as int?,
    created_at: json[SalesDiningPerDayFields.created_at] as String?,
    updated_at: json[SalesDiningPerDayFields.updated_at] as String?,
    soft_delete: json[SalesDiningPerDayFields.soft_delete] as String?,
  );

  Map<String, Object?> toJson() => {
    SalesDiningPerDayFields.sales_dining_per_day_sqlite_id: sales_dining_per_day_sqlite_id,
    SalesDiningPerDayFields.sales_dining_per_day_id: sales_dining_per_day_id,
    SalesDiningPerDayFields.branch_id: branch_id,
    SalesDiningPerDayFields.dine_in: dine_in,
    SalesDiningPerDayFields.take_away: take_away,
    SalesDiningPerDayFields.delivery: delivery,
    SalesDiningPerDayFields.date: date,
    SalesDiningPerDayFields.sync_status: sync_status,
    SalesDiningPerDayFields.created_at: created_at,
    SalesDiningPerDayFields.updated_at: updated_at,
    SalesDiningPerDayFields.soft_delete: soft_delete,
  };
}
