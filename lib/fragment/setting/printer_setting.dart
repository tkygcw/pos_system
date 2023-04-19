import 'dart:convert';

import 'package:confirm_dialog/confirm_dialog.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';
import 'package:pos_system/fragment/setting/printer_dialog.dart';
import 'package:pos_system/object/printer.dart';
import 'package:pos_system/object/printer_link_category.dart';
import 'package:pos_system/page/progress_bar.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';


import '../../database/domain.dart';
import '../../database/pos_database.dart';
import '../../notifier/theme_color.dart';
import '../../object/print_receipt.dart';
import '../../translation/AppLocalizations.dart';

class PrinterSetting extends StatefulWidget {
  const PrinterSetting({Key? key}) : super(key: key);

  @override
  _PrinterSettingState createState() => _PrinterSettingState();
}

class _PrinterSettingState extends State<PrinterSetting> {
  String? printer_value, printer_category_value;
  bool isLoaded = false;
  List<Printer> printerList = [];

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    readAllPrinters();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeColor>(builder: (context, ThemeColor color, child) {
      return LayoutBuilder(builder: (context,  constraints) {
        if(constraints.maxWidth > 800){
          return isLoaded ?
          Scaffold(
            resizeToAvoidBottomInset: false,
            floatingActionButton: FloatingActionButton(
              backgroundColor: color.backgroundColor,
              onPressed: () {
                openPrinterDialog(null);
              },
              tooltip: "Add Printer",
              child: const Icon(Icons.add),
            ),
            body: Padding(
              padding: const EdgeInsets.all(8.0),
              child: printerList.isNotEmpty ?
              ListView.builder(
                  shrinkWrap: true,
                  itemCount: printerList.length,
                  itemBuilder: (BuildContext context,int index){
                    return Card(
                      elevation: 5,
                      child: ListTile(
                        isThreeLine: true,
                        //contentPadding: EdgeInsets.all(10),
                        leading: CircleAvatar(backgroundColor: Colors.grey.shade200,child: Icon(Icons.print, color: Colors.grey,)),
                        title:Text("${printerList[index].printer_label}", style: TextStyle(color: Colors.blueGrey, fontWeight: FontWeight.bold)),
                        subtitle: printerList[index].type == 0
                            ?
                        Text("Type: USB")
                            :
                        Text('Type: LAN\nIP: ${jsonDecode(printerList[index].value!)} '),
                        trailing: Container(
                          child: FittedBox(
                            child: printerList[index].type == 0 ? Icon(Icons.usb) : Icon(Icons.wifi),
                          ),
                        ),
                        onLongPress: () async {
                          if (await confirm(
                            context,
                            title: Text(
                                '${AppLocalizations.of(context)?.translate('remove_printer')}'),
                            content: Text(
                                '${AppLocalizations.of(context)?.translate('would you like to remove?')}'),
                            textOK:
                            Text('${AppLocalizations.of(context)?.translate('yes')}'),
                            textCancel:
                            Text('${AppLocalizations.of(context)?.translate('no')}'),
                          )) {
                            return callClearAllPrinterRecord(printerList[index]);
                          }
                        },
                        onTap: (){
                          openPrinterDialog(printerList[index]);
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
                          Icon(Icons.print_disabled, size: 36.0),
                          Text('NO PRINTER', style: TextStyle(fontSize: 24)),
                        ],
                      ),
                    ),
                  ]
              ),
            ),
          ) : CustomProgressBar();
        } else {
          ///mobile layout
          return isLoaded ?
          Scaffold(
            resizeToAvoidBottomInset: false,
            floatingActionButton: FloatingActionButton(
              backgroundColor: color.backgroundColor,
              onPressed: () {
                openPrinterDialog(null);
              },
              tooltip: "Add Printer",
              child: const Icon(Icons.add),
            ),
            body: Padding(
              padding: const EdgeInsets.all(8.0),
              child: printerList.length > 0 ?
              ListView.builder(
                  shrinkWrap: true,
                  itemCount: printerList.length,
                  itemBuilder: (BuildContext context,int index){
                    return Card(
                      elevation: 5,
                      child: ListTile(
                        contentPadding: EdgeInsets.all(10),
                        leading: CircleAvatar(backgroundColor: Colors.grey.shade200,child: Icon(Icons.print, color: Colors.grey,)),
                        title:Text("${printerList[index].printer_label}", style: TextStyle(color: Colors.blueGrey, fontWeight: FontWeight.bold)),
                        subtitle: printerList[index].type == 0 ? Text("Type: USB") : Text('Type: LAN\nIP: ${jsonDecode(printerList[index].value!)} '),
                        trailing: Container(
                          child: FittedBox(
                            child: printerList[index].type == 0 ? Icon(Icons.usb) : Icon(Icons.wifi),
                          ),
                        ),
                        onLongPress: () async {
                          if (await confirm(
                            context,
                            title: Text(
                                '${AppLocalizations.of(context)?.translate('remove_printer')}'),
                            content: Text(
                                '${AppLocalizations.of(context)?.translate('would you like to remove?')}'),
                            textOK:
                            Text('${AppLocalizations.of(context)?.translate('yes')}'),
                            textCancel:
                            Text('${AppLocalizations.of(context)?.translate('no')}'),
                          )) {
                            return callClearAllPrinterRecord(printerList[index]);
                          }
                        },
                        onTap: (){
                          openPrinterDialog(printerList[index]);
                        },
                      ),
                    );
                  }
              ) : Container(
                alignment: Alignment.center,
                height:
                MediaQuery.of(context).size.height / 1.7,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.print_disabled, size: 36.0),
                    Text('NO PRINTER', style: TextStyle(fontSize: 24)),
                  ],
                ),
              ),
            ),
          ) : CustomProgressBar();
        }
      });

    });
  }

  readAllPrinters() async {
    printerList = await PrintReceipt().readAllPrinters();

    setState(() {
      isLoaded = true;
    });

  }

  callClearAllPrinterRecord(Printer printer) async {
    await removePrinter(printer);
    if(printer.is_counter == 0){
      await clearPrinterCategory(printer);
    }
    if(printer.type == 1){
      syncAllToCloud();
    }
  }

  removePrinter(Printer printer) async {
    try{
      List<String?> _value = [];
      DateFormat dateFormat = DateFormat("yyyy-MM-dd HH:mm:ss");
      String dateTime = dateFormat.format(DateTime.now());

      int data = await PosDatabase.instance.deletePrinter(Printer(
          soft_delete: dateTime,
          sync_status: printer.type == 0 ? 1 : 2,
          printer_sqlite_id: printer.printer_sqlite_id
      ));
      Printer printerData = await PosDatabase.instance.readSpecificPrinterByLocalId(printer.printer_sqlite_id!);
      _value.add(jsonEncode(printerData));
      this.printer_value = _value.toString();
      await readAllPrinters();
    }catch(e){
      Fluttertoast.showToast(
          backgroundColor: Color(0xFFFF0000),
          msg: "Something went wrong, Please try again $e");
    }
  }

  clearPrinterCategory(Printer printer) async {
    try{
      List<String?> _value = [];
      DateFormat dateFormat = DateFormat("yyyy-MM-dd HH:mm:ss");
      String dateTime = dateFormat.format(DateTime.now());

      int data = await PosDatabase.instance.deletePrinterCategory(PrinterLinkCategory(
        soft_delete: dateTime,
        sync_status: printer.type == 0 ? 1 : 2,
        printer_sqlite_id: printer.printer_sqlite_id.toString()
      ));
      if(printer.type == 1){
        List<PrinterLinkCategory> printerCategoryList = await PosDatabase.instance.readDeletedPrinterLinkCategory(printer.printer_sqlite_id!);
        for(int i = 0 ; i < printerCategoryList.length; i++){
          _value.add(jsonEncode(printerCategoryList[i]));
        }
      }
      this.printer_category_value = _value.toString();
    }catch(e){
      Fluttertoast.showToast(
          backgroundColor: Color(0xFFFF0000),
          msg: "Clear printer category, Please try again $e");
    }
  }

  syncAllToCloud() async {
    final prefs = await SharedPreferences.getInstance();
    final int? device_id = prefs.getInt('device_id');
    final String? login_value = prefs.getString('login_value');
    bool _hasInternetAccess = await Domain().isHostReachable();
    if (_hasInternetAccess) {
      Map data = await Domain().syncLocalUpdateToCloud(
          device_id: device_id.toString(),
          value: login_value,
          printer_value: this.printer_value,
          printer_link_category_value: this.printer_category_value
      );
      if(data['status'] == '1'){
        List responseJson = data['data'];
        for(int i = 0; i < responseJson.length; i++) {
          switch (responseJson[i]['table_name']) {
            case 'tb_printer': {
              await PosDatabase.instance.updatePrinterSyncStatusFromCloud(responseJson[i]['printer_key']);
            }
            break;
            case 'tb_printer_link_category': {
              await PosDatabase.instance.updatePrinterLinkCategorySyncStatusFromCloud(responseJson[i]['printer_link_category_key']);
            }
            break;
            default:
              return;
          }
        }
      }
    }
  }


  Future<Future<Object?>> openPrinterDialog(Printer? printer) async {
    return showGeneralDialog(
        barrierColor: Colors.black.withOpacity(0.5),
        transitionBuilder: (context, a1, a2, widget) {
          final curvedValue = Curves.easeInOutBack.transform(a1.value) - 1.0;
          return Transform(
            transform: Matrix4.translationValues(0.0, curvedValue * 200, 0.0),
            child: Opacity(
                opacity: a1.value,
                child: PrinterDialog(
                  printerObject: printer,
                  callBack: () => readAllPrinters(),
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
