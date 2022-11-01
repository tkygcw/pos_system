import 'package:confirm_dialog/confirm_dialog.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';
import 'package:pos_system/database/pos_database.dart';
import 'package:pos_system/fragment/settlement/cash_dialog.dart';
import 'package:pos_system/page/progress_bar.dart';
import 'package:provider/provider.dart';

import '../../notifier/theme_color.dart';
import '../../object/cash_record.dart';
import '../../translation/AppLocalizations.dart';

class SettlementPage extends StatefulWidget {
  const SettlementPage({Key? key}) : super(key: key);

  @override
  State<SettlementPage> createState() => _SettlementPageState();
}

class _SettlementPageState extends State<SettlementPage> {
  List<CashRecord> cashRecordList = [];
  bool isLoad = false;

  @override
  void initState() {
    super.initState();
    readCashRecord();
  }


  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeColor>(builder: (context, ThemeColor color, child) {
      return Scaffold(
        body: isLoad ? Container(
          child: Padding(
              padding: EdgeInsets.all(20),
            child: SingleChildScrollView(
              child: Column(
                children: [
                  Container(
                    margin: EdgeInsets.fromLTRB(0, 0, 0, 10),
                    alignment: Alignment.topLeft,
                    child: Row(
                      children: [
                        Text(
                          "Settlement",
                          style: TextStyle(fontSize: 25),
                        ),
                        Spacer(),
                        Container(
                          width: 350,
                          child: TextField(
                            decoration: InputDecoration(
                              isDense: true,
                              border: InputBorder.none,
                              labelText: 'Search',
                              focusedBorder: OutlineInputBorder(
                                borderSide: const BorderSide(
                                    color: Colors.grey, width: 2.0),
                                borderRadius: BorderRadius.circular(25.0),
                              ),
                            ),
                          ),
                        ),
                      ],
                    )
                  ),
                  Divider(height: 10, color: Colors.grey,),
                  Container(
                    child: Row(
                      children: [
                        ElevatedButton(
                          child: Text('Cash-in'),
                          onPressed: (){
                            openCashDialog(true, false);
                          },
                          style: ElevatedButton.styleFrom(
                            primary: Colors.green
                          )
                        ),
                        Container(
                          height: 30,
                          child: VerticalDivider(color: Colors.grey, thickness: 1),
                        ),
                        ElevatedButton(
                          child: Text('Cash-out'),
                          onPressed: (){
                            openCashDialog(false, true);
                          },
                          style: ElevatedButton.styleFrom(
                            primary: Colors.red
                          ),
                        ),
                        Container(
                          height: 30,
                          child: VerticalDivider(color: Colors.grey, thickness: 1),
                        ),
                        ElevatedButton(
                          child: Text('Settlement'),
                          onPressed: (){
                            print('do settlement');
                          },
                          style: ElevatedButton.styleFrom(
                              primary: Colors.teal
                          ),
                        ),
                        // SizedBox(width: 10,),
                        Container(
                          height: 30,
                          child: VerticalDivider(color: Colors.grey, thickness: 1),
                        ),
                        ElevatedButton(
                          child: Text('Transfer ownership'),
                          onPressed: (){
                            print('do settlement');
                          },
                          style: ElevatedButton.styleFrom(
                              primary: Colors.blue
                          ),
                        )
                      ],
                    ),
                  ),
                  Divider(height: 10, color: Colors.grey,),
                  cashRecordList.length > 0 ?
                  Container(
                    height: MediaQuery.of(context).size.height / 1.6,
                    child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: cashRecordList.length,
                        itemBuilder: (context, index){
                          return ListTile(
                            leading: Icon(Icons.monetization_on),
                            title: Text('${cashRecordList[index].remark}'),
                            subtitle: cashRecordList[index].type == 1 ?
                            Text('Cash in by: ${cashRecordList[index].userName}')
                                :
                            cashRecordList[index].type == 2 ?
                            Text('Cash-out by: ${cashRecordList[index].userName}')
                                :
                            Text('close By: ${cashRecordList[index].userName}'),
                            trailing: cashRecordList[index].type == 2 ?
                            Text('-${cashRecordList[index].amount}', style: TextStyle(color: Colors.red))
                                :
                            Text('+${cashRecordList[index].amount}', style: TextStyle(color: Colors.green)),
                            onLongPress: () async {
                              if (await confirm(
                                context,
                                title: Text(
                                    '${AppLocalizations.of(context)?.translate('remove_cash_record')}'),
                                content: Text(
                                    '${AppLocalizations.of(context)?.translate('would you like to remove?')}'),
                                textOK:
                                Text('${AppLocalizations.of(context)?.translate('yes')}'),
                                textCancel:
                                Text('${AppLocalizations.of(context)?.translate('no')}'),
                              )) {
                                return removeCashRecord(cashRecordList[index]);
                              }
                            },
                          );
                        }
                    ),
                  )
                      :
                  Container(
                    alignment: Alignment.center,
                    height: MediaQuery.of(context).size.height / 1.6,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.menu),
                        Text('NO RECORD'),
                      ],
                    ),
                  ),
                  Divider(height: 10, color: Colors.grey,),
                  Container(
                    margin: EdgeInsets.all(15),
                    padding: EdgeInsets.only(right: 10),
                    alignment: Alignment.bottomRight,
                    child: Text('Total cash drawer: ${getTotalCashDrawerAmount()}')
                  ),
                  Divider(height: 10, color: Colors.grey,),
                ],
              ),
            ),
          ),
        ) : CustomProgressBar(),
      );
    });
  }

  Future<Future<Object?>> openCashDialog(bool cashIn, bool cashOut) async {
    return showGeneralDialog(
        barrierColor: Colors.black.withOpacity(0.5),
        transitionBuilder: (context, a1, a2, widget) {
          final curvedValue = Curves.easeInOutBack.transform(a1.value) - 1.0;
          return Transform(
            transform: Matrix4.translationValues(0.0, curvedValue * 200, 0.0),
            child: Opacity(
                opacity: a1.value,
                child: CashDialog(
                  isCashIn: cashIn,
                  isCashOut: cashOut,
                  callBack: () => readCashRecord(),
                ),
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

  readCashRecord() async {
    List<CashRecord> data = await PosDatabase.instance.readAllCashRecord();
    if(!cashRecordList.contains(data)){
      cashRecordList = List.from(data);
    }

    setState(() {
      isLoad = true;
    });

  }

  removeCashRecord(CashRecord cashRecord) async {
    try{
      DateFormat dateFormat = DateFormat("yyyy-MM-dd HH:mm:ss");
      String dateTime = dateFormat.format(DateTime.now());
      CashRecord cashRecordObject = CashRecord(
          sync_status: 0,
          soft_delete: dateTime,
          cash_record_sqlite_id: cashRecord.cash_record_sqlite_id
      );
      int data = await PosDatabase.instance.deleteCashRecord(cashRecordObject);
      await readCashRecord();
    }catch(e){
      Fluttertoast.showToast(
          backgroundColor: Color(0xFFFF0000),
          msg: "Delete cash record error: ${e}");
    }
  }
  
  getTotalCashDrawerAmount(){
    try{
      double totalCashIn = 0.0;
      double totalCashOut = 0.0;
      double totalCashDrawer = 0.0;
      for(int i = 0; i < cashRecordList.length; i++){
        if(cashRecordList[i].type == 1 && cashRecordList[i].payment_type_id == ''){
          totalCashIn += double.parse(cashRecordList[i].amount!);
        } else if(cashRecordList[i].type == 2 && cashRecordList[i].payment_type_id == '') {
          totalCashOut += double.parse(cashRecordList[i].amount!);
        }
      }
      print('total cash in: ${totalCashIn}');
      print('total cash out: ${totalCashOut}');
      totalCashDrawer = totalCashIn - totalCashOut;
      print('total cash drawer: $totalCashDrawer');
      return totalCashDrawer.toStringAsFixed(2);
    }catch(e){
      Fluttertoast.showToast(
          backgroundColor: Color(0xFFFF0000),
          msg: "get cash drawer error: ${e}");
      return 0.0;
    }
  }
}
