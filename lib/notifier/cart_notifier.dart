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
  String selectedOptionId = '';
  bool isInit = false;
  int myCount = 0;
  bool isChange = false;

  void initialLoad() {
    removeAllTable();
    removeAllCartItem();
    removePromotion();
    removeAutoPromotion();
    removePaymentDetail();
    selectedOption = 'Dine in';
    //selectedOptionId = '1';
    notifyListeners();
  }

  void notDineInInitLoad(){
    removeAllTable();
    removeAllCartItem();
    removeAutoPromotion();
    removePromotion();
    removePaymentDetail();
    selectedOption = 'Take Away';
    //selectedOptionId = '2';
    notifyListeners();
  }

  void resetCount(){
    myCount = 0;
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
    print('add item called');
    cartNotifierItem.add(object);
    //notifyListeners();
  }

  void addAllItem({required List<cartProductItem> cartItemList}) {
    cartNotifierItem = cartItemList;
    //notifyListeners();
  }

  void removeItem(cartProductItem object) {
    cartNotifierItem.remove(object);
    notifyListeners();
  }

  void removeSpecificItem(cartProductItem object){
    for(int i = 0; i < cartNotifierItem.length; i++){
      if(object.order_cache_sqlite_id == cartNotifierItem[i].order_cache_sqlite_id){
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

  void removePartialCartItem(){
    List<cartProductItem> _removeItem = [];
    for(int j = 0; j < cartNotifierItem.length; j++){
      if(cartNotifierItem[j].status == 0){
        _removeItem.add(cartNotifierItem[j]);
      }
    }
    cartNotifierItem.removeWhere((element) => _removeItem.contains(element));
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