import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';
import 'package:pos_system/object/table.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:crypto/crypto.dart';

import '../../database/domain.dart';
import '../../utils/Utils.dart';
import '../setting/table_setting/print_dynamic_qr.dart';

class TableDynamicQrDialog extends StatefulWidget {
  final PosTable posTable;
  const TableDynamicQrDialog({Key? key, required this.posTable}) : super(key: key);

  @override
  State<TableDynamicQrDialog> createState() => _TableDynamicQrDialogState();
}

class _TableDynamicQrDialogState extends State<TableDynamicQrDialog> {
  TextEditingController dateTimeController = TextEditingController(text: Utils.formatDate(DateTime.now().toString()));
  PrintDynamicQr printDynamicQr = PrintDynamicQr();
  DateTime currentDateTime = DateTime.now();
  int tapCount = 0;


  generateDynamicQRUrl() async {
    DateFormat dateFormat = DateFormat("yyyy-MM-dd HH:mm:ss");
    PosTable currentSelectedTable = widget.posTable;
    final prefs = await SharedPreferences.getInstance();
    final String? branch = prefs.getString('branch');
    Map branchObject = json.decode(branch!);
    var md5Hash = md5.convert(utf8.encode(currentDateTime.toString()));
    var hashCode = Utils.shortHashString(hashCode: md5Hash);
    var url = '${Domain.qr_domain}${branchObject['branch_url']}/${currentSelectedTable.table_url}/$hashCode';
    currentSelectedTable.qrOrderUrl = url;
    currentSelectedTable.dynamicQRExp = dateFormat.format(currentDateTime);
    print("table qr url: ${currentSelectedTable.qrOrderUrl}");
    return currentSelectedTable;
  }

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
    tapCount = 0;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text("Generate dynamic QR code"),
      content: TextField(
        readOnly: true,
        onTap: (){
          showDialog(context: context, barrierDismissible: false, builder: (builder){
            return AlertDialog(
              title: Text("Set dynamic QR expired datetime"),
              content: SizedBox(
                height: 250,
                child: CupertinoDatePicker(
                  mode: CupertinoDatePickerMode.dateAndTime,
                  initialDateTime: currentDateTime,
                  onDateTimeChanged: (DateTime newDateTime){
                    currentDateTime = newDateTime;
                  },
                ),
              ),
              actions: [
                ElevatedButton(
                  onPressed: (){
                    dateTimeController.text = Utils.formatDate(currentDateTime.toString());
                    Navigator.of(context).pop();
                  },
                  child: Text("Save"),
                ),
                ElevatedButton(
                  onPressed: (){
                    dateTimeController.text = Utils.formatDate(DateTime.now().toString());
                    currentDateTime = DateTime.now();
                    Navigator.of(context).pop();
                  },
                  child: Text("Cancel"),
                ),
              ],
            );
          });
        },
        controller: dateTimeController,
      ),
      actions: [
        ElevatedButton(
            onPressed: () async {
              tapCount++;
              if(tapCount == 1){
                if(currentDateTime.isBefore(DateTime.now())){
                  tapCount = 0;
                  Fluttertoast.showToast(
                      backgroundColor: Color(0xFFFF0000),
                      msg: "QR expired datetime must after current datetime");
                } else {
                  PosTable selectedTable = await generateDynamicQRUrl();
                  List<PosTable> tableList = [];
                  tableList.add(selectedTable);
                  bool _hasInternetAccess = await Domain().isHostReachable();
                  if(_hasInternetAccess){
                    await Domain().insertTableDynamicQr(selectedTable);
                    await printDynamicQr.printDynamicQR(tableList: tableList);
                  } else {
                    Fluttertoast.showToast(
                        backgroundColor: Color(0xFFFF0000),
                        msg: "Please check your internet connection");
                  }
                  Navigator.of(context).pop();
                }
              }
            },
            child: Text("Generate"),
        ),
        ElevatedButton(
            onPressed: () {
              tapCount++;
              if(tapCount == 1){
                Navigator.of(context).pop();
              }
            },
            child: Text("close"))
      ],
    );
  }
}
