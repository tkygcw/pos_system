import 'dart:convert';
import 'dart:typed_data';

import 'package:esc_pos_printer/esc_pos_printer.dart';
import 'package:esc_pos_utils/esc_pos_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_usb_printer/flutter_usb_printer.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';
import 'package:pos_system/fragment/setting/device_dialog.dart';
import 'package:pos_system/fragment/setting/printer_category_dialog.dart';
import 'package:pos_system/notifier/printer_notifier.dart';
import 'package:pos_system/object/printer.dart';
import 'package:pos_system/object/printer_link_category.dart';
import 'package:pos_system/page/progress_bar.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../database/pos_database.dart';
import '../../notifier/theme_color.dart';
import '../../object/categories.dart';
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
  FlutterUsbPrinter flutterUsbPrinter = FlutterUsbPrinter();
  List<String> printerValue = [];
  List<Categories> selectedCategories = [];
  String printerID = '';
  int? _typeStatus = 0;
  int? _paperSize = 0;
  bool _submitted = false;
  bool _isUpdate = false;
  bool isLoad = false;

  @override
  void initState() {
    // TODO: implement initState
    if (widget.printerObject != null) {
      _isUpdate = true;
      printerLabelController.text = widget.printerObject!.printerLabel!;
      _typeStatus = widget.printerObject!.type!;
      _paperSize = widget.printerObject!.paper_size!;
      printerValue.add(widget.printerObject!.value!);
      readPrinterCategory();
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
    printerLabelController.dispose();
  }

  String? get errorPrinterLabel {
    final text = printerLabelController.value.text;
    if (text.isEmpty) {
      return 'printer_label_required';
    }
    return null;
  }

  void _submit(BuildContext context) {
    setState(() => _submitted = true);
    if (errorPrinterLabel == null) {
      if (printerValue.length > 0 && selectedCategories.length > 0) {
        if (_isUpdate == false) {
          callAddNewPrinter(printerValue, selectedCategories);
        } else {
          callUpdatePrinter(selectedCategories, widget.printerObject!);
        }
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

  chipsList() {
    for (int i = 0; i < selectedCategories.length; i++)
      return Wrap(
        runSpacing: 0,
        children: [
          Chip(
            label: Text('${selectedCategories[i].name}'),
            avatar: CircleAvatar(
              child: Text('${selectedCategories[i].name![0]}'),
            ),
            elevation: 5,
            onDeleted: () => setState(() {
              selectedCategories.removeAt(i);
            }),
            deleteIcon: Icon(Icons.close),
            deleteButtonTooltipMessage: 'remove',
          )
        ],
      );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeColor>(builder: (context, ThemeColor color, child) {
      return AlertDialog(
        title: _isUpdate ? Text('Edit printer') : Text('Add printer'),
        content: isLoad
            ? Container(
                height: MediaQuery.of(context).size.height / 2,
                width: MediaQuery.of(context).size.width / 2,
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
                          Visibility(
                            visible: printerValue.length == 0 ? true : false,
                            child: TextButton(
                                onPressed: () {
                                  openAddDeviceDialog(_typeStatus!);
                                },
                                child: Text('Add New Device')),
                          )
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
                                  setState(() {
                                    printerValue.removeAt(index);
                                  });
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
                      Text('Paper size'),
                      Row(
                        children: [
                          Expanded(
                            child: RadioListTile<int>(
                              title: const Text('88mm'),
                              value: 0,
                              groupValue: _paperSize,
                              onChanged: (value) {
                                setState(() {
                                  _paperSize = value;
                                });
                              },
                            ),
                          ),
                          Expanded(
                            child: RadioListTile<int>(
                              title: const Text('58mm'),
                              value: 1,
                              groupValue: _paperSize,
                              onChanged: (value) {
                                setState(() {
                                  _paperSize = value;
                                });
                              },
                            ),
                          )
                        ],
                      ),
                      Text('Category'),
                      Wrap(
                        runSpacing: 5,
                        spacing: 10,
                        children: List<Widget>.generate(
                            selectedCategories.length, (int index) {
                          return Chip(
                            label: Text('${selectedCategories[index].name}'),
                            avatar: CircleAvatar(
                              backgroundColor: color.backgroundColor,
                              child: Text(
                                  '${selectedCategories[index].name![0]}',
                                  style: TextStyle(color: color.iconColor)),
                            ),
                            elevation: 5,
                            onDeleted: () => setState(() {
                              selectedCategories.removeAt(index);
                            }),
                            deleteIconColor: Colors.red,
                            deleteIcon: Icon(Icons.close),
                            deleteButtonTooltipMessage: 'remove',
                          );
                        }),
                      ),
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
                    ],
                  ),
                ),
              )
            : CustomProgressBar(),
        actions: <Widget>[
          Visibility(
            visible: _isUpdate ? true : false,
            child: TextButton(
              child: Text('test print'),
              onPressed: () {
                if (_typeStatus == 0) {
                  _print();
                } else {
                  _printLAN();
                }
              },
            ),
          ),
          TextButton(
            child: Text('${AppLocalizations.of(context)?.translate('close')}'),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
          TextButton(
            child: _isUpdate
                ? Text('update')
                : Text('${AppLocalizations.of(context)?.translate('add')}'),
            onPressed: () {
              _submit(context);
            },
          ),
        ],
      );
    });
  }

  callAddNewPrinter(List<String> value, List<Categories> allCategories) async {
    await createPrinter(value);
    await createPrinterCategory(allCategories);
  }

  callUpdatePrinter(List<Categories> allCategories, Printer printer) async {
    await clearPrinterCategory(printer);
    await updatePrinterInfo();
    await updatePrinterCategory(allCategories, printer);
  }

  createPrinter(List<String> value) async {
    try {
      DateFormat dateFormat = DateFormat("yyyy-MM-dd HH:mm:ss");
      String dateTime = dateFormat.format(DateTime.now());
      final prefs = await SharedPreferences.getInstance();
      final int? branch_id = prefs.getInt('branch_id');

      Printer data = await PosDatabase.instance.insertSqlitePrinter(Printer(
          printer_id: 1,
          branch_id: branch_id.toString(),
          company_id: '6',
          printerLabel: printerLabelController.text,
          value: value[0],
          type: _typeStatus,
          printer_link_category_id: '0',
          paper_size: _paperSize,
          created_at: dateTime,
          updated_at: '',
          soft_delete: ''));
      printerID = data.printer_id.toString();
    } catch (e) {
      Fluttertoast.showToast(
          backgroundColor: Color(0xFFFF0000),
          msg: "Something went wrong, Please try again $e");
    }
  }

  createPrinterCategory(List<Categories> allCategories) async {
    try {
      DateFormat dateFormat = DateFormat("yyyy-MM-dd HH:mm:ss");
      String dateTime = dateFormat.format(DateTime.now());

      for (int i = 0; i < allCategories.length; i++) {
        if (allCategories[i].isChecked == true) {
          PrinterLinkCategory data = await PosDatabase.instance
              .insertSqlitePrinterLinkCategory(PrinterLinkCategory(
                  printer_link_category_id: 1,
                  printer_id: printerID,
                  category_id: allCategories[i].category_id.toString(),
                  created_at: dateTime,
                  updated_at: '',
                  soft_delete: ''));
        }
      }
      widget.callBack();
      closeDialog(context);
    } catch (e) {
      Fluttertoast.showToast(
          backgroundColor: Color(0xFFFF0000),
          msg: "Something went wrong, Please try again $e");
    }
  }

  readPrinterCategory() async {
    try {
      List<PrinterLinkCategory> data = await PosDatabase.instance
          .readPrinterLinkCategory(widget.printerObject!.printer_id!);
      if (data.length > 0) {
        for (int i = 0; i < data.length; i++) {
          List<Categories> catData = await PosDatabase.instance
              .readSpecificCategoryById(data[i].category_id!);
          if (!selectedCategories.contains(catData)) {
            selectedCategories.add(catData[0]);
          }
        }
      }
      setState(() {
        isLoad = true;
      });
    } catch (e) {
      Fluttertoast.showToast(
          backgroundColor: Color(0xFFFF0000),
          msg: "Read printer_category went wrong, Please try again $e");
    }
  }

  updatePrinterCategory(List<Categories> allCategories, Printer printer) async {
    print('update category call');
    try {
      DateFormat dateFormat = DateFormat("yyyy-MM-dd HH:mm:ss");
      String dateTime = dateFormat.format(DateTime.now());

      for (int i = 0; i < allCategories.length; i++) {
        if (allCategories[i].isChecked == true) {
          PrinterLinkCategory data = await PosDatabase.instance
              .insertSqlitePrinterLinkCategory(PrinterLinkCategory(
                  printer_link_category_id: 1,
                  printer_id: widget.printerObject!.printer_id.toString(),
                  category_id: allCategories[i].category_id.toString(),
                  created_at: dateTime,
                  updated_at: '',
                  soft_delete: ''));
        }
      }
      // widget.callBack();
      // closeDialog(context);
    } catch (e) {
      Fluttertoast.showToast(
          backgroundColor: Color(0xFFFF0000),
          msg: "Something went wrong, Please try again $e");
    }
  }

  clearPrinterCategory(Printer printer) async {
    try {
      DateFormat dateFormat = DateFormat("yyyy-MM-dd HH:mm:ss");
      String dateTime = dateFormat.format(DateTime.now());

      int data = await PosDatabase.instance.deletePrinterCategory(
          PrinterLinkCategory(
              soft_delete: dateTime,
              printer_id: printer.printer_id.toString()));
    } catch (e) {
      Fluttertoast.showToast(
          backgroundColor: Color(0xFFFF0000),
          msg: "Clear printer category, Please try again $e");
    }
  }

  updatePrinterInfo() async {
    try {
      DateFormat dateFormat = DateFormat("yyyy-MM-dd HH:mm:ss");
      String dateTime = dateFormat.format(DateTime.now());

      int data = await PosDatabase.instance.updatePrinter(Printer(
          printerLabel: printerLabelController.text,
          type: _typeStatus,
          value: printerValue[0],
          paper_size: _paperSize,
          updated_at: dateTime,
          printer_id: widget.printerObject!.printer_id));
    } catch (e) {
      Fluttertoast.showToast(
          backgroundColor: Color(0xFFFF0000),
          msg: "update printer error, Please try again $e");
      print('$e');
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
              child: PrinterCategoryDialog(
                callBack: addPrinterCategory,
                selectedList: selectedCategories,
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

  addPrinterValue(String printer_value) {
    printerValue.clear();
    setState(() {
      printerValue.add(printer_value);
    });
  }

  addPrinterCategory(List<Categories> callBackList) {
    setState(() {
      selectedCategories.clear();
      for (int i = 0; i < callBackList.length; i++) {
        if (callBackList[i].isChecked) {
          selectedCategories.add(callBackList[i]);
        }
      }
    });
  }

  _print() async {
    try {
      var printerDetail = jsonDecode(printerValue[0]);
      print(printerDetail);

      var data = Uint8List.fromList(await testTicket(true));
      bool? isConnected = await flutterUsbPrinter.connect(
          int.parse(printerDetail['vendorId']),
          int.parse(printerDetail['productId']));
      if (isConnected == true) {
        await flutterUsbPrinter.write(data);
      } else {
        print('not connected');
      }
    } catch (e) {
      print('Printer Connection Error');
      //response = 'Failed to get platform version.';
    }
  }

  _printLAN() async {
    var printerDetail = jsonDecode(printerValue[0]);
    const PaperSize paper = PaperSize.mm58;
    final profile = await CapabilityProfile.load();
    final printer = NetworkPrinter(paper, profile);
    final PosPrintResult res = await printer.connect(printerDetail, port: 9100);

    if (res == PosPrintResult.success) {
      testTicket(false, value: printer);
      printer.disconnect();
    } else {
      print('not connected');
    }
  }

  testTicket(bool isUSB, {value}) async {
    var generator;
    if (isUSB) {
      final profile = await CapabilityProfile.load();
      generator = Generator(PaperSize.mm80, profile);
    } else {
      generator = value;
    }

    List<int> bytes = [];
    try {
      bytes += generator.text('Lucky 8',
          styles: PosStyles(
              bold: true,
              align: PosAlign.center,
              height: PosTextSize.size3,
              width: PosTextSize.size3));
      bytes += generator.emptyLines(1);
      bytes += generator.reset();
      //Address
      bytes += generator.text(
          '22-2, Jalan Permas 11/1A, Bandar Permas Baru, 81750, Masai',
          styles: PosStyles(align: PosAlign.center));
      //telephone
      bytes += generator.text('Tel: 07-3504533',
          styles: PosStyles(align: PosAlign.center, height: PosTextSize.size1));
      bytes += generator.text('Lucky8@hotmail.com',
          styles: PosStyles(align: PosAlign.center));
      //receipt no
      bytes += generator.emptyLines(1);
      bytes += generator.text('Receipt No.: 17-200-000056',
          styles: PosStyles(
              align: PosAlign.left,
              width: PosTextSize.size1,
              height: PosTextSize.size1,
              bold: true));
      bytes += generator.reset();
      //other order detail
      bytes += generator.text('2022-10-03 17:18:18');
      bytes += generator.text('Close by: Taylor');
      bytes += generator.hr(ch: '-');
      bytes += generator.reset();
      //order product
      bytes += generator.text('Nasi kandar',
          styles: PosStyles(align: PosAlign.left));
      bytes += generator.reset();
      bytes += generator.row([
        PosColumn(
            text: '1x RM11', width: 8, styles: PosStyles(align: PosAlign.left)),
        PosColumn(
            text: 'RM11.00', width: 4, styles: PosStyles(align: PosAlign.right))
      ]);
      bytes +=
          generator.text('Nasi Ayam', styles: PosStyles(align: PosAlign.left));
      bytes += generator.reset();
      bytes += generator.row([
        PosColumn(
            text: '1x RM7.90 (Big + RM2.00)',
            width: 8,
            styles: PosStyles(align: PosAlign.left)),
        PosColumn(
            text: 'RM9.90', width: 4, styles: PosStyles(align: PosAlign.right))
      ]);
      bytes += generator.reset();
      bytes += generator.hr(ch: '-');
      bytes += generator.reset();
      //item count
      bytes += generator.text('Items count: 2');
      bytes += generator.emptyLines(1);
      bytes += generator.reset();
      //total calc
      bytes += generator.row([
        PosColumn(
            text: 'Subtotal:',
            width: 8,
            styles: PosStyles(align: PosAlign.left)),
        PosColumn(
            text: 'RM20.90', width: 4, styles: PosStyles(align: PosAlign.right))
      ]);
      bytes += generator.row([
        PosColumn(
            text: 'Service Tax(10%):',
            width: 8,
            styles: PosStyles(align: PosAlign.left)),
        PosColumn(
            text: 'RM2.09', width: 4, styles: PosStyles(align: PosAlign.right))
      ]);
      bytes += generator.reset();
      //total
      bytes += generator.row([
        PosColumn(
            text: 'TOTAL:',
            width: 8,
            styles: PosStyles(align: PosAlign.left, bold: true)),
        PosColumn(
            text: 'RM22.99',
            width: 4,
            styles: PosStyles(align: PosAlign.right, bold: true))
      ]);

      bytes += generator.feed(1);
      bytes += generator.cut(mode: PosCutMode.partial);
      return bytes;
    } catch ($e) {
      return null;
    }
  }
}
