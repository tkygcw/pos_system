import 'dart:convert';

import 'package:esc_pos_utils/esc_pos_utils.dart';
import 'package:flutter/foundation.dart';
import 'package:imin/imin.dart';
import 'package:intl/intl.dart';
import 'package:pos_system/database/pos_database.dart';
import 'package:pos_system/notifier/cart_notifier.dart';
import 'package:pos_system/object/branch_link_dining_option.dart';
import 'package:pos_system/object/cart_product.dart';
import 'package:pos_system/object/cash_record.dart';
import 'package:pos_system/object/checklist.dart';
import 'package:pos_system/object/order_cache.dart';
import 'package:pos_system/object/order_detail.dart';
import 'package:pos_system/object/payment_link_company.dart';
import 'package:pos_system/object/receipt.dart';
import 'package:pos_system/object/report_class.dart';
import 'package:pos_system/object/settlement.dart';
import 'package:pos_system/object/settlement_link_payment.dart';
import 'package:pos_system/object/table.dart';
import 'package:pos_system/object/table_use_detail.dart';
import 'package:pos_system/object/variant_group.dart';
import 'package:pos_system/utils/Utils.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'order.dart';
import 'order_modifier_detail.dart';
import 'order_promotion_detail.dart';
import 'order_tax_detail.dart';

class ReceiptLayout{
  PaperSize? size;
  Receipt? receipt;
  OrderCache? orderCache;
  Order? paidOrder;
  ReportObject? reportObject;
  List<Order> dateOrderList = [], orderList = [];
  List<OrderCache> paidOrderCacheList = [], orderCacheList = [];
  List<OrderTaxDetail> orderTaxList = [];
  List<OrderPromotionDetail> orderPromotionList = [];
  List<OrderDetail> orderDetailList = [], cancelOrderDetailList = [];
  List<PosTable> tableList = [];
  List<PaymentLinkCompany> paymentList = [];
  List<BranchLinkDining> branchLinkDiningList = [];
  List<OrderModifierDetail> orderModifierDetailList = [];
  DateFormat dateFormat = DateFormat("yyyy-MM-dd HH:mm:ss");
  String settlement_By = '';
  double totalPromotion = 0.0;
  double totalCashBalance = 0.0;
  double totalCashIn = 0.0;
  double totalCashOut = 0.0;
  double totalOpeningCash = 0.0;
  bool _isLoad = false;

/*
  open cash drawer function
*/
  openCashDrawer ({required isUSB, value}) async {
    var generator;
    if (isUSB) {
      return Imin.openDrawer();
    } else {
      generator = value;
      List<int> bytes = [];
      bytes += generator.drawer();
      return bytes;
    }
  }
/*
  format product variant
*/
  getVariant(cartProductItem object) {
    List<String?> variant = [];
    String result = '';
    var length = object.variant!.length;
    for (int i = 0; i < length ; i++) {
      VariantGroup group = object.variant![i];
      for (int j = 0; j < group.child!.length; j++) {
        if (group.child![j].isSelected!) {
          variant.add(group.child![j].name!);
          result = variant.toString().replaceAll('[', '').replaceAll(']', '').replaceAll(",", " |");
        }
      }
    }
    return result;
  }

/*
  get total promotion
*/
  getTotalPromotion(CartModel cartModel){
    for(int i = 0; i < cartModel.cartNotifierPayment[0].promotionList!.length; i++){
      totalPromotion += cartModel.cartNotifierPayment[0].promotionList![i].promoAmount!;
    }
    if(cartModel.selectedPromotion != null){
      totalPromotion += cartModel.selectedPromotion!.promoAmount!;
    }
    return totalPromotion.toStringAsFixed(2);
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
    bytes += generator.text('Self test print', styles: PosStyles(bold: true, align: PosAlign.center, height: PosTextSize.size3, width: PosTextSize.size3));
    bytes += generator.text(
        'Optimy pos',
        styles: PosStyles(align: PosAlign.center));
    //telephone
    bytes += generator.text('Tel: 012-3456789',
        styles: PosStyles(align: PosAlign.center, height: PosTextSize.size1));
    bytes += generator.text('optimy@hotmail.com',
        styles: PosStyles(align: PosAlign.center));
    bytes += generator.hr();
    bytes += generator.reset();
    //receipt no
    bytes += generator.text('abcdefghijk',
        styles: PosStyles(
            align: PosAlign.left,
            width: PosTextSize.size1,
            height: PosTextSize.size1));
    bytes += generator.text('lmnopqrstu',
        styles: PosStyles(
            align: PosAlign.center,
            width: PosTextSize.size1,
            height: PosTextSize.size1));
    bytes += generator.text('vwxyz',
        styles: PosStyles(
            align: PosAlign.right,
            width: PosTextSize.size1,
            height: PosTextSize.size1));
    bytes += generator.reset();

    bytes += generator.feed(1);
    bytes += generator.drawer();
    bytes += generator.cut(mode: PosCutMode.full);
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
    bytes += generator.text('Self test', styles: PosStyles(bold: true, align: PosAlign.center, height: PosTextSize.size3, width: PosTextSize.size3));
    bytes += generator.text('This is 58mm', styles: PosStyles(bold: true, align: PosAlign.center, height: PosTextSize.size3, width: PosTextSize.size3));

    bytes += generator.feed(1);
    bytes += generator.drawer();
    bytes += generator.cut(mode: PosCutMode.partial);
    return bytes;
  }

/*
  test print layout 58mm
*/
  testTicket35mm(bool isUSB, {value}) async {
    String dateTime = dateFormat.format(DateTime.now());
    print("Current Datetime: ${dateTime}");
    var generator;
    try {
      if (isUSB) {
        final profile = await CapabilityProfile.load();
        generator = Generator(PaperSize.mm35, profile);
      } else {
        generator = value;
      }

      List<String> commands = [];
      commands.add('SIZE 35 mm,25 mm\n');
      // commands.add('GAP 2.88 mm,0 mm\n');
      commands.add('DIRECTION 1\n');
      commands.add('CLS\n');
      commands.add('TEXT 50,20,"2",0,1,1,"CHAGEE"\n');
      // commands.add('TEXT 50,20,"TSS24.BF2",0,1,1,"霸王茶姬"\n');
      commands.add('TEXT 50,45,"2",0,1,1,"10234"\n');
      commands.add('TEXT 50,70,"2",0,1,1,"MILK TEA LARGE"\n');
      commands.add('PRINT 1\n');
      commands.add('END\n');

      List<int> bytes = commands.map((command) => command.codeUnits).expand((codeUnit) => codeUnit).toList();
      String textToPrint = String.fromCharCodes(bytes);
      List<int> result = generator.text(textToPrint);

      return result;
    } catch (e) {
      // Handle errors during profile loading or generator initialization
      print('testTicket35mm Error: $e');
      return []; // Or any other error-handling strategy
    }
  }

/*
  Test print checklist layout 80mm
*/
  printTestCheckList80mm(bool isUSB, {value, required Checklist checklistLayout}) async {
    Checklist checklist = checklistLayout;
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

      bytes += generator.text('Table No: 5', styles: PosStyles(bold: true, align: PosAlign.left, height: PosTextSize.size2, width: PosTextSize.size2));

      // bytes += generator.text('Table No: 5', styles: PosStyles(bold: true, align: PosAlign.left, height: PosTextSize.size2, width: PosTextSize.size2));
      bytes += generator.text('Batch No: #123456-005');
      bytes += generator.text('Order By: Demo');
      bytes += generator.text('Order time: DD/MM/YY hh:mm PM');
      bytes += generator.hr();
      bytes += generator.reset();

      //order product
      bytes += generator.row([
        PosColumn(text: '1',
            width: 2,
            styles: PosStyles(
                bold: true,
                height: PosTextSize.size1,
                width: PosTextSize.size1)),
        PosColumn(
            text: 'Product 1',
            width: 10,
            containsChinese: true,
            styles: PosStyles(
                align: PosAlign.left,
                height:  checklist.product_name_font_size == 0 ? PosTextSize.size2 : PosTextSize.size1,
                width: PosTextSize.size1)),
      ]);
      bytes += generator.row([
        PosColumn(text: '1',
            width: 2,
            styles: PosStyles(
                bold: true,
                height: PosTextSize.size1,
                width: PosTextSize.size1)),
        PosColumn(
            text: 'Product 2',
            width: 10,
            containsChinese: true,
            styles: PosStyles(
                height: checklist.product_name_font_size == 0 ? PosTextSize.size2 : PosTextSize.size1,
                width: PosTextSize.size1)),
      ]);
      bytes += generator.reset();
      bytes += generator.row([
        PosColumn(text: '', width: 2),
        PosColumn(text: '**Remark',
            width: 10,
            containsChinese: true,
            styles: PosStyles(
              align: PosAlign.left,
              height: checklist.other_font_size == 0 ? PosTextSize.size2 : PosTextSize.size1,
              width: PosTextSize.size1)),
      ]);
      bytes += generator.row([
        PosColumn(text: '1',
            width: 2,
            styles: PosStyles(
                bold: true,
                height: PosTextSize.size1,
                width: PosTextSize.size1)),
        PosColumn(
            text: 'Product 3',
            width: 10,
            containsChinese: true,
            styles: PosStyles(
                height: checklist.product_name_font_size == 0 ? PosTextSize.size2 : PosTextSize.size1,
                width: PosTextSize.size1)),
      ]);
      bytes += generator.row([
        PosColumn(text: '', width: 2),
        PosColumn(text: '(big | small)',
            containsChinese: true,
            width: 10,
            styles: PosStyles(
                align: PosAlign.left,
                height: checklist.other_font_size == 0 ? PosTextSize.size2 : PosTextSize.size1,
                width: PosTextSize.size1)),
      ]);
      bytes += generator.row([
        PosColumn(text: '1',
            width: 2,
            styles: PosStyles(
                bold: true,
                height: PosTextSize.size1,
                width: PosTextSize.size1)),
        PosColumn(
            text: 'Product 4',
            width: 10,
            containsChinese: true,
            styles: PosStyles(
                height: checklist.product_name_font_size == 0 ? PosTextSize.size2 : PosTextSize.size1,
                width: PosTextSize.size1)),
      ]);
      //modifier
      bytes += generator.row([
        PosColumn(text: '', width: 2),
        PosColumn(text: '+add-on1',
            containsChinese: true,
            width: 10,
            styles: PosStyles(
                align: PosAlign.left,
                height: checklist.other_font_size == 0 ? PosTextSize.size2 : PosTextSize.size1,
                width: PosTextSize.size1)),
      ]);
      bytes += generator.row([
        PosColumn(text: '1',
            width: 2,
            styles: PosStyles(
                bold: true,
                height: PosTextSize.size1,
                width: PosTextSize.size1)),
        PosColumn(
            text: 'Product 5',
            width: 10,
            containsChinese: true,
            styles: PosStyles(
                height: checklist.product_name_font_size == 0 ? PosTextSize.size2 : PosTextSize.size1,
                width: PosTextSize.size1)),
      ]);
      bytes += generator.row([
        PosColumn(text: '', width: 2),
        PosColumn(text: '(big | small)',
            containsChinese: true,
            width: 10,
            styles: PosStyles(
                align: PosAlign.left,
                height: checklist.other_font_size == 0 ? PosTextSize.size2 : PosTextSize.size1,
                width: PosTextSize.size1)),
      ]);
      bytes += generator.row([
        PosColumn(text: '', width: 2),
        PosColumn(text: '+add-on2',
            containsChinese: true,
            width: 10,
            styles: PosStyles(
                align: PosAlign.left,
                height: checklist.other_font_size == 0 ? PosTextSize.size2 : PosTextSize.size1,
                width: PosTextSize.size1)),
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
  Test print checklist layout 58mm
*/
  printTestCheckList58mm(bool isUSB, {value, required Checklist checklistLayout}) async {
    Checklist checklist = checklistLayout;
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
      bytes += generator.text('** ORDER LIST **', styles: PosStyles(align: PosAlign.center, height:PosTextSize.size2, width: PosTextSize.size2 ));
      bytes += generator.emptyLines(1);
      bytes += generator.reset();
      //other order detail
      bytes += generator.text('Table No: 5', styles: PosStyles(bold: true, align: PosAlign.center, height: PosTextSize.size2, width: PosTextSize.size2));
      bytes += generator.text('Batch No', styles: PosStyles(align: PosAlign.center));
      bytes += generator.text('#123456-005', styles: PosStyles(align: PosAlign.center));
      bytes += generator.text('Order By', styles: PosStyles(align: PosAlign.center));
      bytes += generator.text('Demo', styles: PosStyles(align: PosAlign.center));
      bytes += generator.text('Order time', styles: PosStyles(align: PosAlign.center));
      bytes += generator.text('DD/MM/YY hh:mm PM', styles: PosStyles(align: PosAlign.center));
      bytes += generator.hr();
      bytes += generator.reset();

      //order product
      bytes += generator.row([
        PosColumn(text: '1', width: 2, styles: PosStyles(bold: true)),
        PosColumn(
            text: 'Product 1',
            width: 10,
            containsChinese: true,
            styles: PosStyles(
                height: checklist.product_name_font_size == 0 ? PosTextSize.size2 : PosTextSize.size1,
                width: PosTextSize.size1)
        ),
      ]);
      bytes += generator.row([
        PosColumn(text: '1', width: 2, styles: PosStyles(bold: true)),
        PosColumn(
            text: 'Product 2',
            width: 10,
            containsChinese: true,
            styles: PosStyles(
                height: checklist.product_name_font_size == 0 ? PosTextSize.size2 : PosTextSize.size1,
                width: PosTextSize.size1)
        ),
      ]);
      bytes += generator.row([
        PosColumn(text: '', width: 2),
        PosColumn(text: '**Remark',
            width: 10,
            styles: PosStyles(
                height: checklist.other_font_size == 0 ? PosTextSize.size2 : PosTextSize.size1,
                width: PosTextSize.size1)),
      ]);
      bytes += generator.row([
        PosColumn(text: '1', width: 2, styles: PosStyles(bold: true)),
        PosColumn(
            text: 'Product 3',
            width: 10,
            containsChinese: true,
            styles: PosStyles(
                height: checklist.product_name_font_size == 0 ? PosTextSize.size2 : PosTextSize.size1,
                width: PosTextSize.size1)
        ),
      ]);
      bytes += generator.row([
        PosColumn(text: '', width: 2),
        PosColumn(text: '(big | small)',
            containsChinese: true,
            width: 10,
            styles: PosStyles(
                height: checklist.other_font_size == 0 ? PosTextSize.size2 : PosTextSize.size1,
                width: PosTextSize.size1)),
      ]);
      bytes += generator.row([
        PosColumn(text: '1', width: 2, styles: PosStyles(bold: true)),
        PosColumn(
            text: 'Product 4',
            width: 10,
            containsChinese: true,
            styles: PosStyles(
                height: checklist.product_name_font_size == 0 ? PosTextSize.size2 : PosTextSize.size1,
                width: PosTextSize.size1)
        ),
      ]);
      bytes += generator.row([
        PosColumn(text: '', width: 2),
        PosColumn(text: '+add-on1',
            containsChinese: true,
            width: 10,
            styles: PosStyles(
                height: checklist.other_font_size == 0 ? PosTextSize.size2 : PosTextSize.size1,
                width: PosTextSize.size1)),
      ]);
      bytes += generator.row([
        PosColumn(text: '1', width: 2, styles: PosStyles(bold: true)),
        PosColumn(
            text: 'Product 5',
            width: 10,
            containsChinese: true,
            styles: PosStyles(
                height: checklist.product_name_font_size == 0 ? PosTextSize.size2 : PosTextSize.size1,
                width: PosTextSize.size1)
        ),
      ]);
      bytes += generator.row([
        PosColumn(text: '', width: 2),
        PosColumn(text: '(big | small)',
            containsChinese: true,
            width: 10,
            styles: PosStyles(
                height: checklist.other_font_size == 0 ? PosTextSize.size2 : PosTextSize.size1,
                width: PosTextSize.size1)),
      ]);
      bytes += generator.row([
        PosColumn(text: '', width: 2),
        PosColumn(text: '+add-on2',
            containsChinese: true,
            width: 10,
            styles: PosStyles(
                height: checklist.other_font_size == 0 ? PosTextSize.size2 : PosTextSize.size1,
                width: PosTextSize.size1)),
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
      bytes += generator.reset();
      //bytes += generator.image(decodedImage);
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
      if(receipt!.show_address == 1){
        bytes += generator.text('${branchObject['address'].toString().replaceAll(',', '\n')}', styles: PosStyles(align: PosAlign.center));
      }
      //telephone
      bytes += generator.text('Tel: ${branchObject['phone']}', styles: PosStyles(align: PosAlign.center, height: PosTextSize.size1));
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
            text: 'Product 1 (2.00/each)',
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
            text: 'Product 2 (2.00/each)',
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
        bytes += generator.text('${receipt!.footer_text}', styles: PosStyles(bold: true, align: PosAlign.center, height: PosTextSize.size1, width: PosTextSize.size1));
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
        if(receipt!.show_address == 1){
          //Address
          bytes += generator.text('${branchObject['address'].toString().replaceAll(',', '\n')}', styles: PosStyles(align: PosAlign.center));
        }
        //telephone
        bytes += generator.text('Tel: ${branchObject['phone']}', styles: PosStyles(align: PosAlign.center, height: PosTextSize.size1));
        if(receipt!.show_email == 1){
          bytes += generator.text('${receipt!.receipt_email}', styles: PosStyles(align: PosAlign.center));
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
              text: 'Product 1',
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
              text: 'Product 2',
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
          bytes += generator.text('${receipt!.footer_text}', styles: PosStyles(bold: true, height: PosTextSize.size1, width: PosTextSize.size1, align: PosAlign.center));
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

/*
  Receipt layout 80mm
*/
  printReceipt80mm(bool isUSB, String orderId, List<PosTable> selectedTableList, {value, isRefund}) async {
    final prefs = await SharedPreferences.getInstance();
    final String? branch = prefs.getString('branch');
    Map branchObject = json.decode(branch!);
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
    // final ByteData data = await rootBundle.load('drawable/logo2.png');
    // final Uint8List bytes = data.buffer.asUint8List();
    // final decodedImage = img.decodeImage(bytes);
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
        //bytes += generator.image(decodedImage);
        bytes += generator.reset();
        if(paidOrder!.payment_status == 2) {
          bytes += generator.text('** Refund **', styles: PosStyles(align: PosAlign.center, height:PosTextSize.size2, width: PosTextSize.size2));
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
        bytes += generator.emptyLines(1);
        bytes += generator.reset();
        //Address
        if(receipt!.show_address == 1){
          bytes += generator.text('${branchObject['address'].toString().replaceAll(',', '\n')}', styles: PosStyles(align: PosAlign.center));
        }
        //telephone
        bytes += generator.text('Tel: ${branchObject['phone']}', styles: PosStyles(align: PosAlign.center, height: PosTextSize.size1));
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
        bytes += generator.text('Close by: ${this.paidOrder!.close_by}');
        if(selectedTableList.isNotEmpty){
          for(int i = 0; i < selectedTableList.length; i++){
            bytes += generator.text('Table No: ${selectedTableList[i].number}');
          }
        }
        bytes += generator.text('${paidOrder!.dining_name}');
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
        for(int i = 0; i < orderDetailList.length; i++){
          bool productUnitPriceSplit = productNameDisplayOrder(orderDetailList, i, 80);
          bytes += generator.row([
            PosColumn(text: '${orderDetailList[i].quantity}', width: 2),
            orderDetailList[i].unit != '' ?
            PosColumn(
                text: productUnitPriceSplit  ? '${orderDetailList[i].productName}'
                    : '${orderDetailList[i].productName} (${orderDetailList[i].price}/${orderDetailList[i].per_quantity_unit}${orderDetailList[i].unit})',
                width: 7,
                containsChinese: true,
                styles: PosStyles(align: PosAlign.left, bold: true))
                : PosColumn(
                text: productUnitPriceSplit  ? '${orderDetailList[i].productName}'
                    : '${orderDetailList[i].productName} (${orderDetailList[i].price}/each)',
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
              PosColumn(text: orderDetailList[i].unit != '' ? '(${orderDetailList[i].price}/${orderDetailList[i].per_quantity_unit}${orderDetailList[i].unit})' : '(${orderDetailList[i].price}/each)', width: 7),
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
                PosColumn(text: '+${orderModifierDetailList[j].mod_name}', width: 7, containsChinese: true),
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
          receiptItemCount += orderDetailList[i].quantity!.contains('.') ? 1 : int.parse(orderDetailList[i].quantity!);
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
          PosColumn(text: 'Final Amount', width: 8, styles: PosStyles(align: PosAlign.right, height: PosTextSize.size2)),
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
        //footer
        if(receipt!.footer_text_status == 1 && paidOrder!.payment_status == 1){
          bytes += generator.emptyLines(1);
          bytes += generator.text('${receipt!.footer_text}', styles: PosStyles(bold: true, align: PosAlign.center, height: PosTextSize.size1, width: PosTextSize.size1));
        } else if(paidOrder!.payment_status == 2) {
          bytes += generator.hr();
          bytes += generator.text('refund by:', styles: PosStyles(align: PosAlign.center));
          bytes += generator.text('${paidOrder!.refund_by}', styles: PosStyles(align: PosAlign.center));
          bytes += generator.text('refund at:', styles: PosStyles(align: PosAlign.center));
          bytes += generator.text('${Utils.formatDate(paidOrder!.refund_at)}', styles: PosStyles(align: PosAlign.center));
        }
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
  }

/*
  Receipt layout 58mm
*/
  printReceipt58mm(bool isUSB, String orderId, List<PosTable> selectedTableList, {value, isRefund}) async {
    String dateTime = dateFormat.format(DateTime.now());
    final prefs = await SharedPreferences.getInstance();
    final String? branch = prefs.getString('branch');
    Map branchObject = json.decode(branch!);
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
    // final ByteData data = await rootBundle.load('drawable/logo1.jpg');
    // final Uint8List bytes = data.buffer.asUint8List();
    // final image = img.decodeImage(bytes);
    // print('image byte: ${image}');

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
        //bytes += generator.image(image);
        bytes += generator.reset();
        if(paidOrder!.payment_status == 2){
          bytes += generator.text('** Refund **', styles: PosStyles(align: PosAlign.center, height:PosTextSize.size2, width: PosTextSize.size2 ));
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
        bytes += generator.emptyLines(1);
        bytes += generator.reset();
        //Address
        if(receipt!.show_address == 1){
          bytes += generator.text('${branchObject['address'].toString().replaceAll(',', '\n')}', styles: PosStyles(align: PosAlign.center));
        }
        //telephone
        bytes += generator.text('Tel: ${branchObject['phone']}',
            styles: PosStyles(align: PosAlign.center, height: PosTextSize.size1));
        if(receipt!.show_email == 1){
          bytes += generator.text('${receipt!.receipt_email}', styles: PosStyles(align: PosAlign.center));
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
        bytes += generator.text('${this.paidOrder!.generateOrderNumber()}', styles: PosStyles(align: PosAlign.center, bold: true));
        bytes += generator.reset();
        //other order detail
        bytes += generator.text('Close at:', styles: PosStyles(align: PosAlign.center));
        bytes += generator.text('${Utils.formatDate(paidOrder!.created_at)}', styles: PosStyles(align: PosAlign.center));
        if(selectedTableList.isNotEmpty){
          for(int i = 0; i < selectedTableList.length; i++){
            bytes += generator.text('Table No: ${selectedTableList[i].number}', styles: PosStyles(align: PosAlign.center));
          }
        }
        bytes += generator.text('${paidOrder!.dining_name}', styles: PosStyles(align: PosAlign.center));
        bytes += generator.text('Close by:', styles: PosStyles(align: PosAlign.center));
        bytes += generator.text('${this.paidOrder!.close_by}', styles: PosStyles(align: PosAlign.center));
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
        for(int i = 0; i < orderDetailList.length; i++){
          bool productUnitPriceSplit = productNameDisplayOrder(orderDetailList, i, 58);
          bytes += generator.row([
            PosColumn(text: '${orderDetailList[i].quantity}', width: 2),
            orderDetailList[i].unit != '' ?
            PosColumn(
                text: productUnitPriceSplit  ? '${orderDetailList[i].productName!.trim()}'
                    : '${orderDetailList[i].productName!.trim()} (${orderDetailList[i].price}/${orderDetailList[i].per_quantity_unit}${orderDetailList[i].unit})',
                width: 6,
                containsChinese: true,
                styles: PosStyles(bold: true))
                : PosColumn(
                text: productUnitPriceSplit  ? '${orderDetailList[i].productName!.trim()}'
                    : '${orderDetailList[i].productName!.trim()} (${orderDetailList[i].price}/each)',
                width: 6,
                containsChinese: true,
                styles: PosStyles(bold: true)),
            PosColumn(text: '${(double.parse(orderDetailList[i].price!)*double.parse(orderDetailList[i].quantity!)).toStringAsFixed(2)}', width: 4),
          ]);
          bytes += generator.reset();

          if(productUnitPriceSplit){
            bytes += generator.row([
              PosColumn(text: '', width: 2),
              PosColumn(text: orderDetailList[i].unit != '' ? '(${orderDetailList[i].price}/${orderDetailList[i].per_quantity_unit}${orderDetailList[i].unit})' : '(${orderDetailList[i].price}/each)', width: 10),
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
                PosColumn(text: '+${orderModifierDetailList[j].mod_name}', width: 10, containsChinese: true),
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
          receiptItemCount += orderDetailList[i].quantity!.contains('.') ? 1 : int.parse(orderDetailList[i].quantity!);
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
          PosColumn(text: 'Final Amount', width: 8),
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
        bytes += generator.reset();
        //footer
        if(receipt!.footer_text_status == 1 && paidOrder!.payment_status == 1){
          bytes += generator.emptyLines(1);
          bytes += generator.text('${receipt!.footer_text}', styles: PosStyles(bold: true, height: PosTextSize.size1, width: PosTextSize.size1, align: PosAlign.center));
        } else if (paidOrder!.payment_status == 2) {
          bytes += generator.hr();
          bytes += generator.text('refund by:', styles: PosStyles(align: PosAlign.center));
          bytes += generator.text('${paidOrder!.refund_by}', styles: PosStyles(align: PosAlign.center));
          bytes += generator.text('refund at:', styles: PosStyles(align: PosAlign.center));
          bytes += generator.text('${Utils.formatDate(paidOrder!.refund_at)}', styles: PosStyles(align: PosAlign.center));
        }
        bytes += generator.emptyLines(1);
        //copyright
        bytes += generator.text('POWERED BY OPTIMY POS', styles: PosStyles(bold: true, align: PosAlign.center));
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
  Review Receipt layout 80mm
*/
  printPreviewReceipt80mm(bool isUSB, List<PosTable> selectedTableList, CartModel cartModel, {value}) async {
    await readReceiptLayout('80');
    await readOrderCache(int.parse(cartModel.cartNotifierItem[0].order_cache_sqlite_id!));
    // final ByteData data = await rootBundle.load('drawable/logo2.png');
    // final Uint8List bytes = data.buffer.asUint8List();
    // final decodedImage = img.decodeImage(bytes);
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
        bytes += generator.reset();
        //bytes += generator.image(decodedImage);
        bytes += generator.text('** Review Receipt **', styles: PosStyles(align: PosAlign.center, height:PosTextSize.size2, width: PosTextSize.size2 ));
        bytes += generator.emptyLines(1);
        bytes += generator.reset();
        bytes += generator.hr();
        bytes += generator.reset();
        if(selectedTableList.isNotEmpty){
          for(int i = 0; i < selectedTableList.length; i++){
            bytes += generator.text('Table No: ${selectedTableList[i].number}');
          }
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
                text: productUnitPriceSplit  ? '${cartModel.cartNotifierItem[i].product_name}'
                    : '${cartModel.cartNotifierItem[i].product_name} (${cartModel.cartNotifierItem[i].price}/${cartModel.cartNotifierItem[i].per_quantity_unit}${cartModel.cartNotifierItem[i].unit})',
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
              PosColumn(text: '(${cartModel.cartNotifierItem[i].price}/${cartModel.cartNotifierItem[i].per_quantity_unit}${cartModel.cartNotifierItem[i].unit})', width: 7),
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
        return null;
      }
    }
  }

/*
  Review Receipt layout 58mm
*/
  printPreviewReceipt58mm(bool isUSB, List<PosTable> selectedTableList, CartModel cartModel, {value}) async {
    await readReceiptLayout('58');
    await readOrderCache(int.parse(cartModel.cartNotifierItem[0].order_cache_sqlite_id!));
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
        bytes += generator.reset();
        bytes += generator.text('** Review Receipt **', styles: PosStyles(align: PosAlign.center, height:PosTextSize.size2, width: PosTextSize.size2 ));
        bytes += generator.emptyLines(1);
        bytes += generator.reset();
        bytes += generator.hr();
        bytes += generator.reset();
        if(selectedTableList.isNotEmpty){
          for(int i = 0; i < selectedTableList.length; i++){
            bytes += generator.text('Table No: ${selectedTableList[i].number}');
          }
        }
        if(int.tryParse(orderCache!.order_queue!) != null) {
          bytes += generator.text('Order No: ${orderCache!.order_queue}');
        }
        bytes += generator.text('${cartModel.selectedOption}');
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
                text: productUnitPriceSplit  ? '${cartModel.cartNotifierItem[i].product_name!.trim()}'
                    : '${cartModel.cartNotifierItem[i].product_name!.trim()} (${cartModel.cartNotifierItem[i].price}/${cartModel.cartNotifierItem[i].per_quantity_unit!}${cartModel.cartNotifierItem[i].unit!})',
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
              PosColumn(text: '(${cartModel.cartNotifierItem[i].price}/${cartModel.cartNotifierItem[i].per_quantity_unit}${cartModel.cartNotifierItem[i].unit})', width: 10),
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
          // if(cartModel.cartNotifierItem[i].modifier!.isNotEmpty){
          //   for (int j = 0; j < cartModel.cartNotifierItem[i].modifier!.length; j++) {
          //     ModifierGroup group = cartModel.cartNotifierItem[i].modifier![j];
          //     for (int k = 0; k < group.modifierChild!.length; k++) {
          //       if (group.modifierChild![k].isChecked!) {
          //         bytes += generator.row([
          //           PosColumn(text: '+${group.modifierChild![k].name!}', width: 12, containsChinese: true)
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
        return null;
      }
    }
  }

/*
  Check list layout 80mm
*/
  printCheckList80mm(bool isUSB, int localId, {value, isQrOrder}) async {
    Checklist? checklistLayout = await PosDatabase.instance.readSpecificChecklist('80');
    final prefs = await SharedPreferences.getInstance();
    final int? branch_id = prefs.getInt('branch_id');
    await readOrderCache(localId);

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
      bytes += generator.text('** ORDER LIST **', styles: PosStyles(align: PosAlign.center, height:PosTextSize.size2, width: PosTextSize.size2 ));
      bytes += generator.emptyLines(1);
      bytes += generator.reset();
      //other order detail
      if(tableList.isNotEmpty){
        for(int i = 0; i < tableList.length; i++){
          bytes += generator.text('Table No: ${tableList[i].number}', styles: PosStyles(bold: true, align: PosAlign.left, height: PosTextSize.size2, width: PosTextSize.size2));
        }
      } else {
        bytes += generator.text('${orderCache!.dining_name}', styles: PosStyles(bold: true, align: PosAlign.left, height: PosTextSize.size2, width: PosTextSize.size2));
      }
      //order queue
      if(int.tryParse(this.orderCache!.order_queue!) != null){
        bytes += generator.text('Order No: ${this.orderCache!.order_queue!}', styles: PosStyles(align: PosAlign.left, height:PosTextSize.size2, width: PosTextSize.size2));
      }
      // bytes += generator.text('Table No: 5', styles: PosStyles(bold: true, align: PosAlign.left, height: PosTextSize.size2, width: PosTextSize.size2));
      bytes += generator.text('Batch No: #${orderCache!.batch_id}-${branch_id.toString().padLeft(3 ,'0')}');
      if(isQrOrder != null){
        bytes += generator.text('Order By: QrOrder');
      } else {
        bytes += generator.text('Order By: ${orderCache!.order_by}');
      }
      bytes += generator.text('Order time: ${Utils.formatDate(orderCache!.created_at)}');
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
              width: 10,
              containsChinese: true,
              styles: PosStyles(
                  bold: true,
                  align: PosAlign.left,
                  height: checklistLayout != null && checklistLayout.product_name_font_size == 0 ? PosTextSize.size2 : PosTextSize.size1,
                  width: PosTextSize.size1)),
        ]);
        bytes += generator.reset();
        if(orderDetailList[i].has_variant == '1'){
          bytes += generator.row([
            PosColumn(text: '', width: 2, styles: PosStyles(bold: true)),
            PosColumn(text: '(${orderDetailList[i].product_variant_name})',
                containsChinese: true, width: 10,
                styles: PosStyles(
                    align: PosAlign.left,
                    height: checklistLayout != null && checklistLayout.other_font_size == 0 ? PosTextSize.size2 : PosTextSize.size1,
                    width: PosTextSize.size1)),
          ]);
        }
        await getPaidOrderModifierDetail(orderDetailList[i]);
        if(orderModifierDetailList.length > 0) {
          for (int j = 0; j < orderModifierDetailList.length; j++) {
            //modifier
            bytes += generator.row([
              PosColumn(text: '', width: 2),
              PosColumn(text: '+${orderModifierDetailList[j].mod_name}',
                  containsChinese: true,
                  width: 10,
                  styles: PosStyles(
                      align: PosAlign.left,
                      height:  checklistLayout != null && checklistLayout.other_font_size == 0 ? PosTextSize.size2 : PosTextSize.size1,
                      width: PosTextSize.size1)),
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
            PosColumn(text: '**${orderDetailList[i].remark}',
                width: 10,
                containsChinese: true,
                styles: PosStyles(
                    align: PosAlign.left,
                    height:  checklistLayout != null && checklistLayout.other_font_size == 0 ? PosTextSize.size2 : PosTextSize.size1,
                    width: PosTextSize.size1)),
          ]);
        }
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
  printCheckList58mm(bool isUSB, int localId, {value}) async {
    Checklist? checklistLayout = await PosDatabase.instance.readSpecificChecklist('58');
    final prefs = await SharedPreferences.getInstance();
    final int? branch_id = prefs.getInt('branch_id');
    await readOrderCache(localId);

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
      bytes += generator.text('** ORDER LIST **', styles: PosStyles(align: PosAlign.center, height:PosTextSize.size2, width: PosTextSize.size2 ));
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
      if(int.tryParse(this.orderCache!.order_queue!) != null){
        bytes += generator.text('Order No: ${this.orderCache!.order_queue!}', styles: PosStyles(align: PosAlign.center, height:PosTextSize.size2, width: PosTextSize.size2));
      }
      // for(int i = 0; i < tableList.length; i++){
      //   bytes += generator.text('Table No: ${tableList[i].number}', styles: PosStyles(bold: true, align: PosAlign.center, height: PosTextSize.size2, width: PosTextSize.size2));
      // }
      // bytes += generator.text('Table No: 5', styles: PosStyles(bold: true, align: PosAlign.left, height: PosTextSize.size2, width: PosTextSize.size2));
      bytes += generator.text('Batch No', styles: PosStyles(align: PosAlign.center));
      bytes += generator.text('#${orderCache!.batch_id}-${branch_id.toString().padLeft(3 ,'0')}', styles: PosStyles(align: PosAlign.center));
      bytes += generator.text('Order By', styles: PosStyles(align: PosAlign.center));
      bytes += generator.text('${orderCache!.order_by}', styles: PosStyles(align: PosAlign.center));
      bytes += generator.text('Order time', styles: PosStyles(align: PosAlign.center));
      bytes += generator.text('${Utils.formatDate(orderCache!.created_at)}', styles: PosStyles(align: PosAlign.center));
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
              width: 10,
              containsChinese: true,
              styles: PosStyles(
                  bold: true,
                  height: checklistLayout != null && checklistLayout.product_name_font_size == 0 ? PosTextSize.size2 : PosTextSize.size1,
                  width: PosTextSize.size1)
          ),

        ]);
        bytes += generator.reset();
        if(orderDetailList[i].has_variant == '1'){
          bytes += generator.row([
            PosColumn(text: '', width: 2),
            PosColumn(text: '(${orderDetailList[i].product_variant_name})',
                containsChinese: true,
                width: 10,
                styles: PosStyles(
                    height: checklistLayout != null && checklistLayout.other_font_size == 0 ? PosTextSize.size2 : PosTextSize.size1,
                    width: PosTextSize.size1)),
          ]);
        }
        await getPaidOrderModifierDetail(orderDetailList[i]);
        if(orderModifierDetailList.isNotEmpty) {
          for (int j = 0; j < orderModifierDetailList.length; j++) {
            //modifier
            bytes += generator.row([
              PosColumn(text: '', width: 2),
              PosColumn(text: '+${orderModifierDetailList[j].mod_name}',
                  containsChinese: true,
                  width: 10,
                  styles: PosStyles(
                      height: checklistLayout != null && checklistLayout.other_font_size == 0 ? PosTextSize.size2 : PosTextSize.size1,
                      width: PosTextSize.size1)),
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
            PosColumn(text: '**${orderDetailList[i].remark}',
                containsChinese: true,
                width: 10,
                styles: PosStyles(
                    height: checklistLayout != null && checklistLayout.other_font_size == 0 ? PosTextSize.size2 : PosTextSize.size1,
                    width: PosTextSize.size1)),
          ]);
        }
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
  reprint check list layout 80mm
*/
  reprintCheckList80mm(bool isUSB, CartModel cartModel, {value}) async {
    Checklist? checklistLayout = await PosDatabase.instance.readSpecificChecklist('80');
    final prefs = await SharedPreferences.getInstance();
    final int? branch_id = prefs.getInt('branch_id');
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
      bytes += generator.text('** Reprint List **', styles: PosStyles(align: PosAlign.center, height:PosTextSize.size2, width: PosTextSize.size2 ));
      bytes += generator.emptyLines(1);
      bytes += generator.reset();
      //other order detail
      if(cartModel.selectedTable.isNotEmpty){
        for(int i = 0; i < cartModel.selectedTable.length; i++){
          bytes += generator.text('Table No: ${cartModel.selectedTable[i].number}', styles: PosStyles(bold: true, align: PosAlign.left, height: PosTextSize.size2, width: PosTextSize.size2));
        }
      } else {
        bytes += generator.text('${cartModel.selectedOption}');
      }
      bytes += generator.text('Batch No: #${cartModel.cartNotifierItem[0].first_cache_batch}-${branch_id.toString().padLeft(3 ,'0')}');
      bytes += generator.text('Order By: ${cartModel.cartNotifierItem[0].first_cache_order_by}');
      bytes += generator.text('Order Time: ${Utils.formatDate(cartModel.cartNotifierItem[0].first_cache_created_date_time)}');
      // bytes += generator.text('Table No: 5', styles: PosStyles(bold: true, align: PosAlign.left, height: PosTextSize.size2, width: PosTextSize.size2));
      bytes += generator.hr();
      bytes += generator.reset();
      /*
    *
    * body
    *
    * */
      //order product
      for(int i = 0; i < cartModel.cartNotifierItem.length; i++){
        bytes += generator.row([
          PosColumn(text: '${cartModel.cartNotifierItem[i].quantity}', width: 2, styles: PosStyles(align: PosAlign.left, bold: true)),
          PosColumn(
              text: '${cartModel.cartNotifierItem[i].product_name!.trim()}) ',
              width: 10,
              containsChinese: true,
              styles: PosStyles(
                  bold: true,
                  align: PosAlign.left,
                  height: checklistLayout != null && checklistLayout.product_name_font_size == 0 ? PosTextSize.size2 : PosTextSize.size1,
                  width: PosTextSize.size1)),
        ]);
        bytes += generator.reset();
        if(cartModel.cartNotifierItem[i].productVariantName != null && cartModel.cartNotifierItem[i].productVariantName != ''){
          bytes += generator.row([
            PosColumn(text: '', width: 2),
            PosColumn(text: '(${cartModel.cartNotifierItem[i].productVariantName})',
                width: 10,
                containsChinese: true,
                styles: PosStyles(
                    align: PosAlign.left,
                    height: checklistLayout != null && checklistLayout.other_font_size == 0 ? PosTextSize.size2 : PosTextSize.size1,
                    width: PosTextSize.size1)),
          ]);
        }
        bytes += generator.reset();
        if(cartModel.cartNotifierItem[i].orderModifierDetail!.isNotEmpty){
          cartProductItem cartItem = cartModel.cartNotifierItem[i];
          for(int j = 0; j < cartItem.orderModifierDetail!.length; j++){
            bytes += generator.row([
              PosColumn(text: '', width: 2),
              PosColumn(text: '+${cartItem.orderModifierDetail![j].mod_name!}',
                  width: 10,
                  containsChinese: true,
                  styles: PosStyles(
                      align: PosAlign.left,
                      height: checklistLayout != null && checklistLayout.other_font_size == 0 ? PosTextSize.size2 : PosTextSize.size1,
                      width: PosTextSize.size1)),
            ]);
          }
        }
        // if(cartModel.cartNotifierItem[i].modifier!.isNotEmpty){
        //   for (int j = 0; j < cartModel.cartNotifierItem[i].modifier!.length; j++) {
        //     ModifierGroup group = cartModel.cartNotifierItem[i].modifier![j];
        //     for (int k = 0; k < group.modifierChild!.length; k++) {
        //       if (group.modifierChild![k].isChecked!) {
        //         bytes += generator.row([
        //           PosColumn(text: '', width: 2),
        //           PosColumn(text: '+${group.modifierChild![k].name!}',
        //               width: 10,
        //               containsChinese: true,
        //               styles: PosStyles(
        //                   align: PosAlign.left,
        //                   height: checklistLayout != null && checklistLayout.other_font_size == 0 ?  PosTextSize.size2 : PosTextSize.size1,
        //                   width: PosTextSize.size1))
        //         ]);
        //       }
        //     }
        //   }
        // }
        /*
        * product remark
        * */
        bytes += generator.reset();
        if (cartModel.cartNotifierItem[i].remark != '') {
          bytes += generator.row([
            PosColumn(text: '', width: 2),
            PosColumn(text: '**${cartModel.cartNotifierItem[i].remark}',
                width: 10,
                containsChinese: true,
                styles: PosStyles(
                    align: PosAlign.left,
                    height: checklistLayout != null && checklistLayout.other_font_size == 0 ?  PosTextSize.size2 : PosTextSize.size1,
                    width: PosTextSize.size1)),
          ]);
        }
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
  reprint check list layout 58mm
*/
  reprintCheckList58mm(bool isUSB, CartModel cartModel, {value}) async {
    Checklist? checklistLayout = await PosDatabase.instance.readSpecificChecklist('58');
    final prefs = await SharedPreferences.getInstance();
    final int? branch_id = prefs.getInt('branch_id');

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
      bytes += generator.text('** Reprint List **', styles: PosStyles(align: PosAlign.center, height:PosTextSize.size2, width: PosTextSize.size2 ));
      bytes += generator.emptyLines(1);
      bytes += generator.reset();
      //other order detail
      if(cartModel.selectedTable.isNotEmpty){
        for(int i = 0; i < cartModel.selectedTable.length; i++){
          bytes += generator.text('Table No: ${cartModel.selectedTable[i].number}', styles: PosStyles(bold: true, align: PosAlign.left, height: PosTextSize.size2, width: PosTextSize.size2));
        }
      }
      bytes += generator.text('Batch No: #${cartModel.cartNotifierItem[0].first_cache_batch}-${branch_id.toString().padLeft(3 ,'0')}');
      bytes += generator.text('Order By: ${cartModel.cartNotifierItem[0].first_cache_order_by}');
      bytes += generator.text('Order time: ${Utils.formatDate(cartModel.cartNotifierItem[0].first_cache_created_date_time)}');
      // bytes += generator.text('Table No: 5', styles: PosStyles(bold: true, align: PosAlign.left, height: PosTextSize.size2, width: PosTextSize.size2));
      bytes += generator.hr();
      bytes += generator.reset();
      /*
    *
    * body
    *
    * */
      //order product
      for(int i = 0; i < cartModel.cartNotifierItem.length; i++){
        bytes += generator.row([
          PosColumn(text: '${cartModel.cartNotifierItem[i].quantity}', width: 2, styles: PosStyles(align: PosAlign.left, bold: true)),
          PosColumn(
              text: '${cartModel.cartNotifierItem[i].product_name})',
              width: 10,
              containsChinese: true,
              styles: PosStyles(
                  bold: true,
                  align: PosAlign.left,
                  height: checklistLayout != null && checklistLayout.product_name_font_size == 0 ? PosTextSize.size2 : PosTextSize.size1,
                  width: PosTextSize.size1)),
        ]);
        bytes += generator.reset();
        if(cartModel.cartNotifierItem[i].productVariantName != null && cartModel.cartNotifierItem[i].productVariantName != ''){
          bytes += generator.row([
            PosColumn(text: '', width: 2),
            PosColumn(text: '(${cartModel.cartNotifierItem[i].productVariantName})',
                width: 10,
                containsChinese: true,
                styles: PosStyles(
                  width: PosTextSize.size1,
                  height: checklistLayout != null && checklistLayout.other_font_size == 0 ? PosTextSize.size2 : PosTextSize.size1,
                )),
          ]);
        }
        //product modifier
        if(cartModel.cartNotifierItem[i].orderModifierDetail!.isNotEmpty){
          cartProductItem cartItem = cartModel.cartNotifierItem[i];
          for(int j = 0; j < cartItem.orderModifierDetail!.length; j++){
            bytes += generator.row([
              PosColumn(text: '', width: 2),
              PosColumn(text: '+${cartItem.orderModifierDetail![j].mod_name!}',
                  width: 10,
                  containsChinese: true,
                  styles: PosStyles(
                    width: PosTextSize.size1,
                    height: checklistLayout != null && checklistLayout.other_font_size == 0 ? PosTextSize.size2 : PosTextSize.size1,
                  )),
            ]);
          }
        }
        /*
        * product remark
        * */
        bytes += generator.reset();
        if (cartModel.cartNotifierItem[i].remark != '') {
          bytes += generator.row([
            PosColumn(text: '', width: 2),
            PosColumn(text: '**${cartModel.cartNotifierItem[i].remark}',
                width: 10,
                containsChinese: true,
                styles: PosStyles(
                    align: PosAlign.left,
                    height: checklistLayout != null && checklistLayout.other_font_size == 0 ? PosTextSize.size2 : PosTextSize.size1,
                    width: PosTextSize.size1)),
          ]);
        }
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
  qr kitchen layout 80mm
*/
  printQrKitchenList80mm(bool isUSB, OrderDetail orderDetail, int localId, {value}) async {
    String dateTime = dateFormat.format(DateTime.now());
    final prefs = await SharedPreferences.getInstance();
    final int? branch_id = prefs.getInt('branch_id');
    await readOrderCache(localId);

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
        if(orderDetail.tableNumber.isNotEmpty){
          bytes += generator.text('Table No: ${orderDetail.tableNumber[0]}', styles: PosStyles(bold: true, align: PosAlign.center, height: PosTextSize.size2, width: PosTextSize.size2));
        } else {
          bytes += generator.text('${orderCache!.dining_name}', styles: PosStyles(bold: true, align: PosAlign.center, height: PosTextSize.size2, width: PosTextSize.size2));
        }
        bytes += generator.text('Batch No: #${orderCache!.batch_id}-${branch_id.toString().padLeft(3 ,'0')}', styles: PosStyles(align: PosAlign.center));
        bytes += generator.text('order time: ${Utils.formatDate(orderCache!.created_at)}', styles: PosStyles(align: PosAlign.center));
        bytes += generator.hr();
        bytes += generator.reset();
        /*
    *
    * body
    *
    * */
        //order product
        bytes += generator.row([
          PosColumn(text: '${orderDetail.quantity}', width: 2, styles: PosStyles(align: PosAlign.left, bold: true, height: PosTextSize.size2, width: PosTextSize.size2)),
          PosColumn(
              text: '${orderDetail.productName}',
              width: 8,
              containsChinese: true,
              styles: PosStyles(align: PosAlign.left, height: PosTextSize.size2, width: PosTextSize.size2)),
          PosColumn(
              text: '',
              width: 2,
              styles: PosStyles(align: PosAlign.right)),
        ]);
        bytes += generator.reset();
        //product variant
        if(orderDetail.has_variant == '1'){
          bytes += generator.row([
            PosColumn(text: '', width: 2, styles: PosStyles(align: PosAlign.left)),
            PosColumn(text: '(${orderDetail.product_variant_name})', width: 8, containsChinese: true, styles: PosStyles(align: PosAlign.left)),
            PosColumn(text: '', width: 2, styles: PosStyles(align: PosAlign.right)),
          ]);
        }
        bytes += generator.reset();
        //product modifier
        if(orderDetail.orderModifierDetail.isNotEmpty) {
          List<OrderModifierDetail> modList = orderDetail.orderModifierDetail;
          for (int j = 0; j < modList.length; j++) {
            //modifier
            bytes += generator.row([
              PosColumn(text: '', width: 2),
              PosColumn(text: '+${modList[j].mod_name}',
                  width: 8,
                  containsChinese: true,
                  styles: PosStyles(align: PosAlign.left, height: PosTextSize.size2, width: PosTextSize.size2)),
              PosColumn(text: '', width: 2, styles: PosStyles(align: PosAlign.right)),
            ]);
          }
        }
        /*
        * product remark
        * */
        bytes += generator.reset();
        if (orderDetail.remark != '') {
          bytes += generator.row([
            PosColumn(text: '', width: 2),
            PosColumn(text: '**${orderDetail.remark}', width: 8, containsChinese: true, styles: PosStyles(align: PosAlign.left)),
            PosColumn(text: '', width: 2),
          ]);
        }

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
  qr kitchen layout 58mm
*/
  printQrKitchenList58mm(bool isUSB, OrderDetail orderDetail, int localId, {value}) async {
    String dateTime = dateFormat.format(DateTime.now());
    final prefs = await SharedPreferences.getInstance();
    final int? branch_id = prefs.getInt('branch_id');
    await readOrderCache(localId);

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
        bytes += generator.text('** kitchen list **', styles: PosStyles(align: PosAlign.center, width: PosTextSize.size2, height: PosTextSize.size2));
        bytes += generator.emptyLines(1);
        bytes += generator.reset();
        //other order detail
        if(orderDetail.tableNumber.isNotEmpty){
          bytes += generator.text('Table No: ${orderDetail.tableNumber[0]}', styles: PosStyles(bold: true, align: PosAlign.center, height: PosTextSize.size2, width: PosTextSize.size2));
        } else {
          bytes += generator.text('${orderCache!.dining_name}', styles: PosStyles(bold: true, align: PosAlign.center, height: PosTextSize.size2, width: PosTextSize.size2));
        }
        bytes += generator.text('Batch No', styles: PosStyles(align: PosAlign.center));
        bytes += generator.text('#${orderCache!.batch_id}-${branch_id.toString().padLeft(3 ,'0')}', styles: PosStyles(align: PosAlign.center));
        bytes += generator.text('order time', styles: PosStyles(align: PosAlign.center));
        bytes += generator.text('${Utils.formatDate(dateTime)}', styles: PosStyles(align: PosAlign.center));
        bytes += generator.hr();
        bytes += generator.reset();
        /*
    *
    * body
    *
    * */
        //order product
        bytes += generator.row([
          PosColumn(text: '${orderDetail.quantity}', width: 2, styles: PosStyles(bold: true, height: PosTextSize.size2, width: PosTextSize.size2)),
          PosColumn(
              text: '${orderDetail.productName}',
              width: 8,
              containsChinese: true,
              styles: PosStyles(height: PosTextSize.size2, width: PosTextSize.size2)),
          PosColumn(
              text: '',
              width: 2),
        ]);
        bytes += generator.reset();
        //product variant
        if(orderDetail.has_variant == '1'){
          bytes += generator.row([
            PosColumn(text: '', width: 2),
            PosColumn(text: '(${orderDetail.product_variant_name})', width: 8, containsChinese: true,),
            PosColumn(text: '', width: 2),
          ]);
        }
        bytes += generator.reset();

        //product modifier
        if(orderDetail.orderModifierDetail.isNotEmpty) {
          List<OrderModifierDetail> modList = orderDetail.orderModifierDetail;
          for (int j = 0; j < modList.length; j++) {
            //modifier
            bytes += generator.row([
              PosColumn(text: '', width: 2),
              PosColumn(text: '+${modList[j].mod_name}',
                  width: 8,
                  containsChinese: true,
                  styles: PosStyles(height: PosTextSize.size2, width: PosTextSize.size2)),
              PosColumn(text: '', width: 2),
            ]);
          }
        }
        /*
        * product remark
        * */
        bytes += generator.reset();
        if (orderDetail.remark != '') {
          bytes += generator.row([
            PosColumn(text: '', width: 2),
            PosColumn(text: '**${orderDetail.remark}', width: 8, containsChinese: true),
            PosColumn(text: '', width: 2),
          ]);
        }

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
  kitchen layout 80mm
*/
  printKitchenList80mm(bool isUSB, int localId, {value, required OrderDetail orderDetail}) async {
    final prefs = await SharedPreferences.getInstance();
    final int? branch_id = prefs.getInt('branch_id');
    await readOrderCache(localId);
    cartProductItem cartItem = cartProductItem(
      quantity: int.tryParse(orderDetail.quantity!) != null ? int.parse(orderDetail.quantity!) : double.parse(orderDetail.quantity!),
      product_name: orderDetail.productName,
      productVariantName: orderDetail.product_variant_name,
      remark: orderDetail.remark,
      orderModifierDetail: orderDetail.orderModifierDetail,
      unit: orderDetail.unit,
      per_quantity_unit: orderDetail.per_quantity_unit
    );

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
        if(tableList.isNotEmpty){
          for(int i = 0; i < tableList.length; i++){
            bytes += generator.text('Table No: ${tableList[i].number}', styles: PosStyles(bold: true, align: PosAlign.center, height: PosTextSize.size2, width: PosTextSize.size2));
          }
        } else {
          bytes += generator.text('${orderCache!.dining_name}', styles: PosStyles(bold: true, align: PosAlign.center, height: PosTextSize.size2, width: PosTextSize.size2));
        }
        //order queue
        if(int.tryParse(this.orderCache!.order_queue!) != null){
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
          // PosColumn(text: '${cartItem.quantity}', width: 2, styles: PosStyles(align: PosAlign.left, bold: true, height: PosTextSize.size2)),
          // PosColumn(text: '${cartItem.quantity!*int.parse(cartItem.per_quantity_unit!)}${cartItem.unit}', width: 2, styles: PosStyles(align: PosAlign.left, bold: true, height: PosTextSize.size2)),
          PosColumn(text: cartItem.unit != 'each' ? '${(cartItem.quantity!*int.parse(cartItem.per_quantity_unit!)).toStringAsFixed(2)}${cartItem.unit}'
              : '${cartItem.quantity}',
              width: 2, styles: PosStyles(align: PosAlign.left, bold: true, height: PosTextSize.size2)),
          PosColumn(
              text: '${cartItem.product_name}',
              width: 10,
              containsChinese: true,
              styles: PosStyles(align: PosAlign.left, height: PosTextSize.size2, width: PosTextSize.size2))
        ]);
        bytes += generator.reset();
        //product variant
        if(cartItem.productVariantName != ''){
          bytes += generator.row([
            PosColumn(text: '', width: 2, styles: PosStyles(align: PosAlign.left)),
            PosColumn(text: '(${cartItem.productVariantName})', width: 10, containsChinese: true, styles: PosStyles(align: PosAlign.left)),
          ]);
        }
        bytes += generator.reset();
        //product modifier
        if(cartItem.orderModifierDetail!.isNotEmpty) {
          for (int j = 0; j < cartItem.orderModifierDetail!.length; j++) {
            //modifier
            bytes += generator.row([
              PosColumn(text: '', width: 2),
              PosColumn(text: '+${cartItem.orderModifierDetail![j].mod_name}',
                  containsChinese: true,
                  width: 10,
                  styles: PosStyles(align: PosAlign.left)),
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
            PosColumn(text: '**${cartItem.remark}', width: 8, containsChinese: true, styles: PosStyles(align: PosAlign.left, height: PosTextSize.size1, width: PosTextSize.size2)),
            PosColumn(text: '', width: 2),
          ]);
        }

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
  kitchen layout 58mm
*/
  printKitchenList58mm(bool isUSB, int localId, {value, required OrderDetail orderDetail}) async {
    String dateTime = dateFormat.format(DateTime.now());
    final prefs = await SharedPreferences.getInstance();
    final int? branch_id = prefs.getInt('branch_id');
    await readOrderCache(localId);
    cartProductItem cartItem = cartProductItem(
        quantity: int.tryParse(orderDetail.quantity!) != null ? int.parse(orderDetail.quantity!) : double.parse(orderDetail.quantity!),
        product_name: orderDetail.productName,
        productVariantName: orderDetail.product_variant_name,
        remark: orderDetail.remark,
        orderModifierDetail: orderDetail.orderModifierDetail,
        unit: orderDetail.unit,
        per_quantity_unit: orderDetail.per_quantity_unit
    );

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
        bytes += generator.text('** kitchen list **', styles: PosStyles(align: PosAlign.center, width: PosTextSize.size2, height: PosTextSize.size2));
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
        if(int.tryParse(this.orderCache!.order_queue!) != null){
          bytes += generator.text('Order No: ${this.orderCache!.order_queue!}', styles: PosStyles(align: PosAlign.center, height:PosTextSize.size2, width: PosTextSize.size2));
        }
        bytes += generator.text('Batch No', styles: PosStyles(align: PosAlign.center));
        bytes += generator.text('#${orderCache!.batch_id}-${branch_id.toString().padLeft(3 ,'0')}', styles: PosStyles(align: PosAlign.center));
        bytes += generator.text('Order time', styles: PosStyles(align: PosAlign.center));
        bytes += generator.text('${Utils.formatDate(dateTime)}', styles: PosStyles(align: PosAlign.center));
        bytes += generator.hr();
        bytes += generator.reset();
        /*
    *
    * body
    *
    * */
        //order product
        bytes += generator.row([
          PosColumn(text: cartItem.unit != 'each' ? '${(cartItem.quantity!*int.parse(cartItem.per_quantity_unit!)).toStringAsFixed(2)}${cartItem.unit}' : '${cartItem.quantity}',
              width: 3, styles: PosStyles(bold: true)),
          PosColumn(
              text: '${cartItem.product_name}',
              width: 9,
              containsChinese: true),
        ]);
        bytes += generator.reset();
        //product variant
        if(cartItem.productVariantName != ''){
          bytes += generator.row([
            PosColumn(text: '', width: 3),
            PosColumn(text: '(${cartItem.productVariantName})', width: 9, containsChinese: true)
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
                  styles: PosStyles(height: PosTextSize.size1, width: PosTextSize.size1))
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
            PosColumn(text: '**${cartItem.remark}', width: 9, containsChinese: true),
          ]);
        }

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
  label printer layout 35mm
*/
  printLabel35mm(bool isUSB, int localId, {value, required OrderDetail orderDetail}) async {
    String dateTime = dateFormat.format(DateTime.now());
    final prefs = await SharedPreferences.getInstance();
    final int? branch_id = prefs.getInt('branch_id');
    await readOrderCache(localId);
    cartProductItem cartItem = cartProductItem(
      quantity: int.parse(orderDetail.quantity!),
      product_name: orderDetail.productName,
      productVariantName: orderDetail.product_variant_name,
      remark: orderDetail.remark,
      orderModifierDetail: orderDetail.orderModifierDetail,
    );

    if(_isLoad == true){
      var generator;
      if (isUSB) {
        final profile = await CapabilityProfile.load();
        generator = Generator(PaperSize.mm35, profile);
      } else {
        generator = value;
      }

      List<int> bytes = [];
      try {
        //order product
        bytes += generator.row([
          PosColumn(text: '${cartItem.quantity}', width: 2, styles: PosStyles(bold: true)),
          PosColumn(
              text: '${cartItem.product_name}',
              width: 10,
              containsChinese: true),
        ]);
        bytes += generator.reset();
        //product variant
        if(cartItem.productVariantName != ''){
          bytes += generator.row([
            PosColumn(text: '', width: 2),
            PosColumn(text: '(${cartItem.productVariantName})', width: 10, containsChinese: true)
          ]);
        }
        bytes += generator.reset();
        //product modifier
        if(cartItem.orderModifierDetail!.isNotEmpty) {
          for (int j = 0; j < cartItem.orderModifierDetail!.length; j++) {
            //modifier
            bytes += generator.row([
              PosColumn(text: '', width: 2),
              PosColumn(text: '+${cartItem.orderModifierDetail![j].mod_name}',
                  width: 10,
                  containsChinese: true,
                  styles: PosStyles(height: PosTextSize.size1, width: PosTextSize.size1))
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
            PosColumn(text: '**${cartItem.remark}', width: 8, containsChinese: true),
            PosColumn(text: '', width: 2),
          ]);
        }

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
  Cancellation layout 80mm
*/
  printDeleteItemList80mm(bool isUSB, String orderCacheId, String deleteDateTime, {value}) async {
    print('delete printer called');
    String dateTime = dateFormat.format(DateTime.now());
    await readSpecificOrderCache(orderCacheId, deleteDateTime);
    final prefs = await SharedPreferences.getInstance();
    final int? branch_id = prefs.getInt('branch_id');

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
        bytes += generator.text('CANCELLATION',
            styles: PosStyles(align: PosAlign.center, bold: true, fontType:PosFontType.fontA, underline: true, height: PosTextSize.size2, width: PosTextSize.size2));
        bytes += generator.emptyLines(1);
        bytes += generator.reset();
        //other order detail
        if(tableList.isNotEmpty){
          for(int i = 0; i < tableList.length; i++){
            bytes += generator.text('Table No: ${tableList[i].number}', styles: PosStyles(bold: true, align: PosAlign.center, height: PosTextSize.size2, width: PosTextSize.size2));
          }
        } else{
          bytes += generator.text('${orderCache!.dining_name}', styles: PosStyles(bold: true, align: PosAlign.center, height: PosTextSize.size2, width: PosTextSize.size2));
        }
        //order queue
        if(int.tryParse(orderCache!.order_queue!) != null) {
          bytes += generator.text('Order No: ${orderCache!.order_queue}', styles: PosStyles(bold: true, align: PosAlign.center, height: PosTextSize.size2, width: PosTextSize.size2));
        }
        bytes += generator.text('Batch No: #${orderCache!.batch_id}-${branch_id.toString().padLeft(3 ,'0')}', styles: PosStyles(align: PosAlign.center));
        bytes += generator.text('Cancel time: ${Utils.formatDate(dateTime)}', styles: PosStyles(align: PosAlign.center));
        bytes += generator.hr();
        bytes += generator.reset();
        /*
    *
    * body
    *
    * */
        //order product
        for(int i = 0; i < orderDetailList.length; i++){
          bytes += generator.reset();
          bytes += generator.row([
            PosColumn(
                text: '${orderDetailList[i].productName}',
                width: 8,
                containsChinese: true,
                styles: PosStyles(align: PosAlign.left, height: PosTextSize.size2, width: PosTextSize.size2, bold: true)),
            PosColumn(
                text: orderDetailList[i].unit != 'each' ?
                '-${(double.parse(orderDetailList[i].item_cancel!)*int.parse(orderDetailList[i].per_quantity_unit!)).toStringAsFixed(2)}${orderDetailList[i].unit}' :
                '-${orderDetailList[i].item_cancel}',
                width: 4,
                styles: PosStyles(align: PosAlign.right,  bold: true, height: PosTextSize.size2)),
          ]);
          bytes += generator.reset();
          if(orderDetailList[i].has_variant == '1'){
            bytes += generator.row([
              PosColumn(text: '(${orderDetailList[i].product_variant_name})', width: 10, containsChinese: true, styles: PosStyles(align: PosAlign.left, height: PosTextSize.size1, width: PosTextSize.size2)),
              PosColumn(text: '', width: 2, styles: PosStyles(align: PosAlign.right)),
            ]);
          }
          bytes += generator.reset();
          await getDeletedOrderModifierDetail(orderDetailList[i]);
          if(orderModifierDetailList.isNotEmpty){
            for(int j = 0; j < orderModifierDetailList.length; j++){
              //modifier
              bytes += generator.row([
                PosColumn(text: '+${orderModifierDetailList[j].mod_name}', width: 10, containsChinese: true, styles: PosStyles(align: PosAlign.left, height: PosTextSize.size1, width: PosTextSize.size2)),
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
              PosColumn(text: '**${orderDetailList[i].remark}', width: 10, containsChinese: true, styles: PosStyles(align: PosAlign.left, height: PosTextSize.size1, width: PosTextSize.size2)),
              PosColumn(text: '', width: 2),
            ]);
          }
          bytes += generator.hr();
          bytes += generator.text('cancel by: ${orderDetailList[i].cancel_by}', styles: PosStyles(align: PosAlign.center));
        }

        bytes += generator.cut(mode: PosCutMode.partial);
        return bytes;
      } catch (e) {
        print('layout error: $e');
        return null;
      }
    }
  }

/*
  Cancellation layout 58mm
*/
  printDeleteItemList58mm(bool isUSB, String orderCacheId, String deleteDateTime, {value}) async {
    String dateTime = dateFormat.format(DateTime.now());
    await readSpecificOrderCache(orderCacheId, deleteDateTime);
    final prefs = await SharedPreferences.getInstance();
    final int? branch_id = prefs.getInt('branch_id');

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
        bytes += generator.text('CANCELLATION',
            styles: PosStyles(align: PosAlign.center, bold: true, fontType:PosFontType.fontA, underline: true, height: PosTextSize.size2, width: PosTextSize.size2));
        bytes += generator.emptyLines(1);
        bytes += generator.reset();
        //other order detail
        if(tableList.isNotEmpty){
          for(int i = 0; i < tableList.length; i++){
            bytes += generator.text('Table No: ${tableList[i].number}', styles: PosStyles(bold: true, align: PosAlign.center, height: PosTextSize.size2, width: PosTextSize.size2));
          }
        } else{
          bytes += generator.text('${orderCache!.dining_name}', styles: PosStyles(bold: true, align: PosAlign.center, height: PosTextSize.size2, width: PosTextSize.size2));
        }
        bytes += generator.text('Batch No', styles: PosStyles(align: PosAlign.center));
        bytes += generator.text('#${orderCache!.batch_id}-${branch_id.toString().padLeft(3 ,'0')}', styles: PosStyles(align: PosAlign.center));
        bytes += generator.text('Cancel time', styles: PosStyles(align: PosAlign.center));
        bytes += generator.text('${Utils.formatDate(dateTime)}', styles: PosStyles(align: PosAlign.center));
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
            PosColumn(
                text: '${orderDetailList[i].productName}',
                width: 8,
                containsChinese: true,
                styles: PosStyles(bold: true)),
            PosColumn(text: orderDetailList[i].unit != 'each' ?
            '-${(double.parse(orderDetailList[i].item_cancel!)*int.parse(orderDetailList[i].per_quantity_unit!)).toStringAsFixed(2)}${orderDetailList[i].unit}' :
            '-${orderDetailList[i].item_cancel}',
                width: 4, styles: PosStyles(bold: true)),
          ]);
          bytes += generator.reset();
          if(orderDetailList[i].has_variant == '1'){
            bytes += generator.row([
              PosColumn(text: '(${Utils.formatProductVariant(orderDetailList[i].product_variant_name!)})', width: 10, containsChinese: true),
              PosColumn(text: '', width: 2),
            ]);
          }
          bytes += generator.reset();
          await getDeletedOrderModifierDetail(orderDetailList[i]);
          if(orderModifierDetailList.isNotEmpty){
            for(int j = 0; j < orderModifierDetailList.length; j++){
              //modifier
              bytes += generator.row([
                PosColumn(text: '+${orderModifierDetailList[j].mod_name}', width: 12, containsChinese: true),
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
          bytes += generator.hr();
          bytes += generator.text('cancel by: ${orderDetailList[i].cancel_by}', styles: PosStyles(align: PosAlign.center));
        }

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
  Cash balance layout 80mm (print when transfer ownership)
*/
  printCashBalanceList80mm(bool isUSB, String cashBalance, {value}) async {
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
        bytes += generator.text('Transfer time: ${Utils.formatDate(dateTime)}', styles: PosStyles(align: PosAlign.center));
        bytes += generator.hr();
        bytes += generator.reset();
        /*
    *
    * body
    *
    * */
        bytes += generator.row([
          PosColumn(text: 'REMARK', width: 6, styles: PosStyles(bold: true)),
          PosColumn(text: 'AMOUNT', width: 5, styles: PosStyles(bold: true, align: PosAlign.right)),
          PosColumn(text: '', width: 1, styles: PosStyles(bold: true, align: PosAlign.center)),
        ]);
        bytes += generator.hr();
        //order product
        bytes += generator.row([
          PosColumn(
              text: 'Cash Balance',
              width: 9,
              containsChinese: true,
              styles: PosStyles(align: PosAlign.left, height: PosTextSize.size1, width: PosTextSize.size1)),
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
  Cash balance layout 58mm (print when transfer ownership)
*/
  printCashBalanceList58mm(bool isUSB, String cashBalance, {value}) async {
    String dateTime = dateFormat.format(DateTime.now());
    final prefs = await SharedPreferences.getInstance();
    final String? user = prefs.getString('pos_pin_user');
    Map userObject = json.decode(user!);
    var generator;
    if (isUSB) {
      final profile = await CapabilityProfile.load();
      generator = Generator(PaperSize.mm58, profile);
    } else {
      generator = value;
    }

    List<int> bytes = [];
    try {
      bytes += generator.text('** CASH BALANCE LIST **', styles: PosStyles(align: PosAlign.center, width: PosTextSize.size2, height: PosTextSize.size2));
      bytes += generator.emptyLines(1);
      bytes += generator.reset();

      bytes += generator.text('Transfer to', styles: PosStyles(align: PosAlign.center));
      bytes += generator.text('${userObject['name']}', styles: PosStyles(align: PosAlign.center));
      bytes += generator.text('Transfer time', styles: PosStyles(align: PosAlign.center));
      bytes += generator.text('${Utils.formatDate(dateTime)}', styles: PosStyles(align: PosAlign.center));
      bytes += generator.hr();
      bytes += generator.reset();
      /*
    *
    * body
    *
    * */
      bytes += generator.row([
        PosColumn(text: 'REMARK', width: 3, styles: PosStyles(bold: true)),
        PosColumn(text: '', width: 6, styles: PosStyles(bold: true)),
        PosColumn(text: 'AMOUNT', width: 3, styles: PosStyles(bold: true)),
      ]);
      bytes += generator.hr();
      //order product
      bytes += generator.row([
        PosColumn(
            text: 'Cash Balance',
            width: 9,
            containsChinese: true,
            styles: PosStyles(height: PosTextSize.size1, width: PosTextSize.size1)),
        PosColumn(
            text: '${cashBalance}',
            width: 3)
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
  printSettlementList80mm(bool isUSB, String settlementDateTime, Settlement settlement, {value}) async {
    await getAllTodayOrderOverview(settlement);
    // await getBranchLinkDiningOption();
    await readPaymentLinkCompany(settlementDateTime, settlement);
    await calculateCashDrawerAmount(settlementDateTime, settlement);
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
        bytes += generator.text('** SETTLEMENT **', styles: PosStyles(align: PosAlign.center, width: PosTextSize.size2, height: PosTextSize.size2));
        bytes += generator.emptyLines(1);
        bytes += generator.reset();

        bytes += generator.text('Settlement By: ${settlement.settlement_by}', styles: PosStyles(align: PosAlign.center));
        bytes += generator.text('Settlement Time: ${Utils.formatDate(settlementDateTime)}', styles: PosStyles(align: PosAlign.center));
        bytes += generator.hr();
        bytes += generator.reset();
        /*
    *
    * body
    *
    * */bytes += generator.text('Payment Overview', styles: PosStyles(align: PosAlign.left, bold: true));
        bytes += generator.hr();
        bytes += generator.reset();
        bytes += generator.row([
          PosColumn(text: 'Payment Type', width: 6, styles: PosStyles(bold: true)),
          PosColumn(text: 'Amount', width: 5, styles: PosStyles(bold: true, align: PosAlign.right)),
          PosColumn(text: '', width: 1, styles: PosStyles(bold: true, align: PosAlign.center)),
        ]);
        bytes += generator.hr();
        //Payment link company
        for(int i = 0; i < paymentList.length; i++){
          if(paymentList[i].soft_delete == '' || (paymentList[i].soft_delete != '' && paymentList[i].totalAmount != 0.0)){
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
        }
        bytes += generator.hr();
        bytes += generator.text('Counter Overview', styles: PosStyles(align: PosAlign.left, bold: true));
        bytes += generator.hr();
        //Opening balance
        bytes += generator.row([
          PosColumn(text: '', width: 1, styles: PosStyles(align: PosAlign.left, bold: true)),
          PosColumn(
              text: 'Opening Balance',
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
              text: 'Cash In',
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
              text: 'Cash Out',
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
        bytes += generator.hr();
        bytes += generator.reset();
        // Expected total cash drawer
        bytes += generator.row([
          PosColumn(text: '', width: 1, styles: PosStyles(align: PosAlign.left, bold: true)),
          PosColumn(
              text: 'Expect Total Cash Drawer',
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
        bytes += generator.text('Order Overview', styles: PosStyles(align: PosAlign.left, bold: true));
        bytes += generator.hr();
        bytes += generator.reset();
        bytes += generator.row([
          PosColumn(text: '', width: 1, styles: PosStyles(align: PosAlign.left, bold: true)),
          PosColumn(
              text: 'Bills',
              width: 8,
              containsChinese: true,
              styles: PosStyles(align: PosAlign.left, height: PosTextSize.size2, width: PosTextSize.size1)),
          PosColumn(
              text: '${settlement.total_bill}',
              width: 2,
              styles: PosStyles(align: PosAlign.right)),
          PosColumn(
              text: '',
              width: 1,
              styles: PosStyles(align: PosAlign.right)),
        ]);
        bytes += generator.row([
          PosColumn(text: '', width: 1, styles: PosStyles(align: PosAlign.left, bold: true)),
          PosColumn(
              text: 'Sales',
              width: 8,
              containsChinese: true,
              styles: PosStyles(align: PosAlign.left, height: PosTextSize.size2, width: PosTextSize.size1)),
          PosColumn(
              text: '${settlement.total_sales}',
              width: 2,
              styles: PosStyles(align: PosAlign.right)),
          PosColumn(
              text: '',
              width: 1,
              styles: PosStyles(align: PosAlign.right)),
        ]);
        bytes += generator.row([
          PosColumn(text: '', width: 1, styles: PosStyles(align: PosAlign.left, bold: true)),
          PosColumn(
              text: 'Refund Bill',
              width: 8,
              containsChinese: true,
              styles: PosStyles(align: PosAlign.left, height: PosTextSize.size2, width: PosTextSize.size1)),
          PosColumn(
              text: '${'${settlement.total_refund_bill}'}',
              width: 2,
              styles: PosStyles(align: PosAlign.right)),
          PosColumn(
              text: '',
              width: 1,
              styles: PosStyles(align: PosAlign.right)),
        ]);
        bytes += generator.row([
          PosColumn(text: '', width: 1, styles: PosStyles(align: PosAlign.left, bold: true)),
          PosColumn(
              text: 'Refund Amount',
              width: 8,
              containsChinese: true,
              styles: PosStyles(align: PosAlign.left, height: PosTextSize.size2, width: PosTextSize.size1)),
          PosColumn(
              text: '${'${settlement.total_refund_amount}'}',
              width: 2,
              styles: PosStyles(align: PosAlign.right)),
          PosColumn(
              text: '',
              width: 1,
              styles: PosStyles(align: PosAlign.right)),
        ]);
        bytes += generator.row([
          PosColumn(text: '', width: 1, styles: PosStyles(align: PosAlign.left, bold: true)),
          PosColumn(
              text: 'Discount Amount',
              width: 8,
              containsChinese: true,
              styles: PosStyles(align: PosAlign.left, height: PosTextSize.size2, width: PosTextSize.size1)),
          PosColumn(
              text: '${'${settlement.total_discount}'}',
              width: 2,
              styles: PosStyles(align: PosAlign.right)),
          PosColumn(
              text: '',
              width: 1,
              styles: PosStyles(align: PosAlign.right)),
        ]);
        bytes += generator.row([
          PosColumn(text: '', width: 1, styles: PosStyles(align: PosAlign.left, bold: true)),
          PosColumn(
              text: 'Item Cancelled',
              width: 8,
              containsChinese: true,
              styles: PosStyles(align: PosAlign.left, height: PosTextSize.size2, width: PosTextSize.size1)),
          PosColumn(
              text: '${settlement.total_cancellation}',
              width: 2,
              styles: PosStyles(align: PosAlign.right)),
          PosColumn(
              text: '',
              width: 1,
              styles: PosStyles(align: PosAlign.right)),
        ]);
        bytes += generator.hr();
        if(orderTaxList.isNotEmpty){
          bytes += generator.text('Charges overview', styles: PosStyles(align: PosAlign.left, bold: true));
          bytes += generator.hr();
          bytes += generator.reset();
          for(int j = 0; j < orderTaxList.length; j++){
            bytes += generator.row([
              PosColumn(text: '', width: 1, styles: PosStyles(align: PosAlign.left, bold: true)),
              PosColumn(
                  text: '${orderTaxList[j].tax_name}',
                  width: 8,
                  containsChinese: true,
                  styles: PosStyles(align: PosAlign.left, height: PosTextSize.size2, width: PosTextSize.size1)),
              PosColumn(
                  text: '${orderTaxList[j].total_tax_amount!.toStringAsFixed(2)}',
                  width: 2,
                  styles: PosStyles(align: PosAlign.right)),
              PosColumn(
                  text: '',
                  width: 1,
                  styles: PosStyles(align: PosAlign.right)),
            ]);
          }
          bytes += generator.hr();
        }
        bytes += generator.text('Dining overview', styles: PosStyles(align: PosAlign.left, bold: true));
        bytes += generator.hr();
        bytes += generator.reset();
        for(int k = 0; k < orderList.length; k++){
          bytes += generator.row([
            PosColumn(text: '', width: 1, styles: PosStyles(align: PosAlign.left, bold: true)),
            PosColumn(
                text: '${orderList[k].dining_name}',
                width: 8,
                containsChinese: true,
                styles: PosStyles(align: PosAlign.left, height: PosTextSize.size2, width: PosTextSize.size1)),
            PosColumn(
                text: '${orderList[k].gross_sales!.toStringAsFixed(2)}',
                width: 2,
                styles: PosStyles(align: PosAlign.right)),
            PosColumn(
                text: '',
                width: 1,
                styles: PosStyles(align: PosAlign.right)),
          ]);
        }
        //final part
        bytes += generator.feed(1);
        bytes += generator.cut(mode: PosCutMode.partial);
        return bytes;
      } catch (e) {
        print('settlement print error: $e');
        return null;
      }
    }
  }

/*
  Settlement layout 58mm
*/
  printSettlementList58mm(bool isUSB, String settlementDateTime, Settlement settlement, {value}) async {
    await getAllTodayOrderOverview(settlement);
    // await getBranchLinkDiningOption();
    await readPaymentLinkCompany(settlementDateTime, settlement);
    await calculateCashDrawerAmount(settlementDateTime, settlement);
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
        bytes += generator.text('** SETTLEMENT **', styles: PosStyles(align: PosAlign.center, width: PosTextSize.size2, height: PosTextSize.size2));
        bytes += generator.emptyLines(1);
        bytes += generator.reset();

        bytes += generator.text('Settlement By: ${settlement.settlement_by}', styles: PosStyles(align: PosAlign.center));
        bytes += generator.text('Settlement Time: ${Utils.formatDate(settlementDateTime)}', styles: PosStyles(align: PosAlign.center));
        bytes += generator.hr();
        bytes += generator.reset();
        /*
    *
    * body
    *
    * */bytes += generator.text('Payment Overview', styles: PosStyles(align: PosAlign.left, bold: true));
        bytes += generator.hr();
        bytes += generator.reset();
        bytes += generator.row([
          PosColumn(text: 'Payment Type', width: 8, styles: PosStyles(bold: true)),
          PosColumn(text: 'Amount', width: 4, styles: PosStyles(bold: true)),
        ]);
        bytes += generator.hr();
        //Payment link company
        for(int i = 0; i < paymentList.length; i++){
          if(paymentList[i].soft_delete == '' || (paymentList[i].soft_delete != '' && paymentList[i].totalAmount != 0.0)){
            bytes += generator.row([
              PosColumn(
                  text: '${paymentList[i].name}',
                  width: 8,
                  containsChinese: true),
              PosColumn(
                  text: '${paymentList[i].totalAmount.toStringAsFixed(2)}',
                  width: 4)
            ]);
          }
        }
        bytes += generator.hr();
        bytes += generator.text('Counter Overview', styles: PosStyles(align: PosAlign.left, bold: true));
        bytes += generator.hr();
        //Opening balance
        bytes += generator.row([
          PosColumn(
              text: 'Opening Balance',
              width: 8,
              containsChinese: true),
          PosColumn(
              text: '${totalOpeningCash.toStringAsFixed(2)}',
              width: 4)
        ]);
        //cash in
        bytes += generator.row([
          PosColumn(
              text: 'Cash In',
              width: 8,
              containsChinese: true),
          PosColumn(
              text: '${totalCashIn.toStringAsFixed(2)}',
              width: 4),
        ]);
        //cash out
        bytes += generator.row([
          PosColumn(
              text: 'Cash Out',
              width: 8,
              containsChinese: true),
          PosColumn(
              text: '-${totalCashOut.toStringAsFixed(2)}',
              width: 4)
        ]);
        bytes += generator.hr();
        bytes += generator.reset();
        // Expected total cash drawer
        bytes += generator.row([
          PosColumn(
              text: 'Expect Total Cash Drawer',
              width: 8,
              containsChinese: true),
          PosColumn(
              text: '${totalCashBalance.toStringAsFixed(2)}',
              width: 4)
        ]);
        //total cash drawer
        bytes += generator.row([
          PosColumn(
              text: 'Total Cash Drawer',
              width: 8,
              containsChinese: true),
          PosColumn(
              text: '${totalCashBalance.toStringAsFixed(2)}',
              width: 4)
        ]);
        bytes += generator.hr();
        bytes += generator.text('Order Overview', styles: PosStyles(align: PosAlign.left, bold: true));
        bytes += generator.hr();
        bytes += generator.reset();
        bytes += generator.row([
          PosColumn(
              text: 'Bills',
              width: 8,
              containsChinese: true),
          PosColumn(
              text: '${settlement.total_bill}',
              width: 4)
        ]);
        bytes += generator.row([
          PosColumn(
              text: 'Sales',
              width: 8,
              containsChinese: true),
          PosColumn(
              text: '${settlement.total_sales}',
              width: 4)
        ]);
        bytes += generator.row([
          PosColumn(
              text: 'Refund Bill',
              width: 8,
              containsChinese: true),
          PosColumn(
              text: '${'${settlement.total_refund_bill}'}',
              width: 4)
        ]);
        bytes += generator.row([
          PosColumn(
              text: 'Refund Amount',
              width: 8,
              containsChinese: true),
          PosColumn(
              text: '${'${settlement.total_refund_amount}'}',
              width: 4)
        ]);
        bytes += generator.row([
          PosColumn(
              text: 'Discount Amount',
              width: 8,
              containsChinese: true),
          PosColumn(
              text: '${'${settlement.total_discount}'}',
              width: 4)
        ]);
        bytes += generator.row([
          PosColumn(
              text: 'Item Cancelled',
              width: 8,
              containsChinese: true),
          PosColumn(
              text: '${settlement.total_cancellation}',
              width: 4)
        ]);
        bytes += generator.hr();
        if(orderTaxList.isNotEmpty){
          bytes += generator.text('Charges overview', styles: PosStyles(align: PosAlign.left, bold: true));
          bytes += generator.hr();
          bytes += generator.reset();
          for(int j = 0; j < orderTaxList.length; j++){
            bytes += generator.row([
              PosColumn(text: '', width: 1, styles: PosStyles(align: PosAlign.left, bold: true)),
              PosColumn(
                  text: '${orderTaxList[j].tax_name}',
                  width: 8,
                  containsChinese: true),
              PosColumn(
                  text: '${orderTaxList[j].total_tax_amount!.toStringAsFixed(2)}',
                  width: 2),
              PosColumn(
                  text: '',
                  width: 1),
            ]);
          }
          bytes += generator.hr();
        }
        if(orderList.isNotEmpty){
          bytes += generator.text('Dining overview', styles: PosStyles(align: PosAlign.left, bold: true));
          bytes += generator.hr();
          bytes += generator.reset();
          for(int k = 0; k < orderList.length; k++){
            bytes += generator.row([
              PosColumn(
                  text: '${orderList[k].dining_name}',
                  width: 8,
                  containsChinese: true),
              PosColumn(
                  text: '${orderList[k].gross_sales!.toStringAsFixed(2)}',
                  width: 4),
            ]);
          }
        }
        //final part
        bytes += generator.feed(1);
        bytes += generator.cut(mode: PosCutMode.partial);
        return bytes;
      } catch (e) {
        print('settlement print error: $e');
        return null;
      }
    }
  }

/*
  Add table list layout 80mm
*/
  printAddTableList80mm(bool isUSB, {value, dragTable, targetTable}) async{
    String dateTime = dateFormat.format(DateTime.now());
    var generator;
    if (isUSB) {
      final profile = await CapabilityProfile.load();
      generator = Generator(PaperSize.mm80, profile);
    } else {
      generator = value;
    }

    List<int> bytes = [];
    try {
      bytes += generator.text('** Add Table **', styles: PosStyles(width: PosTextSize.size2, height: PosTextSize.size2, align: PosAlign.center));
      bytes += generator.emptyLines(1);
      bytes += generator.reset();

      bytes += generator.text('Printed At', styles: PosStyles(align: PosAlign.center));
      bytes += generator.text('${dateTime}', styles: PosStyles(align: PosAlign.center));
      bytes += generator.reset();
      /*
    *
    * body
    *
    * */
      bytes += generator.hr();
      bytes += generator.text('Table ${dragTable} Merge with Table ${targetTable}', styles: PosStyles(align: PosAlign.center, height: PosTextSize.size2, width: PosTextSize.size1));
      bytes += generator.reset();

      //final part
      bytes += generator.feed(2);
      bytes += generator.cut(mode: PosCutMode.partial);
      return bytes;
    } catch (e) {
      print('layout error: $e');
      return null;
    }

  }

  formatTableList(String tableList){
    String result = '';
    try{
      result = tableList.toString().replaceAll('[', '').replaceAll(']', '');
      return result;
    }catch(e){
      print("format table error");
      return result;
    }
  }

/*
  change table list layout 80mm
*/
  printChangeTableList80mm(bool isUSB, {value, fromTable, toTable}) async{
    String dateTime = dateFormat.format(DateTime.now());
    var generator;
    if (isUSB) {
      final profile = await CapabilityProfile.load();
      generator = Generator(PaperSize.mm80, profile);
    } else {
      generator = value;
    }

    List<int> bytes = [];
    try {
      bytes += generator.text('** Change Table **', styles: PosStyles(width: PosTextSize.size2, height: PosTextSize.size2, align: PosAlign.center));
      bytes += generator.emptyLines(1);
      bytes += generator.reset();

      bytes += generator.text('Printed At', styles: PosStyles(align: PosAlign.center));
      bytes += generator.text('${Utils.formatDate(dateTime)}', styles: PosStyles(align: PosAlign.center));
      bytes += generator.reset();
      /*
    *
    * body
    *
    * */
      bytes += generator.hr();
      bytes += generator.text('Table ${formatTableList(fromTable.toString())} change to Table ${toTable}', styles: PosStyles(align: PosAlign.center, height: PosTextSize.size2, width: PosTextSize.size1));
      bytes += generator.reset();

      //final part
      bytes += generator.feed(2);
      bytes += generator.cut(mode: PosCutMode.partial);
      return bytes;
    } catch (e) {
      print('layout error: $e');
      return null;
    }

  }

/*
  change table list layout 58mm
*/
  printChangeTableList58mm(bool isUSB, {value, fromTable, toTable}) async{
    String dateTime = dateFormat.format(DateTime.now());
    var generator;
    if (isUSB) {
      final profile = await CapabilityProfile.load();
      generator = Generator(PaperSize.mm58, profile);
    } else {
      generator = value;
    }

    List<int> bytes = [];
    try {
      bytes += generator.text('** Change Table **', styles: PosStyles(width: PosTextSize.size2, height: PosTextSize.size2, align: PosAlign.center));
      bytes += generator.emptyLines(1);
      bytes += generator.reset();

      bytes += generator.text('Printed At', styles: PosStyles(align: PosAlign.center));
      bytes += generator.text('${Utils.formatDate(dateTime)}', styles: PosStyles(align: PosAlign.center));
      bytes += generator.reset();
      /*
    *
    * body
    *
    * */
      bytes += generator.hr();
      bytes += generator.text('Table ${formatTableList(fromTable.toString())} change to Table ${toTable}',
          styles: PosStyles(align: PosAlign.center, height: PosTextSize.size2, width: PosTextSize.size1));
      bytes += generator.reset();

      //final part
      bytes += generator.feed(2);
      bytes += generator.cut(mode: PosCutMode.partial);
      return bytes;
    } catch (e) {
      print('layout error: $e');
      return null;
    }

  }

/*
  ----------------DB Query part------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
*/

/*
  read receipt layout
*/
  readReceiptLayout(String paperSize) async {
    Receipt? data = await PosDatabase.instance.readSpecificReceipt(paperSize);
    receipt = data;
  }

/*
  read branch latest order cache (auto print when place order click)
*/
  readOrderCache(int orderCacheId) async {
    final prefs = await SharedPreferences.getInstance();
    final int? branch_id = prefs.getInt('branch_id');
    OrderCache cacheData = await PosDatabase.instance.readSpecificOrderCacheByLocalId(orderCacheId);
    orderCache = cacheData;
    // if(orderCacheId != null){
    //
    // } else {
    //   // List<OrderCache> data = await PosDatabase.instance.readBranchLatestOrderCache(branch_id!);
    //   // orderCache = data[0];
    // }
    List<OrderDetail> detailData = await PosDatabase.instance.readTableOrderDetail(orderCache!.order_cache_key!);
    if(!detailData.contains(detailData)){
      orderDetailList = List.from(detailData);
    }
    List<TableUseDetail> detailData2 = await PosDatabase.instance.readAllTableUseDetail(orderCache!.table_use_sqlite_id!);
    for(int i = 0; i < detailData2.length; i++){
      List<PosTable> tableData = await PosDatabase.instance.readSpecificTable(detailData2[i].table_sqlite_id!);
      if(!tableList.contains(tableData)){
        tableList.add(tableData[0]);
      }
    }
    _isLoad = true;
  }

/*
  read specific order cache (reprint use)
*/
  readReprintOrderCache(String orderCacheId, int table_sqlite_id ) async {
    List<TableUseDetail> tableUseDetailData = await PosDatabase.instance.readSpecificTableUseDetail(table_sqlite_id);

    List<OrderCache> cacheData = await PosDatabase.instance.readTableOrderCache(tableUseDetailData[0].table_use_key!);
    for(int i = 0; i < cacheData.length; i++){
      this.orderCacheList.add(cacheData[i]);
      List<OrderDetail> detailData = await PosDatabase.instance.readTableOrderDetail(orderCacheList[i].order_cache_key!);
      if(!detailData.contains(detailData)){
        orderDetailList = List.from(detailData);
      }
    }
    //orderCache = cacheData[0];


    List<TableUseDetail> detailData2 = await PosDatabase.instance.readAllTableUseDetail(orderCache!.table_use_sqlite_id!);
    for(int i = 0; i < detailData2.length; i++){
      List<PosTable> tableData = await PosDatabase.instance.readSpecificTable(detailData2[i].table_sqlite_id!);
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

    List<OrderCache> cacheData  = await PosDatabase.instance.readSpecificDeletedOrderCache(int.parse(orderCacheId));
    orderCache = cacheData[0];
    print('order cache: ${orderCache!.order_cache_sqlite_id}');
    print('dateTime: ${dateTime}');
    List<OrderDetail> detailData = await PosDatabase.instance.readDeletedOrderDetail(orderCache!.order_cache_sqlite_id.toString());
    orderDetailList = List.from(detailData);
    print('order detail list: ${orderDetailList.length}');

    List<TableUseDetail> detailData2 = await PosDatabase.instance.readAllDeletedTableUseDetail(orderCache!.table_use_sqlite_id!);
    for(int i = 0; i < detailData2.length; i++){
      List<PosTable> tableData = await PosDatabase.instance.readSpecificTable(detailData2[i].table_sqlite_id!);
      if(!tableList.contains(tableData)){
        tableList.add(tableData[0]);
      }
    }
    _isLoad = true;
  }

  /*
  get paid order modifier detail
  */
  getDeletedOrderModifierDetail(OrderDetail orderDetail) async {
    List<OrderModifierDetail> modDetailData = await PosDatabase.instance.readDeletedOrderModifierDetail(orderDetail.order_detail_sqlite_id.toString());
    orderModifierDetailList = List.from(modDetailData);
  }

/*
  read All branch link dining option
*/
  getBranchLinkDiningOption() async {
    List<BranchLinkDining> data = await PosDatabase.instance.readAllBranchLinkDiningOption();
    if(data.isNotEmpty){
      branchLinkDiningList = List.from(data);
    }
    await sumAllDiningOrder();
  }

/*
  get all same dining id order
*/
  sumAllDiningOrder() async {
    List<Order> _orderList = [];
    List<Order> data = await PosDatabase.instance.readAllPaidOrder();
    if(data.isNotEmpty){
      _orderList = data;
      for (int j = 0; j < branchLinkDiningList.length; j++) {
        int _total = 0;
        for(int i = 0; i < _orderList.length; i++){
          if(branchLinkDiningList[j].dining_id == _orderList[i].dining_id){
            _total++;
          }
        }
        branchLinkDiningList[j].total_bill = _total;
      }
    }
  }

/*
  read all payment link company
*/
  readPaymentLinkCompany(String dateTime, Settlement settlement) async {
    final prefs = await SharedPreferences.getInstance();
    final String? user = prefs.getString('user');
    Map userObject = json.decode(user!);

    settlement_By = userObject['name'];
    List<PaymentLinkCompany> data = await PosDatabase.instance.readAllPaymentLinkCompanyWithDeleted(userObject['company_id']);
    print('data length: ${data.length}');
    if(data.isNotEmpty){
      paymentList = List.from(data);
    }
    await calculateTotalAmount(dateTime, settlement);
  }

/*
  calculate each payment link company total amount
*/
  calculateTotalAmount(String dateTime, Settlement settlement) async {
    final prefs = await SharedPreferences.getInstance();
    final int? branch_id = prefs.getInt('branch_id');

    try{
      for (int j = 0; j < paymentList.length; j++) {
        double total = 0.0;
        double totalRefund = 0.0;
        List<SettlementLinkPayment> data = await PosDatabase.instance.readSpecificSettlementLinkPaymentBySettlementKey(settlement.settlement_key!, paymentList[j].payment_link_company_id.toString());
        // List<CashRecord> data = await PosDatabase.instance.readSpecificSettlementCashRecord(branch_id.toString(), dateTime, settlement.settlement_key!);
        if(data.isNotEmpty){
          // for(int i = 0; i < data.length; i++){
          //   if(data[i].type == 3 && data[i].payment_type_id == paymentList[j].payment_type_id){
          //     total += double.parse(data[i].amount!);
          //   } else if(data[i].type == 4 && data[i].payment_type_id == paymentList[j].payment_type_id){
          //     totalRefund += double.parse(data[i].amount!);
          //   }
          //
          // }
          paymentList[j].totalAmount = data[0].all_payment_sales!;
        } else {
          paymentList[j].totalAmount = 0.0;
        }
      }
      _isLoad = true;
    }catch(e){
      print('Layout calculate total amount error: $e');
    }
  }

/*
  calculate cash drawer
*/
  calculateCashDrawerAmount(String dateTime, Settlement settlement) async {
    double _cashTotal = 0.0;
    double _cashRefund = 0.0;
    _isLoad = false;
    final prefs = await SharedPreferences.getInstance();
    final int? branch_id = prefs.getInt('branch_id');
    // double totalCashIn = 0.0;
    // double totalCashOut = 0.0;
    try{
      List<CashRecord> data = await PosDatabase.instance.readSpecificSettlementCashRecord(branch_id.toString(), dateTime, settlement.settlement_key!);
      for (int i = 0; i < data.length; i++) {
        if (data[i].type == 1 && data[i].payment_type_id == '') {
          totalCashIn += double.parse(data[i].amount!);
        } else if (data[i].type == 2 && data[i].payment_type_id == '') {
          totalCashOut += double.parse(data[i].amount!);
        } else if(data[i].type == 0 && data[i].payment_type_id == ''){
          totalOpeningCash = double.parse(data[i].amount!);
        } else if(data[i].type == 3 && data[i].payment_type_id == '1'){
          _cashTotal += double.parse(data[i].amount!);
        } else if(data[i].type == 4 && data[i].payment_type_id == '1'){
          _cashRefund += double.parse(data[i].amount!);
        }
      }
      totalCashBalance = (totalOpeningCash + totalCashIn + _cashTotal) - (totalCashOut + _cashRefund);
      _isLoad = true;
    }catch(e){
      print(e);
      totalCashBalance = 0.0;
    }
  }

/*
  settlement part
*/
  getAllTodayOrderOverview(Settlement settlement) async {
    List<OrderTaxDetail> data = await PosDatabase.instance.readAllSettlementOrderTaxDetailBySettlementKey(settlement.settlement_key!);
    List<Order> orderData = await PosDatabase.instance.readAllSettlementOrderBySettlementKey(settlement.settlement_key!);
    orderTaxList = data;
    orderList = orderData;


    // String currentStDate = new DateFormat("yyyy-MM-dd 00:00:00").format(DateTime.now());
    // ReportObject object = await ReportObject().getAllPaidOrder(currentStDate: currentStDate, currentEdDate: currentStDate);
    // ReportObject object2 = await ReportObject().getTotalCancelledItem(currentStDate: currentStDate, currentEdDate: currentStDate);
    // ReportObject object3 = await ReportObject().getAllRefundOrder(currentStDate: currentStDate, currentEdDate: currentStDate);
    // ReportObject object4 = await ReportObject().getAllPaidOrderPromotionDetail(currentStDate: currentStDate, currentEdDate: currentStDate);
    // ReportObject object5 = await ReportObject().getAllPaidOrderTaxDetail(currentStDate: currentStDate, currentEdDate: currentStDate);
    // reportObject = ReportObject(
    //     totalSales: object.totalSales,
    //     dateOrderList: object.dateOrderList,
    //     dateOrderDetailCancelList: object2.dateOrderDetailCancelList,
    //     totalRefundAmount: object3.totalRefundAmount,
    //     dateRefundOrderList: object3.dateRefundOrderList,
    //     totalPromotionAmount: object4.totalPromotionAmount,
    //     branchTaxList: object5.branchTaxList
    // );
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

    for(int p = 0; p < orderPromotionList.length; p++){
      this.totalPromotion += double.parse(orderPromotionList[p].promotion_amount!);
    }
    print('total promotion: ${this.totalPromotion}');
  }

/*
  read specific paid order
*/
  getPaidOrder(String localOrderId) async {
    List<Order> orderData = await PosDatabase.instance.readSpecificPaidOrder(localOrderId);
    paidOrder = orderData[0];
    _isLoad = false;
  }

/*
  read specific refund order
*/
  getRefundOrder(String localOrderId) async {
    List<Order> orderData = await PosDatabase.instance.readSpecificRefundOrder(localOrderId);
    paidOrder = orderData[0];
    _isLoad = false;
  }

  callRefundOrderDetail(String localOrderId) async {
    await getOrderCache(localOrderId);
    for(int i = 0; i < paidOrderCacheList.length; i++){
      await getOrderDetail(paidOrderCacheList[i]);
      await getTableList(paidOrderCacheList[i]);
    }
    _isLoad = true;
  }

  callPaidOrderDetail(String localOrderId) async {
    await getOrderCache(localOrderId);
    for(int i = 0; i < paidOrderCacheList.length; i++){
      await getOrderDetail(paidOrderCacheList[i]);
      await getTableList(paidOrderCacheList[i]);
    }
    _isLoad = true;
  }

/*
  read paid order cache
*/
  getOrderCache(String localOrderId) async {
    List<OrderCache> cacheData = await PosDatabase.instance.readSpecificOrderCacheByOrderID(localOrderId);
    if(cacheData.isNotEmpty){
      paidOrderCacheList = List.from(cacheData);
    }
  }

/*
  read table use detail
*/
  getTableList(OrderCache paidCache) async {
    List<TableUseDetail> detailData2 = await PosDatabase.instance.readAllDeletedTableUseDetail(paidCache.table_use_sqlite_id!);
    for(int i = 0; i < detailData2.length; i++){
      List<PosTable> tableData = await PosDatabase.instance.readSpecificTable(detailData2[i].table_sqlite_id!);
      if(!tableList.contains(tableData)){
        tableList.add(tableData[0]);
      }
    }
  }

/*
  read paid order cache detail
*/
  getOrderDetail(OrderCache orderCache) async {

    List<OrderDetail> detailData = await PosDatabase.instance.readSpecificOrderDetailByOrderCacheId(orderCache.order_cache_sqlite_id.toString());
    if(detailData.isNotEmpty){
      for(int i = 0; i < detailData.length; i++){
        if(!orderDetailList.contains(detailData[i])){
          orderDetailList.add(detailData[i]);
        }
      }
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

bool productNameDisplayOrder(List<OrderDetail> orderDetailList, int i, int paperSize) {
  int productNameWidth = 0;
  String productUnitPrice = '';
  if(orderDetailList[i].unit != '')
    productUnitPrice = ' (${orderDetailList[i].price}/${orderDetailList[i].per_quantity_unit}${orderDetailList[i].unit})';
  else
    productUnitPrice = ' (${orderDetailList[i].price}/each)';

  int productNameSpaceConsumed = calculateSpaceConsumed(orderDetailList[i].productName!);

  if(paperSize == 80)
    productNameWidth = 26;
  else
    productNameWidth = 14;

  if(productNameSpaceConsumed + productUnitPrice.length > productNameWidth)
    return true;
  else
    return false;
}

bool productNameDisplayCart(List<cartProductItem> cartNotifierItem, int i, int paperSize) {
  int productNameWidth = 0;
  String productUnitPrice = '(${cartNotifierItem[i].price}/${cartNotifierItem[i].per_quantity_unit}${cartNotifierItem[i].unit})';
  int productNameSpaceConsumed = calculateSpaceConsumed(cartNotifierItem[i].product_name!);

  if(paperSize == 80)
    productNameWidth = 26;
  else
    productNameWidth = 14;

  if(productNameSpaceConsumed + productUnitPrice.length > productNameWidth)
    return true;
  else
    return false;
}

int calculateSpaceConsumed(String text) {
  int spaceCount = 0;

  for (int i = 0; i < text.length; i++) {
    if (isChineseCharacter(text[i]) || isSpecialSymbol(text[i])) {
      spaceCount += 2;
    } else {
      spaceCount += 1;
    }
  }
  return spaceCount;
}

bool isChineseCharacter(String character) {
  final chinesePattern = RegExp(r'[\u4e00-\u9fa5]');
  return chinesePattern.hasMatch(character);
}
bool isSpecialSymbol(String character) {
  final specialSymbolPattern = RegExp(r'[！￥（）—：《》？【】、；。，]');
  return specialSymbolPattern.hasMatch(character);
}