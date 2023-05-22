
import 'package:flutter/material.dart';
import 'package:pos_system/object/modifier_group.dart';
import 'package:pos_system/object/variant_group.dart';

import 'order_detail.dart';

class cartProductItem{
   String branchProduct_id = '';
   String name ='';
   String category_id = '';
   String? category_sqlite_id;
   String price ='';
   int quantity = 1;
   late List<ModifierGroup> modifier ;
   late List<VariantGroup> variant ;
   String remark='';
   int status = 0;
   String? orderCacheId;
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
       String branchProduct_id,
       String name,
       String category_id,
       String price,
       int quantity,
       List<ModifierGroup> modifier,
       List<VariantGroup> variant,
       String remark,
       int status,
       String? orderCacheId,
       {category_sqlite_id,
         order_detail_sqlite_id,
         sequence,
         this.isRefund,
         this.base_price,
         this.first_cache_created_date_time,
         this.subtotal,
         this.first_cache_batch,
         this.first_cache_order_by,
         this.refColor
       })
   {
       this.branchProduct_id = branchProduct_id;
       this.name = name;
       this.category_id = category_id;
       this.category_sqlite_id = category_sqlite_id;
       this.price = price;
       this.quantity = quantity;
       this.modifier = modifier;
       this.variant = variant;
       this.remark = remark;
       this.status = status;
       this.orderCacheId = orderCacheId;
       this.order_detail_sqlite_id = order_detail_sqlite_id;
       this.sequence = sequence;
   }

   static cartProductItem fromJson(Map<String, Object?> json) {
     var modJson = json['modifier'] as List;
     var variantJson = json['variant'] as List;
     List<ModifierGroup> modGroup = modJson.map((tagJson) => ModifierGroup.fromJson(tagJson)).toList();
     List<VariantGroup> variantGroup = variantJson.map((tagJson) => VariantGroup.fromJson(tagJson)).toList();
     return cartProductItem(
         json['branchProduct_id'] as String,
         json['name'] as String,
         json['category_id'] as String,
         json['price'] as String,
         json['quantity'] as int,
         modGroup,
         variantGroup,
         json['remark'] as String,
         json['status'] as int,
         json['orderCacheId'] as String,
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
     'branchProduct_id': branchProduct_id,
     'name': name,
     'category_id': category_id,
     'category_sqlite_id': category_sqlite_id,
     'price': price,
     'quantity': quantity,
     'modifier': modifier,
     'variant': variant,
     'remark': remark,
     'status': status,
     'orderCacheId': orderCacheId,
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