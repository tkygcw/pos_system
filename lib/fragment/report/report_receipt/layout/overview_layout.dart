import 'dart:convert';

import 'package:esc_pos_utils/esc_pos_utils.dart';
import 'package:pos_system/object/branch_link_tax.dart';
import 'package:pos_system/utils/Utils.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../notifier/report_notifier.dart';
import '../../../../object/payment_link_company.dart';

class OverviewReceiptLayout {
  Future<List<int>> print80mmFormat(bool isUSB, {value}) async {
    final prefs = await SharedPreferences.getInstance();
    final String? branch = prefs.getString('branch');
    Map branchObject = json.decode(branch!);
    ReportModel model = ReportModel.instance;
    List decodeList = jsonDecode(model.reportValue[6]);
    List decodeList2 = jsonDecode(model.reportValue[7]);
    List<PaymentLinkCompany> paymentList = decodeList.map((e) => PaymentLinkCompany.fromJson(e)).toList();
    List<BranchLinkTax> branchTaxList = decodeList2.map((e) => BranchLinkTax.fromJson(e)).toList();
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
      bytes += generator.text('Sales Overview', containsChinese: true, styles: PosStyles(align: PosAlign.center, bold: true));
      bytes += generator.text('${model.startDateTime2} - ${model.endDateTime2}', containsChinese: true, styles: PosStyles(align: PosAlign.center));
      bytes += generator.text('Generated At', containsChinese: true, styles: PosStyles(align: PosAlign.center, bold: true));
      bytes += generator.text(Utils.formatReportDate(DateTime.now().toString()), containsChinese: true, styles: PosStyles(align: PosAlign.center));
      bytes += generator.hr();

      bytes += generator.row([
        PosColumn(text: 'Overall Summary', width: 10, styles: PosStyles(bold: true, align: PosAlign.left)),
        PosColumn(text: 'Amount', width: 2, styles: PosStyles(bold: true, align: PosAlign.right)),
      ]);
      bytes += generator.row([
        PosColumn(text: 'Bills:', width: 10, styles: PosStyles(align: PosAlign.left)),
        PosColumn(text: model.reportValue[0], width: 2, styles: PosStyles(align: PosAlign.right)),
      ]);
      bytes += generator.row([
        PosColumn(text: 'Sales:', width: 10, styles: PosStyles(align: PosAlign.left)),
        PosColumn(text: model.reportValue[1], width: 2, styles: PosStyles(align: PosAlign.right)),
      ]);
      bytes += generator.row([
        PosColumn(text: 'Refund Bill:', width: 10, styles: PosStyles(align: PosAlign.left)),
        PosColumn(text: model.reportValue[2], width: 2, styles: PosStyles(align: PosAlign.right)),
      ]);
      bytes += generator.row([
        PosColumn(text: 'Refund Amount:', width: 10, styles: PosStyles(align: PosAlign.left)),
        PosColumn(text: model.reportValue[3], width: 2, styles: PosStyles(align: PosAlign.right)),
      ]);
      bytes += generator.row([
        PosColumn(text: 'Discount:', width: 10, styles: PosStyles(align: PosAlign.left)),
        PosColumn(text: model.reportValue[4], width: 2, styles: PosStyles(align: PosAlign.right)),
      ]);
      bytes += generator.row([
        PosColumn(text: 'Cancelled Item:', width: 10, styles: PosStyles(align: PosAlign.left)),
        PosColumn(text: model.reportValue[5], width: 2, styles: PosStyles(align: PosAlign.right)),
      ]);
      bytes += generator.hr();
      bytes += generator.row([
        PosColumn(text: 'Payment Overview', width: 10, styles: PosStyles(bold: true, align: PosAlign.left)),
        PosColumn(text: 'Amount', width: 2, styles: PosStyles(bold: true, align: PosAlign.right)),
      ]);
      for(final payment in paymentList){
        bytes += generator.row([
          PosColumn(text: payment.name!, width: 10, containsChinese: true, styles: PosStyles(align: PosAlign.left)),
          PosColumn(text: Utils.to2Decimal(payment.totalAmount), width: 2, styles: PosStyles(align: PosAlign.right)),
        ]);
      }
      bytes += generator.hr();
      bytes += generator.row([
        PosColumn(text: 'Charges Overview', width: 10, styles: PosStyles(bold: true, align: PosAlign.left)),
        PosColumn(text: 'Amount', width: 2, styles: PosStyles(bold: true, align: PosAlign.right)),
      ]);
      for(final tax in branchTaxList){
        bytes += generator.row([
          PosColumn(text: tax.tax_name!, width: 10, styles: PosStyles(align: PosAlign.left)),
          PosColumn(text: Utils.to2Decimal(tax.total_amount), width: 2, styles: PosStyles(align: PosAlign.right)),
        ]);
      }

      bytes += generator.reset();
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
    List decodeList = jsonDecode(model.reportValue[6]);
    List decodeList2 = jsonDecode(model.reportValue[7]);
    List<PaymentLinkCompany> paymentList = decodeList.map((e) => PaymentLinkCompany.fromJson(e)).toList();
    List<BranchLinkTax> branchTaxList = decodeList2.map((e) => BranchLinkTax.fromJson(e)).toList();
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
      bytes += generator.text('Sales Overview', containsChinese: true, styles: PosStyles(align: PosAlign.center, bold: true));
      bytes += generator.text('${model.startDateTime2} - ${model.endDateTime2}', containsChinese: true, styles: PosStyles(align: PosAlign.center));
      bytes += generator.text('Generated At', containsChinese: true, styles: PosStyles(align: PosAlign.center, bold: true));
      bytes += generator.text(Utils.formatReportDate(DateTime.now().toString()), containsChinese: true, styles: PosStyles(align: PosAlign.center));
      bytes += generator.hr();

      bytes += generator.row([
        PosColumn(text: 'Overall Summary', width: 8, styles: PosStyles(bold: true)),
        PosColumn(text: 'Amount', width: 4, styles: PosStyles(bold: true)),
      ]);
      bytes += generator.row([
        PosColumn(text: 'Bill', width: 8),
        PosColumn(text: model.reportValue[0], width: 4),
      ]);
      bytes += generator.row([
        PosColumn(text: 'Sales', width: 8),
        PosColumn(text: model.reportValue[1], width: 4),
      ]);
      bytes += generator.row([
        PosColumn(text: 'Refund Bill', width: 8),
        PosColumn(text: model.reportValue[2], width: 4),
      ]);
      bytes += generator.row([
        PosColumn(text: 'Refund Amount', width: 8),
        PosColumn(text: model.reportValue[3], width: 4),
      ]);
      bytes += generator.row([
        PosColumn(text: 'Discount:', width: 8),
        PosColumn(text: model.reportValue[4], width: 4),
      ]);
      bytes += generator.row([
        PosColumn(text: 'Cancelled Item', width: 8),
        PosColumn(text: model.reportValue[5], width: 4),
      ]);
      bytes += generator.hr();
      bytes += generator.row([
        PosColumn(text: 'Payment Overview', width: 8, styles: PosStyles(bold: true)),
        PosColumn(text: 'Amount', width: 4, styles: PosStyles(bold: true)),
      ]);
      for(final payment in paymentList){
        bytes += generator.row([
          PosColumn(text: payment.name!, containsChinese: true, width: 8),
          PosColumn(text: Utils.to2Decimal(payment.totalAmount), width: 4),
        ]);
      }
      bytes += generator.hr();
      bytes += generator.row([
        PosColumn(text: 'Charges Overview', width: 8, styles: PosStyles(bold: true)),
        PosColumn(text: 'Amount', width: 4, styles: PosStyles(bold: true)),
      ]);
      for(final tax in branchTaxList){
        bytes += generator.row([
          PosColumn(text: tax.tax_name!, width: 8),
          PosColumn(text: Utils.to2Decimal(tax.total_amount), width: 4),
        ]);
      }

      bytes += generator.reset();
      bytes += generator.hr();
      bytes += generator.cut(mode: PosCutMode.partial);
      return bytes;

    }catch(e){
      print("format error: $e");
      return [];
    }
  }

}