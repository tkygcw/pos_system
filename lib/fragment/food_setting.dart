import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:pos_system/fragment/add_product.dart';
import 'package:pos_system/fragment/edit_product.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../database/pos_database.dart';
import '../notifier/theme_color.dart';
import '../object/categories.dart';
import '../object/colorCode.dart';
import '../object/product.dart';
import '../page/progress_bar.dart';

class FoodSetting extends StatefulWidget {
  const FoodSetting({Key? key}) : super(key: key);

  @override
  _FoodSettingState createState() => _FoodSettingState();
}

class _FoodSettingState extends State<FoodSetting> {
  List<String> categoryList = [];
  String _selectedCategory = 'All Categories';
  List<Product> allProduct = [];
  List<Product> specificProduct = [];
  String? companyID = '';
  bool isLoading = true;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    readAllCategories();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeColor>(builder: (context, ThemeColor color, child) {
      return isLoading
          ? CustomProgressBar()
          : Scaffold(
              resizeToAvoidBottomInset: false,
              body: Container(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(18, 0, 0, 0),
                            child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                    primary: color.backgroundColor),
                                onPressed: () {
                                  print('open add dialog');
                                  openAddProductDialog();
                                },
                                icon: Icon(Icons.add),
                                label: Text("Product")),
                          ),
                          Expanded(
                            child: Padding(
                              padding: EdgeInsets.fromLTRB(0, 0, 60, 0),
                              child: DropdownButton<String>(
                                onChanged: (String? value) {
                                  setState(() {
                                    _selectedCategory = value!;
                                  });
                                },
                                menuMaxHeight: 300,
                                value: _selectedCategory,
                                // Hide the default underline
                                underline: Container(),
                                icon: Icon(
                                  Icons.arrow_drop_down,
                                  color: color.backgroundColor,
                                ),
                                isExpanded: true,
                                // The list of options
                                items: categoryList
                                    .map((e) => DropdownMenuItem(
                                          value: e,
                                          child: Container(
                                            alignment: Alignment.centerLeft,
                                            child: Text(
                                              e,
                                              style: TextStyle(fontSize: 18),
                                            ),
                                          ),
                                        ))
                                    .toList(),
                                // Customize the selected item
                                selectedItemBuilder: (BuildContext context) =>
                                    categoryList
                                        .map((e) => Center(
                                              child: Text(e),
                                            ))
                                        .toList(),
                              ),
                            ),
                          ),
                          SizedBox(width: 300),
                          Expanded(
                            child: TextField(
                              onChanged: (value) {
                                _selectedCategory = 'All Categories';
                                searchProduct(value);
                              },
                              decoration: InputDecoration(
                                contentPadding:
                                    EdgeInsets.fromLTRB(10, 10, 10, 10),
                                isDense: true,
                                border: InputBorder.none,
                                labelText: 'Search',
                                focusedBorder: OutlineInputBorder(
                                  borderSide: const BorderSide(
                                      color: Colors.grey, width: 2.0),
                                  borderRadius: BorderRadius.circular(25.0),
                                ),
                              ),
                            ),
                          )
                        ],
                      ),
                      Expanded(
                        child: _selectedCategory == 'All Categories'
                            ? GridView.count(
                                padding: const EdgeInsets.all(10),
                                shrinkWrap: true,
                                crossAxisCount: 6,
                                children: List.generate(
                                    allProduct
                                        .length, //this is the total number of cards
                                    (index) {
                                  return Card(
                                    child: Container(
                                      decoration: (allProduct[index]
                                                  .graphic_type ==
                                              '2'
                                          ? BoxDecoration(
                                              image: DecorationImage(
                                                  image: FileImage(File(
                                                      'data/user/0/com.example.pos_system/files/assets/' +
                                                          companyID! +
                                                          '/' +
                                                          allProduct[index]
                                                              .image!)),
                                                  fit: BoxFit.cover))
                                          : BoxDecoration(
                                              color: HexColor(
                                                  allProduct[index].color!))),
                                      child: InkWell(
                                        splashColor: Colors.blue.withAlpha(30),
                                        onTap: () {
                                          openEditProductDialog(
                                              allProduct[index]);
                                        },
                                        child: Stack(
                                          alignment: Alignment.bottomLeft,
                                          children: [
                                            Container(
                                              color:
                                                  Colors.black.withOpacity(0.5),
                                              height: 30,
                                              width: 200,
                                              alignment: Alignment.center,
                                              child: Text(
                                                allProduct[index].SKU! +
                                                    ' ' +
                                                    allProduct[index].name!,
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.white,
                                                  fontSize: 13,
                                                ),
                                              ),
                                            )
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                }),
                              )
                            : _buildSpecificProduct(context, _selectedCategory),
                      ),
                    ],
                  ),
                ),
              ),
            );
    });
  }

  Future<Future<Object?>> openAddProductDialog() async {
    return showGeneralDialog(
        barrierColor: Colors.black.withOpacity(0.5),
        transitionBuilder: (context, a1, a2, widget) {
          final curvedValue = Curves.easeInOutBack.transform(a1.value) - 1.0;
          return Transform(
            transform: Matrix4.translationValues(0.0, curvedValue * 200, 0.0),
            child: Opacity(
              opacity: a1.value,
              child: AddProductDialog(callBack: () => readAllCategories()),
            ),
          );
        },
        transitionDuration: Duration(milliseconds: 200),
        barrierDismissible: false,
        context: context,
        pageBuilder: (context, animation1, animation2) {
          return null!;
        });
  }

  Future<Future<Object?>> openEditProductDialog(Product data) async {
    return showGeneralDialog(
        barrierColor: Colors.black.withOpacity(0.5),
        transitionBuilder: (context, a1, a2, widget) {
          final curvedValue = Curves.easeInOutBack.transform(a1.value) - 1.0;
          return Transform(
            transform: Matrix4.translationValues(0.0, curvedValue * 200, 0.0),
            child: Opacity(
              opacity: a1.value,
              child: EditProductDialog(
                product: data,
              ),
            ),
          );
        },
        transitionDuration: Duration(milliseconds: 200),
        barrierDismissible: false,
        context: context,
        pageBuilder: (context, animation1, animation2) {
          return null!;
        });
  }

  readAllCategories() async {
    if (categoryList.isEmpty) {
      categoryList.add('All Categories');
    }
    List<Categories> data = await PosDatabase.instance.readAllCategories();
    if(categoryList.length <= 1){
      for (int i = 0; i < data.length; i++) {
        categoryList.add(data[i].name!);
      }
    }
    readCompanyID();
    readAllProduct();
  }

  readAllProduct() async {
    List<Product> data = await PosDatabase.instance.readAllProduct();
    setState(() {
      allProduct = data;
      isLoading = false;
    });
  }

  readCompanyID() async {
    final prefs = await SharedPreferences.getInstance();
    final String? user = prefs.getString('user');
    Map userObject = json.decode(user!);
    companyID = userObject['company_id'];
  }

  readSpecificProduct(String label) async {
    List<Product> data = await PosDatabase.instance.readSpecificProduct(label);
    setState(() {
      specificProduct = data;
    });
  }

  searchProduct(String text) async {
    List<Product> data = await PosDatabase.instance.searchProduct(text);
    setState(() {
      allProduct = data;
    });
  }

  Widget _buildSpecificProduct(BuildContext context, String label) {
    readSpecificProduct(label);
    return GridView.count(
        padding: const EdgeInsets.all(10),
        shrinkWrap: true,
        crossAxisCount: 6,
        children: List.generate(
            specificProduct.length, //this is the total number of cards
            (index) {
          return Card(
            child: Container(
              decoration: (specificProduct[index].graphic_type == '2'
                  ? BoxDecoration(
                      image: DecorationImage(
                          image: FileImage(File(
                              'data/user/0/com.example.pos_system/files/assets/' +
                                  companyID! +
                                  '/' +
                                  specificProduct[index].image!)),
                          fit: BoxFit.cover))
                  : BoxDecoration(
                      color: HexColor(specificProduct[index].color!))),
              child: InkWell(
                splashColor: Colors.blue.withAlpha(30),
                onTap: () {
                  openEditProductDialog(specificProduct[index]);
                },
                child: Stack(
                  alignment: Alignment.bottomLeft,
                  children: [
                    Container(
                      color: Colors.black.withOpacity(0.5),
                      height: 30,
                      width: 200,
                      alignment: Alignment.center,
                      child: Text(
                        specificProduct[index].SKU! +
                            ' ' +
                            specificProduct[index].name!,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          fontSize: 13,
                        ),
                      ),
                    )
                  ],
                ),
              ),
            ),
          );
        }));
  }
}
