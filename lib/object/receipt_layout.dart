import 'dart:convert';

import 'package:esc_pos_utils/esc_pos_utils.dart';
import 'package:flutter/material.dart';
import 'package:imin/imin.dart';
import 'package:intl/intl.dart';
import 'package:pos_system/database/pos_database.dart';
import 'package:pos_system/object/cash_record.dart';
import 'package:pos_system/object/order_cache.dart';
import 'package:pos_system/object/order_detail.dart';
import 'package:pos_system/object/payment_link_company.dart';
import 'package:pos_system/object/receipt.dart';
import 'package:pos_system/object/table.dart';
import 'package:pos_system/object/table_use_detail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ReceiptLayout{
  PaperSize? size;
  Receipt? receipt;
  OrderCache? orderCache;
  List<OrderDetail> orderDetailList = [];
  List<PosTable> tableList = [];
  List<PaymentLinkCompany> paymentList = [];
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
  void _openDrawer () {
    Imin.openDrawer();
  }

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
  ----------------Receipt layout part------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
*/

/*
  test print layout 80mm
*/
  testTicket80mm(bool isUSB, value) async {
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
  printReceipt80mm(int paperSize, bool isUSB, {value}) async {
    String dateTime = dateFormat.format(DateTime.now());
    await readReceiptLayout();

    var generator;
    if (isUSB) {
      final profile = await CapabilityProfile.load();
      generator = Generator(PaperSize.mm80, profile);
    } else {
      generator = value;
    }

    List<int> bytes = [];
    try {
      bytes += generator.text('${receipt!.header_text}', styles: PosStyles(bold: true, align: PosAlign.center, height: PosTextSize.size3, width: PosTextSize.size3));
      bytes += generator.emptyLines(1);
      bytes += generator.reset();
      //Address
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
      //other order detail
      bytes += generator.text('${dateTime}');
      bytes += generator.text('Table No: 5');
      bytes += generator.text('Dine in');
      bytes += generator.text('Close by: Taylor');
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
      bytes += generator.row([
        PosColumn(
            text: 'Nasi kandar',
            width: 6,
            containsChinese: true,
            styles: PosStyles(align: PosAlign.left, bold: true)),
        PosColumn(text: '1', width: 2, styles: PosStyles(align: PosAlign.right)),
        PosColumn(
            text: '11.00',
            width: 4,
            styles: PosStyles(align: PosAlign.right)),
      ]);
      bytes += generator.row([
        PosColumn(text: '(big,white)', width: 6, containsChinese: true),
        PosColumn(text: '', width: 2, styles: PosStyles(align: PosAlign.right)),
        PosColumn(text: '', width: 4, styles: PosStyles(align: PosAlign.right)),
      ]);
      bytes += generator.emptyLines(1);
      bytes += generator.row([
        PosColumn(
            text: 'Nasi Ayam',
            width: 6,
            containsChinese: true,
            styles: PosStyles(align: PosAlign.left, bold: true)),
        PosColumn(text: '1', width: 2, styles: PosStyles(align: PosAlign.right)),
        PosColumn(
            text: '9.90',
            width: 4,
            styles: PosStyles(align: PosAlign.right)),
      ]);
      bytes += generator.row([
        PosColumn(text: '-Modifier(2.00)', width: 6, containsChinese: true),
        PosColumn(text: '', width: 2, styles: PosStyles(align: PosAlign.right)),
        PosColumn(text: '', width: 4, styles: PosStyles(align: PosAlign.right)),
      ]);
      bytes += generator.emptyLines(1);
      /*
        * product with remark
        * */
      bytes += generator.row([
        PosColumn(
            text: 'Nasi Lemak' + '',
            width: 6,
            containsChinese: true,
            styles: PosStyles(align: PosAlign.left, bold: true)),
        PosColumn(text: '1', width: 2, styles: PosStyles(align: PosAlign.right)),
        PosColumn(
            text: '11.00',
            width: 4,
            styles: PosStyles(align: PosAlign.right)),
      ]);
      bytes += generator.row([
        PosColumn(text: '(big,white)', width: 6, containsChinese: true),
        PosColumn(text: '', width: 2, styles: PosStyles(align: PosAlign.right)),
        PosColumn(text: '', width: 4, styles: PosStyles(align: PosAlign.right)),
      ]);
      bytes += generator.reset();
      bytes += generator.row([
        PosColumn(text: '**remark here', width: 6, containsChinese: true),
        PosColumn(text: '', width: 2, styles: PosStyles(align: PosAlign.right)),
        PosColumn(text: '', width: 4, styles: PosStyles(align: PosAlign.right)),
      ]);
      bytes += generator.hr();
      bytes += generator.reset();
      //item count
      bytes += generator.text('Items count: 3', styles: PosStyles(bold: true));
      bytes += generator.hr();
      bytes += generator.reset();
      //total calc
      bytes += generator.row([
        PosColumn(text: 'SubTotal', width: 8, styles: PosStyles(align: PosAlign.right)),
        PosColumn(text: '33.70', width: 4, styles: PosStyles(align: PosAlign.right)),
      ]);
      //discount
      bytes += generator.row([
        PosColumn(text: 'discount(-)', width: 8, styles: PosStyles(align: PosAlign.right)),
        PosColumn(text: '-0.00', width: 4, styles: PosStyles(align: PosAlign.right)),
      ]);
      //tax
      bytes += generator.row([
        PosColumn(text: 'Service Tax(-)', width: 8, styles: PosStyles(align: PosAlign.right)),
        PosColumn(text: '0.00', width: 4, styles: PosStyles(align: PosAlign.right)),
      ]);
      //payment method
      bytes += generator.row([
        PosColumn(text: 'Payment method', width: 8, styles: PosStyles(align: PosAlign.right)),
        PosColumn(text: 'Cash', width: 4, styles: PosStyles(align: PosAlign.right)),
      ]);
      //total
      bytes += generator.hr();
      bytes += generator.row([
        PosColumn(text: 'Total', width: 8, styles: PosStyles(align: PosAlign.right, height: PosTextSize.size2, bold: true)),
        PosColumn(
            text: '33.70',
            width: 4,
            styles: PosStyles(align: PosAlign.right, height: PosTextSize.size2, bold: true)),
      ]);
      bytes += generator.hr();
      bytes += generator.emptyLines(1);
      //footer
      bytes += generator.text('${receipt!.footer_text}', styles: PosStyles(bold: true, align: PosAlign.center, height: PosTextSize.size3, width: PosTextSize.size3));

      bytes += generator.feed(1);
      bytes += generator.cut(mode: PosCutMode.partial);
      return bytes;
    } catch ($e) {
      return null;
    }
  }

/*
  Check list layout 80mm
*/
  printCheckList80mm(bool isUSB, value) async {
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
        } else {
          bytes += generator.row([
            PosColumn(text: '', width: 2),
            PosColumn(text: '+Modifier', width: 8, styles: PosStyles(align: PosAlign.left)),
            PosColumn(text: '    ', width: 2, styles: PosStyles(align: PosAlign.right)),
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
        bytes += generator.emptyLines(1);
      }

      // bytes += generator.row([
      //   PosColumn(text: '1', width: 2, styles: PosStyles(align: PosAlign.left, bold: true)),
      //   PosColumn(
      //       text: 'Nasi Lemak',
      //       width: 8,
      //       containsChinese: true,
      //       styles: PosStyles(align: PosAlign.left, height: PosTextSize.size2, width: PosTextSize.size1)),
      //   PosColumn(
      //       text: '[   ]',
      //       width: 2,
      //       styles: PosStyles(align: PosAlign.right)),
      // ]);
      // bytes += generator.reset();
      // bytes += generator.row([
      //   PosColumn(text: '', width: 2),
      //   PosColumn(text: '+Modifier', width: 8, styles: PosStyles(align: PosAlign.left)),
      //   PosColumn(text: '', width: 2, styles: PosStyles(align: PosAlign.right)),
      // ]);
      // bytes += generator.emptyLines(1);
      // bytes += generator.row([
      //   PosColumn(text: '1', width: 2, styles: PosStyles(align: PosAlign.left, bold: true)),
      //   PosColumn(
      //       text: 'French fries',
      //       width: 8,
      //       containsChinese: true,
      //       styles: PosStyles(align: PosAlign.left, height: PosTextSize.size2, width: PosTextSize.size1)),
      //   PosColumn(
      //       text: '[   ]',
      //       width: 2,
      //       styles: PosStyles(align: PosAlign.right)),
      // ]);
      // bytes += generator.reset();
      // bytes += generator.row([
      //   PosColumn(text: '', width: 2),
      //   PosColumn(text: '**Remark', width: 8, styles: PosStyles(align: PosAlign.left)),
      //   PosColumn(text: '', width: 2, styles: PosStyles(align: PosAlign.right)),
      // ]);

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
  printKitchenList80mm(bool isUSB, value) async {
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
      bytes += generator.text('** kitchen list **', styles: PosStyles(align: PosAlign.center, width: PosTextSize.size2, height: PosTextSize.size2));
      bytes += generator.emptyLines(1);
      bytes += generator.reset();
      //other order detail
      for(int i = 0; i < tableList.length; i++){
        bytes += generator.text('Table No: ${tableList[i].number}', styles: PosStyles(bold: true, align: PosAlign.center, height: PosTextSize.size2, width: PosTextSize.size2));
      }
      bytes += generator.text('order No: #${orderCache!.batch_id}', styles: PosStyles(align: PosAlign.center));
      bytes += generator.text('order time: ${dateTime}', styles: PosStyles(align: PosAlign.center));
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
  printSettlementList80mm(bool isUSB, value, String settlementDateTime) async {
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
}