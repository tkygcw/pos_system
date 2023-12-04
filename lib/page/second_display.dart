import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:pos_system/database/pos_database.dart';
import 'package:pos_system/object/second_screen.dart';
import 'package:pos_system/page/progress_bar.dart';
import 'package:pos_system/translation/AppLocalizations.dart';
import 'package:presentation_displays/secondary_display.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../object/cart_product.dart';
import '../object/second_display_data.dart';
import '../object/variant_group.dart';

class SecondDisplay extends StatefulWidget {
  const SecondDisplay({Key? key}) : super(key: key);

  @override
  State<SecondDisplay> createState() => _SecondDisplayState();
}

class _SecondDisplayState extends State<SecondDisplay> {
  String value = "init", imagePath = '';
  List<FileImage> imageList = [];
  SecondDisplayData? obj;
  bool isLoaded = false, bannerLoaded = false;

  @override
  void initState() {
    getBanner();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SecondaryDisplay(
          callback: (argument){
            try{
              switch(argument){
                case "init": {
                  setState(() {
                    value = argument;
                  });
                }break;
                case "refresh_img": {
                  getBanner();
                }break;
                default: {
                  var decode = jsonDecode(argument);
                  obj = SecondDisplayData.fromJson(decode);
                  isLoaded = true;
                  setState(() {
                    value = argument;
                  });
                }
              }
            } catch(e){
              print("second display callback error: $e");
              setState(() {
                value == "init";
              });
            }
          },
          child: value == "init" && bannerLoaded == true ?
              imageList.isNotEmpty ?
              CarouselSlider(
                items: imageList.map((item) {
                  return Builder(
                    builder: (BuildContext context) {
                      return Container(
                          width: MediaQuery.of(context).size.width,
                          child: Image(image: item, fit: BoxFit.cover)
                      );
                    },
                  );
                }).toList(),
                options: CarouselOptions(
                  height: MediaQuery.of(context).size.height,
                  autoPlay: imageList.length > 1 ? true : false,
                  autoPlayInterval: Duration(seconds: 8),
                  viewportFraction: 1,
                  pageSnapping: false,
                ),
              ) :
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
              ) :
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
                        Text(AppLocalizations.of(context)!.translate('table_no')+': ${obj?.tableNo}', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24)),
                        Card(
                          elevation: 5,
                          child: Container(
                            padding: EdgeInsets.all(5),
                            child: Row(
                              children: [
                                Expanded(flex: 1, child: Text(AppLocalizations.of(context)!.translate('qty')),),
                                Expanded(flex: 4, child: Text(AppLocalizations.of(context)!.translate('item')),),
                                Expanded(flex: 1, child: Text(AppLocalizations.of(context)!.translate('price_unit'))),
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
                                    trailing: Text('${obj!.itemList![index].price!}/${obj!.itemList![index].per_quantity_unit!}${obj!.itemList![index].unit!}'),
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
                                        Text(AppLocalizations.of(context)!.translate('subtotal')+': ${obj?.subtotal}', style: TextStyle(fontSize: 12)),
                                        SizedBox(height: 5),
                                        Text(AppLocalizations.of(context)!.translate('total_discount')+': ${obj?.totalDiscount}', style: TextStyle(fontSize: 12))
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
                                        Text(AppLocalizations.of(context)!.translate('total_tax')+': ${obj?.totalTax}', style: TextStyle(fontSize: 12)),
                                        SizedBox(height: 5),
                                        Text(AppLocalizations.of(context)!.translate('rounding')+': ${obj?.rounding}', style: TextStyle(fontSize: 12)),
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

  getBanner() async {
    imageList.clear();
    final prefs = await SharedPreferences.getInstance();
    imagePath = prefs.getString('banner_path')!;
    List<SecondScreen> data = await PosDatabase.instance.readAllNotDeletedSecondScreen();
    if(data.isNotEmpty){
      for(int i = 0; i < data.length; i++){
        imageList.add(FileImage(File(imagePath + '/' + data[i].name!)));
      }
    }
    setState(() {
      bannerLoaded = true;
    });
  }

  getVariant(cartProductItem object) {
    List<String?> variant = [];
    String result = '';
    try{
      if(object.productVariantName != '' && object.productVariantName != null){
        result = "(${object.productVariantName!})";
      } else if(object.variant != null) {
        var length = object.variant!.length;
        for (int i = 0; i < length ; i++) {
          VariantGroup group = object.variant![i];
          for (int j = 0; j < group.child!.length; j++) {
            if (group.child![j].isSelected!) {
              variant.add(group.child![j].name!);
              result = '(${variant.toString().replaceAll('[', '').replaceAll(']', '')})'
                  .replaceAll(',', ' |');
              //.replaceAll('|', '\n+')
            }
          }
        }
      }
    }catch(e){
      print("second display get variant error: ${e}");
      result = "";
    }
    return result;
  }
}
