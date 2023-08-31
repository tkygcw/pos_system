import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../database/pos_database.dart';
import '../../notifier/theme_color.dart';
import '../../object/print_receipt.dart';
import '../../object/printer.dart';
import '../../object/user.dart';
import '../../translation/AppLocalizations.dart';

class CashBoxDialog extends StatefulWidget {
  const CashBoxDialog({Key? key}) : super(key: key);

  @override
  State<CashBoxDialog> createState() => _CashBoxDialogState();
}

class _CashBoxDialogState extends State<CashBoxDialog> {
  final adminPosPinController = TextEditingController();
  List<Printer> printerList = [];
  bool _submitted = false;
  bool isButtonDisabled = false;

  @override
  void initState() {
    super.initState();
    readAllPrinters();
  }

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
    adminPosPinController.dispose();
  }

  readAllPrinters() async {
    printerList = await PrintReceipt().readAllPrinters();
  }

  String? get errorPassword {
    final text = adminPosPinController.value.text;
    if (text.isEmpty) {
      return 'password_required';
    }
    return null;
  }

  _submit(BuildContext context) async {
    setState(() => _submitted = true);
    if (errorPassword == null) {
      // Disable the button after it has been pressed
      setState(() {
        isButtonDisabled = true;
      });
      await readAdminData(adminPosPinController.text);
    }
  }

  closeDialog(BuildContext context) {
    return Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeColor>(builder: (context, ThemeColor color, child) {
      return Center(
        child: SingleChildScrollView(
          child: AlertDialog(
            title: Text(AppLocalizations.of(context)!
                .translate('enter_current_user_pin')),
            content: SizedBox(
              height: 100.0,
              width: 350.0,
              child: ValueListenableBuilder(
                  // Note: pass _controller to the animation argument
                  valueListenable: adminPosPinController,
                  builder: (context, TextEditingValue value, __) {
                    return Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: TextField(
                        autofocus: true,
                        onSubmitted: (input) {
                          _submit(context);
                        },
                        obscureText: true,
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'[0-9]'))
                        ],
                        keyboardType: TextInputType.number,
                        controller: adminPosPinController,
                        decoration: InputDecoration(
                          errorText: _submitted
                              ? errorPassword == null
                                  ? errorPassword
                                  : AppLocalizations.of(context)
                                      ?.translate(errorPassword!)
                              : null,
                          border: OutlineInputBorder(
                            borderSide:
                                BorderSide(color: color.backgroundColor),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide:
                                BorderSide(color: color.backgroundColor),
                          ),
                          labelText: 'PIN',
                        ),
                      ),
                    );
                  }),
            ),
            actions: <Widget>[
              TextButton(
                child:
                    Text('${AppLocalizations.of(context)?.translate('close')}'),
                onPressed: isButtonDisabled
                    ? null
                    : () {
                        // Disable the button after it has been pressed
                        setState(() {
                          isButtonDisabled = true;
                        });
                        closeDialog(context);
                      },
              ),
              TextButton(
                child:
                    Text('${AppLocalizations.of(context)?.translate('yes')}'),
                onPressed: isButtonDisabled
                    ? null
                    : () async {
                        _submit(context);
                      },
              ),
            ],
          ),
        ),
      );
    });
  }

  readAdminData(String pin) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? pos_user = prefs.getString('pos_pin_user');
      Map userObject = json.decode(pos_user!);
      User? userData = await PosDatabase.instance.readSpecificUserWithPin(pin);
      if (userData != null) {
        if (userData.user_id == userObject['user_id']) {
          await callOpenCashDrawer();
          //await PrintReceipt().cashDrawer(context, printerList: this.printerList);
          closeDialog(context);
          //ReceiptLayout().openCashDrawer();
        } else {
          setState(() {
            isButtonDisabled = false;
          });
          Fluttertoast.showToast(
              backgroundColor: Color(0xFFFF0000),
              msg:
                  "${AppLocalizations.of(context)?.translate('pin_not_match')}");
        }
      } else {
        setState(() {
          isButtonDisabled = false;
        });
        Fluttertoast.showToast(
            backgroundColor: Color(0xFFFF0000),
            msg:
                "${AppLocalizations.of(context)?.translate('user_not_found')}");
      }
    } catch (e) {
      print('pos pin error ${e}');
    }
  }

  callOpenCashDrawer() async {
    int printStatus =
        await PrintReceipt().cashDrawer(context, printerList: this.printerList);
    if (printStatus == 1) {
      Fluttertoast.showToast(
          backgroundColor: Colors.red,
          msg:
              "${AppLocalizations.of(context)?.translate('printer_not_connected')}");
    } else if (printStatus == 2) {
      Fluttertoast.showToast(
          backgroundColor: Colors.orangeAccent,
          msg:
              "${AppLocalizations.of(context)?.translate('printer_connection_timeout')}");
    } else if (printStatus == 3) {
      Fluttertoast.showToast(
          backgroundColor: Colors.red,
          msg: AppLocalizations.of(context)!
              .translate('no_cashier_printer_added'));
    } else if (printStatus == 4) {
      Fluttertoast.showToast(
          backgroundColor: Colors.orangeAccent,
          msg:
              "${AppLocalizations.of(context)?.translate('no_cashier_printer')}");
    }
  }
}
