String? tableSale = 'tb_sale ';

class SaleFields {
  static List<String> values = [
    sale_sqlite_id,
    sale_id,
    company_id,
    branch_id,
    daily_sales,
    user_sales,
    item_sales,
    cashier_sales,
    hours_sales,
    payment_sales,
    created_at,
    updated_at,
    soft_delete
  ];

  static String sale_sqlite_id = 'sale_sqlite_id';
  static String sale_id = 'sale_id';
  static String company_id = 'company_id';
  static String branch_id = 'branch_id';
  static String daily_sales = 'daily_sales';
  static String user_sales = 'user_sales';
  static String item_sales = 'item_sales';
  static String cashier_sales = 'cashier_sales';
  static String hours_sales = 'hours_sales';
  static String payment_sales = 'payment_sales';
  static String created_at = 'created_at';
  static String updated_at = 'updated_at';
  static String soft_delete = 'soft_delete';
}

class Sale{
  int? sale_sqlite_id;
  int? sale_id;
  String? company_id;
  String? branch_id;
  String? daily_sales;
  String? user_sales;
  String? item_sales;
  String? cashier_sales;
  String? hours_sales;
  String? payment_sales;
  String? created_at;
  String? updated_at;
  String? soft_delete;

  Sale(
      {this.sale_sqlite_id,
        this.sale_id,
        this.company_id,
        this.branch_id,
        this.daily_sales,
        this.user_sales,
        this.item_sales,
        this.cashier_sales,
        this.hours_sales,
        this.payment_sales,
        this.created_at,
        this.updated_at,
        this.soft_delete});

  Sale copy({
    int? sale_sqlite_id,
    int? sale_id,
    String? company_id,
    String? branch_id,
    String? daily_sales,
    String? user_sales,
    String? item_sales,
    String? cashier_sales,
    String? hours_sales,
    String? payment_sales,
    String? created_at,
    String? updated_at,
    String? soft_delete,
  }) =>
      Sale(
          sale_sqlite_id: sale_sqlite_id ?? this.sale_sqlite_id,
          sale_id: sale_id ?? this.sale_id,
          company_id: company_id ?? this.company_id,
          branch_id: branch_id ?? this.branch_id,
          daily_sales: daily_sales ?? this.daily_sales,
          user_sales: user_sales ?? this.user_sales,
          item_sales: item_sales ?? this.item_sales,
          cashier_sales: cashier_sales ?? this.cashier_sales,
          hours_sales: hours_sales ?? this.hours_sales,
          payment_sales: payment_sales ?? this.payment_sales,
          created_at: created_at ?? this.created_at,
          updated_at: updated_at ?? this.updated_at,
          soft_delete: soft_delete ?? this.soft_delete);

  static Sale fromJson(Map<String, Object?> json) => Sale (
    sale_sqlite_id: json[SaleFields.sale_sqlite_id] as int?,
    sale_id: json[SaleFields.sale_id] as int?,
    company_id: json[SaleFields.company_id] as String?,
    branch_id: json[SaleFields.branch_id] as String?,
    daily_sales: json[SaleFields.daily_sales] as String?,
    user_sales: json[SaleFields.user_sales] as String?,
    item_sales: json[SaleFields.item_sales] as String?,
    cashier_sales: json[SaleFields.cashier_sales] as String?,
    hours_sales: json[SaleFields.hours_sales] as String?,
    payment_sales: json[SaleFields.payment_sales] as String?,
    created_at: json[SaleFields.created_at] as String?,
    updated_at: json[SaleFields.updated_at] as String?,
    soft_delete: json[SaleFields.soft_delete] as String?,
  );

  Map<String, Object?> toJson() => {
    SaleFields.sale_sqlite_id: sale_sqlite_id,
    SaleFields.sale_id: sale_id,
    SaleFields.company_id: company_id,
    SaleFields.branch_id: branch_id,
    SaleFields.daily_sales: daily_sales,
    SaleFields.user_sales: user_sales,
    SaleFields.item_sales: item_sales,
    SaleFields.cashier_sales: cashier_sales,
    SaleFields.hours_sales: hours_sales,
    SaleFields.payment_sales: payment_sales,
    SaleFields.created_at: created_at,
    SaleFields.updated_at: updated_at,
    SaleFields.soft_delete: soft_delete,
  };
}
