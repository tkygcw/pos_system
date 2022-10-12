import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:pos_system/object/branch_link_modifier.dart';
import 'package:pos_system/object/branch_link_product.dart';
import 'package:pos_system/object/cart_product.dart';
import 'package:pos_system/object/product.dart';
import 'package:pos_system/object/product_variant.dart';
import 'package:pos_system/object/variant_group.dart';
import 'package:pos_system/object/variant_item.dart';
import 'package:pos_system/page/progress_bar.dart';
import 'package:provider/provider.dart';
import 'package:quantity_input/quantity_input.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../database/pos_database.dart';
import '../../notifier/cart_notifier.dart';
import '../../notifier/theme_color.dart';
import '../../object/modifier_group.dart';
import '../../object/modifier_item.dart';
import '../../translation/AppLocalizations.dart';

class ProductOrderDialog extends StatefulWidget {
  final Product? productDetail;

  const ProductOrderDialog({Key? key, this.productDetail}) : super(key: key);

  @override
  _ProductOrderDialogState createState() => _ProductOrderDialogState();
}

class _ProductOrderDialogState extends State<ProductOrderDialog> {
  String branchLinkProduct_id = '';
  String basePrice = '';
  int simpleIntInput = 1;
  String modifierItemPrice = '';
  List<VariantGroup> variantGroup = [];
  List<ModifierGroup> modifierGroup = [];
  final remarkController = TextEditingController();
  final quantityController = TextEditingController();

  bool checkboxValueA = false;
  bool isLoading = true;
  bool hasPromo = false;

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
        for (int i = 0; i < variantGroup.child.length; i++)
          RadioListTile<int?>(
            value: variantGroup.child[i].variant_item_id,
            groupValue: variantGroup.variant_item_id,
            onChanged: (ind) => setState(() {
              variantGroup.variant_item_id = ind;
            }),
            title: Text(variantGroup.child[i].name!),
            controlAffinity: ListTileControlAffinity.trailing,
          )
      ],
    );
  }

  Widget modifierGroupLayout(ModifierGroup modifierGroup) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(modifierGroup.name!,
            style: TextStyle(fontWeight: FontWeight.bold)),
        for (int i = 0; i < modifierGroup.modifierChild.length; i++)
          CheckboxListTile(
            title: Row(
              children: [
                Text('${modifierGroup.modifierChild[i].name!}'),
                Text(' (+RM ${modifierGroup.modifierChild[i].price})', style: TextStyle(fontSize: 12),)
              ],
            ),
            value: modifierGroup.modifierChild[i].isChecked,
            onChanged: (isChecked) {
              setState(() {
                modifierGroup.modifierChild[i].isChecked = isChecked!;
                print(
                    'flavour ${modifierGroup.modifierChild[i].name},is check ${modifierGroup.modifierChild[i].isChecked}');
              });
            },
            controlAffinity: ListTileControlAffinity.trailing,
          )
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeColor>(builder: (context, ThemeColor color, child) {
      return isLoading != true
          ? Consumer<CartModel>(builder: (context, CartModel cart, child) {
              return AlertDialog(
                title: Row(
                  children: [
                    Text(widget.productDetail!.name!,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        )),
                    Spacer(),
                    Text("RM ${widget.productDetail!.price!}",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        )),
                  ],
                ),
                content: Container(
                  height: 500.0, // Change as per your requirement
                  width: 350.0,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        for (int i = 0; i < variantGroup.length; i++)
                          variantGroupLayout(variantGroup[i]),
                        for (int j = 0; j < modifierGroup.length; j++)
                          modifierGroupLayout(modifierGroup[j]),
                        Column(
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: [
                                  Text(
                                    "Quantity",
                                    style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ),
                            QuantityInput(
                                inputWidth: 273,
                                decoration: InputDecoration(
                                  focusedBorder: OutlineInputBorder(
                                    borderSide: BorderSide(
                                        color: color.backgroundColor),
                                  ),
                                ),
                                buttonColor: color.backgroundColor,
                                value: simpleIntInput,
                                onChanged: (value) => setState(() =>
                                    simpleIntInput =
                                        int.parse(value.replaceAll(',', ''))))
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
                                    style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ),
                            TextField(
                              controller: remarkController,
                              decoration: InputDecoration(
                                focusedBorder: OutlineInputBorder(
                                  borderSide:
                                      BorderSide(color: color.backgroundColor),
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
                  TextButton(
                    child: Text(
                        '${AppLocalizations.of(context)?.translate('close')}'),
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                  ),
                  TextButton(
                    child: Text(
                        '${AppLocalizations.of(context)?.translate('add')}'),
                    onPressed: () async {
                      await addToCart(cart);
                      Navigator.of(context).pop();
                    },
                  ),
                ],
              );
            })
          : CustomProgressBar();
    });
  }

  readProductVariant(int productID) async {
    //loop variant group first
    List<VariantGroup> data =
        await PosDatabase.instance.readProductVariantGroup(productID);
    for (int i = 0; i < data.length; i++) {
      variantGroup.add(VariantGroup(
          variant_group_id: data[i].variant_group_id,
          child: [],
          name: data[i].name));

      //loop variant child based on variant group id
      List<VariantItem> itemData = await PosDatabase.instance
          .readProductVariantItem(data[i].variant_group_id!);
      List<VariantItem> itemChild = [];
      for (int j = 0; j < itemData.length; j++) {
        //pre-check radio button
        if (j == 0) {
          variantGroup[i].variant_item_id = itemData[j].variant_item_id;
        }
        //store all child into one list
        itemChild.add(VariantItem(
            variant_group_id: data[i].variant_group_id.toString(),
            name: itemData[j].name,
            variant_item_id: itemData[j].variant_item_id));
      }
      //assign list into group child
      variantGroup[i].child = itemChild;
    }
  }

  readProductModifier(int productID) async {
    List<ModifierGroup> data =
        await PosDatabase.instance.readProductModifierGroupName(productID);

    for (int i = 0; i < data.length; i++) {
      modifierGroup.add(ModifierGroup(
          modifierChild: [],
          name: data[i].name,
          mod_group_id: data[i].mod_group_id));

      List<ModifierItem> itemData = await PosDatabase.instance
          .readProductModifierItem(data[i].mod_group_id!);
      List<ModifierItem> modItemChild = [];

      for (int j = 0; j < itemData.length; j++) {
        modItemChild.add(ModifierItem(
            mod_group_id: data[i].mod_group_id.toString(),
            name: itemData[j].name!,
            mod_item_id: itemData[j].mod_item_id,
            isChecked: false));
      }
      modifierGroup[i].modifierChild = modItemChild;
      readProductModifierItemPrice(modifierGroup[i]);
    }
  }

  readProductModifierItemPrice(ModifierGroup modGroup) async {
    modifierItemPrice = '';
    final prefs = await SharedPreferences.getInstance();
    final int? branch_id = prefs.getInt('branch_id');

    for (int i = 0; i < modGroup.modifierChild.length; i++) {
      List<BranchLinkModifier> data = await PosDatabase.instance.readBranchLinkModifier(branch_id.toString(), modGroup.modifierChild[i].mod_item_id.toString());
      modGroup.modifierChild[i].price = data[0].price!;
    }
  }

  productChecking() async {
    await readProductVariant(widget.productDetail!.product_id!);
    await readProductModifier(widget.productDetail!.product_id!);
    this.isLoading = false;
  }

  getProductPrice(int? productId) async {
    double totalBasePrice = 0.0;
    double totalModPrice = 0.0;
    try {
      final prefs = await SharedPreferences.getInstance();
      final int? branch_id = prefs.getInt('branch_id');

      List<BranchLinkProduct> data = await PosDatabase.instance
          .readBranchLinkSpecificProduct(
              branch_id.toString(), productId.toString());
      if (data[0].has_variant == '0') {
        basePrice = data[0].price!;
        //check product mod group
        for (int j = 0; j < modifierGroup.length; j++) {
          ModifierGroup group = modifierGroup[j];
          //loop mod group child
          for (int k = 0; k < group.modifierChild.length; k++) {
            if (group.modifierChild[k].isChecked == true) {
              List<BranchLinkModifier> modPrice = await PosDatabase.instance
                  .readBranchLinkModifier(branch_id!.toString(),
                      group.modifierChild[k].mod_item_id.toString());
              totalModPrice += double.parse(modPrice[0].price!);
              totalBasePrice = double.parse(data[0].price!) + totalModPrice;
              basePrice = totalBasePrice.toStringAsFixed(2);
            }
          }
        }
      } else {
        List<BranchLinkProduct> productVariant = await PosDatabase.instance
            .checkProductVariant(await getHasVariantProductPrice(productId),
                productId.toString());
        basePrice = productVariant[0].price!;

        //loop has variant product modifier group
        for (int j = 0; j < modifierGroup.length; j++) {
          ModifierGroup group = modifierGroup[j];
          //loop mod group child
          for (int k = 0; k < group.modifierChild.length; k++) {
            if (group.modifierChild[k].isChecked == true) {
              List<BranchLinkModifier> modPrice = await PosDatabase.instance
                  .readBranchLinkModifier(branch_id!.toString(),
                      group.modifierChild[k].mod_item_id.toString());
              totalModPrice += double.parse(modPrice[0].price!);
              totalBasePrice =
                  double.parse(productVariant[0].price!) + totalModPrice;
              basePrice = totalBasePrice.toStringAsFixed(2);
            }
          }
        }
      }
    } catch (error) {
      print('Get product base price error ${error}');
    }
    return basePrice;
  }

  getBranchLinkProductItem(int? productId) async {
    branchLinkProduct_id = '';

    List<BranchLinkProduct> data = await PosDatabase.instance.checkProductVariant(
        await getHasVariantProductPrice(productId), productId.toString());
    branchLinkProduct_id = data[0].branch_link_product_id.toString();

    return branchLinkProduct_id;
  }

  getHasVariantProductPrice(int? product_id) async {
    String variant = '';
    String variant2 = '';
    String productVariant = '';
    try {
      for (int j = 0; j < variantGroup.length; j++) {
        VariantGroup group = variantGroup[j];
        for (int i = 0; i < group.child.length; i++) {
          if (group.variant_item_id == group.child[i].variant_item_id) {
            group.child[i].isSelected = true;
            if (variant == '') {
              variant = group.child[i].name!;
            } else {
              variant2 = variant + " | " + group.child[i].name!;
              List<ProductVariant> data = await PosDatabase.instance
                  .readSpecificProductVariant(product_id.toString(), variant2);
              productVariant = data[0].product_variant_id.toString();
            }
          }
        }
      }
    } catch (error) {
      print('Price checking error: ${error}');
    }
    return productVariant;
  }

  addToCart(CartModel cart) async {
    //check selected variant
    for (int j = 0; j < variantGroup.length; j++) {
      VariantGroup group = variantGroup[j];
      for (int i = 0; i < group.child.length; i++) {
        if (group.variant_item_id == group.child[i].variant_item_id) {
          group.child[i].isSelected = true;
        } else {
          group.child[i].isSelected = false;
        }
      }
    }

    //print(jsonEncode(modifierGroup.map((e) => e.addToCartJSon()).toList()));
    var value = cartProductItem(
      await getBranchLinkProductItem(widget.productDetail?.product_id),
      widget.productDetail!.name!,
      widget.productDetail!.category_id!,
      await getProductPrice(widget.productDetail?.product_id),
      simpleIntInput,
      modifierGroup,
      variantGroup,
      remarkController.text,
      0,
      null
    );
    cart.addItem(value);

  }
}
