import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:pos_system/fragment/product/product_order_dialog.dart';
import 'package:pos_system/notifier/cart_notifier.dart';
import 'package:pos_system/object/categories.dart';
import 'package:pos_system/object/product.dart';
import 'package:pos_system/page/progress_bar.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../database/pos_database.dart';
import '../../main.dart';
import '../../notifier/theme_color.dart';
import '../../object/colorCode.dart';
import '../../object/search_delegate.dart';

class FoodMenu extends StatefulWidget {
  final CartModel cartModel;

  const FoodMenu({Key? key, required this.cartModel}) : super(key: key);

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
  int loadCount = 0;
  String imagePath = '';

  @override
  void initState() {
    super.initState();
    readAllCategories();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.cartModel.initialLoad();
    });
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
      if(notificationModel.contentLoad == true) {
        isLoading = true;
        //print('notification refresh called!');
      }
      if(notificationModel.contentLoad == true && notificationModel.contentLoaded == true){
        notificationModel.resetContentLoaded();
        notificationModel.resetContentLoad();
        Future.delayed(const Duration(seconds: 1), () {
          if(mounted){
            setState(() {
              readAllCategories(hasNotification: true);
            });
          }
        });
      }
      return isLoading
          ? CustomProgressBar()
          : Scaffold(
              appBar: AppBar(
                automaticallyImplyLeading: false,
                elevation: 0,
                title: Text(
                  "Menu",
                  style: TextStyle(fontSize: 25, color: color.backgroundColor),
                ),
                actions: [
                  IconButton(
                      color: color.buttonColor,
                      onPressed: (){
                        showSearch(context: context, delegate: ProductSearchDelegate(productList: allProduct, imagePath: imagePath, cartModel: widget.cartModel));
                      },
                      icon: Icon(Icons.search),
                  )
                ],
              ),
              resizeToAvoidBottomInset: false,
              body: Container(
                child: Column(
                    children: [
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
                          child: TabBarView(controller: _tabController, children: categoryTabContent),
                        ),
                      ),
                ]),
              ),
            );
    });
  }

  Future<Future<Object?>> openProductOrderDialog(Product product, CartModel cartModel) async {
    return showGeneralDialog(
        barrierColor: Colors.black.withOpacity(0.5),
        transitionBuilder: (context, a1, a2, widget) {
          final curvedValue = Curves.easeInOutBack.transform(a1.value) - 1.0;
          return Transform(
            transform: Matrix4.translationValues(0.0, curvedValue * 200, 0.0),
            child: Opacity(
                opacity: a1.value,
                child: ProductOrderDialog(
                  cartModel:  cartModel,
                  productDetail: product,
                )),
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

  void refresh() {
    isLoading = false;
    setState(() {});
  }

  readAllCategories({hasNotification}) async {
    if(hasNotification == true){
      categoryTab.clear();
      categoryList.clear();
      categoryTabContent.clear();
    }
    await getPreferences();
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
        allProduct = data;
        categoryTabContent.add(GridView.count(
            shrinkWrap: true,
            crossAxisCount: MediaQueryData.fromWindow(WidgetsBinding.instance.window).size.height > 500 ? 5 : 3,
            children: List.generate(data.length, (index) {
              return Card(
                child: Container(
                  decoration: (data[index].graphic_type == '2'
                      ? BoxDecoration(image: DecorationImage(image: FileImage(File(imagePath + '/' + data[index].image!)), fit: BoxFit.cover))
                      : BoxDecoration(color: HexColor(data[index].color!))),
                  child: InkWell(
                    splashColor: Colors.blue.withAlpha(30),
                    onTap: () {
                      openProductOrderDialog(data[index], widget.cartModel);
                    },
                    child: Stack(
                      alignment: Alignment.bottomLeft,
                      children: [
                        Container(
                          height: 50,
                          padding: EdgeInsets.fromLTRB(5, 2, 5, 2),
                          color: Colors.black.withOpacity(0.5),
                          width: 200,
                          alignment: Alignment.center,
                          child: Text(
                            data[index].SKU! + ' ' + data[index].name!,
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
            })));
      } else {
        List<Product> data = await PosDatabase.instance.readSpecificProduct(categoryList[i]);
        categoryTabContent.add(GridView.count(
            shrinkWrap: true,
            padding: const EdgeInsets.all(10),
            crossAxisCount: MediaQueryData.fromWindow(WidgetsBinding.instance.window).size.height > 500 ? 5 : 3,
            children: List.generate(data.length, (index) {
              return Card(
                child: Container(
                  decoration: (data[index].graphic_type == '2'
                      ? BoxDecoration(image: DecorationImage(image: FileImage(File(imagePath + '/' + data[index].image!)), fit: BoxFit.cover))
                      : BoxDecoration(color: HexColor(data[index].color!))),
                  child: InkWell(
                    splashColor: Colors.blue.withAlpha(30),
                    onTap: () {
                      openProductOrderDialog(data[index], widget.cartModel);
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
                            data[index].SKU! + ' ' + data[index].name!,
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
            })));
      }
    }
    refresh();
    _tabController = TabController(length: categoryTab.length, vsync: this);
  }

  getPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    final String? user = prefs.getString('user');
    imagePath = prefs.getString('local_path')!;

    Map userObject = json.decode(user!);
    companyID = userObject['company_id'];
  }

  searchProduct(String text) async {
    print('search product called');
    List<Product> hha = await PosDatabase.instance.searchProduct(text);
    print('product length: ${hha.length}');
    setState(() {
      categoryTabContent.clear();
      insertProduct(hha);
      insertProduct(hha);
      insertProduct(hha);
    });
  }

  insertProduct(List<Product> data) {
    categoryTabContent.add(GridView.count(
        shrinkWrap: true,
        crossAxisCount: 5,
        children: List.generate(data.length, (index) {
          return Card(
            child: Container(
              decoration: (data[index].graphic_type == '2'
                  ? BoxDecoration(
                      image: DecorationImage(
                          image: FileImage(File(imagePath + '/' + data[index].image!)),
                          fit: BoxFit.cover))
                  : BoxDecoration(color: HexColor(data[index].color!))),
              child: InkWell(
                splashColor: Colors.blue.withAlpha(30),
                onTap: () {
                  openProductOrderDialog(data[index], widget.cartModel);
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
                        data[index].SKU! + ' ' + data[index].name!,
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
        })));
  }
}
