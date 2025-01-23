import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../database/pos_database.dart';
import '../../object/app_setting.dart';
import '../../object/branch_link_product.dart';
import '../../object/categories.dart';
import '../../object/dining_option.dart';
import '../../object/order.dart';
import '../../object/order_cache.dart';
import '../../object/order_detail.dart';
import '../../object/order_modifier_detail.dart';
import '../../object/order_payment_split.dart';

class OtherOrderFunction {
  final PosDatabase _posDatabase = PosDatabase.instance;


  readOrderCacheOrderDetail(OrderCache orderCache) async {
    List<OrderDetail> orderDetailList = [];
    if(orderCache.other_order_key != ''){
      List<OrderCache> data = await PosDatabase.instance.readOrderCacheByOtherOrderKey(orderCache.other_order_key!);
      for(int i = 0; i < data.length; i++) {
        orderDetailList.addAll(await _getOrderDetail(data[i]));
      }
    } else {
      orderDetailList = await _getOrderDetail(orderCache);
    }
    return orderDetailList;
  }

  Future<List<OrderDetail>> _getOrderDetail(OrderCache orderCache) async {
    List<OrderDetail> orderDetailList = await _posDatabase.readSpecificOrderDetailByOrderCacheId(orderCache.order_cache_sqlite_id.toString());
    if(orderDetailList.isNotEmpty){
      for (int k = 0; k < orderDetailList.length; k++) {
        //Get data from branch link product
        List<BranchLinkProduct> data = await _posDatabase.readSpecificBranchLinkProduct(orderDetailList[k].branch_link_product_sqlite_id!);
        if(data.isNotEmpty) {
          orderDetailList[k].allow_ticket = data[0].allow_ticket;
          orderDetailList[k].ticket_count = data[0].ticket_count;
          orderDetailList[k].ticket_exp = data[0].ticket_exp;
        }

        //Get product category
        if(orderDetailList[k].category_sqlite_id! == '0'){
          orderDetailList[k].product_category_id = '0';
        } else {
          Categories category = await _posDatabase.readSpecificCategoryByLocalId(orderDetailList[k].category_sqlite_id!);
          orderDetailList[k].product_category_id = category.category_id.toString();
        }
        //check order modifier
        await _getOrderModifierDetail(orderDetailList[k]);
      }
    }
    return orderDetailList;
  }

  _getOrderModifierDetail(OrderDetail orderDetail) async {
    try{
      List<OrderModifierDetail> modDetail = await _posDatabase.readOrderModifierDetail(orderDetail.order_detail_sqlite_id.toString());
      if (modDetail.isNotEmpty) {
        orderDetail.orderModifierDetail = modDetail;
      } else {
        orderDetail.orderModifierDetail = [];
      }
    }catch(e){
      print("getOrderModifierDetail error: $e");
      orderDetail.orderModifierDetail = [];
    }
  }

  Future<List<OrderCache>> getAllOtherOrder(String selectDiningOption) async {
    List<OrderCache> orderCacheList = [];
    final prefs = await SharedPreferences.getInstance();
    final String? user = prefs.getString('user');
    Map userObject = json.decode(user!);
    final int? branch_id = prefs.getInt('branch_id');
    AppSetting? localSetting = await _posDatabase.readLocalAppSetting(branch_id.toString());

    if(localSetting!.table_order == 2) {
      if (selectDiningOption == 'All') {
        orderCacheList = await _posDatabase.readOrderCacheNoDineInAdvanced(branch_id.toString(), userObject['company_id']);
      } else {
        orderCacheList = await _posDatabase.readOrderCacheSpecialAdvanced(selectDiningOption);
      }
    } else {
      if (selectDiningOption == 'All') {
        orderCacheList = await _posDatabase.readOrderCacheNoDineIn(branch_id.toString(), userObject['company_id']);
      } else {
        orderCacheList = await _posDatabase.readOrderCacheSpecial(selectDiningOption);
      }
    }

    for(int i = 0; i < orderCacheList.length; i++) {
      if(orderCacheList[i].order_key != '') {
        double amountPaid = 0;
        double total_amount = double.parse(orderCacheList[i].total_amount!);
        List<OrderPaymentSplit> orderSplit = await PosDatabase.instance.readSpecificOrderSplitByOrderKey(orderCacheList[i].order_key!);

        for(int k = 0; k < orderSplit.length; k++){
          amountPaid += double.parse(orderSplit[k].amount!);
        }

        List<Order> orderData = await PosDatabase.instance.readSpecificOrderByOrderKey(orderCacheList[i].order_key!);
        total_amount = double.parse(orderData[0].final_amount!);

        total_amount -= amountPaid;
        orderCacheList[i].total_amount = total_amount.toString();
      } else {
        if(orderCacheList[i].other_order_key !=''){
          List<OrderCache> data = await PosDatabase.instance.readOrderCacheByOtherOrderKey(orderCacheList[i].other_order_key!);
          double total_amount = 0;
          for(int j = 0; j < data.length; j++){
            total_amount += double.parse(data[j].total_amount!);
          }
          orderCacheList[i].total_amount = total_amount.toString();
        }
      }
    }
    return orderCacheList;
  }

  Future<List<DiningOption>> getDiningList() async{
    try{
      return await _posDatabase.readAllDiningOption();
    }catch(e){
      return [];
    }
  }
}