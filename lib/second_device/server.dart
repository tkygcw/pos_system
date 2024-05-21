import 'dart:async';
import 'dart:convert';
import 'dart:io';

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
  ServerSocket? serverSocket;
  static String _serverIp = '-';
  static final Server instance = Server.init();

  Server.init();

  String? get serverIp  => _serverIp;


  Future<String?> getDeviceIp() async {
    var wifiIP = await networkInfo.getWifiIP();
    if(wifiIP == null) {
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

  bindAllSocket() async {
    final prefs = await SharedPreferences.getInstance();
    final String? branch = prefs.getString('branch');
    Map branchObject = json.decode(branch!);
    print("sub pos status: ${branchObject['sub_pos_status']}");
    if(branchObject['sub_pos_status'] == 0){
      await bindServer();
      await bindRequestServer();
    } else if (branchObject['sub_pos_status'] == null){
      //update share pref
      Branch? branch = await PosDatabase.instance.readSpecificBranch(branchObject['branchID']);
      await prefs.setString('branch', json.encode(branch!));
    }
  }

  void closeSocket(){
    serverSocket!.close();
  }

  void addClient(Socket clientSocket){
    if(clientList.any((e) => e.remoteAddress.address == clientSocket.remoteAddress.address)){
      return;
    } else {
      clientList.add(clientSocket);
      notifyListeners();
    }
    // clientList.add(clientSocket);
  }

  void removeClient(Socket clientSocket){
    clientList.remove(clientSocket);
    notifyListeners();
  }

  bindServer()async {
    print("server socket value: $serverSocket");
    print("server ip value: ${instance.serverIp}");
    final ips = await instance.getDeviceIp();
    print("server ip running at: ${ips}");
    if(ips != null){
      try{
        serverSocket = await ServerSocket.bind(ips, 9999, shared: true);
      }catch(e){
        print("bind server error: ${e}");
        _serverIp = "-";
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
    // clientList.add(clientSocket);
    StringBuffer buffer = StringBuffer();
    Map<String, dynamic>? response;

    clientSocket.listen((List<int> data) async {
      String receivedData = utf8.decode(data);
      buffer.write(receivedData);

      List<String> messageList = buffer.toString().split(messageDelimiter);
      print("message length: ${messageList.length}");
      List<String> messages = messageList.where((e) => e != messageDelimiter).toList();
      for(int i = 0; i < messages.length; i++){
        //print("message: ${messages[i]}");
        final message = messages[i];
        if(message.isNotEmpty){
          //process the request
          var msg = jsonDecode(message);
          if(msg['param'] != ''){
            response = await ServerAction().checkAction(action: msg['action'], param: msg['param']);
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
      onDone: (){
        //print('Client disconnected: ${clientSocket.remoteAddress}:${clientSocket.remotePort}');
        removeClient(clientSocket);
        clientSocket.close();
        //clientList.remove(clientSocket);
        print("on done client list: ${clientList.length}");
      },
      onError: (error){
        print("server handle client error: ${error}");
        removeClient(clientSocket);
        clientSocket.destroy();
      },
    );
  }

  sendRefreshMessage(){
    for (var otherClient in clientList) {
      otherClient.write("refresh");
    }
  }

  bindRequestServer()async {
    List<Socket> client2 = [];
    ServerSocket serverSocket2;
    final ips = await instance.serverIp;
    if(ips != null && ips != '-'){
      try{
        serverSocket2 = await ServerSocket.bind(ips, 8888, shared: true);
      }catch(e){
        print("bind request server error: ${e}");
        return;
      }
      serverSocket2.listen((clientSocket) async  {
        client2.add(clientSocket);
        await handleClient2(clientSocket, client2);
      });
    }
  }

  Future<void> handleClient2(Socket clientSocket, List<Socket> clients) async {
    StringBuffer buffer = StringBuffer();
    Map<String, dynamic>? response;
    String receivedData = '';
    StreamSubscription streamSubscription = clientSocket.listen((List<int> data) async {
      asyncQ.addJob((_) async {
        try{
          print("socket2 called");
          // receivedData += utf8.decode(data);
          receivedData = utf8.decode(data);
          print("received data: ${receivedData}");
          buffer.write(receivedData);

          if (buffer.toString().endsWith(messageDelimiter)) {
            final message = buffer.toString().trim();
            var msg = jsonDecode(jsonEncode(jsonDecode(message)));
            if(msg['param'] != ''){
              response = await ServerAction().checkAction(action: msg['action'], param: msg['param'], address: clientSocket.remoteAddress.address);
            } else {
              response = await ServerAction().checkAction(action: msg['action'], address: clientSocket.remoteAddress.address);
            }
            print("server response 2: ${response}");

            clientSocket.write("${jsonEncode(response)}$messageDelimiter");
            buffer.clear();
          }
        }catch(e){
          print("handle client 2 error: ${e}");
        }
        print("handle client queue done!!!");
      });
    },cancelOnError: true,
        onDone: (){
          //print('Client disconnected 2: ${clientSocket.remoteAddress}:${clientSocket.remotePort}');
          // clientSocket.flush();
          print("client done called!!!");
          clientSocket.close();
          clients.remove(clientSocket);
        },
        onError: (error){
          print("handle client 2 error: ${error}");
          clientSocket.close();
          clients.remove(clientSocket);
        });
    // try{
    //
    //   // await streamSubscription.asFuture();
    // } catch(e){
    //   print("handle client 2 error: ${e}");
    // }
  }

}