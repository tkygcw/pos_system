String? tableTaxLinkDining = 'tb_tax_link_dining ';

class TaxLinkDiningFields {
  static List<String> values = [
    tax_link_dining_id,
    tax_id,
    dining_id,
    created_at,
    updated_at,
    soft_delete
  ];

  static String tax_link_dining_id = 'tax_link_dining_id';
  static String tax_id = 'tax_id';
  static String dining_id = 'dining_id';
  static String created_at = 'created_at';
  static String updated_at = 'updated_at';
  static String soft_delete = 'soft_delete';
}

class TaxLinkDining{
  int? tax_link_dining_id;
  String? tax_id;
  String? dining_id;
  String? created_at;
  String? updated_at;
  String? soft_delete;
  String? tax_rate;
  String? tax_name;
  String? dining_name;

  TaxLinkDining(
      {this.tax_link_dining_id,
        this.tax_id,
        this.dining_id,
        this.created_at,
        this.updated_at,
        this.soft_delete,
        this.tax_rate,
        this.tax_name,
        this.dining_name,
      });

  TaxLinkDining copy({
    int? tax_link_dining_id,
    String? tax_id,
    String? dining_id,
    String? created_at,
    String? updated_at,
    String? soft_delete,
    String? tax_rate,
  }) =>
      TaxLinkDining(
          tax_link_dining_id: tax_link_dining_id ?? this.tax_link_dining_id,
          tax_id: tax_id ?? this.tax_id,
          dining_id: dining_id ?? this.dining_id,
          created_at: created_at ?? this.created_at,
          updated_at: updated_at ?? this.updated_at,
          soft_delete: soft_delete ?? this.soft_delete,
          tax_rate: tax_rate ?? this.tax_rate);

  static TaxLinkDining fromJson(Map<String, Object?> json) => TaxLinkDining (
    tax_link_dining_id: json[TaxLinkDiningFields.tax_link_dining_id] as int?,
    tax_id: json[TaxLinkDiningFields.tax_id] as String?,
    dining_id: json[TaxLinkDiningFields.dining_id] as String?,
    created_at: json[TaxLinkDiningFields.created_at] as String?,
    updated_at: json[TaxLinkDiningFields.updated_at] as String?,
    soft_delete: json[TaxLinkDiningFields .soft_delete] as String?,
    tax_rate: json['tax_rate'] as String?,
    tax_name: json['tax_name'] as String?,
    dining_name: json['dining_name'] as String?
  );

  Map<String, Object?> toJson() => {
    TaxLinkDiningFields.tax_link_dining_id: tax_link_dining_id,
    TaxLinkDiningFields.tax_id: tax_id,
    TaxLinkDiningFields.dining_id: dining_id,
    TaxLinkDiningFields.created_at: created_at,
    TaxLinkDiningFields.updated_at: updated_at,
    TaxLinkDiningFields.soft_delete: soft_delete,
    'tax_rate': tax_rate,
    'tax_name': tax_name,
    'dining_name': dining_name
  };

  Map<String, Object?> toInsertJson() => {
    TaxLinkDiningFields.tax_link_dining_id: tax_link_dining_id,
    TaxLinkDiningFields.tax_id: tax_id,
    TaxLinkDiningFields.dining_id: dining_id,
    TaxLinkDiningFields.created_at: created_at,
    TaxLinkDiningFields.updated_at: updated_at,
    TaxLinkDiningFields.soft_delete: soft_delete,
  };
}
