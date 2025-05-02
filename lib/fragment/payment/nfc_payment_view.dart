import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
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
  StreamController<String> btnStreamController = StreamController<String>();
  StreamController<String> btnTextStreamController = StreamController<String>();
  NFCPayment payment = NFCPayment();
  bool isButtonDisable = false;
  List<cartProductItem> itemList = [];
  late Stream<String> btnStream;
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
    return StreamBuilder<String>(
        stream: btnStream,
        builder: (context, snapshot) {
          return ElevatedButton.icon(
              style: ButtonStyle(
                backgroundColor: WidgetStateProperty.all(Colors.green),
                padding: WidgetStateProperty.all(EdgeInsets.all(10)),
              ),
              onPressed: isButtonDisable ? null : () async {
                asyncQ.addJob((_) async {
                  try{
                    String? referenceNo = await generateRefNo();
                    if(referenceNo != null){
                      //use actual amount in prod
                      await payment.startPayment(amount: "5800", ref_no: referenceNo);
                    } else {
                      throw Exception("Generate reference error");
                    }
                  }catch(e){
                    print("error: $e");
                  }
                });
              },
              icon: Icon(Icons.call_received, size: 20),
              label: buildBtnText()
          );
      }
    );
  }

  Widget buildBtnText() {
   return StreamBuilder<String>(
       stream: btnTextStream,
       builder: (context, snapshot) {
         return Text(
             snapshot.hasData ? snapshot.data! : "Start scan",
             style: TextStyle(fontSize: 16),
         );
       },
   );
  }

  void initTrxStreamSub(){
    _trxStreamSub = payment.transactionEvents.listen((event) {
      var jsonResponse = jsonDecode(event);
      print("trx status: ${jsonResponse[NFCPaymentFields.status]}");
      if(jsonResponse[NFCPaymentFields.status] == 0){
        if(jsonResponse['data'] != null){
          var jsonData = jsonDecode(jsonResponse['data']);
          var trxDetail = NFCPayment.fromJson(jsonData);
          //we will extract the success here
          widget.callBack(trxDetail.transaction_id!, trxDetail.reference_no!);
          print("trans id: ${jsonData[NFCPaymentFields.transaction_id]}");
          print("ref no: ${jsonData[NFCPaymentFields.reference_no]}");
        }
      }
    }, onError: (error) {
      print("onError: ${error.toString()}");
    });
  }

  void initTrxUIStreamSub(){
    String UIMessage = "Start scan";
    _trxUIStreamSub = payment.transactionUIEvents.listen((event) {
      print("event: $event");
      var jsonResponse = jsonDecode(event);
      if(jsonResponse['data'] != null){
        UIMessage = jsonResponse['data'];
      }
      if(jsonResponse[NFCPaymentFields.status] == 0 || jsonResponse[NFCPaymentFields.status] == 1){
        btnTextStreamController.sink.add(UIMessage);
      }
      // btnStreamController.sink.add(UIMessage);
    }, onError: (error) {
      print("onError: ${error.toString()}");
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

