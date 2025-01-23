import 'dart:convert';

import 'package:intl/intl.dart';
import 'package:pos_system/database/pos_database.dart';
import 'package:pos_system/notifier/table_notifier.dart';
import 'package:pos_system/object/branch.dart';
import 'package:pos_system/object/order.dart';
import 'package:pos_system/object/promotion.dart';
import 'package:pos_system/object/table.dart';
import 'package:pos_system/object/table_use.dart';
import 'package:pos_system/object/tax_link_dining.dart';
import 'package:pos_system/second_device/table_function.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:crypto/crypto.dart';
import 'package:sqflite/sqflite.dart';

import '../../firebase_sync/qr_order_sync.dart';
import '../../fragment/payment/ipay_api.dart';
import '../../object/app_setting.dart';
import '../../object/branch_link_promotion.dart';
import '../../object/branch_link_tax.dart';
import '../../object/cash_record.dart';
import '../../object/order_cache.dart';
import '../../object/order_promotion_detail.dart';
import '../../object/order_tax_detail.dart';
import '../../object/table_use_detail.dart';
import '../../utils/Utils.dart';


class PaymentFunction {
  final DateFormat _dateFormat = DateFormat("yyyy-MM-dd HH:mm:ss");
  final PosDatabase _posDatabase = PosDatabase.instance;
  Order _order = Order();
  TableFunction _tableFunction = TableFunction();
  List<Promotion> _promotionList = [];
  List<TaxLinkDining> _taxLinkDiningList = [];
  List<OrderCache> _orderCacheList = [];
  List<PosTable> _selectedTableList = [];
  String? _ipayResultCode;
  int? _user_id;
  late final String _currentDateTime;

  String? get ipayResultCode => _ipayResultCode;

  PaymentFunction({
    Order? order,
    List<Promotion>? promotion,
    List<TaxLinkDining>? taxLinkDining,
    List<OrderCache>? orderCache,
    List<PosTable>? tableList,
    String? ipayResultCode,
    int? user_id
  }) {
    _order = order ?? _order;
    _promotionList = promotion ?? _promotionList;
    _taxLinkDiningList = taxLinkDining ?? _taxLinkDiningList;
    _orderCacheList = orderCache ?? _orderCacheList;
    _selectedTableList = tableList ?? _selectedTableList;
    _ipayResultCode = ipayResultCode ?? _ipayResultCode;
    _currentDateTime = _dateFormat.format(DateTime.now());
    _user_id = user_id ?? _user_id;
  }

  getCompanyPaymentMethod() async {
    return await _posDatabase.readPaymentMethods();
  }

  IsOrderCachePaid() async {
    var db = await _posDatabase.database;
    return await db.transaction((txn) async {
      for(var orderCache in _orderCacheList){
        OrderCache? data = await _readSpecificOrderCachePaymentStatus(txn, orderCache.order_cache_sqlite_id!.toString());
        if (data != null && data.payment_status != 0) {
          return true; // Found a non-zero payment_status, return true immediately
        }
      }
      return false;
    });
  }

  Future<Map<String, dynamic>?> ipayMakePayment() async {
    try{
      Map<String, dynamic> apiRes = await _paymentApi();
      if (apiRes['status'] == '1') {
        print("ipay trans id: ${apiRes['data']}");
        // await callCreateOrder(finalAmount, ipayTransId: apiRes['data']);
        //live data part
        // Branch? data = await PosDatabase.instance.readLocalBranch();
        // if(data != null && data.allow_livedata == 1){
        //   if(!isSyncing){
        //     isSyncing = true;
        //     do{
        //       await syncToCloud.syncAllToCloud(isManualSync: true);
        //     }while(syncToCloud.emptyResponse == false);
        //     if(syncToCloud.emptyResponse == true){
        //       isSyncing = false;
        //     }
        //   }
        // }
        return await makePayment(ipayTransId: apiRes['data']);
      } else {
        // print("API error res: ${apiRes['data']}");
        return {'status': '2', 'action': '19', 'error': apiRes['data']};
      }
    }catch(e, s){
      print("ipay make payment error: $e, $s");
      rethrow;
    }
  }

  _paymentApi() async {
    final prefs = await SharedPreferences.getInstance();
    final String? branch = prefs.getString('branch');
    Map<String, dynamic> branchObject = json.decode(branch!);
    Branch branchData = Branch.fromJson(branchObject);
    String refKey = branchData.branch_id.toString() + DateFormat('yyyyMMddHHmmss').format(DateTime.now());
    try{
      var response = await Api().sendPayment(
        branchData.ipay_merchant_code!,
        // branchObject['ipay_merchant_code'],
        branchData.ipay_merchant_key!,
        // branchObject['ipay_merchant_key'],
        336,
        refKey,
        Utils.formatPaymentAmount(double.parse(_order.final_amount!)),
        'MYR',
        'ipay',
        branchObject['name'],
        branchObject['email'],
        branchObject['phone'],
        'remark',
        _ipayResultCode!,
        '',
        '',
        '',
        '',
        _signature256(
            branchObject['ipay_merchant_key'],
            branchObject['ipay_merchant_code'],
            refKey,
            _order.final_amount,
            //need to change to finalAmount
            'MYR',
            '',
            _ipayResultCode!,
            ''),
      );
      return response;
    }catch(e, s){
      print("ipay paymentApi error: $e, $s");
      rethrow;
      // assetsAudioPlayer.open(
      //   Audio("audio/error_sound.mp3"),
      // );
      // FLog.error(
      //   className: "make_payment_dialog",
      //   text: "paymentApi error",
      //   exception: "$e",
      // );
      return {
        'status': '0',
        'data': e
      };
    }
  }

  _signature256(var merchant_key, var merchant_code, var refNo, var amount, var currency, var xFields, var barcodeNo, var TerminalId) {
    var ipayAmount = double.parse(amount) * 100;
    print("ipay amount: ${ipayAmount.toStringAsFixed(0)}");
    var signature = utf8.encode(merchant_key +
        merchant_code +
        refNo +
        ipayAmount.toStringAsFixed(0) +
        currency +
        xFields +
        barcodeNo +
        TerminalId);
    String value = sha256.convert(signature).toString();
    return value;
  }

  Future<Map<String, dynamic>?> makePayment({String? ipayTransId}) async {
    try{
      var db = await _posDatabase.database;
      await db.transaction((txn) async {
        await _createOrder(txn, ipayTransId: ipayTransId);
        await _createOrderPromotionDetail(txn);
        await _crateOrderTaxDetail(txn);
        await _updateOrderCache(txn);
        await _createCashRecord(txn);
        if (_selectedTableList.isNotEmpty) {
          List<String> uniqueTableUseSqliteId = _getUniqueTableUseSqliteId();
          await _updateTableUseDetailAndTableUse(txn, uniqueTableUseSqliteId);
          await _updatePosTableStatus(txn);
          TableModel.instance.changeContent(true);
          _tableFunction.clearSubPosOrderCache();
        }
      });
      return {'status': '1', 'action': '19'};
    }catch(e, s){
      print("stack trace: $s");
      return {'status': '2', 'action': '19', 'error': e};
    }
  }

  _updatePosTableStatus(Transaction txn) async {
    try{
      List<String> _value = [];
      if (_selectedTableList.isNotEmpty) {
        print("selected table length: ${_selectedTableList.length}");
        for (var posTable in _selectedTableList) {
          PosTable posTableData = posTable.copy(
              table_use_detail_key: '',
              table_use_key: '',
              status: 0,
              sync_status: 2,
              updated_at: _currentDateTime,
              table_sqlite_id: posTable.table_sqlite_id);
          int status = await _resetPosTableStatus(txn, posTableData);
          if (status == 1) {
            // List<PosTable> posTable = await PosDatabase.instance
            //     .readSpecificTable(posTableData.table_sqlite_id.toString());
            // if (posTable[0].sync_status == 2) {
            //   _value.add(jsonEncode(posTable[0]));
            // }
          }
        }
        // table_value = _value.toString();
        //sync to cloud
        //syncUpdatedPosTableToCloud(_value.toString());
      }
    }catch(e, s){
      print("payment success update table error $e, $s");
      rethrow;
    }
  }

  _updateTableUseDetailAndTableUse(Transaction txn, List<String> uniqueTableUseSqliteId) async {
    List<String> _value = [];
    try {
      for (var tableUseSqliteId in uniqueTableUseSqliteId) {
        List<TableUseDetail> tableUseDetail = await _readAllInUsedTableUseDetail(txn, tableUseSqliteId);
        for(var detail in tableUseDetail){
          TableUseDetail data = detail.copy(
              updated_at: _currentDateTime,
              sync_status: detail.sync_status == 0 ? 0 : 2,
              status: 1,
              table_use_sqlite_id: tableUseSqliteId
           );
          int status = await _updateTableUseDetailStatus(txn, data);
        }
       await _updateCurrentTableUseStatus(txn, tableUseSqliteId);
      }
      // table_use_detail_value = _value.toString();
      //sync to cloud
      //syncTableUseDetailToCloud(_value.toString());
    } catch (e, s) {
      print('_updateTableUseDetailAndTableUse error: $e, $s');
      rethrow;
      // Fluttertoast.showToast(
      //     backgroundColor: Color(0xFFFF0000),
      //     msg: AppLocalizations.of(context)!
      //         .translate('delete_current_table_use_detail_error') +
      //         " $e");
    }
  }

  _updateCurrentTableUseStatus(Transaction txn, String tableUseSqliteId) async {
    List<String> _value = [];
    try {
      TableUse? tableUseData = await _readSpecificTableUse(txn, tableUseSqliteId);
      if(tableUseData != null){
        TableUse data = tableUseData.copy(
          updated_at: _currentDateTime,
          sync_status: tableUseData.sync_status == 0 ? 0 : 2,
          status: 1,
          table_use_sqlite_id: int.parse(tableUseSqliteId),
        );
        int status = await _updateTableUseStatus(txn, data);
        if (status == 1) {
          // TableUse tableUseData = await PosDatabase.instance
          //     .readSpecificTableUseIdByLocalId(
          //     tableUseObject.table_use_sqlite_id!);
          // _value.add(jsonEncode(tableUseData));
        }
        //sync to cloud
        //syncUpdatedTableUseIdToCloud(_value.toString());
      }
    } catch (e, s) {
      print('_updateCurrentTableUseStatus error: $e, $s');
      rethrow;
      // Fluttertoast.showToast(
      //     backgroundColor: Color(0xFFFF0000),
      //     msg: AppLocalizations.of(context)!
      //         .translate('delete_current_table_use_id_error') +
      //         " ${e}");
    }
  }

  List<String> _getUniqueTableUseSqliteId() {
    return _orderCacheList
        .map((orderCache) => orderCache.table_use_sqlite_id!) // Extract table_use_key values
        .toSet() // Convert to Set to remove duplicates
        .toList(); // Convert back to List
  }

  _createCashRecord(Transaction txn) async {
    try {
      List<String> _value = [];
      final prefs = await SharedPreferences.getInstance();
      final int? branch_id = prefs.getInt('branch_id');
      final String? pos_user = prefs.getString('pos_pin_user');
      final String? login_user = prefs.getString('user');
      Map userObject = json.decode(pos_user!);
      Map logInUser = json.decode(login_user!);
      // normal payment
      // List<Order> orderData = await PosDatabase.instance.readSpecificPaidOrder(widget.orderId);
      if(_order.payment_link_company_id != '0') {
        CashRecord cashRecordObject = CashRecord(
            cash_record_id: 0,
            cash_record_key: '',
            company_id: logInUser['company_id'].toString(),
            branch_id: branch_id.toString(),
            remark: _order.generateOrderNumber(),
            amount: _order.final_amount,
            payment_name: '',
            payment_type_id: _order.payment_type_id!,
            type: 3,
            user_id: _user_id!.toString(),
            settlement_key: '',
            settlement_date: '',
            sync_status: 0,
            created_at: _currentDateTime,
            updated_at: '',
            soft_delete: '');
        CashRecord data = await _insertSqliteCashRecord(txn, cashRecordObject);
        CashRecord updatedData = await _insertCashRecordKey(txn, data);
        _value.add(jsonEncode(updatedData));
        // cash_record_value = _value.toString();
      } else {
        //split payment
        // List<Order> splitOrderData = await PosDatabase.instance.readSpecificPaidSplitPaymentOrder(widget.orderId);
        // CashRecord cashRecordObject = CashRecord(
        //     cash_record_id: 0,
        //     cash_record_key: '',
        //     company_id: logInUser['company_id'].toString(),
        //     branch_id: branch_id.toString(),
        //     remark: splitOrderData[0].generateOrderNumber(),
        //     amount: splitOrderData[0].amountSplit,
        //     payment_name: '',
        //     payment_type_id: splitOrderData[0].payment_type,
        //     type: 3,
        //     user_id: userObject['user_id'].toString(),
        //     settlement_key: '',
        //     settlement_date: '',
        //     sync_status: 0,
        //     created_at: dateTime,
        //     updated_at: '',
        //     soft_delete: '');
        // CashRecord data = await PosDatabase.instance.insertSqliteCashRecord(cashRecordObject);
        // CashRecord updatedData = await insertCashRecordKey(data, dateTime);
        // _value.add(jsonEncode(updatedData));
        // cash_record_value = _value.toString();
      }

      //sync to cloud
      //syncCashRecordToCloud(updatedData);
    } catch (e, s) {
      print("createCashRecord error: $e, $s");
      rethrow;
      // Fluttertoast.showToast(
      //     backgroundColor: Color(0xFFFF0000),
      //     msg: AppLocalizations.of(context)!
      //         .translate('create_cash_record_error'));
    }
  }

  _updateOrderCache(Transaction txn) async {
    print("server action updateOrderCache");
    List<String> _value = [];
    final inPaymentOrderCache = TableModel.instance.inPaymentOrderCache;
    if (_orderCacheList.isNotEmpty) {
      for (var orderCache in _orderCacheList) {
        if(inPaymentOrderCache != null && orderCache.order_cache_sqlite_id == inPaymentOrderCache.order_cache_sqlite_id){
          throw 'Order is in payment';
        }
        OrderCache? data = await _readSpecificOrderCache(txn, orderCache.order_cache_sqlite_id!.toString());
        OrderCache cacheObject = orderCache.copy(
            order_sqlite_id: _order.order_sqlite_id!.toString(),
            order_key: _order.order_key,
            sync_status: data!.sync_status! == 0 ? 0 : 2,
            updated_at: _currentDateTime,
            order_cache_key: orderCache.order_cache_key!,
            order_cache_sqlite_id: orderCache.order_cache_sqlite_id!,
            payment_status: 1
        );
        int updatedOrderCache = await _updateOrderCachePaymentStatus(txn, cacheObject);
        //update to firestore
        // FirestoreQROrderSync.instance.updateOrderCachePaymentStatus(cacheObject);
        if (updatedOrderCache == 1) {
          // OrderCache orderCacheData = await PosDatabase.instance.readSpecificOrderCacheByLocalId2(cacheObject.order_cache_sqlite_id!);
          // _value.add(jsonEncode(orderCacheData));
        }
      }
      // order_cache_value = _value.toString();
      //sync to cloud
      //syncUpdatedOrderCacheToCloud(_value.toString());
    }
  }

  _crateOrderTaxDetail(Transaction txn) async {
    List<String> _value = [];
    for (var tax in _taxLinkDiningList) {
      List<BranchLinkTax> branchTaxData = await _readSpecificBranchLinkTax(txn, tax.tax_id!);
      if (branchTaxData.isNotEmpty) {
        var orderTaxDetail = OrderTaxDetail(
            order_tax_detail_id: 0,
            order_tax_detail_key: '',
            order_sqlite_id: _order.order_sqlite_id!.toString(),
            order_id: '0',
            order_key: _order.order_key!,
            tax_name: tax.tax_name,
            type: tax.tax_type,
            rate: tax.tax_rate,
            tax_id: tax.tax_id,
            branch_link_tax_id: branchTaxData.first.branch_link_tax_id.toString(),
            tax_amount: tax.tax_amount!,
            sync_status: 0,
            created_at: _currentDateTime,
            updated_at: '',
            soft_delete: '');
        OrderTaxDetail data = await _insertSqliteOrderTaxDetail(txn, orderTaxDetail);
        OrderTaxDetail returnData = await _insertOrderTaxDetailKey(txn, data);
        _value.add(jsonEncode(returnData));
      }
    }
    // order_tax_value = _value.toString();
  }

  _createOrderPromotionDetail(Transaction txn) async {
    List<String> _value = [];
    try{
      for (var promotion in _promotionList) {
        BranchLinkPromotion? branchPromotionData = await _readSpecificBranchLinkPromotion(txn, promotion.promotion_id.toString());
        var insertData = OrderPromotionDetail(
            order_promotion_detail_id: 0,
            order_promotion_detail_key: '',
            order_sqlite_id: _order.order_sqlite_id!.toString(),
            order_id: '0',
            order_key: _order.order_key!,
            promotion_name: promotion.name,
            promotion_id: promotion.promotion_id.toString(),
            rate: promotion.promoRate,
            promotion_amount: promotion.promoAmount!.toStringAsFixed(2),
            promotion_type: promotion.type,
            branch_link_promotion_id: branchPromotionData != null ? branchPromotionData.branch_link_promotion_id.toString() : '',
            auto_apply: promotion.auto_apply!,
            sync_status: 0,
            created_at: _currentDateTime,
            updated_at: '',
            soft_delete: '');
        OrderPromotionDetail data = await _insertSqliteOrderPromotionDetail(txn ,insertData);
        OrderPromotionDetail? returnData = await _insertOrderPromotionDetailKey(txn, data);
        _value.add(jsonEncode(returnData));
      }
      // order_promotion_value = _value.toString();
    }catch(e, s){
      print("_createOrderPromotionDetail error:${e}, $s");
      rethrow;
    }
  }

  _createOrder(Transaction txn, {String? ipayTransId}) async {
    print('create order called');
    List<String> _value = [];
    final prefs = await SharedPreferences.getInstance();
    final String? login_user = prefs.getString('user');
    final int? branch_id = prefs.getInt('branch_id');
    AppSetting? localSetting = await _readLocalAppSetting(txn);
    Map logInUser = json.decode(login_user!);
    int orderNum = await _generateOrderNumber(txn);
    //temp hide order queue
    int orderQueue = localSetting!.enable_numbering == 1 ? await _readQueueFromOrderCache(txn) : 0;
    try {
      if (orderNum != 0) {
        Order orderObject = _order.copy(
            order_id: 0,
            order_number: orderNum.toString().padLeft(5, '0'),
            order_queue: localSetting.enable_numbering == 1 && orderQueue != -1 ? orderQueue.toString().padLeft(4, '0') : '',
            company_id: logInUser['company_id'].toString(),
            branch_id: branch_id.toString(),
            customer_id: '',
            branch_link_promotion_id: '',
            branch_link_tax_id: '',
            payment_status: 1,
            order_key: '',
            refund_sqlite_id: '',
            refund_key: '',
            settlement_sqlite_id: '',
            settlement_key: '',
            ipay_trans_id: ipayTransId ?? '',
            sync_status: 0,
            created_at: _currentDateTime,
            updated_at: '',
            soft_delete: '');
        Order data = await _insertSqliteOrder(txn, orderObject);
         await _insertOrderKey(txn, data);
        // _value.add(jsonEncode(updatedOrder));
        // order_value = _value.toString();
        //await syncOrderToCloud(updatedOrder);
      }
    } catch (e, s) {
      print('create order error: $e, $s');
      rethrow;
      // Fluttertoast.showToast(
      //     backgroundColor: Color(0xFFFF0000),
      //     msg: AppLocalizations.of(context)!.translate('create_order_error') +
      //         " ${e}");
      // FLog.error(
      //   className: "make_payment_dialog",
      //   text: "Create order failed",
      //   exception: "$e\norderNum: $orderNum",
      // );
    }
  }

  Future<int> _readQueueFromOrderCache(Transaction txn) async {
    try {
      OrderCache? orderCache = await _readSpecificOrderCache(txn, _orderCacheList.first.order_cache_sqlite_id!.toString());
      int orderQueue = 0;
      orderQueue = orderCache!.order_queue! != '' ? int.parse(orderCache.order_queue!) : -1;
      return orderQueue;
    } catch(e, s) {
      print("readQueueFromOrderCache error: $e, $s");
    }
    return -1;
  }

  Future<int> _generateOrderNumber(Transaction txn) async {
    Order? data = await _readLatestOrder(txn);
    return data != null ? int.parse(data.order_number!) + 1 : 1;
  }

  _insertCashRecordKey(Transaction txn, CashRecord cashRecord) async {
    CashRecord? _record;
    try{
      String? _key = await _generateCashRecordKey(cashRecord);
      if (_key != null) {
        CashRecord cashRecordObject = cashRecord.copy(
            cash_record_key: _key,
            updated_at: _currentDateTime,
            cash_record_sqlite_id: cashRecord.cash_record_sqlite_id);
        int data = await _updateCashRecordUniqueKey(txn, cashRecordObject);
        if (data == 1) {
          _record = cashRecordObject;
          // _record = await PosDatabase.instance
          //     .readSpecificCashRecord(cashRecord.cash_record_sqlite_id!);
        }
      }
      return _record;
    }catch(e, s){
      print("_insertCashRecordKey error: $e, $s");
      rethrow;
    }
  }

  _insertOrderTaxDetailKey(Transaction txn, OrderTaxDetail orderTaxDetail) async {
    String? _key;
    OrderTaxDetail? _data;
    _key = await _generateOrderTaxDetailKey(orderTaxDetail);
    if (_key != null) {
      OrderTaxDetail orderTaxDetailObject = orderTaxDetail.copy(
          order_tax_detail_key: _key,
          sync_status: 0,
          updated_at: _currentDateTime,
          order_tax_detail_sqlite_id:
          orderTaxDetail.order_tax_detail_sqlite_id);
      int updatedData = await _updateOrderTaxDetailUniqueKey(txn, orderTaxDetailObject);
      if (updatedData == 1) {
        _data = orderTaxDetailObject;
      }
    }
    return _data;
  }

  Future<OrderPromotionDetail?> _insertOrderPromotionDetailKey(Transaction txn, OrderPromotionDetail orderPromotionDetail) async {
    String _key = await _generateOrderPromotionDetailKey(orderPromotionDetail);
    OrderPromotionDetail orderPromoDetailObject = orderPromotionDetail.copy(
        order_promotion_detail_key: _key,
        sync_status: 0,
        updated_at: _currentDateTime,
        order_promotion_detail_sqlite_id: orderPromotionDetail.order_promotion_detail_sqlite_id);
    int updatedData = await _updateOrderPromotionDetailUniqueKey(txn, orderPromoDetailObject);
    if (updatedData == 1) {
      return orderPromoDetailObject;
      // OrderPromotionDetail orderPromotionDetailData = await PosDatabase
      //     .instance
      //     .readSpecificOrderPromotionDetailByLocalId(
      //     orderPromoDetailObject.order_promotion_detail_sqlite_id!);
      // _data = orderPromotionDetailData;
    }
    return null;
  }

  _insertOrderKey(Transaction txn, Order order) async {
    List<String> _value = [];
    Order? _updatedOrder;
    try{
      var orderKey = await _generateOrderKey(order);
      if (orderKey != null) {
        _order = order.copy(
            order_key: orderKey,
            sync_status: 0,
            updated_at: _currentDateTime,
            order_sqlite_id: _order.order_sqlite_id);
        int updatedData = await _updateOrderUniqueKey(txn, _order);
        if (updatedData == 1) {
          // Order orderData = await PosDatabase.instance.readSpecificOrder(orderObject.order_sqlite_id!);
          // _updatedOrder = orderData;
          //_value.add(jsonEncode(orderData));
        }
      }
      return _updatedOrder;
    }catch(e, s){
      print("insertOrderKey error: $e, $s");
      rethrow;
    }
  }

  _generateCashRecordKey(CashRecord cashRecord) async {
    final prefs = await SharedPreferences.getInstance();
    final int? device_id = prefs.getInt('device_id');
    var bytes = cashRecord.created_at!.replaceAll(new RegExp(r'[^0-9]'), '') +
        cashRecord.cash_record_sqlite_id.toString() +
        device_id.toString();
    var md5Hash = md5.convert(utf8.encode(bytes));
    return Utils.shortHashString(hashCode: md5Hash);
  }

  _generateOrderTaxDetailKey(OrderTaxDetail orderTaxDetail) async {
    final prefs = await SharedPreferences.getInstance();
    final int? device_id = prefs.getInt('device_id');
    var bytes =
        orderTaxDetail.created_at!.replaceAll(new RegExp(r'[^0-9]'), '') +
            orderTaxDetail.order_tax_detail_sqlite_id.toString() +
            device_id.toString();
    var md5Hash = md5.convert(utf8.encode(bytes));
    return Utils.shortHashString(hashCode: md5Hash);
  }

  Future<String> _generateOrderPromotionDetailKey(OrderPromotionDetail orderPromotionDetail) async {
    final prefs = await SharedPreferences.getInstance();
    final int? device_id = prefs.getInt('device_id');
    var bytes =
        orderPromotionDetail.created_at!.replaceAll(new RegExp(r'[^0-9]'), '') +
            orderPromotionDetail.order_promotion_detail_sqlite_id.toString() +
            device_id.toString();
    var md5Hash = md5.convert(utf8.encode(bytes));
    return Utils.shortHashString(hashCode: md5Hash);
  }

  _generateOrderKey(Order order) async {
    final prefs = await SharedPreferences.getInstance();
    final int? device_id = prefs.getInt('device_id');
    var bytes = order.created_at!.replaceAll(new RegExp(r'[^0-9]'), '') +
        order.order_sqlite_id!.toString() +
        device_id.toString();
    var md5Hash = md5.convert(utf8.encode(bytes));
    return Utils.shortHashString(hashCode: md5Hash);
  }

/*
---------------------------CREATE QUERY--------------------------------------------
*/

/*
  add cash record data into local db
*/
  Future<CashRecord> _insertSqliteCashRecord(Transaction txn, CashRecord data) async {
    final id = await txn.insert(tableCashRecord!, data.toJson());
    return data.copy(cash_record_sqlite_id: id);
  }

/*
  add order tax detail
*/
  Future<OrderTaxDetail> _insertSqliteOrderTaxDetail(Transaction txn, OrderTaxDetail data) async {
    final id = await txn.insert(tableOrderTaxDetail!, data.toJson());
    return data.copy(order_tax_detail_sqlite_id: id);
  }

/*
  add order promotion detail
*/
  Future<OrderPromotionDetail> _insertSqliteOrderPromotionDetail(Transaction txn, OrderPromotionDetail data) async {
    final id = await txn.insert(tableOrderPromotionDetail!, data.toJson());
    return data.copy(order_promotion_detail_sqlite_id: id);
  }

/*
  crate order into local(from local)
*/
  Future<Order> _insertSqliteOrder(Transaction txn, Order data) async {
    final result = await txn.rawQuery('SELECT created_at FROM $tableOrder WHERE soft_delete = ? AND created_at = ?',
        ['', data.created_at]);
    if(result.isEmpty){
      final id = await txn.insert(tableOrder!, data.toInsertJson());
      return data.copy(order_sqlite_id: id);
    } else {
      throw 'Duplicated payment';
    }
  }

/*
---------------------------READ QUERY--------------------------------------------
*/

/*
  read order cache payment status
*/
  Future<OrderCache?> _readSpecificOrderCachePaymentStatus(Transaction txn, String order_cache_sqlite_id) async {
    final result = await txn.rawQuery('SELECT payment_status FROM $tableOrderCache '
        'WHERE soft_delete = ? AND order_cache_sqlite_id = ?',
        ['', order_cache_sqlite_id]);
    if(result.isNotEmpty){
      return OrderCache.fromJson(result.first);
    } else {
      return null;
    }
  }

/*
  read Specific table use by table use local id
*/
  Future<TableUse?> _readSpecificTableUse(Transaction txn, String table_use_sqlite_id) async {
    final result = await txn.rawQuery('SELECT * FROM $tableTableUse WHERE table_use_sqlite_id = ? AND status = ? ', [table_use_sqlite_id, 0]);
    if(result.isNotEmpty){
      return TableUse.fromJson(result.first);
    } else {
      return null;
    }
  }

/*
  read all occurrence table detail based on table use key
*/
  Future<List<TableUseDetail>> _readAllInUsedTableUseDetail(Transaction txn, String table_use_sqlite_id) async {
    final result = await txn.rawQuery('SELECT * FROM $tableTableUseDetail '
        'WHERE soft_delete = ? AND status = ? AND table_use_sqlite_id = ?',
        ['', 0, table_use_sqlite_id]);

    return result.map((json) => TableUseDetail.fromJson(json)).toList();
  }

/*
  read specific order cache
*/
  Future<OrderCache?> _readSpecificOrderCache(Transaction txn, String order_cache_sqlite_id) async {
    final result = await txn.rawQuery('SELECT * FROM $tableOrderCache '
        'WHERE soft_delete = ? AND accepted = ? AND cancel_by = ? AND order_cache_sqlite_id = ?',
        ['', 0, '', order_cache_sqlite_id]);
    return OrderCache.fromJson(result.first);
  }

/*
  read specific branch link tax
*/
  Future<List<BranchLinkTax>> _readSpecificBranchLinkTax(Transaction txn, String tax_id) async {
    final result = await txn.rawQuery('SELECT * FROM $tableBranchLinkTax WHERE soft_delete = ? AND tax_id = ?', ['', tax_id]);
    return result.map((json) => BranchLinkTax.fromJson(json)).toList();
  }

/*
  read specific branch link promotion
*/
  Future<BranchLinkPromotion?> _readSpecificBranchLinkPromotion(Transaction txn, String promotion_id) async {
    final result = await txn.rawQuery('SELECT * FROM $tableBranchLinkPromotion WHERE soft_delete = ? AND promotion_id = ?', ['', promotion_id]);
    if(result.isNotEmpty){
      return BranchLinkPromotion.fromJson(result.first);
    }
    return null;
  }


/*
  read local app setting
 */
  Future<AppSetting?> _readLocalAppSetting(Transaction txn) async {
    final result = await txn.rawQuery('SELECT * FROM $tableAppSetting');
    if (result.isNotEmpty) {
      return AppSetting.fromJson(result.first);
    } else {
      return null;
    }
  }

/*
  read all order created order(for generate order number use)
*/
  Future<Order?> _readLatestOrder(Transaction txn) async {
    final result = await txn.rawQuery('SELECT * FROM $tableOrder WHERE created_at != ? ORDER BY order_sqlite_id DESC LIMIT 1', ['']);
    if(result.isNotEmpty){
      return Order.fromJson(result.first);
    }
    return null;
  }

/*
---------------------------UPDATE QUERY--------------------------------------------
*/

/*
  reset Pos Table status
*/
  Future<int> _resetPosTableStatus(Transaction txn, PosTable data) async {
    return await txn.rawUpdate('UPDATE $tablePosTable '
        'SET table_use_detail_key = ?, table_use_key = ?, sync_status = ?, status = ?, updated_at = ? '
        'WHERE table_sqlite_id = ?',
        [data.table_use_detail_key, data.table_use_key, data.sync_status, data.status, data.updated_at, data.table_sqlite_id]);
  }

/*
  Soft-delete table use id
*/
  Future<int> _updateTableUseStatus(Transaction txn, TableUse data) async {
    return await txn.rawUpdate(
        'UPDATE $tableTableUse SET updated_at = ?, status = ?, sync_status = ? WHERE table_use_sqlite_id = ?',
        [
          data.updated_at,
          data.status,
          data.sync_status,
          data.table_use_sqlite_id
        ]);
  }


/*
  update table use detail status
*/
  Future<int> _updateTableUseDetailStatus(Transaction txn, TableUseDetail data) async {
    return await txn.rawUpdate('UPDATE $tableTableUseDetail SET updated_at = ?, sync_status = ?, status = ? '
        'WHERE table_use_sqlite_id = ?',
        [data.updated_at, data.sync_status, data.status, data.table_use_sqlite_id]);
  }

/*
  update cash record unique key
*/
  Future<int> _updateCashRecordUniqueKey(Transaction txn, CashRecord data) async {
    return await txn.rawUpdate('UPDATE $tableCashRecord SET cash_record_key = ?, updated_at = ? WHERE cash_record_sqlite_id = ?', [
      data.cash_record_key,
      data.updated_at,
      data.cash_record_sqlite_id,
    ]);
  }

/*
  update order cache payment status
*/
  Future<int> _updateOrderCachePaymentStatus(Transaction txn, OrderCache data) async {
    return await txn.rawUpdate('UPDATE $tableOrderCache SET order_sqlite_id = ?, order_key = ?, payment_status = ?, sync_status = ?, updated_at = ? WHERE order_cache_sqlite_id = ?',
        [data.order_sqlite_id, data.order_key, data.payment_status, data.sync_status, data.updated_at, data.order_cache_sqlite_id]);
  }

/*
  update order tax detail unique key
*/
  Future<int> _updateOrderTaxDetailUniqueKey(Transaction txn, OrderTaxDetail data) async {
    return await txn.rawUpdate('UPDATE $tableOrderTaxDetail SET order_tax_detail_key = ?, sync_status = ?, updated_at = ? WHERE order_tax_detail_sqlite_id = ?', [
      data.order_tax_detail_key,
      data.sync_status,
      data.updated_at,
      data.order_tax_detail_sqlite_id,
    ]);
  }

/*
  update order promotion detail unique key
*/
  Future<int> _updateOrderPromotionDetailUniqueKey(Transaction txn, OrderPromotionDetail data) async {
    return await txn.rawUpdate('UPDATE $tableOrderPromotionDetail SET order_promotion_detail_key = ?, sync_status = ?, updated_at = ? WHERE order_promotion_detail_sqlite_id = ?', [
      data.order_promotion_detail_key,
      data.sync_status,
      data.updated_at,
      data.order_promotion_detail_sqlite_id,
    ]);
  }

/*
  update order unique key
*/
  Future<int> _updateOrderUniqueKey(Transaction txn, Order data) async {
    return await txn.rawUpdate('UPDATE $tableOrder SET order_key = ?, sync_status = ?, updated_at = ? WHERE order_sqlite_id = ?', [
      data.order_key,
      data.sync_status,
      data.updated_at,
      data.order_sqlite_id,
    ]);
  }

}