import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pos_system/notifier/report_notifier.dart';
import 'package:pos_system/object/table.dart';
import 'package:pos_system/utils/Utils.dart';
import 'package:printing/printing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../database/domain.dart';
import 'cash_record.dart';



class ReportFormat {
  var chineseFont;
  var normalFont;

  void presetTextFormat() async {
    final font = await rootBundle.load("font/simply_chinese.ttf");
    chineseFont = pw.Font.ttf(font);
    normalFont = await PdfGoogleFonts.latoRegular();
  }

  getFontFormat(value) {
    if (RegExp(r'^[A-Za-z0-9_.]+$').hasMatch(value.toString())) {
      return normalFont;
    } else {
      return chineseFont;
    }
  }

  String getDuration(int? duration) {
    if (duration == null || duration == 0) {
      return '-';
    }

    int hours = duration ~/ 60;
    int minutes = duration % 60;

    return '${hours > 0 ? '$hours hours' : ''} ${minutes > 0 ? '$minutes minutes' : ''}';
  }

  getQuantityFormat({value}){
    String returnValue = '';
    try{
      if(value.item_sum is double){
        returnValue = '${value.item_qty.toString()}/${double.parse(value.item_sum.toString()).toStringAsFixed(2)}(${value.unit})';
        print("is double: ${value.item_sum}");
      } else {
        print("not double");
        returnValue = value.item_sum.toString();
      }
    }catch(e){
      returnValue = value.item_sum.toString();
    }
    return returnValue;
  }

  Future<Uint8List> generateOverviewReportPdf(PdfPageFormat format, String title, ReportModel reportModel) async {
    const tableHeaders = ['Name', 'Bill', 'Amount'];
    const tableHeaders2 = ['Name', 'Amount'];
    var payment = jsonDecode(reportModel.reportValue[6]);
    var charges = jsonDecode(reportModel.reportValue[7]);
    print('charges: ${charges}');
    final prefs = await SharedPreferences.getInstance();
    final String? branch = prefs.getString('branch');
    final String? user = prefs.getString('user');
    Map branchObject = json.decode(branch!);
    Map userObject = json.decode(user!);
    final pdf = pw.Document(version: PdfVersion.pdf_1_5, compress: true);
    final font = await PdfGoogleFonts.dancingScriptMedium();
    final imageByteData = await rootBundle.load('drawable/logo.png');
    // Convert ByteData to Uint8List
    final imageUint8List = imageByteData.buffer.asUint8List(imageByteData.offsetInBytes, imageByteData.lengthInBytes);
    final image = pw.MemoryImage(imageUint8List);
    pdf.addPage(
      pw.Page(
        pageFormat: format,
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Divider(
                height: 5,
                thickness: 0.10,
                color: PdfColors.black
              ),
              pw.Center(
                child: pw.Text(title, style: pw.TextStyle(fontSize: 38)),
              ),
              pw.Divider(
                  height: 5,
                  thickness: 0.10,
                  color: PdfColors.black
              ),
              pw.Spacer(),
              pw.Center(
                child: pw.Text('${branchObject['name']}', style: pw.TextStyle(font: getFontFormat(branchObject['name']), fontSize: 58))
              ),
              pw.Spacer(),
              pw.Center(
                child: pw.Text('From:', style: pw.TextStyle(fontSize: 18))
              ),
              pw.Center(
                  child: pw.Text('${reportModel.startDateTime2}', style: pw.TextStyle(fontSize: 24))
              ),
              pw.SizedBox(height: 10),
              pw.Center(
                  child: pw.Text('To: ', style: pw.TextStyle(fontSize: 18))
              ),
              pw.Center(
                  child: pw.Text('${reportModel.endDateTime2}', style: pw.TextStyle(fontSize: 24))
              ),
              pw.Spacer(),
              pw.Center(
                  child: pw.Text('Total Bills:', style: pw.TextStyle(fontSize: 18))
              ),
              pw.Center(
                  child: pw.Text('${reportModel.reportValue[0]}', style: pw.TextStyle(fontSize: 24))
              ),
              pw.Center(
                  child: pw.Text('Total Sales:', style: pw.TextStyle(fontSize: 18))
              ),
              pw.Center(
                  child: pw.Text('${reportModel.reportValue[1]}', style: pw.TextStyle(fontSize: 24))
              ),
              pw.Center(
                  child: pw.Text('Total Refund Bill:', style: pw.TextStyle(fontSize: 18))
              ),
              pw.Center(
                  child: pw.Text('${reportModel.reportValue[2]}', style: pw.TextStyle(fontSize: 24))
              ),
              pw.Center(
                  child: pw.Text('Total Refund Amount:', style: pw.TextStyle(fontSize: 18))
              ),
              pw.Center(
                  child: pw.Text('${reportModel.reportValue[3]}', style: pw.TextStyle(fontSize: 24))
              ),
              pw.Center(
                  child: pw.Text('Total Discount:', style: pw.TextStyle(fontSize: 18))
              ),
              pw.Center(
                  child: pw.Text('${reportModel.reportValue[4]}', style: pw.TextStyle(fontSize: 24))
              ),
              pw.Center(
                  child: pw.Text('Total Cancelled item:', style: pw.TextStyle(fontSize: 18))
              ),
              pw.Center(
                  child: pw.Text('${reportModel.reportValue[5]}', style: pw.TextStyle(fontSize: 24))
              ),
            ],
          );
        },
      ),
    );
    ///second page
    pdf.addPage(
      pw.Page(
        pageFormat: format,
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('Payment Overview', style: pw.TextStyle(fontSize: 24)),
              pw.SizedBox(height: 10),
              pw.Table.fromTextArray(
                  border: null,
                  headers: tableHeaders,
                  rowDecoration: pw.BoxDecoration(
                    border: pw.Border(
                      left: pw.BorderSide(color: PdfColors.black),
                      right: pw.BorderSide(color: PdfColors.black),
                      bottom: pw.BorderSide(color: PdfColors.black)
                    )
                  ),
                  headerAlignment: pw.Alignment.centerLeft,
                  headerDecoration: pw.BoxDecoration(
                      color: PdfColors.black
                  ),
                  headerStyle: pw.TextStyle(
                    color: PdfColors.white,
                    fontWeight: pw.FontWeight.bold,
                  ),
                  data: List.generate(
                      payment.length,
                          (index) => [
                        payment[index]['name'],
                        payment[index]['total_bill'],
                        payment[index]['total_amount']
                      ])),
              pw.SizedBox(height: 50),
              charges.isNotEmpty ?
              pw.Text('Charges Overview', style: pw.TextStyle(fontSize: 24)) : pw.Text(''),
              pw.SizedBox(height: 10),
              charges.isNotEmpty ?
              pw.Table.fromTextArray(
                  border: null,
                  headers: tableHeaders2,
                  rowDecoration: pw.BoxDecoration(
                      border: pw.Border(
                          left: pw.BorderSide(color: PdfColors.black),
                          right: pw.BorderSide(color: PdfColors.black),
                          bottom: pw.BorderSide(color: PdfColors.black)
                      )
                  ),
                  headerAlignment: pw.Alignment.centerLeft,
                  headerDecoration: pw.BoxDecoration(
                      color: PdfColors.black
                  ),
                  headerStyle: pw.TextStyle(
                    color: PdfColors.white,
                    fontWeight: pw.FontWeight.bold,
                  ),
                  data: List.generate(
                      charges.length,
                          (index) => [
                            charges[index]['name'],
                            charges[index]['total_amount']
                      ]))
                  :
                  pw.Text('')
            ]
          );
        },
      ),
    );
    return pdf.save();
  }

  Future<Uint8List> generateDailySalesPdf(PdfPageFormat format, String title, ReportModel reportModel) async {
    List valueList = reportModel.reportValue2;
    List paymentHeader = reportModel.headerValue;
    final pdf = pw.Document(version: PdfVersion.pdf_1_5, compress: true);
    final font = await PdfGoogleFonts.nunitoExtraLight();
    final prefs = await SharedPreferences.getInstance();
    final String? branch = prefs.getString('branch');
    Map branchObject = json.decode(branch!);
    final imageByteData = await rootBundle.load('drawable/logo.png');
    // Convert ByteData to Uint8List
    final imageUint8List = imageByteData.buffer.asUint8List(imageByteData.offsetInBytes, imageByteData.lengthInBytes);
    final image = pw.MemoryImage(imageUint8List);
    pdf.addPage(
      pw.MultiPage(
          pageFormat: format,
          orientation: pw.PageOrientation.landscape,
          build: (pw.Context context) => [
            pw.Center(
                child: pw.Text('${branchObject['name']}', style: pw.TextStyle(font: getFontFormat(branchObject['name']), fontSize: 18))
            ),
            pw.SizedBox(height: 10),
            pw.Table(
                border: pw.TableBorder(
                  left: pw.BorderSide(width: 0),
                  top: pw.BorderSide(width: 0),
                  right: pw.BorderSide(width: 0),
                  bottom: pw.BorderSide(width: 0),
                  horizontalInside: pw.BorderSide(width: 0),
                  verticalInside: pw.BorderSide.none,
                ),
                children: [
                  pw.TableRow(
                      decoration: pw.BoxDecoration(
                        color: PdfColors.black,
                      ),
                      children: [
                        pw.Padding(
                          padding: pw.EdgeInsets.fromLTRB(10, 5, 10, 5),
                          child: pw.Text('Date', style: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold, font: getFontFormat('Date'))),
                        ),
                        pw.Padding(
                          padding: pw.EdgeInsets.fromLTRB(10, 5, 10, 5),
                          child: pw.Text('Total Bills', style: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold, font: getFontFormat('Total Bills'))),
                        ),
                        pw.Padding(
                          padding: pw.EdgeInsets.fromLTRB(10, 5, 10, 5),
                          child: pw.Text('Total Sales', style: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold, font: getFontFormat('Total Sales'))),
                        ),
                        pw.Padding(
                          padding: pw.EdgeInsets.fromLTRB(10, 5, 10, 5),
                          child: pw.Text('Total Refund Bills', style: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold, font: getFontFormat('Total Refund Bills'))),
                        ),
                        pw.Padding(
                          padding: pw.EdgeInsets.fromLTRB(10, 5, 10, 5),
                          child: pw.Text('Total Refund Amount', style: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold, font: getFontFormat('Total Refund Amount'))),
                        ),
                        pw.Padding(
                          padding: pw.EdgeInsets.fromLTRB(10, 5, 10, 5),
                          child: pw.Text('Total Discount', style: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold, font: getFontFormat('Total Discount'))),
                        ),
                        pw.Padding(
                          padding: pw.EdgeInsets.fromLTRB(10, 5, 10, 5),
                          child: pw.Text('Total Charge', style: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold, font: getFontFormat('Charge'))),
                        ),
                        pw.Padding(
                          padding: pw.EdgeInsets.fromLTRB(10, 5, 10, 5),
                          child: pw.Text('Total Tax', style: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold, font: getFontFormat('Total Tax'))),
                        ),
                        pw.Padding(
                          padding: pw.EdgeInsets.fromLTRB(10, 5, 10, 5),
                          child: pw.Text('Total Cancellation', style: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold, font: getFontFormat('Total Cancellation'))),
                        ),
                      ]
                  ),
                  for(int j = 0; j < valueList.length; j++)
                    pw.TableRow(
                        children: [
                          pw.Padding(
                            padding: pw.EdgeInsets.fromLTRB(5, 5, 10, 5),
                            child: pw.Text('${valueList[j].created_at}', 
                                style: pw.TextStyle(font: getFontFormat(valueList[j].created_at))),
                          ),
                          pw.Padding(
                            padding: pw.EdgeInsets.fromLTRB(5, 5, 10, 5),
                            child: pw.Text('${valueList[j].all_bill}', style: pw.TextStyle(font: getFontFormat(valueList[j].all_bill))),
                          ),
                          pw.Padding(
                            padding: pw.EdgeInsets.fromLTRB(5, 5, 10, 5),
                            child: pw.Text('${valueList[j].all_sales?.toStringAsFixed(2)}', style: pw.TextStyle(font: getFontFormat(valueList[j].all_sales?.toStringAsFixed(2)))),
                          ),
                          pw.Padding(
                            padding: pw.EdgeInsets.fromLTRB(5, 5, 10, 5),
                            child: pw.Text('${valueList[j].all_refund_bill}', style: pw.TextStyle(font: getFontFormat(valueList[j].all_refund_bill))),
                          ),
                          pw.Padding(
                            padding: pw.EdgeInsets.fromLTRB(5, 5, 10, 5),
                            child: pw.Text('${valueList[j].all_refund_amount?.toStringAsFixed(2)}', style: pw.TextStyle(font: getFontFormat(valueList[j].all_refund_amount?.toStringAsFixed(2)))),
                          ),
                          pw.Padding(
                            padding: pw.EdgeInsets.fromLTRB(5, 5, 10, 5),
                            child: pw.Text('${valueList[j].all_discount?.toStringAsFixed(2)}', style: pw.TextStyle(font: getFontFormat(valueList[j].all_discount?.toStringAsFixed(2)))),
                          ),
                          pw.Padding(
                            padding: pw.EdgeInsets.fromLTRB(5, 5, 10, 5),
                            child: pw.Text('${valueList[j].all_charge_amount?.toStringAsFixed(2)}', style: pw.TextStyle(font: getFontFormat(valueList[j].all_charge_amount?.toStringAsFixed(2)))),
                          ),
                          pw.Padding(
                            padding: pw.EdgeInsets.fromLTRB(5, 5, 10, 5),
                            child: pw.Text('${valueList[j].all_tax_amount?.toStringAsFixed(2)}', style: pw.TextStyle(font: getFontFormat(valueList[j].all_tax_amount?.toStringAsFixed(2)))),
                          ),
                          pw.Padding(
                            padding: pw.EdgeInsets.fromLTRB(5, 5, 10, 5),
                            child: pw.Text('${valueList[j].all_cancellation}', style: pw.TextStyle(font: getFontFormat(valueList[j].all_cancellation))),
                          ),
                        ]
                    ),
                ]
            )
          ]
      ),
    );
    //second page
    pdf.addPage(
        pw.MultiPage(
            pageFormat: format,
            orientation: pw.PageOrientation.landscape,
            build: (pw.Context context) => [
              pw.Table(
                border: pw.TableBorder(
                  left: pw.BorderSide(width: 0),
                  top: pw.BorderSide(width: 0),
                  right: pw.BorderSide(width: 0),
                  bottom: pw.BorderSide(width: 0),
                  horizontalInside: pw.BorderSide(width: 0),
                  verticalInside: pw.BorderSide.none,
                ),
                children: [
                  pw.TableRow(
                      decoration: pw.BoxDecoration(
                        color: PdfColors.black,
                      ),
                    children: [
                      pw.Padding(
                        padding: pw.EdgeInsets.fromLTRB(10, 5, 10, 5),
                        child: pw.Text('Date', style: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold, font: getFontFormat('Date'))),
                      ),
                      for(int i = 0; i < paymentHeader.length; i++)
                        pw.Padding(
                          padding: pw.EdgeInsets.fromLTRB(5, 5, 10, 5),
                          child: pw.Text('${paymentHeader[i].name}', style: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold, font: getFontFormat(paymentHeader[i].name))),
                        ),
                    ]
                  ),
                  for(int j = 0; j < valueList.length; j++)
                  pw.TableRow(
                      children: [
                        pw.Padding(
                          padding: pw.EdgeInsets.fromLTRB(5, 5, 10, 5),
                          child: pw.Text('${valueList[j].created_at}', style: pw.TextStyle(font: getFontFormat(valueList[j].created_at))),
                        ),
                        for(int i = 0; i < valueList[j].settlementPayment.length; i++)
                          pw.Padding(
                            padding: pw.EdgeInsets.fromLTRB(5, 5, 10, 5),
                            child: pw.Text('${valueList[j].settlementPayment[i].all_payment_sales?.toStringAsFixed(2)}', 
                                style: pw.TextStyle(font: getFontFormat(valueList[j].settlementPayment[i].all_payment_sales?.toStringAsFixed(2)))),
                          ),
                      ]
                  ),
                ]
              )
            ])
    );
    return pdf.save();
  }

  Future<Uint8List> generateProductReportPdf(PdfPageFormat format, String title, ReportModel reportModel) async {
    List valueList = reportModel.reportValue2;
    const tableHeaders2 = ['Name', 'Amount'];
    var sales = jsonDecode(reportModel.reportValue[0]);
    var payment = jsonDecode(reportModel.reportValue[1]);
    var settlementPayment = jsonDecode(reportModel.reportValue[2]);
    final pdf = pw.Document(version: PdfVersion.pdf_1_5, compress: true);
    final font = await PdfGoogleFonts.nunitoExtraLight();
    final globalFont = await PdfGoogleFonts.arimoRegular();
    final prefs = await SharedPreferences.getInstance();
    final String? branch = prefs.getString('branch');
    Map branchObject = json.decode(branch!);
    final imageByteData = await rootBundle.load('drawable/logo.png');
    // Convert ByteData to Uint8List
    final imageUint8List = imageByteData.buffer.asUint8List(imageByteData.offsetInBytes, imageByteData.lengthInBytes);
    final image = pw.MemoryImage(imageUint8List);
    // Define the data for the table
    final data = [
      ['Parent Row 1 Column 1'],
      ['Child Row 1 Column 1', 'Child Row 1 Column 2'],
      ['Child Row 2 Column 1', 'Child Row 2 Column 2'],
      ['Child Row 3 Column 1', 'Child Row 3 Column 2'],
      ['Parent Row 2 Column 1'],
      ['Child Row 4 Column 1', 'Child Row 4 Column 2'],
      ['Child Row 5 Column 1', 'Child Row 5 Column 2'],
      ['Child Row 6 Column 1', 'Child Row 6 Column 2'],
    ];

    // Define a function to generate the parent row
    pw.TableRow _generateParentRow(List<String> rowData) {
      return pw.TableRow(
        children: [
          for (final item in rowData)
            pw.Padding(
              padding: pw.EdgeInsets.all(5),
              child: pw.Text(item),
            ),
        ],
      );
    }
    // Define a function to generate the child rows
    List<pw.TableRow> _generateChildRows(List<List<String>> rowsData) {
      return [
        for (final rowData in rowsData)
          pw.TableRow(
            children: [
              for (final item in rowData)
                pw.Padding(
                  padding: pw.EdgeInsets.all(5),
                  child: pw.Text(item),
                ),
            ],
          ),
      ];
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: format,
        orientation: pw.PageOrientation.landscape,
        build: (pw.Context context) => [
          pw.Center(
              child: pw.Text('${branchObject['name']}', style: pw.TextStyle(font: getFontFormat(branchObject['name']), fontSize: 18))
          ),
          pw.SizedBox(height: 10),
          pw.Table(
              border: pw.TableBorder(
                left: pw.BorderSide(width: 0),
                top: pw.BorderSide(width: 0),
                right: pw.BorderSide(width: 0),
                bottom: pw.BorderSide(width: 0),
                horizontalInside: pw.BorderSide(width: 0),
                verticalInside: pw.BorderSide.none,
              ),
              children: [
                pw.TableRow(
                    decoration: pw.BoxDecoration(
                      color: PdfColors.black,
                    ),
                    children: [
                      pw.Padding(
                        padding: pw.EdgeInsets.all(10),
                        child: pw.Text('Product',
                            style: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold, font: getFontFormat('Product'))),
                      ),
                      pw.Padding(
                        padding: pw.EdgeInsets.fromLTRB(5, 10, 10, 10),
                        child: pw.Text('Variant', style: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold, font: getFontFormat('Variant'))),
                      ),
                      pw.Padding(
                        padding: pw.EdgeInsets.fromLTRB(5, 10, 10, 10),
                        child: pw.Text('Quantity', style: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold, font: getFontFormat('Quantity'))),
                      ),
                      pw.Padding(
                        padding: pw.EdgeInsets.fromLTRB(5, 10, 10, 10),
                        child: pw.Text('Net Sales', style: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold, font: getFontFormat('Net Sales'))),
                      ),
                      pw.Padding(
                        padding: pw.EdgeInsets.fromLTRB(5, 10, 10, 10),
                        child: pw.Text('Gross Sales', style: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold, font: getFontFormat('Gross Sales'))),
                      ),
                    ]
                ),
                for(int j = 0; j < valueList.length; j++)
                  for(int i = 0; i < valueList[j].categoryOrderDetailList.length; i++)
                    pw.TableRow(
                      children: [
                        pw.Padding(
                          padding: pw.EdgeInsets.fromLTRB(5, 5, 10, 5),
                          child: pw.Text('${valueList[j].categoryOrderDetailList[i].productName}',
                              style: pw.TextStyle(font: getFontFormat(valueList[j].categoryOrderDetailList[i].productName))),
                        ),
                        pw.Padding(
                          padding: pw.EdgeInsets.fromLTRB(5, 5, 10, 5),
                          child: valueList[j].categoryOrderDetailList[i].product_variant_name != ''
                              ?
                          pw.Text('${valueList[j].categoryOrderDetailList[i].product_variant_name}',
                              style: pw.TextStyle(font: getFontFormat(valueList[j].categoryOrderDetailList[i].product_variant_name)))
                              :
                          pw.Text('-', style: pw.TextStyle(font: getFontFormat('-'))),
                        ),
                        pw.Padding(
                          padding: pw.EdgeInsets.fromLTRB(5, 5, 10, 5),
                          child: pw.Text('${getQuantityFormat(value: valueList[j].categoryOrderDetailList[i])}',
                              style: pw.TextStyle(font: getFontFormat(valueList[j].categoryOrderDetailList[i].item_sum))),
                        ),
                        pw.Padding(
                          padding: pw.EdgeInsets.fromLTRB(5, 5, 10, 5),
                          child: pw.Text('${valueList[j].categoryOrderDetailList[i].double_price!.toStringAsFixed(2)}', 
                              style: pw.TextStyle(font: getFontFormat(valueList[j].categoryOrderDetailList[i].double_price!.toStringAsFixed(2)))),
                        ),
                        pw.Padding(
                          padding: pw.EdgeInsets.fromLTRB(5, 5, 10, 5),
                          child: pw.Text('${valueList[j].categoryOrderDetailList[i].gross_price!.toStringAsFixed(2)}',
                              style: pw.TextStyle(font: getFontFormat(valueList[j].categoryOrderDetailList[i].gross_price!.toStringAsFixed(2)))),
                        ),
                      ]
                    ),
              ]
          ),
        ]
      ),
    );
    return pdf.save();
  }

  Future<Uint8List> generateCategoryReportPdf(PdfPageFormat format, String title, ReportModel reportModel) async {
    List valueList = reportModel.reportValue2;
    final pdf = pw.Document(version: PdfVersion.pdf_1_5, compress: true);
    final font = await PdfGoogleFonts.nunitoExtraLight();
    final prefs = await SharedPreferences.getInstance();
    final String? branch = prefs.getString('branch');
    Map branchObject = json.decode(branch!);
    final imageByteData = await rootBundle.load('drawable/logo.png');
    // Convert ByteData to Uint8List
    final imageUint8List = imageByteData.buffer.asUint8List(imageByteData.offsetInBytes, imageByteData.lengthInBytes);
    final image = pw.MemoryImage(imageUint8List);

    pdf.addPage(
      pw.MultiPage(
          pageFormat: format,
          orientation: pw.PageOrientation.portrait,
          build: (pw.Context context) => [
            pw.Center(
                child: pw.Text('${branchObject['name']}', style: pw.TextStyle(font: getFontFormat(branchObject['name']), fontSize: 18))
            ),
            pw.SizedBox(height: 10),
            pw.Table(
                border: pw.TableBorder(
                  left: pw.BorderSide(width: 0),
                  top: pw.BorderSide(width: 0),
                  right: pw.BorderSide(width: 0),
                  bottom: pw.BorderSide(width: 0),
                  horizontalInside: pw.BorderSide(width: 0),
                  verticalInside: pw.BorderSide.none,
                ),
                children: [
                  pw.TableRow(
                      decoration: pw.BoxDecoration(
                        color: PdfColors.black,
                      ),
                      children: [
                        pw.Padding(
                          padding: pw.EdgeInsets.all(10),
                          child: pw.Text('Category', style: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold, font: getFontFormat('Category'))),
                        ),
                        pw.Padding(
                          padding: pw.EdgeInsets.fromLTRB(5, 10, 10, 10),
                          child: pw.Text('Quantity', style: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold, font: getFontFormat('Quantity'))),
                        ),
                        pw.Padding(
                          padding: pw.EdgeInsets.fromLTRB(5, 10, 10, 10),
                          child: pw.Text('Net Sales', style: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold, font: getFontFormat('Net Sales'))),
                        ),
                        pw.Padding(
                          padding: pw.EdgeInsets.fromLTRB(5, 10, 10, 10),
                          child: pw.Text('Gross Sales', style: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold, font: getFontFormat('Cross Sales'))),
                        ),
                      ]
                  ),
                  for(int j = 0; j < valueList.length; j++)
                    pw.TableRow(
                        children: [
                          valueList[j].category_name != ''?
                          pw.Padding(
                            padding: pw.EdgeInsets.fromLTRB(5, 5, 10, 5),
                            child: pw.Text('${valueList[j].category_name}', style: pw.TextStyle(font: getFontFormat(valueList[j].category_name))),
                          ):
                          pw.Padding(
                            padding: pw.EdgeInsets.fromLTRB(5, 5, 10, 5),
                            child: pw.Text('Other', style: pw.TextStyle(font: getFontFormat('Other'))),
                          ),
                          pw.Padding(
                            padding: pw.EdgeInsets.fromLTRB(5, 5, 10, 5),
                            child: pw.Text('${valueList[j].category_item_sum}', style: pw.TextStyle(font: getFontFormat(valueList[j].category_item_sum))),
                          ),
                          pw.Padding(
                            padding: pw.EdgeInsets.fromLTRB(5, 5, 10, 5),
                            child: pw.Text('${valueList[j].category_net_sales!.toStringAsFixed(2)}',
                                style: pw.TextStyle(font: getFontFormat(valueList[j].category_net_sales!.toStringAsFixed(2)))),
                          ),
                          pw.Padding(
                            padding: pw.EdgeInsets.fromLTRB(5, 5, 10, 5),
                            child: pw.Text('${Utils.to2Decimal(valueList[j].category_gross_sales!)}',
                                style: pw.TextStyle(font: getFontFormat(Utils.to2Decimal(valueList[j].category_gross_sales!)))),
                          ),
                        ]
                    ),
                ]
            ),
          ]
      ),
    );
    return pdf.save();
  }

  Future<Uint8List> generateModifierReportPdf(PdfPageFormat format, String title, ReportModel reportModel) async {
    List valueList = reportModel.reportValue2;
    final pdf = pw.Document(version: PdfVersion.pdf_1_5, compress: true);
    final font = await PdfGoogleFonts.nunitoExtraLight();
    final prefs = await SharedPreferences.getInstance();
    final String? branch = prefs.getString('branch');
    Map branchObject = json.decode(branch!);
    final imageByteData = await rootBundle.load('drawable/logo.png');
    // Convert ByteData to Uint8List
    final imageUint8List = imageByteData.buffer.asUint8List(imageByteData.offsetInBytes, imageByteData.lengthInBytes);
    final image = pw.MemoryImage(imageUint8List);

    pdf.addPage(
      pw.MultiPage(
          pageFormat: format,
          orientation: pw.PageOrientation.portrait,
          build: (pw.Context context) => [
            pw.Center(
                child: pw.Text('${branchObject['name']}', style: pw.TextStyle(font: getFontFormat(branchObject['name']), fontSize: 18))
            ),
            pw.SizedBox(height: 10),
            pw.Table(
                border: pw.TableBorder(
                  left: pw.BorderSide(width: 0),
                  top: pw.BorderSide(width: 0),
                  right: pw.BorderSide(width: 0),
                  bottom: pw.BorderSide(width: 0),
                  horizontalInside: pw.BorderSide(width: 0),
                  verticalInside: pw.BorderSide.none,
                ),
                children: [
                  pw.TableRow(
                      decoration: pw.BoxDecoration(
                        color: PdfColors.black,
                      ),
                      children: [
                        pw.Padding(
                          padding: pw.EdgeInsets.all(10),
                          child: pw.Text('Modifier', style: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold, font: getFontFormat('Modifier'))),
                        ),
                        pw.Padding(
                          padding: pw.EdgeInsets.fromLTRB(5, 10, 10, 10),
                          child: pw.Text('Quantity', style: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold, font: getFontFormat('Quantity'))),
                        ),
                        pw.Padding(
                          padding: pw.EdgeInsets.fromLTRB(5, 10, 10, 10),
                          child: pw.Text('Net Sales', style: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold, font: getFontFormat('Net Sales'))),
                        ),
                      ]
                  ),
                  for(int j = 0; j < valueList.length; j++)
                    for(int i = 0; i < valueList[j].modDetailList.length; i++)
                    pw.TableRow(
                        children: [
                          pw.Padding(
                            padding: pw.EdgeInsets.fromLTRB(5, 5, 10, 5),
                            child: pw.Text('${valueList[j].modDetailList[i].mod_name}',
                                style: pw.TextStyle(font: getFontFormat(valueList[j].modDetailList[i].mod_name))),
                          ),
                          pw.Padding(
                            padding: pw.EdgeInsets.fromLTRB(5, 5, 10, 5),
                            child: pw.Text('${valueList[j].modDetailList[i].item_sum}',
                                style: pw.TextStyle(font: getFontFormat(valueList[j].modDetailList[i].item_sum))),
                          ),
                          pw.Padding(
                            padding: pw.EdgeInsets.fromLTRB(5, 5, 10, 5),
                            child: pw.Text('${valueList[j].modDetailList[i].net_sales!.toStringAsFixed(2)}',
                                style: pw.TextStyle(font: getFontFormat(valueList[j].modDetailList[i].net_sales!.toStringAsFixed(2)))),
                          ),
                        ]
                    ),
                ]
            ),
          ]
      ),
    );
    return pdf.save();
  }

  Future<Uint8List> generatePriceEditReportPdf(PdfPageFormat format, String title, ReportModel reportModel) async {
    List valueList = reportModel.reportValue2;
    final pdf = pw.Document(version: PdfVersion.pdf_1_5, compress: true);
    final prefs = await SharedPreferences.getInstance();
    final String? branch = prefs.getString('branch');
    Map branchObject = json.decode(branch!);
    final imageByteData = await rootBundle.load('drawable/logo.png');
    // Convert ByteData to Uint8List
    final imageUint8List = imageByteData.buffer.asUint8List(imageByteData.offsetInBytes, imageByteData.lengthInBytes);
    final image = pw.MemoryImage(imageUint8List);

    // Define a function to generate the parent row
    pw.TableRow _generateParentRow(List<String> rowData) {
      return pw.TableRow(
        children: [
          for (final item in rowData)
            pw.Padding(
              padding: pw.EdgeInsets.all(5),
              child: pw.Text(item),
            ),
        ],
      );
    }

    pdf.addPage(
      pw.MultiPage(
          pageFormat: format,
          orientation: pw.PageOrientation.landscape,
          build: (pw.Context context) => [
            pw.Center(
                child: pw.Text('${branchObject['name']}', style: pw.TextStyle(font: getFontFormat(branchObject['name']), fontSize: 18))
            ),
            pw.SizedBox(height: 10),
            pw.Table(
                border: pw.TableBorder(
                  left: pw.BorderSide(width: 0),
                  top: pw.BorderSide(width: 0),
                  right: pw.BorderSide(width: 0),
                  bottom: pw.BorderSide(width: 0),
                  horizontalInside: pw.BorderSide(width: 0),
                  verticalInside: pw.BorderSide.none,
                ),
                children: [
                  pw.TableRow(
                      decoration: pw.BoxDecoration(
                        color: PdfColors.black,
                      ),
                      children: [
                        pw.Padding(
                          padding: pw.EdgeInsets.all(10),
                          child: pw.Text('Receipt No', style: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold, font: getFontFormat('Receipt No'))),
                        ),
                        pw.Padding(
                          padding: pw.EdgeInsets.fromLTRB(5, 10, 10, 10),
                          child: pw.Text('Product', style: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold, font: getFontFormat('Product'))),
                        ),
                        pw.Padding(
                          padding: pw.EdgeInsets.fromLTRB(5, 10, 10, 10),
                          child: pw.Text('Original Price', style: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold, font: getFontFormat('Original Price'))),
                        ),
                        pw.Padding(
                          padding: pw.EdgeInsets.fromLTRB(5, 10, 10, 10),
                          child: pw.Text('Price', style: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold, font: getFontFormat('Price'))),
                        ),
                        pw.Padding(
                          padding: pw.EdgeInsets.fromLTRB(5, 10, 10, 10),
                          child: pw.Text('Edit By', style: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold, font: getFontFormat('Edit By'))),
                        ),
                        pw.Padding(
                          padding: pw.EdgeInsets.fromLTRB(5, 10, 10, 10),
                          child: pw.Text('Edit At', style: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold, font: getFontFormat('Edit At'))),
                        ),
                      ]
                  ),
                  for(int j = 0; j < valueList.length; j++)
                    // for(int i = 0; i < valueList[j].categoryOrderDetailList.length; i++)
                      pw.TableRow(
                          children: [
                            pw.Padding(
                              padding: pw.EdgeInsets.fromLTRB(5, 5, 10, 5),
                              child: pw.Text('#${valueList[j].categoryOrderDetailList[j].order_number}-${valueList[j].categoryOrderDetailList[j].branch_id?.padLeft(3,'0')}-${valueList[j].categoryOrderDetailList[j].created_at.toString().replaceAll(' ', '').replaceAll('-', '').replaceAll(':', '')}',
                                  style: pw.TextStyle(font: getFontFormat(valueList[j].categoryOrderDetailList[j].order_number))),
                            ),
                            pw.Padding(
                              padding: pw.EdgeInsets.fromLTRB(5, 5, 10, 5),
                              child:
                              pw.Text('${valueList[j].categoryOrderDetailList[j].productName}',
                                  style: pw.TextStyle(font: getFontFormat(valueList[j].categoryOrderDetailList[j].productName)))
                            ),
                            pw.Padding(
                              padding: pw.EdgeInsets.fromLTRB(5, 5, 10, 5),
                              child:
                              pw.Text('${valueList[j].categoryOrderDetailList[j].original_price}',
                                  style: pw.TextStyle(font: getFontFormat(valueList[j].categoryOrderDetailList[j].original_price)))
                            ),
                            pw.Padding(
                              padding: pw.EdgeInsets.fromLTRB(5, 5, 10, 5),
                              child: pw.Text('${valueList[j].categoryOrderDetailList[j].price}',
                                  style: pw.TextStyle(font: getFontFormat(valueList[j].categoryOrderDetailList[j].price))),
                            ),
                            pw.Padding(
                              padding: pw.EdgeInsets.fromLTRB(5, 5, 10, 5),
                              child: pw.Text('${valueList[j].categoryOrderDetailList[j].edited_by}',
                                  style: pw.TextStyle(font: getFontFormat(valueList[j].categoryOrderDetailList[j].edited_by))),
                            ),
                            pw.Padding(
                              padding: pw.EdgeInsets.fromLTRB(5, 5, 10, 5),
                              child: pw.Text('${valueList[j].categoryOrderDetailList[j].updated_at}',
                                  style: pw.TextStyle(font: getFontFormat(valueList[j].categoryOrderDetailList[j].updated_at))),
                            ),
                          ]
                      ),
                ]
            ),
          ]
      ),
    );
    return pdf.save();
  }

  Future<Uint8List> generateCancelProductReportPdf(PdfPageFormat format, String title, ReportModel reportModel) async {
    List valueList = reportModel.reportValue2;
    final pdf = pw.Document(version: PdfVersion.pdf_1_5, compress: true);
    final prefs = await SharedPreferences.getInstance();
    final String? branch = prefs.getString('branch');
    Map branchObject = json.decode(branch!);
    final imageByteData = await rootBundle.load('drawable/logo.png');
    // Convert ByteData to Uint8List
    final imageUint8List = imageByteData.buffer.asUint8List(imageByteData.offsetInBytes, imageByteData.lengthInBytes);
    final image = pw.MemoryImage(imageUint8List);

    // Define a function to generate the parent row
    pw.TableRow _generateParentRow(List<String> rowData) {
      return pw.TableRow(
        children: [
          for (final item in rowData)
            pw.Padding(
              padding: pw.EdgeInsets.all(5),
              child: pw.Text(item),
            ),
        ],
      );
    }

    pdf.addPage(
      pw.MultiPage(
          pageFormat: format,
          orientation: pw.PageOrientation.landscape,
          build: (pw.Context context) => [
            pw.Center(
                child: pw.Text('${branchObject['name']}', style: pw.TextStyle(font: getFontFormat(branchObject['name']), fontSize: 18))
            ),
            pw.SizedBox(height: 10),
            pw.Table(
                border: pw.TableBorder(
                  left: pw.BorderSide(width: 0),
                  top: pw.BorderSide(width: 0),
                  right: pw.BorderSide(width: 0),
                  bottom: pw.BorderSide(width: 0),
                  horizontalInside: pw.BorderSide(width: 0),
                  verticalInside: pw.BorderSide.none,
                ),
                children: [
                  pw.TableRow(
                      decoration: pw.BoxDecoration(
                        color: PdfColors.black,
                      ),
                      children: [
                        pw.Padding(
                          padding: pw.EdgeInsets.all(10),
                          child: pw.Text('Product', style: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold, font: getFontFormat('Product'))),
                        ),
                        pw.Padding(
                          padding: pw.EdgeInsets.fromLTRB(5, 10, 10, 10),
                          child: pw.Text('Variant', style: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold, font: getFontFormat('Product'))),
                        ),
                        pw.Padding(
                          padding: pw.EdgeInsets.fromLTRB(5, 10, 10, 10),
                          child: pw.Text('Quantity', style: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold, font: getFontFormat('Product'))),
                        ),
                        pw.Padding(
                          padding: pw.EdgeInsets.fromLTRB(5, 10, 10, 10),
                          child: pw.Text('Net Sales', style: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold, font: getFontFormat('Product'))),
                        ),
                        pw.Padding(
                          padding: pw.EdgeInsets.fromLTRB(5, 10, 10, 10),
                          child: pw.Text('Gross Sales', style: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold, font: getFontFormat('Product'))),
                        ),
                        pw.Padding(
                          padding: pw.EdgeInsets.fromLTRB(5, 10, 10, 10),
                          child: pw.Text('Cancel By', style: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold, font: getFontFormat('Product'))),
                        ),
                      ]
                  ),
                  for(int j = 0; j < valueList.length; j++)
                    for(int i = 0; i < valueList[j].categoryOrderDetailList.length; i++)
                      pw.TableRow(
                          children: [
                            pw.Padding(
                              padding: pw.EdgeInsets.fromLTRB(5, 5, 10, 5),
                              child: pw.Text('${valueList[j].categoryOrderDetailList[i].productName}',
                                  style: pw.TextStyle(font: getFontFormat(valueList[j].categoryOrderDetailList[i].productName))),
                            ),
                            pw.Padding(
                              padding: pw.EdgeInsets.fromLTRB(5, 5, 10, 5),
                              child: valueList[j].categoryOrderDetailList[i].product_variant_name != ''
                                  ?
                              pw.Text('${valueList[j].categoryOrderDetailList[i].product_variant_name}',
                                  style: pw.TextStyle(font: getFontFormat(valueList[j].categoryOrderDetailList[i].product_variant_name)))
                                  :
                              pw.Text('-', style: pw.TextStyle(font: getFontFormat('-'))),
                            ),
                            pw.Padding(
                              padding: pw.EdgeInsets.fromLTRB(5, 5, 10, 5),
                              child: pw.Text('${getQuantityFormat(value: valueList[j].categoryOrderDetailList[i])}',
                                  style: pw.TextStyle(font: getFontFormat(valueList[j].categoryOrderDetailList[i].item_sum))),
                            ),
                            pw.Padding(
                              padding: pw.EdgeInsets.fromLTRB(5, 5, 10, 5),
                              child: pw.Text('${valueList[j].categoryOrderDetailList[i].double_price!.toStringAsFixed(2)}',
                                  style: pw.TextStyle(font: getFontFormat(valueList[j].categoryOrderDetailList[i].double_price!.toStringAsFixed(2)))),
                            ),
                            pw.Padding(
                              padding: pw.EdgeInsets.fromLTRB(5, 5, 10, 5),
                              child: pw.Text('${valueList[j].categoryOrderDetailList[i].gross_price!.toStringAsFixed(2)}',
                                  style: pw.TextStyle(font: getFontFormat(valueList[j].categoryOrderDetailList[i].gross_price!.toStringAsFixed(2)))),
                            ),
                            pw.Padding(
                              padding: pw.EdgeInsets.fromLTRB(5, 5, 10, 5),
                              child: pw.Text('${valueList[j].categoryOrderDetailList[i].cancel_by}',
                                  style: pw.TextStyle(font: getFontFormat(valueList[j].categoryOrderDetailList[i].cancel_by))),
                            ),
                          ]
                      ),
                ]
            ),
          ]
      ),
    );
    return pdf.save();
  }

  Future<Uint8List> generateCancelModifierReportPdf(PdfPageFormat format, String title, ReportModel reportModel) async {
    List valueList = reportModel.reportValue2;
    final pdf = pw.Document(version: PdfVersion.pdf_1_5, compress: true);
    final font = await PdfGoogleFonts.nunitoExtraLight();
    final prefs = await SharedPreferences.getInstance();
    final String? branch = prefs.getString('branch');
    Map branchObject = json.decode(branch!);
    final imageByteData = await rootBundle.load('drawable/logo.png');
    // Convert ByteData to Uint8List
    final imageUint8List = imageByteData.buffer.asUint8List(imageByteData.offsetInBytes, imageByteData.lengthInBytes);
    final image = pw.MemoryImage(imageUint8List);

    pdf.addPage(
      pw.MultiPage(
          pageFormat: format,
          orientation: pw.PageOrientation.portrait,
          build: (pw.Context context) => [
            pw.Center(
                child: pw.Text('${branchObject['name']}', style: pw.TextStyle(font: getFontFormat(branchObject['name']), fontSize: 18))
            ),
            pw.SizedBox(height: 10),
            pw.Table(
                border: pw.TableBorder(
                  left: pw.BorderSide(width: 0),
                  top: pw.BorderSide(width: 0),
                  right: pw.BorderSide(width: 0),
                  bottom: pw.BorderSide(width: 0),
                  horizontalInside: pw.BorderSide(width: 0),
                  verticalInside: pw.BorderSide.none,
                ),
                children: [
                  pw.TableRow(
                      decoration: pw.BoxDecoration(
                        color: PdfColors.black,
                      ),
                      children: [
                        pw.Padding(
                          padding: pw.EdgeInsets.all(10),
                          child: pw.Text('Modifier', style: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold, font: getFontFormat('Modifier'))),
                        ),
                        pw.Padding(
                          padding: pw.EdgeInsets.fromLTRB(5, 10, 10, 10),
                          child: pw.Text('Quantity', style: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold, font: getFontFormat('Modifier'))),
                        ),
                        pw.Padding(
                          padding: pw.EdgeInsets.fromLTRB(5, 10, 10, 10),
                          child: pw.Text('Net Sales', style: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold, font: getFontFormat('Modifier'))),
                        ),
                      ]
                  ),
                  for(int j = 0; j < valueList.length; j++)
                    for(int i = 0; i < valueList[j].modDetailList.length; i++)
                      pw.TableRow(
                          children: [
                            pw.Padding(
                              padding: pw.EdgeInsets.fromLTRB(5, 5, 10, 5),
                              child: pw.Text('${valueList[j].modDetailList[i].mod_name}',
                                  style: pw.TextStyle(font: getFontFormat(valueList[j].modDetailList[i].mod_name))),
                            ),
                            pw.Padding(
                              padding: pw.EdgeInsets.fromLTRB(5, 5, 10, 5),
                              child: pw.Text('${valueList[j].modDetailList[i].item_sum}',
                                  style: pw.TextStyle(font: getFontFormat(valueList[j].modDetailList[i].item_sum))),
                            ),
                            pw.Padding(
                              padding: pw.EdgeInsets.fromLTRB(5, 5, 10, 5),
                              child: pw.Text('${valueList[j].modDetailList[i].net_sales!.toStringAsFixed(2)}',
                                  style: pw.TextStyle(font: getFontFormat(valueList[j].modDetailList[i].net_sales!.toStringAsFixed(2)))),
                            ),
                          ]
                      ),
                ]
            ),
          ]
      ),
    );
    return pdf.save();
  }

  Future<Uint8List> generateDiningReport(PdfPageFormat format, String title, ReportModel reportModel) async {
    List valueList = reportModel.reportValue2;
    final pdf = pw.Document(version: PdfVersion.pdf_1_5, compress: true);
    final prefs = await SharedPreferences.getInstance();
    final String? branch = prefs.getString('branch');
    Map branchObject = json.decode(branch!);
    final imageByteData = await rootBundle.load('drawable/logo.png');
    // Convert ByteData to Uint8List
    final imageUint8List = imageByteData.buffer.asUint8List(imageByteData.offsetInBytes, imageByteData.lengthInBytes);
    final image = pw.MemoryImage(imageUint8List);
    pdf.addPage(
      pw.MultiPage(
          pageFormat: format,
          orientation: pw.PageOrientation.portrait,
          build: (pw.Context context) => [
            pw.Center(
                child: pw.Text('${branchObject['name']}', style: pw.TextStyle(font: getFontFormat(branchObject['name']), fontSize: 18))
            ),
            pw.SizedBox(height: 10),
            pw.Table(
                border: pw.TableBorder(
                  left: pw.BorderSide(width: 0),
                  top: pw.BorderSide(width: 0),
                  right: pw.BorderSide(width: 0),
                  bottom: pw.BorderSide(width: 0),
                  horizontalInside: pw.BorderSide(width: 0),
                  verticalInside: pw.BorderSide.none,
                ),
                children: [
                  pw.TableRow(
                      decoration: pw.BoxDecoration(
                        color: PdfColors.black,
                      ),
                      children: [
                        pw.Padding(
                          padding: pw.EdgeInsets.all(10),
                          child: pw.Text('Dining Option', style: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold, font: getFontFormat('Dining Option'))),
                        ),
                        pw.Padding(
                          padding: pw.EdgeInsets.fromLTRB(5, 10, 10, 10),
                          child: pw.Text('Quantity', style: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold, font: getFontFormat('Quantity'))),
                        ),
                        pw.Padding(
                          padding: pw.EdgeInsets.fromLTRB(5, 10, 10, 10),
                          child: pw.Text('Net Sales', style: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold, font: getFontFormat('Net Sales'))),
                        ),
                        pw.Padding(
                          padding: pw.EdgeInsets.fromLTRB(5, 10, 10, 10),
                          child: pw.Text('Gross Sales', style: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold, font: getFontFormat('Gross Sales'))),
                        ),
                      ]
                  ),
                  for(int j = 0; j < valueList.length; j++)
                    pw.TableRow(
                        children: [
                          pw.Padding(
                            padding: pw.EdgeInsets.fromLTRB(5, 5, 10, 5),
                            child: pw.Text('${valueList[j].dining_name}', style: pw.TextStyle(font: getFontFormat(valueList[j].dining_name))),
                          ),
                          pw.Padding(
                            padding: pw.EdgeInsets.fromLTRB(5, 5, 10, 5),
                            child: pw.Text('${valueList[j].item_sum}', style: pw.TextStyle(font: getFontFormat(valueList[j].item_sum))),
                          ),
                          pw.Padding(
                            padding: pw.EdgeInsets.fromLTRB(5, 5, 10, 5),
                            child: pw.Text('${valueList[j].net_sales.toStringAsFixed(2)}', style: pw.TextStyle(font: getFontFormat(valueList[j].net_sales.toStringAsFixed(2)))),
                          ),
                          pw.Padding(
                            padding: pw.EdgeInsets.fromLTRB(5, 5, 10, 5),
                            child: pw.Text('${valueList[j].gross_sales.toStringAsFixed(2)}', style: pw.TextStyle(font: getFontFormat(valueList[j].gross_sales.toStringAsFixed(2)))),
                          ),
                        ]
                    ),
                ]
            ),
          ]
      ),
    );

    return pdf.save();
  }

  Future<Uint8List> generatePaymentReport(PdfPageFormat format, String title, ReportModel reportModel) async {
    List valueList = reportModel.reportValue2;
    final pdf = pw.Document(version: PdfVersion.pdf_1_5, compress: true);
    final prefs = await SharedPreferences.getInstance();
    final String? branch = prefs.getString('branch');
    Map branchObject = json.decode(branch!);
    final imageByteData = await rootBundle.load('drawable/logo.png');
    // Convert ByteData to Uint8List
    final imageUint8List = imageByteData.buffer.asUint8List(imageByteData.offsetInBytes, imageByteData.lengthInBytes);
    final image = pw.MemoryImage(imageUint8List);
    pdf.addPage(
      pw.MultiPage(
          pageFormat: format,
          orientation: pw.PageOrientation.portrait,
          build: (pw.Context context) => [
            pw.Center(
                child: pw.Text('${branchObject['name']}', style: pw.TextStyle(font: getFontFormat(branchObject['name']), fontSize: 18))
            ),
            pw.SizedBox(height: 10),
            pw.Table(
                border: pw.TableBorder(
                  left: pw.BorderSide(width: 0),
                  top: pw.BorderSide(width: 0),
                  right: pw.BorderSide(width: 0),
                  bottom: pw.BorderSide(width: 0),
                  horizontalInside: pw.BorderSide(width: 0),
                  verticalInside: pw.BorderSide.none,
                ),
                children: [
                  pw.TableRow(
                      decoration: pw.BoxDecoration(
                        color: PdfColors.black,
                      ),
                      children: [
                        pw.Padding(
                          padding: pw.EdgeInsets.all(10),
                          child: pw.Text('Payment Type', style: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold, font: getFontFormat('Payment Type'))),
                        ),
                        pw.Padding(
                          padding: pw.EdgeInsets.fromLTRB(5, 10, 10, 10),
                          child: pw.Text('Quantity', style: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold, font: getFontFormat('Quantity'))),
                        ),
                        pw.Padding(
                          padding: pw.EdgeInsets.fromLTRB(5, 10, 10, 10),
                          child: pw.Text('Net Sales', style: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold, font: getFontFormat('Net Sales'))),
                        ),
                        pw.Padding(
                          padding: pw.EdgeInsets.fromLTRB(5, 10, 10, 10),
                          child: pw.Text('Gross Sales', style: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold, font: getFontFormat('Gross Sales'))),
                        ),
                      ]
                  ),
                  for(int j = 0; j < valueList.length; j++)
                    pw.TableRow(
                        children: [
                          pw.Padding(
                            padding: pw.EdgeInsets.fromLTRB(5, 5, 10, 5),
                            child: pw.Text('${valueList[j].payment_name}', style: pw.TextStyle(font: getFontFormat(valueList[j].payment_name))),
                          ),
                          pw.Padding(
                            padding: pw.EdgeInsets.fromLTRB(5, 5, 10, 5),
                            child: pw.Text('${valueList[j].item_sum}', style: pw.TextStyle(font: getFontFormat(valueList[j].item_sum))),
                          ),
                          pw.Padding(
                            padding: pw.EdgeInsets.fromLTRB(5, 5, 10, 5),
                            child: pw.Text('${valueList[j].net_sales.toStringAsFixed(2)}', style: pw.TextStyle(font: getFontFormat(valueList[j].net_sales.toStringAsFixed(2)))),
                          ),
                          pw.Padding(
                            padding: pw.EdgeInsets.fromLTRB(5, 5, 10, 5),
                            child: pw.Text('${valueList[j].gross_sales.toStringAsFixed(2)}', style: pw.TextStyle(font: getFontFormat(valueList[j].gross_sales.toStringAsFixed(2)))),
                          ),
                        ]
                    ),
                ]
            ),
          ]
      ),
    );

    return pdf.save();
  }

  Future<Uint8List> generateRefundReport(PdfPageFormat format, String title, ReportModel reportModel) async {
    List valueList = reportModel.reportValue2;
    List headerList = reportModel.headerValue;
    final pdf = pw.Document(version: PdfVersion.pdf_1_5, compress: true);
    final prefs = await SharedPreferences.getInstance();
    final String? branch = prefs.getString('branch');
    Map branchObject = json.decode(branch!);
    final imageByteData = await rootBundle.load('drawable/logo.png');
    // Convert ByteData to Uint8List
    final imageUint8List = imageByteData.buffer.asUint8List(imageByteData.offsetInBytes, imageByteData.lengthInBytes);
    final image = pw.MemoryImage(imageUint8List);
    pdf.addPage(
      pw.MultiPage(
          pageFormat: format,
          orientation: pw.PageOrientation.landscape,
          build: (pw.Context context) => [
            pw.Center(
                child: pw.Text('${branchObject['name']}', style: pw.TextStyle(font: getFontFormat(branchObject['name']), fontSize: 18))
            ),
            pw.SizedBox(height: 10),
            pw.Table(
                border: pw.TableBorder(
                  left: pw.BorderSide(width: 0),
                  top: pw.BorderSide(width: 0),
                  right: pw.BorderSide(width: 0),
                  bottom: pw.BorderSide(width: 0),
                  horizontalInside: pw.BorderSide(width: 0),
                  verticalInside: pw.BorderSide.none,
                ),
                children: [
                  pw.TableRow(
                      decoration: pw.BoxDecoration(
                        color: PdfColors.black,
                      ),
                      children: [
                        pw.Padding(
                          padding: pw.EdgeInsets.all(10),
                          child: pw.Text('Receipt No', style: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold, font: getFontFormat('Receipt'))),
                        ),
                        pw.Padding(
                          padding: pw.EdgeInsets.fromLTRB(5, 10, 10, 10),
                          child: pw.Text('Subtotal', style: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold, font: getFontFormat('Receipt'))),
                        ),
                        pw.Padding(
                          padding: pw.EdgeInsets.fromLTRB(5, 10, 10, 10),
                          child: pw.Text('Amount', style: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold, font: getFontFormat('Receipt'))),
                        ),
                        pw.Padding(
                          padding: pw.EdgeInsets.fromLTRB(5, 10, 10, 10),
                          child: pw.Text('Rounding', style: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold, font: getFontFormat('Receipt'))),
                        ),
                        pw.Padding(
                          padding: pw.EdgeInsets.fromLTRB(5, 10, 10, 10),
                          child: pw.Text('Final Amount', style: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold, font: getFontFormat('Receipt'))),
                        ),
                        pw.Padding(
                          padding: pw.EdgeInsets.fromLTRB(5, 10, 10, 10),
                          child: pw.Text('Refund By', style: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold, font: getFontFormat('Receipt'))),
                        ),
                        pw.Padding(
                          padding: pw.EdgeInsets.fromLTRB(5, 10, 10, 10),
                          child: pw.Text('Refund At', style: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold, font: getFontFormat('Receipt'))),
                        ),
                      ]
                  ),
                  for(int j = 0; j < valueList.length; j++)
                    pw.TableRow(
                        children: [
                          pw.Padding(
                            padding: pw.EdgeInsets.fromLTRB(5, 5, 10, 5),
                            child: pw.Text('${valueList[j].bill_no}', style: pw.TextStyle(font: getFontFormat(valueList[j].bill_no))),
                          ),
                          pw.Padding(
                            padding: pw.EdgeInsets.fromLTRB(5, 5, 10, 5),
                            child: pw.Text('${valueList[j].subtotal}', style: pw.TextStyle(font: getFontFormat(valueList[j].subtotal))),
                          ),
                          pw.Padding(
                            padding: pw.EdgeInsets.fromLTRB(5, 5, 10, 5),
                            child: pw.Text('${valueList[j].amount}', style: pw.TextStyle(font: getFontFormat(valueList[j].amount))),
                          ),
                          pw.Padding(
                            padding: pw.EdgeInsets.fromLTRB(5, 5, 10, 5),
                            child: pw.Text('${valueList[j].rounding}', style: pw.TextStyle(font: getFontFormat(valueList[j].rounding))),
                          ),
                          pw.Padding(
                            padding: pw.EdgeInsets.fromLTRB(5, 5, 10, 5),
                            child: pw.Text('${valueList[j].final_amount}', style: pw.TextStyle(font: getFontFormat(valueList[j].final_amount))),
                          ),
                          pw.Padding(
                            padding: pw.EdgeInsets.fromLTRB(5, 5, 10, 5),
                            child: pw.Text('${valueList[j].refund_by}', style: pw.TextStyle(font: getFontFormat(valueList[j].refund_by))),
                          ),
                          pw.Padding(
                            padding: pw.EdgeInsets.fromLTRB(5, 5, 10, 5),
                            child: pw.Text('${valueList[j].refund_at}', style: pw.TextStyle(font: getFontFormat(valueList[j].refund_at))),
                          ),
                        ]
                    ),
                ]
            ),
          ]
      ),
    );
    //second page
    pdf.addPage(
        pw.MultiPage(
            pageFormat: format,
            orientation: pw.PageOrientation.landscape,
            build: (pw.Context context) => [
              pw.Table(
                  border: pw.TableBorder(
                    left: pw.BorderSide(width: 0),
                    top: pw.BorderSide(width: 0),
                    right: pw.BorderSide(width: 0),
                    bottom: pw.BorderSide(width: 0),
                    horizontalInside: pw.BorderSide(width: 0),
                    verticalInside: pw.BorderSide.none,
                  ),
                  children: [
                    pw.TableRow(
                        decoration: pw.BoxDecoration(
                          color: PdfColors.black,
                        ),
                        children: [
                          pw.Padding(
                            padding: pw.EdgeInsets.fromLTRB(10, 5, 10, 5),
                            child: pw.Text('Receipt No', style: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold, font: getFontFormat('Receipt No'))),
                          ),
                          pw.Padding(
                            padding: pw.EdgeInsets.fromLTRB(5, 10, 10, 10),
                            child: pw.Text('Total Discount', style: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold, font: getFontFormat('Total Discount'))),
                          ),
                          pw.Padding(
                            padding: pw.EdgeInsets.fromLTRB(5, 10, 10, 10),
                            child: pw.Text('Total Tax', style: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold, font: getFontFormat('Total Discount'))),
                          ),
                        ]
                    ),
                    for(int j = 0; j < valueList.length; j++)
                      pw.TableRow(
                          children: [
                            pw.Padding(
                              padding: pw.EdgeInsets.fromLTRB(5, 5, 10, 5),
                              child: pw.Text('${valueList[j].bill_no}', style: pw.TextStyle(font: getFontFormat(valueList[j].bill_no))),
                            ),
                            valueList[j].promo_amount == null ?
                            pw.Padding(
                              padding: pw.EdgeInsets.fromLTRB(5, 5, 10, 5),
                              child: pw.Text('-0.00', style: pw.TextStyle(font: getFontFormat('-0.00'))),
                            )
                                :
                            pw.Padding(
                              padding: pw.EdgeInsets.fromLTRB(5, 5, 10, 5),
                              child: pw.Text('-${valueList[j].promo_amount}', style: pw.TextStyle(font: getFontFormat(valueList[j].promo_amount))),
                            ),
                            pw.Padding(
                              padding: pw.EdgeInsets.fromLTRB(5, 5, 10, 5),
                              child: pw.Text('${valueList[j].total_tax_amount!.toStringAsFixed(2)}',
                                  style: pw.TextStyle(font: getFontFormat(valueList[j].total_tax_amount!.toStringAsFixed(2)))),
                            ),
                            // if(valueList[j].taxDetailList.length == 0)
                            //   for(int i = 0; i < headerList.length; i++)
                            //     pw.Padding(
                            //       padding: pw.EdgeInsets.fromLTRB(5, 5, 10, 5),
                            //       child: pw.Text('0.00', style: pw.TextStyle(font: getFontFormat('0.00'))))
                            // else
                            // for(int i = 0; i < valueList[j].taxDetailList.length; i++)
                            //   pw.Padding(
                            //     padding: pw.EdgeInsets.fromLTRB(5, 5, 10, 5),
                            //     child: pw.Text('${valueList[j].taxDetailList[i].total_tax_amount!.toStringAsFixed(2)}',
                            //         style: pw.TextStyle(font: getFontFormat(valueList[j].taxDetailList[i].total_tax_amount!.toStringAsFixed(2)))),
                            //   ),

                          ]
                      ),
                  ]
              )
            ])
    );

    return pdf.save();
  }

  Future<Uint8List> generateCashRecordReport(PdfPageFormat format, String title, ReportModel reportModel) async {
    List valueList = reportModel.reportValue2;
    final pdf = pw.Document(version: PdfVersion.pdf_1_5, compress: true);
    final prefs = await SharedPreferences.getInstance();
    final String? branch = prefs.getString('branch');
    Map branchObject = json.decode(branch!);
    final imageByteData = await rootBundle.load('drawable/logo.png');
    // Convert ByteData to Uint8List
    final imageUint8List = imageByteData.buffer.asUint8List(imageByteData.offsetInBytes, imageByteData.lengthInBytes);
    final image = pw.MemoryImage(imageUint8List);
    pdf.addPage(
      pw.MultiPage(
          pageFormat: format,
          orientation: pw.PageOrientation.portrait,
          build: (pw.Context context) => [
            pw.Center(
                child: pw.Text('${branchObject['name']}', style: pw.TextStyle(font: getFontFormat(branchObject['name']), fontSize: 18))
            ),
            pw.SizedBox(height: 10),
            pw.Table(
                border: pw.TableBorder(
                  left: pw.BorderSide(width: 0),
                  top: pw.BorderSide(width: 0),
                  right: pw.BorderSide(width: 0),
                  bottom: pw.BorderSide(width: 0),
                  horizontalInside: pw.BorderSide(width: 0),
                  verticalInside: pw.BorderSide.none,
                ),
                children: [
                  pw.TableRow(
                      decoration: pw.BoxDecoration(
                        color: PdfColors.black,
                      ),
                      children: [
                        pw.Padding(
                          padding: pw.EdgeInsets.all(10),
                          child: pw.Text('DateTime', style: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold, font: getFontFormat('DateTime'))),
                        ),
                        pw.Padding(
                          padding: pw.EdgeInsets.fromLTRB(5, 10, 10, 10),
                          child: pw.Text('User', style: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold, font: getFontFormat('User'))),
                        ),
                        pw.Padding(
                          padding: pw.EdgeInsets.fromLTRB(5, 10, 10, 10),
                          child: pw.Text('Remark', style: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold, font: getFontFormat('Remark'))),
                        ),
                        pw.Padding(
                          padding: pw.EdgeInsets.fromLTRB(5, 10, 10, 10),
                          child: pw.Text('Amount', style: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold, font: getFontFormat('Amount'))),
                        ),
                        pw.Padding(
                          padding: pw.EdgeInsets.fromLTRB(5, 10, 10, 10),
                          child: pw.Text('Payment Method', style: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold, font: getFontFormat('PaymentMethod'))),
                        ),
                      ]
                  ),
                  for(int j = 0; j < valueList.length; j++)
                    pw.TableRow(
                        children: [
                          pw.Padding(
                            padding: pw.EdgeInsets.fromLTRB(5, 5, 10, 5),
                            child: pw.Text('${Utils.formatDate(valueList[j].created_at!)}', style: pw.TextStyle(font: getFontFormat(valueList[j].created_at))),
                          ),
                          pw.Padding(
                            padding: pw.EdgeInsets.fromLTRB(5, 5, 10, 5),
                            child: pw.Text('${valueList[j].userName}', style: pw.TextStyle(font: getFontFormat(valueList[j].userName))),
                          ),
                          pw.Padding(
                            padding: pw.EdgeInsets.fromLTRB(5, 5, 10, 5),
                            child: pw.Text('${valueList[j].remark}', style: pw.TextStyle(font: getFontFormat(valueList[j].remark))),
                          ),
                          pw.Padding(
                            padding: pw.EdgeInsets.fromLTRB(5, 5, 10, 5),
                            child: pw.Text('${formatAmount(cashRecord: valueList[j])}', style: pw.TextStyle(font: getFontFormat(formatAmount(cashRecord: valueList[j])))),
                          ),
                          pw.Padding(
                            padding: pw.EdgeInsets.fromLTRB(5, 5, 10, 5),
                            child: pw.Text('${valueList[j].payment_method ?? ''}', style: pw.TextStyle(font: getFontFormat(valueList[j].payment_method))),
                          ),
                        ]
                    ),
                ]
            ),
          ]
      ),
    );

    return pdf.save();
  }

  Future<Uint8List> generateAttendanceReport(PdfPageFormat format, String title, ReportModel reportModel) async {
    List valueList = reportModel.reportValue2;
    final pdf = pw.Document(version: PdfVersion.pdf_1_5, compress: true);
    final imageByteData = await rootBundle.load('drawable/logo.png');
    // Convert ByteData to Uint8List
    final imageUint8List = imageByteData.buffer.asUint8List(imageByteData.offsetInBytes, imageByteData.lengthInBytes);
    final image = pw.MemoryImage(imageUint8List);

    // Define a function to generate the parent row
    pw.TableRow _generateParentRow(List<String> rowData) {
      return pw.TableRow(
        children: [
          for (final item in rowData)
            pw.Padding(
              padding: pw.EdgeInsets.all(5),
              child: pw.Text(item),
            ),
        ],
      );
    }

    pdf.addPage(
      pw.MultiPage(
          pageFormat: format,
          orientation: pw.PageOrientation.landscape,
          build: (pw.Context context) => [
            pw.Center(
              child: pw.SizedBox(
                  height: 100,
                  width: 100,
                  child: pw.Image(image)
              ),
            ),
            pw.Table(
                border: pw.TableBorder(
                  left: pw.BorderSide(width: 0),
                  top: pw.BorderSide(width: 0),
                  right: pw.BorderSide(width: 0),
                  bottom: pw.BorderSide(width: 0),
                  horizontalInside: pw.BorderSide(width: 0),
                  verticalInside: pw.BorderSide.none,
                ),
                children: [
                  pw.TableRow(
                      decoration: pw.BoxDecoration(
                        color: PdfColors.black,
                      ),
                      children: [
                        pw.Padding(
                          padding: pw.EdgeInsets.all(10),
                          child: pw.Text('User', style: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold, font: getFontFormat('User'))),
                        ),
                        pw.Padding(
                          padding: pw.EdgeInsets.fromLTRB(5, 10, 10, 10),
                          child: pw.Text('Clock in', style: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold, font: getFontFormat('Clock in'))),
                        ),
                        pw.Padding(
                          padding: pw.EdgeInsets.fromLTRB(5, 10, 10, 10),
                          child: pw.Text('Clock out', style: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold, font: getFontFormat('Clock out'))),
                        ),
                        pw.Padding(
                          padding: pw.EdgeInsets.fromLTRB(5, 10, 10, 10),
                          child: pw.Text('Hour/Minute', style: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold, font: getFontFormat('Hour/Minute'))),
                        ),
                      ]
                  ),
                  for(int j = 0; j < valueList.length; j++)
                    for(int i = 0; i < valueList[j].groupAttendanceList.length; i++)
                      pw.TableRow(
                          children: [
                            pw.Padding(
                              padding: pw.EdgeInsets.fromLTRB(5, 5, 10, 5),
                              child: pw.Text('${valueList[j].userName}',
                                  style: pw.TextStyle(font: getFontFormat(valueList[j].userName))),
                            ),
                            pw.Padding(
                              padding: pw.EdgeInsets.fromLTRB(5, 5, 10, 5),
                              child: pw.Text('${valueList[j].groupAttendanceList[i].clock_in_at}',
                                  style: pw.TextStyle(font: getFontFormat(valueList[j].groupAttendanceList[i].clock_in_at))),
                            ),
                            pw.Padding(
                              padding: pw.EdgeInsets.fromLTRB(5, 5, 10, 5),
                              child: pw.Text('${valueList[j].groupAttendanceList[i].clock_out_at}',
                                  style: pw.TextStyle(font: getFontFormat(valueList[j].groupAttendanceList[i].clock_out_at))),
                            ),
                            pw.Padding(
                              padding: pw.EdgeInsets.fromLTRB(5, 5, 10, 5),
                              child: pw.Text('${getDuration(valueList[j].groupAttendanceList[i].duration)}',
                                  style: pw.TextStyle(font: getFontFormat(valueList[j].groupAttendanceList[i].duration))),
                            ),
                          ]
                      ),
                ]
            ),
          ]
      ),
    );
    return pdf.save();
  }

  Future<Uint8List> generateStaffSalesReport(PdfPageFormat format, String title, ReportModel reportModel) async {
    List valueList = reportModel.reportValue2;
    final pdf = pw.Document(version: PdfVersion.pdf_1_5, compress: true);
    final prefs = await SharedPreferences.getInstance();
    final String? branch = prefs.getString('branch');
    Map branchObject = json.decode(branch!);
    final imageByteData = await rootBundle.load('drawable/logo.png');
    // Convert ByteData to Uint8List
    final imageUint8List = imageByteData.buffer.asUint8List(imageByteData.offsetInBytes, imageByteData.lengthInBytes);
    final image = pw.MemoryImage(imageUint8List);
    pdf.addPage(
      pw.MultiPage(
          pageFormat: format,
          orientation: pw.PageOrientation.portrait,
          build: (pw.Context context) => [
            pw.Center(
                child: pw.Text('${branchObject['name']}', style: pw.TextStyle(font: getFontFormat(branchObject['name']), fontSize: 18))
            ),
            pw.SizedBox(height: 10),
            pw.Table(
                border: pw.TableBorder(
                  left: pw.BorderSide(width: 0),
                  top: pw.BorderSide(width: 0),
                  right: pw.BorderSide(width: 0),
                  bottom: pw.BorderSide(width: 0),
                  horizontalInside: pw.BorderSide(width: 0),
                  verticalInside: pw.BorderSide.none,
                ),
                children: [
                  pw.TableRow(
                      decoration: pw.BoxDecoration(
                        color: PdfColors.black,
                      ),
                      children: [
                        pw.Padding(
                          padding: pw.EdgeInsets.fromLTRB(5, 10, 10, 10),
                          child: pw.Text('User', style: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold, font: getFontFormat('User'))),
                        ),
                        pw.Padding(
                          padding: pw.EdgeInsets.fromLTRB(5, 10, 10, 10),
                          child: pw.Text('Amount', style: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold, font: getFontFormat('Amount'))),
                        ),
                      ]
                  ),
                  for(int j = 0; j < valueList.length; j++)
                    pw.TableRow(
                        children: [
                          pw.Padding(
                            padding: pw.EdgeInsets.fromLTRB(5, 5, 10, 5),
                            child: pw.Text('${valueList[j].close_by}', style: pw.TextStyle(font: getFontFormat(valueList[j].close_by))),
                          ),
                          pw.Padding(
                            padding: pw.EdgeInsets.fromLTRB(5, 5, 10, 5),
                            child: pw.Text('${Utils.to2Decimal(valueList[j].gross_sales)}', style: pw.TextStyle(font: getFontFormat(Utils.to2Decimal(valueList[j].gross_sales)))),
                          ),
                        ]
                    ),
                ]
            ),
          ]
      ),
    );
    return pdf.save();
  }

  String formatAmount({required CashRecord cashRecord}){
    String newAmount = Utils.to2Decimal(double.parse(cashRecord.amount!));
    if(cashRecord.type == 2 || cashRecord.type == 4){
      newAmount = "-${Utils.to2Decimal(double.parse(cashRecord.amount!))}";
    }
    return newAmount;
  }

  Future<Uint8List> generateReportPdf(PdfPageFormat format, String title) async {
    final pdf = pw.Document(version: PdfVersion.pdf_1_5, compress: true);
    final font = await PdfGoogleFonts.nunitoExtraLight();
    final prefs = await SharedPreferences.getInstance();
    final String? branch = prefs.getString('branch');
    Map branchObject = json.decode(branch!);
    final imageByteData = await rootBundle.load('drawable/logo.png');
    // Convert ByteData to Uint8List
    final imageUint8List = imageByteData.buffer.asUint8List(imageByteData.offsetInBytes, imageByteData.lengthInBytes);
    final image = pw.MemoryImage(imageUint8List);
    pdf.addPage(
      pw.Page(
        pageFormat: format,
        build: (context) {
          return pw.Column(
            children: [
              pw.Center(
                  child: pw.Text('${branchObject['name']}', style: pw.TextStyle(font: getFontFormat(branchObject['name']), fontSize: 18))
              ),
              pw.SizedBox(height: 10),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  Future<List<PosTable>>generateUrl(List<PosTable> posTableList) async {
    final prefs = await SharedPreferences.getInstance();
    final String? branch = prefs.getString('branch');
    Map branchObject = json.decode(branch!);
    for(int i = 0; i < posTableList.length; i++){
      var url = '${Domain.qr_domain}${branchObject['branch_url']}/${posTableList[i].table_url}';
      posTableList[i].qrOrderUrl = url;
    }
    return posTableList;
  }

  Future<Uint8List> generateQrPdf(PdfPageFormat format, List<PosTable> selectedTable) async {
    print('table length: ${selectedTable.length}');
    List<PosTable> tableList = await generateUrl(selectedTable);
    final pdf = pw.Document(version: PdfVersion.pdf_1_5, compress: true);
    final font = await PdfGoogleFonts.robotoBlack();
    final imageByteData = await rootBundle.load('drawable/logo.png');
    // Convert ByteData to Uint8List
    final imageUint8List = imageByteData.buffer.asUint8List(imageByteData.offsetInBytes, imageByteData.lengthInBytes);
    final image = pw.MemoryImage(imageUint8List);
    // final logoFile = FileImage(File('/data/data/com.example.pos_system/files/assets/img/logo1.jpg'));
    // final logoImage = await flutterImageProvider(logoFile);
    pdf.addPage(
      pw.MultiPage(
        pageFormat: format,
        build: (pw.Context context) => [
          pw.Center(
              child: pw.Container(
                // height: 500,
                child: pw.GridView(
                    padding: pw.EdgeInsets.only(bottom: 50),
                    crossAxisCount: 2,
                    childAspectRatio: 1.10,
                    children: List.generate(
                      tableList.length, (index) => pw.Column(
                        children: [
                          pw.Container(
                              height: 200,
                              width: 200,
                              padding: pw.EdgeInsets.all(15),
                              decoration: pw.BoxDecoration(
                                border: pw.Border.all(color: PdfColors.black),
                              ),
                              child: pw.Stack(
                                  children: [
                                    pw.BarcodeWidget(
                                        data: tableList[index].qrOrderUrl!,
                                        barcode: pw.Barcode.qrCode()
                                    ),
                                    pw.Center(
                                        child: pw.SizedBox(
                                            height: 60,
                                            width: 60,
                                            child: pw.Image(image))
                                    ),
                                  ]
                              ),
                          ),
                          pw.SizedBox(height: 10),
                          pw.Center(
                              child: pw.Text('Table No: ${tableList[index].number}', style: pw.TextStyle(font: font, fontSize: 24))
                          ),
                        ]
                    ),
                    )
                )
              )
          )
        ]
      ),
    );

    return pdf.save();
  }







  // savePdf(List<int> documentBytes ) async {
  //   DateFormat dateFormat = DateFormat("yyyy-MM-dd");
  //   String dateTime = dateFormat.format(DateTime.now());
  //   String name = '';
  //   name = '${dateTime}.pdf';
  //   final path = await _localPath;
  //   final folderName = 'report_pdf';
  //   final pathReport = Directory("$path/assets/$folderName");
  //   var localPath = pathReport.path + '/' + name;
  //   final pdfFile = File(localPath);
  //   await pdfFile.writeAsBytes(documentBytes, flush: true);
  // }
  //
  // Future<String> get _localPath async {
  //   final directory = await getApplicationSupportDirectory();
  //   return directory.path;
  // }
  //
  // Future<void> createPDF(String reportTitle) async {
  //   print('pdf created!');
  //   //Create a PDF document.
  //   final PdfDocument document = PdfDocument();
  //   //Add page to the PDF
  //   final PdfPage page = document.pages.add();
  //   //Get page client size
  //   final Size pageSize = page.getClientSize();
  //   //Draw rectangle
  //   page.graphics.drawRectangle(
  //       bounds: Rect.fromLTWH(0, 0, pageSize.width, pageSize.height),
  //       pen: PdfPen(PdfColor(142, 170, 219)));
  //   //Generate PDF grid.
  //   final PdfGrid grid = getGrid();
  //   //Draw the header section by creating text element
  //   final PdfLayoutResult result = drawHeader(page, pageSize, grid);
  //   //Draw grid
  //   drawGrid(page, grid, result);
  //   //Add invoice footer
  //   drawFooter(page, pageSize);
  //
  //
  //   //Save the document
  //   List<int> bytes = await document.save();
  //
  //   await savePdf(bytes);
  //
  //   //Dispose the document
  //   document.dispose();
  // }
  //
  // //Draws the invoice header
  // PdfLayoutResult drawHeader(PdfPage page, Size pageSize, PdfGrid grid) {
  //   //Draw rectangle
  //   page.graphics.drawRectangle(
  //       brush: PdfSolidBrush(PdfColor(91, 126, 215)),
  //       bounds: Rect.fromLTWH(0, 0, pageSize.width - 115, 90));
  //   //Draw string
  //   page.graphics.drawString(
  //       'INVOICE', PdfStandardFont(PdfFontFamily.helvetica, 30),
  //       brush: PdfBrushes.white,
  //       bounds: Rect.fromLTWH(25, 0, pageSize.width - 115, 90),
  //       format: PdfStringFormat(lineAlignment: PdfVerticalAlignment.middle));
  //
  //   page.graphics.drawRectangle(
  //       bounds: Rect.fromLTWH(400, 0, pageSize.width - 400, 90),
  //       brush: PdfSolidBrush(PdfColor(65, 104, 205)));
  //
  //   page.graphics.drawString(r'$' + getTotalAmount(grid).toString(),
  //       PdfStandardFont(PdfFontFamily.helvetica, 18),
  //       bounds: Rect.fromLTWH(400, 0, pageSize.width - 400, 100),
  //       brush: PdfBrushes.white,
  //       format: PdfStringFormat(
  //           alignment: PdfTextAlignment.center,
  //           lineAlignment: PdfVerticalAlignment.middle));
  //
  //   final PdfFont contentFont = PdfStandardFont(PdfFontFamily.helvetica, 9);
  //   //Draw string
  //   page.graphics.drawString('Amount', contentFont,
  //       brush: PdfBrushes.white,
  //       bounds: Rect.fromLTWH(400, 0, pageSize.width - 400, 33),
  //       format: PdfStringFormat(
  //           alignment: PdfTextAlignment.center,
  //           lineAlignment: PdfVerticalAlignment.bottom));
  //   //Create data foramt and convert it to text.
  //   final DateFormat format = DateFormat.yMMMMd('en_US');
  //   final String invoiceNumber =
  //       'Invoice Number: 2058557939\r\n\r\nDate: ${format.format(DateTime.now())}';
  //   final Size contentSize = contentFont.measureString(invoiceNumber);
  //   // ignore: leading_newlines_in_multiline_strings
  //   const String address = '''Bill To: \r\n\r\nAbraham Swearegin,
  //       \r\n\r\nUnited States, California, San Mateo,
  //       \r\n\r\n9920 BridgePointe Parkway, \r\n\r\n9365550136''';
  //
  //   PdfTextElement(text: invoiceNumber, font: contentFont).draw(
  //       page: page,
  //       bounds: Rect.fromLTWH(pageSize.width - (contentSize.width + 30), 120,
  //           contentSize.width + 30, pageSize.height - 120));
  //
  //   return PdfTextElement(text: address, font: contentFont).draw(
  //       page: page,
  //       bounds: Rect.fromLTWH(30, 120,
  //           pageSize.width - (contentSize.width + 30), pageSize.height - 120))!;
  // }
  //
  // //Draws the grid
  // void drawGrid(PdfPage page, PdfGrid grid, PdfLayoutResult result) {
  //   Rect? totalPriceCellBounds;
  //   Rect? quantityCellBounds;
  //   //Invoke the beginCellLayout event.
  //   grid.beginCellLayout = (Object sender, PdfGridBeginCellLayoutArgs args) {
  //     final PdfGrid grid = sender as PdfGrid;
  //     if (args.cellIndex == grid.columns.count - 1) {
  //       totalPriceCellBounds = args.bounds;
  //     } else if (args.cellIndex == grid.columns.count - 2) {
  //       quantityCellBounds = args.bounds;
  //     }
  //   };
  //   //Draw the PDF grid and get the result.
  //   result = grid.draw(
  //       page: page, bounds: Rect.fromLTWH(0, result.bounds.bottom + 40, 0, 0))!;
  //
  //   //Draw grand total.
  //   page.graphics.drawString('Grand Total',
  //       PdfStandardFont(PdfFontFamily.helvetica, 9, style: PdfFontStyle.bold),
  //       bounds: Rect.fromLTWH(
  //           quantityCellBounds!.left,
  //           result.bounds.bottom + 10,
  //           quantityCellBounds!.width,
  //           quantityCellBounds!.height));
  //   page.graphics.drawString(getTotalAmount(grid).toString(),
  //       PdfStandardFont(PdfFontFamily.helvetica, 9, style: PdfFontStyle.bold),
  //       bounds: Rect.fromLTWH(
  //           totalPriceCellBounds!.left,
  //           result.bounds.bottom + 10,
  //           totalPriceCellBounds!.width,
  //           totalPriceCellBounds!.height));
  // }
  //
  // //Draw the invoice footer data.
  // void drawFooter(PdfPage page, Size pageSize) {
  //   final PdfPen linePen =
  //   PdfPen(PdfColor(142, 170, 219), dashStyle: PdfDashStyle.custom);
  //   linePen.dashPattern = <double>[3, 3];
  //   //Draw line
  //   page.graphics.drawLine(linePen, Offset(0, pageSize.height - 100),
  //       Offset(pageSize.width, pageSize.height - 100));
  //
  //   const String footerContent =
  //   // ignore: leading_newlines_in_multiline_strings
  //   '''800 Interchange Blvd.\r\n\r\nSuite 2501, Austin,
  //        TX 78721\r\n\r\nAny Questions? support@adventure-works.com''';
  //
  //   //Added 30 as a margin for the layout
  //   page.graphics.drawString(
  //       footerContent, PdfStandardFont(PdfFontFamily.helvetica, 9),
  //       format: PdfStringFormat(alignment: PdfTextAlignment.right),
  //       bounds: Rect.fromLTWH(pageSize.width - 30, pageSize.height - 70, 0, 0));
  // }
  //
  // //Create PDF grid and return
  // PdfGrid getGrid() {
  //   //Create a PDF grid
  //   final PdfGrid grid = PdfGrid();
  //   //Secify the columns count to the grid.
  //   grid.columns.add(count: 5);
  //   //Create the header row of the grid.
  //   final PdfGridRow headerRow = grid.headers.add(1)[0];
  //   //Set style
  //   headerRow.style.backgroundBrush = PdfSolidBrush(PdfColor(68, 114, 196));
  //   headerRow.style.textBrush = PdfBrushes.white;
  //   headerRow.cells[0].value = 'Product Id';
  //   headerRow.cells[0].stringFormat.alignment = PdfTextAlignment.center;
  //   headerRow.cells[1].value = 'Product Name';
  //   headerRow.cells[2].value = 'Price';
  //   headerRow.cells[3].value = 'Quantity';
  //   headerRow.cells[4].value = 'Total';
  //   //Add rows
  //   addProducts('CA-1098', 'AWC Logo Cap', 8.99, 2, 17.98, grid);
  //   addProducts('LJ-0192', 'Long-Sleeve Logo Jersey,M', 49.99, 3, 149.97, grid);
  //   addProducts('So-B909-M', 'Mountain Bike Socks,M', 9.5, 2, 19, grid);
  //   addProducts('LJ-0192', 'Long-Sleeve Logo Jersey,M', 49.99, 4, 199.96, grid);
  //   addProducts('FK-5136', 'ML Fork', 175.49, 6, 1052.94, grid);
  //   addProducts('HL-U509', 'Sports-100 Helmet,Black', 34.99, 1, 34.99, grid);
  //   //Apply the table built-in style
  //   grid.applyBuiltInStyle(PdfGridBuiltInStyle.listTable4Accent5);
  //   //Set gird columns width
  //   grid.columns[1].width = 200;
  //   for (int i = 0; i < headerRow.cells.count; i++) {
  //     headerRow.cells[i].style.cellPadding =
  //         PdfPaddings(bottom: 5, left: 5, right: 5, top: 5);
  //   }
  //   for (int i = 0; i < grid.rows.count; i++) {
  //     final PdfGridRow row = grid.rows[i];
  //     for (int j = 0; j < row.cells.count; j++) {
  //       final PdfGridCell cell = row.cells[j];
  //       if (j == 0) {
  //         cell.stringFormat.alignment = PdfTextAlignment.center;
  //       }
  //       cell.style.cellPadding =
  //           PdfPaddings(bottom: 5, left: 5, right: 5, top: 5);
  //     }
  //   }
  //   return grid;
  // }
  //
  // //Create and row for the grid.
  // void addProducts(String productId, String productName, double price,
  //     int quantity, double total, PdfGrid grid) {
  //   final PdfGridRow row = grid.rows.add();
  //   row.cells[0].value = productId;
  //   row.cells[1].value = productName;
  //   row.cells[2].value = price.toString();
  //   row.cells[3].value = quantity.toString();
  //   row.cells[4].value = total.toString();
  // }
  //
  // //Get the total amount.
  // double getTotalAmount(PdfGrid grid) {
  //   double total = 0;
  //   for (int i = 0; i < grid.rows.count; i++) {
  //     final String value =
  //     grid.rows[i].cells[grid.columns.count - 1].value as String;
  //     total += double.parse(value);
  //   }
  //   return total;
  // }

}