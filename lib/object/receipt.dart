String? tableReceipt = 'tb_receipt';

class ReceiptFields {
  static List<String> values = [
    receipt_sqlite_id,
    receipt_id,
    branch_id,
    company_id,
    header_image,
    header_image_status,
    header_text,
    header_text_status,
    footer_image,
    footer_image_status,
    footer_text,
    footer_text_status,
    promotion_detail_status,
    status,
    sync_status,
    created_at,
    updated_at,
    soft_delete
  ];

  static String receipt_sqlite_id = 'receipt_sqlite_id';
  static String receipt_id = 'receipt_id';
  static String branch_id = 'branch_id';
  static String company_id = 'company_id';
  static String header_image = 'header_image';
  static String header_image_status = 'header_image_status';
  static String header_text = 'header_text';
  static String header_text_status = 'header_text_status';
  static String footer_image = 'footer_image';
  static String footer_image_status = 'footer_image_status';
  static String footer_text = 'footer_text';
  static String footer_text_status = 'footer_text_status';
  static String promotion_detail_status = 'promotion_detail_status';
  static String status = 'status';
  static String sync_status = 'sync_status';
  static String created_at = 'created_at';
  static String updated_at = 'updated_at';
  static String soft_delete = 'soft_delete';

}

class Receipt {
  int? receipt_sqlite_id;
  int? receipt_id;
  String? branch_id;
  String? company_id;
  String? header_image;
  int? header_image_status;
  String? header_text;
  int? header_text_status;
  String? footer_image;
  int? footer_image_status;
  String? footer_text;
  int? footer_text_status;
  int? promotion_detail_status;
  int? status;
  int? sync_status;
  String? created_at;
  String? updated_at;
  String? soft_delete;

  Receipt(
      {this.receipt_sqlite_id,
        this.receipt_id,
        this.branch_id,
        this.company_id,
        this.header_image,
        this.header_image_status,
        this.header_text,
        this.header_text_status,
        this.footer_image,
        this.footer_image_status,
        this.footer_text,
        this.footer_text_status,
        this.promotion_detail_status,
        this.status,
        this.sync_status,
        this.created_at,
        this.updated_at,
        this.soft_delete});

  Receipt copy({
    int? receipt_sqlite_id,
    int? receipt_id,
    String? branch_id,
    String? company_id,
    String? header_image,
    int? header_image_status,
    String? header_text,
    int? header_text_status,
    String? footer_image,
    int? footer_image_status,
    String? footer_text,
    int? footer_text_status,
    int? promotion_detail_status,
    int? status,
    int? sync_status,
    String? created_at,
    String? updated_at,
    String? soft_delete
  }) =>
      Receipt(
          receipt_sqlite_id: receipt_sqlite_id ?? this.receipt_sqlite_id,
          receipt_id: receipt_id ?? this.receipt_id,
          branch_id: branch_id ?? this.branch_id,
          company_id: company_id ?? this.company_id,
          header_image: header_image ?? this.header_image,
          header_image_status: header_image_status ?? this.header_image_status,
          header_text: header_text ?? this.header_text,
          header_text_status: header_text_status ?? this.header_text_status,
          footer_image: footer_image ?? this.footer_image,
          footer_image_status: footer_image_status ?? this.footer_image_status,
          footer_text: footer_text ?? this.footer_text,
          footer_text_status: footer_text_status ?? this.footer_text_status,
          promotion_detail_status: promotion_detail_status ?? this.promotion_detail_status,
          status: status ?? this.status,
          sync_status: sync_status ?? this.sync_status,
          created_at: created_at ?? this.created_at,
          updated_at: updated_at ?? this.updated_at,
          soft_delete: soft_delete ?? this.soft_delete);

  static Receipt fromJson(Map<String, Object?> json) => Receipt(
    receipt_sqlite_id: json[ReceiptFields.receipt_sqlite_id] as int?,
    receipt_id: json[ReceiptFields.receipt_id] as int?,
    branch_id: json[ReceiptFields.branch_id] as String?,
    company_id: json[ReceiptFields.company_id] as String?,
    header_image: json[ReceiptFields.header_image] as String?,
    header_image_status: json[ReceiptFields.header_image_status] as int?,
    header_text: json[ReceiptFields.header_text] as String?,
    header_text_status: json[ReceiptFields.header_text_status] as int?,
    footer_image: json[ReceiptFields.footer_image] as String?,
    footer_image_status: json[ReceiptFields.footer_image_status] as int?,
    footer_text: json[ReceiptFields.footer_text] as String?,
    footer_text_status: json[ReceiptFields.footer_text_status] as int?,
    promotion_detail_status: json[ReceiptFields.promotion_detail_status] as int?,
    status: json[ReceiptFields.status] as int?,
    sync_status: json[ReceiptFields.sync_status] as int?,
    created_at: json[ReceiptFields.created_at] as String?,
    updated_at: json[ReceiptFields.updated_at] as String?,
    soft_delete: json[ReceiptFields.soft_delete] as String?,
  );

  Map<String, Object?> toJson() => {
    ReceiptFields.receipt_sqlite_id: receipt_sqlite_id,
    ReceiptFields.receipt_id: receipt_id,
    ReceiptFields.branch_id: branch_id,
    ReceiptFields.company_id: company_id,
    ReceiptFields.header_image: header_image,
    ReceiptFields.header_image_status: header_image_status,
    ReceiptFields.header_text: header_text,
    ReceiptFields.header_text_status: header_text_status,
    ReceiptFields.footer_image: footer_image,
    ReceiptFields.footer_image_status: footer_image_status,
    ReceiptFields.footer_text: footer_text,
    ReceiptFields.footer_text_status: footer_text_status,
    ReceiptFields.promotion_detail_status: promotion_detail_status,
    ReceiptFields.status: status,
    ReceiptFields.sync_status: sync_status,
    ReceiptFields.created_at: created_at,
    ReceiptFields.updated_at: updated_at,
    ReceiptFields.soft_delete: soft_delete,
  };
}
