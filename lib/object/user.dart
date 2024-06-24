String? tableUser = 'tb_user';

class UserFields {
  static List<String> values = [
    user_id,
    name,
    email,
    role,
    phone,
    pos_pin,
    edit_price_without_pin,
    refund_permission,
    cash_drawer_permission,
    settlement_permission,
    report_permission,
    status,
    created_at,
    updated_at,
    soft_delete
  ];

  static String user_id = 'user_id';
  static String name = 'name';
  static String email = 'email';
  static String role = 'role';
  static String phone = 'phone';
  static String pos_pin = 'pos_pin';
  static String edit_price_without_pin = 'edit_price_without_pin';
  static String refund_permission = 'refund_permission';
  static String cash_drawer_permission = 'cash_drawer_permission';
  static String settlement_permission = 'settlement_permission';
  static String report_permission = 'report_permission';
  static String status = 'status';
  static String created_at = 'created_at';
  static String updated_at = 'updated_at';
  static String soft_delete = 'soft_delete';
}

class User {
  int? user_id;
  String? name;
  String? email;
  int? role;
  String? phone;
  String? pos_pin;
  int? edit_price_without_pin;
  int? refund_permission;
  int? cash_drawer_permission;
  int? settlement_permission;
  int? report_permission;
  int? status;
  String? created_at;
  String? updated_at;
  String? soft_delete;
  String? clock_in_at;
  int? attendance_sqlite_id;

  User(
      {this.user_id,
      this.name,
      this.email,
      this.role,
      this.phone,
      this.pos_pin,
      this.edit_price_without_pin,
      this.refund_permission,
      this.cash_drawer_permission,
      this.settlement_permission,
      this.report_permission,
      this.status,
      this.created_at,
      this.updated_at,
      this.soft_delete,
      this.clock_in_at,
      this.attendance_sqlite_id});

  User copy({
    int? user_id,
    String? name,
    String? email,
    int? role,
    String? phone,
    String? pos_pin,
    int? edit_price_without_pin,
    int? refund_permission,
    int? cash_drawer_permission,
    int? settlement_permission,
    int? report_permission,
    int? status,
    String? created_at,
    String? updated_at,
    String? soft_delete,
  }) =>
      User(
          user_id: user_id ?? this.user_id,
          name: name ?? this.name,
          email: email ?? this.email,
          role: role ?? this.role,
          phone: phone ?? this.phone,
          pos_pin: pos_pin ?? this.pos_pin,
          edit_price_without_pin: edit_price_without_pin ?? this.edit_price_without_pin,
          refund_permission: refund_permission ?? this.refund_permission,
          cash_drawer_permission: cash_drawer_permission ?? this.cash_drawer_permission,
          settlement_permission: settlement_permission ?? this.settlement_permission,
          report_permission: report_permission ?? this.report_permission,
          status: status ?? this.status,
          created_at: created_at ?? this.created_at,
          updated_at: updated_at ?? this.updated_at,
          soft_delete: soft_delete ?? this.soft_delete);

  static User fromJson(Map<String, Object?> json) => User(
        user_id: json[UserFields.user_id] as int?,
        name: json[UserFields.name] as String?,
        email: json[UserFields.email] as String?,
        role: json[UserFields.role] as int?,
        phone: json[UserFields.phone] as String?,
        pos_pin: json[UserFields.pos_pin] as String?,
        edit_price_without_pin: json[UserFields.edit_price_without_pin] as int?,
        refund_permission: json[UserFields.refund_permission] as int?,
        cash_drawer_permission: json[UserFields.cash_drawer_permission] as int?,
        settlement_permission: json[UserFields.settlement_permission] as int?,
        report_permission: json[UserFields.report_permission] as int?,
        status: json[UserFields.status] as int?,
        created_at: json[UserFields.created_at] as String?,
        updated_at: json[UserFields.updated_at] as String?,
        soft_delete: json[UserFields.soft_delete] as String?,
        clock_in_at: json['clock_in_at'] as String?,
        attendance_sqlite_id: json['attendance_sqlite_id'] as int?,
      );

  Map<String, Object?> toJson() => {
        UserFields.user_id: user_id,
        UserFields.name: name,
        UserFields.email: email,
        UserFields.role: role,
        UserFields.phone: phone,
        UserFields.pos_pin: pos_pin,
        UserFields.edit_price_without_pin: edit_price_without_pin,
        UserFields.refund_permission: refund_permission,
        UserFields.cash_drawer_permission: cash_drawer_permission,
        UserFields.settlement_permission: settlement_permission,
        UserFields.report_permission: report_permission,
        UserFields.status: status,
        UserFields.created_at: created_at,
        UserFields.updated_at: updated_at,
        UserFields.soft_delete: soft_delete,
      };
}
