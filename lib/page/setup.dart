import 'dart:convert';

import 'package:animations/animations.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';
import 'package:pos_system/fragment/choose_branch.dart';
import 'package:pos_system/fragment/device_register/device_register.dart';
import 'package:pos_system/object/branch.dart';
import 'package:pos_system/page/loading.dart';
import 'package:pos_system/page/login.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../database/domain.dart';
import '../database/pos_database.dart';
import '../notifier/theme_color.dart';
import '../object/device.dart';
import '../translation/AppLocalizations.dart';

class SetupPage extends StatefulWidget {
  const SetupPage({Key? key}) : super(key: key);

  @override
  _SetupPageState createState() => _SetupPageState();
}

class _SetupPageState extends State<SetupPage> {
  bool isFirstPage = true;
  Branch? selectedBranch;
  Device? selectedDevice;
  String? token;

  @override
  void initState() {
    super.initState();
    getToken();
  }

  getToken() async {
    try{
      token = await FirebaseMessaging.instance.getToken();
      print('token: ${token}');
      //token = 'testing';
    }catch(e){
      Navigator.of(context).pushAndRemoveUntil(
        // the new route
        MaterialPageRoute(
          builder: (BuildContext context) => LoginPage(),
        ),

        // this function should return true when we're done removing routes
        // but because we want to remove all other screens, we make it
        // always return false
            (Route route) => false,
      );
    }
    return;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeColor>(builder: (context, ThemeColor color, child) {
      return Scaffold(
        backgroundColor: color.backgroundColor,
        body: Container(
          decoration: BoxDecoration(
            image: DecorationImage(
              image: AssetImage("drawable/login_background.jpg"),
              fit: BoxFit.cover,
            ),
          ),
          child: Container(
            color: Colors.black26,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  buildCards(),
                  Container(
                    child: buildButtons(),
                  ),
                  backToLoginButton(),
                ],
              ),
            ),
          ),
        ),
      );
    });
  }

  Widget buildCards() => PageTransitionSwitcher(
        duration: Duration(milliseconds: 200),
        reverse: isFirstPage,
        transitionBuilder: (child, animation, secondaryAnimation) =>
            SharedAxisTransition(
          fillColor: Colors.transparent,
          child: child,
          animation: animation,
          secondaryAnimation: secondaryAnimation,
          transitionType: SharedAxisTransitionType.horizontal,
        ),
        child: isFirstPage
            ? ChooseBranch(
                preSelectBranch: selectedBranch,
                callBack: (value) {
                  selectedBranch = value;
                },
              )
            : DeviceRegister(
                selectedBranch: selectedBranch,
                callBack: (value) {
                  selectedDevice = value;
                },
              ),
      );

  Widget backToLoginButton() => TextButton(
      style: TextButton.styleFrom(primary: Colors.white),
      onPressed: () {
        backToLogin();
      },
      child: Text('Back to login'));

  Widget buildButtons() =>
      Consumer<ThemeColor>(builder: (context, ThemeColor color, child) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 15),
          child: Center(
            child: Row(
              mainAxisAlignment: isFirstPage && MediaQuery.of(context).size.width < 500 ? MainAxisAlignment.center : MainAxisAlignment.spaceEvenly,
              children: <Widget>[
                Visibility(
                  visible: isFirstPage ? false : true,
                  child: TextButton(
                    style: TextButton.styleFrom(primary: Colors.white),
                    onPressed: isFirstPage ? null : () => togglePage(true),
                    child: Text('BACK'),
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(primary: color.buttonColor),
                  onPressed: () async  {
                    await checkBranchSelected();
                  },
                  child: Text('NEXT'),
                ),
              ],
            ),
          ),
        );
      });

  void togglePage(bool status) {

    setState(() {
      isFirstPage = status;
      if(isFirstPage){
       this.selectedBranch = null;
       this.selectedDevice = null;
      }
    });
  }

  backToLogin() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.clear();
    Navigator.of(context)
        .pushReplacement(MaterialPageRoute(builder: (context) => LoginPage()));
  }

  checkBranchSelected() async {
    if (isFirstPage) {
      if (selectedBranch == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.red,
            content: const Text('Please select your branch'),
            action: SnackBarAction(
              label: 'Close',
              onPressed: () {
                // Code to execute.
              },
            ),
          ),
        );
      } else {
        isFirstPage ? togglePage(false) : null;
      }
    } else {
      if (selectedDevice == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.red,
            content: const Text('Please select your device'),
            action: SnackBarAction(
              label: 'Close',
              onPressed: () {
                // Code to execute.
              },
            ),
          ),
        );
      } else {
        saveBranchAndDevice();
      }
    }
  }


  saveBranchAndDevice() async {
    // Obtain shared preferences.
    final prefs = await SharedPreferences.getInstance();
    if(this.token != null){
      await prefs.setInt('branch_id', selectedBranch!.branchID!);
      await prefs.setInt('device_id', selectedDevice!.deviceID!);
      await prefs.setString("branch", json.encode(selectedBranch!));
      await PosDatabase.instance.insertBranch(selectedBranch!);
      await updateBranchToken();
      //await createDeviceLogin();
    } else {
      Fluttertoast.showToast(msg: '${AppLocalizations.of(context)?.translate('fail_get_token')}');
      Navigator.of(context).pushAndRemoveUntil(
        // the new route
        MaterialPageRoute(
          builder: (BuildContext context) => LoginPage(),
        ),

        // this function should return true when we're done removing routes
        // but because we want to remove all other screens, we make it
        // always return false
            (Route route) => false,
      );
    }

  }

// /*
//   create device login
// */
//   createDeviceLogin() async {
//     DateFormat dateFormat = DateFormat("yyyy-MM-dd HH:mm:ss");
//     String dateTime = dateFormat.format(DateTime.now());
//     final prefs = await SharedPreferences.getInstance();
//     final int? device_id = prefs.getInt('device_id');
//
//     var value = md5.convert(utf8.encode(dateTime)).toString();
//
//     bool _hasInternetAccess = await Domain().isHostReachable();
//     if(_hasInternetAccess){
//       Map response = await Domain().insertDeviceLogin(device_id.toString(), value);
//       if(response['status'] == '1'){
//         await prefs.setString('login_value', value);
//       } else {
//         Navigator.of(context).pushReplacement(MaterialPageRoute(
//           builder: (context) => LoginPage(),
//         ));
//       }
//     } else {
//       Navigator.of(context).pushReplacement(MaterialPageRoute(
//         builder: (context) => LoginPage(),
//       ));
//     }
//   }

  updateBranchToken() async {
    try{
      var connectivityResult = await (Connectivity().checkConnectivity());
      await PosDatabase.instance.updateBranchNotificationToken(Branch(
          notification_token: this.token,
          branchID: selectedBranch!.branchID
      ));
/*
      ------------------------sync to cloud--------------------------------
*/
      if (connectivityResult == ConnectivityResult.mobile || connectivityResult == ConnectivityResult.wifi) {
        Map response = await Domain().updateBranchNotificationToken(this.token, selectedBranch!.branchID);
        if (response['status'] == '1') {
          Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (context) => LoadingPage()));
        } else {
          Fluttertoast.showToast(msg: '${AppLocalizations.of(context)?.translate('fail_get_token')}');
          Navigator.of(context).pushAndRemoveUntil(
            // the new route
            MaterialPageRoute(
              builder: (BuildContext context) => LoginPage(),
            ),

            // this function should return true when we're done removing routes
            // but because we want to remove all other screens, we make it
            // always return false
                (Route route) => false,
          );
        }
      }
    }catch(e){
      print('update token error: ${e}');
      Fluttertoast.showToast(msg: '${AppLocalizations.of(context)?.translate('fail_get_token')}');
      Navigator.of(context).pushAndRemoveUntil(
        // the new route
        MaterialPageRoute(
          builder: (BuildContext context) => LoginPage(),
        ),

        // this function should return true when we're done removing routes
        // but because we want to remove all other screens, we make it
        // always return false
            (Route route) => false,
      );
    }

  }
}
