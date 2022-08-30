import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:pos_system/fragment/cart/cart_dialog.dart';
import 'package:pos_system/notifier/cart_notifier.dart';
import 'package:pos_system/notifier/theme_color.dart';
import 'package:pos_system/object/cart_product.dart';
import 'package:pos_system/object/cart_product.dart';
import 'package:pos_system/object/modifier_group.dart';
import 'package:pos_system/object/variant_group.dart';
import 'package:provider/provider.dart';
import 'package:pos_system/globals.dart' as globals;

import '../../globals.dart';

class CartPage extends StatefulWidget {
  const CartPage({Key? key}) : super(key: key);

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  String _selectedColor = 'Dine in';
  List<String> _animals = ["Dine in", "Delivery", "Take Away"];

  // List<cartProductItem> product = [
  //   // cartProductItem('Chicken rice', '12.00', '1', 'big', 'With Water'),
  //   // cartProductItem('Milk Tea', '12.00', '2', 'big', 'With Water'),
  //   // cartProductItem('Wantan Mee', '12.00', '3', 'big', 'With Water'),
  //   // cartProductItem('ABC soup', '12.00', '4', 'big', 'With Water'),
  //   // cartProductItem('ice', '12.00', '5', 'big', 'With Water'),
  //   // cartProductItem('ice', '12.00', '5', 'big', 'With Water'),
  //   // cartProductItem('ice', '12.00', '5', 'big', 'With Water'),
  //   // cartProductItem('ice', '12.00', '5', 'big', 'With Water'),
  // ];
  int simpleIntInput = 0;

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeColor>(builder: (context, ThemeColor color, child) {
      // Future<void> tableDialog(BuildContext context) {
      //   return showDialog<void>(
      //     context: context,
      //     builder: (BuildContext context) {
      //       return AlertDialog(
      //         title:
      //             Text("Table", style: TextStyle(fontWeight: FontWeight.bold)),
      //         content: Builder(builder: (context) {
      //           var width = MediaQuery.of(context).size.width;
      //           return Container(
      //             width: width - 1000,
      //             child: ScrollConfiguration(
      //               behavior: ScrollConfiguration.of(context)
      //                   .copyWith(scrollbars: false),
      //               child: GridView.count(
      //                 crossAxisCount: 2,
      //                 mainAxisSpacing: 10,
      //                 crossAxisSpacing: 10,
      //                 shrinkWrap: true,
      //                 children: [
      //                   Container(
      //                       child: Stack(
      //                     children: [
      //                       Ink.image(
      //                         image: NetworkImage(
      //                             "https://www.hometown.in/media/cms/icon/Two-Seater-Dining-Sets.png"),
      //                         child: InkWell(
      //                           splashColor: Colors.blue.withAlpha(30),
      //                           onTap: () {},
      //                         ),
      //                         fit: BoxFit.cover,
      //                       ),
      //                       Container(
      //                           alignment: Alignment.center, child: Text("#1"))
      //                     ],
      //                   )),
      //                   Container(
      //                       child: Stack(
      //                     children: [
      //                       Ink.image(
      //                         image: NetworkImage(
      //                             "https://www.hometown.in/media/cms/icon/Two-Seater-Dining-Sets.png"),
      //                         child: InkWell(
      //                           splashColor: Colors.blue.withAlpha(30),
      //                           onTap: () {},
      //                         ),
      //                         fit: BoxFit.cover,
      //                       ),
      //                       Container(
      //                           alignment: Alignment.center, child: Text("#2"))
      //                     ],
      //                   )),
      //                   Container(
      //                       child: Stack(
      //                     children: [
      //                       Ink.image(
      //                         image: NetworkImage(
      //                             "https://www.hometown.in/media/cms/icon/Four-Seater-Dining-Sets.png"),
      //                         child: InkWell(
      //                           splashColor: Colors.blue.withAlpha(30),
      //                           onTap: () {},
      //                         ),
      //                         fit: BoxFit.cover,
      //                       ),
      //                       Container(
      //                           alignment: Alignment.center, child: Text("#3"))
      //                     ],
      //                   )),
      //                   Container(
      //                       child: Stack(
      //                     children: [
      //                       Ink.image(
      //                         image: NetworkImage(
      //                             "https://www.hometown.in/media/cms/icon/Four-Seater-Dining-Sets.png"),
      //                         child: InkWell(
      //                           splashColor: Colors.blue.withAlpha(30),
      //                           onTap: () {},
      //                         ),
      //                         fit: BoxFit.cover,
      //                       ),
      //                       Container(
      //                           alignment: Alignment.center, child: Text("#4"))
      //                     ],
      //                   )),
      //                   Container(
      //                       child: Stack(
      //                     children: [
      //                       Ink.image(
      //                         image: NetworkImage(
      //                             "https://www.hometown.in/media/cms/icon/Six-Seater-Dining-Sets.png"),
      //                         child: InkWell(
      //                           splashColor: Colors.blue.withAlpha(30),
      //                           onTap: () {},
      //                         ),
      //                         fit: BoxFit.cover,
      //                       ),
      //                       Container(
      //                           alignment: Alignment.center, child: Text("#5"))
      //                     ],
      //                   )),
      //                 ],
      //               ),
      //             ),
      //           );
      //         }),
      //       );
      //     },
      //   );
      // }
      return Padding(
        padding: const EdgeInsets.all(8.0),
        child: Scaffold(
          resizeToAvoidBottomInset: false,
          appBar: AppBar(
            automaticallyImplyLeading: false,
            title: Text('Bill',
                style: TextStyle(fontSize: 20, color: Colors.black)),
            backgroundColor: Colors.white,
            actions: [
              IconButton(
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
              IconButton(
                tooltip: 'customer',
                icon: const Icon(
                  Icons.sync,
                ),
                color: color.backgroundColor,
                onPressed: () {},
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
          body: Container(
            decoration: BoxDecoration(
              color: color.iconColor,
              border: Border.all(color: Colors.grey.shade100, width: 3.0),
            ),
            child: Column(
              children: [
                Padding(
                  padding: EdgeInsets.fromLTRB(10, 8, 14, 0),
                  child: Column(children: [
                    DropdownButton<String>(
                      onChanged: (String? value) {
                        setState(() {
                          _selectedColor = value!;
                        });
                      },
                      value: _selectedColor,
                      // Hide the default underline
                      underline: Container(),
                      icon: Icon(
                        Icons.arrow_drop_down,
                        color: color.backgroundColor,
                      ),
                      isExpanded: true,
                      // The list of options
                      items: _animals
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
                      selectedItemBuilder: (BuildContext context) => _animals
                          .map((e) => Center(
                                child: Text(e),
                              ))
                          .toList(),
                    ),
                  ]),
                ),
                Expanded(
                  child: Consumer<CartModel>(
                    builder: (context, CartModel cart, child) {
                      return Container(
                        height: 350,
                        child: ListView.builder(
                            shrinkWrap: true,
                            itemCount: cart.cartNotifierItem.length,
                            itemBuilder: (context, index) {
                              return Dismissible(
                                key: ValueKey(cart.cartNotifierItem[index].name),
                                direction: DismissDirection.startToEnd,
                                confirmDismiss: (direction) async  {
                                  if (direction == DismissDirection.startToEnd) {
                                    cart.removeItem(cart.cartNotifierItem[index]);
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
                                            text: cart.cartNotifierItem[index].name + '\n',
                                            style: TextStyle(
                                                fontSize: 14,
                                                color: color.backgroundColor,
                                                fontWeight: FontWeight.bold)),
                                        TextSpan(
                                            text: "RM" + cart.cartNotifierItem[index].price,
                                            style: TextStyle(
                                              fontSize: 13,
                                              color: color.backgroundColor,
                                            )),
                                      ],
                                    ),
                                  ),
                                  subtitle: Text(getVariant(cart.cartNotifierItem[index]) + getModifier(cart.cartNotifierItem[index])
                                      + getRemark(cart.cartNotifierItem[index]),
                                          style: TextStyle(fontSize: 10)),
                                  trailing: Container(
                                    child: FittedBox(
                                      child: Row(
                                        children: [
                                          IconButton(
                                              hoverColor: Colors.transparent,
                                              icon: Icon(Icons.remove),
                                              onPressed: () => setState(() =>
                                              cart.cartNotifierItem[index].quantity != 1
                                                      ? cart.cartNotifierItem[index].quantity--
                                                      : cart.cartNotifierItem[index].quantity)),
                                          Text(cart.cartNotifierItem[index].quantity.toString()),
                                          IconButton(
                                              hoverColor: Colors.transparent,
                                              icon: Icon(Icons.add),
                                              onPressed: () => setState(
                                                  () => cart.cartNotifierItem[index].quantity++))
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }),
                      );
                    }
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
                      title: Text("Subtotal", style: TextStyle(fontSize: 14)),
                      trailing: Text("12.00", style: TextStyle(fontSize: 14)),
                      visualDensity: VisualDensity(vertical: -4),
                      dense: true,
                    ),
                    ListTile(
                      title: Text("Promotion", style: TextStyle(fontSize: 14)),
                      trailing: Text("- 12.00", style: TextStyle(fontSize: 14)),
                      visualDensity: VisualDensity(vertical: -4),
                      dense: true,
                    ),
                    ListTile(
                      title: Text("Tax", style: TextStyle(fontSize: 14)),
                      trailing: Text("12.00", style: TextStyle(fontSize: 14)),
                      visualDensity: VisualDensity(vertical: -4),
                      dense: true,
                    ),
                    ListTile(
                      visualDensity: VisualDensity(vertical: -4),
                      title: Text("Total",
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold)),
                      trailing: Text("12.00",
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold)),
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
                    onPressed: () {
                    },
                    child: Text('Place Order'),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    });
  }

  getModifier(cartProductItem object) {
    List<String?> modifier =[];
    String result = '';
    for (int i = 0; i < object.modifier.length; i++) {
      ModifierGroup group = object.modifier[i];
      for (int j = 0; j < group.modifierChild.length; j++) {
        if (group.modifierChild[j].isChecked!){
           modifier.add(group.modifierChild[j].name! + '\n');
           result = modifier.toString().replaceAll('[', '').replaceAll(']', '').replaceAll(',', '+').replaceFirst('', '+ ');
        }
      }
    }
    return result;
  }

  getVariant(cartProductItem object){
    List<String?> variant =[];
    String result = '';
    for(int i = 0; i < object.variant.length; i++) {
      VariantGroup group = object.variant[i];
      for(int j = 0; j < group.child.length; j++){
        if(group.child[j].isSelected!){
          variant.add(group.child[j].name! + '\n');
          result = variant.toString().replaceAll('[', '').replaceAll(']', '').replaceAll(',', '+').replaceFirst('', '+ ');
        }
      }
    }
    return result;
  }

  getRemark(cartProductItem object){
    String result = '';
    if(object.remark != ''){
      result = '*' + object.remark.toString();
    }
    return result;
  }

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
}
