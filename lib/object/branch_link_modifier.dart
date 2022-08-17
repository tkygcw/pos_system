String? tableBranchLinkModifier = 'tb_branch_link_modifier';

class BranchLinkModifierFields {
  static List<String> values = [
    branch_link_modifier_id,
    branch_id,
    mod_group_id,
    mod_item_id,
    name,
    price,
    sequence,
    status,
    created_at,
    updated_at,
    soft_delete
  ];

  static String branch_link_modifier_id = 'branch_link_modifier_id';
  static String branch_id = 'branch_id';
  static String mod_group_id = 'mod_group_id';
  static String mod_item_id = 'mod_item_id';
  static String name = 'name';
  static String price = 'price';
  static String sequence = 'sequence';
  static String status = 'status';
  static String created_at = 'created_at';
  static String updated_at = 'updated_at';
  static String soft_delete = 'soft_delete';
}

class BranchLinkModifier {
  int? branch_link_modifier_id;
  String? branch_id;
  String? mod_group_id;
  String? mod_item_id;
  String? name;
  String? price;
  int? sequence;
  String? status;
  String? created_at;
  String? updated_at;
  String? soft_delete;

  BranchLinkModifier(
      {this.branch_link_modifier_id,
      this.branch_id,
      this.mod_group_id,
      this.mod_item_id,
      this.name,
      this.price,
      this.sequence,
      this.status,
      this.created_at,
      this.updated_at,
      this.soft_delete});

  BranchLinkModifier copy({
    int? branch_link_modifier_id,
    String? branch_id,
    String? mod_group_id,
    String? mod_item_id,
    String? name,
    String? price,
    int? sequence,
    String? status,
    String? created_at,
    String? updated_at,
    String? soft_delete,
  }) =>
      BranchLinkModifier(
          branch_link_modifier_id:
              branch_link_modifier_id ?? this.branch_link_modifier_id,
          branch_id: branch_id ?? this.branch_id,
          mod_group_id: mod_group_id ?? this.mod_group_id,
          mod_item_id: mod_item_id ?? this.mod_item_id,
          name: name ?? this.name,
          price: price ?? this.price,
          sequence: sequence ?? this.sequence,
          status: status ?? this.status,
          created_at: created_at ?? this.created_at,
          updated_at: updated_at ?? this.updated_at,
          soft_delete: soft_delete ?? this.soft_delete);

  static BranchLinkModifier fromJson(Map<String, Object?> json) =>
      BranchLinkModifier(
        branch_link_modifier_id:
            json[BranchLinkModifierFields.branch_link_modifier_id] as int?,
        branch_id: json[BranchLinkModifierFields.branch_id] as String?,
        mod_group_id: json[BranchLinkModifierFields.mod_group_id] as String?,
        mod_item_id: json[BranchLinkModifierFields.mod_item_id] as String?,
        name: json[BranchLinkModifierFields.name] as String?,
        price: json[BranchLinkModifierFields.price] as String?,
        sequence: json[BranchLinkModifierFields.sequence] as int?,
        status: json[BranchLinkModifierFields.status] as String?,
        created_at: json[BranchLinkModifierFields.created_at] as String?,
        updated_at: json[BranchLinkModifierFields.updated_at] as String?,
        soft_delete: json[BranchLinkModifierFields.soft_delete] as String?,
      );

  Map<String, Object?> toJson() => {
        BranchLinkModifierFields.branch_link_modifier_id:
            branch_link_modifier_id,
        BranchLinkModifierFields.branch_id: branch_id,
        BranchLinkModifierFields.mod_group_id: mod_group_id,
        BranchLinkModifierFields.mod_item_id: mod_item_id,
        BranchLinkModifierFields.name: name,
        BranchLinkModifierFields.price: price,
        BranchLinkModifierFields.sequence: sequence,
        BranchLinkModifierFields.status: status,
        BranchLinkModifierFields.created_at: created_at,
        BranchLinkModifierFields.updated_at: updated_at,
        BranchLinkModifierFields.soft_delete: soft_delete,
      };
}
