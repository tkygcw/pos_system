import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:pos_system/fragment/cart/cart.dart';
import 'package:pos_system/fragment/cart/cart_dialog.dart';
import 'package:pos_system/fragment/product/product_order_dialog.dart';
import 'package:pos_system/notifier/cart_notifier.dart';
import 'package:pos_system/object/product.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../database/pos_database.dart';
import 'cart_product.dart';

class ServerAction {
  String? action;
  String? imagePath;

  ServerAction({this.action});

   encodeAllImage() async {
    List<String> encodedImage = [];
    final prefs = await SharedPreferences.getInstance();
    final String imagePath = prefs.getString('local_path')!;
    final directory = Directory(imagePath);
    final List<File> imageFiles = directory
        .listSync()
        .where((entity) => entity is File && entity.path.endsWith('.jpeg'))
        .map<File>((entity) => entity as File)
        .toList();

    // for (var file in imageFiles) {
    //   final imageBytes = file.readAsBytesSync();
    //   final base64Image = base64Encode(imageBytes);
    //   encodedImage.add(base64Image);
    // }
    final imageBytes = imageFiles[0].readAsBytesSync();
    final base64Image = base64Encode(imageBytes);
    encodedImage.add(base64Image);
    print('encoded image length: ${encodedImage.length}');
    return encodedImage;
  }

  checkAction({required String action, param}) async {
    final prefs = await SharedPreferences.getInstance();
    final int? branch_id = prefs.getInt('branch_id');
    Map<String, dynamic>? result;
    Map<String, dynamic>? objectData;

    try{
      switch(action){
        case '1': {
          var data = await PosDatabase.instance.readAllCategories();
          var data2 = await PosDatabase.instance.readAllClientProduct();
          var data3 = await PosDatabase.instance.readAllUser();
          var data4 = await PosDatabase.instance.readAllBranchLinkProduct();
          var data5 = await PosDatabase.instance.readAllBranchLinkModifier();
          var data6 = await PosDatabase.instance.readAllProductVariant();
          //List<String> encodedList = await encodeAllImage();
          objectData = {
            'tb_categories': data,
            'tb_product': data2,
            'tb_user': data3,
            'tb_branch_link_product': data4,
            'tb_branch_link_modifier': data5,
            'tb_product_variant': data6,
            //'image_list': encodedList,
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
          objectData = {
            'dining_list': cartPageState.diningList,
            'branch_link_dining_id_list': cartPageState.branchLinkDiningIdList,
            'promotion_list': cartPageState.promotionList
          };
          result = {'status': '1', 'data': objectData};

        }
        break;
        case '7': {
          CartDialogState state = CartDialogState();
          await state.readAllTable(isServerCall: true);
          // await state.readAllTableAmount();
          objectData = {
            'table_list': state.tableList,
          };
          result = {'status': '1', 'data': objectData};
        }
        break;
        case '8': {
          // List<String> encodedList = await encodeAllImage();
          // objectData = {
          //   'image_list': encodedList,
          // };
          // result = {'status': '1','data':objectData};
        }
        break;
        case '9': {
          try{
            CartModel cart = CartModel();
            CartPageState cartPageState = CartPageState();
            var decodeParam = jsonDecode(param);
            var cartJson = decodeParam as List;
            List<cartProductItem> cartList = cartJson.map((tagJson) => cartProductItem.fromJson(tagJson)).toList();
            cart.addAllItem(cartItemList: cartList);
            print("cart list length: ${cart.cartNotifierItem[0].product_name}");
            cart.selectedOption = 'Take Away';
            await cartPageState.readAllPrinters();
            await cartPageState.getSubTotalMultiDevice(cart);
            await cartPageState.callCreateNewNotDineOrder2(cart);
            result = {'status': '1'};
          } catch(e){
            result = {'status': '4'};
            print('place order request error: $e');
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