String? tableBranchLinkUser = 'tb_branch_link_user ';

class BranchLinkUserFields {
  static List<String> values = [
    branch_link_user_id,
    branch_id,
    user_id,
    created_at,
    updated_at,
    soft_delete
  ];

  static String branch_link_user_id = 'branch_link_user_id';
  static String branch_id = 'branch_id';
  static String user_id = 'user_id';
  static String created_at = 'created_at';
  static String updated_at = 'updated_at';
  static String soft_delete = 'soft_delete';
}

class BranchLinkUser{
  int? branch_link_user_id;
  String? branch_id;
  String? user_id;
  String? created_at;
  String? updated_at;
  String? soft_delete;

  BranchLinkUser(
      {this.branch_link_user_id,
        this.branch_id,
        this.user_id,
        this.created_at,
        this.updated_at,
        this.soft_delete});

  BranchLinkUser copy({
    int? branch_link_user_id,
    String? branch_id,
    String? user_id,
    String? created_at,
    String? updated_at,
    String? soft_delete,
  }) =>
      BranchLinkUser(
          branch_link_user_id: branch_link_user_id ?? this.branch_link_user_id,
          branch_id: branch_id ?? this.branch_id,
          user_id: user_id ?? this.user_id,
          created_at: created_at ?? this.created_at,
          updated_at: updated_at ?? this.updated_at,
          soft_delete: soft_delete ?? this.soft_delete);

  static BranchLinkUser fromJson(Map<String, Object?> json) => BranchLinkUser  (
    branch_link_user_id: json[BranchLinkUserFields.branch_link_user_id] as int?,
    branch_id: json[BranchLinkUserFields.branch_id] as String?,
    user_id: json[BranchLinkUserFields.user_id] as String?,
    created_at: json[BranchLinkUserFields.created_at] as String?,
    updated_at: json[BranchLinkUserFields.updated_at] as String?,
    soft_delete: json[BranchLinkUserFields .soft_delete] as String?,
  );

  Map<String, Object?> toJson() => {
    BranchLinkUserFields.branch_link_user_id: branch_link_user_id,
    BranchLinkUserFields.branch_id: branch_id,
    BranchLinkUserFields.user_id: user_id,
    BranchLinkUserFields.created_at: created_at,
    BranchLinkUserFields.updated_at: updated_at,
    BranchLinkUserFields.soft_delete: soft_delete,
  };
}
