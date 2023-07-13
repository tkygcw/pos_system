import 'dart:async';
import 'dart:convert';
import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:pos_system/object/branch_link_modifier.dart';
import 'package:pos_system/object/branch_link_product.dart';
import 'package:pos_system/object/cart_product.dart';
import 'package:pos_system/object/categories.dart';
import 'package:pos_system/object/product.dart';
import 'package:pos_system/object/product_variant.dart';
import 'package:pos_system/object/variant_group.dart';
import 'package:pos_system/object/variant_item.dart';
import 'package:pos_system/page/progress_bar.dart';
import 'package:pos_system/utils/Utils.dart';
import 'package:provider/provider.dart';
import 'package:quantity_input/quantity_input.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../database/pos_database.dart';
import '../../notifier/cart_notifier.dart';
import '../../notifier/theme_color.dart';
import '../../object/modifier_group.dart';
import '../../object/modifier_item.dart';
import '../../translation/AppLocalizations.dart';
import '../cart/cart_dialog.dart';

class ProductOrderDialog extends StatefulWidget {
  final Product? productDetail;
  final CartModel cartModel;

  const ProductOrderDialog({Key? key, this.productDetail, required this.cartModel}) : super(key: key);

  @override
  ProductOrderDialogState createState() => ProductOrderDialogState();
}

class ProductOrderDialogState extends State<ProductOrderDialog> {
  Categories? categories;
  String branchLinkProduct_id = '';
  String basePrice = '';
  String finalPrice = '';
  String dialogPrice = '';
  int simpleIntInput = 1, pressed = 0;
  String modifierItemPrice = '';
  List<VariantGroup> variantGroup = [];
  List<ModifierGroup> modifierGroup = [];
  List<ModifierItem> checkedModItem = [];
  final remarkController = TextEditingController();
  final quantityController = TextEditingController();
  int checkedModifierLength = 0;

  bool checkboxValueA = false;
  bool isLoaded = false;
  bool hasPromo = false;
  bool hasStock = false;
  bool isButtonDisabled = false;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    productChecking();
    //getProductPrice(widget.productDetail?.product_id);
  }

  Widget variantGroupLayout(VariantGroup variantGroup) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(variantGroup.name!, style: TextStyle(fontWeight: FontWeight.bold)),
        for (int i = 0; i < variantGroup.child!.length; i++)
          RadioListTile<int?>(
            value: variantGroup.child![i].variant_item_sqlite_id,
            groupValue: variantGroup.variant_item_sqlite_id,
            onChanged: (ind) => setState(() {
              print('ind: ${ind}');
              variantGroup.variant_item_sqlite_id = ind;
            }),
            title: Text(variantGroup.child![i].name!),
            controlAffinity: ListTileControlAffinity.trailing,
          )
      ],
    );
  }

  Widget modifierGroupLayout(ModifierGroup modifierGroup, CartModel cart) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(modifierGroup.name!, style: TextStyle(fontWeight: FontWeight.bold)),
        for (int i = 0; i < modifierGroup.modifierChild!.length; i++)
          CheckboxListTile(
            title: Row(
              children: [
                Text('${modifierGroup.modifierChild![i].name!}'),
                Text(
                  ' (+RM ${Utils.convertTo2Dec(modifierGroup.modifierChild![i].price)})',
                  style: TextStyle(fontSize: 12),
                )
              ],
            ),
            value: modifierGroup.modifierChild![i].isChecked,
            onChanged: modifierGroup.modifierChild![i].mod_status! == '2'
                ? null
                : (isChecked) {
                    setState(() {
                      modifierGroup.modifierChild![i].isChecked = isChecked!;
                      addCheckedModItem(modifierGroup.modifierChild![i]);
                      //print('check item length: ${checkedModItem.length}');
                      // print('flavour ${modifierGroup.modifierChild[i].name},'
                      //     'is check ${modifierGroup.modifierChild[i].isChecked}, ${modifierGroup.modifierChild[i].mod_status}');
                    });
                  },
            controlAffinity: ListTileControlAffinity.trailing,
          )
      ],
    );
  }

  addCheckedModItem(ModifierItem modifierItem){
    if(modifierItem.isChecked == true){
      checkedModItem.add(modifierItem);
    } else {
      checkedModItem.remove(modifierItem);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeColor>(builder: (context, ThemeColor color, child) {
      return Consumer<CartModel>(builder: (context, CartModel cart, child) {
        return LayoutBuilder(builder: (context, constraints) {
          if (constraints.maxWidth > 800) {
            return this.isLoaded
                ? Center(
                    child: SingleChildScrollView(
                      child: AlertDialog(
                        title: Row(
                          children: [
                            Container(
                              constraints: BoxConstraints(maxWidth: 300),
                              child: Text(widget.productDetail!.name!,
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  )),
                            ),
                            Spacer(),
                            // Text("RM ${Utils.convertTo2Dec(dialogPrice)}",
                            //     style: TextStyle(
                            //       fontSize: 16,
                            //       fontWeight: FontWeight.bold,
                            //     )),
                          ],
                        ),
                        content: Container(
                          constraints: BoxConstraints(
                            maxHeight: MediaQuery.of(context).size.height > 500 ? 500.0 : MediaQuery.of(context).size.height / 2.5,
                          ),
                          height: MediaQuery.of(context).size.height > 500
                              ? 500.0
                              : MediaQuery.of(context).size.height / 2.5, // Change as per your requirement
                          width: MediaQuery.of(context).size.width / 3,
                          child: SingleChildScrollView(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                for (int i = 0; i < variantGroup.length; i++)
                                  variantGroupLayout(variantGroup[i]),
                                for (int j = 0; j < modifierGroup.length; j++)
                                  Visibility(
                                    visible: modifierGroup[j].modifierChild!.isNotEmpty && modifierGroup[j].dining_id == "" || modifierGroup[j].dining_id == cart.selectedOptionId ? true : false,
                                    child: modifierGroupLayout(modifierGroup[j], cart),
                                  ),
                                Column(
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.start,
                                        children: [
                                          Text(
                                            "Quantity",
                                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                          ),
                                        ],
                                      ),
                                    ),
                                    QuantityInput(
                                        inputWidth: 273,
                                        type: QuantityInputType.int,
                                        minValue: 1,
                                        acceptsZero: false,
                                        acceptsNegatives: false,
                                        decoration: InputDecoration(
                                          focusedBorder: OutlineInputBorder(
                                            borderSide: BorderSide(color: color.backgroundColor),
                                          ),
                                        ),
                                        buttonColor: color.backgroundColor,
                                        value: simpleIntInput,
                                        onChanged: (value) => setState(() => simpleIntInput = int.parse(value.replaceAll(',', ''))))
                                  ],
                                ),
                                Column(
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.fromLTRB(8, 30, 8, 10),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.start,
                                        children: [
                                          Text(
                                            "Remark",
                                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                          ),
                                        ],
                                      ),
                                    ),
                                    TextField(
                                      controller: remarkController,
                                      decoration: InputDecoration(
                                        focusedBorder: OutlineInputBorder(
                                          borderSide: BorderSide(color: color.backgroundColor),
                                        ),
                                      ),
                                      keyboardType: TextInputType.multiline,
                                      maxLines: null,
                                    )
                                  ],
                                )
                              ],
                            ),
                          ),
                        ),
                        actions: <Widget>[
                          SizedBox(
                            width: MediaQuery.of(context).size.width / 4,
                            height: MediaQuery.of(context).size.height / 12,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: color.backgroundColor,
                              ),
                              child: Text(
                                'Close',
                                style: TextStyle(color: Colors.white),
                              ),
                              onPressed: isButtonDisabled
                                  ? null
                                  : () {
                                      Navigator.of(context).pop();

                                      // Disable the button after it has been pressed
                                      setState(() {
                                        isButtonDisabled = true;
                                      });
                                    },
                            ),
                          ),
                          SizedBox(
                            width: MediaQuery.of(context).size.width / 4,
                            height: MediaQuery.of(context).size.height / 12,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: color.buttonColor,
                              ),
                              child: Text(
                                'ADD',
                                style: TextStyle(color: Colors.white),
                              ),
                              onPressed: isButtonDisabled
                                  ? null
                                  : () async {
                                      await checkProductStock(widget.productDetail!, cart);
                                      //await getBranchLinkProductItem(widget.productDetail!);
                                      if (hasStock) {
                                        if (cart.selectedOption == 'Dine in') {
                                          if(simpleIntInput > 0){
                                            if (cart.selectedTable.isNotEmpty) {
                                              // Disable the button after it has been pressed
                                              setState(() {
                                                isButtonDisabled = true;
                                              });
                                              await addToCart(cart);
                                              Navigator.of(context).pop();
                                            } else {
                                              openChooseTableDialog(cart);
                                            }
                                          } else {
                                            Fluttertoast.showToast(backgroundColor: Color(0xFFFF0000), msg: "Invalid qty input");
                                          }
                                        } else {
                                          // Disable the button after it has been pressed
                                          setState(() {
                                            isButtonDisabled = true;
                                          });
                                          await addToCart(cart);
                                          Navigator.of(context).pop();
                                        }
                                      } else {
                                        Fluttertoast.showToast(backgroundColor: Color(0xFFFF0000), msg: "Product variant sold out!");
                                      }
                                    },
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : CustomProgressBar();
          } else {
            ///mobile layout
            return Center(
              child: SingleChildScrollView(
                child: AlertDialog(
                  title: Row(
                    children: [
                      Container(
                        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width / 2),
                        child: Text(widget.productDetail!.name!,
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            )),
                      ),
                      Spacer(),
                      // Text("RM ${Utils.convertTo2Dec(widget.productDetail!.price!)}",
                      //     style: TextStyle(
                      //       fontSize: 16,
                      //       fontWeight: FontWeight.bold,
                      //     )),
                    ],
                  ),
                  content: this.isLoaded
                      ? Container(
                          height: MediaQuery.of(context).size.height, // Change as per your requirement
                          width: MediaQuery.of(context).size.width / 1.5,
                          child: SingleChildScrollView(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                for (int i = 0; i < variantGroup.length; i++)
                                  variantGroupLayout(variantGroup[i]),
                                for (int j = 0; j < modifierGroup.length; j++)
                                  Visibility(
                                    visible: modifierGroup[j].modifierChild!.isNotEmpty && modifierGroup[j].dining_id == "" || modifierGroup[j].dining_id == cart.selectedOptionId ? true : false,
                                    child: modifierGroupLayout(modifierGroup[j], cart),
                                  ),
                                Column(
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.start,
                                        children: [
                                          Text(
                                            "Quantity",
                                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                          ),
                                        ],
                                      ),
                                    ),
                                    QuantityInput(
                                        inputWidth: 273,
                                        acceptsNegatives: false,
                                        acceptsZero: false,
                                        minValue: 1,
                                        decoration: InputDecoration(
                                          focusedBorder: OutlineInputBorder(
                                            borderSide: BorderSide(color: color.backgroundColor),
                                          ),
                                        ),
                                        buttonColor: color.backgroundColor,
                                        value: simpleIntInput,
                                        onChanged: (value) => setState(() => simpleIntInput = int.parse(value.replaceAll(',', ''))))
                                  ],
                                ),
                                Column(
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.fromLTRB(8, 30, 8, 10),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.start,
                                        children: [
                                          Text(
                                            "Remark",
                                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                          ),
                                        ],
                                      ),
                                    ),
                                    TextField(
                                      controller: remarkController,
                                      decoration: InputDecoration(
                                        focusedBorder: OutlineInputBorder(
                                          borderSide: BorderSide(color: color.backgroundColor),
                                        ),
                                      ),
                                      keyboardType: TextInputType.multiline,
                                      maxLines: null,
                                    )
                                  ],
                                )
                              ],
                            ),
                          ),
                        )
                      : CustomProgressBar(),
                  actions: <Widget>[
                    SizedBox(
                      width: MediaQuery.of(context).size.width / 2.5,
                      height: MediaQuery.of(context).size.height / 10,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: color.backgroundColor),
                        child: Text('${AppLocalizations.of(context)?.translate('close')}'),
                        onPressed: isButtonDisabled
                            ? null
                            : () {
                                // Disable the button after it has been pressed
                                setState(() {
                                  isButtonDisabled = true;
                                });
                                Navigator.of(context).pop();
                              },
                      ),
                    ),
                    SizedBox(
                      width: MediaQuery.of(context).size.width / 2.5,
                      height: MediaQuery.of(context).size.height / 10,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: color.buttonColor,
                        ),
                        child: Text('${AppLocalizations.of(context)?.translate('add')}'),
                        onPressed: isButtonDisabled
                            ? null
                            : () async {
                                await checkProductStock(widget.productDetail!, cart);
                                //await getBranchLinkProductItem(widget.productDetail!);
                                if (hasStock == true) {
                                  if (cart.selectedOption == 'Dine in') {
                                    if(simpleIntInput > 0){
                                      if (cart.selectedTable.isNotEmpty) {
                                        // Disable the button after it has been pressed
                                        setState(() {
                                          isButtonDisabled = true;
                                        });
                                        await addToCart(cart);
                                        Navigator.of(context).pop();
                                      } else {
                                        openChooseTableDialog(cart);
                                      }
                                    } else {
                                      Fluttertoast.showToast(backgroundColor: Color(0xFFFF0000), msg: "Invalid qty input");
                                    }
                                  } else {
                                    // Disable the button after it has been pressed
                                    setState(() {
                                      isButtonDisabled = true;
                                    });
                                    await addToCart(cart);
                                    Navigator.of(context).pop();
                                  }
                                } else {
                                  Fluttertoast.showToast(backgroundColor: Color(0xFFFF0000), msg: "Product variant sold out!");
                                }
                              },
                      ),
                    ),
                  ],
                ),
              ),
            );
          }
        });
      });
    });
  }

  readProductVariant(int productID) async {
    //loop variant group first
    List<VariantGroup> data = await PosDatabase.instance.readProductVariantGroup(productID);
    for (int i = 0; i < data.length; i++) {
      variantGroup.add(VariantGroup(
          variant_group_sqlite_id: data[i].variant_group_sqlite_id,
          variant_group_id: data[i].variant_group_id,
          child: [],
          name: data[i].name));

      //loop variant child based on variant group id
      List<VariantItem> itemData = await PosDatabase.instance.readProductVariantItem(data[i].variant_group_sqlite_id!);
      List<VariantItem> itemChild = [];
      for (int j = 0; j < itemData.length; j++) {
        //pre-check radio button
        if (j == 0) {
          variantGroup[i].variant_item_sqlite_id = itemData[j].variant_item_sqlite_id;
        }
        //store all child into one list
        itemChild.add(VariantItem(
            variant_group_sqlite_id: itemData[j].variant_group_sqlite_id,
            variant_group_id: itemData[j].variant_group_id.toString(),
            name: itemData[j].name,
            variant_item_sqlite_id: itemData[j].variant_item_sqlite_id,
            variant_item_id: itemData[j].variant_item_id));
      }
      //assign list into group child
      variantGroup[i].child = itemChild;
    }
  }

  readProductModifier(int productID) async {
    List<ModifierGroup> data = await PosDatabase.instance.readProductModifierGroupName(productID);
    if(data.isNotEmpty){
      for (int i = 0; i < data.length; i++) {
        modifierGroup.add(ModifierGroup(
          modifierChild: [],
          name: data[i].name,
          mod_group_id: data[i].mod_group_id,
          dining_id: data[i].dining_id,
          compulsory: data[i].compulsory,
        ));

        List<ModifierItem> itemData = await PosDatabase.instance.readProductModifierItem(data[i].mod_group_id!);
        List<ModifierItem> modItemChild = [];

        for (int j = 0; j < itemData.length; j++) {
          modItemChild.add(ModifierItem(
              mod_group_id: data[i].mod_group_id.toString(),
              name: itemData[j].name!,
              mod_item_id: itemData[j].mod_item_id,
              mod_status: itemData[j].mod_status,
              isChecked: false));
        }
        if(modifierGroup[i].compulsory == '1' && modifierGroup[i].dining_id == widget.cartModel.selectedOptionId){
          for(int k = 0; k < modItemChild.length; k++){
            modItemChild[k].isChecked = true;
          }
          modifierGroup[i].modifierChild = modItemChild;
        }
        modifierGroup[i].modifierChild = modItemChild;
        await readProductModifierItemPrice(modifierGroup[i]);
      }
    }
  }

  readProductModifierItemPrice(ModifierGroup modGroup) async {
    modifierItemPrice = '';

    for (int i = 0; i < modGroup.modifierChild!.length; i++) {
      List<BranchLinkModifier> data = await PosDatabase.instance.readBranchLinkModifier(modGroup.modifierChild![i].mod_item_id.toString());
      modGroup.modifierChild![i].price = data[0].price!;
    }
  }

  productChecking() async {
    await readProductVariant(widget.productDetail!.product_sqlite_id!);
    await readProductModifier(widget.productDetail!.product_sqlite_id!);
    await getProductPrice(widget.productDetail!.product_sqlite_id);
    categories = await PosDatabase.instance.readSpecificCategoryById(widget.productDetail!.category_sqlite_id!);
    print('category init: ${categories}');
    if(mounted){
      setState(() {
        this.isLoaded = true;
      });
    }
  }

  getProductPrice(int? productId) async {
    double totalBasePrice = 0.0;
    double totalModPrice = 0.0;
    try {
      final prefs = await SharedPreferences.getInstance();
      final int? branch_id = prefs.getInt('branch_id');

      List<BranchLinkProduct> data = await PosDatabase.instance.readBranchLinkSpecificProduct(branch_id.toString(), productId.toString());
      if (data[0].has_variant == '0') {
        basePrice = data[0].price!;
        finalPrice = basePrice;
        //check product mod group
        for (int j = 0; j < modifierGroup.length; j++) {
          ModifierGroup group = modifierGroup[j];
          //loop mod group child
          for (int k = 0; k < group.modifierChild!.length; k++) {
            if (group.modifierChild![k].isChecked == true) {
              List<BranchLinkModifier> modPrice = await PosDatabase.instance.readBranchLinkModifier(group.modifierChild![k].mod_item_id.toString());
              totalModPrice += double.parse(modPrice[0].price!);
              totalBasePrice = double.parse(data[0].price!) + totalModPrice;
              finalPrice = totalBasePrice.toStringAsFixed(2);
            }
          }
        }
      } else {
        List<BranchLinkProduct> productVariant = await PosDatabase.instance.checkProductVariant(await getProductVariant(productId!), productId.toString());
        basePrice = productVariant[0].price!;
        finalPrice = basePrice;
        dialogPrice = basePrice;

        //loop has variant product modifier group
        for (int j = 0; j < modifierGroup.length; j++) {
          ModifierGroup group = modifierGroup[j];
          //loop mod group child
          for (int k = 0; k < group.modifierChild!.length; k++) {
            if (group.modifierChild![k].isChecked == true) {
              List<BranchLinkModifier> modPrice = await PosDatabase.instance.readBranchLinkModifier(group.modifierChild![k].mod_item_id.toString());
              totalModPrice += double.parse(modPrice[0].price!);
              totalBasePrice = double.parse(productVariant[0].price!) + totalModPrice;
              finalPrice = totalBasePrice.toStringAsFixed(2);
            }
          }
        }
      }
    } catch (error) {
      print('Get product base price error ${error}');
    }
    return finalPrice;
  }

  int checkCartProductQuantity(CartModel cart, BranchLinkProduct branchLinkProduct){
    ///get all same item in cart
    List<cartProductItem> sameProductList = cart.cartNotifierItem.where(
            (item) => item.branch_link_product_sqlite_id == branchLinkProduct.branch_link_product_sqlite_id.toString() && item.status == 0
    ).toList();
    if(sameProductList.isNotEmpty){
      /// sum all quantity
      int totalQuantity = sameProductList.fold(0, (sum, product) => sum + product.quantity!);
      return totalQuantity;
    } else {
      return 0;
    }
  }

  checkProductStock(Product product, CartModel cart) async {
    final prefs = await SharedPreferences.getInstance();
    final int? branch_id = prefs.getInt('branch_id');
    if (product.has_variant == 0) {
      List<BranchLinkProduct> data1 = await PosDatabase.instance.readBranchLinkSpecificProduct(branch_id.toString(), product.product_sqlite_id.toString());
      if(data1[0].stock_type == '2') {
        if (int.parse(data1[0].stock_quantity!) > 0 && simpleIntInput <= int.parse(data1[0].stock_quantity!)) {
          int stockLeft =  int.parse(data1[0].stock_quantity!) - checkCartProductQuantity(cart, data1[0]);
          if(stockLeft > 0){
            hasStock = true;
          } else {
            hasStock = false;
          }
        } else {
          hasStock = false;
        }
      } else {
        if (int.parse(data1[0].daily_limit!) > 0 && simpleIntInput <= int.parse(data1[0].daily_limit!)) {
          int stockLeft =  int.parse(data1[0].daily_limit!) - checkCartProductQuantity(cart, data1[0]);
          print('stock left: ${stockLeft}');
          if(stockLeft > 0){
            hasStock = true;
          } else {
            hasStock = false;
          }
        } else {
          hasStock = false;
        }
      }
    } else {
      //check has variant product stock
      List<BranchLinkProduct> data = await PosDatabase.instance.checkProductVariant(await getProductVariant(product.product_sqlite_id!), product.product_sqlite_id.toString());
      if (data[0].stock_type == '2') {
        if (int.parse(data[0].stock_quantity!) > 0 && simpleIntInput <= int.parse(data[0].stock_quantity!)) {
          int stockLeft =  int.parse(data[0].stock_quantity!) - checkCartProductQuantity(cart, data[0]);
          print('stock left: ${stockLeft}');
          if(stockLeft > 0){
            hasStock = true;
          } else {
            hasStock = false;
          }
        } else {
          hasStock = false;
        }
      } else {
        if (int.parse(data[0].daily_limit_amount!) > 0 && simpleIntInput <= int.parse(data[0].daily_limit_amount!)) {
          int stockLeft =  int.parse(data[0].daily_limit_amount!) - checkCartProductQuantity(cart, data[0]);
          print('stock left: ${stockLeft}');
          if(stockLeft > 0){
            hasStock = true;
          } else {
            hasStock = false;
          }
        } else {
          hasStock = false;
        }
      }
    }
    print('has stock ${hasStock}');
  }

  getBranchLinkProductItem(Product product) async {
    branchLinkProduct_id = '';
    try {
      final prefs = await SharedPreferences.getInstance();
      final int? branch_id = prefs.getInt('branch_id');
      List<BranchLinkProduct> data1 = await PosDatabase.instance.readBranchLinkSpecificProduct(branch_id.toString(), product.product_sqlite_id.toString());
      branchLinkProduct_id = data1[0].branch_link_product_sqlite_id.toString();
      // if (product.has_variant == 0) {
      //   List<BranchLinkProduct> data1 = await PosDatabase.instance.readBranchLinkSpecificProduct(branch_id.toString(), product.product_sqlite_id.toString());
      //   branchLinkProduct_id = data1[0].branch_link_product_sqlite_id.toString();
      //   if(data1[0].stock_type == '2') {
      //     if (int.parse(data1[0].stock_quantity!) > 0 && simpleIntInput <= int.parse(data1[0].stock_quantity!)) {
      //       hasStock = true;
      //     } else {
      //       hasStock = false;
      //     }
      //   } else {
      //     if (int.parse(data1[0].daily_limit_amount!) > 0 && simpleIntInput <= int.parse(data1[0].daily_limit_amount!)) {
      //       hasStock = true;
      //     } else {
      //       hasStock = false;
      //     }
      //   }
      // } else {
      //   //check has variant product stock
      //   List<BranchLinkProduct> data = await PosDatabase.instance.checkProductVariant(await getProductVariant(product.product_sqlite_id!), product.product_sqlite_id.toString());
      //   branchLinkProduct_id = data[0].branch_link_product_sqlite_id.toString();
      //   if (data[0].stock_type == '2') {
      //     if (int.parse(data[0].stock_quantity!) > 0 && simpleIntInput <= int.parse(data[0].stock_quantity!)) {
      //       hasStock = true;
      //     } else {
      //       hasStock = false;
      //     }
      //   } else {
      //     if (int.parse(data[0].daily_limit_amount!) > 0 && simpleIntInput <= int.parse(data[0].daily_limit_amount!)) {
      //       hasStock = true;
      //     } else {
      //       hasStock = false;
      //     }
      //   }
      // }
      return branchLinkProduct_id;
    } catch (e) {
      Fluttertoast.showToast(msg: 'Make sure stock is restock');
    }
  }

  getProductVariant(int product_id) async {
    String variant = '';
    String variant2 = '';
    String variant3 = '';
    String productVariant = '';
    try {
      for (int j = 0; j < variantGroup.length; j++) {
        VariantGroup group = variantGroup[j];
        for (int i = 0; i < group.child!.length; i++) {
          if (group.variant_item_sqlite_id == group.child![i].variant_item_sqlite_id) {
            group.child![i].isSelected = true;
            if (variant == '') {
              variant = group.child![i].name!.trim();
              if (variantGroup.length == 1) {
                List<ProductVariant> data = await PosDatabase.instance.readSpecificProductVariant(product_id.toString(), variant);
                productVariant = data[0].product_variant_sqlite_id.toString();
                break;
              }
            } else if (variant2 == '') {
              variant2 = variant + " | " + group.child![i].name!;
              if (variantGroup.length == 2) {
                List<ProductVariant> data = await PosDatabase.instance.readSpecificProductVariant(product_id.toString(), variant2);
                productVariant = data[0].product_variant_sqlite_id.toString();
                break;
              }
            } else if (variant3 == '') {
              variant3 = variant2 + " | " + group.child![i].name!;
              if (variantGroup.length == 3) {
                List<ProductVariant> data = await PosDatabase.instance.readSpecificProductVariant(product_id.toString(), variant3);
                productVariant = data[0].product_variant_sqlite_id.toString();
                break;
              }
            }
          }
        }
      }
      // print('variant string: ${variant}');
      // print('product variant: ${productVariant}');
      return productVariant;
    } catch (error) {
      print('get product variant error: ${error}');
      return;
    }
  }

  Future<Future<Object?>> openChooseTableDialog(CartModel cartModel) async {
    return showGeneralDialog(
        barrierColor: Colors.black.withOpacity(0.5),
        transitionBuilder: (context, a1, a2, widget) {
          final curvedValue = Curves.easeInOutBack.transform(a1.value) - 1.0;
          return Transform(
            transform: Matrix4.translationValues(0.0, curvedValue * 200, 0.0),
            child: Opacity(
              opacity: a1.value,
              child: CartDialog(
                selectedTableList: cartModel.selectedTable,
              ),
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

  compareCartProductModifier({required List<ModifierGroup> cartModifierGroup}){
    List<ModifierItem> checkedCartModItem = [];
    //add all checked modifier item from cart product
    if(cartModifierGroup.isNotEmpty){
      for(int i = 0 ; i < cartModifierGroup.length; i++){
        ModifierGroup group = cartModifierGroup[i];
        for(int j = 0; j < group.modifierChild!.length; j++){
          if(group.modifierChild![j].isChecked == true){
            checkedCartModItem.add(cartModifierGroup[i].modifierChild![j]);
          }
        }
      }
    }
    return checkSame(checkedCartModItem, checkedModItem);
  }

  bool checkSame(List<ModifierItem> checkedCartModItem, List<ModifierItem> checkedModItem) {
    List<int> cartModItemId = [];
    List<int> checkedModItemId = [];
    bool same = true;
    print('cart mod item length:${checkedCartModItem.length}');
    print('checked mod item length:${checkedModItem.length}');
    if (checkedCartModItem.length != checkedModItem.length) {
      same = false;
    } else {
      //insert mod item id into a list
      for(int i = 0; i < checkedCartModItem.length; i++){
        cartModItemId.add(checkedCartModItem[i].mod_item_id!);
      }
      //insert mod item id into a list
      for(int j = 0; j< checkedModItem.length; j++){
        checkedModItemId.add(checkedModItem[j].mod_item_id!);
      }
      //get all same mod item into a list
      List<int> comparedList = cartModItemId.toSet().intersection(checkedModItemId.toSet()).toList();
      print('compared list length: ${comparedList.length}');
      if(comparedList.length == checkedModItem.length){
        same = true;
      } else {
        same = false;
      }
    }
    return same;
  }

  addToCart(CartModel cart) async {
    //check selected variant
    for (int j = 0; j < variantGroup.length; j++) {
      VariantGroup group = variantGroup[j];
      for (int i = 0; i < group.child!.length; i++) {
        if (group.variant_item_sqlite_id == group.child![i].variant_item_sqlite_id) {
          group.child![i].isSelected = true;
        } else {
          group.child![i].isSelected = false;
        }
      }
    }
    //check checked modifier length
    if(checkedModItem.isNotEmpty){
      checkedModifierLength = checkedModItem.length;
    } else {
      checkedModifierLength = 0;
    }
    var value = cartProductItem(
        branch_link_product_sqlite_id: await getBranchLinkProductItem(widget.productDetail!),
        product_name: widget.productDetail!.name!,
        category_id: widget.productDetail!.category_id!,
        category_name: categories != null ? categories!.name : '',
        price: await getProductPrice(widget.productDetail?.product_sqlite_id),
        quantity: simpleIntInput,
        checkedModifierLength: checkedModifierLength,
        modifier: modifierGroup,
        variant: variantGroup,
        remark: remarkController.text,
        status: 0,
        category_sqlite_id: widget.productDetail!.category_sqlite_id,
        base_price: basePrice,
        refColor: Colors.black,
    );
    print('value checked item length: ${value.checkedModifierLength}');
    //print('value category: ${value.category_name}');
    // print('base price: ${value.base_price}');
    // print('price: ${value.price}');
    List<cartProductItem> item = [];
    if(cart.cartNotifierItem.isEmpty){
      cart.addItem(value);
    } else {
      for(int k = 0; k < cart.cartNotifierItem.length; k++){
        print('cart checked mod item length in cart: ${cart.cartNotifierItem[k].checkedModifierLength}');
        if(cart.cartNotifierItem[k].branch_link_product_sqlite_id == value.branch_link_product_sqlite_id
            && value.remark == cart.cartNotifierItem[k].remark
            && value.checkedModifierLength == cart.cartNotifierItem[k].checkedModifierLength
            && cart.cartNotifierItem[k].status == 0) {
          item.add(cart.cartNotifierItem[k]);
        }
      }
      print('item length: ${item.length}');
      while(item.length > 1){
        for(int i = 0 ; i < item.length; i++){
          bool status = compareCartProductModifier(cartModifierGroup: item[i].modifier!);
          if(status == false){
            item.remove(item[i]);
          }
        }
      }
      print('item after first compare length: ${item.length}');
      if(item.length == 1){
        if(item[0].checkedModifierLength == 0){
          item[0].quantity = item[0].quantity! + value.quantity!;
        } else {
          bool status = compareCartProductModifier(cartModifierGroup: item[0].modifier!);
          print('compared status: ${status}');
          if(status == false){
            cart.addItem(value);
          } else{
            item[0].quantity = item[0].quantity! + value.quantity!;
          }
        }
      } else {
        cart.addItem(value);
      }
      print('length after: ${cart.cartNotifierItem.length}');
    }
    cart.resetCount();
  }
}
