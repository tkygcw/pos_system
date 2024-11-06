import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'package:f_logs/model/flog/flog.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pos_system/database/pos_database.dart';
import 'package:pos_system/database/pos_firestore.dart';
import 'package:pos_system/object/attendance.dart';
import 'package:pos_system/object/bill.dart';
import 'package:pos_system/object/branch_link_dining_option.dart';
import 'package:pos_system/object/branch_link_modifier.dart';
import 'package:pos_system/object/branch_link_product.dart';
import 'package:pos_system/object/branch_link_promotion.dart';
import 'package:pos_system/object/branch_link_tax.dart';
import 'package:pos_system/object/cash_record.dart';
import 'package:pos_system/object/categories.dart';
import 'package:pos_system/object/kitchen_list.dart';
import 'package:pos_system/object/modifier_group.dart';
import 'package:pos_system/object/modifier_item.dart';
import 'package:pos_system/object/modifier_link_product.dart';
import 'package:pos_system/object/order.dart';
import 'package:pos_system/object/order_cache.dart';
import 'package:pos_system/object/order_detail.dart';
import 'package:pos_system/object/order_detail_cancel.dart';
import 'package:pos_system/object/order_modifier_detail.dart';
import 'package:pos_system/object/order_payment_split.dart';
import 'package:pos_system/object/order_promotion_detail.dart';
import 'package:pos_system/object/order_tax_detail.dart';
import 'package:pos_system/object/payment_link_company.dart';
import 'package:pos_system/object/printer.dart';
import 'package:pos_system/object/printer_link_category.dart';
import 'package:pos_system/object/product.dart';
import 'package:pos_system/object/product_variant.dart';
import 'package:pos_system/object/product_variant_detail.dart';
import 'package:pos_system/object/promotion.dart';
import 'package:pos_system/object/refund.dart';
import 'package:pos_system/object/sale.dart';
import 'package:pos_system/object/second_screen.dart';
import 'package:pos_system/object/settlement.dart';
import 'package:pos_system/object/settlement_link_payment.dart';
import 'package:pos_system/object/subscription.dart';
import 'package:pos_system/object/table.dart';
import 'package:pos_system/object/tax_link_dining.dart';
import 'package:pos_system/object/transfer_owner.dart';
import 'package:pos_system/object/user.dart';
import 'package:pos_system/object/variant_group.dart';
import 'package:pos_system/object/variant_item.dart';
import 'package:pos_system/page/pos_pin.dart';
import 'package:pos_system/page/progress_bar.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:crypto/crypto.dart';
import '../database/domain.dart';
import '../notifier/theme_color.dart';
import '../object/app_setting.dart';
import '../object/branch_link_user.dart';
import '../object/checklist.dart';
import '../object/customer.dart';
import '../object/dining_option.dart';
import '../object/dynamic_qr.dart';
import '../object/receipt.dart';
import '../object/table_use.dart';
import '../object/table_use_detail.dart';
import '../object/tax.dart';
import '../utils/Utils.dart';
import 'login.dart';

class LoadingPage extends StatefulWidget {
  final int selectedDays;
  const LoadingPage({Key? key, required this.selectedDays}) : super(key: key);

  @override
  State<LoadingPage> createState() => _LoadingPageState();
}

class _LoadingPageState extends State<LoadingPage> {
  PosFirestore posFirestore = PosFirestore.instance;
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    startLoad();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeColor>(builder: (context, ThemeColor color, child) {
      return Scaffold(
        body: CustomProgressBar(),
      );
    });
  }

  startLoad() async {
    try{
      await getDateRetrieveDate();
      await getCashRecord();
      await getAllDynamicQr();
      await getSubscription();
      await getAppSettingCloud();
      await createDeviceLogin();
      await getAllChecklist();
      await getAllSecondScreen();
      await getAllKitchenList();
      await _createProductImgFolder();
      await _createBannerImgFolder();
      await getAllUser();
      await getAllAttendance();
      await getAllSettlement();
      await getBranchLinkUser();
      await getAllDiningOption();
      await getBranchLinkDiningOption();
      await getAllTax();
      await getBranchLinkTax();
      await getTaxLinkDining();
      await getAllPromotion();
      await getBranchLinkPromotion();
      await getAllCustomer();
      await getAllBill();
      await getPaymentLinkCompany();
      await getModifierGroup();
      await getModifierItem();
      await getBranchLinkModifier();
      await getTransferOwner();
      await clearCloudSyncRecord();
      await getAllReceipt();
    } catch(e) {
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
      return;
    }
    // Go to Page2 after 5s.
    Timer(Duration(seconds: 2), () {
      Navigator.push(context, MaterialPageRoute(builder: (_) => PosPinPage()));
    });
  }

  getDateRetrieveDate() async {
    final prefs = await SharedPreferences.getInstance();
    try {
      String dataRetrieveDate = '';
      String retrieveDate = '';
      if(widget.selectedDays == 0){
        dataRetrieveDate = '';
      } else if(widget.selectedDays == -1) {
        dataRetrieveDate = 'all';
      } else {
        DateTime retrieveFrom = DateTime.now().subtract(Duration(days: widget.selectedDays));
        retrieveDate = DateFormat('yyyy-MM-dd 00:00:00').format(retrieveFrom);

        final prefs = await SharedPreferences.getInstance();
        final int? branch_id = prefs.getInt('branch_id');
        final String? user = prefs.getString('user');
        Map userObject = json.decode(user!);
        Map data = await Domain().getCashRecordOBAfterDate(userObject['company_id'], branch_id.toString(), retrieveDate);

        if (data['status'] == '1') {
          List responseJson = data['data'];
          dataRetrieveDate = responseJson.first['created_at'];
        } else {
          dataRetrieveDate = '';
        }
      }
      await prefs.setString('dataRetrieveDate', dataRetrieveDate);
    } catch(e) {
      print("getDateRetrieveDate error: $e");
      FLog.error(
        className: "loading",
        text: "getDateRetrieveDate error",
        exception: e,
      );
    }
  }

/*
  get dynamic qr from cloud
*/
  getAllDynamicQr() async {
    try{
      final prefs = await SharedPreferences.getInstance();
      final int? branch_id = prefs.getInt('branch_id');
      Map data = await Domain().getDynamicQr(branch_id: branch_id.toString());
      if(data['status'] == '1'){
        List responseJson = data['data'];
        for (var i = 0; i < responseJson.length; i++) {
          DynamicQR item = DynamicQR.fromJson(responseJson[i]);
          await PosDatabase.instance.insertSqliteDynamicQR(item);
        }
      }
    }catch(e){
      print("dynamic qr insert error: $e");
      FLog.error(
        className: "loading",
        text: "dynamic qr insert failed",
        exception: "$e}",
      );
    }
  }

/*
  get subscription from cloud
*/
  getSubscription() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? user = prefs.getString('user');
      Map userObject = json.decode(user!);
      Map data = await Domain().getSubscription(userObject['company_id'].toString());
      if (data['status'] == '1') {
        List responseJson = data['subscription'];
        for (var i = 0; i < responseJson.length; i++) {
          Subscription item = Subscription.fromJson(responseJson[i]);
          Subscription subscription = Subscription(
            id: item.id,
            company_id: item.company_id,
            subscription_plan_id: item.subscription_plan_id,
            subscribe_package: item.subscribe_package,
            subscribe_fee: item.subscribe_fee,
            duration: item.duration,
            branch_amount: item.branch_amount,
            start_date: item.start_date,
            end_date: item.end_date,
            created_at: item.created_at,
            soft_delete: item.soft_delete,
          );
          try {
            await PosDatabase.instance.insertSqliteSubscription(subscription);
          } catch(e) {
            FLog.error(
              className: "loading",
              text: "subscription insert failed",
              exception: "$e\n${subscription.toJson()}",
            );
          }
        }

      }
    } catch(e) {
      print("getSubscription error: $e");
    }
  }

/*
  get app setting from cloud
*/
  getAppSettingCloud() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final int? branch_id = prefs.getInt('branch_id');
      Map data = await Domain().getAppSetting(branch_id.toString());
      if (data['status'] == '1') {
        print("App Setting: Setting Record exist in cloud");
        bool? isLocalAppSettingExisted = await PosDatabase.instance.isLocalAppSettingExisted();
        // local app setting not exists, sync from cloud
        if (!isLocalAppSettingExisted!){
          List responseJson = data['setting'];
          for (var i = 0; i < responseJson.length; i++) {
            AppSetting item = AppSetting.fromJson(responseJson[i]);
            syncAppSettingFromCloud(item);
          }
        } else {
          AppSetting? localSetting = await PosDatabase.instance.readLocalAppSetting(branch_id.toString());
          print("App Setting Sync Status: ${localSetting!.sync_status}");
          // sync status = 1, sync from cloud, if =2 ignore wait for auto sync
          if(localSetting.sync_status == 1){
            int data = await Domain().SyncAppSettingToCloud(localSetting);
            if(data == 1)
              syncAppSettingFromCloud(localSetting);
          }
        }
      } else {
        print("App Setting: No setting in cloud, create local app setting");
        getAppSettingLocal();
      }
    } catch(e) {
      print("App Setting: Sync from cloud fail1: $e");
      FLog.error(
        className: "loading",
        text: "sync app setting from cloud failed",
        exception: e,
      );
    }
  }

/*
  create app setting
*/
  getAppSettingLocal() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final int? branch_id = prefs.getInt('branch_id');
      DateFormat dateFormat = DateFormat("yyyy-MM-dd HH:mm:ss");
      String dateTime = dateFormat.format(DateTime.now());

      bool? isLocalAppSettingExisted = await PosDatabase.instance.isLocalAppSettingExisted();
      // local app setting not exists, create local
      if (!isLocalAppSettingExisted!) {
        AppSetting appSetting = AppSetting(
            branch_id: branch_id.toString(),
            open_cash_drawer: 1,
            show_second_display: 0,
            direct_payment: 0,
            print_checklist: 1,
            print_receipt: 1,
            show_sku: 0,
            qr_order_auto_accept: 0,
            enable_numbering: 0,
            starting_number: 0,
            table_order: 1,
            settlement_after_all_order_paid: 0,
            hide_dining_method_table_no: 0,
            show_product_desc: 0,
            print_cancel_receipt: 1,
            product_sort_by: 0,
            dynamic_qr_default_exp_after_hour: 1,
            variant_item_sort_by: 0,
            dynamic_qr_invalid_after_payment: 1,
            sync_status: 0,
            created_at: dateTime,
            updated_at: ''
        );
        await PosDatabase.instance.insertSqliteSetting(appSetting);
      }
    } catch(e) {
      print("App Setting: Create App Setting Fail: $e");
      FLog.error(
        className: "loading",
        text: "create app setting failed",
        exception: e,
      );
    }
  }

/*
  create app setting
*/
  syncAppSettingFromCloud(AppSetting item) async {
    AppSetting appSetting = AppSetting(
      branch_id: item.branch_id,
      open_cash_drawer: item.open_cash_drawer,
      show_second_display: item.show_second_display,
      direct_payment: item.direct_payment,
      print_checklist: item.print_checklist,
      print_receipt: item.print_receipt,
      show_sku: item.show_sku,
      qr_order_auto_accept: item.qr_order_auto_accept,
      enable_numbering: item.enable_numbering,
      starting_number: item.starting_number,
      table_order: item.table_order,
      settlement_after_all_order_paid: item.settlement_after_all_order_paid,
      hide_dining_method_table_no: item.hide_dining_method_table_no,
      show_product_desc: item.show_product_desc,
      print_cancel_receipt: item.print_cancel_receipt,
      product_sort_by: item.product_sort_by,
      dynamic_qr_default_exp_after_hour: item.dynamic_qr_default_exp_after_hour,
      variant_item_sort_by: item.variant_item_sort_by,
      dynamic_qr_invalid_after_payment: item.dynamic_qr_invalid_after_payment,
      sync_status: 1,
      created_at: item.created_at,
      updated_at: item.updated_at,
    );
    try {
      await PosDatabase.instance.insertSqliteSetting(appSetting);
      print("App Setting: Sync From Cloud Success");
    } catch(e) {
      print("App Setting: Sync From Cloud Fail: $e");
      FLog.error(
        className: "loading",
        text: "app setting insert failed",
        exception: "$e\n${appSetting.toJson()}",
      );
    }
  }

/*
  create device login
*/
  createDeviceLogin() async {
    try {
      print('device logout called');
      DateFormat dateFormat = DateFormat("yyyy-MM-dd HH:mm:ss");
      String dateTime = dateFormat.format(DateTime.now());
      final prefs = await SharedPreferences.getInstance();
      final int? device_id = prefs.getInt('device_id');

      var value = md5.convert(utf8.encode(dateTime)).toString();

      if(device_id != 4){
        Map response = await Domain().insertDeviceLogin(device_id.toString(), value);
        if (response['status'] == '1') {
          await prefs.setString('login_value', value);
        }
      } else {
        await prefs.setString('login_value', 'demo12345');
      }
    } catch(e) {
      FLog.error(
        className: "loading",
        text: "create device login failed",
        exception: e,
      );
    }
  }

  getAllChecklist() async {
    try{
      final prefs = await SharedPreferences.getInstance();
      final int? branch_id = prefs.getInt('branch_id');
      Map response = await Domain().getChecklist(branch_id.toString());
      if(response['status'] == '1'){
        List responseJson = response['data'];
        for (var i = 0; i < responseJson.length; i++) {
          try {
            await PosDatabase.instance.insertChecklist(Checklist.fromJson(responseJson[i]));
          } catch(e) {
            FLog.error(
              className: "loading",
              text: "checklist insert failed",
              exception: "$e\n${responseJson[i].toJson()}",
            );
          }
        }
      }
    } catch(e){
      print("get all checklist error: ${e}");
      FLog.error(
        className: "loading",
        text: "checklist get failed",
        exception: e,
      );
    }
  }

  getAllKitchenList() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final int? branch_id = prefs.getInt('branch_id');
      Map response = await Domain().getKitchenList(branch_id.toString());
      if (response['status'] == '1') {
        List responseJson = response['data'];
        for (var i = 0; i < responseJson.length; i++) {
          try {
            await PosDatabase.instance.insertKitchenList(KitchenList.fromJson(responseJson[i]));
          } catch(e) {
            FLog.error(
              className: "loading",
              text: "kitchen list insert failed",
              exception: "$e\n${responseJson[i].toJson()}",
            );
          }
        }
      }
    } catch(e) {
      print("get all kitchen list error: ${e}");
      FLog.error(
        className: "loading",
        text: "kitchen list get failed",
        exception: e,
      );
    }
  }

  getAllReceipt() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final int? branch_id = prefs.getInt('branch_id');
      Map response = await Domain().getReceipt(branch_id.toString());
      if (response['status'] == '1') {
        List responseJson = response['receipt'];
        for (var i = 0; i < responseJson.length; i++) {
          try {
            print("getAllRceipt called");
            print("Receiptlayout: ${jsonEncode(Receipt.fromJson(responseJson[i]))}");
            await PosDatabase.instance.insertReceipt(Receipt.fromJson(responseJson[i]));
          } catch(e) {
            FLog.error(
              className: "loading",
              text: "receipt insert failed",
              exception: "$e\n${responseJson[i].toJson()}",
            );
          }
        }
      } else if (response['status'] == '2') {
        await createReceiptLayout80();
        await createReceiptLayout58();
      }
    } catch(e) {
      print("getAllReceipt error: ${e}");
      FLog.error(
        className: "loading",
        text: "receipt get failed",
        exception: e,
      );
    }
  }

  createReceiptLayout80() async {
    try {
      DateFormat dateFormat = DateFormat("yyyy-MM-dd HH:mm:ss");
      String dateTime = dateFormat.format(DateTime.now());
      final prefs = await SharedPreferences.getInstance();
      final int? branch_id = prefs.getInt('branch_id');
      final String? branch = prefs.getString('branch');
      var branchObject = json.decode(branch!);

      Receipt data = await PosDatabase.instance.insertSqliteReceipt(Receipt(
          receipt_id: 0,
          receipt_key: '',
          branch_id: branch_id.toString(),
          header_text: branchObject['name'],
          second_header_text: '',
          footer_text: 'Thank you, please come again',
          header_image: '',
          header_image_size: 0,
          footer_image: '',
          show_address: branchObject['address'] != '' ? 1 : 0,
          show_email: branchObject['email'] != '' ? 1 : 0,
          receipt_email: branchObject['email'] != '' ? branchObject['email'] : '',
          show_break_down_price: 0,
          header_text_status: 1,
          second_header_text_status: 0,
          footer_text_status: 1,
          header_image_status: 0,
          footer_image_status: 0,
          header_font_size: 0,
          second_header_font_size: 0,
          promotion_detail_status: 0,
          paper_size: '80',
          status: 1,
          show_product_sku: 0,
          show_branch_tel: 1,
          show_register_no: 0,
          sync_status: 0,
          created_at: dateTime,
          updated_at: '',
          soft_delete: ''));
      try {
        await insertReceiptKey(data, dateTime);
      } catch(e) {
        FLog.error(
          className: "loading",
          text: "receipt layout 80mm insert failed",
          exception: "$e\n${data.toJson()}",
        );
      }
    } catch(e) {
      //Fluttertoast.showToast(backgroundColor: Color(0xFFFF0000), msg: AppLocalizations.of(context)!.translate('fail_to_add_receipt_layout_please_try_again')+" $e");
      print('$e');
      FLog.error(
        className: "loading",
        text: "createReceiptLayout80 error",
        exception: e,
      );
    }
  }

  generateReceiptKey(Receipt receipt) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final int? branch_id = prefs.getInt('branch_id');
      var bytes = receipt.created_at!.replaceAll(new RegExp(r'[^0-9]'), '') + receipt.receipt_sqlite_id.toString() + branch_id.toString();
      var md5Hash = md5.convert(utf8.encode(bytes));
      return Utils.shortHashString(hashCode: md5Hash);
    } catch(e) {
      FLog.error(
        className: "loading",
        text: "receipt key generate failed",
        exception: e,
      );
    }
  }

  insertReceiptKey(Receipt receipt, String dateTime) async {
    String receiptKey = await generateReceiptKey(receipt);
    Receipt data = Receipt(
        receipt_key: receiptKey,
        updated_at: dateTime,
        sync_status: 0,
        receipt_sqlite_id: receipt.receipt_sqlite_id);
    try {
      await PosDatabase.instance.updateReceiptUniqueKey(data);
    } catch(e) {
      FLog.error(
        className: "loading",
        text: "receipt key insert failed",
        exception: "$e\n${data.toJson()}",
      );
    }
  }

  createReceiptLayout58() async {
    try {
      DateFormat dateFormat = DateFormat("yyyy-MM-dd HH:mm:ss");
      String dateTime = dateFormat.format(DateTime.now());
      final prefs = await SharedPreferences.getInstance();
      final int? branch_id = prefs.getInt('branch_id');
      final String? branch = prefs.getString('branch');
      var branchObject = json.decode(branch!);

      Receipt data = await PosDatabase.instance.insertSqliteReceipt(Receipt(
          receipt_id: 0,
          receipt_key: '',
          branch_id: branch_id.toString(),
          header_text: branchObject['name'],
          second_header_text: '',
          footer_text: 'Thank you, please come again',
          header_image: '',
          header_image_size: 0,
          footer_image: '',
          show_address: branchObject['address'] != '' ? 1 : 0,
          show_email: branchObject['email'] != '' ? 1 : 0,
          receipt_email: branchObject['email'] != '' ? branchObject['email'] : '',
          show_break_down_price: 0,
          header_text_status: 1,
          second_header_text_status: 0,
          footer_text_status: 1,
          header_image_status: 0,
          footer_image_status: 0,
          header_font_size: 0,
          second_header_font_size: 0,
          promotion_detail_status: 0,
          paper_size: '58',
          status: 1,
          show_product_sku: 0,
          show_branch_tel: 1,
          show_register_no: 0,
          sync_status: 0,
          created_at: dateTime,
          updated_at: '',
          soft_delete: ''));
      try {
        await insertReceiptKey(data, dateTime);
      } catch(e) {
        FLog.error(
          className: "loading",
          text: "receipt layout 58mm insert failed",
          exception: "$e\n${data.toJson()}",
        );
      }
    } catch(e) {
      //Fluttertoast.showToast(backgroundColor: Color(0xFFFF0000), msg: AppLocalizations.of(context)!.translate('fail_to_add_receipt_layout_please_try_again')+" $e");
      print('$e');
      FLog.error(
        className: "loading",
        text: "createReceiptLayout58",
        exception: e,
      );
    }
  }

  clearCloudSyncRecord() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final int? branch_id = prefs.getInt('branch_id');
      await Domain().clearAllSyncRecord(branch_id.toString());
    } catch(e) {
      FLog.error(
        className: "loading",
        text: "cloud sync record create failed",
        exception: e,
      );
    }
  }

  /*
  get all second screen
*/
  getAllSecondScreen() async {
    try{
      final prefs = await SharedPreferences.getInstance();
      final int? branchId = prefs.getInt('branch_id');
      Map data = await Domain().getSecondScreen(branch_id: branchId.toString());
      if (data['status'] == '1') {
        List responseJson = data['second_screen'];
        for (var i = 0; i < responseJson.length; i++) {
          try {
            await PosDatabase.instance.insertSecondScreen(SecondScreen.fromJson(responseJson[i]));
          } catch(e) {
            FLog.error(
              className: "loading",
              text: "second screen insert failed",
              exception: "$e\n${responseJson[i].toJson()}",
            );
          }

        }
      }
    }catch(e){
      print("get all second screen error: ${e}");
      FLog.error(
        className: "loading",
        text: "get all second screen error",
        exception: e,
      );
    }
  }

/*
  sava company user to database
*/
  getAllUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? user = prefs.getString('user');
      Map userObject = json.decode(user!);
      Map data = await Domain().getAllUser(userObject['company_id']);
      if (data['status'] == '1') {
        List responseJson = data['user'];
        for (var i = 0; i < responseJson.length; i++) {
          try {
            await PosDatabase.instance.insertUser(User.fromJson(responseJson[i]));
            // if (user != '') {
            //   Navigator.of(context).pushReplacement(MaterialPageRoute(
            //     builder: (context) => PosPinPage(),
            //   ));
            // }
          } catch(e) {
            FLog.error(
              className: "loading",
              text: "user create failed",
              exception: "$e\n${responseJson[i].toJson()}",
            );
          }
        }
      }
    } catch(e) {
      FLog.error(
        className: "loading",
        text: "get all user error",
        exception: e,
      );
    }
  }

/*
  sava attendance to database
*/
  getAllAttendance() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final int? branch_id = prefs.getInt('branch_id');
      final String? dataRetrieveDate = prefs.getString('dataRetrieveDate');
      Map data;

      if(dataRetrieveDate != '') {
        if(dataRetrieveDate == 'all')
          data = await Domain().getAllAttendance(branch_id.toString());
        else
          data = await Domain().getAllAttendanceAfterDate(branch_id.toString(), dataRetrieveDate);

        if (data['status'] == '1') {
          List responseJson = data['data'];
          for (var i = 0; i < responseJson.length; i++) {
            try {
              Attendance item = Attendance.fromJson(responseJson[i]);
              Attendance attendance = Attendance(
                attendance_key: item.attendance_key,
                branch_id: item.branch_id,
                user_id: item.user_id,
                role: item.role,
                clock_in_at: item.clock_in_at,
                clock_out_at: item.clock_out_at,
                duration: item.duration,
                sync_status: 1,
                created_at: item.created_at,
                updated_at: item.updated_at,
                soft_delete: item.soft_delete,
              );
              await PosDatabase.instance.insertAttendance(attendance);
            } catch(e) {
              FLog.error(
                className: "loading",
                text: "attendance create failed",
                exception: "$e\n${responseJson[i].toJson()}",
              );
            }
          }
        }
      }
    } catch(e) {
      FLog.error(
        className: "loading",
        text: "get all attendance error",
        exception: e,
      );
    }
  }

/*
  save branch link user table to database
*/
  getBranchLinkUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final int? branch_id = prefs.getInt('branch_id');
      Map data = await Domain().getBranchLinkUser(branch_id.toString());
      if (data['status'] == '1') {
        List responseJson = data['user'];
        for (var i = 0; i < responseJson.length; i++) {
          try {
            await PosDatabase.instance.insertBranchLinkUser(BranchLinkUser.fromJson(responseJson[i]));
          } catch(e) {
            FLog.error(
              className: "loading",
              text: "branch link user insert failed",
              exception: "$e\n${responseJson[i].toJson()}",
            );
          }
        }
      }
    } catch(e) {
      FLog.error(
        className: "loading",
        text: "get branch link user error",
        exception: e,
      );
    }
  }

/*
  save settlement to database
*/
  getAllSettlement() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final int? branch_id = prefs.getInt('branch_id');
      final String? user = prefs.getString('user');
      final String? dataRetrieveDate = prefs.getString('dataRetrieveDate');
      Map userObject = json.decode(user!);
      Map data;

      if(dataRetrieveDate != '') {
        if(dataRetrieveDate == 'all')
          data = await Domain().getSettlement(userObject['company_id'], branch_id.toString());
        else
          data = await Domain().getSettlementAfterDate(userObject['company_id'], branch_id.toString(), dataRetrieveDate);

        if (data['status'] == '1') {
          List responseJson = data['settlement'];
          for (var i = 0; i < responseJson.length; i++) {
            Settlement item = Settlement.fromJson(responseJson[i]);
            try {
              await PosDatabase.instance.insertSettlement(Settlement(
                settlement_id: item.settlement_id,
                settlement_key: item.settlement_key,
                company_id: item.company_id,
                branch_id: item.branch_id,
                total_bill: item.total_bill,
                total_sales: item.total_sales,
                total_refund_bill: item.total_refund_bill,
                total_refund_amount: item.total_refund_amount,
                total_discount: item.total_discount,
                total_cancellation: item.total_cancellation,
                total_charge: item.total_charge,
                total_tax: item.total_tax,
                settlement_by_user_id: item.settlement_by_user_id,
                settlement_by: item.settlement_by,
                status: item.status,
                sync_status: 1,
                opened_at: item.opened_at,
                created_at: item.created_at,
                updated_at: item.updated_at,
                soft_delete: item.soft_delete,
              ));
            } catch(e) {
              FLog.error(
                className: "loading",
                text: "settlement insert failed (settlement_id: ${item.settlement_id})",
                exception: "$e\n${responseJson[i].toJson()}",
              );
            }
          }
          await getAllOrder();
          getAllTable();
          getSettlementLinkPayment();
        } else {
          await getAllOrder();
          getAllTable();
          getSettlementLinkPayment();
        }
      } else {
        await getAllOrder();
        getAllTable();
        getSettlementLinkPayment();
      }
    } catch(e) {
      FLog.error(
        className: "loading",
        text: "settlement get error",
        exception: e,
      );
    }
  }

/*
  save branch table to database
*/
  getAllTable() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final int? branch_id = prefs.getInt('branch_id');
      final String? dataRetrieveDate = prefs.getString('dataRetrieveDate');
      Map data = await Domain().getAllTable(branch_id.toString());
      if (data['status'] == '1') {
        List responseJson = data['table'];
        for (var i = 0; i < responseJson.length; i++) {
          try {
            PosTable item = PosTable.fromJson(responseJson[i]);
            // PosTable table = await PosDatabase.instance.insertPosTable(PosTable.fromJson(responseJson[i]));
            PosTable table = await PosDatabase.instance.insertPosTable(PosTable(
              table_id: item.table_id,
              table_url: item.table_url,
              branch_id: item.branch_id,
              number: item.number,
              seats: item.seats,
              status: dataRetrieveDate == '' ? 0 : item.status,
              table_use_detail_key: dataRetrieveDate == '' ? '' : item.table_use_detail_key,
              table_use_key: dataRetrieveDate == '' ? '' : item.table_use_key,
              sync_status: 1,
              dx: item.dx,
              dy: item.dy,
              created_at: item.created_at,
              updated_at: item.updated_at,
              soft_delete: item.soft_delete,
            ));
            posFirestore.insertPosTable(table);
          } catch(e) {
            FLog.error(
              className: "loading",
              text: "table insert failed",
              exception: "$e\n${responseJson[i].toJson()}",
            );
          }
        }
        await getAllTableUse();
        getAllCategory();
      } else {
        await getAllTableUse();
        getAllCategory();
      }
    } catch(e) {
      FLog.error(
        className: "loading",
        text: "getAllTable error",
        exception: e,
      );
    }

  }

/*
  save categories to database
*/
  getAllCategory() async {
    try {
      print("getAllCategory called");
      final prefs = await SharedPreferences.getInstance();
      final String? user = prefs.getString('user');
      Map userObject = json.decode(user!);
      Map data = await Domain().getAllCategory(userObject['company_id']);
      if (data['status'] == '1') {
        List responseJson = data['categories'];
        for (var i = 0; i < responseJson.length; i++) {
          try {
            Categories data = await PosDatabase.instance.insertCategories(Categories.fromJson(responseJson[i]));
            posFirestore.insertCategory(data);
          } catch(e) {
            FLog.error(
              className: "loading",
              text: "categories insert failed",
              exception: "$e\n${responseJson[i].toJson()}",
            );
          }
        }
        getAllProduct();
        getAllPrinter();
      } else {
        getAllProduct();
        getAllPrinter();
      }
    } catch(e) {
      FLog.error(
        className: "loading",
        text: "getAllCategory error",
        exception: e,
      );
    }
  }

/*
  save printer to local database
*/
  getAllPrinter() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final int? branch_id = prefs.getInt('branch_id');
      Map data = await Domain().getPrinter(branch_id.toString());
      if (data['status'] == '1') {
        List responseJson = data['printer'];
        for (var i = 0; i < responseJson.length; i++) {
          Printer printerItem = Printer.fromJson(responseJson[i]);
          try {
            await PosDatabase.instance.insertPrinter(Printer(
                printer_id: printerItem.printer_id,
                printer_key: printerItem.printer_key,
                branch_id: printerItem.branch_id,
                company_id: printerItem.company_id,
                printer_link_category_id: '',
                value: printerItem.value,
                type: printerItem.type,
                printer_label: printerItem.printer_label,
                paper_size: printerItem.paper_size,
                printer_status: printerItem.printer_status,
                is_counter: printerItem.is_counter,
                is_kitchen_checklist: printerItem.is_kitchen_checklist,
                is_label: printerItem.is_label,
                sync_status: 1,
                created_at: printerItem.created_at,
                updated_at: printerItem.updated_at,
                soft_delete: printerItem.soft_delete));
          } catch(e) {
            FLog.error(
              className: "loading",
              text: "printer insert failed",
              exception: "$e\n${responseJson[i].toJson()}",
            );
          }
        }
        getAllPrinterLinkCategory();
      }
    } catch(e) {
      print("getAllPrinter error: ${e}");
      FLog.error(
        className: "loading",
        text: "getAllPrinter error",
        exception: e,
      );
    }
  }

/*
  save printer category to database
*/
  getAllPrinterLinkCategory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final int? branch_id = prefs.getInt('branch_id');
      Map data = await Domain().getPrinterCategory(branch_id.toString());
      if (data['status'] == '1') {
        List responseJson = data['printer'];
        for (var i = 0; i < responseJson.length; i++) {
          PrinterLinkCategory item = PrinterLinkCategory.fromJson(responseJson[i]);
          Printer printer = await PosDatabase.instance.readPrinterSqliteID(item.printer_key!);
          Categories? categories = await PosDatabase.instance.readCategorySqliteID(item.category_id!);
          try {
            await PosDatabase.instance.insertPrinterCategory(PrinterLinkCategory(
              printer_link_category_key: item.printer_link_category_key,
              printer_link_category_id: item.printer_link_category_id,
              printer_sqlite_id: printer.printer_sqlite_id.toString(),
              printer_key: item.printer_key,
              category_sqlite_id: categories != null ? categories.category_sqlite_id.toString() : '0',
              category_id: item.category_id,
              sync_status: 1,
              created_at: item.created_at,
              updated_at: item.updated_at,
              soft_delete: item.soft_delete,
            ));
          } catch(e) {
            FLog.error(
              className: "loading",
              text: "printer category insert failed (${item.printer_link_category_id} })",
              exception: "$e\n${responseJson[i].toJson()}",
            );
          }
        }
      }
    } catch(e) {
      FLog.error(
        className: "loading",
        text: "getAllPrinterLinkCategory error",
        exception: e,
      );
    }
  }

/*
  save product to database
*/
  getAllProduct() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? user = prefs.getString('user');
      Map userObject = json.decode(user!);
      Map data = await Domain().getAllProduct(userObject['company_id']);
      // print('product status: ${data['status']}');
      if (data['status'] == '1') {
        print('product status: ${data['status']}');
        List responseJson = data['product'];
        for (var i = 0; i < responseJson.length; i++) {
          Product productItem = Product.fromJson(responseJson[i]);
          Categories? categoryData = await PosDatabase.instance.readCategorySqliteID(productItem.category_id!);
          try {
            Product data = await PosDatabase.instance.insertProduct(Product(
                product_id: productItem.product_id,
                category_id: productItem.category_id,
                category_sqlite_id: categoryData != null ? categoryData.category_sqlite_id.toString() : '0',
                company_id: productItem.company_id,
                name: productItem.name,
                price: productItem.price,
                description: productItem.description,
                SKU: productItem.SKU,
                image: productItem.image,
                has_variant: productItem.has_variant,
                stock_type: productItem.stock_type,
                stock_quantity: productItem.stock_quantity,
                available: productItem.available,
                graphic_type: productItem.graphic_type,
                color: productItem.color,
                daily_limit: productItem.daily_limit,
                daily_limit_amount: productItem.daily_limit_amount,
                unit: productItem.unit,
                per_quantity_unit: productItem.per_quantity_unit,
                sequence_number: productItem.sequence_number,
                allow_ticket: productItem.allow_ticket,
                ticket_count: productItem.ticket_count,
                ticket_exp: productItem.ticket_exp,
                show_in_qr: productItem.show_in_qr ?? 1,
                sync_status: 1,
                created_at: productItem.created_at,
                updated_at: productItem.updated_at,
                soft_delete: productItem.soft_delete));
            posFirestore.insertProduct(data);
          } catch(e) {
            FLog.error(
              className: "loading",
              text: "product insert failed (${productItem.product_id})",
              exception: "$e\n${responseJson[i].toJson()}",
            );
          }
        }
        getModifierLinkProduct();
        getVariantGroup();
      }
    } catch(e) {
      print("getAllProduct error: ${e}");
      FLog.error(
        className: "loading",
        text: "getAllProduct error",
        exception: e,
      );
    }

  }

/*
  save dining option to database
*/
  getAllDiningOption() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? user = prefs.getString('user');
      Map userObject = json.decode(user!);
      Map data = await Domain().getAllDiningOption(userObject['company_id']);
      if (data['status'] == '1') {
        List responseJson = data['dining_option'];
        for (var i = 0; i < responseJson.length; i++) {
          try {
            DiningOption data = await PosDatabase.instance.insertDiningOption(DiningOption.fromJson(responseJson[i]));
            posFirestore.insertDiningOption(data);
          } catch(e) {
            FLog.error(
              className: "loading",
              text: "dining option insert failed",
              exception: "$e\n${responseJson[i].toJson()}",
            );
          }
        }
      }
    } catch(e) {
      FLog.error(
        className: "loading",
        text: "getAllDiningOption error",
        exception: e,
      );
    }
  }

/*
  save branch link dining option to database
*/
  getBranchLinkDiningOption() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final int? branch_id = prefs.getInt('branch_id');
      Map data = await Domain().getBranchLinkDiningOption(branch_id.toString());
      if (data['status'] == '1') {
        List responseJson = data['dining_option'];
        for (var i = 0; i < responseJson.length; i++) {
          try {
            BranchLinkDining data = await PosDatabase.instance.insertBranchLinkDining(BranchLinkDining.fromJson(responseJson[i]));
            posFirestore.insertBranchLinkDining(data);
          } catch(e) {
            FLog.error(
              className: "loading",
              text: "branch link dining insert failed",
              exception: "$e\n${responseJson[i].toJson()}",
            );
          }
        }
      }
    } catch(e) {
      FLog.error(
        className: "loading",
        text: "getBranchLinkDiningOption error",
        exception: e,
      );
    }
  }

/*
  save tax to database
*/
  getAllTax() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? user = prefs.getString('user');
      Map userObject = json.decode(user!);
      Map data = await Domain().getAllTax(userObject['company_id']);
      if (data['status'] == '1') {
        List responseJson = data['tax'];
        for (var i = 0; i < responseJson.length; i++) {
          try {
            await PosDatabase.instance.insertTax(Tax.fromJson(responseJson[i]));
          } catch(e) {
            FLog.error(
              className: "loading",
              text: "tax insert error",
              exception: "$e\n${responseJson[i].toJson()}",
            );
          }
        }
      }
    } catch(e) {
      FLog.error(
        className: "loading",
        text: "getAllTax error",
        exception: e,
      );
    }
  }

/*
  save branch link tax to database
*/
  getBranchLinkTax() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final int? branch_id = prefs.getInt('branch_id');
      Map data = await Domain().getBranchLinkTax(branch_id.toString());
      if (data['status'] == '1') {
        List responseJson = data['tax'];
        for (var i = 0; i < responseJson.length; i++) {
          try {
            BranchLinkTax data = await PosDatabase.instance.insertBranchLinkTax(BranchLinkTax.fromJson(responseJson[i]));
            posFirestore.insertBranchLinkTax(data);
          } catch(e) {
            FLog.error(
              className: "loading",
              text: "branch link tax insert error",
              exception: "$e\n${responseJson[i].toJson()}",
            );
          }
        }
      }
    } catch(e) {
      FLog.error(
        className: "loading",
        text: "getBranchLinkTax error",
        exception: e,
      );
    }
  }

/*
  save tax link dining to database
*/
  getTaxLinkDining() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final int? branch_id = prefs.getInt('branch_id');
      Map data = await Domain().getTaxLinkDining(branch_id.toString());
      if (data['status'] == '1') {
        List responseJson = data['tax'];
        for (var i = 0; i < responseJson.length; i++) {
          try {
            await PosDatabase.instance.insertTaxLinkDining(TaxLinkDining.fromJson(responseJson[i]));
          } catch(e) {
            FLog.error(
              className: "loading",
              text: "tax link dining error",
              exception: "$e\n${responseJson[i].toJson()}",
            );
          }
        }
      }
    } catch(e) {
      FLog.error(
        className: "loading",
        text: "getTaxLinkDining error",
        exception: e,
      );
    }
  }

/*
  save promotion to database
*/
  getAllPromotion() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? user = prefs.getString('user');
      Map userObject = json.decode(user!);
      Map data = await Domain().getAllPromotion(userObject['company_id']);
      if (data['status'] == '1') {
        List responseJson = data['promotion'];
        for (var i = 0; i < responseJson.length; i++) {
          try {
            await PosDatabase.instance.insertPromotion(Promotion.fromJson(responseJson[i]));
          } catch(e) {
            FLog.error(
              className: "loading",
              text: "promotion insert error",
              exception: "$e\n${responseJson[i].toJson()}",
            );
          }
        }
      }
    } catch(e) {
      FLog.error(
        className: "loading",
        text: "getAllPromotion error",
        exception: e,
      );
    }
  }

/*
  save branch link promotion to database
*/
  getBranchLinkPromotion() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final int? branch_id = prefs.getInt('branch_id');
      Map data = await Domain().getBranchLinkPromotion(branch_id.toString());
      if (data['status'] == '1') {
        List responseJson = data['promotion'];
        for (var i = 0; i < responseJson.length; i++) {
          try {
            BranchLinkPromotion data = await PosDatabase.instance.insertBranchLinkPromotion(BranchLinkPromotion.fromJson(responseJson[i]));
            posFirestore.insertBranchLinkPromotion(data);
          } catch(e) {
            FLog.error(
              className: "loading",
              text: "branch link promotion error",
              exception: "$e\n${responseJson[i].toJson()}",
            );
          }
        }
      }
    } catch(e) {
      FLog.error(
        className: "loading",
        text: "getBranchLinkPromotion error",
        exception: e,
      );
    }
  }

/*
  save customer to database
*/
  getAllCustomer() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? user = prefs.getString('user');
      Map userObject = json.decode(user!);
      Map data = await Domain().getAllCustomer(userObject['company_id']);
      if (data['status'] == '1') {
        List responseJson = data['customer'];
        for (var i = 0; i < responseJson.length; i++) {
          try {
            await PosDatabase.instance.insertCustomer(Customer.fromJson(responseJson[i]));
          } catch(e) {
            FLog.error(
              className: "loading",
              text: "customer insert error",
              exception: "$e\n${responseJson[i].toJson()}",
            );
          }
        }
      }
    } catch(e) {
      FLog.error(
        className: "loading",
        text: "getAllCustomer error",
        exception: e,
      );
    }
  }

/*
  save bill to database
*/
  getAllBill() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? user = prefs.getString('user');
      final int? branch_id = prefs.getInt('branch_id');
      Map userObject = json.decode(user!);
      Map data = await Domain().getAllBill(userObject['company_id'], branch_id.toString());
      if (data['status'] == '1') {
        List responseJson = data['bill'];
        for (var i = 0; i < responseJson.length; i++) {
          try {
            await PosDatabase.instance.insertBill(Bill.fromJson(responseJson[i]));
          } catch(e) {
            FLog.error(
              className: "loading",
              text: "bill insert failed",
              exception: "$e\n${responseJson[i].toJson()}",
            );
          }
        }
      }
    } catch(e) {
      FLog.error(
        className: "loading",
        text: "getAllBill error",
        exception: e,
      );
    }
  }

/*
  save payment option to database
*/
  getPaymentLinkCompany() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? user = prefs.getString('user');
      Map userObject = json.decode(user!);
      Map data = await Domain().getPaymentLinkCompany(userObject['company_id']);
      if (data['status'] == '1') {
        List responseJson = data['payment'];
        for (var i = 0; i < responseJson.length; i++) {
          PaymentLinkCompany object = PaymentLinkCompany.fromJson(responseJson[i]);
          try {
            PaymentLinkCompany data = await PosDatabase.instance.insertPaymentLinkCompany(object);
            if(object.soft_delete == ''){
              await _createPaymentImgFolder(paymentLinkCompany: data);
            }
          } catch(e) {
            FLog.error(
              className: "loading",
              text: " error",
              exception: "$e\n${object.toJson()}",
            );
          }
        }
      }
    } catch(e) {
      FLog.error(
        className: "loading",
        text: "getPaymentLinkCompany error",
        exception: e,
      );
    }
  }

/*
  create payment link company image folder
*/
  _createPaymentImgFolder({required PaymentLinkCompany paymentLinkCompany}) async {
    try {
      final folderName = paymentLinkCompany.payment_link_company_id.toString();
      final directory = await _localPath;
      final path = '$directory/assets/payment_qr/$folderName';
      final pathImg = Directory(path);
      await pathImg.create();
      if(paymentLinkCompany.image_name != null && paymentLinkCompany.image_name != ''){
        downloadPaymentImage(path, paymentLinkCompany);
      }
    } catch(e) {
      FLog.error(
        className: "loading",
        text: "_createPaymentImgFolder error",
        exception: e,
      );
    }
  }

/*
  download payment image
*/
  downloadPaymentImage(String path, PaymentLinkCompany paymentLinkCompany) async {
    try{
      final prefs = await SharedPreferences.getInstance();
      final String? user = prefs.getString('user');
      Map userObject = json.decode(user!);
      String url = '';
      String paymentLinkCompanyId =  paymentLinkCompany.payment_link_company_id.toString();
      String name = paymentLinkCompany.image_name!;
      url = '${Domain.backend_domain}api/payment_QR/' + userObject['company_id'] + '/' + paymentLinkCompanyId + '/' + name;
      final response = await http.get(Uri.parse(url));
      var localPath = path + '/' + name;
      final imageFile = File(localPath);
      await imageFile.writeAsBytes(response.bodyBytes);
    } catch(e){
      print("download payment image error: ${e}");
      FLog.error(
        className: "loading",
        text: "download payment image error",
        exception: e,
      );
      return;
    }
  }

/*
  save refund to database
*/
  getAllRefund() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? user = prefs.getString('user');
      final int? branch_id = prefs.getInt('branch_id');
      final String? dataRetrieveDate = prefs.getString('dataRetrieveDate');
      Map userObject = json.decode(user!);
      Map data;

      if(dataRetrieveDate != '') {
        if(dataRetrieveDate == 'all')
          data = await Domain().getAllRefund(userObject['company_id'], branch_id.toString());
        else
          data = await Domain().getAllRefundAfterDate(userObject['company_id'], branch_id.toString(), dataRetrieveDate);

        if (data['status'] == '1') {
          List responseJson = data['refund'];
          for (var i = 0; i < responseJson.length; i++) {
            Order? orderData = await PosDatabase.instance.readOrderSqliteID(responseJson[i]['order_key']);
            Refund data = await PosDatabase.instance.insertRefund(Refund(
              refund_id: responseJson[i]['refund_id'],
              refund_key: responseJson[i]['refund_key'],
              company_id: responseJson[i]['company_id'],
              branch_id: responseJson[i]['branch_id'],
              order_cache_sqlite_id: '',
              order_cache_key: '',
              order_sqlite_id: orderData != null ? orderData.order_sqlite_id.toString() : '',
              order_key: responseJson[i]['order_key'],
              refund_by: responseJson[i]['refund_by'],
              refund_by_user_id: responseJson[i]['refund_by_user_id'],
              bill_id: responseJson[i]['bill_id'],
              sync_status: 1,
              created_at: responseJson[i]['created_at'],
              updated_at: responseJson[i]['updated_at'],
              soft_delete: responseJson[i]['soft_delete'],
            ));
            try {
              if(orderData != null) {
                updateOrderRefundSqliteId(data.refund_sqlite_id.toString(), orderData.order_sqlite_id!);
              }
            } catch(e) {
              FLog.error(
                className: "loading",
                text: "refund insert failed (refund_id: ${responseJson[i]['refund_id']})",
                exception: "$e\n${data.toJson()}",
              );
            }
          }
        }
      }
    } catch(e) {
      FLog.error(
        className: "loading",
        text: "getAllRefund error",
        exception: e,
      );
    }
  }

/*
  save refund local id into order
*/
  updateOrderRefundSqliteId(String refundLocalId, int orderLocalId) async {
    Order order = Order(refund_sqlite_id: refundLocalId, order_sqlite_id: orderLocalId);
    try {
      await PosDatabase.instance.updateOrderRefundSqliteId(order);
    } catch(e) {
      FLog.error(
        className: "loading",
        text: "order refund qqlite id update failed (${refundLocalId})",
        exception: "$e\n${order.toJson()}",
      );
    }
  }

/*
  save modifier group to database
*/
  getModifierGroup() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? user = prefs.getString('user');
      Map userObject = json.decode(user!);
      Map data = await Domain().getModifierGroup(userObject['company_id']);
      if (data['status'] == '1') {
        List responseJson = data['modifier'];
        for (var i = 0; i < responseJson.length; i++) {
          try {
            ModifierGroup data = await PosDatabase.instance.insertModifierGroup(ModifierGroup.fromJson(responseJson[i]));
            posFirestore.insertModifierGroup(data);
          } catch(e) {
            FLog.error(
              className: "loading",
              text: "modifier group insert failed",
              exception: "$e\n${responseJson[i].toJson()}",
            );
          }
        }
      }
    } catch(e) {
      FLog.error(
        className: "loading",
        text: "getModifierGroup error",
        exception: e,
      );
    }
  }

/*
  save modifier item to database
*/
  getModifierItem() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? user = prefs.getString('user');
      Map userObject = json.decode(user!);
      Map data = await Domain().getModifierItem(userObject['company_id']);
      if (data['status'] == '1') {
        List responseJson = data['modifier'];
        for (var i = 0; i < responseJson.length; i++) {
          try {
            ModifierItem data = await PosDatabase.instance.insertModifierItem(ModifierItem.fromJson(responseJson[i]));
            posFirestore.insertModifierItem(data);
          } catch(e) {
            FLog.error(
              className: "loading",
              text: "modifier item insert error",
              exception: "$e\n${responseJson[i].toJson()}",
            );
          }
        }
      }
    } catch(e) {
      FLog.error(
        className: "loading",
        text: "getModifierItem error",
        exception: e,
      );
    }
  }

/*
  save branch link modifier to database
*/
  getBranchLinkModifier() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final int? branch_id = prefs.getInt('branch_id');
      Map data = await Domain().getBranchLinkModifier(branch_id.toString());
      if (data['status'] == '1') {
        List responseJson = data['modifier'];
        for (var i = 0; i < responseJson.length; i++) {
          try {
            BranchLinkModifier data = await PosDatabase.instance.insertBranchLinkModifier(BranchLinkModifier.fromJson(responseJson[i]));
            posFirestore.insertBranchLinkModifier(data);
          } catch(e) {
            FLog.error(
              className: "loading",
              text: " error",
              exception: "$e\n${responseJson[i].toJson()}",
            );
          }
        }
      }
    } catch(e) {
      FLog.error(
        className: "loading",
        text: "getBranchLinkModifier error",
        exception: e,
      );
    }
  }

/*
  save branch link product to database
*/
  getBranchLinkProduct() async {
    try {
      print('branch link product called!!!');
      final prefs = await SharedPreferences.getInstance();
      final int? branch_id = prefs.getInt('branch_id');
      Map data = await Domain().getBranchLinkProduct(branch_id.toString());
      print('branch link product status: ${data['status']}');
      if (data['status'] == '1') {
        List responseJson = data['product'];
        for (var i = 0; i < responseJson.length; i++) {
          BranchLinkProduct branchLinkProductData = BranchLinkProduct.fromJson(responseJson[i]);
          Product? productData = await PosDatabase.instance.readProductSqliteID(branchLinkProductData.product_id!);
          ProductVariant? productVariantData = await PosDatabase.instance.readProductVariantSqliteID(branchLinkProductData.product_variant_id!);
          try {
            BranchLinkProduct data = await PosDatabase.instance.insertBranchLinkProduct(BranchLinkProduct(
                branch_link_product_id: branchLinkProductData.branch_link_product_id,
                branch_id: branchLinkProductData.branch_id,
                product_sqlite_id: productData!.product_sqlite_id.toString(),
                product_id: branchLinkProductData.product_id,
                has_variant: branchLinkProductData.has_variant,
                product_variant_sqlite_id: productVariantData != null ? productVariantData.product_variant_sqlite_id.toString() : '0',
                product_variant_id: branchLinkProductData.product_variant_id,
                b_SKU: branchLinkProductData.b_SKU,
                price: branchLinkProductData.price,
                stock_type: branchLinkProductData.stock_type,
                daily_limit: branchLinkProductData.daily_limit,
                daily_limit_amount: branchLinkProductData.daily_limit_amount,
                stock_quantity: branchLinkProductData.stock_quantity,
                sync_status: 1,
                created_at: branchLinkProductData.created_at,
                updated_at: branchLinkProductData.updated_at,
                soft_delete: branchLinkProductData.soft_delete));
            posFirestore.insertBranchLinkProduct(data);
          } catch(e) {
            FLog.error(
              className: "loading",
              text: "branch link product insert failed (branch_link_product_id: ${branchLinkProductData.branch_link_product_id})",
              exception: "$e\n${branchLinkProductData.toJson()}",
            );
          }
        }
        getAllOrderCache();
      } else {
        getAllOrderCache();
      }
    } catch(e) {
      FLog.error(
        className: "loading",
        text: "getBranchLinkProduct error",
        exception: e,
      );
    }
  }

/*
  sava table use to database
*/
  getAllTableUse() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final int? branch_id = prefs.getInt('branch_id');
      final String? dataRetrieveDate = prefs.getString('dataRetrieveDate');
      Map data;

      if(dataRetrieveDate != '') {
        if(dataRetrieveDate == 'all')
          data = await Domain().getAllTableUse(branch_id.toString());
        else
          data = await Domain().getAllTableUseAfterDate(branch_id.toString(), dataRetrieveDate);

        if (data['status'] == '1') {
          List responseJson = data['table_use'];
          for (var i = 0; i < responseJson.length; i++) {
            TableUse item = TableUse.fromJson(responseJson[i]);
            try {
              await PosDatabase.instance.insertTableUse(TableUse(
                table_use_id: item.table_use_id,
                table_use_key: item.table_use_key,
                branch_id: item.branch_id,
                order_cache_key: item.order_cache_key,
                card_color: item.card_color,
                status: item.status,
                sync_status: 1,
                created_at: item.created_at,
                updated_at: item.updated_at,
                soft_delete: item.soft_delete,
              ));
            } catch(e) {
              FLog.error(
                className: "loading",
                text: "getAllTableUse error",
                exception: "$e\n${item.toJson()}",
              );
            }
          }
          getAllTableUseDetail();
        }
      }
    } catch(e) {
      FLog.error(
        className: "loading",
        text: "getAllTableUse error",
        exception: e,
      );
    }
  }

/*
  sava table use detail to database
*/
  getAllTableUseDetail() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final int? branch_id = prefs.getInt('branch_id');
      final String? dataRetrieveDate = prefs.getString('dataRetrieveDate');
      Map data;

      if(dataRetrieveDate != '') {
        if(dataRetrieveDate == 'all')
          data = await Domain().getAllTableUseDetail(branch_id.toString());
        else
          data = await Domain().getAllTableUseDetailAfterDate(branch_id.toString(), dataRetrieveDate);

        if (data['status'] == '1') {
          List responseJson = data['table_use'];
          for (var i = 0; i < responseJson.length; i++) {
            TableUseDetail item = TableUseDetail.fromJson(responseJson[i]);
            TableUse? tableUseData = await PosDatabase.instance.readTableUseSqliteID(item.table_use_key!);
            PosTable tableData = await PosDatabase.instance.readTableByCloudId(item.table_id.toString());
            try {
              await PosDatabase.instance.insertTableUseDetail(TableUseDetail(
                  table_use_detail_id: item.table_use_detail_id,
                  table_use_detail_key: item.table_use_detail_key,
                  table_use_sqlite_id: tableUseData != null ? tableUseData.table_use_sqlite_id.toString() : '0',
                  table_use_key: item.table_use_key,
                  table_sqlite_id: tableData.table_sqlite_id.toString(),
                  table_id: item.table_id,
                  status: item.status,
                  sync_status: 1,
                  created_at: item.created_at,
                  updated_at: item.updated_at,
                  soft_delete: item.soft_delete));
            } catch(e) {
              FLog.error(
                className: "loading",
                text: "table user detail insert failed (table_use_detail_id: ${item.table_use_detail_id})",
                exception: "$e\n${item.toJson()}",
              );
            }
          }
        }
      }
    } catch(e) {
      FLog.error(
        className: "loading",
        text: "getAllTableUseDetail error",
        exception: e,
      );
    }
  }

/*
  save modifier link product to database
*/
  getModifierLinkProduct() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final int? branch_id = prefs.getInt('branch_id');
      final String? user = prefs.getString('user');
      Map userObject = json.decode(user!);
      Map data = await Domain().getModifierLinkProduct(userObject['company_id'], branch_id.toString());
      if (data['status'] == '1') {
        List responseJson = data['product'];
        for (var i = 0; i < responseJson.length; i++) {
          ModifierLinkProduct modData = ModifierLinkProduct.fromJson(responseJson[i]);
          Product? productData = await PosDatabase.instance.readProductSqliteID(modData.product_id!);
          try {
            ModifierLinkProduct data = await PosDatabase.instance.insertModifierLinkProduct(ModifierLinkProduct(
              modifier_link_product_id: modData.modifier_link_product_id,
              mod_group_id: modData.mod_group_id,
              product_id: modData.product_id,
              product_sqlite_id: productData!.product_sqlite_id.toString(),
              sync_status: 1,
              created_at: modData.created_at,
              updated_at: modData.updated_at,
              soft_delete: modData.soft_delete,
            ));
            posFirestore.insertModifierLinkProduct(data);
          } catch(e) {
            FLog.error(
              className: "loading",
              text: "modifier link product insert failed (modifier_link_product_id: ${modData.modifier_link_product_id})",
              exception: "$e\n${modData.toJson()}",
            );
          }
        }
      }
    } catch(e) {
      FLog.error(
        className: "loading",
        text: "getModifierLinkProduct error",
        exception: e,
      );
    }
  }


/*
  save variant group to database
*/
  getVariantGroup() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? user = prefs.getString('user');
      Map userObject = json.decode(user!);
      Map data = await Domain().getVariantGroup(userObject['company_id']);
      if (data['status'] == '1') {
        List responseJson = data['variant'];
        for (var i = 0; i < responseJson.length; i++) {
          VariantGroup variantData = VariantGroup.fromJson(responseJson[i]);
          Product? productData = await PosDatabase.instance.readProductSqliteID(variantData.product_id!);
          try {
            VariantGroup data = await PosDatabase.instance.insertVariantGroup(VariantGroup(
                child: [],
                variant_group_id: variantData.variant_group_id,
                product_id: variantData.product_id,
                product_sqlite_id: productData!.product_sqlite_id.toString(),
                name: variantData.name,
                sync_status: 1,
                created_at: variantData.created_at,
                updated_at: variantData.updated_at,
                soft_delete: variantData.soft_delete));
            //insert firebase
            posFirestore.insertVariantGroup(data);
          } catch(e) {
            FLog.error(
              className: "loading",
              text: "variant group insert failed (variant_group_id: ${variantData.variant_group_id})",
              exception: "$e\n${variantData.toJson()}",
            );
          }
        }
        getVariantItem();
      } else {
        getBranchLinkProduct();
      }
    } catch(e) {
      FLog.error(
        className: "loading",
        text: "getVariantGroup error",
        exception: e,
      );
    }
  }

/*
  save variant item to database
*/
  getVariantItem() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? user = prefs.getString('user');
      Map userObject = json.decode(user!);
      Map data = await Domain().getVariantItem(userObject['company_id']);
      if (data['status'] == '1') {
        List responseJson = data['variant'];
        for (var i = 0; i < responseJson.length; i++) {
          VariantItem variantItemData = VariantItem.fromJson(responseJson[i]);
          VariantGroup? variantGroupData = await PosDatabase.instance.readVariantGroupSqliteID(variantItemData.variant_group_id!);
          try {
            VariantItem data = await PosDatabase.instance.insertVariantItem(VariantItem(
                variant_item_id: variantItemData.variant_item_id,
                variant_group_id: variantItemData.variant_group_id,
                variant_group_sqlite_id: variantGroupData != null ? variantGroupData.variant_group_sqlite_id.toString() : '0',
                name: variantItemData.name,
                sync_status: 1,
                created_at: variantItemData.created_at,
                updated_at: variantItemData.updated_at,
                soft_delete: variantItemData.soft_delete));
            //insert firebase
            posFirestore.insertVariantItem(data);
          } catch(e) {
            FLog.error(
              className: "loading",
              text: "variant item insert failed (variant_item_id: ${variantItemData.variant_item_id})",
              exception: "$e\n${variantItemData.toJson()}",
            );
          }
        }
        getProductVariant();
      } else {
        getBranchLinkProduct();
      }
    } catch(e) {
      FLog.error(
        className: "loading",
        text: "getVariantItem error",
        exception: e,
      );
    }
  }

/*
  save product variant to database
*/
  getProductVariant() async {
    try {
      print('product variant loading called');
      final prefs = await SharedPreferences.getInstance();
      final String? user = prefs.getString('user');
      Map userObject = json.decode(user!);
      Map data = await Domain().getProductVariant(userObject['company_id']);
      if (data['status'] == '1') {
        List responseJson = data['variant'];
        for (var i = 0; i < responseJson.length; i++) {
          ProductVariant productVariantItem = ProductVariant.fromJson(responseJson[i]);
          Product? productData = await PosDatabase.instance.readProductSqliteID(productVariantItem.product_id!);
          try {
            ProductVariant data = await PosDatabase.instance.insertProductVariant(ProductVariant(
                product_variant_id: productVariantItem.product_variant_id,
                product_sqlite_id: productData!.product_sqlite_id.toString(),
                product_id: productVariantItem.product_id,
                variant_name: productVariantItem.variant_name,
                SKU: productVariantItem.SKU,
                price: productVariantItem.price,
                stock_type: productVariantItem.stock_type,
                daily_limit: productVariantItem.daily_limit,
                daily_limit_amount: productVariantItem.daily_limit_amount,
                stock_quantity: productVariantItem.stock_quantity,
                sync_status: 1,
                created_at: productVariantItem.created_at,
                updated_at: productVariantItem.updated_at,
                soft_delete: productVariantItem.soft_delete));
            posFirestore.insertProductVariant(data);
          } catch(e) {
            FLog.error(
              className: "loading",
              text: "product variant insert failed (product_variant_id: ${productVariantItem.product_variant_id})",
              exception: "$e\n${productVariantItem.toJson()}",
            );
          }

        }
        getBranchLinkProduct();
        getProductVariantDetail();
      }
    } catch(e) {
      FLog.error(
        className: "loading",
        text: "getProductVariant error",
        exception: e,
      );
    }
  }

/*
  save product variant detail to database
*/
  getProductVariantDetail() async {
    try {
      print('product variant detail loading called');
      final prefs = await SharedPreferences.getInstance();
      final String? user = prefs.getString('user');
      Map userObject = json.decode(user!);
      Map data = await Domain().getProductVariantDetail(userObject['company_id']);
      if (data['status'] == '1') {
        List responseJson = data['variant'];
        for (var i = 0; i < responseJson.length; i++) {
          ProductVariantDetail productVariantDetailItem = ProductVariantDetail.fromJson(responseJson[i]);
          ProductVariant? productVariantData = await PosDatabase.instance.readProductVariantSqliteID(productVariantDetailItem.product_variant_id!);
          VariantItem? variantItemData = await PosDatabase.instance.readVariantItemSqliteID(productVariantDetailItem.variant_item_id!);
          try {
            ProductVariantDetail data = await PosDatabase.instance.insertProductVariantDetail(ProductVariantDetail(
                product_variant_detail_id: productVariantDetailItem.product_variant_detail_id,
                product_variant_id: productVariantDetailItem.product_variant_id,
                product_variant_sqlite_id: productVariantData!.product_variant_sqlite_id.toString(),
                variant_item_id: productVariantDetailItem.variant_item_id,
                variant_item_sqlite_id: variantItemData!.variant_item_sqlite_id.toString(),
                sync_status: 1,
                created_at: productVariantDetailItem.created_at,
                updated_at: productVariantDetailItem.updated_at,
                soft_delete: productVariantDetailItem.soft_delete));
            posFirestore.insertProductVariantDetail(data);
          } catch(e) {
            FLog.error(
              className: "loading",
              text: "product variant detail failed (product_variant_detail_id: ${productVariantDetailItem.product_variant_detail_id})",
              exception: "$e\n${productVariantDetailItem.toJson()}",
            );
          }
        }
      }
    } catch(e) {
      FLog.error(
        className: "loading",
        text: "getProductVariantDetail error",
        exception: e,
      );
    }
  }

/*
  save settlement link payment to database
*/
  getSettlementLinkPayment() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final int? branch_id = prefs.getInt('branch_id');
      final String? user = prefs.getString('user');
      final String? dataRetrieveDate = prefs.getString('dataRetrieveDate');
      Map userObject = json.decode(user!);
      Map data;
      if(dataRetrieveDate != '') {
        if(dataRetrieveDate == 'all')
          data = await Domain().getSettlementLinkPayment(userObject['company_id'], branch_id.toString());
        else
          data = await Domain().getSettlementLinkPaymentAfterDate(userObject['company_id'], branch_id.toString(), dataRetrieveDate);

        if (data['status'] == '1') {
          List responseJson = data['settlement'];
          for (var i = 0; i < responseJson.length; i++) {
            SettlementLinkPayment item = SettlementLinkPayment.fromJson(responseJson[i]);
            Settlement settlementData = await PosDatabase.instance.readSettlementSqliteID(item.settlement_key!);
            try {
              await PosDatabase.instance.insertSettlementLinkPayment(SettlementLinkPayment(
                settlement_link_payment_id: item.settlement_link_payment_id,
                settlement_link_payment_key: item.settlement_link_payment_key,
                company_id: item.company_id,
                branch_id: item.branch_id,
                settlement_sqlite_id: settlementData.settlement_sqlite_id.toString(),
                settlement_key: item.settlement_key,
                total_bill: item.total_bill,
                total_sales: item.total_sales,
                payment_link_company_id: item.payment_link_company_id,
                status: item.status,
                sync_status: 1,
                created_at: item.created_at,
                updated_at: item.updated_at,
                soft_delete: item.soft_delete,
              ));
            } catch(e) {
              FLog.error(
                className: "loading",
                text: "settlement link payment insert failed (settlement_link_payment_id: ${item.settlement_link_payment_id})",
                exception: "$e\n${item.toJson()}",
              );
            }
          }
        }
      }
    } catch(e) {
      FLog.error(
        className: "loading",
        text: "getSettlementLinkPayment error",
        exception: e,
      );
    }
  }

/*
  save order to database
*/
  getAllOrder() async {
    try {
      Settlement? settlement;
      final prefs = await SharedPreferences.getInstance();
      final int? branch_id = prefs.getInt('branch_id');
      final String? user = prefs.getString('user');
      final String? dataRetrieveDate = prefs.getString('dataRetrieveDate');
      Map userObject = json.decode(user!);
      Map data;

      if(dataRetrieveDate != '') {
        if(dataRetrieveDate == 'all')
          data = await Domain().getAllOrder(userObject['company_id'], branch_id.toString());
        else
          data = await Domain().getAllOrderAfterDate(userObject['company_id'], branch_id.toString(), dataRetrieveDate);

        if (data['status'] == '1') {
          List responseJson = data['order'];
          for (var i = 0; i < responseJson.length; i++) {
            if (responseJson[i]['settlement_key'] != '') {
              Settlement settlementData = await PosDatabase.instance.readSettlementSqliteID(responseJson[i]['settlement_key']);
              settlement = settlementData;
            }
            try {
              await PosDatabase.instance.insertOrder(Order(
                  order_id: responseJson[i]['order_id'],
                  order_number: responseJson[i]['order_number'],
                  order_queue: responseJson[i]['order_queue'],
                  company_id: responseJson[i]['company_id'],
                  customer_id: responseJson[i]['customer_id'],
                  dining_id: responseJson[i]['dining_id'],
                  dining_name: responseJson[i]['dining_name'],
                  branch_link_promotion_id: responseJson[i]['branch_link_promotion_id'],
                  payment_link_company_id: responseJson[i]['payment_link_company_id'],
                  branch_id: responseJson[i]['branch_id'],
                  branch_link_tax_id: responseJson[i]['branch_link_tax_id'],
                  subtotal: responseJson[i]['subtotal'],
                  amount: responseJson[i]['amount'],
                  rounding: responseJson[i]['rounding'],
                  final_amount: responseJson[i]['final_amount'],
                  close_by: responseJson[i]['close_by'],
                  payment_status: responseJson[i]['payment_status'],
                  payment_split: responseJson[i]['payment_split'],
                  payment_received: responseJson[i]['payment_received'],
                  payment_change: responseJson[i]['payment_change'],
                  order_key: responseJson[i]['order_key'],
                  refund_sqlite_id: '',
                  refund_key: responseJson[i]['refund_key'],
                  settlement_sqlite_id: settlement != null ? settlement.settlement_sqlite_id.toString() : '',
                  settlement_key: responseJson[i]['settlement_key'],
                  ipay_trans_id: responseJson[i]['ipay_trans_id'] ?? '',
                  sync_status: 1,
                  created_at: responseJson[i]['created_at'],
                  updated_at: responseJson[i]['updated_at'],
                  soft_delete: responseJson[i]['soft_delete']));
            } catch(e) {
              FLog.error(
                className: "loading",
                text: "order insert failed (order_id: ${responseJson[i]['order_id']})",
                exception: "$e\n${responseJson[i].toJson()}",
              );
            }
          }
          getAllOrderPromotionDetail();
          getAllOrderTaxDetail();
          getAllOrderPaymentSplit();
          getAllRefund();
        }
      }
    } catch(e) {
      FLog.error(
        className: "loading",
        text: "getAllOrder error",
        exception: e,
      );
    }
  }

/*
  save order promotion detail to database
*/
  getAllOrderPromotionDetail() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final int? branch_id = prefs.getInt('branch_id');
      final String? user = prefs.getString('user');
      Map userObject = json.decode(user!);
      Map data = await Domain().getAllOrderPromotionDetail(userObject['company_id'], branch_id.toString());
      if (data['status'] == '1') {
        List responseJson = data['order'];
        for (var i = 0; i < responseJson.length; i++) {
          Order? orderData = await PosDatabase.instance.readOrderSqliteID(responseJson[i]['order_key']);
          try {
            await PosDatabase.instance.insertOrderPromotionDetail(OrderPromotionDetail(
              order_promotion_detail_id: responseJson[i]['order_promotion_detail_id'],
              order_promotion_detail_key: responseJson[i]['order_promotion_detail_key'],
              order_sqlite_id:  orderData != null ? orderData.order_sqlite_id.toString() : '',
              order_id: orderData != null ? orderData.order_id.toString() : '',
              order_key: responseJson[i]['order_key'],
              promotion_name: responseJson[i]['promotion_name'],
              rate: responseJson[i]['rate'],
              promotion_id: responseJson[i]['promotion_id'],
              branch_link_promotion_id: responseJson[i]['branch_link_promotion_id'],
              promotion_amount: responseJson[i]['promotion_amount'],
              promotion_type: responseJson[i]['promotion_type'],
              auto_apply: responseJson[i]['auto_apply'],
              sync_status: 1,
              created_at: responseJson[i]['created_at'],
              updated_at: responseJson[i]['updated_at'],
              soft_delete: responseJson[i]['soft_delete'],
            ));
          } catch(e) {
            FLog.error(
              className: "loading",
              text: "order promotion detail insert failed (order_promotion_detail_id: ${responseJson[i]['order_promotion_detail_id']})",
              exception: "$e\n${responseJson[i].toJson()}",
            );
          }
        }
      }
    } catch(e) {
      FLog.error(
        className: "loading",
        text: "getAllOrderPromotionDetail error",
        exception: e,
      );
    }
  }

/*
  save order tax detail to database
*/
  getAllOrderTaxDetail() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final int? branch_id = prefs.getInt('branch_id');
      final String? user = prefs.getString('user');
      final String? dataRetrieveDate = prefs.getString('dataRetrieveDate');
      Map userObject = json.decode(user!);
      Map data;

      if(dataRetrieveDate != '') {
        if(dataRetrieveDate == 'all')
          data = await Domain().getAllOrderTaxDetail(userObject['company_id'], branch_id.toString());
        else
          data = await Domain().getAllOrderTaxDetailAfterDate(userObject['company_id'], branch_id.toString(), dataRetrieveDate);

        if (data['status'] == '1') {
          List responseJson = data['order'];
          for (var i = 0; i < responseJson.length; i++) {
            Order? orderData = await PosDatabase.instance.readOrderSqliteID(responseJson[i]['order_key']);
            try {
              await PosDatabase.instance.insertOrderTaxDetail(OrderTaxDetail(
                order_tax_detail_id: responseJson[i]['order_tax_detail_id'],
                order_tax_detail_key: responseJson[i]['order_tax_detail_key'],
                order_sqlite_id:  orderData != null ? orderData.order_sqlite_id.toString() : '',
                order_id: orderData != null ? orderData.order_id.toString() : '',
                order_key: responseJson[i]['order_key'],
                tax_name: responseJson[i]['tax_name'],
                type: responseJson[i]['type'],
                rate: responseJson[i]['rate'],
                tax_id: responseJson[i]['tax_id'],
                branch_link_tax_id: responseJson[i]['branch_link_tax_id'],
                tax_amount: responseJson[i]['tax_amount'],
                sync_status: 1,
                created_at: responseJson[i]['created_at'],
                updated_at: responseJson[i]['updated_at'],
                soft_delete: responseJson[i]['soft_delete'],
              ));
            } catch(e) {
              FLog.error(
                className: "loading",
                text: "order tax detail insert failed (order_tax_detail_id: ${responseJson[i]['order_tax_detail_id']})",
                exception: "$e\n${responseJson[i].toJson()}",
              );
            }
          }
        }
      }
    } catch(e) {
      FLog.error(
        className: "loading",
        text: "getAllOrderTaxDetail error",
        exception: e,
      );
    }
  }

/*
  save order payment split to database
*/
  getAllOrderPaymentSplit() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final int? branch_id = prefs.getInt('branch_id');
      final String? dataRetrieveDate = prefs.getString('dataRetrieveDate');
      Map data;

      if(dataRetrieveDate != '') {
        if(dataRetrieveDate == 'all')
          data = await Domain().getAllOrderPaymentSplit(branch_id.toString());
        else
          data = await Domain().getAllOrderPaymentSplitAfterDate(branch_id.toString(), dataRetrieveDate);

        if (data['status'] == '1') {
          List responseJson = data['data'];
          for (var i = 0; i < responseJson.length; i++) {
            try {
              await PosDatabase.instance.insertSqliteOrderPaymentSplit(OrderPaymentSplit(
                  order_payment_split_id: responseJson[i]['order_payment_split_id'],
                  order_payment_split_key: responseJson[i]['order_payment_split_key'],
                  branch_id: responseJson[i]['branch_id'],
                  payment_link_company_id: responseJson[i]['payment_link_company_id'],
                  amount: responseJson[i]['amount'],
                  payment_received: responseJson[i]['payment_received'],
                  payment_change: responseJson[i]['payment_change'],
                  order_key: responseJson[i]['order_key'],
                  ipay_trans_id: responseJson[i]['ipay_trans_id'],
                  sync_status: 1,
                  created_at: responseJson[i]['created_at'],
                  updated_at: responseJson[i]['updated_at'],
                  soft_delete: responseJson[i]['soft_delete']
              ));
            } catch(e) {
              FLog.error(
                className: "loading",
                text: "order payment split insert failed (order_payment_split_id: ${responseJson[i]['order_payment_split_id']})",
                exception: "$e\n${responseJson[i].toJson()}",
              );
            }
          }
        }
      }
    } catch(e) {
      FLog.error(
        className: "loading",
        text: "getAllOrderPaymentSplit error",
        exception: e,
      );
    }
  }

/*
  save order cache to database
*/
  getAllOrderCache() async {
    try {
      String tableUseLocalId = '', orderLocalId = '';
      final prefs = await SharedPreferences.getInstance();
      final int? branch_id = prefs.getInt('branch_id');
      final String? user = prefs.getString('user');
      final String? dataRetrieveDate = prefs.getString('dataRetrieveDate');
      Map userObject = json.decode(user!);
      Map data;

      if(dataRetrieveDate != '') {
        if(dataRetrieveDate == 'all')
          data = await Domain().getAllOrderCache(userObject['company_id'], branch_id.toString());
        else
          data = await Domain().getAllOrderCacheAfterDate(userObject['company_id'], branch_id.toString(), dataRetrieveDate);

        if (data['status'] == '1') {
          List responseJson = data['order'];
          for (var i = 0; i < responseJson.length; i++) {
            OrderCache cloudData = OrderCache.fromJson(responseJson[i]);
            if (cloudData.table_use_key != '' && cloudData.table_use_key != null) {
              // print("table use key: ${cloudData.table_use_key}");
              TableUse? tableUseData = await PosDatabase.instance.readTableUseSqliteID(cloudData.table_use_key!);
              if(tableUseData != null){
                tableUseLocalId = tableUseData.table_use_sqlite_id.toString();
              } else {
                continue;
              }
            } else {
              tableUseLocalId = '';
            }

            if (cloudData.order_key != '' && cloudData.order_key != null) {
              // print("order key in order cache sync: ${cloudData.order_key}");
              Order? orderData = await PosDatabase.instance.readOrderSqliteID(cloudData.order_key!);
              orderLocalId =  orderData != null ? orderData.order_sqlite_id.toString() : '';
            } else {
              orderLocalId = '';
            }
            try {
              await PosDatabase.instance.insertOrderCache(OrderCache(
                order_cache_id: cloudData.order_cache_id,
                order_cache_key: cloudData.order_cache_key,
                order_queue: cloudData.order_queue,
                company_id: cloudData.company_id,
                branch_id: cloudData.branch_id,
                order_detail_id: '',
                table_use_sqlite_id: tableUseLocalId,
                table_use_key: cloudData.table_use_key != '' && cloudData.table_use_key != null ? cloudData.table_use_key : '',
                batch_id: cloudData.batch_id,
                dining_id: cloudData.dining_id,
                order_sqlite_id: orderLocalId,
                order_key: cloudData.order_key != '' && cloudData.order_key != null ? cloudData.order_key : '',
                order_by: cloudData.order_by != '' ? cloudData.order_by : '',
                order_by_user_id: cloudData.order_by_user_id,
                cancel_by: cloudData.cancel_by != '' ? cloudData.cancel_by : '',
                cancel_by_user_id: cloudData.cancel_by_user_id != '' ? cloudData.cancel_by_user_id : '',
                customer_id: cloudData.customer_id,
                total_amount: cloudData.total_amount != '' ? cloudData.total_amount : '',
                qr_order: cloudData.qr_order,
                qr_order_table_sqlite_id: '',
                qr_order_table_id: responseJson[i]['table_id'],
                accepted: cloudData.accepted,
                sync_status: 1,
                payment_status: cloudData.payment_status,
                created_at: cloudData.created_at,
                updated_at: cloudData.updated_at,
                soft_delete: cloudData.soft_delete,
              ));
            } catch(e) {
              FLog.error(
                className: "loading",
                text: "order cache insert failed (order_cache_id: ${cloudData.order_cache_id})",
                exception: "$e\n${cloudData.toJson()}",
              );
            }
          }
          getAllOrderDetail();
        }
      }
    } catch(e) {
      FLog.error(
        className: "loading",
        text: "getAllOrderCache error",
        exception: e,
      );
    }
  }

/*
  save order detail to database
*/
  getAllOrderDetail() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final int? branch_id = prefs.getInt('branch_id');
      final String? user = prefs.getString('user');
      Map userObject = json.decode(user!);
      Map data = await Domain().getAllOrderDetail(userObject['company_id'], branch_id.toString());
      if (data['status'] == '1') {
        List responseJson = data['order'];
        for (var i = 0; i < responseJson.length; i++) {
          //OrderDetail item = OrderDetail.fromJson(responseJson[i]);
          OrderCache? cacheData = await PosDatabase.instance.readOrderCacheSqliteID(responseJson[i]['order_cache_key']);
          Categories? categoriesData = await PosDatabase.instance.readCategorySqliteID(responseJson[i]['category_id'].toString());
          BranchLinkProduct? branchLinkProductData = await PosDatabase.instance.readBranchLinkProductSqliteID(responseJson[i]['branch_link_product_id'].toString());
          if(cacheData == null || branchLinkProductData == null){
            continue;
          }
          try {
            await PosDatabase.instance.insertOrderDetail(OrderDetail(
                order_detail_id: responseJson[i]['order_detail_id'],
                order_detail_key: responseJson[i]['order_detail_key'].toString(),
                order_cache_sqlite_id: cacheData.order_cache_sqlite_id.toString(),
                order_cache_key: responseJson[i]['order_cache_key'],
                branch_link_product_sqlite_id: branchLinkProductData.branch_link_product_sqlite_id.toString(),
                category_sqlite_id: categoriesData != null ? categoriesData.category_sqlite_id.toString() : '0',
                category_name: responseJson[i]['category_name'],
                productName: responseJson[i]['product_name'],
                has_variant: responseJson[i]['has_variant'],
                product_variant_name: responseJson[i]['product_variant_name'],
                price: responseJson[i]['price'],
                original_price: responseJson[i]['original_price'],
                quantity: responseJson[i]['quantity'],
                remark: responseJson[i]['remark'],
                account: responseJson[i]['account'],
                edited_by: responseJson[i]['edited_by'],
                edited_by_user_id: responseJson[i]['edited_by_user_id'],
                cancel_by: responseJson[i]['cancel_by'],
                cancel_by_user_id: responseJson[i]['cancel_by_user_id'],
                status: responseJson[i]['status'],
                unit: responseJson[i]['unit'],
                per_quantity_unit: responseJson[i]['per_quantity_unit'],
                product_sku: responseJson[i]['product_sku'],
                sync_status: 1,
                created_at: responseJson[i]['created_at'],
                updated_at: responseJson[i]['updated_at'],
                soft_delete: responseJson[i]['soft_delete']));
          } catch(e) {
            FLog.error(
              className: "loading",
              text: "order detail insert failed (order_detail_id: ${responseJson[i]['order_detail_id']})",
              exception: "$e\n${responseJson[i].toJson()}",
            );
          }
        }
        getAllOrderModifierDetail();
        getAllOrderDetailCancel();
      }
    } catch(e) {
      FLog.error(
        className: "loading",
        text: "getAllOrderDetail error",
        exception: e,
      );
    }
  }

/*
  save order detail cancel to database
*/
  getAllOrderDetailCancel() async {
    try {
      Settlement? settlement;
      final prefs = await SharedPreferences.getInstance();
      final int? branch_id = prefs.getInt('branch_id');
      final String? user = prefs.getString('user');
      Map userObject = json.decode(user!);
      Map data = await Domain().getAllOrderDetailCancel(userObject['company_id'], branch_id.toString());
      if (data['status'] == '1') {
        List responseJson = data['order'];
        for (var i = 0; i < responseJson.length; i++) {
          if (responseJson[i]['settlement_key'] != '') {
            Settlement settlementData = await PosDatabase.instance.readSettlementSqliteID(responseJson[i]['settlement_key']);
            settlement = settlementData;
          }
          OrderDetail? detailData = await PosDatabase.instance.readOrderDetailSqliteID(responseJson[i]['order_detail_key']);
          if(detailData == null){
            continue;
          }
          try {
            await PosDatabase.instance.insertOrderDetailCancel(OrderDetailCancel(
              order_detail_cancel_id: responseJson[i]['order_detail_cancel_id'],
              order_detail_cancel_key: responseJson[i]['order_detail_cancel_key'],
              order_detail_sqlite_id: detailData.order_detail_sqlite_id.toString(),
              order_detail_key: responseJson[i]['order_detail_key'],
              quantity: responseJson[i]['quantity'],
              cancel_by: responseJson[i]['cancel_by'],
              cancel_by_user_id: responseJson[i]['cancel_by_user_id'],
              settlement_sqlite_id: responseJson[i]['settlement_key'] != '' ? settlement?.settlement_sqlite_id.toString() : '',
              settlement_key: responseJson[i]['settlement_key'],
              status: responseJson[i]['status'],
              sync_status: 1,
              created_at: responseJson[i]['created_at'],
              updated_at: responseJson[i]['updated_at'],
              soft_delete: responseJson[i]['soft_delete'],
            ));
          } catch(e) {
            FLog.error(
              className: "loading",
              text: "order detail cancel insert failed (order_detail_cancel_id: ${responseJson[i]['order_detail_cancel_id']})",
              exception: "$e\n${responseJson[i].toJson()}",
            );
          }
        }
      }
    } catch(e) {
      FLog.error(
        className: "loading",
        text: "getAllOrderDetailCancel error",
        exception: e,
      );
    }
  }

/*
  save order modifier detail to database
*/
  getAllOrderModifierDetail() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final int? branch_id = prefs.getInt('branch_id');
      final String? user = prefs.getString('user');
      Map userObject = json.decode(user!);
      Map data = await Domain().getAllOrderModifierDetail(userObject['company_id'], branch_id.toString());
      if (data['status'] == '1') {
        List responseJson = data['order'];
        for (var i = 0; i < responseJson.length; i++) {
          OrderDetail? detailData = await PosDatabase.instance.readOrderDetailSqliteID(responseJson[i]['order_detail_key']);
          if(detailData == null){
            continue;
          }
          try {
            await PosDatabase.instance.insertOrderModifierDetail(OrderModifierDetail(
                order_modifier_detail_id: responseJson[i]['order_modifier_detail_id'],
                order_modifier_detail_key: responseJson[i]['order_modifier_detail_key'],
                order_detail_key: responseJson[i]['order_detail_key'],
                order_detail_sqlite_id: detailData.order_detail_sqlite_id.toString(),
                order_detail_id: '0',
                mod_item_id: responseJson[i]['mod_item_id'],
                mod_name: responseJson[i]['name'],
                mod_price: responseJson[i]['price'],
                mod_group_id: responseJson[i]['mod_group_id'],
                sync_status: 1,
                created_at: responseJson[i]['created_at'],
                updated_at: responseJson[i]['updated_at'],
                soft_delete: responseJson[i]['soft_delete']));
          } catch(e) {
            FLog.error(
              className: "loading",
              text: "order modifier detail insert failed (order_modifier_detail_id: ${responseJson[i]['order_modifier_detail_id']})",
              exception: "$e\n${responseJson[i].toJson()}",
            );
          }
        }
      }
    } catch(e) {
      FLog.error(
        className: "loading",
        text: "getAllOrderModifierDetail error",
        exception: e,
      );
    }
  }

/*
  save sale to database
*/
  getSale() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final int? branch_id = prefs.getInt('branch_id');
      final String? user = prefs.getString('user');
      Map userObject = json.decode(user!);
      Map data = await Domain().getSale(userObject['company_id'], branch_id.toString());
      if (data['status'] == '1') {
        List responseJson = data['sale'];
        for (var i = 0; i < responseJson.length; i++) {
          await PosDatabase.instance.insertSale(Sale.fromJson(responseJson[i]));
        }
      }
    } catch(e) {
      FLog.error(
        className: "loading",
        text: "getSale error",
        exception: e,
      );
    }
  }

/*
  save cash record to database
*/
  getCashRecord() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final int? branch_id = prefs.getInt('branch_id');
      final String? user = prefs.getString('user');
      final String? dataRetrieveDate = prefs.getString('dataRetrieveDate');
      Map userObject = json.decode(user!);
      Map data;

      if(dataRetrieveDate != '') {
        if(dataRetrieveDate == 'all')
          data = await Domain().getCashRecord(userObject['company_id'], branch_id.toString());
        else
          data = await Domain().getCashRecordAfterDate(userObject['company_id'], branch_id.toString(), dataRetrieveDate);

        if (data['status'] == '1') {
          List responseJson = data['data'];
          for (var i = 0; i < responseJson.length; i++) {
            try {
              await PosDatabase.instance.insertCashRecord(CashRecord(
                cash_record_id: responseJson[i]['cash_record_id'],
                cash_record_key: responseJson[i]['cash_record_key'],
                company_id: responseJson[i]['company_id'],
                branch_id: responseJson[i]['branch_id'],
                remark: responseJson[i]['remark'],
                payment_name: responseJson[i]['payment_name'],
                payment_type_id: responseJson[i]['payment_type_id'],
                type: responseJson[i]['type'],
                amount: responseJson[i]['amount'],
                user_id: responseJson[i]['user_id'],
                settlement_key: responseJson[i]['settlement_key'],
                settlement_date: responseJson[i]['settlement_date'],
                sync_status: 1,
                created_at: responseJson[i]['created_at'],
                updated_at: responseJson[i]['updated_at'],
                soft_delete: responseJson[i]['soft_delete'],
              ));
            } catch(e) {
              FLog.error(
                className: "loading",
                text: "cash record insert failed (cash_record_id: ${responseJson[i]['cash_record_id']})",
                exception: "$e\n${responseJson[i].toJson()}",
              );
            }
          }
        }
      }
    } catch(e) {
      print("getCashRecord error: ${e}");
      FLog.error(
        className: "loading",
        text: "getCashRecord error",
        exception: e,
      );
    }
  }

/*
  save transfer owner to database
*/
  getTransferOwner() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final int? branch_id = prefs.getInt('branch_id');
      final String? dataRetrieveDate = prefs.getString('dataRetrieveDate');
      Map data;

      if(dataRetrieveDate != '') {
        if(dataRetrieveDate == 'all')
          data = await Domain().getTransferOwner(branch_id.toString());
        else
          data = await Domain().getTransferOwnerAfterDate(branch_id.toString(), dataRetrieveDate);

        if (data['status'] == '1') {
          List responseJson = data['data'];
          for (var i = 0; i < responseJson.length; i++) {
            try {
              await PosDatabase.instance.insertTransferOwner(TransferOwner(
                transfer_owner_key: responseJson[i]['transfer_owner_key'],
                branch_id: responseJson[i]['branch_id'],
                device_id: responseJson[i]['device_id'],
                transfer_from_user_id: responseJson[i]['transfer_from_user_id'],
                transfer_to_user_id: responseJson[i]['transfer_to_user_id'],
                cash_balance: responseJson[i]['cash_balance'],
                sync_status: 1,
                created_at: responseJson[i]['created_at'],
                updated_at: '',
                soft_delete: '',
              ));
            } catch(e) {
              FLog.error(
                className: "loading",
                text: "transfer order insert failed (transfer_owner_key: ${responseJson[i]['transfer_owner_key']})",
                exception: "$e\n${responseJson[i].toJson()}",
              );
            }
          }
        }
      }
    } catch(e) {
      FLog.error(
        className: "loading",
        text: "getTransferOwner error",
        exception: e,
      );
    }
  }

/*
  create folder to save product image
*/
  Future<String> get _localPath async {
    final directory = await getApplicationSupportDirectory();
    return directory.path;
  }

  _createProductImgFolder() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? user = prefs.getString('user');
      Map userObject = json.decode(user!);

      final folderName = userObject['company_id'];
      final directory = await _localPath;
      final path = '$directory/assets/$folderName';
      final pathImg = Directory(path);
      pathImg.create();
      await prefs.setString('local_path', path);
      print('image path: ${pathImg.path}');
      downloadProductImage(pathImg.path);
    } catch(e) {
      FLog.error(
        className: "loading",
        text: "_createProductImgFolder error",
        exception: e,
      );
    }
  }

/*
  download product image
*/
  downloadProductImage(String path) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? user = prefs.getString('user');
      Map userObject = json.decode(user!);
      Map data = await Domain().getAllProduct(userObject['company_id']);
      String url = '';
      String name = '';
      if (data['status'] == '1') {
        List responseJson = data['product'];
        for (var i = 0; i < responseJson.length; i++) {
          Product data = Product.fromJson(responseJson[i]);
          name = data.image!;
          if (data.image != '') {
            url = '${Domain.backend_domain}api/gallery/' + userObject['company_id'] + '/' + name;
            final response = await http.get(Uri.parse(url));
            var localPath = path + '/' + name;
            final imageFile = File(localPath);
            await imageFile.writeAsBytes(response.bodyBytes);
          }
        }
      }
    } catch(e) {
      FLog.error(
        className: "loading",
        text: "downloadProductImage error",
        exception: e,
      );
    }
  }

  _createBannerImgFolder() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final folderName = 'banner';
      final directory = await _localPath;
      final path = '$directory/assets/$folderName';
      final pathImg = Directory(path);

      pathImg.create();
      await prefs.setString('banner_path', path);
      print('image path: ${pathImg.path}');
      downloadBannerImage(pathImg.path);
    } catch(e) {
      FLog.error(
        className: "loading",
        text: " error",
        exception: e,
      );
    }
  }

/*
  download banner image
*/
  downloadBannerImage(String path) async {
    try{
      final prefs = await SharedPreferences.getInstance();
      final int? branchId = prefs.getInt('branch_id');
      final String? user = prefs.getString('user');
      Map userObject = json.decode(user!);
      Map data = await Domain().getSecondScreen(branch_id: branchId.toString());
      String url = '';
      String name = '';
      if (data['status'] == '1') {
        List responseJson = data['second_screen'];
        for (var i = 0; i < responseJson.length; i++) {
          name = responseJson[i]['name'];
          print("second screen img name: ${name}");
          if (name != '') {
            url = '${Domain.backend_domain}api/banner/' + userObject['company_id'] + '/' + branchId.toString() + '/' + name;
            final response = await http.get(Uri.parse(url));
            var localPath = path + '/' + name;
            final imageFile = File(localPath);
            await imageFile.writeAsBytes(response.bodyBytes);
          }
        }
      }
    } catch(e){
      print("download banner image error: ${e}");
      FLog.error(
        className: "loading",
        text: "downloadBannerImage error",
        exception: e,
      );
    }
  }
}
