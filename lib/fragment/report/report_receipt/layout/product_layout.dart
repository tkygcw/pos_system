import 'dart:convert';

import 'package:esc_pos_utils/esc_pos_utils.dart';
import 'package:pos_system/utils/Utils.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../notifier/report_notifier.dart';

class ProductReceiptLayout {

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
      bytes += generator.text('Product Sales', containsChinese: true, styles: PosStyles(align: PosAlign.center, bold: true));
      bytes += generator.text('${model.startDateTime2} - ${model.endDateTime2}', containsChinese: true, styles: PosStyles(align: PosAlign.center));
      bytes += generator.text('Generated At', containsChinese: true, styles: PosStyles(align: PosAlign.center, bold: true));
      bytes += generator.text(Utils.formatReportDate(DateTime.now().toString()), containsChinese: true, styles: PosStyles(align: PosAlign.center));
      bytes += generator.hr();
      bytes += generator.reset();
      for(final category in model.reportValue2){
        bytes += generator.row([
          PosColumn(text: getCategoryName(category), width: 6, styles: PosStyles(bold: true, align: PosAlign.left)),
          PosColumn(text: 'Variant', width: 3, styles: PosStyles(bold: true)),
          PosColumn(text: 'Qty', width: 1, styles: PosStyles(bold: true)),
          PosColumn(text: 'Amount', width: 2, styles: PosStyles(bold: true, align: PosAlign.right)),
        ]);
        bytes += generator.reset();
        for(final orderDetail in category.categoryOrderDetailList){
          bytes += generator.row([
            PosColumn(text: orderDetail.productName, width: 6, containsChinese: true, styles: PosStyles(bold: true, align: PosAlign.left)),
            PosColumn(text: getProductVariant(orderDetail), width: 3, styles: PosStyles(bold: true)),
            PosColumn(text: getProductQty(orderDetail), width: 1, styles: PosStyles(bold: true)),
            PosColumn(text: Utils.to2Decimal(orderDetail.gross_price!), width: 2, styles: PosStyles(bold: true, align: PosAlign.right)),
          ]);
        }
        bytes += generator.hr();
      }
      bytes += generator.row([
        PosColumn(text: 'Grand total', width: 5, styles: PosStyles(bold: true)),
        PosColumn(text: getTotalQty(), width: 3, styles: PosStyles(bold: true)),
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
      bytes += generator.text('Category Sales', containsChinese: true, styles: PosStyles(align: PosAlign.center, bold: true));
      bytes += generator.text('${model.startDateTime2} - ${model.endDateTime2}', containsChinese: true, styles: PosStyles(align: PosAlign.center));
      bytes += generator.text('Generated At', containsChinese: true, styles: PosStyles(align: PosAlign.center, bold: true));
      bytes += generator.text(Utils.formatReportDate(DateTime.now().toString()), containsChinese: true, styles: PosStyles(align: PosAlign.center));
      bytes += generator.hr();
      bytes += generator.row([
        PosColumn(text: 'Category ', width: 5, styles: PosStyles(bold: true)),
        PosColumn(text: 'Qty', width: 3, styles: PosStyles(bold: true)),
        PosColumn(text: 'Amount', width: 4, styles: PosStyles(bold: true)),
      ]);
      bytes += generator.reset();
      for(final detail in model.reportValue2){
        bytes += generator.row([
          PosColumn(text: getCategoryName(detail), width: 5),
          PosColumn(text: detail.category_item_sum.toString(), width: 3),
          PosColumn(text: Utils.to2Decimal(detail.category_gross_sales!), width: 4),
        ]);
      }
      bytes += generator.hr();
      bytes += generator.row([
        PosColumn(text: 'Grand total', width: 5, styles: PosStyles(bold: true)),
        PosColumn(text: getTotalQty(), width: 3, styles: PosStyles(bold: true)),
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

  getProductQty(orderDetail){
    if(orderDetail.item_sum is double){
       return '${orderDetail.item_qty}/${orderDetail.item_sum}(${orderDetail.unit})';
    } else {
      return '${orderDetail.item_sum}';
    }
  }

  getProductVariant(orderDetail){
    if(orderDetail.product_variant_name != ''){
      return orderDetail.product_variant_name;
    } else {
      return '-';
    }
  }

  getTotalAmount(){
    if(ReportModel.instance.reportValue2.isNotEmpty){
      final list = ReportModel.instance.reportValue2.map((e) => e.category_gross_sales!).toList();
      return Utils.to2Decimal(list.reduce((a, b) => a + b));
    } else {
      return '-';
    }
  }

  getTotalQty(){
    if(ReportModel.instance.reportValue2.isNotEmpty){
      final list = ReportModel.instance.reportValue2.map((e) => e.category_item_sum).toList();
      return list.reduce((a, b) => a + b).toString();
    }else {
      return '-';
    }
  }

  getCategoryName(reportDetail){
    if(reportDetail.category_name != ''){
      return reportDetail.category_name;
    } else {
      return 'Other';
    }
  }
}