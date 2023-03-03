import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pos_system/notifier/report_notifier.dart';
import 'package:pos_system/object/table.dart';
import 'package:printing/printing.dart';
import 'package:shared_preferences/shared_preferences.dart';



class ReportFormat {

  Future<Uint8List> generateOverviewReportPdf(PdfPageFormat format, String title, ReportModel reportModel) async {
    final prefs = await SharedPreferences.getInstance();
    final int? branch_id = prefs.getInt('branch_id');
    final String? user = prefs.getString('user');
    Map userObject = json.decode(user!);
    final pdf = pw.Document(version: PdfVersion.pdf_1_5, compress: true);
    final font = await PdfGoogleFonts.nunitoExtraLight();
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
                child: pw.Text(title),
              ),
              pw.Divider(
                  height: 5,
                  thickness: 0.10,
                  color: PdfColors.black
              ),
              pw.SizedBox(height: 20),
              pw.Container(
                child: pw.Text('Branch id: ${branch_id.toString()}')
              ),
              pw.Container(
                child: pw.Text('${'Start date: ${reportModel.startDateTime2}'}')
              ),
              pw.Container(
                  child: pw.Text('${'End date: ${reportModel.endDateTime2}'}')
              ),
            ],
          );
        },
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
          return pw.Column(
            mainAxisAlignment: pw.MainAxisAlignment.center,
            children: [
              pw.Center(
                child: pw.Container(
                    height: 200,
                    width: 200,
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(color: PdfColors.black),
                    ),
                    child: pw.Padding(
                      padding: pw.EdgeInsets.all(15),
                      child: pw.Stack(
                          children: [
                            for(int i = 0; i < tableList.length; i++)
                              pw.BarcodeWidget(
                                  data: tableList[i].qrOrderUrl!,
                                  barcode: pw.Barcode.qrCode()
                              ),
                            pw.Center(
                                child: pw.SizedBox(
                                    height: 40,
                                    width: 40,
                                    child: pw.Image(logoImage))
                            )
                          ]
                      ),
                    )
                ),
              ),
              pw.SizedBox(height: 10),
              for(int i = 0; i< tableList.length; i++)
                pw.Center(
                  child: pw.Text('Table No: ${tableList[i].number}', style: pw.TextStyle(font: font, fontSize: 24))
                )
            ],
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