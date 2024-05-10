import 'dart:io';

import 'package:flutter/material.dart';
import 'package:pos_system/notifier/connectivity_change_notifier.dart';
import 'package:pos_system/second_device/other_device.dart';
import 'package:pos_system/second_device/server.dart';
import 'package:provider/provider.dart';

import '../../translation/AppLocalizations.dart';

class DeviceSetting extends StatefulWidget {
  const DeviceSetting({Key? key}) : super(key: key);

  @override
  State<DeviceSetting> createState() => _DeviceSettingState();
}

class _DeviceSettingState extends State<DeviceSetting> {
  Server server = Server.instance;
  late ConnectivityChangeNotifier connectivity;

  @override
  Widget build(BuildContext context) {
    connectivity = context.watch<ConnectivityChangeNotifier>();
    return Scaffold(
      body: Column(
        children: [
          ListTile(
            title: Text(AppLocalizations.of(context)!.translate('bind_ip_address')),
            subtitle: Text("${AppLocalizations.of(context)!.translate('device_ip')}: ${server.serverIp}"),
            trailing: server.serverIp != null && server.serverIp != '-' ? Icon(Icons.link) : Icon(Icons.link_off),
            onTap: () async {
              await server.bindServer();
              await server.bindRequestServer();
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
          Consumer<Server>(
              builder: (context, server, child) {
                return ListTile(
                  title: Text(AppLocalizations.of(context)!.translate('connection_management')),
                  subtitle: Text('${AppLocalizations.of(context)?.translate('connected_device')}: ${server.clientList.length}'),
                  trailing: Visibility(child: Icon(Icons.navigate_next), visible: server.clientList.isEmpty ? false : true),
                  onTap: server.clientList.isEmpty ? null : (){
                    openDeviceDialog(clientSocket: server.clientList);
                  },
                );
              }),
        ],
      )
    );
  }

  getServerIp(){
    if(!connectivity.isConnect){
      return '-';
    }
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

