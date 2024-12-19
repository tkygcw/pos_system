import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:pos_system/fragment/settlement/settlment_query.dart';
import 'package:pos_system/notifier/connectivity_change_notifier.dart';
import 'package:pos_system/notifier/theme_color.dart';
import 'package:pos_system/page/progress_bar.dart';
import 'package:pos_system/second_device/other_device.dart';
import 'package:pos_system/second_device/server.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../translation/AppLocalizations.dart';

class DeviceSetting extends StatefulWidget {
  const DeviceSetting({Key? key}) : super(key: key);

  @override
  State<DeviceSetting> createState() => _DeviceSettingState();
}

Server server = Server.instance;

class _DeviceSettingState extends State<DeviceSetting> {
  late ConnectivityChangeNotifier connectivity;
  bool hasAccess = true;

  Future<void> checkStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final String? branch = prefs.getString('branch');
    Map branchObject = json.decode(branch!);
    if (branchObject['sub_pos_status'] == 1 || branchObject['sub_pos_status'] == null) {
      hasAccess = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeColor>(builder: (context, ThemeColor color, child) {
      return FutureBuilder(
          future: checkStatus(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.done) {
              return Scaffold(
                appBar:  MediaQuery.of(context).size.width < 800 && MediaQuery.of(context).orientation == Orientation.portrait ? AppBar(
                  elevation: 1,
                  leading: IconButton(
                    icon: Icon(Icons.arrow_back_ios, color: color.buttonColor),
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                  ),
                  backgroundColor: Colors.white,
                  title: Text(AppLocalizations.of(context)!.translate('device_setting'),
                      style: TextStyle(fontSize: 20, color: color.backgroundColor)),
                  centerTitle: false,
                )
                    : null,
                resizeToAvoidBottomInset: false,
                body: hasAccess
                    ? Consumer<ConnectivityChangeNotifier>(builder: (context, connectivity, child) {
                  return Column(
                    children: [
                      BindIpWidget(),
                      Divider(
                        color: Colors.grey,
                        height: 1,
                        thickness: 1,
                        indent: 20,
                        endIndent: 20,
                      ),
                      Consumer<Server>(builder: (context, server, child) {
                        return ListTile(
                          title: Text(
                              AppLocalizations.of(context)!.translate('connection_management')),
                          subtitle: Text(
                              '${AppLocalizations.of(context)?.translate('connected_device')}: ${server.clientList.length}'),
                          trailing: Visibility(
                              child: Icon(Icons.navigate_next),
                              visible: server.clientList.isEmpty ? false : true),
                          onTap: server.clientList.isEmpty
                              ? null
                              : () {
                            openDeviceDialog(clientSocket: server.clientList);
                          },
                        );
                      }),
                      ElevatedButton(
                          onPressed: () async {
                            await SettlementQuery(branch_id: '3').generateSalesPerDay();
                          },
                          child: Text("generate sales per day"),
                      )
                    ],
                  );
                })
                    : Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Column(
                        children: [
                          Icon(Icons.lock),
                          Text(
                              AppLocalizations.of(context)!.translate('upgrade_to_use_sub_pos'))
                        ],
                      )
                    ]),
              );
            } else {
              return CustomProgressBar();
            }
          });
    });
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
        barrierDismissible: true,
        barrierLabel: 'connected_device',
        context: context,
        pageBuilder: (context, animation1, animation2) {
          // ignore: null_check_always_fails
          return null!;
        });
  }
}

class BindIpWidget extends StatefulWidget {
  const BindIpWidget({Key? key}) : super(key: key);

  @override
  State<BindIpWidget> createState() => _BindIpWidgetState();
}

class _BindIpWidgetState extends State<BindIpWidget> {
  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(AppLocalizations.of(context)!.translate('bind_ip_address')),
      subtitle: Text("${AppLocalizations.of(context)!.translate('device_ip')}: ${server.serverIp}"),
      trailing: server.serverIp != null && server.serverIp != '-'
          ? Icon(Icons.link)
          : Icon(Icons.link_off),
      onTap: () async {
        await server.bindServer();
        await server.bindRequestServer();
        setState(() {});
      },
    );
  }
}
