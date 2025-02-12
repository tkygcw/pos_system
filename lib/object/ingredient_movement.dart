String? tableIngredientMovement = 'tb_ingredient_movement';

class IngredientMovementFields {
  static List<String> values = [
    ingredient_movement_sqlite_id,
    ingredient_movement_id,
    ingredient_movement_key,
    branch_id,
    ingredient_company_link_branch_id,
    order_cache_key,
    order_detail_key,
    order_modifier_detail_key,
    type,
    movement,
    source,
    remark,
    calculate_status,
    sync_status,
    created_at,
    updated_at,
    soft_delete,
  ];

  static String ingredient_movement_sqlite_id = 'ingredient_movement_sqlite_id';
  static String ingredient_movement_id = 'ingredient_movement_id';
  static String ingredient_movement_key = 'ingredient_movement_key';
  static String branch_id = 'branch_id';
  static String ingredient_company_link_branch_id = 'ingredient_company_link_branch_id';
  static String order_cache_key = 'order_cache_key';
  static String order_detail_key = 'order_detail_key';
  static String order_modifier_detail_key = 'order_modifier_detail_key';
  static String type = 'type';
  static String movement = 'movement';
  static String source = 'source';
  static String remark = 'remark';
  static String calculate_status = 'calculate_status';
  static String sync_status = 'sync_status';
  static String created_at = 'created_at';
  static String updated_at = 'updated_at';
  static String soft_delete = 'soft_delete';
}

class IngredientMovement {
  int? ingredient_movement_sqlite_id;
  int? ingredient_movement_id;
  String? ingredient_movement_key;
  String? branch_id;
  String? ingredient_company_link_branch_id;
  String? order_cache_key;
  String? order_detail_key;
  String? order_modifier_detail_key;
  int? type;
  String? movement;
  int? source;
  String? remark;
  int? calculate_status;
  int? sync_status;
  String? created_at;
  String? updated_at;
  String? soft_delete;

  IngredientMovement(
      {this.ingredient_movement_sqlite_id,
        this.ingredient_movement_id,
        this.ingredient_movement_key,
        this.branch_id,
        this.ingredient_company_link_branch_id,
        this.order_cache_key,
        this.order_detail_key,
        this.order_modifier_detail_key,
        this.type,
        this.movement,
        this.source,
        this.remark,
        this.calculate_status,
        this.sync_status,
        this.created_at,
        this.updated_at,
        this.soft_delete,
      });

  IngredientMovement copy({
    int? ingredient_movement_sqlite_id,
    int? ingredient_movement_id,
    String? ingredient_movement_key,
    String? branch_id,
    String? ingredient_company_link_branch_id,
    String? order_cache_key,
    String? order_detail_key,
    String? order_modifier_detail_key,
    int? type,
    String? movement,
    int? source,
    String? remark,
    int? calculate_status,
    int? sync_status,
    String? created_at,
    String? updated_at,
    String? soft_delete,
  }) =>
      IngredientMovement(
        ingredient_movement_sqlite_id: ingredient_movement_sqlite_id ?? this.ingredient_movement_sqlite_id,
        ingredient_movement_id: ingredient_movement_id ?? this.ingredient_movement_id,
        ingredient_movement_key: ingredient_movement_key ?? this.ingredient_movement_key,
        branch_id: branch_id ?? this.branch_id,
        ingredient_company_link_branch_id: ingredient_company_link_branch_id ?? this.ingredient_company_link_branch_id,
        order_cache_key: order_cache_key ?? this.order_cache_key,
        order_detail_key: order_detail_key ?? this.order_detail_key,
        order_modifier_detail_key: order_modifier_detail_key ?? this.order_modifier_detail_key,
        type: type ?? this.type,
        movement: movement ?? this.movement,
        source: source ?? this.source,
        remark: remark ?? this.remark,
        calculate_status: calculate_status ?? this.calculate_status,
        sync_status: sync_status ?? this.sync_status,
        created_at: created_at ?? this.created_at,
        updated_at: updated_at ?? this.updated_at,
        soft_delete: soft_delete ?? this.soft_delete,
      );

  static IngredientMovement fromJson(Map<String, Object?> json) => IngredientMovement(
    ingredient_movement_sqlite_id: json[IngredientMovementFields.ingredient_movement_sqlite_id] as int?,
    ingredient_movement_id: json[IngredientMovementFields.ingredient_movement_id] as int?,
    ingredient_movement_key: json[IngredientMovementFields.ingredient_movement_key] as String?,
    branch_id: json[IngredientMovementFields.branch_id] as String?,
    ingredient_company_link_branch_id: json[IngredientMovementFields.ingredient_company_link_branch_id] as String?,
    order_cache_key: json[IngredientMovementFields.order_cache_key] as String?,
    order_detail_key: json[IngredientMovementFields.order_detail_key] as String?,
    order_modifier_detail_key: json[IngredientMovementFields.order_modifier_detail_key] as String?,
    type: json[IngredientMovementFields.type] as int?,
    movement: json[IngredientMovementFields.movement] as String?,
    source: json[IngredientMovementFields.source] as int?,
    remark: json[IngredientMovementFields.remark] as String?,
    calculate_status: json[IngredientMovementFields.calculate_status] as int?,
    sync_status: json[IngredientMovementFields.sync_status] as int?,
    created_at: json[IngredientMovementFields.created_at] as String?,
    updated_at: json[IngredientMovementFields.updated_at] as String?,
    soft_delete: json[IngredientMovementFields.soft_delete] as String?,
  );

  Map<String, Object?> toJson() => {
    IngredientMovementFields.ingredient_movement_sqlite_id: ingredient_movement_sqlite_id,
    IngredientMovementFields.ingredient_movement_id: ingredient_movement_id,
    IngredientMovementFields.ingredient_movement_key: ingredient_movement_key,
    IngredientMovementFields.branch_id: branch_id,
    IngredientMovementFields.ingredient_company_link_branch_id: ingredient_company_link_branch_id,
    IngredientMovementFields.order_cache_key: order_cache_key,
    IngredientMovementFields.order_detail_key: order_detail_key,
    IngredientMovementFields.order_modifier_detail_key: order_modifier_detail_key,
    IngredientMovementFields.type: type,
    IngredientMovementFields.movement: movement,
    IngredientMovementFields.source: source,
    IngredientMovementFields.remark: remark,
    IngredientMovementFields.calculate_status: calculate_status,
    IngredientMovementFields.sync_status: sync_status,
    IngredientMovementFields.created_at: created_at,
    IngredientMovementFields.updated_at: updated_at,
    IngredientMovementFields.soft_delete: soft_delete,
  };
}
