String? tableCustomer = 'tb_customer';

class CustomerFields {
  static List<String> values = [
    customer_sqlite_id,
    customer_id,
    company_id,
    name,
    phone,
    email,
    address,
    note,
    created_at,
    updated_at,
    soft_delete
  ];

  static String customer_sqlite_id = 'customer_sqlite_id';
  static String customer_id = 'customer_id';
  static String company_id = 'company_id';
  static String name = 'name';
  static String phone = 'phone';
  static String email = 'email';
  static String address = 'address';
  static String note = 'note';
  static String created_at = 'created_at';
  static String updated_at = 'updated_at';
  static String soft_delete = 'soft_delete';
}

class Customer {
  int? customer_sqlite_id;
  int? customer_id;
  String? company_id;
  String? name;
  String? phone;
  String? email;
  String? address;
  String? note;
  String? created_at;
  String? updated_at;
  String? soft_delete;

  Customer(
      {this.customer_sqlite_id,
      this.customer_id,
      this.company_id,
      this.name,
      this.phone,
      this.email,
      this.address,
      this.note,
      this.created_at,
      this.updated_at,
      this.soft_delete});

  Customer copy({
    int? customer_sqlite_id,
    int? customer_id,
    String? company_id,
    String? name,
    String? phone,
    String? email,
    String? address,
    String? note,
    String? created_at,
    String? updated_at,
    String? soft_delete,
  }) =>
      Customer(
          customer_sqlite_id: customer_sqlite_id ?? this.customer_sqlite_id,
          customer_id: customer_id ?? this.customer_id,
          company_id: company_id ?? this.company_id,
          name: name ?? this.name,
          phone: phone ?? this.phone,
          email: email ?? this.email,
          address: address ?? this.address,
          note: note ?? this.note,
          created_at: created_at ?? this.created_at,
          updated_at: updated_at ?? this.updated_at,
          soft_delete: soft_delete ?? this.soft_delete);

  static Customer fromJson(Map<String, Object?> json) => Customer(
        customer_sqlite_id: json[CustomerFields.customer_sqlite_id] as int?,
        customer_id: json[CustomerFields.customer_id] as int?,
        company_id: json[CustomerFields.company_id] as String?,
        name: json[CustomerFields.name] as String?,
        phone: json[CustomerFields.phone] as String?,
        email: json[CustomerFields.email] as String?,
        address: json[CustomerFields.address] as String?,
        note: json[CustomerFields.note] as String?,
        created_at: json[CustomerFields.created_at] as String?,
        updated_at: json[CustomerFields.updated_at] as String?,
        soft_delete: json[CustomerFields.soft_delete] as String?,
      );

  Map<String, Object?> toJson() => {
        CustomerFields.customer_sqlite_id: customer_sqlite_id,
        CustomerFields.customer_id: customer_id,
        CustomerFields.company_id: company_id,
        CustomerFields.name: name,
        CustomerFields.phone: phone,
        CustomerFields.email: email,
        CustomerFields.address: address,
        CustomerFields.note: note,
        CustomerFields.created_at: created_at,
        CustomerFields.updated_at: updated_at,
        CustomerFields.soft_delete: soft_delete,
      };
}
