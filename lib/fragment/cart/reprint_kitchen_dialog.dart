import 'package:assets_audio_player/assets_audio_player.dart';
import 'package:flutter/material.dart';
import 'package:pos_system/database/pos_database.dart';
import 'package:pos_system/fragment/custom_toastification.dart';
import 'package:pos_system/main.dart';
import 'package:pos_system/object/order_cache.dart';
import 'package:provider/provider.dart';

import '../../notifier/fail_print_notifier.dart';
import '../../notifier/theme_color.dart';
import '../../object/order_detail.dart';
import '../printing_layout/print_receipt.dart';
import '../../object/printer.dart';
import '../../translation/AppLocalizations.dart';

class ReprintKitchenDialog extends StatefulWidget {
  final List<Printer> printerList;
  final List<OrderCache> orderCacheList;
  final Function() callback;
  const ReprintKitchenDialog({Key? key, required this.printerList, required this.orderCacheList, required this.callback}) : super(key: key);

  @override
  State<ReprintKitchenDialog> createState() => _ReprintKitchenDialogState();
}

class _ReprintKitchenDialogState extends State<ReprintKitchenDialog> {
  PrintReceipt printReceipt = PrintReceipt();
  List<OrderDetail> orderDetail = [], reprintList = [];
  List<Printer> printerList = [];
  late FailPrintModel _failPrintModel;
  bool isButtonDisable = false;
  bool closeButtonDisable = false;
  bool isSelectAll = true;
  Set<String> selectedOrder = {};

  @override
  void initState() {
    super.initState();
    readAllOrderDetail();
    printerList = widget.printerList;
  }

  Map<String, List<OrderDetail>> groupOrder(List<OrderDetail> orderDetails) {
    Map<String, List<OrderDetail>> groupedOrderDetails = {};
    for (OrderDetail orderItem in orderDetails) {
      String cardID = '';
      cardID = orderItem.order_cache_key.toString().replaceAll("[", "").replaceAll("]", "");
      if (groupedOrderDetails.containsKey(cardID)) {
        groupedOrderDetails[cardID]!.add(orderItem);
      } else {
        groupedOrderDetails[cardID] = [orderItem];
      }
    }
    return groupedOrderDetails;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeColor>(builder: (context, ThemeColor color, child) {
      return WillPopScope(
        onWillPop: () async => false,
        child: AlertDialog(
          titlePadding: EdgeInsets.fromLTRB(24, 12, 24, 0),
          contentPadding: EdgeInsets.fromLTRB(12, 10, 12, 0),
          title: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(AppLocalizations.of(context)!.translate('reprint_kitchen_list')),
              Spacer(),
              Checkbox(
                value: isSelectAll,
                onChanged: (value){
                  checkChange(value: value);
                }
              ),
            ],
          ),

          content: Container(
            constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height / 2),
            width: 500,
            child: orderDetail.isNotEmpty ?
            ListView.builder(
              shrinkWrap: true,
              padding: EdgeInsets.zero,
              itemCount: groupOrder(orderDetail).length,
              itemBuilder: (context, groupIndex) {
                String cardID = groupOrder(orderDetail).keys.elementAt(groupIndex);
                List<OrderDetail> items = groupOrder(orderDetail)[cardID]!;

                bool isOrderSelected = isSelectAll ? true : selectedOrder.contains(cardID);
                if(isSelectAll)
                  selectedOrder.add(cardID);
                return Card(
                  elevation: 5,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ListTile(
                        title: Row(
                          children: [
                            Checkbox(
                              value: isOrderSelected,
                              onChanged: (value) {
                                setState(() {
                                  if (value != null) {
                                    if (!value) {
                                      selectedOrder.remove(cardID);
                                      isSelectAll = false;
                                      checkAllOrderItem(value, items);
                                    } else {
                                      selectedOrder.add(cardID);
                                      checkAllOrderItem(value, items);
                                      checkIsLastOrder();
                                    }
                                  }
                                });
                              },
                            ),
                            Text("${MediaQuery.of(context).size.width > 500 ? "${AppLocalizations.of(context)!.translate('order_time')}: " : ""}${items.first.created_at}"),
                          ],
                        ),
                        subtitle: Container(
                          // padding: EdgeInsets.symmetric(horizontal: 15.0),
                          child: Text(
                            "${AppLocalizations.of(context)!.translate('item_count')}: ${items.length}",
                            style: TextStyle(
                              // Add your desired style properties here, for example:
                              color: Colors.grey,
                              fontSize: 14.0,
                            ),
                          ),
                        ),
                        onTap: () {
                          setState(() {
                            if (isOrderSelected) {
                              selectedOrder.remove(cardID);
                              checkAllOrderItem(false, items);
                            } else {
                              selectedOrder.add(cardID);
                              checkAllOrderItem(true, items);
                              checkIsLastOrder();
                            }
                          });
                        },
                      ),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 8.0),
                        child: Column(
                          children: [
                            ...items.asMap().entries.map((entry) {
                              int itemIndex = entry.key;
                              OrderDetail item = entry.value;
                              return CheckboxListTile(
                                // isThreeLine: true,
                                secondary: Text("x${item.quantity}"),
                                title: Text("${item.productName}"),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Visibility(
                                      visible: getProductVariant(item) != '' ? true : false,
                                      child: Text(getProductVariant(item)),
                                    ),
                                    Visibility(
                                      visible: getModifier(item) != '' ? true : false,
                                      child: Text(getModifier(item)),
                                    ),
                                    Visibility(
                                      visible: getRemark(item) != '' ? true : false,
                                      child: Text(getRemark(item)),
                                    ),
                                  ],
                                ),
                                value: item.isSelected,
                                onChanged: (value) {
                                  setState(() {
                                    item.isSelected = value!;
                                    checkIsLastOrder();
                                    checkIsLastItem(items, cardID);
                                  });
                                },
                              );
                            }).toList(),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ) : Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.print_disabled),
                Text("${AppLocalizations.of(context)!.translate('no_order')}"),
              ],
            ),
          ),
          actions: [
            Row(
              children: [
                Expanded(
                  flex: 1,
                  child: SizedBox(
                      height: MediaQuery.of(context).size.width > 900 && MediaQuery.of(context).size.height > 500
                          ? MediaQuery.of(context).size.height / 12
                          : MediaQuery.of(context).orientation == Orientation.landscape ? MediaQuery.of(context).size.height / 10
                          : MediaQuery.of(context).size.height / 20,
                      child: ElevatedButton(
                          onPressed: closeButtonDisable ? null : (){
                            setState(() {
                              closeButtonDisable = true;
                            });
                            closeDialog();
                          },
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
                          child: Text(AppLocalizations.of(context)!.translate('close')))
                  ),
                ),
                SizedBox(width: 10),
                Expanded(
                  flex: 1,
                  child: SizedBox(
                    height: MediaQuery.of(context).size.width > 900 && MediaQuery.of(context).size.height > 500
                        ? MediaQuery.of(context).size.height / 12
                        : MediaQuery.of(context).orientation == Orientation.landscape ? MediaQuery.of(context).size.height / 10
                        : MediaQuery.of(context).size.height / 20,
                    child: ElevatedButton(
                        onPressed: isButtonDisable || orderDetail.isEmpty  ? null : () async {
                          disableButton();
                          asyncQ.addJob((_) async {
                            try{
                              await callPrinter();
                            }catch(e){
                              print("Reprint Kitchen Error: ${e}");
                              ShowFailedPrintKitchenToast.showToast();
                            }
                          });
                          //await callPrinter();
                        },
                        style: ElevatedButton.styleFrom(backgroundColor: color.backgroundColor),
                        child: Text(AppLocalizations.of(context)!.translate('reprint'))),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    });
  }

  readAllOrderDetail() async {
    for(int i = 0; i < widget.orderCacheList.length; i++){
      List<OrderDetail> detailData = await PosDatabase.instance.readSpecificOrderDetailByOrderCacheId(widget.orderCacheList[i].order_cache_sqlite_id.toString());
      orderDetail.addAll(detailData);
    }
  }

  checkIsLastOrder(){
    List<OrderDetail> selectedList = orderDetail.where((element) => element.isSelected == true).toList();
    if(selectedList.isEmpty){
      isSelectAll = false;
      disableButton();
    } else if (selectedList.length != orderDetail.length) {
      isSelectAll = false;
      enableButton();
    } else {
      isSelectAll = true;
      enableButton();
    }
  }

  checkIsLastItem(items, String cardID){
    List<OrderDetail> selectedList = items.where((element) => element.isSelected == true).toList();
    if(selectedList.isEmpty){
      setState((){
        isSelectAll = false;
        selectedOrder.remove(cardID);
      });
    }
  }

  checkAllOrderItem(bool value, items){
    if(value == false){
      for(int i = 0; i < items.length; i++){
        setState(() {
          items[i].isSelected = false;
        });
      }
      checkIsLastOrder();
    } else {
      for(int i = 0; i < items.length; i++){
        setState(() {
          items[i].isSelected = true;
        });
      }
      enableButton();
    }
  }

  checkChange({bool? value}){
    if(value == false){
      setState(() {
        isSelectAll = false;
        unselectAllOrderDetail();
        disableButton();
      });
    } else {
      setState(() {
        isSelectAll = true;
        resetOrderDetail();
        enableButton();
      });
    }
  }

  unselectAllOrderDetail(){
    for(int i = 0; i < orderDetail.length; i++){
      orderDetail[i].isSelected = false;
    }
    selectedOrder = {};
  }

  resetOrderDetail(){
    for(int i = 0; i < orderDetail.length; i++){
      orderDetail[i].isSelected = true;
    }
  }

  closeDialog(){
    resetOrderDetail();
    Navigator.of(context).pop();
  }

  disableButton(){
    setState(() {
      isButtonDisable = true;
    });
  }

  enableButton(){
    setState(() {
      isButtonDisable = false;
    });
  }


  callPrinter() async {
    List<OrderDetail> printList = [];
    printList.addAll(orderDetail);
    Navigator.of(context).pop();
    reprintList = printList.where((element) => element.isSelected == true).toList();

    List<OrderDetail> returnData = await printReceipt.reprintFailKitchenList(printerList, reprintList: reprintList);
    if (returnData.isNotEmpty) {
      reprintList.clear();
      ShowFailedPrintKitchenToast.showToast();
    } else {
      reprintList.clear();
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

  String getModifier(OrderDetail orderDetail){
    String result = '';
    List<String?> modifier = [];
    try{
      if(orderDetail.orderModifierDetail.isNotEmpty){
        for(int i = 0; i < orderDetail.orderModifierDetail.length; i++){
          modifier.add(orderDetail.orderModifierDetail[i].mod_name! + '\n');
          result = modifier
              .toString()
              .replaceAll('[', '')
              .replaceAll(']', '')
              .replaceAll(',', '+')
              .replaceFirst('', '+ ');
        }
      }
    }catch(e){
      result = '';
    }
    return result;
  }

  String getOrderNumber(OrderDetail orderDetail){
    String orderNumber = "";
    try{
      orderNumber = orderDetail.orderQueue.toString().replaceAll("[", "").replaceAll("]", "");
    }catch(e){
      orderNumber = "-";
    }
    return orderNumber;
  }

  String getTableNumber(OrderDetail orderDetail){
    String tableNumber = "";
    try{
      tableNumber = orderDetail.tableNumber.toString().replaceAll("[", "").replaceAll("]", "");
    }catch(e){
      tableNumber = "-";
    }
    return tableNumber;
  }

  String getProductVariant(OrderDetail orderDetail){
    String result = '';
    try{
      if(orderDetail.product_variant_name != ''){
        result = "(${orderDetail.product_variant_name})";
      }
    }catch(e){
      result = '';
    }
    return result;
  }

  String getRemark(OrderDetail orderDetail){
    String result = '';
    try{
      if(orderDetail.remark != ''){
        result = "**${orderDetail.remark}";
      }
    }catch(e){
      result = '';
    }
    return result;
  }
}
