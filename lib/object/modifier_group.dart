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
    sequence_number,
    created_at,
    updated_at,
    soft_delete
  ];

  static String mod_group_id = 'mod_group_id';
  static String company_id = 'company_id';
  static String name = 'name';
  static String dining_id = 'dining_id';
  static String compulsory = 'compulsory';
  static String sequence_number = 'sequence_number';
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
  List<ModifierItem>? modifierChild;
  String? sequence_number;
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
        this.modifierChild,
        this.dining_id,
        this.compulsory,
        this.name,
        this.sequence_number,
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
    String? sequence_number,
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
          sequence_number: sequence_number ?? this.sequence_number,
          created_at: created_at ?? this.created_at,
          updated_at: updated_at ?? this.updated_at,
          soft_delete: soft_delete ?? this.soft_delete);

  // static ModifierGroup fromJson(Map<String, Object?> json) => ModifierGroup(
  //   mod_group_id: json[ModifierGroupFields.mod_group_id] as int?,
  //   company_id: json[ModifierGroupFields.company_id] as String?,
  //   name: json[ModifierGroupFields.name] as String?,
  //   dining_id: json[ModifierGroupFields.dining_id] as String?,
  //   compulsory: json[ModifierGroupFields.compulsory] as String?,
  //   created_at: json[ModifierGroupFields.created_at] as String?,
  //   updated_at: json[ModifierGroupFields.updated_at] as String?,
  //   soft_delete: json[ModifierGroupFields.soft_delete] as String?,
  //   modifierChild: [],
  //   item_sum: json['item_sum'] as int?,
  //   net_sales: json['net_sales'] as double?
  // );

  static ModifierGroup fromJson(Map<String, Object?> json) {
    var childJson = json['modifierChild'] as List?;
    List<ModifierItem>? childList = childJson != null ? childJson.map((json) => ModifierItem.fromJson(json)).toList() : null;
    return ModifierGroup(
        mod_group_id: json[ModifierGroupFields.mod_group_id] as int?,
        company_id: json[ModifierGroupFields.company_id] as String?,
        name: json[ModifierGroupFields.name] as String?,
        dining_id: json[ModifierGroupFields.dining_id] as String?,
        compulsory: json[ModifierGroupFields.compulsory] as String?,
        sequence_number: json[ModifierGroupFields.sequence_number] as String?,
        created_at: json[ModifierGroupFields.created_at] as String?,
        updated_at: json[ModifierGroupFields.updated_at] as String?,
        soft_delete: json[ModifierGroupFields.soft_delete] as String?,
        modifierChild: childList,
        item_sum: json['item_sum'] as int?,
        net_sales: json['net_sales'] as double?
    );
  }
  Map toJson() {
    List? mod_child = this.modifierChild != null ? this.modifierChild?.map((i) => i.toJson()).toList() : null;
    return {
      ModifierGroupFields.mod_group_id: mod_group_id,
      ModifierGroupFields.company_id: company_id,
      ModifierGroupFields.name: name,
      ModifierGroupFields.dining_id: dining_id,
      ModifierGroupFields.compulsory: compulsory,
      ModifierGroupFields.sequence_number: sequence_number,
      ModifierGroupFields.created_at: created_at,
      ModifierGroupFields.updated_at: updated_at,
      ModifierGroupFields.soft_delete: soft_delete,
      'modifierChild': mod_child
    };
  }

  Map<String, Object?> toJson2() => {
    ModifierGroupFields.mod_group_id: mod_group_id,
    ModifierGroupFields.company_id: company_id,
    ModifierGroupFields.name: name,
    ModifierGroupFields.dining_id: dining_id,
    ModifierGroupFields.compulsory: compulsory,
    ModifierGroupFields.sequence_number: sequence_number,
    ModifierGroupFields.created_at: created_at,
    ModifierGroupFields.updated_at: updated_at,
    ModifierGroupFields.soft_delete: soft_delete,
  };

  // Map addToCartJSon() => {
  //   ModifierGroupFields.mod_group_id: mod_group_id,
  //   ModifierGroupFields.name: name,
  //   ModifierGroupFields.modifier_item: jsonEncode(modifierChild.map((e) => e.addToCartJSon()).toList()),
  // };
}
