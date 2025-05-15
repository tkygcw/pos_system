import 'dart:convert';

String tableSalesPerDay = 'tb_sales_per_day';

class SalesPerDayFields {
  static List<String> values = [
    sales_per_day_sqlite_id,
    sales_per_day_id,
    branch_id,
    total_amount,
    tax,
    charge,
    promotion,
    tax_detail,
    charge_detail,
    promotion_detail,
    rounding,
    date,
    payment_method,
    payment_method_sales,
    type,
    sync_status,
    created_at,
    updated_at,
    soft_delete
  ];

  static String sales_per_day_sqlite_id = 'sales_per_day_sqlite_id';
  static String sales_per_day_id = 'sales_per_day_id';
  static String branch_id = 'branch_id';
  static String total_amount = 'total_amount';
  static String tax = 'tax';
  static String charge = 'charge';
  static String promotion = 'promotion';
  static String tax_detail = 'tax_detail';
  static String charge_detail = 'charge_detail';
  static String promotion_detail = 'promotion_detail';
  static String rounding = 'rounding';
  static String date = 'date';
  static String payment_method = 'payment_method';
  static String payment_method_sales = 'payment_method_sales';
  static String type = 'type';
  static String sync_status = 'sync_status';
  static String created_at = 'created_at';
  static String updated_at = 'updated_at';
  static String soft_delete = 'soft_delete';
}

class SalesPerDay{
  int? sales_per_day_sqlite_id;
  int? sales_per_day_id;
  String? branch_id;
  String? total_amount;
  String? tax;
  String? charge;
  String? promotion;
  Map<String, double>? tax_detail;
  Map<String, double>? charge_detail;
  Map<String, double>? promotion_detail;
  String? rounding;
  String? date;
  String? payment_method;
  String? payment_method_sales;
  int? type;
  int? sync_status;
  String? created_at;
  String? updated_at;
  String? soft_delete;

  SalesPerDay({
    this.sales_per_day_sqlite_id,
    this.sales_per_day_id,
    this.branch_id,
    this.total_amount,
    this.tax,
    this.charge,
    this.promotion,
    this.tax_detail,
    this.charge_detail,
    this.promotion_detail,
    this.rounding,
    this.date,
    this.payment_method,
    this.payment_method_sales,
    this.type,
    this.sync_status,
    this.created_at,
    this.updated_at,
    this.soft_delete
  });

  SalesPerDay copy({
    int? sales_per_day_sqlite_id,
    int? sales_per_day_id,
    String? branch_id,
    String? total_amount,
    String? tax,
    String? charge,
    String? promotion,
    Map<String, double>? tax_detail,
    Map<String, double>? charge_detail,
    Map<String, double>? promotion_detail,
    String? rounding,
    String? date,
    String? payment_method,
    String? payment_method_sales,
    int? type,
    int? sync_status,
    String? created_at,
    String? updated_at,
    String? soft_delete,
  }) =>
      SalesPerDay(
          sales_per_day_sqlite_id: sales_per_day_sqlite_id ?? this.sales_per_day_sqlite_id,
          sales_per_day_id: sales_per_day_id ?? this.sales_per_day_id,
          branch_id: branch_id ?? this.branch_id,
          total_amount: total_amount ?? this.total_amount,
          tax: tax ?? this.tax,
          charge: charge ?? this.charge,
          promotion: promotion ?? this.promotion,
          tax_detail: tax_detail ?? this.tax_detail,
          charge_detail: charge_detail ?? this.charge_detail,
          promotion_detail: promotion_detail ?? this.promotion_detail,
          rounding: rounding ?? this.rounding,
          date: date ?? this.date,
          payment_method: payment_method ?? this.payment_method,
          payment_method_sales: payment_method_sales ?? this.payment_method_sales,
          type: type ?? this.type,
          sync_status: sync_status ?? this.sync_status,
          created_at: created_at ?? this.created_at,
          updated_at: updated_at ?? this.updated_at,
          soft_delete: soft_delete ?? this.soft_delete,
      );

  static SalesPerDay fromJson(Map<String, Object?> json) => SalesPerDay (
    sales_per_day_sqlite_id: json[SalesPerDayFields.sales_per_day_sqlite_id] as int?,
    sales_per_day_id: json[SalesPerDayFields.sales_per_day_id] as int?,
    branch_id: json[SalesPerDayFields.branch_id] as String?,
    total_amount: json[SalesPerDayFields.total_amount] as String?,
    tax: json[SalesPerDayFields.tax] as String?,
    charge: json[SalesPerDayFields.charge] as String?,
    promotion: json[SalesPerDayFields.promotion] as String?,
    tax_detail: json['tax_detail'] == null
        ? {}
        : (json['tax_detail'] is String)
        ? (json['tax_detail'].toString().trim().isNotEmpty
        ? Map<String, double>.from(jsonDecode(json['tax_detail'] as String).map(
            (key, value) => MapEntry(key as String, (value as num).toDouble())))
        : {})
        : (json['tax_detail'] is Map)
        ? Map<String, double>.from((json['tax_detail'] as Map).map(
            (key, value) => MapEntry(key as String, (value as num).toDouble())))
        : {},
    charge_detail: json['charge_detail'] == null
        ? {}
        : (json['charge_detail'] is String)
        ? (json['charge_detail'].toString().trim().isNotEmpty
        ? Map<String, double>.from(jsonDecode(json['charge_detail'] as String).map(
            (key, value) => MapEntry(key as String, (value as num).toDouble())))
        : {})
        : (json['charge_detail'] is Map)
        ? Map<String, double>.from((json['charge_detail'] as Map).map(
            (key, value) => MapEntry(key as String, (value as num).toDouble())))
        : {},
    promotion_detail: json['promotion_detail'] == null
        ? {}
        : (json['promotion_detail'] is String)
        ? (json['promotion_detail'].toString().trim().isNotEmpty
        ? Map<String, double>.from(jsonDecode(json['promotion_detail'] as String).map(
            (key, value) => MapEntry(key as String, (value as num).toDouble())))
        : {})
        : (json['promotion_detail'] is Map)
        ? Map<String, double>.from((json['promotion_detail'] as Map).map(
            (key, value) => MapEntry(key as String, (value as num).toDouble())))
        : {},
    rounding: json[SalesPerDayFields.rounding] as String?,
    date: json[SalesPerDayFields.date] as String?,
    payment_method: json[SalesPerDayFields.payment_method] as String?,
    payment_method_sales: json[SalesPerDayFields.payment_method_sales] as String?,
    type: json[SalesPerDayFields.type] as int?,
    sync_status: json[SalesPerDayFields.sync_status] as int?,
    created_at: json[SalesPerDayFields.created_at] as String?,
    updated_at: json[SalesPerDayFields.updated_at] as String?,
    soft_delete: json[SalesPerDayFields.soft_delete] as String?,
  );

  Map<String, Object?> toJson() => {
    SalesPerDayFields.sales_per_day_sqlite_id: sales_per_day_sqlite_id,
    SalesPerDayFields.sales_per_day_id: sales_per_day_id,
    SalesPerDayFields.branch_id: branch_id,
    SalesPerDayFields.total_amount: total_amount,
    SalesPerDayFields.tax: tax,
    SalesPerDayFields.charge: charge,
    SalesPerDayFields.promotion: promotion,
    SalesPerDayFields.tax_detail: tax_detail != null ? jsonEncode(tax_detail) : "{}",
    SalesPerDayFields.charge_detail: charge_detail != null ? jsonEncode(charge_detail) : "{}",
    SalesPerDayFields.promotion_detail: promotion_detail != null ? jsonEncode(promotion_detail) : "{}",
    SalesPerDayFields.rounding: rounding,
    SalesPerDayFields.date: date,
    SalesPerDayFields.payment_method: payment_method,
    SalesPerDayFields.payment_method_sales: payment_method_sales,
    SalesPerDayFields.type: type,
    SalesPerDayFields.sync_status: sync_status,
    SalesPerDayFields.created_at: created_at,
    SalesPerDayFields.updated_at: updated_at,
    SalesPerDayFields.soft_delete: soft_delete,
  };
}
