String? tableModifierItem = 'tb_modifier_item';

class ModifierItemFields {
  static List<String> values = [
    mod_item_id,
    mod_group_id,
    name,
    price,
    sequence,
    quantity,
    isChecked,
    created_at,
    updated_at,
    soft_delete
  ];

  static String mod_item_id = 'mod_item_id';
  static String mod_group_id = 'mod_group_id';
  static String name = 'name';
  static String price = 'price';
  static String sequence = 'sequence';
  static String quantity = 'quantity';
  static String isChecked = 'isChecked';
  static String created_at = 'created_at';
  static String updated_at = 'updated_at';
  static String soft_delete = 'soft_delete';
}

class ModifierItem{
  int? mod_item_id;
  String? mod_group_id;
  String? name;
  String? price;
  int? sequence;
  String? quantity;
  String? created_at;
  String? updated_at;
  String? soft_delete;
  String? mod_status;
  bool? isChecked;

  ModifierItem(
      { this.mod_item_id,
        this.mod_group_id,
        this.name,
        this.price,
        this.sequence,
        this.quantity,
        this.created_at,
        this.updated_at,
        this.soft_delete,
        this.mod_status,
        this.isChecked });

  ModifierItem copy({
    int? mod_item_id,
    String? mod_group_id,
    String? name,
    String? price,
    int? sequence,
    String? quantity,
    String? created_at,
    String? updated_at,
    String? soft_delete,
  }) =>
      ModifierItem(
          mod_item_id: mod_item_id ?? this.mod_item_id,
          mod_group_id: mod_group_id ?? this.mod_group_id,
          name: name ?? this.name,
          price: price ?? this.price,
          sequence: sequence ?? this.sequence,
          quantity: quantity ?? this.quantity,
          created_at: created_at ?? this.created_at,
          updated_at: updated_at ?? this.updated_at,
          soft_delete: soft_delete ?? this.soft_delete);

  static ModifierItem fromJson(Map<String, Object?> json) => ModifierItem(
    mod_item_id: json[ModifierItemFields.mod_item_id] as int?,
    mod_group_id: json[ModifierItemFields.mod_group_id] as String?,
    name: json[ModifierItemFields.name] as String?,
    price: json[ModifierItemFields.price] as String?,
    sequence: json[ModifierItemFields.sequence] as int?,
    quantity: json[ModifierItemFields.quantity] as String?,
    created_at: json[ModifierItemFields.created_at] as String?,
    updated_at: json[ModifierItemFields.updated_at] as String?,
    soft_delete: json[ModifierItemFields.soft_delete] as String?,
    mod_status: json['mod_status'] as String?,
    isChecked: json['isChecked'] as bool?
  );

  Map<String, Object?> toJson() => {
    ModifierItemFields.mod_item_id: mod_item_id,
    ModifierItemFields.mod_group_id: mod_group_id,
    ModifierItemFields.name: name,
    ModifierItemFields.price: price,
    ModifierItemFields.sequence: sequence,
    ModifierItemFields.quantity: quantity,
    ModifierItemFields.created_at: created_at,
    ModifierItemFields.updated_at: updated_at,
    ModifierItemFields.soft_delete: soft_delete,
    'mod_status': mod_status,
    'isChecked': isChecked
  };

  Map<String, Object?> toJson2() => {
    ModifierItemFields.mod_item_id: mod_item_id,
    ModifierItemFields.mod_group_id: mod_group_id,
    ModifierItemFields.name: name,
    ModifierItemFields.price: price,
    ModifierItemFields.sequence: sequence,
    ModifierItemFields.quantity: quantity,
    ModifierItemFields.created_at: created_at,
    ModifierItemFields.updated_at: updated_at,
    ModifierItemFields.soft_delete: soft_delete,
  };

  Map<String, Object?> addToCartJSon() => {
    ModifierItemFields.name: name,
    ModifierItemFields.isChecked: isChecked,
  };
}
