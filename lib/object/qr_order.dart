import 'dart:convert';

import 'package:another_flushbar/flushbar.dart';
import 'package:assets_audio_player/assets_audio_player.dart';
import 'package:awesome_snackbar_content/awesome_snackbar_content.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pos_system/fragment/custom_snackbar.dart';
import 'package:pos_system/object/app_setting.dart';
import 'package:pos_system/object/qr_order_auto_accept.dart';
import 'package:pos_system/translation/AppLocalizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../database/domain.dart';
import '../database/pos_database.dart';
import 'branch_link_product.dart';
import 'categories.dart';
import 'order_cache.dart';
import 'order_detail.dart';
import 'order_modifier_detail.dart';

class QrOrder {
  int count = 0;

  getQrOrder(context) async {
    String categoryLocalId;
    DateFormat dateFormat = DateFormat("yyyy-MM-dd HH:mm:ss");
    String dateTime = dateFormat.format(DateTime.now());
    final prefs = await SharedPreferences.getInstance();
    final String? login_user = prefs.getString('user');
    final int? branch_id = prefs.getInt('branch_id');
    Map logInUser = json.decode(login_user!);
    AppSetting? localSetting = await PosDatabase.instance.readLocalAppSetting(branch_id.toString());

    Map response = await Domain().SyncQrOrderFromCloud(branch_id.toString(), logInUser['company_id'].toString());
    if (response['status'] == '1') {
      print('get qr order length: ${response['data'].length}');
      for(int i = 0; i < response['data'].length; i++){
        print('response table id: ${response['data'][i]['table_id']}');
        //PosTable tableData = await PosDatabase.instance.readTableByCloudId(response['data'][i]['table_id']);
        OrderCache? checkOrderCacheData = await PosDatabase.instance.readSpecificOrderCacheByKey(response['data'][i]['order_cache_key']);
        if(checkOrderCacheData != null){
          break;
        }
        OrderCache orderCache = OrderCache(
            order_cache_id: 0,
            order_cache_key: response['data'][i]['order_cache_key'].toString(),
            order_queue: '',
            company_id: response['data'][i]['company_id'].toString(),
            branch_id: response['data'][i]['branch_id'].toString(),
            order_detail_id: '',
            table_use_sqlite_id: '',
            table_use_key: '',
            batch_id: response['data'][i]['batch_id'].toString(),
            dining_id: response['data'][i]['dining_id'].toString(),
            order_sqlite_id: '',
            order_key: '',
            order_by: '',
            order_by_user_id: '',
            cancel_by: '',
            cancel_by_user_id: '',
            customer_id: response['data'][i]['customer_id'].toString(),
            total_amount: response['data'][i]['total_amount'].toString(),
            qr_order: 1,
            qr_order_table_sqlite_id: '',
            qr_order_table_id: response['data'][i]['table_id'],
            accepted: 1,
            sync_status: 1,
            created_at: dateTime,
            updated_at: '',
            soft_delete: ''
        );

        OrderCache data = await PosDatabase.instance.insertSqLiteOrderCache(orderCache);

        for(int j = 0; j < response['data'][i]['order_detail'].length; j++){
          BranchLinkProduct? branchLinkProductData =
          await PosDatabase.instance.readSpecificBranchLinkProductByCloudId(response['data'][i]['order_detail'][j]['branch_link_product_id'].toString());
          print('category id: ${response['data'][i]['order_detail'][j]['category_id'].toString()}');
          if(response['data'][i]['order_detail'][j]['category_id'].toString() != '0'){
            Categories catData = await PosDatabase.instance.readSpecificCategoryByCloudId(response['data'][i]['order_detail'][j]['category_id'].toString());
            categoryLocalId = catData.category_sqlite_id.toString();
          } else {
            categoryLocalId = '0';
          }

          OrderDetail orderDetail = OrderDetail(
            order_detail_id: 0,
            order_detail_key: response['data'][i]['order_detail'][j]['order_detail_key'],
            order_cache_sqlite_id: data.order_cache_sqlite_id.toString(),
            order_cache_key: response['data'][i]['order_cache_key'].toString(),
            branch_link_product_sqlite_id: branchLinkProductData != null ? branchLinkProductData.branch_link_product_sqlite_id.toString() : '',
            category_sqlite_id: categoryLocalId,
            category_name: response['data'][i]['order_detail'][j]['category_name'],
            productName: response['data'][i]['order_detail'][j]['product_name'],
            has_variant: response['data'][i]['order_detail'][j]['has_variant'],
            product_variant_name: response['data'][i]['order_detail'][j]['product_variant_name'],
            price: response['data'][i]['order_detail'][j]['price'],
            original_price: response['data'][i]['order_detail'][j]['original_price'],
            quantity: response['data'][i]['order_detail'][j]['quantity'],
            remark: response['data'][i]['order_detail'][j]['remark'],
            account: '',
            edited_by: '',
            edited_by_user_id: '',
            cancel_by: '',
            cancel_by_user_id: '',
            status: 0,
            unit: 'each',
            per_quantity_unit: '',
            sync_status: 1,
            created_at: dateTime,
            updated_at: '',
            soft_delete: '',
          );
          OrderDetail orderDetailData = await PosDatabase.instance.insertSqliteOrderDetail(orderDetail);

          if(response['data'][i]['order_detail'][j]['modifier'] != null){
            if(response['data'][i]['order_detail'][j]['modifier'].length > 0){
              for(int k = 0; k < response['data'][i]['order_detail'][j]['modifier'].length; k++){
                OrderModifierDetail modifierDetail = OrderModifierDetail(
                    order_modifier_detail_id: 0,
                    order_modifier_detail_key: response['data'][i]['order_detail'][j]['modifier'][k]['order_modifier_detail_key'].toString(),
                    order_detail_sqlite_id: orderDetailData.order_detail_sqlite_id.toString(),
                    order_detail_id: '0',
                    order_detail_key: response['data'][i]['order_detail'][j]['order_detail_key'],
                    mod_item_id: response['data'][i]['order_detail'][j]['modifier'][k]['mod_item_id'].toString(),
                    mod_name: response['data'][i]['order_detail'][j]['modifier'][k]['name'].toString(),
                    mod_price: response['data'][i]['order_detail'][j]['modifier'][k]['price'].toString(),
                    mod_group_id: response['data'][i]['order_detail'][j]['modifier'][k]['mod_group_id'].toString(),
                    sync_status: 1,
                    created_at: dateTime,
                    updated_at: '',
                    soft_delete: ''
                );
                OrderModifierDetail orderModifierDetailData = await PosDatabase.instance.insertSqliteOrderModifierDetail(modifierDetail);
              }
            }
          }
        }
      }
      // playSound();
      CustomSnackBar.instance.showSnackBar(
          title: "${AppLocalizations.of(context)?.translate('qr_order')}",
          description: "${AppLocalizations.of(context)?.translate('new_qr_order_received')}",
          contentType: ContentType.success,
          playSound: true,
          playtime: 2
      );
      // Flushbar(
      //   icon: Icon(Icons.notifications, size: 32, color: Colors.white),
      //   shouldIconPulse: false,
      //   title: "${AppLocalizations.of(context)?.translate('qr_order')}",
      //   message: "${AppLocalizations.of(context)?.translate('new_qr_order_received')}",
      //   duration: Duration(seconds: 4),
      //   backgroundColor: Colors.green,
      //   messageColor: Colors.white,
      //   flushbarPosition: FlushbarPosition.TOP,
      //   maxWidth: 350,
      //   margin: EdgeInsets.all(8),
      //   borderRadius: BorderRadius.circular(8),
      //   padding: EdgeInsets.fromLTRB(40, 20, 40, 20),
      //   onTap: (flushbar) {
      //     flushbar.dismiss(true);
      //   },
      // )..show(context);
    } else {
      return 1;
    }
    if(localSetting!.qr_order_auto_accept == 1){
      QrOrderAutoAccept(context).load();
    }
  }

  playSound() {
    final assetsAudioPlayer = AssetsAudioPlayer();
    assetsAudioPlayer.open(
      Audio("audio/notification.mp3"),
    );
  }
}