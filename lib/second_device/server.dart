import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:f_logs/model/flog/flog.dart';
import 'package:flutter/cupertino.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:pos_system/main.dart';
import 'package:pos_system/object/server_action.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../database/pos_database.dart';
import '../object/branch.dart';

class Server extends ChangeNotifier {
  final NetworkInfo networkInfo = NetworkInfo();
  static const messageDelimiter = '\n';
  List<Socket> requestClient = [];
  List<Socket> clientList = [];
  ServerSocket? serverSocket, requestSocket;
  static String _serverIp = '-';
  static final Server instance = Server._init();

  Server._init();

  String? get serverIp => _serverIp;

  Future<String?> getDeviceIp() async {
    var wifiIP = await networkInfo.getWifiIP();
    if (wifiIP == null) {
      List<NetworkInterface> interfaces = await NetworkInterface.list();
      for (var interface in interfaces) {
        for (var address in interface.addresses) {
          _serverIp = address.address;
        }
      }
    } else {
      _serverIp = wifiIP;
    }
    return _serverIp;
  }

  Future<void> bindAllSocket() async {
    final prefs = await SharedPreferences.getInstance();
    final String? branch = prefs.getString('branch');
    Map<String, dynamic> branchMap = json.decode(branch!);
    Branch branchObject = Branch.fromJson(branchMap);
    print("sub pos status: ${branchObject.sub_pos_status}");
    if (branchObject.sub_pos_status == 0) {
      await bindServer();
      await bindRequestServer();
    } else if (branchObject.sub_pos_status == null) {
      //update share pref
      Branch? branch = await PosDatabase.instance.readSpecificBranch(branchObject.branch_id!);
      await prefs.setString('branch', json.encode(branch!));
      if (branch.sub_pos_status == 0) {
        await bindServer();
        await bindRequestServer();
      }
    }
  }

  void closeSocket() {
    serverSocket!.close();
  }

  void addClient(Socket clientSocket) {
    if(clientList.isEmpty){
      clientList.add(clientSocket);
    } else {
      removeClient(clientSocket, notNotify: true);
      clientList.add(clientSocket);
    }
    notifyListeners();
  }

  void removeClient(Socket clientSocket, {bool? notNotify}) {
    for(int i = 0; i < clientList.length; i++){
      try{
        if(clientList[i].remoteAddress.address == clientSocket.remoteAddress.address) {
          clientList.remove(clientList[i]);
        }
      }catch(e){
        print("remove client error: $e");
        clientList.remove(clientList[i]);
      }
    }
    if(notNotify == null){
      notifyListeners();
    }
  }

  Future<void> bindServer() async {
    final ips = await instance.getDeviceIp();
    if (ips != null) {
      try {
        serverSocket = await ServerSocket.bind(ips, 9999, shared: true);
      } catch (e) {
        _serverIp = "-";
        FLog.error(
          className: "socket",
          text: "Bind server socket error",
          exception: "$e",
        );
        return;
      }
      serverSocket!.listen((currentClient) async {
        addClient(currentClient);
        //print("client length in bind: ${server.clientList.length}");
        await handleClient(currentClient);
      });
    } else {
      _serverIp = "-";
    }
  }

  Future<void> handleClient(Socket clientSocket) async {
    StringBuffer buffer = StringBuffer();
    Map<String, dynamic>? response;

    clientSocket.listen(
      (List<int> data) async {
        String receivedData = utf8.decode(data, allowMalformed: true);
        buffer.write(receivedData);

        List<String> messageList = buffer.toString().split(messageDelimiter);
        print("message length: ${messageList.length}");
        List<String> messages = messageList.where((e) => e != messageDelimiter).toList();
        for (int i = 0; i < messages.length; i++) {
          //print("message: ${messages[i]}");
          final message = messages[i];
          if (message.isNotEmpty) {
            //process the request
            var msg = jsonDecode(message);
            if (msg['param'] != '') {
              response =
                  await ServerAction().checkAction(action: msg['action'], param: msg['param']);
            } else {
              response = await ServerAction().checkAction(action: msg['action']);
            }
            //Broadcast the message to all other clients
            clientSocket.write("${jsonEncode(response)}$messageDelimiter");
            // for (var otherClient in clients) {
            //   otherClient.write("${jsonEncode(response)}\n");
            // }
          }
        }
        //Update the buffer with the remaining incomplete message
        buffer.clear();
        buffer.write(messageList.last);
        print("after process buffer: ${buffer.toString()}");
      },
      onDone: () {
        removeClient(clientSocket);
        clientSocket.close();
        print("on done client list: ${clientList.length}");
      },
      onError: (error) {
        print("server handle client error: ${error}");
        clientSocket.destroy();
      },
    );
  }

  sendMessageToClient(String action){
    var msg = {'status': '1', 'action': action};
    for (var client in clientList) {
      client.write("${jsonEncode(msg)}$messageDelimiter");
    }
  }

  sendRefreshMessage() {
    for (var otherClient in clientList) {
      otherClient.write("refresh");
    }
  }

  Future<void> bindRequestServer() async {
    List<Socket> client2 = [];
    final ips = await instance.serverIp;
    if (ips != null && ips != '-') {
      try {
        requestSocket = await ServerSocket.bind(ips, 8888, shared: true);
      } catch (e) {
        FLog.error(
          className: "socket",
          text: "Bind request socket error",
          exception: "$e",
        );
        return;
      }
      requestSocket!.listen((clientSocket) async {
        client2.add(clientSocket);
        await handleClient2(clientSocket, client2);
      });
    }
  }

  Future<void> handleClient2(Socket clientSocket, List<Socket> clients) async {
    StringBuffer buffer = StringBuffer();
    Map<String, dynamic>? response;
    String receivedData = '';
    clientSocket.listen((List<int> data) async {
      asyncQ.addJob((_) async {
        try {
          print("socket2 called");
          receivedData = utf8.decode(data, allowMalformed: true);
          print("received data: ${receivedData}");
          buffer.write(receivedData);

          if (buffer.toString().endsWith(messageDelimiter)) {
            final message = buffer.toString().trim();
            var msg = jsonDecode(jsonEncode(jsonDecode(message)));
            if (msg['param'] != '') {
              response = await ServerAction().checkAction(
                  action: msg['action'],
                  param: msg['param'],
                  address: clientSocket.remoteAddress.address);
            } else {
              response = await ServerAction().checkAction(
                  action: msg['action'], address: clientSocket.remoteAddress.address);
            }
            print("server response 2: ${response}");

            clientSocket.write("${jsonEncode(response)}$messageDelimiter");
            buffer.clear();
          }
        } catch (e) {
          FLog.error(
            className: "handleClient2",
            text: "Handle client request 2 error",
            exception: "$e",
          );
        }
        print("handle client queue done!!!");
      });
      },
        cancelOnError: true,
        onDone: () {
          print("client done called!!!");
          clients.remove(clientSocket);
          clientSocket.close();
        },
        onError: (error) {
          print("handle client 2 error: ${error}");
          clientSocket.close();
        });
  }
}
