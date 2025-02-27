import 'dart:convert';
import 'dart:io';
import 'package:collection/collection.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pos_system/database/pos_firestore.dart';
import 'package:pos_system/fragment/product/edit_ingredient.dart';
import 'package:pos_system/notifier/app_setting_notifier.dart';
import 'package:pos_system/object/ingredient_company.dart';
import 'package:pos_system/object/ingredient_company_link_branch.dart';
import 'package:pos_system/object/ingredient_movement.dart';
import 'package:pos_system/translation/AppLocalizations.dart';
import 'package:crypto/crypto.dart';
import 'package:pos_system/utils/Utils.dart';

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
  String _selectedTab = "product";
  List<Product> allProduct = [];
  List<Product> specificProduct = [];
  List<IngredientCompany> ingredientCompanyList = [];
  String? companyID = '';
  bool isLoading = true;
  List<Tab> categoryTab = [];
  List<Widget> categoryTabContent = [];

  String imagePath = '';
  bool isBulkEdit = false;
  List<String> actions = ["ingredient_purchase", "ingredient_extra", "ingredient_damage", "ingredient_lose", "ingredient_theft"];
  Map<int, String> selectedActions = {};
  Map<int, TextEditingController> stockControllers = {};
  Map<int, TextEditingController> remarkControllers = {};
  List<String> stockCalSymbol = [];
  List<int> calNewStock = [];
  bool isNewSync = false;
  int dataSelectLimit = 10;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    readAllCategories();
  }

  void resetAll() {
    calNewStock.clear();


    stockControllers.clear();


    remarkControllers.clear();

    selectedActions.clear();
    stockCalSymbol.clear();
    readAllIngredient();
    setState(() {});
  }

  void calculateStock(int index) {
    if(stockControllers[index] == null){
      stockControllers[index] = TextEditingController();
    }
    int stockUpdateValue = int.tryParse(stockControllers[index]!.text) ?? 0;
    int currentStock = int.parse(ingredientCompanyList[index].stock!);

    if ((selectedActions[index]! == 'ingredient_damage' ||
        selectedActions[index]! == 'ingredient_lose' ||
        selectedActions[index]! == 'ingredient_theft') &&
        stockUpdateValue > currentStock) {
      stockUpdateValue = currentStock;
      stockControllers[index]!.text = stockUpdateValue.toString();
    }

    if (selectedActions[index]! == 'ingredient_damage' ||
        selectedActions[index]! == 'ingredient_lose' ||
        selectedActions[index]! == 'ingredient_theft') {
      calNewStock[index] = currentStock - stockUpdateValue;
      stockCalSymbol[index] = '-';
    } else if (selectedActions[index]! == 'ingredient_extra' ||
        selectedActions[index]! == 'ingredient_purchase') {
      calNewStock[index] = currentStock + stockUpdateValue;
      stockCalSymbol[index] = '+';
    }
    setState(() {});
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
                        child: MediaQuery.of(context).size.width > 500 ? Row(
                          children: [
                            dropdownWidget1(),
                            SizedBox(
                              width: 5,
                            ),
                            dropdownWidget2(),

                            const SizedBox(width: 5),
                            if(MediaQuery.of(context).size.width > 500)
                            Spacer(),
                            if((_selectedTab == 'product' && MediaQuery.of(context).size.width > 750) || _selectedTab == 'ingredient')
                            Row(
                              children: [
                                if(_selectedTab == 'ingredient')
                                  Row(
                                    children: [
                                      ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: isBulkEdit ? Colors.red : color.buttonColor,
                                          foregroundColor: Colors.white, // Text color
                                        ),
                                        onPressed: () {
                                          setState(() {
                                            if(isBulkEdit){
                                              resetAll();
                                            }
                                            isBulkEdit = !isBulkEdit;
                                          });
                                        },
                                        child: Text(isBulkEdit ? AppLocalizations.of(context)!.translate('cancel') : AppLocalizations.of(context)!.translate('bulk_edit')),
                                      ),
                                      SizedBox(width: 5),
                                      if(isBulkEdit)
                                        ElevatedButton(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: color.buttonColor,
                                            foregroundColor: Colors.white, // Text color
                                          ),
                                          onPressed: () {
                                            setState(() async {
                                              if(isBulkEdit){
                                                await updateIngredientStock(context, ingredientCompanyList);
                                                resetAll();
                                              }
                                              isBulkEdit = !isBulkEdit;
                                            });
                                          },
                                          child: Text(AppLocalizations.of(context)!.translate('save')),
                                        ),
                                      SizedBox(width: 10),
                                    ],
                                  ),
                                ConstrainedBox(
                                  constraints: const BoxConstraints(
                                    maxWidth: 250, // Maximum width is 250
                                  ),
                                  child: TextField(
                                    onChanged: (value) {
                                      searchProduct(value);
                                    },
                                    decoration: InputDecoration(
                                      contentPadding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
                                      isDense: true,
                                      border: InputBorder.none,
                                      labelText: AppLocalizations.of(context)!.translate('search'),
                                      focusedBorder: OutlineInputBorder(
                                        borderSide: const BorderSide(color: Colors.grey, width: 2.0),
                                        borderRadius: BorderRadius.circular(25.0),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            )
                          ],
                        ) : Row(
                          children: [
                            Expanded(
                              child: dropdownWidget1(),
                              flex: 1,
                            ),
                            SizedBox(width: 5),
                            Expanded(child: dropdownWidget2(),
                            flex: 1),
                          ],
                        ),
                      ),
                      Expanded(
                        child: _selectedTab == 'product'
                            ? _selectedCategory == 'All Categories' ? GridView.count(
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
                            : _buildSpecificProduct(context, _selectedCategory)
                            : _buildSpecificIngredient(context),
                      ),
                    ],
                  ),
                ),
              ),
            );
    });
  }

  Widget dropdownWidget1() {
    return Container(
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
          items: ["product", "ingredient"]
              .map((e) => DropdownMenuItem<String>(
            value: e,
            child: Text(
              AppLocalizations.of(context)!.translate(e),
              overflow: TextOverflow.visible,
              style: const TextStyle(
                fontSize: 14,
              ),
            ),
          ))
              .toList(),
          value: _selectedTab,
          onChanged: (String? newValue) {
            setState(() {
              _selectedTab = newValue!;
              if (_selectedTab == 'ingredient') {
                ingredientCompanyList = []; // Clear previous data
                readAllIngredient();
              }
            });
          },
        ),
      ),
    );
  }

  Widget dropdownWidget2() {
    return Visibility(
      visible: _selectedTab == 'product',
      child: Container(
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
                specificProduct = [];
              });
              readSpecificProduct(newValue!);
            },
          ),
        ),
      ),
    );
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

  Future<Future<Object?>> openEditIngredientDialog(IngredientCompany data) async {
    return showGeneralDialog(
        barrierColor: Colors.black.withOpacity(0.5),
        transitionBuilder: (context, a1, a2, widget) {
          final curvedValue = Curves.easeInOutBack.transform(a1.value) - 1.0;
          return Transform(
            transform: Matrix4.translationValues(0.0, curvedValue * 200, 0.0),
            child: Opacity(
              opacity: a1.value,
              child: EditIngredientDialog(
                callBack: () => readAllCategories(),
                ingredient_company: data,
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
    setState(() {
      specificProduct = data;
    });
  }

  readAllIngredient() async {
    List<IngredientCompany> data = await PosDatabase.instance.readAllIngredientCompany();
    setState(() {
      ingredientCompanyList = data;
      print("ingredientCompanyList length: ${ingredientCompanyList.length}");
      for(int i = 0; i < ingredientCompanyList.length; i++){
        calNewStock.add(int.parse(ingredientCompanyList[i].stock!));
        stockCalSymbol.add('-');
      }
    });
  }

  searchProduct(String text) async {
    if(_selectedTab == 'product') {
      _selectedCategory = 'All Categories';
      List<Product> data = await PosDatabase.instance.searchProduct(text);
      setState(() {
        allProduct = data;
      });
    } else {
      List<IngredientCompany> data = await PosDatabase.instance.searchIngredient(text);
      setState(() {
        ingredientCompanyList = data;
      });
    }
  }

  Widget _buildSpecificProduct(BuildContext context, String label) {
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
        children: List.generate(specificProduct.length, //this is the total number of cards
            (index) {
          return Card(
            child: Container(
              decoration: (specificProduct[index].graphic_type == '2'
                  ? BoxDecoration(
                      image: DecorationImage(image: FileImage(File(imagePath + '/' + specificProduct[index].image!)), fit: BoxFit.cover))
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
                      height: 30,
                      width: 200,
                      alignment: Alignment.center,
                      child: Text(
                        specificProduct[index].SKU! + ' ' + specificProduct[index].name!,
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

  Widget _buildSpecificIngredient(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(10),
      child: ListView.builder(
        shrinkWrap: true,
        physics: NeverScrollableScrollPhysics(),
        itemCount: ingredientCompanyList.length,
        itemBuilder: (context, index) {
          var ingredient = ingredientCompanyList[index];

          return Column(
            children: [
              isBulkEdit ? ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.grey.shade400,
                  child: Text(
                    ingredient.name![0].toUpperCase(),
                    style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
                title: Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: Text(
                        ingredient.name!,
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      flex: 1,
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 10),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade400),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: selectedActions[index],
                            hint: Text(AppLocalizations.of(context)!.translate('action'), style: TextStyle(fontSize: 14)),
                            icon: Icon(Icons.arrow_drop_down, color: Colors.black54),
                            items: actions.map((String action) {
                              return DropdownMenuItem<String>(
                                value: action,
                                child: Text(AppLocalizations.of(context)!.translate(action), style: TextStyle(fontSize: 14)),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                selectedActions[index] = value!;
                                remarkControllers[index] = TextEditingController(text: AppLocalizations.of(context)!.translate(value));
                                calculateStock(index);
                              });
                            },
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      flex: 1,
                      child: TextField(
                        controller: stockControllers[index],
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly
                        ],
                        decoration: InputDecoration(
                          hintText: AppLocalizations.of(context)!.translate('quantity'),
                          filled: true,
                          fillColor: Colors.grey.shade100,
                          prefixText: '${stockCalSymbol[index]} ',
                          contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.grey.shade400),
                          ),
                        ),
                        onChanged: (value) {
                          setState(() {
                            calculateStock(index);
                          });
                        },
                      ),
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      flex: 3,
                      child: TextField(
                        controller: remarkControllers[index],
                        decoration: InputDecoration(
                          hintText: AppLocalizations.of(context)!.translate('remark'),
                          filled: true,
                          fillColor: Colors.grey.shade100,
                          contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.grey.shade400),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 1,
                      child: Align(
                        alignment: Alignment.centerRight, // Aligns text to the right
                        child: Text(
                          // "${ingredient.unit}",
                          "${calNewStock[index]} ${ingredient.unit}",
                          style: TextStyle(fontSize: 14, color: Colors.black54),
                          textAlign: TextAlign.right, // Ensures right alignment
                        ),
                      ),
                    ),
                  ],
                ),
              )
              : ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.grey.shade400,
                  child: Text(
                    ingredient.name![0].toUpperCase(),
                    style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
                title: Text(
                  "${ingredient.name!}",
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                ),
                trailing: Text(
                  "${ingredient.stock} ${ingredient.unit}",
                  style: TextStyle(fontSize: 14, color: Colors.black54),
                ),
                onTap: () {
                  openEditIngredientDialog(ingredient);
                },
              ),
              Divider(height: 1, thickness: 1),
            ],
          );
        },
      ),
    );
  }

  updateIngredientStock(BuildContext context, List<IngredientCompany> ingredientCompanyList) async {
    int validIngredientCount = 0;
    final prefs = await SharedPreferences.getInstance();
    final int? branch_id = prefs.getInt('branch_id');
    PosFirestore posFirestore = PosFirestore.instance;
    isNewSync = prefs.getInt('new_sync') == 1 ? true : false;
    dataSelectLimit = isNewSync ? 1000 : 10;
    DateFormat dateFormat = DateFormat("yyyy-MM-dd HH:mm:ss");
    String dateTime = dateFormat.format(DateTime.now());

    for(int i = 0; i < ingredientCompanyList.length; i++){
      for (int i = 0; i < ingredientCompanyList.length; i++) {
        if (selectedActions[i] != null &&
            stockControllers[i] != null &&
            stockControllers[i]!.text.isNotEmpty &&
            stockControllers[i]!.text != '0') {
          validIngredientCount++;
        }
      }
      if(selectedActions[i] != null && stockControllers[i] != null && stockControllers[i]!.text != ''){
        if(stockControllers[i]!.text != '0'){
          List<IngredientCompanyLinkBranch> data = await PosDatabase.instance.readIngredientCompanyLinkBranchWithIngredientCompanyId(ingredientCompanyList[i].ingredient_company_id!);

          IngredientMovement ingredientMovement = IngredientMovement(
              ingredient_movement_id: 0,
              ingredient_movement_key: '',
              branch_id: branch_id.toString(),
              ingredient_company_link_branch_id: data[0].ingredient_company_link_branch_id.toString(),
              order_cache_key: '',
              order_detail_key: '',
              order_modifier_detail_key: '',
              type: stockCalSymbol[i] == '+' ? 1 : 2,
              movement: '${stockCalSymbol[i]}${stockControllers[i]!.text}',
              source: 0,
              remark: remarkControllers[i]!.text,
              calculate_status: 1,
              sync_status: 0,
              created_at: dateTime,
              updated_at: '',
              soft_delete: ''
          );
          IngredientMovement movementData = await PosDatabase.instance.insertSqliteIngredientMovement(ingredientMovement);
          await insertIngredientMovementKey(movementData, dateTime);

          IngredientCompanyLinkBranch object = IngredientCompanyLinkBranch(
            updated_at: dateTime,
            sync_status: 2,
            stock_quantity: calNewStock[i].toString(),
            ingredient_company_link_branch_id: data[0].ingredient_company_link_branch_id,
          );
          await PosDatabase.instance.updateIngredientCompanyLinkBranchStock(object);
          posFirestore.updateIngredientCompanyLinkBranchStock(object);
        }
      }
    }
  }

  insertIngredientMovementKey(IngredientMovement ingredientMovement, String dateTime) async {
    String key = await generateIngredientMovementKey(ingredientMovement);
    IngredientMovement data = IngredientMovement(
        updated_at: dateTime,
        sync_status: 0,
        ingredient_movement_key: key,
        ingredient_movement_sqlite_id: ingredientMovement.ingredient_movement_sqlite_id
    );
    await PosDatabase.instance.updateIngredientMovementKey(data);
  }

  Future<String> generateIngredientMovementKey(IngredientMovement ingredientMovement) async {
    final prefs = await SharedPreferences.getInstance();
    final int? device_id = prefs.getInt('device_id');
    var bytes = ingredientMovement.created_at!.replaceAll(new RegExp(r'[^0-9]'), '') + ingredientMovement.ingredient_movement_sqlite_id.toString() + device_id.toString();
    var md5Hash = md5.convert(utf8.encode(bytes));
    return Utils.shortHashString(hashCode: md5Hash);
  }
}
