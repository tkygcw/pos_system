import 'dart:convert';

import 'package:intl/intl.dart';
import 'package:pos_system/database/pos_database.dart';
import 'package:pos_system/object/order.dart';
import 'package:pos_system/object/promotion.dart';
import 'package:pos_system/object/tax_link_dining.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:crypto/crypto.dart';
import 'package:sqflite/sqflite.dart';

import '../../object/app_setting.dart';
import '../../object/branch_link_promotion.dart';
import '../../object/branch_link_tax.dart';
import '../../object/order_promotion_detail.dart';
import '../../object/order_tax_detail.dart';
import '../../utils/Utils.dart';


class PaymentFunction {
  final DateFormat _dateFormat = DateFormat("yyyy-MM-dd HH:mm:ss");
  final PosDatabase _posDatabase = PosDatabase.instance;
  Order _order = Order();
  List<Promotion> _promotionList = [];
  List<TaxLinkDining> _taxLinkDiningList = [];

  PaymentFunction({Order? order, List<Promotion>? promotion, List<TaxLinkDining>? taxLinkDining}) {
    _order = order ?? _order;
    _promotionList = promotion ?? _promotionList;
    _taxLinkDiningList = taxLinkDining ?? _taxLinkDiningList;
  }

  Order get order => _order;

  getCompanyPaymentMethod() async {
    return await _posDatabase.readPaymentMethods();
  }

  makePayment() async {
    var db = await _posDatabase.database;
    await db.transaction((txn) async {
      await _createOrder(txn);
      await _createOrderPromotionDetail(txn);
      await _crateOrderTaxDetail(txn);
    });
  }

  _crateOrderTaxDetail(Transaction txn) async {
    String dateTime = _dateFormat.format(DateTime.now());
    List<String> _value = [];

    for (var tax in _taxLinkDiningList) {
      List<BranchLinkTax> branchTaxData = await _readSpecificBranchLinkTax(txn, tax.tax_id!);
      if (branchTaxData.length > 0) {
        OrderTaxDetail data = await PosDatabase.instance
            .insertSqliteOrderTaxDetail(OrderTaxDetail(
            order_tax_detail_id: 0,
            order_tax_detail_key: '',
            order_sqlite_id: _order.order_sqlite_id!.toString(),
            order_id: '0',
            order_key: _order.order_key!,
            tax_name: tax.tax_name,
            type: tax.tax_type,
            rate: tax.tax_rate,
            tax_id: tax.tax_id,
            branch_link_tax_id:
            branchTaxData[0].branch_link_tax_id.toString(),
            tax_amount: tax.tax_amount!,
            sync_status: 0,
            created_at: dateTime,
            updated_at: '',
            soft_delete: ''));
        OrderTaxDetail returnData = await _insertOrderTaxDetailKey(txn, data, dateTime);
        _value.add(jsonEncode(returnData));
      }
    }
    // order_tax_value = _value.toString();
  }

  _createOrderPromotionDetail(Transaction txn) async {
    String dateTime = _dateFormat.format(DateTime.now());
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
            created_at: dateTime,
            updated_at: '',
            soft_delete: '');
        OrderPromotionDetail data = await _insertSqliteOrderPromotionDetail(txn ,insertData);
        OrderPromotionDetail? returnData = await _insertOrderPromotionDetailKey(txn, data, dateTime);
        _value.add(jsonEncode(returnData));
      }
      // order_promotion_value = _value.toString();
    }catch(e, s){
      print("_createOrderPromotionDetail error:${e}, $s");
      rethrow;
    }
  }

  Future<int> _generateOrderNumber(Transaction txn) async {
    Order? data = await _readLatestOrder(txn);
    return data != null ? int.parse(data.order_number!) + 1 : 1;
  }

  _createOrder(Transaction txn) async {
    print('create order called');
    List<String> _value = [];
    String dateTime = _dateFormat.format(DateTime.now());
    final prefs = await SharedPreferences.getInstance();
    final String? login_user = prefs.getString('user');
    final int? branch_id = prefs.getInt('branch_id');
    AppSetting? localSetting = await _readLocalAppSetting(txn);
    Map logInUser = json.decode(login_user!);
    int orderNum = await _generateOrderNumber(txn);
    //temp hide order queue
    // int orderQueue = localSetting!.enable_numbering == 1 ? await readQueueFromOrderCache() : 0;
    try {
      if (orderNum != 0) {
        Order orderObject = order.copy(
            order_id: 0,
            order_number: orderNum.toString().padLeft(5, '0'),
            // order_queue: localSetting!.enable_numbering == 1 ? orderQueue.toString().padLeft(4, '0') : '',
            order_queue: '',//localSetting.enable_numbering == 1 && orderQueue != -1 ? orderQueue.toString().padLeft(4, '0') : '',
            company_id: logInUser['company_id'].toString(),
            branch_id: branch_id.toString(),
            customer_id: '',
            branch_link_promotion_id: '',
            branch_link_tax_id: '',
            payment_status: 0,
            order_key: '',
            refund_sqlite_id: '',
            refund_key: '',
            settlement_sqlite_id: '',
            settlement_key: '',
            sync_status: 0,
            created_at: dateTime,
            updated_at: '',
            soft_delete: '');
        _order = await _insertSqliteOrder(txn, orderObject);
         await _insertOrderKey(txn);
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

  _insertOrderTaxDetailKey(Transaction txn, OrderTaxDetail orderTaxDetail, String dateTime) async {
    String? _key;
    OrderTaxDetail? _data;
    _key = await _generateOrderTaxDetailKey(orderTaxDetail);
    if (_key != null) {
      OrderTaxDetail orderTaxDetailObject = OrderTaxDetail(
          order_tax_detail_key: _key,
          sync_status: 0,
          updated_at: dateTime,
          order_tax_detail_sqlite_id:
          orderTaxDetail.order_tax_detail_sqlite_id);
      int updatedData = await _updateOrderTaxDetailUniqueKey(txn, orderTaxDetailObject);
      if (updatedData == 1) {
        // OrderTaxDetail orderTaxDetailData = await PosDatabase.instance
        //     .readSpecificOrderTaxDetailByLocalId(
        //     orderTaxDetailObject.order_tax_detail_sqlite_id!);
        // _data = orderTaxDetailData;
      }
    }
    return _data;
  }

  Future<OrderPromotionDetail?> _insertOrderPromotionDetailKey(Transaction txn, OrderPromotionDetail orderPromotionDetail, String dateTime) async {
    String _key = await _generateOrderPromotionDetailKey(orderPromotionDetail);
    OrderPromotionDetail orderPromoDetailObject = orderPromotionDetail.copy(
        order_promotion_detail_key: _key,
        sync_status: 0,
        updated_at: dateTime,
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

  _insertOrderKey(Transaction txn) async {
    List<String> _value = [];
    Order? _updatedOrder;
    try{
      String dateTime = _dateFormat.format(DateTime.now());
      var orderKey = await _generateOrderKey();
      if (orderKey != null) {
        _order = _order.copy(
            order_key: orderKey,
            sync_status: 0,
            updated_at: dateTime,
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

  _generateOrderKey() async {
    final prefs = await SharedPreferences.getInstance();
    final int? device_id = prefs.getInt('device_id');
    var bytes = order.created_at!.replaceAll(new RegExp(r'[^0-9]'), '') +
        _order.order_sqlite_id.toString() +
        device_id.toString();
    var md5Hash = md5.convert(utf8.encode(bytes));
    return Utils.shortHashString(hashCode: md5Hash);
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
    final id = await txn.insert(tableOrder!, data.toJson());
    return data.copy(order_sqlite_id: id);
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