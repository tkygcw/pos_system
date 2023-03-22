import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pos_system/notifier/report_notifier.dart';
import 'package:pos_system/object/categories.dart';
import 'package:pos_system/object/payment_link_company.dart';
import 'package:pos_system/object/table.dart';
import 'package:printing/printing.dart';
import 'package:shared_preferences/shared_preferences.dart';



class ReportFormat {

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
    final logoFile = FileImage(File('/data/data/com.example.pos_system/files/assets/img/logo1.jpg'));
    final logoImage = await flutterImageProvider(logoFile);
    pdf.addPage(
      pw.Page(
        pageFormat: format,
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Center(
                child: pw.SizedBox(
                  height: 100,
                  width: 100,
                  child: pw.Image(logoImage)
                ),

              ),
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
                child: pw.Text('${branchObject['name']}', style: pw.TextStyle(font: font, fontSize: 58))
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
    List<PaymentLinkCompany> paymentList = [
      PaymentLinkCompany(name: 'cash', item_sum: 5),
      PaymentLinkCompany(name: 'card', item_sum: 7),
      PaymentLinkCompany(name: 'TNG', item_sum: 6)];
    const tableHeaders = [
      'Date',
      'Bills',
      'Sales',
      'Refund Bills',
      'Refund Amount',
      'Discount',
      'Tax',
      'Cancelled Item',
    ];

    const tableHeaders2 = ['Name', 'Amount'];
    var sales = jsonDecode(reportModel.reportValue[0]);
    var payment = jsonDecode(reportModel.reportValue[1]);
    var settlementPayment = jsonDecode(reportModel.reportValue[2]);
    final pdf = pw.Document(version: PdfVersion.pdf_1_5, compress: true);
    final font = await PdfGoogleFonts.nunitoExtraLight();
    final logoFile = FileImage(File('/data/data/com.example.pos_system/files/assets/img/logo1.jpg'));
    final logoImage = await flutterImageProvider(logoFile);
    pdf.addPage(
      pw.MultiPage(
          pageFormat: format,
          orientation: pw.PageOrientation.landscape,
          build: (pw.Context context) => [
            pw.Center(
              child: pw.SizedBox(
                  height: 100,
                  width: 100,
                  child: pw.Image(logoImage)
              ),
            ),
            // pw.Table(
            //   children: [
            //     pw.TableRow(
            //         decoration: pw.BoxDecoration(
            //           color: PdfColors.black,
            //         ),
            //         children: [
            //           pw.Padding(
            //             padding: pw.EdgeInsets.all(10),
            //             child: pw.Text('Date', style: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold)),
            //           ),
            //           pw.Padding(
            //             padding: pw.EdgeInsets.fromLTRB(5, 10, 10, 10),
            //             child: pw.Text('Bills', style: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold)),
            //           ),
            //           pw.Padding(
            //             padding: pw.EdgeInsets.fromLTRB(5, 10, 10, 10),
            //             child: pw.Text('Refund Bills', style: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold)),
            //           ),
            //           pw.Padding(
            //             padding: pw.EdgeInsets.fromLTRB(5, 10, 10, 10),
            //             child: pw.Text('Refund Amount', style: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold)),
            //           ),
            //           pw.Padding(
            //             padding: pw.EdgeInsets.fromLTRB(5, 10, 10, 10),
            //             child: pw.Text('Discount', style: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold)),
            //           ),
            //           pw.Padding(
            //             padding: pw.EdgeInsets.fromLTRB(5, 10, 10, 10),
            //             child: pw.Text('Tax', style: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold)),
            //           ),
            //           pw.Padding(
            //             padding: pw.EdgeInsets.fromLTRB(5, 10, 10, 10),
            //             child: pw.Text('Cancelled Item', style: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold)),
            //           ),
            //
            //         ]),
            //     for (var i = 0; i < 50;  i++)
            //       pw.TableRow(
            //         children: [
            //           pw.Text('${i}')
            //         ]
            //       )
            //   ]
            // ),
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
                  sales.length,
                      (index) => [
                    sales[index]['created_at'],
                    sales[index]['total_bill'],
                    sales[index]['total_sales'],
                    sales[index]['total_refund_bill'],
                    sales[index]['total_refund_amount'],
                    sales[index]['total_discount'],
                    sales[index]['total_tax'],
                    sales[index]['total_cancellation'],
                  ]),
            ),
          ]
      ),
    );

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
                  horizontalInside: pw.BorderSide.none,
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
                        child: pw.Text('Date', style: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold)),
                      ),
                      for(int i = 0; i < payment.length; i++)
                        pw.Padding(
                          padding: pw.EdgeInsets.fromLTRB(5, 5, 10, 5),
                          child: pw.Text('${payment[i]['name']}', style: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold)),
                        ),
                    ]
                  ),
                  pw.TableRow(
                      children: [
                        for(int j = 0; j < sales.length; j++)
                          pw.Padding(
                            padding: pw.EdgeInsets.fromLTRB(5, 5, 10, 5),
                            child: pw.Text('${sales[j]['created_at']}'),
                          ),
                        for(int i = 0; i < settlementPayment.length; i++)
                          pw.Padding(
                            padding: pw.EdgeInsets.fromLTRB(5, 5, 10, 5),
                            child: pw.Text('${settlementPayment[i]['total_sales']}'),
                          ),
                      ]
                  )
                ]
              )
              // for(int i = 0; i < payment.length; i++)
              //   pw.Padding(
              //     padding: pw.EdgeInsets.fromLTRB(5, 10, 10, 10),
              //     child: pw.Text('${payment[i]['name']}', style: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold)),
              //   ),
            ])
    );
    return pdf.save();
  }

  Future<Uint8List> generateProductReportPdf(PdfPageFormat format, String title, ReportModel reportModel) async {
    const tableHeaders2 = ['Name', 'Amount'];
    var sales = jsonDecode(reportModel.reportValue[0]);
    var payment = jsonDecode(reportModel.reportValue[1]);
    var settlementPayment = jsonDecode(reportModel.reportValue[2]);
    final pdf = pw.Document(version: PdfVersion.pdf_1_5, compress: true);
    final font = await PdfGoogleFonts.nunitoExtraLight();
    final logoFile = FileImage(File('/data/data/com.example.pos_system/files/assets/img/logo1.jpg'));
    final logoImage = await flutterImageProvider(logoFile);
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
        orientation: pw.PageOrientation.portrait,
        build: (pw.Context context) => [
          pw.Center(
            child: pw.SizedBox(
                height: 100,
                width: 100,
                child: pw.Image(logoImage)
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
                        child: pw.Text('Product', style: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold)),
                      ),
                      pw.Padding(
                        padding: pw.EdgeInsets.fromLTRB(5, 10, 10, 10),
                        child: pw.Text('Variant', style: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold)),
                      ),
                    ]),
                for (var i = 0; i < data.length; i += 4)
                  ...[
                    _generateParentRow(data[i]),
                    ..._generateChildRows(data.sublist(i + 1, i + 4)),
                  ],

              ]
          ),
        ]
      ),
    );
    return pdf.save();
  }

  Future<Uint8List> generateDiningReport(PdfPageFormat format, String title) async {
    final pdf = pw.Document(version: PdfVersion.pdf_1_5, compress: true);
    final font = await PdfGoogleFonts.nunitoExtraLight();
    final logoFile = FileImage(File('/data/data/com.example.pos_system/files/assets/img/logo1.jpg'));
    final logoImage = await flutterImageProvider(logoFile);
    pdf.addPage(
      pw.MultiPage(
        pageFormat: format,
        build: (pw.Context context) => [
          pw.Column(
            children: [
              pw.Center(
                child: pw.SizedBox(
                    height: 100,
                    width: 100,
                    child: pw.Image(logoImage)
                ),

              ),
            ],
          )
        ]
      ),
    );

    return pdf.save();
  }


  Future<Uint8List> generateReportPdf(PdfPageFormat format, String title) async {
    final pdf = pw.Document(version: PdfVersion.pdf_1_5, compress: true);
    final font = await PdfGoogleFonts.nunitoExtraLight();
    final logoFile = FileImage(File('/data/data/com.example.pos_system/files/assets/img/logo1.jpg'));
    final logoImage = await flutterImageProvider(logoFile);
    pdf.addPage(
      pw.Page(
        pageFormat: format,
        build: (context) {
          return pw.Column(
            children: [
              pw.Center(
                child: pw.SizedBox(
                    height: 100,
                    width: 100,
                    child: pw.Image(logoImage)
                ),

              ),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  Future<Uint8List> generateQrPdf(PdfPageFormat format, List<PosTable> tableList) async {
    print('table length: ${tableList.length}');
    final pdf = pw.Document(version: PdfVersion.pdf_1_5, compress: true);
    final font = await PdfGoogleFonts.robotoBlack();
    final logoFile = FileImage(File('/data/data/com.example.pos_system/files/assets/img/logo1.jpg'));
    final logoImage = await flutterImageProvider(logoFile);
    pdf.addPage(
      pw.Page(
        pageFormat: format,
        build: (context) {
          return pw.GridView(
            padding: pw.EdgeInsets.only(bottom: 50),
            crossAxisCount: 2,
            children: List.generate(
                tableList.length, (index) => pw.Column(
                children: [
                  pw.Spacer(),
                  pw.Container(
                      height: 200,
                      width: 200,
                      decoration: pw.BoxDecoration(
                        border: pw.Border.all(color: PdfColors.black),
                      ),
                      child: pw.Padding(
                        padding: pw.EdgeInsets.all(15),
                        child: pw.Stack(
                            children: [
                              pw.BarcodeWidget(
                                  data: tableList[index].qrOrderUrl!,
                                  barcode: pw.Barcode.qrCode()
                              ),
                              pw.Center(
                                  child: pw.SizedBox(
                                      height: 40,
                                      width: 40,
                                      child: pw.Image(logoImage))
                              ),
                            ]
                        ),
                      )
                  ),
                  pw.SizedBox(height: 10),
                  pw.Center(
                      child: pw.Text('Table No: ${tableList[index].number}', style: pw.TextStyle(font: font, fontSize: 24))
                  )
                ]
            ),
            )
          );
        },
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