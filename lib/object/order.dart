String? tableOrder = 'tb_order';

class OrderFields {
  static List<String> values = [
    order_sqlite_id,
    order_id,
    company_id,
    customer_id,
    branch_link_promotion_id,
    payment_link_company_id,
    branch_id,
    branch_link_tax_id,
    amount,
    rounding,
    final_amount,
    close_by,
    created_at,
    updated_at,
    soft_delete
  ];

  static String order_sqlite_id = 'order_sqlite_id';
  static String order_id = 'order_id';
  static String company_id = 'company_id';
  static String customer_id = 'customer_id';
  static String branch_link_promotion_id = 'branch_link_promotion_id';
  static String payment_link_company_id = 'payment_link_company_id';
  static String branch_id = 'branch_id';
  static String branch_link_tax_id = 'branch_link_tax_id';
  static String amount = 'amount';
  static String rounding = 'rounding';
  static String final_amount = 'final_amount';
  static String close_by = 'close_by';
  static String created_at = 'created_at';
  static String updated_at = 'updated_at';
  static String soft_delete = 'soft_delete';
}

class Order {
  int? order_sqlite_id;
  int? order_id;
  String? company_id;
  String? customer_id;
  String? branch_link_promotion_id;
  String? payment_link_company_id;
  String? branch_id;
  String? branch_link_tax_id;
  String? amount;
  String? rounding;
  String? final_amount;
  String? close_by;
  String? created_at;
  String? updated_at;
  String? soft_delete;

  Order(
      {this.order_sqlite_id,
      this.order_id,
      this.company_id,
      this.customer_id,
      this.branch_link_promotion_id,
      this.payment_link_company_id,
      this.branch_id,
      this.branch_link_tax_id,
      this.amount,
      this.rounding,
      this.final_amount,
      this.close_by,
      this.created_at,
      this.updated_at,
      this.soft_delete});

  Order copy({
    int? order_sqlite_id,
    int? order_id,
    String? company_id,
    String? customer_id,
    String? branch_link_promotion_id,
    String? payment_link_company_id,
    String? branch_id,
    String? branch_link_tax_id,
    String? amount,
    String? rounding,
    String? final_amount,
    String? close_by,
    String? created_at,
    String? updated_at,
    String? soft_delete,
  }) =>
      Order(
          order_sqlite_id: order_sqlite_id ?? this.order_sqlite_id,
          order_id: order_id ?? this.order_id,
          company_id: company_id ?? this.company_id,
          customer_id: customer_id ?? this.customer_id,
          branch_link_promotion_id:
              branch_link_promotion_id ?? this.branch_link_promotion_id,
          payment_link_company_id:
              payment_link_company_id ?? this.payment_link_company_id,
          branch_id: branch_id ?? this.branch_id,
          branch_link_tax_id: branch_link_tax_id ?? this.branch_link_tax_id,
          amount: amount ?? this.amount,
          rounding: rounding ?? this.rounding,
          final_amount: final_amount ?? this.final_amount,
          close_by: close_by ?? this.close_by,
          created_at: created_at ?? this.created_at,
          updated_at: updated_at ?? this.updated_at,
          soft_delete: soft_delete ?? this.soft_delete);

  static Order fromJson(Map<String, Object?> json) => Order(
        order_sqlite_id: json[OrderFields.order_sqlite_id] as int?,
        order_id: json[OrderFields.order_id] as int?,
        company_id: json[OrderFields.company_id] as String?,
        customer_id: json[OrderFields.customer_id] as String?,
        branch_link_promotion_id:
            json[OrderFields.branch_link_promotion_id] as String?,
        payment_link_company_id:
            json[OrderFields.payment_link_company_id] as String?,
        branch_id: json[OrderFields.branch_id] as String?,
        branch_link_tax_id: json[OrderFields.branch_link_tax_id] as String?,
        amount: json[OrderFields.amount] as String?,
        rounding: json[OrderFields.rounding] as String?,
        final_amount: json[OrderFields.final_amount] as String?,
        close_by: json[OrderFields.close_by] as String?,
        created_at: json[OrderFields.created_at] as String?,
        updated_at: json[OrderFields.updated_at] as String?,
        soft_delete: json[OrderFields.soft_delete] as String?,
      );

  Map<String, Object?> toJson() => {
        OrderFields.order_sqlite_id: order_sqlite_id,
        OrderFields.order_id: order_id,
        OrderFields.company_id: company_id,
        OrderFields.customer_id: customer_id,
        OrderFields.branch_link_promotion_id: branch_link_promotion_id,
        OrderFields.payment_link_company_id: payment_link_company_id,
        OrderFields.branch_id: branch_id,
        OrderFields.branch_link_tax_id: branch_link_tax_id,
        OrderFields.amount: amount,
        OrderFields.rounding: rounding,
        OrderFields.final_amount: final_amount,
        OrderFields.close_by: close_by,
        OrderFields.created_at: created_at,
        OrderFields.updated_at: updated_at,
        OrderFields.soft_delete: soft_delete,
      };
}
