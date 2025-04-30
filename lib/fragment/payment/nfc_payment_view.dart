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
  RequiredCDCVM //= 80,
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
  StreamController<String> btnTextController = StreamController<String>();
  NFCPayment payment = NFCPayment();
  bool isButtonDisable = false;
  List<cartProductItem> itemList = [];
  late Stream<String> btnTextStream;
  late StreamSubscription _streamSubscription;

  @override
  void initState() {
    btnTextStream = btnTextController.stream;
    _streamSubscription = payment.transactionEvents.listen((event) {
      print("event: $event");
      var jsonResponse = jsonDecode(event);
      if(jsonResponse[NFCPaymentFields.status] == 0){
        if(jsonResponse['data'] != null){
          var jsonData = jsonDecode(jsonResponse['data']);
          var trxDetail = NFCPayment.fromJson(jsonData);
          //we will extract the success here
          widget.callBack(trxDetail.transaction_id!, trxDetail.reference_no!);
          print("trans id: ${jsonData[NFCPaymentFields.transaction_id]}");
          print("ref no: ${jsonData[NFCPaymentFields.reference_no]}");
        }
      } else {
        switch(jsonResponse[NFCPaymentFields.status]) {
          case 23 : {
            btnTextController.sink.add(PaymentUIEvent.CardReadOk.name);
          }break;
          case 24 : {
            btnTextController.sink.add(PaymentUIEvent.CardReadError.name);
          }break;
          case 25 : {
            btnTextController.sink.add(PaymentUIEvent.CardReadRetry.name);
          }break;
          case 65 : {
            btnTextController.sink.add(PaymentUIEvent.EnterPin.name);
          }break;
          case 66 : {
            btnTextController.sink.add(PaymentUIEvent.CancelPin.name);
          }break;
          case 67 : {
            btnTextController.sink.add(PaymentUIEvent.PinBypass.name);
          }break;
          case 68 : {
            btnTextController.sink.add(PaymentUIEvent.PinEnterTimeout.name);
          }break;
          case 69 : {
            btnTextController.sink.add(PaymentUIEvent.PinEntered.name);
          }break;
          case 70 : {
            btnTextController.sink.add(PaymentUIEvent.RequestSignature.name);
          }break;
          case 71 : {
            btnTextController.sink.add(PaymentUIEvent.PresentCard.name);
          }break;
          case 72 : {
            btnTextController.sink.add(PaymentUIEvent.CardPresented.name);
          }break;
          case 73: {
            btnTextController.sink.add(PaymentUIEvent.Authorising.name);
          }break;
          case 74: {
            btnTextController.sink.add(PaymentUIEvent.PresentCardTimeout.name);
          }break;
          case 80: {
            btnTextController.sink.add(PaymentUIEvent.RequiredCDCVM.name);
          }break;
          default: {
            btnTextController.sink.add(PaymentUIEvent.Unknown.name);
          }
        }
      }
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
    return StreamBuilder<String>(
        stream: btnTextStream,
        builder: (context, snapshot) {
          return ElevatedButton.icon(
              style: ButtonStyle(
                backgroundColor: WidgetStateProperty.all(Colors.green),
                padding: WidgetStateProperty.all(EdgeInsets.all(10)),
              ),
              onPressed: isButtonDisable
                  ? null
                  : () async {
                setState(() {
                  isButtonDisable = true;
                });
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
              label: Text(snapshot.hasData ? snapshot.data! : AppLocalizations.of(context)!.translate('payment_received'), style: TextStyle(fontSize: 16))
          );
      }
    );
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

