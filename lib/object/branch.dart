String? tableBranch = 'tb_branch';

class BranchFields {
  static List<String> values = [
    branchID,
    name,
    ipay_merchant_code,
    ipay_merchant_key
  ];

  static String branchID = 'branchID';
  static String name = 'name';
  static String ipay_merchant_code = 'ipay_merchant_code';
  static String ipay_merchant_key = 'ipay_merchant_key';
}

class Branch {
  int? branchID;
  String? name;
  String? ipay_merchant_code;
  String? ipay_merchant_key;

  Branch(
      {this.branchID,
      this.name,
      this.ipay_merchant_code,
      this.ipay_merchant_key});

  Branch copy({int? branchID, String? name}) => Branch(
      branchID: branchID ?? this.branchID,
      name: name ?? this.name,
      ipay_merchant_code: ipay_merchant_code ?? this.ipay_merchant_code,
      ipay_merchant_key: ipay_merchant_key ?? this.ipay_merchant_key);

  factory Branch.fromJson(Map<String, dynamic> json) {
    return Branch(
      branchID: json['branch_id'],
      name: json['name'] as String,
      ipay_merchant_code: json['ipay_merchant_code'] as String,
      ipay_merchant_key: json['ipay_merchant_key'] as String,
    );
  }

  Map<String, Object?> toJson() => {
        BranchFields.branchID: branchID,
        BranchFields.name: name,
        BranchFields.ipay_merchant_code: ipay_merchant_code,
        BranchFields.ipay_merchant_key: ipay_merchant_key,
      };
}
