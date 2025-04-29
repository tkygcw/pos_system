import 'dart:convert';

import 'package:flutter/services.dart';

class NFCPaymentFields {
  static String trx_status_code = 'trx_status_code';
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

class NFCPayment {
  static const  MethodChannel _paymentChannel = MethodChannel('optimy.com.my/nfcPayment');
  final EventChannel _paymentEventChannel = EventChannel('optimy.com.my/paymentEvent');
  static const _INIT_PAYMENT = 'initPayment';
  static const _START_TRX = 'startTrx';
  static const _VOID_TRX = 'voidTrx';
  static const _TRX_STATUS = 'trxStatus';
  static const _SETTLEMENT = 'settlement';
  String? trxStatusCode ;
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

  NFCPayment({
    this.trxStatusCode,
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

  static NFCPayment fromJson(Map<String, Object?> json) => NFCPayment(
    trxStatusCode: json[NFCPaymentFields.trx_status_code] as String?,
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

  Stream<String> get transactionEvents {
    return _paymentEventChannel.receiveBroadcastStream().map((event) => event.toString());
  }

  static initPayment() async {
    await _paymentChannel.invokeMethod(_INIT_PAYMENT);
  }

  refreshToken() async {
    await _paymentChannel.invokeMethod("refreshToken");
  }

  startPayment({required String amount, required String ref_no}) async {
    Map<String, dynamic> value = {
      NFCPaymentFields.amount: amount,
      NFCPaymentFields.reference_no: ref_no
    };
    var result = await _paymentChannel.invokeMethod(_START_TRX, jsonEncode(value));
    print("startPayment result: ${result}");
  }

  voidTransaction({required transactionID}) async {
    Map<String, dynamic> value = {
      NFCPaymentFields.transaction_id: transactionID
    };
    print(jsonEncode(value));
    var result = await _paymentChannel.invokeMethod(_VOID_TRX, jsonEncode(value));
  }

  getTransactionStatus({String? transactionID, String? referenceNo}) async {
    Map<String, dynamic> value = {
      NFCPaymentFields.transaction_id: transactionID,
      NFCPaymentFields.reference_no: referenceNo
    };
    print(jsonEncode(value));
    var result = await _paymentChannel.invokeMethod(_TRX_STATUS, jsonEncode(value));
  }

  Future<void> performSettlement() async {
    await _paymentChannel.invokeMethod(_SETTLEMENT);
  }

}