String tableSalesCategoryPerDay = 'tb_sales_category_per_day';

class SalesCategoryPerDayFields {
  static List<String> values = [
    sales_category_per_day_sqlite_id,
    sales_category_per_day_id,
    branch_id,
    category_id,
    category_name,
    amount_sold,
    total_amount,
    total_ori_amount,
    date,
    sync_status,
    created_at,
    updated_at,
    soft_delete
  ];

  static String sales_category_per_day_sqlite_id = 'category_sales_per_day_sqlite_id';
  static String sales_category_per_day_id = 'category_sales_per_day_id';
  static String branch_id = 'branch_id';
  static String category_id = 'category_id';
  static String category_name = 'category_name';
  static String amount_sold = 'amount_sold';
  static String total_amount = 'total_amount';
  static String total_ori_amount = 'total_ori_amount';
  static String date = 'date';
  static String sync_status = 'sync_status';
  static String created_at = 'created_at';
  static String updated_at = 'updated_at';
  static String soft_delete = 'soft_delete';
}

class SalesCategoryPerDay{
  int? category_sales_per_day_sqlite_id;
  int? category_sales_per_day_id;
  String? branch_id;
  String? category_id;
  String? category_name;
  String? amount_sold;
  String? total_amount;
  String? total_ori_amount;
  String? date;
  int? sync_status;
  String? created_at;
  String? updated_at;
  String? soft_delete;

  SalesCategoryPerDay({
    this.category_sales_per_day_sqlite_id,
    this.category_sales_per_day_id,
    this.branch_id,
    this.category_id,
    this.category_name,
    this.amount_sold,
    this.total_amount,
    this.total_ori_amount,
    this.date,
    this.sync_status,
    this.created_at,
    this.updated_at,
    this.soft_delete
  });

  SalesCategoryPerDay copy({
    int? category_sales_per_day_sqlite_id,
    int? category_sales_per_day_id,
    String? branch_id,
    String? category_id,
    String? category_name,
    String? amount_sold,
    String? total_amount,
    String? total_ori_amount,
    String? date,
    int? sync_status,
    String? created_at,
    String? updated_at,
    String? soft_delete
  }) =>
      SalesCategoryPerDay(
        category_sales_per_day_sqlite_id: category_sales_per_day_sqlite_id ?? this.category_sales_per_day_sqlite_id,
        category_sales_per_day_id: category_sales_per_day_id ?? this.category_sales_per_day_id,
        branch_id: branch_id ?? this.branch_id,
        category_id: category_id ?? this.category_id,
        category_name: category_name ?? this.category_name,
        amount_sold: amount_sold ?? this.amount_sold,
        total_amount: total_amount ?? this.total_amount,
        total_ori_amount: total_ori_amount ?? this.total_ori_amount,
        date: date ?? this.date,
        sync_status: sync_status ?? this.sync_status,
        created_at: created_at ?? this.created_at,
        updated_at: updated_at ?? this.updated_at,
        soft_delete: soft_delete ?? this.soft_delete,
      );

  static SalesCategoryPerDay fromJson(Map<String, Object?> json) => SalesCategoryPerDay (
    category_sales_per_day_sqlite_id: json[SalesCategoryPerDayFields.sales_category_per_day_sqlite_id] as int?,
    category_sales_per_day_id: json[SalesCategoryPerDayFields.sales_category_per_day_id] as int?,
    branch_id: json[SalesCategoryPerDayFields.branch_id] as String?,
    category_id: json[SalesCategoryPerDayFields.category_id] as String?,
    category_name: json[SalesCategoryPerDayFields.category_name] as String?,
    amount_sold: json[SalesCategoryPerDayFields.amount_sold] as String?,
    total_amount: json[SalesCategoryPerDayFields.total_amount] as String?,
    total_ori_amount: json[SalesCategoryPerDayFields.total_ori_amount] as String?,
    date: json[SalesCategoryPerDayFields.date] as String?,
    sync_status: json[SalesCategoryPerDayFields.sync_status] as int?,
    created_at: json[SalesCategoryPerDayFields.created_at] as String?,
    updated_at: json[SalesCategoryPerDayFields.updated_at] as String?,
    soft_delete: json[SalesCategoryPerDayFields.soft_delete] as String?,
  );

  Map<String, Object?> toJson() => {
    SalesCategoryPerDayFields.sales_category_per_day_sqlite_id: category_sales_per_day_sqlite_id,
    SalesCategoryPerDayFields.sales_category_per_day_id: category_sales_per_day_id,
    SalesCategoryPerDayFields.branch_id: branch_id,
    SalesCategoryPerDayFields.category_id: category_id,
    SalesCategoryPerDayFields.category_name: category_name,
    SalesCategoryPerDayFields.amount_sold: amount_sold,
    SalesCategoryPerDayFields.total_amount: total_amount,
    SalesCategoryPerDayFields.total_ori_amount: total_ori_amount,
    SalesCategoryPerDayFields.date: date,
    SalesCategoryPerDayFields.sync_status: sync_status,
    SalesCategoryPerDayFields.created_at: created_at,
    SalesCategoryPerDayFields.updated_at: updated_at,
    SalesCategoryPerDayFields.soft_delete: soft_delete,
  };
}
