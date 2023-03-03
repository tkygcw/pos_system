String? tableDiningOption = 'tb_dining_option';

class DiningOptionFields {
  static List<String> values = [
    dining_id,
    name,
    created_at,
    updated_at,
    soft_delete
  ];

  static String dining_id = 'dining_id';
  static String name = 'name';
  static String created_at = 'created_at';
  static String updated_at = 'updated_at';
  static String soft_delete = 'soft_delete';
}

class DiningOption{
  int? dining_id;
  String? name;
  String? created_at;
  String? updated_at;
  String? soft_delete;

  DiningOption(
      {this.dining_id,
        this.name,
        this.created_at,
        this.updated_at,
        this.soft_delete});

  DiningOption copy({
    int? dining_id,
    String? name,
    String? created_at,
    String? updated_at,
    String? soft_delete,
  }) =>
      DiningOption(
          dining_id: dining_id ?? this.dining_id,
          name: name ?? this.name,
          created_at: created_at ?? this.created_at,
          updated_at: updated_at ?? this.updated_at,
          soft_delete: soft_delete ?? this.soft_delete);

  static DiningOption fromJson(Map<String, Object?> json) => DiningOption(
    dining_id: json[DiningOptionFields.dining_id] as int?,
    name: json[DiningOptionFields.name] as String?,
    created_at: json[DiningOptionFields.created_at] as String?,
    updated_at: json[DiningOptionFields.updated_at] as String?,
    soft_delete: json[DiningOptionFields.soft_delete] as String?,
  );

  Map<String, Object?> toJson() => {
    DiningOptionFields.dining_id: dining_id,
    DiningOptionFields.name: name,
    DiningOptionFields.created_at: created_at,
    DiningOptionFields.updated_at: updated_at,
    DiningOptionFields.soft_delete: soft_delete,
  };
}
