import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:pos_system/fragment/setting/sync_dialog.dart';

import '../../main.dart';
import '../../translation/AppLocalizations.dart';

class DataProcessingSetting extends StatefulWidget {
  const DataProcessingSetting({Key? key}) : super(key: key);

  @override
  State<DataProcessingSetting> createState() => _DataProcessingSettingState();
}

class _DataProcessingSettingState extends State<DataProcessingSetting> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            ListTile(
              title: Text(AppLocalizations.of(context)!.translate('sync')),
              trailing: Icon(Icons.sync),
              onTap: () async {
                openSyncDialog();
              },
            ),
            ListTile(
              title: Text(AppLocalizations.of(context)!.translate('sync_reset')),
              trailing: Icon(Icons.refresh),
              onTap: () async {
                syncRecord.count = 0;
                qrOrder.count = 0;
                Fluttertoast.showToast(msg: AppLocalizations.of(context)!.translate('sync_reset_success'));
              },
            ),
            Divider(
              color: Colors.grey,
              height: 1,
              thickness: 1,
              indent: 20,
              endIndent: 20,
            ),
          ],
        ),
      ),
    );
  }

  Future<Future<Object?>> openSyncDialog() async {
    return showGeneralDialog(
        barrierColor: Colors.black.withOpacity(0.5),
        transitionBuilder: (context, a1, a2, widget) {
          final curvedValue = Curves.easeInOutBack.transform(a1.value) - 1.0;
          return Transform(
            transform: Matrix4.translationValues(0.0, curvedValue * 200, 0.0),
            child: Opacity(
              opacity: a1.value,
              child: SyncDialog(),
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
