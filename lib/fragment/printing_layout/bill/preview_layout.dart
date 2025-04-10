import 'package:collection/collection.dart';
import 'package:pos_system/database/pos_database.dart';
import 'package:pos_system/fragment/printing_layout/receipt_layout.dart';
import 'package:esc_pos_utils/esc_pos_utils.dart';
import 'package:f_logs/model/flog/flog.dart';
import 'package:pos_system/object/order_modifier_detail.dart';
import 'package:pos_system/main.dart';
import 'package:pos_system/object/order_payment_split.dart';

import '../../../notifier/cart_notifier.dart';
import '../../../object/cart_product.dart';
import '../../../utils/Utils.dart';

class PreviewLayout extends ReceiptLayout {
/*
  Review Receipt layout 80mm
*/
  printPreviewReceipt80mm(bool isUSB, CartModel cartModel, String orderKey, {value}) async {
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
    await getAllPaymentSplit(orderKey);
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
        PosColumn(text: 'Price($currency_code)', width: 3, styles: PosStyles(bold: true, align: PosAlign.right)),
      ]);
      bytes += generator.hr();
      //merge same item
      List<cartProductItem> mergedItems = mergeCartItems(cartModel);
      //order product
      for(int i = 0; i < mergedItems.length; i++){
        bool productUnitPriceSplit = productNameDisplayCart(mergedItems, i, 80);
        bytes += generator.row([
          PosColumn(text: '${mergedItems[i].quantity}', width: 2),
          PosColumn(
              text: productUnitPriceSplit  ? getPreviewReceiptProductName(mergedItems[i])
                  : '${getPreviewReceiptProductName(mergedItems[i])} (${mergedItems[i].price}/${mergedItems[i].per_quantity_unit}${mergedItems[i].unit != 'each' && mergedItems[i].unit != 'each_c' ? mergedItems[i].unit : 'each'})',
              width: 7,
              containsChinese: true,
              styles: PosStyles(align: PosAlign.left, bold: true)),
          PosColumn(
              text: '${(double.parse(mergedItems[i].price!)*mergedItems[i].quantity!).toStringAsFixed(2)}',
              width: 3,
              styles: PosStyles(align: PosAlign.right)),
        ]);
        bytes += generator.reset();

        if(productUnitPriceSplit){
          bytes += generator.row([
            PosColumn(text: '', width: 2),
            PosColumn(text: '(${mergedItems[i].price}/${mergedItems[i].per_quantity_unit}${mergedItems[i].unit != 'each' && mergedItems[i].unit != 'each_c' ? mergedItems[i].unit : 'each'})', width: 7),
            PosColumn(text: '', width: 3, styles: PosStyles(align: PosAlign.right)),
          ]);
        }
        bytes += generator.reset();

        if(mergedItems[i].productVariantName != null && mergedItems[i].productVariantName != ''){
          bytes += generator.row([
            PosColumn(text: '', width: 2),
            PosColumn(text: '(${mergedItems[i].productVariantName})', width: 7, containsChinese: true, styles: PosStyles(align: PosAlign.left)),
            PosColumn(text: '', width: 3, styles: PosStyles(align: PosAlign.right)),
          ]);
        }
        bytes += generator.reset();
        //product modifier
        if(mergedItems[i].orderModifierDetail!.isNotEmpty){
          cartProductItem cartItem = mergedItems[i];
          for(int j = 0; j < cartItem.orderModifierDetail!.length; j++)
            bytes += generator.row([
              PosColumn(text: '', width: 2),
              PosColumn(text: '+${cartItem.orderModifierDetail![j].mod_name!}', width: 7, containsChinese: true, styles: PosStyles(align: PosAlign.left)),
              PosColumn(text: '', width: 3, styles: PosStyles(align: PosAlign.right)),
            ]);
        }
        //product remark
        bytes += generator.reset();
        if (mergedItems[i].remark != '') {
          bytes += generator.row([
            PosColumn(text: '', width: 2),
            PosColumn(text: '**${mergedItems[i].remark}', width: 7, containsChinese: true),
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
        PosColumn(text: 'Final Amount($currency_code)', width: 8, styles: PosStyles(align: PosAlign.right, height: PosTextSize.size2)),
        PosColumn(
            text: '${cartModel.cartNotifierPayment[0].finalAmount}',
            width: 4,
            styles: PosStyles(align: PosAlign.right, height: PosTextSize.size2, bold: true)),
      ]);
      bytes += generator.hr();
      if(paymentSplitList.isNotEmpty) {
        for(int i = 0; i < paymentSplitList.length; i++) {
          //payment method
          bytes += generator.row([
            PosColumn(text: '${paymentSplitList[i].payment_name}', width: 8, styles: PosStyles(align: PosAlign.right)),
            PosColumn(text: '${paymentSplitList[i].payment_received}', width: 4, styles: PosStyles(align: PosAlign.right)),
          ]);
        }
      }
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
  printPreviewReceipt58mm(bool isUSB, CartModel cartModel, String orderKey, {value}) async {
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
    await getAllPaymentSplit(orderKey);

    List<int> bytes = [];
    try {
      bytes += generator.reset();
      bytes += generator.text('** Review Receipt **', styles: PosStyles(align: PosAlign.center, width: PosTextSize.size2, bold: true));
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
        PosColumn(text: 'Price($currency_code)', width: 4, styles: PosStyles(bold: true)),
      ]);
      bytes += generator.hr();
      //merge same item
      List<cartProductItem> mergedItems = mergeCartItems(cartModel);

      //order product
      for(int i = 0; i < mergedItems.length; i++){
        bool productUnitPriceSplit = productNameDisplayCart(mergedItems, i, 58);
        bytes += generator.row([
          PosColumn(text: '${mergedItems[i].quantity}', width: 2),
          PosColumn(
              text: productUnitPriceSplit  ? getPreviewReceiptProductName(mergedItems[i])
                  : '${getPreviewReceiptProductName(mergedItems[i])} (${mergedItems[i].price}/${mergedItems[i].per_quantity_unit}${mergedItems[i].unit != 'each' && mergedItems[i].unit != 'each_c' ? mergedItems[i].unit : 'each'})',
              width: 6,
              containsChinese: true,
              styles: PosStyles(bold: true)),
          PosColumn(
            text: '${(double.parse(mergedItems[i].price!)*mergedItems[i].quantity!).toStringAsFixed(2)}',
            width: 4,
          ),
        ]);
        bytes += generator.reset();

        if(productUnitPriceSplit){
          bytes += generator.row([
            PosColumn(text: '', width: 2),
            PosColumn(text: '(${mergedItems[i].price}/${mergedItems[i].per_quantity_unit}${mergedItems[i].unit != 'each' && mergedItems[i].unit != 'each_c' ? mergedItems[i].unit : 'each'})', width: 10),
          ]);
        }
        bytes += generator.reset();

        if(mergedItems[i].productVariantName != null && mergedItems[i].productVariantName != ''){
          bytes += generator.row([
            PosColumn(text: '', width: 2),
            PosColumn(text: '(${mergedItems[i].productVariantName})', width: 10, containsChinese: true),
          ]);
        }
        //product modifier
        if(mergedItems[i].orderModifierDetail!.isNotEmpty){
          cartProductItem cartItem = mergedItems[i];
          for(int j = 0; j < cartItem.orderModifierDetail!.length; j++){
            bytes += generator.row([
              PosColumn(text: '', width: 2),
              PosColumn(text: '+${cartItem.orderModifierDetail![j].mod_name!}', width: 10, containsChinese: true),
            ]);
          }
        }
        //product remark
        bytes += generator.reset();
        if (mergedItems[i].remark != '') {
          bytes += generator.row([
            PosColumn(text: '', width: 2),
            PosColumn(text: '**${mergedItems[i].remark}', width: 6, containsChinese: true),
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
        PosColumn(text: 'Final Amount($currency_code)', width: 8),
        PosColumn(
            text: '${cartModel.cartNotifierPayment[0].finalAmount}',
            width: 4,
            styles: PosStyles(height: PosTextSize.size2, bold: true)),
      ]);
      bytes += generator.hr();
      if(paymentSplitList.isNotEmpty) {
        for(int i = 0; i < paymentSplitList.length; i++) {
          //payment method
          bytes += generator.row([
            PosColumn(text: '${paymentSplitList[i].payment_name}', width: 8),
            PosColumn(text: '${paymentSplitList[i].payment_received}', width: 4),
          ]);
        }
      }
      bytes += generator.emptyLines(1);
      //copyright
      bytes += generator.text('POWERED BY OPTIMY POS', styles: PosStyles(bold: true, align: PosAlign.center));
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

  getAllPaymentSplit(String orderKey) async {
    try {
      paymentSplitList = [];
      if(orderKey != '') {
        List<OrderPaymentSplit> orderSplit = await PosDatabase.instance.readSpecificOrderSplitByOrderKey(orderKey);
        for(int k = 0; k < orderSplit.length; k++){
          paymentSplitList.add(orderSplit[k]);
        }
      }
    } catch(e) {
      print("Total payment split: $e");
    }
  }

  List<cartProductItem> mergeCartItems(CartModel cartModel) {
    List<cartProductItem> mergedItems = cartModel.cartNotifierItem.map((item) => item.clone()).toList();
    Set<int> indicesToRemove = {};

    for (int i = mergedItems.length - 1; i >= 0; i--) {
      if (indicesToRemove.contains(i)) continue;

      for (int j = i - 1; j >= 0; j--) {
        if (indicesToRemove.contains(j)) continue;
        var item1 = mergedItems[i], item2 = mergedItems[j];
        if (item1.branch_link_product_sqlite_id == item2.branch_link_product_sqlite_id &&
          item1.product_name == item2.product_name &&
            item1.price == item2.price &&
            item1.productVariantName == item2.productVariantName &&
            item1.remark == item2.remark &&
            (item1.unit == 'each' || item1.unit == 'each_c') &&
            (item2.unit == 'each' || item2.unit == 'each_c') &&
        haveSameModifiers(item1.orderModifierDetail ?? [], item2.orderModifierDetail ?? [])) {
          item2.quantity = (item2.quantity ?? 0) + (item1.quantity ?? 0);
          indicesToRemove.add(i);
          break;
        }
      }
    }
    return mergedItems.whereIndexed((index, _) => !indicesToRemove.contains(index)).toList();
  }

  bool haveSameModifiers(List<OrderModifierDetail> modList1, List<OrderModifierDetail> modList2) {
    return modList1.length == modList2.length && modList1.map((mod) => int.parse(mod.mod_item_id!)).toSet()
            .containsAll(modList2.map((mod) => int.parse(mod.mod_item_id!)).toSet());
  }
}