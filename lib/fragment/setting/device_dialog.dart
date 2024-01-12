import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:lan_scanner/lan_scanner.dart';
import 'package:flutter_usb_printer/flutter_usb_printer.dart';
import 'package:location/location.dart';
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
  bool isLoad = false, isButtonDisable = false;
  Text? info;

  @override
  initState() {
    super.initState();
    if (widget.type == 0) {
      _getDevicelist();
    } else {
      checkPermission();
    }
  }

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
  }

  checkPermission() async {
    Location location = new Location();
    //check location permission is granted or not
    var permissionGranted = await location.hasPermission();
    if (permissionGranted == PermissionStatus.denied) {
      permissionGranted = await location.requestPermission();
      if (permissionGranted != PermissionStatus.granted) {
        Navigator.of(context).pop();
      } else {
        //check location is on or not
        var _locationOn = await location.serviceEnabled();
        if (!_locationOn) {
          _locationOn = await location.requestService();
          if (!_locationOn) {
            Navigator.of(context).pop();
          } else {
            await scan_network();
          }
        } else {
          await scan_network();
        }
      }
    } else {
      //check location is on or not
      var _locationOn = await location.serviceEnabled();
      if (!_locationOn) {
        _locationOn = await location.requestService();
        if (!_locationOn) {
          Navigator.of(context).pop();
        } else {
          await scan_network();
        }
      } else {
        await scan_network();
      }
    }
  }

  scan_network() async {
    final scanner = LanScanner();
    ips = [];

    var wifiIP = await NetworkInfo().getWifiIP();
    var wifiName = await NetworkInfo().getWifiName();
    if(wifiIP == null) {
      List<NetworkInterface> interfaces = await NetworkInterface.list();
      for (var interface in interfaces) {
        for (var address in interface.addresses) {
          wifiIP = address.address;
          wifiName = "Ethernet";
        }
      }
    }


    var subnet = ipToCSubnet(wifiIP!);

    final stream = scanner.icmpScan(subnet, progressCallback: (progress) {
      if (this.mounted) {
        setState(() {
          info = Text("${AppLocalizations.of(context)?.translate('scanning_device_within')} " + "$wifiName");
          percentage = progress;
          if (percentage == 1.0) {
            isLoad = true;
          }
        });
      }
    });

    stream.listen((Host host) {
      ips.add(host.internetAddress.address);
    });
  }

  _getDevicelist() async {
    List<Map<String, dynamic>> results = [];
    results = await FlutterUsbPrinter.getUSBDeviceList();
    if (this.mounted) {
      setState(() {
        devices = results;
        isLoad = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeColor>(builder: (context, ThemeColor color, child) {
      return Consumer<PrinterModel>(builder: (context, PrinterModel printerModel, child) {
        return AlertDialog(
          insetPadding: EdgeInsets.all(0),
          actionsPadding: EdgeInsets.zero,
          title: Text(AppLocalizations.of(context)!.translate('device_list')),
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
                          shrinkWrap: true,
                          padding: EdgeInsets.zero,
                          itemCount: ips.length,
                          itemBuilder: (context, index) {
                            return Card(
                              elevation: 5,
                              child: ListTile(
                                onTap: isButtonDisable ? null : () {
                                  setState(() {
                                    isButtonDisable = true;
                                  });
                                  widget.callBack(jsonEncode(ips[index]));
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
                  footer: Container(margin: EdgeInsets.only(top: 10), child: info),
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
              child: Text('${AppLocalizations.of(context)?.translate('close')}'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      });
    });
  }

  List<Widget> _buildList(List<Map<String, dynamic>> devices, PrinterModel printerModel) {
    return devices
        .map((device) => new ListTile(
              onTap: () {
                printerModel.removeAllPrinter();
                //printerModel.addPrinter(jsonEncode(device));
                widget.callBack(jsonEncode(device));
                Navigator.of(context).pop();
              },
              leading: new Icon(Icons.usb),
              title: new Text(device['manufacturer'] + " " + device['productName']),
              subtitle: new Text(device['vendorId'] + " " + device['productId']),
            ))
        .toList();
  }
}
