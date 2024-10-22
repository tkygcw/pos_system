String? tableReceipt = 'tb_receipt';

class ReceiptFields {
  static List<String> values = [
    receipt_sqlite_id,
    receipt_id,
    receipt_key,
    branch_id,
    header_image,
    header_image_status,
    header_text,
    header_text_status,
    header_font_size,
    show_address,
    show_email,
    receipt_email,
    show_break_down_price,
    footer_image,
    footer_image_status,
    footer_text,
    footer_text_status,
    promotion_detail_status,
    paper_size,
    status,
    show_product_sku,
    show_branch_tel,
    sync_status,
    created_at,
    updated_at,
    soft_delete
  ];

  static String receipt_sqlite_id = 'receipt_sqlite_id';
  static String receipt_id = 'receipt_id';
  static String receipt_key = 'receipt_key';
  static String branch_id = 'branch_id';
  static String header_image = 'header_image';
  static String header_image_status = 'header_image_status';
  static String header_text = 'header_text';
  static String header_text_status = 'header_text_status';
  static String header_font_size = 'header_font_size';
  static String show_address = 'show_address';
  static String show_email = 'show_email';
  static String receipt_email = 'receipt_email';
  static String show_break_down_price = 'show_break_down_price';
  static String footer_image = 'footer_image';
  static String footer_image_status = 'footer_image_status';
  static String footer_text = 'footer_text';
  static String footer_text_status = 'footer_text_status';
  static String promotion_detail_status = 'promotion_detail_status';
  static String paper_size = 'paper_size';
  static String status = 'status';
  static String show_product_sku = 'show_product_sku';
  static String show_branch_tel = 'show_branch_tel';
  static String sync_status = 'sync_status';
  static String created_at = 'created_at';
  static String updated_at = 'updated_at';
  static String soft_delete = 'soft_delete';

}

class Receipt {
  int? receipt_sqlite_id;
  int? receipt_id;
  String? receipt_key;
  String? branch_id;
  String? header_image;
  int? header_image_status;
  String? header_text;
  int? header_text_status;
  int? header_font_size;
  int? show_address;
  int? show_email;
  String? receipt_email;
  int? show_break_down_price;
  String? footer_image;
  int? footer_image_status;
  String? footer_text;
  int? footer_text_status;
  int? promotion_detail_status;
  String? paper_size;
  int? status;
  int? show_product_sku;
  int? show_branch_tel;
  int? sync_status;
  String? created_at;
  String? updated_at;
  String? soft_delete;

  Receipt(
      {this.receipt_sqlite_id,
        this.receipt_id,
        this.receipt_key,
        this.branch_id,
        this.header_image,
        this.header_image_status,
        this.header_text,
        this.header_text_status,
        this.header_font_size,
        this.show_address,
        this.show_email,
        this.receipt_email,
        this.show_break_down_price,
        this.footer_image,
        this.footer_image_status,
        this.footer_text,
        this.footer_text_status,
        this.promotion_detail_status,
        this.paper_size,
        this.status,
        this.show_product_sku,
        this.show_branch_tel,
        this.sync_status,
        this.created_at,
        this.updated_at,
        this.soft_delete});

  Receipt copy({
    int? receipt_sqlite_id,
    int? receipt_id,
    String? receipt_key,
    String? branch_id,
    String? header_image,
    int? header_image_status,
    String? header_text,
    int? header_text_status,
    int? header_font_size,
    int? show_address,
    int? show_email,
    String? receipt_email,
    int? show_break_down_price,
    String? footer_image,
    int? footer_image_status,
    String? footer_text,
    int? footer_text_status,
    int? promotion_detail_status,
    String? paper_size,
    int? status,
    int? show_product_sku,
    int? show_branch_tel,
    int? sync_status,
    String? created_at,
    String? updated_at,
    String? soft_delete
  }) =>
      Receipt(
          receipt_sqlite_id: receipt_sqlite_id ?? this.receipt_sqlite_id,
          receipt_id: receipt_id ?? this.receipt_id,
          receipt_key: receipt_key ?? this.receipt_key,
          branch_id: branch_id ?? this.branch_id,
          header_image: header_image ?? this.header_image,
          header_image_status: header_image_status ?? this.header_image_status,
          header_text: header_text ?? this.header_text,
          header_text_status: header_text_status ?? this.header_text_status,
          header_font_size: header_font_size ?? this.header_font_size,
          show_address: show_address ?? this.show_address,
          show_email: show_email ?? this.show_email,
          receipt_email: receipt_email ?? this.receipt_email,
          show_break_down_price: show_break_down_price ?? this.show_break_down_price,
          footer_image: footer_image ?? this.footer_image,
          footer_image_status: footer_image_status ?? this.footer_image_status,
          footer_text: footer_text ?? this.footer_text,
          footer_text_status: footer_text_status ?? this.footer_text_status,
          promotion_detail_status: promotion_detail_status ?? this.promotion_detail_status,
          paper_size: paper_size ?? this.paper_size,
          status: status ?? this.status,
          show_product_sku: show_product_sku ?? this.show_product_sku,
          show_branch_tel: show_branch_tel ?? this.show_branch_tel,
          sync_status: sync_status ?? this.sync_status,
          created_at: created_at ?? this.created_at,
          updated_at: updated_at ?? this.updated_at,
          soft_delete: soft_delete ?? this.soft_delete);

  static Receipt fromJson(Map<String, Object?> json) => Receipt(
    receipt_sqlite_id: json[ReceiptFields.receipt_sqlite_id] as int?,
    receipt_id: json[ReceiptFields.receipt_id] as int?,
    receipt_key: json[ReceiptFields.receipt_key] as String?,
    branch_id: json[ReceiptFields.branch_id] as String?,
    header_image: json[ReceiptFields.header_image] as String?,
    header_image_status: json[ReceiptFields.header_image_status] as int?,
    header_text: json[ReceiptFields.header_text] as String?,
    header_text_status: json[ReceiptFields.header_text_status] as int?,
    header_font_size: json[ReceiptFields.header_font_size] as int?,
    show_address: json[ReceiptFields.show_address] as int?,
    show_email: json[ReceiptFields.show_email] as int?,
    receipt_email: json[ReceiptFields.receipt_email] as String?,
    show_break_down_price: json[ReceiptFields.show_break_down_price] as int?,
    footer_image: json[ReceiptFields.footer_image] as String?,
    footer_image_status: json[ReceiptFields.footer_image_status] as int?,
    footer_text: json[ReceiptFields.footer_text] as String?,
    footer_text_status: json[ReceiptFields.footer_text_status] as int?,
    promotion_detail_status: json[ReceiptFields.promotion_detail_status] as int?,
    paper_size: json[ReceiptFields.paper_size] as String?,
    status: json[ReceiptFields.status] as int?,
    show_product_sku: json[ReceiptFields.show_product_sku] as int?,
    show_branch_tel: json[ReceiptFields.show_branch_tel] as int?,
    sync_status: json[ReceiptFields.sync_status] as int?,
    created_at: json[ReceiptFields.created_at] as String?,
    updated_at: json[ReceiptFields.updated_at] as String?,
    soft_delete: json[ReceiptFields.soft_delete] as String?,
  );

  Map<String, Object?> toJson() => {
    ReceiptFields.receipt_sqlite_id: receipt_sqlite_id,
    ReceiptFields.receipt_id: receipt_id,
    ReceiptFields.receipt_key: receipt_key,
    ReceiptFields.branch_id: branch_id,
    ReceiptFields.header_image: header_image,
    ReceiptFields.header_image_status: header_image_status,
    ReceiptFields.header_text: header_text,
    ReceiptFields.header_text_status: header_text_status,
    ReceiptFields.header_font_size: header_font_size,
    ReceiptFields.show_address: show_address,
    ReceiptFields.show_email: show_email,
    ReceiptFields.receipt_email: receipt_email,
    ReceiptFields.show_break_down_price: show_break_down_price,
    ReceiptFields.footer_image: footer_image,
    ReceiptFields.footer_image_status: footer_image_status,
    ReceiptFields.footer_text: footer_text,
    ReceiptFields.footer_text_status: footer_text_status,
    ReceiptFields.promotion_detail_status: promotion_detail_status,
    ReceiptFields.paper_size: paper_size,
    ReceiptFields.status: status,
    ReceiptFields.show_product_sku: show_product_sku,
    ReceiptFields.show_branch_tel: show_branch_tel,
    ReceiptFields.sync_status: sync_status,
    ReceiptFields.created_at: created_at,
    ReceiptFields.updated_at: updated_at,
    ReceiptFields.soft_delete: soft_delete,
  };
}
