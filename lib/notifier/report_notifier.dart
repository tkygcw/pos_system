


import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';

class ReportModel extends ChangeNotifier {
  int load = 0;
  String startDateTime = new DateFormat("yyyy-MM-dd 00:00:00").format(DateTime.now());
  String endDateTime = new DateFormat("yyyy-MM-dd 00:00:00").format(DateTime.now());
  String startDateTime2 = new DateFormat("dd/MM/yyyy").format(DateTime.now());
  String endDateTime2 = new DateFormat("dd/MM/yyyy").format(DateTime.now());
  List<String> reportValue = [];
  List reportValue2 = [];
  List headerValue = [];

  void initDateTime(){
    this.startDateTime = new DateFormat("yyyy-MM-dd 00:00:00").format(DateTime.now());
    this.endDateTime = new DateFormat("yyyy-MM-dd 00:00:00").format(DateTime.now());
    this.startDateTime2 = new DateFormat("dd/MM/yyyy").format(DateTime.now());
    this.endDateTime2 = new DateFormat("dd/MM/yyyy").format(DateTime.now());
    //notifyListeners();
  }

  void setDateTime (String startDateTime, String endDateTime) {
    this.startDateTime = startDateTime;
    this.endDateTime = endDateTime;
    this.startDateTime2 = startDateTime;
    this.endDateTime2 = endDateTime;
    notifyListeners();
  }

  void resetLoad(){
    print('reset loaded called');
    load = 0;
    notifyListeners();
  }

  void setLoaded(){
    print('set loaded called');
    load = 1;
    notifyListeners();
  }

  void addValue(String value1, String value2, String value3, String value4, String value5, String? value6, String value7, String value8){
    reportValue.clear();
    print('add value called');
    var _value1 = value1;
    var _value2 = value2;
    var _value3 = value3;
    var _value4 = value4;
    var _value5 = value5;
    var _value6 = value6 != 'null' ? value6 : '0';
    var _value7 = value7;
    var _value8 = value8;
    reportValue = [_value1, _value2, _value3, _value4, _value5, _value6!, _value7, _value8];
  }

  void clearValue(){
    reportValue.clear();
  }

  // void addOtherReportValue({value1, value2, value3}){
  //   var _value1 = value1;
  //   var _value2 = value2;
  //   var _value3 = value3;
  //   reportValue = [_value1, _value2, _value3];
  // }

  void addOtherValue({headerValue, valueList}){
    headerValue != null
        ?
    this.headerValue = headerValue
        :
    this.headerValue = [];
    this.reportValue2 = valueList;
  }
}