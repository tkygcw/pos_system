String? tableAppSetting = ' tb_app_setting';

class AppSettingFields {
  static List<String> values = [
    app_setting_sqlite_id,
    branch_id,
    open_cash_drawer,
    show_second_display,
    direct_payment,
    print_checklist,
    print_receipt,
    show_sku,
    qr_order_auto_accept,
    enable_numbering,
    starting_number,
    table_order,
    settlement_after_all_order_paid,
    show_product_desc,
    print_cancel_receipt,
    product_sort_by,
    dynamic_qr_default_exp_after_hour,
    variant_item_sort_by,
    dynamic_qr_invalid_after_payment,
    sync_status,
    created_at,
    updated_at
  ];

  static String app_setting_sqlite_id = 'app_setting_sqlite_id';
  static String branch_id = 'branch_id';
  static String open_cash_drawer = 'open_cash_drawer';
  static String show_second_display = 'show_second_display';
  static String direct_payment = 'direct_payment';
  static String print_checklist = 'print_checklist';
  static String print_receipt = 'print_receipt';
  static String show_sku = 'show_sku';
  static String qr_order_auto_accept = 'qr_order_auto_accept';
  static String enable_numbering = 'enable_numbering';
  static String starting_number = 'starting_number';
  static String table_order = 'table_order';
  static String settlement_after_all_order_paid = 'settlement_after_all_order_paid';
  static String show_product_desc = 'show_product_desc';
  static String print_cancel_receipt = 'print_cancel_receipt';
  static String product_sort_by = 'product_sort_by';
  static String dynamic_qr_default_exp_after_hour = 'dynamic_qr_default_exp_after_hour';
  static String variant_item_sort_by = 'variant_item_sort_by';
  static String dynamic_qr_invalid_after_payment = 'dynamic_qr_invalid_after_payment';
  static String sync_status = 'sync_status';
  static String created_at = 'created_at';
  static String updated_at = 'updated_at';
}

class AppSetting{
  int? app_setting_sqlite_id;
  String? branch_id;
  int? open_cash_drawer;
  int? show_second_display;
  int? direct_payment;
  int? print_checklist;
  int? print_receipt;
  int? show_sku;
  int? qr_order_auto_accept;
  int? enable_numbering;
  int? starting_number;
  int? table_order;
  int? settlement_after_all_order_paid;
  int? show_product_desc;
  int? print_cancel_receipt;
  int? product_sort_by;
  int? dynamic_qr_default_exp_after_hour;
  int? variant_item_sort_by;
  int? dynamic_qr_invalid_after_payment;
  int? sync_status;
  String? created_at;
  String? updated_at;

  AppSetting(
      {this.app_setting_sqlite_id,
        this.branch_id,
        this.open_cash_drawer,
        this.show_second_display,
        this.direct_payment,
        this.print_checklist,
        this.print_receipt,
        this.show_sku,
        this.qr_order_auto_accept,
        this.enable_numbering,
        this.starting_number,
        this.table_order,
        this.settlement_after_all_order_paid,
        this.show_product_desc,
        this.print_cancel_receipt,
        this.product_sort_by,
        this.dynamic_qr_default_exp_after_hour,
        this.variant_item_sort_by,
        this.dynamic_qr_invalid_after_payment,
        this.sync_status,
        this.created_at,
        this.updated_at
      });

  AppSetting copy({
    int? app_setting_sqlite_id,
    String? branch_id,
    int? open_cash_drawer,
    int? show_second_display,
    int? direct_payment,
    int? print_checklist,
    int? print_receipt,
    int? show_sku,
    int? qr_order_auto_accept,
    int? enable_numbering,
    int? starting_number,
    int? table_order,
    int? settlement_after_all_order_paid,
    int? show_product_desc,
    int? print_cancel_receipt,
    int? product_sort_by,
    int? dynamic_qr_default_exp_after_hour,
    int? variant_item_sort_by,
    int? dynamic_qr_invalid_after_payment,
    int? sync_status,
    String? created_at,
    String? updated_at
  }) =>
      AppSetting(
        app_setting_sqlite_id: app_setting_sqlite_id ?? this.app_setting_sqlite_id,
        branch_id: branch_id ?? this.branch_id,
        open_cash_drawer: open_cash_drawer ?? this.open_cash_drawer,
        show_second_display: show_second_display ?? this.show_second_display,
        direct_payment: direct_payment ?? this.direct_payment,
        print_checklist: print_checklist ?? this.print_checklist,
        print_receipt: print_receipt ?? this.print_receipt,
        show_sku: show_sku ?? this.show_sku,
        qr_order_auto_accept: qr_order_auto_accept ?? this.qr_order_auto_accept,
        enable_numbering: enable_numbering ?? this.enable_numbering,
        starting_number: starting_number ?? this.starting_number,
        table_order: table_order ?? this.table_order,
        settlement_after_all_order_paid: settlement_after_all_order_paid ?? this.settlement_after_all_order_paid,
        show_product_desc: show_product_desc ?? this.show_product_desc,
        print_cancel_receipt: print_cancel_receipt ?? this.print_cancel_receipt,
        product_sort_by: product_sort_by ?? this.product_sort_by,
        dynamic_qr_default_exp_after_hour: dynamic_qr_default_exp_after_hour ?? this.dynamic_qr_default_exp_after_hour,
        variant_item_sort_by: variant_item_sort_by ?? this.variant_item_sort_by,
        dynamic_qr_invalid_after_payment: dynamic_qr_invalid_after_payment ?? this.dynamic_qr_invalid_after_payment,
        sync_status: sync_status ?? this.sync_status,
        created_at: created_at ?? this.created_at,
        updated_at: updated_at ?? this.updated_at
      );

  static AppSetting fromJson(Map<String, Object?> json) => AppSetting(
    app_setting_sqlite_id: json[AppSettingFields.app_setting_sqlite_id] as int?,
    branch_id: json[AppSettingFields.branch_id] as String?,
    open_cash_drawer: json[AppSettingFields.open_cash_drawer] as int?,
    show_second_display: json[AppSettingFields.show_second_display] as int?,
    direct_payment: json[AppSettingFields.direct_payment] as int?,
    print_checklist: json[AppSettingFields.print_checklist] as int?,
    print_receipt: json[AppSettingFields.print_receipt] as int?,
    show_sku: json[AppSettingFields.show_sku] as int?,
    qr_order_auto_accept: json[AppSettingFields.qr_order_auto_accept] as int?,
    enable_numbering: json[AppSettingFields.enable_numbering] as int?,
    starting_number: json[AppSettingFields.starting_number] as int?,
    table_order: json[AppSettingFields.table_order] as int?,
    settlement_after_all_order_paid: json[AppSettingFields.settlement_after_all_order_paid] as int?,
    show_product_desc: json[AppSettingFields.show_product_desc] as int?,
    print_cancel_receipt: json[AppSettingFields.print_cancel_receipt] as int?,
    product_sort_by: json[AppSettingFields.product_sort_by] as int?,
    dynamic_qr_default_exp_after_hour: json[AppSettingFields.dynamic_qr_default_exp_after_hour] as int?,
    variant_item_sort_by: json[AppSettingFields.variant_item_sort_by] as int?,
    dynamic_qr_invalid_after_payment: json[AppSettingFields.dynamic_qr_invalid_after_payment] as int?,
    sync_status: json[AppSettingFields.sync_status] as int?,
    created_at: json[AppSettingFields.created_at] as String?,
    updated_at: json[AppSettingFields.updated_at] as String?
  );

  Map<String, Object?> toJson() => {
    AppSettingFields.app_setting_sqlite_id: app_setting_sqlite_id,
    AppSettingFields.branch_id: branch_id,
    AppSettingFields.open_cash_drawer: open_cash_drawer,
    AppSettingFields.show_second_display: show_second_display,
    AppSettingFields.direct_payment: direct_payment,
    AppSettingFields.print_checklist: print_checklist,
    AppSettingFields.print_receipt: print_receipt,
    AppSettingFields.show_sku: show_sku,
    AppSettingFields.qr_order_auto_accept: qr_order_auto_accept,
    AppSettingFields.enable_numbering: enable_numbering,
    AppSettingFields.starting_number: starting_number,
    AppSettingFields.table_order: table_order,
    AppSettingFields.settlement_after_all_order_paid: settlement_after_all_order_paid,
    AppSettingFields.show_product_desc: show_product_desc,
    AppSettingFields.print_cancel_receipt: print_cancel_receipt,
    AppSettingFields.product_sort_by: product_sort_by,
    AppSettingFields.dynamic_qr_default_exp_after_hour: dynamic_qr_default_exp_after_hour,
    AppSettingFields.variant_item_sort_by: variant_item_sort_by,
    AppSettingFields.dynamic_qr_invalid_after_payment: dynamic_qr_invalid_after_payment,
    AppSettingFields.sync_status: sync_status,
    AppSettingFields.created_at: created_at,
    AppSettingFields.updated_at: updated_at
  };
}