import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:dotted_line/dotted_line.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';
import 'package:pos_system/database/pos_database.dart';
import 'package:pos_system/object/receipt.dart';
import 'package:pos_system/page/progress_bar.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../database/domain.dart';
import '../../enumClass/receipt_dialog_enum.dart';
import '../../main.dart';
import '../../notifier/theme_color.dart';
import '../../object/print_receipt.dart';
import '../../object/printer.dart';
import '../../translation/AppLocalizations.dart';
import '../logout_dialog.dart';

class ReceiptDialog extends StatefulWidget {
  final Receipt? receiptObject;
  final Function() callBack;
  const ReceiptDialog({Key? key, required this.receiptObject, required this.callBack}) : super(key: key);

  @override
  State<ReceiptDialog> createState() => _ReceiptDialogState();
}

class _ReceiptDialogState extends State<ReceiptDialog> {
  List<Printer> printerList = [];
  final headerTextController = TextEditingController();
  final emailTextController = TextEditingController();
  final footerTextController = TextEditingController();
  File? headerImage;
  File? footerImg;
  String? headerDir;
  String? footerDir;
  String headerText = '';
  String footerTextString = '';
  ReceiptDialogEnum? headerFontSize;
  String? emailAddress;
  bool isLoad = false, isButtonDisabled = false;
  bool _isUpdate = false;
  bool logoImage = false;
  bool footerImage = false;
  bool logoText = false;
  bool footerText = false;
  bool showAddress = true;
  bool showEmail = true;
  bool showTaxDetail = true;
  bool promoDetail = true;
  bool _submitted = false;
  bool isLogOut = false;
  Map? branchObject;
  double? fontSize;
  Receipt? testReceipt;
  Receipt receipt = Receipt();
  String receiptView = "80";

  @override
  void initState() {
    // TODO: implement initState
    if (widget.receiptObject != null) {
      preload();
      //isLoad = true;
    } else {
      _isUpdate = false;
      isLoad = true;
    }
    super.initState();
  }

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
    headerTextController.dispose();
    emailTextController.dispose();
    footerTextController.dispose();
  }

  preload(){
    _isUpdate = true;
    initialData(widget.receiptObject!);
    getSharePreferences();
    getAllPrinter();
  }

  reload() async {
    _isUpdate = true;
    await readSpecificReceiptLayout();
  }

  readSpecificReceiptLayout() async {
    Receipt? data = await PosDatabase.instance.readSpecificReceipt(receiptView);
    if(data != null){
      initialData(data);
    }
    setState(() {
      isLoad = true;
    });
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

  // readAllReceiptLayout() async {
  //   Receipt? data = await PosDatabase.instance.readAllReceipt();
  //   if(data != null){
  //     widget.receiptObject = data;
  //   }
  // }

  initialData(Receipt data){
    receipt = data;
    receipt.header_image_status == 1 ? this.logoImage = true  : this.logoImage = false;
    receipt.footer_image_status == 1 ? this.footerImage = true  : this.footerImage = false;
    receipt.header_text_status == 1 ? this.logoText = true : this.logoText = false;
    receipt.footer_text_status == 1 ? this.footerText = true : this.footerText = false;
    receipt.promotion_detail_status == 1 ? this.promoDetail = true : this.promoDetail = false;
    receipt.show_address == 1 ? this.showAddress = true : this.showAddress = false;
    receipt.show_email == 1 ? this.showEmail = true : this.showEmail = false;
    headerText = receipt.header_text!;
    headerTextController.text = receipt.header_text!;
    receipt.show_email == 1 ? emailAddress = receipt.receipt_email : '';
    receipt.show_email == 1 ? emailTextController.text = receipt.receipt_email! : '';
    footerTextString = receipt.footer_text!;
    footerTextController.text = receipt.footer_text!;
    receipt.header_font_size == 0 ? headerFontSize = ReceiptDialogEnum.big : headerFontSize = ReceiptDialogEnum.small;
    receipt.header_font_size == 0 ? fontSize = 30.0 : fontSize = 12.0;
  }

  getSharePreferences() async {
    final prefs = await SharedPreferences.getInstance();
    final String? branch = prefs.getString('branch');
    branchObject = json.decode(branch!);
    // emailTextController.text = branchObject!['email'];
    // emailAddress = branchObject!['email'];
    // if(branchObject!['address'] != ''){
    //   showAddress = true;
    // } else {
    //   showAddress = false;
    // }
    isLoad = true;
  }

  getAllPrinter() async {
    printerList = await PrintReceipt().readAllPrinters();
  }

  String? get errorHeaderText {
    final text = headerTextController.value.text;
    if (logoText == true && text.isEmpty) {
      return 'header_text_required';
    }
    return null;
  }

  String? get errorEmailText {
    final text = headerTextController.value.text;
    if (showEmail == true && text.isEmpty) {
      return 'email_text_required';
    }
    // else if (!text.contains('@') && !text.endsWith('com')){
    //   return 'invalid_email';
    // }
    return null;
  }

  String? get errorFooterText {
    final text = footerTextController.value.text;
    if (footerText == true && text.isEmpty) {
      return 'footer_text_required';
    }
    return null;
  }

  Future<void> _submit(BuildContext context) async {
    setState(() => _submitted = true);
    if(!_isUpdate){
      if(logoImage == false && footerImage == false && logoText == false && footerText == false){
        Fluttertoast.showToast(
            backgroundColor: Color(0xFFFF0000),
            msg: "${AppLocalizations.of(context)?.translate('submit_fail2')}");
      } else if(errorHeaderText == null && errorFooterText == null) {
        //createReceiptLayout();
      } else {
        setState(() {
          isButtonDisabled = false;
        });
        Fluttertoast.showToast(
            backgroundColor: Color(0xFFFF0000),
            msg: "${AppLocalizations.of(context)?.translate('submit_fail')}");
      }

    } else {
      if(errorHeaderText == null && errorFooterText == null){
        //update receipt layout
        await updateReceiptLayout();
        Navigator.of(context).pop();
      } else {
        setState(() {
          isButtonDisabled = false;
        });
      }

      //setLayoutInUse(widget.receiptObject!);
    }
  }

  testReceiptLayout(){
    testReceipt = Receipt(
      header_text: logoText == true ? headerTextController.text : '',
      footer_text: footerText == true ? footerTextController.text : '',
      header_image: logoImage == true ? 'branchLogo.jpg' : '',
      footer_image: footerImage == true ? 'branchFooter.jpg' : '',
      header_text_status: logoText == true ? 1 : 0,
      footer_text_status: footerText == true ? 1 : 0,
      header_image_status: logoImage == true ? 1 : 0,
      footer_image_status: footerImage == true ? 1 : 0,
      header_font_size: headerFontSize == ReceiptDialogEnum.big ? 0 : 1,
      promotion_detail_status: promoDetail == true ? 1 : 0,
      show_address: showAddress == true ? 1 : 0,
      show_email: showEmail == true ? 1 : 0,
      receipt_email: emailTextController.text,
    );
  }

  closeDialog(BuildContext context) {
    return Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeColor>(builder: (context, ThemeColor color, child) {
      return LayoutBuilder(builder: (context,  constraints) {
        if(constraints.maxWidth > 900 && constraints.maxHeight > 500){
          return Center(
            child: SingleChildScrollView(
              //physics: NeverScrollableScrollPhysics(),
              child: AlertDialog(
                title: !_isUpdate ? Text(AppLocalizations.of(context)!.translate('add_receipt_layout')) : Text(AppLocalizations.of(context)!.translate('receipt_layout')),
                content: isLoad ?
                Container(
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
                                receiptView = newSelection.first;
                                isLoad = false;
                                reload();

                              },
                              selected: <String>{receiptView},
                            ),
                          ),
                          SizedBox(height: 10),
                          receiptView == "80" ?
                          ReceiptView1(color) :
                          ReceiptView2(color),

                        ],
                      )
                  ),
                ) : CustomProgressBar(),
                actions: <Widget>[
                  SizedBox(
                    width: MediaQuery.of(context).size.width / 4,
                    height: MediaQuery.of(context).size.height / 12,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: color.backgroundColor,
                      ),
                      child: !_isUpdate ? Text('${AppLocalizations.of(context)?.translate('add')}') : Text(AppLocalizations.of(context)!.translate('update')),
                      onPressed: isButtonDisabled ? null : () {
                        setState(() {
                          isButtonDisabled = true;
                        });
                        _submit(context);
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
                      child: Text(AppLocalizations.of(context)!.translate('test_print')),
                      onPressed: () {
                        testReceiptLayout();
                        PrintReceipt().printTestPrintReceipt(printerList, testReceipt!, this.receipt.paper_size!, context);
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
                ],
              ),
            ),
          );
        } else {
          ///mobile layout
          return Center(
            child: SingleChildScrollView(
              child: AlertDialog(
                title: !_isUpdate ? Text(AppLocalizations.of(context)!.translate('add_receipt_layout')) : Text(AppLocalizations.of(context)!.translate('receipt_layout')),
                content: isLoad ?
                Container(
                  height: MediaQuery.of(context).size.height /2.5,
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
                              receiptView = newSelection.first;
                              isLoad = false;
                              reload();
                            },
                            selected: <String>{receiptView},
                          ),
                        ),
                        SizedBox(height: 20.0),
                        receiptView == "80" ?
                        MobileReceiptView1(color) :
                        MobileReceiptView2(color)
                      ],
                    ),
                  ),
                ) : CustomProgressBar(),
                actions: <Widget>[
                  SizedBox(
                    width: MediaQuery.of(context).size.width / 4,
                    height: MediaQuery.of(context).size.height / 10,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: color.backgroundColor),
                      child: !_isUpdate ? Text('${AppLocalizations.of(context)?.translate('add')}') : Text(AppLocalizations.of(context)!.translate('update')),
                      onPressed: isButtonDisabled ? null : () {
                        setState(() {
                          isButtonDisabled = true;
                        });
                        _submit(context);
                      },
                    ),
                  ),
                  SizedBox(
                    width: MediaQuery.of(context).size.width / 4,
                    height: MediaQuery.of(context).size.height / 10,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: color.backgroundColor),
                      child: Text(AppLocalizations.of(context)!.translate('test_print')),
                      onPressed: () {
                        testReceiptLayout();
                        PrintReceipt().printTestPrintReceipt(printerList, testReceipt!, this.receipt.paper_size!, context);
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
                ],
              ),
            ),
          );
        }
      });
    });
  }

  updateReceiptLayout() async {
    List<String> receiptValue = [];
    DateFormat dateFormat = DateFormat("yyyy-MM-dd HH:mm:ss");
    String dateTime = dateFormat.format(DateTime.now());
    Receipt? checkData = await PosDatabase.instance.readSpecificReceiptByKey(receipt.receipt_key!);
    Receipt data = Receipt(
      receipt_sqlite_id: receipt.receipt_sqlite_id,
      receipt_key: receipt.receipt_key,
      header_text: logoText == true ? headerTextController.text : '',
      footer_text: footerText == true ? footerTextController.text : '',
      header_font_size: headerFontSize == ReceiptDialogEnum.big ? 0 : 1,
      header_image: logoImage == true ? 'branchLogo.jpg' : '',
      footer_image: footerImage == true ? 'branchFooter.jpg' : '',
      header_text_status: logoText == true ? 1 : 0,
      footer_text_status: footerText == true ? 1 : 0,
      header_image_status: logoImage == true ? 1 : 0,
      footer_image_status: footerImage == true ? 1 : 0,
      promotion_detail_status: promoDetail == true ? 1 : 0,
      show_address: showAddress == true ? 1 : 0,
      show_email: showEmail == true ? 1 : 0,
      receipt_email: emailTextController.text,
      sync_status: checkData!.sync_status == 0 ? 0 : 2,
      updated_at: dateTime
    );
    int status = await PosDatabase.instance.updateReceiptLayout(data);
    if(status == 1){
      widget.callBack();
      Receipt? receipt = await PosDatabase.instance.readSpecificReceiptByKey(data.receipt_key!);
      receiptValue.add(jsonEncode(receipt));
      print("receipt value: ${receiptValue.toString()}");
      await syncAllToCloud(receiptValue: receiptValue.toString());
    }
    print('update status: $status');
  }

  syncAllToCloud({receiptValue}) async {
    try{
      if(mainSyncToCloud.count == 0){
        mainSyncToCloud.count = 1;
        final prefs = await SharedPreferences.getInstance();
        final int? device_id = prefs.getInt('device_id');
        final String? login_value = prefs.getString('login_value');
        Map data = await Domain().syncLocalUpdateToCloud(
            device_id: device_id.toString(),
            value: login_value,
            receipt_value: receiptValue
        );
        if (data['status'] == '1') {
          List responseJson = data['data'];
          await PosDatabase.instance.updateReceiptSyncStatusFromCloud(responseJson[0]['receipt_key']);
          mainSyncToCloud.resetCount();
        }else if(data['status'] == '7'){
          mainSyncToCloud.resetCount();
          //this.isLogOut = true;
          openLogOutDialog();
          return;
        }else if (data['status'] == '8'){
          print('receipt setting timeout');
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

  Widget ReceiptView1(ThemeColor color) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Expanded(
          flex: 1,
          child: Container(
            decoration: BoxDecoration(
                border: Border.all(color: Colors.blueGrey, style: BorderStyle.solid, width: 1)
            ),
            padding: MediaQuery.of(context).size.width > 1300 ? EdgeInsets.fromLTRB(50, 20, 50, 20) : EdgeInsets.fromLTRB(20, 20, 20, 20) ,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Visibility(
                    visible: logoImage ? true : false,
                    child: Center(
                      child: CircleAvatar(
                        radius: 30,
                        backgroundColor: Colors.black,
                        child: Text(AppLocalizations.of(context)!.translate('logo')),
                      ),
                    )
                ),
                Visibility(
                    visible: logoText ? true : false,
                    child: Center(
                      child: Text('${headerText}', style: TextStyle(fontSize: fontSize, fontWeight: FontWeight.bold)),
                    )
                ),
                Center(
                  child: Column(
                    children: [
                      Visibility(
                        visible: showAddress ? true : false,
                        child: Text('Jalan permas baru'),
                      ),
                      Text('Tel: 07-3456789'),
                      Visibility(
                        visible: showEmail? true : false,
                        child: Text('${emailAddress}'),
                      )
                    ],
                  ),
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(0.0, 5.0, 0.0, 5.0),
                  child: DottedLine(),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Receipt No.: #00001-001-12345678', style: TextStyle(fontWeight: FontWeight.bold)),
                    Text('Close At: 31/12/2021 00:00 AM'),
                    Text('Close By: Waiter'),
                    Text('Table No: 1'),
                    Text('Dine In'),
                  ],
                ),
                DottedLine(),
                Container(
                  child: Row(
                    children: [
                      Expanded(
                        flex: 1,
                        child: Text('Qty', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                      Expanded(
                        flex: 4,
                        child: Padding(
                          padding: EdgeInsets.all(5),
                          child: Text('Item', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ),
                      Expanded(
                        flex: 0,
                        child: Text('Price', style: TextStyle(fontWeight: FontWeight.bold)),
                      )
                    ],
                  ),
                ),
                DottedLine(),
                Padding(
                  padding: EdgeInsets.all(5),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            flex: 1,
                            child: Text('2'),
                          ),
                          Expanded(
                            flex: 4,
                            child: Text('Product 1 (2.00/each)', style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                          Expanded(
                            flex: 0,
                            child: Text('4.00'),
                          )
                        ],
                      ),
                      Row(
                        children: [
                          Expanded(
                            flex: 1,
                            child: Text('1'),
                          ),
                          Expanded(
                            flex: 4,
                            child: Text('Product 2 (2.00/each)', style: TextStyle(fontWeight: FontWeight.bold)),
                          ),

                          Expanded(
                            flex: 0,
                            child: Text('2.00'),
                          )
                        ],
                      ),
                    ],
                  ),
                ),
                // Container(
                //   child: Row(
                //     children: [
                //       Expanded(
                //         flex: 2,
                //         child: Text('product1', style: TextStyle(fontWeight: FontWeight.bold)),
                //       ),
                //       Expanded(
                //         flex: 1,
                //         child: Text('2'),
                //       ),
                //       Expanded(
                //         flex: 0,
                //         child: Text('2.00'),
                //       )
                //     ],
                //   ),
                // ),
                // Container(
                //   child: Row(
                //     children: [
                //       Expanded(
                //         flex: 2,
                //         child: Text('product2', style: TextStyle(fontWeight: FontWeight.bold)),
                //       ),
                //       Expanded(
                //         flex: 1,
                //         child: Text('1'),
                //       ),
                //       Expanded(
                //         flex: 0,
                //         child: Text('2.00'),
                //       )
                //     ],
                //   ),
                // ),
                DottedLine(),
                Container(
                  padding: EdgeInsets.fromLTRB(0.0, 5.0, 0.0, 5.0),
                  child: Text('Item Count: 3'),
                ),
                DottedLine(),
                Container(
                  child: Row(
                    children: [
                      Expanded(
                        child: Text('Subtotal', textAlign: TextAlign.right),
                      ),
                      SizedBox(width: 80),
                      Text('6.00')
                    ],
                  ),
                ),
                Visibility(
                    visible: promoDetail ? true : false,
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text('Discount1(1.00)', textAlign: TextAlign.right),
                            ),
                            SizedBox(width: 75),
                            Text('-1.00')
                          ],
                        ),
                        Row(
                          children: [
                            Expanded(
                              child: Text('Discount2(1.00)', textAlign: TextAlign.right),
                            ),
                            SizedBox(width: 75),
                            Text('-1.00')
                          ],
                        ),
                      ],
                    )
                ),
                Visibility(
                  visible: !promoDetail ? true : false,
                  child: Container(
                    child: Row(
                      children: [
                        Expanded(
                          child: Text('Total discount', textAlign: TextAlign.right),
                        ),
                        SizedBox(width: 75),
                        Text('-2.00')
                      ],
                    ),
                  ),
                ),
                Visibility(
                    visible: showTaxDetail ? true : false,
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text('Tax1(10%)', textAlign: TextAlign.right),
                            ),
                            SizedBox(width: 80),
                            Text('0.40')
                          ],
                        ),
                        Row(
                          children: [
                            Expanded(
                              child: Text('Tax2(6%)', textAlign: TextAlign.right),
                            ),
                            SizedBox(width: 80),
                            Text('0.24')
                          ],
                        ),
                      ],
                    )
                ),
                // Visibility(
                //     visible: !showTaxDetail ? true : false,
                //     child: Row(
                //       children: [
                //         Expanded(
                //           flex: 1,
                //           child: Text(''),
                //         ),
                //         Expanded(
                //           flex: 1,
                //           child: Text(''),
                //         ),
                //         Expanded(
                //           flex: 0,
                //           child: Text('Tax inc.'),
                //         )
                //       ],
                //     ),
                // ),
                Row(
                  children: [
                    Expanded(
                      child: Text('Amount', textAlign: TextAlign.right),
                    ),
                    SizedBox(width: 80),
                    Text('3.36')
                  ],
                ),
                Row(
                  children: [
                    Expanded(
                      child: Text('Rounding', textAlign: TextAlign.right),
                    ),
                    SizedBox(width: 75),
                    Text('+0.04',)
                  ],
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(0.0, 5.0, 0.0, 5.0),
                  child: DottedLine(),
                ),
                Row(
                  children: [
                    Expanded(
                      child: Text('Final Amount', textAlign: TextAlign.right, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    ),
                    SizedBox(width: 70),
                    Text('3.40', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20))
                  ],
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(0.0, 5.0, 0.0, 5.0),
                  child: DottedLine(),
                ),
                Container(
                  child: Row(
                    children: [
                      Expanded(
                        child: Text('Payment Method', textAlign: TextAlign.right),
                      ),
                      SizedBox(width: 75),
                      Text('Cash')
                    ],
                  ),
                ),
                Row(
                  children: [
                    Expanded(
                      child: Text('Payment Received', textAlign: TextAlign.right,),
                    ),
                    SizedBox(width: 80),
                    Text('5.00')
                  ],
                ),
                Row(
                  children: [
                    Expanded(
                      flex: 1,
                      child: Text('Change', textAlign: TextAlign.right,),
                    ),
                    SizedBox(width: 80),
                    Text('1.60')
                  ],
                ),
                SizedBox(height: 20),
                Visibility(
                    visible: footerImage ? true : false,
                    child: Center(
                      child: CircleAvatar(
                        radius: 30,
                        backgroundColor: Colors.black,
                        child: Text(AppLocalizations.of(context)!.translate('footer')),
                      ),
                    )
                ),
                SizedBox(height: 10),
                Visibility(
                    visible: footerText ? true : false,
                    child: Center(
                      child: Text('${footerTextString}',
                          maxLines: 3,
                          textAlign: TextAlign.center,
                          style: TextStyle(fontWeight: FontWeight.bold)),
                    )
                ),
                SizedBox(height: 10),
                Container(
                  child: Center(
                    child: Text('POWERED BY OPTIMY POS', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                )
              ],
            ),
          )
      ),
      SizedBox(width: 25),
      Expanded(
        flex: 1,
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  alignment: Alignment.topLeft,
                  child: Text(AppLocalizations.of(context)!.translate('logo_text'), style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey)),
                ),
                Spacer(),
                Switch(
                    value: logoText,
                    activeColor: color.backgroundColor,
                    onChanged: (bool value){
                      setState(() {
                        logoText = value;
                      });
                    })
              ],
            ),
            Visibility(
              visible: logoText ? true : false,
              child: Container(
                child: ValueListenableBuilder(
                  // Note: pass _controller to the animation argument
                    valueListenable: headerTextController,
                    builder: (context, TextEditingValue value, __) {
                      return SizedBox(
                        height: 80,
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: TextField(
                            onChanged: (value){
                              setState(() {
                                headerText = value;
                              });
                            },
                            controller: headerTextController,
                            decoration: InputDecoration(
                              errorText: _submitted
                                  ? errorHeaderText == null
                                  ? errorHeaderText
                                  : AppLocalizations.of(context)
                                  ?.translate(errorHeaderText!)
                                  : null,
                              border: OutlineInputBorder(
                                borderSide: BorderSide(
                                    color: color.backgroundColor),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderSide: BorderSide(
                                    color: color.backgroundColor),
                              ),
                              labelText: AppLocalizations.of(context)!.translate('logo_text_here'),
                            ),
                          ),
                        ),
                      );
                    }),
              ),
            ),
            Visibility(
                visible: logoText ? true : false,
                child: Column(
                  children: [
                    Container(
                      alignment: Alignment.topLeft,
                      child: Text(AppLocalizations.of(context)!.translate('logo_font_size'), style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey)),
                    ),
                    RadioListTile<ReceiptDialogEnum?>(
                      value: ReceiptDialogEnum.big,
                      groupValue: headerFontSize,
                      onChanged: (value) async  {
                        setState(() {
                          headerFontSize = value;
                          fontSize = 30.0;
                        });
                      },
                      title: Text(AppLocalizations.of(context)!.translate('big')),
                      controlAffinity: ListTileControlAffinity.trailing,
                    ),
                    RadioListTile<ReceiptDialogEnum?>(
                      value: ReceiptDialogEnum.small,
                      groupValue: headerFontSize,
                      onChanged: (value) async  {
                        setState(() {
                          headerFontSize = value;
                          fontSize = 12.0;
                        });
                      },
                      title: Text(AppLocalizations.of(context)!.translate('small')),
                      controlAffinity: ListTileControlAffinity.trailing,
                    ),
                  ],
                )
            ),
            Row(
              children: [
                Container(
                  alignment: Alignment.topLeft,
                  child: Text(AppLocalizations.of(context)!.translate('show_address'), style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey)),
                ),
                Spacer(),
                Container(
                  child: Switch(
                      value: showAddress,
                      activeColor: color.backgroundColor,
                      onChanged: branchObject!['address'] != '' ? (bool value){
                        setState(() {
                          showAddress = value;
                        });
                      } :
                          (bool value){
                        Fluttertoast.showToast(msg: AppLocalizations.of(context)!.translate('no_branch_address_added'));
                      }
                  ),
                )
              ],
            ),
            Row(
              children: [
                Container(
                  alignment: Alignment.topLeft,
                  child: Text(AppLocalizations.of(context)!.translate('show_email'), style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey)),
                ),
                Spacer(),
                Switch(
                    value: showEmail,
                    activeColor: color.backgroundColor,
                    onChanged: (bool value){
                      setState(() {
                        showEmail = value;
                        if(widget.receiptObject!.show_email == 0 && showEmail ==true){
                          emailAddress = widget.receiptObject!.receipt_email;
                          emailTextController.text = widget.receiptObject!.receipt_email!;
                        }
                      });
                    })
              ],
            ),
            Visibility(
              visible: showEmail ? true : false,
              child: ValueListenableBuilder(
                // Note: pass _controller to the animation argument
                  valueListenable: emailTextController,
                  builder: (context, TextEditingValue value, __) {
                    return SizedBox(
                      height: 80,
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: TextField(
                          onChanged: (value){
                            setState(() {
                              print('value: $value');
                              emailAddress = value;
                            });
                          },
                          controller: emailTextController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: InputDecoration(
                            errorText: _submitted
                                ? errorEmailText == null
                                ? errorEmailText
                                : AppLocalizations.of(context)
                                ?.translate(errorEmailText!)
                                : null,
                            border: OutlineInputBorder(
                              borderSide: BorderSide(
                                  color: color.backgroundColor),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                  color: color.backgroundColor),
                            ),
                            labelText: AppLocalizations.of(context)!.translate('email_here'),
                          ),
                        ),
                      ),
                    );
                  }),
            ),
            Row(
              children: [
                Container(
                  alignment: Alignment.topLeft,
                  child: Text(AppLocalizations.of(context)!.translate('footer_text'), style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey)),
                ),
                Spacer(),
                Container(
                  child: Switch(
                      value: footerText,
                      activeColor: color.backgroundColor,
                      onChanged: (bool value){
                        setState(() {
                          footerText = value;
                        });
                      }),
                )
              ],
            ),
            Visibility(
              visible: footerText ? true : false,
              child: ValueListenableBuilder(
                // Note: pass _controller to the animation argument
                  valueListenable: footerTextController,
                  builder: (context, TextEditingValue value, __) {
                    return Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: TextField(
                          onChanged: (value){
                            setState(() {
                              footerTextString = value;
                            });
                          },
                          controller: footerTextController,
                          decoration: InputDecoration(
                            helperText: AppLocalizations.of(context)!.translate('max_3_lines'),
                            isDense: true,
                            focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: color.backgroundColor),
                            ),
                          ),
                          keyboardType: TextInputType.multiline,
                          maxLines: 3,
                          maxLength: 40,
                        )
                      // TextField(
                      //   onChanged: (value){
                      //     setState(() {
                      //       footerTextString = value;
                      //     });
                      //   },
                      //   controller: footerTextController,
                      //   decoration: InputDecoration(
                      //     errorText: _submitted
                      //         ? errorFooterText == null
                      //         ? errorFooterText
                      //         : AppLocalizations.of(context)
                      //         ?.translate(errorFooterText!)
                      //         : null,
                      //     border: OutlineInputBorder(
                      //       borderSide: BorderSide(
                      //           color: color.backgroundColor),
                      //     ),
                      //     focusedBorder: OutlineInputBorder(
                      //       borderSide: BorderSide(
                      //           color: color.backgroundColor),
                      //     ),
                      //     labelText: 'footer text here',
                      //   ),
                      // ),
                    );
                  }),
            ),
            // Row(
            //   children: [
            //     Container(
            //       alignment: Alignment.topLeft,
            //       child: Text('Show tax detail', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey)),
            //     ),
            //     Spacer(),
            //     Container(
            //       child: Switch(
            //           value: showTaxDetail,
            //           activeColor: color.backgroundColor,
            //           onChanged: (bool value){
            //             setState(() {
            //               showTaxDetail = value;
            //             });
            //           }
            //       ),
            //     )
            //   ],
            // ),
            Row(
              children: [
                Container(
                  alignment: Alignment.topLeft,
                  child: Text(AppLocalizations.of(context)!.translate('show_promotion_detail'), style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey)),
                ),
                Spacer(),
                Container(
                  child: Switch(
                      value: promoDetail,
                      activeColor: color.backgroundColor,
                      onChanged: (bool value){
                        setState(() {
                          promoDetail = value;
                        });
                      }),
                )
              ],
            ),
          ],
        ),
      )
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
            padding: MediaQuery.of(context).size.width > 1300 ? EdgeInsets.fromLTRB(50, 20, 50, 20) : EdgeInsets.fromLTRB(20, 20, 20, 20) ,
            child: Column(
              // crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Visibility(
                    visible: logoImage ? true : false,
                    child: Center(
                      child: CircleAvatar(
                        radius: 30,
                        backgroundColor: Colors.black,
                        child: Text(AppLocalizations.of(context)!.translate('logo')),
                      ),
                    )
                ),
                Visibility(
                    visible: logoText ? true : false,
                    child: Center(
                      child: Text('${headerText}', style: TextStyle(fontSize: fontSize, fontWeight: FontWeight.bold)),
                    )
                ),
                Center(
                  child: Column(
                    children: [
                      Visibility(
                        visible: showAddress ? true : false,
                        child: Text('Jalan permas baru'),
                      ),
                      Text('Tel: 07-3456789'),
                      Visibility(
                        visible: showEmail? true : false,
                        child: Text('${emailAddress}'),
                      )
                    ],
                  ),
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(0.0, 5.0, 0.0, 5.0),
                  child: DottedLine(),
                ),
                Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  //crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text('Receipt No:', style: TextStyle(fontWeight: FontWeight.bold)),
                    Text('#00001-001-12345678', style: TextStyle(fontWeight: FontWeight.bold)),
                    Text('Close At:'),
                    Text('31/12/2021 00:00 AM'),
                    Text('Close By:'),
                    Text('Waiter'),
                    Text('Table No: 1', textAlign: TextAlign.center),
                    Text('Dine In', textAlign: TextAlign.center),
                  ],
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(0.0, 5.0, 0.0, 5.0),
                  child: DottedLine(),
                ),
                Row(
                  children: [
                    Expanded(
                      flex: 1,
                      child: Text('Qty', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                    Expanded(
                      flex: 3,
                      child: Text('Item', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text('Price', style: TextStyle(fontWeight: FontWeight.bold)),
                    )
                  ],
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(0.0, 5.0, 0.0, 5.0),
                  child: DottedLine(),
                ),
                Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          flex: 1,
                          child: Text('2'),
                        ),
                        Expanded(
                          flex: 3,
                          child: Text('Product 1', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text('4.00', textAlign: TextAlign.left),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Expanded(
                          flex: 1,
                          child: Text(''),
                        ),
                        Expanded(
                          flex: 3,
                          child: Text('(2.00/each)', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text('', textAlign: TextAlign.left),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Expanded(
                          flex: 1,
                          child: Text('1'),
                        ),
                        Expanded(
                          flex: 3,
                          child: Text('Product 2', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text('2.00'),
                        )
                      ],
                    ),
                    Row(
                      children: [
                        Expanded(
                          flex: 1,
                          child: Text(''),
                        ),
                        Expanded(
                          flex: 3,
                          child: Text('(2.00/each)', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(''),
                        )
                      ],
                    ),
                  ],
                ),
                // Container(
                //   child: Row(
                //     children: [
                //       Expanded(
                //         flex: 2,
                //         child: Text('product1', style: TextStyle(fontWeight: FontWeight.bold)),
                //       ),
                //       Expanded(
                //         flex: 1,
                //         child: Text('2'),
                //       ),
                //       Expanded(
                //         flex: 0,
                //         child: Text('2.00'),
                //       )
                //     ],
                //   ),
                // ),
                // Container(
                //   child: Row(
                //     children: [
                //       Expanded(
                //         flex: 2,
                //         child: Text('product2', style: TextStyle(fontWeight: FontWeight.bold)),
                //       ),
                //       Expanded(
                //         flex: 1,
                //         child: Text('1'),
                //       ),
                //       Expanded(
                //         flex: 0,
                //         child: Text('2.00'),
                //       )
                //     ],
                //   ),
                // ),
                Padding(
                  padding: EdgeInsets.fromLTRB(0.0, 5.0, 0.0, 5.0),
                  child: DottedLine(),
                ),
                Container(
                  alignment: Alignment.topLeft,
                  child: Text('Item Count: 3', textAlign: TextAlign.left),
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(0.0, 5.0, 0.0, 5.0),
                  child: DottedLine(),
                ),
                Row(
                  children: [
                    Expanded(
                      child: Text('Subtotal', textAlign: TextAlign.left),
                    ),
                    Expanded(child: Text('')),
                    Expanded(child: Text('6.00'))
                  ],
                ),
                Row(
                  children: [
                    Expanded(
                      child: Text('Total discount', textAlign: TextAlign.left),
                    ),
                    Expanded(child: Text('')),
                    Expanded(child: Text('-2.00', textAlign: TextAlign.left,))
                  ],
                ),
                Visibility(
                    visible: showTaxDetail ? true : false,
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text('Tax1(10%)', textAlign: TextAlign.left),
                            ),
                            Expanded(child: Text('')),
                            Expanded(child: Text('0.40'))
                          ],
                        ),
                        Row(
                          children: [
                            Expanded(
                              child: Text('Tax2(6%)', textAlign: TextAlign.left),
                            ),
                            Expanded(child: Text('')),
                            Expanded(child: Text('0.24'))
                          ],
                        ),
                      ],
                    )
                ),
                // Visibility(
                //     visible: !showTaxDetail ? true : false,
                //     child: Row(
                //       children: [
                //         Expanded(
                //           flex: 1,
                //           child: Text(''),
                //         ),
                //         Expanded(
                //           flex: 1,
                //           child: Text(''),
                //         ),
                //         Expanded(
                //           flex: 0,
                //           child: Text('Tax inc.'),
                //         )
                //       ],
                //     ),
                // ),
                Row(
                  children: [
                    Expanded(
                      child: Text('Amount', textAlign: TextAlign.left),
                    ),
                    Expanded(child: Text('')),
                    Expanded(child: Text('3.36'))
                  ],
                ),
                Row(
                  children: [
                    Expanded(
                      child: Text('Rounding', textAlign: TextAlign.left),
                    ),
                    Expanded(child: Text('')),
                    Expanded(child: Text('+0.04',))
                  ],
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(0.0, 5.0, 0.0, 5.0),
                  child: DottedLine(),
                ),
                Row(
                  children: [
                    Expanded(
                      child: Text('Final Amount', textAlign: TextAlign.left, style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                    Expanded(child: Text('')),
                    Expanded(child: Text('3.40', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)))
                  ],
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(0.0, 5.0, 0.0, 5.0),
                  child: DottedLine(),
                ),
                Row(
                  children: [
                    Text('Payment Method', textAlign: TextAlign.left),
                    Expanded(child: Text('')),
                    Expanded(child: Text('Cash'))
                  ],
                ),
                Row(
                  children: [
                    Text('Payment Received', textAlign: TextAlign.left),
                    // SizedBox(width: 80),
                    Expanded(child: Text('')),
                    Expanded(child: Text('5.00')),
                  ],
                ),
                Row(
                  children: [
                    Expanded(
                      child: Text('Change', textAlign: TextAlign.left),
                    ),
                    Expanded(child: Text('')),
                    Expanded(child: Text('1.60'))
                  ],
                ),
                SizedBox(height: 20),
                Visibility(
                    visible: footerImage ? true : false,
                    child: Center(
                      child: CircleAvatar(
                        radius: 30,
                        backgroundColor: Colors.black,
                        child: Text(AppLocalizations.of(context)!.translate('footer')),
                      ),
                    )
                ),
                SizedBox(height: 10),
                Visibility(
                    visible: footerText ? true : false,
                    child: Center(
                      child: Text('${footerTextString}',
                          maxLines: 3,
                          textAlign: TextAlign.center,
                          style: TextStyle(fontWeight: FontWeight.bold)),
                    )
                ),
                SizedBox(height: 10),
                Container(
                  child: Center(
                    child: Text('POWERED BY OPTIMY POS', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                )
              ],
            ),
          )
      ),
      SizedBox(width: 25),
      Expanded(
        flex: 1,
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  alignment: Alignment.topLeft,
                  child: Text(AppLocalizations.of(context)!.translate('logo_text'), style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey)),
                ),
                Spacer(),
                Switch(
                    value: logoText,
                    activeColor: color.backgroundColor,
                    onChanged: (bool value){
                      setState(() {
                        logoText = value;
                      });
                    })
              ],
            ),
            Visibility(
              visible: logoText ? true : false,
              child: ValueListenableBuilder(
                // Note: pass _controller to the animation argument
                  valueListenable: headerTextController,
                  builder: (context, TextEditingValue value, __) {
                    return SizedBox(
                      height: 80,
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: TextField(
                          onChanged: (value){
                            setState(() {
                              headerText = value;
                            });
                          },
                          controller: headerTextController,
                          decoration: InputDecoration(
                            errorText: _submitted
                                ? errorHeaderText == null
                                ? errorHeaderText
                                : AppLocalizations.of(context)
                                ?.translate(errorHeaderText!)
                                : null,
                            border: OutlineInputBorder(
                              borderSide: BorderSide(
                                  color: color.backgroundColor),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                  color: color.backgroundColor),
                            ),
                            labelText: AppLocalizations.of(context)!.translate('logo_text_here'),
                          ),
                        ),
                      ),
                    );
                  }),
            ),
            Visibility(
                visible: logoText ? true : false,
                child: Column(
                  children: [
                    Container(
                      alignment: Alignment.topLeft,
                      child: Text(AppLocalizations.of(context)!.translate('logo_font_size'), style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey)),
                    ),
                    RadioListTile<ReceiptDialogEnum?>(
                      value: ReceiptDialogEnum.big,
                      groupValue: headerFontSize,
                      onChanged: (value) async  {
                        setState(() {
                          headerFontSize = value;
                          fontSize = 30.0;
                        });
                      },
                      title: Text(AppLocalizations.of(context)!.translate('big')),
                      controlAffinity: ListTileControlAffinity.trailing,
                    ),
                    RadioListTile<ReceiptDialogEnum?>(
                      value: ReceiptDialogEnum.small,
                      groupValue: headerFontSize,
                      onChanged: (value) async  {
                        setState(() {
                          headerFontSize = value;
                          fontSize = 12.0;
                        });
                      },
                      title: Text(AppLocalizations.of(context)!.translate('small')),
                      controlAffinity: ListTileControlAffinity.trailing,
                    ),
                  ],
                )
            ),
            Row(
              children: [
                Container(
                  alignment: Alignment.topLeft,
                  child: Text(AppLocalizations.of(context)!.translate('show_address'), style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey)),
                ),
                Spacer(),
                Switch(
                    value: showAddress,
                    activeColor: color.backgroundColor,
                    onChanged: branchObject!['address'] != '' ? (bool value){
                      setState(() {
                        showAddress = value;
                      });
                    } :
                        (bool value){
                      Fluttertoast.showToast(msg: AppLocalizations.of(context)!.translate('no_branch_address_added'));
                    }
                )
              ],
            ),
            Row(
              children: [
                Container(
                  alignment: Alignment.topLeft,
                  child: Text(AppLocalizations.of(context)!.translate('show_email'), style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey)),
                ),
                Spacer(),
                Switch(
                    value: showEmail,
                    activeColor: color.backgroundColor,
                    onChanged: (bool value){
                      setState(() {
                        showEmail = value;
                        if(widget.receiptObject!.show_email == 0 && showEmail ==true){
                          emailAddress = widget.receiptObject!.receipt_email;
                          emailTextController.text = widget.receiptObject!.receipt_email!;
                        }
                      });
                    })
              ],
            ),
            Visibility(
              visible: showEmail ? true : false,
              child: ValueListenableBuilder(
                // Note: pass _controller to the animation argument
                  valueListenable: emailTextController,
                  builder: (context, TextEditingValue value, __) {
                    return SizedBox(
                      height: 80,
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: TextField(
                          onChanged: (value){
                            setState(() {
                              print('value: $value');
                              emailAddress = value;
                            });
                          },
                          controller: emailTextController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: InputDecoration(
                            errorText: _submitted
                                ? errorEmailText == null
                                ? errorEmailText
                                : AppLocalizations.of(context)
                                ?.translate(errorEmailText!)
                                : null,
                            border: OutlineInputBorder(
                              borderSide: BorderSide(
                                  color: color.backgroundColor),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                  color: color.backgroundColor),
                            ),
                            labelText: AppLocalizations.of(context)!.translate('email_here'),
                          ),
                        ),
                      ),
                    );
                  }),
            ),
            Row(
              children: [
                Container(
                  alignment: Alignment.topLeft,
                  child: Text(AppLocalizations.of(context)!.translate('footer_text'), style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey)),
                ),
                Spacer(),
                Switch(
                    value: footerText,
                    activeColor: color.backgroundColor,
                    onChanged: (bool value){
                      setState(() {
                        footerText = value;
                      });
                    })
              ],
            ),
            Visibility(
              visible: footerText ? true : false,
              child: ValueListenableBuilder(
                // Note: pass _controller to the animation argument
                  valueListenable: footerTextController,
                  builder: (context, TextEditingValue value, __) {
                    return Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: TextField(
                          onChanged: (value){
                            setState(() {
                              footerTextString = value;
                            });
                          },
                          controller: footerTextController,
                          decoration: InputDecoration(
                            helperText: AppLocalizations.of(context)!.translate('max_3_lines'),
                            isDense: true,
                            focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: color.backgroundColor),
                            ),
                          ),
                          keyboardType: TextInputType.multiline,
                          maxLines: 3,
                          maxLength: 40,
                        )
                      // TextField(
                      //   onChanged: (value){
                      //     setState(() {
                      //       footerTextString = value;
                      //     });
                      //   },
                      //   controller: footerTextController,
                      //   decoration: InputDecoration(
                      //     errorText: _submitted
                      //         ? errorFooterText == null
                      //         ? errorFooterText
                      //         : AppLocalizations.of(context)
                      //         ?.translate(errorFooterText!)
                      //         : null,
                      //     border: OutlineInputBorder(
                      //       borderSide: BorderSide(
                      //           color: color.backgroundColor),
                      //     ),
                      //     focusedBorder: OutlineInputBorder(
                      //       borderSide: BorderSide(
                      //           color: color.backgroundColor),
                      //     ),
                      //     labelText: 'footer text here',
                      //   ),
                      // ),
                    );
                  }),
            ),
            // Row(
            //   children: [
            //     Container(
            //       alignment: Alignment.topLeft,
            //       child: Text('Show tax detail', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey)),
            //     ),
            //     Spacer(),
            //     Container(
            //       child: Switch(
            //           value: showTaxDetail,
            //           activeColor: color.backgroundColor,
            //           onChanged: (bool value){
            //             setState(() {
            //               showTaxDetail = value;
            //             });
            //           }
            //       ),
            //     )
            //   ],
            // ),
          ],
        ),
      )
    ],
  );

  Widget MobileReceiptView1(ThemeColor color) => Column(
    children: [
      Container(
        alignment: Alignment.topLeft,
        child: Text(AppLocalizations.of(context)!.translate('logo_font_size'), style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey)),
      ),
      RadioListTile<ReceiptDialogEnum?>(
        value: ReceiptDialogEnum.big,
        groupValue: headerFontSize,
        onChanged: (value) async  {
          setState(() {
            headerFontSize = value;
          });
        },
        title: Text(AppLocalizations.of(context)!.translate('big')),
        controlAffinity: ListTileControlAffinity.trailing,
      ),
      RadioListTile<ReceiptDialogEnum?>(
        value: ReceiptDialogEnum.small,
        groupValue: headerFontSize,
        onChanged: (value) async  {
         setState(() {
           headerFontSize = value;
         });
        },
        title: Text(AppLocalizations.of(context)!.translate('small')),
        controlAffinity: ListTileControlAffinity.trailing,
      ),
      Row(
        children: [
          Container(
            alignment: Alignment.topLeft,
            child: Text(AppLocalizations.of(context)!.translate('logo_text'), style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey)),
          ),
          Spacer(),
          Switch(
              value: logoText,
              activeColor: color.backgroundColor,
              onChanged: (bool value){
                setState(() {
                  logoText = value;
                });
              })
        ],
      ),
      Visibility(
        visible: logoText ? true : false,
        child: ValueListenableBuilder(
          // Note: pass _controller to the animation argument
            valueListenable: headerTextController,
            builder: (context, TextEditingValue value, __) {
              return SizedBox(
                height: MediaQuery.of(context).size.height / 4,
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TextField(
                    controller: headerTextController,
                    decoration: InputDecoration(
                      errorText: _submitted
                          ? errorHeaderText == null
                          ? errorHeaderText
                          : AppLocalizations.of(context)
                          ?.translate(errorHeaderText!)
                          : null,
                      border: OutlineInputBorder(
                        borderSide: BorderSide(
                            color: color.backgroundColor),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                            color: color.backgroundColor),
                      ),
                      labelText: AppLocalizations.of(context)!.translate('logo_text_here'),
                    ),
                  ),
                ),
              );
            }),
      ),
      Row(
        children: [
          Container(
            alignment: Alignment.topLeft,
            child: Text(AppLocalizations.of(context)!.translate('show_address'), style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey)),
          ),
          Spacer(),
          Switch(
              value: showAddress,
              activeColor: color.backgroundColor,
              onChanged: branchObject!['address'] != '' ? (bool value){
                setState(() {
                  showAddress = value;
                });
              } :
                  (bool value){
                Fluttertoast.showToast(msg: AppLocalizations.of(context)!.translate('no_branch_address_added'));
              }
          )
        ],
      ),
      Row(
        children: [
          Container(
            alignment: Alignment.topLeft,
            child: Text(AppLocalizations.of(context)!.translate('show_email'), style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey)),
          ),
          Spacer(),
          Switch(
              value: showEmail,
              activeColor: color.backgroundColor,
              onChanged: (bool value){
                setState(() {
                  showEmail = value;
                  if(widget.receiptObject!.show_email == 0 && showEmail ==true){
                    emailAddress = widget.receiptObject!.receipt_email;
                    emailTextController.text = widget.receiptObject!.receipt_email!;
                  }
                });
              })
        ],
      ),
      Visibility(
        visible: showEmail ? true : false,
        child: ValueListenableBuilder(
          // Note: pass _controller to the animation argument
            valueListenable: emailTextController,
            builder: (context, TextEditingValue value, __) {
              return SizedBox(
                height: 80,
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TextField(
                    onChanged: (value){
                      setState(() {
                        print('value: $value');
                        emailAddress = value;
                      });
                    },
                    controller: emailTextController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      errorText: _submitted
                          ? errorEmailText == null
                          ? errorEmailText
                          : AppLocalizations.of(context)
                          ?.translate(errorEmailText!)
                          : null,
                      border: OutlineInputBorder(
                        borderSide: BorderSide(
                            color: color.backgroundColor),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                            color: color.backgroundColor),
                      ),
                      labelText: AppLocalizations.of(context)!.translate('email_here'),
                    ),
                  ),
                ),
              );
            }),
      ),
      Row(
        children: [
          Container(
            alignment: Alignment.topLeft,
            child: Text(AppLocalizations.of(context)!.translate('footer_text'), style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey)),
          ),
          Spacer(),
          Switch(
              value: footerText,
              activeColor: color.backgroundColor,
              onChanged: (bool value){
                setState(() {
                  footerText = value;
                });
              })
        ],
      ),
      Visibility(
        visible: footerText ? true : false,
        child: ValueListenableBuilder(
          // Note: pass _controller to the animation argument
            valueListenable: footerTextController,
            builder: (context, TextEditingValue value, __) {
              return SizedBox(
                height: MediaQuery.of(context).size.height / 4,
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TextField(
                    controller: footerTextController,
                    decoration: InputDecoration(
                      errorText: _submitted
                          ? errorFooterText == null
                          ? errorFooterText
                          : AppLocalizations.of(context)
                          ?.translate(errorFooterText!)
                          : null,
                      border: OutlineInputBorder(
                        borderSide: BorderSide(
                            color: color.backgroundColor),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                            color: color.backgroundColor),
                      ),
                      labelText: AppLocalizations.of(context)!.translate('footer_text_here'),
                    ),
                  ),
                ),
              );
            }),
      ),
      Row(
        children: [
          Expanded(
            child: Text(AppLocalizations.of(context)!.translate('show_promotion_detail'), style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey)),
          ),
          Spacer(),
          Switch(
              value: promoDetail,
              activeColor: color.backgroundColor,
              onChanged: (bool value){
                setState(() {
                  promoDetail = value;
                });
              })
        ],
      ),
    ],
  );

  Widget MobileReceiptView2(ThemeColor color) => Column(
    children: [
      Container(
        alignment: Alignment.topLeft,
        child: Text(AppLocalizations.of(context)!.translate('logo_font_size'), style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey)),
      ),
      RadioListTile<ReceiptDialogEnum?>(
        value: ReceiptDialogEnum.big,
        groupValue: headerFontSize,
        onChanged: (value) async  {
          setState(() {
            headerFontSize = value;
          });
        },
        title: Text(AppLocalizations.of(context)!.translate('big')),
        controlAffinity: ListTileControlAffinity.trailing,
      ),
      RadioListTile<ReceiptDialogEnum?>(
        value: ReceiptDialogEnum.small,
        groupValue: headerFontSize,
        onChanged: (value) async  {
          setState(() {
            headerFontSize = value;
          });
        },
        title: Text(AppLocalizations.of(context)!.translate('small')),
        controlAffinity: ListTileControlAffinity.trailing,
      ),
      Row(
        children: [
          Container(
            alignment: Alignment.topLeft,
            child: Text(AppLocalizations.of(context)!.translate('logo_text'), style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey)),
          ),
          Spacer(),
          Switch(
              value: logoText,
              activeColor: color.backgroundColor,
              onChanged: (bool value){
                setState(() {
                  logoText = value;
                });
              })
        ],
      ),
      Visibility(
        visible: logoText ? true : false,
        child: ValueListenableBuilder(
          // Note: pass _controller to the animation argument
            valueListenable: headerTextController,
            builder: (context, TextEditingValue value, __) {
              return SizedBox(
                height: MediaQuery.of(context).size.height / 4,
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TextField(
                    controller: headerTextController,
                    decoration: InputDecoration(
                      errorText: _submitted
                          ? errorHeaderText == null
                          ? errorHeaderText
                          : AppLocalizations.of(context)
                          ?.translate(errorHeaderText!)
                          : null,
                      border: OutlineInputBorder(
                        borderSide: BorderSide(
                            color: color.backgroundColor),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                            color: color.backgroundColor),
                      ),
                      labelText: AppLocalizations.of(context)!.translate('logo_text_here'),
                    ),
                  ),
                ),
              );
            }),
      ),
      Row(
        children: [
          Container(
            alignment: Alignment.topLeft,
            child: Text(AppLocalizations.of(context)!.translate('show_address'), style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey)),
          ),
          Spacer(),
          Switch(
              value: showAddress,
              activeColor: color.backgroundColor,
              onChanged: branchObject!['address'] != '' ? (bool value){
                setState(() {
                  showAddress = value;
                });
              } :
                  (bool value){
                Fluttertoast.showToast(msg: AppLocalizations.of(context)!.translate('no_branch_address_added'));
              }
          )
        ],
      ),
      Row(
        children: [
          Container(
            alignment: Alignment.topLeft,
            child: Text(AppLocalizations.of(context)!.translate('show_email'), style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey)),
          ),
          Spacer(),
          Switch(
              value: showEmail,
              activeColor: color.backgroundColor,
              onChanged: (bool value){
                setState(() {
                  showEmail = value;
                  if(widget.receiptObject!.show_email == 0 && showEmail ==true){
                    emailAddress = widget.receiptObject!.receipt_email;
                    emailTextController.text = widget.receiptObject!.receipt_email!;
                  }
                });
              })
        ],
      ),
      Visibility(
        visible: showEmail ? true : false,
        child: ValueListenableBuilder(
          // Note: pass _controller to the animation argument
            valueListenable: emailTextController,
            builder: (context, TextEditingValue value, __) {
              return SizedBox(
                height: 80,
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TextField(
                    onChanged: (value){
                      setState(() {
                        print('value: $value');
                        emailAddress = value;
                      });
                    },
                    controller: emailTextController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      errorText: _submitted
                          ? errorEmailText == null
                          ? errorEmailText
                          : AppLocalizations.of(context)
                          ?.translate(errorEmailText!)
                          : null,
                      border: OutlineInputBorder(
                        borderSide: BorderSide(
                            color: color.backgroundColor),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                            color: color.backgroundColor),
                      ),
                      labelText: AppLocalizations.of(context)!.translate('email_here'),
                    ),
                  ),
                ),
              );
            }),
      ),
      Row(
        children: [
          Container(
            alignment: Alignment.topLeft,
            child: Text(AppLocalizations.of(context)!.translate('footer_text'), style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey)),
          ),
          Spacer(),
          Switch(
              value: footerText,
              activeColor: color.backgroundColor,
              onChanged: (bool value){
                setState(() {
                  footerText = value;
                });
              })
        ],
      ),
      Visibility(
        visible: footerText ? true : false,
        child: ValueListenableBuilder(
          // Note: pass _controller to the animation argument
            valueListenable: footerTextController,
            builder: (context, TextEditingValue value, __) {
              return SizedBox(
                height: MediaQuery.of(context).size.height / 4,
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TextField(
                    controller: footerTextController,
                    decoration: InputDecoration(
                      errorText: _submitted
                          ? errorFooterText == null
                          ? errorFooterText
                          : AppLocalizations.of(context)
                          ?.translate(errorFooterText!)
                          : null,
                      border: OutlineInputBorder(
                        borderSide: BorderSide(
                            color: color.backgroundColor),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                            color: color.backgroundColor),
                      ),
                      labelText: AppLocalizations.of(context)!.translate('footer_text_here'),
                    ),
                  ),
                ),
              );
            }),
      ),
    ],
  );

}
