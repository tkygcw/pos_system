import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:pos_system/database/pos_database.dart';
import 'package:pos_system/object/receipt.dart';
import 'package:pos_system/page/progress_bar.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../notifier/theme_color.dart';
import '../../translation/AppLocalizations.dart';

class ReceiptDialog extends StatefulWidget {
  final Function() callBack;
  final Receipt? receiptObject;
  final List<Receipt> allReceiptList;
  const ReceiptDialog({Key? key, required this.callBack, required this.receiptObject, required this.allReceiptList}) : super(key: key);

  @override
  State<ReceiptDialog> createState() => _ReceiptDialogState();
}

class _ReceiptDialogState extends State<ReceiptDialog> {
  final headerTextController = TextEditingController();
  final footerTextController = TextEditingController();
  File? headerImage;
  File? footerImg;
  String? headerDir;
  String? footerDir;
  bool isLoad = false;
  bool _isUpdate = false;
  bool logoImage = true;
  bool footerImage = true;
  bool logoText = false;
  bool footerText = false;

  @override
  void initState() {
    // TODO: implement initState
    if (widget.receiptObject != null) {
      _isUpdate = true;
      widget.receiptObject!.header_image_status == 1 ? this.logoImage = true  : this.logoImage = false;
      widget.receiptObject!.footer_image_status == 1 ? this.footerImage = true  : this.footerImage = false;
      widget.receiptObject!.header_text_status == 1 ? this.logoText = true : this.logoText = false;
      widget.receiptObject!.footer_text_status == 1 ? this.footerText = true : this.footerText = false;
      headerTextController.text = widget.receiptObject!.header_text!;
      footerTextController.text = widget.receiptObject!.footer_text!;
      isLoad = true;
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
    footerTextController.dispose();
  }

  void _submit(BuildContext context) {
    !_isUpdate ? createReceiptLayout() : setLayoutInUse(widget.receiptObject!);
  }

  closeDialog(BuildContext context) {
    return Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeColor>(builder: (context, ThemeColor color, child) {
      return AlertDialog(
        title: !_isUpdate ? Text('Add receipt layout') : Text("Receipt Layout"),
        content: isLoad ?
        Container(
          height: MediaQuery.of(context).size.height / 1.75,
          width: MediaQuery.of(context).size.width / 4,
          child: SingleChildScrollView(
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      alignment: Alignment.topLeft,
                      child: Text('Logo image', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey)),
                    ),
                    Spacer(),
                    Container(
                      child: Switch(
                          value: logoImage,
                          activeColor: color.backgroundColor,
                          onChanged: !_isUpdate ?  (bool value){
                            setState(() {
                              logoImage = value;
                            });
                          }: null ),
                    )
                  ],
                ),
                Row(
                  children: [
                    Container(
                      alignment: Alignment.topLeft,
                      child: Text('Footer image', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey)),
                    ),
                    Spacer(),
                    Container(
                      child: Switch(
                          value: footerImage,
                          activeColor: color.backgroundColor,
                          onChanged: !_isUpdate ? (bool value){
                            setState(() {
                              footerImage = value;
                            });
                          }: null),
                    )
                  ],
                ),
                Row(
                  children: [
                    Container(
                      alignment: Alignment.topLeft,
                      child: Text('Logo text', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey)),
                    ),
                    Spacer(),
                    Container(
                      child: Switch(
                          value: logoText,
                          activeColor: color.backgroundColor,
                          onChanged: !_isUpdate ? (bool value){
                            setState(() {
                              logoText = value;
                            });
                          } : null),
                    )
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
                            height: MediaQuery.of(context).size.height / 8,
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: TextField(
                                enabled: _isUpdate ? false : true,
                                controller: headerTextController,
                                decoration: InputDecoration(
                                  border: OutlineInputBorder(
                                    borderSide: BorderSide(
                                        color: color.backgroundColor),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderSide: BorderSide(
                                        color: color.backgroundColor),
                                  ),
                                  labelText: 'Logo text here',
                                ),
                              ),
                            ),
                          );
                        }),
                  ),
                ),
                Row(
                  children: [
                    Container(
                      alignment: Alignment.topLeft,
                      child: Text('Footer text', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey)),
                    ),
                    Spacer(),
                    Container(
                      child: Switch(
                          value: footerText,
                          activeColor: color.backgroundColor,
                          onChanged: !_isUpdate ? (bool value){
                            setState(() {
                              footerText = value;
                            });
                          } : null),
                    )
                  ],
                ),
                Visibility(
                  visible: footerText ? true : false,
                  child: Container(
                    child: ValueListenableBuilder(
                      // Note: pass _controller to the animation argument
                        valueListenable: footerTextController,
                        builder: (context, TextEditingValue value, __) {
                          return SizedBox(
                            height: MediaQuery.of(context).size.height / 8,
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: TextField(
                                enabled: _isUpdate ? false : true,
                                controller: footerTextController,
                                decoration: InputDecoration(
                                  border: OutlineInputBorder(
                                    borderSide: BorderSide(
                                        color: color.backgroundColor),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderSide: BorderSide(
                                        color: color.backgroundColor),
                                  ),
                                  labelText: 'footer text here',
                                ),
                              ),
                            ),
                          );
                        }),
                  ),
                ),
              ],
            ),
          ),
        ) : CustomProgressBar(),
        actions: <Widget>[
          TextButton(
            child: Text('${AppLocalizations.of(context)?.translate('close')}'),
            onPressed: () {
              closeDialog(context);
            },
          ),
          TextButton(
            child: !_isUpdate ? Text('${AppLocalizations.of(context)?.translate('add')}') : Text("Apply"),
            onPressed: () {
              _submit(context);
            },
          ),
        ],
      );
    });
  }

  createReceiptLayout() async {
    try{
      DateFormat dateFormat = DateFormat("yyyy-MM-dd HH:mm:ss");
      String dateTime = dateFormat.format(DateTime.now());
      final prefs = await SharedPreferences.getInstance();
      final int? branch_id = prefs.getInt('branch_id');

      Receipt data = await PosDatabase.instance.insertSqliteReceipt(Receipt(
        receipt_id: 0,
        branch_id: branch_id.toString(),
        company_id: '6',
        header_text: logoText == true ? headerTextController.text : '',
        footer_text: footerText == true ? footerTextController.text : '',
        header_image: logoImage == true ? 'branchLogo.jpg' : '',
        footer_image: footerImage == true ? 'branchFooter.jpg' : '',
        header_text_status: logoText == true ? 1 : 0,
        footer_text_status: footerText == true ? 1 : 0,
        header_image_status: logoImage == true ? 1 : 0,
        footer_image_status: footerImage == true ? 1 : 0,
        status: widget.allReceiptList.length == 0 ? 1 : 0,
        sync_status: 0,
        created_at: dateTime,
        updated_at: '',
        soft_delete: ''
      ));
      widget.callBack();
      closeDialog(context);
    }catch(e){
      Fluttertoast.showToast(
          backgroundColor: Color(0xFFFF0000),
          msg: "Fail to add receipt layout, Please try again $e");
      print('$e');
    }
  }

  setLayoutInUse(Receipt receipt) async {
    print('called');
    try{
      DateFormat dateFormat = DateFormat("yyyy-MM-dd HH:mm:ss");
      String dateTime = dateFormat.format(DateTime.now());

      for(int i = 0; i < widget.allReceiptList.length; i++){
        if(widget.allReceiptList[i].status == 1){
          int data = await PosDatabase.instance.updateReceiptStatus(Receipt(
              status: 0,
              sync_status: 0,
              updated_at: dateTime,
              receipt_sqlite_id: widget.allReceiptList[i].receipt_sqlite_id
          ));
        }
      }

      if(receipt.status == 0){
        int data = await PosDatabase.instance.updateReceiptStatus(Receipt(
            status: 1,
            sync_status: 0,
            updated_at: dateTime,
            receipt_sqlite_id: receipt.receipt_sqlite_id
        ));
        widget.callBack();
        closeDialog(context);
        Fluttertoast.showToast(
            backgroundColor: Color(0xFF07F107),
            msg: "Receipt layout apply");
      } else {
        closeDialog(context);
        Fluttertoast.showToast(
            backgroundColor: Color(0xFFFF0000),
            msg: "receipt already in-use");
      }
    }catch(e){
      Fluttertoast.showToast(
          backgroundColor: Color(0xFFFF0000),
          msg: "Fail set layout in use, Please try again $e");
      print('$e');
    }
  }

}
