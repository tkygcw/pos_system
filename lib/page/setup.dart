import 'dart:convert';
import 'dart:io';

import 'package:animations/animations.dart';
import 'package:f_logs/model/flog/flog.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pos_system/fragment/choose_branch.dart';
import 'package:pos_system/fragment/device_register/device_register.dart';
import 'package:pos_system/object/branch.dart';
import 'package:pos_system/page/loading.dart';
import 'package:pos_system/page/login.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
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
  final adminPosPinController = TextEditingController();
  bool inProgress = false;
  bool isButtonDisabled = false;
  bool _submitted = false;
  int selectedDays = 0;

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
      bool _hasInternetAccess = await Domain().isHostReachable();
      if(_hasInternetAccess == false){
        throw SocketException("Connection failed");
      }
      token = await FirebaseMessaging.instance.getToken();
      print('token: ${token}');
      //token = 'testing';
    }on SocketException catch(_){
      backToLogin();
    } catch(e){
      print("get token error: ${e}");
    }
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
    PosDatabase.instance.clearAllBranch();
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
      await downloadBranchLogo(imageName: selectedBranch!.logo!);
      await updateBranchToken();
    } else {
      savePref();
      await PosDatabase.instance.insertBranch(selectedBranch!);
      await downloadBranchLogo(imageName: selectedBranch!.logo!);
      // Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (context) => LoadingPage()));
      showDaysSelectionDialog(context);
    }
  }

  downloadBranchLogo({required String imageName}) async {
    try{
      final prefs = await SharedPreferences.getInstance();
      final String? user = prefs.getString('user');
      Map userObject = json.decode(user!);

      final directory = await _localPath;
      final path = '$directory/assets/logo';
      final pathImg = Directory(path);
      await prefs.setString('logo_path', path);

      if (!(await pathImg.exists())) {
        await pathImg.create(recursive: true);
      }

      String url = '${Domain.backend_domain}api/logo/' + userObject['company_id'] + '/' + imageName;
      final response = await http.get(Uri.parse(url));
      var localPath = path + '/' + imageName;
      final imageFile = File(localPath);
      await imageFile.writeAsBytes(response.bodyBytes);
        }catch(e){
      print("download branch logo error: $e");
    }
  }

  Future<String> get _localPath async {
    final directory = await getApplicationSupportDirectory();
    return directory.path;
  }

  savePref() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('branch_id', selectedBranch!.branchID!);
    await prefs.setInt('device_id', selectedDevice!.deviceID!);
    await prefs.setString("branch", json.encode(selectedBranch!));
    String userEmail = jsonDecode(prefs.getString('user') ?? '')['email'] ?? '';
    FLog.info(
      className: "setup",
      text: "Account logged in",
      exception: "Email: ${userEmail}\nBranch: ${selectedBranch!.name}\nDevice: ${selectedDevice!.name}",
    );
  }

  updateBranchToken() async {
    try{
      print("update branch token called");
      await PosDatabase.instance.updateBranchNotificationToken(Branch(
          notification_token: this.token,
          branchID: selectedBranch!.branchID
      ));
/*
      ------------------------sync to cloud--------------------------------
*/
      bool _hasInternetAccess = await Domain().isHostReachable();
      if(_hasInternetAccess){
        Map response = await Domain().updateBranchNotificationToken(this.token, selectedBranch!.branchID);
        if (response['status'] == '1') {
          showDaysSelectionDialog(context);
          // Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (context) => LoadingPage()));
        } else {
          Fluttertoast.showToast(
              msg: '${AppLocalizations.of(context)?.translate('fail_get_token')}');
          backToLogin();
        }
      } else {
        Fluttertoast.showToast(msg: '${AppLocalizations.of(context)?.translate('fail_get_token')}');
        backToLogin();
      }
    }catch(e){
      FLog.error(
        className: "setup",
        text: "update branch token error",
        exception: "$e",
      );
      Fluttertoast.showToast(msg: '${AppLocalizations.of(context)?.translate('fail_get_token')}');
      backToLogin();
    }
  }

  showDaysSelectionDialog(BuildContext context) async {
    await showDialog<int>(
      barrierDismissible: false,
      context: context,
      builder: (BuildContext context) {
        int tempSelectedDays = selectedDays;

        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return AlertDialog(
              title: Text('${AppLocalizations.of(context)?.translate('download_order_data_from_cloud')}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
              content: Container(
                width: 400,
                padding: EdgeInsets.all(10.0),
                child: DropdownButton<int>(
                  value: tempSelectedDays,
                  onChanged: (int? newValue) {
                    setState(() {
                      tempSelectedDays = newValue!;
                    });
                  },
                  items: [
                    DropdownMenuItem<int>(
                      value: 0,
                      child: Text('${AppLocalizations.of(context)?.translate('do_not_download_order_data')}'),
                    ),
                    DropdownMenuItem<int>(
                      value: 1,
                      child: Text('1 ${AppLocalizations.of(context)?.translate('days')}'),
                    ),
                    DropdownMenuItem<int>(
                      value: 3,
                      child: Text('3 ${AppLocalizations.of(context)?.translate('days')}'),
                    ),
                    DropdownMenuItem<int>(
                      value: 7,
                      child: Text('7 ${AppLocalizations.of(context)?.translate('days')}'),
                    ),
                    DropdownMenuItem<int>(
                      value: -1,
                      child: Text('Debug'),
                    ),
                  ],
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 16,
                  ),
                  dropdownColor: Colors.white,
                  isExpanded: true,
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    backToLogin();
                  },
                  child: Text('${AppLocalizations.of(context)?.translate('back_to_login')}')
                ),
                SizedBox(width: 10),
                TextButton(
                  onPressed: () {
                    selectedDays = tempSelectedDays;
                    if(selectedDays == -1) {
                      showSecondDialog(context);
                    } else {
                      Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (context) => LoadingPage(selectedDays: selectedDays)));
                    }
                  },
                  child: Text('${AppLocalizations.of(context)?.translate('yes')}')
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future showSecondDialog(BuildContext context) async {
    String? pin;
    await showDialog(
      barrierDismissible: false,
      context: context,
      builder: (BuildContext context) {
        return Consumer<ThemeColor>(
          builder: (context, ThemeColor color, child) {
            return AlertDialog(
              title: Text(AppLocalizations.of(context)!.translate('enter_debug_pin')),
              content: TextField(
                autofocus: true,
                obscureText: true,
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderSide: BorderSide(color: color.backgroundColor),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: color.backgroundColor),
                  ),
                  labelText: "PIN",
                ),
                onChanged: (value) {
                  pin = value;
                },
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: Text(AppLocalizations.of(context)!.translate('close')),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop(pin);
                  },
                  child: Text(AppLocalizations.of(context)!.translate('yes')),
                ),
              ],
            );
          },
        );
      },
    );

    if (pin != null) {
      await readAdminData(pin!);
    }
  }

  readAdminData(String pin) async {
    final prefs = await SharedPreferences.getInstance();
    final String? branchId = prefs.getInt('branch_id')?.toString();

    if (branchId != null) {
      if (pin == branchId.padLeft(6, '0')) {
        Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (context) => LoadingPage(selectedDays: selectedDays)));
      } else {
        Fluttertoast.showToast(backgroundColor: Color(0xFFFF0000), msg: "${AppLocalizations.of(context)?.translate('wrong_pin_please_insert_valid_pin')}");
      }
    } else {
      Fluttertoast.showToast(backgroundColor: Color(0xFFFF0000), msg: "${AppLocalizations.of(context)?.translate('something_went_wrong_please_try_again_later')}");
    }
  }

}