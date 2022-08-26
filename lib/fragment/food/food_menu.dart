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

class Variant {
  String? name;
  String? group;

  Variant({this.name, this.group});

  Map<String, Object?> toJson() => {
        'name': name,
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

class FoodMenu extends StatefulWidget {
  const FoodMenu({Key? key}) : super(key: key);

  @override
  _FoodMenuState createState() => _FoodMenuState();
}

class _FoodMenuState extends State<FoodMenu> with TickerProviderStateMixin {
  String _name = "Order";
  List<Tab> categoryTab = [];
  List<Widget> categoryTabContent = [];
  late TabController _tabController;
  late String companyID;
  List<Product> allProduct = [];
  List<Product> specificProduct = [];
  TextEditingController searchController = new TextEditingController();
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 0, vsync: this);
    readAllCategories();
    readAllProduct();
    readCompanyID();
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
                          "$_name",
                          style: TextStyle(
                              fontSize: 25, color: color.backgroundColor),
                        )),
                        SizedBox(width: 400),
                        Expanded(
                          child: TextField(
                            onChanged: (value) {
                              _tabController.index = 0;
                              searchProduct(value);
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
                          children: categoryTab.map((Tab tab) {
                            final String label = tab.text!;
                            if (label != 'All Category') {
                              readSpecificProduct(label);
                              return GridView.count(
                                shrinkWrap: true,
                                crossAxisCount: 5,
                                children: List.generate(
                                    specificProduct
                                        .length, //this is the total number of cards
                                    (index) {
                                  return Card(
                                    child: Container(
                                      decoration: (specificProduct[index]
                                                  .graphic_type ==
                                              '2'
                                          ? BoxDecoration(
                                              image: DecorationImage(
                                                  image: FileImage(File(
                                                      'data/user/0/com.example.pos_system/files/assets/' +
                                                          companyID +
                                                          '/' +
                                                          specificProduct[index]
                                                              .image!)),
                                                  fit: BoxFit.cover))
                                          : BoxDecoration(
                                              color: HexColor(
                                                  specificProduct[index]
                                                      .color!))),
                                      child: InkWell(
                                        splashColor: Colors.blue.withAlpha(30),
                                        onTap: () async {
                                          openProductOrderDialog(
                                              specificProduct[index]);
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
                                                specificProduct[index].SKU! +
                                                    ' ' +
                                                    specificProduct[index]
                                                        .name!,
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
                            } else {
                              if (allProduct.length == 0) {
                                return Padding(
                                  padding:
                                      const EdgeInsets.fromLTRB(0, 0, 0, 100),
                                  child: Center(
                                      child: Text(
                                    'No Product Found',
                                    style: TextStyle(
                                        fontSize: 18, color: Colors.grey),
                                  )),
                                );
                              } else {
                                return GridView.count(
                                  shrinkWrap: true,
                                  crossAxisCount: 5,
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
                                                            companyID +
                                                            '/' +
                                                            allProduct[index]
                                                                .image!)),
                                                    fit: BoxFit.cover))
                                            : BoxDecoration(
                                                color: HexColor(
                                                    allProduct[index].color!))),
                                        child: InkWell(
                                          splashColor:
                                              Colors.blue.withAlpha(30),
                                          onTap: () {
                                            openProductOrderDialog(
                                                allProduct[index]);
                                          },
                                          child: Stack(
                                            alignment: Alignment.bottomLeft,
                                            children: [
                                              Container(
                                                color: Colors.black
                                                    .withOpacity(0.5),
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
                                );
                              }
                            }
                          }).toList()),
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

  readAllCategories() async {
    List<Categories> data = await PosDatabase.instance.readAllCategories();
    setState(() {
      categoryTab.add(Tab(
        text: 'All Category',
      ));
      for (int i = 0; i < data.length; i++) {
        categoryTab.add(Tab(
          text: data[i].name!,
        ));
      }
      _tabController = TabController(length: categoryTab.length, vsync: this);
    });
  }

  readCompanyID() async {
    final prefs = await SharedPreferences.getInstance();
    final String? user = prefs.getString('user');
    Map userObject = json.decode(user!);
    if(mounted) {
      setState(() {
        companyID = userObject['company_id'];
      });
    }
  }

  readAllProduct() async {
    List<Product> data = await PosDatabase.instance.readAllProduct();
    if(mounted) {
      setState(() {
        allProduct = data;
        this.isLoading = false;
      });
    }
  }

  readSpecificProduct(String label) async {
    List<Product> data = await PosDatabase.instance.readSpecificProduct(label);
    if(mounted) {
      setState(() {
        specificProduct = data;
      });
    }
  }

  searchProduct(String text) async {
    List<Product> data = await PosDatabase.instance.searchProduct(text);
    if(mounted) {
      setState(() {
        allProduct = data;
      });
    }
  }
}
