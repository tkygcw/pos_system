import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';
import 'package:page_transition/page_transition.dart';
import 'package:pos_system/database/pos_database.dart';
import 'package:pos_system/fragment/setting/table_setting/print_dynamic_qr.dart';
import 'package:pos_system/page/progress_bar.dart';
import 'package:pos_system/utils/Utils.dart';
import 'package:provider/provider.dart';
import 'package:circular_menu/circular_menu.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:crypto/crypto.dart';

import '../../../database/domain.dart';
import '../../../notifier/theme_color.dart';
import '../../../object/table.dart';
import '../../../translation/AppLocalizations.dart';
import '../../report/print_report_page.dart';

class TableSetting extends StatefulWidget {
  const TableSetting({Key? key}) : super(key: key);

  @override
  State<TableSetting> createState() => _TableSettingState();
}

class _TableSettingState extends State<TableSetting> {
  TextEditingController dateTimeController = TextEditingController(text: Utils.formatDate(DateTime.now().toString()));
  PrintDynamicQr printDynamicQr = PrintDynamicQr();
  DateTime currentDateTime = DateTime.now();
  List<PosTable> tableList = [];
  List<PosTable> checkedTable = [];
  String btnText = "Select All";
  bool dynamicQr = false;
  bool _isLoad = false;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    getInitData();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeColor>(builder: (context, ThemeColor color, child) {
      return LayoutBuilder(builder: (context,  constraints) {
        if(constraints.maxWidth > 800) {
          return Scaffold(
            appBar: AppBar(
              automaticallyImplyLeading: false,
              title: Text(AppLocalizations.of(context)!.translate('table_qr_generate'), style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.blueGrey)),
              elevation: 0,
              actions: [
                SizedBox(
                  width: 200,
                  child: CheckboxListTile(
                      title: Container(child: Text("Dynamic QR")),
                      value: dynamicQr,
                      onChanged: (value) async {
                        setState(() {
                          dynamicQr = value!;
                          unselectAllTable();
                        });
                        await generateUrl();
                        if(dynamicQr == false){
                          currentDateTime = DateTime.now();
                          dateTimeController.text = Utils.formatDate(DateTime.now().toString());
                        }
                      }),
                ),
                Visibility(
                  visible: dynamicQr ? true : false,
                  child: SizedBox(
                    width: 200,
                    child: TextField(
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
                                onDateTimeChanged: (DateTime newDateTime) async {
                                  currentDateTime = newDateTime;
                                  await generateUrl();
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
                        // onPressed: (){
                        //   showCupertinoDialog(context: context, builder: (builder){
                        //     return AlertDialog(
                        //       title: Text("Set dynamic QR expired datetime"),
                        //       content: CupertinoDatePicker(
                        //         mode: CupertinoDatePickerMode.dateAndTime,
                        //         initialDateTime: DateTime.now(),
                        //         onDateTimeChanged: (DateTime newDateTime){
                        //         },
                        //       ),
                        //     );
                        //   });
                        // },
                        // child: Text("time picker"),
                    ),
                  ),
                ),
                Container(
                  padding: EdgeInsets.all(10),
                  width: 125,
                  child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: color.backgroundColor
                      ),
                      onPressed: (){
                        setState(() {
                          if(btnText == "Select All"){
                            for(var table in tableList){
                              if(table.isSelected == false){
                                table.isSelected = true;
                                checkedTable.add(table);
                              }
                            }
                            btnText = "Unselect";
                          } else {
                            unselectAllTable();
                            btnText = "Select All";
                          }
                        });
                      },
                      child: Text(AppLocalizations.of(context)!.translate(checkedTable.length > 0 ? 'unselect' : 'select_all'))),
                )
              ],
            ),
            resizeToAvoidBottomInset: false,
            floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
            floatingActionButton: dynamicQr ?
            FloatingActionButton(
              backgroundColor: color.backgroundColor,
              onPressed: () async {
                if(dynamicQr == true && currentDateTime.isBefore(DateTime.now())){
                  Fluttertoast.showToast(
                      backgroundColor: Color(0xFFFF0000),
                      msg: "QR expired datetime must after current datetime");
                } else {
                  if(checkedTable.isNotEmpty){
                    await syncTableDynamicToCloud();
                    await printDynamicQr.printDynamicQR(tableList: checkedTable);
                  } else {
                    Fluttertoast.showToast(
                        backgroundColor: Color(0xFFFF0000),
                        msg: "${AppLocalizations.of(context)?.translate('no_table')}");
                  }
                }
              },
              tooltip: "Print QR",
              child: const Icon(Icons.receipt),
            ) :
            CircularMenu(
                curve: Curves.decelerate,
                toggleButtonBoxShadow: [],
                toggleButtonColor: color.backgroundColor,
                items: [
                  CircularMenuItem(
                      color: color.buttonColor,
                      boxShadow: [],
                      icon: Icons.receipt,
                      onTap: () async {
                        if(checkedTable.isNotEmpty){
                          await printDynamicQr.printDynamicQR(tableList: checkedTable);
                        } else {
                          Fluttertoast.showToast(
                              backgroundColor: Color(0xFFFF0000),
                              msg: "${AppLocalizations.of(context)?.translate('no_table')}");
                        }
                      }),
                  CircularMenuItem(
                    color: color.buttonColor,
                    boxShadow: [],
                    icon: Icons.picture_as_pdf,
                    onTap: (){
                      if(dynamicQr == true && currentDateTime.isBefore(DateTime.now())){
                        Fluttertoast.showToast(
                            backgroundColor: Color(0xFFFF0000),
                            msg: "QR expired datetime must after current datetime");
                      } else {
                        if(checkedTable.isNotEmpty){
                          Navigator.push(
                            context,
                            PageTransition(
                              type: PageTransitionType.bottomToTop,
                              child: PrintReportPage(
                                currentPage: -1,
                                tableList: this.checkedTable,
                                callBack: () => getInitData(),
                              ),
                            ),
                          );
                        } else {
                          Fluttertoast.showToast(
                              backgroundColor: Color(0xFFFF0000),
                              msg: "${AppLocalizations.of(context)?.translate('no_table')}");
                        }
                      }
                    },
                  ),
                ]),
            body: _isLoad ?
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: tableList.isNotEmpty ?
              ListView.builder(
                  shrinkWrap: true,
                  itemCount: tableList.length,
                  itemBuilder: (BuildContext context,int index){
                    return Card(
                      elevation: 5,
                      child: CheckboxListTile(
                          value: tableList[index].isSelected,
                          activeColor: color.backgroundColor,
                          title: Text(AppLocalizations.of(context)!.translate('table_no') +': ${tableList[index].number}'),
                          onChanged: (value){
                            setState(() {
                              if(value!){
                                tableList[index].isSelected = true;
                                checkedTable.add(tableList[index]);
                                btnText = "Unselect";
                              } else {
                                tableList[index].isSelected = false;
                                checkedTable.remove(tableList[index]);
                              }
                              if(checkedTable.isEmpty){
                                btnText = "Select All";
                              }
                            });
                          }),
                    );
                  }
              ) : Stack(
                  children: [
                    Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.table_restaurant, size: 36.0),
                          Text(AppLocalizations.of(context)!.translate('no_table_found'), style: TextStyle(fontSize: 24)),
                        ],
                      ),
                    ),
                  ]
              )
            )
                : CustomProgressBar(),
          );
        } else {
          ///mobile layout
          return Scaffold(
            appBar: AppBar(
              primary: false,
              automaticallyImplyLeading: false,
              title: Text(AppLocalizations.of(context)!.translate('table_qr_generate'), style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.blueGrey)),
              elevation: 0,
              actions: [
                Container(
                  padding: EdgeInsets.all(10),
                  width: 125,
                  child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                          backgroundColor: color.backgroundColor
                      ),
                      onPressed: (){
                        setState(() {
                          if(btnText == "Select All"){
                            for(var table in tableList){
                              if(table.isSelected == false){
                                table.isSelected = true;
                                checkedTable.add(table);
                              }
                            }
                            btnText = "Unselect";
                          } else {
                            for(var table in tableList){
                              if(table.isSelected == true){
                                table.isSelected = false;
                                checkedTable.clear();
                              }
                            }
                            btnText = "Select All";
                          }
                        });
                      },
                      child: Text('${btnText}')),
                )
              ],
            ),
            resizeToAvoidBottomInset: false,
            floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
            floatingActionButton: FloatingActionButton(
              elevation: 5,
              backgroundColor: color.backgroundColor,
              onPressed: () {
                if(checkedTable.isNotEmpty){
                  Navigator.push(
                    context,
                    PageTransition(
                      type: PageTransitionType.bottomToTop,
                      child: PrintReportPage(
                        currentPage: -1,
                        tableList: this.checkedTable,
                        callBack: () => getInitData(),
                      ),
                    ),
                  );
                } else {
                  Fluttertoast.showToast(
                      backgroundColor: Color(0xFFFF0000),
                      msg: "${AppLocalizations.of(context)?.translate('no_table')}");
                }
              },
              tooltip: "Print QR",
              child: const Icon(Icons.print),
            ),
            body: _isLoad ?
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: tableList.isNotEmpty ?
              ListView.builder(
                  shrinkWrap: true,
                  itemCount: tableList.length,
                  itemBuilder: (BuildContext context,int index){
                    return Card(
                      elevation: 5,
                      child: CheckboxListTile(
                          value: tableList[index].isSelected,
                          activeColor: color.backgroundColor,
                          title: Text(AppLocalizations.of(context)!.translate('table_no') + ': ${tableList[index].number}'),
                          onChanged: (value){
                            setState(() {
                              if(value!){
                                tableList[index].isSelected = true;
                                checkedTable.add(tableList[index]);
                                btnText = "Unselect";
                              } else {
                                tableList[index].isSelected = false;
                                checkedTable.remove(tableList[index]);
                              }
                              if(checkedTable.isEmpty){
                                btnText = "Select All";
                              }
                            });
                          }),
                    );
                  }
              ) : Stack(
                  children: [
                    Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.table_restaurant, size: 36.0),
                          Text(AppLocalizations.of(context)!.translate('no_table_found'), style: TextStyle(fontSize: 24)),
                        ],
                      ),
                    ),
                  ]
              ),
            )
                : CustomProgressBar(),
          );
        }
      });
    });
  }

  syncTableDynamicToCloud() async {
    for(int i = 0; i < checkedTable.length; i++){
      await Domain().insertTableDynamicQr(checkedTable[i]);
    }
  }

  getInitData() async {
    this.btnText = "Select All";
    this.checkedTable.clear();
    List<PosTable> data = await PosDatabase.instance.readAllTable();
    tableList = data;
    await generateUrl();
    sortTable();
    setState(() {
      _isLoad = true;
    });
  }

  unselectAllTable(){
    for(var table in tableList){
      if(table.isSelected == true){
        table.isSelected = false;
      }
    }
    checkedTable.clear();
  }

  generateUrl() async {
    DateFormat dateFormat = DateFormat("yyyy-MM-dd HH:mm:ss");
    final prefs = await SharedPreferences.getInstance();
    final String? branch = prefs.getString('branch');
    Map branchObject = json.decode(branch!);
    if(dynamicQr){
      for(int i = 0; i < tableList.length; i++){
        final md5Hash = md5.convert(utf8.encode(currentDateTime.toString()));
        final hashCode = Utils.shortHashString(hashCode: md5Hash);
        var url = '${Domain.qr_domain}${branchObject['branch_url']}/${tableList[i].table_url}/${hashCode}';
        tableList[i].qrOrderUrl = url;
        tableList[i].dynamicQRExp = dateFormat.format(currentDateTime);
      }
    } else {
      for(int i = 0; i < tableList.length; i++){
        var url = '${Domain.qr_domain}${branchObject['branch_url']}/${tableList[i].table_url}';
        tableList[i].qrOrderUrl = url;
        tableList[i].dynamicQRExp = null;
      }
    }
  }

  sortTable(){
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
  }
}
