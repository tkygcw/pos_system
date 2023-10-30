import 'package:confirm_dialog/confirm_dialog.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../notifier/fail_print_notifier.dart';
import '../../notifier/theme_color.dart';
import '../../object/order_detail.dart';
import '../../object/print_receipt.dart';
import '../../object/printer.dart';
import '../../translation/AppLocalizations.dart';

class ReprintKitchenDialog extends StatefulWidget {
  final List<Printer> printerList;
  final Function() callback;
  const ReprintKitchenDialog({Key? key, required this.printerList, required this.callback}) : super(key: key);

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

  @override
  void initState() {
    super.initState();
    printerList = widget.printerList;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeColor>(builder: (context, ThemeColor color, child) {
      return Consumer<FailPrintModel>(builder: (context, FailPrintModel failPrintModel, child) {
        orderDetail = failPrintModel.failedPrintOrderDetail;
        _failPrintModel = failPrintModel;
        return WillPopScope(
          onWillPop: () async => false,
          child: AlertDialog(
            title: Row(
              children: [
                Text(AppLocalizations.of(context)!.translate('fail_print_order_detail')),
                Spacer(),
                Visibility(
                  visible: orderDetail.isEmpty ? false : true,
                  child: Row(
                    children: [
                      Checkbox(
                          value: isSelectAll,
                          onChanged: (value){
                            checkChange(value: value);
                          }),
                      Container(
                        height: 30,
                        child: VerticalDivider(color: Colors.grey, thickness: 1),
                      ),
                      IconButton(
                          onPressed: () async {
                            if (await confirm(
                              context,
                              title: Text("${AppLocalizations.of(context)!.translate('confirm_remove_all_order_detail')}"),
                              content: Text('${AppLocalizations.of(context)!.translate('confirm_remove_all_order_detail_desc')}'),
                              textOK: Text('${AppLocalizations.of(context)!.translate('yes')}'),
                              textCancel: Text('${AppLocalizations.of(context)!.translate('no')}'),
                            )) {
                              _failPrintModel.removeAllFailedOrderDetail();
                            }
                          },
                          icon: Icon(Icons.delete_forever, color: Colors.red))
                    ],
                  ),
                )
              ],
            ),
            content: Container(
                constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height/2),
                width: 500,
                child: orderDetail.isNotEmpty ?
                ListView.builder(
                  shrinkWrap: true,
                  padding: EdgeInsets.zero,
                  itemCount: orderDetail.length,
                  itemBuilder: (context, index) {
                    return Card(
                        elevation: 5,
                        child: CheckboxListTile(
                            isThreeLine: true,
                            secondary: Text("x${orderDetail[index].quantity}"),
                            title: Text("${orderDetail[index].productName}"),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Visibility(
                                    visible: getTableNumber(orderDetail[index]) != '' ? true : false,
                                    child: Text("${AppLocalizations.of(context)!.translate('table_no')}: ${getTableNumber(orderDetail[index])}")),
                                Visibility(
                                    visible: getProductVariant(orderDetail[index]) != '' ? true : false,
                                    child: Text(getProductVariant(orderDetail[index]))),
                                Visibility(
                                    visible: getModifier(orderDetail[index]) != '' ? true : false,
                                    child: Text(getModifier(orderDetail[index]))),
                                Visibility(
                                    visible: getRemark(orderDetail[index]) != '' ? true : false,
                                    child: Text(getRemark(orderDetail[index])))
                              ],
                            ),
                            value: orderDetail[index].isSelected,
                            onChanged: (value){
                              setState(() {
                                orderDetail[index].isSelected = value!;
                                checkIsLastOrder();
                              });
                            })
                    );
                  },
                ) :
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.print_disabled),
                    Text("${AppLocalizations.of(context)!.translate('no_fail_print_order_detail')}"),
                  ],
                )
            ),
            actions: [
              ElevatedButton(
                  onPressed: isButtonDisable || orderDetail.isEmpty  ? null : () async {
                    disableButton();
                    await callPrinter();
                  },
                  child: Text(AppLocalizations.of(context)!.translate('reprint'))),
              ElevatedButton(
                  onPressed: closeButtonDisable ? null : (){
                    setState(() {
                      closeButtonDisable = true;
                    });
                    closeDialog();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: color.backgroundColor,
                  ),
                  child: Text(AppLocalizations.of(context)!.translate('close')))
            ],
          ),
        );
      });
    });
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
    _failPrintModel.removeAllFailedOrderDetail();
    Navigator.of(context).pop();
    reprintList = printList.where((element) => element.isSelected == true).toList();
    List<OrderDetail> returnData = await printReceipt.reprintKitchenList(printerList, reprintList: reprintList);
    if (returnData.isNotEmpty) {
      reprintList.clear();
      _failPrintModel.addAllFailedOrderDetail(orderDetailList: returnData);
    } else {
      reprintList.clear();
      _failPrintModel.removeAllFailedOrderDetail();
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
