import 'order_tax_detail.dart';

String? tableOrder = 'tb_order';

class OrderFields {
  static List<String> values = [
    order_sqlite_id,
    order_id,
    order_number,
    order_queue,
    company_id,
    customer_id,
    dining_id,
    dining_name,
    branch_link_promotion_id,
    payment_link_company_id,
    branch_id,
    branch_link_tax_id,
    subtotal,
    amount,
    rounding,
    final_amount,
    close_by,
    payment_status,
    payment_received,
    payment_change,
    order_key,
    refund_sqlite_id,
    refund_key,
    settlement_sqlite_id,
    settlement_key,
    sync_status,
    created_at,
    updated_at,
    soft_delete
  ];

  static String order_sqlite_id = 'order_sqlite_id';
  static String order_id = 'order_id';
  static String order_number = 'order_number';
  static String order_queue = 'order_queue';
  static String company_id = 'company_id';
  static String customer_id = 'customer_id';
  static String dining_id = 'dining_id';
  static String dining_name = 'dining_name';
  static String branch_link_promotion_id = 'branch_link_promotion_id';
  static String payment_link_company_id = 'payment_link_company_id';
  static String branch_id = 'branch_id';
  static String branch_link_tax_id = 'branch_link_tax_id';
  static String subtotal = 'subtotal';
  static String amount = 'amount';
  static String rounding = 'rounding';
  static String final_amount = 'final_amount';
  static String close_by = 'close_by';
  static String payment_status = 'payment_status';
  static String payment_received = 'payment_received';
  static String payment_change = 'payment_change';
  static String order_key = 'order_key';
  static String refund_sqlite_id = 'refund_sqlite_id';
  static String refund_key = 'refund_key';
  static String settlement_sqlite_id = 'settlement_sqlite_id';
  static String settlement_key = 'settlement_key';
  static String sync_status = 'sync_status';
  static String created_at = 'created_at';
  static String updated_at = 'updated_at';
  static String soft_delete = 'soft_delete';
}

class Order {
  int? order_sqlite_id;
  int? order_id;
  String? order_number;
  String? order_queue;
  String? company_id;
  String? customer_id;
  String? dining_id;
  String? dining_name;
  String? branch_link_promotion_id;
  String? payment_link_company_id;
  String? branch_id;
  String? branch_link_tax_id;
  String? subtotal;
  String? amount;
  String? rounding;
  String? final_amount;
  String? close_by;
  int? payment_status;
  String? payment_received;
  String? payment_change;
  String? order_key;
  String? refund_sqlite_id;
  String? refund_key;
  String? settlement_sqlite_id;
  String? settlement_key;
  int? sync_status;
  String? created_at;
  String? updated_at;
  String? soft_delete;
  bool isSelected = false;
  String? payment_name;
  String? payment_type;
  String? refund_by;
  String? refund_at;
  int? item_sum;
  double? net_sales;
  double? gross_sales;
  String? bill_no;
  double? promo_amount;
  double? total_tax_amount;
  String? tax_id;
  List<OrderTaxDetail> taxDetailList = [];
  String? counterOpenDate;

  generateOrderNumber(){
    String orderNum = '';
    orderNum = '#${order_number}-${branch_id?.padLeft(3,'0')}-${created_at.toString().replaceAll(' ', '').replaceAll('-', '').replaceAll(':', '')}';
    return orderNum;
  }

  Order(
      {this.order_sqlite_id,
        this.order_id,
        this.order_number,
        this.order_queue,
        this.company_id,
        this.customer_id,
        this.dining_id,
        this.dining_name,
        this.branch_link_promotion_id,
        this.payment_link_company_id,
        this.branch_id,
        this.branch_link_tax_id,
        this.subtotal,
        this.amount,
        this.rounding,
        this.final_amount,
        this.close_by,
        this.payment_status,
        this.payment_received,
        this.payment_change,
        this.order_key,
        this.refund_sqlite_id,
        this.refund_key,
        this.settlement_sqlite_id,
        this.settlement_key,
        this.sync_status,
        this.created_at,
        this.updated_at,
        this.soft_delete,
        this.payment_name,
        this.payment_type,
        this.refund_by,
        this.refund_at,
        this.item_sum,
        this.net_sales,
        this.gross_sales,
        this.bill_no,
        this.promo_amount,
        this.total_tax_amount,
        this.tax_id,
        this.counterOpenDate});

  Order copy({
    int? order_sqlite_id,
    int? order_id,
    String? order_number,
    String? order_queue,
    String? company_id,
    String? customer_id,
    String? dining_id,
    String? dining_name,
    String? branch_link_promotion_id,
    String? payment_link_company_id,
    String? branch_id,
    String? branch_link_tax_id,
    String? subtotal,
    String? amount,
    String? rounding,
    String? final_amount,
    String? close_by,
    int? payment_status,
    String? payment_received,
    String? payment_change,
    String? order_key,
    String? refund_sqlite_id,
    String? refund_key,
    String? settlement_sqlite_id,
    String? settlement_key,
    int? sync_status,
    String? created_at,
    String? updated_at,
    String? soft_delete,
  }) =>
      Order(
          order_sqlite_id: order_sqlite_id ?? this.order_sqlite_id,
          order_id: order_id ?? this.order_id,
          order_number: order_number ?? this.order_number,
          order_queue: order_queue ?? this.order_queue,
          company_id: company_id ?? this.company_id,
          customer_id: customer_id ?? this.customer_id,
          dining_id: dining_id ?? this.dining_id,
          dining_name: dining_name ?? this.dining_name,
          branch_link_promotion_id: branch_link_promotion_id ?? this.branch_link_promotion_id,
          payment_link_company_id: payment_link_company_id ?? this.payment_link_company_id,
          branch_id: branch_id ?? this.branch_id,
          branch_link_tax_id: branch_link_tax_id ?? this.branch_link_tax_id,
          subtotal: subtotal ?? this.subtotal,
          amount: amount ?? this.amount,
          rounding: rounding ?? this.rounding,
          final_amount: final_amount ?? this.final_amount,
          close_by: close_by ?? this.close_by,
          payment_status: payment_status ?? this.payment_status,
          payment_received: payment_received ?? this.payment_received,
          payment_change: payment_change ?? this.payment_change,
          order_key: order_key ?? this.order_key,
          refund_sqlite_id: refund_sqlite_id ?? this.refund_sqlite_id,
          refund_key: refund_key ?? this.refund_key,
          settlement_sqlite_id: settlement_sqlite_id ?? this.settlement_sqlite_id,
          settlement_key: settlement_key ?? this.settlement_key,
          sync_status: sync_status ?? this.sync_status,
          created_at: created_at ?? this.created_at,
          updated_at: updated_at ?? this.updated_at,
          soft_delete: soft_delete ?? this.soft_delete,
          payment_name: payment_name ?? this.payment_name,
          payment_type: payment_type ?? this.payment_type);

  static Order fromJson(Map<String, Object?> json) => Order(
      order_sqlite_id: json[OrderFields.order_sqlite_id] as int?,
      order_id: json[OrderFields.order_id] as int?,
      order_number: json[OrderFields.order_number] as String?,
      order_queue: json[OrderFields.order_queue] as String?,
      company_id: json[OrderFields.company_id] as String?,
      customer_id: json[OrderFields.customer_id] as String?,
      dining_id: json[OrderFields.dining_id] as String?,
      dining_name: json[OrderFields.dining_name] as String?,
      branch_link_promotion_id: json[OrderFields.branch_link_promotion_id] as String?,
      payment_link_company_id: json[OrderFields.payment_link_company_id] as String?,
      branch_id: json[OrderFields.branch_id] as String?,
      branch_link_tax_id: json[OrderFields.branch_link_tax_id] as String?,
      subtotal: json[OrderFields.subtotal] as String?,
      amount: json[OrderFields.amount] as String?,
      rounding: json[OrderFields.rounding] as String?,
      final_amount: json[OrderFields.final_amount] as String?,
      close_by: json[OrderFields.close_by] as String?,
      payment_status: json[OrderFields.payment_status] as int?,
      payment_received: json[OrderFields.payment_received] as String?,
      payment_change: json[OrderFields.payment_change] as String?,
      order_key: json[OrderFields.order_key] as String?,
      refund_sqlite_id: json[OrderFields.refund_sqlite_id] as String?,
      refund_key: json[OrderFields.refund_key] as String?,
      settlement_sqlite_id: json[OrderFields.settlement_sqlite_id] as String?,
      settlement_key: json[OrderFields.settlement_key] as String?,
      sync_status: json[OrderFields.sync_status] as int?,
      created_at: json[OrderFields.created_at] as String?,
      updated_at: json[OrderFields.updated_at] as String?,
      soft_delete: json[OrderFields.soft_delete] as String?,
      payment_name: json['name'] as String?,
      payment_type: json['payment_type_id'] as String?,
      refund_by: json['refund_name'] as String?,
      refund_at: json['refund_at'] as String?,
      item_sum: json['item_sum'] as int?,
      net_sales: json['net_sales'] as double?,
      gross_sales: json['gross_sales'] as double?,
      bill_no: json['bill_no'] as String?,
      promo_amount: json['promo_amount'] as double?,
      total_tax_amount: json['total_tax_amount'] as double?,
      tax_id: json['tax_id'] as String?,
      counterOpenDate: json['counterOpenDate'] as String?,
  );

  Map<String, Object?> toJson() => {
    OrderFields.order_sqlite_id: order_sqlite_id,
    OrderFields.order_id: order_id,
    OrderFields.order_number: order_number,
    OrderFields.order_queue: order_queue,
    OrderFields.company_id: company_id,
    OrderFields.customer_id: customer_id,
    OrderFields.dining_id: dining_id,
    OrderFields.dining_name: dining_name,
    OrderFields.branch_link_promotion_id: branch_link_promotion_id,
    OrderFields.payment_link_company_id: payment_link_company_id,
    OrderFields.branch_id: branch_id,
    OrderFields.branch_link_tax_id: branch_link_tax_id,
    OrderFields.subtotal: subtotal,
    OrderFields.amount: amount,
    OrderFields.rounding: rounding,
    OrderFields.final_amount: final_amount,
    OrderFields.close_by: close_by,
    OrderFields.payment_status: payment_status,
    OrderFields.payment_received: payment_received,
    OrderFields.payment_change: payment_change,
    OrderFields.order_key: order_key,
    OrderFields.refund_sqlite_id: refund_sqlite_id,
    OrderFields.refund_key: refund_key,
    OrderFields.settlement_sqlite_id: settlement_sqlite_id,
    OrderFields.settlement_key: settlement_key,
    OrderFields.sync_status: sync_status,
    OrderFields.created_at: created_at,
    OrderFields.updated_at: updated_at,
    OrderFields.soft_delete: soft_delete,
  };
}