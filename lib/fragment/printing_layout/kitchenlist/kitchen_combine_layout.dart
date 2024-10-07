import 'package:esc_pos_utils/esc_pos_utils.dart';
import 'package:pos_system/fragment/printing_layout/receipt_layout.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../database/pos_database.dart';
import '../../../object/cart_product.dart';
import '../../../object/kitchen_list.dart';
import '../../../object/order_detail.dart';
import '../../../utils/Utils.dart';


class CombineKitchenListLayout extends ReceiptLayout {
/*
  combine kitchen layout 80mm
*/
  printCombinedKitchenList80mm(bool isUSB, int localId, {value, required List<OrderDetail> orderDetailList, bool? isReprint, double? combineListTotal}) async {
    List<cartProductItem> cartItemList = [];
    final prefs = await SharedPreferences.getInstance();
    final int? branch_id = prefs.getInt('branch_id');
    KitchenList? kitchenListLayout = await PosDatabase.instance.readSpecificKitchenList('80');
    if(kitchenListLayout == null){
      kitchenListLayout = kitchenListDefaultLayout;
    }
    await readOrderCache(localId);

    for (int i = 0; i < orderDetailList.length; i++) {
      OrderDetail orderDetail = orderDetailList[i];
      cartProductItem cartItem = cartProductItem(
          quantity: int.tryParse(orderDetail.quantity!) != null
              ? int.parse(orderDetail.quantity!)
              : double.parse(orderDetail.quantity!),
          product_name: orderDetail.productName,
          productVariantName: orderDetail.product_variant_name,
          remark: orderDetail.remark,
          orderModifierDetail: orderDetail.orderModifierDetail,
          unit: orderDetail.unit,
          per_quantity_unit: orderDetail.per_quantity_unit,
          price: orderDetail.price,
          product_sku: orderDetail.product_sku
      );
      cartItemList.add(cartItem);
    }

    var generator;
    if (isUSB) {
      final profile = await CapabilityProfile.load();
      generator = Generator(PaperSize.mm80, profile);
    } else {
      generator = value;
    }

    List<int> bytes = [];
    try {
      bytes += generator.reset();
      bytes += generator.text(isReprint != null ? '** Reprint List **' : '** kitchen list **', styles: PosStyles(align: PosAlign.center, width: PosTextSize.size2, height: PosTextSize.size2));
      bytes += generator.emptyLines(1);
      bytes += generator.reset();
      //other order detail
      if(tableList.isNotEmpty){
        for(int i = 0; i < tableList.length; i++){
          bytes += generator.text('Table No: ${tableList[i].number}', styles: PosStyles(bold: true, align: PosAlign.center, height: PosTextSize.size2, width: PosTextSize.size2));
        }
      } else {
        bytes += generator.text('${orderCache!.dining_name}', styles: PosStyles(bold: true, align: PosAlign.center, height: PosTextSize.size2, width: PosTextSize.size2));
      }
      //order queue
      if(int.tryParse(orderCache!.order_queue!) != null){
        bytes += generator.text('Order No: ${orderCache!.order_queue!}', styles: PosStyles(align: PosAlign.center, height:PosTextSize.size2, width: PosTextSize.size2));
      }
      bytes += generator.text('Batch No: #${orderCache!.batch_id}-${branch_id.toString().padLeft(3 ,'0')}', styles: PosStyles(align: PosAlign.center));
      bytes += generator.text('Order time: ${Utils.formatDate(orderCache!.created_at)}', styles: PosStyles(align: PosAlign.center));
      bytes += generator.hr();
      bytes += generator.reset();
      /*
    *
    * body
    *
    * */
      for (int i = 0; i < cartItemList.length; i++) {
        //order product
        if(i != 0) {
          if(kitchenListLayout.kitchen_list_item_separator == 1) {
            bytes += generator.reset();
            bytes += generator.hr();
          }
        }
        bytes += generator.row([
          PosColumn(
              text: cartItemList[i].unit != 'each' && cartItemList[i].unit != 'each_c' ? '${(cartItemList[i].quantity! * int.parse(cartItemList[i].per_quantity_unit!)).toStringAsFixed(2)}${cartItemList[i].unit}' : '${cartItemList[i].quantity}',
              width: 2,
              styles: PosStyles(
                  align: PosAlign.left,
                  bold: true,
                  height: kitchenListLayout.product_name_font_size == 1 ? PosTextSize.size1 : PosTextSize.size2,
                  width: kitchenListLayout.product_name_font_size == 1 ? PosTextSize.size1 : PosTextSize.size2)),
          PosColumn(
              text: '${getCartProductSKU(cartItemList[i], layout: kitchenListLayout)}${cartItemList[i].product_name}${kitchenListLayout.kitchen_list_show_price == 1 ? '(RM${(double.parse(cartItemList[i].price!) * cartItemList[i].quantity!).toStringAsFixed(2)})' : '' }',
              width: 10, containsChinese: true,
              styles: PosStyles(
                  align: PosAlign.left,
                  height: kitchenListLayout.product_name_font_size == 1 ? PosTextSize.size1 : PosTextSize.size2,
                  width: kitchenListLayout.product_name_font_size == 1 ? PosTextSize.size1 : PosTextSize.size2))
        ]);
        bytes += generator.reset();
        //product variant
        if (cartItemList[i].productVariantName != '') {
          bytes += generator.row([
            PosColumn(text: '', width: 2, styles: PosStyles(align: PosAlign.left)),
            PosColumn(
                text: '(${cartItemList[i].productVariantName})',
                width: 10,
                containsChinese: true,
                styles: PosStyles(
                    align: PosAlign.left,
                    height: kitchenListLayout.other_font_size == 0 ? PosTextSize.size2 : PosTextSize.size1,
                    width: kitchenListLayout.other_font_size == 0 ? PosTextSize.size2 : PosTextSize.size1)),
          ]);
        }
        bytes += generator.reset();
        //product modifier
        if (cartItemList[i].orderModifierDetail!.isNotEmpty) {
          for (int j = 0; j < cartItemList[i].orderModifierDetail!.length; j++) {
            //modifier
            bytes += generator.row([
              PosColumn(text: '', width: 2),
              PosColumn(text: '+${cartItemList[i].orderModifierDetail![j].mod_name}', containsChinese: true, width: 10,
                  styles: PosStyles(
                      align: PosAlign.left,
                      height: kitchenListLayout.other_font_size == 0 ? PosTextSize.size2 : PosTextSize.size1,
                      width: kitchenListLayout.other_font_size == 0 ? PosTextSize.size2 : PosTextSize.size1)),
            ]);
          }
        }
        /*
        * product remark
        * */
        bytes += generator.reset();
        if (cartItemList[i].remark != '') {
          bytes += generator.row([
            PosColumn(text: '', width: 2),
            PosColumn(
                text: '**${cartItemList[i].remark}', width: 8, containsChinese: true,
                styles: PosStyles(
                    align: PosAlign.left,
                    height: kitchenListLayout.other_font_size == 0 ? PosTextSize.size2 : PosTextSize.size1,
                    width: PosTextSize.size2)),
            PosColumn(text: '', width: 2),
          ]);
        }
        bytes += generator.emptyLines(1);
      }

      if(combineListTotal != null) {
        bytes += generator.reset();
        bytes += generator.emptyLines(1);
        bytes += generator.text('Total: RM ${combineListTotal.toStringAsFixed(2)}',
            styles: PosStyles(
                align: PosAlign.right,
                height: kitchenListLayout.product_name_font_size == 1 ? PosTextSize.size1 : PosTextSize.size2,
                width: kitchenListLayout.product_name_font_size == 1 ? PosTextSize.size1 : PosTextSize.size2
            )
        );
      }

      bytes += generator.feed(1);
      bytes += generator.cut(mode: PosCutMode.partial);
      return bytes;
    } catch (e) {
      print('layout error: $e');
      return null;
    }
  }

/*
  combine kitchen layout 58mm
*/
  printCombinedKitchenList58mm(bool isUSB, int localId, {value, required List<OrderDetail> orderDetailList, bool? isReprint, double? combineListTotal}) async {
    List<cartProductItem> cartItemList = [];
    final prefs = await SharedPreferences.getInstance();
    final int? branch_id = prefs.getInt('branch_id');
    KitchenList? kitchenListLayout = await PosDatabase.instance.readSpecificKitchenList('58');
    if(kitchenListLayout == null){
      kitchenListLayout = kitchenListDefaultLayout;
    }
    await readOrderCache(localId);

    for (int i = 0; i < orderDetailList.length; i++) {
      OrderDetail orderDetail = orderDetailList[i];
      cartProductItem cartItem = cartProductItem(
          quantity: int.tryParse(orderDetail.quantity!) != null
              ? int.parse(orderDetail.quantity!)
              : double.parse(orderDetail.quantity!),
          product_name: orderDetail.productName,
          productVariantName: orderDetail.product_variant_name,
          remark: orderDetail.remark,
          orderModifierDetail: orderDetail.orderModifierDetail,
          unit: orderDetail.unit,
          per_quantity_unit: orderDetail.per_quantity_unit,
          price: orderDetail.price,
          product_sku: orderDetail.product_sku
      );
      cartItemList.add(cartItem);
    }

    var generator;
    if (isUSB) {
      final profile = await CapabilityProfile.load();
      generator = Generator(PaperSize.mm58, profile);
    } else {
      generator = value;
    }

    List<int> bytes = [];
    try {
      bytes += generator.reset();
      bytes += generator.text(isReprint != null ? '** Reprint List **' : '** kitchen list **', styles: PosStyles(align: PosAlign.center, width: PosTextSize.size2, height: PosTextSize.size2));
      bytes += generator.emptyLines(1);
      bytes += generator.reset();
      //other order detail
      if(tableList.isNotEmpty){
        for(int i = 0; i < tableList.length; i++){
          bytes += generator.text('Table No: ${tableList[i].number}', styles: PosStyles(bold: true, align: PosAlign.center, height: PosTextSize.size2, width: PosTextSize.size2));
        }
      } else {
        bytes += generator.text('${orderCache!.dining_name}', styles: PosStyles(bold: true, align: PosAlign.center, height: PosTextSize.size2, width: PosTextSize.size2));
      }
      //order queue
      if(int.tryParse(orderCache!.order_queue!) != null){
        bytes += generator.text('Order No: ${orderCache!.order_queue!}', styles: PosStyles(align: PosAlign.center, height:PosTextSize.size2, width: PosTextSize.size2));
      }
      bytes += generator.text('Batch No: #${orderCache!.batch_id}-${branch_id.toString().padLeft(3 ,'0')}', styles: PosStyles(align: PosAlign.center));
      bytes += generator.text('Order time: ${Utils.formatDate(orderCache!.created_at)}', styles: PosStyles(align: PosAlign.center));
      bytes += generator.hr();
      bytes += generator.reset();
      /*
    *
    * body
    *
    * */
      print("cart item list: ${cartItemList.length}");
      for (int i = 0; i < cartItemList.length; i++) {
        //order product
        if(i != 0) {
          if(kitchenListLayout.kitchen_list_item_separator == 1) {
            bytes += generator.reset();
            bytes += generator.hr();
          }
        }
        bytes += generator.row([
          PosColumn(
              text: cartItemList[i].unit != 'each' && cartItemList[i].unit != 'each_c' ? '${(cartItemList[i].quantity! * int.parse(cartItemList[i].per_quantity_unit!)).toStringAsFixed(2)}${cartItemList[i].unit}' : '${cartItemList[i].quantity}',
              width: 2,
              styles: PosStyles(
                  align: PosAlign.left,
                  bold: true,
                  height: kitchenListLayout.product_name_font_size == 1 ? PosTextSize.size1 : PosTextSize.size2,
                  width: kitchenListLayout.product_name_font_size == 1 ? PosTextSize.size1 : PosTextSize.size2)),
          PosColumn(
              text: '${getCartProductSKU(cartItemList[i], layout: kitchenListLayout)}${cartItemList[i].product_name}${kitchenListLayout.kitchen_list_show_price == 1 ? '(RM${(double.parse(cartItemList[i].price!) * cartItemList[i].quantity!).toStringAsFixed(2)})' : '' }',
              width: 10, containsChinese: true,
              styles: PosStyles(
                  align: PosAlign.left,
                  height: kitchenListLayout.product_name_font_size == 1 ? PosTextSize.size1 : PosTextSize.size2,
                  width: kitchenListLayout.product_name_font_size == 1 ? PosTextSize.size1 : PosTextSize.size2))
        ]);
        bytes += generator.reset();
        //product variant
        if (cartItemList[i].productVariantName != '') {
          bytes += generator.row([
            PosColumn(text: '', width: 2, styles: PosStyles(align: PosAlign.left)),
            PosColumn(
                text: '(${cartItemList[i].productVariantName})',
                width: 10,
                containsChinese: true,
                styles: PosStyles(
                    align: PosAlign.left,
                    height: kitchenListLayout.other_font_size == 0 ? PosTextSize.size2 : PosTextSize.size1,
                    width: kitchenListLayout.other_font_size == 0 ? PosTextSize.size2 : PosTextSize.size1)),
          ]);
        }
        bytes += generator.reset();
        //product modifier
        if (cartItemList[i].orderModifierDetail!.isNotEmpty) {
          for (int j = 0; j < cartItemList[i].orderModifierDetail!.length; j++) {
            //modifier
            bytes += generator.row([
              PosColumn(text: '', width: 2),
              PosColumn(text: '+${cartItemList[i].orderModifierDetail![j].mod_name}', containsChinese: true, width: 10,
                  styles: PosStyles(
                      align: PosAlign.left,
                      height: kitchenListLayout.other_font_size == 0 ? PosTextSize.size2 : PosTextSize.size1,
                      width: kitchenListLayout.other_font_size == 0 ? PosTextSize.size2 : PosTextSize.size1)),
            ]);
          }
        }
        /*
        * product remark
        * */
        bytes += generator.reset();
        if (cartItemList[i].remark != '') {
          bytes += generator.row([
            PosColumn(text: '', width: 2),
            PosColumn(
                text: '**${cartItemList[i].remark}', width: 8, containsChinese: true,
                styles: PosStyles(
                    align: PosAlign.left,
                    height: kitchenListLayout.other_font_size == 0 ? PosTextSize.size2 : PosTextSize.size1,
                    width: PosTextSize.size2)),
            PosColumn(text: '', width: 2),
          ]);
        }
        bytes += generator.emptyLines(1);
      }

      if(combineListTotal != null) {
        bytes += generator.reset();
        bytes += generator.emptyLines(1);
        bytes += generator.text('Total: RM ${combineListTotal.toStringAsFixed(2)}',
            styles: PosStyles(
                align: PosAlign.right,
                height: kitchenListLayout.product_name_font_size == 1 ? PosTextSize.size1 : PosTextSize.size2,
                width: kitchenListLayout.product_name_font_size == 1 ? PosTextSize.size1 : PosTextSize.size2
            )
        );
      }

      bytes += generator.feed(1);
      bytes += generator.cut(mode: PosCutMode.partial);
      return bytes;
    } catch (e) {
      print('layout 58mm error: $e');
      return null;
    }
  }
}