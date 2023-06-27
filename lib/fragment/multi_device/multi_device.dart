import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:pos_system/database/pos_database.dart';

import '../../object/product.dart';
import '../../object/server_action.dart';

class MultiDevicePage extends StatefulWidget {
  const MultiDevicePage({Key? key}) : super(key: key);

  @override
  State<MultiDevicePage> createState() => _MultiDevicePageState();
}

class _MultiDevicePageState extends State<MultiDevicePage> {
  List<Socket> clientList = [];
  final StreamController stramController = StreamController();
  String incomingMessage = "No device connected";
  final NetworkInfo networkInfo = NetworkInfo();

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    listen();
  }

  @override
  dispose() {
    super.dispose();
  }

  void listen() async {
    var ips = await networkInfo.getWifiIP();
    print('ips: $ips');
    ServerSocket.bind(ips, 9999).then((ServerSocket server) {
      print('server running on: ${ips}:9999');
      server.listen(handleClient);
    });
  }

  void handleClient(Socket client) {
    var response;
    Socket currentClient = client;
    print('server incoming connection from ${client.remoteAddress.address}:${client.remotePort}');
    bool sameClient = clientList.any((item) => item.remoteAddress == client.remoteAddress);
    if(!sameClient){
      clientList.add(client);
    }

    client.listen((data) async {
      print("server listen: ${String.fromCharCodes(data).trim()}");
      incomingMessage = String.fromCharCodes(data).trim();
      stramController.sink.add(incomingMessage);

      // setState(() {
      //   incomingMessage = String.fromCharCodes(data).trim();
      // });
      if(incomingMessage != '1') {
        var msg = jsonDecode(incomingMessage);
        if(msg['param'] != ''){
          response = await ServerAction().checkAction(action: msg['action'], param: msg['param']);
        } else {
          response = await ServerAction().checkAction(action: msg['action']);
        }
        print('server response2: ${jsonEncode(response)}');
        currentClient.write(jsonEncode(response) + '\n');
        currentClient.flush();
      }
      //incomingMessage =  await PosDatabase.instance.readAllTableToJson();
      //Map<String, dynamic> result = {'status': '1','data':jsonDecode(incomingMessage)};
      //var response = jsonEncode(result);
      //String response = "Success";
      //currentClient.write(jsonEncode(response));
      // String response = incomingMessage;
      // for (var clients in clientList) {
      //   clients.write(response);
      // }
    }, onDone: () {
      print("server done");
      //client.close();
    }, onError: (error){
      String response = 'Server response: Status 500$error';
      client.write(response);
      //client.close();
    });
    //client.close();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder(
        stream: stramController.stream,
        builder: (context, snapshot) {
          if(snapshot.hasData){
            return clientList.isNotEmpty ?
            Column(
              children: [
                ListView.builder(
                    shrinkWrap: true,
                    itemCount: clientList.length,
                    itemBuilder: (context, index){
                      return Card(
                        elevation: 5,
                        child: ListTile(
                          title: Text('${clientList[index].remoteAddress}'),
                        ),
                      );
                    }
                ),
                SizedBox(height: 10,),
                Text("Incoming message: ${incomingMessage}")
              ],
            ) :
            Center(
              child: Text('No device connected to server'),
            );
          } else {
            return Center(
              child: CircularProgressIndicator()
            );
          }
        }),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          ServerAction().encodeAllImage();
          // List<Product> data = await PosDatabase.instance.readAllClientProduct();
          // print('product length: ${data.length}');
        },
        child: Icon(Icons.call_made),

      ),
    );
  }
}
