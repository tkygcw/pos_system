String? tableAttendance = 'tb_attendance';

class AttendanceFields {
  static List<String> values = [
    attendance_sqlite_id,
    attendance_key,
    branch_id,
    user_id,
    role,
    clock_in_at,
    clock_out_at,
    duration,
    sync_status,
    created_at,
    updated_at,
    soft_delete
  ];

  static String attendance_sqlite_id = 'attendance_sqlite_id';
  static String attendance_key = 'attendance_key';
  static String branch_id = 'branch_id';
  static String user_id = 'user_id';
  static String role = 'role';
  static String clock_in_at = 'clock_in_at';
  static String clock_out_at = 'clock_out_at';
  static String duration = 'duration';
  static String sync_status = 'sync_status';
  static String created_at = 'created_at';
  static String updated_at = 'updated_at';
  static String soft_delete = 'soft_delete';
}

class Attendance{
  int? attendance_sqlite_id;
  String? attendance_key;
  String? branch_id;
  String? user_id;
  int? role;
  String? clock_in_at;
  String? clock_out_at;
  int? duration;
  int? sync_status;
  String? created_at;
  String? updated_at;
  String? soft_delete;
  List<Attendance> groupAttendanceList = [];
  List<Attendance> attendanceGroupData = [];
  String? userName;
  int? totalDuration;

  Attendance(
      {this.attendance_sqlite_id,
        this.attendance_key,
        this.branch_id,
        this.user_id,
        this.role,
        this.clock_in_at,
        this.clock_out_at,
        this.duration,
        this.sync_status,
        this.created_at,
        this.updated_at,
        this.soft_delete,
        this.userName,
        this.totalDuration
      });

  Attendance copy({
    int? attendance_sqlite_id,
    String? attendance_key,
    String? branch_id,
    String? user_id,
    int? role,
    String? clock_in_at,
    String? clock_out_at,
    int? duration,
    int? sync_status,
    String? created_at,
    String? updated_at,
    String? soft_delete
  }) =>
      Attendance(
          attendance_sqlite_id: attendance_sqlite_id ?? this.attendance_sqlite_id,
          attendance_key: attendance_key ?? this.attendance_key,
          branch_id: branch_id ?? this.branch_id,
          user_id: user_id ?? this.user_id,
          role: role ?? this.role,
          clock_in_at: clock_in_at ?? this.clock_in_at,
          clock_out_at: clock_out_at ?? this.clock_out_at,
          duration: duration ?? this.duration,
          sync_status: sync_status ?? this.sync_status,
          created_at: created_at ?? this.created_at,
          updated_at: updated_at ?? this.updated_at,
          soft_delete: soft_delete ?? this.soft_delete
      );

  static Attendance fromJson(Map<String, Object?> json) => Attendance(
      attendance_sqlite_id: json[AttendanceFields.attendance_sqlite_id] as int?,
      attendance_key: json[AttendanceFields.attendance_key] as String?,
      branch_id: json[AttendanceFields.branch_id] as String?,
      user_id: json[AttendanceFields.user_id] as String?,
      role: json[AttendanceFields.role] as int?,
      clock_in_at: json[AttendanceFields.clock_in_at] as String?,
      clock_out_at: json[AttendanceFields.clock_out_at] as String?,
      duration: json[AttendanceFields.duration] as int?,
      sync_status: json[AttendanceFields.sync_status] as int?,
      created_at: json[AttendanceFields.created_at] as String?,
      updated_at: json[AttendanceFields.updated_at] as String?,
      soft_delete: json[AttendanceFields.soft_delete] as String?,
      userName: json['name'] as String?,
      totalDuration: json['totalDuration'] as int?,
  );

  Map<String, Object?> toJson() => {
    AttendanceFields.attendance_sqlite_id: attendance_sqlite_id,
    AttendanceFields.attendance_key: attendance_key,
    AttendanceFields.branch_id: branch_id,
    AttendanceFields.user_id: user_id,
    AttendanceFields.role: role,
    AttendanceFields.clock_in_at: clock_in_at,
    AttendanceFields.clock_out_at: clock_out_at,
    AttendanceFields.duration: duration,
    AttendanceFields.sync_status: sync_status,
    AttendanceFields.created_at: created_at,
    AttendanceFields.updated_at: updated_at,
    AttendanceFields.soft_delete: soft_delete
  };
}