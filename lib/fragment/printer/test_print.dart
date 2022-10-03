
import 'dart:typed_data';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_usb_printer/flutter_usb_printer.dart';

import 'package:esc_pos_utils/esc_pos_utils.dart';

class TestPrint extends StatefulWidget {
  const TestPrint({Key? key}) : super(key: key);

  @override
  State<TestPrint> createState() => _TestPrintState();
}

class _TestPrintState extends State<TestPrint> {
  List<Map<String, dynamic>> devices = [];
  FlutterUsbPrinter flutterUsbPrinter = FlutterUsbPrinter();
  bool connected = false;

  @override
  initState() {
    super.initState();
    _getDevicelist();
  }

  _getDevicelist() async {
    List<Map<String, dynamic>> results = [];
    results = await FlutterUsbPrinter.getUSBDeviceList();

    print(" length: ${results.length}");
    setState(() {
      devices = results;
    });
  }

  _connect(int vendorId, int productId) async {
    bool? returned = false;
    try {
      returned = await flutterUsbPrinter.connect(vendorId, productId);
    } on PlatformException {
      //response = 'Failed to get platform version.';
    }
    if (returned!) {
      setState(() {
        connected = true;
      });
    }
  }

  _print() async {
    try {
      var data = Uint8List.fromList(await testTicket());
      await flutterUsbPrinter.write(data);
      // await FlutterUsbPrinter.printRawData("text");
      // await FlutterUsbPrinter.printText("Testing ESC POS printer...");
    } on PlatformException {
      //response = 'Failed to get platform version.';
    }
  }

  testTicket() async {
    // Using default profile
    final profile = await CapabilityProfile.load();
    final generator = Generator(PaperSize.mm80, profile);
    List<int> bytes = [];

    //LOGO
    bytes += generator.text('Lucky 8', styles: PosStyles(bold: true, align: PosAlign.center, height: PosTextSize.size3, width: PosTextSize.size3));
    bytes += generator.emptyLines(1);
    bytes += generator.reset();
    //Address
    bytes += generator.text('22-2, Jalan Permas 11/1A, Bandar Permas Baru, 81750, Masai', styles: PosStyles(align: PosAlign.center));
    //telephone
    bytes += generator.text('Tel: 07-3504533', styles: PosStyles(align: PosAlign.center, height: PosTextSize.size1));
    bytes += generator.text('Lucky8@hotmail.com', styles: PosStyles(align: PosAlign.center));
    //receipt no
    bytes += generator.emptyLines(1);
    bytes += generator.text('Receipt No.: 17-200-000056',
        styles: PosStyles(align: PosAlign.left, width: PosTextSize.size1, height: PosTextSize.size1, bold: true));
    bytes += generator.reset();
    //other order detail
    bytes += generator.text('2022-10-03 17:18:18');
    bytes += generator.text('Close by: Taylor');
    bytes += generator.hr(ch: '-');
    bytes += generator.reset();
    //order product
    bytes += generator.text('Nasi kandar',styles: PosStyles(align: PosAlign.left));
    bytes += generator.reset();
    bytes += generator.row([
      PosColumn(text: '1x RM11', width: 8, styles: PosStyles(align: PosAlign.left)),
      PosColumn(text: 'RM11.00', width: 4, styles: PosStyles(align: PosAlign.right))
    ]);
    bytes += generator.text('Nasi Ayam',styles: PosStyles(align: PosAlign.left));
    bytes += generator.reset();
    bytes += generator.row([
      PosColumn(text: '1x RM7.90 (Big + RM2.00)', width: 8, styles: PosStyles(align: PosAlign.left)),
      PosColumn(text: 'RM9.90', width: 4, styles: PosStyles(align: PosAlign.right))
    ]);
    bytes += generator.reset();
    bytes += generator.hr(ch: '-');
    bytes += generator.reset();
    //item count
    bytes += generator.text('Items count: 2');
    bytes += generator.emptyLines(1);
    bytes += generator.reset();
    //total calc
    bytes += generator.row([
      PosColumn(text: 'Subtotal:', width: 8, styles: PosStyles(align: PosAlign.left)),
      PosColumn(text: 'RM20.90', width: 4, styles: PosStyles(align: PosAlign.right))
    ]);
    bytes += generator.row([
      PosColumn(text: 'Service Tax(10%):', width: 8, styles: PosStyles(align: PosAlign.left)),
      PosColumn(text: 'RM2.09', width: 4, styles: PosStyles(align: PosAlign.right))
    ]);
    bytes += generator.reset();
    //total
    bytes += generator.row([
      PosColumn(text: 'TOTAL:', width: 8, styles: PosStyles(align: PosAlign.left, bold: true)),
      PosColumn(text: 'RM22.99', width: 4, styles: PosStyles(align: PosAlign.right, bold: true))
    ]);

    bytes += generator.feed(1);
    bytes += generator.cut(mode: PosCutMode.partial);
    return bytes;
  }

  @override
  Widget build(BuildContext context) {
    return new MaterialApp(
      home: new Scaffold(
        appBar: new AppBar(
          title: new Text('USB PRINTER'),
          actions: <Widget>[
            new IconButton(
                icon: new Icon(Icons.refresh),
                onPressed: () => _getDevicelist()),
            connected == true
                ? new IconButton(
                    icon: new Icon(Icons.print),
                    onPressed: ()  {
                      _print();
                    })
                : new Container(),
          ],
        ),
        body: devices.length > 0
            ? new ListView(
                scrollDirection: Axis.vertical,
                children: _buildList(devices),
              )
            : null,
      ),
    );
  }

  List<Widget> _buildList(List<Map<String, dynamic>> devices) {
    return devices
        .map((device) => new ListTile(
              onTap: () {
                print(device);
                _connect(int.parse(device['vendorId']),
                    int.parse(device['productId']));
              },
              leading: new Icon(Icons.usb),
              title: new Text(
                  device['manufacturer'] + " " + device['productName']),
              subtitle:
                  new Text(device['vendorId'] + " " + device['productId']),
            ))
        .toList();
  }
}
