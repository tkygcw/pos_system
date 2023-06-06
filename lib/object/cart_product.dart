
import 'package:flutter/material.dart';
import 'package:pos_system/object/modifier_group.dart';
import 'package:pos_system/object/variant_group.dart';

import 'order_detail.dart';

class cartProductItem{
   String? branch_link_product_sqlite_id;
   String? product_name;
   String? category_id;
   String? category_name;
   String? price;
   int? quantity;
   List<ModifierGroup>? modifier ;
   List<VariantGroup>? variant ;
   String? remark;
   int? status = 0;
   String? order_cache_sqlite_id;
   String? order_cache_key;
   String? category_sqlite_id;
   Color? refColor = Colors.black;
   String? order_detail_sqlite_id;
   int? sequence = 0;
   bool? isRefund;
   String? base_price;
   String? first_cache_created_date_time;
   String? subtotal;
   String? first_cache_batch;
   String? first_cache_order_by;

   cartProductItem(
       {
         this.branch_link_product_sqlite_id,
         this.product_name,
         this.category_id,
         this.category_name,
         this.price,
         this.quantity,
         this.modifier,
         this.variant,
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
         this.subtotal,
         this.first_cache_batch,
         this.first_cache_order_by,
         this.refColor
       });

   static cartProductItem fromJson(Map<String, Object?> json) {
     var modJson = json['modifier'] as List;
     var variantJson = json['variant'] as List;
     List<ModifierGroup> modGroup = modJson.map((tagJson) => ModifierGroup.fromJson(tagJson)).toList();
     List<VariantGroup> variantGroup = variantJson.map((tagJson) => VariantGroup.fromJson(tagJson)).toList();
     return cartProductItem(
         branch_link_product_sqlite_id: json['branch_link_product_sqlite_id'] as String?,
         product_name: json['product_name'] as String?,
         category_id: json['category_id'] as String?,
         category_name: json['category_name'] as String?,
         price: json['price'] as String?,
         quantity: json['quantity'] as int?,
         modifier: modGroup,
         variant: variantGroup,
         remark: json['remark'] as String?,
         status: json['status'] as int?,
         order_cache_sqlite_id: json['orderCacheId'] as String?,
         order_cache_key: json['order_cache_key'] as String?,
         category_sqlite_id: json['category_sqlite_id'] as String,
         order_detail_sqlite_id: json['order_detail_sqlite_id'] as String,
         sequence: json['sequence'] as int?,
         isRefund: json['isRefund'] as bool?,
         base_price: json['base_price'] as String?,
         first_cache_created_date_time: json['first_cache_created_date_time'] as String?,
         subtotal: json['subtotal'] as String?,
         first_cache_batch: json['first_cache_batch'] as String?,
         first_cache_order_by: json['first_cache_order_by'] as String?,
         refColor: json['refColor'] as Color?
     );
   }

   Map<String, Object?> toJson() => {
     'branch_link_product_sqlite_id': branch_link_product_sqlite_id,
     'product_name': product_name,
     'category_id': category_id,
     'category_name': category_name,
     'category_sqlite_id': category_sqlite_id,
     'price': price,
     'quantity': quantity,
     'modifier': modifier,
     'variant': variant,
     'remark': remark,
     'status': status,
     'order_cache_sqlite_id': order_cache_sqlite_id,
     'order_cache_key': order_cache_key,
     'order_detail_sqlite_id': order_detail_sqlite_id,
     'sequence': sequence,
     'isRefund': isRefund,
     'base_price': base_price,
     'first_cache_created_date_time': first_cache_created_date_time,
     'subtotal': subtotal,
     'first_cache_batch': first_cache_batch,
     'first_cache_order_by': first_cache_order_by,
     'refColor': null
   };

}