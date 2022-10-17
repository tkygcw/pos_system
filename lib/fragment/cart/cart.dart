import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';
import 'package:pos_system/fragment/cart/cart_dialog.dart';
import 'package:pos_system/fragment/cart/promotion_dialog.dart';
import 'package:pos_system/fragment/cart/remove_cart_dialog.dart';
import 'package:pos_system/notifier/cart_notifier.dart';
import 'package:pos_system/notifier/theme_color.dart';
import 'package:pos_system/object/branch_link_dining_option.dart';
import 'package:pos_system/object/branch_link_promotion.dart';
import 'package:pos_system/object/cart_product.dart';
import 'package:pos_system/object/dining_option.dart';
import 'package:pos_system/object/modifier_group.dart';
import 'package:pos_system/object/order_cache.dart';
import 'package:pos_system/object/order_detail.dart';
import 'package:pos_system/object/promotion.dart';
import 'package:pos_system/object/table_use.dart';
import 'package:pos_system/object/table_use_detail.dart';
import 'package:pos_system/object/tax_link_dining.dart';
import 'package:pos_system/object/variant_group.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../database/domain.dart';
import '../../database/pos_database.dart';
import '../../object/order_modifier_detail.dart';
import '../../object/table.dart';
import '../../translation/AppLocalizations.dart';

class CartPage extends StatefulWidget {
  final String currentPage;

  const CartPage({required this.currentPage, Key? key}) : super(key: key);

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  late StreamController controller;
  List<Promotion> promotionList = [];
  List<String> diningList = [];
  List<String> branchLinkDiningIdList = [];
  List<cartProductItem> sameCategoryItemList = [];
  List<Promotion> autoApplyPromotionList = [];
  List<TableUse> tableUseList = [];
  int diningOptionID = 0;
  int simpleIntInput = 0;
  int taxRate = 0;
  double total = 0.0;
  double promo = 0.0;
  double selectedPromo = 0.0;
  double selectedPromoAmount = 0.0;
  double priceIncSST = 0.0;
  double priceIncServiceTax = 0.0;
  double discountPrice = 0.0;
  double promoAmount = 0.0;
  double totalAmount = 0.0;
  double tableOrderPrice = 0.0;
  String selectedPromoRate = '';
  String promoName = '';
  String promoRate = '';
  String tableUseId = '';
  String orderCacheId = '';
  String? allPromo = '';
  bool hasPromo = false;
  bool hasSelectedPromo = false;
  Color font = Colors.black45;

  @override
  void initState() {
    print('refreshed');
    super.initState();
    controller = StreamController();
    readAllBranchLinkDiningOption();
    getPromotionData();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  void deactivate() {
    // TODO: implement deactivate
    controller.close();
    super.deactivate();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeColor>(builder: (context, ThemeColor color, child) {
      return Padding(
        padding: const EdgeInsets.all(8.0),
        child: Consumer<CartModel>(builder: (context, CartModel cart, child) {
          getSubTotal(cart);
          return Scaffold(
            resizeToAvoidBottomInset: false,
            appBar: AppBar(
              automaticallyImplyLeading: false,
              title: Row(
                children: [
                  Text('Bill',
                      style: TextStyle(fontSize: 20, color: Colors.black)),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text('Table: ${getSelectedTable(cart)}'),
                    ),
                  ),
                ],
              ),
              backgroundColor: Colors.white,
              actions: [
                Visibility(
                  visible: cart.selectedOption == 'Dine in' &&
                          widget.currentPage == 'menu'
                      ? true
                      : false,
                  child: IconButton(
                    tooltip: 'table',
                    icon: const Icon(
                      Icons.table_restaurant,
                    ),
                    color: color.backgroundColor,
                    onPressed: () {
                      //tableDialog(context);
                      openChooseTableDialog();
                    },
                  ),
                ),
                Visibility(
                  visible: widget.currentPage == 'menu' ? false : true,
                  child: IconButton(
                    tooltip: 'promotion',
                    icon: Icon(Icons.discount),
                    color: color.backgroundColor,
                    onPressed: () {
                      openPromotionDialog();
                    },
                  ),
                ),
                IconButton(
                  tooltip: 'clear cart',
                  icon: const Icon(
                    Icons.delete,
                  ),
                  color: color.backgroundColor,
                  onPressed: () {
                    cart.removeAllCartItem();
                    cart.removeAllTable();
                  },
                ),
                // PopupMenuButton<Text>(
                //     icon: Icon(Icons.more_vert, color: color.backgroundColor),
                //     itemBuilder: (context) {
                //       return [
                //         PopupMenuItem(
                //           child: Text(
                //             'test',
                //           ),
                //         ),
                //       ];
                //     })
              ],
            ),
            body: StreamBuilder(
                stream: controller.stream,
                builder: (context, snapshot) {
                  return Container(
                    decoration: BoxDecoration(
                      color: color.iconColor,
                      border:
                          Border.all(color: Colors.grey.shade100, width: 3.0),
                    ),
                    child: Column(
                      children: [
                        Padding(
                          padding: EdgeInsets.fromLTRB(10, 8, 14, 0),
                          child: Column(children: [
                            DropdownButton<String>(
                              onChanged: (value) {
                                setState(() {
                                  cart.selectedOption = value!;
                                });
                              },
                              value: cart.selectedOption,
                              // Hide the default underline
                              underline: Container(),
                              icon: Icon(
                                Icons.arrow_drop_down,
                                color: color.backgroundColor,
                              ),
                              isExpanded: true,
                              // The list of options
                              items: diningList
                                  .map((e) => DropdownMenuItem(
                                        child: Container(
                                          alignment: Alignment.centerLeft,
                                          child: Text(
                                            e,
                                            style: TextStyle(fontSize: 18),
                                          ),
                                        ),
                                        value: e,
                                      ))
                                  .toList(),
                              // Customize the selected item
                              selectedItemBuilder: (BuildContext context) =>
                                  diningList
                                      .map((e) => Center(child: Text(e)))
                                      .toList(),
                            ),
                          ]),
                        ),
                        Expanded(
                          child: Container(
                            height: 350,
                            child: ListView.builder(
                                shrinkWrap: true,
                                itemCount: cart.cartNotifierItem.length,
                                itemBuilder: (context, index) {
                                  return Dismissible(
                                    background: Container(
                                      color: Colors.red,
                                      padding: EdgeInsets.only(left: 25.0),
                                      child: Row(
                                        children: [
                                          Icon(Icons.delete,
                                              color: Colors.white),
                                        ],
                                      ),
                                    ),
                                    key: ValueKey(
                                        cart.cartNotifierItem[index].name),
                                    direction: DismissDirection.startToEnd,
                                    confirmDismiss: (direction) async {
                                      if (direction ==
                                          DismissDirection.startToEnd) {
                                        await openRemoveCartItemDialog(
                                            cart.cartNotifierItem[index]);
                                      }
                                      return null;
                                    },
                                    child: ListTile(
                                      hoverColor: Colors.transparent,
                                      onTap: () {},
                                      isThreeLine: true,
                                      title: RichText(
                                        text: TextSpan(
                                          children: <TextSpan>[
                                            TextSpan(
                                                text: cart
                                                        .cartNotifierItem[index]
                                                        .name +
                                                    '\n',
                                                style: TextStyle(
                                                    fontSize: 14,
                                                    color: cart
                                                                .cartNotifierItem[
                                                                    index]
                                                                .status ==
                                                            1
                                                        ? font
                                                        : color.backgroundColor,
                                                    fontWeight:
                                                        FontWeight.bold)),
                                            TextSpan(
                                                text: "RM" +
                                                    cart.cartNotifierItem[index]
                                                        .price,
                                                style: TextStyle(
                                                  fontSize: 13,
                                                  color: cart
                                                              .cartNotifierItem[
                                                                  index]
                                                              .status ==
                                                          1
                                                      ? font
                                                      : color.backgroundColor,
                                                )),
                                          ],
                                        ),
                                      ),
                                      subtitle: Text(
                                          getVariant(cart
                                                  .cartNotifierItem[index]) +
                                              getModifier(cart
                                                  .cartNotifierItem[index]) +
                                              getRemark(
                                                  cart.cartNotifierItem[index]),
                                          style: TextStyle(fontSize: 10)),
                                      trailing: Container(
                                        child: FittedBox(
                                          child: Row(
                                            children: [
                                              IconButton(
                                                  hoverColor:
                                                      Colors.transparent,
                                                  icon: Icon(Icons.remove),
                                                  onPressed: () {
                                                    cart.cartNotifierItem[index]
                                                                .quantity !=
                                                            1
                                                        ? setState(() => cart
                                                            .cartNotifierItem[
                                                                index]
                                                            .quantity--)
                                                        : null;
                                                  }),
                                              Text(cart.cartNotifierItem[index]
                                                  .quantity
                                                  .toString()),
                                              IconButton(
                                                  hoverColor:
                                                      Colors.transparent,
                                                  icon: Icon(Icons.add),
                                                  onPressed: () {
                                                    if (cart
                                                            .cartNotifierItem[
                                                                index]
                                                            .status ==
                                                        0) {
                                                      setState(() {
                                                        cart
                                                            .cartNotifierItem[
                                                                index]
                                                            .quantity++;
                                                      });
                                                    } else {
                                                      Fluttertoast.showToast(
                                                          backgroundColor:
                                                              Colors.red,
                                                          msg:
                                                              "order already placed!");
                                                    }

                                                    controller.add('refresh');
                                                  })
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                }),
                          ),
                        ),
                        SizedBox(height: 20),
                        Divider(
                          color: Colors.grey,
                          height: 1,
                          thickness: 1,
                          indent: 20,
                          endIndent: 20,
                        ),
                        SizedBox(height: 10),
                        ListView(
                          physics: NeverScrollableScrollPhysics(),
                          children: [
                            ListTile(
                              title: Text("Subtotal",
                                  style: TextStyle(fontSize: 14)),
                              trailing: Text('${total.toStringAsFixed(2)}',
                                  style: TextStyle(fontSize: 14)),
                              visualDensity: VisualDensity(vertical: -4),
                              dense: true,
                            ),
                            Visibility(
                              visible:
                                  cart.selectedPromotion != null ? true : false,
                              child: ListTile(
                                title: SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: Row(
                                    children: [
                                      Text('${allPromo} (${selectedPromoRate})',
                                          style: TextStyle(fontSize: 14)),
                                      IconButton(
                                        padding: EdgeInsets.only(left: 10),
                                        constraints: BoxConstraints(),
                                        icon: Icon(Icons.close),
                                        iconSize: 20.0,
                                        color: Colors.red,
                                        onPressed: () {
                                          cart.removePromotion();
                                          selectedPromo = 0.0;
                                          hasSelectedPromo = false;
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                                trailing: Text(
                                    '-${selectedPromo.toStringAsFixed(2)}',
                                    style: TextStyle(fontSize: 14)),
                                visualDensity: VisualDensity(vertical: -4),
                                dense: true,
                              ),
                            ),
                            Visibility(
                                visible: hasPromo == true ? true : false,
                                child: ListView.builder(
                                    shrinkWrap: true,
                                    itemCount: autoApplyPromotionList.length,
                                    itemBuilder: (context, index) {
                                      return ListTile(
                                          title: Text(
                                              '${autoApplyPromotionList[index].name} (${autoApplyPromotionList[index].promoRate})',
                                              style: TextStyle(fontSize: 14)),
                                          visualDensity:
                                              VisualDensity(vertical: -4),
                                          dense: true,
                                          trailing: Text(
                                              '-${autoApplyPromotionList[index].promoAmount!.toStringAsFixed(2)}',
                                              style: TextStyle(fontSize: 14)));
                                    })),
                            ListTile(
                              title: Text('Sst (6%)',
                                  style: TextStyle(fontSize: 14)),
                              trailing: Text(
                                  '${priceIncSST.toStringAsFixed(2)}',
                                  style: TextStyle(fontSize: 14)),
                              visualDensity: VisualDensity(vertical: -4),
                              dense: true,
                            ),
                            ListTile(
                              title: Text('Service Tax ($taxRate%)',
                                  style: TextStyle(fontSize: 14)),
                              trailing: Text(
                                  '${priceIncServiceTax.toStringAsFixed(2)}',
                                  style: TextStyle(fontSize: 14)),
                              visualDensity: VisualDensity(vertical: -4),
                              dense: true,
                            ),
                            ListTile(
                              visualDensity: VisualDensity(vertical: -4),
                              title: Text("Total",
                                  style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold)),
                              trailing: Text(
                                  "${totalAmount.toStringAsFixed(2)}",
                                  style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold)),
                              dense: true,
                            ),
                          ],
                          shrinkWrap: true,
                        ),
                        SizedBox(height: 10),
                        Divider(
                          color: Colors.grey,
                          height: 1,
                          thickness: 1,
                          indent: 20,
                          endIndent: 20,
                        ),
                        SizedBox(height: 10),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              primary: color.backgroundColor,
                              minimumSize: const Size.fromHeight(50), // NEW
                            ),
                            onPressed: () async {
                              if (widget.currentPage == 'menu') {
                                if (cart.selectedOption == 'Dine in') {
                                  if (cart.selectedTable.isNotEmpty &&
                                      cart.cartNotifierItem.isNotEmpty) {
                                    if (cart.cartNotifierItem[0].status == 1) {
                                      print('add new item');
                                      //await colorChecking();
                                      // await callAddOrderCache(cart);
                                      cart.removeAllCartItem();
                                      cart.removeAllTable();
                                    } else {
                                      print('add order cache');
                                      //await colorChecking();
                                      await callCreateNewOrder(cart);
                                      cart.removeAllCartItem();
                                      cart.removeAllTable();
                                    }
                                  } else {
                                    Fluttertoast.showToast(
                                        backgroundColor: Colors.red,
                                        msg:
                                            "make sure cart is not empty and table is selected");
                                  }
                                } else {
                                  cart.removeAllTable();
                                  if (cart.cartNotifierItem.isNotEmpty) {
                                    //await createOrderCache(cart);
                                    // await updatePosTable(cart);
                                    cart.removeAllCartItem();
                                    cart.selectedTable.clear();
                                  } else {
                                    Fluttertoast.showToast(
                                        backgroundColor: Colors.red,
                                        msg: "cart empty");
                                  }
                                }
                              } else {
                                print('make payment');
                              }
                            },
                            child: widget.currentPage == 'menu'
                                ? Text('Place Order')
                                : Text('Make payment'),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
          );
        }),
      );
    });
  }

/*
  -----------------------Cart-item-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
*/

/*
  Get Cart product modifier
*/
  getModifier(cartProductItem object) {
    List<String?> modifier = [];
    String result = '';
    for (int i = 0; i < object.modifier.length; i++) {
      ModifierGroup group = object.modifier[i];
      for (int j = 0; j < group.modifierChild.length; j++) {
        if (group.modifierChild[j].isChecked!) {
          modifier.add(group.modifierChild[j].name! + '\n');
          result = modifier
              .toString()
              .replaceAll('[', '')
              .replaceAll(']', '')
              .replaceAll(',', '+')
              .replaceFirst('', '+ ');
        }
      }
    }
    return result;
  }

/*
  Get Cart product variant
*/
  getVariant(cartProductItem object) {
    List<String?> variant = [];
    String result = '';
    for (int i = 0; i < object.variant.length; i++) {
      VariantGroup group = object.variant[i];
      for (int j = 0; j < group.child.length; j++) {
        if (group.child[j].isSelected!) {
          variant.add(group.child[j].name! + '\n');
          result = variant
              .toString()
              .replaceAll('[', '')
              .replaceAll(']', '')
              .replaceAll(',', '+')
              .replaceAll('|', '\n+')
              .replaceFirst('', '+ ');
        }
      }
    }
    return result;
  }

/*
  Get Remark
*/
  getRemark(cartProductItem object) {
    String result = '';
    if (object.remark != '') {
      result = '*' + object.remark.toString();
    }
    return result;
  }

/*
  Get Selected table
*/
  getSelectedTable(CartModel cart) {
    List<String> result = [];
    if (cart.selectedTable.isEmpty && cart.selectedOption == 'Dine in') {
      result.add('No table');
    } else if (cart.selectedOption != 'Dine in') {
      result.add('');
    } else {
      if (cart.selectedTable.length > 1) {
        for (int i = 0; i < cart.selectedTable.length; i++) {
          result.add('${cart.selectedTable[i].number}');
        }
      } else {
        result.add('${cart.selectedTable[0].number}');
      }
    }

    return result.toString().replaceAll('[', '').replaceAll(']', '');
  }

/*
  -----------------Calculation-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
*/
  calPromotion(CartModel cart) {
    promoAmount = 0.0;
    getAutoApplyPromotion(cart);
    getManualApplyPromotion(cart);
    controller.add('refresh');
  }

  getManualApplyPromotion(CartModel cart) {
    List<cartProductItem> _sameCategoryList = [];
    allPromo = '';
    selectedPromoRate = '';
    try {
      if (cart.selectedPromotion != null) {
        allPromo = cart.selectedPromotion!.name;
        if (cart.selectedPromotion!.type == 0) {
          selectedPromoRate = cart.selectedPromotion!.amount.toString() + '%';
        } else {
          selectedPromoRate = cart.selectedPromotion!.amount! + '.00';
        }

        if (cart.selectedPromotion!.specific_category == '1') {
          for (int i = 0; i < cart.cartNotifierItem.length; i++) {
            if (cart.cartNotifierItem[i].category_id ==
                cart.selectedPromotion!.category_id) {
              _sameCategoryList.add(cart.cartNotifierItem[i]);
            }
          }
          specificCategoryAmount(cart.selectedPromotion!, _sameCategoryList);
        } else {
          nonSpecificCategoryAmount(cart);
        }
      }
    } catch (error) {
      print('Get manual promotion error: $error');
    }
    controller.add('refresh');
  }

  specificCategoryAmount(Promotion promotion, List<cartProductItem> cartItem) {
    try {
      selectedPromo = 0.0;
      hasSelectedPromo = false;

      for (int j = 0; j < cartItem.length; j++) {
        if (promotion.type == 0) {
          hasSelectedPromo = true;
          selectedPromo +=
              (double.parse(cartItem[j].price) * cartItem[j].quantity) *
                  (double.parse(promotion.amount!) / 100);
        } else {
          hasSelectedPromo = true;
          selectedPromo +=
              (double.parse(promotion.amount!) * cartItem[j].quantity);
        }
      }
      promoAmount += selectedPromo;
    } catch (e) {
      print('Specific category offer amount error: $e');
      selectedPromo = 0.0;
    }
    controller.add('refresh');
  }

  nonSpecificCategoryAmount(CartModel cart) {
    try {
      selectedPromo = 0.0;
      hasSelectedPromo = false;

      if (cart.selectedPromotion!.type == 0) {
        hasSelectedPromo = true;
        selectedPromo = total * 0.10;
      } else {
        if (cart.cartNotifierItem.isNotEmpty) {
          for (int i = 0; i < cart.cartNotifierItem.length; i++) {
            hasSelectedPromo = true;
            selectedPromo += double.parse(cart.selectedPromotion!.amount!) *
                cart.cartNotifierItem[i].quantity;
          }
        }
      }
      promoAmount += selectedPromo;
    } catch (error) {
      print('check promotion type error: $error');
      selectedPromo = 0.0;
    }
    controller.add('refresh');
  }

  getAutoApplyPromotion(CartModel cart) {
    try {
      autoApplyPromotionList = [];
      promoName = '';
      hasPromo = false;
      //loop promotion list get promotion
      for (int j = 0; j < promotionList.length; j++) {
        promotionList[j].promoAmount = 0.0;
        if (promotionList[j].auto_apply == '1') {
          if (promotionList[j].specific_category == '1') {
            //Auto apply specific category promotion
            for (int m = 0; m < cart.cartNotifierItem.length; m++) {
              //check cart item status
              if (cart.cartNotifierItem[m].status == 0) {
                if (cart.cartNotifierItem[m].category_id ==
                    promotionList[j].category_id) {
                  hasPromo = true;
                  promoName = promotionList[j].name!;
                  if (!autoApplyPromotionList.contains(promotionList[j])) {
                    autoApplyPromotionList.add(promotionList[j]);
                  }
                  autoApplySpecificCategoryAmount(
                      promotionList[j], cart.cartNotifierItem[m]);
                }
              }
            }
          } else {
            //Auto apply non specific category promotion
            if (cart.cartNotifierItem.isNotEmpty) {
              for (int i = 0; i < cart.cartNotifierItem.length; i++) {
                if (cart.cartNotifierItem[i].status == 0) {
                  hasPromo = true;
                }
              }
              autoApplyPromotionList.add(promotionList[j]);
              promoName = promotionList[j].name!;
              autoApplyNonSpecificCategoryAmount(promotionList[j], cart);
            }
          }
        }
      }
    } catch (error) {
      print('Promotion error $error');
      promo = 0.0;
    }
    controller.add('refresh');
  }

  autoApplyNonSpecificCategoryAmount(Promotion promotion, CartModel cart) {
    try {
      promo = 0.0;
      for (int i = 0; i < cart.cartNotifierItem.length; i++) {
        if (cart.cartNotifierItem[i].status == 0) {
          if (promotion.type == 1) {
            promo += (double.parse(promotion.amount!) *
                cart.cartNotifierItem[i].quantity);
            promotion.promoAmount = promo;
            promoRate = 'RM' + promotion.amount!;
            promotion.promoRate = promoRate;
          } else {
            promo += (double.parse(cart.cartNotifierItem[i].price) *
                    cart.cartNotifierItem[i].quantity) *
                (double.parse(promotion.amount!) / 100);
            promotion.promoAmount = promo;
            promoRate = promotion.amount! + '%';
            promotion.promoRate = promoRate;
          }
        }
      }
      promoAmount += promo;
    } catch (e) {
      print("calc auto apply non specific error: $e");
      promoRate = '';
      promo = 0.0;
    }

    controller.add('refresh');
  }

  autoApplySpecificCategoryAmount(
      Promotion promotion, cartProductItem cartItem) {
    try {
      promo = 0.0;
      if (cartItem.status == 0) {
        if (promotion.type == 1) {
          promo += (double.parse(promotion.amount!) * cartItem.quantity);
          promotion.promoAmount = promotion.promoAmount! + promo;
          promoRate = 'RM' + promotion.amount!;
          promotion.promoRate = promoRate;
        } else {
          promo += (double.parse(cartItem.price) * cartItem.quantity) *
              (double.parse(promotion.amount!) / 100);
          promotion.promoAmount = promotion.promoAmount! + promo;
          promoRate = promotion.amount! + '%';
          promotion.promoRate = promoRate;
        }
      }
      //calculate promo total amount
      promoAmount += promo;
    } catch (e) {
      print("calc auto apply specific category error: $e");
      promoRate = '';
      promo = 0.0;
    }
    controller.add('refresh');
  }

  getDiningTax(CartModel cart) async {
    try {
      taxRate = 0;
      diningOptionID = 0;
      //get dining option data
      List<DiningOption> data =
          await PosDatabase.instance.checkSelectedOption(cart.selectedOption);
      diningOptionID = data[0].dining_id!;
      //get dining tax
      List<TaxLinkDining> TaxLinkDiningData =
          await PosDatabase.instance.readTaxLinkDining(data[0].dining_id!);
      if (TaxLinkDiningData.length > 0) {
        for (int i = 0; i < TaxLinkDiningData.length; i++) {
          taxRate = int.parse(TaxLinkDiningData[i].tax_rate!);
        }
      } else {
        taxRate = 0;
      }
    } catch (error) {
      print('get dining tax error: $error');
      taxRate = 0;
    }

    controller.add('refresh');
    return diningOptionID;
  }

  getSubTotal(CartModel cart) async {
    try {
      total = 0.0;
      promo = 0.0;
      promoAmount = 0.0;
      for (int i = 0; i < cart.cartNotifierItem.length; i++) {
        if (cart.cartNotifierItem[i].status == 0) {
          total += (double.parse((cart.cartNotifierItem[i].price)) *
              cart.cartNotifierItem[i].quantity);
        }
      }
    } catch (e) {
      print('Sub Total Error: $e');
      total = 0.0;
    }
    await getDiningTax(cart);
    // getCartPromotion(cart);
    // getAutoApplyPromotion(cart);
    calPromotion(cart);
    getSalesServiceTax();
    getServiceTax();
    getAllTotal();
    controller.add('refresh');
  }

  getSalesServiceTax() {
    try {
      priceIncServiceTax = 0.00;
      discountPrice = 0.00;

      discountPrice = total - promoAmount;
      priceIncSST = discountPrice * 0.06;
      priceIncSST = (priceIncSST * 100).truncate() / 100;
    } catch (error) {
      print('SST calculation error $error');
      priceIncSST = 0.0;
    }
    controller.add('refresh');
  }

  getServiceTax() {
    try {
      priceIncServiceTax = 0.0;
      discountPrice = 0.0;

      discountPrice = total - promoAmount;
      priceIncServiceTax = discountPrice * (taxRate / 100);
      priceIncServiceTax = (priceIncServiceTax * 100).truncate() / 100;
    } catch (error) {
      print('Service Tax error $error');
      priceIncServiceTax = 0.0;
    }

    controller.add('refresh');
  }

  getAllTotal() {
    try {
      totalAmount = 0.0;

      totalAmount = discountPrice + priceIncSST + priceIncServiceTax;
      totalAmount = (totalAmount * 100).truncate() / 100;
    } catch (error) {
      print('Total calc error: $error');
    }

    controller.add('refresh');
  }

/*
  ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
*/

  Future<Future<Object?>> openChooseTableDialog() async {
    return showGeneralDialog(
        barrierColor: Colors.black.withOpacity(0.5),
        transitionBuilder: (context, a1, a2, widget) {
          final curvedValue = Curves.easeInOutBack.transform(a1.value) - 1.0;
          return Transform(
            transform: Matrix4.translationValues(0.0, curvedValue * 200, 0.0),
            child: Opacity(
              opacity: a1.value,
              child: CartDialog(),
            ),
          );
        },
        transitionDuration: Duration(milliseconds: 200),
        barrierDismissible: false,
        context: context,
        pageBuilder: (context, animation1, animation2) {
          // ignore: null_check_always_fails
          return null!;
        });
  }

  Future<Future<Object?>> openPromotionDialog() async {
    return showGeneralDialog(
        barrierColor: Colors.black.withOpacity(0.5),
        transitionBuilder: (context, a1, a2, widget) {
          final curvedValue = Curves.easeInOutBack.transform(a1.value) - 1.0;
          return Transform(
            transform: Matrix4.translationValues(0.0, curvedValue * 200, 0.0),
            child: Opacity(
              opacity: a1.value,
              child: PromotionDialog(),
            ),
          );
        },
        transitionDuration: Duration(milliseconds: 200),
        barrierDismissible: false,
        context: context,
        pageBuilder: (context, animation1, animation2) {
          // ignore: null_check_always_fails
          return null!;
        });
  }

  Future<Future<Object?>> openRemoveCartItemDialog(cartProductItem item) async {
    return showGeneralDialog(
        barrierColor: Colors.black.withOpacity(0.5),
        transitionBuilder: (context, a1, a2, widget) {
          final curvedValue = Curves.easeInOutBack.transform(a1.value) - 1.0;
          return Transform(
            transform: Matrix4.translationValues(0.0, curvedValue * 200, 0.0),
            child: Opacity(
              opacity: a1.value,
              child: CartRemoveDialog(cartItem: item),
            ),
          );
        },
        transitionDuration: Duration(milliseconds: 200),
        barrierDismissible: false,
        context: context,
        pageBuilder: (context, animation1, animation2) {
          // ignore: null_check_always_fails
          return null!;
        });
  }

  readAllBranchLinkDiningOption() async {
    final prefs = await SharedPreferences.getInstance();
    final int? branch_id = prefs.getInt('branch_id');
    List<BranchLinkDining> data = await PosDatabase.instance
        .readBranchLinkDiningOption(branch_id!.toString());
    for (int i = 0; i < data.length; i++) {
      diningList.add(data[i].name!);
      branchLinkDiningIdList.add(data[i].dining_id!);
    }

    controller.add('refresh');
  }

  void getPromotionData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final int? branch_id = prefs.getInt('branch_id');
      List<BranchLinkPromotion> data = await PosDatabase.instance
          .readBranchLinkPromotion(branch_id.toString());

      for (int i = 0; i < data.length; i++) {
        List<Promotion> temp =
            await PosDatabase.instance.checkPromotion(data[i].promotion_id!);
        if (temp.length > 0) promotionList.add(temp[0]);
      }
    } catch (error) {
      print('promotion list error $error');
    }
  }

/*
  taylor part
*/
  // updatePosTable(CartModel cart) async {
  //   print('updated');
  //   DateFormat dateFormat = DateFormat("yyyy-MM-dd HH:mm:ss");
  //   String dateTime = dateFormat.format(DateTime.now());
  //   final prefs = await SharedPreferences.getInstance();
  //   final int? branch_id = prefs.getInt('branch_id');
  //
  //   for (int i = 0; i < cart.selectedTable.length; i++) {
  //     List<PosTable> result = await PosDatabase.instance
  //         .checkPosTableStatus(branch_id!, cart.selectedTable[i].table_id!);
  //     if (result[0].status == 0) {
  //       Map responseEditTableStatus = await Domain()
  //           .editTableStatus('1', cart.selectedTable[i].table_id.toString());
  //       if (responseEditTableStatus['status'] == '1') {
  //         PosTable posTableData = PosTable(
  //             table_id: cart.selectedTable[i].table_id,
  //             status: 1,
  //             updated_at: dateTime);
  //         int data =
  //             await PosDatabase.instance.updatePosTableStatus(posTableData);
  //       }
  //     }
  //   }
  // }

/*
  Taylor part
*/
  // createOrderCache(CartModel cart) async {
  //   print('create order cache called');
  //   DateFormat dateFormat = DateFormat("yyyy-MM-dd HH:mm:ss");
  //   String dateTime = dateFormat.format(DateTime.now());
  //   final prefs = await SharedPreferences.getInstance();
  //   final int? branch_id = prefs.getInt('branch_id');
  //   final String? user = prefs.getString('user');
  //   Map userObject = json.decode(user!);
  //   if (cart.selectedTable.length == 0) {
  //     Map responseInsertOrderCache = await Domain().insertOrderCache(
  //         userObject['company_id'].toString(),
  //         branch_id.toString(),
  //         '',
  //         diningOptionID.toString(),
  //         userObject['name'].toString(),
  //         totalAmount.toStringAsFixed(2));
  //     if (responseInsertOrderCache['status'] == '1') {
  //       OrderCache data = await PosDatabase.instance.insertSqLiteOrderCache(
  //           OrderCache(
  //               order_cache_id: responseInsertOrderCache['order'],
  //               company_id: userObject['company_id'],
  //               branch_id: branch_id.toString(),
  //               order_detail_id: '',
  //               table_id: '',
  //               dining_id: diningOptionID.toString(),
  //               order_id: '',
  //               order_by: userObject['name'].toString(),
  //               total_amount: totalAmount.toStringAsFixed(2),
  //               customer_id: '',
  //               created_at: dateTime,
  //               updated_at: '',
  //               soft_delete: ''));
  //
  //       for (int j = 0; j < cart.cartNotifierItem.length; j++) {
  //         Map responseInsertOrderDetail = await Domain().insertOrderDetail(
  //             responseInsertOrderCache['order'].toString(),
  //             cart.cartNotifierItem[j].branchProduct_id.toString(),
  //             cart.cartNotifierItem[j].name.toString(),
  //             cart.cartNotifierItem[j].variant.length == 0 ? '0' : '1',
  //             cart.cartNotifierItem[j].name.toString(),
  //             cart.cartNotifierItem[j].price.toString(),
  //             cart.cartNotifierItem[j].quantity.toString(),
  //             cart.cartNotifierItem[j].remark.toString(),
  //             '');
  //         if (responseInsertOrderDetail['status'] == '1') {
  //           OrderDetail detailData = await PosDatabase.instance
  //               .insertOrderDetail(OrderDetail(
  //                   order_detail_id: responseInsertOrderDetail['order'],
  //                   order_cache_id:
  //                       responseInsertOrderCache['order'].toString(),
  //                   branch_link_product_id:
  //                       cart.cartNotifierItem[j].branchProduct_id,
  //                   productName: cart.cartNotifierItem[j].name,
  //                   has_variant: cart.cartNotifierItem[j].variant.length == 0
  //                       ? '0'
  //                       : '1',
  //                   product_variant_name: cart.cartNotifierItem[j].name,
  //                   price: cart.cartNotifierItem[j].price,
  //                   quantity: cart.cartNotifierItem[j].quantity.toString(),
  //                   remark: cart.cartNotifierItem[j].remark,
  //                   account: '',
  //                   created_at: dateTime,
  //                   updated_at: '',
  //                   soft_delete: ''));
  //
  //           for (int k = 0; k < cart.cartNotifierItem[j].modifier.length; k++) {
  //             ModifierGroup group = cart.cartNotifierItem[j].modifier[k];
  //             for (int m = 0; m < group.modifierChild.length; m++) {
  //               if (group.modifierChild[m].isChecked!) {
  //                 Map responseInsertOrderModifierDetail = await Domain()
  //                     .insertOrderModifierDetail(
  //                         responseInsertOrderDetail['order'].toString(),
  //                         group.modifierChild[m].mod_item_id.toString(),
  //                         group.mod_group_id.toString());
  //                 if (responseInsertOrderModifierDetail['status'] == '1') {
  //                   OrderModifierDetail modifierData = await PosDatabase
  //                       .instance
  //                       .insertSqliteOrderModifierDetail(OrderModifierDetail(
  //                           order_modifier_detail_id:
  //                               responseInsertOrderModifierDetail['order'],
  //                           order_detail_id:
  //                               responseInsertOrderDetail['order'].toString(),
  //                           mod_item_id:
  //                               group.modifierChild[m].mod_item_id.toString(),
  //                           mod_group_id: group.mod_group_id.toString(),
  //                           created_at: dateTime,
  //                           updated_at: '',
  //                           soft_delete: ''));
  //                 }
  //               }
  //             }
  //           }
  //         }
  //       }
  //     }
  //   } else {
  //     for (int i = 0; i < cart.selectedTable.length; i++) {
  //       print(cart.selectedTable[i].table_id.toString());
  //       Map responseInsertOrderCache = await Domain().insertOrderCache(
  //           userObject['company_id'].toString(),
  //           branch_id.toString(),
  //           cart.selectedTable[i].table_id.toString(),
  //           diningOptionID.toString(),
  //           userObject['name'].toString(),
  //           totalAmount.toStringAsFixed(2));
  //       if (responseInsertOrderCache['status'] == '1') {
  //         OrderCache data = await PosDatabase.instance.insertSqLiteOrderCache(
  //             OrderCache(
  //                 order_cache_id: responseInsertOrderCache['order'],
  //                 company_id: userObject['company_id'],
  //                 branch_id: branch_id.toString(),
  //                 order_detail_id: '',
  //                 table_id: cart.selectedTable[i].table_id.toString(),
  //                 dining_id: diningOptionID.toString(),
  //                 order_id: '',
  //                 order_by: userObject['name'].toString(),
  //                 total_amount: totalAmount.toStringAsFixed(2),
  //                 customer_id: '',
  //                 created_at: dateTime,
  //                 updated_at: '',
  //                 soft_delete: ''));
  //
  //         for (int j = 0; j < cart.cartNotifierItem.length; j++) {
  //           Map responseInsertOrderDetail = await Domain().insertOrderDetail(
  //               responseInsertOrderCache['order'].toString(),
  //               cart.cartNotifierItem[j].branchProduct_id.toString(),
  //               cart.cartNotifierItem[j].name.toString(),
  //               cart.cartNotifierItem[j].variant.length == 0 ? '0' : '1',
  //               cart.cartNotifierItem[j].name.toString(),
  //               cart.cartNotifierItem[j].price.toString(),
  //               cart.cartNotifierItem[j].quantity.toString(),
  //               cart.cartNotifierItem[j].remark.toString(),
  //               '');
  //           if (responseInsertOrderDetail['status'] == '1') {
  //             OrderDetail detailData = await PosDatabase.instance
  //                 .insertOrderDetail(OrderDetail(
  //                     order_detail_id: responseInsertOrderDetail['order'],
  //                     order_cache_id:
  //                         responseInsertOrderCache['order'].toString(),
  //                     branch_link_product_id:
  //                         cart.cartNotifierItem[j].branchProduct_id,
  //                     productName: cart.cartNotifierItem[j].name,
  //                     has_variant: cart.cartNotifierItem[j].variant.length == 0
  //                         ? '0'
  //                         : '1',
  //                     product_variant_name: cart.cartNotifierItem[j].name,
  //                     price: cart.cartNotifierItem[j].price,
  //                     quantity: cart.cartNotifierItem[j].quantity.toString(),
  //                     remark: cart.cartNotifierItem[j].remark,
  //                     account: '',
  //                     created_at: dateTime,
  //                     updated_at: '',
  //                     soft_delete: ''));
  //
  //             for (int k = 0;
  //                 k < cart.cartNotifierItem[j].modifier.length;
  //                 k++) {
  //               ModifierGroup group = cart.cartNotifierItem[j].modifier[k];
  //               for (int m = 0; m < group.modifierChild.length; m++) {
  //                 if (group.modifierChild[m].isChecked!) {
  //                   Map responseInsertOrderModifierDetail = await Domain()
  //                       .insertOrderModifierDetail(
  //                           responseInsertOrderDetail['order'].toString(),
  //                           group.modifierChild[m].mod_item_id.toString(),
  //                           group.mod_group_id.toString());
  //                   if (responseInsertOrderModifierDetail['status'] == '1') {
  //                     OrderModifierDetail modifierData = await PosDatabase
  //                         .instance
  //                         .insertSqliteOrderModifierDetail(OrderModifierDetail(
  //                             order_modifier_detail_id:
  //                                 responseInsertOrderModifierDetail['order'],
  //                             order_detail_id:
  //                                 responseInsertOrderDetail['order'].toString(),
  //                             mod_item_id:
  //                                 group.modifierChild[m].mod_item_id.toString(),
  //                             mod_group_id: group.mod_group_id.toString(),
  //                             created_at: dateTime,
  //                             updated_at: '',
  //                             soft_delete: ''));
  //                   }
  //                 }
  //               }
  //             }
  //           }
  //         }
  //       }
  //     }
  //   }
  // }

/*
 leow part
*/
  callCreateNewOrder(CartModel cart) async {
    await createTableUseID();
    await createTableUseDetail(cart);
    await createOrderCache(cart);
    await createOrderDetail(cart);
    await updatePosTable(cart);
  }

  callAddOrderCache(CartModel cart) async {
    print('add product cache');
    await createOrderCache(cart);
    await createOrderDetail(cart);
  }

  /**
   * concurrent here
   */
  updatePosTable(CartModel cart) async {
    print('update table');
    DateFormat dateFormat = DateFormat("yyyy-MM-dd HH:mm:ss");
    String dateTime = dateFormat.format(DateTime.now());
    final prefs = await SharedPreferences.getInstance();
    final int? branch_id = prefs.getInt('branch_id');

    for (int i = 0; i < cart.selectedTable.length; i++) {
      List<PosTable> result = await PosDatabase.instance
          .checkPosTableStatus(branch_id!, cart.selectedTable[i].table_id!);
      if (result[0].status == 0) {
        PosTable posTableData = PosTable(
            table_id: cart.selectedTable[i].table_id,
            status: 1,
            updated_at: dateTime);
        int data =
            await PosDatabase.instance.updatePosTableStatus(posTableData);
      }
    }
  }

  colorToHex(Color color) {
    String hex = '#' + color.value.toRadixString(16).substring(2);
    return hex;
  }

  hexToInteger(String hexCode) {
    int temp = int.parse(hexCode, radix: 16);
    return temp;
  }

  randomColor(){
    return Color(Random().nextInt(0xffffffff));
  }

  colorChecking() async {
    String? hexCode;
    bool colorFound = false;
    bool found = false;
    int tempColor = 0;
    int matchColor = 0;
    int diff = 0;
    final prefs = await SharedPreferences.getInstance();
    final int? branch_id = prefs.getInt('branch_id');
    List<TableUse> data = await PosDatabase.instance.readAllTableUseId(branch_id!);

    while (colorFound == false) {
      /* change color */
      hexCode = colorToHex(randomColor());
      if(data.length > 0){
        for (int i = 0; i < data.length; i++) {
          if (hexCode == data[i].cardColor) {
            found = false;
            break;
          }else {
            tempColor = hexToInteger(hexCode!.replaceAll('#', ''));
            matchColor = hexToInteger(data[i].cardColor!.replaceAll('#', ''));
            diff = tempColor - matchColor;
            if (diff.abs() < 150000) {
              print('color too close or not yet loop finish');
              print('diff: ${diff.abs()}');
              i--;
              found = false;
              break;

            } else {
              print('color is ok');
              print('diff: ${diff}');
              i++;
              if(i == data.length){
                found = true;
                break;
              }
            }
          }
        }
      } else {
        found = true;
        break;
      }

      if (found == true) colorFound = true;
    }
    return hexCode;
  }

  /**
   * concurrent here
   */
  createTableUseID() async {
    print('create table use id called');
    DateFormat dateFormat = DateFormat("yyyy-MM-dd HH:mm:ss");
    String dateTime = dateFormat.format(DateTime.now());
    final prefs = await SharedPreferences.getInstance();
    final int? branch_id = prefs.getInt('branch_id');
    String? hexCode;
    tableUseId = '';
    try {
      hexCode = await colorChecking();
      if (hexCode != null) {
        //create table use data
        TableUse tableUseData = await PosDatabase.instance.insertSqliteTableUse(
            TableUse(
                table_use_id: 9,
                branch_id: branch_id,
                cardColor: hexCode.toString(),
                created_at: dateTime,
                updated_at: '',
                soft_delete: ''));
        tableUseId = tableUseData.table_use_id.toString();
      }
    } catch (e) {
      Fluttertoast.showToast(
          backgroundColor: Color(0xFFFF0000),
          msg: "Create table id error: ${e}");
    }
    return tableUseId;
  }

  /**
   * concurrent here
   */
  createTableUseDetail(CartModel cart) async {
    DateFormat dateFormat = DateFormat("yyyy-MM-dd HH:mm:ss");
    String dateTime = dateFormat.format(DateTime.now());
    try {
      for (int i = 0; i < cart.selectedTable.length; i++) {
        //create table use detail
        TableUseDetail tableUseDetailData = await PosDatabase.instance
            .insertSqliteTableUseDetail(TableUseDetail(
                table_use_detail_id: 9,
                table_use_id: tableUseId,
                table_id: cart.selectedTable[i].table_id.toString(),
                original_table_id: cart.selectedTable[i].table_id.toString(),
                created_at: dateTime,
                updated_at: '',
                soft_delete: ''));
      }
    } catch (e) {
      Fluttertoast.showToast(
          backgroundColor: Color(0xFFFF0000),
          msg: "Create table detail error: ${e}");
    }
  }

  /**
   * concurrent here
   */
  createOrderCache(CartModel cart) async {
    print('create order cache local called');
    DateFormat dateFormat = DateFormat("yyyy-MM-dd HH:mm:ss");
    String dateTime = dateFormat.format(DateTime.now());
    String _tableUseId = '';
    try {
      //check selected table is in use or not
      for (int i = 0; i < cart.selectedTable.length; i++) {
        List<TableUseDetail> useDetail = await PosDatabase.instance
            .readSpecificTableUseDetail(cart.selectedTable[i].table_id!);
        if (useDetail.length > 0) {
          _tableUseId = useDetail[0].table_use_id!;
        } else {
          _tableUseId = this.tableUseId;
        }
      }
      //create order cache
      OrderCache data = await PosDatabase.instance.insertSqLiteOrderCache(
          OrderCache(
              order_cache_id: 9,
              company_id: '6',
              branch_id: '5',
              order_detail_id: '',
              table_use_id: _tableUseId,
              table_id: '',
              dining_id: '1',
              order_id: '',
              order_by: '',
              customer_id: '0',
              total_amount: totalAmount.toStringAsFixed(2),
              created_at: dateTime,
              updated_at: '',
              soft_delete: ''));
      orderCacheId = data.order_cache_id.toString();
    } catch (e) {
      Fluttertoast.showToast(
          backgroundColor: Color(0xFFFF0000),
          msg: "Create order cache error: ${e}");
    }
    return orderCacheId;
  }

  /**
   * concurrent here
   */
  createOrderDetail(CartModel cart) async {
    DateFormat dateFormat = DateFormat("yyyy-MM-dd HH:mm:ss");
    String dateTime = dateFormat.format(DateTime.now());

    //loop cart item & create order detail
    for (int j = 0; j < cart.cartNotifierItem.length; j++) {
      if (cart.cartNotifierItem[j].status == 0) {
        OrderDetail detailData = await PosDatabase.instance
            .insertSqliteOrderDetail(OrderDetail(
                order_detail_id: 0,
                order_cache_id: orderCacheId,
                branch_link_product_id:
                    cart.cartNotifierItem[j].branchProduct_id,
                productName: cart.cartNotifierItem[j].name,
                has_variant:
                    cart.cartNotifierItem[j].variant.length == 0 ? '0' : '1',
                product_variant_name: cart.cartNotifierItem[j].name,
                price: cart.cartNotifierItem[j].price,
                quantity: cart.cartNotifierItem[j].quantity.toString(),
                remark: cart.cartNotifierItem[j].remark,
                account: '',
                created_at: dateTime,
                updated_at: '',
                soft_delete: ''));

        for (int k = 0; k < cart.cartNotifierItem[j].modifier.length; k++) {
          ModifierGroup group = cart.cartNotifierItem[j].modifier[k];
          for (int m = 0; m < group.modifierChild.length; m++) {
            if (group.modifierChild[m].isChecked!) {
              OrderModifierDetail modifierData = await PosDatabase.instance
                  .insertSqliteOrderModifierDetail(OrderModifierDetail(
                      order_modifier_detail_id: 0,
                      order_detail_id:
                          await detailData.order_detail_id.toString(),
                      mod_item_id:
                          group.modifierChild[m].mod_item_id.toString(),
                      mod_group_id: group.mod_group_id.toString(),
                      created_at: dateTime,
                      updated_at: '',
                      soft_delete: ''));
            }
          }
        }
      }
    }
  }
}
