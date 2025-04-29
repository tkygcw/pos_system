import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pos_system/object/nfc_payment/nfc_payment.dart';

class NfcPaymentPage extends StatefulWidget {
  const NfcPaymentPage({Key? key}) : super(key: key);

  @override
  State<NfcPaymentPage> createState() => _NfcPaymentPageState();
}

class _NfcPaymentPageState extends State<NfcPaymentPage> {
  NFCPayment payment = NFCPayment();
  String onData = 'Listening...';
  late StreamSubscription _streamSubscription;
  late String transactionID;
  String? referenceNo;

  @override
  void initState() {
    _streamSubscription = payment.transactionEvents.listen((event) {
      print("event: $event");
      var jsonResponse = jsonDecode(event);
      if(jsonResponse[NFCPaymentFields.status] == 0) {
        if(jsonResponse['data'] != null){
          var jsonData = jsonDecode(jsonResponse['data']);
          var trxDetail = NFCPayment.fromJson(jsonData);
          //we will extract the success here
          transactionID = trxDetail.transaction_id!;
          referenceNo = trxDetail.reference_no;
          print("trans id: ${jsonData[NFCPaymentFields.transaction_id]}");
          print("ref no: ${jsonData[NFCPaymentFields.reference_no]}");
        }
      }
      setState(() {
        onData = jsonResponse['data'];
      });
    }, onError: (error) {
      print("onError: ${error.toString()}");
    });
    super.initState();
  }

  @override
  void dispose() {
    _streamSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ElevatedButton(
              onPressed: () async {
                //await NFCPayment.initPayment();
                print("init done");
              },
              child: Text("NFC payment init"),
            ),
            ElevatedButton(
              onPressed: () async {
                await payment.refreshToken();
                print("refresh token done");
              },
              child: Text("Refresh token"),
            ),
            ElevatedButton(
              onPressed: () async {
                DateFormat dateFormat = DateFormat("yyyy-MM-dd HH:mm:ss");
                String dateTime = dateFormat.format(DateTime.now());
                await payment.startPayment(amount: "5800", ref_no: "order${dateTime.replaceAll(' ', '').replaceAll('-', '').replaceAll(':', '')}");
                print("done");
              },
              child: Text("Start payment"),
            ),
            ElevatedButton(
              onPressed: () async {
                await payment.voidTransaction(transactionID: transactionID);
                print("done");
              },
              child: Text("Void/Refund payment"),
            ),
            ElevatedButton(
              onPressed: () async {
                await payment.getTransactionStatus(transactionID: transactionID, referenceNo: referenceNo);
                print("done");
              },
              child: Text("Get transaction status"),
            ),
            ElevatedButton(
              onPressed: () async {
                await payment.performSettlement();
                print("done");
              },
              child: Text("Perform settlement"),
            ),
            Text(onData),
          ],
        ),
      ),
    );
  }
}
