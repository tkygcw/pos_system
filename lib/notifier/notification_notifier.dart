import 'package:flutter/cupertino.dart';

class NotificationModel extends ChangeNotifier {
  bool notificationStatus = false;

  void setNotification(bool status){
    notificationStatus = status;
    notifyListeners();
    print('notification status: ${notificationStatus}');
  }

  void resetNotifier(){
    notificationStatus = false;
    notifyListeners();
  }
}