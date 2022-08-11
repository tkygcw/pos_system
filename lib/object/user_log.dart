String? tableUserLog = 'tb_user_log ';

class UserLogFields {
  static List<String> values = [
    user_log_id,
    user_id,
    check_in_time,
    check_out_time,
    date,
  ];

  static String user_log_id = 'user_log_id';
  static String user_id = 'user_id';
  static String check_in_time = 'check_in_time';
  static String check_out_time = 'check_out_time';
  static String date = 'date';
}

class UserLog{
  int? user_log_id;
  String? user_id;
  String? check_in_time;
  String? check_out_time;
  String? date;

  UserLog(
      {this.user_log_id,
        this.user_id,
        this.check_in_time,
        this.check_out_time,
        this.date});

  UserLog copy({
    int? user_log_id,
    String? user_id,
    String? check_in_time,
    String? check_out_time,
    String? date,
  }) =>
      UserLog(
          user_log_id: user_log_id ?? this.user_log_id,
          user_id: user_id ?? this.user_id,
          check_in_time: check_in_time ?? this.check_in_time,
          check_out_time: check_out_time ?? this.check_out_time,
          date: date ?? this.date,);

  static UserLog fromJson(Map<String, Object?> json) => UserLog  (
    user_log_id: json[UserLogFields.user_log_id] as int?,
    user_id: json[UserLogFields.user_id] as String?,
    check_in_time: json[UserLogFields.check_in_time] as String?,
    check_out_time: json[UserLogFields.check_out_time] as String?,
    date: json[UserLogFields.date] as String?,
  );

  Map<String, Object?> toJson() => {
    UserLogFields.user_log_id: user_log_id,
    UserLogFields.user_id: user_id,
    UserLogFields.check_in_time: check_in_time,
    UserLogFields.check_out_time: check_out_time,
    UserLogFields.date: date,
  };
}
