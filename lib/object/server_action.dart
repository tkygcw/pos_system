import 'dart:convert';
import 'dart:io';

import 'package:f_logs/model/flog/flog.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pos_system/fragment/cart/cart.dart';
import 'package:pos_system/fragment/product/product_order_dialog.dart';
import 'package:pos_system/notifier/cart_notifier.dart';
import 'package:pos_system/object/branch_link_product.dart';
import 'package:pos_system/object/order_detail.dart';
import 'package:pos_system/object/product.dart';
import 'package:pos_system/object/promotion.dart';
import 'package:pos_system/object/table.dart';
import 'package:pos_system/second_device/cart_dialog_function.dart';
import 'package:pos_system/second_device/place_order.dart';
import 'package:pos_system/second_device/reprint_kitchen_list_function.dart';
import 'package:pos_system/second_device/table_function.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../database/pos_database.dart';
import '../main.dart';
import 'branch_link_promotion.dart';

class ServerAction {
  String? action;
  String? imagePath;

  ServerAction({this.action});

  Future<String> encodeImage(String imageName) async {
    String imagePath;
    final prefs = await SharedPreferences.getInstance();
    final String? user = prefs.getString('user');
    Map userObject = json.decode(user!);
    // final String imagePath = prefs.getString('local_path')!;
    if(Platform.isIOS){
      String dir = await _localPath;
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
    Map<String, dynamic>? result;
    Map<String, dynamic>? objectData;

    try{
      switch(action){
        case '-1': {
          String status = '';
          var branchId = jsonDecode(param);
          print("branchId: ${branchId}");
          print("server branch id: ${branch_id.toString()}");
          if(branchId.toString() == branch_id.toString()){
            status = '1';
          } else {
            status = '2';
          }
          print("status: $status");
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
             'app_language_code': data11
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
            CartDialogFunction function = CartDialogFunction();
            await function.readAllTable();
            objectData = {
              'table_list': function.tableList,
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
            if(cart.selectedOption == 'Dine in'){
              PlaceNewDineInOrder order = PlaceNewDineInOrder();
              Map<String, dynamic>? cartItem = await order.checkOrderStock(cart);
              if(cartItem != null){
                return result = cartItem;
              }
              result = await order.callCreateNewOrder(cart, address!, decodeParam['order_by'], decodeParam['order_by_user_id']);
            } else {
              PlaceNotDineInOrder order = PlaceNotDineInOrder();
              Map<String, dynamic>? cartItem = await order.checkOrderStock(cart);
              if(cartItem != null){
                return result = cartItem;
              }
              result = await order.callCreateNewNotDineOrder(cart, address!, decodeParam['order_by'], decodeParam['order_by_user_id']);
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
            PlaceAddOrder order = PlaceAddOrder();
            var decodeParam = jsonDecode(param);
            cart = CartModel.fromJson(decodeParam['cart']);
            Map<String, dynamic>? cartItem = await order.checkOrderStock(cart);
            if(cartItem != null){
              return result = cartItem;
            }
            result = await order.callAddOrderCache(cart, address!, decodeParam['order_by'], decodeParam['order_by_user_id']);
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
          CartDialogFunction function = CartDialogFunction();
          await function.readSpecificTableDetail(posTable);
          objectData = {
            'order_detail': function.orderDetailList,
            'order_cache': function.orderCacheList,
            //'pos_table': data3,
          };
          result = {'status': '1', 'data':objectData};
        }
        break;
        case '11': {
          try{
            CartDialogFunction function = CartDialogFunction();
            var jsonValue = param;
            await function.callRemoveTableQuery(int.parse(jsonValue));
            result = {'status': '1', 'data': jsonValue};
          }catch(e){
            result = {'status': '4', 'exception': e.toString()};
            print("cart dialog remove merged table request error: $e");
          }
        }
        break;
        case '12': {
          try{
            CartDialogFunction function = CartDialogFunction();
            var jsonValue = jsonDecode(param);
            print("json value: ${jsonValue['dragTableId']}");
            int status = await function.callMergeTableQuery(dragTableId: jsonValue['dragTableId'], targetTableId: jsonValue['targetTableId']);
            if(status == 1){
              result = {'status': '1'};
            } else {
              result = {'status': '2', 'error': "Table status changed"};
            }
          }catch(e){
            result = {'status': '4', 'exception': e.toString()};
            print("cart dialog remove merged table request error: $e");
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
          }catch(e){
            result = {'status': '4'};
            print("cart dialog remove merged table request error: $e");
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
      }
      return result;
    } catch(e){
      print('server error: $e');
      result = {'status': '2'};
      return result;
    }
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