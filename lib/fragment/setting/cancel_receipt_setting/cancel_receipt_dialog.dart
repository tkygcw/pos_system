import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:pos_system/fragment/printing_layout/print_receipt.dart';
import 'package:pos_system/fragment/setting/cancel_receipt_setting/mm80_receipt_view.dart';
import 'package:pos_system/object/cancel_receipt.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:crypto/crypto.dart';

import '../../../database/pos_database.dart';
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
  PrintReceipt printReceipt = PrintReceipt();
  PaperSize receiptView = PaperSize.mm80;
  PosDatabase posDatabase = PosDatabase.instance;
  CancelReceipt testPrintLayout = CancelReceipt(
    product_name_font_size: 0,
    other_font_size: 0,
    show_product_sku: 0,
    show_product_price: 0
  );

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    printReceipt.readAllPrinters();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Text('Cancel receipt layout'),
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
            onSelectionChanged: (Set<PaperSize> newSelection) async{
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
        child: receiptView == PaperSize.mm80 ? mm80ReceiptView(callback: testLayout): Container(),
      ),
      actions: [
        ElevatedButton(
          onPressed: (){
            Navigator.of(context).pop();
          },
          child: Text('close'),
        ),
        ElevatedButton(
            onPressed: (){
              printReceipt.testPrintCancelReceipt(testPrintLayout);
            },
            child: Text('test print')),
        ElevatedButton(
            onPressed: (){

            }, child: Text('save'))
      ],
    );
  }
   createCancelReceipt() async {
    var db = await posDatabase.database;
    db.transaction((txn) async {
      // CancelReceipt checkData = await txn.execute('');
      var id = await txn.insert(tableCancelReceipt!, testPrintLayout.toJson());
      CancelReceipt data = testPrintLayout.copy(cancel_receipt_sqlite_id: id);
      data.cancel_receipt_key = await generateKey(data);
      await txn.update(tableCancelReceipt!, data.toJson());
    });
   }

  generateKey(CancelReceipt cancelReceipt) async {
    final prefs = await SharedPreferences.getInstance();
    final int? branch_id = prefs.getInt('branch_id');
    var bytes = cancelReceipt.created_at!.replaceAll(new RegExp(r'[^0-9]'), '') + cancelReceipt.cancel_receipt_sqlite_id.toString() + branch_id.toString();
    var md5Hash = md5.convert(utf8.encode(bytes));
    return Utils.shortHashString(hashCode: md5Hash);
  }

  testLayout(CancelReceipt layout){
    testPrintLayout = layout;
    print(jsonEncode(testPrintLayout));
  }
}
