import 'package:flutter/material.dart';
import 'package:pos_system/database/pos_database.dart';
import 'package:pos_system/fragment/printing_layout/print_receipt.dart';
import 'package:pos_system/page/progress_bar.dart';

import '../../object/printer.dart';
import '../../object/settlement.dart';
import '../../translation/AppLocalizations.dart';
import '../../utils/Utils.dart';

class ReprintSettlementDialog extends StatefulWidget {
  const ReprintSettlementDialog({Key? key}) : super(key: key);

  @override
  State<ReprintSettlementDialog> createState() => _ReprintSettlementDialogState();
}

class _ReprintSettlementDialogState extends State<ReprintSettlementDialog> {
  List<Settlement> settlementList = [];
  List<Printer> printerList = [];
  @override
  void initState() {
    // TODO: implement initState
    getPrinter();
    super.initState();
  }
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(AppLocalizations.of(context)!.translate('reprint_settlement')),
      content: FutureBuilder(
          future: getLatest7RowsSettlement(),
          builder: (context, snapshot){
            if(snapshot.hasData){
              return SizedBox(
                width: 350.0,
                child: settlementList.isNotEmpty ?
                Scrollbar(
                  thumbVisibility: true,
                  trackVisibility: true,
                  radius: Radius.circular(5.0),
                  child: ListView.builder(
                    shrinkWrap: true,
                      itemCount: settlementList.length,
                      itemBuilder: (context, index){
                        return Card(
                          elevation: 5,
                          child: ListTile(
                            leading: CircleAvatar(
                                backgroundColor: Colors.grey.shade200,
                                child: Icon(
                                  Icons.receipt,
                                  color: Colors.grey,
                                )),
                            title: Text(Utils.formatDate(settlementList[index].created_at!)),
                            onTap: () async{
                                await PrintReceipt().printSettlementList(printerList, settlementList[index].created_at!, settlementList[index]);
                            },
                          ),
                        );
                      }),
                ) :
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.menu),
                      Text(AppLocalizations.of(context)!.translate('no_record_found')),
                    ],
                  ),
                ),
              );
            } else {
              return CustomProgressBar();
            }
          }),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: Text(AppLocalizations.of(context)!.translate('close')),
        ),
      ],
    );
  }

  getPrinter()async {
    printerList = await PrintReceipt().readAllPrinters();
  }

  getLatest7RowsSettlement() async {
    List<Settlement> data = await PosDatabase.instance.readLatest7Settlement();
    settlementList = data;
    return settlementList;
  }
}
