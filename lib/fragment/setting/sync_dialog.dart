import 'dart:async';

import 'package:flutter/material.dart';
import 'package:pos_system/page/progress_bar.dart';

import '../../main.dart';
import '../../translation/AppLocalizations.dart';

class SyncDialog extends StatefulWidget {
  const SyncDialog({Key? key}) : super(key: key);

  @override
  State<SyncDialog> createState() => _SyncDialogState();
}

class _SyncDialogState extends State<SyncDialog> {
  StreamController controller = StreamController();
  StreamController actionController = StreamController();
  late Stream contentStream;
  late Stream actionStream;
  late StreamSubscription streamSubscription;
  bool isButtonDisable = false;

  @override
  void initState() {
    super.initState();
    contentStream = controller.stream.asBroadcastStream();
    actionStream = actionController.stream.asBroadcastStream();
    listenAction();
  }

  @override
  void dispose() {
    streamSubscription.cancel();
    super.dispose();
  }

  listenAction(){
    actionController.sink.add("init");
    streamSubscription = actionStream.listen((event) async {
      switch(event){
        case 'init':{
          await syncData();
          Future.delayed(const Duration(seconds: 2), () {
            controller.sink.add("refresh");
          });
        }
        break;
        case 'close': {
          isButtonDisable = true;
          controller.sink.add("refresh");
          Navigator.of(context).pop();
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      content: Container(
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height / 2),
        child: StreamBuilder(
            stream: contentStream,
            builder: (context, snapshot){
              if(snapshot.hasData){
                return Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(AppLocalizations.of(context)!.translate('sync_done')),
                    SizedBox(height: 15),
                    ElevatedButton(
                      onPressed: isButtonDisable ? null : () {
                        actionController.sink.add("close");
                      },
                      child: Icon(Icons.done, color: Colors.white),
                      style: ElevatedButton.styleFrom(
                        shape: CircleBorder(),
                        padding: EdgeInsets.all(20)
                      ),
                    ),
                  ],
                );
              } else {
                return CustomProgressBar();
              }
            }),
      ),
    );
  }

  syncData() async {
    try{
      if(syncRecord.count == 0){
        syncRecord.count = 1;
        await syncRecord.syncFromCloud();
        syncRecord.count = 0;
      }
      await mainSyncToCloud.syncAllToCloud();
    }catch(e){
      syncRecord.count = 0;
      print("sync data error: ${e}");
    }
  }
}