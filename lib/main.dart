import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pos_system/fragment/test_dual_screen/test_display.dart';
import 'package:pos_system/notifier/notification_notifier.dart';
import 'package:pos_system/notifier/report_notifier.dart';
import 'package:pos_system/notifier/table_notifier.dart';
import 'package:pos_system/object/notification.dart';
import 'package:pos_system/page/login.dart';
import 'package:pos_system/translation/AppLocalizations.dart';
import 'package:pos_system/translation/appLanguage.dart';
import 'package:presentation_displays/display.dart';
import 'package:presentation_displays/displays_manager.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'notifier/cart_notifier.dart';
import 'notifier/connectivity_change_notifier.dart';
import 'notifier/printer_notifier.dart';
import 'notifier/theme_color.dart';
import 'page/loading.dart';
import 'utils/notification_plugin.dart';

final NotificationModel notificationModel = NotificationModel();
final snackBarKey = GlobalKey<ScaffoldMessengerState>();

Route<dynamic> generateRoute(RouteSettings settings) {
  switch (settings.name) {
    case '/init':
      return MaterialPageRoute(builder: (_) => const LoginPage());
    case 'presentation':
      return MaterialPageRoute(builder: (_) => const SecondDisplayTest());
    default:
      return MaterialPageRoute(
          builder: (_) => Scaffold(
                body: Center(child: Text('No route defined for ${settings.name}')),
              ));
  }
}

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {}

Future<void> main() async {
  //firebase method
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  setupNotificationChannel();

  //device detect
  deviceDetect();
  //other method
  statusBarColor();
  WidgetsFlutterBinding.ensureInitialized();

  AppLanguage appLanguage = AppLanguage();
  //create default app color
  await appLanguage.fetchLocale();
  runApp(ChangeNotifierProvider.value(
    value: notificationModel,
    child: MyApp(appLanguage: appLanguage),
  ));
}

deviceDetect() async {
  final double screenWidth = MediaQueryData.fromWindow(WidgetsBinding.instance.window).size.width;
  if (screenWidth < 500) {
    await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]);
  } else {
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }
}

setupNotificationChannel() {
  List<CustomNotificationChannel> channels = [
    CustomNotificationChannel(
        channelId: 2, channelName: 'Order', title: 'Order', message: 'New Order Received!', description: 'New Order Received!', sound: 'notification')
  ];
  NotificationPlugin(channels);
}

bool hasNotification = false;

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
          scaffoldMessengerKey: snackBarKey,
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
                backgroundColor: Colors.white24,
                titleTextStyle: TextStyle(color: Colors.black),
                iconTheme: IconThemeData(color: Colors.orange), //
              ),
              primarySwatch: Colors.teal,
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
          routes: {'/loading': (context) => LoadingPage(), '/': (context) => LoginPage()},
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
  if (displays.length > 1) {
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
