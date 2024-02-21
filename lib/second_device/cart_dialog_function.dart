import '../database/pos_database.dart';
import '../notifier/cart_notifier.dart';
import '../object/cart_product.dart';
import '../object/categories.dart';
import '../object/order_cache.dart';
import '../object/order_detail.dart';
import '../object/order_modifier_detail.dart';
import '../object/table.dart';
import '../object/table_use_detail.dart';

class CartDialogFunction {
  List<OrderCache> orderCacheList = [];
  List<OrderDetail> orderDetailList = [];


  readSpecificTableDetail(PosTable posTable) async {
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
  }

  Future<void> getOrderModifierDetail(OrderDetail orderDetail) async {
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
        //modifier: getModifierGroupItem(orderDetailList[i]),
        //variant: getVariantGroupItem(orderDetailList[i]),
        productVariantName: orderDetailList[i].product_variant_name,
        remark: orderDetailList[i].remark!,
        unit: orderDetailList[i].unit,
        per_quantity_unit: orderDetailList[i].per_quantity_unit,
        status: 1,
        category_sqlite_id: orderDetailList[i].category_sqlite_id,
        first_cache_created_date_time: orderCacheList.last.created_at,  //orderCacheList[0].created_at,
        first_cache_batch: orderCacheList.last.batch_id,
        first_cache_order_by: orderCacheList.last.order_by,
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
}