
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_usb_printer/flutter_usb_printer.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:page_transition/page_transition.dart';
import 'package:pos_system/page/home.dart';
import 'package:pos_system/page/mobile_home.dart';
import 'package:provider/provider.dart';
import 'package:custom_pin_screen/custom_pin_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../database/pos_database.dart';
import '../notifier/theme_color.dart';
import '../object/cash_record.dart';
import '../object/printer.dart';
import '../object/printer_link_category.dart';
import '../object/receipt_layout.dart';
import '../object/user.dart';

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
    final prefs = await SharedPreferences.getInstance();
    final int? branch_id = prefs.getInt('branch_id');

    List<Printer> data = await PosDatabase.instance.readAllBranchPrinter(branch_id!);
    printerList = List.from(data);
  }

/*
  -------------------Pos pin checking part---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
*/

  userCheck(String pos_pin) async{
    final prefs = await SharedPreferences.getInstance();
    final int? branch_id = prefs.getInt('branch_id');
    User? user = await PosDatabase.instance.verifyPosPin(pos_pin,branch_id.toString());
    if(user!='' && user != null){
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString("pos_pin_user", jsonEncode(user));
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
        //await _printCashBalanceList();
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
    final int? branch_id = prefs.getInt('branch_id');
     bool isNewUser = false;

    CashRecord? cashRecord = await PosDatabase.instance.readLastCashRecord(branch_id.toString());
    if(cashRecord?.user_id == user_id){
      isNewUser = false;
    } else {
      isNewUser = true;
    }
    return isNewUser;
  }

/*
  -------------------Printing part---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
*/
  _printCashBalanceList() async {
    print('printer called');
    try {
      for (int i = 0; i < printerList.length; i++) {
        List<PrinterLinkCategory> data = await PosDatabase.instance
            .readPrinterLinkCategory(printerList[i].printer_sqlite_id!);
        for (int j = 0; j < data.length; j++) {
          if (data[j].category_sqlite_id == '3') {
            if (printerList[i].type == 0) {
              var printerDetail = jsonDecode(printerList[i].value!);
              var data = Uint8List.fromList(await ReceiptLayout().printCashBalanceList80mm(true, null, widget.cashBalance!));
              bool? isConnected = await flutterUsbPrinter.connect(
                  int.parse(printerDetail['vendorId']),
                  int.parse(printerDetail['productId']));
              if (isConnected == true) {
                await flutterUsbPrinter.write(data);
              } else {
                print('not connected');
              }
            } else {
              print("print lan");
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
