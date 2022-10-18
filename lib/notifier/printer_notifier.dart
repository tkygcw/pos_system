import 'package:flutter/cupertino.dart';

import '../object/categories.dart';

class PrinterModel extends ChangeNotifier {
  List<String> printerList = [];
  String jsonPrinter = '';
  List<Categories> selectedCategories = [];


  void addPrinter(String object) {
    printerList.add(object);
    notifyListeners();
  }

  void addCategories(Categories categories) {
    selectedCategories.add(categories);
    notifyListeners();
  }

  void removeSpecificCategories(Categories categories){
    for(int i = 0; i < selectedCategories.length; i++){
      if(selectedCategories[i].category_id == categories.category_id)
      selectedCategories.removeAt(i);
      break;
    }

    notifyListeners();
  }

  void removeAllCategories(){
    selectedCategories.clear();
    notifyListeners();
  }

  void removeAllPrinter(){
    printerList.clear();
    notifyListeners();
  }
}