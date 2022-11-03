
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:page_transition/page_transition.dart';
import 'package:pos_system/page/home.dart';
import 'package:provider/provider.dart';
import 'package:custom_pin_screen/custom_pin_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../database/pos_database.dart';
import '../notifier/theme_color.dart';
import '../object/cash_record.dart';
import '../object/user.dart';

class PosPinPage extends StatefulWidget {
  const PosPinPage({Key? key}) : super(key: key);

  @override
  _PosPinPageState createState() => _PosPinPageState();
}

class _PosPinPageState extends State<PosPinPage> {


  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeColor>(builder: (context, ThemeColor color, child) {
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
    });
  }

  userCheck(String pos_pin) async{
    final prefs = await SharedPreferences.getInstance();
    final int? branch_id = prefs.getInt('branch_id');
    User? user = await PosDatabase.instance.verifyPosPin(pos_pin,branch_id.toString());
    if(user!='' && user != null){
      if(await settlementCheck(user) == true){
        print('pop a start cash dialog');
        // Navigator.push(
        //   context,
        //   PageTransition(
        //     type: PageTransitionType.fade,
        //     child: HomePage(user: user),
        //   ),
        // );
      } else {
        Navigator.push(
          context,
          PageTransition(
            type: PageTransitionType.fade,
            child: HomePage(user: user),
          ),
        );
      }

    }
    else {
      Fluttertoast.showToast( backgroundColor: Colors.red, msg: "Wrong pin. Please insert valid pin");
    }

  }

  settlementCheck(User user) async {
    bool isNewDay = false;
    List<CashRecord> data = await PosDatabase.instance.readAllCashRecord();
    if(data.length > 0){
      if(await settlementUserCheck(user.user_id.toString()) == true){
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
}
