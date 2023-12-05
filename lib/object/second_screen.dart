String? tableSecondScreen = 'tb_second_screen ';

class SecondScreenFields {
  static List<String> values = [
    second_screen_id,
    company_id,
    branch_id,
    name,
    sequence_number,
    created_at,
    soft_delete
  ];

  static String second_screen_id = 'id';
  static String company_id = 'company_id';
  static String branch_id = 'branch_id';
  static String name = 'name';
  static String sequence_number = 'sequence_number';
  static String created_at = 'created_at';
  static String soft_delete = 'soft_delete';
}

class SecondScreen{
  int? second_screen_id;
  String? company_id;
  String? branch_id;
  String? name;
  String? sequence_number;
  String? created_at;
  String? soft_delete;

  SecondScreen({
    this.second_screen_id,
    this.company_id,
    this.branch_id,
    this.name,
    this.sequence_number,
    this.created_at,
    this.soft_delete});

  SecondScreen copy({
    int? second_screen_id,
    String? company_id,
    String? branch_id,
    String? name,
    String? sequence_number,
    String? created_at,
    String? soft_delete,
  }) =>
      SecondScreen(
        second_screen_id: second_screen_id ?? this.second_screen_id,
        company_id: company_id ?? this.company_id,
        branch_id: branch_id ?? this.branch_id,
        name: name ?? this.name,
        sequence_number: sequence_number ?? this.sequence_number,
        created_at: created_at ?? this.created_at,
        soft_delete: soft_delete ?? this.soft_delete,
      );


  static SecondScreen fromJson(Map<String, Object?> json) => SecondScreen(
    second_screen_id: json[SecondScreenFields.second_screen_id] as int?,
    company_id: json[SecondScreenFields.company_id] as String?,
    branch_id: json[SecondScreenFields.branch_id] as String?,
    name: json[SecondScreenFields.name] as String?,
    sequence_number: json[SecondScreenFields.sequence_number] as String?,
    created_at: json[SecondScreenFields.created_at] as String?,
    soft_delete: json[SecondScreenFields.soft_delete] as String?,
  );

  Map<String, Object?> toJson() => {
    SecondScreenFields.second_screen_id: second_screen_id,
    SecondScreenFields.company_id: company_id,
    SecondScreenFields.branch_id: branch_id,
    SecondScreenFields.name: name,
    SecondScreenFields.sequence_number: sequence_number,
    SecondScreenFields.created_at: created_at,
    SecondScreenFields.soft_delete: soft_delete,
  };

}