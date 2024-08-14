import 'dart:async';
import 'dart:convert';

import 'package:dotted_line/dotted_line.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';
import 'package:pos_system/object/kitchen_list.dart';
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
import '../printing_layout/print_receipt.dart';
import '../../translation/AppLocalizations.dart';
import '../../utils/Utils.dart';
import '../logout_dialog.dart';

class KitchenlistDialog extends StatefulWidget {
  const KitchenlistDialog({Key? key}) : super(key: key);

  @override
  State<KitchenlistDialog> createState() => _KitchenlistDialogState();
}

class _KitchenlistDialogState extends State<KitchenlistDialog> {
  StreamController actionController = StreamController();
  StreamController contentController = StreamController();
  late Stream contentStream;
  late Stream actionStream;
  final defaultFontSize = 14.0;
  KitchenList testPrintLayout = KitchenList();
  KitchenList? kitchen_list;
  ReceiptDialogEnum? productFontSize, variantAddonFontSize;
  String kitchen_listView = "80";
  String? kitchen_list_value;
  double? fontSize, otherFontSize;
  bool isButtonDisabled = false, submitted = false, kitchenListShowPrice = false, printCombineKitchenList = false, kitchenListItemSeparator = false, showSKU = false;
  List<Printer> kitchenPrinter = [];

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
          await getAllKitchenPrinter();
          await getKitchenListSetting();
          contentController.sink.add("refresh");
        }
        break;
        case 'view':{
          await getKitchenListSetting();
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

  getKitchenListSetting() async {
    try{
      KitchenList? data = await PosDatabase.instance.readSpecificKitchenList(kitchen_listView);
      print("data: $data");
      if(data != null){
        kitchen_list = data;
        productFontSize = data.product_name_font_size == 0 ? ReceiptDialogEnum.big : ReceiptDialogEnum.small;
        fontSize = data.product_name_font_size == 0 ? 20 : 14;
        variantAddonFontSize = data.other_font_size == 0 ? ReceiptDialogEnum.big : ReceiptDialogEnum.small;
        otherFontSize = data.other_font_size == 0 ? 20 : 14;
        kitchenListShowPrice = data.kitchen_list_show_price == 0 ? false : true;
        printCombineKitchenList = data.print_combine_kitchen_list == 0 ? false : true;
        kitchenListItemSeparator = data.kitchen_list_item_separator == 0 ? false : true;
        showSKU = data.show_product_sku == 0 ? false : true;
      } else {
        kitchen_list = null;
        productFontSize = ReceiptDialogEnum.big;
        fontSize = 20;
        variantAddonFontSize = ReceiptDialogEnum.small;
        otherFontSize = 14;
        kitchenListShowPrice = false;
        printCombineKitchenList = false;
        kitchenListItemSeparator = false;
        showSKU = false;
      }
    } catch(e){
      print("read kitchen list layout error: $e");
    }
  }

  getAllKitchenPrinter() async {
    try{
      List<Printer> printerList = await PrintReceipt().readAllPrinters();
      kitchenPrinter = printerList.where((printer) => printer.printer_status == 1).toList();
    } catch(e){
      print("get all kitchen printer error: $e");
      kitchenPrinter = [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeColor>(builder: (context, ThemeColor color, child) {
      return LayoutBuilder(builder: (context,  constraints) {
        if(constraints.maxWidth > 900 && constraints.maxHeight > 500){
          return AlertDialog(
            title: Text(AppLocalizations.of(context)!.translate('kitchen_list_layout')),
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
                                    kitchen_listView = newSelection.first;
                                    actionController.sink.add("view");

                                  },
                                  selected: <String>{kitchen_listView},
                                ),
                              ),
                              SizedBox(height: 10),
                              kitchen_listView == "80" ?
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
                    if(kitchenPrinter.isNotEmpty){
                      testLayout();
                      PrintReceipt().printTestPrintKitchenList(kitchenPrinter, testPrintLayout, testPrintLayout.paper_size!);
                    } else {
                      Fluttertoast.showToast(msg: AppLocalizations.of(context)!.translate('no_kitchen_printer'));
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
            title: Text(AppLocalizations.of(context)!.translate('kitchen_list_layout')),
            titlePadding: EdgeInsets.fromLTRB(24, 16, 24, 0),
            contentPadding: EdgeInsets.fromLTRB(24, 16, 24, 5),
            content: StreamBuilder(
                stream: contentStream,
                builder: (context, snapshot){
                  if(snapshot.hasData){
                    return Container(
                      height: MediaQuery.of(context).size.height /2,
                      width: 500,
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
                                    kitchen_listView = newSelection.first;
                                    actionController.sink.add("view");

                                  },
                                  selected: <String>{kitchen_listView},
                                ),
                              ),
                              SizedBox(height: 10),
                              kitchen_listView == "80" ?
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
                  style: ElevatedButton.styleFrom(backgroundColor: color.backgroundColor),
                  child: Text(AppLocalizations.of(context)!.translate('test_print')),
                  onPressed: () {
                    if(kitchenPrinter.isNotEmpty){
                      testLayout();
                      PrintReceipt().printTestPrintKitchenList(kitchenPrinter, testPrintLayout, testPrintLayout.paper_size!);
                    } else {
                      Fluttertoast.showToast(msg: AppLocalizations.of(context)!.translate('no_kitchen_printer'));
                    }
                  },
                ),
              ),
              SizedBox(
                width: MediaQuery.of(context).size.width / 4,
                height: MediaQuery.of(context).size.height / 10,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
                  child: Text('${AppLocalizations.of(context)?.translate('close')}'),
                  onPressed: isButtonDisabled ? null : () {
                    // Disable the button after it has been pressed
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
                  style: ElevatedButton.styleFrom(backgroundColor: color.backgroundColor),
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

  updateKitchenList() async {
    List<String> value = [];
    DateFormat dateFormat = DateFormat("yyyy-MM-dd HH:mm:ss");
    String dateTime = dateFormat.format(DateTime.now());
    try{
      KitchenList? checkData = await PosDatabase.instance.readSpecificKitchenListByKey(kitchen_list!.kitchen_list_key!);
      if(checkData != null){
        KitchenList data = KitchenList(
          product_name_font_size: productFontSize == ReceiptDialogEnum.big ? 0 : 1,
          other_font_size: variantAddonFontSize == ReceiptDialogEnum.big ? 0 : 1,
          kitchen_list_show_price: kitchenListShowPrice == true ? 1: 0,
          print_combine_kitchen_list: printCombineKitchenList == true ? 1: 0,
          kitchen_list_item_separator: kitchenListItemSeparator == true ? 1: 0,
          show_product_sku: showSKU ? 1 : 0,
          sync_status: checkData.sync_status == 0 ? 0 : 2,
          updated_at: dateTime,
          kitchen_list_sqlite_id: kitchen_list!.kitchen_list_sqlite_id,
        );
        int status = await PosDatabase.instance.updateKitchenList(data);
        if(status == 1){
          KitchenList? returnData = await PosDatabase.instance.readSpecificKitchenListByKey(kitchen_list!.kitchen_list_key!);
          if(returnData != null){
            value.add(jsonEncode(returnData));
          }
        }
      }
      kitchen_list_value = value.toString();
      print("kitchen_list value: ${kitchen_list_value}");
    }catch(e){
      print("update kitchen list error: $e");
      kitchen_list_value = null;
    }
  }

  createKitchenList() async {
    List<String> value = [];
    try{
      DateFormat dateFormat = DateFormat("yyyy-MM-dd HH:mm:ss");
      String dateTime = dateFormat.format(DateTime.now());
      final prefs = await SharedPreferences.getInstance();
      final String? branch = prefs.getString('branch');
      var branchObject = json.decode(branch!);

      KitchenList data = await PosDatabase.instance.insertSqliteKitchenList(KitchenList(
        kitchen_list_id: 0,
        kitchen_list_key: '',
        branch_id: branchObject['branchID'].toString(),
        product_name_font_size: productFontSize == ReceiptDialogEnum.big ? 0 : 1,
        other_font_size: variantAddonFontSize == ReceiptDialogEnum.big ? 0 : 1,
        paper_size: kitchen_listView,
        kitchen_list_show_price: kitchenListShowPrice == true ? 1 : 0,
        print_combine_kitchen_list: printCombineKitchenList == true ? 1 : 0,
        kitchen_list_item_separator: kitchenListItemSeparator == true ? 1 : 0,
        show_product_sku: showSKU ? 1 : 0,
        sync_status: 0,
        created_at: dateTime,
        updated_at: '',
        soft_delete: '',
      ));
      KitchenList? returnData = await insertKitchenListKey(data, dateTime);
      if(returnData != null){
        value.add(jsonEncode(returnData));
      }
      kitchen_list_value = value.toString();
      print("kitchen_list value: ${kitchen_list_value}");
    }catch(e) {
      print("create kitchen_list error: ${e}");
      kitchen_list_value = null;
    }
  }

  insertKitchenListKey(KitchenList kitchen_list, String dateTime) async {
    KitchenList? returnData;
    String key = await generateKitchenListKey(kitchen_list);
    KitchenList data = KitchenList(
        updated_at: dateTime,
        sync_status: 0,
        kitchen_list_key: key,
        kitchen_list_sqlite_id: kitchen_list.kitchen_list_sqlite_id
    );
    int status =  await PosDatabase.instance.updateKitchenListUniqueKey(data);
    if(status == 1){
      KitchenList? checkData = await PosDatabase.instance.readSpecificKitchenListByKey(data.kitchen_list_key!);
      if(checkData != null){
        returnData = checkData;
      }
    }
    return returnData;
  }

  generateKitchenListKey(KitchenList kitchen_list) async {
    final prefs = await SharedPreferences.getInstance();
    final int? branch_id = prefs.getInt('branch_id');
    var bytes = kitchen_list.created_at!.replaceAll(new RegExp(r'[^0-9]'), '') + kitchen_list.kitchen_list_sqlite_id.toString() + branch_id.toString();
    var md5Hash = md5.convert(utf8.encode(bytes));
    return Utils.shortHashString(hashCode: md5Hash);
  }

  Future<void> _submit(BuildContext context) async {
    setState(() => submitted = true);
    if(kitchen_list != null){
      await updateKitchenList();
    } else {
      await createKitchenList();
    }
    await syncAllToCloud();
    closeDialog(context);

  }

  testLayout(){
    testPrintLayout = KitchenList(
        product_name_font_size: productFontSize == ReceiptDialogEnum.big ? 0 : 1,
        other_font_size: variantAddonFontSize == ReceiptDialogEnum.big ? 0 : 1,
        kitchen_list_show_price: kitchenListShowPrice == true ? 1: 0,
        print_combine_kitchen_list: printCombineKitchenList == true ? 1: 0,
        kitchen_list_item_separator: kitchenListItemSeparator == true ? 1: 0,
        paper_size: kitchen_listView
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
          kitchen_list_value: kitchen_list_value,
        );
        if (data['status'] == '1') {
          List responseJson = data['data'];
          await PosDatabase.instance.updateKitchenListSyncStatusFromCloud(responseJson[0]['kitchen_list_key']);
          mainSyncToCloud.resetCount();
        }else if(data['status'] == '7'){
          mainSyncToCloud.resetCount();
          //this.isLogOut = true;
          openLogOutDialog();
          return;
        }else if (data['status'] == '8'){
          print('kitchen_list setting timeout');
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
  // 80mm
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
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text("Dine In", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24.0)),
              Text("Table No: 5", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24.0)),
              Text("Batch No: #123456-005"),
              Text("Order time: DD/MM/YY hh:mm PM"),
              Padding(
                padding: EdgeInsets.only(top: 10, bottom: 10),
                child: DottedLine(),
              ),
              Column(
                children: [
                  Row(
                    children: [
                      Text("1", style: TextStyle(fontWeight: FontWeight.bold, fontSize: fontSize)),
                      SizedBox(width: 50),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: EdgeInsets.only(top: 5),
                            child: Row(
                              children: [
                                Visibility(visible: showSKU, child: Text("SKU001 ", style: TextStyle(fontWeight: FontWeight.bold, fontSize: fontSize))),
                                Text("Product 1${kitchenListShowPrice ? "(RM6.90)" : ''}",
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: fontSize)),
                              ],
                            ),
                          ),
                          Text("(big | small)", style: TextStyle(fontSize: otherFontSize)),
                        ],
                      ),
                    ],
                  ),
                  Visibility(
                    visible: printCombineKitchenList,
                    child: Column(
                      children: [
                        Visibility(
                          visible: kitchenListItemSeparator,
                          child: Padding(
                            padding: EdgeInsets.only(top: 20, bottom: 10),
                            child: DottedLine(),
                          ),
                        ),
                        Row(
                          children: [
                            Text("1", style: TextStyle(fontWeight: FontWeight.bold, fontSize: fontSize)),
                            SizedBox(width: 50),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: EdgeInsets.only(top: 5),
                                  child: Row(
                                    children: [
                                      Visibility(visible: showSKU, child: Text("SKU002 ", style: TextStyle(fontWeight: FontWeight.bold, fontSize: fontSize))),
                                      Text("Product 2${kitchenListShowPrice ? "(RM8.80)" : ''}",
                                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: fontSize)),
                                    ],
                                  ),
                                ),
                                Text("**Remark", style: TextStyle(fontSize: otherFontSize)),
                              ],
                            ),
                          ],
                        ),
                        Visibility(
                          visible: kitchenListItemSeparator,
                          child: Padding(
                            padding: EdgeInsets.only(top: 20, bottom: 10),
                            child: DottedLine(),
                          ),
                        ),
                        Row(
                          children: [
                            Text("1", style: TextStyle(fontWeight: FontWeight.bold, fontSize: fontSize)),
                            SizedBox(width: 50),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: EdgeInsets.only(top: 5),
                                  child: Row(
                                    children: [
                                      Visibility(visible: showSKU, child: Text("SKU003 ", style: TextStyle(fontWeight: FontWeight.bold, fontSize: fontSize))),
                                      Text("Product 3${kitchenListShowPrice ? "(RM15.90)" : ''}",
                                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: fontSize)),
                                    ],
                                  ),
                                ),
                                Text("+add-on1", style: TextStyle(fontSize: otherFontSize)),
                              ],
                            ),
                          ],
                        ),
                        // Add more Rows as needed
                      ],
                    ),
                  ),
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
              child: Text(AppLocalizations.of(context)!.translate('kitchen_list_setting'), style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey)),
            ),
            ListTile(
              title: Text(AppLocalizations.of(context)!.translate('kitchen_list_show_price')),
              subtitle: Text(AppLocalizations.of(context)!.translate('kitchen_list_show_price_desc')),
              trailing: Switch(
                value: kitchenListShowPrice,
                activeColor: color.backgroundColor,
                onChanged: (value) async {
                  kitchenListShowPrice = value;
                  actionController.sink.add("switch");
                },
              ),
            ),
            ListTile(
              title: Text(AppLocalizations.of(context)!.translate('print_combine_kitchen_list')),
              subtitle: Text(AppLocalizations.of(context)!.translate('print_combine_kitchen_list_desc')),
              trailing: Switch(
                value: printCombineKitchenList,
                activeColor: color.backgroundColor,
                onChanged: (value) async {
                  printCombineKitchenList = value;
                  if(!printCombineKitchenList){
                    if(kitchenListItemSeparator)
                      kitchenListItemSeparator = value;
                  }
                  actionController.sink.add("switch");
                },
              ),
            ),
            ListTile(
              title: Text(AppLocalizations.of(context)!.translate('kitchen_list_item_separator'),
                  style: TextStyle(
                    color: !printCombineKitchenList ? Colors.grey : null)
              ),
              subtitle: Text(AppLocalizations.of(context)!.translate('kitchen_list_item_separator_desc'),
                  style: TextStyle(
                    color: !printCombineKitchenList ? Colors.grey : null)
              ),
              trailing: Switch(
                value: kitchenListItemSeparator,
                activeColor: color.backgroundColor,
                onChanged: (value) async {
                  if(!printCombineKitchenList) {
                    Fluttertoast.showToast(msg: AppLocalizations.of(context)!.translate('print_combine_kitchen_list_required'));
                  } else {
                    kitchenListItemSeparator = value;
                    actionController.sink.add("switch");
                  }
                },
              ),
            ),
            ListTile(
              title: Text(AppLocalizations.of(context)!.translate('show_product_sku')),
              subtitle: Text(AppLocalizations.of(context)!.translate('show_product_sku_desc')),
              trailing: Switch(
                value: showSKU,
                activeColor: color.backgroundColor,
                onChanged: (value) {
                  showSKU = value;
                  actionController.sink.add("switch");
                },
              ),
            ),
          ],
        ),
      ),
    ],
  );

  //50mm
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
              Text("Dine In", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24.0)),
              Text("Table No: 5", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24.0)),
              Text("Batch No"),
              Text("#123456-005"),
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
                      Text("1", style: TextStyle(fontWeight: FontWeight.bold, fontSize: fontSize)),
                      SizedBox(width: 50),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: EdgeInsets.only(top: 5),
                            child: Row(
                              children: [
                                Visibility(visible: showSKU, child: Text("SKU001 ", style: TextStyle(fontWeight: FontWeight.bold, fontSize: fontSize))),
                                Text("Product 1${kitchenListShowPrice ? "(RM6.90)" : ''}",
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: fontSize)),
                              ],
                            ),
                          ),
                          Text("(big | small)", style: TextStyle(fontSize: otherFontSize)),
                        ],
                      )
                    ],
                  ),
                  Visibility(
                    visible: printCombineKitchenList,
                    child: Column(
                      children: [
                        Visibility(
                          visible: kitchenListItemSeparator,
                          child: Padding(
                            padding: EdgeInsets.only(top: 20, bottom: 10),
                            child: DottedLine(),
                          ),
                        ),
                        Row(
                          children: [
                            Text("1", style: TextStyle(fontWeight: FontWeight.bold, fontSize: fontSize)),
                            SizedBox(width: 50),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: EdgeInsets.only(top: 5),
                                  child: Row(
                                    children: [
                                      Visibility(visible: showSKU, child: Text("SKU002 ", style: TextStyle(fontWeight: FontWeight.bold, fontSize: fontSize))),
                                      Text("Product 2${kitchenListShowPrice ? "(RM8.80)" : ''}",
                                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: fontSize)),
                                    ],
                                  ),
                                ),
                                Text("**Remark", style: TextStyle(fontSize: otherFontSize)),
                              ],
                            ),
                          ],
                        ),
                        Visibility(
                          visible: kitchenListItemSeparator,
                          child: Padding(
                            padding: EdgeInsets.only(top: 20, bottom: 10),
                            child: DottedLine(),
                          ),
                        ),
                        Row(
                          children: [
                            Text("1", style: TextStyle(fontWeight: FontWeight.bold, fontSize: fontSize)),
                            SizedBox(width: 50),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: EdgeInsets.only(top: 5),
                                  child: Row(
                                    children: [
                                      Visibility(visible: showSKU, child: Text("SKU003 ", style: TextStyle(fontWeight: FontWeight.bold, fontSize: fontSize))),
                                      Text("Product 3${kitchenListShowPrice ? "(RM15.90)" : ''}",
                                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: fontSize)),
                                    ],
                                  ),
                                ),
                                Text("+add-on1", style: TextStyle(fontSize: otherFontSize)),
                              ],
                            ),
                          ],
                        ),
                        // Add more Rows as needed
                      ],
                    ),
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
              child: Text(AppLocalizations.of(context)!.translate('kitchen_list_setting'), style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey)),
            ),
            ListTile(
              title: Text(AppLocalizations.of(context)!.translate('kitchen_list_show_price')),
              subtitle: Text(AppLocalizations.of(context)!.translate('kitchen_list_show_price_desc')),
              trailing: Switch(
                value: kitchenListShowPrice,
                activeColor: color.backgroundColor,
                onChanged: (value) async {
                  kitchenListShowPrice = value;
                  // appSettingModel.setPrintChecklistStatus(kitchenListShowPrice);
                  actionController.sink.add("switch");
                },
              ),
            ),
            ListTile(
              title: Text(AppLocalizations.of(context)!.translate('print_combine_kitchen_list')),
              subtitle: Text(AppLocalizations.of(context)!.translate('print_combine_kitchen_list_desc')),
              trailing: Switch(
                value: printCombineKitchenList,
                activeColor: color.backgroundColor,
                onChanged: (value) async {
                  printCombineKitchenList = value;
                  if(!printCombineKitchenList){
                    if(kitchenListItemSeparator)
                      kitchenListItemSeparator = value;
                  }
                  actionController.sink.add("switch");
                },
              ),
            ),
            ListTile(
              title: Text(AppLocalizations.of(context)!.translate('kitchen_list_item_separator'),
                  style: TextStyle(
                      color: !printCombineKitchenList ? Colors.grey : null)
              ),
              subtitle: Text(AppLocalizations.of(context)!.translate('kitchen_list_item_separator_desc'),
                  style: TextStyle(
                      color: !printCombineKitchenList ? Colors.grey : null)
              ),
              trailing: Switch(
                value: kitchenListItemSeparator,
                activeColor: color.backgroundColor,
                onChanged: (value) async {
                  if(!printCombineKitchenList) {
                    Fluttertoast.showToast(msg: AppLocalizations.of(context)!.translate('print_combine_kitchen_list_required'));
                  } else {
                    kitchenListItemSeparator = value;
                    actionController.sink.add("switch");
                  }
                },
              ),
            ),
            ListTile(
              title: Text(AppLocalizations.of(context)!.translate('show_product_sku')),
              subtitle: Text(AppLocalizations.of(context)!.translate('show_product_sku_desc')),
              trailing: Switch(
                value: showSKU,
                activeColor: color.backgroundColor,
                onChanged: (value) {
                  showSKU = value;
                  actionController.sink.add("switch");
                },
              ),
            ),
          ],
        ),
      ),
    ],
  );

  //mobile layout 80mm
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
        child: Text(AppLocalizations.of(context)!.translate('kitchen_list_setting'), style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey)),
      ),
      ListTile(
        title: Text(AppLocalizations.of(context)!.translate('kitchen_list_show_price')),
        subtitle: Text(AppLocalizations.of(context)!.translate('kitchen_list_show_price_desc')),
        trailing: Switch(
          value: kitchenListShowPrice,
          activeColor: color.backgroundColor,
          onChanged: (value) async {
            kitchenListShowPrice = value;
            actionController.sink.add("switch");
          },
        ),
      ),
      ListTile(
        title: Text(AppLocalizations.of(context)!.translate('print_combine_kitchen_list')),
        subtitle: Text(AppLocalizations.of(context)!.translate('print_combine_kitchen_list_desc')),
        trailing: Switch(
          value: printCombineKitchenList,
          activeColor: color.backgroundColor,
          onChanged: (value) async {
            printCombineKitchenList = value;
            if(!printCombineKitchenList){
              if(kitchenListItemSeparator)
                kitchenListItemSeparator = value;
            }
            actionController.sink.add("switch");
          },
        ),
      ),
      ListTile(
        title: Text(AppLocalizations.of(context)!.translate('kitchen_list_item_separator'),
            style: TextStyle(
                color: !printCombineKitchenList ? Colors.grey : null)
        ),
        subtitle: Text(AppLocalizations.of(context)!.translate('kitchen_list_item_separator_desc'),
            style: TextStyle(
                color: !printCombineKitchenList ? Colors.grey : null)
        ),
        trailing: Switch(
          value: kitchenListItemSeparator,
          activeColor: color.backgroundColor,
          onChanged: (value) async {
            if(!printCombineKitchenList) {
              Fluttertoast.showToast(msg: AppLocalizations.of(context)!.translate('print_combine_kitchen_list_required'));
            } else {
              kitchenListItemSeparator = value;
              actionController.sink.add("switch");
            }
          },
        ),
      ),
      ListTile(
        title: Text(AppLocalizations.of(context)!.translate('show_product_sku')),
        subtitle: Text(AppLocalizations.of(context)!.translate('show_product_sku_desc')),
        trailing: Switch(
          value: showSKU,
          activeColor: color.backgroundColor,
          onChanged: (value) {
            showSKU = value;
            actionController.sink.add("switch");
          },
        ),
      ),
    ],
  );

  //mobile layout 35mm
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
        child: Text(AppLocalizations.of(context)!.translate('kitchen_list_setting'), style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey)),
      ),
      ListTile(
        title: Text(AppLocalizations.of(context)!.translate('kitchen_list_show_price')),
        subtitle: Text(AppLocalizations.of(context)!.translate('kitchen_list_show_price_desc')),
        trailing: Switch(
          value: kitchenListShowPrice,
          activeColor: color.backgroundColor,
          onChanged: (value) async {
            kitchenListShowPrice = value;
            actionController.sink.add("switch");
          },
        ),
      ),
      ListTile(
        title: Text(AppLocalizations.of(context)!.translate('print_combine_kitchen_list')),
        subtitle: Text(AppLocalizations.of(context)!.translate('print_combine_kitchen_list_desc')),
        trailing: Switch(
          value: printCombineKitchenList,
          activeColor: color.backgroundColor,
          onChanged: (value) async {
            printCombineKitchenList = value;
            if(!printCombineKitchenList){
              if(kitchenListItemSeparator)
                kitchenListItemSeparator = value;
            }
            actionController.sink.add("switch");
          },
        ),
      ),
      ListTile(
        title: Text(AppLocalizations.of(context)!.translate('kitchen_list_item_separator'),
            style: TextStyle(
                color: !printCombineKitchenList ? Colors.grey : null)
        ),
        subtitle: Text(AppLocalizations.of(context)!.translate('kitchen_list_item_separator_desc'),
            style: TextStyle(
                color: !printCombineKitchenList ? Colors.grey : null)
        ),
        trailing: Switch(
          value: kitchenListItemSeparator,
          activeColor: color.backgroundColor,
          onChanged: (value) async {
            if(!printCombineKitchenList) {
              Fluttertoast.showToast(msg: AppLocalizations.of(context)!.translate('print_combine_kitchen_list_required'));
            } else {
              kitchenListItemSeparator = value;
              actionController.sink.add("switch");
            }
          },
        ),
      ),
      ListTile(
        title: Text(AppLocalizations.of(context)!.translate('show_product_sku')),
        subtitle: Text(AppLocalizations.of(context)!.translate('show_product_sku_desc')),
        trailing: Switch(
          value: showSKU,
          activeColor: color.backgroundColor,
          onChanged: (value) {
            showSKU = value;
            actionController.sink.add("switch");
          },
        ),
      ),
    ],
  );
}
