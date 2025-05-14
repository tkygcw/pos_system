import 'dart:convert';
import 'dart:io';

import 'package:f_logs/model/flog/flog.dart';
import 'package:flutter/services.dart';

class NFCPaymentFields {
  static String trx_status_code = 'trx_status_code';
  static String trx_status_msg = 'trx_status_msg';
  static String transaction_id = 'transaction_id';
  static String reference_no = 'ref_no';
  static String approval_code = 'approval_code';
  static String card_number = 'card_number';
  static String card_holder_name = 'card_holder_name';
  static String acquirer_id = 'acquirer_id';
  static String contactless_CVM_type = 'contactless_CVM_type';
  static String RRN = 'rrn';
  static String trace_no = 'trace_no';
  static String transaction_datetime = 'transaction_datetime';
  static String transaction_date = 'transaction_date';
  static String amount = 'amount';
  static String amount_auth = 'amount_auth';
  static String status = 'status';
  static String batch_no = 'batch_no';
  static String invoice_no = 'invoice_no';
  static String aid = 'aid';
  static String application_label = 'application_label';
  static String card_type = 'card_type';
}

class NFCPaymentResponse {
  String? trxStatusCode;
  String? trxStatusMsg;
  String? transaction_id;
  String? reference_no ;
  String? approval_code;
  String? card_number;
  String? card_holder_name ;
  String? acquirer_id;
  String? contactless_CVM_type;
  String? RRN;
  String? trace_no;
  String? transaction_datetime;
  String? transaction_date;
  String? amount;
  String? amount_auth;
  String? batch_no;
  String? invoice_no;
  String? aid;
  String? application_label;
  String? card_type;

  NFCPaymentResponse({
    this.trxStatusCode,
    this.trxStatusMsg,
    this.transaction_id,
    this.reference_no,
    this.approval_code,
    this.card_number,
    this.card_holder_name,
    this.acquirer_id,
    this.contactless_CVM_type,
    this.RRN,
    this.trace_no,
    this.transaction_datetime,
    this.transaction_date,
    this.amount,
    this.amount_auth,
    this.batch_no,
    this.invoice_no,
    this.aid,
    this.application_label,
    this.card_type
  });

  static NFCPaymentResponse fromJson(Map<String, Object?> json) => NFCPaymentResponse(
      trxStatusCode: json[NFCPaymentFields.trx_status_code] as String?,
      trxStatusMsg: json[NFCPaymentFields.trx_status_msg] as String?,
      transaction_id: json[NFCPaymentFields.transaction_id] as String?,
      reference_no: json[NFCPaymentFields.reference_no] as String?,
      approval_code: json[NFCPaymentFields.approval_code] as String?,
      card_number: json[NFCPaymentFields.card_number] as String?,
      card_holder_name: json[NFCPaymentFields.card_holder_name] as String?,
      acquirer_id: json[NFCPaymentFields.acquirer_id] as String?,
      contactless_CVM_type: json[NFCPaymentFields.contactless_CVM_type] as String?,
      RRN: json[NFCPaymentFields.RRN] as String?,
      trace_no: json[NFCPaymentFields.trace_no] as String?,
      transaction_datetime: json[NFCPaymentFields.transaction_datetime] as String?,
      transaction_date: json[NFCPaymentFields.transaction_date] as String?,
      amount: json[NFCPaymentFields.amount] as String?,
      amount_auth: json[NFCPaymentFields.amount_auth] as String?,
      batch_no: json[NFCPaymentFields.batch_no] as String?,
      invoice_no: json[NFCPaymentFields.invoice_no] as String?,
      aid: json[NFCPaymentFields.aid] as String?,
      application_label: json[NFCPaymentFields.application_label] as String?,
      card_type: json[NFCPaymentFields.card_type] as String?
  );
}

class NFCPayment {
  static const  MethodChannel _paymentChannel = MethodChannel('optimy.com.my/nfcPayment');
  static const EventChannel _transactionUIEvents = EventChannel('optimy.com.my/transactionUIEvent');
  static const EventChannel _transactionEvents = EventChannel('optimy.com.my/transactionEvent');
  static const _INIT_PAYMENT = 'initPayment';
  static const _START_TRX = 'startTrx';
  static const _VOID_TRX = 'voidTrx';
  static const _CANCEL_TRX = 'cancelTrx';
  static const _TRX_STATUS = 'trxStatus';
  static const _SETTLEMENT = 'settlement';

  static Stream<String> get transactionUIEvents {
    return _transactionUIEvents.receiveBroadcastStream().map((event) => event.toString());
  }

  static Stream<String> get transactionEvents {
    return _transactionEvents.receiveBroadcastStream().map((event) => event.toString());
  }

  static initPaymentSDK() async {
    try{
      if(Platform.isAndroid){
        var result = await _paymentChannel.invokeMethod(_INIT_PAYMENT);
        FLog.info(
          className: "nfc_payment",
          text: "initPaymentSDK",
          exception: result,
        );
      }
    }catch(e, s){
      FLog.error(
        className: "nfc_payment",
        text: "initPaymentSDK",
        exception: "Error: $e, Stacktrace: $s",
      );
    }
  }

  static Future<void> refreshToken({required String uniqueID}) async {
    if(Platform.isAndroid){
      var status = await _paymentChannel.invokeMethod("refreshToken", uniqueID);
      FLog.info(
        className: "nfc_payment",
        text: "refreshToken",
        exception: status
      );
    }
  }

  static Future<void> startPayment({required String amount, required String ref_no}) async {
    Map<String, dynamic> value = {
      NFCPaymentFields.amount: amount,
      NFCPaymentFields.reference_no: ref_no
    };
    if(Platform.isAndroid){
      await _paymentChannel.invokeMethod(_START_TRX, jsonEncode(value));
    }
  }

  static Future<String?> voidTransaction({required transactionID}) async {
    Map<String, dynamic> value = {
      NFCPaymentFields.transaction_id: transactionID
    };
    if(Platform.isAndroid){
      var result = await _paymentChannel.invokeMethod(_VOID_TRX, jsonEncode(value));
      print("refund result: $result");
      if(result != null) {
        return result;
      }
    }
    return null;
  }

  static Future<void> cancelTransaction() async {
    if(Platform.isAndroid){
      await _paymentChannel.invokeMethod(_CANCEL_TRX);
    }
  }

  getTransactionStatus({String? transactionID, String? referenceNo}) async {
    Map<String, dynamic> value = {
      NFCPaymentFields.transaction_id: transactionID,
      NFCPaymentFields.reference_no: referenceNo
    };
    print(jsonEncode(value));
    var result = await _paymentChannel.invokeMethod(_TRX_STATUS, jsonEncode(value));
  }

  static Future<void> performSettlement() async {
    if(Platform.isAndroid){
      await _paymentChannel.invokeMethod(_SETTLEMENT);
    }
  }

}