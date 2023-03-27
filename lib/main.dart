import 'dart:async';
import 'dart:convert';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:pos_system/fragment/test_dual_screen/test_display.dart';
import 'package:pos_system/notifier/notification_notifier.dart';
import 'package:pos_system/notifier/report_notifier.dart';
import 'package:pos_system/notifier/table_notifier.dart';
import 'package:pos_system/object/cart_product.dart';
import 'package:pos_system/object/qr_order.dart';
import 'package:pos_system/object/sync_record.dart';
import 'package:pos_system/object/sync_to_cloud.dart';
import 'package:pos_system/page/login.dart';
import 'package:pos_system/translation/AppLocalizations.dart';
import 'package:pos_system/translation/appLanguage.dart';
import 'package:presentation_displays/display.dart';
import 'package:presentation_displays/displays_manager.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'database/domain.dart';
import 'notifier/cart_notifier.dart';
import 'notifier/connectivity_change_notifier.dart';
import 'notifier/printer_notifier.dart';
import 'notifier/theme_color.dart';
import 'page/loading.dart';

Route<dynamic> generateRoute(RouteSettings settings) {
  switch (settings.name) {
    case '/init':
      return MaterialPageRoute(builder: (_) => const LoginPage());
    case 'presentation':
      return MaterialPageRoute(builder: (_) => const SecondDisplayTest());
    default:
      return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(
                child: Text('No route defined for ${settings.name}')),
          ));
  }
}

void showFlutterNotification(RemoteMessage message) {
  RemoteNotification? notification = message.notification;
  AndroidNotification? android = message.notification?.android;
  if (notification != null && android != null) {
    print('title: ${message.data['type']}');
    if(message.data['type'] == '0'){
      flutterLocalNotificationsPlugin.show(
          notification.hashCode,
          notification.title,
          notification.body,
          NotificationDetails(
            android: AndroidNotificationDetails(
              channel.id,
              channel.name,
              channelDescription: channel.description,
              color: Colors.red,
              // TODO add a proper drawable resource to android, for now using
              //      one that already exists in example app.
              icon: "@mipmap/ic_launcher",
            ),
          ));
      QrOrder().getQrOrder();
      hasNotification = true;
      notificationModel.setNotification(hasNotification);
    } else {
      hasNotification = true;
      notificationModel.setNotification(hasNotification);
      Fluttertoast.showToast(
          backgroundColor: Colors.green,
          msg:
          "Cloud db change! sync from cloud");
      print('Notification not show, but received: ${notification.title}');
      SyncRecord().syncFromCloud();
    }
  }
}

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // If you're going to use other Firebase services in the background, such as Firestore,
  // make sure you call `initializeApp` before using other Firebase services.
  await Firebase.initializeApp();
  print('Handling a background message ${message.messageId}');
  showFlutterNotification(message);
}

Future<void> onResume(RemoteMessage message) async {
  // Show a notification
  showFlutterNotification(message);
}

Future<void> main() async {
  //firebase method
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  await flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()?.createNotificationChannel(channel);

  FirebaseMessaging.onMessage.listen(showFlutterNotification);

  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    RemoteNotification? notification = message.notification;
    AndroidNotification? android = message.notification?.android;
    if (notification != null && android != null) {
      print('title: ${message.data['type']}');
      if (message.data['type'] == '0') {
        flutterLocalNotificationsPlugin.show(
            notification.hashCode,
            notification.title,
            notification.body,
            NotificationDetails(
              android: AndroidNotificationDetails(
                channel.id,
                channel.name,
                channelDescription: channel.description,
                color: Colors.red,
                // TODO add a proper drawable resource to android, for now using
                //      one that already exists in example app.
                icon: "@mipmap/ic_launcher",
              ),
            ));
        QrOrder().getQrOrder();
        hasNotification = true;
        notificationModel.setNotification(hasNotification);
      } else {
        hasNotification = true;
        Fluttertoast.showToast(
            backgroundColor: Colors.green,
            msg:
            "Cloud db change! sync from cloud");
        print('Notification not show, but received: ${notification.title}');
        SyncRecord().syncFromCloud();
      }
    }
  });

  FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
    // Resume the app and call onResume
    onResume(message);
  });


  //device detect
  final double screenWidth = MediaQueryData.fromWindow(WidgetsBinding.instance.window).size.width;
  if (screenWidth < 500) {
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown
    ]);
  } else {
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }

  //sync
  //startTimers();


  //second screen test(init second screen)
  //initSecondScreen();

  //other method
  statusBarColor();
  WidgetsFlutterBinding.ensureInitialized();

  AppLanguage appLanguage = AppLanguage();
  //create default app color
  await appLanguage.fetchLocale();
  runApp(
      ChangeNotifierProvider.value(
        value: notificationModel,
        child: MyApp(appLanguage: appLanguage),
      )
  );
}

final NotificationModel notificationModel = NotificationModel();

bool hasNotification = false;

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

//Notification importance setting
const AndroidNotificationChannel channel = AndroidNotificationChannel(
  'high_importance_channel', // id
  'High Importance Notifications', // title
  description: 'This channel is used for important notifications.', // description
  importance: Importance.max,
);

// startTimers() {
//   int timerCount = 0;
//
//   Timer.periodic(Duration(seconds: 15), (timer) async {
//     print('has notification: ${hasNotification}');
//     if(hasNotification == true){
//       print('timer reset');
//       timerCount = 0;
//     }
//     bool _hasInternetAccess = await Domain().isHostReachable();
//     if(_hasInternetAccess){
//       if (timerCount == 0) {
//         //sync to cloud
//         SyncToCloud().syncToCloud();
//       } else {
//         //sync from cloud
//         SyncRecord().syncFromCloud();
//       }
//       //add timer and reset hasNotification
//       timerCount++;
//       hasNotification = false;
//       // reset the timer after two executions
//       if (timerCount >= 2) {
//         timerCount = 0;
//       }
//     }
//   });
// }

class MyApp extends StatelessWidget {
  final AppLanguage appLanguage;

  MyApp({required this.appLanguage});

  @override
  Widget build(BuildContext context) {
    bool notification = hasNotification;
    print('notification inside build main: ${notification}');
    // Set landscape orientation
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
    ));


    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AppLanguage>(
          create: (_) => appLanguage,
        ),
        ChangeNotifierProvider(create: (_) {
          ConnectivityChangeNotifier changeNotifier = ConnectivityChangeNotifier();
          changeNotifier.initialLoad();
          return changeNotifier;
        }),
        ChangeNotifierProvider(
          create: (_) => ThemeColor(),
        ),
        ChangeNotifierProvider(
            create: (_) => CartModel(),
        ),
        ChangeNotifierProvider(
          create: (_) => PrinterModel(),
        ),
        ChangeNotifierProvider(
          create: (_) => TableModel(),
        ),
        ChangeNotifierProvider(
          create: (_) => ReportModel(),
        ),
      ],
      child: Consumer<AppLanguage>(builder: (context, model, child) {
        return MaterialApp(
          locale: model.appLocal,
          supportedLocales: [
            Locale('en', ''),
            Locale('zh', ''),
            Locale('ms', ''),
          ],
          localizationsDelegates: [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
            DefaultCupertinoLocalizations.delegate
          ],
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
              appBarTheme: AppBarTheme(
                backgroundColor: Colors.white,
                titleTextStyle: TextStyle(color: Colors.black),
                iconTheme: IconThemeData(color: Colors.orange), //
              ),
              primarySwatch: Colors.deepOrange,
              inputDecorationTheme: InputDecorationTheme(
                focusColor: Colors.black,
                labelStyle: TextStyle(
                  color: Colors.black54,
                ),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(
                    color: Colors.black26,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(
                    color: Colors.orangeAccent,
                    width: 2.0,
                  ),
                ),
              )),
          routes: {
            '/loading': (context) => LoadingPage(),
            '/': (context) => LoginPage()
          },
        );
      }),
    );
  }
}

initSecondScreen() async {
  DisplayManager displayManager = DisplayManager();
  List<Display?> displays = [];
  final values = await displayManager.getDisplays();
  displays.clear();
  displays.addAll(values!);
  if(displays.length > 1){
    await displayManager.showSecondaryDisplay(displayId: 1, routerName: "/init");
  }
  print('display list = ${displays.length}');
}

statusBarColor() {
  SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
    statusBarColor: Colors.white, // status bar color
    statusBarBrightness: Brightness.dark, //status bar brightness
    statusBarIconBrightness: Brightness.dark,
  ));
}
