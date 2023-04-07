

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:grouped_list/grouped_list.dart';
import 'package:pos_system/database/pos_database.dart';
import 'package:pos_system/page/progress_bar.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../notifier/theme_color.dart';
import '../../object/cash_record.dart';
import '../../translation/AppLocalizations.dart';

class HistoryDialog extends StatefulWidget {
  const HistoryDialog({Key? key}) : super(key: key);

  @override
  State<HistoryDialog> createState() => _HistoryDialogState();
}

class _HistoryDialogState extends State<HistoryDialog> {
  List<CashRecord> cashRecordList =[];
  late String jsonList = jsonEncode(cashRecordList);
  bool isLoaded = false;
  bool isButtonDisabled = false;


  @override
  void initState() {
    super.initState();
    //readPaymentLinkCompany();
    readCashRecord();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeColor>(builder: (context, ThemeColor color, child) {
      return LayoutBuilder(builder: (context, constraints) {
        if(constraints.maxWidth > 800){
          return AlertDialog(
            title: Text('Cash Record History'),
            content: isLoaded ?
            Container(
              height: MediaQuery.of(context).size.height / 2,
              width: MediaQuery.of(context).size.width / 2,
              child: Column(
                children: [
                  Container(
                    height: MediaQuery.of(context).size.height / 2,
                    child: //GroupedListView<dynamic, String>(
                    //   shrinkWrap: true,
                    //     elements: cashRecordList,
                    //     groupBy: (e) {
                    //     String something = '';
                    //     for(int i = 0; i < cashRecordList.length; i++){
                    //       something = cashRecordList[i].settlement_date!;
                    //     }
                    //       return something;
                    //     },
                    //   groupComparator: (value1, value2) => value2.compareTo(value1),
                    //   useStickyGroupSeparators: true,
                    //   groupSeparatorBuilder: (String value) => Container(
                    //     child: Padding(
                    //       padding: EdgeInsets.fromLTRB(380, 10, 380, 8),
                    //       child: Container(
                    //         decoration: BoxDecoration(
                    //           borderRadius: BorderRadius.circular(4),
                    //           color: color.backgroundColor,
                    //         ),
                    //         child: Text(
                    //           value,
                    //           textAlign: TextAlign.center,
                    //           style: TextStyle(fontSize: 18, color: color.iconColor, fontWeight: FontWeight.bold),
                    //         ),
                    //       ),
                    //     ),
                    //   ),
                    //   itemBuilder: (c, index) {
                    //     return ListTile(
                    //       title: Text(index.remark!),
                    //     );
                    //     //   ListTile(
                    //     //   leading: cashRecordList[index].payment_type_id == '1' || cashRecordList[index].payment_type_id == ''
                    //     //       ? Icon(Icons.payments_sharp)
                    //     //       : cashRecordList[index].payment_type_id == '2'
                    //     //       ? Icon(Icons.credit_card_rounded)
                    //     //       : Icon(Icons.wifi),
                    //     //   title: Text(
                    //     //       '${cashRecordList[index].remark}'),
                    //     //   subtitle: cashRecordList[index].type == 1
                    //     //       ? Text(
                    //     //       'Cash in by: ${cashRecordList[index].userName}')
                    //     //       : cashRecordList[index].type == 2
                    //     //       ? Text(
                    //     //       'Cash-out by: ${cashRecordList[index].userName}')
                    //     //       : Text(
                    //     //       'close By: ${cashRecordList[index].userName}'),
                    //     //   trailing: cashRecordList[index].type == 2
                    //     //       ? Text(
                    //     //       '-${cashRecordList[index].amount}',
                    //     //       style: TextStyle(
                    //     //           color: Colors.red))
                    //     //       : Text(
                    //     //       '+${cashRecordList[index].amount}',
                    //     //       style: TextStyle(
                    //     //           color: Colors.green)),
                    //     // );
                    //   },
                    // ),
                    cashRecordList.length > 0 ? ListView.builder(
                        shrinkWrap: true,
                        itemCount: cashRecordList.length,
                        itemBuilder: (context, index) {
                          return ListTile(
                            isThreeLine: true,
                            leading: cashRecordList[index].payment_type_id == '1' || cashRecordList[index].payment_type_id == ''
                                ? Icon(Icons.payments_sharp)
                                : cashRecordList[index].payment_type_id == '2'
                                ? Icon(Icons.credit_card_rounded)
                                : Icon(Icons.wifi),
                            title: Text(
                                '${cashRecordList[index].remark}'),
                            subtitle: cashRecordList[index].type == 1
                                ? Text(
                                'Cash in by: ${cashRecordList[index].userName}\nDate Time: ${cashRecordList[index].created_at}')
                                : cashRecordList[index].type == 2
                                ? Text(
                                'Cash-out by: ${cashRecordList[index].userName}\nDate Time: ${cashRecordList[index].created_at}')
                                : Text(
                                'Close By: ${cashRecordList[index].userName}\nDate Time: ${cashRecordList[index].created_at}'),
                            trailing: cashRecordList[index].type == 2 || cashRecordList[index].type == 4
                                ? Text(
                                '-${cashRecordList[index].amount}',
                                style: TextStyle(
                                    color: Colors.red))
                                : Text(
                                '+${cashRecordList[index].amount}',
                                style: TextStyle(
                                    color: Colors.green)),
                          );
                        }) : Container(
                      alignment: Alignment.center,
                      height: MediaQuery.of(context).size.height / 1.7,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.list, size: 28),
                          Text('NO RECORD', style: TextStyle(fontSize: 16)),
                        ],
                      ),
                    ),
                  )
                ],
              ),
            ) : CustomProgressBar(),
            actions: [
              TextButton(
                child: Text('${AppLocalizations.of(context)?.translate('close')}'),
                onPressed: isButtonDisabled ? null : () {
                  // Disable the button after it has been pressed
                  setState(() {
                    isButtonDisabled = true;
                  });
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        } else {
          ///mobile layout
          return AlertDialog(
            title: Text('Settlement History'),
            content: isLoaded ?
            Container(
              height: MediaQuery.of(context).size.height / 2,
              width: MediaQuery.of(context).size.width / 1.5,
              child: cashRecordList.isNotEmpty ?
              ListView.builder(
                  shrinkWrap: true,
                  itemCount: cashRecordList.length,
                  itemBuilder: (context, index) {
                    return ListTile(
                      leading: cashRecordList[index].payment_type_id == '1' || cashRecordList[index].payment_type_id == ''
                          ? Icon(Icons.payments_sharp)
                          : cashRecordList[index].payment_type_id == '2'
                          ? Icon(Icons.credit_card_rounded)
                          : Icon(Icons.wifi),
                      title: Text(
                          '${cashRecordList[index].remark}'),
                      subtitle: cashRecordList[index].type == 1
                          ? Text(
                          'Cash in by: ${cashRecordList[index].userName}')
                          : cashRecordList[index].type == 2
                          ? Text(
                          'Cash-out by: ${cashRecordList[index].userName}')
                          : Text(
                          'close By: ${cashRecordList[index].userName}'),
                      trailing: cashRecordList[index].type == 2 || cashRecordList[index].type == 4
                          ? Text(
                          '-${cashRecordList[index].amount}',
                          style: TextStyle(
                              color: Colors.red))
                          : Text(
                          '+${cashRecordList[index].amount}',
                          style: TextStyle(
                              color: Colors.green)),
                    );
                  }) :
              Stack(
                  children: [
                    Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.list, size: 36.0),
                          Text('NO RECORD', style: TextStyle(fontSize: 24)),
                        ],
                      ),
                    ),
                  ]
              )
            ) : CustomProgressBar(),
            actions: [
              TextButton(
                child: Text('${AppLocalizations.of(context)?.translate('close')}'),
                onPressed: isButtonDisabled ? null : () {
                  // Disable the button after it has been pressed
                  setState(() {
                    isButtonDisabled = true;
                  });
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        }
      });
    });
  }

  readCashRecord() async {
    cashRecordList.clear();
    final prefs = await SharedPreferences.getInstance();
    final int? branch_id = prefs.getInt('branch_id');

    List<CashRecord> data = await PosDatabase.instance.readAllBranchSettlementCashRecord(branch_id.toString());
    print('settlement data: ${data.length}');
    cashRecordList = data;
    print('cash list: ${cashRecordList.length}');
    setState(() {
      isLoaded = true;
    });
  }
}
