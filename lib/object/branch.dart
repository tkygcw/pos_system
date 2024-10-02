String? tableBranch = 'tb_branch';

class BranchFields {
  static List<String> values = [
    branch_id,
    branch_url,
    name,
    address,
    phone,
    email,
    ipay_merchant_code,
    ipay_merchant_key,
    notification_token,
    qr_order_status,
    sub_pos_status,
    attendance_status,
    company_id,
    working_day,
    working_time,
  ];

  static String branch_id = 'branch_id';
  static String branch_url = 'branch_url';
  static String name = 'name';
  static String address = 'address';
  static String phone = 'phone';
  static String email = 'email';
  static String ipay_merchant_code = 'ipay_merchant_code';
  static String ipay_merchant_key = 'ipay_merchant_key';
  static String notification_token = 'notification_token';
  static String qr_order_status = 'qr_order_status';
  static String sub_pos_status = 'sub_pos_status';
  static String attendance_status = 'attendance_status';
  static String company_id = 'company_id';
  static String working_day = 'working_day';
  static String working_time = 'working_time';
}

class Branch {
  int? branch_id;
  String? branch_url;
  String? name;
  String? address;
  String? phone;
  String? email;
  String? ipay_merchant_code;
  String? ipay_merchant_key;
  String? notification_token;
  String? qr_order_status;
  int? sub_pos_status;
  int? attendance_status;
  String? company_id;
  String? working_day;
  String? working_time;

  Branch(
      {this.branch_id,
      this.branch_url,
      this.name,
      this.address,
      this.phone,
      this.email,
      this.ipay_merchant_code,
      this.ipay_merchant_key,
      this.notification_token,
      this.qr_order_status,
      this.sub_pos_status,
      this.attendance_status,
      this.company_id,
      this.working_day,
      this.working_time
      });

  Branch copy({int? branch_id, String? name}) => Branch(
    branch_id: branch_id ?? this.branch_id,
    branch_url: branch_url ?? this.branch_url,
    name: name ?? this.name,
    address: address ?? this.address,
    phone: phone ?? this.phone,
    email: email ?? this.email,
    ipay_merchant_code: ipay_merchant_code ?? this.ipay_merchant_code,
    ipay_merchant_key: ipay_merchant_key ?? this.ipay_merchant_key,
    notification_token: notification_token ?? this.notification_token,
    qr_order_status: qr_order_status ?? this.qr_order_status,
    sub_pos_status: sub_pos_status ?? this.sub_pos_status,
    attendance_status: attendance_status ?? this.attendance_status,
    company_id: company_id ?? this.company_id,
    working_day: working_day ?? this.working_day,
    working_time: working_time ?? this.working_time
  );

  factory Branch.fromJson(Map<String, dynamic> json) {
    return Branch(
      branch_id: json['branch_id'],
      branch_url: json['branch_url'],
      name: json['name'] as String,
      address: json['address'] as String,
      phone: json['phone'] as String,
      email: json['email'] as String,
      ipay_merchant_code: json['ipay_merchant_code'] as String,
      ipay_merchant_key: json['ipay_merchant_key'] as String,
      notification_token: json['notification_token'] as String,
      qr_order_status: json['qr_order_status'] as String?,
      sub_pos_status: json['sub_pos_status'] as int?,
      attendance_status: json['attendance_status'] as int?,
      company_id: json[BranchFields.company_id] as String?,
      working_day: json[BranchFields.working_day] as String?,
      working_time: json[BranchFields.working_time] as String?
    );
  }

  Map<String, Object?> toJson() => {
    BranchFields.branch_id: branch_id,
    BranchFields.branch_url: branch_url,
    BranchFields.name: name,
    BranchFields.address: address,
    BranchFields.phone: phone,
    BranchFields.email: email,
    BranchFields.ipay_merchant_code: ipay_merchant_code,
    BranchFields.ipay_merchant_key: ipay_merchant_key,
    BranchFields.notification_token: notification_token,
    BranchFields.qr_order_status: qr_order_status,
    BranchFields.sub_pos_status: sub_pos_status,
    BranchFields.attendance_status: attendance_status,
    BranchFields.company_id: company_id,
    BranchFields.working_day: working_day,
    BranchFields.working_time: working_time
  };
}
