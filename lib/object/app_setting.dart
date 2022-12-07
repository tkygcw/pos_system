String? tableAppSetting = ' tb_app_setting';

class AppSettingFields {
  static List<String> values = [
    app_setting_sqlite_id,
    open_cash_drawer,
  ];

  static String app_setting_sqlite_id = 'app_setting_sqlite_id';
  static String open_cash_drawer = 'open_cash_drawer';
}

class AppSetting{
  int? app_setting_sqlite_id;
  int? open_cash_drawer;

  AppSetting(
      {this.app_setting_sqlite_id,
        this.open_cash_drawer});

  AppSetting copy({
   int? app_setting_sqlite_id,
   int? open_cash_drawer,
  }) =>
      AppSetting(
        app_setting_sqlite_id: app_setting_sqlite_id ?? this.app_setting_sqlite_id,
        open_cash_drawer: open_cash_drawer ?? this.open_cash_drawer,
      );

  static AppSetting fromJson(Map<String, Object?> json) => AppSetting(
    app_setting_sqlite_id: json[AppSettingFields.app_setting_sqlite_id] as int?,
    open_cash_drawer: json[AppSettingFields.open_cash_drawer] as int?,
  );

  Map<String, Object?> toJson() => {
    AppSettingFields.app_setting_sqlite_id: app_setting_sqlite_id,
    AppSettingFields.open_cash_drawer: open_cash_drawer
  };
}