String? tableBranch = 'tb_branch';

class BranchFields {
  static List<String> values = [
    branchID,
    branch_url,
    name,
    address,
    phone,
    email,
    ipay_merchant_code,
    ipay_merchant_key,
    notification_token
  ];

  static String branchID = 'branchID';
  static String branch_url = 'branch_url';
  static String name = 'name';
  static String address = 'address';
  static String phone = 'phone';
  static String email = 'email';
  static String ipay_merchant_code = 'ipay_merchant_code';
  static String ipay_merchant_key = 'ipay_merchant_key';
  static String notification_token = 'notification_token';
}

class Branch {
  int? branchID;
  String? branch_url;
  String? name;
  String? address;
  String? phone;
  String? email;
  String? ipay_merchant_code;
  String? ipay_merchant_key;
  String? notification_token;

  Branch(
      {this.branchID,
      this.branch_url,
      this.name,
      this.address,
      this.phone,
      this.email,
      this.ipay_merchant_code,
      this.ipay_merchant_key,
      this.notification_token});

  Branch copy({int? branchID, String? name}) => Branch(
      branchID: branchID ?? this.branchID,
      branch_url: branch_url ?? this.branch_url,
      name: name ?? this.name,
      address: address ?? this.address,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      ipay_merchant_code: ipay_merchant_code ?? this.ipay_merchant_code,
      ipay_merchant_key: ipay_merchant_key ?? this.ipay_merchant_key,
      notification_token: notification_token ?? this.notification_token);

  factory Branch.fromJson(Map<String, dynamic> json) {
    return Branch(
      branchID: json['branch_id'],
      branch_url: json['branch_url'],
      name: json['name'] as String,
      address: json['address'] as String,
      phone: json['phone'] as String,
      email: json['email'] as String,
      ipay_merchant_code: json['ipay_merchant_code'] as String,
      ipay_merchant_key: json['ipay_merchant_key'] as String,
      notification_token: json['notification_token'] as String,
    );
  }

  Map<String, Object?> toJson() => {
        BranchFields.branchID: branchID,
        BranchFields.branch_url: branch_url,
        BranchFields.name: name,
        BranchFields.address: address,
        BranchFields.phone: phone,
        BranchFields.email: email,
        BranchFields.ipay_merchant_code: ipay_merchant_code,
        BranchFields.ipay_merchant_key: ipay_merchant_key,
        BranchFields.notification_token : notification_token
      };
}
