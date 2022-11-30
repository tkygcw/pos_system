import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:pos_system/fragment/product/product_order_dialog.dart';
import 'package:pos_system/object/categories.dart';
import 'package:pos_system/object/product.dart';
import 'package:pos_system/page/progress_bar.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../database/pos_database.dart';
import '../../notifier/theme_color.dart';
import '../../object/colorCode.dart';

class FoodMenu extends StatefulWidget {
  const FoodMenu({Key? key}) : super(key: key);

  @override
  _FoodMenuState createState() => _FoodMenuState();
}

class _FoodMenuState extends State<FoodMenu> with TickerProviderStateMixin {
  List<Tab> categoryTab = [];
  List<Widget> categoryTabContent = [];
  List<String> categoryList = [];
  late TabController _tabController;
  late String companyID;
  List<Product> allProduct = [];
  List<Product> specificProduct = [];
  TextEditingController searchController = new TextEditingController();
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    readAllCategories();
    // _tabController = TabController(length: 0, vsync: this);
  }

  @override
  void dispose() {
    // TODO: implement dispose
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeColor>(builder: (context, ThemeColor color, child) {
      return isLoading
          ? CustomProgressBar()
          : Scaffold(
        resizeToAvoidBottomInset: false,
        body: Container(
          child: Column(children: [
            Padding(
              padding: EdgeInsets.fromLTRB(11, 8, 11, 4),
              child: Row(
                children: [
                  Expanded(
                      child: Text(
                        "Menu",
                        style: TextStyle(
                            fontSize: 25, color: color.backgroundColor),
                      )),
                  SizedBox(width: MediaQuery.of(context).size.height > 500 ? 400 : 0),
                  Expanded(
                    child: TextField(
                      onChanged: (value) {
                        _tabController.index = 0;
                        setState(() {
                          searchProduct(value);
                        });
                      },
                      controller: searchController,
                      decoration: InputDecoration(
                        isDense: true,
                        border: InputBorder.none,
                        labelText: 'Search ',
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
            ),
            SizedBox(height: 10),
            TabBar(
              isScrollable: true,
              unselectedLabelColor: Colors.black,
              labelColor: color.buttonColor,
              indicatorColor: color.buttonColor,
              tabs: categoryTab,
              controller: _tabController,
              indicatorSize: TabBarIndicatorSize.tab,
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(4.0),
                child: TabBarView(
                    controller: _tabController,
                    children: categoryTabContent),
              ),
            ),
          ]),
        ),
      );
    });
  }

  Future<Future<Object?>> openProductOrderDialog(Product product) async {
    return showGeneralDialog(
        barrierColor: Colors.black.withOpacity(0.5),
        transitionBuilder: (context, a1, a2, widget) {
          final curvedValue = Curves.easeInOutBack.transform(a1.value) - 1.0;
          return Transform(
            transform: Matrix4.translationValues(0.0, curvedValue * 200, 0.0),
            child: Opacity(
                opacity: a1.value,
                child: ProductOrderDialog(
                  productDetail: product,
                )),
          );
        },
        transitionDuration: Duration(milliseconds: 200),
        barrierDismissible: false,
        context: context,
        pageBuilder: (context, animation1, animation2) {
          return null!;
        });
  }

  void refresh() {
    isLoading = false;
    setState(() {});
  }

  readAllCategories() async {
    await readCompanyID();
    List<Categories> data = await PosDatabase.instance.readAllCategories();
    categoryTab.add(Tab(
      text: 'All Category',
    ));
    categoryList.add('All Category');
    for (int i = 0; i < data.length; i++) {
      categoryTab.add(Tab(
        text: data[i].name!,
      ));
      categoryList.add(data[i].name!);
    }

    for (int i = 0; i < categoryList.length; i++) {
      if (categoryList[i] == 'All Category') {
        List<Product> data = await PosDatabase.instance.readAllProduct();
        categoryTabContent.add(GridView.count(
            shrinkWrap: true,
            crossAxisCount: 5,
            children: List.generate(data.length, (index) {
              return Card(
                child: Container(
                  decoration: (data[index].graphic_type == '2'
                      ? BoxDecoration(
                      image: DecorationImage(
                          image: FileImage(File(
                              'data/user/0/com.example.pos_system/files/assets/' +
                                  companyID +
                                  '/' +
                                  data[index].image!)),
                          fit: BoxFit.cover))
                      : BoxDecoration(color: HexColor(data[index].color!))),
                  child: InkWell(
                    splashColor: Colors.blue.withAlpha(30),
                    onTap: () {
                      openProductOrderDialog(data[index]);
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
                            data[index].SKU! + ' ' + data[index].name!,
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
            })));
      } else {
        List<Product> data =
        await PosDatabase.instance.readSpecificProduct(categoryList[i]);
        categoryTabContent.add(GridView.count(
            shrinkWrap: true,
            crossAxisCount: 5,
            children: List.generate(data.length, (index) {
              return Card(
                child: Container(
                  decoration: (data[index].graphic_type == '2'
                      ? BoxDecoration(
                      image: DecorationImage(
                          image: FileImage(File(
                              'data/user/0/com.example.pos_system/files/assets/' +
                                  companyID +
                                  '/' +
                                  data[index].image!)),
                          fit: BoxFit.cover))
                      : BoxDecoration(color: HexColor(data[index].color!))),
                  child: InkWell(
                    splashColor: Colors.blue.withAlpha(30),
                    onTap: () {
                      openProductOrderDialog(data[index]);
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
                            data[index].SKU! + ' ' + data[index].name!,
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
            })));
      }
    }
    refresh();
    _tabController = TabController(length: categoryTab.length, vsync: this);
  }

  readCompanyID() async {
    final prefs = await SharedPreferences.getInstance();
    final String? user = prefs.getString('user');
    Map userObject = json.decode(user!);
    companyID = userObject['company_id'];
  }

  searchProduct(String text) async {
    List<Product> hha = await PosDatabase.instance.searchProduct(text);
    categoryTabContent.clear();
    insertProduct(hha);
    insertProduct(hha);
    insertProduct(hha);

  }

  insertProduct(List<Product> data){
    categoryTabContent.add(
        GridView.count(
            shrinkWrap: true,
            crossAxisCount: 5,
            children: List.generate(data.length, (index) {
              return Card(
                child: Container(
                  decoration: (data[index].graphic_type == '2'
                      ? BoxDecoration(
                      image: DecorationImage(
                          image: FileImage(File(
                              'data/user/0/com.example.pos_system/files/assets/' +
                                  companyID +
                                  '/' +
                                  data[index].image!)),
                          fit: BoxFit.cover))
                      : BoxDecoration(color: HexColor(data[index].color!))),
                  child: InkWell(
                    splashColor: Colors.blue.withAlpha(30),
                    onTap: () {
                      openProductOrderDialog(data[index]);
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
                            data[index].SKU! + ' ' + data[index].name!,
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
            })));
  }
}
