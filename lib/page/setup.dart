import 'dart:convert';

import 'package:animations/animations.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
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
import 'device_check_dialog.dart';

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

  Future<Future<Object?>> openConfirmDialog() async {
    return showGeneralDialog(
        barrierColor: Colors.black.withOpacity(0.5),
        transitionBuilder: (context, a1, a2, widget) {
          final curvedValue = Curves.easeInOutBack.transform(a1.value) - 1.0;
          return Transform(
            transform: Matrix4.translationValues(0.0, curvedValue * 200, 0.0),
            child: Opacity(
              opacity: a1.value,
              child: DeviceCheckDialog(
                callBack: () async => await saveBranchAndDevice(),
              )
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
        transitionBuilder: (child, animation, secondaryAnimation) => SharedAxisTransition(
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
      style: TextButton.styleFrom(foregroundColor: Colors.white),
      onPressed: () {
        backToLogin();
      },
      child: Text(AppLocalizations.of(context)!.translate('back_to_login')));

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
                    style: TextButton.styleFrom(foregroundColor: Colors.white),
                    onPressed: isFirstPage ? null : () => togglePage(true),
                    child: Text(AppLocalizations.of(context)!.translate('back')),
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: color.buttonColor),
                  onPressed: () async  {
                    await checkBranchSelected();
                  },
                  child: Text(AppLocalizations.of(context)!.translate('next')),
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
            content: Text(AppLocalizations.of(context)!.translate('please_select_your_branch')),
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
            content: Text(AppLocalizations.of(context)!.translate('please_select_your_device')),
            action: SnackBarAction(
              label: 'Close',
              onPressed: () {
                // Code to execute.
              },
            ),
          ),
        );
      } else {
        //saveBranchAndDevice();
        checkDeviceLogin();
      }
    }
  }

  checkDeviceLogin() async {
    print('selected device id: ${selectedDevice!.deviceID!}');
    if(selectedDevice!.deviceID! != 4){
      Map response = await Domain().getDeviceLogin(selectedDevice!.deviceID!.toString());
      if(response['status'] == '1'){
        openConfirmDialog();
      } else if (response['status'] == '2'){
        await saveBranchAndDevice();
      }
    } else {
      await saveBranchAndDevice();
    }
  }

  saveBranchAndDevice() async {
    // Obtain shared preferences.
    if(this.token != null){
      savePref();
      await PosDatabase.instance.insertBranch(selectedBranch!);
      await updateBranchToken();
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

  savePref() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('branch_id', selectedBranch!.branchID!);
    await prefs.setInt('device_id', selectedDevice!.deviceID!);
    await prefs.setString("branch", json.encode(selectedBranch!));
  }

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
          Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (context) => LoadingPage()));
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
    return;

  }
}
