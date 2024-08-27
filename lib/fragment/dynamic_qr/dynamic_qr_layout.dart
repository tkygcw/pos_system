import 'dart:convert';

import 'package:pos_system/database/pos_database.dart';
import 'package:pos_system/object/table.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:esc_pos_utils/esc_pos_utils.dart';

import '../../object/dynamic_qr.dart';
import '../../utils/Utils.dart';

class DynamicQrLayout {
  Future<List<int>> print80mmFormat(bool isUSB, {value, required PosTable posTable}) async {
    print("pos table url: ${posTable.qrOrderUrl}");
    DynamicQR? layout = await PosDatabase.instance.readSpecificDynamicQRByPaperSize('80');
    final prefs = await SharedPreferences.getInstance();
    final String? branch = prefs.getString('branch');
    Map branchObject = json.decode(branch!);
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
      bytes += generator.text('Table No:${posTable.number}', containsChinese: true, styles: PosStyles(align: PosAlign.center, bold: true));
      bytes += generator.emptyLines(1);
      if(layout != null){
        if(layout.qr_code_size == 2){
          bytes += generator.qrcode(posTable.qrOrderUrl, size: QRSize.Size6, cor: QRCorrection.H);
        } else if (layout.qr_code_size == 1){
          bytes += generator.qrcode(posTable.qrOrderUrl, size: QRSize.Size5, cor: QRCorrection.H);
        } else {
          bytes += generator.qrcode(posTable.qrOrderUrl, size: QRSize.Size4, cor: QRCorrection.H);
        }
      } else {
        bytes += generator.qrcode(posTable.qrOrderUrl, size: QRSize.Size6, cor: QRCorrection.H);
      }
      bytes += generator.emptyLines(1);
      if(posTable.dynamicQRExp != null){
        bytes += generator.text('Generated At', containsChinese: true, styles: PosStyles(align: PosAlign.center, bold: true));
        bytes += generator.text(Utils.formatReportDate(DateTime.now().toString()), containsChinese: true, styles: PosStyles(align: PosAlign.center));
        bytes += generator.text('Expired At', containsChinese: true, styles: PosStyles(align: PosAlign.center, bold: true));
        bytes += generator.text(Utils.formatReportDate(posTable.dynamicQRExp), containsChinese: true, styles: PosStyles(align: PosAlign.center));
      }
      bytes += generator.hr();

      bytes += generator.cut(mode: PosCutMode.partial);
      return bytes;

    }catch(e){
      print("format error: $e");
      return [];
    }
  }

  Future<List<int>> print58mmFormat(bool isUSB, {value, required PosTable posTable}) async {
    print("pos table url: ${posTable.qrOrderUrl}");
    DynamicQR? layout = await PosDatabase.instance.readSpecificDynamicQRByPaperSize('58');
    final prefs = await SharedPreferences.getInstance();
    final String? branch = prefs.getString('branch');
    Map branchObject = json.decode(branch!);
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
      bytes += generator.text('Table No:${posTable.number}', containsChinese: true, styles: PosStyles(align: PosAlign.center, bold: true));
      bytes += generator.emptyLines(1);
      if(layout != null){
        if(layout.qr_code_size == 2){
          bytes += generator.qrcode(posTable.qrOrderUrl, size: QRSize.Size6, cor: QRCorrection.H);
        } else if (layout.qr_code_size == 1){
          bytes += generator.qrcode(posTable.qrOrderUrl, size: QRSize.Size5, cor: QRCorrection.H);
        } else {
          bytes += generator.qrcode(posTable.qrOrderUrl, size: QRSize.Size4, cor: QRCorrection.H);
        }
      } else {
        bytes += generator.qrcode(posTable.qrOrderUrl, size: QRSize.Size6, cor: QRCorrection.H);
      }
      bytes += generator.emptyLines(1);
      if(posTable.dynamicQRExp != null){
        bytes += generator.text('Generated At', containsChinese: true, styles: PosStyles(align: PosAlign.center, bold: true));
        bytes += generator.text(Utils.formatReportDate(DateTime.now().toString()), containsChinese: true, styles: PosStyles(align: PosAlign.center));
        bytes += generator.text('Expired At', containsChinese: true, styles: PosStyles(align: PosAlign.center, bold: true));
        bytes += generator.text(Utils.formatReportDate(posTable.dynamicQRExp), containsChinese: true, styles: PosStyles(align: PosAlign.center));
      }
      bytes += generator.hr();

      bytes += generator.cut(mode: PosCutMode.partial);
      return bytes;

    }catch(e){
      print("format error: $e");
      return [];
    }
  }

  Future<List<int>> testPrint80mmFormat(bool isUSB, {value, required DynamicQR dynamicQR}) async {
    final testUrl = 'https://qr.optimy.com.my/9118035f22025995fed0c63a08c2dbbb/ab7e005f1e61d81db0bd569db8ffe39b/3ecd9';
    final prefs = await SharedPreferences.getInstance();
    final String? branch = prefs.getString('branch');
    Map branchObject = json.decode(branch!);
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
      bytes += generator.text('Table No: 1', containsChinese: true, styles: PosStyles(align: PosAlign.center, bold: true));
      bytes += generator.emptyLines(1);
      if(dynamicQR.qr_code_size == 2){
        bytes += generator.qrcode('$testUrl', size: QRSize.Size6, cor: QRCorrection.H);
      } else if (dynamicQR.qr_code_size == 1){
        bytes += generator.qrcode('$testUrl', size: QRSize.Size5, cor: QRCorrection.H);
      } else {
        bytes += generator.qrcode('$testUrl', size: QRSize.Size4, cor: QRCorrection.H);
      }
      bytes += generator.emptyLines(1);
      bytes += generator.text('Generated At', containsChinese: true, styles: PosStyles(align: PosAlign.center, bold: true));
      bytes += generator.text('DD/MM/YYYY hh:mm:ss AM', containsChinese: true, styles: PosStyles(align: PosAlign.center));
      bytes += generator.text('Expired At', containsChinese: true, styles: PosStyles(align: PosAlign.center, bold: true));
      bytes += generator.text('DD/MM/YYYY hh:mm:ss PM', containsChinese: true, styles: PosStyles(align: PosAlign.center));
      bytes += generator.hr();
      bytes += generator.text(dynamicQR.footer_text!, containsChinese: true, styles: PosStyles(align: PosAlign.center));

      bytes += generator.cut(mode: PosCutMode.partial);
      return bytes;

    }catch(e){
      print("format error: $e");
      return [];
    }
  }

  Future<List<int>> testPrint58mmFormat(bool isUSB, {value, required DynamicQR dynamicQR}) async {
    final testUrl = 'https://qr.optimy.com.my/9118035f22025995fed0c63a08c2dbbb/ab7e005f1e61d81db0bd569db8ffe39b/3ecd9';
    final prefs = await SharedPreferences.getInstance();
    final String? branch = prefs.getString('branch');
    Map branchObject = json.decode(branch!);
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
      bytes += generator.text('Table No: 1', containsChinese: true, styles: PosStyles(align: PosAlign.center, bold: true));
      bytes += generator.emptyLines(1);
      if(dynamicQR.qr_code_size == 2){
        bytes += generator.qrcode('$testUrl', size: QRSize.Size6, cor: QRCorrection.H);
      } else if (dynamicQR.qr_code_size == 1){
        bytes += generator.qrcode('$testUrl', size: QRSize.Size5, cor: QRCorrection.H);
      } else {
        bytes += generator.qrcode('$testUrl', size: QRSize.Size4, cor: QRCorrection.H);
      }
      bytes += generator.emptyLines(1);
      bytes += generator.text('Generated At', containsChinese: true, styles: PosStyles(align: PosAlign.center, bold: true));
      bytes += generator.text('DD/MM/YYYY hh:mm:ss AM', containsChinese: true, styles: PosStyles(align: PosAlign.center));
      bytes += generator.text('Expired At', containsChinese: true, styles: PosStyles(align: PosAlign.center, bold: true));
      bytes += generator.text('DD/MM/YYYY hh:mm:ss PM', containsChinese: true, styles: PosStyles(align: PosAlign.center));
      bytes += generator.hr();
      bytes += generator.text(dynamicQR.footer_text!, containsChinese: true, styles: PosStyles(align: PosAlign.center));

      bytes += generator.cut(mode: PosCutMode.partial);
      return bytes;

    }catch(e){
      print("format error: $e");
      return [];
    }
  }
}