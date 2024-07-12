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
      // return;
    } else {
      return;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeColor>(builder: (context, ThemeColor color, child) {
      return Center(
        child: SingleChildScrollView(
          child: AlertDialog(
            title: Text(AppLocalizations.of(context)!.translate('multi_device_login')),
            content: Container(
              height: MediaQuery.of(context).size.height > 500 ? 225 : MediaQuery.of(context).size.height/2.5,
              width: 400,
              child: Column(
                children: [
                  Text("${AppLocalizations.of(context)?.translate('confirm_logout_desc')}"),
                  SizedBox(height: 10),
                  ValueListenableBuilder(
                    // Note: pass _controller to the animation argument
                      valueListenable: adminPosPinController,
                      builder: (context, TextEditingValue value, __) {
                        return Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: TextField(
                            //inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9]'))],
                            onSubmitted: (input) {
                              _submit(context);
                            },
                            controller: adminPosPinController,
                            decoration: InputDecoration(
                              labelText: AppLocalizations.of(context)!.translate('yes'),
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
                            ),
                          ),
                        );
                      }),
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
                child: Text('${AppLocalizations.of(context)?.translate('yes')}'),
                onPressed: isButtonDisabled ? null : () async {
                  _submit(context);
                },
              ),
            ],
          ),
        ),
      );
    });
  }
}
