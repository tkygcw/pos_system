import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pos_system/notifier/app_setting_notifier.dart';
import 'package:provider/provider.dart';

import '../../database/pos_database.dart';
import '../../notifier/theme_color.dart';
import '../../object/app_setting.dart';
import '../../translation/AppLocalizations.dart';

class AdjustHourDialog extends StatefulWidget {
  final int exp_hour;
  const AdjustHourDialog({Key? key, required this.exp_hour}) : super(key: key);

  @override
  State<AdjustHourDialog> createState() => _AdjustHourDialogState();
}

class _AdjustHourDialogState extends State<AdjustHourDialog> {
  TextEditingController hourController = TextEditingController();
  int tapCount = 0;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    hourController.text = widget.exp_hour.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeColor>(builder: (context, ThemeColor color, child) {
      return AlertDialog(
        title: Text(AppLocalizations.of(context)!.translate('set_default_exp_after_hour')),
        content: SizedBox(
          width: 350,
          height: 100,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // quantity input remove button
              Container(
                decoration: BoxDecoration(
                  color: color.backgroundColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: IconButton(
                  icon: Icon(Icons.remove, color: Colors.white), // Set the icon color to white.
                  onPressed: () {
                    if(int.parse(hourController.text) != 1){
                      hourController.text = (int.parse(hourController.text) - 1).toString();
                    }
                  },
                ),
              ),
              SizedBox(width: 10),
              // quantity input text field
              Container(
                width: 200,
                child: TextField(
                  readOnly: true,
                  controller: hourController,
                  textAlign: TextAlign.center,
                  decoration: InputDecoration(
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: color.backgroundColor),
                    ),
                  ),
                ),
              ),
              SizedBox(width: 10),
              // quantity input add button
              Container(
                decoration: BoxDecoration(
                  color: color.backgroundColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: IconButton(
                  icon: Icon(Icons.add, color: Colors.white),
                  onPressed: () {
                    if(int.parse(hourController.text) != 12){
                      hourController.text = (int.parse(hourController.text) + 1).toString();
                    }
                  },
                ),
              ),
            ],
          ),
        ),
        actions: [
          SizedBox(
            width: 200,
            height: 60,
            child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: color.buttonColor
                ),
                onPressed: () async {
                  tapCount++;
                  if(tapCount == 1){
                    await updateAppSetting();
                    AppSettingModel.instance.setDynamicQrDefaultExpAfterHour(int.parse(hourController.text));
                    Navigator.of(context).pop();
                  }
                },
                child: Text(AppLocalizations.of(context)!.translate('update'))),
          ),
          SizedBox(
            width: 200,
            height: 60,
            child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red
                ),
                onPressed: () {
                  tapCount++;
                  if(tapCount == 1){
                    Navigator.of(context).pop();
                  }
                },
                child: Text(AppLocalizations.of(context)!.translate('close'))),
          ),
        ],
      );
    });
  }

  updateAppSetting() async {
    DateFormat dateFormat = DateFormat("yyyy-MM-dd HH:mm:ss");
    String dateTime = dateFormat.format(DateTime.now());
    AppSetting object = AppSetting(
        dynamic_qr_default_exp_after_hour: int.parse(hourController.text),
        sync_status: 2,
        updated_at: dateTime
    );
    int data = await PosDatabase.instance.updateAppSettingsDynamicQrDefaultExpAfterHour(object);
  }
}
