import 'dart:convert';

import 'package:flutter/material.dart';

import 'package:lan_scanner/lan_scanner.dart';
import 'package:flutter_usb_printer/flutter_usb_printer.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:pos_system/notifier/printer_notifier.dart';
import 'package:provider/provider.dart';

import '../../notifier/theme_color.dart';
import '../../translation/AppLocalizations.dart';

class DeviceDialog extends StatefulWidget {
  final int type;
  final Function(String value) callBack;
  const DeviceDialog({Key? key, required this.type, required this.callBack}) : super(key: key);

  @override
  State<DeviceDialog> createState() => _DeviceDialogState();
}

class _DeviceDialogState extends State<DeviceDialog> {
  List<Map<String, dynamic>> devices = [];
  FlutterUsbPrinter flutterUsbPrinter = FlutterUsbPrinter();
  String wifi = "";
  List<String> ips = [];
  double percentage = 0.0;
  bool isLoad = false;
  Text? info;

  @override
  initState() {
    super.initState();
    if (widget.type == 0) {
      _getDevicelist();
    } else {
      scan_network();
    }
  }

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
  }

  scan_network() async {
    final scanner = LanScanner();
    ips = [];

    var wifiIP = await NetworkInfo().getWifiIP();
    var wifiName = await NetworkInfo().getWifiName();

    var subnet = ipToCSubnet(wifiIP!);

    final stream = scanner.icmpScan(subnet, progressCallback: (progress) {
      setState(() {
        info = Text('Scanning device within $wifiName');
        percentage = progress;
        if (percentage == 1.0) {
          print('${wifiName}');
          isLoad = true;
        }
      });
    });

    stream.listen((HostModel host) {
      ips.add(host.ip);
    });
  }

  _getDevicelist() async {
    List<Map<String, dynamic>> results = [];
    results = await FlutterUsbPrinter.getUSBDeviceList();

    setState(() {
      devices = results;
      isLoad = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeColor>(builder: (context, ThemeColor color, child) {
      return Consumer<PrinterModel>(
          builder: (context, PrinterModel printerModel, child) {
        return AlertDialog(
          insetPadding: EdgeInsets.all(0),
          title: Text('Device list'),
          content: isLoad
              ? SizedBox(
                  height: MediaQuery.of(context).size.height / 2.5,
                  width: MediaQuery.of(context).size.width / 4,
                  child: widget.type == 0
                      ? ListView(
                          scrollDirection: Axis.vertical,
                          children: _buildList(devices, printerModel),
                        )
                      : ListView.builder(
                          itemCount: ips.length,
                          itemBuilder: (context, index) {
                            return Card(
                              elevation: 5,
                              child: ListTile(
                                onTap: () {

                                  widget.callBack(jsonEncode(ips[index]));
                                  // printerModel
                                  //     .addPrinter(jsonEncode(ips[index]));
                                  Navigator.of(context).pop();
                                },
                                leading: Icon(
                                  Icons.print,
                                  color: Colors.black45,
                                ),
                                title: Text('${ips[index]}'),
                              ),
                            );
                          }))
              : CircularPercentIndicator(
                  footer: Container(
                    margin: EdgeInsets.only(top: 10),
                    child: info
                  ),
                  circularStrokeCap: CircularStrokeCap.round,
                  radius: 90.0,
                  lineWidth: 10.0,
                  percent: percentage,
                  center: Text(
                    "${(percentage * 100).toStringAsFixed(0)} %",
                    style: TextStyle(
                      fontSize: 25,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  progressColor: color.backgroundColor),
          actions: <Widget>[
            TextButton(
              child:
                  Text('${AppLocalizations.of(context)?.translate('close')}'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      });
    });
  }

  List<Widget> _buildList(
      List<Map<String, dynamic>> devices, PrinterModel printerModel) {
    return devices
        .map((device) => new ListTile(
              onTap: () {
                printerModel.removeAllPrinter();
                //printerModel.addPrinter(jsonEncode(device));
                widget.callBack(jsonEncode(device));
                Navigator.of(context).pop();
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
