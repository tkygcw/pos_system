import 'dart:async';
import 'dart:convert';

import 'package:f_logs/model/flog/flog.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pos_system/fragment/custom_toastification.dart';
import 'package:pos_system/object/cart_product.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../main.dart';
import '../../object/nfc_payment/nfc_payment.dart';
import '../../translation/AppLocalizations.dart';

enum PaymentUIEvent {
  Unknown, //= 255,
  PresentCard, //= 71,
  PresentCardTimeout, //= 74,
  CardPresented,//= 72,
  CardReadOk, // = 23,
  CardReadError,  //= 24,
  CardReadRetry, //= 25,
  EnterPin, //= 65,
  CancelPin, //= 66,
  PinBypass, //= 67,
  PinEnterTimeout, //= 68,
  PinEntered, //= 69,
  Authorising, //= 73,
  RequestSignature, //= 70,
  RequiredCDCVM, //= 80,
  Cancel, //1
  StartScan //0
}

class NfcPaymentView extends StatelessWidget {
  final String finalAmount;
  final Function(String transactionID, String referenceNo) callBack;
  const NfcPaymentView({Key? key, required this.finalAmount, required this.callBack}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(finalAmount),
        Container(
          height: 150,
          margin: EdgeInsets.only(bottom: 10, top: 10),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16.0),
            child: Image(image: AssetImage("drawable/duitNow.jpg")),
          ),
        ),
        _ScanButton(
          callBack: callBack,
        )

      ],
    );
  }
}

class _ScanButton extends StatefulWidget {
  final Function(String transactionID, String referenceNo) callBack;
  const _ScanButton({Key? key, required this.callBack}) : super(key: key);

  @override
  State<_ScanButton> createState() => _ScanButtonState();
}

class _ScanButtonState extends State<_ScanButton> {
  final String startScan = "Start scan";
  StreamController<bool> btnStreamController = StreamController<bool>();
  StreamController<String> btnTextStreamController = StreamController<String>();
  NFCPayment payment = NFCPayment();
  bool isButtonDisable = false;
  List<cartProductItem> itemList = [];
  late Stream<bool> btnStream;
  late Stream<String> btnTextStream;
  late StreamSubscription _trxUIStreamSub;
  late StreamSubscription _trxStreamSub;

  @override
  void initState() {
    btnStream = btnStreamController.stream;
    btnTextStream = btnTextStreamController.stream;
    initTrxStreamSub();
    initTrxUIStreamSub();
    super.initState();
  }

  @override
  void dispose() {
    _trxUIStreamSub.cancel();
    _trxStreamSub.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<bool>(
        stream: btnStream,
        initialData: false,
        builder: (context, snapshot) {
          return ElevatedButton.icon(
              style: ButtonStyle(
                backgroundColor: WidgetStateProperty.all(Colors.green),
                padding: WidgetStateProperty.all(EdgeInsets.all(10)),
              ),
              onPressed: snapshot.data == false ? () async {
                asyncQ.addJob((_) async {
                  try{
                    String? referenceNo = await generateRefNo();
                    if(referenceNo != null){
                      //use actual amount in prod
                      await payment.startPayment(amount: "58000", ref_no: referenceNo);
                    } else {
                      throw Exception("Generate reference error");
                    }
                  }catch(e){
                    print("error: $e");
                  }
                });
              } : null,
              icon: Icon(Icons.call_received, size: 20),
              label: buildBtnText()
          );
      }
    );
  }

  Widget buildBtnText() {
   return StreamBuilder<String>(
       stream: btnTextStream,
       initialData: startScan,
       builder: (context, snapshot) {
         return Text(
             snapshot.data!,
             style: TextStyle(fontSize: 16),
         );
       },
   );
  }

  void initTrxStreamSub(){
    _trxStreamSub = payment.transactionEvents.listen((event) {
      var jsonResponse = jsonDecode(event);
      if(jsonResponse['data'] != null){
        var jsonData = jsonDecode(jsonResponse['data']);
        payment = NFCPayment.fromJson(jsonData);
      }
      print("trx status: ${jsonResponse[NFCPaymentFields.status]}");
      if(jsonResponse[NFCPaymentFields.status] == 0){
        widget.callBack(payment.transaction_id!, payment.reference_no!);
        print("trans id: ${payment.transaction_id!}");
        print("ref no: ${payment.reference_no}");
      } else {
        Navigator.of(context).pop();
        CustomFailedToast.showToast(
            title: "Transaction Failed: ${jsonResponse[NFCPaymentFields.status]}",
            description: "${payment.trxStatusCode}-${payment.trxStatusMsg}",
            duration: 8
        );
      }
    }, onError: (error) {
      print("onError: ${error.toString()}");
    });
  }

  void initTrxUIStreamSub(){
    String UIMessage = startScan;
    _trxUIStreamSub = payment.transactionUIEvents.listen((event) {
      print("event: $event");
      var jsonResponse = jsonDecode(event);
      if(jsonResponse['data'] != null){
        UIMessage = jsonResponse['data'];
      }
      if(jsonResponse[NFCPaymentFields.status] == 71){
        return;
      } else if (jsonResponse[NFCPaymentFields.status] == 72)  {
        btnStreamController.sink.add(true);
      } else {
        btnTextStreamController.sink.add(UIMessage);
      }
    }, onError: (error) {
      print("onError: ${error.toString()}");
      btnTextStreamController.sink.add(startScan);
      btnStreamController.sink.add(false);
      CustomFailedToast.showToast(title: "UI stream error");
      FLog.error(
        className: "nfc_payment_view",
        text: "listen UI stream error",
        exception: error,
      );
    });
  }

  Future<String?> generateRefNo() async {
    final prefs = await SharedPreferences.getInstance();
    final int? branch_id = prefs.getInt('branch_id');
    DateFormat dateFormat = DateFormat("yyyy-MM-dd HH:mm:ss");
    String dateTime = dateFormat.format(DateTime.now());
    String? refNo;
    refNo = 'Fiuu-${branch_id!.toString()}-${dateTime.replaceAll(' ', '').replaceAll('-', '').replaceAll(':', '')}';
    return refNo;
  }
}

