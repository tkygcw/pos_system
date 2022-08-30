
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:pos_system/object/cart_product.dart';
import 'package:pos_system/object/product.dart';
import 'package:pos_system/object/variant_group.dart';
import 'package:pos_system/object/variant_item.dart';
import 'package:pos_system/page/progress_bar.dart';
import 'package:provider/provider.dart';
import 'package:quantity_input/quantity_input.dart';

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
  int simpleIntInput = 1;
  List<VariantGroup> variantGroup = [];
  List<ModifierGroup> modifierGroup = [];
  final remarkController = TextEditingController();
  final quantityController = TextEditingController();

  bool checkboxValueA = false;
  bool isLoading = true;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    productChecking();
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
        Text(modifierGroup.name!, style: TextStyle(fontWeight: FontWeight.bold)),
        for(int i = 0; i < modifierGroup.modifierChild.length; i++)
          CheckboxListTile(
            title: Text(modifierGroup.modifierChild[i].name!),
            value: modifierGroup.modifierChild[i].isChecked,
            onChanged: (isChecked){
              setState(() {
                modifierGroup.modifierChild[i].isChecked = isChecked!;
                print('flavour ${modifierGroup.modifierChild[i].name},is check ${modifierGroup.modifierChild[i].isChecked}');
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
          ? Consumer<CartModel>(
            builder: (context, CartModel cart, child) {
              return AlertDialog(
                  title: Text(
                    widget.productDetail!.name!,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  content: Container(
                    height: 500.0, // Change as per your requirement
                    width: 350.0,
                    child: SingleChildScrollView(
                      child:
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          for (int i = 0; i < variantGroup.length; i++)
                            variantGroupLayout(variantGroup[i]),

                          for(int j = 0; j < modifierGroup.length; j++)
                            modifierGroupLayout(modifierGroup[j]),
                          // Column(
                          //   children: [
                          //     GroupedListView<ModifierItem, String>(
                          //       physics: NeverScrollableScrollPhysics(),
                          //       shrinkWrap: true,
                          //       elements: modifierElement,
                          //       groupBy: (element) => element.mod_group_id!,
                          //       groupComparator: (value1, value2) =>
                          //           value2.compareTo(value1),
                          //       itemComparator: (item1, item2) =>
                          //           item1.name!.compareTo(item2.name!),
                          //       order: GroupedListOrder.DESC,
                          //       useStickyGroupSeparators: true,
                          //       stickyHeaderBackgroundColor: Colors.transparent,
                          //       groupSeparatorBuilder: (String value) => Padding(
                          //         padding: const EdgeInsets.all(8.0),
                          //         child: Row(
                          //           mainAxisAlignment: MainAxisAlignment.start,
                          //           children: [
                          //             Text(
                          //               value,
                          //               style: TextStyle(
                          //                   fontSize: 16,
                          //                   fontWeight: FontWeight.bold),
                          //             ),
                          //           ],
                          //         ),
                          //       ),
                          //       itemBuilder: (c, element) {
                          //         return ListTile(
                          //           trailing: Checkbox(
                          //             activeColor: color.backgroundColor,
                          //             value: element.isChecked,
                          //             onChanged: (value) {
                          //               setState(() {
                          //                 element.isChecked = value!;
                          //                 if (element.isChecked!) {
                          //                   checkedModifier.add(element);
                          //                 } else {
                          //                   checkedModifier.remove(element);
                          //                 }
                          //                 print(
                          //                     'flavour ${element.name},is check ${element.isChecked}');
                          //               });
                          //             },
                          //           ),
                          //           title: Text(element.name!,
                          //               style: TextStyle(fontSize: 14)),
                          //           dense: true,
                          //         );
                          //       },
                          //     ),
                          //   ],
                          // ),
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
                                      borderSide:
                                          BorderSide(color: color.backgroundColor),
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
                      child:
                          Text('${AppLocalizations.of(context)?.translate('add')}'),
                      onPressed: () async {
                        await addToCart(cart);
                        Navigator.of(context).pop();
                      },
                    ),
                  ],
                );
            }
          )
          : CustomProgressBar();
    });
  }

  readProductVariant(int productID) async {
    //loop variant group first
    List<VariantGroup> data =
        await PosDatabase.instance.readProductVariantGroup(productID);
    for (int i = 0; i < data.length; i++) {
      variantGroup.add(VariantGroup(child: [], name: data[i].name));

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
            name: itemData[j].name,
            variant_item_id: itemData[j].variant_item_id));
      }
      //assign list into group child
      variantGroup[i].child = itemChild;
    }
  }

  readProductModifier(int productID) async {
    List<ModifierGroup> data = await PosDatabase.instance.readProductModifierGroupName(productID);

    for (int i = 0; i < data.length; i++) {
      modifierGroup.add(ModifierGroup(modifierChild: [], name: data[i].name));
      List<ModifierItem> itemData = await PosDatabase.instance.readProductModifierItem(data[i].mod_group_id!);
      List<ModifierItem> modItemChild = [];

      for (int j = 0; j < itemData.length; j++) {
        modItemChild.add(ModifierItem(
            name: itemData[j].name!,
            mod_item_id: itemData[j].mod_item_id,
            isChecked: false));
      }
      modifierGroup[i].modifierChild = modItemChild;
    }
  }

  productChecking() async {
    await readProductVariant(widget.productDetail!.product_id!);
    await readProductModifier(widget.productDetail!.product_id!);
    this.isLoading = false;
  }

  addToCart(CartModel cart) {
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

    print(jsonEncode(modifierGroup.map((e) => e.addToCartJSon()).toList()));
    var value = cartProductItem(widget.productDetail!.name!, '12.00', simpleIntInput, modifierGroup, variantGroup, remarkController.text);
    cart.addItem(value);
  }
}

// class cartProductItem{
//   String name ='';
//   String price ='';
//   int quantity = 0;
//   String? modifier='';
//   late List<String> variant;
//   String? remark ='';
//
//   cartProductItem(String name, String price, int quantity, String modifier, variant, String remark){
//     this.name = name;
//     this.price = price;
//     this.quantity = quantity;
//     this.modifier = modifier;
//     this.variant = variant;
//     this.remark = remark;
//   }
