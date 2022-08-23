import 'package:flutter/material.dart';
import 'package:grouped_list/grouped_list.dart';
import 'package:pos_system/object/product.dart';
import 'package:pos_system/object/variant_group.dart';
import 'package:pos_system/object/variant_item.dart';
import 'package:pos_system/page/progress_bar.dart';
import 'package:provider/provider.dart';
import 'package:quantity_input/quantity_input.dart';

import '../../database/pos_database.dart';
import '../../notifier/theme_color.dart';
import '../../object/modifier_group.dart';
import '../../object/modifier_item.dart';

class ProductOrderDialog extends StatefulWidget {
  final Product? productDetail;

  const ProductOrderDialog({Key? key, this.productDetail}) : super(key: key);

  @override
  _ProductOrderDialogState createState() => _ProductOrderDialogState();
}



class _ProductOrderDialogState extends State<ProductOrderDialog> {
  int simpleIntInput = 0;
  List<VariantGroup> variantGroup = [];

  // late Variant selected = Variant(item: '', group: '');
  bool checkboxValueA = false;
  List<ModifierItem> modifierElement = [];
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
        Text(variantGroup.name!,
            style: TextStyle(fontWeight: FontWeight.bold)),
        for (int i = 0; i < variantGroup.child.length; i++)
          RadioListTile<int?>(
            value: variantGroup.child[i].variant_item_id,
            groupValue: variantGroup.variant_item_id,
            onChanged: (ind) => setState(() {
              print(ind);
              variantGroup.variant_item_id = ind;
              // print('main item: ${ind.item}');
            }),
            title: Text(variantGroup.child[i].name!),
            controlAffinity: ListTileControlAffinity.trailing,
          )
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeColor>(builder: (context, ThemeColor color, child) {
      return isLoading != true
          ? AlertDialog(
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
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (int i = 0; i < variantGroup.length; i++)
                        variantGroupLayout(variantGroup[i]),
                      Column(
                        children: [
                          GroupedListView<ModifierItem, String>(
                            physics: NeverScrollableScrollPhysics(),
                            shrinkWrap: true,
                            elements: modifierElement,
                            groupBy: (element) => element.mod_group_id!,
                            groupComparator: (value1, value2) =>
                                value2.compareTo(value1),
                            itemComparator: (item1, item2) =>
                                item1.name!.compareTo(item2.name!),
                            order: GroupedListOrder.DESC,
                            useStickyGroupSeparators: true,
                            stickyHeaderBackgroundColor: Colors.transparent,
                            groupSeparatorBuilder: (String value) => Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: [
                                  Text(
                                    value,
                                    style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ),
                            itemBuilder: (c, element) {
                              return ListTile(
                                trailing: Checkbox(
                                  activeColor: color.backgroundColor,
                                  value: element.isChecked,
                                  onChanged: (value) {
                                    setState(() {
                                      element.isChecked = value!;
                                      print(
                                          'flavour ${element.name},is check ${element.isChecked}');
                                    });
                                  },
                                ),
                                title: Text(element.name!,
                                    style: TextStyle(fontSize: 14)),
                                dense: true,
                              );
                            },
                          ),
                        ],
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
                  child: Text('Close'),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
                TextButton(
                  child: const Text('Add'),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
              ],
            )
          : CustomProgressBar();
    });
  }

  readProductVariant(int productID) async {
    //loop variant group first
    List<VariantGroup> data = await PosDatabase.instance.readProductVariantGroup(productID);
    for (int i = 0; i < data.length; i++) {
      variantGroup.add(VariantGroup(child: [], name: data[i].name));

      //loop variant child based on variant group id
      List<VariantItem> itemData = await PosDatabase.instance.readProductVariantItem(data[i].variant_group_id!);
      List<VariantItem> itemChild = [];
      for (int j = 0; j < itemData.length; j++) {
        //pre-check radio button
        if (j == 0) {
          variantGroup[i].variant_item_id = itemData[j].variant_item_id;
        }
        //store all child into one list
        itemChild.add(VariantItem(
            name: itemData[j].name, variant_item_id: itemData[j].variant_item_id));
      }
      //assign list into group child
      variantGroup[i].child = itemChild;
    }
  }

  readProductModifier(int productID) async {
    List<ModifierGroup> data = await PosDatabase.instance.readProductModifierGroupName(productID);

    for (int i = 0; i < data.length; i++) {
      List<ModifierItem> itemData = await PosDatabase.instance.readProductModifierItem(data[i].mod_group_id!);

      for (int j = 0; j < itemData.length; j++) {
        modifierElement.add(ModifierItem(
            name: itemData[j].name!, mod_group_id: data[i].name!, isChecked: false));
      }
    }
  }

  productChecking() async {
    await readProductVariant(widget.productDetail!.product_id!);
    await readProductModifier(widget.productDetail!.product_id!);
    this.isLoading = false;
  }
}
