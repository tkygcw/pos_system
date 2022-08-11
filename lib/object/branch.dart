String? tableBranch = 'tb_branch';

class BranchFields {
  static List<String> values = [
    branchID,
    name,
  ];

  static String branchID = 'branchID';
  static String name = 'name';
}

class Branch {
  int? branchID;
  String? name;

  Branch({this.branchID, this.name});

  Branch copy({int? branchID, String? name}) =>
      Branch(branchID: branchID ?? this.branchID, name: name ?? this.name);

  factory Branch.fromJson(Map<String, dynamic> json) {
    return Branch(
      branchID: json['branch_id'],
      name: json['name'] as String,
    );
  }

  Map<String, Object?> toJson() => {
        BranchFields.branchID: branchID,
        BranchFields.name: name,
      };

}
