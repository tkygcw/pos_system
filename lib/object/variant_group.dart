import 'dart:convert';

import 'package:pos_system/object/variant_item.dart';

String? tableVariantGroup = 'tb_variant_group ';

class VariantGroupFields {
  static List<String> values = [
    variant_group_sqlite_id,
    variant_group_id,
    product_id,
    product_sqlite_id,
    name,
    sync_status,
    created_at,
    updated_at,
    soft_delete
  ];

  static String variant_group_sqlite_id = 'variant_group_sqlite_id';
  static String variant_group_id = 'variant_group_id';
  static String product_id = 'product_id';
  static String product_sqlite_id = 'product_sqlite_id';
  static String name = 'name';
  static String sync_status = 'sync_status';
  static String created_at = 'created_at';
  static String updated_at = 'updated_at';
  static String soft_delete = 'soft_delete';
  static String variant_item = 'variant_item';
}

class VariantGroup {
  int? variant_group_sqlite_id;
  int? variant_group_id;
  int? variant_item_id;
  int? variant_item_sqlite_id;
  List<VariantItem>? child;
  String? product_id;
  String? product_sqlite_id;
  String? name;
  int? sync_status;
  String? created_at;
  String? updated_at;
  String? soft_delete;

  VariantGroup(
      {this.variant_group_sqlite_id,
      this.variant_group_id,
      this.variant_item_id,
      this.variant_item_sqlite_id,
      this.child,
      this.product_id,
      this.product_sqlite_id,
      this.name,
      this.sync_status,
      this.created_at,
      this.updated_at,
      this.soft_delete});

  VariantGroup copy({
    int? variant_group_sqlite_id,
    int? variant_group_id,
    String? product_id,
    String? product_sqlite_id,
    String? name,
    int? sync_status,
    String? created_at,
    String? updated_at,
    String? soft_delete,
  }) =>
      VariantGroup(
          variant_group_sqlite_id: variant_group_sqlite_id ?? this.variant_group_sqlite_id,
          variant_group_id: variant_group_id ?? this.variant_group_id,
          product_id: product_id ?? this.product_id,
          product_sqlite_id: product_sqlite_id ?? this.product_sqlite_id,
          name: name ?? this.name,
          sync_status: sync_status ?? this.sync_status,
          created_at: created_at ?? this.created_at,
          updated_at: updated_at ?? this.updated_at,
          soft_delete: soft_delete ?? this.soft_delete,
      );

  // static VariantGroup fromJson(Map<String, Object?> json) => VariantGroup(
  //       variant_group_sqlite_id: json[VariantGroupFields.variant_group_sqlite_id] as int?,
  //       variant_group_id: json[VariantGroupFields.variant_group_id] as int?,
  //       product_id: json[VariantGroupFields.product_id] as String?,
  //       product_sqlite_id: json[VariantGroupFields.product_sqlite_id] as String?,
  //       name: json[VariantGroupFields.name] as String?,
  //       sync_status: json[VariantGroupFields.sync_status] as int?,
  //       created_at: json[VariantGroupFields.created_at] as String?,
  //       updated_at: json[VariantGroupFields.updated_at] as String?,
  //       soft_delete: json[VariantGroupFields.soft_delete] as String?,
  //       child: [],
  //     );

  static VariantGroup fromJson(Map<String, Object?> json) {
    var childJson = json['child'] as List?;
    List<VariantItem>? childList = childJson != null ? childJson.map((json) => VariantItem.fromJson(json)).toList() : null;
    return VariantGroup(
      variant_group_sqlite_id: json[VariantGroupFields.variant_group_sqlite_id] as int?,
      variant_group_id: json[VariantGroupFields.variant_group_id] as int?,
      product_id: json[VariantGroupFields.product_id] as String?,
      product_sqlite_id: json[VariantGroupFields.product_sqlite_id] as String?,
      name: json[VariantGroupFields.name] as String?,
      sync_status: json[VariantGroupFields.sync_status] as int?,
      created_at: json[VariantGroupFields.created_at] as String?,
      updated_at: json[VariantGroupFields.updated_at] as String?,
      soft_delete: json[VariantGroupFields.soft_delete] as String?,
      child: childList,
      variant_item_sqlite_id: json['variant_item_sqlite_id'] as int?
    );
  }

  // Map<String, Object?> toJson() => {
  //   VariantGroupFields.variant_group_sqlite_id: variant_group_sqlite_id,
  //   VariantGroupFields.variant_group_id: variant_group_id,
  //   VariantGroupFields.product_id: product_id,
  //   VariantGroupFields.product_sqlite_id: product_sqlite_id,
  //   VariantGroupFields.name: name,
  //   VariantGroupFields.sync_status: sync_status,
  //   VariantGroupFields.created_at: created_at,
  //   VariantGroupFields.updated_at: updated_at,
  //   VariantGroupFields.soft_delete: soft_delete,
  // };

  Map toJson() {
    List? variantChild = this.child != null ? this.child?.map((i) => i.toJson()).toList() : null;
    return {
      VariantGroupFields.variant_group_sqlite_id: variant_group_sqlite_id,
      VariantGroupFields.variant_group_id: variant_group_id,
      VariantGroupFields.product_id: product_id,
      VariantGroupFields.product_sqlite_id: product_sqlite_id,
      VariantGroupFields.name: name,
      VariantGroupFields.sync_status: sync_status,
      VariantGroupFields.created_at: created_at,
      VariantGroupFields.updated_at: updated_at,
      VariantGroupFields.soft_delete: soft_delete,
      'child': variantChild,
      'variant_item_sqlite_id': variant_item_sqlite_id
    };
  }

  // Map addToCartJSon() => {
  //       VariantGroupFields.variant_group_sqlite_id: variant_group_sqlite_id,
  //       VariantGroupFields.variant_group_id: variant_group_id,
  //       VariantGroupFields.name: name,
  //       VariantGroupFields.variant_item:
  //           jsonEncode(child.map((e) => e.addToCartJSon()).toList()),
  //     };
}
