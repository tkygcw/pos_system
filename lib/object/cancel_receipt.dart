String? tableCancelReceipt = 'tb_cancel_receipt';

class CancelReceiptFields {
  static List<String> values = [
    cancel_receipt_sqlite_id,
    cancel_receipt_id,
    cancel_receipt_key,
    branch_id,
    product_name_font_size,
    other_font_size,
    paper_size,
    show_product_price,
    show_product_sku,
    sync_status,
    created_at,
    updated_at,
    soft_delete
  ];

  static String cancel_receipt_sqlite_id = 'cancel_receipt_sqlite_id';
  static String cancel_receipt_id = 'cancel_receipt_id';
  static String cancel_receipt_key = 'cancel_receipt_key';
  static String branch_id = 'branch_id';
  static String product_name_font_size = 'product_name_font_size';
  static String other_font_size = 'other_font_size';
  static String paper_size = 'paper_size';
  static String show_product_price = 'show_product_price';
  static String show_product_sku = 'show_product_sku';
  static String sync_status = 'sync_status';
  static String created_at = 'created_at';
  static String updated_at = 'updated_at';
  static String soft_delete = 'soft_delete';

}

class CancelReceipt {
  int? cancel_receipt_sqlite_id;
  int? cancel_receipt_id;
  String? cancel_receipt_key;
  String? branch_id;
  int? product_name_font_size;
  int? other_font_size;
  String? paper_size;
  int? show_product_price;
  int? show_product_sku;
  int? sync_status;
  String? created_at;
  String? updated_at;
  String? soft_delete;

  CancelReceipt({
    this.cancel_receipt_sqlite_id,
    this.cancel_receipt_id,
    this.cancel_receipt_key,
    this.branch_id,
    this.product_name_font_size,
    this.other_font_size,
    this.paper_size,
    this.show_product_price,
    this.show_product_sku,
    this.sync_status,
    this.created_at,
    this.updated_at,
    this.soft_delete});

  CancelReceipt copy({
    int? cancel_receipt_sqlite_id,
    int? cancel_receipt_id,
    String? cancel_receipt_key,
    String? branch_id,
    int? product_name_font_size,
    int? other_font_size,
    String? paper_size,
    int? show_product_price,
    int? show_product_sku,
    int? sync_status,
    String? created_at,
    String? updated_at,
    String? soft_delete
  }) =>
      CancelReceipt(
          cancel_receipt_sqlite_id: cancel_receipt_sqlite_id ?? this.cancel_receipt_sqlite_id,
          cancel_receipt_id: cancel_receipt_id ?? this.cancel_receipt_id,
          cancel_receipt_key: cancel_receipt_key ?? this.cancel_receipt_key,
          branch_id: branch_id ?? this.branch_id,
          product_name_font_size: product_name_font_size ?? this.product_name_font_size,
          other_font_size: other_font_size ?? this.other_font_size,
          paper_size: paper_size ?? this.paper_size,
          show_product_price: show_product_price ?? this.show_product_price,
          show_product_sku: show_product_sku ?? this.show_product_sku,
          sync_status: sync_status ?? this.sync_status,
          created_at: created_at ?? this.created_at,
          updated_at: updated_at ?? this.updated_at,
          soft_delete: soft_delete ?? this.soft_delete);

  static CancelReceipt fromJson(Map<String, Object?> json) => CancelReceipt(
    cancel_receipt_sqlite_id: json[CancelReceiptFields.cancel_receipt_sqlite_id] as int?,
    cancel_receipt_id: json[CancelReceiptFields.cancel_receipt_id] as int?,
    cancel_receipt_key: json[CancelReceiptFields.cancel_receipt_key] as String?,
    branch_id: json[CancelReceiptFields.branch_id] as String?,
    product_name_font_size: json[CancelReceiptFields.product_name_font_size] as int?,
    other_font_size: json[CancelReceiptFields.other_font_size] as int?,
    paper_size: json[CancelReceiptFields.paper_size] as String?,
    show_product_price: json[CancelReceiptFields.show_product_price] as int?,
    show_product_sku: json[CancelReceiptFields.show_product_sku] as int?,
    sync_status: json[CancelReceiptFields.sync_status] as int?,
    created_at: json[CancelReceiptFields.created_at] as String?,
    updated_at: json[CancelReceiptFields.updated_at] as String?,
    soft_delete: json[CancelReceiptFields.soft_delete] as String?,
  );

  Map<String, Object?> toJson() => {
    CancelReceiptFields.cancel_receipt_sqlite_id: cancel_receipt_sqlite_id,
    CancelReceiptFields.cancel_receipt_id: cancel_receipt_id,
    CancelReceiptFields.cancel_receipt_key: cancel_receipt_key,
    CancelReceiptFields.branch_id: branch_id,
    CancelReceiptFields.product_name_font_size: product_name_font_size,
    CancelReceiptFields.other_font_size: other_font_size,
    CancelReceiptFields.paper_size: paper_size,
    CancelReceiptFields.show_product_price: show_product_price,
    CancelReceiptFields.show_product_sku: show_product_sku,
    CancelReceiptFields.sync_status: sync_status,
    CancelReceiptFields.created_at: created_at,
    CancelReceiptFields.updated_at: updated_at,
    CancelReceiptFields.soft_delete: soft_delete,
  };
}
