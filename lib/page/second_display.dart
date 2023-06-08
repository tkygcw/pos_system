import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:pos_system/page/progress_bar.dart';
import 'package:presentation_displays/secondary_display.dart';

import '../object/cart_product.dart';
import '../object/second_display_data.dart';
import '../object/variant_group.dart';

class SecondDisplay extends StatefulWidget {
  const SecondDisplay({Key? key}) : super(key: key);

  @override
  State<SecondDisplay> createState() => _SecondDisplayState();
}

class _SecondDisplayState extends State<SecondDisplay> {
  String value = "init";
  SecondDisplayData? obj;
  bool isLoaded = false;

  getVariant(cartProductItem object) {
    List<String?> variant = [];
    String result = '';
    var length = object.variant!.length;
    for (int i = 0; i < length ; i++) {
      VariantGroup group = object.variant![i];
      for (int j = 0; j < group.child!.length; j++) {
        if (group.child![j].isSelected!) {
          variant.add(group.child![j].name!);
          result = '(${variant.toString().replaceAll('[', '').replaceAll(']', '')})';
          //.replaceAll(',', '+')
          //.replaceAll('|', '\n+')
        }
      }
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SecondaryDisplay(
          callback: (argument){
            setState(() {
              if(argument != 'init'){
                var decode = jsonDecode(argument);
                obj = SecondDisplayData.fromJson(decode);
                isLoaded = true;
              }
              value = argument;
            });
          },
          child: value == "init" ?
          Container(
            decoration: BoxDecoration(
                image: DecorationImage(
                  image: AssetImage("drawable/login_background.jpg"),
                  fit: BoxFit.cover,
                )
            ),
            child: Center(
                child: Column(
                  children: [
                    Container(
                        height: 150,
                        child: Image(image: AssetImage("drawable/logo.png"),)
                    ),
                  ],
                )
            ),
          )
              :
          obj != null ?
          Container(
            color: Colors.white24,
            child: Row(
              children: [
                Expanded(
                    flex: 2,
                    child: Container(
                      decoration: BoxDecoration(
                          image: DecorationImage(
                            image: AssetImage("drawable/login_background.jpg"),
                            fit: BoxFit.cover,
                          )
                      ),
                      child: Center(
                          child: Column(
                            children: [
                              Container(
                                  height: 150,
                                  child: Image(image: AssetImage("drawable/logo.png"),)
                              ),
                            ],
                          )
                      ),
                    )
                ),
                Expanded(
                  flex: 3,
                  child: Padding(
                    padding: EdgeInsets.all(10),
                    child: Column(
                      children: [
                        Text('Table No: ${obj?.tableNo}', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24)),
                        Card(
                          elevation: 5,
                          child: Container(
                            padding: EdgeInsets.all(5),
                            child: Row(
                              children: [
                                Expanded(flex: 1, child: Text('Qty'),),
                                Expanded(flex: 4, child: Text('Item'),),
                                Expanded(flex: 1, child: Text('Price/Unit')),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(
                          height: 340,
                          child: ListView.builder(
                              itemCount: obj!.itemList!.length,
                              shrinkWrap: true,
                              itemBuilder: (context, index) {
                                return SizedBox(
                                  height: 20,
                                  child: ListTile(
                                    dense: true,
                                    visualDensity: VisualDensity(horizontal: 0, vertical: -4),
                                    title: Text('${obj!.itemList![index].product_name} ${getVariant(obj!.itemList![index])}'),
                                    leading: Text('${obj!.itemList![index].quantity}'),
                                    trailing: Text('${obj!.itemList![index].price}'),
                                  ),
                                );
                              }
                          ),
                        ),
                        Row(
                          children: [
                            Expanded(
                                child: Card(
                                  elevation: 10,
                                  child: Container(
                                    padding: EdgeInsets.all(10),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('Subtotal: ${obj?.subtotal}', style: TextStyle(fontSize: 12)),
                                        SizedBox(height: 5),
                                        Text('Total Discount: ${obj?.totalDiscount}', style: TextStyle(fontSize: 12))
                                      ],
                                    ),
                                  )
                                )
                            ),
                            Expanded(
                                child: Card(
                                  elevation: 10,
                                  child: Container(
                                    padding: EdgeInsets.all(10),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('Total Tax: ${obj?.totalTax}', style: TextStyle(fontSize: 12)),
                                        SizedBox(height: 5),
                                        Text('Rounding: ${obj?.rounding}', style: TextStyle(fontSize: 12)),
                                      ],
                                    ),
                                  )
                                )
                            )
                          ],
                        ),
                        Expanded(
                            child: Card(
                              elevation: 10,
                              child: Container(
                                alignment: Alignment.centerRight,
                                padding: EdgeInsets.all(5),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text('Total Amount: ${obj?.finalAmount}', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24)),
                                  ],
                                )
                              ),
                            )
                        )
                      ],
                    ),

                  )
                ),
              ],
            )
          )
              :
          CustomProgressBar()
      ),
    );
  }
}
