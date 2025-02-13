import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:io' as Platform;
import 'package:app_settings/app_settings.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:lan_scanner/lan_scanner.dart';
import 'package:flutter_usb_printer/flutter_usb_printer.dart';
import 'package:location/location.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:pos_system/notifier/printer_notifier.dart';
import 'package:print_bluetooth_thermal/print_bluetooth_thermal.dart';
import 'package:provider/provider.dart';
import 'package:thermal_printer/thermal_printer.dart';

import '../../notifier/theme_color.dart';
import '../../translation/AppLocalizations.dart';

class SearchPrinterDialog extends StatefulWidget {
  final int type;
  final Function(String value) callBack;

  const SearchPrinterDialog(
      {Key? key, required this.type, required this.callBack})
      : super(key: key);

  @override
  State<SearchPrinterDialog> createState() => _SearchPrinterDialogState();
}

class _SearchPrinterDialogState extends State<SearchPrinterDialog> {
  var printerManager = PrinterManager.instance;
  var currentPrinterType = PrinterType.usb;
  StreamSubscription? streamSub;
  List<Map<String, dynamic>> devices = [];
  List<PrinterDevice> printerDevice = [];
  FlutterUsbPrinter flutterUsbPrinter = FlutterUsbPrinter();
  List<String> ips = [];
  double percentage = 0.0;
  bool isLoad = false, isButtonDisable = false;
  String? wifiIP;
  Text? info;
  List<BluetoothInfo> items = [];
  bool connected = false;
  bool bluetoothIsOn = false;
  String customIp = '';
  bool isStreamRunning = false;

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
    if (streamSub != null) {
      streamSub!.cancel();
    }
    super.dispose();
  }

  _scan(PrinterType type, {bool isBle = false}) {
    // Find printers
    PrinterManager.instance.discovery(type: type, isBle: isBle).listen((device) {
      printerDevice.add(device);
    });
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
    bool bluetoothIsGranted = await PrintBluetoothThermal.isPermissionBluetoothGranted;
    if(bluetoothIsGranted){
      bluetoothIsOn = await PrintBluetoothThermal.bluetoothEnabled;
      if (!bluetoothIsOn) {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text(
                  '${AppLocalizations.of(context)?.translate('bluetooth_is_off')}'),
              content: Text(
                  '${AppLocalizations.of(context)?.translate('bluetooth_is_off_desc')}'),
              actions: <Widget>[
                TextButton(
                  child: Text(
                      '${AppLocalizations.of(context)?.translate('cancel')}'),
                  onPressed: () {
                    Navigator.of(context).pop();
                    Navigator.of(context).pop();
                  },
                ),
                TextButton(
                  child: Text(
                      '${AppLocalizations.of(context)?.translate('setting')}'),
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
  }

  Future<void> getBluetoots() async {
    isLoad = false;
    setState(() {
      items = [];
    });
    final List<BluetoothInfo> listResult =
        await PrintBluetoothThermal.pairedBluetooths;

    setState(() {
      items = listResult;
      isLoad = true;
    });
  }

  Future<void> connect(String mac) async {
    setState(() {
      connected = false;
    });
    final bool result =
        await PrintBluetoothThermal.connect(macPrinterAddress: mac);
    if (result) connected = true;
    setState(() {});
  }

  scan_network() async {
    isLoad = false;
    final scanner = LanScanner();
    ips = [];
    percentage = 0.0;

    wifiIP = await NetworkInfo().getWifiIP();
    if (wifiIP != null) {
      setState(() => {});
    }
    var wifiName = await NetworkInfo().getWifiName();
    if (wifiIP == null) {
      List<NetworkInterface> interfaces = await NetworkInterface.list();
      for (var interface in interfaces) {
        for (var address in interface.addresses) {
          wifiIP = address.address;
          wifiName = "Ethernet";
        }
      }
    }
    if (wifiName == null) {
      wifiName = '"mobile data"';
    }
    var subnet = ipToCSubnet(wifiIP!);

    if(Platform.Platform.isAndroid) {
      final stream = scanner.icmpScan(subnet, progressCallback: (progress) {
        if (mounted) {
          setState(() {
            info = Text(
                "${AppLocalizations.of(context)?.translate('scanning_device_within')} $wifiName\n${AppLocalizations.of(context)!.translate('device_ip')}: ${wifiIP}");
            percentage = progress;
            if (percentage == 1.0) {
              isLoad = true;
              isStreamRunning = false;
            }
          });
        }
      });

      isStreamRunning = true;
      streamSub = stream.listen((Host host) async {
        if (wifiIP != host.internetAddress.address) {
          bool isPortOpen = await checkPort(host.internetAddress.address, 9100);
          if (isPortOpen) {
            setState(() {
              ips.add(host.internetAddress.address);
            });
          }
        }
      });

      if(streamSub != null) {
        streamSub!.onDone(() {
          isStreamRunning = false;
        });
      }
    } else {
      isLoad = true;
    }
  }

  Future<bool> checkPort(String ip, int port) async {
    try {
      final socket =
          await Socket.connect(ip, port, timeout: Duration(seconds: 2));
      socket.destroy();
      return true;
    } catch (e) {
      return false;
    }
  }

  _getDevicelist() async {
    isLoad = false;
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
          title: Row(
            children: [
              Text(AppLocalizations.of(context)!.translate('device_list')),
              Spacer(),
              Visibility(
                  visible: widget.type == 1 && wifiIP != null,
                  child: Text(wifiIP.toString())),
            ],
          ),
          content: Container(
            height: MediaQuery.of(context).size.height / 2.5,
            width: MediaQuery.of(context).size.width / 4,
            child: Column(
              children: [
                !isLoad
                    ? Padding(
                        padding: EdgeInsets.only(bottom: 20),
                        child: SizedBox(
                          width: 25.0,
                          height: 25.0,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.grey),
                              ),
                              Text(
                                '${(percentage * 100).toStringAsFixed(0)}',
                                style: TextStyle(
                                  color: Colors.black,
                                  fontSize: 14.0,
                                ),
                              ),
                            ],
                          )
                        ),
                      )
                    : Container(),
                Expanded(
                    child: widget.type == 0
                        ? ListView.builder(
                            shrinkWrap: true,
                            padding: EdgeInsets.zero,
                            itemCount: devices.length,
                            itemBuilder: (context, index) {
                              return Card(
                                elevation: 5,
                                child: _buildList(devices, printerModel)[index],
                              );
                            })
                        : widget.type == 1
                            // lan
                            ? ListView.builder(
                                shrinkWrap: true,
                                padding: EdgeInsets.zero,
                                itemCount:
                                    ips.length + 1, // Increase itemCount by 1
                                itemBuilder: (context, index) {
                                  if (index == 0) {
                                    return Card(
                                      elevation: 5,
                                      child: ListTile(
                                        onTap: isButtonDisable
                                            ? null
                                            : () async {
                                                setState(() {
                                                  isButtonDisable = true;
                                                  if (isStreamRunning) {
                                                    streamSub!.cancel();
                                                    isLoad = true;
                                                    isStreamRunning = false;
                                                  }
                                                });
                                                await manualAddDeviceDialog();
                                              },
                                        leading: Icon(
                                          Icons.print,
                                          color: Colors.black45,
                                        ),
                                        title: Text('Custom'),
                                      ),
                                    );
                                  } else {
                                    // Existing cards
                                    return Card(
                                      elevation: 5,
                                      child: ListTile(
                                        onTap: isButtonDisable
                                            ? null
                                            : () {
                                                setState(() {
                                                  isButtonDisable = true;
                                                });
                                                widget.callBack(jsonEncode(ips[
                                                    index -
                                                        1])); // Adjust index
                                                Navigator.of(context).pop();
                                              },
                                        leading: Icon(
                                          Icons.print,
                                          color: Colors.black45,
                                        ),
                                        title: Text(
                                            '${ips[index - 1]}'), // Adjust index
                                      ),
                                    );
                                  }
                                },
                              )
                            : items.isEmpty
                                ? Center(
                                    child: Text(bluetoothIsOn
                                        ? "${AppLocalizations.of(context)?.translate('no_result_found')}"
                                        : "${AppLocalizations.of(context)?.translate('bluetooth_is_off')}"))
                                : ListView.builder(
                                    //bluetooth
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
                                            // this.connect(mac);
                                          },
                                          leading: Icon(
                                            Icons.bluetooth,
                                            color: Colors.black45,
                                          ),
                                          title: Text('${items[index].name}'),
                                          subtitle:
                                              Text("${items[index].macAdress}"),
                                        ),
                                      );
                                    },
                                  )),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text(
                  "${AppLocalizations.of(context)?.translate('refresh')}"),
              onPressed: () {
                if (isStreamRunning) {
                  streamSub!.cancel();
                  setState(() {
                    isLoad = true;
                    isStreamRunning = false;
                  });
                } else {
                  widget.type == 0
                      ? _getDevicelist()
                      : widget.type == 1
                      ? scan_network()
                      : checkBluetooth();
                }
              },
            ),
            TextButton(
              child:
                  Text('${AppLocalizations.of(context)?.translate('close')}',
                      style: TextStyle(color: Colors.red)),
              onPressed: () {
                if (isStreamRunning) {
                  streamSub!.cancel();
                }
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

  manualAddDeviceDialog() {
    var ip = TextEditingController(text: '${ipToCSubnet(wifiIP!).toString()}.');
    bool isValidIp(String ip) {
      final regex = RegExp(r'^(\d{1,3}\.){3}\d{1,3}$');
      if (!regex.hasMatch(ip)) return false;
      return ip.split('.').every((octet) => int.parse(octet) <= 255);
    }

    // flutter defined function
    showDialog(
      context: context,
      builder: (BuildContext context) {
        // return alert dialog object
        return Center(
          child: SingleChildScrollView(
            child: AlertDialog(
              title: Text("${AppLocalizations.of(context)!.translate('add_printer')}"),
              content: Column(
                children: [
                  TextField(
                    keyboardType: TextInputType.numberWithOptions(decimal: true),
                    controller: ip,
                    textAlign: TextAlign.start,
                    maxLines: 1,
                    autofocus: true,
                    decoration: InputDecoration(
                      prefixIcon: Icon(Icons.wifi),
                      labelText: '${AppLocalizations.of(context)!.translate('ip_address')}',
                      labelStyle: TextStyle(fontSize: 14, color: Colors.blueGrey),
                      hintText: '192.168.x.x',
                      border: new OutlineInputBorder(borderSide: new BorderSide(color: Colors.teal)),
                    ),
                    onSubmitted: (value) {
                      if (ip.text.isEmpty || !isValidIp(ip.text)) {
                        setState(() {
                          Fluttertoast.showToast(
                              backgroundColor: Colors.red,
                              msg: "${AppLocalizations.of(context)?.translate('invalid_input')}");
                        });
                      } else {
                        customIp = ip.text;
                        widget.callBack(jsonEncode(customIp));
                        Navigator.of(context).pop();
                        Navigator.of(context).pop();
                      }
                    },
                  ),
                ],
              ),
              actions: <Widget>[
                TextButton(
                  child: Text('${AppLocalizations.of(context)!.translate('cancel')}'),
                  onPressed: () {
                    setState(() {
                      isButtonDisable = false;
                      // scan_network();
                    });
                    Navigator.of(context).pop();
                  },
                ),
                TextButton(
                  child: Text(
                    '${AppLocalizations.of(context)!.translate('confirm')}',
                    style: TextStyle(color: Colors.red),
                  ),
                  onPressed: () async {
                    if (ip.text.isEmpty || !isValidIp(ip.text)) {
                      setState(() {
                        Fluttertoast.showToast(
                            backgroundColor: Colors.red,
                            msg: "${AppLocalizations.of(context)?.translate('invalid_input')}");
                      });
                    } else {
                      customIp = ip.text;
                      widget.callBack(jsonEncode(customIp));
                      Navigator.of(context).pop();
                      Navigator.of(context).pop();
                    }
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
