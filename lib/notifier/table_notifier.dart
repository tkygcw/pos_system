import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../database/pos_database.dart';
import '../object/table.dart';

class TableModel extends ChangeNotifier {
  List<PosTable> notifierTableList = [];
  bool isChange = false;

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
    final int? branch_id = prefs.getInt('branch_id');
    List<PosTable> data = await PosDatabase.instance.readAllTable(branch_id!.toInt());
    notifierTableList = List.from(data);
  }
}