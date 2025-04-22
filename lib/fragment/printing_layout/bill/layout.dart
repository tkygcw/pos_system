import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:pos_system/database/domain.dart';
import 'package:pos_system/database/pos_database.dart';
import 'package:pos_system/fragment/printing_layout/receipt_layout.dart';
import 'package:pos_system/main.dart';
import 'package:pos_system/object/branch.dart';
import 'package:pos_system/object/order_detail.dart';
import 'package:pos_system/object/order_modifier_detail.dart';
import 'package:pos_system/object/order_payment_split.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:esc_pos_utils/esc_pos_utils.dart';
import 'package:f_logs/model/flog/flog.dart';

import '../../../object/branch.dart';
import '../../../object/table.dart';
import '../../../utils/Utils.dart';

class BillLayout extends ReceiptLayout{
  /*
  Receipt layout 80mm
*/
  printReceipt80mm(bool isUSB, String orderId, List<PosTable> selectedTableList, {value, isRefund}) async {
    final prefs = await SharedPreferences.getInstance();
    final String? branch = prefs.getString('branch');
    Map branchObject = json.decode(branch!);
    Branch branchData = Branch.fromJson(json.decode(branch));
    await readReceiptLayout('80');
    if(isRefund != null && isRefund == true){
      await getRefundOrder(orderId);
      await callOrderTaxPromoDetail();
      await callRefundOrderDetail(orderId);
    } else {
      await getPaidOrder(orderId);
      await callOrderTaxPromoDetail();
      await callPaidOrderDetail(orderId);
    }
    await getAllPaymentSplit(paidOrder!.order_key!);
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
      //bytes += generator.image(decodedImage);
      bytes += generator.reset();
      if(paidOrder!.payment_status == 2) {
        bytes += generator.text('** Refund **', styles: PosStyles(align: PosAlign.center, height:PosTextSize.size2, width: PosTextSize.size2));
        bytes += generator.emptyLines(1);
      }

      if(receipt!.header_image_status == 1){
        img.Image processedImage = await getBranchLogo(receipt!.header_image_size!);
        bytes += generator.imageRaster(processedImage, align: PosAlign.center);
        bytes += generator.emptyLines(1);
      }

      if(int.tryParse(this.paidOrder!.order_queue!) != null){
        bytes += generator.text('------------------', styles: PosStyles(align: PosAlign.center, height:PosTextSize.size2, width: PosTextSize.size2));
        bytes += generator.emptyLines(1);
        bytes += generator.text('Order No: ${this.paidOrder!.order_queue!}', styles: PosStyles(align: PosAlign.center, height:PosTextSize.size2, width: PosTextSize.size2));
        bytes += generator.emptyLines(1);
        bytes += generator.text('------------------', styles: PosStyles(align: PosAlign.center, height:PosTextSize.size2, width: PosTextSize.size2));
        bytes += generator.emptyLines(1);
      }

      bytes += generator.reset();
      if(receipt!.header_text_status == 1 && receipt!.header_font_size == 0){
        bytes += generator.row([
          PosColumn(
              text: '${receipt!.header_text}',
              width: 12,
              containsChinese: true,
              styles: PosStyles(align: PosAlign.center, height: PosTextSize.size2, width: PosTextSize.size2)),
        ]);
      } else if(receipt!.header_text_status == 1 && receipt!.header_font_size == 1) {
        bytes += generator.row([
          PosColumn(
              text: '${receipt!.header_text}',
              width: 12,
              containsChinese: true,
              styles: PosStyles(align: PosAlign.center, height: PosTextSize.size1, width: PosTextSize.size1)),
        ]);
      }

      if(receipt!.second_header_text_status == 1) {
        PosTextSize productFontSize = receipt!.second_header_font_size == 0 ? PosTextSize.size1 : PosTextSize.size2;
        PosFontType productFontType = receipt!.second_header_font_size == 1 ? PosFontType.fontB : PosFontType.fontA;

        bytes += generator.row([
          PosColumn(
              text: '${receipt!.second_header_text}',
              width: 12,
              containsChinese: true,
              styles: PosStyles(
                  align: PosAlign.center,
                  fontType: productFontType,
                  height: productFontSize,
                  width: productFontSize)),
        ]);
        bytes += generator.reset();
      }

      bytes += generator.emptyLines(1);
      bytes += generator.reset();
      //register no
      if(receipt!.show_register_no == 1 && branchObject[BranchFields.register_no] != ''){
        bytes += generator.text(branchObject[BranchFields.register_no],
          containsChinese: true,
          styles: PosStyles(align: PosAlign.center),
        );
      }
      //Address
      if(receipt!.show_address == 1 && branchObject['address'].toString() != ''){
        bytes += generator.text('${branchObject['address']}', containsChinese: true, styles: PosStyles(align: PosAlign.center));
      }
      //telephone
      if(receipt!.show_branch_tel == 1 && branchObject['phone'] != ''){
        bytes += generator.text('Tel: ${branchObject['phone']}', styles: PosStyles(align: PosAlign.center, height: PosTextSize.size1));
      }
      if(receipt!.show_email == 1){
        bytes += generator.text('${receipt!.receipt_email}', styles: PosStyles(align: PosAlign.center));
      }
      bytes += generator.hr();
      bytes += generator.reset();
      //receipt no
      bytes += generator.text('Receipt No.: ${this.paidOrder!.generateOrderNumber()}',
          styles: PosStyles(
              align: PosAlign.left,
              width: PosTextSize.size1,
              height: PosTextSize.size1,
              bold: true));
      bytes += generator.reset();
      //other order detail
      bytes += generator.text('Close at: ${Utils.formatDate(paidOrder!.created_at)}');
      bytes += generator.text('Close by: ${this.paidOrder!.close_by}', containsChinese: true);
      if(receipt!.hide_dining_method_table_no == 0){
        if(selectedTableList.isNotEmpty){
          bytes += generator.text('Table No: ${getCartTableNumber(selectedTableList).toString().replaceAll('[', '').replaceAll(']', '')}');
        }
        bytes += generator.text('${paidOrder!.dining_name}');
      }

      bytes += generator.reset();
      /*
    *
    * body
    *
    * */
      bytes += generator.hr();
      bytes += generator.row([
        PosColumn(text: 'Qty ', width: 2, styles: PosStyles(bold: true)),
        PosColumn(text: 'Item', width: 7, styles: PosStyles(bold: true)),
        PosColumn(text: 'Price($currency_code)', width: 3, styles: PosStyles(bold: true, align: PosAlign.right)),
      ]);
      bytes += generator.hr();
      //merge same item
      await checkMergeOrderDetail(orderDetailList);
      //order product
      for(int i = 0; i < orderDetailList.length; i++){
        bool productUnitPriceSplit = productNameDisplayOrder(orderDetailList, i, 80);
        bytes += generator.row([
          PosColumn(text: '${orderDetailList[i].quantity}', width: 2),
          orderDetailList[i].unit != 'each' && orderDetailList[i].unit != 'each_c' ?
          PosColumn(
              text: productUnitPriceSplit  ? getReceiptProductName(orderDetailList[i])
                  : '${getReceiptProductName(orderDetailList[i])} (${receipt!.show_break_down_price == 0 ? orderDetailList[i].price : orderDetailList[i].original_price}/${orderDetailList[i].per_quantity_unit}${orderDetailList[i].unit})',
              width: 7,
              containsChinese: true,
              styles: PosStyles(align: PosAlign.left, bold: true))
              : PosColumn(
              text: productUnitPriceSplit  ? getReceiptProductName(orderDetailList[i])
                  : '${getReceiptProductName(orderDetailList[i])} (${receipt!.show_break_down_price == 0 ? orderDetailList[i].price : orderDetailList[i].original_price}/each)',
              width: 7,
              containsChinese: true,
              styles: PosStyles(align: PosAlign.left, bold: true)),
          PosColumn(
              text: '${(double.parse(orderDetailList[i].price!)*double.parse(orderDetailList[i].quantity!)).toStringAsFixed(2)} ',
              width: 3,
              styles: PosStyles(align: PosAlign.right)),
        ]);
        bytes += generator.reset();

        if(productUnitPriceSplit){
          bytes += generator.row([
            PosColumn(text: '', width: 2),
            PosColumn(text: orderDetailList[i].unit != 'each' && orderDetailList[i].unit != 'each_c' ? '(${receipt!.show_break_down_price == 0 ? orderDetailList[i].price : orderDetailList[i].original_price}/${orderDetailList[i].per_quantity_unit}${orderDetailList[i].unit})'
                : '(${receipt!.show_break_down_price == 0 ? orderDetailList[i].price : orderDetailList[i].original_price}/each)', width: 7),
            PosColumn(text: '', width: 3, styles: PosStyles(align: PosAlign.right)),
          ]);
        }
        bytes += generator.reset();
        if(orderDetailList[i].has_variant == '1'){
          bytes += generator.row([
            PosColumn(text: '', width: 2),
            PosColumn(text: '(${orderDetailList[i].product_variant_name!})', width: 7, containsChinese: true, styles: PosStyles(align: PosAlign.left)),
            PosColumn(text: '', width: 3, styles: PosStyles(align: PosAlign.right)),
          ]);
        }
        bytes += generator.reset();
        await getPaidOrderModifierDetail(orderDetailList[i]);
        if(orderModifierDetailList.length > 0){
          for(int j = 0; j < orderModifierDetailList.length; j++){
            //modifier
            bytes += generator.row([
              PosColumn(text: '', width: 2, styles: PosStyles(align: PosAlign.right)),
              PosColumn(text: '+${orderModifierDetailList[j].mod_name}${receipt!.show_break_down_price == 0 ? '' : ' (${double.parse(orderModifierDetailList[j].mod_price!).toStringAsFixed(2)}/each)'}', width: 7, containsChinese: true),
              PosColumn(text: '', width: 3, styles: PosStyles(align: PosAlign.right)),
            ]);
          }
        }
        //product remark
        bytes += generator.reset();
        if (orderDetailList[i].remark != '') {
          bytes += generator.row([
            PosColumn(text: '', width: 2, styles: PosStyles(align: PosAlign.right)),
            PosColumn(text: '**${orderDetailList[i].remark}', width: 7, containsChinese: true),
            PosColumn(text: '', width: 3, styles: PosStyles(align: PosAlign.right)),
          ]);
        }
        // bytes += generator.emptyLines(1);
      }
      bytes += generator.hr();
      bytes += generator.reset();
      //item count
      int receiptItemCount = 0;
      for(int i = 0; i < orderDetailList.length; i++){
        receiptItemCount += orderDetailList[i].unit != 'each' && orderDetailList[i].unit != 'each_c' ? 1 : int.parse(orderDetailList[i].quantity!);
      }
      bytes += generator.text('Item count: ${receiptItemCount}');
      bytes += generator.hr();
      bytes += generator.reset();
      //total calc
      bytes += generator.row([
        PosColumn(text: 'SubTotal', width: 8, styles: PosStyles(align: PosAlign.right)),
        PosColumn(text: '${this.paidOrder!.subtotal}', width: 4, styles: PosStyles(align: PosAlign.right)),
      ]);
      //discount
      if(receipt!.promotion_detail_status == 1){
        for(int p = 0; p < orderPromotionList.length; p++){
          bytes += generator.row([
            PosColumn(text: '${orderPromotionList[p].promotion_name}(${orderPromotionList[p].rate})', width: 8, containsChinese: true, styles: PosStyles(align: PosAlign.right)),
            PosColumn(text: '-${orderPromotionList[p].promotion_amount}', width: 4, styles: PosStyles(align: PosAlign.right)),
          ]);
        }
      } else {
        bytes += generator.row([
          PosColumn(text: 'Total discount', width: 8, styles: PosStyles(align: PosAlign.right)),
          PosColumn(text: '-${this.totalPromotion.toStringAsFixed(2)}', width: 4, styles: PosStyles(align: PosAlign.right)),
        ]);
      }
      //tax
      for(int t = 0; t < orderTaxList.length; t++){
        bytes += generator.row([
          PosColumn(text: '${orderTaxList[t].tax_name}(${orderTaxList[t].rate}%)', width: 8, styles: PosStyles(align: PosAlign.right)),
          PosColumn(text: '${orderTaxList[t].tax_amount}', width: 4, styles: PosStyles(align: PosAlign.right)),
        ]);
      }
      //Amount
      bytes += generator.row([
        PosColumn(text: 'Amount', width: 8, styles: PosStyles(align: PosAlign.right)),
        PosColumn(text: '${this.paidOrder!.amount}', width: 4, styles: PosStyles(align: PosAlign.right)),
      ]);
      //rounding
      bytes += generator.row([
        PosColumn(text: 'Rounding', width: 8, styles: PosStyles(align: PosAlign.right)),
        PosColumn(text: '${this.paidOrder!.rounding}', width: 4, styles: PosStyles(align: PosAlign.right)),
      ]);
      //total
      bytes += generator.hr();
      bytes += generator.row([
        PosColumn(text: 'Final Amount($currency_code)', width: 8, styles: PosStyles(align: PosAlign.right, height: PosTextSize.size2)),
        PosColumn(
            text: '${this.paidOrder!.final_amount}',
            width: 4,
            styles: PosStyles(align: PosAlign.right, height: PosTextSize.size2, bold: true)),
      ]);
      bytes += generator.hr();
      if(paymentSplitList.isNotEmpty) {
        for(int i = 0; i < paymentSplitList.length; i++) {
          //payment method
          bytes += generator.row([
            PosColumn(text: '${paymentSplitList[i].payment_name}', width: 8, containsChinese: true, styles: PosStyles(align: PosAlign.right)),
            PosColumn(text: '${paymentSplitList[i].payment_received}', width: 4, styles: PosStyles(align: PosAlign.right)),
          ]);
        }
      } else {
        //payment method
        bytes += generator.row([
          PosColumn(text: 'Payment method', width: 8, styles: PosStyles(align: PosAlign.right)),
          PosColumn(text: '${this.paidOrder!.payment_name}', width: 4, containsChinese: true, styles: PosStyles(align: PosAlign.right)),
        ]);
        //payment received
        bytes += generator.row([
          PosColumn(text: 'Payment received', width: 8, styles: PosStyles(align: PosAlign.right)),
          PosColumn(text: '${this.paidOrder!.payment_received}', width: 4, styles: PosStyles(align: PosAlign.right)),
        ]);
      }
      //payment change
      bytes += generator.row([
        PosColumn(text: 'Change', width: 8, styles: PosStyles(align: PosAlign.right)),
        PosColumn(text: '${this.paidOrder!.payment_change}', width: 4, styles: PosStyles(align: PosAlign.right)),
      ]);
      bytes += generator.hr();
      if(branchData.allow_einvoice == 1 && branchData.einvoice_status == 1){
        bytes += generator.text('E-invoice', styles: PosStyles(bold: true, align: PosAlign.center));
        bytes += generator.qrcode(generateQrUrl(branchData.branch_url!), size: QRSize.Size3, cor: QRCorrection.M);
        bytes += generator.text('Request Timeline:', styles: PosStyles(bold: true));
        bytes += generator.text('Last Date: 1st calender day of the following month');
        bytes += generator.hr();
      }
      //footer
      if(receipt!.footer_text_status == 1 && paidOrder!.payment_status == 1){
        bytes += generator.emptyLines(1);
        bytes += generator.text('${receipt!.footer_text}', styles: PosStyles(bold: true, align: PosAlign.center, height: PosTextSize.size1, width: PosTextSize.size1), containsChinese: true);
      } else if(paidOrder!.payment_status == 2) {
        bytes += generator.text('refund by: ${paidOrder!.refund_by}', styles: PosStyles(align: PosAlign.center));
        // bytes += generator.text('${paidOrder!.refund_by}', containsChinese: true, styles: PosStyles(align: PosAlign.center));
        bytes += generator.text('refund at: ${Utils.formatDate(paidOrder!.refund_at)}', styles: PosStyles(align: PosAlign.center));
        // bytes += generator.text('${Utils.formatDate(paidOrder!.refund_at)}', styles: PosStyles(align: PosAlign.center));
      }
      bytes += generator.emptyLines(1);
      //copyright
      bytes += generator.text('POWERED BY OPTIMY POS', styles: PosStyles(bold: true, align: PosAlign.center));
      bytes += generator.feed(1);
      bytes += generator.cut(mode: PosCutMode.partial);
      return bytes;
    } catch (e) {
      print('layout error: ${e}');
      FLog.error(
        className: "bill layout",
        text: "print receipt 80mm error",
        exception: e,
      );
      return null;
    }
  }

/*
  Receipt layout 58mm
*/
  printReceipt58mm(bool isUSB, String orderId, List<PosTable> selectedTableList, {value, isRefund}) async {
    final prefs = await SharedPreferences.getInstance();
    final String? branch = prefs.getString('branch');
    Map branchObject = json.decode(branch!);
    Branch branchData = Branch.fromJson(json.decode(branch));
    await readReceiptLayout('58');
    if(isRefund != null && isRefund == true){
      await getRefundOrder(orderId);
      await callOrderTaxPromoDetail();
      await callRefundOrderDetail(orderId);
    } else {
      await getPaidOrder(orderId);
      await callOrderTaxPromoDetail();
      await callPaidOrderDetail(orderId);
    }
    await getAllPaymentSplit(paidOrder!.order_key!);
    // final ByteData data = await rootBundle.load('drawable/logo1.jpg');
    // final Uint8List bytes = data.buffer.asUint8List();
    // final image = img.decodeImage(bytes);
    // print('image byte: ${image}');

    var generator;
    if (isUSB) {
      final profile = await CapabilityProfile.load();
      generator = Generator(PaperSize.mm58, profile);
    } else {
      generator = value;
    }

    List<int> bytes = [];
    try {
      //bytes += generator.image(image);
      bytes += generator.reset();
      if(paidOrder!.payment_status == 2){
        bytes += generator.text('** Refund **', styles: PosStyles(align: PosAlign.center, height:PosTextSize.size2, width: PosTextSize.size2 ));
        bytes += generator.emptyLines(1);
      }

      if(receipt!.header_image_status == 1){
        img.Image processedImage = await getBranchLogo(receipt!.header_image_size!);
        bytes += generator.imageRaster(processedImage, align: PosAlign.center);
        bytes += generator.emptyLines(1);
      }

      if(int.tryParse(this.paidOrder!.order_queue!) != null){
        bytes += generator.text('---------------', styles: PosStyles(align: PosAlign.center, height:PosTextSize.size2, width: PosTextSize.size2));
        bytes += generator.emptyLines(1);
        bytes += generator.text('Order No: ${this.paidOrder!.order_queue!}', styles: PosStyles(align: PosAlign.center, height:PosTextSize.size2, width: PosTextSize.size2));
        bytes += generator.emptyLines(1);
        bytes += generator.text('---------------', styles: PosStyles(align: PosAlign.center, height:PosTextSize.size2, width: PosTextSize.size2));
        bytes += generator.emptyLines(1);
      }

      bytes += generator.reset();
      if(receipt!.header_text_status == 1 && receipt!.header_font_size == 0){
        bytes += generator.row([
          PosColumn(
              text: '${receipt!.header_text}',
              width: 12,
              containsChinese: true,
              styles: PosStyles(align: PosAlign.center, height: PosTextSize.size2, width: PosTextSize.size2)),
        ]);
      } else if(receipt!.header_text_status == 1 && receipt!.header_font_size == 1) {
        bytes += generator.row([
          PosColumn(
              text: '${receipt!.header_text}',
              width: 12,
              containsChinese: true,
              styles: PosStyles(align: PosAlign.center, height: PosTextSize.size1, width: PosTextSize.size1)),
        ]);
      }

      if(receipt!.second_header_text_status == 1) {
        PosTextSize productFontSize = receipt!.second_header_font_size == 0 ? PosTextSize.size1 : PosTextSize.size2;
        PosFontType productFontType = receipt!.second_header_font_size == 1 ? PosFontType.fontB : PosFontType.fontA;

        bytes += generator.row([
          PosColumn(
              text: '${receipt!.second_header_text}',
              width: 12,
              containsChinese: true,
              styles: PosStyles(
                  align: PosAlign.center,
                  fontType: productFontType,
                  height: productFontSize,
                  width: productFontSize)),
        ]);
        bytes += generator.reset();
      }

      bytes += generator.emptyLines(1);
      bytes += generator.reset();
      //register no
      if(receipt!.show_register_no == 1 && branchObject[BranchFields.register_no] != ''){
        bytes += generator.text(branchObject[BranchFields.register_no],
          containsChinese: true,
          styles: PosStyles(align: PosAlign.center),
        );
      }
      //Address
      if(receipt!.show_address == 1 && branchObject['address'].toString() != ''){
        bytes += generator.text('${branchObject['address'].toString().replaceAll(',', '\n')}', containsChinese: true, styles: PosStyles(align: PosAlign.center));
      }
      //telephone
      if(receipt!.show_branch_tel == 1 && branchObject['phone'] != ''){
        bytes += generator.text('Tel: ${branchObject['phone']}',
            styles: PosStyles(align: PosAlign.center, height: PosTextSize.size1));
      }
      if(receipt!.show_email == 1){
        bytes += generator.text('${receipt!.receipt_email}', styles: PosStyles(align: PosAlign.center));
      }

      bytes += generator.hr();
      bytes += generator.reset();
      //receipt no
      // bytes += generator.text('Receipt No:',
      //     styles: PosStyles(
      //         align: PosAlign.center,
      //         width: PosTextSize.size1,
      //         height: PosTextSize.size1,
      //         bold: true));
      // bytes += generator.text('${this.paidOrder!.generateOrderNumber()}', styles: PosStyles(align: PosAlign.center, bold: true));
      bytes += generator.text('Receipt No: ${this.paidOrder!.generateOrderNumber()}',
          styles: PosStyles(
              align: PosAlign.left,
              width: PosTextSize.size1,
              height: PosTextSize.size1,
              bold: true));
      bytes += generator.reset();
      //other order detail
      // bytes += generator.text('Close at:', styles: PosStyles(align: PosAlign.center));
      // bytes += generator.text('${Utils.formatDate(paidOrder!.created_at)}', styles: PosStyles(align: PosAlign.center));
      bytes += generator.text('Close at: ${Utils.formatDate(paidOrder!.created_at)}');
      // bytes += generator.text('Close by:', styles: PosStyles(align: PosAlign.center));
      // bytes += generator.text('${this.paidOrder!.close_by}', containsChinese: true, styles: PosStyles(align: PosAlign.center));
      bytes += generator.text('Close by: ${this.paidOrder!.close_by}', containsChinese: true);
      if(receipt!.hide_dining_method_table_no == 0){
        if(selectedTableList.isNotEmpty){
          for(int i = 0; i < selectedTableList.length; i++){
            bytes += generator.text('Table No: ${selectedTableList[i].number}');
          }
        }
        bytes += generator.text('${paidOrder!.dining_name}');
      }

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
      await checkMergeOrderDetail(orderDetailList);
      //order product
      for(int i = 0; i < orderDetailList.length; i++){
        bool productUnitPriceSplit = productNameDisplayOrder(orderDetailList, i, 58);
        bytes += generator.row([
          PosColumn(text: '${orderDetailList[i].quantity}', width: 2),
          orderDetailList[i].unit != 'each' && orderDetailList[i].unit != 'each_c' ?
          PosColumn(
              text: productUnitPriceSplit  ? getReceiptProductName(orderDetailList[i])
                  : '${getReceiptProductName(orderDetailList[i])} (${receipt!.show_break_down_price == 0 ? orderDetailList[i].price : orderDetailList[i].original_price}/${orderDetailList[i].per_quantity_unit}${orderDetailList[i].unit})',
              width: 6,
              containsChinese: true,
              styles: PosStyles(bold: true))
              : PosColumn(
              text: productUnitPriceSplit  ? getReceiptProductName(orderDetailList[i])
                  : '${getReceiptProductName(orderDetailList[i])} (${receipt!.show_break_down_price == 0 ? orderDetailList[i].price : orderDetailList[i].original_price}/each)',
              width: 6,
              containsChinese: true,
              styles: PosStyles(bold: true)),
          PosColumn(text: '${(double.parse(orderDetailList[i].price!)*double.parse(orderDetailList[i].quantity!)).toStringAsFixed(2)}', width: 4),
        ]);
        bytes += generator.reset();

        if(productUnitPriceSplit){
          bytes += generator.row([
            PosColumn(text: '', width: 2),
            PosColumn(text: orderDetailList[i].unit != 'each' && orderDetailList[i].unit != 'each_c' ? '(${receipt!.show_break_down_price == 0 ? orderDetailList[i].price : orderDetailList[i].original_price}/${orderDetailList[i].per_quantity_unit}${orderDetailList[i].unit})'
                : '(${receipt!.show_break_down_price == 0 ? orderDetailList[i].price : orderDetailList[i].original_price}/each)', width: 10),
          ]);
        }
        bytes += generator.reset();

        if(orderDetailList[i].has_variant == '1'){
          bytes += generator.row([
            PosColumn(text: '', width: 2),
            PosColumn(text: '(${orderDetailList[i].product_variant_name!})', width: 10, containsChinese: true),
          ]);
        }
        bytes += generator.reset();
        await getPaidOrderModifierDetail(orderDetailList[i]);
        if(orderModifierDetailList.length > 0){
          for(int j = 0; j < orderModifierDetailList.length; j++){
            //modifier
            bytes += generator.row([
              PosColumn(text: '', width: 2),
              PosColumn(text: '+${orderModifierDetailList[j].mod_name}${receipt!.show_break_down_price == 0 ? '' : ' (${double.parse(orderModifierDetailList[j].mod_price!).toStringAsFixed(2)}/each)'}', width: 10, containsChinese: true),
            ]);
          }
        }
        //product remark
        bytes += generator.reset();
        if (orderDetailList[i].remark != '') {
          bytes += generator.row([
            PosColumn(text: '', width: 2),
            PosColumn(text: '**${orderDetailList[i].remark}', width: 10, containsChinese: true),
          ]);
        }
      }
      bytes += generator.hr();
      bytes += generator.reset();
      //item count
      int receiptItemCount = 0;
      for(int i = 0; i < orderDetailList.length; i++){
        receiptItemCount += orderDetailList[i].unit != 'each' && orderDetailList[i].unit != 'each_c' ? 1 : int.parse(orderDetailList[i].quantity!);
      }
      bytes += generator.text('Item count: ${receiptItemCount}');
      bytes += generator.hr();
      bytes += generator.reset();
      //total calc
      bytes += generator.row([
        PosColumn(text: 'SubTotal', width: 8),
        PosColumn(text: '${this.paidOrder!.subtotal}', width: 4),
      ]);
      //discount
      bytes += generator.row([
        PosColumn(text: 'Total discount', width: 8),
        PosColumn(text: '-${this.totalPromotion.toStringAsFixed(2)}', width: 4),
      ]);
      //tax
      for(int t = 0; t < orderTaxList.length; t++){
        bytes += generator.row([
          PosColumn(text: '${orderTaxList[t].tax_name}(${orderTaxList[t].rate}%)', width: 8),
          PosColumn(text: '${orderTaxList[t].tax_amount}', width: 4),
        ]);
      }

      //Amount
      bytes += generator.row([
        PosColumn(text: 'Amount', width: 8),
        PosColumn(text: '${this.paidOrder!.amount}', width: 4),
      ]);
      //rounding
      bytes += generator.row([
        PosColumn(text: 'Rounding', width: 8),
        PosColumn(text: '${this.paidOrder!.rounding}', width: 4),
      ]);
      //total
      bytes += generator.hr();
      bytes += generator.row([
        PosColumn(text: 'Final Amount($currency_code)', width: 8),
        PosColumn(
            text: '${this.paidOrder!.final_amount}',
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
      } else {
        //payment method
        bytes += generator.row([
          PosColumn(text: 'Payment method', width: 8),
          PosColumn(text: '${this.paidOrder!.payment_name}', width: 4),
        ]);
        //payment received
        bytes += generator.row([
          PosColumn(text: 'Payment received', width: 8),
          PosColumn(text: '${this.paidOrder!.payment_received}', width: 4),
        ]);
      }
      //payment change
      bytes += generator.row([
        PosColumn(text: 'Change', width: 8),
        PosColumn(text: '${this.paidOrder!.payment_change}', width: 4),
      ]);
      bytes += generator.hr();
      bytes += generator.reset();
      if(branchData.allow_einvoice == 1 && branchData.einvoice_status == 1){
        bytes += generator.text('E-invoice', styles: PosStyles(bold: true, align: PosAlign.center));
        bytes += generator.qrcode(generateQrUrl(branchData.branch_url!), size: QRSize.Size3, cor: QRCorrection.M);
        bytes += generator.text('Request Timeline:', styles: PosStyles(bold: true));
        bytes += generator.text('Last Date: 1st calender day of the following month');
        bytes += generator.hr();
      }
      //footer
      if(receipt!.footer_text_status == 1 && paidOrder!.payment_status == 1){
        bytes += generator.emptyLines(1);
        bytes += generator.text('${receipt!.footer_text}', styles: PosStyles(bold: true, height: PosTextSize.size1, width: PosTextSize.size1, align: PosAlign.center), containsChinese: true);
      } else if (paidOrder!.payment_status == 2) {
        bytes += generator.text('refund by: ${paidOrder!.refund_by}', styles: PosStyles(align: PosAlign.center));
        // bytes += generator.text('${paidOrder!.refund_by}', containsChinese: true, styles: PosStyles(align: PosAlign.center));
        bytes += generator.text('refund at: ${Utils.formatDate(paidOrder!.refund_at)}', styles: PosStyles(align: PosAlign.center));
        // bytes += generator.text('${Utils.formatDate(paidOrder!.refund_at)}', styles: PosStyles(align: PosAlign.center));
      }
      bytes += generator.emptyLines(1);
      //copyright
      bytes += generator.text('POWERED BY OPTIMY POS', styles: PosStyles(bold: true, align: PosAlign.center));
      bytes += generator.feed(1);
      bytes += generator.cut(mode: PosCutMode.partial);
      return bytes;
    } catch (e) {
      print("print 58mm receipt layout error: $e");
      FLog.error(
        className: "bill layout",
        text: "print receipt 58mm error",
        exception: e,
      );
      return null;
    }
  }

  String generateQrUrl(String branchUrl){
    return '${Domain.einvoice}$branchUrl/${this.paidOrder!.generateOrderNumber().toString().replaceAll('#', '')}?id=${paidOrder!.order_key}';
  }

  Future<img.Image> getBranchLogo(int header_image_size) async {
    int imageSize = header_image_size == 0 ? 100 : header_image_size == 1 ? 160 : 220;
    final prefs = await SharedPreferences.getInstance();
    final String? branch = prefs.getString('branch');
    Map branchObject = json.decode(branch!);
    String? path = '';

    if(Platform.isIOS){
      String dir = await _localPath;
      path = dir + '/assets/logo';
    } else {
      if(prefs.getString('logo_path') != null)
        path = prefs.getString('logo_path')!;
    }

    if(path != '') {
      final File imageFile = File('$path/${branchObject['logo']}');
      if (!await imageFile.exists()) {
        return img.Image(width: 1, height: 1);
      }
      final Uint8List imageBytes = await imageFile.readAsBytes();
      final img.Image decodedImage = img.decodeImage(imageBytes)!;
      img.Image thumbnail = img.copyResize(decodedImage, height: imageSize);
      img.Image originalImg = img.copyResize(decodedImage, width: 380, height: imageSize);
      img.fill(originalImg, color: img.ColorRgb8(255, 255, 255));

      var padding = (originalImg.width - thumbnail.width) / 2;
      img.compositeImage(originalImg, thumbnail, dstX: padding.toInt());
      img.Image processedImage = img.adjustColor(originalImg, saturation: -100, contrast: 100, gamma: 10);

      return processedImage;
    } else {
      return img.Image(width: 1, height: 1);
    }
  }

  Future<String> get _localPath async {
    final directory = await getApplicationSupportDirectory();
    return directory.path;
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

  checkMergeOrderDetail(List<OrderDetail> orderDetailList) async {
    for (int i = orderDetailList.length - 1; i >= 0; i--) {
      await getPaidOrderModifierDetail(orderDetailList[i]);
      orderDetailList[i].orderModifierDetail = orderModifierDetailList;
      for (int j = i - 1; j >= 0; j--) {
        var item1 = orderDetailList[i], item2 = orderDetailList[j];

        if (item1.branch_link_product_sqlite_id == item2.branch_link_product_sqlite_id &&
            item1.productName == item2.productName &&
            item1.price == item2.price &&
            item1.product_variant_name == item2.product_variant_name &&
            item1.remark == item2.remark &&
            (item1.unit == 'each' || item1.unit == 'each_c') &&
            (item2.unit == 'each' || item2.unit == 'each_c') &&
            haveSameModifiers(item1.orderModifierDetail, item2.orderModifierDetail)) {

          item2.quantity = (int.parse(item2.quantity!) + int.parse(item1.quantity!)).toString();
          orderDetailList.removeAt(i);
          break;
        }
      }
    }
  }

  bool haveSameModifiers(List<OrderModifierDetail> modList1, List<OrderModifierDetail> modList2) {
    return modList1.length == modList2.length && modList1.map((mod) => int.parse(mod.mod_item_id!)).toSet()
        .containsAll(modList2.map((mod) => int.parse(mod.mod_item_id!)).toSet());
  }
}

