
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:pos_system/object/notification.dart';
import 'dart:io' show Platform;

import 'package:rxdart/subjects.dart';

class NotificationPlugin {
  //
  late FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin;
  final BehaviorSubject<ReceivedNotification> didReceivedLocalNotificationSubject = BehaviorSubject<ReceivedNotification>();
  var initializationSettings;

  NotificationPlugin(List<CustomNotificationChannel> notificationChannels) {
    init(notificationChannels);
  }

  init(List<CustomNotificationChannel> notificationChannels) async {
    flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
    if (Platform.isIOS) {
      _requestIOSPermission();
    }
    initializePlatformSpecifics();

    for (int i = 0; i < notificationChannels.length; i++) {
      createAndroidNotificationChannel(notificationChannels[i]);
    }
  }

  initializePlatformSpecifics() {
    var initializationSettingsAndroid = AndroidInitializationSettings('optimy');
    /*
    * ios
    * */
    var initializationSettingsIOS = IOSInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
      onDidReceiveLocalNotification: (id, title, body, payload) async {
        ReceivedNotification receivedNotification = ReceivedNotification(id: id, title: title!, body: body!, payload: payload!);
        didReceivedLocalNotificationSubject.add(receivedNotification);
      },
    );
    /*
    * initialize for both
    * */
    initializationSettings = InitializationSettings(android: initializationSettingsAndroid, iOS: initializationSettingsIOS);
  }

  _requestIOSPermission() {
    flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()!.requestPermissions(
          alert: false,
          badge: true,
          sound: true,
        );
  }

  setListenerForLowerVersions(Function onNotificationInLowerVersions) {
    didReceivedLocalNotificationSubject.listen((receivedNotification) {
      onNotificationInLowerVersions(receivedNotification);
    });
  }

  Future<void> showNotification(data) async {
    flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

    var androidChannelSpecifics = AndroidNotificationDetails(
      data['id'],
      data['name'],
      channelDescription: "CHANNEL_DESCRIPTION",
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      sound: RawResourceAndroidNotificationSound('notification'),
      icon: 'logo',
      styleInformation: DefaultStyleInformation(true, true),
    );

    var iosChannelSpecifics = IOSNotificationDetails();

    var platformChannelSpecifics = NotificationDetails(android: androidChannelSpecifics, iOS: iosChannelSpecifics);

    await flutterLocalNotificationsPlugin.show(
      0,
      data['title'],
      data['message'], //null
      platformChannelSpecifics,
      payload: data['name'],
    );
  }

  Future<void> createAndroidNotificationChannel(CustomNotificationChannel channel) async {
    print('channel id: ${channel.channelId}');
    print('channel id: ${channel.sound}');
    final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
    var androidNotificationChannel = AndroidNotificationChannel(
      channel.channelId.toString(),
      channel.channelName,
      description: channel.description,
      playSound: true,
      importance: Importance.high,
      sound: RawResourceAndroidNotificationSound(channel.sound),
    );
    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(androidNotificationChannel);
  }

  Future<int> getPendingNotificationCount() async {
    List<PendingNotificationRequest> p = await flutterLocalNotificationsPlugin.pendingNotificationRequests();
    return p.length;
  }

  Future<void> cancelNotification() async {
    await flutterLocalNotificationsPlugin.cancel(0);
  }

  Future<void> cancelAllNotification() async {
    await flutterLocalNotificationsPlugin.cancelAll();
  }
}

class ReceivedNotification {
  final int id;
  final String title;
  final String body;
  final String payload;

  ReceivedNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.payload,
  });
}
