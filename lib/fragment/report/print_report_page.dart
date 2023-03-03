import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pos_system/object/pdf_format.dart';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';

import '../../notifier/report_notifier.dart';
import '../../object/table.dart';

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
  List<PosTable> posTableList = [];


  @override
  void initState() {
    super.initState();
    if(widget.currentPage == -1){
      generateUrl();
    }
  }
  @override
  Widget build(BuildContext context) {
    return Consumer<ReportModel>(builder: (context, ReportModel reportModel, child) {
        return Scaffold(
          body: PdfPreview(
            build: (format) {
              if(widget.currentPage == 0){
                return ReportFormat().generateOverviewReportPdf(format, 'Overview Report', reportModel);
              } else if(widget.currentPage == -1){
                return ReportFormat().generateQrPdf(format, posTableList);
              }
              else {
                return ReportFormat().generateReportPdf(format, 'Report');
              }
            },
            canDebug: false,
            previewPageMargin: EdgeInsets.all(100),
            pdfFileName: generateFileName(),
            maxPageWidth: MediaQuery.of(context).size.width/2,
            initialPageFormat: PdfPageFormat.a4,
          ),
        );
      }
    );
  }

  generateUrl() async {
    final logoFile = FileImage(File('/data/data/com.example.pos_system/files/assets/img/logo1.jpg'));
    final logoImage = await flutterImageProvider(logoFile);
    final prefs = await SharedPreferences.getInstance();
    final String? branch = prefs.getString('branch');
    Map branchObject = json.decode(branch!);
    posTableList = widget.tableList!;
    for(int i = 0; i < posTableList.length; i++){
      var url = 'https://pos.lkmng.com/${branchObject['branch_url']}/${posTableList[i].table_url}';
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
