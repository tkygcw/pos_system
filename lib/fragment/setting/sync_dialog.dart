import 'dart:async';

import 'package:f_logs/model/flog/flog.dart';
import 'package:flutter/material.dart';
import 'package:pos_system/object/sync_to_cloud.dart';
import 'package:pos_system/page/progress_bar.dart';

import '../../main.dart';
import '../../translation/AppLocalizations.dart';

class SyncDialog extends StatefulWidget {
  const SyncDialog({Key? key}) : super(key: key);

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
    actionController.sink.add("init");
    streamSubscription = actionStream.listen((event) async {
      switch(event){
        case 'init':{
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
                    SizedBox(height: 20),
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
                        SizedBox(width: 10),
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
                    )
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
