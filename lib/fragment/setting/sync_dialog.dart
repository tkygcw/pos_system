import 'dart:async';

import 'package:f_logs/model/flog/flog.dart';
import 'package:flutter/material.dart';
import 'package:pos_system/firebase_sync/sync_to_firebase.dart';
import 'package:pos_system/object/sync_to_cloud.dart';
import 'package:pos_system/page/progress_bar.dart';

import '../../main.dart';
import '../../translation/AppLocalizations.dart';

enum SyncType {
  sync,
  firestore_sync
}

class SyncDialog extends StatefulWidget {
  final SyncType syncType;
  const SyncDialog({Key? key, required this.syncType}) : super(key: key);

  @override
  State<SyncDialog> createState() => _SyncDialogState();
}

class _SyncDialogState extends State<SyncDialog> {
  SyncToCloud syncToCloud = SyncToCloud();
  StreamController controller = StreamController();
  StreamController actionController = StreamController();
  late Stream contentStream;
  late Stream actionStream;
  late StreamSubscription streamSubscription;
  Timer? timer;
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
    timer?.cancel();
    super.dispose();
  }

  listenAction(){
    actionController.sink.add(widget.syncType);
    streamSubscription = actionStream.listen((event) async {
      switch(event){
        case SyncType.sync :{
          await syncData();
          await syncToCloudChecking();
        }
        break;
        case 'retry':{
          controller.sink.add(null);
          await syncData();
          await syncToCloudChecking();
        }
        break;
        case 'close': {
          isButtonDisable = true;
          Navigator.of(context).pop(true);
        }
        break;
        case SyncType.firestore_sync: {
          manualSyncToFirestore();
        }
        break;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      content: Container(
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height / 3),
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
              } else if (snapshot.hasError){
                return Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(AppLocalizations.of(context)!.translate('sync_failed')),
                    SizedBox(height: 15),
                    ElevatedButton(
                      onPressed: isButtonDisable ? null : () {
                        actionController.sink.add("close");
                      },
                      child: Icon(Icons.close, color: Colors.white),
                      style: ElevatedButton.styleFrom(
                          shape: CircleBorder(),
                          backgroundColor: Colors.redAccent,
                          padding: EdgeInsets.all(20)
                      ),
                    ),
                    SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ElevatedButton.icon(
                          onPressed: isButtonDisable ? null : () {
                            actionController.sink.add("retry");
                          },
                          label: Text(AppLocalizations.of(context)!.translate('retry')),
                          icon: Icon(Icons.refresh),
                        ),
                      ],
                    )
                  ],
                );
              } else {
                return CustomProgressBar();
              }
            }),
      ),
      actions: [
        ElevatedButton.icon(
          onPressed: isButtonDisable ? null : () {
            actionController.sink.add("close");
          },
          style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent
          ),
          label: Text(AppLocalizations.of(context)!.translate('close')),
          icon: Icon(Icons.close),
        ),
      ],
    );
  }

  manualSyncToFirestore(){
    try{
      FLog.info(
        className: "sync_dialog",
        text: "Manual firestore sync: start",
      );
      SyncToFirebase.instance.sync();
      Future.delayed(Duration(seconds: 3), () => controller.sink.add("refresh"));
    }catch(e){
      controller.sink.add("refresh");
      FLog.error(
        className: "sync_dialog",
        text: "manualSyncToFirestore error",
        exception: e,
      );
    }
  }

  syncData() async {
    try{
      if(syncRecord.count == 0){
        syncRecord.count = 1;
        await syncRecord.syncFromCloud();
        syncRecord.count = 0;
        FLog.info(
          className: "sync_dialog",
          text: "Manual sync: Start",
        );
      }
    }catch(e){
      syncRecord.count = 0;
      FLog.error(
        className: "sync_dialog",
        text: "Manual sync data from cloud error",
        exception: e,
      );
    }
  }

  syncToCloudChecking() async {
    try{
      int status = 0;
      if(mainSyncToCloud.count == 0){
        mainSyncToCloud.count = 1;
        //start sync
        do{
          status = await syncToCloud.syncAllToCloud(isManualSync: true);
        }while(syncToCloud.emptyResponse == false);
        mainSyncToCloud.count = 0;
        Future.delayed(const Duration(seconds: 2), () {
          if(status == 0){
            controller.sink.add("refresh");
          } else {
            controller.sink.addError(Exception("Sync failed"));
          }
        });
      } else {
        //if auto sync is running, check every 2 second
        timer = Timer.periodic(Duration(seconds: 2), (timer) async {
          //reset sync count
          mainSyncToCloud.count = 0;
          if(mainSyncToCloud.count == 0){
            this.timer?.cancel();
            mainSyncToCloud.count = 1;
            do{
              status = await syncToCloud.syncAllToCloud(isManualSync: true);
            }while(syncToCloud.emptyResponse == false);
            mainSyncToCloud.count = 0;

            Future.delayed(const Duration(seconds: 2), () {
              if(status == 0){
                controller.sink.add("refresh");
              } else {
                controller.sink.addError(Exception("Sync failed"));
              }
            });
          }
        });
      }
    }catch(e){
      timer?.cancel();
      controller.sink.addError(Exception(e));
      print("sync to cloud checking error: ${e}");
      FLog.error(
        className: "sync_dialog",
        text: "Manual sync to cloud error",
        exception: e,
      );
    }
  }
}
