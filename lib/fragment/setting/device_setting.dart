import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:pos_system/object/server_action.dart';
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
            onTap: () async {
              await Server.instance.bindServer();
              await Server.instance.bindRequestServer();
             setState(() {});
            },
          ),
          Divider(
            color: Colors.grey,
            height: 1,
            thickness: 1,
            indent: 20,
            endIndent: 20,
          ),
          ElevatedButton(
              onPressed: () async {
                List<Socket> clientSocketList = Server.instance.clientList;
                for(int i = 0; i < clientSocketList.length; i++){
                  Map<String, dynamic>? result = await ServerAction().checkAction(action: '1');
                  clientSocketList[i].write("${jsonEncode(result)}\n");
                }
              },
              child: Text("Backend received notification"))
          // Consumer<Server>(
          //     builder: (context, server, child) {
          //       return ListTile(
          //         title: Text("Connection management"),
          //         subtitle: Text('Connected device: ${server.clientList.length}'),
          //         trailing: Visibility(child: Icon(Icons.navigate_next), visible: server.clientList.isEmpty ? false : true),
          //         onTap: server.clientList.isEmpty ? null : (){
          //           openDeviceDialog(clientSocket: server.clientList);
          //         },
          //       );
          //     }),
        ],
      )
    );
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

