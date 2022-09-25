String? tableOrderCache = 'tb_order_cache ';

class OrderCacheFields {
  static List<String> values = [
    order_cache_sqlite_id,
    order_cache_id,
    company_id,
    branch_id,
    order_detail_id,
    table_id,
    dining_id,
    order_id,
    order_by,
    customer_id,
    total_amount,
    created_at,
    updated_at,
    soft_delete
  ];

  static String order_cache_sqlite_id = 'order_cache_sqlite_id';
  static String order_cache_id = 'order_cache_id';
  static String company_id = 'company_id';
  static String branch_id = 'branch_id';
  static String order_detail_id = 'order_detail_id';
  static String table_id = 'table_id';
  static String dining_id = 'dining_id';
  static String order_id = 'order_id';
  static String order_by = 'order_by';
  static String customer_id = 'customer_id';
  static String total_amount = 'total_amount';
  static String created_at = 'created_at';
  static String updated_at = 'updated_at';
  static String soft_delete = 'soft_delete';
}

class OrderCache{
  int? order_cache_sqlite_id;
  int? order_cache_id;
  String? company_id;
  String? branch_id;
  String? order_detail_id;
  String? table_id;
  String? dining_id;
  String? order_id;
  String? order_by;
  String? customer_id;
  String? total_amount;
  String? created_at;
  String? updated_at;
  String? soft_delete;

  OrderCache(
      {this.order_cache_sqlite_id,
        this.order_cache_id,
        this.company_id,
        this.branch_id,
        this.order_detail_id,
        this.table_id,
        this.dining_id,
        this.order_id,
        this.order_by,
        this.customer_id,
        this.total_amount,
        this.created_at,
        this.updated_at,
        this.soft_delete});

  OrderCache copy({
    int? order_cache_sqlite_id,
    int? order_cache_id,
    String? company_id,
    String? branch_id,
    String? order_detail_id,
    String? table_id,
    String? dining_id,
    String? order_id,
    String? order_by,
    String? customer_id,
    String? total_amount,
    String? created_at,
    String? updated_at,
    String? soft_delete,
  }) =>
      OrderCache(
          order_cache_sqlite_id: order_cache_sqlite_id ?? this.order_cache_sqlite_id,
          order_cache_id: order_cache_id ?? this.order_cache_id,
          company_id: company_id ?? this.company_id,
          branch_id: branch_id ?? this.branch_id,
          order_detail_id: order_detail_id ?? this.order_detail_id,
          table_id: table_id ?? this.table_id,
          dining_id: dining_id ?? this.dining_id,
          order_id: order_id ?? this.order_id,
          order_by: order_by ?? this.order_by,
          customer_id: customer_id ?? this.customer_id,
          total_amount: total_amount ?? this.total_amount,
          created_at: created_at ?? this.created_at,
          updated_at: updated_at ?? this.updated_at,
          soft_delete: soft_delete ?? this.soft_delete);

  static OrderCache fromJson(Map<String, Object?> json) => OrderCache(
    order_cache_sqlite_id: json[OrderCacheFields.order_cache_sqlite_id] as int?,
    order_cache_id: json[OrderCacheFields.order_cache_id] as int?,
    company_id: json[OrderCacheFields.company_id] as String?,
    branch_id: json[OrderCacheFields.branch_id] as String?,
    order_detail_id: json[OrderCacheFields.order_detail_id] as String?,
    table_id: json[OrderCacheFields.table_id] as String?,
    dining_id: json[OrderCacheFields.dining_id] as String?,
    order_id: json[OrderCacheFields.order_id] as String?,
    order_by: json[OrderCacheFields.order_by] as String?,
    customer_id: json[OrderCacheFields.customer_id] as String?,
    total_amount: json[OrderCacheFields.total_amount] as String?,
    created_at: json[OrderCacheFields.created_at] as String?,
    updated_at: json[OrderCacheFields.updated_at] as String?,
    soft_delete: json[OrderCacheFields.soft_delete] as String?,
  );

  Map<String, Object?> toJson() => {
    OrderCacheFields.order_cache_sqlite_id: order_cache_sqlite_id,
    OrderCacheFields.order_cache_id: order_cache_id,
    OrderCacheFields.company_id: company_id,
    OrderCacheFields.branch_id: branch_id,
    OrderCacheFields.order_detail_id: order_detail_id,
    OrderCacheFields.table_id: table_id,
    OrderCacheFields.dining_id: dining_id,
    OrderCacheFields.order_id: order_id,
    OrderCacheFields.order_by: order_by,
    OrderCacheFields.customer_id: customer_id,
    OrderCacheFields.total_amount: total_amount,
    OrderCacheFields.created_at: created_at,
    OrderCacheFields.updated_at: updated_at,
    OrderCacheFields.soft_delete: soft_delete,
  };
}
