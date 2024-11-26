import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:pos_system/object/cart_payment.dart';
import 'package:pos_system/object/cart_product.dart';
import 'package:pos_system/object/order_cache.dart';
import 'package:pos_system/object/promotion.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../database/pos_database.dart';
import '../object/branch_link_dining_option.dart';
import '../object/table.dart';

class CartModel extends ChangeNotifier {
  List<cartProductItem> cartNotifierItem = [];
  List<cartPaymentDetail> cartNotifierPayment = [];
  List<Promotion> autoPromotion = [];
  Promotion? selectedPromotion;
  List<PosTable> selectedTable = [];
  List<OrderCache> selectedOrderQueue = [];
  String selectedOption = '';
  String selectedOptionId = '';
  String selectedOptionOrderKey = '';
  String? subtotal;
  bool isInit = false;
  bool isChange = false;
  List<String> groupList = [];
  List<OrderCache> _currentOrderCache = [];
  int _scrollDown = 0;

  int get scrollDown => _scrollDown;

  set setScrollDown(int value) {
    _scrollDown = value;
  }

  List<OrderCache> get currentOrderCache => _currentOrderCache;

  CartModel({
    List<cartProductItem>? cartNotifierItem,
    List<cartPaymentDetail>? cartNotifierPayment,
    List<PosTable>? selectedTable,
    String? selectedOption,
    String? selectedOptionId,
    String? selectedOptionOrderKey,
    String? subtotal
  }){
    this.groupList = groupList ?? [];
    this.selectedTable = selectedTable ?? [];
    this.cartNotifierItem = cartNotifierItem ?? [];
    this.selectedOption = selectedOption ?? '';
    this.selectedOptionId = selectedOptionId ?? '';
    this.selectedOptionOrderKey = selectedOptionOrderKey ?? '';
    this.subtotal = subtotal;
    this.cartNotifierPayment = cartNotifierPayment ?? [];
  }

  static CartModel fromJson(Map<String, Object?> json) {
    var tableJson = json['selectedTable'] as List;
    var cartItemJson = json['cartNotifierItem'] as List;
    List<cartProductItem> cartNotifierItem = cartItemJson.map((tagJson) => cartProductItem.fromJson(tagJson)).toList();
    List<PosTable> selectedTable = tableJson.map((e) => PosTable.fromJson(e)).toList();
    return CartModel(
        selectedTable: selectedTable,
        cartNotifierItem: cartNotifierItem,
        selectedOption: json['selectedOption'] as String?,
        selectedOptionId: json['selectedOptionId'] as String?,
        selectedOptionOrderKey: json['selectedOptionOrderKey'] as String?,
        subtotal: json['subtotal'] as String?
    );
  }

  readAllBranchLinkDiningOption() async {
    final prefs = await SharedPreferences.getInstance();
    final int? branch_id = prefs.getInt('branch_id');
    List<BranchLinkDining> data = await PosDatabase.instance.readBranchLinkDiningOption(branch_id!.toString());

    if (data.any((item) => item.name == 'Dine in')) {
      selectedOption = 'Dine in';
    } else {
      selectedOption = "Take Away";
    }
  }

  void initialLoad() {
    removeAllTable();
    removeAllCartItem();
    removePromotion();
    removeAutoPromotion();
    removePaymentDetail();
    readAllBranchLinkDiningOption();
    _currentOrderCache.clear();
    removeAllGroupList();
    //selectedOptionId = '1';
    selectedOptionOrderKey = '';
    notifyListeners();
  }

  void notDineInInitLoad() {
    removeAllTable();
    removeAllCartItem();
    removeAutoPromotion();
    removePromotion();
    removePaymentDetail();
    _currentOrderCache.clear();
    selectedOption = 'Take Away';
    //selectedOptionId = '2';
    selectedOptionOrderKey = '';
    notifyListeners();
  }

  void resetCount() {
    _scrollDown = 0;
    notifyListeners();
  }

  void changInit(bool action) {
    isInit = action;
    notifyListeners();
  }

  void setInit(bool action) {
    isInit = action;
  }

  void setSelectedOption(String option) {
    selectedOption = option;
    notifyListeners();
  }

  void removePaymentDetail() {
    cartNotifierPayment.clear();
    notifyListeners();
  }

  void addPaymentDetail(cartPaymentDetail object) {
    cartNotifierPayment.add(object);
    notifyListeners();
  }

  void addItem(cartProductItem object) {
    cartNotifierItem.add(object);
    _scrollDown = 0;
    notifyListeners();
  }

  void addAllItem({required List<cartProductItem> cartItemList}) {
    cartNotifierItem.addAll(cartItemList);
    notifyListeners();
  }

  void overrideItem({required List<cartProductItem> cartItem, bool? notify = true}) {
    List<cartProductItem> notPlacedItem = cartNotifierItem.where((e) => e.status == 0).toList();
    cartNotifierItem = cartItem;
    cartNotifierItem.addAll(notPlacedItem);
    _scrollDown = 0;
    if(notify = true){
      notifyListeners();
    }
  }

  void removeItem(cartProductItem object) {
    cartNotifierItem.remove(object);
    notifyListeners();
  }

  void removeSpecificItem(cartProductItem object) {
    for (int i = 0; i < cartNotifierItem.length; i++) {
      if (object.order_cache_sqlite_id == cartNotifierItem[i].order_cache_sqlite_id) {
        cartNotifierItem.removeAt(i);
        break;
      }
    }
    notifyListeners();
  }

  void removeAllCartItem() {
    cartNotifierItem.clear();
    notifyListeners();
  }

  void removePartialCartItem() {
    List<cartProductItem> _removeItem = [];
    for (int j = 0; j < cartNotifierItem.length; j++) {
      if (cartNotifierItem[j].status == 0) {
        _removeItem.add(cartNotifierItem[j]);
      }
    }
    cartNotifierItem.removeWhere((element) => _removeItem.contains(element));
    notifyListeners();
  }

  void addToGroupList(String tableGroupList) {
    groupList.add(tableGroupList);
    notifyListeners();
  }

  void removeAllGroupList() {
    groupList.clear();
    notifyListeners();
  }

  void removeSpecificGroupList(String tableGroupList) {
    groupList.remove(tableGroupList);
    notifyListeners();
  }

  bool checkGroupListContain(String tableGroupList) {
    bool contains = groupList.contains(tableGroupList);
    notifyListeners();
    return contains;
  }

  void removeCartItemBasedOnOrderCache(String orderCacheSqliteId){
    cartNotifierItem.removeWhere((e) => e.order_cache_sqlite_id == orderCacheSqliteId);
    notifyListeners();
  }

  void addTable(PosTable posTable) {
    selectedTable.add(posTable);
    notifyListeners();
  }

  void overrideSelectedTable(List<PosTable> tableList, {bool? notify = true}){
    selectedTable = tableList.toList();
    if(notify == true){
      notifyListeners();
    }
  }

  void removeAllTable() {
    selectedTable.clear();
    notifyListeners();
  }

  void removeSpecificTable(PosTable posTable) {
    for (int i = 0; i < selectedTable.length; i++) {
      if (posTable.table_id == selectedTable[i].table_id) {
        selectedTable.removeAt(i);
        break;
      }
    }
    notifyListeners();
  }

  void addOrder(OrderCache orderCache) {
    selectedOrderQueue.add(orderCache);
    notifyListeners();
  }

  void addPromotion(Promotion promo) {
    selectedPromotion = promo;
    notifyListeners();
  }

  void removePromotion() {
    selectedPromotion = null;
    notifyListeners();
  }

  void addAutoApplyPromo(Promotion promo) {
    autoPromotion.add(promo);
    //notifyListeners();
  }

  void removeAutoPromotion() {
    autoPromotion.clear();
    notifyListeners();
  }

  void removeAllPromotion() {
    autoPromotion.clear();
    selectedPromotion = null;
    notifyListeners();
  }

  void refresh() {
    notifyListeners();
  }

  void overrideCartOrderCache(List<OrderCache> orderCacheList){
    _currentOrderCache = orderCacheList;
  }

  void addAllCartOrderCache(List<OrderCache> orderCacheList){
    _currentOrderCache.addAll(orderCacheList);
  }

  void addCartOrderCache(OrderCache orderCache){
    _currentOrderCache.add(orderCache);
  }

  void removeSpecificOrderCache(OrderCache orderCache){
    _currentOrderCache.removeWhere((e) => e.order_cache_sqlite_id == orderCache.order_cache_sqlite_id);
  }

  void removeCartOrderCache(List<OrderCache> orderCacheList){
    for(final cache in orderCacheList){
      _currentOrderCache.removeWhere((e) => e.order_cache_sqlite_id == cache.order_cache_sqlite_id);
    }
  }

  void removeAllCartOrderCache(){
    _currentOrderCache.clear();
  }
}
