import 'package:flutter/cupertino.dart';

class PrinterModel extends ChangeNotifier {
  List<String> printerList = [];


  void initialLoad() async {
    notifyListeners();
  }

  void addPrinter(String object) {
    printerList.add(object);
    notifyListeners();
  }

  void removeAllPrinter(){
    printerList.clear();
    notifyListeners();
  }
}