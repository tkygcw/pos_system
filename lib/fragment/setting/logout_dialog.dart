
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pos_system/object/user.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../database/pos_database.dart';
import '../../main.dart';
import '../../notifier/theme_color.dart';
import '../../page/login.dart';
import '../../translation/AppLocalizations.dart';

class logout_dialog extends StatefulWidget {

  const logout_dialog({Key? key}) : super(key: key);

  @override
  State<logout_dialog> createState() => _logout_dialogState();
}

class _logout_dialogState extends State<logout_dialog> {
  final adminPosPinController = TextEditingController();
  bool _submitted = false;
  bool isLogout = true;
  List <User> adminData = [];
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
  }

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
    adminPosPinController.dispose();
  }

  String? get errorPassword {
    final text = adminPosPinController.value.text;
    readAdminData(text);
    if (text.isEmpty) {
      return 'password_required';
    }
    return null;
  }

  void _submit(BuildContext context) async {
    setState(() => _submitted = true);
    if (errorPassword == '') {
      await readAdminData(adminPosPinController.text);
      return;
    }
  }

  closeDialog(BuildContext context) {
    return Navigator.of(context).pop(true);
  }

  Future showSecondDialog(BuildContext context, ThemeColor color) {
    return showDialog(
      barrierDismissible: false,
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.translate('enter_admin_pin')),
        content: SizedBox(
          height: 100.0,
          width: 350.0,
          child: Column(
            children: [
              ValueListenableBuilder(
                  valueListenable: adminPosPinController,
                  builder: (context, TextEditingValue value, __) {
                    return Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: TextField(
                        controller: adminPosPinController,
                        decoration: InputDecoration(
                          errorText: _submitted
                              ? errorPassword == null ? errorPassword: AppLocalizations.of(context)
                                  ?.translate(errorPassword!)
                              : null,
                          border: OutlineInputBorder(
                            borderSide:
                                BorderSide(color: color.backgroundColor),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide:
                                BorderSide(color: color.backgroundColor),
                          ),
                          labelText: "PIN",
                        ),
                      ),
                    );
                  }),
            ],
          ),
        ),
        actions: <Widget>[
          TextButton(
            child: Text(AppLocalizations.of(context)!.translate('close')),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
          TextButton(
            child:
                Text(AppLocalizations.of(context)!.translate('confirm_logout')),
            onPressed: () async {
              _submit(context);
            },
          ),
        ],
      ),
    );
  }

//   AlertDialog(

// );

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeColor>(builder: (context, ThemeColor color, child) {
      return AlertDialog(
        title: Text(
          "Confirm Log out?",
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        content:
            Text('${AppLocalizations.of(context)?.translate('confirm_logout_desc')}'),
        actions: <Widget>[
          TextButton(
            child: Text('${AppLocalizations.of(context)?.translate('no')}'),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
          TextButton(
            child: Text('${AppLocalizations.of(context)?.translate('yes')}'),
            onPressed: () async {
              await showSecondDialog(context, color);
              closeDialog(context);
              //_submit(context);
            },
          ),
        ],
      );
    });
  }

  logout() async{
    final prefs = await SharedPreferences.getInstance();
    prefs.clear();
    deleteAllRecord();
    deleteDirectory();
    displayManager.transferDataToPresentation("refresh_img");
    //deleteFile2();
    Navigator.of(context).pushReplacement(MaterialPageRoute(
        builder: (context) => LoginPage()));
  }

  readAdminData(String pin) async {
    List<User> data = await PosDatabase.instance.readSpecificUserWithRole(pin);
    if(data.length > 0){
      closeDialog(context);
      logout();
      Fluttertoast.showToast(
          backgroundColor: Color(0xFF24EF10),
          msg: AppLocalizations.of(context)!.translate('log_out_success'));
    }else{
      Fluttertoast.showToast(
          backgroundColor: Color(0xFFFF0000),
          msg: AppLocalizations.of(context)!.translate('password_incorrect'));
    }
  }

  deleteAllRecord() async {
    PosDatabase.instance.clearAllPosTable();
    PosDatabase.instance.clearAllTableUse();
    PosDatabase.instance.clearAllTableUseDetail();
    PosDatabase.instance.clearAllProduct();
    //clear variant item
    PosDatabase.instance.clearAllVariantItem();
    PosDatabase.instance.clearAllVariantGroup();
    PosDatabase.instance.clearAllProductVariant();
    PosDatabase.instance.clearAllProductVariantDetail();
    //clear Modifier
    PosDatabase.instance.clearAllModifierItem();
    PosDatabase.instance.clearAllModifierGroup();
    PosDatabase.instance.clearAllModifierLinkProduct();
    //clear branch link
    PosDatabase.instance.clearAllBranch();
    PosDatabase.instance.clearAllBranchLinkModifier();
    PosDatabase.instance.clearAllBranchLinkProduct();
    PosDatabase.instance.clearAllBranchLinkPromotion();
    PosDatabase.instance.clearAllBranchLinkTax();
    PosDatabase.instance.clearAllBranchLinkDining();
    PosDatabase.instance.clearAllBranchLinkUser();
    //clear dining option
    PosDatabase.instance.clearAllDiningOption();
    //clear all user
    PosDatabase.instance.clearAllUser();
    //clear payment link company
    PosDatabase.instance.clearAllPaymentLinkCompany();
    //clear tax
    PosDatabase.instance.clearAllTax();
    PosDatabase.instance.clearAllTaxLinkDining();
    //clear promotion
    PosDatabase.instance.clearAllPromotion();
    //clear categories
    PosDatabase.instance.clearAllCategory();
    //clear order
    PosDatabase.instance.clearAllOrderCache();
    PosDatabase.instance.clearAllOrderDetail();
    PosDatabase.instance.clearAllOrderDetailCancel();
    PosDatabase.instance.clearAllOrderModifierDetail();
    PosDatabase.instance.clearAllOrder();
    PosDatabase.instance.clearAllOrderTax();
    PosDatabase.instance.clearAllOrderPromotion();
    //clear refund
    PosDatabase.instance.clearAllRefund();
    //clear settlement
    PosDatabase.instance.clearAllSettlement();
    PosDatabase.instance.clearAllSettlementLinkPayment();
    //clear customer
    PosDatabase.instance.clearAllCustomer();
    //clear receipt layout
    PosDatabase.instance.clearAllReceiptLayout();
    //clear cash record
    PosDatabase.instance.clearAllCashRecord();
    //clear cash record
    PosDatabase.instance.clearAllCashRecord();
    //clear printer
    PosDatabase.instance.clearAllPrinter();
    //clear printer category
    PosDatabase.instance.clearAllPrinterCategory();
    //clear checklist layout
    PosDatabase.instance.clearAllChecklist();
    //clear kitchen list layout
    PosDatabase.instance.clearAllKitchenList();
    //clear second screen
    PosDatabase.instance.clearAllSecondScreen();
  }

  Future<String> get _localPath async {
    final directory = await getApplicationSupportDirectory();
    return directory.path;
  }

  Future<Directory> get _localDirectory async {
    final path = await _localPath;
    print('path ${path}');
    return Directory('$path/assets');
  }

  Future<int> deleteDirectory() async {
    try {
      final folder = await _localDirectory;
        folder.delete(recursive: true);
        print("delete successful");
      return 1;
    } catch (e) {
      print(e);
      return 0;
    }
  }

}
