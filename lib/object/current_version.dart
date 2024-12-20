String? tableCurrentVersion = 'tb_current_version';

class CurrentVersionFields {
  static List<String> values = [
    current_version_sqlite_id,
    current_version_id,
    branch_id,
    current_version,
    platform,
    is_gms,
    source,
    sync_status,
    created_at,
    updated_at,
    soft_delete
  ];

  static String current_version_sqlite_id = 'current_version_sqlite_id';
  static String current_version_id = 'current_version_id';
  static String branch_id = 'branch_id';
  static String current_version = 'current_version';
  static String platform = 'platform';
  static String is_gms = 'is_gms';
  static String source = 'source';
  static String sync_status = 'sync_status';
  static String created_at = 'created_at';
  static String updated_at = 'updated_at';
  static String soft_delete = 'soft_delete';
}

class CurrentVersion {
  int? current_version_sqlite_id;
  int? current_version_id;
  String? branch_id;
  String? current_version;
  int? platform;
  int? is_gms;
  String? source;
  int? sync_status;
  String? created_at;
  String? updated_at;
  String? soft_delete;

  CurrentVersion(
      {this.current_version_sqlite_id,
        this.current_version_id,
        this.branch_id,
        this.current_version,
        this.platform,
        this.is_gms,
        this.source,
        this.sync_status,
        this.created_at,
        this.updated_at,
        this.soft_delete,
      });

  CurrentVersion copy({
    int? current_version_sqlite_id,
    int? current_version_id,
    String? branch_id,
    String? current_version,
    int? platform,
    int? is_gms,
    String? source,
    int? sync_status,
    String? created_at,
    String? updated_at,
    String? soft_delete
  }) =>
      CurrentVersion(
          current_version_sqlite_id: current_version_sqlite_id ?? this.current_version_sqlite_id,
          current_version_id: current_version_id ?? this.current_version_id,
          branch_id: branch_id ?? this.branch_id,
          current_version: current_version ?? this.current_version,
          platform: platform ?? this.platform,
          is_gms: is_gms ?? this.is_gms,
          source: source ?? this.source,
          sync_status: sync_status ?? this.sync_status,
          created_at: created_at ?? this.created_at,
          updated_at: updated_at ?? this.updated_at,
          soft_delete: soft_delete ?? this.soft_delete);

  static CurrentVersion fromJson(Map<String, Object?> json) => CurrentVersion(
    current_version_sqlite_id: json[CurrentVersionFields.current_version_sqlite_id] as int?,
    current_version_id: json[CurrentVersionFields.current_version_id] as int?,
    branch_id: json[CurrentVersionFields.branch_id] as String?,
    current_version: json[CurrentVersionFields.current_version] as String?,
    platform: json[CurrentVersionFields.platform] as int?,
    is_gms: json[CurrentVersionFields.is_gms] as int?,
    source: json[CurrentVersionFields.source] as String?,
    sync_status: json[CurrentVersionFields.sync_status] as int?,
    created_at: json[CurrentVersionFields.created_at] as String?,
    updated_at: json[CurrentVersionFields.updated_at] as String?,
    soft_delete: json[CurrentVersionFields.soft_delete] as String?,
  );

  Map<String, Object?> toJson() => {
    CurrentVersionFields.current_version_sqlite_id: current_version_sqlite_id,
    CurrentVersionFields.current_version_id: current_version_id,
    CurrentVersionFields.branch_id: branch_id,
    CurrentVersionFields.current_version: current_version,
    CurrentVersionFields.platform: platform,
    CurrentVersionFields.is_gms: is_gms,
    CurrentVersionFields.source: source,
    CurrentVersionFields.sync_status: sync_status,
    CurrentVersionFields.created_at: created_at,
    CurrentVersionFields.updated_at: updated_at,
    CurrentVersionFields.soft_delete: soft_delete,
  };
}


