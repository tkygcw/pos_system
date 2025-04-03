
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:pos_system/object/branch_link_product.dart';
import 'package:pos_system/object/modifier_group.dart';
import 'package:pos_system/object/modifier_item.dart';
import 'package:pos_system/object/variant_group.dart';

import 'order_modifier_detail.dart';

class cartProductItem{
   int? branch_link_product_id;
   String? branch_link_product_sqlite_id;
   String? product_name;
   String? category_id;
   String? category_name;
   String? price;
   num? quantity;
   int? checkedModifierLength;
   List<ModifierItem>? checkedModifierItem;
   List<ModifierGroup>? modifier;
   List<VariantGroup>? variant;
   String? productVariantName;
   String? remark;
   int? status = 0;
   String? order_cache_sqlite_id;
   String? order_cache_key;
   String? category_sqlite_id;
   Color? refColor = Colors.black;
   String? order_key;
   String? order_detail_sqlite_id;
   int? sequence = 0;
   bool? isRefund;
   String? base_price;
   String? first_cache_created_date_time;
   String? first_cache_other_order_key;
   String? subtotal;
   String? first_cache_batch;
   String? first_cache_order_by;
   List<OrderModifierDetail>? orderModifierDetail;
   String? unit;
   String? per_quantity_unit;
   String? order_queue;
   String? custom_table_number;
   int? allow_ticket;
   int? ticket_count;
   String? ticket_exp;
   String? product_sku;
   Map<String, double>? promo = {};
   Map<String, double>? charge = {};
   Map<String, double>? tax = {};

   cartProductItem(
       {
         this.branch_link_product_id,
         this.branch_link_product_sqlite_id,
         this.product_name,
         this.category_id,
         this.category_name,
         this.price,
         this.quantity,
         this.checkedModifierLength,
         this.checkedModifierItem,
         this.modifier,
         this.variant,
         this.productVariantName,
         this.remark,
         this.status,
         this.order_cache_sqlite_id,
         this.order_cache_key,
         this.category_sqlite_id,
         this.order_detail_sqlite_id,
         this.sequence,
         this.isRefund,
         this.base_price,
         this.first_cache_created_date_time,
         this.first_cache_other_order_key,
         this.subtotal,
         this.first_cache_batch,
         this.first_cache_order_by,
         this.refColor,
         this.order_key,
         this.orderModifierDetail,
         this.unit,
         this.per_quantity_unit,
         this.order_queue,
         this.custom_table_number,
         this.allow_ticket,
         this.ticket_count,
         this.ticket_exp,
         this.product_sku,
         this.promo,
         this.charge,
         this.tax,
       });

   static cartProductItem fromJson(Map<String, Object?> json) {
     var modItemJson = json['checkedModifierItem'] as List?;
     var modJson = json['modifier'] as List?;
     var variantJson = json['variant'] as List?;
     var orderModDetail = json['orderModifierDetail'] as List?;
     List<ModifierItem>? modItem = modItemJson != null ? modItemJson.map((tagJson) => ModifierItem.fromJson(tagJson)).toList() : null;
     List<ModifierGroup>? modGroup = modJson != null ? modJson.map((tagJson) => ModifierGroup.fromJson(tagJson)).toList() : null;
     List<VariantGroup>? variantGroup = variantJson != null ? variantJson.map((tagJson) => VariantGroup.fromJson(tagJson)).toList() : null;
     List<OrderModifierDetail>? orderModifierDetailList = orderModDetail != null ? orderModDetail.map((tagJson) => OrderModifierDetail.fromJson(tagJson)).toList() : null;
     return cartProductItem(
         branch_link_product_id: json['branch_link_product_id'] as int?,
         branch_link_product_sqlite_id: json['branch_link_product_sqlite_id'] as String?,
         product_name: json['product_name'] as String?,
         category_id: json['category_id'] as String?,
         category_name: json['category_name'] as String?,
         price: json['price'] as String?,
         quantity: json['quantity'] as num?,
         checkedModifierLength: json['checkedModifierLength'] as int?,
         checkedModifierItem: modItem,
         modifier: modGroup,
         variant: variantGroup,
         productVariantName: json['productVariantName'] as String?,
         remark: json['remark'] as String?,
         status: json['status'] as int?,
         order_cache_sqlite_id: json['orderCacheId'] as String?,
         order_cache_key: json['order_cache_key'] as String?,
         category_sqlite_id: json['category_sqlite_id'] as String?,
         order_detail_sqlite_id: json['order_detail_sqlite_id'] as String?,
         sequence: json['sequence'] as int?,
         isRefund: json['isRefund'] as bool?,
         base_price: json['base_price'] as String?,
         first_cache_created_date_time: json['first_cache_created_date_time'] as String?,
         first_cache_other_order_key: json['first_cache_other_order_key'] as String?,
         subtotal: json['subtotal'] as String?,
         first_cache_batch: json['first_cache_batch'] as String?,
         first_cache_order_by: json['first_cache_order_by'] as String?,
         refColor: json['refColor'] as Color?,
         order_key: json['order_key'] as String?,
         orderModifierDetail: orderModifierDetailList,
         unit: json['unit'] as String?,
         per_quantity_unit: json['per_quantity_unit'] as String?,
         order_queue: json['order_queue'] as String?,
         custom_table_number: json['custom_table_number'] as String?,
         allow_ticket: json['allow_ticket'] as int?,
         ticket_count: json['ticket_count'] as int?,
         ticket_exp: json['ticket_exp'] as String?,
         product_sku: json['product_sku'] as String?,
         promo: json['promo'] == null
             ? {}
             : (json['promo'] is String)
             ? (json['promo'].toString().trim().isNotEmpty
             ? Map<String, double>.from(jsonDecode(json['promo'] as String).map(
                 (key, value) => MapEntry(key as String, (value as num).toDouble())))
             : {})
             : (json['promo'] is Map)
             ? Map<String, double>.from((json['promo'] as Map).map(
                 (key, value) => MapEntry(key as String, (value as num).toDouble())))
             : {},
         charge: json['charge'] == null
             ? {"a": 1}
             : (json['charge'] is String)
             ? (json['charge'].toString().trim().isNotEmpty
             ? Map<String, double>.from(jsonDecode(json['charge'] as String).map(
                 (key, value) => MapEntry(key as String, (value as num).toDouble())))
             : {"a": 2})
             : (json['charge'] is Map)
             ? Map<String, double>.from((json['charge'] as Map).map(
                 (key, value) => MapEntry(key as String, (value as num).toDouble())))
             : {"a": 3},
         tax: json['tax'] == null
             ? {}
             : (json['tax'] is String)
             ? (json['tax'].toString().trim().isNotEmpty
             ? Map<String, double>.from(jsonDecode(json['tax'] as String).map(
                 (key, value) => MapEntry(key as String, (value as num).toDouble())))
             : {})
             : (json['tax'] is Map)
             ? Map<String, double>.from((json['tax'] as Map).map(
                 (key, value) => MapEntry(key as String, (value as num).toDouble())))
             : {},
     );
   }

   Map<String, Object?> toJson() => {
     'branch_link_product_id': branch_link_product_id,
     'branch_link_product_sqlite_id': branch_link_product_sqlite_id,
     'product_name': product_name,
     'category_id': category_id,
     'category_name': category_name,
     'category_sqlite_id': category_sqlite_id,
     'price': price,
     'quantity': quantity,
     'checkedModifierLength': checkedModifierLength,
     'checkedModifierItem': checkedModifierItem,
     'modifier': modifier,
     'variant': variant,
     'productVariantName': productVariantName,
     'remark': remark,
     'status': status,
     'order_cache_sqlite_id': order_cache_sqlite_id,
     'order_cache_key': order_cache_key,
     'order_detail_sqlite_id': order_detail_sqlite_id,
     'sequence': sequence,
     'isRefund': isRefund,
     'base_price': base_price,
     'first_cache_created_date_time': first_cache_created_date_time,
     'first_cache_other_order_key': first_cache_other_order_key,
     'subtotal': subtotal,
     'first_cache_batch': first_cache_batch,
     'first_cache_order_by': first_cache_order_by,
     'refColor': null,
     'order_key': order_key,
     'orderModifierDetail': orderModifierDetail,
     'unit': unit,
     'per_quantity_unit': per_quantity_unit,
     'order_queue': order_queue,
     'custom_table_number': custom_table_number,
     'allow_ticket': allow_ticket,
     'ticket_count': ticket_count,
     'ticket_exp': ticket_exp,
     'product_sku': product_sku,
     'promo': promo,
     'charge': charge,
     'tax': tax,
   };

}