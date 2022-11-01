String? tablePaymentType = 'tb_payment_type ';

class PaymentTypeFields {
  static List<String> values = [
    payment_type_sqlite_id,
    payment_type_id,
    name,
    type,
    iPay_code,
    sync_status,
    created_at,
    updated_at,
    soft_delete
  ];

  static String payment_type_sqlite_id = 'payment_type_sqlite_id';
  static String payment_type_id = 'payment_type_id';
  static String name = 'name';
  static String type = 'type';
  static String iPay_code = 'iPay_code';
  static String sync_status = 'sync_status';
  static String created_at = 'created_at';
  static String updated_at = 'updated_at';
  static String soft_delete = 'soft_delete';
}

class PaymentType{
  int? payment_type_sqlite_id;
  int? payment_type_id;
  String? name;
  int? type;
  String? iPay_code;
  int? sync_status;
  String? created_at;
  String? updated_at;
  String? soft_delete;

  PaymentType(
      {this.payment_type_sqlite_id,
        this.payment_type_id,
        this.name,
        this.type,
        this.iPay_code,
        this.sync_status,
        this.created_at,
        this.updated_at,
        this.soft_delete});

  PaymentType copy({
    int? payment_type_sqlite_id,
    int? payment_type_id,
    String? name,
    int? type,
    String? iPay_code,
    int? sync_status,
    String? created_at,
    String? updated_at,
    String? soft_delete,
  }) =>
      PaymentType(
          payment_type_sqlite_id: payment_type_sqlite_id ?? this.payment_type_sqlite_id,
          payment_type_id: payment_type_id ?? this.payment_type_id,
          name: name ?? this.name,
          type: type ?? this.type,
          iPay_code: iPay_code ?? this.iPay_code,
          sync_status: sync_status ?? this.sync_status,
          created_at: created_at ?? this.created_at,
          updated_at: updated_at ?? this.updated_at,
          soft_delete: soft_delete ?? this.soft_delete);

  static PaymentType fromJson(Map<String, Object?> json) => PaymentType(
    payment_type_sqlite_id: json[PaymentTypeFields.payment_type_sqlite_id] as int?,
    payment_type_id: json[PaymentTypeFields.payment_type_id] as int?,
    name: json[PaymentTypeFields.name] as String?,
    type: json[PaymentTypeFields.type] as int?,
    iPay_code: json[PaymentTypeFields.iPay_code] as String?,
    sync_status: json[PaymentTypeFields.sync_status] as int?,
    created_at: json[PaymentTypeFields.created_at] as String?,
    updated_at: json[PaymentTypeFields.updated_at] as String?,
    soft_delete: json[PaymentTypeFields.soft_delete] as String?,
  );

  Map<String, Object?> toJson() => {
    PaymentTypeFields.payment_type_sqlite_id: payment_type_sqlite_id,
    PaymentTypeFields.payment_type_id: payment_type_id,
    PaymentTypeFields.name: name,
    PaymentTypeFields.type: type,
    PaymentTypeFields.iPay_code: iPay_code,
    PaymentTypeFields.sync_status: sync_status,
    PaymentTypeFields.created_at: created_at,
    PaymentTypeFields.updated_at: updated_at,
    PaymentTypeFields.soft_delete: soft_delete,
  };
}
