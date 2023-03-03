import 'dart:convert';

import 'package:pos_system/object/modifier_item.dart';

import 'order_modifier_detail.dart';

String? tableModifierGroup = 'tb_modifier_group';

class ModifierGroupFields {
  static List<String> values = [
    mod_group_id,
    company_id,
    name,
    dining_id,
    compulsory,
    created_at,
    updated_at,
    soft_delete
  ];

  static String mod_group_id = 'mod_group_id';
  static String company_id = 'company_id';
  static String name = 'name';
  static String dining_id = 'dining_id';
  static String compulsory = 'compulsory';
  static String created_at = 'created_at';
  static String updated_at = 'updated_at';
  static String soft_delete = 'soft_delete';
  static String modifier_item = 'modifier_item';
}

class ModifierGroup{
  int? mod_group_id;
  String? company_id;
  String? name;
  String? dining_id;
  String? compulsory;
  int? modifier_item_id;
  late List<ModifierItem> modifierChild;
  String? created_at;
  String? updated_at;
  String? soft_delete;
  int? item_sum;
  double? net_sales;
  List<OrderModifierDetail> modDetailList = [];

  ModifierGroup(
      {this.mod_group_id,
        this.company_id,
        this.modifier_item_id,
        required this.modifierChild,
        this.dining_id,
        this.compulsory,
        this.name,
        this.created_at,
        this.updated_at,
        this.soft_delete,
        this.item_sum,
        this.net_sales
      });

  ModifierGroup copy({
    int? mod_group_id,
    String? company_id,
    String? name,
    String? dining_id,
    String? compulsory,
    String? created_at,
    String? updated_at,
    String? soft_delete,
  }) =>
      ModifierGroup(
          mod_group_id: mod_group_id ?? this.mod_group_id,
          company_id: company_id ?? this.company_id,
          name: name ?? this.name,
          dining_id: dining_id ?? this.dining_id,
          compulsory: compulsory ?? this.compulsory,
          created_at: created_at ?? this.created_at,
          updated_at: updated_at ?? this.updated_at,
          soft_delete: soft_delete ?? this.soft_delete, modifierChild: []);

  static ModifierGroup fromJson(Map<String, Object?> json) => ModifierGroup(
    mod_group_id: json[ModifierGroupFields.mod_group_id] as int?,
    company_id: json[ModifierGroupFields.company_id] as String?,
    name: json[ModifierGroupFields.name] as String?,
    dining_id: json[ModifierGroupFields.dining_id] as String?,
    compulsory: json[ModifierGroupFields.compulsory] as String?,
    created_at: json[ModifierGroupFields.created_at] as String?,
    updated_at: json[ModifierGroupFields.updated_at] as String?,
    soft_delete: json[ModifierGroupFields.soft_delete] as String?,
    modifierChild: [],
    item_sum: json['item_sum'] as int?,
    net_sales: json['net_sales'] as double?
  );

  Map<String, Object?> toJson() => {
    ModifierGroupFields.mod_group_id: mod_group_id,
    ModifierGroupFields.company_id: company_id,
    ModifierGroupFields.name: name,
    ModifierGroupFields.dining_id: dining_id,
    ModifierGroupFields.compulsory: compulsory,
    ModifierGroupFields.created_at: created_at,
    ModifierGroupFields.updated_at: updated_at,
    ModifierGroupFields.soft_delete: soft_delete,
  };

  Map addToCartJSon() => {
    ModifierGroupFields.mod_group_id: mod_group_id,
    ModifierGroupFields.name: name,
    ModifierGroupFields.modifier_item: jsonEncode(modifierChild.map((e) => e.addToCartJSon()).toList()),
  };
}
