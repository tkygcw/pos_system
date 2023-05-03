import 'package:flutter/cupertino.dart';

class NotificationModel extends ChangeNotifier {
  bool stopTimer = false;
  bool notificationStatus = false;
  bool notificationStarted = false;
  bool syncCountStarted = false;
  bool contentLoaded = false;

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

  void setContentLoaded(){
    contentLoaded = true;
  }

  void resetContentLoaded(){
    contentLoaded = false;
  }
}