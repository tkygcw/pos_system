
import 'dart:convert';
import 'dart:typed_data';

import 'package:esc_pos_printer/esc_pos_printer.dart';
import 'package:esc_pos_utils/esc_pos_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_usb_printer/flutter_usb_printer.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';
import 'package:page_transition/page_transition.dart';
import 'package:pos_system/object/transfer_owner.dart';
import 'package:pos_system/page/home.dart';
import 'package:pos_system/page/mobile_home.dart';
import 'package:provider/provider.dart';
import 'package:custom_pin_screen/custom_pin_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:crypto/crypto.dart';
import '../database/domain.dart';
import '../database/pos_database.dart';
import '../notifier/theme_color.dart';
import '../object/cash_record.dart';
import '../object/print_receipt.dart';
import '../object/printer.dart';
import '../object/printer_link_category.dart';
import '../object/receipt_layout.dart';
import '../object/user.dart';
import '../translation/AppLocalizations.dart';

class PosPinPage extends StatefulWidget {
  final String? cashBalance;
  const PosPinPage({Key? key, this.cashBalance}) : super(key: key);

  @override
  _PosPinPageState createState() => _PosPinPageState();
}

class _PosPinPageState extends State<PosPinPage> {
  FlutterUsbPrinter flutterUsbPrinter = FlutterUsbPrinter();
  List<Printer> printerList = [];

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    readAllPrinters();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeColor>(builder: (context, ThemeColor color, child) {
      return LayoutBuilder(
        builder: (context, constraints) {
          if(constraints.maxWidth > 800){
            return Scaffold(
              backgroundColor: color.backgroundColor,
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Container(
                        child: Theme(
                          data: Theme.of(context).copyWith(
                              textTheme:  TextTheme(
                                bodyText2: TextStyle(color: Colors.white),
                              )
                          ),
                          child: PinAuthentication(
                            pinTheme: PinTheme(
                              shape: PinCodeFieldShape.box,
                              selectedFillColor:
                              const Color(0xFFF7F8FF).withOpacity(0.13),
                              inactiveFillColor:
                              const Color(0xFFF7F8FF).withOpacity(0.13),
                              borderRadius: BorderRadius.circular(5),
                              backgroundColor: color.backgroundColor,
                              keysColor: Colors.white,
                              activeFillColor:
                              const Color(0xFFF7F8FF).withOpacity(0.13),
                            ),
                            onChanged: (v) {},
                            onCompleted: (v) {
                              if(v.length==6){
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
                            textTheme:  TextTheme(
                              bodyText2: TextStyle(color: Colors.white),
                            )
                        ),
                        child: SingleChildScrollView(
                            child: Container(
                              height: 600,
                              child: PinAuthentication(
                                pinTheme: PinTheme(
                                  shape: PinCodeFieldShape.box,
                                  selectedFillColor:
                                  const Color(0xFFF7F8FF).withOpacity(0.13),
                                  inactiveFillColor:
                                  const Color(0xFFF7F8FF).withOpacity(0.13),
                                  borderRadius: BorderRadius.circular(5),
                                  backgroundColor: color.backgroundColor,
                                  keysColor: Colors.white,
                                  activeFillColor:
                                  const Color(0xFFF7F8FF).withOpacity(0.13),
                                ),
                                onChanged: (v) {},
                                onCompleted: (v) {
                                  if(v.length==6){
                                    userCheck(v);
                                  }
                                },
                                maxLength: 6,

                              ),
                            )
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

        }
      );
    });
  }
/*
  -------------------DB Query part---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
*/

  readAllPrinters() async {
    printerList = await PrintReceipt().readAllPrinters();
  }

/*
  -------------------Pos pin checking part---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
*/

  userCheck(String pos_pin) async{
    final prefs = await SharedPreferences.getInstance();
    final int? branch_id = prefs.getInt('branch_id');
    User? user = await PosDatabase.instance.verifyPosPin(pos_pin,branch_id.toString());
    if(user!='' && user != null){
      if(await settlementCheck(user) == true){
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
      await prefs.setString("pos_pin_user", jsonEncode(user));
    }
    else {
      Fluttertoast.showToast( backgroundColor: Colors.red, msg: "Wrong pin. Please insert valid pin");
    }
  }

  settlementCheck(User user) async {
    final prefs = await SharedPreferences.getInstance();
    final int? branch_id = prefs.getInt('branch_id');
    bool isNewDay = false;
    List<CashRecord> data = await PosDatabase.instance.readBranchCashRecord(branch_id.toString());
    if(data.length > 0){
      if(await settlementUserCheck(user.user_id.toString()) == true){
        await _printCashBalanceList();
        isNewDay = false;
        print('print a cash balance receipt');
      } else{
        isNewDay = false;
      }
    } else {
      isNewDay = true;
    }
    return isNewDay;
  }

  settlementUserCheck(String user_id) async{
    final prefs = await SharedPreferences.getInstance();
    final String? lastUser = prefs.getString('pos_pin_user');
    bool isNewUser = false;
    //CashRecord? cashRecord = await PosDatabase.instance.readLastCashRecord();
    if(lastUser != null){
      Map userObject = json.decode(lastUser);
      if(userObject['user_id'].toString() == user_id){
        isNewUser = false;
      } else {
        isNewUser = true;
        createTransferOwnerRecord(fromUser: userObject['user_id'].toString(), toUser: user_id);
      }
    } else {
      isNewUser = true;
    }

    return isNewUser;
  }

  generateTransferOwnerKey(TransferOwner transferOwner) async {
    final prefs = await SharedPreferences.getInstance();
    final int? device_id = prefs.getInt('device_id');
    var bytes = transferOwner.created_at!.replaceAll(new RegExp(r'[^0-9]'), '') + transferOwner.transfer_owner_sqlite_id.toString() + device_id.toString();
    return md5.convert(utf8.encode(bytes)).toString();
  }

  insertTransferOwnerKey(TransferOwner transferOwner, String dateTime) async {
    TransferOwner? updatedRecord;
    String _key = await generateTransferOwnerKey(transferOwner);
    TransferOwner objectData = TransferOwner(
      transfer_owner_key: _key,
      sync_status: 0,
      updated_at: dateTime,
      transfer_owner_sqlite_id: transferOwner.transfer_owner_sqlite_id
    );
    int transferOwnerData = await PosDatabase.instance.updateTransferOwnerUniqueKey(objectData);
    if(transferOwnerData == 1){
      TransferOwner updatedData = await PosDatabase.instance.readSpecificTransferOwnerByLocalId(objectData.transfer_owner_sqlite_id!);
      updatedRecord = updatedData;
    }
    return updatedRecord;
  }

  createTransferOwnerRecord({fromUser, toUser}) async {
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
      cash_balance: widget.cashBalance,
      sync_status: 0,
      created_at: dateTime,
      updated_at: '',
      soft_delete: ''
    );
    TransferOwner createRecord = await PosDatabase.instance.insertSqliteTransferOwner(object);
    TransferOwner _keyInsert = await insertTransferOwnerKey(createRecord, dateTime);
    _value.add(jsonEncode(_keyInsert));
    syncToCloud(_value.toString());

  }

  syncToCloud(String value) async {
    //check is host reachable
    bool _hasInternetAccess = await Domain().isHostReachable();
    if(_hasInternetAccess){
      Map data = await Domain().syncLocalUpdateToCloud(
          transfer_owner_value: value
      );
      if (data['status'] == '1') {
        List responseJson = data['data'];
        await PosDatabase.instance.updateTransferOwnerSyncStatusFromCloud(responseJson[0]['transfer_owner_key']);
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
  _printCashBalanceList() async {
    try {
      for (int i = 0; i < printerList.length; i++) {
        List<PrinterLinkCategory> data = await PosDatabase.instance.readPrinterLinkCategory(printerList[i].printer_sqlite_id!);
        for (int j = 0; j < data.length; j++) {
          if (data[j].category_sqlite_id == '-1') {
            var printerDetail = jsonDecode(printerList[i].value!);
            if (printerList[i].type == 0) {
              if(printerList[i].paper_size == 0){
                //print usb 80mm
                var data = Uint8List.fromList(await ReceiptLayout().printCashBalanceList80mm(true, widget.cashBalance!));
                bool? isConnected = await flutterUsbPrinter.connect(
                    int.parse(printerDetail['vendorId']),
                    int.parse(printerDetail['productId']));
                if (isConnected == true) {
                  await flutterUsbPrinter.write(data);
                } else {
                  Fluttertoast.showToast(
                      backgroundColor: Colors.red,
                      msg: "${AppLocalizations.of(context)?.translate('usb_printer_not_connect')}");
                }
              } else {
                //print usb 58mm
                var data = Uint8List.fromList(await ReceiptLayout().printCashBalanceList58mm(true, widget.cashBalance!));
                bool? isConnected = await flutterUsbPrinter.connect(
                    int.parse(printerDetail['vendorId']),
                    int.parse(printerDetail['productId']));
                if (isConnected == true) {
                  await flutterUsbPrinter.write(data);
                } else {
                  Fluttertoast.showToast(
                      backgroundColor: Colors.red,
                      msg: "${AppLocalizations.of(context)?.translate('usb_printer_not_connect')}");
                }
              }
            } else {
              //print LAN
              if(printerList[i].paper_size == 0){
                //print 80mm
                final profile = await CapabilityProfile.load();
                final printer = NetworkPrinter(PaperSize.mm80, profile);
                final PosPrintResult res = await printer.connect(printerDetail, port: 9100);
                if (res == PosPrintResult.success) {
                  await ReceiptLayout().printCashBalanceList80mm(false, widget.cashBalance!, value: printer);
                  printer.disconnect();
                } else {
                  Fluttertoast.showToast(
                      backgroundColor: Colors.red,
                      msg: "${AppLocalizations.of(context)?.translate('lan_printer_not_connect')}");
                }
              } else {
                //print 58mm
                final profile = await CapabilityProfile.load();
                final printer = NetworkPrinter(PaperSize.mm58, profile);
                final PosPrintResult res = await printer.connect(printerDetail, port: 9100);
                if (res == PosPrintResult.success) {
                  await ReceiptLayout().printCashBalanceList58mm(false, widget.cashBalance!, value: printer);
                  printer.disconnect();
                } else {
                  Fluttertoast.showToast(
                      backgroundColor: Colors.red,
                      msg: "${AppLocalizations.of(context)?.translate('lan_printer_not_connect')}");
                }
              }
            }
          }
        }
      }
    } catch (e) {
      print(e);
      print('Printer Connection Error');
      //response = 'Failed to get platform version.';
    }
  }

}
