String? tableOrder = 'tb_order';

class OrderFields {
  static List<String> values = [
    order_sqlite_id,
    order_id,
    order_number,
    company_id,
    customer_id,
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
    created_at,
    updated_at,
    soft_delete
  ];

  static String order_sqlite_id = 'order_sqlite_id';
  static String order_id = 'order_id';
  static String order_number = 'order_number';
  static String company_id = 'company_id';
  static String customer_id = 'customer_id';
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
  static String created_at = 'created_at';
  static String updated_at = 'updated_at';
  static String soft_delete = 'soft_delete';
}

class Order {
  int? order_sqlite_id;
  int? order_id;
  String? order_number;
  String? company_id;
  String? customer_id;
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
  String? created_at;
  String? updated_at;
  String? soft_delete;
  bool isSelected = false;
  String? payment_name;

  generateOrderNumber(){
    String orderNum = '';
    orderNum = '#${order_number}-${branch_id?.padLeft(3,'0')}';
    return orderNum;
  }

  Order(
      {this.order_sqlite_id,
      this.order_id,
      this.order_number,
      this.company_id,
      this.customer_id,
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
      this.created_at,
      this.updated_at,
      this.soft_delete,
      this.payment_name});

  Order copy({
    int? order_sqlite_id,
    int? order_id,
    String? order_number,
    String? company_id,
    String? customer_id,
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
    String? created_at,
    String? updated_at,
    String? soft_delete,
  }) =>
      Order(
          order_sqlite_id: order_sqlite_id ?? this.order_sqlite_id,
          order_id: order_id ?? this.order_id,
          order_number: order_number ?? this.order_number,
          company_id: company_id ?? this.company_id,
          customer_id: customer_id ?? this.customer_id,
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
          created_at: created_at ?? this.created_at,
          updated_at: updated_at ?? this.updated_at,
          soft_delete: soft_delete ?? this.soft_delete,
          payment_name: payment_name ?? this.payment_name);

  static Order fromJson(Map<String, Object?> json) => Order(
        order_sqlite_id: json[OrderFields.order_sqlite_id] as int?,
        order_id: json[OrderFields.order_id] as int?,
        order_number: json[OrderFields.order_number] as String?,
        company_id: json[OrderFields.company_id] as String?,
        customer_id: json[OrderFields.customer_id] as String?,
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
        created_at: json[OrderFields.created_at] as String?,
        updated_at: json[OrderFields.updated_at] as String?,
        soft_delete: json[OrderFields.soft_delete] as String?,
        payment_name: json['name'] as String?
      );

  Map<String, Object?> toJson() => {
        OrderFields.order_sqlite_id: order_sqlite_id,
        OrderFields.order_id: order_id,
        OrderFields.order_number: order_number,
        OrderFields.company_id: company_id,
        OrderFields.customer_id: customer_id,
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
        OrderFields.created_at: created_at,
        OrderFields.updated_at: updated_at,
        OrderFields.soft_delete: soft_delete,
      };
}
