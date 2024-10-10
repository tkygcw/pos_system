import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:esc_pos_utils/esc_pos_utils.dart';

import '../../../../notifier/report_notifier.dart';
import '../../../../utils/Utils.dart';

class CancelRecordLayout {

  String getProductQty(record){
    if(record.unit == 'each' || record.unit == 'each_c'){
      return record.quantity!;
    } else {
      return '${record.quantity!}(${record.quantity_before_cancel!})';
    }
  }

  String getCancelRecordDetail(record){
    return '${record.product_name}\n'
        '${record.product_variant_name!}\n'
        '${Utils.formatDate(record.created_at!)}\n'
        '${record.cancel_by}\n'
        '${record.cancel_reason}';
  }

  Future<List<int>> print80mmFormat(bool isUSB, {value}) async {
    final prefs = await SharedPreferences.getInstance();
    final String? branch = prefs.getString('branch');
    Map branchObject = json.decode(branch!);
    ReportModel model = ReportModel.instance;
    var generator;
    if (isUSB) {
      final profile = await CapabilityProfile.load();
      generator = Generator(PaperSize.mm80, profile);
    } else {
      generator = value;
    }

    List<int> bytes = [];
    try{
      bytes += generator.reset();
      bytes += generator.row([
        PosColumn(
            text: '${branchObject['name']}',
            width: 12,
            containsChinese: true,
            styles: PosStyles(align: PosAlign.center, bold: true)),
      ]);
      bytes += generator.emptyLines(1);
      if(branchObject['address'] != ''){
        bytes += generator.text('${branchObject['address']}', containsChinese: true, styles: PosStyles(align: PosAlign.center));
      }
      bytes += generator.hr();
      bytes += generator.text('Cancel Record', containsChinese: true, styles: PosStyles(align: PosAlign.center, bold: true));
      bytes += generator.text('${model.startDateTime2} - ${model.endDateTime2}', containsChinese: true, styles: PosStyles(align: PosAlign.center));
      bytes += generator.text('Generated At', containsChinese: true, styles: PosStyles(align: PosAlign.center, bold: true));
      bytes += generator.text(Utils.formatReportDate(DateTime.now().toString()), containsChinese: true, styles: PosStyles(align: PosAlign.center));
      bytes += generator.hr();
      bytes += generator.reset();
      bytes += generator.row([
        PosColumn(text: 'Product', width: 8, containsChinese: true, styles: PosStyles(bold: true, fontType: PosFontType.fontA)),
        PosColumn(text: 'Qty', width: 2, styles: PosStyles(bold: true)),
        PosColumn(text: 'Total', width: 2, styles: PosStyles(bold: true, align: PosAlign.right)),
      ]);
      bytes += generator.hr();
      for(final record in model.reportValue2){
        bytes += generator.reset();
        bytes += generator.row([
          PosColumn(text: getCancelRecordDetail(record), width: 8, containsChinese: true, styles: PosStyles()),
          // PosColumn(text: getProductVariant(orderDetail), width: 3, containsChinese: true, styles: PosStyles(fontType: PosFontType.fontB)),
          PosColumn(text: getProductQty(record), width: 2, styles: PosStyles(fontType: PosFontType.fontB)),
          PosColumn(text: Utils.to2Decimal(record.price!), width: 2, styles: PosStyles(align: PosAlign.right, fontType: PosFontType.fontA)),
        ]);
      }
      bytes += generator.hr();
      bytes += generator.row([
        PosColumn(text: 'Subtotal', width: 5, styles: PosStyles(bold: true)),
        PosColumn(text: ' ', width: 3, styles: PosStyles(bold: true)),
        PosColumn(text: model.reportValue2.first.total_item.toString(), width: 2, styles: PosStyles(bold: true)),
        PosColumn(text: model.reportValue2.first.total_amount!.toStringAsFixed(2), width: 2, styles: PosStyles(align: PosAlign.right, bold: true)),
      ]);
      bytes += generator.hr();
      bytes += generator.reset();
      bytes += generator.row([
        PosColumn(text: 'Grand total', width: 5, styles: PosStyles(bold: true)),
        PosColumn(text: ' ', width: 3, styles: PosStyles(bold: true)),
        PosColumn(text: model.reportValue2.first.total_item.toString(), width: 2, styles: PosStyles(bold: true)),
        PosColumn(text: model.reportValue2.first.total_amount!.toStringAsFixed(2), width: 2, styles: PosStyles(bold: true, align: PosAlign.right)),
      ]);
      bytes += generator.hr();
      bytes += generator.cut(mode: PosCutMode.partial);
      return bytes;

    }catch(e){
      print("format error: $e");
      return [];
    }
  }
}