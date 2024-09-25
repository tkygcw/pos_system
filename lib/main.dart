import 'dart:async';

import 'package:async_queue/async_queue.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pos_system/notifier/app_setting_notifier.dart';
import 'package:pos_system/notifier/fail_print_notifier.dart';
import 'package:pos_system/notifier/notification_notifier.dart';
import 'package:pos_system/notifier/report_notifier.dart';
import 'package:pos_system/notifier/table_notifier.dart';
import 'package:pos_system/object/notification.dart';
import 'package:pos_system/object/qr_order.dart';
import 'package:pos_system/object/sync_record.dart';
import 'package:pos_system/object/sync_to_cloud.dart';
import 'package:pos_system/page/login.dart';
import 'package:pos_system/page/second_display.dart';
import 'package:pos_system/second_device/server.dart';
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
import 'object/lcd_display.dart';
import 'page/loading.dart';
import 'utils/notification_plugin.dart';

final NotificationModel notificationModel = NotificationModel();
final SyncToCloud mainSyncToCloud = SyncToCloud();
final SyncRecord syncRecord = SyncRecord();
final QrOrder qrOrder = QrOrder.instance;
final LCDDisplay lcdDisplay = LCDDisplay();
final asyncQ = AsyncQueue.autoStart();
DisplayManager displayManager = DisplayManager();
AppLanguage appLanguage = AppLanguage();
final snackBarKey = GlobalKey<ScaffoldMessengerState>();
bool isCartExpanded = false;

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {}

Future<void> main() async {
  //firebase method
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  setupNotificationChannel();

  //check second screen
  getSecondScreen();

  //device detect
  deviceDetect();

  //other method
  statusBarColor();

  //init lcd screen
  initLCDScreen();

  WidgetsFlutterBinding.ensureInitialized();
  //create default app color
  await appLanguage.fetchLocale();

  runApp(MyApp(
    appLanguage: appLanguage,
  ));

  // runApp(
  //     ChangeNotifierProvider.value(
  //       value: notificationModel,
  //       child: MyApp(appLanguage: appLanguage),
  //     )
  // );
}

deviceDetect() async {
  final double screenWidth = WidgetsBinding
      .instance.platformDispatcher.views.first.physicalSize.width /
      WidgetsBinding.instance.platformDispatcher.views.first.devicePixelRatio;
  // if (screenWidth < 500) {
  //   await SystemChrome.setPreferredOrientations(
  //       [DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]);
  // } else {
  //   await SystemChrome.setPreferredOrientations([
  //     DeviceOrientation.landscapeLeft,
  //     DeviceOrientation.landscapeRight,
  //   ]);
  // }
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown
  ]);
}

setupNotificationChannel() {
  List<CustomNotificationChannel> channels = [
    CustomNotificationChannel(
        channelId: 2,
        channelName: 'Order',
        title: 'Order',
        message: 'New Order Received!',
        description: 'New Order Received!',
        sound: 'notification')
  ];
  NotificationPlugin(channels);
}

class MyApp extends StatelessWidget {
  final AppLanguage appLanguage;

  MyApp({required this.appLanguage});
  static GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  @override
  Widget build(BuildContext context) {
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
          create: (_) => TableModel.instance,
        ),
        ChangeNotifierProvider(
          create: (_) => ReportModel.instance,
        ),
        ChangeNotifierProvider(
          create: (_) {
            AppSettingModel.instance.initialLoad();
            return AppSettingModel.instance;
          },
        ),
        ChangeNotifierProvider(
          create: (_) => FailPrintModel.instance,
        ),
        ChangeNotifierProvider(
          create: (_) => notificationModel,
        ),
        ChangeNotifierProvider(
          create: (_) => QrOrder.instance,
        ),
        ChangeNotifierProvider(
          create: (_) {
            return Server.instance;
          },
        ),
      ],
      child: Consumer<AppLanguage>(builder: (context, model, child) {
        return MaterialApp(
          navigatorKey: MyApp.navigatorKey,
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
            useMaterial3: false,
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
          routes: {
            '/loading': (context) => LoadingPage(selectedDays: 0,),
            '/': (context) => LoginPage(),
            'presentation': (context) => SecondDisplay(),
          },
        );
      }),
    );
  }
}

initLCDScreen() async {
  int status = await lcdDisplay.checkLcdScreen();
  if(status == 1){
    await lcdDisplay.initLcd();
  }
}

getSecondScreen() async {
  List<Display?> displays = [];
  final values = await displayManager.getDisplays();
  displays.clear();
  displays.addAll(values!);
  if (displays.length > 1) {
    notificationModel.setHasSecondScreen();
    notificationModel.insertDisplay(value: displays);
    //await displayManager.showSecondaryDisplay(displayId: 1, routerName: "/init");
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
