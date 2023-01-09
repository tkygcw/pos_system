String? tableBranchLinkTax = 'tb_branch_link_tax';

class BranchLinkTaxFields {
  static List<String> values = [
    branch_link_tax_id,
    branch_id,
    tax_id,
    created_at,
    updated_at,
    soft_delete
  ];

  static String branch_link_tax_id = 'branch_link_tax_id';
  static String branch_id = 'branch_id';
  static String tax_id = 'tax_id';
  static String created_at = 'created_at';
  static String updated_at = 'updated_at';
  static String soft_delete = 'soft_delete';
}

class BranchLinkTax {
  int? branch_link_tax_id;
  String? branch_id;
  String? tax_id;
  String? created_at;
  String? updated_at;
  String? soft_delete;
  String? tax_name;
  double total_amount = 0.0;

  BranchLinkTax(
      {this.branch_link_tax_id,
        this.branch_id,
        this.tax_id,
        this.created_at,
        this.updated_at,
        this.soft_delete,
        this.tax_name});

  BranchLinkTax copy({
    int? branch_link_tax_id,
    String? branch_id,
    String? tax_id,
    String? created_at,
    String? updated_at,
    String? soft_delete,
  }) =>
      BranchLinkTax(
          branch_link_tax_id:
          branch_link_tax_id ?? this.branch_link_tax_id,
          branch_id: branch_id ?? this.branch_id,
          tax_id: tax_id ?? this.tax_id,
          created_at: created_at ?? this.created_at,
          updated_at: updated_at ?? this.updated_at,
          soft_delete: soft_delete ?? this.soft_delete);

  static BranchLinkTax fromJson(Map<String, Object?> json) =>
      BranchLinkTax(
        branch_link_tax_id:
        json[BranchLinkTaxFields.branch_link_tax_id] as int?,
        branch_id: json[BranchLinkTaxFields.branch_id] as String?,
        tax_id: json[BranchLinkTaxFields.tax_id] as String?,
        created_at: json[BranchLinkTaxFields.created_at] as String?,
        updated_at: json[BranchLinkTaxFields.updated_at] as String?,
        soft_delete: json[BranchLinkTaxFields.soft_delete] as String?,
        tax_name: json['name'] as String?
      );

  Map<String, Object?> toJson() => {
    BranchLinkTaxFields.branch_link_tax_id: branch_link_tax_id,
    BranchLinkTaxFields.branch_id: branch_id,
    BranchLinkTaxFields.tax_id: tax_id,
    BranchLinkTaxFields.created_at: created_at,
    BranchLinkTaxFields.updated_at: updated_at,
    BranchLinkTaxFields.soft_delete: soft_delete,
  };
}
