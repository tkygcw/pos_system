String? tableBranchLinkPromotion = 'tb_branch_link_promotion';

class BranchLinkPromotionFields {
  static List<String> values = [
    branch_link_promotion_id,
    branch_id,
    promotion_id,
    created_at,
    updated_at,
    soft_delete
  ];

  static String branch_link_promotion_id = 'branch_link_promotion_id';
  static String branch_id = 'branch_id';
  static String promotion_id = 'promotion_id';
  static String created_at = 'created_at';
  static String updated_at = 'updated_at';
  static String soft_delete = 'soft_delete';
}

class BranchLinkPromotion {
  int? branch_link_promotion_id;
  String? branch_id;
  String? promotion_id;
  String? created_at;
  String? updated_at;
  String? soft_delete;
  String? name;

  BranchLinkPromotion(
      {this.branch_link_promotion_id,
      this.branch_id,
      this.promotion_id,
      this.created_at,
      this.updated_at,
      this.soft_delete,
      this.name});

  BranchLinkPromotion copy({
    int? branch_link_promotion_id,
    String? branch_id,
    String? promotion_id,
    String? created_at,
    String? updated_at,
    String? soft_delete,
  }) =>
      BranchLinkPromotion(
          branch_link_promotion_id:
              branch_link_promotion_id ?? this.branch_link_promotion_id,
          branch_id: branch_id ?? this.branch_id,
          promotion_id: promotion_id ?? this.promotion_id,
          created_at: created_at ?? this.created_at,
          updated_at: updated_at ?? this.updated_at,
          soft_delete: soft_delete ?? this.soft_delete,
          name: name ?? this.name);

  static BranchLinkPromotion fromJson(Map<String, Object?> json) =>
      BranchLinkPromotion(
        branch_link_promotion_id:
            json[BranchLinkPromotionFields.branch_link_promotion_id] as int?,
        branch_id: json[BranchLinkPromotionFields.branch_id] as String?,
        promotion_id: json[BranchLinkPromotionFields.promotion_id] as String?,
        created_at: json[BranchLinkPromotionFields.created_at] as String?,
        updated_at: json[BranchLinkPromotionFields.updated_at] as String?,
        soft_delete: json[BranchLinkPromotionFields.soft_delete] as String?,
        name: json['name'] as String?,
      );

  Map<String, Object?> toJson() => {
        BranchLinkPromotionFields.branch_link_promotion_id:
            branch_link_promotion_id,
        BranchLinkPromotionFields.branch_id: branch_id,
        BranchLinkPromotionFields.promotion_id: promotion_id,
        BranchLinkPromotionFields.created_at: created_at,
        BranchLinkPromotionFields.updated_at: updated_at,
        BranchLinkPromotionFields.soft_delete: soft_delete,
      };
}
