import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../database/pos_database.dart';
import '../object/table.dart';

class TableModel extends ChangeNotifier {
  static final TableModel instance = TableModel.init();
  List<PosTable> notifierTableList = [];
  bool isChange = false;

  TableModel.init();

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

  readAllTable() async {
    final prefs = await SharedPreferences.getInstance();
    List<PosTable> data = await PosDatabase.instance.readAllTable();
    notifierTableList = List.from(data);
  }
}