import 'dart:convert';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pos_system/database/domain.dart';
import 'package:pos_system/page/pos_pin.dart';
import 'package:pos_system/page/setup.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../notifier/theme_color.dart';
import 'package:flutter_login/flutter_login.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  @override
  void initState()  {
    // TODO: implement initState
    super.initState();
    loginCheck();

  }

  Duration get loginTime => Duration(milliseconds: 2250);

  Future<String?> _recoverPassword(String name) {
    return Future.delayed(loginTime).then((_) async {
      Map data = await Domain().forgetPassword(name);
      if (data['status'] == '2') {
        return 'User not Found.';
      }
      if (data['status'] == '3') {
        return 'Please wait for 1 minute to send again.';
      }
      if (data['status'] == '4') {
        return 'Please try again later';
      }
      return null;
    });
  }

  Future<String?> _authUser(LoginData loginInfo) {
    return Future.delayed(loginTime).then((_) async {
      Map data = await Domain().userlogin(loginInfo.name, loginInfo.password);
      if (data['status'] == '2') {
        return 'Please check your email or password.';
      }
      if (data['status'] == '4') {
        return 'Please try again later';
      }
      // Obtain shared preferences.
      _createDir();
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString("user", json.encode(data['user']));
      return null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeColor>(builder: (context, ThemeColor color, child) {
      return Scaffold(
        body: Container(
          child: Theme(
            data: Theme.of(context).copyWith(
              colorScheme: ThemeData().colorScheme.copyWith(
                    primary: color.backgroundColor,
                  ),
            ),
            child: Padding(
              padding: EdgeInsets.fromLTRB(0, 20, 0, 0),
              child: FlutterLogin(
                title: 'ChannelPOS',
                navigateBackAfterRecovery: true,
                messages: LoginMessages(
                  recoverPasswordButton: "SEND",
                  recoverPasswordIntro: "Reset Password Send",
                  recoverPasswordDescription:
                      "We will send an reset password link to this email.Please check your mail.",
                  recoverPasswordSuccess: 'Password reset successfully',
                ),
                scrollable: false,
                logo: File('data/user/0/com.example.pos_system/files/assets/img/logo1.jpg').existsSync() == false ? NetworkImage(
                    "https://channelsoft.com.my/wp-content/uploads/2020/02/logo1.jpg") : FileImage(File('data/user/0/com.example.pos_system/files/assets/img/logo1.jpg')),
                onLogin: _authUser,
                onSubmitAnimationCompleted: () {
                  Navigator.of(context).pushReplacement(MaterialPageRoute(
                    builder: (context) => SetupPage(),
                  ));
                },
                theme: LoginTheme(
                    primaryColor: color.backgroundColor,
                    accentColor: Colors.white,
                    inputTheme: InputDecorationTheme(
                      filled: true,
                      fillColor: Colors.grey.shade200,
                    )),
                onRecoverPassword: _recoverPassword,
              ),
            ),
          ),
        ),
      );
    });
  }

  loginCheck() async{
    final prefs = await SharedPreferences.getInstance();
    final String? user = prefs.getString('user');
    final int? branch_id = prefs.getInt('branch_id');
    final int? device_id = prefs.getInt('device_id');
    if(user != '' && user !=null && branch_id != '' && branch_id !=null && device_id != '' && device_id !=null ){
      Navigator.of(context).pushReplacement(MaterialPageRoute(
        builder: (context) => PosPinPage(),
      ));
    }
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
  downloadOtherImage(String path) async{
    final String url = 'https://pos.lkmng.com/asset/output-onlinegiftools.gif';
    final response = await http.get(Uri.parse(url));
    var localPath = path + '/output-onlinegiftools.gif';
    final imageFile = File(localPath);
    await imageFile.writeAsBytes(response.bodyBytes);
  }
  downloadLogo(String path) async{
    final String url = 'https://pos.lkmng.com/asset/logo1.jpg';
    final response = await http.get(Uri.parse(url));
    var localPath = path + '/logo1.jpg';
    final imageFile = File(localPath);
    await imageFile.writeAsBytes(response.bodyBytes);
  }
  downloadDuitNowLogo(String path) async {
    final String url = 'https://pos.lkmng.com/asset/duitNow.jpg';
    final response = await http.get(Uri.parse(url));
    var localPath = path + '/duitNow.jpg';
    final imageFile = File(localPath);
    await imageFile.writeAsBytes(response.bodyBytes);

  }
  downloadTNGLogo(String path) async {
    final String url = 'https://pos.lkmng.com/asset/TNG.jpg';
    final response = await http.get(Uri.parse(url));
    var localPath = path + '/TNG.jpg';
    final imageFile = File(localPath);
    await imageFile.writeAsBytes(response.bodyBytes);
  }

  downloadTwoSeat(String path) async{
    final String url = 'https://pos.lkmng.com/asset/two-seat.jpg';
    final response = await http.get(Uri.parse(url));
    var localPath = path + '/two-seat.jpg';
    final imageFile = File(localPath);
    await imageFile.writeAsBytes(response.bodyBytes);
  }

  downloadFourSeat(String path) async{
    final String url = 'https://pos.lkmng.com/asset/four-seat.jpg';
    final response = await http.get(Uri.parse(url));
    var localPath = path + '/four-seat.jpg';
    final imageFile = File(localPath);
    await imageFile.writeAsBytes(response.bodyBytes);
  }

  downloadSixSeat(String path) async{
    final String url = 'https://pos.lkmng.com/asset/six-seat.jpg';
    final response = await http.get(Uri.parse(url));
    var localPath = path + '/six-seat.jpg';
    final imageFile = File(localPath);
    await imageFile.writeAsBytes(response.bodyBytes);
  }

}
