import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pos_system/translation/AppLocalizations.dart';
import 'package:pos_system/translation/appLanguage.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'notifier/connectivity_change_notifier.dart';
import 'notifier/theme_color.dart';
import 'page/home.dart';
import 'page/loading.dart';

Future<void> main() async {
  statusBarColor();
  WidgetsFlutterBinding.ensureInitialized();

  AppLanguage appLanguage = AppLanguage();
  await appLanguage.fetchLocale();
  runApp(MyApp(
    appLanguage: appLanguage,
  ));
}

class MyApp extends StatelessWidget {
  final AppLanguage appLanguage;

  MyApp({required this.appLanguage});

  @override
  Widget build(BuildContext context) {
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
          routes: {'/loading': (context) => LoadingPage(), '/': (context) => HomePage()},
        );
      }),
    );
  }
}

statusBarColor() {
  SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
    statusBarColor: Colors.white, // status bar color
    statusBarBrightness: Brightness.dark, //status bar brigtness
    statusBarIconBrightness: Brightness.dark,
  ));
}
