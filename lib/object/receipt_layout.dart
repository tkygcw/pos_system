

import 'package:esc_pos_utils/esc_pos_utils.dart';
import 'package:intl/intl.dart';
import 'package:pos_system/database/pos_database.dart';
import 'package:pos_system/object/receipt.dart';

class ReceiptLayout{
  PaperSize? size;
  Receipt? receipt;
  DateFormat dateFormat = DateFormat("yyyy-MM-dd HH:mm:ss");


  readReceiptLayout() async {
    List<Receipt> data = await PosDatabase.instance.readAllReceipt();
    for(int i = 0; i < data.length; i++){
      if(data[i].status == 1){
        receipt = data[i];
      }
    }
  }

  testTicket(int paperSize, bool isUSB, {value}) async {
    String dateTime = dateFormat.format(DateTime.now());
    await readReceiptLayout();

    if(paperSize == 0){
      size = PaperSize.mm80;
    } else {
      size = PaperSize.mm58;
    }
    var generator;
    if (isUSB) {
      final profile = await CapabilityProfile.load();
      generator = Generator(size!, profile);
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
            text: 'Nasi kandar' + '(big,white)',
            width: 6,
            containsChinese: true,
            styles: PosStyles(align: PosAlign.left, bold: true)),
        PosColumn(text: '1', width: 2, styles: PosStyles(align: PosAlign.right)),
        PosColumn(
            text: '11.00',
            width: 4,
            styles: PosStyles(align: PosAlign.right)),
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
            text: 'Nasi Lemak' + '(big,white)',
            width: 6,
            containsChinese: true,
            styles: PosStyles(align: PosAlign.left, bold: true)),
        PosColumn(text: '1', width: 2, styles: PosStyles(align: PosAlign.right)),
        PosColumn(
            text: '11.00',
            width: 4,
            styles: PosStyles(align: PosAlign.right)),
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

}