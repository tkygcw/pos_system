import 'dart:async';
import 'dart:convert';

import 'package:f_logs/model/flog/flog.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pos_system/fragment/setting/qr_code_setting/receipt_view_1.dart';
import 'package:pos_system/fragment/setting/qr_code_setting/receipt_view_2.dart';
import 'package:pos_system/object/dynamic_qr.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:crypto/crypto.dart';

import '../../../database/pos_database.dart';
import '../../../notifier/theme_color.dart';
import '../../../translation/AppLocalizations.dart';
import '../../../utils/Utils.dart';
import '../../dynamic_qr/print_dynamic_qr.dart';
import 'mobile_receipt_view_1.dart';
import 'mobile_receipt_view_2.dart';

class DynamicQrReceiptDialog extends StatefulWidget {
  const DynamicQrReceiptDialog({Key? key}) : super(key: key);

  @override
  State<DynamicQrReceiptDialog> createState() => _DynamicQrReceiptDialogState();
}

class _DynamicQrReceiptDialogState extends State<DynamicQrReceiptDialog> {
  PrintDynamicQr printDynamicQr = PrintDynamicQr();
  String receiptView = "80";
  DynamicQR? testPrintLayout;
  late Map branchObject;
  int tapCount = 0;

  testLayout(DynamicQR qrLayout){
    testPrintLayout = qrLayout;
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    printDynamicQr.readCashierPrinter();
  }

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
    tapCount = 0;
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    return Consumer<ThemeColor>(builder: (context, ThemeColor color, child) {
      if(screenWidth > 800 && screenHeight > 500){
        return AlertDialog(
          title: Row(
            children: [
              Text(AppLocalizations.of(context)!.translate('qr_code_layout')),
              SizedBox(width: 10),
              SegmentedButton(
                style: ButtonStyle(
                    side: WidgetStateProperty.all(
                      BorderSide.lerp(BorderSide(
                        style: BorderStyle.solid,
                        color: Colors.blueGrey,
                        width: 1,
                      ),
                          BorderSide(
                            style: BorderStyle.solid,
                            color: Colors.blueGrey,
                            width: 1,
                          ),
                          1),
                    )
                ),
                segments: <ButtonSegment<String>>[
                  ButtonSegment(value: "80", label: Text("80mm")),
                  ButtonSegment(value: "58", label: Text("58mm"))
                ],
                onSelectionChanged: (Set<String> newSelection) async{
                  setState(() {
                    receiptView = newSelection.first;
                  });
                },
                selected: <String>{receiptView},
              ),
            ],
          ),
          content: SizedBox(
            height: MediaQuery.of(context).size.height,
            width: MediaQuery.of(context).size.width/2,
            child: receiptView == "80" ?
            ReceiptView1(callBack: testLayout) :
            ReceiptView2(callBack: testLayout),
          ),
          actions: [
            SizedBox(
              width: MediaQuery.of(context).size.width / 4,
              height: MediaQuery.of(context).size.height / 12,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: color.backgroundColor,
                ),
                child: Text(AppLocalizations.of(context)!.translate('test_print')),
                onPressed: () async {
                  await printDynamicQr.testPrintDynamicQR(qrLayout: testPrintLayout!, paperSize: receiptView);
                },
              ),
            ),
            SizedBox(
              width: MediaQuery.of(context).size.width / 4,
              height: MediaQuery.of(context).size.height / 12,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                ),
                child: Text('${AppLocalizations.of(context)?.translate('close')}'),
                onPressed: () {
                  tapCount++;
                  if(tapCount == 1){
                    Navigator.of(context).pop();
                  }
                },
              ),
            ),
            SizedBox(
              width: MediaQuery.of(context).size.width / 4,
              height: MediaQuery.of(context).size.height / 12,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: color.backgroundColor,
                ),
                child: Text(AppLocalizations.of(context)!.translate('update')),
                onPressed: () {
                  tapCount++;
                  if(tapCount == 1){
                    _submit(context);
                  }
                },
              ),
            ),
          ],
        );
      } else {
        return AlertDialog(
          title: Text(AppLocalizations.of(context)!.translate('dynamic_qr_layout')),
          titlePadding: EdgeInsets.fromLTRB(24, 16, 24, 0),
          contentPadding: EdgeInsets.fromLTRB(24, 16, 24, 16),
          content: Container(
            height: MediaQuery.of(context).size.height / 2,
            width: 500,
            child: SingleChildScrollView(
              child: Column(
                children: [
                  Align(
                    alignment: Alignment.topLeft,
                    child: SegmentedButton(
                      style: ButtonStyle(
                          side: WidgetStateProperty.all(
                            BorderSide.lerp(BorderSide(
                              style: BorderStyle.solid,
                              color: Colors.blueGrey,
                              width: 1,
                            ),
                                BorderSide(
                                  style: BorderStyle.solid,
                                  color: Colors.blueGrey,
                                  width: 1,
                                ),
                                1),
                          )
                      ),
                      segments: <ButtonSegment<String>>[
                        ButtonSegment(value: "80", label: Text("80mm")),
                        ButtonSegment(value: "58", label: Text("58mm"))
                      ],
                      onSelectionChanged: (Set<String> newSelection) async{
                        setState(() {
                          receiptView = newSelection.first;
                        });
                      },
                      selected: <String>{receiptView},
                    ),
                  ),
                  SizedBox(height: 10),
                  receiptView == "80" ?
                  MobileReceiptView1(callBack: testLayout) :
                  MobileReceiptView2(callBack: testLayout),
                ],
              ),
            ),
          ),
          actions: [
            Row(
              children: [
                Expanded(
                  flex: 1,
                  child: SizedBox(
                    width: MediaQuery.of(context).orientation == Orientation.landscape ? MediaQuery.of(context).size.width / 2.5 : MediaQuery.of(context).size.width / 3,
                    height: MediaQuery.of(context).orientation == Orientation.landscape ? MediaQuery.of(context).size.height / 10 : MediaQuery.of(context).size.height / 20,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: color.backgroundColor,
                      ),
                      child: Text(MediaQuery.of(context).orientation == Orientation.landscape ?
                      AppLocalizations.of(context)!.translate('test_print')
                          : AppLocalizations.of(context)!.translate('test')),
                      onPressed: () async {
                        await printDynamicQr.testPrintDynamicQR(qrLayout: testPrintLayout!, paperSize: receiptView);
                      },
                    ),
                  ),
                ),
                SizedBox(width: 10),
                Expanded(
                  flex: 1,
                  child: SizedBox(
                    width: MediaQuery.of(context).orientation == Orientation.landscape ? MediaQuery.of(context).size.width / 2.5 : MediaQuery.of(context).size.width / 3,
                    height: MediaQuery.of(context).orientation == Orientation.landscape ? MediaQuery.of(context).size.height / 10 : MediaQuery.of(context).size.height / 20,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                      ),
                      child: Text('${AppLocalizations.of(context)?.translate('close')}'),
                      onPressed: () {
                        tapCount++;
                        if(tapCount == 1){
                          Navigator.of(context).pop();
                        }
                      },
                    ),
                  ),
                ),
                SizedBox(width: 10),
                Expanded(
                  flex: 1,
                  child: SizedBox(
                    width: MediaQuery.of(context).orientation == Orientation.landscape ? MediaQuery.of(context).size.width / 2.5 : MediaQuery.of(context).size.width / 3,
                    height: MediaQuery.of(context).orientation == Orientation.landscape ? MediaQuery.of(context).size.height / 10 : MediaQuery.of(context).size.height / 20,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: color.backgroundColor,
                      ),
                      child: Text(AppLocalizations.of(context)!.translate('update')),
                      onPressed: () {
                        tapCount++;
                        if(tapCount == 1){
                          _submit(context);
                        }
                      },
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
      }
    });
  }

  Future<void> _submit(BuildContext context) async {
    DynamicQR? data = await PosDatabase.instance.readSpecificDynamicQRByPaperSize(receiptView);
    if(data != null){
      await updateLayout(data);
    } else {
      await createLayout();
    }
    Navigator.of(context).pop();
  }

  Future<void> updateLayout(DynamicQR currentLayout) async {
    DateFormat dateFormat = DateFormat("yyyy-MM-dd HH:mm:ss");
    String dateTime = dateFormat.format(DateTime.now());
    try{
      DynamicQR data = DynamicQR(
        branch_id: currentLayout.branch_id,
        qr_code_size: testPrintLayout!.qr_code_size,
        paper_size: receiptView,
        footer_text: testPrintLayout!.footer_text,
        sync_status: currentLayout.sync_status == 0 ? 0 : 2,
        updated_at: dateTime,
        dynamic_qr_sqlite_id: currentLayout.dynamic_qr_sqlite_id,
      );
      await PosDatabase.instance.updateDynamicQR(data);
    }catch(e){
      FLog.error(
        className: "dynamic qr receipt dialog",
        text: "dynamic qr update failed",
        exception: "$e",
      );
    }
  }

  Future<void> createLayout() async {
    try{
      DateFormat dateFormat = DateFormat("yyyy-MM-dd HH:mm:ss");
      String dateTime = dateFormat.format(DateTime.now());
      final prefs = await SharedPreferences.getInstance();
      final String? branch = prefs.getString('branch');
      var branchObject = json.decode(branch!);

      DynamicQR data = await PosDatabase.instance.insertSqliteDynamicQR(DynamicQR(
       dynamic_qr_id: 0,
       branch_id: branchObject['branchID'].toString(),
       qr_code_size: testPrintLayout!.qr_code_size,
       dynamic_qr_key: '',
       paper_size: receiptView,
       footer_text: testPrintLayout!.footer_text,
       sync_status: 0,
       created_at: dateTime,
       updated_at: '',
       soft_delete: '',
      ));
      await insertDynamicQRKey(data, dateTime);
    }catch(e) {
      FLog.error(
        className: "dynamic qr receipt dialog",
        text: "dynamic qr insert failed",
        exception: "$e",
      );
    }
  }

  Future<DynamicQR?> insertDynamicQRKey(DynamicQR dynamicQR, String dateTime) async {
    DynamicQR? returnData;
    try{
      String key = await generateDynamicQRKey(dynamicQR);
      DynamicQR data = DynamicQR(
          updated_at: dateTime,
          dynamic_qr_key: key,
          dynamic_qr_sqlite_id: dynamicQR.dynamic_qr_sqlite_id
      );
      int status =  await PosDatabase.instance.updateDynamicQRUniqueKey(data);
      if(status == 1){
        DynamicQR? updatedData = await PosDatabase.instance.readSpecificDynamicQRByKey(dynamicQR.dynamic_qr_sqlite_id.toString());
        if(updatedData != null){
          returnData = updatedData;
        }
      }
    }catch(e){
      await PosDatabase.instance.clearSpecificDynamicQr(dynamicQR.dynamic_qr_sqlite_id!);
      FLog.error(
        className: "dynamic qr receipt dialog",
        text: "dynamic qr insert key failed",
        exception: "$e",
      );
    }
    return returnData;
  }

  String generateDynamicQRKey(DynamicQR dynamicQR) {
    var bytes = dynamicQR.created_at!.replaceAll(new RegExp(r'[^0-9]'), '') + dynamicQR.dynamic_qr_sqlite_id.toString() + dynamicQR.branch_id.toString();
    var md5Hash = md5.convert(utf8.encode(bytes));
    return Utils.shortHashString(hashCode: md5Hash);
  }
}
