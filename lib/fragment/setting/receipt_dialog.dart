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
  File? footerImage;
  String? headerDir;
  String? footerDir;
  bool isLoad = false;
  bool _isUpdate = false;

  @override
  void initState() {
    // TODO: implement initState
    if (widget.receiptObject != null) {
      _isUpdate = true;
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
    !_isUpdate ?
    createReceiptLayout() : setLayoutInUse(widget.receiptObject!);
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
                Container(
                  alignment: Alignment.topLeft,
                  child: Text('Logo Text', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey)),
                ),
                SizedBox(height: 10,),
                Container(
                  child: ValueListenableBuilder(
                    // Note: pass _controller to the animation argument
                      valueListenable: headerTextController,
                      builder: (context, TextEditingValue value, __) {
                        return SizedBox(
                          height: MediaQuery.of(context).size.height / 8,
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: TextField(
                              readOnly: !_isUpdate ? false : true,
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
                Container(
                  alignment: Alignment.topLeft,
                  child: Text('Footer Text', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey)),
                ),
                SizedBox(height: 10,),
                Container(
                  child: ValueListenableBuilder(
                    // Note: pass _controller to the animation argument
                      valueListenable: footerTextController,
                      builder: (context, TextEditingValue value, __) {
                        return SizedBox(
                          height: MediaQuery.of(context).size.height / 8,
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: TextField(
                              readOnly: !_isUpdate ? false : true,
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
                Container(
                  alignment: Alignment.topLeft,
                  child: Text('Logo image', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey)),
                ),
                Center(
                  child: Column(
                    children: [
                      headerImage != null ?
                      Image.file(
                        headerImage!,
                        width: 250,
                        height: 250,
                        fit: BoxFit.cover,
                      ):
                          Container(
                            alignment: Alignment.center,
                            child: Column(
                              children: [
                                Icon(Icons.image),
                                Text('No image')
                              ],
                            ),
                          ),
                      SizedBox(
                        height: 10,
                      ), !_isUpdate ?
                      ElevatedButton(
                        child: Row(
                          children: [
                            Icon(Icons.image_outlined),
                            SizedBox(
                              width: 10,
                            ),
                            Text("Pick Image from Gallery"),
                          ],
                        ),
                        onPressed: () {
                          getHeaderImage(ImageSource.gallery);
                        },
                        style: ElevatedButton.styleFrom(
                            primary: color.backgroundColor,
                            textStyle: TextStyle(
                                color: Colors.white70,
                                fontWeight: FontWeight.bold)),
                      ) :
                      Container(),
                    ],
                  ),
                ),
                SizedBox(height: 10,),
                Container(
                  alignment: Alignment.topLeft,
                  child: Text('Footer image', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey)),
                ),
                Center(
                  child: Column(
                    children: [
                      footerImage != null ?
                      Image.file(
                        footerImage!,
                        width: 250,
                        height: 250,
                        fit: BoxFit.cover,
                      ):
                      Container(
                        alignment: Alignment.center,
                        child: Column(
                          children: [
                            Icon(Icons.image),
                            Text('No image')
                          ],
                        ),
                      ),
                      SizedBox(
                        height: 10,
                      ), !_isUpdate ?
                      ElevatedButton(
                        child: Row(
                          children: [
                            Icon(Icons.image_outlined),
                            SizedBox(
                              width: 10,
                            ),
                            Text("Pick Image from Gallery"),
                          ],
                        ),
                        onPressed: () {
                          getFooterImage(ImageSource.gallery);
                        },
                        style: ElevatedButton.styleFrom(
                            primary: color.backgroundColor,
                            textStyle: TextStyle(
                                color: Colors.white70,
                                fontWeight: FontWeight.bold)),
                      ) :
                      Container(),
                    ],
                  ),
                )
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
        header_text: headerTextController.text,
        footer_text: footerTextController.text,
        header_image: headerDir != null
            ? headerImage.toString()
            : '',
        footer_image: footerDir != null
            ? footerImage.toString()
            : '',
        status: 0,
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

  Future getHeaderImage(ImageSource source) async {
    try {
      final ImagePicker _picker = ImagePicker();
      final XFile? image = await _picker.pickImage(source: source);
      if (image == null) return;
      final imageTemporary = File(image.path);
      setState(() {
        this.headerImage = imageTemporary;
        this.headerDir = image.path;
      });
    } on PlatformException catch (e) {
      print('failed to pick image: $e');
    }
  }

  Future getFooterImage(ImageSource source) async {
    try {
      final ImagePicker _picker = ImagePicker();
      final XFile? image = await _picker.pickImage(source: source);
      if (image == null) return;
      final imageTemporary = File(image.path);
      setState(() {
        this.footerImage = imageTemporary;
        this.footerDir = image.path;
      });
    } on PlatformException catch (e) {
      print('failed to pick image: $e');
    }
  }
}
