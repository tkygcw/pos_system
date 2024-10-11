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

  String getProductVariant(record){
    if(record.product_variant_name != null && record.product_variant_name != ''){
      return '${record.product_variant_name}';
    } else {
      return '';
    }
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
        PosColumn(text: 'Product', width: 8, containsChinese: true, styles: PosStyles(bold: true)),
        PosColumn(text: 'Qty', width: 2, styles: PosStyles(bold: true)),
        PosColumn(text: 'Total', width: 2, styles: PosStyles(bold: true)),
      ]);
      bytes += generator.hr();
      for(final record in model.reportValue2){
        bytes += generator.reset();
        bytes += generator.row([
          PosColumn(text: record.product_name, width: 8, containsChinese: true, styles: PosStyles()),
          PosColumn(text: getProductQty(record), width: 2, styles: PosStyles()),
          PosColumn(text: Utils.to2Decimal(record.price!), width: 2, styles: PosStyles()),
        ]);
        if(record.product_variant_name != null && record.product_variant_name != ''){
          bytes += generator.row([
            PosColumn(text: getProductVariant(record), width: 12, containsChinese: true, styles: PosStyles()),
          ]);
        }
        bytes += generator.row([
          PosColumn(text: 'By: ${record.cancel_by}', width: 12, containsChinese: true, styles: PosStyles()),
        ]);
        bytes += generator.row([
          PosColumn(text: 'Reason: ${record.cancel_reason}', width: 12, containsChinese: true, styles: PosStyles()),
        ]);

        bytes += generator.hr();
      }
      bytes += generator.row([
        PosColumn(text: 'Subtotal', width: 8, styles: PosStyles(bold: true)),
        PosColumn(text: model.reportValue2.first.total_item.toString(), width: 2, styles: PosStyles(bold: true)),
        PosColumn(text: model.reportValue2.first.total_amount!.toStringAsFixed(2), width: 2, styles: PosStyles(bold: true)),
      ]);
      bytes += generator.reset();
      bytes += generator.row([
        PosColumn(text: 'Grand total', width: 8, styles: PosStyles(bold: true)),
        PosColumn(text: model.reportValue2.first.total_item.toString(), width: 2, styles: PosStyles(bold: true)),
        PosColumn(text: model.reportValue2.first.total_amount!.toStringAsFixed(2), width: 2, styles: PosStyles(bold: true)),
      ]);
      bytes += generator.hr();
      bytes += generator.cut(mode: PosCutMode.partial);
      return bytes;

    }catch(e){
      print("format error: $e");
      return [];
    }
  }

  Future<List<int>> print58mmFormat(bool isUSB, {value}) async {
    final prefs = await SharedPreferences.getInstance();
    final String? branch = prefs.getString('branch');
    Map branchObject = json.decode(branch!);
    ReportModel model = ReportModel.instance;
    var generator;
    if (isUSB) {
      final profile = await CapabilityProfile.load();
      generator = Generator(PaperSize.mm58, profile);
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
        PosColumn(text: 'Product', width: 8, containsChinese: true, styles: PosStyles(bold: true)),
        PosColumn(text: 'Qty', width: 2, styles: PosStyles(bold: true)),
        PosColumn(text: 'Total', width: 2, styles: PosStyles(bold: true)),
      ]);
      bytes += generator.hr();
      for(final record in model.reportValue2){
        bytes += generator.reset();
        bytes += generator.row([
          PosColumn(text: record.product_name, width: 8, containsChinese: true, styles: PosStyles()),
          PosColumn(text: getProductQty(record), width: 2, styles: PosStyles()),
          PosColumn(text: Utils.to2Decimal(record.price!), width: 2, styles: PosStyles()),
        ]);
        if(record.product_variant_name != null && record.product_variant_name != ''){
          bytes += generator.row([
            PosColumn(text: getProductVariant(record), width: 12, containsChinese: true, styles: PosStyles()),
          ]);
        }
        bytes += generator.row([
          PosColumn(text: 'By: ${record.cancel_by}', width: 12, containsChinese: true, styles: PosStyles()),
        ]);
        bytes += generator.row([
          PosColumn(text: 'Reason: ${record.cancel_reason}', width: 12, containsChinese: true, styles: PosStyles()),
        ]);

        bytes += generator.hr();
      }
      bytes += generator.row([
        PosColumn(text: 'Subtotal', width: 8, styles: PosStyles(bold: true)),
        PosColumn(text: model.reportValue2.first.total_item.toString(), width: 2, styles: PosStyles(bold: true)),
        PosColumn(text: model.reportValue2.first.total_amount!.toStringAsFixed(2), width: 2, styles: PosStyles(bold: true)),
      ]);
      bytes += generator.reset();
      bytes += generator.row([
        PosColumn(text: 'Grand total', width: 8, styles: PosStyles(bold: true)),
        PosColumn(text: model.reportValue2.first.total_item.toString(), width: 2, styles: PosStyles(bold: true)),
        PosColumn(text: model.reportValue2.first.total_amount!.toStringAsFixed(2), width: 2, styles: PosStyles(bold: true)),
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