String? tableOrderDetail = 'tb_order_detail ';

class OrderDetailFields {
  static List<String> values = [
    order_detail_sqlite_id,
    order_detail_id,
    order_cache_id,
    branch_link_product_id,
    productName,
    has_variant,
    product_variant_name,
    price,
    quantity,
    remark,
    account,
    created_at,
    updated_at,
    soft_delete
  ];

  static String order_detail_sqlite_id = 'order_detail_sqlite_id';
  static String order_detail_id = 'order_detail_id';
  static String order_cache_id = 'order_cache_id';
  static String branch_link_product_id = 'branch_link_product_id';
  static String productName = 'product_name';
  static String has_variant = 'has_variant';
  static String product_variant_name = 'product_variant_name';
  static String price = 'price';
  static String quantity = 'quantity';
  static String remark = 'remark';
  static String account = 'account';
  static String created_at = 'created_at';
  static String updated_at = 'updated_at';
  static String soft_delete = 'soft_delete';
}

class OrderDetail{
  int? order_detail_sqlite_id;
  int? order_detail_id;
  String? order_cache_id;
  String? branch_link_product_id;
  String? productName = '';
  String? has_variant = '';
  String? product_variant_name = '';
  String? price = '';
  String? quantity;
  String? remark;
  String? account;
  String? created_at;
  String? updated_at;
  String? soft_delete;
  String? total_amount;
  String product_name = '';
  String variant_name ='';
  List<String> modifier_name = [];

  OrderDetail(
      {this.order_detail_sqlite_id,
        this.order_detail_id,
        this.order_cache_id,
        this.branch_link_product_id,
        this.productName,
        this.has_variant,
        this.product_variant_name,
        this.price,
        this.quantity,
        this.remark,
        this.account,
        this.created_at,
        this.updated_at,
        this.soft_delete,
        this.total_amount});

  OrderDetail copy({
    int? order_detail_sqlite_id,
    int? order_detail_id,
    String? order_cache_id,
    String? branch_link_product_id,
    String? productName,
    String? has_variant,
    String? product_variant_name,
    String? price,
    String? quantity,
    String? remark,
    String? account,
    String? created_at,
    String? updated_at,
    String? soft_delete,
  }) =>
      OrderDetail(
          order_detail_sqlite_id: order_detail_sqlite_id ?? this.order_detail_sqlite_id,
          order_detail_id: order_detail_id ?? this.order_detail_id,
          order_cache_id: order_cache_id ?? this.order_cache_id,
          branch_link_product_id: branch_link_product_id ?? this.branch_link_product_id,
          productName: productName ?? this.productName,
          has_variant: has_variant ?? this.has_variant,
          product_variant_name: product_variant_name ?? this.product_variant_name,
          price: price ?? this.price,
          quantity: quantity ?? this.quantity,
          remark: remark ?? this.remark,
          account: account ?? this.account,
          created_at: created_at ?? this.created_at,
          updated_at: updated_at ?? this.updated_at,
          soft_delete: soft_delete ?? this.soft_delete,
          total_amount: total_amount ?? this.total_amount);

  static OrderDetail fromJson(Map<String, Object?> json) => OrderDetail(
    order_detail_sqlite_id: json[OrderDetailFields.order_detail_sqlite_id] as int?,
    order_detail_id: json[OrderDetailFields.order_detail_id] as int?,
    order_cache_id: json[OrderDetailFields.order_cache_id] as String?,
    branch_link_product_id: json[OrderDetailFields.branch_link_product_id] as String?,
    productName: json[OrderDetailFields.productName] as String?,
    has_variant: json[OrderDetailFields.has_variant] as String?,
    product_variant_name: json[OrderDetailFields.product_variant_name] as String?,
    price: json[OrderDetailFields.price] as String?,
    quantity: json[OrderDetailFields.quantity] as String?,
    remark: json[OrderDetailFields.remark] as String?,
    account: json[OrderDetailFields.account] as String?,
    created_at: json[OrderDetailFields.created_at] as String?,
    updated_at: json[OrderDetailFields.updated_at] as String?,
    soft_delete: json[OrderDetailFields.soft_delete] as String?,
    total_amount: json['total_amount'] as String?
  );

  Map<String, Object?> toJson() => {
    OrderDetailFields.order_detail_sqlite_id: order_detail_sqlite_id,
    OrderDetailFields.order_detail_id: order_detail_id,
    OrderDetailFields.order_cache_id: order_cache_id,
    OrderDetailFields.branch_link_product_id: branch_link_product_id,
    OrderDetailFields.productName: productName,
    OrderDetailFields.has_variant: has_variant,
    OrderDetailFields.product_variant_name: product_variant_name,
    OrderDetailFields.price: price,
    OrderDetailFields.quantity: quantity,
    OrderDetailFields.remark: remark,
    OrderDetailFields.account: account,
    OrderDetailFields.created_at: created_at,
    OrderDetailFields.updated_at: updated_at,
    OrderDetailFields.soft_delete: soft_delete,
  };
}
