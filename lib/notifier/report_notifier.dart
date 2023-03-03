

import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';

class ReportModel extends ChangeNotifier {
  int load = 0;
  String startDateTime = new DateFormat("yyyy-MM-dd 00:00:00").format(DateTime.now());
  String endDateTime = new DateFormat("yyyy-MM-dd 00:00:00").format(DateTime.now());
  String startDateTime2 = new DateFormat("yyyy-MM-dd").format(DateTime.now());
  String endDateTime2 = new DateFormat("yyyy-MM-dd").format(DateTime.now());

  void setDateTime (String startDateTime, String endDateTime) {
    this.startDateTime = startDateTime;
    this.endDateTime = endDateTime;
    this.startDateTime2 = startDateTime;
    this.endDateTime2 = endDateTime;
    notifyListeners();
  }

  void resetLoad(){
    load = 0;
    notifyListeners();
  }

  void setLoaded(){
    load = 1;
    notifyListeners();
  }
}