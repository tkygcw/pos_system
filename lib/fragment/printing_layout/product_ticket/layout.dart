import 'dart:convert';

import 'package:pos_system/fragment/printing_layout/receipt_layout.dart';
import 'package:pos_system/main.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:esc_pos_utils/esc_pos_utils.dart';

import '../../../database/pos_database.dart';
import '../../../object/branch.dart';
import '../../../object/cart_product.dart';
import '../../../object/checklist.dart';
import '../../../utils/Utils.dart';

class ProductTicketLayout extends ReceiptLayout {
  /*
  product ticket 80mm
*/
  printProductTicket80mm(bool isUSB, int localId, int count, {value, required cartProductItem cartItem}) async {
    final prefs = await SharedPreferences.getInstance();
    final String? branch = prefs.getString('branch');
    Map<String, dynamic> branchMap = json.decode(branch!);
    Branch branchObject = Branch.fromJson(branchMap);
    Checklist? checklistLayout = await PosDatabase.instance.readSpecificChecklist('80');
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
      bytes += generator.text(branchObject.name, containsChinese: true, styles: PosStyles(align: PosAlign.center, width: PosTextSize.size2, height: PosTextSize.size2));
      bytes += generator.text(branchObject.address, styles: PosStyles(align: PosAlign.center));
      bytes += generator.emptyLines(1);
      bytes += generator.reset();
      //other order detail
      if(tableList.isNotEmpty){
        for(int i = 0; i < tableList.length; i++){
          bytes += generator.text('Table No: ${tableList[i].number}', styles: PosStyles(bold: true, height: PosTextSize.size2, width: PosTextSize.size2));
        }
      } else {
        bytes += generator.text('${orderCache!.dining_name}', styles: PosStyles(bold: true, height: PosTextSize.size2, width: PosTextSize.size2));
      }
      //order queue
      if(int.tryParse(orderCache!.order_queue!) != null){
        bytes += generator.text('Order No: ${orderCache!.order_queue!}', styles: PosStyles(height:PosTextSize.size2, width: PosTextSize.size2));
      }
      bytes += generator.text('Batch No: #${orderCache!.batch_id}-${branchObject.branch_id!.toString().padLeft(3 ,'0')}');
      bytes += generator.text('Order By: ${orderCache!.order_by}', containsChinese: true);
      bytes += generator.text('Order time: ${Utils.formatDate(orderCache!.created_at)}');
      bytes += generator.hr();
      bytes += generator.reset();
      /*
    *
    * body
    *
    * */
      //order product
      bytes += generator.row([
        PosColumn(text: cartItem.unit != 'each' && cartItem.unit != 'each_c' ? '${(cartItem.quantity!*int.parse(cartItem.per_quantity_unit!)).toStringAsFixed(2)}${cartItem.unit}'
            : '${cartItem.quantity}',
            width: 2,
            styles: PosStyles(
                align: PosAlign.left,
                bold: true,
                height: checklistLayout != null && checklistLayout.product_name_font_size == 1 ? PosTextSize.size1 : PosTextSize.size2,
                width: checklistLayout != null && checklistLayout.product_name_font_size == 1 ? PosTextSize.size1 : PosTextSize.size2)),
        PosColumn(
            text: '${cartItem.product_name}${checklistLayout != null && checklistLayout.check_list_show_price == 1 ? '($currency_symbol${(double.parse(cartItem.price!) * cartItem.quantity!).toStringAsFixed(2)})' : '' }',
            width: 10,
            containsChinese: true,
            styles: PosStyles(
                align: PosAlign.left,
                height: checklistLayout != null && checklistLayout.product_name_font_size == 1 ? PosTextSize.size1 : PosTextSize.size2,
                width: checklistLayout != null && checklistLayout.product_name_font_size == 1 ? PosTextSize.size1 : PosTextSize.size2))
      ]);
      bytes += generator.reset();
      //product variant
      if(cartItem.productVariantName != ''){
        bytes += generator.row([
          PosColumn(
              text: '',
              width: 2,
              styles: PosStyles(
                  align: PosAlign.left,
                  height: checklistLayout != null && checklistLayout.other_font_size == 0 ? PosTextSize.size2 : PosTextSize.size1,
                  width: checklistLayout != null && checklistLayout.other_font_size == 0 ? PosTextSize.size2 : PosTextSize.size1)),
          PosColumn(
              text: '(${cartItem.productVariantName})',
              width: 10,
              containsChinese: true,
              styles: PosStyles(
                  align: PosAlign.left,
                  height: checklistLayout != null && checklistLayout.other_font_size == 0 ? PosTextSize.size2 : PosTextSize.size1,
                  width: checklistLayout != null && checklistLayout.other_font_size == 0 ? PosTextSize.size2 : PosTextSize.size1)),
        ]);
      }
      bytes += generator.reset();
      //product modifier
      if(cartItem.checkedModifierItem != null){
        if(cartItem.checkedModifierItem!.isNotEmpty) {
          for (int j = 0; j < cartItem.checkedModifierItem!.length; j++) {
            //modifier
            bytes += generator.row([
              PosColumn(
                  text: '',
                  width: 2,
                  styles: PosStyles(
                      height: checklistLayout != null && checklistLayout.other_font_size == 0 ? PosTextSize.size2 : PosTextSize.size1,
                      width: checklistLayout != null && checklistLayout.other_font_size == 0 ? PosTextSize.size2 : PosTextSize.size1)),
              PosColumn(text: '+${cartItem.checkedModifierItem![j].name}',
                  containsChinese: true,
                  width: 10,
                  styles: PosStyles(
                      align: PosAlign.left,
                      height: checklistLayout != null && checklistLayout.other_font_size == 0 ? PosTextSize.size2 : PosTextSize.size1,
                      width: checklistLayout != null && checklistLayout.other_font_size == 0 ? PosTextSize.size2 : PosTextSize.size1)),
            ]);
          }
        }
      } else {
        for(final modItem in cartItem.orderModifierDetail!){
          bytes += generator.row([
            PosColumn(
                text: '',
                width: 2,
                styles: PosStyles(
                    height: checklistLayout != null && checklistLayout.other_font_size == 0 ? PosTextSize.size2 : PosTextSize.size1,
                    width: checklistLayout != null && checklistLayout.other_font_size == 0 ? PosTextSize.size2 : PosTextSize.size1)),
            PosColumn(text: '+${modItem.mod_name}',
                containsChinese: true,
                width: 10,
                styles: PosStyles(
                    align: PosAlign.left,
                    height: checklistLayout != null && checklistLayout.other_font_size == 0 ? PosTextSize.size2 : PosTextSize.size1,
                    width: checklistLayout != null && checklistLayout.other_font_size == 0 ? PosTextSize.size2 : PosTextSize.size1)),
          ]);
        }
      }
      /*
        * product remark
        * */
      bytes += generator.reset();
      if (cartItem.remark != '') {
        bytes += generator.row([
          PosColumn(text: '', width: 2),
          PosColumn(
              text: '**${cartItem.remark}',
              width: 8,
              containsChinese: true,
              styles: PosStyles(
                  align: PosAlign.left,
                  height: checklistLayout != null && checklistLayout.other_font_size == 0 ? PosTextSize.size2 : PosTextSize.size1,
                  width: PosTextSize.size2)),
          PosColumn(text: '', width: 2),
        ]);
      }
      bytes += generator.emptyLines(1);
      bytes += generator.reset();
      bytes += generator.row([
        PosColumn(text: '', width: 2),
        PosColumn(text: '', width: 8),
        PosColumn(text: '$count/${cartItem.ticket_count}', width: 2),
      ]);

      if(cartItem.ticket_exp != '' && cartItem.ticket_exp != '0'){
        bytes += generator.text('**Valid for ${cartItem.ticket_exp} days only**', styles: PosStyles(align: PosAlign.center));
      }
      bytes += generator.feed(1);
      bytes += generator.cut(mode: PosCutMode.partial);
      return bytes;
    } catch (e) {
      print('layout error: $e');
      return null;
    }
  }

/*
  product ticket 58mm
*/
  printProductTicket58mm(bool isUSB, int localId, int count, {value, required cartProductItem cartItem}) async {
    final prefs = await SharedPreferences.getInstance();
    final String? branch = prefs.getString('branch');
    Map<String, dynamic> branchMap = json.decode(branch!);
    Branch branchObject = Branch.fromJson(branchMap);
    Checklist? checklistLayout = await PosDatabase.instance.readSpecificChecklist('58');
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
      bytes += generator.text(branchObject.name, containsChinese: true, styles: PosStyles(align: PosAlign.center, width: PosTextSize.size2, height: PosTextSize.size2));
      bytes += generator.text(branchObject.address, styles: PosStyles(align: PosAlign.center));
      bytes += generator.emptyLines(1);
      bytes += generator.reset();
      //other order detail
      if(tableList.isNotEmpty){
        for(int i = 0; i < tableList.length; i++){
          bytes += generator.text('Table No: ${tableList[i].number}', styles: PosStyles(bold: true, height: PosTextSize.size2, width: PosTextSize.size2));
        }
      } else {
        bytes += generator.text('${orderCache!.dining_name}', styles: PosStyles(bold: true, height: PosTextSize.size2, width: PosTextSize.size2));
      }
      //order queue
      if(int.tryParse(orderCache!.order_queue!) != null){
        bytes += generator.text('Order No: ${orderCache!.order_queue!}', styles: PosStyles(height:PosTextSize.size2, width: PosTextSize.size2));
      }
      bytes += generator.text('Batch No: #${orderCache!.batch_id}-${branchObject.branch_id!.toString().padLeft(3 ,'0')}');
      bytes += generator.text('Order By: ${orderCache!.order_by}', containsChinese: true);
      bytes += generator.text('Order time: ${Utils.formatDate(orderCache!.created_at)}');
      bytes += generator.hr();
      bytes += generator.reset();
      /*
    *
    * body
    *
    * */
      //order product
      bytes += generator.row([
        PosColumn(text: cartItem.unit != 'each' && cartItem.unit != 'each_c' ? '${(cartItem.quantity!*int.parse(cartItem.per_quantity_unit!)).toStringAsFixed(2)}${cartItem.unit}'
            : '${cartItem.quantity}',
            width: 2,
            styles: PosStyles(
                bold: true,
                height: checklistLayout != null && checklistLayout.product_name_font_size == 1 ? PosTextSize.size1 : PosTextSize.size2,
                width: checklistLayout != null && checklistLayout.product_name_font_size == 1 ? PosTextSize.size1 : PosTextSize.size2)),
        PosColumn(
            text: '${cartItem.product_name}${checklistLayout != null && checklistLayout.check_list_show_price == 1 ? '($currency_symbol${(double.parse(cartItem.price!) * cartItem.quantity!).toStringAsFixed(2)})' : '' }',
            width: 10,
            containsChinese: true,
            styles: PosStyles(
                height: checklistLayout != null && checklistLayout.product_name_font_size == 1 ? PosTextSize.size1 : PosTextSize.size2,
                width: checklistLayout != null && checklistLayout.product_name_font_size == 1 ? PosTextSize.size1 : PosTextSize.size2))
      ]);
      bytes += generator.reset();
      //product variant
      if(cartItem.productVariantName != ''){
        bytes += generator.row([
          PosColumn(
              text: '',
              width: 2,
              styles: PosStyles(
                  height: checklistLayout != null && checklistLayout.other_font_size == 0 ? PosTextSize.size2 : PosTextSize.size1,
                  width: checklistLayout != null && checklistLayout.other_font_size == 0 ? PosTextSize.size2 : PosTextSize.size1)),
          PosColumn(
              text: '(${cartItem.productVariantName})',
              width: 10,
              containsChinese: true,
              styles: PosStyles(
                  height: checklistLayout != null && checklistLayout.other_font_size == 0 ? PosTextSize.size2 : PosTextSize.size1,
                  width: checklistLayout != null && checklistLayout.other_font_size == 0 ? PosTextSize.size2 : PosTextSize.size1)),
        ]);
      }
      bytes += generator.reset();
      //product modifier
      if(cartItem.checkedModifierItem != null){
        if(cartItem.checkedModifierItem!.isNotEmpty) {
          for (int j = 0; j < cartItem.checkedModifierItem!.length; j++) {
            //modifier
            bytes += generator.row([
              PosColumn(
                  text: '',
                  width: 2,
                  styles: PosStyles(
                      height: checklistLayout != null && checklistLayout.other_font_size == 0 ? PosTextSize.size2 : PosTextSize.size1,
                      width: checklistLayout != null && checklistLayout.other_font_size == 0 ? PosTextSize.size2 : PosTextSize.size1)),
              PosColumn(text: '+${cartItem.checkedModifierItem![j].name}',
                  containsChinese: true,
                  width: 10,
                  styles: PosStyles(
                      height: checklistLayout != null && checklistLayout.other_font_size == 0 ? PosTextSize.size2 : PosTextSize.size1,
                      width: checklistLayout != null && checklistLayout.other_font_size == 0 ? PosTextSize.size2 : PosTextSize.size1)),
            ]);
          }
        }
      } else {
        for(final modItem in cartItem.orderModifierDetail!){
          bytes += generator.row([
            PosColumn(
                text: '',
                width: 2,
                styles: PosStyles(
                    height: checklistLayout != null && checklistLayout.other_font_size == 0 ? PosTextSize.size2 : PosTextSize.size1,
                    width: checklistLayout != null && checklistLayout.other_font_size == 0 ? PosTextSize.size2 : PosTextSize.size1)),
            PosColumn(text: '+${modItem.mod_name}',
                containsChinese: true,
                width: 10,
                styles: PosStyles(
                    height: checklistLayout != null && checklistLayout.other_font_size == 0 ? PosTextSize.size2 : PosTextSize.size1,
                    width: checklistLayout != null && checklistLayout.other_font_size == 0 ? PosTextSize.size2 : PosTextSize.size1)),
          ]);
        }
      }
      /*
        * product remark
        * */
      bytes += generator.reset();
      if (cartItem.remark != '') {
        bytes += generator.row([
          PosColumn(text: '', width: 2),
          PosColumn(
              text: '**${cartItem.remark}',
              width: 8,
              containsChinese: true,
              styles: PosStyles(
                  height: checklistLayout != null && checklistLayout.other_font_size == 0 ? PosTextSize.size2 : PosTextSize.size1,
                  width: PosTextSize.size2)),
          PosColumn(text: '', width: 2),
        ]);
      }
      bytes += generator.emptyLines(1);
      bytes += generator.reset();
      bytes += generator.row([
        PosColumn(text: '', width: 2),
        PosColumn(text: '', width: 8),
        PosColumn(text: '$count/${cartItem.ticket_count}', width: 2),
      ]);
      if(cartItem.ticket_exp != '' && cartItem.ticket_exp != '0'){
        bytes += generator.text('**Valid for ${cartItem.ticket_exp} days only**', styles: PosStyles(align: PosAlign.center));
      }
      bytes += generator.feed(1);
      bytes += generator.cut(mode: PosCutMode.partial);
      return bytes;
    } catch (e) {
      print('layout error: $e');
      return null;
    }
  }
}