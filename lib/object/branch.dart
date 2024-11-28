String? tableBranch = 'tb_branch';

class BranchFields {
  static List<String> values = [
    branch_id,
    branch_url,
    name,
    logo,
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
    close_qr_order,
    register_no,
    allow_firestore,
    qr_show_sku,
    qr_product_sequence,
    show_qr_history
  ];

  static String branch_id = 'branch_id';
  static String branch_url = 'branch_url';
  static String name = 'name';
  static String logo = 'logo';
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
  static String close_qr_order = 'close_qr_order';
  static String register_no = 'register_no';
  static String allow_firestore = 'allow_firestore';
  static String qr_show_sku = 'qr_show_sku';
  static String qr_product_sequence = 'qr_product_sequence';
  static String show_qr_history = 'show_qr_history';
  static String firestore_db_version = 'firestore_db_version';
}

class Branch {
  int? branch_id;
  String? branch_url;
  String? name;
  String? logo;
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
  int? close_qr_order;
  String? register_no;
  int? allow_firestore;
  int? qr_show_sku;
  int? qr_product_sequence;
  String? show_qr_history;
  int? firestore_db_version;

  Branch({
    this.branch_id,
    this.branch_url,
    this.name,
    this.logo,
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
    this.working_time,
    this.close_qr_order,
    this.register_no,
    this.allow_firestore,
    this.qr_show_sku,
    this.qr_product_sequence,
    this.show_qr_history,
    this.firestore_db_version
  });

  Branch copy({int? branch_id, String? name}) => Branch(
    branch_id: branch_id ?? this.branch_id,
    branch_url: branch_url ?? this.branch_url,
    name: name ?? this.name,
    logo: logo ?? this.logo,
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
    working_time: working_time ?? this.working_time,
    close_qr_order: close_qr_order ?? this.close_qr_order,
    register_no: register_no ?? this.register_no,
    allow_firestore: allow_firestore ?? this.allow_firestore,
    qr_show_sku: qr_show_sku ?? this.qr_show_sku,
    qr_product_sequence: qr_product_sequence ?? this.qr_product_sequence,
    show_qr_history: show_qr_history ?? this.show_qr_history
  );

  factory Branch.fromJson(Map<String, dynamic> json) {
    return Branch(
      branch_id: json['branch_id'],
      branch_url: json['branch_url'],
      name: json['name'] as String,
      logo: json['logo'] as String?,
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
      working_time: json[BranchFields.working_time] as String?,
      close_qr_order: json[BranchFields.close_qr_order] as int?,
      register_no: json[BranchFields.register_no] as String?,
      allow_firestore: json[BranchFields.allow_firestore] as int?,
      qr_show_sku: json[BranchFields.qr_show_sku] as int?,
      qr_product_sequence: json[BranchFields.qr_product_sequence] as int?,
      show_qr_history: json[BranchFields.show_qr_history] as String?,
      firestore_db_version: json[BranchFields.firestore_db_version] as int?
    );
  }

  Map<String, Object?> toJson() => {
    BranchFields.branch_id: branch_id,
    BranchFields.branch_url: branch_url,
    BranchFields.name: name,
    BranchFields.logo: logo,
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
    BranchFields.working_time: working_time,
    BranchFields.close_qr_order: close_qr_order,
    BranchFields.register_no: register_no,
    BranchFields.allow_firestore: allow_firestore,
    BranchFields.qr_show_sku: qr_show_sku,
    BranchFields.qr_product_sequence: qr_product_sequence,
    BranchFields.show_qr_history: show_qr_history
  };

  Map<String, Object?> toFirestoreJson() => {
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
    BranchFields.working_time: working_time,
    BranchFields.close_qr_order: close_qr_order,
    BranchFields.register_no: register_no,
    BranchFields.allow_firestore: allow_firestore,
    BranchFields.qr_show_sku: qr_show_sku,
    BranchFields.qr_product_sequence: qr_product_sequence,
    BranchFields.show_qr_history: show_qr_history,
    BranchFields.firestore_db_version: firestore_db_version
  };
}
