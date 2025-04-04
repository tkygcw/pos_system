import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pos_system/database/domain.dart';
import 'package:pos_system/main.dart';
import 'package:pos_system/page/pos_pin.dart';
import 'package:pos_system/page/progress_bar.dart';
import 'package:pos_system/page/setup.dart';
import 'package:pos_system/translation/AppLocalizations.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../fragment/network_dialog.dart';
import '../notifier/theme_color.dart';
import 'package:flutter_login/flutter_login.dart';

import '../second_device/server.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool toNextPage = true;
  bool isLoaded = false;
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    loginCheck();
  }

  Duration get loginTime => Duration(milliseconds: 2250);

  Future<String?> _recoverPassword(String name) {
    return Future.delayed(loginTime).then((_) async {
      Map data = await Domain().forgetPassword(name);
      if (data['status'] == '2') {
        return AppLocalizations.of(context)!.translate('user_not_found');
      }
      if (data['status'] == '3') {
        return AppLocalizations.of(context)!.translate('please_wait_for_1_minute_to_send_again');
      }
      if (data['status'] == '4') {
        return AppLocalizations.of(context)!.translate('please_try_again_later');
      }
      return null;
    });
  }

  Future<String?> _authUser(LoginData loginInfo) {
    return Future.delayed(loginTime).then((_) async {
      try{
        Map data = await Domain().userlogin(loginInfo.name, loginInfo.password);
        if (data['status'] == '2') {
          return AppLocalizations.of(context)!.translate('please_check_your_email_or_password');
        }
        if (data['status'] == '4') {
          return AppLocalizations.of(context)!.translate('please_try_again_later');
        }
        if(data['status'] == '8'){
          throw TimeoutException("Time out");
          return 'Connection timeout';
        }
        // Obtain shared preferences.
        _createDir();
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString("user", json.encode(data['user']));
        return null;
      } catch(e){
        Fluttertoast.showToast(msg: AppLocalizations.of(context)!.translate('please_try_again_later'));
        toNextPage = false;
      }
      return null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeColor>(builder: (context, ThemeColor color, child) {
      return Scaffold(
        body: isLoaded ?
        Stack(
          children: [
            Container(
              child: Theme(
                data: Theme.of(context).copyWith(
                  colorScheme: ThemeData().colorScheme.copyWith(
                    primary: Colors.black26,
                  ),
                ),
                child: Container(
                  decoration: BoxDecoration(
                    image: DecorationImage(
                      image: AssetImage("drawable/login_background.jpg"),
                      fit: BoxFit.cover,
                    ),
                  ),
                  child: FlutterLogin(
                    title: 'Optimy POS',
                    navigateBackAfterRecovery: true,
                    messages: LoginMessages(
                      recoverPasswordButton: "SEND",
                      recoverPasswordIntro: "Reset Password Send",
                      recoverPasswordDescription: "We will send an reset password link to this email.Please check your mail.",
                      recoverPasswordSuccess: 'Password reset successfully',
                    ),
                    scrollable: false,
                    logo: AssetImage("drawable/logo.png"),
                    onLogin: _authUser,
                    onSubmitAnimationCompleted: () {
                      if(toNextPage == true){
                        Navigator.of(context).pushReplacement(MaterialPageRoute(
                          builder: (context) => SetupPage(),
                        ));
                      } else {
                        Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute(builder: (context) => LoginPage()),
                              (Route route) => false,
                        );
                      }
                    },
                    theme: LoginTheme(
                        primaryColor: Colors.black26,
                        accentColor: Colors.white,
                        buttonTheme: LoginButtonTheme(backgroundColor: Colors.teal),
                        inputTheme: InputDecorationTheme(
                          filled: true,
                          fillColor: Colors.grey.shade200,
                        )),
                    onRecoverPassword: _recoverPassword,
                  ),
                ),
              ),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 16.0), // Adjust the value as needed
                child: Text(
                  appVersionCode,
                  style: TextStyle(
                    color: Colors.white54,
                  ),
                ),
              ),
            ),
          ],
        ): CustomProgressBar()
      );
    });
  }

  loginCheck() async {
    final prefs = await SharedPreferences.getInstance();
    final String? user = prefs.getString('user');
    final int? branch_id = prefs.getInt('branch_id');
    final int? device_id = prefs.getInt('device_id');
    if (user != '' && user != null && branch_id != '' && branch_id != null && device_id != '' && device_id != null) {
      Navigator.of(context).pushReplacement(MaterialPageRoute(
        builder: (context) => PosPinPage(),
      ));
      return;
    }
    Future.delayed(loginTime).then((_) async {
      bool _hasInternetAccess = await Domain().isHostReachable();
      print('host reach: ${_hasInternetAccess}');
      if(!_hasInternetAccess){
        openLogOutDialog();
        return;
      }
      if(mounted){
        Timer(Duration(seconds: 3), () {
          setState(() {
            isLoaded = true;
          });
        });
      }
    });
  }

  Future<Future<Object?>> openLogOutDialog() async {
    return showGeneralDialog(
        barrierColor: Colors.black.withOpacity(0.5),
        transitionBuilder: (context, a1, a2, widget) {
          final curvedValue = Curves.easeInOutBack.transform(a1.value) - 1.0;
          return Transform(
            transform: Matrix4.translationValues(0.0, curvedValue * 200, 0.0),
            child: Opacity(
              opacity: a1.value,
              child: NetworkDialog(
                callback: () => loginCheck(),
              ),
            ),
          );
        },
        transitionDuration: Duration(milliseconds: 200),
        barrierDismissible: false,
        context: context,
        pageBuilder: (context, animation1, animation2) {
          // ignore: null_check_always_fails
          return null!;
        });
  }

  Future<String> get _localPath async {
    final directory = await getApplicationSupportDirectory();
    return directory.path;
  }

  Future<Directory> get _localDirectory async {
    final path = await _localPath;
    return Directory('$path/assets');
  }

  _createDir() async {
    final path = await _localDirectory;
    path.create();
    _createOtherImgFolder();
    _createPaymentQrFolder();
  }

  _createPaymentQrFolder() async {
    final folderName = 'payment_qr';
    final path = await _localPath;
    final pathPaymentQr = Directory('$path/assets/$folderName');
    pathPaymentQr.create();
  }

  _createOtherImgFolder() async {
    final folderName = 'img';
    final path = await _localPath;
    final pathImg = Directory('$path/assets/$folderName');
    pathImg.create();
    downloadOtherImage(pathImg.path);
    downloadLogo(pathImg.path);
    downloadDuitNowLogo(pathImg.path);
    downloadTNGLogo(pathImg.path);
    downloadTwoSeat(pathImg.path);
    downloadFourSeat(pathImg.path);
    downloadSixSeat(pathImg.path);
  }

  downloadOtherImage(String path) async {
    final String url = '${Domain.domain}asset/output-onlinegiftools.gif';
    final response = await http.get(Uri.parse(url));
    var localPath = path + '/output-onlinegiftools.gif';
    final imageFile = File(localPath);
    await imageFile.writeAsBytes(response.bodyBytes);
  }

  downloadLogo(String path) async {
    final String url = '${Domain.domain}asset/logo1.jpg';
    final response = await http.get(Uri.parse(url));
    var localPath = path + '/logo1.jpg';
    final imageFile = File(localPath);
    await imageFile.writeAsBytes(response.bodyBytes);
  }

  downloadDuitNowLogo(String path) async {
    final String url = '${Domain.domain}asset/duitNow.jpg';
    final response = await http.get(Uri.parse(url));
    var localPath = path + '/duitNow.jpg';
    final imageFile = File(localPath);
    await imageFile.writeAsBytes(response.bodyBytes);
  }

  downloadTNGLogo(String path) async {
    final String url = '${Domain.domain}asset/TNG.jpg';
    final response = await http.get(Uri.parse(url));
    var localPath = path + '/TNG.jpg';
    final imageFile = File(localPath);
    await imageFile.writeAsBytes(response.bodyBytes);
  }

  downloadTwoSeat(String path) async {
    final String url = '${Domain.domain}asset/two-seat.jpg';
    final response = await http.get(Uri.parse(url));
    var localPath = path + '/two-seat.jpg';
    final imageFile = File(localPath);
    await imageFile.writeAsBytes(response.bodyBytes);
  }

  downloadFourSeat(String path) async {
    final String url = '${Domain.domain}asset/four-seat.jpg';
    final response = await http.get(Uri.parse(url));
    var localPath = path + '/four-seat.jpg';
    final imageFile = File(localPath);
    await imageFile.writeAsBytes(response.bodyBytes);
  }

  downloadSixSeat(String path) async {
    final String url = '${Domain.domain}asset/six-seat.jpg';
    final response = await http.get(Uri.parse(url));
    var localPath = path + '/six-seat.jpg';
    final imageFile = File(localPath);
    await imageFile.writeAsBytes(response.bodyBytes);
  }
}
