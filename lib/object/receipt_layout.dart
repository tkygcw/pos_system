import 'package:esc_pos_utils/esc_pos_utils.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pos_system/database/pos_database.dart';
import 'package:pos_system/object/order_cache.dart';
import 'package:pos_system/object/order_detail.dart';
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
  DateFormat dateFormat = DateFormat("yyyy-MM-dd HH:mm:ss");


  readReceiptLayout() async {
    List<Receipt> data = await PosDatabase.instance.readAllReceipt();
    for(int i = 0; i < data.length; i++){
      if(data[i].status == 1){
        receipt = data[i];
      }
    }
  }

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

}