import 'dart:convert';
import 'dart:io';

import 'package:f_logs/model/flog/flog.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pos_system/fragment/cart/cart.dart';
import 'package:pos_system/fragment/product/product_order_dialog.dart';
import 'package:pos_system/notifier/app_setting_notifier.dart';
import 'package:pos_system/notifier/cart_notifier.dart';
import 'package:pos_system/object/branch_link_product.dart';
import 'package:pos_system/object/dining_option.dart';
import 'package:pos_system/object/order_cache.dart';
import 'package:pos_system/object/order_detail.dart';
import 'package:pos_system/object/payment_link_company.dart';
import 'package:pos_system/object/product.dart';
import 'package:pos_system/object/promotion.dart';
import 'package:pos_system/object/table.dart';
import 'package:pos_system/object/tax_link_dining.dart';
import 'package:pos_system/second_device/cart_dialog_function.dart';
import 'package:pos_system/second_device/order/dine_in_order.dart';
import 'package:pos_system/second_device/order/place_order.dart';
import 'package:pos_system/second_device/other_order/other_order_function.dart';
import 'package:pos_system/second_device/payment/payment_function.dart';
import 'package:pos_system/second_device/promotion/promotion_function.dart';
import 'package:pos_system/second_device/reprint_kitchen_list_function.dart';
import 'package:pos_system/second_device/table_function.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:version/version.dart';

import '../database/pos_database.dart';
import '../main.dart';
import '../second_device/order/add_on_order.dart';
import '../second_device/order/not_dine_in_order.dart';
import 'branch_link_promotion.dart';
import 'order.dart';

class ServerAction {
  String? action;
  String? imagePath;
  List<PosTable> tableList = [];

  ServerAction({this.action});

  Future<String> encodeImage(String imageName) async {
    String imagePath;
    final prefs = await SharedPreferences.getInstance();
    final String? user = prefs.getString('user');
    Map userObject = json.decode(user!);
    // final String imagePath = prefs.getString('local_path')!;
    if(Platform.isIOS){
      Directory tempDir = await getApplicationSupportDirectory();
      String dir = tempDir.path;
      imagePath = dir + '/assets/${userObject['company_id']}';
    } else {
      imagePath = prefs.getString('local_path')!;
    }
    final imageBytes = await File(imagePath + '/' + imageName).readAsBytes();
    final base64Image = base64Encode(imageBytes);
    return base64Image;
  }

  Future<String> get _localPath async {
    final directory = await getApplicationSupportDirectory();
    return directory.path;
  }

  Future<Map<String, dynamic>?> checkAction({required String action, param, String? address}) async {
    final prefs = await SharedPreferences.getInstance();
    final int? branch_id = prefs.getInt('branch_id');
    String minVersion = '1.0.22';
    Map<String, dynamic>? result;
    Map<String, dynamic>? objectData;
    try{
      switch(action){
        case '-1': {
          String status = '';
          var jsonParam = jsonDecode(param);
          if(jsonParam['branch_id'].toString() == branch_id.toString()){
            status = '1';
          } else {
            status = '2';
          }
          //check supported version
          Version subPosAppVersion = Version.parse(jsonParam['app_version']);
          Version supportedVersion = Version.parse(minVersion);
          if(subPosAppVersion < supportedVersion){
            status = '3';
          }
          result = {'status': status};
        }
        break;
        case '0': {
          if(param != 'Null'){
            objectData = {
              'image_name': await encodeImage(param)
            };
            result = {'status': '1','data': objectData};
          }
        }
        break;
        case '1': {
          var data = await PosDatabase.instance.readAllCategories();
          var data2 = await PosDatabase.instance.readAllClientProduct();
          var data3 = await PosDatabase.instance.readAllUser();
          var data4 = await PosDatabase.instance.readAllBranchLinkProduct();
          var data5 = await PosDatabase.instance.readAllBranchLinkModifier();
          var data6 = await PosDatabase.instance.readAllProductVariant();
          var data7 = await PosDatabase.instance.readAppSetting();
          var data8 = await PosDatabase.instance.readBranchLinkDiningOption(branch_id!.toString());
          var data9 = await PosDatabase.instance.readAllTaxLinkDining();
          var data10 = await getBranchPromotionData();
          var data11 = appLanguage.appLocal.languageCode;
          var data12 = await PosDatabase.instance.readAllSubscription();

          print("data2 length: ${data2.length}");
           objectData = {
             'tb_categories': data,
             'tb_product': data2,
             'tb_user': data3,
             'tb_branch_link_product': data4,
             'tb_branch_link_modifier': data5,
             'tb_product_variant': data6,
             'tb_app_setting': data7,
             'tb_branch_link_dining_option': data8,
             'taxLinkDiningList': data9,
             'branchPromotionList': data10,
             'app_language_code': data11,
             'subscription_data': data12
          };
          result = {'status': '1', 'action': '1', 'data': objectData};
        }
        break;
        case '2': {
          var parameter = jsonDecode(param);
          Product product = Product.fromJson(parameter['product_detail']);
          ProductOrderDialogState state = ProductOrderDialogState();
          await state.readProductVariant(product.product_sqlite_id!);
          await state.readProductModifier(product.product_sqlite_id!, diningOptionId: parameter['dining_option_id']);
          List<BranchLinkProduct> data = await PosDatabase.instance.readBranchLinkSpecificProduct(product.product_sqlite_id.toString());
          objectData = {
            'variant': state.variantGroup,
            'modifier': state.modifierGroup,
            'branch_link_product': data
          };
          result = {'status': '1','data':objectData};
        }
        break;
        case '3': {
          var data = await PosDatabase.instance.verifyPosPin(param, branch_id.toString());
          objectData = {'tb_user': data};
          result = {'status': '1','data': data};
        }
        break;
        case '4': {
          var data = await PosDatabase.instance.readAllCategories();
          var data2 = await PosDatabase.instance.readAllClientProduct();
          objectData = {'tb_categories': data, 'tb_product': data2};
          result = {'status': '1','data': objectData};
        }
        break;
        case '5': {
          var data = await PosDatabase.instance.readSpecificProduct(param);
          objectData = {'tb_product2': data};
          result = {'status': '1','data': objectData};
        }
        break;
        case '6': {
          // List<Promotion> promotionList = [];
          // List<BranchLinkPromotion> data = await PosDatabase.instance.readBranchLinkPromotion();
          // for (int i = 0; i < data.length; i++) {
          //   promotionList = await PosDatabase.instance.checkPromotion(data[i].promotion_id!);
          // }
          CartPageState cartPageState = CartPageState();
          await cartPageState.readAllBranchLinkDiningOption(serverCall: 1);
          await cartPageState.getPromotionData();
          objectData = {
            'promotion_list': cartPageState.promotionList,
          };
          result = {'status': '1', 'data': objectData};

        }
        break;
        case '7': {
          try{
            SubPosCartDialogFunction function = SubPosCartDialogFunction();
            tableList = await PosDatabase.instance.readAllTable();
            List<Map<String, String>> tableOrderKeyList = [];
            for(int i = 0; i < tableList.length; i++){
              if(tableList[i].status == 1){
                List<OrderCache> data = await PosDatabase.instance.readTableOrderCache(tableList[i].table_use_key!);
                if(data.isNotEmpty){
                  if(data.first.order_key != null){
                    tableOrderKeyList.add({
                      'table_id': tableList[i].table_id.toString(),
                      'order_key': data.first.order_key ?? '',
                    });
                  }
                }
              }
            }
            await function.readAllTable();
            objectData = {
              'table_list': function.tableList,
              'table_order_key_list': tableOrderKeyList,
            };
            result = {'status': '1', 'data': objectData};
          }catch(e){
            result = {'status': '4'};
            print("cart dialog read all table error: $e");
          }
        }
        break;
        case '8': {
          try{
            CartModel cart = CartModel();
            var decodeParam = jsonDecode(param);
            cart = CartModel.fromJson(decodeParam['cart']);
            if(cart.selectedOption == 'Dine in' && AppSettingModel.instance.table_order != 0){
              result = await placeOrderFunction(PlaceDineInOrder(), cart, address!, decodeParam['order_by'], decodeParam['order_by_user_id']);
            } else {
              result = await placeOrderFunction(PlaceNotDineInOrder(), cart, address!, decodeParam['order_by'], decodeParam['order_by_user_id']);
            }
          } catch(e){
            result = {'status': '4', 'exception': "New-order error: ${e.toString()}"};
            FLog.error(
              className: "checkAction",
              text: "Server action 8 error",
              exception: "$e",
            );
          }
        }
        break;
        case '9': {
          try{
            CartModel cart = CartModel();
            var decodeParam = jsonDecode(param);
            cart = CartModel.fromJson(decodeParam['cart']);
            result = await placeOrderFunction(PlaceAddOrder(), cart, address!, decodeParam['order_by'], decodeParam['order_by_user_id']);
          } catch(e){
            result = {'status': '4', 'exception': "add-order error: ${e.toString()}"};
            FLog.error(
              className: "checkAction",
              text: "Server action 9 error",
              exception: "$e",
            );
          }
        }
        break;
        case '10': {
          var decodeParam = jsonDecode(param);
          PosTable posTable = PosTable.fromJson(decodeParam);
          SubPosCartDialogFunction function = SubPosCartDialogFunction();
          int status = await function.readSpecificTableDetail(posTable);
          if(status == 1){
            objectData = {
              'order_detail': function.orderDetailList,
              'order_cache': function.orderCacheList,
            };
            result = {'status': '1', 'data':objectData};
          } else {
            result = {'status': '2'};
          }
        }
        break;
        case '11': {
          try{
            SubPosCartDialogFunction function = SubPosCartDialogFunction();
            var jsonValue = param;
            int status = await function.callRemoveTableQuery(int.parse(jsonValue));
            switch(status){
              case 1: {
                result = {'status': '1', 'data': jsonValue};
              }break;
              case 2: {
                ///table not in used
                result = {'status': '2', 'error': 'table_not_in_used'};
              }break;
              case 3: {
                ///cannot remove last table
                print("case 3 called!!!");
                result = {'status': '2', 'error': 'cannot_remove_this_table'};
              }break;
              case 5: {
                ///table is in cart
                result = {'status': '3', 'error': 'table_is_in_payment'};
              }break;
            }
          }catch(e){
            result = {'status': '4', 'exception': e.toString()};
            FLog.error(
              className: "checkAction",
              text: "Server action 11 error",
              exception: "$e",
            );
          }
        }
        break;
        case '12': {
          try{
            SubPosCartDialogFunction function = SubPosCartDialogFunction();
            print("param: ${param}");
            var jsonValue = jsonDecode(param);
            print("json value: ${jsonValue['targetPosTable']}");
            int status = await function.callMergeTableQuery(
                dragTableId: jsonValue['dragTableId'],
                targetTable: PosTable.fromJson(jsonValue['targetPosTable'])
            );
            if(status == 1){
              result = {'status': '1'};
            } else if (status == 2) {
              result = {'status': '2', 'error': "table_status_changed"};
            } else if (status == 3) {
              result = {'status': '3', 'error': "table_is_in_payment"};
            } else if (status == 5){
              result = {'status': '2', 'error': "table_group_changed"};
            }
          }catch(e){
            result = {'status': '4', 'exception': e.toString()};
            FLog.error(
              className: "checkAction",
              text: "Server action 12 error",
              exception: "$e",
            );
          }
        }
        break;
        case '13': {
          try{
            TableFunction function = TableFunction();
            await function.readAllTable();
            objectData = {
              'table_list': function.tableList,
            };
            result = {'status': '1', 'data': objectData};
          }catch(e, s){
            result = {'status': '4'};
            FLog.error(
              className: "checkAction",
              text: "Server action 13 error",
              exception: "Error: $e, StackTrace: $s",
            );
          }
        }
        break;
        case '14': {
          try{
            ReprintKitchenListFunction reprintKitchenList = ReprintKitchenListFunction();
            var decodeParam = jsonDecode(param);
            List<OrderDetail> reprintList =  List<OrderDetail>.from(decodeParam.map((json) => OrderDetail.fromJson(json)));
            reprintKitchenList.printFailKitchenList(reprintList);
            result = {'status': '1'};
          }catch(e){
            result = {'status': '4'};
            print("reprint fail kitchen print list request error: $e");
          }
        }
        break;
        case '15': {
          try{
            var data1 = await PosDatabase.instance.readAllBranchLinkProduct();
            objectData = {
              'tb_branch_link_product': data1,
            };
            result = {'status': '1', 'action': '15', 'data': objectData};
          }catch(e){
            result = {'status': '4'};
            print("resend branch link product request error: $e");
          }
        }
        break;
        case '16': {
          try{
            var decodeParam = jsonDecode(param);
            PosTable posTable = PosTable.fromJson(decodeParam);
            TableFunction function = TableFunction();
            bool isTableInPayment = await function.checkIsTableSelectedInPaymentCart(posTable);
            if(isTableInPayment == true){
              result = {'status': '2', 'action': '16', 'error': 'table_is_in_payment'};
            } else {
              await function.readSpecificTableDetail(posTable);
              objectData = {
                'orderCacheList': function.orderCacheList,
                'orderDetailList': function.orderDetailList
              };
              result = {'status': '1', 'action': '16', 'data': objectData};
            }
          }catch(e, s){
            result = {'status': '4'};
            FLog.error(
              className: "checkAction",
              text: "Server action 16 error",
              exception: "Error: $e, StackTrace: $s",
            );
          }
        }
        break;
        case '17': {
          //get company payment method
          try{
            var function = PaymentFunction();
            List<PaymentLinkCompany> paymentMethod = await function.getCompanyPaymentMethod();
            objectData = {
              'paymentMethod': paymentMethod,
            };
            result = {'status': '1', 'action': '17', 'data': objectData};
          }catch(e, s){
            result = {'status': '4'};
            FLog.error(
              className: "checkAction",
              text: "Server action 17 error",
              exception: "Error: $e, StackTrace: $s",
            );
          }
        }
        break;
        case '18': {
          //get branch selected promotion
          try{
            var function = PromotionFunction();
            List<Promotion> promotion = await function.getBranchPromotion();
            objectData = {
              'promotion': promotion,
            };
            result = {'status': '1', 'action': '18', 'data': objectData};
          }catch(e, s){
            result = {'status': '4'};
            FLog.error(
              className: "checkAction",
              text: "Server action 18 error",
              exception: "Error: $e, StackTrace: $s",
            );
          }
        }
        break;
        case '19': {
          //make payment function
          try{
            var decodeParam = jsonDecode(param);
            int? close_by_user_id =  decodeParam['user_id'];
            String? ipay_result_code = decodeParam['ipayResultCode'];
            Order orderData = Order.fromJson(decodeParam['orderData']);
            var promoJson = decodeParam['promotion'] as List;
            var taxJson = decodeParam['tax'] as List;
            var orderCacheJson = decodeParam['orderCacheList'] as List;
            var posTableJson = decodeParam['selectedTable'] as List;
            List<Promotion>? promotionList = promoJson.isNotEmpty ? promoJson.map((tagJson) => Promotion.fromJson(tagJson)).toList() : [];
            List<TaxLinkDining>? taxList = taxJson.isNotEmpty ? taxJson.map((tagJson) => TaxLinkDining.fromJson(tagJson)).toList() : [];
            List<OrderCache>? orderCacheList = orderCacheJson.isNotEmpty ? orderCacheJson.map((tagJson) => OrderCache.fromJson(tagJson)).toList() : [];
            List<PosTable>? tableList = posTableJson.isNotEmpty ? posTableJson.map((tagJson) => PosTable.fromJson(tagJson)).toList() : [];
            PaymentFunction function = PaymentFunction(
              order: orderData,
              promotion: promotionList,
              taxLinkDining: taxList,
              orderCache: orderCacheList,
              tableList: tableList,
              ipayResultCode: ipay_result_code,
              user_id: close_by_user_id
            );
            if(function.ipayResultCode != null) {
              result = await function.ipayMakePayment();
            } else {
              result = await function.makePayment();
            }
          }catch(e, s){
            result = {'status': '4'};
            FLog.error(
              className: "checkAction",
              text: "Server action 19 error",
              exception: "Error: $e, StackTrace: $s",
            );
          }
        }
        break;
        case '20': {
          TableFunction().clearSubPosOrderCache(table_use_key: param);
          result = {'status': '1'};
        }
        break;
        case '21': {
          List<DiningOption> diningOption = await OtherOrderFunction().getDiningList();
          result = {'status': '1', 'data': diningOption};
        }
        break;
        case '22': {
          List<OrderCache> data = await OtherOrderFunction().getAllOtherOrder(param);
          result = {'status': '1', 'data': data};
        }
        break;
        case '23': {
          var decodeParam = jsonDecode(param);
          OrderCache orderCache = OrderCache.fromJson(decodeParam);
          List<OrderDetail> data = await OtherOrderFunction().readOrderCacheOrderDetail(orderCache);
          result = {'status': '1', 'data': data};
        }
        break;
      }
      return result;
    } catch(e){
      FLog.error(
        className: "server_action",
        text: "checkAction error",
        exception: e,
      );
      result = {'status': '2'};
      return result;
    }
  }

  Future<Map<String, dynamic>> placeOrderFunction(PlaceOrder orderType, cart, address, orderBy, orderByUserId) async {
    return await orderType.placeOrder(cart, address, orderBy, orderByUserId);
  }

  Future<List<Promotion>> getBranchPromotionData() async {
    List<Promotion> branchPromoList = [];
    try {
      List<BranchLinkPromotion> data = await PosDatabase.instance.readBranchLinkPromotion();
      for (int i = 0; i < data.length; i++) {
        List<Promotion> temp = await PosDatabase.instance.checkPromotion(data[i].promotion_id!);
        if(temp.isNotEmpty){
          branchPromoList.add(temp.first);
        }
      }
      return branchPromoList;
    } catch (error) {
      print('promotion list error $error');
      return branchPromoList = [];
    }
  }
}