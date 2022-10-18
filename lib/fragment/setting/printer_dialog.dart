import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';
import 'package:pos_system/fragment/category/category_dialog.dart';
import 'package:pos_system/fragment/setting/device_dialog.dart';
import 'package:pos_system/fragment/setting/printer_category_dialog.dart';
import 'package:pos_system/notifier/printer_notifier.dart';
import 'package:pos_system/object/printer.dart';
import 'package:pos_system/object/printer_link_category.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../database/pos_database.dart';
import '../../notifier/theme_color.dart';
import '../../translation/AppLocalizations.dart';

class PrinterDialog extends StatefulWidget {
  final Function() callBack;
  final Printer? printerObject;
  const PrinterDialog({Key? key, required this.callBack, this.printerObject})
      : super(key: key);

  @override
  State<PrinterDialog> createState() => _PrinterDialogState();
}

class _PrinterDialogState extends State<PrinterDialog> {
  final printerLabelController = TextEditingController();
  List<String> printerValue =[];
  String printerID = '';
  int? _typeStatus = 0;
  bool _submitted = false;
  bool _isUpdate = false;

  @override
  void initState() {
    // TODO: implement initState
    if(widget.printerObject != null){
      _isUpdate = true;
      printerLabelController.text = widget.printerObject!.printerLabel!;
      _typeStatus = widget.printerObject!.type!;
      printerValue.add(widget.printerObject!.value!);
    } else {
      _isUpdate = false;
    }
    super.initState();
  }

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
    printerLabelController.dispose();
  }

  String? get errorPrinterLabel {
    final text = printerLabelController.value.text;
    if (text.isEmpty) {
      return 'printer_label_required';
    }
    return null;
  }

  void _submit(BuildContext context, PrinterModel printerModel) {
    setState(() => _submitted = true);
    if (errorPrinterLabel == null) {
      if (printerModel.printerList.length > 0 && printerModel.selectedCategories.length > 0) {
        callAddNewPrinter(printerModel);
      } else {
        Fluttertoast.showToast(
            backgroundColor: Color(0xFFFF0000),
            msg: "Make sure printer and category is selected");
      }
    }
  }

  closeDialog(BuildContext context) {
    return Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeColor>(builder: (context, ThemeColor color, child) {
      return Consumer<PrinterModel>(builder: (context, PrinterModel printerModel, child) {
        return AlertDialog(
          title: _isUpdate ? Text('Edit printer') : Text('Add printer'),
          content: Container(
            height: MediaQuery.of(context).size.height / 2,
            width: MediaQuery.of(context).size.width / 2,
            child: SingleChildScrollView(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ValueListenableBuilder(
                        // Note: pass _controller to the animation argument
                        valueListenable: printerLabelController,
                        builder: (context, TextEditingValue value, __) {
                          return SizedBox(
                            height: 100,
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: TextField(
                                controller: printerLabelController,
                                decoration: InputDecoration(
                                  errorText: _submitted
                                      ? errorPrinterLabel == null
                                          ? errorPrinterLabel
                                          : AppLocalizations.of(context)
                                              ?.translate(errorPrinterLabel!)
                                      : null,
                                  border: OutlineInputBorder(
                                    borderSide: BorderSide(
                                        color: color.backgroundColor),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderSide: BorderSide(
                                        color: color.backgroundColor),
                                  ),
                                  labelText: 'Printer label',
                                ),
                              ),
                            ),
                          );
                        }),
                    Text('Type'),
                    Row(
                      children: [
                        Expanded(
                          child: RadioListTile<int>(
                            title: const Text('USB'),
                            value: 0,
                            groupValue: _typeStatus,
                            onChanged: (value) {
                              setState(() {
                                this.printerValue.clear();
                                // printerModel.removeAllPrinter();
                                _typeStatus = value;
                              });
                            },
                          ),
                        ),
                        Expanded(
                          child: RadioListTile<int>(
                            title: const Text('LAN'),
                            value: 1,
                            groupValue: _typeStatus,
                            onChanged: (value) {
                              setState(() {
                                this.printerValue.clear();
                                // printerModel.removeAllPrinter();
                                _typeStatus = value;
                              });
                            },
                          ),
                        )
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        TextButton(
                            onPressed: () {
                              openAddDeviceDialog(_typeStatus!);
                            },
                            child: printerModel.printerList.length == 0 && printerValue.length == 0
                                ? Text('Add New Device')
                                : Text(''))
                      ],
                    ),
                    ListView.builder(
                      padding: EdgeInsets.only(bottom: 10),
                      shrinkWrap: true,
                      itemCount: printerValue.length,
                      itemBuilder: (context, index) {
                        return Dismissible(
                            key: ValueKey(printerValue[index]),
                            direction: DismissDirection.startToEnd,
                            confirmDismiss: (direction) async {
                              if (direction == DismissDirection.startToEnd) {
                                //printerModel.removeAllPrinter();
                              }
                              return null;
                            },
                            child: Card(
                              elevation: 5,
                              child: Container(
                                  margin: EdgeInsets.all(30),
                                  child: _typeStatus == 0
                                      ? Text(
                                      '${jsonDecode(printerValue[index])["manufacturer"] + jsonDecode(printerValue[index])["productName"]}')
                                      : Text(
                                      '${jsonDecode(printerValue[index])}')),
                            ));
                      },
                    ),
                    // ListView.builder(
                    //   padding: EdgeInsets.only(bottom: 10),
                    //   shrinkWrap: true,
                    //   itemCount: printerModel.printerList.length,
                    //   itemBuilder: (context, index) {
                    //     return Dismissible(
                    //         key: ValueKey(printerModel.printerList[index]),
                    //         direction: DismissDirection.startToEnd,
                    //         confirmDismiss: (direction) async {
                    //           if (direction == DismissDirection.startToEnd) {
                    //             printerModel.removeAllPrinter();
                    //           }
                    //           return null;
                    //         },
                    //         child: Card(
                    //           elevation: 5,
                    //           child: Container(
                    //               margin: EdgeInsets.all(30),
                    //               child: _typeStatus == 0
                    //                   ? Text(
                    //                       '${jsonDecode(printerModel.printerList[index])["manufacturer"] + jsonDecode(printerModel.printerList[index])["productName"]}')
                    //                   : Text(
                    //                       '${jsonDecode(printerModel.printerList[index])}')),
                    //         ));
                    //   },
                    // ),
                    Text('Category'),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        TextButton(
                            onPressed: () {
                              openCategoriesDialog();
                            },
                            child: Text('Add Category'))
                      ],
                    ),
                    ListView.builder(
                      padding: EdgeInsets.only(bottom: 10),
                      shrinkWrap: true,
                      itemCount: printerModel.selectedCategories.length,
                      itemBuilder: (context, index) {
                        return Dismissible(
                            key: ValueKey(
                                printerModel.selectedCategories[index]),
                            direction: DismissDirection.startToEnd,
                            confirmDismiss: (direction) async {
                              if (direction == DismissDirection.startToEnd) {
                                printerModel.removeSpecificCategories(
                                    printerModel.selectedCategories[index]);
                              }
                              return null;
                            },
                            child: Card(
                              elevation: 5,
                              child: Container(
                                margin: EdgeInsets.all(30),
                                child: Text(
                                    '${printerModel.selectedCategories[index].name}'),
                              ),
                            ));
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
          actions: <Widget>[
            TextButton(
              child:
                  Text('${AppLocalizations.of(context)?.translate('close')}'),
              onPressed: () {
                printerModel.removeAllPrinter();
                printerModel.removeAllCategories();
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: _isUpdate ? Text('update') : Text('${AppLocalizations.of(context)?.translate('add')}'),
              onPressed: () {
                _submit(context, printerModel);
              },
            ),
          ],
        );
      });
    });
  }

  callAddNewPrinter(PrinterModel printerModel) async {
    await createPrinter(printerModel);
    await createPrinterCategory(printerModel);
  }

  createPrinter(PrinterModel printerModel) async {
    try {
      DateFormat dateFormat = DateFormat("yyyy-MM-dd HH:mm:ss");
      String dateTime = dateFormat.format(DateTime.now());
      final prefs = await SharedPreferences.getInstance();
      final int? branch_id = prefs.getInt('branch_id');

      Printer data = await PosDatabase.instance.insertSqlitePrinter(Printer(
          printer_id: 4,
          branch_id: branch_id.toString(),
          company_id: '6',
          printerLabel: printerLabelController.text,
          value: printerModel.printerList[0],
          type: _typeStatus,
          printer_link_category_id: '0',
          created_at: dateTime,
          updated_at: '',
          soft_delete: ''));
      printerID = data.printer_id.toString();
      widget.callBack();
      closeDialog(context);
    } catch (e) {
      Fluttertoast.showToast(
          backgroundColor: Color(0xFFFF0000),
          msg: "Something went wrong, Please try again $e");
    }
  }

  createPrinterCategory(PrinterModel printerModel) async {
    try{
      DateFormat dateFormat = DateFormat("yyyy-MM-dd HH:mm:ss");
      String dateTime = dateFormat.format(DateTime.now());

      for(int i = 0; i < printerModel.selectedCategories.length; i++){
        if(printerModel.selectedCategories[i].isChecked == true){
          PrinterLinkCategory data = await PosDatabase.instance.insertSqlitePrinterLinkCategory(PrinterLinkCategory(
              printer_link_category_id: 4,
              printer_id: printerID,
              category_id: printerModel.selectedCategories[i].category_id.toString(),
              created_at: dateTime,
              updated_at: '',
              soft_delete: ''
          ));
        }
      }
      printerModel.removeAllPrinter();
      printerModel.removeAllCategories();
    } catch(e){
      Fluttertoast.showToast(
          backgroundColor: Color(0xFFFF0000),
          msg: "Something went wrong, Please try again $e");
    }
  }

  Future<Future<Object?>> openAddDeviceDialog(int printerType) async {
    return showGeneralDialog(
        barrierColor: Colors.black.withOpacity(0.5),
        transitionBuilder: (context, a1, a2, widget) {
          final curvedValue = Curves.easeInOutBack.transform(a1.value) - 1.0;
          return Transform(
            transform: Matrix4.translationValues(0.0, curvedValue * 200, 0.0),
            child: Opacity(
              opacity: a1.value,
              child: DeviceDialog(
                callBack: addPrinterValue,
                type: printerType,
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

  Future<Future<Object?>> openCategoriesDialog() async {
    return showGeneralDialog(
        barrierColor: Colors.black.withOpacity(0.5),
        transitionBuilder: (context, a1, a2, widget) {
          final curvedValue = Curves.easeInOutBack.transform(a1.value) - 1.0;
          return Transform(
            transform: Matrix4.translationValues(0.0, curvedValue * 200, 0.0),
            child: Opacity(
              opacity: a1.value,
              child: PrinterCategoryDialog(),
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

  addPrinterValue(String printer_value){
    printerValue.clear();
    setState(() {
      printerValue.add(printer_value);
    });
  }
}
