
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:pos_system/database/pos_database.dart';
import 'package:pos_system/object/order_cache.dart';
import 'package:pos_system/object/order_detail.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../database/domain.dart';
import '../object/table.dart';
import '../translation/AppLocalizations.dart';
import 'dynamic_qr/print_dynamic_qr.dart';
import 'dynamic_qr/table_dynamic_qr_dialog.dart';

class ChooseQrTypeDialog extends StatefulWidget {
  final List<PosTable> posTableList;
  final Function()? callback;
  const ChooseQrTypeDialog({Key? key, required this.posTableList, this.callback}) : super(key: key);

  @override
  State<ChooseQrTypeDialog> createState() => _ChooseQrTypeDialogState();
}

class _ChooseQrTypeDialogState extends State<ChooseQrTypeDialog> {
  PrintDynamicQr printDynamicQr = PrintDynamicQr();
  int tapCount = 0;
  late Map branchObject;
  List<OrderCache> orderCacheList = [];
  List<OrderDetail> orderDetailList = [];

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    printDynamicQr.readCashierPrinter();
  }

  bool checkTableStatus() {
    if (widget.posTableList.isEmpty) {
      return true;
    }

    return !widget.posTableList.any((table) =>
    table.status != 1 || (table.status == 1 && table.order_key != null)
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(AppLocalizations.of(context)!.translate('choose_qr_type')),
      content: SingleChildScrollView(
        child: Column(
          children: [
            Card(
              elevation: 10,
              child: ListTile(
                leading: CircleAvatar(
                    backgroundColor: Colors.grey.shade200,
                    child: Icon(
                      Icons.access_time_outlined,
                      color: Colors.grey,
                    )),
                title: Text(AppLocalizations.of(context)!.translate('dynamic_qr')),
                onTap: (){
                  Navigator.of(context).pop();
                  openDynamicQRDialog();
                },
                trailing: Icon(Icons.navigate_next),
              ),
            ),
            Card(
              elevation: 10,
              child: ListTile(
                leading: CircleAvatar(
                    backgroundColor: Colors.grey.shade200,
                    child: Icon(
                      Icons.qr_code_2,
                      color: Colors.grey,
                    )),
                title: Text(AppLocalizations.of(context)!.translate('fixed_qr')),
                onTap: () async {
                  tapCount++;
                  if(tapCount == 1){
                    await getPref();
                    for(int i = 0; i < widget.posTableList.length; i++){
                      PosTable updatedTable = await generateFixQrUrl(widget.posTableList[i]);
                      await printDynamicQr.printDynamicQR(table: updatedTable);
                    }
                    if(widget.callback != null){
                      widget.callback!();
                    }
                    Navigator.of(context).pop();
                  }
                },
                trailing: Icon(Icons.navigate_next),
              ),
            ),
            Visibility(
              visible: checkTableStatus(),
              child: Card(
                elevation: 10,
                child: ListTile(
                  leading: CircleAvatar(
                      backgroundColor: Colors.grey.shade200,
                      child: Icon(
                        Icons.delete,
                        color: Colors.grey,
                      )),
                  title: Text(AppLocalizations.of(context)!.translate('void')),
                  onTap: () async {
                    tapCount++;
                    if(tapCount == 1){
                      await getPref();
                      for(int i = 0; i < widget.posTableList.length; i++){
                        // if table active
                        if (widget.posTableList[i].status == 1) {
                          if(widget.posTableList[i].order_key == null) {
                            print("table user key: ${widget.posTableList[i].table_use_key}");
                            // isTableSelectedBySubPos
                            List<OrderCache> data = await PosDatabase.instance.readTableOrderCache(widget.posTableList[i].table_use_key!);
                            for (int i = 0; i < data.length; i++) {
                              if (!orderCacheList.contains(data)) {
                                orderCacheList = List.from(data);
                              }
                              List<OrderDetail> detailData = await PosDatabase.instance.readTableOrderDetail(data[i].order_cache_key!);
                              if (!orderDetailList.contains(detailData)) {
                                orderDetailList..addAll(detailData);
                              }

                            }

                          } else {
                            Fluttertoast.showToast(backgroundColor: Color(0xFFFF0000), msg: AppLocalizations.of(context)!.translate('payment_not_complete'));
                          }
                        }
                      }
                      if(widget.callback != null){
                        widget.callback!();
                      }
                      Navigator.of(context).pop();
                    }
                  },
                  trailing: Icon(Icons.navigate_next),
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        Center(
          child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red
              ),
              onPressed: () {
                tapCount++;
                if(tapCount == 1){
                  Navigator.of(context).pop();
                }
              },
              child: Text(AppLocalizations.of(context)!.translate('close'))),
        )
      ],
    );
  }

  getPref() async {
    final prefs = await SharedPreferences.getInstance();
    final String? branch = prefs.getString('branch');
    branchObject = json.decode(branch!);
  }

  generateFixQrUrl(PosTable posTable){
    var url = '${Domain.qr_domain}${branchObject['branch_url']}/${posTable.table_url}';
    posTable.qrOrderUrl = url;
    posTable.dynamicQRExp = null;
    return posTable;
  }

  Future<Future<Object?>> openDynamicQRDialog() async {
    final List<PosTable> selectedTable = [];
    selectedTable.addAll(widget.posTableList);
    return showGeneralDialog(
        barrierColor: Colors.black.withOpacity(0.5),
        transitionBuilder: (context, a1, a2, widget) {
          final curvedValue = Curves.easeInOutBack.transform(a1.value) - 1.0;
          return Transform(
            transform: Matrix4.translationValues(0.0, curvedValue * 200, 0.0),
            child: TableDynamicQrDialog(posTableList: selectedTable, callback: this.widget.callback,),
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
}
