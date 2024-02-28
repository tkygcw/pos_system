import 'dart:io';

import 'package:async_queue/async_queue.dart';
import 'package:flutter/material.dart';
import 'package:pos_system/main.dart';
import 'package:pos_system/second_device/other_device.dart';
import 'package:pos_system/second_device/server.dart';
import 'package:provider/provider.dart';

class DeviceSetting extends StatefulWidget {
  const DeviceSetting({Key? key}) : super(key: key);

  @override
  State<DeviceSetting> createState() => _DeviceSettingState();
}

class _DeviceSettingState extends State<DeviceSetting> {

  @override
  void initState() {
    super.initState();
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          ListTile(
            title: Text("Server socket ip: ${Server.instance.serverIp}"),
            onTap: () async{
              await Server.instance.bindServer();
            },
          ),
          Divider(
            color: Colors.grey,
            height: 1,
            thickness: 1,
            indent: 20,
            endIndent: 20,
          ),
          Consumer<Server>(
              builder: (context, server, child) {
                return ListTile(
                  title: Text("Connection management"),
                  subtitle: Text('Connected device: ${server.clientList.length}'),
                  trailing: Visibility(child: Icon(Icons.navigate_next), visible: server.clientList.isEmpty ? false : true),
                  onTap: server.clientList.isEmpty ? null : (){
                    openDeviceDialog(clientSocket: server.clientList);
                  },
                );
              }),
          // Text("queue is close: ${asyncQ.isClosed}"),
          // Text("queue length: ${asyncQ.size}"),
          ElevatedButton(
              onPressed: (){
                autoQ();
                // final asyncQueue = AsyncFunctionQueue();
                //
                // asyncQueue.enqueue(() async {
                //   try{
                //     throw Exception("self test");
                //   }catch(e){
                //     print("error: $e");
                //   }
                //   // print("Task 1 started");
                //   // await Future.delayed(Duration(seconds: 3));
                //   // print("Task 1 completed");
                // });
                //
                // asyncQueue.enqueue(() async {
                //   print("Task 2 started");
                //   await Future.delayed(Duration(seconds: 1));
                //   print("Task 2 completed");
                // });
              },
              child: Text("start queue"))
        ],
      )
    );
  }

  Future<void> autoQ() async {
    int i = 0;
    final autoAsyncQ = AsyncQueue.autoStart();
    autoAsyncQ.addQueueListener((event) => print("$event"));
    autoAsyncQ.addJob((_) =>
        Future.delayed(const Duration(seconds: 1), () => print("AutoQ: 1")));
    await Future.delayed(const Duration(seconds: 6));
    autoAsyncQ.addJob((_) =>
        Future.delayed(const Duration(seconds: 0), () => print("AutoQ: 1.2")));
    if(i == 0){
      autoAsyncQ.addJob((_) {
        Future.delayed(const Duration(seconds: 0), () {
          try{
            function1();
          }catch(e){
            print("error: $e");
            return Exception("eeeee");
            //return;
          }
        });
      }, retryTime: -1);
    } else {
      print("else called!!!");
    }
    print("something here");
    autoAsyncQ.addJob((_) =>
        Future.delayed(const Duration(seconds: 4), () => print("AutoQ: 2")));
    autoAsyncQ.addJob((_) =>
        Future.delayed(const Duration(seconds: 3), () => print("AutoQ: 2.2")));
    autoAsyncQ.addJob((_) =>
        Future.delayed(const Duration(seconds: 2), () => print("AutoQ: 3")));
    autoAsyncQ.addJob((_) =>
        Future.delayed(const Duration(seconds: 1), () => print("AutoQ: 4")));
  }

  function1(){
    throw Exception("error catch!");
  }

  Future<Future<Object?>> openDeviceDialog({required List<Socket> clientSocket}) async {
    return showGeneralDialog(
        barrierColor: Colors.black.withOpacity(0.5),
        transitionBuilder: (context, a1, a2, widget) {
          final curvedValue = Curves.easeInOutBack.transform(a1.value) - 1.0;
          return Transform(
            transform: Matrix4.translationValues(0.0, curvedValue * 200, 0.0),
            child: Opacity(
              opacity: a1.value,
              child: OtherDevice(clientSocket: clientSocket),
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

class AsyncFunctionQueue {
  final List<Function> _queue = [];
  bool _running = false;

  void enqueue(Function function) {
    _queue.add(function);
    if (!_running) {
      _executeQueue();
    }
  }

  Future<void> _executeQueue() async {
    _running = true;
    while (_queue.isNotEmpty) {
      final currentFunction = _queue.removeAt(0);
      await currentFunction();
    }
    _running = false;
  }
}
