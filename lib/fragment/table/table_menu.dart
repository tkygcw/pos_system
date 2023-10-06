import 'dart:async';
import 'dart:convert';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:pos_system/database/domain.dart';
import 'package:pos_system/fragment/table/table_change_dialog.dart';
import 'package:pos_system/fragment/table/table_detail_dialog.dart';
import 'package:pos_system/fragment/table/table_dialog.dart';
import 'package:pos_system/main.dart';
import 'package:pos_system/notifier/cart_notifier.dart';
import 'package:pos_system/object/categories.dart';
import 'package:pos_system/object/order_cache.dart';
import 'package:pos_system/object/table.dart';
import 'package:pos_system/object/table_use_detail.dart';
import 'package:pos_system/page/progress_bar.dart';
import 'package:pos_system/translation/AppLocalizations.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../database/pos_database.dart';
import '../../notifier/table_notifier.dart';
import '../../notifier/theme_color.dart';
import '../../object/branch_link_product.dart';
import '../../object/cart_product.dart';
import '../../object/modifier_group.dart';
import '../../object/modifier_item.dart';
import '../../object/modifier_link_product.dart';
import '../../object/order_detail.dart';
import '../../object/order_modifier_detail.dart';
import '../../object/print_receipt.dart';
import '../../object/printer.dart';
import '../../object/product.dart';
import '../../object/product_variant.dart';
import '../../object/product_variant_detail.dart';
import '../../object/variant_group.dart';
import '../../object/variant_item.dart';
import 'advanced_table/advanced_table_view.dart';

class TableMenu extends StatefulWidget {
  final CartModel cartModel;
  final Function() callBack;
  const TableMenu({Key? key, required this.callBack, required this.cartModel}) : super(key: key);

  @override
  _TableMenuState createState() => _TableMenuState();
}

class _TableMenuState extends State<TableMenu> {
  List<Printer> printerList = [];
  List<PosTable> tableList = [];
  List<OrderCache> orderCacheList = [];
  List<OrderDetail> orderDetailList = [];
  List<VariantGroup> variantGroup = [];
  List<ModifierGroup> modifierGroup = [];
  List<PosTable> sameGroupTbList = [];
  List<PosTable> initialTableList = [];

  double scrollContainerHeight = 130;
  double priceSST = 0.0;
  double priceServeTax = 0.0;
  bool isLoaded = false;
  bool showAdvanced = false;
  bool productDetailLoaded = false;
  bool editingMode = false, isButtonDisable = false;
  late SharedPreferences prefs;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    readAllTable();
    readAllPrinters();
    getPreData();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.cartModel.initialLoad();
    });
  }

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
  }

  fontColor({required PosTable posTable}){
    if(posTable.status == 1){
      Color fontColor = Colors.black;
      Color backgroundColor = toColor(posTable.card_color!);
      if(backgroundColor.computeLuminance() > 0.5){
        fontColor = Colors.black;
      } else {
        fontColor = Colors.white;
      }
      return fontColor;
    }
  }

  toColor(String hex) {
    var hexColor = hex.replaceAll("#", "");
    if (hexColor.length == 6) {
      hexColor = "FF" + hexColor;
    }
    if (hexColor.length == 8) {
      return Color(int.parse("0x$hexColor"));
    }
  }

  searchTable(String text) async {
    isLoaded = false;
    List<PosTable> data = await PosDatabase.instance.searchTable(text);
    tableList = data;
    await readAllTableGroup();
    if(mounted){
      setState(() {
        isLoaded = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeColor>(builder: (context, ThemeColor color, child) {
      return Consumer<CartModel>(builder: (context, CartModel cart, child) {
        return Consumer<TableModel>(builder: (context, TableModel tableModel, child) {
          if (tableModel.isChange) {
            readAllTable(model: tableModel);
          }
          if(notificationModel.contentLoad == true) {
            isLoaded = false;
          }
          if(notificationModel.contentLoad == true && notificationModel.contentLoaded == true){
            notificationModel.resetContentLoaded();
            notificationModel.resetContentLoad();
            Future.delayed(const Duration(seconds: 1), () {
              if(mounted){
                setState(() {
                  readAllTable(notification: true);
                });
              }
            });
          }
          return LayoutBuilder(builder: (context, constraints) {
            if (constraints.maxWidth > 800){
              return Scaffold(
                body: isLoaded
                    ? Container(
                  child: Column(
                    children: [
                      Padding(
                        padding: EdgeInsets.fromLTRB(11, 15, 11, 4),
                        child: Row(
                          children: [
                            Text(
                              showAdvanced && editingMode ? AppLocalizations.of(context)!.translate('edit') : AppLocalizations.of(context)!.translate('table'),
                              style: TextStyle(fontSize: 25),
                            ),
                            // Padding(
                            //   padding:
                            //       const EdgeInsets.fromLTRB(18, 0, 0, 0),
                            //   child: ElevatedButton.icon(
                            //       style: ElevatedButton.styleFrom(
                            //           backgroundColor: color.backgroundColor),
                            //       onPressed: () async  {
                            //         bool hasInternetAccess = await Domain().isHostReachable();
                            //         if(hasInternetAccess){
                            //           openAddTableDialog(PosTable());
                            //         } else {
                            //           Fluttertoast.showToast(msg: AppLocalizations.of(context)!.translate('internet_access_required'));
                            //         }
                            //       },
                            //       icon: Icon(Icons.add),
                            //       label: Text(AppLocalizations.of(context)!.translate('table'))),
                            // ),

                            Expanded(
                              flex: MediaQuery.of(context).size.height > 500 ? 23 : 3,
                              child: Row(
                                mainAxisAlignment: MediaQuery.of(context).size.height > 500 ? MainAxisAlignment.center: MainAxisAlignment.end,
                                children: [
                                  Text(
                                    AppLocalizations.of(context)!.translate('advanced'),
                                    style: TextStyle(fontSize: MediaQuery.of(context).size.height > 500 ? 18 : 12),
                                  ),
                                  Switch(
                                    value: showAdvanced,
                                    onChanged: (value) async {
                                      if(MediaQuery.of(context).size.height > 500) {
                                        if (isUpdated()) {
                                          scrollContainerHeight = 130;
                                          showSaveDialog(context);
                                        } else {
                                          editingMode = false;
                                          showAdvanced = !showAdvanced;
                                        }
                                        prefs.setBool('show_advanced', showAdvanced);
                                      } else {
                                        Fluttertoast.showToast(backgroundColor: Color(0xFFFF0000), msg: AppLocalizations.of(context)!.translate('feature_not_supported_on_phone'));
                                      }
                                    },
                                  ),
                                ],
                              ),
                            ),
                            // SizedBox(width: MediaQuery.of(context).size.height > 450 ? 450 : 50),
                            // Spacer(),
                            Expanded(
                              flex: MediaQuery.of(context).size.height > 500 ? 47 : 2,
                              child: Visibility(
                                visible: showAdvanced ? true : false,
                                child: Row(
                                  mainAxisAlignment: MediaQuery.of(context).size.height > 500 ? MainAxisAlignment.end : MainAxisAlignment.center,
                                  children: [
                                    Visibility(
                                      visible: editingMode ? true : false,
                                      child: IconButton(
                                        icon: const Icon(
                                          Icons.save,
                                        ),
                                        color: color.backgroundColor,
                                        onPressed: () {
                                          if (isUpdated()) {
                                            scrollContainerHeight = 130;
                                            showSaveDialog(context);
                                          } else {
                                            editingMode = !editingMode;
                                          }
                                        },
                                      ),
                                      replacement: IconButton(
                                        icon: const Icon(
                                          Icons.edit,
                                        ),
                                        color: color.backgroundColor,
                                        onPressed: () async {
                                          bool _hasInternetAccess = await Domain().isHostReachable();
                                          if (_hasInternetAccess) {
                                            editingMode = !editingMode;
                                            if (editingMode) {
                                              for (int j = 0; j < tableList.length; j++) {
                                                if (tableList[j].status == 1) {
                                                  tableList[j].isSelected = false;
                                                  cart.removeAllCartItem();
                                                  cart.removePromotion();
                                                  cart.removeSpecificTable(tableList[j]);
                                                }
                                              }
                                            }
                                            setState(() {});
                                          } else {
                                            Fluttertoast.showToast(msg: AppLocalizations.of(context)!.translate('no_internet_access'));
                                          }
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            SizedBox(width: MediaQuery.of(context).size.height > 500 ? 15 : 2),

                            Expanded(
                              flex: MediaQuery.of(context).size.height > 500 ? 30 : 3,
                              child: TextField(
                                onChanged: (value) {
                                  searchTable(value);
                                },
                                decoration: InputDecoration(
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
                        ),
                      ),
                      SizedBox(height: 20),
                      !showAdvanced
                          ? Expanded(
                        child: GridView.count(
                          shrinkWrap: true,
                          crossAxisCount: MediaQuery.of(context).size.height > 500 ? 5 : 3,
                          children: List.generate(
                            //this is the total number of cards
                              tableList.length, (index) {
                            // tableList[index].seats == 2;
                            return Card(
                              color: tableList[index].status != 0 && MediaQuery.of(context).size.height < 500 ? toColor(tableList[index].card_color!) : Colors.white,
                              shape: tableList[index].isSelected
                                  ? new RoundedRectangleBorder(side: new BorderSide(color: color.backgroundColor, width: 3.0), borderRadius: BorderRadius.circular(4.0))
                                  : new RoundedRectangleBorder(side: new BorderSide(color: Colors.white, width: 3.0), borderRadius: BorderRadius.circular(4.0)),
                              elevation: 5,
                              child: InkWell(
                                splashColor: Colors.blue.withAlpha(30),
                                onDoubleTap: () {
                                  if (tableList[index].status != 1) {
                                    //openAddTableDialog(tableList[index]);
                                  } else {
                                    openChangeTableDialog(tableList[index], cart);
                                  }
                                },
                                onTap: () async {
                                  onSelect(index, cart);
                                },
                                child: Container(
                                  margin: MediaQuery.of(context).size.height > 500 ? EdgeInsets.all(2) : EdgeInsets.all(0),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      // tableList[index].group != null && MediaQuery.of(context).size.height > 500
                                      //     ? Expanded(
                                      //         child: Text(
                                      //         "Group: ${tableList[index].group}",
                                      //         style:
                                      //             TextStyle(fontSize: 18),
                                      //       ))
                                      //     : MediaQuery.of(context).size.height > 500
                                      //         ? Expanded(child: Text(''))
                                      //         : Container(height: 10),
                                      Container(
                                        margin: MediaQuery.of(context).size.height > 500 ? EdgeInsets.fromLTRB(0, 5, 0, 5) : null,
                                        height: MediaQuery.of(context).size.height < 500
                                            ? 100
                                            : MediaQuery.of(context).size.height < 700
                                            ? MediaQuery.of(context).size.height / 6.5
                                            : MediaQuery.of(context).size.height / 5.5,
                                        child: Stack(
                                          children: [
                                            Visibility(
                                              visible: tableList[index].group != null && MediaQuery.of(context).size.height > 500 ? true : false,
                                              child: Container(
                                                  alignment: Alignment.topCenter,
                                                  child: Container(
                                                    padding: EdgeInsets.only(right: 5.0, left: 5.0),
                                                    decoration: BoxDecoration(
                                                        color: tableList[index].group != null && MediaQuery.of(context).size.height > 500
                                                            ? toColor(tableList[index].card_color!)
                                                            : Colors.white,
                                                        borderRadius: BorderRadius.circular(5.0)),
                                                    child: Text(
                                                      AppLocalizations.of(context)!.translate('group') + ": ${tableList[index].group}",
                                                      style: TextStyle(fontSize: 18, color: fontColor(posTable: tableList[index])),
                                                    ),
                                                  )),
                                            ),
                                            tableList[index].seats == '2'
                                                ? Container(alignment: Alignment.center, child: Image.asset("drawable/two-seat.jpg"))
                                                : tableList[index].seats == '4'
                                                ? Container(alignment: Alignment.center, child: Image.asset("drawable/four-seat.jpg"))
                                                : tableList[index].seats == '6'
                                                ? Container(alignment: Alignment.center, child: Image.asset("drawable/six-seat.jpg"))
                                                : Container(),
                                            // Ink.image(
                                            //   image: tableList[index].seats == '2'
                                            //       ? FileImage(File('data/user/0/com.example.pos_system/files/assets/img/two-seat.jpg'))
                                            //   // NetworkImage(
                                            //   //         "https://www.hometown.in/media/cms/icon/Two-Seater-Dining-Sets.png")
                                            //       : tableList[index].seats == '4'
                                            //           ? FileImage(File('data/user/0/com.example.pos_system/files/assets/img/four-seat.jpg'))
                                            //   // NetworkImage(
                                            //   //             "https://www.hometown.in/media/cms/icon/Four-Seater-Dining-Sets.png")
                                            //           : tableList[index].seats == '6'
                                            //               ? FileImage(File('data/user/0/com.example.pos_system/files/assets/img/six-seat.jpg'))
                                            //   // NetworkImage(
                                            //   //                 "https://www.hometown.in/media/cms/icon/Six-Seater-Dining-Sets.png")
                                            //               : FileImage(File('data/user/0/com.example.pos_system/files/assets/img/duitNow.jpg')),
                                            //   // NetworkImage(
                                            //   //                 "https://png.pngtree.com/png-vector/20190820/ourmid/pngtree-no-image-vector-illustration-isolated-png-image_1694547.jpg"),
                                            //   fit: BoxFit.cover,
                                            // ),
                                            Container(alignment: Alignment.center, child: Text(tableList[index].number!)),
                                            Visibility(
                                              visible: MediaQuery.of(context).size.height > 500 ? true : false,
                                              child: Container(
                                                  alignment: Alignment.bottomCenter,
                                                  child: Text("RM ${tableList[index].total_Amount.toStringAsFixed(2)}", style: TextStyle(fontSize: 18))),
                                            ),
                                          ],
                                        ),
                                      ),
                                      MediaQuery.of(context).size.height > 500 ? Container(height: 10) : Container(),
                                      // tableList[index].status == 1 ?
                                      // Expanded(
                                      //     child: Text(
                                      //       "RM ${tableList[index].total_Amount.toStringAsFixed(2)}",
                                      //       style: TextStyle(fontSize: 18)),
                                      // ) :
                                      //     Expanded
                                      //       (child: Text(''))
                                    ],
                                  ),
                                ),
                              ),
                            );
                          }),
                        ),
                      )
                          : AdvancedTableMap(cart, editingMode),
                      //         : LayoutBuilder(builder: (BuildContext context, BoxConstraints constraints){
                      //   print('Max Width: ' + constraints.maxWidth.toString() + ', Max Height: ' + constraints.maxHeight.toString());
                      //
                      //   return AdvancedTableMap(cart, editingMode);
                      // }
                    ],
                  ),
                )
                    : Container(child: CustomProgressBar()),

                // floatingActionButton: editingMode && showAdvanced
                //     ? Column(
                //   mainAxisAlignment: MainAxisAlignment.end,
                //   children: [
                //     SizedBox(height: 10),
                //     FloatingActionButton(
                //       onPressed: () {
                //         //openAddTableDialog(PosTable());
                //       },
                //       child: Icon(Icons.add),
                //     ),
                //   ],
                // )
                //     : null, // Set to null when editingMode is false
                // floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
              );
            } else {
              return Scaffold(
                  body: isLoaded ? Container(
                    child: Column(
                      children: [
                        Padding(
                          padding: EdgeInsets.fromLTRB(11, 15, 11, 4),
                          child: Row(
                            children: [
                              Text(
                                AppLocalizations.of(context)!.translate('table'),
                                style: TextStyle(fontSize: 25),
                              ),
                              SizedBox(width: 50),
                              Expanded(
                                child: TextField(
                                  onChanged: (value) {
                                    searchTable(value);
                                  },
                                  decoration: InputDecoration(
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
                          ),
                        ),
                        SizedBox(height: 20),
                        Expanded(
                          child: GridView.count(
                            shrinkWrap: true,
                            crossAxisCount: 3,
                            children: List.generate(
                              //this is the total number of cards
                                tableList.length, (index) {
                              // tableList[index].seats == 2;
                              return Card(
                                color: Colors.white,
                                shape: tableList[index].isSelected
                                    ? new RoundedRectangleBorder(
                                    side: new BorderSide(
                                        color: color.backgroundColor, width: 3.0),
                                    borderRadius:
                                    BorderRadius.circular(4.0))
                                    : new RoundedRectangleBorder(
                                    side: new BorderSide(
                                        color: Colors.white, width: 3.0),
                                    borderRadius:
                                    BorderRadius.circular(4.0)),
                                elevation: 5,
                                child: InkWell(
                                  splashColor: Colors.blue.withAlpha(30),
                                  onDoubleTap: () {
                                    if (tableList[index].status != 1) {
                                      //openAddTableDialog(tableList[index]);
                                    } else {
                                      openChangeTableDialog(tableList[index], cart);
                                    }
                                  },
                                  onTap: () async {
                                    await readSpecificTableDetail(tableList[index]);
                                    if (this.productDetailLoaded) {
                                      if (tableList[index].status == 1) {
                                        // table in use (colored)
                                        for (int i = 0; i < tableList.length; i++) {
                                          if (tableList[index].group == tableList[i].group) {
                                            if (tableList[i].isSelected == false) {
                                              tableList[i].isSelected = true;
                                            } else if (tableList[i].isSelected == true) {
                                              if (tableList[index].group == tableList[i].group) {
                                                setState(() {
                                                  //removeFromCart(cart, tableList[index]);
                                                  tableList[i].isSelected = false;
                                                  //print('table list: ${tableList[i].number}');
                                                  //cart.removeSpecificTable(tableList[i]);
                                                });
                                              } else {
                                                setState(() {
                                                  //removeFromCart(cart, tableList[index]);
                                                  tableList[i].isSelected = false;
                                                  //cart.removeSpecificTable(tableList[index]);
                                                });
                                              }
                                            }
                                          }
                                        }
                                      } else {
                                        for (int j = 0; j < tableList.length; j++) {
                                          //reset all using table to un-select (table status == 1)
                                          if (tableList[j].status == 1) {
                                            tableList[j].isSelected = false;
                                            cart.removeAllCartItem();
                                            cart.removePromotion();
                                            cart.removeSpecificTable(tableList[j]);
                                          }
                                        }
                                        Fluttertoast.showToast(backgroundColor: Color(0xFF07F107), msg: AppLocalizations.of(context)!.translate('table_not_in_use'));
                                      }
                                      if (tableList[index].status == 1 && tableList[index].isSelected == true) {
                                        //await readSpecificTableDetail(tableList[index]);
                                        addToCart(cart, tableList[index]);
                                      } else {
                                        removeFromCart(cart, tableList[index]);
                                      }
                                    }
                                  },
                                  child: Container(
                                    padding: EdgeInsets.all(5),
                                    child: Stack(
                                      children: [
                                        Visibility(
                                          visible: tableList[index].group != null ? true : false,
                                          child: Container(
                                              alignment: Alignment.topCenter,
                                              child: Container(
                                                padding: EdgeInsets.only(right: 5.0, left: 5.0),
                                                decoration: BoxDecoration(
                                                    color: tableList[index].group != null
                                                        ?
                                                    toColor(tableList[index].card_color!)
                                                        :
                                                    Colors.white,
                                                    borderRadius: BorderRadius.circular(5.0)
                                                ),
                                                child: Text(
                                                  AppLocalizations.of(context)!.translate('group')+": ${tableList[index].group}",
                                                  style:
                                                  TextStyle(fontSize: 14, color: fontColor(posTable: tableList[index])),
                                                ),
                                              )),
                                        ),
                                        tableList[index].seats == '2'
                                            ?
                                        Container(
                                            alignment: Alignment.center,
                                            child: Image.asset("drawable/two-seat.jpg")
                                        )
                                            :
                                        tableList[index].seats == '4'
                                            ?
                                        Container(
                                            alignment: Alignment.center,
                                            child: Image.asset("drawable/four-seat.jpg")
                                        )
                                            :
                                        tableList[index].seats == '6'
                                            ?
                                        Container(
                                            alignment: Alignment.center,
                                            child: Image.asset("drawable/six-seat.jpg")
                                        )
                                            :
                                        Container(),
                                        Container(
                                            alignment: Alignment.center,
                                            child: Text(tableList[index].number!)),

                                      ],
                                    ),
                                  ),
                                ),
                              );
                            }),
                          ),
                        )
                      ],
                    ),
                  )
                      : CustomProgressBar());
            }
          });
          // need to apply changes

          // end of apply changes
        });
      });
    });
  }

  onSelect(index, cart) async {
    await readSpecificTableDetail(tableList[index]);
    if (!editingMode) {
      if (this.productDetailLoaded) {
        if (tableList[index].status == 1) {
          // table in use (colored)
          for (int i = 0; i < tableList.length; i++) {
            if (tableList[index].group == tableList[i].group) {
              if (tableList[i].isSelected == false) {
                tableList[i].isSelected = true;
              } else if (tableList[i].isSelected == true) {
                if (tableList[index].group == tableList[i].group) {
                  setState(() {
                    //removeFromCart(cart, tableList[index]);
                    tableList[i].isSelected = false;
                    //print('table list: ${tableList[i].number}');
                    //cart.removeSpecificTable(tableList[i]);
                  });
                } else {
                  setState(() {
                    //removeFromCart(cart, tableList[index]);
                    tableList[i].isSelected = false;
                    //cart.removeSpecificTable(tableList[index]);
                  });
                }
              }
            }
          }
        } else {
          for (int j = 0; j < tableList.length; j++) {
            //reset all using table to un-select (table status == 1)
            if (tableList[j].status == 1) {
              tableList[j].isSelected = false;
              cart.removeAllCartItem();
              cart.removePromotion();
              cart.removeSpecificTable(tableList[j]);
            }
          }
          Fluttertoast.showToast(backgroundColor: Color(0xFF07F107), msg: AppLocalizations.of(context)!.translate('table_not_in_use'));
        }
        if (tableList[index].status == 1 && tableList[index].isSelected == true) {
          //await readSpecificTableDetail(tableList[index]);
          addToCart(cart, tableList[index]);
        } else {
          removeFromCart(cart, tableList[index]);
        }
      }
    } else {
      if (tableList[index].status != 1) {
        //openEditTableDialog(tableList[index]);
      } else
        Fluttertoast.showToast(backgroundColor: Color(0xFF07F107), msg: AppLocalizations.of(context)!.translate('table_is_used'));
    }
  }

  Future<Future<Object?>> openAddTableDialog(PosTable posTable) async {
    return showGeneralDialog(
        barrierColor: Colors.black.withOpacity(0.5),
        transitionBuilder: (context, a1, a2, widget) {
          final curvedValue = Curves.easeInOutBack.transform(a1.value) - 1.0;
          return Transform(
            transform: Matrix4.translationValues(0.0, curvedValue * 200, 0.0),
            child: Opacity(opacity: a1.value, child: TableDialog(allTableList: tableList, object: posTable, callBack: () => readAllTable())),
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

  Future<Future<Object?>> openEditTableDialog(PosTable posTable) async {
    return showGeneralDialog(
        barrierColor: Colors.black.withOpacity(0.5),
        transitionBuilder: (context, a1, a2, widget) {
          final curvedValue = Curves.easeInOutBack.transform(a1.value) - 1.0;
          return Transform(
            transform: Matrix4.translationValues(0.0, curvedValue * 200, 0.0),
            child: Opacity(opacity: a1.value, child: TableDialog(allTableList: tableList, object: posTable, callBack: () => readAllTable())),
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

  Future<Future<Object?>> openChangeTableDialog(PosTable posTable, CartModel cartModel) async {
    return showGeneralDialog(
        barrierColor: Colors.black.withOpacity(0.5),
        transitionBuilder: (context, a1, a2, widget) {
          final curvedValue = Curves.easeInOutBack.transform(a1.value) - 1.0;
          return Transform(
            transform: Matrix4.translationValues(0.0, curvedValue * 200, 0.0),
            child: Opacity(
                opacity: a1.value,
                child: TableChangeDialog(
                  object: posTable,
                  callBack: () {
                    readAllTable();
                    cartModel.initialLoad();
                  },
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

  // Future<Future<Object?>> openTableDetailDialog(PosTable posTable) async {
  //   return showGeneralDialog(
  //       barrierColor: Colors.black.withOpacity(0.5),
  //       transitionBuilder: (context, a1, a2, widget) {
  //         final curvedValue = Curves.easeInOutBack.transform(a1.value) - 1.0;
  //         return Transform(
  //           transform: Matrix4.translationValues(0.0, curvedValue * 200, 0.0),
  //           child: Opacity(
  //             opacity: a1.value,
  //             child: TableDetailDialog(
  //               object: posTable,
  //               callBack: () => readAllTable(),
  //             ),
  //           ),
  //         );
  //       },
  //       transitionDuration: Duration(milliseconds: 200),
  //       barrierDismissible: false,
  //       context: context,
  //       pageBuilder: (context, animation1, animation2) {
  //         // ignore: null_check_always_fails
  //         return null!;
  //       });
  // }

  readAllPrinters() async {
    printerList = await PrintReceipt().readAllPrinters();
  }

  readAllTable({model, notification}) async {
    if(notification == null){
      isLoaded = false;
    }
    if (model != null) {
      model.changeContent2(false);
    }

    tableList = await PosDatabase.instance.readAllTable();
    //for compare purpose
    initialTableList = await PosDatabase.instance.readAllTable();

    //table number sorting
    sortTable();

    await readAllTableGroup();
    if (mounted) {
      setState(() {
        isLoaded = true;
      });
    }
  }

  sortTable(){
    tableList.sort((a, b) {
      final aNumber = a.number!;
      final bNumber = b.number!;

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
  }

  bool isUpdated() {
    for (int i = 0; i < tableList.length; i++) {
      bool matched = false;
      for (int j = 0; j < initialTableList.length; j++) {
        //Find if there is any match data
        if (tableList[i].dx == initialTableList[j].dx) {
          if (tableList[i].dy == initialTableList[j].dy) {
            matched = true;
            break;
          }
        }
      }
      if (!matched) {
        //No match found, update needed
        return true;
      }
    }
    //all data are matched, no update needed
    return false;
  }

  readAllTableGroup() async {
    priceSST = 0.0;
    priceServeTax = 0.0;

    bool hasTableInUse = tableList.any((item) => item.status == 1);
    if(hasTableInUse){
      for (int i = 0; i < tableList.length; i++) {
        if(tableList[i].status == 1){
          List<TableUseDetail> tableUseDetailData = await PosDatabase.instance.readSpecificInUsedTableUseDetail(tableList[i].table_sqlite_id!);
          if (tableUseDetailData.isNotEmpty) {
            List<OrderCache> data = await PosDatabase.instance.readTableOrderCache(tableUseDetailData[0].table_use_key!);
            if(data.isNotEmpty){
              tableList[i].group = data[0].table_use_sqlite_id;
              tableList[i].card_color = data[0].card_color;
              //tableList[i].total_Amount = double.parse(data[0].total_amount!);

              for(int j = 0; j < data.length; j++){
                tableList[i].total_Amount += double.parse(data[j].total_amount!);
              }
            }
          }
        }
      }
    }
  }

  readSpecificTableDetail(PosTable posTable) async {
    orderDetailList.clear();
    orderCacheList.clear();

    //Get specific table use detail
    List<TableUseDetail> tableUseDetailData = await PosDatabase.instance.readSpecificInUsedTableUseDetail(posTable.table_sqlite_id!);
    if (tableUseDetailData.isNotEmpty) {
      //Get all order table cache
      List<OrderCache> data = await PosDatabase.instance.readTableOrderCache(tableUseDetailData[0].table_use_key!);

      //loop all table order cache
      for (int i = 0; i < data.length; i++) {
        if (!orderCacheList.contains(data)) {
          orderCacheList = List.from(data);
        }
        //Get all order detail based on order cache id
        //print('order cache key: ${data[i].order_cache_key!}');
        List<OrderDetail> detailData = await PosDatabase.instance.readTableOrderDetail(data[i].order_cache_key!);
        //print('order detail length 2 : ${detailData.length}');
        //add all order detail from db
        if (!orderDetailList.contains(detailData)) {
          orderDetailList..addAll(detailData);
        }
      }
    }

    //loop all order detail
    for (int k = 0; k < orderDetailList.length; k++) {
      //Get data from branch link product
      //List<BranchLinkProduct> result = await PosDatabase.instance.readSpecificBranchLinkProduct(orderDetailList[k].branch_link_product_sqlite_id!);

      //Get product category
      if(orderDetailList[k].category_sqlite_id! == '0'){
        orderDetailList[k].product_category_id = '0';
      } else {
        Categories category = await PosDatabase.instance.readSpecificCategoryByLocalId(orderDetailList[k].category_sqlite_id!);
        orderDetailList[k].product_category_id = category.category_id.toString();
      }
      // List<Product> productResult = await PosDatabase.instance.readSpecificProductCategory(result[0].product_id!);
      // orderDetailList[k].product_category_id = productResult[0].category_id;

      // if (result[0].has_variant == '1') {
      //   //Get product variant
      //   List<BranchLinkProduct> variant = await PosDatabase.instance.readBranchLinkProductVariant(orderDetailList[k].branch_link_product_sqlite_id!);
      //   orderDetailList[k].productVariant = ProductVariant(
      //       product_variant_id: int.parse(variant[0].product_variant_id!),
      //       variant_name: variant[0].variant_name);
      //
      //   //Get product variant detail
      //   List<ProductVariantDetail> productVariantDetail = await PosDatabase.instance.readProductVariantDetail(variant[0].product_variant_id!);
      //   orderDetailList[k].variantItem.clear();
      //   for (int v = 0; v < productVariantDetail.length; v++) {
      //     //Get product variant item
      //     List<VariantItem> variantItemDetail = await PosDatabase.instance.readProductVariantItemByVariantID(productVariantDetail[v].variant_item_id!);
      //     orderDetailList[k].variantItem.add(VariantItem(
      //         variant_item_id: int.parse(productVariantDetail[v].variant_item_id!),
      //         variant_group_id: variantItemDetail[0].variant_group_id,
      //         name: variant[0].variant_name,
      //         isSelected: true));
      //     productVariantDetail.clear();
      //   }
      // }

      //check product modifier
      await getOrderModifierDetail(orderDetailList[k]);
      // List<ModifierLinkProduct> productMod = await PosDatabase.instance.readProductModifier(result[0].product_sqlite_id!);
      // if (productMod.isNotEmpty) {
      //   orderDetailList[k].hasModifier = true;
      //   await getOrderModifierDetail(orderDetailList[k]);
      // }

      // if (orderDetailList[k].hasModifier == true) {
      //   //Get order modifier detail
      //   gerOrderModifierDetail(orderDetailList[k]);
      //   // List<OrderModifierDetail> modDetail = await PosDatabase.instance.readOrderModifierDetail(orderDetailList[k].order_detail_sqlite_id.toString());
      //   // if (modDetail.length > 0) {
      //   //   orderDetailList[k].modifierItem.clear();
      //   //   for (int m = 0; m < modDetail.length; m++) {
      //   //     // print('mod detail length: ${modDetail.length}');
      //   //     if (!orderDetailList[k].modifierItem.contains(modDetail[m].mod_group_id!)) {
      //   //       orderDetailList[k].modifierItem.add(ModifierItem(
      //   //           mod_group_id: modDetail[m].mod_group_id!,
      //   //           mod_item_id: int.parse(modDetail[m].mod_item_id!),
      //   //           name: modDetail[m].modifier_name!));
      //   //       orderDetailList[k].mod_group_id.add(modDetail[m].mod_group_id!);
      //   //       orderDetailList[k].mod_item_id = modDetail[m].mod_item_id;
      //   //     }
      //   //   }
      //   // }
      // }
    }
    if(mounted){
      setState(() {
        productDetailLoaded = true;
      });
    }
  }

  getOrderModifierDetail(OrderDetail orderDetail) async {
    List<OrderModifierDetail> modDetail = await PosDatabase.instance.readOrderModifierDetail(orderDetail.order_detail_sqlite_id.toString());
    if (modDetail.isNotEmpty) {
      orderDetail.orderModifierDetail = modDetail;
      // orderDetail.modifierItem.clear();
      // for (int m = 0; m < modDetail.length; m++) {
      //   // print('mod detail length: ${modDetail.length}');
      //   if (!orderDetail.modifierItem.contains(modDetail[m].mod_group_id!)) {
      //     orderDetail.modifierItem.add(ModifierItem(
      //         mod_group_id: modDetail[m].mod_group_id!,
      //         mod_item_id: int.parse(modDetail[m].mod_item_id!),
      //         name: modDetail[m].modifier_name!));
      //     orderDetail.mod_group_id.add(modDetail[m].mod_group_id!);
      //     orderDetail.mod_item_id = modDetail[m].mod_item_id;
      //   }
      // }
    } else {
      orderDetail.orderModifierDetail = [];
    }

  }

  getModifierGroupItem(OrderDetail orderDetail) {
    modifierGroup = [];
    List<ModifierItem> temp = List.from(orderDetail.modifierItem);

    for (int j = 0; j < orderDetail.mod_group_id.length; j++) {
      List<ModifierItem> modItemChild = [];
      //check modifier group is existed or not
      bool isModifierExisted = false;
      int position = 0;
      for (int g = 0; g < modifierGroup.length; g++) {
        if (modifierGroup[g].mod_group_id == orderDetail.mod_group_id[j]) {
          isModifierExisted = true;
          position = g;
          break;
        }
      }
      //if new category
      if (!isModifierExisted) {
        modifierGroup.add(ModifierGroup(
            modifierChild: [],
            mod_group_id: int.parse(orderDetail.mod_group_id[j])));
        position = modifierGroup.length - 1;
      }

      for (int k = 0; k < temp.length; k++) {
        if (modifierGroup[position].mod_group_id.toString() ==
            temp[k].mod_group_id) {
          modItemChild.add(ModifierItem(
              mod_group_id: orderDetail.mod_group_id[position],
              mod_item_id: temp[k].mod_item_id,
              name: temp[k].name,
              isChecked: true));
          temp.removeAt(k);
        }
      }
      modifierGroup[position].modifierChild = modItemChild;
    }
    return modifierGroup;
  }

  getVariantGroupItem(OrderDetail orderDetail) {
    variantGroup = [];
    //loop all order detail variant
    for (int i = 0; i < orderDetail.variantItem.length; i++) {
      variantGroup.add(VariantGroup(
          child: orderDetail.variantItem,
          variant_group_id:
          int.parse(orderDetail.variantItem[i].variant_group_id!)));
    }
    //print('variant group length: ${variantGroup.length}');
    return variantGroup;
  }

  addToCart(CartModel cart, PosTable posTable) async {
    var value;
    List<TableUseDetail> tableUseDetailList = [];
    var detailLength = orderDetailList.length;
    //print('tb order detail length: ${detailLength}');
    for (int i = 0; i < detailLength; i++) {
      value = cartProductItem(
        branch_link_product_sqlite_id: orderDetailList[i].branch_link_product_sqlite_id!,
        product_name: orderDetailList[i].productName!,
        category_id: orderDetailList[i].product_category_id!,
        price: orderDetailList[i].price!,
        quantity: int.parse(orderDetailList[i].quantity!),
        // checkedModifierItem: [],
        orderModifierDetail: orderDetailList[i].orderModifierDetail,
        //modifier: getModifierGroupItem(orderDetailList[i]),
        //variant: getVariantGroupItem(orderDetailList[i]),
        productVariantName: orderDetailList[i].product_variant_name,
        remark: orderDetailList[i].remark!,
        status: 0,
        order_cache_sqlite_id: orderDetailList[i].order_cache_sqlite_id,
        order_cache_key: orderDetailList[i].order_cache_key,
        category_sqlite_id: orderDetailList[i].category_sqlite_id,
        order_detail_sqlite_id: orderDetailList[i].order_detail_sqlite_id.toString(),
        base_price: orderDetailList[i].original_price,
        refColor: Colors.black,
      );
      cart.addItem(value);
    }
    var cacheLength = orderCacheList.length;
    for (int j = 0; j < cacheLength; j++) {
      //Get specific table use detail
      List<TableUseDetail> tableUseDetailData = await PosDatabase.instance
          .readAllTableUseDetail(orderCacheList[j].table_use_sqlite_id!);
      tableUseDetailList = List.from(tableUseDetailData);
    }
    var length = tableUseDetailList.length;
    for (int k = 0; k < length; k++) {
      List<PosTable> tableData = await PosDatabase.instance.readSpecificTable(tableUseDetailList[k].table_sqlite_id!);
      cart.addTable(tableData[0]);
    }
    //cart.addAllItem(cartItemList: itemList);
  }

  removeFromCart(CartModel cart, PosTable posTable) async {
    var value;
    List<TableUseDetail> tableUseDetailList = [];
    //await readSpecificTableDetail(posTable);
    if (this.productDetailLoaded) {
      var detailLength = orderDetailList.length;
      for (int i = 0; i < detailLength; i++) {
        value = cartProductItem(
          branch_link_product_sqlite_id: orderDetailList[i].branch_link_product_sqlite_id!,
          product_name: orderDetailList[i].productName!,
          category_id: orderDetailList[i].product_category_id!,
          price: orderDetailList[i].price!,
          quantity: int.parse(orderDetailList[i].quantity!),
          modifier: getModifierGroupItem(orderDetailList[i]),
          variant: getVariantGroupItem(orderDetailList[i]),
          remark: orderDetailList[i].remark!,
          status: 0,
          order_cache_sqlite_id: orderDetailList[i].order_cache_sqlite_id,
          category_sqlite_id: orderDetailList[i].category_sqlite_id,
          order_detail_sqlite_id: orderDetailList[i].order_detail_sqlite_id.toString(),
          refColor: toColor(posTable.card_color!),
        );
        cart.removeSpecificItem(value);
        cart.removePromotion();
      }
      var cacheLength = orderCacheList.length;
      for (int j = 0; j < cacheLength; j++) {
        //Get specific table use detail
        List<TableUseDetail> tableUseDetailData = await PosDatabase.instance.readAllTableUseDetail(orderCacheList[j].table_use_sqlite_id!);
        tableUseDetailList = tableUseDetailData;
      }
      var length = tableUseDetailList.length;
      for (int k = 0; k < length; k++) {
        List<PosTable> tableData = await PosDatabase.instance.readSpecificTable(tableUseDetailList[k].table_sqlite_id!);
        cart.removeSpecificTable(tableData[0]);
        //cart.addTable(tableData[0]);
      }
    }
  }

  Widget AdvancedTableMap(CartModel cart, bool editingMode) {
    return Expanded(
      child: SingleChildScrollView(
        child: Stack(
          children: [
            Container(
              height: getScrollContainerHeight(),
            ),
            for (int i = 0; i < tableList.length; i++)
              AdvancedTableView(
                cart: cart,
                position: i,
                table: tableList[i],
                tableList: tableList,
                tableLength: tableList.length,
                editingMode: editingMode,
                callBack: (action, value) {
                  if (action == 'on_tap')
                    onSelect(i, cart);
                  else if (action == 'on_double_tap')
                    openChangeTableDialog(tableList[i], cart);
                },
              )
          ],
        ),
      ),
    );
  }

  /*
  * Update table layout dialog
  * */
  showSaveDialog(mainContext) {
    // flutter defined function
    return showDialog(
      context: mainContext,
      builder: (BuildContext context) {
        // return alert dialog object
        return StatefulBuilder(builder: (context, StateSetter setState){
          return AlertDialog(
            title: Text("${AppLocalizations.of(context)?.translate('update_table_layout')}"),
            content: Text('${AppLocalizations.of(context)?.translate('confirm_update_table_layout')}'),
            actions: <Widget>[
              TextButton(
                child: Text('${AppLocalizations.of(context)?.translate('cancel')}'),
                onPressed: () {
                  readAllTable();
                  Navigator.of(context).pop();
                },
              ),
              TextButton(
                child: Text(
                  '${AppLocalizations.of(context)?.translate('confirm')}',
                  style: TextStyle(color: Colors.red),
                ),
                onPressed: isButtonDisable ? null : () async {
                  setState(() {
                    isButtonDisable = true;
                  });
                  await updateTableCoordinate(jsonEncode(tableList));
                  editingMode = !editingMode;
                  isButtonDisable = false;

                },
              ),
            ],
          );
        });
      },
    );
  }

  void getPreData() async {
    try {
      prefs = await SharedPreferences.getInstance();
      showAdvanced = prefs.getBool('show_advanced')!;
    } catch (e) {
      showAdvanced = false;
    }
  }

  // To get the scroll view height in table layout
  double getScrollContainerHeight() {
    try {
      if (editingMode){
        // return 1130;
        return MediaQuery.of(context).size.height*1.4+130;
      }
      else {
        if (scrollContainerHeight == 130) {
          double maxDy = tableList
              .where((posTable) => posTable.dy != null && posTable.dy!.isNotEmpty)
              .map((posTable) => double.tryParse(posTable.dy ?? '') ?? 0.0)
              .fold(0.0, (max, dyValue) => max > dyValue ? max : dyValue);
          scrollContainerHeight = maxDy + 130;
        }
      }
      return scrollContainerHeight;
    } catch (e) {
      print('Error: Failed to get table scroll height!');
      return scrollContainerHeight = 630;
    }
  }

  Future<int> updateTableCoordinate(table_list) async {
    int data = 0;
    try {
      bool _hasInternetAccess = await Domain().isHostReachable();
      if (_hasInternetAccess) {
        //update cloud
        Map response = await Domain().editTableCoordinate(table_list);
        if (response['status'] == '1') {
          //update local
          for (int i = 0; i < tableList.length; i++) {
            await PosDatabase.instance.updateTablePosition(tableList[i]);
          }
          Fluttertoast.showToast(msg: AppLocalizations.of(context)!.translate('successfully_update'));
          Navigator.of(context).pop();
          await readAllTable();
        }
      } else {
        Fluttertoast.showToast(msg: AppLocalizations.of(context)!.translate('no_internet_access'));
      }
    } catch (error) {
      print('Error: ' + error.toString());
      Fluttertoast.showToast(msg: AppLocalizations.of(context)!.translate('something_went_wrong_please_try_again_later'));
    }
    return data;
  }
}

class AddTableDialog extends StatelessWidget {
  final Function(int) onTableAdded;
  final _seatsController = TextEditingController();

  AddTableDialog({required this.onTableAdded});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Add Table'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            autofocus: true,
            controller: _seatsController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(labelText: 'Number of Seats'),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(context);
          },
          child: Text('Cancel'),
        ),
        TextButton(
          onPressed: () {
            int seats = int.tryParse(_seatsController.text) ?? 0;
            if (seats > 0) {
              onTableAdded(seats);
            }
            Navigator.pop(context);
          },
          child: Text('Add'),
        ),
      ],
    );
  }
}
