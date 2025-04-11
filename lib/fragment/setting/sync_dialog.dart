import 'dart:async';

import 'package:f_logs/model/flog/flog.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pos_system/database/pos_database.dart';
import 'package:pos_system/firebase_sync/sync_to_firebase.dart';
import 'package:pos_system/object/sync_to_cloud.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../main.dart';
import '../../translation/AppLocalizations.dart';

enum SyncType {
  sync,
  firestore_sync,
  sync_updates_from_cloud
}

class SyncDialog extends StatefulWidget {
  final SyncType syncType;
  final Function() callBack;
  const SyncDialog({Key? key, required this.syncType, required this.callBack}) : super(key: key);

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

  DateFormat dateFormat = DateFormat("HH:mm:ss");
  String unsyncedData = "";

  @override
  void initState() {
    super.initState();
    contentStream = controller.stream.asBroadcastStream();
    actionStream = actionController.stream.asBroadcastStream();
    calUnsyncedData();
    listenAction();
  }

  @override
  void dispose() {
    streamSubscription.cancel();
    timer?.cancel();
    super.dispose();
  }

  calUnsyncedData() async {
    unsyncedData = await PosDatabase.instance.getUnsyncedData();
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
        case 'pause': {
          // isSyncing = false;
          isPaused = true;
          // Navigator.of(context).pop(true);
        }
        break;
        case SyncType.firestore_sync: {
          manualSyncToFirestore();
        }
        break;
        case SyncType.sync_updates_from_cloud: {
          manualSyncUpdatesFromCloud();
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
                    Text(isPaused ? AppLocalizations.of(context)!.translate('sync_paused') : AppLocalizations.of(context)!.translate('sync_done')),
                    SizedBox(height: 15),
                    ElevatedButton(
                      onPressed: isButtonDisable ? null : () {
                        if(isPaused){
                          actionController.sink.add("retry");
                        } else {
                          actionController.sink.add("close");
                        }
                        widget.callBack();
                      },
                      child: Icon(isPaused ? Icons.play_arrow : Icons.done, color: Colors.white),
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
                        widget.callBack();
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
                return Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    StreamBuilder<int>(
                      stream: Stream.periodic(Duration(milliseconds: 500), (count) => count % 4),
                      builder: (context, snapshot) {
                        String dots = '.' * (snapshot.data ?? 0 + 1);
                        return Text(!isPaused ? "${AppLocalizations.of(context)!.translate('syncing')}$dots" : "${AppLocalizations.of(context)!.translate('pausing')}$dots");
                      },
                    ),
                    SizedBox(height: 15),
                    ElevatedButton(
                      onPressed: isButtonDisable ? null : () {
                        actionController.sink.add("pause");
                      },
                      child: Icon(Icons.pause, color: Colors.white),
                      style: ElevatedButton.styleFrom(
                          shape: CircleBorder(),
                          padding: EdgeInsets.all(20)
                      ),
                    ),
                  ],
                );
              }
            }),
      ),
      actions: [
        ElevatedButton.icon(
          onPressed: isButtonDisable ? null : () {
            actionController.sink.add("close");
            widget.callBack();
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

  manualSyncUpdatesFromCloud(){
    print("manualSyncUpdatesFromCloud called");
    try{
      syncRecord.syncFromCloud();
      Future.delayed(Duration(seconds: 3), () => controller.sink.add("refresh"));
    }catch(e){
      controller.sink.add("refresh");
      FLog.error(
        className: "sync_dialog",
        text: "manualSyncUpdatesFromCloud error",
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
        // FLog.info(
        //   className: "sync_dialog",
        //   text: "Manual sync: Start",
        // );
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
    DateTime startSync = DateTime.now();
    try{
      int status = 0;
      if(mainSyncToCloud.count == 0){
        mainSyncToCloud.count = 1;
        //start sync
        if(!isSyncisSyncingingNotifier.value){
          print("sync called from sync dialog");
          isSyncisSyncingingNotifier.value = true;
          do{
            widget.callBack();
            status = await syncToCloud.syncAllToCloud(isManualSync: true);
          }while(syncToCloud.emptyResponse == false);
          if(syncToCloud.emptyResponse == true){
            isSyncisSyncingingNotifier.value = false;
            isPaused = false;
          }
          mainSyncToCloud.count = 0;
          final prefs = await SharedPreferences.getInstance();
          if(prefs.getInt('new_sync') == null){
            await prefs.setInt('new_sync', 0);
          }
          Future.delayed(const Duration(seconds: 2), () {
            if(status == 0){
              controller.sink.add("refresh");
            } else {
              controller.sink.addError(Exception("Sync failed"));
            }
            widget.callBack();
          });
        } else {
          isSyncisSyncingingNotifier.value = true;
          controller.sink.add("refresh");
          print("sync to cloud is running");
        }
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
            if(syncToCloud.emptyResponse == true){
              isSyncisSyncingingNotifier.value = false;
            }
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
