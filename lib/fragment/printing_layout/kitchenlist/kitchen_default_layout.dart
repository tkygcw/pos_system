import 'package:esc_pos_utils/esc_pos_utils.dart';
import 'package:f_logs/model/flog/flog.dart';
import 'package:pos_system/fragment/printing_layout/receipt_layout.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../database/pos_database.dart';
import '../../../object/cart_product.dart';
import '../../../object/kitchen_list.dart';
import '../../../object/order_detail.dart';
import '../../../utils/Utils.dart';

class DefaultKitchenListLayout extends ReceiptLayout {
/*
  kitchen layout 80mm
*/
  printKitchenList80mm(bool isUSB, int localId, {value, required OrderDetail orderDetail, bool? isReprint, String? printerLabel}) async {

    final prefs = await SharedPreferences.getInstance();
    final int? branch_id = prefs.getInt('branch_id');
    KitchenList? kitchenListLayout = await PosDatabase.instance.readSpecificKitchenList('80');
    if(kitchenListLayout == null){
      kitchenListLayout = kitchenListDefaultLayout;
    }
    PosFontType productFontType = kitchenListLayout.product_name_font_size == 2 ? PosFontType.fontB : PosFontType.fontA;
    PosFontType otherFontType = kitchenListLayout.other_font_size == 2 ? PosFontType.fontB : PosFontType.fontA;
    PosTextSize productFontSize = kitchenListLayout.product_name_font_size == 1 ? PosTextSize.size1 : PosTextSize.size2;
    PosTextSize otherFontSize = kitchenListLayout.other_font_size == 1 ? PosTextSize.size1 : PosTextSize.size2;

    await readOrderCache(localId);
    cartProductItem cartItem = cartProductItem(
        quantity: int.tryParse(orderDetail.quantity!) != null ? int.parse(orderDetail.quantity!) : double.parse(orderDetail.quantity!),
        product_name: orderDetail.productName,
        productVariantName: orderDetail.product_variant_name,
        remark: orderDetail.remark,
        orderModifierDetail: orderDetail.orderModifierDetail,
        unit: orderDetail.unit,
        per_quantity_unit: orderDetail.per_quantity_unit,
        price: orderDetail.price,
        product_sku: orderDetail.product_sku
    );

    var generator;
    if (isUSB) {
      final profile = await CapabilityProfile.load();
      generator = Generator(PaperSize.mm80, profile);
    } else {
      generator = value;
    }

    List<int> bytes = [];
    try {
      bytes += generator.text(isReprint != null ? '** Reprint List **' : kitchenListLayout.use_printer_label_as_title == 0 ? '** kitchen list **' : '** $printerLabel **', styles: PosStyles(align: PosAlign.center, width: PosTextSize.size2, height: PosTextSize.size2));
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
        bytes += generator.text('Order No: ${this.orderCache!.order_queue!}', styles: PosStyles(align: PosAlign.center, height:PosTextSize.size2, width: PosTextSize.size2));
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
      //order product
      bytes += generator.row([
        PosColumn(text: cartItem.unit != 'each' && cartItem.unit != 'each_c' ? '${(cartItem.quantity!*int.parse(cartItem.per_quantity_unit!)).toStringAsFixed(2)}${cartItem.unit}'
            : '${cartItem.quantity}',
            width: 2,
            styles: PosStyles(
                align: PosAlign.left,
                bold: true,
                fontType: productFontType,
                height: productFontSize,
                width: productFontSize)),
        PosColumn(
            text: '${getCartProductSKU(cartItem, layout: kitchenListLayout)}${cartItem.product_name}${kitchenListLayout.kitchen_list_show_price == 1 ?
            '(RM${(double.parse(cartItem.price!) * cartItem.quantity!).toStringAsFixed(2)})' : '' }',
            width: 10,
            containsChinese: true,
            styles: PosStyles(
                align: PosAlign.left,
                fontType: productFontType,
                height: productFontSize,
                width: productFontSize))
      ]);
      bytes += generator.reset();
      //product variant
      if(cartItem.productVariantName != ''){
        bytes += generator.row([
          PosColumn(
              text: '',
              width: 2,
              styles: PosStyles(
                  align: PosAlign.left,
                  fontType: otherFontType,
                  height: otherFontSize,
                  width: otherFontSize)),
          PosColumn(
              text: '(${cartItem.productVariantName})',
              width: 10,
              containsChinese: true,
              styles: PosStyles(
                  align: PosAlign.left,
                  fontType: otherFontType,
                  height: otherFontSize,
                  width: otherFontSize)),
        ]);
      }
      bytes += generator.reset();
      //product modifier
      if(cartItem.orderModifierDetail!.isNotEmpty) {
        for (int j = 0; j < cartItem.orderModifierDetail!.length; j++) {
          //modifier
          bytes += generator.row([
            PosColumn(
                text: '',
                width: 2,
                styles: PosStyles(
                    fontType: otherFontType,
                    height: otherFontSize,
                    width: otherFontSize)),
            PosColumn(text: '+${cartItem.orderModifierDetail![j].mod_name}',
                containsChinese: true,
                width: 10,
                styles: PosStyles(
                    align: PosAlign.left,
                    fontType: otherFontType,
                    height: otherFontSize,
                    width: otherFontSize)),
          ]);
        }
      }
      /*
        * product remark
        * */
      bytes += generator.reset();
      if (cartItem.remark != '') {
        bytes += generator.row([
          PosColumn(text: '', width: 2),
          PosColumn(
              text: '**${cartItem.remark}',
              width: 8,
              containsChinese: true,
              styles: PosStyles(
                  align: PosAlign.left,
                  fontType: otherFontType,
                  height: otherFontSize,
                  width: otherFontSize)),
          PosColumn(text: '', width: 2),
        ]);
      }

      bytes += generator.feed(1);
      bytes += generator.cut(mode: PosCutMode.partial);
      return bytes;
    } catch (e) {
      print('layout error: $e');
      FLog.error(
        className: "receipt_layout",
        text: "printKitchenList80mm error",
        exception: "$e",
      );
      return null;
    }
  }

/*
  kitchen layout 58mm
*/
  printKitchenList58mm(bool isUSB, int localId, {value, required OrderDetail orderDetail, bool? isReprint, String? printerLabel}) async {
    final prefs = await SharedPreferences.getInstance();
    final int? branch_id = prefs.getInt('branch_id');
    KitchenList? kitchenListLayout = await PosDatabase.instance.readSpecificKitchenList('58');
    if(kitchenListLayout == null){
      kitchenListLayout = kitchenListDefaultLayout;
    }
    PosFontType productFontType = kitchenListLayout.product_name_font_size == 2 ? PosFontType.fontB : PosFontType.fontA;
    PosFontType otherFontType = kitchenListLayout.other_font_size == 2 ? PosFontType.fontB : PosFontType.fontA;
    PosTextSize productFontSize = kitchenListLayout.product_name_font_size == 1 ? PosTextSize.size1 : PosTextSize.size2;
    PosTextSize otherFontSize = kitchenListLayout.other_font_size == 1 ? PosTextSize.size1 : PosTextSize.size2;

    await readOrderCache(localId);
    cartProductItem cartItem = cartProductItem(
        quantity: int.tryParse(orderDetail.quantity!) != null ? int.parse(orderDetail.quantity!) : double.parse(orderDetail.quantity!),
        product_name: orderDetail.productName,
        productVariantName: orderDetail.product_variant_name,
        remark: orderDetail.remark,
        orderModifierDetail: orderDetail.orderModifierDetail,
        unit: orderDetail.unit,
        per_quantity_unit: orderDetail.per_quantity_unit,
        price: orderDetail.price,
        product_sku: orderDetail.product_sku
    );

    var generator;
    if (isUSB) {
      final profile = await CapabilityProfile.load();
      generator = Generator(PaperSize.mm58, profile);
    } else {
      generator = value;
    }

    List<int> bytes = [];
    try {
      bytes += generator.text(isReprint != null ? '** Reprint List **' : kitchenListLayout.use_printer_label_as_title == 0 ? '** kitchen list **' : '** $printerLabel **', styles: PosStyles(align: PosAlign.center, width: PosTextSize.size2, height: PosTextSize.size2));
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
      //order product
      bytes += generator.row([
        PosColumn(text: cartItem.unit != 'each' && cartItem.unit != 'each_c' ? '${(cartItem.quantity!*int.parse(cartItem.per_quantity_unit!)).toStringAsFixed(2)}${cartItem.unit}'
            : '${cartItem.quantity}',
            width: 3,
            styles: PosStyles(
                bold: true,
                fontType: productFontType,
                height: productFontSize,
                width: productFontSize)),
        PosColumn(
            text: '${getCartProductSKU(cartItem, layout: kitchenListLayout)}${cartItem.product_name}${kitchenListLayout.kitchen_list_show_price == 1 ?
            '(RM${(double.parse(cartItem.price!) * cartItem.quantity!).toStringAsFixed(2)})' : '' }',
            width: 9,
            containsChinese: true,
            styles: PosStyles(
                bold: true,
                align: PosAlign.left,
                fontType: productFontType,
                height: productFontSize,
                width: productFontSize))
      ]);
      bytes += generator.reset();
      //product variant
      if(cartItem.productVariantName != ''){
        bytes += generator.row([
          PosColumn(
              text: '',
              width: 3,
              styles: PosStyles(
                  fontType: otherFontType,
                  height: otherFontSize,
                  width: otherFontSize)),
          PosColumn(
              text: '(${cartItem.productVariantName})',
              width: 9,
              containsChinese: true,
              styles: PosStyles(
                  fontType: otherFontType,
                  height: otherFontSize,
                  width: otherFontSize))
        ]);
      }
      bytes += generator.reset();
      //product modifier
      if(cartItem.orderModifierDetail!.isNotEmpty) {
        for (int j = 0; j < cartItem.orderModifierDetail!.length; j++) {
          //modifier
          bytes += generator.row([
            PosColumn(text: '', width: 3),
            PosColumn(text: '+${cartItem.orderModifierDetail![j].mod_name}',
                width: 9,
                containsChinese: true,
                styles: PosStyles(
                    fontType: otherFontType,
                    height: otherFontSize,
                    width: otherFontSize))
          ]);
        }
      }
      /*
        * product remark
        * */
      bytes += generator.reset();
      if (cartItem.remark != '') {
        bytes += generator.row([
          PosColumn(text: '', width: 3),
          PosColumn(
              text: '**${cartItem.remark}',
              width: 9,
              containsChinese: true,
              styles: PosStyles(
                  fontType: otherFontType,
                  height: otherFontSize,
                  width: otherFontSize)),
        ]);
      }

      bytes += generator.feed(1);
      bytes += generator.cut(mode: PosCutMode.partial);
      return bytes;
    } catch (e) {
      print('layout 58mm error: $e');
      FLog.error(
        className: "receipt_layout",
        text: "printKitchenList58mm error",
        exception: "$e",
      );
      return null;
    }
  }
}