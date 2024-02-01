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
  int? status;
  String? created_at;
  String? updated_at;
  String? soft_delete;

  User(
      {this.user_id,
      this.name,
      this.email,
      this.role,
      this.phone,
      this.pos_pin,
      this.edit_price_without_pin,
      this.status,
      this.created_at,
      this.updated_at,
      this.soft_delete});

  User copy({
    int? user_id,
    String? name,
    String? email,
    int? role,
    String? phone,
    String? pos_pin,
    int? edit_price_without_pin,
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
        status: json[UserFields.status] as int?,
        created_at: json[UserFields.created_at] as String?,
        updated_at: json[UserFields.updated_at] as String?,
        soft_delete: json[UserFields.soft_delete] as String?,
      );

  Map<String, Object?> toJson() => {
        UserFields.user_id: user_id,
        UserFields.name: name,
        UserFields.email: email,
        UserFields.role: role,
        UserFields.phone: phone,
        UserFields.pos_pin: pos_pin,
        UserFields.edit_price_without_pin: edit_price_without_pin,
        UserFields.status: status,
        UserFields.created_at: created_at,
        UserFields.updated_at: updated_at,
        UserFields.soft_delete: soft_delete,
      };
}
