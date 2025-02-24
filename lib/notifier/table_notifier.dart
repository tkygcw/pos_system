import 'package:flutter/material.dart';

import '../database/pos_database.dart';
import '../object/order_cache.dart';
import '../object/table.dart';

class TableModel extends ChangeNotifier {
  static final TableModel instance = TableModel._init();
  List<PosTable> notifierTableList = [];
  OrderCache? _inPaymentOrderCache;
  bool isChange = false;

  OrderCache? get inPaymentOrderCache => _inPaymentOrderCache;

  set setInPaymentOrderCache(OrderCache? value) {
    _inPaymentOrderCache = value;
  }

  TableModel._init();

  void initialLoad() async {
    print('table notifier called');
    notifyListeners();
  }

  void changeContent(bool action) async {
    print('change content changed in model');
    isChange = action;
    notifyListeners();
  }

  void changeContent2(bool action) async {
    isChange = action;
  }

}