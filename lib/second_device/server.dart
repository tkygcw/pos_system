import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:pos_system/object/server_action.dart';


class Server extends ChangeNotifier {
  final NetworkInfo networkInfo = NetworkInfo();
  static const messageDelimiter = '\n';
  List<Socket> requestClient = [];
  List<Socket> clientList = [];
  ServerSocket? serverSocket;
  static String? _serverIp;
  static final Server instance = Server.init();

  Server.init();

  String? get serverIp  => _serverIp;


  Future<String?> getDeviceIp() async {
    _serverIp = await networkInfo.getWifiIP();
    return _serverIp;
  }

  closeSocket(){
    serverSocket!.close();
  }

  void addClient(Socket clientSocket){
    clientList.add(clientSocket);
    notifyListeners();
  }

  void removeClient(Socket clientSocket){
    clientList.remove(clientSocket);
    notifyListeners();
  }

  bindServer()async {
    print("server socket value: $serverSocket");
    print("server ip value: ${instance.serverIp}");
    // if(serverSocket != null){
    //   closeSocket();
    // }
    final ips = await instance.getDeviceIp();
    print("server ip running at: ${ips}");
    serverSocket = await ServerSocket.bind(ips, 9999, shared: true);
    serverSocket!.listen((currentClient) async {
      addClient(currentClient);
      //print("client length in bind: ${server.clientList.length}");
      await handleClient(currentClient, clientList);
    });
  }

  bindRequestServer()async {
    List<Socket> client2 = [];
    final ips = await instance.serverIp;
    ServerSocket serverSocket2 = await ServerSocket.bind(ips, 8888, shared: true);
    await for(Socket clientSocket in serverSocket2){
      client2.add(clientSocket);
      await handleClient2(clientSocket, client2);
    }
  }

  Future<void> handleClient(Socket clientSocket, List<Socket> clients) async {
    // clientList.add(clientSocket);
    StringBuffer buffer = StringBuffer();
    Map<String, dynamic>? response;

    clientSocket.listen((List<int> data) async {
      String receivedData = utf8.decode(data);
      buffer.write(receivedData);

      final messages = buffer.toString().split('\n');
      print("message length: ${messages.length}");
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
          for (var otherClient in clients) {
            otherClient.write("${jsonEncode(response)}\n");
          }
        }
      }
      //Update the buffer with the remaining incomplete message
      buffer.clear();
      buffer.write(messages.last);
      print("after process buffer: ${buffer.toString()}");

    },
        onDone: (){
          print('Client disconnected: ${clientSocket.remoteAddress}:${clientSocket.remotePort}');
          clientSocket.close();
          //clientList.remove(clientSocket);
          removeClient(clientSocket);
          print("on done client list: ${clientList.length}");
        });
  }

  addClientList(){

  }


  Future<void> handleClient2(Socket clientSocket, List<Socket> clients) async {
    try{
      StringBuffer buffer = StringBuffer();
      Map<String, dynamic>? response;
      String receivedData = '';

      StreamSubscription streamSubscription = clientSocket.listen((List<int> data) async {
        print("socket2 called");
        // receivedData += utf8.decode(data);
        receivedData = utf8.decode(data);
        print("received data: ${receivedData}");
        buffer.write(receivedData);

        if (buffer.toString().endsWith(messageDelimiter)) {
          final message = buffer.toString().trim();
          var msg = jsonDecode(jsonEncode(jsonDecode(message)));
          if(msg['param'] != ''){
            response = await ServerAction().checkAction(action: msg['action'], param: msg['param']);
          } else {
            response = await ServerAction().checkAction(action: msg['action']);
          }
          print("server response 2: ${response}");

          clientSocket.write("${jsonEncode(response)}\n");
          buffer.clear();
        }
      },
          onDone: (){
            print('Client disconnected 2: ${clientSocket.remoteAddress}:${clientSocket.remotePort}');
            clientSocket.flush();
            clientSocket.close();
            clients.remove(clientSocket);
          },
          onError: (error){
            print("handle client 2 error: ${error}");
            clientSocket.close();
            clients.remove(clientSocket);
          });
      await streamSubscription.asFuture();
    } catch(e){
      print("handle client 2 error: ${e}");
    }
  }

}