import 'dart:convert';

import 'package:esc_pos_utils/esc_pos_utils.dart';
import 'package:pos_system/utils/Utils.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../notifier/report_notifier.dart';

class ModifierReceiptLayout {

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
      bytes += generator.text('Modifier Sales', containsChinese: true, styles: PosStyles(align: PosAlign.center, bold: true));
      bytes += generator.text('${model.startDateTime2} - ${model.endDateTime2}', containsChinese: true, styles: PosStyles(align: PosAlign.center));
      bytes += generator.text('Generated At', containsChinese: true, styles: PosStyles(align: PosAlign.center, bold: true));
      bytes += generator.text(Utils.formatReportDate(DateTime.now().toString()), containsChinese: true, styles: PosStyles(align: PosAlign.center));
      bytes += generator.hr();

      bytes += generator.row([
        PosColumn(text: 'Group ', width: 6, styles: PosStyles(bold: true, align: PosAlign.left)),
        PosColumn(text: 'Qty', width: 2, styles: PosStyles(bold: true)),
        PosColumn(text: 'Amount', width: 4, styles: PosStyles(bold: true, align: PosAlign.right)),
      ]);
      bytes += generator.hr();

      bytes += generator.reset();
      for(final modGroup in model.reportValue2){
        bytes += generator.row([
          PosColumn(text: modGroup.name, width: 6, containsChinese: true, styles: PosStyles(bold: true)),
          PosColumn(text: 'Qty', width: 2, styles: PosStyles(bold: true)),
          PosColumn(text: 'Total', width: 4, styles: PosStyles(align: PosAlign.right, bold: true)),
        ]);
        for(final modItem in modGroup.modDetailList){
          bytes += generator.row([
            PosColumn(text: modItem.mod_name, width: 6, containsChinese: true),
            PosColumn(text: modItem.item_sum.toString(), width: 2),
            PosColumn(text: Utils.to2Decimal(modItem.net_sales), width: 4, styles: PosStyles(align: PosAlign.right)),
          ]);
        }
        bytes += generator.hr();
        bytes += generator.row([
          PosColumn(text: 'Subtotal', width: 6, styles: PosStyles(bold: true)),
          PosColumn(text: modGroup.item_sum.toString(), width: 2, styles: PosStyles(bold: true)),
          PosColumn(text: Utils.to2Decimal(modGroup.net_sales), width: 4, styles: PosStyles(align: PosAlign.right, bold: true)),
        ]);
        bytes += generator.hr();
      }
      bytes += generator.row([
        PosColumn(text: 'Grand total', width: 6, styles: PosStyles(bold: true)),
        PosColumn(text: getTotalQty(), width: 2, styles: PosStyles(bold: true)),
        PosColumn(text: getTotalAmount(), width: 4, styles: PosStyles(bold: true, align: PosAlign.right)),
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
      bytes += generator.text('Modifier Sales', containsChinese: true, styles: PosStyles(align: PosAlign.center, bold: true));
      bytes += generator.text('${model.startDateTime2} - ${model.endDateTime2}', containsChinese: true, styles: PosStyles(align: PosAlign.center));
      bytes += generator.text('Generated At', containsChinese: true, styles: PosStyles(align: PosAlign.center, bold: true));
      bytes += generator.text(Utils.formatReportDate(DateTime.now().toString()), containsChinese: true, styles: PosStyles(align: PosAlign.center));
      bytes += generator.hr();

      bytes += generator.row([
        PosColumn(text: 'Group ', width: 6, styles: PosStyles(bold: true)),
        PosColumn(text: 'Qty', width: 2, styles: PosStyles(bold: true)),
        PosColumn(text: 'Amount', width: 4, styles: PosStyles(bold: true)),
      ]);
      bytes += generator.hr();

      bytes += generator.reset();
      for(final modGroup in model.reportValue2){
        bytes += generator.row([
          PosColumn(text: modGroup.name, width: 6, containsChinese: true, styles: PosStyles(bold: true)),
          PosColumn(text: 'Qty', width: 2, styles: PosStyles(bold: true)),
          PosColumn(text: 'Total', width: 4, styles: PosStyles(bold: true)),
        ]);
        for(final modItem in modGroup.modDetailList){
          bytes += generator.row([
            PosColumn(text: modItem.mod_name, width: 6, containsChinese: true),
            PosColumn(text: modItem.item_sum.toString(), width: 2),
            PosColumn(text: Utils.to2Decimal(modItem.net_sales), width: 4),
          ]);
        }
        bytes += generator.hr();
        bytes += generator.row([
          PosColumn(text: 'Subtotal', width: 6, styles: PosStyles(bold: true)),
          PosColumn(text: modGroup.item_sum.toString(), width: 2, styles: PosStyles(bold: true)),
          PosColumn(text: Utils.to2Decimal(modGroup.net_sales), width: 4, styles: PosStyles(bold: true)),
        ]);
        bytes += generator.hr();
      }
      bytes += generator.row([
        PosColumn(text: 'Grand total', width: 6, styles: PosStyles(bold: true)),
        PosColumn(text: getTotalQty(), width: 2, styles: PosStyles(bold: true)),
        PosColumn(text: getTotalAmount(), width: 4, styles: PosStyles(bold: true)),
      ]);
      bytes += generator.hr();
      bytes += generator.cut(mode: PosCutMode.partial);
      return bytes;

    }catch(e){
      print("format error: $e");
      return [];
    }
  }

  getTotalAmount(){
    if(ReportModel.instance.reportValue2.isNotEmpty){
      final list = ReportModel.instance.reportValue2.map((e) => e.net_sales).toList();
      return Utils.to2Decimal(list.reduce((a, b) => a + b));
    } else {
      return '-';
    }
  }

  getTotalQty(){
    if(ReportModel.instance.reportValue2.isNotEmpty){
      final list = ReportModel.instance.reportValue2.map((e) => e.item_sum).toList();
      return list.reduce((a, b) => a + b).toString();
    }else {
      return '-';
    }
  }
}