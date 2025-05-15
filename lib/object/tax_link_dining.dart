String? tableTaxLinkDining = 'tb_tax_link_dining ';

class TaxLinkDiningFields {
  static List<String> values = [
    tax_link_dining_id,
    tax_id,
    dining_id,
    created_at,
    updated_at,
    soft_delete,
    tax_name,
    tax_rate,
    tax_amount
  ];

  static String tax_link_dining_id = 'tax_link_dining_id';
  static String tax_id = 'tax_id';
  static String dining_id = 'dining_id';
  static String created_at = 'created_at';
  static String updated_at = 'updated_at';
  static String soft_delete = 'soft_delete';
  static String tax_name = 'tax_name';
  static String tax_rate = 'tax_rate';
  static String tax_amount = 'tax_amount';
  static String tax_type = 'tax_type';
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
  int? specific_category;
  String? multiple_category;
  String? tax_amount;
  int? tax_type;

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
        this.specific_category,
        this.multiple_category,
        this.tax_amount,
        this.tax_type
      });

  TaxLinkDining copy({
    int? tax_link_dining_id,
    String? tax_id,
    String? dining_id,
    String? created_at,
    String? updated_at,
    String? soft_delete,
    String? tax_rate,
    String? tax_name,
    String? tax_amount,
    int? tax_type
  }) =>
      TaxLinkDining(
        tax_link_dining_id: tax_link_dining_id ?? this.tax_link_dining_id,
        tax_id: tax_id ?? this.tax_id,
        dining_id: dining_id ?? this.dining_id,
        created_at: created_at ?? this.created_at,
        updated_at: updated_at ?? this.updated_at,
        soft_delete: soft_delete ?? this.soft_delete,
        tax_rate: tax_rate ?? this.tax_rate,
        tax_name: tax_name ?? this.tax_name,
        tax_amount: tax_amount ?? this.tax_amount,
        tax_type: tax_type ?? this.tax_type
      );

  static TaxLinkDining fromJson(Map<String, Object?> json) => TaxLinkDining (
    tax_link_dining_id: json[TaxLinkDiningFields.tax_link_dining_id] as int?,
    tax_id: json[TaxLinkDiningFields.tax_id] as String?,
    dining_id: json[TaxLinkDiningFields.dining_id] as String?,
    created_at: json[TaxLinkDiningFields.created_at] as String?,
    updated_at: json[TaxLinkDiningFields.updated_at] as String?,
    soft_delete: json[TaxLinkDiningFields .soft_delete] as String?,
    tax_rate: json[TaxLinkDiningFields.tax_rate] as String?,
    tax_name: json[TaxLinkDiningFields.tax_name] as String?,
    dining_name: json['dining_name'] as String?,
    specific_category: json['specific_category'] as int?,
    multiple_category: json['multiple_category'] as String?,
    tax_amount: json[TaxLinkDiningFields.tax_amount] as String?,
    tax_type: json[TaxLinkDiningFields.tax_type] as int?
  );

  Map<String, Object?> toJson() => {
    TaxLinkDiningFields.tax_link_dining_id: tax_link_dining_id,
    TaxLinkDiningFields.tax_id: tax_id,
    TaxLinkDiningFields.dining_id: dining_id,
    TaxLinkDiningFields.created_at: created_at,
    TaxLinkDiningFields.updated_at: updated_at,
    TaxLinkDiningFields.soft_delete: soft_delete,
    TaxLinkDiningFields.tax_rate: tax_rate,
    TaxLinkDiningFields.tax_name: tax_name,
    TaxLinkDiningFields.tax_amount: tax_amount,
    TaxLinkDiningFields.tax_type: tax_type,
    'dining_name': dining_name,
    'specific_category': specific_category,
    'multiple_category': multiple_category,
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
