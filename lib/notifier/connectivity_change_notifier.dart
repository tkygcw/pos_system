
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';

import '../second_device/server.dart';

class ConnectivityChangeNotifier extends ChangeNotifier {
  ConnectivityChangeNotifier() {
    Connectivity().onConnectivityChanged.listen((List<ConnectivityResult> result) async  {
      resultHandler(result[0]);
    });
  }

  ConnectivityResult _connectivityResult = ConnectivityResult.none;
  bool _connection = false;

  ConnectivityResult get connectivity => _connectivityResult;

  bool get isConnect => _connection;

  void resultHandler(ConnectivityResult result) async {
    await Server.instance.bindAllSocket();
    _connectivityResult = result;
    if (result == ConnectivityResult.none) {
      _connection = false;
    } else if (result == ConnectivityResult.mobile) {
      _connection = true;
    } else if (result == ConnectivityResult.wifi) {
      _connection = true;
    }else if (result == ConnectivityResult.ethernet) {
      _connection = true;
    }else if (result == ConnectivityResult.other) {
      _connection = true;
    }
    notifyListeners();
  }


  void initialLoad() async {
    List<ConnectivityResult> connectivityResult = await (Connectivity().checkConnectivity());
    resultHandler(connectivityResult[0]);
  }
}
