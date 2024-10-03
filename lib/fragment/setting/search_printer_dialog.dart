import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:app_settings/app_settings.dart';
import 'package:flutter/material.dart';
import 'package:lan_scanner/lan_scanner.dart';
import 'package:flutter_usb_printer/flutter_usb_printer.dart';
import 'package:location/location.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:pos_system/notifier/printer_notifier.dart';
import 'package:print_bluetooth_thermal/print_bluetooth_thermal.dart';
import 'package:provider/provider.dart';

import '../../notifier/theme_color.dart';
import '../../translation/AppLocalizations.dart';

class SearchPrinterDialog extends StatefulWidget {
  final int type;
  final Function(String value) callBack;

  const SearchPrinterDialog({Key? key, required this.type, required this.callBack}) : super(key: key);

  @override
  State<SearchPrinterDialog> createState() => _SearchPrinterDialogState();
}

class _SearchPrinterDialogState extends State<SearchPrinterDialog> {
  StreamSubscription? streamSub;
  List<Map<String, dynamic>> devices = [];
  FlutterUsbPrinter flutterUsbPrinter = FlutterUsbPrinter();
  List<String> ips = [];
  double percentage = 0.0;
  bool isLoad = false, isButtonDisable = false;
  String? wifiIP;
  Text? info;
  List<BluetoothInfo> items = [];
  bool connected = false;
  bool bluetoothIsOn = false;

  @override
  initState() {
    super.initState();
    if (widget.type == 0) {
      _getDevicelist();
    } else if (widget.type == 1) {
      checkPermission();
    } else {
      checkBluetooth();
    }
  }

  @override
  void dispose() {
    // TODO: implement dispose
    if(streamSub != null){
      streamSub!.cancel();
    }
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

  checkBluetooth() async {
    bluetoothIsOn = await PrintBluetoothThermal.bluetoothEnabled;
    if (!bluetoothIsOn) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('${AppLocalizations.of(context)?.translate('bluetooth_is_off')}'),
            content: Text('${AppLocalizations.of(context)?.translate('bluetooth_is_off_desc')}'),
            actions: <Widget>[
              TextButton(
                child: Text('${AppLocalizations.of(context)?.translate('cancel')}'),
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).pop();
                },
              ),
              TextButton(
                child: Text('${AppLocalizations.of(context)?.translate('setting')}'),
                onPressed: () {
                  AppSettings.openAppSettings(type: AppSettingsType.bluetooth);
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        },
      );
    } else {
      if (this.mounted) {
        this.getBluetoots();
        setState(() {
          isLoad = false;
        });
      }
    }
  }

  Future<void> getBluetoots() async {
    setState(() {
      isLoad = false;
      items = [];
    });
    final List<BluetoothInfo> listResult = await PrintBluetoothThermal.pairedBluetooths;

    setState(() {
      items = listResult;
      isLoad = true;
    });
  }

  Future<void> connect(String mac) async {
    setState(() {
      connected = false;
    });
    final bool result = await PrintBluetoothThermal.connect(macPrinterAddress: mac);
    if (result)
      connected = true;
    setState(() {
    });
  }

  scan_network() async {
    final scanner = LanScanner();
    ips = [];

    wifiIP = await NetworkInfo().getWifiIP();
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
    if(wifiName == null){
      wifiName = '"mobile data"';
    }
    var subnet = ipToCSubnet(wifiIP!);
    final stream = scanner.icmpScan(subnet, progressCallback: (progress) {
      if (mounted) {
        setState(() {
          info = Text("${AppLocalizations.of(context)?.translate('scanning_device_within')} $wifiName\n${AppLocalizations.of(context)!.translate('device_ip')}: ${wifiIP}");
          percentage = progress;
          if (percentage == 1.0) {
            isLoad = true;
          }
        });
      }
    });

    streamSub = stream.listen((Host host) {
      if(wifiIP != host.internetAddress.address){
        ips.add(host.internetAddress.address);
      }
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
          titlePadding: EdgeInsets.fromLTRB(24, 12, 24, 0),
          title: Row(
            children: [
              Text(AppLocalizations.of(context)!.translate('device_list')),
              Spacer(),
              Visibility(visible: widget.type == 1 && isLoad, child: Text(wifiIP.toString())),
              Visibility(
                visible: widget.type == 2,
                child: TextButton(
                  onPressed: () {
                    checkBluetooth();
                  },
                  child: Text("${AppLocalizations.of(context)?.translate('refresh')}"),
                ),
              )
            ],
          ),
          content: isLoad
              ? SizedBox(
                  height: MediaQuery.of(context).size.height / 2.5,
                  width: MediaQuery.of(context).size.width / 4,
                  child: widget.type == 0
                      ? ListView(
                          scrollDirection: Axis.vertical,
                          children: _buildList(devices, printerModel),
                        )
                      : widget.type == 1
                        ? ListView.builder(
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
                            })
                      : items.isEmpty ? Center(child: Text(bluetoothIsOn ? "${AppLocalizations.of(context)?.translate('no_result_found')}" : "${AppLocalizations.of(context)?.translate('bluetooth_is_off')}"))
                  : ListView.builder(
                        shrinkWrap: true,
                        padding: EdgeInsets.zero,
                        itemCount: items.length,
                        itemBuilder: (context, index) {
                          return Card(
                            elevation: 5,
                            child: ListTile(
                              onTap: () {
                                String mac = items[index].macAdress;
                                printerModel.removeAllPrinter();
                                widget.callBack(jsonEncode(mac));
                                Navigator.of(context).pop();
                                this.connect(mac);
                              },
                              leading: Icon(
                                Icons.bluetooth,
                                color: Colors.black45,
                              ),
                              title: Text('${items[index].name}'),
                              subtitle: Text("${items[index].macAdress}"),
                            ),
                          );
                        },
                      )
              )
              : CircularPercentIndicator(
                  addAutomaticKeepAlive: false,
                  footer: Container(margin: EdgeInsets.only(top: 10), child: info),
                  circularStrokeCap: CircularStrokeCap.round,
                  radius: 80.0,
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
