import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../notifier/theme_color.dart';
import '../translation/AppLocalizations.dart';
import 'login.dart';

class DeviceCheckDialog extends StatefulWidget {
  final Function() callBack;
  const DeviceCheckDialog({Key? key, required this.callBack}) : super(key: key);

  @override
  State<DeviceCheckDialog> createState() => _DeviceCheckDialogState();
}

class _DeviceCheckDialogState extends State<DeviceCheckDialog> {
  final adminPosPinController = TextEditingController();
  int buttonTap = 0;
  bool isButtonDisabled = false, _submitted = false;

  String? get errorPassword {
    final text = adminPosPinController.value.text;
    if (text.isEmpty) {
      return 'password_required';
    } else if (text != "YES") {
      return 'enter_yes';
    }
    return null;
  }

  _submit(BuildContext context) async  {
    setState(() => _submitted = true);
    if (errorPassword == null) {
      widget.callBack();
    } else {
      buttonTap = 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeColor>(builder: (context, ThemeColor color, child) {
      return Center(
        child: SingleChildScrollView(
          child: AlertDialog(
            title: Row(
              children: [
                Icon(Icons.warning_rounded, color: Colors.red[700], size: 40),
                SizedBox(width: 10),
                Flexible(
                  child: Text(
                    AppLocalizations.of(context)!.translate('multi_device_login'),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                ),
              ],
            ),
            content: Container(
              width: 400,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red[50],
                      border: Border.all(color: Colors.red[300]!),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.security, color: Colors.red[700], size: 24),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            "${AppLocalizations.of(context)?.translate('confirm_logout_warning')}",
                            style: TextStyle(
                              fontWeight: FontWeight.w500,
                              color: Colors.red[900],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 10),
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red[50],
                      border: Border.all(color: Colors.red[300]!),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.security, color: Colors.red[700], size: 24),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            "${AppLocalizations.of(context)?.translate('confirm_logout_desc')}",
                            style: TextStyle(
                              fontWeight: FontWeight.w500,
                              color: Colors.red[900],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 20),
                  ValueListenableBuilder(
                      valueListenable: adminPosPinController,
                      builder: (context, TextEditingValue value, __) {
                        return Container(
                          decoration: BoxDecoration(
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black12,
                                blurRadius: 5,
                                offset: Offset(0, 2),
                              ),
                            ],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: TextField(
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              color: Colors.red[800],
                            ),
                            onSubmitted: (input) {
                              _submit(context);
                            },
                            controller: adminPosPinController,
                            decoration: InputDecoration(
                              contentPadding: EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                              hintText: "YES",
                              hintStyle: TextStyle(
                                color: Colors.red[100],
                                fontWeight: FontWeight.w500,
                              ),
                              labelStyle: TextStyle(
                                color: Colors.red[700],
                                fontWeight: FontWeight.w600,
                              ),
                              errorText: _submitted
                                  ? errorPassword == null ? errorPassword : AppLocalizations.of(context)?.translate(errorPassword!)
                                  : null,
                              filled: true,
                              fillColor: Colors.white,
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: Colors.red[400]!, width: 2),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: Colors.red[700]!, width: 2),
                              ),
                              errorBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: Colors.red[900]!, width: 2),
                              ),
                              prefixIcon: Icon(
                                Icons.warning_amber_rounded,
                                color: Colors.red[900],
                              ),
                            ),
                          ),
                        );
                      }
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                child: Text('${AppLocalizations.of(context)?.translate('back_to_login')}'),
                onPressed: isButtonDisabled ? null : () {
                  // Disable the button after it has been pressed
                  setState(() {
                    isButtonDisabled = true;
                  });
                  Navigator.of(context).pushAndRemoveUntil(
                    // the new route
                    MaterialPageRoute(
                      builder: (BuildContext context) => LoginPage(),
                    ),

                    // this function should return true when we're done removing routes
                    // but because we want to remove all other screens, we make it
                    // always return false
                        (Route route) => false,
                  );
                },
              ),
              TextButton(
                child: Text('${AppLocalizations.of(context)?.translate('yes')}',
                    style: TextStyle(
                        color: Colors.red[700]
                    )),
                onPressed: isButtonDisabled ? null : () async {
                  setState(() {
                    isButtonDisabled = true;
                  });
                  _submit(context);
                  setState(() {
                    isButtonDisabled = false;
                  });
                },
              ),
            ],
          ),
        ),
      );
    });
  }
}
