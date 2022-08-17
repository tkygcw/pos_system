import 'package:flutter/material.dart';
import 'package:grouped_list/grouped_list.dart';
import 'package:pos_system/object/product.dart';
import 'package:pos_system/object/variant_item.dart';
import 'package:pos_system/page/progress_bar.dart';
import 'package:provider/provider.dart';
import 'package:quantity_input/quantity_input.dart';

import '../database/pos_database.dart';
import '../notifier/theme_color.dart';
import '../object/modifier_group.dart';
import '../object/modifier_item.dart';
import '../object/variant_group.dart';

class ProductOrderDialog extends StatefulWidget {
  final Product? productDetail;
  const ProductOrderDialog({Key? key, this.productDetail}) : super(key: key);

  @override
  _ProductOrderDialogState createState() => _ProductOrderDialogState();
}

class Variant {
  String? item;
  String? group;

  Variant({this.item, this.group});

  Map<String, Object?> toJson() => {
        'name': item,
        'group': group,
      };
}

class Modifier {
  String? name;
  String? group;

  Modifier({this.name, this.group});

  Map<String, Object?> toJson() => {
        'name': name,
        'group': group,
      };
}

class _ProductOrderDialogState extends State<ProductOrderDialog> {
  int simpleIntInput = 0;
  List<Variant> variantElement = [];
  late Variant selected = Variant(item: '', group: '');
  bool checkboxValueA = false;
  List<Modifier> modifierElement = [];
  bool isLoading = true;


  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    productChecking();

  }


  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeColor>(builder: (context, ThemeColor color, child) {
      return isLoading != true ? AlertDialog(
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
                (widget.productDetail!.has_variant == 1
                    ? Column(
                        children: [
                          GroupedListView<Variant, String>(
                            physics: NeverScrollableScrollPhysics(),
                            shrinkWrap: true,
                            elements: variantElement,
                            groupBy: (element) => element.group!,
                            groupComparator: (value1, value2) =>
                                value2.compareTo(value1),
                            itemComparator: (item1, item2) =>
                                item1.item!.compareTo(item2.item!),
                            order: GroupedListOrder.DESC,
                            useStickyGroupSeparators: true,
                            stickyHeaderBackgroundColor: Colors.transparent,
                            groupSeparatorBuilder: (String value) => Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Text(
                                value,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                            ),
                            itemBuilder: (c, element) {
                              // return ListTile(
                              //   trailing: Radio(
                              //       value: element.name!,
                              //       activeColor: color.backgroundColor,
                              //       groupValue: selected,
                              //       onChanged: (String? value) {
                              //         selected = value!;
                              //       }),
                              //   leading: Text(element.name!,
                              //       style: TextStyle(fontSize: 14)),
                              //   dense: true,
                              // );
                              return RadioListTile<Variant>(
                                value: element,
                                groupValue: selected,
                                onChanged: (ind) => setState(() => selected = ind!),
                                title: Text(element.item!),
                              );
                            },
                          ),
                        ],
                      )
                    : Container()),
                Column(
                  children: [
                    GroupedListView<Modifier, String>(
                      physics: NeverScrollableScrollPhysics(),
                      shrinkWrap: true,
                      elements: modifierElement,
                      groupBy: (element) => element.group!,
                      groupComparator: (value1, value2) =>
                          value2.compareTo(value1),
                      itemComparator: (item1, item2) =>
                          item1.name!.compareTo(item2.name!),
                      order: GroupedListOrder.DESC,
                      useStickyGroupSeparators: true,
                      stickyHeaderBackgroundColor: Colors.transparent,
                      groupSeparatorBuilder: (String value) => Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          value,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ),
                      itemBuilder: (c, element) {
                        return ListTile(
                          trailing: Checkbox(
                            activeColor: color.backgroundColor,
                            value: checkboxValueA,
                            onChanged: (value) {},
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
                      child: Text(
                        "Quantity",
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
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
                        onChanged: (value) => setState(() => simpleIntInput =
                            int.parse(value.replaceAll(',', ''))))
                  ],
                ),
                Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(8, 30, 8, 10),
                      child: Text(
                        "Remark",
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                    TextField(
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
      ) : CustomProgressBar();
    });
  }

  readProductVariant(int productID) async {
    List<VariantGroup> data =
        await PosDatabase.instance.readProductVariantGroup(productID);
    for (int i = 0; i < data.length; i++) {
      List<VariantItem> itemData = await PosDatabase.instance
          .readProductVariantItem(data[i].variant_group_id!);
      for (int j = 0; j < itemData.length; j++) {
        variantElement
            .add(Variant(item: itemData[j].name!, group: data[i].name!));
      }
    }
  }

  readProductModifier(int productID) async {
    List<ModifierGroup> data =
        await PosDatabase.instance.readProductModifierGroupName(productID);
    for (int i = 0; i < data.length; i++) {
      List<ModifierItem> itemData = await PosDatabase.instance
          .readProductModifierItem(data[i].mod_group_id!);
      for (int j = 0; j < itemData.length; j++) {
        modifierElement
            .add(Modifier(name: itemData[j].name!, group: data[i].name!));
      }
    }
  }

  productChecking() async {
   await readProductVariant(widget.productDetail!.product_id!);
   await readProductModifier(widget.productDetail!.product_id!);
   this.isLoading = false;
  }
}
