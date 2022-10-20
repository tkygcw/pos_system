

import 'package:esc_pos_utils/esc_pos_utils.dart';
import 'package:intl/intl.dart';
import 'package:pos_system/database/pos_database.dart';
import 'package:pos_system/object/receipt.dart';

class ReceiptLayout{
  PaperSize? size;
  Receipt? receipt;
  final dateFormat = DateFormat("dd/MM/yyyy");
  final timeFormat = DateFormat("hh:mm a");


  readReceiptLayout() async {
    List<Receipt> data = await PosDatabase.instance.readAllReceipt();
    for(int i = 0; i < data.length; i++){
      if(data[i].status == 1){
        receipt = data[i];
      }
    }
  }

  testTicket(int paperSize, bool isUSB, {value}) async {

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
      bytes += generator.hr(ch: '-');
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
      //receipt no
      bytes += generator.emptyLines(1);
      bytes += generator.text('Receipt No.: 17-200-000056',
          styles: PosStyles(
              align: PosAlign.left,
              width: PosTextSize.size1,
              height: PosTextSize.size1,
              bold: true));
      bytes += generator.reset();
      //other order detail
      bytes += generator.text('2022-10-03 17:18:18');
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
            text: 'Nasi kandar' + ' (big, white) ',
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
        PosColumn(text: '-Modifier(RM2.00)', width: 6, containsChinese: true),
        PosColumn(text: '', width: 2, styles: PosStyles(align: PosAlign.right)),
        PosColumn(text: '', width: 4, styles: PosStyles(align: PosAlign.right)),
      ]);
      bytes += generator.reset();
      bytes += generator.hr(ch: '-');
      bytes += generator.reset();
      //item count
      bytes += generator.text('Items count: 1');
      bytes += generator.emptyLines(1);
      bytes += generator.reset();
      //total calc
      bytes += generator.row([
        PosColumn(
            text: 'Subtotal:',
            width: 8,
            styles: PosStyles(align: PosAlign.left)),
        PosColumn(
            text: 'RM20.90', width: 4, styles: PosStyles(align: PosAlign.right))
      ]);
      bytes += generator.row([
        PosColumn(
            text: 'Service Tax(10%):',
            width: 8,
            styles: PosStyles(align: PosAlign.left)),
        PosColumn(
            text: 'RM2.09', width: 4, styles: PosStyles(align: PosAlign.right))
      ]);
      bytes += generator.reset();
      //total
      bytes += generator.row([
        PosColumn(
            text: 'TOTAL:',
            width: 8,
            styles: PosStyles(align: PosAlign.left, bold: true)),
        PosColumn(
            text: 'RM22.99',
            width: 4,
            styles: PosStyles(align: PosAlign.right, bold: true))
      ]);
      bytes += generator.text('${receipt!.footer_text}', styles: PosStyles(bold: true, align: PosAlign.center, height: PosTextSize.size3, width: PosTextSize.size3));

      bytes += generator.feed(1);
      bytes += generator.cut(mode: PosCutMode.partial);
      return bytes;
    } catch ($e) {
      return null;
    }
  }

}