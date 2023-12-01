import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:io' as Platform;

import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:esc_pos_printer/esc_pos_printer.dart';
import 'package:esc_pos_utils/esc_pos_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_usb_printer/flutter_usb_printer.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';
import 'package:pos_system/fragment/setting/device_dialog.dart';
import 'package:pos_system/fragment/setting/printer_category_dialog.dart';
import 'package:pos_system/object/printer.dart';
import 'package:pos_system/object/printer_link_category.dart';
import 'package:pos_system/object/receipt_layout.dart';
import 'package:pos_system/page/progress_bar.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:crypto/crypto.dart';

import '../../database/domain.dart';
import '../../database/pos_database.dart';
import '../../main.dart';
import '../../notifier/theme_color.dart';
import '../../object/categories.dart';
import '../../translation/AppLocalizations.dart';
import '../logout_dialog.dart';

class PrinterDialog extends StatefulWidget {
  final Function() callBack;
  final Printer? printerObject;
  final devices;

  const PrinterDialog({Key? key, required this.callBack, this.printerObject, this.devices}) : super(key: key);

  @override
  State<PrinterDialog> createState() => _PrinterDialogState();
}

class _PrinterDialogState extends State<PrinterDialog> {
  final printerLabelController = TextEditingController();
  FlutterUsbPrinter flutterUsbPrinter = FlutterUsbPrinter();
  Printer? printer;
  List<String> printerValue = [];
  List<Categories> selectedCategories = [];
  String printerID = '', printer_key = '';
  String? printer_value, printer_category_value, printer_category_delete_value;
  int? _typeStatus = 0;
  int? _paperSize = 0;
  bool _submitted = false, _isUpdate = false, _isCashier = false, _isKitchen = false, _isLabel = false, _isActive = true, isLogOut = false;
  bool isLoad = false;

  String? selectedValue;

  @override
  void initState() {
    // TODO: implement initState
    if (widget.printerObject != null) {
      readPrinterCategory();
      _isUpdate = true;
      printerLabelController.text = widget.printerObject!.printer_label!;
      _typeStatus = widget.printerObject!.type!;
      _paperSize = widget.printerObject!.paper_size!;
      printerValue.add(widget.printerObject!.value!);

      widget.printerObject!.is_counter == 1 ? _isCashier = true : _isCashier = false;
      widget.printerObject!.is_label == 1 ? selectedValue = 'label_printer' : selectedValue = 'general_printer';
      widget.printerObject!.printer_status == 1 ? _isActive = true : _isActive = false;
    } else if (widget.devices != null) {
      printerValue.add(widget.devices);
      _isCashier = true;
      isLoad = true;
    } else {
      _isUpdate = false;
      isLoad = true;
    }

    if (Platform.Platform.isIOS) {
      _typeStatus = 1;
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

  void _submit(BuildContext context) async {
    setState(() => _submitted = true);
    print('submit status: ${errorPrinterLabel}');
    if (errorPrinterLabel == null) {
      if (printerValue.isNotEmpty) {
        if (_isCashier != false || selectedCategories.isNotEmpty) {
          if (_isUpdate == false) {
            await callAddNewPrinter(printerValue, selectedCategories);
            if (_typeStatus == 0) {
              var printerDetail = jsonDecode(printerValue[0]);
              bool? isConnected = await flutterUsbPrinter.connect(int.parse(printerDetail['vendorId']), int.parse(printerDetail['productId']));
            }
          } else {
            await callUpdatePrinter(selectedCategories, widget.printerObject!);
            if (_typeStatus == 0) {
              var printerDetail = jsonDecode(printerValue[0]);
              bool? isConnected = await flutterUsbPrinter.connect(int.parse(printerDetail['vendorId']), int.parse(printerDetail['productId']));
            }
          }
          if (_typeStatus == 1) {
            await syncAllToCloud();
          }
          if (this.isLogOut == true) {
            openLogOutDialog();
            return;
          }
          widget.callBack();
          closeDialog(context);
        } else {
          Fluttertoast.showToast(
              backgroundColor: Color(0xFFFF0000), msg: AppLocalizations.of(context)!.translate('please_set_the_printer_setting_or_category'));
        }
      } else {
        Fluttertoast.showToast(backgroundColor: Color(0xFFFF0000), msg: AppLocalizations.of(context)!.translate('make_sure_printer_is_selected'));
      }
    }
  }

  closeDialog(BuildContext context) {
    return Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeColor>(builder: (context, ThemeColor color, child) {
      return LayoutBuilder(builder: (context, constraints) {
        if (constraints.maxWidth > 800) {
          return Center(
            child: SingleChildScrollView(
              physics: NeverScrollableScrollPhysics(),
              child: AlertDialog(
                title: _isUpdate
                    ? Text(AppLocalizations.of(context)!.translate('edit_printer'))
                    : Text(AppLocalizations.of(context)!.translate('add_printer')),
                content: isLoad
                    ? Container(
                        height: MediaQuery.of(context).size.height / 1.5,
                        width: MediaQuery.of(context).size.width / 2.5,
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
                                                    : AppLocalizations.of(context)?.translate(errorPrinterLabel!)
                                                : null,
                                            border: OutlineInputBorder(
                                              borderSide: BorderSide(color: color.backgroundColor),
                                            ),
                                            focusedBorder: OutlineInputBorder(
                                              borderSide: BorderSide(color: color.backgroundColor),
                                            ),
                                            labelText: AppLocalizations.of(context)!.translate('printer_label'),
                                          ),
                                        ),
                                      ),
                                    );
                                  }),
                              Text(
                                AppLocalizations.of(context)!.translate('type'),
                                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey),
                              ),
                              Row(
                                children: [
                                  Visibility(
                                    visible: !Platform.Platform.isIOS,
                                    child: Expanded(
                                      child: RadioListTile<int>(
                                        activeColor: color.backgroundColor,
                                        title: const Text(
                                          'USB',
                                          style: TextStyle(fontSize: 15),
                                        ),
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
                                  ),
                                  Expanded(
                                    child: RadioListTile<int>(
                                      activeColor: color.backgroundColor,
                                      title: Text(AppLocalizations.of(context)!.translate('lan'), style: TextStyle(fontSize: 15)),
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
                              Visibility(
                                visible: printerValue.length == 0 ? true : false,
                                child: Container(
                                  alignment: Alignment.center,
                                  child: ElevatedButton(
                                      style: ElevatedButton.styleFrom(primary: color.backgroundColor),
                                      onPressed: () {
                                        if (Platform.Platform.isAndroid) {
                                          setState(() {
                                            openAddDeviceDialog(_typeStatus!);
                                          });
                                        } else {
                                          manualAddDeviceDialog();
                                        }
                                      },
                                      child: Text(AppLocalizations.of(context)!.translate('add_new_device'))),
                                ),
                              ),
                              ListView.builder(
                                padding: EdgeInsets.only(bottom: 10),
                                shrinkWrap: true,
                                itemCount: printerValue.length,
                                itemBuilder: (context, index) {
                                  return ListTile(
                                      leading: Icon(Icons.print),
                                      trailing: ElevatedButton(
                                          onPressed: () {
                                            setState(() {
                                              printerValue.removeAt(index);
                                            });
                                          },
                                          child: Icon(Icons.delete)),
                                      subtitle: _typeStatus == 0
                                          ? Text(
                                              '${jsonDecode(printerValue[index])["manufacturer"] + jsonDecode(printerValue[index])["productName"]}')
                                          : Text('${jsonDecode(printerValue[index])}'),
                                      title: Text(AppLocalizations.of(context)!.translate('printer')));
                                },
                              ),
                              SizedBox(
                                height: 10,
                              ),
                              Text(
                                AppLocalizations.of(context)!.translate('printer_type'),
                                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey),
                              ),
                              SizedBox(
                                height: 10,
                              ),
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: DropdownButtonFormField2<String>(
                                  isExpanded: true,
                                  isDense: false,
                                  decoration: InputDecoration(
                                    contentPadding: const EdgeInsets.symmetric(vertical: 5),
                                    // border: OutlineInputBorder(
                                    //   borderRadius: BorderRadius.circular(15),
                                    // ),
                                    focusedBorder: OutlineInputBorder(
                                      borderSide: BorderSide(color: color.backgroundColor),
                                    ),
                                  ),
                                  hint: Text(
                                    'Printer Type',
                                    style: TextStyle(
                                      fontSize: 15,
                                      color: Theme.of(context).hintColor,
                                    ),
                                  ),
                                  items: <String>['general_printer', 'label_printer']
                                      .map<DropdownMenuItem<String>>((String value) {
                                    return DropdownMenuItem<String>(
                                      value: value,
                                      child: Text(value == 'general_printer' ? 'General Printer' : 'Label Printer'),
                                    );
                                  }).toList(),
                                  value: selectedValue ?? 'general_printer',
                                  onChanged: (String? value) {
                                    setState(() {
                                      selectedValue = value;
                                      _isLabel = (value == 'label_printer');
                                      if(selectedValue != 'label_printer')
                                        _paperSize = 0;
                                      else
                                        _paperSize =2;
                                    });
                                  },
                                ),
                              ),
                              Visibility(
                                visible: selectedValue != 'label_printer',
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    SizedBox(
                                      height: 10,
                                    ),
                                    Text(
                                      AppLocalizations.of(context)!.translate('setting'),
                                      style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey),
                                    ),
                                    Row(
                                      children: [
                                        Container(
                                          child: Text(AppLocalizations.of(context)!.translate('set_as_cashier_printer')),
                                        ),
                                        Spacer(),
                                        Container(
                                          child: Checkbox(
                                            value: _isCashier,
                                            onChanged: widget.devices != null
                                                ? null
                                                : (value) {
                                              setState(() {
                                                _isCashier = value!;
                                              });
                                            },
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(
                                height: 10,
                              ),
                              Text(
                                AppLocalizations.of(context)!.translate('paper_size'),
                                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey),
                              ),
                              selectedValue != 'label_printer' ?
                                Row(
                                  children: [
                                    Expanded(
                                      child: RadioListTile<int>(
                                        activeColor: color.backgroundColor,
                                        title: const Text('80mm'),
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
                                        activeColor: color.backgroundColor,
                                        title: const Text('58mm'),
                                        value: 1,
                                        groupValue: _paperSize,
                                        onChanged: (value) {
                                          setState(() {
                                            _paperSize = value;
                                          });
                                        },
                                      ),
                                    ),
                                  ],
                                )
                              : Row(
                                children: [
                                  Expanded(
                                    child: RadioListTile<int>(
                                      activeColor: color.backgroundColor,
                                      title: const Text('35mm'),
                                      value: 2,
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
                              SizedBox(
                                height: 10,
                              ),
                              Visibility(
                                visible: widget.devices == null ? true : false,
                                child: Container(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        AppLocalizations.of(context)!.translate('category'),
                                        style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey),
                                      ),
                                      SizedBox(height: 10),
                                      Wrap(
                                          runSpacing: 5,
                                          spacing: 10,
                                          children: List<Widget>.generate(selectedCategories.length, (int index) {
                                            return Chip(
                                              label: Text('${selectedCategories[index].name}'),
                                              avatar: CircleAvatar(
                                                backgroundColor: color.backgroundColor,
                                                child: Text('${selectedCategories[index].name![0]}', style: TextStyle(color: color.iconColor)),
                                              ),
                                              elevation: 5,
                                              onDeleted: () => setState(() {
                                                selectedCategories.removeAt(index);
                                              }),
                                              deleteIconColor: Colors.red,
                                              deleteIcon: Icon(Icons.close),
                                              deleteButtonTooltipMessage: 'remove',
                                            );
                                          })),
                                      Container(
                                        alignment: Alignment.center,
                                        child: ElevatedButton(
                                            style: ElevatedButton.styleFrom(primary: color.backgroundColor),
                                            onPressed: () {
                                              setState(() {
                                                openCategoriesDialog();
                                              });
                                            },
                                            child: Icon(Icons.add)),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              Text(
                                AppLocalizations.of(context)!.translate('status'),
                                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey),
                              ),
                              SizedBox(
                                height: 10,
                              ),
                              Row(
                                children: [
                                  Container(
                                    child: Text(AppLocalizations.of(context)!.translate('active')),
                                  ),
                                  Spacer(),
                                  Container(
                                      child: Switch(
                                          value: _isActive,
                                          activeColor: color.backgroundColor,
                                          onChanged: (bool value) {
                                            setState(() {
                                              _isActive = value;
                                            });
                                          }))
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
                      child: Text('${AppLocalizations.of(context)?.translate('test_print')}'),
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
                    child: Text('${AppLocalizations.of(context)?.translate('close')}', style: TextStyle(color: color.buttonColor)),
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                  ),
                  TextButton(
                    child: _isUpdate
                        ? Text('${AppLocalizations.of(context)?.translate('update')}')
                        : Text('${AppLocalizations.of(context)?.translate('add')}', style: TextStyle(color: color.backgroundColor)),
                    onPressed: () {
                      _submit(context);
                    },
                  ),
                ],
              ),
            ),
          );
        } else {
          ///mobile layout
          return Center(
            child: SingleChildScrollView(
              physics: ClampingScrollPhysics(),
              child: AlertDialog(
                actionsPadding: EdgeInsets.zero,
                title: _isUpdate
                    ? Text(AppLocalizations.of(context)!.translate('edit_printer'))
                    : Text(AppLocalizations.of(context)!.translate('add_printer')),
                content: isLoad
                    ? Container(
                        height: MediaQuery.of(context).size.height / 2,
                        width: MediaQuery.of(context).size.width,
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
                                                    : AppLocalizations.of(context)?.translate(errorPrinterLabel!)
                                                : null,
                                            border: OutlineInputBorder(
                                              borderSide: BorderSide(color: color.backgroundColor),
                                            ),
                                            focusedBorder: OutlineInputBorder(
                                              borderSide: BorderSide(color: color.backgroundColor),
                                            ),
                                            labelText: AppLocalizations.of(context)!.translate('printer_label'),
                                          ),
                                        ),
                                      ),
                                    );
                                  }),
                              Text(
                                AppLocalizations.of(context)!.translate('type'),
                                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey),
                              ),
                              Row(
                                children: [
                                  Visibility(
                                    visible: !Platform.Platform.isIOS,
                                    child: Expanded(
                                      child: RadioListTile<int>(
                                        activeColor: color.backgroundColor,
                                        title: const Text(
                                          'USB',
                                          style: TextStyle(fontSize: 15),
                                        ),
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
                                  ),
                                  Expanded(
                                    child: RadioListTile<int>(
                                      activeColor: color.backgroundColor,
                                      title: Text(AppLocalizations.of(context)!.translate('lan'), style: TextStyle(fontSize: 15)),
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
                              Visibility(
                                visible: printerValue.isEmpty ? true : false,
                                child: Container(
                                  alignment: Alignment.center,
                                  child: ElevatedButton(
                                      style: ElevatedButton.styleFrom(backgroundColor: color.backgroundColor),
                                      onPressed: () {
                                        if (Platform.Platform.isAndroid) {
                                          setState(() {
                                            openAddDeviceDialog(_typeStatus!);
                                          });
                                        } else {
                                          manualAddDeviceDialog();
                                        }
                                      },
                                      child: Text(AppLocalizations.of(context)!.translate('add_new_device'))),
                                ),
                              ),
                              ListView.builder(
                                physics: NeverScrollableScrollPhysics(),
                                padding: EdgeInsets.only(bottom: 10),
                                shrinkWrap: true,
                                itemCount: printerValue.length,
                                itemBuilder: (context, index) {
                                  return ListTile(
                                      leading: Icon(Icons.print),
                                      trailing: ElevatedButton(
                                          onPressed: () {
                                            setState(() {
                                              printerValue.removeAt(index);
                                            });
                                          },
                                          child: Icon(Icons.delete)),
                                      subtitle: _typeStatus == 0
                                          ? Text(
                                              '${jsonDecode(printerValue[index])["manufacturer"] + jsonDecode(printerValue[index])["productName"]}')
                                          : Text('${jsonDecode(printerValue[index])}'),
                                      title: Text(AppLocalizations.of(context)!.translate('printer')));
                                },
                              ),
                              SizedBox(
                                height: 10,
                              ),
                              Text(
                                AppLocalizations.of(context)!.translate('printer_type'),
                                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey),
                              ),
                              SizedBox(
                                height: 10,
                              ),
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: DropdownButtonFormField2<String>(
                                  isExpanded: true,
                                  isDense: false,
                                  decoration: InputDecoration(
                                    contentPadding: const EdgeInsets.symmetric(vertical: 5),
                                    // border: OutlineInputBorder(
                                    //   borderRadius: BorderRadius.circular(15),
                                    // ),
                                    focusedBorder: OutlineInputBorder(
                                      borderSide: BorderSide(color: color.backgroundColor),
                                    ),
                                  ),
                                  hint: Text(
                                    'Printer Type',
                                    style: TextStyle(
                                      fontSize: 15,
                                      color: Theme.of(context).hintColor,
                                    ),
                                  ),
                                  items: <String>['general_printer', 'label_printer']
                                      .map<DropdownMenuItem<String>>((String value) {
                                    return DropdownMenuItem<String>(
                                      value: value,
                                      child: Text(value == 'general_printer' ? 'General Printer' : 'Label Printer'),
                                    );
                                  }).toList(),
                                  value: selectedValue ?? 'general_printer',
                                  onChanged: (String? value) {
                                    setState(() {
                                      selectedValue = value;
                                      _isLabel = (value == 'label_printer');
                                    });
                                  },
                                ),
                              ),
                              Visibility(
                                visible: selectedValue == 'general_printer',
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    SizedBox(
                                      height: 10,
                                    ),
                                    Text(
                                      AppLocalizations.of(context)!.translate('setting'),
                                      style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey),
                                    ),
                                    Row(
                                      children: [
                                        Container(
                                          child: Text(AppLocalizations.of(context)!.translate('set_as_cashier_printer')),
                                        ),
                                        Spacer(),
                                        Container(
                                          child: Checkbox(
                                            value: _isCashier,
                                            onChanged: widget.devices != null
                                                ? null
                                                : (value) {
                                              setState(() {
                                                _isCashier = value!;
                                              });
                                            },
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(
                                height: 10,
                              ),
                              Text(
                                AppLocalizations.of(context)!.translate('paper_size'),
                                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey),
                              ),
                              selectedValue == 'general_printer' ?
                              Row(
                                children: [
                                  Expanded(
                                    child: RadioListTile<int>(
                                      activeColor: color.backgroundColor,
                                      title: const Text('80mm'),
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
                                      activeColor: color.backgroundColor,
                                      title: const Text('58mm'),
                                      value: 1,
                                      groupValue: _paperSize,
                                      onChanged: (value) {
                                        setState(() {
                                          _paperSize = value;
                                        });
                                      },
                                    ),
                                  ),
                                ],
                              )
                              : Row(
                                children: [
                                  Expanded(
                                    child: RadioListTile<int>(
                                      activeColor: color.backgroundColor,
                                      title: const Text('35mm'),
                                      value: 2,
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
                              SizedBox(
                                height: 10,
                              ),
                              Container(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      AppLocalizations.of(context)!.translate('category'),
                                      style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey),
                                    ),
                                    SizedBox(height: 10),
                                    Wrap(
                                        runSpacing: 5,
                                        spacing: 10,
                                        children: List<Widget>.generate(selectedCategories.length, (int index) {
                                          return Chip(
                                            label: Text('${selectedCategories[index].name}'),
                                            avatar: CircleAvatar(
                                              backgroundColor: color.backgroundColor,
                                              child: Text('${selectedCategories[index].name![0]}', style: TextStyle(color: color.iconColor)),
                                            ),
                                            elevation: 5,
                                            onDeleted: () => setState(() {
                                              selectedCategories.removeAt(index);
                                            }),
                                            deleteIconColor: Colors.red,
                                            deleteIcon: Icon(Icons.close),
                                            deleteButtonTooltipMessage: 'remove',
                                          );
                                        })),
                                    Container(
                                      alignment: Alignment.center,
                                      child: ElevatedButton(
                                          style: ElevatedButton.styleFrom(primary: color.backgroundColor),
                                          onPressed: () {
                                            setState(() {
                                              openCategoriesDialog();
                                            });
                                          },
                                          child: Icon(Icons.add)),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                AppLocalizations.of(context)!.translate('status'),
                                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey),
                              ),
                              SizedBox(
                                height: 10,
                              ),
                              Row(
                                children: [
                                  Container(
                                    child: Text(AppLocalizations.of(context)!.translate('active')),
                                  ),
                                  Spacer(),
                                  Container(
                                      child: Switch(
                                          value: _isActive,
                                          activeColor: color.backgroundColor,
                                          onChanged: (bool value) {
                                            setState(() {
                                              _isActive = value;
                                            });
                                          }))
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
                      child: Text(AppLocalizations.of(context)!.translate('test_print')),
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
                    child: Text('${AppLocalizations.of(context)?.translate('close')}', style: TextStyle(color: color.buttonColor)),
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                  ),
                  TextButton(
                    child: _isUpdate
                        ? Text(AppLocalizations.of(context)!.translate('update'))
                        : Text('${AppLocalizations.of(context)?.translate('add')}', style: TextStyle(color: color.backgroundColor)),
                    onPressed: () {
                      _submit(context);
                    },
                  ),
                ],
              ),
            ),
          );
        }
      });
    });
  }

/*
  -------------------DB Query part---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
*/

  callAddNewPrinter(List<String> value, List<Categories> allCategories) async {
    await createPrinter(value);
    if (allCategories.isNotEmpty) {
      await createPrinterCategory(allCategories);
    }
  }

  callUpdatePrinter(List<Categories> allCategories, Printer printer) async {
    await updatePrinterInfo();
    await clearPrinterCategory(printer);
    if (allCategories.isNotEmpty) {
      await updatePrinterCategory(allCategories, printer);
    }
  }

  generatePrinterKey(Printer printer) async {
    final prefs = await SharedPreferences.getInstance();
    final int? device_id = prefs.getInt('device_id');
    var bytes = printer.created_at!.replaceAll(new RegExp(r'[^0-9]'), '') + printer.printer_sqlite_id.toString() + device_id.toString();
    return md5.convert(utf8.encode(bytes)).toString();
  }

  insertPrinterKey(Printer printer, String dateTime) async {
    Printer? detailData;
    var key = await generatePrinterKey(printer);
    if (key != null) {
      Printer printerData = Printer(
          printer_key: key,
          updated_at: dateTime,
          sync_status: printer.sync_status == 0
              ? 0
              : printer.sync_status == 1
                  ? 2
                  : 1,
          printer_sqlite_id: printer.printer_sqlite_id);
      int updateUniqueKey = await PosDatabase.instance.updatePrinterUniqueKey(printerData);
      if (updateUniqueKey == 1) {
        Printer data = await PosDatabase.instance.readSpecificPrinterByLocalId(printerData.printer_sqlite_id!);
        detailData = data;
      }
    }
    return detailData;
  }

  createPrinter(List<String> value) async {
    try {
      List<String> _value = [];
      DateFormat dateFormat = DateFormat("yyyy-MM-dd HH:mm:ss");
      String dateTime = dateFormat.format(DateTime.now());
      final prefs = await SharedPreferences.getInstance();
      final int? branch_id = prefs.getInt('branch_id');
      final String? login_user = prefs.getString('user');
      Map logInUser = json.decode(login_user!);
      //start insert
      Printer data = await PosDatabase.instance.insertSqlitePrinter(Printer(
          printer_key: '',
          printer_id: 0,
          branch_id: branch_id.toString(),
          company_id: logInUser['company_id'].toString(),
          printer_label: printerLabelController.text,
          value: value[0],
          type: _typeStatus,
          printer_link_category_id: '',
          paper_size: _paperSize,
          printer_status: _isActive ? 1 : 0,
          is_counter: _isCashier ? 1 : 0,
          is_label: _isLabel ? 1 : 0,
          sync_status: _typeStatus == 0 ? -1 : 0,
          created_at: dateTime,
          updated_at: '',
          soft_delete: ''));
      printerID = data.printer_sqlite_id.toString();
      //get key and update into printer
      Printer updatedData = await insertPrinterKey(data, dateTime);
      this.printer = updatedData;
      printer_key = updatedData.printer_key!;
      if (data.type == 1) {
        _value.add(jsonEncode(updatedData));
        printer_value = _value.toString();
        //sync to cloud
        //syncPrinterToCloud(_value.toString());
      }
    } catch (e) {
      print('create printer error: ${e}');
      Fluttertoast.showToast(
          backgroundColor: Color(0xFFFF0000), msg: AppLocalizations.of(context)!.translate('something_went_wrong_please_try_again_later') + " $e");
    }
  }

  // syncPrinterToCloud(String value) async {
  //   bool _hasInternetAccess = await Domain().isHostReachable();
  //   if (_hasInternetAccess) {
  //     Map response = await Domain().SyncPrinterToCloud(value);
  //     if (response['status'] == '1') {
  //       List responseJson = response['data'];
  //       int syncUpdated = await PosDatabase.instance.updatePrinterSyncStatusFromCloud(responseJson[0]['printer_key']);
  //     }
  //   }
  // }

  generatePrinterCategoryKey(PrinterLinkCategory printerLinkCategory) async {
    final prefs = await SharedPreferences.getInstance();
    final int? device_id = prefs.getInt('device_id');
    var bytes = printerLinkCategory.created_at!.replaceAll(new RegExp(r'[^0-9]'), '') +
        printerLinkCategory.printer_link_category_sqlite_id.toString() +
        device_id.toString();
    return md5.convert(utf8.encode(bytes)).toString();
  }

  insertPrinterCategoryKey(PrinterLinkCategory printerLinkCategory, String dateTime) async {
    PrinterLinkCategory? detailData;
    var key = await generatePrinterCategoryKey(printerLinkCategory);
    if (key != null) {
      PrinterLinkCategory object = PrinterLinkCategory(
          updated_at: dateTime,
          sync_status: this.printer!.type == 0 ? 1 : 0,
          printer_link_category_key: key,
          printer_link_category_sqlite_id: printerLinkCategory.printer_link_category_sqlite_id);
      int updateUniqueKey = await PosDatabase.instance.updatePrinterLinkCategoryUniqueKey(object);
      if (updateUniqueKey == 1) {
        PrinterLinkCategory data = await PosDatabase.instance.readSpecificPrinterCategoryByLocalId(object.printer_link_category_sqlite_id!);
        detailData = data;
      }
    }
    return detailData;
  }

  createPrinterCategory(List<Categories> allCategories) async {
    try {
      List<String> _value = [];
      DateFormat dateFormat = DateFormat("yyyy-MM-dd HH:mm:ss");
      String dateTime = dateFormat.format(DateTime.now());
      for (int i = 0; i < allCategories.length; i++) {
        if (allCategories[i].isChecked == true) {
          Categories? categories = await PosDatabase.instance.readSpecificCategoryById(allCategories[i].category_sqlite_id.toString());
          PrinterLinkCategory data = await PosDatabase.instance.insertSqlitePrinterLinkCategory(PrinterLinkCategory(
              printer_link_category_id: 0,
              printer_link_category_key: '',
              printer_sqlite_id: printerID,
              printer_key: printer_key,
              category_sqlite_id: allCategories[i].category_sqlite_id.toString(),
              category_id: categories != null ? categories.category_id.toString() : '0',
              sync_status: 0,
              created_at: dateTime,
              updated_at: '',
              soft_delete: ''));

          PrinterLinkCategory updatedData = await insertPrinterCategoryKey(data, dateTime);
          _value.add(jsonEncode(updatedData));
        }
      }
      this.printer_category_value = _value.toString();
      print('value: ${_value.toString()}');
    } catch (e) {
      print('error: ${e}');
      Fluttertoast.showToast(
          backgroundColor: Color(0xFFFF0000), msg: AppLocalizations.of(context)!.translate('something_went_wrong_please_try_again_later') + " $e");
    }
  }

  readPrinterCategory() async {
    try {
      List<PrinterLinkCategory> data = await PosDatabase.instance.readPrinterLinkCategory(widget.printerObject!.printer_sqlite_id!);
      if (widget.printerObject!.is_counter == 1) {
        _isCashier = true;
      }
      if (data.isNotEmpty) {
        for (int i = 0; i < data.length; i++) {
          if (data[i].category_sqlite_id == '0') {
            selectedCategories.add(Categories(category_sqlite_id: 0, name: 'Other/uncategorized'));
          } else {
            Categories? catData = await PosDatabase.instance.readSpecificCategoryById(data[i].category_sqlite_id!);
            if (!selectedCategories.contains(catData)) {
              catData!.isChecked = true;
              selectedCategories.add(catData);
            }
          }
        }
      }
      setState(() {
        isLoad = true;
      });
    } catch (e) {
      Fluttertoast.showToast(
          backgroundColor: Color(0xFFFF0000),
          msg: AppLocalizations.of(context)!.translate('read_printer_category_went_wrong_please_try_again') + " $e");
    }
  }

  updatePrinterCategory(List<Categories> allCategories, Printer printer) async {
    try {
      List<String> _value = [];
      DateFormat dateFormat = DateFormat("yyyy-MM-dd HH:mm:ss");
      String dateTime = dateFormat.format(DateTime.now());
      if (allCategories.isNotEmpty) {
        for (int i = 0; i < allCategories.length; i++) {
          if (allCategories[i].category_sqlite_id == 0) {
            allCategories[i].isChecked = true;
          }
          if (allCategories[i].isChecked == true) {
            Categories? categories = await PosDatabase.instance.readSpecificCategoryById(allCategories[i].category_sqlite_id.toString());
            PrinterLinkCategory data = await PosDatabase.instance.insertSqlitePrinterLinkCategory(PrinterLinkCategory(
                printer_link_category_id: 0,
                printer_link_category_key: '',
                printer_sqlite_id: printer.printer_sqlite_id.toString(),
                printer_key: printer.printer_key,
                category_sqlite_id: allCategories[i].category_sqlite_id.toString(),
                category_id: categories != null ? categories.category_id.toString() : '0',
                sync_status: this.printer!.type == 1
                    ? 0
                    : this.printer!.type == 0
                        ? 1
                        : 2,
                created_at: dateTime,
                updated_at: '',
                soft_delete: ''));

            PrinterLinkCategory updatedData = await insertPrinterCategoryKey(data, dateTime);
            _value.add(jsonEncode(updatedData));
          }
        }
      }
      this.printer_category_value = _value.toString();
    } catch (e) {
      Fluttertoast.showToast(
          backgroundColor: Color(0xFFFF0000), msg: AppLocalizations.of(context)!.translate('update_printer_category_error_please_try_again') + " $e");
      print('"Update printer category error, Please try again $e"');
    }
  }

  clearPrinterCategory(Printer printer) async {
    try {
      List<String> _value = [];
      DateFormat dateFormat = DateFormat("yyyy-MM-dd HH:mm:ss");
      String dateTime = dateFormat.format(DateTime.now());

      PrinterLinkCategory printerLinkCategoryObject = PrinterLinkCategory(
          soft_delete: dateTime, sync_status: this.printer!.type == 0 ? 1 : 2, printer_sqlite_id: printer.printer_sqlite_id.toString());

      int data = await PosDatabase.instance.deletePrinterCategory(printerLinkCategoryObject);
      if (this.printer!.type == 1) {
        List<PrinterLinkCategory> printerCategoryList =
            await PosDatabase.instance.readDeletedPrinterLinkCategory(int.parse(printerLinkCategoryObject.printer_sqlite_id!));
        for (int i = 0; i < printerCategoryList.length; i++) {
          _value.add(jsonEncode(printerCategoryList[i]));
        }
      }
      printer_category_delete_value = _value.toString();
    } catch (e) {
      Fluttertoast.showToast(
          backgroundColor: Color(0xFFFF0000), msg: AppLocalizations.of(context)!.translate('clear_printer_category_please_try_again') + " $e");
    }
  }

  updatePrinterInfo() async {
    try {
      List<String> _value = [];
      DateFormat dateFormat = DateFormat("yyyy-MM-dd HH:mm:ss");
      String dateTime = dateFormat.format(DateTime.now());
      Printer checkData = await PosDatabase.instance.readSpecificPrinterByLocalId(widget.printerObject!.printer_sqlite_id!);
      Printer printerObject = Printer(
          printer_label: printerLabelController.text,
          type: _typeStatus,
          value: printerValue[0],
          paper_size: _paperSize,
          printer_status: _isActive ? 1 : 0,
          is_counter: _isCashier ? 1 : 0,
          is_label: _isLabel ? 1 : 0,
          sync_status: checkData.type == 0 && _typeStatus == 1
              ? 0
              : checkData.type == 0 && _typeStatus == 0
                  ? 1
                  : checkData.type == 1 && _typeStatus == 0
                      ? 1
                      : 2,
          updated_at: dateTime,
          printer_sqlite_id: widget.printerObject!.printer_sqlite_id);

      int data = await PosDatabase.instance.updatePrinter(printerObject);
      this.printer = printerObject;
      Printer updatedData = await PosDatabase.instance.readSpecificPrinterByLocalId(printerObject.printer_sqlite_id!);
      _value.add(jsonEncode(updatedData));
      this.printer_value = _value.toString();
    } catch (e) {
      Fluttertoast.showToast(
          backgroundColor: Color(0xFFFF0000), msg: AppLocalizations.of(context)!.translate('update_printer_error_please_try_again') + " $e");
      print('$e');
    }
  }

/*
  -------------------Dialog part---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
*/

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

  manualAddDeviceDialog() {
    var ip = TextEditingController();
    // flutter defined function
    showDialog(
      context: context,
      builder: (BuildContext context) {
        // return alert dialog object
        return AlertDialog(
          title: Text("${AppLocalizations.of(context)!.translate('add_printer')}"),
          content: SingleChildScrollView(
            child: Container(
              height: 150,
              child: Column(
                children: [
                  TextField(
                    keyboardType: TextInputType.numberWithOptions(decimal: true),
                    controller: ip,
                    textAlign: TextAlign.start,
                    maxLines: 1,
                    decoration: InputDecoration(
                      prefixIcon: Icon(Icons.wifi),
                      labelText: '${AppLocalizations.of(context)!.translate('ip_address')}',
                      labelStyle: TextStyle(fontSize: 14, color: Colors.blueGrey),
                      hintText: '192.168.x.x',
                      border: new OutlineInputBorder(borderSide: new BorderSide(color: Colors.teal)),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('${AppLocalizations.of(context)!.translate('cancel')}'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text(
                '${AppLocalizations.of(context)!.translate('confirm')}',
                style: TextStyle(color: Colors.red),
              ),
              onPressed: () async {
                addPrinterValue('"${ip.text}"');
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
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
    print(printer_value);
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

  syncAllToCloud() async {
    try {
      if (mainSyncToCloud.count == 0) {
        mainSyncToCloud.count = 1;
        final prefs = await SharedPreferences.getInstance();
        final int? device_id = prefs.getInt('device_id');
        final String? login_value = prefs.getString('login_value');
        Map data = await Domain().syncLocalUpdateToCloud(
            device_id: device_id.toString(),
            value: login_value,
            printer_value: this.printer_value,
            printer_link_category_value: this.printer_category_value,
            printer_link_category_delete_value: this.printer_category_delete_value);
        if (data['status'] == '1') {
          List responseJson = data['data'];
          for (int i = 0; i < responseJson.length; i++) {
            switch (responseJson[i]['table_name']) {
              case 'tb_printer':
                {
                  await PosDatabase.instance.updatePrinterSyncStatusFromCloud(responseJson[i]['printer_key']);
                }
                break;
              case 'tb_printer_link_category':
                {
                  await PosDatabase.instance.updatePrinterLinkCategorySyncStatusFromCloud(responseJson[i]['printer_link_category_key']);
                }
                break;
              default:
                return;
            }
          }
          mainSyncToCloud.resetCount();
        } else if (data['status'] == '7') {
          mainSyncToCloud.resetCount();
          this.isLogOut = true;
        } else if (data['status'] == '8') {
          print('printer sync timeout');
          mainSyncToCloud.resetCount();
          throw TimeoutException("Time out");
        } else {
          mainSyncToCloud.resetCount();
        }
        // bool _hasInternetAccess = await Domain().isHostReachable();
        // if (_hasInternetAccess) {
        //
        // }
        // mainSyncToCloud.resetCount();
      }
    } catch (e) {
      mainSyncToCloud.resetCount();
    }
  }

/*
  -------------------Printing part---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
*/

  _print() async {
    try {
      var printerDetail = jsonDecode(printerValue[0]);

      if (_paperSize == 0) {
        var data = Uint8List.fromList(await ReceiptLayout().testTicket80mm(true));
        bool? isConnected = await flutterUsbPrinter.connect(int.parse(printerDetail['vendorId']), int.parse(printerDetail['productId']));
        if (isConnected == true) {
          bool? status = await flutterUsbPrinter.write(data);
        } else {
          print('not connected');
        }
      } else if (_paperSize == 1) {
        print('print 58mm');
        var data = Uint8List.fromList(await ReceiptLayout().testTicket58mm(true, null));
        bool? isConnected = await flutterUsbPrinter.connect(
            int.parse(printerDetail['vendorId']),
            int.parse(printerDetail['productId']));
        if (isConnected == true) {
          await flutterUsbPrinter.write(data);
        } else {
          print('not connected');
        }
      } else {
        print('pprint 35mm');
        var data = Uint8List.fromList(await ReceiptLayout().testTicket35mm(true));
        bool? isConnected = await flutterUsbPrinter.connect(
            int.parse(printerDetail['vendorId']),
            int.parse(printerDetail['productId']));
        if (isConnected == true) {
          await flutterUsbPrinter.write(data);
        } else {
          print('not connected');
        }
      }
    } catch (e) {
      print('error $e');
      print('Printer Connection Error');
      //response = 'Failed to get platform version.';
    }
  }

  _printLAN() async {
    var printerDetail = jsonDecode(printerValue[0]);
    if(_paperSize == 0){
      PaperSize paper = PaperSize.mm80;
      final profile = await CapabilityProfile.load();
      final printer = NetworkPrinter(paper, profile);
      final PosPrintResult res = await printer.connect(printerDetail, port: 9100);

      if (res == PosPrintResult.success) {
        await ReceiptLayout().testTicket80mm(false, value: printer);
        printer.disconnect();
      } else {
        Fluttertoast.showToast(
            backgroundColor: Color(0xFFFF0000),
            msg: "${AppLocalizations.of(context)?.translate('lan_printer_not_connect')}");
      }
    } else if(_paperSize == 2) {
      print("self test print 35mm");
      PaperSize paper = PaperSize.mm35;
      final profile = await CapabilityProfile.load();
      final printer = NetworkPrinter(paper, profile);
      final PosPrintResult res = await printer.connect(printerDetail, port: 9100);

      if (res == PosPrintResult.success) {
        print("Printer connected");
        await ReceiptLayout().testTicket35mm(false, value: printer);
        printer.disconnect();
        print("Printer Disconected");
      } else {
        Fluttertoast.showToast(
            backgroundColor: Color(0xFFFF0000),
            msg: "${AppLocalizations.of(context)?.translate('lan_printer_not_connect')}");
      }
    }
  }
}
