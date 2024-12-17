String tableSalesProductPerDay = 'tb_sales_product_per_day';

class SalesProductPerDayFields {
  static List<String> values = [
    sales_product_per_day_sqlite_id,
    sales_product_per_day_id,
    branch_id,
    product_id,
    product_name,
    amount_sold,
    total_amount,
    total_ori_amount,
    date,
    sync_status,
    created_at,
    updated_at,
    soft_delete
  ];

  static String sales_product_per_day_sqlite_id = 'sales_product_per_day_sqlite_id';
  static String sales_product_per_day_id = 'sales_product_per_day_id';
  static String branch_id = 'branch_id';
  static String product_id = 'product_id';
  static String product_name = 'product_name';
  static String amount_sold = 'amount_sold';
  static String total_amount = 'total_amount';
  static String total_ori_amount = 'total_ori_amount';
  static String date = 'date';
  static String sync_status = 'sync_status';
  static String created_at = 'created_at';
  static String updated_at = 'updated_at';
  static String soft_delete = 'soft_delete';
}

class SalesProductPerDay{
  int? sales_product_per_day_sqlite_id;
  int? sales_product_per_day_id;
  String? branch_id;
  String? product_id;
  String? product_name;
  String? amount_sold;
  String? total_amount;
  String? total_ori_amount;
  String? date;
  int? sync_status;
  String? created_at;
  String? updated_at;
  String? soft_delete;

  SalesProductPerDay({
    this.sales_product_per_day_sqlite_id,
    this.sales_product_per_day_id,
    this.branch_id,
    this.product_id,
    this.product_name,
    this.amount_sold,
    this.total_amount,
    this.total_ori_amount,
    this.date,
    this.sync_status,
    this.created_at,
    this.updated_at,
    this.soft_delete
  });

  SalesProductPerDay copy({
    int? sales_product_per_day_sqlite_id,
    int? sales_product_per_day_id,
    String? branch_id,
    String? product_id,
    String? product_name,
    String? amount_sold,
    String? total_amount,
    String? total_ori_amount,
    String? date,
    int? sync_status,
    String? created_at,
    String? updated_at,
    String? soft_delete
  }) =>
      SalesProductPerDay(
        sales_product_per_day_sqlite_id: sales_product_per_day_sqlite_id ?? this.sales_product_per_day_sqlite_id,
        sales_product_per_day_id: sales_product_per_day_id ?? this.sales_product_per_day_id,
        branch_id: branch_id ?? this.branch_id,
        product_id: product_id ?? this.product_id,
        product_name: product_name ?? this.product_name,
        amount_sold: amount_sold ?? this.amount_sold,
        total_amount: total_amount ?? this.total_amount,
        total_ori_amount: total_ori_amount ?? this.total_ori_amount,
        date: date ?? this.date,
        sync_status: sync_status ?? this.sync_status,
        created_at: created_at ?? this.created_at,
        updated_at: updated_at ?? this.updated_at,
        soft_delete: soft_delete ?? this.soft_delete,
      );

  static SalesProductPerDay fromJson(Map<String, Object?> json) => SalesProductPerDay (
    sales_product_per_day_sqlite_id: json[SalesProductPerDayFields.sales_product_per_day_sqlite_id] as int?,
    sales_product_per_day_id: json[SalesProductPerDayFields.sales_product_per_day_id] as int?,
    branch_id: json[SalesProductPerDayFields.branch_id] as String?,
    product_id: json[SalesProductPerDayFields.product_id] as String?,
    product_name: json[SalesProductPerDayFields.product_name] as String?,
    amount_sold: json[SalesProductPerDayFields.amount_sold] as String?,
    total_amount: json[SalesProductPerDayFields.total_amount] as String?,
    total_ori_amount: json[SalesProductPerDayFields.total_ori_amount] as String?,
    date: json[SalesProductPerDayFields.date] as String?,
    sync_status: json[SalesProductPerDayFields.sync_status] as int?,
    created_at: json[SalesProductPerDayFields.created_at] as String?,
    updated_at: json[SalesProductPerDayFields.updated_at] as String?,
    soft_delete: json[SalesProductPerDayFields.soft_delete] as String?,
  );

  Map<String, Object?> toJson() => {
    SalesProductPerDayFields.sales_product_per_day_sqlite_id: sales_product_per_day_sqlite_id,
    SalesProductPerDayFields.sales_product_per_day_id: sales_product_per_day_id,
    SalesProductPerDayFields.branch_id: branch_id,
    SalesProductPerDayFields.product_id: product_id,
    SalesProductPerDayFields.product_name: product_name,
    SalesProductPerDayFields.amount_sold: amount_sold,
    SalesProductPerDayFields.total_amount: total_amount,
    SalesProductPerDayFields.total_ori_amount: total_ori_amount,
    SalesProductPerDayFields.date: date,
    SalesProductPerDayFields.sync_status: sync_status,
    SalesProductPerDayFields.created_at: created_at,
    SalesProductPerDayFields.updated_at: updated_at,
    SalesProductPerDayFields.soft_delete: soft_delete,
  };
}
