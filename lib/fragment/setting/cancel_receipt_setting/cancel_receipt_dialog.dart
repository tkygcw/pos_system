import 'dart:convert';

import 'package:f_logs/model/flog/flog.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';
import 'package:pos_system/fragment/printing_layout/print_receipt.dart';
import 'package:pos_system/fragment/setting/cancel_receipt_setting/mobile_view/mm58_receipt_view.dart';
import 'package:pos_system/fragment/setting/cancel_receipt_setting/mobile_view/mm80_receipt_view.dart';
import 'package:pos_system/fragment/setting/cancel_receipt_setting/tablet_view/mm58_receipt_view.dart';
import 'package:pos_system/fragment/setting/cancel_receipt_setting/tablet_view/mm80_receipt_view.dart';
import 'package:pos_system/notifier/theme_color.dart';
import 'package:pos_system/object/cancel_receipt.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:crypto/crypto.dart';

import '../../../database/pos_database.dart';
import '../../../translation/AppLocalizations.dart';
import '../../../utils/Utils.dart';

enum PaperSize {
  mm80,
  mm58
}

class CancelReceiptDialog extends StatefulWidget {
  const CancelReceiptDialog({Key? key}) : super(key: key);

  @override
  State<CancelReceiptDialog> createState() => _CancelReceiptDialogState();
}

class _CancelReceiptDialogState extends State<CancelReceiptDialog> {
  final DateFormat dateFormat = DateFormat("yyyy-MM-dd HH:mm:ss");
  PrintReceipt printReceipt = PrintReceipt();
  PaperSize receiptView = PaperSize.mm80;
  PosDatabase posDatabase = PosDatabase.instance;
  CancelReceipt testPrintLayout = Utils.defaultCancelReceiptLayout().copy(
    paper_size: '80',
  );
  bool _isButtonDisabled = false;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    printReceipt.readAllPrinters();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    var color = context.watch<ThemeColor>();
    if(screenWidth > 900 && screenHeight > 500){
      return SafeArea(
        child: AlertDialog(
          title: Row(
            children: [
              Text(AppLocalizations.of(context)!.translate('cancel_receipt_layout')),
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
                segments: <ButtonSegment<PaperSize>>[
                  ButtonSegment(value: PaperSize.mm80, label: Text("80mm")),
                  ButtonSegment(value: PaperSize.mm58, label: Text("58mm"))
                ],
                onSelectionChanged: (Set<PaperSize> newSelection) {
                  setState(() {
                    receiptView = newSelection.first;
                  });
                },
                selected: <PaperSize>{receiptView},
              ),
            ],
          ),
          content: Container(
            width: MediaQuery.of(context).size.width / 1.5,
            child: receiptView == PaperSize.mm80 ?
            mm80ReceiptView(callback: testLayout) : mm58ReceiptView(callback: testLayout),
          ),
          actions: [
            SizedBox(
              width: MediaQuery.of(context).size.width / 4,
              height: MediaQuery.of(context).size.height / 12,
              child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: color.backgroundColor,
                  ),
                  onPressed: () async {
                    int status = await printReceipt.testPrintCancelReceipt(testPrintLayout);
                    if(status != 0){
                      Fluttertoast.showToast(
                          backgroundColor: Colors.red,
                          msg: "${AppLocalizations.of(context)?.translate('no_cashier_printer')}");
                    }
                  },
                  child: Text(AppLocalizations.of(context)!.translate('test_print')),
              ),
            ),
            SizedBox(
              width: MediaQuery.of(context).size.width / 4,
              height: MediaQuery.of(context).size.height / 12,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                ),
                onPressed: _isButtonDisabled ? null : () {
                  setState(() {
                    _isButtonDisabled = true;
                  });
                  Navigator.of(context).pop();
                },
                child: Text(AppLocalizations.of(context)!.translate('close')),
              ),
            ),
            SizedBox(
              width: MediaQuery.of(context).size.width / 4,
              height: MediaQuery.of(context).size.height / 12,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: color.backgroundColor,
                ),
                onPressed: _isButtonDisabled ? null : () async {
                  setState(() {
                    _isButtonDisabled = true;
                  });
                  await createCancelReceipt();
                  Navigator.of(context).pop();
                },
                child: Text(AppLocalizations.of(context)!.translate('save')),
              ),
            ),
            // ElevatedButton(
            //   onPressed: () async {
            //     await deleteCancelReceipt();
            //     Navigator.of(context).pop();
            //   },
            //   child: Text('delete'),
            // )
          ],
        ),
      );
    } else {
      return SafeArea(
        child: AlertDialog(
          title:Text(AppLocalizations.of(context)!.translate('cancel_receipt_layout')),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
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
                    segments: <ButtonSegment<PaperSize>>[
                      ButtonSegment(value: PaperSize.mm80, label: Text("80mm")),
                      ButtonSegment(value: PaperSize.mm58, label: Text("58mm"))
                    ],
                    onSelectionChanged: (Set<PaperSize> newSelection) {
                      setState(() {
                        receiptView = newSelection.first;
                      });
                    },
                    selected: <PaperSize>{receiptView},
                  ),
                ),
                SizedBox(height: 10),
                SizedBox(
                  width: 500,
                  child: receiptView == PaperSize.mm80 ?
                  mm80MobileReceiptView(callback: testLayout) : mm58MobileReceiptView(callback: testLayout),
                )
              ],
            ),
          ),
          actions: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Expanded(
                  child: SizedBox(
                    width: MediaQuery.of(context).orientation == Orientation.landscape ? MediaQuery.of(context).size.width / 2.5 : MediaQuery.of(context).size.width / 3,
                    height: MediaQuery.of(context).orientation == Orientation.landscape ? MediaQuery.of(context).size.height / 10 : MediaQuery.of(context).size.height / 20,
                    child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: color.backgroundColor,
                        ),
                        onPressed: () {
                          printReceipt.testPrintCancelReceipt(testPrintLayout);
                        },
                        child: Text('test')),
                  ),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: SizedBox(
                    width: MediaQuery.of(context).orientation == Orientation.landscape ? MediaQuery.of(context).size.width / 2.5 : MediaQuery.of(context).size.width / 3,
                    height: MediaQuery.of(context).orientation == Orientation.landscape ? MediaQuery.of(context).size.height / 10 : MediaQuery.of(context).size.height / 20,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                      ),
                      onPressed: _isButtonDisabled ? null : () {
                        setState(() {
                          _isButtonDisabled = true;
                        });
                        Navigator.of(context).pop();
                      },
                      child: Text('close'),
                    ),
                  ),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: SizedBox(
                    width: MediaQuery.of(context).orientation == Orientation.landscape ? MediaQuery.of(context).size.width / 2.5 : MediaQuery.of(context).size.width / 3,
                    height: MediaQuery.of(context).orientation == Orientation.landscape ? MediaQuery.of(context).size.height / 10 : MediaQuery.of(context).size.height / 20,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: color.backgroundColor,
                      ),
                      onPressed: _isButtonDisabled ? null : () async {
                        setState(() {
                          _isButtonDisabled = true;
                        });
                        await createCancelReceipt();
                        Navigator.of(context).pop();
                      },
                      child: Text(AppLocalizations.of(context)!.translate('save')),
                    ),
                  ),
                ),
              ],
            )
          ],
        ),
      );
    }
  }
  
  deleteCancelReceipt() async {
    var db = await posDatabase.database;
    db.transaction((txn) async {
      await txn.rawDelete('DELETE FROM $tableCancelReceipt');
    });
  }

   createCancelReceipt() async {
     String paperSize = receiptView == PaperSize.mm80 ? '80':'58';
     String dateTime = dateFormat.format(DateTime.now());
     var db = await posDatabase.database;
     final prefs = await SharedPreferences.getInstance();
     final int? branch_id = prefs.getInt('branch_id');
     if(branch_id == null){
       return;
     }
     db.transaction((txn) async {
       final existingReceipt = await _fetchExistingReceipt(txn, paperSize);
       if(existingReceipt != null){
         await _updateCancelReceipt(txn, existingReceipt, dateTime);
       } else {
         await _createCancelReceipt(txn, branch_id, dateTime);
       }
     });
   }

  generateKey(CancelReceipt cancelReceipt, int branch_id) async {
    var bytes = cancelReceipt.created_at!.replaceAll(new RegExp(r'[^0-9]'), '') + cancelReceipt.cancel_receipt_sqlite_id.toString() + branch_id.toString();
    var md5Hash = md5.convert(utf8.encode(bytes));
    return Utils.shortHashString(hashCode: md5Hash);
  }

  Future<void> _createCancelReceipt(txn, int branchId, String dateTime) async {
    try{
      CancelReceipt insertData = testPrintLayout.copy(
        cancel_receipt_id: 0,
        cancel_receipt_key: '',
        branch_id: branchId.toString(),
        sync_status: 0,
        created_at: dateTime,
        updated_at: dateTime,
        soft_delete: '',
      );
      var id = await txn.insert(tableCancelReceipt!, insertData.toJson());
      insertData.cancel_receipt_sqlite_id = id;
      insertData.cancel_receipt_key = await generateKey(insertData, branchId);
      await txn.rawUpdate('UPDATE $tableCancelReceipt SET cancel_receipt_key = ?, updated_at = ? WHERE cancel_receipt_sqlite_id = ?', [
        insertData.cancel_receipt_key,
        insertData.updated_at,
        insertData.cancel_receipt_sqlite_id,
      ]);
    }catch(e, stackTrace){
      FLog.error(
        className: "cancel_receipt_dialog",
        text: "create cancel receipt error",
        exception: "Error: $e, StackTrace: $stackTrace",
      );
      rethrow;
    }
  }

  /// Updates the existing cancel receipt with new data.
  Future<void> _updateCancelReceipt(txn, CancelReceipt currentLayout, String dateTime) async {
    try{
      final updatedData = testPrintLayout.copy(
        sync_status: currentLayout.sync_status == 0 ? 0 : 1,
        updated_at: dateTime,
        cancel_receipt_sqlite_id: currentLayout.cancel_receipt_sqlite_id,
      );

      await txn.rawUpdate(
        'UPDATE $tableCancelReceipt SET '
            'product_name_font_size = ?, other_font_size = ?, show_product_sku = ?, '
            'show_product_price = ?, updated_at = ? WHERE cancel_receipt_sqlite_id = ?',
        [
          updatedData.product_name_font_size,
          updatedData.other_font_size,
          updatedData.show_product_sku,
          updatedData.show_product_price,
          updatedData.updated_at,
          updatedData.cancel_receipt_sqlite_id,
        ],
      );
    }catch(e, stackTrace){
      FLog.error(
        className: "cancel_receipt_dialog",
        text: "update cancel receipt error",
        exception: "$e, $stackTrace",
      );
      rethrow;
    }
  }

  /// Fetches the existing receipt layout for the given paper size.
  Future<CancelReceipt?> _fetchExistingReceipt(txn, String paperSize) async {
    try{
      final result = await txn.rawQuery(
        'SELECT * FROM $tableCancelReceipt WHERE soft_delete = ? AND paper_size = ?',
        ['', paperSize],
      );
      return result.isNotEmpty ? CancelReceipt.fromJson(result.first) : null;
    }catch(e, stackTrace){
      FLog.error(
        className: "cancel_receipt_dialog",
        text: "fetch Existing Receipt error",
        exception: "$e, $stackTrace",
      );
      rethrow;
    }
  }

  testLayout(CancelReceipt layout){
    testPrintLayout = layout;
    print(jsonEncode(testPrintLayout));
  }
}
