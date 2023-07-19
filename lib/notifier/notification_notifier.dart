import 'package:flutter/cupertino.dart';
import 'package:presentation_displays/display.dart';

class NotificationModel extends ChangeNotifier {
  bool stopTimer = false;
  bool notificationStatus = false;
  bool notificationStarted = false;
  bool syncCountStarted = false;
  bool contentLoad = false, contentLoaded = false;
  bool cartContentLoaded = false;
  List<Display?> displays = [];
  bool hasSecondScreen = false;
  bool secondScreenEnable = false;

  void setNotification(bool status){
    notificationStatus = status;
    notifyListeners();
    print('notification status: ${notificationStatus}');
  }

  void setTimer(bool status){
    stopTimer = status;
    notifyListeners();
    print('timer status: ${stopTimer}');
  }

  void resetTimer(){
    stopTimer = false;
  }

  void resetNotification(){
    notificationStatus = false;
    notifyListeners();
  }

  void setNotificationAsStarted(){
    notificationStarted = true;
  }

  void setSyncCountAsStarted(){
    syncCountStarted = true;
  }

  void resetSyncCount(){
    syncCountStarted = false;
  }

  void setContentLoad(){
    contentLoad = true;
  }

  void resetContentLoad(){
    contentLoad = false;
  }

  void setContentLoaded(){
    contentLoaded = true;
    notifyListeners();
  }

  void resetContentLoaded(){
    contentLoaded = false;
  }

  void setCartContentLoaded(){
    cartContentLoaded = true;
    notifyListeners();
  }

  void resetCartContentLoaded(){
    cartContentLoaded = false;
  }

  void setHasSecondScreen(){
    hasSecondScreen = true;
  }

  void insertDisplay({value}){
    displays = value;
  }

  void disableSecondDisplay(){
    secondScreenEnable = false;
  }

  void enableSecondDisplay(){
    secondScreenEnable = true;
  }
}