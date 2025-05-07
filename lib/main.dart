import 'dart:async';
import 'dart:io';
import 'dart:ui';

import 'package:async_queue/async_queue.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:desktop_multi_window/desktop_multi_window.dart';
import 'package:f_logs/model/flog/flog.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:media_kit/media_kit.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:pos_system/database/pos_database.dart';
import 'package:pos_system/database/pos_firestore.dart';
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
import 'package:pos_system/windows_app/customer_display.dart';
import 'package:presentation_displays/display.dart';
import 'package:presentation_displays/displays_manager.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:screen_retriever/screen_retriever.dart' as Retriever;
import 'package:toastification/toastification.dart';
import 'package:window_manager/window_manager.dart';
import 'notifier/cart_notifier.dart';
import 'notifier/connectivity_change_notifier.dart';
import 'notifier/printer_notifier.dart';
import 'notifier/theme_color.dart';
import 'object/imin_lib.dart';
import 'page/loading.dart';
import 'utils/notification_plugin.dart';

final NotificationModel notificationModel = NotificationModel();
final SyncToCloud mainSyncToCloud = SyncToCloud();
final SyncRecord syncRecord = SyncRecord();
final QrOrder qrOrder = QrOrder.instance;
final IminLib iminLib = IminLib();
final asyncQ = AsyncQueue.autoStart();
DisplayManager displayManager = DisplayManager();
AppLanguage appLanguage = AppLanguage();
final snackBarKey = GlobalKey<ScaffoldMessengerState>();
bool isCartExpanded = false;
bool isPaused = false;
String appVersionCode = '', patch = '1';
ValueNotifier<int> unsyncedDataNotifier = ValueNotifier<int>(0);
final ValueNotifier<bool> isSyncisSyncingingNotifier = ValueNotifier<bool>(false);
String currency_code = 'MYR';
String currency_symbol = 'RM';

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {}

Future<void> main(List<String> args) async {
  WidgetsFlutterBinding.ensureInitialized();

  // Necessary initialization for package:media_kit.
  MediaKit.ensureInitialized();

  //check second screen
  await getSecondScreen();

  //device detect
  deviceDetect();

  //other method
  statusBarColor();

  //init lcd screen (if is not win devices)
  initLCDScreen();

  //get app version
  await getAppVersion();

  await calUnsyncedData();

  //create default app color
  await appLanguage.fetchLocale();

  if(Platform.isWindows){
    //windows manager initialized
    await windowManager.ensureInitialized();

    windowManager.waitUntilReadyToShow(null, () async {
      await windowManager.show();
      await windowManager.focus();
      await windowManager.setFullScreen(true);
    });
  }

  if (args.isNotEmpty) {
    runApp(WinCustomerDisplay(appLanguage: appLanguage,));
    windowManager.waitUntilReadyToShow(null, () async {
      await windowManager.show();
      await windowManager.setFullScreen(true);
    });
  } else {
    //firebase method
    await Firebase.initializeApp(
      options: Platform.isWindows ? FirebaseOptions(
          apiKey: 'AIzaSyCw5m1txfmZIHhrjc5gnQmElcjh2IfkZWA',
          appId: '1:837940125447:web:90e55e25e0d6b1a63aafa2',
          messagingSenderId: '837940125447',
          projectId: 'test-13a67') : null
    );
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    setupNotificationChannel();
    configFirestore();
    runApp(MyApp(
      appLanguage: appLanguage,
    ));
    if(Platform.isWindows){
      //open a new windows for customer display
      await createNewWindows();
    }
  }
}

Future<void> createNewWindows() async {
  try{
    Offset screenPosition;
    // Retrieve all available screens
    final screens = await Retriever.screenRetriever.getAllDisplays();
    if (screens.length > 1) {
      notificationModel.setHasSecondScreen();
      //internal will always be the first
      final internalScreen = screens.first;
      //primary screen is the screen set as main display in windows setting
      final primaryScreens = await Retriever.screenRetriever.getPrimaryDisplay();
      //move customer display to non-main display screen
      if(primaryScreens.id == internalScreen.id){
        screenPosition = screens[1].visiblePosition!;
      } else {
        screenPosition = internalScreen.visiblePosition!;
      }
      //call create windows
      final window = await DesktopMultiWindow.createWindow();
      // Set the window's initial position to the external display
      await window
        ..setFrame(screenPosition & Size(1280, 720))
        ..center()
        ..show();
    }
  }catch(e, s){
    FLog.error(
      className: "main",
      text: "createNewWindows failed",
      exception: "Error: $e, StackTrace: $s",
    );
  }
}

Future<void> calUnsyncedData() async {
  int unsyncedData = int.parse(await PosDatabase.instance.getUnsyncedData());
  unsyncedDataNotifier.value = unsyncedData;
}

deviceDetect() async {
  if(Platform.isWindows){
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
}

configFirestore(){
  PosFirestore.instance.firestore.settings = const Settings(
    persistenceEnabled: true,
    cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
  );
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

initLCDScreen() async {
  if(!Platform.isWindows){
    int status = await iminLib.checkLcdScreen();
    if(status == 1){
      await iminLib.initLcd();
    }
  }
}

getSecondScreen() async {
  if(!Platform.isWindows){
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
}

statusBarColor() {
  SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
    statusBarColor: Colors.white, // status bar color
    statusBarBrightness: Brightness.dark, //status bar brightness
    statusBarIconBrightness: Brightness.dark,
  ));
}

getAppVersion() async {
  PackageInfo packageInfo = await PackageInfo.fromPlatform();
  appVersionCode = '${packageInfo.version}${patch != '' ? '+$patch' : ''}';
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
        return ToastificationWrapper(
          child: MaterialApp(
            scrollBehavior: CustomScrollBehavior(),
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
          ),
        );
      }),
    );
  }
}


class CustomScrollBehavior extends MaterialScrollBehavior {
  // Override behavior methods and getters like dragDevices
  @override
  Set<PointerDeviceKind> get dragDevices => {
    PointerDeviceKind.touch,
    PointerDeviceKind.mouse,
    PointerDeviceKind.trackpad,
    PointerDeviceKind.stylus,
    PointerDeviceKind.invertedStylus
  };
}
