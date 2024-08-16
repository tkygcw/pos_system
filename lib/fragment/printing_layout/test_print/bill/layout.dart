import 'dart:convert';

import 'package:pos_system/fragment/printing_layout/receipt_layout.dart';

import 'package:image/image.dart' as img;
import 'package:flutter/services.dart';
import 'package:pos_system/fragment/printing_layout/receipt_layout.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:esc_pos_utils/esc_pos_utils.dart';
import 'package:f_logs/model/flog/flog.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../object/receipt.dart';

class ReceiptTestPrintLayout extends ReceiptLayout{
  /*
  Test print Receipt layout 80mm
*/
  printTestReceipt80mm(bool isUSB, Receipt receipt2, {value}) async {
    String dateTime = dateFormat.format(DateTime.now());
    final prefs = await SharedPreferences.getInstance();
    final String? branch = prefs.getString('branch');
    Map branchObject = json.decode(branch!);
    this.receipt = receipt2;
    var generator;
    if (isUSB) {
      final profile = await CapabilityProfile.load();
      generator = Generator(PaperSize.mm80, profile);
    } else {
      generator = value;
    }

    List<int> bytes = [];
    try {
      if(receipt!.show_branch_image == 1){
        final decodedImage = await getBranchLogoImg();
        bytes += generator.image(decodedImage);
      }
      if(receipt!.header_text_status == 1 && receipt!.header_font_size == 0){
        ///big font
        // bytes += generator.text('${receipt!.header_text}', styles: PosStyles(align: PosAlign.center, height: PosTextSize.size2, width: PosTextSize.size2));
        bytes += generator.row([
          PosColumn(
              text: '${receipt!.header_text}',
              width: 12,
              containsChinese: true,
              styles: PosStyles(align: PosAlign.center, height: PosTextSize.size2, width: PosTextSize.size2)),
        ]);
      } else if(receipt!.header_text_status == 1 && receipt!.header_font_size == 1) {
        ///small font
        bytes += generator.row([
          PosColumn(
              text: '${receipt!.header_text}',
              width: 12,
              containsChinese: true,
              styles: PosStyles(align: PosAlign.center, height: PosTextSize.size1, width: PosTextSize.size1)),
        ]);
      }
      bytes += generator.emptyLines(1);
      bytes += generator.reset();
      //Address
      if(receipt!.show_address == 1 && branchObject['address'].toString() != ''){
        bytes += generator.text('${branchObject['address']}', containsChinese: true, styles: PosStyles(align: PosAlign.center, ));
      }
      //telephone
      if(receipt!.show_branch_tel == 1){
        bytes += generator.text('Tel: ${branchObject['phone']}', styles: PosStyles(align: PosAlign.center, height: PosTextSize.size1));
      }
      if(receipt!.show_email == 1){
        bytes += generator.text('${receipt!.receipt_email}', styles: PosStyles(align: PosAlign.center));
      }
      bytes += generator.hr();
      bytes += generator.reset();
      //receipt no
      bytes += generator.text('Receipt No: #00001-001-12345678',
          styles: PosStyles(
              align: PosAlign.left,
              width: PosTextSize.size1,
              height: PosTextSize.size1,
              bold: true));
      bytes += generator.reset();
      //other order detail
      bytes += generator.text('Close at: 31/12/2021 00:00 AM');
      bytes += generator.text('Close by: Waiter');
      bytes += generator.text('Table No: 1');
      bytes += generator.text('Dine in');
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
        PosColumn(text: 'Price', width: 3, styles: PosStyles(bold: true, align: PosAlign.right)),
      ]);
      bytes += generator.hr();
      //order product
      bytes += generator.row([
        PosColumn(text: '2', width: 2),
        PosColumn(
            text: '${getTestPrintProductSKU(1, layout: receipt)}Product 1 (2.00/each)',
            width: 7,
            containsChinese: true,
            styles: PosStyles(align: PosAlign.left, bold: true)),
        PosColumn(
            text: '4.00',
            width: 3,
            styles: PosStyles(align: PosAlign.right)),
      ]);
      bytes += generator.row([
        PosColumn(text: '1', width: 2),
        PosColumn(
            text: '${getTestPrintProductSKU(2, layout: receipt)}Product 2 (2.00/each)',
            width: 7,
            containsChinese: true,
            styles: PosStyles(align: PosAlign.left, bold: true)),
        PosColumn(
            text: '2.00',
            width: 3,
            styles: PosStyles(align: PosAlign.right)),
      ]);
      bytes += generator.hr();
      bytes += generator.reset();
      //item count
      bytes += generator.text('Item count: 3');
      bytes += generator.hr();
      bytes += generator.reset();
      //total calc
      bytes += generator.row([
        PosColumn(text: 'SubTotal', width: 8, styles: PosStyles(align: PosAlign.right)),
        PosColumn(text: '6.00', width: 4, styles: PosStyles(align: PosAlign.right)),
      ]);
      //discount
      if(receipt!.promotion_detail_status == 1){
        bytes += generator.row([
          PosColumn(text: 'Discount1(1.00)', width: 8, containsChinese: true, styles: PosStyles(align: PosAlign.right)),
          PosColumn(text: '-1.00', width: 4, styles: PosStyles(align: PosAlign.right)),
        ]);
        bytes += generator.row([
          PosColumn(text: 'Discount2(1.00)', width: 8, containsChinese: true, styles: PosStyles(align: PosAlign.right)),
          PosColumn(text: '-1.00', width: 4, styles: PosStyles(align: PosAlign.right)),
        ]);
      } else {
        bytes += generator.row([
          PosColumn(text: 'Total discount', width: 8, styles: PosStyles(align: PosAlign.right)),
          PosColumn(text: '-2.00', width: 4, styles: PosStyles(align: PosAlign.right)),
        ]);
      }
      //tax
      bytes += generator.row([
        PosColumn(text: 'Tax1(10%)', width: 8, styles: PosStyles(align: PosAlign.right)),
        PosColumn(text: '0.40', width: 4, styles: PosStyles(align: PosAlign.right)),
      ]);
      bytes += generator.row([
        PosColumn(text: 'Tax2(6%)', width: 8, styles: PosStyles(align: PosAlign.right)),
        PosColumn(text: '0.24', width: 4, styles: PosStyles(align: PosAlign.right)),
      ]);
      //Amount
      bytes += generator.row([
        PosColumn(text: 'Amount', width: 8, styles: PosStyles(align: PosAlign.right)),
        PosColumn(text: '3.36', width: 4, styles: PosStyles(align: PosAlign.right)),
      ]);
      //rounding
      bytes += generator.row([
        PosColumn(text: 'Rounding', width: 8, styles: PosStyles(align: PosAlign.right)),
        PosColumn(text: '+0.04', width: 4, styles: PosStyles(align: PosAlign.right)),
      ]);
      //total
      bytes += generator.hr();
      bytes += generator.row([
        PosColumn(text: 'Final Amount', width: 8, styles: PosStyles(align: PosAlign.right, height: PosTextSize.size2)),
        PosColumn(
            text: '3.40',
            width: 4,
            styles: PosStyles(align: PosAlign.right, height: PosTextSize.size2, bold: true)),
      ]);
      bytes += generator.hr();
      //payment method
      bytes += generator.row([
        PosColumn(text: 'Payment method', width: 8, styles: PosStyles(align: PosAlign.right)),
        PosColumn(text: 'Cash', width: 4, styles: PosStyles(align: PosAlign.right)),
      ]);
      //payment received
      bytes += generator.row([
        PosColumn(text: 'Payment received', width: 8, styles: PosStyles(align: PosAlign.right)),
        PosColumn(text: '5.00', width: 4, styles: PosStyles(align: PosAlign.right)),
      ]);
      //payment change
      bytes += generator.row([
        PosColumn(text: 'Change', width: 8, styles: PosStyles(align: PosAlign.right)),
        PosColumn(text: '1.60', width: 4, styles: PosStyles(align: PosAlign.right)),
      ]);
      //footer
      if(receipt!.footer_text_status == 1){
        bytes += generator.emptyLines(1);
        bytes += generator.text('${receipt!.footer_text}', containsChinese: true, styles: PosStyles(bold: true, align: PosAlign.center, height: PosTextSize.size1, width: PosTextSize.size1));
      }
      // else if(paidOrder!.payment_status == 2) {
      //   bytes += generator.hr();
      //   bytes += generator.text('refund by:', styles: PosStyles(align: PosAlign.center));
      //   bytes += generator.text('${paidOrder!.refund_by}', styles: PosStyles(align: PosAlign.center));
      //   bytes += generator.text('refund at:', styles: PosStyles(align: PosAlign.center));
      //   bytes += generator.text('${Utils.formatDate(paidOrder!.refund_at)}', styles: PosStyles(align: PosAlign.center));
      // }
      bytes += generator.emptyLines(1);
      //copyright
      bytes += generator.text('POWERED BY OPTIMY POS', styles: PosStyles(bold: true, align: PosAlign.center));
      bytes += generator.feed(1);
      bytes += generator.cut(mode: PosCutMode.partial);
      return bytes;
    } catch (e) {
      print('layout error: ${e}');
      return null;
    }
  }

/*
  Test print Receipt layout 58mm
*/
  printTestReceipt58mm(bool isUSB, Receipt receipt2, {value}) async {
    String dateTime = dateFormat.format(DateTime.now());
    final prefs = await SharedPreferences.getInstance();
    final String? branch = prefs.getString('branch');
    Map branchObject = json.decode(branch!);
    this.receipt = receipt2;

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
      if(receipt!.header_text_status == 1 && receipt!.header_font_size == 0){
        bytes += generator.row([
          PosColumn(
              text: '${receipt!.header_text}',
              width: 12,
              containsChinese: true,
              styles: PosStyles(align: PosAlign.center, height: PosTextSize.size2, width: PosTextSize.size2)),
        ]);
      } else if (receipt!.header_text_status == 1 && receipt!.header_font_size == 1){
        bytes += generator.row([
          PosColumn(
              text: '${receipt!.header_text}',
              width: 12,
              containsChinese: true,
              styles: PosStyles(align: PosAlign.center, height: PosTextSize.size1, width: PosTextSize.size1)),
        ]);
      }
      bytes += generator.emptyLines(1);
      bytes += generator.reset();
      if(receipt!.show_address == 1 && branchObject['address'].toString() != ''){
        //Address
        bytes += generator.text('${branchObject['address'].toString()}', containsChinese: true, styles: PosStyles(align: PosAlign.center));
      }
      //telephone
      if(receipt!.show_branch_tel == 1){
        bytes += generator.text('Tel: ${branchObject['phone']}', styles: PosStyles(align: PosAlign.center, height: PosTextSize.size1));
      }
      if(receipt!.show_email == 1){
        bytes += generator.text('${receipt!.receipt_email}', containsChinese: true, styles: PosStyles(align: PosAlign.center));
      }
      bytes += generator.hr();
      bytes += generator.reset();
      //receipt no
      bytes += generator.text('Receipt No:',
          styles: PosStyles(
              align: PosAlign.center,
              width: PosTextSize.size1,
              height: PosTextSize.size1,
              bold: true));
      bytes += generator.text('#00001-001-12345678', styles: PosStyles(align: PosAlign.center, bold: true));
      bytes += generator.reset();
      //other order detail
      bytes += generator.text('Close at:', styles: PosStyles(align: PosAlign.center));
      bytes += generator.text('31/12/2021 00:00 AM', styles: PosStyles(align: PosAlign.center));
      bytes += generator.text('Close by:', styles: PosStyles(align: PosAlign.center));
      bytes += generator.text('Waiter', styles: PosStyles(align: PosAlign.center));
      bytes += generator.text('Table No: 1', styles: PosStyles(align: PosAlign.center));
      bytes += generator.text('Dine in', styles: PosStyles(align: PosAlign.center));

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
      bytes += generator.row([
        PosColumn(text: '2', width: 2),
        PosColumn(
            text: '${getTestPrintProductSKU(1, layout: receipt)}Product 1',
            width: 6,
            containsChinese: true,
            styles: PosStyles(bold: true)),
        PosColumn(text: '4.00', width: 4),
      ]);
      bytes += generator.row([
        PosColumn(text: '', width: 2),
        PosColumn(
            text: '(2.00/each)',
            width: 6,
            containsChinese: true,
            styles: PosStyles(bold: true)),
        PosColumn(text: '', width: 4),
      ]);
      bytes += generator.row([
        PosColumn(text: '1', width: 2),
        PosColumn(
            text: '${getTestPrintProductSKU(2, layout: receipt)}Product 2',
            width: 6,
            containsChinese: true,
            styles: PosStyles(bold: true)),
        PosColumn(text: '2.00', width: 4),
      ]);
      bytes += generator.row([
        PosColumn(text: '', width: 2),
        PosColumn(
            text: '(2.00/each)',
            width: 6,
            containsChinese: true,
            styles: PosStyles(bold: true)),
        PosColumn(text: '', width: 4),
      ]);
      bytes += generator.hr();
      bytes += generator.reset();
      //item count
      bytes += generator.text('Item count: 3');
      bytes += generator.hr();
      bytes += generator.reset();
      //total calc
      bytes += generator.row([
        PosColumn(text: 'SubTotal', width: 8),
        PosColumn(text: '6.00', width: 4),
      ]);
      //discount
      bytes += generator.row([
        PosColumn(text: 'Total discount', width: 8),
        PosColumn(text: '-2.00', width: 4),
      ]);
      //tax
      bytes += generator.row([
        PosColumn(text: 'Tax1(10%)', width: 8),
        PosColumn(text: '0.40', width: 4),
      ]);
      //tax
      bytes += generator.row([
        PosColumn(text: 'Tax1(6%)', width: 8),
        PosColumn(text: '0.24', width: 4),
      ]);
      //Amount
      bytes += generator.row([
        PosColumn(text: 'Amount', width: 8),
        PosColumn(text: '3.36', width: 4),
      ]);
      //rounding
      bytes += generator.row([
        PosColumn(text: 'Rounding', width: 8),
        PosColumn(text: '+0.04', width: 4),
      ]);
      //total
      bytes += generator.hr();
      bytes += generator.row([
        PosColumn(text: 'Final Amount', width: 8),
        PosColumn(
            text: '3.40',
            width: 4,
            styles: PosStyles(height: PosTextSize.size2, bold: true)),
      ]);
      bytes += generator.hr();
      //payment method
      bytes += generator.row([
        PosColumn(text: 'Payment method', width: 8),
        PosColumn(text: 'Cash', width: 4),
      ]);
      //payment received
      bytes += generator.row([
        PosColumn(text: 'Payment received', width: 8),
        PosColumn(text: '5.00', width: 4),
      ]);
      //payment change
      bytes += generator.row([
        PosColumn(text: 'Change', width: 8),
        PosColumn(text: '1.60', width: 4),
      ]);
      bytes += generator.reset();
      //footer
      if(receipt!.footer_text_status == 1){
        bytes += generator.emptyLines(1);
        bytes += generator.text('${receipt!.footer_text}', containsChinese: true, styles: PosStyles(bold: true, height: PosTextSize.size1, width: PosTextSize.size1, align: PosAlign.center));
      }
      bytes += generator.emptyLines(1);
      //copyright
      bytes += generator.text('POWERED BY OPTIMY POS', styles: PosStyles(bold: true, align: PosAlign.center));
      bytes += generator.cut(mode: PosCutMode.partial);
      return bytes;
    } catch (e) {
      print('test print receipt error: $e');
      return null;
    }
  }
}