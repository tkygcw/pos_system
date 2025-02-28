import 'dart:convert';
import 'dart:io';
import 'package:collection/collection.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pos_system/notifier/app_setting_notifier.dart';
import 'package:pos_system/translation/AppLocalizations.dart';

import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../database/pos_database.dart';
import '../../notifier/theme_color.dart';
import '../../object/categories.dart';
import '../../object/colorCode.dart';
import '../../object/product.dart';
import '../../page/progress_bar.dart';
import '../product/edit_product.dart';
import 'dart:io' as Platform;

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
  List<Tab> categoryTab = [];
  List<Widget> categoryTabContent = [];

  String imagePath = '';

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
                  padding: const EdgeInsets.all(0),
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(10.0),
                        child: Row(
                          children: [
                            Container(
                              width: 250,
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton2(
                                  isExpanded: true,
                                  buttonStyleData: ButtonStyleData(
                                    height: 40,
                                    padding: const EdgeInsets.only(left: 14, right: 14),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(5),
                                      border: Border.all(
                                        color: Colors.black26,
                                      ),
                                    ),
                                  ),
                                  dropdownStyleData: DropdownStyleData(
                                    maxHeight: 400,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(10),
                                      color: Colors.grey.shade100,
                                    ),
                                    scrollbarTheme: ScrollbarThemeData(
                                      thickness: WidgetStateProperty.all(5),
                                      mainAxisMargin: 20,
                                      crossAxisMargin: 5,
                                    ),
                                  ),
                                  items: categoryList
                                      .map((e) => DropdownMenuItem<String>(
                                    value: e,
                                    child: Text(
                                      e,
                                      overflow: TextOverflow.visible,
                                      style: const TextStyle(
                                        fontSize: 14,
                                      ),
                                    ),
                                  ))
                                      .toList(),
                                  value: _selectedCategory,
                                  onChanged: (String? newValue) {
                                    setState(() {
                                      _selectedCategory = newValue!;
                                    });
                                  },
                                ),
                              ),
                            ),
                            if(MediaQuery.of(context).size.width > 500)
                              Spacer(),
                            if(MediaQuery.of(context).size.width > 500)
                              SizedBox(
                              width: 250,
                              child: TextField(
                                onChanged: (value) {
                                  _selectedCategory = 'All Categories';
                                  searchProduct(value);
                                },
                                decoration: InputDecoration(
                                  contentPadding: EdgeInsets.fromLTRB(10, 10, 10, 10),
                                  isDense: true,
                                  border: InputBorder.none,
                                  labelText: AppLocalizations.of(context)!.translate('search'),
                                  focusedBorder: OutlineInputBorder(
                                    borderSide: const BorderSide(color: Colors.grey, width: 2.0),
                                    borderRadius: BorderRadius.circular(25.0),
                                  ),
                                ),
                              ),
                            )
                          ],
                        ),
                      ),
                      Expanded(
                        child: _selectedCategory == 'All Categories'
                            ? GridView.count(
                                padding: const EdgeInsets.all(10),
                                shrinkWrap: true,
                                crossAxisCount: MediaQuery.of(context).orientation == Orientation.landscape
                                    ? MediaQuery.of(context).size.height > 500 && MediaQuery.of(context).size.width > 900 ? 7
                                    : MediaQuery.of(context).size.height > 450 && MediaQuery.of(context).size.width > 800 ? 5
                                    : 4
                                    : MediaQuery.of(context).size.height > 900 && MediaQuery.of(context).size.width > 500 ? 5
                                    : MediaQuery.of(context).size.height > 800 && MediaQuery.of(context).size.width > 450 ? 4
                                    : 3,
                                children: List.generate(allProduct.length, //this is the total number of cards
                                    (index) {
                                  return Card(
                                    child: Container(
                                      decoration: (allProduct[index].graphic_type == '2'
                                          ? BoxDecoration(
                                              image: DecorationImage(
                                                  image: FileImage(File(imagePath + '/' + allProduct[index].image!)),
                                                  fit: BoxFit.cover))
                                          : BoxDecoration(color: HexColor(allProduct[index].color!))),
                                      child: InkWell(
                                        splashColor: Colors.blue.withAlpha(30),
                                        onTap: () {
                                          openEditProductDialog(allProduct[index]);
                                        },
                                        child: Stack(
                                          alignment: Alignment.bottomLeft,
                                          children: [
                                            Container(
                                              color: Colors.black.withOpacity(0.5),
                                              padding: EdgeInsets.fromLTRB(5, 2, 5, 2),
                                              height: 50,
                                              width: 200,
                                              alignment: Alignment.center,
                                              child: Text(
                                                allProduct[index].SKU! + ' ' + allProduct[index].name!,
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
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
                callBack: () => readAllCategories(),
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
    await getPreferences();
    if (categoryList.isEmpty) {
      categoryList.add('All Categories');
    }
    List<Categories> data = await PosDatabase.instance.readAllCategories();
    if (categoryList.length <= 1) {
      for (int i = 0; i < data.length; i++) {
        categoryList.add(data[i].name!);
      }
    }
    await readAllProduct();
  }

  readAllProduct() async {
    List<Product> data = await PosDatabase.instance.readAllProductForProductSetting();
    data = sortProduct(data);
    if(mounted){
      setState(() {
        allProduct = data;
        isLoading = false;
      });
    }
  }

  Future<String> get _localPath async {
    final directory = await getApplicationSupportDirectory();
    return directory.path;
  }

  getPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    final String? user = prefs.getString('user');
    Map userObject = json.decode(user!);
    companyID = userObject['company_id'];

    if(Platform.Platform.isIOS){
      String dir = await _localPath;
      imagePath = dir + '/assets/$companyID';
    } else {
      imagePath = prefs.getString('local_path')!;
    }
  }

  sortCategory(List<Categories> list){
    list.sort((a, b) {
      final aNumber = a.sequence!;
      final bNumber = b.sequence!;

      bool isANumeric = int.tryParse(aNumber) != null;
      bool isBNumeric = int.tryParse(bNumber) != null;

      if (isANumeric && isBNumeric) {
        return int.parse(aNumber).compareTo(int.parse(bNumber));
      } else if (isANumeric) {
        return -1; // Numeric before alphanumeric
      } else if (isBNumeric) {
        return 1; // Alphanumeric before numeric
      } else if (!isANumeric && !isBNumeric) {
        return compareNatural(a.name!, b.name!);
      } else {
        // Custom alphanumeric sorting logic
        return compareNatural(aNumber, bNumber);
      }
    });
    return list;
  }

  sortProduct(List<Product> list){
    List<Product> hasSequenceProduct = list.where((e) => e.sequence_number != null && e.sequence_number != '').toList();
    hasSequenceProduct.sort((a, b) {
      final aNumber = a.sequence_number!;
      final bNumber = b.sequence_number!;

      bool isANumeric = int.tryParse(aNumber) != null;
      bool isBNumeric = int.tryParse(bNumber) != null;

      if (isANumeric && isBNumeric) {
        return int.parse(aNumber).compareTo(int.parse(bNumber));
      } else if (isANumeric) {
        return -1; // Numeric before alphanumeric
      } else if (isBNumeric) {
        return 1; // Alphanumeric before numeric
      } else {
        // Custom alphanumeric sorting logic
        return compareNatural(aNumber, bNumber);
      }
    });
    list.removeWhere((e) => e.sequence_number != null && e.sequence_number != '');
    List<Product> sortedList2 = getSortedList(list);
    return hasSequenceProduct + sortedList2;
  }

  List<Product> getSortedList(List<Product> noSequenceProduct){
    switch(AppSettingModel.instance.product_sort_by){
      case 1 :{
        return sortByProductName(noSequenceProduct);
      }
      case 2: {
        return sortByProductSKU(noSequenceProduct);
      }
      case 3: {
        return sortByProductPrice(noSequenceProduct);
      }
      case 4: {
        return sortByProductName(noSequenceProduct, isDESC: true);
      }
      case 5: {
        return sortByProductSKU(noSequenceProduct, isDESC: true);
      }
      case 6: {
        return sortByProductPrice(noSequenceProduct, isDESC: true);
      }
      default: {
        return noSequenceProduct;
      }
    }
  }

  sortByProductName(List<Product> sortedList, {isDESC}){
    sortedList.sort((a, b){
      return compareNatural(a.name!, b.name!);
    });
    return isDESC == null ? sortedList : sortedList.reversed.toList();
  }

  sortByProductSKU(List<Product> sortedList, {bool? isDESC}){
    sortedList.sort((a, b){
      return compareNatural(a.SKU!, b.SKU!);
    });
    return isDESC == null ? sortedList : sortedList.reversed.toList();
  }

  sortByProductPrice(List<Product> sortedList, {bool? isDESC}){
    sortedList.sort((a, b){
      return compareNatural(a.price!, b.price!);
    });
    return isDESC == null ? sortedList : sortedList.reversed.toList();
  }

  readSpecificProduct(String label) async {
    List<Product> data = await PosDatabase.instance.readSpecificProduct(label);
    specificProduct = data;
  }

  searchProduct(String text) async {
    List<Product> data = await PosDatabase.instance.searchProduct(text);
    setState(() {
      allProduct = data;
    });
  }

  Widget _buildSpecificProduct(BuildContext context, String label) {
    return FutureBuilder<void>(
      future: readSpecificProduct(label), // Fetch data asynchronously
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CustomProgressBar()); // Show loading indicator
        } else if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        return GridView.count(
          padding: const EdgeInsets.all(10),
          shrinkWrap: true,
          crossAxisCount: MediaQuery.of(context).orientation == Orientation.landscape
              ? MediaQuery.of(context).size.height > 500 && MediaQuery.of(context).size.width > 900 ? 7
              : MediaQuery.of(context).size.height > 450 && MediaQuery.of(context).size.width > 800 ? 5
              : 4
              : MediaQuery.of(context).size.height > 900 && MediaQuery.of(context).size.width > 500 ? 5
              : MediaQuery.of(context).size.height > 800 && MediaQuery.of(context).size.width > 450 ? 4
              : 3,
          children: List.generate(specificProduct.length, (index) {
            return Card(
              child: Container(
                decoration: (specificProduct[index].graphic_type == '2'
                    ? BoxDecoration(
                  image: DecorationImage(
                    image: FileImage(File(imagePath + '/' + specificProduct[index].image!)),
                    fit: BoxFit.cover,
                  ),
                )
                    : BoxDecoration(color: HexColor(specificProduct[index].color!))),
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
                        padding: EdgeInsets.fromLTRB(5, 2, 5, 2),
                        height: 50,
                        width: 200,
                        alignment: Alignment.center,
                        child: Text(
                          '${specificProduct[index].SKU!} ${specificProduct[index].name!}',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
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
        );
      },
    );
  }

}
