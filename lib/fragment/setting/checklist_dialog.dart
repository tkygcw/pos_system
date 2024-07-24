import 'dart:async';
import 'dart:convert';

import 'package:dotted_line/dotted_line.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';
import 'package:pos_system/object/checklist.dart';
import 'package:pos_system/object/printer.dart';
import 'package:pos_system/page/progress_bar.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:crypto/crypto.dart';

import '../../database/domain.dart';
import '../../database/pos_database.dart';
import '../../enumClass/receipt_dialog_enum.dart';
import '../../main.dart';
import '../../notifier/theme_color.dart';
import '../../object/print_receipt.dart';
import '../../translation/AppLocalizations.dart';
import '../../utils/Utils.dart';
import '../logout_dialog.dart';

class ChecklistDialog extends StatefulWidget {
  const ChecklistDialog({Key? key}) : super(key: key);

  @override
  State<ChecklistDialog> createState() => _ChecklistDialogState();
}

class _ChecklistDialogState extends State<ChecklistDialog> {
  StreamController actionController = StreamController();
  StreamController contentController = StreamController();
  late Stream contentStream;
  late Stream actionStream;
  final defaultFontSize = 14.0;
  Checklist testPrintLayout = Checklist();
  Checklist? checklist;
  ReceiptDialogEnum? productFontSize, variantAddonFontSize;
  String checklistView = "80";
  String? checklist_value;
  double? fontSize, otherFontSize;
  bool isButtonDisabled = false, submitted = false, checkListShowPrice = false, checkListItemSeparator = false;
  List<Printer> cashierPrinter = [];

  @override
  void initState() {
    // TODO: implement initState
    contentStream = contentController.stream.asBroadcastStream();
    actionStream = actionController.stream.asBroadcastStream();
    listenAction();
    super.initState();
  }

  @override
  void dispose() {
    actionController.close();
    super.dispose();
  }

  listenAction(){
    actionController.sink.add("init");
    actionStream.listen((event) async  {
      switch(event){
        case 'init':{
          await getAllCashierPrinter();
          await readChecklistLayout();
          contentController.sink.add("refresh");
        }
        break;
        case 'view':{
          await readChecklistLayout();
          contentController.sink.add("refresh");
        }
        break;
        case 'switch':{
          contentController.sink.add("refresh");
        }
        break;
      }
    });
  }

  readChecklistLayout() async {
    try{
      Checklist? data = await PosDatabase.instance.readSpecificChecklist(checklistView);
      print("data: $data");
      if(data != null){
        checklist = data;
        productFontSize = data.product_name_font_size == 0 ? ReceiptDialogEnum.big : ReceiptDialogEnum.small;
        fontSize = data.product_name_font_size == 0 ? 20 : 14;
        variantAddonFontSize = data.other_font_size == 0 ? ReceiptDialogEnum.big : ReceiptDialogEnum.small;
        otherFontSize = data.other_font_size == 0 ? 20 : 14;
        checkListShowPrice = data.check_list_show_price == 0 ? false : true;
        checkListItemSeparator = data.check_list_show_separator == 0 ? false : true;
      } else {
        checklist = null;
        productFontSize = ReceiptDialogEnum.small;
        fontSize = 14;
        variantAddonFontSize = ReceiptDialogEnum.small;
        otherFontSize = 14;
        checkListShowPrice = false;
        checkListItemSeparator = false;
      }
    } catch(e){
      print("read check list layout error: $e");
    }
  }

  getAllCashierPrinter() async {
    try{
      List<Printer> printerList = await PrintReceipt().readAllPrinters();
      cashierPrinter = printerList.where((printer) => printer.is_counter == 1).toList();
    } catch(e){
      print("get all cashier printer error: $e");
      cashierPrinter = [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeColor>(builder: (context, ThemeColor color, child) {
      return LayoutBuilder(builder: (context,  constraints) {
        if(constraints.maxWidth > 800){
          return AlertDialog(
            title: Text(AppLocalizations.of(context)!.translate('check_list_layout')),
            content: StreamBuilder(
              stream: contentStream,
                builder: (context, snapshot){
                  if(snapshot.hasData){
                    return Container(
                      height: 500,
                      width: 850,
                      child: SingleChildScrollView(
                          child: Column(
                            children: [
                              Align(
                                alignment: Alignment.topLeft,
                                child: SegmentedButton(
                                  style: ButtonStyle(
                                      side: MaterialStateProperty.all(
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
                                    checklistView = newSelection.first;
                                    actionController.sink.add("view");

                                  },
                                  selected: <String>{checklistView},
                                ),
                              ),
                              SizedBox(height: 10),
                              checklistView == "80" ?
                              ReceiptView1(color) :
                              ReceiptView2(color),

                            ],
                          )
                      ),
                    );
                  } else {
                    //mobile layout
                    return CustomProgressBar();
                  }
                }
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
                  onPressed: () {
                    if(cashierPrinter.isNotEmpty){
                      testLayout();
                      PrintReceipt().printTestPrintChecklist(cashierPrinter, testPrintLayout, testPrintLayout.paper_size!);
                    } else {
                      Fluttertoast.showToast(msg: "No cashier printer added");
                    }
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
                  onPressed: isButtonDisabled ? null : () {
                    setState(() {
                      isButtonDisabled = true;
                    });
                    closeDialog(context);
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
                  onPressed: isButtonDisabled ? null : () {
                    setState(() {
                      isButtonDisabled = true;
                    });
                    _submit(context);
                  },
                ),
              ),
            ],
          );
        } else {
          ///mobile layout
          return AlertDialog(
            title: Text(AppLocalizations.of(context)!.translate('check_list_layout')),
            titlePadding: EdgeInsets.fromLTRB(24, 16, 24, 0),
            contentPadding: EdgeInsets.fromLTRB(24, 16, 24, 5),
            content: StreamBuilder(
                stream: contentStream,
                builder: (context, snapshot){
                  if(snapshot.hasData){
                    return Container(
                      height: MediaQuery.of(context).size.height /2,
                      width: 500 ,
                      child: SingleChildScrollView(
                          child: Column(
                            children: [
                              Align(
                                alignment: Alignment.topLeft,
                                child: SegmentedButton(
                                  style: ButtonStyle(
                                      side: MaterialStateProperty.all(
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
                                    checklistView = newSelection.first;
                                    actionController.sink.add("view");

                                  },
                                  selected: <String>{checklistView},
                                ),
                              ),
                              SizedBox(height: 10),
                              checklistView == "80" ?
                              mobileView1(color) :
                              mobileView2(color),

                            ],
                          )
                      ),
                    );
                  } else {
                    return CustomProgressBar();
                  }
                }
            ),
            actions: [
              SizedBox(
                width: MediaQuery.of(context).size.width / 4,
                height: MediaQuery.of(context).size.height / 10,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: color.backgroundColor,
                  ),
                  child: Text(AppLocalizations.of(context)!.translate('test_print')),
                  onPressed: () {
                    if(cashierPrinter.isNotEmpty){
                      testLayout();
                      PrintReceipt().printTestPrintChecklist(cashierPrinter, testPrintLayout, testPrintLayout.paper_size!);
                    } else {
                      Fluttertoast.showToast(msg: "No cashier printer added");
                    }
                  },
                ),
              ),
              SizedBox(
                width: MediaQuery.of(context).size.width / 4,
                height: MediaQuery.of(context).size.height / 10,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                  ),
                  child: Text('${AppLocalizations.of(context)?.translate('close')}'),
                  onPressed: isButtonDisabled ? null : () {
                    setState(() {
                      isButtonDisabled = true;
                    });
                    closeDialog(context);
                  },
                ),
              ),
              SizedBox(
                width: MediaQuery.of(context).size.width / 4,
                height: MediaQuery.of(context).size.height / 10,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: color.backgroundColor,
                  ),
                  child: Text(AppLocalizations.of(context)!.translate('update')),
                  onPressed: isButtonDisabled ? null : () {
                    setState(() {
                      isButtonDisabled = true;
                    });
                    _submit(context);
                  },
                ),
              ),
            ],
          );
        }
      });
    });
  }

  updateChecklist() async {
    List<String> value = [];
    DateFormat dateFormat = DateFormat("yyyy-MM-dd HH:mm:ss");
    String dateTime = dateFormat.format(DateTime.now());
    try{
      Checklist? checkData = await PosDatabase.instance.readSpecificChecklistByKey(checklist!.checklist_key!);
      if(checkData != null){
        Checklist data = Checklist(
          product_name_font_size: productFontSize == ReceiptDialogEnum.big ? 0 : 1,
          other_font_size: variantAddonFontSize == ReceiptDialogEnum.big ? 0 : 1,
          check_list_show_price: checkListShowPrice == true ? 1: 0,
          check_list_show_separator: checkListItemSeparator == true ? 1: 0,
          sync_status: checkData.sync_status == 0 ? 0 : 2,
          updated_at: dateTime,
          checklist_sqlite_id: checklist!.checklist_sqlite_id,
        );
        int status = await PosDatabase.instance.updateChecklist(data);
        if(status == 1){
          Checklist? returnData = await PosDatabase.instance.readSpecificChecklistByKey(checklist!.checklist_key!);
          if(returnData != null){
            value.add(jsonEncode(returnData));
          }
        }
      }
      checklist_value = value.toString();
      print("checklist value: ${checklist_value}");
    }catch(e){
      print("update check list error: $e");
      checklist_value = null;
    }
  }

  createChecklist() async {
    List<String> value = [];
    try{
      DateFormat dateFormat = DateFormat("yyyy-MM-dd HH:mm:ss");
      String dateTime = dateFormat.format(DateTime.now());
      final prefs = await SharedPreferences.getInstance();
      final String? branch = prefs.getString('branch');
      var branchObject = json.decode(branch!);

      Checklist data = await PosDatabase.instance.insertSqliteChecklist(Checklist(
        checklist_id: 0,
        checklist_key: '',
        branch_id: branchObject['branchID'].toString(),
        product_name_font_size: productFontSize == ReceiptDialogEnum.big ? 0 : 1,
        other_font_size: variantAddonFontSize == ReceiptDialogEnum.big ? 0 : 1,
        check_list_show_price: checkListShowPrice == true ? 1 : 0,
        check_list_show_separator: checkListItemSeparator == true ? 1 : 0,
        paper_size: checklistView,
        sync_status: 0,
        created_at: dateTime,
        updated_at: '',
        soft_delete: '',
      ));
      Checklist? returnData = await insertChecklistKey(data, dateTime);
      if(returnData != null){
        value.add(jsonEncode(returnData));
      }
      checklist_value = value.toString();
      print("checklist value: ${checklist_value}");
    }catch(e) {
      print("create checklist error: ${e}");
      checklist_value = null;
    }
  }

  insertChecklistKey(Checklist checklist, String dateTime) async {
    Checklist? returnData;
    String key = await generateChecklistKey(checklist);
    Checklist data = Checklist(
        updated_at: dateTime,
        sync_status: 0,
        checklist_key: key,
        checklist_sqlite_id: checklist.checklist_sqlite_id
    );
   int status =  await PosDatabase.instance.updateChecklistUniqueKey(data);
   if(status == 1){
     Checklist? checkData = await PosDatabase.instance.readSpecificChecklistByKey(data.checklist_key!);
     if(checkData != null){
       returnData = checkData;
     }
   }
   return returnData;
  }

  generateChecklistKey(Checklist checklist) async {
    final prefs = await SharedPreferences.getInstance();
    final int? branch_id = prefs.getInt('branch_id');
    var bytes = checklist.created_at!.replaceAll(new RegExp(r'[^0-9]'), '') + checklist.checklist_sqlite_id.toString() + branch_id.toString();
    var md5Hash = md5.convert(utf8.encode(bytes));
    return Utils.shortHashString(hashCode: md5Hash);
  }

  Future<void> _submit(BuildContext context) async {
    setState(() => submitted = true);
    if(checklist != null){
      await updateChecklist();
    } else {
      await createChecklist();
    }
    await syncAllToCloud();
    closeDialog(context);

  }

  testLayout(){
    testPrintLayout = Checklist(
      product_name_font_size: productFontSize == ReceiptDialogEnum.big ? 0 : 1,
      other_font_size: variantAddonFontSize == ReceiptDialogEnum.big ? 0 : 1,
      check_list_show_price: checkListShowPrice == true ? 1: 0,
      check_list_show_separator: checkListItemSeparator == true ? 1: 0,
      paper_size: checklistView
    );
  }

  closeDialog(BuildContext context) {
    return Navigator.of(context).pop(true);
  }

  syncAllToCloud() async {
    try{
      if(mainSyncToCloud.count == 0){
        mainSyncToCloud.count = 1;
        final prefs = await SharedPreferences.getInstance();
        final int? device_id = prefs.getInt('device_id');
        final String? login_value = prefs.getString('login_value');
        Map data = await Domain().syncLocalUpdateToCloud(
          device_id: device_id.toString(),
          value: login_value,
          checklist_value: checklist_value,
        );
        if (data['status'] == '1') {
          List responseJson = data['data'];
          await PosDatabase.instance.updateChecklistSyncStatusFromCloud(responseJson[0]['checklist_key']);
          mainSyncToCloud.resetCount();
        }else if(data['status'] == '7'){
          mainSyncToCloud.resetCount();
          //this.isLogOut = true;
          openLogOutDialog();
          return;
        }else if (data['status'] == '8'){
          print('checklist setting timeout');
          mainSyncToCloud.resetCount();
          throw TimeoutException("Time out");
        } else {
          mainSyncToCloud.resetCount();
        }
      }
    }catch(e){
      mainSyncToCloud.resetCount();
    }
  }

  Future<Future<Object?>> openLogOutDialog() async {
    return showGeneralDialog(
        barrierColor: Colors.black.withOpacity(0.5),
        transitionBuilder: (context, a1, a2, widget) {
          final curvedValue = Curves.easeInOutBack.transform(a1.value) - 1.0;
          return Transform(
            transform: Matrix4.translationValues(0.0, curvedValue * 200, 0.0),
            child: Opacity(
              opacity: a1.value,
              child: LogoutConfirmDialog(),
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

  Widget ReceiptView1(ThemeColor color) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Expanded(
          flex: 1,
          child: Container(
            decoration: BoxDecoration(
                border: Border.all(color: Colors.blueGrey, style: BorderStyle.solid, width: 1)
            ),
            padding: MediaQuery.of(context).size.width > 1300 ? EdgeInsets.fromLTRB(40, 20, 40, 20) : EdgeInsets.fromLTRB(20, 20, 20, 20) ,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Table No: 5", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24.0)),
                Text("Batch No: #123456-005"),
                Text("Order by: Demo"),
                Text("Order time: DD/MM/YY hh:mm PM"),
                Padding(
                  padding: EdgeInsets.only(top: 10, bottom: 10),
                  child: DottedLine(),
                ),
                Column(
                  children: [
                    Row(
                      children: [
                        Text("1", style: TextStyle(fontWeight: FontWeight.bold, fontSize: defaultFontSize)),
                        SizedBox(width: 30),
                        Text("Product 1 ${checkListShowPrice ? "(6.90/each)" : ''}", style: TextStyle(fontWeight: FontWeight.bold, fontSize: fontSize)),
                      ],
                    ),
                    Visibility(
                      visible: checkListItemSeparator,
                      child: Padding(
                        padding: EdgeInsets.only(top: 20, bottom: 10),
                        child: DottedLine(),
                      ),
                    ),
                    Row(
                      children: [
                        Text("1", style: TextStyle(fontWeight: FontWeight.bold, fontSize: defaultFontSize)),
                        SizedBox(width: 30),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: EdgeInsets.only(top: 5),
                              child: Text("Product 2 ${checkListShowPrice ? "(8.80/each)" : ''}", style: TextStyle(fontWeight: FontWeight.bold, fontSize: fontSize)),
                            ),
                            Text("**Remark", style: TextStyle(fontSize: otherFontSize)),
                          ],
                        )
                      ],
                    ),
                    Visibility(
                      visible: checkListItemSeparator,
                      child: Padding(
                        padding: EdgeInsets.only(top: 20, bottom: 10),
                        child: DottedLine(),
                      ),
                    ),
                    Row(
                      children: [
                        Text("1", style: TextStyle(fontWeight: FontWeight.bold, fontSize: defaultFontSize)),
                        SizedBox(width: 30),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: EdgeInsets.only(top: 5),
                              child: Text("Product 3 ${checkListShowPrice ? "(3.50/each)" : ''}", style: TextStyle(fontWeight: FontWeight.bold, fontSize: fontSize)),
                            ),
                            Text("(big | small)", style: TextStyle(fontSize: otherFontSize)),
                          ],
                        )
                      ],
                    ),
                    Visibility(
                      visible: checkListItemSeparator,
                      child: Padding(
                        padding: EdgeInsets.only(top: 20, bottom: 10),
                        child: DottedLine(),
                      ),
                    ),
                    Row(
                      children: [
                        Text("1", style: TextStyle(fontWeight: FontWeight.bold, fontSize: defaultFontSize)),
                        SizedBox(width: 30),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: EdgeInsets.only(top: 5),
                              child: Text("Product 4 ${checkListShowPrice ? "(15.90/each)" : ''}", style: TextStyle(fontWeight: FontWeight.bold, fontSize: fontSize)),
                            ),
                            Text("+add-on1", style: TextStyle(fontSize: otherFontSize)),
                          ],
                        )
                      ],
                    ),
                    Visibility(
                      visible: checkListItemSeparator,
                      child: Padding(
                        padding: EdgeInsets.only(top: 20, bottom: 10),
                        child: DottedLine(),
                      ),
                    ),
                    Row(
                      children: [
                        Text("1", style: TextStyle(fontWeight: FontWeight.bold, fontSize: defaultFontSize)),
                        SizedBox(width: 30),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Product 5 ${checkListShowPrice ? "(10.90/each)" : ''}", style: TextStyle(fontWeight: FontWeight.bold, fontSize: fontSize)),
                            Text("(big | small)", style: TextStyle(fontSize: otherFontSize)),
                            Text("+add-on2", style: TextStyle(fontSize: otherFontSize))
                          ],
                        )
                      ],
                    )
                  ],
                )
              ],
            ),
          ),
      ),
      SizedBox(width: 25),
      Expanded(
        flex: 1,
        child: Column(
          children: [
            Container(
              alignment: Alignment.topLeft,
              child: Text(AppLocalizations.of(context)!.translate('product_name_font_size'), style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey)),
            ),
            RadioListTile<ReceiptDialogEnum?>(
              value: ReceiptDialogEnum.big,
              groupValue: productFontSize,
              onChanged: (value) async  {
                productFontSize = value;
                fontSize = 20.0;
                actionController.sink.add("switch");
              },
              title: Text(AppLocalizations.of(context)!.translate('big')),
              controlAffinity: ListTileControlAffinity.trailing,
            ),
            RadioListTile<ReceiptDialogEnum?>(
              value: ReceiptDialogEnum.small,
              groupValue: productFontSize,
              onChanged: (value) async  {
                productFontSize = value;
                fontSize = 14.0;
                actionController.sink.add("switch");
              },
              title: Text(AppLocalizations.of(context)!.translate('small')),
              controlAffinity: ListTileControlAffinity.trailing,
            ),
            Container(
              alignment: Alignment.topLeft,
              child: Text(AppLocalizations.of(context)!.translate('other_font_size'), style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey)),
            ),
            RadioListTile<ReceiptDialogEnum?>(
              value: ReceiptDialogEnum.big,
              groupValue: variantAddonFontSize,
              onChanged: (value) async  {
                variantAddonFontSize = value;
                otherFontSize = 20.0;
                actionController.sink.add("switch");
              },
              title: Text(AppLocalizations.of(context)!.translate('big')),
              controlAffinity: ListTileControlAffinity.trailing,
            ),
            RadioListTile<ReceiptDialogEnum?>(
              value: ReceiptDialogEnum.small,
              groupValue: variantAddonFontSize,
              onChanged: (value) async  {
                variantAddonFontSize = value;
                otherFontSize = 14.0;
                actionController.sink.add("switch");
              },
              title: Text(AppLocalizations.of(context)!.translate('small')),
              controlAffinity: ListTileControlAffinity.trailing,
            ),
            Container(
              alignment: Alignment.topLeft,
              child: Text(AppLocalizations.of(context)!.translate('check_list_setting'), style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey)),
            ),
            ListTile(
              title: Text(AppLocalizations.of(context)!.translate('check_list_show_price')),
              subtitle: Text(AppLocalizations.of(context)!.translate('check_list_show_price_desc')),
              trailing: Switch(
                value: checkListShowPrice,
                activeColor: color.backgroundColor,
                onChanged: (value) async {
                  checkListShowPrice = value;
                  actionController.sink.add("switch");
                },
              ),
            ),
            ListTile(
              title: Text(AppLocalizations.of(context)!.translate('check_list_item_separator')),
              subtitle: Text(AppLocalizations.of(context)!.translate('check_list_item_separator_desc')),
              trailing: Switch(
                value: checkListItemSeparator,
                activeColor: color.backgroundColor,
                onChanged: (value) async {
                  checkListItemSeparator = value;
                  actionController.sink.add("switch");
                },
              ),
            ),
          ],
        ),
      ),
    ],
  );

  Widget ReceiptView2(ThemeColor color) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Expanded(
        flex: 1,
        child: Container(
          decoration: BoxDecoration(
              border: Border.all(color: Colors.blueGrey, style: BorderStyle.solid, width: 1)
          ),
          padding: MediaQuery.of(context).size.width > 1300 ? EdgeInsets.fromLTRB(40, 20, 40, 20) : EdgeInsets.fromLTRB(20, 20, 20, 20) ,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text("Table No: 5", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24.0)),
              Text("Batch No"),
              Text("#123456-005"),
              Text("Order by"),
              Text("Demo"),
              Text("Order time"),
              Text("DD/MM/YY hh:mm PM"),
              Padding(
                padding: EdgeInsets.only(top: 10, bottom: 10),
                child: DottedLine(),
              ),
              Column(
                children: [
                  Row(
                    children: [
                      Text("1", style: TextStyle(fontWeight: FontWeight.bold, fontSize: defaultFontSize)),
                      SizedBox(width: 30),
                      Text("Product 1 ${checkListShowPrice ? "(6.90/each)" : ''}", style: TextStyle(fontWeight: FontWeight.bold, fontSize: fontSize)),
                    ],
                  ),
                  Visibility(
                    visible: checkListItemSeparator,
                    child: Padding(
                      padding: EdgeInsets.only(top: 20, bottom: 10),
                      child: DottedLine(),
                    ),
                  ),
                  Row(
                    children: [
                      Text("1", style: TextStyle(fontWeight: FontWeight.bold, fontSize: defaultFontSize)),
                      SizedBox(width: 30),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: EdgeInsets.only(top: 5),
                            child: Text("Product 2 ${checkListShowPrice ? "(8.80/each)" : ''}", style: TextStyle(fontWeight: FontWeight.bold, fontSize: fontSize)),
                          ),
                          Text("**Remark", style: TextStyle(fontSize: otherFontSize)),
                        ],
                      )
                    ],
                  ),
                  Visibility(
                    visible: checkListItemSeparator,
                    child: Padding(
                      padding: EdgeInsets.only(top: 20, bottom: 10),
                      child: DottedLine(),
                    ),
                  ),
                  Row(
                    children: [
                      Text("1", style: TextStyle(fontWeight: FontWeight.bold, fontSize: defaultFontSize)),
                      SizedBox(width: 30),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: EdgeInsets.only(top: 5),
                            child: Text("Product 3 ${checkListShowPrice ? "(3.50/each)" : ''}", style: TextStyle(fontWeight: FontWeight.bold, fontSize: fontSize)),
                          ),
                          Text("(big | small)", style: TextStyle(fontSize: otherFontSize)),
                        ],
                      )
                    ],
                  ),
                  Visibility(
                    visible: checkListItemSeparator,
                    child: Padding(
                      padding: EdgeInsets.only(top: 20, bottom: 10),
                      child: DottedLine(),
                    ),
                  ),
                  Row(
                    children: [
                      Text("1", style: TextStyle(fontWeight: FontWeight.bold, fontSize: defaultFontSize)),
                      SizedBox(width: 30),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: EdgeInsets.only(top: 5),
                            child: Text("Product 4 ${checkListShowPrice ? "(15.90/each)" : ''}", style: TextStyle(fontWeight: FontWeight.bold, fontSize: fontSize)),
                          ),
                          Text("+add-on1", style: TextStyle(fontSize: otherFontSize)),
                        ],
                      )
                    ],
                  ),
                  Visibility(
                    visible: checkListItemSeparator,
                    child: Padding(
                      padding: EdgeInsets.only(top: 20, bottom: 10),
                      child: DottedLine(),
                    ),
                  ),
                  Row(
                    children: [
                      Text("1", style: TextStyle(fontWeight: FontWeight.bold, fontSize: defaultFontSize)),
                      SizedBox(width: 30),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Product 5 ${checkListShowPrice ? "(10.90/each)" : ''}", style: TextStyle(fontWeight: FontWeight.bold, fontSize: fontSize)),
                          Text("(big | small)", style: TextStyle(fontSize: otherFontSize)),
                          Text("+add-on2", style: TextStyle(fontSize: otherFontSize))
                        ],
                      )
                    ],
                  )
                ],
              )
            ],
          ),
        ),
      ),
      SizedBox(width: 25),
      Expanded(
        flex: 1,
        child: Column(
          children: [
            Container(
              alignment: Alignment.topLeft,
              child: Text(AppLocalizations.of(context)!.translate('product_name_font_size'), style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey)),
            ),
            RadioListTile<ReceiptDialogEnum?>(
              value: ReceiptDialogEnum.big,
              groupValue: productFontSize,
              onChanged: (value) async  {
                productFontSize = value;
                fontSize = 20.0;
                actionController.sink.add("switch");
              },
              title: Text(AppLocalizations.of(context)!.translate('big')),
              controlAffinity: ListTileControlAffinity.trailing,
            ),
            RadioListTile<ReceiptDialogEnum?>(
              value: ReceiptDialogEnum.small,
              groupValue: productFontSize,
              onChanged: (value) async  {
                productFontSize = value;
                fontSize = 14.0;
                actionController.sink.add("switch");
              },
              title: Text(AppLocalizations.of(context)!.translate('small')),
              controlAffinity: ListTileControlAffinity.trailing,
            ),
            Container(
              alignment: Alignment.topLeft,
              child: Text(AppLocalizations.of(context)!.translate('other_font_size'), style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey)),
            ),
            RadioListTile<ReceiptDialogEnum?>(
              value: ReceiptDialogEnum.big,
              groupValue: variantAddonFontSize,
              onChanged: (value) async  {
                variantAddonFontSize = value;
                otherFontSize = 20.0;
                actionController.sink.add("switch");
              },
              title: Text(AppLocalizations.of(context)!.translate('big')),
              controlAffinity: ListTileControlAffinity.trailing,
            ),
            RadioListTile<ReceiptDialogEnum?>(
              value: ReceiptDialogEnum.small,
              groupValue: variantAddonFontSize,
              onChanged: (value) async  {
                variantAddonFontSize = value;
                otherFontSize = 14.0;
                actionController.sink.add("switch");
              },
              title: Text(AppLocalizations.of(context)!.translate('small')),
              controlAffinity: ListTileControlAffinity.trailing,
            ),
            Container(
              alignment: Alignment.topLeft,
              child: Text(AppLocalizations.of(context)!.translate('check_list_setting'), style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey)),
            ),
            ListTile(
              title: Text(AppLocalizations.of(context)!.translate('check_list_show_price')),
              subtitle: Text(AppLocalizations.of(context)!.translate('check_list_show_price_desc')),
              trailing: Switch(
                value: checkListShowPrice,
                activeColor: color.backgroundColor,
                onChanged: (value) async {
                  checkListShowPrice = value;
                  actionController.sink.add("switch");
                },
              ),
            ),
            ListTile(
              title: Text(AppLocalizations.of(context)!.translate('check_list_item_separator')),
              subtitle: Text(AppLocalizations.of(context)!.translate('check_list_item_separator_desc')),
              trailing: Switch(
                value: checkListItemSeparator,
                activeColor: color.backgroundColor,
                onChanged: (value) async {
                  checkListItemSeparator = value;
                  actionController.sink.add("switch");
                },
              ),
            ),
          ],
        ),
      ),
    ],
  );

  Widget mobileView1(ThemeColor color) => Column(
    children: [
      Container(
        alignment: Alignment.topLeft,
        child: Text(AppLocalizations.of(context)!.translate('product_name_font_size'), style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey)),
      ),
      RadioListTile<ReceiptDialogEnum?>(
        value: ReceiptDialogEnum.big,
        groupValue: productFontSize,
        onChanged: (value) async  {
          productFontSize = value;
          fontSize = 20.0;
          actionController.sink.add("switch");
        },
        title: Text(AppLocalizations.of(context)!.translate('big')),
        controlAffinity: ListTileControlAffinity.trailing,
      ),
      RadioListTile<ReceiptDialogEnum?>(
        value: ReceiptDialogEnum.small,
        groupValue: productFontSize,
        onChanged: (value) async  {
          productFontSize = value;
          fontSize = 14.0;
          actionController.sink.add("switch");
        },
        title: Text(AppLocalizations.of(context)!.translate('small')),
        controlAffinity: ListTileControlAffinity.trailing,
      ),
      Container(
        alignment: Alignment.topLeft,
        child: Text(AppLocalizations.of(context)!.translate('other_font_size'), style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey)),
      ),
      RadioListTile<ReceiptDialogEnum?>(
        value: ReceiptDialogEnum.big,
        groupValue: variantAddonFontSize,
        onChanged: (value) async  {
          variantAddonFontSize = value;
          otherFontSize = 20.0;
          actionController.sink.add("switch");
        },
        title: Text(AppLocalizations.of(context)!.translate('big')),
        controlAffinity: ListTileControlAffinity.trailing,
      ),
      RadioListTile<ReceiptDialogEnum?>(
        value: ReceiptDialogEnum.small,
        groupValue: variantAddonFontSize,
        onChanged: (value) async  {
          variantAddonFontSize = value;
          otherFontSize = 14.0;
          actionController.sink.add("switch");
        },
        title: Text(AppLocalizations.of(context)!.translate('small')),
        controlAffinity: ListTileControlAffinity.trailing,
      ),
      Container(
        alignment: Alignment.topLeft,
        child: Text(AppLocalizations.of(context)!.translate('check_list_setting'), style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey)),
      ),
      ListTile(
        title: Text(AppLocalizations.of(context)!.translate('check_list_show_price')),
        subtitle: Text(AppLocalizations.of(context)!.translate('check_list_show_price_desc')),
        trailing: Switch(
          value: checkListShowPrice,
          activeColor: color.backgroundColor,
          onChanged: (value) async {
            checkListShowPrice = value;
            actionController.sink.add("switch");
          },
        ),
      ),
      ListTile(
        title: Text(AppLocalizations.of(context)!.translate('check_list_item_separator')),
        subtitle: Text(AppLocalizations.of(context)!.translate('check_list_item_separator_desc')),
        trailing: Switch(
          value: checkListItemSeparator,
          activeColor: color.backgroundColor,
          onChanged: (value) async {
            checkListItemSeparator = value;
            actionController.sink.add("switch");
          },
        ),
      ),
    ],
  );

  Widget mobileView2(ThemeColor color) => Column(
    children: [
      Container(
        alignment: Alignment.topLeft,
        child: Text(AppLocalizations.of(context)!.translate('product_name_font_size'), style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey)),
      ),
      RadioListTile<ReceiptDialogEnum?>(
        value: ReceiptDialogEnum.big,
        groupValue: productFontSize,
        onChanged: (value) async  {
          productFontSize = value;
          fontSize = 20.0;
          actionController.sink.add("switch");
        },
        title: Text(AppLocalizations.of(context)!.translate('big')),
        controlAffinity: ListTileControlAffinity.trailing,
      ),
      RadioListTile<ReceiptDialogEnum?>(
        value: ReceiptDialogEnum.small,
        groupValue: productFontSize,
        onChanged: (value) async  {
          productFontSize = value;
          fontSize = 14.0;
          actionController.sink.add("switch");
        },
        title: Text(AppLocalizations.of(context)!.translate('small')),
        controlAffinity: ListTileControlAffinity.trailing,
      ),
      Container(
        alignment: Alignment.topLeft,
        child: Text(AppLocalizations.of(context)!.translate('other_font_size'), style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey)),
      ),
      RadioListTile<ReceiptDialogEnum?>(
        value: ReceiptDialogEnum.big,
        groupValue: variantAddonFontSize,
        onChanged: (value) async  {
          variantAddonFontSize = value;
          otherFontSize = 20.0;
          actionController.sink.add("switch");
        },
        title: Text(AppLocalizations.of(context)!.translate('big')),
        controlAffinity: ListTileControlAffinity.trailing,
      ),
      RadioListTile<ReceiptDialogEnum?>(
        value: ReceiptDialogEnum.small,
        groupValue: variantAddonFontSize,
        onChanged: (value) async  {
          variantAddonFontSize = value;
          otherFontSize = 14.0;
          actionController.sink.add("switch");
        },
        title: Text(AppLocalizations.of(context)!.translate('small')),
        controlAffinity: ListTileControlAffinity.trailing,
      ),
      Container(
        alignment: Alignment.topLeft,
        child: Text(AppLocalizations.of(context)!.translate('check_list_setting'), style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey)),
      ),
      ListTile(
        title: Text(AppLocalizations.of(context)!.translate('check_list_show_price')),
        subtitle: Text(AppLocalizations.of(context)!.translate('check_list_show_price_desc')),
        trailing: Switch(
          value: checkListShowPrice,
          activeColor: color.backgroundColor,
          onChanged: (value) async {
            checkListShowPrice = value;
            actionController.sink.add("switch");
          },
        ),
      ),
      ListTile(
        title: Text(AppLocalizations.of(context)!.translate('check_list_item_separator')),
        subtitle: Text(AppLocalizations.of(context)!.translate('check_list_item_separator_desc')),
        trailing: Switch(
          value: checkListItemSeparator,
          activeColor: color.backgroundColor,
          onChanged: (value) async {
            checkListItemSeparator = value;
            actionController.sink.add("switch");
          },
        ),
      ),
    ],
  );
}
