import 'dart:convert';
import 'dart:io';

import 'package:flutter/rendering.dart';
import 'package:pos_system/fragment/cart/cart.dart';
import 'package:pos_system/fragment/cart/cart_dialog.dart';
import 'package:pos_system/fragment/product/product_order_dialog.dart';
import 'package:pos_system/notifier/cart_notifier.dart';
import 'package:pos_system/object/product.dart';
import 'package:pos_system/object/table.dart';
import 'package:pos_system/object/tax_link_dining.dart';
import 'package:pos_system/second_device/cart_dialog_function.dart';
import 'package:pos_system/second_device/place_order.dart';
import 'package:pos_system/second_device/table_function.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../database/pos_database.dart';
import 'cart_product.dart';

class ServerAction {
  String? action;
  String? imagePath;

  ServerAction({this.action});

  Future<String> encodeImage(String imageName) async {
    final prefs = await SharedPreferences.getInstance();
    final String imagePath = prefs.getString('local_path')!;
    final imageBytes = await File(imagePath + '/' + imageName).readAsBytes();
    final base64Image = base64Encode(imageBytes);
    return base64Image;
  }

  Future<Map<String, dynamic>?> checkAction({required String action, param}) async {
    final prefs = await SharedPreferences.getInstance();
    final int? branch_id = prefs.getInt('branch_id');
    Map<String, dynamic>? result;
    Map<String, dynamic>? objectData;

    try{
      switch(action){
        case '0': {
          objectData = {
            'image_name': await encodeImage(param)
          };
          result = {'status': '1','data': objectData};
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
          objectData = {
            'tb_categories': data,
            'tb_product': data2,
            'tb_user': data3,
            'tb_branch_link_product': data4,
            'tb_branch_link_modifier': data5,
            'tb_product_variant': data6,
            'tb_app_setting': data7,
            'tb_branch_link_dining_option': data8
          };
          result = {'status': '1','data': objectData};
        }
        break;
        case '2': {
          var parameter = jsonDecode(param);
          Product product = Product.fromJson(parameter);
          ProductOrderDialogState state = ProductOrderDialogState();
          await state.readProductVariant(product.product_sqlite_id!); //await PosDatabase.instance.readSpecificTableToJson(param);
          await state.readProductModifier(product.product_sqlite_id!);
          await state.getProductPrice(product.product_sqlite_id!);
          await PosDatabase.instance.readSpecificCategoryById(product.category_sqlite_id!);
          objectData = {
            'variant': state.variantGroup,
            'modifier': state.modifierGroup,
            'final_price': state.finalPrice,
            'base_price': state.basePrice,
            'dialog_price': state.dialogPrice,
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
          CartPageState cartPageState = CartPageState();
          await cartPageState.readAllBranchLinkDiningOption(serverCall: 1);
          await cartPageState.getPromotionData();
          List<TaxLinkDining> taxLinkDiningList = await PosDatabase.instance.readAllTaxLinkDining();
          objectData = {
            'dining_list': cartPageState.diningList,
            'branch_link_dining_id_list': cartPageState.branchLinkDiningIdList,
            'promotion_list': cartPageState.promotionList,
            'taxLinkDiningList': taxLinkDiningList
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
            PlaceOrder order = PlaceOrder();
            await order.readAllPrinters();
            var decodeParam = jsonDecode(param);
            cart = CartModel.fromJson(decodeParam);
            if(cart.selectedOption == 'Dine in'){
              await order.callCreateNewOrder(cart);
            } else {
              await order.callCreateNewNotDineOrder(cart);
            }
            result = {'status': '1'};
          } catch(e){
            result = {'status': '4'};
            print('place order request error: $e');
          }
        }
        break;
        case '9': {
          try{
            CartModel cart = CartModel();
            PlaceOrder order = PlaceOrder();
            await order.readAllPrinters();
            var decodeParam = jsonDecode(param);
            cart = CartModel.fromJson(decodeParam);
            await order.callAddOrderCache(cart);
            result = {'status': '1'};
          } catch(e){
            result = {'status': '4'};
            print('add order request error: $e');
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
            result = {'status': '1'};
          }catch(e){
            result = {'status': '4'};
            print("cart dialog remove merged table request error: $e");
          }
        }
        break;
        case '12': {
          try{
            CartDialogFunction function = CartDialogFunction();
            var jsonValue = jsonDecode(param);
            print("json value: ${jsonValue['dragTableId']}");
            await function.callMergeTableQuery(dragTableId: jsonValue['dragTableId'], targetTableId: jsonValue['targetTableId']);
            result = {'status': '1'};
          }catch(e){
            result = {'status': '4'};
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
      }
      return result;
    } catch(e){
      print('server error: $e');
      result = {'status': '2'};
      return result;
    }
  }
}