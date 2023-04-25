import 'dart:io';

import 'package:flutter/material.dart';
import 'package:pos_system/notifier/cart_notifier.dart';
import 'package:pos_system/object/product.dart';

import '../fragment/product/product_order_dialog.dart';

class ProductSearchDelegate extends SearchDelegate{
  // Demo list to show querying
  // List<String> searchTerms = [
  //   "Apple",
  //   "Banana",
  //   "Mango",
  //   "Pear",
  //   "Watermelons",
  //   "Blueberries",
  //   "Pineapples",
  //   "Strawberries"
  // ];
  String? imagePath;
  List<Product>? productList;
  CartModel? cartModel;

  ProductSearchDelegate({
    this.productList,
    this.imagePath,
    this.cartModel
  });

  Future<Future<Object?>> openProductOrderDialog(Product product, CartModel cartModel, BuildContext context) async {
    return showGeneralDialog(
        barrierColor: Colors.black.withOpacity(0.5),
        transitionBuilder: (context, a1, a2, widget) {
          final curvedValue = Curves.easeInOutBack.transform(a1.value) - 1.0;
          return Transform(
            transform: Matrix4.translationValues(0.0, curvedValue * 200, 0.0),
            child: Opacity(
                opacity: a1.value,
                child: ProductOrderDialog(
                  cartModel: cartModel,
                  productDetail: product,
                )),
          );
        },
        transitionDuration: Duration(milliseconds: 200),
        barrierDismissible: false,
        context: context,
        pageBuilder: (context, animation1, animation2) {
          // ignore: null_check_always_fails
          return null!;
        });
  }

  @override
  List<Widget>? buildActions(BuildContext context) {
    // TODO: implement buildActions
    return [
      IconButton(
        onPressed: () {
          if(query.isEmpty){
            close(context, null);
          } else {
            query = '';
          }
        },
        icon: Icon(Icons.clear),
      ),
    ];
    //throw UnimplementedError();
  }

  @override
  Widget? buildLeading(BuildContext context) {
    // TODO: implement buildLeading
    return IconButton(
      onPressed: (){
        close(context, null);
      },
      icon: Icon(Icons.arrow_back),);
    //throw UnimplementedError();
  }

  @override
  Widget buildResults(BuildContext context) {
    // TODO: implement buildResults
    List<Product> matchQuery = [];
    print('product list: ${productList!.length}');
    for (int i = 0; i < productList!.length; i++) {
      if (productList![i].name!.toLowerCase().contains(query.toLowerCase())) {
        matchQuery.add(productList![i]);
      } else if (productList![i].SKU!.contains(query.toLowerCase())){
        matchQuery.add(productList![i]);
      }
    }
    return ListView.builder(
      itemCount: matchQuery.length,
      itemBuilder: (context, index) {
        var result = matchQuery[index].SKU! + '-' + matchQuery[index].name!;
        return ListTile(
          title: Text(result),
          leading: CircleAvatar(
              backgroundColor: Colors.grey.shade200,
              child: Image.file(File(imagePath! + '/' + matchQuery[index].image!))),
          onTap: (){
            close(context, null);
            openProductOrderDialog(matchQuery[index], cartModel!, context);
          },
        );
      },
    );
    throw UnimplementedError();
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    // TODO: implement buildSuggestions
    List<Product> matchQuery = [];
    for (int i = 0; i < productList!.length; i++) {
      if (productList![i].name!.toLowerCase().contains(query.toLowerCase())) {
        matchQuery.add(productList![i]);
      } else if (productList![i].SKU!.contains(query.toLowerCase())){
        matchQuery.add(productList![i]);
      }
    }
    if(query.isNotEmpty){
      return ListView.builder(
        itemCount: matchQuery.length,
        itemBuilder: (context, index) {
          var result = matchQuery[index].SKU! + ' ' + matchQuery[index].name!;
          return ListTile(
            title: Text(result),
            leading: CircleAvatar(
                backgroundColor: Colors.grey.shade200,
                child: Image.file(File(imagePath! + '/' + matchQuery[index].image!))),
            onTap: () {
              close(context, null);
              openProductOrderDialog(matchQuery[index], cartModel!, context);
            },
          );
        },
      );
    } else {
      return Container();
    }
  }
  
}