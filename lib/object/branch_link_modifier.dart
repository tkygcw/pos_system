String? tableBranchLinkModifier = 'tb_branch_link_modifier';

class BranchLinkModifierFields {
  static List<String> values = [
    branch_link_modifier_id,
    branch_id,
    mod_group_id,
    mod_item_id,
    name,
    price,
    stock_type,
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
  static String stock_type = 'stock_type';
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
  int? stock_type;
  int? sequence;
  String? status;
  String? created_at;
  String? updated_at;
  String? soft_delete;
  double? net_sales;
  int? item_sum;

  BranchLinkModifier(
      {this.branch_link_modifier_id,
      this.branch_id,
      this.mod_group_id,
      this.mod_item_id,
      this.name,
      this.price,
      this.stock_type,
      this.sequence,
      this.status,
      this.created_at,
      this.updated_at,
      this.soft_delete,
      this.net_sales,
      this.item_sum});

  BranchLinkModifier copy({
    int? branch_link_modifier_id,
    String? branch_id,
    String? mod_group_id,
    String? mod_item_id,
    String? name,
    String? price,
    int? stock_type,
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
          stock_type: stock_type ?? this.stock_type,
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
          stock_type: json[BranchLinkModifierFields.stock_type] as int?,
        sequence: json[BranchLinkModifierFields.sequence] as int?,
        status: json[BranchLinkModifierFields.status] as String?,
        created_at: json[BranchLinkModifierFields.created_at] as String?,
        updated_at: json[BranchLinkModifierFields.updated_at] as String?,
        soft_delete: json[BranchLinkModifierFields.soft_delete] as String?,
        net_sales: json['net_sales'] as double?,
        item_sum: json['item_sum'] as int?
      );

  Map<String, Object?> toJson() => {
        BranchLinkModifierFields.branch_link_modifier_id:
            branch_link_modifier_id,
        BranchLinkModifierFields.branch_id: branch_id,
        BranchLinkModifierFields.mod_group_id: mod_group_id,
        BranchLinkModifierFields.mod_item_id: mod_item_id,
        BranchLinkModifierFields.name: name,
        BranchLinkModifierFields.price: price,
        BranchLinkModifierFields.stock_type: stock_type,
        BranchLinkModifierFields.sequence: sequence,
        BranchLinkModifierFields.status: status,
        BranchLinkModifierFields.created_at: created_at,
        BranchLinkModifierFields.updated_at: updated_at,
        BranchLinkModifierFields.soft_delete: soft_delete,
      };
}
