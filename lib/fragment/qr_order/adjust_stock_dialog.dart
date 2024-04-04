import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:another_flushbar/flushbar.dart';
import 'package:assets_audio_player/assets_audio_player.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';
import 'package:pos_system/notifier/app_setting_notifier.dart';
import 'package:pos_system/notifier/theme_color.dart';
import 'package:pos_system/object/print_receipt.dart';
import 'package:pos_system/object/printer.dart';
import 'package:pos_system/object/table.dart';
import 'package:pos_system/utils/Utils.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:crypto/crypto.dart';

import '../../database/domain.dart';
import '../../database/pos_database.dart';
import '../../main.dart';
import '../../notifier/fail_print_notifier.dart';
import '../../object/branch_link_product.dart';
import '../../object/order_cache.dart';
import '../../object/order_detail.dart';
import '../../object/table_use.dart';
import '../../object/table_use_detail.dart';
import '../../translation/AppLocalizations.dart';
import '../logout_dialog.dart';

class AdjustStockDialog extends StatefulWidget {
  final int orderCacheLocalId;
  final String tableLocalId;
  final String currentBatch;
  final List<OrderCache> orderCacheList;
  final List<OrderDetail> orderDetailList;
  final Function() callBack;

  const AdjustStockDialog(
      {Key? key,
        required this.orderDetailList,
        required this.orderCacheLocalId,
        required this.callBack,
        required this.tableLocalId,
        required this.orderCacheList, required this.currentBatch})
      : super(key: key);

  @override
  State<AdjustStockDialog> createState() => _AdjustStockDialogState();
}

class _AdjustStockDialogState extends State<AdjustStockDialog> {
  DateFormat dateFormat = DateFormat("yyyy-MM-dd HH:mm:ss");
  List<OrderDetail> orderDetailList = [], noStockOrderDetailList = [], removeDetailList = [];
  List<Printer> printerList = [];
  String localTableUseId = '', tableUseKey = '', tableUseDetailKey = '', batchNo = '';
  String? table_use_value, table_use_detail_value, order_cache_value, order_detail_value,
      delete_order_detail_value, order_modifier_detail_value, table_value, branch_link_product_value;
  double newSubtotal = 0.0;
  bool hasNoStockProduct = false, hasNotAvailableProduct = false, tableInUsed = false;
  bool isButtonDisabled = false, isLogOut = false;
  bool willPop = true;
  late AppSettingModel _appSettingModel;

  late FailPrintModel _failPrintModel;

  @override
  void initState() {
    super.initState();
    readAllPrinters();
  }

  readAllPrinters() async {
    printerList = await PrintReceipt().readAllPrinters();
  }

  formatProductVariant(String variant) {
    String result = '';
    result = variant.toString().replaceAll("|", ",");
    return result;
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

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeColor>(builder: (context, ThemeColor color, child) {
      return Consumer<AppSettingModel>(builder: (context, AppSettingModel appSettingModel, child) {
        _appSettingModel = appSettingModel;
        return Consumer<FailPrintModel>(builder: (context, FailPrintModel failPrintModel, child) {
          _failPrintModel = failPrintModel;
          return LayoutBuilder(builder: (context, constraints) {
            if (constraints.maxWidth > 800) {
              return WillPopScope(
                onWillPop: () async => willPop,
                child: AlertDialog(
                  title: Row(
                    children: [
                      Text(AppLocalizations.of(context)!.translate('order_detail'),
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Spacer(),
                      IconButton(
                          onPressed: (){
                            if(removeDetailList.isNotEmpty){
                              if(mounted){
                                setState(() {
                                  widget.orderDetailList.addAll(removeDetailList);
                                  removeDetailList.clear();
                                });
                                Fluttertoast.showToast(msg: "${AppLocalizations.of(context)?.translate('content_reset_success')}", backgroundColor: Colors.green);
                              }
                            } else {
                              Fluttertoast.showToast(msg: "${AppLocalizations.of(context)?.translate('content_already_reset')}", backgroundColor: Colors.red);
                            }
                          },
                          icon: Icon(Icons.refresh))
                    ],
                  ),
                  content: Container(
                    height: MediaQuery.of(context).size.height,
                    width: MediaQuery.of(context).size.width / 1.5,
                    child: ListView.builder(
                        padding: EdgeInsets.zero,
                        itemCount: widget.orderDetailList.length,
                        shrinkWrap: true,
                        itemBuilder: (context, index) {
                          return Dismissible(
                            background: Container(
                              color: Colors.red,
                              padding: EdgeInsets.only(left: 25.0),
                              child: Row(
                                children: [
                                  Icon(Icons.delete, color: Colors.white),
                                ],
                              ),
                            ),
                            key: ValueKey(widget.orderDetailList[index].productName),
                            direction: DismissDirection.startToEnd,
                            confirmDismiss: (direction) async {
                              if (direction == DismissDirection.startToEnd) {
                                print('detail remove');
                                if (mounted) {
                                  setState(() {
                                    widget.orderDetailList[index].isRemove = true;
                                    removeDetailList.add(widget.orderDetailList[index]);
                                    widget.orderDetailList.removeAt(index);
                                  });
                                }
                              }
                              return null;
                            },
                            child: Card(
                              elevation: 5,
                              child: Container(
                                margin: EdgeInsets.all(10),
                                child: Column(children: [
                                  ListTile(
                                    onTap: null,
                                    isThreeLine: true,
                                    title: RichText(
                                      text: TextSpan(
                                        children: <TextSpan>[
                                          TextSpan(
                                              text: "${widget.orderDetailList[index].productName}" + "\n",
                                              style: TextStyle(fontSize: 14, color: Colors.black)),
                                          TextSpan(
                                              text: "RM ${widget.orderDetailList[index].price}", style: TextStyle(fontSize: 13, color: Colors.black)),
                                        ],
                                      ),
                                    ),
                                    subtitle: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Visibility(
                                          visible: widget.orderDetailList[index].product_variant_name != '' ? true : false,
                                          child: Text("(${Utils.formatProductVariant(widget.orderDetailList[index].product_variant_name!)})"),
                                        ),
                                        Visibility(
                                          visible: getOrderDetailModifier(widget.orderDetailList[index]) != '' ? true : false,
                                          child: Text("${getOrderDetailModifier(widget.orderDetailList[index])}"),
                                        ),
                                        widget.orderDetailList[index].remark != '' ? Text("*${widget.orderDetailList[index].remark}") : Text('')
                                      ],
                                    ),
                                    trailing: Container(
                                      child: FittedBox(
                                        child: Column(
                                          children: [
                                            Row(
                                              crossAxisAlignment: CrossAxisAlignment.center,
                                              children: [
                                                IconButton(
                                                    hoverColor: Colors.transparent,
                                                    icon: Icon(
                                                      Icons.remove,
                                                      size: 40,
                                                    ),
                                                    onPressed: () {
                                                      print('qty remove');
                                                      int qty = int.parse(widget.orderDetailList[index].quantity!);
                                                      int totalQty = qty - 1;
                                                      if (totalQty <= 0) {
                                                        setState(() {
                                                          widget.orderDetailList[index].isRemove = true;
                                                          removeDetailList.add(widget.orderDetailList[index]);
                                                          widget.orderDetailList.removeAt(index);
                                                        });
                                                      } else {
                                                        setState(() {
                                                          widget.orderDetailList[index].quantity = totalQty.toString();
                                                        });
                                                      }
                                                    }),
                                                Padding(
                                                  padding: const EdgeInsets.fromLTRB(10, 0, 10, 0),
                                                  child: Text(
                                                    '${widget.orderDetailList[index].quantity}',
                                                    textAlign: TextAlign.center,
                                                    style: TextStyle(color: Colors.black, fontSize: 30),
                                                  ),
                                                ),
                                                IconButton(
                                                    hoverColor: Colors.transparent,
                                                    icon: Icon(
                                                      Icons.add,
                                                      size: 40,
                                                    ),
                                                    onPressed: () {
                                                      if(widget.orderDetailList[index].available_stock != ''){
                                                        if (int.parse(widget.orderDetailList[index].quantity!) < int.parse(widget.orderDetailList[index].available_stock!)) {
                                                          setState(() {
                                                            int qty = int.parse(widget.orderDetailList[index].quantity!);
                                                            int totalQty = qty + 1;
                                                            widget.orderDetailList[index].quantity = totalQty.toString();
                                                          });
                                                        } else {
                                                          Fluttertoast.showToast(backgroundColor: Colors.red, msg: AppLocalizations.of(context)!.translate('out_of_stock'));
                                                        }
                                                      } else {
                                                        setState(() {
                                                          int qty = int.parse(widget.orderDetailList[index].quantity!);
                                                          int totalQty = qty + 1;
                                                          widget.orderDetailList[index].quantity = totalQty.toString();
                                                        });
                                                      }
                                                    })
                                              ],
                                            ),
                                            Visibility(
                                                visible: widget.orderDetailList[index].available_stock != '' ? true : false,
                                                child: Text(AppLocalizations.of(context)!.translate('available_stock')+': ${widget.orderDetailList[index].available_stock}')
                                            )
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ]),
                              ),
                            ),
                          );
                        }),
                  ),
                  actions: <Widget>[
                    SizedBox(
                      width: MediaQuery.of(context).size.width / 4,
                      height: MediaQuery.of(context).size.height / 12,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: color.backgroundColor,
                        ),
                        child: Text(AppLocalizations.of(context)!.translate('close'),
                          style: TextStyle(color: Colors.white),
                        ),
                        onPressed: isButtonDisabled
                            ? null
                            : () {
                          // Disable the button after it has been pressed
                          setState(() {
                            isButtonDisabled = true;
                          });
                          Navigator.of(context).pop();
                        },
                      ),
                    ),
                    SizedBox(
                      width: MediaQuery.of(context).size.width / 4,
                      height: MediaQuery.of(context).size.height / 12,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.redAccent,
                        ),
                        child: Text(AppLocalizations.of(context)!.translate('reject'),
                          style: TextStyle(color: Colors.white),
                        ),
                        onPressed: isButtonDisabled
                            ? null
                            : () async {
                          // Disable the button after it has been pressed
                          setState(() {
                            isButtonDisabled = true;
                            willPop = false;
                          });
                          await callRejectOrder();
                          syncToCloudFunction();
                        },
                      ),
                    ),
                    SizedBox(
                      width: MediaQuery.of(context).size.width / 4,
                      height: MediaQuery.of(context).size.height / 12,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: color.buttonColor,
                        ),
                        child: Text(AppLocalizations.of(context)!.translate('add'),
                          style: TextStyle(color: Colors.white),
                        ),
                        onPressed: isButtonDisabled
                            ? null
                            : widget.orderDetailList.isNotEmpty
                            ? () async {
                          await checkOrderDetailStock();
                          print('available check: ${hasNotAvailableProduct}');
                          if (hasNoStockProduct) {
                            Fluttertoast.showToast(backgroundColor: Colors.orangeAccent, msg: AppLocalizations.of(context)!.translate('contain_out_of_stock_product'));
                          } else if(hasNotAvailableProduct){
                            Fluttertoast.showToast(backgroundColor: Colors.red, msg: AppLocalizations.of(context)!.translate('contain_not_available_product'));
                          } else {
                            // Disable the button after it has been pressed
                            setState(() {
                              isButtonDisabled = true;
                              willPop = false;
                            });
                            if (removeDetailList.isNotEmpty) {
                              await removeOrderDetail();
                            }
                            if (widget.tableLocalId != '') {
                              await checkTable();
                              if (tableInUsed == true) {
                                await updateOrderDetail();
                                await updateOrderCache();
                                await updateProductStock();
                              } else {
                                await callNewOrder();
                                await updateProductStock();
                              }
                            } else {
                              await callOtherOrder();
                            }
                            if(_appSettingModel.autoPrintChecklist == true){
                              await printCheckList();
                            }
                            syncToCloudFunction();
                            widget.callBack;
                            Navigator.of(context).pop();
                            await callPrinter();
                          }
                        }
                            : null,
                      ),
                    ),
                  ],
                ),
              );
            } else {
              ///mobile layout
              return AlertDialog(
                title: Text(AppLocalizations.of(context)!.translate('order_detail'),
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                content: Container(
                  //height: MediaQuery.of(context).size.height,
                  width: MediaQuery.of(context).size.width,
                  child: ListView.builder(
                      padding: EdgeInsets.zero,
                      itemCount: widget.orderDetailList.length,
                      shrinkWrap: true,
                      itemBuilder: (context, index) {
                        return Dismissible(
                          background: Container(
                            color: Colors.red,
                            padding: EdgeInsets.only(left: 25.0),
                            child: Row(
                              children: [
                                Icon(Icons.delete, color: Colors.white),
                              ],
                            ),
                          ),
                          key: ValueKey(widget.orderDetailList[index].productName),
                          direction: DismissDirection.startToEnd,
                          confirmDismiss: (direction) async {
                            if (direction == DismissDirection.startToEnd) {
                              print('detail remove');
                              if (mounted) {
                                setState(() {
                                  widget.orderDetailList[index].isRemove = true;
                                  removeDetailList.add(widget.orderDetailList[index]);
                                  widget.orderDetailList.removeAt(index);
                                });
                              }
                            }
                            return null;
                          },
                          child: Card(
                            elevation: 5,
                            child: Container(
                              margin: EdgeInsets.all(10),
                              height: MediaQuery.of(context).size.height / 4,
                              child: Column(children: [
                                Expanded(
                                  child: ListTile(
                                    onTap: null,
                                    isThreeLine: true,
                                    title: RichText(
                                      text: TextSpan(
                                        children: <TextSpan>[
                                          TextSpan(
                                              text: "${widget.orderDetailList[index].productName}" + "\n",
                                              style: TextStyle(fontSize: 14, color: Colors.black)),
                                          TextSpan(
                                              text: "RM ${widget.orderDetailList[index].price}", style: TextStyle(fontSize: 13, color: Colors.black)),
                                        ],
                                      ),
                                    ),
                                    subtitle: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Visibility(
                                          visible: widget.orderDetailList[index].product_variant_name != '' ? true : false,
                                          child: Text("+${widget.orderDetailList[index].product_variant_name}"),
                                        ),
                                        //modifier
                                        Visibility(
                                          visible: getOrderDetailModifier(widget.orderDetailList[index]) != '' ? true : false,
                                          child: Text("${getOrderDetailModifier(widget.orderDetailList[index])}"),
                                        ),
                                        widget.orderDetailList[index].remark != '' ? Text("*${widget.orderDetailList[index].remark}") : Text('')
                                      ],
                                    ),
                                    trailing: Container(
                                      child: FittedBox(
                                        child: Column(
                                          children: [
                                            Row(
                                              crossAxisAlignment: CrossAxisAlignment.center,
                                              children: [
                                                IconButton(
                                                    hoverColor: Colors.transparent,
                                                    icon: Icon(
                                                      Icons.remove,
                                                      size: 40,
                                                    ),
                                                    onPressed: () {
                                                      print('qty remove');
                                                      int qty = int.parse(widget.orderDetailList[index].quantity!);
                                                      int totalQty = qty - 1;
                                                      if (totalQty <= 0) {
                                                        setState(() {
                                                          widget.orderDetailList[index].isRemove = true;
                                                          removeDetailList.add(widget.orderDetailList[index]);
                                                          widget.orderDetailList.removeAt(index);
                                                        });
                                                      } else {
                                                        setState(() {
                                                          widget.orderDetailList[index].quantity = totalQty.toString();
                                                        });
                                                      }
                                                    }),
                                                Padding(
                                                  padding: const EdgeInsets.fromLTRB(10, 0, 10, 0),
                                                  child: Text(
                                                    '${widget.orderDetailList[index].quantity}',
                                                    style: TextStyle(color: Colors.black, fontSize: 30),
                                                  ),
                                                ),
                                                IconButton(
                                                    hoverColor: Colors.transparent,
                                                    icon: Icon(
                                                      Icons.add,
                                                      size: 40,
                                                    ),
                                                    onPressed: () {
                                                      if(int.tryParse(widget.orderDetailList[index].available_stock!) != null){
                                                        if (int.parse(widget.orderDetailList[index].quantity!) <
                                                            int.parse(widget.orderDetailList[index].available_stock!)) {
                                                          setState(() {
                                                            int qty = int.parse(widget.orderDetailList[index].quantity!);
                                                            int totalQty = qty + 1;
                                                            widget.orderDetailList[index].quantity = totalQty.toString();
                                                          });
                                                        } else {
                                                          Fluttertoast.showToast(backgroundColor: Colors.red, msg: AppLocalizations.of(context)!.translate('out_of_stock'));
                                                        }
                                                      } else {
                                                        setState(() {
                                                          int qty = int.parse(widget.orderDetailList[index].quantity!);
                                                          int totalQty = qty + 1;
                                                          widget.orderDetailList[index].quantity = totalQty.toString();
                                                        });
                                                      }
                                                    })
                                              ],
                                            ),
                                            Visibility(
                                                visible: widget.orderDetailList[index].available_stock != '' ? true : false,
                                                child: Text(AppLocalizations.of(context)!.translate('available_stock')+': ${widget.orderDetailList[index].available_stock}')
                                            )
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ]),
                            ),
                          ),
                        );
                      }),
                ),
                actions: <Widget>[
                  SizedBox(
                    width: MediaQuery.of(context).size.width / 3.6,
                    height: MediaQuery.of(context).size.height / 8,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: color.backgroundColor,
                      ),
                      child: Text(AppLocalizations.of(context)!.translate('close')),
                      onPressed: isButtonDisabled
                          ? null
                          : () {
                        // Disable the button after it has been pressed
                        setState(() {
                          isButtonDisabled = true;
                        });
                        Navigator.of(context).pop();
                      },
                    ),
                  ),
                  SizedBox(
                    width: MediaQuery.of(context).size.width / 3.6,
                    height: MediaQuery.of(context).size.height / 8,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                      ),
                      child: Text(AppLocalizations.of(context)!.translate('reject')),
                      onPressed: isButtonDisabled
                          ? null
                          : () async {
                        // Disable the button after it has been pressed
                        setState(() {
                          isButtonDisabled = true;
                        });
                        await callRejectOrder();
                        syncToCloudFunction();
                      },
                    ),
                  ),
                  SizedBox(
                    width: MediaQuery.of(context).size.width / 3.6,
                    height: MediaQuery.of(context).size.height / 8,
                    child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: color.buttonColor,
                        ),
                        child: Text(AppLocalizations.of(context)!.translate('add')),
                        onPressed: isButtonDisabled || widget.orderDetailList.isEmpty ? null : () async {
                          await checkOrderDetailStock();
                          if (hasNoStockProduct) {
                            Fluttertoast.showToast(backgroundColor: Colors.orangeAccent, msg: AppLocalizations.of(context)!.translate('contain_out_of_stock_product'));
                          } else if (hasNotAvailableProduct){
                            Fluttertoast.showToast(backgroundColor: Colors.red, msg: AppLocalizations.of(context)!.translate('contain_not_available_product'));
                          } else {
                            // Disable the button after it has been pressed
                            setState(() {
                              isButtonDisabled = true;
                            });
                            if (removeDetailList.isNotEmpty) {
                              await removeOrderDetail();
                            }
                            if (widget.tableLocalId != '') {
                              await checkTable();
                              if (tableInUsed == true) {
                                await updateOrderDetail();
                                await updateOrderCache();
                                await updateProductStock();
                              } else {
                                await callNewOrder();
                                await updateProductStock();
                              }
                            } else {
                              await callOtherOrder();
                            }
                            if(_appSettingModel.autoPrintChecklist == true){
                              await printCheckList();
                            }
                            syncToCloudFunction();
                            widget.callBack;
                            Navigator.of(context).pop();
                            await callPrinter();
                          }
                        }
                    ),
                  ),
                ],
              );
            }
          });
        });
      });
    });
  }

  syncToCloudFunction() async {
    await syncAllToCloud();
    if (this.isLogOut == true) {
      openLogOutDialog();
      return;
    }
  }

  printCheckList() async {
    int printStatus = await PrintReceipt().printCheckList(printerList, widget.orderCacheLocalId);
    if(printStatus == 1){
      Fluttertoast.showToast(
          backgroundColor: Colors.red,
          msg: "${AppLocalizations.of(context)?.translate('printer_not_connected')}");
    } else if (printStatus == 2){
      Fluttertoast.showToast(
          backgroundColor: Colors.orangeAccent,
          msg: "${AppLocalizations.of(context)?.translate('printer_connection_timeout')}");
    }
  }

  //print qr kitchen list
  callPrinter() async {
    try {
      print("callPrinter called");
      BuildContext _context = MyApp.navigatorKey.currentContext!;
      String flushbarStatus = '';
      List<OrderDetail> returnData = await PrintReceipt().printQrKitchenList(printerList, widget.orderCacheLocalId, orderDetailList: widget.orderDetailList);
      if(returnData != null) {
        if(returnData.isNotEmpty){
          _failPrintModel.addAllFailedOrderDetail(orderDetailList: returnData);
          playSound();
          Flushbar(
            icon: Icon(Icons.error, size: 32, color: Colors.white),
            shouldIconPulse: false,
            title: "${AppLocalizations.of(_context)?.translate('error')}${AppLocalizations.of(_context)?.translate('kitchen_printer_timeout')}",
            message: "${AppLocalizations.of(_context)?.translate('please_try_again_later')}",
            duration: Duration(seconds: 5),
            backgroundColor: Colors.red,
            messageColor: Colors.white,
            flushbarPosition: FlushbarPosition.TOP,
            maxWidth: 350,
            margin: EdgeInsets.all(8),
            borderRadius: BorderRadius.circular(8),
            padding: EdgeInsets.fromLTRB(40, 20, 40, 20),
            onTap: (flushbar) {
              flushbar.dismiss(true);
            },
            onStatusChanged: (status) {
              flushbarStatus = status.toString();
            },
          )..show(_context);
          Future.delayed(Duration(seconds: 3), () {
            if(flushbarStatus != "FlushbarStatus.IS_HIDING" && flushbarStatus != "FlushbarStatus.DISMISSED")
              playSound();
          });
        }
      } else {
        Fluttertoast.showToast(
            backgroundColor: Colors.red,
            msg: "${AppLocalizations.of(_context)?.translate('no_printer_added')}");
      }
    } catch(e) {
      print("callPrinter error: ${e}");
    }

  }

  playSound() {
    try {
      final assetsAudioPlayer = AssetsAudioPlayer();
      assetsAudioPlayer.open(
        Audio("audio/review.mp3"),
      );
    } catch(e) {
      print("Play Sound Error: ${e}");
    }
  }

  callNewOrder() async {
    await createTableUseID();
    await createTableUseDetail();
    await updateOrderDetail();
    await updateOrderCache();
    await updatePosTable();
  }

  callOtherOrder() async {
    await acceptOrder(widget.orderCacheLocalId);
    await updateProductStock();
    await callPrinter();
    await syncAllToCloud();
    if (this.isLogOut == true) {
      openLogOutDialog();
      return;
    }
  }

  callRejectOrder() async {
    await rejectOrder(widget.orderCacheLocalId);
    widget.callBack;
    Navigator.of(context).pop();
  }

  updateProductStock() async {
    DateFormat dateFormat = DateFormat("yyyy-MM-dd HH:mm:ss");
    String dateTime = dateFormat.format(DateTime.now());
    List<String> _branchLinkProductValue = [];
    int _totalStockQty = 0, updateStock = 0;
    BranchLinkProduct? object;
    try{
      for (int i = 0; i < orderDetailList.length; i++) {
        List<BranchLinkProduct> checkData = await PosDatabase.instance.readSpecificBranchLinkProduct(orderDetailList[i].branch_link_product_sqlite_id!);
        if(checkData.isNotEmpty){
          switch(checkData[0].stock_type){
            case '1': {
              _totalStockQty = int.parse(checkData[0].daily_limit!) - int.parse(orderDetailList[i].quantity!);
              object = BranchLinkProduct(
                  updated_at: dateTime,
                  sync_status: 2,
                  daily_limit: _totalStockQty.toString(),
                  branch_link_product_sqlite_id: int.parse(orderDetailList[i].branch_link_product_sqlite_id!));
              updateStock = await PosDatabase.instance.updateBranchLinkProductDailyLimit(object);
            }break;
            case '2' :{
              _totalStockQty = int.parse(checkData[0].stock_quantity!) - int.parse(orderDetailList[i].quantity!);
              object = BranchLinkProduct(
                  updated_at: dateTime,
                  sync_status: 2,
                  stock_quantity: _totalStockQty.toString(),
                  branch_link_product_sqlite_id: int.parse(orderDetailList[i].branch_link_product_sqlite_id!));
              updateStock = await PosDatabase.instance.updateBranchLinkProductStock(object);
            }break;
            default: {
              updateStock = 0;
            }
          }
          if (updateStock == 1) {
            List<BranchLinkProduct> updatedData =
            await PosDatabase.instance.readSpecificBranchLinkProduct(orderDetailList[i].branch_link_product_sqlite_id!);
            _branchLinkProductValue.add(jsonEncode(updatedData[0]));
          }
        }
      }
      this.branch_link_product_value = _branchLinkProductValue.toString();
    } catch(e){
      print("update product stock in adjust stock dialog error: $e");
      branch_link_product_value = null;
    }

    //sync to cloud
    //syncBranchLinkProductStock(_branchLinkProductValue.toString());
  }

  // syncBranchLinkProductStock(String value) async {
  //   bool _hasInternetAccess = await Domain().isHostReachable();
  //   if (_hasInternetAccess) {
  //     Map orderDetailResponse = await Domain().SyncBranchLinkProductToCloud(value);
  //     if (orderDetailResponse['status'] == '1') {
  //       List responseJson = orderDetailResponse['data'];
  //       for (int i = 0; i < responseJson.length; i++) {
  //         int syncUpdated = await PosDatabase.instance.updateBranchLinkProductSyncStatusFromCloud(responseJson[i]['branch_link_product_id']);
  //       }
  //     }
  //   }
  // }

  updatePosTable() async {
    try {
      List<String> _value = [];
      DateFormat dateFormat = DateFormat("yyyy-MM-dd HH:mm:ss");
      String dateTime = dateFormat.format(DateTime.now());

      List<PosTable> result = await PosDatabase.instance.checkPosTableStatus(int.parse(widget.tableLocalId));
      if (result[0].status == 0) {
        PosTable posTableData = PosTable(
            table_sqlite_id: int.parse(widget.tableLocalId),
            table_use_detail_key: tableUseDetailKey,
            table_use_key: tableUseKey,
            status: 1,
            updated_at: dateTime);
        int data = await PosDatabase.instance.updateCartPosTableStatus(posTableData);
        if (data == 1) {
          List<PosTable> posTable = await PosDatabase.instance.readSpecificTable(posTableData.table_sqlite_id.toString());
          if (posTable[0].sync_status == 2) {
            _value.add(jsonEncode(posTable[0]));
          }
        }
      }
      this.table_value = _value.toString();
      //syncUpdatedTableToCloud(_value.toString());
    } catch (e) {
      Fluttertoast.showToast(backgroundColor: Color(0xFFFF0000), msg: AppLocalizations.of(context)!.translate('update_table_error')+" ${e}");
      print("update table error: $e");
    }
  }

  // syncUpdatedTableToCloud(String value) async {
  //   bool _hasInternetAccess = await Domain().isHostReachable();
  //   if (_hasInternetAccess) {
  //     Map data = await Domain().SyncUpdatedPosTableToCloud(value);
  //     if (data['status'] == '1') {
  //       List responseJson = data['data'];
  //       for (var i = 0; i < responseJson.length; i++) {
  //         int syncData = await PosDatabase.instance.updatePosTableSyncStatusFromCloud(responseJson[i]['table_id']);
  //       }
  //     }
  //   }
  // }

  updateOrderCache() async {
    String currentBatch = widget.currentBatch;
    List<String> _value = [];
    DateFormat dateFormat = DateFormat("yyyy-MM-dd HH:mm:ss");
    String dateTime = dateFormat.format(DateTime.now());
    OrderCache orderCache = OrderCache(
        updated_at: dateTime,
        sync_status: 2,
        order_by: 'Qr order',
        order_by_user_id: '',
        accepted: 0,
        total_amount: newSubtotal.toStringAsFixed(2),
        batch_id: tableInUsed ? this.batchNo : currentBatch,
        table_use_key: this.tableUseKey,
        table_use_sqlite_id: this.localTableUseId,
        order_cache_sqlite_id: widget.orderCacheLocalId);
    int status = await PosDatabase.instance.updateQrOrderCache(orderCache);
    if (status == 1) {
      //await acceptOrder(orderCache.order_cache_sqlite_id!);
      OrderCache updatedCache = await PosDatabase.instance.readSpecificOrderCacheByLocalId(orderCache.order_cache_sqlite_id!);
      _value.add(jsonEncode(updatedCache));
      this.order_cache_value = _value.toString();
    }
  }

  updateOrderDetail() async {
    try{
      List<String> _value = [];
      newSubtotal = 0.0;
      String dateTime = dateFormat.format(DateTime.now());
      List<OrderDetail> _orderDetail = widget.orderDetailList;
      for(int i = 0; i < _orderDetail.length; i++){
        OrderDetail orderDetailObj = OrderDetail(
            updated_at: dateTime,
            sync_status: 2,
            price: _orderDetail[i].price,
            quantity: _orderDetail[i].quantity,
            order_detail_key: _orderDetail[i].order_detail_key,
            order_detail_sqlite_id: _orderDetail[i].order_detail_sqlite_id
        );
        print('order detail${i}: ${orderDetailObj.quantity}');
        newSubtotal += double.parse(orderDetailObj.price!) * int.parse(orderDetailObj.quantity!);
        //update order detail
        int status = await PosDatabase.instance.updateOrderDetailQuantity(orderDetailObj);
        if(status == 1){
          OrderDetail data = await PosDatabase.instance.readSpecificOrderDetailByLocalId(orderDetailObj.order_detail_sqlite_id!);
          _value.add(jsonEncode(data.syncJson()));
        }
      }
      this.order_detail_value = _value.toString();
    } catch(e){
      print('qr update order detail error: ${e}');
      return;
    }
  }

  createTableUseDetail() async {
    DateFormat dateFormat = DateFormat("yyyy-MM-dd HH:mm:ss");
    String dateTime = dateFormat.format(DateTime.now());
    List<String> _value = [];
    List<PosTable> tableData = await PosDatabase.instance.readSpecificTable(widget.tableLocalId.toString());
    try {
      //create table use detail
      TableUseDetail tableUseDetailData = await PosDatabase.instance.insertSqliteTableUseDetail(TableUseDetail(
          table_use_detail_id: 0,
          table_use_detail_key: '',
          table_use_sqlite_id: localTableUseId,
          table_use_key: tableUseKey,
          table_sqlite_id: widget.tableLocalId,
          table_id: tableData[0].table_id.toString(),
          status: 0,
          sync_status: 0,
          created_at: dateTime,
          updated_at: '',
          soft_delete: ''));
      TableUseDetail updatedDetail = await insertTableUseDetailKey(tableUseDetailData, dateTime);
      _value.add(jsonEncode(updatedDetail));
      this.table_use_detail_value = _value.toString();
      //sync to cloud
      //syncTableUseDetailToCloud(_value.toString());
    } catch (e) {
      print(e);
      Fluttertoast.showToast(backgroundColor: Color(0xFFFF0000), msg: AppLocalizations.of(context)!.translate('create_table_detail_error')+" ${e}");
    }
  }

  // syncTableUseDetailToCloud(String value) async {
  //   //check is host reachable
  //   bool _hasInternetAccess = await Domain().isHostReachable();
  //   if (_hasInternetAccess) {
  //     Map response = await Domain().SyncTableUseDetailToCloud(value);
  //     if (response['status'] == '1') {
  //       List responseJson = response['data'];
  //       for (int i = 0; i < responseJson.length; i++) {
  //         int updateStatus = await PosDatabase.instance.updateTableUseDetailSyncStatusFromCloud(responseJson[i]['table_use_detail_key']);
  //       }
  //     }
  //   }
  // }

  generateTableUseDetailKey(TableUseDetail tableUseDetail) async {
    final prefs = await SharedPreferences.getInstance();
    final int? device_id = prefs.getInt('device_id');
    var bytes = tableUseDetail.created_at!.replaceAll(new RegExp(r'[^0-9]'), '') +
        tableUseDetail.table_use_detail_sqlite_id.toString() +
        device_id.toString();
    return md5.convert(utf8.encode(bytes)).toString();
  }

  insertTableUseDetailKey(TableUseDetail tableUseDetail, String dateTime) async {
    TableUseDetail? _tableUseDetailData;
    tableUseDetailKey = await generateTableUseDetailKey(tableUseDetail);
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
    return _tableUseDetailData;
  }

  createTableUseID() async {
    List<String> _value = [];
    DateFormat dateFormat = DateFormat("yyyy-MM-dd HH:mm:ss");
    String dateTime = dateFormat.format(DateTime.now());
    final prefs = await SharedPreferences.getInstance();
    final int? branch_id = prefs.getInt('branch_id');
    String? hexCode;
    localTableUseId = '';
    try {
      hexCode = await colorChecking();
      if (hexCode != null) {
        TableUse data = TableUse(
            table_use_id: 0,
            branch_id: branch_id,
            table_use_key: '',
            order_cache_key: '',
            card_color: hexCode.toString(),
            status: 0,
            sync_status: 0,
            created_at: dateTime,
            updated_at: '',
            soft_delete: '');
        //create table use data
        TableUse tableUseData = await PosDatabase.instance.insertSqliteTableUse(data);
        localTableUseId = tableUseData.table_use_sqlite_id.toString();
        TableUse _updatedTableUseData = await insertTableUseKey(tableUseData, dateTime);
        _value.add(jsonEncode(_updatedTableUseData));
        this.table_use_value = _value.toString();
        //sync tot cloud
        //await syncTableUseIdToCloud(_updatedTableUseData);
      }
    } catch (e) {
      print(e);
      Fluttertoast.showToast(backgroundColor: Color(0xFFFF0000), msg: AppLocalizations.of(context)!.translate('create_table_id_error')+" ${e}");
    }
  }

  // syncTableUseIdToCloud(TableUse updatedTableUseData) async {
  //   List<String> _value = [];
  //   //check is host reachable
  //   bool _hasInternetAccess = await Domain().isHostReachable();
  //   if (_hasInternetAccess) {
  //     _value.add(jsonEncode(updatedTableUseData));
  //     print('table use value: ${_value}');
  //     Map response = await Domain().SyncTableUseToCloud(_value.toString());
  //     if (response['status'] == '1') {
  //       List responseJson = response['data'];
  //       int syncData = await PosDatabase.instance.updateTableUseSyncStatusFromCloud(responseJson[0]['table_use_key']);
  //     }
  //   }
  // }

  generateTableUseKey(TableUse tableUse) async {
    final prefs = await SharedPreferences.getInstance();
    final int? device_id = prefs.getInt('device_id');
    var bytes = tableUse.created_at!.replaceAll(new RegExp(r'[^0-9]'), '') + tableUse.table_use_sqlite_id.toString() + device_id.toString();
    return md5.convert(utf8.encode(bytes)).toString();
  }

  insertTableUseKey(TableUse tableUse, String dateTime) async {
    TableUse? _tbUseList;
    tableUseKey = await generateTableUseKey(tableUse);
    TableUse tableUseObject =
    TableUse(table_use_key: tableUseKey, sync_status: 0, updated_at: dateTime, table_use_sqlite_id: tableUse.table_use_sqlite_id);
    int tableUseData = await PosDatabase.instance.updateTableUseUniqueKey(tableUseObject);
    if (tableUseData == 1) {
      TableUse data = await PosDatabase.instance.readSpecificTableUseIdByLocalId(tableUseObject.table_use_sqlite_id!);
      _tbUseList = data;
    }
    return _tbUseList;
  }

  colorChecking() async {
    String? hexCode;
    bool colorFound = false;
    bool found = false;
    int tempColor = 0;
    int matchColor = 0;
    int diff = 0;
    int count = 0;
    final prefs = await SharedPreferences.getInstance();
    final int? branch_id = prefs.getInt('branch_id');
    List<TableUse> data = await PosDatabase.instance.readAllTableUseId(branch_id!);

    while (colorFound == false) {
      /* change color */
      hexCode = colorToHex(randomColor());
      if (data.length > 0) {
        for (int i = 0; i < data.length; i++) {
          if (hexCode == data[i].card_color) {
            found = false;
            break;
          } else {
            tempColor = hexToInteger(hexCode!.replaceAll('#', ''));
            matchColor = hexToInteger(data[i].card_color!.replaceAll('#', ''));
            diff = tempColor - matchColor;
            if (diff.abs() < 160000) {
              print('color too close or not yet loop finish');
              print('diff: ${diff.abs()}');
              found = false;
              break;
            } else {
              print('color is ok');
              print('diff: ${diff}');
              if (i < data.length) {
                continue;
              }
            }
          }
        }
        found = true;
      } else {
        found = true;
        break;
      }
      if (found == true) colorFound = true;
    }
    return hexCode;
  }

  randomColor() {
    return Color(Random().nextInt(0xffffffff)).withAlpha(0xff);
  }

  colorToHex(Color color) {
    String hex = '#' + color.value.toRadixString(16).substring(2);
    return hex;
  }

  hexToInteger(String hexCode) {
    int temp = int.parse(hexCode, radix: 16);
    return temp;
  }

  removeOrderDetail() async {
    List<String> value = [];
    for (int i = 0; i < removeDetailList.length; i++) {
      DateFormat dateFormat = DateFormat("yyyy-MM-dd HH:mm:ss");
      String dateTime = dateFormat.format(DateTime.now());
      OrderDetail orderDetail = OrderDetail(
        updated_at: dateTime,
        sync_status: 2,
        status: 2,
        cancel_by: '',
        cancel_by_user_id: '',
        order_detail_key: removeDetailList[i].order_detail_key,
        order_detail_sqlite_id: removeDetailList[i].order_detail_sqlite_id,
      );
      int deleteOrderDetail = await PosDatabase.instance.updateOrderDetailStatus(orderDetail);
      if (deleteOrderDetail == 1) {
        OrderDetail data = await PosDatabase.instance.readSpecificOrderDetailByLocalId(orderDetail.order_detail_sqlite_id!);
        value.add(jsonEncode(data.syncJson()));
      }
    }
    this.delete_order_detail_value = value.toString();
    //syncOrderDetailToCloud(value.toString());
  }

  // syncOrderDetailToCloud(String orderDetailValue) async {
  //   bool _hasInternetAccess = await Domain().isHostReachable();
  //   if (_hasInternetAccess) {
  //     Map orderDetailResponse = await Domain().SyncOrderDetailToCloud(orderDetailValue);
  //     if (orderDetailResponse['status'] == '1') {
  //       List responseJson = orderDetailResponse['data'];
  //       for (int i = 0; i < responseJson.length; i++) {
  //         int syncUpdated = await PosDatabase.instance.updateOrderDetailSyncStatusFromCloud(responseJson[i]['order_detail_key']);
  //       }
  //     }
  //   }
  // }

  checkTable() async {
    tableInUsed = false;
    if (widget.tableLocalId != '') {
      print('widget table local id: ${widget.tableLocalId}');
      List<PosTable> tableData = await PosDatabase.instance.readSpecificTable(widget.tableLocalId);
      print('table use key: ${tableData[0].table_use_key}');
      if (tableData[0].status == 1) {
        TableUse tableUse = await PosDatabase.instance.readSpecificTableUseByKey(tableData[0].table_use_key!);
        List<OrderCache> orderCache = await PosDatabase.instance.readTableOrderCache(tableUse.table_use_key!);
        tableInUsed = true;
        batchNo = orderCache[0].batch_id!;
        this.tableUseKey = tableData[0].table_use_key!;
        this.localTableUseId = tableUse.table_use_sqlite_id.toString();
      }
    }
  }

  checkOrderDetailStock() async {
    orderDetailList = widget.orderDetailList;
    print('detail length: ${orderDetailList.length}');
    noStockOrderDetailList = [];
    hasNoStockProduct = false;
    hasNotAvailableProduct = false;
    for (int i = 0; i < orderDetailList.length; i++) {
      BranchLinkProduct? data = await PosDatabase.instance.readSpecificAvailableBranchLinkProduct(orderDetailList[i].branch_link_product_sqlite_id!);
      if(data != null){
        switch(data.stock_type){
          case '1':{
            orderDetailList[i].available_stock = data.daily_limit_amount!;
            if (int.parse(orderDetailList[i].quantity!) > int.parse(data.daily_limit_amount!)) {
              hasNoStockProduct = true;
            } else {
              hasNoStockProduct = false;
            }
          }break;
          case '2': {
            orderDetailList[i].available_stock = data.stock_quantity!;
            if (int.parse(orderDetailList[i].quantity!) > int.parse(data.stock_quantity!)) {
              hasNoStockProduct = true;
            } else {
              hasNoStockProduct = false;
            }
          }break;
          default: {
            hasNoStockProduct = false;
          }
        }
      } else {
        hasNotAvailableProduct = true;
      }
      print('has no available product status: ${hasNotAvailableProduct}');
      //orderDetailList[i].isRemove = false;
      //noStockOrderDetailList.add(orderDetailList[i]);
    }
  }

  acceptOrder(int orderCacheLocalId) async {
    List<String> _value = [];
    DateFormat dateFormat = DateFormat("yyyy-MM-dd HH:mm:ss");
    String dateTime = dateFormat.format(DateTime.now());
    final prefs = await SharedPreferences.getInstance();
    final String? pos_user = prefs.getString('pos_pin_user');
    Map userObject = json.decode(pos_user!);
    List<String> _orderCacheValue = [];
    try {
      OrderCache orderCache = OrderCache(
          soft_delete: '',
          updated_at: dateTime,
          sync_status: 2,
          order_by: userObject['name'].toString(),
          order_by_user_id: userObject['user_id'].toString(),
          accepted: 0,
          order_cache_sqlite_id: orderCacheLocalId);
      int acceptedOrderCache = await PosDatabase.instance.updateOrderCacheAccept(orderCache);
      if (acceptedOrderCache == 1) {
        OrderCache updatedCache = await PosDatabase.instance.readSpecificOrderCacheByLocalId(orderCache.order_cache_sqlite_id!);
        _value.add(jsonEncode(updatedCache));
        this.order_cache_value = _value.toString();
      }
    } catch (e) {
      print('accept order cache error: ${e}');
    }
  }

  rejectOrder(int orderCacheLocalId) async {
    List<String> _value = [];
    DateFormat dateFormat = DateFormat("yyyy-MM-dd HH:mm:ss");
    String dateTime = dateFormat.format(DateTime.now());
    final prefs = await SharedPreferences.getInstance();
    final String? pos_user = prefs.getString('pos_pin_user');
    Map userObject = json.decode(pos_user!);
    List<String> _orderCacheValue = [];
    try {
      OrderCache orderCache = OrderCache(
          soft_delete: dateTime,
          updated_at: dateTime,
          order_by: '',
          order_by_user_id: '',
          sync_status: 2,
          accepted: 2,
          order_cache_sqlite_id: orderCacheLocalId);
      int rejectOrderCache = await PosDatabase.instance.updateOrderCacheAccept(orderCache);
      OrderCache updatedCache = await PosDatabase.instance.readSpecificOrderCacheByLocalId(orderCache.order_cache_sqlite_id!);
      _value.add(jsonEncode(updatedCache));
      this.order_cache_value = _value.toString();
      //sync to cloud
      // if(deletedOrderCache == 1){
      //   OrderCache orderCacheData = await PosDatabase.instance.readSpecificOrderCacheByLocalId(orderCacheObject.order_cache_sqlite_id!);
      //   if(orderCacheData.sync_status != 1){
      //     _orderCacheValue.add(jsonEncode(orderCacheData));
      //   }
      //   Map response = await Domain().SyncOrderCacheToCloud(_orderCacheValue.toString());
      //   if(response['status'] == '1'){
      //     List responseJson = response['data'];
      //     int syncData = await PosDatabase.instance.updateOrderCacheSyncStatusFromCloud(responseJson[0]['order_cache_key']);
      //   }
      // }
      //controller.sink.add('1');
    } catch (e) {
      print(e);
      print('delete order cache error: ${e}');
    }
  }

  getOrderDetailModifier(OrderDetail orderDetail) {
    List<String> modifier = [];
    String result = '';
    if(orderDetail.orderModifierDetail.isNotEmpty){
      for (int j = 0; j < orderDetail.orderModifierDetail.length; j++) {
        modifier.add(orderDetail.orderModifierDetail[j].mod_name! + "\n");
      }
      result = modifier.toString().replaceAll('[', '').replaceAll(']', '').replaceAll(', ', '+').replaceFirst('', '+');
    }

    return result;
  }

  syncAllToCloud() async {
    try{
      if(mainSyncToCloud.count == 0){
        mainSyncToCloud.count = 1;
        final prefs = await SharedPreferences.getInstance();
        final int? device_id = prefs.getInt('device_id');
        final String? login_value = prefs.getString('login_value');
        Map data = await Domain().syncLocalUpdateToCloud(
            device_id: device_id.toString(),
            value: login_value,
            table_use_value: this.table_use_value,
            table_use_detail_value: this.table_use_detail_value,
            order_cache_value: this.order_cache_value,
            order_detail_value: this.order_detail_value,
            order_detail_delete_value: this.delete_order_detail_value,
            branch_link_product_value: this.branch_link_product_value,
            order_modifier_value: this.order_modifier_detail_value,
            table_value: this.table_value);
        if (data['status'] == '1') {
          List responseJson = data['data'];
          for (int i = 0; i < responseJson.length; i++) {
            switch (responseJson[i]['table_name']) {
              case 'tb_table_use':
                {
                  await PosDatabase.instance.updateTableUseSyncStatusFromCloud(responseJson[i]['table_use_key']);
                }
                break;
              case 'tb_table_use_detail':
                {
                  await PosDatabase.instance.updateTableUseDetailSyncStatusFromCloud(responseJson[i]['table_use_detail_key']);
                }
                break;
              case 'tb_order_cache':
                {
                  await PosDatabase.instance.updateOrderCacheSyncStatusFromCloud(responseJson[i]['order_cache_key']);
                }
                break;
              case 'tb_order_detail':
                {
                  await PosDatabase.instance.updateOrderDetailSyncStatusFromCloud(responseJson[i]['order_detail_key']);
                }
                break;
              case 'tb_order_modifier_detail':
                {
                  await PosDatabase.instance.updateOrderModifierDetailSyncStatusFromCloud(responseJson[i]['order_modifier_detail_key']);
                }
                break;
              case 'tb_branch_link_product':
                {
                  await PosDatabase.instance.updateBranchLinkProductSyncStatusFromCloud(responseJson[i]['branch_link_product_id']);
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
          print('qr sync to cloud time out');
          mainSyncToCloud.resetCount();
          throw TimeoutException("Time out");
        } else {
          mainSyncToCloud.resetCount();
        }
        // bool _hasInternetAccess = await Domain().isHostReachable();
        // if (_hasInternetAccess) {
        //
        // }
      }
    }catch(e){
      //return 1;
      mainSyncToCloud.resetCount();
    }
  }
}
