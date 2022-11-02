String? tablePaymentLinkCompany = 'tb_payment_link_company ';

class PaymentLinkCompanyFields {
  static List<String> values = [
    payment_link_company_id,
    payment_type_id,
    company_id,
    name,
    created_at,
    updated_at,
    soft_delete
  ];

  static String payment_link_company_id = 'payment_link_company_id';
  static String payment_type_id = 'payment_type_id';
  static String company_id = 'company_id';
  static String name = 'name';
  static String created_at = 'created_at';
  static String updated_at = 'updated_at';
  static String soft_delete = 'soft_delete';
}

class PaymentLinkCompany{
  int? payment_link_company_id;
  String? payment_type_id;
  String? company_id;
  String? name;
  String? created_at;
  String? updated_at;
  String? soft_delete;
  double  totalAmount = 0.0;

  PaymentLinkCompany(
      {this.payment_link_company_id,
        this.payment_type_id,
        this.company_id,
        this.name,
        this.created_at,
        this.updated_at,
        this.soft_delete,
      });

  PaymentLinkCompany copy({
    int? payment_link_company_id,
    String? payment_type_id,
    String? company_id,
    String? name,
    String? created_at,
    String? updated_at,
    String? soft_delete,
  }) =>
      PaymentLinkCompany(
          payment_link_company_id: payment_link_company_id ?? this.payment_link_company_id,
          payment_type_id: payment_type_id ?? this.payment_type_id,
          company_id: company_id ?? this.company_id,
          name: name ?? this.name,
          created_at: created_at ?? this.created_at,
          updated_at: updated_at ?? this.updated_at,
          soft_delete: soft_delete ?? this.soft_delete);

  static PaymentLinkCompany fromJson(Map<String, Object?> json) => PaymentLinkCompany(
    payment_link_company_id: json[PaymentLinkCompanyFields.payment_link_company_id] as int?,
    payment_type_id: json[PaymentLinkCompanyFields.payment_type_id] as String?,
    company_id: json[PaymentLinkCompanyFields.company_id] as String?,
    name: json[PaymentLinkCompanyFields.name] as String?,
    created_at: json[PaymentLinkCompanyFields.created_at] as String?,
    updated_at: json[PaymentLinkCompanyFields.updated_at] as String?,
    soft_delete: json[PaymentLinkCompanyFields.soft_delete] as String?,
  );

  Map<String, Object?> toJson() => {
    PaymentLinkCompanyFields.payment_link_company_id: payment_link_company_id,
    PaymentLinkCompanyFields.payment_type_id: payment_type_id,
    PaymentLinkCompanyFields.company_id: company_id,
    PaymentLinkCompanyFields.name: name,
    PaymentLinkCompanyFields.created_at: created_at,
    PaymentLinkCompanyFields.updated_at: updated_at,
    PaymentLinkCompanyFields.soft_delete: soft_delete,
  };
}
