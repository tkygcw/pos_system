String? tableAppColors = ' tb_app_color';

class AppColorsFields {
  static List<String> values = [
    app_color_sqlite_id,
    app_color_id,
    background_color,
    icon_color,
    button_color,
    created_at,
    updated_at,
    soft_delete,
  ];

  static String app_color_sqlite_id = 'app_color_sqlite_id';
  static String app_color_id = 'app_color_id';
  static String background_color = 'background_color';
  static String icon_color = 'icon_color';
  static String button_color = 'button_color';
  static String created_at = 'created_at';
  static String updated_at = 'updated_at';
  static String soft_delete = 'soft_delete';
}

class AppColors {
  int? app_color_sqlite_id;
  int? app_color_id;
  String? background_color;
  String? icon_color;
  String? button_color;
  String? created_at;
  String? updated_at;
  String? soft_delete;
  int? item_sum;

  AppColors(
      {this.app_color_sqlite_id,
        this.app_color_id,
        this.background_color,
        this.icon_color,
        this.button_color,
        this.created_at,
        this.updated_at,
        this.soft_delete,
        this.item_sum});

  AppColors copy({
    int? app_color_sqlite_id,
    int? app_color_id,
    String? background_color,
    String? icon_color,
    String? button_color,
    String? created_at,
    String? updated_at,
    String? soft_delete,
    int? item_sum,
  }) =>
      AppColors(
          app_color_sqlite_id: app_color_sqlite_id ?? this.app_color_sqlite_id,
          app_color_id: app_color_id ?? this.app_color_id,
          background_color: background_color ?? this.background_color,
          icon_color: icon_color ?? this.icon_color,
          button_color: button_color ?? this.button_color,
          created_at: created_at ?? this.created_at,
          updated_at: updated_at ?? this.updated_at,
          soft_delete: soft_delete ?? this.soft_delete,
          item_sum: item_sum ?? this.item_sum);

  static AppColors fromJson(Map<String, Object?> json) => AppColors(
    app_color_sqlite_id: json[AppColorsFields.app_color_sqlite_id] as int?,
    app_color_id: json[AppColorsFields.app_color_id] as int?,
    background_color: json[AppColorsFields.background_color] as String?,
    icon_color: json[AppColorsFields.icon_color] as String?,
    button_color: json[AppColorsFields.button_color] as String?,
    created_at: json[AppColorsFields.created_at] as String?,
    updated_at: json[AppColorsFields.updated_at] as String?,
    soft_delete: json[AppColorsFields.soft_delete] as String?,
    item_sum: json['item_sum'] as int?,
  );

  Map<String, Object?> toJson() => {
    AppColorsFields.app_color_sqlite_id: app_color_sqlite_id,
    AppColorsFields.app_color_id: app_color_id,
    AppColorsFields.background_color: background_color,
    AppColorsFields.icon_color: icon_color,
    AppColorsFields.button_color: button_color,
    AppColorsFields.created_at: created_at,
    AppColorsFields.updated_at: updated_at,
    AppColorsFields.soft_delete: soft_delete,
  };
}