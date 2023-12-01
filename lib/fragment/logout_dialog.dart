import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pos_system/database/domain.dart';
import 'package:pos_system/main.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../database/pos_database.dart';
import '../notifier/cart_notifier.dart';
import '../notifier/theme_color.dart';
import '../page/login.dart';
import '../translation/AppLocalizations.dart';

class LogoutConfirmDialog extends StatefulWidget {
  final String? currentPage;
  const LogoutConfirmDialog({Key? key, this.currentPage}) : super(key: key);

  @override
  State<LogoutConfirmDialog> createState() => _LogoutConfirmDialogState();
}

class _LogoutConfirmDialogState extends State<LogoutConfirmDialog> {
  var prefs;
  bool isButtonDisabled = false;

  @override
  void initState() {
    super.initState();
    getPreferences();
  }

  getPreferences() async {
    prefs = await SharedPreferences.getInstance();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeColor>(builder: (context, ThemeColor color, child) {
      return Consumer<CartModel>(builder: (context, CartModel cart, child) {
        return WillPopScope(
          onWillPop: () async => false,
          child: AlertDialog(
            title: widget.currentPage != null
                ?
            Text('${AppLocalizations.of(context)?.translate('log-out_reset-pos')}')
                :
            Text('${AppLocalizations.of(context)?.translate('detect_multiple_login')}'),
            content: Container(
              height: MediaQuery.of(context).size.height / 5,
              width: MediaQuery.of(context).size.width / 3,
              child: widget.currentPage == null
                  ?
              Text('${AppLocalizations.of(context)?.translate('logout_desc')}')
                  :
              Text('${AppLocalizations.of(context)?.translate('logout_desc2')}'),
            ),
            actions: [
              Visibility(
                  visible: widget.currentPage != null ? true : false,
                  child: TextButton(
                    child: Text('${AppLocalizations.of(context)?.translate('close')}'),
                    onPressed: isButtonDisabled ? null : () {
                      // Disable the button after it has been pressed
                      setState(() {
                        isButtonDisabled = true;
                      });
                     Navigator.of(context).pop();
                    },
                  ),
              ),
              TextButton(
                child: Text('${AppLocalizations.of(context)?.translate('ok')}'),
                onPressed: isButtonDisabled ? null : () {
                  // Disable the button after it has been pressed
                  setState(() {
                    isButtonDisabled = true;
                  });
                  if(widget.currentPage != null){
                    deviceLogout();
                  }
                  logout(cart);
                },
              ),
            ],
          ),
        );
      });
    });
  }

  deviceLogout() async {
    final int? device_id = prefs.getInt('device_id');
    if(device_id != 4){
      Map response = await Domain().deviceLogout(device_id.toString());
    }
  }

  logout(CartModel cart) async{
    notificationModel.setTimer(true);
    notificationModel.resetSyncCount();
    prefs.clear();
    deleteAllLocalRecord();
    deleteDirectory();
    cart.removeAllTable();
    cart.removeAllCartItem();
    cart.removePromotion();
    setState(() {});
    //deleteFile2();
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
    // Navigator.of(context).pushReplacement(MaterialPageRoute(
    //     builder: (context) => LoginPage()));
  }

  deleteAllLocalRecord() async {
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
    //clear app setting
    PosDatabase.instance.clearAllAppSetting();
    //clear printer
    PosDatabase.instance.clearAllPrinter();
    //clear printer category
    PosDatabase.instance.clearAllPrinterCategory();
    //clear checklist layout
    PosDatabase.instance.clearAllChecklist();
    //clear kitchen list layout
    PosDatabase.instance.clearAllKitchenList();
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
