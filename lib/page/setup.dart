import 'dart:convert';

import 'package:animations/animations.dart';
import 'package:flutter/material.dart';
import 'package:pos_system/fragment/choose_branch.dart';
import 'package:pos_system/fragment/device_register/device_register.dart';
import 'package:pos_system/object/branch.dart';
import 'package:pos_system/page/loading.dart';
import 'package:pos_system/page/login.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../database/pos_database.dart';
import '../notifier/theme_color.dart';
import '../object/device.dart';

class SetupPage extends StatefulWidget {
  const SetupPage({Key? key}) : super(key: key);

  @override
  _SetupPageState createState() => _SetupPageState();
}

class _SetupPageState extends State<SetupPage> {
  bool isFirstPage = true;
  Branch? selectedBranch;
  Device? selectedDevice;

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeColor>(builder: (context, ThemeColor color, child) {
      return Scaffold(
        backgroundColor: color.backgroundColor,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              buildCards(),
              buildButtons(),
              backToLoginButton(),
            ],
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
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: <Widget>[
                TextButton(
                  style: TextButton.styleFrom(primary: Colors.white),
                  onPressed: isFirstPage ? null : togglePage,
                  child: Text('BACK'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(primary: color.buttonColor),
                  onPressed: checkBranchSelected,
                  child: Text('NEXT'),
                ),
              ],
            ),
          ),
        );
      });

  void togglePage() => setState(() => isFirstPage = !isFirstPage);

  backToLogin() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.clear();
    Navigator.of(context)
        .pushReplacement(MaterialPageRoute(builder: (context) => LoginPage()));
  }

  void checkBranchSelected() {
    if (isFirstPage) {
      if (selectedBranch == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.red,
            content: const Text('Please select your branch'),
            action: SnackBarAction(
              label: 'Action',
              onPressed: () {
                // Code to execute.
              },
            ),
          ),
        );
      } else {
        isFirstPage ? togglePage() : null;
      }
    } else {
      if (selectedDevice == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.red,
            content: const Text('Please select your device'),
            action: SnackBarAction(
              label: 'Action',
              onPressed: () {
                // Code to execute.
              },
            ),
          ),
        );
      } else {
        saveBranchAndDevice();
        Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => LoadingPage()));
      }
    }
  }

  saveBranchAndDevice() async {
    // Obtain shared preferences.
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('branch_id', selectedBranch!.branchID!);
    await prefs.setInt('device_id', selectedDevice!.deviceID!);
    await prefs.setString("branch", json.encode(selectedBranch!));
    await PosDatabase.instance.insertBranch(selectedBranch!);


  }
}
