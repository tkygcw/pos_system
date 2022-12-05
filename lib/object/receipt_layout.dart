import 'dart:convert';

import 'package:esc_pos_utils/esc_pos_utils.dart';
import 'package:flutter/material.dart';
import 'package:imin/imin.dart';
import 'package:intl/intl.dart';
import 'package:pos_system/database/pos_database.dart';
import 'package:pos_system/object/cart_product.dart';
import 'package:pos_system/object/cash_record.dart';
import 'package:pos_system/object/order_cache.dart';
import 'package:pos_system/object/order_detail.dart';
import 'package:pos_system/object/payment_link_company.dart';
import 'package:pos_system/object/product.dart';
import 'package:pos_system/object/product_variant.dart';
import 'package:pos_system/object/product_variant_detail.dart';
import 'package:pos_system/object/receipt.dart';
import 'package:pos_system/object/table.dart';
import 'package:pos_system/object/table_use_detail.dart';
import 'package:pos_system/object/variant_group.dart';
import 'package:pos_system/object/variant_item.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'branch_link_product.dart';
import 'modifier_group.dart';
import 'order.dart';
import 'order_modifier_detail.dart';
import 'order_promotion_detail.dart';
import 'order_tax_detail.dart';

class ReceiptLayout{
  PaperSize? size;
  Receipt? receipt;
  OrderCache? orderCache;
  Order? paidOrder;
  List<OrderCache> paidOrderCacheList = [];
  List<OrderTaxDetail> orderTaxList = [];
  List<OrderPromotionDetail> orderPromotionList = [];
  List<OrderDetail> orderDetailList = [];
  List<PosTable> tableList = [];
  List<PaymentLinkCompany> paymentList = [];
  List<OrderModifierDetail> orderModifierDetailList = [];
  DateFormat dateFormat = DateFormat("yyyy-MM-dd HH:mm:ss");
  String settlement_By = '';
  double totalCashBalance = 0.0;
  double totalCashIn = 0.0;
  double totalCashOut = 0.0;
  double totalOpeningCash = 0.0;
  bool _isLoad = false;

/*
  open cash drawer function
*/
  void openCashDrawer () {
    Imin.openDrawer();
  }


/*
  ----------------Receipt layout part------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
*/

/*
  test print layout 80mm
*/
  testTicket80mm(bool isUSB, {value}) async {
    // Using default profile
    var generator;
    if (isUSB) {
      final profile = await CapabilityProfile.load();
      generator = Generator(PaperSize.mm80, profile);
    } else {
      generator = value;
    }
    List<int> bytes = [];

    //LOGO
    bytes += generator.text('Lucky 8', styles: PosStyles(bold: true, align: PosAlign.center, height: PosTextSize.size3, width: PosTextSize.size3));
    bytes += generator.text(
        '22-2, Jalan Permas 11/1A, Bandar Permas Baru, 81750, Masai',
        styles: PosStyles(align: PosAlign.center));
    //telephone
    bytes += generator.text('Tel: 07-3504533',
        styles: PosStyles(align: PosAlign.center, height: PosTextSize.size1));
    bytes += generator.text('Lucky8@hotmail.com',
        styles: PosStyles(align: PosAlign.center));
    bytes += generator.hr();
    bytes += generator.reset();
    //receipt no
    bytes += generator.text('Receipt No.: 17-200-000056',
        styles: PosStyles(
            align: PosAlign.left,
            width: PosTextSize.size1,
            height: PosTextSize.size1,
            bold: true));
    bytes += generator.reset();

    bytes += generator.feed(1);
    bytes += generator.drawer();
    bytes += generator.cut(mode: PosCutMode.partial);
    return bytes;
  }

/*
  test print layout 58mm
*/
  testTicket58mm(bool isUSB, value) async {
    // Using default profile
    var generator;
    if (isUSB) {
      final profile = await CapabilityProfile.load();
      generator = Generator(PaperSize.mm58, profile);
    } else {
      generator = value;
    }
    List<int> bytes = [];

    //LOGO
    bytes += generator.text('Lucky 8', styles: PosStyles(bold: true, align: PosAlign.center, height: PosTextSize.size3, width: PosTextSize.size3));
    bytes += generator.text('This is 58mm', styles: PosStyles(bold: true, align: PosAlign.center, height: PosTextSize.size3, width: PosTextSize.size3));

    bytes += generator.feed(1);
    bytes += generator.drawer();
    bytes += generator.cut(mode: PosCutMode.partial);
    return bytes;
  }

/*
  Receipt layout 80mm
*/
  printReceipt80mm(bool isUSB, String orderId, {value}) async {
    String dateTime = dateFormat.format(DateTime.now());
    final prefs = await SharedPreferences.getInstance();
    final String? branch = prefs.getString('branch');
    Map branchObject = json.decode(branch!);
    await readReceiptLayout();
    await getPaidOrder(orderId);
    await callOrderTaxPromoDetail();
    await callPaidOrderDetail(orderId);

    if(_isLoad = true){
      var generator;
      if (isUSB) {
        final profile = await CapabilityProfile.load();
        generator = Generator(PaperSize.mm80, profile);
      } else {
        generator = value;
      }

      List<int> bytes = [];
      try {
        if(receipt!.header_text_status == 1){
          bytes += generator.text('${receipt!.header_text}', styles: PosStyles(bold: true, align: PosAlign.center, height: PosTextSize.size3, width: PosTextSize.size3));
        }
        bytes += generator.emptyLines(1);
        bytes += generator.reset();
        //Address
        bytes += generator.text('${branchObject['address'].toString().replaceAll(',', '\n')}', styles: PosStyles(align: PosAlign.center));
        //telephone
        bytes += generator.text('Tel: ${branchObject['phone']}',
            styles: PosStyles(align: PosAlign.center, height: PosTextSize.size1));
        bytes += generator.text('Lucky8@hotmail.com',
            styles: PosStyles(align: PosAlign.center));
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
        bytes += generator.text('Printed at: ${dateTime}');
        if(paidOrder!.dining_id == '1'){
          for(int i = 0; i < tableList.length; i++){
            bytes += generator.text('Table No: ${tableList[i].number}');
          }
        }
        bytes += generator.text('${paidOrder!.dining_name}');
        bytes += generator.text('Close by: ${this.paidOrder!.close_by}');
        bytes += generator.reset();
        /*
    *
    * body
    *
    * */
        bytes += generator.hr();
        bytes += generator.row([
          PosColumn(text: 'ITEM', width: 6, styles: PosStyles(bold: true)),
          PosColumn(text: 'QTY ', width: 2, styles: PosStyles(bold: true, align: PosAlign.right)),
          PosColumn(text: 'AMOUNT', width: 4, styles: PosStyles(bold: true, align: PosAlign.right)),
        ]);
        bytes += generator.hr();
        //order product
        for(int i = 0; i < orderDetailList.length; i++){
          bytes += generator.row([
            PosColumn(
                text: '${orderDetailList[i].productName}',
                width: 6,
                containsChinese: true,
                styles: PosStyles(align: PosAlign.left, bold: true)),
            PosColumn(text: '${orderDetailList[i].quantity}', width: 2, styles: PosStyles(align: PosAlign.right)),
            PosColumn(
                text: '${orderDetailList[i].price}',
                width: 4,
                styles: PosStyles(align: PosAlign.right)),
          ]);
          bytes += generator.reset();
          if(orderDetailList[i].has_variant == '1'){
            bytes += generator.row([
              PosColumn(text: '(${orderDetailList[i].product_variant_name!})', width: 6, styles: PosStyles(align: PosAlign.left)),
              PosColumn(text: '', width: 2),
              PosColumn(text: '', width: 4, styles: PosStyles(align: PosAlign.right)),
            ]);
          }
          bytes += generator.reset();
          await getPaidOrderModifierDetail(orderDetailList[i]);
          if(orderModifierDetailList.length > 0){
            for(int j = 0; j < orderModifierDetailList.length; j++){
              //modifier
              bytes += generator.row([
                PosColumn(text: '-${orderModifierDetailList[j].modifier_name}', width: 6, containsChinese: true),
                PosColumn(text: '', width: 2, styles: PosStyles(align: PosAlign.right)),
                PosColumn(text: '', width: 4, styles: PosStyles(align: PosAlign.right)),
              ]);
            }
          }
          //product remark
          bytes += generator.reset();
          if (orderDetailList[i].remark != '') {
            bytes += generator.row([
              PosColumn(text: '', width: 2),
              PosColumn(text: '**${orderDetailList[i].remark}', width: 8, containsChinese: true, styles: PosStyles(align: PosAlign.left)),
              PosColumn(text: '', width: 2),
            ]);
          }
          bytes += generator.feed(1);
          bytes += generator.emptyLines(1);
        }

        // bytes += generator.row([
        //   PosColumn(
        //       text: 'Nasi Ayam',
        //       width: 6,
        //       containsChinese: true,
        //       styles: PosStyles(align: PosAlign.left, bold: true)),
        //   PosColumn(text: '1', width: 2, styles: PosStyles(align: PosAlign.right)),
        //   PosColumn(
        //       text: '9.90',
        //       width: 4,
        //       styles: PosStyles(align: PosAlign.right)),
        // ]);

        // bytes += generator.emptyLines(1);
        // /*
        // * product with remark
        // * */
        // bytes += generator.row([
        //   PosColumn(
        //       text: 'Nasi Lemak' + '',
        //       width: 6,
        //       containsChinese: true,
        //       styles: PosStyles(align: PosAlign.left, bold: true)),
        //   PosColumn(text: '1', width: 2, styles: PosStyles(align: PosAlign.right)),
        //   PosColumn(
        //       text: '11.00',
        //       width: 4,
        //       styles: PosStyles(align: PosAlign.right)),
        // ]);
        // bytes += generator.row([
        //   PosColumn(text: '(big,white)', width: 6, containsChinese: true),
        //   PosColumn(text: '', width: 2, styles: PosStyles(align: PosAlign.right)),
        //   PosColumn(text: '', width: 4, styles: PosStyles(align: PosAlign.right)),
        // ]);
        // bytes += generator.reset();
        // bytes += generator.row([
        //   PosColumn(text: '**remark here', width: 6, containsChinese: true),
        //   PosColumn(text: '', width: 2, styles: PosStyles(align: PosAlign.right)),
        //   PosColumn(text: '', width: 4, styles: PosStyles(align: PosAlign.right)),
        // ]);
        bytes += generator.hr();
        bytes += generator.reset();
        //item count
        bytes += generator.text('Items count: ${orderDetailList.length}', styles: PosStyles(bold: true));
        bytes += generator.hr();
        bytes += generator.reset();
        //total calc
        bytes += generator.row([
          PosColumn(text: 'SubTotal', width: 8, styles: PosStyles(align: PosAlign.right)),
          PosColumn(text: '${this.paidOrder!.subtotal}', width: 4, styles: PosStyles(align: PosAlign.right)),
        ]);
        //discount
        for(int p = 0; p < orderPromotionList.length; p++){
          bytes += generator.row([
            PosColumn(text: '${orderPromotionList[p].promotion_name}(${orderPromotionList[p].rate})', width: 8, styles: PosStyles(align: PosAlign.right)),
            PosColumn(text: '-${orderPromotionList[p].promotion_amount}', width: 4, styles: PosStyles(align: PosAlign.right)),
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
          PosColumn(text: 'Final Amount', width: 8, styles: PosStyles(align: PosAlign.right, height: PosTextSize.size2, bold: true)),
          PosColumn(
              text: '${this.paidOrder!.final_amount}',
              width: 4,
              styles: PosStyles(align: PosAlign.right, height: PosTextSize.size2, bold: true)),
        ]);
        bytes += generator.hr();
        //payment method
        bytes += generator.row([
          PosColumn(text: 'Payment method', width: 8, styles: PosStyles(align: PosAlign.right)),
          PosColumn(text: '${this.paidOrder!.payment_name}', width: 4, styles: PosStyles(align: PosAlign.right)),
        ]);
        //payment received
        bytes += generator.row([
          PosColumn(text: 'Payment received', width: 8, styles: PosStyles(align: PosAlign.right)),
          PosColumn(text: '${this.paidOrder!.payment_received}', width: 4, styles: PosStyles(align: PosAlign.right)),
        ]);
        //payment change
        bytes += generator.row([
          PosColumn(text: 'Change', width: 8, styles: PosStyles(align: PosAlign.right)),
          PosColumn(text: '${this.paidOrder!.payment_change}', width: 4, styles: PosStyles(align: PosAlign.right)),
        ]);
        bytes += generator.emptyLines(1);
        //footer
        if(receipt!.footer_text_status == 1){
          bytes += generator.text('${receipt!.footer_text}', styles: PosStyles(bold: true, align: PosAlign.center, height: PosTextSize.size3, width: PosTextSize.size3));
        }
        //copyright
        bytes += generator.text('POWERED BY CHANNEL POS', styles: PosStyles(bold: true, align: PosAlign.center));
        bytes += generator.feed(1);
        bytes += generator.cut(mode: PosCutMode.partial);
        return bytes;
      } catch (e) {
        print(e);
        return null;
      }
    }
  }

/*
  Receipt layout 58mm
*/
  printReceipt58mm(bool isUSB, String orderId, {value}) async {
    String dateTime = dateFormat.format(DateTime.now());
    final prefs = await SharedPreferences.getInstance();
    final String? branch = prefs.getString('branch');
    Map branchObject = json.decode(branch!);
    await readReceiptLayout();
    await getPaidOrder(orderId);
    await callOrderTaxPromoDetail();
    await callPaidOrderDetail(orderId);

    if(_isLoad = true){
      var generator;
      if (isUSB) {
        final profile = await CapabilityProfile.load();
        generator = Generator(PaperSize.mm58, profile);
      } else {
        generator = value;
      }

      List<int> bytes = [];
      try {
        if(receipt!.header_text_status == 1){
          bytes += generator.text('${receipt!.header_text}', styles: PosStyles(bold: true, align: PosAlign.center, height: PosTextSize.size3, width: PosTextSize.size3));
        }
        bytes += generator.text('this is 58mm', styles: PosStyles(bold: true, align: PosAlign.center, height: PosTextSize.size3, width: PosTextSize.size3));
        bytes += generator.emptyLines(1);
        bytes += generator.reset();
        //Address
        bytes += generator.text('${branchObject['address'].toString().replaceAll(',', '\n')}', styles: PosStyles(align: PosAlign.center));
        //telephone
        bytes += generator.text('Tel: ${branchObject['phone']}',
            styles: PosStyles(align: PosAlign.center, height: PosTextSize.size1));
        bytes += generator.text('Lucky8@hotmail.com',
            styles: PosStyles(align: PosAlign.center));
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
        bytes += generator.text('Printed at: ${dateTime}');
        if(paidOrder!.dining_id == '1'){
          for(int i = 0; i < tableList.length; i++){
            bytes += generator.text('Table No: ${tableList[i].number}');
          }
        }
        bytes += generator.text('${paidOrder!.dining_name}');
        bytes += generator.text('Close by: ${this.paidOrder!.close_by}');
        bytes += generator.reset();
        /*
    *
    * body
    *
    * */
        bytes += generator.hr();
        bytes += generator.row([
          PosColumn(text: 'ITEM', width: 6, styles: PosStyles(bold: true)),
          PosColumn(text: 'QTY ', width: 2, styles: PosStyles(bold: true)),
          PosColumn(text: 'AMOUNT', width: 4, styles: PosStyles(bold: true)),
        ]);
        bytes += generator.hr();
        //order product
        for(int i = 0; i < orderDetailList.length; i++){
          bytes += generator.row([
            PosColumn(
                text: '${orderDetailList[i].productName}',
                width: 6,
                containsChinese: true,
                styles: PosStyles(bold: true)),
            PosColumn(text: '${orderDetailList[i].quantity}', width: 2),
            PosColumn(text: '${orderDetailList[i].price}', width: 4),
          ]);
          bytes += generator.reset();
          if(orderDetailList[i].has_variant == '1'){
            bytes += generator.row([
              PosColumn(text: '(${orderDetailList[i].product_variant_name!})', width: 6),
              PosColumn(text: '', width: 2),
              PosColumn(text: '', width: 4),
            ]);
          }
          bytes += generator.reset();
          await getPaidOrderModifierDetail(orderDetailList[i]);
          if(orderModifierDetailList.length > 0){
            for(int j = 0; j < orderModifierDetailList.length; j++){
              //modifier
              bytes += generator.row([
                PosColumn(text: '-${orderModifierDetailList[j].modifier_name}', width: 6, containsChinese: true),
                PosColumn(text: '', width: 2),
                PosColumn(text: '', width: 4),
              ]);
            }
          }
          //product remark
          bytes += generator.reset();
          if (orderDetailList[i].remark != '') {
            bytes += generator.row([
              PosColumn(text: '', width: 2),
              PosColumn(text: '**${orderDetailList[i].remark}', width: 8, containsChinese: true),
              PosColumn(text: '', width: 2),
            ]);
          }
          bytes += generator.feed(1);
          bytes += generator.emptyLines(1);
        }
        bytes += generator.hr();
        bytes += generator.reset();
        //item count
        bytes += generator.text('Items count: ${orderDetailList.length}', styles: PosStyles(bold: true));
        bytes += generator.hr();
        bytes += generator.reset();
        //total calc
        bytes += generator.row([
          PosColumn(text: 'SubTotal', width: 8),
          PosColumn(text: '${this.paidOrder!.subtotal}', width: 4),
        ]);
        //discount
        for(int p = 0; p < orderPromotionList.length; p++){
          bytes += generator.row([
            PosColumn(text: '${orderPromotionList[p].promotion_name}(${orderPromotionList[p].rate})', width: 8),
            PosColumn(text: '-${orderPromotionList[p].promotion_amount}', width: 4),
          ]);
        }
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
          PosColumn(text: 'Final Amount', width: 8, styles: PosStyles(height: PosTextSize.size2, bold: true)),
          PosColumn(
              text: '${this.paidOrder!.final_amount}',
              width: 4,
              styles: PosStyles(height: PosTextSize.size2, bold: true)),
        ]);
        bytes += generator.hr();
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
        //payment change
        bytes += generator.row([
          PosColumn(text: 'Change', width: 8),
          PosColumn(text: '${this.paidOrder!.payment_change}', width: 4),
        ]);
        bytes += generator.emptyLines(1);
        //footer
        if(receipt!.footer_text_status == 1){
          bytes += generator.text('${receipt!.footer_text}', styles: PosStyles(bold: true, height: PosTextSize.size3, width: PosTextSize.size3));
        }
        //copyright
        bytes += generator.text('POWERED BY CHANNEL POS', styles: PosStyles(bold: true));
        bytes += generator.feed(1);
        bytes += generator.cut(mode: PosCutMode.partial);
        return bytes;
      } catch (e) {
        print(e);
        return null;
      }
    }
  }

/*
  Check list layout 80mm
*/
  printCheckList80mm(bool isUSB, {value}) async {
    String dateTime = dateFormat.format(DateTime.now());
    await readOrderCache();

    var generator;
    if (isUSB) {
      final profile = await CapabilityProfile.load();
      generator = Generator(PaperSize.mm80, profile);
    } else {
      generator = value;
    }

    List<int> bytes = [];
    try {
      bytes += generator.text('** ORDER LIST **', styles: PosStyles(align: PosAlign.center, height:PosTextSize.size2, width: PosTextSize.size2 ));
      bytes += generator.emptyLines(1);
      bytes += generator.reset();
      //other order detail
      for(int i = 0; i < tableList.length; i++){
        bytes += generator.text('Table No: ${tableList[i].number}', styles: PosStyles(bold: true, align: PosAlign.left, height: PosTextSize.size2, width: PosTextSize.size2));
      }
      // bytes += generator.text('Table No: 5', styles: PosStyles(bold: true, align: PosAlign.left, height: PosTextSize.size2, width: PosTextSize.size2));
      bytes += generator.text('Order No: #${orderCache!.batch_id}');
      bytes += generator.text('Order By: ${orderCache!.order_by}');
      bytes += generator.text('Order time: ${dateTime}');
      bytes += generator.hr();
      bytes += generator.reset();
      /*
    *
    * body
    *
    * */
      //order product
      for(int i = 0; i < orderDetailList.length; i++){
        bytes += generator.row([
          PosColumn(text: '${orderDetailList[i].quantity}', width: 2, styles: PosStyles(align: PosAlign.left, bold: true)),
          PosColumn(
              text: '${orderDetailList[i].productName}',
              width: 8,
              containsChinese: true,
              styles: PosStyles(align: PosAlign.left, height: PosTextSize.size2, width: PosTextSize.size1)),
          PosColumn(
              text: '[   ]',
              width: 2,
              styles: PosStyles(align: PosAlign.right)),
        ]);
        bytes += generator.reset();
        if(orderDetailList[i].has_variant == '1'){
          bytes += generator.row([
            PosColumn(text: '', width: 2),
            PosColumn(text: '(${orderDetailList[i].product_variant_name})', width: 8, styles: PosStyles(align: PosAlign.left)),
            PosColumn(text: '', width: 2, styles: PosStyles(align: PosAlign.right)),
          ]);
        }
        await getPaidOrderModifierDetail(orderDetailList[i]);
        if(orderModifierDetailList.length > 0) {
          for (int j = 0; j < orderModifierDetailList.length; j++) {
            //modifier
            bytes += generator.row([
              PosColumn(text: '', width: 2),
              PosColumn(text: '+${orderModifierDetailList[j].modifier_name}', width: 8, styles: PosStyles(align: PosAlign.left)),
              PosColumn(text: '', width: 2, styles: PosStyles(align: PosAlign.right)),
            ]);
          }
        }
        /*
        * product remark
        * */
        bytes += generator.reset();
        if (orderDetailList[i].remark != '') {
          bytes += generator.row([
            PosColumn(text: '', width: 2),
            PosColumn(text: '**${orderDetailList[i].remark}', width: 8, containsChinese: true, styles: PosStyles(align: PosAlign.left)),
            PosColumn(text: '', width: 2),
          ]);
        }
        bytes += generator.feed(1);
        bytes += generator.emptyLines(1);
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
  Check list layout 58mm
*/
  printCheckList58mm(bool isUSB, {value}) async {
    String dateTime = dateFormat.format(DateTime.now());
    await readOrderCache();

    var generator;
    if (isUSB) {
      final profile = await CapabilityProfile.load();
      generator = Generator(PaperSize.mm58, profile);
    } else {
      generator = value;
    }

    List<int> bytes = [];
    try {
      bytes += generator.text('** ORDER LIST **', styles: PosStyles(align: PosAlign.center, height:PosTextSize.size2, width: PosTextSize.size2 ));
      bytes += generator.emptyLines(1);
      bytes += generator.reset();
      //other order detail
      for(int i = 0; i < tableList.length; i++){
        bytes += generator.text('Table No: ${tableList[i].number}', styles: PosStyles(bold: true, align: PosAlign.center, height: PosTextSize.size2, width: PosTextSize.size2));
      }
      // bytes += generator.text('Table No: 5', styles: PosStyles(bold: true, align: PosAlign.left, height: PosTextSize.size2, width: PosTextSize.size2));
      bytes += generator.text('Order No: #${orderCache!.batch_id}');
      bytes += generator.text('Order By: ${orderCache!.order_by}');
      bytes += generator.text('Order time: ${dateTime}');
      bytes += generator.hr();
      bytes += generator.reset();
      /*
    *
    * body
    *
    * */
      //order product
      for(int i = 0; i < orderDetailList.length; i++){
        bytes += generator.row([
          PosColumn(text: '${orderDetailList[i].quantity}', width: 2, styles: PosStyles(bold: true)),
          PosColumn(
              text: '${orderDetailList[i].productName}',
              width: 8,
              containsChinese: true,
              styles: PosStyles(height: PosTextSize.size2, width: PosTextSize.size1)),
          PosColumn(text: '[ ]', width: 2),
        ]);
        bytes += generator.reset();
        if(orderDetailList[i].has_variant == '1'){
          bytes += generator.row([
            PosColumn(text: '', width: 2),
            PosColumn(text: '(${orderDetailList[i].product_variant_name})', width: 8),
            PosColumn(text: '', width: 2),
          ]);
        }
        await getPaidOrderModifierDetail(orderDetailList[i]);
        if(orderModifierDetailList.length > 0) {
          for (int j = 0; j < orderModifierDetailList.length; j++) {
            //modifier
            bytes += generator.row([
              PosColumn(text: '', width: 2),
              PosColumn(text: '+${orderModifierDetailList[j].modifier_name}', width: 8),
              PosColumn(text: '', width: 2),
            ]);
          }
        }
        /*
        * product remark
        * */
        bytes += generator.reset();
        if (orderDetailList[i].remark != '') {
          bytes += generator.row([
            PosColumn(text: '', width: 2),
            PosColumn(text: '**${orderDetailList[i].remark}', width: 8, containsChinese: true),
            PosColumn(text: '', width: 2),
          ]);
        }
        bytes += generator.feed(1);
        bytes += generator.emptyLines(1);
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
  kitchen layout 80mm
*/
  printKitchenList80mm(bool isUSB, cartProductItem cartItem, {value}) async {
    String dateTime = dateFormat.format(DateTime.now());
    final prefs = await SharedPreferences.getInstance();
    final int? branch_id = prefs.getInt('branch_id');
    await readOrderCache();

    if(_isLoad == true){
      var generator;
      if (isUSB) {
        final profile = await CapabilityProfile.load();
        generator = Generator(PaperSize.mm80, profile);
      } else {
        generator = value;
      }

      List<int> bytes = [];
      try {
        bytes += generator.text('** kitchen list **', styles: PosStyles(align: PosAlign.center, width: PosTextSize.size2, height: PosTextSize.size2));
        bytes += generator.emptyLines(1);
        bytes += generator.reset();
        //other order detail
        for(int i = 0; i < tableList.length; i++){
          bytes += generator.text('Table No: ${tableList[i].number}', styles: PosStyles(bold: true, align: PosAlign.center, height: PosTextSize.size2, width: PosTextSize.size2));
        }
        bytes += generator.text('order No: #${orderCache!.batch_id}-${branch_id.toString().padLeft(3 ,'0')}', styles: PosStyles(align: PosAlign.center));
        bytes += generator.text('order time: ${dateTime}', styles: PosStyles(align: PosAlign.center));
        bytes += generator.hr();
        bytes += generator.reset();
        /*
    *
    * body
    *
    * */
        //order product
        bytes += generator.row([
          PosColumn(text: '${cartItem.quantity}', width: 2, styles: PosStyles(align: PosAlign.left, bold: true)),
          PosColumn(
              text: '${cartItem.name}',
              width: 8,
              containsChinese: true,
              styles: PosStyles(align: PosAlign.left, height: PosTextSize.size2, width: PosTextSize.size1)),
          PosColumn(
              text: '',
              width: 2,
              styles: PosStyles(align: PosAlign.right)),
        ]);
        bytes += generator.reset();
        //product variant
        if(cartItem.variant.isNotEmpty){
          for (int i = 0; i < cartItem.variant.length; i++) {
            VariantGroup group = cartItem.variant[i];
            for (int j = 0; j < group.child.length; j++) {
              if (group.child[j].isSelected!) {
                bytes += generator.row([
                  PosColumn(text: '', width: 2, styles: PosStyles(align: PosAlign.left)),
                  PosColumn(text: '-${group.child[j].name!}', width: 8, styles: PosStyles(align: PosAlign.left)),
                  PosColumn(text: '', width: 2, styles: PosStyles(align: PosAlign.right)),
                ]);
              }
            }
          }
        }
        bytes += generator.reset();
        //product modifier
        if(cartItem.modifier.isNotEmpty){
          for (int i = 0; i < cartItem.modifier.length; i++) {
            ModifierGroup group = cartItem.modifier[i];
            for (int j = 0; j < group.modifierChild.length; j++) {
              if (group.modifierChild[j].isChecked!) {
                bytes += generator.row([
                  PosColumn(text: '', width: 2),
                  PosColumn(text: '+${group.modifierChild[j].name!}', width: 8, styles: PosStyles(align: PosAlign.left)),
                  PosColumn(text: '', width: 2, styles: PosStyles(align: PosAlign.right)),
                ]);
              }
            }
          }
        }
        /*
        * product remark
        * */
        bytes += generator.reset();
        if (cartItem.remark != '') {
          bytes += generator.row([
            PosColumn(text: '', width: 2),
            PosColumn(text: '**${cartItem.remark}', width: 8, containsChinese: true, styles: PosStyles(align: PosAlign.left)),
            PosColumn(text: '', width: 2),
          ]);
          bytes += generator.feed(1);
          bytes += generator.emptyLines(1);
        }

        bytes += generator.feed(1);
        bytes += generator.beep(n: 3, duration: PosBeepDuration.beep400ms);
        bytes += generator.cut(mode: PosCutMode.partial);
        return bytes;
      } catch (e) {
        print('layout error: $e');
        return null;
      }
    }

  }

/*
  Cancellation layout 80mm
*/
  printDeleteItemList80mm(bool isUSB, value, String orderCacheId, String deleteDateTime) async {
    String dateTime = dateFormat.format(DateTime.now());
    await readSpecificOrderCache(orderCacheId, deleteDateTime);

    var generator;
    if (isUSB) {
      final profile = await CapabilityProfile.load();
      generator = Generator(PaperSize.mm80, profile);
    } else {
      generator = value;
    }

    List<int> bytes = [];
    try {
      bytes += generator.text('CANCELLATION',
          styles: PosStyles(align: PosAlign.center, bold: true, fontType:PosFontType.fontA, underline: true, height: PosTextSize.size2, width: PosTextSize.size2));
      bytes += generator.emptyLines(1);
      bytes += generator.reset();
      //other order detail
      for(int i = 0; i < tableList.length; i++){
        bytes += generator.text('Table No: ${tableList[i].number}', styles: PosStyles(bold: true, align: PosAlign.center, height: PosTextSize.size2, width: PosTextSize.size2));
      }
      bytes += generator.text('order No: #${orderCache!.batch_id}', styles: PosStyles(align: PosAlign.center));
      bytes += generator.text('cancel time: ${dateTime}', styles: PosStyles(align: PosAlign.center));
      bytes += generator.hr();
      bytes += generator.reset();
      /*
    *
    * body
    *
    * */
      //order product
      for(int i = 0; i < orderDetailList.length; i++){
        bytes += generator.row([
          PosColumn(text: '${orderDetailList[i].quantity}', width: 2, styles: PosStyles(align: PosAlign.left, bold: true)),
          PosColumn(
              text: '${orderDetailList[i].productName}',
              width: 8,
              containsChinese: true,
              styles: PosStyles(align: PosAlign.left, height: PosTextSize.size2, width: PosTextSize.size1)),
          PosColumn(
              text: '',
              width: 2,
              styles: PosStyles(align: PosAlign.right)),
        ]);
        bytes += generator.reset();
        if(orderDetailList[i].has_variant == '1'){
          bytes += generator.row([
            PosColumn(text: '', width: 2),
            PosColumn(text: '(${orderDetailList[i].product_variant_name})', width: 8, styles: PosStyles(align: PosAlign.left)),
            PosColumn(text: '', width: 2, styles: PosStyles(align: PosAlign.right)),
          ]);
        } else {
          bytes += generator.row([
            PosColumn(text: '', width: 2),
            PosColumn(text: '+Modifier', width: 8, styles: PosStyles(align: PosAlign.left)),
            PosColumn(text: '', width: 2, styles: PosStyles(align: PosAlign.right)),
          ]);
        }
        /*
        * product remark
        * */
        bytes += generator.reset();
        if (orderDetailList[i].remark != '') {
          bytes += generator.row([
            PosColumn(text: '', width: 2),
            PosColumn(text: '**${orderDetailList[i].remark}', width: 8, containsChinese: true, styles: PosStyles(align: PosAlign.left)),
            PosColumn(text: '', width: 2),
          ]);
        }
        bytes += generator.feed(1);
        bytes += generator.hr();
        bytes += generator.text('cancel by: ${orderDetailList[i].cancel_by}', styles: PosStyles(align: PosAlign.center));
      }

      bytes += generator.feed(1);
      bytes += generator.beep(n: 3, duration: PosBeepDuration.beep400ms);
      bytes += generator.cut(mode: PosCutMode.partial);
      return bytes;
    } catch (e) {
      print('layout error: $e');
      return null;
    }
  }

/*
  Cash balance layout 80mm (print when transfer ownership)
*/
  printCashBalanceList80mm(bool isUSB, value, String cashBalance) async {
    String dateTime = dateFormat.format(DateTime.now());
    final prefs = await SharedPreferences.getInstance();
    final String? user = prefs.getString('pos_pin_user');
    Map userObject = json.decode(user!);
      var generator;
      if (isUSB) {
        final profile = await CapabilityProfile.load();
        generator = Generator(PaperSize.mm80, profile);
      } else {
        generator = value;
      }

      List<int> bytes = [];
      try {
        bytes += generator.text('** CASH BALANCE LIST **', styles: PosStyles(align: PosAlign.center, width: PosTextSize.size2, height: PosTextSize.size2));
        bytes += generator.emptyLines(1);
        bytes += generator.reset();

        bytes += generator.text('Transfer to: ${userObject['name']}', styles: PosStyles(align: PosAlign.center));
        bytes += generator.text('Transfer time: ${dateTime}', styles: PosStyles(align: PosAlign.center));
        bytes += generator.hr();
        bytes += generator.reset();
        /*
    *
    * body
    *
    * */
        bytes += generator.row([
          PosColumn(text: 'Payment Type', width: 6, styles: PosStyles(bold: true)),
          PosColumn(text: 'AMOUNT', width: 5, styles: PosStyles(bold: true, align: PosAlign.right)),
          PosColumn(text: '', width: 1, styles: PosStyles(bold: true, align: PosAlign.center)),
        ]);
        bytes += generator.hr();
        //order product
        bytes += generator.row([
          PosColumn(text: '', width: 1, styles: PosStyles(align: PosAlign.left, bold: true)),
          PosColumn(
              text: 'Cash Balance',
              width: 8,
              containsChinese: true,
              styles: PosStyles(align: PosAlign.left, height: PosTextSize.size2, width: PosTextSize.size1)),
          PosColumn(
              text: '${cashBalance}',
              width: 2,
              styles: PosStyles(align: PosAlign.right)),
          PosColumn(
              text: '',
              width: 1,
              styles: PosStyles(align: PosAlign.right)),
        ]);

        bytes += generator.feed(1);
        bytes += generator.cut(mode: PosCutMode.partial);
        return bytes;
      } catch (e) {
        print('layout error: $e');
        return null;
      }

  }

/*
  Settlement layout 80mm
*/
  printSettlementList80mm(bool isUSB, String settlementDateTime, {value}) async {
    await readPaymentLinkCompany(settlementDateTime);
    await calculateCashDrawerAmount(settlementDateTime);
    if(_isLoad == true){
      var generator;
      if (isUSB) {
        final profile = await CapabilityProfile.load();
        generator = Generator(PaperSize.mm80, profile);
      } else {
        generator = value;
      }

      List<int> bytes = [];
      try {
        bytes += generator.text('** SETTLEMENT LIST **', styles: PosStyles(align: PosAlign.center, width: PosTextSize.size2, height: PosTextSize.size2));
        bytes += generator.emptyLines(1);
        bytes += generator.reset();

        bytes += generator.text('Settlement By: ${settlement_By}', styles: PosStyles(align: PosAlign.center));
        bytes += generator.text('Settlement Time: ${settlementDateTime}', styles: PosStyles(align: PosAlign.center));
        bytes += generator.hr();
        bytes += generator.reset();
        /*
    *
    * body
    *
    * */
        bytes += generator.row([
          PosColumn(text: 'Payment Type', width: 6, styles: PosStyles(bold: true)),
          PosColumn(text: 'AMOUNT', width: 5, styles: PosStyles(bold: true, align: PosAlign.right)),
          PosColumn(text: '', width: 1, styles: PosStyles(bold: true, align: PosAlign.center)),
        ]);
        bytes += generator.hr();
        //Payment link company
        for(int i = 0; i < paymentList.length; i++){
          bytes += generator.row([
            PosColumn(text: '', width: 1, styles: PosStyles(align: PosAlign.left, bold: true)),
            PosColumn(
                text: '${paymentList[i].name}',
                width: 8,
                containsChinese: true,
                styles: PosStyles(align: PosAlign.left, height: PosTextSize.size2, width: PosTextSize.size1)),
            PosColumn(
                text: '${paymentList[i].totalAmount.toStringAsFixed(2)}',
                width: 2,
                styles: PosStyles(align: PosAlign.right)),
            PosColumn(
                text: '',
                width: 1,
                styles: PosStyles(align: PosAlign.right)),
          ]);

        }
        bytes += generator.hr();
        bytes += generator.reset();
        //Opening balance
        bytes += generator.row([
          PosColumn(text: '', width: 1, styles: PosStyles(align: PosAlign.left, bold: true)),
          PosColumn(
              text: 'Total Opening Balance',
              width: 8,
              containsChinese: true,
              styles: PosStyles(align: PosAlign.left, height: PosTextSize.size2, width: PosTextSize.size1)),
          PosColumn(
              text: '${totalOpeningCash.toStringAsFixed(2)}',
              width: 2,
              styles: PosStyles(align: PosAlign.right)),
          PosColumn(
              text: '',
              width: 1,
              styles: PosStyles(align: PosAlign.right)),
        ]);
        //cash in
        bytes += generator.row([
          PosColumn(text: '', width: 1, styles: PosStyles(align: PosAlign.left, bold: true)),
          PosColumn(
              text: 'Total Cash In',
              width: 8,
              containsChinese: true,
              styles: PosStyles(align: PosAlign.left, height: PosTextSize.size2, width: PosTextSize.size1)),
          PosColumn(
              text: '${totalCashIn.toStringAsFixed(2)}',
              width: 2,
              styles: PosStyles(align: PosAlign.right)),
          PosColumn(
              text: '',
              width: 1,
              styles: PosStyles(align: PosAlign.right)),
        ]);
        //cash out
        bytes += generator.row([
          PosColumn(text: '', width: 1, styles: PosStyles(align: PosAlign.left, bold: true)),
          PosColumn(
              text: 'Total Cash Out',
              width: 8,
              containsChinese: true,
              styles: PosStyles(align: PosAlign.left, height: PosTextSize.size2, width: PosTextSize.size1)),
          PosColumn(
              text: '-${totalCashOut.toStringAsFixed(2)}',
              width: 2,
              styles: PosStyles(align: PosAlign.right)),
          PosColumn(
              text: '',
              width: 1,
              styles: PosStyles(align: PosAlign.right)),
        ]);
        //total cash drawer
        bytes += generator.row([
          PosColumn(text: '', width: 1, styles: PosStyles(align: PosAlign.left, bold: true)),
          PosColumn(
              text: 'Total Cash Drawer',
              width: 8,
              containsChinese: true,
              styles: PosStyles(align: PosAlign.left, height: PosTextSize.size2, width: PosTextSize.size1)),
          PosColumn(
              text: '${totalCashBalance.toStringAsFixed(2)}',
              width: 2,
              styles: PosStyles(align: PosAlign.right)),
          PosColumn(
              text: '',
              width: 1,
              styles: PosStyles(align: PosAlign.right)),
        ]);
        bytes += generator.hr();
        //final part
        bytes += generator.feed(1);
        bytes += generator.cut(mode: PosCutMode.partial);
        return bytes;
      } catch (e) {
        print('layout error: $e');
        return null;
      }
    }
  }

/*
  Settlement layout 58mm
*/
  printSettlementList58mm(bool isUSB, String settlementDateTime, {value}) async {
    print('58mm called');
    await readPaymentLinkCompany(settlementDateTime);
    await calculateCashDrawerAmount(settlementDateTime);
    if(_isLoad == true){
      var generator;
      if (isUSB) {
        final profile = await CapabilityProfile.load();
        generator = Generator(PaperSize.mm58, profile);
      } else {
        generator = value;
      }

      List<int> bytes = [];
      try {
        bytes += generator.text('** SETTLEMENT LIST 58mm **', styles: PosStyles(width: PosTextSize.size2, height: PosTextSize.size2));
        bytes += generator.emptyLines(1);
        bytes += generator.reset();

        bytes += generator.text('Settlement By: ${settlement_By}');
        bytes += generator.text('Settlement Time: ${settlementDateTime}');
        bytes += generator.reset();
        /*
    *
    * body
    *
    * */
        bytes += generator.hr();
        bytes += generator.row([
          PosColumn(text: 'Payment Type', width: 3, styles: PosStyles(bold: true)),
          PosColumn(text: '', width: 6, styles: PosStyles(bold: true)),
          PosColumn(text: 'AMOUNT', width: 3, styles: PosStyles(bold: true)),
        ]);
        bytes += generator.hr();
        //Payment link company
        for(int i = 0; i < paymentList.length; i++){
          bytes += generator.reset();
          bytes += generator.row([
            PosColumn(
                text: '${paymentList[i].name}',
                width: 9,
                containsChinese: true,
                styles: PosStyles(height: PosTextSize.size1, width: PosTextSize.size1)),
            PosColumn(
                text: '${paymentList[i].totalAmount.toStringAsFixed(2)}', width: 3),
          ]);

        }
        bytes += generator.hr();
        bytes += generator.reset();
        //Opening balance
        bytes += generator.row([
          PosColumn(
              text: 'Total Opening Balance',
              width: 9,
              containsChinese: true,
              styles: PosStyles(height: PosTextSize.size1, width: PosTextSize.size1)),
          PosColumn(
              text: '${totalOpeningCash.toStringAsFixed(2)}', width: 3),
        ]);
        //cash in
        bytes += generator.row([
          PosColumn(
              text: 'Total Cash In',
              width: 9,
              containsChinese: true,
              styles: PosStyles(height: PosTextSize.size1, width: PosTextSize.size1)),
          PosColumn(
              text: '${totalCashIn.toStringAsFixed(2)}', width: 3),
        ]);
        //cash out
        bytes += generator.row([
          PosColumn(
              text: 'Total Cash Out',
              width: 9,
              containsChinese: true,
              styles: PosStyles(height: PosTextSize.size1, width: PosTextSize.size1)),
          PosColumn(
              text: '-${totalCashOut.toStringAsFixed(2)}', width: 3)
        ]);
        //total cash drawer
        bytes += generator.row([
          PosColumn(
              text: 'Total Cash Drawer',
              width: 9,
              containsChinese: true,
              styles: PosStyles(height: PosTextSize.size1, width: PosTextSize.size1)),
          PosColumn(text: '${totalCashBalance.toStringAsFixed(2)}', width: 3)
        ]);
        bytes += generator.hr();
        //final part
        bytes += generator.feed(1);
        bytes += generator.cut(mode: PosCutMode.partial);
        return bytes;
      } catch (e) {
        print('layout error: $e');
        return null;
      }
    }
  }

/*
  ----------------DB Query part------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
*/

/*
  read receipt layout
*/
  readReceiptLayout() async {
    List<Receipt> data = await PosDatabase.instance.readAllReceipt();
    for(int i = 0; i < data.length; i++){
      if(data[i].status == 1){
        receipt = data[i];
      }
    }
  }

/*
  read branch latest order cache (auto print when place order click)
*/
  readOrderCache() async {
    final prefs = await SharedPreferences.getInstance();
    final int? branch_id = prefs.getInt('branch_id');
    List<OrderCache> data = await PosDatabase.instance.readBranchLatestOrderCache(branch_id!);
    orderCache = data[0];
    List<OrderDetail> detailData = await PosDatabase.instance.readTableOrderDetail(orderCache!.order_cache_sqlite_id.toString());
    if(!detailData.contains(detailData)){
      orderDetailList = List.from(detailData);
    }
    List<TableUseDetail> detailData2 = await PosDatabase.instance.readAllTableUseDetail(orderCache!.table_use_sqlite_id!);
    for(int i = 0; i < detailData2.length; i++){
      List<PosTable> tableData = await PosDatabase.instance
          .readSpecificTable(branch_id, detailData2[i].table_sqlite_id!);
      if(!tableList.contains(tableData)){
        tableList.add(tableData[0]);
      }
    }
    _isLoad = true;
  }

/*
  read specific order cache/table
*/
  readSpecificOrderCache(String orderCacheId, String dateTime) async {

    final prefs = await SharedPreferences.getInstance();
    final int? branch_id = prefs.getInt('branch_id');

    List<OrderCache> cacheData  = await PosDatabase.instance.readSpecificDeletedOrderCache(int.parse(orderCacheId));
    orderCache = cacheData[0];
    print('order cache: ${orderCache!.order_cache_sqlite_id}');
    List<OrderDetail> detailData = await PosDatabase.instance.readDeletedOrderDetail(orderCache!.order_cache_sqlite_id.toString(), dateTime);
    orderDetailList = List.from(detailData);
    print('order detail list: ${orderDetailList.length}');


    List<TableUseDetail> detailData2 = await PosDatabase.instance.readAllDeletedTableUseDetail(orderCache!.table_use_sqlite_id!);
    for(int i = 0; i < detailData2.length; i++){
      List<PosTable> tableData = await PosDatabase.instance
          .readSpecificTable(branch_id!, detailData2[i].table_sqlite_id!);
      if(!tableList.contains(tableData)){
        tableList.add(tableData[0]);
      }
    }
  }

/*
  read all payment link company
*/
  readPaymentLinkCompany(String dateTime) async {
    final prefs = await SharedPreferences.getInstance();
    final String? user = prefs.getString('user');
    Map userObject = json.decode(user!);

    settlement_By = userObject['name'];
    List<PaymentLinkCompany> data = await PosDatabase.instance.readAllPaymentLinkCompany(userObject['company_id']);
    for (int i = 0; i < data.length; i++) {
      paymentList = List.from(data);
      await calculateTotalAmount(dateTime);
      _isLoad = true;
    }
  }

/*
  calculate each payment link company total amount
*/
  calculateTotalAmount(String dateTime) async {
    double total = 0.0;
    final prefs = await SharedPreferences.getInstance();
    final int? branch_id = prefs.getInt('branch_id');

    try{
      for(int j = 0; j < paymentList.length; j++){
        total = 0.0;
        List<CashRecord> data = await PosDatabase.instance.readSpecificSettlementCashRecord(branch_id.toString(), dateTime);
        for(int i = 0; i < data.length; i++){
          if(data[i].type == 3 && data[i].payment_type_id == paymentList[j].payment_type_id){
            total += double.parse(data[i].amount!);
            paymentList[j].totalAmount = total;
          } else {
            total = 0.0;
          }
        }
      }
    }catch(e){
      print('Layout calculate total amount error: $e');
    }
  }

/*
  calculate cash drawer
*/
  calculateCashDrawerAmount(String dateTime) async {
    _isLoad = false;
    final prefs = await SharedPreferences.getInstance();
    final int? branch_id = prefs.getInt('branch_id');
    // double totalCashIn = 0.0;
    // double totalCashOut = 0.0;
    try{
      List<CashRecord> data = await PosDatabase.instance.readSpecificSettlementCashRecord(branch_id.toString(), dateTime);
      for (int i = 0; i < data.length; i++) {
        if (data[i].type == 1 || data[i].payment_type_id == '1') {
          totalCashIn += double.parse(data[i].amount!);
        } else if (data[i].type == 2 && data[i].payment_type_id == '') {
          totalCashOut += double.parse(data[i].amount!);
        } else if(data[i].type == 0 && data[i].payment_type_id == ''){
          totalOpeningCash = double.parse(data[i].amount!);
        }
      }
      totalCashBalance = (totalOpeningCash + totalCashIn) - totalCashOut;
      _isLoad = true;
    }catch(e){
      print(e);
      totalCashBalance = 0.0;
    }
  }

/*
  call order item
*/
  callOrderTaxPromoDetail() async {
    await getPaidOrderTaxDetail();
    await getPaidOrderPromotionDetail();
    _isLoad = false;
  }

/*
  read specific paid order tax detail
*/
  getPaidOrderTaxDetail() async {
    List<OrderTaxDetail> data = await PosDatabase.instance.readSpecificOrderTaxDetail(this.paidOrder!.order_sqlite_id.toString());
    orderTaxList = List.from(data);
  }

  getPaidOrderPromotionDetail() async {
    List<OrderPromotionDetail> detailData = await PosDatabase.instance.readSpecificOrderPromotionDetail(this.paidOrder!.order_sqlite_id.toString());
    orderPromotionList = List.from(detailData);
  }

/*
  read specific paid order
*/
  getPaidOrder(String localOrderId) async {
    List<Order> orderData = await PosDatabase.instance.readSpecificPaidOrder(localOrderId);
    paidOrder = orderData[0];
    _isLoad = false;
  }

  callPaidOrderDetail(String localOrderId) async {
    await getPaidOrderCache(localOrderId);
    for(int i = 0; i < paidOrderCacheList.length; i++){
      await getOrderDetail(paidOrderCacheList[i]);
      await getTableList(paidOrderCacheList[i]);
    }
    _isLoad = true;
  }

/*
  read paid order cache
*/
  getPaidOrderCache(String localOrderId) async {
    List<OrderCache> cacheData = await PosDatabase.instance.readSpecificOrderCacheByOrderID(localOrderId);
    if(cacheData.length > 0){
      paidOrderCacheList = List.from(cacheData);
    }
  }

/*
  read table use detail
*/
  getTableList(OrderCache paidCache) async {
    final prefs = await SharedPreferences.getInstance();
    final int? branch_id = prefs.getInt('branch_id');

    List<TableUseDetail> detailData2 = await PosDatabase.instance.readAllDeletedTableUseDetail(paidCache.table_use_sqlite_id!);
    for(int i = 0; i < detailData2.length; i++){
      List<PosTable> tableData = await PosDatabase.instance.readSpecificTable(branch_id!, detailData2[i].table_sqlite_id!);
      if(!tableList.contains(tableData)){
        tableList.add(tableData[0]);
      }
    }
  }

/*
  read paid order cache detail
*/
  getOrderDetail(OrderCache orderCache) async {

    List<OrderDetail> detailData = await PosDatabase.instance.readSpecificOrderDetail(orderCache.order_cache_sqlite_id.toString());
    if(detailData.length > 0){
      orderDetailList = List.from(detailData);
    }
    // for (int k = 0; k < orderDetailList.length; k++) {
    //   List<BranchLinkProduct> result = await PosDatabase.instance.readSpecificBranchLinkProduct(orderDetailList[k].branch_link_product_sqlite_id!);
    //   //Get product category
    //   List<Product> productResult = await PosDatabase.instance.readSpecificProductCategory(result[0].product_id!);
    //   orderDetailList[k].category_id = productResult[0].category_id;
    //   if(orderDetailList[k].has_variant == '1'){
    //     List<BranchLinkProduct> variant = await PosDatabase.instance
    //         .readBranchLinkProductVariant(
    //         orderDetailList[k].branch_link_product_sqlite_id!);
    //     orderDetailList[k].productVariant = ProductVariant(
    //         product_variant_id: int.parse(variant[0].product_variant_id!),
    //         variant_name: variant[0].variant_name);
    //
    //     //Get product variant detail
    //     List<ProductVariantDetail> productVariantDetail = await PosDatabase
    //         .instance
    //         .readProductVariantDetail(variant[0].product_variant_id!);
    //     orderDetailList[k].variantItem.clear();
    //     for (int v = 0; v < productVariantDetail.length; v++) {
    //       //Get product variant item
    //       List<VariantItem> variantItemDetail = await PosDatabase.instance
    //           .readProductVariantItemByVariantID(
    //           productVariantDetail[v].variant_item_id!);
    //       orderDetailList[k].variantItem.add(VariantItem(
    //           variant_item_id:
    //           int.parse(productVariantDetail[v].variant_item_id!),
    //           variant_group_id: variantItemDetail[0].variant_group_id,
    //           name: variant[0].variant_name,
    //           isSelected: true));
    //       productVariantDetail.clear();
    //     }
    //   }
    // }
  }

/*
  get paid order modifier detail
*/
 getPaidOrderModifierDetail(OrderDetail orderDetail) async {
   List<OrderModifierDetail> modDetail = await PosDatabase.instance.readOrderModifierDetail(orderDetail.order_detail_sqlite_id.toString());
   orderModifierDetailList = List.from(modDetail);
 }

/*
  reformat variant name
*/



}