import 'package:collection/collection.dart';
import 'package:pos_system/notifier/cart_notifier.dart';
import 'package:provider/provider.dart';

import '../database/pos_database.dart';
import '../main.dart';
import '../object/branch_link_product.dart';
import '../object/categories.dart';
import '../object/order.dart';
import '../object/order_cache.dart';
import '../object/order_detail.dart';
import '../object/order_modifier_detail.dart';
import '../object/order_payment_split.dart';
import '../object/table.dart';
import '../object/table_use_detail.dart';

class TableFunction {
  final _context = MyApp.navigatorKey.currentContext!;
  PosDatabase _posDatabase = PosDatabase.instance;
  List<PosTable> tableList = [];
  List<PosTable> initialTableList = [];
  List<OrderCache> _orderCacheList = [];
  List<OrderDetail> _orderDetailList = [];

  List<OrderCache> get orderCacheList => _orderCacheList;

  List<OrderDetail> get orderDetailList => _orderDetailList;


  readAllTable() async {
    tableList = await _posDatabase.readAllTable();
    //for compare purpose
    initialTableList = await _posDatabase.readAllTable();

    //table number sorting
    sortTable();

    await readAllTableGroup();
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

  readAllTableGroup() async {
    double tableAmount = 0.0;
    bool hasTableInUse = tableList.any((item) => item.status == 1);
    if(hasTableInUse){
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
  }

  Future<void> readSpecificTableDetail(PosTable posTable) async {
    try{
      //Get specific table use detail
      List<TableUseDetail> tableUseDetailData = await _posDatabase.readSpecificTableUseDetail(posTable.table_sqlite_id!);
      if(tableUseDetailData.isNotEmpty){
        //Get all order table cache
        List<OrderCache> data = await _posDatabase.readTableOrderCache(tableUseDetailData[0].table_use_key!);
        Provider.of<CartModel>(_context, listen: false).addAllSubPosOrderCache(data);
        //loop all table order cache
        for (int i = 0; i < data.length; i++) {
          if (!_orderDetailList.contains(data)) {
            _orderCacheList = List.from(data);
          }
          //Get all order detail based on order cache id
          List<OrderDetail> detailData = await _posDatabase.readTableOrderDetail(data[i].order_cache_key!);
          //add all order detail from db
          if (!_orderDetailList.contains(detailData)) {
            _orderDetailList..addAll(detailData);
          }
        }
        //loop all order detail
        for (int k = 0; k < _orderDetailList.length; k++) {
          //Get data from branch link product
          List<BranchLinkProduct> data = await _posDatabase.readSpecificBranchLinkProduct(_orderDetailList[k].branch_link_product_sqlite_id!);
          _orderDetailList[k].allow_ticket = data[0].allow_ticket;
          _orderDetailList[k].ticket_count = data[0].ticket_count;
          _orderDetailList[k].ticket_exp = data[0].ticket_exp;
          // if(data.isNotEmpty){
          //   _orderDetailList[k].allow_ticket = data[0].allow_ticket;
          //   _orderDetailList[k].ticket_count = data[0].ticket_count;
          //   _orderDetailList[k].ticket_exp = data[0].ticket_exp;
          // }
          //Get product category
          if(_orderDetailList[k].category_sqlite_id! == '0'){
            _orderDetailList[k].product_category_id = '0';
          } else {
            Categories category = await _posDatabase.readSpecificCategoryByLocalId(_orderDetailList[k].category_sqlite_id!);
            _orderDetailList[k].product_category_id = category.category_id.toString();
          }

          //check product modifier
          await _getOrderModifierDetail(_orderDetailList[k]);
        }
      }
    }catch(e){
      rethrow;
    }
  }

  Future<void> _getOrderModifierDetail(OrderDetail orderDetail) async {
    try{
      List<OrderModifierDetail> modDetail = await _posDatabase.readOrderModifierDetail(orderDetail.order_detail_sqlite_id.toString());
      if (modDetail.isNotEmpty) {
        orderDetail.orderModifierDetail = modDetail;
      } else {
        orderDetail.orderModifierDetail = [];
      }
    }catch(e){
      rethrow;
    }
  }

  void clearSubPosOrderCache({String? table_use_key}){
    print("table use key: ${table_use_key}");
    if(table_use_key != null){
      Provider.of<CartModel>(_context, listen: false).removeSpecificSubPosOrderCache(table_use_key);
    } else {
      Provider.of<CartModel>(_context, listen: false).clearSubPosOrderCache();
    }
  }

  void removeSpecificBatchSubPosOrderCache(String batch){
    Provider.of<CartModel>(_context, listen: false).removeSpecificBatchSubPosOrderCache(batch);
  }

  Future<bool> IsTableSelected(PosTable posTable) async {
    CartModel cartModel =  Provider.of<CartModel>(_context, listen: false);
    bool status1 = await cartModel.isTableSelectedBySubPos(tableUseKey: posTable.table_use_key!);
    bool status2 = await cartModel.isTableSelectedByMainPos(tableUseKey: posTable.table_use_key!);
    bool isTableSelected = false;
    if(posTable.table_use_key != null){
      isTableSelected = status1 || status2;
    }
    // List<PosTable> inCartTableList = Provider.of<CartModel>(_context, listen: false).selectedTable.where((e) => e.isInPaymentCart == true).toList();
    // if(inCartTableList.isNotEmpty){
    //   return inCartTableList.any((e) => e.table_sqlite_id == posTable.table_sqlite_id);
    //
    //   // for(int i = 0; i < cart.selectedTable.length; i++){
    //   //   for(int j = 0; j < inCartTableList.length; j++){
    //   //     if(cart.selectedTable[i].table_sqlite_id == inCartTableList[j].table_sqlite_id){
    //   //       isTableSelected = true;
    //   //       break;
    //   //     }
    //   //   }
    //   // }
    // }
    return isTableSelected;
  }

}