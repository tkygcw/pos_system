import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_usb_printer/flutter_usb_printer.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:gms_check/gms_check.dart';
import 'package:intl/intl.dart';
import 'package:page_transition/page_transition.dart';
import 'package:pos_system/fragment/setting/sync_dialog.dart';
import 'package:pos_system/fragment/subscription_expired.dart';
import 'package:pos_system/fragment/update_dialog.dart';
import 'package:pos_system/main.dart';
import 'package:pos_system/object/current_version.dart';
import 'package:pos_system/object/subscription.dart';
import 'package:pos_system/object/transfer_owner.dart';
import 'package:pos_system/page/home.dart';
import 'package:pos_system/translation/AppLocalizations.dart';
import 'package:print_bluetooth_thermal/print_bluetooth_thermal.dart';
import 'package:provider/provider.dart';
import 'package:custom_pin_screen/custom_pin_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:crypto/crypto.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:store_checker/store_checker.dart';
import 'package:version/version.dart';
import '../database/domain.dart';
import '../database/pos_database.dart';
import '../fragment/logout_dialog.dart';
import '../fragment/setting/printer_dialog.dart';
import '../notifier/theme_color.dart';
import '../object/cash_record.dart';
import '../fragment/printing_layout/print_receipt.dart';
import '../object/printer.dart';
import '../object/user.dart';
import '../second_device/server.dart';
import '../utils/Utils.dart';

class PosPinPage extends StatefulWidget {
  final String? cashBalance;

  const PosPinPage({Key? key, this.cashBalance}) : super(key: key);

  @override
  _PosPinPageState createState() => _PosPinPageState();
}

class _PosPinPageState extends State<PosPinPage> {
  FlutterUsbPrinter flutterUsbPrinter = FlutterUsbPrinter();
  PrintReceipt printReceipt = PrintReceipt();
  List response = [];
  List subscription = [];
  List<Printer> printerList = [];
  String latestVersion = '';
  String? userValue, transferOwnerValue;
  bool isLogOut = false;
  String source = '';

  @override
  void initState() {
    super.initState();
    //readAllPrinters();
    setScreenLayout();
    preload();
    bindSocket();
    checkVersion();
    checkSubscription();
  }

  @override
  dispose() {
    super.dispose();
  }

  setScreenLayout() async {
    final prefs = await SharedPreferences.getInstance();
    final int? orientation = prefs.getInt('orientation');
    if(orientation == null || orientation == 0) {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeRight,
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
      ]);
    } else {
      if (orientation == 1) {
        SystemChrome.setPreferredOrientations([
          DeviceOrientation.landscapeLeft,
          DeviceOrientation.landscapeRight
        ]);
      } else {
        SystemChrome.setPreferredOrientations([
          DeviceOrientation.portraitUp,
          DeviceOrientation.portraitDown
        ]);
      }
    }
  }

  preload() async {
    syncRecord.syncFromCloud();
    if(notificationModel.syncCountStarted == false){
      startTimers();
    }
    await readAllPrinters();
  }

/*
  bind server socket
*/
  bindSocket() async {
    try{
      await Server.instance.bindAllSocket();
    }catch(e){
      print("init bind error: ${e}");
    }
  }

  getLatestVersion() async {
    if(defaultTargetPlatform == TargetPlatform.android){
      Map data =  await Domain().getAppVersion('0');
      if(data['status'] == '1'){
        response = data['app_version'];
        latestVersion = response[0]['version'];
      }
    } else if(defaultTargetPlatform == TargetPlatform.iOS) {
      Map data =  await Domain().getAppVersion('1');
      if(data['status'] == '1'){
        response = data['app_version'];
        latestVersion = response[0]['version'];
      }
    }
  }

  getSource() async {
    Source installationSource;
    try {
      installationSource = await StoreChecker.getSource;
    } on PlatformException {
      installationSource = Source.UNKNOWN;
    }

    switch (installationSource) {
      case Source.IS_INSTALLED_FROM_PLAY_STORE:
      // Installed from Play Store
        source = "Play Store";
        break;
      case Source.IS_INSTALLED_FROM_PLAY_PACKAGE_INSTALLER:
      // Installed from Google Package installer
        source = "Google Package installer";
        break;
      case Source.IS_INSTALLED_FROM_LOCAL_SOURCE:
      // Installed using adb commands or side loading or any cloud service
        source = "Local Source";
        break;
      case Source.IS_INSTALLED_FROM_AMAZON_APP_STORE:
      // Installed from Amazon app store
        source = "Amazon Store";
        break;
      case Source.IS_INSTALLED_FROM_HUAWEI_APP_GALLERY:
      // Installed from Huawei app store
        source = "Huawei App Gallery";
        break;
      case Source.IS_INSTALLED_FROM_SAMSUNG_GALAXY_STORE:
      // Installed from Samsung app store
        source = "Samsung Galaxy Store";
        break;
      case Source.IS_INSTALLED_FROM_SAMSUNG_SMART_SWITCH_MOBILE:
      // Installed from Samsung Smart Switch Mobile
        source = "Samsung Smart Switch Mobile";
        break;
      case Source.IS_INSTALLED_FROM_XIAOMI_GET_APPS:
      // Installed from Xiaomi app store
        source = "Xiaomi Get Apps";
        break;
      case Source.IS_INSTALLED_FROM_OPPO_APP_MARKET:
      // Installed from Oppo app store
        source = "Oppo App Market";
        break;
      case Source.IS_INSTALLED_FROM_VIVO_APP_STORE:
      // Installed from Vivo app store
        source = "Vivo App Store";
        break;
      case Source.IS_INSTALLED_FROM_RU_STORE:
      // Installed apk from RuStore
        source = "RuStore";
        break;
      case Source.IS_INSTALLED_FROM_OTHER_SOURCE:
      // Installed from other market store
        source = "Other Source";
        break;
      case Source.IS_INSTALLED_FROM_APP_STORE:
      // Installed from app store
        source = "App Store";
        break;
      case Source.IS_INSTALLED_FROM_TEST_FLIGHT:
      // Installed from Test Flight
        source = "Test Flight";
        break;
      case Source.UNKNOWN:
      // Installed from Unknown source
        source = "Unknown Source";
        break;
    }
  }

  checkVersion() async {
    final prefs = await SharedPreferences.getInstance();
    final int? branch_id = prefs.getInt('branch_id');
    DateFormat dateFormat = DateFormat("yyyy-MM-dd HH:mm:ss");
    String dateTime = dateFormat.format(DateTime.now());

    await getSource();
    await getLatestVersion();
    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    String version = packageInfo.version;
    if(latestVersion != ''){
      Version newVersion = Version.parse(latestVersion);
      Version currentVersion = Version.parse(version);
      if(currentVersion < newVersion){
        openUpdateDialog();
      }
    }

    try {
      int isGms = 0;
      if(defaultTargetPlatform == TargetPlatform.android) {
        await GmsCheck().checkGmsAvailability();
        isGms = GmsCheck().isGmsAvailable ? 1 : 0;
      }

      print("isGmsAvailable: $isGms");
      CurrentVersion? item = await PosDatabase.instance.readCurrentVersion();
      if(item == null){
        CurrentVersion object = CurrentVersion(
            current_version_id: 0,
            branch_id: branch_id.toString(),
            current_version: version,
            platform: defaultTargetPlatform == TargetPlatform.android ? 0 : 1,
            is_gms: isGms,
            source: source,
            sync_status: 0,
            created_at: dateTime,
            updated_at: '',
            soft_delete: '');
        await PosDatabase.instance.insertSqliteCurrentVersion(object);
        print("Current Version: insert");
      } else {
        if(item.current_version != version || item.platform != (defaultTargetPlatform == TargetPlatform.android ? 0 : 1) || item.source != source || item.is_gms != isGms){
          CurrentVersion object = CurrentVersion(
              branch_id: branch_id.toString(),
              current_version: version,
              platform: defaultTargetPlatform == TargetPlatform.android ? 0 : 1,
              is_gms: isGms,
              source: source,
              sync_status: item.sync_status == 0 ? 0 : 2,
              updated_at: dateTime);
          await PosDatabase.instance.updateCurrentVersion(object);
            print("Current Version: update");
        }
      }
      try {
        CurrentVersion? data = await PosDatabase.instance.readCurrentVersion();
        if(data!.sync_status != 1) {
          Map? response = await Domain().insertCurrentVersionDay(jsonEncode(data).toString());
          if (response != null && response['status'] == '1') {
            await PosDatabase.instance.updateCurrentVersionSyncStatusFromCloud(branch_id.toString());
            print("insert current version success");
            return 1;
          } else {
            print("insert current version failed");
            return 0;
          }
        }
      } catch(e) {
        print("current version sync to cloud error: $e");
      }
    } catch(e) {
      print("current version insert error: $e");
    }
  }

  checkSubscription() async {
    DateFormat dateFormat = DateFormat("yyyy-MM-dd");
    Subscription? data = await PosDatabase.instance.readAllSubscription();
    if (data != null) {
      DateTime subscriptionEndDate = dateFormat.parse(data.end_date!);
      Duration difference = subscriptionEndDate.difference(DateTime.now());
      if (DateTime.now().isAfter(subscriptionEndDate.add(Duration(days: 1)))) {
        showDialog(
            context: context,
            barrierDismissible: false,
            builder: (BuildContext context) {
              return WillPopScope(
                onWillPop: () async => false,
                child: AlertDialog(
                  title: Text(AppLocalizations.of(context)!.translate('subscription_expired')),
                  contentPadding: EdgeInsets.fromLTRB(24, 10, 24, 10),
                  content: Container(
                    height: 100,
                    child: Column(
                      children: [
                        Icon(
                          Icons.warning,
                          color: Colors.red,
                          size: MediaQuery.of(context).size.width > 900 && MediaQuery.of(context).size.height > 500 ? 60 : 35,
                        ),
                        SizedBox(height: 10),
                        Expanded(
                          child: Text(
                            AppLocalizations.of(context)!.translate('subscription_expired_desc'),
                            style: TextStyle(
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  actions: [
                    ElevatedButton(
                        onPressed: () async {
                          await openSyncDialog();
                          Subscription? item = await PosDatabase.instance.readAllSubscription();
                          DateTime newEndDate = dateFormat.parse(item!.end_date!);
                          setState(() {
                            if(DateTime.now().isBefore(newEndDate)) {
                              Navigator.of(context).pop();
                            }
                          });
                        },
                        child: Text(AppLocalizations.of(context)!.translate('refresh'))
                    )
                  ],
                ),
              );
            }
        );
      } else if (difference.inDays < 7) {
        showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                contentPadding: EdgeInsets.fromLTRB(24, 10, 24, 10),
                title: Text(AppLocalizations.of(context)!.translate('subscription_is_about_to_expire')),
                content: Container(
                  height: 100,
                  child: Column(
                    children: [
                      Icon(
                        Icons.warning,
                        color: Colors.yellow,
                        size: MediaQuery.of(context).size.width > 900 && MediaQuery.of(context).size.height > 500 ? 60 : 35,
                      ),
                      SizedBox(height: 10),
                      Expanded(
                          child: Text(
                          '${AppLocalizations.of(context)!.translate('subscription_is_about_to_expire_desc')} (${DateFormat('dd/MM/yyyy').format(subscriptionEndDate)})',
                            style: TextStyle(
                              fontSize: 16,
                            ),
                          )
                      )
                    ],
                  ),
                ),
                actions: [
                  ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      child: Text(AppLocalizations.of(context)!.translate('close')))
                ],
              );
            }
        );
      }
    }
  }

  Future<void> openSyncDialog() async {
    Completer<void> completer = Completer<void>();
    return showGeneralDialog(
        barrierColor: Colors.black.withOpacity(0.5),
        transitionBuilder: (context, a1, a2, widget) {
          final curvedValue = Curves.easeInOutBack.transform(a1.value) - 1.0;
          return Transform(
            transform: Matrix4.translationValues(0.0, curvedValue * 200, 0.0),
            child: Opacity(
              opacity: a1.value,
              child: SyncDialog(),
            ),
          );
        },
        transitionDuration: Duration(milliseconds: 200),
        barrierDismissible: false,
        context: context,
        pageBuilder: (context, animation1, animation2) {
          // ignore: null_check_always_fails
          return null!;
        }).then((_) {
      completer.complete(); // Completing the Future when the dialog is dismissed
    });
  }

  startTimers() {
    int timerCount = 0;
    notificationModel.setSyncCountAsStarted();
    notificationModel.resetTimer();
    Timer.periodic(Duration(seconds: 30), (timer) async {
      // print('sync record count: ${syncRecord.count}');
      bool _status = notificationModel.notificationStatus;
      bool stopTimer = notificationModel.stopTimer;
      if (stopTimer == true) {
        // print('timer cancelled called');
        timer.cancel();
        return;
      }
      if (_status == true) {
        // print('timer reset');
        timerCount = 0;
        notificationModel.resetNotification();
        return;
      }
      // print("sync to cloud count in 30 sec: ${mainSyncToCloud.count}");
      // print('timer count: ${timerCount}');
      //sync qr order
      if(qrOrder.count == 0){
        qrOrder.count = 1;
        await qrOrder.getQrOrder(MyApp.navigatorKey.currentContext!);
        qrOrder.count = 0;
      }

      //sync subscription
      if(syncRecord.count == 0){
        // print('subscription sync');
        syncRecord.count = 1;
        int syncStatus = await syncRecord.syncSubscriptionFromCloud();
        syncRecord.count = 0;
        // print('is log out: ${syncStatus}');
        if (syncStatus == 1) {
          openLogOutDialog();
          return;
        }
      }
      //30 sec sync
      // if (timerCount == 0) {
      //   //sync to cloud
      //   if(mainSyncToCloud.count == 0){
      //     mainSyncToCloud.count = 1;
      //     int? status = await mainSyncToCloud.syncAllToCloud();
      //     print('status: ${status}');
      //     if (status == 1) {
      //       openLogOutDialog();
      //       mainSyncToCloud.resetCount();
      //       return;
      //     } else if(status == 2){
      //       print('time out detected');
      //       mainSyncToCloud.resetCount();
      //     } else {
      //       mainSyncToCloud.resetCount();
      //     }
      //   }
      // } else {
      //   //qr order sync
      //   print("qr order count: ${qrOrder.count}");
      //   if(qrOrder.count == 0){
      //     print('qr order sync');
      //     qrOrder.count = 1;
      //     await qrOrder.getQrOrder(MyApp.navigatorKey.currentContext!);
      //     qrOrder.count = 0;
      //   }
      //
      //   //sync from cloud
      //   if(syncRecord.count == 0){
      //     syncRecord.count = 1;
      //     int syncStatus = await syncRecord.syncFromCloud();
      //     syncRecord.count = 0;
      //     print('is log out: ${syncStatus}');
      //     if (syncStatus == 1) {
      //       openLogOutDialog();
      //       return;
      //     }
      //   }
      // }
      //add timer and reset hasNotification
      //timerCount++;
      notificationModel.resetNotification();
      // reset the timer after two executions
      // if (timerCount >= 2) {
      //   timerCount = 0;
      // }
    });
  }

  Future<Future<Object?>> openSubscriptionExpiredDialog() async {
    return showGeneralDialog(
        barrierColor: Colors.black.withOpacity(0.5),
        transitionBuilder: (context, a1, a2, widget) {
          final curvedValue = Curves.easeInOutBack.transform(a1.value) - 1.0;
          return Transform(
            transform: Matrix4.translationValues(0.0, curvedValue * 200, 0.0),
            child: Opacity(
                opacity: a1.value,
                child: SubscriptionExpired()
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

  Future<Future<Object?>> openUpdateDialog() async {
    return showGeneralDialog(
        barrierColor: Colors.black.withOpacity(0.5),
        transitionBuilder: (context, a1, a2, widget) {
          final curvedValue = Curves.easeInOutBack.transform(a1.value) - 1.0;
          return Transform(
            transform: Matrix4.translationValues(0.0, curvedValue * 200, 0.0),
            child: Opacity(
                opacity: a1.value,
                child: UpdateDialog(versionData: response,)
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

  Future<Future<Object?>> openPrinterDialog({devices}) async {
    return showGeneralDialog(
        barrierColor: Colors.black.withOpacity(0.5),
        transitionBuilder: (context, a1, a2, widget) {
          final curvedValue = Curves.easeInOutBack.transform(a1.value) - 1.0;
          return Transform(
            transform: Matrix4.translationValues(0.0, curvedValue * 200, 0.0),
            child: Opacity(
                opacity: a1.value,
                child: PrinterDialog(
                  devices: devices,
                  callBack: () => readAllPrinters(),
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


  Future<Future<Object?>> openLogOutDialog() async {
    return showGeneralDialog(
        barrierColor: Colors.black.withOpacity(0.5),
        transitionBuilder: (context, a1, a2, widget) {
          final curvedValue = Curves.easeInOutBack.transform(a1.value) - 1.0;
          return Transform(
            transform: Matrix4.translationValues(0.0, curvedValue * 200, 0.0),
            child: Opacity(
              opacity: a1.value,
              child: LogoutConfirmDialog(),
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

  // _getDeviceList() async {
  //   List<Map<String, dynamic>> results = [];
  //   results = await FlutterUsbPrinter.getUSBDeviceList();
  //   if(results.isNotEmpty){
  //     devices = jsonEncode(results[0]);
  //     openPrinterDialog();
  //   }
  // }

  readAllPrinters() async {
    printerList = await printReceipt.readAllPrinters();
    if(printerList.isEmpty){
      var device = await printReceipt.getDeviceList();
      if(device != null){
        openPrinterDialog(devices: device);
      }
    } else {
      bool hasCashierPrinter = printerList.any((item) => item.is_counter == 1);
      if(!hasCashierPrinter){
        var device = await printReceipt.getDeviceList();
        if(device != null){
          openPrinterDialog(devices: device);
        }
      } else {
        await testPrintAllUsbPrinter();
        await bluetoothPrinterConnect();
      }
    }
  }

  testPrintAllUsbPrinter() async {
    List<Printer> usbPrinter = printerList.where((item) => item.type == 0).toList();
    await printReceipt.selfTest(usbPrinter);
  }

  bluetoothPrinterConnect() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? lastBtConnection = prefs.getString('lastBtConnection');

    bool bluetoothIsOn = await PrintBluetoothThermal.bluetoothEnabled;
    if(bluetoothIsOn) {
      bool connectionStatus = await PrintBluetoothThermal.connectionStatus;
      if (!connectionStatus && lastBtConnection != null) {
        bool result = await PrintBluetoothThermal.connect(macPrinterAddress: lastBtConnection);
        if(result) {
          await prefs.setString('lastBtConnection', lastBtConnection);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeColor>(builder: (context, ThemeColor color, child) {
      return LayoutBuilder(builder: (context, constraints) {
        if (constraints.maxWidth > 900 && constraints.maxHeight > 500) {
          return PopScope(
            canPop: false,
            child: Scaffold(
              body: Container(
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage("drawable/login_background.jpg"),
                    fit: BoxFit.cover,
                  ),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Container(
                          child: Theme(
                            data: Theme.of(context).copyWith(
                                textTheme: TextTheme(
                              bodyMedium: TextStyle(color: Colors.white),
                            )),
                            child: PinAuthentication(
                              pinTheme: PinTheme(
                                shape: PinCodeFieldShape.box,
                                selectedFillColor: const Color(0xFFF7F8FF).withOpacity(0.13),
                                inactiveFillColor: const Color(0xFFF7F8FF).withOpacity(0.13),
                                borderRadius: BorderRadius.circular(5),
                                backgroundColor: Colors.black87,
                                keysColor: Colors.white,
                                activeFillColor: const Color(0xFFF7F8FF).withOpacity(0.13),
                              ),
                              onChanged: (v) {},
                              onCompleted: (v) {
                                if (v.length == 6) {
                                  userCheck(v);
                                }
                              },
                              maxLength: 6,
                            ),
                          ),
                        ),
                      )
                    ],
                  ),
                ),
              ),
            ),
          );
        } else {
          return PopScope(
            canPop: false,
            child: Scaffold(
              backgroundColor: color.backgroundColor,
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Theme(
                        data: Theme.of(context).copyWith(
                            textTheme: TextTheme(
                          bodyMedium: TextStyle(color: Colors.white),
                        )),
                        child: SingleChildScrollView(
                            child: Container(
                              height: MediaQuery.of(context).size.height,
                              child: PinAuthentication(
                                pinTheme: PinTheme(
                                shape: PinCodeFieldShape.box,
                                fieldOuterPadding: EdgeInsets.zero,
                                fieldWidth: 40,
                                selectedFillColor: const Color(0xFFF7F8FF).withOpacity(0.13),
                                inactiveFillColor: const Color(0xFFF7F8FF).withOpacity(0.13),
                                borderRadius: BorderRadius.circular(5),
                                backgroundColor: color.backgroundColor,
                                keysColor: Colors.white,
                                activeFillColor: const Color(0xFFF7F8FF).withOpacity(0.13),
                              ),
                            onChanged: (v) {},
                            onCompleted: (v) {
                              if (v.length == 6) {
                                userCheck(v);
                              }
                            },
                            maxLength: 6,
                          ),
                        )),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }
      });
    });
  }

/*
  -------------------DB Query part---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
*/



/*
  -------------------Pos pin checking part---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
*/

  userCheck(String pos_pin) async {
    final prefs = await SharedPreferences.getInstance();
    final int? orientation = prefs.getInt('orientation');
    final int? branch_id = prefs.getInt('branch_id');
    User? user = await PosDatabase.instance.verifyPosPin(pos_pin, branch_id.toString());
    if (user != '' && user != null) {
      if(orientation == null || orientation == 0) {
        if (MediaQuery.of(context).orientation == Orientation.portrait) {
          SystemChrome.setPreferredOrientations([
            DeviceOrientation.portraitUp,
            DeviceOrientation.portraitDown
          ]);
        } else {
          SystemChrome.setPreferredOrientations([
            DeviceOrientation.landscapeLeft,
            DeviceOrientation.landscapeRight
          ]);
        }
      } else {
        if (orientation == 1) {
          SystemChrome.setPreferredOrientations([
            DeviceOrientation.landscapeLeft,
            DeviceOrientation.landscapeRight
          ]);
        } else {
          SystemChrome.setPreferredOrientations([
            DeviceOrientation.portraitUp,
            DeviceOrientation.portraitDown
          ]);
        }
      }

      if (await settlementCheck(user) == true) {
        // if(this.isLogOut == true){
        //   openLogOutDialog();
        //   return;
        // }
        print('pop a start cash dialog');
        Navigator.push(
          context,
          PageTransition(
            type: PageTransitionType.fade,
            child: HomePage(
              user: user,
              isNewDay: true,
            ),
          ),
        );
      } else {
        // if(this.isLogOut == true){
        //   openLogOutDialog();
        //   return;
        // }

        Navigator.push(
          context,
          PageTransition(
            type: PageTransitionType.fade,
            child: HomePage(
              user: user,
              isNewDay: false,
            ),
          ),
        );
      }
    } else {
      Fluttertoast.showToast(backgroundColor: Colors.red, msg: AppLocalizations.of(context)!.translate('wrong_pin_please_insert_valid_pin'));

    }
  }

  settlementCheck(User user) async {
    print('cash balance: ${widget.cashBalance}');
    final prefs = await SharedPreferences.getInstance();
    bool isNewDay = false;
    String totalCashBalance = '';
    List<CashRecord> data = await PosDatabase.instance.readBranchCashRecord();
    print("data length: ${data.length}");
    if (data.isNotEmpty) {
      if(widget.cashBalance == null){
        totalCashBalance = calcCashDrawer(cashRecordList: data);
      }
      if (await settlementUserCheck(user.user_id.toString(), totalCashBalance: totalCashBalance) == true) {
        await prefs.setString("pos_pin_user", jsonEncode(user));
        await PrintReceipt().printCashBalanceList(printerList, context, cashBalance: widget.cashBalance != null ? widget.cashBalance : totalCashBalance);  //_printCashBalanceList();
        isNewDay = false;
        print('print a cash balance receipt');
      } else {
        await prefs.setString("pos_pin_user", jsonEncode(user));
        isNewDay = false;
      }
    } else {
      await prefs.setString("pos_pin_user", jsonEncode(user));
      isNewDay = true;
    }
    return isNewDay;
  }

  calcCashDrawer({required List<CashRecord> cashRecordList}) {
    try {
      double totalCashIn = 0.0;
      double totalCashOut = 0.0;
      double totalCashDrawer = 0.0;
      double totalCashRefund = 0.0;
      for (int i = 0; i < cashRecordList.length; i++) {
        if (cashRecordList[i].type == 0) {
          totalCashIn += double.parse(cashRecordList[i].amount!);
        } else if (cashRecordList[i].type == 1) {
          totalCashIn += double.parse(cashRecordList[i].amount!);
        } else if (cashRecordList[i].type == 3 && cashRecordList[i].payment_type_id == '1') {
          totalCashIn += double.parse(cashRecordList[i].amount!);
        } else if (cashRecordList[i].type == 2 && cashRecordList[i].payment_type_id == '') {
          totalCashOut += double.parse(cashRecordList[i].amount!);
        } else if (cashRecordList[i].type == 4 && cashRecordList[i].payment_type_id == '1') {
          totalCashRefund += double.parse(cashRecordList[i].amount!);
        }
      }
      totalCashDrawer = totalCashIn - (totalCashOut + totalCashRefund);
      return totalCashDrawer.toStringAsFixed(2);
    } catch (e) {
      Fluttertoast.showToast(backgroundColor: Color(0xFFFF0000), msg: AppLocalizations.of(context)!.translate('calculate_cash_drawer_error')+" ${e}");
      return 0.0;
    }
  }

  settlementUserCheck(String user_id, {totalCashBalance}) async {
    final prefs = await SharedPreferences.getInstance();
    final String? lastUser = prefs.getString('pos_pin_user');
    bool isNewUser = false;
    CashRecord? cashRecord = await PosDatabase.instance.readLastCashRecord();
    print('last user: ${lastUser}');
    if (lastUser != null) {
      Map userObject = json.decode(lastUser);
      if (userObject['user_id'].toString() == user_id) {
        isNewUser = false;
      } else {
        isNewUser = true;
        await createTransferOwnerRecord(fromUser: userObject['user_id'].toString(), toUser: user_id, totalCashBalance: totalCashBalance);
        //await syncAllToCloud();
      }
    } else {
      if(cashRecord!.user_id != user_id){
        isNewUser = true;
        await createTransferOwnerRecord(fromUser: cashRecord.user_id, toUser: user_id, totalCashBalance: totalCashBalance);
        //await syncAllToCloud();
      } else {
        isNewUser = false;
      }
    }

    return isNewUser;
  }

  generateTransferOwnerKey(TransferOwner transferOwner) async {
    final prefs = await SharedPreferences.getInstance();
    final int? device_id = prefs.getInt('device_id');
    var bytes =
        transferOwner.created_at!.replaceAll(new RegExp(r'[^0-9]'), '') + transferOwner.transfer_owner_sqlite_id.toString() + device_id.toString();
    var md5Hash = md5.convert(utf8.encode(bytes));
    return Utils.shortHashString(hashCode: md5Hash);
  }

  insertTransferOwnerKey(TransferOwner transferOwner, String dateTime) async {
    TransferOwner? updatedRecord;
    String _key = await generateTransferOwnerKey(transferOwner);
    TransferOwner objectData = TransferOwner(
        transfer_owner_key: _key, sync_status: 0, updated_at: dateTime, transfer_owner_sqlite_id: transferOwner.transfer_owner_sqlite_id);
    int transferOwnerData = await PosDatabase.instance.updateTransferOwnerUniqueKey(objectData);
    if (transferOwnerData == 1) {
      TransferOwner updatedData = await PosDatabase.instance.readSpecificTransferOwnerByLocalId(objectData.transfer_owner_key!);
      updatedRecord = updatedData;
    }
    return updatedRecord;
  }

  createTransferOwnerRecord({fromUser, toUser, totalCashBalance}) async {
    List<String> _value = [];
    final prefs = await SharedPreferences.getInstance();
    final int? branch_id = prefs.getInt('branch_id');
    final int? device_id = prefs.getInt('device_id');
    DateFormat dateFormat = DateFormat("yyyy-MM-dd HH:mm:ss");
    String dateTime = dateFormat.format(DateTime.now());

    TransferOwner object = TransferOwner(
        transfer_owner_key: '',
        branch_id: branch_id.toString(),
        device_id: device_id.toString(),
        transfer_from_user_id: fromUser,
        transfer_to_user_id: toUser,
        cash_balance: widget.cashBalance != null ? widget.cashBalance : totalCashBalance,
        sync_status: 0,
        created_at: dateTime,
        updated_at: '',
        soft_delete: '');
    TransferOwner createRecord = await PosDatabase.instance.insertSqliteTransferOwner(object);
    TransferOwner _keyInsert = await insertTransferOwnerKey(createRecord, dateTime);
    _value.add(jsonEncode(_keyInsert));
    transferOwnerValue = _value.toString();
    //await syncTransferOwnerToCloud(_value.toString());
  }

  // syncTransferOwnerToCloud(String value) async {
  //   final prefs = await SharedPreferences.getInstance();
  //   final int? device_id = prefs.getInt('device_id');
  //   final String? login_value = prefs.getString('login_value');
  //   //check is host reachable
  //   bool _hasInternetAccess = await Domain().isHostReachable();
  //   if (_hasInternetAccess) {
  //     Map data = await Domain().syncLocalUpdateToCloud(
  //         device_id: device_id.toString(),
  //         value: login_value,
  //         transfer_owner_value: value
  //     );
  //     if (data['status'] == '1') {
  //       List responseJson = data['data'];
  //       await PosDatabase.instance.updateTransferOwnerSyncStatusFromCloud(responseJson[0]['transfer_owner_key']);
  //     } else if (data['status'] == '7') {
  //       this.isLogOut = true;
  //     }
  //     // Map response = await Domain().SyncTransferOwnerToCloud(value);
  //     // if (response['status'] == '1') {
  //     //   List responseJson = response['data'];
  //     //   int updateStatus = await PosDatabase.instance.updateTransferOwnerSyncStatusFromCloud(responseJson[0]['transfer_owner_key']);
  //     // }
  //   }
  // }

  syncAllToCloud() async {
    try{
      if(mainSyncToCloud.count == 0){
        mainSyncToCloud.count = 1;
        final prefs = await SharedPreferences.getInstance();
        final int? device_id = prefs.getInt('device_id');
        final String? login_value = prefs.getString('login_value');
        Map data = await Domain().syncLocalUpdateToCloud(
            device_id: device_id.toString(),
            value: login_value,
            transfer_owner_value: transferOwnerValue,
            user_value: userValue
        );
        if (data['status'] == '1') {
          List responseJson = data['data'];
          for(int i = 0; i < responseJson.length; i++){
            if(responseJson[i]['table_name'] == 'tb_transfer_owner'){
              await PosDatabase.instance.updateTransferOwnerSyncStatusFromCloud(responseJson[0]['transfer_owner_key']);
            }
          }
          mainSyncToCloud.resetCount();
        } else if (data['status'] == '7') {
          mainSyncToCloud.resetCount();
          this.isLogOut = true;
        } else if(data['status'] == '8'){
          mainSyncToCloud.resetCount();
          throw TimeoutException("Time out");
        } else {
          mainSyncToCloud.resetCount();
        }
      }
    }catch(e){
      mainSyncToCloud.resetCount();
    }
  }

/*
  -------------------Printing part---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
*/

}
