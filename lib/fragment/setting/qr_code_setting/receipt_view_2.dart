import 'dart:async';
import 'dart:convert';

import 'package:dotted_line/dotted_line.dart';
import 'package:f_logs/model/flog/flog.dart';
import 'package:flutter/material.dart';
import 'package:pos_system/fragment/setting/qr_code_setting/qr_code_utils.dart';
import 'package:pos_system/object/dynamic_qr.dart';
import 'package:pos_system/page/progress_bar.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../database/pos_database.dart';
import '../../../enumClass/receipt_dialog_enum.dart';
import '../../../notifier/theme_color.dart';
import '../../../translation/AppLocalizations.dart';

class ReceiptView2 extends StatefulWidget {
  final Function(DynamicQR layout) callBack;
  const ReceiptView2({Key? key, required this.callBack}) : super(key: key);

  @override
  State<ReceiptView2> createState() => _ReceiptView2State();
}

class _ReceiptView2State extends State<ReceiptView2> {
  final String receiptView = '58';
  ScrollController previewScrollController = ScrollController();
  StreamController actionController = StreamController();
  TextEditingController footerTextController = TextEditingController(text: 'Powered by Optimy POS');
  late Stream actionStream;
  ReceiptDialogEnum qrCodeSize = ReceiptDialogEnum.big;
  late DynamicQR testLayout;
  late Map branchObject;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    actionStream = actionController.stream.asBroadcastStream();
    initData();
  }

  initData() async {
    await getDynamicQRLayout();
    await getBranchData();
    actionController.sink.add("refresh");
  }

  getDynamicQRLayout() async {
    try {
      DynamicQR data = await PosDatabase.instance.readSpecificDynamicQRByPaperSize(receiptView) ?? QrCodeUtils.default58mmDynamicLayout;
      testLayout = data;
      footerTextController.text = data.footer_text!;
      switch (data.qr_code_size) {
        case 0:
          {
            qrCodeSize = ReceiptDialogEnum.small;
          }
          break;
        case 1:
          {
            qrCodeSize = ReceiptDialogEnum.medium;
          }
          break;
        default:
          {
            qrCodeSize = ReceiptDialogEnum.big;
          }
      }
    } catch (e) {
      testLayout = QrCodeUtils.default58mmDynamicLayout;
      FLog.error(
        className: "receipt view 2",
        text: "get dynamic qr layout error",
        exception: "$e",
      );
    }
    widget.callBack(testLayout);
  }

  getBranchData() async {
    final prefs = await SharedPreferences.getInstance();
    final String? branch = prefs.getString('branch');
    branchObject = json.decode(branch!);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeColor>(builder: (context, ThemeColor color, child) {
      return StreamBuilder(
          stream: actionStream,
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  preview_part(context),
                  SizedBox(width: 25),
                  setting_part(color, context),
                ],
              );
            } else {
              return Center(
                child: CustomProgressBar(),
              );
            }
          });
    });
  }

  Widget setting_part(ThemeColor color, BuildContext context) {
    return Expanded(
      flex: 1,
      child: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              alignment: Alignment.topLeft,
              child: Text(AppLocalizations.of(context)!.translate('qr_code_size'),
                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey)),
            ),
            RadioListTile<ReceiptDialogEnum?>(
              activeColor: color.buttonColor,
              value: ReceiptDialogEnum.big,
              groupValue: qrCodeSize,
              onChanged: (value) {
                qrCodeSize = value!;
                testLayout.qr_code_size = 2;
                widget.callBack(testLayout);
                actionController.sink.add("refresh");
              },
              title: Text(AppLocalizations.of(context)!.translate('big')),
              controlAffinity: ListTileControlAffinity.trailing,
            ),
            RadioListTile<ReceiptDialogEnum?>(
              activeColor: color.buttonColor,
              value: ReceiptDialogEnum.medium,
              groupValue: qrCodeSize,
              onChanged: (value) {
                qrCodeSize = value!;
                testLayout.qr_code_size = 1;
                widget.callBack(testLayout);
                actionController.sink.add("refresh");
              },
              title: Text(AppLocalizations.of(context)!.translate('medium')),
              controlAffinity: ListTileControlAffinity.trailing,
            ),
            RadioListTile<ReceiptDialogEnum?>(
              activeColor: color.buttonColor,
              value: ReceiptDialogEnum.small,
              groupValue: qrCodeSize,
              onChanged: (value) {
                qrCodeSize = value!;
                testLayout.qr_code_size = 0;
                widget.callBack(testLayout);
                actionController.sink.add("refresh");
              },
              title: Text(AppLocalizations.of(context)!.translate('small')),
              controlAffinity: ListTileControlAffinity.trailing,
            ),
            Container(
              alignment: Alignment.topLeft,
              child: Text(AppLocalizations.of(context)!.translate('footer_text'), style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey)),
            ),
            ValueListenableBuilder(
              // Note: pass _controller to the animation argument
                valueListenable: footerTextController,
                builder: (context, TextEditingValue value, __) {
                  return Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: TextField(
                      onChanged: (value){
                        setState(() {
                          footerTextController.text = value;
                          previewScrollController.jumpTo(previewScrollController.position.maxScrollExtent);
                          testLayout.footer_text = value;
                          widget.callBack(testLayout);
                        });
                      },
                      controller: footerTextController,
                      keyboardType: TextInputType.multiline,
                      maxLines: null,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderSide: BorderSide(
                              color: color.backgroundColor),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                              color: color.backgroundColor),
                        ),
                        labelText: AppLocalizations.of(context)!.translate('footer_text_here'),
                      ),
                    ),
                  );
                }),
          ],
        ),
      ),
    );
  }

  Widget preview_part(BuildContext context) {
    return SingleChildScrollView(
      controller: previewScrollController,
      child: Container(
        width: 450,
        decoration: BoxDecoration(
            border: Border.all(color: Colors.blueGrey, style: BorderStyle.solid, width: 1)),
        padding: MediaQuery.of(context).size.width > 1300
            ? EdgeInsets.fromLTRB(40, 20, 40, 20)
            : EdgeInsets.fromLTRB(20, 20, 20, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(branchObject['name'],
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14.0)),
            SizedBox(height: 10),
            Text(branchObject['address'],
                textAlign: TextAlign.center,
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14.0)),
            Padding(
              padding: EdgeInsets.only(top: 10, bottom: 10),
              child: DottedLine(),
            ),
            Column(
              children: [
                Text("Table No: 1", style: TextStyle(fontWeight: FontWeight.bold)),
                qrCodeSize == ReceiptDialogEnum.big
                    ? Container(
                  child: Image.asset("drawable/qr300.png"),
                )
                    : qrCodeSize == ReceiptDialogEnum.medium
                    ? Container(
                  child: Image.asset("drawable/qr250.png"),
                )
                    : Container(
                  child: Image.asset("drawable/qr150.png"),
                ),
                Text("Generated At", style: TextStyle(fontWeight: FontWeight.bold)),
                Text("DD/MM/YY hh:mm:ss AM"),
                Text("Expired At", style: TextStyle(fontWeight: FontWeight.bold)),
                Text("DD/MM/YY hh:mm:ss PM"),
                Padding(
                  padding: EdgeInsets.only(top: 10, bottom: 10),
                  child: DottedLine(),
                ),
                Text(footerTextController.text)

              ],
            )
          ],
        ),
      ),
    );
  }
}
