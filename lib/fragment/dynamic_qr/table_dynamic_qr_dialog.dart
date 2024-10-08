import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';
import 'package:pos_system/database/pos_firestore.dart';
import 'package:pos_system/notifier/app_setting_notifier.dart';
import 'package:pos_system/object/table.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:crypto/crypto.dart';

import '../../database/domain.dart';
import '../../notifier/theme_color.dart';
import '../../translation/AppLocalizations.dart';
import '../../utils/Utils.dart';
import 'print_dynamic_qr.dart';

class TableDynamicQrDialog extends StatefulWidget {
  final List<PosTable> posTableList;
  final Function()? callback;
  const TableDynamicQrDialog({Key? key, required this.posTableList, this.callback}) : super(key: key);

  @override
  State<TableDynamicQrDialog> createState() => _TableDynamicQrDialogState();
}

class _TableDynamicQrDialogState extends State<TableDynamicQrDialog> {
  PosFirestore posFirestore = PosFirestore.instance;
  PrintDynamicQr printDynamicQr = PrintDynamicQr();
  DateTime currentDateTime = DateTime.now().add(Duration(hours: AppSettingModel.instance.dynamic_qr_default_exp_after_hour!));
  int tapCount = 0;
  late Map branchObject;
  late TextEditingController dateTimeController;

  resetTapCount () => tapCount = 0;

  resetDefaultDatetime(){
    currentDateTime = DateTime.now().add(Duration(hours: AppSettingModel.instance.dynamic_qr_default_exp_after_hour!));
    dateTimeController.text = Utils.formatDate(currentDateTime.toString());
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    dateTimeController = TextEditingController(text: Utils.formatDate(currentDateTime.toString()));
    printDynamicQr.readCashierPrinter();
    getPref();
  }

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
    resetTapCount();
    resetDefaultDatetime();
  }

  String generateSelectedTable(){
    if(widget.posTableList.length > 1){
      return "${AppLocalizations.of(context)?.translate('selected')}: ${widget.posTableList.length}";
    } else {
      return "${AppLocalizations.of(context)?.translate('table_no')}: ${widget.posTableList.first.number}";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeColor>(builder: (context, ThemeColor color, child) {
      return AlertDialog(
        title: Text(AppLocalizations.of(context)!.translate('generate_dynamic_qr')),
        content: SizedBox(
          width: 250,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(generateSelectedTable(),
                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey, fontSize: 18.0),),
              SizedBox(height: 20),
              TextField(
                decoration: InputDecoration(
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(width: 1,color: color.backgroundColor),
                    ),
                  label: Text(AppLocalizations.of(context)!.translate('exp_datetime'))
                ),
                readOnly: true,
                onTap: (){
                  openDateTimePicker(color);
                },
                controller: dateTimeController,
              ),
            ],
          ),
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: color.buttonColor
            ),
            onPressed: () async {
              tapCount++;
              if(tapCount == 1){
                if(currentDateTime.isBefore(DateTime.now())){
                  resetTapCount();
                  Fluttertoast.showToast(
                      backgroundColor: Color(0xFFFF0000),
                      msg: AppLocalizations.of(context)!.translate('dynamic_qr_error'));
                } else {
                  bool _hasInternetAccess = await Domain().isHostReachable();
                  if(_hasInternetAccess){
                    List<PosTable> selectedTable = widget.posTableList;
                    for(int i = 0 ; i < selectedTable.length; i++){
                      PosTable updatedTable = await generateDynamicQRUrl(selectedTable[i]);
                      posFirestore.insertTableDynamic(updatedTable);
                      Map res = await Domain().insertTableDynamicQr(updatedTable);
                      if(res['status'] == '1'){
                        await printDynamicQr.printDynamicQR(table: updatedTable);
                      } else {
                        break;
                      }
                    }
                    if(widget.callback != null){
                      widget.callback!();
                    }
                    Navigator.of(context).pop();
                  } else {
                    resetTapCount();
                    Fluttertoast.showToast(
                        backgroundColor: Color(0xFFFF0000),
                        msg: AppLocalizations.of(context)!.translate('check_internet_connection'));
                  }
                }
              }
            },
            child: Text(AppLocalizations.of(context)!.translate('generate')),
          ),
          ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red
              ),
              onPressed: () {
                tapCount++;
                if(tapCount == 1){
                  Navigator.of(context).pop();
                }
              },
              child: Text(AppLocalizations.of(context)!.translate('close')))
        ],
      );
    });
  }

  openDateTimePicker(ThemeColor color){
    showDialog(context: context, barrierDismissible: false, builder: (builder){
      return AlertDialog(
        title: Text(AppLocalizations.of(context)!.translate('set_dynamic_qr_exp_datetime')),
        content: SizedBox(
          height: 250,
          width: 350,
          child: CupertinoDatePicker(
            mode: CupertinoDatePickerMode.dateAndTime,
            initialDateTime: currentDateTime,
            onDateTimeChanged: (DateTime newDateTime){
              currentDateTime = newDateTime;
            },
          ),
        ),
        actions: [
          SizedBox(
            width: 200,
            height: 60,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: color.buttonColor
              ),
              onPressed: (){
                dateTimeController.text = Utils.formatDate(currentDateTime.toString());
                Navigator.of(context).pop();
              },
              child: Text(AppLocalizations.of(context)!.translate('save')),
            ),
          ),
          SizedBox(
            width: 200,
            height: 60,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red
              ),
              onPressed: (){
                resetDefaultDatetime();
                Navigator.of(context).pop();
              },
              child: Text(AppLocalizations.of(context)!.translate('cancel')),
            ),
          ),
        ],
      );
    });
  }

  PosTable generateDynamicQRUrl(PosTable currentSelectedTable) {
    DateFormat dateFormat = DateFormat("yyyy-MM-dd HH:mm:ss");
    var bytes = currentDateTime.toString() + currentSelectedTable.table_id.toString();
    final md5Hash = md5.convert(utf8.encode(bytes));
    final hashCode = Utils.shortHashString(hashCode: md5Hash);
    var url = '${Domain.qr_domain}${branchObject['branch_url']}/$hashCode';
    currentSelectedTable.dynamicQrHash = hashCode;
    currentSelectedTable.qrOrderUrl = url;
    currentSelectedTable.dynamicQRExp = dateFormat.format(currentDateTime);
    return currentSelectedTable;
  }

  getPref() async {
    final prefs = await SharedPreferences.getInstance();
    final String? branch = prefs.getString('branch');
    branchObject = json.decode(branch!);
  }

  List<PosTable> sortTable(List<PosTable> tableList){
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
        return aNumber.compareTo(bNumber);
      }
    });
    return tableList;
  }

}
