import 'package:f_logs/model/flog/flog.dart';
import 'package:pos_system/fragment/printing_layout/receipt_layout.dart';
import 'package:pos_system/object/cancel_receipt.dart';
import 'package:esc_pos_utils/esc_pos_utils.dart';
import 'package:pos_system/object/order_detail.dart';

import '../../../utils/Utils.dart';

class CancelReceiptLayout extends ReceiptLayout {
  final _defaultCancelReceiptLayout = Utils.defaultCancelReceiptLayout();

  Future<List<int>> printCancelReceipt80mm(bool isUSB, String orderCacheId, String deleteDateTime, {value}) async {
    String dateTime = dateFormat.format(DateTime.now());
    await readSpecificOrderCache(orderCacheId, deleteDateTime);
    var cancelReceipt = await posDatabase.readSpecificCancelReceiptByPaperSize('80') ?? _defaultCancelReceiptLayout;
    var generator;
    if (isUSB) {
      final profile = await CapabilityProfile.load();
      generator = Generator(PaperSize.mm80, profile);
    } else {
      generator = value;
    }

    List<int> bytes = [];
    try {
      PosFontType productFontType = cancelReceipt.product_name_font_size == 1 ? PosFontType.fontB : PosFontType.fontA;
      PosFontType otherFontType = cancelReceipt.other_font_size == 1 ? PosFontType.fontB : PosFontType.fontA;
      PosTextSize productFontSize = cancelReceipt.product_name_font_size == 2 ? PosTextSize.size1 : PosTextSize.size2;
      PosTextSize otherFontSize = cancelReceipt.other_font_size == 2 ? PosTextSize.size1 : PosTextSize.size2;

      bytes += generator.text('CANCELLATION',
          styles: PosStyles(
              align: PosAlign.center,
              bold: true,
              fontType:PosFontType.fontA,
              reverse: true,
              height: PosTextSize.size2, width: PosTextSize.size2));
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
      if(int.tryParse(orderCache!.order_queue!) != null) {
        bytes += generator.text('Order No: ${orderCache!.order_queue}', styles: PosStyles(bold: true, align: PosAlign.center, height: PosTextSize.size2, width: PosTextSize.size2));
      }
      bytes += generator.text('Batch No: #${orderCache!.batch_id}-${orderCache!.branch_id.toString().padLeft(3 ,'0')}', styles: PosStyles(align: PosAlign.center));
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
              text: getProductName(cancelReceipt, orderDetailList[i]),
              width: 8,
              containsChinese: true,
              styles: PosStyles(fontType: productFontType,
                height: productFontSize,
                width: productFontSize,
              ),
          ),
          PosColumn(
              text: getProductUnit(cancelReceipt, orderDetailList[i]),
              width: 4,
              styles: PosStyles(
                  align: PosAlign.right,
                  fontType: productFontType,
                  height: productFontSize,
                  width: productFontSize,
              ),
          ),
        ]);
        bytes += generator.reset();
        if(orderDetailList[i].has_variant == '1'){
          bytes += generator.row([
            PosColumn(
              text: '(${orderDetailList[i].product_variant_name})',
              width: 10,
              containsChinese: true,
              styles: PosStyles(
                fontType: otherFontType,
                height: otherFontSize,
                width: otherFontSize,
              ),
            ),
            PosColumn(text: '', width: 2, styles: PosStyles(align: PosAlign.right)),
          ]);
        }
        bytes += generator.reset();
        await getDeletedOrderModifierDetail(orderDetailList[i]);
        if(orderModifierDetailList.isNotEmpty){
          for(int j = 0; j < orderModifierDetailList.length; j++){
            //modifier
            bytes += generator.row([
              PosColumn(
                text: '+${orderModifierDetailList[j].mod_name}',
                width: 10,
                containsChinese: true,
                styles: PosStyles(
                  fontType: otherFontType,
                  height: otherFontSize,
                  width: otherFontSize,
                ),
              ),
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
            PosColumn(
              text: '**${orderDetailList[i].remark}',
              width: 10,
              containsChinese: true,
              styles: PosStyles(
                fontType: otherFontType,
                height: otherFontSize,
                width: otherFontSize,
              ),
            ),
            PosColumn(text: '', width: 2),
          ]);
        }
        bytes += generator.hr();
        bytes += generator.text('cancel by: ${orderDetailList[i].cancel_by}', containsChinese: true, styles: PosStyles(align: PosAlign.center));
      }

      bytes += generator.cut(mode: PosCutMode.partial);
      return bytes;
    } catch (e, stackTrace) {
      FLog.error(
        className: "cancel_receipt/layout",
        text: "printCancelReceipt80mm error",
        exception: "Error: $e, StackTrace: $stackTrace",
      );
      rethrow;
    }
  }

  printCancelReceipt58mm(bool isUSB, String orderCacheId, String deleteDateTime, {value}) async {
    String dateTime = dateFormat.format(DateTime.now());
    await readSpecificOrderCache(orderCacheId, deleteDateTime);
    var cancelReceipt = await posDatabase.readSpecificCancelReceiptByPaperSize('58') ?? _defaultCancelReceiptLayout;
    var generator;
    if (isUSB) {
      final profile = await CapabilityProfile.load();
      generator = Generator(PaperSize.mm58, profile);
    } else {
      generator = value;
    }

    List<int> bytes = [];
    try {
      PosFontType productFontType = cancelReceipt.product_name_font_size == 1 ? PosFontType.fontB : PosFontType.fontA;
      PosFontType otherFontType = cancelReceipt.other_font_size == 1 ? PosFontType.fontB : PosFontType.fontA;
      PosTextSize productFontSize = cancelReceipt.product_name_font_size == 2 ? PosTextSize.size1 : PosTextSize.size2;
      PosTextSize otherFontSize = cancelReceipt.other_font_size == 2 ? PosTextSize.size1 : PosTextSize.size2;

      bytes += generator.text('CANCELLATION',
          styles: PosStyles(
              align: PosAlign.center,
              bold: true,
              fontType:PosFontType.fontA,
              reverse: true,
              height: PosTextSize.size2, width: PosTextSize.size2));
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
      bytes += generator.text('Batch No: #${orderCache!.batch_id}-${orderCache!.branch_id.toString().padLeft(3 ,'0')}', styles: PosStyles(align: PosAlign.center));
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
            text: getProductName(cancelReceipt, orderDetailList[i]),
            width: 8,
            containsChinese: true,
            styles: PosStyles(
              fontType: productFontType,
              height: productFontSize,
              width: productFontSize,
            ),
          ),
          PosColumn(
            text: getProductUnit(cancelReceipt, orderDetailList[i]),
            width: 4,
            styles: PosStyles(
              fontType: productFontType,
              height: productFontSize,
              width: productFontSize,
            ),
          ),
        ]);
        bytes += generator.reset();
        if(orderDetailList[i].has_variant == '1'){
          bytes += generator.row([
            PosColumn(
              text: '(${orderDetailList[i].product_variant_name})',
              width: 10,
              containsChinese: true,
              styles: PosStyles(
                fontType: otherFontType,
                height: otherFontSize,
                width: otherFontSize,
              ),
            ),
            PosColumn(text: '', width: 2),
          ]);
        }
        bytes += generator.reset();
        await getDeletedOrderModifierDetail(orderDetailList[i]);
        if(orderModifierDetailList.isNotEmpty){
          for(int j = 0; j < orderModifierDetailList.length; j++){
            //modifier
            bytes += generator.row([
              PosColumn(
                text: '+${orderModifierDetailList[j].mod_name}',
                width: 10,
                containsChinese: true,
                styles: PosStyles(
                  fontType: otherFontType,
                  height: otherFontSize,
                  width: otherFontSize,
                ),
              ),
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
            PosColumn(
              text: '**${orderDetailList[i].remark}',
              width: 10,
              containsChinese: true,
              styles: PosStyles(
                fontType: otherFontType,
                height: otherFontSize,
                width: otherFontSize,
              ),
            ),
            PosColumn(text: '', width: 2),
          ]);
        }
        bytes += generator.hr();
        bytes += generator.text('cancel by: ${orderDetailList[i].cancel_by}', containsChinese: true, styles: PosStyles(align: PosAlign.center));
      }

      bytes += generator.cut(mode: PosCutMode.partial);
      return bytes;
    } catch (e, stackTrace) {
      FLog.error(
        className: "cancel_receipt/layout",
        text: "printCancelReceipt58mm error",
        exception: "Error: $e, StackTrace: $stackTrace",
      );
      rethrow;
    }
  }


  Future<List<int>> testPrint80mmFormat({value, required CancelReceipt cancelReceipt, required bool isUSB}) async {
    var generator;
    if (isUSB) {
      final profile = await CapabilityProfile.load();
      generator = Generator(PaperSize.mm80, profile);
    } else {
      generator = value;
    }
    OrderDetail orderDetail = OrderDetail(
      productName: 'Product 1',
      product_sku: 'SKU001',
      price: 'RM6.90'
    );
    PosFontType productFontType = cancelReceipt.product_name_font_size == 1 ? PosFontType.fontB : PosFontType.fontA;
    PosFontType otherFontType = cancelReceipt.other_font_size == 1 ? PosFontType.fontB : PosFontType.fontA;
    PosTextSize productFontSize = cancelReceipt.product_name_font_size == 2 ? PosTextSize.size1 : PosTextSize.size2;
    PosTextSize otherFontSize = cancelReceipt.other_font_size == 2 ? PosTextSize.size1 : PosTextSize.size2;
    List<int> bytes = [];
    try{
      bytes += generator.reset();
      bytes += generator.text('CANCELLATION',
          styles: PosStyles(
              align: PosAlign.center,
              bold: true,
              fontType:PosFontType.fontA,
              reverse: true,
              height: PosTextSize.size2, width: PosTextSize.size2));
      bytes += generator.emptyLines(1);
      bytes += generator.text('Table No: 5', styles: PosStyles(bold: true, align: PosAlign.center, height: PosTextSize.size2, width: PosTextSize.size2));
      bytes += generator.text('Batch No: #123456-005', styles: PosStyles(align: PosAlign.center));
      bytes += generator.text('Cancel time: DD/MM/YY hh:mm PM', styles: PosStyles(align: PosAlign.center));
      bytes += generator.hr();
      bytes += generator.reset();
      bytes += generator.row([
        PosColumn(
            text: getProductName(cancelReceipt, orderDetail),
            width: 10,
            containsChinese: true,
            styles: PosStyles(
                fontType: productFontType,
                height: productFontSize,
                width: productFontSize,
            ),
        ),
        PosColumn(
            text: '-1',
            width: 2,
            styles: PosStyles(
                align: PosAlign.right,
                fontType: productFontType,
                height: productFontSize,
                width: productFontSize),
        ),
      ]);
      bytes += generator.reset();
      bytes += generator.row([
        PosColumn(
            text: '(big | small)',
            width: 10,
            containsChinese: true,
            styles: PosStyles(
              fontType: otherFontType,
              height: otherFontSize,
              width: otherFontSize,
            ),
        ),
        PosColumn(
          text: '',
          width: 2,
          styles: PosStyles(
              align: PosAlign.right,
              fontType: productFontType,
              height: productFontSize,
              width: productFontSize),
        ),
      ]);
      bytes += generator.reset();
      bytes += generator.row([
        PosColumn(
            text: '+Spicy',
            width: 10,
            containsChinese: true,
            styles: PosStyles(
              fontType: otherFontType,
              height: otherFontSize,
              width: otherFontSize,
            ),
        ),
        PosColumn(
          text: '',
          width: 2,
          styles: PosStyles(
              align: PosAlign.right,
              fontType: productFontType,
              height: productFontSize,
              width: productFontSize),
        )
      ]);
      bytes += generator.row([
        PosColumn(
          text: '**Remark',
          width: 10,
          containsChinese: true,
          styles: PosStyles(
            fontType: otherFontType,
            height: otherFontSize,
            width: otherFontSize,
          ),
        ),
        PosColumn(
          text: '',
          width: 2,
          styles: PosStyles(
              align: PosAlign.right,
              fontType: productFontType,
              height: productFontSize,
              width: productFontSize),
        )
      ]);
      bytes += generator.reset();
      bytes += generator.hr();
      bytes += generator.text('cancel by: Optimy', containsChinese: true, styles: PosStyles(align: PosAlign.center));
      bytes += generator.cut(mode: PosCutMode.partial);
      return bytes;
    }catch(e){
      print("format error: $e");
      return [];
    }
  }

  Future<List<int>> testPrint58mmFormat({value, required CancelReceipt cancelReceipt, required bool isUSB}) async {
    var generator;
    if (isUSB) {
      final profile = await CapabilityProfile.load();
      generator = Generator(PaperSize.mm58, profile);
    } else {
      generator = value;
    }
    OrderDetail orderDetail = OrderDetail(
        productName: 'Product 1',
        product_sku: 'SKU001',
        price: 'RM6.90'
    );
    PosFontType productFontType = cancelReceipt.product_name_font_size == 1 ? PosFontType.fontB : PosFontType.fontA;
    PosFontType otherFontType = cancelReceipt.other_font_size == 1 ? PosFontType.fontB : PosFontType.fontA;
    PosTextSize productFontSize = cancelReceipt.product_name_font_size == 2 ? PosTextSize.size1 : PosTextSize.size2;
    PosTextSize otherFontSize = cancelReceipt.other_font_size == 2 ? PosTextSize.size1 : PosTextSize.size2;
    List<int> bytes = [];
    try{
      bytes += generator.reset();
      bytes += generator.text('CANCELLATION',
          styles: PosStyles(
              align: PosAlign.center,
              bold: true,
              fontType:PosFontType.fontA,
              reverse: true,
              height: PosTextSize.size2, width: PosTextSize.size2));
      bytes += generator.emptyLines(1);
      bytes += generator.text('Table No: 5', styles: PosStyles(bold: true, align: PosAlign.center, height: PosTextSize.size2, width: PosTextSize.size2));
      bytes += generator.text('Batch No: #123456-005', styles: PosStyles(align: PosAlign.center));
      bytes += generator.text('Cancel time: DD/MM/YY hh:mm PM', styles: PosStyles(align: PosAlign.center));
      bytes += generator.hr();
      bytes += generator.reset();
      bytes += generator.row([
        PosColumn(
          text: getProductName(cancelReceipt, orderDetail),
          width: 10,
          containsChinese: true,
          styles: PosStyles(
            fontType: productFontType,
            height: productFontSize,
            width: productFontSize,
          ),
        ),
        PosColumn(
          text: '-1',
          width: 2,
          styles: PosStyles(
            fontType: productFontType,
            height: productFontSize,
            width: productFontSize,
          ),
        ),
      ]);
      bytes += generator.reset();
      bytes += generator.row([
        PosColumn(
          text: '(big | small)',
          width: 10,
          containsChinese: true,
          styles: PosStyles(
            fontType: otherFontType,
            height: otherFontSize,
            width: otherFontSize,
          ),
        ),
        PosColumn(
          text: '',
          width: 2,
          styles: PosStyles(
            fontType: productFontType,
            height: productFontSize,
            width: productFontSize,
          ),
        ),
      ]);
      bytes += generator.reset();
      bytes += generator.row([
        PosColumn(
          text: '+Spicy',
          width: 10,
          containsChinese: true,
          styles: PosStyles(
            fontType: otherFontType,
            height: otherFontSize,
            width: otherFontSize,
          ),
        ),
        PosColumn(
          text: '',
          width: 2,
          styles: PosStyles(
            fontType: productFontType,
            height: productFontSize,
            width: productFontSize,
          ),
        )
      ]);
      bytes += generator.row([
        PosColumn(
          text: '**Remark',
          width: 10,
          containsChinese: true,
          styles: PosStyles(
            fontType: otherFontType,
            height: otherFontSize,
            width: otherFontSize,
          ),
        ),
        PosColumn(
          text: '',
          width: 2,
          styles: PosStyles(
            fontType: productFontType,
            height: productFontSize,
            width: productFontSize,
          ),
        )
      ]);
      bytes += generator.reset();
      bytes += generator.hr();
      bytes += generator.text('cancel by: Optimy', containsChinese: true, styles: PosStyles(align: PosAlign.center));
      bytes += generator.cut(mode: PosCutMode.partial);
      return bytes;
    }catch(e){
      print("format error: $e");
      return [];
    }
  }

  getProductName(CancelReceipt cancelReceipt, OrderDetail orderDetail){
    if(cancelReceipt.show_product_price == 0 && cancelReceipt.show_product_sku == 0){
      return orderDetail.productName;
    } else {
      if(cancelReceipt.show_product_price == 1 && cancelReceipt.show_product_sku == 1){
        return '${orderDetail.product_sku} ${orderDetail.productName}(${orderDetail.price})';
      } else if (cancelReceipt.show_product_sku == 1) {
        return '${orderDetail.product_sku}${orderDetail.productName}';
      } else {
        return '${orderDetail.productName}(${orderDetail.price})';
      }
    }
  }

  getProductUnit(CancelReceipt cancelReceipt, OrderDetail orderDetail){
    if(orderDetail.unit != 'each' && orderDetail.unit != 'each_c'){
      return '-${(double.parse(orderDetail.item_cancel!)*int.parse(orderDetail.per_quantity_unit!)).toStringAsFixed(2)}${orderDetail.unit}';
    } else {
      return '-${orderDetail.item_cancel}';
    }
  }
}
