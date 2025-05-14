import 'dart:async';
import 'dart:convert';

import 'package:app_settings/app_settings.dart';
import 'package:f_logs/model/flog/flog.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pos_system/fragment/custom_toastification.dart';
import 'package:pos_system/object/cart_product.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../main.dart';
import '../../object/nfc_payment/nfc_payment.dart';
import '../../translation/AppLocalizations.dart';
import '../../utils/Utils.dart';

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
  StartScan, //0
  Cancel, //1
  NFCRequired, //2
  InvalidToken //3
}

class NfcPaymentView extends StatelessWidget {
  final String finalAmount;
  final Function(String transactionID, String referenceNo) callBack;
  const NfcPaymentView({Key? key, required this.finalAmount, required this.callBack}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text('Total: ${finalAmount}', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        Container(
          height: 150,
          margin: EdgeInsets.only(bottom: 10, top: 10),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16.0),
            child: Image(image: AssetImage("drawable/duitNow.jpg")),
          ),
        ),
        _ScanButton(
          finalAmount: finalAmount,
          callBack: callBack,
        )

      ],
    );
  }
}

class _ScanButton extends StatefulWidget {
  final String finalAmount;
  final Function(String transactionID, String referenceNo) callBack;
  const _ScanButton({Key? key, required this.finalAmount, required this.callBack}) : super(key: key);

  @override
  State<_ScanButton> createState() => _ScanButtonState();
}

class _ScanButtonState extends State<_ScanButton> {
  final String startScan = "Start scan";
  StreamController<String?> eventStreamController = StreamController<String?>();
  StreamController<bool> btnStreamController = StreamController<bool>();
  StreamController<String> btnTextStreamController = StreamController<String>();
  bool isButtonDisable = false;
  List<cartProductItem> itemList = [];
  late Stream<String?> eventStream;
  late Stream<bool> btnStream;
  late Stream<String> btnTextStream;
  late StreamSubscription _trxUIStreamSub;
  late StreamSubscription _trxStreamSub;

  @override
  void initState() {
    eventStream = eventStreamController.stream;
    btnStream = btnStreamController.stream;
    btnTextStream = btnTextStreamController.stream;
    initTrxStreamSub();
    initTrxUIStreamSub();
    super.initState();
  }

  @override
  void dispose() {
    cancelTransaction();
    _trxUIStreamSub.cancel();
    _trxStreamSub.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        buildButtonEvent(),
        buildScanButton()
      ],
    );
  }

  Widget buildButtonEvent() {
    return StreamBuilder<String?>(
          stream: eventStream,
          builder: (context, snapshot) {
            if(snapshot.hasData){
              return Text(snapshot.data!);
            } else {
              return SizedBox.shrink();
            }
          }
      );
  }

  Widget buildScanButton() {
    return StreamBuilder<bool>(
          stream: btnStream,
          initialData: false,
          builder: (context, snapshot) {
            return ElevatedButton.icon(
                style: ButtonStyle(
                  backgroundColor: WidgetStateProperty.all(Colors.green),
                  padding: WidgetStateProperty.all(EdgeInsets.all(getButtonPadding())),
                ),
                onPressed: snapshot.data == false ? () async {
                  asyncQ.addJob((_) async {
                    try{
                      String? referenceNo = await generateRefNo();
                      if(referenceNo != null){
                        //use actual amount in prod, remember remove decimal point
                        //for debug use 5800 or 58000 (trigger PIN)
                        print("Actual NFC amount: ${widget.finalAmount.replaceAll(".", "")}");
                        String formatAmount = widget.finalAmount.replaceAll(".", "");
                        FLog.info(
                          className: "nfc_payment_view",
                          text: "Payment button onPressed",
                          exception: "Ref no: $referenceNo, Auth amt: $formatAmount",
                        );
                        await NFCPayment.startPayment(amount: formatAmount, ref_no: referenceNo);
                      } else {
                        throw Exception("Generate reference error");
                      }
                    }catch(e){
                      cancelTransaction();
                      Navigator.of(context).pop();
                      showErrorToast(title: "Start scan error", description: e.toString());
                      FLog.error(
                        className: "nfc_payment_view",
                        text: "Payment button onPressed error",
                        exception: e,
                      );
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
             style: TextStyle(fontSize: getButtonFontSize()),
         );
       },
   );
  }

  void showErrorToast({required String title, String? description}){
    CustomFailedToast.showToast(
        title: title,
        description: description,
        duration: 8
    );
  }

  void openNFCSetting(){
    showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            content: Text("NFC is not enabled. Please enable NFC in the settings screen."),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  AppSettings.openAppSettings(type: AppSettingsType.nfc);
                },
                child: Text("SETTINGS"),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text("OK"),
              )
            ],
          );
        },
    );
  }

  void cancelTransaction() async {
    await NFCPayment.cancelTransaction();
  }

  void initTrxStreamSub(){
    late NFCPaymentResponse response;
    _trxStreamSub = NFCPayment.transactionEvents.listen((event) {
      var jsonResponse = jsonDecode(event);
      var status = jsonResponse[NFCPaymentFields.status];
      if(jsonResponse['data'] != null){
        var jsonData = jsonDecode(jsonResponse['data']);
        response = NFCPaymentResponse.fromJson(jsonData);
      }
      print("trx status: ${jsonResponse[NFCPaymentFields.status]}");
      switch(status){
        case 0 : {
          widget.callBack(response.transaction_id!, response.reference_no!);
          print("trans id: ${response.transaction_id!}");
          print("ref no: ${response.reference_no}");
        }break;
        case 2: {
          openNFCSetting();
        }break;
        case 3: {
          Navigator.of(context).pop();
          showErrorToast(title: "Invalid token");
        }break;
        default: {
          Navigator.of(context).pop();
          showErrorToast(
              title: "Transaction Failed: ${jsonResponse[NFCPaymentFields.status]}",
              description:"${response.trxStatusCode}-${response.trxStatusMsg}");
          FLog.error(
            className: "nfc_payment_view",
            text: "Transaction outcome failed: ${jsonResponse[NFCPaymentFields.status]}",
            exception: "${response.trxStatusCode}-${response.trxStatusMsg}",
          );
        }
      }
      // if(jsonResponse[NFCPaymentFields.status] == 0){
      //   widget.callBack(response.transaction_id!, response.reference_no!);
      //   print("trans id: ${response.transaction_id!}");
      //   print("ref no: ${response.reference_no}");
      // } else if(jsonResponse[NFCPaymentFields.status] == 2) {
      //   openNFCSetting();
      // } else {
      //   Navigator.of(context).pop();
      //   showErrorToast(
      //       title: "Transaction Failed: ${jsonResponse[NFCPaymentFields.status]}",
      //       description:"${response.trxStatusCode}-${response.trxStatusMsg}");
      //   FLog.error(
      //     className: "nfc_payment_view",
      //     text: "Transaction outcome failed: ${jsonResponse[NFCPaymentFields.status]}",
      //     exception: "${response.trxStatusCode}-${response.trxStatusMsg}",
      //   );
      // }
    }, onError: (error) {
      showErrorToast(title: "Transaction Error", description: error.toString());
      FLog.error(
        className: "nfc_payment_view",
        text: "listen Trx stream error",
        exception: error,
      );

    });
  }

  void initTrxUIStreamSub(){
    String UIMessage = startScan;
    _trxUIStreamSub = NFCPayment.transactionUIEvents.listen((event) {
      print("event: $event");

      var jsonResponse = jsonDecode(event);
      int status = jsonResponse[NFCPaymentFields.status];
      if(jsonResponse['data'] != null){
        UIMessage = jsonResponse['data'];
      }
      if(status == 0 || status == 1){
        btnTextStreamController.sink.add(UIMessage);
        eventStreamController.sink.add(null);
      } else {
        eventStreamController.sink.add(UIMessage);
        if(status == 71){
          //Present card status
          btnStreamController.sink.add(false);
        } else if (status == 72){
          //Card Presented status
          btnStreamController.sink.add(true);
        }
      }
    }, onError: (error) {
      print("onError: ${error.toString()}");
      btnTextStreamController.sink.add(startScan);
      btnStreamController.sink.add(false);
      showErrorToast(title: "Transaction UI stream Error", description: error.toString());
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

  double getButtonPadding() {
    final media = MediaQuery.of(context);
    final isLargeScreen = media.size.width > 900 && media.size.height > 500;

    return media.orientation == Orientation.landscape
        ? isLargeScreen
        ? 20.0
        : 10.0
        : isLargeScreen
        ? 20.0
        : 10.0;
  }

  double getButtonFontSize() {
    final media = MediaQuery.of(context);
    final isLargeScreen = media.size.width > 900 && media.size.height > 500;

    return media.orientation == Orientation.landscape
        ? isLargeScreen
        ? 20.0
        : 14.0
        : isLargeScreen
        ? 20.0
        : 14.0;
  }
}

