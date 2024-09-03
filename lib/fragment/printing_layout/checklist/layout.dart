import 'package:esc_pos_utils/esc_pos_utils.dart';
import 'package:f_logs/model/flog/flog.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../database/pos_database.dart';
import '../../../object/checklist.dart';
import '../receipt_layout.dart';
import '../../../utils/Utils.dart';

class ChecklistLayout extends ReceiptLayout {

/*
  Check list layout 80mm
*/
  printCheckList80mm(bool isUSB, int localId, {value, isQrOrder, String? order_by}) async {
    Checklist? checklistLayout = await PosDatabase.instance.readSpecificChecklist('80');
    if(checklistLayout == null){
      checklistLayout = checklistDefaultLayout;
    }
    final prefs = await SharedPreferences.getInstance();
    final int? branch_id = prefs.getInt('branch_id');
    await readOrderCache(localId);

    var generator;
    if (isUSB) {
      final profile = await CapabilityProfile.load();
      generator = Generator(PaperSize.mm80, profile);
    } else {
      generator = value;
    }
    List<int> bytes = [];
    try {
      bytes += generator.reset();
      bytes += generator.text('** ORDER LIST **', styles: PosStyles(align: PosAlign.center, height:PosTextSize.size2, width: PosTextSize.size2 ));
      bytes += generator.emptyLines(1);
      bytes += generator.reset();
      //other order detail
      if(tableList.isNotEmpty){
        for(int i = 0; i < tableList.length; i++){
          bytes += generator.text('Table No: ${tableList[i].number}', styles: PosStyles(bold: true, align: PosAlign.left, height: PosTextSize.size2, width: PosTextSize.size2));
        }
      } else {
        bytes += generator.text('${orderCache!.dining_name}', styles: PosStyles(bold: true, align: PosAlign.left, height: PosTextSize.size2, width: PosTextSize.size2));
      }
      //order queue
      if(int.tryParse(orderCache!.order_queue!) != null){
        bytes += generator.text('Order No: ${this.orderCache!.order_queue!}', styles: PosStyles(align: PosAlign.left, height:PosTextSize.size2, width: PosTextSize.size2));
      }
      bytes += generator.text('Batch No: #${orderCache!.batch_id}-${branch_id.toString().padLeft(3 ,'0')}');
      if(isQrOrder != null){
        bytes += generator.text('Order By: QrOrder');
      } else if (order_by != null){
        bytes += generator.text('Order By: ${order_by}', containsChinese: true);
      } else {
        bytes += generator.text('Order By: ${orderCache!.order_by}', containsChinese: true);
      }
      bytes += generator.text('Order time: ${Utils.formatDate(orderCache!.created_at)}');
      bytes += generator.hr();
      bytes += generator.reset();
      /*
    *
    * body
    *
    * */
      //order product
      for(int i = 0; i < orderDetailList.length; i++){
        if(i != 0) {
          if(checklistLayout.check_list_show_separator == 1) {
            bytes += generator.reset();
            bytes += generator.hr();
          }
        }
        bytes += generator.row([
          PosColumn(text: '${orderDetailList[i].quantity}', width: 2, styles: PosStyles(bold: true)),
          PosColumn(
              text: '${getOrderDetailSKU(orderDetailList[i], layout: checklistLayout)}${orderDetailList[i].productName} ${checklistLayout.check_list_show_price == 1 ?
              '(${orderDetailList[i].price!}/${orderDetailList[i].unit! != 'each' && orderDetailList[i].unit! != 'each_c' ? orderDetailList[i].unit! : 'each'})' : '' }',
              width: 10,
              containsChinese: true,
              styles: PosStyles(
                  bold: true,
                  align: PosAlign.left,
                  height: checklistLayout.product_name_font_size == 0 ? PosTextSize.size2 : PosTextSize.size1,
                  width: PosTextSize.size1)),
        ]);
        bytes += generator.reset();
        if(orderDetailList[i].has_variant == '1'){
          bytes += generator.row([
            PosColumn(text: '', width: 2, styles: PosStyles(bold: true)),
            PosColumn(text: '(${orderDetailList[i].product_variant_name})',
                containsChinese: true, width: 10,
                styles: PosStyles(
                    align: PosAlign.left,
                    height: checklistLayout.other_font_size == 0 ? PosTextSize.size2 : PosTextSize.size1,
                    width: PosTextSize.size1)),
          ]);
        }
        await getPaidOrderModifierDetail(orderDetailList[i]);
        if(orderModifierDetailList.length > 0) {
          for (int j = 0; j < orderModifierDetailList.length; j++) {
            //modifier
            bytes += generator.row([
              PosColumn(text: '', width: 2),
              PosColumn(text: '+${orderModifierDetailList[j].mod_name}',
                  containsChinese: true,
                  width: 10,
                  styles: PosStyles(
                      align: PosAlign.left,
                      height: checklistLayout.other_font_size == 0 ? PosTextSize.size2 : PosTextSize.size1,
                      width: PosTextSize.size1)),
            ]);
          }
        }
        /*
        * product remark
        * */
        bytes += generator.reset();
        if (orderDetailList[i].remark != '') {
          bytes += generator.row([
            PosColumn(text: '', width: 2),
            PosColumn(text: '**${orderDetailList[i].remark}',
                width: 10,
                containsChinese: true,
                styles: PosStyles(
                    align: PosAlign.left,
                    height: checklistLayout.other_font_size == 0 ? PosTextSize.size2 : PosTextSize.size1,
                    width: PosTextSize.size1)),
          ]);
        }
      }
      bytes += generator.feed(1);
      bytes += generator.cut(mode: PosCutMode.partial);
      return bytes;
    } catch (e) {
      print('layout error: $e');
      FLog.error(
        className: "receipt_layout",
        text: "printCheckList80mm error",
        exception: "$e",
      );
      return null;
    }
  }

/*
  Check list layout 58mm
*/
  printCheckList58mm(bool isUSB, int localId, {value, isQrOrder, String? order_by}) async {
    Checklist? checklistLayout = await PosDatabase.instance.readSpecificChecklist('58');
    if(checklistLayout == null){
      checklistLayout = checklistDefaultLayout;
    }
    final prefs = await SharedPreferences.getInstance();
    final int? branch_id = prefs.getInt('branch_id');
    await readOrderCache(localId);

    var generator;
    if (isUSB) {
      final profile = await CapabilityProfile.load();
      generator = Generator(PaperSize.mm58, profile);
    } else {
      generator = value;
    }

    List<int> bytes = [];
    try {
      bytes += generator.reset();
      bytes += generator.text('** ORDER LIST **', styles: PosStyles(align: PosAlign.center, height:PosTextSize.size2, width: PosTextSize.size2 ));
      bytes += generator.emptyLines(1);
      bytes += generator.reset();
      //other order detail
      if(tableList.isNotEmpty){
        for(int i = 0; i < tableList.length; i++){
          bytes += generator.text('Table No: ${tableList[i].number}', styles: PosStyles(bold: true, align: PosAlign.left, height: PosTextSize.size2, width: PosTextSize.size2));
        }
      } else {
        bytes += generator.text('${orderCache!.dining_name}', styles: PosStyles(bold: true, align: PosAlign.left, height: PosTextSize.size2, width: PosTextSize.size2));
      }
      //order queue
      if(int.tryParse(this.orderCache!.order_queue!) != null){
        bytes += generator.text('Order No: ${this.orderCache!.order_queue!}', styles: PosStyles(align: PosAlign.left, height:PosTextSize.size2, width: PosTextSize.size2));
      }
      bytes += generator.text('Batch No: #${orderCache!.batch_id}-${branch_id.toString().padLeft(3 ,'0')}', styles: PosStyles(align: PosAlign.left));
      if(isQrOrder != null){
        bytes += generator.text('Order By: QrOrder', styles: PosStyles(align: PosAlign.left));
      } else if (order_by != null){
        bytes += generator.text('Order By: ${order_by}', containsChinese: true, styles: PosStyles(align: PosAlign.left));
      } else {
        bytes += generator.text('Order By: ${orderCache!.order_by}', containsChinese: true, styles: PosStyles(align: PosAlign.left));
      }
      bytes += generator.text('Order time: ${Utils.formatDate(orderCache!.created_at)}', styles: PosStyles(align: PosAlign.left));
      bytes += generator.hr();
      bytes += generator.reset();
      /*
    *
    * body
    *
    * */
      //order product
      for(int i = 0; i < orderDetailList.length; i++){
        if(i != 0) {
          if(checklistLayout.check_list_show_separator == 1) {
            bytes += generator.reset();
            bytes += generator.hr();
          }
        }

        bytes += generator.row([
          PosColumn(text: '${orderDetailList[i].quantity}', width: 2, styles: PosStyles(bold: true)),
          PosColumn(
              text: '${getOrderDetailSKU(orderDetailList[i], layout: checklistLayout)}${orderDetailList[i].productName} '
                  '${checklistLayout.check_list_show_price == 1 ? '(${orderDetailList[i].price!}/${orderDetailList[i].unit! != 'each' && orderDetailList[i].unit! != 'each_c' ? orderDetailList[i].unit! : 'each'})' : '' }',
              width: 10,
              containsChinese: true,
              styles: PosStyles(
                  bold: true,
                  height: checklistLayout.product_name_font_size == 0 ? PosTextSize.size2 : PosTextSize.size1,
                  width: PosTextSize.size1)
          ),

        ]);
        bytes += generator.reset();
        if(orderDetailList[i].has_variant == '1'){
          bytes += generator.row([
            PosColumn(text: '', width: 2),
            PosColumn(text: '(${orderDetailList[i].product_variant_name})',
                containsChinese: true,
                width: 10,
                styles: PosStyles(
                    height: checklistLayout.other_font_size == 0 ? PosTextSize.size2 : PosTextSize.size1,
                    width: PosTextSize.size1)),
          ]);
        }
        await getPaidOrderModifierDetail(orderDetailList[i]);
        if(orderModifierDetailList.isNotEmpty) {
          for (int j = 0; j < orderModifierDetailList.length; j++) {
            //modifier
            bytes += generator.row([
              PosColumn(text: '', width: 2),
              PosColumn(text: '+${orderModifierDetailList[j].mod_name}',
                  containsChinese: true,
                  width: 10,
                  styles: PosStyles(
                      height: checklistLayout.other_font_size == 0 ? PosTextSize.size2 : PosTextSize.size1,
                      width: PosTextSize.size1)),
            ]);
          }
        }
        /*
        * product remark
        * */
        bytes += generator.reset();
        if (orderDetailList[i].remark != '') {
          bytes += generator.row([
            PosColumn(text: '', width: 2),
            PosColumn(text: '**${orderDetailList[i].remark}',
                containsChinese: true,
                width: 10,
                styles: PosStyles(
                    height: checklistLayout.other_font_size == 0 ? PosTextSize.size2 : PosTextSize.size1,
                    width: PosTextSize.size1)),
          ]);
        }
      }
      bytes += generator.feed(1);
      bytes += generator.cut(mode: PosCutMode.partial);
      return bytes;
    } catch (e) {
      print('layout error: $e');
      FLog.error(
        className: "receipt_layout",
        text: "printCheckList58mm error",
        exception: "$e",
      );
      return null;
    }
  }


}