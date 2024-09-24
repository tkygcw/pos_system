import 'dart:async';
import 'dart:convert';

import 'package:collapsible_sidebar/collapsible_sidebar.dart';
import 'package:collection/collection.dart';
import 'package:f_logs/model/flog/flog.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:pos_system/database/domain.dart';
import 'package:pos_system/fragment/table/table_change_dialog.dart';
import 'package:pos_system/fragment/table/table_dialog.dart';
import 'package:pos_system/main.dart';
import 'package:pos_system/notifier/cart_notifier.dart';
import 'package:pos_system/object/categories.dart';
import 'package:pos_system/object/order.dart';
import 'package:pos_system/object/order_cache.dart';
import 'package:pos_system/object/order_payment_split.dart';
import 'package:pos_system/object/table.dart';
import 'package:pos_system/object/table_use_detail.dart';
import 'package:pos_system/page/progress_bar.dart';
import 'package:pos_system/translation/AppLocalizations.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../database/pos_database.dart';
import '../../notifier/notification_notifier.dart';
import '../../notifier/table_notifier.dart';
import '../../notifier/theme_color.dart';
import '../../object/branch_link_product.dart';
import '../../object/cart_product.dart';
import '../../object/modifier_group.dart';
import '../../object/modifier_item.dart';
import '../../object/order_detail.dart';
import '../../object/order_modifier_detail.dart';
import '../printing_layout/print_receipt.dart';
import '../../object/printer.dart';
import '../../object/variant_group.dart';
import '../../page/loading_dialog.dart';
import '../choose_qr_type_dialog.dart';
import 'advanced_table/advanced_table_view.dart';

class TableMenu extends StatefulWidget {
  final CartModel cartModel;
  final Function() callBack;
  const TableMenu({Key? key, required this.callBack, required this.cartModel}) : super(key: key);

  @override
  _TableMenuState createState() => _TableMenuState();
}

class _TableMenuState extends State<TableMenu> {
  Timer? timer;

  List<Printer> printerList = [];
  List<PosTable> tableList = [], selectedTable = [];
  List<OrderCache> orderCacheList = [];
  List<OrderDetail> orderDetailList = [];
  List<VariantGroup> variantGroup = [];
  List<ModifierGroup> modifierGroup = [];
  List<PosTable> sameGroupTbList = [];
  List<PosTable> initialTableList = [];

  double scrollContainerHeight = 130;
  double priceSST = 0.0;
  double priceServeTax = 0.0;
  int tapCount = 0, loadCount = 0;
  bool isLoaded = false;
  bool showAdvanced = false;
  bool productDetailLoaded = false;
  bool editingMode = false, isButtonDisable = false, onTapDisable = false;
  String qrOrderStatus = '0';
  String orderKey = '';
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
    if(timer != null){
      timer!.cancel();
    }
    tapCount = 0;
    onTapDisable = false;
    selectedTable.clear();
    super.dispose();
  }

  fontColor({required PosTable posTable}){
    try{
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
    }catch(e){
      return Colors.black;
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
    var screenSize = MediaQuery.of(context).size;
    return Consumer<ThemeColor>(builder: (context, ThemeColor color, child) {
      return Consumer<CartModel>(builder: (context, CartModel cart, child) {
        return Consumer<TableModel>(builder: (context, TableModel tableModel, child) {
          return Consumer<NotificationModel>(builder: (context, NotificationModel notificationModel, child) {
            if(notificationModel.contentLoaded == true){
              notificationModel.resetContentLoaded();
              notificationModel.resetContentLoad();
              Future.delayed(const Duration(seconds: 1), () {
                readAllTable(notification: true);
              });
            } else {
              if (tableModel.isChange && cart.cartNotifierItem.isEmpty) {
                readAllTable(model: tableModel);
              }
            }
            if (screenSize.width > 900 && screenSize.height > 500){
              return Scaffold(
                body: isLoaded ?
                Column(
                  children: [
                    Padding(
                      padding: EdgeInsets.fromLTRB(11, 4, 11, 4),
                      child: TableMenuAppBar(context, color, cart),
                    ),
                    SizedBox(height: 20),
                    !showAdvanced ?
                    NormalTableMap(context, color, cart) :
                    AdvancedTableMap(cart, editingMode),
                  ],
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
              //mobile
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
                    title: Text(AppLocalizations.of(context)!.translate('table'),
                      style: TextStyle(fontSize: 20, color: color.backgroundColor),
                    ),
                    centerTitle: false,
                  ),
                  body: isLoaded ? Container(
                    child: Column(
                      children: [
                        // SizedBox(height: 20),
                        Expanded(
                          child: GridView.count(
                            shrinkWrap: true,
                            crossAxisCount: MediaQuery.of(context).orientation == Orientation.landscape ?
                              screenSize.width > 900 && screenSize.height > 500 ? 5
                                : 3
                                : screenSize.height > 500 && screenSize.width > 500 ? 4
                                : 3,
                            children: List.generate(
                              //this is the total number of cards
                                tableList.length, (index) {
                              // tableList[index].seats == 2;
                              return Card(
                                color: tableList[index].status == 1 && tableList[index].order_key != null ? Color(0xFFFFB3B3) : Colors.white,
                                shape: tableList[index].isSelected
                                    ? new RoundedRectangleBorder(
                                    side: new BorderSide(
                                        color: tableList[index].order_key != null ? Colors.red : color.backgroundColor, width: 3.0),
                                    borderRadius:
                                    BorderRadius.circular(4.0))
                                    : new RoundedRectangleBorder(
                                    side: new BorderSide(
                                        color: tableList[index].status == 1 && tableList[index].order_key != null ? Color(0xFFFFB3B3) : Colors.white, width: 3.0),
                                    borderRadius:
                                    BorderRadius.circular(4.0)),
                                elevation: 5,
                                child: InkWell(
                                  splashColor: Colors.blue.withAlpha(30),
                                  onLongPress: qrOrderStatus == '1' ? null : () {
                                    selectedTable = [tableList[index]];
                                    openChooseQRDialog(selectedTable);
                                    },
                                  onDoubleTap: () {
                                    if (tableList[index].status != 1) {
                                      //openAddTableDialog(tableList[index]);
                                    } else {
                                      if(tableList[index].order_key == null) {
                                        openChangeTableDialog(tableList[index], cart);
                                      } else {
                                        Fluttertoast.showToast(backgroundColor: Color(0xFFFF0000), msg: AppLocalizations.of(context)!.translate('payment_not_complete'));
                                      }
                                    }
                                  },
                                  onTap: onTapDisable ? null : () {
                                    setState(() {
                                      tapCount++;
                                      onTapDisable = true;
                                    });
                                    if(tapCount == 1){
                                      asyncQ.addJob((_) async {
                                        try{
                                          await onSelect(index, cart);
                                        }catch(e) {
                                          setState(() {
                                            tapCount = 0;
                                            onTapDisable = false;
                                          });
                                          FLog.error(
                                            className: "table menu",
                                            text: "on select queue error",
                                            exception: e,
                                          );
                                        }
                                      });
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
                                        Visibility(
                                          visible: MediaQuery.of(context).orientation == Orientation.landscape ? false : true,
                                          child: Container(
                                              alignment: Alignment.bottomCenter,
                                              child: Text("RM ${tableList[index].total_amount ?? '0.00'}")),
                                        ),
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
        });
      });
    });
  }

  Widget NormalTableMap(BuildContext context, ThemeColor color, CartModel cart) {
    return Expanded(
      child: GridView.count(
        shrinkWrap: true,
        crossAxisCount: MediaQuery.of(context).orientation == Orientation.landscape ?
          MediaQuery.of(context).size.width > 900 && MediaQuery.of(context).size.height > 500 ? 5
            : 3
            : MediaQuery.of(context).size.height > 500 && MediaQuery.of(context).size.width > 500 ? 4
            : 3,
        children: List.generate(
          //this is the total number of cards
            tableList.length, (index) {
          // tableList[index].seats == 2;
          return Card(
            color: tableList[index].status != 0 && MediaQuery.of(context).size.height < 500 ? toColor(tableList[index].card_color!) :
              tableList[index].status == 1 && tableList[index].order_key != null ? Color(0xFFFFB3B3) : Colors.white,
            shape: tableList[index].isSelected
                ? new RoundedRectangleBorder(side: new BorderSide(color: tableList[index].order_key != null ? Colors.red : color.backgroundColor, width: 3.0), borderRadius: BorderRadius.circular(4.0))
                : new RoundedRectangleBorder(side: new BorderSide(
                  color: tableList[index].status == 1 && tableList[index].order_key != null ? Color(0xFFFFB3B3) : Colors.white, width: 3.0
                ), borderRadius: BorderRadius.circular(4.0)),
            elevation: 5,
            child: InkWell(
              splashColor: Colors.blue.withAlpha(30),
              onLongPress: qrOrderStatus == '1' ? null : () {
                selectedTable = [tableList[index]];
                openChooseQRDialog(selectedTable);
              },
              onDoubleTap: () {
                if (tableList[index].status != 1) {
                  //openAddTableDialog(tableList[index]);
                } else {
                  if(tableList[index].order_key == null) {
                    openChangeTableDialog(tableList[index], cart);
                  } else {
                    Fluttertoast.showToast(backgroundColor: Color(0xFFFF0000), msg: AppLocalizations.of(context)!.translate('payment_not_complete'));
                  }
                }
              },
              onTap: onTapDisable ? null : () {
                setState(() {
                  tapCount++;
                  onTapDisable = true;
                });
                if(tapCount == 1){
                  asyncQ.addJob((_) async {
                    try{
                      await onSelect(index, cart);
                    }catch(e) {
                      setState(() {
                        tapCount = 0;
                        onTapDisable = false;
                      });
                      FLog.error(
                        className: "table menu",
                        text: "on select queue error",
                        exception: e,
                      );
                    }
                  });
                }
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
                          : calculateHeight(context),
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
                            visible: MediaQuery.of(context).size.height > 500 && MediaQuery.of(context).size.width > 900 ? true : false,
                            child: Container(
                                alignment: Alignment.bottomCenter,
                                child: Text("RM ${tableList[index].total_amount ?? '0.00'}", style: TextStyle(fontSize: 18))),
                          ),
                        ],
                      ),
                    ),
                    MediaQuery.of(context).size.height > 500 && MediaQuery.of(context).size.width > 900 ? Container(height: 10) : Container(),
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
    );
  }

  Widget TableMenuAppBar(BuildContext context, ThemeColor color, CartModel cart) {
    return Row(
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
                      setState(() {
                        showAdvanced = !showAdvanced;
                      });

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
    );
  }

  onSelect(index, CartModel cart) async {
    try{
      openLoadingDialogBox();
      timer = Timer(Duration(milliseconds: 500), () async {
        try{
          await readSpecificTableDetail(tableList[index]);
          if (!editingMode) {
            if (productDetailLoaded) {
              if (tableList[index].status == 1) {
                // table in use (colored)
                for (int i = 0; i < tableList.length; i++) {
                  if (tableList[index].group == tableList[i].group || ((tableList[index].order_key == tableList[i].order_key) && tableList[index].order_key != null)) {
                    if (tableList[i].isSelected == false) {
                      if(tableList[i].order_key == null) {
                        for (int j = 0; j < tableList.length; j++) {
                          //reset all using table to un-select (table status == 1)
                          if (tableList[j].isSelected == true && tableList[j].order_key != null) {
                            tableList[j].isSelected = false;
                            cart.removeSpecificGroupList(tableList[j].group!);
                            cart.removeAllCartItem();
                            cart.removePromotion();
                            cart.removeSpecificTable(tableList[j]);
                          }
                        }
                        tableList[i].isSelected = true;
                      } else {
                        for (int j = 0; j < tableList.length; j++) {
                          //reset all using table to un-select (table status == 1)
                          if (tableList[j].isSelected == true && tableList[j].group != tableList[index].group && tableList[index].order_key != tableList[j].order_key) {
                            tableList[j].isSelected = false;
                            cart.removeSpecificGroupList(tableList[j].group!);
                            cart.removeAllCartItem();
                            cart.removePromotion();
                            cart.removeSpecificTable(tableList[j]);
                          }
                        }
                        tableList[i].isSelected = true;
                      }
                    } else if (tableList[i].isSelected == true) {
                      if (tableList[index].group == tableList[i].group) {
                        setState(() {
                          //removeFromCart(cart, tableList[index]);
                          tableList[i].isSelected = false;
                          cart.removeSpecificGroupList(tableList[i].group!);
                          //print('table list: ${tableList[i].number}');
                          //cart.removeSpecificTable(tableList[i]);
                        });
                      } else {
                        setState(() {
                          //removeFromCart(cart, tableList[index]);
                          tableList[i].isSelected = false;
                          cart.removeSpecificGroupList(tableList[i].group!);
                          //cart.removeSpecificTable(tableList[index]);
                        });
                      }
                    }
                    if (tableList[i].status == 1 && tableList[i].isSelected == true) {
                      // if(!groupList.contains(tableList[i].group)) {
                      if(!cart.groupList.contains(tableList[i].group)) {
                        await readSpecificTableDetail(tableList[i]);
                        //await readSpecificTableDetail(tableList[index]);
                        List<TableUseDetail> tableUseDetailData = await PosDatabase.instance.readSpecificInUsedTableUseDetail(tableList[i].table_sqlite_id!);
                        if (tableUseDetailData.isNotEmpty){
                          List<OrderCache> data = await PosDatabase.instance.readTableOrderCache(tableUseDetailData[0].table_use_key!);
                          if(data.isNotEmpty){
                            if(data[0].order_key != ''){
                              orderKey = data[0].order_key!;
                            } else {
                              orderKey = '';
                            }
                          }
                        }
                        addToCart(cart, tableList[i]);
                        cart.addToGroupList(tableList[i].group!);
                        // groupList.add(tableList[i].group!);
                      }
                    } else {
                      await readSpecificTableDetail(tableList[i]);
                      removeFromCart(cart, tableList[i]);
                      cart.removeSpecificGroupList(tableList[i].group!);
                      cart.removeCartOrderCache(orderCacheList);
                    }
                  }
                }
              } else {
                for (int j = 0; j < tableList.length; j++) {
                  //reset all using table to un-select (table status == 1)
                  if (tableList[j].status == 1) {
                    tableList[j].isSelected = false;
                    cart.removeSpecificGroupList(tableList[j].group!);
                    cart.removeAllCartItem();
                    cart.removePromotion();
                    cart.removeSpecificTable(tableList[j]);
                  }
                }
                Fluttertoast.showToast(backgroundColor: Color(0xFF07F107), msg: AppLocalizations.of(context)!.translate('table_not_in_use'));
              }

            }
          } else {
            if (tableList[index].status != 1) {
              //openEditTableDialog(tableList[index]);
            } else {
              if(tableList[index].order_key == null) {
                openChangeTableDialog(tableList[index], cart);
              } else {
                Fluttertoast.showToast(backgroundColor: Color(0xFFFF0000), msg: AppLocalizations.of(context)!.translate('payment_not_complete'));
              }
            }
          }
          setState(() {
            tapCount = 0;
            onTapDisable = false;
            Navigator.of(context).pop();
          });
        }catch(e){
          FLog.error(
            className: "table menu",
            text: "inside on select error",
            exception: e,
          );
          setState(() {
            tapCount = 0;
            onTapDisable = false;
            Navigator.of(context).pop();
          });
        }
      });
    }catch(e){
      FLog.error(
        className: "table menu",
        text: "outside on select error",
        exception: e,
      );
      setState(() {
        tapCount = 0;
        onTapDisable = false;
        Navigator.of(context).pop();
      });
    }
  }

  Future<Future<Object?>> openChooseQRDialog(List<PosTable> selectedTable) async {
    return showGeneralDialog(
        barrierColor: Colors.black.withOpacity(0.5),
        transitionBuilder: (context, a1, a2, widget) {
          final curvedValue = Curves.easeInOutBack.transform(a1.value) - 1.0;
          return Transform(
            transform: Matrix4.translationValues(0.0, curvedValue * 200, 0.0),
            child: ChooseQrTypeDialog(posTableList: selectedTable),
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

  Future<Future<Object?>> openLoadingDialogBox() async {
    return showGeneralDialog(
        barrierColor: Colors.black.withOpacity(0.5),
        transitionBuilder: (context, a1, a2, widget) {
          final curvedValue = Curves.easeInOutBack.transform(a1.value) - 1.0;
          return Transform(
            transform: Matrix4.translationValues(0.0, curvedValue * 200, 0.0),
            child: Opacity(
                opacity: a1.value,
                child: WillPopScope(child: LoadingDialog(isTableMenu: true), onWillPop: () async => false)),
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
    if(loadCount == 0){
      loadCount++;
      if(notification != null){
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
          loadCount = 0;
          isLoaded = true;
        });
      }
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
              double tableAmount = 0.0;
              tableList[i].group = data[0].table_use_sqlite_id;
              tableList[i].card_color = data[0].card_color;
              for(int j = 0; j < data.length; j++){
                tableAmount += double.parse(data[j].total_amount!);
              }
              if(data[0].order_key != ''){
                double amountPaid = 0;
                List<OrderPaymentSplit> orderSplit = await PosDatabase.instance.readSpecificOrderSplitByOrderKey(data[0].order_key!);

                for(int k = 0; k < orderSplit.length; k++){
                  amountPaid += double.parse(orderSplit[k].amount!);
                }
                List<Order> orderData = await PosDatabase.instance.readSpecificOrderByOrderKey(data[0].order_key!);
                tableAmount = double.parse(orderData[0].final_amount!);

                tableAmount -= amountPaid;
                tableList[i].order_key = data[0].order_key!;
              }
              tableList[i].total_amount = tableAmount.toStringAsFixed(2);
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
        List<OrderDetail> detailData = await PosDatabase.instance.readTableOrderDetail(data[i].order_cache_key!);
        //add all order detail from db
        if (!orderDetailList.contains(detailData)) {
          orderDetailList..addAll(detailData);
        }
      }
    }
    //loop all order detail
    for (int k = 0; k < orderDetailList.length; k++) {
      //Get data from branch link product
      List<BranchLinkProduct> data = await PosDatabase.instance.readSpecificBranchLinkProduct(orderDetailList[k].branch_link_product_sqlite_id!);
      orderDetailList[k].allow_ticket = data[0].allow_ticket;
      orderDetailList[k].ticket_count = data[0].ticket_count;
      orderDetailList[k].ticket_exp = data[0].ticket_exp;
      //Get product category
      if(orderDetailList[k].category_sqlite_id! == '0'){
        orderDetailList[k].product_category_id = '0';
      } else {
        Categories category = await PosDatabase.instance.readSpecificCategoryByLocalId(orderDetailList[k].category_sqlite_id!);
        orderDetailList[k].product_category_id = category.category_id.toString();
      }
      //check product modifier
      await getOrderModifierDetail(orderDetailList[k]);
    }
    productDetailLoaded = true;
  }

  getOrderModifierDetail(OrderDetail orderDetail) async {
    List<OrderModifierDetail> modDetail = await PosDatabase.instance.readOrderModifierDetail(orderDetail.order_detail_sqlite_id.toString());
    if (modDetail.isNotEmpty) {
      orderDetail.orderModifierDetail = modDetail;
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
    try{
      cart.addAllCartOrderCache(orderCacheList);
      cartProductItem value;
      List<TableUseDetail> tableUseDetailList = [];
      List<cartProductItem> cartItemList = [];
      var detailLength = orderDetailList.length;
      for (int i = 0; i < detailLength; i++) {
        value = cartProductItem(
          branch_link_product_sqlite_id: orderDetailList[i].branch_link_product_sqlite_id!,
          product_name: orderDetailList[i].productName!,
          category_id: orderDetailList[i].product_category_id!,
          price: orderDetailList[i].price!,
          quantity: int.tryParse(orderDetailList[i].quantity!) != null ? int.parse(orderDetailList[i].quantity!) : double.parse(orderDetailList[i].quantity!),
          orderModifierDetail: orderDetailList[i].orderModifierDetail,
          productVariantName: orderDetailList[i].product_variant_name,
          remark: orderDetailList[i].remark!,
          unit: orderDetailList[i].unit,
          per_quantity_unit: orderDetailList[i].per_quantity_unit,
          status: 0,
          order_cache_sqlite_id: orderDetailList[i].order_cache_sqlite_id,
          order_cache_key: orderDetailList[i].order_cache_key,
          category_sqlite_id: orderDetailList[i].category_sqlite_id,
          order_detail_sqlite_id: orderDetailList[i].order_detail_sqlite_id.toString(),
          base_price: orderDetailList[i].original_price,
          refColor: Colors.black,
          first_cache_created_date_time: orderCacheList.last.created_at,  //orderCacheList[0].created_at,
          first_cache_batch: orderCacheList.last.batch_id,
          first_cache_order_by: orderCacheList.last.order_by,
          allow_ticket: orderDetailList[i].allow_ticket,
          ticket_count: orderDetailList[i].ticket_count,
          ticket_exp: orderDetailList[i].ticket_exp,
          product_sku: orderDetailList[i].product_sku,
          order_key: orderKey,
        );
        cartItemList.add(value);
      }
      var cacheLength = orderCacheList.length;
      for (int j = 0; j < cacheLength; j++) {
        //Get specific table use detail
        List<TableUseDetail> tableUseDetailData = await PosDatabase.instance.readAllTableUseDetail(orderCacheList[j].table_use_sqlite_id!);
        tableUseDetailList = List.from(tableUseDetailData);
      }
      var length = tableUseDetailList.length;
      for (int k = 0; k < length; k++) {
        List<PosTable> tableData = await PosDatabase.instance.readSpecificTable(tableUseDetailList[k].table_sqlite_id!);
        tableData[0].isInPaymentCart = true;
        cart.addTable(tableData[0]);
      }
      cart.addAllItem(cartItemList: cartItemList);
    } catch(e){
      FLog.error(
        className: "table menu",
        text: "add to cart error",
        exception: e,
      );
    }
  }

  removeFromCart(CartModel cart, PosTable posTable) async {
    var value;
    List<TableUseDetail> tableUseDetailList = [];
    //await readSpecificTableDetail(posTable);
    if (this.productDetailLoaded) {
      var detailLength = orderDetailList.length;
      for (int i = 0; i < detailLength; i++) {
        value = cartProductItem(
          quantity: int.tryParse(orderDetailList[i].quantity!) != null ? int.parse(orderDetailList[i].quantity!) : double.parse(orderDetailList[i].quantity!),
          order_cache_sqlite_id: orderDetailList[i].order_cache_sqlite_id,
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
                callBack: onTapDisable ? (action, value){} : (action, value) {
                  if (action == 'on_tap'){
                    tapCount++;
                    setState(() {
                      onTapDisable = true;
                    });
                    if(tapCount == 1){
                      asyncQ.addJob((_) async {
                        try{
                          await onSelect(i, cart);
                        }catch(e) {
                          setState(() {
                            tapCount = 0;
                            onTapDisable = false;
                          });
                          FLog.error(
                            className: "table menu",
                            text: "advance on select queue error",
                            exception: e,
                          );
                        }
                      });
                    }
                  }
                  else if (action == 'on_double_tap') {
                    if(tableList[i].order_key == null) {
                      openChangeTableDialog(tableList[i], cart);
                    } else {
                      Fluttertoast.showToast(backgroundColor: Color(0xFFFF0000), msg: AppLocalizations.of(context)!.translate('payment_not_complete'));
                    }
                  }

                  else if (action == 'on_long_press'){
                    if(tableList[i].order_key == null) {
                      if(qrOrderStatus == '0'){
                        selectedTable = [tableList[i]];
                        openChooseQRDialog(selectedTable);
                      }
                    } else {
                      Fluttertoast.showToast(backgroundColor: Color(0xFFFF0000), msg: AppLocalizations.of(context)!.translate('payment_not_complete'));
                    }
                  }
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
      if(prefs.getBool('show_advanced') != null){
        showAdvanced = prefs.getBool('show_advanced')!;
      } else {
        showAdvanced = false;
      }
      String? branch = prefs.getString('branch');
      Map branchObject = json.decode(branch!);
      qrOrderStatus = branchObject['qr_order_status'];
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

  double calculateHeight(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;

    double screenRatio = screenWidth / screenHeight;

    double targetAspectRatio16x9 = 16 / 9;
    double targetAspectRatio4x3 = 4 / 3;

    double diff16x9 = (screenRatio - targetAspectRatio16x9).abs();
    double diff4x3 = (screenRatio - targetAspectRatio4x3).abs();

    return diff16x9 < diff4x3
        ? screenHeight / 5.5
        : screenHeight / 7;
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
