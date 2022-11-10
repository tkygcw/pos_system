String? tableTax = 'tb_tax ';

class TaxFields {
  static List<String> values = [
    tax_id,
    company_id,
    name,
    tax_rate,
    created_at,
    updated_at,
    soft_delete
  ];

  static String tax_id = 'tax_id';
  static String company_id = 'company_id';
  static String name = 'name';
  static String tax_rate = 'tax_rate';
  static String created_at = 'created_at';
  static String updated_at = 'updated_at';
  static String soft_delete = 'soft_delete';
}

class Tax{
  int? tax_id;
  String? company_id;
  String? name;
  String? tax_rate;
  String? created_at;
  String? updated_at;
  String? soft_delete;
  double? tax_amount;

  Tax(
      {this.tax_id,
        this.company_id,
        this.name,
        this.tax_rate,
        this.created_at,
        this.updated_at,
        this.soft_delete,
        this.tax_amount});

  Tax copy({
    int? tax_id,
    String? company_id,
    String? name,
    String? tax_rate,
    String? created_at,
    String? updated_at,
    String? soft_delete,
  }) =>
      Tax(
          tax_id: tax_id ?? this.tax_id,
          company_id: company_id ?? this.company_id,
          name: name ?? this.name,
          tax_rate: tax_rate ?? this.tax_rate,
          created_at: created_at ?? this.created_at,
          updated_at: updated_at ?? this.updated_at,
          soft_delete: soft_delete ?? this.soft_delete);

  static Tax fromJson(Map<String, Object?> json) => Tax  (
    tax_id: json[TaxFields.tax_id] as int?,
    company_id: json[TaxFields.company_id] as String?,
    name: json[TaxFields.name] as String?,
    tax_rate: json[TaxFields.tax_rate] as String?,
    created_at: json[TaxFields.created_at] as String?,
    updated_at: json[TaxFields.updated_at] as String?,
    soft_delete: json[TaxFields .soft_delete] as String?,
  );

  Map<String, Object?> toJson() => {
    TaxFields.tax_id: tax_id,
    TaxFields.company_id: company_id,
    TaxFields.name: name,
    TaxFields.tax_rate: tax_rate,
    TaxFields.created_at: created_at,
    TaxFields.updated_at: updated_at,
    TaxFields.soft_delete: soft_delete,
  };
}
