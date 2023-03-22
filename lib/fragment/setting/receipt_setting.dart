import 'package:confirm_dialog/confirm_dialog.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';
import 'package:pos_system/database/pos_database.dart';
import 'package:pos_system/fragment/setting/receipt_dialog.dart';
import 'package:pos_system/page/progress_bar.dart';
import 'package:provider/provider.dart';

import '../../notifier/theme_color.dart';
import '../../object/receipt.dart';
import '../../translation/AppLocalizations.dart';

class ReceiptSetting extends StatefulWidget {
  const ReceiptSetting({Key? key}) : super(key: key);

  @override
  State<ReceiptSetting> createState() => _ReceiptSettingState();
}

class _ReceiptSettingState extends State<ReceiptSetting> {
  int saved = 0;
  List<Receipt> receiptList = [];
  bool isLoad = false;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    readAllReceiptLayout();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeColor>(builder: (context, ThemeColor color, child) {
      return LayoutBuilder(builder: (context,  constraints) {
        if(constraints.maxWidth > 800){
          return Scaffold(
            floatingActionButton: FloatingActionButton(
                    backgroundColor: color.backgroundColor,
                    onPressed: () {
                      openReceiptDialog(null, receiptList);
                    },
                    tooltip: "Add Receipt layout",
                    child: const Icon(Icons.add),
                  ),
            body: isLoad ? Padding(
              padding: EdgeInsets.all(8),
              child: receiptList.length > 0 ?
              ListView.builder(
                  shrinkWrap: true,
                  itemCount: receiptList.length,
                  itemBuilder: (BuildContext context,int index){
                    return Card(
                      shape: receiptList[index].status == 1
                          ? new RoundedRectangleBorder(
                          side: new BorderSide(color: color.backgroundColor, width: 3.0),
                          borderRadius: BorderRadius.circular(4.0))
                          : new RoundedRectangleBorder(
                          side: new BorderSide(color: Colors.white, width: 3.0),
                          borderRadius: BorderRadius.circular(4.0)),
                      elevation: 5,
                      child: ListTile(
                        title: Text('Layout ${index +1}'),
                        leading: CircleAvatar(backgroundColor: Colors.grey.shade200,child: Icon(Icons.receipt, color: Colors.grey,)),
                        onTap: () {
                          openReceiptDialog(receiptList[index], receiptList);
                        },
                        onLongPress: () async {
                          if (await confirm(
                            context,
                            title: Text(
                                '${AppLocalizations.of(context)?.translate('remove_layout')}'),
                            content: Text(
                                '${AppLocalizations.of(context)?.translate('would you like to remove?')}'),
                            textOK:
                            Text('${AppLocalizations.of(context)?.translate('yes')}'),
                            textCancel:
                            Text('${AppLocalizations.of(context)?.translate('no')}'),
                          )) {
                            return callRemoveLayout(receiptList[index]);
                          }
                        },
                      ),
                    );
                  }
              ) : Stack(
                  children: [
                    Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.receipt, size: 36.0),
                          Text('NO LAYOUT', style: TextStyle(fontSize: 24)),
                        ],
                      ),
                    ),
                  ]
              ),
            ) : CustomProgressBar(),

          );
        } else {
          ///mobile layout
          return Scaffold(
            resizeToAvoidBottomInset: true,
            floatingActionButton: FloatingActionButton(
              backgroundColor: color.backgroundColor,
              onPressed: () {
                openReceiptDialog(null, receiptList);
              },
              tooltip: "Add Receipt layout",
              child: const Icon(Icons.add),
            ),
            body: isLoad ? Padding(
              padding: EdgeInsets.all(8),
              child: receiptList.length > 0 ?
              ListView.builder(
                  shrinkWrap: true,
                  itemCount: receiptList.length,
                  itemBuilder: (BuildContext context, int index){
                    return Card(
                      shape: receiptList[index].status == 1
                          ? new RoundedRectangleBorder(
                          side: new BorderSide(color: color.backgroundColor, width: 3.0),
                          borderRadius: BorderRadius.circular(4.0))
                          : new RoundedRectangleBorder(
                          side: new BorderSide(color: Colors.white, width: 3.0),
                          borderRadius: BorderRadius.circular(4.0)),
                      elevation: 5,
                      child: ListTile(
                        title: Text('Layout ${index +1}'),
                        leading: CircleAvatar(backgroundColor: Colors.grey.shade200,child: Icon(Icons.receipt, color: Colors.grey,)),
                        onTap: () {
                          openReceiptDialog(receiptList[index], receiptList);
                        },
                        onLongPress: () async {
                          if (await confirm(
                            context,
                            title: Text(
                                '${AppLocalizations.of(context)?.translate('remove_layout')}'),
                            content: Text(
                                '${AppLocalizations.of(context)?.translate('would you like to remove?')}'),
                            textOK:
                            Text('${AppLocalizations.of(context)?.translate('yes')}'),
                            textCancel:
                            Text('${AppLocalizations.of(context)?.translate('no')}'),
                          )) {
                            return callRemoveLayout(receiptList[index]);
                          }
                        },
                      ),
                    );
                  }
              ) : Center(
                child: Stack(
                  children: [
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.receipt, size: 36.0),
                        Text('NO LAYOUT', style: TextStyle(fontSize: 24)),
                      ],
                    ),
                  ]
                ),
              ),
            ) : CustomProgressBar(),

          );
        }
      });

    });
  }
  
  callRemoveLayout(Receipt receipt) async {
    await deleteLayout(receipt);
    await readAllReceiptLayout();
  }

  readAllReceiptLayout() async {
    List<Receipt> data = await PosDatabase.instance.readAllReceipt();
    if(!receiptList.contains(data)){
      receiptList = List.from(data);
    }
    setState(() {
      isLoad = true;
    });
  }

  deleteLayout(Receipt receipt) async {
   try{
     DateFormat dateFormat = DateFormat("yyyy-MM-dd HH:mm:ss");
     String dateTime = dateFormat.format(DateTime.now());
     if(receipt.status == 0){
       int data = await PosDatabase.instance.deleteReceiptLayout(Receipt(
           sync_status: 0,
           soft_delete: dateTime,
           receipt_sqlite_id: receipt.receipt_sqlite_id
       ));
     } else {
       Fluttertoast.showToast(
           backgroundColor: Color(0xFFFF0000),
           msg: "Cannot remove in-use layout");
     }
   }catch(e){
     Fluttertoast.showToast(
         backgroundColor: Color(0xFFFF0000),
         msg: "${AppLocalizations.of(context)?.translate('remove_layout_error')}, $e");
   }

  }

  Future<Future<Object?>> openReceiptDialog(Receipt? receipt, List<Receipt> allReceipt) async {
    return showGeneralDialog(
        barrierColor: Colors.black.withOpacity(0.5),
        transitionBuilder: (context, a1, a2, widget) {
          final curvedValue = Curves.easeInOutBack.transform(a1.value) - 1.0;
          return Transform(
            transform: Matrix4.translationValues(0.0, curvedValue * 200, 0.0),
            child: Opacity(
                opacity: a1.value,
                child: ReceiptDialog(
                  allReceiptList: allReceipt,
                  receiptObject: receipt,
                  callBack: () => readAllReceiptLayout(),
                )
            ),
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
