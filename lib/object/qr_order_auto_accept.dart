import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:another_flushbar/flushbar.dart';
import 'package:assets_audio_player/assets_audio_player.dart';
import 'package:f_logs/model/flog/flog.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';
import 'package:crypto/crypto.dart';
import 'package:pos_system/database/domain.dart';
import 'package:pos_system/database/pos_database.dart';
import 'package:pos_system/fragment/logout_dialog.dart';
import 'package:pos_system/main.dart';
import 'package:pos_system/notifier/fail_print_notifier.dart';
import 'package:pos_system/notifier/table_notifier.dart';
import 'package:pos_system/object/app_setting.dart';
import 'package:pos_system/object/branch_link_product.dart';
import 'package:pos_system/object/order_cache.dart';
import 'package:pos_system/object/order_detail.dart';
import 'package:pos_system/object/order_modifier_detail.dart';
import 'package:pos_system/object/print_receipt.dart';
import 'package:pos_system/object/printer.dart';
import 'package:pos_system/object/table.dart';
import 'package:pos_system/object/table_use.dart';
import 'package:pos_system/object/table_use_detail.dart';
import 'package:pos_system/translation/AppLocalizations.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class QrOrderAutoAccept {
  BuildContext context;
  QrOrderAutoAccept(this.context);
  DateFormat dateFormat = DateFormat("yyyy-MM-dd HH:mm:ss");
  List<Printer> printerList = [];
  List<OrderCache> qrOrderCacheList = [];
  List<OrderDetail> orderDetailList = [], noStockOrderDetailList = [], removeDetailList = [];
  String localTableUseId = '', tableUseKey = '', tableUseDetailKey = '', batchNo = '';
  String? table_use_value, table_use_detail_value, order_cache_value, order_detail_value,
      delete_order_detail_value, order_modifier_detail_value, table_value, branch_link_product_value;
  double newSubtotal = 0.0;
  bool hasNoStockProduct = false, hasNotAvailableProduct = false, tableInUsed = false;
  bool isButtonDisabled = false, isLogOut = false;
  bool willPop = true;
  // late TableModel tableModel;

  // late FailPrintModel _failPrintModel;

  load() async {
    final tableModel = Provider.of<TableModel>(context, listen: false);
    await readAllPrinters();
    await getAllNotAcceptedQrOrder();
    // tableModel.changeContent(true);
    await failedPrintAlert();
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
          return null!;
        });
  }

  readAllPrinters() async {
    printerList = await PrintReceipt().readAllPrinters();
  }

  syncToCloudFunction() async {
    await syncAllToCloud();
    if (this.isLogOut == true) {
      openLogOutDialog();
      return;
    }
  }

  printCheckList(int orderCacheLocalId) async {
    int printStatus = await PrintReceipt().printCheckList(printerList, orderCacheLocalId);
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

  failedPrintAlert() async {
    String flushbarStatus = '';
    final _failPrintModel = Provider.of<FailPrintModel>(context, listen: false);
    if(_failPrintModel.failedPrintOrderDetail.length >= 1) {
      playSound();
      Flushbar(
        icon: Icon(Icons.error, size: 32, color: Colors.white),
        shouldIconPulse: false,
        title: "${AppLocalizations.of(context)?.translate('error')}${AppLocalizations.of(context)?.translate('kitchen_printer_timeout')}",
        message: "${AppLocalizations.of(context)?.translate('please_try_again_later')}",
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
      )..show(context);
      Future.delayed(Duration(seconds: 3), () {
        if(flushbarStatus != "FlushbarStatus.IS_HIDING" && flushbarStatus != "FlushbarStatus.DISMISSED")
          playSound();
      });
    }
  }

  callPrinter(int orderCacheLocalId) async {
    try {
      print("callPrinter called");
      final _failPrintModel = Provider.of<FailPrintModel>(context, listen: false);
      List<OrderDetail> returnData = await PrintReceipt().printQrKitchenList(printerList, orderCacheLocalId, orderDetailList: orderDetailList);
      if(returnData.isNotEmpty){
        _failPrintModel.addAllFailedOrderDetail(orderDetailList: returnData);
      }
    } catch(e) {
      print("callPrinter error: ${e}");
    }
  }

  getAllNotAcceptedQrOrder() async {
    List<OrderCache> data = await PosDatabase.instance.readNotAcceptedQROrderCache();
    qrOrderCacheList = data;
    if (qrOrderCacheList.isNotEmpty) {
      for (int i = 0; i < qrOrderCacheList.length; i++) {
        if (qrOrderCacheList[i].qr_order_table_id != '') {
          PosTable tableData = await PosDatabase.instance.readTableByCloudId(qrOrderCacheList[i].qr_order_table_id!);
          await updateQrOrderTableLocalId(qrOrderCacheList[i].order_cache_sqlite_id!, tableData.table_sqlite_id.toString());
          qrOrderCacheList[i].qr_order_table_sqlite_id = tableData.table_sqlite_id.toString();
        } else {
          qrOrderCacheList[i].table_number = '';
        }
        await checkOrderDetail(qrOrderCacheList[i].order_cache_sqlite_id!, i);
        await autoAcceptQrOrder(qrOrderCacheList[i], orderDetailList, i);
      }
    }
    // _isLoaded = true;
    // if (!controller.isClosed) {
    //   controller.sink.add('refresh');
    // }
  }

  updateQrOrderTableLocalId(int orderCacheId, String tableLocalId) async {
    OrderCache orderCache = OrderCache(order_cache_sqlite_id: orderCacheId, qr_order_table_sqlite_id: tableLocalId);
    int data = await PosDatabase.instance.updateOrderCacheTableLocalId(orderCache);
  }

  checkOrderDetail(int orderCacheLocalId, int index) async {
    List<OrderDetail> detailData = await PosDatabase.instance.readAllOrderDetailByOrderCache(orderCacheLocalId);
    orderDetailList = detailData;
    for (int i = 0; i < orderDetailList.length; i++) {
      orderDetailList[i].tableNumber.add(qrOrderCacheList[index].table_number!);
      List<BranchLinkProduct> data = await PosDatabase.instance.readSpecificBranchLinkProduct(orderDetailList[i].branch_link_product_sqlite_id!);
      List<OrderModifierDetail> modDetailData = await PosDatabase.instance.readOrderModifierDetail(orderDetailList[i].order_detail_sqlite_id.toString());

      orderDetailList[i].orderModifierDetail = modDetailData;
      if(data.isNotEmpty){
        switch(data[0].stock_type){
          case '1': {
            orderDetailList[i].available_stock = data[0].daily_limit!;
          }break;
          case '2': {
            orderDetailList[i].available_stock = data[0].stock_quantity!;
          } break;
          default: {
            orderDetailList[i].available_stock = '';
          }
        }
      } else {
        orderDetailList[i].available_stock = '';
      }
      orderDetailList[i].isRemove = false;
    }
  }

  autoAcceptQrOrder(OrderCache qrOrderCacheList, List<OrderDetail> orderDetailList, int index) async {
    try {
      await checkOrderDetailStock();
      print('available check: ${hasNotAvailableProduct}');
      if (hasNoStockProduct) {
        Fluttertoast.showToast(backgroundColor: Colors.orangeAccent, msg: AppLocalizations.of(context)!.translate('contain_out_of_stock_product'));
      } else if(hasNotAvailableProduct){
        Fluttertoast.showToast(backgroundColor: Colors.red, msg: AppLocalizations.of(context)!.translate('contain_not_available_product'));
      } else {
        if (removeDetailList.isNotEmpty) {
          await removeOrderDetail();
        }
        if (qrOrderCacheList.qr_order_table_sqlite_id != '') {
          await checkTable(qrOrderCacheList.qr_order_table_sqlite_id!);
          if (tableInUsed == true) {
            await updateOrderDetail();
            await updateOrderCache(qrOrderCacheList.batch_id!, qrOrderCacheList.order_cache_sqlite_id!);
            await updateProductStock();
          } else {
            await callNewOrder(qrOrderCacheList);
            await updateProductStock();
          }
        } else {
          await callOtherOrder(qrOrderCacheList);
        }
        final prefs = await SharedPreferences.getInstance();
        final int? branch_id = prefs.getInt('branch_id');
        AppSetting? localSetting = await PosDatabase.instance.readLocalAppSetting(branch_id.toString());
        if(localSetting!.print_checklist == 1) {
          await printCheckList(qrOrderCacheList.order_cache_sqlite_id!);
        }
        syncToCloudFunction();
        await callPrinter(qrOrderCacheList.order_cache_sqlite_id!);
        notificationModel.setContentLoaded();
        notificationModel.setCartContentLoaded();
      }
    } catch(e) {
      print("auto accept qr order error: ${e}");
      FLog.error(
        className: "qr_order",
        text: "auto accept qr order error",
        exception: e,
      );
    }
  }

  checkOrderDetailStock() async {
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
    }
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
  }

  checkTable(String tableLocalId) async {
    tableInUsed = false;
    if (tableLocalId != '') {
      print('widget table local id: ${tableLocalId}');
      List<PosTable> tableData = await PosDatabase.instance.readSpecificTable(tableLocalId!);
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

  updateOrderDetail() async {
    try{
      List<String> _value = [];
      newSubtotal = 0.0;
      String dateTime = dateFormat.format(DateTime.now());
      List<OrderDetail> _orderDetail = orderDetailList;
      for(int i = 0; i < _orderDetail.length; i++){
        OrderDetail orderDetailObj = OrderDetail(
            updated_at: dateTime,
            sync_status: 2,
            price: _orderDetail[i].price,
            quantity: _orderDetail[i].quantity,
            order_detail_key: _orderDetail[i].order_detail_key,
            order_detail_sqlite_id: _orderDetail[i].order_detail_sqlite_id
        );
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

  updateOrderCache(String currentBatch, int order_cache_sqlite_id) async {
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
        order_cache_sqlite_id: order_cache_sqlite_id);
    int status = await PosDatabase.instance.updateQrOrderCache(orderCache);
    if (status == 1) {
      OrderCache updatedCache = await PosDatabase.instance.readSpecificOrderCacheByLocalId(orderCache.order_cache_sqlite_id!);
      _value.add(jsonEncode(updatedCache));
      this.order_cache_value = _value.toString();
    }
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

  callNewOrder(OrderCache qrOrderCacheList) async {
    await createTableUseID();
    await createTableUseDetail(qrOrderCacheList.qr_order_table_sqlite_id!);
    await updateOrderDetail();
    await updateOrderCache(qrOrderCacheList.batch_id!, qrOrderCacheList.order_cache_sqlite_id!);
    await updatePosTable(qrOrderCacheList.qr_order_table_sqlite_id!);
  }

  callOtherOrder(OrderCache qrOrderCacheList) async {
    await acceptOrder(qrOrderCacheList.order_cache_sqlite_id!);
    await updateProductStock();
    await callPrinter(qrOrderCacheList.order_cache_sqlite_id!);
    await syncAllToCloud();
    if (this.isLogOut == true) {
      openLogOutDialog();
      return;
    }
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
      Fluttertoast.showToast(backgroundColor: Color(0xFFFF0000), msg: AppLocalizations.of(context)!.translate('create_table_id_error')+" ${e}");
      print("create table id error: $e");
    }
  }

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

  createTableUseDetail(String tableLocalId) async {
    DateFormat dateFormat = DateFormat("yyyy-MM-dd HH:mm:ss");
    String dateTime = dateFormat.format(DateTime.now());
    List<String> _value = [];
    List<PosTable> tableData = await PosDatabase.instance.readSpecificTable(tableLocalId);
    try {
      //create table use detail
      TableUseDetail tableUseDetailData = await PosDatabase.instance.insertSqliteTableUseDetail(TableUseDetail(
          table_use_detail_id: 0,
          table_use_detail_key: '',
          table_use_sqlite_id: localTableUseId,
          table_use_key: tableUseKey,
          table_sqlite_id: tableLocalId,
          table_id: tableData[0].table_id.toString(),
          status: 0,
          sync_status: 0,
          created_at: dateTime,
          updated_at: '',
          soft_delete: ''));
      TableUseDetail updatedDetail = await insertTableUseDetailKey(tableUseDetailData, dateTime);
      _value.add(jsonEncode(updatedDetail));
      this.table_use_detail_value = _value.toString();
    } catch (e) {
      print("create_table_detail_error: $e");
      Fluttertoast.showToast(backgroundColor: Color(0xFFFF0000), msg: AppLocalizations.of(context)!.translate('create_table_detail_error')+" ${e}");
    }
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

  updatePosTable(String tableLocalId) async {
    try {
      List<String> _value = [];
      DateFormat dateFormat = DateFormat("yyyy-MM-dd HH:mm:ss");
      String dateTime = dateFormat.format(DateTime.now());

      List<PosTable> result = await PosDatabase.instance.checkPosTableStatus(int.parse(tableLocalId));
      if (result[0].status == 0) {
        PosTable posTableData = PosTable(
            table_sqlite_id: int.parse(tableLocalId),
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
    } catch (e) {
      Fluttertoast.showToast(backgroundColor: Color(0xFFFF0000), msg: AppLocalizations.of(context)!.translate('update_table_error')+" ${e}");
      print("update table error: $e");
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
      }
    }catch(e){
      mainSyncToCloud.resetCount();
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Placeholder();
  }
}
