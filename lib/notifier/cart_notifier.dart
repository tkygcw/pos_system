import 'package:flutter/cupertino.dart';
import 'package:pos_system/object/cart_product.dart';

class CartModel extends ChangeNotifier {
  List<cartProductItem> cartNotifierItem = [];

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
}