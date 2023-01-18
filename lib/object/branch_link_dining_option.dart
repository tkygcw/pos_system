String? tableBranchLinkDining = 'tb_branch_link_dining_option';

class BranchLinkDiningFields {
  static List<String> values = [
    branch_link_dining_id,
    branch_id,
    dining_id,
    is_default,
    sequence,
    created_at,
    updated_at,
    soft_delete
  ];

  static String branch_link_dining_id = 'branch_link_dining_id';
  static String branch_id = 'branch_id';
  static String dining_id = 'dining_id';
  static String is_default = 'is_default';
  static String sequence = 'sequence';
  static String created_at = 'created_at';
  static String updated_at = 'updated_at';
  static String soft_delete = 'soft_delete';
}

class BranchLinkDining {
  int? branch_link_dining_id;
  String? branch_id;
  String? dining_id;
  int? is_default;
  String? sequence;
  String? created_at;
  String? updated_at;
  String? soft_delete;
  String? name;
  int? total_bill;

  BranchLinkDining(
      {this.branch_link_dining_id,
      this.branch_id,
      this.dining_id,
      this.is_default,
      this.sequence,
      this.created_at,
      this.updated_at,
      this.soft_delete,
      this.name,
      this.total_bill});

  BranchLinkDining copy({
    int? branch_link_dining_id,
    String? branch_id,
    String? dining_id,
    int? is_default,
    String? sequence,
    String? created_at,
    String? updated_at,
    String? soft_delete,
    String? name,
  }) =>
      BranchLinkDining(
          branch_link_dining_id:
              branch_link_dining_id ?? this.branch_link_dining_id,
          branch_id: branch_id ?? this.branch_id,
          dining_id: dining_id ?? this.dining_id,
          is_default: is_default ?? this.is_default,
          sequence: sequence ?? this.sequence,
          created_at: created_at ?? this.created_at,
          updated_at: updated_at ?? this.updated_at,
          soft_delete: soft_delete ?? this.soft_delete,
          name: name ?? this.name);

  static BranchLinkDining fromJson(Map<String, Object?> json) =>
      BranchLinkDining(
        branch_link_dining_id:
            json[BranchLinkDiningFields.branch_link_dining_id] as int?,
        branch_id: json[BranchLinkDiningFields.branch_id] as String?,
        dining_id: json[BranchLinkDiningFields.dining_id] as String?,
        is_default: json[BranchLinkDiningFields.is_default] as int?,
        sequence: json[BranchLinkDiningFields.sequence] as String?,
        created_at: json[BranchLinkDiningFields.created_at] as String?,
        updated_at: json[BranchLinkDiningFields.updated_at] as String?,
        soft_delete: json[BranchLinkDiningFields.soft_delete] as String?,
        name: json['name'] as String?,
      );

  Map<String, Object?> toJson() => {
        BranchLinkDiningFields.branch_link_dining_id: branch_link_dining_id,
        BranchLinkDiningFields.branch_id: branch_id,
        BranchLinkDiningFields.dining_id: dining_id,
        BranchLinkDiningFields.is_default: is_default,
        BranchLinkDiningFields.sequence: sequence,
        BranchLinkDiningFields.created_at: created_at,
        BranchLinkDiningFields.updated_at: updated_at,
        BranchLinkDiningFields.soft_delete: soft_delete,
      };
}
