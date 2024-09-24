import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:collapsible_sidebar/collapsible_sidebar.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pos_system/fragment/product/product_order_dialog.dart';
import 'package:pos_system/notifier/cart_notifier.dart';
import 'package:pos_system/notifier/notification_notifier.dart';
import 'package:pos_system/object/categories.dart';
import 'package:pos_system/object/product.dart';
import 'package:pos_system/page/progress_bar.dart';
import 'package:pos_system/translation/AppLocalizations.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../database/pos_database.dart';
import '../../main.dart';
import '../../notifier/app_setting_notifier.dart';
import '../../notifier/theme_color.dart';
import '../../object/colorCode.dart';
import '../../object/search_delegate.dart';
import 'dart:io' as Platform;

class FoodMenu extends StatefulWidget {
  final CartModel cartModel;

  const FoodMenu({Key? key, required this.cartModel}) : super(key: key);

  @override
  _FoodMenuState createState() => _FoodMenuState();
}

class _FoodMenuState extends State<FoodMenu> with TickerProviderStateMixin {
  StreamController controller = StreamController();
  late Stream contentStream;
  List<Tab> categoryTab = [];
  List<Widget> categoryTabContent = [];
  List<String> categoryList = [];
  TabController? _tabController;
  late String companyID;
  late AppSettingModel _appSettingModel;
  List<Product> allProduct = [];
  List<Product> specificProduct = [];
  TextEditingController searchController = new TextEditingController();
  bool isLoading = true;
  int loadCount = 0;
  String imagePath = '';

  @override
  void initState() {
    super.initState();
    if(mounted){
      contentStream = controller.stream.asBroadcastStream();
      readAllCategories();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        widget.cartModel.initialLoad();
      });
    }
  }

  @override
  void dispose() {
    // TODO: implement dispose
    if(_tabController != null){
      _tabController!.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeColor>(builder: (context, ThemeColor color, child) {
      return Consumer<AppSettingModel>(builder: (context, AppSettingModel appSettingModel, child) {
        return Consumer<NotificationModel>(builder: (context, NotificationModel notificationModel, child) {
          _appSettingModel = appSettingModel;
          if(notificationModel.contentLoad == true){
            categoryTab.clear();
            categoryList.clear();
            categoryTabContent.clear();
          }
          if(notificationModel.contentLoaded == true){
            notificationModel.resetContentLoaded();
            notificationModel.resetContentLoad();
            Future.delayed(const Duration(seconds: 2), () {
              readAllCategories();
            });
          }
          return Scaffold(
            appBar: AppBar(
              automaticallyImplyLeading: false,
              elevation: 0,
              leading: MediaQuery.of(context).orientation == Orientation.landscape ? null : Padding(
                padding: const EdgeInsets.all(8.0),
                child: GestureDetector(
                  onTap: () {
                    isCollapsedNotifier.value = !isCollapsedNotifier.value;
                  },
                  child: Image.asset('drawable/logo.png'),
                ),
              ),
              title: Text(AppLocalizations.of(context)!.translate('menu'),
                style: MediaQuery.of(context).size.width > 900 && MediaQuery.of(context).size.height > 500
                    ? TextStyle(fontSize: 25, color: Colors.black)
                    : TextStyle(fontSize: 20, color: color.backgroundColor),
              ),
              centerTitle: false,
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
            body: StreamBuilder(
              stream: contentStream,
              builder: (context, snapshot) {
                if(snapshot.hasData && categoryTab.isNotEmpty){
                  return Column(
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
                      ]);
                } else {
                  return CustomProgressBar();
                }
              }
            ),
          );
        });
      });
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
    controller.sink.add("refresh");
  }

  readAllCategories() async {
    List<Categories> _data = [];
    await getPreferences();
    if(categoryTab.isEmpty){
      _data = await PosDatabase.instance.readAllCategories();
      _data = sortCategory(_data);
      categoryTab.add(Tab(
        text: AppLocalizations.of(MyApp.navigatorKey.currentContext!)!.translate('all_category'),
      ));
      categoryList.add(AppLocalizations.of(MyApp.navigatorKey.currentContext!)!.translate('all_category'));
      for (int i = 0; i < _data.length; i++) {
        categoryTab.add(Tab(
          text: _data[i].name!,
        ));
        categoryList.add(_data[i].name!);
      }
      for (int i = 0; i < categoryList.length; i++) {
        if (categoryList[i] == AppLocalizations.of(MyApp.navigatorKey.currentContext!)!.translate('all_category')) {
          List<Product> data = await PosDatabase.instance.readAllProduct();
          data = sortProduct(data);
          allProduct = data;
          categoryTabContent.add(GridView.count(
              shrinkWrap: true,
              //MediaQueryData.fromWindow(WidgetsBinding.instance.window).size.height
              crossAxisCount: MediaQuery.of(context).size.height > 500 && MediaQuery.of(context).size.width > 900 ? 5
                  : MediaQuery.of(MyApp.navigatorKey.currentContext!).size.height > 500 && MediaQuery.of(MyApp.navigatorKey.currentContext!).size.width > 500 ? 4
                    : 3,
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
                            child: _appSettingModel.show_sku! ?
                            Text(
                              data[index].SKU! + ' ' + data[index].name!,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                fontSize: 13,
                              ),
                            ) :
                            Text(
                              data[index].name!,
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
          data = sortProduct(data);
          categoryTabContent.add(GridView.count(
              shrinkWrap: true,
              padding: const EdgeInsets.all(10),
              crossAxisCount: MediaQuery.of(context).size.height > 500 && MediaQuery.of(context).size.width > 900 ? 5
                : MediaQuery.of(MyApp.navigatorKey.currentContext!).size.height > 500 && MediaQuery.of(MyApp.navigatorKey.currentContext!).size.width > 500 ? 4
                  : 3,
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
                            child:  _appSettingModel.show_sku! ? Text(
                              data[index].SKU! + ' ' + data[index].name!,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                fontSize: 13,
                              ),
                            ) :
                            Text(
                              data[index].name!,
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
      if(!mounted) return;
      _tabController = TabController(length: categoryTab.length, vsync: this);
      refresh();
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

  Future<String> get _localPath async {
    final directory = await getApplicationSupportDirectory();
    return directory.path;
  }

  searchProduct(String text) async {
    List<Product> hha = await PosDatabase.instance.searchProduct(text);
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
                        data[index].name!,
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
