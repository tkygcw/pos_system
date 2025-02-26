
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:pos_system/page/second_display.dart';
import 'package:provider/provider.dart';

import '../translation/AppLocalizations.dart';
import '../translation/appLanguage.dart';

class WinCustomerDisplay extends StatelessWidget {
  final AppLanguage appLanguage;
  const WinCustomerDisplay({Key? key, required this.appLanguage}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AppLanguage>(
          create: (_) => appLanguage,
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
                useMaterial3: false,
                appBarTheme: AppBarTheme(
                  backgroundColor: Colors.white24,
                  titleTextStyle: TextStyle(color: Colors.black),
                  iconTheme: IconThemeData(color: Colors.teal), //
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
                      color: Colors.teal,
                      width: 2.0,
                    ),
                  ),
                )),
            home: SecondDisplay()
        );
      }),
    );
  }
}

