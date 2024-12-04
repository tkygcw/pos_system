import 'dart:async';
import 'dart:convert';
import 'package:f_logs/model/flog/flog.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
import 'package:pos_system/object/table.dart';

import '../object/branch.dart';

class Domain {
  // static var domain = 'https://pos.lkmng.com/';
  // static var backend_domain = 'https://pos.lkmng.com/';
  // static var qr_domain = 'https://pos-qr.lkmng.com/';
  static var domain = 'https://testing.optimy.com.my/';
  // static var domain = 'https://pos.optimy.com.my/';
  static var backend_domain = 'https://api.optimy.com.my/';
  static var qr_domain = 'https://qr.optimy.com.my/';
  static Uri login = Uri.parse(domain + 'mobile-api/login/index.php');
  static Uri branch = Uri.parse(domain + 'mobile-api/branch/index.php');
  static Uri device = Uri.parse(domain + 'mobile-api/device/index.php');
  static Uri device_login = Uri.parse(domain + 'mobile-api/device_login/index.php');
  static Uri user = Uri.parse(domain + 'mobile-api/user/index.php');
  static Uri table = Uri.parse(domain + 'mobile-api/table/index.php');
  static Uri dining_option = Uri.parse(domain + 'mobile-api/dining_option/index.php');
  static Uri tax = Uri.parse(domain + 'mobile-api/tax/index.php');
  static Uri categories = Uri.parse(domain + 'mobile-api/categories/index.php');
  static Uri promotion = Uri.parse(domain + 'mobile-api/promotion/index.php');
  static Uri customer = Uri.parse(domain + 'mobile-api/customer/index.php');
  static Uri bill = Uri.parse(domain + 'mobile-api/bill/index.php');
  static Uri payment = Uri.parse(domain + 'mobile-api/payment/index.php');
  static Uri refund = Uri.parse(domain + 'mobile-api/refund/index.php');
  static Uri modifier = Uri.parse(domain + 'mobile-api/modifier/index.php');
  static Uri product = Uri.parse(domain + 'mobile-api/product/index.php');
  static Uri variant = Uri.parse(domain + 'mobile-api/variant/index.php');
  static Uri order = Uri.parse(domain + 'mobile-api/order/index.php');
  static Uri sale = Uri.parse(domain + 'mobile-api/sale/index.php');
  static Uri settlement = Uri.parse(domain + 'mobile-api/settlement/index.php');
  static Uri table_use = Uri.parse(domain + 'mobile-api/table_use/index.php');
  static Uri transfer_owner = Uri.parse(domain + 'mobile-api/transfer_owner/index.php');
  static Uri cash_record = Uri.parse(domain + 'mobile-api/cash_record/index.php');
  static Uri sync_record = Uri.parse(domain + 'mobile-api/sync/index.php');
  static Uri sync_to_cloud = Uri.parse(domain + 'mobile-api/sync_to_cloud/index.php');
  static Uri qr_order_sync = Uri.parse(domain + 'mobile-api/qr_order_sync/index.php');
  static Uri printer = Uri.parse(domain + 'mobile-api/printer/index.php');
  static Uri app_version = Uri.parse(domain + 'mobile-api/app_version/index.php');
  static Uri app_setting = Uri.parse(domain + 'mobile-api/app_setting/index.php');
  static Uri subscription = Uri.parse(domain + 'mobile-api/subscription/index.php');
  static Uri receipt = Uri.parse(domain + 'mobile-api/receipt/index.php');
  static Uri checklist = Uri.parse(domain + 'mobile-api/checklist/index.php');
  static Uri kitchen_list = Uri.parse(domain + 'mobile-api/kitchen_list/index.php');
  static Uri second_screen = Uri.parse(domain + 'mobile-api/second_screen/index.php');
  static Uri local_data_export = Uri.parse(domain + 'mobile-api/local_data_export/index.php');
  static Uri attendance = Uri.parse(domain + 'mobile-api/attendance/index.php');
  static Uri dynamic_qr = Uri.parse(domain + 'mobile-api/dynamic_qr/index.php');
  static Uri table_dynamic = Uri.parse(domain + 'mobile-api/table_dynamic/index.php');
  static Uri order_payment_split = Uri.parse(domain + 'mobile-api/order_payment_split/index.php');
  static Uri current_version = Uri.parse(domain + 'mobile-api/current_version/index.php');
  //for transfer data use only
  static Uri import_firebase = Uri.parse(domain + 'mobile-api/import_firebase/index.php');


  transferDatabaseData(String tb_name) async {
    try {
      var response = await http.post(Domain.import_firebase, body: {
        'import_firebase': '1',
        'tb_name': tb_name
      });
      return jsonDecode(response.body);
    } catch (error) {
      FLog.error(
        className: "domain",
        text: "transfer db data failed",
        exception: "$error",
      );
      Fluttertoast.showToast(msg: error.toString());
      return {'status': '2'};
    }
  }

  /**
   * update branch close qr status
   * */
  updateBranchCloseQrOrder(Branch branch) async {
    try {
      var response = await http.post(Domain.branch, body: {
        'updateBranchCloseQrOrder': '1',
        'close_qr_order': branch.close_qr_order.toString(),
        'branch_id': branch.branch_id!.toString(),
      }).timeout(Duration(seconds: 5), onTimeout: ()=> throw TimeoutException("Timeout"));
      return jsonDecode(response.body);
    } catch (error) {
      FLog.error(
        className: "domain",
        text: "updateBranchCloseQrOrder failed",
        exception: "$error",
      );
      Fluttertoast.showToast(msg: error.toString());
      return {'status': '2'};
    }
  }

  /**
   * soft_delete table dynamic qr (one-time qr)
   * */
  softDeleteTableDynamicQr(PosTable posTable) async {
    try {
      var response = await http.post(Domain.table_dynamic, body: {
        'one_time_qr_soft_delete': '1',
        'table_id': posTable.table_id.toString(),
      }).timeout(Duration(seconds: 30), onTimeout: ()=> throw TimeoutException("Timeout"));
      return jsonDecode(response.body);
    } catch (error) {
      FLog.error(
        className: "domain",
        text: "dynamic QR soft_delete failed",
        exception: "$error",
      );
      Fluttertoast.showToast(msg: error.toString());
      return {'status': '2'};
    }
  }

  /**
  * insert table dynamic qr
  * */
  insertTableDynamicQr(PosTable posTable) async {
    try {
      var response = await http.post(Domain.table_dynamic, body: {
        'new_version': '1',
        'tb_dynamic_table_create': '1',
        'table_id': posTable.table_id.toString(),
        'branch_id': posTable.branch_id,
        'qr_url': posTable.dynamicQrHash,
        'qr_expired_dateTime': posTable.dynamicQRExp,
        'invalid_after_payment': posTable.invalid_after_payment!.toString()
      }).timeout(Duration(seconds: 5), onTimeout: ()=> throw TimeoutException("Timeout"));
      return jsonDecode(response.body);
    } catch (error) {
      FLog.error(
        className: "domain",
        text: "dynamic qr insert failed",
        exception: "$error",
      );
      Fluttertoast.showToast(msg: error.toString());
      return {'status': '2'};
    }
  }


/*
  get dynamic qr layout
*/
  getDynamicQr({required String branch_id}) async {
    try{
      print("branch_id: ${branch_id}");
      var response = await http.post(Domain.dynamic_qr, body: {
        'getAllDynamicQr': '1',
        'branch_id': branch_id,
      });
      return jsonDecode(response.body);
    } catch(e){
      Fluttertoast.showToast(msg: e.toString());
    }
  }

/*
  get banner image
*/
  getSecondScreen({required String branch_id}) async {
    try{
      print("branch_id: ${branch_id}");
      var response = await http.post(Domain.second_screen, body: {
        'getSecondScreen': '1',
        'branch_id': branch_id,
      });
      return jsonDecode(response.body);
    } catch(e){
      Fluttertoast.showToast(msg: e.toString());
    }
  }


/*
  get app version
*/
  getAppVersion(String platform) async {
    try{
      var response = await http.post(Domain.app_version, body: {
        'getAppVersion': '1',
        'platform': platform,
      });
      return jsonDecode(response.body);
    } catch(e){
      Fluttertoast.showToast(msg: e.toString());
    }
  }

  /**
  * login
  * */
  userlogin(email, password) async {
    try {
      var response = await http.post(Domain.login, body: {
        'login': '1',
        'password': password,
        'email': email,
      }).timeout(Duration(seconds: 3), onTimeout: ()=> throw TimeoutException("Time out"));
      return jsonDecode(response.body);
    } on TimeoutException catch(_){
      print('domain login time out');
      Map<String, dynamic>? result = {'status': '8'};
      return result;
    } catch (error) {
      print('login domain error: $error');
      Fluttertoast.showToast(msg: error.toString());
    }
  }

  /**
  * Forget Password
  * */
  forgetPassword(email) async {
    try {
      var response = await http.post(Domain.login, body: {
        'resetPassword': '1',
        'email': email,
      });
      return jsonDecode(response.body);
    } catch (error) {
      Fluttertoast.showToast(msg: error.toString());
    }
  }

  /*
  * get company branch
  * */
  getCompanyBranch(company_id) async {
    try {
      var response = await http.post(Domain.branch, body: {
        'getAllCompanyBranch': '1',
        'company_id': company_id,
      });
      return jsonDecode(response.body);
    } catch (error) {
      Fluttertoast.showToast(msg: error.toString());
    }
  }

  /*
  * get branch device
  * */
  getBranchDevice(branch_id) async {
    try {
      var response = await http.post(Domain.device, body: {
        'getBranchDevice': '1',
        'branch_id': branch_id,
      });
      return jsonDecode(response.body);
    } catch (error) {
      Fluttertoast.showToast(msg: error.toString());
    }
  }

  /*
  * get all branch user
  * */
  getAllUser(company_id) async {
    try {
      var response = await http.post(Domain.user, body: {
        'getAllUser': '1',
        'company_id': company_id,
      });
      return jsonDecode(response.body);
    } catch (error) {
      Fluttertoast.showToast(msg: error.toString());
    }
  }

  /*
  * get all attendance
  * */
  getAllAttendance(branch_id) async {
    try {
      var response = await http.post(Domain.attendance, body: {
        'getAllAttendance': '1',
        'branch_id': branch_id,
      });
      return jsonDecode(response.body);
    } catch (error) {
      Fluttertoast.showToast(msg: error.toString());
    }
  }

  /*
  * get all attendance after date
  * */
  getAllAttendanceAfterDate(branch_id, date_from) async {
    try {
      var response = await http.post(Domain.attendance, body: {
        'getAllAttendanceAfterDate': '1',
        'branch_id': branch_id,
        'date_from': date_from,
      });
      return jsonDecode(response.body);
    } catch (error) {
      Fluttertoast.showToast(msg: error.toString());
    }
  }

  /*
  * get all order payment split
  * */
  getAllOrderPaymentSplit(branch_id) async {
    try {
      var response = await http.post(Domain.order_payment_split, body: {
        'getAllOrderPaymentSplit': '1',
        'branch_id': branch_id,
      });
      return jsonDecode(response.body);
    } catch (error) {
      Fluttertoast.showToast(msg: error.toString());
      print("getAllOrderPaymentSplit error: ${error}");
    }
  }

  /*
  * get all order payment split after date
  * */
  getAllOrderPaymentSplitAfterDate(branch_id, date_from) async {
    try {
      var response = await http.post(Domain.order_payment_split, body: {
        'getAllOrderPaymentSplitAfterDate': '1',
        'branch_id': branch_id,
        'date_from': date_from,
      });
      return jsonDecode(response.body);
    } catch (error) {
      Fluttertoast.showToast(msg: error.toString());
    }
  }

  /*
  * get all table_use
  * */
  getAllTableUse(branch_id) async {
    try {
      var response = await http.post(Domain.table_use, body: {
        'getAllTableUse': '1',
        'branch_id': branch_id,
      });
      return jsonDecode(response.body);
    } catch (error) {
      Fluttertoast.showToast(msg: error.toString());
    }
  }

  /*
  * get all table_use after date
  * */
  getAllTableUseAfterDate(branch_id, date_from) async {
    try {
      var response = await http.post(Domain.table_use, body: {
        'getAllTableUseAfterDate': '1',
        'branch_id': branch_id,
        'date_from': date_from,
      });
      return jsonDecode(response.body);
    } catch (error) {
      Fluttertoast.showToast(msg: error.toString());
    }
  }

  /*
  * get device login
  * */
  getDeviceLogin(device_id) async {
    try {
      var response = await http.post(Domain.device_login, body: {
        'getAllDeviceLogin': '1',
        'device_id': device_id,
      });
      return jsonDecode(response.body);
    } catch (error) {
      Fluttertoast.showToast(msg: error.toString());
    }
  }

  /*
  * insert device login
  * */
  insertDeviceLogin(deviceId, value) async {
    try {
      var response = await http.post(Domain.device_login, body: {
        'addDeviceLogin': '1',
        'device_id': deviceId,
        'value': value.toString(),
      });
      return jsonDecode(response.body);
    } catch (error) {
      Fluttertoast.showToast(msg: error.toString());
    }
  }

  /*
  * device logout
  * */
  deviceLogout(deviceId) async {
    try {
      var response = await http.post(Domain.device_login, body: {
        'deviceLogout': '1',
        'device_id': deviceId,
      });
      return jsonDecode(response.body);
    } catch (error) {
      Fluttertoast.showToast(msg: error.toString());
    }
  }



  /*
  * get all table_use
  * */
  insertTableUse(branch_id, card_color) async {
    try {
      var response = await http.post(Domain.table_use, body: {
        'insertTableUse': '1',
        'branch_id': branch_id,
        'card_color': card_color,
      });
      return jsonDecode(response.body);
    } catch (error) {
      Fluttertoast.showToast(msg: error.toString());
    }
  }

  /*
  * get all table_use detail
  * */
  getAllTableUseDetail(branch_id) async {
    try {
      var response = await http.post(Domain.table_use, body: {
        'getAllTableUseDetail': '1',
        'branch_id': branch_id,
      });
      return jsonDecode(response.body);
    } catch (error) {
      Fluttertoast.showToast(msg: error.toString());
    }
  }

  /*
  * get all table_use detail after date
  * */
  getAllTableUseDetailAfterDate(branch_id, date_from) async {
    try {
      var response = await http.post(Domain.table_use, body: {
        'getAllTableUseDetailAfterDate': '1',
        'branch_id': branch_id,
        'date_from': date_from
      });
      return jsonDecode(response.body);
    } catch (error) {
      Fluttertoast.showToast(msg: error.toString());
    }
  }

  /*
  * get transfer owner
  * */
  getTransferOwner(branch_id) async {
    try {
      var response = await http.post(Domain.transfer_owner, body: {
        'getTransferOwner': '1',
        'branch_id': branch_id,
      });
      return jsonDecode(response.body);
    } catch (error) {
      Fluttertoast.showToast(msg: error.toString());
    }
  }

  /*
  * get transfer owner after date
  * */
  getTransferOwnerAfterDate(branch_id, date_from) async {
    try {
      var response = await http.post(Domain.transfer_owner, body: {
        'getTransferOwnerAfterDate': '1',
        'branch_id': branch_id,
        'date_from': date_from,
      });
      return jsonDecode(response.body);
    } catch (error) {
      Fluttertoast.showToast(msg: error.toString());
    }
  }

/*
  --------------------Sync part----------------------------------------------------------------------------------------------------------------------------------------------
*/
  /*
  * clear sync record
  * */
  clearAllSyncRecord(branch_id) async {
    try {
      var response = await http.post(Domain.sync_record, body: {
        'clear_sync_status': '1',
        'branch_id': branch_id,
      });
      return jsonDecode(response.body);
    } catch (error) {
      Fluttertoast.showToast(msg: error.toString());
    }
  }

  /*
  * get all sync_record
  * */
  getAllSyncRecord(branch_id, device_id, value) async {
    try {
      print("sync record domain called!");
      var response = await http.post(Domain.sync_record, body: {
        'sync': '1',
        'branch_id': branch_id,
        'device_id': device_id,
        'value': value
      }).timeout(Duration(seconds: 8), onTimeout: ()=> throw TimeoutException("Timeout"));
      return jsonDecode(response.body);
    } on TimeoutException catch(_){
      print('domain sync record time out');
      Map<String, dynamic>? result = {'status': '8'};
      return result;
    } catch (error) {
      Map<String, dynamic>? result = {'status': '9'};
      return result;
      //Fluttertoast.showToast(msg: error.toString());
    }
  }



  /*
  * update all cloud sync_record
  * */
  updateAllCloudSyncRecord(branch_id, String sync_list) async {
    try {
      var response = await http.post(Domain.sync_record, body: {
        'response_sync': '1',
        'branch_id': branch_id,
        'sync_list': sync_list
      });
      print('domain call:${response.body}');
      return jsonDecode(response.body);
    } catch (error) {
      Fluttertoast.showToast(msg: error.toString());
    }
  }


  /*
  * check device login
  * */
  checkDeviceLogin({required device_id, required value}) async{
    try{
      var response = await http.post(Domain.sync_to_cloud, body: {
        'getAllDeviceLogin': '1',
        'device_id': device_id,
        'value': value,
      }).timeout(Duration(seconds: 3), onTimeout: ()=> throw TimeoutException("Timeout"));
      return jsonDecode(response.body);
    }on TimeoutException catch(_){
      print('domain checkDeviceLogin timeout');
      Map<String, dynamic>? result = {'status': '8'};
      return result;
    }  catch(error){
      print('checkDeviceLogin error: ${error}');
      //Fluttertoast.showToast(msg: error.toString());
    }
  }

  /*
  * sync all local update to cloud
  * */
  syncLocalUpdateToCloud(
      {device_id,
        value,
        isSync,
        isManualSync,
        order_value,
        order_tax_value,
        order_promotion_value,
        table_use_value,
        table_use_detail_value,
        order_cache_value,
        order_detail_value,
        order_detail_delete_value,
        order_modifier_value,
        cash_record_value,
        app_setting_value,
        transfer_owner_value,
        receipt_value,
        refund_value,
        branch_link_product_value,
        settlement_value,
        settlement_link_payment_value,
        order_detail_cancel_value,
        printer_value,
        printer_link_category_value,
        printer_link_category_delete_value,
        table_value,
        user_value,
        checklist_value,
        kitchen_list_value,
        attendance_value,
        order_payment_split_value,
        dynamic_qr_value
      }) async {
    try {
      //print('order cache value 15 sync: ${order_cache_value}');
      var response = await http.post(Domain.sync_to_cloud, body: {
        'all_local_update': '1',
        'device_id': device_id,
        'isManualSync': isManualSync != null ? '1': '0',
        'value': value,
        'tb_order_create': order_value != null ? order_value : [].toString(),
        'tb_order_tax_detail_create': order_tax_value != null ? order_tax_value: [].toString(),
        'tb_order_promotion_detail_create': order_promotion_value != null ? order_promotion_value: [].toString(),
        'tb_table_use_create': table_use_value != null ? table_use_value: [].toString(),
        'tb_table_use_detail_create': table_use_detail_value != null ? table_use_detail_value : [].toString(),
        'tb_order_cache_create': order_cache_value != null ? order_cache_value : [].toString(),
        'tb_order_detail_create': order_detail_value != null ? order_detail_value : [].toString(),
        'tb_order_detail_delete': order_detail_delete_value != null ? order_detail_delete_value : [].toString(),
        'tb_order_modifier_detail_create': order_modifier_value != null ? order_modifier_value : [].toString(),
        'tb_cash_record_create': cash_record_value != null ? cash_record_value : [].toString(),
        'tb_app_setting_create': app_setting_value != null ? app_setting_value : [].toString(),
        'tb_transfer_owner_create': transfer_owner_value != null ? transfer_owner_value : [].toString(),
        'tb_receipt_create': receipt_value != null ? receipt_value : [].toString(),
        'tb_refund_create': refund_value != null ? refund_value : [].toString(),
        'tb_branch_link_product_sync': branch_link_product_value != null ? branch_link_product_value : [].toString(),
        'tb_settlement_create': settlement_value != null ? settlement_value : [].toString(),
        'tb_settlement_link_payment_create': settlement_link_payment_value != null ? settlement_link_payment_value : [].toString(),
        'tb_order_detail_cancel_create': order_detail_cancel_value != null ? order_detail_cancel_value : [].toString(),
        'tb_printer_create': printer_value != null ? printer_value : [].toString(),
        'tb_printer_link_category_sync': printer_link_category_value != null ? printer_link_category_value : [].toString(),
        'tb_printer_link_category_delete': printer_link_category_delete_value != null ? printer_link_category_delete_value : [].toString(),
        'tb_table_sync': table_value != null ? table_value : [].toString(),
        'tb_user_sync': user_value != null ? user_value : [].toString(),
        'tb_checklist_create': checklist_value != null ? checklist_value : [].toString(),
        'tb_kitchen_list_create': kitchen_list_value != null ? kitchen_list_value : [].toString(),
        'tb_attendance_create': attendance_value != null ? attendance_value : [].toString(),
        'tb_order_payment_split_create': order_payment_split_value != null ? order_payment_split_value : [].toString(),
        'tb_dynamic_qr_create': dynamic_qr_value != null ? dynamic_qr_value : [].toString()
      }).timeout(Duration(seconds: isManualSync != null ? 120 : isSync != null ? 25 : 15), onTimeout: () => throw TimeoutException("Time out"));
      print('response in domain: ${jsonDecode(response.body)}');
      return jsonDecode(response.body);
    } on TimeoutException catch(_){
      print('domain sync to cloud time out');
      FLog.error(
        className: "domain",
        text: "sync to cloud timeout",
        exception: _,
      );
      Map<String, dynamic>? result = {'status': '8'};
      return result;
    }
    catch (error) {
      print('domain sync to cloud error: ${error}');
      FLog.error(
        className: "domain",
        text: "sync to cloud error",
        exception: error,
      );
      Map<String, dynamic>? result = {'status': '8'};
      return result;
      //Fluttertoast.showToast(msg: error.toString());
    }
  }

  /*
  * sync printer to cloud
  * */
  SyncPrinterToCloud(detail) async {
    try {
      var response = await http.post(Domain.sync_to_cloud, body: {
        'tb_printer_create': '1',
        'details': detail,
      });

      return jsonDecode(response.body);
    } catch (error) {
      print('domain error: ${error}');
      Fluttertoast.showToast(msg: error.toString());
    }
  }

  /*
  * sync order to cloud
  * */
  SyncOrderToCloud(detail) async {
    try {
      var response = await http.post(Domain.sync_to_cloud, body: {
        'tb_order_create': '1',
        'details': detail,
      });
      return jsonDecode(response.body);
    } catch (error) {
      Fluttertoast.showToast(msg: error.toString());
    }
  }

  /*
  * sync updated order to cloud
  * */
  SyncUpdatedOrderToCloud(detail) async {
    try {
      var response = await http.post(Domain.sync_to_cloud, body: {
        'tb_order_update': '1',
        'details': detail,
      });
      return jsonDecode(response.body);
    } catch (error) {
      Fluttertoast.showToast(msg: error.toString());
    }
  }

  /*
  * sync order tax detail to cloud
  * */
  SyncOrderTaxDetailToCloud(detail) async {
    try {
      var response = await http.post(Domain.sync_to_cloud, body: {
        'tb_order_tax_detail_create': '1',
        'details': detail,
      });

      return jsonDecode(response.body);
    } catch (error) {
      Fluttertoast.showToast(msg: error.toString());
    }
  }

  /*
  * sync order promotion detail to cloud
  * */
  SyncOrderPromotionDetailToCloud(detail) async {
    try {
      var response = await http.post(Domain.sync_to_cloud, body: {
        'tb_order_promotion_detail_create': '1',
        'details': detail,
      });

      return jsonDecode(response.body);
    } catch (error) {
      Fluttertoast.showToast(msg: error.toString());
    }
  }

  /*
  * sync updated order tax detail to cloud
  * */
  SyncUpdatedOrderTaxDetailToCloud(detail) async {
    try {
      var response = await http.post(Domain.sync_to_cloud, body: {
        'tb_order_tax_detail_update': '1',
        'details': detail,
      });

      return jsonDecode(response.body);
    } catch (error) {
      Fluttertoast.showToast(msg: error.toString());
    }
  }

  /*
  * sync updated order promotion detail to cloud
  * */
  SyncUpdatedOrderPromotionDetailToCloud(detail) async {
    try {
      var response = await http.post(Domain.sync_to_cloud, body: {
        'tb_order_promotion_detail_update': '1',
        'details': detail,
      });

      return jsonDecode(response.body);
    } catch (error) {
      Fluttertoast.showToast(msg: error.toString());
    }
  }

  /*
  * sync order cache to cloud
  * */
  SyncOrderCacheToCloud(detail) async {
    try {
      var response = await http.post(Domain.sync_to_cloud, body: {
        'tb_order_cache_create': '1',
        'details': detail,
      });

      return jsonDecode(response.body);
    } catch (error) {
      print('domain error: ${error}');
      Fluttertoast.showToast(msg: error.toString());
    }
  }

  /*
  * sync order cache to cloud
  * */
  SyncUpdatedOrderCacheToCloud(detail) async {
    try {
      var response = await http.post(Domain.sync_to_cloud, body: {
        'tb_order_cache_update': '1',
        'details': detail,
      });

      return jsonDecode(response.body);
    } catch (error) {
      print('domain error: ${error}');
      Fluttertoast.showToast(msg: error.toString());
    }
  }

  /*
  * sync order detail to cloud
  * */
  SyncOrderDetailToCloud(detail) async {
    try {
      var response = await http.post(Domain.sync_to_cloud, body: {
        'tb_order_detail_create': '1',
        'details': detail,
      });

      return jsonDecode(response.body);
    } catch (error) {
      print('domain error: ${error}');
      Fluttertoast.showToast(msg: error.toString());
    }
  }

  /*
  * sync updated order detail to cloud
  * */
  SyncUpdatedOrderDetailToCloud(detail) async {
    try {
      var response = await http.post(Domain.sync_to_cloud, body: {
        'tb_order_detail_update': '1',
        'details': detail,
      });

      return jsonDecode(response.body);
    } catch (error) {
      print('domain error: ${error}');
      Fluttertoast.showToast(msg: error.toString());
    }
  }

  /*
  * sync order modifier detail to cloud
  * */
  SyncOrderModifierDetailToCloud(detail) async {
    try {
      var response = await http.post(Domain.sync_to_cloud, body: {
        'tb_order_modifier_detail_create': '1',
        'details': detail,
      });

      return jsonDecode(response.body);
    } catch (error) {
      print('domain error: ${error}');
      Fluttertoast.showToast(msg: error.toString());
    }
  }

  /*
  * sync updated order modifier detail to cloud
  * */
  SyncUpdatedOrderModifierDetailToCloud(detail) async {
    try {
      var response = await http.post(Domain.sync_to_cloud, body: {
        'tb_order_modifier_detail_update': '1',
        'details': detail,
      });

      return jsonDecode(response.body);
    } catch (error) {
      print('domain error: ${error}');
      Fluttertoast.showToast(msg: error.toString());
    }
  }

  /*
  * sync table use to cloud
  * */
  SyncTableUseToCloud(detail) async {
    try {
      var response = await http.post(Domain.sync_to_cloud, body: {
        'tb_table_use_create': '1',
        'details': detail,
      });

      return jsonDecode(response.body);
    } catch (error) {
      print('domain error: ${error}');
      Fluttertoast.showToast(msg: error.toString());
    }
  }

  /*
  * sync updated table use to cloud
  * */
  SyncUpdatedTableUseToCloud(detail) async {
    try {
      var response = await http.post(Domain.sync_to_cloud, body: {
        'tb_table_use_update': '1',
        'details': detail,
      });

      return jsonDecode(response.body);
    } catch (error) {
      print('domain error: ${error}');
      Fluttertoast.showToast(msg: error.toString());
    }
  }

  /*
  * sync table use detail to cloud
  * */
  SyncTableUseDetailToCloud(detail) async {
    try {
      var response = await http.post(Domain.sync_to_cloud, body: {
        'tb_table_use_detail_create': '1',
        'details': detail,
      });

      return jsonDecode(response.body);
    } catch (error) {
      print('domain error: ${error}');
      Fluttertoast.showToast(msg: error.toString());
    }
  }

  /*
  * sync updated table use detail to cloud
  * */
  SyncUpdatedTableUseDetailToCloud(detail) async {
    try {
      var response = await http.post(Domain.sync_to_cloud, body: {
        'tb_table_use_detail_update': '1',
        'details': detail,
      });

      return jsonDecode(response.body);
    } catch (error) {
      print('domain error: ${error}');
      Fluttertoast.showToast(msg: error.toString());
    }
  }

  /*
  * sync updated pos table to cloud
  * */
  SyncUpdatedPosTableToCloud(detail) async {
    try {
      var response = await http.post(Domain.sync_to_cloud, body: {
        'tb_table_update': '1',
        'details': detail,
      });

      return jsonDecode(response.body);
    } catch (error) {
      print('domain error: ${error}');
      Fluttertoast.showToast(msg: error.toString());
    }
  }

  /*
  * sync cash record to cloud
  * */
  SyncCashRecordToCloud(detail) async {
    try {
      var response = await http.post(Domain.sync_to_cloud, body: {
        'tb_cash_record_create': '1',
        'details': detail,
      });
      return jsonDecode(response.body);
    } catch (error) {
      Fluttertoast.showToast(msg: error.toString());
    }
  }

  /*
  * sync cash record to cloud
  * */
  SyncAppSettingToCloud(detail) async {
    try {
      var response = await http.post(Domain.sync_to_cloud, body: {
        'tb_app_setting_create': '1',
        'details': detail,
      });
      print("SyncAppSettingToCloud success");
      return jsonDecode(response.body);

    } catch (error) {
      Fluttertoast.showToast(msg: error.toString());
    }
  }

  /*
  * sync updated cash record to cloud
  * */
  SyncUpdatedCashRecordToCloud(detail) async {
    try {
      var response = await http.post(Domain.sync_to_cloud, body: {
        'tb_cash_record_update': '1',
        'details': detail,
      });
      return jsonDecode(response.body);
    } catch (error) {
      Fluttertoast.showToast(msg: error.toString());
    }
  }

  /*
  * sync transfer owner to cloud
  * */
  SyncTransferOwnerToCloud(detail) async {
    try{
      var response = await http.post(Domain.sync_to_cloud, body: {
        'tb_transfer_owner_create': '1',
        'details': detail,
      });
      return jsonDecode(response.body);
    } catch(error){
      Fluttertoast.showToast(msg: error.toString());
    }
  }

  /*
  * sync refund to cloud
  * */
  SyncRefundToCloud(detail) async {
    try{
      var response = await http.post(Domain.sync_to_cloud, body: {
        'tb_refund_create': '1',
        'details': detail,
      });
      return jsonDecode(response.body);
    } catch(error){
      Fluttertoast.showToast(msg: error.toString());
    }
  }

  /*
  * sync order detail to cloud
  * */
  SyncBranchLinkProductToCloud(detail) async {
    try {
      var response = await http.post(Domain.sync_to_cloud, body: {
        'tb_branch_link_product_update': '1',
        'details': detail,
      });

      return jsonDecode(response.body);
    } catch (error) {
      print('domain error: ${error}');
      Fluttertoast.showToast(msg: error.toString());
    }
  }

  /*
  * sync settlement to cloud
  * */
  SyncSettlementToCloud(detail) async {
    try {
      var response = await http.post(Domain.sync_to_cloud, body: {
        'tb_settlement_create': '1',
        'details': detail,
      });

      return jsonDecode(response.body);
    } catch (error) {
      print('domain error: ${error}');
      Fluttertoast.showToast(msg: error.toString());
    }
  }

  /*
  * sync settlement link payment to cloud
  * */
  SyncSettlementLinkPaymentToCloud(detail) async {
    try {
      var response = await http.post(Domain.sync_to_cloud, body: {
        'tb_settlement_link_payment_create': '1',
        'details': detail,
      });

      return jsonDecode(response.body);
    } catch (error) {
      print('domain error: ${error}');
      Fluttertoast.showToast(msg: error.toString());
    }
  }

  /*
  * sync order detail cancel to cloud
  * */
  SyncOrderDetailCancelToCloud(detail) async {
    try {
      var response = await http.post(Domain.sync_to_cloud, body: {
        'tb_order_detail_cancel_create': '1',
        'details': detail,
      });

      return jsonDecode(response.body);
    } catch (error) {
      print('domain error: ${error}');
      Fluttertoast.showToast(msg: error.toString());
    }
  }

/*
  ---------------QR Order---------------------------------------------------------------------------------------------------------------------------------------------------------------
*/

  /*
  * sync order from cloud (Qr order)
  * */
  SyncQrOrderFromCloud(String branch_id, String company_id) async {
    try {
      var response = await http.post(Domain.qr_order_sync, body: {
        'get_new_qr_order': '1',
        'branch_id': branch_id,
        'company_id': company_id
      }).timeout(Duration(seconds: 120), onTimeout: ()=> throw TimeoutException("Timeout"));

      return jsonDecode(response.body);
    } on TimeoutException catch(_){
      print('domain qr order sync timeout');
      Map<String, dynamic>? result = {'status': '8'};
      return result;
    } catch (error) {
      print('domain error: ${error}');
      Map<String, dynamic>? result = {'status': '9'};
      return result;
      //Fluttertoast.showToast(msg: error.toString());
    }
  }

  /*
  * sync order from cloud (Qr order)
  * */
  updateCloudOrderCacheSyncStatus(String order_cache_key) async {
    try {
      var response = await http.post(Domain.qr_order_sync, body: {
        'tb_order_cache_sync_update': '1',
        'order_cache_key': order_cache_key,
      });
      return jsonDecode(response.body);
    } catch (error) {
      print('domain error: ${error}');
      Fluttertoast.showToast(msg: error.toString());
    }
  }

/*
  ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
*/

  /*
  * update branch notification token to cloud
  * */
  updateBranchNotificationToken(token, branch_id) async {
    try {
      var response = await http.post(Domain.sync_record, body: {
        'updateToken': '1',
        'token': token,
        'branch_id': branch_id.toString(),
      });
      return jsonDecode(response.body);
    } catch (error) {
      print('domain call error: ${error}');
      Fluttertoast.showToast(msg: error.toString());
    }
  }

  /*
  * get all table_use
  * */
  insertTableUseDetail(table_use_id, table_id, original_table_id) async {
    try {
      var response = await http.post(Domain.table_use, body: {
        'insertTableUseDetail': '1',
        'table_use_id': table_use_id,
        'table_id': table_id,
        'original_table_id': original_table_id,
      });
      return jsonDecode(response.body);
    } catch (error) {
      Fluttertoast.showToast(msg: error.toString());
    }
  }

  /*
  * get all branch user
  * */
  getBranchLinkUser(branch_id) async {
    try {
      var response = await http.post(Domain.user, body: {
        'getBranchLinkUser': '1',
        'branch_id': branch_id,
      });
      return jsonDecode(response.body);
    } catch (error) {
      Fluttertoast.showToast(msg: error.toString());
    }
  }

  /*
  * get all branch table
  * */
  getAllTable(branch_id) async {
    try {
      var response = await http.post(Domain.table, body: {
        'getAllTable': '1',
        'branch_id': branch_id,
      });
      return jsonDecode(response.body);
    } catch (error) {
      Fluttertoast.showToast(msg: error.toString());
    }
  }

  /*
  * insert branch table
  * */
  insertTable(seats, number, branch_id, table_url) async {
    try {
      var response = await http.post(Domain.table, body: {
        'addTable': '1',
        'seats': seats,
        'number': number,
        'branch_id': branch_id,
        'table_url': table_url,
      });
      return jsonDecode(response.body);
    } catch (error) {
      Fluttertoast.showToast(msg: error.toString());
    }
  }

  /*
  * edit branch table
  * */
  editTable(seats, number, table_id) async {
    try {
      var response = await http.post(Domain.table, body: {
        'editTable': '1',
        'seats': seats,
        'number': number,
        'table_id': table_id,
      });
      return jsonDecode(response.body);
    } catch (error) {
      Fluttertoast.showToast(msg: error.toString());
    }
  }

  /*
  * edit table coordinate
  * */
  editTableCoordinate(table_list) async {
    try {
      var response = await http.post(Domain.table, body: {
        'updateCoordinate': '1',
        'table_list': table_list,
      });
      return jsonDecode(response.body);
    } catch (error) {
      Fluttertoast.showToast(msg: error.toString());
    }
  }

  /*
  * edit branch table
  * */
  editTableStatus(status, table_id) async {
    try {
      var response = await http.post(Domain.table, body: {
        'editTableStatus': '1',
        'status': status,
        'table_id': table_id,
      });
      return jsonDecode(response.body);
    } catch (error) {
      Fluttertoast.showToast(msg: error.toString());
    }
  }

  /*
  * delete branch table
  * */
  deleteBranchTable(table_id) async {
    try {
      var response = await http.post(Domain.table, body: {
        'delete': '1',
        'table_id': table_id,
      });
      return jsonDecode(response.body);
    } catch (error) {
      Fluttertoast.showToast(msg: error.toString());
    }
  }

  /*
  * get all dining option
  * */
  getAllDiningOption(company_id) async {
    try {
      var response = await http.post(Domain.dining_option, body: {
        'getAllDiningOption': '1',
        'company_id': company_id,
      });
      return jsonDecode(response.body);
    } catch (error) {
      Fluttertoast.showToast(msg: error.toString());
    }
  }

  /*
  * get branch link dining option
  * */
  getBranchLinkDiningOption(branch_id) async {
    try {
      var response = await http.post(Domain.dining_option, body: {
        'getBranchLinkDiningOption': '1',
        'branch_id': branch_id,
      });
      return jsonDecode(response.body);
    } catch (error) {
      Fluttertoast.showToast(msg: error.toString());
    }
  }

  /*
  * get all company tax
  * */
  getAllTax(company_id) async {
    try {
      var response = await http.post(Domain.tax, body: {
        'getAllTax': '1',
        'company_id': company_id,
      });
      return jsonDecode(response.body);
    } catch (error) {
      Fluttertoast.showToast(msg: error.toString());
    }
  }

  /*
  * get branch link tax
  * */
  getBranchLinkTax(branch_id) async {
    try {
      var response = await http.post(Domain.tax, body: {
        'getBranchLinkTax': '1',
        'branch_id': branch_id,
      });
      return jsonDecode(response.body);
    } catch (error) {
      Fluttertoast.showToast(msg: error.toString());
    }
  }

  /*
  * get tax link dining
  * */
  getTaxLinkDining(branch_id) async {
    try {
      var response = await http.post(Domain.tax, body: {
        'getTaxLinkDining': '1',
        'branch_id': branch_id,
      });
      return jsonDecode(response.body);
    } catch (error) {
      Fluttertoast.showToast(msg: error.toString());
    }
  }

  /*
  * get all categories
  * */
  getAllCategory(company_id) async {
    try {
      var response = await http.post(Domain.categories, body: {
        'getAllCategory': '1',
        'company_id': company_id,
      });
      return jsonDecode(response.body);
    } catch (error) {
      Fluttertoast.showToast(msg: error.toString());
    }
  }

  /*
  * insert categories to cloud
  * */
  insertCategory(color, name, company_id) async {
    try {
      var response = await http.post(Domain.categories, body: {
        'addCategories': '1',
        'color': color,
        'name': name,
        'company_id': company_id,
      });
      return jsonDecode(response.body);
    } catch (error) {
      Fluttertoast.showToast(msg: error.toString());
    }
  }

  /*
  * insert categories to cloud
  * */
  editCategory(color, name, category_id) async {
    try {
      var response = await http.post(Domain.categories, body: {
        'editCategories': '1',
        'color': color,
        'name': name,
        'category_id': category_id,
      });
      return jsonDecode(response.body);
    } catch (error) {
      Fluttertoast.showToast(msg: error.toString());
    }
  }

  /*
  * insert categories to cloud
  * */
  deleteCategory(category_id) async {
    try {
      var response = await http.post(Domain.categories, body: {
        'deleteCategories': '1',
        'category_id': category_id,
      });
      return jsonDecode(response.body);
    } catch (error) {
      Fluttertoast.showToast(msg: error.toString());
    }
  }

  /*
  * get all promotion
  * */
  getAllPromotion(company_id) async {
    try {
      var response = await http.post(Domain.promotion, body: {
        'getAllPromotion': '1',
        'company_id': company_id,
      });
      return jsonDecode(response.body);
    } catch (error) {
      Fluttertoast.showToast(msg: error.toString());
    }
  }

  /*
  * get branch link promotion
  * */
  getBranchLinkPromotion(branch_id) async {
    try {
      var response = await http.post(Domain.promotion, body: {
        'getBranchLinkPromotion': '1',
        'branch_id': branch_id,
      });
      return jsonDecode(response.body);
    } catch (error) {
      Fluttertoast.showToast(msg: error.toString());
    }
  }

  /*
  * get customer
  * */
  getAllCustomer(company_id) async {
    try {
      var response = await http.post(Domain.customer, body: {
        'getAllCustomer': '1',
        'company_id': company_id,
      });
      return jsonDecode(response.body);
    } catch (error) {
      Fluttertoast.showToast(msg: error.toString());
    }
  }

  /*
  * get bill
  * */
  getAllBill(company_id, branch_id) async {
    try {
      var response = await http.post(Domain.bill,
          body: {'getAllCustomer': '1', 'company_id': company_id, 'branch_id': branch_id});
      return jsonDecode(response.body);
    } catch (error) {
      Fluttertoast.showToast(msg: error.toString());
    }
  }

  /*
  * get payment option
  * */
  getPaymentLinkCompany(company_id) async {
    try {
      var response = await http
          .post(Domain.payment, body: {'getPaymentLinkCompany': '1', 'company_id': company_id});
      return jsonDecode(response.body);
    } catch (error) {
      Fluttertoast.showToast(msg: error.toString());
    }
  }

  /*
  * get refund
  * */
  getAllRefund(company_id, branch_id) async {
    try {
      var response = await http.post(Domain.refund,
          body: {'getAllRefund': '1', 'company_id': company_id, 'branch_id': branch_id});
      return jsonDecode(response.body);
    } catch (error) {
      Fluttertoast.showToast(msg: error.toString());
    }
  }

  /*
  * get refund after date
  * */
  getAllRefundAfterDate(company_id, branch_id, date_from) async {
    try {
      var response = await http.post(Domain.refund,
          body: {'getAllRefundAfterDate': '1', 'company_id': company_id, 'branch_id': branch_id, 'date_from': date_from});
      return jsonDecode(response.body);
    } catch (error) {
      Fluttertoast.showToast(msg: error.toString());
    }
  }

  /*
  * get modifier group name
  * */
  getModifierGroup(company_id) async {
    try {
      var response = await http
          .post(Domain.modifier, body: {'getModifierGroup': '1', 'company_id': company_id});
      return jsonDecode(response.body);
    } catch (error) {
      Fluttertoast.showToast(msg: error.toString());
    }
  }

  /*
  * get modifier item
  * */
  getModifierItem(company_id) async {
    try {
      var response = await http
          .post(Domain.modifier, body: {'getModifierItem': '1', 'company_id': company_id});
      return jsonDecode(response.body);
    } catch (error) {
      Fluttertoast.showToast(msg: error.toString());
    }
  }

  /*
  * get branch link modifier
  * */
  getBranchLinkModifier(branch_id) async {
    try {
      var response = await http
          .post(Domain.modifier, body: {'getBranchLinkModifier': '1', 'branch_id': branch_id});
      return jsonDecode(response.body);
    } catch (error) {
      Fluttertoast.showToast(msg: error.toString());
    }
  }

  /*
  * get product
  * */
  getAllProduct(company_id) async {
    try {
      var response = await http.post(Domain.product, body: {'getAllProduct': '1', 'company_id': company_id});
      return jsonDecode(response.body);
    } catch (error) {
      Fluttertoast.showToast(msg: error.toString());
    }
  }

  /*
  * insert product
  * */
  insertProduct(name, category_id, description, price, SKU, availableSale, hasVariant, stockType,
      dailyLimit, stockQuantity, graphic, color, imageName, company_id) async {
    try {
      var response = await http.post(Domain.product, body: {
        'addProduct': '1',
        'pName': name,
        'pCategories': category_id,
        'pDescription': description,
        'pPrice': price,
        'pSKU': SKU,
        'availableSale': availableSale,
        'hasVariant': hasVariant,
        'stockType': stockType,
        'dailyLimit': dailyLimit,
        'stockQuantity': stockQuantity,
        'graphic': graphic,
        'color': color,
        'image_name': imageName,
        'company_id': company_id,
      });
      return jsonDecode(response.body);
    } catch (error) {
      Fluttertoast.showToast(msg: error.toString());
    }
  }

  /*
  * update product
  * */
  updateProduct(name, category_id, description, price, SKU, availableSale, hasVariant, stockType,
      dailyLimit, stockQuantity, graphic, color, imageName, product_id) async {
    try {
      var response = await http.post(Domain.product, body: {
        'editProduct': '1',
        'pID': product_id,
        'pName': name,
        'pCategories': category_id,
        'pDescription': description,
        'pPrice': price,
        'pSKU': SKU,
        'availableSale': availableSale,
        'hasVariant': hasVariant,
        'stockType': stockType,
        'dailyLimit': dailyLimit,
        'stockQuantity': stockQuantity,
        'graphic': graphic,
        'color': color,
        'imageName': imageName,
      });
      return jsonDecode(response.body);
    } catch (error) {
      Fluttertoast.showToast(msg: error.toString());
    }
  }

  /*
  * delete product
  * */
  deleteProduct(product_id, branch_id) async {
    try {
      var response = await http.post(Domain.product,
          body: {'deleteProduct': '1', 'product_id': product_id, 'branch_id': branch_id});
      return jsonDecode(response.body);
    } catch (error) {
      Fluttertoast.showToast(msg: error.toString());
    }
  }

  /*
  * get branch link product
  * */
  getBranchLinkProduct(branch_id) async {
    try {
      var response = await http
          .post(Domain.product, body: {'getBranchLinkProduct': '1', 'branch_id': branch_id});
      return jsonDecode(response.body);
    } catch (error) {
      Fluttertoast.showToast(msg: error.toString());
    }
  }

  /*
  * insert branch link product
  * */
  insertBranchLinkProduct(branch_id, product_id, hasVariant, product_variant_id, SKU, price,
      stockType, quantity) async {
    try {
      var response = await http.post(Domain.product, body: {
        'addBranchLinkProduct': '1',
        'branch_id': branch_id,
        'product_id': product_id,
        'hasVariant': hasVariant,
        'product_variant_id': product_variant_id,
        'b_SKU': SKU,
        'price': price,
        'stockType': stockType,
        'quantity': quantity
      });
      return jsonDecode(response.body);
    } catch (error) {
      Fluttertoast.showToast(msg: error.toString());
    }
  }

  /*
  * edit branch link product
  * */
  editBranchLinkProductForVariant(branch_id, product_id, product_variant_id, daily_limit, price,
      stockType, stock_quantity) async {
    try {
      var response = await http.post(Domain.product, body: {
        'updateBranchLinkProductForVariant': '1',
        'branch_id': branch_id,
        'product_id': product_id,
        'product_variant_id': product_variant_id,
        'price': price,
        'stockType': stockType,
        'daily_limit': daily_limit,
        'stock_quantity': stock_quantity
      });
      return jsonDecode(response.body);
    } catch (error) {
      Fluttertoast.showToast(msg: error.toString());
    }
  }

  /*
  * edit branch link product
  * */
  editBranchLinkProduct(
      branch_id, product_id, daily_limit, price, stockType, stock_quantity) async {
    try {
      var response = await http.post(Domain.product, body: {
        'updateBranchLinkProduct': '1',
        'branch_id': branch_id,
        'product_id': product_id,
        'price': price,
        'stockType': stockType,
        'daily_limit': daily_limit,
        'stock_quantity': stock_quantity
      });
      return jsonDecode(response.body);
    } catch (error) {
      Fluttertoast.showToast(msg: error.toString());
    }
  }

  /*
  * delete branch link product
  * */
  deleteBranchLinkProduct(branch_id, product_id, product_variant_id) async {
    try {
      var response = await http.post(Domain.product, body: {
        'deleteBranchLinkProduct': '1',
        'branch_id': branch_id,
        'product_id': product_id,
        'product_variant_id': product_variant_id
      });
      return jsonDecode(response.body);
    } catch (error) {
      Fluttertoast.showToast(msg: error.toString());
    }
  }

  /*
  * get modifier link product
  * */
  getModifierLinkProduct(company_id, branch_id) async {
    try {
      var response = await http.post(Domain.product,
          body: {'getModifierLinkProduct': '1', 'company_id': company_id, 'branch_id': branch_id});
      return jsonDecode(response.body);
    } catch (error) {
      Fluttertoast.showToast(msg: error.toString());
    }
  }

  /*
  * insert product modifier
  * */
  insertModifierLinkProduct(mod_group_id, product_id) async {
    try {
      var response = await http.post(Domain.product, body: {
        'addProductModifier': '1',
        'mod_group_id': mod_group_id,
        'product_id': product_id,
      });
      return jsonDecode(response.body);
    } catch (error) {
      Fluttertoast.showToast(msg: error.toString());
    }
  }

  /*
  * delete product modifier
  * */
  deleteModifierLinkProduct(product_id, mod_group_id) async {
    try {
      var response = await http.post(Domain.product, body: {
        'deleteModLinkProduct': '1',
        'product_id': product_id,
        'mod_group_id': mod_group_id
      });
      return jsonDecode(response.body);
    } catch (error) {
      Fluttertoast.showToast(msg: error.toString());
    }
  }

  /*
  * get variant group
  * */
  getVariantGroup(company_id) async {
    try {
      var response = await http.post(Domain.variant, body: {
        'getVariantGroup': '1',
        'company_id': company_id,
      });
      return jsonDecode(response.body);
    } catch (error) {
      Fluttertoast.showToast(msg: error.toString());
    }
  }

  /*
  * insert variant group
  * */
  insertVariantGroup(name, product_id) async {
    try {
      var response = await http.post(Domain.product, body: {
        'addVariantGroup': '1',
        'name': name,
        'product_id': product_id,
      });
      return jsonDecode(response.body);
    } catch (error) {
      Fluttertoast.showToast(msg: error.toString());
    }
  }

  /*
  * delete variant group
  * */
  deleteVariantGroup(product_id, variant_group_id) async {
    try {
      var response = await http.post(Domain.product, body: {
        'deleteVariantGroup': '1',
        'product_id': product_id,
        'variant_group_id': variant_group_id,
      });
      return jsonDecode(response.body);
    } catch (error) {
      Fluttertoast.showToast(msg: error.toString());
    }
  }

  /*
  * get variant item
  * */
  getVariantItem(company_id) async {
    try {
      var response = await http.post(Domain.variant, body: {
        'getVariantItem': '1',
        'company_id': company_id,
      });
      return jsonDecode(response.body);
    } catch (error) {
      Fluttertoast.showToast(msg: error.toString());
    }
  }

  /*
  * insert variant item
  * */
  insertVariantItem(name, variant_group_id) async {
    try {
      var response = await http.post(Domain.product, body: {
        'addVariantItem': '1',
        'name': name,
        'variant_group_id': variant_group_id,
      });
      return jsonDecode(response.body);
    } catch (error) {
      Fluttertoast.showToast(msg: error.toString());
    }
  }

  /*
  * delete variant item
  * */
  deleteVariantItem(variant_group_id) async {
    try {
      var response = await http.post(Domain.product, body: {
        'deleteVariantItem': '1',
        'variant_group_id': variant_group_id,
      });
      return jsonDecode(response.body);
    } catch (error) {
      Fluttertoast.showToast(msg: error.toString());
    }
  }

  /*
  * get product variant
  * */
  getProductVariant(company_id) async {
    try {
      var response = await http.post(Domain.variant, body: {
        'getProductVariant': '1',
        'company_id': company_id,
      });
      return jsonDecode(response.body);
    } catch (error) {
      Fluttertoast.showToast(msg: error.toString());
    }
  }

  /*
  * insert product variant
  * */
  insertProductVariant(product_id, name, SKU, price, stockType, quantity) async {
    try {
      var response = await http.post(Domain.product, body: {
        'addProductVariant': '1',
        'product_id': product_id,
        'name': name,
        'SKU': SKU,
        'price': price,
        'stockType': stockType,
        'quantity': quantity
      });
      return jsonDecode(response.body);
    } catch (error) {
      Fluttertoast.showToast(msg: error.toString());
    }
  }

  /*
  * delete product variant
  * */
  deleteProductVariant(product_id, product_variant_id) async {
    try {
      var response = await http.post(Domain.product, body: {
        'deleteProductVariant': '1',
        'product_id': product_id,
        'product_variant_id': product_variant_id
      });
      return jsonDecode(response.body);
    } catch (error) {
      Fluttertoast.showToast(msg: error.toString());
    }
  }

  /*
  * get product variant detail
  * */
  getProductVariantDetail(company_id) async {
    try {
      var response = await http.post(Domain.variant, body: {
        'getProductVariantDetail': '1',
        'company_id': company_id,
      });
      return jsonDecode(response.body);
    } catch (error) {
      Fluttertoast.showToast(msg: error.toString());
    }
  }

  /*
  * insert product variant detail
  * */
  insertProductVariantDetail(product_variant_id, variant_item_id) async {
    try {
      var response = await http.post(Domain.product, body: {
        'addProductVariantDetail': '1',
        'product_variant_id': product_variant_id,
        'variant_item_id': variant_item_id
      });
      return jsonDecode(response.body);
    } catch (error) {
      Fluttertoast.showToast(msg: error.toString());
    }
  }

  /*
  * delete product variant detail
  * */
  deleteProductVariantDetail(product_variant_id) async {
    try {
      var response = await http.post(Domain.product,
          body: {'deleteProductVariantDetail': '1', 'product_variant_id': product_variant_id});
      return jsonDecode(response.body);
    } catch (error) {
      Fluttertoast.showToast(msg: error.toString());
    }
  }

  /*
  * get all order
  * */
  getAllOrder(company_id, branch_id) async {
    try {
      var response = await http.post(Domain.order,
          body: {'getAllOrder': '1', 'company_id': company_id, 'branch_id': branch_id});
      return jsonDecode(response.body);
    } catch (error) {
      Fluttertoast.showToast(msg: error.toString());
    }
  }

  /*
  * get all order after
  * */
  getAllOrderAfterDate(company_id, branch_id, date_from) async {
    try {
      var response = await http.post(Domain.order,
          body: {'getAllOrderAfterDate': '1', 'company_id': company_id, 'branch_id': branch_id, 'date_from': date_from});
      return jsonDecode(response.body);
    } catch (error) {
      Fluttertoast.showToast(msg: error.toString());
    }
  }

  /*
  * get all order promotion detail
  * */
  getAllOrderPromotionDetail(company_id, branch_id) async {
    try {
      var response = await http.post(Domain.order,
          body: {'getAllOrderPromotionDetail': '1', 'company_id': company_id, 'branch_id': branch_id});
      return jsonDecode(response.body);
    } catch (error) {
      Fluttertoast.showToast(msg: error.toString());
    }
  }

  /*
  * get all order promotion detail
  * */
  getAllOrderTaxDetail(company_id, branch_id) async {
    try {
      var response = await http.post(Domain.order,
          body: {'getAllOrderTaxDetail': '1', 'company_id': company_id, 'branch_id': branch_id});
      return jsonDecode(response.body);
    } catch (error) {
      Fluttertoast.showToast(msg: error.toString());
    }
  }

  /*
  * get all order tax detail after date
  * */
  getAllOrderTaxDetailAfterDate(company_id, branch_id, date_from) async {
    try {
      var response = await http.post(Domain.order,
          body: {'getAllOrderTaxDetailAfterDate': '1', 'company_id': company_id, 'branch_id': branch_id, 'date_from': date_from});
      return jsonDecode(response.body);
    } catch (error) {
      Fluttertoast.showToast(msg: error.toString());
    }
  }

  /*
  * get all order cache
  * */
  getAllOrderCache(company_id, branch_id) async {
    try {
      var response = await http.post(Domain.order,
          body: {'getAllOrderCache': '1', 'company_id': company_id, 'branch_id': branch_id});
      return jsonDecode(response.body);
    } catch (error) {
      Fluttertoast.showToast(msg: error.toString());
    }
  }

  /*
  * get all order cache after date
  * */
  getAllOrderCacheAfterDate(company_id, branch_id, date_from) async {
    try {
      var response = await http.post(Domain.order,
          body: {'getAllOrderCacheAfterDate': '1', 'company_id': company_id, 'branch_id': branch_id, 'date_from': date_from});
      return jsonDecode(response.body);
    } catch (error) {
      Fluttertoast.showToast(msg: error.toString());
    }
  }

  /*
  * insert order cache
  * */
  insertOrderCache(
      company_id, branch_id, table_use_id, table_id, dining_id, order_by, total_amount) async {
    try {
      var response = await http.post(Domain.order, body: {
        'insertOrderCache': '1',
        'company_id': company_id,
        'branch_id': branch_id,
        'table_use_id': table_use_id,
        'table_id': table_id,
        'dining_id': dining_id,
        'order_by': order_by,
        'total_amount': total_amount
      });
      print(jsonDecode(response.body));
      return jsonDecode(response.body);
    } catch (error) {
      Fluttertoast.showToast(msg: error.toString());
    }
  }

  /*
  * edit order cache table id
  * */
  editOrderCache(order_cache_id, table_id) async {
    try {
      var response = await http.post(Domain.order, body: {
        'editOrderCache': '1',
        'order_cache_id': order_cache_id,
        'table_id': table_id,
      });
      print(jsonDecode(response.body));
      return jsonDecode(response.body);
    } catch (error) {
      Fluttertoast.showToast(msg: error.toString());
    }
  }

  /*
  * delete order cache
  * */
  deleteOrderCache(order_cache_id) async {
    try {
      var response = await http.post(Domain.order, body: {
        'deleteOrderCache': '1',
        'order_cache_id': order_cache_id,
      });
      print(jsonDecode(response.body));
      return jsonDecode(response.body);
    } catch (error) {
      Fluttertoast.showToast(msg: error.toString());
    }
  }

  /*
  * get all order detail
  * */
  getAllOrderDetail(company_id, branch_id) async {
    try {
      var response = await http.post(Domain.order,
          body: {'getAllOrderDetail': '1', 'company_id': company_id, 'branch_id': branch_id});
      return jsonDecode(response.body);
    } catch (error) {
      Fluttertoast.showToast(msg: error.toString());
    }
  }

  /*
  * insert order detail
  * */
  insertOrderDetail(order_cache_id, branch_link_product_id, product_name, has_variant,
      product_variant_name, price, quantity, remark, account) async {
    try {
      var response = await http.post(Domain.order, body: {
        'insertOrderDetail': '1',
        'order_cache_id': order_cache_id,
        'branch_link_product_id': branch_link_product_id,
        'product_name': product_name,
        'has_variant': has_variant,
        'product_variant_name': product_variant_name,
        'price': price,
        'quantity': quantity,
        'remark': remark,
        'account': account,
      });
      print(jsonDecode(response.body));
      return jsonDecode(response.body);
    } catch (error) {
      Fluttertoast.showToast(msg: error.toString());
    }
  }

  /*
  * delete order detail
  * */
  deleteOrderDetail(order_cache_id) async {
    try {
      var response = await http.post(Domain.order, body: {
        'deleteOrderDetail': '1',
        'order_cache_id': order_cache_id,
      });
      print(jsonDecode(response.body));
      return jsonDecode(response.body);
    } catch (error) {
      Fluttertoast.showToast(msg: error.toString());
    }
  }

  /*
  * get all order modifier detail
  * */
  getAllOrderModifierDetail(company_id, branch_id) async {
    try {
      var response = await http.post(Domain.order, body: {
        'getAllOrderModifierDetail': '1',
        'company_id': company_id,
        'branch_id': branch_id
      });
      return jsonDecode(response.body);
    } catch (error) {
      Fluttertoast.showToast(msg: error.toString());
    }
  }

  /*
  * get all order detail cancel
  * */
  getAllOrderDetailCancel(company_id, branch_id) async {
    try {
      var response = await http.post(Domain.order, body: {
        'getAllOrderDetailCancel': '1',
        'company_id': company_id,
        'branch_id': branch_id
      });
      return jsonDecode(response.body);
    } catch (error) {
      Fluttertoast.showToast(msg: error.toString());
    }
  }

  /*
  * insert order modifier detail
  * */
  insertOrderModifierDetail(order_detail_id, mod_item_id, mod_group_id) async {
    try {
      var response = await http.post(Domain.order, body: {
        'insertOrderModifierDetail': '1',
        'order_detail_id': order_detail_id,
        'mod_item_id': mod_item_id,
        'mod_group_id': mod_group_id
      });
      print(jsonDecode(response.body));
      return jsonDecode(response.body);
    } catch (error) {
      Fluttertoast.showToast(msg: error.toString());
    }
  }

  /*
  * delete order modifier detail
  * */
  deleteOrderModifierDetail(order_detail_id) async {
    try {
      var response = await http.post(Domain.order, body: {
        'deleteOrderModifierDetail': '1',
        'order_detail_id': order_detail_id,
      });
      print(jsonDecode(response.body));
      return jsonDecode(response.body);
    } catch (error) {
      Fluttertoast.showToast(msg: error.toString());
    }
  }

  /*
  * get sale
  * */
  getSale(company_id, branch_id) async {
    try {
      var response = await http.post(Domain.sale,
          body: {'getSale': '1', 'company_id': company_id, 'branch_id': branch_id});
      return jsonDecode(response.body);
    } catch (error) {
      Fluttertoast.showToast(msg: error.toString());
    }
  }

  /*
  * get settlement
  * */
  getSettlement(company_id, branch_id) async {
    try {
      var response = await http.post(Domain.settlement,
          body: {'getAllSettlement': '1', 'company_id': company_id, 'branch_id': branch_id});
      return jsonDecode(response.body);
    } catch (error) {
      Fluttertoast.showToast(msg: error.toString());
    }
  }

  /*
  * get settlement after date
  * */
  getSettlementAfterDate(company_id, branch_id, date_from) async {
    try {
      var response = await http.post(Domain.settlement,
          body: {'getSettlementAfterDate': '1', 'company_id': company_id, 'branch_id': branch_id, 'date_from': date_from});
      return jsonDecode(response.body);
    } catch (error) {
      Fluttertoast.showToast(msg: error.toString());
    }
  }

  /*
  * get settlement link payment
  * */
  getSettlementLinkPayment(company_id, branch_id) async {
    try {
      var response = await http.post(Domain.settlement,
          body: {'getAllSettlementLinkPayment': '1', 'company_id': company_id, 'branch_id': branch_id});
      return jsonDecode(response.body);
    } catch (error) {
      Fluttertoast.showToast(msg: error.toString());
    }
  }

  /*
  * get settlement link payment after date
  * */
  getSettlementLinkPaymentAfterDate(company_id, branch_id, date_from) async {
    try {
      var response = await http.post(Domain.settlement,
          body: {'getAllSettlementLinkPaymentAfterDate': '1', 'company_id': company_id, 'branch_id': branch_id, 'date_from': date_from});
      return jsonDecode(response.body);
    } catch (error) {
      Fluttertoast.showToast(msg: error.toString());
    }
  }

  /*
  * get cash record
  * */
  getCashRecord(company_id, branch_id) async {
    try {
      var response = await http.post(Domain.cash_record,
          body: {'getAllCashRecord': '1', 'company_id': company_id, 'branch_id': branch_id});
      return jsonDecode(response.body);
    } catch (error) {
      Fluttertoast.showToast(msg: error.toString());
    }
  }

  /*
  * get cash record after date
  * */
  getCashRecordAfterDate(company_id, branch_id, date_from) async {
    try {
      var response = await http.post(Domain.cash_record,
          body: {'getCashRecordAfterDate': '1', 'company_id': company_id, 'branch_id': branch_id, 'date_from': date_from});
      return jsonDecode(response.body);
    } catch (error) {
      Fluttertoast.showToast(msg: error.toString());
    }
  }

  /*
  * get cash record opening balance after date
  * */
  getCashRecordOBAfterDate(company_id, branch_id, date_from) async {
    try {
      var response = await http.post(Domain.cash_record,
          body: {'getCashRecordOBAfterDate': '1', 'company_id': company_id, 'branch_id': branch_id, 'date_from': date_from});
      return jsonDecode(response.body);
    } catch (error) {
      Fluttertoast.showToast(msg: error.toString());
    }
  }

  /*
  * get subscription
  * */
  getSubscription(company_id) async {
    try {
      var response = await http.post(Domain.subscription,
          body: {'getAllSubscription': '1', 'company_id': company_id});
      return jsonDecode(response.body);
    } catch (error) {
      Fluttertoast.showToast(msg: error.toString());
    }
  }

  /*
  * get app setting
  * */
  getAppSetting(branch_id) async {
    try {
      var response = await http.post(Domain.app_setting,
          body: {'getAllAppSetting': '1', 'branch_id': branch_id});
      return jsonDecode(response.body);
    } catch (error) {
      Fluttertoast.showToast(msg: error.toString());
    }
  }

  /*
  * get printer
  * */
  getPrinter(branch_id) async {
    try {
      var response = await http.post(Domain.printer,
          body: {'getAllPrinter': '1', 'branch_id': branch_id});
      return jsonDecode(response.body);
    } catch (error) {
      Fluttertoast.showToast(msg: error.toString());
    }
  }

  /*
  * get printer
  * */
  getPrinterCategory(branch_id) async {
    try {
      var response = await http.post(Domain.printer,
          body: {'getAllPrinterLinkCategory': '1', 'branch_id': branch_id});
      return jsonDecode(response.body);
    } catch (error) {
      Fluttertoast.showToast(msg: error.toString());
    }
  }

  /**
  * get receipt
  * */
  getReceipt(branch_id) async {
    try {
      var response = await http.post(Domain.receipt,
          body: {'getReceipt': '1', 'branch_id': branch_id});
      return jsonDecode(response.body);
    } catch (error) {
      Fluttertoast.showToast(msg: error.toString());
    }
  }

  /**
   * get checklist
   * */
  getChecklist(branch_id) async {
    try {
      var response = await http.post(Domain.checklist, body: {
        'getAllChecklist': '1',
        'branch_id': branch_id,
      });
      return jsonDecode(response.body);
    } catch (error) {
      Fluttertoast.showToast(msg: error.toString());
    }
  }

  /**
   * get kitchen list
   * */
  getKitchenList(branch_id) async {
    try {
      var response = await http.post(Domain.kitchen_list, body: {
        'getAllKitchenList': '1',
        'branch_id': branch_id,
      });
      return jsonDecode(response.body);
    } catch (error) {
      Fluttertoast.showToast(msg: error.toString());
    }
  }

  /*
  * store image to cloud
  * */
  storeProductImage(image, image_name, company_id) async {
    try {
      var response = await http.post(Domain.product, body: {
        'storeImage': '1',
        'image': image,
        'image_name': image_name,
        'company_id': company_id,
      });
      return jsonDecode(response.body);
    } catch (error) {
      Fluttertoast.showToast(msg: error.toString());
    }
  }

  /*
  * delete image from cloud
  * */
  deleteProductImage(image_name, company_id) async {
    try {
      var response = await http.post(Domain.product, body: {
        'deleteImage': '1',
        'image_name': image_name,
        'company_id': company_id,
      });
      return jsonDecode(response.body);
    } catch (error) {
      Fluttertoast.showToast(msg: error.toString());
    }
  }

  /*
  * insert current version
  * */
  insertCurrentVersionDay(data) async {
    try {
      var response = await http.post(Domain.current_version, body: {
        'data': data,
      });
      print(jsonDecode(response.body));
      return jsonDecode(response.body);
    } catch (error) {
      Fluttertoast.showToast(msg: error.toString());
    }
  }

  isHostReachable() async {
    try {
      await http.post(Domain.login).timeout(Duration(seconds: 20), onTimeout: () => throw TimeoutException("Timeout"));
      return true;
    } catch (e) {
      print('host check error: $e');
      return false;
    }
  }
}
