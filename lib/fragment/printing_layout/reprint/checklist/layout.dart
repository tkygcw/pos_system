import 'package:esc_pos_utils/esc_pos_utils.dart';
import 'package:pos_system/fragment/printing_layout/receipt_layout.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../database/pos_database.dart';
import '../../../../notifier/cart_notifier.dart';
import '../../../../object/cart_product.dart';
import '../../../../object/checklist.dart';
import '../../../../utils/Utils.dart';

class ReprintCheckListLayout extends ReceiptLayout{
  /*
  reprint check list layout 80mm
*/
  reprintCheckList80mm(bool isUSB, CartModel cartModel, {value, bool? isPayment}) async {
    double subtotal = 0;
    Checklist? checklistLayout = await PosDatabase.instance.readSpecificChecklist('80');
    if(checklistLayout == null){
      checklistLayout = checklistDefaultLayout;
    }
    final prefs = await SharedPreferences.getInstance();
    final int? branch_id = prefs.getInt('branch_id');
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
      bytes += generator.text('** Reprint List **', styles: PosStyles(align: PosAlign.center, height:PosTextSize.size2, width: PosTextSize.size2 ));
      bytes += generator.emptyLines(1);
      bytes += generator.reset();
      //other order detail
      if(cartModel.selectedTable.isNotEmpty && isPayment == null){
        for(int i = 0; i < cartModel.selectedTable.length; i++){
          bytes += generator.text('Table No: ${cartModel.selectedTable[i].number}', styles: PosStyles(bold: true, align: PosAlign.left, height: PosTextSize.size2, width: PosTextSize.size2));
        }
      } else {
        bytes += generator.text('${cartModel.selectedOption}', styles: PosStyles(bold: true, align: PosAlign.left, height: PosTextSize.size2, width: PosTextSize.size2));
      }
      //order queue
      if(cartModel.cartNotifierItem[0].order_queue != null && int.tryParse(cartModel.cartNotifierItem[0].order_queue!) != null){
        bytes += generator.text('Order No: ${cartModel.cartNotifierItem[0].order_queue!}', styles: PosStyles(align: PosAlign.left, height:PosTextSize.size2, width: PosTextSize.size2));
      }
      bytes += generator.text('Batch No: #${cartModel.cartNotifierItem[0].first_cache_batch}-${branch_id.toString().padLeft(3 ,'0')}');
      bytes += generator.text('Order By: ${cartModel.cartNotifierItem[0].first_cache_order_by}', containsChinese: true);
      bytes += generator.text('Order Time: ${Utils.formatDate(cartModel.cartNotifierItem[0].first_cache_created_date_time)}');
      bytes += generator.hr();
      bytes += generator.reset();
      /*
    *
    * body
    *
    * */
      //order product
      for(int i = 0; i < cartModel.cartNotifierItem.length; i++){
        if(i != 0) {
          if(checklistLayout.check_list_show_separator == 1) {
            bytes += generator.reset();
            bytes += generator.hr();
          }
        }

        bytes += generator.row([
          PosColumn(text: '${cartModel.cartNotifierItem[i].quantity}', width: 2, styles: PosStyles(align: PosAlign.left, bold: true)),
          PosColumn(
              text: '${getCartProductSKU(cartModel.cartNotifierItem[i], layout: checklistLayout)}${cartModel.cartNotifierItem[i].product_name!.trim()} ${checklistLayout.check_list_show_price == 1 ? '(${cartModel.cartNotifierItem[i].price!}/${cartModel.cartNotifierItem[i].unit! != 'each' && cartModel.cartNotifierItem[i].unit! != 'each_c' ? cartModel.cartNotifierItem[i].unit! : 'each'})' : '' }',
              width: 10,
              containsChinese: true,
              styles: PosStyles(
                  bold: true,
                  align: PosAlign.left,
                  height: checklistLayout.product_name_font_size == 0 ? PosTextSize.size2 : PosTextSize.size1,
                  width: PosTextSize.size1)),
        ]);
        bytes += generator.reset();
        if(cartModel.cartNotifierItem[i].productVariantName != null && cartModel.cartNotifierItem[i].productVariantName != ''){
          bytes += generator.row([
            PosColumn(text: '', width: 2),
            PosColumn(text: '(${cartModel.cartNotifierItem[i].productVariantName})',
                width: 10,
                containsChinese: true,
                styles: PosStyles(
                    align: PosAlign.left,
                    height: checklistLayout.other_font_size == 0 ? PosTextSize.size2 : PosTextSize.size1,
                    width: PosTextSize.size1)),
          ]);
        }
        bytes += generator.reset();
        if(cartModel.cartNotifierItem[i].orderModifierDetail!.isNotEmpty){
          cartProductItem cartItem = cartModel.cartNotifierItem[i];
          for(int j = 0; j < cartItem.orderModifierDetail!.length; j++){
            bytes += generator.row([
              PosColumn(text: '', width: 2),
              PosColumn(text: '+${cartItem.orderModifierDetail![j].mod_name!}',
                  width: 10,
                  containsChinese: true,
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
        if (cartModel.cartNotifierItem[i].remark != '') {
          bytes += generator.row([
            PosColumn(text: '', width: 2),
            PosColumn(text: '**${cartModel.cartNotifierItem[i].remark}',
                width: 10,
                containsChinese: true,
                styles: PosStyles(
                    align: PosAlign.left,
                    height: checklistLayout.other_font_size == 0 ?  PosTextSize.size2 : PosTextSize.size1,
                    width: PosTextSize.size1)),
          ]);
        }
        subtotal += double.parse(cartModel.cartNotifierItem[i].price!) * cartModel.cartNotifierItem[i].quantity!;
      }

      if(subtotal != 0 && checklistLayout.show_total_amount == 1) {
        bytes += generator.reset();
        bytes += generator.emptyLines(1);
        bytes += generator.text('Total: RM ${subtotal.toStringAsFixed(2)}',
            styles: PosStyles(
                align: PosAlign.right,
                height: checklistLayout.other_font_size == 0 ? PosTextSize.size2 : PosTextSize.size1,
                width: PosTextSize.size1
            )
        );
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
  reprint check list layout 58mm
*/
  reprintCheckList58mm(bool isUSB, CartModel cartModel, {value, bool? isPayment}) async {
    double subtotal = 0;
    Checklist? checklistLayout = await PosDatabase.instance.readSpecificChecklist('58');
    if(checklistLayout == null){
      checklistLayout = checklistDefaultLayout;
    }
    final prefs = await SharedPreferences.getInstance();
    final int? branch_id = prefs.getInt('branch_id');

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
      bytes += generator.text('** Reprint List **', styles: PosStyles(align: PosAlign.center, height:PosTextSize.size2, width: PosTextSize.size2 ));
      bytes += generator.emptyLines(1);
      bytes += generator.reset();
      //other order detail
      if(cartModel.selectedTable.isNotEmpty && isPayment == null){
        for(int i = 0; i < cartModel.selectedTable.length; i++){
          bytes += generator.text('Table No: ${cartModel.selectedTable[i].number}', styles: PosStyles(bold: true, align: PosAlign.left, height: PosTextSize.size2, width: PosTextSize.size2));
        }
      }else {
        bytes += generator.text('${cartModel.selectedOption}', styles: PosStyles(bold: true, align: PosAlign.left, height: PosTextSize.size2, width: PosTextSize.size2));
      }
      //order queue
      if(cartModel.cartNotifierItem[0].order_queue != null && int.tryParse(cartModel.cartNotifierItem[0].order_queue!) != null){
        bytes += generator.text('Order No: ${cartModel.cartNotifierItem[0].order_queue!}', styles: PosStyles(align: PosAlign.left, height:PosTextSize.size2, width: PosTextSize.size2));
      }
      bytes += generator.text('Batch No: #${cartModel.cartNotifierItem[0].first_cache_batch}-${branch_id.toString().padLeft(3 ,'0')}');
      bytes += generator.text('Order By: ${cartModel.cartNotifierItem[0].first_cache_order_by}', containsChinese: true);
      bytes += generator.text('Order time: ${Utils.formatDate(cartModel.cartNotifierItem[0].first_cache_created_date_time)}');
      // bytes += generator.text('Table No: 5', styles: PosStyles(bold: true, align: PosAlign.left, height: PosTextSize.size2, width: PosTextSize.size2));
      bytes += generator.hr();
      bytes += generator.reset();
      /*
    *
    * body
    *
    * */
      //order product
      for(int i = 0; i < cartModel.cartNotifierItem.length; i++){
        if(i != 0) {
          if(checklistLayout.check_list_show_separator == 1) {
            bytes += generator.reset();
            bytes += generator.hr();
          }
        }

        bytes += generator.row([
          PosColumn(text: '${cartModel.cartNotifierItem[i].quantity}', width: 2, styles: PosStyles(align: PosAlign.left, bold: true)),
          PosColumn(
              text: '${getCartProductSKU(cartModel.cartNotifierItem[i], layout: checklistLayout)}${cartModel.cartNotifierItem[i].product_name} ${checklistLayout.check_list_show_price == 1 ? '(${cartModel.cartNotifierItem[i].price!}/${cartModel.cartNotifierItem[i].unit! != 'each' && cartModel.cartNotifierItem[i].unit! != 'each_c' ? cartModel.cartNotifierItem[i].unit! : 'each'})' : '' }',
              width: 10,
              containsChinese: true,
              styles: PosStyles(
                  bold: true,
                  align: PosAlign.left,
                  height: checklistLayout.product_name_font_size == 0 ? PosTextSize.size2 : PosTextSize.size1,
                  width: PosTextSize.size1)),
        ]);
        bytes += generator.reset();
        if(cartModel.cartNotifierItem[i].productVariantName != null && cartModel.cartNotifierItem[i].productVariantName != ''){
          bytes += generator.row([
            PosColumn(text: '', width: 2),
            PosColumn(text: '(${cartModel.cartNotifierItem[i].productVariantName})',
                width: 10,
                containsChinese: true,
                styles: PosStyles(
                  width: PosTextSize.size1,
                  height: checklistLayout.other_font_size == 0 ? PosTextSize.size2 : PosTextSize.size1,
                )),
          ]);
        }
        //product modifier
        if(cartModel.cartNotifierItem[i].orderModifierDetail!.isNotEmpty){
          cartProductItem cartItem = cartModel.cartNotifierItem[i];
          for(int j = 0; j < cartItem.orderModifierDetail!.length; j++){
            bytes += generator.row([
              PosColumn(text: '', width: 2),
              PosColumn(text: '+${cartItem.orderModifierDetail![j].mod_name!}',
                  width: 10,
                  containsChinese: true,
                  styles: PosStyles(
                    width: PosTextSize.size1,
                    height: checklistLayout.other_font_size == 0 ? PosTextSize.size2 : PosTextSize.size1,
                  )),
            ]);
          }
        }
        /*
        * product remark
        * */
        bytes += generator.reset();
        if (cartModel.cartNotifierItem[i].remark != '') {
          bytes += generator.row([
            PosColumn(text: '', width: 2),
            PosColumn(text: '**${cartModel.cartNotifierItem[i].remark}',
                width: 10,
                containsChinese: true,
                styles: PosStyles(
                    align: PosAlign.left,
                    height: checklistLayout.other_font_size == 0 ? PosTextSize.size2 : PosTextSize.size1,
                    width: PosTextSize.size1)),
          ]);
        }
        subtotal += double.parse(cartModel.cartNotifierItem[i].price!) * cartModel.cartNotifierItem[i].quantity!;
      }

      if(subtotal != 0 && checklistLayout.show_total_amount == 1) {
        bytes += generator.reset();
        bytes += generator.emptyLines(1);
        bytes += generator.text('Total: RM ${subtotal.toStringAsFixed(2)}',
            styles: PosStyles(
                align: PosAlign.right,
                height: checklistLayout.other_font_size == 0 ? PosTextSize.size2 : PosTextSize.size1,
                width: PosTextSize.size1
            )
        );
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