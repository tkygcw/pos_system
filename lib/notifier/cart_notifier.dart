import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:pos_system/object/cart_product.dart';
import 'package:pos_system/object/promotion.dart';

import '../object/table.dart';

class CartModel extends ChangeNotifier {
  List<cartProductItem> cartNotifierItem = [];
  List<Promotion> autoPromotion = [];
  Promotion? selectedPromotion ;
  List<PosTable> selectedTable = [];
  String selectedOption = 'Dine in';


  void initialLoad() async {
    notifyListeners();
  }

  void addItem(cartProductItem object) {
    cartNotifierItem.add(object);
    notifyListeners();
  }

  void removeItem(cartProductItem object) {
    cartNotifierItem.remove(object);
    notifyListeners();
  }

  void removeAllCartItem(){
    cartNotifierItem.clear();
    notifyListeners();
  }

  void addTable(PosTable posTable){
    selectedTable.add(posTable);
    notifyListeners();
  }

  void removeAllTable(){
    selectedTable.clear();
    notifyListeners();
  }

  void addPromotion(Promotion promo){
    selectedPromotion = promo;
    notifyListeners();
  }

  void removePromotion(){
    selectedPromotion = null;
    notifyListeners();
  }

  void addAutoApplyPromo(Promotion promo){
    autoPromotion.add(promo);
    notifyListeners();
  }

  void removeAutoPromotion(){
    autoPromotion.clear();
    notifyListeners();
  }


}