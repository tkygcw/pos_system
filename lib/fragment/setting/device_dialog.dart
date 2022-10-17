import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lan_scanner/lan_scanner.dart';
import 'package:flutter_usb_printer/flutter_usb_printer.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:pos_system/notifier/printer_notifier.dart';
import 'package:pos_system/page/progress_bar.dart';
import 'package:provider/provider.dart';

import '../../notifier/theme_color.dart';
import '../../translation/AppLocalizations.dart';

class DeviceDialog extends StatefulWidget {
  final int type;

  const DeviceDialog({Key? key, required this.type}) : super(key: key);

  @override
  State<DeviceDialog> createState() => _DeviceDialogState();
}

class _DeviceDialogState extends State<DeviceDialog> {
  List<Map<String, dynamic>> devices = [];
  FlutterUsbPrinter flutterUsbPrinter = FlutterUsbPrinter();
  List<String> ips = [];
  bool isLoad = false;

  @override
  initState() {
    super.initState();
    if (widget.type == 0) {
      _getDevicelist();
    } else {
      scan_network();
    }
  }

  scan_network() async {
    final scanner = LanScanner();
    ips = [];

    var wifiIP = await NetworkInfo().getWifiIP();

    var subnet = ipToCSubnet(wifiIP!);

    final stream = scanner.icmpScan(subnet, progressCallback: (progress) {
      if (progress == 1.0) {
        print('progress: $progress');
        setState(() {
          isLoad = true;
        });
      }
    });

    stream.listen((HostModel host) {
      ips.add(host.ip);
    });
  }

  _getDevicelist() async {
    List<Map<String, dynamic>> results = [];
    results = await FlutterUsbPrinter.getUSBDeviceList();

    print(" length: ${results.length}");
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
                title: Text('Device list'),
                content: isLoad ? SizedBox(
                    height: MediaQuery.of(context).size.height / 3,
                    width: MediaQuery.of(context).size.width / 3,
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
                                child: Container(
                                  margin: EdgeInsets.all(30),
                                  padding: EdgeInsets.only(bottom: 0),
                                  child: GestureDetector(
                                    onTap: () {
                                      printerModel.addPrinter(ips[index]);
                                      Navigator.of(context).pop();
                                    } ,
                                    child: Text('${ips[index]}'),
                                  ),
                                ),
                              );
                            })) : CustomProgressBar(),
                actions: <Widget>[
                  TextButton(
                    child: Text(
                        '${AppLocalizations.of(context)?.translate('close')}'),
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
                print(device);
                printerModel.removeAllPrinter();
                printerModel.addPrinter(
                    device['manufacturer'] + " " + device['productName']);
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
