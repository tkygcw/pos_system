String? tableAppSetting = ' tb_app_setting';

class AppSettingFields {
  static List<String> values = [
    app_setting_sqlite_id,
    open_cash_drawer,
    show_second_display,
  ];

  static String app_setting_sqlite_id = 'app_setting_sqlite_id';
  static String open_cash_drawer = 'open_cash_drawer';
  static String show_second_display = 'show_second_display';
}

class AppSetting{
  int? app_setting_sqlite_id;
  int? open_cash_drawer;
  int? show_second_display;

  AppSetting(
      {this.app_setting_sqlite_id,
        this.open_cash_drawer,
        this.show_second_display
      });

  AppSetting copy({
   int? app_setting_sqlite_id,
   int? open_cash_drawer,
   int? show_second_display
  }) =>
      AppSetting(
        app_setting_sqlite_id: app_setting_sqlite_id ?? this.app_setting_sqlite_id,
        open_cash_drawer: open_cash_drawer ?? this.open_cash_drawer,
        show_second_display: show_second_display ?? this.show_second_display
      );

  static AppSetting fromJson(Map<String, Object?> json) => AppSetting(
    app_setting_sqlite_id: json[AppSettingFields.app_setting_sqlite_id] as int?,
    open_cash_drawer: json[AppSettingFields.open_cash_drawer] as int?,
    show_second_display: json[AppSettingFields.show_second_display] as int?
  );

  Map<String, Object?> toJson() => {
    AppSettingFields.app_setting_sqlite_id: app_setting_sqlite_id,
    AppSettingFields.open_cash_drawer: open_cash_drawer,
    AppSettingFields.show_second_display: show_second_display
  };
}