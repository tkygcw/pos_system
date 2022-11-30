import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:pos_system/object/receipt_layout.dart';
import 'package:provider/provider.dart';

import '../../database/pos_database.dart';
import '../../notifier/theme_color.dart';
import '../../object/user.dart';
import '../../translation/AppLocalizations.dart';

class CashBoxDialog extends StatefulWidget {
  const CashBoxDialog({Key? key}) : super(key: key);

  @override
  State<CashBoxDialog> createState() => _CashBoxDialogState();
}

class _CashBoxDialogState extends State<CashBoxDialog> {
  final adminPosPinController = TextEditingController();
  bool _submitted = false;

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
    adminPosPinController.dispose();
  }

  String? get errorPassword {
    final text = adminPosPinController.value.text;
    if (text.isEmpty) {
      return 'password_required';
    }
    return null;
  }

  _submit(BuildContext context) async  {
    setState(() => _submitted = true);
    if (errorPassword == null) {
      await readAdminData(adminPosPinController.text);
      return;
    }
  }

  closeDialog(BuildContext context) {
    return Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeColor>(builder: (context, ThemeColor color, child) {
      return SingleChildScrollView(
        child: AlertDialog(
          title: Text('Enter Admin PIN'),
          content: SizedBox(
            height: 100.0,
            width: 350.0,
            child:  ValueListenableBuilder(
              // Note: pass _controller to the animation argument
                valueListenable: adminPosPinController,
                builder: (context, TextEditingValue value, __) {
                  return Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: TextField(
                      keyboardType: TextInputType.number,
                      controller: adminPosPinController,
                      decoration: InputDecoration(
                        errorText: _submitted
                            ? errorPassword == null ? errorPassword : AppLocalizations.of(context)?.translate(errorPassword!)
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
              child: Text('${AppLocalizations.of(context)?.translate('close')}'),
              onPressed: () {
                closeDialog(context);
              },
            ),
            TextButton(
              child: Text('${AppLocalizations.of(context)?.translate('yes')}'),
              onPressed: () async {
                await _submit(context);
              },
            ),
          ],
        ),
      );
    });
  }

  readAdminData(String pin) async {
    print('called');
    try {
      List<User> userData = await PosDatabase.instance.readSpecificUserWithRole(pin);
      if (userData.length > 0) {
        closeDialog(context);
       ReceiptLayout().openCashDrawer();
      } else {
        Fluttertoast.showToast(
            backgroundColor: Color(0xFFFF0000), msg: "Password incorrect");
      }
    } catch (e) {
      print('pos pin error ${e}');
    }
  }
}
