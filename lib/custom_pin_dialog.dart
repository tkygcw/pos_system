import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:pos_system/notifier/theme_color.dart';
import 'package:pos_system/translation/AppLocalizations.dart';
import 'package:provider/provider.dart';

import 'database/pos_database.dart';
import 'object/user.dart';

class CustomPinDialog extends StatefulWidget {
  final Function() callback;
  const CustomPinDialog({Key? key, required this.callback}) : super(key: key);

  @override
  State<CustomPinDialog> createState() => _CustomPinDialogState();
}

class _CustomPinDialogState extends State<CustomPinDialog> {
  final PosDatabase posDatabase = PosDatabase.instance;
  final adminPosPinController = TextEditingController();
  bool isButtonDisabled = false;
  bool _submitted = false;

  String? get errorPassword {
    final text = adminPosPinController.value.text;
    if (text.isEmpty) {
      return 'password_required';
    }
    return null;
  }

  void _submit(BuildContext context) async {
    setState(() => _submitted = true);
    if (errorPassword == null) {
      await readAdminData(adminPosPinController.text);
    } else {
      setState(() {
        isButtonDisabled = false;
      });
    }
  }

  readAdminData(String pin) async {
    try {
      User? userData = await posDatabase.readSpecificUserWithPin(pin);
      if (userData != null) {
        if (userData.role == 0) {
          Navigator.of(context).pop();
          widget.callback();
        } else {
          Fluttertoast.showToast(backgroundColor: Color(0xFFFF0000), msg: "${AppLocalizations.of(context)?.translate('no_permission')}");
          adminPosPinController.clear();
          setState(() {
            isButtonDisabled = false;
          });
        }
      } else {
        Fluttertoast.showToast(backgroundColor: Color(0xFFFF0000), msg: "${AppLocalizations.of(context)?.translate('user_not_found')}");
        adminPosPinController.clear();
        setState(() {
          isButtonDisabled = false;
        });
      }
    } catch (e) {
      print('user checking error ${e}');
      return;
    }
  }

  @override
  Widget build(BuildContext context) {
    var color = context.watch<ThemeColor>();
    return AlertDialog(
      title: Text(AppLocalizations.of(context)!.translate('enter_admin_pin')),
      content: ValueListenableBuilder(
          valueListenable: adminPosPinController,
          builder: (context, TextEditingValue value, __) {
            return Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextField(
                autofocus: true,
                onSubmitted: (input) {
                  setState(() {
                    isButtonDisabled = true;
                  });
                  _submit(context);
                },
                obscureText: true,
                controller: adminPosPinController,
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  errorText: _submitted
                      ? errorPassword == null
                      ? errorPassword
                      : AppLocalizations.of(context)?.translate(errorPassword!)
                      : null,
                  border: OutlineInputBorder(
                    borderSide: BorderSide(color: color.backgroundColor),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: color.backgroundColor),
                  ),
                  labelText: "PIN",
                ),
              ),
            );
          }),
      actions: <Widget>[
        Row(
          children: [
            Expanded(
              flex: 1,
              child: SizedBox(
                height: MediaQuery.of(context).size.width > 900 && MediaQuery.of(context).size.height > 500
                    ? MediaQuery.of(context).size.height / 12
                    : MediaQuery.of(context).orientation == Orientation.landscape ? MediaQuery.of(context).size.height / 10
                    : MediaQuery.of(context).size.height / 20,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: color.backgroundColor,
                  ),
                  child: Text(
                    AppLocalizations.of(context)!.translate('close'),
                    style: TextStyle(color: Colors.white),
                  ),
                  onPressed: isButtonDisabled ? null : () {
                    setState(() {
                      isButtonDisabled = true;
                    });
                    Navigator.of(context).pop();
                  },
                ),
              ),
            ),
            SizedBox(width: 10),
            Expanded(
              flex: 1,
              child: SizedBox(
                height: MediaQuery.of(context).size.width > 900 && MediaQuery.of(context).size.height > 500
                    ? MediaQuery.of(context).size.height / 12
                    : MediaQuery.of(context).orientation == Orientation.landscape ? MediaQuery.of(context).size.height / 10
                    : MediaQuery.of(context).size.height / 20,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: color.buttonColor,
                  ),
                  child: Text(
                    AppLocalizations.of(context)!.translate('yes'),
                    style: TextStyle(color: Colors.white),
                  ),
                  onPressed: isButtonDisabled ? null : () async {
                    setState(() {
                      isButtonDisabled = true;
                    });
                    _submit(context);
                  },
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
