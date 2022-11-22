String? tableBranch = 'tb_branch';

class BranchFields {
  static List<String> values = [
    branchID,
    name,
    address,
    phone,
    ipay_merchant_code,
    ipay_merchant_key
  ];

  static String branchID = 'branchID';
  static String name = 'name';
  static String address = 'address';
  static String phone = 'phone';
  static String ipay_merchant_code = 'ipay_merchant_code';
  static String ipay_merchant_key = 'ipay_merchant_key';
}

class Branch {
  int? branchID;
  String? name;
  String? address;
  String? phone;
  String? ipay_merchant_code;
  String? ipay_merchant_key;

  Branch(
      {this.branchID,
      this.name,
      this.address,
      this.phone,
      this.ipay_merchant_code,
      this.ipay_merchant_key});

  Branch copy({int? branchID, String? name}) => Branch(
      branchID: branchID ?? this.branchID,
      name: name ?? this.name,
      address: address ?? this.address,
      phone: phone ?? this.phone,
      ipay_merchant_code: ipay_merchant_code ?? this.ipay_merchant_code,
      ipay_merchant_key: ipay_merchant_key ?? this.ipay_merchant_key);

  factory Branch.fromJson(Map<String, dynamic> json) {
    return Branch(
      branchID: json['branch_id'],
      name: json['name'] as String,
      address: json['address'] as String,
      phone: json['phone'] as String,
      ipay_merchant_code: json['ipay_merchant_code'] as String,
      ipay_merchant_key: json['ipay_merchant_key'] as String,
    );
  }

  Map<String, Object?> toJson() => {
        BranchFields.branchID: branchID,
        BranchFields.name: name,
        BranchFields.address: address,
        BranchFields.phone: phone,
        BranchFields.ipay_merchant_code: ipay_merchant_code,
        BranchFields.ipay_merchant_key: ipay_merchant_key,
      };
}
