import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:pos_system/object/cart_payment.dart';
import 'package:pos_system/object/cart_product.dart';
import 'package:pos_system/object/promotion.dart';

import '../object/table.dart';

class CartModel extends ChangeNotifier {
  List<cartProductItem> cartNotifierItem = [];
  List<cartPaymentDetail> cartNotifierPayment  = [];
  List<Promotion> autoPromotion = [];
  Promotion? selectedPromotion ;
  List<PosTable> selectedTable = [];
  String selectedOption = 'Dine in';
  bool isInit = false;
  int count = 0;
  bool isChange = false;

  void initialLoad() {
    removeAllTable();
    removeAllCartItem();
    removePromotion();
    removePaymentDetail();
    notifyListeners();
  }

  void changInit(bool action) {
    isInit = action;
    notifyListeners();
  }

  void setInit(bool action) {
    isInit = action;
  }

  void setSelectedOption(String option){
    selectedOption = option;
    notifyListeners();
  }

  void removePaymentDetail(){
    cartNotifierPayment.clear();
    notifyListeners();
  }

  void addPaymentDetail(cartPaymentDetail object){
    cartNotifierPayment.add(object);
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

  void removeSpecificItem(cartProductItem object){
    for(int i = 0; i < cartNotifierItem.length; i++){
      if(object.orderCacheId == cartNotifierItem[i].orderCacheId){
        cartNotifierItem.removeAt(i);
        break;
      }
    }
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

  void removeSpecificTable(PosTable posTable){
    for(int i= 0; i < selectedTable.length; i++){
      if(posTable.table_id == selectedTable[i].table_id){
        selectedTable.removeAt(i);
        break;
      }
    }
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