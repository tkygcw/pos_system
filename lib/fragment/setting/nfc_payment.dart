import 'dart:convert';

import 'package:f_logs/model/flog/flog.dart';
import 'package:flutter/material.dart';
import 'package:pos_system/notifier/theme_color.dart';
import 'package:pos_system/object/nfc_payment/nfc_payment.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../object/branch.dart';
import '../../translation/AppLocalizations.dart';
import '../custom_toastification.dart';

class PaymentSettingPage extends StatelessWidget {
  const PaymentSettingPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    var orientation = MediaQuery.of(context).orientation;
    return Scaffold(
      appBar: orientation == Orientation.portrait ?  buildAppBar(context): null,
      body: ListTile(
        title: Text(AppLocalizations.of(context)!.translate('refresh_nfc_token')),
        trailing: ElevatedButton(onPressed: refreshTokenOnPressed, child: Icon(Icons.nfc)),
      ),
    );
  }

  AppBar buildAppBar(BuildContext context) {
    var color = context.read<ThemeColor>();
    return AppBar(
      elevation: 1,
      leading: IconButton(
        icon: Icon(Icons.arrow_back_ios, color: color.buttonColor),
        onPressed: () {
          Navigator.of(context).pop();
        },
      ),
      backgroundColor: Colors.white,
      title: Text(AppLocalizations.of(context)!.translate('payment_setting'),
          style: TextStyle(fontSize: 20, color: color.backgroundColor)),
      centerTitle: false,
    );
  }

  void refreshTokenOnPressed() async {
    try{
      final prefs = await SharedPreferences.getInstance();
      final String? branch = prefs.getString('branch');
      Map<String, dynamic> branchMap = json.decode(branch!);
      Branch branchObject = Branch.fromJson(branchMap);
      //need to pass userID/uniqueID for refresh token (will save in tb_branch)
      //branchObject.fiuu_unique_id = "nI2qo2vAmRoPbdgE2tfJ";
      if(branchObject.allow_nfc_payment == 1){
        await NFCPayment.refreshToken(uniqueID: branchObject.fiuu_unique_id ?? '');
        showToast(title: "Token refresh success");
      } else {
        showToast(title: "NFC payment not allowed", isError: true);
      }
    }catch(e, s){
      FLog.error(
        className: "Pos pin",
        text: "refresh nfc token failed",
        exception: "Error: $e, StackTrace: $s",
      );
      showToast(title: "Invalid token", isError: true);
    }
  }

  void showToast({required String title, String? description, bool? isError = false}){
    if(isError == true){
      CustomFailedToast.showToast(
          title: title,
          description: description,
          duration: 8
      );
    } else {
      CustomSuccessToast.showToast(title: title);
    }
  }
}

