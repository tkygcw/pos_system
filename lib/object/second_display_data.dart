import 'cart_product.dart';

class SecondDisplayData {
  String? tableNo;
  List<cartProductItem>? itemList;
  String? subtotal;
  String? totalTax;
  String? totalDiscount;
  String? amount;
  String? rounding;
  String? finalAmount;

  SecondDisplayData({
    this.tableNo,
    this.itemList,
    this.subtotal,
    this.totalDiscount,
    this.totalTax,
    this.amount,
    this.rounding,
    this.finalAmount

  });

  static SecondDisplayData fromJson(Map<String, Object?> json) {
    var cartJson = json['itemList'] as List;
    List<cartProductItem> cartList = cartJson.map((tagJson) => cartProductItem.fromJson(tagJson)).toList();
    return SecondDisplayData (
      tableNo: json['tableNo'] as String?,
      itemList: cartList,
      subtotal: json['subtotal'] as String?,
      totalDiscount: json['totalDiscount'] as String?,
      totalTax: json['totalTax'] as String?,
      amount: json['amount'] as String?,
      rounding: json['rounding'] as String?,
      finalAmount: json['finalAmount'] as String?
    );
  }

  // Map<String, Object?> toJson() => {
  //   'tableNo': tableNo,
  //   //'itemList': itemList
  // };

  Map toJson() {
    List? itemList = this.itemList != null ? this.itemList?.map((i) => i.toJson()).toList() : null;
    return {
      'tableNo': tableNo,
      'itemList': itemList,
      'subtotal': subtotal,
      'totalDiscount': totalDiscount,
      'totalTax': totalTax,
      'amount': amount,
      'rounding': rounding,
      'finalAmount': finalAmount
    };
  }

}