import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';

class ConnectivityChangeNotifier extends ChangeNotifier {
  ConnectivityChangeNotifier() {
    Connectivity().onConnectivityChanged.listen((ConnectivityResult result) {
      resultHandler(result);
    });
  }

  ConnectivityResult _connectivityResult = ConnectivityResult.none;
  bool _connection = false;

  ConnectivityResult get connectivity => _connectivityResult;

  bool get isConnect => _connection;

  void resultHandler(ConnectivityResult result) {
    _connectivityResult = result;
    if (result == ConnectivityResult.none) {
      _connection = false;
    } else if (result == ConnectivityResult.mobile) {
      _connection = true;
    } else if (result == ConnectivityResult.wifi) {
      _connection = true;
    }
    notifyListeners();
  }

  void initialLoad() async {
    ConnectivityResult connectivityResult = await (Connectivity().checkConnectivity());
    resultHandler(connectivityResult);
  }
}
