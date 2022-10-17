import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';
import 'package:pos_system/fragment/setting/device_dialog.dart';
import 'package:pos_system/notifier/printer_notifier.dart';
import 'package:pos_system/object/printer.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../database/pos_database.dart';
import '../../notifier/theme_color.dart';
import '../../translation/AppLocalizations.dart';

class PrinterDialog extends StatefulWidget {
  final Function() callBack;
  final Printer object;
  const PrinterDialog({Key? key, required this.callBack, required this.object}) : super(key: key);

  @override
  State<PrinterDialog> createState() => _PrinterDialogState();
}

class _PrinterDialogState extends State<PrinterDialog> {
  final printerLabelController = TextEditingController();
  int? _typeStatus = 0;
  bool _submitted = false;

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
    if(errorPrinterLabel == null){
      createPrinter();
    }

  }

  closeDialog(BuildContext context) {
    return Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeColor>(builder: (context, ThemeColor color, child) {
      return Consumer<PrinterModel>(
        builder: (context, PrinterModel printerModel, child) {
          return AlertDialog(
            title: Text('Add Printer'),
            content: Container(
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
                                  errorText: _submitted ? errorPrinterLabel == null
                                      ? errorPrinterLabel
                                      : AppLocalizations.of(context)
                                      ?.translate(errorPrinterLabel!)
                                      : null,
                                  border: OutlineInputBorder(
                                    borderSide:
                                    BorderSide(color: color.backgroundColor),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderSide:
                                    BorderSide(color: color.backgroundColor),
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
                                  _typeStatus = value;
                                });
                              },
                            ),
                          ),
                         Expanded(
                           child:  RadioListTile<int>(
                             title: const Text('LAN'),
                             value: 1,
                             groupValue: _typeStatus,
                             onChanged: (value) {
                               setState(() {
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
                            onPressed: (){
                              openAddDeviceDialog(_typeStatus!);
                            },
                            child: Text('Add New Device')
                        )
                      ],
                    ),
                    ListView.builder(
                      padding: EdgeInsets.only(bottom: 10),
                      shrinkWrap: true,
                      itemCount: printerModel.printerList.length,
                      itemBuilder: (context, index) {
                        return Dismissible(
                            key: ValueKey(printerModel.printerList[index]),
                            direction: DismissDirection.startToEnd,
                            confirmDismiss: (direction) async {
                              if (direction == DismissDirection.startToEnd) {
                                printerModel.removeAllPrinter();
                              }
                              return null;
                            },
                            child: Card(
                              elevation: 5,
                              child: Container(
                                margin: EdgeInsets.all(30),
                                child: Text('${printerModel.printerList[index]}'),
                              ),
                        )
                        );
                      },
                    ),
                    Text('Category'),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        TextButton(
                            onPressed: (){},
                            child: Text('Add Category')
                        )
                      ],
                    ),
                  ],
                ),
              ),
            ),
            actions: <Widget>[
              TextButton(
                child: Text('${AppLocalizations.of(context)?.translate('close')}'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
              TextButton(
                child: Text('${AppLocalizations.of(context)?.translate('add')}'),
                onPressed: (){
                  print('submit');
                  _submit(context);
                },
              ),
            ],
          );
        }
      );
    });
  }

  createPrinter() async {
    try{
      DateFormat dateFormat = DateFormat("yyyy-MM-dd HH:mm:ss");
      String dateTime = dateFormat.format(DateTime.now());
      final prefs = await SharedPreferences.getInstance();
      final int? branch_id = prefs.getInt('branch_id');

      Printer data = await PosDatabase.instance.insertSqlitePrinter(Printer(
          printer_id: 2,
          branch_id: branch_id.toString(),
          company_id: '6',
          printerLabel: printerLabelController.text,
          value: '',
          type: _typeStatus,
          printer_link_category_id: '0',
          created_at: dateTime,
          updated_at: '',
          soft_delete: ''
      ));
      widget.callBack();
      closeDialog(context);
    }catch(e){
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

}
