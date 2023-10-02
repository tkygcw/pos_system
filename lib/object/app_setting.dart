String? tableAppSetting = ' tb_app_setting';

class AppSettingFields {
  static List<String> values = [
    app_setting_sqlite_id,
    open_cash_drawer,
    show_second_display,
    direct_payment,
    print_checklist,
    show_sku,
  ];

  static String app_setting_sqlite_id = 'app_setting_sqlite_id';
  static String open_cash_drawer = 'open_cash_drawer';
  static String show_second_display = 'show_second_display';
  static String direct_payment = 'direct_payment';
  static String print_checklist = 'print_checklist';
  static String show_sku = 'show_sku';
}

class AppSetting{
  int? app_setting_sqlite_id;
  int? open_cash_drawer;
  int? show_second_display;
  int? direct_payment;
  int? print_checklist;
  int? show_sku;

  AppSetting(
      {this.app_setting_sqlite_id,
        this.open_cash_drawer,
        this.show_second_display,
        this.direct_payment,
        this.print_checklist,
        this.show_sku
      });

  AppSetting copy({
    int? app_setting_sqlite_id,
    int? open_cash_drawer,
    int? show_second_display,
    int? direct_payment,
    int? print_checklist,
    int? show_sku
  }) =>
      AppSetting(
        app_setting_sqlite_id: app_setting_sqlite_id ?? this.app_setting_sqlite_id,
        open_cash_drawer: open_cash_drawer ?? this.open_cash_drawer,
        show_second_display: show_second_display ?? this.show_second_display,
        direct_payment: direct_payment ?? this.direct_payment,
        print_checklist: print_checklist ?? this.print_checklist,
        show_sku: show_sku ?? this.show_sku
      );

  static AppSetting fromJson(Map<String, Object?> json) => AppSetting(
    app_setting_sqlite_id: json[AppSettingFields.app_setting_sqlite_id] as int?,
    open_cash_drawer: json[AppSettingFields.open_cash_drawer] as int?,
    show_second_display: json[AppSettingFields.show_second_display] as int?,
    direct_payment: json[AppSettingFields.direct_payment] as int?,
    print_checklist: json[AppSettingFields.print_checklist] as int?,
    show_sku: json[AppSettingFields.show_sku] as int?
  );

  Map<String, Object?> toJson() => {
    AppSettingFields.app_setting_sqlite_id: app_setting_sqlite_id,
    AppSettingFields.open_cash_drawer: open_cash_drawer,
    AppSettingFields.show_second_display: show_second_display,
    AppSettingFields.direct_payment: direct_payment,
    AppSettingFields.print_checklist: print_checklist,
    AppSettingFields.show_sku: show_sku
  };
}