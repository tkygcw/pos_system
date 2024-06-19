import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';
import 'package:pos_system/database/domain.dart';
import 'package:pos_system/object/pdf_format.dart';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../notifier/report_notifier.dart';
import '../../object/table.dart';
import '../../translation/AppLocalizations.dart';

class PrintReportPage extends StatefulWidget {
  final int? currentPage;
  final List<PosTable>? tableList;
  final Function? callBack;
  const PrintReportPage({Key? key, this.currentPage, this.tableList, this.callBack}) : super(key: key);

  @override
  State<PrintReportPage> createState() => _PrintReportPageState();
}

class _PrintReportPageState extends State<PrintReportPage> {
  DateFormat dateFormat = DateFormat("yyyy-MM-dd");
  ReportFormat reportFormat = new ReportFormat();
  List<PosTable> posTableList = [];


  @override
  void initState() {
    super.initState();
    reportFormat.presetTextFormat();
    if(widget.currentPage == -1){
      generateUrl();
    }
  }
  @override
  Widget build(BuildContext context) {
    return Consumer<ReportModel>(builder: (context, ReportModel reportModel, child) {
        return WillPopScope(
          onWillPop: () async {
            for(int i = 0; i < posTableList.length; i++){
              setState(() {
                posTableList[i].isSelected = false;
                widget.callBack!();
              });
            }
            return true;
          },
          child: Scaffold(
            appBar:  AppBar(
              backgroundColor: Colors.white,
                actions: [
                ],
                title: Text('Pdf',
                    style: TextStyle(fontSize: 18))),
            body: PdfPreview(
              build: (format) {
                switch(widget.currentPage){
                  case -1 :
                    return ReportFormat().generateQrPdf(format, posTableList);
                  case 0:
                    return reportFormat.generateOverviewReportPdf(format, 'Overview', reportModel);
                  case 1:
                    return reportFormat.generateDailySalesPdf(format, 'Daily Sales Report', reportModel);
                  case 2:
                    //generate product report
                    return reportFormat.generateProductReportPdf(format, 'Product Report', reportModel);
                  case 3:
                    //generate category report
                    return reportFormat.generateCategoryReportPdf(format, 'Category Report', reportModel);
                  case 4:
                    //generate modifier report
                    return reportFormat.generateModifierReportPdf(format, 'Modifier Report', reportModel);
                  case 5:
                    //generate edit report
                    return reportFormat.generatePriceEditReportPdf(format, 'Price Edit Report', reportModel);
                  case 6:
                    //generate cancel report
                    return reportFormat.generateCancelProductReportPdf(format, 'Cancellation Report', reportModel);
                  case 7:
                    //generate cancel modifier report
                    return reportFormat.generateCancelModifierReportPdf(format, 'Cancel Modifier Report', reportModel);
                  case 8:
                    //generate dining report
                    return reportFormat.generateDiningReport(format, 'Dining Report', reportModel);
                  case 9:
                    //generate payment report
                    return reportFormat.generatePaymentReport(format, 'Payment Report', reportModel);
                  case 10:
                    //generate refund report
                    return reportFormat.generateRefundReport(format, 'Refund Report', reportModel);
                  case 11:
                  //generate cash record report
                    return reportFormat.generateCashRecordReport(format, 'Cash Record Report', reportModel);
                  case 12:
                  //generate user sales report
                    return reportFormat.generateStaffSalesReport(format, 'Staff Sales Report', reportModel);
                  default:
                    // generate transfer report
                    return reportFormat.generateReportPdf(format, 'Report');
                }
              },
              canDebug: false,
              previewPageMargin: EdgeInsets.all(10),
              pdfFileName: generateFileName(),
              maxPageWidth: MediaQuery.of(context).size.width/2,
              initialPageFormat: PdfPageFormat.a4,
              onPrintError: (context, error) {
                Fluttertoast.showToast(
                    backgroundColor: Colors.red,
                    msg: "${AppLocalizations.of(context)?.translate('printing_error')}");
              },
            ),
          ),
        );
      }
    );
  }

  generateUrl() async {
    // final logoFile = FileImage(File('/data/data/com.example.pos_system/files/assets/img/logo1.jpg'));
    // final logoFile = FileImage(File('drawable/logo.png'));
    // final logoImage = await flutterImageProvider(logoFile);
    final prefs = await SharedPreferences.getInstance();
    final String? branch = prefs.getString('branch');
    Map branchObject = json.decode(branch!);
    posTableList = widget.tableList!;
    for(int i = 0; i < posTableList.length; i++){
      var url = '${Domain.qr_domain}${branchObject['branch_url']}/${posTableList[i].table_url}';
      posTableList[i].qrOrderUrl = url;
    }
    //widget.callBack!();
  }

  Future<Uint8List?> toQrImageData(String text) async {
    try {
      final image = await QrPainter(
        data: text,
        version: QrVersions.auto,
        gapless: false,
      ).toImage(300);
      final a = await image.toByteData(format: ImageByteFormat.png);
      return a?.buffer.asUint8List();
    } catch (e) {
      throw e;
    }
  }

  generateFileName(){
    String name = '';
    String dateTime = dateFormat.format(DateTime.now());
    name = '${dateTime}.pdf';
    return name;
  }


}
