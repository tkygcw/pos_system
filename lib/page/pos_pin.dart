import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_usb_printer/flutter_usb_printer.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';
import 'package:page_transition/page_transition.dart';
import 'package:pos_system/main.dart';
import 'package:pos_system/object/transfer_owner.dart';
import 'package:pos_system/page/home.dart';
import 'package:provider/provider.dart';
import 'package:custom_pin_screen/custom_pin_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:crypto/crypto.dart';
import '../database/domain.dart';
import '../database/pos_database.dart';
import '../fragment/logout_dialog.dart';
import '../fragment/setting/printer_dialog.dart';
import '../notifier/theme_color.dart';
import '../object/cash_record.dart';
import '../object/print_receipt.dart';
import '../object/printer.dart';
import '../object/user.dart';

class PosPinPage extends StatefulWidget {
  final String? cashBalance;

  const PosPinPage({Key? key, this.cashBalance}) : super(key: key);

  @override
  _PosPinPageState createState() => _PosPinPageState();
}

class _PosPinPageState extends State<PosPinPage> {
  FlutterUsbPrinter flutterUsbPrinter = FlutterUsbPrinter();
  PrintReceipt printReceipt = PrintReceipt();
  List<Printer> printerList = [];
  bool isLogOut = false;

  @override
  void initState() {
    super.initState();
    //readAllPrinters();
    preload();
  }

  @override
  dispose() {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeRight,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    super.dispose();
  }

  preload() async {
    bool _hasInternetAccess = await Domain().isHostReachable();
    if(_hasInternetAccess){
      syncRecord.syncFromCloud();
      syncRecord.count = 0;
    }
    if(notificationModel.syncCountStarted == false){
      startTimers();
    }
    await readAllPrinters();
  }

  startTimers() {
    int timerCount = 0;
    notificationModel.setSyncCountAsStarted();
    notificationModel.resetTimer();
    Timer.periodic(Duration(seconds: 15), (timer) async {
      print('sync record count: ${syncRecord.count}');
      bool _status = notificationModel.notificationStatus;
      bool stopTimer = notificationModel.stopTimer;
      if (stopTimer == true) {
        print('timer cancelled called');
        timer.cancel();
        return;
      }
      if (_status == true) {
        print('timer reset');
        timerCount = 0;
        notificationModel.resetNotification();
        return;
      }
      bool _hasInternetAccess = await Domain().isHostReachable();
      if (_hasInternetAccess) {
        print('timer count: ${timerCount}');
        if (timerCount == 0) {
          //sync to cloud
          print('sync to cloud');
          if(mainSyncToCloud.count == 0){
            var isLogOut = await mainSyncToCloud.syncAllToCloud();
            if (isLogOut == true) {
              openLogOutDialog();
              return;
            }
            mainSyncToCloud.resetCount();
          }
          //SyncToCloud().syncToCloud();
        } else {
          //qr order sync
          if(qrOrder.count == 0){
            print('qr order sync');
            qrOrder.getQrOrder();
            qrOrder.count = 0;
          }

          // if (notificationModel.notificationStatus == true) {
          //   print('timer reset inside');
          //   timerCount = 0;
          //   notificationModel.resetNotification();
          //   return;
          // }
          //sync from cloud
          if(syncRecord.count == 0){
            var syncStatus = await syncRecord.syncFromCloud();
            print('is log out: ${syncStatus}');
            if (syncStatus == true) {
              openLogOutDialog();
              return;
            } else if (syncStatus == false) {
              // ScaffoldMessenger.of(context).showSnackBar(
              //   SnackBar(
              //     duration: Duration(minutes: 5),
              //     backgroundColor: Colors.green,
              //     content: const Text('Content change !!!'),
              //     action: SnackBarAction(
              //       label: 'Refresh',
              //       textColor: Colors.white,
              //       onPressed: () {
              //         setState(() {
              //           ScaffoldMessenger.of(context).hideCurrentSnackBar();
              //         });
              //         // Code to execute.
              //       },
              //     ),
              //   ),
              // );
            }
            syncRecord.count = 0;
          }
        }
        //add timer and reset hasNotification
        timerCount++;
        notificationModel.resetNotification();
        // reset the timer after two executions
        if (timerCount >= 2) {
          timerCount = 0;
        }
      }
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
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeColor>(builder: (context, ThemeColor color, child) {
      return LayoutBuilder(builder: (context, constraints) {
        if (constraints.maxWidth > 800) {
          return WillPopScope(
            onWillPop: () async => false,
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
                              bodyText2: TextStyle(color: Colors.white),
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
          return Scaffold(
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
    final int? branch_id = prefs.getInt('branch_id');
    User? user = await PosDatabase.instance.verifyPosPin(pos_pin, branch_id.toString());
    if (user != '' && user != null) {
      if (await settlementCheck(user) == true) {
        if(this.isLogOut == true){
          openLogOutDialog();
          return;
        }
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
        if(this.isLogOut == true){
          openLogOutDialog();
          return;
        }
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
      Fluttertoast.showToast(backgroundColor: Colors.red, msg: "Wrong pin. Please insert valid pin");

    }
  }

  settlementCheck(User user) async {
    print('cash balance: ${widget.cashBalance}');
    final prefs = await SharedPreferences.getInstance();
    bool isNewDay = false;
    double totalCashBalance = 0.0;
    List<CashRecord> data = await PosDatabase.instance.readBranchCashRecord();
    if (data.isNotEmpty) {
      if(widget.cashBalance == null){
        for(int i = 0; i < data.length; i++){
          totalCashBalance += double.parse(data[i].amount!);
        }
      }
      if (await settlementUserCheck(user.user_id.toString(), totalCashBalance: totalCashBalance.toStringAsFixed(2)) == true) {
        await prefs.setString("pos_pin_user", jsonEncode(user));
        await PrintReceipt().printCashBalanceList(printerList, context, cashBalance: widget.cashBalance != null ? widget.cashBalance : totalCashBalance.toStringAsFixed(2));  //_printCashBalanceList();
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
        await createTransferOwnerRecord(fromUser: userObject['user_id'].toString(), toUser: user_id);
      }
    } else {
      if(cashRecord!.user_id != user_id){
        isNewUser = true;
        await createTransferOwnerRecord(fromUser: cashRecord.user_id, toUser: user_id, totalCashBalance: totalCashBalance);
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
    return md5.convert(utf8.encode(bytes)).toString();
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
    print('user changed!');
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
    await syncTransferOwnerToCloud(_value.toString());
  }

  syncTransferOwnerToCloud(String value) async {
    final prefs = await SharedPreferences.getInstance();
    final int? device_id = prefs.getInt('device_id');
    final String? login_value = prefs.getString('login_value');
    //check is host reachable
    bool _hasInternetAccess = await Domain().isHostReachable();
    if (_hasInternetAccess) {
      Map data = await Domain().syncLocalUpdateToCloud(
          device_id: device_id.toString(),
          value: login_value,
          transfer_owner_value: value
      );
      if (data['status'] == '1') {
        List responseJson = data['data'];
        await PosDatabase.instance.updateTransferOwnerSyncStatusFromCloud(responseJson[0]['transfer_owner_key']);
      } else if (data['status'] == '7') {
        this.isLogOut = true;
      }
      // Map response = await Domain().SyncTransferOwnerToCloud(value);
      // if (response['status'] == '1') {
      //   List responseJson = response['data'];
      //   int updateStatus = await PosDatabase.instance.updateTransferOwnerSyncStatusFromCloud(responseJson[0]['transfer_owner_key']);
      // }
    }
  }

/*
  -------------------Printing part---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
*/

}
