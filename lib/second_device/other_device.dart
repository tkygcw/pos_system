import 'dart:io';

import 'package:flutter/material.dart';

class OtherDevice extends StatefulWidget {
  final List<Socket> clientSocket;
  const OtherDevice({Key? key, required this.clientSocket}) : super(key: key);

  @override
  State<OtherDevice> createState() => _OtherDeviceState();
}

class _OtherDeviceState extends State<OtherDevice> {

  List<Socket> socketList = [];

  @override
  initState() {
    super.initState();
    socketList.addAll(widget.clientSocket);
  }


  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text("Connected device ip"),
      content: Container(
        width: 300,
        child: ListView.builder(
          shrinkWrap: true,
          padding: EdgeInsets.zero,
          itemCount: socketList.length,
          itemBuilder: (context, index) {
            return Card(
              elevation: 5,
              child: ListTile(
                onTap: () {
                  Navigator.of(context).pop();
                },
                leading: Icon(
                  Icons.devices,
                ),
                title: Text('${socketList[index].remoteAddress.address}'),
              ),
            );
          },
        ),
      ),
    );
  }
}
