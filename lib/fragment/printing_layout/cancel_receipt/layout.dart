import 'package:pos_system/object/cancel_receipt.dart';
import 'package:esc_pos_utils/esc_pos_utils.dart';
import 'package:pos_system/object/order_detail.dart';

class CancelReceiptLayout {
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
          styles: PosStyles(align: PosAlign.center, bold: true, fontType:PosFontType.fontA, underline: true, height: PosTextSize.size2, width: PosTextSize.size2));
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
    PosFontType productFontType = cancelReceipt.product_name_font_size == 2 ? PosFontType.fontB : PosFontType.fontA;
    PosFontType otherFontType = cancelReceipt.other_font_size == 2 ? PosFontType.fontB : PosFontType.fontA;
    PosTextSize productFontSize = cancelReceipt.product_name_font_size == 1 ? PosTextSize.size1 : PosTextSize.size2;
    PosTextSize otherFontSize = cancelReceipt.other_font_size == 1 ? PosTextSize.size1 : PosTextSize.size2;
    List<int> bytes = [];
    try{
      bytes += generator.reset();
      bytes += generator.text('CANCELLATION',
          styles: PosStyles(align: PosAlign.center, bold: true, fontType:PosFontType.fontA, underline: true, height: PosTextSize.size2, width: PosTextSize.size2));
      bytes += generator.emptyLines(1);
      bytes += generator.text('Table No: 5', styles: PosStyles(bold: true, align: PosAlign.center, height: PosTextSize.size2, width: PosTextSize.size2));
      bytes += generator.text('Batch No: #123456-005', styles: PosStyles(align: PosAlign.center));
      bytes += generator.text('Cancel time: DD/MM/YY hh:mm PM', styles: PosStyles(align: PosAlign.center));
      bytes += generator.hr();
      bytes += generator.reset();
      bytes += generator.row([
        PosColumn(
          text: getProductName(cancelReceipt, orderDetail),
          width: 8,
          containsChinese: true,
          styles: PosStyles(
              fontType: productFontType,
              align: PosAlign.left,
              height: productFontSize,
              width: productFontSize,
          ),
        ),
        PosColumn(
            text: '-1',
            width: 4,
            styles: PosStyles(align: PosAlign.right,  bold: true, height: PosTextSize.size2)),
      ]);
      bytes += generator.reset();
      bytes += generator.row([
        PosColumn(text: '(big | small)', width: 10, containsChinese: true, styles: PosStyles(align: PosAlign.left, height: PosTextSize.size1, width: PosTextSize.size2)),
        PosColumn(
            text: '', width: 2, styles: PosStyles(align: PosAlign.right,
          fontType: otherFontType,
          height: otherFontSize,
          width: otherFontSize,
        )),
      ]);
      bytes += generator.reset();
      bytes += generator.row([
        PosColumn(text: '+Spicy', width: 10, containsChinese: true, styles: PosStyles(align: PosAlign.left, height: PosTextSize.size1, width: PosTextSize.size2)),
        PosColumn(text: '', width: 2, styles: PosStyles(
          align: PosAlign.right,
          fontType: otherFontType,
          height: otherFontSize,
          width: otherFontSize,
        )),
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
}