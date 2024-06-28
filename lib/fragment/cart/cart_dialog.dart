import 'dart:async';
import 'dart:convert';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_usb_printer/flutter_usb_printer.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';
import 'package:pos_system/notifier/cart_notifier.dart';
import 'package:pos_system/page/progress_bar.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:crypto/crypto.dart';

import '../../database/domain.dart';
import '../../database/pos_database.dart';
import '../../main.dart';
import '../../notifier/theme_color.dart';
import '../../object/branch_link_product.dart';
import '../../object/cart_product.dart';
import '../../object/categories.dart';
import '../../object/modifier_group.dart';
import '../../object/modifier_item.dart';
import '../../object/order_cache.dart';
import '../../object/order_detail.dart';
import '../../object/order_modifier_detail.dart';
import '../../object/print_receipt.dart';
import '../../object/printer.dart';
import '../../object/table.dart';
import '../../object/table_use_detail.dart';
import '../../object/variant_group.dart';
import '../../translation/AppLocalizations.dart';
import 'package:reorderable_grid_view/reorderable_grid_view.dart';

import '../logout_dialog.dart';
import '../table/advanced_table/advanced_table_view.dart';
import '../table/table_change_dialog.dart';

class CartDialog extends StatefulWidget {
  final List<PosTable> selectedTableList;

  const CartDialog({Key? key, required this.selectedTableList}) : super(key: key);

  @override
  State<CartDialog> createState() => CartDialogState();
}

class CartDialogState extends State<CartDialog> {
  FlutterUsbPrinter flutterUsbPrinter = FlutterUsbPrinter();
  List<PosTable> tableList = [];
  List<OrderCache> orderCacheList = [];
  List<OrderDetail> orderDetailList = [];
  List<VariantGroup> variantGroup = [];
  List<ModifierGroup> modifierGroup = [];
  List<TableUseDetail> tbUseDetailList = [];
  List<PosTable> sameGroupTbList = [];
  List<Printer> printerList = [];
  late StreamController controller;
  late SharedPreferences prefs;
  double scrollContainerHeight = 0.0;
  double priceSST = 0.0;
  double priceServeTax = 0.0;
  bool showAdvanced = false;
  bool isLoad = false;
  bool isFinish = false;
  bool isButtonDisabled = false, isMergeButtonDisabled = false, isLogOut = false;
  Color cardColor = Colors.white;
  String? table_use_detail_value, table_value, tableUseDetailKey, tableUseKey;
  String group = '';

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    controller = StreamController();
    readAllTable();
    getPreData();
  }

  Future<Future<Object?>> openLogOutDialog() async {
    return showGeneralDialog(
        barrierColor: Colors.black.withOpacity(0.5),
        transitionBuilder: (context, a1, a2, widget) {
          final curvedValue = Curves.easeInOutBack.transform(a1.value) - 1.0;
          return Transform(
            transform: Matrix4.translationValues(0.0, curvedValue * 200, 0.0),
            child: Opacity(
              opacity: a1.value,
              child: LogoutConfirmDialog(),
            ),
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

  showSecondDialog(BuildContext context, ThemeColor color, int dragIndex, int targetIndex, CartModel cart) {
    return showDialog(
      barrierDismissible: false,
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.translate('confirm_merge_table')),
        content: SizedBox(
            height: 100.0, width: 350.0, child: Text(AppLocalizations.of(context)!.translate('merge_table')+' ${tableList[dragIndex].number} ${AppLocalizations.of(context)!.translate('with_table')} ${tableList[targetIndex].number} ?')),
        actions: <Widget>[
          TextButton(
            child: Text('${AppLocalizations.of(context)?.translate('close')}'),
            onPressed: () {
              setState(() {
                for (int i = 0; i < tableList.length; i++) {
                  tableList[i].isSelected = false;
                }
                cart.initialLoad();
              });
              Navigator.of(context).pop();
            },
          ),
          TextButton(
            child: Text('${AppLocalizations.of(context)?.translate('yes')}'),
            onPressed: () async {
              Navigator.of(context).pop();
              if (tableList[dragIndex].table_sqlite_id != tableList[targetIndex].table_sqlite_id) {
                if (tableList[targetIndex].status == 1 && tableList[dragIndex].status == 0) {
                  asyncQ.addJob((_) async => await callAddNewTableQuery(tableList[dragIndex].table_sqlite_id!, tableList[targetIndex].table_sqlite_id!));
                  //await _printTableAddList(dragTable: tableList[dragIndex].number, targetTable: tableList[targetIndex].number);
                  cart.removeAllTable();
                  cart.removeAllCartItem();
                } else {
                  Fluttertoast.showToast(backgroundColor: Color(0xFFFF0000), msg: "${AppLocalizations.of(context)?.translate('merge_error_2')}");
                }
              } else {
                Fluttertoast.showToast(backgroundColor: Color(0xFFFF0000), msg: "${AppLocalizations.of(context)?.translate('merge_error')}");
              }
            },
          ),
        ],
      ),
    );
  }

  hexToColor(String hexCode) {
    return new Color(int.parse(hexCode.substring(1, 7), radix: 16) + 0xFF000000);
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

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeColor>(builder: (context, ThemeColor color, child) {
      return Consumer<CartModel>(builder: (context, CartModel cart, child) {
          return StreamBuilder(
              stream: controller.stream,
              builder: (context, snapshot) {
                return AlertDialog(
                  title: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(AppLocalizations.of(context)!.translate('select_table')),
                      Visibility(
                        visible: checkIsSelected(),
                        child: SizedBox(
                          width: MediaQuery.of(context).size.height > 500 && MediaQuery.of(context).size.width > 900 ? MediaQuery.of(context).size.width / 10 : MediaQuery.of(context).size.width / 8,
                          height: MediaQuery.of(context).size.height > 500 && MediaQuery.of(context).size.width > 900 ? MediaQuery.of(context).size.height / 20 : MediaQuery.of(context).size.height / 12,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              padding: EdgeInsets.zero,
                              backgroundColor: Colors.red,
                            ),
                            child: Text(
                              AppLocalizations.of(context)!.translate('clear_all'),
                              style: TextStyle(color: Colors.white),
                            ),
                            onPressed: () {
                              setState(() {
                                for (int i = 0; i < tableList.length; i++) {
                                  tableList[i].isSelected = false;
                                }
                                cart.initialLoad();
                              });
                              //Navigator.of(context).pop();
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                  content: isLoad
                      ? !showAdvanced
                        ? Container(
                            // height: 650,
                            width: MediaQuery.of(context).size.width / 2,
                            child: ReorderableGridView.count(
                              padding: EdgeInsets.zero,
                              shrinkWrap: true,
                              crossAxisSpacing: 10,
                              mainAxisSpacing: 10,
                              crossAxisCount: MediaQuery.of(context).size.height > 500 && MediaQuery.of(context).size.width > 900 ? 4 : 3,
                              children: tableList.asMap().map((index, posTable) => MapEntry(index, tableItem(cart, color, index))).values.toList(),
                              onReorder: (int oldIndex, int newIndex) {
                                if (oldIndex != newIndex) {
                                  showSecondDialog(context, color, oldIndex, newIndex, cart);
                                }
                              },
                            ))
                      : Column(
                    children: [
                      Expanded(
                        child: SingleChildScrollView(
                          child: Stack(
                            children: [
                              Container(
                                height: getScrollContainerHeight(),
                                // width: 900,
                                width: MediaQuery.of(context).size.width / 1.4,
                              ),
                              for (int i = 0; i < tableList.length; i++)
                                AdvancedTableView(
                                  cart: cart,
                                  position: i,
                                  table: tableList[i],
                                  tableList: tableList,
                                  tableLength: tableList.length,
                                  editingMode: false,
                                  callBack: (action, value) {
                                    if (action == 'on_tap')
                                      onSelect(i, cart, color);
                                    else if (action == 'on_double_tap')
                                      openChangeTableDialog(tableList[i], printerList: printerList);
                                    },
                                ),
                            ],
                          ),
                        ),
                      ),
                      // Other widgets you may want to include in the Column
                    ],
                  )


                      : CustomProgressBar(),

                  actions: <Widget>[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: MediaQuery.of(context).size.height / 12,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: color.backgroundColor,
                              ),
                              child: Text(AppLocalizations.of(context)!.translate('close'),
                                style: TextStyle(color: Colors.white),
                              ),
                              onPressed: isButtonDisabled ? null : () {
                                      setState(() {
                                        isButtonDisabled = true;
                                      });
                                      Navigator.of(context).pop();
                                    },
                            ),
                          ),
                        ),
                        SizedBox(width: 20),
                        Expanded(
                          child: SizedBox(
                            height: MediaQuery.of(context).size.height / 12,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: color.buttonColor,
                              ),
                              child: Text(AppLocalizations.of(context)!.translate('select_table'),
                                style: TextStyle(color: Colors.white),
                              ),
                              onPressed: !checkIsSelected() || isButtonDisabled ? null : () async {
                                      cart.removeAllTable();
                                      cart.removeAllCartItem();
                                      isButtonDisabled = true;
                                      for (int index = 0; index < tableList.length; index++) {
                                        //if using table is selected
                                        if (tableList[index].status == 1 && tableList[index].isSelected == true) {
                                          this.isLoad = false;
                                          await readSpecificTableDetail(tableList[index]);
                                          this.isLoad = true;
                                        }
                                        //if non-using table is selected
                                        else if (tableList[index].status == 0 && tableList[index].isSelected == true) {
                                          //merge all table
                                          cart.addTable(tableList[index]);
                                        } else {
                                          cart.removeSpecificTable(tableList[index]);
                                        }
                                      }
                                      if(orderDetailList.isNotEmpty){
                                        addToCart(cart);
                                      }
                                      Navigator.of(context).pop();
                                    },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              });
      });
    });
  }

  bool checkIsSelected() {
    bool selected = false;
    for (int i = 0; i < tableList.length; i++) {
      if (tableList[i].isSelected) {
        selected = true;
        break;
      }
    }
    return selected;
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

  Widget tableItem(CartModel cart, ThemeColor color, index) {
    return Container(
      key: Key(index.toString()),
      child: Card(
        elevation: 5,
        shape: tableList[index].isSelected
            ? new RoundedRectangleBorder(side: new BorderSide(color: color.backgroundColor, width: 3.0), borderRadius: BorderRadius.circular(4.0))
            : new RoundedRectangleBorder(side: new BorderSide(color: Colors.white, width: 3.0), borderRadius: BorderRadius.circular(4.0)),
        color: Colors.white,
        child: InkWell(
          splashColor: Colors.blue.withAlpha(30),
          onDoubleTap: () {
            if (tableList[index].status == 1) {
              openChangeTableDialog(tableList[index], printerList: printerList);
              cart.removeAllTable();
              cart.removeAllCartItem();
            } else {
              Fluttertoast.showToast(backgroundColor: Color(0xFFFF0000), msg: AppLocalizations.of(context)!.translate('table_not_in_use'));
            }
          },
          onTap: () async {
            //check selected table is in use or not
            if (tableList[index].status == 1) {
              // table in use (colored)
              for (int i = 0; i < tableList.length; i++) {
                //check all group
                if (tableList[index].group == tableList[i].group) {
                  if (tableList[i].isSelected == false) {
                    setState(() {
                      tableList[i].isSelected = true;
                    });
                  } else {
                    setState(() {
                      tableList[i].isSelected = false;
                    });
                  }
                } else {
                  setState(() {
                    tableList[i].isSelected = false;
                  });
                }
              }
            } else {
              //table not in use (white)
              for (int j = 0; j < tableList.length; j++) {
                //reset all using table to un-select (table status == 1)
                if (tableList[j].status == 1) {
                  setState(() {
                    tableList[j].isSelected = false;
                  });
                }
              }
              //for table not in use
              if (tableList[index].isSelected == false) {
                setState(() {
                  tableList[index].isSelected = true;
                });
              } else if (tableList[index].isSelected == true) {
                setState(() {
                  tableList[index].isSelected = false;
                });
              }
            }
          },
          child: Container(
            margin: EdgeInsets.all(10),
            child: Container(
              //margin: MediaQuery.of(context).size.height > 500 ? EdgeInsets.fromLTRB(0, 2, 0, 2) : null,
              height: 100,
              child: Stack(
                children: [
                  tableList[index].seats == '2'
                      ? Container(
                          decoration: BoxDecoration(
                            image: DecorationImage(
                              image: AssetImage("drawable/two-seat.jpg"),
                              fit: BoxFit.cover,
                            ),
                          ),
                        )
                      : tableList[index].seats == '4'
                          ? Container(
                              decoration: BoxDecoration(
                                image: DecorationImage(
                                  image: AssetImage("drawable/four-seat.jpg"),
                                  fit: BoxFit.cover,
                                ),
                              ),
                            )
                          : tableList[index].seats == '6'
                              ? Container(
                                  decoration: BoxDecoration(
                                    image: DecorationImage(
                                      image: AssetImage("drawable/six-seat.jpg"),
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                )
                              : SizedBox.shrink(),
                  Container(alignment: Alignment.center, child: Text(tableList[index].number!)),
                  tableList[index].group != null ? Row(
                      children: [
                        Container(
                          padding: EdgeInsets.only(right: 5.0, left: 5.0),
                          decoration: BoxDecoration(
                              color: tableList[index].group != null
                                  ?
                              toColor(tableList[index].card_color!)
                                  :
                              Colors.white,
                              borderRadius: BorderRadius.circular(5.0)
                          ),
                          child: MediaQuery.of(context).size.height > 500 ? Text(
                            "Group: ${tableList[index].group}",
                            style: TextStyle(fontSize: 18, color: fontColor(posTable: tableList[index])),
                          ) : Text(
                            "${tableList[index].group}",
                            style: TextStyle(fontSize: 14, color: fontColor(posTable: tableList[index])),
                          ),
                        ),
                        Spacer(),
                        Visibility(
                            visible: tableList[index].isSelected  ? true : false,
                            child: IconButton(
                              color: Colors.red,
                              icon: Icon(Icons.close, size: 18),
                              constraints: BoxConstraints(),
                              padding: EdgeInsets.zero,
                              onPressed: () async {
                                sameGroupTbList = [];
                                for (int i = 0; i < tableList.length; i++) {
                                  if (tableList[index].group == tableList[i].group) {
                                    sameGroupTbList.add(tableList[i]);
                                  }
                                }
                                if (sameGroupTbList.length > 1) {
                                  asyncQ.addJob((_) async {
                                    await callRemoveTableQuery(tableList[index].table_sqlite_id!);
                                  });
                                  tableList[index].isSelected = false;
                                  tableList[index].group = null;
                                  cart.removeAllTable();
                                  cart.removeAllCartItem();
                                } else {
                                  Fluttertoast.showToast(backgroundColor: Color(0xFFFF0000), msg: AppLocalizations.of(context)!.translate('cannot_remove_this_table'));
                                }
                              },
                            ))
                      ])
                      :
                  SizedBox.shrink(),
                ],
              ),
            ),
          ),
        ),
      ),
      // need to apply changes
    );
  }
// end of changes

  Future<Future<Object?>> openChangeTableDialog(PosTable posTable, {printerList}) async {
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
                  callBack: () => readAllTable(),
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

  readAllTable({isReset, bool? isServerCall}) async {
    isLoad = false;

    List<PosTable> data = await PosDatabase.instance.readAllTable();

    tableList = data;
    sortTable();
    await readAllTableAmount();
    if(isServerCall == null){
      if (widget.selectedTableList.isNotEmpty) {
        for (int i = 0; i < widget.selectedTableList.length; i++) {
          for (int j = 0; j < tableList.length; j++) {
            if (tableList[j].table_sqlite_id == widget.selectedTableList[i].table_sqlite_id) {
              tableList[j].isSelected = true;
            }
          }
        }
      }
    }
    if (isReset == true) {
      await resetAllTable();
    }
    await readAllPrinters();
    if (mounted) {
      setState(() {
        isLoad = true;
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

  resetAllTable() async {
    for (int j = 0; j < tableList.length; j++) {
      tableList[j].isSelected = false;
    }
  }

  readAllPrinters() async {
    printerList = await PrintReceipt().readAllPrinters();
  }

  readAllTableAmount() async {
    double tableAmount = 0.0;
    for (int i = 0; i < tableList.length; i++) {
      if(tableList[i].status == 1){
        List<TableUseDetail> tableUseDetailData = await PosDatabase.instance.readSpecificTableUseDetail(tableList[i].table_sqlite_id!);

        if (tableUseDetailData.isNotEmpty) {
          List<OrderCache> data = await PosDatabase.instance.readTableOrderCache(tableUseDetailData[0].table_use_key!);

          tableList[i].group = data[0].table_use_sqlite_id;
          tableList[i].card_color = data[0].card_color;

          for (int j = 0; j < data.length; j++) {
            tableAmount += double.parse(data[j].total_amount!);
          }
          tableList[i].total_amount = tableAmount.toStringAsFixed(2);
        }
      }
    }
  }

  readSpecificTableDetail(PosTable posTable) async {
    orderDetailList.clear();
    orderCacheList.clear();

    //Get specific table use detail
    List<TableUseDetail> tableUseDetailData = await PosDatabase.instance.readSpecificTableUseDetail(posTable.table_sqlite_id!);

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
    isFinish = true;
  }

  getOrderModifierDetail(OrderDetail orderDetail) async {
    List<OrderModifierDetail> modDetail = await PosDatabase.instance.readOrderModifierDetail(orderDetail.order_detail_sqlite_id.toString());
    if (modDetail.isNotEmpty) {
      orderDetail.orderModifierDetail = modDetail;
    } else {
      orderDetail.orderModifierDetail = [];
    }
  }

  addToCart(CartModel cart) async {
    var value;
    List<TableUseDetail> tableUseDetailList = [];
    cart.removeAllTable();
    print('order detail length: ${orderDetailList.length}');
    for (int i = 0; i < orderDetailList.length; i++) {
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
          status: 1,
          category_sqlite_id: orderDetailList[i].category_sqlite_id,
          order_cache_sqlite_id: orderCacheList.last.order_cache_sqlite_id.toString(),
          first_cache_created_date_time: orderCacheList.last.created_at,  //orderCacheList[0].created_at,
          first_cache_batch: orderCacheList.last.batch_id,
          first_cache_order_by: orderCacheList.last.order_by,
          allow_ticket: orderDetailList[i].allow_ticket,
          ticket_count: orderDetailList[i].ticket_count,
          ticket_exp: orderDetailList[i].ticket_exp
      );
      cart.addItem(value);
    }
    for (int j = 0; j < orderCacheList.length; j++) {
      //Get specific table use detail
      List<TableUseDetail> tableUseDetailData = await PosDatabase.instance.readAllTableUseDetail(orderCacheList[j].table_use_sqlite_id!);
      tableUseDetailList = List.from(tableUseDetailData);
    }

    for (int k = 0; k < tableUseDetailList.length; k++) {
      List<PosTable> tableData = await PosDatabase.instance.readSpecificTable(tableUseDetailList[k].table_sqlite_id!);
      cart.addTable(tableData[0]);
    }
  }

  /**
   * concurrent here
   */
  callRemoveTableQuery(int table_id) async {
    if(await checkTableStatus(table_id) == true){
      await deleteCurrentTableUseDetail(table_id);
      await updatePosTableStatus(table_id, 0, '', '');
      // await syncAllToCloud();
      // if (this.isLogOut == true) {
      //   openLogOutDialog();
      //   return;
      // }
      await readAllTable(isReset: true);
    }
  }

  Future<bool> checkTableStatus(int table_id) async {
    bool tableInUse = false;
    List<PosTable> table = await PosDatabase.instance.checkPosTableStatus(table_id);
    if(table[0].status == 1){
      tableInUse = true;
    }
    return tableInUse;
  }

  deleteCurrentTableUseDetail(int currentTableId) async {
    print('current delete table local id: ${currentTableId}');
    DateFormat dateFormat = DateFormat("yyyy-MM-dd HH:mm:ss");
    String dateTime = dateFormat.format(DateTime.now());
    List<String> _value = [];
    try {
      List<TableUseDetail> checkData = await PosDatabase.instance.readSpecificTableUseDetail(currentTableId);
      print('check data length: ${checkData.length}');
      TableUseDetail tableUseDetailObject = TableUseDetail(
          soft_delete: dateTime,
          sync_status: checkData[0].sync_status == 0 ? 0 : 2,
          status: 1,
          table_sqlite_id: currentTableId.toString(),
          table_use_detail_key: checkData[0].table_use_detail_key,
          table_use_detail_sqlite_id: checkData[0].table_use_detail_sqlite_id);
      int updatedData = await PosDatabase.instance.deleteTableUseDetailByKey(tableUseDetailObject);
      print('update status: ${updatedData}');
      if (updatedData == 1) {
        TableUseDetail detailData = await PosDatabase.instance.readSpecificTableUseDetailByLocalId(tableUseDetailObject.table_use_detail_sqlite_id!);
        _value.add(jsonEncode(detailData));
      }
      print('tb use detail value: ${_value}');
      //sync to cloud
      this.table_use_detail_value = _value.toString();
      //syncDeletedTableUseDetailToCloud(_value.toString());
      // Map data = await Domain().SyncTableUseDetailToCloud(_value.toString());
      // if(data['status'] == 1){
      //   List responseJson = data['data'];
      //   int tablaUseDetailData = await PosDatabase.instance.updateTableUseDetailSyncStatusFromCloud(responseJson[0]['table_use_detail_key']);
      // }
    } catch (e) {
      Fluttertoast.showToast(backgroundColor: Color(0xFFFF0000), msg: AppLocalizations.of(context)!.translate('delete_current_table_use_detail_error')+": ${e}");
    }
  }

  // syncDeletedTableUseDetailToCloud(String value) async {
  //   bool _hasInternetAccess = await Domain().isHostReachable();
  //   if (_hasInternetAccess) {
  //     Map data = await Domain().SyncTableUseDetailToCloud(value);
  //     if (data['status'] == '1') {
  //       List responseJson = data['data'];
  //       int tablaUseDetailData = await PosDatabase.instance.updateTableUseDetailSyncStatusFromCloud(responseJson[0]['table_use_detail_key']);
  //     }
  //   }
  // }

  updatePosTableStatus(int dragTableId, int status, String tableUseDetailKey, String tableUseKey) async {
    List<String> _value = [];
    DateFormat dateFormat = DateFormat("yyyy-MM-dd HH:mm:ss");
    String dateTime = dateFormat.format(DateTime.now());
    /*get target table use key here*/
    PosTable posTableData = PosTable(
        table_use_detail_key: tableUseDetailKey,
        table_use_key: tableUseKey,
        table_sqlite_id: dragTableId,
        status: status,
        updated_at: dateTime);
    int updatedTable = await PosDatabase.instance.updatePosTableStatus(posTableData);
    int updatedKey = await PosDatabase.instance.removePosTableTableUseDetailKey(posTableData);
    if (updatedTable == 1 && updatedKey == 1) {
      List<PosTable> posTable = await PosDatabase.instance.readSpecificTable(posTableData.table_sqlite_id.toString());
      _value.add(jsonEncode(posTable[0]));
    }
    print('table value: ${_value}');
    //sync to cloud
    this.table_value = _value.toString();
    //syncUpdatedTableToCloud(_value.toString());
    // Map response = await Domain().SyncUpdatedPosTableToCloud(_value.toString());
    // if (response['status'] == '1') {
    //   List responseJson = response['data'];
    //   int syncData = await PosDatabase.instance.updatePosTableSyncStatusFromCloud(responseJson[0]['table_id']);
    // }
  }

  // syncUpdatedTableToCloud(String value) async {
  //   bool _hasInternetAccess = await Domain().isHostReachable();
  //   if (_hasInternetAccess) {
  //     Map response = await Domain().SyncUpdatedPosTableToCloud(value);
  //     if (response['status'] == '1') {
  //       List responseJson = response['data'];
  //       int syncData = await PosDatabase.instance.updatePosTableSyncStatusFromCloud(responseJson[0]['table_id']);
  //     }
  //   }
  // }

  callAddNewTableQuery(int dragTableId, int targetTableId) async {
    //List<TableUseDetail> checkData = await PosDatabase.instance.readSpecificTableUseDetail(targetTableId);
    if(await checkTableStatus(dragTableId) == false && await checkTableStatus(targetTableId) == true){
      await createTableUseDetail(dragTableId, targetTableId);
      await updatePosTableStatus(dragTableId, 1, this.tableUseDetailKey!, tableUseKey!);
      // await syncAllToCloud();
      // if (this.isLogOut == true) {
      //   openLogOutDialog();
      //   return;
      // }

    }
    await readAllTable(isReset: true);
  }

  generateTableUseDetailKey(TableUseDetail tableUseDetail) async {
    final prefs = await SharedPreferences.getInstance();
    final int? device_id = prefs.getInt('device_id');
    var bytes = tableUseDetail.created_at!.replaceAll(new RegExp(r'[^0-9]'), '') +
        tableUseDetail.table_use_detail_sqlite_id.toString() +
        device_id.toString();
    return md5.convert(utf8.encode(bytes)).toString();
  }

  insertTableUseDetailKey(TableUseDetail tableUseDetail, String dateTime) async {
    String? tableUseDetailKey;
    TableUseDetail? _tableUseDetailData;
    tableUseDetailKey = await generateTableUseDetailKey(tableUseDetail);
    if (tableUseDetailKey != null) {
      TableUseDetail tableUseDetailObject = TableUseDetail(
          table_use_detail_key: tableUseDetailKey,
          sync_status: 0,
          updated_at: dateTime,
          table_use_detail_sqlite_id: tableUseDetail.table_use_detail_sqlite_id);
      int data = await PosDatabase.instance.updateTableUseDetailUniqueKey(tableUseDetailObject);
      if (data == 1) {
        TableUseDetail detailData = await PosDatabase.instance.readSpecificTableUseDetailByLocalId(tableUseDetailObject.table_use_detail_sqlite_id!);
        _tableUseDetailData = detailData;
      }
    }
    return _tableUseDetailData;
  }

  createTableUseDetail(int newTableId, int oldTableId) async {
    DateFormat dateFormat = DateFormat("yyyy-MM-dd HH:mm:ss");
    String dateTime = dateFormat.format(DateTime.now());
    List<String> _value = [];
    try {
      //read table use detail data based on target table id
      List<TableUseDetail> tableUseDetailData = await PosDatabase.instance.readSpecificTableUseDetail(oldTableId);
      List<PosTable> tableData = await PosDatabase.instance.readSpecificTable(newTableId.toString());

      //create table use detail
      TableUseDetail insertData = await PosDatabase.instance.insertSqliteTableUseDetail(TableUseDetail(
          table_use_detail_id: 0,
          table_use_detail_key: '',
          table_use_sqlite_id: tableUseDetailData[0].table_use_sqlite_id,
          table_use_key: tableUseDetailData[0].table_use_key,
          table_sqlite_id: newTableId.toString(),
          table_id: tableData[0].table_id.toString(),
          created_at: dateTime,
          status: 0,
          sync_status: 0,
          updated_at: '',
          soft_delete: ''));
      this.tableUseKey = insertData.table_use_key;
      TableUseDetail updatedDetail = await insertTableUseDetailKey(insertData, dateTime);
      this.tableUseDetailKey = updatedDetail.table_use_detail_key;
      _value.add(jsonEncode(updatedDetail));
      //sync to cloud
      this.table_use_detail_value = _value.toString();
      //syncTableUseDetailToCloud(_value.toString());
    } catch (e) {
      print('create table use detail error: $e');
      Fluttertoast.showToast(backgroundColor: Color(0xFFFF0000), msg: AppLocalizations.of(context)!.translate('create_table_detail_error')+" ${e}");
    }
  }

  // syncTableUseDetailToCloud(String value) async {
  //   bool _hasInternetAccess = await Domain().isHostReachable();
  //   if (_hasInternetAccess) {
  //     Map data = await Domain().SyncTableUseDetailToCloud(value);
  //     if (data['status'] == '1') {
  //       List responseJson = data['data'];
  //       int syncData = await PosDatabase.instance.updateTableUseDetailSyncStatusFromCloud(responseJson[0]['table_use_detail_key']);
  //     }
  //   }
  // }

  syncAllToCloud() async {
    try{
      if(mainSyncToCloud.count == 0){
        mainSyncToCloud.count = 1;
        final prefs = await SharedPreferences.getInstance();
        final int? device_id = prefs.getInt('device_id');
        final String? login_value = prefs.getString('login_value');
        Map data = await Domain().syncLocalUpdateToCloud(
            device_id: device_id.toString(), value: login_value, table_use_detail_value: this.table_use_detail_value, table_value: this.table_value);
        if (data['status'] == '1') {
          List responseJson = data['data'];
          for (int i = 0; i < responseJson.length; i++) {
            switch (responseJson[i]['table_name']) {
              case 'tb_table_use_detail':
                {
                  await PosDatabase.instance.updateTableUseDetailSyncStatusFromCloud(responseJson[i]['table_use_detail_key']);
                }
                break;
              case 'tb_table':
                {
                  await PosDatabase.instance.updatePosTableSyncStatusFromCloud(responseJson[i]['table_id']);
                }
                break;
              default:
                {
                  return;
                }
            }
          }
          mainSyncToCloud.resetCount();
        } else if (data['status'] == '7') {
          mainSyncToCloud.resetCount();
          this.isLogOut = true;
        }else if (data['status'] == '8'){
          print('cart dialog sync to cloud timeout');
          mainSyncToCloud.resetCount();
          throw TimeoutException("Timeout");
        }
      }
      // bool _hasInternetAccess = await Domain().isHostReachable();
      // if (_hasInternetAccess) {
      //
      // }
    }catch(e){
      mainSyncToCloud.resetCount();
    }
  }

  void getPreData() async {
    try {
      prefs = await SharedPreferences.getInstance();
      showAdvanced = prefs.getBool('show_advanced')!;
    } catch (e) {
      showAdvanced = false;
    }
  }

  void onSelect(int index, CartModel cart, ThemeColor color) {
    //check selected table is in use or not
    if (tableList[index].status == 1) {
      print('Group: '+ getSelectedTableGroup(tableList[index].group.toString()));
      // table in use (colored)
      for (int i = 0; i < tableList.length; i++) {
        //check all group
        setState(() {
          if (tableList[index].group == tableList[i].group) {
            if (tableList[i].isSelected == false) {
              tableList[i].isSelected = true;
            } else {
              tableList[i].isSelected = false;
            }
          } else {
            tableList[i].isSelected = false;
          }
        });

      }
    } else {
      print('Group: '+ getSelectedTableGroup(''));

      if (getSelectedTableGroup('') == ''){
        //table not in use (white)
        for (int j = 0; j < tableList.length; j++) {
          //reset all using table to un-select (table status == 1)
          if (tableList[j].status == 1) {
            setState(() {
              tableList[j].isSelected = false;
            });
          }
        }
      }

      //for table not in use
      if (tableList[index].isSelected == false) {
        setState(() {
          tableList[index].isSelected = true;
        });
      } else if (tableList[index].isSelected == true) {
        setState(() {
          tableList[index].isSelected = false;
        });
      }
    }
    int dragIndex = -1;
    int targetIndex = -1;
    for (int j = 0; j < tableList.length; j++) {
      if(tableList[j].isSelected == true) {

        // table have group/ target index
        if (tableList[j].group == getSelectedTableGroup('')) {
          targetIndex = j;
        }
        else {
          dragIndex = j;
        }
      }
    }
    if(dragIndex != -1 && targetIndex != -1 )
      showSecondDialog(context, color, dragIndex, targetIndex, cart);
  }

  String getSelectedTableGroup(String selectedTableGroup) {
    if(selectedTableGroup != '')
      group = selectedTableGroup;
    return group;
  }

  getScrollContainerHeight() {
    if(scrollContainerHeight == 0){
      double maxDy = tableList
          .where((posTable) => posTable.dy != null && posTable.dy!.isNotEmpty)
          .map((posTable) => double.tryParse(posTable.dy ?? '') ?? 0.0)
          .fold(0.0, (max, dyValue) => max > dyValue ? max : dyValue);

      scrollContainerHeight = maxDy + 130;
    }
    return scrollContainerHeight;
  }
}
