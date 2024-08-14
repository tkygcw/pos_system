import 'package:pos_system/fragment/printing_layout/receipt_layout.dart';
import 'package:esc_pos_utils/esc_pos_utils.dart';
import 'package:f_logs/model/flog/flog.dart';

import '../../../notifier/cart_notifier.dart';
import '../../../object/cart_product.dart';
import '../../../utils/Utils.dart';

class PreviewLayout extends ReceiptLayout {
/*
  Review Receipt layout 80mm
*/
  printPreviewReceipt80mm(bool isUSB, CartModel cartModel, {value}) async {
    String dateTime = dateFormat.format(DateTime.now());
    await readReceiptLayout('80');
    await readOrderCache(int.parse(cartModel.cartNotifierItem[0].order_cache_sqlite_id!));
    // final ByteData data = await rootBundle.load('drawable/logo2.png');
    // final Uint8List bytes = data.buffer.asUint8List();
    // final decodedImage = img.decodeImage(bytes);
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
      //bytes += generator.image(decodedImage);
      bytes += generator.text('** Review Receipt **', styles: PosStyles(align: PosAlign.center, height:PosTextSize.size2, width: PosTextSize.size2 ));
      bytes += generator.emptyLines(1);
      bytes += generator.reset();
      bytes += generator.hr();
      bytes += generator.reset();
      if(cartModel.selectedTable.isNotEmpty){
        bytes += generator.text('Table No: ${getCartTableNumber(cartModel.selectedTable).toString().replaceAll('[', '').replaceAll(']', '')}');
      }
      if(int.tryParse(orderCache!.order_queue!) != null) {
        bytes += generator.text('Order No: ${orderCache!.order_queue}');
      }
      // if( == true){
      //   for(int i = 0; i < selectedTableList.length; i++){
      //     bytes += generator.text('Order No: ${selectedTableList[i].number}');
      //   }
      // }
      bytes += generator.text('${cartModel.selectedOption}');
      bytes += generator.text('Print At: ${Utils.formatDate(dateTime)}');
      bytes += generator.reset();
      /*
    *
    * body
    *
    * */
      bytes += generator.hr();
      bytes += generator.row([
        PosColumn(text: 'Qty ', width: 2, styles: PosStyles(bold: true)),
        PosColumn(text: 'Item', width: 7, styles: PosStyles(bold: true, align: PosAlign.left)),
        PosColumn(text: 'Price', width: 3, styles: PosStyles(bold: true, align: PosAlign.right)),
      ]);
      bytes += generator.hr();
      //order product
      for(int i = 0; i < cartModel.cartNotifierItem.length; i++){
        bool productUnitPriceSplit = productNameDisplayCart(cartModel.cartNotifierItem, i, 80);
        bytes += generator.row([
          PosColumn(text: '${cartModel.cartNotifierItem[i].quantity}', width: 2),
          PosColumn(
            // text: '${cartModel.cartNotifierItem[i].product_name} (${cartModel.cartNotifierItem[i].price}/${cartModel.cartNotifierItem[i].per_quantity_unit}${cartModel.cartNotifierItem[i].unit})',
              text: productUnitPriceSplit  ? getPreviewReceiptProductName(cartModel.cartNotifierItem[i])
                  : '${getPreviewReceiptProductName(cartModel.cartNotifierItem[i])} (${cartModel.cartNotifierItem[i].price}/${cartModel.cartNotifierItem[i].per_quantity_unit}${cartModel.cartNotifierItem[i].unit != 'each' && cartModel.cartNotifierItem[i].unit != 'each_c' ? cartModel.cartNotifierItem[i].unit : 'each'})',
              width: 7,
              containsChinese: true,
              styles: PosStyles(align: PosAlign.left, bold: true)),
          PosColumn(
              text: '${(double.parse(cartModel.cartNotifierItem[i].price!)*cartModel.cartNotifierItem[i].quantity!).toStringAsFixed(2)}',
              width: 3,
              styles: PosStyles(align: PosAlign.right)),
        ]);
        bytes += generator.reset();

        if(productUnitPriceSplit){
          bytes += generator.row([
            PosColumn(text: '', width: 2),
            PosColumn(text: '(${cartModel.cartNotifierItem[i].price}/${cartModel.cartNotifierItem[i].per_quantity_unit}${cartModel.cartNotifierItem[i].unit != 'each' && cartModel.cartNotifierItem[i].unit != 'each_c' ? cartModel.cartNotifierItem[i].unit : 'each'})', width: 7),
            PosColumn(text: '', width: 3, styles: PosStyles(align: PosAlign.right)),
          ]);
        }
        bytes += generator.reset();

        if(cartModel.cartNotifierItem[i].productVariantName != null && cartModel.cartNotifierItem[i].productVariantName != ''){
          bytes += generator.row([
            PosColumn(text: '', width: 2),
            PosColumn(text: '(${cartModel.cartNotifierItem[i].productVariantName})', width: 7, containsChinese: true, styles: PosStyles(align: PosAlign.left)),
            PosColumn(text: '', width: 3, styles: PosStyles(align: PosAlign.right)),
          ]);
        }
        // if(cartModel.cartNotifierItem[i].variant!.isNotEmpty){
        //   bytes += generator.row([
        //     PosColumn(text: '(${getVariant(cartModel.cartNotifierItem[i])})', width: 6, containsChinese: true, styles: PosStyles(align: PosAlign.left)),
        //     PosColumn(text: '', width: 2),
        //     PosColumn(text: '', width: 4, styles: PosStyles(align: PosAlign.right)),
        //   ]);
        // }
        bytes += generator.reset();
        //product modifier
        if(cartModel.cartNotifierItem[i].orderModifierDetail!.isNotEmpty){
          cartProductItem cartItem = cartModel.cartNotifierItem[i];
          for(int j = 0; j < cartItem.orderModifierDetail!.length; j++)
            bytes += generator.row([
              PosColumn(text: '', width: 2),
              PosColumn(text: '+${cartItem.orderModifierDetail![j].mod_name!}', width: 7, containsChinese: true, styles: PosStyles(align: PosAlign.left)),
              PosColumn(text: '', width: 3, styles: PosStyles(align: PosAlign.right)),
            ]);
        }
        // if(cartModel.cartNotifierItem[i].modifier!.isNotEmpty){
        //   for (int j = 0; j < cartModel.cartNotifierItem[i].modifier!.length; j++) {
        //     ModifierGroup group = cartModel.cartNotifierItem[i].modifier![j];
        //     for (int k = 0; k < group.modifierChild!.length; k++) {
        //       if (group.modifierChild![k].isChecked!) {
        //         bytes += generator.row([
        //           PosColumn(text: '+${group.modifierChild![k].name!}', width: 12, containsChinese: true, styles: PosStyles(align: PosAlign.left))
        //         ]);
        //       }
        //     }
        //   }
        // }
        //product remark
        bytes += generator.reset();
        if (cartModel.cartNotifierItem[i].remark != '') {
          bytes += generator.row([
            PosColumn(text: '', width: 2),
            PosColumn(text: '**${cartModel.cartNotifierItem[i].remark}', width: 7, containsChinese: true),
            PosColumn(text: '', width: 3, styles: PosStyles(align: PosAlign.right)),
          ]);
        }
        // bytes += generator.emptyLines(1);
      }
      bytes += generator.hr();
      bytes += generator.reset();


      //item count
      num receiptItemCount = 0;
      for(int i = 0; i < cartModel.cartNotifierItem.length; i++){
        receiptItemCount += cartModel.cartNotifierItem[i].quantity!.toString().contains('.') ? 1 : cartModel.cartNotifierItem[i].quantity!;
      }
      bytes += generator.text('Item count: ${receiptItemCount}');
      bytes += generator.hr();
      bytes += generator.reset();
      //total calc
      bytes += generator.row([
        PosColumn(text: 'SubTotal', width: 8, styles: PosStyles(align: PosAlign.right)),
        PosColumn(text: '${cartModel.cartNotifierPayment[0].subtotal.toStringAsFixed(2)}', width: 4, styles: PosStyles(align: PosAlign.right)),
      ]);
      if(receipt!.promotion_detail_status == 1){
        //discount
        if(cartModel.selectedPromotion != null){
          bytes += generator.row([
            PosColumn(text: '${cartModel.selectedPromotion!.name}(${cartModel.selectedPromotion!.promoRate})', width: 8, containsChinese: true, styles: PosStyles(align: PosAlign.right)),
            PosColumn(text: '-${cartModel.selectedPromotion!.promoAmount!.toStringAsFixed(2)}', width: 4, styles: PosStyles(align: PosAlign.right)),
          ]);
        }
        if(cartModel.cartNotifierPayment[0].promotionList!.isNotEmpty){
          for(int p = 0; p < cartModel.cartNotifierPayment[0].promotionList!.length; p++){
            bytes += generator.row([
              PosColumn(text: '${cartModel.cartNotifierPayment[0].promotionList![p].name}(${cartModel.cartNotifierPayment[0].promotionList![p].promoRate})', width: 8, containsChinese: true, styles: PosStyles(align: PosAlign.right)),
              PosColumn(text: '-${cartModel.cartNotifierPayment[0].promotionList![p].promoAmount!.toStringAsFixed(2)}', width: 4, styles: PosStyles(align: PosAlign.right)),
            ]);
          }
        }
      } else {
        bytes += generator.row([
          PosColumn(text: 'Total Discount', width: 8, styles: PosStyles(align: PosAlign.right)),
          PosColumn(text: '-${getTotalPromotion(cartModel)}', width: 4, styles: PosStyles(align: PosAlign.right)),
        ]);
      }
      //tax
      if(cartModel.cartNotifierPayment[0].taxList!.isNotEmpty){
        for(int t = 0; t < cartModel.cartNotifierPayment[0].taxList!.length; t++){
          bytes += generator.row([
            PosColumn(text: '${cartModel.cartNotifierPayment[0].taxList![t].name}(${cartModel.cartNotifierPayment[0].taxList![t].tax_rate}%)', width: 8, styles: PosStyles(align: PosAlign.right)),
            PosColumn(text: '${cartModel.cartNotifierPayment[0].taxList![t].tax_amount!.toStringAsFixed(2)}', width: 4, styles: PosStyles(align: PosAlign.right)),
          ]);
        }
      }
      //Amount
      bytes += generator.row([
        PosColumn(text: 'Amount', width: 8, styles: PosStyles(align: PosAlign.right)),
        PosColumn(text: '${cartModel.cartNotifierPayment[0].amount.toStringAsFixed(2)}', width: 4, styles: PosStyles(align: PosAlign.right)),
      ]);
      //rounding
      bytes += generator.row([
        PosColumn(text: 'Rounding', width: 8, styles: PosStyles(align: PosAlign.right)),
        PosColumn(text: '${cartModel.cartNotifierPayment[0].rounding.toStringAsFixed(2)}', width: 4, styles: PosStyles(align: PosAlign.right)),
      ]);
      //total
      bytes += generator.hr();
      bytes += generator.row([
        PosColumn(text: 'Final Amount', width: 8, styles: PosStyles(align: PosAlign.right, height: PosTextSize.size2)),
        PosColumn(
            text: '${cartModel.cartNotifierPayment[0].finalAmount}',
            width: 4,
            styles: PosStyles(align: PosAlign.right, height: PosTextSize.size2, bold: true)),
      ]);
      bytes += generator.hr();
      //footer
      // if(receipt!.footer_text_status == 1){
      //   bytes += generator.text('${receipt!.footer_text}', styles: PosStyles(bold: true, align: PosAlign.center, height: PosTextSize.size1, width: PosTextSize.size1));
      // }
      bytes += generator.emptyLines(1);
      //copyright
      bytes += generator.text('POWERED BY OPTIMY POS', styles: PosStyles(bold: true, align: PosAlign.center));
      bytes += generator.cut(mode: PosCutMode.partial);
      return bytes;
    } catch (e) {
      print('layout error: ${e}');
      FLog.error(
        className: "receipt_layout",
        text: "print preview receipt 80 error",
        exception: e,
      );
      return [];
    }
  }

/*
  Review Receipt layout 58mm
*/
  printPreviewReceipt58mm(bool isUSB, CartModel cartModel, {value}) async {
    String dateTime = dateFormat.format(DateTime.now());
    await readReceiptLayout('58');
    await readOrderCache(int.parse(cartModel.cartNotifierItem[0].order_cache_sqlite_id!));
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
      bytes += generator.text('** Review Receipt **', styles: PosStyles(align: PosAlign.center, height:PosTextSize.size2, width: PosTextSize.size2 ));
      bytes += generator.emptyLines(1);
      bytes += generator.reset();
      bytes += generator.hr();
      bytes += generator.reset();
      if(cartModel.selectedTable.isNotEmpty){
        for(int i = 0; i < cartModel.selectedTable.length; i++){
          bytes += generator.text('Table No: ${cartModel.selectedTable[i].number}');
        }
      }
      if(int.tryParse(orderCache!.order_queue!) != null) {
        bytes += generator.text('Order No: ${orderCache!.order_queue}');
      }
      bytes += generator.text('${cartModel.selectedOption}');
      bytes += generator.text('Print At: ${Utils.formatDate(dateTime)}');
      bytes += generator.reset();
      /*
    *
    * body
    *
    * */
      bytes += generator.hr();
      bytes += generator.row([
        PosColumn(text: 'Qty ', width: 2, styles: PosStyles(bold: true)),
        PosColumn(text: 'Item', width: 6, styles: PosStyles(bold: true)),
        PosColumn(text: 'Price', width: 4, styles: PosStyles(bold: true)),
      ]);
      bytes += generator.hr();
      //order product
      for(int i = 0; i < cartModel.cartNotifierItem.length; i++){
        bool productUnitPriceSplit = productNameDisplayCart(cartModel.cartNotifierItem, i, 58);
        bytes += generator.row([
          PosColumn(text: '${cartModel.cartNotifierItem[i].quantity}', width: 2),
          PosColumn(
              text: productUnitPriceSplit  ? getPreviewReceiptProductName(cartModel.cartNotifierItem[i])
                  : '${getPreviewReceiptProductName(cartModel.cartNotifierItem[i])} (${cartModel.cartNotifierItem[i].price}/${cartModel.cartNotifierItem[i].per_quantity_unit}${cartModel.cartNotifierItem[i].unit != 'each' && cartModel.cartNotifierItem[i].unit != 'each_c' ? cartModel.cartNotifierItem[i].unit : 'each'})',
              width: 6,
              containsChinese: true,
              styles: PosStyles(bold: true)),
          PosColumn(//Utils.convertTo2Dec()
            text: '${(double.parse(cartModel.cartNotifierItem[i].price!)*cartModel.cartNotifierItem[i].quantity!).toStringAsFixed(2)}',
            width: 4,
          ),
        ]);
        bytes += generator.reset();

        if(productUnitPriceSplit){
          bytes += generator.row([
            PosColumn(text: '', width: 2),
            PosColumn(text: '(${cartModel.cartNotifierItem[i].price}/${cartModel.cartNotifierItem[i].per_quantity_unit}${cartModel.cartNotifierItem[i].unit != 'each' && cartModel.cartNotifierItem[i].unit != 'each_c' ? cartModel.cartNotifierItem[i].unit : 'each'})', width: 10),
          ]);
        }
        bytes += generator.reset();

        if(cartModel.cartNotifierItem[i].productVariantName != null && cartModel.cartNotifierItem[i].productVariantName != ''){
          bytes += generator.row([
            PosColumn(text: '', width: 2),
            PosColumn(text: '(${cartModel.cartNotifierItem[i].productVariantName})', width: 10, containsChinese: true),
          ]);
        }
        //product modifier
        if(cartModel.cartNotifierItem[i].orderModifierDetail!.isNotEmpty){
          cartProductItem cartItem = cartModel.cartNotifierItem[i];
          for(int j = 0; j < cartItem.orderModifierDetail!.length; j++){
            bytes += generator.row([
              PosColumn(text: '', width: 2),
              PosColumn(text: '+${cartItem.orderModifierDetail![j].mod_name!}', width: 10, containsChinese: true),
            ]);
          }
        }
        //product remark
        bytes += generator.reset();
        if (cartModel.cartNotifierItem[i].remark != '') {
          bytes += generator.row([
            PosColumn(text: '', width: 2),
            PosColumn(text: '**${cartModel.cartNotifierItem[i].remark}', width: 6, containsChinese: true),
            PosColumn(text: '', width: 4),
          ]);
        }
        // bytes += generator.emptyLines(1);
      }
      bytes += generator.hr();
      bytes += generator.reset();
      //item count
      num receiptItemCount = 0;
      for(int i = 0; i < cartModel.cartNotifierItem.length; i++){
        receiptItemCount += cartModel.cartNotifierItem[i].quantity!.toString().contains('.') ? 1 : cartModel.cartNotifierItem[i].quantity!;
      }
      bytes += generator.text('Item count: ${receiptItemCount}');
      bytes += generator.hr();
      bytes += generator.reset();
      //total calc
      bytes += generator.row([
        PosColumn(text: 'SubTotal', width: 8, containsChinese: true),
        PosColumn(text: '${cartModel.cartNotifierPayment[0].subtotal.toStringAsFixed(2)}', width: 4),
      ]);
      if(receipt!.promotion_detail_status == 1){
        //discount
        if(cartModel.selectedPromotion != null){
          bytes += generator.row([
            PosColumn(text: '${cartModel.selectedPromotion!.name}(${cartModel.selectedPromotion!.promoRate})',
              width: 8,
              containsChinese: true,
            ),
            PosColumn(text: '-${cartModel.selectedPromotion!.promoAmount!.toStringAsFixed(2)}', width: 4),
          ]);
        }
        if(cartModel.cartNotifierPayment[0].promotionList!.isNotEmpty){
          for(int p = 0; p < cartModel.cartNotifierPayment[0].promotionList!.length; p++){
            bytes += generator.row([
              PosColumn(text: '${cartModel.cartNotifierPayment[0].promotionList![p].name}(${cartModel.cartNotifierPayment[0].promotionList![p].promoRate})',
                width: 8,
                containsChinese: true,
              ),
              PosColumn(text: '-${cartModel.cartNotifierPayment[0].promotionList![p].promoAmount!.toStringAsFixed(2)}', width: 4),
            ]);
          }
        }
      } else {
        bytes += generator.row([
          PosColumn(text: 'Total Discount', width: 8),
          PosColumn(text: '-${getTotalPromotion(cartModel)}', width: 4),
        ]);
      }
      //tax
      if(cartModel.cartNotifierPayment[0].taxList!.isNotEmpty){
        for(int t = 0; t < cartModel.cartNotifierPayment[0].taxList!.length; t++){
          bytes += generator.row([
            PosColumn(text: '${cartModel.cartNotifierPayment[0].taxList![t].name}(${cartModel.cartNotifierPayment[0].taxList![t].tax_rate}%)',
              width: 8,
            ),
            PosColumn(text: '${cartModel.cartNotifierPayment[0].taxList![t].tax_amount!.toStringAsFixed(2)}', width: 4),
          ]);
        }
      }
      //Amount
      bytes += generator.row([
        PosColumn(text: 'Amount', width: 8, containsChinese: true),
        PosColumn(text: '${cartModel.cartNotifierPayment[0].amount.toStringAsFixed(2)}', width: 4),
      ]);
      //rounding
      bytes += generator.row([
        PosColumn(text: 'Rounding', width: 8, containsChinese: true),
        PosColumn(text: '${cartModel.cartNotifierPayment[0].rounding.toStringAsFixed(2)}', width: 4),
      ]);
      //total
      bytes += generator.hr();
      bytes += generator.row([
        PosColumn(text: 'Final Amount', width: 8, styles: PosStyles(height: PosTextSize.size2)),
        PosColumn(
            text: '${cartModel.cartNotifierPayment[0].finalAmount}',
            width: 4,
            styles: PosStyles(height: PosTextSize.size2, bold: true)),
      ]);
      bytes += generator.hr();
      bytes += generator.emptyLines(1);
      //copyright
      bytes += generator.text('POWERED BY OPTIMY POS');
      bytes += generator.cut(mode: PosCutMode.partial);
      return bytes;
    } catch (e) {
      print('layout error: ${e}');
      FLog.error(
        className: "receipt_layout",
        text: "print preview receipt 58 error",
        exception: e,
      );
      return null;
    }
  }
}